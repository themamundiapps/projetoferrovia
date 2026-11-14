"""Gera Theme.lua, Assets.lua e Mapas.lua a partir das mesmas fontes usadas nos PNGs."""
import json, os, glob
from theme import ERAS

P = "/home/claude/pack"
os.makedirs(f"{P}/lua", exist_ok=True)
misc = json.load(open("/home/claude/work/misc_meta.json"))
maps = json.load(open("/home/claude/work/maps_manifest.json"))

SEA = {"vapor": "mar_hachura", "diesel": "mar_ondas", "eletrico": None, "alta": "mar_pontos"}
PAPER = {"vapor": True, "diesel": True, "eletrico": False, "alta": False}

def q(s): return '"' + str(s) + '"'

# ---------------- Theme.lua ----------------
L = ["-- Theme.lua · gerado automaticamente a partir de theme.py (não editar à mão)",
     "-- Cores, fontes nativas do Roblox e formas de cada era.", "",
     "local Theme = {}", "",
     "local function F(familia, peso)",
     '\treturn Font.new("rbxasset://fonts/families/" .. familia .. ".json", (Enum.FontWeight :: any)[peso])',
     "end", "",
     "Theme.Eras = {"]
for e in ERAS:
    L.append("\t{")
    L.append(f"\t\tid = {q(e['id'])}, nome = {q(e['nome'])}, anos = {q(e['anos'])},")
    L.append("\t\tcores = {")
    for k, v in e["colors"].items():
        L.append(f"\t\t\t{k} = Color3.fromHex({q(v)}),")
    L.append("\t\t},")
    L.append("\t\tlinhas = { " + ", ".join(f"Color3.fromHex({q(c)})" for c in e["lines"]) + " },")
    L.append("\t\tfontes = {")
    for k, (fam, w) in e["fonts"].items():
        L.append(f"\t\t\t{k} = F({q(fam)}, {q(w)}),")
    L.append("\t\t},")
    s = e["shape"]
    L.append(f"\t\tforma = {{ canto = {s['corner']}, traco = {s['stroke']}, molduraDupla = {str(s['doubleFrame']).lower()} }},")
    L.append(f"\t\tmarPadrao = {q(SEA[e['id']]) if SEA[e['id']] else 'nil'},")
    L.append(f"\t\tgraoPapel = {str(PAPER[e['id']]).lower()},")
    L.append("\t},")
L += ["}", "", "Theme.PorId = {}", "for i, era in ipairs(Theme.Eras) do", "\tera.indice = i", "\tTheme.PorId[era.id] = era", "end", "",
      "-- Linhas com cor clara precisam de contorno escuro (UIStroke 2 px na cor ink) para contraste sobre a terra.",
      "Theme.ContornoLinha = 2", "", "return Theme", ""]
open(f"{P}/lua/Theme.lua", "w").write("\n".join(L))

# ---------------- Assets.lua ----------------
files = sorted(glob.glob(f"{P}/*/*.png"))
L = ["-- Assets.lua · ids das imagens. Depois do Bulk Import, cole cada rbxassetid no lugar do 0.",
     "-- Todas as imagens (exceto identidade/) são brancas: tingir com ImageColor3 usando a cor da era.", "",
     "local Assets = {}", "", "Assets.Ids = {"]
cur = None
for f in files:
    folder = os.path.basename(os.path.dirname(f))
    if folder in ("mapas", "icones"): continue
    if folder == "identidade" and not os.path.basename(f).startswith("logo"): continue
    if folder != cur:
        L.append(f"\t-- {folder}"); cur = folder
    name = os.path.splitext(os.path.basename(f))[0]
    L.append(f'\t{name} = "rbxassetid://0",')
L += ["}", "",
      "-- Ícones dentro de atlas/icones_atlas.png (128 x 128 cada).",
      "-- Uso: imagem.Image = Assets.Ids.icones_atlas; imagem.ImageRectOffset = r.offset; imagem.ImageRectSize = r.size",
      "Assets.Atlas = {"]
for n, (x, y, w, h) in misc["atlas_icones"].items():
    L.append(f"\t{n} = {{ offset = Vector2.new({x}, {y}), size = Vector2.new({w}, {h}) }},")
L += ["}", "", "-- Configuração de 9-slice e tiles.", "Assets.Slice = {"]
for n, m in misc["uso"].items():
    if "SliceCenter" in m:
        a, b, c, d = m["SliceCenter"]
        L.append(f"\t{n} = Rect.new({a}, {b}, {c}, {d}),")
L += ["}", "", "Assets.Tile = {"]
for n, m in misc["uso"].items():
    if "TileSize" in m:
        L.append(f"\t{n} = {m['TileSize']},")
L += ["}", "", "return Assets", ""]
open(f"{P}/lua/Assets.lua", "w").write("\n".join(L))

# ---------------- Mapas.lua ----------------
L = ["-- Mapas.lua · tiles dos mapas base e a projeção usada para gerá-los.",
     "-- Camadas (de baixo para cima): fundo do mar (cor + textura) -> terra (tingir com land) -> linhas (tingir com coast).",
     "-- Na terra, o país/região jogável é opaco; os vizinhos têm alfa 0.45 e ficam entre a cor do mar e a da terra.",
     "-- As coordenadas em 'cidades' são pixels do mapa completo; o pipeline de dados usa a mesma projeção (d3-geo).", "",
     "local Mapas = {}", ""]
for name, m in maps.items():
    pj = m["projecao"]
    L.append(f"Mapas.{name} = {{")
    L.append(f"\tlargura = {m['largura']}, altura = {m['altura']},")
    par = ", ".join(str(round(v, 4)) for v in pj["parallels"]) if pj.get("parallels") else ""
    L.append(f"\tprojecao = {{ tipo = {q(pj['type'])}, rotacao = {{ {', '.join(str(round(v,4)) for v in pj['rotate'])} }}, escala = {round(pj['scale'],4)}, translacao = {{ {', '.join(str(round(v,4)) for v in pj['translate'])} }}" + (f", paralelos = {{ {par} }}" if par else "") + " },")
    L.append("\ttiles = {")
    for t in m["tiles"]:
        L.append(f'\t\t{{ camada = {q(t["camada"])}, x = {t["x"]}, y = {t["y"]}, w = {t["w"]}, h = {t["h"]}, id = "rbxassetid://0", arquivo = {q(t["arquivo"])} }},')
    L.append("\t},")
    L.append("\tcidades = {")
    for c, (x, y) in m["cidades_px"].items():
        L.append(f'\t\t[{q(c)}] = Vector2.new({x}, {y}),')
    L.append("\t},")
    L.append("}")
    L.append("")
L += ["return Mapas", ""]
open(f"{P}/lua/Mapas.lua", "w").write("\n".join(L))
print("lua ok")
