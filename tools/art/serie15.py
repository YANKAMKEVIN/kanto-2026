#!/usr/bin/env python3
"""Série 15 — Route 4, Azuria et Route 24 (jalon 13, lumière neutre). Liste : docs/tech/jalon-13.md
§1.4 ; fiches : docs/design/fiches-assets/serie-15-azuria.md.

Méthode des J8–J12 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées, `docs/design/reference/azuria-vue-generale-v1.png`, `route-4-vue-generale-v1.png` et
`route-24-vue-generale-v1.png` ; **la grille fait foi** : `tools/plans/route_4.txt`, `azuria.txt`,
`route_24.txt`, `azuria_arene.txt`, `azuria_velos.txt`, `azuria_maison.txt`). Presque tout est repris
(sols, forêt, hautes herbes, Centre, Boutique, maisons, mobilier, habitants) ; ne sont générées que
**19 images** :
  - eau et ville d'eau : texture d'eau des canaux, planche de quais (6 modules alignés sur
    `QUAY_PIECES` de `tools/cerulean_map_kit.gd`), planche de ponts (8 modules), mobilier de ville
    d'eau (6), indices du cambriolage (5), fermetures (3), Grotte Azurée ;
  - bâtiments : façades de l'Arène (verrière) et du magasin de vélos ;
  - Route 4 : rebord et falaise en roche ardoise (correction validée : net, sans planche) ;
  - Route 24 : berges naturelles (6 modules) ;
  - intérieurs : coque de l'Arène (piscine) + ses 3 meubles ; 4 meubles du magasin de vélos ;
  - 2 personnages × (marche + attente) : Ondine, Nageur ; 1 planche d'icône : la Pépite.
**Pas de portrait d'Ondine** (Q-2 décidé par Kevin).
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_GROUND_DALLES_CLAIRES_01, PNJ_NAGEUSE,
PNJ_HABITANTE.

Lumière : NE (neutre) pour objets, personnages, icône ; les reflets de l'eau sont **dans la valeur
peinte** de la texture, jamais d'ombre portée peinte.

**Les prompts sont versionnés** : `tools/art/prompts/serie15/<NOM>.txt` (un par image) et
`tools/art/attente/prompts/<NOM>_ATTENTE.txt`, écrits par `--prompts` à partir des tables ci-dessous.
Corriger une image = corriger la table, relancer `--prompts`, relire le diff ; une correction après
génération se lance en `_r2`. Sources et sorties dans $ART (défaut : build/art de cette copie ;
`--ancres` y copie les ancres de style depuis le checkout principal).

Usage :
  tools/art/serie15.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie15.py --refs                  recadre les REF_* dans $ART (sans Codex)
  tools/art/serie15.py --ancres                copie les ancres de style absentes dans $ART
  tools/art/serie15.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie15.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/AZ_KIT_v1.png)
  tools/art/serie15.py --contact [sortie.png]  planche de contact des images générées (T2)
  tools/art/serie15.py --retouches             T5 : ponts de pierre sans poteaux d'angle, Pépite dans sa colonne (_r3)
  tools/art/serie15.py --manifeste             ajoute les entrées en fin de manifeste.json (T5 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie15.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T5)
  tools/art/serie15.py [IDENTIFIANT ...]       génère avec Codex, en deux vagues (sans argument :
                                               la série sans les conditionnels ; --refs --ancres d'abord)
"""
from __future__ import annotations

import json
import os
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie10  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE, TEXTURE_FIN  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _miroir, _Planche, _teinter)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026/build/art")  # ancres validées des séries 01–14
REFERENCE = RACINE / "docs/design/reference"
VUES = {
	"AZ": REFERENCE / "azuria-vue-generale-v1.png",  # 1536 × 1024, ≈ 27,4 px par case (56 × 41)
	"R4": REFERENCE / "route-4-vue-generale-v1.png",  # 1536 × 1024, ≈ 24 px par case (64 cases)
	"R24": REFERENCE / "route-24-vue-generale-v1.png",  # 1536 × 1024, ≈ 27,4 px par case (56 cases)
}
PX_CASE = {"AZ": 1536 / 56, "R4": 1536 / 64, "R24": 1536 / 56}
PROMPTS = ICI / "prompts" / "serie15"
ATTENTES = ICI / "attente" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue).
REFS = {
	# Azuria
	"REF_AZ_EAU": ("AZ", (725, 270, 800, 460)),
	"REF_AZ_BAIE": ("AZ", (1280, 200, 1536, 430)),
	"REF_AZ_QUAI": ("AZ", (810, 360, 1280, 480)),
	"REF_AZ_QUAI_OUEST": ("AZ", (640, 80, 735, 470)),
	"REF_AZ_PONTS": ("AZ", (825, 365, 1130, 475)),
	"REF_AZ_PONT_OUEST": ("AZ", (705, 185, 830, 265)),
	"REF_AZ_ARENE": ("AZ", (905, 80, 1225, 300)),
	"REF_AZ_VELOS": ("AZ", (915, 685, 1135, 880)),
	"REF_AZ_JARDIN": ("AZ", (255, 30, 440, 110)),
	"REF_AZ_PORTE_RUBAN": ("AZ", (255, 100, 440, 260)),
	"REF_AZ_JARDINIERE": ("AZ", (700, 545, 760, 605)),
	"REF_AZ_ARBRE_BAC": ("AZ", (1195, 580, 1280, 670)),
	"REF_AZ_GROTTE": ("AZ", (1310, 55, 1500, 195)),
	"REF_AZ_PALISSADE": ("AZ", (800, 895, 935, 955)),
	"REF_AZ_PLACE": ("AZ", (600, 520, 1000, 640)),
	"REF_AZ_PECHEUR": ("AZ", (685, 295, 725, 360)),
	"REF_AZ_NAGEUSE": ("AZ", (1005, 245, 1040, 310)),
	"REF_AZ_ENFANT": ("AZ", (888, 420, 920, 480)),
	"REF_AZ_POLICIER": ("AZ", (385, 215, 420, 280)),
	"REF_AZ_VOISINE": ("AZ", (580, 220, 615, 280)),
	"REF_AZ_DRESSEUR": ("AZ", (945, 500, 980, 565)),
	"REF_AZ_CLOTURE_EST": ("AZ", (1360, 520, 1450, 620)),
	# Route 4
	"REF_R4_REBORD": ("R4", (690, 460, 850, 515)),
	"REF_R4_FALAISE": ("R4", (130, 460, 700, 520)),
	"REF_R4_PAROI": ("R4", (0, 0, 500, 250)),
	# Route 24
	"REF_R24_BERGE_N": ("R24", (0, 325, 500, 375)),
	"REF_R24_BERGE_S": ("R24", (0, 680, 660, 725)),
	"REF_R24_RIVIERE": ("R24", (1000, 380, 1536, 640)),
	"REF_R24_PONT": ("R24", (800, 260, 890, 700)),
	"REF_R24_PONT_TETE": ("R24", (800, 255, 890, 345)),
	"REF_R24_PIED_PONT": ("R24", (735, 685, 1000, 850)),
	"REF_R24_ONDINE": ("R24", (945, 665, 990, 735)),
}
AGRANDIR = 3

## Ancres de style (images validées des séries précédentes, dans $ART ; `--ancres` les copie).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"
MURET = "WORLD_RELIEF_MURET_01_NE_r1.png"
BALUSTRADE = "WORLD_PROP_BALUSTRADE_01_NE_r1.png"
ESCALIER_VILLE = "WORLD_RELIEF_ESCALIER_VILLE_01_NE_r1.png"
EAU_JEU = "WORLD_GROUND_EAU_01_NE_r1.png"
ARENE_ARGENTA = "WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png"
MAISON_ARGENTA = "WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png"
BOUTIQUE = "WORLD_BLDG_BOUTIQUE_01_NE_r1.png"
COQUE_ARENE = "INT_ARENE_COQUE_NE_r1.png"
COQUE_CENTRE = "INT_CENTRE_COQUE_NE_r1.png"
COQUE_MAISON = "INT_MAISON_ARGENTA_COQUE_NE_r1.png"
VELO = "WORLD_PROP_VELO_01_NE_r1.png"
RATELIER = "WORLD_PROP_RATELIER_VELOS_01_NE_r1.png"
POTS = "WORLD_PROP_POTS_FLEURS_01_NE_r1.png"
BANC = "WORLD_PROP_BANC_01_GH_r1.png"
LAMPADAIRE = "WORLD_PROP_LAMPADAIRE_01_GH_r1.png"
CLOTURE = "WORLD_PROP_CLOTURE_01_NE_r1.png"
REBORD = "WORLD_RELIEF_REBORD_01_NE_r1.png"
FALAISE = "WORLD_RELIEF_FALAISE_01_NE_r1.png"
ARDOISE = "WORLD_RELIEF_PAROI_ARDOISE_PLANCHE_NE_r1.png"  # série 14
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
PIERRE = "PNJ_PIERRE_NE_r1.png"
NURSE_REF = "PNJ_INFIRMIERE_NE_r1.png"
# Images de la série 15 jointes aux vagues suivantes.
QUAIS = "WORLD_RELIEF_QUAI_PLANCHE_NE_r1.png"
ARENE_AZ = "WORLD_BLDG_ARENE_AZURIA_01_NE_r1.png"
VELOS_AZ = "WORLD_BLDG_VELOS_01_NE_r1.png"
ANCRES = [STYLE[0], STYLE[1], HEROS, MURET, BALUSTRADE, ESCALIER_VILLE, EAU_JEU, ARENE_ARGENTA,
	MAISON_ARGENTA, BOUTIQUE, COQUE_ARENE, COQUE_CENTRE, COQUE_MAISON, VELO, RATELIER, POTS, BANC,
	LAMPADAIRE, CLOTURE, REBORD, FALAISE, ARDOISE, MENU_OBJETS, PIERRE, NURSE_REF,
	"WORLD_GROUND_CHEMIN_01_NE_r1.png", "WORLD_PROP_ROCHER_01_NE_r1.png",
	"WORLD_PROP_ROCHER_MER_01_NE_r1.png", "WORLD_PROP_TRONC_COUCHE_01_NE_r1.png"]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, AUCUN emblème rond de type balle "
	"(ni cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou faune "
	"non-Pokémon (oiseaux, poissons réels, insectes), Pikachu et tout Pokémon non demandé, personnage "
	"qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune), élément effrayant.")

## Eau claire d'Azuria : valeurs et palette communes aux images d'eau.
VALEURS_EAU = ("VALEURS D'EAU (exception de palette à l'ADN : l'eau d'Azuria est claire et fraîche) : bleu "
	"turquoise clair vers le bleu azur, plus clair et plus vert que l'eau de mer jointe ; lumière NEUTRE, "
	"diffuse ; les reflets (éclats clairs, ondulations, reflets de ciel) sont PEINTS DANS LA VALEUR de la "
	"surface, discrets et réguliers ; aucune ombre portée, aucune écume, aucun vignettage.")

# --- Tables ------------------------------------------------------------------------------

## Textures de sol (opaques, raccordables) : (identifiant, référence, description, ancres,
## valeurs, vague).
SOLS = [
	("WORLD_GROUND_EAU_CANAL_01", "REF_AZ_EAU",
		"texture de l'EAU CLAIRE des canaux d'Azuria et de la rivière de la Route 24, vue strictement de "
		"dessus : eau turquoise-azur calme et limpide, légèrement plus profonde (bleu plus soutenu) au "
		"centre des motifs, fines ondulations régulières en écailles allongées, éclats de ciel clairs "
		"répartis uniformément, quelques reflets blanc-bleuté en petites touches ; on devine à peine le "
		"fond clair ; plus CLAIRE, plus VERTE-TURQUOISE et plus régulière que la texture de mer jointe "
		"(à ne pas copier) ; aucune écume, aucun rivage, aucun nénuphar, aucun reflet de bâtiment ni de "
		"rive, aucun motif remarquable qui trahirait la répétition.",
		[EAU_JEU], VALEURS_EAU, 1),
]

## Textures conditionnelles : (identifiant, référence, description, ancres, valeurs).
SOLS_COND = [
	("WORLD_GROUND_DALLES_CLAIRES_01", "REF_AZ_PLACE",
		"texture de PIERRE CLAIRE des quais et de la place d'Azuria : grandes dalles carrées régulières "
		"blanc-crème très pâle aux joints fins gris clair, bords légèrement usés, fines nuances de crème "
		"et de gris perle d'une dalle à l'autre, quelques éclats minéraux discrets ; propre, calme et "
		"lumineuse (luminosité 80 à 88 %) ; plus claire, plus froide et plus régulière que le pavé "
		"joint (à ne pas copier) ; aucune plante, aucune fissure marquée, aucune flaque.",
		["WORLD_GROUND_PAVE_A_01_CENTRE_NE_r1.webp"],
		"Valeurs : pierre claire, lumière neutre, aucune ombre portée ; contraste doux."),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_BLDG_ARENE_AZURIA_01", "REF_AZ_ARENE", 12, 7,
		"l'ARÈNE d'Azuria, la piscine d'entraînement élégante d'une Championne de l'eau, façade de face "
		"(base de 12 cases de large, environ 7 cases de haut avec le toit), même gabarit et même hauteur "
		"que la façade jointe WORLD_BLDG_ARENE_ARGENTA_01 : un long bâtiment bas en pierre de taille "
		"blanc-crème aux pilastres réguliers, soubassement de pierre bleu-gris, qui porte une grande "
		"VERRIÈRE en berceau de verre bleuté à structure blanche (toit entier en verre, reflets de ciel "
		"clairs peints sur les vitres) ; au centre, un porche en arc surbaissé avec une double porte de "
		"bois brun, deux marches de pierre et un petit auvent ; de chaque côté du porche, une haute "
		"fenêtre de verre ; sous la verrière, un bandeau de pierre ; à gauche et à droite du porche, une "
		"jardinière de pierre pleine de fleurs bleues et blanches ; quelques motifs de vagues stylisées "
		"sculptés dans la pierre au-dessus du porche. AUCUN emblème rond, AUCUN médaillon, AUCUN "
		"écusson, AUCUN texte : le porche porte seulement des vagues sculptées. Bâtiment fermé (la porte "
		"est la seule ouverture), aucun personnage.",
		[ARENE_ARGENTA, "WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png"], LUMIERE_NE, 1),
	("WORLD_BLDG_VELOS_01", "REF_AZ_VELOS", 8, 7,
		"le MAGASIN DE VÉLOS d'Azuria, boutique de quartier de 8 cases de large et environ 7 de haut avec "
		"le toit, même gabarit que la Boutique jointe (WORLD_BLDG_BOUTIQUE_01) mais d'un style tout "
		"différent : maison de commerce basse aux murs crème, toit de tuiles ORANGE vif à quatre pans "
		"avec une petite lucarne, deux grandes VITRINES de chaque côté de la porte où l'on voit deux "
		"vélos à l'étalage, un store à rayures orange et blanches au-dessus de chaque vitrine, porte "
		"de bois brun au centre sous un petit auvent, deux marches, une jardinière fleurie sous une "
		"vitrine, un porte-vélos gris contre le mur de droite avec deux vélos (un rouge, un vert). "
		"AUCUN emblème rond, AUCUN texte, AUCUNE enseigne écrite (une simple roue de vélo stylisée "
		"suspendue en enseigne est permise : une roue à rayons, pas un cercle plein partagé). Bâtiment "
		"fermé (la porte est la seule ouverture), aucun personnage.",
		[BOUTIQUE, MAISON_ARGENTA, VELO], LUMIERE_NE, 1),
	("WORLD_RELIEF_GROTTE_AZUREE_01", "REF_AZ_GROTTE", 4, 3.5,
		"un ÎLOT ROCHEUX avec la bouche de la GROTTE AZURÉE, vu de loin au milieu de l'eau (repère visuel, "
		"personne n'y va) : un amas de roche gris perle et gris bleuté, haut d'environ 3 cases, large "
		"d'environ 3,5 cases, aux facettes verticales arrondies, avec en bas, tournée vers le sud, une "
		"OUVERTURE de grotte arrondie sombre (noir bleuté, d'environ 1 case de large et 1 de haut) ; "
		"quelques rochers plus petits au pied (deux petits blocs à droite) ; la base de l'îlot est "
		"posée sur l'eau avec un fin liseré d'écume claire peint (le seul endroit où l'écume est permise). "
		"Aucun escalier, aucun ponton, aucun panneau, aucune porte, aucune lanterne, aucune plante "
		"sauf un peu de mousse verte discrète sur le sommet.",
		["WORLD_PROP_ROCHER_MER_01_NE_r1.png", ARDOISE], LUMIERE_NE, 1),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("WORLD_RELIEF_QUAI_PLANCHE", ["REF_AZ_QUAI", "REF_AZ_QUAI_OUEST", "REF_AZ_PONTS"],
		"PLANCHE de 6 MODULES DE QUAI de pierre claire, bords d'un canal d'eau vus de dessus en trois "
		"quarts, dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
		"512 × 512), un module par cellule, centré, à une échelle COMMUNE de 1 case = 240 px, TOUS posés à "
		"plat. Même pierre que le muret et la balustrade joints (pierre blanc-crème, joints fins, un peu "
		"de mousse verte discrète en bas) ; chaque module se raccorde bout à bout avec son semblable. "
		"Chaque module est la PARTIE QUI DESCEND DANS L'EAU : le haut de l'image se raccorde au dallage "
		"du quai, le bas touche l'eau (fine ligne d'eau mouillée sombre bleu-gris au pied, rien de plus).\n"
		"Module 1 (ligne 1, à gauche) : FACE DE QUAI A, mur de quai vu de face dont le dallage est AU "
		"NORD : une fine lèvre de pierre claire en haut (liseré éclairé), puis la face verticale en "
		"grandes pierres de taille appareillées (joints verticaux tous les 120 px), une légère "
		"patine d'humidité vers le bas ; 2 cases de long × 0,45 de haut (≈ 480 × 108 px), rectangle "
		"horizontal complet bord à bord. Module 2 (ligne 1, au milieu) : FACE DE QUAI B, même gabarit "
		"(480 × 108), appareillage décalé et deux pierres de teinte légèrement différente, un anneau de "
		"fer scellé dans la pierre. Module 3 (ligne 1, à droite) : LÈVRE DE QUAI, bord d'un quai vu "
		"depuis l'autre rive : seulement le dessus arrondi d'une margelle de pierre claire, très mince "
		"(2 cases de long × 0,17 de haut, ≈ 480 × 40 px), liseré éclairé en haut, ligne d'eau en bas. "
		"Module 4 (ligne 2, à gauche) : BORD LATÉRAL DE QUAI, vu de profil : une bande verticale de "
		"pierre, dallage à GAUCHE, eau à droite, tranche de dalle claire à gauche puis face mince "
		"sombre-humide, ligne d'eau à droite (0,21 de large × 2 de haut, ≈ 50 × 480 px). Module 5 "
		"(ligne 2, au milieu) : ANGLE DE QUAI, petit bloc de pierre carré (≈ 100 × 100 px) : coin de "
		"margelle arrondi en haut à gauche, ligne d'eau à droite et en bas. Module 6 (ligne 2, à droite) : "
		"ESCALIER DE QUAI : quatre marches de pierre claire qui descendent du dallage (en haut) vers "
		"l'eau (en bas), 2 cases de large × 1 de haut (≈ 480 × 240 px), deux petits murets latéraux "
		"bas, la dernière marche à demi immergée (ligne d'eau). Aucune plante, aucun bateau, aucun "
		"amarrage.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune eau dessinée autour, aucune "
		"ombre portée.",
		[MURET, BALUSTRADE, ESCALIER_VILLE], LUMIERE_NE, 1),
	("WORLD_PROP_VILLE_EAU_PLANCHE", ["REF_AZ_JARDINIERE", "REF_AZ_ARBRE_BAC", "REF_AZ_PLACE"],
		"PLANCHE de 6 éléments de MOBILIER d'une ville bordée d'eau (Azuria : pierre claire, eau, fleurs "
		"fraîches), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
		"512 × 512), un élément par cellule, centré, la base de chacun sur une même ligne horizontale à "
		"40 px du bas de sa cellule, à une échelle COMMUNE : 1 case = 150 px.\n"
		"1 (ligne 1, à gauche) : JARDINIÈRE carrée de pierre blanc-crème, 1 case de large (≈ 150 px), "
		"0,6 case de haut, pleine de petites fleurs bleues et blanches. 2 (ligne 1, au milieu) : "
		"JARDINIÈRE carrée identique à bord de pierre, fleurs roses et jaunes. 3 (ligne 1, à droite) : "
		"PETIT ARBRE EN BAC, un arbuste rond taillé (feuillage vert frais) dans un bac carré de pierre "
		"claire, 1 case de large, environ 1,6 case de haut. 4 (ligne 2, à gauche) : BANC de pierre claire "
		"à assise de bois clair, 2 cases de large (≈ 300 px), 0,8 case de haut. 5 (ligne 2, au milieu) : "
		"LAMPADAIRE DE QUAI, mât fin blanc cassé à lanterne de verre, soubassement de pierre carré, "
		"0,45 case de large, environ 2,6 cases de haut. 6 (ligne 2, à droite) : BITTE D'AMARRAGE, "
		"petite bitte de fer sombre peinte sur un socle de pierre, avec un bout de cordage beige enroulé, "
		"0,5 case de large, 0,5 case de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[POTS, BANC, LAMPADAIRE, MURET], LUMIERE_NE, 1),
	("WORLD_PROP_CAMBRIOLAGE_PLANCHE", ["REF_AZ_JARDIN", "REF_AZ_PORTE_RUBAN"],
		"PLANCHE de 5 INDICES MATÉRIELS d'un cambriolage discret dans un quartier calme (jamais "
		"effrayant : de simples dégâts domestiques), dans une image 1536 × 1024 : grille invisible de "
		"3 colonnes × 2 lignes (cellules de 512 × 512), un élément par cellule, centré, la base de "
		"chacun sur une même ligne horizontale à 40 px du bas de sa cellule, à une échelle COMMUNE : "
		"1 case = 150 px ; la 6e cellule reste VIDE.\n"
		"1 (ligne 1, à gauche) : CLÔTURE ARRACHÉE, un tronçon de clôture de bois clair de 3 cases de long "
		"(≈ 450 px), 0,7 case de haut, dont la partie centrale est arrachée : deux piquets cassés "
		"inclinés, une planche tombée au sol, un trou net au milieu. 2 (ligne 1, au milieu) : PORTE "
		"CONDAMNÉE, une porte de bois brun de 1 case de large et 1,5 de haut, fermée, sur laquelle deux "
		"PLANCHES clouées en croix et un RUBAN de chantier jaune et noir (rayures, SANS aucune lettre) "
		"tendu en travers ; elle est peinte seule, comme un autocollant à poser sur une façade. 3 "
		"(ligne 1, à droite) : POT RENVERSÉ, un grand pot de terre cuite couché sur le flanc, de la "
		"terre et une petite plante répandues, 1 case de large, 0,5 case de haut. 4 (ligne 2, à gauche) : "
		"TROU DANS LA CLÔTURE, un morceau de clôture de bois de 1 case de long avec une brèche à hauteur "
		"d'homme, deux planches de travers, 1 case de large, 0,8 case de haut. 5 (ligne 2, au milieu) : "
		"RUBAN seul, un ruban de chantier jaune et noir (rayures sans lettres) tendu entre deux petits "
		"piquets de bois, 2 cases de long, 0,6 case de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[CLOTURE, "WORLD_PROP_POTS_FLEURS_01_NE_r1.png"], LUMIERE_NE, 1),
	("WORLD_RELIEF_REBORD_ARDOISE_PLANCHE", ["REF_R4_REBORD", "REF_R4_FALAISE", "REF_R4_PAROI"],
		"PLANCHE de 3 modules de RELIEF en ROCHE ARDOISE, pour le versant de la Route 4 (la roche "
		"grise-bleutée du Mont Sélénite, la MÊME que la planche jointe WORLD_RELIEF_PAROI_ARDOISE), dans "
		"une image 1536 × 1024 : grille invisible de 3 colonnes × 1 ligne (cellules de 512 × 1024), un "
		"module par colonne, centré, la base des trois sur une même ligne horizontale à 120 px du bas, "
		"à une échelle COMMUNE : 1 case = 150 px. Dessus en herbe courte vert frais sur le bord ; face en "
		"ardoise gris bleuté froid à grandes facettes verticales, arêtes claires gris perle.\n"
		"1 (colonne 1) : REBORD, un petit rebord NET d'une case et demie de large (≈ 225 px) et d'environ "
		"0,55 case de haut (≈ 82 px) : une lèvre d'herbe, puis une face basse de roche ardoise "
		"horizontale, UNIQUEMENT de la roche (AUCUNE planche, AUCUNE poutre, AUCUN morceau de bois, AUCUNE "
		"terre brune), qui se raccorde bout à bout avec lui-même. 2 (colonne 2) : FALAISE A, face de "
		"versant haute d'environ 1,3 case (≈ 195 px), 3,4 cases de large (≈ 510 px), même roche, herbe en "
		"haut ; se raccorde bout à bout. 3 (colonne 3) : FALAISE B, même gabarit (3,4 × 1,3), facettes "
		"différentes, un petit éclat bleu pâle discret. Aucune plante grimpante, aucun cristal "
		"visible hors l'éclat du module 3.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[REBORD, FALAISE, ARDOISE], LUMIERE_NE, 1),
	# Vague 2 (une image de la vague 1 jointe)
	("WORLD_PROP_PONTS_PLANCHE", ["REF_AZ_PONTS", "REF_AZ_PONT_OUEST", "REF_R24_PONT", "REF_R24_PONT_TETE"],
		"PLANCHE de 8 MODULES DE PONT vus de dessus en trois quarts (un pont de ville en pierre et le "
		"long pont de bois d'une rivière), dans une image 1536 × 1024 : grille invisible de 4 colonnes × "
		"2 lignes (cellules de 384 × 512), un module par cellule, centré, la base sur la ligne basse de "
		"la cellule, à une échelle COMMUNE : 1 case = 120 px. Chaque tablier est un MODULE RÉPÉTABLE : il "
		"se raccorde bout à bout avec lui-même dans le sens de la traversée.\n"
		"Ligne 1. Module 1 : TABLIER DE VILLE de 2 cases de large × 1 de long (240 × 120 px), traversée "
		"du haut vers le bas : dalles de pierre claire calepinées, un parapet bas de pierre (muret à "
		"couvre-joint arrondi) de chaque côté, vu de dessus, 24 px d'épaisseur. Module 2 : TABLIER DE "
		"VILLE de 3 cases de large × 1 de long (360 × 120 px), même dalles et mêmes parapets. Module 3 : "
		"TABLIER DE VILLE pour une traversée de gauche à droite, 1 case de long × 2 de large (120 × 240 "
		"px) : mêmes dalles, parapet du haut vu de face (face en pierre visible, ≈ 36 px de haut) et "
		"parapet du bas vu de dessus (≈ 20 px). Module 4 : TABLIER DE BOIS A, pont de rivière de 2 cases "
		"de large × 1 de long (240 × 120 px), traversée du haut vers le bas : planches de bois clair "
		"perpendiculaires à la traversée, clouées, quelques planches un peu plus sombres, un longeron de "
		"bois sombre de chaque côté (≈ 14 px), aucun garde-corps.\n"
		"Ligne 2. Module 5 : TABLIER DE BOIS B, même gabarit que 4 (240 × 120), planches décalées, deux "
		"nœuds visibles. Module 6 : TABLIER DE BOIS C, même gabarit, une planche neuve plus claire et un "
		"petit raccord de fer. Module 7 : GARDE-CORPS de pont de bois, un segment de rambarde en pierre "
		"claire et bois de 1 case de long (120 px) vu depuis le côté du tablier, 0,5 case de haut "
		"(≈ 60 px) : une lisse de bois sur deux petits balustres de pierre, bords raccordables avec "
		"lui-même ; posé le long du pont, JAMAIS dessus. Module 8 : PILE de pont, un pilier carré de "
		"pierre claire à chapiteau plat, 0,5 case de large (≈ 60 px), 1,2 case de haut (≈ 144 px), qui "
		"sort de l'eau au bord du pont (on voit sa face et un peu de la ligne d'eau mouillée à son pied).\n"
		"Même pierre que les quais joints (blanc-crème) ; bois clair et chaud. Aucun nom, aucune "
		"inscription.\nFond avec une vraie transparence (canal alpha), aucun sol, aucune eau dessinée "
		"autour, aucune ombre portée.",
		[QUAIS, BALUSTRADE, "WORLD_PROP_PONTON_01_NE_r1.png"], LUMIERE_NE, 2),
	("WORLD_RELIEF_BERGE_PLANCHE", ["REF_R24_BERGE_N", "REF_R24_BERGE_S", "REF_R24_RIVIERE"],
		"PLANCHE de 6 modules de BERGE NATURELLE d'une rivière (Route 24 : terre, herbe, galets et "
		"roseaux, SANS pierre taillée), bords d'eau vus de dessus en trois quarts, dans une image "
		"1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un module par "
		"cellule, centré, à une échelle COMMUNE de 1 case = 240 px. Chaque module est la PARTIE QUI "
		"DESCEND DANS L'EAU : le haut de l'image se raccorde à l'herbe de la rive, le bas touche l'eau "
		"(fine ligne d'eau mouillée sombre, rien de plus) ; chaque module se raccorde bout à bout avec "
		"son semblable. Même rendu que les quais joints (même main, même finesse) mais en matière "
		"naturelle : talus de terre brune humide, bord d'herbe vert frais, galets gris, touffes de "
		"roseaux.\n"
		"Module 1 (ligne 1, à gauche) : BERGE NORD A, rive dont l'herbe est AU NORD : lèvre d'herbe en "
		"haut, talus de terre brune d'environ 0,45 case de haut, quelques galets et trois touffes de "
		"roseaux fines au pied ; 2 cases de long × 0,45 de haut (≈ 480 × 108 px), rectangle horizontal "
		"complet. Module 2 (ligne 1, au milieu) : BERGE NORD B, même gabarit (480 × 108), talus décalé, "
		"une grosse racine, un caillou plat. Module 3 (ligne 1, à droite) : LÈVRE DE BERGE SUD, rive "
		"vue depuis l'autre côté : seulement un bord d'herbe et de terre arrondi, très mince, quelques "
		"brins de roseaux (2 cases de long × 0,17 de haut, ≈ 480 × 40 px). Module 4 (ligne 2, à "
		"gauche) : BERGE LATÉRALE vue de profil : bande verticale, herbe à GAUCHE, eau à droite, talus "
		"mince (0,21 de large × 2 de haut, ≈ 50 × 480 px). Module 5 (ligne 2, au milieu) : ANGLE DE "
		"BERGE, petit bloc d'herbe et de terre arrondi (≈ 100 × 100 px), ligne d'eau à droite et en bas. "
		"Module 6 (ligne 2, à droite) : TOUFFE DE ROSEAUX isolée à poser dans l'eau, un bouquet de "
		"roseaux et de joncs verts avec trois quenouilles brunes (1 case de large, 1 de haut). Aucune "
		"pierre taillée, aucun quai, aucun ponton, aucun animal.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune eau dessinée autour, aucune "
		"ombre portée.",
		[QUAIS, "WORLD_PROP_ROCHER_MER_01_NE_r1.png"], LUMIERE_NE, 2),
	("WORLD_PROP_FERMETURES_PLANCHE", ["REF_AZ_PALISSADE", "REF_AZ_CLOTURE_EST"],
		"PLANCHE de 3 FERMETURES de sorties d'une ville (travaux en cours, sans aucun texte), dans une "
		"image 1536 × 1024 : grille invisible de 3 colonnes × 1 ligne (cellules de 512 × 1024), un "
		"élément par colonne, centré, la base des trois sur une même ligne horizontale à 120 px du bas, "
		"à une échelle COMMUNE : 1 case = 150 px.\n"
		"1 : PALISSADE DE CHANTIER A, 3 cases de long (≈ 450 px), 1,1 case de haut : grandes planches "
		"verticales de bois brun-gris, deux traverses, une bande de renfort en X au milieu, "
		"raccordable bout à bout avec elle-même. 2 : PALISSADE DE CHANTIER B, même gabarit, planches "
		"un peu plus claires, deux planches de longueurs différentes, un cône de chantier orange et "
		"blanc posé au pied à droite. 3 : BARRIÈRE À CROISILLON, une barrière de bois de 2 cases de "
		"long (≈ 300 px), 0,9 case de haut, à deux traverses et deux croisillons, posée sur deux "
		"pieds.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[CLOTURE, "WORLD_PROP_TRONC_COUCHE_01_NE_r1.png"], LUMIERE_NE, 2),
	("INT_ARENE_AZURIA_PLANCHE", ["REF_AZ_ARENE"],
		"PLANCHE de 3 meubles pour l'intérieur de l'Arène d'Azuria (piscine, pierre blanc-crème et bleu "
		"pâle), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 1 ligne (cellules de "
		"512 × 1024), un élément par colonne, centré, la base des trois sur une même ligne horizontale à "
		"120 px du bas, à une échelle COMMUNE : 1 case = 180 px.\n"
		"1 : PLONGEOIR, un petit plongeoir de piscine à deux cases de large (≈ 360 px) : plate-forme de "
		"pierre claire bordée d'une rambarde chromée, une échelle chromée à droite, une planche de "
		"plongeon bleu pâle qui avance vers la gauche, environ 2 cases de haut. 2 : BANC DE PISCINE, banc "
		"de pierre claire à assise de lattes de bois clair, 2 cases de large, 0,8 case de haut, une "
		"serviette bleu pâle pliée sur le côté. 3 : PORTE-BOUÉES, un petit râtelier de bois clair "
		"contre lequel pendent trois bouées rondes unies (bleu pâle, blanc, jaune clair, SANS aucune "
		"bande ni motif), 1 case de large, 1,4 case de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[ARENE_AZ, "INT_ARENE_ROCHERS_PLANCHE_NE_r1.png"], LUMIERE_NE, 2),
	("INT_VELOS_PLANCHE", ["REF_AZ_VELOS"],
		"PLANCHE de 4 meubles d'un magasin de vélos (bois clair, murs crème, touches orange), dans une "
		"image 1536 × 1024 : grille invisible de 2 colonnes × 2 lignes (cellules de 768 × 512), un "
		"élément par cellule, centré, la base de chacun sur une même ligne horizontale à 40 px du bas "
		"de sa cellule, à une échelle COMMUNE : 1 case = 150 px.\n"
		"1 (ligne 1, à gauche) : VÉLO EXPOSÉ ROUGE sur sa béquille d'exposition, de profil, 2 cases de "
		"long (≈ 300 px), 1 case de haut (panier à l'avant, selle brune). 2 (ligne 1, à droite) : VÉLO "
		"EXPOSÉ BLEU CIEL, même gabarit et même pose, cadre bleu ciel, sacoche arrière. 3 (ligne 2, à "
		"gauche) : VÉLO EXPOSÉ JAUNE, même gabarit et même pose, cadre jaune, sonnette. 4 (ligne 2, à "
		"droite) : ÉTAGÈRE DE CASQUES, une étagère murale basse de bois clair de 4 cases de large "
		"(≈ 600 px) et 1,4 case de haut, portant une rangée de casques de vélo colorés (rouge, bleu, "
		"jaune, vert) et deux petites pompes à pied en bas.\n"
		"Même rendu que le vélo joint ; fond avec une vraie transparence (canal alpha), aucun sol, aucune "
		"ombre portée.",
		[VELO, RATELIER, VELOS_AZ], LUMIERE_NE, 2),
]

## Corrections (T2) : (identifiant de l'image corrigée sans _NE_rN, révision, ancres ajoutées,
## texte qui remplace la description de la planche d'origine). Le prompt part de la table d'origine.
CORRECTIONS = {
	("WORLD_PROP_PONTS_PLANCHE", 2): (
		"PLANCHE de 8 MODULES DE PONT vus de dessus en trois quarts (un pont de ville en pierre et le "
		"long pont de bois d'une rivière), dans une image 1536 × 1024 : grille invisible de 4 colonnes × "
		"2 lignes (cellules de 384 × 512), un module par cellule, centré, à une échelle COMMUNE : 1 case = "
		"90 px. CHAQUE TABLIER EST UN MODULE RÉPÉTABLE : ses deux extrémités (le haut et le bas pour les "
		"ponts verticaux, la gauche et la droite pour le pont horizontal) sont coupées DROIT, bord à bord, "
		"SANS embout, SANS poteau d'angle, SANS chapiteau, de sorte que le module se raccorde sans "
		"couture avec une copie de lui-même posée à la suite ; les parapets et les longerons vont "
		"d'un bout à l'autre du module sans interruption.\n"
		"Ligne 1. Module 1 : TABLIER DE VILLE de 2 cases de large × 4 de long (180 × 360 px), "
		"traversée du haut vers le bas : dalles de pierre claire calepinées, un parapet bas continu de "
		"pierre (muret à couvre-joint arrondi, ≈ 22 px d'épaisseur) de chaque côté, vu de dessus. Module 2 : "
		"TABLIER DE VILLE de 3 cases de large × 4 de long (270 × 360 px), mêmes dalles et mêmes parapets. "
		"Module 3 : TABLIER DE VILLE pour une traversée de GAUCHE À DROITE, 4 cases de long × 2 de large "
		"(360 × 180 px, paysage) : mêmes dalles, parapet du haut vu de face (face en pierre visible, ≈ 32 px "
		"de haut) et parapet du bas vu de dessus (≈ 18 px), continus d'un bout à l'autre. Module 4 : "
		"TABLIER DE BOIS A, pont de rivière de 2 cases de large × 4 de long (180 × 360 px), traversée du "
		"haut vers le bas : planches de bois clair perpendiculaires à la traversée, clouées, quelques "
		"planches un peu plus sombres, un longeron de bois sombre continu de chaque côté (≈ 14 px), aucun "
		"garde-corps.\n"
		"Ligne 2. Module 5 : TABLIER DE BOIS B, même gabarit que 4 (180 × 360), planches décalées, deux "
		"nœuds visibles. Module 6 : TABLIER DE BOIS C, même gabarit, une planche neuve plus claire et un "
		"petit raccord de fer. Module 7 : GARDE-CORPS de pont de bois, un segment de rambarde en pierre "
		"claire et bois de 1 case de long (90 px), 0,5 case de haut (≈ 45 px), vu depuis le côté du "
		"tablier : une lisse de bois sur deux petits balustres de pierre, ses extrémités coupées droit "
		"pour se raccorder avec lui-même ; posé le long du pont, JAMAIS dessus. Module 8 : PILE de pont, "
		"un pilier carré de pierre claire à chapiteau plat, 0,5 case de large (≈ 45 px), 1,2 case de haut "
		"(≈ 108 px), qui sort de l'eau au bord du pont (on voit sa face et un peu de la ligne d'eau "
		"mouillée à son pied).\n"
		"Même pierre que les quais joints (blanc-crème) ; bois clair et chaud. Aucun nom, aucune "
		"inscription.\nFond avec une vraie transparence (canal alpha), aucun sol, aucune eau dessinée "
		"autour, aucune ombre portée."),
}

CORRECTIONS[("INT_ARENE_AZURIA_COQUE", 2)] = (
	"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 17 cases de large × 13 de profondeur "
	"(1 case ≈ 90 px de large, ≈ 79 px de haut). CORRECTION de la salle jointe INT_ARENE_AZURIA_COQUE_NE_r1 : "
	"même salle, mêmes murs, même verrière, mêmes matériaux, même sortie, MAIS LE BASSIN EST TROP LARGE : "
	"le nouveau bassin, MARGELLE COMPRISE, occupe EXACTEMENT 7 cases de large × 5 de profondeur, soit un "
	"rectangle de 632 × 394 px dont le bord gauche est à x = 452 (29 % de la largeur), le bord droit à "
	"x = 1084 (71 %), le bord haut à y = 315 (31 % de la hauteur) et le bord bas à y = 709 (69 %) : "
	"le bassin est donc nettement plus étroit que dans l'image jointe (qui mesure environ 765 px de "
	"large) et il laisse 5 cases de chemin sec de chaque côté (colonnes 1 à 4 et 12 à 16 entièrement "
	"en dalles). Le bassin est centré sur la salle, bordé d'une margelle de pierre claire de 0,3 case, "
	"EAU turquoise limpide STATIQUE (reflets peints, quelques éclats clairs, trois lignes de bassin bleu "
	"marine au fond). Murs : mur du fond = paroi de pierre claire (2 cases du haut) percée de hautes "
	"fenêtres de verre bleuté ; murs latéraux = bandes de 2 cases à gauche et à droite (gradins légers de "
	"deux marches de pierre claire, SYMÉTRIQUES entre gauche et droite) ; mur du bas = deux rangées de "
	"pierre interrompues au milieu par la SORTIE : une ouverture de 3 cases (≈ 270 px) centrée, avec un "
	"paillasson de pierre bleu pâle, sans emblème. Tout le sol sec est un dallage de pierre claire "
	"LIBRE et VIDE (aucun meuble, aucun plongeoir : ils sont ajoutés séparément).")
CORRECTIONS[("UI_OBJETS_J13_PLANCHE", 2)] = (
	"PLANCHE d'UNE icône d'objet peinte pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : l'icône est dans la PREMIÈRE colonne (x de 0 à 384), CENTRÉE dans "
	"cette colonne, de 260 px de large au plus et 260 px de haut au plus, avec au moins 60 px de marge "
	"vide de chaque côté (elle ne touche ni ne dépasse le bord de la colonne) ; les trois autres colonnes "
	"restent VIDES (transparentes), dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE (même "
	"rendu, même angle de trois quarts, même lumière) : la PÉPITE, une grosse pépite d'or brut "
	"irrégulière, arrondie et bosselée, jaune doré chaud avec des reflets clairs et de petites veines "
	"brun-ocre, quelques fines facettes brillantes, posée de trois quarts ; sans pièce, sans lingot. "
	"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : l'objet est net, avec seulement son "
	"contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).")

## Coques : (identifiant, largeur, profondeur, ancres, géométrie, matériaux, vague).
_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus.")
COQUES = [
	("INT_ARENE_AZURIA_COQUE", 17, 13, [COQUE_ARENE, ARENE_AZ],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 17 cases de large × 13 de profondeur "
		"(la préparation l'étire à 1 632 × 1 248 : 1 case ≈ 90 px de large, ≈ 79 px de haut). "
		+ _BASE_COQUE + " Murs : mur du fond = paroi de pierre claire dont on voit la face sur les 2 "
		"cases du haut, percée de hautes fenêtres de verre bleuté ; murs latéraux = bandes de 2 cases "
		"d'épaisseur à gauche et à droite, faites de GRADINS légers (deux marches de pierre claire "
		"vues de dessus) ; mur du bas = deux rangées de pierre, interrompu au milieu par la SORTIE : une "
		"ouverture de 3 cases (≈ 270 px) centrée, avec un paillasson de pierre bleu pâle (au centre "
		"de la 12e rangée), sans aucun emblème. LE BASSIN : au centre de la salle, un bassin rectangulaire "
		"de 7 cases de large × 5 de profondeur (de la 5e à la 11e colonne, de la 5e à la 9e rangée, "
		"≈ 630 × 395 px), peint d'EAU turquoise limpide STATIQUE (reflets peints, quelques éclats clairs, "
		"lignes de bassin bleu marine au fond), bordé d'une margelle de pierre claire de 0,3 case ; "
		"tout autour : des CHEMINS SECS de dalles de pierre claire (sol de la salle) sur 2 rangées au "
		"nord du bassin, 3 colonnes à gauche, 3 colonnes à droite, 2 rangées au sud ; le sol du "
		"chemin est entièrement LIBRE et VIDE (aucun meuble, aucun plongeoir : ils sont ajoutés "
		"séparément). La sortie et le bassin sont exactement l'un au-dessus de l'autre, au centre.",
		"l'Arène d'Azuria, la piscine d'entraînement élégante, mêmes matériaux que la façade jointe "
		"WORLD_BLDG_ARENE_AZURIA_01 : pierre blanc-crème et soubassement bleu-gris ; la lumière de la "
		"verrière est neutre et égale (aucune flaque de lumière peinte, aucun faisceau, aucun reflet "
		"de lumière sur le sol) ; claire, fraîche, calme.", 2),
]

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenues = défauts (règle 4).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_ONDINE", ["REF_R24_ONDINE"], 128, "Ondine, Championne de l'Arène d'Azuria",
		"Ondine, la Championne de l'Arène d'Azuria, jeune fille d'environ 16 ans, énergique, directe et "
		"fière (jamais méchante) : cheveux ORANGE vif relevés en UNE courte queue de cheval sur le CÔTÉ "
		"de la tête (côté droit), yeux vert-bleu, petit nez, sourire franc ; petit débardeur jaune "
		"clair court à col rond, SHORT en jean bleu moyen retenu par des BRETELLES ROUGES, baskets "
		"rouges à semelles blanches, chaussettes blanches courtes, un fin bracelet blanc au poignet "
		"gauche. Taille du héros (un peu plus petite), silhouette sportive. Ni cheveux roses, ni bleus ; "
		"aucun insigne, aucun texte.",
		f"{PIEDS_JOINTS}, la main droite posée sur la hanche, l'autre bras détendu, le menton légèrement "
		"relevé, l'air sûr d'elle", [], 1),
	("PNJ_NAGEUR", ["REF_AZ_NAGEUSE"], 128, "le Nageur de l'Arène d'Azuria (Lucas)",
		"un Nageur, jeune homme d'environ 22 ans, athlétique et décontracté, l'air sympathique : "
		"cheveux bruns courts encore humides, hâlé, des LUNETTES DE NATATION relevées sur le front, une "
		"SERVIETTE blanche autour du cou, un maillot de natation sans manches bleu marine, un SHORT de "
		"bain bleu clair à fines rayures blanches (mi-cuisse), des claquettes de piscine bleues. "
		"Différent du héros (ni casquette ni rouge) et d'Ondine (ni jaune ni orange).",
		f"{PIEDS_JOINTS}, les deux mains tenant les extrémités de la serviette autour de son cou, "
		"l'air détendu", [], 1),
]

## Conditionnels : (identifiant, références, hauteur, rôle, tenue, pose) — personnages dont la
## marche et l'attente ne partent jamais par défaut.
PERSONNAGES_COND = [
	("PNJ_NAGEUSE", ["REF_AZ_NAGEUSE"], 128, "la nageuse H5 d'Azuria",
		"une Nageuse, jeune femme d'environ 20 ans, sportive et souriante : cheveux châtains en "
		"chignon haut, lunettes de natation relevées sur le front, serviette bleu pâle sur l'épaule, "
		"maillot une pièce bleu turquoise à fines bretelles recouvert d'un court paréo blanc noué à la "
		"taille, claquettes blanches. Différente d'Ondine (ni orange, ni jaune) et du Nageur "
		"(ni bleu marine).",
		f"{PIEDS_JOINTS}, la serviette sur l'épaule tenue d'une main", [], 2),
	("PNJ_HABITANTE", ["REF_AZ_VOISINE"], 128, "une habitante d'Azuria (voisine, maison ouverte)",
		"une habitante d'Azuria, femme d'environ 45 ans, bienveillante : cheveux châtain clair "
		"mi-longs attachés d'un ruban bleu, robe longue bleu pervenche à petit col blanc, gilet "
		"crème, ballerines brunes, un petit panier au bras. Différente de Maman (tablier), de "
		"l'infirmière et de la jeune Dresseuse.",
		f"{PIEDS_JOINTS}, les mains jointes devant elle sur son panier", [], 2),
]

## Planche d'icône du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE).
UI = ("UI_OBJETS_J13_PLANCHE",
	"PLANCHE d'UNE icône d'objet peinte pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : l'icône est dans la PREMIÈRE colonne (à gauche), environ 280 px, "
	"les trois autres colonnes restent VIDES, dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE "
	"(même rendu, même angle de trois quarts, même lumière) : la PÉPITE, une grosse pépite d'or brut "
	"irrégulière, arrondie et bosselée, jaune doré chaud avec des reflets clairs et de petites veines "
	"brun-ocre, quelques fines facettes brillantes, posée de trois quarts ; sans pièce, sans lingot, sans "
	"étincelles autour.",
	[MENU_OBJETS], 1)

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées "
		"d'Azuria, de la Route 4 et de la Route 24 (minuscules : n'en copie pas le rendu) ; ")


def _prompt_texture(identifiant: str, ref: str, description: str, ancres: list[str],
		valeurs: str) -> str:
	jointes = (f"Images jointes : {ref} = matériau et couleurs, extrait d'une vue d'ensemble validée "
		f"(minuscule : n'en copie pas le rendu) ; {_noms(STYLE + ancres)} = ancres de style (rendu peint, "
		"finesse, lumière neutre).")
	return (f"{identifiant} — NOUVELLE image : une texture de sol de jeu, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\nASSET : {description}\n{TEXTURE_FIN}\n{INTERDITS}\n")


def _prompt_objet(identifiant: str, ref: str, largeur, hauteur, description: str,
		ancres: list[str], valeurs: str) -> str:
	jointes = (f"Images jointes : {ref} = référence de forme, de matériaux et de couleurs, extraite d'une "
		"vue d'ensemble validée (minuscule : n'en copie pas le rendu) : dessine l'élément comme s'il avait "
		"été extrait de cette image puis agrandi, avec le même angle, mais avec la finesse des ancres. "
		f"{_noms(STYLE + ancres)} = ancres de style de la série (rendu peint, contour coloré, finesse, même "
		"angle de vue, même lumière neutre). Les vues sont en lumière d'ambiance : l'élément garde la "
		"lumière NEUTRE des ancres (le jeu ajoute la lumière lui-même).")
	corps = (f"ASSET : {description}\nFormat : PNG paysage 1536 × 1024 ; l'élément occupe environ 1 300 px "
		f"dans sa plus grande dimension, centré. Échelle : {largeur} cases de large et environ {hauteur} "
		f"de haut ; un adulte mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\n{corps}\n")


def _prompt_planche(identifiant: str, refs: list[str], description: str, ancres: list[str],
		valeurs: str) -> str:
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages "
		f"jointes : {_jointes_refs(refs)}{_noms(ancres)} = ancres de style (rendu peint, contour coloré, "
		f"finesse, angle de vue, lumière neutre) : respecte-les exactement.\n\n{ADN}\n{valeurs}\n\n"
		"EXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une même planche, chacun "
		f"entier dans sa cellule, sans cadre ni séparation.\n{description}\n{INTERDITS}\n")


def _prompt_coque(identifiant: str, geometrie: str, materiaux: str, ancres: list[str]) -> str:
	return (f"{identifiant} — NOUVELLE image : l'enveloppe d'une pièce intérieure de jeu (murs, sol, "
		f"bassin ; aucun meuble).\nImages jointes : {_noms(ancres)} = ancres de style des intérieurs "
		"(rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre) "
		"et matériaux de la façade : respecte-les exactement.\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		"trois quarts, image opaque qui remplit tout le cadre.\n"
		f"Géométrie (respecte-la exactement, c'est un plan de jeu) : {geometrie}\n"
		f"Pièce : {materiaux}\n"
		"Interdit : meubles, plongeoir, bancs, plantes, tapis (sauf le paillasson demandé), personnages, "
		"Pokémon (ni Pikachu), porte fermée, texte, lettres, chiffres, logo, emblème rond de type balle, "
		"perspective avec point de fuite, vue isométrique, ombre portée.\n")


def _prompt_marche(identifiant: str, refs: list[str], tenue: str, ancres: list[str]) -> str:
	texte = ""
	if refs:
		texte += (f" ; {', '.join(refs)} = tenue et silhouette seulement (minuscules, extraites des vues "
			"d'ensemble, rendu à NE PAS copier)")
	if ancres:
		texte += f" ; {_noms(ancres)} = tenue exacte à reprendre (même main, mêmes couleurs)"
	return MODELE_MARCHE.format(ident=identifiant, ref=texte, tenue=tenue) + INTERDITS + "\n"


def _prompt_attente(identifiant: str, role: str, hauteur: int, tenue: str, pose: str) -> str:
	"""Modèle des attentes des séries 10–14."""
	nom = identifiant.removeprefix("PNJ_")
	marche = f"{identifiant}_NE_r1"
	posture = ("POSE D'ATTENTE dans les 4 vues : " + pose + ", les jambes droites et serrées, les PIEDS "
		"JOINTS côte à côte (aucun pied devant l'autre, aucun pas, aucun talon levé), les deux semelles "
		"posées à plat au sol, le buste droit. De profil, les deux jambes se superposent presque : on voit "
		"une seule silhouette de jambes, les deux pieds l'un à côté de l'autre, pas un compas ouvert. De "
		"face et de dos, les deux pieds sont à la même hauteur, rapprochés sous les hanches.")
	return (f"{nom}_ATTENTE — POSE D'ATTENTE (personnage immobile, au repos) du même personnage "
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
		"même taille dans les 4 poses (environ 280 px de haut debout, comme dans la planche jointe), le bas "
		"des 4 poses sur une même ligne horizontale. Pas de sol, pas d'ombre, pas de texte, pas de "
		"numéros, pas de cadres.\n"
		f"- Pose 1 : tourné vers le BAS (vu de face), comme la ligne 1 de {marche}.\n"
		f"- Pose 2 : tourné vers la GAUCHE (de profil), comme la ligne 2 de {marche}.\n"
		f"- Pose 3 : tourné vers la DROITE (de profil), comme la ligne 3 de {marche}.\n"
		f"- Pose 4 : tourné vers le HAUT (vu de dos), comme la ligne 4 de {marche}.\n"
		f"{posture}\n{INTERDITS}\n")


def _prompt_ui(identifiant: str, description: str, format_: str) -> str:
	return (f"{identifiant} — NOUVELLE image pour l'interface (Sac) du jeu Kanto 2026, pas une capture "
		"d'écran.\nLes images jointes donnent la direction artistique et la forme des objets ; n'en "
		f"reproduis ni la mise en page ni les textes.\n\n{RENDU}\n\nIMAGE : {description}\nFormat : "
		f"{format_}.\n{INTERDITS}\n")


def _images() -> list[dict]:
	"""Toutes les images de la série : nom (sans .png), fichier de prompt, texte, jointes (noms dans
	$ART), vague, conditionnel, groupe."""
	images = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, ref, description, ancres, valeurs, vague in SOLS:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres, valeurs),
			[f"{ref}.png"] + STYLE + ancres, vague, groupe=ident)
	for ident, ref, largeur, hauteur, description, ancres, valeurs, vague in SERIE:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
			ancres, valeurs), [f"{ref}.png"] + STYLE + ancres, vague, groupe=ident)
	for ident, refs, description, ancres, valeurs, vague in PLANCHES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres, valeurs),
			[f"{r}.png" for r in refs] + ancres, vague, groupe=ident)
	for ident, largeur, profondeur, ancres, geometrie, materiaux, vague in COQUES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, geometrie, materiaux, ancres),
			ancres, vague, groupe=ident)
	for liste, conditionnel in ((PERSONNAGES, False), (PERSONNAGES_COND, True)):
		for ident, refs, hauteur, role, tenue, pose, ancres, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres),
				[HEROS] + [f"{r}.png" for r in refs] + ancres, vague, conditionnel, groupe=ident)
			court = ident.removeprefix("PNJ_")
			ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
				_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1,
				conditionnel, groupe=ident)
	ident, description, ancres, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres), vague, groupe=ident)
	for ident, ref, description, ancres, valeurs in SOLS_COND:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres, valeurs),
			[f"{ref}.png"] + STYLE + ancres, 2, True, groupe=ident)
	for (ident, rev), description in CORRECTIONS.items():
		nom = f"{ident}_NE_r{rev}" if not ident.startswith("UI_") else f"{ident}_r{rev}"
		precedent = (f"{ident}_NE_r{rev - 1}" if not ident.startswith("UI_") else f"{ident}_r{rev - 1}")
		groupe = f"{ident}_r{rev}"
		base = next((t for t in PLANCHES if t[0] == ident), None)
		if base is not None:
			_, refs, _, ancres_, valeurs, _ = base
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_,
				valeurs), [f"{r}.png" for r in refs] + ancres_, 3, True, groupe=groupe)
			continue
		coque = next((t for t in COQUES if t[0] == ident), None)
		if coque is not None:
			_, _, _, ancres_, _, materiaux, _ = coque
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, description, materiaux,
				[f"{precedent}.png"] + ancres_), [f"{precedent}.png"] + ancres_, 3, True,
				groupe=groupe)
			continue
		ident_ui, _, ancres_ui, _ = UI
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_ui(ident, description,
			"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres_ui), 3, True,
			groupe=groupe)
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	ATTENTES.mkdir(parents=True, exist_ok=True)
	changes = 0
	for image in _images():
		fichier: Path = image["fichier"]
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	print(f"{len(_images())} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}, "
		f"{ATTENTES.relative_to(RACINE)}")


# --- Références et génération ----------------------------------------------------------


def _recadrage(nom: str) -> Image.Image:
	vue, boite = REFS[nom]
	return Image.open(VUES[vue]).convert("RGB").crop(boite)


def references() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for nom in REFS:
		ref = _recadrage(nom)
		ref = ref.resize((ref.width * AGRANDIR, ref.height * AGRANDIR), Image.LANCZOS)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_AZ_*, REF_R4_*, REF_R24_* dans {ART}")


def ancres() -> None:
	"""Copie dans $ART les ancres de style absentes (depuis le checkout principal)."""
	ART.mkdir(parents=True, exist_ok=True)
	manquantes = []
	generees = {i["nom"] + ".png" for i in _images()}
	extra = {j for i in _images() for j in i["jointes"]
		if not j.startswith("REF_") and j not in generees and j not in ANCRES}
	for nom in sorted(set(ANCRES) | extra):
		if (ART / nom).exists() or ART.resolve() == PRINCIPAL.resolve():
			continue
		source = PRINCIPAL / nom
		if source.exists():
			shutil.copy2(source, ART / nom)
		else:
			manquantes.append(nom)
	print("ancres copiées" + (f" ; ABSENTES : {', '.join(manquantes)}" if manquantes else ""))


VAGUES = (1, 2, 3)


def commandes() -> str:
	lignes = [f"ART={ART}"]
	for conditionnel in (False, True):
		for vague in VAGUES:
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
	ancres()
	manquants = [str(i["fichier"]) for i in _images() if not i["fichier"].exists()]
	if manquants:
		print("prompts absents (lancer --prompts) : " + ", ".join(manquants))
		sys.exit(1)
	for vague in VAGUES:
		images = [i for i in _images() if i["vague"] == vague and (
			(not choix and not i["conditionnel"]) or i["groupe"] in choix or i["nom"] in choix)]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(_generer, images):
				print(ligne, flush=True)


# --- Retouches (T5) : recadrage de la partie médiane des tabliers de pierre ----------------

## Tabliers de pierre nord-sud de `WORLD_PROP_PONTS_PLANCHE_NE_r2` : (cellule x0, x1, ordonnées
## de coupe [haut, bas] dans la partie médiane, entre les poteaux d'angle). Les coupes tombent sur
## un joint de dalles ; un parapet coupé reste un bloc de longueur normale une fois raccordé.
DECKS_PIERRE = [(0, 384, 172, 325), (384, 720, 178, 341)]
LONGUEUR_MODULE_CASES = 2


def retoucher_ponts() -> Path:
	"""`PONTS_PLANCHE_NE_r3` = r2 dont les deux tabliers de pierre nord-sud n'ont plus de poteau
	d'angle : on garde leur partie médiane (un parapet continu de chaque côté), remise à la
	longueur de `LONGUEUR_MODULE_CASES` cases à l'échelle de préparation (largeur = cases du
	manifeste), de sorte que le module se raccorde à lui-même. Reproductible : les autres
	modules sont recopiés tels quels."""
	import numpy as np
	source = Image.open(ART / "WORLD_PROP_PONTS_PLANCHE_NE_r2.png").convert("RGBA")
	sortie = source.copy()
	alpha = np.array(source.getchannel("A")) > 32
	largeurs = {0: 2, 1: 3}  # cases de largeur de chaque tablier (manifeste)
	for indice, (x0, x1, haut, bas) in enumerate(DECKS_PIERRE):
		zone = alpha[:490, x0:x1]
		ys, xs = np.where(zone)
		gauche, droite = int(xs.min()) + x0, int(xs.max()) + 1 + x0
		sortie.paste((0, 0, 0, 0), (x0, 0, x1, 500))
		morceau = source.crop((gauche, haut, droite, bas))
		longueur = round((droite - gauche) * LONGUEUR_MODULE_CASES / largeurs[indice])
		morceau = morceau.resize((droite - gauche, longueur), Image.LANCZOS)
		sortie.alpha_composite(morceau, (gauche, 256 - longueur // 2))
	chemin = ART / "WORLD_PROP_PONTS_PLANCHE_NE_r3.png"
	sortie.save(chemin)
	return chemin


def retoucher_pepite() -> Path:
	"""`UI_OBJETS_J13_PLANCHE_r3` = r2 dont la Pépite est remise **dans sa colonne** de 384 px :
	silhouette recadrée (alpha > 32), réduite à 260 px au plus, centrée dans la colonne de
	gauche ; couleurs écrites seulement sous l'alpha (le halo doré des pixels transparents du
	générateur est effacé), les trois autres colonnes restent vides."""
	source = Image.open(ART / "UI_OBJETS_J13_PLANCHE_r2.png").convert("RGBA")
	masque = source.getchannel("A").point(lambda a: 255 if a > 32 else 0)
	objet = source.crop(masque.getbbox())
	echelle = 260 / max(objet.size)
	objet = objet.resize((round(objet.width * echelle), round(objet.height * echelle)), Image.LANCZOS)
	sortie = Image.new("RGBA", source.size, (0, 0, 0, 0))
	sortie.alpha_composite(objet, ((384 - objet.width) // 2, (source.height - objet.height) // 2))
	chemin = ART / "UI_OBJETS_J13_PLANCHE_r3.png"
	sortie.save(chemin)
	return chemin


# --- Manifeste (T5) ---------------------------------------------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"


def _revision(base: str) -> str:
	"""Dernière révision présente dans $ART pour `base` (sans `_rN.png`), `_r1` par défaut."""
	for rev in (4, 3, 2, 1):
		if (ART / f"{base}_r{rev}.png").exists():
			return f"{base}_r{rev}.png"
	return f"{base}_r1.png"


def _planche_objets(base: str, dossier: str, colonnes: int, lignes: int, ids: list[str],
		cases: list[float], contact: float | None) -> dict:
	return {"source": _revision(base), "dossier": f"{_W}{dossier}/", "colonnes": colonnes,
		"lignes": lignes, "ids": ids, "cases": cases, "contact": contact}


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T5 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T5 sur la planche de contrôle. `cases` = largeur en cases de chaque élément."""
	return {
		"objets": [
			{"id": "bldg_arene_azuria_01", "source": _revision("WORLD_BLDG_ARENE_AZURIA_01_NE"),
				"sortie": f"{_W}buildings/bldg_arene_azuria_01.png", "axe": "w", "cases": 12,
				"ombre": True, "contact": 0.12},
			{"id": "bldg_velos_01", "source": _revision("WORLD_BLDG_VELOS_01_NE"),
				"sortie": f"{_W}buildings/bldg_velos_01.png", "axe": "w", "cases": 8,
				"ombre": True, "contact": 0.12},
			{"id": "relief_grotte_azuree_01", "source": _revision("WORLD_RELIEF_GROTTE_AZUREE_01_NE"),
				"sortie": f"{_W}relief/relief_grotte_azuree_01.png", "axe": "w", "cases": 4,
				"ombre": False, "contact": None},
		],
		"sols": [
			{"id": "ground_eau_canal_01", "source": _revision("WORLD_GROUND_EAU_CANAL_01_NE"),
				"sortie": f"{_W}ground/ground_eau_canal_01.png", "taille": 384, "contraste": 1.0,
				"couleur": 1.0, "raccord": 24},
		],
		# Découpe par taches (série 12) ; largeur en cases de chaque élément, ordre de lecture.
		# Quais et berges : 01/02 sol au nord (face), 03 sol au sud (lèvre), 04 côtés (miroir à
		# l'est), 05 angles (miroirs), 06 escalier = rôles de `QUAY_PIECES` (cerulean_map_kit.gd).
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_QUAI_PLANCHE_NE", "relief", 3, 2,
				[f"relief_quai_0{n}" for n in range(1, 7)], [2, 2, 2, 0.21, 0.42, 2], 0.0),
			_planche_objets("WORLD_RELIEF_BERGE_PLANCHE_NE", "relief", 3, 2,
				["relief_berge_01", "relief_berge_02", "relief_berge_03", "relief_berge_04",
					"relief_berge_05", "prop_roseaux_01"], [2, 2, 2, 0.21, 0.42, 1], 0.0),
			_planche_objets("WORLD_PROP_PONTS_PLANCHE_NE", "props", 4, 2,
				["prop_pont_ville_01", "prop_pont_ville_03_01", "prop_pont_ville_ew_01",
					"prop_pont_pepite_tablier_01", "prop_pont_pepite_tablier_02",
					"prop_pont_pepite_tablier_03", "prop_pont_pepite_garde_corps_01",
					"prop_pont_pepite_pile_01"], [2, 3, 4, 2, 2, 2, 1, 0.5], 0.0),
			_planche_objets("WORLD_PROP_VILLE_EAU_PLANCHE_NE", "props", 3, 2,
				["prop_jardiniere_pierre_01", "prop_jardiniere_pierre_02", "prop_arbre_bac_01",
					"prop_banc_pierre_01", "prop_lampadaire_quai_01", "prop_bitte_01"],
				[1, 1, 1, 2, 0.45, 0.5], 0.15),
			_planche_objets("WORLD_PROP_CAMBRIOLAGE_PLANCHE_NE", "props", 3, 2,
				["prop_cloture_arrachee_01", "prop_porte_condamnee_01", "prop_pot_renverse_01",
					"prop_cloture_trou_01", "prop_ruban_01"], [3, 1, 1, 1, 2], 0.1),
			_planche_objets("WORLD_PROP_FERMETURES_PLANCHE_NE", "props", 3, 1,
				["prop_palissade_chantier_01", "prop_palissade_chantier_02", "prop_barriere_croisillon_01"],
				[3, 3, 2], 0.1),
			_planche_objets("WORLD_RELIEF_REBORD_ARDOISE_PLANCHE_NE", "relief", 3, 1,
				["relief_rebord_ardoise_01", "relief_falaise_ardoise_01", "relief_falaise_ardoise_02"],
				[1.5, 3.4, 3.4], 0.0),
			_planche_objets("INT_ARENE_AZURIA_PLANCHE_NE", "interiors", 3, 1,
				["int_plongeoir_01", "int_banc_piscine_01", "int_porte_bouees_01"], [2, 2, 1], 0.2),
			_planche_objets("INT_VELOS_PLANCHE_NE", "interiors", 2, 2,
				["int_velo_expose_01", "int_velo_expose_02", "int_velo_expose_03",
					"int_etagere_casques_01"], [2, 2, 2, 4], 0.2),
		],
		"pieces": [
			{"id": "int_arene_azuria_coque", "source": _revision("INT_ARENE_AZURIA_COQUE_NE"),
				"sortie": f"{_W}interiors/int_arene_azuria_coque.png", "cases": [17, 13]},
		],
		"personnages": [
			{"id": "ondine", "source": _revision("PNJ_ONDINE_NE"), "sortie": f"{_C}ondine_sheet.png",
				"hauteur": 128},
			{"id": "nageur", "source": _revision("PNJ_NAGEUR_NE"), "sortie": f"{_C}nageur_sheet.png",
				"hauteur": 128},
			{"id": "nageuse", "source": _revision("PNJ_NAGEUSE_NE"), "sortie": f"{_C}nageuse_sheet.png",
				"hauteur": 128},
		],
		"attentes": [
			{"id": "ondine_idle", "source": _revision("ONDINE_ATTENTE"),
				"sortie": f"{_C}ondine_idle_sheet.png", "marche": "ondine"},
			{"id": "nageur_idle", "source": _revision("NAGEUR_ATTENTE"),
				"sortie": f"{_C}nageur_idle_sheet.png", "marche": "nageur"},
			{"id": "nageuse_idle", "source": _revision("NAGEUSE_ATTENTE"),
				"sortie": f"{_C}nageuse_idle_sheet.png", "marche": "nageuse"},
		],
	}


## Icône du Sac (T5, `preparer_menu.py` : planche d'une icône en 4 colonnes) → `assets/ui/items/nugget.webp`.
ICONES_IDS = ["nugget"]
## Planches de personnages préparées : (planche, identifiant de données, hauteur de fiche).
PERSONNAGES_JEU = [("ondine", "misty", 128), ("nageur", "swimmer", 128),
	("nageuse", "swimmer_f", 128)]


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 14) ; une section absente est créée en fin de fichier."""
	chemin = ICI / "manifeste.json"
	texte = chemin.read_text()
	m = json.loads(texte)
	ajouts = 0
	for section, entrees in manifeste_donnees().items():
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
	print(f"manifeste : {ajouts} entrée(s) de la série 15 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------


def _ref(nom: str, cases_haut: float | None = None, hauteur: int | None = None) -> Image.Image:
	"""Recadrage d'une vue, à la taille en jeu (1 case = CASE_PLANCHE) ou à `hauteur` px."""
	image = _recadrage(nom).convert("RGBA")
	if hauteur is None:
		vue, _ = REFS[nom]
		hauteur = round(image.height / PX_CASE[vue] * CASE_PLANCHE) if cases_haut is None else round(
			cases_haut * CASE_PLANCHE)
	return _echelle(image, max(1, hauteur) / image.height)


def _si(relatif: str, etiquette: str, fonction=_asset):
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso(f"{_C}heros_sheet.png"), "héros (échelle)")
	w, c, k = _W, _C, CASE_PLANCHE
	p = _Planche(2600, "Route 4, Azuria, Route 24 — kit de la série 15 (T1, jalon 13) : 1 case = 48 px "
		"sur cette planche ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu)", [
		heros,
		(_asset(f"{w}buildings/bldg_centre_01.png"), "bldg_centre_01 8 × 7\nCentre (1er de l'avenue)"),
		(_asset(f"{w}buildings/bldg_boutique_01.png"), "bldg_boutique_01 8 × 7\nBoutique"),
		*_si(f"{w}buildings/bldg_maison_argenta_01.png", "maisons (argenta, a–d)\n7 × 6 : M, m"),
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 4, 6, 8)],
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\nH1–H3, R24"),
		(_asset(f"{w}props/prop_haie_01.png"), "prop_haie_01\nhaies x"),
		(_asset(f"{w}props/prop_buisson_a_01_bourg.png"), "buissons b"),
		(_asset(f"{w}props/prop_rocher_01.png"), "prop_rocher_01\nrochers o"),
		(_asset(f"{w}props/prop_panneau_01.png"), "prop_panneau_01\npanneaux ×4"),
		(_asset(f"{w}props/prop_banc_01.png"), "prop_banc_01\nbancs n"),
		(_asset(f"{w}props/prop_pots_fleurs_01.png"), "pots de fleurs\n(façades)"),
		(_asset(f"{w}props/prop_massif_01.png"), "massif rond\n(place)"),
		(_asset(f"{w}props/prop_cloture_01.png"), "prop_cloture_01\nclôtures c, jardin"),
		(_asset(f"{w}props/prop_tronc_couche_01.png"), "tronc couché\n(arbre qui barre, t)"),
		(_asset(f"{w}props/prop_balustrade_01.png"), "prop_balustrade_01\nbalustrade (ville)"),
		(_asset(f"{w}relief/relief_muret_01.png"), "relief_muret_01\nmuret"),
		(_asset(f"{w}relief/relief_escalier_ville_01.png"), "escalier de ville\nperron de l'Arène"),
		(_asset(f"{w}relief/relief_falaise_01.png"), "falaise (sas, ouest)"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball au sol\n(O1, O2)"),
		*_si(f"{c}dresseuse_sheet.png", "lass : Clara, Alice,\nRomane, Diane, H3, H5", _cellule_perso),
		*_si(f"{c}jeune_dresseur_sheet.png", "youngster : Malo, H6", _cellule_perso),
		*_si(f"{c}scout_sheet.png", "scout : Timéo", _cellule_perso),
		*_si(f"{c}campeur_sheet.png", "camper : Ethan", _cellule_perso),
		*_si(f"{c}garde_sheet.png", "guard : H4 policier", _cellule_perso),
		*_si(f"{c}enfant_sheet.png", "kid : H2", _cellule_perso),
		*_si(f"{c}vieil_homme_sheet.png", "old_man : H1, maison", _cellule_perso),
		*_si(f"{c}guide_arene_sheet.png", "gym_guide", _cellule_perso),
		*_si(f"{c}infirmiere_sheet.png", "nurse", _cellule_perso),
		*_si(f"{c}marchand_sheet.png", "clerk : Boutique,\nvélos", _cellule_perso),
		*_si(f"{c}rival_sheet.png", "rival (n° 3)", _cellule_perso),
	], (40, 90, 50))

	foret = _asset(f"{w}props/tree_foret_03.png")
	pave = _asset(f"{w}ground/ground_paves_01.png")
	p.section("2. VARIATIONS SANS NOUVEL ASSET (échelle, miroir, teinte)", [
		(_teinter(foret, (1.0, 1.0, 0.97)), "forêt de la Route 4\nmoins sèche (R3 × 1,05)"),
		(_teinter(pave, (1.12, 1.12, 1.08)), "pavés éclaircis\n(Shade) : quais, place"),
		*[(_echelle(_asset(f"{w}ground/decals/decal_fleur_{i}.png"), 1.6), f"fleur_{i}\nplus fréquentes\nen ville")
			for i in (2, 4)],
		(_miroir(_asset(f"{w}props/prop_haie_01.png")), "haie miroir"),
		(_teinter(_asset(f"{w}props/prop_banc_01.png"), (1.1, 1.1, 1.1)), "banc + 10 %"),
	], (60, 80, 110))

	p.section("3. NOUVEAUX : EAU ET VILLE (Codex, lumière NE) — référence de la vue à la taille en jeu", [
		heros,
		(_ref("REF_AZ_EAU", hauteur=3 * k), "WORLD_GROUND_EAU_CANAL_01\ntexture (canaux, rivière)"),
		(_ref("REF_AZ_QUAI", 3), "QUAI_PLANCHE\n6 modules (QUAY_PIECES)"),
		(_ref("REF_AZ_PONTS", 3), "PONTS_PLANCHE\nville ×3 (2, 3, ew)"),
		(_ref("REF_R24_PONT", 6), "PONTS_PLANCHE\nPont Pépite : tablier ×3,\ngarde-corps, pile"),
		(_ref("REF_AZ_ARENE", 7), "BLDG_ARENE_AZURIA_01\n12 × 7, verrière"),
		(_ref("REF_AZ_VELOS", 7), "BLDG_VELOS_01\n8 × 7, vitrines"),
		(_ref("REF_AZ_JARDINIERE", 1), "VILLE_EAU_PLANCHE\njardinières ×2"),
		(_ref("REF_AZ_ARBRE_BAC", 3), "arbre en bac,\nbanc, lampadaire, bitte"),
		(_ref("REF_AZ_PORTE_RUBAN", 4), "CAMBRIOLAGE_PLANCHE\nporte condamnée, ruban"),
		(_ref("REF_AZ_JARDIN", 3), "clôture arrachée, trou,\npot renversé"),
		(_ref("REF_AZ_PALISSADE", 2), "FERMETURES_PLANCHE\npalissade, barrière"),
		(_ref("REF_AZ_GROTTE", 4), "GROTTE_AZUREE_01\nîlot 4 × 3,5"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : ROUTE 4 (ardoise) ET ROUTE 24 (berges)", [
		heros,
		(_ref("REF_R4_REBORD", 2), "REBORD_ARDOISE_PLANCHE\nrebord net, SANS planche,\nen ardoise (vue : terre)"),
		(_ref("REF_R4_FALAISE", 2), "falaise du versant ~\n(vue : terre ; cible : ardoise)"),
		(_ref("REF_R24_BERGE_N", 1.6), "BERGE_PLANCHE\nberge naturelle (vue :\nmargelle de pierre)"),
		(_ref("REF_R24_BERGE_S", 1.6), "berge sud (lèvre)"),
		(_ref("REF_R24_PIED_PONT", 4), "pied du pont :\nquais de pierre (réutilisés)"),
	], (110, 60, 90))
	p.section("3 ter. NOUVEAUX : INTÉRIEURS ET PERSONNAGES", [
		heros,
		(_ref("REF_AZ_ARENE", 3), "INT_ARENE_AZURIA_COQUE\n17 × 13 + PLANCHE (plongeoir,\nbanc, porte-bouées)"),
		(_ref("REF_AZ_VELOS", 3), "INT_VELOS_PLANCHE\n3 vélos + étagère de casques"),
		(_ref("REF_R24_ONDINE", hauteur=64), "PNJ_ONDINE\n128 px (+ attente)"),
		(_ref("REF_AZ_NAGEUSE", hauteur=64), "PNJ_NAGEUR\n128 px (+ attente)"),
	], (130, 100, 40))
	icones = [(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
		f"{i}.webp\n(existante, style)") for i in ("poke_ball", "potion")
		if (RACINE / f"assets/ui/items/{i}.webp").exists()]
	p.section("3 quater. ICÔNE DU SAC : UI_OBJETS_J13_PLANCHE (Pépite, chaîne de preparer_menu.py)", [
		*icones, (_ref("REF_AZ_JARDINIERE", hauteur=90), "nugget.webp\n(aucune forme existante)"),
	], (90, 60, 120))
	p.section("3 quinquies. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_ref("REF_AZ_PLACE", 2), "DALLES_CLAIRES_01\nsi les pavés éclaircis\nne suffisent pas"),
		(_ref("REF_AZ_NAGEUSE", hauteur=64), "PNJ_NAGEUSE\nsi lass trop répété (H5)"),
		(_ref("REF_AZ_VOISINE", hauteur=64), "PNJ_HABITANTE\nsi lass / old_man gênent"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits) ET RÉUTILISÉS À LA PLACE", [
		(_ref("REF_AZ_PECHEUR", hauteur=64), "pêcheur H1 → old_man\n(haru nommé exclu)"),
		(_ref("REF_AZ_ENFANT", hauteur=64), "enfant H2 → kid"),
		(_ref("REF_AZ_POLICIER", hauteur=64), "policier H4 → guard"),
		(_ref("REF_AZ_VOISINE", hauteur=64), "voisine H3 → lass"),
		(_ref("REF_AZ_DRESSEUR", hauteur=64), "dresseur H6 → youngster"),
		(_ref("REF_AZ_CLOTURE_EST", hauteur=80), "arbre + clôture est\n→ tronc couché + clôture"),
		(_ref("REF_R24_PONT_TETE", hauteur=80), "recruteur → Sbire ♂\n(série 14, J12 T6)"),
		(_ref("REF_R4_PAROI", hauteur=80), "paroi + cristaux bleus\n(série 14 : ardoise 02)"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


def _jeu(relatif: str, facteur: float = 1.0) -> Image.Image:
	image = Image.open(RACINE / relatif).convert("RGBA")
	return image if facteur == 1.0 else _echelle(image, facteur)


def _cellules(relatif: str, colonnes: int, lignes: int, choix: list[tuple[int, int]]) -> Image.Image:
	feuille = Image.open(RACINE / relatif).convert("RGBA")
	largeur, hauteur = feuille.width // colonnes, feuille.height // lignes
	bande = Image.new("RGBA", (largeur * len(choix), hauteur), (0, 0, 0, 0))
	for i, (colonne, ligne) in enumerate(choix):
		bande.alpha_composite(feuille.crop((colonne * largeur, ligne * hauteur,
			(colonne + 1) * largeur, (ligne + 1) * hauteur)), (i * largeur, 0))
	return bande


def _present(relatif: str, etiquette: str, fonction=_jeu) -> list:
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def controle(sortie: Path) -> Path:
	"""Planche de contrôle du T5 : les assets **préparés** (assets/), à 1:1 (1 case = 96 px)."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(4300, "Série 15 préparée (T5, jalon 13) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	donnees = manifeste_donnees()
	for e in donnees["sols"]:
		if (RACINE / e["sortie"]).exists():
			tuile = Image.open(RACINE / e["sortie"]).convert("RGBA")
			carre = Image.new("RGBA", (192, 192))
			for x in range(0, 192, tuile.width):
				for y in range(0, 192, tuile.height):
					carre.alpha_composite(tuile, (x, y))
			p.section("1. SOL (répété sur 2 × 2 cases)", [heros, (carre, f"{e['id']}\n2 × 2 cases")],
				(40, 90, 50))
	elements = [x for planche_ in donnees["planches_objets"] for ident in planche_["ids"]
		for x in _present(f"{_W}{planche_['dossier'].removeprefix(_W)}{ident}.png", ident)]
	p.section("2. PLANCHES DÉCOUPÉES (quais, berges, ponts, mobilier, indices, intérieurs)",
		[heros, *elements], (60, 80, 110))
	p.section("3. BÂTIMENTS ET REPÈRES", [
		heros,
		*[x for e in donnees["objets"] for x in _present(e["sortie"], e["id"])],
	], (130, 70, 40))
	p.section("4. PERSONNAGES : marche (face, gauche, droite, dos) puis attente", [
		heros,
		*[x for nom, ident, h in PERSONNAGES_JEU for x in _present(f"{_C}{nom}_sheet.png",
			f"{nom} ({ident}) {h} px\nmarche",
			lambda r: _cellules(r, 4, 4, [(0, 0), (1, 1), (1, 2), (0, 3)]))],
		*[x for nom, _, _ in PERSONNAGES_JEU for x in _present(f"{_C}{nom}_idle_sheet.png",
			f"{nom}_idle\nattente", lambda r: _cellules(r, 4, 1, [(n, 0) for n in range(4)]))],
	], (110, 90, 40))
	p.section("5. ICÔNE DU SAC (256 px)", [
		*[x for ident in ICONES_IDS for x in _present(f"assets/ui/items/{ident}.webp", ident)],
	], (120, 40, 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T2, validation 13.0-art) : la dernière révision
	présente de chaque image (_r4 … _r1) sur fond gris moyen, nom et révision dessous. Les
	conditionnels ne sont pas montrés."""
	from PIL import ImageDraw, ImageFont
	cellule, marge, colonnes = 440, 24, 4
	choisies = []
	for image in _images():
		if image["conditionnel"]:
			continue
		base = image["nom"].rsplit("_r", 1)[0]
		for rev in (4, 3, 2, 1):
			chemin = ART / f"{base}_r{rev}.png"
			if chemin.exists():
				choisies.append((f"{base}_r{rev}", chemin))
				break
	lignes = (len(choisies) + colonnes - 1) // colonnes
	feuille = Image.new("RGB", (colonnes * (cellule + marge) + marge,
		lignes * (cellule + 60 + marge) + marge), (118, 118, 124))
	dessin = ImageDraw.Draw(feuille)
	police = ImageFont.load_default()
	for chemin_police in ("/System/Library/Fonts/Helvetica.ttc", "/Library/Fonts/Arial.ttf"):
		if Path(chemin_police).exists():
			police = ImageFont.truetype(chemin_police, 17)
			break
	for i, (nom, chemin) in enumerate(choisies):
		x = marge + (i % colonnes) * (cellule + marge)
		y = marge + (i // colonnes) * (cellule + 60 + marge)
		img = Image.open(chemin).convert("RGBA")
		img.thumbnail((cellule, cellule), Image.LANCZOS)
		fond = Image.new("RGBA", img.size, (118, 118, 124, 255))
		fond.alpha_composite(img)
		feuille.paste(fond.convert("RGB"), (x + (cellule - img.width) // 2, y))
		dessin.text((x, y + cellule + 8), nom.replace("_NE", ""), fill=(255, 255, 255), font=police)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	feuille.save(sortie, optimize=True)
	print(f"{len(choisies)} images")
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--refs" in arguments:
		references()
	elif "--ancres" in arguments:
		ancres()
	elif "--commandes" in arguments:
		print(commandes())
	elif "--planche" in arguments:
		autres = [a for a in arguments if a != "--planche"]
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "AZ_KIT_v1.png"))
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon13_assets" / "serie15_contact.png"))
	elif "--retouches" in arguments:
		print(retoucher_ponts())
		print(retoucher_pepite())
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon13_assets" / "serie15_controle.png"))
	else:
		generer(set(arguments))
