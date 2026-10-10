#!/usr/bin/env python3
"""Plan schématique en aplats d'une carte, tiré de sa grille fonctionnelle (jalon 8, T0).

Image 1 de la vue générale peinte (méthode de Bourg Palette et de la Route 1 : plan en aplats +
vue d'un AUTRE lieu comme ancre de style). Couleurs du plan de la Route 1
(`docs/design/reference/route-1-plan-v1.png`) pour forêt, herbe, chemin, hautes herbes, rebord ;
le reste suit la légende du prompt `CONCEPT_ROUTE2_VUE_GENERALE_r1.txt`.
1 case = 24 px ; la grille est centrée sur un fond de forêt 1024 × 1536 (format portrait de Codex).

Usage : python3 tools/art/plan_aplats.py [grille.txt] [sortie.png] [--lisiere]
        (défaut : tools/plans/route_2.txt → build/art/PLAN_ROUTE2_v1.png ;
        tools/plans/viridian_forest.txt → build/art/PLAN_FORET_JADE_v2.png, forêt agrandie du
        2026-10-08, `dessiner_foret` : 1 case = 14 px pour faire tenir 70 × 90 cases (v1 :
        grille 58 × 74 du T14, 17 px) ; --annote ajoute
        <sortie>_annote.png, version de relecture réduite, JAMAIS jointe à Codex)
--lisiere (vue générale, essai 3) : la géométrie ne change pas ; le plan PORTE la transition
vers la forêt (canopée plus sombre vers le nord, herbe éloignée du chemin rendue en sous-bois
ombragé, arbres serrés le long du chemin) et ferme visiblement FUTUR A (masse d'arbre dense).
tools/plans/route_3.txt → build/art/PLAN_ROUTE3_v1.png (J12, `dessiner_route_3`) : PAYSAGE
1536 × 1024, 1 case = 18 px ; montagne, affleurements, sol rocheux, entrée de grotte, Centre ;
la case cachée (type « cache ») n'apparaît que sur <sortie>_annote.png (--annote, même taille).
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


# --- Forêt de Jade (jalon 9, T14) -------------------------------------------------------------
# Légende de tools/plans/viridian_forest.txt. Couleurs : celles de la Route 2 pour chemin, hautes
# herbes, poste, Poké Balls ; forêt plus profonde, sous-bois, clairières plus claires, rai de
# lumière presque blanc (lumière blanche et douce, jamais dorée : prompt du T14).
F_FORET = (16, 60, 34)              # T : forêt serrée infranchissable (et marges de l'image)
F_SOUS_BOIS = (44, 100, 56)         # . : sous-bois praticable, à l'ombre
F_CLAIRIERE = (84, 158, 72)         # C : clairière (herbe rase éclairée)
F_LUMIERE = (214, 228, 170)         # L : rai de lumière au sol
F_LUMIERE_HALO = (150, 196, 110)
F_TRONC = (122, 82, 50)
F_TRONC_BORD = (70, 45, 28)
F_RACINE = (104, 72, 46)
F_FOND_CASE = {
	"T": F_FORET, ".": F_SOUS_BOIS, "C": F_CLAIRIERE, "L": F_LUMIERE, "=": CHEMIN, "g": CHEMIN,
	"h": HAUTES_HERBES, "P": POSTE, "D": POSTE, "I": F_SOUS_BOIS, "S": F_CLAIRIERE,
	"s": F_CLAIRIERE, "r": F_SOUS_BOIS,
}


def dessiner_foret(grille: Path, sortie: Path) -> Path:
	"""Plan en aplats de la Forêt de Jade : 1 case = CASE_FORET px (la carte 58 × 74 tient dans
	1024 × 1536), centré sur la canopée. Personnages, Pokémon et objets cachés non dessinés ;
	Poké Balls des objets visibles dessinées (comme à la Route 2)."""
	plan = lire(grille)
	case = min(CASE, TAILLE[0] // plan.width, TAILLE[1] // plan.height)
	k = case / CASE
	img = Image.new("RGB", TAILLE, F_FORET)
	d = ImageDraw.Draw(img)
	ox = (TAILLE[0] - plan.width * case) // 2
	oy = (TAILLE[1] - plan.height * case) // 2

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def boite(cases: list[tuple[int, int]]) -> tuple[int, int, int, int]:
		xs = [x for x, _ in cases]
		ys = [y for _, y in cases]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		return x0, y0, x1, y1

	# 1. Aplats ; la sortie sud est prolongée jusqu'au bas de l'image (vers le poste sud).
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=F_FOND_CASE[c])
			if c == "g" and y == plan.height - 1:
				d.rectangle([x0, y0, x0 + case - 1, TAILLE[1]], fill=CHEMIN)

	# 2. Rai de lumière : halo clair autour des cases L, puis le cœur presque blanc.
	rai = plan.cells_of("L")
	if rai:
		x0, y0, x1, y1 = boite(rai)
		m = case
		d.ellipse([x0 - m, y0 - m, x1 + m, y1 + m], fill=F_LUMIERE_HALO)
		for x, y in rai:
			cx0, cy0 = coin(x, y)
			d.rectangle([cx0, cy0, cx0 + case - 1, cy0 + case - 1], fill=F_LUMIERE)
		# Le halo ne déborde pas sur la forêt ni sur le chemin : on repeint ces cases.
		for y, row in enumerate(plan.rows):
			for x, c in enumerate(row):
				if c in "T=" :
					cx0, cy0 = coin(x, y)
					if x1 + m >= cx0 >= x0 - m - case and y1 + m >= cy0 >= y0 - m - case:
						d.rectangle([cx0, cy0, cx0 + case - 1, cy0 + case - 1],
							fill=F_FOND_CASE[c])

	# 3. Poste nord : toit plus sombre sur la moitié haute de l'emprise, porte.
	poste = plan.cells_of("P") + plan.cells_of("D")
	if poste:
		x0, y0, x1, y1 = boite(poste)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) // 2], fill=POSTE_TOIT)
	for x, y in plan.cells_of("D"):
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 4 * k, y0 + 4 * k, x0 + case - 5 * k, y0 + case - 1], fill=PORTE)

	# 4. Grande souche : une large ellipse brune cerclée sur toute son emprise (vue de dessus).
	souche = plan.cells_of("S")
	if souche:
		x0, y0, x1, y1 = boite(souche)
		d.ellipse([x0 - 2 * k, y0 - 2 * k, x1 + 2 * k, y1 + 2 * k], fill=F_TRONC,
			outline=F_TRONC_BORD, width=max(2, round(3 * k)))
		cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		for r in (0.55, 0.3):
			d.ellipse([cx - (x1 - x0) * r / 2 * 1.6, cy - (y1 - y0) * r / 2 * 1.6,
				cx + (x1 - x0) * r / 2 * 1.6, cy + (y1 - y0) * r / 2 * 1.6],
				outline=F_TRONC_BORD, width=max(1, round(2 * k)))

	# 5. Tronc incliné : une grosse barre brune couchée sur ses cases, qui déborde d'une
	#    demi-case au-dessus du bord du sentier (il penche vers lui sans le barrer).
	tronc = plan.cells_of("I")
	if tronc:
		x0, y0, x1, y1 = boite(tronc)
		cy = (y0 + y1) / 2
		d.rectangle([x0 - 2 * k, cy - 5 * k, x1 + case * 0.5, cy + 5 * k], fill=F_TRONC,
			outline=F_TRONC_BORD, width=max(1, round(2 * k)))
		_disque(d, x0, cy, 8 * k, F_TRONC, F_TRONC_BORD)

	# 6. Petites souches, amas de racines.
	for x, y in plan.cells_of("s"):
		cx, cy = centre(x, y)
		d.rectangle([cx - 6 * k, cy - 6 * k, cx + 6 * k, cy + 6 * k], fill=SOUCHE)
	for x, y in plan.cells_of("r"):
		cx, cy = centre(x, y)
		for dx, dy in ((-6, -4), (5, -6), (-4, 6), (6, 5), (0, 0)):
			d.line([cx, cy, cx + dx * k * 1.4, cy + dy * k * 1.4], fill=F_RACINE,
				width=max(2, round(3 * k)))

	# 7. Objets visibles : Poké Ball (rouge en haut, blanche en bas).
	for p in plan.of_kind("objet_visible"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			r = max(4, round(5 * k))
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=BALL_ROUGE)
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=BLANC)
			d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=BALL_BORD, width=1)

	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def annoter_foret(grille: Path, plan_png: Path, sortie: Path, largeur: int = 768) -> Path:
	"""Version de RELECTURE (jamais jointe à Codex) : le plan en aplats + Dresseurs et lignes de
	vue, PNJ, objets (visibles / cachés), Pokémon d'ambiance, zones et repères, étiquetés ;
	réduite à [largeur] px de large."""
	from PIL import ImageFont
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_check import FACINGS, FORET_PROFILS, nommer_zones  # noqa: E402
	plan = lire(grille)
	img = Image.open(plan_png).convert("RGBA")
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	case = min(CASE, TAILLE[0] // plan.width, TAILLE[1] // plan.height)
	ox = (TAILLE[0] - plan.width * case) // 2
	oy = (TAILLE[1] - plan.height * case) // 2
	def fonte(taille: int):
		for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
			try:
				return ImageFont.truetype(chemin, taille)
			except OSError:
				continue
		return ImageFont.load_default(size=taille)
	police = fonte(15)
	petite = fonte(12)

	def centre(c: tuple[int, int]) -> tuple[float, float]:
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def etiquette(c, texte: str, couleur, f=police, dx: float = 0, dy: float = -14) -> None:
		cx, cy = centre(c)
		x, y = cx + dx, cy + dy
		box = d.textbbox((x, y), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 170))
		d.text((x, y), texte, font=f, fill=couleur, anchor="mm")

	for p in plan.of_kind("dresseur"):
		fx, fy = FACINGS[p.attrs["facing"]]
		c = p.cells[0]
		for k in range(1, int(p.attrs["sight"]) + 1):
			x0, y0 = ox + (c[0] + fx * k) * case, oy + (c[1] + fy * k) * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(230, 40, 40, 110))
		cx, cy = centre(c)
		d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		etiquette(c, p.attrs.get("role", "?"), (255, 140, 140, 255))
	for p in plan.of_kind("pnj"):
		for c in p.cells:
			cx, cy = centre(c)
			d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(70, 140, 255, 255))
		etiquette(p.cells[len(p.cells) // 2], p.attrs.get("role", "?"), (150, 190, 255, 255))
	for p in plan.of_kind("objet_visible") + plan.of_kind("objet_cache"):
		c = p.cells[0]
		cx, cy = centre(c)
		if p.kind == "objet_cache":
			d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 220, 40, 255),
				outline=(0, 0, 0, 255))
		etiquette(c, p.attrs.get("role", "?") + ("*" if p.kind == "objet_cache" else ""),
			(255, 230, 90, 255))
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(200, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.ident.split("_")[0][:4], (225, 170, 245, 255), petite, dy=12)
	profil = FORET_PROFILS.get(grille.stem, FORET_PROFILS["viridian_forest"])
	for nom, zone in nommer_zones(plan, profil["zones"]).items():
		xs = sorted(x for x, _ in zone)
		ys = sorted(y for _, y in zone)
		etiquette((xs[len(xs) // 2], ys[len(ys) // 2]), nom, (240, 255, 150, 255), dy=0)
	for p in plan.of_kind("clairiere"):
		role = p.attrs.get("role", "")
		if role.startswith("C"):
			etiquette(p.cells[-1], role, (255, 255, 255, 255), dx=-12, dy=-6)
	for car, nom in (("I", "tronc incliné"), ("S", "grande souche"), ("L", "rai de lumière"),
			("r", "racines")):
		cases = plan.cells_of(car)
		if cases:
			etiquette(cases[0], nom, (255, 220, 180, 255), petite, dy=-12)
	for p in plan.of_kind("spawn"):
		etiquette(p.cells[0], p.ident, (180, 255, 255, 255), petite, dx=0, dy=12)
	img = Image.alpha_composite(img, calque).convert("RGB")
	hauteur = round(img.height * largeur / img.width)
	img = img.resize((largeur, hauteur), Image.LANCZOS)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


# --- Route 3 (jalon 12, dossier 15 §3) ------------------------------------------------------
# Légende de tools/plans/route_3.txt. Format PAYSAGE 1536 × 1024 (Codex le produit, comme les
# coques d'intérieur de la série 12) : la route fait 82 × 38 cases, elle tient à 18 px par case
# (1476 × 684) ; en portrait elle tomberait à 12 px par case. Les marges prolongent les cases du
# bord (forêt, montagne, chemin d'Argenta à l'ouest), sans rien inventer.
TAILLE_PAYSAGE = (1536, 1024)
R3_HERBE_SECHE = (128, 150, 74)     # herbe rase de l'est, plus sèche (§7 : herbes qui se raréfient)
R3_SOL_ROCHEUX = (176, 168, 150)    # o : sol rocheux praticable, pied de la montagne
R3_AFFLEUREMENT = (150, 143, 132)   # R : affleurements et rochers (bloqués)
R3_PAROI = (122, 112, 100)          # K : paroi de la montagne
R3_PAROI_PROFONDE = (98, 90, 84)    # K loin de tout passage : la masse qui monte
R3_STRATE = (108, 99, 89)
R3_GROTTE = (28, 26, 34)            # Q : ouverture de la grotte
R3_GROTTE_BORD = (70, 64, 60)
R3_FOND = {
	"T": FORET, ".": HERBE, "=": CHEMIN, "h": HAUTES_HERBES, "v": REBORD, "o": R3_SOL_ROCHEUX,
	"K": R3_PAROI, "R": R3_AFFLEUREMENT, "x": HERBE, "C": BATIMENTS["C"][0], "D": PORTE,
	"Q": R3_PAROI,
}
R3_HERBE_FIN = 60                   # colonne où l'herbe rase est la plus sèche


def _geometrie(plan: Plan, taille: tuple[int, int]) -> tuple[int, int, int]:
	case = min(CASE, taille[0] // plan.width, taille[1] // plan.height)
	return case, (taille[0] - plan.width * case) // 2, (taille[1] - plan.height * case) // 2


def dessiner_route_3(grille: Path, sortie: Path) -> Path:
	"""Plan en aplats de la Route 3, paysage 1536 × 1024. Personnages, Pokémon, case cachée et
	coupes d'itinéraire NON dessinés (le plan est joint à Codex) ; Poké Balls des objets visibles
	et panneaux dessinés."""
	plan = lire(grille)
	case, ox, oy = _geometrie(plan, TAILLE_PAYSAGE)
	img = Image.new("RGB", TAILLE_PAYSAGE, FORET)
	d = ImageDraw.Draw(img)
	alea = random.Random(GRAINE + 3)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def bord(x: int, y: int) -> str:
		return plan.at(min(max(x, 0), plan.width - 1), min(max(y, 0), plan.height - 1))

	# Profondeur de la paroi : distance (en cases) à la plus proche case non-paroi.
	paroi = set(plan.cells_of("K"))
	profondeur: dict[tuple[int, int], int] = {}
	front = [c for c in paroi if any(
		0 <= c[0] + dx < plan.width and 0 <= c[1] + dy < plan.height
		and plan.at(c[0] + dx, c[1] + dy) != "K" for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
	for c in front:
		profondeur[c] = 1
	while front:
		suivant = []
		for x, y in front:
			for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				n = (x + dx, y + dy)
				if n in paroi and n not in profondeur:
					profondeur[n] = profondeur[(x, y)] + 1
					suivant.append(n)
		front = suivant

	def couleur(car: str, x: int, y: int):
		if car == ".":
			return _melange(HERBE, R3_HERBE_SECHE, min(1.0, max(0.0, x / R3_HERBE_FIN)))
		if car == "K":
			p = profondeur.get((min(max(x, 0), plan.width - 1), min(max(y, 0), plan.height - 1)), 6)
			hors = x < 0 or y < 0 or x >= plan.width or y >= plan.height
			return _melange(R3_PAROI, R3_PAROI_PROFONDE, 1.0 if hors else min(1.0, (p - 1) / 4))
		return R3_FOND[car]

	# 1. Aplats, marges comprises (cases virtuelles = case du bord la plus proche).
	gx0, gy0 = -(ox // case) - 1, -(oy // case) - 1
	gx1, gy1 = plan.width + (TAILLE_PAYSAGE[0] - ox) // case + 1, \
		plan.height + (TAILLE_PAYSAGE[1] - oy) // case + 1
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			car = bord(x, y)
			if not (0 <= x < plan.width and 0 <= y < plan.height) and car not in "TKR=":
				car = "T"
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleur(car, x, y))

	# 2. Strates de la paroi (traits horizontaux) et blocs des affleurements.
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			car = bord(x, y)
			x0, y0 = coin(x, y)
			if car == "K" and (x + 2 * y) % 5 == 0:
				d.line([x0 + 2, y0 + case // 2, x0 + case - 3, y0 + case // 2], fill=R3_STRATE,
					width=2)
			elif car == "R" and alea.random() < 0.45:
				cx, cy = x0 + case / 2, y0 + case / 2
				_disque(d, cx + alea.uniform(-3, 3), cy + alea.uniform(-3, 3),
					alea.uniform(4, 7), PIERRE, PIERRE_BORD)

	# 3. Fleurs dans la prairie de la sortie (aucune à l'est).
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			part = 0.25 * max(0.0, 1 - x / 24)
			if c == "." and alea.random() < part:
				cx, cy = centre(x, y)
				_disque(d, cx + alea.uniform(-4, 4), cy + alea.uniform(-4, 4), 2, FLEUR)

	# 4. Buissons, rebords (bande sombre en bas de la case : la marche vers le sud).
	for x, y in plan.cells_of("x"):
		cx, cy = centre(x, y)
		_disque(d, cx, cy, case * 0.4, BUISSON, SOMBRE_BORD)
	for x, y in plan.cells_of("v"):
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case // 2], fill=_melange(REBORD, PAROI, 0.3))
		d.rectangle([x0, y0 + case // 2, x0 + case - 1, y0 + case - 1], fill=REBORD)

	# 5. Centre Pokémon : toit rouge sur les 3/5 hauts de l'emprise, portes.
	centre_cases = plan.cells_of("C") + plan.cells_of("D")
	if centre_cases:
		xs = [x for x, _ in centre_cases]
		ys = [y for _, y in centre_cases]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=BATIMENTS["C"][1])
		for x, y in plan.cells_of("D"):
			px0, py0 = coin(x, y)
			d.rectangle([px0, py0 + case // 4, px0 + case - 1, py0 + case - 1], fill=PORTE)

	# 6. Entrée du Mont Sélénite : ouverture sombre en arche dans la paroi.
	grotte = plan.cells_of("Q")
	if grotte:
		xs = [x for x, _ in grotte]
		ys = [y for _, y in grotte]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.pieslice([x0 - 2, y0 - case * 0.8, x1 + 1, y1 + case * 0.8], 180, 360, fill=R3_GROTTE,
			outline=R3_GROTTE_BORD, width=2)
		d.rectangle([x0 - 2, y0 + case * 0.4, x1 + 1, y1 - 1], fill=R3_GROTTE)

	# 7. Panneaux et objets visibles (la case cachée « cache » n'est JAMAIS dessinée ici).
	for p in plan.of_kind("panneau"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			d.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=PANNEAU, outline=PANNEAU_BORD)
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


def annoter_route_3(grille: Path, plan_png: Path, sortie: Path) -> Path:
	"""Version de RELECTURE de la Route 3 (jamais jointe à Codex) : Dresseurs et lignes de vue,
	PNJ, objets (la case cachée en jaune, « * »), Pokémon d'ambiance, zones d'herbes, rebords,
	coupes d'itinéraire, points d'apparition, repères ; même taille que le plan."""
	from PIL import ImageFont
	from plan_check import FACINGS, nommer_zones  # noqa: E402
	plan = lire(grille)
	img = Image.open(plan_png).convert("RGBA")
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	case, ox, oy = _geometrie(plan, TAILLE_PAYSAGE)

	def fonte(taille: int):
		for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
			try:
				return ImageFont.truetype(chemin, taille)
			except OSError:
				continue
		return ImageFont.load_default(size=taille)
	police, petite = fonte(15), fonte(11)

	def centre(c) -> tuple[float, float]:
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def etiquette(c, texte: str, couleur, f=police, dx: float = 0, dy: float = -14) -> None:
		cx, cy = centre(c)
		box = d.textbbox((cx + dx, cy + dy), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 170))
		d.text((cx + dx, cy + dy), texte, font=f, fill=couleur, anchor="mm")

	# Grille fine (repérage des coordonnées) et graduations tous les 5.
	for x in range(plan.width + 1):
		d.line([ox + x * case, oy, ox + x * case, oy + plan.height * case],
			fill=(0, 0, 0, 60 if x % 5 else 130), width=1)
	for y in range(plan.height + 1):
		d.line([ox, oy + y * case, ox + plan.width * case, oy + y * case],
			fill=(0, 0, 0, 60 if y % 5 else 130), width=1)
	for x in range(0, plan.width, 5):
		d.text((ox + (x + 0.5) * case, oy - 10), str(x), font=petite, fill=(255, 255, 255, 255),
			anchor="mm")
	for y in range(0, plan.height, 5):
		d.text((ox - 12, oy + (y + 0.5) * case), str(y), font=petite, fill=(255, 255, 255, 255),
			anchor="mm")

	for p in plan.of_kind("itineraire"):
		xs = [x for x, _ in p.cells]
		ys = [y for _, y in p.cells]
		d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1,
			oy + (max(ys) + 1) * case - 1], outline=(255, 255, 255, 150), width=2)
		etiquette((min(xs), min(ys)), f"itinéraire {p.attrs.get('role')}", (255, 255, 255, 255),
			petite, dx=30, dy=-4)
	for p in plan.of_kind("dresseur"):
		fx, fy = FACINGS[p.attrs["facing"]]
		c = p.cells[0]
		for k in range(1, int(p.attrs["sight"]) + 1):
			x0, y0 = ox + (c[0] + fx * k) * case, oy + (c[1] + fy * k) * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(230, 40, 40, 120))
		cx, cy = centre(c)
		d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		etiquette(c, f"{p.attrs.get('role')} {p.ident}", (255, 150, 150, 255))
	for p in plan.of_kind("pnj"):
		for c in p.cells:
			cx, cy = centre(c)
			d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(70, 140, 255, 255),
				outline=(0, 0, 0, 255))
		etiquette(p.cells[0], f"{p.attrs.get('role')} {p.ident}", (160, 200, 255, 255))
	for p in plan.of_kind("objet_visible") + plan.of_kind("cache"):
		c = p.cells[0]
		cx, cy = centre(c)
		if p.kind == "cache":
			d.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 220, 40, 255),
				outline=(0, 0, 0, 255))
		etiquette(c, f"{p.attrs.get('role')}{'*' if p.kind == 'cache' else ''} "
			f"{p.attrs.get('item')}", (255, 230, 90, 255), petite, dy=13)
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(200, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.ident.split("_")[0], (225, 170, 245, 255), petite, dy=12)
	for nom, zone in nommer_zones(plan, ("H1", "H2", "H3", "H4")).items():
		xs = sorted(x for x, _ in zone)
		ys = sorted(y for _, y in zone)
		etiquette((xs[len(xs) // 2], ys[len(ys) // 2]), nom, (240, 255, 150, 255), dy=0)
	rebords = sorted(plan.cells_of("v"))
	groupes: list[list[tuple[int, int]]] = []
	for c in rebords:
		if groupes and groupes[-1][-1] == (c[0] - 1, c[1]):
			groupes[-1].append(c)
		else:
			groupes.append([c])
	for i, g in enumerate(sorted(groupes, key=lambda g: -g[0][0]), 1):
		etiquette(g[len(g) // 2], f"L{i} ↓", (255, 210, 160, 255), petite, dy=12)
	for p in plan.of_kind("spawn"):
		etiquette(p.cells[0], p.ident, (180, 255, 255, 255), petite, dx=0, dy=12)
	grotte = plan.cells_of("Q")
	if grotte:
		etiquette(grotte[0], "MONT SÉLÉNITE (1F)", (255, 255, 255, 255), dx=case / 2, dy=-22)
	porte = plan.cells_of("D")
	if porte:
		etiquette(porte[0], "CENTRE", (255, 255, 255, 255), dx=case / 2, dy=-40)
	etiquette((0, 26), "← ARGENTA (51, 25..27)", (255, 255, 255, 255), petite, dx=60, dy=-30)
	img = Image.alpha_composite(img, calque).convert("RGB")
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


# Grille → (fonction, sortie par défaut).
PLANS = {
	"route_2": (dessiner, "build/art/PLAN_ROUTE2_v1.png"),
	"viridian_forest": (dessiner_foret, "build/art/PLAN_FORET_JADE_v2.png"),
	"route_3": (dessiner_route_3, "build/art/PLAN_ROUTE3_v1.png"),
}


def main() -> int:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	if "--empiler" in sys.argv:
		nord, sud, dx, sortie = args[0], args[1], int(args[2]), Path(args[3])
		print(dessiner(empiler(lire(Path(nord)), lire(Path(sud)), dx), sortie))
		return 0
	grille = Path(args[0]) if len(args) > 0 else RACINE / "tools/plans/route_2.txt"
	fonction, defaut = PLANS.get(grille.stem, PLANS["route_2"])
	sortie = Path(args[1]) if len(args) > 1 else RACINE / defaut
	if fonction is dessiner:
		print(dessiner(grille, sortie, "--lisiere" in sys.argv))
	else:
		print(fonction(grille, sortie))
	if fonction is dessiner_foret and "--annote" in sys.argv:
		print(annoter_foret(grille, sortie, sortie.with_name(sortie.stem + "_annote.png")))
	if fonction is dessiner_route_3 and "--annote" in sys.argv:
		print(annoter_route_3(grille, sortie, sortie.with_name(sortie.stem + "_annote.png")))
	return 0


if __name__ == "__main__":
	sys.exit(main())
