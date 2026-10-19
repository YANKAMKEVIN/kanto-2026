#!/usr/bin/env python3
"""Plans en aplats SANS annotation des trois vues générales du jalon 16 (dossier 19, §0.4).

Image 1 jointe à Codex pour les vues générales peintes (méthode des vues du J15) : la géométrie
vient des grilles validées (`tools/plans/ss_anne_pont_principal.txt`, `ss_anne_pont_exterieur.txt`,
`carmin_arene.txt`, qui font foi) ; aucun texte, aucun personnage, aucun objet de jeu (Dresseurs,
PNJ, objets ramassables) : seulement le bâti et le mobilier de la grille. La planche annotée
`docs/design/reference/ss-anne-plans-v1.png` (`plan_ss_anne.py`) n'est JAMAIS jointe à Codex.

PAYSAGE 1536 × 1024, grille centrée ; la marge prolonge le décor (mer pour le pont extérieur,
masse sombre pour les intérieurs). Reproductible : même grille → même image.

Usage : python3 tools/art/plan_aplats_ss_anne.py [dossier_de_sortie]   (défaut : build/art)
        → PLAN_SS_ANNE_PONT_PRINCIPAL_v1.png, PLAN_SS_ANNE_PONT_EXTERIEUR_v1.png,
          PLAN_ARENE_CARMIN_v1.png
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
TAILLE = (1536, 1024)

VIDE = (28, 24, 30)
MUR_HAUT = (92, 62, 44)        # dessus des murs (bois sombre)
MUR_FACE = (176, 132, 92)      # face avant des murs nord (boiseries)
PARQUET = (214, 184, 140)
PORTE = (120, 70, 36)
PASSERELLE = (236, 236, 228)
ESCALIER = (86, 70, 60)
COMPTOIR = (70, 44, 30)
BANQUETTE = (150, 48, 52)
PLANTE = (60, 140, 60)
POT = (170, 110, 70)

MER = (40, 100, 160)
PONT_BOIS = (226, 196, 150)
RAMBARDE = (248, 248, 244)
MAIN_COURANTE = (150, 104, 64)
SUPERSTRUCTURE = (240, 240, 236)
CHAISE = (168, 112, 70)
BOUEE_ROUGE = (210, 50, 50)

SOL_TECH = (150, 156, 164)
MUR_TECH_HAUT = (58, 62, 72)
MUR_TECH_FACE = (104, 110, 122)
ESTRADE = (190, 196, 206)
MACHINE = (82, 88, 104)
BARRIERE = (120, 200, 255)
FOUILLE = (120, 126, 136)
FOUILLE_BORD = (60, 64, 72)
SORTIE_TECH = (210, 210, 200)


def _image(plan: Plan, fond: tuple) -> tuple[Image.Image, ImageDraw.ImageDraw, int, int, int]:
	case = min(TAILLE[0] // plan.width, TAILLE[1] // plan.height)
	img = Image.new("RGB", TAILLE, fond)
	ox = (TAILLE[0] - plan.width * case) // 2
	oy = (TAILLE[1] - plan.height * case) // 2
	return img, ImageDraw.Draw(img), case, ox, oy


def _boite(ox: int, oy: int, case: int, x: int, y: int, x2: int | None = None, y2: int | None = None):
	x2 = x if x2 is None else x2
	y2 = y if y2 is None else y2
	return [ox + x * case, oy + y * case, ox + (x2 + 1) * case - 1, oy + (y2 + 1) * case - 1]


def _mur(d, plan: Plan, b, x: int, y: int, haut: tuple, face: tuple) -> None:
	"""Mur : face avant (couleur claire) si la case du dessous est un sol ; sinon dessus du mur."""
	dessous = plan.at(x, y + 1) if y + 1 < plan.height else "K"
	d.rectangle(b(x, y), fill=face if dessous not in "KD" else haut)


def pont_principal(sortie: Path) -> Path:
	plan = lire(PLANS / "ss_anne_pont_principal.txt")
	img, d, case, ox, oy = _image(plan, VIDE)

	def b(*a):
		return _boite(ox, oy, case, *a)

	for y in range(plan.height):
		for x in range(plan.width):
			c = plan.at(x, y)
			if c == "K":
				_mur(d, plan, b, x, y, MUR_HAUT, MUR_FACE)
			else:
				d.rectangle(b(x, y), fill=PARQUET)
			if c == "D":
				x0, y0, x1, y1 = b(x, y)
				if plan.at(x, y + 1) != "K":   # porte dans la face du mur nord
					d.rectangle(b(x, y), fill=MUR_FACE)
				d.rectangle([x0 + 4, y0 + 2, x1 - 4, y1], fill=PORTE)
			elif c == "X":
				d.rectangle(b(x, y), fill=PASSERELLE)
			elif c == "S":
				x0, y0, x1, y1 = b(x, y)
				d.rectangle([x0, y0, x1, y1], fill=ESCALIER)
				for i in range(1, 6):
					yy = y0 + i * case // 6
					d.line([x0, yy, x1, yy], fill=(140, 120, 100), width=3)
			elif c == "c":
				x0, y0, x1, y1 = b(x, y)
				d.rectangle([x0, y0 + 6, x1, y1 - 6], fill=COMPTOIR)
			elif c == "b":
				x0, y0, x1, y1 = b(x, y)
				d.rectangle([x0 + 2, y0 + 8, x1 - 2, y1 - 8], fill=BANQUETTE)
			elif c == "x":
				x0, y0, x1, y1 = b(x, y)
				d.ellipse([x0 + 6, y0 + 6, x1 - 6, y1 - 6], fill=PLANTE, outline=POT, width=4)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def pont_exterieur(sortie: Path) -> Path:
	plan = lire(PLANS / "ss_anne_pont_exterieur.txt")
	img, d, case, ox, oy = _image(plan, MER)
	# À l'ouest de la grille, la superstructure du navire se prolonge (masse blanche).
	d.rectangle([0, oy + 2 * case, ox + case - 1, oy + 10 * case - 1], fill=SUPERSTRUCTURE)

	def b(*a):
		return _boite(ox, oy, case, *a)

	for y in range(plan.height):
		for x in range(plan.width):
			c = plan.at(x, y)
			x0, y0, x1, y1 = b(x, y)
			if c == "w":
				d.rectangle(b(x, y), fill=MER)
			elif c == "K":
				d.rectangle(b(x, y), fill=SUPERSTRUCTURE)
			else:
				d.rectangle(b(x, y), fill=PONT_BOIS)
				for i in range(1, 4):
					yy = y0 + i * case // 4
					d.line([x0, yy, x1, yy], fill=(200, 168, 124), width=1)
			if c == "r":
				d.rectangle(b(x, y), fill=PONT_BOIS)
				if y in (2, 9):
					yy = y0 + case // 2
					d.rectangle([x0, yy - 6, x1, yy + 6], fill=RAMBARDE)
					d.rectangle([x0, yy - 3, x1, yy + 3], fill=MAIN_COURANTE)
				else:
					xx = x0 + case // 2
					d.rectangle([xx - 6, y0, xx + 6, y1], fill=RAMBARDE)
					d.rectangle([xx - 3, y0, xx + 3, y1], fill=MAIN_COURANTE)
			elif c == "D":
				d.rectangle([x0 + 2, y0 + 4, x1 - 2, y1 - 4], fill=PORTE)
			elif c == "l":
				d.rectangle([x0 + 6, y0 + 4, x1 - 6, y1 - 4], fill=CHAISE)
			elif c == "u":
				cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, case * 0.38
				d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=BOUEE_ROUGE)
				d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5], fill=PONT_BOIS)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def arene_carmin(sortie: Path) -> Path:
	plan = lire(PLANS / "carmin_arene.txt")
	img, d, case, ox, oy = _image(plan, VIDE)

	def b(*a):
		return _boite(ox, oy, case, *a)

	for y in range(plan.height):
		for x in range(plan.width):
			c = plan.at(x, y)
			x0, y0, x1, y1 = b(x, y)
			if c == "K":
				_mur(d, plan, b, x, y, MUR_TECH_HAUT, MUR_TECH_FACE)
				continue
			d.rectangle(b(x, y), fill=SOL_TECH, outline=(136, 142, 150))
			if c == "X":
				d.rectangle(b(x, y), fill=SORTIE_TECH)
			elif c == "m":
				d.rectangle([x0 + 2, y0 + 4, x1 - 2, y1 - 2], fill=MACHINE)
			elif c == "B":
				d.rectangle(b(x, y), fill=BARRIERE)
			elif c == "i":
				d.rectangle([x0 + 10, y0 + 8, x1 - 10, y1 - 6], fill=FOUILLE, outline=FOUILLE_BORD, width=3)
	# Estrade du Champion : plancher métallique plus clair, AU MÊME NIVEAU, au fond au centre.
	d.rectangle(b(5, 2, 11, 4), fill=ESTRADE, outline=(150, 156, 166), width=2)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def main() -> None:
	dossier = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "build" / "art"
	for f, nom in ((pont_principal, "PLAN_SS_ANNE_PONT_PRINCIPAL_v1.png"),
			(pont_exterieur, "PLAN_SS_ANNE_PONT_EXTERIEUR_v1.png"),
			(arene_carmin, "PLAN_ARENE_CARMIN_v1.png")):
		print(f(dossier / nom))


if __name__ == "__main__":
	main()
