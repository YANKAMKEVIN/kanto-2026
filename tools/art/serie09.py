#!/usr/bin/env python3
"""Série 09 — personnages peints de Bourg Palette (DA.4, plan d'intégration du monde peint).

Planches de marche 4 × 4 au format de la série 02 (ancre PERSO_P2_PEINT_r1, le héros validé).
Repris tels quels du prototype : Mme Aoki = PNJ_VIEILLE_DAME, Haru = PNJ_PECHEUR,
Maya = PNJ_CHERCHEUSE, chercheur = PNJ_CHERCHEUR (série 06B). Nouveaux ici : Maman, Chen,
Léo et les trois starters (Pokémon du monde, au labo). Tenues = valeurs par défaut (règle 4).
Usage : tools/art/serie09.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import ART, PROMPTS  # noqa: E402
from serie06b import _lancer, _prompt_habitant  # noqa: E402

HABITANTS = [
	("PNJ_MAMAN", "la mère du héros, femme d'une quarantaine d'années chaleureuse et douce : cheveux "
		"châtains mi-longs attachés en queue basse, pull rose pâle, tablier vert clair noué à la taille, "
		"jupe longue beige, chaussons bruns."),
	("PNJ_CHEN", "le Professeur Chen, homme d'une soixantaine d'années bienveillant et énergique : "
		"cheveux gris clair coiffés en arrière, blouse blanche de laboratoire ouverte, chemise bordeaux, "
		"pantalon brun clair, chaussures brunes."),
	("PNJ_LEO", "Léo, un petit garçon d'environ 8 ans, plus petit que les autres personnages : cheveux "
		"blonds en bataille, casquette bleu ciel portée à l'envers, t-shirt jaune à rayures, short bleu "
		"marine, baskets rouges. Différent de l'enfant de Jadielle (cheveux noirs, t-shirt vert)."),
]

STARTERS = [
	("POKE_BULBIZARRE", "Bulbizarre, le starter Plante de Pokémon Rouge/Bleu, fidèle à son design "
		"officiel : quadrupède turquoise à taches vert foncé, gros bulbe vert sur le dos, yeux rouges. "
		"Allure calme et curieuse.", "marche à quatre pattes en 4 images, petits pas posés"),
	("POKE_SALAMECHE", "Salamèche, le starter Feu de Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"petit lézard orange qui marche debout, ventre crème, flamme orange au bout de la queue. Allure "
		"enthousiaste.", "marche debout en 4 images, queue à flamme qui balance"),
	("POKE_CARAPUCE", "Carapuce, le starter Eau de Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"petite tortue bleu clair qui marche debout, carapace brune au bord crème, queue enroulée. Allure "
		"énergique et joueuse.", "marche debout en 4 images, petits pas dynamiques"),
]


def _prompt_starter(identifiant: str, description: str, mouvement: str) -> str:
	modele = (PROMPTS / "POKE_ROUCOOL_NE_r1.txt").read_text()
	modele = modele.replace("POKE_ROUCOOL — planche d'animation du Pokémon de la Dresseuse.",
		f"{identifiant} — planche d'animation d'un Pokémon du monde (laboratoire du Professeur Chen).")
	debut, reste = modele.split("POKÉMON (identique dans toutes les images) : ", 1)
	fin = reste.split("\n", 1)[1]
	fin = fin.replace("sautillement d'oiseau au sol en 4 images (petits bonds, ailes repliées qui "
		"frémissent légèrement)", mouvement)
	fin = fin.replace("on voit un peu le dos de l'oiseau", "on voit un peu le dessus du Pokémon")
	fin = fin.replace("les pattes posées", "les pieds posés")
	return debut + f"POKÉMON (identique dans toutes les images) : {description}\n" + fin


def _taches():
	heros = [str(ART / "PERSO_P2_PEINT_r1.png")]
	for identifiant, description in HABITANTS:
		yield identifiant, lambda i=identifiant, d=description: _lancer(i, _prompt_habitant(i, d), heros)
	# Ancre de forme proche seulement (leçon du Nidoran ♂, série 05) : le Rattata pour le
	# quadrupède, aucune ancre de Pokémon pour les deux bipèdes.
	for identifiant, description, mouvement in STARTERS:
		ancres = heros + ([str(ART / "POKE_RATTATA_P2_r1.png")] if identifiant == "POKE_BULBIZARRE" else [])
		yield identifiant, lambda i=identifiant, d=description, m=mouvement, a=ancres: _lancer(
			i, _prompt_starter(i, d, m), a)


if __name__ == "__main__":
	choix = set(sys.argv[1:])
	taches = [t for i, t in _taches() if not choix or i in choix]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(lambda t: t(), taches):
			print(ligne, flush=True)
