#!/usr/bin/env python3
"""Vérifie les grilles de l'arc des Pierres (dossier docs/design/dossier-joh-11-arc-pierres.md).

Grilles : `ruins_of_alph`, `alph_tent`, `alph_gallery`, `alph_chamber` (JOHP1) ; `goeland_deck`,
`cianwood_city`, `tide_cave_1f`, `tide_cave_b1f` (JOHP2) ; `blackthorn_city`, `dragons_den_1f`,
`dragons_den_sanctuary` (JOHP3) ; variantes ARC de `route_36`, `oliville` et `rosalia`. Mêmes règles
que les contrôles du JOH2 au JOH8 : 4 directions, positions `bloque` bloquantes, déclencheurs libres.

Pour chaque carte : taille ; cases praticables connexes ; pourtour fermé hors des warps de bord ;
portes, objets, Dresseurs, panneaux et examens abordables. En plus :
- aucune case surfable dans l'arc (JH : aucune CS exigée, A-6) ;
- Route 36 ↔ Ruines sur 2 cases, barrière sur tout le passage ; base de la Route 36 inchangée ;
- Galerie : Sbire X inévitable, V, W et le Scientifique évitables ; 3 rangées de 4 dalles à franchir ;
  barrière du fond sur tout le passage ;
- Chambre : la scène couvre le seul accès au socle ;
- Grotte B1F : sans gué pas de vanne 2, sans gué b pas de socle, Chef de cale inévitable ;
- Ébènelle : aucune sortie à pied ; barrière sur l'accès à l'Antre ;
- Antre : trois Gardiens abordables sans passer la barrière ; barrière sur tout le passage ;
- Sanctuaire : scène d'Ysolde et scène de l'autel sur tout le passage ;
- Oliville ARC : barrière de la mer sur toute la largeur de l'accès sud.

Usage : python3 tools/art/plan_check_johp.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402
import plan_check_joh2 as base  # noqa: E402
from plan_check_joh2 import atteignables, cases, communs, herbes_evitables, verifie, voisines_atteintes  # noqa: E402
from plan_check_joh3 import vue  # noqa: E402

PLANS = base.PLANS


def evitable(plan, depart, cible, dresseur) -> None:
	r = atteignables(plan, cases(plan, depart), interdites=vue(plan, dresseur))
	verifie(all(c in r for c in cases(plan, cible)), f"{dresseur} évitable ({depart} → {cible})")


def inevitable(plan, depart, cible, dresseur) -> None:
	r = atteignables(plan, cases(plan, depart), interdites=vue(plan, dresseur))
	verifie(not any(c in r for c in cases(plan, cible)), f"{dresseur} inévitable")


def barre(plan, depart, barriere, cible) -> None:
	"""`barriere` couvre tout le passage de `depart` à `cible` (warp, ou position bloquante abordable)."""
	r = atteignables(plan, cases(plan, depart), interdites=set(cases(plan, barriere)))
	touche = voisines_atteintes(plan, cible, r) if plan.positions[cible].bloque or plan.positions[cible].kind == "examen" \
		else any(c in r for c in cases(plan, cible))
	verifie(not touche, f"{barriere} couvre le seul accès à {cible}")


def sans_surf(plan) -> None:
	verifie("w" not in plan.praticables, "pas de case surfable (A-6)")


def ruines() -> None:
	print("ruins_of_alph")
	p = lire(PLANS / "ruins_of_alph.txt")
	communs(p, (36, 30), "from_route_36", ["warp_nord"])
	sans_surf(p)
	verifie(len(p.of_kind("herbes")) == 2, "2 poches d'herbes")
	herbes_evitables(p, "from_route_36", "entree_galerie")
	for d in ("agnes", "remi", "solange"):
		evitable(p, "from_route_36", "entree_galerie", d)
	verifie(all(p.at(*c) == "E" for c in cases(p, "entree_galerie")), "escalier de la Galerie sur E")
	print("route_36 (ARC)")
	r = lire(PLANS / "route_36.txt", "ARC")
	communs(r, (56, 20), "from_route_37", ["warp_nord", "warp_sud", "warp_ruines"])
	barre(r, "from_route_37", "barriere_ruines", "warp_ruines")
	verifie(len(cases(r, "warp_ruines")) == len(cases(p, "warp_nord")) == 2, "raccord Route 36 ↔ Ruines sur 2 cases")
	b = lire(PLANS / "route_36.txt")
	verifie(all(b.at(x, 19) == "T" for x in (40, 41)), "grille de base de la Route 36 inchangée")


def galerie() -> None:
	print("alph_tent")
	communs(lire(PLANS / "alph_tent.txt"), (9, 7), "from_ruins", ["sortie"])
	print("alph_gallery")
	p = lire(PLANS / "alph_gallery.txt")
	communs(p, (24, 18), "from_ruins", [])
	inevitable(p, "from_ruins", "escalier_bas", "sbire_x")
	for d in ("sbire_v", "sbire_w", "scientifique"):
		evitable(p, "from_ruins", "escalier_bas", d)
	for r in ("dalles_r1", "dalles_r2", "dalles_r3"):
		verifie(len(cases(p, r)) == 4 and all(p.at(*c) == "t" for c in cases(p, r)), f"{r} : 4 dalles")
		barre(p, "from_ruins", r, "escalier_bas")
		bonne = tuple(int(v) for v in p.positions[r].attrs["bonne"].split(","))
		verifie(bonne in cases(p, r), f"{r} : la bonne dalle est dans la rangée")
	barre(p, "from_ruins", "barriere_fond", "escalier_bas")
	print("alph_chamber")
	c = lire(PLANS / "alph_chamber.txt")
	communs(c, (14, 12), "from_gallery", [])
	barre(c, "from_gallery", "scene_faux", "socle")


def irisia() -> None:
	print("goeland_deck")
	d = lire(PLANS / "goeland_deck.txt")
	communs(d, (16, 8), "from_quai", [])
	verifie(voisines_atteintes(d, "goulven", atteignables(d, cases(d, "from_quai"), interdites=vue(d, "yvon"))),
		"Yvon évitable (Goulven abordable hors de sa vue)")
	print("cianwood_city")
	p = lire(PLANS / "cianwood_city.txt")
	communs(p, (32, 28), "from_goeland", [])
	sans_surf(p)
	verifie(len(p.of_kind("herbes")) == 2, "2 poches d'herbes")
	herbes_evitables(p, "from_goeland", "entree_grotte")
	for t in ("ronan", "tanguy", "maelle"):
		evitable(p, "from_goeland", "entree_grotte", t)
	print("tide_cave_1f")
	a = lire(PLANS / "tide_cave_1f.txt")
	communs(a, (26, 20), "from_city", ["sortie"])
	sans_surf(a)
	inevitable(a, "from_city", "echelle_bas", "sbire_z")
	evitable(a, "from_city", "echelle_bas", "sbire_y")
	print("tide_cave_b1f")
	b = lire(PLANS / "tide_cave_b1f.txt")
	communs(b, (20, 16), "from_1f", [])
	sans_surf(b)
	depart = cases(b, "from_1f")
	r = atteignables(b, depart, chars=b.praticables - {"a", "b"})
	verifie(voisines_atteintes(b, "vanne_1", r), "vanne 1 abordable sans gué")
	verifie(not voisines_atteintes(b, "vanne_2", r), "vanne 2 hors d'atteinte sans le gué a")
	r = atteignables(b, depart, chars=b.praticables - {"b"})
	verifie(voisines_atteintes(b, "vanne_2", r), "vanne 2 abordable par le gué a")
	verifie(not voisines_atteintes(b, "socle", r), "socle hors d'atteinte sans le gué b")
	inevitable(b, "from_1f", "scene_socle", "chef_cale")
	evitable(b, "from_1f", "scene_socle", "sbire_aa")
	evitable(b, "from_1f", "scene_socle", "scientifique")
	barre(b, "from_1f", "scene_socle", "socle")


def antre() -> None:
	print("blackthorn_city")
	p = lire(PLANS / "blackthorn_city.txt")
	communs(p, (32, 30), "from_dragon", [])
	sans_surf(p)
	verifie(len(p.of_kind("herbes")) == 2, "2 poches d'herbes")
	herbes_evitables(p, "from_dragon", "entree_antre")
	barre(p, "from_dragon", "barriere_antre", "entree_antre")
	for t in ("nolwenn", "malo", "herve"):
		evitable(p, "from_dragon", "entree_antre", t)
	print("dragons_den_1f")
	a = lire(PLANS / "dragons_den_1f.txt")
	communs(a, (28, 24), "from_city", [])
	sans_surf(a)
	r = atteignables(a, cases(a, "from_city"), interdites=set(cases(a, "barriere_sanctuaire")))
	for g in ("gardienne_eau", "gardien_pierre", "gardien_ciel"):
		verifie(voisines_atteintes(a, g, r), f"{g} abordable avant la barrière")
	barre(a, "from_city", "barriere_sanctuaire", "escalier_bas")
	for d in ("sbire_ab", "sbire_ac"):
		evitable(a, "from_city", "escalier_bas", d)
	print("dragons_den_sanctuary")
	s = lire(PLANS / "dragons_den_sanctuary.txt")
	communs(s, (22, 18), "from_1f", [])
	barre(s, "from_1f", "scene_ysolde", "autel")
	barre(s, "from_1f", "scene_autel", "autel")
	r = atteignables(s, cases(s, "from_1f"), interdites=set(cases(s, "scene_ysolde")))
	verifie(voisines_atteintes(s, "aieule", r), "l'Aïeule est abordable avant Ysolde")


def retouches() -> None:
	print("oliville (ARC)")
	p = lire(PLANS / "oliville.txt", "ARC")
	r = atteignables(p, cases(p, "from_route_39") if "from_route_39" in p.positions else cases(p, "porte_centre"))
	verifie(voisines_atteintes(p, "goulven", r), "Goulven abordable depuis le quai")
	mer = p.praticables | {"w"}
	r = atteignables(p, [(30, 35)], chars=mer, interdites=set(cases(p, "barriere_mer_sud")))
	verifie(not any(c in r for c in cases(p, "warp_sud_mer")), "barriere_mer_sud couvre l'accès à la Route 40")
	print("rosalia (ARC)")
	q = lire(PLANS / "rosalia.txt", "ARC")
	r = atteignables(q, cases(q, "from_route_38"))
	verifie(voisines_atteintes(q, "corentin", r), "Corentin abordable")
	verifie(all(c in r for c in cases(q, "from_dragon")), "from_dragon atteignable")


def main() -> int:
	ruines()
	galerie()
	irisia()
	antre()
	retouches()
	print("Arc des Pierres : " + ("tout est bon" if not base.echecs else f"{len(base.echecs)} échec(s)"))
	return 1 if base.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
