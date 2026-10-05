#!/usr/bin/env python3
"""Série 06B — habillage de Bourg Palette (lumière neutre) : densité et vie.

Remarque de Kevin (2026-10-05) : « la ville est un peu simple et vide ». Objets d'habillage
(même gabarit que la série 06) ; aucune faune non-Pokémon (Kevin, 2026-10-06), planches de fleurs sauvages et côtières à semer dans l'herbe,
et habitants (planches de marche au format de la série 02, ancre PERSO_P2_PEINT_r1).
Usage : tools/art/serie06b.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import ADN, ART, LUMIERE_NE, PROMPTS, RACINE, STYLE, generer  # noqa: E402

OBJETS = [
	("WORLD_PROP_CLOTURE_PIQUETS_V_01", None, 0.5,
		"tronçon de clôture à piquets blancs vu de dessus, orienté du HAUT vers le BAS de l'image "
		"(il longe le côté d'un jardin) : on voit surtout le sommet pointu des piquets alignés en colonne et "
		"un peu leur face avant, traverses blanches ; long de 3 cases, extrémités coupées net pour se raccorder."),
	("WORLD_TREE_C_01", "REF_BP_SENTIER_SECRET", 3,
		"arbre feuillu de lisière au houppier bien rond, feuillage vert clair et lumineux en grandes masses, "
		"tronc brun court ; différent des arbres joints (plus clair, plus rond)."),
	("WORLD_TREE_D_01", None, 2.6,
		"bouleau : tronc fin blanc tacheté de noir, légèrement penché, feuillage léger vert-jaune en petites "
		"masses aérées."),
	("WORLD_TREE_E_01", None, 3.6,
		"grand chêne sombre et touffu de forêt, feuillage vert sapin profond en grandes masses, tronc épais."),
	("WORLD_PROP_HORTENSIAS_01", "REF_BP_MAISON_JOUEUR", 1.6,
		"buisson d'hortensias en fleurs, grosses boules de fleurs bleues et mauves sur un feuillage vert franc."),
	("WORLD_PROP_JARDINIERE_01", "REF_BP_MAISON_RIVAL", 3,
		"longue jardinière basse en pierre claire au pied d'une façade, débordant de fleurs variées "
		"(géraniums rouges, marguerites, lavande)."),
	("WORLD_PROP_MANGEOIRE_01", "REF_BP_ARBRE_ANCIEN", 1,
		"mangeoire à oiseaux en bois sur un poteau, petit toit, graines visibles."),
	("WORLD_PROP_EPOUVANTAIL_01", "REF_BP_CHAMP", 1.2,
		"épouvantail sympathique : chapeau de paille, chemise à carreaux rouge, bras écartés sur une croix de bois."),
	("WORLD_PROP_BARQUE_01", "REF_BP_PONTON", 2.6,
		"petite barque en bois bleue et blanche tirée sur le sable, vue de dessus et de face, deux rames posées."),
	("WORLD_PROP_CASIERS_PECHE_01", "REF_BP_PONTON", 1.6,
		"casiers de pêche en bois empilés, un filet de pêche plié, un seau et une canne à pêche."),
	("WORLD_PROP_HERBES_DUNE_01", "REF_BP_COTE", 1,
		"touffe d'oyats : herbes de dune hautes, fines et souples, vert pâle et beige."),
	("WORLD_PROP_MATERIEL_LABO_01", "REF_BP_LABO", 2,
		"matériel scientifique d'extérieur : deux cuves bleues, une petite station météo blanche sur trépied "
		"avec anémomètre, une caisse de matériel."),
	("WORLD_PROP_RATELIER_VELOS_01", "REF_BP_LABO", 2,
		"râtelier métallique avec deux vélos de ville garés côte à côte (un vert, un blanc), vus de profil "
		"légèrement de dessus."),
	("WORLD_PROP_BROUETTE_01", "REF_BP_JARDINS", 1.4,
		"brouette en bois remplie de terre et de jeunes plants, une pelle et un râteau appuyés contre elle."),
	("WORLD_PROP_TAS_BOIS_01", "REF_BP_MAISON_RIVAL", 1.8,
		"tas de bûches proprement empilées contre un mur, sous un petit auvent de planches, une hache plantée "
		"dans un billot à côté."),
	("WORLD_PROP_ARROSOIR_SEAU_01", "REF_BP_JARDINS", 0.9,
		"arrosoir en zinc vert et petit seau en métal posés côte à côte au bord d'un jardin."),
	("WORLD_PROP_PIERRES_01", None, 1,
		"petit groupe de trois pierres grises arrondies à demi enfoncées dans l'herbe, un peu de mousse."),
]

PLANCHES = [
	("WORLD_GROUND_FLEURS_SAUVAGES_01",
		"PLANCHE de 8 petites décalcomanies de sol à semer dans l'herbe, vues strictement de DESSUS, à plat : "
		"grille invisible de 4 colonnes × 2 lignes dans une image 1024 × 512 (cellules de 256 × 256), un élément "
		"centré par cellule, sans cadre ni séparation. Ligne 1 : touffe de pâquerettes blanches ; touffe de "
		"boutons d'or jaunes ; touffe de fleurs roses ; touffe de petites fleurs violettes. Ligne 2 : touffe de "
		"trèfles ; touffe d'herbe plus foncée ; trois petits cailloux ; quelques pissenlits. Chaque élément fait "
		"environ 140 px, posé sur RIEN : fond avec une vraie transparence (canal alpha), aucun sol, aucune "
		"herbe autour, aucune ombre portée."),
	("WORLD_GROUND_FLEURS_COTIERES_01",
		"PLANCHE de 8 petites décalcomanies de végétation côtière vues strictement de DESSUS, à plat : grille "
		"invisible de 4 colonnes × 2 lignes dans une image 1024 × 512 (cellules de 256 × 256), un élément centré "
		"par cellule, sans cadre ni séparation. Ligne 1 : touffe d'armérie rose ; touffe de chardons bleus des "
		"dunes ; coussin de plantes grasses ; touffe de fleurs jaunes de bord de mer. Ligne 2 : herbe sèche "
		"blonde ; touffe d'herbe couchée par le vent ; deux galets clairs ; coquillage et bois flotté. Chaque "
		"élément fait environ 140 px, posé sur RIEN : fond avec une vraie transparence (canal alpha), aucun sol, "
		"aucune ombre portée."),
]

## Habitants : (identifiant, description du personnage).
HABITANTS = [
	("PNJ_CHERCHEUR", "un chercheur du laboratoire du Professeur Chen, homme d'une trentaine d'années : "
		"cheveux noirs courts, lunettes rondes, blouse blanche ouverte sur un pull vert, pantalon gris, "
		"chaussures brunes, porte-bloc sous le bras."),
	("PNJ_CHERCHEUSE", "une chercheuse du laboratoire, femme d'une vingtaine d'années : cheveux châtains "
		"attachés en queue de cheval, blouse blanche sur un t-shirt bleu ciel, pantalon beige, baskets "
		"blanches, gants de jardinage verts."),
	("PNJ_PECHEUR", "un pêcheur du village, homme d'une cinquantaine d'années à la barbe grise : bob beige, "
		"gilet de pêche kaki à poches, chemise bleue, pantalon retroussé, bottes vertes, canne à pêche."),
	("PNJ_VIEILLE_DAME", "une vieille dame souriante du village : cheveux blancs en chignon, gilet mauve, "
		"robe longue gris-bleu, petit sac de graines pour les oiseaux à la main, marche lentement."),
	("PNJ_JARDINIERE", "une jardinière du village, femme d'une quarantaine d'années : chapeau de paille, "
		"chemise à carreaux verte, salopette en jean, bottes de jardin jaunes, petit arrosoir."),
]


def _prompt_planche(identifiant: str, description: str) -> str:
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages jointes : "
		"WORLD_BLDG_MAISON_A_01_NE_r1 et WORLD_TREE_A_01_NE_r1 = ancres de style (rendu peint, contour "
		f"coloré, finesse, lumière neutre).\n\n{ADN}\n{LUMIERE_NE}\n\nEXCEPTION à la règle « Isolement » : "
		f"plusieurs éléments séparés sur une même planche.\n{description}\nInterdit : texte, chiffres, cadres, "
		"personnage, Pokémon, ombre portée.\n")


def _prompt_habitant(identifiant: str, description: str) -> str:
	modele = (PROMPTS / "PNJ_MARCHAND_NE_r1.txt").read_text()
	debut, reste = modele.split("PERSONNAGE (identique dans toutes les images) : ", 1)
	fin = reste.split("\n", 1)[1]
	return (debut.replace("PNJ_MARCHAND", identifiant)
		+ f"PERSONNAGE (identique dans toutes les images) : {description}\n" + fin)


def _lancer(identifiant: str, texte: str, jointes: list[str]) -> str:
	nom = f"{identifiant}_NE_r1"
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(texte)
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier), *jointes],
		cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


def _taches():
	for entree in OBJETS:
		yield entree[0], lambda e=entree: generer(e)
	style = [str(ART / s) for s in STYLE]
	for identifiant, description in PLANCHES:
		yield identifiant, lambda i=identifiant, d=description: _lancer(i, _prompt_planche(i, d), style)
	heros = [str(ART / "PERSO_P2_PEINT_r1.png")]
	for identifiant, description in HABITANTS:
		yield identifiant, lambda i=identifiant, d=description: _lancer(i, _prompt_habitant(i, d), heros)


if __name__ == "__main__":
	choix = set(sys.argv[1:])
	taches = [t for i, t in _taches() if not choix or i in choix]
	with ThreadPoolExecutor(max_workers=2) as pool:
		for ligne in pool.map(lambda t: t(), taches):
			print(ligne, flush=True)
