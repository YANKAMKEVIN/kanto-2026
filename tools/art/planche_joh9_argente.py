#!/usr/bin/env python3
"""Planche avant / après de la peinture du Mont Argenté et de la Route 28 : vues du joueur, de jour et de
nuit, à côté des captures d'avant et des vues générales validées. Usage :
tools/art/planche_joh9_argente.py AVANT APRES SORTIE (dossiers de `tools/capture_joh9.sh` et
`tools/capture_joh9_art.sh`)."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
REFERENCE = RACINE / "docs/design/reference"
LARGEUR = 640
HAUTEUR = 296
TITRE = 30
POLICE = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 20)
# Lignes : titre, avant, après, nuit ou vue d'ensemble (capture de `APRES`), vue validée.
LIGNES = [
	("Sentier", "sentier_centre", "sentier_centre", "nuit_sentier", "sentier-mont-argente-vue-generale-v1.png"),
	("Sentier : muraille", "sentier_hugo", "sentier_hugo", "nuit_sentier_sud", None),
	("Extérieur", "exterieur_esplanade", "exterieur_esplanade", "nuit_exterieur", "mont-argente-exterieur-vue-generale-v1.png"),
	("Grotte 1F", "grotte_1f_lac", "grotte_1f_lac", "vue_1f", "mont-argente-1f-vue-generale-v1.png"),
	("Grotte 2F", "grotte_2f_flash", "grotte_2f_flash", "vue_2f", "mont-argente-2f-vue-generale-v1.png"),
	("Grotte 3F", None, "grotte_3f", "vue_3f", "mont-argente-3f-vue-generale-v1.png"),
	("Sommet", "sommet_arrivee", "sommet_centre", "nuit_sommet", "mont-argente-sommet-vue-generale-v1.png"),
	("Route 28", "route_28_est", "route_28_maison", "nuit_route_28", "route-28-vue-generale-v1.png"),
	("Poste de la Route 28", "poste_kanto", "poste", "vue_route_28", "poste-route-28-v1.png"),
]


def vignette(chemin: Path | None) -> Image.Image:
	cadre = Image.new("RGB", (LARGEUR, HAUTEUR), (16, 17, 22))
	if chemin is None or not chemin.exists():
		return cadre
	image = Image.open(chemin).convert("RGB")
	image.thumbnail((LARGEUR, HAUTEUR), Image.LANCZOS)
	cadre.paste(image, ((LARGEUR - image.width) // 2, (HAUTEUR - image.height) // 2))
	return cadre


def main(avant: Path, apres: Path, sortie: Path) -> None:
	planche = Image.new("RGB", (4 * LARGEUR + 50, len(LIGNES) * (HAUTEUR + TITRE + 10) + 10), (28, 29, 36))
	dessin = ImageDraw.Draw(planche)
	for rang, (titre, a, b, c, d) in enumerate(LIGNES):
		y = 10 + rang * (HAUTEUR + TITRE + 10)
		cases = [(avant / f"{a}.png" if a else None, f"{titre} : avant"), (apres / f"{b}.png", "après"),
			(apres / f"{c}.png", "après : nuit" if "nuit" in c else "après : ensemble"),
			(REFERENCE / d if d else None, "vue validée" if d else "")]
		for colonne, (chemin, texte) in enumerate(cases):
			x = 10 + colonne * (LARGEUR + 10)
			dessin.text((x + 4, y + 4), texte, font=POLICE, fill=(235, 235, 240))
			planche.paste(vignette(chemin), (x, y + TITRE))
	planche.save(sortie)


if __name__ == "__main__":
	main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
