# Ícones das badges no mesmo estilo da Pioneer: disco marrom com luz, aro dourado com rebites, objeto dourado no centro.
import math, cv2, numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
S = 1024; C = S // 2
OURO = [(255, 246, 196), (248, 212, 110), (214, 150, 40), (252, 220, 130), (170, 100, 20)]
PRATA = [(255, 255, 255), (220, 226, 236), (150, 160, 178), (214, 222, 234), (110, 118, 136)]
def grad(cores, w=S, h=S):
    t = np.linspace(0, 1, h); pos = np.linspace(0, 1, len(cores))
    g = np.stack([np.interp(t, pos, [c[i] for c in cores]) for i in range(3)], -1)
    return Image.fromarray(np.repeat(g[:, None, :], w, 1).astype(np.uint8)).convert("RGBA")
def bisel(img, m, forca=1.0, r=4):
    a = np.array(m).astype(np.float32) / 255; b = cv2.GaussianBlur(a, (0, 0), r)
    gy, gx = np.gradient(b); luz = gx * 0.6 + gy * 0.8; luz /= (np.abs(luz).max() + 1e-6)
    for v, cor, k in ((np.clip(-luz, 0, 1), (255, 250, 225), 235), (np.clip(luz, 0, 1), (40, 18, 0), 190)):
        c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(Image.fromarray((v * a * forca * k).astype(np.uint8))); img.alpha_composite(c)
def pintar(img, m, cor):
    c = Image.new("RGBA", img.size, cor + (0,)); c.putalpha(m); img.alpha_composite(c)
def dil(m, r):
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1)); return Image.fromarray(cv2.dilate(np.array(m), k))
def M(): return Image.new("L", (S, S))
def metal(img, m, cores=OURO, contorno=True, halo=False):
    if halo:
        h = Image.new("RGBA", (S, S), (255, 200, 90, 0)); h.putalpha(dil(m, 40).filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(v * 0.5))); img.alpha_composite(h)
    if contorno:
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sh.paste((0, 0, 0, 160), (14, 22), dil(m, 10).filter(ImageFilter.GaussianBlur(10))); img.alpha_composite(sh)
        pintar(img, dil(m, 9), (30, 14, 4)); pintar(img, dil(m, 4), (110, 64, 12) if cores is OURO else (50, 54, 66))
    g = grad(cores); g.putalpha(m); img.alpha_composite(g); bisel(img, m, 1.0, 4)
def estrela(d, x, y, r):
    d.polygon([(x, y - r), (x + r * 0.18, y - r * 0.18), (x + r, y), (x + r * 0.18, y + r * 0.18), (x, y + r), (x - r * 0.18, y + r * 0.18), (x - r, y), (x - r * 0.18, y - r * 0.18)], fill=255)
def base(fundo=((120, 50, 25), (72, 30, 22), (32, 14, 10))):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    yy, xx = np.mgrid[0:S, 0:S]; r = np.hypot(xx - C, yy - C * 0.9) / (S * 0.5)
    f = np.stack([np.interp(r, [0, 0.6, 1.1], [a, b, c]) for a, b, c in zip(*fundo)], -1)
    d = Image.fromarray(f.astype(np.uint8)).convert("RGBA"); md = M(); ImageDraw.Draw(md).ellipse([60, 60, S - 60, S - 60], fill=255)
    d.putalpha(md); img.alpha_composite(d); return img
def acabamento(img, brilhos):
    md = M(); ImageDraw.Draw(md).ellipse([62, 62, S - 62, S - 62], fill=255)
    img.putalpha(ImageChops.multiply(img.split()[3], md))
    st = M(); ds = ImageDraw.Draw(st)
    for x, y, rr in brilhos: estrela(ds, x, y, rr)
    pintar(img, st.filter(ImageFilter.GaussianBlur(5)), (255, 220, 120)); pintar(img, st, (255, 250, 220))
    aro = M(); da = ImageDraw.Draw(aro); da.ellipse([40, 40, S - 40, S - 40], fill=255); da.ellipse([78, 78, S - 78, S - 78], fill=0)
    pintar(img, dil(aro, 6), (30, 14, 4)); g = grad(OURO); g.putalpha(aro); img.alpha_composite(g); bisel(img, aro, 1.0, 4)
    rb = M(); dr = ImageDraw.Draw(rb)
    for i in range(24):
        a = i * 2 * math.pi / 24; x = C + (S / 2 - 59) * math.cos(a); y = C + (S / 2 - 59) * math.sin(a)
        dr.ellipse([x - 7, y - 7, x + 7, y + 7], fill=255)
    pintar(img, rb, (150, 95, 25)); bisel(img, rb, 1.0, 2)
    return img.resize((512, 512), Image.LANCZOS)

def diesel():
    img = base()
    # locomotiva diesel de frente: caixa com nariz, janelas, farol, faixas
    corpo = M(); d = ImageDraw.Draw(corpo)
    d.rounded_rectangle([300, 250, 724, 720], 60, fill=255)
    d.polygon([(300, 560), (724, 560), (760, 760), (264, 760)], fill=255)  # saia
    metal(img, corpo, halo=True)
    jan = M(); dj = ImageDraw.Draw(jan)
    dj.rounded_rectangle([340, 300, 500, 420], 20, fill=255); dj.rounded_rectangle([524, 300, 684, 420], 20, fill=255)
    pintar(img, dil(jan, 5), (30, 14, 4)); g = grad([(70, 110, 140), (30, 50, 70)]); g.putalpha(jan); img.alpha_composite(g)
    fx = M(); df = ImageDraw.Draw(fx)
    for y in (480, 530):
        df.rectangle([300, y, 724, y + 22], fill=255)
    pintar(img, fx, (150, 32, 28)); bisel(img, fx, 0.6, 2)
    far = M(); ImageDraw.Draw(far).ellipse([462, 600, 562, 700], fill=255)
    pintar(img, dil(far, 6), (30, 14, 4)); pintar(img, far, (255, 240, 190))
    gl = Image.new("RGBA", (S, S), (255, 230, 150, 0)); gl.putalpha(dil(far, 30).filter(ImageFilter.GaussianBlur(25)).point(lambda v: v // 2)); img.alpha_composite(gl)
    ac = M(); da = ImageDraw.Draw(ac)
    for x in (330, 694): da.ellipse([x - 30, 620, x + 30, 680], fill=255)
    pintar(img, dil(ac, 5), (30, 14, 4)); pintar(img, ac, (200, 60, 40))
    return acabamento(img, ((250, 260, 40), (800, 330, 26), (770, 760, 20), (220, 640, 16)))

def eletrica():
    img = base(((40, 60, 95), (26, 34, 60), (12, 14, 28)))
    # fio aéreo, pantógrafo em losango e raio dourado
    fio = M(); df = ImageDraw.Draw(fio); df.rectangle([110, 250, 914, 266], fill=255)
    metal(img, fio, PRATA)
    pan = M(); dp = ImageDraw.Draw(pan)
    for a, b in (((512, 270), (380, 450)), ((380, 450), (512, 630)), ((512, 270), (644, 450)), ((644, 450), (512, 630))):
        dp.line([a, b], fill=255, width=26)
    dp.rectangle([400, 258, 624, 282], fill=255)
    dp.rounded_rectangle([330, 630, 694, 700], 16, fill=255)
    metal(img, pan, PRATA)
    raio = M(); dr = ImageDraw.Draw(raio)
    dr.polygon([(600, 280), (470, 520), (560, 520), (430, 800), (680, 470), (585, 470), (690, 280)], fill=255)
    metal(img, raio, halo=True)
    return acabamento(img, ((260, 380, 40), (790, 600, 28), (300, 760, 18), (760, 330, 16)))

def alta():
    img = base(((40, 60, 95), (26, 34, 60), (12, 14, 28)))
    # linhas de velocidade
    lv = M(); dl = ImageDraw.Draw(lv)
    for y, x0, w in ((400, 100, 9), (470, 70, 7), (560, 60, 9), (690, 110, 6)):
        dl.line([(x0, y), (x0 + 120, y)], fill=255, width=w)
    pintar(img, lv.filter(ImageFilter.GaussianBlur(2)), (255, 220, 140))
    # trem-bala de lado, nariz arredondado para a direita
    tb = M(); dt = ImageDraw.Draw(tb)
    pts = [(150, 650), (150, 440), (520, 440)]
    for t in np.linspace(0, 1, 60):
        x = 520 + 360 * t; y = 440 + 205 * (1 - math.cos(t * math.pi / 2)) ** 1.3
        pts.append((x, y))
    pts += [(880, 650)]
    dt.polygon(pts, fill=255)
    metal(img, tb, PRATA)
    fx = M(); dfx = ImageDraw.Draw(fx)
    dfx.polygon([(150, 575), (820, 600), (835, 625), (150, 612)], fill=255)
    g = grad(OURO); g.putalpha(fx); img.alpha_composite(g); bisel(img, fx, 0.8, 2)
    jan = M(); dj = ImageDraw.Draw(jan)
    dj.polygon([(600, 470), (720, 490), (780, 540), (600, 540)], fill=255)
    for x in (190, 290, 390, 490): dj.rounded_rectangle([x, 480, x + 70, 525], 12, fill=255)
    pintar(img, jan, (40, 70, 110)); bisel(img, jan, 0.5, 2)
    luz = M(); ImageDraw.Draw(luz).ellipse([835, 600, 865, 625], fill=255)
    pintar(img, luz, (255, 245, 200))
    tr = M(); ImageDraw.Draw(tr).rectangle([150, 680, 880, 700], fill=255)
    metal(img, tr)
    return acabamento(img, ((780, 360, 40), (250, 330, 22), (840, 760, 18), (480, 400, 14)))

def dono():
    img = base()
    # cartola dourada com faixa vermelha e monóculo
    ca = M(); dc = ImageDraw.Draw(ca)
    dc.rounded_rectangle([370, 230, 654, 620], 30, fill=255)
    dc.ellipse([250, 580, 774, 690], fill=255)
    metal(img, ca, [(70, 60, 60), (40, 34, 36), (20, 16, 18), (50, 44, 46), (14, 10, 12)], halo=False)
    h = Image.new("RGBA", (S, S), (255, 200, 90, 0)); h.putalpha(dil(ca, 40).filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(v * 0.45))); img.alpha_composite(h)
    g = grad([(70, 60, 60), (40, 34, 36), (20, 16, 18), (50, 44, 46), (14, 10, 12)]); g.putalpha(ca); img.alpha_composite(g); bisel(img, ca, 1.0, 5)
    fa = M(); ImageDraw.Draw(fa).rectangle([370, 520, 654, 590], fill=255)
    pintar(img, fa, (170, 34, 30)); bisel(img, fa, 0.7, 3)
    fo = M(); ImageDraw.Draw(fo).rounded_rectangle([370, 516, 654, 528], 4, fill=255)
    g = grad(OURO); g.putalpha(fo); img.alpha_composite(g)
    mo = M(); dm = ImageDraw.Draw(mo); dm.ellipse([560, 640, 760, 840], fill=255); dm.ellipse([592, 672, 728, 808], fill=0)
    metal(img, mo)
    lente = M(); ImageDraw.Draw(lente).ellipse([592, 672, 728, 808], fill=255)
    pintar(img, lente.point(lambda v: v // 3), (220, 240, 255))
    co = M(); ImageDraw.Draw(co).line([(590, 790), (470, 860), (380, 850)], fill=255, width=10)
    metal(img, co, contorno=False)
    return acabamento(img, ((280, 300, 42), (760, 290, 26), (260, 720, 18), (520, 180, 14)))

if __name__ == "__main__":
    for nome, f in (("diesel", diesel), ("eletrica", eletrica), ("alta", alta), ("dono", dono)):
        f().save(f"badge_{nome}_512.png")
    ims = [Image.open(f"badge_{n}_512.png") for n in ("diesel", "eletrica", "alta", "dono")]
    c = Image.new("RGBA", (1040, 260), (60, 60, 60, 255))
    for i, im in enumerate(ims): c.alpha_composite(im.resize((250, 250)), (5 + i * 260, 5))
    c.convert("RGB").save("/tmp/badges.png")
