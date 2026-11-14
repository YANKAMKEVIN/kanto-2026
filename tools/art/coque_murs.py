#!/usr/bin/env python3
"""Murs latéraux des coques peintes d'arènes recalés sur le plan (audit du 2026-11-14 ; Kevin :
« repeins les arènes »). La coque peignait des murs latéraux plus fins que les deux colonnes
bloquées du plan : une colonne de « sol » peint était un mur invisible. Chaque bande de mur
(bord gauche et bord droit, toute la hauteur) glisse vers l'intérieur de SHIFT px ; le vide
laissé côté extérieur prend la couleur de fond de la coque. Le milieu de l'image ne bouge pas.

Repart toujours de la coque d'origine (commit SOURCE), donc relançable sans cumuler.

  python3 tools/art/coque_murs.py
"""
import io
import os
import subprocess

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = "a85e8fc31"
INTERIORS = "assets/world/interiors/"
# image : (décalage gauche, décalage droite, largeur de la bande de mur), en px.
COQUES = {
    "int_arene_coque.png": (96, 96, 150),           # Argenta : mur x 0..1 et 13..14
    "int_arene_azuria_coque.png": (96, 96, 160),    # Azuria : x 0..1 et 15..16
    "int_arene_carmin_coque.png": (56, 56, 150),    # Carmin : x 0..1 et 15..16
}


def original(name: str) -> Image.Image:
    data = subprocess.run(["git", "show", f"{SOURCE}:{INTERIORS}{name}"], cwd=ROOT,
                          check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(data)).convert("RGBA")


def main() -> None:
    for name, (left, right, strip) in COQUES.items():
        src = original(name)
        w, h = src.size
        bg = src.getpixel((2, h - 2))
        out = src.copy()
        if left:
            out.paste(Image.new("RGBA", (left, h), bg), (0, 0))
            out.paste(src.crop((0, 0, strip, h)), (left, 0))
        if right:
            out.paste(Image.new("RGBA", (right, h), bg), (w - right, 0))
            out.paste(src.crop((w - strip, 0, w, h)), (w - strip - right, 0))
        out.save(os.path.join(ROOT, INTERIORS, name))
        print(f"{name} : murs recalés ({left} px à gauche, {right} px à droite)")


if __name__ == "__main__":
    main()
