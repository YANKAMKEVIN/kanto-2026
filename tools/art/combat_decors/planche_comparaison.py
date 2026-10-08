#!/usr/bin/env python3
"""Planche côte à côte : la cible combat-v1 | le jeu (CB.3), même hauteur.

  python3 tools/art/combat_decors/planche_comparaison.py build/captures/combat_cb3
Écrit cb3_comparaison_combat_v1.png (cible | Roucool sur la Route 1) dans le dossier donné.
"""
import os
import sys

from PIL import Image

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
CIBLE = os.path.join(RACINE, "docs", "design", "reference", "combat-v1.webp")


def main():
    dossier = sys.argv[1]
    jeu = Image.open(os.path.join(dossier, "cb3_route_1_roucool.png")).convert("RGB")
    cible = Image.open(CIBLE).convert("RGB")
    h = 1080
    cible = cible.resize((round(cible.size[0] * h / cible.size[1]), h), Image.LANCZOS)
    jeu = jeu.resize((round(jeu.size[0] * h / jeu.size[1]), h), Image.LANCZOS)
    marge = 24
    planche = Image.new("RGB", (cible.size[0] + marge + jeu.size[0], h), (20, 20, 24))
    planche.paste(cible, (0, 0))
    planche.paste(jeu, (cible.size[0] + marge, 0))
    sortie = os.path.join(dossier, "cb3_comparaison_combat_v1.png")
    planche.save(sortie)
    print("CAPTURE %s" % sortie)


if __name__ == "__main__":
    main()
