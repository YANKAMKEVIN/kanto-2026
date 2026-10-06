#!/usr/bin/env python3
"""Série 08 — Route 1 (lumière neutre).

Cible : docs/design/reference/route-1-vue-generale-v1.png (validée par Kevin). Presque tout est
repris de Bourg Palette et de la Route 22 ; ne restent que les éléments propres à la Route 1.
Références : recadrages REF_R1_* de la vue générale (build/art/, non versionné).
Usage : tools/art/serie08.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import generer  # noqa: E402

SERIE = [
	("WORLD_TREE_AUTOMNE_01", "REF_R1_AUTOMNE", 3,
		"arbre repère de la Route 1 : feuillu rond au feuillage ORANGE d'automne lumineux (orange vif à "
		"rouille, quelques touches jaunes), en grandes masses arrondies, tronc brun ; le seul de la route."),
	("WORLD_PROP_SOUCHE_01", "REF_R1_SOUCHE", 1.2,
		"vieille souche d'arbre coupée, large, aux racines noueuses bien visibles qui s'étalent au sol, un "
		"peu de mousse et un petit champignon ; un creux entre deux racines (une cachette discrète)."),
	("WORLD_RELIEF_REBORD_01", "REF_R1_REBORD", 1,
		"tronçon d'un petit rebord de terrain franchissable seulement vers le bas : vu de dessus et de face, "
		"le dessus est une bande d'herbe et la face avant une marche de terre brune d'environ une demi-case "
		"de haut, avec quelques cailloux et racines ; les bords gauche et droit sont coupés net pour se "
		"raccorder bout à bout (1 case de large)."),
]

if __name__ == "__main__":
	choix = set(sys.argv[1:])
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(generer, [e for e in SERIE if not choix or e[0] in choix]):
			print(ligne, flush=True)
