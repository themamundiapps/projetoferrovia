// Gera os caminhos SVG de uma região de detalhe (alta resolução) de um mapa,
// usando a MESMA projeção do mapa base, multiplicada por um fator de escala.
// Uso: node detalhe.mjs <saida.json>
import fs from "node:fs";
import * as d3 from "d3-geo";
import * as topojson from "topojson-client";

const REGIOES = [
  // Sudeste do Brasil: cobre as 5 linhas do MVP. Caixa em pixels do mapa base (2048x2048).
  { mapa: "brasil", id: "sudeste", x0: 1232, y0: 1168, largura: 512, altura: 336, escala: 4, foco: "Brazil" },
];

const proj = JSON.parse(fs.readFileSync(new URL("../dados/projecoes.json", import.meta.url)));
const world = JSON.parse(fs.readFileSync("node_modules/world-atlas/countries-10m.json"));
const land = topojson.feature(world, world.objects.land ?? world.objects.countries);
const paises = topojson.feature(world, world.objects.countries);

const out = [];
for (const r of REGIOES) {
  const p = proj[r.mapa].projecao;
  const projecao = d3.geoMercator()
    .scale(p.scale * r.escala)
    .translate([(p.translate[0] - r.x0) * r.escala, (p.translate[1] - r.y0) * r.escala]);
  const path = d3.geoPath(projecao);
  const foco = paises.features.filter((f) => f.properties.name === r.foco);
  const fronteiras = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (a.properties.name === r.foco || b.properties.name === r.foco));
  out.push({
    ...r,
    w: r.largura * r.escala,
    h: r.altura * r.escala,
    landAll: path(topojson.feature(world, world.objects.countries)),
    focus: path({ type: "FeatureCollection", features: foco }),
    outline: path(topojson.merge(world, world.objects.countries.geometries.filter((g) => g.properties.name === r.foco))),
    borders: path(fronteiras),
  });
}
fs.writeFileSync(process.argv[2] ?? "detalhe.json", JSON.stringify(out));
console.log(out.map((r) => `${r.mapa}/${r.id}: ${r.w}x${r.h}`).join("\n"));
