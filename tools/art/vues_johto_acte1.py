#!/usr/bin/env python3
"""Vues générales du Chapitre Johto, acte 1 (JOH1 à JOH5) : plans pour Codex, plans annotés, planches.

Sur le modèle de `tools/art/vues_est_j22.py` (J22, T9). Les grilles `tools/plans/*.txt` font foi ;
les vues peintes donnent la DA et la composition.

`--plans [jalon]`         : plans en aplats SANS annotation (ni PNJ, ni objet, ni étiquette), joints à
                            Codex (`tools/art/generer.sh`) : build/art/PLAN_<ZONE>_codex.png. Les marges
                            sont de la forêt (extérieurs) ou de la roche (grottes).
`--plans-annotes [jalon]` : plans annotés (positions, numéros de cases, légende), qui font foi à la
                            relecture : docs/design/reference/plans-johto/<carte>-plan-v1.png.
`--planche <jalon>`       : docs/design/reference/<jalon>-vues-v1.png, chaque vue peinte à côté de son
                            plan annoté.

Usage : python3 tools/art/vues_johto_acte1.py --plans joh1
        python3 tools/art/vues_johto_acte1.py --plans-annotes joh1
        python3 tools/art/vues_johto_acte1.py --planche joh1
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
ART = RACINE / "build" / "art"
REF = RACINE / "docs" / "design" / "reference"
PLANS_REF = REF / "plans-johto"

PORTRAIT, PAYSAGE = (1024, 1536), (1536, 1024)
# jalon → [(ZONE Codex, grille, format, genre, titre[, styles])] ; genre : grotte | exterieur | interieur.
# `styles` : lettre → style de dessin quand la lettre n'a pas son sens habituel dans cette grille
# (ex. « P » = Phare à Oliville, grille du Parc sur la Route 36, poste de garde sur la Route 35).
JALONS: dict[str, list[tuple]] = {
	"joh1": [
		("GROTTE_MARINE_1", "grotte_marine_1", PORTRAIT, "grotte", "Grotte marine, salle 1 (30 × 40)"),
		("GROTTE_MARINE_2", "grotte_marine_2", PORTRAIT, "grotte", "Grotte marine, salle 2 (30 × 40)"),
		("OLIVILLE", "oliville", PAYSAGE, "exterieur", "Oliville (50 × 40)"),
	],
	"joh2": [
		("ROUTE39", "route_39", PORTRAIT, "exterieur", "Route 39 (24 × 50)"),
		("ROUTE38", "route_38", PAYSAGE, "exterieur", "Route 38 (60 × 20)"),
		("ROSALIA", "rosalia", PAYSAGE, "exterieur", "Rosalia (56 × 48)"),
	],
	"joh3": [
		("ROUTE37", "route_37", PORTRAIT, "exterieur", "Route 37 (20 × 40)"),
		("ROUTE36", "route_36", PAYSAGE, "exterieur", "Route 36 (56 × 20)", {"P": "parc"}),
		("ROUTE35", "route_35", PORTRAIT, "exterieur", "Route 35 (24 × 44)", {"P": "poste", "x": "cloture"}),
		("DOUBLONVILLE", "doublonville", PAYSAGE, "exterieur", "Doublonville (72 × 60)", {"E": "escalier"}),
		("SOUTERRAIN", "souterrain", PAYSAGE, "interieur", "Souterrain de Doublonville (40 × 14)"),
	],
	"joh4": [
		("ROUTE34", "route_34", PORTRAIT, "exterieur", "Route 34 (24 × 48)", {"x": "cloture", "M": "mer"}),
		("BOIS_CHENES", "ilex_forest", PAYSAGE, "exterieur", "Bois aux Chênes (48 × 48)", {"C": "clairiere", "A": "autel"}),
		("ECORCIA", "azalea_town", PAYSAGE, "exterieur", "Écorcia (44 × 36)", {"K": "maison", "E": "puits", "x": "margelle"}),
		("PUITS_B1F", "slowpoke_well_b1f", PAYSAGE, "grotte", "Puits Ramoloss B1F (30 × 24)"),
		("PUITS_B2F", "slowpoke_well_b2f", PAYSAGE, "grotte", "Puits Ramoloss B2F (30 × 24)"),
	],
	"joh5": [
		("TOUR_RADIO_1F", "radio_tower_1f", PAYSAGE, "interieur", "Tour Radio 1F, hall (24 × 16)"),
		("TOUR_RADIO_2F", "radio_tower_2f", PAYSAGE, "interieur", "Tour Radio 2F, studios (24 × 16)"),
		("TOUR_RADIO_3F", "radio_tower_3f", PAYSAGE, "interieur", "Tour Radio 3F, archives (24 × 16)"),
		("TOUR_RADIO_4F", "radio_tower_4f", PAYSAGE, "interieur", "Tour Radio 4F, régie (24 × 16)"),
		("TOUR_RADIO_5F", "radio_tower_5f", PAYSAGE, "interieur", "Tour Radio 5F, studio de diffusion (24 × 16)"),
	],
}
# Styles par défaut des lettres de bâtiment (toit, mur) ; les lettres spéciales ont leur dessin.
BATIMENTS = {
	"C": ((200, 60, 60), (236, 232, 224)), "O": ((60, 100, 200), (236, 232, 224)),
	"m": ((176, 70, 52), (226, 214, 190)), "N": ((176, 70, 52), (226, 214, 190)),
	"S": ((176, 70, 52), (226, 214, 190)), "L": ((176, 70, 52), (226, 214, 190)),
	"M": ((150, 70, 50), (214, 196, 160)), "A": ((230, 200, 80), (236, 232, 224)),
	"F": ((110, 110, 120), (214, 206, 190)), "poste": ((84, 92, 110), (214, 206, 190)),
	"H": ((70, 60, 56), (120, 96, 76)), "maison": ((176, 70, 52), (226, 214, 190)),
}


# Grilles dont la vue et le plan portent un nom français différent du nom de la grille.
NOMS = {"ilex_forest": "bois-aux-chenes", "azalea_town": "ecorcia", "slowpoke_well_b1f": "puits-ramoloss-b1f",
	"slowpoke_well_b2f": "puits-ramoloss-b2f", "souterrain": "souterrain-doublonville",
	"radio_tower_1f": "tour-radio-1f", "radio_tower_2f": "tour-radio-2f", "radio_tower_3f": "tour-radio-3f",
	"radio_tower_4f": "tour-radio-4f", "radio_tower_5f": "tour-radio-5f"}


def nom_vue(grille: str) -> str:
	return NOMS.get(grille, grille.replace("_", "-")) + "-vue-generale-v1.png"


def nom_plan(grille: str) -> str:
	return NOMS.get(grille, grille.replace("_", "-")) + "-plan-v1.png"


# ---------------------------------------------------------------- couleurs des aplats
FORET, FORET_BORD = (27, 87, 45), (20, 66, 34)
ROCHE, ROCHE_BORD = (44, 46, 54), (74, 76, 88)
EAU, EAU_PROFONDE = (56, 104, 168), (30, 62, 122)
PELOUSE, CHEMIN, HERBES = (86, 152, 62), (224, 196, 140), (150, 170, 40)
PAVE, PAVE_2 = (206, 196, 176), (192, 182, 162)
GALETS, GALETS_2 = (184, 172, 150), (160, 150, 130)
BOIS, BOIS_2 = (150, 106, 66), (120, 82, 50)
FALAISE, FALAISE_2 = (138, 130, 120), (164, 158, 148)
OCRE = (196, 140, 50)

# Couleur de fond de chaque caractère (les détails sont dessinés ensuite).
COULEURS_EXT = {
	"T": FORET, ".": PELOUSE, "=": CHEMIN, "h": HERBES, "p": PAVE, "g": GALETS, "q": BOIS, "w": EAU,
	"R": FALAISE, "x": PELOUSE, "y": PELOUSE, "n": PELOUSE, "G": PELOUSE, "k": PAVE, "E": FALAISE,
	"C": PELOUSE, "O": PELOUSE, "m": PELOUSE, "N": PELOUSE, "P": FALAISE, "D": PELOUSE,
	# JOH2 : W mer (décor), f clôture et e pré de l'enclos, M Ferme Meumeu, B Tour Cendrée, K Tour Carillon,
	# S maison des sages
	"W": EAU_PROFONDE, "f": PELOUSE, "e": (122, 170, 80), "M": PELOUSE, "B": PELOUSE, "K": FORET, "S": PELOUSE,
	# JOH3 : a arbre fruitier, b pont, X barrière de chantier, r rocher, U Tour Radio, A Grand Magasin,
	# L maison du lien, F gare
	"a": PELOUSE, "b": EAU_PROFONDE, "X": PELOUSE, "r": PELOUSE, "U": PELOUSE, "A": PELOUSE, "L": PELOUSE,
	"F": PELOUSE,
	# JOH4 : M mer (décor), H charbonnerie, Q margelle du puits, s souche
	"M": EAU_PROFONDE, "H": PELOUSE, "Q": PELOUSE, "s": PELOUSE,
}
CLAIRIERE = (140, 196, 100)
SOL_INT, MUR_INT, NOIR = (200, 186, 150), (78, 70, 64), (10, 10, 12)
COULEURS_INT = {"X": MUR_INT, "#": MUR_INT, ".": SOL_INT, "b": SOL_INT, "k": SOL_INT, "E": SOL_INT, "M": SOL_INT,
	"V": SOL_INT, "c": SOL_INT, "r": SOL_INT, "p": SOL_INT, "U": SOL_INT, "D": SOL_INT, "L": MUR_INT, "K": SOL_INT,
	"S": MUR_INT}
COULEURS_GROTTE = {
	"#": ROCHE, "o": EAU, ".": (150, 150, 158), "g": GALETS, "w": EAU, "d": EAU_PROFONDE, ">": EAU, "<": EAU,
	"v": EAU, "^": EAU, "E": (200, 186, 150), "U": (150, 150, 158), "V": (150, 150, 158), "R": (150, 150, 158),
}
LEGENDE_EXT = [
	("T", "forêt, bordure d'arbres"), ("R", "falaise, rochers"), (".", "pelouse"), ("=", "chemin"),
	("p", "pavé"), ("h", "hautes herbes"), ("g", "plage de galets"), ("q", "quai, pontons"), ("w", "eau surfable"),
	("x", "haie"), ("y", "massif de fleurs"), ("n", "banc"), ("G", "arbre repère"), ("k", "caisses"),
	("C", "Centre"), ("O", "Boutique"), ("m", "Maison 1"), ("N", "Maison 2"), ("P", "Phare"), ("D", "porte"),
	("E", "bouche de grotte"), ("W", "mer (décor)"), ("f", "clôture de l'enclos"), ("e", "pré de l'enclos"),
	("M", "Ferme Meumeu"), ("B", "Tour Cendrée"), ("K", "Tour Carillon"), ("S", "maison des sages"),
	("a", "arbre fruitier"), ("b", "pont"), ("X", "barrière de chantier"), ("r", "rocher"), ("U", "Tour Radio"),
	("A", "Grand Magasin"), ("L", "maison du lien"), ("F", "gare"), ("M", "mer (décor)"), ("H", "charbonnerie"),
	("Q", "margelle du puits"), ("s", "souche"),
]
LEGENDE_INT = [("X", "mur"), ("#", "mur, cloison"), (".", "sol"), ("b", "boutique fermée"), ("k", "caisse"),
	("E", "escalier / sortie"), ("M", "mobilier"), ("V", "vitre"), ("c", "comptoir"), ("r", "rayonnage"),
	("p", "pupitre"), ("U", "escalier qui monte"), ("D", "escalier qui descend"), ("L", "ascenseur"),
	("K", "porte à clé"), ("S", "escalier de secours")]
LEGENDE_GROTTE = [
	("#", "paroi"), ("o", "rocher isolé"), (".", "îlot, corniche"), ("g", "plage de galets"), ("w", "eau surfable"),
	("d", "eau profonde"), (">", "courant →"), ("v", "courant ↓"), ("E", "sortie à pied"), ("U", "échelle qui monte"),
	("V", "échelle qui descend"), ("R", "caisse marquée R"),
]
# Pastilles de légende des caractères dont la couleur de fond n'est pas parlante (dessinés par-dessus).
SWATCH = {
	"x": (40, 110, 50), "y": (240, 120, 170), "n": BOIS, "G": (32, 96, 48), "k": BOIS, "C": (200, 60, 60),
	"O": (60, 100, 200), "m": (176, 70, 52), "N": (176, 70, 52), "P": (240, 240, 236), "D": (60, 80, 120),
	"E": (30, 30, 36), "o": (118, 120, 132), ">": (225, 240, 255), "v": (225, 240, 255),
	"f": (244, 242, 232), "M": (150, 70, 50), "B": (60, 52, 50), "K": (120, 60, 50), "S": (176, 70, 52),
	"a": (60, 130, 60), "b": BOIS, "X": (230, 120, 40), "r": (128, 118, 108), "U": (190, 190, 200),
	"A": (230, 200, 80), "L": (176, 70, 52), "F": (110, 110, 120), "M": EAU_PROFONDE, "H": (70, 60, 56),
	"Q": (150, 146, 140), "s": (120, 86, 56), "U": (160, 110, 60), "V": (160, 110, 60), "R": (200, 50, 50),
}
SWATCH_INT = {"M": (120, 86, 56), "V": (170, 210, 230), "c": BOIS, "r": (96, 70, 46), "p": (70, 74, 86),
	"U": (120, 110, 96), "D": (90, 84, 76), "L": (150, 150, 160), "K": (80, 52, 32), "S": (110, 110, 120),
	"E": (120, 110, 96), "b": (120, 96, 76)}
SYMBOLES = [
	((255, 120, 220), "warp (raccord, porte)"), ((120, 220, 120), "spawn (arrivée)"), ((80, 150, 255), "PNJ"),
	((255, 220, 40), "objet"), ((255, 150, 40), "déclencheur"), ((230, 40, 40), "Dresseur et sa vue"),
	((255, 255, 255), "panneau / courant"),
]
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
FLECHES = {">": (1, 0), "<": (-1, 0), "v": (0, 1), "^": (0, -1)}


def fonte(t: int, gras: bool = False):
	for chemin in (f"/System/Library/Fonts/Supplemental/Arial{' Bold' if gras else ''}.ttf",
			"/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
		try:
			return ImageFont.truetype(chemin, t)
		except OSError:
			continue
	return ImageFont.load_default(size=t)


def _voisin(plan: Plan, x: int, y: int, dx: int, dy: int) -> str | None:
	nx, ny = x + dx, y + dy
	if 0 <= nx < plan.width and 0 <= ny < plan.height:
		return plan.at(nx, ny)
	return None


def _bord(plan: Plan, x: int, y: int, meme: str) -> bool:
	"""Vrai si la case (x, y) touche une case d'un autre caractère que `meme` (dans la carte)."""
	return any(v is not None and v != meme for v in (_voisin(plan, x, y, dx, dy) for dx, dy in FACINGS.values()))


def _boite(d: ImageDraw.ImageDraw, cases, coin, **kw) -> tuple[int, int, int, int]:
	xs = [x for x, _ in cases]
	ys = [y for _, y in cases]
	x0, y0 = coin(min(xs), min(ys))
	x1, y1 = coin(max(xs) + 1, max(ys) + 1)
	if kw:
		d.rectangle([x0, y0, x1 - 1, y1 - 1], **kw)
	return x0, y0, x1, y1


def _vagues(d, plan, coin, case, chars: str) -> None:
	for ch in chars:
		for x, y in plan.cells_of(ch):
			if (x + 2 * y) % 5 == 0:
				x0, y0 = coin(x, y)
				d.line([x0 + 3, y0 + case // 2, x0 + case - 4, y0 + case // 2], fill=(110, 160, 220), width=1)


def _fleche(d, x0: int, y0: int, case: int, sens: tuple[int, int], couleur) -> None:
	cx, cy = x0 + case / 2, y0 + case / 2
	r = case * 0.32
	dx, dy = sens
	pointe = (cx + dx * r, cy + dy * r)
	base = (cx - dx * r, cy - dy * r)
	d.line([base, pointe], fill=couleur, width=max(2, case // 8))
	px, py = -dy, dx                                    # perpendiculaire
	d.polygon([pointe, (cx + dx * r * 0.1 + px * r * 0.6, cy + dy * r * 0.1 + py * r * 0.6),
		(cx + dx * r * 0.1 - px * r * 0.6, cy + dy * r * 0.1 - py * r * 0.6)], fill=couleur)


def dessiner_aplats(img: Image.Image, plan: Plan, ox: int, oy: int, case: int, genre: str,
		styles: dict[str, str] | None = None) -> None:
	"""Aplats et détails « muets » (sans PNJ, objet ni étiquette) de la grille, à `case` px la case."""
	d = ImageDraw.Draw(img)
	couleurs = {"grotte": COULEURS_GROTTE, "interieur": COULEURS_INT}.get(genre, COULEURS_EXT)
	defaut = {"grotte": ROCHE, "interieur": MUR_INT}.get(genre, FORET)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	for y in range(plan.height):
		for x in range(plan.width):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleurs.get(plan.at(x, y), defaut))
	if genre == "grotte":
		_details_grotte(d, plan, coin, case)
	elif genre == "interieur":
		_details_interieur(d, plan, coin, case)
	else:
		_details_exterieur(d, plan, coin, case, styles or {})


def _details_interieur(d, plan, coin, case) -> None:
	murs = plan.cells_of("X") + plan.cells_of("#")
	for x, y in murs:                                   # mur du fond (au-dessus du sol) plus clair
		if _voisin(plan, x, y, 0, 1) not in (None, "X", "#", "L", "S"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(150, 128, 104))
	for x, y in plan.cells_of("M"):                     # mobilier : bureaux, plantes, bancs (bloc de bois)
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 2, y0 + 3, x0 + case - 3, y0 + case - 3], fill=(120, 86, 56), outline=(70, 50, 30))
	for x, y in plan.cells_of("V"):                     # vitre : bande bleu clair
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(170, 210, 230))
		d.rectangle([x0 + case // 3, y0, x0 + case * 2 // 3 - 1, y0 + case - 1], fill=(200, 230, 245))
	for x, y in plan.cells_of("c"):                     # comptoir d'accueil
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0 + 2, x0 + case - 1, y0 + case - 2], fill=BOIS, outline=BOIS_2)
	for x, y in plan.cells_of("r"):                     # rayonnage : étagères
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=(96, 70, 46))
		for k in range(case // 4, case - 2, max(3, case // 4)):
			d.line([x0 + 2, y0 + k, x0 + case - 3, y0 + k], fill=(170, 140, 100), width=1)
	for x, y in plan.cells_of("p"):                     # pupitre de régie : sombre, boutons
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0 + 2, x0 + case - 1, y0 + case - 2], fill=(70, 74, 86), outline=(40, 42, 50))
		d.ellipse([x0 + case // 3, y0 + case // 3, x0 + case // 3 + 3, y0 + case // 3 + 3], fill=(90, 200, 120))
	for x, y in plan.cells_of("U") + plan.cells_of("D"):    # escaliers dans le mur nord
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(60, 56, 52) if plan.at(x, y) == "D" else (120, 110, 96))
		for k in range(4):
			d.rectangle([x0 + 1, y0 + k * case // 4, x0 + case - 2, y0 + k * case // 4 + case // 8],
				fill=(150, 150, 160) if plan.at(x, y) == "U" else (110, 104, 96))
	for x, y in plan.cells_of("S"):                     # escalier de secours : porte métallique dans le mur est
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 1, y0 + 2, x0 + case - 2, y0 + case - 3], fill=(110, 110, 120), outline=(60, 60, 70))
	for x, y in plan.cells_of("L"):                     # porte d'ascenseur : métal gris, deux battants
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 1], fill=(150, 150, 160), outline=(70, 70, 80))
		d.line([x0 + case // 2, y0 + 1, x0 + case // 2, y0 + case - 1], fill=(70, 70, 80), width=1)
	for x, y in plan.cells_of("K"):                     # porte fermée à clé : battant de bois sombre
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 2, y0, x0 + case - 3, y0 + case - 1], fill=(80, 52, 32), outline=(40, 26, 16))
	for x, y in plan.cells_of("b"):                     # boutique fermée : devanture et rideau baissé
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(120, 96, 76))
		if _voisin(plan, x, y, 0, 1) == "." or _voisin(plan, x, y, 0, -1) == ".":
			for k in range(2, case - 2, max(3, case // 5)):
				d.line([x0 + 1, y0 + k, x0 + case - 2, y0 + k], fill=(160, 150, 140), width=1)
	for x, y in plan.cells_of("k"):
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=BOIS, outline=BOIS_2, width=2)
	for x, y in plan.cells_of("E"):                     # escalier (Souterrain) ou sortie (paillasson, Tour Radio)
		x0, y0 = coin(x, y)
		if "#" in plan.praticables or plan.cells_of("#"):
			d.rectangle([x0 + 1, y0 + 2, x0 + case - 2, y0 + case - 1], fill=(140, 60, 50))
		else:
			for k in range(4):
				d.rectangle([x0 + 1, y0 + k * case // 4, x0 + case - 2, y0 + k * case // 4 + case // 8], fill=(120, 110, 96))


def _details_grotte(d, plan, coin, case) -> None:
	for x, y in plan.cells_of("#"):                     # arête de la paroi, pour lire les contours
		if _bord(plan, x, y, "#"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=ROCHE_BORD)
	_vagues(d, plan, coin, case, "wd")
	for x, y in plan.cells_of("o"):                     # rocher isolé qui sort de l'eau
		x0, y0 = coin(x, y)
		d.ellipse([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=(118, 120, 132), outline=(80, 82, 94))
	for x, y in plan.cells_of("."):                     # îlot : quelques cailloux
		if (x * 3 + y) % 4 == 0:
			x0, y0 = coin(x, y)
			d.ellipse([x0 + case // 3, y0 + case // 3, x0 + case // 2 + 1, y0 + case // 2 + 1], fill=(120, 120, 130))
	for x, y in plan.cells_of("g"):                     # galets
		x0, y0 = coin(x, y)
		for k in range(2):
			px = x0 + (case * (1 + 2 * k) // 4) + ((x + y + k) % 3) - 1
			py = y0 + case // 2 + ((x * k + y) % 3) - 1
			d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=GALETS_2)
	for ch, sens in FLECHES.items():                    # courants : chevrons blancs dans le sens du flux
		for x, y in plan.cells_of(ch):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(72, 124, 190))
			if (x + y) % 2 == 0:
				_fleche(d, x0, y0, case, sens, (225, 240, 255))
	for x, y in plan.cells_of("E"):                     # sortie : lumière du dehors
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(228, 216, 180))
	for x, y in plan.cells_of("U") + plan.cells_of("V"):    # échelles de bois (montants et barreaux)
		x0, y0 = coin(x, y)
		if plan.at(x, y) == "V":                        # trou sombre autour de l'échelle qui descend
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(40, 40, 46))
		m = max(2, case // 6)
		d.rectangle([x0 + m, y0 + 1, x0 + m + 2, y0 + case - 2], fill=(160, 110, 60))
		d.rectangle([x0 + case - m - 3, y0 + 1, x0 + case - m - 1, y0 + case - 2], fill=(160, 110, 60))
		for k in range(3, case - 2, max(3, case // 4)):
			d.line([x0 + m, y0 + k, x0 + case - m - 1, y0 + k], fill=(160, 110, 60), width=2)
	for x, y in plan.cells_of("R"):                     # caisses marquées d'un R rouge
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=BOIS, outline=BOIS_2, width=2)
		d.rectangle([x0 + case // 3, y0 + case // 3, x0 + case * 2 // 3, y0 + case * 2 // 3], fill=(200, 50, 50))


def _details_exterieur(d, plan, coin, case, styles: dict[str, str]) -> None:
	for x, y in plan.cells_of("T"):                     # bord de la forêt
		if _bord(plan, x, y, "T"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=FORET_BORD)
	rochers = plan.cells_of("R") + plan.cells_of("r")
	if styles.get("P", "phare") == "phare":
		rochers += plan.cells_of("P") + plan.cells_of("E")
	for x, y in rochers:                                # falaise : rochers
		if (x * 2 + y) % 3 == 0:
			x0, y0 = coin(x, y)
			d.ellipse([x0 + 2, y0 + 3, x0 + case - 3, y0 + case - 4], fill=FALAISE_2)
	for x, y in plan.cells_of("p") + plan.cells_of("k"):    # pavé en damier
		if (x + y) % 2 == 0:
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=PAVE_2)
	for x, y in plan.cells_of("g"):                     # galets
		x0, y0 = coin(x, y)
		for k in range(2):
			px = x0 + (case * (1 + 2 * k) // 4) + ((x + y + k) % 3) - 1
			py = y0 + case // 2 + ((x * k + y) % 3) - 1
			d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=GALETS_2)
	for x, y in plan.cells_of("q"):                     # planches du quai et des pontons
		x0, y0 = coin(x, y)
		for k in range(0, case, max(3, case // 4)):
			d.line([x0, y0 + k, x0 + case - 1, y0 + k], fill=BOIS_2, width=1)
	_vagues(d, plan, coin, case, "wWM")
	if styles.get("C") == "clairiere":                  # clairière de l'autel : herbe rase éclairée
		for x, y in plan.cells_of("C"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=CLAIRIERE)
	for x, y in plan.cells_of("A") if styles.get("A") == "autel" else []:   # autel de bois moussu
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 1, y0 + case // 4, x0 + case - 2, y0 + case - 2], fill=(110, 84, 56), outline=(60, 44, 30))
		d.rectangle([x0 + 1, y0 + case // 4, x0 + case - 2, y0 + case // 2], fill=(90, 130, 70))
	for x, y in plan.cells_of("s"):                     # souche
		x0, y0 = coin(x, y)
		d.ellipse([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=(120, 86, 56), outline=(70, 50, 30))
		d.ellipse([x0 + case // 3, y0 + case // 3, x0 + case * 2 // 3, y0 + case * 2 // 3], fill=(180, 140, 100))
	for x, y in plan.cells_of("Q"):                     # margelle du puits : pierre grise
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(150, 146, 140), outline=(90, 88, 84))
	if styles.get("x") == "margelle":
		for x, y in plan.cells_of("x"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0 + case // 4, x0 + case - 1, y0 + case * 3 // 4], fill=(150, 146, 140), outline=(90, 88, 84))
	for x, y in plan.cells_of("r"):                     # rocher isolé
		x0, y0 = coin(x, y)
		d.ellipse([x0 + 1, y0 + 2, x0 + case - 2, y0 + case - 2], fill=FALAISE, outline=(98, 90, 82))
	for x, y in plan.cells_of("b"):                     # pont de planches sur la rivière
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=BOIS)
		for k in range(0, case, max(3, case // 4)):
			d.line([x0 + k, y0, x0 + k, y0 + case - 1], fill=BOIS_2, width=1)
	for x, y in plan.cells_of("X"):                     # barrière de chantier rayée
		x0, y0 = coin(x, y)
		d.rectangle([x0 + case // 3, y0, x0 + case * 2 // 3, y0 + case - 1], fill=(240, 240, 236))
		for k in range(0, case, max(4, case // 3)):
			d.rectangle([x0 + case // 3, y0 + k, x0 + case * 2 // 3, y0 + k + max(2, case // 6)], fill=(230, 120, 40))
	for x, y in plan.cells_of("a"):                     # arbre fruitier : couronne ronde et fruits
		x0, y0 = coin(x, y)
		d.ellipse([x0 - case // 4, y0 - case // 4, x0 + case + case // 4, y0 + case + case // 4], fill=(60, 130, 60),
			outline=FORET_BORD)
		for k in range(3):
			px, py = x0 + case * (1 + 2 * k) // 6, y0 + case // 3 + (k % 2) * case // 3
			d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=(230, 60, 60))
	cloture = plan.cells_of("f") + (plan.cells_of("x") if styles.get("x") == "cloture" else [])
	for x, y in cloture:                                # clôture de bois : lisse et poteaux
		x0, y0 = coin(x, y)
		gauche = _voisin(plan, x, y, -1, 0) == "f"
		droite = _voisin(plan, x, y, 1, 0) == "f"
		haut = _voisin(plan, x, y, 0, -1) == "f"
		bas = _voisin(plan, x, y, 0, 1) == "f"
		m, e = case // 2, max(2, case // 6)
		if gauche or droite or not (haut or bas):
			d.rectangle([x0, y0 + m - e // 2, x0 + case - 1, y0 + m + e // 2], fill=(244, 242, 232))
		if haut or bas:
			d.rectangle([x0 + m - e // 2, y0, x0 + m + e // 2, y0 + case - 1], fill=(244, 242, 232))
		d.rectangle([x0 + m - e, y0 + m - e, x0 + m + e, y0 + m + e], fill=(255, 255, 250))
	for x, y in plan.cells_of("h"):                     # hautes herbes : touffes
		x0, y0 = coin(x, y)
		d.line([x0 + 2, y0 + case - 3, x0 + case // 2, y0 + 3], fill=(110, 130, 20), width=1)
		d.line([x0 + case - 3, y0 + case - 3, x0 + case // 2, y0 + 3], fill=(110, 130, 20), width=1)
	if styles.get("x") not in ("cloture", "margelle"):
		for x, y in plan.cells_of("x"):                 # haie : bande continue
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0 + 2, x0 + case - 1, y0 + case - 3], fill=(40, 110, 50))
	for x, y in plan.cells_of("y"):                     # massif de fleurs
		x0, y0 = coin(x, y)
		d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(100, 160, 70))
		for k, coul in enumerate(((240, 120, 170), (250, 240, 200), (240, 120, 170))):
			px = x0 + case * (1 + 2 * k) // 6 + ((x + y + k) % 2)
			py = y0 + case // 3 + ((x * k + y) % 3) * case // 4
			d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=coul)
	for x, y in plan.cells_of("n"):                     # banc
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 1, y0 + case // 3, x0 + case - 2, y0 + case * 2 // 3], fill=BOIS, outline=BOIS_2)
	for x, y in plan.cells_of("G"):                     # arbre repère
		x0, y0 = coin(x, y)
		d.ellipse([x0 - case // 4, y0 - case // 4, x0 + case + case // 4, y0 + case + case // 4], fill=(32, 96, 48),
			outline=FORET_BORD)
	for x, y in plan.cells_of("k"):                     # caisses
		x0, y0 = coin(x, y)
		d.rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=BOIS, outline=BOIS_2, width=2)
	batiments = dict(BATIMENTS)
	for lettre, style in styles.items():
		if style == "maison":
			batiments[lettre] = BATIMENTS["maison"]
	for lettre, (toit, mur) in batiments.items():
		if len(lettre) != 1 or styles.get(lettre, "maison") != "maison":
			continue
		cases = plan.cells_of(lettre)
		if not cases:
			continue
		x0, y0, x1, y1 = _boite(d, cases, coin, fill=mur, outline=(90, 60, 40), width=2)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=toit, outline=(90, 40, 30), width=2)
		if lettre in "CO":                              # emblème rond sans texte
			cx, cy, r = (x0 + x1) // 2, y0 + (y1 - y0) * 3 // 10, (y1 - y0) // 8
			d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(245, 245, 245), outline=(60, 60, 60))
		if lettre == "A":                               # Grand Magasin : vitrines du rez-de-chaussée
			for k in range(1, 6):
				vx = x0 + (x1 - x0) * k // 6
				d.rectangle([vx - case // 3, y1 - case * 3 // 2, vx + case // 3, y1 - case // 2], fill=(120, 170, 220))
		if lettre == "H":                               # charbonnerie : cheminée de pierre, pas de porte
			cx = x0 + (x1 - x0) * 3 // 4
			d.rectangle([cx - case // 3, y0 - case // 2, cx + case // 3, y0 + case // 2], fill=(120, 116, 110),
				outline=(60, 58, 54))
		if lettre == "F":                               # gare : horloge ronde sur le fronton
			cx, cy, r = (x0 + x1) // 2, y0 + (y1 - y0) * 3 // 10, (y1 - y0) // 10
			d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(245, 245, 240), outline=(60, 60, 60))
	if styles.get("P") == "parc":                       # grille du Parc National : piliers de pierre, grille de fer
		x0, y0, x1, y1 = _boite(d, plan.cells_of("P"), coin, fill=(100, 150, 80), outline=(70, 60, 50), width=2)
		d.rectangle([x0, y0, x0 + case - 1, y1 - 1], fill=(180, 174, 160), outline=(70, 60, 50))
		d.rectangle([x1 - case, y0, x1 - 1, y1 - 1], fill=(180, 174, 160), outline=(70, 60, 50))
		for k in range(x0 + case + case // 2, x1 - case, max(4, case // 2)):
			d.line([k, y0 + 2, k, y1 - 2], fill=(40, 40, 48), width=2)
		d.line([x0 + case, y0 + case // 2, x1 - case, y0 + case // 2], fill=(40, 40, 48), width=2)
	if styles.get("P") == "poste":                      # poste de garde : murs clairs, toit d'ardoise
		toit, mur = BATIMENTS["poste"]
		x0, y0, x1, y1 = _boite(d, plan.cells_of("P"), coin, fill=mur, outline=(70, 70, 80), width=2)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) // 2], fill=toit, outline=(50, 54, 64), width=2)
		px, py = x0, (y0 + y1) // 2 - case // 2        # porte latérale côté chemin (ouest)
		d.rectangle([px, py + 2, px + case - 1, py + case - 3], fill=(80, 52, 32))
	if plan.cells_of("U") and "U" not in styles:        # Tour Radio : haute tour claire, antenne sur le toit
		x0, y0, x1, y1 = _boite(d, plan.cells_of("U"), coin, fill=(214, 214, 222), outline=(70, 70, 90), width=2)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) // 4], fill=(120, 130, 160), outline=(50, 54, 70), width=2)
		cx = (x0 + x1) // 2
		d.line([cx, y0 - case, cx, y0 + case], fill=(200, 40, 40), width=max(3, case // 3))
		for k in range(1, 4):                           # rangées de fenêtres
			yk = y0 + (y1 - y0) * k // 4 + case // 2
			for vx in range(x0 + case, x1 - case // 2, case):
				d.rectangle([vx, yk, vx + case // 2, yk + case // 2], fill=(120, 170, 220))
	if plan.cells_of("M") and "M" not in styles:        # Ferme : porte décor fermée au milieu de la façade
		x0, y0, x1, y1 = _boite(d, plan.cells_of("M"), coin)
		px, py = (x0 + x1) // 2 - case // 2, y1 - case
		d.rectangle([px + 3, py + case // 4, px + case - 4, py + case - 1], fill=(80, 52, 32))
	if plan.cells_of("B") and "B" not in styles:        # Tour Cendrée : ruine noircie, toit effondré
		x0, y0, x1, y1 = _boite(d, plan.cells_of("B"), coin, fill=(74, 66, 62), outline=(40, 34, 32), width=2)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 2 // 5], fill=(50, 44, 42), outline=(30, 26, 24), width=2)
		for k in range(3):                              # brèches du toit
			bx = x0 + (x1 - x0) * (1 + 3 * k) // 10
			d.rectangle([bx, y0 + case // 2, bx + case, y0 + case * 3 // 2], fill=(26, 24, 24))
	if plan.cells_of("K") and "K" not in styles:        # Tour Carillon : pagode à toits rouges étagés
		x0, y0, x1, y1 = _boite(d, plan.cells_of("K"), coin, fill=(214, 196, 160), outline=(90, 40, 30), width=2)
		h = y1 - y0
		for k in range(3):
			yk = y0 + h * k // 3
			d.rectangle([x0 - case // 4 * (2 - k), yk, x1 - 1 + case // 4 * (2 - k), yk + h // 6], fill=(170, 50, 40),
				outline=(90, 30, 24), width=2)
	if plan.cells_of("P") and styles.get("P", "phare") == "phare":   # Phare : tour blanche à bandes, lanterne rouge
		x0, y0, x1, y1 = _boite(d, plan.cells_of("P"), coin, fill=(240, 240, 236), outline=(90, 90, 100), width=2)
		h = y1 - y0
		for k in range(1, 5):
			d.rectangle([x0, y0 + h * k // 5, x1 - 1, y0 + h * k // 5 + max(2, case // 4)], fill=(200, 60, 60))
		d.rectangle([x0, y0, x1 - 1, y0 + h // 7], fill=(200, 60, 60), outline=(90, 40, 30), width=2)
		cx, cy, r = (x0 + x1) // 2, y0 + h // 14, h // 20
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 236, 140))
		px, py = (x0 + x1) // 2 - case // 2, y1 - case      # porte close au pied de la façade
		d.rectangle([px + 3, py + case // 4, px + case - 4, py + case - 1], fill=(80, 52, 32))
	for x, y in plan.cells_of("D"):                     # portes
		px, py = coin(x, y)
		d.rectangle([px + 3, py + case // 4, px + case - 4, py + case - 1], fill=(60, 80, 120))
	for x, y in plan.cells_of("E"):                     # bouche de grotte dans la falaise, ou escalier
		px, py = coin(x, y)
		if styles.get("E") == "escalier":
			d.rectangle([px, py, px + case - 1, py + case - 1], fill=(60, 60, 70))
			for k in range(4):
				d.rectangle([px + 1, py + k * case // 4, px + case - 2, py + k * case // 4 + case // 8], fill=(150, 150, 160))
		elif styles.get("E") == "puits":                # descente du puits : trou noir cerclé de pierre
			d.rectangle([px, py, px + case - 1, py + case - 1], fill=(150, 146, 140))
			d.ellipse([px + 2, py + 2, px + case - 3, py + case - 3], fill=(20, 20, 24))
		else:
			d.rectangle([px, py, px + case - 1, py + case - 1], fill=(30, 30, 36))
	for p in plan.of_kind("panneau"):                   # panneaux sans texte
		for x, y in p.cells:
			px, py = coin(x, y)
			d.rectangle([px + case // 4, py + case // 4, px + case * 3 // 4, py + case * 3 // 4], fill=OCRE,
				outline=(110, 70, 30))


# ---------------------------------------------------------------- plans pour Codex
def _geometrie(largeur: int, hauteur: int, taille: tuple[int, int]) -> tuple[int, int, int]:
	case = min(taille[0] // largeur, taille[1] // hauteur)
	return case, (taille[0] - case * largeur) // 2, (taille[1] - case * hauteur) // 2


def plan_codex(zone: str, grille: str, taille: tuple[int, int], genre: str, styles=None) -> Path:
	plan = lire(PLANS / f"{grille}.txt")
	img = Image.new("RGB", taille, {"grotte": ROCHE, "interieur": NOIR}.get(genre, FORET))
	case, ox, oy = _geometrie(plan.width, plan.height, taille)
	dessiner_aplats(img, plan, ox, oy, case, genre, styles)
	ART.mkdir(parents=True, exist_ok=True)
	sortie = ART / f"PLAN_{zone}_codex.png"
	img.save(sortie)
	return sortie


# ---------------------------------------------------------------- plans annotés (font foi)
def _annoter(img: Image.Image, plan: Plan, ox: int, oy: int, case: int) -> None:
	d = ImageDraw.Draw(img, "RGBA")
	petite = fonte(max(9, min(14, case - 2)))

	def centre(c):
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def boite(cells, couleur, largeur=2):
		xs = [x for x, _ in cells]
		ys = [y for _, y in cells]
		d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1,
			oy + (max(ys) + 1) * case - 1], outline=couleur, width=largeur)

	def etiquette(c, t, couleur, dy=-0.9):
		cx, cy = centre(c)
		cy += dy * case
		cx = min(max(cx, ox + 30), ox + plan.width * case - 30)
		cy = min(max(cy, oy + 8), oy + plan.height * case - 8)
		b = d.textbbox((cx, cy), t, font=petite, anchor="mm")
		d.rectangle([b[0] - 2, b[1] - 1, b[2] + 2, b[3] + 1], fill=(0, 0, 0, 170))
		d.text((cx, cy), t, font=petite, fill=couleur, anchor="mm")

	def libre(c):
		return (0 <= c[0] < plan.width and 0 <= c[1] < plan.height and plan.at(*c) in plan.praticables
			and not any(p.bloque and c in p.cells for p in plan.positions.values()))

	for p in plan.of_kind("spawn"):
		boite(p.cells, (120, 220, 120, 230), 1)
	for p in plan.of_kind("warp"):
		boite(p.cells, (255, 120, 220, 255), 2 if case >= 8 else 1)
		cible = p.note.split("→")[1].split(",")[0].strip() if "→" in p.note else ""
		etiquette(p.cells[0], ("→ " + cible) if cible else p.ident, (255, 190, 240))
	for p in plan.of_kind("declencheur") + plan.of_kind("courant"):
		couleur = (255, 150, 40, 255) if p.kind == "declencheur" else (255, 255, 255, 230)
		boite(p.cells, couleur, 2 if case >= 8 else 1)
		etiquette(p.cells[len(p.cells) // 2], p.ident, (255, 200, 140) if p.kind == "declencheur" else (240, 240, 240),
			dy=0.95 if p.kind == "declencheur" else -0.9)
	for p in plan.of_kind("dresseur"):
		f = FACINGS[p.attrs.get("facing", "down")]
		c = p.cells[0]
		for k in range(1, int(p.attrs.get("sight", "0")) + 1):
			v = (c[0] + f[0] * k, c[1] + f[1] * k)
			if not libre(v):
				break
			d.rectangle([ox + v[0] * case, oy + v[1] * case, ox + (v[0] + 1) * case - 1, oy + (v[1] + 1) * case - 1],
				fill=(230, 40, 40, 110))
		cx, cy = centre(c)
		r = max(3, case * 0.42)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		d.line([cx, cy, cx + f[0] * r * 1.4, cy + f[1] * r * 1.4], fill=(255, 255, 255, 255), width=2)
		etiquette(c, p.attrs.get("trainer", p.ident) + (" (I)" if p.attrs.get("inevitable") == "oui" else ""),
			(255, 230, 60) if p.attrs.get("inevitable") == "oui" else (255, 120, 120))
	for p in plan.of_kind("objet") + plan.of_kind("objet_visible") + plan.of_kind("cache"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.38)
		if p.kind == "cache":
			pts = []
			for i in range(10):
				a = -math.pi / 2 + i * math.pi / 5
				rr = r if i % 2 == 0 else r * 0.45
				pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
			d.polygon(pts, fill=(255, 220, 40, 255), outline=(0, 0, 0, 255))
		else:
			d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 220, 40, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.attrs.get("objet", p.attrs.get("item", p.ident)), (255, 235, 120), dy=0.95)
	for p in plan.of_kind("pnj"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.38)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 150, 255, 255), outline=(0, 0, 0, 255))
		f = FACINGS.get(p.attrs.get("facing", ""), None)
		if f:
			d.line([cx, cy, cx + f[0] * r * 1.4, cy + f[1] * r * 1.4], fill=(255, 255, 255, 255), width=2)
		etiquette(p.cells[0], p.ident, (170, 210, 255), dy=0.95)
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.42)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(190, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.attrs.get("species", p.ident), (230, 190, 255), dy=0.95)
	for p in plan.of_kind("panneau"):
		x0, y0 = ox + p.cells[0][0] * case, oy + p.cells[0][1] * case
		m = max(1, case // 5)
		d.rectangle([x0 + m, y0 + m, x0 + case - 1 - m, y0 + case - 1 - m], fill=(255, 255, 255, 255),
			outline=(60, 40, 20, 255))


def _legende(img: Image.Image, x: int, y: int, plan: Plan, genre: str, colonnes: int, t: int = 14) -> int:
	d = ImageDraw.Draw(img, "RGBA")
	police = fonte(t)
	couleurs = {"grotte": COULEURS_GROTTE, "interieur": COULEURS_INT}.get(genre, COULEURS_EXT)
	presents = {ch for row in plan.rows for ch in row}
	legende = {"grotte": LEGENDE_GROTTE, "interieur": LEGENDE_INT}.get(genre, LEGENDE_EXT)
	entrees = [(ch, nom) for ch, nom in legende if ch in presents]
	larg = 230
	for i, (ch, nom) in enumerate(entrees):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		sw = SWATCH_INT if genre == "interieur" else SWATCH
		d.rectangle([cx, cy, cx + t, cy + t], fill=sw.get(ch, couleurs[ch]), outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), f"{ch}  {nom}", font=police, fill=(240, 240, 240))
	y += ((len(entrees) + colonnes - 1) // colonnes) * (t + 8) + 8
	for i, (coul, nom) in enumerate(SYMBOLES):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		d.ellipse([cx, cy, cx + t, cy + t], fill=coul, outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), nom, font=police, fill=(240, 240, 240))
	return y + ((len(SYMBOLES) + colonnes - 1) // colonnes) * (t + 8)


def plan_annote(grille: str, genre: str, titre: str, styles=None) -> Path:
	plan = lire(PLANS / f"{grille}.txt")
	case = max(8, min(36, int(1700 / max(plan.width, plan.height))))
	marge, haut, bas = 40, 56, 200
	w = max(plan.width * case + 2 * marge, 960)
	img = Image.new("RGB", (w, plan.height * case + haut + bas), (28, 30, 34))
	ox = (w - plan.width * case) // 2
	dessiner_aplats(img, plan, ox, haut, case, genre, styles)
	_annoter(img, plan, ox, haut, case)
	d = ImageDraw.Draw(img)
	d.text((ox, 14), f"{titre} — tools/plans/{grille}.txt (fait foi)", font=fonte(22, True), fill=(255, 255, 255))
	petite = fonte(11)
	pas = 5 if case >= 14 else 10
	for x in range(0, plan.width, pas):
		d.text((ox + (x + 0.5) * case, haut - 8), str(x), font=petite, fill=(200, 200, 200), anchor="mm")
	for y in range(0, plan.height, pas):
		d.text((ox - 14, haut + (y + 0.5) * case), str(y), font=petite, fill=(200, 200, 200), anchor="mm")
	_legende(img, 20, haut + plan.height * case + 16, plan, genre, colonnes=max(2, min(4, w // 240)))
	PLANS_REF.mkdir(parents=True, exist_ok=True)
	sortie = PLANS_REF / nom_plan(grille)
	img.save(sortie, optimize=True)
	return sortie


# ---------------------------------------------------------------- planche de relecture
def planche(jalon: str) -> Path:
	hauteur = 640
	police = fonte(26)
	lignes = []
	for zone in JALONS[jalon]:
		grille, titre = zone[1], zone[4]
		images = []
		for f in (REF / nom_vue(grille), PLANS_REF / nom_plan(grille)):
			im = Image.open(f).convert("RGB")
			images.append(im.resize((round(im.width * hauteur / im.height), hauteur), Image.LANCZOS))
		texte = f"{titre}  |  {nom_vue(grille)}  |  plan (fait foi) : plans-johto/{nom_plan(grille)}"
		largeur = max(sum(i.width for i in images) + 40 * 3, int(police.getlength(texte)) + 80)
		ligne = Image.new("RGB", (largeur, hauteur + 70), (28, 30, 34))
		ImageDraw.Draw(ligne).text((40, 18), texte, fill=(235, 235, 235), font=police)
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
	sortie = REF / f"{jalon}-vues-v1.png"
	tout.save(sortie, optimize=True)
	return sortie


def main() -> int:
	args = sys.argv[1:]
	if not args or args[0] not in ("--plans", "--plans-annotes", "--planche"):
		print(__doc__)
		return 2
	jalons = args[1:] or list(JALONS)
	for jalon in jalons:
		for zone, grille, taille, genre, titre, *reste in JALONS[jalon]:
			styles = reste[0] if reste else None
			if args[0] == "--plans":
				print(plan_codex(zone, grille, taille, genre, styles))
			elif args[0] == "--plans-annotes":
				print(plan_annote(grille, genre, titre, styles))
		if args[0] == "--planche":
			print(planche(jalon))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
