#!/usr/bin/env python3
"""Planches de validation du lot DAF.9 « Cramois'Île » (RP-024) : une planche par zone (île, Arène,
Manoir), captures 2340 × 1080 avant / après (`tools/capture_daf9.sh`), kit à l'échelle du jeu,
synthèse pour le téléphone. Mêmes mises en page que `planches_daf3.py` et `planches_daf4.py`.

  tools/capture_daf9.sh build/captures/daf9/avant     (avant le lot, une fois)
  tools/capture_daf9.sh build/captures/daf9/apres
  python3 tools/art/planches_daf9.py

Écrit `docs/design/fiches-assets/daf-9/planche-*.jpg` et `daf-9/synthese-telephone.jpg`.
"""
from __future__ import annotations

from PIL import Image, ImageDraw

import planches_daf3 as p3

p3.AVANT = p3.RACINE / "build/captures/daf9/avant"
p3.APRES = p3.RACINE / "build/captures/daf9/apres"
DAF9 = p3.RACINE / "docs/design/fiches-assets/daf-9"


def main() -> None:
	DAF9.mkdir(parents=True, exist_ok=True)
	p3._ecrire(p3._avant_apres([("ile_vue", "Cramois'Île, vue d'ensemble"), ("ile", "Place, Manoir et Arène"),
		("ile_plage", "Plage de sable noir, Centre et Boutique")],
		"DAF.9 — Cramois'Île : sol volcanique, sable noir, récifs, façades"), DAF9 / "planche-1-ile.jpg")
	p3._ecrire(p3._avant_apres([("arene_vue", "Arène, herses fermées (nouvelle partie)"),
		("arene_ouverte_vue", "Arène, herses ouvertes (6 bonnes réponses)"), ("arene", "Entrée"),
		("arene_auguste", "Salle d'Auguste")],
		"DAF.9 — Arène de Cramois'Île : dalles, murs, machines de quiz, herses"), DAF9 / "planche-2-arene.jpg")
	p3._ecrire(p3._avant_apres([("manoir_1f_vue", "Manoir 1F (interrupteur sur ARRÊT)"),
		("manoir_1f_marche_vue", "Manoir 1F (interrupteur sur MARCHE)"), ("manoir_2f_vue", "Manoir 2F"),
		("manoir_3f_vue", "Manoir 3F (trous)"), ("manoir_b1f_vue", "Manoir B1F (laboratoire)")],
		"DAF.9 — Manoir Pokémon : parquet, murs, mobilier, grilles, statues"), DAF9 / "planche-3-manoir.jpg")
	p3._ecrire(p3._avant_apres([("manoir_1f", "1F, entrée"), ("manoir_1f_statue", "1F, statue"),
		("manoir_2f", "2F"), ("manoir_3f", "3F"), ("manoir_b1f", "B1F")],
		"DAF.9 — Manoir Pokémon à hauteur du joueur"), DAF9 / "planche-4-manoir-joueur.jpg")
	g, r, p, b = "assets/world/ground/", "assets/world/relief/", "assets/world/props/", "assets/world/buildings/"
	p3._ecrire(p3._contact([(f"{g}ground_volcanique_01.png", "sol volcanique (neuf)"),
		(f"{g}ground_sable_noir_01.png", "sable noir (neuf)"), (f"{g}ground_roche_volcanique_01.png", "récifs (neuf)"),
		(f"{b}bldg_manoir_ruine_01.png", "Manoir (neuf)"), (f"{b}bldg_arene_cramois_01.png", "Arène (neuve)"),
		(f"{b}bldg_labo_cramois_01.png", "Labo (neuf)"),
		(f"{g}ground_parquet_manoir_01.png", "parquet"), (f"{g}ground_carrelage_b1_01.png", "carrelage B1F"),
		(f"{g}ground_dalles_arene_01.png", "dalles Arène"), (f"{r}relief_mur_manoir_01.png", "mur Manoir"),
		(f"{r}relief_mur_manoir_b1_01.png", "mur B1F"), (f"{r}relief_mur_arene_01.png", "mur Arène"),
		(f"{p}int_statue_manoir_01.png", "statue"), (f"{p}int_pupitre_carnet_01.png", "journal"),
		(f"{p}int_grille_manoir_fermee_01.png", "grille fermée"), (f"{p}int_grille_manoir_ouverte_01.png", "ouverte"),
		(f"{p}int_trou_plancher_01.png", "trou"), (f"{p}int_machine_quiz_01.png", "machine"),
		(f"{p}int_herse_fermee_01.png", "herse fermée"), (f"{p}int_herse_ouverte_01.png", "ouverte"),
		(f"{p}int_statue_arene_01.png", "statue Arène")],
		"DAF.9 — kit à l'échelle du jeu (1 case = 96 px) : neuf + série 28 (validée le 2026-10-19)", 1.0),
		DAF9 / "planche-5-kit.jpg")
	paires = [("ile_vue", "Cramois'Île"), ("ile", "Cramois'Île, la place"), ("arene_vue", "Arène"),
		("manoir_1f_vue", "Manoir 1F"), ("manoir_3f_vue", "Manoir 3F"), ("manoir_b1f_vue", "Manoir B1F"),
		("manoir_1f", "Manoir 1F, joueur")]
	lw = 1080
	hh = lw * 1080 // 2340
	bloc = 2 * hh + 110
	syn = Image.new("RGB", (lw, 140 + len(paires) * bloc), p3.FOND)
	d = ImageDraw.Draw(syn)
	d.text((24, 30), "DAF.9 Cramois'Île : avant / après", font=p3._police(54), fill=p3.TEXTE)
	y = 140
	for nom, legende in paires:
		d.text((24, y), legende, font=p3._police(40), fill=p3.TEXTE)
		for k, (dossier, mot) in enumerate(((p3.AVANT, "avant"), (p3.APRES, "après"))):
			yy = y + 56 + k * (hh + 4)
			syn.paste(Image.open(dossier / f"{nom}.png").convert("RGB").resize((lw, hh), Image.LANCZOS), (0, yy))
			d.rectangle((0, yy, 150, yy + 46), fill=p3.FOND)
			d.text((12, yy + 4), mot, font=p3._police(34), fill=p3.TEXTE if k else p3.GRIS)
		y += bloc
	p3._ecrire(syn, DAF9 / "synthese-telephone.jpg")


if __name__ == "__main__":
	main()
