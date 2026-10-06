#!/usr/bin/env python3
"""Planche « avant / après » de la pose d'attente, agrandie × 4, par personnage.

Avant = colonne 0 (« passage ») de la planche de marche ; après = planche d'attente (`<id>_idle`
du catalogue). Ligne du haut : avant (bas, gauche, droite, haut) ; ligne du bas : après. Fond
vert d'herbe, ligne de sol rouge = bas de la cellule (origine aux pieds dans le jeu).
Usage : tools/art/comparer_attente.py DOSSIER_SORTIE [identifiant ...]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
ZOOM = 4
FOND = (96, 128, 84, 255)


def _image(fichier: str) -> Image.Image:
	return Image.open(RACINE / fichier[len("res://"):]).convert("RGBA")


def comparer(identifiant: str, catalogue: dict, sortie: Path) -> Path:
	marche = catalogue[identifiant]
	attente = catalogue[identifiant + "_idle"]
	ml, mh = marche["cellule"]
	al, ah = attente["cellule"]
	planche_m, planche_a = _image(marche["fichier"]), _image(attente["fichier"])
	avant = [planche_m.crop((0, r * mh, ml, (r + 1) * mh)) for r in range(4)]
	apres = [planche_a.crop((c * al, 0, (c + 1) * al, ah)) for c in range(4)]
	largeur = max(ml, al) + 8
	hauteur = max(mh, ah) + 8
	image = Image.new("RGBA", (largeur * 4, hauteur * 2), FOND)
	dessin = ImageDraw.Draw(image)
	for ligne, cellules in enumerate((avant, apres)):
		sol = ligne * hauteur + hauteur - 4
		dessin.line([(0, sol), (image.width, sol)], fill=(200, 40, 40, 255))
		for colonne, cellule in enumerate(cellules):
			x = colonne * largeur + (largeur - cellule.width) // 2
			image.alpha_composite(cellule, (x, sol - cellule.height))
	image = image.resize((image.width * ZOOM, image.height * ZOOM), Image.NEAREST)
	chemin = sortie / f"{identifiant}_avant_apres_x4.png"
	image.save(chemin)
	return chemin


def main() -> None:
	sortie = Path(sys.argv[1])
	sortie.mkdir(parents=True, exist_ok=True)
	catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())["personnages"]
	identifiants = sys.argv[2:] or [k[:-5] for k in catalogue if k.endswith("_idle")]
	for identifiant in identifiants:
		print(comparer(identifiant, catalogue, sortie))


if __name__ == "__main__":
	main()
