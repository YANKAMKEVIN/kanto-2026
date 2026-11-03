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
# jalon → [(ZONE Codex, grille, format, genre, titre)] ; genre : grotte | exterieur
JALONS: dict[str, list[tuple[str, str, tuple[int, int], str, str]]] = {
	"joh1": [
		("GROTTE_MARINE_1", "grotte_marine_1", PORTRAIT, "grotte", "Grotte marine, salle 1 (30 × 40)"),
		("GROTTE_MARINE_2", "grotte_marine_2", PORTRAIT, "grotte", "Grotte marine, salle 2 (30 × 40)"),
		("OLIVILLE", "oliville", PAYSAGE, "exterieur", "Oliville (50 × 40)"),
	],
}


def nom_vue(grille: str) -> str:
	return grille.replace("_", "-") + "-vue-generale-v1.png"


def nom_plan(grille: str) -> str:
	return grille.replace("_", "-") + "-plan-v1.png"


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
}
COULEURS_GROTTE = {
	"#": ROCHE, "o": EAU, ".": (150, 150, 158), "g": GALETS, "w": EAU, "d": EAU_PROFONDE, ">": EAU, "<": EAU,
	"v": EAU, "^": EAU, "E": (200, 186, 150),
}
LEGENDE_EXT = [
	("T", "forêt, bordure d'arbres"), ("R", "falaise, rochers"), (".", "pelouse"), ("=", "chemin"),
	("p", "pavé"), ("h", "hautes herbes"), ("g", "plage de galets"), ("q", "quai, pontons"), ("w", "eau surfable"),
	("x", "haie"), ("y", "massif de fleurs"), ("n", "banc"), ("G", "arbre repère"), ("k", "caisses"),
	("C", "Centre"), ("O", "Boutique"), ("m", "Maison 1"), ("N", "Maison 2"), ("P", "Phare"), ("D", "porte"),
	("E", "bouche de grotte"),
]
LEGENDE_GROTTE = [
	("#", "paroi"), ("o", "rocher isolé"), (".", "îlot, corniche"), ("g", "plage de galets"), ("w", "eau surfable"),
	("d", "eau profonde"), (">", "courant →"), ("v", "courant ↓"), ("E", "sortie à pied"),
]
# Pastilles de légende des caractères dont la couleur de fond n'est pas parlante (dessinés par-dessus).
SWATCH = {
	"x": (40, 110, 50), "y": (240, 120, 170), "n": BOIS, "G": (32, 96, 48), "k": BOIS, "C": (200, 60, 60),
	"O": (60, 100, 200), "m": (176, 70, 52), "N": (176, 70, 52), "P": (240, 240, 236), "D": (60, 80, 120),
	"E": (30, 30, 36), "o": (118, 120, 132), ">": (225, 240, 255), "v": (225, 240, 255),
}
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


def dessiner_aplats(img: Image.Image, plan: Plan, ox: int, oy: int, case: int, genre: str) -> None:
	"""Aplats et détails « muets » (sans PNJ, objet ni étiquette) de la grille, à `case` px la case."""
	d = ImageDraw.Draw(img)
	couleurs = COULEURS_GROTTE if genre == "grotte" else COULEURS_EXT
	defaut = ROCHE if genre == "grotte" else FORET

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	for y in range(plan.height):
		for x in range(plan.width):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleurs.get(plan.at(x, y), defaut))
	if genre == "grotte":
		_details_grotte(d, plan, coin, case)
	else:
		_details_exterieur(d, plan, coin, case)


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


def _details_exterieur(d, plan, coin, case) -> None:
	for x, y in plan.cells_of("T"):                     # bord de la forêt
		if _bord(plan, x, y, "T"):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=FORET_BORD)
	for x, y in plan.cells_of("R") + plan.cells_of("P") + plan.cells_of("E"):   # falaise : rochers
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
	_vagues(d, plan, coin, case, "w")
	for x, y in plan.cells_of("h"):                     # hautes herbes : touffes
		x0, y0 = coin(x, y)
		d.line([x0 + 2, y0 + case - 3, x0 + case // 2, y0 + 3], fill=(110, 130, 20), width=1)
		d.line([x0 + case - 3, y0 + case - 3, x0 + case // 2, y0 + 3], fill=(110, 130, 20), width=1)
	for x, y in plan.cells_of("x"):                     # haie : bande continue
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
	for lettre, toit, mur in (("C", (200, 60, 60), (236, 232, 224)), ("O", (60, 100, 200), (236, 232, 224)),
			("m", (176, 70, 52), (226, 214, 190)), ("N", (176, 70, 52), (226, 214, 190))):
		cases = plan.cells_of(lettre)
		if not cases:
			continue
		x0, y0, x1, y1 = _boite(d, cases, coin, fill=mur, outline=(90, 60, 40), width=2)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=toit, outline=(90, 40, 30), width=2)
		if lettre in "CO":                              # emblème rond sans texte
			cx, cy, r = (x0 + x1) // 2, y0 + (y1 - y0) * 3 // 10, (y1 - y0) // 8
			d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(245, 245, 245), outline=(60, 60, 60))
	if plan.cells_of("P"):                              # Phare : tour blanche à bandes, lanterne rouge
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
	for x, y in plan.cells_of("E"):                     # bouche de grotte dans la falaise
		px, py = coin(x, y)
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


def plan_codex(zone: str, grille: str, taille: tuple[int, int], genre: str) -> Path:
	plan = lire(PLANS / f"{grille}.txt")
	img = Image.new("RGB", taille, ROCHE if genre == "grotte" else FORET)
	case, ox, oy = _geometrie(plan.width, plan.height, taille)
	dessiner_aplats(img, plan, ox, oy, case, genre)
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
	couleurs = COULEURS_GROTTE if genre == "grotte" else COULEURS_EXT
	presents = {ch for row in plan.rows for ch in row}
	entrees = [(ch, nom) for ch, nom in (LEGENDE_GROTTE if genre == "grotte" else LEGENDE_EXT) if ch in presents]
	larg = 230
	for i, (ch, nom) in enumerate(entrees):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		d.rectangle([cx, cy, cx + t, cy + t], fill=SWATCH.get(ch, couleurs[ch]), outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), f"{ch}  {nom}", font=police, fill=(240, 240, 240))
	y += ((len(entrees) + colonnes - 1) // colonnes) * (t + 8) + 8
	for i, (coul, nom) in enumerate(SYMBOLES):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		d.ellipse([cx, cy, cx + t, cy + t], fill=coul, outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), nom, font=police, fill=(240, 240, 240))
	return y + ((len(SYMBOLES) + colonnes - 1) // colonnes) * (t + 8)


def plan_annote(grille: str, genre: str, titre: str) -> Path:
	plan = lire(PLANS / f"{grille}.txt")
	case = max(8, min(36, int(1700 / max(plan.width, plan.height))))
	marge, haut, bas = 40, 56, 200
	w = max(plan.width * case + 2 * marge, 960)
	img = Image.new("RGB", (w, plan.height * case + haut + bas), (28, 30, 34))
	ox = (w - plan.width * case) // 2
	dessiner_aplats(img, plan, ox, haut, case, genre)
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
	for _, grille, _, _, titre in JALONS[jalon]:
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
		for zone, grille, taille, genre, titre in JALONS[jalon]:
			if args[0] == "--plans":
				print(plan_codex(zone, grille, taille, genre))
			elif args[0] == "--plans-annotes":
				print(plan_annote(grille, genre, titre))
		if args[0] == "--planche":
			print(planche(jalon))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
