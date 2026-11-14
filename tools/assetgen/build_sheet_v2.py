"""Folha-guia visual: as 4 eras lado a lado com paleta, fontes, ícones, trem e mapa."""
import io
import cairosvg
from PIL import Image
from theme import ERAS
from composite import tint, map_preview, hex2rgb
from icons import train_svg

P = "/home/claude/pack_v2"
from build_v2_emoji import EMOJIS, tw_png
COLW, H, GAP = 600, 1500, 0
TRAIN = {"vapor": "trem_vapor", "diesel": "trem_diesel", "eletrico": "trem_eletrico", "alta": "trem_alta_velocidade"}
SEA = {"vapor": "mar_hachura", "diesel": "mar_ondas", "eletrico": None, "alta": "mar_pontos"}
ICONS = ["linhas", "trens", "estacoes", "cargas", "companhia", "loja", "dinheiro", "passageiros", "carga_cafe", "carga_minerio", "terreno_montanha", "cadeado"]

def r(svg):
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")

sheet = Image.new("RGBA", (COLW * 4, H), (255, 255, 255, 255))
for i, e in enumerate(ERAS):
    c = e["colors"]; f = e["preview_fonts"]
    col = Image.new("RGBA", (COLW, H), hex2rgb(c["bg"]) + (255,))
    sw = [("bg", c["bg"]), ("panel", c["panel"]), ("ink", c["ink"]), ("inkMuted", c["inkMuted"]), ("accent", c["accent"]),
          ("land", c["land"]), ("sea", c["sea"]), ("positive", c["positive"])]
    swatches = "".join(
        f'<rect x="{40 + (k%4)*132}" y="{200 + (k//4)*96}" width="120" height="56" fill="{v}" stroke="{c["ink"]}" stroke-opacity="0.35"/>'
        f'<text x="{40 + (k%4)*132}" y="{274 + (k//4)*96}" font-family="Roboto Mono" font-size="13" fill="{c["inkMuted"]}">{n} {v}</text>'
        for k, (n, v) in enumerate(sw))
    lines = "".join(f'<rect x="{40 + k*66}" y="420" width="58" height="14" fill="{v}"/>' for k, v in enumerate(e["lines"]))
    btn_r = e["shape"]["corner"]
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{COLW}" height="{H}">
<text x="40" y="80" font-family="{f["label"][0]}" font-weight="{f["label"][1]}" font-size="18" letter-spacing="3" fill="{c["inkMuted"]}">{e["anos"]}</text>
<text x="40" y="140" font-family="{f["display"][0]}" font-weight="{f["display"][1]}" font-size="{40 if e["id"]!="alta" else 30}" fill="{c["ink"]}">{e["nome"]}</text>
{swatches}
<text x="40" y="404" font-family="{f["label"][0]}" font-weight="{f["label"][1]}" font-size="15" fill="{c["inkMuted"]}">CORES DAS LINHAS</text>
{lines}
<rect x="40" y="470" width="520" height="250" rx="{btn_r}" fill="{c["panel"]}" stroke="{c["ink"]}" stroke-width="{e["shape"]["stroke"]*2}"/>
{f'<rect x="48" y="478" width="504" height="234" fill="none" stroke="{c["ink"]}" stroke-width="1.5"/>' if e["shape"]["doubleFrame"] else ""}
<text x="64" y="512" font-family="{f["label"][0]}" font-weight="{f["label"][1]}" font-size="14" letter-spacing="2" fill="{c["inkMuted"]}">CONCESSÃO Nº 0003</text>
<text x="64" y="556" font-family="{f["display"][0]}" font-weight="{f["display"][1]}" font-size="{30 if e["id"]!="alta" else 22}" fill="{c["ink"]}">Jundiaí – Campinas</text>
<text x="64" y="590" font-family="{f["body"][0]}" font-weight="{f["body"][1]}" font-size="18" fill="{c["inkMuted"]}">Terreno: planalto · custo ×1,0</text>
<text x="64" y="620" font-family="{f["number"][0]}" font-weight="{f["number"][1]}" font-size="20" fill="{c["positive"]}">+ R$ 1,40/s</text>
<rect x="64" y="644" width="472" height="52" rx="{btn_r}" fill="{c["accent"]}"/>
<text x="300" y="678" text-anchor="middle" font-family="{f["display"][0]}" font-weight="{f["display"][1]}" font-size="{20 if e["id"]!="alta" else 15}" fill="{c["onAccent"]}">Construir · R$ 190</text>
<text x="40" y="1490" font-family="Roboto Mono" font-size="12" fill="{c["inkMuted"]}">display {e["fonts"]["display"][0]} · label {e["fonts"]["label"][0]} · corpo {e["fonts"]["body"][0]} · núm. {e["fonts"]["number"][0]}</text>
</svg>'''
    # mapa
    pat = Image.open(f"{P}/texturas/{SEA[e['id']]}.png") if SEA[e["id"]] else None
    mp = map_preview("brasil", e, pattern=pat, scale=0.26)
    col.alpha_composite(mp, (40, 930))
    col.alpha_composite(r(svg))
    # ícones
    for k, n in enumerate(ICONS):
        im = tw_png(EMOJIS[n][0], 56)
        col.alpha_composite(im, (44 + (k % 6) * 88, 748 + (k // 6) * 84))
    tr = tint(Image.open(f"{P}/trens/{TRAIN[e['id']]}.png"), c["ink"]).resize((260, 97), Image.LANCZOS)
    col.alpha_composite(tr, (300, 1350))
    sheet.alpha_composite(col, (i * COLW, 0))
sheet.convert("RGB").save(f"{P}/guia_visual.png", quality=92)
print("sheet ok")
