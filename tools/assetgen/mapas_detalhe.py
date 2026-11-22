"""Escreve o bloco Mapas.<mapa>.detalhes em src/shared/Mapas.luau a partir do manifesto da grade
(arte/mapas/<mapa>_detalhe/manifesto.json) e dos ids enviados (arte/mapas/<mapa>_detalhe/ids.json: arquivo -> id).
Uso: python3 mapas_detalhe.py [brasil|eua]
"""
import json, os, re, sys

MAPA = sys.argv[1] if len(sys.argv) > 1 else "brasil"
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
PASTA = os.path.join(RAIZ, f"arte/mapas/{MAPA}_detalhe")
manifesto = json.load(open(os.path.join(PASTA, "manifesto.json")))
ids_arq = os.path.join(PASTA, "ids.json")
ids = json.load(open(ids_arq)) if os.path.exists(ids_arq) else {}

linhas = [f"Mapas.{MAPA}.detalhes = {{"]
for b in manifesto:
    linhas.append(f'\t{{ id = "{b["id"]}", x0 = {b["x0"]}, y0 = {b["y0"]}, largura = 256, altura = 256, escala = 4, tiles = {{')
    for t in b["tiles"]:
        linhas.append(f'\t\t{{ camada = "{t["camada"]}", x = 0, y = 0, w = 1024, h = 1024, id = "{ids.get(t["arquivo"], "rbxassetid://0")}", arquivo = "{t["arquivo"]}" }},')
    linhas.append("\t} },")
linhas.append("}")
bloco = "\n".join(linhas)

p = os.path.join(RAIZ, "src/shared/Mapas.luau")
s = open(p).read()
m = re.search(rf"Mapas\.{MAPA}\.detalhes = \{{\n.*?\n\}}\n", s, re.S)
if m:
    s = s[: m.start()] + bloco + "\n" + s[m.end():]
else:
    i = s.index("\nreturn Mapas")
    s = s[:i] + "\n-- Regiões de detalhe do mapa (ver o comentário do Brasil acima).\n" + bloco + "\n" + s[i:]
open(p, "w").write(s)
faltam = sum(1 for b in manifesto for t in b["tiles"] if t["arquivo"] not in ids)
print(len(manifesto), "blocos;", faltam, "imagens sem id")
