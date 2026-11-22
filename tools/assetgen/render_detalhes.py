"""Grade de detalhe de um mapa: blocos de 256 px do mapa base desenhados a 4x, só onde passam trilhos.

Passos (MAPA = brasil ou eua; padrão brasil):
  python3 render_detalhes.py --grade <grade.json> [MAPA]          # calcula as células a partir das linhas
  node detalhe_grade.mjs <grade.json> <faixas.json> [MAPA]         # caminhos SVG por faixa
  python3 render_detalhes.py --render <grade.json> <faixas.json> <arte/mapas> [MAPA]   # tiles + manifesto
  python3 mapas_detalhe.py [MAPA]                                  # escreve Mapas.<mapa>.detalhes
Os estilos repetem os do Sudeste original (traços conferidos pixel a pixel).
"""
import io, json, os, re, sys

C, ESCALA, MARGEM = 256, 4, 40
# origem da grade de cada mapa (no Brasil, alinhada à antiga caixa do Sudeste)
ORIGEM = {"brasil": (208, 144), "eua": (0, 0)}
ARQ_DADOS = {"brasil": "Brasil", "eua": "EUA"}
MAPA = "brasil"
OX, OY = ORIGEM[MAPA]
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")


def grade(saida):
    s = open(os.path.join(RAIZ, f"src/shared/Dados/{ARQ_DADOS[MAPA]}.luau")).read()
    pts = {m[0]: (float(m[1]), float(m[2])) for m in re.findall(r'(\w+) = \{ nome = "[^"]*",[^\n]*? pos = Vector2\.new\(([\d.]+), ([\d.]+)\)', s)}
    d = json.load(open(os.path.join(RAIZ, f"tools/dados/{MAPA}.json")))
    cel = set()
    for linha in d["linhas"]:
        for t in linha["trechos"]:
            a, b = pts[t["de"]], pts[t["para"]]
            for i in range(41):
                x, y = a[0] + (b[0] - a[0]) * i / 40, a[1] + (b[1] - a[1]) * i / 40
                for dx in (-MARGEM, 0, MARGEM):
                    for dy in (-MARGEM, 0, MARGEM):
                        cel.add((int((x + dx - OX) // C), int((y + dy - OY) // C)))
    cel = sorted(cel)
    json.dump({"C": C, "ox": OX, "oy": OY, "escala": ESCALA, "celulas": cel}, open(saida, "w"))
    print(len(cel), "células")


def render(grade_json, faixas_json, arte):
    import cairosvg
    from PIL import Image
    g = json.load(open(grade_json))
    celulas = {tuple(c) for c in g["celulas"]}
    pasta = os.path.join(arte, f"{MAPA}_detalhe")
    os.makedirs(pasta, exist_ok=True)
    T = C * ESCALA
    RIOS = {4: 4.2, 5: 3.6, 6: 3.0, 7: 2.6, 8: 2.2}
    manifesto = []
    for f in json.load(open(faixas_json)):
        W, H = f["w"], f["h"]

        def svg(corpo):
            png = cairosvg.svg2png(bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">{corpo}</svg>'.encode(), output_width=W, output_height=H)
            return Image.open(io.BytesIO(png)).convert("RGBA")

        terra = svg(f'<path d="{f["landAll"]}" fill="#FFFFFF" fill-opacity="0.45"/><path d="{f["focus"]}" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="0.6"/>')
        linhas = svg(
            f'<path d="{f["landAll"]}" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="1.5" stroke-linejoin="round"/>'
            f'<path d="{f["borders"]}" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2" stroke-dasharray="7 5" stroke-linejoin="round"/>'
            f'<path d="{f["outline"]}" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linejoin="round"/>')
        linhas.alpha_composite(svg(f'<path d="{f["divisas"]}" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2.4" stroke-dasharray="14 6 3 6" stroke-linejoin="round"/>'))
        rios = svg("".join(f'<path d="{r["d"]}" fill="none" stroke="#FFFFFF" stroke-width="{RIOS.get(int(r["rank"]), 2.0)}" stroke-linecap="round" stroke-linejoin="round"/>' for r in f["rios"]))
        cy = f["cy"]
        for i in range(W // T):
            cx = f["cx0"] + i
            if (cx, cy) not in celulas:
                continue
            bloco = {"id": f"{cx}_{cy}", "x0": OX + C * cx, "y0": OY + C * cy, "tiles": []}
            for nome, img in (("terra", terra), ("linhas", linhas), ("rios", rios)):
                c = img.crop((i * T, 0, (i + 1) * T, T))
                if c.getchannel("A").getbbox() is None:
                    continue  # bloco vazio (mar aberto, sem rio): nem envia
                arq = f"{MAPA}_detalhe_{cx}_{cy}_{nome}.png"
                c.save(os.path.join(pasta, arq), optimize=True)
                bloco["tiles"].append({"camada": nome, "arquivo": f"mapas/{MAPA}_detalhe/{arq}"})
            manifesto.append(bloco)
        print("faixa", cy, "ok")
    json.dump(manifesto, open(os.path.join(pasta, "manifesto.json"), "w"), indent=1)
    print(len(manifesto), "blocos,", sum(len(b["tiles"]) for b in manifesto), "imagens")


if __name__ == "__main__":
    if sys.argv[1] == "--grade":
        MAPA = sys.argv[3] if len(sys.argv) > 3 else "brasil"
        OX, OY = ORIGEM[MAPA]
        grade(sys.argv[2])
    else:
        MAPA = sys.argv[5] if len(sys.argv) > 5 else "brasil"
        OX, OY = ORIGEM[MAPA]
        render(sys.argv[2], sys.argv[3], sys.argv[4])
