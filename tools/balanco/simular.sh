#!/bin/sh
# Simula um jogador "guloso" no mapa do Brasil e imprime quando cada trecho/projeto/era acontece.
# Precisa do luau (https://github.com/luau-lang/luau/releases). Uso: tools/balanco/simular.sh [caminho/do/luau]
set -e
LUAU=${1:-luau}
RAIZ=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
sed 's|require(script.Parent:WaitForChild("Tarifas"))|require("./Tarifas")|' "$RAIZ/src/shared/Economia.luau" > "$TMP/Economia.luau"
cp "$RAIZ/src/shared/Tarifas.luau" "$TMP/Tarifas.luau"
sed 's/Vector2\.new(\([^,]*\), \([^)]*\))/{ X = \1, Y = \2 }/g' "$RAIZ/src/shared/Dados/Brasil.luau" > "$TMP/Brasil.luau"
cp "$RAIZ/tools/balanco/simular.luau" "$TMP/sim.luau"
cd "$TMP" && "$LUAU" sim.luau
