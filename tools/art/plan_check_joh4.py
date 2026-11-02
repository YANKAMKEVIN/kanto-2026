#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH4 (Chapitre Johto, dossier docs/design/dossier-joh-05-ecorcia.md).

Grilles : `tools/plans/route_34.txt` (24 × 48), `ilex_forest.txt` (48 × 48), `azalea_town.txt`
(44 × 36), `slowpoke_well_b1f.txt` et `slowpoke_well_b2f.txt` (30 × 24). Mêmes règles que les
contrôles du JOH2 et du JOH3 (`plan_check_joh2.py`, `plan_check_joh3.py`, dont on reprend les
fonctions) : 4 directions, positions `bloque` bloquantes, déclencheurs libres ; l'étang de la
Route 34 et l'eau du puits (w) se traversent en Surf (JH-36).

Pour chaque carte : taille ; toutes les cases praticables connexes ; aucune ouverture sur le
pourtour hors des warps de bord ; portes, échelles, objets, Dresseurs, panneaux et examens
abordables. Raccords : Doublonville sud ↔ Route 34 nord, Route 34 sud ↔ Bois nord, Bois sud ↔
Écorcia nord (3 cases de chaque côté).
Route 34 : 3 poches d'herbes évitables ; Félix inévitable (sa case de vue est le seul passage de la
clôture), Sophie et Bruno évitables. Bois : 4 poches, H1 et H3 obligatoires (sans herbes, la sortie
sud est inatteignable), H2 et H4 évitables ; Tom et Céline évitables ; l'autel est dans la
clairière. Écorcia : la barrière du Sbire couvre le seul accès à la descente du puits. Puits B1F :
le Sbire E est inévitable (le goulet), F et G évitables. Puits B2F : la scène de Brace couvre le
seul accès à l'alcôve ; la Corde Sortie se prend sans passer par Brace.

Usage : python3 tools/art/plan_check_joh4.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, cases, communs, herbes_evitables, verifie  # noqa: E402
from plan_check_joh3 import largeur, vue  # noqa: E402

PLANS = base.PLANS


def evitable(plan, depart: str, cible: str, dresseur: str) -> None:
	r = atteignables(plan, cases(plan, depart), interdites=vue(plan, dresseur))
	verifie(all(c in r for c in cases(plan, cible)), f"{dresseur} évitable ({depart} → {cible} hors de sa vue)")


def inevitable(plan, depart: str, cible: str, dresseur: str) -> None:
	r = atteignables(plan, cases(plan, depart), interdites=vue(plan, dresseur))
	verifie(not any(c in r for c in cases(plan, cible)), f"{dresseur} inévitable : sa vue est le seul passage")


def herbes_obligatoires(plan, de: str, vers: str) -> None:
	sans = plan.praticables - {"h"}
	r = atteignables(plan, cases(plan, de), chars=sans)
	verifie(not any(c in r for c in cases(plan, vers)), f"{de} → {vers} impossible sans traverser d'herbes")


def main() -> int:
	goldenrod = lire(PLANS / "doublonville.txt")

	print("route_34")
	r34 = lire(PLANS / "route_34.txt")
	communs(r34, (24, 48), "from_goldenrod", ["warp_nord", "warp_sud"])
	largeur(goldenrod, "warp_sud", r34, "warp_nord")
	verifie(len(r34.of_kind("herbes")) == 3, "3 poches d'herbes hautes")
	herbes_evitables(r34, "from_goldenrod", "warp_sud")
	inevitable(r34, "from_goldenrod", "warp_sud", "felix")
	evitable(r34, "from_goldenrod", "warp_sud", "sophie")
	evitable(r34, "from_goldenrod", "warp_sud", "bruno")
	px, py = cases(r34, "pecheur")[0]
	verifie(r34.at(px - 1, py) == "w", "le Pêcheur regarde l'étang")

	print("ilex_forest")
	bois = lire(PLANS / "ilex_forest.txt")
	communs(bois, (48, 48), "from_route_34", ["warp_nord", "warp_sud"])
	largeur(r34, "warp_sud", bois, "warp_nord")
	verifie(len(bois.of_kind("herbes")) == 4, "4 poches d'herbes hautes")
	herbes_obligatoires(bois, "from_route_34", "warp_sud")
	for h in ("herbes_h2", "herbes_h4"):
		# la poche h reste évitable : la sortie est atteignable sans aucune de ses cases
		r = atteignables(bois, cases(bois, "from_route_34"), interdites=_poche(bois, h))
		verifie(all(c in r for c in cases(bois, "warp_sud")), f"{h} évitable")
	evitable(bois, "from_route_34", "warp_sud", "tom")
	evitable(bois, "from_route_34", "warp_sud", "celine")
	cl = set(cases(bois, "clairiere_autel"))
	verifie(all(c in cl for c in cases(bois, "autel")), "l'autel est dans la clairière")
	verifie(all(bois.at(x, y) == "C" for x, y in cl if bois.at(x, y) not in "=Ay"), "clairière en herbe rase (C)")

	print("azalea_town")
	az = lire(PLANS / "azalea_town.txt")
	communs(az, (44, 36), "from_ilex", ["warp_nord"])
	largeur(bois, "warp_sud", az, "warp_nord")
	r = atteignables(az, cases(az, "from_ilex"), interdites=set(cases(az, "barriere_puits")))
	verifie(not any(c in r for c in cases(az, "puits")), "barriere_puits couvre le seul accès à la descente")
	verifie(az.at(*cases(az, "puits")[0]) == "E", "descente du puits sur une case E")

	print("slowpoke_well_b1f")
	b1 = lire(PLANS / "slowpoke_well_b1f.txt")
	communs(b1, (30, 24), "from_azalea", [])
	inevitable(b1, "from_azalea", "echelle_b2f", "sbire_e")
	evitable(b1, "from_azalea", "echelle_b2f", "sbire_f")
	evitable(b1, "from_azalea", "echelle_b2f", "sbire_g")
	verifie(all(b1.at(x, y) == "g" for x, y in cases(b1, "gravats_g2")), "gravats G2 devant l'échelle")

	print("slowpoke_well_b2f")
	b2 = lire(PLANS / "slowpoke_well_b2f.txt")
	communs(b2, (30, 24), "from_b1f", [])
	r = atteignables(b2, cases(b2, "from_b1f"), interdites=set(cases(b2, "scene_brace")))
	verifie(not base.voisines_atteintes(b2, "brace", r), "scene_brace couvre le seul accès à Brace")
	verifie(base.voisines_atteintes(b2, "well_b2f_item_1", r), "la Corde Sortie se prend sans passer par Brace")
	verifie(all(b2.at(x, y) == "R" for x, y in ((26, 3), (27, 3))), "caisses marquées derrière Brace")

	print("JOH4 : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


def _poche(plan, h: str) -> set:
	"""Toutes les cases d'herbes de la poche nommée (composante connexe de h)."""
	depart = cases(plan, h)
	return atteignables(plan, depart, chars={"h"})


if __name__ == "__main__":
	sys.exit(main())
