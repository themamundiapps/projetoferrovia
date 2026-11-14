"""Fonte única do guia de estilo: eras, paletas e fontes (nativas do Roblox)."""

ERAS = [
 {
  "id": "vapor", "nome": "Era do Vapor", "anos": "1830–1930",
  "fonts": {  # (nome do arquivo .json do Roblox, peso usado)
   "display": ("Merriweather", "Bold"), "label": ("SpecialElite", "Regular"),
   "body": ("SourceSansPro", "Regular"), "number": ("SpecialElite", "Regular")},
  "preview_fonts": {"display": ("Merriweather", 900), "label": ("Special Elite", 400), "body": ("Source Sans Pro", 400), "number": ("Special Elite", 400)},
  "colors": {
   "bg": "#EFE4CC", "panel": "#F7F0DE", "ink": "#3B2A1A", "inkMuted": "#6B5640", "rule": "#B8A27A",
   "land": "#E4D2AA", "sea": "#D9CBAA", "seaPattern": "#C9B992", "coast": "#3B2A1A", "rio": "#4E6A78",
   "accent": "#8E2B23", "onAccent": "#F7F0DE", "positive": "#3F5E3A", "negative": "#8E2B23", "locked": "#3B2A1A",
  },
  "lines": ["#8E2B23", "#2E4A6B", "#B5762A", "#5B3A5E", "#3F5E3A", "#6B4A2B", "#7A6A2A", "#2F6B6B"],
  "shape": {"corner": 0, "stroke": 1.5, "doubleFrame": True},
 },
 {
  "id": "diesel", "nome": "Era do Diesel", "anos": "1930–1965",
  "fonts": {"display": ("Oswald", "Bold"), "label": ("Oswald", "Medium"), "body": ("SourceSansPro", "Regular"), "number": ("RobotoMono", "Medium")},
  "preview_fonts": {"display": ("Oswald", 700), "label": ("Oswald", 500), "body": ("Source Sans Pro", 400), "number": ("Roboto Mono", 500)},
  "colors": {
   "bg": "#E9E2CF", "panel": "#F5F0E1", "ink": "#1F2B33", "inkMuted": "#4E5B63", "rule": "#B9B39C",
   "land": "#D9D4AE", "sea": "#BFD3D0", "seaPattern": "#A9C2BF", "coast": "#1F2B33", "rio": "#2F6E86",
   "accent": "#B8471F", "onAccent": "#FFF8EC", "positive": "#2F6B4F", "negative": "#A63A2A", "locked": "#1F2B33",
  },
  "lines": ["#C8572B", "#1F5D8C", "#A87708", "#6A4C93", "#2F6B4F", "#8C5A2B", "#A8323E", "#2B7A78"],
  "shape": {"corner": 6, "stroke": 2, "doubleFrame": False},
 },
 {
  "id": "eletrico", "nome": "Era Elétrica", "anos": "1965–2000",
  "fonts": {"display": ("Montserrat", "ExtraBold"), "label": ("Montserrat", "SemiBold"), "body": ("SourceSansPro", "Regular"), "number": ("RobotoMono", "Medium")},
  "preview_fonts": {"display": ("Montserrat", 800), "label": ("Montserrat", 600), "body": ("Source Sans Pro", 400), "number": ("Roboto Mono", 500)},
  "colors": {
   "bg": "#F4F2EC", "panel": "#FFFFFF", "ink": "#1A1A1A", "inkMuted": "#55595F", "rule": "#D5D2C8",
   "land": "#E8E6DE", "sea": "#CFE1EA", "seaPattern": "#B8D2DE", "coast": "#8C9298", "rio": "#3B8FC2",
   "accent": "#D13A26", "onAccent": "#FFFFFF", "positive": "#1E7D4F", "negative": "#C0392B", "locked": "#1A1A1A",
  },
  "lines": ["#E2382B", "#0B63B8", "#C28400", "#7B3FA0", "#18A058", "#8B5E3C", "#E5007E", "#00A3AD"],
  "shape": {"corner": 10, "stroke": 1, "doubleFrame": False},
 },
 {
  "id": "alta", "nome": "Era da Alta Velocidade", "anos": "2000–",
  "fonts": {"display": ("Michroma", "Regular"), "label": ("TitilliumWeb", "SemiBold"), "body": ("TitilliumWeb", "Regular"), "number": ("RobotoMono", "Medium")},
  "preview_fonts": {"display": ("Michroma", 400), "label": ("Titillium Web", 600), "body": ("Titillium Web", 600), "number": ("Roboto Mono", 500)},
  "colors": {
   "bg": "#0C111C", "panel": "#141D2E", "ink": "#E8EEF8", "inkMuted": "#8A9BB8", "rule": "#2C3D5C",
   "land": "#151E30", "sea": "#0C111C", "seaPattern": "#24324D", "coast": "#3A4F75", "rio": "#3A6EA8",
   "accent": "#7CF7FF", "onAccent": "#0C111C", "positive": "#3DDC97", "negative": "#FF5C7A", "locked": "#8A9BB8",
  },
  "lines": ["#FF5C7A", "#4DA3FF", "#FFB547", "#C77DFF", "#3DDC97", "#FF8A4C", "#E6D85C", "#7CF7FF"],
  "shape": {"corner": 14, "stroke": 1, "doubleFrame": False},
 },
]
