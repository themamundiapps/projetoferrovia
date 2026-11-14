// Feições geográficas (rios e divisas de estados) para o mapa base e as regiões de detalhe.
// Mesma projeção dos tiles. Saída: JSON com caminhos SVG, renderizado por render_feicoes.py.
//
// Dados: Natural Earth (domínio público). Se a pasta naturalearth/ não existir, baixe:
//   https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson
//   https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_1_states_provinces.geojson
// Uso: node feicoes.mjs <saida.json>
import fs from "node:fs";
import * as d3 from "d3-geo";
import * as topojson from "topojson-client";
import { topology } from "topojson-server";

const AQUI = new URL(".", import.meta.url);
const proj = JSON.parse(fs.readFileSync(new URL("../dados/projecoes.json", AQUI))).brasil;
const rios = JSON.parse(fs.readFileSync(new URL("naturalearth/ne_10m_rivers_lake_centerlines.geojson", AQUI)));
const adm = JSON.parse(fs.readFileSync(new URL("naturalearth/ne_50m_admin_1_states_provinces.geojson", AQUI)));

// Rios mostrados. rankMax: no mapa inteiro só os maiores; no detalhe, também os médios.
const RIOS_BR = new Set(["Paraná", "Tietê", "Paraiba", "Grande", "Paranapanema", "Doce", "Velhas", "São  Francisco",
  "Paranaíba", "Ribeira", "Pardo", "Jequitinhonha", "Amazonas", "Solimões", "Madeira", "Tocantins", "Araguaia",
  "Xingu", "Tapajós", "Negro", "Paraguay", "Uruguay", "Iguaçu", "Parnaíba", "Teles Pires", "Juruena", "Mamoré", "Guaporé"]);

const ALVOS = [
  { id: "base", escala: 1, x0: 0, y0: 0, w: proj.largura, h: proj.altura, rankMax: 6 },
  { id: "sudeste", escala: 4, x0: 1232, y0: 1168, w: 2048, h: 1344, rankMax: 8 },
];

const br = { type: "FeatureCollection", features: adm.features.filter((f) => f.properties.admin === "Brazil") };
const topo = topology({ s: br }, 1e5);
const divisasGeo = topojson.mesh(topo, topo.objects.s, (a, b) => a !== b);

const out = {};
for (const a of ALVOS) {
  const p = proj.projecao;
  const P = d3.geoMercator().scale(p.scale * a.escala).translate([(p.translate[0] - a.x0) * a.escala, (p.translate[1] - a.y0) * a.escala]);
  const path = d3.geoPath(P);
  out[a.id] = {
    ...a,
    divisas: path(divisasGeo),
    rios: rios.features
      .filter((f) => RIOS_BR.has(f.properties.name) && f.properties.scalerank <= a.rankMax)
      .map((f) => ({ nome: f.properties.name, rank: f.properties.scalerank, d: path(f) }))
      .filter((r) => r.d),
  };
}
fs.writeFileSync(process.argv[2] ?? "feicoes.json", JSON.stringify(out));
for (const [k, v] of Object.entries(out)) console.log(k, v.w + "x" + v.h, v.rios.length, "rios");
