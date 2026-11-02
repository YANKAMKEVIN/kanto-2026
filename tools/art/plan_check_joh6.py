#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH6 (Chapitre Johto, dossier docs/design/dossier-joh-07-acajou.md).

Grilles : `tools/plans/burned_tower_1f.txt` (28 × 24), `burned_tower_b1f.txt` (20 × 16),
`route_42.txt` (72 × 20), `mahogany_town.txt` (36 × 30), `mahogany_souvenir_shop.txt` (15 × 10),
`route_43.txt` (24 × 52), `lake_of_rage.txt` (56 × 52), `mahogany_hideout_b1f.txt` (30 × 18),
`mahogany_hideout_b2f.txt` (30 × 22), `mahogany_hideout_b3f.txt` (24 × 18), plus la retouche de
`rosalia.txt` (porte de la Tour Cendrée). Mêmes règles que les contrôles du JOH2 au JOH5
(`plan_check_joh2.py` à `plan_check_joh5.py`, dont on reprend les fonctions) : 4 directions,
positions `bloque` bloquantes, déclencheurs libres ; l'eau (w) se traverse en Surf ; les trous (O)
se marchent (chute) ; les dalles glissent selon la règle du repaire de Céladopole
(`plan_check_repaire.glisse`).

Pour chaque carte : taille ; cases praticables connexes ; aucune ouverture sur le pourtour hors des
warps de bord ; objets, Dresseurs, panneaux et examens abordables. Raccords : Rosalia est ↔ Route 42
ouest, Route 42 est ↔ Acajou ouest, Acajou nord ↔ Route 43 sud, Route 43 nord ↔ Lac Colère sud
(3 cases de chaque côté) ; paires d'escaliers Tour 1F ↔ B1F, repaire B1F ↔ B2F ↔ B3F (même case,
arrivée voisine).
Tour 1F : l'échelle ne s'atteint pas sans marcher sur un trou ; Odile et le Sbire P évitables.
Tour B1F : la scène des chiens couvre les deux arrivées. Route 42 : lac obligatoire, Louis
inévitable, les trois autres évitables, 3 poches évitables, Super Bonbon en Surf seulement.
Boutique : escalier caché sous l'étagère (12, 3), scène devant. Route 43 : péager inévitable, Q et
Basile évitables, 3 poches évitables. Lac : Léviator rouge et Rappel Max en Surf seulement, pêcheur
à pied, barrière du sentier (JOH9). Repaire B1F : alarmes = vue des statues, un chemin les évite
toutes, l'Hyper Potion sonne la statue 3. B2F : trajets des dalles, les deux sorties de la salle ne
s'atteignent qu'en glissant, Scientifique inévitable, R et S évitables, portes à clé seules voies.
B3F : la scène de Brace couvre le seul passage ; Raikou abordable depuis (17, 10).

Usage : python3 tools/art/plan_check_joh6.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import DIRS, atteignables, bloquees, cases, communs, herbes_evitables, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh3 import largeur, vue  # noqa: E402
from plan_check_joh4 import evitable, inevitable  # noqa: E402
from plan_check_joh5 import couvre  # noqa: E402
from plan_check_repaire import FLECHES, glisse  # noqa: E402

PLANS = base.PLANS


def paire(a, ident_a: str, b, ident_b: str) -> None:
	ca, cb = cases(a, ident_a), cases(b, ident_b)
	verifie(ca == cb, f"paire {ident_a} ↔ {ident_b} sur la même case ({ca} / {cb})")
	pa, pb = a.positions[ident_a].attrs.get("paire"), b.positions[ident_b].attrs.get("paire")
	verifie(pa == pb and pa is not None, f"paire {pa} partagée")
	for plan, ident in ((a, ident_a), (b, ident_b)):
		spawn = next(p for p in plan.of_kind("spawn") if p.attrs.get("paire") == pa)
		(x, y) = cases(plan, ident)[0]
		(sx, sy) = spawn.cells[0]
		verifie(abs(sx - x) + abs(sy - y) == 1 and plan.at(sx, sy) in plan.praticables,
			f"{spawn.ident} sur une case voisine libre de {ident}")


def sans(plan, depart: str, lettre: str) -> set:
	return atteignables(plan, cases(plan, depart), chars=plan.praticables - {lettre})


def glisse_bfs(plan, depart) -> set:
	"""Cases atteintes en marchant ET en glissant sur les dalles (une flèche téléporte à son arrêt)."""
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
			if plan.at(*n) in FLECHES:
				_, arret, erreur, _ = glisse(plan, n)
				if erreur or arret is None:
					continue
				n = arret
			if n not in vus:
				vus.add(n)
				file.append(n)
	return vus


def main() -> int:
	print("rosalia (retouche)")
	ros = lire(PLANS / "rosalia.txt")
	verifie(cases(ros, "entree_tour_cendree") == [(8, 12), (9, 12)] and all(ros.at(x, 12) == "D" for x in (8, 9)),
		"porte de la Tour Cendrée sur deux cases D (8..9, 12)")
	r = atteignables(ros, cases(ros, "from_route_38"))
	verifie(all(c in r for c in cases(ros, "entree_tour_cendree") + cases(ros, "retour_tour_cendree")),
		"porte et sortie de la Tour Cendrée atteignables")
	verifie(voisines_atteintes(ros, "panneau_tour_cendree", r), "panneau C-3 abordable")

	print("burned_tower_1f")
	f1 = lire(PLANS / "burned_tower_1f.txt")
	communs(f1, (28, 24), "from_city", ["sortie"])
	trous = {c for p in f1.of_kind("trou") for c in p.cells}
	verifie(trous == set(f1.cells_of("O")), "chaque case O porte un trou et réciproquement")
	verifie(all(p.attrs.get("vers") == "burned_tower_b1f" and p.attrs.get("arrivee") == "chute" for p in f1.of_kind("trou")),
		"tous les trous tombent au B1F, arrivée « chute »")
	r_sans_trou = sans(f1, "from_city", "O")
	verifie(not any(c in r_sans_trou for c in cases(f1, "vers_b1f")), "l'échelle ne s'atteint pas sans marcher sur un trou")
	verifie(all(c in r_sans_trou for c in cases(f1, "plancher_effondre")), "la scène C-5 se joue avant les trous")
	evitable(f1, "from_city", "plancher_effondre", "odile")
	evitable(f1, "from_city", "plancher_effondre", "sbire_p")

	print("burned_tower_b1f")
	b1 = lire(PLANS / "burned_tower_b1f.txt")
	r = communs(b1, (20, 16), "chute", [])
	verifie(all(c in r for c in cases(b1, "from_1f")), "arrivée de l'échelle atteignable")
	paire(f1, "vers_b1f", b1, "vers_1f")
	couvre(b1, "chute", "scene_chiens", "raikou")
	couvre(b1, "from_1f", "scene_chiens", "raikou")

	print("route_42")
	r42 = lire(PLANS / "route_42.txt")
	communs(r42, (72, 20), "from_ecruteak", ["warp_ouest", "warp_est"])
	largeur(ros, "warp_est", r42, "warp_ouest")
	verifie(len(r42.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(r42, "from_ecruteak", "warp_est")
	r_sec = sans(r42, "from_ecruteak", "w")
	verifie(not any(c in r_sec for c in cases(r42, "warp_est")), "le lac se traverse en Surf (pas de chemin à pied)")
	verifie(not voisines_atteintes(r42, "super_bonbon", r_sec), "le Super Bonbon de l'îlot demande Surf")
	inevitable(r42, "from_ecruteak", "warp_est", "louis")
	for d in ("hector", "marcel", "coralie"):
		evitable(r42, "from_ecruteak", "warp_est", d)

	print("mahogany_town")
	mt = lire(PLANS / "mahogany_town.txt")
	r = communs(mt, (36, 30), "from_route_42", ["warp_ouest", "warp_nord"])
	largeur(r42, "warp_est", mt, "warp_ouest")
	for s in ("retour_centre", "retour_boutique", "retour_maison_1", "retour_maison_2"):
		verifie(all(c in r for c in cases(mt, s)), f"{s} atteignable")

	print("mahogany_souvenir_shop")
	shop = lire(PLANS / "mahogany_souvenir_shop.txt")
	r = communs(shop, (15, 10), "entrance", ["sortie"])
	verifie(cases(shop, "vers_b1f") == [(12, 3)] and shop.at(12, 3) == "S", "escalier caché sur la case S (12, 3)")
	verifie(cases(shop, "scene_escalier") == [(12, 4)] and (12, 4) in r, "scène C-28 devant l'étagère, atteignable")

	print("route_43")
	r43 = lire(PLANS / "route_43.txt")
	communs(r43, (24, 52), "from_mahogany", ["warp_sud", "warp_nord"])
	largeur(mt, "warp_nord", r43, "warp_sud")
	verifie(len(r43.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(r43, "from_mahogany", "warp_nord")
	inevitable(r43, "from_mahogany", "warp_nord", "peager")
	evitable(r43, "from_mahogany", "warp_nord", "sbire_q")
	evitable(r43, "from_mahogany", "warp_nord", "basile")

	print("lake_of_rage")
	lac = lire(PLANS / "lake_of_rage.txt")
	r = communs(lac, (56, 52), "from_route_43", ["warp_sud", "warp_sentier"])
	largeur(r43, "warp_nord", lac, "warp_sud")
	verifie(len(lac.of_kind("herbes")) == 4, "4 poches d'herbes hautes")
	herbes_evitables(lac, "from_route_43", "warp_sentier")
	r_sec = sans(lac, "from_route_43", "w")
	verifie(voisines_atteintes(lac, "leviator_rouge", r) and not voisines_atteintes(lac, "leviator_rouge", r_sec),
		"le Léviator rouge s'aborde en Surf seulement")
	verifie(not voisines_atteintes(lac, "rappel_max", r_sec), "le Rappel Max de la rive nord demande Surf")
	verifie(voisines_atteintes(lac, "pecheur", r_sec), "le pêcheur s'aborde à pied")
	couvre(lac, "from_route_43", "barriere_sentier", "warp_sentier")
	evitable(lac, "from_route_43", "warp_sentier", "ludovic")

	print("mahogany_hideout_b1f")
	h1 = lire(PLANS / "mahogany_hideout_b1f.txt")
	r = communs(h1, (30, 18), "from_shop", [])
	verifie(all(c in r for c in cases(h1, "vers_boutique") + cases(h1, "vers_b2f")), "les deux escaliers atteignables")
	vues = set()
	for n in (1, 2, 3):
		v = vue(h1, f"statue_{n}")
		vues |= v
		verifie(set(cases(h1, f"alarme_{n}")) == v and all(h1.at(*c) in h1.praticables for c in v),
			f"alarme_{n} = regard de la statue {n}, sur des cases libres")
	r_discret = atteignables(h1, cases(h1, "from_shop"), interdites=vues)
	verifie(all(c in r_discret for c in cases(h1, "vers_b2f")), "un chemin évite les trois statues")
	verifie(not voisines_atteintes(h1, "hyper_potion", atteignables(h1, cases(h1, "from_shop"), interdites=vue(h1, "statue_3"))),
		"l'Hyper Potion sonne l'alarme de la statue 3")

	print("mahogany_hideout_b2f")
	h2 = lire(PLANS / "mahogany_hideout_b2f.txt")
	r = communs(h2, (30, 22), "from_b1f", [])
	paire(h1, "vers_b2f", h2, "vers_b1f")
	fleches = {c for ch in FLECHES for c in h2.cells_of(ch)}
	dalles = {p.cells[0]: p for p in h2.of_kind("dalle")}
	verifie(set(dalles) == fleches, "chaque flèche porte une position dalle et réciproquement")
	arrets = set()
	mal = []
	for c, p in dalles.items():
		trajet, arret, erreur, _ = glisse(h2, c)
		attendu = tuple(int(v) for v in p.attrs["arret"].split(","))
		if erreur or arret != attendu or p.attrs["trajet"] != trajet:
			mal.append(p.ident)
		arrets.add(arret)
	verifie(not mal, f"trajets des dalles conformes à la glisse ({mal[:4]})")
	verifie(arrets == set(h2.cells_of("o")), "chaque case d'arrêt est l'arrêt d'au moins une dalle")
	rg = glisse_bfs(h2, cases(h2, "from_b1f"))
	r_pied = atteignables(h2, cases(h2, "from_b1f"), chars=h2.praticables - set(FLECHES))
	for cible in ((4, 4), (5, 12)):
		verifie(cible in rg and cible not in r_pied, f"sortie {cible} de la salle des dalles : en glissant seulement")
	inevitable(h2, "from_b1f", "porte_mdp", "scientifique")
	evitable(h2, "from_b1f", "entree_dalles", "sbire_r")
	evitable(h2, "from_b1f", "porte_cellule", "sbire_s")
	couvre(h2, "from_b1f", "porte_mdp", "vers_b3f")
	couvre(h2, "from_b1f", "porte_cellule", "deserteur")
	lx, ly = (int(v) for v in h2.positions["levier"].attrs["depuis"].split(","))
	verifie((lx, ly) in r, "le levier des cellules s'actionne depuis une case atteignable")

	print("mahogany_hideout_b3f")
	h3 = lire(PLANS / "mahogany_hideout_b3f.txt")
	r = communs(h3, (24, 18), "from_b2f", [])
	paire(h2, "vers_b3f", h3, "vers_b2f")
	couvre(h3, "from_b2f", "scene_brace", "brace")
	verifie((17, 10) in r and voisines_atteintes(h3, "raikou", r), "Raikou abordable depuis (17, 10)")
	px, py = (int(v) for v in h3.positions["arret_generateur"].attrs["depuis"].split(","))
	verifie((px, py) in r, "le pupitre d'arrêt s'actionne depuis une case atteignable")

	print("JOH6 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
