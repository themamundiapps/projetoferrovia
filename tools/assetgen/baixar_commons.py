"""Baixa do Wikimedia Commons as fotos das fichas das cidades por era (lista em fotos_commons.json;
licenças e créditos em arte/cidades/CREDITOS.md).

Uso (na pasta do projeto):  python tools/assetgen/baixar_commons.py
Salva arte/cidades_jogo/<cidade>_<era>.jpg (ou .png), com 960 px de largura (tamanho padrão de miniatura
do Commons); a ficha recorta em 16:9 sozinha. Não precisa de nenhum pacote além do Python.
"""
import json
import pathlib
import time
import urllib.request

AQUI = pathlib.Path(__file__).resolve().parent
UA = "FerroviaTycoon/1.0 (jogo no Roblox; baixa fotos com licenca livre do Commons)"


def url_miniatura(caminho: str) -> str:
    arquivo = caminho.split("/")[-1]
    nome = f"lossy-page1-960px-{arquivo}.jpg" if arquivo.lower().endswith((".tif", ".tiff")) else f"960px-{arquivo}"
    return f"https://upload.wikimedia.org/wikipedia/commons/thumb/{caminho}/{nome}"


def main():
    pasta = AQUI.parents[1] / "arte" / "cidades_jogo"
    pasta.mkdir(parents=True, exist_ok=True)
    fotos = json.loads((AQUI / "fotos_commons.json").read_text(encoding="utf-8"))
    erros = 0
    for f in fotos:
        url = url_miniatura(f["caminho"])
        ext = ".png" if url.lower().endswith(".png") else ".jpg"
        destino = pasta / f"{f['cidade']}_{f['era']}{ext}"
        try:
            pedido = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(pedido, timeout=60) as r:
                destino.write_bytes(r.read())
            print("ok  ", destino.name)
        except Exception as e:  # segue com as outras
            erros += 1
            print("ERRO", destino.name, e)
        time.sleep(0.3)
    print(f"{len(fotos) - erros} de {len(fotos)} fotos em {pasta}")


if __name__ == "__main__":
    main()
