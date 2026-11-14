"""Pacote v2: mesmos gráficos da v1, mas ícones trocados por emojis (texto, sem upload)."""
import io, os, json, shutil, subprocess
import cairosvg
from PIL import Image
from theme import ERAS
from composite import tint, map_preview, hex2rgb

V1 = "/home/claude/pack"
V2 = "/home/claude/pack_v2"
TW = "node_modules/@twemoji/svg"

# nome -> (emoji, versão Unicode, observação)
EMOJIS = {
 # navegação
 "linhas": ("🛤️", "7.0", ""), "trens": ("🚂", "6.0", ""), "estacoes": ("🚉", "6.0", ""), "cargas": ("📦", "6.0", ""),
 "companhia": ("💼", "6.0", ""), "loja": ("🛒", "9.0", ""), "mapa_mundo": ("🌎", "6.0", ""), "missoes": ("📋", "6.0", ""),
 "ranking": ("🏆", "6.0", ""), "configuracoes": ("⚙️", "4.1", ""), "visitar": ("👀", "6.0", ""), "menu": ("📜", "6.0", ""),
 # status e ações
 "dinheiro": ("💰", "6.0", ""), "renda": ("📈", "6.0", ""), "passageiros": ("👥", "6.0", ""), "satisfacao": ("😊", "6.0", ""),
 "relogio": ("⏰", "6.0", ""), "cadeado": ("🔒", "6.0", ""), "melhorar": ("⬆️", "4.0", ""), "confirmar": ("✅", "6.0", ""),
 "fechar": ("❌", "6.0", ""), "mais": ("➕", "6.0", ""), "menos": ("➖", "6.0", ""), "info": ("ℹ️", "3.0", ""),
 "alerta": ("⚠️", "4.0", ""), "velocidade": ("💨", "6.0", "não há velocímetro em emoji"), "distancia": ("📏", "6.0", ""),
 "presente": ("🎁", "6.0", ""), "prestigio": ("⭐", "5.1", ""), "conectar": ("🔗", "6.0", ""), "construir": ("🔨", "6.0", ""),
 "assinar": ("✍️", "1.1", ""), "sede": ("🚩", "6.0", ""), "auto": ("🔄", "6.0", ""),
 # cargas
 "carga_cafe": ("☕", "4.0", ""), "carga_minerio": ("⛏️", "5.2", "picareta no lugar de minério"),
 "carga_soja": ("🌱", "6.0", "o emoji de feijão (🫘) é novo demais"), "carga_graos": ("🌾", "6.0", ""),
 "carga_carvao": ("🔥", "6.0", "não há emoji de carvão"), "carga_petroleo": ("🛢️", "7.0", ""),
 "carga_madeira": ("🌲", "6.0", "o emoji de tora (🪵) é novo demais"), "carga_gado": ("🐄", "6.0", ""),
 "carga_aco": ("🔩", "6.0", ""), "carga_mercadorias": ("🏭", "6.0", ""), "carga_passageiros": ("🎫", "6.0", ""),
 # terreno
 "terreno_montanha": ("⛰️", "5.2", ""), "terreno_ponte": ("🌉", "6.0", ""), "terreno_pantano": ("🐊", "6.0", "jacaré representa o Pantanal"),
 "terreno_floresta": ("🌳", "6.0", ""), "terreno_tunel": ("🚇", "6.0", ""), "terreno_cremalheira": ("🧗", "10.0", "não há emoji de cremalheira; escalada = trecho íngreme"),
 # eras
 "era_vapor": ("🚂", "6.0", ""), "era_diesel": ("🚆", "6.0", ""), "era_eletrico": ("🚈", "6.0", ""), "era_alta": ("🚅", "6.0", ""),
}

def tw_file(e):
    cps = [f"{ord(c):x}" for c in e]
    for cand in ("-".join(cps), "-".join(c for c in cps if c != "fe0f")):
        p = f"{TW}/{cand}.svg"
        if os.path.exists(p): return p
    raise FileNotFoundError(e)

def tw_png(e, size):
    return Image.open(io.BytesIO(cairosvg.svg2png(url=tw_file(e), output_width=size, output_height=size))).convert("RGBA")

# ---------- copiar a v1 sem os ícones ----------
if os.path.exists(V2): shutil.rmtree(V2)
shutil.copytree(V1, V2, ignore=shutil.ignore_patterns("icones", "atlas"))
for d in ("icones", "atlas"):
    assert not os.path.exists(f"{V2}/{d}")

# ---------- Emojis.lua ----------
L = ["-- Emojis.lua · ícones do jogo em emoji (texto). Não precisam de upload.",
     "-- Uso: label.Text = Emojis.carga_cafe  (TextLabel/TextButton; a cor do texto não afeta emojis coloridos)",
     "-- Mantém os mesmos nomes dos ícones da v1, para trocar de volta sem mexer no resto do código.", "",
     "local Emojis = {"]
cat = None
for n, (e, ver, obs) in EMOJIS.items():
    group = n.split("_")[0] if n.startswith(("carga_", "terreno_", "era_")) else "geral"
    if group != cat:
        L.append(f"\t-- {group}"); cat = group
    L.append(f'\t{n} = "{e}",' + (f" -- {obs}" if obs else ""))
L += ["}", "", "return Emojis", ""]
open(f"{V2}/lua/Emojis.lua", "w").write("\n".join(L))
json.dump({n: {"emoji": e, "unicode": v, "obs": o} for n, (e, v, o) in EMOJIS.items()},
          open(f"{V2}/lua/emojis.json", "w"), ensure_ascii=False, indent=1)

# ---------- Assets.lua sem atlas ----------
src = open(f"{V2}/lua/Assets.lua").read()
start = src.index("-- Ícones dentro de atlas/icones_atlas.png")
end = src.index("-- Configuração de 9-slice e tiles.")
src = src[:start] + src[end:]
src = "\n".join(l for l in src.split("\n") if "icones_atlas" not in l and l.strip() != "-- atlas")
src = src.replace("-- Todas as imagens (exceto identidade/) são brancas: tingir com ImageColor3 usando a cor da era.",
                  "-- Todas as imagens (exceto identidade/) são brancas: tingir com ImageColor3 usando a cor da era.\n-- Ícones: na v2 são emojis, veja Emojis.lua.")
open(f"{V2}/lua/Assets.lua", "w").write(src)

# ---------- folha de emojis ----------
names = list(EMOJIS); cols = 6; cw, ch = 320, 120
rows = (len(names) + cols - 1) // cols
c0 = ERAS[0]["colors"]
sheet = Image.new("RGBA", (cols * cw, rows * ch + 40), hex2rgb(c0["bg"]) + (255,))
labels = ""
for i, n in enumerate(names):
    x, y = (i % cols) * cw + 20, (i // cols) * ch + 30
    sheet.alpha_composite(tw_png(EMOJIS[n][0], 64), (x, y))
    obs = " *" if EMOJIS[n][2] else ""
    labels += f'<text x="{x+80}" y="{y+40}" font-family="Roboto Mono" font-size="16" fill="{c0["ink"]}">{n}{obs}</text>'
lab = cairosvg.svg2png(bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" width="{sheet.width}" height="{sheet.height}">{labels}</svg>'.encode())
sheet.alpha_composite(Image.open(io.BytesIO(lab)).convert("RGBA"))
sheet.convert("RGB").save(f"{V2}/emojis.png", quality=92)

# ---------- guia visual v2 (mesma folha, ícones -> emojis) ----------
print("v2 base ok", len(EMOJIS), "emojis")
