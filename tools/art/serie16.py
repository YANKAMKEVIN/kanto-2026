#!/usr/bin/env python3
"""Série 16 — Route 25, Cap d'Azuria et maison de Léo (jalon 14, lumière neutre). Liste :
docs/tech/jalon-14.md §1.4 ; fiches : docs/design/fiches-assets/serie-16-cap-azuria.md.

Méthode des J8–J13 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées, `docs/design/reference/route-25-vue-generale-v1.png` et `maison-leo-v1.png` ; **la grille
fait foi** : `tools/plans/route_25.txt`, `bill_house.txt`). Presque tout est repris (sols, mer,
sable, falaise et piliers de la série 12, forêt, hautes herbes, buissons, massifs, Dresseurs,
mobilier d'intérieur, planche de Mélofée du J12, ruban, barrière et fermetures du J13) ; ne sont
générées que **7 images** :
  - côte : planche du RIVAGE ROCHEUX (6 modules alignés sur les rôles de la grille, + l'indice
    coquillage de l'objet caché O4 et la clôture réparée d'Azuria) ;
  - maison du Cap (façade 8 × 6, toit d'ardoise bleue, parabole, cheminée) ;
  - intérieur : coque de la maison de Léo (16 × 11) et planche de 6 meubles (cabine de
    téléportation, console au grand bouton rouge, écran de diagnostic, module, bureau encombré,
    bibliothèque vue de côté) ;
  - Léo humain × (marche + attente) ;
  - planche d'icônes du Sac : Passe Bateau, Super Bonbon.
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_PROP_BARRIERE_POLICE_01 (si la barrière à
croisillon du J13 ne se lit pas comme un barrage de police sur la capture de 14C) ;
COMBAT_DECOR_ROUTE25_COTE_r1 (le dossier ne demande aucun décor de combat : repli flou existant ;
prompt écrit dans tools/art/combat_decors/prompts/, chaîne des décors de combat).

Lumière : NE (neutre) pour tout ; la mer et l'écume restent celles du jeu (shader), jamais peintes
sur les modules de rivage (une fine ligne d'eau mouillée seulement).

**Les prompts sont versionnés** : `tools/art/prompts/serie16/<NOM>.txt` (un par image) et
`tools/art/attente/prompts/<NOM>_ATTENTE.txt`, écrits par `--prompts` à partir des tables ci-dessous.
Corriger une image = corriger la table, relancer `--prompts`, relire le diff ; une correction après
génération se lance en `_r2` (table CORRECTIONS, comme la série 15). Sources et sorties dans $ART
(défaut : build/art de cette copie ; `--ancres` y copie les ancres validées depuis le checkout
principal, puis depuis les copies du J13 pour les images de la série 15).

Usage :
  tools/art/serie16.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie16.py --refs                  recadre les REF_R25_*, REF_LEO_* dans $ART (sans Codex)
  tools/art/serie16.py --ancres                copie les ancres de style absentes dans $ART
  tools/art/serie16.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie16.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/R25_KIT_v1.png)
  tools/art/serie16.py --contact [sortie.png]  planche de contact des images générées (T2)
  tools/art/serie16.py --manifeste             ajoute les entrées en fin de manifeste.json (T13 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie16.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T13)
  tools/art/serie16.py [IDENTIFIANT ...]       génère avec Codex, en deux vagues (sans argument :
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
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _miroir, _Planche)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
## Ancres validées : checkout principal (séries 01–14), puis copies du J13 (série 15).
SOURCES_ANCRES = [Path("/Users/kevinyankam/dev/kanto-2026/build/art"),
	Path("/Users/kevinyankam/dev/kanto-2026/.claude/worktrees/j13-t5/build/art"),
	Path("/Users/kevinyankam/dev/kanto-2026/.claude/worktrees/j13-t1/build/art")]
REFERENCE = RACINE / "docs/design/reference"
VUES = {
	"R25": REFERENCE / "route-25-vue-generale-v1.png",  # 1536 × 1024, ≈ 19,2 px par case (80 cases)
	"LEO": REFERENCE / "maison-leo-v1.png",  # 1536 × 1024, ≈ 96 px par case (16 cases)
}
PX_CASE = {"R25": 1536 / 80, "LEO": 1536 / 16}
PROMPTS = ICI / "prompts" / "serie16"
ATTENTES = ICI / "attente" / "prompts"
DECORS_COMBAT = ICI / "combat_decors" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue). Agrandis × 3 au plus, sans
## dépasser 1 536 px (les recadrages de l'intérieur sont déjà grands).
REFS = {
	# Route 25 et Cap
	"REF_R25_MAISON": ("R25", (1290, 322, 1462, 478)),
	"REF_R25_RIVAGE": ("R25", (300, 538, 870, 672)),
	"REF_R25_RIVAGE_CAP": ("R25", (1030, 640, 1525, 700)),
	"REF_R25_RIVAGE_COTE": ("R25", (1478, 300, 1528, 690)),
	"REF_R25_RIVAGE_ANGLE": ("R25", (1020, 540, 1100, 620)),
	"REF_R25_CRIQUE": ("R25", (630, 545, 850, 668)),
	"REF_R25_ROCHER_INDICE": ("R25", (1225, 620, 1290, 680)),
	"REF_R25_FALAISE": ("R25", (420, 0, 1536, 280)),
	"REF_R25_PILIER": ("R25", (308, 312, 402, 446)),
	"REF_R25_MASSIFS": ("R25", (1280, 440, 1470, 495)),
	"REF_R25_REBORD": ("R25", (515, 440, 680, 472)),
	"REF_R25_MER": ("R25", (0, 690, 760, 1024)),
	# Écarts de la vue volontairement non reproduits (personnages placés par le peintre).
	"REF_R25_SCOUT": ("R25", (1092, 440, 1152, 512)),
	"REF_R25_PECHEUR": ("R25", (1446, 530, 1486, 598)),
	# Maison de Léo
	"REF_LEO_PIECE": ("LEO", (0, 0, 1536, 1024)),
	"REF_LEO_CABINE": ("LEO", (200, 0, 395, 368)),
	"REF_LEO_ECRAN": ("LEO", (388, 68, 568, 196)),
	"REF_LEO_CONSOLE": ("LEO", (640, 190, 900, 345)),
	"REF_LEO_MODULE": ("LEO", (950, 185, 1160, 355)),
	"REF_LEO_BUREAU": ("LEO", (165, 420, 590, 745)),
	"REF_LEO_BIBLIO": ("LEO", (20, 130, 180, 610)),
	"REF_LEO_FENETRE": ("LEO", (560, 30, 1070, 205)),
	"REF_LEO_LIT": ("LEO", (1075, 435, 1505, 835)),
	"REF_LEO_MARCHE": ("LEO", (560, 800, 965, 1024)),
}
AGRANDIR = 3
REF_MAX = 1536

## Ancres de style (images validées des séries précédentes, dans $ART ; `--ancres` les copie).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"
ROCHER_MER = "WORLD_PROP_ROCHER_MER_01_NE_r1.png"
PAROI = "WORLD_RELIEF_PAROI_PLANCHE_NE_r1.png"  # série 12 (falaise et piliers beiges)
QUAIS = "WORLD_RELIEF_QUAI_PLANCHE_NE_r1.png"  # série 15 (gabarit des modules de bord)
BERGES = "WORLD_RELIEF_BERGE_PLANCHE_NE_r1.png"  # série 15
CAMBRIOLAGE = "WORLD_PROP_CAMBRIOLAGE_PLANCHE_NE_r1.png"  # série 15 (clôture d'Azuria)
FERMETURES = "WORLD_PROP_FERMETURES_PLANCHE_NE_r1.png"  # série 15 (barrière à croisillon)
MAISON_ARGENTA = "WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png"
MAISON_A = "WORLD_BLDG_MAISON_A_01_NE_r1.png"
COQUE_MAISON = "INT_MAISON_ARGENTA_COQUE_NE_r1.png"
COQUE_LABO = "INT_LABO_COQUE_NE_r1.png"
MACHINES = "INT_MACHINES_LABO_01_NE_r1.png"
BUREAU_CHEN = "INT_BUREAU_CHEN_01_NE_r1.png"
ETAGERE = "INT_GRANDE_ETAGERE_01_NE_r1.png"
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
CHEN = "PNJ_CHEN_NE_r1.png"
# Image de la série 16 jointe à la vague 2.
MAISON_LEO = "WORLD_BLDG_MAISON_LEO_01_NE_r1.png"
ANCRES = [STYLE[0], STYLE[1], HEROS, ROCHER_MER, PAROI, QUAIS, BERGES, CAMBRIOLAGE, FERMETURES,
	MAISON_ARGENTA, MAISON_A, COQUE_MAISON, COQUE_LABO, MACHINES, BUREAU_CHEN, ETAGERE,
	MENU_OBJETS, CHEN]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, AUCUN emblème rond de type balle "
	"(ni cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou faune "
	"non-Pokémon (oiseaux, poissons réels, crabes, mouettes, insectes), Pikachu et tout Pokémon non "
	"demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune), "
	"élément effrayant.")

# --- Tables ------------------------------------------------------------------------------

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_BLDG_MAISON_LEO_01", "REF_R25_MAISON", 8, 6,
		"la MAISON DE LÉO, au bout du Cap d'Azuria, petite maison isolée d'un inventeur passionné au bord "
		"de la mer, façade de face (base de 8 cases de large, environ 6 cases de haut avec le toit), même "
		"gabarit et même main que la maison jointe WORLD_BLDG_MAISON_ARGENTA_01 : murs de PIERRE claire "
		"crème-beige appareillée, soubassement de pierre plus foncée ; grand toit à deux pans d'ARDOISES "
		"BLEU-GRIS foncé (bleu ardoise franc, la couleur qui distingue la maison) aux rangs réguliers ; "
		"une CHEMINÉE carrée de pierre claire à droite du faîtage ; une petite ANTENNE PARABOLIQUE "
		"blanche fixée sur le toit, à gauche de la cheminée (le seul signe que c'est la maison d'un "
		"inventeur) ; au milieu exact du bas de la façade (4e et 5e colonnes sur 8), une PORTE DOUBLE "
		"de bois brun chaud de 2 cases de large sous un linteau de pierre, une marche de pierre ; une "
		"fenêtre à petits carreaux de chaque côté, encadrement de bois brun, vitres bleutées, celle de "
		"droite un peu plus lumineuse (reflet bleu pâle d'écran à l'intérieur, discret). Accueillante, "
		"un peu excentrique, jamais délabrée. Sans massifs de fleurs, sans clôture, sans panneau, sans "
		"boîte aux lettres, sans plantes au sol (posés par la carte), aucune inscription.",
		[MAISON_ARGENTA, MAISON_A], LUMIERE_NE, 1),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("WORLD_RELIEF_RIVAGE_PLANCHE", ["REF_R25_RIVAGE", "REF_R25_RIVAGE_CAP", "REF_R25_RIVAGE_ANGLE"],
		"PLANCHE de 8 cellules : 6 MODULES DE RIVAGE ROCHEUX (le bord de pierres entre la terre et la mer "
		"de la Route 25) et 2 petits éléments, dans une image 1536 × 1024 : grille invisible de 4 colonnes "
		"× 2 lignes (cellules de 384 × 512), un élément par cellule, centré, à une échelle COMMUNE de "
		"1 case = 180 px, TOUS vus de dessus en trois quarts. Matière : une rangée serrée de GROS BLOCS DE "
		"ROCHE arrondis et trapus, beige-gris chaud (la même roche beige que la planche de paroi jointe "
		"WORLD_RELIEF_PAROI_PLANCHE et que le rocher de mer joint), facettes douces, arêtes claires, "
		"quelques touffes d'herbe et de mousse vert frais dans les joints du haut ; chaque bloc fait "
		"environ une demi-case à trois quarts de case ; ANGLES DROITS : chaque module est un rectangle "
		"net, ses bords se raccordent bout à bout avec son semblable, aucun bord arrondi en arc. Chaque "
		"module est posé SUR UNE CASE DE ROCHER : le côté terre (en haut ou à gauche) se fond dans la "
		"transparence, le côté mer porte une FINE LIGNE D'EAU MOUILLÉE sombre bleu-gris au pied des blocs, "
		"RIEN de plus (aucune écume, aucune vague, aucune eau dessinée : le jeu les ajoute). Même finesse "
		"et même découpe que la planche de quais jointe (gabarit seulement : ici de la roche brute, pas de "
		"pierre taillée).\n"
		"Ligne 1. Module 1 (colonne 1) : RIVAGE DROIT A, la mer est AU SUD : la rangée de blocs vue de "
		"dessus, leur face avant visible qui plonge vers l'eau en bas, la ligne d'eau mouillée tout en bas "
		"; 2 cases de long × 1,15 de haut (≈ 360 × 207 px), rectangle horizontal complet bord à bord. "
		"Module 2 (colonne 2) : RIVAGE DROIT B, même gabarit (360 × 207), blocs de tailles et de teintes "
		"différentes, un bloc plus gros et un petit galet. Module 3 (colonne 3) : RIVAGE DE CÔTÉ, la mer "
		"est À DROITE (à l'est) : une bande verticale de blocs vus de dessus, terre à gauche, ligne d'eau "
		"mouillée sur le bord droit ; 1 case de large × 2 de long (≈ 180 × 360 px). Module 4 (colonne 4) : "
		"ANGLE EXTÉRIEUR, la mer est au SUD et À DROITE : un bloc d'angle carré, face avant qui plonge en "
		"bas, ligne d'eau mouillée en bas et à droite ; 1 case de large × 1,15 de haut (≈ 180 × 207 px).\n"
		"Ligne 2. Module 5 (colonne 1) : ANGLE INTÉRIEUR, la mer ne touche que le coin en bas à droite : "
		"un amas de blocs carré dont seul le coin bas-droit porte une petite face et une courte ligne "
		"d'eau mouillée ; 1 × 1 case (≈ 180 × 180 px). Module 6 (colonne 2) : BLOC DE ROCHERS plein, un "
		"amas carré de blocs serrés vus de dessus, sans ligne d'eau (rocher loin de l'eau, extrémités), "
		"1 × 1 case (≈ 180 × 180 px). Module 7 (colonne 3) : INDICE COQUILLAGE, un seul petit COQUILLAGE "
		"nacré rose pâle et crème en éventail, posé à plat, discret mais lisible, environ 0,35 case "
		"(≈ 63 px), sans rocher autour. Module 8 (colonne 4) : CLÔTURE RÉPARÉE, un tronçon de clôture de "
		"bois clair d'une case de long (≈ 180 px) et 0,7 case de haut, même clôture que dans la planche "
		"jointe WORLD_PROP_CAMBRIOLAGE_PLANCHE, avec deux PLANCHES NEUVES plus claires clouées en travers "
		"(têtes de clous visibles), propre, sans ruban.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune eau dessinée, aucune ombre "
		"portée.",
		[PAROI, ROCHER_MER, QUAIS, CAMBRIOLAGE], LUMIERE_NE, 1),
	("INT_MAISON_LEO_PLANCHE", ["REF_LEO_CABINE", "REF_LEO_CONSOLE", "REF_LEO_MODULE", "REF_LEO_ECRAN",
			"REF_LEO_BUREAU", "REF_LEO_BIBLIO"],
		"PLANCHE de 6 MEUBLES pour la maison-laboratoire de Léo, un inventeur passionné qui travaille sur "
		"la téléportation (bois chaud, métal brossé clair, verre bleuté, câbles noirs ; bricolé avec "
		"amour, jamais inquiétant), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes "
		"(cellules de 512 × 512), un meuble par cellule, centré, la base de chacun sur une même ligne "
		"horizontale à 30 px du bas de sa cellule, à une échelle COMMUNE : 1 case = 150 px. Vue de dessus "
		"en trois quarts : on voit le dessus et la face avant de chaque meuble, jamais ses côtés.\n"
		"1 (ligne 1, à gauche) : CABINE DE TÉLÉPORTATION, un grand cylindre vertical de verre bleuté "
		"transparent (on voit l'intérieur vide) cerclé de métal brossé clair en bas et en haut, un "
		"chapeau métallique d'où partent deux tuyaux vers le haut, un anneau lumineux bleu pâle peint "
		"doucement au sol de la cabine (pas d'éclat, pas de halo autour), une porte vitrée fermée ; "
		"accolée à SA GAUCHE, une étroite ARMOIRE ÉLECTRIQUE métallique (voyants, câbles noirs qui "
		"rejoignent la cabine) ; ensemble 3 cases de large (≈ 450 px : armoire 1 case, cabine 2 cases), "
		"environ 2,6 cases de haut. 2 (ligne 1, au milieu) : CONSOLE DE COMMANDE, un pupitre de bois et de "
		"métal de 2 cases de large (≈ 300 px), 1 case de haut, plateau incliné couvert de manettes, de "
		"curseurs et de petits voyants, avec au centre un GRAND BOUTON ROUGE rond bien visible (le seul "
		"rouge vif de la planche, un bouton, pas un emblème) ; un petit tiroir à droite. 3 (ligne 1, à "
		"droite) : MODULE DE TÉLÉPORTATION, un boîtier métallique carré de 1 case de large (≈ 150 px), "
		"1,3 case de haut, deux cylindres sur le dessus, des voyants verts et ambre, une grille "
		"d'aération, des TUYAUX et des câbles noirs qui sortent des deux côtés et retombent au sol.\n"
		"4 (ligne 2, à gauche) : ÉCRAN DE DIAGNOSTIC, un grand écran mural sombre bleu nuit encadré de "
		"métal, aux courbes et cercles cyan simples (aucun chiffre, aucune lettre : seulement des traits, "
		"des cercles et des barres), monté sur un petit meuble bas à deux tiroirs ; 1 case de large "
		"(≈ 150 px) pour le meuble, l'écran un peu plus large (≈ 1,3 case), environ 2,2 cases de haut au "
		"total. 5 (ligne 2, au milieu) : BUREAU ENCOMBRÉ, un bureau de bois de 3 cases de large "
		"(≈ 450 px), 1 case de haut, couvert de PLANS techniques étalés (feuilles crème aux schémas de "
		"cercles et de lignes bleues, sans texte), une lampe d'architecte noire, un pot à crayons, une "
		"tasse, une petite pile de livres, deux caissons à tiroirs ; sans chaise. 6 (ligne 2, à droite) : "
		"BIBLIOTHÈQUE VUE DE CÔTÉ, une haute bibliothèque de bois adossée au mur de GAUCHE d'une pièce, "
		"vue de dessus en trois quarts : on voit son dessus étroit et la tranche de ses étagères tournée "
		"vers la DROITE, pleines de livres colorés, deux plantes en pot sur le dessus ; 1 case de large "
		"(≈ 150 px) × 2 cases de profondeur, environ 2,4 cases de haut.\n"
		"Même rendu que les meubles joints INT_MACHINES_LABO_01, INT_BUREAU_CHEN_01 et "
		"INT_GRANDE_ETAGERE_01 (même main, même angle) ; fond avec une vraie transparence (canal alpha), "
		"aucun sol, aucun tapis, aucune ombre portée, aucune lueur peinte autour des objets.",
		[MACHINES, BUREAU_CHEN, ETAGERE], LUMIERE_NE, 1),
]

## Coques : (identifiant, largeur, profondeur, ancres, géométrie, matériaux, vague).
_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus.")
COQUES = [
	("INT_MAISON_LEO_COQUE", 16, 11, [COQUE_MAISON, COQUE_LABO, MAISON_LEO, "REF_LEO_PIECE.png"],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 16 cases de large × 11 de profondeur "
		"(la préparation l'étire à 1 536 × 1 056 : 1 case = 96 px de large, ≈ 93 px de haut). "
		+ _BASE_COQUE + " Face avant du mur du fond sur les 3 cases du haut (≈ 280 px) ; épaisseur des "
		"murs latéraux ≈ 48 px ; épaisseur du mur du bas ≈ 60 px, interrompue au milieu par l'ENTRÉE : "
		"une ouverture de 2 cases (≈ 192 px, de x 672 à x 864) exactement centrée, avec un paillasson "
		"brun uni. Au milieu du mur du fond, une GRANDE FENÊTRE à petits bois de 5 cases de large "
		"(de x 576 à x 1056) qui donne sur la MER calme turquoise, un îlot lointain et un phare blanc "
		"(vue de jour, lumière neutre, aucun coucher de soleil) ; de chaque côté de la fenêtre, le mur "
		"porte seulement deux petits cadres de paysages marins et des tuyaux de cuivre fins qui courent "
		"le long du haut du mur. Tout le sol est un PARQUET de lattes claires, LIBRE et VIDE (aucun "
		"meuble, aucune machine : ils sont ajoutés séparément).",
		"la maison-laboratoire de Léo, au Cap d'Azuria, mêmes matériaux que la façade jointe "
		"WORLD_BLDG_MAISON_LEO_01 : mur du fond en lambris de bois miel clair au-dessus d'un soubassement "
		"de pierre crème, poutre de bois apparente en haut ; épaisseur des murs en pierre crème ; parquet "
		"de lattes de bois clair. Chaleureuse, lumineuse, un peu bohème. L'intérieur de référence joint "
		"(REF_LEO_PIECE) donne la composition et l'ambiance (lambris, grande fenêtre sur la mer) : n'en "
		"reprends NI les meubles, NI les machines, NI les flaques de lumière dorée, NI la marche d'entrée.",
		2),
]

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenue = défaut (règle 4,
## dossier 17 §4.1 : « tenue de bricoleur, manches retroussées » [D]).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_LEO_HUMAIN", [], 128, "Léo, l'inventeur du Cap d'Azuria, redevenu humain",
		"Léo, inventeur passionné d'environ 25 ans, curieux, bavard et un peu excentrique, l'air "
		"enthousiaste et sympathique : cheveux CHÂTAIN-ROUX en bataille, une paire de LUNETTES DE "
		"PROTECTION à verres ronds relevée sur le front, yeux noisette, sourire large ; CHEMISE à "
		"carreaux vert sapin et crème, MANCHES RETROUSSÉES jusqu'aux coudes ; TABLIER D'ATELIER brun "
		"cuir noué à la taille, avec une poche où dépassent un tournevis et un crayon ; pantalon de "
		"toile beige ; bottines de travail brun foncé. Taille d'un adulte (un peu plus grand que le "
		"héros), silhouette mince. Différent du héros (ni casquette, ni rouge, ni blanc), du professeur "
		"Chen joint (ni blouse blanche, ni cheveux gris) et d'un Dresseur ; aucun insigne, aucun texte.",
		f"{PIEDS_JOINTS}, les deux mains sur les hanches, le buste un peu en avant, l'air ravi et "
		"satisfait", [CHEN], 1),
]

## Planche d'icônes du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE : 4 colonnes).
UI = ("UI_OBJETS_J14_PLANCHE",
	"PLANCHE de DEUX icônes d'objets peintes pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : une icône CENTRÉE dans chacune des DEUX PREMIÈRES colonnes (x de 0 à "
	"384, puis de 384 à 768), chacune de 260 px de large au plus et 260 px de haut au plus, avec au moins "
	"60 px de marge vide de chaque côté ; les deux dernières colonnes restent VIDES (transparentes) ; "
	"dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE (même rendu, même angle de trois "
	"quarts, même lumière).\n"
	"1 (colonne 1) : le PASSE BATEAU, un billet d'embarquement de croisière élégant : une carte "
	"rectangulaire crème un peu épaisse, posée de trois quarts, bordée d'un liseré bleu marine, une "
	"petite silhouette de PAQUEBOT blanc et bleu marine imprimée à gauche, une bande dorée à droite, "
	"un coin prédécoupé ; AUCUNE lettre, AUCUN chiffre, AUCUN code.\n"
	"2 (colonne 2) : le SUPER BONBON, un gros bonbon rond enveloppé dans une PAPILLOTE bleu ciel et "
	"blanc aux deux bouts torsadés, papier brillant aux reflets clairs, un petit motif d'étoile "
	"blanche sur le dessus ; appétissant et précieux.\n"
	"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec "
	"seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).",
	[MENU_OBJETS], 1)

## Conditionnels.
SERIE_COND = [
	("WORLD_PROP_BARRIERE_POLICE_01", None, 1, 1,
		"une BARRIÈRE DE POLICE basse pour barrer une route : une barrière métallique blanche à deux "
		"pieds, 1 case de large et environ 0,8 case de haut, sa lisse peinte de bandes obliques bleu "
		"marine et blanc, un petit gyrophare bleu éteint sur le dessus ; se pose côte à côte avec "
		"elle-même ; aucune lettre, aucun écusson.",
		[FERMETURES], LUMIERE_NE),
]

## Décor de combat conditionnel (chaîne des décors de combat, tools/art/combat_decors/) :
## (identifiant, images jointes dans l'ordre, texte).
DECOR_COMBAT = ("COMBAT_DECOR_ROUTE25_COTE_r1",
	["docs/design/reference/combat-v1.webp", "docs/design/reference/combat-decors-planche-v1.webp",
		"docs/design/reference/route-25-vue-generale-v1.png"],
	"DÉCOR DE COMBAT — ROUTE 25, CORNICHE DU CAP D'AZURIA (Kanto 2026). Image de PRODUCTION : le fond "
	"peint d'un écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, "
	"AUCUNE interface, AUCUN texte.\n\n"
	"Images jointes.\n"
	"IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement "
	"plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité de "
	"peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont.\n"
	"IMAGE 2 : une planche d'intention de décors de combat (guide de facture).\n"
	"IMAGE 3 : la vue générale (de dessus) de la Route 25 : chemin de terre clair entre une forêt dense "
	"et la mer turquoise, rivage de gros blocs de roche beige, falaise beige au loin (guide de palette).\n\n"
	"FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution "
	"possible, OPAQUE, cadrage plein, sans bord.\n\n"
	"LIEU : le chemin côtier de la Route 25. Sol de terre battue claire et d'herbe courte vert tendre, "
	"quelques fleurs ; derrière, à droite, la lisière d'une forêt dense et une falaise beige ; à "
	"gauche, au-delà d'un rivage de gros blocs de roche beige, la MER turquoise puis bleu profond qui "
	"va jusqu'à l'horizon. Golden hour.\n\n"
	"COMPOSITION (fractions depuis le coin haut gauche) :\n"
	"- Horizon vers 33 % de la hauteur : la mer à gauche et au centre, qui miroite doucement ; la "
	"falaise beige et la lisière de la forêt à droite (x 60 à 100 %), entre 15 et 45 % de la hauteur. "
	"Le rivage de blocs de roche beige court en plan moyen entre 40 et 48 % de la hauteur, côté gauche "
	"et centre.\n"
	"- De 50 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de terre battue claire et d'herbe "
	"courte.\n"
	"- Point A (x 67 %, y 58 %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien de "
	"haut dans un rayon de 12 % de la largeur autour.\n"
	"- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier "
	"plan. Rien de haut autour.\n"
	"- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de "
	"détails et peu de contraste, valeurs simples (ciel et mer calmes).\n"
	"- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol "
	"simple, presque sans objet, valeurs moyennes, sans contraste fort.\n"
	"- Les deux coins du bas restent du SOL nu : pas de buisson ni de rocher en gros plan.\n"
	"- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés "
	"sur certains écrans).\n\n"
	"LUMIÈRE : golden hour, soleil bas du haut à gauche (hors cadre), reflets dorés sur la mer, ombres "
	"douces ; ciel bleu pâle voilé aux nuages légers, pas de soleil visible.\n\n"
	"RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D "
	"peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni "
	"en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches "
	"sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à "
	"hauteur d'yeux, un peu plongeante, le sol recule nettement vers l'horizon.\n\n"
	"INTERDITS : Pokémon, animal, oiseau, mouette, poisson, personnage, silhouette, texte, lettres, "
	"chiffres, panneau lisible, logo, signature, filigrane, cadre, interface, bateau, maison, bâtiment, "
	"phare, véhicule, pixel art, flou, vignettage.\n")

## Corrections (T2) : (identifiant sans _NE_rN, révision) → texte qui remplace la description
## d'origine (planche, coque ou décor). Vide au T1.
CORRECTIONS: dict[tuple[str, int], str] = {}

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées "
		"de la Route 25 et de la maison de Léo (ambiance dorée : n'en copie ni le rendu ni la lumière) ; ")


def _prompt_objet(identifiant: str, ref: str | None, largeur, hauteur, description: str,
		ancres: list[str], valeurs: str) -> str:
	jointes = "Images jointes : "
	if ref:
		jointes += (f"{ref} = référence de forme, de matériaux et de couleurs, extraite d'une vue "
			"d'ensemble validée (minuscule : n'en copie pas le rendu) : dessine l'élément comme s'il "
			"avait été extrait de cette image puis agrandi, avec le même angle, mais avec la finesse des "
			"ancres. ")
	jointes += (f"{_noms(STYLE + ancres)} = ancres de style de la série (rendu peint, contour coloré, "
		"finesse, même angle de vue, même lumière neutre). Les vues sont en lumière d'ambiance : "
		"l'élément garde la lumière NEUTRE des ancres (le jeu ajoute la lumière lui-même).")
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
		f"fenêtre ; aucun meuble).\nImages jointes : {_noms(ancres)} = ancres de style des intérieurs "
		"(rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre), "
		"matériaux de la façade et composition de la pièce de référence : respecte-les exactement.\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		"trois quarts, image opaque qui remplit tout le cadre.\n"
		f"Géométrie (respecte-la exactement, c'est un plan de jeu) : {geometrie}\n"
		f"Pièce : {materiaux}\n"
		"Interdit : meubles, machines, cabines, bibliothèques, lit, plantes, tapis (sauf le paillasson "
		"demandé), personnages, Pokémon (ni Pikachu), porte fermée, marche ou escalier d'entrée, flaques "
		"de lumière peintes au sol, texte, lettres, chiffres, logo, emblème rond de type balle, "
		"perspective avec point de fuite, vue isométrique, ombre portée.\n")


def _prompt_marche(identifiant: str, refs: list[str], tenue: str, ancres: list[str]) -> str:
	texte = ""
	if refs:
		texte += (f" ; {', '.join(refs)} = tenue et silhouette seulement (minuscules, extraites des vues "
			"d'ensemble, rendu à NE PAS copier)")
	if ancres:
		texte += (f" ; {_noms(ancres)} = même main et même finesse pour un adulte (à NE PAS copier : "
			"autre visage, autre tenue)")
	return MODELE_MARCHE.format(ident=identifiant, ref=texte, tenue=tenue) + INTERDITS + "\n"


def _prompt_attente(identifiant: str, role: str, hauteur: int, tenue: str, pose: str) -> str:
	"""Modèle des attentes des séries 10–15."""
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
	$ART, ou chemins relatifs à la racine pour le décor de combat), vague, conditionnel, groupe."""
	images = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for liste, conditionnel in ((SERIE, False), ([(*t, 2) for t in SERIE_COND], True)):
		for ident, ref, largeur, hauteur, description, ancres, valeurs, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur,
				description, ancres, valeurs), ([f"{ref}.png"] if ref else []) + STYLE + ancres, vague,
				conditionnel, groupe=ident)
	for ident, refs, description, ancres, valeurs, vague in PLANCHES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres, valeurs),
			[f"{r}.png" for r in refs] + ancres, vague, groupe=ident)
	for ident, largeur, profondeur, ancres, geometrie, materiaux, vague in COQUES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, geometrie, materiaux, ancres),
			ancres, vague, groupe=ident)
	for ident, refs, hauteur, role, tenue, pose, ancres, vague in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres),
			[HEROS] + [f"{r}.png" for r in refs] + ancres, vague, groupe=ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1,
			groupe=ident)
	ident, description, ancres, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres), vague, groupe=ident)
	ident, jointes, texte = DECOR_COMBAT
	ajouter(ident, DECORS_COMBAT / f"{ident}.txt", texte, jointes, 2, True,
		groupe=ident.rsplit("_", 1)[0])
	for (ident, rev), description in CORRECTIONS.items():
		nom = f"{ident}_NE_r{rev}"
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
			precedent = f"{ident}_NE_r{rev - 1}.png"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, description, materiaux,
				[precedent] + ancres_), [precedent] + ancres_, 3, True, groupe=groupe)
	return images


def ecrire_prompts() -> None:
	changes = 0
	images = _images()
	for image in images:
		fichier: Path = image["fichier"]
		fichier.parent.mkdir(parents=True, exist_ok=True)
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	print(f"{len(images)} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}, "
		f"{ATTENTES.relative_to(RACINE)}, {DECORS_COMBAT.relative_to(RACINE)}")


# --- Références et génération ----------------------------------------------------------


def _recadrage(nom: str) -> Image.Image:
	vue, boite = REFS[nom]
	return Image.open(VUES[vue]).convert("RGB").crop(boite)


def references() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for nom in REFS:
		ref = _recadrage(nom)
		facteur = min(AGRANDIR, REF_MAX / max(ref.size))
		if facteur != 1:
			ref = ref.resize((round(ref.width * facteur), round(ref.height * facteur)), Image.LANCZOS)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_R25_*, REF_LEO_* dans {ART}")


def _jointes_art() -> set[str]:
	"""Noms des jointes à trouver dans $ART (hors références, images de la série et décor)."""
	generees = {i["nom"] + ".png" for i in _images()}
	return {j for i in _images() for j in i["jointes"]
		if "/" not in j and not j.startswith("REF_") and j not in generees}


def ancres() -> None:
	"""Copie dans $ART les ancres de style absentes (checkout principal, puis copies du J13)."""
	ART.mkdir(parents=True, exist_ok=True)
	manquantes = []
	for nom in sorted(set(ANCRES) | _jointes_art()):
		if (ART / nom).exists():
			continue
		source = next((s / nom for s in SOURCES_ANCRES if (s / nom).exists()), None)
		if source is None:
			manquantes.append(nom)
		elif source.resolve() != (ART / nom).resolve():
			shutil.copy2(source, ART / nom)
	print("ancres copiées" + (f" ; ABSENTES : {', '.join(manquantes)}" if manquantes else ""))


VAGUES = (1, 2, 3)


def _chemin_jointe(jointe: str) -> str:
	return jointe if "/" in jointe else f"$ART/{jointe}"


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
				jointes = " ".join(_chemin_jointe(j) for j in i["jointes"])
				lignes.append(f"tools/art/generer.sh {i['nom']} {fichier} {jointes}".rstrip())
	return "\n".join(lignes)


def _generer(image: dict) -> str:
	texte = image["fichier"].read_text()
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	return _lancer(image["nom"], texte, jointes)


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


# --- Manifeste (T13) --------------------------------------------------------------------

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


## Rôles des modules de rivage (fiche, §« Alignement ») ; ordre de lecture de la planche.
RIVAGE_IDS = ["relief_rivage_01", "relief_rivage_02", "relief_rivage_03", "relief_rivage_04",
	"relief_rivage_05", "relief_rivage_06", "prop_indice_coquillage_01", "prop_cloture_reparee_01"]
LEO_IDS = ["int_cabine_teleport_01", "int_console_leo_01", "int_module_leo_01",
	"int_ecran_diagnostic_01", "int_bureau_leo_01", "int_bibliotheque_cote_01"]


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T13 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T13 sur la planche de contrôle. `cases` = largeur en cases de chaque élément."""
	return {
		"objets": [
			{"id": "bldg_maison_leo_01", "source": _revision("WORLD_BLDG_MAISON_LEO_01_NE"),
				"sortie": f"{_W}buildings/bldg_maison_leo_01.png", "axe": "w", "cases": 8,
				"ombre": True, "contact": 0.12},
		],
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_RIVAGE_PLANCHE_NE", "relief", 4, 2, RIVAGE_IDS,
				[2, 2, 1, 1, 1, 1, 0.35, 1], 0.0),
			_planche_objets("INT_MAISON_LEO_PLANCHE_NE", "interiors", 3, 2, LEO_IDS,
				[3, 2, 1, 1.3, 3, 1], 0.2),
		],
		"pieces": [
			{"id": "int_maison_leo_coque", "source": _revision("INT_MAISON_LEO_COQUE_NE"),
				"sortie": f"{_W}interiors/int_maison_leo_coque.png", "cases": [16, 11]},
		],
		"pokemon": [
			{"id": "melofee", "source": "POKE_MELOFEE_NE_r1.png",
				"sortie": "assets/sprites/pokemon/painted/melofee_sheet.png", "hauteur": 52},
		],
		"personnages": [
			{"id": "leo_humain", "source": _revision("PNJ_LEO_HUMAIN_NE"),
				"sortie": f"{_C}leo_humain_sheet.png", "hauteur": 128},
		],
		"attentes": [
			{"id": "leo_humain_idle", "source": _revision("LEO_HUMAIN_ATTENTE"),
				"sortie": f"{_C}leo_humain_idle_sheet.png", "marche": "leo_humain"},
		],
	}


## Icônes du Sac (T13, `preparer_menu.py` : planche de 4 colonnes, les 2 premières occupées) →
## `assets/ui/items/ss_ticket.webp`, `rare_candy.webp`.
ICONES_IDS = ["ss_ticket", "rare_candy"]
## Planches de personnages préparées : (planche, identifiant de look, hauteur de fiche). Le look
## `leo` existe déjà (Nils) : Léo humain est le look `bill`.
PERSONNAGES_JEU = [("leo_humain", "bill", 128)]


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 15) ; une section absente est créée en fin de fichier."""
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
	print(f"manifeste : {ajouts} entrée(s) de la série 16 ajoutée(s)")


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
	w, c = _W, _C
	p = _Planche(2600, "Route 25, Cap d'Azuria, maison de Léo — kit de la série 16 (T1, jalon 14) : "
		"1 case = 48 px ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu ou dans les séries 14–15)", [
		heros,
		*[(_asset(f"{w}relief/relief_paroi_0{i}.png"), f"relief_paroi_0{i}\nfalaise K, piliers R")
			for i in (1, 3)],
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 5)],
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\nH1–H4"),
		(_asset(f"{w}relief/relief_rebord_01.png"), "relief_rebord_01\nrebord L1 v"),
		(_asset(f"{w}props/prop_buisson_a_01.png"), "buissons x"),
		(_asset(f"{w}props/prop_massif_01.png"), "massifs f"),
		(_asset(f"{w}props/prop_hortensias_01.png"), "hortensias\n(massifs f)"),
		(_asset(f"{w}props/prop_rocher_mer_01.png"), "rocher de mer\n(accents)"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneaux ×2"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball\nO1–O3"),
		(_asset(f"{w}props/prop_barriere_croisillon_01.png"), "barrière à croisillon\n(barrage sud)"),
		(_asset(f"{w}props/prop_ruban_01.png"), "prop_ruban_01\n(bande, ruban)"),
		*_si(f"{c}jeune_dresseur_sheet.png", "youngster :\nJules, D6", _cellule_perso),
		*_si(f"{c}montagnard_sheet.png", "mountaineer : D2, D4", _cellule_perso),
		*_si(f"{c}fillette_sheet.png", "lass_young : Zoé", _cellule_perso),
		*_si(f"{c}campeur_sheet.png", "camper : D5", _cellule_perso),
		*_si(f"{c}voyageur_sheet.png", "traveler :\npromeneur P1", _cellule_perso),
		*_si(f"{c}vieil_homme_sheet.png", "old_man :\npêcheur P2", _cellule_perso),
		*_si(f"{c}garde_sheet.png", "guard :\npoliciers", _cellule_perso),
		*_si(f"{c}sbire_h_sheet.png", "sbire_h : Rocket", _cellule_perso),
	], (40, 90, 50))
	sols = [(_echelle(Image.open(RACINE / f"{w}ground/{n}.png").convert("RGBA").crop((0, 0, 192, 192)),
		0.5), f"{n}\n{role}") for n, role in (("ground_herbe_01", "herbe ."),
		("ground_chemin_01", "chemin ="), ("ground_sable_01", "sable s (crique)"),
		("ground_eau_01", "mer w + écume (shader)"))]
	p.section("1 bis. SOLS RÉUTILISÉS (extrait 2 × 2 cases)", sols, (40, 90, 50))
	interieur = [
		(_asset(f"{w}interiors/int_lit_01.png"), "int_lit_01\nlit L (12..13, 7..8)"),
		(_asset(f"{w}interiors/int_chevet_lampe_01.png"), "chevet"),
		(_asset(f"{w}interiors/int_plante.png"), "int_plante\nx (1, 9)"),
		(_asset(f"{w}interiors/int_chaise_bureau_01.png"), "chaise (6, 8)"),
		(_asset(f"{w}interiors/int_tapis_salon_01.png"), "tapis"),
		(_asset(f"{w}interiors/int_bureau_chen_01.png"), "bureau de Chen\n(repli du bureau)"),
	]
	p.section("1 ter. INTÉRIEUR RÉUTILISÉ (maison de Léo)", [heros, *interieur], (40, 90, 50))

	rivage = _ref("REF_R25_RIVAGE")
	p.section("2. VARIATIONS SANS NOUVEL ASSET", [
		(_miroir(_asset(f"{w}props/prop_massif_01.png")), "massif en miroir ± 8 %"),
		(_ref("REF_R25_FALAISE", 3), "falaise : paroi série 12\n(étalonnage golden_hour)"),
		(_ref("REF_R25_PILIER"), "piliers R : modules\nde paroi empilés"),
	], (110, 90, 40))
	p.section("3. NOUVEAUX : CÔTE ET CAP (série 16, Codex, lumière NE)", [
		heros,
		(rivage, "RIVAGE_PLANCHE : 6 modules\n(droits ×2, côté, angles, bloc)"),
		(_ref("REF_R25_RIVAGE_ANGLE"), "angle extérieur\n(vue)"),
		(_ref("REF_R25_ROCHER_INDICE"), "+ coquillage O4\n(64, 20)"),
		(_ref("REF_R25_MAISON", 6), "BLDG_MAISON_LEO_01\n8 × 6, ardoise bleue"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : MAISON DE LÉO ET PERSONNAGE", [
		heros,
		(_ref("REF_LEO_PIECE", 5.5), "INT_MAISON_LEO_COQUE\n16 × 11 (vide ; réduite × 0,5)"),
		(_ref("REF_LEO_CABINE", 2.8), "PLANCHE : cabine\n(+ armoire), ×2 miroir"),
		(_ref("REF_LEO_CONSOLE", 1.4), "console 2 × 1\ngrand bouton rouge"),
		(_ref("REF_LEO_MODULE", 1.6), "module 1 × 1"),
		(_ref("REF_LEO_ECRAN", 1.2), "écran 1 × 1"),
		(_ref("REF_LEO_BUREAU", 2.5), "bureau encombré 3 × 1"),
		(_ref("REF_LEO_BIBLIO", 3), "bibliothèque de côté\n1 × 2, ×2 miroir"),
		# Aucune référence peinte de Léo humain : l'échelle est celle d'un adulte (128 px).
		(heros[0], "PNJ_LEO_HUMAIN 128 px\n(+ attente ; aucune réf.)"),
	], (130, 100, 40))
	icones = [(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
		f"{i}.webp\n(existante, style)") for i in ("potion", "nugget")
		if (RACINE / f"assets/ui/items/{i}.webp").exists()]
	p.section("3 ter. ICÔNES DU SAC : UI_OBJETS_J14_PLANCHE (Passe Bateau, Super Bonbon)", icones,
		(90, 60, 120))
	p.section("3 quater. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_asset(f"{w}props/prop_barriere_croisillon_01.png"), "BARRIERE_POLICE_01\nsi croisillon\nne se lit pas"),
		(_ref("REF_R25_MER", hauteur=110), "COMBAT_DECOR_ROUTE25\n_COTE (repli : flou)"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_R25_SCOUT", hauteur=64), "Scout de D5\n→ camper"),
		(_ref("REF_R25_PECHEUR", hauteur=64), "personnages placés\npar le peintre"),
		(_ref("REF_LEO_MARCHE", 2), "marche d'entrée\n(n'existe pas)"),
		(_ref("REF_LEO_FENETRE", 1.6), "lumière dorée au sol\n(jeu : NE + éclairage)"),
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
	"""Planche de contrôle du T13 : les assets **préparés** (assets/), à 1:1 (1 case = 96 px)."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(4300, "Série 16 préparée (T13, jalon 14) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	donnees = manifeste_donnees()
	elements = [x for planche_ in donnees["planches_objets"] for ident in planche_["ids"]
		for x in _present(f"{planche_['dossier']}{ident}.png", ident)]
	p.section("1. PLANCHES DÉCOUPÉES (rivage, indice, clôture, meubles de Léo)", [heros, *elements],
		(60, 80, 110))
	p.section("2. MAISON DU CAP", [heros, *[x for e in donnees["objets"]
		for x in _present(e["sortie"], e["id"])]], (130, 70, 40))
	p.section("3. COQUE (réduite × 0,5)", [x for e in donnees["pieces"]
		for x in _present(e["sortie"], e["id"], lambda r: _jeu(r, 0.5))], (130, 100, 40))
	p.section("4. LÉO HUMAIN : marche (face, gauche, droite, dos) puis attente", [
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


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T2, validation 14.0-art) : la dernière révision
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
	lignes = max(1, (len(choisies) + colonnes - 1) // colonnes)
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
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "R25_KIT_v1.png"))
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon14_assets" / "serie16_contact.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon14_assets" / "serie16_controle.png"))
	else:
		generer(set(arguments))
