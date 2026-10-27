#!/usr/bin/env python3
"""Planches de validation du lot DAF.4, suite (Route Victoire, Grotte Azurée, façades du J29, fonds de
combat) : captures 2340 × 1080 avant / après (`tools/capture_daf4.sh`), modules à l'échelle du jeu.
Mêmes mises en page que `planches_daf3.py`.

  tools/capture_daf4.sh build/captures/daf4/avant     (avant le lot, une fois)
  tools/capture_daf4.sh build/captures/daf4/apres
  python3 tools/art/planches_daf4.py

Écrit `docs/design/fiches-assets/daf-4/planche-2-*.jpg` à `planche-6-*.jpg` et
`daf-4/synthese-telephone.jpg`.
"""
from __future__ import annotations

from PIL import Image, ImageDraw

import planches_daf3 as p3

p3.AVANT = p3.RACINE / "build/captures/daf4/avant"
p3.APRES = p3.RACINE / "build/captures/daf4/apres"
DAF4 = p3.DAF4


def main() -> None:
	p3._ecrire(p3._avant_apres([("victoire_1f", "Route Victoire 1F"), ("victoire_2f", "Route Victoire 2F"),
		("victoire_3f", "Route Victoire 3F (interrupteur, barrière, trou)")],
		"DAF.4 — Route Victoire : sol haut / sol bas, rebords, escaliers, interrupteurs"),
		DAF4 / "planche-2-route-victoire.jpg")
	p3._ecrire(p3._avant_apres([("azuree_1f", "Grotte Azurée 1F"), ("azuree_2f", "Grotte Azurée 2F"),
		("azuree_b1f", "Grotte Azurée B1F (Mewtwo)")], "DAF.4 — Grotte Azurée : niveaux, eau, échelles"),
		DAF4 / "planche-3-grotte-azuree.jpg")
	p3._ecrire(p3._avant_apres([("route_22_ouest", "Route 22 ouest : poste de la Ligue"),
		("plateau_indigo", "Plateau Indigo : bâtiment de la Ligue (sol encore provisoire)"),
		("route_23_milieu", "Route 23 (sol encore provisoire, inchangée)")],
		"DAF.4 — façades du J29"), DAF4 / "planche-4-facades-j29.jpg")
	g, r, i, b = "assets/world/ground/", "assets/world/relief/", "assets/world/interiors/", "assets/world/buildings/"
	p3._ecrire(p3._contact([(f"{g}ground_victoire_bas_01.png", "victoire bas"),
		(f"{g}ground_victoire_haut_01.png", "victoire haut"), (f"{g}ground_azuree_bas_01.png", "azurée bas"),
		(f"{g}ground_azuree_haut_01.png", "azurée haut"), (f"{r}relief_rebord_victoire_01.png", "rebord"),
		(f"{r}relief_rebord_victoire_cote_01.png", "côté"), (f"{r}relief_escalier_victoire_01.png", "escalier"),
		(f"{i}decal_interrupteur_victoire_01.png", "interrupteur"),
		(f"{i}decal_interrupteur_victoire_enfonce_01.png", "enfoncé"),
		("assets/world/props/prop_barriere_victoire_01.png", "barrière"),
		(f"{i}decal_trou_victoire_01.png", "trou"), (f"{i}decal_trou_victoire_bouche_01.png", "bouché"),
		(f"{r}relief_rebord_azuree_01.png", "rebord azurée"), (f"{r}relief_escalier_azuree_01.png", "escalier azurée"),
		(f"{b}bldg_poste_route_22_01.png", "poste Route 22"), (f"{b}bldg_ligue_01.png", "Ligue")],
		"DAF.4 — kit à l'échelle du jeu (1 case = 96 px)", 1.0), DAF4 / "planche-5-kit.jpg")
	fonds = [("route_23_roche", "Route 23"), ("victory_road_grotte", "Route Victoire"),
		("cerulean_cave_azuree", "Grotte Azurée")]
	l, h = 1170, 540
	planche = Image.new("RGB", (2 * l + 30, 90 + 2 * (h + 56)), p3.FOND)
	d = ImageDraw.Draw(planche)
	d.text((16, 20), "DAF.4 — fonds de combat dédiés (remplacent les décors [D])", font=p3._police(44),
		fill=p3.TEXTE)
	for k, (ident, legende) in enumerate(fonds):
		x, y = (k % 2) * (l + 30), 90 + (k // 2) * (h + 56)
		d.text((x + 8, y + 8), legende, font=p3._police(28), fill=p3.TEXTE)
		planche.paste(Image.open(p3.RACINE / f"assets/battle/decors/{ident}_back.webp").convert("RGB").resize(
			(l, h), Image.LANCZOS), (x, y + 48))
	p3._ecrire(planche, DAF4 / "planche-6-fonds-combat.jpg")
	paires = [("victoire_2f", "Route Victoire 2F"), ("victoire_3f", "Route Victoire 3F"),
		("azuree_1f", "Grotte Azurée 1F"), ("azuree_b1f", "Grotte Azurée B1F"),
		("route_22_ouest", "Poste de la Route 22"), ("plateau_indigo", "Plateau Indigo")]
	lw = 1080
	hh = lw * 1080 // 2340
	bloc = 2 * hh + 110
	syn = Image.new("RGB", (lw, 140 + len(paires) * bloc), p3.FOND)
	d = ImageDraw.Draw(syn)
	d.text((24, 30), "DAF.4 (suite) : avant / après", font=p3._police(54), fill=p3.TEXTE)
	y = 140
	for nom, legende in paires:
		d.text((24, y), legende, font=p3._police(40), fill=p3.TEXTE)
		for k, (dossier, mot) in enumerate(((p3.AVANT, "avant"), (p3.APRES, "après"))):
			yy = y + 56 + k * (hh + 4)
			syn.paste(Image.open(dossier / f"{nom}.png").convert("RGB").resize((lw, hh), Image.LANCZOS), (0, yy))
			d.rectangle((0, yy, 150, yy + 46), fill=p3.FOND)
			d.text((12, yy + 4), mot, font=p3._police(34), fill=p3.TEXTE if k else p3.GRIS)
		y += bloc
	p3._ecrire(syn, DAF4 / "synthese-telephone.jpg")


if __name__ == "__main__":
	main()
