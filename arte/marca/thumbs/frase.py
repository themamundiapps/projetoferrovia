# Frase de efeito em letras douradas (ou prata/neon) com contorno, filetes e losangos nas pontas.
import cv2, numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
FONTE = "/root/.fonts/extra/Rye-Regular.ttf"
def dil(m, r):
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1)); return Image.fromarray(cv2.dilate(np.array(m), k))
def grad(W, H, cores):
    ys = np.linspace(0, 1, H); pos = np.linspace(0, 1, len(cores))
    g = np.stack([np.interp(ys, pos, [c[i] for c in cores]) for i in range(3)], -1)
    return Image.fromarray(np.repeat(g[:, None, :], W, 1).astype(np.uint8)).convert("RGBA")
def bisel(img, m, forca=0.9):
    a = np.array(m).astype(np.float32) / 255; b = cv2.GaussianBlur(a, (0, 0), 2)
    gy, gx = np.gradient(b); luz = gx * 0.6 + gy * 0.8; luz /= (np.abs(luz).max() + 1e-6)
    for v, cor, k in ((np.clip(-luz, 0, 1), (255, 250, 225), 220), (np.clip(luz, 0, 1), (50, 20, 0), 170)):
        c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(Image.fromarray((v * a * forca * k).astype(np.uint8))); img.alpha_composite(c)
def frase(txt, tam=74, estilo="ouro"):
    f = ImageFont.truetype(FONTE, tam)
    d0 = ImageDraw.Draw(Image.new("L", (1, 1)))
    esp = tam * 0.08
    larg = int(sum(d0.textlength(c, font=f) for c in txt) + esp * (len(txt) - 1))
    asc, desc = f.getmetrics()
    lados = 150
    W, H = larg + 2 * lados + 80, asc + desc + 60
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m); x = lados + 40
    for c in txt: d.text((x, 30), c, font=f, fill=255); x += d.textlength(c, font=f) + esp
    # filetes com losango nas pontas
    o = Image.new("L", (W, H)); do = ImageDraw.Draw(o); cy = 30 + asc * 0.62
    for s in (-1, 1):
        x0 = lados + 40 - 22 if s < 0 else lados + 40 + larg + 22
        x1 = x0 + s * (lados - 30)
        do.line([(x0, cy), (x1, cy)], fill=255, width=max(3, tam // 18))
        r = tam * 0.16
        do.polygon([(x1, cy - r), (x1 + s * r * 1.4, cy), (x1, cy + r), (x1 - s * r * 1.4, cy)], fill=255)
    tudo = ImageChops.lighter(m, o)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s = Image.new("RGBA", (W, H), (0, 0, 0, 0)); s.paste((0, 0, 0, 190), (0, 6), dil(tudo, 9).filter(ImageFilter.GaussianBlur(6))); img.alpha_composite(s)
    if estilo == "ouro":
        borda = (20, 10, 5); face = [(255, 244, 190), (246, 205, 100), (205, 140, 35), (240, 200, 110), (160, 95, 20)]; meio = (80, 40, 10)
    else:
        borda = (10, 8, 30); face = [(255, 255, 255), (220, 228, 240), (150, 160, 185), (215, 222, 235), (120, 128, 150)]; meio = (60, 110, 255)
    c = Image.new("RGBA", (W, H), borda + (0,)); c.putalpha(dil(tudo, 7)); img.alpha_composite(c)
    if estilo != "ouro":
        g = Image.new("RGBA", (W, H), (120, 90, 255, 0)); g.putalpha(dil(tudo, 9).filter(ImageFilter.GaussianBlur(7)).point(lambda v: int(v * 0.9))); img.alpha_composite(g)
        c = Image.new("RGBA", (W, H), borda + (0,)); c.putalpha(dil(tudo, 5)); img.alpha_composite(c)
    c = Image.new("RGBA", (W, H), meio + (0,)); c.putalpha(dil(tudo, 3)); img.alpha_composite(c)
    fc = grad(W, H, face); fc.putalpha(tudo); img.alpha_composite(fc)
    bisel(img, tudo)
    return img.crop(img.getbbox())

def aplicar(base, saida, txt, estilo="ouro", tam=74, y_base=1048, faixa=True):
    im = Image.open(base).convert("RGBA")
    if faixa:
        g = Image.new("L", (1, 1080))
        for y in range(1080): g.putpixel((0, y), int(175 * max(0, (y - 820) / 260) ** 1.2))
        s = Image.new("RGBA", (1920, 1080), (6, 4, 3, 0)); s.putalpha(g.resize((1920, 1080))); im.alpha_composite(s)
    fr = frase(txt, tam, estilo)
    im.alpha_composite(fr, ((1920 - fr.width) // 2, y_base - fr.height))
    im.convert("RGB").save(saida)
