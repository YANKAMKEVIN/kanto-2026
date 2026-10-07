#!/usr/bin/env python3
"""Plan schématique en aplats d'une carte, tiré de sa grille fonctionnelle (jalon 8, T0).

Image 1 de la vue générale peinte (méthode de Bourg Palette et de la Route 1 : plan en aplats +
vue d'un AUTRE lieu comme ancre de style). Couleurs du plan de la Route 1
(`docs/design/reference/route-1-plan-v1.png`) pour forêt, herbe, chemin, hautes herbes, rebord ;
le reste suit la légende du prompt `CONCEPT_ROUTE2_VUE_GENERALE_r1.txt`.
1 case = 24 px ; la grille est centrée sur un fond de forêt 1024 × 1536 (format portrait de Codex).

Usage : python3 tools/art/plan_aplats.py [grille.txt] [sortie.png] [--lisiere]
        (défaut : tools/plans/route_2.txt → build/art/PLAN_ROUTE2_v1.png)
--lisiere (vue générale, essai 3) : la géométrie ne change pas ; le plan PORTE la transition
vers la forêt (canopée plus sombre vers le nord, herbe éloignée du chemin rendue en sous-bois
ombragé, arbres serrés le long du chemin) et ferme visiblement FUTUR A (masse d'arbre dense).
--empiler NORD SUD DX (vue générale d'Argenta, J10) : assemble deux cartes raccordées, NORD au-dessus
de SUD, SUD décalée de DX colonnes vers l'est (forêt autour) ; la case est réduite pour tenir
dans le format portrait.
Reproductible : même grille → même image (fleurs tirées avec une graine fixe).
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, Position, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
CASE = 24
TAILLE = (1024, 1536)
GRAINE = 2

# Couleurs relevées sur route-1-plan-v1.png.
FORET = (25, 90, 40)
HERBE = (70, 150, 60)
CHEMIN = (225, 195, 140)
HAUTES_HERBES = (150, 170, 30)
REBORD = (150, 100, 60)
FLEUR = (240, 200, 220)
ARBRE = (40, 120, 50)
ARBRE_BORD = (20, 60, 30)
SOMBRE = (20, 70, 50)
SOMBRE_BORD = (10, 40, 30)
BLANC = (240, 240, 240)
SOUCHE = (110, 70, 40)
# Ajouts de la Route 2.
POSTE = (120, 135, 160)
POSTE_TOIT = (95, 108, 135)
PORTE = (80, 55, 40)
SENTIER_FERME = (175, 160, 115)
PIERRE = (215, 215, 205)
PIERRE_BORD = (150, 150, 145)
BUISSON = (35, 85, 45)
PANNEAU = (200, 150, 60)
PANNEAU_BORD = (120, 85, 35)
BALL_ROUGE = (220, 40, 40)
BALL_BORD = (40, 40, 40)
# Ajouts d'Argenta et de la Route 2 nord (J10).
PAROI = (150, 138, 120)
PAVE = (205, 192, 168)
BANC = (125, 85, 50)
BLOC = (185, 180, 170)
EBOULIS = (160, 150, 135)
# Bâtiments : (mur, toit).
BATIMENTS = {
	"M": ((222, 210, 185), (120, 100, 85)),   # Musée : pierre claire, grand toit sombre
	"Z": ((175, 168, 155), (105, 98, 92)),    # Arène : pierre grise massive
	"C": ((240, 238, 232), (205, 60, 50)),    # Centre Pokémon : toit rouge
	"O": ((240, 238, 232), (60, 110, 195)),   # Boutique : toit bleu
	"m": ((228, 212, 182), (165, 95, 65)),    # maison : toit de tuiles
	"P": (POSTE, POSTE_TOIT),                 # poste de garde
}

# Couleur de fond de chaque caractère (les symboles sont dessinés par-dessus).
FOND = {
	"T": FORET, ".": HERBE, "=": CHEMIN, "h": HAUTES_HERBES, "v": REBORD, "P": POSTE,
	"D": POSTE, "A": FORET, "a": SENTIER_FERME, "B": SENTIER_FERME, "b": SENTIER_FERME,
	"R": HERBE, "S": HERBE, "x": HERBE, "G": HERBE, "c": HERBE,
	"K": PAROI, "p": PAVE, "n": PAVE, "k": HERBE, "E": HERBE, "e": SENTIER_FERME,
	"M": BATIMENTS["M"][0], "Z": BATIMENTS["Z"][0], "C": BATIMENTS["C"][0],
	"O": BATIMENTS["O"][0], "m": BATIMENTS["m"][0],
}
# Part des cases d'herbe rase fleuries, par rangée (du sud, très fleuri, au nord, aucune).
FLEURS_SUD = 0.35
RANGEE_FIN_FLEURS = 20


def _disque(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill, outline=None) -> None:
	d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline, width=2)


# Lisière (--lisiere) : de LISIERE_DEBUT (rangée) vers le nord, la forêt s'assombrit jusqu'à
# CANOPEE et l'herbe rase loin du chemin devient du sous-bois ombragé.
LISIERE_DEBUT = 30
CANOPEE = (10, 48, 28)
SOUS_BOIS = (34, 88, 46)
OMBRE = (22, 66, 38)


def _melange(a, b, t: float):
	return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _lisiere(plan, img, d, coin, centre) -> None:
	"""Transition peinte vers la forêt, portée par le plan (géométrie inchangée)."""
	alea = random.Random(GRAINE + 1)
	ouvert = set("=hDvR")
	def pres_du_chemin(x: int, y: int, r: int) -> bool:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				yy, xx = y + dy, x + dx
				if 0 <= yy < plan.height and 0 <= xx < plan.width and plan.rows[yy][xx] in ouvert:
					return True
		return False
	for y, row in enumerate(plan.rows):
		t = max(0.0, (LISIERE_DEBUT - y) / LISIERE_DEBUT)
		if t <= 0:
			continue
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if c == ".":
				# Herbe à plus d'une case du chemin : sous-bois de plus en plus ombragé.
				if not pres_du_chemin(x, y, 1):
					d.rectangle([x0, y0, x0 + CASE - 1, y0 + CASE - 1],
						fill=_melange(HERBE, SOUS_BOIS, min(1.0, t * 1.6)))
	# Taches d'ombre de canopée au sol, de plus en plus nombreuses vers le nord.
	for y, row in enumerate(plan.rows):
		t = max(0.0, (LISIERE_DEBUT - y) / LISIERE_DEBUT)
		for x, c in enumerate(row):
			if c in ".h" and alea.random() < 0.55 * t:
				cx, cy = centre(x, y)
				_disque(d, cx + alea.uniform(-8, 8), cy + alea.uniform(-8, 8),
					alea.uniform(7, 12), OMBRE)
	# Arbres serrés le long du chemin : houppiers débordant de la forêt sur ses bords.
	for y, row in enumerate(plan.rows):
		t = max(0.0, (LISIERE_DEBUT - y) / LISIERE_DEBUT)
		for x, c in enumerate(row):
			if c == "T" and pres_du_chemin(x, y, 1) and alea.random() < 0.35 + 0.5 * t:
				cx, cy = centre(x, y)
				_disque(d, cx, cy, CASE * (0.55 + 0.35 * t), _melange(ARBRE, CANOPEE, t * 0.7),
					ARBRE_BORD)


def _futur_a_ferme(plan, d, centre) -> None:
	"""FUTUR A : une masse d'arbre dense coupe tout le sentier (le sentier reste visible derrière)."""
	for x, y in plan.cells_of("A"):
		cx, cy = centre(x, y)
		_disque(d, cx, cy, CASE * 1.7, SOMBRE, SOMBRE_BORD)
		for dx, dy, r in ((-0.9, -1.0, 0.8), (0.9, -1.0, 0.8), (-0.9, 1.0, 0.8), (0.9, 1.0, 0.8)):
			_disque(d, cx + dx * CASE, cy + dy * CASE, CASE * r, BUISSON, SOMBRE_BORD)
		_disque(d, cx, cy, CASE * 1.1, (14, 52, 34), SOMBRE_BORD)


def empiler(nord: Plan, sud: Plan, dx: int) -> Plan:
	"""NORD au-dessus de SUD (décalée de dx colonnes), forêt autour ; positions recalées."""
	largeur = max(nord.width, sud.width + dx)
	rows = [r.ljust(largeur, "T") for r in nord.rows]
	rows += [("T" * dx + r).ljust(largeur, "T") for r in sud.rows]
	plan = Plan(largeur, len(rows), rows)
	plan.positions = dict(nord.positions)
	for ident, p in sud.positions.items():
		cells = [(x + dx, y + nord.height) for x, y in p.cells]
		plan.positions["sud_" + ident] = Position(ident, p.kind, cells, p.bloque, p.note)
	return plan


def _composantes(plan: Plan, char: str) -> list[list[tuple[int, int]]]:
	reste = set(plan.cells_of(char))
	groupes = []
	while reste:
		pile = [reste.pop()]
		groupe = []
		while pile:
			x, y = pile.pop()
			groupe.append((x, y))
			for v in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
				if v in reste:
					reste.remove(v)
					pile.append(v)
		groupes.append(groupe)
	return groupes


def dessiner(grille: Path | Plan, sortie: Path, lisiere: bool = False) -> Path:
	global CASE
	plan = grille if isinstance(grille, Plan) else lire(grille)
	CASE = min(24, TAILLE[0] // plan.width, TAILLE[1] // plan.height)
	img = Image.new("RGB", TAILLE, FORET)
	d = ImageDraw.Draw(img)
	ox = (TAILLE[0] - plan.width * CASE) // 2
	oy = (TAILLE[1] - plan.height * CASE) // 2
	if lisiere:
		# Marges de l'image : même dégradé de canopée que les cases de forêt de la rangée.
		for py in range(TAILLE[1]):
			gy = (py - oy) / CASE
			t = max(0.0, (LISIERE_DEBUT - gy) / LISIERE_DEBUT)
			d.line([(0, py), (TAILLE[0], py)], fill=_melange(FORET, CANOPEE, min(1.0, t)))

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * CASE, oy + y * CASE

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * CASE, oy + (y + 0.5) * CASE

	# 1. Aplats.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if lisiere and c == "T":
				continue  # la forêt suit le dégradé déjà peint
			fond = FOND[c]
			if c == "D":
				for vx, vy in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
					if 0 <= vx < plan.width and 0 <= vy < plan.height \
							and plan.rows[vy][vx] in BATIMENTS:
						fond = BATIMENTS[plan.rows[vy][vx]][0]
						break
			d.rectangle([x0, y0, x0 + CASE - 1, y0 + CASE - 1], fill=fond)
			# Chemins et sentiers qui sortent de la carte : prolongés jusqu'au bord de l'image.
			if c in "=abe":
				x1, y1 = x0 + CASE - 1, y0 + CASE - 1
				if x == 0:
					d.rectangle([0, y0, x0, y1], fill=FOND[c])
				if x == plan.width - 1:
					d.rectangle([x1, y0, TAILLE[0], y1], fill=FOND[c])
				if y == 0:
					d.rectangle([x0, 0, x1, y0], fill=FOND[c])
				if y == plan.height - 1:
					d.rectangle([x0, y1, x1, TAILLE[1]], fill=FOND[c])

	if lisiere:
		_lisiere(plan, img, d, coin, centre)

	# 2. Fleurs (prairies du sud ; graine fixe).
	alea = random.Random(GRAINE)
	for y, row in enumerate(plan.rows):
		part = FLEURS_SUD * max(0.0, (y - RANGEE_FIN_FLEURS) / (plan.height - RANGEE_FIN_FLEURS))
		for x, c in enumerate(row):
			if c == "." and alea.random() < part:
				cx, cy = centre(x, y)
				_disque(d, cx + alea.uniform(-6, 6), cy + alea.uniform(-6, 6), 2.5, FLEUR)

	# 3. Poste : toit plus sombre sur la moitié haute de l'emprise, porte.
	portes_poste = [(x, y) for x, y in plan.cells_of("D")
		if any(0 <= x + dx < plan.width and 0 <= y + dy < plan.height
			and plan.rows[y + dy][x + dx] == "P" for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
	poste = plan.cells_of("P") + portes_poste
	if poste:
		xs = [x for x, _ in poste]
		ys = [y for _, y in poste]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) // 2], fill=POSTE_TOIT)
	for x, y in portes_poste:
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 6, y0 + 6, x0 + CASE - 7, y0 + CASE - 1], fill=PORTE)

	# 3 bis. Autres bâtiments (J10) : toit sur la moitié haute de chaque emprise, portes.
	for char in "MZCOm":
		for groupe in _composantes(plan, char):
			xs = [x for x, _ in groupe]
			ys = [y for _, y in groupe]
			x0, y0 = coin(min(xs), min(ys))
			x1, y1 = coin(max(xs) + 1, max(ys) + 1)
			d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=BATIMENTS[char][1])
	for x, y in plan.cells_of("D"):
		if any(plan.rows[y][x2] in "MZCOm" for x2 in (x - 1, x + 1) if 0 <= x2 < plan.width):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + CASE // 4, y0 + CASE // 4, x0 + CASE - CASE // 4 - 1, y0 + CASE - 1],
				fill=PORTE)

	# 4. Symboles par case.
	panneaux = {c for p in plan.of_kind("panneau") for c in p.cells}
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			cx, cy = centre(x, y)
			x0, y0 = coin(x, y)
			if c == "x" and (x, y) not in panneaux:
				_disque(d, cx, cy, 9, BUISSON, SOMBRE_BORD)
			elif c == "A":
				_disque(d, cx, cy, 11, SOMBRE, SOMBRE_BORD)
			elif c == "S":
				d.rectangle([cx - 7, cy - 7, cx + 7, cy + 7], fill=SOUCHE)
			elif c == "B":
				d.rectangle([cx - 3, y0, cx + 3, y0 + CASE - 1], fill=BLANC)
			elif c == "c":
				d.rectangle([x0, cy - 2, x0 + CASE - 1, cy + 2], fill=BLANC)
			elif c == "n":
				d.rectangle([x0 + 2, cy - 3, x0 + CASE - 3, cy + 3], fill=BANC)
			elif c == "k":
				d.rectangle([x0 + 2, y0 + 3, x0 + CASE - 3, y0 + CASE - 3], fill=BLOC,
					outline=PIERRE_BORD)
			elif c == "E":
				for ex, ey, er in ((-0.2, -0.2, 0.35), (0.25, 0.1, 0.3), (-0.15, 0.3, 0.25)):
					_disque(d, cx + ex * CASE, cy + ey * CASE, CASE * er, EBOULIS, PIERRE_BORD)
	for x, y in sorted(panneaux):
		cx, cy = centre(x, y)
		d.rectangle([cx - 6, cy - 6, cx + 6, cy + 6], fill=PANNEAU, outline=PANNEAU_BORD)

	# 5. Grande pierre : une ellipse sur toute son emprise.
	for pierre in _composantes(plan, "R"):
		xs = [x for x, _ in pierre]
		ys = [y for _, y in pierre]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.ellipse([x0 + 2, y0 + 2, x1 - 3, y1 - 3], fill=PIERRE, outline=PIERRE_BORD, width=2)

	# 6. Grands arbres repères : disque de 2 cases centré au-dessus du pied.
	for x, y in plan.cells_of("G"):
		cx, cy = centre(x, y)
		_disque(d, cx, cy - CASE * 0.5, CASE, ARBRE, ARBRE_BORD)

	if lisiere:
		_futur_a_ferme(plan, d, centre)

	# 7. Objets visibles : Poké Ball (rouge en haut, blanche en bas).
	for p in plan.of_kind("objet_visible"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			r = 5
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=BALL_ROUGE)
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=BLANC)
			d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=BALL_BORD, width=1)

	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def main() -> int:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	if "--empiler" in sys.argv:
		nord, sud, dx, sortie = args[0], args[1], int(args[2]), Path(args[3])
		print(dessiner(empiler(lire(Path(nord)), lire(Path(sud)), dx), sortie))
		return 0
	grille = Path(args[0]) if len(args) > 0 else RACINE / "tools/plans/route_2.txt"
	sortie = Path(args[1]) if len(args) > 1 else RACINE / "build/art/PLAN_ROUTE2_v1.png"
	print(dessiner(grille, sortie, "--lisiere" in sys.argv))
	return 0


if __name__ == "__main__":
	sys.exit(main())
