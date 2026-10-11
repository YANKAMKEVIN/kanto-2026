#!/usr/bin/env python3
"""Série 14 — Route 3 et Mont Sélénite (jalon 12, lumière neutre). Liste : docs/tech/jalon-12.md
§1.4 ; fiches : docs/design/fiches-assets/serie-14-mont-selenite.md.

Méthode des J8–J10 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des
vues validées, `docs/design/reference/route-3-vue-generale-v1.png` et
`mont-selenite-vue-generale-v1.png`, essais 2 ; **la grille fait foi** : `tools/plans/route_3.txt`,
`mont_selenite_1f.txt`, `mont_selenite_b1f.txt`, `mont_selenite_b2f.txt`, `route_4_sas.txt`,
contrôlées par `plan_check_route_3.py` et `plan_check_mont_selenite.py`). Presque toute la Route 3
est reprise (forêt serrée, herbes, rebords, rochers, buissons, Centre, Gamin, Scout, voyageur,
randonneuse) ; ne sont générées que **23 images** :
  - Route 3 et sas : sol rocheux (texture), planche de paroi d'ardoise (4 modules), entrée de la
    grotte (reprise en miroir pour la bouche du sas) ;
  - kit de grotte des trois étages : 3 textures (sol calme, gravats, dessus des masses), planche de
    parois (6 modules), planche de repères minéraux (6), mare, échelles (2), puits de jour ;
  - camp Rocket (6 éléments), dalle et fossiles posés (3), indices des objets cachés (2) ;
  - 4 personnages × (marche + attente) : Fillette, Sbire Rocket ♂, Sbire Rocket ♀ (attente « en
    train de creuser »), chercheur de terrain (Gaspard) ;
  - 1 planche de 4 icônes du Sac : Pierre Lune, Corde Sortie, Fossile Dôme, Fossile Nautile.
CONDITIONNELS (jamais lancés sans leur nom ; décision sur capture des T8 / T9, notée dans
etat-projet.md) : WORLD_PROP_AFFLEUREMENTS_PLANCHE (si les rochers existants ne tiennent pas les
blocs `R` de la Route 3), WORLD_RELIEF_BOUCHE_SAS_01 (si l'entrée en miroir ne se lit pas comme une
bouche ouverte vers l'est), UI_ITEM_CT (si le J11 se clôt sans illustration de CT).

Lumière : NE (neutre) pour les objets, les personnages et les icônes ; la lumière de la grotte est
**dans la valeur peinte** des sols et des parois (clair au sol, sombre en masse) et dans les halos
du moteur (jalon-12.md §2.4), jamais dans une ombre portée peinte.

**Les prompts sont versionnés** : `tools/art/prompts/serie14/<NOM>.txt` (un par image) et
`tools/art/attente/prompts/<NOM>_ATTENTE.txt`, écrits par `--prompts` à partir des tables
ci-dessous ; la génération lit ces fichiers. Corriger une image = corriger la table, relancer
`--prompts`, relire le diff ; une correction après génération se lance en `_r2` (fiche).
Références : recadrages REF_R3_* et REF_MS_* des vues validées (`--refs`, boîtes ci-dessous,
agrandies × 3) ; REF_AR_PAROI (vue d'Argenta, ancre de style de la roche, même boîte que la
série 12). Sources et sorties dans $ART (défaut : build/art de cette copie ; sur une autre copie
que le checkout principal, ART=/Users/kevinyankam/dev/kanto-2026/build/art, où sont les ancres).

Usage :
  tools/art/serie14.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie14.py --refs                  recadre les REF_* dans $ART (sans Codex)
  tools/art/serie14.py --commandes             liste les commandes generer.sh du T2 (sans Codex)
  tools/art/serie14.py --planche [sortie.png]  planche de contrôle du kit (sans Codex ;
                                               défaut build/art/MS_KIT_v1.png)
  tools/art/serie14.py --manifeste             ajoute les entrées de la série 14 en fin de
                                               tools/art/manifeste.json (T6, après la validation
                                               des images par Kevin ; NE PAS lancer avant)
  tools/art/serie14.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T6 ;
                                               défaut build/captures/jalon12_assets/serie14_controle.png)
  tools/art/serie14.py [IDENTIFIANT ...]       génère avec Codex, en trois vagues (sans argument :
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
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE, TEXTURE_FIN  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _miroir, _Planche, _teinter)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
REFERENCE = RACINE / "docs/design/reference"
VUES = {
	"R3": REFERENCE / "route-3-vue-generale-v1.png",  # 1536 × 1024, ≈ 18,7 px par case
	"MS": REFERENCE / "mont-selenite-vue-generale-v1.png",  # 1024 × 1536, ≈ 17 px par case
	"AR": REFERENCE / "argenta-vue-generale-v1.png",  # ancre de style (série 12)
}
PROMPTS = ICI / "prompts" / "serie14"
ATTENTES = ICI / "attente" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue).
REFS = {
	# Route 3 (forme et matériaux ; la montagne y est beige : la cible est l'ardoise, §7).
	"REF_R3_PAROI_EST": ("R3", (1180, 0, 1536, 260)),
	"REF_R3_PAROI_SUD": ("R3", (1230, 560, 1536, 900)),
	"REF_R3_ENTREE": ("R3", (1320, 250, 1440, 350)),
	"REF_R3_SOL_ROCHE": ("R3", (845, 340, 1030, 470)),
	"REF_R3_FILLETTE": ("R3", (895, 370, 950, 445)),
	"REF_R3_AFFLEUREMENT": ("R3", (370, 470, 500, 580)),
	# Mont Sélénite : 1F (y 0..610), B1F (620..1010), B2F (1030..1536).
	"REF_MS_SOL": ("MS", (150, 220, 250, 320)),
	"REF_MS_GRAVATS": ("MS", (745, 280, 860, 445)),
	"REF_MS_PAROI": ("MS", (370, 370, 720, 500)),
	"REF_MS_MASSE": ("MS", (0, 430, 180, 620)),
	"REF_MS_SECTEUR": ("MS", (380, 230, 720, 600)),
	"REF_MS_COLONNE": ("MS", (480, 270, 550, 350)),
	"REF_MS_COLONNES": ("MS", (465, 1105, 605, 1215)),
	"REF_MS_ROCHER": ("MS", (200, 252, 232, 285)),
	"REF_MS_ECLATS": ("MS", (680, 360, 730, 410)),
	"REF_MS_MARE": ("MS", (725, 35, 820, 95)),
	"REF_MS_PUITS": ("MS", (465, 480, 565, 560)),
	"REF_MS_ENTREE_1F": ("MS", (470, 560, 560, 612)),
	"REF_MS_ECHELLE_V": ("MS", (800, 530, 845, 585)),
	"REF_MS_ECHELLE_U": ("MS", (255, 630, 295, 670)),
	"REF_MS_CAISSES": ("MS", (130, 160, 190, 215)),
	"REF_MS_LAMPE": ("MS", (230, 165, 262, 198)),
	"REF_MS_FOUILLE": ("MS", (130, 330, 195, 390)),
	"REF_MS_TRANCHEE": ("MS", (255, 875, 320, 935)),
	"REF_MS_PROJECTEUR": ("MS", (425, 1375, 465, 1415)),
	"REF_MS_DALLE": ("MS", (470, 1385, 590, 1450)),
	"REF_MS_GUETTEUR": ("MS", (445, 635, 490, 700)),
	"REF_MS_FOUILLEUSE": ("MS", (320, 870, 385, 945)),
	"REF_MS_GARDIEN": ("MS", (505, 1290, 550, 1355)),
	"REF_MS_CHERCHEUR": ("MS", (295, 1385, 345, 1455)),
	# Écarts des vues volontairement non reproduits (dossier 15, « Vues générales peintes v1 »).
	"REF_MS_NOSFERAPTI": ("MS", (365, 120, 435, 180)),
	"REF_MS_MELOFEE": ("MS", (850, 275, 895, 330)),
	"REF_MS_RACAILLOU": ("MS", (635, 80, 695, 130)),
	"REF_MS_PARAS": ("MS", (595, 735, 645, 795)),
	"REF_MS_RANDONNEUR": ("MS", (865, 430, 910, 500)),
	# Ancre de style de la roche : la vue d'Argenta (même boîte que REF_AR_PAROI de la série 12).
	"REF_AR_PAROI": ("AR", (0, 0, 600, 140)),
}
AGRANDIR = 3

## Ancres de style (images validées des séries précédentes, dans $ART).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
PAROI_12 = "WORLD_RELIEF_PAROI_PLANCHE_NE_r1.png"
ROCHER = "WORLD_PROP_ROCHER_01_NE_r1.png"
HEROS = "PERSO_P2_PEINT_r1.png"
# Images de la série 14 jointes aux vagues suivantes.
SOL_GROTTE = "WORLD_GROUND_GROTTE_01_NE_r1.png"
MASSE = "WORLD_GROUND_MASSE_ROCHE_01_NE_r1.png"
ARDOISE = "WORLD_RELIEF_PAROI_ARDOISE_PLANCHE_NE_r1.png"
PROPS_GROTTE = "WORLD_PROP_GROTTE_PLANCHE_NE_r1.png"
ICONES = "UI_OBJETS_J12_PLANCHE_r1.png"
SBIRE_H = "PNJ_SBIRE_ROCKET_H_NE_r1.png"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo (sauf l'emblème demandé), "
	"animaux réels ou faune non-Pokémon (oiseaux, chauves-souris réelles, insectes, araignées), Pikachu "
	"et tout Pokémon non demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac "
	"à dos jaune), squelette, os, crâne, toile d'araignée, élément effrayant.")

## Valeurs de la grotte (sols et parois). La lumière du jeu (profils de grotte, halos) s'ajoute
## par-dessus : ces valeurs sont la base « éclairée » que le moteur assombrit.
VALEURS_GROTTE = ("VALEURS DE GROTTE (exception de palette à l'ADN : la montagne est froide) : ardoise, "
	"pierre froide et gris bleuté, touches minérales claires ; lumière NEUTRE, diffuse et blanche, venant "
	"légèrement du haut à gauche, aucune teinte dorée ni orangée (les lampes et les puits de jour sont "
	"ajoutés par le jeu). La lisibilité est DANS LA VALEUR PEINTE : le sol praticable est CLAIR, les faces "
	"de paroi sont moyennes à sombres, le dessus des masses rocheuses est TRÈS SOMBRE ; le contraste entre "
	"le sol et la paroi reste net (rapport de luminosité d'au moins 2). Aucune ombre portée, aucune flaque "
	"de lumière peinte, aucun vignettage.")

## Uniforme commun des Sbires (B-7 : sombre, R rouge, ni militaire ni caricature, aucun chef).
UNIFORME = ("l'uniforme de la Team Rocket, sobre et légèrement modernisé dans la main peinte du jeu : "
	"blouson court NOIR anthracite à col montant, fermé, aux coutures discrètes gris foncé, avec un grand "
	"R majuscule ROUGE vif, simple et plein, au milieu de la poitrine (le SEUL emblème, aucune autre lettre "
	"ni aucun logo) ; pantalon noir droit ; ceinture gris foncé ; gants gris clair ; bottes courtes gris "
	"clair ; CASQUETTE NOIRE unie à visière courte, sans insigne. Une seule couleur vive : le R rouge. "
	"Ni grade, ni galon, ni arme, ni équipement tactique, ni masque, ni lunettes noires ; pas une tenue de "
	"soldat ; pas un méchant de dessin animé (ni rictus exagéré, ni pose théâtrale). Aucune ressemblance avec "
	"un personnage connu de la série (ni cheveux roses, bleus ou violets, ni uniforme blanc).")


# --- Tables ------------------------------------------------------------------------------

## Textures de sol (opaques, raccordables) : (identifiant, référence, description, ancres,
## valeurs, vague).
SOLS = [
	("WORLD_GROUND_ROCHE_01", "REF_R3_SOL_ROCHE",
		"texture de sol ROCHEUX praticable du pied de la montagne (est de la Route 3, plateau du Centre, "
		"parvis de la grotte, sas de la Route 4) : terre battue gris-beige claire et sèche, semée de petits "
		"cailloux et de graviers gris clair et ardoise, quelques plaques plates de roche affleurante au ras "
		"du sol, de RARES brins d'herbe sèche jaune-vert ; valeur claire, lisible comme un sol où l'on "
		"marche ; plus froide, plus minérale et plus caillouteuse que le chemin de terre joint (à ne pas "
		"copier) ; aucun gros rocher, aucune touffe d'herbe haute.",
		["WORLD_GROUND_CHEMIN_01_NE_r1.png"], LUMIERE_NE, 1),
	("WORLD_GROUND_GROTTE_01", "REF_MS_SOL",
		"texture du SOL CALME de la grotte (couloirs et salles sans rencontre) : roche plate et tassée gris "
		"beige pâle légèrement froid, larges dalles naturelles aux joints doux et peu marqués, fine poussière "
		"claire, quelques minuscules gravillons isolés ; surface lisse et reposante, la plus CLAIRE des trois "
		"textures de la grotte (luminosité moyenne-claire, environ 65 à 75 %) ; aucune flaque, aucun tas de "
		"gravats, aucun cristal.",
		["REF_AR_PAROI.png"], VALEURS_GROTTE, 1),
	("WORLD_GROUND_GRAVATS_01", "REF_MS_GRAVATS",
		"texture des GRAVATS de la grotte (le seul terrain de rencontre sous terre) : tapis serré de "
		"cailloux anguleux et de pierres cassées brun ocre et gris-brun, de tailles mêlées (du gravillon au "
		"caillou de la taille d'un poing), petits creux plus sombres entre les pierres ; nettement plus CHAUD, "
		"plus BRUN et plus GRANULEUX que le sol calme joint (on voit au premier coup d'œil qu'on marche sur "
		"autre chose), d'une luminosité proche (environ 50 à 60 %), jamais noire ; motif régulier, sans gros "
		"bloc.",
		[SOL_GROTTE], VALEURS_GROTTE, 2),
	("WORLD_GROUND_MASSE_ROCHE_01", "REF_MS_MASSE",
		"texture du DESSUS des masses rocheuses de la grotte (cases de paroi vues de dessus, "
		"infranchissables) : roche d'ardoise bleu-gris très SOMBRE (luminosité environ 15 à 25 %), grands "
		"blocs facettés vus de dessus, arêtes à peine plus claires, crevasses bleu nuit ; se lit comme une "
		"masse pleine et inaccessible, nettement plus sombre que le sol calme joint (rapport de luminosité "
		"d'au moins 3) ; aucun cristal, aucune lumière, aucune herbe.",
		[SOL_GROTTE], VALEURS_GROTTE, 2),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases,
## description, ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_RELIEF_ENTREE_GROTTE_01", "REF_R3_ENTREE", 4, 3,
		"l'ENTRÉE du Mont Sélénite, ouverte dans la paroi d'ardoise de la montagne (deuxième repère de la "
		"fin de la Route 3) : un module de PAROI d'ardoise gris bleuté de 4 cases de large et 3 de haut, de "
		"la même roche et de la même hauteur que les modules de la planche jointe "
		"WORLD_RELIEF_PAROI_ARDOISE_PLANCHE (il se raccorde à gauche et à droite), percé au MILIEU de son bas "
		"d'une OUVERTURE de grotte arrondie de 2 cases de large et environ 1,6 case de haut, noir bleuté à "
		"l'intérieur (on ne voit rien dedans, juste un peu de profondeur), coiffée d'un linteau naturel de "
		"gros blocs ; un seuil de terre claire et de petits cailloux au ras du bas de l'image, dans "
		"l'ouverture. Aucun étai de bois, aucune marche, AUCUN ESCALIER, aucune porte, aucune grille, aucun "
		"panneau, aucune lanterne.",
		[ARDOISE, PAROI_12], LUMIERE_NE, 2),
	("WORLD_PROP_MARE_GROTTE_01", "REF_MS_MARE", 4, 3,
		"une MARE souterraine du secteur nord du 1F (repère), vue de dessus, À PLAT au niveau du sol : un "
		"bassin d'eau calme rectangulaire aux angles arrondis, de 4 cases de large et 3 de profondeur, eau "
		"bleu profond presque noire au centre, petites vaguelettes claires peintes en touches, reflets froids ; "
		"un bord de roche claire et lisse tout autour, un peu irrégulier. Aucune plante, aucun Pokémon, aucune "
		"lumière qui sort de l'eau.",
		[SOL_GROTTE], VALEURS_GROTTE, 2),
	("WORLD_DECAL_PUITS_JOUR_01", "REF_MS_PUITS", 4, 3,
		"une DÉCALCOMANIE de lumière à poser sur le sol de la grotte : la tache de JOUR qui tombe d'une "
		"fissure du plafond (puits de jour du hall du 1F), vue de dessus, À PLAT : une forme rectangulaire de "
		"4 cases × 3 aux bords très doux et un peu irréguliers, lumière blanche neutre à peine crème, plus "
		"intense au centre et qui se fond en transparence progressive vers les bords. UNIQUEMENT la lumière : "
		"pas de sol, pas de cailloux, pas de rayons verticaux, pas de poussière (le sol est dessous, le jeu "
		"ajoute le halo). Le centre reste semi-transparent (environ 60 % d'opacité au plus).",
		[SOL_GROTTE], VALEURS_GROTTE, 2),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("WORLD_RELIEF_PAROI_ARDOISE_PLANCHE", ["REF_R3_PAROI_EST", "REF_R3_PAROI_SUD", "REF_AR_PAROI"],
		"PLANCHE de 4 modules de PAROI ROCHEUSE de montagne en ARDOISE (la montagne qui passe du beige "
		"chaud d'Argenta à l'ardoise et au gris bleuté vers l'est : masse de l'est de la Route 3, parvis de "
		"la grotte, paroi du sas de la Route 4), dans une image 1536 × 1024 : grille invisible de 2 colonnes "
		"× 2 lignes (cellules de 768 × 512), un module par cellule, centré, la base de chaque module sur une "
		"même ligne horizontale à 30 px du bas de sa cellule. Chaque module fait 4 cases de large et 3 de "
		"haut (environ 680 × 510 px : 1 case = 170 px), EXACTEMENT la découpe et la hauteur de la planche "
		"jointe WORLD_RELIEF_PAROI_PLANCHE (les deux planches se raccordent bout à bout ; garde sa manière "
		"de peindre, change seulement la roche). Roche d'ARDOISE gris bleuté froid, en couches feuilletées "
		"obliques et en grandes facettes, arêtes claires gris perle du côté éclairé, ombres propres bleu "
		"ardoise ; plus froide et un peu plus sombre que la paroi beige jointe ; mousse rare vert sombre sur "
		"les replats, aucune herbe jaune, aucune fleur. Les vues jointes montrent une montagne BEIGE : n'en "
		"garde que les formes.\n"
		"Module 1 (en haut à gauche) : FACE de paroi A, falaise verticale vue de face, crête irrégulière en "
		"haut, pied droit en bas. Module 2 (en haut à droite) : FACE de paroi B, même hauteur, une faille "
		"verticale, deux ou trois petits éclats minéraux bleu pâle très discrets incrustés, un petit éboulis "
		"au pied ; les modules 1 et 2 se raccordent bout à bout par leurs bords gauche et droit. Module 3 (en "
		"bas à gauche) : EXTRÉMITÉ GAUCHE de la paroi, qui descend en gradins vers la gauche et finit en gros "
		"blocs posés au sol. Module 4 (en bas à droite) : DESSUS DE MASSIF, amas serré de pitons et de blocs "
		"d'ardoise vus de dessus en trois quarts, sans face avant nette, pour remplir l'intérieur d'une "
		"masse : il se raccorde sur ses quatre côtés.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[PAROI_12, ROCHER], LUMIERE_NE, 1),
	("WORLD_RELIEF_PAROI_GROTTE_PLANCHE", ["REF_MS_PAROI", "REF_MS_SECTEUR"],
		"PLANCHE de 6 modules de PAROI de grotte (les bords des masses rocheuses qui entourent les galeries "
		"du Mont Sélénite), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules "
		"de 512 × 512), un module par cellule, centré, la base de chacun sur une même ligne horizontale à 40 px "
		"du bas de sa cellule, à une échelle COMMUNE : 1 case = 150 px. Roche d'ardoise gris bleuté : le "
		"DESSUS des masses est très sombre (comme la texture jointe WORLD_GROUND_MASSE_ROCHE_01), les FACES "
		"verticales sont moyennes à sombres, en facettes verticales, avec une arête claire en haut et un pied "
		"un peu plus clair qui touche le sol (le sol, clair, est celui de la texture jointe "
		"WORLD_GROUND_GROTTE_01 et n'est PAS dessiné). Même manière de peindre que la planche jointe "
		"WORLD_RELIEF_PAROI_PLANCHE.\n"
		"1 (ligne 1, à gauche) : FACE A, bord SUD d'une masse vu de face, 3 cases de large × 2 de haut : en "
		"haut une bande du dessus sombre, puis l'arête claire, puis la face verticale ; bord bas droit et "
		"net. 2 (ligne 1, au milieu) : FACE B, identique en hauteur, une fissure verticale et deux ou trois "
		"blocs tombés au pied ; 1 et 2 se raccordent bout à bout par leurs bords gauche et droit. "
		"3 (ligne 1, à droite) : ANGLE SAILLANT, 2 cases × 2 : l'extrémité gauche d'une face, qui tourne "
		"vers le haut de l'image et devient un bord latéral. 4 (ligne 2, à gauche) : ANGLE RENTRANT, 2 cases "
		"× 2 : le coin intérieur d'une salle, où un bord latéral (à gauche) rejoint une face (en haut). "
		"5 (ligne 2, au milieu) : BORD LATÉRAL, bande VERTICALE d'une case de large et 3 de haut : le côté "
		"gauche ou droit d'une masse vu de dessus, une arête claire et une mince bande de face. 6 (ligne 2, à "
		"droite) : LÈVRE NORD, bande HORIZONTALE de 3 cases de large et une de haut : le bord d'une masse "
		"située au sud d'une galerie, vu de dessus, juste une arête claire légèrement en surplomb, sans face "
		"visible.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[SOL_GROTTE, MASSE, PAROI_12], VALEURS_GROTTE, 2),
	("WORLD_PROP_GROTTE_PLANCHE", ["REF_MS_COLONNE", "REF_MS_COLONNES", "REF_MS_ROCHER",
			"REF_MS_ECLATS"],
		"PLANCHE de 6 repères minéraux du Mont Sélénite (embranchements lisibles sans carte), dans une image "
		"1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un élément par "
		"cellule, centré, la base de chacun sur une même ligne horizontale à 40 px du bas de sa cellule, à une "
		"échelle COMMUNE : 1 case = 150 px. Roche d'ardoise gris bleuté, arêtes claires, ombres propres bleu "
		"froid ; posés sur le sol clair de la texture jointe (non dessiné).\n"
		"1 (ligne 1, à gauche) : GRANDE COLONNE rocheuse du carrefour du 1F, 2 cases de large × 2 de "
		"profondeur, environ 2,4 cases de haut : pilier massif tronqué, sommet plat facetté, pied large, "
		"stries verticales. 2 (ligne 1, au milieu) : COLONNE FINE d'une case, environ 1,6 case de haut (la "
		"salle aux quatre colonnes du B2F), même roche. 3 (ligne 1, à droite) : ROCHER de grotte arrondi d'une "
		"case, environ 0,8 case de haut. 4 (ligne 2, à gauche) : ROCHER de grotte plus anguleux d'une case, "
		"environ 0,7 case de haut. 5 (ligne 2, au milieu) : ÉCLATS DE PIERRE LUNE, une grappe de 3 ou 4 "
		"cristaux bleu pâle et blanc lunaire qui sortent d'un petit bloc d'ardoise, une case, environ 1 case "
		"de haut ; les cristaux ont leur propre éclat peint (reflets clairs sur leurs facettes), AUCUNE lueur "
		"autour. 6 (ligne 2, à droite) : ÉCLATS variante, 2 cristaux plus bas et plus larges, une case.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[SOL_GROTTE, ROCHER], LUMIERE_NE, 2),
	("WORLD_PROP_ROCKET_PLANCHE", ["REF_MS_CAISSES", "REF_MS_LAMPE", "REF_MS_FOUILLE",
			"REF_MS_TRANCHEE", "REF_MS_PROJECTEUR"],
		"PLANCHE de 6 éléments du chantier de la Team Rocket dans la grotte (indices sans personnage, puis "
		"camp de la chambre des fossiles), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 "
		"lignes (cellules de 512 × 512), un élément par cellule, centré, la base de chacun sur une même ligne "
		"horizontale à 40 px du bas de sa cellule, à une échelle COMMUNE : 1 case = 150 px. Matériel de "
		"chantier sobre et fonctionnel : métal gris foncé, bois brun, toile sombre.\n"
		"1 (ligne 1, à gauche) : LAMPE DE CHANTIER posée au sol, une case, environ 0,9 case de haut : "
		"lanterne électrique robuste à cadre de métal noir et poignée, verre allumé jaune pâle peint CLAIR "
		"(le jeu ajoute le halo : aucune lueur autour). 2 (ligne 1, au milieu) : CAISSE de bois sombre d'une "
		"case, cerclée de métal, marquée sur sa face avant d'un grand R majuscule ROUGE vif peint au pochoir "
		"(le seul emblème). 3 (ligne 1, à droite) : DEUX CAISSES identiques empilées en quinconce, 2 cases "
		"de large, chacune marquée du même R rouge. 4 (ligne 2, à gauche) : TRANCHÉE de fouille, 3 cases × 3, "
		"vue de dessus : trou rectangulaire peu profond dans la roche, bord de planches de bois posées à "
		"plat, terre et gravats retournés en petits tas, une pioche et une pelle posées en travers. "
		"5 (ligne 2, au milieu) : PROJECTEUR de chantier sur trépied de métal, une case, environ 1,5 case de "
		"haut, tête ronde inclinée vers le bas, verre peint clair (aucun faisceau dessiné). 6 (ligne 2, à "
		"droite) : OUTILS DE FOUILLE posés, une case : un seau de métal, un tamis rond et un petit marteau.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		["WORLD_PROP_CAISSES_01_NE_r1.png", "WORLD_PROP_TONNEAU_01_NE_r1.png"], LUMIERE_NE, 1),
	("WORLD_PROP_ECHELLES_PLANCHE", ["REF_MS_ECHELLE_V", "REF_MS_ECHELLE_U"],
		"PLANCHE des 2 passages entre les étages de la grotte (ils doivent être CLAIREMENT VISIBLES), dans "
		"une image 1536 × 1024 : grille invisible de 2 colonnes (cellules de 768 × 1024), un élément par "
		"colonne, centré, la base des deux sur une même ligne horizontale à 60 px du bas, à une échelle "
		"COMMUNE : 1 case = 200 px. Bois brun clair bien lisible sur la roche sombre, métal gris pour les "
		"fixations.\n"
		"1 (à gauche) : ÉCHELLE QUI DESCEND : un PUITS carré noir bleuté d'une case dans le sol, vu de dessus, "
		"bordé de quatre planches de bois, d'où dépassent les deux montants et les trois derniers barreaux "
		"d'une échelle de bois (environ 1,2 case de haut au-dessus du sol) ; on comprend qu'on descend. "
		"2 (à droite) : ÉCHELLE QUI MONTE : une échelle de bois d'une case de large, dressée contre une face de "
		"roche (non dessinée), environ 2 cases de haut, barreaux réguliers, dont le haut disparaît dans un "
		"petit trou noir bleuté bordé de roche peint en haut de l'élément ; on comprend qu'on monte.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[ROCHER], LUMIERE_NE, 1),
	("WORLD_PROP_DALLE_FOSSILES_PLANCHE", ["REF_MS_DALLE"],
		"PLANCHE de 3 éléments de la chambre des fossiles (B2F), dans une image 1536 × 1024 : grille "
		"invisible de 3 colonnes (cellules de 512 × 1024), un élément par colonne, centré, la base des trois "
		"sur une même ligne horizontale à 60 px du bas, à une échelle COMMUNE : 1 case = 150 px.\n"
		"1 (à gauche) : la DALLE des fossiles, 3 cases de large × 1 de profondeur, environ 0,4 case de haut : "
		"une dalle de pierre claire plate et basse, bord taillé, surface lisse un peu poussiéreuse, deux "
		"pinceaux de fouilleur posés au bout droit ; RIEN posé dessus au milieu (les fossiles sont des objets "
		"séparés). 2 (au milieu) : le FOSSILE DÔME posé, environ 0,6 case de large : EXACTEMENT le même "
		"objet que l'icône 3 de la planche jointe UI_OBJETS_J12_PLANCHE (fidèle au Fossile Dôme officiel de "
		"Pokémon Rouge/Bleu), vu de trois quarts depuis le dessus comme le jeu. 3 (à droite) : le FOSSILE "
		"NAUTILE posé, environ 0,6 case de large : EXACTEMENT le même objet que l'icône 4 de la planche "
		"jointe (fidèle au Fossile Nautile officiel), même vue. Les fossiles peints sur la vue jointe ne "
		"font PAS foi (formes inventées) : suis la planche d'icônes.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[ICONES, ROCHER], LUMIERE_NE, 2),
	("WORLD_PROP_INDICES_PLANCHE", [],
		"PLANCHE des 2 INDICES discrets des objets cachés (on les trouve en se plaçant face à eux ; ils "
		"doivent attirer l'œil d'un joueur attentif sans crier « objet » : aucun éclat de lumière, aucune "
		"étoile), dans une image 1536 × 1024 : grille invisible de 2 colonnes (cellules de 768 × 1024), un "
		"élément par colonne, centré, la base des deux sur une même ligne horizontale à 60 px du bas, à une "
		"échelle COMMUNE : 1 case = 300 px.\n"
		"1 (à gauche) : le CAILLOU de la Route 3 (posé sur l'herbe), environ 0,7 case de large et 0,5 de "
		"haut : un rocher bas et arrondi d'une teinte DIFFÉRENTE des rochers gris joints (beige rosé plus "
		"clair et plus lisse), une petite tache de lichen pâle ; seul, sans herbe autour. 2 (à droite) : "
		"l'ÉCLAT isolé de la grotte (au pied d'une paroi), environ 0,6 case de large et 0,5 de haut : un "
		"caillou d'ardoise sombre dans lequel est à demi enfoncé UN SEUL petit éclat minéral blanc bleuté, "
		"plus petit et plus terne que les grappes d'éclats de la planche jointe WORLD_PROP_GROTTE_PLANCHE "
		"(à ne pas copier).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[PROPS_GROTTE, ROCHER, "WORLD_PROP_PIERRES_01_NE_r1.png"], LUMIERE_NE, 3),
]

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenues = défauts
## (règle 4).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_FILLETTE", ["REF_R3_FILLETTE"], 108, "la Fillette, Dresseuse débutante de la Route 3",
		"une Fillette (classe de Dresseuse de la Route 3), petite fille d'environ 10 ans, PLUS PETITE que les "
		"adultes (environ 80 % de la taille du héros), joyeuse et sûre d'elle : longs cheveux châtains "
		"détachés avec un petit nœud rose sur le côté, chemisier blanc à manches courtes et col rond, robe "
		"chasuble BLEU CIEL, chaussettes blanches, ballerines brunes, petite sacoche ronde rose en "
		"bandoulière. Différente de la jeune Dresseuse de Jadielle (veste orange, serre-tête jaune : ni "
		"orange, ni serre-tête), de l'enfant de Jadielle et du héros. Elle sert à DEUX Dresseuses (Léa, "
		"Inès) : rien de personnel.",
		f"{PIEDS_JOINTS}, les deux mains jointes derrière le dos, un petit sourire", [], 1),
	("PNJ_SBIRE_ROCKET_H", ["REF_MS_GUETTEUR", "REF_MS_GARDIEN"], 128,
		"un Sbire Rocket (homme), le guetteur et le gardien de la grotte",
		"un Sbire de la Team Rocket, homme anonyme d'environ 25 ans, mince, l'air froid et attentif (ni "
		"brute, ni clown) : cheveux noirs courts qui dépassent à peine de la casquette, rasé, sourcils "
		f"droits. Il porte {UNIFORME} Il sert à DEUX Sbires (le guetteur et le gardien) : rien de personnel.",
		f"{PIEDS_JOINTS}, les deux mains jointes DANS LE DOS, le buste droit, le regard attentif de quelqu'un "
		"qui surveille un passage", [], 1),
	("PNJ_SBIRE_ROCKET_F", ["REF_MS_FOUILLEUSE"], 124,
		"une Sbire Rocket (femme), la fouilleuse de la grotte",
		"une Sbire de la Team Rocket, femme anonyme d'environ 25 ans, l'air concentré et impatient : cheveux "
		"BRUN FONCÉ attachés en une courte queue de cheval basse qui dépasse de la casquette, aucune mèche "
		f"colorée. Elle porte {UNIFORME} En plus : des genouillères gris foncé, les manches du blouson "
		"retroussées aux avant-bras, une petite PIOCHE de fouille à manche de bois accrochée à la ceinture "
		"pour la marche. Exactement le même uniforme que le Sbire de la planche jointe "
		"PNJ_SBIRE_ROCKET_H (même noir, même R rouge, même casquette, mêmes gants et bottes), seuls la "
		"personne et les genouillères changent.",
		None, [SBIRE_H], 2),
	("PNJ_CHERCHEUR_FOSSILES", ["REF_MS_CHERCHEUR"], 128,
		"Gaspard, chercheur de fossiles indépendant (scientifique de terrain)",
		"Gaspard, chercheur de fossiles indépendant, homme d'environ 35 ans, scientifique de TERRAIN un peu "
		"échevelé, méfiant mais pas méchant : cheveux bruns en bataille, petite barbe de quelques jours, "
		"lunettes rondes à monture fine, CASQUE colonial de toile beige clair poussiéreux, gilet de terrain "
		"sable à nombreuses poches sur une chemise bleu pâle aux manches retroussées, pantalon de toile brun "
		"aux genoux poussiéreux, grosses chaussures de marche, une SACOCHE de cuir en bandoulière, une brosse "
		"et un petit marteau de géologue glissés à la ceinture. PAS de blouse blanche (différent des "
		"chercheurs du Musée et du laboratoire), pas de gros sac à dos (différent du Montagnard et de la "
		"Randonneuse), ni chapeau de paille ni bob.",
		f"{PIEDS_JOINTS}, la main gauche le long du corps, la main droite tenant la sangle de la sacoche, "
		"l'air un peu sur ses gardes", [], 1),
]

## Attente « en train de creuser » de la fouilleuse (jalon-12.md §1.4, §2.11) : une pose par
## direction, comme toutes les attentes (le moteur ne joue qu'une image par direction).
CREUSE = ("POSE D'ATTENTE « EN TRAIN DE FOUILLER » dans les 4 vues (elle est absorbée par son travail et ne "
	"lève pas la tête) : un genou à terre, l'autre jambe pliée devant, le buste penché vers le sol, les DEUX "
	"mains sur le manche de la petite pioche dont la pointe touche le sol juste devant elle, au moment où elle "
	"gratte la roche ; la casquette baissée vers le sol. Le personnage est donc plus BAS que debout (environ "
	"75 % de sa hauteur debout) mais à la MÊME ÉCHELLE que la planche jointe (même taille de tête, même "
	"largeur d'épaules). Le point le plus bas (genou et pied posés) sur la même ligne horizontale dans les "
	"4 poses. De profil, la pioche est devant elle, du côté où elle regarde ; de face, on la voit gratter "
	"devant ses pieds ; de dos, on voit son dos penché et la pioche dépasser devant. Aucun sol, aucun "
	"caillou, aucune poussière dessinés.")

## Planche d'icônes du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE) :
## (identifiant, description, ancres, vague).
UI = ("UI_OBJETS_J12_PLANCHE",
	"PLANCHE de 4 icônes d'objets peintes pour le Sac, alignées sur une ligne, chacune dans une colonne "
	"invisible de 384 px, bien séparées par du vide, même taille (environ 280 px), dans le style EXACT de "
	"la planche jointe MENU_OBJETS_PLANCHE (même rendu, même angle de trois quarts, même lumière) : "
	"1) la PIERRE LUNE : pierre sombre gris-bleu, bosselée, aux fines inclusions pâles et à de petits "
	"reflets froids, la même que celle de la vitrine du Musée sur la planche jointe INT_MUSEE_PLANCHE ; "
	"2) la CORDE SORTIE : un écheveau de corde de chanvre beige clair enroulée en boucles régulières, "
	"nouée en son milieu par un tour de la même corde, une extrémité qui pend avec un petit nœud ; "
	"3) le FOSSILE DÔME, fidèle à l'objet officiel de Pokémon Rouge/Bleu : une carapace fossile en forme "
	"de dôme arrondi brun-ocre, vue de dessus de trois quarts, une arête centrale et des stries régulières, "
	"un bord plat plus clair, aspect de pierre ancienne (le même que la vitrine du Musée jointe) ; "
	"4) le FOSSILE NAUTILE, fidèle à l'objet officiel de Pokémon Rouge/Bleu : une coquille fossile "
	"enroulée en SPIRALE gris-beige légèrement bleuté, nervures de la spirale bien marquées, aspect de "
	"pierre ancienne (le même que la vitrine du Musée jointe).",
	["MENU_OBJETS_PLANCHE_r1.png", "INT_MUSEE_PLANCHE_NE_r1.png"], 1)

## Conditionnels : (identifiant, références, description, ancres, valeurs, type).
CONDITIONNELS = [
	("WORLD_PROP_AFFLEUREMENTS_PLANCHE", ["REF_R3_AFFLEUREMENT", "REF_R3_PAROI_SUD"],
		"PLANCHE de 4 AFFLEUREMENTS rocheux de la Route 3 (les blocs de rochers infranchissables qui "
		"bordent les chemins et ferment les goulets), dans une image 1536 × 1024 : grille invisible de 2 "
		"colonnes × 2 lignes (cellules de 768 × 512), un élément par cellule, centré, la base de chacun sur une "
		"même ligne horizontale à 30 px du bas de sa cellule, à une échelle COMMUNE : 1 case = 170 px. "
		"1 et 2 (ligne 1) : amas de 3 ou 4 rochers beige-gris chauds (couleur des rochers joints), 3 cases × "
		"2, environ 1,4 case de haut, raccordables bout à bout. 3 et 4 (ligne 2) : les mêmes amas en roche "
		"plus froide, gris bleuté (vers l'ardoise de la montagne), 3 cases × 2. Quelques touffes d'herbe sèche "
		"au pied, rien de pointu.\nFond avec une vraie transparence (canal alpha), aucun sol, aucune ombre "
		"portée.",
		[ROCHER, "WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png"], LUMIERE_NE, "planche"),
	("WORLD_RELIEF_BOUCHE_SAS_01", ["REF_R3_ENTREE"],
		"la BOUCHE de sortie du Mont Sélénite sur le versant est (sas de la Route 4) : un module de paroi "
		"d'ardoise gris bleuté de 3 cases de large et 4 de haut, qui forme le BORD GAUCHE (ouest) d'une "
		"vallée vue de dessus en trois quarts ; l'ouverture de grotte, noire bleutée, d'une case de large et "
		"environ 1,5 case de haut, s'ouvre VERS LA DROITE (vers l'est) dans le bas du module, avec un seuil "
		"de terre claire qui sort vers la droite ; même roche que l'entrée jointe "
		"WORLD_RELIEF_ENTREE_GROTTE_01 (dont c'est la sœur, vue de côté). Aucun escalier, aucune porte, aucun "
		"étai, aucun panneau.",
		["WORLD_RELIEF_ENTREE_GROTTE_01_NE_r1.png", ARDOISE], LUMIERE_NE, "objet"),
	("UI_ITEM_CT", [],
		"une icône pour le Sac : une CT (Capsule Technique) générique de Pokémon, un disque de données "
		"plat gris argenté à reflets doux, vu de trois quarts, avec une étiquette ronde unie de couleur vive "
		"au centre, SANS aucun chiffre ni lettre (le numéro est affiché par l'interface) ; centrée, environ "
		"700 px de large dans une image carrée 1024 × 1024 ; style EXACT de la planche jointe "
		"MENU_OBJETS_PLANCHE.",
		["MENU_OBJETS_PLANCHE_r1.png"], "", "ui"),
]


# --- Prompts ----------------------------------------------------------------------------

def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées de "
		"la Route 3 et du Mont Sélénite (minuscules : n'en copie pas le rendu) ; ")


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
	corps = (f"ASSET : {description}\nFormat : PNG carré 1024 × 1024 ; l'élément occupe environ 900 px "
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


def _prompt_marche(identifiant: str, refs: list[str], tenue: str, ancres: list[str]) -> str:
	texte = ""
	if refs:
		texte += (f" ; {', '.join(refs)} = tenue et silhouette seulement (minuscules, extraites des vues "
			"d'ensemble, rendu à NE PAS copier)")
	if ancres:
		texte += f" ; {_noms(ancres)} = l'uniforme exact à reprendre (même main, mêmes couleurs)"
	return MODELE_MARCHE.format(ident=identifiant, ref=texte, tenue=tenue) + INTERDITS + "\n"


def _prompt_attente(identifiant: str, role: str, hauteur: int, tenue: str, pose: str | None) -> str:
	"""Modèle des attentes des séries 10–12 ; `pose` None = attente « creuse » ([constant CREUSE])."""
	nom = identifiant.removeprefix("PNJ_")
	marche = f"{identifiant}_NE_r1"
	if pose is None:
		posture = CREUSE
		bouge = "Ce n'est PAS une marche : le personnage reste sur place, absorbé par sa fouille.\n"
	else:
		bouge = "Ce n'est PAS une marche : le personnage ne bouge pas, il attend.\n"
		posture = ("POSE D'ATTENTE dans les 4 vues : " + pose + ", les jambes droites et serrées, les PIEDS "
			"JOINTS côte à côte (aucun pied devant l'autre, aucun pas, aucun talon levé), les deux semelles "
			"posées à plat au sol, le buste droit. De profil, les deux jambes se superposent presque : on voit "
			"une seule silhouette de jambes, les deux pieds l'un à côté de l'autre, pas un compas ouvert. De "
			"face et de dos, les deux pieds sont à la même hauteur, rapprochés sous les hanches.")
	return (f"{nom}_ATTENTE — POSE D'ATTENTE (personnage immobile, au repos) du même personnage "
		f"que la planche jointe {marche} (sa planche de marche 4 × 4) : {role}. Même main peinte, mêmes "
		"couleurs, mêmes proportions, même visage, même coiffure, mêmes vêtements et accessoires, même "
		f"taille de personnage. {bouge}"
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
	"""Toutes les images de la série : nom de l'image (sans .png), fichier de prompt, texte,
	images jointes (noms dans $ART), vague, conditionnel, groupe."""
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
	for ident, refs, hauteur, role, tenue, pose, ancres, vague in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres),
			[HEROS] + [f"{r}.png" for r in refs] + ancres, vague, groupe=ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1, groupe=ident)
	ident, description, ancres, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres), vague, groupe=ident)
	for ident, refs, description, ancres, valeurs, type_ in CONDITIONNELS:
		if type_ == "planche":
			nom = f"{ident}_NE_r1"
			texte = _prompt_planche(ident, refs, description, ancres, valeurs)
			jointes = [f"{r}.png" for r in refs] + ancres
		elif type_ == "objet":
			nom = f"{ident}_NE_r1"
			texte = _prompt_objet(ident, refs[0], 3, 4, description, ancres, valeurs)
			jointes = [f"{refs[0]}.png"] + STYLE + ancres
		else:
			nom = f"{ident}_r1"
			texte = _prompt_ui(ident, description, "PNG carré 1024 × 1024, fond TRANSPARENT (canal alpha)")
			jointes = list(ancres)
		ajouter(nom, PROMPTS / f"{nom}.txt", texte, jointes, 3, True, groupe=ident)
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

def _recadrage(nom: str) -> Image.Image:
	vue, boite = REFS[nom]
	return Image.open(VUES[vue]).convert("RGB").crop(boite)


def references() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for nom in REFS:
		ref = _recadrage(nom)
		ref = ref.resize((ref.width * AGRANDIR, ref.height * AGRANDIR), Image.LANCZOS)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_R3_*, REF_MS_*, REF_AR_PAROI dans {ART}")


VAGUES = (1, 2, 3)


def commandes() -> str:
	"""Commandes generer.sh équivalentes à la génération (pour une image seule ou un _r2)."""
	lignes = ["ART=/Users/kevinyankam/dev/kanto-2026/build/art"]
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


# --- Manifeste (T6) ---------------------------------------------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"


def _sol(ident: str, source: str, contraste: float, couleur: float) -> dict:
	return {"id": ident, "source": source, "sortie": f"{_W}ground/{ident}.png", "taille": 384,
		"contraste": contraste, "couleur": couleur}


## Entrées du manifeste (T6 seulement, en fin de chaque section). Réglages = défauts (règle 4),
## ajustés au T6 sur la planche de contrôle.
MANIFESTE = {
	"objets": [
		{"id": "relief_entree_grotte_01", "source": "WORLD_RELIEF_ENTREE_GROTTE_01_NE_r1.png",
			"sortie": f"{_W}relief/relief_entree_grotte_01.png", "axe": "w", "cases": 4,
			"ombre": False, "contact": 0.0},
		{"id": "prop_mare_grotte_01", "source": "WORLD_PROP_MARE_GROTTE_01_NE_r1.png",
			"sortie": f"{_W}props/prop_mare_grotte_01.png", "axe": "w", "cases": 4,
			"ombre": False, "contact": None},
		{"id": "decal_puits_jour_01", "source": "WORLD_DECAL_PUITS_JOUR_01_NE_r1.png",
			"sortie": f"{_W}ground/decals/decal_puits_jour_01.png", "axe": "w", "cases": 4,
			"ombre": False, "contact": None},
	],
	"sols": [
		_sol("ground_roche_01", "WORLD_GROUND_ROCHE_01_NE_r1.png", 0.7, 1.0),
		_sol("ground_grotte_01", "WORLD_GROUND_GROTTE_01_NE_r1.png", 0.6, 1.0),
		_sol("ground_gravats_01", "WORLD_GROUND_GRAVATS_01_NE_r1.png", 0.8, 1.0),
		_sol("ground_masse_roche_01", "WORLD_GROUND_MASSE_ROCHE_01_NE_r1.png", 0.6, 0.9),
	],
	# Planche 2 × 2 coupée comme la paroi de la série 12 (coupe la plus vide), hauteur 3 cases.
	"planches_arbres": [
		{"source": "WORLD_RELIEF_PAROI_ARDOISE_PLANCHE_NE_r1.png", "dossier": f"{_W}relief/",
			"ids": ["relief_paroi_ardoise_01", "relief_paroi_ardoise_02", "relief_paroi_ardoise_03",
				"relief_paroi_ardoise_04"],
			"hauteurs_px": [288, 288, 288, 288], "contact": 0.0},
	],
	# Découpe par taches (série 12), largeur en cases de chaque élément, ordre de lecture.
	"planches_objets": [
		{"source": "WORLD_RELIEF_PAROI_GROTTE_PLANCHE_NE_r1.png", "dossier": f"{_W}relief/",
			"colonnes": 3, "lignes": 2,
			"ids": ["relief_paroi_grotte_01", "relief_paroi_grotte_02", "relief_paroi_grotte_03",
				"relief_paroi_grotte_04", "relief_paroi_grotte_05", "relief_paroi_grotte_06"],
			"cases": [3, 3, 2, 2, 1, 3], "contact": 0.0},
		{"source": "WORLD_PROP_GROTTE_PLANCHE_NE_r1.png", "dossier": f"{_W}props/",
			"colonnes": 3, "lignes": 2,
			"ids": ["prop_colonne_grotte_01", "prop_colonne_grotte_02", "prop_rocher_grotte_01",
				"prop_rocher_grotte_02", "prop_eclats_lune_01", "prop_eclats_lune_02"],
			"cases": [2, 1, 1, 1, 1, 1], "contact": 0.15},
		{"source": "WORLD_PROP_ROCKET_PLANCHE_NE_r1.png", "dossier": f"{_W}props/",
			"colonnes": 3, "lignes": 2,
			"ids": ["prop_lampe_chantier_01", "prop_caisse_r_01", "prop_caisse_r_02",
				"prop_tranchee_01", "prop_projecteur_01", "prop_outils_fouille_01"],
			"cases": [1, 1, 2, 3, 1, 1], "contact": 0.15},
		{"source": "WORLD_PROP_ECHELLES_PLANCHE_NE_r1.png", "dossier": f"{_W}props/",
			"colonnes": 2, "lignes": 1,
			"ids": ["prop_echelle_descend_01", "prop_echelle_monte_01"],
			"cases": [1, 1], "contact": 0.0},
		{"source": "WORLD_PROP_DALLE_FOSSILES_PLANCHE_NE_r1.png", "dossier": f"{_W}props/",
			"colonnes": 3, "lignes": 1,
			"ids": ["prop_dalle_01", "prop_fossile_dome_01", "prop_fossile_nautile_01"],
			"cases": [3, 0.6, 0.6], "contact": 0.1},
		{"source": "WORLD_PROP_INDICES_PLANCHE_NE_r1.png", "dossier": f"{_W}props/",
			"colonnes": 2, "lignes": 1,
			"ids": ["prop_indice_caillou_01", "prop_indice_eclat_01"],
			"cases": [0.7, 0.6], "contact": 0.2},
	],
	"personnages": [
		{"id": "fillette", "source": "PNJ_FILLETTE_NE_r1.png", "sortie": f"{_C}fillette_sheet.png",
			"hauteur": 108},
		{"id": "sbire_h", "source": "PNJ_SBIRE_ROCKET_H_NE_r1.png", "sortie": f"{_C}sbire_h_sheet.png",
			"hauteur": 128},
		{"id": "sbire_f", "source": "PNJ_SBIRE_ROCKET_F_NE_r1.png", "sortie": f"{_C}sbire_f_sheet.png",
			"hauteur": 124},
		{"id": "chercheur_fossiles", "source": "PNJ_CHERCHEUR_FOSSILES_NE_r1.png",
			"sortie": f"{_C}chercheur_fossiles_sheet.png", "hauteur": 128},
	],
	"attentes": [
		{"id": f"{nom}_idle", "source": f"{court}_ATTENTE_r1.png",
			"sortie": f"{_C}{nom}_idle_sheet.png", "marche": nom}
		for nom, court in (("fillette", "FILLETTE"), ("sbire_h", "SBIRE_ROCKET_H"),
			("sbire_f", "SBIRE_ROCKET_F"), ("chercheur_fossiles", "CHERCHEUR_FOSSILES"))
	],
}

## Icônes du Sac (T6, `preparer_menu.py` : seconde planche, même découpe que MENU_OBJETS_PLANCHE)
## → `assets/ui/items/<id>.webp`, dans l'ordre de la planche.
ICONES_IDS = ["moon_stone", "escape_rope", "dome_fossil", "helix_fossil"]

## Planches de personnages préparées : (planche, identifiant de données, hauteur de fiche).
PERSONNAGES_JEU = [("fillette", "lass_young", 108), ("sbire_h", "rocket_grunt_m", 128),
	("sbire_f", "rocket_grunt_f", 124), ("chercheur_fossiles", "fossil_researcher", 128)]


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 12) ; une section absente est créée en fin de fichier."""
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
	print(f"manifeste : {ajouts} entrée(s) de la série 14 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------

## Échelle des vues en pixels par case (pour poser une référence à sa taille en jeu).
PX_CASE = {"R3": 1536 / 82, "MS": 1024 / 60, "AR": 1024 / 56}


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
	p = _Planche(2600, "Route 3 et Mont Sélénite — kit de la série 14 (T1, jalon 12) : 1 case = 48 px "
		"sur cette planche ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu)", [
		heros,
		(_asset(f"{w}buildings/bldg_centre_01.png"), "bldg_centre_01 8 × 7\nCentre du Mont Sélénite"),
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 4, 6, 8)],
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\nH1–H4"),
		(_asset(f"{w}relief/relief_rebord_01.png"), "relief_rebord_01\nrebords L1, L2"),
		*[(_asset(f"{w}relief/relief_paroi_0{n}.png"), f"relief_paroi_0{n}\nmontagne, ouest")
			for n in (1, 2, 4)],
		(_asset(f"{w}relief/relief_falaise_01.png"), "relief_falaise_01\nrebord du sas ~"),
		(_asset(f"{w}props/prop_rocher_01.png"), "prop_rocher_01\naffleurements R"),
		(_asset(f"{w}props/prop_grande_pierre_01.png"), "grande pierre\nR (0,6–1)"),
		(_asset(f"{w}props/prop_pierres_01.png"), "prop_pierres_01"),
		(_asset(f"{w}props/prop_buisson_a_01_bourg.png"), "buisson x, b"),
		(_asset(f"{w}props/prop_buisson_b_01_bourg.png"), "buisson x, b"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneau ×4"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball au sol\n(tous objets)"),
		*_si(f"{c}jeune_dresseur_sheet.png", "Gamin ×2\n(youngster)", _cellule_perso),
		*_si(f"{c}scout_sheet.png", "Scout ×2 (scout)", _cellule_perso),
		*_si(f"{c}voyageur_sheet.png", "voyageur\n(traveler)", _cellule_perso),
		*_si(f"{c}randonneuse_sheet.png", "randonneuse\n(hiker)", _cellule_perso),
		*_si(f"{c}montagnard_sheet.png", "randonneur 1F\n(mountaineer)", _cellule_perso),
		*_si(f"{c}infirmiere_sheet.png", "infirmière", _cellule_perso),
		*_si("assets/sprites/pokemon/painted/piafabec_sheet.png", "Piafabec ×2\n(spearow)"),
	], (40, 90, 50))

	rocher = _asset(f"{w}props/prop_rocher_01.png")
	foret = _asset(f"{w}props/tree_foret_03.png")
	buisson = _asset(f"{w}props/prop_buisson_a_01_bourg.png")
	paroi = _asset(f"{w}relief/relief_paroi_01.png")
	p.section("2. VARIATIONS SANS NOUVEL ASSET (échelle, miroir, teinte)", [
		(_teinter(foret, (0.95, 0.95, 0.93)), "forêt plus sèche\nvaleur × 0,95"),
		(_teinter(foret, (0.92, 0.9, 0.86)), "forêt est\nvaleur × 0,9"),
		(_teinter(rocher, (0.9, 0.93, 1.0)), "rocher teinté\ngris bleuté (est)"),
		(_miroir(_echelle(_asset(f"{w}props/prop_grande_pierre_01.png"), 0.6)), "grande pierre\n× 0,6 miroir"),
		(_teinter(_miroir(buisson), (1.08, 1.08, 1.08)), "buisson miroir\n+ 8 %"),
		(_teinter(buisson, (0.92, 0.92, 0.92)), "buisson − 8 %"),
		(_teinter(paroi, (0.86, 0.9, 1.0)), "paroi série 12\nouest seulement (x < 40)"),
		*[(_echelle(_asset(f"{w}ground/decals/decal_fleur_{i}.png"), 1.6), f"fleur_{i}\n(rares à l'est)")
			for i in (2, 4)],
		(_ref("REF_MS_ENTREE_1F", 1.5), "entrée E du 1F : sol de grotte\n+ halo du jour (aucun asset)"),
	], (60, 80, 110))

	p.section("3. NOUVEAUX : ROUTE 3 ET SAS (Codex, lumière NE) — référence de la vue à la taille en jeu", [
		heros,
		(_ref("REF_R3_SOL_ROCHE", hauteur=3 * k), "WORLD_GROUND_ROCHE_01\ntexture (o, parvis, sas)"),
		(_ref("REF_R3_PAROI_EST", 3), "PAROI_ARDOISE_PLANCHE\n4 modules 4 × 3 (forme ; ardoise)"),
		(_ref("REF_R3_PAROI_SUD", 3), "paroi : masse sud-est\n(dessus de massif)"),
		(_ref("REF_R3_ENTREE", 3), "RELIEF_ENTREE_GROTTE_01\n4 × 3, ouverture 2 (Q ; miroir D)"),
		(_ref("REF_R3_FILLETTE", hauteur=54), "PNJ_FILLETTE\n108 px, ×2 (Léa, Inès)"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : MONT SÉLÉNITE (valeurs de grotte pour sols et parois)", [
		heros,
		(_ref("REF_MS_SOL", hauteur=2 * k), "GROUND_GROTTE_01\nsol calme ."),
		(_ref("REF_MS_GRAVATS", hauteur=3 * k), "GROUND_GRAVATS_01\ngravats g"),
		(_ref("REF_MS_MASSE", hauteur=3 * k), "GROUND_MASSE_ROCHE_01\ndessus des masses #"),
		(_ref("REF_MS_PAROI", 2.5), "PAROI_GROTTE_PLANCHE\n6 modules (faces, angles, bords)"),
		(_ref("REF_MS_COLONNE", 2.4), "PROP_GROTTE_PLANCHE\ncolonne 2 × 3 (K 1F)"),
		(_ref("REF_MS_COLONNES", 3), "colonnes fines 1 × 1\n(B2F)"),
		(_ref("REF_MS_ROCHER", 0.8), "rochers o ×2"),
		(_ref("REF_MS_ECLATS", 1), "éclats * ×2"),
		(_ref("REF_MS_MARE", 3), "PROP_MARE_GROTTE_01\n4 × 3 (w)"),
		(_ref("REF_MS_PUITS", 3), "DECAL_PUITS_JOUR_01\n4 × 3 (j ; 2 × 2 à l'échelle)"),
		(_ref("REF_MS_ECHELLE_V", 1.4), "ECHELLES_PLANCHE\nV descend"),
		(_ref("REF_MS_ECHELLE_U", 2), "U monte"),
		(_ref("REF_MS_CAISSES", 2), "ROCKET_PLANCHE\ncaisses R ×2"),
		(_ref("REF_MS_LAMPE", 1), "lampe L"),
		(_ref("REF_MS_FOUILLE", 2), "outils, tranchée F"),
		(_ref("REF_MS_PROJECTEUR", 1.5), "projecteur (B2F)"),
		(_ref("REF_MS_DALLE", 1), "DALLE_FOSSILES_PLANCHE\ndalle S 3 × 1 + 2 fossiles"),
		(_ref("REF_MS_GUETTEUR", hauteur=64), "PNJ_SBIRE_ROCKET_H\n128 px (R1, R3)"),
		(_ref("REF_MS_FOUILLEUSE", hauteur=56), "PNJ_SBIRE_ROCKET_F\n124 px, attente creuse"),
		(_ref("REF_MS_CHERCHEUR", hauteur=64), "PNJ_CHERCHEUR_FOSSILES\n128 px (Gaspard)"),
		(_ref("REF_MS_SECTEUR", hauteur=200), "INDICES_PLANCHE\ncaillou (R3), éclat (x)"),
	], (130, 70, 40))
	icones = [(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
		f"{i}.webp\n(existante, style)") for i in ("poke_ball", "potion")
		if (RACINE / f"assets/ui/items/{i}.webp").exists()]
	p.section("3 ter. ICÔNES DU SAC : UI_OBJETS_J12_PLANCHE (4 icônes, chaîne de preparer_menu.py) — "
		"style des icônes existantes, formes des vitrines du Musée", [
		*icones,
		*_si(f"{w}interiors/int_vitrine_pierre_lune_01.png", "Pierre Lune\n(vitrine du Musée)"),
		*_si(f"{w}interiors/int_vitrine_dome_01.png", "Fossile Dôme\n(vitrine du Musée)"),
		*_si(f"{w}interiors/int_vitrine_nautile_01.png", "Fossile Nautile\n(vitrine du Musée)"),
		(_ref("REF_MS_FOUILLE", hauteur=90), "Corde Sortie\n(aucune forme existante)"),
	], (90, 60, 120))
	p.section("3 quater. CONDITIONNELS (prompts prêts ; captures des T8 / T9, ou clôture du J11)", [
		(_ref("REF_R3_AFFLEUREMENT", 2), "AFFLEUREMENTS_PLANCHE\nsi les rochers ne tiennent pas R"),
		(_miroir(_ref("REF_R3_ENTREE", 3)), "RELIEF_BOUCHE_SAS_01\nsi le miroir ne se lit pas"),
		*_si("assets/ui/items/potion.webp", "UI_ITEM_CT (style des icônes)\nsi le J11 n'en livre pas",
			lambda r: _echelle(Image.open(RACINE / r).convert("RGBA"), 0.4)),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_R3_PAROI_EST", hauteur=110), "montagne beige à l'est\n(→ ardoise)"),
		(_ref("REF_R3_FILLETTE", hauteur=80), "Fillette sur le plateau\n(elle est à la jonction)"),
		(_ref("REF_MS_RANDONNEUR", hauteur=80), "randonneur galerie est\n(il est au hall)"),
		(_ref("REF_MS_NOSFERAPTI", hauteur=80), "Pokémon d'ambiance\nde la grotte (×4)"),
		(_ref("REF_MS_MELOFEE", hauteur=80), "Mélofée"),
		(_ref("REF_MS_RACAILLOU", hauteur=80), "Racaillou"),
		(_ref("REF_MS_PARAS", hauteur=80), "Paras"),
		(_ref("REF_MS_DALLE", hauteur=80), "fossiles peints de la vue\n(→ objets officiels)"),
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


def _present(relatif: str, etiquette: str, fonction=_jeu) -> list:
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def controle(sortie: Path) -> Path:
	"""Planche de contrôle du T6 : les assets **préparés** (assets/), à l'échelle du jeu (1:1,
	1 case = 96 px ; textures en carré de 2 × 2 cases), le héros à côté de chaque groupe. Un asset
	absent est sauté (la planche se relance à chaque étape)."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(4300, "Série 14 préparée (T6, jalon 12) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	sols = []
	for e in MANIFESTE["sols"]:
		if (RACINE / e["sortie"]).exists():
			tuile = Image.open(RACINE / e["sortie"]).convert("RGBA")
			carre = Image.new("RGBA", (192, 192))
			for x in range(0, 192, tuile.width):
				for y in range(0, 192, tuile.height):
					carre.alpha_composite(tuile, (x, y))
			sols.append((carre, f"{e['id']}\n2 × 2 cases"))
	p.section("1. SOLS (répétés sur 2 × 2 cases)", [heros, *sols], (40, 90, 50))
	relief = [e for e in MANIFESTE["planches_arbres"][0]["ids"]] + \
		MANIFESTE["planches_objets"][0]["ids"]
	p.section("2. PAROIS ET ENTRÉE", [
		heros,
		*[x for ident in relief for x in _present(f"{_W}relief/{ident}.png", ident)],
		*_present(f"{_W}relief/relief_entree_grotte_01.png", "relief_entree_grotte_01\n4 × 3"),
	], (60, 80, 110))
	props = [i for planche_ in MANIFESTE["planches_objets"][1:] for i in planche_["ids"]]
	p.section("3. OBJETS DE LA GROTTE, CAMP ROCKET, FOSSILES, INDICES", [
		heros,
		*[x for ident in props for x in _present(f"{_W}props/{ident}.png", ident)],
		*_present(f"{_W}props/prop_mare_grotte_01.png", "prop_mare_grotte_01\n4 × 3"),
		*_present(f"{_W}ground/decals/decal_puits_jour_01.png", "decal_puits_jour_01\n4 × 3"),
	], (130, 70, 40))
	p.section("4. PERSONNAGES : marche (face, gauche, droite, dos) puis attente", [
		heros,
		*[x for nom, ident, h in PERSONNAGES_JEU for x in _present(f"{_C}{nom}_sheet.png",
			f"{nom} ({ident}) {h} px\nmarche",
			lambda r: _cellules(r, 4, 4, [(0, 0), (1, 1), (1, 2), (0, 3)]))],
		*[x for nom, _, _ in PERSONNAGES_JEU for x in _present(f"{_C}{nom}_idle_sheet.png",
			f"{nom}_idle\nattente", lambda r: _cellules(r, 4, 1, [(n, 0) for n in range(4)]))],
	], (110, 90, 40))
	p.section("5. ICÔNES DU SAC (256 px)", [
		*[x for ident in ICONES_IDS for x in _present(f"assets/ui/items/{ident}.webp", ident)],
	], (120, 40, 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


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
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "MS_KIT_v1.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon12_assets" / "serie14_controle.png"))
	else:
		generer(set(arguments))
