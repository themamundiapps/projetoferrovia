from ads2 import *
img = raios((60, 40, 18), (84, 58, 26), cy=H * 0.62)
texto(img, "3 MAPS.", W / 2, 22, 112, estilo="branco")
texto(img, "112 HISTORIC LINES.", W / 2, 150, 104, estilo="ouro")
mapas = [("h18", 4.0, 1000, 560, 1.15, "BRAZIL", -7, 360), ("h15", 17.0, 960, 470, 1.15, "EUROPE", 0, 960), ("h21", 4.0, 960, 500, 1.15, "USA", 7, 1560)]
# Europa por último (no meio, por cima)
for (s, t, cx, cy, z, nome, rot, x) in [mapas[0], mapas[2], mapas[1]]:
    big = nome == "EUROPE"
    w, h = (620, 440) if big else (520, 380)
    y = 590 if big else 620
    cartao(img, quadro(s, t, cx, cy, z), x, y, w, h, rot)
    texto(img, nome, x, y + h / 2 + 10, 64 if big else 56, estilo="ouro" if big else "branco", rot=rot * 0.5)
selo(img, 1250, 330, 100, [("SWITCH", 26), ("ANYTIME", 26)], cor=(30, 110, 60), rot=12) if False else None
texto(img, "Master one map to unlock the next.", W / 2, 965, 50, fonte="Rye-Regular.ttf", estilo="branco", esp=0.03)
logo(img, 210, 30, 340)
img.convert("RGB").save("ad2_mapas_1920x1080.png")
