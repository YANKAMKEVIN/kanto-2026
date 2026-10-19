#!/usr/bin/env python3
"""Plan en aplats de relecture des grilles du jalon 18 (lavanville, tour_pokemon_rdc).

Aperçu fonctionnel (une couleur par caractère de légende, PNJ, portes, raccords, examens), PAS la
vue générale peinte. Sortie : build/plans_j18/<carte>.png (non versionné). 1 case = 24 px
(Lavanville) ou 40 px (intérieurs).
Usage : python3 tools/art/plan_apercu_j18.py [grille.txt ...]   (défaut : les deux grilles)
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
COULEURS = {
	"T": (28, 70, 40), ".": (112, 150, 92), "p": (186, 176, 190), "x": (52, 100, 56),
	"y": (206, 190, 222), "n": (130, 90, 60), "G": (36, 96, 48), "D": (240, 200, 60),
	"C": (210, 90, 90), "O": (80, 130, 210), "F": (230, 160, 100), "m": (190, 160, 130),
	"N": (170, 140, 110), "U": (84, 70, 120),
	# intérieurs
	"K": (60, 56, 70), "X": (240, 200, 60), "g": (130, 130, 140), "W": (150, 110, 70),
	"b": (250, 190, 90), "S": (230, 120, 210),
}
PNJ = (250, 250, 250)


def dessiner(chemin: Path, sortie: Path, case: int) -> Path:
	plan = lire(chemin)
	img = Image.new("RGB", (plan.width * case, plan.height * case), (0, 0, 0))
	d = ImageDraw.Draw(img)
	for y, ligne in enumerate(plan.rows):
		for x, c in enumerate(ligne):
			d.rectangle([x * case, y * case, (x + 1) * case - 1, (y + 1) * case - 1],
				fill=COULEURS.get(c, (255, 0, 255)))
	for p in plan.positions.values():
		for x, y in p.cells:
			box = [x * case + 3, y * case + 3, (x + 1) * case - 4, (y + 1) * case - 4]
			if p.kind == "pnj":
				d.ellipse(box, fill=PNJ, outline=(0, 0, 0), width=2)
				d.text((x * case + case // 3, y * case + case // 4), p.attrs.get("role", "?")[-1],
					fill=(0, 0, 0))
			elif p.kind in ("panneau", "examen"):
				d.rectangle(box, outline=(255, 255, 0), width=2)
			elif p.kind == "warp" and p.attrs.get("coming_soon"):
				d.rectangle(box, outline=(255, 90, 90), width=2)
			elif p.kind == "warp":
				d.rectangle(box, outline=(0, 255, 255), width=2)
			elif p.kind == "declencheur":
				d.line([box[0], box[1], box[2], box[3]], fill=(255, 255, 255), width=1)
			elif p.kind == "lamp":
				d.ellipse([x * case - case, y * case - case, (x + 2) * case, (y + 2) * case],
					outline=(255, 220, 120), width=1)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def main() -> int:
	args = [Path(a) for a in sys.argv[1:]] or [RACINE / "tools" / "plans" / f"{n}.txt"
		for n in ("lavanville", "tour_pokemon_rdc")]
	for g in args:
		taille = 24 if g.stem == "lavanville" else 40
		print(dessiner(g, RACINE / "build" / "plans_j18" / f"{g.stem}.png", taille))
	return 0


if __name__ == "__main__":
	sys.exit(main())
