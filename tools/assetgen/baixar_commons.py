"""Baixa do Wikimedia Commons as fotos de época das fichas das cidades (licenças em arte/cidades/CREDITOS.md).

Uso (na pasta do projeto):  python tools/assetgen/baixar_commons.py
Salva em arte/cidades_jogo/<nome>.jpg, com 960 px de largura (tamanho padrão de miniatura do Commons) (a ficha recorta em 16:9 sozinha).
Não precisa de nenhum pacote além do Python.
"""
import pathlib
import urllib.request

FOTOS = {
    "rio_1960": "a/ab/Az_Avenida_Atl%C3%A2ntica_%28Copacabana%29_a_Rua_Sousa_Lima_torkolat%C3%A1n%C3%A1l._Fortepan_74395.jpg",
    "rio_1980": "0/03/Rio_de_Janeiro%2C_Brazil_%2828252969945%29.jpg",
    "sao_paulo_1960": "6/6d/Praca_Ramos_de_Azevedo_a_Rua_Bar%C3%A3o_de_Itapetininga_fel%C3%A9_n%C3%A9zve._Fortepan_73751.jpg",
    "sao_paulo_1980": "4/40/S%C3%A3o_Paulo_-_Air_View_-_2356164247.jpg",
    "bh_1960": "5/5c/Tr%C3%B3lebus_Belo_Horizonte_%281953%29.png",
    "bh_1980": "1/13/Belo_Horizonte%2C_Fundo_Correio_da_Manh%C3%A3_-_2.tif",
}


def url_miniatura(caminho: str) -> str:
    arquivo = caminho.split("/")[-1]
    if arquivo.lower().endswith((".tif", ".tiff")):
        nome = f"lossy-page1-960px-{arquivo}.jpg"
    else:
        nome = f"960px-{arquivo}"
    return f"https://upload.wikimedia.org/wikipedia/commons/thumb/{caminho}/{nome}"


def main():
    pasta = pathlib.Path(__file__).resolve().parents[2] / "arte" / "cidades_jogo"
    pasta.mkdir(parents=True, exist_ok=True)
    for nome, caminho in FOTOS.items():
        url = url_miniatura(caminho)
        ext = ".png" if url.lower().endswith(".png") else ".jpg"
        destino = pasta / f"{nome}{ext}"
        pedido = urllib.request.Request(url, headers={"User-Agent": "FerroviaTycoon/1.0 (jogo no Roblox; baixa fotos com licença livre)"})
        with urllib.request.urlopen(pedido, timeout=60) as r:
            destino.write_bytes(r.read())
        print("ok", destino.name, destino.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
