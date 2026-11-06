#!/usr/bin/env python3
"""Planche avant / après de la peinture d'Ébènelle (`docs/design/reference/ebenelle-peinture-v1.webp`),
d'après `tools/capture_ebenelle.sh` (avant : build/captures/ebenelle_avant ; après : build/captures/ebenelle).
Usage : tools/art/planche_ebenelle.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
AVANT = RACINE / "build/captures/ebenelle_avant"
APRES = RACINE / "build/captures/ebenelle"
SORTIE = RACINE / "docs/design/reference/ebenelle-peinture-v1.webp"
LARGEUR = 760
MARGE = 20
FOND = (24, 26, 33)
TEXTE = (235, 236, 240)
POLICE = "/System/Library/Fonts/Supplemental/Arial.ttf"
PLANS = [("Vue d'ensemble", "vue"), ("Rue, jour", "jour_rue"), ("Maison de l'Aïeule, jour", "jour_aieule"),
	("Maison de l'Aïeule, nuit", "nuit_aieule"), ("Porche de l'Antre, jour", "jour_antre"),
	("Porche de l'Antre, nuit", "nuit_antre"), ("Aire d'atterrissage, nuit", "nuit_aire"),
	("Intérieur de l'Aïeule", "int_aieule"), ("Maison", "int_maison")]


def main() -> None:
	hauteur = LARGEUR * 1080 // 2340
	police = ImageFont.truetype(POLICE, 24)
	ligne = hauteur + 44
	planche = Image.new("RGB", (2 * LARGEUR + 3 * MARGE, 50 + ligne * len(PLANS)), FOND)
	dessin = ImageDraw.Draw(planche)
	dessin.text((MARGE, 12), "Avant", font=police, fill=TEXTE)
	dessin.text((2 * MARGE + LARGEUR, 12), "Après", font=police, fill=TEXTE)
	for i, (titre, nom) in enumerate(PLANS):
		y = 50 + i * ligne
		dessin.text((MARGE, y), titre, font=police, fill=TEXTE)
		for j, dossier in enumerate((AVANT, APRES)):
			image = Image.open(dossier / f"{nom}.png").convert("RGB").resize((LARGEUR, hauteur), Image.LANCZOS)
			planche.paste(image, (MARGE + j * (LARGEUR + MARGE), y + 34))
	planche.save(SORTIE, quality=86)
	print(SORTIE)


if __name__ == "__main__":
	main()
