#!/usr/bin/env python3
"""Vérifie Azuria « après J18 » : variante `J18` de `tools/plans/azuria.txt` (jalon 18).

Référence : dossier 21 §9 et §13.1 ; dossier 19 (J16) pour l'arbuste coupable. La grille de base
(J13) reste contrôlée par `plan_check_azuria.py`, la variante J14 par `plan_check_azuria_j14.py` ;
la variante J18 est CUMULATIVE (le lecteur n'applique qu'une variante à la fois) : elle doit
valoir J14 plus les seuls changements du J18.

Critères :
  1. Cumul : toutes les rangées et positions de J14 reprises à l'identique, sauf les rangées
     22..24 (x 53..55) et les positions de l'est (warp_est, from_route_9, barriere_est).
  2. Arbre « k » unique en (53, 23), entre deux pans de clôture (53, 22) et (53, 24) ; sentier
     « = » de 3 × 2 cases derrière (54..55, 22..24).
  3. Tant que l'arbre est debout (état final E3 de J14), le sentier et le raccord est sont
     inatteignables depuis l'entrée ouest ; une fois coupé, ils le sont, le raccord à 3 pas de la
     case devant l'arbre ; l'arbre est le seul verrou.
  4. Raccord est : rangées praticables, warps et spawns = ouest de la Route 9 (aucun décalage).
  5. Bords ouverts : ouest, nord, sud et est (sentier) seulement.

Usage : python3 tools/art/plan_check_azuria_j18.py [azuria.txt]   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from dataclasses import replace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import INF  # noqa: E402
from plan_check_azuria import Rapport, _libres_du_bord, _nom  # noqa: E402
from plan_check_azuria_j14 import ETATS, carte_etat  # noqa: E402
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
ARBRE = (53, 23)
DERRIERE = [(x, y) for x in (54, 55) for y in (22, 23, 24)]
EST_IDS = ("warp_est", "from_route_9", "barriere_est")
CHANGEES = {(x, y) for x in (53, 54, 55) for y in (22, 23, 24)}


def verifier_azuria_j18(chemin: Path) -> bool:
	j14 = lire(chemin, "J14")
	plan = lire(chemin, "J18")
	pos = plan.positions
	r = Rapport(f"Azuria après J18 — {_nom(chemin)} (variante J18) : {plan.width} × {plan.height}")

	# 1. Cumul.
	diff = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if j14.at(x, y) != plan.at(x, y)}
	r.critere((j14.width, j14.height) == (plan.width, plan.height) and diff <= CHANGEES and diff,
		f"J18 = J14 + l'est seulement ({len(diff)} cases changées, toutes en x 53..55, y 22..24)")
	ecarts = [i for i, p in j14.positions.items() if i not in EST_IDS and (
		i not in pos or pos[i].cells != p.cells or pos[i].attrs != p.attrs
		or pos[i].kind != p.kind or pos[i].bloque != p.bloque)]
	r.critere(not ecarts and all(i in pos for i in EST_IDS),
		f"toutes les positions de J14 reprises à l'identique {ecarts}")
	r.critere(plan.praticables >= j14.praticables and "k" not in plan.praticables,
		"cases praticables de J14 conservées ; « k » bloqué debout")

	# 2. Arbre et sentier.
	r.critere(plan.cells_of("k") == [ARBRE] and plan.at(53, 22) == "c" and plan.at(53, 24) == "c"
		and all(plan.at(*c) == "=" for c in DERRIERE),
		f"arbre à couper « k » {ARBRE} entre deux pans de clôture ; sentier 3 × 2 derrière")

	# 3. Verrou.
	debout = carte_etat(plan, ETATS[3][1])
	entree = sorted(c for c in _libres_du_bord(debout) if c[0] == 0)
	dist = debout.distances(entree)
	# Coupé : « k » praticable et l'examen `barriere_est` ne bloque plus la case de l'arbre.
	coupee = carte_etat(replace(plan, praticables=plan.praticables | {"k"}),
		ETATS[3][1]).avec(retire=[ARBRE])
	dist_c = coupee.distances(entree)
	est = sorted(c for c in DERRIERE if c[0] == plan.width - 1)
	r.critere(not any(c in dist for c in DERRIERE) and all(c in dist_c for c in DERRIERE),
		"derrière l'arbre : inatteignable debout, atteignable une fois coupé")
	r.critere(dist_c[ARBRE] == dist[(52, 23)] + 1
		and min(dist_c[c] for c in est) - dist[(52, 23)] == 3,
		"l'arbre est le seul verrou : raccord est à 3 pas de la case devant l'arbre")

	# 4. Raccord est = ouest de la Route 9.
	route_9 = lire(chemin.with_name("route_9.txt"))
	ouest = sorted(c for p in route_9.of_kind("warp") for c in p.cells if c[0] == 0)
	w = sorted(c for c in pos["warp_est"].cells)
	s = sorted(c for c in pos["from_route_9"].cells)
	r.critere(est == w == s and [y for _, y in est] == [y for _, y in ouest],
		f"raccord est : rangées {[y for _, y in est]} = ouest de la Route 9 "
		f"(0, {ouest[0][1]}..{ouest[-1][1]}), aucun décalage")
	r.critere(pos["barriere_est"].cells == [(53, 22), (53, 23), (53, 24)] and pos["barriere_est"].bloque,
		"barriere_est : examen sur l'arbre et la clôture (texte 17)")

	# 5. Bords.
	bords = _libres_du_bord(coupee)
	r.critere(all(c[0] == 0 or c[1] in (0, plan.height - 1) or c in est for c in bords)
		and set(est) <= set(bords),
		"seuls bords ouverts : ouest, nord, sud (J14 E3) et le sentier est derrière l'arbre")

	r.info(f"entrée ouest → devant l'arbre {dist.get((52, 23), INF)} pas")
	return r.ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/azuria.txt"
	ok = verifier_azuria_j18(chemin.resolve())
	print("Plan conforme." if ok else "Plan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
