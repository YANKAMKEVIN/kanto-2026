#!/usr/bin/env python3
"""Plans en aplats de la Route 5 et du passage souterrain (jalon 15, dossier 18), pour la revue.

Grilles : `tools/plans/route_5.txt`, `tools/plans/underground_path.txt` (lecture `plan_grille`).
Palette et fonctions de `plan_aplats.py` (même légende que la Route 2 / la Route 3). Sorties dans
`build/plans/` (non versionné) : image nette + version annotée (`_annote.png` : légende, objets,
PNJ, case cachée, portes ; JAMAIS jointe à Codex pour la vue générale).

Usage : python3 tools/art/plan_aplats_j15.py [dossier_de_sortie]   (défaut : build/plans)
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]

TOIT_PENSION = (196, 112, 78)      # toit chaud
MUR_PENSION = (232, 214, 184)
JARDIN = (214, 150, 176)           # fleurs
CLOTURE = (150, 108, 70)
POSTE_C = pa.POSTE
SOUTERRAIN_TOIT = (120, 112, 104)
PAROI_S = (74, 68, 66)
SOL_S = (150, 140, 124)
TRACE_S = (172, 160, 138)
STELE = (118, 110, 100)
PIERRE_N = (206, 196, 150)
ESCALIER = (60, 56, 60)

FOND = {"T": pa.FORET, ".": pa.HERBE, "=": pa.CHEMIN, "h": pa.HAUTES_HERBES, "c": pa.HERBE,
	"j": JARDIN, "W": MUR_PENSION, "D": pa.PORTE, "P": POSTE_C, "G": pa.PORTE,
	"U": SOUTERRAIN_TOIT, "E": pa.PORTE}


def _case_px(plan: Plan, largeur: int, hauteur: int, marge: int = 0) -> int:
	return min((largeur - 2 * marge) // plan.width, (hauteur - 2 * marge) // plan.height)


def _bati(d, plan, car, toit, mur, coin, case, bas_mur: int = 1) -> None:
	cases = plan.cells_of(car) + plan.cells_of({"W": "D", "P": "G", "U": "E"}[car])
	xs, ys = [x for x, _ in cases], [y for _, y in cases]
	x0, y0 = coin(min(xs), min(ys))
	x1, y1 = coin(max(xs) + 1, max(ys) + 1)
	d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=mur, outline=(60, 50, 40), width=2)
	d.rectangle([x0, y0, x1 - 1, y1 - bas_mur * case - 1], fill=toit, outline=(60, 50, 40), width=2)


def dessiner_route_5(plan: Plan, sortie: Path, annote: bool = False) -> Path:
	case = 18
	marge = 30 if annote else 0
	img = Image.new("RGB", (plan.width * case + 2 * marge + (260 if annote else 0),
		plan.height * case + 2 * marge), pa.FORET)
	d = ImageDraw.Draw(img)

	def coin(x: int, y: int) -> tuple[int, int]:
		return marge + x * case, marge + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return marge + (x + 0.5) * case, marge + (y + 0.5) * case

	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=FOND[c])
			if c == "T":
				pa._disque(d, x0 + case / 2, y0 + case / 2, case * 0.52, pa.ARBRE, pa.ARBRE_BORD)
			if c == "c":
				d.rectangle([x0, y0 + case * 0.4, x0 + case - 1, y0 + case * 0.6], fill=CLOTURE)
				d.rectangle([x0 + case * 0.4, y0, x0 + case * 0.6, y0 + case - 1], fill=CLOTURE)
	_bati(d, plan, "W", TOIT_PENSION, MUR_PENSION, coin, case, 2)
	_bati(d, plan, "P", pa.POSTE_TOIT, POSTE_C, coin, case)
	_bati(d, plan, "U", (96, 90, 84), SOUTERRAIN_TOIT, coin, case)
	for ch in "DGE":
		for x, y in plan.cells_of(ch):
			x0, y0 = coin(x, y)
			d.rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 1], fill=pa.PORTE,
				outline=(30, 20, 15), width=2)
	for p in plan.of_kind("panneau"):
		cx, cy = centre(*p.cells[0])
		d.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=pa.PANNEAU, outline=pa.PANNEAU_BORD, width=2)
	for p in plan.of_kind("objet_visible"):
		cx, cy = centre(*p.cells[0])
		pa._disque(d, cx, cy, case * 0.32, pa.BALL_ROUGE, pa.BALL_BORD)
	for p in plan.of_kind("pnj"):
		cx, cy = centre(*p.cells[0])
		pa._disque(d, cx, cy, case * 0.36, (70, 90, 200), (20, 20, 60))
	if annote:
		police = pa._fonte(13)
		gros = pa._fonte(17)

		def etiq(c, texte, couleur=(255, 255, 255), dx=10, dy=-8, f=police):
			cx, cy = centre(*c)
			d.text((cx + dx, cy + dy), texte, fill=couleur, font=f, stroke_width=2,
				stroke_fill=(0, 0, 0))
		for p in plan.of_kind("cache"):
			cx, cy = centre(*p.cells[0])
			d.rectangle([cx - 7, cy - 7, cx + 7, cy + 7], outline=(255, 60, 60), width=3)
			etiq(p.cells[0], f"caché : {p.attrs['item']} ({p.attrs['indice']})", (255, 140, 140))
		for p in plan.of_kind("objet_visible"):
			etiq(p.cells[0], p.attrs["item"])
		for p in plan.of_kind("pnj"):
			etiq(p.cells[0], f"{p.attrs['role']} {p.ident}")
		for ident, texte in (("herbes_h1", "H1"), ("herbes_h2", "H2")):
			etiq(plan.positions[ident].cells[0], texte, (255, 255, 120), -8, -8, gros)
		etiq((27, 24), "PENSION", (40, 20, 10), -26, -8, gros)
		etiq((34, 42), "POSTE (fermé)", (20, 20, 40), -36, -4)
		etiq((11, 54), "SOUTERRAIN", (255, 255, 255), -34, -4)
		etiq((34, 26), "jardin clos", (60, 20, 40), -30, -8)
		etiq((20, 0), "AZURIA", (255, 255, 255), -24, 4, gros)
		etiq((13, 34), "détour facultatif", (255, 255, 255), -10, -2)
		etiq((22, 17), "① arrivée y0-21  ② Pension y22-37  ③ carrefour y38-58", (255, 255, 255),
			8, 0)
		for y in range(0, plan.height, 10):
			d.text((2, marge + y * case), str(y), fill=(255, 255, 255), font=police)
		for x in range(0, plan.width, 10):
			d.text((marge + x * case, 6), str(x), fill=(255, 255, 255), font=police)
		leg = ["Légende", "vert foncé : forêt (bloquée)", "vert : herbe rase", "beige : chemin",
			"jaune-vert : hautes herbes", "rose : jardin clos", "brun : clôture",
			"bleu : PNJ", "rouge : objet visible", "orange : panneau", "carré rouge : caché",
			"", f"{plan.width} × {plan.height} cases", "1 case = 18 px"]
		for i, ligne in enumerate(leg):
			d.text((plan.width * case + 2 * marge + 10, 40 + i * 20), ligne, fill=(255, 255, 255),
				font=gros if i == 0 else police)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def dessiner_souterrain(plan: Plan, sortie: Path, annote: bool = False) -> Path:
	case = 28
	marge = 30 if annote else 0
	img = Image.new("RGB", (plan.width * case + 2 * marge + (240 if annote else 0),
		plan.height * case + 2 * marge), PAROI_S)
	d = ImageDraw.Draw(img)

	def coin(x: int, y: int) -> tuple[int, int]:
		return marge + x * case, marge + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return marge + (x + 0.5) * case, marge + (y + 0.5) * case

	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			couleur = {"#": PAROI_S, ".": SOL_S, "=": TRACE_S, "r": SOL_S, "n": SOL_S,
				"E": ESCALIER}[c]
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=couleur)
			if c == "E":
				for k in range(1, 4):
					d.line([x0, y0 + k * case // 4, x0 + case - 1, y0 + k * case // 4],
						fill=(110, 104, 110), width=2)
			if c == "r":
				d.rectangle([x0 + 5, y0 + 5, x0 + case - 6, y0 + case - 6], fill=STELE,
					outline=(40, 38, 36), width=2)
			if c == "n":
				d.rectangle([x0 + 3, y0 + 3, x0 + case - 4, y0 + case - 4], fill=PIERRE_N,
					outline=(40, 38, 36), width=2)
	for p in plan.of_kind("repere"):
		if p.attrs.get("role") == "lampe":
			for c in p.cells:
				pa._disque(d, *centre(*c), case * 0.22, (240, 200, 90), (90, 70, 20))
	for p in plan.of_kind("pnj"):
		pa._disque(d, *centre(*p.cells[0]), case * 0.34, (70, 90, 200), (20, 20, 60))
	if annote:
		police = pa._fonte(14)
		gros = pa._fonte(18)

		def etiq(c, texte, couleur=(255, 255, 255), dx=12, dy=-8, f=police):
			cx, cy = centre(*c)
			d.text((cx + dx, cy + dy), texte, fill=couleur, font=f, stroke_width=2,
				stroke_fill=(0, 0, 0))
		for p in plan.of_kind("cache"):
			cx, cy = centre(*p.cells[0])
			d.rectangle([cx - 13, cy - 13, cx + 13, cy + 13], outline=(255, 60, 60), width=3)
			etiq((p.cells[0][0] + 1, p.cells[0][1]), "Guérison (pierre descellée)", (255, 150, 150))
		for p in plan.of_kind("alcove"):
			c = (p.cells[0][0], p.cells[0][1] - 1)
			etiq(c, p.attrs["role"], (255, 255, 120), 4, -4, gros)
		etiq((3, 0), "↑ Route 5 (Azuria)", (255, 255, 255), 30, -4)
		etiq((19, 28), "↓ Route 6 (Carmin)", (255, 255, 255), -150, 20)
		etiq((3, 8), "S1", (160, 220, 255), 40, 0, gros)
		etiq((11, 12), "S2", (160, 220, 255), -6, 12, gros)
		etiq((19, 22), "S3", (160, 220, 255), -50, 0, gros)
		etiq((3, 12), "coude 1", (255, 200, 120), 28, 14)
		etiq((19, 13), "coude 2", (255, 200, 120), -76, 14)
		etiq((11, 14), "passant", (160, 160, 255), 14, 4)
		leg = ["Légende", "gris foncé : paroi", "gris-beige : sol", "clair : traces",
			"jaune : appliques", "bleu : passant", "carré rouge : caché", "",
			f"{plan.width} × {plan.height} cases", "trajet : 40 pas", "1 case = 28 px"]
		for i, ligne in enumerate(leg):
			d.text((plan.width * case + 2 * marge + 10, 40 + i * 22), ligne, fill=(255, 255, 255),
				font=gros if i == 0 else police)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	img.save(sortie)
	return sortie


def main() -> int:
	sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "build/plans"
	r5 = lire(RACINE / "tools/plans/route_5.txt")
	sou = lire(RACINE / "tools/plans/underground_path.txt")
	for chemin in (
		dessiner_route_5(r5, sortie / "PLAN_ROUTE5_v2.png"),
		dessiner_route_5(r5, sortie / "PLAN_ROUTE5_v2_annote.png", True),
		dessiner_souterrain(sou, sortie / "PLAN_SOUTERRAIN_v1.png"),
		dessiner_souterrain(sou, sortie / "PLAN_SOUTERRAIN_v1_annote.png", True),
	):
		print(chemin)
	return 0


if __name__ == "__main__":
	sys.exit(main())
