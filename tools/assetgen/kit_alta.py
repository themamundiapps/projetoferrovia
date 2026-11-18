"""Prepara as peças do kit de UI da Alta Velocidade (arte/ui/alta/).

Entrada: as versões escolhidas, já recortadas, em <pasta>/<peca>_<versao>.png.
Saída: arte/ui/alta/<peca>.png prontas para o 9-slice, e os ícones em arte/ui/alta/icones/.
Uso: python kit_alta.py <pasta das opções> <pasta de saída>
"""
import sys
import numpy as np
from PIL import Image

ent, sai = sys.argv[1], sys.argv[2]


def abrir(nome):
    return np.array(Image.open(f"{ent}/{nome}.png").convert("RGBA")).astype(np.float32)


def salvar(a, nome):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(f"{sai}/{nome}.png")
    print(nome, a.shape[1], "x", a.shape[0])


def aparar(a, lim=10, p=2):
    ys, xs = np.where(a[..., 3] > lim)
    return a[max(ys.min() - p, 0):ys.max() + p + 1, max(xs.min() - p, 0):xs.max() + p + 1]


def miolo_h(a, x0, x1, fonte=None):
    """Miolo uniforme na horizontal: as colunas x0..x1 viram a mediana (por linha) das colunas da fonte."""
    f0, f1 = fonte or (x0, x1)
    col = np.median(a[:, f0:f1], axis=1, keepdims=True)
    a[:, x0:x1] = col
    return a


def miolo_v(a, y0, y1, fonte=None):
    f0, f1 = fonte or (y0, y1)
    lin = np.median(a[f0:f1], axis=0, keepdims=True)
    a[y0:y1] = lin
    return a


def escurecer(a, k):
    a[..., :3] *= k
    return a


# moldura do painel: só apara
salvar(aparar(abrir("painel_1")), "painel")

# cartão: um tom acima do painel (a peça veio clara demais para texto claro)
salvar(escurecer(aparar(abrir("cartao_1")), 0.55), "cartao")

# faixa do título: tira o reflexo do miolo (repete o trecho limpo da direita)
a = aparar(abrir("cabecalho_1"))
w = a.shape[1]
friso = (a[..., 1] > 150) & (a[..., 2] > 150) & (a[..., 0] < 150)  # o filete ciano da ponta esquerda
copia = a.copy()
a = miolo_h(a, 70, w - 60, (int(w * 0.62), int(w * 0.85)))
a[friso] = copia[friso]
salvar(a, "cabecalho")

# divisor: só a faixa da linha (sem a fumaça de cima)
a = aparar(abrir("divisor_1"))
lum = a[..., :3].mean(axis=2) * (a[..., 3] / 255)
linhas = np.where((a[..., 3] > 200).mean(axis=1) > 0.6)[0]
y0, y1 = linhas.min(), linhas.max()
salvar(aparar(a[max(y0 - 3, 0):y1 + 4]), "divisor")

# botões, abas, trilho, plaquinhas: miolo uniforme
for nome, saida, cap in [("botao_1", "botao", 120), ("botao_discreto_1", "botao_discreto", 115),
                         ("aba_1", "aba", 50), ("aba_ativa_1", "aba_ativa", 50),
                         ("barra_fundo_1", "barra_fundo", 75), ("placa_nome_1", "placa_nome", 45),
                         ("base_medalhoes_1", "base_medalhoes", 85)]:
    a = aparar(abrir(nome))
    salvar(miolo_h(a, cap, a.shape[1] - cap), saida)

# placa de cidade: o friso ciano fica na ponta esquerda
a = aparar(abrir("placa_cidade_1"))
salvar(miolo_h(a, 60, a.shape[1] - 45), "placa_cidade")

# preenchimento: cápsula gerada (a da arte tinha textura manchada), em tons claros para tingir; 620 x 22,
# com um filete de brilho na metade de cima, como a da referência
W, H, S = 620, 22, 4
yy, xx = np.mgrid[:H * S, :W * S] / S
r = H / 2
dx = np.maximum(np.maximum(r - xx, xx - (W - r)), 0)
d = np.hypot(dx, yy - r)
alfa = np.clip(r - d, 0, 1)
tom = 0.86 + 0.14 * np.clip(1 - np.abs(yy - H * 0.3) / 3, 0, 1)
a = np.zeros((H * S, W * S, 4), np.float32)
a[..., :3] = (tom * 255)[..., None]
a[..., 3] = alfa * 255
a = np.array(Image.fromarray(a.astype(np.uint8)).resize((W, H), Image.LANCZOS), np.float32)
salvar(a, "barra_cheia")

# aba lateral: miolo uniforme na vertical
a = aparar(abrir("aba_lateral_1"))
salvar(miolo_v(a, 100, a.shape[0] - 100), "aba_lateral")

# botão redondo e medalhão: corta o que sobra fora do círculo (mancha do redondo)
for nome, saida in [("botao_redondo_1", "botao_redondo"), ("medalhao_1", "medalhao")]:
    a = abrir(nome)
    ys, xs = np.where(a[..., 3] > 200)
    cy, cx = (ys.min() + ys.max()) / 2, (xs.min() + xs.max()) / 2
    r = max(ys.max() - ys.min(), xs.max() - xs.min()) / 2
    yy, xx = np.mgrid[:a.shape[0], :a.shape[1]]
    d = np.hypot(yy - cy, xx - cx)
    a[..., 3] *= np.clip((r + 6 - d) / 6, 0, 1)
    a = aparar(a)
    # quadrado, centrado
    h, w = a.shape[:2]
    s = max(h, w)
    q = np.zeros((s, s, 4), np.float32)
    q[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = a
    salvar(q, saida)

# barra de cima: pontas e miolo que se repete (sem emendas)
a = aparar(abrir("barra_topo_1"))
h, w = a.shape[:2]
PONTA, MEIO = 60, 320
col = np.median(a[:, 100:w - 100], axis=1, keepdims=True)
a[:, 50:w - 50] = col
salvar(a[:, :PONTA].copy(), "topo_esq")
salvar(a[:, w - PONTA:].copy(), "topo_dir")
salvar(np.repeat(col, MEIO, axis=1), "topo_meio")

# ícones: traço claro (o escuro da arte vira opaco, o recheio branco some), 256 x 256
ICONES = {
    "icones_abas_1": ["linhas", "projetos", "metas", "jornal", "banco", "companhia", "ajustes", "tarifas"],
    "icones_recursos_2": ["trens", "passageiros", "satisfacao", "carga", "decisao", "dinheiro", "estrela", "calendario"],
}
GELO = np.array([232, 238, 248], np.float32)
for folha, nomes in ICONES.items():
    a = abrir(folha)
    lum = a[..., :3] @ np.array([0.299, 0.587, 0.114], np.float32)
    alfa = a[..., 3] / 255 * np.clip((215 - lum) / 140, 0, 1)
    h, w = a.shape[:2]
    for i, nome in enumerate(nomes):
        r, c = divmod(i, 4)
        cel = alfa[r * h // 2:(r + 1) * h // 2, c * w // 4:(c + 1) * w // 4]
        ys, xs = np.where(cel > 0.08)
        cel = cel[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        im = Image.fromarray((cel * 255).astype(np.uint8))
        e = 220 / max(im.size)
        im = im.resize((max(1, round(im.width * e)), max(1, round(im.height * e))), Image.LANCZOS)
        q = np.zeros((256, 256, 4), np.float32)
        q[..., :3] = GELO
        y0, x0 = (256 - im.height) // 2, (256 - im.width) // 2
        q[y0:y0 + im.height, x0:x0 + im.width, 3] = np.array(im, np.float32)
        Image.fromarray(q.astype(np.uint8)).save(f"{sai}/icones/{nome}.png")
    print(folha, "-> 8 ícones")

# vinheta do mapa: mesma queda da Elétrica, um pouco mais forte e em azul-noite
v = np.array(Image.open(f"{sai}/../moderno/vinheta.png").convert("RGBA"), np.float32)
v[..., :3] = [5, 8, 15]
v[..., 3] = np.clip(v[..., 3] * 1.2, 0, 255)
salvar(v, "vinheta")
