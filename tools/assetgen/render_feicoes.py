"""Renderiza rios (camada nova) e divisas de estados (somadas à camada de contorno) em tiles brancos.

Entrada: feicoes.json (de feicoes.mjs) e as camadas de contorno completas já renderizadas.
Uso: python3 render_feicoes.py <feicoes.json> <pasta_com_*_linhas_full.png> <pasta arte/mapas>
"""
import io, json, os, sys
import cairosvg
from PIL import Image

feicoes = json.load(open(sys.argv[1]))
FULL = sys.argv[2]
ARTE = sys.argv[3]
TILE = 1024

CONFIG = {
    # alvo: (prefixo dos arquivos, pasta, arquivo da camada de contorno completa, larguras dos rios por rank, estilo das divisas)
    "base": ("brasil", "brasil", "brasil_linhas_full.png", {4: 2.4, 5: 2.0, 6: 1.6}, (1.6, "6 3 1.5 3", 0.5)),
    "sudeste": ("brasil_sudeste", "brasil_sudeste", "sudeste_linhas_full.png", {4: 4.2, 5: 3.6, 6: 3.0, 7: 2.6, 8: 2.2}, (2.4, "14 6 3 6", 0.55)),
}


def render(svg, w, h):
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h))).convert("RGBA")


def fatiar(img, pasta, prefixo, camada):
    arquivos = []
    for ty in range(0, img.height, TILE):
        for tx in range(0, img.width, TILE):
            c = img.crop((tx, ty, min(tx + TILE, img.width), min(ty + TILE, img.height)))
            nome = f"{prefixo}_{camada}_{ty // TILE}_{tx // TILE}.png"
            c.save(os.path.join(ARTE, pasta, nome), optimize=True)
            arquivos.append({"camada": camada, "x": tx, "y": ty, "w": c.width, "h": c.height, "arquivo": f"mapas/{pasta}/{nome}"})
    return arquivos


manifesto = {}
for alvo, (prefixo, pasta, contorno, larguras, (dw, dash, dalpha)) in CONFIG.items():
    f = feicoes[alvo]
    W, H = f["w"], f["h"]
    rios = "".join(
        f'<path d="{r["d"]}" fill="none" stroke="#FFFFFF" stroke-width="{larguras.get(int(r["rank"]), 2.0)}" stroke-linecap="round" stroke-linejoin="round"/>'
        for r in f["rios"]
    )
    camada_rios = render(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">{rios}</svg>', W, H)
    divisas = render(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}"><path d="{f["divisas"]}" fill="none" stroke="#FFFFFF" '
        f'stroke-opacity="{dalpha}" stroke-width="{dw}" stroke-dasharray="{dash}" stroke-linejoin="round"/></svg>', W, H)
    linhas = Image.open(os.path.join(FULL, contorno)).convert("RGBA")
    linhas.alpha_composite(divisas)
    manifesto[alvo] = fatiar(camada_rios, pasta, prefixo, "rios") + fatiar(linhas, pasta, prefixo, "linhas")
    print(alvo, W, H, len(manifesto[alvo]), "tiles")

json.dump(manifesto, open(os.path.join(FULL, "feicoes_manifest.json"), "w"), indent=1)
