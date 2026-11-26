import math, cv2, numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
S = 1024; C = S // 2
def grad(cores, w, h, vertical=True):
    t = np.linspace(0, 1, h if vertical else w); pos = np.linspace(0, 1, len(cores))
    g = np.stack([np.interp(t, pos, [c[i] for c in cores]) for i in range(3)], -1)
    arr = np.repeat(g[:, None, :], w, 1) if vertical else np.repeat(g[None, :, :], h, 0)
    return Image.fromarray(arr.astype(np.uint8)).convert("RGBA")
def bisel(img, m, forca=1.0, r=4):
    a = np.array(m).astype(np.float32) / 255; b = cv2.GaussianBlur(a, (0, 0), r)
    gy, gx = np.gradient(b); luz = gx * 0.6 + gy * 0.8; luz /= (np.abs(luz).max() + 1e-6)
    for v, cor, k in ((np.clip(-luz, 0, 1), (255, 250, 225), 235), (np.clip(luz, 0, 1), (40, 18, 0), 190)):
        c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(Image.fromarray((v * a * forca * k).astype(np.uint8))); img.alpha_composite(c)
def pintar(img, m, cor):
    c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(m); img.alpha_composite(c)
def dil(m, r):
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1)); return Image.fromarray(cv2.dilate(np.array(m), k))
OURO = [(255, 246, 196), (248, 212, 110), (214, 150, 40), (252, 220, 130), (170, 100, 20)]

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
# fundo: disco marrom com luz radial
yy, xx = np.mgrid[0:S, 0:S]; r = np.hypot(xx - C, yy - C * 0.9) / (S * 0.5)
fundo = np.stack([np.interp(r, [0, 0.6, 1.1], [c1, c2, c3]) for c1, c2, c3 in ((120, 50, 25), (72, 30, 22), (32, 14, 10))], -1)
disco = Image.fromarray(fundo.astype(np.uint8)).convert("RGBA")
mdisco = Image.new("L", (S, S)); ImageDraw.Draw(mdisco).ellipse([60, 60, S - 60, S - 60], fill=255)
disco.putalpha(mdisco); img.alpha_composite(disco)

# trilhos: dois trilhos paralelos na diagonal sobre dormentes
cena = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ang = math.radians(-28)
def rot(px, py):
    x, y = px - C, py - C
    return (C + x * math.cos(ang) - y * math.sin(ang), C + x * math.sin(ang) + y * math.cos(ang))
dorm = Image.new("L", (S, S)); dd = ImageDraw.Draw(dorm)
for i in range(-4, 5):
    x = C + i * 120
    dd.polygon([rot(x - 34, C - 260), rot(x + 34, C - 260), rot(x + 34, C + 260), rot(x - 34, C + 260)], fill=255)
madeira = grad([(140, 88, 50), (96, 58, 32), (70, 40, 22)], S, S)
pintar(cena, dil(dorm, 5), (25, 12, 6)); madeira.putalpha(dorm); cena.alpha_composite(madeira); bisel(cena, dorm, 0.6, 3)
for off in (-150, 150):
    tr = Image.new("L", (S, S)); dt = ImageDraw.Draw(tr)
    dt.polygon([rot(C - 520, C + off - 22), rot(C + 520, C + off - 22), rot(C + 520, C + off + 22), rot(C - 520, C + off + 22)], fill=255)
    aco = grad([(220, 226, 232), (150, 158, 170), (70, 76, 88)], S, S)
    pintar(cena, dil(tr, 6), (15, 15, 20)); aco.putalpha(tr); cena.alpha_composite(aco); bisel(cena, tr, 0.9, 3)
cena.putalpha(ImageChops.multiply(cena.split()[3], mdisco))
img.alpha_composite(cena)
esc = Image.new("RGBA", (S, S), (20, 8, 4, 0)); esc.putalpha(mdisco.point(lambda v: int(v * 0.42))); img.alpha_composite(esc)

# prego dourado (vertical e depois girado)
P = Image.new("L", (S, S)); dp = ImageDraw.Draw(P)
w = 100; top = 170; bot = 840
dp.rectangle([C - w / 2, top + 50, C + w / 2, bot - 90], fill=255)          # haste
dp.polygon([(C - w / 2, bot - 90), (C + w / 2, bot - 90), (C + 6, bot), (C - 6, bot)], fill=255)  # ponta em cunha
dp.rounded_rectangle([C - w / 2 - 30, top, C + w / 2 + 70, top + 62], 14, fill=255)  # cabeça deslocada
dp.polygon([(C + w / 2, top + 62), (C + w / 2 + 70, top + 62), (C + w / 2, top + 110)], fill=255)  # aba da cabeça
P = P.rotate(34, resample=Image.BICUBIC, center=(C, C))
halo = Image.new("RGBA", (S, S), (255, 200, 90, 0)); halo.putalpha(dil(P, 40).filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(v * 0.55))); img.alpha_composite(halo)
sombra = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sombra.paste((0, 0, 0, 170), (18, 26), dil(P, 10).filter(ImageFilter.GaussianBlur(12))); img.alpha_composite(sombra)
pintar(img, dil(P, 9), (30, 14, 4)); pintar(img, dil(P, 4), (110, 64, 12))
ouro = grad(OURO, S, S); ouro.putalpha(P); img.alpha_composite(ouro)
bisel(img, P, 1.0, 5)
# gravações na haste
g = Image.new("L", (S, S)); dg = ImageDraw.Draw(g)
for yv in range(top + 120, bot - 120, 46):
    dg.line([(C - w / 2 + 12, yv), (C + w / 2 - 12, yv + 14)], fill=255, width=5)
    dg.ellipse([C - 6, yv + 18, C + 6, yv + 30], fill=255)
g = g.rotate(34, resample=Image.BICUBIC, center=(C, C))
g = ImageChops.multiply(g, Image.fromarray(cv2.erode(np.array(P), np.ones((15, 15), np.uint8))))
pintar(img, g.point(lambda v: int(v * 0.55)), (120, 70, 10))
# brilho na haste
b = Image.new("L", (S, S)); ImageDraw.Draw(b).rectangle([C - w / 2 + 10, top + 70, C - w / 2 + 22, bot - 130], fill=255)
b = b.rotate(34, resample=Image.BICUBIC, center=(C, C)).filter(ImageFilter.GaussianBlur(4))
pintar(img, b.point(lambda v: int(v * 0.8)), (255, 252, 230))
# brilhos
def estrela(d, x, y, r):
    d.polygon([(x, y - r), (x + r * 0.18, y - r * 0.18), (x + r, y), (x + r * 0.18, y + r * 0.18), (x, y + r), (x - r * 0.18, y + r * 0.18), (x - r, y), (x - r * 0.18, y - r * 0.18)], fill=255)
st = Image.new("L", (S, S)); ds = ImageDraw.Draw(st)
for x, y, rr in ((330, 230, 48), (720, 760, 30), (760, 330, 22), (250, 600, 18), (450, 150, 14)):
    estrela(ds, x, y, rr)
pintar(img, st.filter(ImageFilter.GaussianBlur(5)), (255, 220, 120)); pintar(img, st, (255, 250, 220))
# aro dourado
aro = Image.new("L", (S, S)); da = ImageDraw.Draw(aro)
da.ellipse([40, 40, S - 40, S - 40], fill=255); da.ellipse([78, 78, S - 78, S - 78], fill=0)
pintar(img, dil(aro, 6), (30, 14, 4)); o2 = grad(OURO, S, S); o2.putalpha(aro); img.alpha_composite(o2); bisel(img, aro, 1.0, 4)
# rebites no aro
rb = Image.new("L", (S, S)); dr = ImageDraw.Draw(rb)
for i in range(24):
    a = i * 2 * math.pi / 24; x = C + (S / 2 - 59) * math.cos(a); y = C + (S / 2 - 59) * math.sin(a)
    dr.ellipse([x - 7, y - 7, x + 7, y + 7], fill=255)
pintar(img, rb, (150, 95, 25)); bisel(img, rb, 1.0, 2)
img.resize((512, 512), Image.LANCZOS).save("badge_pioneer_512.png")
