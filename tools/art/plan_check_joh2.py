#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH2 (Chapitre Johto, dossier docs/design/dossier-joh-03-rosalia.md).

Grilles : `tools/plans/route_39.txt` (24 × 50), `route_38.txt` (60 × 20) et `rosalia.txt`
(56 × 48). Lecture par `plan_grille.lire` ; déplacements en 4 directions sur les cases praticables
de chaque grille ; positions `bloque` bloquantes ; les déclencheurs (barrières) ne bloquent pas.

Pour chaque carte : taille ; toutes les cases praticables connexes ; aucune ouverture sur le
pourtour hors des warps de bord ; toutes les portes, objets et dresseurs abordables.
Raccords : Oliville est ↔ Route 39 ouest, Route 39 est ↔ Route 38 ouest, Route 38 est ↔ Rosalia
ouest, sur les mêmes rangées.
Herbes : Route 39 2 poches, Route 38 3 poches, toutes évitables (le sentier relie les bords sans
herbes) ; Rosalia : herbe seulement autour des tours (rangées y ≤ 13).
Route 38 : la Dresseuse Inès est inévitable (sans sa case de vue, l'est est inatteignable).
Rosalia : la scène des Sbires coupe l'avenue ; la barrière du chemin gardé et celle de la Route 42
couvrent toute la largeur de leur passage.

Usage : python3 tools/art/plan_check_joh2.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1))

echecs: list[str] = []


def verifie(cond: bool, message: str) -> None:
	print(("  ok   " if cond else "  ÉCHEC ") + message)
	if not cond:
		echecs.append(message)


def bloquees(plan) -> set[tuple[int, int]]:
	return {c for p in plan.positions.values() if p.bloque for c in p.cells}


def atteignables(plan, depart, interdites: set | None = None, chars: set | None = None) -> set:
	bloc = bloquees(plan) | (interdites or set())
	ok = chars if chars is not None else plan.praticables

	def libre(x, y):
		return 0 <= x < plan.width and 0 <= y < plan.height \
			and plan.at(x, y) in ok and (x, y) not in bloc

	vus = set(c for c in depart if libre(*c))
	file = deque(vus)
	while file:
		x, y = file.popleft()
		for dx, dy in DIRS:
			n = (x + dx, y + dy)
			if libre(*n) and n not in vus:
				vus.add(n)
				file.append(n)
	return vus


def cases(plan, ident):
	return plan.positions[ident].cells


def voisines_atteintes(plan, ident, r) -> bool:
	"""Une position bloquante (objet, dresseur, panneau) est abordable depuis une case voisine."""
	return any((x + dx, y + dy) in r for x, y in cases(plan, ident) for dx, dy in DIRS)


def communs(plan, taille, depart, bords: list[str]) -> set:
	verifie((plan.width, plan.height) == taille, f"taille {taille[0]} × {taille[1]}")
	r = atteignables(plan, cases(plan, depart))
	bloc = bloquees(plan)
	toutes = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in bloc}
	verifie(toutes <= r, f"toutes les cases praticables connexes ({sorted(toutes - r)[:5]} isolées)")
	ouvertures = set().union(*(cases(plan, b) for b in bords))
	bord = {c for c in toutes if c[0] in (0, plan.width - 1) or c[1] in (0, plan.height - 1)}
	verifie(bord <= ouvertures, f"aucune autre ouverture sur le pourtour ({sorted(bord - ouvertures)[:5]})")
	for b in bords:
		verifie(all(c in r for c in cases(plan, b)), f"{b} atteignable")
	for p in plan.positions.values():
		if p.kind == "warp" and p.ident not in bords:
			verifie(all(c in r for c in p.cells), f"{p.ident} atteignable")
		if p.kind in ("objet_visible", "cache", "dresseur", "panneau", "examen"):
			verifie(voisines_atteintes(plan, p.ident, r), f"{p.ident} abordable")
	return r


def herbes_evitables(plan, de: str, vers: str) -> None:
	sans = plan.praticables - {"h"}
	r = atteignables(plan, cases(plan, de), chars=sans)
	verifie(all(c in r for c in cases(plan, vers)), f"{de} → {vers} sans traverser d'herbes")


def raccord(a, wa, b, wb) -> None:
	ya = sorted(y for _, y in cases(a, wa))
	yb = sorted(y for _, y in cases(b, wb))
	verifie(ya == yb, f"raccord {wa} ↔ {wb} sur les mêmes rangées ({ya} / {yb})")


def route_39(oliville):
	print("route_39")
	p = lire(PLANS / "route_39.txt")
	communs(p, (24, 50), "from_olivine", ["warp_ouest", "warp_est"])
	raccord(oliville, "warp_est", p, "warp_ouest")
	verifie(len(p.of_kind("herbes")) == 2, "2 poches d'herbes hautes")
	herbes_evitables(p, "from_olivine", "warp_est")
	verifie(all(p.at(*c) == "e" for n in ("ecremeuh_1", "ecremeuh_2", "ecremeuh_3", "tauros", "ponyta")
		for c in cases(p, n)), "Pokémon de la ferme dans l'enclos")
	return p


def route_38(r39):
	print("route_38")
	p = lire(PLANS / "route_38.txt")
	communs(p, (60, 20), "from_route_39", ["warp_ouest", "warp_est"])
	raccord(r39, "warp_est", p, "warp_ouest")
	verifie(len(p.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(p, "from_route_39", "warp_est")
	vue_ines = {(42, 15)}
	r = atteignables(p, cases(p, "from_route_39"), interdites=vue_ines)
	verifie(not any(c in r for c in cases(p, "warp_est")), "Inès inévitable : sa case de vue (42, 15) est le seul passage")
	return p


def rosalia(r38) -> None:
	print("rosalia")
	p = lire(PLANS / "rosalia.txt")
	communs(p, (56, 48), "from_route_38", ["warp_ouest", "warp_sud", "warp_est", "warp_bois"])
	raccord(r38, "warp_est", p, "warp_ouest")
	depart = cases(p, "from_route_38")
	for ident, cible in (("scene_sbires", "warp_sud"), ("barriere_carillon", "warp_bois"),
			("barriere_route_42", "warp_est")):
		r = atteignables(p, depart, interdites=set(cases(p, ident)))
		verifie(not any(c in r for c in cases(p, cible)), f"{ident} couvre tout son passage")
	verifie(all(y <= 13 for x, y in p.cells_of("h")), "herbe seulement autour des tours (y ≤ 13)")
	verifie(len(p.of_kind("herbes")) == 3, "3 zones d'herbe des tours")


def main() -> int:
	oliville = lire(PLANS / "oliville.txt")
	r39 = route_39(oliville)
	r38 = route_38(r39)
	rosalia(r38)
	print("JOH2 : " + ("tout est bon" if not echecs else f"{len(echecs)} échec(s)"))
	return 1 if echecs else 0


if __name__ == "__main__":
	sys.exit(main())
