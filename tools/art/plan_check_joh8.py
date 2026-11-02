#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH8 (Chapitre Johto, dossier docs/design/dossier-joh-09-tour-carillon.md).

Grilles : `tools/plans/bell_tower_woods.txt` (24 × 20), `bell_tower_1f.txt` (24 × 24),
`bell_tower_2f.txt` (24 × 24), `bell_tower_roof.txt` (20 × 20), plus la retouche de `rosalia.txt`
(sage blessé, raccord nord). Mêmes règles que les contrôles du JOH2 au JOH7 (dont on reprend les
fonctions) ; les planches qui cèdent (O) se marchent (chute au 1F).

Pour chaque carte : taille ; cases praticables connexes ; aucune ouverture sur le pourtour hors
des warps de bord ; objets, Dresseurs, panneaux et examens abordables. Raccords : Rosalia nord ↔
Bois sud (2 cases), Bois porte ↔ 1F entrée, paires 1F ↔ 2F et 2F ↔ sommet (même case, arrivée
voisine). Bois : Sbire de guet évitable. 1F : Sbire V inévitable. 2F : chaque O porte un trou vers
le 1F (jamais vers le sommet), l'arrivée « chute » existe au 1F, un chemin sans chute mène au
sommet, Sbire W évitable, Hiroshi abordable. Sommet : la scène d'arrivée couvre la seule sortie du
palier ; Entei (depuis (12, 9)), Ho-Oh et la plume abordables.

Usage : python3 tools/art/plan_check_joh8.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, cases, communs, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh4 import evitable, inevitable  # noqa: E402
from plan_check_joh5 import couvre  # noqa: E402
from plan_check_joh6 import paire, sans  # noqa: E402

PLANS = base.PLANS


def main() -> int:
	print("rosalia (retouche)")
	ros = lire(PLANS / "rosalia.txt")
	r = atteignables(ros, cases(ros, "from_route_38"))
	verifie(voisines_atteintes(ros, "sage_blesse", r), "le sage blessé (H-1) est abordable")

	print("bell_tower_woods")
	bw = lire(PLANS / "bell_tower_woods.txt")
	r = communs(bw, (24, 20), "from_ecruteak", ["warp_sud"])
	verifie(len(cases(ros, "warp_bois")) == len(cases(bw, "warp_sud")) == 2, "raccord Rosalia ↔ Bois : 2 cases de chaque côté")
	verifie(all(c in r for c in cases(bw, "retour_tour")), "retour devant la porte atteignable")
	evitable(bw, "from_ecruteak", "porte_tour", "sbire_guet")

	print("bell_tower_1f")
	t1 = lire(PLANS / "bell_tower_1f.txt")
	r = communs(t1, (24, 24), "from_woods", ["sortie", "vers_2f"])
	verifie(all(c in r for c in cases(t1, "chute")), "arrivée des chutes atteignable")
	inevitable(t1, "from_woods", "vers_2f", "sbire_v")

	print("bell_tower_2f")
	t2 = lire(PLANS / "bell_tower_2f.txt")
	r = communs(t2, (24, 24), "from_1f", ["vers_1f", "vers_sommet"])
	paire(t1, "vers_2f", t2, "vers_1f")
	trous = {c for p in t2.of_kind("trou") for c in p.cells}
	verifie(trous == set(t2.cells_of("O")), "chaque planche O porte un trou et réciproquement")
	verifie(all(p.attrs.get("vers") == "bell_tower_1f" and p.attrs.get("arrivee") == "chute" for p in t2.of_kind("trou")),
		"toutes les planches tombent au 1F (jamais au sommet)")
	r_sec = sans(t2, "from_1f", "O")
	verifie(all(c in r_sec for c in cases(t2, "vers_sommet")), "un chemin sans chute mène à l'escalier du sommet")
	verifie(voisines_atteintes(t2, "hiroshi", r_sec), "Hiroshi abordable sans chute")
	evitable(t2, "from_1f", "vers_sommet", "sbire_w")

	print("bell_tower_roof")
	tr = lire(PLANS / "bell_tower_roof.txt")
	r = communs(tr, (20, 20), "from_2f", ["vers_2f"])
	paire(t2, "vers_sommet", tr, "vers_2f")
	couvre(tr, "from_2f", "scene_sommet", "dante")
	verifie((12, 8) in r and voisines_atteintes(tr, "entei", r), "Entei abordable depuis (12, 8)")
	verifie(voisines_atteintes(tr, "ho_oh", r) and voisines_atteintes(tr, "plume", r), "Ho-Oh et la plume abordables")
	verifie(not tr.of_kind("trou"), "aucune planche qui cède au sommet")

	print("JOH8 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
