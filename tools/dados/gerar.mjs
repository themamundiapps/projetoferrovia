// Gera src/shared/Dados/<Mapa>.luau a partir de tools/dados/<mapa>.json,
// usando a MESMA projeção dos tiles do mapa (projecoes.json), para tudo cair no lugar certo.
// Uso: node tools/dados/gerar.mjs   (ou `npm run gerar` dentro de tools/dados)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as d3 from "d3-geo";

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const RAIZ = path.resolve(AQUI, "../..");
const SAIDA = path.join(RAIZ, "src/shared/Dados");
const projecoes = JSON.parse(fs.readFileSync(path.join(AQUI, "projecoes.json"), "utf8"));

// Economia provisória: só para o protótipo andar. O balanceamento real vem nos playtests.
const CUSTO_POR_KM = 6;        // R$ por km no primeiro trecho do jogo
const CRESCIMENTO_LINHA = 2.4; // cada degrau (onda de linhas) custa ~70% mais por km
const SINUOSIDADE = 1.25;      // trilho real é mais longo que a linha reta

const MAPAS = {
  brasil: { arquivo: "brasil.json", modulo: "Brasil", moeda: "BRL", simbolo: "R$" },
  eua: { arquivo: "eua.json", modulo: "EUA", moeda: "USD", simbolo: "US$" },
};

function projecao(def) {
  const p = def.projecao;
  const tipos = { geoMercator: d3.geoMercator, geoConicEqualArea: d3.geoConicEqualArea, geoAzimuthalEqualArea: d3.geoAzimuthalEqualArea };
  let proj = tipos[p.type]().rotate(p.rotate).scale(p.scale).translate(p.translate);
  if (p.parallels) proj = proj.parallels(p.parallels);
  return proj;
}

const lua = (v) => {
  if (v === null || v === undefined) return "nil";
  if (typeof v === "string") return JSON.stringify(v);
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "number") return Number.isInteger(v) ? String(v) : String(Math.round(v * 1000) / 1000);
  // texto nos dois idiomas
  if (typeof v === "object" && typeof v.pt === "string") return `{ pt = ${lua(v.pt)}, en = ${lua(v.en)} }`;
  throw new Error("tipo não suportado: " + typeof v);
};

for (const [id, cfg] of Object.entries(MAPAS)) {
  const dados = JSON.parse(fs.readFileSync(path.join(AQUI, cfg.arquivo), "utf8"));
  const proj = projecao(projecoes[id]);
  const est = Object.fromEntries(dados.estacoes.map((e) => [e.id, e]));

  // validações
  for (const l of dados.linhas) for (const t of l.trechos) {
    for (const k of [t.de, t.para]) if (!est[k]) throw new Error(`Estação desconhecida "${k}" na linha ${l.id}`);
    if (!dados.terrenos[t.terreno]) throw new Error(`Terreno desconhecido "${t.terreno}" em ${l.id}`);
  }
  for (const l of dados.linhas) {
    if (!Number.isInteger(l.degrau)) throw new Error(`Linha ${l.id} sem "degrau"`);
    // os trens andam pela linha de ponta a ponta: cada trecho tem que começar onde o anterior termina
    l.trechos.forEach((t, i) => { if (i > 0 && l.trechos[i - 1].para !== t.de) throw new Error(`Linha ${l.id}: trecho ${i + 1} não continua o anterior`); });
  }
  for (const e of dados.estacoes) {
    if (e.porte < 3 && !e.paisagem) throw new Error(`Estação ${e.id} sem "paisagem"`);
    if (!dados.estados[e.uf]) throw new Error(`Estação ${e.id} sem "uf" válida`);
    if (!e.historia?.pt || !e.historia?.en) throw new Error(`Estação ${e.id} sem "historia" (pt e en)`);
  }

  // km pelo traçado: de -> pontos de "via" (desvios para o trilho não cortar o mar) -> para
  const km = (a, b, via = []) => {
    const pts = [[est[a].lon, est[a].lat], ...via, [est[b].lon, est[b].lat]];
    let rad = 0;
    for (let i = 1; i < pts.length; i++) rad += d3.geoDistance(pts[i - 1], pts[i]);
    return Math.round(rad * 6371 * SINUOSIDADE);
  };
  // Linhas históricas em ordem de ano; depois, as do Gabinete de Projetos na ordem da lista de projetos.
  const ordemProjeto = Object.fromEntries((dados.projetos ?? []).map((p, i) => [p.id, i]));
  for (const l of dados.linhas) if (l.projeto && ordemProjeto[l.projeto] === undefined) throw new Error(`Projeto desconhecido "${l.projeto}" na linha ${l.id}`);
  const historicas = dados.linhas.filter((l) => !l.projeto).sort((a, b) => a.ano - b.ano);
  const projetadas = dados.linhas.filter((l) => l.projeto).sort((a, b) => ordemProjeto[a.projeto] - ordemProjeto[b.projeto]);
  const linhas = [...historicas, ...projetadas];

  const L = [];
  L.push(`-- ${cfg.modulo}.luau · GERADO por tools/dados/gerar.mjs a partir de tools/dados/${cfg.arquivo}. Não editar à mão.`);
  L.push(`-- Posições em pixels do mapa completo (${projecoes[id].largura}x${projecoes[id].altura}), na mesma projeção dos tiles.`);
  L.push(`-- Custos provisórios (economia ainda não balanceada).`);
  L.push("");
  L.push("return {");
  L.push(`\tid = ${lua(id)},`);
  L.push(`\tmoeda = ${lua(cfg.moeda)},`);
  L.push(`\tsimbolo = ${lua(cfg.simbolo)},`);
  // anos de cada era neste país (a data no jogo e o rótulo das eras); sem isso, os de Economia.ERAS
  if (dados.anos) {
    L.push("\tanos = {");
    for (const [era, [ini, fim]] of Object.entries(dados.anos)) L.push(`\t\t${era} = { ${ini}, ${fim} },`);
    L.push("\t},");
  }
  // linhas completas para liberar cada era neste país; sem isso, as de Economia.ERAS
  if (dados.metasEra) {
    L.push("\tmetasEra = {");
    for (const [era, n] of Object.entries(dados.metasEra)) L.push(`\t\t${era} = ${n},`);
    L.push("\t},");
  }
  L.push("\tterrenos = {");
  for (const [tid, t] of Object.entries(dados.terrenos)) L.push(`\t\t${tid} = { nome = ${lua(t.nome)}, nomes = { pt = ${lua(t.nome)}, en = ${lua(t.nomeEn ?? t.nome)} }, custo = ${lua(t.custo)} },`);
  L.push("\t},");
  L.push("\testacoes = {");
  for (const e of dados.estacoes) {
    const [x, y] = proj([e.lon, e.lat]);
    L.push(`\t\t${e.id} = { nome = ${lua(e.nome)}, nomeEn = ${lua(e.nomeEn)}, pos = Vector2.new(${x.toFixed(1)}, ${y.toFixed(1)}), lon = ${lua(e.lon)}, lat = ${lua(e.lat)}, porte = ${lua(e.porte)}, produz = ${lua(e.produz)}, porto = ${lua(!!e.porto)}, paisagem = ${lua(e.paisagem)}, estado = ${lua(dados.estados[e.uf][0])}, regiao = ${lua(dados.estados[e.uf][1])}, historia = { pt = ${lua(e.historia.pt)}, en = ${lua(e.historia.en)} } },`);
  }
  L.push("\t},");
  // Enquadramento inicial da câmera: as estações das linhas listadas em "foco".
  if (dados.foco) {
    const pts = dados.linhas.filter((l) => dados.foco.includes(l.id)).flatMap((l) => l.trechos.flatMap((t) => [t.de, t.para])).map((k) => proj([est[k].lon, est[k].lat]));
    const xs = pts.map((q) => q[0]), ys = pts.map((q) => q[1]);
    L.push(`\tfoco = { min = Vector2.new(${Math.min(...xs).toFixed(1)}, ${Math.min(...ys).toFixed(1)}), max = Vector2.new(${Math.max(...xs).toFixed(1)}, ${Math.max(...ys).toFixed(1)}) },`);
  }
  // Regiões do país (nome em cada idioma), usadas nas fichas das cidades.
  L.push("\tregioes = {");
  for (const [k, v] of Object.entries(dados.regioes)) L.push(`\t\t${k} = { pt = ${lua(v.pt)}, en = ${lua(v.en)} },`);
  L.push("\t},");
  L.push("\tlinhas = {");
  linhas.forEach((l, ordem) => {
    // o degrau (onda) da linha define o preço por km, o prazo de retorno e quando ela libera
    const degrau = l.degrau;
    const fator = CUSTO_POR_KM * Math.pow(CRESCIMENTO_LINHA, degrau);
    L.push("\t\t{");
    L.push(`\t\t\tid = ${lua(l.id)}, nome = ${lua(l.nome)}, nomeEn = ${lua(l.nomeEn)}, ano = ${lua(l.ano)}, cor = ${lua(l.cor)}, ordem = ${ordem + 1}, degrau = ${degrau}, projeto = ${lua(l.projeto)}, nota = ${lua(l.nota)},`);
    L.push("\t\t\ttrechos = {");
    l.trechos.forEach((t, i) => {
      const k = km(t.de, t.para, t.via);
      const custo = Math.round(k * fator * dados.terrenos[t.terreno].custo);
      let s = `\t\t\t\t{ id = ${lua(`${l.id}_${i + 1}`)}, de = ${lua(t.de)}, para = ${lua(t.para)}, ano = ${lua(t.ano)}, km = ${k}, terreno = ${lua(t.terreno)}, custo = ${custo}, degrau = ${degrau}`;
      if (t.via) {
        const vs = t.via.map((p) => { const [x, y] = proj(p); return `Vector2.new(${x.toFixed(1)}, ${y.toFixed(1)})`; });
        s += `, via = { ${vs.join(", ")} }`;
      }
      if (t.alternativas) {
        const alts = t.alternativas.map((a) => {
          const ka = Math.round(k * a.fatorKm);
          const ca = Math.round(ka * fator * dados.terrenos[a.terreno].custo);
          return `{ id = ${lua(a.id)}, nome = ${lua(a.nome)}, descricao = ${lua(a.descricao)}, terreno = ${lua(a.terreno)}, km = ${ka}, custo = ${ca}, fatorDemanda = ${lua(a.fatorDemanda)}, historico = ${lua(a.historico)} }`;
        });
        s += `,\n\t\t\t\t\talternativas = {\n\t\t\t\t\t\t${alts.join(",\n\t\t\t\t\t\t")},\n\t\t\t\t\t}`;
      }
      L.push(s + " },");
    });
    L.push("\t\t\t},");
    L.push("\t\t},");
  });
  L.push("\t},");
  // Gabinete de Projetos: ferrovias planejadas que nunca saíram (ou não saíram inteiras) do papel.
  L.push("\tprojetos = {");
  for (const p of dados.projetos ?? []) {
    const r = p.requer ?? {};
    if (r.projeto && ordemProjeto[r.projeto] === undefined) throw new Error(`Projeto requer desconhecido "${r.projeto}"`);
    const linha = linhas.find((l) => l.projeto === p.id);
    if (!linha) throw new Error(`Projeto ${p.id} sem linha`);
    L.push(`\t\t{ id = ${lua(p.id)}, nome = ${lua(p.nome)}, nomeEn = ${lua(p.nomeEn)}, emoji = ${lua(p.emoji)}, linha = ${lua(linha.id)}, custo = ${lua(p.custo)}, segundos = ${lua(Math.round(p.minutos * 60))}, ficticio = ${lua(!!p.ficticio)}, descricao = ${lua(p.descricao)}, requer = { linhasCompletas = ${lua(r.linhasCompletas)}, era = ${lua(r.era)}, projeto = ${lua(r.projeto)} } },`);
  }
  L.push("\t},");
  // Rótulos do mapa (estados, regiões, rios, oceano). Estados e oceano com letras espaçadas, estilo carta antiga.
  const espacar = (t) => t.split("\n").map((linha) => [...linha].join(" ").replace(/   /g, "    ")).join("\n");
  L.push("\trotulos = {");
  for (const r of dados.rotulos ?? []) {
    const [x, y] = proj([r.lon, r.lat]);
    const espacado = r.tipo === "estado" || r.tipo === "oceano";
    const texto = espacado ? espacar(r.texto) : r.texto;
    const textoEn = r.textoEn ? (espacado ? espacar(r.textoEn) : r.textoEn) : texto;
    L.push(`\t\t{ tipo = ${lua(r.tipo)}, texto = ${lua(texto)}, textoEn = ${lua(textoEn)}, pos = Vector2.new(${x.toFixed(1)}, ${y.toFixed(1)}), angulo = ${lua(r.angulo ?? 0)}, zoomMin = ${lua(r.zoomMin ?? 0)}, zoomMax = ${lua(r.zoomMax ?? 99)} },`);
  }
  L.push("\t},");
  L.push("}");
  L.push("");
  fs.mkdirSync(SAIDA, { recursive: true });
  fs.writeFileSync(path.join(SAIDA, `${cfg.modulo}.luau`), L.join("\n"));
  console.log(`${cfg.modulo}.luau: ${dados.estacoes.length} estações, ${linhas.length} linhas, ${linhas.reduce((n, l) => n + l.trechos.length, 0)} trechos`);
}
