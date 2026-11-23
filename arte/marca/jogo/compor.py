# Ícone e miniatura com prints do próprio jogo (modo gravação no Studio) e o kit de UI da Era do Vapor.
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
AQUI = os.path.dirname(os.path.abspath(__file__))
ARTE = os.path.abspath(os.path.join(AQUI, "..", ".."))
FONTES = os.path.expanduser("~/.fonts")
INK = (59, 42, 26); ACCENT = (142, 43, 35); PANEL = (247, 240, 222)

def fonte(nome, t): return ImageFont.truetype(os.path.join(FONTES, nome), t)
def kit(nome): return Image.open(os.path.join(ARTE, "ui", "classico", nome)).convert("RGBA")

def texto_centro(d, cx, y, txt, f, cor, espaco=0, sombra=None):
    # largura com espaçamento entre letras
    larg = sum(d.textlength(ch, font=f) for ch in txt) + espaco * (len(txt) - 1)
    x = cx - larg / 2
    for ch in txt:
        if sombra: d.text((x + 2, y + 2), ch, font=f, fill=sombra)
        d.text((x, y), ch, font=f, fill=cor)
        x += d.textlength(ch, font=f) + espaco

def vinheta(img, forca=0.55):
    w, h = img.size
    m = Image.new("L", (w, h), 0)
    dm = ImageDraw.Draw(m)
    dm.ellipse([-w * 0.25, -h * 0.25, w * 1.25, h * 1.25], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(min(w, h) * 0.18))
    escuro = Image.new("RGBA", (w, h), (40, 26, 14, int(255 * forca)))
    base = img.copy()
    base.paste(escuro, (0, 0), Image.eval(m, lambda v: 255 - v))
    return Image.alpha_composite(img, Image.composite(Image.new("RGBA", (w, h), (0, 0, 0, 0)), escuro, m))

def icone(mapa, nome1, saida):
    base = Image.open(mapa).convert("RGBA")
    # recorte quadrado em volta de Paris, Bélgica e Renânia
    x0, y0, lado = 330, 40, 572
    img = base.crop((x0, y0, x0 + lado, y0 + lado)).resize((512, 512), Image.LANCZOS)
    img = ImageEnhance.Contrast(img).enhance(1.06)
    img = vinheta(img, 0.35)
    # placa do nome (a mesma das cidades no jogo)
    placa = kit("placa_cidade.png")
    pw = 488; ph = round(placa.height * pw / placa.width)
    placa = placa.resize((pw, ph), Image.LANCZOS)
    sombra = Image.new("RGBA", placa.size, (0, 0, 0, 0)); sombra.putalpha(placa.split()[3].point(lambda a: int(a * 0.55)))
    sombra = sombra.filter(ImageFilter.GaussianBlur(6))
    py = 512 - ph - 10
    img.alpha_composite(sombra, ((512 - pw) // 2 + 3, py + 6))
    img.alpha_composite(placa, ((512 - pw) // 2, py))
    d = ImageDraw.Draw(img)
    f1 = fonte("Merriweather-Black.ttf", 50 if len(nome1) <= 7 else 46)
    f2 = fonte("SpecialElite.ttf", 26)
    texto_centro(d, 256, py + 22, nome1, f1, INK, espaco=1)
    texto_centro(d, 256, py + 92, "TYCOON", f2, ACCENT, espaco=9)
    img.convert("RGB").save(saida)

def miniatura(mapa, nome1, frase, mapas_txt, saida):
    W, H = 1920, 1080
    base = Image.open(mapa).convert("RGBA")
    esc = H / base.height
    m = base.resize((round(base.width * esc), H), Image.LANCZOS)
    m = m.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
    img = Image.new("RGBA", (W, H))
    img.alpha_composite(m, (W - m.width, 0) if m.width >= W else (0, 0))
    if m.width < W:
        img = img.resize((W, H))
    # painel do título à direita (painel_3 do kit)
    painel = kit("painel_3.png")
    pw = 820; ph = round(painel.height * pw / painel.width)
    painel = painel.resize((pw, ph), Image.LANCZOS)
    px, py = W - pw - 56, H - ph - 110
    sombra = Image.new("RGBA", painel.size, (0, 0, 0, 0)); sombra.putalpha(painel.split()[3].point(lambda a: int(a * 0.6)))
    sombra = sombra.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(sombra, (px + 8, py + 14))
    img.alpha_composite(painel, (px, py))
    d = ImageDraw.Draw(img)
    cx = px + pw / 2
    f1 = fonte("Merriweather-Black.ttf", 88 if len(nome1) <= 7 else 80)
    f2 = fonte("SpecialElite.ttf", 46)
    f3 = fonte("Merriweather-Bold.ttf", 32)
    f4 = fonte("SpecialElite.ttf", 25)
    texto_centro(d, cx, py + 52, nome1, f1, INK, espaco=2)
    texto_centro(d, cx, py + 160, "TYCOON", f2, ACCENT, espaco=16)
    div = kit("divisor.png"); dw = 520; div = div.resize((dw, round(div.height * dw / div.width)), Image.LANCZOS)
    img.alpha_composite(div, (round(cx - dw / 2), py + 222))
    texto_centro(d, cx, py + 262, frase, f3, INK)
    texto_centro(d, cx, py + 312, mapas_txt, f4, (107, 86, 64), espaco=3)
    img.convert("RGB").save(saida)

if __name__ == "__main__":
    t = sys.argv[1]
    icone(os.path.join(t, "europa_media_semtexto.jpg"), "RAILWAY", os.path.join(AQUI, "icone_en.png"))
    icone(os.path.join(t, "europa_media_semtexto.jpg"), "FERROVIA", os.path.join(AQUI, "icone_pt.png"))
    miniatura(os.path.join(t, "europa_rede.jpg"), "RAILWAY", "Build a railway empire", "BRAZIL · USA · EUROPE", os.path.join(AQUI, "miniatura_en.png"))
    miniatura(os.path.join(t, "europa_rede.jpg"), "FERROVIA", "Construa um império ferroviário", "BRASIL · EUA · EUROPA", os.path.join(AQUI, "miniatura_pt.png"))
