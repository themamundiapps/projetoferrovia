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

os.makedirs("arte/loja", exist_ok=True)
for nome, f in [("mala", mala), ("cofre", cofre), ("banco", banco), ("impulso", impulso), ("estudo", estudo)]:
    im, d = base()
    f(d)
    im.resize((512, 512), Image.LANCZOS).save(f"arte/loja/{nome}.png")
print("ok")
