import ads2
from ads2 import *
ads2.W, ads2.H = 1456, 180  # desenha em 2x e reduz para 728x90
import importlib
Wb, Hb = 1456, 180
img = Image.new("RGBA", (Wb, Hb), (70, 16, 12, 255)); d = ImageDraw.Draw(img)
for i in range(0, 40, 2):
    a0, a1 = i * math.pi / 20, (i + 1) * math.pi / 20
    d.polygon([(330, 90), (330 + 2000 * math.cos(a0), 90 + 2000 * math.sin(a0)), (330 + 2000 * math.cos(a1), 90 + 2000 * math.sin(a1))], fill=(98, 26, 18))
lh = round(LOGO.height * 340 / LOGO.width); img.alpha_composite(LOGO.resize((340, lh), Image.LANCZOS), (20, (Hb - lh) // 2))
camada = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
texto(camada, "FROM ONE LINE", 0, 0, 50, estilo="branco", ancora="esq")
texto(camada, "TO A CONTINENT", 0, 62, 54, estilo="ouro", ancora="esq")
t = camada.crop(camada.getbbox()); img.alpha_composite(t, (395, (Hb - t.height) // 2))
foto = preencher(quadro("h15", 17.0, 1000, 470, 1.15), 330, 150)
c = Image.new("RGBA", (342, 162), (250, 244, 228, 255)); c.alpha_composite(foto, (6, 6)); c = c.rotate(3, resample=Image.BICUBIC, expand=True)
img.alpha_composite(c, (Wb - c.width - 14, (Hb - c.height) // 2))
img.resize((728, 90), Image.LANCZOS).convert("RGB").save("ad2_banner_728x90.png")
