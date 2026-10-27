#!/usr/bin/env python3
"""Art PROVISOIRE de l'Arène de Jadielle (jalon 28, T6) : enveloppe d'intérieur cuite d'après la
grille `tools/plans/jadielle_arene.txt` (murs, sol, dalles fléchées, cases d'arrêt, ouverture de
sortie). Le lot d'art du J28 (jalon-28.md §2.6) remplacera l'image (mêmes dimensions), pas la carte.

  python3 tools/art/placeholders_j28.py

Écrit `assets/world/interiors/placeholder/ph_viridian_gym.png` (24 × 22 cases de 96 px).
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLAN = RACINE / "tools/plans/jadielle_arene.txt"
SORTIE = RACINE / "assets/world/interiors/placeholder/ph_viridian_gym.png"
CASE = 96
SOL_A, SOL_B = (206, 190, 160), (196, 180, 150)        # terre battue claire
MUR, MUR_FACE = (92, 74, 60), (140, 112, 88)
FLECHE, DALLE = (226, 92, 52), (238, 226, 200)
ARRET = (70, 130, 190)
TAPIS = (150, 40, 40)
DIRS = {">": (1, 0), "<": (-1, 0), "^": (0, -1), "v": (0, 1)}


def main() -> int:
	plan = lire(PLAN)
	w, h = plan.width, plan.height
	image = Image.new("RGB", (w * CASE, h * CASE), MUR)
	g = ImageDraw.Draw(image)

	def at(x, y):
		return plan.at(x, y) if 0 <= x < w and 0 <= y < h else "K"

	for y in range(h):
		for x in range(w):
			c, px, py = at(x, y), x * CASE, y * CASE
			if c == "K":
				if at(x, y + 1) != "K":
					g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=MUR_FACE)
					g.rectangle((px, py + CASE - 12, px + CASE - 1, py + CASE - 1), fill=MUR)
				continue
			g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=SOL_A if (x + y) % 2 else SOL_B)
			cx, cy = px + CASE // 2, py + CASE // 2
			if c in DIRS:
				g.rectangle((px + 6, py + 6, px + CASE - 7, py + CASE - 7), fill=DALLE,
					outline=FLECHE, width=4)
				dx, dy = DIRS[c]
				r = 30
				tip = (cx + dx * r, cy + dy * r)
				base = [(cx - dx * r // 2 + dy * r, cy - dy * r // 2 + dx * r),
					(cx - dx * r // 2 - dy * r, cy - dy * r // 2 - dx * r)]
				g.polygon([tip] + base, fill=FLECHE)
			elif c == "o":
				g.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), outline=ARRET, width=6)
				g.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=ARRET)
			elif c == "X":
				g.rectangle((px + 4, py + 10, px + CASE - 5, py + CASE - 10), fill=TAPIS)
	SORTIE.parent.mkdir(parents=True, exist_ok=True)
	image.save(SORTIE)
	print(f"{SORTIE.relative_to(RACINE)} : {image.size}")
	return 0


if __name__ == "__main__":
	sys.exit(main())
