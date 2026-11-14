// Gera os caminhos SVG dos mapas base (Brasil, EUA, Europa) e os parâmetros de projeção.
import fs from "node:fs";
import * as d3 from "d3-geo";
import * as topojson from "topojson-client";

const world = JSON.parse(fs.readFileSync("node_modules/world-atlas/countries-50m.json"));
const us = JSON.parse(fs.readFileSync("node_modules/us-atlas/states-10m.json"));
const countries = topojson.feature(world, world.objects.countries);
const land = topojson.feature(world, world.objects.land);

const EUROPE = new Set(["Portugal","Spain","France","Belgium","Netherlands","Luxembourg","Germany","Switzerland","Austria","Italy",
 "United Kingdom","Ireland","Denmark","Norway","Sweden","Finland","Poland","Czechia","Slovakia","Hungary","Slovenia","Croatia",
 "Bosnia and Herz.","Serbia","Montenegro","Kosovo","Albania","Macedonia","North Macedonia","Greece","Bulgaria","Romania","Moldova",
 "Lithuania","Latvia","Estonia","Liechtenstein","Andorra","Monaco","San Marino","Vatican","Malta","Cyprus","Iceland"]);

const PAD = 60;
const out = {};

function mk(name, W, H, projection, fitObj, focusPred, borderMeshes, cities) {
  projection.fitExtent([[PAD, PAD], [W - PAD, H - PAD]], fitObj);
  const path = d3.geoPath(projection);
  const focus = { type: "FeatureCollection", features: countries.features.filter(focusPred) };
  const res = {
    width: W, height: H,
    landAll: path(land),
    focus: path(focus),
    outline: path(topojson.merge(world, world.objects.countries.geometries.filter(g => focusPred({properties: g.properties})))),
    borders: borderMeshes.map(m => path(m)).join(" "),
    projection: {
      type: projection._type, rotate: projection.rotate(), scale: projection.scale(), translate: projection.translate(),
      parallels: projection.parallels ? projection.parallels() : null,
    },
    cities: {},
  };
  for (const [n, lon, lat] of cities) {
    const p = projection([lon, lat]);
    res.cities[n] = [Math.round(p[0]), Math.round(p[1])];
  }
  out[name] = res;
}

// ---- Brasil: Mercator, 2048x2048
{
  const p = d3.geoMercator(); p._type = "geoMercator";
  const br = countries.features.find(f => f.properties.name === "Brazil");
  const borders = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (a.properties.name === "Brazil" || b.properties.name === "Brazil"));
  mk("brasil", 2048, 2048, p, br, f => f.properties.name === "Brazil", [borders], [
    ["São Paulo",-46.63,-23.55],["Rio de Janeiro",-43.2,-22.9],["Santos",-46.33,-23.96],["Belo Horizonte",-43.94,-19.92],
    ["Brasília",-47.88,-15.79],["Salvador",-38.5,-12.97],["Recife",-34.88,-8.05],["Fortaleza",-38.52,-3.73],["Belém",-48.5,-1.45],
    ["Manaus",-60.02,-3.12],["Porto Alegre",-51.23,-30.03],["Curitiba",-49.27,-25.43],["Corumbá",-57.65,-19.01],["Porto Velho",-63.9,-8.76],
  ]);
}

// ---- EUA (48 estados): Albers, 2048x1280
{
  const p = d3.geoConicEqualArea().parallels([29.5, 45.5]).rotate([96, 0]); p._type = "geoConicEqualArea";
  const states = topojson.feature(us, us.objects.states);
  const skip = new Set(["02", "15", "60", "66", "69", "72", "78"]);
  const lower = { type: "FeatureCollection", features: states.features.filter(f => !skip.has(f.id)) };
  p.fitExtent([[PAD, PAD], [2048 - PAD, 1280 - PAD]], lower);
  const path = d3.geoPath(p);
  const stateBorders = topojson.mesh(us, us.objects.states, (a, b) => a !== b && !skip.has(a.id) && !skip.has(b.id));
  const res = {
    width: 2048, height: 1280,
    landAll: path(land),
    focus: path(lower),
    outline: path(topojson.merge(us, us.objects.states.geometries.filter(g => !skip.has(g.id)))),
    borders: path(stateBorders),
    projection: { type: "geoConicEqualArea", rotate: p.rotate(), scale: p.scale(), translate: p.translate(), parallels: p.parallels() },
    cities: {},
  };
  for (const [n, lon, lat] of [["New York",-74.0,40.71],["Chicago",-87.63,41.88],["Omaha",-95.94,41.26],["Sacramento",-121.49,38.58],
      ["Denver",-104.99,39.74],["New Orleans",-90.07,29.95],["Seattle",-122.33,47.61],["Los Angeles",-118.24,34.05],["Baltimore",-76.61,39.29],["Promontory",-112.55,41.62]]) {
    const q = p([lon, lat]); res.cities[n] = [Math.round(q[0]), Math.round(q[1])];
  }
  out["eua"] = res;
}

// ---- Europa: Lambert azimutal equivalente, 2048x1536
{
  const p = d3.geoAzimuthalEqualArea().rotate([-10, -52]); p._type = "geoAzimuthalEqualArea";
  const box = { type: "MultiPoint", coordinates: [[-10, 36], [30, 36], [-10, 61], [30, 61], [10, 35.5], [10, 62], [-9.5, 50], [31, 50]] };
  const isEu = f => EUROPE.has(f.properties.name);
  const borders = topojson.mesh(world, world.objects.countries, (a, b) => a !== b && (isEu(a) || isEu(b)));
  mk("europa", 2048, 1536, p, box, isEu, [borders], [
    ["London",-0.13,51.51],["Paris",2.35,48.86],["Berlin",13.4,52.52],["Madrid",-3.7,40.42],["Roma",12.5,41.9],["Wien",16.37,48.21],
    ["Amsterdam",4.9,52.37],["Bruxelles",4.35,50.85],["Milano",9.19,45.46],["Lisboa",-9.14,38.72],["Warszawa",21.01,52.23],["Zürich",8.54,47.37],
    ["Stockton",-1.32,54.57],["Liverpool",-2.98,53.41],["Manchester",-2.24,53.48],["Istanbul",28.98,41.01],
  ]);
}

fs.writeFileSync("maps.json", JSON.stringify(out));
for (const [k, v] of Object.entries(out)) console.log(k, v.width, v.height, "focus", v.focus.length, "borders", v.borders.length, JSON.stringify(v.cities).slice(0, 120));
