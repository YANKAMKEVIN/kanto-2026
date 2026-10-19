#!/usr/bin/env python3
"""Plans en aplats de la Grotte Sombre (jalon 18) : 1F et B1F, annotés (Dresseurs et lignes de
vue, objets, échelles, halos, chemin principal, gravats obligatoires).

Usage : python3 tools/art/plan_aplats_grotte_sombre.py [dossier]   (défaut : build/plans_j18/)
Écrit grotte_sombre_1f.png, grotte_sombre_b1f.png et grotte_sombre_ensemble.png.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
import plan_check_grotte_sombre as ck  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402

CASE = 18
COUL = {
	"#": (34, 36, 46), ".": (128, 130, 140), "g": (150, 124, 90), "j": (226, 224, 180),
	"o": (84, 86, 98), "K": (96, 96, 112), "V": (176, 124, 66), "U": (176, 124, 66),
	"E": (230, 220, 160), "e": (230, 220, 160), "w": (44, 74, 112), "f": (220, 214, 170),
	"r": (96, 70, 48),
}
LUMIERES = {"shaft": (255, 244, 190), "lamp": (255, 206, 90)}


def fonte(t: int):
	for f in ("/System/Library/Fonts/Helvetica.ttc", "/Library/Fonts/Arial.ttf"):
		try:
			return ImageFont.truetype(f, t)
		except OSError:
			pass
	return ImageFont.load_default()


def dessiner(nom: str, plan: Plan, trajet: list, obligatoires: set) -> Image.Image:
	img = Image.new("RGB", (plan.width * CASE, plan.height * CASE + 22), (14, 14, 18))
	d = ImageDraw.Draw(img)
	for y in range(plan.height):
		for x in range(plan.width):
			d.rectangle([x * CASE, y * CASE + 22, (x + 1) * CASE - 1, (y + 1) * CASE + 21],
				fill=COUL.get(plan.at(x, y), (255, 0, 255)))
	d.rectangle([0, 0, img.width, 21], fill=(20, 20, 28))
	d.text((6, 3), f"Grotte Sombre {nom} : {plan.width} x {plan.height}", font=fonte(14),
		fill=(235, 235, 235))
	dec = lambda c: (c[0] * CASE, c[1] * CASE + 22)  # noqa: E731
	for (n, x, y) in obligatoires:
		if n == nom:
			px, py = dec((x, y))
			d.rectangle([px, py, px + CASE - 1, py + CASE - 1], outline=(255, 120, 40), width=2)
	pts = [(x * CASE + CASE // 2, y * CASE + CASE // 2 + 22) for (n, x, y) in trajet if n == nom]
	for a, b in zip(pts, pts[1:]):
		if abs(a[0] - b[0]) + abs(a[1] - b[1]) <= CASE:
			d.line([a, b], fill=(255, 70, 70), width=3)
	f = fonte(11)
	monde = ck.Monde(plan)
	for p in plan.positions.values():
		for c in p.cells:
			px, py = dec(c)
			cx, cy = px + CASE // 2, py + CASE // 2
			if p.kind == "dresseur":
				for v in ck.ligne_de_vue(monde, p):
					vx, vy = dec(v)
					d.rectangle([vx + 3, vy + 3, vx + CASE - 4, vy + CASE - 4],
						outline=(255, 60, 200), width=1)
				inev = p.attrs.get("inevitable") == "oui"
				d.ellipse([px + 1, py + 1, px + CASE - 2, py + CASE - 2],
					fill=(200, 40, 40) if inev else (60, 120, 220), outline=(255, 255, 255))
				d.text((px + 20, py - 2), p.attrs["role"], font=f, fill=(255, 220, 220))
			elif p.kind in ("objet_visible", "objet_cache"):
				d.polygon([(cx, py + 2), (px + CASE - 2, cy), (cx, py + CASE - 2), (px + 2, cy)],
					fill=(80, 230, 120) if p.kind == "objet_visible" else (230, 230, 80),
					outline=(0, 0, 0))
			elif p.kind == "halo":
				t = LUMIERES[p.attrs.get("type", "lamp")]
				d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], outline=t, width=2)
			elif p.kind == "echelle":
				d.text((px + 2, py), p.attrs["paire"], font=f, fill=(255, 255, 255))
			elif p.kind == "panneau":
				d.rectangle([px + 3, py + 3, px + CASE - 4, py + CASE - 4], fill=(230, 230, 230))
	return img


def main() -> int:
	sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else ck.RACINE / "build" / "plans_j18"
	sortie.mkdir(parents=True, exist_ok=True)
	plans = {n: lire(ck.PLANS / f"{f}.txt") for n, f in ck.CARTES.items()}
	g = ck.Grotte(plans, sans_dresseurs=True)
	depart = ("1F", *plans["1F"].positions["from_route_10_n"].cells[0])
	but = {("1F", x, y) for x, y in plans["1F"].cells_of(ck.SORTIE)}
	dist, parent = g.bfs([depart])
	fin = min((b for b in but if b in dist), key=lambda b: dist[b])
	trajet = ck.chemin(parent, fin)
	obligatoires = set()
	for nom, plan in plans.items():
		for zone in ck.zones_gravats(plan):
			g2 = ck.Grotte(plans, bloquees={nom: zone}, sans_dresseurs=True)
			if not any(b in g2.bfs([depart])[0] for b in but):
				obligatoires |= {(nom, x, y) for x, y in zone}
	imgs = {}
	for nom, plan in plans.items():
		imgs[nom] = dessiner(nom, plan, trajet, obligatoires)
		chemin = sortie / f"grotte_sombre_{nom.lower()}.png"
		imgs[nom].save(chemin)
		print(chemin)
	w = imgs["1F"].width + imgs["B1F"].width + 12
	h = max(i.height for i in imgs.values())
	ens = Image.new("RGB", (w, h), (8, 8, 10))
	ens.paste(imgs["1F"], (0, 0))
	ens.paste(imgs["B1F"], (imgs["1F"].width + 12, 0))
	chemin = sortie / "grotte_sombre_ensemble.png"
	ens.save(chemin)
	print(chemin)
	return 0


if __name__ == "__main__":
	sys.exit(main())
