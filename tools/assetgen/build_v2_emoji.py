"""Pacote v2: mesmos gráficos da v1, mas ícones trocados por emojis (texto, sem upload)."""
import io, os, json, shutil, subprocess
import cairosvg
from PIL import Image
from theme import ERAS
from composite import tint, map_preview, hex2rgb

V1 = "/home/claude/pack"
V2 = "/home/claude/pack_v2"
TW = "node_modules/@twemoji/svg"

# nome -> (emoji, versão Unicode, observação)
EMOJIS = {
 # navegação
 "linhas": ("🛤️", "7.0", ""), "trens": ("🚂", "6.0", ""), "estacoes": ("🚉", "6.0", ""), "cargas": ("📦", "6.0", ""),
 "companhia": ("💼", "6.0", ""), "loja": ("🛒", "9.0", ""), "mapa_mundo": ("🌎", "6.0", ""), "missoes": ("📋", "6.0", ""),
 "ranking": ("🏆", "6.0", ""), "configuracoes": ("⚙️", "4.1", ""), "visitar": ("👀", "6.0", ""), "menu": ("📜", "6.0", ""),
 # status e ações
 "dinheiro": ("💰", "6.0", ""), "renda": ("📈", "6.0", ""), "passageiros": ("👥", "6.0", ""), "satisfacao": ("😊", "6.0", ""),
 "relogio": ("⏰", "6.0", ""), "cadeado": ("🔒", "6.0", ""), "melhorar": ("⬆️", "4.0", ""), "confirmar": ("✅", "6.0", ""),
 "fechar": ("❌", "6.0", ""), "mais": ("➕", "6.0", ""), "menos": ("➖", "6.0", ""), "info": ("ℹ️", "3.0", ""),
 "alerta": ("⚠️", "4.0", ""), "velocidade": ("💨", "6.0", "não há velocímetro em emoji"), "distancia": ("📏", "6.0", ""),
 "presente": ("🎁", "6.0", ""), "prestigio": ("⭐", "5.1", ""), "conectar": ("🔗", "6.0", ""), "construir": ("🔨", "6.0", ""),
 "assinar": ("✍️", "1.1", ""), "sede": ("🚩", "6.0", ""), "auto": ("🔄", "6.0", ""),
 # cargas
 "carga_cafe": ("☕", "4.0", ""), "carga_minerio": ("⛏️", "5.2", "picareta no lugar de minério"),
 "carga_soja": ("🌱", "6.0", "o emoji de feijão (🫘) é novo demais"), "carga_graos": ("🌾", "6.0", ""),
 "carga_carvao": ("🔥", "6.0", "não há emoji de carvão"), "carga_petroleo": ("🛢️", "7.0", ""),
 "carga_madeira": ("🌲", "6.0", "o emoji de tora (🪵) é novo demais"), "carga_gado": ("🐄", "6.0", ""),
 "carga_aco": ("🔩", "6.0", ""), "carga_mercadorias": ("🏭", "6.0", ""), "carga_passageiros": ("🎫", "6.0", ""),
 # terreno
 "terreno_montanha": ("⛰️", "5.2", ""), "terreno_ponte": ("🌉", "6.0", ""), "terreno_pantano": ("🐊", "6.0", "jacaré representa o Pantanal"),
 "terreno_floresta": ("🌳", "6.0", ""), "terreno_tunel": ("🚇", "6.0", ""), "terreno_cremalheira": ("🧗", "10.0", "não há emoji de cremalheira; escalada = trecho íngreme"),
 # eras
 "era_vapor": ("🚂", "6.0", ""), "era_diesel": ("🚆", "6.0", ""), "era_eletrico": ("🚈", "6.0", ""), "era_alta": ("🚅", "6.0", ""),
}

def tw_file(e):
    cps = [f"{ord(c):x}" for c in e]
    for cand in ("-".join(cps), "-".join(c for c in cps if c != "fe0f")):
        p = f"{TW}/{cand}.svg"
        if os.path.exists(p): return p
    raise FileNotFoundError(e)

def tw_png(e, size):
    return Image.open(io.BytesIO(cairosvg.svg2png(url=tw_file(e), output_width=size, output_height=size))).convert("RGBA")

