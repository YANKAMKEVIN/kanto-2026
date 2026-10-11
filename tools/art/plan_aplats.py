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
--mont-selenite [sortie.png] [--annote] (J12, dossier 15) : les trois étages du Mont Sélénite
empilés (1F, B1F, B2F) → build/art/PLAN_MONT_SELENITE_v1.png ; --annote ajoute
<sortie>_annote.png (échelles, Dresseurs, objets cachés… : JAMAIS jointe à Codex).
tools/plans/route_4_sas.txt → build/art/PLAN_ROUTE4_SAS_v1.png (`dessiner_sas`).
tools/plans/route_25.txt → build/art/PLAN_ROUTE25_v1.png (J14, `dessiner_route_25`) : PAYSAGE,
mer, rivage, falaise, plage, maison de Léo ; --annote comme la Route 3.
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


# --- Mont Sélénite et sas de la Route 4 (jalon 12, dossier 15) --------------------------------
# Légende de tools/plans/mont_selenite_*.txt. Ardoise, pierre froide, gris bleuté ; les étages
# s'assombrissent en descendant (transitions de lumière progressives, dossier 15 §5.1) ; lampes
# Rocket et puits de jour éclairent le sol autour d'eux ; éclats de Pierre Lune bleu-blanc.
G_FOND = (24, 25, 31)               # roche autour des étages et bandes de séparation
G_ETAGES = {
	# étage : (paroi, sol calme, gravats)
	"1F": ((66, 68, 80), (132, 134, 140), (150, 128, 98)),
	"B1F": ((58, 60, 72), (114, 117, 126), (138, 117, 90)),
	"B2F": ((52, 54, 66), (100, 104, 116), (128, 108, 84)),
}
G_GRAVIER = (96, 82, 64)
G_JOUR = (214, 216, 196)            # puits de jour
G_DEHORS = (222, 214, 172)          # entrée vers la Route 3 (lumière du dehors)
G_ROCHER = (82, 84, 96)
G_ROCHER_BORD = (40, 42, 52)
G_COLONNE = (92, 92, 106)
G_ECHELLE = (176, 124, 66)
G_ECHELLE_BORD = (92, 60, 30)
G_TROU = (14, 14, 18)
G_LAMPE = (255, 206, 90)
G_LUEUR = (232, 192, 116)
G_CAISSE = (138, 98, 60)
G_CAISSE_BORD = (70, 48, 28)
G_R = (214, 36, 36)
G_FOUILLE = (86, 68, 50)
G_FOUILLE_TRAIT = (60, 46, 34)
G_DALLE = (200, 194, 176)
G_DALLE_BORD = (120, 114, 100)
G_FOSSILE = (150, 112, 70)
G_ECLAT = (196, 226, 255)
G_ECLAT_HALO = (120, 150, 190)
G_INDICE = (196, 192, 170)
G_EAU = (36, 62, 94)
G_EAU_REFLET = (70, 104, 140)
LAMPE_RAYON = 4.5                  # cases éclairées autour d'une lampe (lueur au sol)
JOUR_RAYON = 2.5
G_GRILLES = ("mont_selenite_1f", "mont_selenite_b1f", "mont_selenite_b2f")
G_NOMS = {"mont_selenite_1f": "1F", "mont_selenite_b1f": "B1F", "mont_selenite_b2f": "B2F"}
G_BANDE = 2                        # rangées de roche entre deux étages


def _sources(plan: Plan, car: str) -> list[tuple[int, int]]:
	return plan.cells_of(car)


def _lueur(c: tuple[int, int], sources: list[tuple[int, int]], rayon: float) -> float:
	best = 0.0
	for sx, sy in sources:
		dist = ((c[0] - sx) ** 2 + (c[1] - sy) ** 2) ** 0.5
		best = max(best, 1.0 - dist / rayon)
	return best


def _peindre_grotte(d: ImageDraw.ImageDraw, plan: Plan, etage: str, ox: int, oy: int,
		case: int) -> None:
	"""Aplats d'un étage de grotte à (ox, oy), 1 case = case px. Objets cachés non dessinés."""
	paroi, sol, gravats = G_ETAGES[etage]
	alea = random.Random(GRAINE + len(etage) * 7 + plan.width)
	lampes = _sources(plan, "L")
	jour = _sources(plan, "j")
	k = case / CASE

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	sol_de = {".": sol, "g": gravats, "j": G_JOUR, "E": G_DEHORS, "U": sol, "V": sol, "o": sol,
		"K": sol, "R": sol, "x": sol, "S": sol}
	# 1. Aplats : paroi, sol, gravats ; lueur des lampes et du jour sur le sol.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if c in sol_de:
				fond = sol_de[c]
				if c not in "jE":
					t = _lueur((x, y), lampes, LAMPE_RAYON)
					if t > 0:
						fond = _melange(fond, G_LUEUR, 0.6 * t)
					t = _lueur((x, y), jour, JOUR_RAYON)
					if t > 0:
						fond = _melange(fond, G_JOUR, 0.45 * t)
			elif c == "F":
				fond = G_FOUILLE
			elif c == "w":
				fond = G_EAU
			else:
				fond = paroi
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=fond)
			if c == "g":
				for _ in range(3):
					px, py = x0 + alea.uniform(2, case - 3), y0 + alea.uniform(2, case - 3)
					_disque(d, px, py, alea.uniform(1.2, 2.4) * k * 1.4, G_GRAVIER)
	# 2. Symboles.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			cx, cy = centre(x, y)
			x0, y0 = coin(x, y)
			r = case / 2
			if c == "o":
				_disque(d, cx, cy, r * 0.8, G_ROCHER, G_ROCHER_BORD)
			elif c == "x":
				_disque(d, cx + r * 0.2, cy + r * 0.1, r * 0.32, G_INDICE)
			elif c == "F":
				for i in (0.3, 0.6):
					d.line([x0 + 1, y0 + case * i, x0 + case - 2, y0 + case * i],
						fill=G_FOUILLE_TRAIT, width=max(1, round(2 * k)))
			elif c == "w":
				d.line([x0 + case * 0.2, cy, x0 + case * 0.7, cy], fill=G_EAU_REFLET,
					width=max(1, round(2 * k)))
			elif c == "R":
				d.rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=G_CAISSE,
					outline=G_CAISSE_BORD)
				d.rectangle([cx - r * 0.25, cy - r * 0.4, cx + r * 0.25, cy + r * 0.4], fill=G_R)
			elif c == "L":
				_disque(d, cx, cy, r * 0.55, G_LAMPE, G_ECHELLE_BORD)
			elif c == "*":
				_disque(d, cx, cy, r * 0.75, G_ECLAT_HALO)
				d.polygon([(cx, cy - r * 0.8), (cx + r * 0.45, cy), (cx, cy + r * 0.8),
					(cx - r * 0.45, cy)], fill=G_ECLAT)
			elif c in "UV":
				if c == "V":
					_disque(d, cx, cy, r * 0.95, G_TROU)
				else:
					_disque(d, cx, cy, r * 0.95, _melange(sol, G_JOUR, 0.5))
				for dx in (-0.45, 0.45):
					d.line([cx + dx * r, y0 + 1, cx + dx * r, y0 + case - 2], fill=G_ECHELLE,
						width=max(2, round(2 * k)))
				for i in (0.25, 0.5, 0.75):
					d.line([cx - 0.45 * r, y0 + case * i, cx + 0.45 * r, y0 + case * i],
						fill=G_ECHELLE, width=max(1, round(2 * k)))
	# Colonnes : un bloc arrondi sur chaque composante.
	for groupe in _composantes(plan, "K"):
		xs = [x for x, _ in groupe]
		ys = [y for _, y in groupe]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rounded_rectangle([x0 - 1, y0 - 1, x1, y1], radius=case * 0.45, fill=G_COLONNE,
			outline=G_ROCHER_BORD, width=max(1, round(2 * k)))
	# Dalle des fossiles et fossiles posés dessus.
	for groupe in _composantes(plan, "S"):
		xs = [x for x, _ in groupe]
		ys = [y for _, y in groupe]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0 + 2, x1 - 1, y1 - 3], fill=G_DALLE, outline=G_DALLE_BORD,
			width=max(1, round(2 * k)))
	for p in plan.of_kind("fossile"):
		cx, cy = centre(*p.cells[0])
		r = case * 0.36
		if "dome" in p.attrs.get("item", ""):
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=G_FOSSILE,
				outline=G_CAISSE_BORD)
			d.line([cx - r, cy, cx + r, cy], fill=G_CAISSE_BORD, width=max(1, round(2 * k)))
		else:
			_disque(d, cx, cy, r, G_FOSSILE, G_CAISSE_BORD)
			_disque(d, cx + r * 0.2, cy, r * 0.45, G_FOSSILE, G_CAISSE_BORD)
	# Objets visibles : Poké Balls.
	for p in plan.of_kind("objet_visible"):
		cx, cy = centre(*p.cells[0])
		r = max(4, round(case * 0.3))
		d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=BALL_ROUGE)
		d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=BLANC)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=BALL_BORD, width=1)
	# Panneau d'entrée.
	for p in plan.of_kind("panneau"):
		cx, cy = centre(*p.cells[0])
		r = case * 0.3
		d.rectangle([cx - r, cy - r, cx + r, cy + r], fill=PANNEAU, outline=PANNEAU_BORD)


def _fonte(taille: int):
	from PIL import ImageFont
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
		try:
			return ImageFont.truetype(chemin, taille)
		except OSError:
			continue
	return ImageFont.load_default(size=taille)


def _annoter_grotte(img: Image.Image, plans: list[tuple[str, Plan, int, int]], case: int) -> Image.Image:
	"""Version de RELECTURE (jamais jointe à Codex) : étages, échelles (paire, sens), Dresseurs et
	lignes de vue, PNJ, objets visibles (O) et cachés (C*), fossiles, zones de gravats, repères."""
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_check import FACINGS  # noqa: E402
	from plan_check_mont_selenite import zones_gravats  # noqa: E402
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	police, petite, grande = _fonte(14), _fonte(11), _fonte(22)

	def etiquette(x: float, y: float, texte: str, couleur, f=police) -> None:
		box = d.textbbox((x, y), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 180))
		d.text((x, y), texte, font=f, fill=couleur, anchor="mm")

	for nom, plan, ox, oy in plans:
		def centre(c, ox=ox, oy=oy):
			return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case
		etiquette(ox - 30 if ox > 40 else ox + 30, oy + 16, G_NOMS.get(nom, nom),
			(255, 255, 255, 255), grande)
		for zone, p in ((z, p) for z in zones_gravats(plan) for p in plan.of_kind("gravats")
				if p.cells[0] in z):
			xs = sorted(x for x, _ in zone)
			ys = sorted(y for _, y in zone)
			etiquette(*centre((xs[len(xs) // 2], ys[len(ys) // 2])), p.attrs["role"],
				(255, 220, 160, 255))
		for p in plan.of_kind("echelle"):
			fleche = "↑" if p.attrs["sens"] == "monte" else "↓"
			cx, cy = centre(p.cells[0])
			etiquette(cx, cy - case * 1.1, f"{p.attrs['paire']}{fleche}", (140, 255, 140, 255))
		for p in plan.of_kind("dresseur"):
			c = p.cells[0]
			if p.attrs.get("facing") and int(p.attrs.get("sight", "0")):
				fx, fy = FACINGS[p.attrs["facing"]]
				for kk in range(1, int(p.attrs["sight"]) + 1):
					x0, y0 = ox + (c[0] + fx * kk) * case, oy + (c[1] + fy * kk) * case
					d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(230, 40, 40, 120))
			cx, cy = centre(c)
			d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(230, 40, 40, 255),
				outline=(0, 0, 0, 255))
			texte = p.attrs["role"] + (" !" if p.attrs.get("inevitable") == "oui" else "")
			etiquette(cx, cy - case * 1.1, texte, (255, 150, 150, 255))
			if "apres" in p.attrs:
				ax, ay = (int(v) for v in p.attrs["apres"].split(","))
				ex, ey = centre((ax, ay))
				d.ellipse([ex - 3, ey - 3, ex + 3, ey + 3], outline=(255, 150, 150, 255))
		for p in plan.of_kind("pnj"):
			cx, cy = centre(p.cells[0])
			d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(70, 140, 255, 255))
			etiquette(cx, cy - case * 1.1, "randonneur", (150, 190, 255, 255), petite)
		for p in plan.of_kind("objet_visible") + plan.of_kind("objet_cache"):
			cx, cy = centre(p.cells[0])
			if p.kind == "objet_cache":
				d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 220, 40, 255),
					outline=(0, 0, 0, 255))
			etiquette(cx, cy + case * 1.1, f"{p.attrs.get('role', '?')} {p.attrs.get('item', '')}"
				+ ("*" if p.kind == "objet_cache" else ""), (255, 230, 90, 255), petite)
		for p in plan.of_kind("repere"):
			xs = sorted(x for x, _ in p.cells)
			ys = sorted(y for _, y in p.cells)
			etiquette(*centre((xs[len(xs) // 2], ys[len(ys) // 2])),
				p.ident.replace("repere_", "").replace("_", " "), (200, 230, 255, 255), petite)
	return Image.alpha_composite(img.convert("RGBA"), calque).convert("RGB")


def dessiner_mont_selenite(sortie: Path, annote: bool = False) -> list[Path]:
	"""Les trois étages empilés (1F en haut, B1F, B2F), séparés par une bande de roche, sur fond
	de roche sombre ; 1024 × 1536. Le sas de la Route 4 a son image à part (dessiner_sas)."""
	plans = [(n, lire(RACINE / "tools" / "plans" / f"{n}.txt")) for n in G_GRILLES]
	largeur = max(p.width for _, p in plans)
	hauteur = sum(p.height for _, p in plans) + G_BANDE * (len(plans) - 1)
	case = min(CASE, TAILLE[0] // largeur, TAILLE[1] // hauteur)
	img = Image.new("RGB", TAILLE, G_FOND)
	d = ImageDraw.Draw(img)
	oy = (TAILLE[1] - hauteur * case) // 2
	places = []
	for nom, plan in plans:
		ox = (TAILLE[0] - plan.width * case) // 2
		_peindre_grotte(d, plan, G_NOMS[nom], ox, oy, case)
		# Lumière du dehors : l'entrée du 1F déborde d'une rangée dans la bande.
		for x, y in plan.cells_of("E"):
			d.rectangle([ox + x * case, oy + (y + 1) * case, ox + (x + 1) * case - 1,
				oy + (y + 2) * case - 1], fill=_melange(G_DEHORS, G_FOND, 0.4))
		places.append((nom, plan, ox, oy))
		oy += (plan.height + G_BANDE) * case
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	sorties = [sortie]
	if annote:
		chemin = sortie.with_name(sortie.stem + "_annote.png")
		_annoter_grotte(img, places, case).save(chemin)
		sorties.append(chemin)
	return sorties


# Sas de la Route 4 (extérieur) : herbe sèche de piémont, paroi du versant, plaine en contrebas.
S_HERBE = (118, 150, 78)
S_PAROI = (128, 120, 108)
S_PAROI_FOND = (104, 98, 90)
S_PLAINE = (156, 178, 104)
S_GROTTE = (22, 22, 28)
S_FOND_CASE = {".": S_HERBE, "=": CHEMIN, "e": CHEMIN, "#": S_PAROI, "D": S_PAROI, "o": S_HERBE,
	"~": REBORD, "b": S_HERBE}


def dessiner_sas(grille: Path, sortie: Path) -> Path:
	"""Sas de la Route 4 sur 1024 × 1536 : la montagne au-dessus et à l'ouest, la plaine en
	contrebas au sud, le chemin prolongé vers l'est jusqu'au bord de l'image."""
	plan = lire(grille)
	case = min(TAILLE[0] // plan.width, 42)
	img = Image.new("RGB", TAILLE, S_PAROI_FOND)
	d = ImageDraw.Draw(img)
	ox = (TAILLE[0] - plan.width * case) // 2
	oy = (TAILLE[1] - plan.height * case) // 2
	d.rectangle([0, oy + plan.height * case, TAILLE[0], TAILLE[1]], fill=S_PLAINE)
	d.rectangle([ox + plan.width * case, oy + 3 * case, TAILLE[0], oy + plan.height * case],
		fill=_melange(S_HERBE, S_PLAINE, 0.5))
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = ox + x * case, oy + y * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=S_FOND_CASE[c])
			if c == "~":
				d.rectangle([x0, y0 + case * 0.6, x0 + case - 1, y0 + case - 1],
					fill=_melange(REBORD, (0, 0, 0), 0.3))
			if c == "e":
				d.rectangle([x0, y0, TAILLE[0], y0 + case - 1], fill=CHEMIN)
			if c == "o":
				_disque(d, x0 + case / 2, y0 + case / 2, case * 0.4, PIERRE, PIERRE_BORD)
			if c == "b":
				_disque(d, x0 + case / 2, y0 + case / 2, case * 0.55, BUISSON, SOMBRE_BORD)
	# Bouche de la grotte creusée dans la paroi ouest, ouverte vers l'est (par-dessus le chemin).
	for x, y in plan.cells_of("D"):
		x0, y0 = ox + x * case, oy + y * case
		d.ellipse([x0 - case * 0.5, y0 - case * 0.4, x0 + case * 1.2, y0 + case * 1.4],
			fill=S_GROTTE, outline=_melange(S_PAROI, (0, 0, 0), 0.4), width=3)
	for p in plan.of_kind("panneau"):
		cx, cy = ox + (p.cells[0][0] + 0.5) * case, oy + (p.cells[0][1] + 0.5) * case
		d.rectangle([cx - 9, cy - 9, cx + 9, cy + 9], fill=PANNEAU, outline=PANNEAU_BORD, width=2)
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
	route_25 = grille.stem == "route_25"
	if porte:
		etiquette(porte[0], "MAISON DE LÉO" if route_25 else "CENTRE", (255, 255, 255, 255),
			dx=case / 2, dy=-40)
	if route_25:
		etiquette((0, 14), "← ROUTE 24 (relais J13)", (255, 255, 255, 255), petite, dx=60, dy=-30)
	else:
		etiquette((0, 26), "← ARGENTA (51, 25..27)", (255, 255, 255, 255), petite, dx=60, dy=-30)
	img = Image.alpha_composite(img, calque).convert("RGB")
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


# Légende de tools/plans/route_25.txt (jalon 14, brouillon). PAYSAGE 1536 × 1024 comme la Route 3 :
# 80 × 32 cases à 19 px. Mer au sud et à l'est, rivage rocheux, falaise au nord, plage, maison de
# Léo (toit bleu-gris, distinct du Centre), massifs de fleurs. Les marges prolongent les cases du
# bord (mer, falaise, forêt), sans rien inventer.
R25_MER = (52, 120, 170)
R25_MER_PROFONDE = (34, 88, 140)
R25_RIVAGE = (150, 143, 132)        # R : rochers et rivage rocheux (bloqués)
R25_FALAISE = (132, 120, 104)       # K : falaise
R25_SABLE = (226, 210, 160)         # s : plage
R25_MASSIF = (205, 120, 160)        # f : massif de fleurs (bloqué)
R25_MAISON_MUR = (215, 205, 185)
R25_MAISON_TOIT = (80, 105, 140)
R25_FOND = {
	"T": FORET, ".": HERBE, "=": CHEMIN, "h": HAUTES_HERBES, "v": REBORD, "s": R25_SABLE,
	"K": R25_FALAISE, "R": R25_RIVAGE, "x": HERBE, "w": R25_MER, "f": HERBE,
	"M": R25_MAISON_MUR, "D": PORTE,
}


def dessiner_route_25(grille: Path, sortie: Path) -> Path:
	"""Plan en aplats de la Route 25 et du Cap d'Azuria, paysage 1536 × 1024. Personnages,
	Pokémon et case cachée NON dessinés (le plan est joint à Codex) ; Poké Balls des objets
	visibles et panneaux dessinés."""
	plan = lire(grille)
	case, ox, oy = _geometrie(plan, TAILLE_PAYSAGE)
	img = Image.new("RGB", TAILLE_PAYSAGE, R25_MER)
	d = ImageDraw.Draw(img)
	alea = random.Random(GRAINE + 25)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def bord(x: int, y: int) -> str:
		return plan.at(min(max(x, 0), plan.width - 1), min(max(y, 0), plan.height - 1))

	mer = set(plan.cells_of("w"))

	def couleur(car: str, x: int, y: int):
		if car == "w":
			# La mer fonce en s'éloignant du rivage (distance au bord praticable approchée).
			loin = min([abs(y - 24), abs(x - 78)] if x < plan.width and y < plan.height else [8])
			return _melange(R25_MER, R25_MER_PROFONDE, min(1.0, max(0.0, (loin - 1) / 6)))
		return R25_FOND[car]

	# 1. Aplats, marges comprises (cases virtuelles = case du bord la plus proche).
	gx0, gy0 = -(ox // case) - 1, -(oy // case) - 1
	gx1, gy1 = plan.width + (TAILLE_PAYSAGE[0] - ox) // case + 1, \
		plan.height + (TAILLE_PAYSAGE[1] - oy) // case + 1
	for y in range(gy0, gy1):
		for x in range(gx0, gx1):
			car = bord(x, y)
			if not (0 <= x < plan.width and 0 <= y < plan.height) and car not in "TKRw=":
				car = "T"
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleur(car, x, y))

	# 2. Strates de la falaise, galets du rivage, écume au bord de la mer.
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
	for x, y in mer:
		if any(bord(x + dx, y + dy) == "R" for dx, dy in ((0, -1), (-1, 0))):
			x0, y0 = coin(x, y)
			d.line([x0, y0 + 2, x0 + case - 1, y0 + 2], fill=BLANC, width=2)

	# 3. Fleurs : quelques-unes dans l'herbe, massifs denses autour de la maison.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if c == "." and alea.random() < (0.22 if x >= 56 else 0.08):
				cx, cy = centre(x, y)
				_disque(d, cx + alea.uniform(-4, 4), cy + alea.uniform(-4, 4), 2, FLEUR)
			elif c == "f":
				for _ in range(4):
					cx, cy = centre(x, y)
					_disque(d, cx + alea.uniform(-6, 6), cy + alea.uniform(-6, 6), 3, R25_MASSIF)

	# 4. Buissons, rebords.
	for x, y in plan.cells_of("x"):
		cx, cy = centre(x, y)
		_disque(d, cx, cy, case * 0.4, BUISSON, SOMBRE_BORD)
	for x, y in plan.cells_of("v"):
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case // 2], fill=_melange(REBORD, PAROI, 0.3))
		d.rectangle([x0, y0 + case // 2, x0 + case - 1, y0 + case - 1], fill=REBORD)

	# 5. Maison de Léo : toit sur les 3/5 hauts de l'emprise, porte.
	maison = plan.cells_of("M") + plan.cells_of("D")
	if maison:
		xs = [x for x, _ in maison]
		ys = [y for _, y in maison]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=R25_MAISON_TOIT)
		for x, y in plan.cells_of("D"):
			px0, py0 = coin(x, y)
			d.rectangle([px0, py0 + case // 4, px0 + case - 1, py0 + case - 1], fill=PORTE)

	# 6. Panneaux et objets visibles (la case cachée « cache » n'est JAMAIS dessinée ici).
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


# Grille → (fonction, sortie par défaut).
PLANS = {
	"route_2": (dessiner, "build/art/PLAN_ROUTE2_v1.png"),
	"viridian_forest": (dessiner_foret, "build/art/PLAN_FORET_JADE_v2.png"),
	"route_3": (dessiner_route_3, "build/art/PLAN_ROUTE3_v1.png"),
	"route_4_sas": (dessiner_sas, "build/art/PLAN_ROUTE4_SAS_v1.png"),
	"route_25": (dessiner_route_25, "build/art/PLAN_ROUTE25_v1.png"),
}


def main() -> int:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	if "--mont-selenite" in sys.argv:
		sortie = Path(args[0]) if args else RACINE / "build/art/PLAN_MONT_SELENITE_v1.png"
		for chemin in dessiner_mont_selenite(sortie, "--annote" in sys.argv):
			print(chemin)
		return 0
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
	if fonction in (dessiner_route_3, dessiner_route_25) and "--annote" in sys.argv:
		print(annoter_route_3(grille, sortie, sortie.with_name(sortie.stem + "_annote.png")))
	return 0


if __name__ == "__main__":
	sys.exit(main())
