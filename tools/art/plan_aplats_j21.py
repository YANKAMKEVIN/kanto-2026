#!/usr/bin/env python3
"""Plans en aplats du jalon 21 (lot 21.0, T8) : Tour Pokémon 7F, Route 12 nord, Route 16 est.

Image 1 des vues générales peintes (méthode de la Tour, de la Route 25 et de la Forêt de Jade :
plan en aplats + vue d'un AUTRE lieu comme ancre de style). Les grilles de `tools/plans/` font foi.
Personnages, Pokémon et cases cachées ne sont JAMAIS dessinés : le prompt les décrit.

Réutilise les palettes et les peintres du J19 (`tools/art/plan_aplats.py` de la branche
`jalon-19` : `_peindre_tour`, couleurs de la Route 3 / 25) : tant que le J19 n'est pas fusionné ici
(T9), ce module en tire une copie temporaire via `git show` (jamais écrite dans le dépôt). Après T9,
`plan_aplats` est importé tel quel.

Usage : python3 tools/art/plan_aplats_j21.py [tour_7f|route_12|route_16 ...]
  → build/art/PLAN_TOUR_7F_v1.png (paysage 1536 × 1024), PLAN_ROUTE12_v1.png (portrait 1024 × 1536),
    PLAN_ROUTE16_v1.png (paysage 1536 × 1024). Reproductible (graine fixe).
"""
from __future__ import annotations

import importlib
import random
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
ART = RACINE / "build" / "art"


def _charger_plan_aplats():
	"""`plan_aplats` du J19 : celui d'ici s'il a `_peindre_tour`, sinon une copie via git."""
	sys.path.insert(0, str(ICI))
	try:
		pa = importlib.import_module("plan_aplats")
		if hasattr(pa, "_peindre_tour"):
			return pa
	except ModuleNotFoundError:
		pass
	for nom in ("plan_aplats", "plan_grille"):
		sys.modules.pop(nom, None)
	sys.path.remove(str(ICI))
	tmp = Path(tempfile.mkdtemp(prefix="plan_aplats_j19_"))
	for nom in ("plan_aplats.py", "plan_grille.py"):
		for ref in ("origin/jalon-19", "jalon-19"):
			res = subprocess.run(["git", "-C", str(RACINE), "show", f"{ref}:tools/art/{nom}"],
				capture_output=True, text=True)
			if res.returncode == 0:
				(tmp / nom).write_text(res.stdout, encoding="utf-8")
				break
		else:
			raise SystemExit(f"{nom} du J19 introuvable (branche jalon-19)")
	sys.path.insert(0, str(tmp))
	return importlib.import_module("plan_aplats")


pa = _charger_plan_aplats()
from plan_grille import Plan, lire  # noqa: E402  (la copie compatible avec pa)

PLANS = RACINE / "tools" / "plans"
GRAINE = 21

# --- Couleurs --------------------------------------------------------------------------------
TOUR_7F = ((56, 50, 72), (126, 120, 142))  # mur, dalles : plus sombre que le 6F (dossier 24 §6)
pa.P_ETAGES["7F"] = TOUR_7F
FORET = pa.ARBRE if hasattr(pa, "ARBRE") else (40, 120, 50)
FORET_FOND = (25, 90, 40)
FORET_BORD = (20, 60, 30)
EAU = (70, 150, 200)
EAU_PROFONDE = (35, 90, 150)
PONTON = (186, 140, 88)
PONTON_JOINT = (140, 100, 60)
PONTON_BORD = (96, 64, 38)
TERRE = (225, 195, 140)
RIVE = (150, 150, 140)
RIVE_BORD = (100, 100, 96)
ILOT = (170, 128, 82)
POSTE_MUR = (120, 135, 160)
POSTE_TOIT = (95, 108, 135)
POSTE_TOIT_B = (70, 82, 108)
PORTE = (80, 55, 40)
CLOTURE = (140, 100, 60)
CLOTURE_B = (90, 60, 30)
HAUTES = (150, 170, 30)
HAUTES_FIN = (120, 140, 20)
PIERRE = (215, 215, 205)
PIERRE_BORD = (150, 150, 145)
PANNEAU = (200, 150, 60)
PANNEAU_BORD = (120, 85, 35)


def _chemin_ou_fond(img, d, taille, plan, case, ox, oy, couleur_hors):
	"""Remplit l'image d'une couleur de fond, puis la grille (appelé avant les symboles)."""
	d.rectangle([0, 0, taille[0], taille[1]], fill=couleur_hors)


def _arbres(d, plan: Plan, car: str, case: int, ox: int, oy: int, alea: random.Random,
		marges: tuple[int, int, int, int] = (0, 0, 0, 0)) -> None:
	"""Cimes rondes sur les cases `car` (et sur les marges virtuelles, voir `marges`)."""
	def un(x: int, y: int) -> None:
		cx, cy = ox + (x + 0.5) * case, oy + (y + 0.5) * case
		for _ in range(2):
			pa._disque(d, cx + alea.uniform(-case * 0.2, case * 0.2),
				cy + alea.uniform(-case * 0.2, case * 0.2), case * alea.uniform(0.42, 0.6),
				FORET, FORET_BORD)
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if c in car:
				un(x, y)


# --- Tour Pokémon 7F --------------------------------------------------------------------------


def dessiner_tour_7f(sortie: Path) -> Path:
	"""Le 7F seul, paysage 1536 × 1024, 1 case = 48 px, centré sur un fond neutre sombre. Les
	étages voisins ne sont pas dessinés (le 7F est une carte isolée)."""
	plan = lire(PLANS / "pokemon_tower_7f.txt")
	taille = pa.TAILLE_PAYSAGE
	case = 48
	ox = (taille[0] - plan.width * case) // 2
	oy = (taille[1] - plan.height * case) // 2
	img = Image.new("RGB", taille, pa.P_FOND)
	d = ImageDraw.Draw(img)
	pa._peindre_tour(d, plan, "7F", ox, oy, case)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


# --- Route 16 est -----------------------------------------------------------------------------


def dessiner_route_16(sortie: Path) -> Path:
	"""Paysage 1536 × 1024, 1 case = 32 px, grille centrée sur un fond de forêt. Poste : façade
	de 12 × 8 avec porte fermée ; voie haute = clairière d'herbes hautes (décor) ; arbre à Couper
	en décor = grand arbre dense."""
	plan = lire(PLANS / "route_16.txt")
	taille = pa.TAILLE_PAYSAGE
	case = 32
	ox = (taille[0] - plan.width * case) // 2
	oy = (taille[1] - plan.height * case) // 2
	img = Image.new("RGB", taille, FORET_FOND)
	d = ImageDraw.Draw(img)
	alea = random.Random(GRAINE + 16)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def bord(x: int, y: int) -> str:
		return plan.at(min(max(x, 0), plan.width - 1), min(max(y, 0), plan.height - 1))

	# 1. Aplats (marges comprises : forêt, sauf le chemin qui sortirait par l'est).
	gx0, gy0 = -(ox // case) - 1, -(oy // case) - 1
	gx1 = plan.width + (taille[0] - ox) // case + 1
	gy1 = plan.height + (taille[1] - oy) // case + 1
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			dedans = 0 <= x < plan.width and 0 <= y < plan.height
			car = bord(x, y) if dedans else ("=" if x >= plan.width and y in (21, 22, 23) else "T")
			x0, y0 = coin(x, y)
			if car in "=D":
				fond = TERRE
			elif car == "Y":
				fond = HAUTES
			elif car == "P":
				fond = POSTE_MUR
			elif car == "R":
				fond = RIVE
			elif car == "c":
				fond = FORET_FOND
			else:
				fond = FORET_FOND
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=fond)
	# 2. Forêt (cimes), hautes herbes (touffes), affleurements, clôture.
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			dedans = 0 <= x < plan.width and 0 <= y < plan.height
			car = bord(x, y) if dedans else ("=" if x >= plan.width and y in (21, 22, 23) else "T")
			cx, cy = centre(x, y)
			if car in "TW":
				for _ in range(2):
					pa._disque(d, cx + alea.uniform(-6, 6), cy + alea.uniform(-6, 6),
						case * alea.uniform(0.45, 0.62), FORET, FORET_BORD)
			elif car == "Y":
				for _ in range(3):
					pa._disque(d, cx + alea.uniform(-9, 9), cy + alea.uniform(-9, 9),
						alea.uniform(3, 6), HAUTES_FIN)
			elif car == "R":
				for _ in range(2):
					pa._disque(d, cx + alea.uniform(-8, 8), cy + alea.uniform(-8, 8),
						alea.uniform(6, 10), PIERRE, PIERRE_BORD)
			elif car == "c":
				x0, y0 = coin(x, y)
				d.line([x0, cy, x0 + case, cy], fill=CLOTURE_B, width=3)
				d.line([x0, cy - 5, x0 + case, cy - 5], fill=CLOTURE, width=2)
				d.rectangle([cx - 2, cy - 9, cx + 2, cy + 6], fill=CLOTURE_B)
	# L'arbre « à Couper » en décor : un seul grand arbre dense de 2 × 2 cases.
	w = plan.cells_of("W")
	if w:
		xs = [x for x, _ in w]
		ys = [y for _, y in w]
		cx0, cy0 = coin(min(xs), min(ys))
		cx1, cy1 = coin(max(xs) + 1, max(ys) + 1)
		pa._disque(d, (cx0 + cx1) / 2, (cy0 + cy1) / 2, (cx1 - cx0) * 0.58, FORET, FORET_BORD)
	# 3. Poste : toit sur les 3/5 hauts de l'emprise, façade dessous, porte.
	poste = plan.cells_of("P")
	xs = [x for x, _ in poste]
	ys = [y for _, y in poste]
	x0, y0 = coin(min(xs), min(ys))
	x1, y1 = coin(max(xs) + 1, max(ys) + 1)
	d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=POSTE_TOIT, outline=POSTE_TOIT_B,
		width=2)
	for x, y in plan.cells_of("D"):
		px0, py0 = coin(x, y)
		d.rectangle([px0 + 2, py0 + case // 4, px0 + case - 3, py0 + case - 1], fill=PORTE)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


# --- Route 12 nord ----------------------------------------------------------------------------


def _distance_rive(plan: Plan) -> dict[tuple[int, int], int]:
	"""Distance (en cases) de chaque case d'eau à la case non-eau la plus proche."""
	dist: dict[tuple[int, int], int] = {}
	file: deque = deque()
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if c != "w":
				dist[(x, y)] = 0
				file.append((x, y))
	while file:
		x, y = file.popleft()
		for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
			n = (x + dx, y + dy)
			if 0 <= n[0] < plan.width and 0 <= n[1] < plan.height and n not in dist:
				dist[n] = dist[(x, y)] + 1
				file.append(n)
	return dist


def dessiner_route_12(sortie: Path) -> Path:
	"""Portrait 1024 × 1536, 1 case = 15 px (39 × 102 cases = 585 × 1530), centré sur un fond de
	forêt (comme la Forêt de Jade, 14 px). Ponton, eau, poste traversant, éperons, îlot vide. Le
	raccord ouest (rangées 93..94) sort de la grille : le chemin se prolonge dans la marge."""
	plan = lire(PLANS / "route_12.txt")
	taille = pa.TAILLE
	case = 15
	ox = (taille[0] - plan.width * case) // 2
	oy = (taille[1] - plan.height * case) // 2
	img = Image.new("RGB", taille, FORET_FOND)
	d = ImageDraw.Draw(img)
	alea = random.Random(GRAINE + 12)
	prof = _distance_rive(plan)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def sorti(x: int, y: int) -> str:
		"""Caractère d'une case, marges virtuelles comprises (forêt ; chemin ouest prolongé)."""
		if 0 <= x < plan.width and 0 <= y < plan.height:
			return plan.at(x, y)
		if x < 0 and y in (93, 94):
			return "."
		return "T"

	gx0, gy0 = -(ox // case) - 1, 0
	gx1, gy1 = plan.width + (taille[0] - ox) // case + 1, plan.height
	# 1. Aplats.
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			car = sorti(x, y)
			x0, y0 = coin(x, y)
			if car == "w":
				t = min(1.0, max(0.0, (prof.get((x, y), 4) - 1) / 5))
				fond = pa._melange(EAU, EAU_PROFONDE, t)
			elif car == "=":
				fond = PONTON
			elif car == ".":
				fond = TERRE
			elif car == "i":
				fond = ILOT
			elif car == "R":
				fond = RIVE
			elif car in "PD":
				fond = POSTE_MUR
			else:
				fond = FORET_FOND
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=fond)
	# 2. Planches (traits en travers du sens de marche), écume au pied des rives et du ponton,
	#    cimes de la forêt, cailloux des rives.
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			car = sorti(x, y)
			x0, y0 = coin(x, y)
			cx, cy = centre(x, y)
			if car in "=i":
				vertical = sorti(x - 1, y) not in "=i." or sorti(x + 1, y) not in "=i."
				if car == "i" or vertical:
					d.line([x0, y0 + case // 2, x0 + case - 1, y0 + case // 2], fill=PONTON_JOINT)
				else:
					d.line([x0 + case // 2, y0, x0 + case // 2, y0 + case - 1], fill=PONTON_JOINT)
				for dx, dy, p0, p1 in ((0, -1, (x0, y0), (x0 + case - 1, y0)),
						(0, 1, (x0, y0 + case - 1), (x0 + case - 1, y0 + case - 1)),
						(-1, 0, (x0, y0), (x0, y0 + case - 1)),
						(1, 0, (x0 + case - 1, y0), (x0 + case - 1, y0 + case - 1))):
					if sorti(x + dx, y + dy) == "w":
						d.line([p0, p1], fill=PONTON_BORD, width=2)
			elif car == "w":
				if any(sorti(x + dx, y + dy) in "=iR.PD" for dx, dy in ((0, -1), (-1, 0), (0, 1), (1, 0))):
					if alea.random() < 0.5:
						d.line([x0 + 2, y0 + case // 2, x0 + case - 3, y0 + case // 2],
							fill=pa.BLANC, width=1)
			elif car == "R":
				for _ in range(2):
					pa._disque(d, cx + alea.uniform(-4, 4), cy + alea.uniform(-4, 4),
						alea.uniform(2.5, 4.5), pa.PIERRE, pa.PIERRE_BORD)
			elif car == "T":
				if x < -3 or x > plan.width + 3 or alea.random() < 1.0:
					for _ in range(2):
						pa._disque(d, cx + alea.uniform(-3, 3), cy + alea.uniform(-3, 3),
							case * alea.uniform(0.45, 0.62), FORET, FORET_BORD)
	# 3. Poste : emprise 9 × 9, toit sur les 6 rangées hautes, façade sud, deux portes.
	poste = plan.cells_of("P") + plan.cells_of("D")
	xs = [x for x, _ in poste]
	ys = [y for _, y in poste]
	x0, y0 = coin(min(xs), min(ys))
	x1, y1 = coin(max(xs) + 1, max(ys) + 1)
	d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 2 // 3], fill=POSTE_TOIT, outline=POSTE_TOIT_B,
		width=2)
	for x, y in plan.cells_of("D"):
		px0, py0 = coin(x, y)
		d.rectangle([px0 + 1, py0 + 2, px0 + case - 2, py0 + case - 1], fill=PORTE)
	# 4. Panneaux (objets visibles : aucun ; les personnages ne sont jamais dessinés).
	for p in plan.of_kind("panneau"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=PANNEAU, outline=PANNEAU_BORD)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


SORTIES = {
	"tour_7f": (dessiner_tour_7f, "PLAN_TOUR_7F_v1.png"),
	"route_12": (dessiner_route_12, "PLAN_ROUTE12_v1.png"),
	"route_16": (dessiner_route_16, "PLAN_ROUTE16_v1.png"),
}


def main() -> int:
	noms = [a for a in sys.argv[1:] if not a.startswith("--")] or list(SORTIES)
	for nom in noms:
		if nom not in SORTIES:
			print(f"{nom} : inconnu (attendu : {', '.join(SORTIES)})")
			return 1
		fonction, fichier = SORTIES[nom]
		print(fonction(ART / fichier))
	return 0


if __name__ == "__main__":
	sys.exit(main())
