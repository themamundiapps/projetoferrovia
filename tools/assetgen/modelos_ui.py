"""Gera os modelos (PNG) das peças do kit de UI: proporção certa e linhas de corte do fatiamento em 9.
Uso: python3 modelos_ui.py <pasta_saida>
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

# arquivo: (largura, altura, corte em px no tamanho final, descrição)  corte None = não estica
PECAS = {
    "painel": (512, 512, 64, "moldura de painel"),
    "cartao": (256, 256, 24, "cartão"),
    "botao": (384, 128, 40, "botão principal"),
    "botao_discreto": (384, 128, 32, "botão discreto"),
    "aba": (256, 128, 32, "aba do menu"),
    "barra_fundo": (512, 32, 14, "trilho da barra"),
    "barra_cheia": (512, 32, 14, "preenchimento da barra"),
    "cabecalho": (640, 128, 56, "faixa de título"),
    "divisor": (512, 32, None, "divisor (não estica)"),
    "botao_redondo": (128, 128, 40, "botão redondo"),
    "selo": (256, 256, None, "selo (não estica)"),
}

ESCALA = 2
MARGEM = 60

def fonte(t):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, t)
    return ImageFont.load_default()

def tracejado(d, a, b, cor, larg=3, passo=14):
    (x0, y0), (x1, y1) = a, b
    comp = max(abs(x1 - x0), abs(y1 - y0))
    n = int(comp // passo)
    for i in range(0, n, 2):
        t0, t1 = i / n, min(1, (i + 1) / n)
        d.line([(x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0), (x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1)], fill=cor, width=larg)

saida = sys.argv[1]
os.makedirs(saida, exist_ok=True)
for nome, (w, h, corte, desc) in PECAS.items():
    W, H = w * ESCALA, h * ESCALA
    img = Image.new("RGB", (W + 2 * MARGEM, H + 2 * MARGEM + 50), (236, 236, 236))
    d = ImageDraw.Draw(img)
    x0, y0 = MARGEM, MARGEM + 50
    d.rectangle([x0, y0, x0 + W, y0 + H], fill=(255, 255, 255), outline=(60, 60, 60), width=2)
    f, fp = fonte(22), fonte(15)
    d.text((MARGEM, 14), f"{nome}.png · {desc} · final {w}×{h} px" + (f" · corte {corte} px" if corte else ""), fill=(30, 30, 30), font=f)
    if corte:
        c = corte * ESCALA
        cinza = (255, 214, 120)
        for cx, cy in ((x0, y0), (x0 + W - c, y0), (x0, y0 + H - c), (x0 + W - c, y0 + H - c)):
            d.rectangle([cx, cy, cx + c, cy + c], fill=cinza)
        borda = (205, 232, 255)
        d.rectangle([x0 + c, y0, x0 + W - c, y0 + c], fill=borda)
        d.rectangle([x0 + c, y0 + H - c, x0 + W - c, y0 + H], fill=borda)
        d.rectangle([x0, y0 + c, x0 + c, y0 + H - c], fill=borda)
        d.rectangle([x0 + W - c, y0 + c, x0 + W, y0 + H - c], fill=borda)
        mag = (220, 0, 160)
        for xx in (x0 + c, x0 + W - c):
            tracejado(d, (xx, y0 - 20), (xx, y0 + H + 20), mag)
        for yy in (y0 + c, y0 + H - c):
            tracejado(d, (x0 - 20, yy), (x0 + W + 20, yy), mag)
        d.rectangle([x0, y0, x0 + W, y0 + H], outline=(60, 60, 60), width=2)
        if c >= 40:
            d.text((x0 + 6, y0 + 6), "canto fixo", fill=(120, 80, 0), font=fp)
        if W - 2 * c > 120 and H - 2 * c > 30:
            d.text((x0 + W / 2 - 70, y0 + H / 2 - 9), "meio estica (liso)", fill=(110, 110, 110), font=fp)
        if c >= 40 and W - 2 * c > 120:
            d.text((x0 + W / 2 - 40, y0 + 6), "borda estica", fill=(40, 90, 140), font=fp)
    else:
        d.text((x0 + 10, y0 + H / 2 - 9), "não estica: desenho inteiro aqui", fill=(110, 110, 110), font=fp)
    img.save(os.path.join(saida, f"{nome}.png"))
    print(nome, img.size)
