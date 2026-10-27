#!/usr/bin/env python3
"""Art PROVISOIRE de Safrania (jalon 26, T6) : façades de la ville, sur le modèle de
`placeholders_celadopole.py` (J20 T16).

Le lot d'art de Safrania (`docs/tech/jalon-26.md` §2.7 : façades, Sylphe SARL...) n'est pas encore
là : ce script dessine des **provisoires aux dimensions finales** (emprises de la grille
`tools/plans/safrania.txt`), lisibles et sans prétention, pour que la carte, ses collisions et ses
tests existent. Remplacer par le vrai lot = changer les images (mêmes identifiants, mêmes
dimensions, mêmes emprises), pas la carte.

  python3 -I tools/art/placeholders_safrania.py

Écrit `assets/world/buildings/bldg_*_safrania_*.png` (+ ombres portée et de contact), puis leurs
entrées dans `assets/world/catalogue.json` (indent 1, comme `preparer.py`). Emprises :
`game/world/props/painted_prop_rules.gd` (bloc « Safrania », ajouté à la main) ; scènes :
`godot --headless --path . -s res://tools/build_painted_props.gd -- --nouveaux`.

Le Centre et la Boutique gardent les façades communes (`bldg_centre_01`, `bldg_boutique_01`).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
import preparer  # noqa: E402  (ombres portées et de contact du jeu)

CASE = 96
SS = 2  # supersampling
OVERHANG = 24  # px au-dessus de l'emprise (rebord de toit)

# id, largeur et profondeur (cases), couleurs, enseigne, style, portes : liste de colonnes (cases
# depuis la gauche) et côté (« bas », « haut », « gauche », « droite »), hauteur de mur (cases).
FACADES = [
    # Sylphe SARL : tour de bureaux, verre bleu-gris, enseigne dorée (14 × 17, porte double).
    dict(id="bldg_sylphe_safrania_01", w=14, d=17, wall=(150, 168, 186), roof=(112, 120, 136),
         trim=(236, 214, 140), sign="SYLPHE SARL", style="office", doors=[6, 7], side="bas",
         wall_h=7.0),
    # Arène de Morgane : pierre rose-violet, toit prune (12 × 7, porte simple, 7e colonne).
    dict(id="bldg_arene_safrania_01", w=12, d=7, wall=(214, 186, 214), roof=(120, 72, 120),
         trim=(250, 236, 250), sign="ARENE", style="hall", doors=[6], side="bas", wall_h=3.0),
    # Dojo : bois sombre, toit rouge (10 × 7, porte double, 5e et 6e colonnes).
    dict(id="bldg_dojo_safrania_01", w=10, d=7, wall=(176, 132, 92), roof=(170, 62, 52),
         trim=(244, 226, 196), sign="DOJO", style="dojo", doors=[4, 5], side="bas", wall_h=3.0),
    # Maisons (7 × 6, porte au milieu) : Copieur, Roucool, M. Psy.
    dict(id="bldg_maison_safrania_01", w=7, d=6, wall=(226, 196, 150), roof=(176, 98, 70),
         trim=(250, 240, 220), sign="", style="house", doors=[3], side="bas", wall_h=2.4),
    dict(id="bldg_maison_safrania_02", w=7, d=6, wall=(206, 214, 190), roof=(96, 130, 104),
         trim=(248, 248, 236), sign="", style="house", doors=[3], side="bas", wall_h=2.4),
    dict(id="bldg_maison_safrania_03", w=7, d=6, wall=(220, 206, 230), roof=(110, 96, 150),
         trim=(250, 246, 252), sign="", style="house", doors=[3], side="bas", wall_h=2.4),
    # Immeubles sans porte (7 × 6) : trois teintes ; dos d'immeubles au sud (8 × 4, 6 × 4).
    dict(id="bldg_immeuble_safrania_01", w=7, d=6, wall=(222, 204, 160), roof=(150, 140, 126),
         trim=(246, 240, 224), sign="", style="block", doors=[], side="bas", wall_h=3.0),
    dict(id="bldg_immeuble_safrania_02", w=7, d=6, wall=(200, 190, 178), roof=(126, 120, 118),
         trim=(240, 236, 230), sign="", style="block", doors=[], side="bas", wall_h=3.0),
    dict(id="bldg_immeuble_safrania_03", w=7, d=6, wall=(214, 180, 150), roof=(140, 108, 92),
         trim=(246, 232, 214), sign="", style="block", doors=[], side="bas", wall_h=3.0),
    dict(id="bldg_immeuble_bas_safrania_01", w=8, d=4, wall=(208, 196, 170), roof=(136, 128, 118),
         trim=(242, 236, 222), sign="", style="block", doors=[], side="bas", wall_h=2.2),
    dict(id="bldg_immeuble_bas_safrania_02", w=6, d=4, wall=(214, 190, 162), roof=(146, 120, 104),
         trim=(244, 234, 218), sign="", style="block", doors=[], side="bas", wall_h=2.2),
    # Postes de garde au bord de la ville : porte tournée vers la ville.
    dict(id="bldg_poste_safrania_nord_01", w=4, d=3, wall=(214, 206, 188), roof=(96, 104, 120),
         trim=(244, 240, 228), sign="POSTE", style="gate", doors=[1, 2], side="bas", wall_h=1.6),
    dict(id="bldg_poste_safrania_sud_01", w=4, d=3, wall=(214, 206, 188), roof=(96, 104, 120),
         trim=(244, 240, 228), sign="POSTE", style="gate", doors=[1, 2], side="haut", wall_h=1.0),
    dict(id="bldg_poste_safrania_ouest_01", w=3, d=5, wall=(214, 206, 188), roof=(96, 104, 120),
         trim=(244, 240, 228), sign="", style="gate", doors=[2, 3], side="droite", wall_h=1.4),
    dict(id="bldg_poste_safrania_est_01", w=3, d=5, wall=(214, 206, 188), roof=(96, 104, 120),
         trim=(244, 240, 228), sign="", style="gate", doors=[2, 3], side="gauche", wall_h=1.4),
]
DOOR_DARK = (46, 36, 34)
DOOR_LIGHT = (86, 66, 58)


def _font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.load_default(size=size * SS)


def _shade(color, k):
    return tuple(max(0, min(255, round(c * k))) for c in color)


def _facade(spec: dict) -> Image.Image:
    w, d, s = spec["w"], spec["d"], SS
    # Poste du sud : vu de dos (toit seul, ouverture au nord), sans rebord au-dessus (rien ne
    # passe devant le joueur qui arrive juste au nord).
    overhang = 0 if spec["side"] == "haut" else OVERHANG
    width, height = w * CASE * s, (d * CASE + overhang) * s
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    g = ImageDraw.Draw(image)
    wall, roof, trim, style = spec["wall"], spec["roof"], spec["trim"], spec["style"]
    wall_h = int(spec["wall_h"] * CASE * s)
    top_wall = height - wall_h
    # Toit vu de dessus.
    g.rounded_rectangle((0, 0, width - 1, top_wall + 14 * s), radius=10 * s, fill=roof)
    if style in ("house", "dojo", "gate"):
        for y in range(8 * s, top_wall, 14 * s):  # rangs de tuiles
            g.line((6 * s, y, width - 6 * s, y), fill=_shade(roof, 0.84), width=2 * s)
        g.line((6 * s, 6 * s, width - 6 * s, 6 * s), fill=_shade(roof, 1.18), width=4 * s)
    elif style == "office":
        g.rectangle((12 * s, 12 * s, width - 12 * s, top_wall - 10 * s), outline=_shade(roof, 0.75),
                    width=4 * s)  # acrotère
        cx, cy = width // 2, top_wall // 2
        r = int(1.6 * CASE * s)
        g.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(236, 214, 140), width=6 * s)
        g.text((cx - 22 * s, cy - 34 * s), "H", font=_font(64), fill=(236, 214, 140))
        for i in range(3):  # climatiseurs
            x = (1 + i * 4) * CASE * s
            g.rectangle((x, 2 * CASE * s // 2, x + 2 * CASE * s, 2 * CASE * s), fill=(150, 156, 170),
                        outline=_shade(roof, 0.6), width=3 * s)
    elif style in ("hall", "block"):
        g.rectangle((10 * s, 10 * s, width - 10 * s, top_wall - 8 * s), outline=_shade(roof, 0.8),
                    width=3 * s)
        if style == "hall":
            cx, cy = width // 2, top_wall // 2
            g.ellipse((cx - 70 * s, cy - 40 * s, cx + 70 * s, cy + 40 * s), fill=(236, 170, 220),
                      outline=trim, width=4 * s)
    if spec["side"] == "haut":
        # Dos du poste : seule l'ouverture au nord, peinte comme un passage sombre dans le toit.
        for col in spec["doors"]:
            x0 = col * CASE * s
            g.rectangle((x0 + 8 * s, 0, x0 + CASE * s - 8 * s, CASE * s - 18 * s), fill=DOOR_DARK)
            g.rectangle((x0 + 16 * s, 0, x0 + CASE * s - 16 * s, CASE * s - 30 * s), fill=DOOR_LIGHT)
        return image.resize((width // s, height // s), Image.LANCZOS)
    # Mur de façade.
    g.rectangle((0, top_wall, width - 1, height - 1), fill=wall)
    g.rectangle((0, top_wall, width - 1, top_wall + 10 * s), fill=_shade(wall, 0.78))
    for y in range(top_wall + 26 * s, height, 24 * s):
        g.line((0, y, width, y), fill=_shade(wall, 0.93), width=1 * s)
    g.rectangle((0, height - 12 * s, width - 1, height - 1), fill=_shade(wall, 0.7))
    # Fenêtres : rangées sur toute la hauteur du mur.
    win = (150, 190, 210) if style != "office" else (120, 160, 196)
    door_cols = set(spec["doors"]) if spec["side"] == "bas" else set()
    rows = max(1, int((wall_h - 70 * s) // (86 * s)))
    for r in range(rows):
        y0 = top_wall + (30 + r * 86) * s
        for col in range(w):
            if col in door_cols and r == rows - 1:
                continue
            if style != "office" and w > 4 and col % 2 == 1 and col not in door_cols:
                continue
            cx = col * CASE * s + CASE * s // 2
            x0, x1 = cx - 26 * s, cx + 26 * s
            g.rectangle((x0 - 4 * s, y0 - 4 * s, x1 + 4 * s, y0 + 56 * s), fill=trim)
            g.rectangle((x0, y0, x1, y0 + 52 * s), fill=win)
            g.line((cx, y0, cx, y0 + 52 * s), fill=trim, width=2 * s)
    if style == "dojo":
        for x in range(0, width, CASE * s):  # poteaux de bois
            g.rectangle((x, top_wall, x + 8 * s, height), fill=_shade(wall, 0.6))
    # Portes.
    if spec["side"] == "bas" and spec["doors"]:
        cols = spec["doors"]
        x0, x1 = min(cols) * CASE * s, (max(cols) + 1) * CASE * s
        g.rectangle((x0 + 4 * s, height - 130 * s, x1 - 4 * s, height - 1), fill=trim)
        g.rectangle((x0 + 10 * s, height - 124 * s, x1 - 10 * s, height - 1), fill=DOOR_DARK)
        g.rectangle((x0 + 18 * s, height - 116 * s, x1 - 18 * s, height - 1), fill=DOOR_LIGHT)
        if style == "office":
            g.line(((x0 + x1) // 2, height - 116 * s, (x0 + x1) // 2, height), fill=trim, width=3 * s)
    elif spec["side"] in ("gauche", "droite"):
        # Porte de côté (rangées de l'emprise, depuis le haut) : bande sombre sur le bord.
        for row in spec["doors"]:
            y0 = overhang * s + row * CASE * s
            if spec["side"] == "droite":
                g.rectangle((width - 30 * s, y0 + 6 * s, width - 1, y0 + CASE * s - 6 * s), fill=DOOR_DARK)
            else:
                g.rectangle((0, y0 + 6 * s, 30 * s, y0 + CASE * s - 6 * s), fill=DOOR_DARK)
    # Enseigne.
    if spec["sign"]:
        font = _font(30 if len(spec["sign"]) < 10 else 26)
        box = g.textbbox((0, 0), spec["sign"], font=font)
        tw, th = box[2] - box[0], box[3] - box[1]
        bx0 = (width - tw) // 2 - 22 * s
        by0 = top_wall - 30 * s
        g.rounded_rectangle((bx0, by0, bx0 + tw + 44 * s, by0 + th + 24 * s), radius=8 * s,
                            fill=(40, 44, 58) if style == "office" else _shade(trim, 0.96),
                            outline=_shade(trim, 0.6), width=3 * s)
        g.text((bx0 + 22 * s, by0 + 10 * s - box[1]), spec["sign"], font=font,
               fill=(236, 214, 140) if style == "office" else (60, 52, 46))
    return image.resize((width // s, height // s), Image.LANCZOS)


def _write_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def write_facades() -> None:
    catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
    catalogue = json.loads(catalogue_path.read_text())
    manifest = json.loads((ICI / "manifeste.json").read_text())
    for spec in FACADES:
        rel = "assets/world/buildings/%s.png" % spec["id"]
        image = _facade(spec)
        _write_png(image, RACINE / rel)
        entry = {"fichier": "res://" + rel, "taille": list(image.size)}
        shadow, offset, reduction = preparer.ombre_portee(image, manifest["ombre_portee"])
        name = rel.replace(".png", "_shadow.png")
        _write_png(shadow, RACINE / name)
        entry["ombre"] = {"fichier": "res://" + name, "decalage": list(offset),
                          "echelle": reduction, "taille": list(shadow.size)}
        shadow, offset, reduction = preparer.ombre_contact(image, 0.12, manifest["ombre_contact"])
        name = rel.replace(".png", "_contact.png")
        _write_png(shadow, RACINE / name)
        entry["contact"] = {"fichier": "res://" + name, "decalage": list(offset),
                            "echelle": reduction, "taille": list(shadow.size)}
        catalogue["objets"][spec["id"]] = entry
        print(spec["id"], image.size)
    catalogue_path.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
    write_facades()
