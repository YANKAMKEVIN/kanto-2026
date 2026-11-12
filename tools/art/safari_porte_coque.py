#!/usr/bin/env python3
"""Enveloppe de la Porte du Parc Safari : `int_safari_12x10_coque` avec une ouverture au nord.

L'enveloppe commune (Porte et Maison Secrète) n'a pas de sortie au nord : à la Porte, le joueur
traversait un mur pour entrer dans le Parc. Dérivé [D] : le panneau central du mur nord (entre les
deux piliers, cases 5 et 6) devient une ouverture, avec la vue d'extérieur et le cadre du poste de la
Forêt (`int_poste_foret_coque`). Sortie : `int_safari_porte_coque.png`.

    python3 tools/art/safari_porte_coque.py
"""
from pathlib import Path

from PIL import Image

DIR = Path(__file__).resolve().parents[2] / "assets/world/interiors"
PANEL = (462, 45, 691, 203)  # panneau entre les piliers, jusqu'au parquet
VIEW_SRC = (401, 47, 559, 157)  # vue d'extérieur du poste de la Forêt
SILL_SRC = (401, 157, 559, 165)  # son seuil
FRAME_SRC = (392, 100)  # un pixel de son cadre de bois
FRAME = 10
SILL = 7


def main() -> None:
    shell = Image.open(DIR / "int_safari_12x10_coque.png").convert("RGBA")
    forest = Image.open(DIR / "int_poste_foret_coque.png").convert("RGBA")
    x0, y0, x1, y1 = PANEL
    shell.paste(forest.getpixel(FRAME_SRC), PANEL)
    inner = (x0 + FRAME, y0 + FRAME, x1 - FRAME, y1 - SILL)
    size = (inner[2] - inner[0], inner[3] - inner[1])
    shell.paste(forest.crop(VIEW_SRC).resize(size, Image.LANCZOS), inner[:2])
    sill = forest.crop(SILL_SRC).resize((size[0], SILL), Image.LANCZOS)
    shell.paste(sill, (inner[0], inner[3]))
    shell.save(DIR / "int_safari_porte_coque.png")


if __name__ == "__main__":
    main()
