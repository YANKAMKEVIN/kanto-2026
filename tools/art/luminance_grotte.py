#!/usr/bin/env python3
"""Lisibilité de la grotte mesurée sur les captures (jalon 12 T9, docs/tech/jalon-12.md §2.4).

Lit les captures 1:1 de `tools/capture_mt_moon.sh` (`<nom>.png` + fiche de caméra `<nom>.json`)
et la grille de l'étage (`tools/plans/mont_selenite_*.txt`, elle fait foi), puis calcule pour
chaque vue la **luminance relative** moyenne (WCAG : sRGB linéarisé, 0,2126 R + 0,7152 V +
0,0722 B, de 0 à 1) :

- du **sol** : cases praticables entièrement à l'écran (`.` `g` `j` `U` `V` `E`), hors case du
  joueur et case au-dessus (son sprite) ; aussi le sol calme seul, les gravats seuls et la case de
  sol la plus sombre (10e centile des moyennes par case) ;
- des **parois** : cases de paroi (`#` `*`) voisines d'une galerie (faces, bords, lèvres), celles
  que l'œil doit séparer du sol ; la masse profonde est donnée pour information.

Seuils [D] : sol ≥ 0,22, sol / paroi ≥ 2,0. Les vues d'ensemble (zoom ≠ 1) sont ignorées.

Contraste du héros (facultatif) : si `<nom>_vide.png` existe (même vue sans joueur,
`--noplayer --aim=…`), les pixels qui changent dans la boîte du sprite sont le héros ; rapport de
contraste WCAG moyen, pixel par pixel, entre le héros et le sol qu'il recouvre (à comparer à la
Forêt de Jade, `heros_foret`).

    python3 tools/art/luminance_grotte.py build/captures/mt_moon [--json resultat.json]
Code de sortie 1 si un seuil n'est pas tenu.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import plan_grille  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = {
	"mt_moon_1f": "tools/plans/mont_selenite_1f.txt",
	"mt_moon_b1f": "tools/plans/mont_selenite_b1f.txt",
	"mt_moon_b2f": "tools/plans/mont_selenite_b2f.txt",
}
SOL = set(".gjUVE")
PAROI = set("#*")
SEUIL_SOL = 0.22
SEUIL_RAPPORT = 2.0
# Boîte du sprite du héros autour de sa case (pixels du monde) : 128 px de haut, pied au bas.
HEROS_LARGEUR = 96
HEROS_HAUTEUR = 136
HEROS_ECART = 40  # somme des écarts RVB au-delà de laquelle un pixel appartient au héros

_LIN = [((c / 255.0) / 12.92) if c <= 10 else (((c / 255.0) + 0.055) / 1.055) ** 2.4
	for c in range(256)]


def luminance(pixel: tuple[int, int, int]) -> float:
	r, g, b = pixel[:3]
	return 0.2126 * _LIN[r] + 0.7152 * _LIN[g] + 0.0722 * _LIN[b]


def moyenne_case(image: Image.Image, boite: tuple[int, int, int, int]) -> float:
	# Sous-échantillonnage 1 pixel sur 4 en x et y : assez pour une moyenne de case.
	x0, y0, x1, y1 = boite
	total = 0.0
	compte = 0
	for y in range(y0, y1, 4):
		for x in range(x0, x1, 4):
			total += luminance(image.getpixel((x, y)))
			compte += 1
	return total / max(compte, 1)


def voisin_galerie(plan, x: int, y: int) -> bool:
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		nx, ny = x + dx, y + dy
		if 0 <= nx < plan.width and 0 <= ny < plan.height and plan.rows[ny][nx] in SOL:
			return True
	return False


def mesurer(png: Path, fiche: dict) -> dict | None:
	if abs(float(fiche["zoom"]) - 1.0) > 1e-6:
		return None
	if fiche["map"] not in PLANS:
		# Carte de comparaison (Forêt de Jade) : contraste du héros seulement.
		vide = png.with_name(png.stem + "_vide.png")
		if not fiche.get("player") or not vide.exists():
			return None
		cx, cy = fiche["center"]
		image = Image.open(png).convert("RGB")
		return {"vue": png.stem, "carte": fiche["map"], "comparaison": True,
			"contraste_heros": contraste_heros(image, Image.open(vide).convert("RGB"),
				tuple(fiche["player"]), int(fiche["tile"]), cx - image.width / 2.0,
				cy - image.height / 2.0)}
	plan = plan_grille.lire(RACINE / PLANS[fiche["map"]])
	image = Image.open(png).convert("RGB")
	tuile = int(fiche["tile"])
	vue_l, vue_h = image.size
	cx, cy = fiche["center"]
	ox, oy = cx - vue_l / 2.0, cy - vue_h / 2.0
	joueur = tuple(fiche["player"]) if fiche.get("player") else None
	cache = set()
	if joueur:
		cache = {joueur, (joueur[0], joueur[1] - 1)}
	sol, calme, gravats, paroi, masse = [], [], [], [], []
	for y in range(plan.height):
		for x in range(plan.width):
			x0 = round(x * tuile - ox)
			y0 = round(y * tuile - oy)
			if x0 < 0 or y0 < 0 or x0 + tuile > vue_l or y0 + tuile > vue_h:
				continue
			marque = plan.rows[y][x]
			if (x, y) in cache:
				continue
			valeur = moyenne_case(image, (x0, y0, x0 + tuile, y0 + tuile))
			if marque in SOL:
				sol.append(valeur)
				(gravats if marque == "g" else calme).append(valeur)
			elif marque in PAROI:
				(paroi if voisin_galerie(plan, x, y) else masse).append(valeur)
	if not sol or not paroi:
		return None

	def moy(valeurs: list[float]) -> float | None:
		return round(sum(valeurs) / len(valeurs), 4) if valeurs else None

	sombre = sorted(sol)[max(0, len(sol) // 10 - 1)]
	resultat = {
		"vue": png.stem, "carte": fiche["map"], "cases_sol": len(sol),
		"sol": moy(sol), "sol_calme": moy(calme), "gravats": moy(gravats),
		"sol_10e_centile": round(sombre, 4), "paroi": moy(paroi), "masse": moy(masse),
	}
	resultat["rapport"] = round(resultat["sol"] / max(resultat["paroi"], 1e-6), 2)
	resultat["ok"] = resultat["sol"] >= SEUIL_SOL and resultat["rapport"] >= SEUIL_RAPPORT
	vide = png.with_name(png.stem + "_vide.png")
	if joueur and vide.exists():
		resultat["contraste_heros"] = contraste_heros(image, Image.open(vide).convert("RGB"),
			joueur, tuile, ox, oy)
	return resultat


def contraste_heros(image, vide, joueur, tuile, ox, oy) -> float | None:
	pied_x = joueur[0] * tuile + tuile / 2.0 - ox
	pied_y = (joueur[1] + 1) * tuile - oy
	x0 = int(pied_x - HEROS_LARGEUR / 2)
	y0 = int(pied_y - HEROS_HAUTEUR)
	heros, dessous = [], []
	for y in range(max(0, y0), min(image.height, int(pied_y))):
		for x in range(max(0, x0), min(image.width, x0 + HEROS_LARGEUR)):
			a = image.getpixel((x, y))
			b = vide.getpixel((x, y))
			if sum(abs(a[i] - b[i]) for i in range(3)) > HEROS_ECART:
				heros.append(luminance(a))
				dessous.append(luminance(b))
	if len(heros) < 200:
		return None
	# Moyenne, pixel par pixel, du rapport WCAG entre le héros et le sol qu'il cache : ses parts
	# sombres (cheveux, pantalon) comme claires (maillot, casquette) comptent.
	rapports = [(max(h, d) + 0.05) / (min(h, d) + 0.05) for h, d in zip(heros, dessous)]
	return round(sum(rapports) / len(rapports), 2)


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
	parser.add_argument("dossier", type=Path)
	parser.add_argument("--json", type=Path)
	args = parser.parse_args()
	resultats = []
	for fiche_path in sorted(args.dossier.glob("*.json")):
		png = fiche_path.with_suffix(".png")
		if not png.exists() or fiche_path.stem.endswith("_vide"):
			continue
		mesure = mesurer(png, json.loads(fiche_path.read_text()))
		if mesure:
			resultats.append(mesure)
	echec = False
	print(f"{'vue':16} {'sol':>6} {'calme':>6} {'grav.':>6} {'p10':>6} {'paroi':>6} "
		f"{'masse':>6} {'rapp.':>6} {'héros':>6}")
	for r in resultats:
		heros = r.get("contraste_heros")
		if r.get("comparaison"):
			print(f"{r['vue']:16} (comparaison, {r['carte']}) contraste du héros : {heros}")
			continue
		echec = echec or not r["ok"]
		print(f"{r['vue']:16} {r['sol']:6.3f} {r['sol_calme'] or 0:6.3f} {r['gravats'] or 0:6.3f} "
			f"{r['sol_10e_centile']:6.3f} {r['paroi']:6.3f} {r['masse'] or 0:6.3f} "
			f"{r['rapport']:6.2f} {heros if heros else '—':>6} {'OK' if r['ok'] else 'ÉCHEC'}")
	print(f"seuils : sol ≥ {SEUIL_SOL}, sol / paroi ≥ {SEUIL_RAPPORT}")
	if args.json:
		args.json.write_text(json.dumps(resultats, indent="\t", ensure_ascii=False))
	return 1 if echec or not resultats else 0


if __name__ == "__main__":
	sys.exit(main())
