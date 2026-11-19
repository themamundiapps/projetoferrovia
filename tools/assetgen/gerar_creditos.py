"""Gera src/shared/Creditos.luau a partir da tabela de arte/cidades/CREDITOS.md.

Rode depois de mudar a tabela (foto nova, foto trocada ou removida):
    python tools/assetgen/gerar_creditos.py
A tela de créditos do jogo (Ajustes › Créditos) lê esse arquivo.
"""

import re
from pathlib import Path
from urllib.parse import unquote

RAIZ = Path(__file__).resolve().parents[2]
ORIGEM = RAIZ / "arte" / "cidades" / "CREDITOS.md"
DESTINO = RAIZ / "src" / "shared" / "Creditos.luau"


def lua(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main() -> None:
    linhas = []
    for bruta in ORIGEM.read_text(encoding="utf-8").splitlines():
        if not bruta.startswith("| ") or bruta.startswith("| Cidade") or bruta.startswith("|---"):
            continue
        cols = [c.strip() for c in bruta.strip().strip("|").split("|")]
        if len(cols) != 6:
            raise SystemExit(f"linha com {len(cols)} colunas: {bruta}")
        cidade, era, foto, ano, autor, licenca = cols
        m = re.match(r"\[(.+?)\]\((.+?)\)", foto)
        arquivo = unquote(m.group(1) if m else foto).replace("_", " ")
        linhas.append((cidade, era, ano, autor, licenca, arquivo))

    saida = [
        "--!strict",
        "-- Créditos das fotos das cidades (Wikimedia Commons).",
        "-- GERADO por tools/assetgen/gerar_creditos.py a partir de arte/cidades/CREDITOS.md: não editar à mão.",
        "",
        "export type Credito = { cidade: string, era: string, ano: string, autor: string, licenca: string, arquivo: string }",
        "",
        "local Creditos: { Credito } = {",
    ]
    for cidade, era, ano, autor, licenca, arquivo in linhas:
        saida.append(
            f"\t{{ cidade = {lua(cidade)}, era = {lua(era)}, ano = {lua(ano)}, autor = {lua(autor)}, "
            f"licenca = {lua(licenca)}, arquivo = {lua(arquivo)} }},"
        )
    saida += ["}", "", "return Creditos", ""]
    DESTINO.write_text("\n".join(saida), encoding="utf-8")
    print(f"{len(linhas)} créditos em {DESTINO.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
