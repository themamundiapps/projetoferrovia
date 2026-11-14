"""Renderiza as camadas dos mapas (brancas, para tingir no Roblox) e fatia em tiles de 1024."""
import json, os, io
import cairosvg
from PIL import Image

OUT = "/home/claude/pack/mapas"
TILE = 1024
maps = json.load(open("maps.json"))

def render(svg, w, h):
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h)
    return Image.open(io.BytesIO(png)).convert("RGBA")

def land_svg(m):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{m['width']}" height="{m['height']}">
<path d="{m['landAll']}" fill="#FFFFFF" fill-opacity="0.45"/>
<path d="{m['focus']}" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="0.6"/>
</svg>'''

def lines_svg(m):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{m['width']}" height="{m['height']}">
<path d="{m['landAll']}" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="1.5" stroke-linejoin="round"/>
<path d="{m['borders']}" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2" stroke-dasharray="7 5" stroke-linejoin="round"/>
<path d="{m['outline']}" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linejoin="round"/>
</svg>'''

manifest = {}
for name, m in maps.items():
    d = os.path.join(OUT, name); os.makedirs(d, exist_ok=True)
    W, H = m["width"], m["height"]
    layers = {"terra": render(land_svg(m), W, H), "linhas": render(lines_svg(m), W, H)}
    tiles = []
    for lname, img in layers.items():
        img.save(os.path.join("/home/claude/work", f"{name}_{lname}_full.png"))
        for ty in range(0, H, TILE):
            for tx in range(0, W, TILE):
                crop = img.crop((tx, ty, min(tx + TILE, W), min(ty + TILE, H)))
                fn = f"{name}_{lname}_{ty//TILE}_{tx//TILE}.png"
                crop.save(os.path.join(d, fn), optimize=True)
                tiles.append({"arquivo": f"mapas/{name}/{fn}", "camada": lname, "x": tx, "y": ty, "w": crop.width, "h": crop.height})
    manifest[name] = {"largura": W, "altura": H, "projecao": m["projection"], "cidades_px": m["cities"], "tiles": tiles}
    print(name, len(tiles), "tiles")

json.dump(manifest, open("/home/claude/work/maps_manifest.json", "w"), ensure_ascii=False, indent=1)
