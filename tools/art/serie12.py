#!/usr/bin/env python3
"""Série 12 — Argenta et Route 2 nord (jalon 10, lumière neutre). Liste : docs/tech/jalon-10.md
§1.4 ; fiches : docs/design/fiches-assets/serie-12-argenta.md.

Méthode du J8 et du J9 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation de
la vue validée, `docs/design/reference/argenta-vue-generale-v1.png`, essai 2 ; **la grille fait
foi** : `tools/plans/argenta*.txt`, `route_2_nord.txt`, contrôlées par `plan_check_argenta.py`).
Presque tout est repris (sols, forêt serrée, arbres, hautes herbes, Centre, Boutique, meubles,
habitants) ; ne sont générées que **23 images** :
  - 7 décors : Musée, Arène, maison (×2 en jeu), planche de paroi (4 modules), rocher de la
    place, blocs du tailleur, poste de la forêt vu du nord ;
  - 5 personnages × (marche + attente) : Pierre, tailleur, Montagnard, Campeur, guide d'Arène ;
  - 1 Pokémon d'ambiance immobile (format « Pokémon fixe » du J9) : Racaillou ;
  - 3 coques (Musée pour deux salles, Arène, maison pour deux maisons) et 2 planches de meubles
    (Musée : vitrines, porte du laboratoire, panneau ; Arène : pilier et rochers).
CONDITIONNELS (jamais lancés sans leur nom ; décision sur capture du T11, notée dans
etat-projet.md) : WORLD_PROP_EBOULIS_01, WORLD_PROP_ROCHER_ROUTE2N_01 ; UI_BADGE_ROCHE seulement
si Kevin le demande.

**Les prompts sont versionnés** : `tools/art/prompts/serie12/<NOM>.txt` (un par image) et
`tools/art/attente/prompts/<NOM>_ATTENTE.txt`, écrits par `--prompts` à partir des tables
ci-dessous ; la génération lit ces fichiers. Corriger une image = corriger la table, relancer
`--prompts`, relire le diff ; une correction après génération se lance en `_r2` (fiche).
Références : recadrages REF_AR_* de la vue validée (`--refs`, boîtes ci-dessous, agrandies × 3).
Sources et sorties dans $ART (défaut : build/art de cette copie ; sur une autre copie que le
checkout principal, ART=/Users/kevinyankam/dev/kanto-2026/build/art, où sont les ancres).

Usage :
  tools/art/serie12.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie12.py --refs                  recadre les REF_AR_* dans $ART (sans Codex)
  tools/art/serie12.py --commandes             liste les commandes generer.sh du T2 (sans Codex)
  tools/art/serie12.py --planche [sortie.png]  planche de contrôle du kit (sans Codex ;
                                               défaut build/art/AR_KIT_v1.png)
  tools/art/serie12.py --manifeste             ajoute les entrées de la série 12 en fin de
                                               tools/art/manifeste.json (T10, après le J9 et la
                                               validation des images ; NE PAS lancer avant)
  tools/art/serie12.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T10 ;
                                               défaut build/captures/jalon10_assets/serie12_controle.png)
  tools/art/serie12.py [IDENTIFIANT ...]       génère avec Codex, en deux vagues (sans argument :
                                               la série, sans les conditionnels ; --refs d'abord)
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
from plan_check_argenta import EMPRISES  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _miroir, _Planche, _teinter)

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
VUE = RACINE / "docs/design/reference/argenta-vue-generale-v1.png"
PROMPTS = ICI / "prompts" / "serie12"
ATTENTES = ICI / "attente" / "prompts"

## Recadrages de la vue validée (1024 × 1536, ≈ 18 px par case), en pixels de la vue.
REFS = {
	"REF_AR_MUSEE": (66, 526, 352, 742),
	"REF_AR_ARENE": (586, 56, 850, 232),
	"REF_AR_MAISON": (62, 262, 214, 398),
	"REF_AR_PAROI": (0, 0, 600, 140),
	"REF_AR_RELIEF_ROUTE": (575, 925, 985, 1165),
	"REF_AR_ROCHER_PLACE": (462, 322, 562, 398),
	"REF_AR_BLOCS": (52, 412, 138, 492),
	"REF_AR_TAILLEUR": (132, 396, 174, 460),
	"REF_AR_RACAILLOU": (166, 404, 220, 450),
	"REF_AR_POSTE": (418, 1415, 585, 1532),
	"REF_AR_PLACE": (250, 280, 820, 470),
	"REF_AR_ROCHER_ROUTE": (468, 1032, 550, 1098),
	# Écarts de la vue volontairement non reproduits (dossier 12, « Vue générale peinte v1 »).
	"REF_AR_DECROCHEMENT": (185, 975, 420, 1130),
	"REF_AR_MONTAGNARD": (578, 972, 634, 1058),
	"REF_AR_CAISSES": (674, 538, 714, 602),
}
AGRANDIR = 3

## Ancres de style (images validées des séries précédentes, dans $ART).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
POSTE = "WORLD_BLDG_POSTE_FORET_01_NE_r1.png"
HEROS = "PERSO_P2_PEINT_r1.png"
RATTATA = "POKE_RATTATA_P2_r1.png"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo (sauf l'emblème demandé), "
	"animaux réels ou faune non-Pokémon (oiseaux, papillons, insectes, chats, chiens), Pikachu et tout "
	"Pokémon non demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos "
	"jaune).")


def _emprise(carte: str, car: str) -> tuple[int, int]:
	largeur, hauteur, _, _ = EMPRISES[carte][car]
	return largeur, hauteur


# --- Tables ------------------------------------------------------------------------------

## Décors : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, vague). Vague 2 = attend une image de la vague 1.
MUSEE = _emprise("argenta", "M")
ARENE = _emprise("argenta", "Z")
MAISON = _emprise("argenta", "m")
POSTE_NORD = _emprise("route_2_nord", "P")
SERIE = [
	("WORLD_BLDG_MUSEE_ARGENTA_01", "REF_AR_MUSEE", MUSEE[0], MUSEE[1],
		"le Musée d'Argenta, le plus grand bâtiment de la ville et son premier repère : bâtiment de "
		"PIERRE claire gris-beige d'un étage, large, bas et symétrique ; grand toit à deux pans de "
		"TUILES brun chocolat avec un fronton central un peu plus haut ; au centre de la façade, un "
		"PORTIQUE de quatre COLONNES de pierre claire sous un fronton arrondi percé d'une fenêtre en "
		"demi-lune ; sous le portique, une DOUBLE PORTE de bois brun de 2 cases de large, au milieu "
		"exact du bas de la façade (6e et 7e colonnes sur 12), une marche de pierre ; de chaque côté, "
		"deux hautes fenêtres cintrées à petits carreaux bleutés ; soubassement de pierre plus foncée, "
		"corniche moulurée. Savant, calme et accueillant. Aucune inscription, aucune enseigne, aucun "
		"drapeau, aucun fossile ni squelette sur la façade ; sans arbres, sans pavés, sans panneau, "
		"sans massifs de fleurs (posés par la carte).",
		["WORLD_BLDG_LABO_01_NE_r1.png", POSTE], 1),
	("WORLD_BLDG_ARENE_ARGENTA_01", "REF_AR_ARENE", ARENE[0], ARENE[1],
		"l'Arène d'Argenta, une forteresse de pierre adossée à la montagne, deuxième repère de la "
		"ville : bâtiment massif et BAS en gros blocs de PIERRE grise appareillés ; toit d'ARDOISES "
		"gris-bleu à faible pente ; deux piliers d'angle carrés et massifs aux coins avant, coiffés "
		"d'un chapiteau de pierre qui dépasse un peu du toit ; au centre, un avant-corps d'entrée en pierre plus claire au linteau épais, "
		"surmonté d'un MÉDAILLON de pierre sculpté d'un motif OCTOGONAL simple (le seul emblème "
		"autorisé, sans lettre) ; DOUBLE PORTE de bois brun cerclée de fer, 2 cases de large, au milieu "
		"exact du bas de la façade (6e et 7e colonnes sur 12) ; fenêtres étroites ; des ROCHERS bruts "
		"gris-beige pris dans la maçonnerie aux deux coins arrière, comme si le bâtiment sortait de la "
		"roche. Imposante mais pas menaçante. Plus basse, plus large et plus minérale que l'Arène de "
		"Jadielle jointe (à ne pas copier). Aucune inscription, aucun drapeau ; sans arbres ni pavés.",
		["WORLD_BLDG_ARENE_01_NE_r1.png", POSTE], 1),
	("WORLD_BLDG_MAISON_ARGENTA_01", "REF_AR_MAISON", MAISON[0], MAISON[1],
		"une maison d'habitant d'Argenta, plus grande et plus minérale que celles de Jadielle : murs "
		"de PIERRE claire gris-beige appareillée (pas d'enduit crème), toit à deux pans de TUILES "
		"rouge-orangé, cheminée de pierre à gauche ; porte de bois brun d'une case au MILIEU exact du "
		"bas de la façade (4e colonne sur 7) sous un linteau de pierre, une marche de pierre ; une "
		"fenêtre à petits carreaux de chaque côté de la porte avec une jardinière discrète ; "
		"soubassement de pierre plus foncée. Rien de personnel (elle sert deux fois). Sans clôture, "
		"sans boîte aux lettres, sans plantes au sol.",
		["WORLD_BLDG_MAISON_A_01_NE_r1.png"], 1),
	("WORLD_PROP_ROCHER_PLACE_01", "REF_AR_ROCHER_PLACE", 3, 2.6,
		"le gros rocher de la place d'Argenta, quatrième repère de la ville : UN SEUL énorme bloc "
		"arrondi de GRANIT gris clair un peu chaud, presque aussi haut que large, surface grenue et "
		"mouchetée, quelques facettes douces, une longue fissure, lichen ocre discret, base large et "
		"stable. Plus haut, plus massif et plus grenu que la grande pierre lisse jointe (Route 2, à ne "
		"pas copier). Ni socle, ni herbe, ni fleurs autour.",
		["WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png"], 1),
	("WORLD_PROP_BLOCS_TAILLES_01", "REF_AR_BLOCS", 3, 1.6,
		"le chantier du tailleur de pierre, posé au sol sur 3 cases de large et 2 de profondeur : deux "
		"piles de blocs de pierre claire taillés au carré (une de trois blocs, une de deux), un bloc à "
		"moitié dégrossi posé devant, un maillet de bois et un ciseau posés sur un bloc, quelques éclats "
		"de pierre au pied, un petit chevalet de bois. Au plus 1,6 case de haut. Sans personnage ni "
		"Pokémon.",
		["WORLD_PROP_ROCHER_01_NE_r1.png"], 1),
	("WORLD_BLDG_POSTE_FORET_NORD_01", "REF_AR_POSTE", POSTE_NORD[0], POSTE_NORD[1],
		"le poste de garde de la Forêt de Jade VU DEPUIS LE NORD : le même bâtiment que la façade jointe "
		"WORLD_BLDG_POSTE_FORET_01 (mêmes ardoises gris-bleu, même pierre claire, mêmes poutres), dont "
		"on ne voit ici que le HAUT, dans la même vue de trois quarts depuis le sud que tout le jeu : le "
		"TOIT d'ardoises à deux pans occupe presque toute l'image, vu de dessus, faîtage horizontal ; "
		"au MILIEU du bord HAUT de l'image, un petit avant-corps d'entrée bas en pierre claire, coiffé "
		"de son propre petit toit d'ardoises, dont l'OUVERTURE de porte, sombre et vide, d'une case de "
		"large, donne vers le haut de l'image (le nord) : un seuil de pierre et un paillasson brun "
		"devant elle. Le bas de l'image est coupé NET à l'horizontale (le reste du bâtiment est hors de "
		"la carte). Environ 7 cases de large et 3 de haut. La référence REF_AR_POSTE montre le poste de "
		"face : n'en garde que les matériaux, PAS l'angle ni la porte en bas.",
		[POSTE], 1),
]

## Planche de paroi (2 × 2 modules de 4 × 3 cases) : identifiant, références, description.
PAROI = ("WORLD_RELIEF_PAROI_PLANCHE", ["REF_AR_PAROI", "REF_AR_RELIEF_ROUTE"],
	"PLANCHE de 4 modules de PAROI ROCHEUSE de montagne (troisième repère d'Argenta : la montagne au "
	"nord de la ville, et le bloc rocheux de la Route 2 nord), dans une image 1536 × 1024 : grille "
	"invisible de 2 colonnes × 2 lignes (cellules de 768 × 512), un module par cellule, centré, la base "
	"de chaque module sur une même ligne horizontale à 30 px du bas de sa cellule. Chaque module fait "
	"4 cases de large et 3 de haut (environ 680 × 510 px : 1 case = 170 px). Roche beige-gris chaud en "
	"grandes FACETTES VERTICALES et en gradins, arêtes claires du côté éclairé, ombres propres bleu-gris, "
	"quelques touffes d'herbe et petits buissons sur les replats, rien de pointu ni de menaçant.\n"
	"Module 1 (en haut à gauche) : FACE de paroi A, falaise verticale vue de face, crête irrégulière en "
	"haut, pied droit en bas. Module 2 (en haut à droite) : FACE de paroi B, même hauteur, une faille "
	"verticale et un petit éboulis au pied ; les modules 1 et 2 se raccordent bout à bout par leurs bords "
	"gauche et droit. Module 3 (en bas à gauche) : EXTRÉMITÉ GAUCHE de la paroi, qui descend en gradins "
	"vers la gauche et finit en gros blocs posés au sol. Module 4 (en bas à droite) : DESSUS DE MASSIF, "
	"amas serré de pitons et de blocs rocheux vus de dessus en trois quarts, sans face avant nette, "
	"pour remplir l'intérieur d'un massif : il se raccorde sur ses quatre côtés.\n"
	"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
	["WORLD_RELIEF_FALAISE_01_NE_r1.png", "WORLD_PROP_ROCHER_01_NE_r1.png"])

## Coques : (identifiant, largeur, profondeur, ancres, géométrie, matériaux, vague).
_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus. Tout le reste est du SOL, entièrement libre et vide.")
COQUES = [
	("INT_MUSEE_COQUE", 15, 10, ["INT_CENTRE_COQUE_NE_r1.png", "INT_LABO_COQUE_NE_r1.png",
		"WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png"],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 15 cases de large × 10 de profondeur "
		"(1 case ≈ 102 px). " + _BASE_COQUE + " Face avant du mur du fond sur les 2,5 cases du haut "
		"(≈ 256 px) ; épaisseur des murs latéraux ≈ 40 px ; épaisseur du mur du bas ≈ 50 px, "
		"interrompue au milieu par l'ENTRÉE : une ouverture de 2 cases (≈ 204 px) centrée, avec un "
		"paillasson. Au MILIEU du mur du fond, une grande ARCHE ouverte de 3 cases de large (≈ 306 px), "
		"sans porte, jusqu'au sol : on n'y voit que le sol qui continue et une lumière claire et neutre "
		"(la salle suivante, sans aucun détail). L'arche et l'entrée sont exactement l'une au-dessus de "
		"l'autre, au centre. Cette enveloppe sert aux DEUX salles du Musée.",
		"le Musée d'Argenta, mêmes matériaux que la façade jointe WORLD_BLDG_MUSEE_ARGENTA_01 : sol de "
		"grandes dalles de pierre claire polies, beige très pâle, bordure de pierre plus sombre le long "
		"des murs ; mur du fond en pierre de taille claire, pilastres réguliers, corniche moulurée en haut, "
		"une haute fenêtre cintrée à petits carreaux de chaque côté de l'arche, deux appliques éteintes ; "
		"épaisseur des murs en pierre claire. Calme, silencieux, savant.", 2),
	("INT_ARENE_COQUE", 15, 11, ["INT_CENTRE_COQUE_NE_r1.png", "WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png"],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 15 cases de large × 11 de profondeur "
		"(la préparation l'étire à 1 440 × 1 056 : 1 case ≈ 102 px de large, ≈ 93 px de haut). "
		+ _BASE_COQUE + " Ici les murs sont de la ROCHE : mur du fond = paroi rocheuse claire dont on "
		"voit la face sur les 2 cases du haut ; murs latéraux = bandes de rochers naturels de 2 cases "
		"d'épaisseur à gauche et à droite, vues de dessus ; mur du bas = une rangée de rochers d'une "
		"case, interrompue au milieu par la SORTIE : une ouverture de 3 cases (≈ 306 px) centrée, avec "
		"un paillasson de pierre. Juste sous le mur du fond, au milieu, une ESTRADE basse de pierre "
		"claire de 3 cases de large et 1 de profondeur (la 3e rangée en partant du haut), surélevée d'une "
		"marche, face à la sortie. Au-dessus de l'estrade, sur la paroi du fond, un grand médaillon de "
		"pierre au motif OCTOGONAL (sans lettre). La sortie et l'estrade sont exactement l'une au-dessus "
		"de l'autre, au centre.",
		"l'Arène de Pierre, Champion de type Roche : salle de ROCHE CLAIRE beige-gris, SOL DE SABLE clair "
		"ocre, tassé, quelques traces douces et petits cailloux, aucune ligne de terrain ; lumière "
		"d'intérieur neutre et égale. Mêmes pierres que la façade jointe WORLD_BLDG_ARENE_ARGENTA_01. "
		"Sobre, minérale, solennelle sans être sombre.", 2),
	("INT_MAISON_ARGENTA_COQUE", 15, 10, ["INT_CENTRE_COQUE_NE_r1.png", "INT_MAISON_RIVAL_COQUE_NE_r1.png",
		"WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png"],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 15 cases de large × 10 de profondeur "
		"(1 case ≈ 102 px). " + _BASE_COQUE + " Face avant du mur du fond sur les 2,5 cases du haut "
		"(≈ 256 px) ; épaisseur des murs latéraux ≈ 40 px ; épaisseur du mur du bas ≈ 50 px, "
		"interrompue au milieu par l'ENTRÉE : une ouverture de 2 cases (≈ 204 px) centrée, avec un "
		"paillasson. Cette enveloppe sert à DEUX maisons (meubles différents) : rien de personnel.",
		"une maison d'Argenta, mêmes matériaux que la façade jointe WORLD_BLDG_MAISON_ARGENTA_01 : sol "
		"de larges planches de bois chaud ; mur du fond en pierre claire jusqu'à mi-hauteur puis enduit "
		"crème, poutres de bois apparentes en haut ; deux fenêtres à petits carreaux ; épaisseur des murs "
		"en pierre. Chaleureux et simple.", 2),
]

## Planches de meubles : (identifiant, ancres, description, vague).
PLANCHES = [
	("INT_MUSEE_PLANCHE", ["INT_VITRINE_POKEBALLS_01_NE_r1.png", "INT_ETAGERE_LABO_01_NE_r1.png",
		"WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png"],
		"PLANCHE de 6 meubles du Musée d'Argenta, dans une image 1536 × 1024 : grille invisible de "
		"3 colonnes × 2 lignes (cellules de 512 × 512), un meuble par cellule, centré, la base de chacun "
		"sur une même ligne horizontale à 40 px du bas de sa cellule, à une échelle COMMUNE : 1 case = "
		"150 px. Bois sombre ciré, laiton discret, verre clair légèrement bleuté (comme la vitrine "
		"jointe), pierre claire.\n"
		"1 (ligne 1, à gauche) : VITRINE basse de 2 cases de large (≈ 1,3 case de haut) contenant un "
		"FOSSILE en forme de DÔME : coquille brune arrondie et striée, sur un coussin. "
		"2 (ligne 1, au milieu) : VITRINE identique de 2 cases contenant un FOSSILE en SPIRALE (coquille "
		"enroulée gris-beige). 3 (ligne 1, à droite) : la PIERRE LUNE sous une cloche de verre, sur un "
		"socle de pierre claire d'une case de large (≈ 1,5 case de haut) : pierre sombre gris-bleu, "
		"bosselée, aux fines inclusions pâles. 4 (ligne 2, à gauche) : VITRINE plate inclinée de 2 cases "
		"contenant un vieux CARNET ouvert, pages jaunies couvertes de croquis effacés, aucune écriture "
		"lisible. 5 (ligne 2, au milieu) : PORTE DU LABORATOIRE, 3 cases de large et 2,5 de haut, faite "
		"pour fermer une arche : double porte métallique gris-bleu FERMÉE (2 cases, à droite) avec un "
		"petit hublot rond et un petit voyant rouge, et à sa gauche, dans le même encadrement de pierre "
		"claire, une PLAQUE murale rectangulaire claire, VIERGE. 6 (ligne 2, à droite) : PANNEAU "
		"D'EXPOSITION sur pieds de bois, 2 cases de large (≈ 1,8 case de haut) : formes abstraites de "
		"coquilles et de spirales reliées par des flèches, aucun Pokémon reconnaissable, aucun mot.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.", 2),
	("INT_ARENE_ROCHERS_PLANCHE", ["WORLD_PROP_ROCHER_01_NE_r1.png", "WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png"],
		"PLANCHE de 3 formations rocheuses d'intérieur pour l'Arène d'Argenta (roche claire beige-gris, "
		"posées sur un sol de sable), dans une image 1536 × 1024 : grille invisible de 3 colonnes "
		"(cellules de 512 × 1024), un élément par colonne, centré, la base des trois sur une même ligne "
		"horizontale à 60 px du bas, à une échelle COMMUNE : 1 case = 180 px.\n"
		"1 (à gauche) : PILIER naturel de roche, 2 cases de large × 1 de profondeur, environ 2,8 cases "
		"de haut, massif et strié, sommet arrondi. 2 (au milieu) : BLOC de rochers bas, 2 cases × 2, "
		"amas de 3 ou 4 rochers arrondis d'environ 1,5 case de haut. 3 (à droite) : un ROCHER seul d'une "
		"case, environ 1 case de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.", 2),
]

## Personnages (marche + attente) : (identifiant, référence ou None, hauteur en jeu, rôle court,
## tenue, mains au repos). Tenues = défauts (règle 4).
PERSONNAGES = [
	("PNJ_PIERRE", None, 128, "Pierre, Champion de l'Arène d'Argenta",
		"Pierre, le Champion de l'Arène d'Argenta, jeune homme d'une vingtaine d'années, calme, solide et "
		"posé, JAMAIS arrogant (ni bras croisés, ni sourire moqueur) : peau hâlée, cheveux brun foncé "
		"en épis courts et drus, yeux plissés au regard tranquille, carrure large ; gilet sans manches "
		"vert olive ouvert sur un t-shirt orange brique, pantalon de toile brun, ceinture brune, "
		"chaussures de marche brun foncé. Fidèle au Pierre de Pokémon Rouge/Bleu ; aucun insigne, aucun "
		"texte.",
		"les deux bras détendus le long du corps, le buste droit, l'air calme"),
	("PNJ_TAILLEUR", "REF_AR_TAILLEUR", 128, "le tailleur de pierre d'Argenta",
		"le tailleur de pierre d'Argenta, homme d'une quarantaine d'années, robuste et tranquille : "
		"cheveux bruns courts, sourcils épais, rasé, long TABLIER DE CUIR brun sur une chemise blanche aux "
		"manches retroussées, gros gants de travail gris, pantalon gris foncé, chaussures de travail "
		"brunes, un petit maillet de bois passé à la ceinture (tenue de la vue validée). Différent du "
		"Marchand de Jadielle (tablier bleu, moustache, chemise rayée).",
		"les deux bras détendus le long du corps, le maillet reste à la ceinture"),
	("PNJ_MONTAGNARD", None, 132, "le Montagnard de la Route 2 nord",
		"un Montagnard (randonneur de montagne) qui revient d'Argenta, homme d'une quarantaine d'années, "
		"grand et costaud (un peu plus grand que les autres adultes) : barbe brune fournie, BOB de toile "
		"kaki, chemise à carreaux rouge et brun aux manches retroussées, pantalon de toile vert olive, "
		"grosses chaussures de montagne, GROS sac à dos vert sapin à armature avec une corde enroulée et "
		"une gamelle accrochées. Différent de la Randonneuse de la Route 2 (chapeau de paille, sac "
		"orange) : ni paille ni orange.",
		"les deux pouces glissés sous les bretelles du sac à dos"),
	("PNJ_CAMPEUR", None, 112, "le Campeur Liam, Dresseur de l'Arène d'Argenta",
		"le Campeur Liam, Dresseur de l'Arène d'Argenta, garçon d'environ 12 ans, PLUS PETIT que les "
		"adultes (environ 85 % de la taille du héros), énergique : cheveux noirs courts en épis, SANS "
		"couvre-chef, FOULARD ROUGE noué autour du cou, chemise de camp beige à manches courtes avec deux "
		"poches à rabat, short vert olive, chaussettes hautes grises, chaussures de marche brunes, petit "
		"sac de couchage roulé porté en bandoulière dans le dos. Différent du Scout (chapeau de paille, "
		"filet) et du héros (ni casquette rouge, ni t-shirt blanc, ni sac jaune).",
		"les deux bras détendus le long du corps, les poings légèrement serrés, prêt à se battre"),
	("PNJ_GUIDE_ARENE", None, 128, "le guide d'Arène (le même dans les huit Arènes)",
		"le guide d'Arène, homme d'une trentaine d'années jovial et accueillant, le même dans toutes les "
		"Arènes de Kanto : cheveux bruns courts, polo blanc à col et liserés bleu marine, pantalon de "
		"survêtement bleu marine, baskets blanches, serviette blanche autour du cou, une bouteille d'eau "
		"dans la main droite. Aucun insigne ni texte, rien qui le rattache à une ville.",
		"le bras gauche détendu le long du corps, la main droite tenant la bouteille d'eau le long du "
		"corps"),
]

## Pokémon d'ambiance immobile (format « Pokémon fixe » du J9) : (identifiant, référence,
## description, repos, réaction, hauteur en jeu).
POKEMON_FIXES = [
	("POKE_RACAILLOU_FIXE", "REF_AR_RACAILLOU",
		"Racaillou, le Pokémon Roche de Pokémon Rouge/Bleu, fidèle à son design officiel : une ROCHE "
		"ronde gris-brun un peu bosselée, SANS jambes, deux bras musclés de pierre aux grosses mains à "
		"cinq doigts, épais sourcils de roche au-dessus de petits yeux, bouche déterminée.",
		"posé au sol, les deux mains posées à plat devant lui, calme",
		"il SOULÈVE à deux mains au-dessus de sa tête une pierre claire presque aussi grosse que lui, "
		"fier (il « travaille » au chantier du tailleur)", 56),
]

## Conditionnels : (identifiant, référence, largeur, hauteur, description, ancres).
CONDITIONNELS = [
	("WORLD_PROP_EBOULIS_01", "REF_AR_RELIEF_ROUTE", 1.6, 2.2,
		"des ÉBOULIS qui bouchent un sentier de montagne : amas haut de blocs de roche beige-gris cassés et "
		"empilés, quelques pierres roulées au pied, une touffe d'herbe ; clairement infranchissable, "
		"environ 1,6 case de large et 2 cases de profondeur. Pas de panneau, pas de barrière.",
		["WORLD_PROP_ROCHER_01_NE_r1.png"]),
	("WORLD_PROP_ROCHER_ROUTE2N_01", "REF_AR_ROCHER_ROUTE", 2.2, 1.6,
		"un rocher arrondi gris clair au bord d'un chemin de montagne, UN SEUL bloc, plus petit, plus "
		"gris et plus rugueux que la grande pierre lisse jointe (à ne pas copier), base large.",
		["WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png"]),
]
BADGE = ("UI_BADGE_ROCHE",
	"UI_BADGE_ROCHE — NOUVELLE image : l'emblème du Badge Roche, pour l'interface (pas un objet du monde)."
	"\nUn badge métallique gris argenté en forme d'OCTOGONE FACETTÉ, comme une pierre taillée, contour fin, "
	"reflets doux, vu strictement de face, centré, environ 700 px de large dans une image carrée 1024 × "
	"1024 ; fond avec une vraie transparence (canal alpha). Rendu peint net, contour coloré sans trait "
	"noir, lumière neutre venant du haut à gauche.\n" + INTERDITS + "\n")

## Entrées du manifeste (T10 seulement, en fin de chaque section ; sections du J9 comprises).
MANIFESTE = {
	"objets": [
		{"id": "bldg_musee_argenta_01", "source": "WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png",
			"sortie": "assets/world/buildings/bldg_musee_argenta_01.png", "axe": "w", "cases": MUSEE[0],
			"ombre": True, "contact": 0.12},
		{"id": "bldg_arene_argenta_01", "source": "WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png",
			"sortie": "assets/world/buildings/bldg_arene_argenta_01.png", "axe": "w", "cases": ARENE[0],
			"ombre": True, "contact": 0.12},
		{"id": "bldg_maison_argenta_01", "source": "WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png",
			"sortie": "assets/world/buildings/bldg_maison_argenta_01.png", "axe": "w", "cases": MAISON[0],
			"ombre": True, "contact": 0.12},
		{"id": "bldg_poste_foret_nord_01", "source": "WORLD_BLDG_POSTE_FORET_NORD_01_NE_r1.png",
			"sortie": "assets/world/buildings/bldg_poste_foret_nord_01.png", "axe": "w",
			"cases": POSTE_NORD[0], "ombre": False, "contact": 0.0},
		{"id": "prop_rocher_place_01", "source": "WORLD_PROP_ROCHER_PLACE_01_NE_r1.png",
			"sortie": "assets/world/props/prop_rocher_place_01.png", "axe": "w", "cases": 3,
			"ombre": False, "contact": 0.15},
		{"id": "prop_blocs_tailles_01", "source": "WORLD_PROP_BLOCS_TAILLES_01_NE_r1.png",
			"sortie": "assets/world/props/prop_blocs_tailles_01.png", "axe": "w", "cases": 3,
			"ombre": False, "contact": 0.2},
	],
	# Planche 2 × 2 coupée comme les arbres de forêt (coupe la plus vide), hauteur 3 cases.
	"planches_arbres": [
		{"source": "WORLD_RELIEF_PAROI_PLANCHE_NE_r1.png", "dossier": "assets/world/relief/",
			"ids": ["relief_paroi_01", "relief_paroi_02", "relief_paroi_03", "relief_paroi_04"],
			"hauteurs_px": [288, 288, 288, 288], "contact": 0.0},
	],
	"pieces": [
		{"id": "int_musee_coque", "source": "INT_MUSEE_COQUE_NE_r1.png",
			"sortie": "assets/world/interiors/int_musee_coque.png", "cases": [15, 10]},
		{"id": "int_arene_coque", "source": "INT_ARENE_COQUE_NE_r1.png",
			"sortie": "assets/world/interiors/int_arene_coque.png", "cases": [15, 11]},
		{"id": "int_maison_argenta_coque", "source": "INT_MAISON_ARGENTA_COQUE_NE_r1.png",
			"sortie": "assets/world/interiors/int_maison_argenta_coque.png", "cases": [15, 10]},
	],
	# Section nouvelle (T10 : découpe d'une planche C × L en objets, à ajouter à preparer.py sur le
	# modèle de planches_arbres) : largeur en cases de chaque élément, dans l'ordre de lecture.
	"planches_objets": [
		{"source": "INT_MUSEE_PLANCHE_NE_r1.png", "dossier": "assets/world/interiors/",
			"colonnes": 3, "lignes": 2,
			"ids": ["int_vitrine_dome_01", "int_vitrine_nautile_01", "int_vitrine_pierre_lune_01",
				"int_vitrine_journal_01", "int_porte_labo_01", "int_panneau_expo_01"],
			"cases": [2, 2, 1, 2, 3, 2], "contact": 0.2},
		{"source": "INT_ARENE_ROCHERS_PLANCHE_NE_r1.png", "dossier": "assets/world/interiors/",
			"colonnes": 3, "lignes": 1,
			"ids": ["int_pilier_roche_01", "int_rochers_bas_01", "int_rochers_bas_02"],
			"cases": [2, 2, 1], "contact": 0.2},
	],
	"personnages": [
		{"id": "pierre", "source": "PNJ_PIERRE_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/pierre_sheet.png", "hauteur": 128},
		{"id": "tailleur", "source": "PNJ_TAILLEUR_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/tailleur_sheet.png", "hauteur": 128},
		{"id": "montagnard", "source": "PNJ_MONTAGNARD_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/montagnard_sheet.png", "hauteur": 132},
		{"id": "campeur", "source": "PNJ_CAMPEUR_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/campeur_sheet.png", "hauteur": 112},
		{"id": "guide_arene", "source": "PNJ_GUIDE_ARENE_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/guide_arene_sheet.png", "hauteur": 128},
	],
	"attentes": [
		{"id": f"{nom}_idle", "source": f"{nom.upper()}_ATTENTE_r1.png",
			"sortie": f"assets/sprites/characters/painted/{nom}_idle_sheet.png", "marche": nom}
		for nom in ("pierre", "tailleur", "montagnard", "campeur", "guide_arene")
	],
	"pokemon_fixes": [
		{"id": "racaillou", "source": "POKE_RACAILLOU_FIXE_NE_r1.png",
			"sortie": "assets/sprites/pokemon/painted/racaillou_sheet.png", "hauteur": 56},
	],
}


# --- Prompts ----------------------------------------------------------------------------

def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _prompt_objet(identifiant: str, ref: str, largeur, hauteur, description: str,
		ancres: list[str]) -> str:
	jointes = (f"Images jointes : {ref} = référence de forme, de matériaux et de couleurs, extraite de "
		"la vue d'ensemble validée d'Argenta (minuscule : n'en copie pas le rendu) : dessine l'objet "
		"comme s'il avait été extrait de cette image puis agrandi, avec le même angle, mais avec la "
		f"finesse des ancres. {_noms(STYLE + ancres)} = ancres de style de la série (rendu peint, contour "
		"coloré, finesse, même angle de vue, même lumière neutre). La vue est en lumière dorée de fin "
		"de journée : l'objet garde la lumière NEUTRE des ancres (le jeu ajoute la lumière lui-même).")
	corps = (f"ASSET : {description}\nFormat : PNG carré 1024 × 1024 ; l'objet occupe environ 900 px "
		f"dans sa plus grande dimension, centré. Échelle : {largeur} cases de large et environ {hauteur} "
		f"de haut ; un adulte mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n{corps}\n")


def _prompt_planche(identifiant: str, refs: list[str], description: str, ancres: list[str]) -> str:
	jointes = (f"{', '.join(refs)} = forme et couleurs dans la vue d'ensemble validée (minuscule, "
		"rendu à NE PAS copier) ; " if refs else "")
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages "
		f"jointes : {jointes}{_noms(ancres)} = ancres de style (rendu peint, contour coloré, finesse, "
		f"angle de vue, lumière neutre) : respecte-les exactement.\n\n{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une même planche, chacun "
		f"entier dans sa cellule, sans cadre ni séparation.\n{description}\n{INTERDITS}\n")


def _prompt_coque(identifiant: str, ancres: list[str], geometrie: str, materiaux: str) -> str:
	return (f"{identifiant} — NOUVELLE image : l'enveloppe VIDE d'une pièce intérieure de jeu (murs et "
		f"sol, aucun meuble).\nImages jointes : {_noms(ancres[:-1])} = ancres de style des intérieurs "
		"(rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière "
		f"neutre) : respecte-les exactement ; {Path(ancres[-1]).stem} = la façade validée de ce "
		f"bâtiment (matériaux et couleurs des murs).\n\n{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		"trois quarts, image opaque qui remplit tout le cadre.\nGéométrie (respecte-la exactement, c'est "
		f"un plan de jeu) : {geometrie}\nPièce : {materiaux}\nInterdit : meubles, vitrines, plantes, "
		"tapis (sauf le paillasson demandé), personnages, Pokémon (ni Pikachu), porte fermée, texte, "
		"lettres, chiffres, logo écrit, perspective avec point de fuite, vue isométrique, ombre portée.\n")


## Modèle des planches de marche (celui de PNJ_MARCHAND_NE_r1, séries 02 à 11).
MODELE_MARCHE = (
	"{ident} — planche d'animation de marche d'un PNJ de Kanto 2026.\n"
	"Style : exactement le rendu de la planche jointe PERSO_P2_PEINT_r1 (le héros validé){ref} : "
	"personnage peint simplifié, chibi d'environ 3 têtes, même finesse, même contour fin coloré sans "
	"trait noir, mêmes proportions, même manière de peindre le visage et les vêtements. Ni pixel art, "
	"ni 3D, ni anime aux contours noirs. Le personnage ne ressemble PAS au héros joint (autre visage, "
	"autres couleurs, autre tenue).\n"
	f"{LUMIERE_NE}\n\n"
	"PERSONNAGE (identique dans toutes les images) : {tenue}\n\n"
	"PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence "
	"(canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule "
	"fait 256 × 384 px et contient UNE pose du personnage, entier, centré horizontalement, les pieds "
	"posés sur la même ligne horizontale à 30 px du bas de la cellule, à la même taille dans toutes les "
	"cellules (environ 320 px de haut). Aucune pose ne déborde de sa cellule.\n"
	"- Ligne 1 : de face (marche vers le bas de l'écran).\n"
	"- Ligne 2 : de profil, marche vers la gauche.\n"
	"- Ligne 3 : de profil, marche vers la droite.\n"
	"- Ligne 4 : de dos (marche vers le haut de l'écran).\n"
	"- Colonnes : cycle de marche en 4 images : 1 = pieds joints (passage), 2 = pas avec le pied gauche "
	"en avant, 3 = pieds joints (passage), 4 = pas avec le pied droit en avant. Bras qui balancent à "
	"l'opposé des jambes ; tête et buste qui montent très légèrement aux images 1 et 3.\n"
	"Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le "
	"dessus de la tête). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de "
	"numéros, pas de cadres autour des cellules, aucun Pokémon.\n"
	"Le visage, les couleurs, les proportions et les vêtements doivent être EXACTEMENT les mêmes dans "
	"les 16 poses.\n")


def _prompt_marche(identifiant: str, ref: str | None, tenue: str) -> str:
	texte_ref = (f" ; {ref} = tenue seulement (minuscule, extraite de la vue d'ensemble, rendu à NE PAS "
		"copier)") if ref else ""
	return MODELE_MARCHE.format(ident=identifiant, ref=texte_ref, tenue=tenue)


def _prompt_attente(identifiant: str, role: str, hauteur: int, tenue: str, mains: str) -> str:
	nom = identifiant.removeprefix("PNJ_")
	marche = f"{identifiant}_NE_r1"
	return (f"{nom}_ATTENTE — POSE D'ATTENTE (personnage immobile, debout, au repos) du même personnage "
		f"que la planche jointe {marche} (sa planche de marche 4 × 4) : {role}. Même main peinte, mêmes "
		"couleurs, mêmes proportions, même visage, même coiffure, mêmes vêtements et accessoires, même "
		"taille de personnage. Ce n'est PAS une marche : le personnage ne bouge pas, il attend.\n"
		"Style : illustration 2D peinte numériquement, contour fin et doux d'une teinte sombre et colorée, "
		"aucun trait noir, trois valeurs nettes par matériau, légère granularité de pinceau, lumière "
		"neutre de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche, aucune "
		"teinte dorée. Formes simplifiées et lisibles pour rester net une fois réduit à environ "
		f"{hauteur} px de haut. Ni pixel art, ni 3D.\n"
		f"PERSONNAGE : {tenue} Tout doit être EXACTEMENT comme dans {marche}.\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chaque pose dans une colonne invisible "
		"de 384 px de large, bien séparées par du vide, le personnage entier dans chaque colonne, à la "
		"même taille dans les 4 poses (environ 280 px de haut, comme dans la planche jointe), les pieds "
		"des 4 poses sur une même ligne horizontale. Pas de sol, pas d'ombre, pas de texte, pas de "
		"numéros, pas de cadres.\n"
		f"- Pose 1 : debout, tourné vers le BAS (vu de face), comme la ligne 1 de {marche}.\n"
		f"- Pose 2 : debout, tourné vers la GAUCHE (de profil), comme la ligne 2 de {marche}.\n"
		f"- Pose 3 : debout, tourné vers la DROITE (de profil), comme la ligne 3 de {marche}.\n"
		f"- Pose 4 : debout, tourné vers le HAUT (vu de dos), comme la ligne 4 de {marche}.\n"
		"POSE D'ATTENTE dans les 4 vues : debout, calme et naturel, le poids réparti sur les deux jambes, "
		"les jambes droites et serrées, les PIEDS JOINTS côte à côte (aucun pied devant l'autre, aucun "
		f"pas, aucun talon levé), les deux semelles posées à plat au sol, {mains}, le buste droit. De "
		"profil, les deux jambes se superposent presque : on voit une seule silhouette de jambes, les "
		"deux pieds l'un à côté de l'autre, pas un compas ouvert. De face et de dos, les deux pieds sont "
		"à la même hauteur, rapprochés sous les hanches.\n")


def _prompt_pokemon_fixe(identifiant: str, ref: str | None, description: str, repos: str,
		reaction: str, hauteur: int) -> str:
	jointes = f"{HEROS[:-4]} (le héros validé) et {RATTATA[:-4]} (un petit Pokémon validé) = ancres de style"
	if ref:
		jointes += f" ; {ref} = couleurs et taille relative seulement (minuscule, rendu à NE PAS copier)"
	return (f"{identifiant} — planche d'un Pokémon d'ambiance IMMOBILE (il ne marche jamais) : 4 poses.\n"
		f"Images jointes : {jointes}.\nStyle : exactement le rendu des ancres : Pokémon peint simplifié, "
		"même finesse, même contour fin coloré sans trait noir. Ni pixel art, ni 3D, ni anime aux contours "
		f"noirs. Formes simples et lisibles pour rester net une fois réduit à environ {hauteur} px de "
		f"haut.\n{LUMIERE_NE}\n\nPOKÉMON (identique dans les 4 poses, le SEUL Pokémon de l'image) : "
		f"{description}\n\n"
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
		"d'outil, pas de personnage, pas d'ombre au sol, pas de texte, pas de numéros, pas de cadres. Les "
		"couleurs, les proportions et le visage doivent être EXACTEMENT les mêmes dans les 4 poses ; seule "
		"la posture change entre repos et réaction.\n")


def _images() -> list[dict]:
	"""Toutes les images de la série : nom de l'image (sans .png), fichier de prompt, texte,
	images jointes (noms dans $ART), vague, conditionnel."""
	images = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, ref, largeur, hauteur, description, ancres, vague in SERIE:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
			ancres), [f"{ref}.png"] + STYLE + ancres, vague, groupe=ident)
	ident, refs, description, ancres = PAROI
	ajouter(f"{ident}_NE_r1", PROMPTS / f"{ident}_NE_r1.txt",
		_prompt_planche(ident, refs, description, ancres), [f"{r}.png" for r in refs] + ancres,
		groupe=ident)
	for ident, ref, hauteur, role, tenue, mains in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, ref, tenue),
			[HEROS] + ([f"{ref}.png"] if ref else []), 1, groupe=ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, mains), [f"{nom}.png"], 2, groupe=ident)
	for ident, ref, description, repos, reaction, hauteur in POKEMON_FIXES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt",
			_prompt_pokemon_fixe(ident, ref, description, repos, reaction, hauteur),
			[HEROS, RATTATA] + ([f"{ref}.png"] if ref else []), groupe=ident)
	for ident, largeur, profondeur, ancres, geometrie, materiaux, vague in COQUES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, ancres, geometrie, materiaux),
			list(ancres), vague, groupe=ident)
	for ident, ancres, description, vague in PLANCHES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, [], description, ancres),
			list(ancres), vague, groupe=ident)
	for ident, ref, largeur, hauteur, description, ancres in CONDITIONNELS:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
			ancres), [f"{ref}.png"] + STYLE + ancres, 1, True, groupe=ident)
	ident, texte = BADGE
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", texte, [], 1, True, groupe=ident)
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	changes = 0
	for image in _images():
		fichier: Path = image["fichier"]
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	print(f"{len(_images())} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}, "
		f"{ATTENTES.relative_to(RACINE)}")


# --- Références et génération ----------------------------------------------------------

def references() -> None:
	vue = Image.open(VUE).convert("RGB")
	ART.mkdir(parents=True, exist_ok=True)
	for nom, boite in REFS.items():
		ref = vue.crop(boite)
		ref = ref.resize((ref.width * AGRANDIR, ref.height * AGRANDIR), Image.LANCZOS)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_AR_* dans {ART}")


def commandes() -> str:
	"""Commandes generer.sh équivalentes à la génération (pour une image seule ou un _r2)."""
	lignes = ["ART=/Users/kevinyankam/dev/kanto-2026/build/art"]
	for conditionnel in (False, True):
		for vague in (1, 2):
			choisies = [i for i in _images() if i["vague"] == vague and i["conditionnel"] == conditionnel]
			if not choisies:
				continue
			lignes.append(f"# {'CONDITIONNELS — ne pas lancer par défaut' if conditionnel else 'Vague'}"
				f"{'' if conditionnel else f' {vague}'}")
			for i in choisies:
				fichier = i["fichier"].relative_to(RACINE)
				jointes = " ".join(f"$ART/{j}" for j in i["jointes"])
				lignes.append(f"tools/art/generer.sh {i['nom']} {fichier} {jointes}".rstrip())
	return "\n".join(lignes)


def _generer(image: dict) -> str:
	texte = image["fichier"].read_text()
	return _lancer(image["nom"], texte, [ART / j for j in image["jointes"]])


def generer(choix: set[str]) -> None:
	references()
	manquants = [str(i["fichier"]) for i in _images() if not i["fichier"].exists()]
	if manquants:
		print("prompts absents (lancer --prompts) : " + ", ".join(manquants))
		sys.exit(1)
	for vague in (1, 2):
		images = [i for i in _images() if i["vague"] == vague and (
			(not choix and not i["conditionnel"]) or i["groupe"] in choix or i["nom"] in choix)]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(_generer, images):
				print(ligne, flush=True)


# --- Manifeste (T10) --------------------------------------------------------------------

def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 et 11) ; une section absente est créée en fin de fichier."""
	chemin = ICI / "manifeste.json"
	texte = chemin.read_text()
	m = json.loads(texte)
	ajouts = 0
	for section, entrees in MANIFESTE.items():
		presents = {_cle(e) for e in m.get(section, [])}
		nouvelles = [e for e in entrees if _cle(e) not in presents]
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
	json.loads(texte)
	chemin.write_text(texte)
	print(f"manifeste : {ajouts} entrée(s) de la série 12 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------

def _ref(nom: str, hauteur: int) -> Image.Image:
	image = Image.open(VUE).convert("RGBA").crop(REFS[nom])
	return _echelle(image, hauteur / image.height)


def _si(relatif: str, etiquette: str, fonction=_asset):
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso("assets/sprites/characters/painted/heros_sheet.png"), "héros (échelle)")
	w = "assets/world/"
	c = "assets/sprites/characters/painted/"
	p = _Planche(2600, "Argenta et Route 2 nord — kit de la série 12 (T1, jalon 10) : 1 case = 48 px "
		"sur cette planche ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu)", [
		heros,
		(_asset(f"{w}buildings/bldg_centre_01.png"), "bldg_centre_01\n8 × 7, même enseigne"),
		(_asset(f"{w}buildings/bldg_boutique_01.png"), "bldg_boutique_01\n8 × 7"),
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt serrée") for i in (1, 3, 5, 8)],
		(_asset(f"{w}props/tree_a_01.png"), "tree_a_01\narbre de ville G"),
		(_asset(f"{w}props/tree_c_01.png"), "tree_c_01"),
		(_asset(f"{w}props/tree_e_01.png"), "tree_e_01"),
		(_asset(f"{w}props/tree_b_01.png"), "tree_b_01"),
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\njaune-vert H1, H2"),
		(_asset(f"{w}props/prop_banc_01.png"), "banc n ×5"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneau ×4"),
		(_asset(f"{w}props/prop_buisson_a_01_bourg.png"), "buisson x"),
		(_asset(f"{w}props/prop_buisson_c_01_bourg.png"), "buisson x"),
		(_asset(f"{w}props/prop_pots_fleurs_01.png"), "pots de fleurs\n(Centre, Boutique)"),
		(_asset(f"{w}props/prop_caisses_01.png"), "caisses"),
		(_asset(f"{w}props/prop_ronces_01.png"), "ronces"),
		(_asset(f"{w}props/prop_pierres_01.png"), "pierres"),
		(_asset(f"{w}interiors/int_centre_coque.png"), "coque du Centre\n(Centre d'Argenta)"),
		(_asset(f"{w}interiors/int_boutique_coque.png"), "coque de la Boutique"),
		(_asset(f"{w}interiors/int_grande_etagere_01.png"), "grande étagère\n(maisons)"),
		(_asset(f"{w}interiors/int_table_repas_01.png"), "table (maisons)"),
		(_asset(f"{w}interiors/int_paillasse_01.png"), "paillasse\n(salle science)"),
		(_asset(f"{w}interiors/int_plante.png"), "int_plante"),
		*_si(f"{c}enfant_sheet.png", "enfant (kid)", _cellule_perso),
		*_si(f"{c}vieille_dame_sheet.png", "visiteuse\n(vieille)", _cellule_perso),
		*_si(f"{c}vieil_homme_sheet.png", "vieil habitant\n(old)", _cellule_perso),
		*_si(f"{c}dresseuse_sheet.png", "jeune Dresseuse\n(lass)", _cellule_perso),
		*_si(f"{c}livreur_sheet.png", "employé du Musée\n(courier)", _cellule_perso),
		*_si(f"{c}chercheur_sheet.png", "chercheur", _cellule_perso),
		*_si(f"{c}chercheuse_sheet.png", "chercheuse ×2\n(cartes ≠)", _cellule_perso),
		*_si(f"{c}maman_sheet.png", "compagne\n(maya)", _cellule_perso),
		*_si(f"{c}garde_sheet.png", "garde (J9)", _cellule_perso),
	], (40, 90, 50))

	pierre = _asset(f"{w}props/prop_grande_pierre_01.png")
	rocher = _asset(f"{w}props/prop_rocher_01.png")
	foret = _asset(f"{w}props/tree_foret_03.png")
	buisson = _asset(f"{w}props/prop_buisson_a_01_bourg.png")
	eboulis = Image.new("RGBA", (rocher.width + 30, rocher.height + 40), (0, 0, 0, 0))
	sombre = _teinter(rocher, (0.78, 0.78, 0.8))
	eboulis.alpha_composite(sombre, (0, 0))
	eboulis.alpha_composite(_miroir(sombre), (30, 40))
	p.section("2. VARIATIONS SANS NOUVEL ASSET (échelle, miroir, teinte)", [
		(_miroir(_echelle(pierre, 0.75)), "grande pierre × 0,75\nmiroir (Route 2 nord)"),
		(eboulis, "éboulis = rochers\nassombris × 2"),
		(_teinter(foret, (0.97 * 1.02, 0.95, 0.95)), "forêt plus sèche\nvaleur × 0,95"),
		(_teinter(_miroir(buisson), (1.08, 1.08, 1.08)), "buisson miroir\n+ 8 %"),
		(_teinter(buisson, (0.92, 0.92, 0.92)), "buisson − 8 %"),
		*[(_echelle(_asset(f"{w}ground/decals/decal_fleur_{i}.png"), 1.6), f"fleur_{i}\n(rares)")
			for i in (1, 3, 5)],
	], (60, 80, 110))

	k = CASE_PLANCHE
	p.section("3. NOUVEAUX (Codex, lumière NE) — référence recadrée de la vue, à la taille en jeu", [
		heros,
		(_ref("REF_AR_MUSEE", round(MUSEE[1] * k)), f"WORLD_BLDG_MUSEE_ARGENTA_01\n{MUSEE[0]} × {MUSEE[1]}"),
		(_ref("REF_AR_ARENE", round(ARENE[1] * k)), f"WORLD_BLDG_ARENE_ARGENTA_01\n{ARENE[0]} × {ARENE[1]}"),
		(_ref("REF_AR_MAISON", round(MAISON[1] * k)), f"WORLD_BLDG_MAISON_ARGENTA_01\n{MAISON[0]} × "
			f"{MAISON[1]}, ×2"),
		(_ref("REF_AR_POSTE", round(POSTE_NORD[1] * k)), "POSTE_FORET_NORD_01 7 × 3\n(matériaux ; vu du nord)"),
		(_ref("REF_AR_PAROI", round(3 * k)), "WORLD_RELIEF_PAROI_PLANCHE\n4 modules 4 × 3"),
		(_ref("REF_AR_RELIEF_ROUTE", round(5 * k)), "paroi : bloc de la\nRoute 2 nord"),
		(_ref("REF_AR_ROCHER_PLACE", round(2.6 * k)), "WORLD_PROP_ROCHER_PLACE_01\n3 × 3"),
		(_ref("REF_AR_BLOCS", round(1.6 * k)), "WORLD_PROP_BLOCS_TAILLES_01\n3 × 2"),
		(_ref("REF_AR_TAILLEUR", 64), "PNJ_TAILLEUR\n128 px"),
		(_ref("REF_AR_RACAILLOU", 28), "POKE_RACAILLOU_FIXE\n56 px"),
		(_cellule_perso("assets/sprites/characters/painted/vieil_homme_sheet.png"),
			"PIERRE, MONTAGNARD,\nCAMPEUR, GUIDE (fiches)"),
		(_ref("REF_AR_PLACE", 120), "coques Musée, Arène,\nmaison ; 2 planches"),
	], (130, 70, 40))
	p.section("3 bis. CONDITIONNELS (prompts prêts ; capture du T11, ou demande de Kevin)", [
		(_ref("REF_AR_RELIEF_ROUTE", 110), "WORLD_PROP_EBOULIS_01\nsi les rochers ne bloquent pas"),
		(_ref("REF_AR_ROCHER_ROUTE", round(1.6 * k)), "WORLD_PROP_ROCHER_ROUTE2N_01\nsi doublon visible"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts de la vue, non reproduits)", [
		(_ref("REF_AR_DECROCHEMENT", 140), "décrochement du chemin\n(chemin droit)"),
		(_ref("REF_AR_POSTE", 110), "poste vu de face\n(porte en haut)"),
		(_ref("REF_AR_MONTAGNARD", 80), "tenue du Montagnard\n(= Randonneuse)"),
		(_ref("REF_AR_CAISSES", 60), "caisses hors grille"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


def _jeu(relatif: str, facteur: float = 1.0) -> Image.Image:
	"""Image préparée du jeu, à 1:1 (96 px par case) sauf `facteur`."""
	image = Image.open(RACINE / relatif).convert("RGBA")
	return image if facteur == 1.0 else _echelle(image, facteur)


def _cellules(relatif: str, colonnes: int, lignes: int, choix: list[tuple[int, int]]) -> Image.Image:
	"""Cellules (colonne, ligne) d'une feuille du jeu, côte à côte, à 1:1."""
	feuille = Image.open(RACINE / relatif).convert("RGBA")
	largeur, hauteur = feuille.width // colonnes, feuille.height // lignes
	bande = Image.new("RGBA", (largeur * len(choix), hauteur), (0, 0, 0, 0))
	for i, (colonne, ligne) in enumerate(choix):
		bande.alpha_composite(feuille.crop((colonne * largeur, ligne * hauteur,
			(colonne + 1) * largeur, (ligne + 1) * hauteur)), (i * largeur, 0))
	return bande


def controle(sortie: Path) -> Path:
	"""Planche de contrôle du T10 : les assets **préparés** (assets/), à l'échelle du jeu
	(1:1, 1 case = 96 px ; enveloppes des pièces à 1:2), le héros à côté de chaque groupe."""
	c = "assets/sprites/characters/painted/"
	b = "assets/world/buildings/"
	i = "assets/world/interiors/"
	heros = (_cellules(f"{c}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(4300, "Série 12 préparée (T10, jalon 10) : assets du jeu à 1:1, 1 case = 96 px "
		"(enveloppes à 1:2) ; héros à l'échelle")
	p.section("1. BÂTIMENTS (largeur = emprise de la grille)", [
		heros,
		(_jeu(f"{b}bldg_musee_argenta_01.png"), "bldg_musee_argenta_01\n12 × 9, porte (−1, 0), (0, 0)"),
		(_jeu(f"{b}bldg_arene_argenta_01.png"), "bldg_arene_argenta_01\n12 × 7, porte (−1, 0), (0, 0)"),
		(_jeu(f"{b}bldg_maison_argenta_01.png"), "bldg_maison_argenta_01\n7 × 6, porte (0, 0)"),
		(_jeu(f"{b}bldg_poste_foret_nord_01.png"), "bldg_poste_foret_nord_01\n7 × 3, porte (0, −2), sol"),
	], (40, 90, 50))
	p.section("2. RELIEF ET OBJETS", [
		heros,
		*[(_jeu(f"assets/world/relief/relief_paroi_0{n}.png"), f"relief_paroi_0{n}\n288 px, sol")
			for n in (1, 2, 3, 4)],
		(_jeu("assets/world/props/prop_rocher_place_01.png"), "prop_rocher_place_01\n3 × 3"),
		(_jeu("assets/world/props/prop_blocs_tailles_01.png"), "prop_blocs_tailles_01\n3 × 2"),
		(_cellules("assets/sprites/pokemon/painted/racaillou_sheet.png", 6, 1,
			[(n, 0) for n in range(6)]), "racaillou (geodude), Pokémon fixe 56 px :\nface, réaction, "
			"gauche, réaction, droite, réaction"),
	], (60, 80, 110))
	p.section("3. PERSONNAGES : marche (face, gauche, droite, dos) puis attente", [
		heros,
		*[(_cellules(f"{c}{nom}_sheet.png", 4, 4, [(0, 0), (1, 1), (1, 2), (0, 3)]),
			f"{nom} ({ident}) {h} px\nmarche") for nom, ident, h in PERSONNAGES_JEU],
		*[(_cellules(f"{c}{nom}_idle_sheet.png", 4, 1, [(n, 0) for n in range(4)]),
			f"{nom}_idle\nattente") for nom, _, _ in PERSONNAGES_JEU],
	], (130, 70, 40))
	p.section("4. MEUBLES DES INTÉRIEURS (1:1)", [
		heros,
		*[(_jeu(f"{i}{ident}.png"), f"{ident}\n{texte}") for ident, texte in (
			("int_vitrine_dome_01", "2 × 1"), ("int_vitrine_nautile_01", "2 × 1"),
			("int_vitrine_pierre_lune_01", "1 × 1"), ("int_vitrine_journal_01", "2 × 1"),
			("int_porte_labo_01", "3, dans l'arche"), ("int_panneau_expo_01", "2 × 1"),
			("int_pilier_roche_01", "2 × 1"), ("int_rochers_bas_01", "2 × 2"),
			("int_rochers_bas_02", "1 × 1"))],
	], (110, 90, 40))
	p.section("5. ENVELOPPES DES PIÈCES (1:2)", [
		(_jeu(f"{i}int_musee_coque.png", 0.5), "int_musee_coque 15 × 10"),
		(_jeu(f"{i}int_arene_coque.png", 0.5), "int_arene_coque 15 × 11"),
		(_jeu(f"{i}int_maison_argenta_coque.png", 0.5), "int_maison_argenta_coque 15 × 10"),
	], (120, 40, 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


## Planches de personnages préparées : (planche, identifiant de données, hauteur de fiche).
PERSONNAGES_JEU = [("pierre", "brock", 128), ("tailleur", "stonemason", 128),
	("montagnard", "mountaineer", 132), ("campeur", "camper", 112),
	("guide_arene", "gym_guide", 128)]


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--refs" in arguments:
		references()
	elif "--commandes" in arguments:
		print(commandes())
	elif "--planche" in arguments:
		autres = [a for a in arguments if a != "--planche"]
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "AR_KIT_v1.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon10_assets" / "serie12_controle.png"))
	else:
		generer(set(arguments))
