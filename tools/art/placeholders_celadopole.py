#!/usr/bin/env python3
"""Art PROVISOIRE de Céladopole (jalon 20, T16) : façades de la ville et enveloppes d'intérieur.

Le kit d'art de Céladopole (série 22 bis : façades, serre, grand magasin...) n'est pas encore là
(`docs/tech/jalon-20.md` §1.4, stratégie d'accélération) : ce script dessine des **provisoires aux
dimensions finales**, lisibles et sans prétention, pour que cartes, collisions et tests existent.
Remplacer par le vrai kit = changer les images (mêmes identifiants, mêmes dimensions, mêmes
emprises), pas les cartes.

  python3 tools/art/placeholders_celadopole.py            # tout
  python3 tools/art/placeholders_celadopole.py --facades  # façades et fontaine seulement
  python3 tools/art/placeholders_celadopole.py --shells   # enveloppes d'intérieur seulement

Écrit :
  - `assets/world/buildings/bldg_*_01.png` (+ ombres) et `assets/world/props/prop_fontaine_01.png`,
    puis leurs entrées dans `assets/world/catalogue.json` (indent 1, comme `preparer.py`) ;
    emprises dans `game/world/props/painted_prop_rules.gd` (bloc « Série 22 bis provisoire »,
    ajouté à la main) ; scènes par `godot ... tools/build_painted_props.gd -- --nouveaux` ;
  - `assets/world/interiors/placeholder/ph_<carte>.png` : enveloppe d'une carte d'intérieur,
    **dessinée d'après sa grille** (`tools/plans/celadopole_*.txt`) : murs, sol, escaliers,
    comptoirs, étagères... cuits dans l'image (aucun mobilier séparé).
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
SS = 2  # supersampling des façades

# --- Façades ---------------------------------------------------------------------------------
# id, largeur et profondeur (cases), couleurs, enseigne, style.
FACADES = [
    # Grand magasin : briques miel, toit-terrasse clair, vitrines à auvents de cinq couleurs.
    dict(id="bldg_grand_magasin_01", w=14, d=9, wall=(214, 176, 120), roof=(226, 222, 210),
         trim=(250, 246, 232), sign="GRAND MAGASIN", style="store"),
    # Résidence : pierre claire, toit ardoise vert-gris, deux rangs de fenêtres.
    dict(id="bldg_residence_01", w=12, d=8, wall=(228, 214, 186), roof=(108, 128, 124),
         trim=(250, 246, 232), sign="RESIDENCE", style="mansion"),
    # Escalier de service : tourelle de pierre au nord de la Résidence.
    dict(id="bldg_escalier_service_01", w=4, d=4, wall=(214, 200, 170), roof=(96, 112, 108),
         trim=(244, 238, 220), sign="SERVICE", style="tower"),
    # Casino : seul bâtiment aux néons (magenta et or).
    dict(id="bldg_casino_01", w=12, d=7, wall=(58, 40, 78), roof=(40, 28, 56),
         trim=(255, 70, 180), sign="CASINO", style="casino"),
    # Façade de l'ancien Coin à lots : vitrine éteinte, volets, aucune porte.
    dict(id="bldg_coin_lots_01", w=8, d=7, wall=(176, 168, 158), roof=(90, 90, 96),
         trim=(206, 200, 190), sign="", style="shut"),
    # Arène : serre élégante, charpente blanche et verrière verte.
    dict(id="bldg_arene_celadopole_01", w=12, d=7, wall=(206, 232, 214), roof=(120, 190, 150),
         trim=(250, 252, 246), sign="ARENE", style="glasshouse"),
    dict(id="bldg_restaurant_01", w=8, d=7, wall=(222, 190, 150), roof=(168, 78, 62),
         trim=(250, 240, 220), sign="RESTAURANT", style="house"),
    dict(id="bldg_hotel_01", w=10, d=7, wall=(190, 204, 214), roof=(84, 100, 128),
         trim=(246, 248, 250), sign="HOTEL", style="house"),
    dict(id="bldg_maison_chef_01", w=7, d=6, wall=(210, 160, 120), roof=(150, 84, 68),
         trim=(246, 236, 216), sign="", style="house"),
    # Maison du toit de la Résidence (5 × 4 sur la terrasse).
    dict(id="bldg_maison_toit_01", w=5, d=4, wall=(232, 224, 204), roof=(122, 150, 140),
         trim=(250, 248, 238), sign="", style="house"),
]
# Largeur de l'ouverture (cases) pour la porte dessinée ; 0 = aucune porte.
DOORS = {"bldg_grand_magasin_01": 2, "bldg_residence_01": 2, "bldg_escalier_service_01": 2,
         "bldg_casino_01": 2, "bldg_coin_lots_01": 0, "bldg_arene_celadopole_01": 2,
         "bldg_restaurant_01": 2, "bldg_hotel_01": 2, "bldg_maison_chef_01": 1,
         "bldg_maison_toit_01": 1}
OVERHANG = 24  # px au-dessus de la rangée du haut de l'emprise (rebord de toit)
AWNINGS = [(226, 96, 96), (240, 176, 64), (96, 176, 120), (88, 140, 214), (170, 110, 200)]


def _font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.load_default(size=size * SS)


def _shade(color, k):
    return tuple(max(0, min(255, round(c * k))) for c in color)


def _facade(spec: dict) -> Image.Image:
    w, d = spec["w"], spec["d"]
    width, height = w * CASE * SS, (d * CASE + OVERHANG) * SS
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    g = ImageDraw.Draw(image)
    s = SS
    wall, roof, trim = spec["wall"], spec["roof"], spec["trim"]
    # Hauteur du mur de façade : 3 cases (2,5 pour les petits bâtiments), le reste est toit.
    wall_h = int((3.0 if d >= 7 else 2.4) * CASE * s)
    top_wall = height - wall_h
    # Toit : du haut de l'image au haut du mur.
    g.rounded_rectangle((0, 0, width - 1, top_wall + 14 * s), radius=10 * s, fill=roof)
    style = spec["style"]
    step = 14 * s
    if style in ("house", "mansion", "tower", "shut"):
        for y in range(8 * s, top_wall, step):  # rangs de tuiles
            g.line((6 * s, y, width - 6 * s, y), fill=_shade(roof, 0.84), width=2 * s)
        g.line((6 * s, 6 * s, width - 6 * s, 6 * s), fill=_shade(roof, 1.18), width=4 * s)
    elif style == "store":
        g.rectangle((10 * s, 10 * s, width - 10 * s, top_wall - 8 * s), outline=_shade(roof, 0.8),
                    width=3 * s)  # parapet de la terrasse
        for i in range(3):  # lanterneaux et climatisation
            x = (2 + i * 4) * CASE * s
            g.rectangle((x, 2 * CASE * s, x + 3 * CASE * s, 3.6 * CASE * s),
                        fill=(188, 214, 226), outline=_shade(roof, 0.7), width=3 * s)
    elif style == "casino":
        g.rectangle((8 * s, 8 * s, width - 8 * s, top_wall - 6 * s), outline=(255, 70, 180),
                    width=4 * s)
        g.rectangle((16 * s, 16 * s, width - 16 * s, top_wall - 14 * s), outline=(255, 200, 70),
                    width=3 * s)
    elif style == "glasshouse":
        for x in range(0, width, 48 * s):  # montants de la verrière
            g.line((x, 0, x, top_wall), fill=trim, width=3 * s)
        for y in range(0, top_wall, 48 * s):
            g.line((0, y, width, y), fill=trim, width=3 * s)
    # Mur de façade.
    g.rectangle((0, top_wall, width - 1, height - 1), fill=wall)
    g.rectangle((0, top_wall, width - 1, top_wall + 10 * s), fill=_shade(wall, 0.78))
    for y in range(top_wall + 26 * s, height, 24 * s):  # joints de briques
        g.line((0, y, width, y), fill=_shade(wall, 0.92), width=1 * s)
    g.rectangle((0, height - 12 * s, width - 1, height - 1), fill=_shade(wall, 0.7))  # soubassement
    # Ouverture de la porte (cases du bas, au centre ; hauteur 1,3 case).
    door = DOORS[spec["id"]]
    door_x0 = door_x1 = 0
    if door:
        door_x0 = (width // 2) - (door * CASE * s) // 2
        door_x1 = door_x0 + door * CASE * s
        g.rectangle((door_x0 - 6 * s, height - 130 * s, door_x1 + 6 * s, height - 1), fill=trim)
        g.rectangle((door_x0, height - 124 * s, door_x1, height - 1), fill=(46, 36, 34))
        g.rectangle((door_x0 + 8 * s, height - 116 * s, door_x1 - 8 * s, height - 1),
                    fill=(86, 66, 58))
    # Fenêtres selon le style.
    win = (150, 190, 210)
    if style == "shut":
        win = (70, 72, 78)
    n_cols = max(1, w // 2 - (1 if door else 0))
    margin = 30 * s
    span = width - 2 * margin
    if style == "store":
        # Vitrines pleine largeur, auvents colorés, un par groupe de 2 cases.
        for i in range(w // 2):
            x0 = margin + i * span // (w // 2) + 6 * s
            x1 = margin + (i + 1) * span // (w // 2) - 6 * s
            if door and x1 > door_x0 - 10 * s and x0 < door_x1 + 10 * s:
                continue
            g.rectangle((x0, top_wall + 70 * s, x1, height - 24 * s), fill=win, outline=trim,
                        width=3 * s)
            g.polygon([(x0 - 4 * s, top_wall + 30 * s), (x1 + 4 * s, top_wall + 30 * s),
                       (x1 + 10 * s, top_wall + 74 * s), (x0 - 10 * s, top_wall + 74 * s)],
                      fill=AWNINGS[i % len(AWNINGS)])
    elif style in ("mansion", "house", "casino", "shut", "glasshouse", "tower"):
        rows = 2 if (style == "mansion" and d >= 8) else 1
        for r in range(rows):
            y0 = top_wall + (28 + r * 78) * s
            for i in range(w // 2 if w > 4 else 1):
                cx = margin + (i + 0.5) * span // max(1, (w // 2 if w > 4 else 1))
                if door and r == rows - 1 and abs(cx - (door_x0 + door_x1) / 2) < 1.0 * CASE * s:
                    continue
                x0, x1 = cx - 24 * s, cx + 24 * s
                g.rectangle((x0 - 4 * s, y0 - 4 * s, x1 + 4 * s, y0 + 60 * s + 4 * s), fill=trim)
                g.rectangle((x0, y0, x1, y0 + 60 * s), fill=win)
                g.line((cx, y0, cx, y0 + 60 * s), fill=trim, width=2 * s)
                if style == "shut":
                    for y in range(int(y0), int(y0 + 60 * s), 8 * s):
                        g.line((x0, y, x1, y), fill=(52, 54, 60), width=2 * s)
    if style == "casino":
        for x in range(10 * s, width - 10 * s, 28 * s):  # guirlande de néons
            g.ellipse((x, top_wall + 8 * s, x + 12 * s, top_wall + 20 * s), fill=(255, 215, 90))
    # Enseigne.
    if spec["sign"]:
        font = _font(30 if len(spec["sign"]) < 10 else 24)
        box = g.textbbox((0, 0), spec["sign"], font=font)
        tw, th = box[2] - box[0], box[3] - box[1]
        bx0 = (width - tw) // 2 - 22 * s
        by0 = top_wall - 30 * s
        g.rounded_rectangle((bx0, by0, bx0 + tw + 44 * s, by0 + th + 24 * s), radius=8 * s,
                            fill=(34, 30, 40) if style == "casino" else _shade(trim, 0.96),
                            outline=spec["trim"] if style == "casino" else _shade(trim, 0.6),
                            width=3 * s)
        g.text((bx0 + 22 * s, by0 + 10 * s - box[1]), spec["sign"], font=font,
               fill=(255, 215, 90) if style == "casino" else (60, 52, 46))
    return image.resize((width // s, height // s), Image.LANCZOS)


def _fountain() -> Image.Image:
    size = 2 * CASE
    image = Image.new("RGBA", (size * SS, (size - 6) * SS), (0, 0, 0, 0))
    g = ImageDraw.Draw(image)
    s = SS
    w, h = image.size
    g.ellipse((4 * s, 20 * s, w - 4 * s, h - 2 * s), fill=(196, 190, 176))
    g.ellipse((12 * s, 28 * s, w - 12 * s, h - 12 * s), fill=(120, 190, 214))
    g.ellipse((w // 2 - 22 * s, h // 2 - 20 * s, w // 2 + 22 * s, h // 2 + 14 * s),
              fill=(214, 208, 192))
    g.rectangle((w // 2 - 6 * s, 6 * s, w // 2 + 6 * s, h // 2), fill=(226, 220, 205))
    g.ellipse((w // 2 - 18 * s, 2 * s, w // 2 + 18 * s, 22 * s), fill=(170, 224, 240))
    return image.resize((w // s, h // s), Image.LANCZOS)


def _write_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def write_facades() -> None:
    catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
    catalogue = json.loads(catalogue_path.read_text())
    manifest = json.loads((ICI / "manifeste.json").read_text())
    entries = [(f["id"], "assets/world/buildings/%s.png" % f["id"], _facade(f), 0.12)
               for f in FACADES]
    entries.append(("prop_fontaine_01", "assets/world/props/prop_fontaine_01.png", _fountain(),
                    None))
    for ident, rel, image, contact in entries:
        _write_png(image, RACINE / rel)
        entry = {"fichier": "res://" + rel, "taille": list(image.size)}
        if ident.startswith("bldg_"):
            shadow, offset, reduction = preparer.ombre_portee(image, manifest["ombre_portee"])
            name = rel.replace(".png", "_shadow.png")
            _write_png(shadow, RACINE / name)
            entry["ombre"] = {"fichier": "res://" + name, "decalage": list(offset),
                              "echelle": reduction, "taille": list(shadow.size)}
        if contact is not None:
            shadow, offset, reduction = preparer.ombre_contact(image, contact,
                                                               manifest["ombre_contact"])
            name = rel.replace(".png", "_contact.png")
            _write_png(shadow, RACINE / name)
            entry["contact"] = {"fichier": "res://" + name, "decalage": list(offset),
                                "echelle": reduction, "taille": list(shadow.size)}
        catalogue["objets"][ident] = entry
        print(ident, image.size)
    catalogue_path.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")


# --- Enveloppes d'intérieur -------------------------------------------------------------------
# carte -> (grille, accent, ambiance). Les grilles font foi ; l'image n'en est que la lecture.
SHELLS = {
    "celadon_dept_gf": ("celadopole_magasin_rdc", (92, 178, 168), "store"),
    "celadon_dept_2f": ("celadopole_magasin_2e", (232, 120, 150), "store"),
    "celadon_dept_3f": ("celadopole_magasin_3e", (150, 120, 214), "store"),
    "celadon_dept_4f": ("celadopole_magasin_4e", (240, 176, 70), "store"),
    "celadon_dept_5f": ("celadopole_magasin_5e", (96, 160, 220), "store"),
    "celadon_dept_roof": ("celadopole_magasin_toit", (150, 196, 120), "roof"),
    "celadon_dept_elevator": ("celadopole_magasin_ascenseur", (170, 176, 186), "cabin"),
    "celadon_mansion_gf": ("celadopole_residence_rdc", (176, 140, 104), "mansion"),
    "celadon_mansion_1f": ("celadopole_residence_1er", (176, 140, 104), "mansion"),
    "celadon_mansion_2f": ("celadopole_residence_2e", (176, 140, 104), "mansion"),
    "celadon_mansion_3f": ("celadopole_residence_3e", (176, 140, 104), "mansion"),
    "celadon_mansion_roof": ("celadopole_residence_toit", (150, 196, 120), "roof"),
    "celadon_mansion_roof_house": ("celadopole_residence_maison_toit", (190, 150, 110), "house"),
    "celadon_restaurant": ("celadopole_restaurant", (196, 120, 90), "house"),
    "celadon_chief_house": ("celadopole_maison_chef", (190, 150, 110), "house"),
    "celadon_hotel": ("celadopole_hotel", (120, 150, 190), "house"),
    "celadon_gym": ("celadopole_arene", (112, 176, 120), "gym"),
}


def _read_plan(name: str) -> list[str]:
    rows: list[str] = []
    active = False
    for line in (RACINE / "tools" / "plans" / (name + ".txt")).read_text().splitlines():
        if line.startswith("GRILLE"):
            active = True
            continue
        if active and line.startswith("FIN"):
            break
        if active and line[:2].isdigit():
            rows.append(line.split(" ", 1)[1].strip())
    return rows


def _box(g: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, top, front, lift: int) -> None:
    """Volume vu de dessus et de face : le dessus est remonté de [lift] px."""
    g.rectangle((x, y + lift, x + w - 1, y + h - 1), fill=front)
    g.rectangle((x, y, x + w - 1, y + h - 1 - lift), fill=top)
    g.rectangle((x, y, x + w - 1, y + h - 1), outline=_shade(front, 0.7), width=2)


def _shell(map_id: str, plan: str, accent, mood: str) -> Image.Image:
    rows = _read_plan(plan)
    cols, lines = len(rows[0]), len(rows)
    image = Image.new("RGB", (cols * CASE, lines * CASE), (30, 28, 34))
    g = ImageDraw.Draw(image)
    floor_a, floor_b = {
        "store": ((236, 232, 222), (222, 218, 208)), "roof": ((200, 196, 188), (188, 184, 176)),
        "cabin": ((120, 124, 132), (110, 114, 122)), "mansion": ((226, 206, 170), (214, 194, 158)),
        "house": ((232, 214, 178), (222, 204, 168)), "gym": ((196, 214, 186), (184, 204, 176)),
    }[mood]
    wall = {"store": (206, 196, 176), "roof": (176, 164, 150), "cabin": (150, 156, 166),
            "mansion": (190, 160, 122), "house": (196, 160, 124), "gym": (150, 186, 156)}[mood]
    font = ImageFont.load_default(size=22)

    def at(x, y):
        return rows[y][x] if 0 <= x < cols and 0 <= y < lines else "K"

    for y in range(lines):
        for x in range(cols):
            c = at(x, y)
            px, py = x * CASE, y * CASE
            if c == "K":
                continue
            g.rectangle((px, py, px + CASE - 1, py + CASE - 1),
                        fill=floor_a if (x + y) % 2 == 0 else floor_b)
    # Murs : face visible sous chaque rangée de mur qui touche du sol au sud.
    for y in range(lines):
        for x in range(cols):
            if at(x, y) != "K":
                continue
            px, py = x * CASE, y * CASE
            south_open = at(x, y + 1) not in "KSZVPf" and at(x, y + 1) != "K"
            g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=_shade(wall, 0.62))
            if south_open:
                g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=wall)
                g.rectangle((px, py + CASE - 14, px + CASE - 1, py + CASE - 1),
                            fill=_shade(wall, 0.72))  # plinthe
                g.rectangle((px, py + 10, px + CASE - 1, py + 18), fill=_shade(wall, 1.12))
    # Éléments cuits dans l'image, case par case (les groupes horizontaux se lisent d'un bloc).
    for y in range(lines):
        x = 0
        while x < cols:
            c = at(x, y)
            n = 1
            while x + n < cols and at(x + n, y) == c:
                n += 1
            px, py, wpx = x * CASE, y * CASE, n * CASE
            if c == "S" or c == "Z":
                up = c == "S" if mood != "roof" else False
                for k in range(n):
                    bx = px + k * CASE
                    g.rectangle((bx, py, bx + CASE - 1, py + CASE - 1), fill=(120, 108, 98))
                    for i in range(5):
                        shade = 0.78 + 0.07 * (i if up else 4 - i)
                        g.rectangle((bx + 6, py + 8 + i * 17, bx + CASE - 7, py + 22 + i * 17),
                                    fill=_shade((220, 208, 190), shade))
                    g.polygon([(bx + 40, py + 68), (bx + 56, py + 68), (bx + 48, py + 54)] if up
                              else [(bx + 40, py + 54), (bx + 56, py + 54), (bx + 48, py + 68)],
                              fill=(60, 54, 50))
            elif c == "V":
                g.rectangle((px, py, px + wpx - 1, py + CASE - 1), fill=(170, 176, 186))
                g.rectangle((px + 6, py + 6, px + wpx - 7, py + CASE - 1), fill=(120, 128, 140))
                g.line((px + wpx // 2, py + 6, px + wpx // 2, py + CASE - 1), fill=(60, 66, 76),
                       width=3)
                g.rectangle((px + wpx // 2 - 12, py - 2, px + wpx // 2 + 12, py + 6), fill=accent)
            elif c == "X":
                g.rectangle((px, py, px + wpx - 1, py + CASE - 1), fill=(70, 100, 150))
                g.rectangle((px + 6, py + 6, px + wpx - 7, py + CASE - 7), outline=(220, 220, 230),
                            width=2)
            elif c == "P":
                g.rectangle((px + 8, py + 8, px + wpx - 9, py + CASE - 16), fill=(250, 246, 232),
                            outline=_shade(accent, 0.7), width=3)
                for i in range(5):
                    g.rectangle((px + 22, py + 18 + i * 10, px + wpx - 23, py + 22 + i * 10),
                                fill=accent if i % 2 == 0 else (150, 140, 130))
            elif c == "B":
                _box(g, px + 2, py + 6, wpx - 4, CASE - 10, (214, 176, 126), (150, 110, 74), 30)
            elif c == "e":
                for k in range(n):
                    bx = px + k * CASE
                    _box(g, bx + 8, py + 6, CASE - 16, CASE - 10, (236, 230, 216), (170, 130, 96),
                         22)
                    for i in range(3):
                        g.rectangle((bx + 16, py + 12 + i * 16, bx + CASE - 17, py + 18 + i * 16),
                                    fill=accent if (i + k) % 2 else (200, 190, 170))
            elif c == "m":
                for k in range(n):
                    bx = px + k * CASE
                    _box(g, bx + 14, py + 4, CASE - 28, CASE - 8, (96, 104, 124), (66, 72, 90), 36)
                    g.rectangle((bx + 26, py + 14, bx + CASE - 27, py + 36), fill=accent)
            elif c == "t":
                for k in range(n):
                    bx = px + k * CASE
                    _box(g, bx + 6, py + 10, CASE - 12, CASE - 14, (222, 188, 140),
                         (160, 120, 82), 26)
            elif c == "c":
                for k in range(n):
                    bx = px + k * CASE
                    _box(g, bx + 4, py + 14, CASE - 8, CASE - 20, accent, _shade(accent, 0.7), 34)
            elif c == "n":
                for k in range(n):
                    bx = px + k * CASE
                    _box(g, bx + 4, py + 30, CASE - 8, 44, (190, 150, 106), (140, 104, 70), 18)
            elif c == "p":
                for k in range(n):
                    bx = px + k * CASE
                    g.rectangle((bx + 30, py + 54, bx + 66, py + 88), fill=(176, 110, 84))
                    g.ellipse((bx + 14, py + 8, bx + 82, py + 66), fill=(74, 150, 86))
                    g.ellipse((bx + 28, py + 18, bx + 60, py + 46), fill=(110, 184, 112))
            elif c == "f":  # porte du bureau privé
                g.rectangle((px + 12, py + 6, px + wpx - 13, py + CASE - 1), fill=(96, 68, 50))
                g.rectangle((px + 20, py + 14, px + wpx - 21, py + 42), fill=(220, 214, 196))
                g.text((px + 24, py + 16), "BUREAU", font=ImageFont.load_default(size=14),
                       fill=(60, 50, 44))
            elif c == "w":
                for k in range(n):
                    bx = px + k * CASE
                    g.rectangle((bx, py, bx + CASE - 1, py + CASE - 1), fill=(110, 180, 200))
                    g.rectangle((bx, py, bx + CASE - 1, py + CASE - 1),
                                outline=(226, 224, 212), width=5)
                    g.ellipse((bx + 28, py + 30, bx + 70, py + 62), outline=(170, 224, 232),
                              width=2)
            elif c == "x" and mood == "gym":
                pass  # haies : objets peints du catalogue (build_celadon_gym.gd)
            elif c == "j" and mood == "gym":
                pass
            x += n
    if mood == "gym":
        # Verrière : ombres vertes douces en haut, montants blancs.
        for x in range(0, cols * CASE, 192):
            g.line((x, 0, x, 2 * CASE), fill=(236, 244, 236), width=4)
    return image


def write_shells() -> None:
    for map_id, (plan, accent, mood) in SHELLS.items():
        image = _shell(map_id, plan, accent, mood)
        _write_png(image, RACINE / "assets" / "world" / "interiors" / "placeholder"
                   / ("ph_%s.png" % map_id))
        print(map_id, image.size)


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or "--facades" in args:
        write_facades()
    if not args or "--shells" in args:
        write_shells()
