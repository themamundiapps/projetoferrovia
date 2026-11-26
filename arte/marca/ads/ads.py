# Anúncios do Railway Tycoon (Roblox Ads Manager): 16:9 para Sponsored Experiences e os três formatos
# de imagem (banner 728x90, arranha-céu 160x600, retângulo 300x250). Imagens tiradas do próprio jogo.
import sys, os, math
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "jogo"))
from compor import fonte, kit, texto_centro, INK, ACCENT
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
from limpo import limpo
FR = "/home/claude/video/frames"
CREAM = (247, 240, 222); GOLD = (222, 180, 98); DARK = (24, 15, 8)
ICONE = Image.open(os.path.join(os.path.dirname(__file__), "..", "jogo", "icone_en.png")).convert("RGBA")

def quadro(src, t, cx=None, cy=None, zoom=1.0, topo=0):
    im = limpo(src, t).convert("RGBA")
    im = im.crop((0, 72 + topo, 1920, 876))  # sem as barras da interface
    w, h = im.size
    cx = w / 2 if cx is None else cx; cy = h / 2 if cy is None else cy - 72 - topo
    vw, vh = w / zoom, h / zoom
    x0 = min(max(cx - vw / 2, 0), w - vw); y0 = min(max(cy - vh / 2, 0), h - vh)
    im = im.crop((int(x0), int(y0), int(x0 + vw), int(y0 + vh)))
    im = im.filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2))
    return ImageEnhance.Contrast(im).enhance(1.05)

def preencher(im, W, H):
    esc = max(W / im.width, H / im.height)
    im = im.resize((math.ceil(im.width * esc), math.ceil(im.height * esc)), Image.LANCZOS)
    x = (im.width - W) // 2; y = (im.height - H) // 2
    return im.crop((x, y, x + W, y + H))

def gradiente(W, H, lado="esq", ate=0.62, forca=235):
    g = Image.new("L", (W, 1))
    for x in range(W):
        f = x / W if lado == "esq" else 1 - x / W
        g.putpixel((x, 0), int(forca * max(0, 1 - f / ate) ** 1.3))
    g = g.resize((W, H))
    c = Image.new("RGBA", (W, H), DARK + (0,)); c.putalpha(g); return c

def gradiente_v(W, H, de=0.55, forca=230):
    g = Image.new("L", (1, H))
    for y in range(H):
        f = y / H
        g.putpixel((0, y), int(forca * max(0, (f - de) / (1 - de)) ** 1.2))
    g = g.resize((W, H)); c = Image.new("RGBA", (W, H), DARK + (0,)); c.putalpha(g); return c

def texto(d, x, y, txt, f, cor, esp=0, sombra=True, ancora="esq", contorno=0):
    larg = sum(d.textlength(ch, font=f) for ch in txt) + esp * (len(txt) - 1)
    if ancora == "centro": x -= larg / 2
    if ancora == "dir": x -= larg
    for ch in txt:
        if sombra: d.text((x + 3, y + 4), ch, font=f, fill=(0, 0, 0, 170))
        d.text((x, y), ch, font=f, fill=cor, stroke_width=contorno, stroke_fill=DARK)
        x += d.textlength(ch, font=f) + esp
    return larg

def icone(tam):
    m = Image.new("L", ICONE.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, ICONE.width - 1, ICONE.height - 1], int(ICONE.width * 0.16), fill=255)
    ic = ICONE.copy(); ic.putalpha(m); ic = ic.resize((tam, tam), Image.LANCZOS)
    out = Image.new("RGBA", (tam + 40, tam + 40), (0, 0, 0, 0))
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0)); sh.paste((0, 0, 0, 180), (20, 28, 20 + tam, 28 + tam), ic.split()[3])
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10))); out.alpha_composite(ic, (20, 20)); return out

def marca(img, x, y, tam=150, cor=CREAM, sub=True):
    x, y = int(x), int(y); img.alpha_composite(icone(tam), (x - 20, y - 20))
    d = ImageDraw.Draw(img)
    f = fonte("Merriweather-Black.ttf", int(tam * 0.36))
    texto(d, x + tam + 26, y + tam * 0.18, "RAILWAY TYCOON", f, cor, 3)
    if sub: texto(d, x + tam + 30, y + tam * 0.62, "ON ROBLOX", fonte("SpecialElite.ttf", int(tam * 0.18)), GOLD, 8, False)

def fio(d, x0, y, x1, cor=GOLD, w=3):
    d.line([(x0, y), (x1, y)], fill=cor, width=w)
    cx = (x0 + x1) / 2 if False else x0
    d.polygon([(x1 + 10, y), (x1 + 20, y - 8), (x1 + 30, y), (x1 + 20, y + 8)], fill=cor)

# 1) Império ------------------------------------------------------------------
def ad_imperio():
    W, H = 1920, 1080
    img = preencher(quadro("h11", 21.0, 1130, 600, 1.35), W, H)
    img.alpha_composite(gradiente(W, H, ate=0.7))
    img.alpha_composite(gradiente_v(W, H, 0.6, 200))
    d = ImageDraw.Draw(img)
    texto(d, 110, 150, "FROM 1825 TO TODAY", fonte("SpecialElite.ttf", 46), GOLD, 10, False)
    f = fonte("Merriweather-Black.ttf", 132)
    texto(d, 100, 225, "BUILD A", f, CREAM, 4)
    texto(d, 100, 385, "RAILWAY", f, CREAM, 4)
    texto(d, 100, 545, "EMPIRE", f, GOLD, 4)
    fio(d, 112, 735, 640)
    fs = fonte("SourceSansPro-SemiBold.ttf", 44) if os.path.exists(os.path.expanduser("~/.fonts/SourceSansPro-SemiBold.ttf")) else fonte("SpecialElite.ttf", 40)
    texto(d, 112, 765, "Connect real cities, buy trains, carry cargo.", fs, CREAM, 0)
    marca(img, 110, 880, 140)
    texto(d, W - 80, H - 90, "BRAZIL · USA · EUROPE", fonte("SpecialElite.ttf", 40), CREAM, 8, ancora="dir")
    return img.convert("RGB")

# 2) Quatro eras ----------------------------------------------------------------
def ad_eras():
    W, H = 1920, 1080
    fontes = [("h10", 3.0, "STEAM", "1825"), ("h13", 4.0, "DIESEL", "1935"), ("h14", 4.0, "ELECTRIC", "1960"), ("h15", 4.0, "HIGH SPEED", "1990")]
    img = Image.new("RGBA", (W, H), DARK + (255,))
    n = 4; incl = 220; larg = (W + incl) / n
    for i, (s, t, nome, ano) in enumerate(fontes):
        q = preencher(quadro(s, t, 960, 590, 1.3), W, H)
        m = Image.new("L", (W, H), 0)
        x0 = i * larg - incl / 2
        ImageDraw.Draw(m).polygon([(x0 + incl, 0), (x0 + larg + incl, 0), (x0 + larg, H), (x0, H)], fill=255)
        img.paste(q, (0, 0), m)
    d = ImageDraw.Draw(img)
    for i in range(1, n):
        x0 = i * larg - incl / 2
        d.line([(x0 + incl, 0), (x0, H)], fill=GOLD, width=10)
    img.alpha_composite(gradiente_v(W, H, 0.45, 245))
    top = Image.new("RGBA", (W, 300), (0, 0, 0, 0)); g = Image.new("L", (1, 300))
    for y in range(300): g.putpixel((0, y), int(225 * (1 - y / 300) ** 1.4))
    top.paste(DARK + (255,), (0, 0, W, 300), g.resize((W, 300))); img.alpha_composite(top)
    d = ImageDraw.Draw(img)
    texto(d, W / 2, 50, "FROM STEAM TO HIGH SPEED", fonte("Merriweather-Black.ttf", 104), CREAM, 4, ancora="centro")
    for i, (_, _, nome, ano) in enumerate(fontes):
        a = i * larg - incl / 2 + incl * (1 - 770 / H)
        cx = (max(a, 0) + min(a + larg, W)) / 2
        texto(d, cx, 735, nome, fonte("Merriweather-Black.ttf", 52 if len(nome) > 8 else 58), CREAM, 2, ancora="centro")
        texto(d, cx, 808, ano, fonte("SpecialElite.ttf", 46), GOLD, 8, False, ancora="centro")
    marca(img, W / 2 - 330, 905, 120)
    return img.convert("RGB")

# 3) Três mapas -------------------------------------------------------------------
def ad_mapas():
    W, H = 1920, 1080
    img = Image.new("RGBA", (W, H), DARK + (255,))
    mapas = [("h18", 4.0, 1000, 560, 1.0, "BRAZIL", "24 LINES"), ("h21", 4.0, 960, 500, 1.0, "USA", "33 LINES"),
             ("h15", 17.0, 960, 500, 1.0, "EUROPE", "55 LINES")]
    gap = 14; pw = (W - 4 * gap) // 3; y0, ph = 250, 640
    for i, (s, t, cx, cy, z, nome, linhas) in enumerate(mapas):
        q = preencher(quadro(s, t, cx, cy, z, topo=70), pw, ph)
        x = gap + i * (pw + gap)
        q.alpha_composite(gradiente_v(pw, ph, 0.55, 235))
        img.alpha_composite(q, (x, y0))
        d = ImageDraw.Draw(img)
        d.rectangle([x, y0, x + pw - 1, y0 + ph - 1], outline=GOLD, width=4)
        texto(d, x + pw / 2, y0 + ph - 170, nome, fonte("Merriweather-Black.ttf", 76), CREAM, 4, ancora="centro")
        texto(d, x + pw / 2, y0 + ph - 78, linhas, fonte("SpecialElite.ttf", 40), GOLD, 8, False, ancora="centro")
    d = ImageDraw.Draw(img)
    texto(d, W / 2, 50, "THREE MAPS. ONE EMPIRE.", fonte("Merriweather-Black.ttf", 106), CREAM, 4, ancora="centro")
    texto(d, W / 2, 178, "112 HISTORIC RAILWAYS TO BUILD", fonte("SpecialElite.ttf", 44), GOLD, 9, False, ancora="centro")
    marca(img, W / 2 - 330, 925, 120)
    return img.convert("RGB")

# 4) Formatos pequenos ----------------------------------------------------------------
def ad_banner():
    W, H = 728, 90
    img = preencher(quadro("h15", 16.0, 960, 500, 1.0), W, H)
    img.alpha_composite(gradiente(W, H, ate=0.75, forca=240))
    img.alpha_composite(icone(70), (-10, -10))
    d = ImageDraw.Draw(img)
    texto(d, 92, 10, "RAILWAY TYCOON", fonte("Merriweather-Black.ttf", 30), CREAM, 2)
    texto(d, 94, 52, "BUILD A RAILWAY EMPIRE", fonte("SpecialElite.ttf", 21), GOLD, 4, False)
    texto(d, W - 18, 32, "BRAZIL · USA · EUROPE", fonte("SpecialElite.ttf", 18), CREAM, 3, ancora="dir")
    return img.convert("RGB")

def ad_arranhaceu():
    W, H = 160, 600
    img = preencher(quadro("h10", 5.0, 960, 560, 1.6), W, H)
    img.alpha_composite(gradiente_v(W, H, 0.35, 245))
    top = Image.new("RGBA", (W, 230), DARK + (220,)); img.alpha_composite(top)
    d = ImageDraw.Draw(img)
    img.alpha_composite(icone(108), (6, 6))
    texto(d, W / 2, 148, "RAILWAY", fonte("Merriweather-Black.ttf", 25), CREAM, 1, ancora="centro")
    texto(d, W / 2, 182, "TYCOON", fonte("Merriweather-Black.ttf", 25), GOLD, 2, ancora="centro")
    for i, l in enumerate(["BUILD A", "RAILWAY", "EMPIRE"]):
        texto(d, W / 2, 440 + i * 34, l, fonte("Merriweather-Black.ttf", 24), CREAM, 1, ancora="centro")
    texto(d, W / 2, 556, "STEAM TO HIGH SPEED", fonte("SpecialElite.ttf", 11), GOLD, 1, False, ancora="centro")
    return img.convert("RGB")

def ad_retangulo():
    W, H = 300, 250
    img = preencher(quadro("h14", 4.0, 960, 560, 1.4), W, H)
    img.alpha_composite(gradiente_v(W, H, 0.3, 245))
    d = ImageDraw.Draw(img)
    img.alpha_composite(icone(64), (W - 92, -6))
    texto(d, 16, 112, "BUILD A", fonte("Merriweather-Black.ttf", 28), CREAM, 1)
    texto(d, 16, 146, "RAILWAY EMPIRE", fonte("Merriweather-Black.ttf", 27), GOLD, 0)
    texto(d, 17, 190, "RAILWAY TYCOON", fonte("Merriweather-Black.ttf", 16), CREAM, 1)
    texto(d, 17, 216, "BRAZIL · USA · EUROPE", fonte("SpecialElite.ttf", 14), GOLD, 2, False)
    return img.convert("RGB")

if __name__ == "__main__":
    for nome, f in [("ad_imperio_1920x1080", ad_imperio), ("ad_eras_1920x1080", ad_eras), ("ad_mapas_1920x1080", ad_mapas),
                    ("ad_banner_728x90", ad_banner), ("ad_skyscraper_160x600", ad_arranhaceu), ("ad_retangulo_300x250", ad_retangulo)]:
        f().save(f"{nome}.png"); print(nome)
