// Gera os caminhos SVG da grade de detalhe (alta resolução) de um mapa, uma faixa (linha da grade) por vez.
// Mesma projeção do mapa base, multiplicada por ESCALA. Estilos e renderização: render_detalhes.py.
// A grade cobre só as células por onde passam trilhos (calculadas por render_detalhes.py --grade).
// Uso: node detalhe_grade.mjs <grade.json> <saida.json> [brasil|eua]
import fs from "node:fs";
import * as d3 from "d3-geo";
import * as topojson from "topojson-client";
import { topology } from "topojson-server";

const AQUI = new URL(".", import.meta.url);
const grade = JSON.parse(fs.readFileSync(process.argv[2]));
const MAPA = process.argv[4] ?? "brasil";
const proj = JSON.parse(fs.readFileSync(new URL("../dados/projecoes.json", AQUI)))[MAPA].projecao;
const world = JSON.parse(fs.readFileSync(new URL("node_modules/world-atlas/countries-10m.json", AQUI)));
const rios = JSON.parse(fs.readFileSync(new URL("naturalearth/ne_10m_rivers_lake_centerlines.geojson", AQUI)));
const admArq = new URL("naturalearth/ne_50m_admin_1_states_provinces.geojson", AQUI);
const adm = fs.existsSync(admArq) ? JSON.parse(fs.readFileSync(admArq)) : { features: [] };

// mesma lista de feicoes.mjs
const RIOS_BR = new Set(["Paraná", "Tietê", "Paraiba", "Grande", "Paranapanema", "Doce", "Velhas", "São  Francisco",
  "Paranaíba", "Ribeira", "Pardo", "Jequitinhonha", "Amazonas", "Solimões", "Madeira", "Tocantins", "Araguaia",
  "Xingu", "Tapajós", "Negro", "Paraguay", "Uruguay", "Iguaçu", "Parnaíba", "Teles Pires", "Juruena", "Mamoré", "Guaporé"]);
// mesma lista de tools/dados/rios_mapa.mjs
const RIOS_EUA = new Set(["Mississippi", "Missouri", "Ohio", "Arkansas", "Red", "Platte", "Colorado", "Columbia", "Snake",
  "Rio Grande", "Tennessee", "Hudson", "Susquehanna", "Potomac", "Sacramento", "San Joaquin", "Yellowstone",
  "Cumberland", "Illinois", "Wabash", "Kansas", "Canadian", "Brazos", "Alabama", "Savannah", "Connecticut", "Gila", "Green"]);
const FOCO = MAPA === "eua" ? "United States of America" : "Brazil";
// países do mapa da Europa (a mesma lista de maps.mjs)
const EUROPA = new Set(["Portugal","Spain","France","Belgium","Netherlands","Luxembourg","Germany","Switzerland","Austria","Italy",
 "United Kingdom","Ireland","Denmark","Norway","Sweden","Finland","Poland","Czechia","Slovakia","Hungary","Slovenia","Croatia",
 "Bosnia and Herz.","Serbia","Montenegro","Kosovo","Albania","Macedonia","North Macedonia","Greece","Bulgaria","Romania","Moldova",
 "Lithuania","Latvia","Estonia","Liechtenstein","Andorra","Monaco","San Marino","Vatican","Malta","Cyprus","Iceland"]);
const RIOS_EUROPA = new Set(["Danube", "Rhine", "Seine", "Oder", "Elbe", "Ebro", "Tajo", "Tejo", "Vistula", "Daugava", "Rhône",
  "Thames", "Duero", "Garonne", "Loire", "Po", "Severn", "Guadiana", "Tevere", "Sava", "Weser", "Neman",
  "Inn", "Main", "Guadalquivir", "Trent", "Maas"]);

const paises = topojson.feature(world, world.objects.countries);
let fronteiras = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (a.properties.name === FOCO || b.properties.name === FOCO));
let foco, contorno, divisas, riosMapa;
if (MAPA === "europa") {
  const ehEu = (f) => EUROPA.has(f.properties.name);
  foco = { type: "FeatureCollection", features: paises.features.filter(ehEu) };
  contorno = topojson.merge(world, world.objects.countries.geometries.filter(ehEu));
  fronteiras = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (ehEu(a) || ehEu(b)));
  divisas = { type: "MultiLineString", coordinates: [] };
  const dentro = ([lon, lat]) => lon > -11 && lon < 32 && lat > 35 && lat < 62;
  riosMapa = rios.features.filter((f) => RIOS_EUROPA.has(f.properties.name) && f.properties.scalerank <= 8)
    .filter((f) => (f.geometry.type === "LineString" ? f.geometry.coordinates : f.geometry.coordinates.flat()).some(dentro));
} else if (MAPA === "eua") {
  // 48 estados (us-atlas), como no mapa base
  const us = JSON.parse(fs.readFileSync(new URL("node_modules/us-atlas/states-10m.json", AQUI)));
  const fora = new Set(["02", "15", "60", "66", "69", "72", "78"]);
  const estados = topojson.feature(us, us.objects.states);
  foco = { type: "FeatureCollection", features: estados.features.filter((f) => !fora.has(f.id)) };
  contorno = topojson.merge(us, us.objects.states.geometries.filter((g) => !fora.has(g.id)));
  divisas = topojson.mesh(us, us.objects.states, (a, b) => a !== b && !fora.has(a.id) && !fora.has(b.id));
  const dentro = ([lon, lat]) => lon > -126 && lon < -66 && lat > 24 && lat < 50;
  riosMapa = rios.features.filter((f) => RIOS_EUA.has(f.properties.name) && f.properties.scalerank <= 7)
    .filter((f) => (f.geometry.type === "LineString" ? f.geometry.coordinates : f.geometry.coordinates.flat()).some(dentro));
} else {
  foco = { type: "FeatureCollection", features: paises.features.filter((f) => f.properties.name === FOCO) };
  contorno = topojson.merge(world, world.objects.countries.geometries.filter((g) => g.properties.name === FOCO));
  const br = { type: "FeatureCollection", features: adm.features.filter((f) => f.properties.admin === "Brazil") };
  const topo = topology({ s: br }, 1e5);
  divisas = topojson.mesh(topo, topo.objects.s, (a, b) => a !== b);
  riosMapa = rios.features.filter((f) => RIOS_BR.has(f.properties.name) && f.properties.scalerank <= 8);
}

const { C, ox, oy, escala, celulas } = grade;
const cxs = celulas.map((c) => c[0]);
const cx0 = Math.min(...cxs), cx1 = Math.max(...cxs);
const faixas = [...new Set(celulas.map((c) => c[1]))].sort((a, b) => a - b);
const out = [];
for (const cy of faixas) {
  const x0 = ox + C * cx0, y0 = oy + C * cy;
  const tipos = { geoMercator: d3.geoMercator, geoConicEqualArea: d3.geoConicEqualArea, geoAzimuthalEqualArea: d3.geoAzimuthalEqualArea };
  let P = tipos[proj.type ?? "geoMercator"]();
  if (proj.rotate) P = P.rotate(proj.rotate);
  if (proj.parallels) P = P.parallels(proj.parallels);
  P = P.scale(proj.scale * escala).translate([(proj.translate[0] - x0) * escala, (proj.translate[1] - y0) * escala]);
  const path = d3.geoPath(P);
  out.push({
    cy, x0, y0, cx0, w: (cx1 - cx0 + 1) * C * escala, h: C * escala,
    landAll: path(paises), focus: path(foco), outline: path(contorno), borders: path(fronteiras), divisas: path(divisas) ?? "",
    rios: riosMapa.map((f) => ({ rank: f.properties.scalerank, d: path(f) })).filter((r) => r.d),
  });
  console.log("faixa", cy, out.at(-1).w + "x" + out.at(-1).h);
}
fs.writeFileSync(process.argv[3], JSON.stringify(out));
