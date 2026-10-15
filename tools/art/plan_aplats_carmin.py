#!/usr/bin/env python3
"""Plans en aplats de la Route 6 et de Carmin-sur-Mer (jalon 15, dossier 18 §6, §8).

Légende de `tools/plans/route_6.txt` et `vermilion_city.txt`. Route 6 en portrait 1024 × 1536
(24 px par case), Carmin en paysage 1536 × 1024 (23 px par case). Personnages et Pokémon NON
dessinés (le plan peut être joint à Codex) ; Poké Balls visibles et panneaux dessinés.
`--annote` ajoute <sortie>_annote.png (Dresseurs, lignes de vue, PNJ, objets, portes : relecture,
JAMAIS jointe à Codex).

Usage : python3 tools/art/plan_aplats_carmin.py [route_6|vermilion_city] [--annote]
        (ou python3 tools/art/plan_aplats.py tools/plans/<grille>.txt [sortie.png] [--annote])
        → build/plans/PLAN_ROUTE6_v1.png, build/plans/PLAN_CARMIN_v1.png
Reproductible : même grille → même image (graine fixe).
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
SORTIES = {"route_6": "build/plans/PLAN_ROUTE6_v1.png", "vermilion_city": "build/plans/PLAN_CARMIN_v1.png"}

C_EAU = (38, 96, 150)
C_QUAI = (152, 112, 72)
C_QUAI_BORD = (96, 66, 40)
C_PASSERELLE = (120, 84, 52)
C_COQUE = (74, 88, 108)
C_PONT = (206, 204, 196)
C_CHEMINEE = (196, 62, 48)
C_BITTE = (60, 50, 44)
C_CAISSE = (130, 92, 56)
C_ARBRE_JEUNE = (96, 168, 78)
FOND = {
	"T": pa.FORET, ".": pa.HERBE, "=": pa.CHEMIN, "h": pa.HAUTES_HERBES, "W": C_EAU,
	"R": pa.HERBE, "G": pa.HERBE, "x": pa.HERBE, "c": pa.HERBE, "p": pa.PAVE, "n": pa.PAVE,
	"q": C_QUAI, "g": C_PASSERELLE, "E": C_PASSERELLE, "N": C_COQUE, "z": C_QUAI, "k": C_QUAI,
	"A": pa.HERBE, "U": pa.POSTE, "P": pa.POSTE, "D": pa.PORTE,
}
# Bâtiments : (mur, toit).
BATIMENTS = {**pa.BATIMENTS, "F": ((236, 226, 205), (70, 140, 112)),
	"U": (pa.POSTE, pa.POSTE_TOIT), "P": (pa.POSTE, pa.POSTE_TOIT)}
EMPRISES = "MZCOmFUP"


def _taille(plan) -> tuple[int, int]:
	return pa.TAILLE_PAYSAGE if plan.width > plan.height else pa.TAILLE


def dessiner(grille: Path, sortie: Path) -> Path:
	plan = lire(grille)
	taille = _taille(plan)
	case, ox, oy = pa._geometrie(plan, taille)
	img = Image.new("RGB", taille, pa.FORET)
	d = ImageDraw.Draw(img)
	alea = random.Random(pa.GRAINE + 6)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	# 1. Aplats ; les portes prennent la couleur du mur voisin.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			fond = FOND.get(c) or BATIMENTS[c][0]
			if c == "D":
				for vx, vy in ((x - 1, y), (x + 1, y), (x, y - 1)):
					if 0 <= vx < plan.width and 0 <= vy < plan.height \
							and plan.rows[vy][vx] in EMPRISES:
						fond = BATIMENTS[plan.rows[vy][vx]][0]
						break
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=fond)
			if c == "=":      # chemins qui sortent de la carte : prolongés jusqu'au bord
				x1, y1 = x0 + case - 1, y0 + case - 1
				if x == 0:
					d.rectangle([0, y0, x0, y1], fill=pa.CHEMIN)
				if x == plan.width - 1:
					d.rectangle([x1, y0, taille[0], y1], fill=pa.CHEMIN)
				if y == 0:
					d.rectangle([x0, 0, x1, y0], fill=pa.CHEMIN)
				if y == plan.height - 1:
					d.rectangle([x0, y1, x1, taille[1]], fill=pa.CHEMIN)
	# Planches : joints un rang sur deux ; pavés : damier léger ; fleurs sur l'herbe rase.
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if c in "qg" and y % 2 == 0:
				d.line([x0, y0, x0 + case - 1, y0], fill=C_QUAI_BORD, width=1)
			elif c == "p" and (x + y) % 2 == 0:
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1],
					fill=pa._melange(pa.PAVE, pa.BLANC, 0.12))
			elif c == "." and alea.random() < 0.10:
				cx, cy = centre(x, y)
				pa._disque(d, cx + alea.uniform(-4, 4), cy + alea.uniform(-4, 4), 2, pa.FLEUR)
	# 2. Bâtiments : toit sur le haut de l'emprise (moitié pour 3 rangées, 3/5 sinon), portes.
	for char in EMPRISES:
		for groupe in pa._composantes(plan, char):
			xs = [x for x, _ in groupe]
			ys = [y for _, y in groupe]
			x0, y0 = coin(min(xs), min(ys))
			x1, y1 = coin(max(xs) + 1, max(ys) + 1)
			part = (1, 2) if max(ys) - min(ys) + 1 == 3 else (3, 5)
			d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * part[0] // part[1]],
				fill=BATIMENTS[char][1])
	for x, y in plan.cells_of("D"):
		if any(0 <= x2 < plan.width and plan.rows[y][x2] in EMPRISES for x2 in (x - 1, x + 1)):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + case // 4, y0 + case // 4, x0 + case - case // 4 - 1,
				y0 + case - 1], fill=pa.PORTE)
	# 3. S.S. Anne : coque (N + E), pont clair, superstructure, cheminée.
	coque = plan.cells_of("N") + plan.cells_of("E")
	if coque:
		xs = [x for x, _ in coque]
		ys = [y for _, y in coque]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=C_COQUE, outline=(30, 40, 56), width=2)
		d.rectangle([x0 + 8, y0 + 8, x1 - 9, y0 + 2 * case], fill=C_PONT)
		milieu = (x0 + x1) // 2
		d.rectangle([milieu - 6 * case, y0 + 2 * case, milieu + 6 * case, y0 + 4 * case],
			fill=(226, 224, 216), outline=(120, 120, 126), width=2)
		d.rectangle([milieu - case, y0 + case, milieu + case, y0 + 2 * case], fill=C_CHEMINEE)
		for x, y in plan.cells_of("E"):
			ex, ey = coin(x, y)
			d.rectangle([ex, ey, ex + case - 1, ey + case - 1], fill=C_PASSERELLE)
	# 4. Symboles par case.
	panneaux = {c for p in plan.of_kind("panneau") for c in p.cells}
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			cx, cy = centre(x, y)
			x0, y0 = coin(x, y)
			if c == "x" and (x, y) not in panneaux:
				pa._disque(d, cx, cy, case * 0.38, pa.BUISSON, pa.SOMBRE_BORD)
			elif c == "G":
				pa._disque(d, cx, cy - case * 0.5, case, pa.ARBRE, pa.ARBRE_BORD)
			elif c == "R":
				d.rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=pa.PIERRE,
					outline=pa.PIERRE_BORD)
			elif c == "c":
				d.rectangle([x0, cy - 2, x0 + case - 1, cy + 2], fill=pa.BLANC)
			elif c == "n":
				d.rectangle([x0 + 2, cy - 3, x0 + case - 3, cy + 3], fill=pa.BANC)
			elif c == "k":
				d.rectangle([x0 + 2, y0 + 3, x0 + case - 3, y0 + case - 3], fill=C_CAISSE,
					outline=C_QUAI_BORD)
			elif c == "z":
				pa._disque(d, cx, cy, case * 0.3, C_BITTE, (20, 16, 14))
			elif c == "A":
				pa._disque(d, cx, cy, case * 0.45, C_ARBRE_JEUNE, pa.ARBRE_BORD)
	for x, y in sorted(panneaux):
		cx, cy = centre(x, y)
		d.rectangle([cx - 6, cy - 6, cx + 6, cy + 6], fill=pa.PANNEAU, outline=pa.PANNEAU_BORD)
	for p in plan.of_kind("objet_visible"):
		for x, y in p.cells:
			cx, cy = centre(x, y)
			r = 5
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=pa.BALL_ROUGE)
			d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=pa.BLANC)
			d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=pa.BALL_BORD, width=1)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def annoter(grille: Path, plan_png: Path, sortie: Path) -> Path:
	"""Version de RELECTURE : Dresseurs et lignes de vue, PNJ, objets (case cachée « * »),
	Pokémon d'ambiance, portes, déclencheurs, repères, zones d'herbes, graduations."""
	from plan_check import FACINGS, Monde, ligne_de_vue, nommer_zones
	plan = lire(grille)
	img = Image.open(plan_png).convert("RGBA")
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	case, ox, oy = pa._geometrie(plan, _taille(plan))
	police, petite = pa._fonte(15), pa._fonte(11)

	def centre(c) -> tuple[float, float]:
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def etiquette(c, texte: str, couleur, f=police, dx: float = 0, dy: float = -14) -> None:
		cx, cy = centre(c)
		box = d.textbbox((cx + dx, cy + dy), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 170))
		d.text((cx + dx, cy + dy), texte, font=f, fill=couleur, anchor="mm")

	for x in range(plan.width + 1):
		d.line([ox + x * case, oy, ox + x * case, oy + plan.height * case],
			fill=(0, 0, 0, 55 if x % 5 else 120), width=1)
	for y in range(plan.height + 1):
		d.line([ox, oy + y * case, ox + plan.width * case, oy + y * case],
			fill=(0, 0, 0, 55 if y % 5 else 120), width=1)
	for x in range(0, plan.width, 5):
		d.text((ox + x * case + 2, max(0, oy - 14)), str(x), font=petite, fill=(255, 255, 255, 255))
	for y in range(0, plan.height, 5):
		d.text((max(2, ox - 24), oy + y * case + 2), str(y), font=petite, fill=(255, 255, 255, 255))
	monde = Monde(plan)
	for p in plan.of_kind("dresseur"):
		role = p.attrs.get("role", p.ident)
		for c in ligne_de_vue(monde, p):
			cx, cy = centre(c)
			d.rectangle([cx - case / 2 + 1, cy - case / 2 + 1, cx + case / 2 - 1,
				cy + case / 2 - 1], fill=(255, 40, 40, 120 if role == "D1" else 80))
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		fx, fy = FACINGS[p.attrs["facing"]]
		d.line([cx, cy, cx + fx * 12, cy + fy * 12], fill=(255, 255, 255, 255), width=3)
		etiquette(p.cells[0], f"{role} {p.ident.capitalize()}"
			+ (" (inévitable)" if role == "D1" else ""), (255, 200, 200, 255), petite, dy=-14)
	for p in plan.of_kind("pnj"):
		for c in p.cells:
			cx, cy = centre(c)
			d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(60, 140, 255, 255),
				outline=(0, 0, 0, 255))
			etiquette(c, p.ident, (200, 225, 255, 255), petite, dy=12)
	for p in plan.of_kind("pokemon"):
		for c in p.cells:
			cx, cy = centre(c)
			d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(200, 90, 230, 255),
				outline=(0, 0, 0, 255))
	for p in plan.of_kind("objet_visible") + plan.of_kind("cache"):
		cache = p.kind == "cache"
		for c in p.cells:
			cx, cy = centre(c)
			d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6],
				fill=(255, 225, 40, 255) if cache else (255, 255, 255, 255), outline=(0, 0, 0, 255))
			etiquette(c, ("* " if cache else "") + p.attrs.get("item", p.ident),
				(255, 245, 150, 255), petite, dy=12)
	for p in plan.of_kind("warp"):
		c = p.cells[0]
		etiquette(c, p.ident, (255, 255, 255, 255), petite, dy=-12 if c[1] > 1 else 14)
	for p in plan.of_kind("declencheur"):
		for c in p.cells:
			cx, cy = centre(c)
			d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], outline=(255, 160, 40, 255), width=2)
	for p in plan.of_kind("repere"):
		c = p.cells[0]
		cx, cy = centre(c)
		d.polygon([(cx, cy - 7), (cx + 7, cy), (cx, cy + 7), (cx - 7, cy)],
			fill=(255, 150, 40, 255), outline=(0, 0, 0, 255))
		etiquette(c, p.ident, (255, 215, 160, 255), petite, dy=12)
	if plan.of_kind("herbes"):
		for nom, zone in nommer_zones(plan, ("H1", "H2", "H3", "H4")).items():
			xs = sorted(x for x, _ in zone)
			ys = sorted(y for _, y in zone)
			etiquette((xs[len(xs) // 2], ys[len(ys) // 2]), nom, (240, 255, 150, 255), dy=0)
	img = Image.alpha_composite(img, calque).convert("RGB")
	img.save(sortie)
	return sortie


def main_pour(grille: Path, sortie: Path | None, avec_annote: bool) -> int:
	sortie = sortie or RACINE / SORTIES[grille.stem]
	print(dessiner(grille, sortie))
	if avec_annote:
		print(annoter(grille, sortie, sortie.with_name(sortie.stem + "_annote.png")))
	return 0


def main() -> int:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	noms = [Path(args[0]).stem] if args else list(SORTIES)
	for nom in noms:
		main_pour(RACINE / "tools" / "plans" / f"{nom}.txt", None, "--annote" in sys.argv)
	return 0


if __name__ == "__main__":
	sys.exit(main())
