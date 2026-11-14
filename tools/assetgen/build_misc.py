"""Molduras 9-slice, marcadores, texturas, atlas de ícones e identidade (logo, ícone, thumbnail)."""
import io, os, json, math
import numpy as np
import cairosvg
from PIL import Image, ImageFilter, ImageDraw
from icons import ICONS, TRAINS, icon_svg, train_svg
from composite import tint, map_preview, hex2rgb
from theme import ERAS

P = "/home/claude/pack"
for d in ["icones", "trens", "molduras", "marcadores", "texturas", "identidade", "atlas"]:
    os.makedirs(f"{P}/{d}", exist_ok=True)

def r(svg, w=None, h=None):
    kw = {}
    if w: kw["output_width"] = w
    if h: kw["output_height"] = h
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), **kw))).convert("RGBA")

def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'

META = {}  # nome -> dicas de uso (SliceCenter, TileSize...)

# ---------------- ícones e trens ----------------
for n in ICONS:
    r(icon_svg(n)).save(f"{P}/icones/{n}.png", optimize=True)
for n in TRAINS:
    r(train_svg(n)).save(f"{P}/trens/{n}.png", optimize=True)

# atlas 1024 com ícones de 128
atlas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
rects = {}
for i, n in enumerate(ICONS):
    x, y = (i % 8) * 128, (i // 8) * 128
    atlas.alpha_composite(Image.open(f"{P}/icones/{n}.png"), (x, y))
    rects[n] = [x, y, 128, 128]
atlas.save(f"{P}/atlas/icones_atlas.png", optimize=True)

# ---------------- molduras (9-slice) ----------------
W = "#FFFFFF"
r(svg(128, 128, f'<rect x="1.5" y="1.5" width="125" height="125" fill="none" stroke="{W}" stroke-width="3"/><rect x="7.5" y="7.5" width="113" height="113" fill="none" stroke="{W}" stroke-width="1.5"/>')).save(f"{P}/molduras/moldura_dupla.png")
META["moldura_dupla"] = {"ScaleType": "Slice", "SliceCenter": [12, 12, 116, 116], "uso": "Contorno de documento/concessão (era do vapor). Tingir com ink."}

def ticket_path(w, h, n, inset=0):
    i = inset
    return (f"M{n+i},{i} H{w-n-i} A{n},{n} 0 0 0 {w-i},{n+i} V{h-n-i} A{n},{n} 0 0 0 {w-n-i},{h-i} "
            f"H{n+i} A{n},{n} 0 0 0 {i},{h-n-i} V{n+i} A{n},{n} 0 0 0 {n+i},{i} Z")
r(svg(128, 128, f'<path d="{ticket_path(128,128,14)}" fill="{W}"/>')).save(f"{P}/molduras/bilhete_fundo.png")
r(svg(128, 128, f'<path d="{ticket_path(128,128,14,1.5)}" fill="none" stroke="{W}" stroke-width="3"/>')).save(f"{P}/molduras/bilhete_contorno.png")
META["bilhete_fundo"] = {"ScaleType": "Slice", "SliceCenter": [18, 18, 110, 110], "uso": "Fundo de bilhete com cantos recortados (caixa, botões do vapor). Tingir com panel."}
META["bilhete_contorno"] = {"ScaleType": "Slice", "SliceCenter": [18, 18, 110, 110], "uso": "Contorno do bilhete, sobreposto ao fundo. Tingir com ink."}

# sombra suave
sh = Image.new("L", (160, 160), 0)
ImageDraw.Draw(sh).rounded_rectangle((40, 40, 120, 120), radius=10, fill=255)
sh = sh.filter(ImageFilter.GaussianBlur(12))
img = Image.new("RGBA", (160, 160), (255, 255, 255, 0)); img.putalpha(sh)
img.save(f"{P}/molduras/sombra_painel.png")
META["sombra_painel"] = {"ScaleType": "Slice", "SliceCenter": [64, 64, 96, 96], "uso": "Sombra sob painéis (diesel e elétrica). Tingir de preto, ImageTransparency 0.7; 20 px maior que o painel."}

# brilho neon
g = Image.new("L", (128, 128), 0)
ImageDraw.Draw(g).ellipse((24, 24, 104, 104), fill=255)
g = g.filter(ImageFilter.GaussianBlur(16))
img = Image.new("RGBA", (128, 128), (255, 255, 255, 0)); img.putalpha(g)
img.save(f"{P}/molduras/brilho.png")
META["brilho"] = {"uso": "Halo atrás de estações/linhas na era da alta velocidade. Tingir com a cor da linha."}

# pílula (entroncamento / chips)
r(svg(128, 64, f'<rect x="0" y="0" width="128" height="64" rx="32" fill="{W}"/>')).save(f"{P}/molduras/pilula_fundo.png")
r(svg(128, 64, f'<rect x="2" y="2" width="124" height="60" rx="30" fill="none" stroke="{W}" stroke-width="4"/>')).save(f"{P}/molduras/pilula_contorno.png")
META["pilula_fundo"] = {"ScaleType": "Slice", "SliceCenter": [32, 32, 96, 32], "uso": "Entroncamentos (várias linhas na mesma estação) e chips."}
META["pilula_contorno"] = {"ScaleType": "Slice", "SliceCenter": [32, 32, 96, 32], "uso": "Contorno da pílula."}

# perfuração e tracejado (tiles)
r(svg(16, 8, f'<circle cx="8" cy="4" r="2.2" fill="{W}"/>')).save(f"{P}/molduras/perfuracao.png")
META["perfuracao"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(16, 8)", "uso": "Linha picotada do bilhete."}
r(svg(24, 4, f'<rect x="0" y="0" width="14" height="4" fill="{W}"/>')).save(f"{P}/molduras/tracejado.png")
META["tracejado"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(24, 4)", "uso": "Divisores tracejados e trechos ainda não comprados."}

# ---------------- marcadores ----------------
r(svg(64, 64, f'<circle cx="32" cy="32" r="28" fill="{W}"/>')).save(f"{P}/marcadores/estacao_disco.png")
r(svg(64, 64, f'<circle cx="32" cy="32" r="24" fill="none" stroke="{W}" stroke-width="8"/>')).save(f"{P}/marcadores/estacao_anel.png")
r(svg(64, 64, f'<circle cx="32" cy="32" r="22" fill="none" stroke="{W}" stroke-width="4"/>')).save(f"{P}/marcadores/estacao_fechada.png")
r(svg(128, 128, f'<circle cx="64" cy="64" r="58" fill="none" stroke="{W}" stroke-width="4" stroke-dasharray="10 8"/>')).save(f"{P}/marcadores/anel_selecao.png")
r(svg(128, 128, f'<circle cx="64" cy="64" r="62" fill="{W}"/>')).save(f"{P}/marcadores/disco.png")
r(svg(64, 32, f'<path d="M6 4 H46 L60 16 L46 28 H6 a4 4 0 0 1 -4 -4 V8 a4 4 0 0 1 4 -4 Z" fill="{W}"/>')).save(f"{P}/marcadores/trem_ficha.png")
META["estacao_disco"] = {"uso": "Miolo da estação. Tingir com panel."}
META["estacao_anel"] = {"uso": "Aro da estação, por cima do disco. Tingir com ink."}
META["estacao_fechada"] = {"uso": "Estação ainda não conectada. Tingir com locked, ImageTransparency 0.5."}
META["anel_selecao"] = {"uso": "Destaque do trecho/estação selecionada; girar devagar."}
META["disco"] = {"uso": "Fundo do número da linha (badge). Tingir com a cor da linha."}
META["trem_ficha"] = {"uso": "Ficha do trem andando sobre a linha (vista de cima). Rotacionar na direção do trecho."}

# carimbo com falhas de tinta
st = r(svg(256, 256, f'<circle cx="128" cy="128" r="118" fill="none" stroke="{W}" stroke-width="8"/><circle cx="128" cy="128" r="100" fill="none" stroke="{W}" stroke-width="3"/>'))
rng = np.random.default_rng(7)
noise = rng.random((256, 256))
noise = np.array(Image.fromarray((noise * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.2))) / 255.0
a = np.array(st.getchannel("A")).astype(float)
a = a * np.clip((noise - 0.30) * 3.0, 0, 1)
st.putalpha(Image.fromarray(a.clip(0, 255).astype("uint8")))
st.save(f"{P}/marcadores/carimbo.png")
META["carimbo"] = {"uso": "Carimbo do ano na concessão; o texto (ano) vai por código no centro. Tingir com accent, girar -12°."}

# ---------------- texturas ----------------
r(svg(128, 128, "".join(f'<rect x="0" y="{y}" width="128" height="1.3" fill="{W}"/>' for y in range(4, 128, 8)))).save(f"{P}/texturas/mar_hachura.png")
r(svg(96, 96, "".join(f'<circle cx="{x}" cy="{y}" r="1.3" fill="{W}"/>' for x in range(6, 96, 12) for y in range(6, 96, 12)))).save(f"{P}/texturas/mar_pontos.png")
r(svg(128, 64, '<path d="M0 16 q16 -8 32 0 t32 0 t32 0 t32 0 M0 48 q16 -8 32 0 t32 0 t32 0 t32 0" fill="none" stroke="#FFFFFF" stroke-width="1.6"/>')).save(f"{P}/texturas/mar_ondas.png")
META["mar_hachura"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(128, 128)", "uso": "Mar da era do vapor. Tingir com seaPattern."}
META["mar_ondas"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(128, 64)", "uso": "Mar da era do diesel. Tingir com seaPattern."}
META["mar_pontos"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(96, 96)", "uso": "Mar da alta velocidade. Tingir com seaPattern."}

# papel: ruído contínuo nas bordas (tileable)
n = rng.random((512, 512))
def wrap_blur(x, k):
    out = np.zeros_like(x)
    for dy in range(-k, k + 1):
        for dx in range(-k, k + 1):
            out += np.roll(np.roll(x, dy, 0), dx, 1)
    return out / (2 * k + 1) ** 2
fine = wrap_blur(n, 1)
coarse = wrap_blur(rng.random((512, 512)), 6)
v = (fine - fine.mean()) * 2.2 + (coarse - coarse.mean()) * 4
alpha = np.clip(np.abs(v) * 170, 0, 70).astype("uint8")
paper = Image.new("RGBA", (512, 512), (255, 255, 255, 0)); paper.putalpha(Image.fromarray(alpha))
paper.save(f"{P}/texturas/papel_grao.png")
META["papel_grao"] = {"ScaleType": "Tile", "TileSize": "UDim2.fromOffset(512, 512)", "uso": "Grão de papel por cima dos painéis e do fundo (vapor e diesel). Tingir com ink, ImageTransparency 0.85."}

vg = Image.new("L", (512, 512), 0)
yy, xx = np.mgrid[0:512, 0:512]
d = np.sqrt(((xx - 256) / 256) ** 2 + ((yy - 256) / 256) ** 2)
vg = Image.fromarray((np.clip((d - 0.55) / 0.6, 0, 1) ** 1.6 * 255).astype("uint8"))
img = Image.new("RGBA", (512, 512), (255, 255, 255, 0)); img.putalpha(vg)
img.save(f"{P}/texturas/vinheta.png")
META["vinheta"] = {"ScaleType": "Stretch", "uso": "Escurecer as bordas da tela. Tingir com ink (vapor) ou preto; ImageTransparency 0.6."}

# ---------------- identidade (nome provisório) ----------------
V = ERAS[0]["colors"]
def logo_svg(w, h, ink, accent, panel=None):
    bg = f'<rect width="{w}" height="{h}" fill="{panel}"/>' if panel else ""
    cx = w / 2
    return svg(w, h, f'''{bg}
<text x="{cx}" y="{h*0.50}" text-anchor="middle" font-family="Merriweather" font-weight="900" font-size="{h*0.30}" letter-spacing="2" fill="{ink}">FERROVIA</text>
<rect x="{w*0.10}" y="{h*0.60}" width="{w*0.80}" height="{h*0.022}" fill="{ink}"/>
<rect x="{w*0.10}" y="{h*0.665}" width="{w*0.80}" height="{h*0.022}" fill="{ink}"/>
{"".join(f'<rect x="{w*0.10 + i*w*0.04}" y="{h*0.585}" width="{w*0.012}" height="{h*0.12}" fill="{ink}"/>' for i in range(21))}
<rect x="{cx - w*0.215}" y="{h*0.565}" width="{w*0.43}" height="{h*0.17}" fill="{panel or "#00000000"}"/>
<text x="{cx}" y="{h*0.71}" text-anchor="middle" font-family="Special Elite" font-size="{h*0.15}" letter-spacing="{h*0.03}" fill="{accent}">TYCOON</text>
''')
r(logo_svg(1024, 512, V["ink"], V["accent"], V["bg"])).save(f"{P}/identidade/logo_vapor.png")
# versão branca (para tingir sobre qualquer fundo) — sem fundo, o miolo do TYCOON vira um recorte
r(svg(1024, 512, f'''<text x="512" y="256" text-anchor="middle" font-family="Merriweather" font-weight="900" font-size="154" letter-spacing="2" fill="#FFFFFF">FERROVIA</text>
<text x="512" y="364" text-anchor="middle" font-family="Special Elite" font-size="77" letter-spacing="15" fill="#FFFFFF">TYCOON</text>
<rect x="102" y="300" width="246" height="11" fill="#FFFFFF"/><rect x="676" y="300" width="246" height="11" fill="#FFFFFF"/>''')).save(f"{P}/identidade/logo_branco.png")

# ícone do jogo 512
br = map_preview("brasil", ERAS[0], scale=0.25)  # 512x512
icon = Image.new("RGBA", (512, 512), hex2rgb(V["bg"]) + (255,))
icon.alpha_composite(br)
ov = r(svg(512, 512, f'''
<rect x="0" y="0" width="512" height="512" fill="{V["bg"]}" fill-opacity="0.35"/>
<rect x="14" y="14" width="484" height="484" fill="none" stroke="{V["ink"]}" stroke-width="8"/>
<rect x="28" y="28" width="456" height="456" fill="none" stroke="{V["ink"]}" stroke-width="3"/>
<rect x="28" y="372" width="456" height="112" fill="{V["panel"]}"/>
<line x1="28" y1="372" x2="484" y2="372" stroke="{V["ink"]}" stroke-width="3"/>
<text x="256" y="430" text-anchor="middle" font-family="Merriweather" font-weight="900" font-size="54" fill="{V["ink"]}">FERROVIA</text>
<text x="256" y="469" text-anchor="middle" font-family="Special Elite" font-size="30" letter-spacing="9" fill="{V["accent"]}">TYCOON</text>'''))
icon.alpha_composite(ov)
train = tint(r(train_svg("trem_vapor", 400, 150)), V["ink"])
icon.alpha_composite(train, (56, 150))
icon.convert("RGB").save(f"{P}/identidade/icone_jogo_512.png")

# thumbnail 1920x1080
pat = Image.open(f"{P}/texturas/mar_hachura.png")
th = Image.new("RGBA", (1920, 1080), hex2rgb(V["sea"]) + (255,))
pt = tint(pat, V["seaPattern"])
for y in range(0, 1080, 128):
    for x in range(0, 1920, 128):
        th.alpha_composite(pt, (x, y))
land = Image.open("/home/claude/work/brasil_terra_full.png").resize((1024, 1024), Image.LANCZOS)
lns = Image.open("/home/claude/work/brasil_linhas_full.png").resize((1024, 1024), Image.LANCZOS)
th.alpha_composite(tint(land, V["land"]), (40, 28)); th.alpha_composite(tint(lns, V["coast"]), (40, 28))
def pp(x, y): return (int(x * 0.5 + 40), int(y * 0.5 + 28))
lines_demo = [
 ("#8E2B23", [(1402,1464),(1388,1443),(1372,1420)]), ("#2E4A6B", [(1549,1410),(1530,1335),(1514,1260)]),
 ("#B5762A", [(1372,1420),(1250,1402),(1120,1395)]), ("#3F5E3A", [(1514,1260),(1330,1110)]),
]
demo = ""
for c, pts in lines_demo:
    ps = " ".join("%d,%d" % pp(*p) for p in pts)
    demo += f'<polyline points="{ps}" fill="none" stroke="{V["ink"]}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
    demo += f'<polyline points="{ps}" fill="none" stroke="{c}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
for c, pts in lines_demo:
    for p in (pts[0], pts[-1]):
        x, y = pp(*p)
        demo += f'<circle cx="{x}" cy="{y}" r="8" fill="{V["panel"]}" stroke="{V["ink"]}" stroke-width="4"/>'
th.alpha_composite(r(svg(1920, 1080, demo)))
paper = Image.open(f"{P}/texturas/papel_grao.png")
pa = paper.getchannel("A").point(lambda v: v // 2); paper2 = paper.copy(); paper2.putalpha(pa)
for y in range(0, 1080, 512):
    for x in range(0, 1920, 512):
        th.alpha_composite(tint(paper2, V["ink"]), (x, y))
panel = r(svg(1920, 1080, f'''
<rect x="1110" y="250" width="740" height="580" fill="{V["panel"]}" stroke="{V["ink"]}" stroke-width="4"/>
<rect x="1124" y="264" width="712" height="552" fill="none" stroke="{V["ink"]}" stroke-width="1.5"/>
<text x="1480" y="430" text-anchor="middle" font-family="Merriweather" font-weight="900" font-size="112" fill="{V["ink"]}">FERROVIA</text>
<text x="1480" y="520" text-anchor="middle" font-family="Special Elite" font-size="64" letter-spacing="18" fill="{V["accent"]}">TYCOON</text>
<line x1="1200" y1="568" x2="1760" y2="568" stroke="{V["rule"]}" stroke-width="2" stroke-dasharray="6 6"/>
<text x="1480" y="640" text-anchor="middle" font-family="Source Sans Pro" font-weight="700" font-size="40" fill="{V["ink"]}">Construa a ferrovia do seu país</text>
<text x="1480" y="720" text-anchor="middle" font-family="Special Elite" font-size="34" letter-spacing="4" fill="{V["inkMuted"]}">BRASIL · EUA · EUROPA</text>'''))
th.alpha_composite(panel)
th.alpha_composite(tint(r(train_svg("trem_vapor", 520, 195)), V["ink"]), (1220, 860))
th.convert("RGB").save(f"{P}/identidade/thumbnail_1920x1080.png", quality=92)

json.dump({"atlas_icones": rects, "uso": META}, open("/home/claude/work/misc_meta.json", "w"), ensure_ascii=False, indent=1)
print("ok")
