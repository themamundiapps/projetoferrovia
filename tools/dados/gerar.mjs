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
const CRESCIMENTO_LINHA = 1.7; // cada linha nova (em ordem histórica) custa ~70% mais por km
const SINUOSIDADE = 1.25;      // trilho real é mais longo que a linha reta

const MAPAS = { brasil: { arquivo: "brasil.json", modulo: "Brasil", moeda: "BRL", simbolo: "R$" } };

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

  const km = (a, b) => Math.round(d3.geoDistance([est[a].lon, est[a].lat], [est[b].lon, est[b].lat]) * 6371 * SINUOSIDADE);
  const linhas = [...dados.linhas].sort((a, b) => a.ano - b.ano);

  const L = [];
  L.push(`-- ${cfg.modulo}.luau · GERADO por tools/dados/gerar.mjs a partir de tools/dados/${cfg.arquivo}. Não editar à mão.`);
  L.push(`-- Posições em pixels do mapa completo (${projecoes[id].largura}x${projecoes[id].altura}), na mesma projeção dos tiles.`);
  L.push(`-- Custos provisórios (economia ainda não balanceada).`);
  L.push("");
  L.push("return {");
  L.push(`\tid = ${lua(id)},`);
  L.push(`\tmoeda = ${lua(cfg.moeda)},`);
  L.push(`\tsimbolo = ${lua(cfg.simbolo)},`);
  L.push("\tterrenos = {");
  for (const [tid, t] of Object.entries(dados.terrenos)) L.push(`\t\t${tid} = { nome = ${lua(t.nome)}, custo = ${lua(t.custo)} },`);
  L.push("\t},");
  L.push("\testacoes = {");
  for (const e of dados.estacoes) {
    const [x, y] = proj([e.lon, e.lat]);
    L.push(`\t\t${e.id} = { nome = ${lua(e.nome)}, pos = Vector2.new(${x.toFixed(1)}, ${y.toFixed(1)}), lon = ${lua(e.lon)}, lat = ${lua(e.lat)}, porte = ${lua(e.porte)}, produz = ${lua(e.produz)}, porto = ${lua(!!e.porto)} },`);
  }
  L.push("\t},");
  L.push("\tlinhas = {");
  linhas.forEach((l, ordem) => {
    const fator = CUSTO_POR_KM * Math.pow(CRESCIMENTO_LINHA, ordem);
    L.push("\t\t{");
    L.push(`\t\t\tid = ${lua(l.id)}, nome = ${lua(l.nome)}, ano = ${lua(l.ano)}, cor = ${lua(l.cor)}, ordem = ${ordem + 1},`);
    L.push("\t\t\ttrechos = {");
    l.trechos.forEach((t, i) => {
      const k = km(t.de, t.para);
      const custo = Math.round(k * fator * dados.terrenos[t.terreno].custo);
      let s = `\t\t\t\t{ id = ${lua(`${l.id}_${i + 1}`)}, de = ${lua(t.de)}, para = ${lua(t.para)}, ano = ${lua(t.ano)}, km = ${k}, terreno = ${lua(t.terreno)}, custo = ${custo}`;
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
  // Rótulos do mapa (estados, regiões, rios, oceano). Estados e oceano com letras espaçadas, estilo carta antiga.
  const espacar = (t) => t.split("\n").map((linha) => [...linha].join(" ").replace(/   /g, "    ")).join("\n");
  L.push("\trotulos = {");
  for (const r of dados.rotulos ?? []) {
    const [x, y] = proj([r.lon, r.lat]);
    const texto = r.tipo === "estado" || r.tipo === "oceano" ? espacar(r.texto) : r.texto;
    L.push(`\t\t{ tipo = ${lua(r.tipo)}, texto = ${lua(texto)}, pos = Vector2.new(${x.toFixed(1)}, ${y.toFixed(1)}), angulo = ${lua(r.angulo ?? 0)}, zoomMin = ${lua(r.zoomMin ?? 0)}, zoomMax = ${lua(r.zoomMax ?? 99)} },`);
  }
  L.push("\t},");
  L.push("}");
  L.push("");
  fs.mkdirSync(SAIDA, { recursive: true });
  fs.writeFileSync(path.join(SAIDA, `${cfg.modulo}.luau`), L.join("\n"));
  console.log(`${cfg.modulo}.luau: ${dados.estacoes.length} estações, ${linhas.length} linhas, ${linhas.reduce((n, l) => n + l.trechos.length, 0)} trechos`);
}
