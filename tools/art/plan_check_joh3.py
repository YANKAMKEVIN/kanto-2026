#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH3 (Chapitre Johto, dossier docs/design/dossier-joh-04-doublonville.md).

Grilles : `tools/plans/route_37.txt` (20 × 40), `route_36.txt` (56 × 20), `route_35.txt` (24 × 44),
`doublonville.txt` (72 × 60) et `souterrain.txt` (40 × 14). Mêmes règles que le contrôle du JOH2
(`plan_check_joh2.py`, dont on reprend les fonctions) : 4 directions, positions `bloque`
bloquantes, déclencheurs libres ; l'étang de la Route 35 (w) se traverse en Surf (JH-36).

Pour chaque carte : taille ; toutes les cases praticables connexes ; aucune ouverture sur le
pourtour hors des warps de bord ; portes, escaliers, objets, Dresseurs et panneaux abordables.
Raccords : Rosalia sud ↔ Route 37 nord, Route 37 sud ↔ Route 36 nord (mêmes colonnes), Route 36
sud ↔ Route 35 nord, Route 35 sud ↔ Doublonville nord (même largeur de 3 cases).
Herbes : 2 poches (Route 37), 3 (Routes 36 et 35), toutes évitables d'un bord à l'autre.
Route 35 : la Campeuse Anna est inévitable. Route 36 : le pont est fermé (aucune case à l'est de la
barrière). Doublonville : la barrière de la sortie sud couvre tout le passage. Souterrain : les
Sbires C et D sont évitables d'un escalier à l'autre ; le chef est abordable.

Usage : python3 tools/art/plan_check_joh3.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, cases, communs, herbes_evitables, verifie  # noqa: E402

PLANS = base.PLANS


def largeur(a, wa, b, wb) -> None:
	verifie(len(cases(a, wa)) == len(cases(b, wb)) == 3, f"raccord {wa} ↔ {wb} : 3 cases de chaque côté")


def colonnes(a, wa, b, wb) -> None:
	xa = sorted(x for x, _ in cases(a, wa))
	xb = sorted(x for x, _ in cases(b, wb))
	verifie(xa == xb, f"raccord {wa} ↔ {wb} sur les mêmes colonnes ({xa} / {xb})")


def vue(plan, ident) -> set:
	"""Cases vues par un Dresseur (direction `facing`, portée `sight`)."""
	p = plan.positions[ident]
	dx, dy = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}[p.attrs["facing"]]
	(x, y), n = p.cells[0], int(p.attrs["sight"])
	return {(x + dx * i, y + dy * i) for i in range(1, n + 1)}


def main() -> int:
	rosalia = lire(PLANS / "rosalia.txt")
	print("route_37")
	r37 = lire(PLANS / "route_37.txt")
	communs(r37, (20, 40), "from_ecruteak", ["warp_nord", "warp_sud"])
	largeur(rosalia, "warp_sud", r37, "warp_nord")
	verifie(len(r37.of_kind("herbes")) == 2, "2 poches d'herbes hautes")
	herbes_evitables(r37, "from_ecruteak", "warp_sud")
	for s in ("sbire_a", "sbire_b"):
		verifie(r37.positions[s].attrs.get("periode") == "nuit", f"{s} : la nuit seulement")
		r = atteignables(r37, cases(r37, "from_ecruteak"), interdites=vue(r37, s))
		verifie(all(c in r for c in cases(r37, "warp_sud")), f"{s} évitable")

	print("route_36")
	r36 = lire(PLANS / "route_36.txt")
	communs(r36, (56, 20), "from_route_37", ["warp_nord", "warp_sud"])
	colonnes(r37, "warp_sud", r36, "warp_nord")
	verifie(len(r36.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(r36, "from_route_37", "warp_sud")
	r = atteignables(r36, cases(r36, "from_route_37"))
	verifie(not any(x >= 46 for x, _ in r), "pont en travaux : rien d'atteignable à l'est de la barrière")
	verifie(base.voisines_atteintes(r36, "grille_parc", r), "grille du Parc National abordable")

	print("route_35")
	r35 = lire(PLANS / "route_35.txt")
	communs(r35, (24, 44), "from_route_36", ["warp_nord", "warp_sud"])
	largeur(r36, "warp_sud", r35, "warp_nord")
	verifie(len(r35.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(r35, "from_route_36", "warp_sud")
	r = atteignables(r35, cases(r35, "from_route_36"), interdites=vue(r35, "anna"))
	verifie(not any(c in r for c in cases(r35, "warp_sud")), "Anna inévitable : sa case de vue est le seul passage")
	verifie(all(r35.at(x, y) == "w" for x, y in vue(r35, "gaston")), "Gaston regarde l'étang")

	print("doublonville")
	gc = lire(PLANS / "doublonville.txt")
	communs(gc, (72, 60), "from_route_35", ["warp_nord", "warp_sud"])
	largeur(r35, "warp_sud", gc, "warp_nord")
	r = atteignables(gc, cases(gc, "from_route_35"), interdites=set(cases(gc, "barriere_sud")))
	verifie(not any(c in r for c in cases(gc, "warp_sud")), "barriere_sud couvre tout son passage")
	verifie(all(gc.at(*c) == "E" for n in ("escalier_ouest", "escalier_est") for c in cases(gc, n)),
		"escaliers du Souterrain sur des cases E")

	print("souterrain")
	sg = lire(PLANS / "souterrain.txt")
	communs(sg, (40, 14), "from_goldenrod_west", [])
	interdites = vue(sg, "sbire_c") | vue(sg, "sbire_d")
	r = atteignables(sg, cases(sg, "from_goldenrod_west"), interdites=interdites)
	verifie(all(c in r for c in cases(sg, "escalier_est")), "Sbires C et D évitables d'un escalier à l'autre")
	print("JOH3 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
