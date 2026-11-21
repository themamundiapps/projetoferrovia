// Auxiliar: projeta o traçado de cada trecho (de -> via -> para) em pixels do mapa, para conferir se corta o mar.
// Uso: node tools/dados/proj_trechos.mjs [mapa] > /tmp/trechos.json   (mapa: brasil, eua; padrão brasil)
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as d3 from "d3-geo";
const AQUI = path.dirname(fileURLToPath(import.meta.url));
const MAPA = process.argv[2] ?? "brasil";
const p = JSON.parse(fs.readFileSync(path.join(AQUI, "projecoes.json"), "utf8"))[MAPA].projecao;
const tipos = { geoMercator: d3.geoMercator, geoConicEqualArea: d3.geoConicEqualArea, geoAzimuthalEqualArea: d3.geoAzimuthalEqualArea };
let proj = tipos[p.type]().rotate(p.rotate).scale(p.scale).translate(p.translate);
if (p.parallels) proj = proj.parallels(p.parallels);
const dados = JSON.parse(fs.readFileSync(path.join(AQUI, `${MAPA}.json`), "utf8"));
const est = Object.fromEntries(dados.estacoes.map((e) => [e.id, e]));
const out = [];
for (const l of dados.linhas) l.trechos.forEach((t, i) => {
  const pts = [[est[t.de].lon, est[t.de].lat], ...(t.via || []), [est[t.para].lon, est[t.para].lat]].map((q) => proj(q));
  out.push({ id: `${l.id}_${i + 1}`, de: est[t.de].nome, para: est[t.para].nome, pts });
});
console.log(JSON.stringify(out));
