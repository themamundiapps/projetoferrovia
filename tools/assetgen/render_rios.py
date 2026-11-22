"""Rios de um mapa em tiles brancos com transparência (a cor vem do jogo, como as outras camadas).
Entrada: JSON de tools/dados/rios_mapa.mjs. Saída: arte/mapas/<mapa>/<mapa>_rios_<linha>_<coluna>.png
Uso: python tools/assetgen/render_rios.py eua /tmp/rios_eua.json
"""
import json, os, sys
from PIL import Image, ImageDraw

MAPA, ENTRADA = sys.argv[1], sys.argv[2]
d = json.load(open(ENTRADA))
W, H = d["largura"], d["altura"]
K = 2  # desenha em 2x e reduz: bordas suaves
LARGURA = {1: 3.0, 2: 3.0, 3: 2.8, 4: 2.4, 5: 2.0, 6: 1.6, 7: 1.4, 8: 1.2}
img = Image.new("RGBA", (W * K, H * K), (255, 255, 255, 0))
dr = ImageDraw.Draw(img)
for r in sorted(d["rios"], key=lambda r: -r["rank"]):
    pts = [(x * K, y * K) for x, y in r["pts"]]
    w = LARGURA.get(int(r["rank"]), 1.6) * K
    dr.line(pts, fill=(255, 255, 255, 255), width=round(w), joint="curve")
    for x, y in (pts[0], pts[-1]):
        dr.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=(255, 255, 255, 255))
img = img.resize((W, H), Image.LANCZOS)
pasta = os.path.join(os.path.dirname(__file__), "..", "..", "arte", "mapas", MAPA)
TILE = 1024
for ty in range(0, H, TILE):
    for tx in range(0, W, TILE):
        c = img.crop((tx, ty, min(tx + TILE, W), min(ty + TILE, H)))
        nome = f"{MAPA}_rios_{ty // TILE}_{tx // TILE}.png"
        c.save(os.path.join(pasta, nome), optimize=True)
        print(nome, c.size)
