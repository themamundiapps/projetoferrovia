"""Baixa do Wikimedia Commons as fotos das fichas das cidades por era (lista em fotos_commons.json;
licenças e créditos em arte/cidades/CREDITOS.md).

Uso (na pasta do projeto):  python tools/assetgen/baixar_commons.py
Salva arte/cidades_jogo/<cidade>_<era>.jpg (ou .png), com 960 px de largura (tamanho padrão de miniatura
do Commons); a ficha recorta em 16:9 sozinha. Não precisa de nenhum pacote além do Python.
"""
import json
import pathlib
import time
import urllib.error
import urllib.request

AQUI = pathlib.Path(__file__).resolve().parent
UA = "FerroviaTycoon/1.0 (jogo no Roblox; baixa fotos com licenca livre do Commons)"


def url_miniatura(caminho: str) -> str:
    arquivo = caminho.split("/")[-1]
    nome = f"lossy-page1-960px-{arquivo}.jpg" if arquivo.lower().endswith((".tif", ".tiff")) else f"960px-{arquivo}"
    return f"https://upload.wikimedia.org/wikipedia/commons/thumb/{caminho}/{nome}"


def baixar(url: str) -> bytes:
    """Baixa com paciência: o Commons recusa (429/503) quem pede rápido demais; espera e tenta de novo."""
    espera = 5
    for tentativa in range(6):
        try:
            pedido = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(pedido, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code not in (429, 500, 502, 503, 504) or tentativa == 5:
                raise
            print(f"     o Commons pediu calma ({e.code}); esperando {espera}s...")
            time.sleep(espera)
            espera *= 2
    raise RuntimeError("não deu")


def main():
    pasta = AQUI.parents[1] / "arte" / "cidades_jogo"
    pasta.mkdir(parents=True, exist_ok=True)
    fotos = json.loads((AQUI / "fotos_commons.json").read_text(encoding="utf-8"))
    erros = 0
    for f in fotos:
        url = url_miniatura(f["caminho"])
        ext = ".png" if url.lower().endswith(".png") else ".jpg"
        destino = pasta / f"{f['cidade']}_{f['era']}{ext}"
        if destino.exists() and destino.stat().st_size > 10_000:
            print("já tem", destino.name)
            continue
        try:
            destino.write_bytes(baixar(url))
            print("ok  ", destino.name)
        except Exception as e:  # segue com as outras
            erros += 1
            print("ERRO", destino.name, e)
        time.sleep(2)
    print(f"{len(fotos) - erros} de {len(fotos)} fotos em {pasta}")


if __name__ == "__main__":
    main()
