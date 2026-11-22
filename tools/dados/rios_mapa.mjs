// Rios de um mapa (Natural Earth, domínio público) projetados em pixels do mapa, para render_rios.py.
// Baixe antes: tools/assetgen/naturalearth/ne_10m_rivers_lake_centerlines.geojson
// (https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson)
// Uso: node tools/dados/rios_mapa.mjs eua > /tmp/rios_eua.json
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as d3 from "d3-geo";
const AQUI = path.dirname(fileURLToPath(import.meta.url));
const MAPA = process.argv[2] ?? "eua";
const def = JSON.parse(fs.readFileSync(path.join(AQUI, "projecoes.json"), "utf8"))[MAPA];
const p = def.projecao;
const tipos = { geoMercator: d3.geoMercator, geoConicEqualArea: d3.geoConicEqualArea, geoAzimuthalEqualArea: d3.geoAzimuthalEqualArea };
let proj = tipos[p.type]().rotate(p.rotate).scale(p.scale).translate(p.translate);
if (p.parallels) proj = proj.parallels(p.parallels);
const rios = JSON.parse(fs.readFileSync(path.join(AQUI, "../assetgen/naturalearth/ne_10m_rivers_lake_centerlines.geojson"), "utf8"));
// rios mostrados e a caixa (lon/lat) do país, para não pegar rios homônimos de outros lugares
const CONFIG = {
  eua: {
    nomes: new Set(["Mississippi", "Missouri", "Ohio", "Arkansas", "Red", "Platte", "Colorado", "Columbia", "Snake",
      "Rio Grande", "Tennessee", "Hudson", "Susquehanna", "Potomac", "Sacramento", "San Joaquin", "Yellowstone",
      "Cumberland", "Illinois", "Wabash", "Kansas", "Canadian", "Brazos", "Alabama", "Savannah", "Connecticut", "Gila", "Green"]),
    caixa: [-126, -66, 24, 50],
    rankMax: 7,
  },
};
const cfg = CONFIG[MAPA];
const out = [];
for (const f of rios.features) {
  const g = f.geometry;
  if (!g || !cfg.nomes.has(f.properties.name) || f.properties.scalerank > cfg.rankMax) continue;
  const partes = g.type === "LineString" ? [g.coordinates] : g.type === "MultiLineString" ? g.coordinates : [];
  for (const linha of partes) {
    const dentro = linha.filter(([lon, lat]) => lon > cfg.caixa[0] && lon < cfg.caixa[1] && lat > cfg.caixa[2] && lat < cfg.caixa[3]);
    if (dentro.length < 2) continue;
    out.push({ nome: f.properties.name, rank: f.properties.scalerank, pts: dentro.map((q) => proj(q).map((v) => Math.round(v * 10) / 10)) });
  }
}
console.log(JSON.stringify({ largura: def.largura, altura: def.altura, rios: out }));
