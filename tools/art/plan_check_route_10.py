#!/usr/bin/env python3
"""Vérifie la grille de la Route 10 (jalon 18, dossier 21 §4, §13.1) par recherche de chemin.

Grille : `tools/plans/route_10.txt` (une seule carte, 34 × 76). Lecture par `plan_grille.lire` ;
déplacements de `plan_check.Monde`, avec des **portes terminales** (porte du Centre `D`, entrées de
la grotte `Q` : on y entre, on ne les traverse pas). Les positions `bloque` bloquent leurs cases.

Critères :
  - taille 34 × 76 ; raccord ouest = rangées du raccord est de la Route 9 (`route_9.txt`) ; raccord
    sud (21..23, 75) (21..23, 75) ; carte fermée ailleurs ;
  - DEUX SECTEURS non reliés à pied : nord (depuis le raccord ouest) et sud (depuis la sortie sud
    de la grotte, qui mène au raccord sud) ; aucune case praticable orpheline ; l'eau jamais
    praticable ; la falaise centrale ferme la bande ;
  - secteur nord : Centre 8 × 7 (porte sur les 4e et 5e colonnes du bas) avant la grotte, entrée
    nord dans la paroi (K au-dessus et des deux côtés), spawn de sortie devant elle ; panneau,
    randonneur, poche d'herbes évitable ;
  - centrale : décor bloqué, sans porte, séparé de tout sol praticable par l'eau ;
  - secteur sud : entrée sud dans la paroi, R10-1 et R10-2 facultatifs (évitables, un à un et
    ensemble, sans détour), 0 case d'herbe obligatoire, 1 objet atteignable hors des lignes de vue ;
  - l'approche d'un Dresseur ne ferme aucun passage.
Imprime les longueurs de chemin (pas) et une estimation de la durée de traversée.

Usage : python3 tools/art/plan_check_route_10.py [grille]   code 1 si un critère échoue
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, ligne_brute, ligne_de_vue,  # noqa: E402
	nommer_zones, zones_herbes)
from plan_grille import HERBES, PORTE, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
Case = tuple[int, int]

TAILLE = (34, 76)
SOL = set(".=o")
CENTRE_EMPRISE = (8, 7, (3, 4))
RACCORD_SUD = [(21, 75), (22, 75), (23, 75)]
DRESSEURS = {"R10-1": 4, "R10-2": 5}
S_PAR_PAS = 0.72
S_SAUVAGE = 50
TAUX = 25 / 256


class Route(Monde):
	"""`plan_check.Monde` avec portes terminales (`D`, `Q`) et `sans`."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset()) -> None:
		super().__init__(plan, bloquees)
		self.portes = set(plan.cells_of(PORTE)) | set(plan.cells_of("Q"))

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Route":
		return Route(self.plan, self.bloquees | set(cases))


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _acces(monde: Route, p) -> list[Case]:
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if monde.libre(_decale(c, d)) and _decale(c, d) not in monde.portes]


def verifier_route_10(chemin: Path) -> bool:
	plan = lire(chemin)
	ok = True

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	monde = Route(plan)
	pos = plan.positions
	nom = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {nom} : {plan.width} × {plan.height}")
	critere((plan.width, plan.height) == TAILLE, f"taille {plan.width} × {plan.height} "
		f"(attendu {TAILLE[0]} × {TAILLE[1]})")

	# 1. Raccords.
	r9 = lire(chemin.with_name("route_9.txt"))
	rangees = sorted(y for x, y in r9.positions["warp_est"].cells if x == r9.width - 1)
	entree = [(0, y) for y in range(plan.height) if monde.libre((0, y))]
	w_o = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	s_o = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	critere(entree == w_o == s_o == [(0, y) for y in rangees],
		f"raccord ouest : rangées {[y for _, y in entree]}, warps, spawns = est de la Route 9 "
		f"(79, {rangees[0]}..{rangees[-1]})")
	sud = [(x, plan.height - 1) for x in range(plan.width) if monde.libre((x, plan.height - 1))]
	w_s = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == plan.height - 1)
	s_s = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[1] == plan.height - 1)
	critere(sud == w_s == s_s == RACCORD_SUD,
		f"raccord sud (21..23, 75) : colonnes {[x for x, _ in sud]} (attendu 21..23), "
		"warps et spawns identiques")
	lav = lire(chemin.with_name("lavanville.txt"))
	haut_lav = sorted(x for p in lav.of_kind("warp") for x, y in p.cells if y == 0)
	critere([x for x, _ in sud] == haut_lav, "mêmes colonnes que le raccord nord de "
		f"lavanville.txt : Route 10 {[x for x, _ in sud]}, Lavanville {haut_lav}")
	bords = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and monde.libre((x, y))]
	critere(sorted(bords) == sorted(entree + sud), "carte fermée : seuls les raccords ouest et sud "
		"touchent le bord")

	# 2. Deux secteurs non reliés.
	nord = monde.distances(entree)
	sortie_sud = pos["from_dark_cave_s"].cells
	sudd = monde.distances(sortie_sud)
	critere(not (set(nord) & set(sudd)), "les deux secteurs ne sont PAS reliés à pied : aucune "
		f"case commune ({len(nord)} cases au nord, {len(sudd)} au sud)")
	critere(all(c in sudd for c in sud) and not any(c in nord for c in sud),
		"le raccord sud n'est atteint que depuis le secteur sud")
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in monde.bloquees
		and (x, y) not in nord and (x, y) not in sudd]
	critere(not orphelines, f"aucune case praticable orpheline {orphelines[:4]}")
	eau = plan.cells_of("w")
	critere("w" not in plan.praticables and not any(monde.libre(c) for c in eau)
		and all(plan.at(x, y) == "K" for x in range(0, 24) for y in range(29, 47)),
		f"eau jamais praticable ({len(eau)} cases) ; falaise pleine (x 0..23, y 29..46) entre "
		"les deux secteurs")
	ys_n = [y for _, y in nord]
	ys_s = [y for _, y in sudd]
	critere(max(ys_n) < 29 and min(ys_s) >= 47,
		f"secteur nord y {min(ys_n)}..{max(ys_n)}, secteur sud y {min(ys_s)}..{max(ys_s)}")

	# 3. Secteur nord : Centre, grotte, panneau, randonneur.
	centre = set(plan.cells_of("C")) | set(plan.cells_of(PORTE))
	portes = plan.cells_of(PORTE)
	xs = [x for x, _ in centre]
	ys = [y for _, y in centre]
	larg, haut, cols = CENTRE_EMPRISE
	taille_c = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
	attendues = sorted((min(xs) + i, max(ys)) for i in cols)
	critere(taille_c == (larg, haut) and len(centre) == larg * haut and sorted(portes) == attendues,
		f"Centre ({min(xs)}..{max(xs)}, {min(ys)}..{max(ys)}) : {taille_c[0]} × {taille_c[1]} "
		f"(attendu {larg} × {haut}), porte {sorted(portes)} sur la façade sud")
	warps = {c for p in plan.of_kind("warp") for c in p.cells}
	qs = plan.cells_of("Q")
	qn = [c for c in qs if c[1] < 29]
	qsud = [c for c in qs if c[1] >= 29]

	def paroi(cases: list[Case]) -> bool:
		y = cases[0][1]
		return all(plan.at(x, y - 1) == "K" for x, _ in cases) and plan.at(
			min(x for x, _ in cases) - 1, y) == "K" and plan.at(max(x for x, _ in cases) + 1, y) == "K"
	critere(len(qn) == 2 and len(qsud) == 2 and paroi(qn) and paroi(qsud)
		and set(portes) | set(qs) <= warps,
		f"entrées de la grotte nord {qn} et sud {qsud} : ouvertures dans la paroi (K au-dessus et "
		"des deux côtés), avec warps ; porte du Centre avec warp")
	d_centre = min(nord.get(c, INF) for c in portes)
	d_grotte = min(nord.get(c, INF) for c in qn)
	critere(d_centre < d_grotte < INF,
		f"raccord ouest → porte du Centre : {d_centre} pas ; → entrée nord de la grotte : "
		f"{d_grotte} pas ; le Centre avant la grotte")
	sp_n = pos["from_dark_cave_n"].cells
	critere(all((x, y) in [(qx, qy + 1) for qx, qy in qn] for x, y in sp_n) and all(
		c in nord for c in sp_n), f"spawn de sortie nord {sp_n} juste devant l'entrée, atteignable")
	panneau, hik = pos["panneau_grotte"], pos["randonneur"]
	devant = [_decale(c, (0, 1)) for c in panneau.cells]
	critere(all(plan.at(*c) in SOL - {"="} for c in panneau.cells) and all(d in nord for d in devant)
		and abs(panneau.cells[0][0] - qn[0][0]) <= 4 and abs(hik.cells[0][0] - qn[0][0]) <= 4
		and hik.attrs.get("facing") and plan.at(*hik.cells[0]) in SOL - {"="}
		and any(a in nord for a in _acces(monde, hik)),
		f"panneau {panneau.cells[0]} (lu depuis {devant[0]}) et randonneur {hik.cells[0]} devant la "
		"grotte")

	# 4. Centrale : décor, séparée du sol par l'eau.
	e = plan.cells_of("E")
	voisins_e = {_decale(c, d) for c in e for d in DIRECTIONS
		if 0 <= _decale(c, d)[0] < plan.width and 0 <= _decale(c, d)[1] < plan.height}
	critere(bool(e) and not any(monde.libre(c) for c in e) and not any(c in warps for c in e)
		and not any(monde.libre(c) and (c in nord or c in sudd) for c in voisins_e)
		and all(plan.at(24 + i, y) == "w" for i in range(5) for y in range(3, 10)),
		f"centrale ({len(e)} cases) : décor bloqué, sans porte ni warp, au-delà de 5 cases d'eau, "
		"aucune case praticable à côté")

	# 5. Herbes.
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ("H1", "H2"))
	if len(zones) != 2 or sorted(nommees) != ["H1", "H2"]:
		critere(False, f"zones H1, H2 attendues : {len(zones)} trouvées")
		return False
	toutes = set().union(*zones)
	h1, h2 = nommees["H1"], nommees["H2"]
	g_nord = min(monde.herbes_min(entree, lambda c: c in toutes).get(c, INF) for c in qn)
	g_sud = min(monde.herbes_min(sortie_sud, lambda c: c in toutes).get(c, INF) for c in sud)
	critere(g_nord == 0 and g_sud == 0 and min(c[1] for c in h1) < 29 <= min(c[1] for c in h2),
		f"H1 au nord, H2 au sud, toutes deux évitables : {g_nord} et {g_sud} case(s) d'herbe "
		"obligatoire (0 rencontre forcée, I-16)")

	# 6. Dresseurs facultatifs.
	dresseurs = _role(plan, "dresseur")
	critere(sorted(dresseurs) == sorted(DRESSEURS), f"2 Dresseurs R10-1, R10-2 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(DRESSEURS):
		return False
	aller = min(sudd.get(c, INF) for c in sud)
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vue = ligne_de_vue(monde, p)
		vues[role] = vue
		vision = int(p.attrs.get("sight", "0"))
		c0 = p.cells[0]
		critere(vision == DRESSEURS[role] and len(vue) == vision and plan.at(*c0) in SOL
			and c0 in {(x, y) for y in range(29, plan.height) for x in range(plan.width)},
			f"{role} {p.ident} {c0} tourné {p.attrs.get('facing')} : vision {len(vue)}/{vision} "
			f"cases dégagées ({''.join(plan.at(*c) for c in vue)}), secteur sud")
		d = min(monde.sans(vue).distances(sortie_sud).get(c, INF) for c in sud)
		sur_route = any(plan.at(*c) == "=" for c in vue)
		critere(d == aller,
			f"{role} facultatif : sa ligne touche le sentier : {sur_route} ; le raccord sud reste "
			f"à {d} pas sans la croiser (chemin direct {aller})")
	tous = set().union(*vues.values())
	d_tous = min(monde.sans(tous).distances(sortie_sud).get(c, INF) for c in sud)
	critere(d_tous == aller, f"les deux évitables ensemble : raccord sud en {d_tous} pas")

	# 7. Objet.
	objets = _role(plan, "objet_visible")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((sudd.get(a, INF) for a in _acces(monde, p)), default=INF)
		critere(atteint < INF and plan.at(*c) in SOL and c not in lignes and p.attrs.get("item")
			== "super_potion", f"{role} {p.ident} {c} ({p.attrs.get('item')}) au sud : atteint en "
			f"{atteint} pas, hors des lignes de vue")
	critere(sorted(objets) == ["O1"] and not any(
		min((nord.get(a, INF) for a in _acces(monde, p)), default=INF) < INF
		for p in objets.values()), "1 objet, au sud ; aucun au nord")

	# 8. Approche d'un Dresseur.
	cibles = [list(sud), list(sortie_sud)] + [_acces(monde, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in sudd:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Route(plan)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3] if fermes else ''}")

	# 9. Repère de la Tour, placements.
	tour = pos["tour_lointaine"]
	critere(all(not monde.libre(c) for c in tour.cells) and all(c[1] > 60 for c in tour.cells)
		and all(plan.at(*c) == "T" for c in tour.cells),
		f"silhouette de la Tour {tour.cells[0]}..{tour.cells[-1]} : au sud, au-dessus de la forêt, "
		"hors d'atteinte")
	fautes: list[str] = []
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if plan.at(*c) not in SOL or (c not in nord and c not in sudd):
				fautes.append(f"{p.ident} {c}")
	for p in plan.of_kind("herbes"):
		if p.cells[0] not in nord and p.cells[0] not in sudd:
			fautes.append(p.ident)
	critere(not fautes, f"points d'apparition et herbes bien placés {fautes}")

	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes")
	print(f"  secteur nord : raccord ouest → Centre {d_centre} pas, → grotte {d_grotte} pas ; "
		f"secteur sud : sortie de la grotte → Lavanville {aller} pas (≈ {aller * S_PAR_PAS:.0f} s "
		"à la marche)")
	return ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/route_10.txt"
	bon = verifier_route_10(chemin.resolve())
	print("Plan conforme." if bon else "Plan NON conforme.")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
