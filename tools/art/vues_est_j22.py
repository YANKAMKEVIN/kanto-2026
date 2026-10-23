#!/usr/bin/env python3
"""Vues générales du chemin est du jalon 22 (T9) : plans pour Codex et planche de relecture.

`--plans`   : plans en aplats SANS annotation (ni Dresseur, ni objet, ni étiquette), destinés à être
              joints à Codex : build/art/PLAN_<ZONE>_codex.png (Route 12 sud, Routes 13, 14, 15,
              poste 15). Les marges sont de la forêt (routes) ou du noir (poste).
`--planche` : docs/design/reference/j22-vues-est-v1.png, chaque vue peinte à côté de son plan annoté
              (docs/design/reference/plans-j22/*-plan-v1.png, qui fait foi).

Usage : python3 tools/art/vues_est_j22.py --plans | --planche
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
ART = RACINE / "build" / "art"
REF = RACINE / "docs" / "design" / "reference"

PORTRAIT, PAYSAGE = (1024, 1536), (1536, 1024)
# zone : (grille, format, vue peinte, plan annoté)
ZONES = {
	"ROUTE12_SUD": ("route_12_sud", PORTRAIT, "route-12-sud-vue-generale-v1.png", "route-12-sud-plan-v1.png"),
	"ROUTE13": ("route_13", PAYSAGE, "route-13-vue-generale-v1.png", "route-13-plan-v1.png"),
	"ROUTE14": ("route_14", PORTRAIT, "route-14-vue-generale-v1.png", "route-14-plan-v1.png"),
	"ROUTE15": ("route_15", PAYSAGE, "route-15-vue-generale-v1.png", "route-15-plan-v1.png"),
	"POSTE15": ("route_15_gate", PAYSAGE, "poste-15-v1.png", "route-15-gate-plan-v1.png"),
}

FORET, FORET_BORD = (27, 87, 45), (20, 66, 34)
COULEURS = {
	"T": FORET, ".": (86, 152, 62), "=": (224, 196, 140), "h": (150, 170, 40), "q": (150, 106, 66),
	"w": (56, 104, 168), "f": (64, 122, 186), "R": (138, 130, 120), "c": (86, 152, 62), "x": (86, 152, 62),
	"m": (86, 152, 62), "P": (86, 152, 62), "D": (224, 196, 140),
	# poste (intérieur)
	"K": (78, 70, 64), "V": (10, 10, 12), "B": (200, 186, 150), "N": (200, 186, 150), "J": (200, 186, 150),
	"U": (200, 186, 150), "X": (200, 186, 150),
}
SOL_POSTE = (200, 186, 150)
OCRE = (196, 140, 50)


def _geometrie(largeur: int, hauteur: int, taille: tuple[int, int]) -> tuple[int, int, int]:
	case = min(taille[0] // largeur, taille[1] // hauteur)
	return case, (taille[0] - case * largeur) // 2, (taille[1] - case * hauteur) // 2


def _boite(d, cases, coin, case, **kw) -> tuple[int, int, int, int]:
	xs = [x for x, _ in cases]
	ys = [y for _, y in cases]
	x0, y0 = coin(min(xs), min(ys))
	x1, y1 = coin(max(xs) + 1, max(ys) + 1)
	if kw:
		d.rectangle([x0, y0, x1 - 1, y1 - 1], **kw)
	return x0, y0, x1, y1


def plan_codex(zone: str) -> Path:
	grille, taille, _, _ = ZONES[zone]
	plan = lire(RACINE / "tools" / "plans" / f"{grille}.txt")
	interieur = grille == "route_15_gate"
	img = Image.new("RGB", taille, (10, 10, 12) if interieur else FORET)
	d = ImageDraw.Draw(img)
	case, ox, oy = _geometrie(plan.width, plan.height, taille)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	for y in range(plan.height):
		for x in range(plan.width):
			c = plan.at(x, y)
			x0, y0 = coin(x, y)
			couleur = SOL_POSTE if interieur and c == "." else COULEURS.get(c, FORET)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleur)
	if not interieur:                                   # bord de la forêt, pour lire les contours
		for y in range(plan.height):
			for x in range(plan.width):
				if plan.at(x, y) == "T" and any(0 <= x + dx < plan.width and 0 <= y + dy < plan.height
						and plan.at(x + dx, y + dy) != "T" for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
					x0, y0 = coin(x, y)
					d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=FORET_BORD)
		for x, y in plan.cells_of("q"):                 # planches du ponton
			x0, y0 = coin(x, y)
			for k in range(0, case, max(3, case // 4)):
				d.line([x0, y0 + k, x0 + case - 1, y0 + k], fill=(120, 82, 50), width=1)
		for x, y in plan.cells_of("w") + plan.cells_of("f"):
			if (x + 2 * y) % 5 == 0:
				x0, y0 = coin(x, y)
				d.line([x0 + 3, y0 + case // 2, x0 + case - 4, y0 + case // 2], fill=(100, 150, 210), width=1)
		for x, y in plan.cells_of("R"):                 # rive rocheuse
			x0, y0 = coin(x, y)
			d.ellipse([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=(176, 170, 160))
		for x, y in plan.cells_of("x"):                 # buissons
			x0, y0 = coin(x, y)
			d.ellipse([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=(40, 110, 50), outline=FORET_BORD)
		for x, y in plan.cells_of("c"):                 # clôture blanche : lisse et poteaux
			x0, y0 = coin(x, y)
			gauche = plan.at(x - 1, y) == "c" if x > 0 else False
			droite = plan.at(x + 1, y) == "c" if x < plan.width - 1 else False
			haut = plan.at(x, y - 1) == "c" if y > 0 else False
			bas = plan.at(x, y + 1) == "c" if y < plan.height - 1 else False
			m, e = case // 2, max(2, case // 6)
			if gauche or droite or not (haut or bas):
				d.rectangle([x0, y0 + m - e // 2, x0 + case - 1, y0 + m + e // 2], fill=(244, 242, 232))
			if haut or bas:
				d.rectangle([x0 + m - e // 2, y0, x0 + m + e // 2, y0 + case - 1], fill=(244, 242, 232))
			d.rectangle([x0 + m - e, y0 + m - e, x0 + m + e, y0 + m + e], fill=(255, 255, 250))
		if plan.cells_of("m"):                          # maison : mur clair, toit rouge, porte
			x0, y0, x1, y1 = _boite(d, plan.cells_of("m") + plan.cells_of("D"), coin, case,
				fill=(226, 214, 190), outline=(90, 60, 40), width=2)
			d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=(176, 70, 52), outline=(90, 40, 30), width=2)
			for x, y in plan.cells_of("D"):
				px, py = coin(x, y)
				d.rectangle([px + 3, py + case // 4, px + case - 4, py + case - 1], fill=(80, 52, 32))
		if plan.cells_of("P"):                          # poste : murs clairs, toit d'ardoise, portes latérales
			x0, y0, x1, y1 = _boite(d, plan.cells_of("P") + plan.cells_of("D"), coin, case,
				fill=(214, 206, 190), outline=(70, 70, 80), width=2)
			d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) // 2], fill=(84, 92, 110), outline=(50, 54, 64), width=2)
			for x, y in plan.cells_of("D"):
				px, py = coin(x, y)
				d.rectangle([px, py + 2, px + case - 1, py + case - 3], fill=(80, 52, 32))
		for p in plan.of_kind("panneau"):               # panneaux sans texte
			for x, y in p.cells:
				px, py = coin(x, y)
				d.rectangle([px + case // 4, py + case // 4, px + case * 3 // 4, py + case * 3 // 4], fill=OCRE,
					outline=(110, 70, 30))
	else:
		for x, y in plan.cells_of("K"):                 # mur du fond plus clair que les marges
			if y in (1, 2):
				x0, y0 = coin(x, y)
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(150, 128, 104))
		for x, y in plan.cells_of("B"):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + 2, y0 - case // 2, x0 + case - 3, y0 + case - 3], fill=(120, 80, 48))
		for x, y in plan.cells_of("N"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0 + 4, x0 + case - 1, y0 + case - 4], fill=(150, 104, 60))
		for x, y in plan.cells_of("J"):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + case // 4, y0 + case // 6, x0 + case * 3 // 4, y0 + case * 5 // 6], fill=(60, 64, 76))
		for x, y in plan.cells_of("x"):
			x0, y0 = coin(x, y)
			d.ellipse([x0 + 4, y0 + 4, x0 + case - 5, y0 + case - 5], fill=(50, 130, 60))
		for x, y in plan.cells_of("U"):
			x0, y0 = coin(x, y)
			for k in range(4):
				d.rectangle([x0 + 2, y0 + k * case // 4, x0 + case - 3, y0 + k * case // 4 + case // 8],
					fill=(120, 110, 96))
		for x, y in plan.cells_of("X"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(40, 30, 24))
	ART.mkdir(parents=True, exist_ok=True)
	sortie = ART / f"PLAN_{zone}_codex.png"
	img.save(sortie)
	return sortie


def planche() -> Path:
	hauteur = 640
	police = ImageFont.load_default(size=28)
	lignes = []
	for zone, (_, _, vue, plan) in ZONES.items():
		images = []
		for f in (REF / vue, REF / "plans-j22" / plan):
			im = Image.open(f).convert("RGB")
			images.append(im.resize((round(im.width * hauteur / im.height), hauteur), Image.LANCZOS))
		largeur = sum(i.width for i in images) + 40 * 3
		ligne = Image.new("RGB", (largeur, hauteur + 70), (28, 30, 34))
		ImageDraw.Draw(ligne).text((40, 18), f"{vue}  |  plan (fait foi) : plans-j22/{plan}", fill=(235, 235, 235),
			font=police)
		x = 40
		for im in images:
			ligne.paste(im, (x, 60))
			x += im.width + 40
		lignes.append(ligne)
	largeur = max(l.width for l in lignes)
	tout = Image.new("RGB", (largeur, sum(l.height for l in lignes) + 20), (28, 30, 34))
	y = 0
	for l in lignes:
		tout.paste(l, (0, y))
		y += l.height
	sortie = REF / "j22-vues-est-v1.png"
	tout.save(sortie, optimize=True)
	return sortie


def main() -> int:
	if "--plans" in sys.argv:
		for zone in ZONES:
			print(plan_codex(zone))
	if "--planche" in sys.argv:
		print(planche())
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
