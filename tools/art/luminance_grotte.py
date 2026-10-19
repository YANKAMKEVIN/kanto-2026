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

Passe « lumière rare » (2026-10-14) : la grotte est volontairement sombre loin des sources ; les
seuils portent désormais sur le sol **près du joueur** (cases praticables à ≤ 2,5 cases de lui)
et **près des repères** (sol calme seul, les gravats sont plus sombres par nature ; ≤ 2 cases d'une lampe ou d'un projecteur `L`, d'un puits `j`, d'un éclat
`*`, d'une échelle `U` / `V`, de l'entrée `E`) : chacun ≥ 0,22 et ≥ 2,0 × la paroi. La moyenne de
toute la vue (« sol ») reste donnée pour information. **Écart centre / pourtour** : sol calme
loin des parois (aucune masse à ≤ 2 cases) ou près d'une source, contre sol au pied des parois
(masse voisine, 8 voisins, loin des sources) : rapport des moyennes ≥ 1,25 quand les deux
existent dans la vue. Contraste du héros ≥ 3,0 (vues `heros_*`).

Contraste du héros (facultatif) : si `<nom>_vide.png` existe (même vue sans joueur,
`--noplayer --aim=…`), les pixels qui changent dans la boîte du sprite sont le héros ; rapport de
contraste WCAG moyen, pixel par pixel, entre le héros et le sol qu'il recouvre (à comparer à la
Forêt de Jade, `heros_foret`).

    python3 tools/art/luminance_grotte.py build/captures/mt_moon [--json resultat.json]
    python3 tools/art/luminance_grotte.py --halo build/captures/flash [--json resultat.json]
Code de sortie 1 si un seuil n'est pas tenu.

Option `--halo` (J17 T25, voile d'obscurité) : mesure les captures de `tools/capture_flash.sh`
(voile posé sur une grotte de `PLANS` ; la carte de QA `qa_flash` est retirée au J17 T28 ; nom
`<sans_voile|dark|lit>_<lieu>.png` + `_vide`) : contraste du héros ≥ 3,0 dans le halo (héros
contre le sol qu'il recouvre) et **sol hors du halo ≥ 0,10** (cases praticables entièrement à
l'écran, plus loin du joueur que la fin du fondu : 4 cases sans Flash, 9 avec ;
non mesuré sans voile ni si aucune case n'est assez loin).
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
	"digletts_cave": "tools/plans/digletts_cave.txt",
}
SOL = set(".gjUVE")
PAROI = set("#*")
SEUIL_SOL = 0.22
SEUIL_RAPPORT = 2.0
SEUIL_HEROS = 3.0
SEUIL_ECART = 1.25
# Cartes sans voile de pénombre (Cave Taupiqueur, J17 T15 : lumière naturelle, aucun voile) : l'écart
# centre / pourtour est donné pour information, il n'y a pas de pénombre à mesurer.
SANS_VOILE = {"digletts_cave"}
SEUIL_HORS_HALO = 0.10
FONDU = {"dark": 4.0, "lit": 9.0}  # fin du fondu du halo (cases), data/world/darkness.json
REPERES = set("LjUVE*")
RAYON_JOUEUR = 2.5
RAYON_REPERE = 2.0
RAYON_SOURCE = 2.0
SOURCES = set("Lj*E")
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
	par_case = {}
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
				par_case[(x, y)] = valeur
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
	reperes = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.rows[y][x] in REPERES]
	sources = [c for c in reperes if plan.rows[c[1]][c[0]] in SOURCES]

	def pres(centres, rayon):
		# Sol calme seulement : les gravats (texture plus sombre par nature, déjà 0,16–0,19
		# avant la passe) sont donnés à part (« gravats »).
		return [v for (x, y), v in par_case.items() if plan.rows[y][x] != "g"
			and any((x - cx) ** 2 + (y - cy) ** 2 <= rayon * rayon for cx, cy in centres)]

	proche = pres([joueur], RAYON_JOUEUR) if joueur else []
	pres_reperes = pres(reperes, RAYON_REPERE)
	centre, pourtour = [], []
	for (x, y), v in par_case.items():
		if plan.rows[y][x] == "g":
			continue
		eclaire = any(abs(x - cx) <= RAYON_SOURCE and abs(y - cy) <= RAYON_SOURCE
			for cx, cy in sources)
		pied = any(_masse(plan, x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
		loin = not any(_masse(plan, x + dx, y + dy) for dx in range(-2, 3) for dy in range(-2, 3))
		if loin or eclaire:
			centre.append(v)
		elif pied:
			pourtour.append(v)
	resultat["sol_joueur"] = moy(proche)
	resultat["sol_reperes"] = moy(pres_reperes)
	resultat["centre"] = moy(centre)
	resultat["pourtour"] = moy(pourtour)
	resultat["ecart"] = round(resultat["centre"] / max(resultat["pourtour"], 1e-6), 2) \
		if centre and pourtour else None
	proches = [v for v in (resultat["sol_joueur"], resultat["sol_reperes"]) if v is not None]
	plancher = min(proches) if proches else resultat["sol"]
	resultat["rapport_proche"] = round(plancher / max(resultat["paroi"], 1e-6), 2)
	resultat["ok"] = plancher >= SEUIL_SOL and resultat["rapport_proche"] >= SEUIL_RAPPORT \
		and (fiche["map"] in SANS_VOILE or resultat["ecart"] is None
			or resultat["ecart"] >= SEUIL_ECART)
	vide = png.with_name(png.stem + "_vide.png")
	if joueur and vide.exists():
		resultat["contraste_heros"] = contraste_heros(image, Image.open(vide).convert("RGB"),
			joueur, tuile, ox, oy)
		if resultat["contraste_heros"] is not None:
			resultat["ok"] = resultat["ok"] and resultat["contraste_heros"] >= SEUIL_HEROS
	return resultat


def _masse(plan, x: int, y: int) -> bool:
	if not (0 <= x < plan.width and 0 <= y < plan.height):
		return True
	return plan.rows[y][x] in PAROI


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


def mesurer_halo(png: Path, fiche: dict) -> dict | None:
	if fiche["map"] not in PLANS or not fiche.get("player"):
		return None
	vide = png.with_name(png.stem + "_vide.png")
	if not vide.exists():
		return None
	plan = plan_grille.lire(RACINE / PLANS[fiche["map"]])
	image = Image.open(png).convert("RGB")
	tuile = int(fiche["tile"])
	cx, cy = fiche["center"]
	ox, oy = cx - image.width / 2.0, cy - image.height / 2.0
	joueur = tuple(fiche["player"])
	etat = png.stem.split("_")[0]
	resultat = {"vue": png.stem, "etat": etat, "hors_halo": None, "cases_hors_halo": 0,
		"contraste_heros": contraste_heros(image, Image.open(vide).convert("RGB"), joueur,
			tuile, ox, oy)}
	if etat in FONDU:
		valeurs = []
		for y in range(plan.height):
			for x in range(plan.width):
				if plan.rows[y][x] not in SOL:
					continue
				x0, y0 = round(x * tuile - ox), round(y * tuile - oy)
				if x0 < 0 or y0 < 0 or x0 + tuile > image.width or y0 + tuile > image.height:
					continue
				if ((x - joueur[0]) ** 2 + (y - joueur[1]) ** 2) ** 0.5 <= FONDU[etat] + 1.0:
					continue
				if plan.rows[y][x] == "g":
					continue
				valeurs.append(moyenne_case(image, (x0, y0, x0 + tuile, y0 + tuile)))
		if valeurs:
			resultat["hors_halo"] = round(sum(valeurs) / len(valeurs), 4)
			resultat["cases_hors_halo"] = len(valeurs)
	ok = resultat["contraste_heros"] is not None and resultat["contraste_heros"] >= SEUIL_HEROS
	if resultat["hors_halo"] is not None:
		ok = ok and resultat["hors_halo"] >= SEUIL_HORS_HALO
	# Sans voile : vue de référence (aucun halo), donnée pour information.
	resultat["ok"] = ok or etat not in FONDU
	return resultat


def main_halo(args) -> int:
	resultats = []
	for fiche_path in sorted(args.dossier.glob("*.json")):
		png = fiche_path.with_suffix(".png")
		if not png.exists() or fiche_path.stem.endswith("_vide"):
			continue
		mesure = mesurer_halo(png, json.loads(fiche_path.read_text()))
		if mesure:
			resultats.append(mesure)
	print(f"{'vue':20} {'héros':>6} {'hors halo':>9} {'cases':>5}")
	for r in resultats:
		h = r["contraste_heros"]
		o = r["hors_halo"]
		print(f"{r['vue']:20} {h if h is not None else '—':>6} "
			f"{f'{o:9.3f}' if o is not None else '        —'} {r['cases_hors_halo']:5d} "
			f"{'OK' if r['ok'] else 'ÉCHEC'}")
	print(f"seuils : héros ≥ {SEUIL_HEROS} (dans le halo), sol hors du halo ≥ {SEUIL_HORS_HALO}")
	if args.json:
		args.json.write_text(json.dumps(resultats, indent="\t", ensure_ascii=False))
	return 1 if not resultats or any(not r["ok"] for r in resultats) else 0


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
	parser.add_argument("dossier", type=Path)
	parser.add_argument("--json", type=Path)
	parser.add_argument("--halo", action="store_true", help="captures du voile (tools/capture_flash.sh)")
	args = parser.parse_args()
	if args.halo:
		return main_halo(args)
	resultats = []
	for fiche_path in sorted(args.dossier.glob("*.json")):
		png = fiche_path.with_suffix(".png")
		if not png.exists() or fiche_path.stem.endswith("_vide"):
			continue
		mesure = mesurer(png, json.loads(fiche_path.read_text()))
		if mesure:
			resultats.append(mesure)
	echec = False
	print(f"{'vue':16} {'sol':>6} {'joueur':>6} {'repère':>6} {'centre':>6} {'pourt.':>6} "
		f"{'écart':>6} {'paroi':>6} {'rapp.':>6} {'héros':>6}")
	for r in resultats:
		heros = r.get("contraste_heros")
		if r.get("comparaison"):
			print(f"{r['vue']:16} (comparaison, {r['carte']}) contraste du héros : {heros}")
			continue
		echec = echec or not r["ok"]
		def f(v, n=3):
			return f"{v:6.{n}f}" if v is not None else f"{'—':>6}"
		print(f"{r['vue']:16} {f(r['sol'])} {f(r['sol_joueur'])} {f(r['sol_reperes'])} "
			f"{f(r['centre'])} {f(r['pourtour'])} {f(r['ecart'], 2)} {f(r['paroi'])} "
			f"{f(r['rapport_proche'], 2)} {heros if heros else '—':>6} "
			f"{'OK' if r['ok'] else 'ÉCHEC'}")
	print(f"seuils : sol près du joueur et des repères ≥ {SEUIL_SOL}, ce sol / paroi ≥ "
		f"{SEUIL_RAPPORT}, centre / pourtour ≥ {SEUIL_ECART}, héros ≥ {SEUIL_HEROS}")
	if args.json:
		args.json.write_text(json.dumps(resultats, indent="\t", ensure_ascii=False))
	return 1 if echec or not resultats else 0


if __name__ == "__main__":
	sys.exit(main())
