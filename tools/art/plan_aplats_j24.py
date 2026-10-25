#!/usr/bin/env python3
"""Plans en aplats des grilles du jalon 24 (série 27, lot 24.0 ; dossier 27 §4, §7, §9, §10).

Image 1 des vues générales peintes (méthode habituelle : plan en aplats + vue d'un AUTRE lieu
comme ancre de style). Les grilles de `tools/plans/` font foi ; ce script ne fait que les dessiner.

Trois familles de légende (le même caractère n'a pas le même sens partout) :
  - « mer » : route_19, route_20, route_21, cinnabar_island (eau surfable w, eau décor ~, récifs R,
    sable y, falaises blanches K de l'île, entrées de grotte D, bâtiments M Z L C O, gravats X…) ;
  - « grotte » : seafoam_1f … seafoam_b4f (paroi #, arête |, sol bas ., sol haut :, escalier =,
    courants ^ v < >, rocher de Force B, trou O, échelles U V, entrée E, petit rocher o, panneau n,
    caillou x) ;
  - « labo » : cinnabar_labo_* (mur K, sol ., paillasson X, porte D, photo P, plante x, table T,
    ordinateurs Q, machine M, lampe d, vitrines A, canapé S, table basse b).

Personnages et Pokémon NON dessinés (le plan est joint à Codex) ; objets visibles (Poké Ball),
panneaux, rochers de Force et trous dessinés. Les cases d'objets cachés ne sont pas marquées
(seul le caillou x, visible en jeu, l'est).

Vues (dossier 27 §14.4) — les cartes trop allongées pour un seul format de Codex sont coupées en
deux vues qui se recouvrent [D] :
  route_19                  → PLAN_ROUTE19_v1.png (portrait)
  route_20 colonnes 40..119 → PLAN_ROUTE20_v1.png (paysage) : l'île des Îles Écume, la poche,
                              l'îlot de l'Ornithologue ; les colonnes 0..39 et 120..149 ne sont
                              que de la mer entre deux récifs (même rendu) [D]
  route_21 rangées 0..67    → PLAN_ROUTE21_NORD_v1.png (portrait)
  route_21 rangées 67..134  → PLAN_ROUTE21_SUD_v1.png (portrait)
  cinnabar_island           → PLAN_CRAMOIS_ILE_v1.png (paysage)
  seafoam_1f … b4f          → PLAN_ILES_ECUME_1F_v1.png … _B4F_v1.png (paysage)
  cinnabar_labo_hall, _rd, _fossiles, _reunion → PLAN_LABO_<SALLE>_v1.png (paysage, coques) :
                            murs, sol, portes, et ce qui est fixé au mur du fond (photo,
                            ordinateurs, machine de résurrection, vitrines) ; les meubles posés
                            au sol (tables, plantes, lampe, canapé, table basse) sont des objets
                            séparés pour le tri en profondeur [D] : NON dessinés

Usage : python3 tools/art/plan_aplats_j24.py [NOM ...] [--annote]   (sans nom : tout)
        → build/plans/PLAN_*_v1.png ; --annote ajoute <sortie>_annote.png (grille, positions :
        relecture, JAMAIS jointe à Codex).
Reproductible : même grille → même image (graine fixe).
"""
from __future__ import annotations

import random
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_grille import Plan, Position, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
SORTIES = RACINE / "build" / "plans"
PAYSAGE = (1536, 1024)
PORTRAIT = (1024, 1536)
GRAINE = 27


@dataclass
class Vue:
	nom: str              # identifiant (argument de la ligne de commande)
	grille: str           # tools/plans/<grille>.txt
	famille: str          # mer | grotte | labo
	taille: tuple[int, int]
	colonnes: tuple[int, int] | None = None   # coupe (bornes incluses)
	rangees: tuple[int, int] | None = None
	ile_cramois: bool = False                 # sable noir et sol volcanique

	@property
	def sortie(self) -> Path:
		return SORTIES / f"PLAN_{self.nom.upper()}_v1.png"


VUES = [
	Vue("route19", "route_19", "mer", PORTRAIT),
	Vue("route20", "route_20", "mer", PAYSAGE, colonnes=(40, 119)),
	Vue("route21_nord", "route_21", "mer", PORTRAIT, rangees=(0, 67)),
	Vue("route21_sud", "route_21", "mer", PORTRAIT, rangees=(67, 134)),
	Vue("cramois_ile", "cinnabar_island", "mer", PAYSAGE, ile_cramois=True),
	Vue("iles_ecume_1f", "seafoam_1f", "grotte", PAYSAGE),
	Vue("iles_ecume_b1f", "seafoam_b1f", "grotte", PAYSAGE),
	Vue("iles_ecume_b2f", "seafoam_b2f", "grotte", PAYSAGE),
	Vue("iles_ecume_b3f", "seafoam_b3f", "grotte", PAYSAGE),
	Vue("iles_ecume_b4f", "seafoam_b4f", "grotte", PAYSAGE),
	Vue("labo_hall", "cinnabar_labo_hall", "labo", PAYSAGE),
	Vue("labo_rd", "cinnabar_labo_rd", "labo", PAYSAGE),
	Vue("labo_fossiles", "cinnabar_labo_fossiles", "labo", PAYSAGE),
	Vue("labo_reunion", "cinnabar_labo_reunion", "labo", PAYSAGE),
]

# --- Couleurs -----------------------------------------------------------------------------------
MER = (40, 112, 170)
MER_DECOR = (34, 98, 156)
MER_ECUME = (226, 240, 248)
RECIF = (128, 124, 116)
RECIF_CLAIR = (176, 170, 158)
SABLE = (234, 214, 160)
SABLE_REBORD = (196, 164, 104)
FALAISE_BLANCHE = (226, 230, 232)
FALAISE_OMBRE = (170, 182, 196)
GROTTE_ENTREE = (30, 34, 48)
# Cramois'Île
SOL_VOLCANIQUE = (156, 132, 114)
ROCHE_VOLCANIQUE = (92, 80, 78)
ROCHE_VOLCANIQUE_CLAIR = (122, 108, 102)
SABLE_NOIR = (88, 84, 86)
GRAVATS = (112, 96, 86)
BATIMENTS_MER = {
	"M": ((150, 136, 124), (62, 56, 56)),       # Manoir incendié : murs noircis, toit effondré
	"Z": ((226, 208, 190), (186, 78, 50)),      # Arène : toit rouge brique (volcan)
	"L": ((242, 244, 246), (168, 186, 204)),    # Labo : blanc et moderne, toit gris bleuté
	"C": pa.BATIMENTS["C"],
	"O": pa.BATIMENTS["O"],
}
# Grotte glacée (Îles Écume)
PAROI = (56, 70, 94)
PAROI_HAUT = (84, 100, 126)
SOL_BAS = (150, 172, 192)
SOL_HAUT = (200, 216, 228)
ARETE = (112, 132, 156)
ESCALIER = (176, 194, 210)
ESCALIER_TRAIT = (120, 140, 162)
EAU_GROTTE = (44, 104, 150)
EAU_GROTTE_DECOR = (36, 86, 128)
ROCHER_FORCE = (214, 212, 204)
ROCHER_FORCE_BORD = (120, 118, 112)
TROU = (16, 20, 32)
TROU_BORD = (96, 116, 140)
ECHELLE = (176, 124, 66)
ECHELLE_BORD = (92, 60, 30)
ENTREE_JOUR = (236, 232, 200)
PETIT_ROCHER = (92, 102, 120)
CAILLOU = (232, 236, 240)
# Labo
MUR_FACE = (206, 212, 222)
MUR_DESSUS = (96, 104, 120)
SOL_LABO = (226, 230, 234)
SOL_LABO_JOINT = (206, 212, 218)
PAILLASSON = (70, 140, 90)
PORTE_SALLE = (150, 160, 176)
PHOTO = (196, 160, 90)
PLANTE = (60, 140, 70)
TABLE = (176, 136, 92)
ORDINATEUR = (60, 80, 120)
MACHINE = (178, 190, 204)
MACHINE_VITRE = (130, 210, 230)
LAMPE = (250, 236, 170)
VITRINE = (170, 220, 236)
CANAPE = (176, 64, 60)

COURANTS = {"^": (0, -1), "v": (0, 1), "<": (-1, 0), ">": (1, 0)}


def couper(plan: Plan, colonnes: tuple[int, int] | None, rangees: tuple[int, int] | None) -> Plan:
	x0, x1 = colonnes or (0, plan.width - 1)
	y0, y1 = rangees or (0, plan.height - 1)
	rows = [r[x0:x1 + 1] for r in plan.rows[y0:y1 + 1]]
	sous = Plan(x1 - x0 + 1, y1 - y0 + 1, rows, praticables=plan.praticables)
	for ident, p in plan.positions.items():
		cells = [(x - x0, y - y0) for x, y in p.cells if x0 <= x <= x1 and y0 <= y <= y1]
		if cells:
			sous.positions[ident] = Position(p.ident, p.kind, cells, p.bloque, p.note, p.attrs)
	return sous


def geometrie(plan: Plan, taille: tuple[int, int]) -> tuple[int, int, int]:
	case = min(taille[0] // plan.width, taille[1] // plan.height)
	return case, (taille[0] - plan.width * case) // 2, (taille[1] - plan.height * case) // 2


def _eau_voisine(plan: Plan, x: int, y: int) -> bool:
	for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
		xx, yy = x + dx, y + dy
		if 0 <= xx < plan.width and 0 <= yy < plan.height and plan.rows[yy][xx] in "w~s^v<>":
			return True
	return False


def dessiner(vue: Vue) -> Path:
	plan = couper(lire(RACINE / "tools" / "plans" / f"{vue.grille}.txt"), vue.colonnes, vue.rangees)
	case, ox, oy = geometrie(plan, vue.taille)
	fond = {"mer": MER_DECOR, "grotte": PAROI, "labo": (24, 26, 32)}[vue.famille]
	img = Image.new("RGB", vue.taille, fond)
	d = ImageDraw.Draw(img)
	alea = random.Random(GRAINE)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	def carre(x: int, y: int, couleur) -> None:
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleur)

	if vue.famille == "mer":
		_mer(vue, plan, img, d, case, ox, oy, coin, centre, carre, alea)
	elif vue.famille == "grotte":
		_grotte(plan, d, case, coin, centre, carre, alea)
	else:
		_labo(plan, d, case, coin, centre, carre)
	# Panneaux et objets visibles (toutes familles).
	for p in plan.of_kind("panneau"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			r = case * 0.28
			d.rectangle([cx - r, cy - r * 0.8, cx + r, cy + r * 0.6], fill=pa.PANNEAU,
				outline=pa.PANNEAU_BORD, width=max(1, case // 16))
			d.rectangle([cx - case * 0.04, cy + r * 0.6, cx + case * 0.04, cy + r * 1.2],
				fill=pa.PANNEAU_BORD)
	for p in plan.of_kind("objet_visible"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			r = max(4, case * 0.22)
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=pa.BALL_ROUGE)
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=pa.BLANC)
			d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=pa.BALL_BORD, width=1)
	vue.sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(vue.sortie)
	return vue.sortie


def _mer(vue, plan, img, d, case, ox, oy, coin, centre, carre, alea) -> None:
	# Marges : la mer (décor) tout autour ; au nord de la Route 19 et de la Route 21, forêt.
	fonds = {
		"w": MER, "~": MER_DECOR, "s": MER, "R": RECIF, "T": pa.FORET,
		"y": SABLE_NOIR if vue.ile_cramois else SABLE, "v": SABLE, "K": FALAISE_BLANCHE,
		"D": GROTTE_ENTREE, ".": SOL_VOLCANIQUE if vue.ile_cramois else pa.HERBE,
		"h": pa.HAUTES_HERBES, "X": SOL_VOLCANIQUE,
	}
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if vue.ile_cramois and c in BATIMENTS_MER:
				carre(x, y, BATIMENTS_MER[c][0])
			elif c == "D" and vue.ile_cramois:
				carre(x, y, pa.PORTE)
			else:
				carre(x, y, fonds.get(c, MER))
	# Récifs : amas de rochers gris sur l'eau (ou la roche volcanique de Cramois'Île).
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			cx, cy = centre(x, y)
			if c == "R":
				base = ROCHE_VOLCANIQUE if vue.ile_cramois else RECIF
				clair = ROCHE_VOLCANIQUE_CLAIR if vue.ile_cramois else RECIF_CLAIR
				carre(x, y, base)
				for _ in range(2):
					pa._disque(d, cx + alea.uniform(-0.25, 0.25) * case,
						cy + alea.uniform(-0.25, 0.25) * case, case * alea.uniform(0.18, 0.3), clair)
			elif c == "v":
				x0, y0 = coin(x, y)
				d.rectangle([x0, y0 + case * 0.62, x0 + case - 1, y0 + case - 1], fill=SABLE_REBORD)
			elif c == "K":
				x0, y0 = coin(x, y)
				d.rectangle([x0, y0 + case * 0.55, x0 + case - 1, y0 + case - 1], fill=FALAISE_OMBRE)
			elif c == "X":
				for _ in range(4):
					pa._disque(d, cx + alea.uniform(-0.35, 0.35) * case,
						cy + alea.uniform(-0.35, 0.35) * case, case * 0.12, GRAVATS)
			elif c == "D" and not vue.ile_cramois:
				x0, y0 = coin(x, y)
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=GROTTE_ENTREE)
			elif c in "w" and _bord_terre(plan, x, y):
				# Liseré d'écume le long des rives et des récifs.
				x0, y0 = coin(x, y)
				for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
					xx, yy = x + dx, y + dy
					if 0 <= xx < plan.width and 0 <= yy < plan.height and plan.rows[yy][xx] not in "w~s":
						ep = max(2, case // 8)
						if dy == -1:
							d.rectangle([x0, y0, x0 + case - 1, y0 + ep], fill=MER_ECUME)
						elif dy == 1:
							d.rectangle([x0, y0 + case - 1 - ep, x0 + case - 1, y0 + case - 1], fill=MER_ECUME)
						elif dx == -1:
							d.rectangle([x0, y0, x0 + ep, y0 + case - 1], fill=MER_ECUME)
						else:
							d.rectangle([x0 + case - 1 - ep, y0, x0 + case - 1, y0 + case - 1], fill=MER_ECUME)
			elif c == "." and not vue.ile_cramois and alea.random() < 0.12:
				pa._disque(d, cx + alea.uniform(-4, 4), cy + alea.uniform(-4, 4), max(2, case // 10), pa.FLEUR)
	# Bâtiments de Cramois'Île : toit sur le haut de l'emprise, portes.
	if vue.ile_cramois:
		for char in "MZLCO":
			for groupe in pa._composantes(plan, char):
				xs = [x for x, _ in groupe]
				ys = [y for _, y in groupe]
				x0, y0 = coin(min(xs), min(ys))
				x1, y1 = coin(max(xs) + 1, max(ys) + 1)
				d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=BATIMENTS_MER[char][1])
				if char == "M":   # toit éventré
					for _ in range(5):
						pa._disque(d, alea.uniform(x0 + case, x1 - case), alea.uniform(y0 + case, y0 + 3 * case),
							case * 0.45, (36, 32, 32))
		for x, y in plan.cells_of("D"):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + case // 6, y0 + case // 4, x0 + case - case // 6 - 1, y0 + case - 1],
				fill=pa.PORTE)
		for x, y in plan.cells_of("X"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=GRAVATS)
			for _ in range(5):
				pa._disque(d, x0 + alea.uniform(0.15, 0.85) * case, y0 + alea.uniform(0.15, 0.85) * case,
					case * 0.14, (70, 60, 56))


def _bord_terre(plan: Plan, x: int, y: int) -> bool:
	for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
		xx, yy = x + dx, y + dy
		if 0 <= xx < plan.width and 0 <= yy < plan.height and plan.rows[yy][xx] not in "w~s":
			return True
	return False


def _grotte(plan, d, case, coin, centre, carre, alea) -> None:
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if c == "#":
				carre(x, y, PAROI)
			elif c == "|":
				carre(x, y, ARETE)
			elif c in ".BOoxnE":
				carre(x, y, SOL_BAS)
			elif c in ":UV":
				carre(x, y, SOL_HAUT if c == ":" else SOL_BAS)
			elif c == "=":
				carre(x, y, ESCALIER)
			elif c == "~":
				carre(x, y, EAU_GROTTE_DECOR)
			elif c in "ws^v<>":
				carre(x, y, EAU_GROTTE)
			elif c == "F":
				carre(x, y, EAU_GROTTE if _eau_voisine(plan, x, y) else SOL_BAS)
	# Échelles : sol haut ou bas selon les voisines (une échelle est posée sur le sol qui l'entoure).
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			if c in "UV":
				haut = sum(1 for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0))
					if 0 <= x + dx < plan.width and 0 <= y + dy < plan.height
					and plan.rows[y + dy][x + dx] == ":")
				carre(x, y, SOL_HAUT if haut >= 2 else SOL_BAS)
	# Parois : arête claire sur le haut des parois qui bordent un sol (lecture du relief).
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			cx, cy = centre(x, y)
			if c == "#" and y + 1 < plan.height and plan.rows[y + 1][x] != "#":
				d.rectangle([x0, y0 + case * 0.55, x0 + case - 1, y0 + case - 1], fill=PAROI_HAUT)
			elif c == "|":
				d.rectangle([x0, y0, x0 + case - 1, y0 + max(2, case // 8)], fill=SOL_HAUT)
			elif c == "=":
				for i in range(1, 4):
					yy = y0 + i * case // 4
					d.line([x0 + 2, yy, x0 + case - 3, yy], fill=ESCALIER_TRAIT, width=max(1, case // 16))
			elif c in COURANTS:
				dx, dy = COURANTS[c]
				for k in (-0.22, 0.12):
					px, py = cx + dx * k * case, cy + dy * k * case
					ex, ey = -dy * 0.22 * case, dx * 0.22 * case
					d.line([px - dx * 0.18 * case + ex, py - dy * 0.18 * case + ey, px, py,
						px - dx * 0.18 * case - ex, py - dy * 0.18 * case - ey], fill=MER_ECUME,
						width=max(2, case // 12))
			elif c == "B":
				pa._disque(d, cx, cy, case * 0.42, ROCHER_FORCE, ROCHER_FORCE_BORD)
				d.line([cx - case * 0.1, cy - case * 0.3, cx + case * 0.04, cy - case * 0.05,
					cx - case * 0.06, cy + case * 0.2], fill=ROCHER_FORCE_BORD, width=max(2, case // 14))
			elif c == "O":
				d.ellipse([x0 + case * 0.1, y0 + case * 0.15, x0 + case * 0.9, y0 + case * 0.88],
					fill=TROU, outline=TROU_BORD, width=max(2, case // 12))
			elif c in "UV":
				if c == "V":
					d.ellipse([x0 + case * 0.12, y0 + case * 0.12, x0 + case * 0.88, y0 + case * 0.88],
						fill=TROU)
				for xx in (0.3, 0.7):
					d.line([x0 + xx * case, y0 + case * 0.1, x0 + xx * case, y0 + case * 0.9],
						fill=ECHELLE, width=max(2, case // 10))
				for i in range(4):
					yy = y0 + case * (0.2 + i * 0.2)
					d.line([x0 + 0.3 * case, yy, x0 + 0.7 * case, yy], fill=ECHELLE, width=max(2, case // 14))
			elif c == "E":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=ENTREE_JOUR)
			elif c == "o":
				pa._disque(d, cx, cy, case * 0.34, PETIT_ROCHER, PAROI)
			elif c == "x":
				pa._disque(d, cx, cy + case * 0.1, case * 0.18, CAILLOU, ARETE)


def _labo(plan, d, case, coin, centre, carre) -> None:
	premier_sol = next(y for y, row in enumerate(plan.rows) if "." in row)
	derniere = max(y for y, row in enumerate(plan.rows) if "." in row)
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if c in "KP":
				# Face du mur du fond (3 rangées au-dessus du premier sol) ; ailleurs, épaisseur.
				face = (premier_sol - 3 <= y < premier_sol and 0 < x < plan.width - 1) or c == "P"
				carre(x, y, MUR_FACE if face else MUR_DESSUS)
				if face and y == premier_sol - 1:
					d.rectangle([x0, y0 + case * 0.8, x0 + case - 1, y0 + case - 1], fill=(170, 176, 190))
			else:
				carre(x, y, SOL_LABO)
				if (x + y) % 2 == 0:
					d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=SOL_LABO_JOINT)
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			cx, cy = centre(x, y)
			if c == "X":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case * 0.6], fill=PAILLASSON)
			elif c == "D":
				d.rectangle([x0 + 2, y0 - case * 1.2, x0 + case - 3, y0 + case - 1], fill=PORTE_SALLE)
			elif c == "P":
				d.rectangle([x0 + 4, y0 - case * 1.6, x0 + case - 5, y0 - case * 0.4], fill=PHOTO,
					outline=(110, 80, 40), width=2)
			elif c in "xTdSb":
				continue   # meubles posés au sol : objets séparés (tri en profondeur), pas dans la coque
			elif c == "x":
				pa._disque(d, cx, cy, case * 0.38, PLANTE, (30, 80, 40))
			elif c == "T":
				d.rectangle([x0, y0 + 3, x0 + case - 1, y0 + case - 4], fill=TABLE)
			elif c == "Q":
				d.rectangle([x0 + 2, y0 - case * 0.6, x0 + case - 3, y0 + case * 0.7], fill=ORDINATEUR)
				d.rectangle([x0 + case * 0.2, y0 - case * 0.45, x0 + case * 0.8, y0 + case * 0.1],
					fill=(120, 200, 230))
			elif c == "M":
				d.rectangle([x0, y0 - case * 1.0, x0 + case - 1, y0 + case * 0.8], fill=MACHINE)
				d.rectangle([x0 + case * 0.2, y0 - case * 0.7, x0 + case * 0.8, y0 + case * 0.2],
					fill=MACHINE_VITRE)
			elif c == "A":
				d.rectangle([x0 + 2, y0 - case * 0.5, x0 + case - 3, y0 + case * 0.8], fill=VITRINE,
					outline=(90, 120, 140), width=2)
			elif c == "d":
				pa._disque(d, cx, cy - case * 0.2, case * 0.25, LAMPE, (150, 130, 80))
			elif c == "S":
				d.rectangle([x0, y0 + 4, x0 + case - 1, y0 + case - 4], fill=CANAPE)
			elif c == "b":
				d.rectangle([x0 + 2, y0 + case * 0.3, x0 + case - 3, y0 + case * 0.8], fill=TABLE)


def annoter(vue: Vue) -> Path:
	"""Relecture : grille, numéros de colonnes et de rangées de la grille d'origine, positions."""
	brut = lire(RACINE / "tools" / "plans" / f"{vue.grille}.txt")
	plan = couper(brut, vue.colonnes, vue.rangees)
	dx0 = vue.colonnes[0] if vue.colonnes else 0
	dy0 = vue.rangees[0] if vue.rangees else 0
	img = Image.open(vue.sortie).convert("RGBA")
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	case, ox, oy = geometrie(plan, vue.taille)
	petite = pa._fonte(11)
	for x in range(plan.width + 1):
		d.line([ox + x * case, oy, ox + x * case, oy + plan.height * case],
			fill=(0, 0, 0, 50 if (x + dx0) % 5 else 120), width=1)
	for y in range(plan.height + 1):
		d.line([ox, oy + y * case, ox + plan.width * case, oy + y * case],
			fill=(0, 0, 0, 50 if (y + dy0) % 5 else 120), width=1)
	for x in range(plan.width):
		if (x + dx0) % 5 == 0:
			d.text((ox + x * case + 2, max(0, oy - 14)), str(x + dx0), font=petite, fill=(255, 255, 255, 255))
	for y in range(plan.height):
		if (y + dy0) % 5 == 0:
			d.text((max(2, ox - 26), oy + y * case + 2), str(y + dy0), font=petite, fill=(255, 255, 255, 255))
	couleurs = {"dresseur": (255, 80, 80, 255), "pnj": (80, 160, 255, 255), "rencontre": (220, 120, 255, 255),
		"objet_visible": (255, 255, 255, 255), "objet_cache": (255, 225, 40, 255)}
	for p in plan.positions.values():
		if p.kind not in couleurs:
			continue
		x, y = p.cells[0]
		cx, cy = ox + (x + 0.5) * case, oy + (y + 0.5) * case
		d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=couleurs[p.kind], outline=(0, 0, 0, 255))
		box = d.textbbox((cx, cy - 12), p.ident, font=petite, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 160))
		d.text((cx, cy - 12), p.ident, font=petite, fill=couleurs[p.kind], anchor="mm")
	sortie = vue.sortie.with_name(vue.sortie.stem + "_annote.png")
	Image.alpha_composite(img, calque).convert("RGB").save(sortie)
	return sortie


def main() -> int:
	noms = [a for a in sys.argv[1:] if not a.startswith("--")]
	for vue in VUES:
		if noms and vue.nom not in noms:
			continue
		print(dessiner(vue))
		if "--annote" in sys.argv:
			print(annoter(vue))
	return 0


if __name__ == "__main__":
	sys.exit(main())
