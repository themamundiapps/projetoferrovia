"""Escreve o bloco Mapas.brasil.detalhes em src/shared/Mapas.luau a partir do manifesto da grade
(arte/mapas/brasil_detalhe/manifesto.json) e dos ids enviados (arte/mapas/brasil_detalhe/ids.json: arquivo -> id).
Uso: python3 mapas_detalhe.py
"""
import json, os, re

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PASTA = os.path.join(RAIZ, "arte/mapas/brasil_detalhe")
manifesto = json.load(open(os.path.join(PASTA, "manifesto.json")))
ids_arq = os.path.join(PASTA, "ids.json")
ids = json.load(open(ids_arq)) if os.path.exists(ids_arq) else {}

linhas = [
    "-- Regiões de detalhe: blocos de 256 px do mapa base desenhados a 4x, só onde passam trilhos (gerados por",
    "-- tools/assetgen/render_detalhes.py e mapas_detalhe.py). Aparecem por cima do mapa base a partir de ZOOM_DETALHE.",
    "-- x0/y0/largura/altura em pixels do mapa base; escala = pixels do detalhe por pixel do mapa base.",
    "Mapas.brasil.detalhes = {",
]
for b in manifesto:
    linhas.append(f'\t{{ id = "{b["id"]}", x0 = {b["x0"]}, y0 = {b["y0"]}, largura = 256, altura = 256, escala = 4, tiles = {{')
    for t in b["tiles"]:
        linhas.append(f'\t\t{{ camada = "{t["camada"]}", x = 0, y = 0, w = 1024, h = 1024, id = "{ids.get(t["arquivo"], "rbxassetid://0")}", arquivo = "{t["arquivo"]}" }},')
    linhas.append("\t} },")
linhas.append("}")

p = os.path.join(RAIZ, "src/shared/Mapas.luau")
s = open(p).read()
i = s.index("-- Regiões de detalhe:")
j = s.index("\nreturn Mapas")
s = s[:i] + "\n".join(linhas) + "\n" + s[j:]
open(p, "w").write(s)
faltam = sum(1 for b in manifesto for t in b["tiles"] if t["arquivo"] not in ids)
print(len(manifesto), "blocos;", faltam, "imagens sem id")
