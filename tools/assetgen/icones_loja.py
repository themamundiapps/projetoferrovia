# Ícones simples (sem texto) dos produtos da loja: arte/loja/<id>.png, 512 x 512.
# Medalhão de mogno com aro dourado, desenho creme no meio (estilo do kit clássico).
from PIL import Image, ImageDraw
import os
S = 1024  # desenha em 2x e reduz (bordas suaves)
MOGNO, MOGNO2 = (92, 30, 28), (60, 18, 18)
OURO, OURO2 = (214, 168, 72), (150, 108, 40)
CREME, SOMBRA = (246, 232, 200), (40, 14, 12)

def base():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((24, 24, S - 24, S - 24), fill=OURO2)
    d.ellipse((44, 44, S - 44, S - 44), fill=OURO)
    d.ellipse((84, 84, S - 84, S - 84), fill=MOGNO2)
    d.ellipse((100, 100, S - 100, S - 100), fill=MOGNO)
    return im, d

def mala(d):
    # saco de dinheiro amarrado, com moedas na frente
    d.polygon([(400, 330), (624, 330), (580, 400), (444, 400)], fill=CREME)
    d.ellipse((300, 380, 724, 800), fill=CREME)
    d.rectangle((420, 380, 604, 420), fill=OURO2)
    d.ellipse((440, 250, 584, 350), fill=CREME)
    for x, y in ((270, 690), (360, 730)):
        d.ellipse((x, y, x + 150, y + 90), fill=OURO2)
        d.ellipse((x + 6, y - 14, x + 156, y + 72), fill=OURO)

def cofre(d):
    d.rounded_rectangle((270, 260, 754, 760), 40, fill=CREME)
    d.rounded_rectangle((310, 300, 714, 720), 24, fill=OURO)
    d.ellipse((400, 400, 624, 624), fill=MOGNO)
    d.ellipse((430, 430, 594, 594), fill=CREME)
    for ang in range(0, 360, 45):
        import math
        a = math.radians(ang)
        x, y = 512 + 70 * math.cos(a), 512 + 70 * math.sin(a)
        d.ellipse((x - 14, y - 14, x + 14, y + 14), fill=MOGNO)
    d.rectangle((300, 760, 380, 800), fill=CREME)
    d.rectangle((644, 760, 724, 800), fill=CREME)

def banco(d):
    d.polygon([(512, 230), (790, 400), (234, 400)], fill=CREME)
    d.rectangle((250, 410, 774, 450), fill=CREME)
    for x in (290, 410, 534, 654):
        d.rectangle((x, 470, x + 80, 700), fill=CREME)
    d.rectangle((240, 710, 784, 760), fill=CREME)
    d.rectangle((210, 770, 814, 810), fill=CREME)
    d.ellipse((482, 300, 542, 360), fill=OURO)

def impulso(d):
    d.polygon([(580, 200), (330, 560), (500, 560), (430, 830), (700, 440), (530, 440), (620, 200)], fill=OURO)
    d.polygon([(560, 230), (370, 535), (520, 535), (470, 760), (660, 465), (505, 465), (590, 230)], fill=CREME)

def estudo(d):
    # prancheta com planta da ferrovia e um visto
    d.rounded_rectangle((300, 240, 724, 800), 30, fill=CREME)
    d.rounded_rectangle((430, 210, 594, 280), 20, fill=OURO)
    for y in (360, 440, 520):
        d.rectangle((360, y, 660, y + 22), fill=OURO2)
    d.line([(390, 640), (470, 720), (640, 560)], fill=(70, 130, 60), width=48, joint="curve")

# ---- passes (permanentes): mesmo medalhão, miolo azul-petróleo para diferenciar dos produtos
PETROLEO, PETROLEO2 = (24, 70, 84), (14, 44, 54)

def base_passe():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((24, 24, S - 24, S - 24), fill=OURO2)
    d.ellipse((44, 44, S - 44, S - 44), fill=OURO)
    d.ellipse((84, 84, S - 84, S - 84), fill=PETROLEO2)
    d.ellipse((100, 100, S - 100, S - 100), fill=PETROLEO)
    return im, d

def moeda(d, x, y, r):
    d.ellipse((x - r, y - r + 18, x + r, y + r + 18), fill=OURO2)
    d.ellipse((x - r, y - r, x + r, y + r), fill=OURO)
    d.ellipse((x - r * 0.7, y - r * 0.7, x + r * 0.7, y + r * 0.7), outline=OURO2, width=14)

def dobro(d):
    # duas moedas grandes e uma seta para cima
    moeda(d, 400, 600, 150)
    moeda(d, 600, 480, 150)
    d.polygon([(512, 190), (660, 350), (570, 350), (570, 420), (454, 420), (454, 350), (364, 350)], fill=CREME)

def gerente(d):
    # engrenagem
    import math
    cx, cy = 512, 512
    pts = []
    for i in range(16):
        a = math.radians(i * 22.5)
        r = 300 if i % 2 == 0 else 230
        for da in (-7, 7):
            b = a + math.radians(da)
            pts.append((cx + r * math.cos(b), cy + r * math.sin(b)))
    d.polygon(pts, fill=CREME)
    d.ellipse((cx - 110, cy - 110, cx + 110, cy + 110), fill=PETROLEO)
    d.ellipse((cx - 60, cy - 60, cx + 60, cy + 60), fill=OURO)

def estudos(d):
    # ampulheta
    d.rectangle((330, 220, 694, 270), fill=OURO)
    d.rectangle((330, 754, 694, 804), fill=OURO)
    d.polygon([(370, 270), (654, 270), (540, 512), (654, 754), (370, 754), (484, 512)], fill=CREME)
    d.polygon([(420, 300), (604, 300), (512, 470)], fill=OURO)
    d.polygon([(512, 600), (610, 730), (414, 730)], fill=OURO)

def offline(d):
    # lua crescente e estrelas (a renda continua à noite)
    d.ellipse((290, 260, 730, 700), fill=CREME)
    d.ellipse((400, 210, 800, 610), fill=PETROLEO)
    import math
    def estrela(x, y, r):
        pts = []
        for i in range(10):
            a = math.radians(-90 + i * 36)
            rr = r if i % 2 == 0 else r * 0.45
            pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
        d.polygon(pts, fill=OURO)
    estrela(690, 640, 70)
    estrela(600, 790, 45)
    estrela(760, 470, 40)

def pinturas(d):
    # locomotiva a vapor dourada
    d.rectangle((260, 470, 640, 640), fill=OURO)          # caldeira
    d.rectangle((600, 360, 780, 640), fill=OURO)          # cabine
    d.rectangle((630, 400, 750, 480), fill=PETROLEO)      # janela
    d.rectangle((300, 360, 370, 470), fill=OURO)          # chaminé
    d.rectangle((285, 340, 385, 370), fill=OURO2)
    d.rectangle((230, 640, 800, 670), fill=OURO2)
    for x in (330, 480, 680):
        d.ellipse((x - 75, 610, x + 75, 760), fill=CREME)
        d.ellipse((x - 30, 655, x + 30, 715), fill=OURO2)
    for (x, y, r) in ((230, 290, 40), (300, 250, 30), (190, 230, 25)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=CREME)

os.makedirs("arte/loja", exist_ok=True)
for nome, f in [("dobro", dobro), ("gerente", gerente), ("estudos", estudos), ("offline", offline), ("pinturas", pinturas)]:
    im, d = base_passe()
    f(d)
    im.resize((512, 512), Image.LANCZOS).save(f"arte/loja/{nome}.png")
for nome, f in [("mala", mala), ("cofre", cofre), ("banco", banco), ("impulso", impulso), ("estudo", estudo)]:
    im, d = base()
    f(d)
    im.resize((512, 512), Image.LANCZOS).save(f"arte/loja/{nome}.png")
print("ok")
