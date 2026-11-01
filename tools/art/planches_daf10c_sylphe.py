#!/usr/bin/env python3
"""Planches de validation (DA-6) du mobilier de Sylphe par étage (`daf10c_sylphe.py`), à partir de
tools/capture_daf10c.sh (build/daf10c_sylphe/avant|apres, 1F compris). Sortie : docs/design/fiches-assets/daf-10c/.

    python3 tools/art/planches_daf10c_sylphe.py
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from planches_daf10d import police  # noqa: E402
import planches_daf10d  # noqa: E402
from daf10c_sylphe import ETAGES, SERVICES  # noqa: E402

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(RACINE, "build", "daf10c_sylphe")
SORTIE = os.path.join(RACINE, "docs", "design", "fiches-assets", "daf-10c")
INT = os.path.join(RACINE, "assets", "world", "interiors")
FOND = (24, 24, 28)
JAUNE = (255, 220, 120)


def kit():
    """Les douze meubles à l'échelle du jeu × 2, par service, avec les étages qui les portent."""
    f, ft = police(24), police(38)
    zoom, col = 2, 300
    out = Image.new("RGB", (40 + col * len(SERVICES), 640), FOND)
    d = ImageDraw.Draw(out)
    d.text((20, 20), "Sylphe SARL — mobilier par service (Codex), échelle du jeu × 2", font=ft, fill=(255, 255, 255))
    for k, service in enumerate(SERVICES):
        x = 20 + k * col
        etages = ", ".join(c.replace("silph_co_", "").upper() for c, s in ETAGES.items() if s == service)
        d.text((x, 80), service, font=f, fill=JAUNE)
        d.text((x, 110), etages, font=f, fill=(200, 200, 210))
        for j, nom in enumerate((f"int_armoire_sylphe_{service}_01", f"int_bureau_sylphe_{service}_01")):
            im = Image.open(os.path.join(INT, nom + ".png")).convert("RGBA")
            im = im.resize((im.width * zoom, im.height * zoom), Image.LANCZOS)
            pied = 470 if j == 0 else 620
            fond = Image.new("RGBA", im.size, FOND + (255,))
            fond.alpha_composite(im)
            out.paste(fond.convert("RGB"), (x + 30, pied - im.height))
    out.save(os.path.join(SORTIE, "planche-8-sylphe-mobilier.jpg"), quality=88)
    print("planche-8-sylphe-mobilier.jpg", out.size)


def main():
    planches_daf10d.B = B
    planches_daf10d.SORTIE = SORTIE
    kit()
    planches_daf10d.planche_avant_apres([("silph_co_1f", "Sylphe 1F (accueil)"),
        ("silph_co_2f", "Sylphe 2F (administration)"), ("silph_co_4f", "Sylphe 4F (recherche)"),
        ("silph_co_6f", "Sylphe 6F (recherche)")], "Sylphe SARL : mobilier par étage (1/2)",
        "planche-9-sylphe-etages.jpg", 640)
    planches_daf10d.planche_avant_apres([("silph_co_7f", "Sylphe 7F (informatique)"),
        ("silph_co_9f", "Sylphe 9F (ingénierie)"), ("silph_co_10f", "Sylphe 10F (direction)"),
        ("silph_co_11f", "Sylphe 11F (direction)")], "Sylphe SARL : mobilier par étage (2/2)",
        "planche-10-sylphe-etages.jpg", 640)


if __name__ == "__main__":
    main()
