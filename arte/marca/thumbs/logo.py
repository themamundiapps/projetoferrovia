# Logotipo "RAILWAY TYCOON" em estilo de placa ferroviária vitoriana (dourado, fita vermelha, rodas, filetes).
import math, cv2, numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
FX = "/root/.fonts/extra/"
W, H = 2400, 1100
def F(n, s): return ImageFont.truetype(FX + n, s)

def mascara_texto(txt, fonte, esp=0):
    tmp = Image.new("L", (W, H)); d = ImageDraw.Draw(tmp)
    larg = sum(d.textlength(c, font=fonte) for c in txt) + esp * (len(txt) - 1)
    return larg

def texto_reto(txt, fonte, cx, y, esp=0):
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    larg = sum(d.textlength(c, font=fonte) for c in txt) + esp * (len(txt) - 1)
    x = cx - larg / 2
    for c in txt:
        d.text((x, y), c, font=fonte, fill=255); x += d.textlength(c, font=fonte) + esp
    return m

def texto_arco(txt, fonte, cx, cy, raio, esp=0, escala_alt=1.0):
    # letras ao longo de um arco (centro abaixo), topo convexo
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    larguras = [d.textlength(c, font=fonte) for c in txt]
    total = sum(larguras) + esp * (len(txt) - 1)
    ang = -total / raio / 2
    asc, desc = fonte.getmetrics()
    for c, lw in zip(txt, larguras):
        meio = ang + (lw / 2) / raio
        g = Image.new("L", (int(lw + 40), asc + desc + 40)); ImageDraw.Draw(g).text((20, 20), c, font=fonte, fill=255)
        if escala_alt != 1.0: g = g.resize((g.width, int(g.height * escala_alt)))
        g = g.rotate(-math.degrees(meio), resample=Image.BICUBIC, expand=True)
        px = cx + raio * math.sin(meio); py = cy - raio * math.cos(meio)
        m.paste(255, (int(px - g.width / 2), int(py - g.height / 2)), g)
        ang += (lw + esp) / raio
    return m

def dil(m, r):
    a = np.array(m); k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    return Image.fromarray(cv2.dilate(a, k))

def gradiente_v(cores, y0, y1):
    g = np.zeros((H, W, 3), np.float32)
    ys = np.clip((np.arange(H) - y0) / max(1, y1 - y0), 0, 1)
    pos = np.linspace(0, 1, len(cores))
    for ch in range(3):
        g[:, :, ch] = np.interp(ys, pos, [c[ch] for c in cores])[:, None]
    return Image.fromarray(g.astype(np.uint8))

def chapa(img, m, cor):
    img.alpha_composite(Image.new("RGBA", (W, H), cor + (255,)) if len(cor) == 3 else cor, (0, 0)) if False else None
    camada = Image.new("RGBA", (W, H), cor + (0,)); camada.putalpha(m); img.alpha_composite(camada)

def bisel(img, m, forca=1.0, raio=4):
    a = np.array(m).astype(np.float32) / 255
    b = cv2.GaussianBlur(a, (0, 0), raio)
    gy, gx = np.gradient(b)
    luz = -(gx * -0.6 + gy * -0.8)  # luz vindo de cima à esquerda
    luz = luz / (np.abs(luz).max() + 1e-6)
    alto = np.clip(luz, 0, 1) * a * forca; baixo = np.clip(-luz, 0, 1) * a * forca
    branco = Image.new("RGBA", (W, H), (255, 250, 220, 0)); branco.putalpha(Image.fromarray((alto * 230).astype(np.uint8)))
    preto = Image.new("RGBA", (W, H), (60, 25, 0, 0)); preto.putalpha(Image.fromarray((baixo * 200).astype(np.uint8)))
    img.alpha_composite(branco); img.alpha_composite(preto)

def dourado(img, m, y0, y1):
    ouro = gradiente_v([(255, 246, 190), (247, 210, 105), (214, 150, 40), (250, 214, 120), (176, 104, 22)], y0, y1).convert("RGBA")
    ouro.putalpha(m); img.alpha_composite(ouro)

def palavra(img, m, y0, y1, vermelho=(122, 22, 18), contorno=(18, 10, 6)):
    sombra = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sm = dil(m, 20).filter(ImageFilter.GaussianBlur(10))
    s = Image.new("RGBA", (W, H), (0, 0, 0, 0)); s.paste((0, 0, 0, 170), (0, 14), sm); img.alpha_composite(s)
    chapa(img, dil(m, 20), contorno)
    v = gradiente_v([(170, 40, 30), vermelho, (80, 12, 10)], y0, y1).convert("RGBA"); v.putalpha(dil(m, 15)); img.alpha_composite(v)
    bisel(img, dil(m, 15), 0.6, 3)
    chapa(img, dil(m, 6), (70, 38, 10))
    dourado(img, m, y0, y1)
    bisel(img, m, 1.0, 3)
    # filete interno claro
    interno = ImageChops.subtract(m, Image.fromarray(cv2.erode(np.array(m), np.ones((5, 5), np.uint8))))
    chapa(img, interno.point(lambda v: v * 0.35), (255, 245, 200))

def roda(img, cx, cy, r, raios=10):
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255); d.ellipse([cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82], fill=0)
    for i in range(raios):
        a = i * 2 * math.pi / raios
        d.line([(cx, cy), (cx + r * 0.85 * math.cos(a), cy + r * 0.85 * math.sin(a))], fill=255, width=int(r * 0.11))
    d.ellipse([cx - r * 0.25, cy - r * 0.25, cx + r * 0.25, cy + r * 0.25], fill=255)
    d.ellipse([cx - r * 0.09, cy - r * 0.09, cx + r * 0.09, cy + r * 0.09], fill=0)
    # contrapeso
    pass
    chapa(img, dil(m, 9), (18, 10, 6)); chapa(img, dil(m, 4), (70, 38, 10))
    dourado(img, m, cy - r, cy + r); bisel(img, m, 0.9, 2)

def fita(img, cx, y, larg, alt):
    # fita vermelha com pontas dobradas e filetes dourados
    d0 = Image.new("L", (W, H)); d = ImageDraw.Draw(d0)
    x0, x1 = cx - larg / 2, cx + larg / 2
    curva = 26
    pts_top = [(x0 + (x1 - x0) * t, y - curva * math.sin(math.pi * t)) for t in np.linspace(0, 1, 60)]
    pts_bot = [(x, yy + alt) for x, yy in reversed(pts_top)]
    d.polygon(pts_top + pts_bot, fill=255)
    pontas = Image.new("L", (W, H)); dp = ImageDraw.Draw(pontas)
    for s in (-1, 1):
        xb = cx + s * (larg / 2 - 10)
        xe = cx + s * (larg / 2 + 150)
        yb = y + 40
        dp.polygon([(xb, yb), (xe, yb), (xe - s * 55, yb + alt / 2), (xe, yb + alt), (xb, yb + alt)], fill=255)
    chapa(img, dil(pontas, 9), (18, 10, 6))
    v = gradiente_v([(120, 22, 18), (82, 12, 10)], y, y + alt + 40).convert("RGBA"); v.putalpha(pontas); img.alpha_composite(v)
    bisel(img, pontas, 0.5, 4)
    # dobras escuras
    db = Image.new("L", (W, H)); dd = ImageDraw.Draw(db)
    for s in (-1, 1):
        xb = cx + s * (larg / 2 - 10)
        dd.polygon([(xb, y + 40 + alt), (xb + s * 0, y + alt), (xb - s * 40, y + alt - 2)], fill=255)
    chapa(img, db, (45, 6, 6))
    chapa(img, dil(d0, 9), (18, 10, 6))
    v = gradiente_v([(196, 48, 34), (150, 30, 24), (96, 14, 12)], y - curva, y + alt).convert("RGBA"); v.putalpha(d0); img.alpha_composite(v)
    bisel(img, d0, 0.5, 5)
    # filetes dourados
    f = Image.new("L", (W, H)); df = ImageDraw.Draw(f)
    for off in (12, alt - 12):
        pts = [(x0 + 20 + (x1 - x0 - 40) * t, y + off - curva * math.sin(math.pi * t)) for t in np.linspace(0, 1, 80)]
        df.line(pts, fill=255, width=4)
    dourado(img, f, y, y + alt)
    return d0

def estrela(d, cx, cy, r):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5; rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=255)

def arabesco(d, cx, cy, s, larg):
    # filete com voltas nas pontas (flourish)
    for t in np.linspace(0, 1, 2):
        pass
    x0, x1 = cx, cx + s * larg
    d.line([(x0, cy), (x1, cy)], fill=255, width=6)
    r = 16
    d.arc([x1 - r, cy - 2 * r, x1 + r, cy], 90 if s > 0 else 270, 90 if s < 0 else 450, fill=255, width=6) if False else None
    bx = x1 + s * 4
    d.arc([bx - (r if s > 0 else -r) * 0 - r, cy - r * 2, bx + r, cy], 0, 360, fill=255, width=5)
    d.polygon([(x0 - s * 10, cy), (x0 + s * 18, cy - 10), (x0 + s * 46, cy), (x0 + s * 18, cy + 10)], fill=255)

def montar():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cx = W // 2
    # fita atrás de TYCOON
    fita(img, cx, 560, 1520, 300)
    # rodas nas pontas da fita
    for s in (-1, 1): roda(img, cx + s * 905, 712, 120)
    # RAILWAY em arco
    m1 = texto_arco("RAILWAY", F("Rye-Regular.ttf", 250), cx, 1615, 1330, esp=14)
    palavra(img, m1, 150, 490)
    # TYCOON reto sobre a fita
    m2 = texto_reto("TYCOON", F("Rye-Regular.ttf", 230), cx, 545, esp=16)
    palavra(img, m2, 570, 840)
    # ornamentos: estrelas e "EST. 1825"
    o = Image.new("L", (W, H)); d = ImageDraw.Draw(o)
    for s in (-1, 1):
        estrela(d, cx + s * 560, 905, 22)
        d.line([(cx + s * 250, 905), (cx + s * 520, 905)], fill=255, width=6)
        d.polygon([(cx + s * 230, 905), (cx + s * 258, 893), (cx + s * 286, 905), (cx + s * 258, 917)], fill=255)
    f = F("IMFeENsc28P.ttf", 64)
    est = texto_reto("Est. 1825", f, cx, 862, esp=6)
    o = ImageChops.lighter(o, est)
    chapa(img, dil(o, 7), (18, 10, 6)); dourado(img, o, 860, 950); bisel(img, o, 0.8, 2)
    return img

if __name__ == "__main__":
    img = montar()
    bb = img.getbbox(); img = img.crop((bb[0] - 20, bb[1] - 20, bb[2] + 20, bb[3] + 30))
    img.save("logo_railway_tycoon.png")
    fundo = Image.new("RGBA", img.size, (40, 28, 22, 255)); fundo.alpha_composite(img)
    fundo.convert("RGB").save("/tmp/logo_prev.png")
    print(img.size)
