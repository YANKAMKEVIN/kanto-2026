#!/usr/bin/env python3
"""Barrière de l'Arène de Carmin élargie (audit du 2026-11-14 ; Kevin : « repeins les
arènes »). Les pylônes tombaient sur les cases `B` (7 et 9), praticables une fois la barrière
ouverte : on traversait les pylônes. Le plan les veut sur les machines voisines (6 et 10). Les
deux pylônes gardent leur dessin ; seul le champ (ou la barre éteinte) entre eux est étiré de
WIDEN px, et l'image reste centrée sur la case du milieu (8, 5).

Écrit les deux images de la barrière, leurs ombres de contact et la copie `electric_barrier.png`
des objets fixes (tailles au catalogue) ; relancer ensuite `tools/build_character_frames.gd`. Repart des images
d'origine (commit SOURCE), donc relançable.

  python3 tools/art/barriere_carmin.py
"""
import io
import json
import os
import subprocess

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = "a85e8fc31"
IMAGES = ["assets/world/interiors/int_barriere_active_01.png",
          "assets/world/interiors/int_barriere_coupee_01.png"]
PYLON = 68
WIDEN = 96


def original(path: str) -> Image.Image:
    data = subprocess.run(["git", "show", f"{SOURCE}:{path}"], cwd=ROOT, check=True,
                          capture_output=True).stdout
    return Image.open(io.BytesIO(data)).convert("RGBA")


def widen(src: Image.Image) -> Image.Image:
    w, h = src.size
    out = Image.new("RGBA", (w + WIDEN, h), (0, 0, 0, 0))
    middle = src.crop((PYLON, 0, w - PYLON, h)).resize((w - 2 * PYLON + WIDEN, h), Image.LANCZOS)
    out.paste(middle, (PYLON, 0))
    out.paste(src.crop((0, 0, PYLON, h)), (0, 0))
    out.paste(src.crop((w - PYLON, 0, w, h)), (w - PYLON + WIDEN, 0))
    return out


def main() -> None:
    for path in IMAGES:
        img = widen(original(path))
        img.save(os.path.join(ROOT, path), optimize=True)
        print(f"{path} : {img.width} × {img.height}")
    active = Image.open(os.path.join(ROOT, IMAGES[0]))
    dest = "assets/sprites/objects/painted/electric_barrier.png"
    active.save(os.path.join(ROOT, dest), optimize=True)
    cat_path = os.path.join(ROOT, "assets/world/catalogue.json")
    cat = json.load(open(cat_path, encoding="utf-8"))
    cat["images"]["electric_barrier"]["taille"] = list(active.size)
    for path in IMAGES:
        key = os.path.basename(path)[:-4]
        entry = cat["objets"][key]
        entry["taille"] = list(Image.open(os.path.join(ROOT, path)).size)
        # Ombre de contact (moitié de la taille) : élargie d'autant que l'image.
        contact = entry["contact"]
        cpath = contact["fichier"].replace("res://", "")
        shadow = original(cpath)
        shadow = shadow.resize((shadow.width + WIDEN // contact["echelle"], shadow.height),
                               Image.LANCZOS)
        shadow.save(os.path.join(ROOT, cpath), optimize=True)
        contact["taille"] = list(shadow.size)
        contact["decalage"] = [-shadow.width, contact["decalage"][1]]
    with open(cat_path, "w", encoding="utf-8") as f:
        f.write(json.dumps(cat, ensure_ascii=False, indent=1) + "\n")
    print(f"{dest} : {active.width} × {active.height}")


if __name__ == "__main__":
    main()
