"""Ícones monocromáticos (traço branco, grade 24) para tingir no Roblox."""
import math

def gear():
    p = ['<circle cx="12" cy="12" r="3"/>', '<circle cx="12" cy="12" r="6.5"/>']
    for i in range(8):
        a = i * math.pi / 4
        x1, y1 = 12 + 6.5 * math.cos(a), 12 + 6.5 * math.sin(a)
        x2, y2 = 12 + 9.5 * math.cos(a), 12 + 9.5 * math.sin(a)
        p.append(f'<path d="M{x1:.2f} {y1:.2f} L{x2:.2f} {y2:.2f}" stroke-width="2.6"/>')
    return "".join(p)

def wheat():
    p = ['<path d="M12 22 V5"/>']
    for y in (8, 12.5, 17):
        p.append(f'<path d="M12 {y} C9 {y-1} 7.5 {y-3} 7.5 {y-5.5} C10 {y-5} 12 {y-3} 12 {y} Z"/>')
        p.append(f'<path d="M12 {y} C15 {y-1} 16.5 {y-3} 16.5 {y-5.5} C14 {y-5} 12 {y-3} 12 {y} Z"/>')
    return "".join(p)

def star():
    pts = []
    for i in range(10):
        r = 9.5 if i % 2 == 0 else 4.2
        a = -math.pi / 2 + i * math.pi / 5
        pts.append(f"{12 + r*math.cos(a):.2f},{12.6 + r*math.sin(a):.2f}")
    return f'<polygon points="{" ".join(pts)}"/>'

DOT = lambda x, y, r=1.1: f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff" stroke="none"/>'

ICONS = {
 # navegação
 "linhas": '<circle cx="5" cy="5.5" r="2.2"/><circle cx="19" cy="18.5" r="2.2"/><path d="M5 7.7 V10 a3 3 0 0 0 3 3 h8 a3 3 0 0 1 3 3 v0.3"/>',
 "trens": '<rect x="5" y="3" width="14" height="14" rx="3"/><rect x="8" y="6" width="8" height="4" rx="1"/>' + DOT(9, 13.5) + DOT(15, 13.5) + '<path d="M8 17 L6 21 M16 17 L18 21"/>',
 "estacoes": '<path d="M3 10 L12 4 L21 10"/><path d="M5 9.5 V20 H19 V9.5"/><rect x="10" y="14" width="4" height="6"/><path d="M2 20 H22"/>',
 "cargas": '<path d="M12 3 L20 7 V17 L12 21 L4 17 V7 Z"/><path d="M4 7 L12 11 L20 7 M12 11 V21"/>',
 "companhia": '<rect x="3" y="7.5" width="18" height="12.5" rx="2"/><path d="M9 7.5 V5.5 a1.5 1.5 0 0 1 1.5 -1.5 h3 a1.5 1.5 0 0 1 1.5 1.5 v2 M3 13 h18"/>',
 "loja": '<path d="M5 8 h14 l-1.2 12 H6.2 Z"/><path d="M9 10.5 V6.5 a3 3 0 0 1 6 0 v4"/>',
 "mapa_mundo": '<circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12 h18"/>',
 "missoes": '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 3 h6 v3 H9 Z"/><path d="M8.5 12.5 l2 2 l4.5 -4.5 M8.5 17.5 h7"/>',
 "ranking": '<path d="M8 4 h8 v5 a4 4 0 0 1 -8 0 Z"/><path d="M8 5.5 H5 v1 a3 3 0 0 0 3 3 M16 5.5 h3 v1 a3 3 0 0 1 -3 3 M12 13 v4 M8 20.5 h8 M10 17 h4 v3.5 h-4 Z"/>',
 "configuracoes": gear(),
 "visitar": '<path d="M2 12 C5 6.5 8.5 5 12 5 S19 6.5 22 12 C19 17.5 15.5 19 12 19 S5 17.5 2 12 Z"/><circle cx="12" cy="12" r="3"/>',
 "menu": '<path d="M4 6 h16 M4 12 h16 M4 18 h16"/>',
 # status
 "dinheiro": '<circle cx="12" cy="12" r="9"/><path d="M15 9 a3 2.6 0 0 0 -3 -1.7 a2.5 2.3 0 0 0 0 4.7 a2.5 2.3 0 0 1 0 4.7 a3 2.6 0 0 1 -3 -1.7 M12 5.8 v12.4"/>',
 "renda": '<path d="M3 17 L9 11 L13 15 L21 7"/><path d="M15 7 h6 v6"/>',
 "passageiros": '<circle cx="9" cy="8" r="3.2"/><path d="M3 20 a6 6 0 0 1 12 0"/><circle cx="17" cy="9" r="2.5"/><path d="M15.8 14.2 a5 5 0 0 1 5.7 4.8"/>',
 "satisfacao": '<circle cx="12" cy="12" r="9"/><path d="M8 14 a5 5 0 0 0 8 0"/>' + DOT(9, 10) + DOT(15, 10),
 "relogio": '<circle cx="12" cy="12" r="9"/><path d="M12 7 v5 l3.2 2"/>',
 "cadeado": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11 V8 a4 4 0 0 1 8 0 v3"/>' + DOT(12, 16, 1.4),
 "melhorar": '<path d="M12 20 V5 M6 11 l6 -6 l6 6"/>',
 "confirmar": '<path d="M5 12.5 l4.5 4.5 L19 7"/>',
 "fechar": '<path d="M6 6 l12 12 M18 6 L6 18"/>',
 "mais": '<path d="M12 5 v14 M5 12 h14"/>',
 "menos": '<path d="M5 12 h14"/>',
 "info": '<circle cx="12" cy="12" r="9"/><path d="M12 11 v6"/>' + DOT(12, 7.6, 1.3),
 "alerta": '<path d="M12 3.5 L21.5 20 H2.5 Z"/><path d="M12 10 v4.5"/>' + DOT(12, 17.2, 1.2),
 "velocidade": '<path d="M4 17 a8 8 0 1 1 16 0"/><path d="M12 17 l4 -5.5"/>' + DOT(12, 17, 1.5),
 "distancia": '<path d="M3.5 17.5 L17.5 3.5 L20.5 6.5 L6.5 20.5 Z"/><path d="M7.5 13.5 l2 2 M10.5 10.5 l2 2 M13.5 7.5 l2 2"/>',
 "presente": '<rect x="4" y="9" width="16" height="4" rx="1"/><rect x="5" y="13" width="14" height="8" rx="1"/><path d="M12 9 v12 M12 9 C10 4 6 5 8.5 9 M12 9 C14 4 18 5 15.5 9"/>',
 "prestigio": star(),
 "conectar": '<path d="M10 14 a4 4 0 0 0 5.7 0 l3 -3 a4 4 0 0 0 -5.7 -5.7 l-1 1"/><path d="M14 10 a4 4 0 0 0 -5.7 0 l-3 3 a4 4 0 0 0 5.7 5.7 l1 -1"/>',
 "construir": '<path d="M13.5 3.5 l7 7 l-3 3 l-7 -7 Z"/><path d="M12 9 L3.5 17.5 a2 2 0 0 0 3 3 L15 12"/>',
 "assinar": '<path d="M4 20 l1 -4 L16 5 l3 3 L8 19 Z"/><path d="M14 7 l3 3 M3 21.5 h8"/>',
 "sede": '<path d="M5 21 V3.5"/><path d="M5 4 h12 l-2.5 3.5 L17 11 H5"/>',
 "auto": '<path d="M20 12 a8 8 0 1 1 -2.3 -5.7"/><path d="M20 4 v4 h-4"/><path d="M10 9 l5 3 l-5 3 Z"/>',
 # cargas
 "carga_cafe": '<ellipse cx="12" cy="12" rx="6.5" ry="9" transform="rotate(35 12 12)"/><path d="M8 6 C13 10 11 14 16 18"/>',
 "carga_minerio": '<path d="M4 15 L8 6 L16 5 L21 12 L17 20 L7 20 Z"/><path d="M4 15 L12 12 L21 12 M12 12 L8 6 M12 12 L7 20"/>',
 "carga_soja": '<path d="M5 18.5 C3 12 8 5 15 4 C21 4 21 9 18 13 C14 19 8 21 5 18.5 Z"/><circle cx="9" cy="15" r="1.8"/><circle cx="12.5" cy="11.3" r="1.8"/><circle cx="16" cy="7.8" r="1.8"/>',
 "carga_graos": wheat(),
 "carga_carvao": '<path d="M3 19 L5 13 L10 11 L13 15 L11 19 Z"/><path d="M12 19 L14 13 L19 11.5 L21.5 16 L19 19 Z"/><path d="M8 10 L10 5 L14.5 4 L16 8.5 L12.5 11 Z"/>',
 "carga_petroleo": '<path d="M12 3 C12 3 5 11 5 15 a7 7 0 0 0 14 0 C19 11 12 3 12 3 Z"/><path d="M8.5 15 a3.5 3.5 0 0 0 3.5 3.5"/>',
 "carga_madeira": '<circle cx="7" cy="16.5" r="3.6"/><circle cx="16.5" cy="16.5" r="3.6"/><circle cx="11.8" cy="9" r="3.6"/>' + DOT(7, 16.5, 1) + DOT(16.5, 16.5, 1) + DOT(11.8, 9, 1),
 "carga_gado": '<path d="M7 8 C4.5 8 3 6.5 3 4.5 M17 8 C19.5 8 21 6.5 21 4.5"/><path d="M7 7.5 h10 v5.5 a5 5 0 0 1 -10 0 Z"/><ellipse cx="12" cy="17" rx="3.6" ry="2.4"/>' + DOT(9.5, 10.5) + DOT(14.5, 10.5),
 "carga_aco": '<path d="M4 4 h16 v3 h-6 v10 h6 v3 H4 v-3 h6 V7 H4 Z"/>',
 "carga_mercadorias": '<rect x="3" y="7" width="18" height="11" rx="1"/><path d="M7 9.5 v6 M10.5 9.5 v6 M14 9.5 v6 M17.5 9.5 v6"/>',
 "carga_passageiros": '<rect x="6" y="3" width="12" height="16" rx="3"/><path d="M6 11 h12 M9 19 l-2 2.5 M15 19 l2 2.5"/>' + DOT(9.5, 15.5) + DOT(14.5, 15.5),
 # terreno
 "terreno_montanha": '<path d="M2 19 L9 7 L13 13 L16 9 L22 19 Z"/><path d="M7.3 10 L9 7 L10.8 10"/>',
 "terreno_ponte": '<path d="M2 9 h20 M4 9 v7 M20 9 v7 M4 16 C6 11 18 11 20 16"/><path d="M2 21 q2.5 -2 5 0 t5 0 t5 0 t5 0"/>',
 "terreno_pantano": '<path d="M2 19 q2.5 -2 5 0 t5 0 t5 0 t5 0"/><path d="M8 16 V8 M12 16 V5 M16 16 V9"/><ellipse cx="8" cy="7.5" rx="1.3" ry="2.6"/><ellipse cx="12" cy="4.5" rx="1.3" ry="2.6"/>',
 "terreno_floresta": '<path d="M7 3 L11.5 11 H2.5 Z M7 11 v3.5"/><path d="M16 7 L21.5 17 H10.5 Z M16 17 v4"/>',
 "terreno_tunel": '<path d="M2 20 h20"/><path d="M4 20 V12 a8 8 0 0 1 16 0 v8"/><path d="M8 20 v-6 a4 4 0 0 1 8 0 v6"/>',
 "terreno_cremalheira": '<path d="M3 21 L21 12"/><path d="M3.5 17.5 l2 -3.2 l1.6 2.4 l2 -3.2 l1.6 2.4 l2 -3.2 l1.6 2.4 l2 -3.2 l1.6 2.4 l2 -3.2"/>',
}

SVG_HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="{s}" height="{s}"><g fill="none" stroke="#FFFFFF" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round">'

def icon_svg(name, size=128, stroke=1.9):
    return SVG_HEAD.format(s=size, w=stroke) + ICONS[name] + "</g></svg>"

# --------- trens (silhuetas preenchidas, viewBox 160x60) ---------
TRAINS = {
 "trem_vapor": '''<path fill-rule="evenodd" d="
  M20 22 h80 v20 H20 Z
  M28 22 V10 h12 v12 Z M25 7 h18 v4 h-18 Z
  M54 22 a6 6 0 0 1 12 0 Z
  M100 12 h28 v30 h-28 Z M96 8 h36 v5 h-36 Z M106 17 h16 v10 h-16 Z
  M132 18 h24 v24 h-24 Z
  M20 42 L8 51 H20 Z M14 42 h142 v4 H14 Z"/>
  <circle cx="64" cy="49" r="10"/><circle cx="88" cy="49" r="10"/><circle cx="32" cy="52" r="6"/><circle cx="114" cy="51" r="7"/><circle cx="140" cy="52" r="6"/>''',
 "trem_diesel": '''<path fill-rule="evenodd" d="M8 46 C8 27 20 14 44 12 H152 V46 Z M27 19 C22 21 18.5 26 17.5 30 H40 V19 Z M60 20 h14 v8 h-14 Z M84 20 h14 v8 h-14 Z M108 20 h14 v8 h-14 Z"/>
  <rect x="20" y="46" width="38" height="5" rx="2"/><rect x="104" y="46" width="38" height="5" rx="2"/>
  <circle cx="29" cy="53" r="5"/><circle cx="49" cy="53" r="5"/><circle cx="113" cy="53" r="5"/><circle cx="133" cy="53" r="5"/>''',
 "trem_eletrico": '''<path fill-rule="evenodd" d="M6 46 V26 L16 18 H154 V46 Z M14 23 L9 28 V32 H22 V23 Z M30 24 h14 v8 h-14 Z M52 24 h14 v8 h-14 Z M74 24 h14 v8 h-14 Z M96 24 h14 v8 h-14 Z M118 24 h14 v8 h-14 Z M140 24 h10 v8 h-10 Z"/>
  <path d="M68 18 L78 6 L88 18 M72 6 h12" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="18" y="46" width="34" height="5" rx="2"/><rect x="108" y="46" width="34" height="5" rx="2"/>
  <circle cx="26" cy="53" r="4.5"/><circle cx="44" cy="53" r="4.5"/><circle cx="116" cy="53" r="4.5"/><circle cx="134" cy="53" r="4.5"/>''',
 "trem_alta_velocidade": '''<path fill-rule="evenodd" d="M2 44 C8 31 34 19 80 17 H158 V44 Z M36 25 C46 22 58 21 70 21 H154 V27 H34 Z"/>
  <rect x="6" y="44" width="152" height="4" rx="2"/>
  <rect x="44" y="48" width="26" height="4" rx="2"/><rect x="120" y="48" width="26" height="4" rx="2"/>
  <circle cx="50" cy="54" r="3.5"/><circle cx="64" cy="54" r="3.5"/><circle cx="126" cy="54" r="3.5"/><circle cx="140" cy="54" r="3.5"/>''',
}

def train_svg(name, w=512, h=192):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 60" width="{w}" height="{h}"><g fill="#FFFFFF">{TRAINS[name]}</g></svg>'
