#!/usr/bin/env python3
"""Plans en aplats du jalon 18 (Route 9, Route 10) et relecture de l'arbre à couper d'Azuria.

Usage : python3 tools/art/plan_aplats_j18.py [route_9|route_10|azuria|tout] [dossier de sortie]
Sortie par défaut : build/plans_j18/ (non versionné). Chaque plan est écrit deux fois :
`<carte>.png` (aplats, sans personnages) et `<carte>_annote.png` (Dresseurs et lignes de vue,
objets, Pokémon, PNJ, herbes, coupes d'itinéraire, rebords, raccords) pour la RELECTURE.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_check import FACINGS, nommer_zones  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
EAU = (82, 150, 192)
CENTRALE = (120, 120, 132)
CASE = {"route_9": 16, "route_10": 12, "azuria": 18}
FOND = {
	"T": pa.FORET, ".": pa.HERBE, "=": pa.CHEMIN, "h": pa.HAUTES_HERBES, "v": pa.REBORD,
	"o": (176, 168, 150), "K": (122, 112, 100), "R": (150, 143, 132), "x": pa.HERBE,
	"w": EAU, "E": CENTRALE, "C": pa.BATIMENTS["C"][0], "D": pa.PORTE, "Q": (28, 26, 34),
}


def _police(taille: int):
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
		try:
			return ImageFont.truetype(chemin, taille)
		except OSError:
			continue
	return ImageFont.load_default(size=taille)


def dessiner(plan: Plan, stem: str) -> Image.Image:
	case = CASE[stem]
	marge = 24
	img = Image.new("RGB", (plan.width * case + 2 * marge, plan.height * case + 2 * marge), pa.FORET)
	d = ImageDraw.Draw(img)
	for y, row in enumerate(plan.rows):
		for x, car in enumerate(row):
			x0, y0 = marge + x * case, marge + y * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=FOND.get(car, pa.HERBE))
			if car == "K" and (x + 2 * y) % 5 == 0:
				d.line([x0 + 2, y0 + case // 2, x0 + case - 3, y0 + case // 2], fill=(108, 99, 89))
			if car == "R":
				d.ellipse([x0 + 3, y0 + 3, x0 + case - 4, y0 + case - 4], fill=pa.PIERRE,
					outline=pa.PIERRE_BORD)
			if car == "v":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case // 2], fill=(110, 90, 66))
			if car == "T" and (x * 7 + y * 3) % 5 == 0:
				d.ellipse([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=(10, 60, 36))
			if car == "k":
				d.ellipse([x0 - 4, y0 - 8, x0 + case + 3, y0 + case], fill=pa.ARBRE,
					outline=(255, 220, 40), width=2)
			if car == "c":
				d.rectangle([x0, y0 + case // 3, x0 + case - 1, y0 + 2 * case // 3], fill=(140, 100, 62))
	return img


def annoter(plan: Plan, img: Image.Image, stem: str) -> Image.Image:
	case, marge = CASE[stem], 24
	calque = Image.new("RGBA", img.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(calque)
	petite, police = _police(max(9, case - 4)), _police(max(10, case - 2))

	def centre(c):
		return marge + (c[0] + 0.5) * case, marge + (c[1] + 0.5) * case

	def etiquette(c, texte, couleur, f=petite, dx=0, dy=-case * 0.9):
		cx, cy = centre(c)
		box = d.textbbox((cx + dx, cy + dy), texte, font=f, anchor="mm")
		d.rectangle([box[0] - 1, box[1], box[2] + 1, box[3]], fill=(0, 0, 0, 170))
		d.text((cx + dx, cy + dy), texte, font=f, fill=couleur, anchor="mm")

	pas = 10
	for x in range(0, plan.width + 1, pas):
		d.line([marge + x * case, marge, marge + x * case, marge + plan.height * case],
			fill=(0, 0, 0, 90))
		d.text((marge + x * case, 10), str(x), font=petite, fill=(255, 255, 255, 255), anchor="mm")
	for y in range(0, plan.height + 1, pas):
		d.line([marge, marge + y * case, marge + plan.width * case, marge + y * case],
			fill=(0, 0, 0, 90))
		d.text((10, marge + y * case), str(y), font=petite, fill=(255, 255, 255, 255), anchor="mm")
	for p in plan.of_kind("itineraire"):
		xs, ys = [x for x, _ in p.cells], [y for _, y in p.cells]
		d.rectangle([marge + min(xs) * case, marge + min(ys) * case, marge + (max(xs) + 1) * case - 1,
			marge + (max(ys) + 1) * case - 1], outline=(255, 255, 255, 190), width=2)
		etiquette((min(xs), min(ys)), f"coupe {p.attrs.get('role')}", (255, 255, 255, 255), dy=-8)
	for p in plan.of_kind("dresseur"):
		fx, fy = FACINGS[p.attrs["facing"]]
		c = p.cells[0]
		for k in range(1, int(p.attrs["sight"]) + 1):
			x0, y0 = marge + (c[0] + fx * k) * case, marge + (c[1] + fy * k) * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=(230, 40, 40, 120))
		cx, cy = centre(c)
		d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		etiquette(c, f"{p.attrs.get('role')} {p.ident}", (255, 170, 170, 255))
	for p in plan.of_kind("pnj"):
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(70, 140, 255, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.ident, (170, 205, 255, 255))
	for p in plan.of_kind("objet_visible"):
		cx, cy = centre(p.cells[0])
		d.pieslice([cx - 5, cy - 5, cx + 5, cy + 5], 180, 360, fill=pa.BALL_ROUGE)
		d.pieslice([cx - 5, cy - 5, cx + 5, cy + 5], 0, 180, fill=pa.BLANC)
		etiquette(p.cells[0], f"{p.attrs.get('role')} {p.attrs.get('item')}", (255, 230, 90, 255),
			dy=case * 0.9)
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(200, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.ident.split("_")[0], (225, 170, 245, 255))
	for p in plan.of_kind("panneau"):
		cx, cy = centre(p.cells[0])
		d.rectangle([cx - 4, cy - 4, cx + 4, cy + 4], fill=pa.PANNEAU, outline=pa.PANNEAU_BORD)
	if plan.of_kind("herbes"):
		noms = tuple(p.attrs.get("role", p.ident) for p in plan.of_kind("herbes"))
		for nom, zone in nommer_zones(plan, noms).items():
			xs, ys = sorted(x for x, _ in zone), sorted(y for _, y in zone)
			etiquette((xs[len(xs) // 2], ys[len(ys) // 2]), nom, (240, 255, 150, 255), f=police, dy=0)
	for p in plan.of_kind("spawn"):
		etiquette(p.cells[0], p.ident, (180, 255, 255, 255), dy=case * 0.9)
	for p in plan.of_kind("warp"):
		for c in p.cells:
			cx, cy = centre(c)
			d.rectangle([cx - 3, cy - 3, cx + 3, cy + 3], outline=(255, 255, 255, 255))
	return Image.alpha_composite(img.convert("RGBA"), calque).convert("RGB")


def main() -> int:
	args = [a for a in sys.argv[1:]]
	cible = args[0] if args else "tout"
	sortie = Path(args[1]) if len(args) > 1 else RACINE / "build/plans_j18"
	sortie.mkdir(parents=True, exist_ok=True)
	for stem in (["route_9", "route_10", "azuria"] if cible == "tout" else [cible]):
		plan = lire(RACINE / f"tools/plans/{stem}.txt")
		if stem == "azuria":
			import plan_aplats  # noqa: F401
			base = Image.open(pa.dessiner_j13(RACINE / f"tools/plans/{stem}.txt",
				sortie / f"{stem}_ref.png")).convert("RGB")
			# L'arbre à couper « k » (53, 23) : encadré jaune sur le plan de référence du J13.
			case, ox, oy = pa._geom_j13(plan, "azuria")
			d = ImageDraw.Draw(base)
			for x, y in plan.cells_of("k"):
				d.ellipse([ox + x * case - 4, oy + (y - 1) * case, ox + (x + 1) * case + 4,
					oy + (y + 1) * case], fill=pa.ARBRE, outline=(255, 220, 40), width=3)
			base.crop((ox + 42 * case, oy + 16 * case, ox + plan.width * case,
				oy + 30 * case)).resize((case * 14 * 3, case * 14 * 3 * 14 // 14)).save(
				sortie / "azuria_est.png")
			print(sortie / "azuria_est.png")
			continue
		img = dessiner(plan, stem)
		img.save(sortie / f"{stem}.png")
		annoter(plan, img, stem).save(sortie / f"{stem}_annote.png")
		print(sortie / f"{stem}_annote.png")
	return 0


if __name__ == "__main__":
	sys.exit(main())
