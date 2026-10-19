#!/usr/bin/env python3
"""Série 28 (numéro PROVISOIRE) — kit d'art du jalon 25 : Manoir Pokémon, Arène d'Auguste,
réserve du Musée d'Argenta, PNJ, décors de combat, dos de Pokémon. Lot 25.0, tâches T10 à T12.

Fiche : docs/design/fiches-assets/serie-28-cramois.md ; conception : dossier 28 §4, §7, §8, §9, §13 ;
plan : docs/tech/jalon-25.md §2.9 ; géométrie (fait foi) : tools/plans/manoir_*.txt, cramois_arene.txt,
argenta_musee_reserve.txt. Aucune intégration Godot : rien dans `assets/`, aucun manifeste lancé ;
tout sort dans $ART (défaut : build/art de cette copie), sous `serie28/`.

Méthode des cartes (comme la Tour du J19, `tools/build_pokemon_tower.gd`, et les grottes) : un KIT
MODULAIRE (sols raccordables, masses de murs, faces / couronnements / flancs, objets) posé par la
GRILLE, jamais une image peinte d'un coup (une image de 30 × 28 cases n'a que ≈ 43 px par case et
suit mal le plan, essai du 2026-10-19 : 75 % des cases justes). `--cartes` recompose chaque carte à
1 case = 96 px, état « ARRÊT » (jeu A fermé, jeu B ouvert) : c'est la « carte peinte » de contrôle.

Usage :
  tools/art/serie28.py --prompts            écrit tous les prompts (sans Codex)
  tools/art/serie28.py --ancres             copie les ancres de style dans $ART
  tools/art/serie28.py --refs               recadre les vues validées dans $ART (REF_*)
  tools/art/serie28.py --commandes [VAGUE]  liste les appels tools/art/generer.sh
  tools/art/serie28.py --tuiles ESSAI       portions TL / TR d'une composition de décor
  tools/art/serie28.py --decor ID ESSAI     assemble un décor (manoir_salle | arene_cramois)
  tools/art/serie28.py --preparer           prépare les essais retenus -> $ART/serie28/
  tools/art/serie28.py --cartes             recompose les cartes (kit + grille) -> $ART/serie28/cartes/
  tools/art/serie28.py --controle [sortie]  planche de contrôle -> build/art/SERIE28_CONTROLE_v1.png
"""
from __future__ import annotations

import json
import math
import os
import random
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
sys.path.insert(0, str(ICI / "combat_decors"))
from serie06 import ADN, LUMIERE_NE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
SORTIE = ART / "serie28"
PROMPTS = ICI / "prompts" / "serie28"
PROMPTS_DECOR = PROMPTS / "decors"
REFERENCE = RACINE / "docs/design/reference"
PLANS = RACINE / "tools/plans"
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026/build/art")
J20_ART = Path("/Users/kevinyankam/dev/kanto-2026/.claude/worktrees/j20-t2-t3-art/build/art")
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PROTO = RACINE / "assets/sprites/pokemon/battle_proto"
CASE = 96

VUE_M = REFERENCE / "manoir-vue-generale-v1.png"          # 1536 × 1024 : 2F | 3F, 1F | B1F
VUE_A = REFERENCE / "cramois-arene-vue-generale-v1.png"   # 1254 × 1254
PLAN_M = REFERENCE / "manoir-plan-v1.png"

## Recadrages des vues validées (boîtes en px des vues), agrandis × 3 (jointes d'ambiance).
REFS = {
	"REF_M_SALLE": (VUE_M, (190, 470, 480, 720)),      # 1F : parquet, tonneaux, statue, murs fins
	"REF_M_MUR": (VUE_M, (280, 30, 560, 150)),         # 2F : mur du fond, fenêtres, poutres
	"REF_M_PLAFOND": (VUE_M, (800, 100, 1130, 240)),   # 3F : plafond ouvert sur le ciel, escalier
	"REF_M_PUPITRE": (VUE_M, (800, 250, 1010, 380)),   # 2F : pupitre à carnet, grille, table
	"REF_M_TROUS": (VUE_M, (1000, 330, 1260, 420)),    # 3F : trous du plancher, planches
	"REF_M_B1F": (VUE_M, (790, 470, 1060, 720)),       # B1F : dalles gris-bleu, tables de labo
	"REF_A_SALLE": (VUE_A, (40, 330, 420, 740)),       # Arène : murs, herse, machine, sol
	"REF_A_STATUE": (VUE_A, (880, 940, 1210, 1130)),   # Arène : statue sur socle
	"REF_A_PNJ": (VUE_A, (200, 130, 320, 330)),        # Arène : Auguste (blouse) et Intello
	"REF_A_PILLARD": (VUE_A, (200, 540, 280, 640)),    # Arène : Pillard (bonnet, écharpe)
}

## Ancres de style : (nom dans $ART, source principale ou chemin relatif à la racine).
ANCRES = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png", "PERSO_P2_PEINT_r1.png",
	"INT_LIT_01_NE_r1.png", "INT_MACHINES_LABO_01_NE_r1.png", "INT_GRANDE_ETAGERE_01_NE_r1.png",
	"PNJ_GUIDE_ARENE_NE_r1.png", "PNJ_VIEIL_HOMME_NE_r1.png", "PNJ_CHERCHEUR_NE_r1.png"]
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1", "WORLD_TREE_A_01_NE_r1"]
HEROS = "PERSO_P2_PEINT_r1"
## Assets préparés du dépôt, joints comme ancres de planches d'intérieur (relatifs à la racine).
ANCRE_ARMOIRE = "assets/world/interiors/int_armoire_electrique_01.png"
ANCRE_BARRIERE = "assets/world/interiors/int_barriere_active_01.png"
ANCRE_VITRINE = "assets/world/interiors/int_vitrine_dome_01.png"
ANCRE_MUSEE_BAT = "assets/world/buildings/bldg_musee_argenta_01.png"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, signature, AUCUN emblème rond de "
	"type balle (ni cercle partagé en deux, ni médaillon à bande centrale) nulle part, Pikachu et tout "
	"Pokémon non demandé, AUCUNE créature (ni silhouette, ni ombre de créature, ni forme dans un bocal, "
	"un tube ou une vitrine), personnage non demandé, élément gore ou effrayant (ni sang, ni squelette, "
	"ni crâne, ni toile d'araignée envahissante), pixel art, 3D, vue isométrique, halo, rayon ou "
	"faisceau de lumière, flaque de lumière.")
LUMIERE_INT = (LUMIERE_NE + " Intérieur : les fenêtres montrent un ciel de jour pâle et neutre ; les "
	"flammes de bougie et de braise sont peintes petites, SANS halo ni rayon ; aucun faisceau, aucune "
	"flaque de lumière dorée au sol (le jeu ajoute lui-même l'éclairage : doré de fin d'après-midi dans "
	"le Manoir, braises rougeoyantes dans l'Arène).")
OBJET_FIN = ("Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné. La base de "
	"l'objet est une ligne de sol droite et horizontale ; rien sous cette ligne ; aucun sol autour, "
	"aucune ombre portée.")
TEXTURE_FIN = ("Format : PNG carré 1024 × 1024, OPAQUE, qui couvre toute l'image. Texture vue strictement "
	"de dessus, à plat, RACCORDABLE sans couture sur ses quatre bords (elle se répète en mosaïque) ; motif "
	"sans élément remarquable qui trahirait la répétition ; aucune perspective, aucun objet, aucun "
	"bord, aucun vignettage.")
FIN_DETOURE = ("FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond "
	"coloré, aucun sol, aucune ombre portée.")

# --------------------------------------------------------------------------------------------
# Sols et masses (textures raccordables 1024 -> 384 px = 4 × 4 cases)
# --------------------------------------------------------------------------------------------
## (identifiant de fiche, id préparé, référence jointe, description)
TEXTURES = [
	("WORLD_GROUND_PARQUET_MANOIR_01", "ground_parquet_manoir_01", "REF_M_SALLE",
		"texture du PARQUET du rez-de-chaussée et des étages d'un manoir de chercheurs brûlé : lattes de "
		"chêne miel posées HORIZONTALEMENT (de gauche à droite), 4 lattes par case (1 case = 256 px sur "
		"cette texture), fins joints brun foncé, extrémités décalées d'une rangée à l'autre, quelques "
		"lattes plus sombres noircies par la suie, très légères traces de brûlure en surface (jamais de "
		"trou ni de flaque), pas de clou visible. Chaud, usé, lisible ; valeurs moyennes, contraste doux."),
	("WORLD_GROUND_CARRELAGE_B1_01", "ground_carrelage_b1_01", "REF_M_B1F",
		"texture du SOL DU SOUS-SOL d'un laboratoire abandonné : grandes dalles de pierre gris-bleu "
		"d'1 case chacune (1 case = 256 px sur cette texture), joints sombres fins, usure et rayures "
		"légères, quelques taches de rouille ocre et d'huile discrètes, très peu nombreuses ; frais, "
		"sec, silencieux ; valeurs moyennes, contraste doux."),
	("WORLD_GROUND_MASSE_MANOIR_01", "ground_masse_manoir_01", "REF_M_SALLE",
		"texture du DESSUS DES MURS ÉPAIS du manoir brûlé, vus de dessus : bois et plâtre CARBONISÉS "
		"brun-violet très sombre (noir chaud), grain de poutres calcinées, fissures fines, éclats de "
		"braise éteinte à peine plus clairs ; AUCUNE ligne de joint régulière ; très sombre mais jamais "
		"noir pur ; sert à remplir de grandes surfaces."),
	("WORLD_GROUND_MASSE_MANOIR_B1_01", "ground_masse_manoir_b1_01", "REF_M_B1F",
		"texture du DESSUS DES MURS ÉPAIS du sous-sol, vus de dessus : béton et pierre sombres bleu nuit, "
		"grain fin, quelques fissures et petites taches de rouille ; AUCUNE ligne de joint régulière ; "
		"sombre mais jamais noir pur ; sert à remplir de grandes surfaces."),
	("WORLD_GROUND_DALLES_ARENE_01", "ground_dalles_arene_01", "REF_A_SALLE",
		"texture du SOL DE L'ARÈNE de Cramois'Île : dalles de grès volcanique sable chaud rosé d'1 case "
		"chacune (1 case = 256 px sur cette texture), joints fins plus sombres, usure douce, de rares "
		"éclats et de petits cailloux ; jamais de lave, jamais de flaque de lumière ; valeurs moyennes."),
	("WORLD_GROUND_MASSE_ARENE_01", "ground_masse_arene_01", "REF_A_SALLE",
		"texture du DESSUS DES MURS et de la ROCHE de l'Arène, vus de dessus : basalte volcanique "
		"violet-brun sombre, gros blocs irréguliers aux arêtes adoucies, quelques fissures où couve une "
		"braise orange très fine et RARE (jamais de lave, jamais de flaque) ; sombre mais jamais noir pur ; "
		"sert à remplir de grandes surfaces."),
]

# --------------------------------------------------------------------------------------------
# Planches (relief des murs, objets). 3 colonnes × 2 lignes de 512 dans 1536 × 1024
# --------------------------------------------------------------------------------------------
_PLANCHE_FORMAT = ("PLANCHE dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes "
	"(cellules de 512 × 512), un élément par cellule, centré, sa base sur une même ligne horizontale à "
	"30 px du bas de sa cellule, à une échelle COMMUNE de 1 case = {px} px. Vue de dessus de trois "
	"quarts, en projection oblique frontale : on voit le dessus et la face avant (sud), jamais les "
	"côtés. Fond transparent.")

## (identifiant de fiche, références, description, jointes d'ancre supplémentaires)
PLANCHES = [
	("WORLD_RELIEF_MUR_MANOIR_PLANCHE", ["REF_M_MUR", "REF_M_PLAFOND"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : le KIT DES MURS ÉPAIS du Manoir Pokémon, un manoir de "
		"chercheurs ravagé par un incendie (bois noirci de suie, plâtre fissuré, papier peint décollé, "
		"poutres brisées). Six éléments, tous du MÊME mur (mêmes matières et mêmes couleurs : boiseries "
		"brun-violet sombre, plâtre crème sali, suie) :\n"
		"1 (ligne 1, à gauche) FACE_01 : la FACE AVANT (sud) d'un pan de mur, vue de face : lambris bas de "
		"planches noircies, haut en plâtre fissuré taché de suie ; 2 cases de large (≈ 320 px) × 1 case "
		"de haut (≈ 160 px), les bords gauche et droit COUPÉS NET en ligne droite (elle se juxtapose bout "
		"à bout), le bas droit et horizontal.\n"
		"2 (ligne 1, au milieu) FACE_02 : même gabarit (2 × 1), le papier peint décollé en lambeaux "
		"(motif de petites fleurs fanées, sans détail lisible) laissant voir le plâtre ; "
		"3 (ligne 1, à droite) FACE_03 : même gabarit (2 × 1), avec une FENÊTRE crevée au milieu : cadre de "
		"bois brisé, vitres cassées, ciel de jour pâle et neutre derrière ;\n"
		"4 (ligne 2, à gauche) FACE_04 : même gabarit (2 × 1), le haut éventré : une grande POUTRE brisée "
		"en diagonale et une brèche sur le ciel de jour pâle, quelques planches pendantes ;\n"
		"5 (ligne 2, au milieu) CAP : le COURONNEMENT du mur, un liseré d'1 case de long vu de dessus : "
		"bord supérieur du mur en bois brûlé et plâtre, un peu plus clair que la masse ; 2 cases de large "
		"(≈ 320 px) × 0,4 case de haut (≈ 64 px), bords gauche et droit coupés net, juxtaposable ;\n"
		"6 (ligne 2, à droite) SIDE : le FLANC d'un mur, bande verticale étroite vue de dessus : 0,35 case "
		"de large (≈ 56 px) × 3 cases de haut (≈ 480 px), bois brûlé et plâtre, coupée net en haut et en "
		"bas, juxtaposable verticalement.\n"
		"Aucune porte, aucun meuble, aucune lumière peinte.", []),
	("WORLD_RELIEF_MUR_MANOIR_B1_PLANCHE", ["REF_M_B1F"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : le KIT DES MURS du SOUS-SOL du Manoir (laboratoire secret "
		"abandonné : briques de pierre gris-bleu, béton sombre, tuyaux de cuivre rouillés). Six éléments "
		"du MÊME mur :\n"
		"1 (ligne 1, à gauche) FACE_01 : FACE AVANT (sud) d'un pan de mur, vue de face : soubassement de "
		"béton sombre, haut en BRIQUES de pierre gris-bleu à joints fins ; 2 cases de large (≈ 320 px) × "
		"1 case de haut (≈ 160 px), bords gauche et droit COUPÉS NET (juxtaposable), bas droit.\n"
		"2 (ligne 1, au milieu) FACE_02 : même gabarit (2 × 1), avec deux TUYAUX de cuivre verdis qui "
		"courent horizontalement et un raccord à vanne ; "
		"3 (ligne 1, à droite) FACE_03 : même gabarit (2 × 1), avec une ÉTAGÈRE MURALE de laboratoire "
		"en bois sombre portant quelques BOCAUX VIDES et des flacons (verre pâle, AUCUN contenu vivant) ;\n"
		"4 (ligne 2, à gauche) FACE_04 : même gabarit (2 × 1), briques tachées de rouille et d'humidité, "
		"quelques briques fissurées ;\n"
		"5 (ligne 2, au milieu) CAP : COURONNEMENT du mur vu de dessus : liseré de béton plus clair, "
		"2 cases de large (≈ 320 px) × 0,4 case de haut (≈ 64 px), bords coupés net, juxtaposable ;\n"
		"6 (ligne 2, à droite) SIDE : FLANC du mur, bande verticale étroite vue de dessus : 0,35 case de "
		"large (≈ 56 px) × 3 cases de haut (≈ 480 px), béton et brique, coupée net en haut et en bas, "
		"juxtaposable verticalement.\nAucune porte, aucun meuble, aucune lumière peinte.", []),
	("WORLD_RELIEF_MUR_ARENE_PLANCHE", ["REF_A_SALLE"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : le KIT DES MURS de l'ARÈNE de Cramois'Île (champion de "
		"type Feu) : gros blocs de roche volcanique violet-brun sombre taillés, joints nets, dessus plus "
		"clair, un fin liseré de braise orange au pied. Six éléments du MÊME mur :\n"
		"1 (ligne 1, à gauche) FACE_01 : FACE AVANT (sud) d'un pan de mur, vue de face : deux assises de "
		"blocs de basalte taillés ; 2 cases de large (≈ 320 px) × 1 case de haut (≈ 160 px), bords "
		"gauche et droit COUPÉS NET (juxtaposable), bas droit ; un liseré orange très fin de braise au "
		"pied.\n"
		"2 (ligne 1, au milieu) FACE_02 : même gabarit (2 × 1), blocs un peu plus clairs et fissurés ; "
		"3 (ligne 1, à droite) FACE_03 : même gabarit (2 × 1), avec une RIGOLE de braise : une fente "
		"étroite au pied du mur où couve une braise orange (petite, sans halo) ;\n"
		"4 (ligne 2, à gauche) FACE_04 : même gabarit (2 × 1), blocs sombres unis, sans braise ;\n"
		"5 (ligne 2, au milieu) CAP : COURONNEMENT vu de dessus : arête de blocs plus clairs, 2 cases de "
		"large (≈ 320 px) × 0,4 case de haut (≈ 64 px), bords coupés net, juxtaposable ;\n"
		"6 (ligne 2, à droite) SIDE : FLANC vu de dessus : 0,35 case de large (≈ 56 px) × 3 cases de haut "
		"(≈ 480 px), blocs de basalte, coupé net en haut et en bas, juxtaposable verticalement.\n"
		"Aucune porte, aucune herse, aucune machine, aucune lumière peinte.", []),
	("INT_MANOIR_PLANCHE_A", ["REF_M_PUPITRE", "REF_M_TROUS", "REF_M_SALLE"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : six OBJETS DE DÉCOR du Manoir Pokémon (manoir de chercheurs "
		"brûlé), matières communes : bois noirci, fer, pierre claire, papier.\n"
		"1 (ligne 1, à gauche) STATUE : statue de pierre BLANCHE d'une créature féline assise (un chat "
		"stylisé, de face, oreilles dressées, regard vide), sur un SOCLE de pierre gris ; statue et socle "
		"≈ 1 case de large (≈ 160 px) × 1,6 case de haut (≈ 256 px) ; légèrement poussiéreuse.\n"
		"2 (ligne 1, au milieu) GRILLE FERMÉE : un portail de FER noir à deux battants posé en travers "
		"d'un passage de 2 cases : barreaux verticaux et deux traverses, cadre de fer, seuil de pierre ; "
		"2 cases de large (≈ 320 px) × environ 1,4 case de haut (≈ 224 px) ; FERMÉ, les deux battants "
		"joints.\n"
		"3 (ligne 1, à droite) GRILLE OUVERTE : le MÊME portail, ouvert : les deux battants repliés et "
		"coulissés contre les montants gauche et droit, le passage central libre (seuil de pierre et rail "
		"visibles) ; mêmes dimensions (2 cases × ≈ 1,4 case), même fer, même cadre.\n"
		"4 (ligne 2, à gauche) TROU : un TROU dans le plancher, vu de dessus : ouverture ronde irrégulière "
		"d'environ 0,9 case de diamètre (≈ 150 px), bords en planches éclatées et poutres brisées "
		"pointant vers l'intérieur, fond noir bleuté profond (on ne voit rien au fond) ; la zone peinte "
		"fait ≈ 1,2 case de large avec ses éclats ; AUCUN sol autour hors des éclats.\n"
		"5 (ligne 2, au milieu) PUPITRE : un petit PUPITRE de bois brun sur quatre pieds, vu de dessus en "
		"trois quarts, un CARNET OUVERT posé dessus, pages jaunies aux bords BRÛLÉS, quelques lignes "
		"d'écriture suggérées par des traits flous (AUCUNE lettre lisible), un petit encrier ; ≈ 1 case "
		"de large (≈ 150 px) × 1,1 case de haut.\n"
		"6 (ligne 2, à droite) SEUIL : une OUVERTURE DE PORTE d'entrée brûlée vue de l'INTÉRIEUR : "
		"encadrement de bois noirci, battants brisés repoussés contre les côtés, seuil de pierre, et dans "
		"l'ouverture le rectangle pâle du dehors (ciel de jour neutre, sans rayon) ; 2 cases de large "
		"(≈ 320 px) × 1 case de haut (≈ 160 px).", [ANCRE_BARRIERE]),
	("INT_MANOIR_PLANCHE_B", ["REF_M_SALLE", "REF_M_B1F"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : six ÉLÉMENTS de décor et de mobilier du Manoir Pokémon "
		"(manoir de chercheurs brûlé), matières communes : bois noirci, fer, verre, papier.\n"
		"1 (ligne 1, à gauche) ESCALIER_MONTE : un ESCALIER de bois qui MONTE vers le haut de l'image, "
		"adossé à un mur : cinq marches de planches claires entre deux montants de bois sombres, "
		"1 case de large (≈ 160 px) × 1,2 case de haut (≈ 190 px).\n"
		"2 (ligne 1, au milieu) ESCALIER_DESCEND : une TRÉMIE d'escalier qui DESCEND : ouverture "
		"carrée dans le plancher, cinq marches de bois qui s'enfoncent vers le haut de l'image dans une "
		"ombre brun-violet douce (jamais noire), garde-corps bas de bois sur les trois côtés ; "
		"1 case × 1 case (≈ 160 px), vue de dessus.\n"
		"3 (ligne 1, à droite) TONNEAU : un TONNEAU de bois cerclé de fer, brûlé et noirci, couvercle "
		"plat sombre, 1 case de large (≈ 140 px) × 1,1 case de haut.\n"
		"4 (ligne 2, à gauche) GROUPE_TONNEAUX : QUATRE tonneaux identiques à celui-ci serrés en carré "
		"(2 × 2), noircis, quelques cercles de fer rouillés ; 2 cases de large (≈ 320 px) × "
		"2 cases de profondeur (≈ 340 px de haut au total).\n"
		"5 (ligne 2, au milieu) TABLE_LABO : une TABLE DE LABORATOIRE en bois brun étroite, vue de dessus "
		"en trois quarts : 1 case de large (≈ 150 px) × 2 cases de profondeur (≈ 340 px de haut), portant "
		"deux gros BOCAUX DE VERRE pâle à couvercle de métal (vides ou à liquide ambre ou bleu-gris "
		"uni ; AUCUN être vivant, aucune forme à l'intérieur) et quelques instruments.\n"
		"6 (ligne 2, à droite) CAISSE_ARCHIVES : une CAISSE de bois cerclée de fer pleine de dossiers et "
		"de papiers jaunis aux bords brûlés (couvercle ouvert), 1 case de large (≈ 150 px) × 1 case de "
		"haut.", []),
	("WORLD_DECALS_GRAVATS_MANOIR_PLANCHE", ["REF_M_SALLE", "REF_M_TROUS"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : six DÉCALCOMANIES de débris à poser sur le plancher du "
		"Manoir brûlé (vues strictement de dessus, à plat, bords doux qui s'effacent dans la transparence), "
		"une par cellule, 0,8 à 1,5 case de large :\n"
		"1 PLANCHES CASSÉES : trois ou quatre planches de bois noircies et éclatées, en désordre ;\n"
		"2 PAPIERS ÉPARPILLÉS : feuilles jaunies aux bords brûlés, dispersées (AUCUN texte lisible) ;\n"
		"3 GRAVATS : petits éclats de plâtre et de brique, un peu de poussière claire ;\n"
		"4 SUIE : grande tache de suie sombre irrégulière, bords très doux (alpha progressif) ;\n"
		"5 VERRE BRISÉ : éclats de verre pâle et de cadre cassé ;\n"
		"6 TAPIS BRÛLÉ : un morceau de tapis bordeaux déchiré aux bords noircis.\n"
		"À plat, sans relief marqué, sans ombre portée.", []),
	("INT_ARENE_PLANCHE", ["REF_A_SALLE", "REF_A_STATUE"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : QUATRE objets de l'ARÈNE de Cramois'Île (salle de quiz du "
		"Champion de type Feu : roche volcanique sombre, fer, braise). Les cellules 5 et 6 restent VIDES.\n"
		"1 (ligne 1, à gauche) MACHINE_QUIZ : un PUPITRE-TERMINAL de pierre sombre et de métal, vu de "
		"dessus en trois quarts, avec un petit ÉCRAN incliné allumé BLEU PÂLE UNI (aucune lettre, aucun "
		"dessin, aucun halo) et trois gros boutons ; 1 case de large (≈ 150 px) × 1,2 case de haut.\n"
		"2 (ligne 1, au milieu) HERSE_FERMEE : une HERSE de fer noir, portail à barreaux verticaux épais "
		"et traverses, qui ferme un passage de 2 cases ; pierre volcanique de chaque côté du cadre ; fer "
		"qui rougeoie à peine à la base (un liseré orange fin, sans halo) ; 2 cases de large (≈ 320 px) × "
		"1,4 case de haut (≈ 224 px) ; FERMÉE.\n"
		"3 (ligne 1, à droite) HERSE_OUVERTE : la MÊME herse RELEVÉE : la grille remontée dans la "
		"gaine de pierre du haut (on en voit seulement les pointes, la gaine reste en haut du cadre), "
		"passage central libre, rail et seuil de pierre ; mêmes dimensions (2 × ≈ 1,4 case), même fer, "
		"même pierre.\n"
		"4 (ligne 2, à gauche) STATUE_ARENE : une STATUE de pierre grise d'une créature massive "
		"à cornes, DEBOUT, trapue, les bras le long du corps, tête de monstre sans expression (un "
		"colosse de roche stylisé, visage peu détaillé), sur un SOCLE carré de pierre volcanique à deux "
		"degrés ; ≈ 1,3 case de large (≈ 210 px) × 1,8 case de haut (≈ 290 px).", [ANCRE_BARRIERE]),
	("INT_MUSEE_RESERVE_PLANCHE", ["REF_M_PUPITRE"],
		_PLANCHE_FORMAT.format(px=160) + "\nSUJET : TROIS éléments de la RÉSERVE du Musée de paléontologie "
		"d'Argenta (pierre claire, bois clair, verre) ; les cellules 4 à 6 restent VIDES.\n"
		"1 (ligne 1, à gauche) VITRINE_AMBRE_PLEINE : une VITRINE de verre sur socle de bois clair, vue de "
		"dessus en trois quarts, qui contient un gros MORCEAU D'AMBRE orange translucide poli (de la "
		"taille d'un ballon de rugby), calé sur un coussin de feutre ; AUCUNE forme dans l'ambre ; "
		"1 case de large (≈ 150 px) × 1,2 case de haut (≈ 190 px).\n"
		"2 (ligne 1, au milieu) VITRINE_AMBRE_VIDE : la MÊME vitrine VIDE (le coussin de feutre seul "
		"garde l'empreinte de l'ambre) ; mêmes dimensions.\n"
		"3 (ligne 1, à droite) CAISSES_FOUILLES : deux CAISSES de bois clair empilées côte à côte, "
		"couvercle cloué, remplies de paille, une pelle de fouille et un tamis posés dessus ; "
		"2 cases de large (≈ 320 px) × 1 case de haut (≈ 170 px).", [ANCRE_VITRINE]),
]

# Objets individuels (portrait ou paysage)
OBJETS = [
	("WORLD_BLDG_MUSEE_PORTE_ARRIERE", ["REF_BAT_MUSEE"],
		"la PORTE ARRIÈRE (porte de service) du Musée de paléontologie d'Argenta, un élément de façade "
		"vu de face, dessiné pour s'accoler à la façade est du bâtiment : MÊMES pierres, mêmes couleurs "
		"et même main que le bâtiment joint (REF_BAT_MUSEE : pierre claire, toit, encadrements). Une "
		"petite PORTE de bois sombre renforcée de fer d'1 case de large et 1,5 case de haut, sous un "
		"petit auvent de pierre, encadrée de chaînage de pierre ; deux marches de pierre ; un mur de "
		"pierre de 2 cases de large autour ; fermée (porte close, pas de poignée lisible), aucun texte, "
		"aucune plaque. Largeur totale 2 cases (≈ 190 px), hauteur ≈ 2,3 cases ; la base du mur sur "
		"une ligne de sol droite.",
		"Format : PNG portrait 1024 × 1536, l'élément entier et centré.", 2.0),
]

# --------------------------------------------------------------------------------------------
# Personnages (marche 4 × 4 puis attente 4 × 1, 128 px)
# --------------------------------------------------------------------------------------------
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
## (fiche, joints_refs, joints_ancres, id préparé, look, rôle, tenue, pose d'attente)
PERSONNAGES = [
	("PNJ_PILLARD", ["REF_A_PILLARD"], ["PNJ_VIEIL_HOMME_NE_r1"], "pillard", "burglar",
		"un Pillard, Dresseur du Manoir et de l'Arène de Cramois'Île",
		"un PILLARD d'environ 35 ans, l'air louche mais pas méchant : BONNET de laine bleu marine "
		"enfoncé jusqu'aux sourcils, ÉCHARPE rouge brique remontée sur le menton, VESTE de travail brune "
		"usée à grosses poches, pantalon brun foncé, bottes de cuir, un gros SAC de toile (le butin) sur "
		"le dos. Taille d'un adulte, un peu voûté. Différent du héros et du vieil homme joint ; aucun "
		"masque de cambrioleur à rayures, aucun texte.",
		f"{PIEDS_JOINTS}, les mains dans les poches de sa veste, le regard de côté"),
	("PNJ_AUGUSTE", ["REF_A_PNJ"], ["PNJ_VIEIL_HOMME_NE_r1"], "auguste", "blaine",
		"Auguste, Champion de l'Arène de Cramois'Île, le maître du quiz au sang chaud",
		"AUGUSTE, Champion de type Feu, un vieux savant excentrique d'environ 65 ans, sec et énergique : "
		"crâne CHAUVE avec deux touffes de cheveux blancs sur les côtés, épaisse MOUSTACHE blanche en "
		"guidon, petites LUNETTES RONDES à verres sombres, long SARRAU de laboratoire BLANC CRÈME dont le "
		"bas est bordé d'une bande ORANGE avec des petites flammes stylisées (un motif de flammes, jamais "
		"un cercle), pantalon brun, sandales de cuir sur chaussettes blanches. Taille d'un adulte, "
		"menu. Différent du vieil homme joint (autre visage, autre tenue) ; aucun texte.",
		f"{PIEDS_JOINTS}, les mains derrière le dos, le menton levé, l'air fier et espiègle"),
]
## Réutilisés (pas de génération) : Intello (J20, série 22), Scientifique (`chercheur`), guide de
## l'Arène (`guide_arene`, série 14).

# --------------------------------------------------------------------------------------------
# Dos de combat (provisoires IA : modèles 3D X/Y de ces espèces absents, Colab non lancé)
# --------------------------------------------------------------------------------------------
## (id fiche, n°, nom, ancre de dos, sujet)
DOS = [
	("DOS_PONYTA", "077", "PONYTA (n° 077)", "dos_ia_004",
		"un poney de feu : petit cheval à robe CRÈME, dont la crinière et la queue sont de flammes "
		"orange et jaunes (flammes peintes, nettes, SANS halo), sabots jaune pâle ; quatre pattes fines, "
		"vu de dos : la croupe, la queue enflammée qui retombe, la crinière de flammes qui monte entre les "
		"oreilles."),
	("DOS_GALOPA", "078", "GALOPA (n° 078)", "dos_ia_004",
		"un grand cheval de feu : robe CRÈME, corne droite sur le front, crinière et queue de longues "
		"flammes orange et jaunes qui se dressent (flammes peintes, nettes, SANS halo), sabots jaune "
		"pâle ; musclé et élégant ; vu de dos : la croupe, la queue enflammée, la crinière de flammes."),
	("DOS_MAGMAR", "126", "MAGMAR (n° 126)", "dos_ia_004",
		"un Pokémon de feu bipède, trapu : corps de braise rouge-orange à ventre jaune, flamme sur la "
		"tête et au bout de la queue, bras puissants ; vu de dos : le dos rouge, la tête avec sa flamme, "
		"la queue qui part vers la droite."),
	("DOS_PTERA", "142", "PTÉRA (n° 142)", "dos_ia_016",
		"un grand ptérosaure fossile : corps gris-violet, ailes membraneuses repliées dans le dos, longue "
		"queue effilée, bec de crocs ; vu de dos : les ailes repliées en V, le dos écailleux, la queue."),
]

# --------------------------------------------------------------------------------------------
# Décors de combat CB.3 (hors assets/ : $ART/serie28/)
# --------------------------------------------------------------------------------------------
DECORS = [
	("manoir_salle", "COMBAT_DECOR_MANOIR_SALLE",
		"un grand SALON du Manoir Pokémon, à demi brûlé : au fond, un mur de boiseries sombres noircies "
		"de suie et de papier peint décollé, une GRANDE FENÊTRE aux vitres brisées par où entre un long "
		"rai de lumière dorée de fin d'après-midi, une cheminée de pierre éventrée, un fauteuil renversé, "
		"des étagères aux livres roussis, de la poussière en suspension ; au sol, un PARQUET de lattes "
		"de chêne noircies, quelques planches cassées et du plâtre tombé sur les côtés ; le fond est "
		"sombre, le centre du sol bien lisible.",
		"un salon brûlé en lumière dorée : le rai de la fenêtre brisée tombe sur le fond gauche, "
		"poussière dorée dans l'air, ombres violet-brun chaudes ; ambiance silencieuse et abandonnée, "
		"jamais effrayante ni sinistre.",
		", squelette, crâne, toile d'araignée, flamme vive, feu en gros plan, sang, fantôme"),
	("arene_cramois", "COMBAT_DECOR_ARENE_CRAMOIS",
		"la grande SALLE de l'Arène de Cramois'Île, une salle de volcan aménagée : au fond, un mur de "
		"blocs de roche volcanique violet-brun sombre, joints nets, avec deux BRASEROS de pierre dont "
		"les flammes sont petites et calmes, une herse de fer noir relevée dans une gaine ; des RIGOLES "
		"de braise orange très fines au pied du mur ; au sol, de larges DALLES de grès volcanique "
		"sable rosé aux joints fins ; de la chaleur qui fait trembler l'air près du mur (rendue par de "
		"fins reflets seulement), quelques braises qui flottent.",
		"chaude et martiale : lumière orange des braises sur le fond, sol clair et lisible au centre, "
		"ombres violet-brun ; énergique, jamais sombre ni inquiétante, aucune lave coulante au sol.",
		", lave coulante, grand incendie, flamme géante, silhouette de créature, machine, pupitre, statue, "
		"herse fermée"),
]

## Essais retenus (mis à jour après relecture ; voir la fiche).
RETENUS: dict[str, str] = {}
if (SORTIE / "retenus.json").exists():
	RETENUS = json.loads((SORTIE / "retenus.json").read_text())


# --------------------------------------------------------------------------------------------
# Prompts
# --------------------------------------------------------------------------------------------
def _ecrire(chemin: Path, texte: str) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	chemin.write_text(texte.strip() + "\n")
	print(chemin.relative_to(RACINE))


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_vues(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble VALIDÉES "
		"(petites, éclairées d'une lumière d'ambiance dorée ou orangée : n'en copie NI la lumière NI "
		"le flou ; redessine plus net, en lumière neutre) ; ")


def prompt_texture(ident: str, ref: str, description: str, r: int) -> str:
	ancre = ("" if r == 3 else f"{_noms(STYLE)} = ancres de style (rendu peint, finesse, lumière neutre). ")
	jointes = ("Images jointes : " + (f"{ref} = matériau et couleurs, extrait d'une vue d'ensemble validée "
		"(petit, lumière d'ambiance : n'en copie ni la lumière ni le flou) ; " if r != 2 else "")
		+ ancre) if r != 3 else "Aucune image jointe."
	return (f"{ident} — NOUVELLE image : une texture de sol de jeu, pas une scène.\n{jointes}\n\n{ADN}\n"
		f"{LUMIERE_INT}\n\nASSET : {description}\n{TEXTURE_FIN}\n{INTERDITS}\n")


def prompt_planche(ident: str, refs: list[str], description: str, ancres: list[str]) -> str:
	extra = (f"{_noms(ancres)} = ancres de style d'objets d'intérieur du jeu (rendu peint, contour coloré, "
		"finesse) : respecte-les. " if ancres else "")
	return (f"{ident} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages jointes : "
		f"{_jointes_vues(refs)}{extra}{_noms(STYLE)} = ancres de style (rendu peint, finesse, lumière "
		f"neutre).\n\n{ADN}\n{LUMIERE_INT}\n\nEXCEPTION à la règle « Isolement » de l'ADN : plusieurs "
		f"éléments séparés sur une même planche, chacun entier dans sa cellule, sans cadre ni séparation.\n"
		f"{description}\n{FIN_DETOURE}\n{INTERDITS}\n")


def prompt_objet(ident: str, refs: list[str], description: str, format_: str) -> str:
	return (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\nImages jointes : "
		f"{_jointes_vues(refs)}{_noms(STYLE)} = ancres de style (rendu peint, finesse, lumière neutre)."
		f"\n\n{ADN}\n{LUMIERE_NE}\n\nASSET : {description}\n{format_}\n{OBJET_FIN}\n{INTERDITS}\n")


def prompt_marche(ident: str, refs: list[str], ancres: list[str], tenue: str) -> str:
	import serie18 as s18
	texte = ""
	if refs:
		texte += (f" ; {', '.join(refs)} = tenue et silhouette seulement (petites, extraites de la vue "
			"d'ensemble validée, rendu à NE PAS copier)")
	if ancres:
		texte += (f" ; {_noms(ancres)} = même main et même finesse pour un adulte (à NE PAS copier : "
			"autre visage, autre tenue)")
	return s18.MODELE_MARCHE.format(ident=ident, ref=texte, tenue=tenue) + INTERDITS + "\n"


def prompt_attente(ident: str, role: str, tenue: str, pose: str) -> str:
	import serie18 as s18
	texte = s18._prompt_attente(ident, role, 128, tenue, pose)
	return texte.replace(s18.INTERDITS, INTERDITS)


DOS_TEXTE = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). {nom}

{ancres}

SUJET : {sujet}

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit le dos et l'arrière de la tête, au plus un peu du profil ; aucun visage de face. Pose de combat : prête, attentive.

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance. Les flammes éventuelles sont peintes nettes, sans halo ni lueur sur le fond.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE, centrée, qui occupe environ 85 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe.
{fin}
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage."""

DOS_ANCRES = {
	1: ("IMAGE 1 : l'artwork officiel de face de ce Pokémon : anatomie, couleurs, proportions et style de "
		"rendu (pas la pose : on le veut de dos).\nIMAGE 2 : un autre Pokémon de dos déjà produit pour ce "
		"jeu : reprends son ANGLE de vue (trois quarts dos, regard vers le haut à droite), son cadrage et "
		"sa famille de rendu ; ne reprends ni sa forme ni ses couleurs."),
	2: ("IMAGE 1 : une illustration de face de la créature : couleurs, proportions et style (pas la "
		"pose).\nIMAGE 2 : une autre créature vue de dos dans ce jeu : reprends son ANGLE de vue et son "
		"cadrage, pas sa forme."),
	3: "Aucune image jointe.",
}


def prompt_dos(nom: str, sujet: str, r: int) -> str:
	if r == 1:
		titre = f"Le Pokémon est {nom}, de la première génération."
	else:
		titre = "La créature est un monstre de jeu vidéo original, décrit ci-dessous."
		nom_court = nom.split(" (")[0]
		sujet = sujet.replace(nom_court, "la créature")
	return DOS_TEXTE.format(nom=titre, ancres=DOS_ANCRES[r], sujet=sujet, fin=FIN_DETOURE)


_DECOR_FORMAT = ("COMPOSITION (fractions depuis le coin haut gauche) :\n"
	"- Le haut (0 à 40 %) : le mur du fond et ses éléments, base du mur vers 38 % de la hauteur, calme "
	"en haut à gauche.\n- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT, très lisible.")
_DECOR_TUILE = """AGRANDISSEMENT D'UNE PORTION DE DÉCOR (Kanto 2026). L'image jointe est une portion d'un décor peint ({lieu}). Produis EXACTEMENT LA MÊME IMAGE, à une résolution plus élevée, avec plus de finesse dans la peinture.

RÈGLES ABSOLUES :
- Même cadrage au pixel près : même largeur et même hauteur relatives, chaque élément exactement à la même place et à la même taille. N'ajoute rien, n'enlève rien, ne déplace rien, ne recadre pas, ne prolonge pas l'image.
- Mêmes couleurs, même lumière, même style (illustration 2D peinte « HD-2D peint », masses douces, aucun trait noir).
- Seulement plus de netteté et de détails fins dans le pinceau, comme une version haute définition du même tableau.
- Aucun flou, aucun texte, aucune inscription, aucun personnage, aucune créature, aucun cadre.

FORMAT : même rapport largeur / hauteur que l'image jointe (environ 1,17 : 1, légèrement plus large que haute), la plus grande résolution possible, OPAQUE."""


def prompt_decor(titre: str, lieu: str, lumiere: str, interdits: str) -> str:
	import serie18 as s18
	return s18._prompt_decor(titre, "la vue d'ensemble (de dessus) validée du lieu : matières et palette "
		"à reprendre, vues ici à hauteur d'yeux (guide de palette et de matières, pas de composition).",
		s18._INTERIEUR, lieu, _DECOR_FORMAT, lumiere, interdits).replace("nom de navire, ", "")


def prompts() -> None:
	for ident, _, ref, desc in TEXTURES:
		for r in (1, 2, 3):
			_ecrire(PROMPTS / f"{ident}_NE_r{r}.txt", prompt_texture(ident, ref, desc, r))
	for ident, refs, desc, ancres in PLANCHES:
		_ecrire(PROMPTS / f"{ident}_NE_r1.txt", prompt_planche(ident, refs, desc, ancres))
	for ident, refs, desc, format_, _cases in OBJETS:
		_ecrire(PROMPTS / f"{ident}_NE_r1.txt", prompt_objet(ident, refs, desc, format_))
	for ident, refs, ancres, _pid, _look, role, tenue, pose in PERSONNAGES:
		_ecrire(PROMPTS / f"{ident}_NE_r1.txt", prompt_marche(ident, refs, ancres, tenue))
		_ecrire(PROMPTS / f"{ident.removeprefix('PNJ_')}_ATTENTE_r1.txt",
			prompt_attente(ident, role, tenue, pose))
	for ident, _num, nom, _anc, sujet in DOS:
		for r in (1, 2, 3):
			_ecrire(PROMPTS / f"{ident}_r{r}.txt", prompt_dos(nom, sujet, r))
	for did, ident, lieu, lumiere, interdits in DECORS:
		_ecrire(PROMPTS_DECOR / f"{ident}_r1.txt", prompt_decor(did.upper(), lieu, lumiere, interdits))
		_ecrire(PROMPTS_DECOR / f"{ident}_TUILE_r1.txt", _DECOR_TUILE.format(
			lieu=f"décor de combat « {did} »"))
	_ecrire(PROMPTS / "README.txt", __doc__ or "")


# --------------------------------------------------------------------------------------------
# Références, ancres, commandes
# --------------------------------------------------------------------------------------------
def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for nom in ANCRES:
		if (ART / nom).exists():
			continue
		for source in (PRINCIPAL / nom, J20_ART / nom):
			if source.exists():
				shutil.copy(source, ART / nom)
				print("copié", nom, "<-", source.parent)
				break
		else:
			print("MANQUE", nom)


def refs() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for nom, (vue, boite) in REFS.items():
		im = Image.open(vue).convert("RGB").crop(boite)
		im = im.resize((im.width * 3, im.height * 3), Image.LANCZOS)
		im.save(ART / f"{nom}.png")
		print(ART / f"{nom}.png", im.size)
	shutil.copy(RACINE / ANCRE_MUSEE_BAT, ART / "REF_BAT_MUSEE.png")


def _chemin_jointe(nom: str) -> str:
	if "/" in nom:
		return str(RACINE / nom) if not nom.startswith("/") else nom
	return str(ART / (nom if nom.endswith(".png") else nom + ".png"))


def jointes() -> dict[str, list[str]]:
	"""Identifiant d'essai -> images jointes, dans l'ordre des « IMAGE n » des prompts."""
	j: dict[str, list[str]] = {}
	for ident, _, ref, _ in TEXTURES:
		j[f"{ident}_NE_r1"] = [ref, *STYLE]
		j[f"{ident}_NE_r2"] = [*STYLE]
		j[f"{ident}_NE_r3"] = []
	for ident, refs_, _, ancres_ in PLANCHES:
		j[f"{ident}_NE_r1"] = [*refs_, *ancres_, *STYLE]
	for ident, refs_, _, _, _ in OBJETS:
		j[f"{ident}_NE_r1"] = [*[r if r != "REF_BAT_MUSEE" else r for r in refs_], *STYLE]
	for ident, refs_, ancres_, *_ in PERSONNAGES:
		j[f"{ident}_NE_r1"] = [HEROS, *refs_, *ancres_]
		j[f"{ident.removeprefix('PNJ_')}_ATTENTE_r1"] = [f"{ident}_NE_r1"]
	for ident, num, _, anc, _ in DOS:
		j[f"{ident}_r1"] = [str(OFFICIEL / f"{num}.png"), str(PROTO / f"{anc}.png")]
		j[f"{ident}_r2"] = [str(OFFICIEL / f"{num}.png"), str(PROTO / f"{anc}.png")]
		j[f"{ident}_r3"] = []
	for did, ident, *_ in DECORS:
		vue = "REF_M_SALLE" if did == "manoir_salle" else "REF_A_SALLE"
		j[f"{ident}_r1"] = [str(REFERENCE / "combat-v1.webp"),
			str(REFERENCE / "combat-decors-planche-v1.webp"), vue]
	return j


VAGUES = {
	1: ["WORLD_GROUND_PARQUET_MANOIR_01_NE_r1", "WORLD_GROUND_MASSE_MANOIR_01_NE_r1",
		"WORLD_RELIEF_MUR_MANOIR_PLANCHE_NE_r1"],
	2: ["INT_MANOIR_PLANCHE_A_NE_r1", "INT_MANOIR_PLANCHE_B_NE_r1",
		"WORLD_DECALS_GRAVATS_MANOIR_PLANCHE_NE_r1"],
	3: ["WORLD_GROUND_CARRELAGE_B1_01_NE_r1", "WORLD_GROUND_MASSE_MANOIR_B1_01_NE_r1",
		"WORLD_RELIEF_MUR_MANOIR_B1_PLANCHE_NE_r1"],
	4: ["WORLD_GROUND_DALLES_ARENE_01_NE_r1", "WORLD_GROUND_MASSE_ARENE_01_NE_r1",
		"WORLD_RELIEF_MUR_ARENE_PLANCHE_NE_r1", "INT_ARENE_PLANCHE_NE_r1"],
	5: ["INT_MUSEE_RESERVE_PLANCHE_NE_r1", "WORLD_BLDG_MUSEE_PORTE_ARRIERE_NE_r1"],
	6: ["PNJ_PILLARD_NE_r1", "PNJ_AUGUSTE_NE_r1"],
	7: ["PILLARD_ATTENTE_r1", "AUGUSTE_ATTENTE_r1"],
	8: ["DOS_PONYTA_r1", "DOS_GALOPA_r1", "DOS_MAGMAR_r1", "DOS_PTERA_r1"],
	9: ["COMBAT_DECOR_MANOIR_SALLE_r1", "COMBAT_DECOR_ARENE_CRAMOIS_r1"],
}


def _fichier_prompt(ident: str) -> Path:
	if ident.startswith("COMBAT_DECOR"):
		return PROMPTS_DECOR / f"{ident}.txt"
	return PROMPTS / f"{ident}.txt"


def commandes(vague: int | None = None) -> None:
	j = jointes()
	for v, idents in VAGUES.items():
		if vague and v != vague:
			continue
		print(f"# vague {v}")
		for ident in idents:
			images = " ".join(_chemin_jointe(x) for x in j[ident])
			print("tools/art/generer.sh %s %s %s" % (ident,
				_fichier_prompt(ident).relative_to(RACINE), images))


def _generer_un(ident: str) -> str:
	images = [_chemin_jointe(x) for x in jointes()[ident]]
	resultat = subprocess.run([str(ICI / "generer.sh"), ident, str(_fichier_prompt(ident)), *images],
		cwd=RACINE, capture_output=True, text=True)
	if resultat.returncode == 0:
		return f"{ident} : ok"
	return f"{ident} : ÉCHEC {resultat.stderr.strip()[-300:]}"


def generer(idents: list[str]) -> None:
	"""Lance generer.sh pour chaque identifiant (trois à la fois) ; numéro de vague accepté."""
	from concurrent.futures import ThreadPoolExecutor
	liste: list[str] = []
	for i in idents:
		liste += VAGUES[int(i)] if i.isdigit() else [i]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(_generer_un, liste):
			print(ligne, flush=True)


# --------------------------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------------------------
def main() -> None:
	args = sys.argv[1:]
	ART.mkdir(parents=True, exist_ok=True)
	if not args or args[0] == "--prompts":
		prompts()
	elif args[0] == "--ancres":
		ancres()
	elif args[0] == "--refs":
		refs()
	elif args[0] == "--commandes":
		commandes(int(args[1]) if len(args) > 1 else None)
	elif args[0] == "--generer":
		generer(args[1:])
	else:
		import serie28_suite  # noqa: F401  (préparation, cartes, contrôle : ajoutés après la génération)
		serie28_suite.main(args)


if __name__ == "__main__":
	main()
