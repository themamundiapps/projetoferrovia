# Thumbnails: tira a marca "Made with" (canto inferior direito), desfoca as bordas como lente, vinheta e logo no topo.
import sys, cv2, numpy as np
from PIL import Image, ImageFilter
def mascara_marca(im):
    H, W = im.shape[:2]
    y0, y1, x0, x1 = 680, 748, 1086, 1348
    hsv = cv2.cvtColor(im[y0:y1, x0:x1], cv2.COLOR_BGR2HSV)
    glow = ((hsv[..., 2] > 140) & (hsv[..., 1] < 60)).astype(np.uint8) * 255
    m = cv2.morphologyEx(glow, cv2.MORPH_CLOSE, np.ones((17, 17), np.uint8))
    m = cv2.dilate(m, np.ones((13, 13), np.uint8))
    mask = np.zeros((H, W), np.uint8); mask[y0:y1, x0:x1] = m
    mask[684:748, 1286:1348] = 255
    return mask
def processar(entrada, saida, preencher=None, larg_logo=720, topo=6, escurecer=110):
    im = cv2.imread(entrada)
    mask = mascara_marca(im)
    base = preencher(im, mask) if preencher else cv2.inpaint(im, mask, 7, cv2.INPAINT_TELEA)
    # desfoque de lente nas bordas (mais forte embaixo e nos cantos)
    H, W = base.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    nx = (xx - W / 2) / (W / 2); ny = (yy - H * 0.45) / (H / 2)
    d = np.sqrt((nx * 0.85) ** 2 + (np.maximum(ny, 0) * 1.25 * (0.3 + 0.7 * np.abs(nx))) ** 2 + (np.minimum(ny, 0) * 0.6) ** 2)
    peso = np.clip((d - 0.62) / 0.45, 0, 1) ** 1.4
    b1 = cv2.GaussianBlur(base, (0, 0), 3); b2 = cv2.GaussianBlur(base, (0, 0), 7)
    p = peso[..., None]
    out = base * (1 - np.clip(p * 2, 0, 1)) + b1 * np.clip(p * 2, 0, 1)
    out = out * (1 - np.clip(p * 2 - 1, 0, 1)) + b2 * np.clip(p * 2 - 1, 0, 1)
    # vinheta suave
    vin = 1 - 0.28 * np.clip((d - 0.5) / 0.7, 0, 1)[..., None]
    out = np.clip(out * vin, 0, 255).astype(np.uint8)
    img = Image.fromarray(cv2.cvtColor(out, cv2.COLOR_BGR2RGB))
    w, h = img.size; nw = round(h * 16 / 9); x = (w - nw) // 2
    img = img.crop((x, 0, x + nw, h)).resize((1920, 1080), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.6, 50, 2)).convert("RGBA")
    g = Image.new("L", (1, 1080))
    for y in range(1080): g.putpixel((0, y), int(escurecer * max(0, 1 - y / 380) ** 1.6))
    s = Image.new("RGBA", (1920, 1080), (8, 4, 3, 0)); s.putalpha(g.resize((1920, 1080))); img.alpha_composite(s)
    logo = Image.open("/home/claude/logo/logo_railway_tycoon.png")
    lh = round(logo.height * larg_logo / logo.width)
    img.alpha_composite(logo.resize((larg_logo, lh), Image.LANCZOS), ((1920 - larg_logo) // 2, topo))
    img.convert("RGB").save(saida)
    return img

def trilho(im, mask):  # para a das eras: copia os dormentes ao longo dos trilhos
    imf = im.astype(np.float32); H, W = im.shape[:2]
    def sh(k, r):
        dx, dy = -int(round(r * k)), -k
        return np.roll(np.roll(imf, -dy, axis=0), -dx, axis=1)
    a = sh(40, 1.24); b = sh(40, 0.85)
    peso = np.clip((np.arange(W)[None, :, None] - 1150) / 60, 0, 1)
    src = b * (1 - peso) + a * peso
    soft = cv2.GaussianBlur((mask > 0).astype(np.float32), (0, 0), 2)[..., None]
    o = np.clip(imf * (1 - soft) + src * soft, 0, 255).astype(np.uint8)
    for (x0, y0, x1, y1) in [(52, 300, 118, 326), (1262, 300, 1330, 326), (624, 264, 650, 290), (726, 264, 752, 290)]:
        o[y0:y1, x0:x1] = cv2.GaussianBlur(o[y0:y1, x0:x1], (0, 0), 3.5)
    return cv2.inpaint(o, cv2.dilate(((cv2.cvtColor(o, cv2.COLOR_BGR2HSV)[..., 2] > 150) & (cv2.cvtColor(o, cv2.COLOR_BGR2HSV)[..., 1] < 45) & (mask > 0) | ((np.indices(mask.shape)[0] > 728) & (np.indices(mask.shape)[0] < 750) & (np.indices(mask.shape)[1] > 1290) & (np.indices(mask.shape)[1] < 1330) & (cv2.cvtColor(o, cv2.COLOR_BGR2GRAY) > 120))).astype(np.uint8) * 255, np.ones((5, 5), np.uint8)), 5, cv2.INPAINT_TELEA)

if __name__ == "__main__":
    processar("/mnt/user-data/uploads/60f7c20b-image.png", "/home/claude/thumb_alta_1920x1080.png", escurecer=90)
    processar("/mnt/user-data/uploads/d45fbac3-image.png", "/home/claude/thumb_eras_1920x1080.png", preencher=trilho)
    for n in ["alta", "eras"]:
        Image.open(f"/home/claude/thumb_{n}_1920x1080.png").resize((1280, 720)).save(f"/tmp/{n}.jpg")
        Image.open(f"/home/claude/thumb_{n}_1920x1080.png").crop((1440, 840, 1920, 1080)).save(f"/tmp/{n}_canto.png")
