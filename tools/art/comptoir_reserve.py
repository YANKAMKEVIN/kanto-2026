#!/usr/bin/env python3
"""Dérive `int_comptoir_reserve_01` de `int_long_comptoir_01` : même comptoir sans l'écran.

Le scientifique de la réserve du Musée (5, 4) se tient juste derrière le centre du comptoir, là où
l'écran le cacherait. On efface l'écran et son pied, puis on prolonge le plateau avec, rangée par
rangée, la moyenne des colonnes propres à sa droite (le fil du bois est horizontal).

Usage : python3 tools/art/comptoir_reserve.py   puis  godot --headless --path . --import
"""
from pathlib import Path

from PIL import Image

DOSSIER = Path("assets/world/interiors")
SOURCE = "int_long_comptoir_01"
CIBLE = "int_comptoir_reserve_01"
X_DEBUT, X_FIN = 202, 292  # bande de l'écran
Y_BORD, Y_FIN = 54, 104  # bord arrière du plateau ; bord avant, ombre du pied comprise
X_PROPRE, LARGEUR_PROPRE = 285, 7  # colonnes de plateau sans objet
FONDU = 6


def main() -> None:
	image = Image.open(DOSSIER / f"{SOURCE}.png").convert("RGBA")
	source = image.copy()
	moyennes = {}
	for y in range(Y_BORD, Y_FIN):
		colonnes = [source.getpixel((X_PROPRE + i, y)) for i in range(LARGEUR_PROPRE)]
		moyennes[y] = tuple(sum(canal) / LARGEUR_PROPRE for canal in zip(*colonnes))
	for x in range(X_DEBUT, X_FIN):
		for y in range(0, Y_BORD):
			image.putpixel((x, y), (0, 0, 0, 0))
		poids = min(1.0, (x - X_DEBUT + 1) / FONDU, (X_FIN - x) / FONDU)
		for y in range(Y_BORD, Y_FIN):
			ancien = source.getpixel((x, y))
			image.putpixel((x, y), tuple(round(a + (b - a) * poids) for a, b in zip(ancien, moyennes[y])))
	image.save(DOSSIER / f"{CIBLE}.png")


if __name__ == "__main__":
	main()
