#!/usr/bin/env python3
"""Plans en aplats des grilles du jalon 17 (Route 11, Cave Taupiqueur, Route 2 est).

Enveloppe de `plan_aplats.py` SANS le modifier : elle réutilise `dessiner_route_3` (même rendu de
paroi, d'affleurements, de bouche de grotte, de buissons, de panneaux et d'objets) après avoir
ajouté à sa table `R3_FOND` les caractères propres au J17 (mer, digue, clôtures, poste, arbuste,
éboulis, gravats) et, pour la Cave et le poste, traduit la légende de la grille vers celle de la
Route 3 dans un fichier temporaire. Les personnages, Pokémon d'ambiance et la case cachée ne sont
PAS dessinés (le plan peut être joint à Codex) ; `--annote` ajoute un second PNG de RELECTURE
(Dresseurs et lignes de vue, Ronflex, objets, case cachée, herbes, coupes d'itinéraire, arbuste,
raccords), JAMAIS joint à Codex.

Usage : python3 tools/art/plan_aplats_j17.py [--annote]
        → docs/design/reference/route-11-plan-v1.png, cave-taupiqueur-plan-v1.png,
          route-2-est-plan-v1.png (et *-annote-v1.png avec --annote)
"""
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_check import FACINGS  # noqa: E402
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "docs" / "design" / "reference"
PORTRAIT = (1024, 1536)

MER = (58, 108, 168)
DIGUE = (203, 192, 170)
CLOTURE = (140, 104, 64)
POSTE_MUR = (176, 140, 98)
POSTE_TOIT = (84, 92, 104)
ARBUSTE = (28, 96, 44)
EBOULIS = (118, 108, 98)
SENTIER_PEINT = (190, 170, 120)
GRAVATS = (142, 124, 98)
# Cave : « # » → K (paroi), « . » → o (sol calme), « g » gravats, « o » → R (rocher), « E » → o
# (les deux bouches sont dessinées à part : « Q » de dessiner_route_3 relie toutes les ouvertures).
TRADUCTION = {
	"digletts_cave": str.maketrans({"#": "K", ".": "o", "o": "R", "E": "o"}),
	"route_2_east": str.maketrans({"D": "P"}),
}
PLANS = {
	# nom de grille : (taille de l'image, fichier)
	"route_11": (pa.TAILLE_PAYSAGE, "route-11-plan-v1.png"),
	"digletts_cave": (PORTRAIT, "cave-taupiqueur-plan-v1.png"),
	"route_2_east": (PORTRAIT, "route-2-est-plan-v1.png"),
}


def _grille_traduite(nom: str, dossier: Path) -> Path:
	source = (RACINE / "tools" / "plans" / f"{nom}.txt").read_text(encoding="utf-8").split("\n")
	table = TRADUCTION.get(nom)
	sortie, dans_grille = [], False
	for ligne in source:
		mots = ligne.split()
		if mots and mots[0] == "GRILLE":
			dans_grille = True
		elif mots and mots[0] == "FIN":
			dans_grille = False
		elif dans_grille and table is not None and len(mots) == 2 and mots[0].isdigit():
			ligne = f"{mots[0]} {mots[1].translate(table)}"
		sortie.append(ligne)
	f = dossier / f"{nom}.txt"
	f.write_text("\n".join(sortie), encoding="utf-8")
	return f


def dessiner(nom: str, destination: Path) -> Path:
	taille, _ = PLANS[nom]
	pa.TAILLE_PAYSAGE = taille
	pa.R3_FOND.update({"W": MER, "q": DIGUE, "c": CLOTURE, "P": POSTE_MUR, "A": ARBUSTE,
		"E": EBOULIS, "e": SENTIER_PEINT, "g": GRAVATS})
	with tempfile.TemporaryDirectory() as tmp:
		grille = _grille_traduite(nom, Path(tmp))
		pa.dessiner_route_3(grille, destination)
	plan = lire(RACINE / "tools" / "plans" / f"{nom}.txt")
	img = Image.open(destination).convert("RGB")
	d = ImageDraw.Draw(img)
	case, ox, oy = pa._geometrie(plan, taille)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def rect(cases, fill, outline=None) -> None:
		xs = [x for x, _ in cases]
		ys = [y for _, y in cases]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=fill, outline=outline, width=2)

	if nom == "route_11":
		for x, y in plan.cells_of("c"):          # clôtures : une lisse et des poteaux
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0 + case // 2 - 2, x0 + case - 1, y0 + case // 2 + 1], fill=CLOTURE)
			d.rectangle([x0 + case // 2 - 2, y0 + 3, x0 + case // 2 + 1, y0 + case - 4],
				fill=pa.PORTE)
		for x, y in plan.cells_of("q"):          # joints de la digue
			x0, y0 = coin(x, y)
			d.line([x0, y0 + case - 1, x0 + case - 1, y0 + case - 1], fill=(170, 158, 138), width=1)
		for x, y in plan.cells_of("W"):          # vagues
			if (x + 2 * y) % 4 == 0:
				x0, y0 = coin(x, y)
				d.line([x0 + 3, y0 + case // 2, x0 + case - 4, y0 + case // 2], fill=(96, 146, 200),
					width=2)
	if nom == "route_2_east":
		poste = plan.cells_of("P") + plan.cells_of("D")
		rect(poste, POSTE_MUR, pa.PORTE)
		xs = [x for x, _ in poste]
		ys = [y for _, y in poste]
		x0, y0 = coin(min(xs), min(ys))
		x1, y1 = coin(max(xs) + 1, max(ys) + 1)
		d.rectangle([x0, y0, x1 - 1, y0 + (y1 - y0) * 3 // 5], fill=POSTE_TOIT, outline=pa.PORTE)
		for x, y in plan.cells_of("D"):
			px, py = coin(x, y)
			d.rectangle([px + 2, py + case // 4, px + case - 3, py + case - 1], fill=pa.PORTE)
		for x, y in plan.cells_of("A"):          # arbuste coupable
			cx, cy = coin(x, y)[0] + case / 2, coin(x, y)[1] + case / 2
			pa._disque(d, cx, cy, case * 0.46, ARBUSTE, pa.SOMBRE_BORD)
	if nom == "digletts_cave":
		for x, y in plan.cells_of("E"):          # bouches : ouverture sombre dans le bord de carte
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=pa.R3_GROTTE,
				outline=pa.R3_GROTTE_BORD)
		for x, y in plan.cells_of("g"):          # gravats : petits cailloux
			if (x * 7 + y * 3) % 3 == 0:
				cx, cy = coin(x, y)[0] + case / 2, coin(x, y)[1] + case / 2
				pa._disque(d, cx, cy, 2, (110, 94, 72))
	img.save(destination)
	return destination


def annoter(nom: str, plan_png: Path, sortie: Path) -> Path:
	"""Version de RELECTURE (jamais jointe à Codex)."""
	taille, _ = PLANS[nom]
	plan = lire(RACINE / "tools" / "plans" / f"{nom}.txt")
	img = Image.open(plan_png).convert("RGBA")
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	case, ox, oy = pa._geometrie(plan, taille)

	def fonte(t: int):
		for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
			try:
				return ImageFont.truetype(chemin, t)
			except OSError:
				continue
		return ImageFont.load_default(size=t)
	police, petite = fonte(max(11, case - 6)), fonte(max(9, case - 10))

	def centre(c) -> tuple[float, float]:
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def etiquette(c, texte: str, couleur, f=police, dx: float = 0, dy: float = -case * 0.7) -> None:
		cx, cy = centre(c)
		box = d.textbbox((cx + dx, cy + dy), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 2, box[1] - 1, box[2] + 2, box[3] + 1], fill=(0, 0, 0, 175))
		d.text((cx + dx, cy + dy), texte, font=f, fill=couleur, anchor="mm")

	for x in range(plan.width + 1):
		d.line([ox + x * case, oy, ox + x * case, oy + plan.height * case],
			fill=(0, 0, 0, 55 if x % 5 else 120), width=1)
	for y in range(plan.height + 1):
		d.line([ox, oy + y * case, ox + plan.width * case, oy + y * case],
			fill=(0, 0, 0, 55 if y % 5 else 120), width=1)
	for x in range(0, plan.width, 5):
		d.text((ox + (x + 0.5) * case, oy - 8), str(x), font=petite, fill=(255, 255, 255, 255),
			anchor="mm")
	for y in range(0, plan.height, 5):
		d.text((ox - 10, oy + (y + 0.5) * case), str(y), font=petite, fill=(255, 255, 255, 255),
			anchor="mm")
	for p in plan.of_kind("itineraire"):
		xs = [x for x, _ in p.cells]
		ys = [y for _, y in p.cells]
		d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1,
			oy + (max(ys) + 1) * case - 1], outline=(255, 255, 255, 190), width=2)
		etiquette((min(xs), min(ys)), p.attrs.get("role", ""), (255, 255, 255, 255), petite, dx=0,
			dy=-case * 0.8)
	for p in plan.of_kind("dresseur"):
		fx, fy = FACINGS[p.attrs["facing"]]
		c = p.cells[0]
		for k in range(1, int(p.attrs["sight"]) + 1):
			x0, y0 = ox + (c[0] + fx * k) * case, oy + (c[1] + fy * k) * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(230, 40, 40, 120))
		cx, cy = centre(c)
		d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		etiquette(c, f"{p.attrs.get('role')} {p.ident}", (255, 150, 150, 255), petite)
	for p in plan.of_kind("pnj"):
		xs = [x for x, _ in p.cells]
		ys = [y for _, y in p.cells]
		d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1,
			oy + (max(ys) + 1) * case - 1], fill=(70, 140, 255, 150), outline=(0, 0, 0, 255), width=2)
		etiquette(p.cells[0], f"{p.attrs.get('role')} {p.ident}", (160, 200, 255, 255), petite)
	for p in plan.of_kind("objet_visible") + plan.of_kind("cache"):
		c = p.cells[0]
		cx, cy = centre(c)
		if p.kind == "cache":
			d.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 220, 40, 255),
				outline=(0, 0, 0, 255))
		etiquette(c, f"{p.attrs.get('role')}{'*' if p.kind == 'cache' else ''} {p.attrs.get('item')}",
			(255, 230, 90, 255), petite, dy=case * 0.8)
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(200, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.ident.split("_")[0], (225, 170, 245, 255), petite, dy=case * 0.8)
	for p in plan.of_kind("herbes") + plan.of_kind("gravats"):
		etiquette(p.cells[0], p.attrs.get("role", p.ident), (240, 255, 150, 255), petite, dy=0)
	for p in plan.of_kind("panneau"):
		etiquette(p.cells[0], p.attrs.get("role", "panneau"), (255, 210, 120, 255), petite)
	for p in plan.of_kind("arbuste"):
		etiquette(p.cells[0], "ARBUSTE", (120, 255, 120, 255), petite, dx=case * 1.8, dy=0)
	for p in plan.of_kind("repere"):
		if p.attrs.get("role") in ("R1", "R2", "route_12"):
			etiquette(p.cells[0], p.attrs["role"], (255, 255, 255, 255), petite, dy=0)
	for p in plan.of_kind("warp"):
		etiquette(p.cells[0], "warp", (255, 180, 255, 255), petite, dy=-case * 1.4)
	img = Image.alpha_composite(img, calque).convert("RGB")
	img.save(sortie)
	return sortie


def main() -> int:
	SORTIE.mkdir(parents=True, exist_ok=True)
	for nom, (_, fichier) in PLANS.items():
		destination = SORTIE / fichier
		print(dessiner(nom, destination))
		if "--annote" in sys.argv:
			print(annoter(nom, destination, destination.with_name(
				destination.stem.replace("-plan-", "-plan-annote-") + ".png")))
	return 0


if __name__ == "__main__":
	sys.exit(main())
