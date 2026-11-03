#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH9 (Chapitre Johto, dossier docs/design/dossier-joh-10-mont-argente.md).

Grilles : `tools/plans/silver_trail.txt` (24 × 44), `mt_silver_outside.txt` (40 × 40),
`mt_silver_1f.txt`, `mt_silver_2f.txt` (32 × 28), `mt_silver_3f.txt` (28 × 24),
`mt_silver_summit.txt` (20 × 18), `route_28.txt` (44 × 20), `route_28_gate.txt` (10 × 8), plus
les retouches de `lake_of_rage.txt` (sentier) et `route_22_ouest.txt` (porte neuve, JH-8). Mêmes
règles que les contrôles du JOH2 au JOH8 (dont on reprend les fonctions) ; l'eau se traverse en
Surf ; les rochers de Force bloquent tant qu'on ne les pousse pas (couloir de poussée ≥ 2 cases).

Pour chaque carte : taille ; cases praticables connexes ; aucune ouverture sur le pourtour hors
des warps de bord ; objets, Dresseurs, panneaux et examens abordables. Raccords : Lac Colère est ↔
Sentier ouest, Sentier nord ↔ extérieur sud, extérieur entrée ↔ 1F, 1F sortie ouest ↔ Route 28
est (1 case), Route 28 porte ↔ poste ↔ Route 22 ouest ; paires d'échelles 1F ↔ 2F ↔ 3F ↔ sommet.
Sentier : Hugo inévitable, Baptiste et Inès évitables, 3 poches évitables. Extérieur : la scène
du relais couvre la seule entrée de l'esplanade, 3 poches évitables. 1F : lac obligatoire vers le
nord, Route 28 atteignable sans Surf ni Force, rochers de Force dans l'ordre, Y inévitable, X
évitable. 2F : la scène du rival couvre le seul passage. 3F : Lucas évitable. Sommet : la scène
couvre la seule sortie du palier. Route 28 : Jules évitable. Poste : les deux contrôles couvrent
leurs sorties.

Usage : python3 tools/art/plan_check_joh9.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, bloquees, cases, communs, herbes_evitables, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh3 import largeur  # noqa: E402
from plan_check_joh4 import evitable, inevitable  # noqa: E402
from plan_check_joh5 import couvre  # noqa: E402
from plan_check_joh6 import paire, sans  # noqa: E402

PLANS = base.PLANS
DIRS_NSEO = {"E": (1, 0), "O": (-1, 0), "S": (0, 1), "N": (0, -1)}


def rochers_force(plan, depart: str, cible: str) -> None:
	rochers = plan.of_kind("rocher")
	for p in rochers:
		p.bloque = True
	r0 = atteignables(plan, cases(plan, depart))
	verifie(not any(c in r0 for c in cases(plan, cible)), f"sans Force (rochers en place), {cible} est inaccessible")
	for i, p in enumerate(rochers):
		for q in rochers:
			q.bloque = rochers.index(q) >= i
		r = atteignables(plan, cases(plan, depart))
		bloc = bloquees(plan)
		lane = [tuple(int(v) for v in c.split(",")) for c in p.attrs["lane"].split(";")]
		(x, y) = p.cells[0]
		dx, dy = DIRS_NSEO[p.attrs["pousse"]]
		verifie(len(lane) >= 2 and all(lane[k] == (x + dx * (k + 1), y + dy * (k + 1)) for k in range(len(lane)))
			and all(plan.at(*c) in plan.praticables and c not in bloc for c in lane),
			f"{p.ident} : couloir de poussée libre sur {len(lane)} cases vers {p.attrs['pousse']}")
		verifie((x - dx, y - dy) in r, f"{p.ident} : le joueur arrive derrière le rocher pour le pousser")
	for p in rochers:
		p.bloque = False


def main() -> int:
	print("lake_of_rage, route_22_ouest (retouches)")
	lac = lire(PLANS / "lake_of_rage.txt")
	r22 = lire(PLANS / "route_22_ouest.txt", "JOH9")  # retouche portée par la variante JOH9 jusqu'au code du JOH9
	r = atteignables(r22, cases(r22, "from_route_22"))
	verifie(all(c in r for c in cases(r22, "porte_route_28") + cases(r22, "from_route_28_gate")), "porte neuve de la Route 22 atteignable")

	print("silver_trail")
	st = lire(PLANS / "silver_trail.txt")
	r = communs(st, (24, 44), "from_lake", ["warp_ouest", "warp_nord"])
	largeur(lac, "warp_sentier", st, "warp_ouest")
	verifie(all(c in r for c in cases(st, "retour_centre")), "retour du Centre atteignable")
	verifie(len(st.of_kind("herbes")) == 3, "3 poches d'herbes")
	herbes_evitables(st, "from_lake", "warp_nord")
	inevitable(st, "from_lake", "warp_nord", "hugo")
	evitable(st, "from_lake", "warp_nord", "baptiste")
	evitable(st, "from_lake", "warp_nord", "ines")

	print("mt_silver_outside")
	ex = lire(PLANS / "mt_silver_outside.txt")
	communs(ex, (40, 40), "from_trail", ["warp_sud"])
	largeur(st, "warp_nord", ex, "warp_sud")
	verifie(len(ex.of_kind("herbes")) == 3, "3 poches d'herbes")
	herbes_evitables(ex, "from_trail", "entree_grotte")
	couvre(ex, "from_trail", "scene_relais", "entree_grotte")
	verifie(all(c in atteignables(ex, cases(ex, "from_trail")) for c in cases(ex, "retour_grotte")), "retour devant la grotte atteignable")

	print("mt_silver_1f")
	g1 = lire(PLANS / "mt_silver_1f.txt")
	for p in g1.of_kind("rocher"):
		p.bloque = False
	r = communs(g1, (32, 28), "from_outside", ["entree", "sortie_ouest"])
	verifie(all(c in r for c in cases(g1, "vers_2f")), "échelle du 2F atteignable (Surf et Force)")
	r_sec = sans(g1, "from_outside", "w")
	verifie(not any(c in r_sec for c in cases(g1, "vers_2f")), "le lac se traverse en Surf (pas de chemin à pied vers le nord)")
	rochers_force(g1, "from_outside", "vers_2f")
	for p in g1.of_kind("rocher"):
		p.bloque = True
	r_bloque = atteignables(g1, cases(g1, "from_outside"), chars=g1.praticables - {"w"})
	verifie(all(c in r_bloque for c in cases(g1, "sortie_ouest")), "la sortie vers la Route 28 ne demande ni Surf ni Force")
	for p in g1.of_kind("rocher"):
		p.bloque = False
	inevitable(g1, "from_outside", "vers_2f", "sbire_y")
	evitable(g1, "from_outside", "vers_2f", "sbire_x")

	print("mt_silver_2f")
	g2 = lire(PLANS / "mt_silver_2f.txt")
	communs(g2, (32, 28), "from_1f", [])
	paire(g1, "vers_2f", g2, "vers_1f")
	couvre(g2, "from_1f", "scene_rival", "vers_3f")
	z = g2.positions["obscurite"]
	verifie(all((x, y) in set(z.cells) for y in range(g2.height) for x in range(g2.width) if g2.at(x, y) in g2.praticables),
		"le voile d'obscurité couvre toute la carte")

	print("mt_silver_3f")
	g3 = lire(PLANS / "mt_silver_3f.txt")
	communs(g3, (28, 24), "from_2f", [])
	paire(g2, "vers_3f", g3, "vers_2f")
	evitable(g3, "from_2f", "vers_sommet", "lucas")

	print("mt_silver_summit")
	so = lire(PLANS / "mt_silver_summit.txt")
	r = communs(so, (20, 18), "from_3f", [])
	paire(g3, "vers_sommet", so, "vers_3f")
	couvre(so, "from_3f", "scene_sommet", "dante")
	for ident in ("giovanni", "cenere_sommet", "rival_sommet"):
		verifie(all(c in r for c in cases(so, ident)), f"{ident} posé sur une case atteignable")

	print("route_28")
	r28 = lire(PLANS / "route_28.txt")
	r = communs(r28, (44, 20), "from_mt_silver", ["warp_est"])
	verifie(len(cases(g1, "sortie_ouest")) == len(cases(r28, "warp_est")) == 1, "raccord grotte 1F ↔ Route 28 : 1 case de chaque côté")
	verifie(all(c in r for c in cases(r28, "from_gate") + cases(r28, "retour_maison")), "retours du poste et de la maison atteignables")
	herbes_evitables(r28, "from_mt_silver", "porte_poste")
	evitable(r28, "from_mt_silver", "porte_poste", "jules")

	print("route_28_gate")
	gt = lire(PLANS / "route_28_gate.txt")
	communs(gt, (10, 8), "from_route_28", ["sortie_nord", "sortie_sud"])
	couvre(gt, "from_route_22", "controle_kanto", "sortie_nord")
	couvre(gt, "from_route_28", "barriere_johto", "sortie_sud")
	verifie(cases(gt, "scene_porte") == cases(gt, "barriere_johto"), "la scène A-47 est sur les cases de la barrière")

	print("JOH9 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
