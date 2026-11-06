#!/usr/bin/env python3
"""Planche avant / après de la peinture des Ruines d'Alpha : vues du joueur, de jour et de nuit, à
côté des captures d'avant et des vues générales validées. Usage : tools/art/planche_johp1_alpha.py
AVANT APRES SORTIE (dossiers de `tools/capture_johp1.sh` et `tools/capture_johp1_art.sh`)."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
REFERENCE = RACINE / "docs/design/reference"
LARGEUR = 760
HAUTEUR = 351
TITRE = 34
POLICE = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 22)
# Lignes : titre, avant, après, vue validée (capture de `APRES`, ou image de référence).
LIGNES = [
	("Ruines : tente", "ruines_tente", "ruines_tente", "ruins-of-alph-vue-generale-v1.png"),
	("Ruines : temple", "ruines_temple", "ruines_temple", "ruines_nuit_temple"),
	("Tente d'Héloïse", "tente", "tente", "alph-tent-vue-generale-v1.png"),
	("Galerie : entrée", "galerie_entree", "galerie_entree", "alph-gallery-vue-generale-v1.png"),
	("Galerie : dalles", "galerie_dalles", "galerie_dalles", "galerie_porte"),
	("Chambre de la Mémoire", "chambre", "chambre", "alph-chamber-vue-generale-v1.png"),
]


def vignette(chemin: Path) -> Image.Image:
	image = Image.open(chemin).convert("RGB")
	image.thumbnail((LARGEUR, HAUTEUR), Image.LANCZOS)
	cadre = Image.new("RGB", (LARGEUR, HAUTEUR), (16, 17, 22))
	cadre.paste(image, ((LARGEUR - image.width) // 2, (HAUTEUR - image.height) // 2))
	return cadre


def main(avant: Path, apres: Path, sortie: Path) -> None:
	planche = Image.new("RGB", (3 * LARGEUR + 40, len(LIGNES) * (HAUTEUR + TITRE + 10) + 10), (28, 29, 36))
	dessin = ImageDraw.Draw(planche)
	for rang, (titre, a, b, c) in enumerate(LIGNES):
		y = 10 + rang * (HAUTEUR + TITRE + 10)
		troisieme = REFERENCE / c if c.endswith(".png") else apres / f"{c}.png"
		legende = "vue validée" if c.endswith(".png") else "après : nuit" if "nuit" in c else "après : porte fermée"
		for colonne, (chemin, texte) in enumerate([(avant / f"{a}.png", f"{titre} : avant"),
				(apres / f"{b}.png", "après"), (troisieme, legende)]):
			x = 10 + colonne * (LARGEUR + 10)
			dessin.text((x + 4, y + 4), texte, font=POLICE, fill=(235, 235, 240))
			planche.paste(vignette(chemin), (x, y + TITRE))
	planche.save(sortie)


if __name__ == "__main__":
	main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
