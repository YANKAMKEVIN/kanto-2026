#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH5 (Chapitre Johto, dossier docs/design/dossier-joh-06-tour-radio.md).

Grilles : `tools/plans/radio_tower_1f.txt` à `radio_tower_5f.txt` (24 × 16 chacune). Mêmes règles
que les contrôles du JOH2 au JOH4 (`plan_check_joh2.py`, `plan_check_joh3.py`, `plan_check_joh4.py`,
dont on reprend les fonctions) : 4 directions, positions `bloque` bloquantes, déclencheurs libres.

Pour chaque étage : taille ; toutes les cases praticables connexes ; aucune ouverture sur le
pourtour hors des escaliers, de l'ascenseur et de la sortie ; objets, Dresseurs et examens
abordables ; l'ascenseur en (18, 0) avec son arrivée une case devant.
Paires d'escaliers : 1F ↔ 2F (3, 0), 2F ↔ 3F (20, 0), 3F ↔ 4F (3, 0), 4F ↔ 5F (20, 0), même case des
deux côtés, arrivée une case devant.
1F : la scène du faux employé couvre le seul accès à l'escalier ; la scène de sortie couvre toute
la largeur du hall. 2F : le Sbire I est inévitable, H et J évitables. 3F : le gardien est
inévitable, K et L évitables ; la porte de la réserve est le seul accès à Raphaël. 4F : le Sbire O
est inévitable, M et N évitables. 5F : la scène de Cenere couvre le seul accès au studio ; la porte
du bureau est le seul accès au directeur.

Usage : python3 tools/art/plan_check_joh5.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, cases, communs, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh4 import evitable, inevitable  # noqa: E402

PLANS = base.PLANS
TAILLE = (24, 16)


def paire(bas, ident_bas: str, haut, ident_haut: str) -> None:
	cb, ch = cases(bas, ident_bas), cases(haut, ident_haut)
	verifie(cb == ch, f"paire {ident_bas} ↔ {ident_haut} sur la même case ({cb} / {ch})")
	pb, ph = bas.positions[ident_bas].attrs.get("paire"), haut.positions[ident_haut].attrs.get("paire")
	verifie(pb == ph and pb is not None, f"paire {pb} partagée")
	for plan, ident in ((bas, ident_bas), (haut, ident_haut)):
		spawn = next(p for p in plan.of_kind("spawn") if p.attrs.get("paire") == pb)
		(x, y) = cases(plan, ident)[0]
		verifie(spawn.cells == [(x, y + 1)], f"{spawn.ident} une case devant {ident}")


def ascenseur(plan) -> None:
	verifie(cases(plan, "ascenseur") == [(18, 0)] and plan.at(18, 0) == "L", "ascenseur en (18, 0) sur une case L")
	verifie(cases(plan, "from_elevator") == [(18, 1)], "arrivée de l'ascenseur en (18, 1)")


def couvre(plan, depart: str, scene: str, cible: str) -> None:
	r = atteignables(plan, cases(plan, depart), interdites=set(cases(plan, scene)))
	verifie(not voisines_atteintes(plan, cible, r) and not any(c in r for c in cases(plan, cible)),
		f"{scene} couvre le seul accès à {cible}")


def main() -> int:
	print("radio_tower_1f")
	f1 = lire(PLANS / "radio_tower_1f.txt")
	communs(f1, TAILLE, "from_city", ["sortie_ville", "vers_2f", "ascenseur"])
	ascenseur(f1)
	couvre(f1, "from_city", "scene_impostor", "vers_2f")
	verifie(set(cases(f1, "scene_sortie")) >= {(x, 12) for x in range(1, 23) if f1.at(x, 12) in f1.praticables},
		"scene_sortie couvre toute la largeur du hall")
	verifie(cases(f1, "sortie_ville") == [(11, 15), (12, 15)] and cases(f1, "from_city") == [(11, 14), (12, 14)],
		"sortie (11..12, 15) et arrivée une case devant")

	print("radio_tower_2f")
	f2 = lire(PLANS / "radio_tower_2f.txt")
	communs(f2, TAILLE, "from_1f", ["vers_1f", "vers_3f", "ascenseur"])
	ascenseur(f2)
	paire(f1, "vers_2f", f2, "vers_1f")
	inevitable(f2, "from_1f", "vers_3f", "sbire_i")
	evitable(f2, "from_1f", "vers_3f", "sbire_h")
	evitable(f2, "from_1f", "vers_3f", "sbire_j")

	print("radio_tower_3f")
	f3 = lire(PLANS / "radio_tower_3f.txt")
	communs(f3, TAILLE, "from_2f", ["vers_2f", "vers_4f", "ascenseur"])
	ascenseur(f3)
	paire(f2, "vers_3f", f3, "vers_2f")
	inevitable(f3, "from_2f", "vers_4f", "gardien")
	evitable(f3, "from_2f", "vers_4f", "sbire_k")
	evitable(f3, "from_2f", "vers_4f", "sbire_l")
	couvre(f3, "from_2f", "porte_reserve", "raphael")
	verifie(f3.at(*cases(f3, "porte_reserve")[0]) == "K", "porte de la réserve sur une case K")

	print("radio_tower_4f")
	f4 = lire(PLANS / "radio_tower_4f.txt")
	communs(f4, TAILLE, "from_3f", ["vers_3f", "vers_5f", "ascenseur"])
	ascenseur(f4)
	paire(f3, "vers_4f", f4, "vers_3f")
	inevitable(f4, "from_3f", "vers_5f", "sbire_o")
	evitable(f4, "from_3f", "vers_5f", "sbire_m")
	evitable(f4, "from_3f", "vers_5f", "sbire_n")

	print("radio_tower_5f")
	f5 = lire(PLANS / "radio_tower_5f.txt")
	communs(f5, TAILLE, "from_4f", ["vers_4f", "ascenseur"])
	ascenseur(f5)
	paire(f4, "vers_5f", f5, "vers_4f")
	couvre(f5, "from_4f", "scene_cenere", "cenere")
	couvre(f5, "from_4f", "porte_bureau", "directeur")
	verifie(f5.at(*cases(f5, "porte_bureau")[0]) == "K", "porte du bureau sur une case K")
	verifie(not f5.of_kind("escalier") or all(p.attrs.get("sens") == "descend" for p in f5.of_kind("escalier")),
		"5F : dernier étage, aucun escalier qui monte")

	print("JOH5 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
