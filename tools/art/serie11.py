#!/usr/bin/env python3
"""Série 11 — Forêt de Jade (jalon 9, lumière neutre). Liste exacte : docs/tech/jalon-09.md §2.8.

Méthode du J8 T2 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation de la vue
validée, `docs/design/reference/foret-jade-vue-generale-v1.png`, essai r2, sans effet répétitif).
La forêt reprend presque tout de la Route 2 (forêt serrée, sous-bois, hautes herbes jaune-vert,
façade du poste, souche, Poké Ball au sol, Randonneuse, Jeune Dresseur, Roucool) ; ne sont
générés que (16 images) :
  - 4 décors : WORLD_PROP_TRONC_INCLINE_01 (repère sud), WORLD_PROP_GRANDE_SOUCHE_01 (repère
    central), WORLD_PROP_RACINES_01 (amas de racines d'O4), WORLD_PROP_SAC_RANDO_01 (sac de P2) ;
  - 1 planche : WORLD_GROUND_SOUS_BOIS_01 (conditionnel du J8, promu : 8 décalcomanies) ;
  - 1 pièce : INT_POSTE_FORET_COQUE (enveloppe vide des deux postes, 10 × 8) ;
  - 3 personnages × (marche + attente) : PNJ_GARDE, PNJ_SCOUT, PNJ_NATURALISTE ;
  - 4 Pokémon d'ambiance immobiles, une planche chacun (attente + réaction, face et profil) :
    POKE_CHENIPAN_FIXE, POKE_ASPICOT_FIXE, POKE_CHRYSACIER_FIXE, POKE_COCONFORT_FIXE.
CONDITIONNELS (jamais lancés sans leur nom ; seulement si les captures du T19 / T21 le demandent) :
WORLD_TREE_FORET_PLANCHE_C (4 arbres de forêt plus sombres), WORLD_DECAL_RAIS_LUMIERE_01 (rais
peints sur fond noir, mode additif).

Références : recadrages REF_FJ_* de la vue validée (`--refs`, boîtes ci-dessous, agrandies × 3) ;
REF_FJ_TRONC est retourné (le jeu penche le tronc à l'opposé du sentier). Ancres : assets validés
(souche de la série 08, arbre A, façade du poste, coque du Centre, héros, Rattata).
Sources et sorties dans $ART (défaut : build/art de cette copie ; sur une autre copie que le
checkout principal, ART=/Users/kevinyankam/dev/kanto-2026/build/art, où sont les ancres).

Usage :
  tools/art/serie11.py --refs                 recadre les REF_FJ_* dans $ART (sans Codex)
  tools/art/serie11.py --planche [sortie.png] planche de contrôle du kit (sans Codex ;
                                              défaut build/art/FJ_KIT_v1.png)
  tools/art/serie11.py --manifeste            ajoute les entrées de la série 11 en fin de
                                              tools/art/manifeste.json (idempotent ; au T17,
                                              une fois les images validées)
  tools/art/serie11.py [IDENTIFIANT ...]      génère avec Codex (sans argument : la série,
                                              sans les conditionnels ; --refs fait d'abord)
"""
from __future__ import annotations

import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE  # noqa: E402
from serie10 import (CASE_PLANCHE, _Planche, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _miroir, _teinter)

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
VUE = RACINE / "docs/design/reference/foret-jade-vue-generale-v1.png"
ATTENTES = ICI / "attente" / "prompts"

## Recadrages de la vue validée (1024 × 1536, ≈ 17,7 px par case en largeur), en pixels de la vue.
REFS = {
	"REF_FJ_POSTE": (420, 80, 590, 190),
	"REF_FJ_TRONC": (325, 1160, 585, 1345),
	"REF_FJ_SOUCHE": (470, 405, 665, 540),
	"REF_FJ_RACINES": (20, 640, 175, 775),
	"REF_FJ_SAC": (812, 632, 868, 684),
	"REF_FJ_SCOUT": (612, 1250, 690, 1340),
	"REF_FJ_NATURALISTE": (405, 468, 466, 560),
	"REF_FJ_CHENIPAN": (566, 1282, 610, 1330),
	"REF_FJ_COCONFORT": (356, 496, 392, 540),
	"REF_FJ_RAI": (850, 0, 1024, 190),
	"REF_FJ_SOUS_BOIS": (300, 1235, 490, 1370),
	"REF_FJ_FORET": (0, 1340, 520, 1536),
	# Écarts de la vue volontairement non reproduits (dossier 10, « Vue générale peinte v1 »).
	"REF_FJ_SECONDE_SOUCHE": (465, 860, 560, 935),
	"REF_FJ_HAIES": (190, 595, 560, 735),
	"REF_FJ_CHICOT": (318, 450, 402, 575),
}
## Références retournées : le tronc de la vue monte vers le sentier ; dans le jeu, il s'en écarte.
MIROIRS = {"REF_FJ_TRONC"}
AGRANDIR = 3

STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"

## (identifiant, référence, largeur en cases, description, ancres supplémentaires).
SERIE = [
	("WORLD_PROP_TRONC_INCLINE_01", "REF_FJ_TRONC", 4,
		"un grand tronc d'arbre mort INCLINÉ, repère à l'entrée d'une forêt : le PIED (base cassée, "
		"quelques racines courtes) est posé au sol en BAS À DROITE de l'image ; le tronc monte en "
		"diagonale vers le HAUT À GAUCHE, à environ 35 degrés, et se termine par une cassure nette en "
		"biseau, sans branches feuillues. Écorce brun-gris profondément striée, dessus couvert de MOUSSE "
		"vert vif par plaques, deux ou trois champignons plats sur le flanc, une petite fougère au pied. "
		"Long d'environ 4 cases, épais d'environ 0,6 case. Pas d'arbre vivant, pas de feuillage, pas de "
		"sol, pas de pierre.", []),
	("WORLD_PROP_GRANDE_SOUCHE_01", "REF_FJ_SOUCHE", 3.4,
		"une ÉNORME souche d'arbre ancien, repère central d'une forêt : tronc coupé très large (environ "
		"2,5 cases de diamètre), CREUX au sommet (on voit l'intérieur sombre du cylindre par le haut), "
		"bord supérieur irrégulier et ébréché, écorce brune épaisse couverte de mousse vert vif par "
		"plaques, GROSSES RACINES qui s'étalent tout autour au ras du sol comme des doigts. Plus large "
		"que haute (environ 2,6 cases de haut). UNE SEULE souche, pas une souche coupée à plat.", []),
	("WORLD_PROP_RACINES_01", "REF_FJ_RACINES", 1.6,
		"un amas de grosses racines noueuses et moussues qui sortent de terre et s'entrelacent en "
		"boucles et en arches basses (jusqu'à environ 1 case de haut), comme au pied d'un très vieil "
		"arbre, avec un creux sombre entre deux racines où un objet pourrait se coincer. Plus haut que "
		"large (environ 2 cases de haut). Pas de tronc au-dessus, pas de feuillage, pas d'objet.", []),
	("WORLD_PROP_SAC_RANDO_01", "REF_FJ_SAC", 0.7,
		"un sac à dos de randonnée posé DEBOUT au sol, kaki et brun, rabat sanglé, gourde métallique "
		"accrochée sur le côté, tapis de sol roulé attaché dessous ; seul, sans personnage.", []),
]

PLANCHE_SOUS_BOIS = ("WORLD_GROUND_SOUS_BOIS_01",
	"PLANCHE de 8 petites décalcomanies de sous-bois à semer sur une herbe ombragée de forêt, vues "
	"strictement de DESSUS, à plat : grille invisible de 4 colonnes × 2 lignes dans une image 1024 × 512 "
	"(cellules de 256 × 256), un élément centré par cellule, sans cadre ni séparation. Ligne 1 : touffe de "
	"fougères vert sombre ; jeune fougère plus claire ; tapis de mousse ; feuilles mortes brunes éparses. "
	"Ligne 2 : trèfle sombre ; petites racines qui affleurent ; brindilles et aiguilles ; deux petits "
	"champignons brun-rouge discrets. Chaque élément fait environ 140 px, posé sur RIEN : fond avec "
	"une vraie transparence (canal alpha), aucun sol, aucune ombre portée. Couleurs sourdes : verts "
	"profonds, bleu-vert dans les ombres, terre brun doux.")

## Pièce : (identifiant, largeur, profondeur, description) ; ancres de la série 07 + la façade.
COQUE = ("INT_POSTE_FORET_COQUE", 10, 8,
	"l'unique pièce d'un petit poste de garde à l'orée de la Forêt de Jade (bâtiment-porte que l'on "
	"traverse du sud au nord). Mêmes matériaux que la façade jointe WORLD_BLDG_POSTE_FORET_01 : mur du "
	"fond en PIERRE claire appareillée gris-beige, soubassement et poteaux de bois brun, une poutre de "
	"bois en haut ; sol en larges planches de bois clair un peu usées. Au MILIEU du mur du fond, une "
	"OUVERTURE de passage de 2 cases de large, sans porte, sous un linteau de bois, par laquelle on voit "
	"seulement un seuil de terre et une lumière verte claire (l'extérieur, sans détail). De part et "
	"d'autre de l'ouverture : une petite fenêtre à petits carreaux et une applique éteinte. L'ouverture "
	"du bas (2 cases, centrée) est l'entrée, avec un paillasson brun. Sobre, propre, un peu de mousse "
	"au pied du mur du fond.")
STYLE_PIECE = ["INT_CENTRE_COQUE_NE_r1.png", "INT_CENTRE_BANQUETTE_NE_r1.png",
	"WORLD_BLDG_POSTE_FORET_01_NE_r1.png"]

## Personnages : (identifiant, référence ou None, description). Tenues = défauts (règle 4).
PERSONNAGES = [
	("PNJ_GARDE", None,
		"le garde d'un poste à l'orée de la Forêt de Jade, homme d'une trentaine d'années calme et "
		"serviable : casquette à visière bleu marine avec un petit insigne doré rond (sans texte), veste "
		"d'uniforme bleu marine courte et boutonnée, chemise bleu clair, pantalon bleu marine, ceinture "
		"brune avec un talkie-walkie gris, chaussures brun foncé. Différent du Livreur et du Marchand : "
		"uniforme, pas de tablier ni de sacoche."),
	("PNJ_SCOUT", "REF_FJ_SCOUT",
		"un jeune Scout passionné de Pokémon Insecte, garçon d'environ 10 ans, PLUS PETIT que les adultes "
		"(environ 85 % de la taille du héros) : chapeau de paille rond à bord court, cheveux châtains "
		"courts, débardeur vert olive sur un t-shirt blanc, short beige à poches, chaussettes hautes "
		"blanches, baskets vertes, petite boîte à insectes verte en bandoulière, FILET À INSECTES (manche "
		"en bois, filet blanc) tenu dans la main droite. Pas de casquette (différent du Jeune Dresseur), "
		"pas de sac à dos."),
	("PNJ_NATURALISTE", "REF_FJ_NATURALISTE",
		"un jeune naturaliste d'une vingtaine d'années, curieux et doux : cheveux bruns courts en "
		"bataille, fines lunettes rondes, gilet sans manches beige à nombreuses poches sur une chemise "
		"vert sauge, pantalon de toile brun clair, bottines de marche brunes, petit sac à dos gris-vert, "
		"carnet de terrain ouvert dans la main gauche, loupe accrochée à la ceinture. Pas de blouse "
		"blanche (différent du chercheur de Bourg Palette)."),
]

## Pokémon d'ambiance immobiles : (identifiant, référence ou None, description, repos, réaction).
POKEMON_FIXES = [
	("POKE_CHENIPAN_FIXE", "REF_FJ_CHENIPAN",
		"Chenipan, la petite chenille de Pokémon Rouge/Bleu, fidèle à son design officiel : corps vert "
		"vif en segments ronds, ventre crème jaunâtre, grands yeux, taches rondes jaunes sur les côtés "
		"de la tête, antenne rouge fourchue sur le dessus de la tête, petites pattes.",
		"posé à plat, le corps allongé au sol, la tête basse, calme",
		"il RELÈVE LA TÊTE et le haut du corps, antenne dressée, curieux, le bas du corps reste posé"),
	("POKE_ASPICOT_FIXE", None,
		"Aspicot, la petite chenille de Pokémon Rouge/Bleu, fidèle à son design officiel : corps orangé "
		"en segments ronds, gros nez rose, petits yeux noirs, dard pointu gris sur la tête et un autre au "
		"bout de la queue, petites pattes roses.",
		"posé à plat, calme, le dard de tête au repos",
		"il se RECROQUEVILLE sur ses gardes : tête rentrée et baissée, dard de tête pointé vers l'avant, "
		"corps tassé"),
	("POKE_CHRYSACIER_FIXE", None,
		"Chrysacier, le cocon de Pokémon Rouge/Bleu, fidèle à son design officiel : carapace verte dure "
		"en forme de croissant, plaques segmentées, yeux mi-clos à la paupière lourde.",
		"immobile, droit, yeux mi-clos",
		"un léger frisson : la carapace s'incline un peu sur le côté et les yeux s'ouvrent davantage"),
	("POKE_COCONFORT_FIXE", "REF_FJ_COCONFORT",
		"Coconfort, le cocon de Pokémon Rouge/Bleu, fidèle à son design officiel : carapace jaune doré "
		"dure, plaques segmentées, deux petites excroissances pointues sur les côtés, yeux plissés.",
		"immobile, droit, yeux plissés",
		"un léger frisson : la carapace s'incline un peu sur le côté et les yeux s'ouvrent davantage"),
]

## Conditionnels : (identifiant, références, description) — lancés seulement par leur nom.
PLANCHE_FORET_C = ("WORLD_TREE_FORET_PLANCHE_C",
	"PLANCHE de 4 arbres de forêt serrée, grille invisible de 2 colonnes × 2 lignes dans une image "
	"1024 × 1024, un arbre entier et centré par cellule, les pieds sur une même ligne dans chaque rangée, "
	"à la même échelle que les planches jointes WORLD_TREE_FORET_PLANCHE_A et _B (environ 3 cases de "
	"haut). Même main peinte, même vue, mêmes contours, mais une forêt plus PROFONDE : verts sombres "
	"bleutés, peu de hautes lumières jaunes. 1 : feuillu vert profond bleuté ; 2 : feuillu au tronc "
	"moussu, feuillage vert sombre ; 3 : conifère bleu-vert dense ; 4 : feuillu vert sapin aux feuilles "
	"larges. Fond avec une vraie transparence, aucun sol, aucune ombre portée.")
RAIS = ("WORLD_DECAL_RAIS_LUMIERE_01",
	"PLANCHE de lumières de sous-bois destinées à un mélange ADDITIF : fond NOIR PUR opaque (#000000), "
	"rien d'autre que de la lumière. Image 1024 × 1024 en 2 colonnes : à gauche, un RAI DE LUMIÈRE "
	"oblique (du haut à gauche vers le bas à droite, environ 20 degrés), large en bas, doux et "
	"légèrement poussiéreux, blanc chaud très pâle, bords très flous, qui s'éteint progressivement vers "
	"le haut ; à droite, une TACHE DE LUMIÈRE au sol vue de dessus, ovale, irrégulière (comme filtrée "
	"par des feuilles), blanc chaud très pâle, bords très flous. Aucune feuille, aucun arbre, aucun "
	"sol, aucun objet, aucun texte.")

## Entrées du manifeste (ajoutées au T17 par --manifeste, en fin de chaque section).
MANIFESTE = {
	"objets": [
		{"id": "prop_tronc_incline_01", "source": "WORLD_PROP_TRONC_INCLINE_01_NE_r1.png",
			"sortie": "assets/world/props/prop_tronc_incline_01.png", "axe": "w", "cases": 4,
			"ombre": False, "contact": 0.15},
		{"id": "prop_grande_souche_01", "source": "WORLD_PROP_GRANDE_SOUCHE_01_NE_r1.png",
			"sortie": "assets/world/props/prop_grande_souche_01.png", "axe": "w", "cases": 3.4,
			"ombre": False, "contact": 0.2},
		{"id": "prop_racines_01", "source": "WORLD_PROP_RACINES_01_NE_r1.png",
			"sortie": "assets/world/props/prop_racines_01.png", "axe": "w", "cases": 1.6,
			"ombre": False, "contact": 0.2},
		{"id": "prop_sac_rando_01", "source": "WORLD_PROP_SAC_RANDO_01_NE_r1.png",
			"sortie": "assets/world/props/prop_sac_rando_01.png", "axe": "w", "cases": 0.7,
			"ombre": False, "contact": 0.3},
	],
	"pieces": [
		{"id": "int_poste_foret_coque", "source": "INT_POSTE_FORET_COQUE_NE_r1.png",
			"sortie": "assets/world/interiors/int_poste_foret_coque.png", "cases": [10, 8]},
	],
	"decalcomanies": [
		{"source": "WORLD_GROUND_SOUS_BOIS_01_NE_r1.png", "dossier": "assets/world/ground/decals/",
			"prefixe": "decal_sousbois_", "colonnes": 4, "lignes": 2, "largeur_cases": 0.6},
	],
	"personnages": [
		{"id": "garde", "source": "PNJ_GARDE_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/garde_sheet.png", "hauteur": 130},
		{"id": "scout", "source": "PNJ_SCOUT_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/scout_sheet.png", "hauteur": 112},
		{"id": "naturaliste", "source": "PNJ_NATURALISTE_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/naturaliste_sheet.png", "hauteur": 128},
	],
	"attentes": [
		{"id": "garde_idle", "source": "GARDE_ATTENTE_r1.png",
			"sortie": "assets/sprites/characters/painted/garde_idle_sheet.png", "marche": "garde"},
		{"id": "scout_idle", "source": "SCOUT_ATTENTE_r1.png",
			"sortie": "assets/sprites/characters/painted/scout_idle_sheet.png", "marche": "scout"},
		{"id": "naturaliste_idle", "source": "NATURALISTE_ATTENTE_r1.png",
			"sortie": "assets/sprites/characters/painted/naturaliste_idle_sheet.png",
			"marche": "naturaliste"},
	],
	# Section nouvelle (préparation au T17, jalon 9 §2.8) : planche 4 × 1 (repos face, réaction
	# face, repos profil gauche, réaction profil gauche) → feuille 6 × 1 (+ profil droit en miroir),
	# une seule échelle (hauteur = la pose de repos de face), pieds alignés.
	"pokemon_fixes": [
		{"id": "chenipan", "source": "POKE_CHENIPAN_FIXE_NE_r1.png",
			"sortie": "assets/sprites/pokemon/painted/chenipan_sheet.png", "hauteur": 44},
		{"id": "aspicot", "source": "POKE_ASPICOT_FIXE_NE_r1.png",
			"sortie": "assets/sprites/pokemon/painted/aspicot_sheet.png", "hauteur": 44},
		{"id": "chrysacier", "source": "POKE_CHRYSACIER_FIXE_NE_r1.png",
			"sortie": "assets/sprites/pokemon/painted/chrysacier_sheet.png", "hauteur": 56},
		{"id": "coconfort", "source": "POKE_COCONFORT_FIXE_NE_r1.png",
			"sortie": "assets/sprites/pokemon/painted/coconfort_sheet.png", "hauteur": 56},
	],
}


# --- Références -------------------------------------------------------------------------

def references() -> None:
	vue = Image.open(VUE).convert("RGB")
	ART.mkdir(parents=True, exist_ok=True)
	for nom, boite in REFS.items():
		ref = vue.crop(boite)
		ref = ref.resize((ref.width * AGRANDIR, ref.height * AGRANDIR), Image.LANCZOS)
		if nom in MIROIRS:
			ref = ref.transpose(Image.FLIP_LEFT_RIGHT)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_FJ_* dans {ART}")


# --- Prompts ----------------------------------------------------------------------------

def _prompt_objet(identifiant: str, ref: str, largeur, description: str, ancres: list[str]) -> str:
	noms = " et ".join(Path(a).stem for a in STYLE + ancres)
	retourne = " (retournée : respecte l'orientation décrite ci-dessous)" if ref in MIROIRS else ""
	jointes = (f"Images jointes : {ref} = référence de forme, de matériaux et de couleurs{retourne}, "
		"extraite de la vue d'ensemble de la Forêt de Jade : dessine l'objet comme s'il avait été extrait "
		f"de cette image puis agrandi, avec le même angle, mais avec la finesse des ancres. {noms} = ancres "
		"de style de la série (rendu peint, contour coloré, finesse, même angle de vue, même lumière "
		"neutre). La vue est plus sombre et plus bleue que les ancres : l'objet garde la lumière NEUTRE "
		"des ancres (le jeu assombrit la forêt lui-même).")
	corps = (f"ASSET : {description}\nFormat : PNG carré 1024 × 1024 ; l'objet occupe environ 900 px dans sa "
		f"plus grande dimension, centré. Échelle : {largeur} cases de large ; un adulte mesure 1,33 case."
		f"\n{OBJET_FIN}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n{corps}\n")


def _prompt_planche(identifiant: str, jointes: str, description: str) -> str:
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages jointes : "
		f"{jointes}\n\n{ADN}\n{LUMIERE_NE}\n\nEXCEPTION à la règle « Isolement » : plusieurs éléments "
		f"séparés sur une même planche.\n{description}\nInterdit : texte, chiffres, cadres, personnage, "
		"Pokémon, ombre portée.\n")


def _prompt_coque() -> str:
	identifiant, largeur, profondeur, description = COQUE
	return (f"{identifiant} — NOUVELLE image : l'enveloppe VIDE d'une pièce intérieure de jeu (murs et sol, "
		"aucun meuble).\nImages jointes : WORLD_BLDG_POSTE_FORET_01_NE_r1 = la façade validée de ce poste "
		"(matériaux et couleurs des murs) ; INT_CENTRE_COQUE_NE_r1 et INT_CENTRE_BANQUETTE_NE_r1 = ancres "
		"de style des intérieurs (rendu peint, contour coloré, finesse, angle de vue, géométrie d'une "
		f"enveloppe, lumière neutre) : respecte-les exactement.\n\n{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en trois "
		f"quarts, image opaque qui remplit tout le cadre.\nFormat : PNG opaque, proportions {largeur} × "
		f"{profondeur} (un peu plus large que profond).\nGéométrie (respecte-la exactement, c'est un plan de "
		f"jeu) : la pièce fait {largeur} cases de large × {profondeur} cases de profondeur. Vue de dessus en "
		"projection oblique frontale : le MUR DU FOND occupe toute la largeur en haut, on voit sa face avant "
		"sur les 2 cases du haut ; les murs latéraux gauche et droit ne sont visibles que par leur épaisseur "
		"vue de dessus (bande fine le long des bords) ; le mur du bas (au premier plan) n'est visible que par "
		"son épaisseur vue de dessus (bande fine en bas), interrompue au milieu par l'entrée. Les deux "
		"ouvertures (fond et bas) sont exactement l'une au-dessus de l'autre, au centre. Tout le reste est "
		f"du SOL, entièrement libre et vide.\nPièce : {description}\n"
		"Interdit : meubles, plantes, tapis (sauf le paillasson demandé), personnages, Pokémon, porte "
		"fermée, texte, lettres, chiffres, logo écrit, perspective avec point de fuite, vue isométrique, "
		"ombre portée.\n")


def _prompt_personnage(identifiant: str, ref: str | None, description: str) -> str:
	modele = (ART / "prompts" / "PNJ_MARCHAND_NE_r1.txt").read_text()
	debut, reste = modele.split("PERSONNAGE (identique dans toutes les images) : ", 1)
	fin = reste.split("\n", 1)[1]
	debut = debut.replace("PNJ_MARCHAND", identifiant)
	if ref:
		debut = debut.replace("(le héros validé) :", f"(le héros validé) ; {ref} = tenue seulement "
			"(petite, extraite d'une vue d'ensemble, rendu à NE PAS copier) :")
	return debut + f"PERSONNAGE (identique dans toutes les images) : {description}\n" + fin


def _prompt_pokemon_fixe(identifiant: str, ref: str | None, description: str, repos: str,
		reaction: str) -> str:
	jointes = ("PERSO_P2_PEINT_r1 (le héros validé) et POKE_RATTATA_P2_r1 (un petit Pokémon validé) = "
		"ancres de style")
	if ref:
		jointes += f" ; {ref} = couleurs et taille relative seulement (minuscule, rendu à NE PAS copier)"
	return (f"{identifiant} — planche d'un Pokémon d'ambiance IMMOBILE (il ne marche jamais) : 4 poses.\n"
		f"Images jointes : {jointes}.\nStyle : exactement le rendu des ancres : Pokémon peint simplifié, "
		"même finesse, même contour fin coloré sans trait noir. Ni pixel art, ni 3D, ni anime aux contours "
		f"noirs. Formes simples et lisibles pour rester net une fois réduit à environ 50 px de haut.\n"
		f"{LUMIERE_NE}\n\nPOKÉMON (identique dans les 4 poses) : {description}\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chaque pose dans une colonne invisible de "
		"384 px de large, bien séparées par du vide, le Pokémon entier dans chaque colonne, à la MÊME "
		"ÉCHELLE dans les 4 poses (environ 220 px de haut au repos), la base des 4 poses sur une même ligne "
		"horizontale.\n"
		f"- Pose 1 : au repos, vu de face (tourné vers le bas de l'écran) : {repos}.\n"
		f"- Pose 2 : même vue de face, RÉACTION : {reaction}.\n"
		f"- Pose 3 : au repos, de profil, tourné vers la GAUCHE : {repos}.\n"
		f"- Pose 4 : même profil gauche, RÉACTION : {reaction}.\n"
		"Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus). Pas de sol, pas "
		"de branche, pas de feuille, pas de tronc, pas de fil de soie, pas d'ombre au sol, pas de texte, "
		"pas de numéros, pas de cadres. Les couleurs, les proportions et le visage doivent être EXACTEMENT "
		"les mêmes dans les 4 poses ; seule la posture change entre repos et réaction.\n")


# --- Génération (Codex) -----------------------------------------------------------------

def _objet(entree) -> str:
	identifiant, ref, largeur, description, ancres = entree
	jointes = [ART / f"{ref}.png"] + [ART / a for a in STYLE + ancres]
	return _lancer(f"{identifiant}_NE_r1", _prompt_objet(identifiant, ref, largeur, description, ancres),
		jointes)


def _personnage(entree) -> str:
	identifiant, ref, description = entree
	jointes = [ART / HEROS] + ([ART / f"{ref}.png"] if ref else [])
	ligne = _lancer(f"{identifiant}_NE_r1", _prompt_personnage(identifiant, ref, description), jointes)
	# L'attente se calque sur la planche de marche (méthode de tools/art/attente).
	nom = identifiant.removeprefix("PNJ_")
	attente = _lancer(f"{nom}_ATTENTE_r1", (ATTENTES / f"{nom}_ATTENTE.txt").read_text(),
		[ART / f"{identifiant}_NE_r1.png"])
	return f"{ligne}\n{attente}"


def _pokemon(entree) -> str:
	identifiant, ref = entree[0], entree[1]
	jointes = [ART / HEROS, ART / "POKE_RATTATA_P2_r1.png"] + ([ART / f"{ref}.png"] if ref else [])
	return _lancer(f"{identifiant}_NE_r1", _prompt_pokemon_fixe(*entree), jointes)


def _taches(choix: set[str]):
	def voulu(identifiant: str) -> bool:
		return not choix or identifiant in choix

	for entree in SERIE:
		if voulu(entree[0]):
			yield lambda e=entree: _objet(e)
	identifiant, description = PLANCHE_SOUS_BOIS
	if voulu(identifiant):
		jointes = ("REF_FJ_SOUS_BOIS = ambiance et couleurs du sous-bois ; WORLD_PROP_SOUCHE_01_NE_r1 et "
			"WORLD_TREE_A_01_NE_r1 = ancres de style (rendu peint, contour coloré, finesse, lumière neutre).")
		yield lambda: _lancer(f"{identifiant}_NE_r1", _prompt_planche(identifiant, jointes, description),
			[ART / "REF_FJ_SOUS_BOIS.png"] + [ART / s for s in STYLE])
	if voulu(COQUE[0]):
		yield lambda: _lancer(f"{COQUE[0]}_NE_r1", _prompt_coque(), [ART / s for s in STYLE_PIECE])
	for entree in PERSONNAGES:
		if voulu(entree[0]):
			yield lambda e=entree: _personnage(e)
	for entree in POKEMON_FIXES:
		if voulu(entree[0]):
			yield lambda e=entree: _pokemon(e)
	# Conditionnels : seulement par leur nom.
	if PLANCHE_FORET_C[0] in choix:
		identifiant, description = PLANCHE_FORET_C
		jointes = ("WORLD_TREE_FORET_PLANCHE_A_NE_r1 et WORLD_TREE_FORET_PLANCHE_B_NE_r1 = les planches "
			"validées de la forêt serrée (style, échelle, vue) ; REF_FJ_FORET = couleurs de la forêt voulue.")
		yield lambda: _lancer(f"{identifiant}_NE_r1", _prompt_planche(identifiant, jointes, description),
			[ART / "WORLD_TREE_FORET_PLANCHE_A_NE_r1.png", ART / "WORLD_TREE_FORET_PLANCHE_B_NE_r1.png",
				ART / "REF_FJ_FORET.png"])
	if RAIS[0] in choix:
		identifiant, description = RAIS
		yield lambda: _lancer(f"{identifiant}_r1", f"{identifiant} — NOUVELLE image : lumières de jeu, pas "
			f"une scène.\nImage jointe : REF_FJ_RAI = le rai de la vue validée (forme et douceur seulement)."
			f"\n{description}\nInterdit : texte, chiffres, cadres, personnage, Pokémon.\n",
			[ART / "REF_FJ_RAI.png"])


# --- Manifeste --------------------------------------------------------------------------

def _cle(section: str, entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, **par insertion de texte** (mise en forme
	manuelle du manifeste intacte) ; une section absente est créée en fin de fichier."""
	chemin = ICI / "manifeste.json"
	texte = chemin.read_text()
	m = json.loads(texte)
	ajouts = 0
	for section, entrees in MANIFESTE.items():
		presents = {_cle(section, e) for e in m.get(section, [])}
		nouvelles = [e for e in entrees if _cle(section, e) not in presents]
		if not nouvelles:
			continue
		blocs = ",\n".join("  " + json.dumps(e, ensure_ascii=False, indent=1).replace("\n", "\n  ")
			for e in nouvelles)
		if section in m:
			fin = _fin_de_liste(texte, section)
			avant = texte[:fin].rstrip()
			separateur = "," if not avant.endswith("[") else ""
			texte = f"{avant}{separateur}\n{blocs}\n {texte[fin:]}"
		else:
			fin = texte.rstrip().rindex("}")
			texte = f'{texte[:fin].rstrip()},\n "{section}": [\n{blocs}\n ]\n{texte[fin:]}'
		ajouts += len(nouvelles)
	json.loads(texte)  # toujours du JSON valide
	chemin.write_text(texte)
	print(f"manifeste : {ajouts} entrée(s) de la série 11 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------

def _ref(nom: str, hauteur: int) -> Image.Image:
	image = Image.open(VUE).convert("RGBA").crop(REFS[nom])
	if nom in MIROIRS:
		image = _miroir(image)
	return _echelle(image, hauteur / image.height)


def _interieur(nom: str) -> Image.Image:
	return _asset(f"assets/world/interiors/{nom}.png")


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso("assets/sprites/characters/painted/heros_sheet.png"), "héros (échelle)")
	w = "assets/world/"
	p = _Planche(2600, "Forêt de Jade — kit de la série 11 (T16, jalon 9) : 1 case = 48 px sur cette "
		"planche ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu)", [
		heros,
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt serrée") for i in range(1, 9)],
		(_asset(f"{w}props/tree_e_01.png"), "tree_e_01\nlisière des clairières"),
		(_asset(f"{w}props/tree_b_01.png"), "tree_b_01\nconifère de lisière"),
		(_asset(f"{w}props/tree_c_01.png"), "tree_c_01\nbord de C3"),
		(_asset(f"{w}props/tree_a_01.png"), "tree_a_01\nparvis"),
		(_echelle(_asset(f"{w}buildings/bldg_poste_foret_01.png"), 1.0), "bldg_poste_foret_01\nposte nord"),
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\njaune-vert H1-H4"),
		(_asset(f"{w}props/prop_souche_01.png"), "souche ×2\n(parvis, P2)"),
		(_asset(f"{w}props/prop_ronces_01.png"), "ronces\nlisière"),
		(_asset(f"{w}props/prop_tronc_couche_01.png"), "tronc couché\nlisière"),
		*[(_echelle(_asset(f"{w}ground/decals/decal_fleur_{i}.png"), 1.6), f"fleur_{i}")
			for i in (1, 3, 5, 6)],
		*[(_echelle(_asset(f"{w}ground/decals/decal_touffe_{i}.png"), 1.0), f"touffe_{i}") for i in (1, 2)],
		(_asset("assets/sprites/objects/painted/poke_ball_ground.png"), "Ball au sol\nO1, O2, O5"),
		(_interieur("int_plante"), "int_plante ×2\nposte"),
		(_interieur("int_meuble_bas_01"), "meuble bas\nposte"),
		(_interieur("int_porte_manteau_01"), "porte-manteau\nposte"),
		(_cellule_perso("assets/sprites/characters/painted/randonneuse_sheet.png"), "Randonneuse\n(P2)"),
		(_cellule_perso("assets/sprites/characters/painted/jeune_dresseur_sheet.png"), "Jeune Dresseur\n(Tom)"),
		(_cellule_perso("assets/sprites/pokemon/painted/roucool_sheet.png"), "Roucool\n(clairière H4)"),
	], (40, 90, 50))

	# 2. Variations.
	arbre = _asset(f"{w}props/tree_foret_03.png")
	variations = [(_teinter(arbre, (v * 0.97, v, min(1.0, v * 1.05))), f"forêt × {v:.2f}\nplus froide")
		for v in (0.82, 0.72)]
	variations.append((_teinter(_asset(f"{w}props/tree_foret_05.png"), (0.7, 0.74, 0.78)),
		"conifères 04-06\npoids × 2"))
	herbe = _asset(f"{w}ground/ground_hautes_herbes_jaune_01.png")
	variations.append((_teinter(herbe, (0.84, 0.88, 0.9)), "H3 sous la\ncanopée × 0,86"))
	ombre = _asset(f"{w}props/tree_a_01_shadow.png")
	tache = Image.new("RGBA", ombre.size, (16, 26, 40, 0))
	tache.putalpha(ombre.getchannel("A").point(lambda a: round(a * 0.5)))
	variations.append((_echelle(tache, 2.0), "ombres de canopée\nau sol (J8)"))
	variations.append((_teinter(_miroir(_asset(f"{w}props/prop_souche_01.png")), (0.85, 0.88, 0.9)),
		"souche miroir\n+ teinte"))
	rai = Image.new("RGBA", (70, 200), (0, 0, 0, 0))
	for y in range(rai.height):
		for x in range(rai.width):
			rai.putpixel((x, y), (255, 244, 214, round(90 * (y / rai.height) * (1 - abs(x - 35) / 35))))
	variations.append((rai, "rai de lumière\n(Godot, dégradé)"))
	p.section("2. VARIATIONS SANS NOUVEL ASSET (teinte, poids des essences, miroir, Godot)",
		variations, (60, 80, 110))

	# 3. Nouveaux : références recadrées de la vue, à leur taille en jeu.
	p.section("3. NOUVEAUX (Codex, lumière NE) — référence recadrée de la vue, à la taille en jeu", [
		heros,
		(_ref("REF_FJ_TRONC", round(3 * CASE_PLANCHE)), "WORLD_PROP_TRONC_INCLINE_01\n4 cases, pied 2 × 1"),
		(_ref("REF_FJ_SOUCHE", round(2.6 * CASE_PLANCHE)), "WORLD_PROP_GRANDE_SOUCHE_01\nemprise 3 × 2"),
		(_ref("REF_FJ_RACINES", round(2 * CASE_PLANCHE)), "WORLD_PROP_RACINES_01\nemprise 1 × 2"),
		(_ref("REF_FJ_SAC", round(0.7 * CASE_PLANCHE)), "WORLD_PROP_SAC_RANDO_01\n1 case"),
		(_ref("REF_FJ_SOUS_BOIS", 120), "WORLD_GROUND_SOUS_BOIS_01\n8 décalcomanies"),
		(_ref("REF_FJ_POSTE", 120), "INT_POSTE_FORET_COQUE\n10 × 8 (matériaux)"),
		(_ref("REF_FJ_SCOUT", 60), "PNJ_SCOUT (+ attente)\n112 px"),
		(_ref("REF_FJ_NATURALISTE", 66), "PNJ_NATURALISTE\n(+ attente) 128 px"),
		(_cellule_perso("assets/sprites/characters/painted/livreur_sheet.png"), "PNJ_GARDE (+ attente)\n"
			"130 px (pas dans la vue)"),
		(_ref("REF_FJ_CHENIPAN", 26), "Chenipan\n44 px"),
		(_ref("REF_FJ_COCONFORT", 32), "Coconfort\n56 px"),
	], (130, 70, 40))
	p.section("3 bis. CONDITIONNELS (prompts prêts, lancés seulement si les captures du T19 / T21 le "
		"demandent)", [
		(_ref("REF_FJ_FORET", 160), "WORLD_TREE_FORET_PLANCHE_C\nsi la forêt se répète"),
		(_ref("REF_FJ_RAI", 160), "WORLD_DECAL_RAIS_LUMIERE_01\nsi le rai Godot ne se lit pas"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts de la vue, non reproduits)", [
		(_ref("REF_FJ_SECONDE_SOUCHE", 70), "seconde souche au centre\n(une seule grande souche)"),
		(_ref("REF_FJ_HAIES", 120), "bords en haies taillées\n(sous-bois irrégulier)"),
		(_ref("REF_FJ_CHICOT", 110), "chicot du naturaliste\n(un tronc de forêt suffit)"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--refs" in arguments:
		references()
	elif "--planche" in arguments:
		autres = [a for a in arguments if a != "--planche"]
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "FJ_KIT_v1.png"))
	elif "--manifeste" in arguments:
		manifeste()
	else:
		references()
		taches = list(_taches(set(arguments)))
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(lambda t: t(), taches):
				print(ligne, flush=True)
