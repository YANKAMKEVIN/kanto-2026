#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH7 (Chapitre Johto, dossier docs/design/dossier-joh-08-iles-tourbillon.md).

Grilles : `tools/plans/route_40.txt` (24 × 40), `route_41.txt` (60 × 48), `whirl_islands_1f.txt`
(30 × 24), `whirl_islands_b1f.txt` (36 × 28), `whirl_islands_b2f.txt` (24 × 24), plus la retouche
d'`oliville.txt` (marin de la plage, raccord sud). Mêmes règles que les contrôles du JOH2 au JOH6
(dont on reprend les fonctions) ; l'eau se traverse en Surf ; les courants poussent jusqu'à la
première case sans courant (règle de la grotte marine : simulation ci-dessous) ; les rochers de
Force bloquent tant qu'on ne les pousse pas.

Pour chaque carte : taille ; cases praticables connexes ; aucune ouverture sur le pourtour hors
des warps de bord ; objets, Dresseurs, panneaux et examens abordables. Raccords : Oliville sud ↔
Route 40 nord (10 cases), Route 40 sud ↔ Route 41 nord (3 cases), Route 41 entrée ↔ 1F, paires
d'échelles 1F ↔ B1F, B1F ↔ B2F (même case, arrivée voisine).
Route 40 : 3 Nageurs évitables. Route 41 : Noé inévitable, Léa et Gabin évitables. 1F : sans
pousser les rochers l'échelle est inaccessible, leurs couloirs de poussée sont libres ; Sbire T
évitable, Sbire U inévitable. B1F : le lac ouest ne s'atteint qu'en glissant, Suicune, l'Écaille
Draco et la crique s'atteignent, l'escalier du B2F seulement sans le courant violent, aucune case
atteinte n'est un cul-de-sac (on revient toujours à l'échelle), les scènes couvrent Suicune.
B2F : la scène de Lugia couvre le seul accès au bassin ; Super Bonbon derrière la cascade.

Usage : python3 tools/art/plan_check_joh7.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import DIRS, atteignables, bloquees, cases, communs, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh3 import colonnes, largeur  # noqa: E402
from plan_check_joh4 import evitable, inevitable  # noqa: E402
from plan_check_joh5 import couvre  # noqa: E402
from plan_check_joh6 import paire, sans  # noqa: E402

PLANS = base.PLANS
FLECHES = {">": (1, 0), "<": (-1, 0), "^": (0, -1), "v": (0, 1)}


def courant(plan, depart, inertes: set) -> tuple | None:
	"""Pousse depuis une case de courant jusqu'à la première case sans courant ; None si bloqué."""
	x, y = depart
	d = FLECHES[plan.at(x, y)]
	vus = set()
	while True:
		x, y = x + d[0], y + d[1]
		if not (0 <= x < plan.width and 0 <= y < plan.height) or plan.at(x, y) not in plan.praticables:
			return None
		g = plan.at(x, y)
		if g in FLECHES and (x, y) not in inertes:
			d = FLECHES[g]
			if (x, y, d) in vus:
				return None
			vus.add((x, y, d))
			continue
		return (x, y)


def nage(plan, depart, inertes: set | None = None) -> set:
	"""Cases atteintes en marchant, en nageant et en se laissant porter par les courants."""
	inertes = inertes or set()
	bloc = bloquees(plan)

	def libre(x, y):
		return 0 <= x < plan.width and 0 <= y < plan.height and plan.at(x, y) in plan.praticables and (x, y) not in bloc

	vus = set(depart)
	file = deque(depart)
	while file:
		x, y = file.popleft()
		for dx, dy in DIRS:
			n = (x + dx, y + dy)
			if not libre(*n):
				continue
			if plan.at(*n) in FLECHES and n not in inertes:
				n = courant(plan, n, inertes)
				if n is None or not libre(*n):
					continue
			if n not in vus:
				vus.add(n)
				file.append(n)
	return vus


def main() -> int:
	print("oliville (retouche)")
	oli = lire(PLANS / "oliville.txt")
	r = atteignables(oli, cases(oli, "from_route_39"))
	verifie(voisines_atteintes(oli, "marin_plage", r), "le marin de la plage (M-1) est abordable")

	print("route_40")
	r40 = lire(PLANS / "route_40.txt")
	communs(r40, (24, 40), "from_olivine", ["warp_nord", "warp_sud"])
	verifie(len(cases(oli, "warp_sud_mer")) == len(cases(r40, "warp_nord")) == 10, "raccord Oliville ↔ Route 40 : 10 cases de chaque côté")
	for d in ("yanis", "elodie", "marius"):
		evitable(r40, "from_olivine", "warp_sud", d)

	print("route_41")
	r41 = lire(PLANS / "route_41.txt")
	communs(r41, (60, 48), "from_route_40", ["warp_nord"])
	largeur(r40, "warp_sud", r41, "warp_nord")
	inevitable(r41, "from_route_40", "entree_iles", "noe")
	evitable(r41, "from_route_40", "entree_iles", "lea")
	evitable(r41, "from_route_40", "entree_iles", "gabin")
	verifie(r41.at(*cases(r41, "from_whirl")[0]) == "w" and cases(r41, "from_whirl")[0][0] == cases(r41, "entree_iles")[0][0] - 1,
		"retour des îles en Surf, juste devant l'entrée")

	print("whirl_islands_1f")
	w1 = lire(PLANS / "whirl_islands_1f.txt")
	rochers = w1.of_kind("rocher")
	for p in rochers:
		p.bloque = False
	r = communs(w1, (30, 24), "from_route_41", ["sortie"])
	verifie(all(c in r for c in cases(w1, "vers_b1f")), "échelle du B1F atteignable une fois les rochers poussés")
	for p in rochers:
		p.bloque = True
	r_bloque = atteignables(w1, cases(w1, "from_route_41"))
	verifie(not any(c in r_bloque for c in cases(w1, "vers_b1f")), "sans Force (rochers en place), l'échelle est inaccessible")
	bloc = bloquees(w1)
	for i, p in enumerate(rochers):
		for q in rochers:
			q.bloque = q is p or rochers.index(q) > i  # les rochers précédents sont déjà poussés
		r_bloque = atteignables(w1, cases(w1, "from_route_41"))
		lane = [tuple(int(v) for v in c.split(",")) for c in p.attrs["lane"].split(";")]
		(x, y) = p.cells[0]
		dx, dy = {"E": (1, 0), "O": (-1, 0), "S": (0, 1), "N": (0, -1)}[p.attrs["pousse"]]
		verifie(len(lane) >= 3 and all(lane[i] == (x + dx * (i + 1), y + dy * (i + 1)) for i in range(len(lane)))
			and all(w1.at(*c) in w1.praticables and c not in bloc for c in lane),
			f"{p.ident} : couloir de poussée libre sur {len(lane)} cases vers {p.attrs['pousse']}")
		verifie((x - dx, y - dy) in r_bloque, f"{p.ident} : le joueur arrive derrière le rocher pour le pousser")
	for p in rochers:
		p.bloque = False
	evitable(w1, "from_route_41", "vers_b1f", "sbire_t")
	inevitable(w1, "from_route_41", "vers_b1f", "sbire_u")

	print("whirl_islands_b1f")
	wb = lire(PLANS / "whirl_islands_b1f.txt")
	communs(wb, (36, 28), "from_1f", [])
	paire(w1, "vers_b1f", wb, "vers_1f")
	depart = cases(wb, "from_1f")
	r_pied = atteignables(wb, depart, chars=wb.praticables - set(FLECHES))
	verifie(not any(c in r_pied for c in cases(wb, "scene_suicune")), "le lac ouest ne s'atteint pas sans se laisser porter")
	r_cour = nage(wb, depart)
	verifie(all(c in r_cour for c in cases(wb, "scene_suicune")) and voisines_atteintes(wb, "suicune", r_cour),
		"Suicune s'atteint par les courants")
	verifie(voisines_atteintes(wb, "ecaille_draco", r_cour), "l'Écaille Draco s'atteint au bout de son courant")
	verifie(voisines_atteintes(wb, "lokhlass", r_cour), "la crique de Lokhlass s'atteint")
	verifie(not any(c in r_cour for c in cases(wb, "vers_b2f")), "l'escalier du B2F est fermé par le courant violent")
	calme = set(cases(wb, "courant_b2f"))
	r_calme = nage(wb, depart, inertes=calme)
	verifie(all(c in r_calme for c in cases(wb, "vers_b2f")), "l'escalier du B2F s'atteint une fois le courant apaisé")
	cul_de_sac = [c for c in r_calme if not any(u in nage(wb, [c], inertes=calme) for u in cases(wb, "vers_1f"))]
	verifie(not cul_de_sac, f"aucun cul-de-sac : on revient toujours à l'échelle ({cul_de_sac[:4]})")
	for p in wb.of_kind("courant"):
		verifie(all(wb.at(*c) in FLECHES for c in p.cells), f"{p.ident} sur des cases de courant")
	verifie({c for p in wb.of_kind("courant") for c in p.cells} == {c for f in FLECHES for c in wb.cells_of(f)},
		"chaque case de courant porte une position courant")
	for scene in ("scene_suicune", "scene_cenere"):
		rr = nage_sans(wb, depart, set(cases(wb, scene)), calme)
		verifie(not voisines_atteintes(wb, "suicune", rr), f"{scene} couvre tout accès à Suicune")

	print("whirl_islands_b2f")
	w2 = lire(PLANS / "whirl_islands_b2f.txt")
	r = communs(w2, (24, 24), "from_b1f", [])
	paire(wb, "vers_b2f", w2, "vers_b1f")
	couvre(w2, "from_b1f", "scene_lugia", "lugia")
	verifie(voisines_atteintes(w2, "lugia", r), "Lugia abordable depuis l'eau")
	verifie(voisines_atteintes(w2, "super_bonbons", r) and w2.at(13, 2) == ".", "Super Bonbon ×2 derrière la cascade, grotte (13, 2)")

	print("JOH7 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


def nage_sans(plan, depart, interdites: set, inertes: set) -> set:
	"""Comme nage(), en interdisant des cases (scènes)."""
	bloc = bloquees(plan) | interdites

	def libre(x, y):
		return 0 <= x < plan.width and 0 <= y < plan.height and plan.at(x, y) in plan.praticables and (x, y) not in bloc

	vus = set(c for c in depart if libre(*c))
	file = deque(vus)
	while file:
		x, y = file.popleft()
		for dx, dy in DIRS:
			n = (x + dx, y + dy)
			if not libre(*n):
				continue
			if plan.at(*n) in FLECHES and n not in inertes:
				n = courant(plan, n, inertes)
				if n is None or not libre(*n):
					continue
			if n not in vus:
				vus.add(n)
				file.append(n)
	return vus


if __name__ == "__main__":
	sys.exit(main())
