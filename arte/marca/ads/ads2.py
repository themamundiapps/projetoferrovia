# ADs v2: mais chamativos, só com imagens do jogo (sem 3D): raios de sol, cartões inclinados, selos e letras grossas.
import sys, math, cv2, numpy as np
sys.path.insert(0, "/home/claude/projetoferrovia/arte/marca/ads")
from limpo import limpo
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageChops
W, H = 1920, 1080
FX = "/root/.fonts/extra/"
LOGO = Image.open("/home/claude/logo/logo_railway_tycoon.png")
OURO = [(255, 246, 190), (247, 210, 105), (214, 150, 40), (250, 214, 120), (176, 104, 22)]
def F(n, s): return ImageFont.truetype(FX + n, s)
def dil(m, r):
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1)); return Image.fromarray(cv2.dilate(np.array(m), k))
def grad(cores, w, h):
    t = np.linspace(0, 1, h); pos = np.linspace(0, 1, len(cores))
    g = np.stack([np.interp(t, pos, [c[i] for c in cores]) for i in range(3)], -1)
    return Image.fromarray(np.repeat(g[:, None, :], w, 1).astype(np.uint8)).convert("RGBA")
def bisel(img, m, forca=0.9, r=2.5):
    a = np.array(m).astype(np.float32) / 255; b = cv2.GaussianBlur(a, (0, 0), r)
    gy, gx = np.gradient(b); luz = gx * 0.6 + gy * 0.8; luz /= (np.abs(luz).max() + 1e-6)
    for v, cor, k in ((np.clip(-luz, 0, 1), (255, 250, 225), 220), (np.clip(luz, 0, 1), (50, 20, 0), 170)):
        c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(Image.fromarray((v * a * forca * k).astype(np.uint8))); img.alpha_composite(c)
def pintar(img, m, cor):
    c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(m); img.alpha_composite(c)

def quadro(s, t, cx, cy, zoom):
    im = limpo(s, t).convert("RGBA").crop((0, 72, 1920, 876))
    w, h = im.size; vw, vh = w / zoom, h / zoom; cy -= 72
    x0 = min(max(cx - vw / 2, 0), w - vw); y0 = min(max(cy - vh / 2, 0), h - vh)
    im = im.crop((int(x0), int(y0), int(x0 + vw), int(y0 + vh)))
    return ImageEnhance.Contrast(im.filter(ImageFilter.UnsharpMask(2, 70, 2))).enhance(1.08)
def preencher(im, w, h):
    e = max(w / im.width, h / im.height); im = im.resize((math.ceil(im.width * e), math.ceil(im.height * e)), Image.LANCZOS)
    x = (im.width - w) // 2; y = (im.height - h) // 2; return im.crop((x, y, x + w, y + h))

def raios(c1, c2, cx=W / 2, cy=H * 0.55, n=28, girar=0):
    img = Image.new("RGBA", (W, H), c1 + (255,)); d = ImageDraw.Draw(img)
    R = 3000
    for i in range(n):
        if i % 2: continue
        a0 = girar + i * 2 * math.pi / n; a1 = girar + (i + 1) * 2 * math.pi / n
        d.polygon([(cx, cy), (cx + R * math.cos(a0), cy + R * math.sin(a0)), (cx + R * math.cos(a1), cy + R * math.sin(a1))], fill=c2 + (255,))
    v = Image.new("L", (W, H)); yy, xx = np.mgrid[0:H, 0:W]
    r = np.hypot((xx - cx) / W, (yy - cy) / H)
    v = Image.fromarray((np.clip((r - 0.2) / 0.6, 0, 1) ** 1.4 * 200).astype(np.uint8))
    esc = Image.new("RGBA", (W, H), (10, 4, 2, 0)); esc.putalpha(v); img.alpha_composite(esc)
    return img

def texto(img, txt, cx, y, tam, fonte="Ultra-Regular.ttf", estilo="ouro", esp=0.02, rot=0, ancora="centro"):
    f = F(fonte, tam); d0 = ImageDraw.Draw(Image.new("L", (1, 1)))
    e = tam * esp; larg = int(sum(d0.textlength(c, font=f) for c in txt) + e * (len(txt) - 1))
    asc, desc = f.getmetrics(); w, h = larg + 80, asc + desc + 80
    m = Image.new("L", (w, h)); d = ImageDraw.Draw(m); x = 40
    for c in txt: d.text((x, 40), c, font=f, fill=255); x += d.textlength(c, font=f) + e
    camada = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    r1 = max(4, tam // 11); r2 = max(2, tam // 22)
    s = Image.new("RGBA", (w, h), (0, 0, 0, 0)); s.paste((0, 0, 0, 200), (0, max(4, tam // 14)), dil(m, r1 + 3).filter(ImageFilter.GaussianBlur(5))); camada.alpha_composite(s)
    if estilo == "ouro":
        pintar(camada, dil(m, r1), (24, 10, 4)); pintar(camada, dil(m, r2), (130, 24, 18))
        g = grad(OURO, w, h); g.putalpha(m); camada.alpha_composite(g); bisel(camada, m)
    elif estilo == "branco":
        pintar(camada, dil(m, r1), (24, 10, 4)); g = grad([(255, 255, 255), (238, 232, 220)], w, h); g.putalpha(m); camada.alpha_composite(g)
    elif estilo == "vermelho":
        pintar(camada, dil(m, r1), (24, 10, 4)); pintar(camada, dil(m, r2), (250, 220, 140))
        g = grad([(235, 70, 50), (190, 30, 24), (130, 14, 12)], w, h); g.putalpha(m); camada.alpha_composite(g); bisel(camada, m)
    camada = camada.crop(camada.getbbox())
    if rot: camada = camada.rotate(rot, resample=Image.BICUBIC, expand=True)
    x = cx - camada.width / 2 if ancora == "centro" else cx
    img.alpha_composite(camada, (int(x), int(y)))
    return camada.size

def cartao(img, foto, cx, cy, w, h, rot, borda=14, cor=(250, 244, 228)):
    f = preencher(foto, w, h)
    c = Image.new("RGBA", (w + 2 * borda, h + 2 * borda), cor + (255,)); c.alpha_composite(f, (borda, borda))
    d = ImageDraw.Draw(c); d.rectangle([0, 0, c.width - 1, c.height - 1], outline=(40, 22, 10), width=4)
    c = c.rotate(rot, resample=Image.BICUBIC, expand=True)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); a = c.split()[3].filter(ImageFilter.GaussianBlur(14))
    sh.paste((0, 0, 0, 170), (int(cx - c.width / 2 + 14), int(cy - c.height / 2 + 22)), a); img.alpha_composite(sh)
    img.alpha_composite(c, (int(cx - c.width / 2), int(cy - c.height / 2)))

def selo(img, cx, cy, r, linhas, cor=(200, 34, 28), pontas=18, rot=-12):
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m); pts = []
    for i in range(pontas * 2):
        a = i * math.pi / pontas + math.radians(rot); rr = r if i % 2 == 0 else r * 0.84
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=255)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sh.paste((0, 0, 0, 160), (8, 14), m.filter(ImageFilter.GaussianBlur(10))); img.alpha_composite(sh)
    pintar(img, dil(m, 6), (24, 10, 4)); g = grad([(240, 80, 60), cor, (120, 14, 10)], W, H); g.putalpha(m); img.alpha_composite(g); bisel(img, m, 0.6, 4)
    anel = Image.new("L", (W, H)); da = ImageDraw.Draw(anel); da.ellipse([cx - r * 0.74, cy - r * 0.74, cx + r * 0.74, cy + r * 0.74], outline=255, width=5)
    pintar(img, anel, (255, 225, 150))
    tot = sum(t for _, t in linhas) + 6 * (len(linhas) - 1); y = cy - tot / 2
    for txt, t in linhas:
        lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); texto(lay, txt, cx, 0, t, estilo="branco")
        bb = lay.getbbox(); pedaço = lay.crop(bb).rotate(rot + 12, resample=Image.BICUBIC, expand=True)
        img.alpha_composite(pedaço, (int(cx - pedaço.width / 2), int(y))); y += t + 6

def faixa(img, y, h, cor=(150, 24, 20), incl=-3):
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    dy = math.tan(math.radians(incl)) * W
    d.polygon([(-20, y + dy / 2), (W + 20, y - dy / 2), (W + 20, y - dy / 2 + h), (-20, y + dy / 2 + h)], fill=255)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sh.paste((0, 0, 0, 170), (0, 10), m.filter(ImageFilter.GaussianBlur(10))); img.alpha_composite(sh)
    g = grad([(190, 40, 30), cor, (95, 12, 10)], W, H); g.putalpha(m); img.alpha_composite(g)
    for off in (10, h - 14):
        fl = Image.new("L", (W, H)); ImageDraw.Draw(fl).line([(-20, y + dy / 2 + off), (W + 20, y - dy / 2 + off)], fill=255, width=4)
        pintar(img, fl, (240, 200, 110))

def logo(img, cx, y, larg):
    lh = round(LOGO.height * larg / LOGO.width); img.alpha_composite(LOGO.resize((larg, lh), Image.LANCZOS), (int(cx - larg / 2), int(y)))
    return lh
