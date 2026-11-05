#!/usr/bin/env python3
"""Planche de relecture de l'ambiance de Johto, lot 2 (`docs/design/reference/joh-ambiance-lot2-v1.webp`),
d'après les captures de `tools/capture_joh_ambiance2.sh` (build/captures/joh_lot2).
Usage : tools/art/planche_joh_ambiance2.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
CAPTURES = RACINE / "build/captures/joh_lot2"
SORTIE = RACINE / "docs/design/reference/joh-ambiance-lot2-v1.webp"
COLONNES = 4
LARGEUR = 640
MARGE = 24
FOND = (24, 26, 33)
TEXTE = (235, 236, 240)
POLICE = "/System/Library/Fonts/Supplemental/Arial.ttf"

SECTIONS = [
	("JOH3 — Doublonville", ["doub_jour_tour", "doub_nuit_tour", "doub_jour_magasin",
		"doub_nuit_magasin", "doub_jour_gare", "doub_nuit_gare", "doub_jour_place",
		"doub_nuit_place"]),
	("JOH3 — Routes 37, 36, 35 et Souterrain", ["r37_jour_sud", "r37_nuit_sud", "r36_jour_grille",
		"r36_nuit_pont", "r35_jour_poste", "r35_nuit_poste", "sout_ouest", "sout_chef"]),
	("JOH4 — Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss", ["r34_jour_cloture",
		"r34_nuit_maison", "bois_jour_autel", "bois_nuit_autel", "eco_jour_charbonnerie",
		"eco_nuit_charbonnerie", "eco_jour_puits", "eco_nuit_centre", "eco_jour_fargas", "p1_entree",
		"p1_mare", "p2_mare"]),
	("JOH5 — Tour Radio 1F à 5F", ["t1_hall", "t2_studio", "t3_archives", "t4_regie",
		"t5_studio", "t1_vue", "t2_vue", "t5_vue"]),
	("JOH7 — Routes 40 et 41, Îles Tourbillon", ["r40_jour_banc", "r40_nuit_banc",
		"r41_jour_entree", "r41_nuit_entree", "r41_jour_tourbillons", "w1_entree", "w1_salle",
		"w2_rive", "w2_lac", "w3_corniche"]),
	("Vues d'ensemble (à comparer aux vues générales)", ["doub_vue", "r36_vue", "bois_vue",
		"eco_vue", "r41_vue", "p1_vue", "w2_vue", "w3_vue"]),
]


def main() -> None:
	titre = ImageFont.truetype(POLICE, 34)
	section = ImageFont.truetype(POLICE, 26)
	legende = ImageFont.truetype(POLICE, 17)
	hauteur_case = int(LARGEUR * 1080 / 2340) + 28
	largeur = COLONNES * (LARGEUR + MARGE) + MARGE
	hauteur = 90
	for _, noms in SECTIONS:
		hauteur += 52 + ((len(noms) + COLONNES - 1) // COLONNES) * hauteur_case
	planche = Image.new("RGB", (largeur, hauteur), FOND)
	dessin = ImageDraw.Draw(planche)
	dessin.text((MARGE, 26), "Johto — ambiance peinte, lot 2 : JOH3, JOH4, JOH5, JOH7 (v1, 2026-11-05)",
		fill=TEXTE, font=titre)
	y = 90
	for nom_section, noms in SECTIONS:
		dessin.text((MARGE, y + 12), nom_section, fill=TEXTE, font=section)
		y += 52
		for rang, nom in enumerate(noms):
			x = MARGE + (rang % COLONNES) * (LARGEUR + MARGE)
			y_case = y + (rang // COLONNES) * hauteur_case
			image = Image.open(CAPTURES / f"{nom}.png").convert("RGB")
			image = image.resize((LARGEUR, int(LARGEUR * image.height / image.width)), Image.LANCZOS)
			planche.paste(image, (x, y_case))
			dessin.text((x, y_case + image.height + 3), nom.replace("_", " "), fill=TEXTE, font=legende)
		y += ((len(noms) + COLONNES - 1) // COLONNES) * hauteur_case
	planche.save(SORTIE, quality=86, method=6)
	print(SORTIE, planche.size, SORTIE.stat().st_size)


if __name__ == "__main__":
	main()
