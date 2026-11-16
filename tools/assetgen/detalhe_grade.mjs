// Gera os caminhos SVG da grade de detalhe (alta resolução) do Brasil, uma faixa (linha da grade) por vez.
// Mesma projeção do mapa base, multiplicada por ESCALA. Estilos e renderização: render_detalhes.py.
// A grade cobre só as células por onde passam trilhos (calculadas por render_detalhes.py --grade).
// Uso: node detalhe_grade.mjs <grade.json> <saida.json>
import fs from "node:fs";
import * as d3 from "d3-geo";
import * as topojson from "topojson-client";
import { topology } from "topojson-server";

const AQUI = new URL(".", import.meta.url);
const grade = JSON.parse(fs.readFileSync(process.argv[2]));
const proj = JSON.parse(fs.readFileSync(new URL("../dados/projecoes.json", AQUI))).brasil.projecao;
const world = JSON.parse(fs.readFileSync(new URL("node_modules/world-atlas/countries-10m.json", AQUI)));
const rios = JSON.parse(fs.readFileSync(new URL("naturalearth/ne_10m_rivers_lake_centerlines.geojson", AQUI)));
const adm = JSON.parse(fs.readFileSync(new URL("naturalearth/ne_50m_admin_1_states_provinces.geojson", AQUI)));

// mesma lista de feicoes.mjs
const RIOS_BR = new Set(["Paraná", "Tietê", "Paraiba", "Grande", "Paranapanema", "Doce", "Velhas", "São  Francisco",
  "Paranaíba", "Ribeira", "Pardo", "Jequitinhonha", "Amazonas", "Solimões", "Madeira", "Tocantins", "Araguaia",
  "Xingu", "Tapajós", "Negro", "Paraguay", "Uruguay", "Iguaçu", "Parnaíba", "Teles Pires", "Juruena", "Mamoré", "Guaporé"]);
const FOCO = "Brazil";

const paises = topojson.feature(world, world.objects.countries);
const foco = { type: "FeatureCollection", features: paises.features.filter((f) => f.properties.name === FOCO) };
const contorno = topojson.merge(world, world.objects.countries.geometries.filter((g) => g.properties.name === FOCO));
const fronteiras = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (a.properties.name === FOCO || b.properties.name === FOCO));
const br = { type: "FeatureCollection", features: adm.features.filter((f) => f.properties.admin === "Brazil") };
const topo = topology({ s: br }, 1e5);
const divisas = topojson.mesh(topo, topo.objects.s, (a, b) => a !== b);
const riosBR = rios.features.filter((f) => RIOS_BR.has(f.properties.name) && f.properties.scalerank <= 8);

const { C, ox, oy, escala, celulas } = grade;
const cxs = celulas.map((c) => c[0]);
const cx0 = Math.min(...cxs), cx1 = Math.max(...cxs);
const faixas = [...new Set(celulas.map((c) => c[1]))].sort((a, b) => a - b);
const out = [];
for (const cy of faixas) {
  const x0 = ox + C * cx0, y0 = oy + C * cy;
  const P = d3.geoMercator().scale(proj.scale * escala).translate([(proj.translate[0] - x0) * escala, (proj.translate[1] - y0) * escala]);
  const path = d3.geoPath(P);
  out.push({
    cy, x0, y0, cx0, w: (cx1 - cx0 + 1) * C * escala, h: C * escala,
    landAll: path(paises), focus: path(foco), outline: path(contorno), borders: path(fronteiras), divisas: path(divisas),
    rios: riosBR.map((f) => ({ rank: f.properties.scalerank, d: path(f) })).filter((r) => r.d),
  });
  console.log("faixa", cy, out.at(-1).w + "x" + out.at(-1).h);
}
fs.writeFileSync(process.argv[3], JSON.stringify(out));
