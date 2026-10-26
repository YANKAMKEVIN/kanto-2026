#!/usr/bin/env python3
"""Points d'origine des effets de combat par espèce (chantier Combat vivant, CV.A).

Plan : docs/tech/combat-vivant.md §2.2 (CV-10, décision de Kevin du 2026-10-26).
Données : data/battle/fx_anchors.json.

Chaque espèce a, de face (artwork officiel) et de dos (dos peint retenu par BattleArt :
plongée > IA > 3D > provisoire), des points nommés. Coordonnées **normalisées dans la boîte
visible** de l'image (rectangle de l'alpha > 0, comme `Image.get_used_rect()` de Godot) :
(0, 0) = coin haut gauche de la boîte, (1, 1) = coin bas droit. La boîte en pixels est écrite à
côté (`box`), le jeu n'a donc pas à la recalculer.

Commandes :
  squelette   crée ou met à jour les entrées (image, taille, boîte, centre), garde les points
  grilles     une image quadrillée par espèce, pour poser les points (--de N --a M)
  planche     planches de contrôle pour Kevin (points dessinés sur les images)
  synthese    planche unique des espèces délicates (liste SYNTHESE), lisible sur téléphone
  verifier    contrôle du fichier (noms, bornes, image à jour)

Exemple : python3 tools/art/fx_anchors.py grilles --de 1 --a 38
"""
from __future__ import annotations

import argparse
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATA = os.path.join(ROOT, "data", "battle", "fx_anchors.json")
OFFICIAL = "assets/sprites/pokemon/official/{:03d}.png"
BACKS = ["assets/sprites/pokemon/dos/dos_rb_{:03d}.png",
         "assets/sprites/pokemon/dos/dos_ia_{:03d}.png",
         "assets/sprites/pokemon/dos/dos3d_{:03d}.png"]
PLACEHOLDER_BACK = "assets/sprites/pokemon/placeholder/{}_back.png"
OUT = os.path.join(ROOT, "build", "cv_a")

## Points permis. Seul `tete` est obligatoire ; `centre` est calculé (barycentre de l'alpha).
## Paires (deux points, gauche puis droite dans l'image) : joues, yeux, mains, canons.
POINTS = ["tete", "bouche", "yeux", "joues", "mains", "queue", "cornes", "canons", "bulbe",
          "centre"]
PAIRS = {"yeux", "joues", "mains", "canons"}
COLORS = {"tete": "#FFFFFF", "bouche": "#FF3B30", "yeux": "#FF2DD1", "joues": "#FFD60A",
          "mains": "#34C759", "queue": "#FF9500", "cornes": "#AF52DE", "canons": "#0A84FF",
          "bulbe": "#30D158", "centre": "#8E8E93"}

## Identifiants des 151 espèces (données du jeu et des branches de jalons ; 5 absentes de toutes
## les branches au 2026-10-26, écrites ici d'après le Pokédex national).
## Les 25 espèces absentes de `main` au 2026-10-26 (20 viennent des branches `jalon-23` à `jalon-32`).
EXTRA_IDS = {
    65: ("alakazam", "Alakazam"), 68: ("machamp", "Mackogneur"), 94: ("gengar", "Ectoplasma"),
    103: ("exeggutor", "Noadkoko"), 106: ("hitmonlee", "Kicklee"), 107: ("hitmonchan", "Tygnon"),
    108: ("lickitung", "Excelangue"), 112: ("rhydon", "Rhinoféros"), 113: ("chansey", "Leveinard"),
    122: ("mr_mime", "M. Mime"), 123: ("scyther", "Insécateur"), 124: ("jynx", "Lippoutou"),
    125: ("electabuzz", "Élektek"), 127: ("pinsir", "Scarabrute"), 128: ("tauros", "Tauros"),
    131: ("lapras", "Lokhlass"), 132: ("ditto", "Métamorph"), 137: ("porygon", "Porygon"),
    145: ("zapdos", "Électhor"), 146: ("moltres", "Sulfura"), 147: ("dratini", "Minidraco"),
    148: ("dragonair", "Draco"), 149: ("dragonite", "Dracolosse"), 150: ("mewtwo", "Mewtwo"),
    151: ("mew", "Mew"),
}


def rel(path: str) -> str:
    return os.path.relpath(path, ROOT)


def load() -> dict:
    if not os.path.exists(DATA):
        return {"version": 1, "species": {}}
    with open(DATA, encoding="utf-8") as f:
        return json.load(f)


def save(data: dict) -> None:
    data["species"] = dict(sorted(data["species"].items()))
    with open(DATA, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")


def back_image(dex: int, species_id: str) -> str:
    for pattern in BACKS:
        path = pattern.format(dex)
        if os.path.exists(os.path.join(ROOT, path)):
            return path
    if species_id:
        path = PLACEHOLDER_BACK.format(species_id)
        if os.path.exists(os.path.join(ROOT, path)):
            return path
    return ""


def box_and_centre(path: str) -> tuple[list[int], list[int], list[float]]:
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    alpha = im.getchannel("A")
    bbox = alpha.point(lambda a: 255 if a > 0 else 0).getbbox() or (0, 0, im.width, im.height)
    x0, y0, x1, y1 = bbox
    crop = alpha.crop(bbox)
    w, h = crop.size
    # Barycentre de l'alpha (sous-échantillonné : 64 × 64 suffit).
    small = crop.resize((min(64, w), min(64, h)))
    sw, sh = small.size
    total = sx = sy = 0.0
    pixels = small.load()
    for y in range(sh):
        for x in range(sw):
            a = pixels[x, y]
            total += a
            sx += a * (x + 0.5)
            sy += a * (y + 0.5)
    centre = [round(sx / total / sw, 3), round(sy / total / sh, 3)] if total else [0.5, 0.5]
    return [im.width, im.height], [x0, y0, x1 - x0, y1 - y0], centre


def species_ids() -> dict[int, tuple[str, str]]:
    """Identifiants et noms connus des données du jeu (data/pokemon/species/)."""
    ids: dict[int, tuple[str, str]] = {}
    folder = os.path.join(ROOT, "data", "pokemon", "species")
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".json"):
            continue
        with open(os.path.join(folder, name), encoding="utf-8") as f:
            for key, value in json.load(f).items():
                if isinstance(value, dict) and "dex" in value:
                    ids.setdefault(value["dex"], (key, value.get("name", key)))
    return ids


def cmd_squelette(args: argparse.Namespace) -> None:
    data = load()
    known = species_ids()
    for dex in range(1, 152):
        key = f"{dex:03d}"
        entry = data["species"].setdefault(key, {})
        species_id, name = known.get(dex) or EXTRA_IDS.get(dex) or (entry.get("id", ""), entry.get("name", ""))
        entry["id"] = species_id or entry.get("id", "")
        entry["name"] = name or entry.get("name", "")
        for side, path in (("front", OFFICIAL.format(dex)), ("back", back_image(dex, entry["id"]))):
            view = entry.get(side) or {}
            if not path:
                entry[side] = None
                continue
            size, box, centre = box_and_centre(path)
            if view.get("image") not in (None, path) or view.get("box") not in (None, box):
                # Image changée : les points posés ne valent plus rien.
                view = {"points": {}}
            view["image"] = path
            view["size"] = size
            view["box"] = box
            points = view.setdefault("points", {})
            points["centre"] = centre
            entry[side] = {k: view[k] for k in ("image", "size", "box", "points")}
    data["_doc"] = ("Points d'origine des effets de combat (docs/tech/combat-vivant.md §2.2, "
                    "CV-10). Coordonnées normalisées dans la boîte visible (box, px). "
                    "Outil : tools/art/fx_anchors.py.")
    save(data)
    print(f"{len(data['species'])} espèces écrites dans {rel(DATA)}")


def _font(size: int) -> ImageFont.ImageFont:
    for path in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _checker(size: tuple[int, int]) -> Image.Image:
    bg = Image.new("RGB", size, "#5A6270")
    d = ImageDraw.Draw(bg)
    step = 24
    for y in range(0, size[1], step):
        for x in range(0, size[0], step):
            if (x // step + y // step) % 2:
                d.rectangle([x, y, x + step, y + step], fill="#4A515D")
    return bg


def _view_panel(view: dict | None, cell: int, grid: bool, title: str,
                big: bool = False) -> Image.Image:
    pad = 40
    panel = Image.new("RGB", (cell + pad * 2, cell + pad * 2 + 40), "#20242B")
    d = ImageDraw.Draw(panel)
    d.text((pad, 8), title, fill="#FFFFFF", font=_font(30 if big else 22))
    if view is None:
        d.text((pad, cell // 2), "aucune image", fill="#FF6B6B", font=_font(28))
        return panel
    im = Image.open(os.path.join(ROOT, view["image"])).convert("RGBA")
    x, y, w, h = view["box"]
    crop = im.crop((x, y, x + w, y + h))
    scale = cell / max(w, h)
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    crop = crop.resize((nw, nh), Image.NEAREST if max(w, h) < 200 else Image.LANCZOS)
    ox, oy = pad, pad + 40
    board = _checker((nw, nh))
    board.paste(crop, (0, 0), crop)
    panel.paste(board, (ox, oy))
    small = _font(26 if big else 15)
    if grid:
        for i in range(21):
            t = i / 20
            major = i % 2 == 0
            colour = "#00E5FF" if major else "#00E5FF55"
            width = 2 if i % 10 == 0 else 1
            gx, gy = ox + round(t * nw), oy + round(t * nh)
            if major or True:
                d.line([(gx, oy), (gx, oy + nh)], fill=colour if major else "#2A7F8C", width=width)
                d.line([(ox, gy), (ox + nw, gy)], fill=colour if major else "#2A7F8C", width=width)
            if major:
                d.text((gx - 8, oy - 18), f"{t:.1f}"[1:] if t < 1 else "1", fill="#00E5FF",
                       font=small)
                d.text((ox - 30, gy - 8), f"{t:.1f}"[1:] if t < 1 else "1", fill="#00E5FF",
                       font=small)
    for name, value in (view.get("points") or {}).items():
        pts = value if name in PAIRS else [value]
        for p in pts:
            px, py = ox + p[0] * nw, oy + p[1] * nh
            r = 15 if big else 9
            d.ellipse([px - r, py - r, px + r, py + r], fill=COLORS.get(name, "#FFF"),
                      outline="#000000", width=3)
            if not grid or name != "centre":
                d.text((px + r + 3, py - r - 1), name, fill="#FFFFFF", font=small,
                       stroke_width=3, stroke_fill="#000000")
    return panel


def _species_sheet(key: str, entry: dict, cell: int, grid: bool,
                   big: bool = False) -> Image.Image:
    front = _view_panel(entry.get("front"), cell, grid, f"{key} {entry['name']} — FACE", big)
    back = _view_panel(entry.get("back"), cell, grid, f"{key} {entry['name']} — DOS"
                       + ("" if big or not entry.get("back")
                          else f" ({os.path.basename(entry['back']['image'])})"), big)
    sheet = Image.new("RGB", (front.width + back.width, max(front.height, back.height)), "#20242B")
    sheet.paste(front, (0, 0))
    sheet.paste(back, (front.width, 0))
    return sheet


def cmd_grilles(args: argparse.Namespace) -> None:
    data = load()
    out = os.path.join(OUT, "grilles")
    os.makedirs(out, exist_ok=True)
    overlay = {}
    if args.points:
        with open(args.points, encoding="utf-8") as f:
            overlay = json.load(f)
    for dex in range(args.de, args.a + 1):
        key = f"{dex:03d}"
        entry = json.loads(json.dumps(data["species"][key]))
        for side, points in (overlay.get(key) or {}).items():
            if entry.get(side) is not None:
                entry[side]["points"].update(points)
        _species_sheet(key, entry, 560, True).save(os.path.join(out, f"{key}.png"))
    print(f"grilles {args.de}–{args.a} dans {rel(out)}")


def cmd_planche(args: argparse.Namespace) -> None:
    data = load()
    out = os.path.join(OUT, "planche")
    os.makedirs(out, exist_ok=True)
    keys = sorted(data["species"])
    per_page, cols = 12, 3
    for page in range(0, len(keys), per_page):
        sheets = [_species_sheet(k, data["species"][k], 300, False)
                  for k in keys[page:page + per_page]]
        w, h = sheets[0].width, max(s.height for s in sheets)
        rows = (len(sheets) + cols - 1) // cols
        legend_h = 50
        board = Image.new("RGB", (w * cols, h * rows + legend_h), "#15181D")
        d = ImageDraw.Draw(board)
        x = 16
        for name in POINTS:
            d.ellipse([x, 16, x + 18, 34], fill=COLORS[name], outline="#000", width=2)
            d.text((x + 24, 14), name, fill="#FFFFFF", font=_font(18))
            x += 24 + 18 * len(name) // 2 + 60
        for i, s in enumerate(sheets):
            board.paste(s, ((i % cols) * w, legend_h + (i // cols) * h))
        name = f"planche_{page // per_page + 1:02d}.png"
        board.save(os.path.join(out, name))
    print(f"{(len(keys) + per_page - 1) // per_page} planches dans {rel(out)}")


def cmd_fusionner(args: argparse.Namespace) -> None:
    data = load()
    count = 0
    for path in args.fichiers:
        with open(path, encoding="utf-8") as f:
            for key, sides in json.load(f).items():
                for side, points in sides.items():
                    view = data["species"][key].get(side)
                    if view is None:
                        continue
                    centre = view["points"].get("centre")
                    view["points"] = {k: points[k] for k in POINTS if k in points}
                    view["points"]["centre"] = centre
                    count += 1
    save(data)
    print(f"{count} vues mises à jour")


## Planche de synthèse (à valider sur téléphone) : les espèces délicates et les cas d'hésitation.
SYNTHESE = [
    (1, "bulbe ; de dos, la tête est cachée par le bulbe"),
    (9, "canons (Hydrocanon) ; dos encore en pixel art"),
    (25, "joues (Éclair) ; de dos, une seule joue visible : pas de joues"),
    (26, "joues ; queue posée au bout de l'éclair"),
    (47, "tête sous le champignon (face et dos)"),
    (51, "trois têtes : celle du haut"),
    (63, "corrigé : tête remontée (elle était sur le visage bas)"),
    (81, "pas de tête distincte : l'œil"),
    (84, "deux têtes : celle de gauche"),
    (85, "trois têtes : celle du milieu"),
    (90, "coquillage : de dos, tête au centre"),
    (100, "boule sans bouche (bouche retirée)"),
    (103, "plusieurs têtes : celle de droite"),
    (108, "corrigé : la langue du dos était notée « queue »"),
    (110, "deux têtes : la grande"),
    (111, "corne = petite corne du nez ; dos : tête invisible"),
    (114, "lianes : tête au centre du visage"),
    (120, "étoile : la gemme ; de dos, le centre"),
    (123, "mains = les lames"),
    (138, "de dos, tête sous la coquille"),
    (142, "de dos, tête au bout du cou (en haut à droite)"),
    (145, "de dos, tête dans les plumes"),
    (150, "de dos, une main près du bord bas"),
    (151, "queue : bout posé en haut de la boucle"),
]


def cmd_synthese(args: argparse.Namespace) -> None:
    data = load()
    os.makedirs(OUT, exist_ok=True)
    blocks = []
    for dex, note in SYNTHESE:
        key = f"{dex:03d}"
        pair = _species_sheet(key, data["species"][key], 440, False, True)
        block = Image.new("RGB", (pair.width, pair.height + 64), "#20242B")
        block.paste(pair, (0, 0))
        ImageDraw.Draw(block).text((40, pair.height + 4), note, fill="#FFD60A", font=_font(34))
        blocks.append(block)
    cols = 1
    w, h = blocks[0].width, max(b.height for b in blocks)
    legend_h = 130
    rows = (len(blocks) + cols - 1) // cols
    board = Image.new("RGB", (w * cols, h * rows + legend_h), "#15181D")
    d = ImageDraw.Draw(board)
    for i, name in enumerate(POINTS):
        x, y = 20 + (i % 5) * 200, 14 + (i // 5) * 56
        d.ellipse([x, y + 4, x + 34, y + 38], fill=COLORS[name], outline="#000", width=2)
        d.text((x + 44, y), name, fill="#FFFFFF", font=_font(34))
    for i, b in enumerate(blocks):
        board.paste(b, ((i % cols) * w, legend_h + (i // cols) * h))
    path = os.path.join(OUT, "synthese.png")
    board.save(path)
    print(f"{len(blocks)} espèces dans {rel(path)} ({board.width} × {board.height})")


def cmd_verifier(args: argparse.Namespace) -> int:
    data = load()
    known = species_ids()
    errors = []
    for dex in range(1, 152):
        key = f"{dex:03d}"
        entry = data["species"].get(key)
        if entry is None:
            errors.append(f"{key} : absente")
            continue
        species_id = (known.get(dex) or EXTRA_IDS.get(dex) or (entry.get("id"), ""))[0]
        for side, expected in (("front", OFFICIAL.format(dex)),
                               ("back", back_image(dex, species_id))):
            view = entry.get(side)
            if not expected:
                if view is not None:
                    errors.append(f"{key} {side} : aucune image en jeu, points à retirer")
                continue
            if view is None:
                errors.append(f"{key} {side} : points absents")
                continue
            if view["image"] != expected:
                errors.append(f"{key} {side} : image changée ({view['image']} → {expected})")
            points = view.get("points", {})
            if "tete" not in points:
                errors.append(f"{key} {side} : point « tete » manquant")
            for name, value in points.items():
                if name not in POINTS:
                    errors.append(f"{key} {side} : point inconnu « {name} »")
                    continue
                pts = value if name in PAIRS else [value]
                if name in PAIRS and len(pts) != 2:
                    errors.append(f"{key} {side} : « {name} » doit avoir deux points")
                for p in pts:
                    if len(p) != 2 or not all(-0.05 <= c <= 1.05 for c in p):
                        errors.append(f"{key} {side} : « {name} » hors de la boîte {p}")
    for e in errors:
        print(e)
    print(f"{len(errors)} erreur(s)")
    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("squelette")
    g = sub.add_parser("grilles")
    g.add_argument("--de", type=int, default=1)
    g.add_argument("--a", type=int, default=151)
    g.add_argument("--points", help="fichier de points à dessiner par-dessus (contrôle)")
    sub.add_parser("planche")
    sub.add_parser("verifier")
    sub.add_parser("synthese")
    f = sub.add_parser("fusionner", help="verse des fichiers de points dans les données")
    f.add_argument("fichiers", nargs="+")
    args = parser.parse_args()
    if args.cmd == "squelette":
        cmd_squelette(args)
    elif args.cmd == "grilles":
        cmd_grilles(args)
    elif args.cmd == "planche":
        cmd_planche(args)
    elif args.cmd == "fusionner":
        cmd_fusionner(args)
    elif args.cmd == "synthese":
        cmd_synthese(args)
    elif args.cmd == "verifier":
        return cmd_verifier(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
