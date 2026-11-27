from ads2 import *
img = raios((22, 26, 48), (34, 40, 70), cy=H * 0.5)
texto(img, "HOW FAR WILL YOU GO?", W / 2, 22, 112, estilo="ouro")
texto(img, "4 ERAS  ·  3 MAPS  ·  112 LINES", W / 2, 165, 46, fonte="Rye-Regular.ttf", estilo="branco", esp=0.05)
eras = [("h10", 3.0, 960, 560, 1.6, "STEAM", "vapor"), ("h13", 4.0, 960, 560, 1.6, "DIESEL", "diesel"),
        ("h14", 4.0, 1000, 560, 1.6, "ELECTRIC", "eletrica"), ("h15", 4.0, 960, 560, 1.6, "HIGH SPEED", "alta")]
xs = [285, 735, 1185, 1635]; rots = [-5, 3, -3, 5]
for i, (s, t, cx, cy, z, nome, icone) in enumerate(eras):
    foto = quadro(s, t, cx, cy, z)
    cartao(img, foto, xs[i], 545, 380, 300, rots[i])
    ic = Image.open(f"/home/claude/badge/badge_{icone}_512.png").resize((150, 150), Image.LANCZOS)
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sh.paste((0, 0, 0, 160), (xs[i] - 75 + 6, 300 + 12), ic.split()[3].filter(ImageFilter.GaussianBlur(8))); img.alpha_composite(sh)
    img.alpha_composite(ic, (xs[i] - 75, 300))
    texto(img, nome, xs[i], 730, 54, estilo="branco" if i < 3 else "ouro")
# setinhas entre as eras
for x in (510, 960, 1410):
    m = Image.new("L", (W, H)); ImageDraw.Draw(m).polygon([(x - 22, 520), (x + 26, 548), (x - 22, 576)], fill=255)
    pintar(img, dil(m, 6), (24, 10, 4)); g = grad(OURO, W, H); g.putalpha(m); img.alpha_composite(g)
logo(img, W / 2, 845, 520)
img.convert("RGB").save("ad2_eras_1920x1080.png")
