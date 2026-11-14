"""Simula no PC o que o Roblox fará: tingir as camadas brancas com as cores de cada era."""
from PIL import Image, ImageChops

def hex2rgb(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def tint(img, color):
    """ImageColor3: multiplica o branco pela cor, mantém o alfa."""
    r, g, b = hex2rgb(color)
    solid = Image.new("RGBA", img.size, (r, g, b, 255))
    out = ImageChops.multiply(img.convert("RGBA"), solid)
    out.putalpha(img.getchannel("A"))
    return out

def tile_bg(size, color, pattern=None, pattern_color=None):
    bg = Image.new("RGBA", size, hex2rgb(color) + (255,))
    if pattern is not None:
        p = tint(pattern, pattern_color)
        for y in range(0, size[1], p.height):
            for x in range(0, size[0], p.width):
                bg.alpha_composite(p, (x, y))
    return bg

def map_preview(name, era, pattern=None, scale=0.25):
    land = Image.open(f"/home/claude/work/{name}_terra_full.png")
    lines = Image.open(f"/home/claude/work/{name}_linhas_full.png")
    c = era["colors"]
    bg = tile_bg(land.size, c["sea"], pattern, c["seaPattern"])
    bg.alpha_composite(tint(land, c["land"]))
    bg.alpha_composite(tint(lines, c["coast"]))
    w, h = bg.size
    return bg.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
