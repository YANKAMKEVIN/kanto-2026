#!/usr/bin/env python3
"""Planches de validation du lot DAF.10b « Routes 13 à 21 » (RP-272 postes, RP-273, RP-274, RP-281,
RP-282) : captures 2340 × 1080 avant / après (`tools/capture_daf10b.sh`), images neuves à l'échelle
du jeu, synthèse pour le téléphone. Mêmes mises en page que `planches_daf9.py`.

  tools/capture_daf10b.sh build/captures/daf10b_avant     (avant le lot, une fois)
  tools/capture_daf10b.sh build/captures/daf10b
  tools/capture_t2_audit.sh build/captures/daf10b_raccords "^route_(4|22|24)$"
  python3 tools/art/planches_daf10b.py

Avant des raccords : les captures de l'audit T2 (`fiches-assets/t2-audit/route_4|22|24.jpg`).
Écrit `docs/design/fiches-assets/daf-10b/planche-*.jpg` et `daf-10b/synthese-telephone.jpg`.
"""
from __future__ import annotations

import shutil

from PIL import Image, ImageDraw

import planches_daf3 as p3

p3.AVANT = p3.RACINE / "build/captures/daf10b_avant"
p3.APRES = p3.RACINE / "build/captures/daf10b"
SORTIE = p3.RACINE / "docs/design/fiches-assets/daf-10b"
AUDIT = p3.RACINE / "docs/design/fiches-assets/t2-audit"
RACCORDS = p3.RACINE / "build/captures/daf10b_raccords"


def _raccords() -> None:
	"""Copie les avant (audit T2) et après (`capture_t2_audit.sh`) des raccords sous les noms de la planche."""
	for carte in ("route_4", "route_22", "route_24"):
		Image.open(AUDIT / f"{carte}.jpg").convert("RGB").resize((2340, 1080)).save(p3.AVANT / f"{carte}_raccord.png")
		shutil.copyfile(RACCORDS / f"{carte}.png", p3.APRES / f"{carte}_raccord.png")


def main() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	_raccords()
	p3._ecrire(p3._avant_apres([("route_12_south_vue", "Route 12 sud"), ("route_13_vue", "Route 13"),
		("route_14_vue", "Route 14"), ("route_15_vue", "Route 15 (poste traversant)"),
		("route_16_west_vue", "Route 16 ouest (poste, maison)"), ("route_17_vue", "Route 17, Piste Cyclable"),
		("route_18_vue", "Route 18 (poste traversant)")],
		"DAF.10b — Routes 12 sud à 18 : forêt serrée, herbe, chemins, Piste, clôtures, façades"),
		SORTIE / "planche-1-routes.jpg")
	p3._ecrire(p3._avant_apres([("route_12_south", "Route 12 sud, ponton et maison du pêcheur"),
		("route_13", "Route 13, pré est"), ("route_13_ouest", "Route 13, labyrinthe de clôtures"),
		("route_14", "Route 14"), ("route_15", "Route 15, porte du poste"),
		("route_16_west", "Route 16 ouest"), ("route_17", "Route 17, Piste"), ("route_18", "Route 18, porte du poste")],
		"DAF.10b — routes à hauteur du joueur"), SORTIE / "planche-2-routes-joueur.jpg")
	p3._ecrire(p3._avant_apres([("route_19_vue", "Route 19"), ("route_20_vue", "Route 20 (Îles Écume)"),
		("route_21_vue", "Route 21"), ("route_19", "Route 19, plage et rebords"),
		("route_20", "Route 20, entrée des Îles Écume"), ("route_21", "Route 21, côte de Bourg Palette")],
		"DAF.10b — mer des Routes 19 à 21 : mer de Bourg Palette, rivage rocheux, sable"),
		SORTIE / "planche-3-mer.jpg")
	p3._ecrire(p3._avant_apres([("poste_15", "Poste de la Route 15, 1F"), ("poste_15_2f", "Poste de la Route 15, 2F"),
		("poste_16", "Poste de la Route 16"), ("poste_18", "Poste de la Route 18")],
		"DAF.10b — postes des routes (RP-272, hors pavillons du Parc Safari)"), SORTIE / "planche-4-postes.jpg")
	p3._ecrire(p3._avant_apres([("route_4_raccord", "Route 4 : coin nord-est (RP-282)"),
		("route_22_raccord", "Route 22 : haut du fond peint fondu (RP-281)"),
		("route_24_raccord", "Route 24 : coin sud-ouest (RP-282)")],
		"DAF.10b — raccords"), SORTIE / "planche-5-raccords.jpg")
	g, b, i = "assets/world/ground/", "assets/world/buildings/", "assets/world/interiors/"
	p3._ecrire(p3._contact([(f"{b}bldg_poste_traversant_01.png", "façade du poste traversant [D]"),
		(f"{i}int_poste_traversant_coque.png", "poste 1F (15, 18) [D]"), (f"{i}int_poste_etage_coque.png", "poste 2F (15) [D]"),
		(f"{i}int_poste_16_coque.png", "poste 16 [D]"), (f"{g}ground_dalles_souterrain_01.png", "Piste : dalles [D]")],
		"DAF.10b — images dérivées du kit peint (sans Codex) à l'échelle du jeu × 0,5", 0.5),
		SORTIE / "planche-6-images.jpg")
	paires = [("route_13_vue", "Route 13"), ("route_15_vue", "Route 15"), ("route_17", "Route 17, Piste"),
		("route_18_vue", "Route 18"), ("route_19", "Route 19"), ("route_20_vue", "Route 20"),
		("poste_15", "Poste de la Route 15"), ("poste_16", "Poste de la Route 16")]
	lw = 1080
	hh = lw * 1080 // 2340
	bloc = 2 * hh + 110
	syn = Image.new("RGB", (lw, 140 + len(paires) * bloc), p3.FOND)
	d = ImageDraw.Draw(syn)
	d.text((24, 30), "DAF.10b Routes 13 à 21 : avant / après", font=p3._police(54), fill=p3.TEXTE)
	y = 140
	for nom, legende in paires:
		d.text((24, y), legende, font=p3._police(40), fill=p3.TEXTE)
		for k, (dossier, mot) in enumerate(((p3.AVANT, "avant"), (p3.APRES, "après"))):
			yy = y + 56 + k * (hh + 4)
			syn.paste(Image.open(dossier / f"{nom}.png").convert("RGB").resize((lw, hh), Image.LANCZOS), (0, yy))
			d.rectangle((0, yy, 150, yy + 46), fill=p3.FOND)
			d.text((12, yy + 4), mot, font=p3._police(34), fill=p3.TEXTE if k else p3.GRIS)
		y += bloc
	p3._ecrire(syn, SORTIE / "synthese-telephone.jpg")


if __name__ == "__main__":
	main()
