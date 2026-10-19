#!/usr/bin/env python3
"""Série 18 — S.S. Anne et Arène de Carmin (jalon 16, lumière neutre).
Liste : docs/tech/jalon-16.md §1.4 ; fiches : docs/design/fiches-assets/serie-18-ss-anne.md.
**Numéro provisoire** : la série prend son numéro au push ; 18 = prochain numéro libre constaté le
2026-10-16 (17 = J15, 19 = J17, 20 = J19 sur les branches distantes ; 18 absent partout).

Méthode des J8–J15 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées, `docs/design/reference/ss-anne-pont-principal-v1.png`, `ss-anne-pont-exterieur-v1.png`,
`arene-carmin-v1.png` ; **la grille fait foi** : `tools/plans/ss_anne_*.txt`, `carmin_arene.txt`).
Les salles du navire sans vue (couloir et cabine du capitaine, restaurant, pont inférieur, cabines)
suivent le rendu du pont principal : leur coque est générée en vague 2, la coque du pont principal
jointe. Réutilisés : navire amarré (3 tranches), jeune arbre de l'Arène, passerelle, caisses du port,
marin (série 17, `main`), plantes, PNJ existants, rival. Générées :
  - coques : pont principal, couloir du capitaine, cabine du capitaine, restaurant, pont inférieur,
    cabine de passagers (A, B, C), Arène de Carmin ;
  - mobilier : deux planches du navire, une planche de l'Arène (poubelle unique ×15, armoires
    électriques, barrière active / coupée) ;
  - pont extérieur : planche des bastingages (+ chaises longues, bouée), superstructure ouest ;
  - personnages : capitaine (+ pose « malade »), Major Bob, gentleman, rockeur, hôtesse, passagère ;
  - effet de Coupe (4 images), icônes du Sac (Anti-Para, Réveil), 3 décors de combat (CB.3).
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_GROUND_PONT_TECK_01 (si les planches du quai
éclaircies ne suffisent pas), PNJ_CUISINIER (aucune case dans la grille : décision de Kevin).

Lumière : NE pour tout ce qui va dans le monde (appliques, hublots, tubes lumineux et voyants peints
éteints-neutres : la lueur vient de `LightGlow` et des profils de lumière) ; les décors de combat
gardent leur ambiance (chaîne CB.3).

**Les prompts sont versionnés** : `tools/art/prompts/serie18/<NOM>.txt` (un par image),
`tools/art/attente/prompts/<NOM>_ATTENTE.txt` et `tools/art/combat_decors/prompts/`, écrits par
`--prompts` à partir des tables ci-dessous. Corriger une image = corriger la table, relancer
`--prompts`, relire le diff ; une correction après génération se lance en `_r2` (table CORRECTIONS).

Usage :
  tools/art/serie18.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie18.py --refs                  recadre les REF_PP_*, REF_PE_*, REF_AC_* dans $ART
  tools/art/serie18.py --ancres                copie les ancres de style absentes dans $ART (images
                                               brutes, sinon assets préparés locaux ou de origin/main)
  tools/art/serie18.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie18.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/J16_KIT_v1.png)
  tools/art/serie18.py --contact [sortie.png]  planche de contact des images générées (T2)
  tools/art/serie18.py --manifeste             ajoute les entrées en fin de manifeste.json (T10 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie18.py [IDENTIFIANT ...]       génère avec Codex, par vagues (sans argument : la
                                               série sans les conditionnels ; --refs --ancres d'abord)
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie10  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE, TEXTURE_FIN  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_lancer, _Planche, _police)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
## Ancres validées : checkout principal, puis toutes les copies de travail ; la première trouvée gagne.
_PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026")
## Branche où vivent les assets préparés de la série 17 (J15) tant que `jalon-16` ne l'a pas fusionnée.
BRANCHE_J15 = "origin/main"


def _sources_ancres() -> list[Path]:
	copies = sorted((_PRINCIPAL / ".claude" / "worktrees").glob("*/build/art"))
	return [_PRINCIPAL / "build" / "art", *copies]


REFERENCE = RACINE / "docs/design/reference"
PLANS = RACINE / "tools/plans"
VUES = {
	"PP": REFERENCE / "ss-anne-pont-principal-v1.png",  # 1536 × 1024, grille 26 × 13 (≈ 59 × 79 px)
	"PE": REFERENCE / "ss-anne-pont-exterieur-v1.png",  # 1536 × 1024, grille 26 × 11 (≈ 59 × 93 px)
	"AC": REFERENCE / "arene-carmin-v1.png",  # 1536 × 1024, grille 17 × 15 (≈ 90 × 68 px)
}
## Pixels de la vue par case (hauteur), pour remettre un recadrage à la taille en jeu.
PX_CASE = {"PP": 79.0, "PE": 93.0, "AC": 68.0}
PROMPTS = ICI / "prompts" / "serie18"
ATTENTES = ICI / "attente" / "prompts"
DECORS_COMBAT = ICI / "combat_decors" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue). Agrandis × 3 au plus, sans
## dépasser 1 536 px. Boîtes recalées à l'œil sur les vues (la grille, elle, fait foi).
REFS = {
	# Pont principal (hall d'accueil)
	"REF_PP_SALLE": ("PP", (0, 0, 1536, 1024)),
	"REF_PP_MUR": ("PP", (110, 80, 1430, 235)),
	"REF_PP_PORTE": ("PP", (240, 95, 355, 225)),
	"REF_PP_BANQUETTE": ("PP", (170, 215, 335, 312)),
	"REF_PP_COMPTOIR": ("PP", (862, 678, 1205, 782)),
	"REF_PP_ESCALIER": ("PP", (1268, 662, 1482, 782)),
	"REF_PP_PASSERELLE": ("PP", (570, 760, 845, 915)),
	"REF_PP_TAPIS": ("PP", (415, 370, 1115, 640)),
	# Pont extérieur
	"REF_PE_PONT": ("PE", (0, 0, 1536, 1024)),
	"REF_PE_BASTINGAGE_N": ("PE", (80, 240, 900, 310)),
	"REF_PE_BASTINGAGE_S": ("PE", (0, 650, 900, 805)),
	"REF_PE_ANGLE_EST": ("PE", (1440, 240, 1536, 700)),
	"REF_PE_SUPERSTRUCTURE": ("PE", (0, 175, 85, 665)),
	"REF_PE_CHAISES": ("PE", (275, 330, 425, 450)),
	"REF_PE_BOUEE": ("PE", (822, 258, 898, 330)),
	"REF_PE_TECK": ("PE", (500, 330, 1300, 640)),
	"REF_PE_MOUETTES": ("PE", (1340, 70, 1500, 150)),
	# Arène de Carmin
	"REF_AC_SALLE": ("AC", (0, 0, 1536, 1024)),
	"REF_AC_MUR": ("AC", (190, 15, 1345, 190)),
	"REF_AC_POUBELLE": ("AC", (198, 478, 282, 572)),
	"REF_AC_ARMOIRES": ("AC", (128, 298, 625, 432)),
	"REF_AC_BARRIERE": ("AC", (605, 292, 930, 432)),
	"REF_AC_SOL": ("AC", (300, 590, 1200, 900)),
	"REF_AC_CHAMPION": ("AC", (190, 175, 1345, 300)),
}
AGRANDIR = 3
REF_MAX = 1536

## Ancres de style (images validées des séries précédentes, dans $ART ; `--ancres` les copie).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"
COQUE_CENTRE = "INT_CENTRE_COQUE_NE_r1.png"
COQUE_LABO = "INT_LABO_COQUE_NE_r1.png"
COQUE_ARENE_AZ = "INT_ARENE_AZURIA_COQUE_NE_r2.png"  # série 15
COQUE_LEO = "INT_MAISON_LEO_COQUE_NE_r1.png"  # série 16
COMPTOIR = "INT_LONG_COMPTOIR_01_NE_r1.png"
CANAPE = "INT_CANAPE_01_NE_r1.png"
LIT = "INT_LIT_01_NE_r1.png"
LAVABO = "INT_LAVABO_01_NE_r1.png"
ETAGERE = "INT_GRANDE_ETAGERE_01_NE_r1.png"
MACHINES = "INT_MACHINES_LABO_01_NE_r1.png"
CAISSES = "WORLD_PROP_CAISSES_01_NE_r1.png"
EAU_MER = "WORLD_GROUND_EAU_01_NE_r1.png"
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
GUIDE = "PNJ_GUIDE_ARENE_NE_r1.png"
PIERRE = "PNJ_PIERRE_NE_r1.png"
ONDINE = "PNJ_ONDINE_NE_r1.png"  # série 15
MARCHAND = "PNJ_MARCHAND_NE_r1.png"
VIEIL_HOMME = "PNJ_VIEIL_HOMME_NE_r1.png"
# Série 17 (J15, `main`) : brutes dans une copie de travail, sinon assets préparés de `main`.
MARIN = "PNJ_MARIN_NE_r1.png"
NAVIRE = "WORLD_BLDG_SS_ANNE_MILIEU_NE_r1.png"
ARENE_CARMIN = "WORLD_BLDG_ARENE_CARMIN_01_NE_r1.png"
QUAI = "WORLD_GROUND_PLANCHES_QUAI_01_NE_r1.png"
PRESIDENT = "PNJ_PRESIDENT_FAN_CLUB_NE_r1.png"
# Images de la série 18 jointes aux vagues suivantes.
COQUE_PP = "INT_SS_ANNE_PONT_PRINCIPAL_COQUE_NE_r1.png"
PLANCHE_A = "INT_SS_ANNE_PLANCHE_A_NE_r1.png"
ANCRES = [*STYLE, HEROS, COQUE_CENTRE, COQUE_LABO, COQUE_ARENE_AZ, COQUE_LEO, COMPTOIR, CANAPE, LIT,
	LAVABO, ETAGERE, MACHINES, CAISSES, EAU_MER, MENU_OBJETS, GUIDE, PIERRE, ONDINE, MARCHAND,
	VIEIL_HOMME, MARIN, NAVIRE, ARENE_CARMIN, QUAI, PRESIDENT]

## Repli de `--ancres` : image brute introuvable → asset préparé (local, sinon `BRANCHE_J15`),
## converti en PNG sous le nom brut. Assez pour une ancre de style ou de tenue.
PREPARES = {
	MARIN: "assets/sprites/characters/painted/marin_sheet.png",
	PRESIDENT: "assets/sprites/characters/painted/president_fan_club_sheet.png",
	NAVIRE: "assets/world/buildings/bldg_ss_anne_milieu_01.png",
	ARENE_CARMIN: "assets/world/buildings/bldg_arene_carmin_01.png",
	QUAI: "assets/world/ground/ground_planches_quai_01.png",
	COQUE_ARENE_AZ: "assets/world/interiors/int_arene_azuria_coque.png",
	COQUE_LEO: "assets/world/interiors/int_maison_leo_coque.png",
	ONDINE: "assets/sprites/characters/painted/ondine_sheet.png",
}

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, nom de navire, plaque gravée "
	"lisible, AUCUN emblème rond de type balle (ni cercle partagé en deux, ni médaillon à bande "
	"centrale) nulle part, animaux réels ou faune non-Pokémon (mouettes, oiseaux, poissons réels), "
	"Pikachu et tout Pokémon non demandé, personnage qui ressemble au héros (casquette rouge, t-shirt "
	"blanc, sac à dos jaune), élément effrayant.")

LUMIERE_INT = (LUMIERE_NE + " Intérieur : les appliques, les hublots, les tubes lumineux et les voyants "
	"sont peints dans leur couleur propre, ÉTEINTS-NEUTRES, sans halo, sans rayon, sans flaque de lumière "
	"ni faisceau au sol (le jeu ajoute lui-même la lumière) ; les hublots montrent la mer et le ciel de "
	"jour, bleus et calmes.")

# --- Grilles (font foi) ------------------------------------------------------------------


def lire_grille(nom: str) -> list[str]:
	"""Rangées de la section GRILLE de `tools/plans/<nom>.txt` (sans le numéro de rangée)."""
	lignes = (PLANS / f"{nom}.txt").read_text().splitlines()
	debut = next(i for i, ligne in enumerate(lignes) if ligne.startswith("GRILLE "))
	_, largeur, hauteur = lignes[debut].split()
	rangees = [ligne[3:] for ligne in lignes[debut + 1:debut + 1 + int(hauteur)]]
	assert all(len(r) == int(largeur) for r in rangees), nom
	return rangees


def _murs(rangees: list[str]) -> tuple[int, int, int, int]:
	"""Épaisseurs (haut, bas, gauche, droite) en cases : rangées sans sol au haut et au bas, colonnes
	de mur (K, D) au bord de chaque rangée du sol (minimum sur les rangées)."""
	sol = [i for i, r in enumerate(rangees) if any(c not in "KDXw" for c in r)]
	haut, bas = sol[0], len(rangees) - 1 - sol[-1]
	gauche = min(len(r) - len(r.lstrip("KD")) for r in rangees[haut:len(rangees) - bas])
	droite = min(len(r) - len(r.rstrip("KD")) for r in rangees[haut:len(rangees) - bas])
	return haut, bas, gauche, droite


def _groupes(cases: list[int]) -> list[tuple[int, int]]:
	groupes: list[tuple[int, int]] = []
	for c in sorted(cases):
		if groupes and c == groupes[-1][1] + 1:
			groupes[-1] = (groupes[-1][0], c)
		else:
			groupes.append((c, c))
	return groupes


def geometrie(nom: str, cadre: tuple[int, int, int, int] | None = None) -> str:
	"""Géométrie d'une coque tirée de la grille : taille, murs, portes, sorties, en cases et en pixels
	de l'image générée. `cadre` = (x0, y0, px par case en largeur, en hauteur) ; défaut : la pièce
	remplit tout le cadre 1536 × 1024."""
	rangees = lire_grille(nom)
	largeur, hauteur = len(rangees[0]), len(rangees)
	x0, y0, cw, ch = cadre or (0, 0, 1536 / largeur, 1024 / hauteur)
	haut, bas, gauche, droite = _murs(rangees)

	def px_x(a: int, b: int) -> str:
		return f"x ≈ {round(x0 + a * cw)} à {round(x0 + (b + 1) * cw)}"

	def px_y(a: int, b: int) -> str:
		return f"y ≈ {round(y0 + a * ch)} à {round(y0 + (b + 1) * ch)}"

	morceaux = [
		f"La pièce fait {largeur} cases de large × {hauteur} de profondeur (1 case ≈ {round(cw)} px de "
		f"large, ≈ {round(ch)} px de haut sur l'image ; la préparation l'étire à {largeur * 96} × "
		f"{hauteur * 96} : 1 case = 96 px).",
		f"Mur du fond : les {haut} rangées du haut ({px_y(0, haut - 1)}), dont on voit la FACE avant.",
		f"Murs latéraux : {gauche} colonne(s) d'épaisseur à gauche ({px_x(0, gauche - 1)}) et {droite} à "
		f"droite ({px_x(largeur - droite, largeur - 1)}), vus seulement par leur épaisseur de dessus.",
		f"Mur du bas : les {bas} rangées du bas ({px_y(hauteur - bas, hauteur - 1)}), vu par son "
		"épaisseur de dessus.",
	]
	for y, rangee in enumerate(rangees):
		for x, c in enumerate(rangee):
			if c != "D":
				continue
			if y < haut:
				morceaux.append(f"PORTE FERMÉE d'une case dans le mur du fond, colonne {x + 1} sur "
					f"{largeur} ({px_x(x, x)}), en bas de la face du mur.")
			elif x < gauche + 1:
				morceaux.append(f"PORTE FERMÉE dans le mur de GAUCHE, à la hauteur de la rangée {y + 1} "
					f"({px_y(y, y)}), vue dans l'épaisseur du mur.")
			else:
				morceaux.append(f"PORTE FERMÉE dans le mur de DROITE, à la hauteur de la rangée {y + 1} "
					f"({px_y(y, y)}), vue dans l'épaisseur du mur.")
	sorties = [x for y in range(hauteur - bas, hauteur) for x, c in enumerate(rangees[y]) if c == "X"]
	for a, b in _groupes(sorties):
		morceaux.append(f"SORTIE : une OUVERTURE de {b - a + 1} case(s) dans le mur du bas, colonnes "
			f"{a + 1} à {b + 1} ({px_x(a, b)}), seuil plat, sans porte, sans marche.")
	morceaux.append("Tout le reste du sol est LIBRE et VIDE : les meubles, les objets et les "
		"personnages sont posés à part par le jeu.")
	return " ".join(morceaux)


# --- Tables ------------------------------------------------------------------------------

_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus.")
## Couloir du capitaine (18 × 7) : bande de 1 530 × 595 px centrée (1 case = 85 px), recadrée à la
## préparation (`boite`) ; les autres pièces remplissent tout le cadre.
CADRE_COULOIR = (3, 214, 85, 85)
## T10 : la bande réellement peinte dans `_r1` (1 536 × 520 px, rangées 250..770 ; le reste est
## noir) ; étirée de 1,125 en largeur et 1,29 en hauteur vers les 18 × 7 cases.
BOITE_COULOIR = [0, 250, 1536, 770]

## Coques : (identifiant, grille, cadre, ancres, matériaux et décor, escaliers, vague).
COQUES = [
	("INT_SS_ANNE_PONT_PRINCIPAL_COQUE", "ss_anne_pont_principal", None,
		["REF_PP_SALLE.png", "REF_PP_MUR.png", COQUE_CENTRE, COQUE_LEO, NAVIRE],
		"le grand HALL D'ACCUEIL du paquebot de croisière S.S. Anne, RECALÉ sur la vue d'ensemble validée "
		"jointe REF_PP_SALLE (la reproduire fidèlement, en plus net, avec les MÊMES matériaux et couleurs) "
		"MAIS SANS ses meubles (ni banquettes, ni comptoir, ni plantes : ils sont posés à part) et SANS ses "
		"faisceaux et flaques de lumière dorée : mur du fond CRÈME au-dessus d'un haut LAMBRIS D'ACAJOU, "
		"corniche de bois, HUBLOTS RONDS cerclés de laiton entre les portes, petites appliques de laiton à "
		"globe de verre ; portes de bois verni à petit hublot rond et poignée de laiton ; épaisseur des "
		"murs en acajou sombre ; PARQUET de lattes de bois miel posées horizontalement ; au centre, un "
		"grand TAPIS bordeaux à double bordure dorée peint à plat dans le sol, de la 8e à la 19e colonne "
		"et de la 5e à la 9e rangée (comme dans la vue). Élégant, chaleureux, accueillant.",
		"Dans le coin bas à droite, EXACTEMENT sur les 23e et 24e colonnes de la 11e rangée, la TRÉMIE "
		"d'un ESCALIER qui DESCEND vers le pont inférieur : une ouverture de 2 cases dans le parquet, des "
		"marches de bois qui s'enfoncent vers le bas de l'image, une rambarde de laiton sur ses côtés "
		"gauche, droit et haut (comme dans la vue). La sortie du bas est l'arrivée de la PASSERELLE : "
		"seuil de planches claires.", 1),
	("INT_SS_ANNE_COULOIR_COQUE", "ss_anne_couloir_capitaine", CADRE_COULOIR,
		[COQUE_PP, "REF_PP_MUR.png", "REF_PP_PORTE.png"],
		"le COULOIR DES OFFICIERS du S.S. Anne, qui mène à la cabine du capitaine : MÊMES matériaux et MÊME "
		"main que la coque jointe du hall INT_SS_ANNE_PONT_PRINCIPAL_COQUE (mur crème au-dessus du lambris "
		"d'acajou, appliques de laiton, deux hublots ronds), plus intime : une longue MOQUETTE BLEU MARINE "
		"à liseré doré court sur toute la longueur du sol ; la porte du fond (cabine du capitaine) est plus "
		"imposante que les autres : bois sombre à deux panneaux, poignée et petite plaque de laiton VIERGE.",
		"FORMAT PARTICULIER : le couloir est une BANDE de 1 530 × 595 px centrée verticalement dans l'image "
		"1536 × 1024 (de y = 214 à y = 809) ; au-dessus et au-dessous, un fond NOIR UNI (rogné à la "
		"préparation).", 2),
	("INT_SS_ANNE_CABINE_CAPITAINE_COQUE", "ss_anne_cabine_capitaine", None,
		[COQUE_PP, "REF_PP_MUR.png", COQUE_LEO],
		"la CABINE DU CAPITAINE du S.S. Anne : MÊMES matériaux et MÊME main que la coque jointe du hall "
		"INT_SS_ANNE_PONT_PRINCIPAL_COQUE, plus sobre et plus marine : lambris d'acajou sur toute la "
		"hauteur du mur du fond, un GRAND HUBLOT DOUBLE cerclé de laiton à gauche du milieu, une "
		"horloge de bord ronde de laiton SANS chiffres, un baromètre ; moquette BLEU MARINE unie bordée "
		"d'un liseré doré.", "", 2),
	("INT_SS_ANNE_RESTAURANT_COQUE", "ss_anne_restaurant", None,
		[COQUE_PP, "REF_PP_MUR.png", "REF_PP_TAPIS.png"],
		"la SALLE À MANGER du S.S. Anne : MÊMES matériaux et MÊME main que la coque jointe du hall "
		"INT_SS_ANNE_PONT_PRINCIPAL_COQUE (mur crème, lambris d'acajou, hublots ronds, appliques), plus "
		"festive : moulures dorées au mur, deux miroirs ovales encadrés d'or (sans reflet de personnage) ; "
		"sol de MOQUETTE bordeaux à fins motifs dorés réguliers. Au-dessus des 12e à 15e colonnes de la "
		"3e rangée, le mur du fond s'ouvre en PASSE-PLAT : une large ouverture rectangulaire où l'on "
		"devine une cuisine d'inox et de carrelage blanc (décor, on n'y entre pas).", "", 2),
	("INT_SS_ANNE_PONT_INFERIEUR_COQUE", "ss_anne_pont_inferieur", None,
		[COQUE_PP, COQUE_LABO],
		"le PONT INFÉRIEUR du S.S. Anne : quartiers de l'équipage et réserves, plus simple et plus "
		"fonctionnel que le hall joint INT_SS_ANNE_PONT_PRINCIPAL_COQUE (même main, même angle) : murs de "
		"TÔLE peinte vert d'eau clair, rivetés, soubassement plus foncé, tuyaux de cuivre et de fer qui "
		"courent le long du haut du mur, deux hublots ronds, une grosse applique grillagée ; épaisseur "
		"des murs en tôle grise ; sol de PLANCHES de bois brut plus sombres et usées ; la porte est une "
		"porte de tôle à hublot et à loquet. Propre, solide, accueillant malgré la simplicité.",
		"Contre le mur du fond, EXACTEMENT sur les 3e et 4e colonnes de la 3e rangée, un ESCALIER de bois "
		"raide de 2 cases de large qui MONTE et disparaît dans le mur du fond (vers le pont principal), "
		"avec une main courante de corde de chaque côté.", 2),
	("INT_SS_ANNE_CABINE_COQUE", "ss_anne_cabine_a", None,
		[COQUE_PP, "REF_PP_MUR.png", COQUE_LEO],
		"une CABINE DE PASSAGERS du S.S. Anne (la même pour les cabines A, B et C) : MÊMES matériaux et "
		"MÊME main que la coque jointe du hall INT_SS_ANNE_PONT_PRINCIPAL_COQUE, plus intime : papier "
		"peint crème à fines rayures bleu ciel au-dessus d'un lambris d'acajou clair, un hublot rond au-dessus "
		"des 3e et 4e colonnes et un autre au-dessus des 9e et 10e colonnes, une applique de "
		"laiton entre les deux ; moquette BLEU MARINE unie.", "", 2),
	("INT_ARENE_CARMIN_COQUE", "carmin_arene", None,
		["REF_AC_SALLE.png", "REF_AC_MUR.png", "REF_AC_SOL.png", COQUE_ARENE_AZ, ARENE_CARMIN],
		"l'ARÈNE DE CARMIN-SUR-MER, la salle technique d'un Champion de type Électrik, RECALÉE sur la vue "
		"d'ensemble validée jointe REF_AC_SALLE (la reproduire fidèlement, en plus net) MAIS SANS ses "
		"poubelles, SANS la rangée d'armoires électriques, SANS la barrière lumineuse (posées à part : à "
		"leur place le sol de plaques continue) et SANS lueur bleue : le MUR DU FOND est couvert de "
		"TABLEAUX ÉLECTRIQUES, armoires murales, cadrans, interrupteurs et faisceaux de tuyaux et de câbles "
		"gris acier (comme dans la vue), les TUBES LUMINEUX du mur sont peints éteints-neutres (blanc "
		"bleuté pâle, sans halo) ; murs latéraux de tôle rivetée gris-bleu avec des grilles d'aération ; "
		"sol de grandes PLAQUES DE MÉTAL gris-bleu clair rivetées (une plaque par case), une bande de "
		"danger jaune et noir le long du pied des murs. La ZONE DU CHAMPION au nord fait 3 rangées de "
		"profondeur (de la 3e à la 5e rangée : ATTENTION, plus profonde que dans la vue, qui n'en peint "
		"que 2). Martial, propre, technique, jamais inquiétant.", "", 1),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("INT_SS_ANNE_PLANCHE_A", ["REF_PP_BANQUETTE", "REF_PP_COMPTOIR"],
		"PLANCHE de 6 MEUBLES du paquebot S.S. Anne (hall, restaurant, cabines) dans une image 1536 × 1024 : "
		"grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un meuble par cellule, centré, "
		"la base de chacun sur une même ligne horizontale à 30 px du bas de sa cellule, à une échelle "
		"COMMUNE de 1 case = 120 px. Vue de dessus en trois quarts : on voit le dessus et la face avant, "
		"jamais les côtés. Matières communes : ACAJOU verni, LAITON, velours bordeaux, linge blanc.\n"
		"1 (ligne 1, à gauche) : BANQUETTE du hall, un canapé à deux places de VELOURS ROUGE bordeaux "
		"capitonné, cadre et accoudoirs de bois et de laiton (comme dans la référence) ; 2 cases de large "
		"(≈ 240 px), 1 de profondeur. 2 (ligne 1, au milieu) : COMPTOIR D'ACCUEIL du hall, long comptoir "
		"d'acajou à panneaux, bandeau et pieds de laiton, une petite CLOCHETTE de laiton et un registre "
		"fermé bleu nuit posés dessus ; 4 cases de large (≈ 480 px), 1 de profondeur. 3 (ligne 1, à "
		"droite) : TABLE DE RESTAURANT nappée de BLANC, deux chaises d'acajou à assise bordeaux (une à "
		"gauche, une à droite), deux couverts, un petit vase de fleurs ; 2 cases (≈ 240 px), 1 de "
		"profondeur.\n"
		"4 (ligne 2, à gauche) : COMPTOIR DE LA CUISINE (passe-plat du restaurant), comptoir d'inox et "
		"d'acajou, une cloche de service en métal, des piles d'assiettes blanches ; 4 cases (≈ 480 px), 1 "
		"de profondeur. 5 (ligne 2, au milieu) : LIT DE CABINE, cadre d'acajou, couvre-lit BLEU MARINE à "
		"liseré blanc, deux oreillers blancs unis ; 2 cases de large (≈ 240 px), 2 de long. 6 (ligne 2, à "
		"droite) : ARMOIRE DE CABINE, haute armoire d'acajou à deux portes, poignées de laiton ; 1 case "
		"de large (≈ 120 px), environ 1,8 de haut.\n"
		"Même rendu que les meubles joints (même main, même angle) ; fond avec une vraie transparence (canal "
		"alpha), aucun sol, aucun tapis, aucune ombre portée.",
		[COMPTOIR, CANAPE, LIT], LUMIERE_NE, 1),
	("INT_SS_ANNE_PLANCHE_B", [],
		"PLANCHE de 6 MEUBLES du paquebot S.S. Anne (cabines, cabine du capitaine, pont inférieur) dans une "
		"image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un élément "
		"par cellule, centré, la base de chacun sur une même ligne horizontale à 30 px du bas de sa "
		"cellule, à une échelle COMMUNE de 1 case = 120 px. Vue de dessus en trois quarts. Même main et "
		"mêmes matières que la planche jointe INT_SS_ANNE_PLANCHE_A (acajou, laiton).\n"
		"1 (ligne 1, à gauche) : TABLE SOUS LE HUBLOT, petite table d'acajou rectangulaire, deux tasses et "
		"une théière blanches, une chaise ; 2 cases (≈ 240 px), 1 de profondeur. 2 (ligne 1, au milieu) : "
		"BUREAU DU CAPITAINE, grand bureau d'acajou à tiroirs, une longue-vue de laiton, un compas de "
		"marine, un livre de bord fermé, une lampe de laiton à abat-jour vert ; 3 cases (≈ 360 px), 1 de "
		"profondeur. 3 (ligne 1, à droite) : LAVABO DE CABINE, petit lavabo de porcelaine blanche sur "
		"meuble d'acajou, robinet de laiton, miroir rond cerclé de laiton au-dessus, une serviette ; 1 "
		"case de large (≈ 120 px), environ 1,8 de haut.\n"
		"4 (ligne 2, à gauche) : TABLE À CARTES, table d'acajou au plateau incliné couvert d'une CARTE "
		"MARINE (côtes et lignes de sonde, AUCUNE lettre), un compas à pointes, une règle ; 2 cases (≈ 240 "
		"px), 1 de profondeur. 5 (ligne 2, au milieu) : CAISSES DE LA CALE, une pile compacte de caisses "
		"de bois cerclées de fer, deux sacs de toile et un rouleau de corde ; 2 × 2 cases (≈ 240 px de "
		"large), environ 2,3 de haut. 6 (ligne 2, à droite) : GRANDE PILE DE LA CALE, même famille, plus "
		"large : caisses, deux tonneaux, une bâche nouée ; 3 × 2 cases (≈ 360 px), environ 2,3 de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[PLANCHE_A, LAVABO, CAISSES], LUMIERE_NE, 2),
	("INT_ARENE_CARMIN_PLANCHE", ["REF_AC_POUBELLE", "REF_AC_ARMOIRES", "REF_AC_BARRIERE"],
		"PLANCHE de 5 ÉLÉMENTS de l'Arène de Carmin (salle technique électrique) dans une image 1536 × 1024 : "
		"grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un élément par cellule, centré, "
		"la base de chacun sur une même ligne horizontale à 30 px du bas de sa cellule, à une échelle "
		"COMMUNE de 1 case = 150 px, tous vus de dessus en trois quarts. Matière : acier gris-bleu riveté, "
		"cuivre ; voyants et champ peints dans leur couleur propre, SANS halo autour.\n"
		"1 (ligne 1, à gauche) : POUBELLE MÉTALLIQUE, une poubelle cylindrique d'acier gris clair à "
		"couvercle bombé et poignée, cerclages fins (comme dans la référence) ; environ 0,75 case de large "
		"(≈ 110 px), 1 case de haut. Elle sera posée 15 fois, toutes IDENTIQUES : aucun détail qui la "
		"distingue, aucune étincelle, aucun voyant. 2 (ligne 1, au milieu) : ARMOIRE ÉLECTRIQUE A, un "
		"gros cube d'acier riveté gris-bleu, porte à grille d'aération, un voyant bleu ; 1 case de large "
		"(≈ 150 px), environ 1,5 de haut ; ses bords gauche et droit sont droits pour se raccorder bout à "
		"bout (une rangée de 5). 3 (ligne 1, à droite) : ARMOIRE ÉLECTRIQUE B, même gabarit, autre façade "
		"(deux cadrans, une manette), un faisceau de tuyaux de cuivre sur le côté.\n"
		"4 (ligne 2, à gauche) : BARRIÈRE ACTIVE, deux PYLÔNES cylindriques d'acier à bandes lumineuses "
		"bleu clair aux deux extrémités et, tendu entre eux, un CHAMP D'ÉNERGIE bleu ciel translucide à "
		"fines nervures (comme dans la référence), net, sans flou ni halo débordant ; 3 cases de large "
		"(≈ 450 px), environ 1,5 de haut. 5 (ligne 2, au milieu) : BARRIÈRE COUPÉE, les MÊMES pylônes, "
		"bandes éteintes grises, AUCUN champ entre eux (on voit à travers), un rail d'acier au sol entre "
		"les deux ; même taille. 6 (ligne 2, à droite) : VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[MACHINES, ARENE_CARMIN], LUMIERE_NE, 1),
	("WORLD_RELIEF_PONT_EXTERIEUR_PLANCHE", ["REF_PE_BASTINGAGE_N", "REF_PE_BASTINGAGE_S",
			"REF_PE_CHAISES", "REF_PE_BOUEE"],
		"PLANCHE de 8 ÉLÉMENTS du PONT PROMENADE du S.S. Anne (pont extérieur, la mer de chaque côté) "
		"dans une image 1536 × 1024 : grille invisible de 4 colonnes × 2 lignes (cellules de 384 × 512), "
		"un élément par cellule, centré, à une échelle COMMUNE de 1 case = 180 px, tous vus de dessus en "
		"trois quarts ; même main que le navire joint (coque blanche, bleu marine, teck). ANGLES DROITS : "
		"les bastingages se raccordent bout à bout avec leur semblable.\n"
		"1 (ligne 1, colonne 1) : BASTINGAGE NORD A, la mer est AU NORD (en haut) : la main courante de "
		"TECK vue de dessus sur des poteaux BLANCS, deux lisses blanches ; 2 cases de long × environ 0,9 "
		"de haut (≈ 360 × 160 px). 2 (ligne 1, colonne 2) : BASTINGAGE NORD B, même gabarit, un taquet "
		"d'amarrage de laiton en plus. 3 (ligne 1, colonne 3) : BASTINGAGE SUD avec le FLANC, la mer est "
		"AU SUD : la même main courante et ses poteaux, puis, sous le pont, le FLANC BLANC de la coque "
		"avec UN hublot rond cerclé de laiton et un liseré bleu marine en bas ; 2 cases × environ 1,6 "
		"(≈ 360 × 290 px). 4 (ligne 1, colonne 4) : BASTINGAGE EST, le bout du pont, la mer À DROITE : "
		"main courante de teck vue de dessus en bande verticale ; 0,35 case × 2 (≈ 65 × 360 px).\n"
		"5 (ligne 2, colonne 1) : ANGLE NORD-EST du bastingage (0,35 × 0,9 case). 6 (ligne 2, colonne 2) : "
		"ANGLE SUD-EST avec le flanc (0,35 × 1,6 case). 7 (ligne 2, colonne 3) : DEUX CHAISES LONGUES de "
		"teck côte à côte, orientées du haut vers le bas, coussins crème ; 2 cases de large × environ "
		"1,2 de long (≈ 360 × 215 px). 8 (ligne 2, colonne 4) : BOUÉE de sauvetage rouge et blanche "
		"accrochée à un petit support de bois ; 1 case (≈ 180 px).\n"
		"Fond avec une vraie transparence (canal alpha), AUCUNE mer, aucune écume, aucun plancher (le jeu "
		"les ajoute), aucune ombre portée, aucune mouette.",
		[NAVIRE], LUMIERE_NE, 1),
	("FX_COUPE_PLANCHE", [],
		"PLANCHE de 4 IMAGES d'un EFFET DE COUPE générique (le trait de lame d'un Pokémon qui tranche un "
		"arbuste), dans une image 1536 × 1024 : une seule LIGNE de 4 cellules de 384 × 512 dans la moitié "
		"HAUTE de l'image (y de 0 à 512), la moitié basse VIDE ; dans chaque cellule, l'effet centré, "
		"environ 300 px dans sa plus grande dimension (en jeu ≈ 2 cases : la taille de l'arbuste).\n"
		"1 : un TRAIT DE LAME fin qui naît en haut à gauche et descend en arc vers le bas à droite (moitié "
		"du geste). 2 : l'ARC COMPLET, croissant de lumière blanc pur au cœur, bordé de bleu ciel pâle, "
		"effilé aux deux bouts. 3 : un SECOND trait croisé (en X avec le premier qui s'amincit) et quelques "
		"FEUILLES vertes et brindilles qui jaillissent. 4 : les traits s'effacent en fines lignes, les "
		"feuilles retombent, plus clairsemées.\n"
		"Rendu peint de la série (contour fin coloré, aucun trait noir), formes nettes et lisibles, AUCUN "
		"flou, AUCUN halo diffus, aucune étincelle électrique, aucun Pokémon, aucun arbuste, aucun "
		"personnage. Fond avec une vraie transparence (canal alpha).",
		["WORLD_TREE_A_01_NE_r1.png"], LUMIERE_NE, 1),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée, description, ancres,
## valeurs, vague). Format portrait pour la superstructure (haute et étroite).
SERIE = [
	("WORLD_BLDG_SS_ANNE_SUPERSTRUCTURE_OUEST", "REF_PE_SUPERSTRUCTURE", "1,3", "7,5",
		"le BOUT OUEST DE LA SUPERSTRUCTURE du S.S. Anne qui ferme le pont promenade à gauche (comme dans "
		"la référence) : un bloc d'acier peint BLANC, haut et étroit, vu de dessus en trois quarts : son "
		"TOIT gris clair occupe la bande, et sur son bord DROIT (côté pont) on voit sa paroi blanche "
		"montrée de biais comme dans la référence, avec deux HUBLOTS ronds cerclés de laiton et une PORTE "
		"de bois verni à petit hublot rond dont le centre est à 2,5 cases au-dessus du bas du bloc. 1,3 "
		"case de large, environ 7,5 cases de haut. AUCUNE eau, aucun plancher autour, aucune lettre.",
		[NAVIRE], LUMIERE_NE, 1),
]
FORMATS = {"WORLD_BLDG_SS_ANNE_SUPERSTRUCTURE_OUEST": "Format : PNG PORTRAIT 1024 × 1536 ; le bloc "
	"occupe environ 1 400 px de haut, centré"}

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenues = défauts (règle 4).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_CAPITAINE", [], 128, "le capitaine du S.S. Anne",
		"le CAPITAINE du paquebot, un monsieur d'environ 60 ans, digne et bienveillant : courte BARBE "
		"BLANCHE soignée, cheveux blancs, teint un peu pâle ; VAREUSE de commandant BLEU MARINE à double "
		"rangée de boutons dorés, GALONS DORÉS aux manches, CASQUETTE blanche à visière noire ornée d'une "
		"simple ANCRE dorée, pantalon bleu marine, chaussures noires cirées. Taille d'un adulte. Différent "
		"du marin joint (ni col marin, ni bachi) et du vieil homme joint ; aucun texte.",
		f"{PIEDS_JOINTS}, les mains croisées dans le dos, l'air digne", [MARIN, VIEIL_HOMME], 1),
	("PNJ_MAJOR_BOB", [], 128, "Major Bob, Champion de l'Arène de Carmin, le Soldat de la Foudre",
		"MAJOR BOB, Champion de type Électrik surnommé « le Soldat de la Foudre », un ancien militaire "
		"d'environ 35 ans, GRAND et très CARRÉ (nettement plus large qu'un adulte ordinaire, même "
		"échelle de chibi), sourire assuré : cheveux BLONDS en brosse courte, mâchoire carrée ; DÉBARDEUR "
		"VERT OLIVE, PANTALON TREILLIS kaki à poches, gros CEINTURON, RANGERS noires lacées, une plaque "
		"d'identité sans inscription au cou, un petit éclair jaune cousu sur l'épaule (un éclair, jamais "
		"un cercle). Différent du héros, de Pierre et du guide d'Arène joints ; aucun texte.",
		f"{PIEDS_JOINTS}, les bras croisés sur la poitrine, le menton levé, l'air sûr de lui",
		[PIERRE, GUIDE], 1),
	("PNJ_GENTLEMAN", [], 128, "un Gentleman, Dresseur passager du S.S. Anne",
		"un GENTLEMAN d'environ 55 ans, distingué et courtois : MOUSTACHE GRISE soignée, cheveux gris "
		"plaqués ; CHAPEAU MELON noir, COSTUME TROIS PIÈCES GRIS ANTHRACITE, gilet, chemise blanche, "
		"cravate lavallière bleu nuit, une CANNE noire à pommeau d'argent, chaussures vernies. Plus mince "
		"que le président du Fan Club joint (ni bordeaux, ni rondeur, ni lunettes) ; différent du vieil "
		"homme joint ; aucun texte.",
		f"{PIEDS_JOINTS}, les deux mains posées sur le pommeau de sa canne devant lui",
		[PRESIDENT, VIEIL_HOMME], 1),
	("PNJ_ROCKEUR", [], 128, "un Rockeur, Dresseur de l'Arène de Carmin",
		"un ROCKEUR d'environ 25 ans, énergique : cheveux noirs coiffés en BANANE, petites lunettes "
		"noires ; VESTE DE CUIR NOIRE aux épaules ornées de petits ÉCLAIRS jaunes (motif, aucun texte), "
		"t-shirt rouge, jean bleu, bottes noires, une GUITARE ÉLECTRIQUE rouge en bandoulière (sans logo). "
		"Taille d'un adulte, mince. Différent du héros et du rival ; aucun texte.",
		f"{PIEDS_JOINTS}, une main sur le manche de sa guitare, l'autre levée, l'air enjoué", [GUIDE], 1),
	("PNJ_HOTESSE", [], 128, "l'hôtesse d'accueil du S.S. Anne",
		"l'HÔTESSE D'ACCUEIL du paquebot, une jeune femme d'environ 30 ans, souriante et posée : CHIGNON "
		"brun ; TAILLEUR BLEU MARINE ajusté à boutons dorés, FOULARD rouge et blanc noué au cou, petit "
		"CALOT bleu marine, jupe droite au genou, chaussures bleu marine à petit talon. Même uniforme de "
		"compagnie que le marin joint (bleu marine, rouge, blanc), mais d'hôtesse ; différente de "
		"l'infirmière et de la Dresseuse ; aucun badge lisible, aucun texte.",
		f"{PIEDS_JOINTS}, les mains jointes devant elle, l'air accueillant", [MARIN], 1),
	("PNJ_PASSAGERE", [], 128, "une passagère du S.S. Anne en croisière",
		"une PASSAGÈRE en croisière, une dame d'environ 40 ans, élégante et détendue : cheveux châtains "
		"ondulés aux épaules, GRAND CHAPEAU DE PAILLE à ruban bleu ciel, lunettes de soleil relevées sur le "
		"chapeau ; ROBE D'ÉTÉ légère JAUNE PÂLE à petites fleurs blanches, ceinture fine, sandales "
		"blanches, un petit sac de paille au bras. Taille d'une adulte. Différente de la randonneuse, de la "
		"Dresseuse et de l'hôtesse ; aucun texte.",
		f"{PIEDS_JOINTS}, une main tenant le bord de son chapeau, l'air rêveur", [], 1),
]
## Conditionnels : même format (jamais lancés sans leur nom).
PERSONNAGES_COND = [
	("PNJ_CUISINIER", [], 128, "le cuisinier du restaurant du S.S. Anne",
		"un CUISINIER de paquebot d'environ 45 ans, rond et jovial, rasé de près : haute TOQUE blanche, "
		"VESTE DE CHEF blanche croisée, petit foulard rouge, long tablier blanc, pantalon pied-de-poule "
		"noir et blanc, une louche à la main. Différent du marchand joint (ni moustache, ni tablier bleu) ; "
		"aucun texte.", f"{PIEDS_JOINTS}, la louche levée, l'air fier de sa cuisine", [MARCHAND], 1),
]

## Pose « malade » du capitaine (dossier 19 §6 : penché sur son lavabo, animation courte).
CAPITAINE_MALADE = ("CAPITAINE_MALADE",
	"CAPITAINE_MALADE — POSES SPÉCIALES du même personnage que la planche jointe PNJ_CAPITAINE_NE_r1 "
	"(sa planche de marche 4 × 4) : le capitaine du S.S. Anne, qui a le mal de mer. Même main peinte, "
	"mêmes couleurs, mêmes proportions, même visage, même barbe, même uniforme, même taille.\n"
	"Style : illustration 2D peinte numériquement, contour fin et doux d'une teinte sombre et colorée, "
	"aucun trait noir, trois valeurs nettes par matériau, légère granularité de pinceau, lumière neutre "
	"de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche, aucune teinte dorée. "
	"Formes simplifiées et lisibles pour rester net une fois réduit à environ 128 px de haut.\n"
	"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
	"dessiné). UNE seule ligne de poses, de gauche à droite, chaque pose dans une colonne invisible de "
	"384 px, le personnage entier, à la même taille que dans la planche jointe (environ 280 px de haut "
	"debout), le bas des poses sur une même ligne horizontale. Pas de sol, pas d'ombre, pas de lavabo, "
	"pas de texte.\n"
	"- Pose 1 : vu de DOS, PENCHÉ EN AVANT, les deux mains appuyées devant lui comme sur un lavabo "
	"(invisible), la tête basse, les épaules affaissées.\n"
	"- Pose 2 : la même pose de dos, les épaules un peu plus hautes (il respire : 2e image d'une "
	"animation lente avec la pose 1).\n"
	"- Pose 3 : vu de FACE, redressé mais encore pâle, une main sur le ventre, un sourire fatigué et "
	"reconnaissant.\n"
	"- Colonne 4 : VIDE.\n" + INTERDITS + "\n")

## Planche d'icônes du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE : 4 colonnes).
UI = ("UI_OBJETS_J16_PLANCHE",
	"PLANCHE de DEUX icônes d'objets peintes pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : une icône CENTRÉE dans chacune des DEUX PREMIÈRES colonnes (x de 0 à "
	"384, puis de 384 à 768), chacune de 260 px de large au plus et 260 px de haut au plus, avec au moins "
	"60 px de marge vide de chaque côté ; les deux dernières colonnes restent VIDES (transparentes) ; "
	"dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE et de l'icône jointe de l'Antidote "
	"(même rendu, même angle de trois quarts, même lumière).\n"
	"1 (colonne 1) : l'ANTI-PARA, le MÊME flacon vaporisateur que l'Antidote joint (même forme, même "
	"taille, même gâchette) mais au corps JAUNE CITRON, gâchette et bouchon blancs.\n"
	"2 (colonne 2) : le RÉVEIL, le même flacon vaporisateur au corps BLEU CIEL, gâchette et bouchon "
	"blancs.\n"
	"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec "
	"seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).",
	[MENU_OBJETS, "assets/ui/items/antidote.webp"], 1)

## Textures conditionnelles : (identifiant, référence, description, ancres, valeurs).
SOLS_COND = [
	("WORLD_GROUND_PONT_TECK_01", "REF_PE_TECK",
		"texture du PONT DE TECK du paquebot, vue strictement de dessus : longues lattes de TECK miel "
		"clair posées HORIZONTALEMENT (de gauche à droite), 4 lattes par case (1 case = 256 px sur cette "
		"texture), fins JOINTS de calfatage brun sombre réguliers, extrémités décalées, très légères nuances "
		"d'une latte à l'autre ; propre, lisse, bien entretenu ; aucun clou visible, aucune corde, aucune "
		"flaque, aucun élément remarquable.",
		[QUAI], "Valeurs : bois clair et chaud, lumière neutre, aucune ombre portée ; contraste doux."),
]

## Décors de combat (chaîne CB.3, tools/art/combat_decors/) : (identifiant, vue jointe, lieu,
## composition du fond, lumière, interdits propres).
_DECOR_BASE = (
	"DÉCOR DE COMBAT — {titre} (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat "
	"Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.\n\n"
	"Images jointes.\n"
	"IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement "
	"plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité de "
	"peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le coucher "
	"de soleil orange.\n"
	"IMAGE 2 : une planche d'intention de décors de combat (guide de facture).\n"
	"IMAGE 3 : {image3}\n{interieur}\n"
	"FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution "
	"possible, OPAQUE, cadrage plein, sans bord.\n\n"
	"LIEU : {lieu}\n\n"
	"COMPOSITION (fractions depuis le coin haut gauche) :\n{fond}\n"
	"- Point A (x 67 %, y 58 %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien de "
	"haut dans un rayon de 12 % de la largeur autour.\n"
	"- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier plan. "
	"Rien de haut autour.\n"
	"- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de "
	"détails et peu de contraste, valeurs simples.\n"
	"- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol "
	"simple, presque sans objet, valeurs moyennes, sans contraste fort.\n"
	"- Les deux coins du bas restent du SOL nu : pas de meuble ni de gros objet en gros plan.\n"
	"- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur "
	"certains écrans).\n\n"
	"LUMIÈRE : {lumiere}\n\n"
	"RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D "
	"peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni "
	"en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches "
	"sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à "
	"hauteur d'yeux, un peu plongeante, le sol recule nettement vers le fond.\n\n"
	"INTERDITS : Pokémon, animal, oiseau, mouette, personnage, silhouette, texte, lettres, chiffres, "
	"panneau lisible, logo, nom de navire, signature, filigrane, cadre, interface, pixel art, flou, "
	"vignettage{interdits}.\n")
_INTERIEUR = "Ce décor est INTÉRIEUR : au lieu de l'horizon d'un paysage, un fond de salle.\n"
DECORS = [
	("COMBAT_DECOR_SS_ANNE_SALON_r1", "docs/design/reference/ss-anne-pont-principal-v1.png",
		"S.S. ANNE, SALON DU PAQUEBOT", "la vue d'ensemble (de dessus) du hall du S.S. Anne : lambris "
		"d'acajou, mur crème, hublots de laiton, parquet miel, tapis bordeaux (guide de palette et de "
		"matières).", _INTERIEUR,
		"le grand salon d'un paquebot de croisière élégant : au fond, un mur crème au-dessus d'un haut "
		"lambris d'acajou, une rangée de HUBLOTS RONDS cerclés de laiton qui montrent la mer bleue, des "
		"appliques de laiton allumées, une porte de bois verni à hublot ; un PARQUET de bois miel ciré et "
		"un grand TAPIS bordeaux à bordure dorée au sol. Combats du pont principal, du restaurant, du pont "
		"inférieur, des cabines et du couloir.",
		"- Le haut (0 à 40 %) : le mur du fond, calme, base du mur vers 40 % de la hauteur ; hublots et "
		"appliques réguliers, pas de meuble devant.\n"
		"- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de parquet, le tapis bordeaux au "
		"centre, très lisible.",
		"intérieur chaleureux : appliques de laiton dorées, lumière du jour bleutée et douce par les "
		"hublots, reflets légers sur le parquet ciré, ombres douces ; jamais sombre.",
		", meuble encombrant, lustre, table, chaise"),
	("COMBAT_DECOR_SS_ANNE_PONT_r1", "docs/design/reference/ss-anne-pont-exterieur-v1.png",
		"S.S. ANNE, PONT PROMENADE EN MER", "la vue d'ensemble (de dessus) du pont promenade du S.S. Anne : "
		"pont de teck clair, bastingage blanc à main courante de teck, mer bleu profond scintillante "
		"(guide de palette ; ses mouettes ne sont PAS à reprendre).", "",
		"le pont promenade d'un paquebot en pleine mer : un large PONT DE TECK clair au premier plan, le "
		"BASTINGAGE blanc à main courante de teck qui court en travers au fond, une bouée rouge et blanche "
		"accrochée, et derrière la MER bleu profond scintillante jusqu'à l'horizon, un ciel clair aux "
		"nuages légers.",
		"- Horizon de la mer vers 33 % de la hauteur ; le bastingage traverse l'image de 34 à 42 % de la "
		"hauteur, plus bas que l'horizon.\n"
		"- De 45 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de lattes de teck qui fuient vers "
		"le fond.",
		"golden hour, soleil bas venant du haut à gauche (hors cadre), lumière dorée chaude sur le teck et "
		"le bastingage, éclats dorés sur la mer, ombres douces ; ciel bleu pâle voilé, nuages teintés de "
		"rose doré, pas de soleil visible, pas de contre-jour.",
		", terre, côte, île, autre bateau, voile, cheminée, chaise longue en gros plan"),
	("COMBAT_DECOR_GYM_CARMIN_r1", "docs/design/reference/arene-carmin-v1.png",
		"ARÈNE DE CARMIN-SUR-MER, SALLE ÉLECTRIQUE", "la vue d'ensemble (de dessus) de l'Arène de Carmin : "
		"tableaux électriques, tuyaux, plaques de métal rivetées, tubes lumineux bleus (guide de palette "
		"et de matières).", _INTERIEUR,
		"la salle technique de l'Arène d'un Champion de type Électrik : au fond, un mur couvert de "
		"TABLEAUX ÉLECTRIQUES gris acier, de cadrans, de câbles et de tuyaux, des TUBES LUMINEUX bleu "
		"froid ; au sol, de grandes PLAQUES DE MÉTAL gris-bleu rivetées et une bande de danger jaune et "
		"noir au pied du mur.",
		"- Le haut (0 à 40 %) : le mur technique du fond, base du mur vers 40 % de la hauteur, calme en "
		"haut à gauche (grands panneaux unis).\n"
		"- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de plaques de métal, très lisible.",
		"intérieur électrique : lumière blanc bleuté des tubes, reflets nets sur les plaques de métal, "
		"quelques voyants bleus et ambre, ombres douces ; ambiance énergique et martiale, jamais sombre ni "
		"inquiétante.",
		", éclair dessiné dans l'air, étincelles, foudre, barrière d'énergie, poubelle, machine en gros "
		"plan"),
]

## Corrections (T2) : (identifiant sans _NE_rN, révision) → texte qui remplace la description
## d'origine. T2 : la description d'origine suivie d'une phrase qui corrige l'essai précédent (joint).
def _corriger(ident: str, phrase: str) -> str:
	return next(t[4] for t in COQUES if t[0] == ident) + " " + phrase


CORRECTIONS: dict[tuple[str, int], str] = {
	("INT_SS_ANNE_PONT_PRINCIPAL_COQUE", 2): _corriger("INT_SS_ANNE_PONT_PRINCIPAL_COQUE",
		"CORRECTION de l'essai précédent (joint en premier) : sa porte du MILIEU était décalée d'une case et "
		"demie vers la droite. Les trois portes du mur du fond sont CENTRÉES sur x = 325, x = 680 et "
		"x = 1212 (de gauche à droite), chacune large d'une case (≈ 59 px) ; la porte du milieu est donc "
		"nettement plus à GAUCHE que le milieu de l'image (x = 768). Le reste de l'essai précédent est bon : "
		"le conserver à l'identique."),
	("INT_SS_ANNE_RESTAURANT_COQUE", 2): _corriger("INT_SS_ANNE_RESTAURANT_COQUE",
		"CORRECTION de l'essai précédent (joint en premier) : sa porte du mur de DROITE était trop haute. "
		"Elle doit se trouver dans l'épaisseur du mur de droite, centrée sur y = 605 (de y = 559 à y = 652), "
		"dans la moitié BASSE de la pièce, bien visible, et non au milieu de la hauteur. Le reste de l'essai "
		"précédent est bon : le conserver à l'identique."),
}

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées du "
		"S.S. Anne et de l'Arène de Carmin (petites, lumière d'ambiance : n'en copie ni le rendu ni la "
		"lumière) ; ")


def _prompt_texture(identifiant: str, ref: str, description: str, ancres: list[str],
		valeurs: str) -> str:
	jointes = (f"Images jointes : {ref} = matériau et couleurs, extrait d'une vue d'ensemble validée "
		f"(petit : n'en copie pas le rendu) ; {_noms(STYLE + ancres)} = ancres de style (rendu peint, "
		"finesse, lumière neutre).")
	return (f"{identifiant} — NOUVELLE image : une texture de sol de jeu, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\nASSET : {description}\n{TEXTURE_FIN}\n{INTERDITS}\n")


def _prompt_objet(identifiant: str, ref: str | None, largeur, hauteur, description: str,
		ancres: list[str], valeurs: str) -> str:
	jointes = "Images jointes : "
	if ref:
		jointes += (f"{ref} = référence de forme, de matériaux et de couleurs, extraite d'une vue "
			"d'ensemble validée (petite : n'en copie pas le rendu) : dessine l'élément comme s'il avait été "
			"extrait de cette image puis agrandi, avec le même angle, mais avec la finesse des ancres. ")
	jointes += (f"{_noms(STYLE + ancres)} = ancres de style de la série (rendu peint, contour coloré, "
		"finesse, même angle de vue, même lumière neutre).")
	format_ = FORMATS.get(identifiant, "Format : PNG paysage 1536 × 1024 ; l'élément occupe environ "
		"1 300 px dans sa plus grande dimension, centré")
	corps = (f"ASSET : {description}\n{format_}. Échelle : {largeur} cases de large et environ {hauteur} "
		f"de haut ; un adulte mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\n{corps}\n")


def _prompt_planche(identifiant: str, refs: list[str], description: str, ancres: list[str],
		valeurs: str) -> str:
	ancres_ = f"{_noms(ancres)} = ancres de style (rendu peint, contour coloré, finesse, angle de vue, " \
		"lumière neutre) : respecte-les exactement." if ancres else "Aucune ancre : suis l'ADN ci-dessous."
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages "
		f"jointes : {_jointes_refs(refs)}{ancres_}\n\n{ADN}\n{valeurs}\n\n"
		"EXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une même planche, chacun "
		f"entier dans sa cellule, sans cadre ni séparation.\n{description}\n{INTERDITS}\n")


def _prompt_coque(identifiant: str, grille: str, cadre, ancres: list[str], materiaux: str,
		particulier: str) -> str:
	format_ = ("Format : PNG paysage 1536 × 1024, opaque." if cadre else "Format : PNG paysage 1536 × "
		"1024, opaque ; la pièce remplit TOUT le cadre.")
	escalier = "" if "ESCALIER" in particulier else ", marche ou escalier"
	return (f"{identifiant} — NOUVELLE image : l'enveloppe d'une pièce intérieure de jeu (murs, sol, "
		f"portes, hublots ; aucun meuble).\nImages jointes : {_noms(ancres)} = composition, matériaux "
		"(vues d'ensemble validées et coques déjà produites) et ancres de style des intérieurs (rendu "
		"peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre) : "
		f"respecte-les exactement.\n\n{ADN}\n{LUMIERE_INT}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		f"trois quarts, image opaque.\n{format_} {particulier}\n"
		f"Géométrie (tirée de la grille de jeu `tools/plans/{grille}.txt`, respecte-la EXACTEMENT : c'est "
		f"un plan de jeu) : {_BASE_COQUE} {geometrie(grille, cadre)}\n"
		f"Pièce : {materiaux}\n"
		"Interdit : meubles, banquettes, tables, lits, comptoirs, plantes, caisses, poubelles, machines "
		f"posées au sol, personnages, Pokémon (ni Pikachu){escalier} non demandés, flaques ou faisceaux de "
		"lumière peints au sol, halo, texte, lettres, chiffres, logo, emblème rond de type balle, "
		"perspective avec point de fuite, vue isométrique, ombre portée.\n")


def _prompt_marche(identifiant: str, refs: list[str], tenue: str, ancres: list[str]) -> str:
	texte = ""
	if refs:
		texte += (f" ; {', '.join(refs)} = tenue et silhouette seulement (petites, extraites des vues "
			"d'ensemble, rendu à NE PAS copier)")
	if ancres:
		texte += (f" ; {_noms(ancres)} = même main et même finesse pour un adulte (à NE PAS copier : "
			"autre visage, autre tenue)")
	return MODELE_MARCHE.format(ident=identifiant, ref=texte, tenue=tenue) + INTERDITS + "\n"


def _prompt_attente(identifiant: str, role: str, hauteur: int, tenue: str, pose: str) -> str:
	"""Modèle des attentes des séries 10–17."""
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


def _prompt_decor(titre: str, image3: str, interieur: str, lieu: str, fond: str, lumiere: str,
		interdits: str) -> str:
	return _DECOR_BASE.format(titre=titre, image3=image3, interieur=interieur, lieu=lieu, fond=fond,
		lumiere=lumiere, interdits=interdits)


def _images() -> list[dict]:
	"""Toutes les images de la série : nom (sans .png), fichier de prompt, texte, jointes (noms dans
	$ART, ou chemins relatifs à la racine quand ils contiennent « / »), vague, conditionnel, groupe."""
	images = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, grille, cadre, ancres_, materiaux, particulier, vague in COQUES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, grille, cadre, ancres_, materiaux,
			particulier), list(ancres_), vague, groupe=ident)
	for ident, refs, description, ancres_, valeurs, vague in PLANCHES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_, valeurs),
			[f"{r}.png" for r in refs] + ancres_, vague, groupe=ident)
	for ident, ref, largeur, hauteur, description, ancres_, valeurs, vague in SERIE:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
			ancres_, valeurs), [f"{ref}.png"] + STYLE + ancres_, vague, groupe=ident)
	for liste, conditionnel in ((PERSONNAGES, False), (PERSONNAGES_COND, True)):
		for ident, refs, hauteur, role, tenue, pose, ancres_, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres_),
				[HEROS] + [f"{r}.png" for r in refs] + ancres_, vague, conditionnel, groupe=ident)
			court = ident.removeprefix("PNJ_")
			ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
				_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1, conditionnel,
				groupe=ident)
	ident, texte = CAPITAINE_MALADE
	ajouter(f"{ident}_r1", ATTENTES / f"{ident}.txt", texte, ["PNJ_CAPITAINE_NE_r1.png"], 2,
		groupe="PNJ_CAPITAINE")
	ident, description, ancres_, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres_), vague, groupe=ident)
	for ident, ref, description, ancres_, valeurs in SOLS_COND:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres_, valeurs),
			[f"{ref}.png"] + STYLE + ancres_, 2, True, groupe=ident)
	for ident, vue, titre, image3, interieur, lieu, fond, lumiere, interdits in DECORS:
		ajouter(ident, DECORS_COMBAT / f"{ident}.txt", _prompt_decor(titre, image3, interieur, lieu, fond,
			lumiere, interdits), ["docs/design/reference/combat-v1.webp",
			"docs/design/reference/combat-decors-planche-v1.webp", vue], 1, groupe=ident.rsplit("_", 1)[0])
	for (ident, rev), description in CORRECTIONS.items():
		nom = f"{ident}_NE_r{rev}"
		groupe = f"{ident}_r{rev}"
		precedent = f"{ident}_NE_r{rev - 1}.png"
		base = next((t for t in PLANCHES if t[0] == ident), None)
		if base is not None:
			_, refs, _, ancres_, valeurs, _ = base
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description,
				[precedent] + ancres_, valeurs), [f"{r}.png" for r in refs] + [precedent] + ancres_, 3,
				True, groupe=groupe)
			continue
		coque = next((t for t in COQUES if t[0] == ident), None)
		if coque is not None:
			_, grille, cadre, ancres_, _, particulier, _ = coque
			ancres_ = ancres_[:4]  # Codex : 5 images jointes au plus
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, grille, cadre, [precedent] + ancres_,
				description, particulier), [precedent] + ancres_, 3, True, groupe=groupe)
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
	print(f"{len(REFS)} références REF_PP_*, REF_PE_*, REF_AC_* dans {ART}")


def _octets_prepare(relatif: str) -> bytes | None:
	"""Asset préparé : dans cette copie, sinon dans `BRANCHE_J15` (git show), sinon None."""
	if (RACINE / relatif).exists():
		return (RACINE / relatif).read_bytes()
	resultat = subprocess.run(["git", "show", f"{BRANCHE_J15}:{relatif}"], cwd=RACINE,
		capture_output=True)
	return resultat.stdout if resultat.returncode == 0 else None


def _image_preparee(relatif: str) -> Image.Image | None:
	octets = _octets_prepare(relatif)
	return Image.open(BytesIO(octets)).convert("RGBA") if octets else None


def _jointes_art() -> set[str]:
	generees = {i["nom"] + ".png" for i in _images()}
	return {j for i in _images() for j in i["jointes"]
		if "/" not in j and not j.startswith("REF_") and j not in generees}


def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	manquantes, preparees = [], []
	sources = _sources_ancres()
	for nom in sorted(set(ANCRES) | _jointes_art()):
		if (ART / nom).exists():
			continue
		source = next((s / nom for s in sources if (s / nom).exists()), None)
		if source is not None:
			if source.resolve() != (ART / nom).resolve():
				shutil.copy2(source, ART / nom)
			continue
		image = _image_preparee(PREPARES[nom]) if nom in PREPARES else None
		if image is None:
			manquantes.append(nom)
		else:
			image.save(ART / nom)
			preparees.append(nom)
	print("ancres copiées" + (f" ; depuis les assets préparés : {', '.join(preparees)}" if preparees
		else "") + (f" ; ABSENTES : {', '.join(manquantes)}" if manquantes else ""))


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
	if len(jointes) > 5:  # Codex refuse plus de 5 images jointes
		return f"{image['nom']} : ÉCHEC, {len(jointes)} images jointes (5 au plus)"
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


# --- Manifeste (T10) --------------------------------------------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"


def _revision(base: str) -> str:
	"""Dernière révision présente dans $ART pour `base` (sans `_rN.png`), `_r1` par défaut."""
	for rev in (4, 3, 2, 1):
		if (ART / f"{base}_r{rev}.png").exists():
			return f"{base}_r{rev}.png"
	return f"{base}_r1.png"


def _planche_objets(base: str, dossier: str, colonnes: int, lignes: int, ids: list[str],
		cases: list[float], contact: float | None, boites: list[list[int]] | None = None,
		nettoyer: bool = True) -> dict:
	"""Planche d'objets ; `nettoyer` (T10, défaut) : halo lumineux du fond retiré (comme la
	série 17), constaté sur les quatre planches de la série au T2."""
	entree = {"source": _revision(base), "dossier": f"{_W}{dossier}/", "colonnes": colonnes,
		"lignes": lignes, "ids": ids, "cases": cases, "contact": contact}
	if nettoyer:
		entree["nettoyer"] = True
	if boites:
		entree["boites"] = boites
	return entree


## Ordre de lecture des planches (fiche, §« Alignement »).
SS_ANNE_A_IDS = ["int_banquette_ss_anne_01", "int_comptoir_accueil_ss_anne_01",
	"int_table_restaurant_01", "int_comptoir_cuisine_01", "int_lit_cabine_01", "int_armoire_cabine_01"]
SS_ANNE_B_IDS = ["int_table_hublot_01", "int_bureau_capitaine_01", "int_lavabo_cabine_01",
	"int_table_cartes_01", "int_caisses_cale_01", "int_caisses_cale_02"]
ARENE_IDS = ["int_poubelle_arene_01", "int_armoire_electrique_01", "int_armoire_electrique_02",
	"int_barriere_active_01", "int_barriere_coupee_01"]
PONT_EXT_IDS = ["relief_bastingage_01", "relief_bastingage_02", "relief_bastingage_sud_01",
	"relief_bastingage_est_01", "relief_bastingage_angle_ne_01", "relief_bastingage_angle_se_01",
	"prop_chaises_longues_01", "prop_bouee_01"]
FX_IDS = ["fx_coupe_01", "fx_coupe_02", "fx_coupe_03", "fx_coupe_04"]
## Boîtes de la planche du pont extérieur (pixels de `_r1`, relevées au T10 sur les taches après
## `nettoyer`) : bastingages N ×2, S, E ; angles NE, SE ; paire de chaises longues ; bouée.
BOITES_PONT_EXT = [[40, 200, 484, 392], [500, 190, 940, 392], [956, 140, 1380, 436],
	[1424, 104, 1492, 440], [88, 540, 236, 790], [344, 516, 488, 888], [628, 516, 1092, 908],
	[1204, 580, 1472, 856]]
## Retouches des coques à la préparation (T10, défauts notés au T2), en pixels du jeu de la coque
## à sa taille (`preparer.retoucher_coque`), relevées sur les révisions retenues :
## - cabines A/B/C et cabine du capitaine : sortie peinte d'environ 1,4 case, élargie aux 2 cases
##   de la grille (montants déplacés, seuil prolongé) ;
## - pont inférieur : escalier (≈ 2,4 cases) ramené aux 2 cases `S` (2..3, 2), porte de la cabine B
##   recentrée sur (10, 1) ;
## - couloir : porte du capitaine recentrée sur (15, 1).
RETOUCHES_COQUES = {
	"INT_SS_ANNE_CABINE_COQUE": [
		{"zone": [466, 690, 513, 864], "dx": -33, "remplir": [560, 590]},
		{"zone": [637, 690, 683, 864], "dx": 35, "remplir": [560, 590]},
	],
	"INT_SS_ANNE_CABINE_CAPITAINE_COQUE": [
		{"zone": [570, 790, 616, 960], "dx": -40, "remplir": [650, 700]},
		{"zone": [732, 790, 774, 960], "dx": 36, "remplir": [650, 700]},
	],
	"INT_SS_ANNE_PONT_INFERIEUR_COQUE": [
		{"zone": [190, 0, 432, 292], "largeur": 202, "remplir": [440, 470]},
		{"zone": [950, 30, 1166, 262], "dx": -54, "remplir": [1180, 1220]},
	],
	"INT_SS_ANNE_COULOIR_COQUE": [
		{"zone": [1322, 30, 1512, 290], "dx": 72, "remplir": [1150, 1222]},
	],
}
## Coques préparées : (id, fiche, grille).
PIECES = [
	("int_ss_anne_pont_principal_coque", "INT_SS_ANNE_PONT_PRINCIPAL_COQUE", "ss_anne_pont_principal"),
	("int_ss_anne_couloir_coque", "INT_SS_ANNE_COULOIR_COQUE", "ss_anne_couloir_capitaine"),
	("int_ss_anne_cabine_capitaine_coque", "INT_SS_ANNE_CABINE_CAPITAINE_COQUE",
		"ss_anne_cabine_capitaine"),
	("int_ss_anne_restaurant_coque", "INT_SS_ANNE_RESTAURANT_COQUE", "ss_anne_restaurant"),
	("int_ss_anne_pont_inferieur_coque", "INT_SS_ANNE_PONT_INFERIEUR_COQUE", "ss_anne_pont_inferieur"),
	("int_ss_anne_cabine_coque", "INT_SS_ANNE_CABINE_COQUE", "ss_anne_cabine_a"),
	("int_arene_carmin_coque", "INT_ARENE_CARMIN_COQUE", "carmin_arene"),
]
## (planche préparée, identifiant de fiche, look du jeu) ; looks en fin de LOOKS au T10.
_PERSOS = [("capitaine", "CAPITAINE", "captain"), ("major_bob", "MAJOR_BOB", "surge"),
	("gentleman", "GENTLEMAN", "gentleman"), ("rockeur", "ROCKEUR", "rocker"),
	("hotesse", "HOTESSE", "hostess"), ("passagere", "PASSAGERE", "passenger_f")]
PERSONNAGES_JEU = [(nom, look, 128) for nom, _, look in _PERSOS]
## Icônes du Sac (T10, `preparer_menu.py` : planche de 4 colonnes, les 2 premières occupées).
ICONES_IDS = ["paralyze_heal", "awakening"]


def _taille_grille(grille: str) -> list[int]:
	rangees = lire_grille(grille)
	return [len(rangees[0]), len(rangees)]


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T10 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T10 sur la planche de contrôle. `cases` = largeur en cases de chaque élément.
	`boite` (couloir) : recadrage avant l'étirement — deux lignes à ajouter à `preparer.pieces` au T10."""
	pieces = []
	for ident, fiche, grille in PIECES:
		entree = {"id": ident, "source": _revision(f"{fiche}_NE"),
			"sortie": f"{_W}interiors/{ident}.png", "cases": _taille_grille(grille)}
		if fiche == "INT_SS_ANNE_COULOIR_COQUE":
			entree["boite"] = BOITE_COULOIR
		if fiche in RETOUCHES_COQUES:
			entree["retouches"] = RETOUCHES_COQUES[fiche]
		pieces.append(entree)
	return {
		"objets": [
			# Bloc 4 fois plus haut que large : à 1,3 case de large il ne ferait que 5 cases de
			# haut ; `taille_cases` l'étire (× 1,34 en hauteur, comme les coques ≤ 1,35) pour que
			# la porte peinte tombe sur la case `D` (0, 6) (T10).
			{"id": "bldg_ss_anne_superstructure_01",
				"source": _revision("WORLD_BLDG_SS_ANNE_SUPERSTRUCTURE_OUEST_NE"),
				"sortie": f"{_W}buildings/bldg_ss_anne_superstructure_01.png", "axe": "w", "cases": 1.3,
				"taille_cases": [1.3, 6.8], "ombre": False, "contact": None},
		],
		"planches_objets": [
			_planche_objets("INT_SS_ANNE_PLANCHE_A_NE", "interiors", 3, 2, SS_ANNE_A_IDS,
				[2, 4, 2, 4, 2, 1], 0.2),
			_planche_objets("INT_SS_ANNE_PLANCHE_B_NE", "interiors", 3, 2, SS_ANNE_B_IDS,
				[2, 3, 1, 2, 2, 3], 0.2),
			_planche_objets("INT_ARENE_CARMIN_PLANCHE_NE", "interiors", 3, 2, ARENE_IDS,
				[0.75, 1, 1, 3.5, 3.5], 0.15),
			# Une seule échelle (216 px de la planche = 1 case, mesurée sur les bastingages nord
			# de 2 cases) ; les deux chaises longues forment une seule paire (2 cases) : boîtes.
			_planche_objets("WORLD_RELIEF_PONT_EXTERIEUR_PLANCHE_NE", "relief", 4, 2, PONT_EXT_IDS,
				[2, 2, 2, 0.27, 0.62, 0.63, 2, 1], None, boites=BOITES_PONT_EXT),
		],
		# Effet : cellules fixes (les feuilles détachées ne font pas de taches séparées), une
		# seule échelle pour les 4 images et la même cellule (le trait ne saute pas d'une image à
		# l'autre) : `preparer.effets`.
		"effets": [
			{"source": _revision("FX_COUPE_PLANCHE_NE"), "dossier": f"{_W}fx/", "ids": FX_IDS,
				"boites": [[i * 384, 60, (i + 1) * 384, 560] for i in range(4)], "echelle": 0.6,
				"nettoyer": True},
		],
		"pieces": pieces,
		# Pont de teck du pont extérieur : les planches du quai (série 17) éclaircies et un peu
		# désaturées (fiche §B : variation sans nouvelle image).
		"sols": [
			{"id": "ground_pont_teck_01", "source": "WORLD_GROUND_PLANCHES_QUAI_01_NE_r1.png",
				"sortie": f"{_W}ground/ground_pont_teck_01.png", "taille": 384, "contraste": 1.0,
				"couleur": 0.9, "luminosite": 1.15, "raccord": 24},
		],
		"personnages": [
			{"id": nom, "source": _revision(f"PNJ_{ident}_NE"), "sortie": f"{_C}{nom}_sheet.png",
				"hauteur": 128} for nom, ident, _ in _PERSOS
		],
		"attentes": [
			*[{"id": f"{nom}_idle", "source": _revision(f"{ident}_ATTENTE"),
				"sortie": f"{_C}{nom}_idle_sheet.png", "marche": nom} for nom, ident, _ in _PERSOS],
		],
	}
	# Le capitaine malade (3 poses, pas 4) n'est pas une planche d'attente : `--malade`.


## Planche du capitaine malade (T10) : 3 poses (dos penché, dos penché en inspirant, face
## soulagée) → planche d'attente de 5 colonnes `capitaine_malade_idle` (bas = soulagé, gauche et
## droite = l'attente du capitaine, haut = penché, 5e = penché en inspirant : `idle_up` en deux
## images, la respiration du dossier 19 §6) ; marche = celle du capitaine. Même échelle que
## l'attente du capitaine (la pose de face prend la hauteur de son attente de face).
MALADE_BOITES = [[0, 200, 480, 840], [480, 200, 880, 840], [880, 200, 1250, 840]]


def capitaine_malade() -> None:
	import preparer
	source = preparer.nettoyer_halos(Image.open(ART / _revision("CAPITAINE_MALADE")).convert("RGBA"))
	poses = [preparer._silhouette(source.crop(tuple(b))) for b in MALADE_BOITES]
	catalogue_chemin = RACINE / "assets/world/catalogue.json"
	catalogue = json.loads(catalogue_chemin.read_text())
	attente = catalogue["personnages"]["capitaine_idle"]
	largeur_c, hauteur_c = attente["cellule"]
	feuille_attente = Image.open(RACINE / attente["fichier"][6:]).convert("RGBA")
	face = feuille_attente.crop((0, 0, largeur_c, hauteur_c))
	hauteur_face = face.getbbox()[3] - face.getbbox()[1]
	echelle = hauteur_face / poses[2].height
	reduites = [p.resize((round(p.width * echelle), round(p.height * echelle)), Image.LANCZOS)
		for p in poses]
	largeur = max(largeur_c, max(r.width for r in reduites) + 4)
	largeur += largeur % 2
	colonnes = [reduites[2], feuille_attente.crop((largeur_c, 0, 2 * largeur_c, hauteur_c)),
		feuille_attente.crop((2 * largeur_c, 0, 3 * largeur_c, hauteur_c)), reduites[0], reduites[1]]
	feuille = Image.new("RGBA", (largeur * len(colonnes), hauteur_c), (0, 0, 0, 0))
	for i, image in enumerate(colonnes):
		if image.height == hauteur_c and image.width == largeur_c:  # cellule d'attente telle quelle
			feuille.alpha_composite(image, (i * largeur + (largeur - largeur_c) // 2, 0))
		else:
			feuille.alpha_composite(image, (i * largeur + (largeur - image.width) // 2,
				hauteur_c - image.height))
	sortie = f"{_C}capitaine_malade_idle_sheet.png"
	feuille.save(RACINE / sortie, optimize=True)
	ancienne = RACINE / f"{_C}capitaine_malade_sheet.png"
	if ancienne.exists():
		ancienne.unlink()
	personnages = catalogue["personnages"]
	personnages.pop("capitaine_malade", None)
	personnages["capitaine_malade"] = dict(personnages["capitaine"])
	personnages["capitaine_malade_idle"] = {"fichier": "res://" + sortie,
		"cellule": [largeur, hauteur_c], "hauteur": 128, "colonnes": len(colonnes), "lignes": 1,
		"ordre_colonnes": ["bas", "gauche", "droite", "haut", "haut_inspire"]}
	catalogue_chemin.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")
	print(f"capitaine_malade_idle : cellule {largeur} × {hauteur_c}, échelle {echelle:.4f}")


## Objets fixes de l'Arène (T10, sous l'identifiant du T11 `electric_barrier`) : la barrière
## active entière (3,5 cases : pylônes à cheval sur les machines voisines) portée par le segment
## du milieu (8, 5) ; les segments 7 et 9 portent une image vide (`electric_barrier_side`), ils
## ne servent qu'à bloquer leur case. Écrits dans `assets/sprites/objects/painted/`, entrées
## « images » du catalogue (lues par `build_character_frames.gd`, FIXED_OBJECTS).
def objets_arene() -> None:
	catalogue_chemin = RACINE / "assets/world/catalogue.json"
	catalogue = json.loads(catalogue_chemin.read_text())
	dossier = "assets/sprites/objects/painted/"
	active = Image.open(RACINE / "assets/world/interiors/int_barriere_active_01.png").convert("RGBA")
	active.save(RACINE / f"{dossier}electric_barrier.png", optimize=True)
	Image.new("RGBA", (4, 4), (0, 0, 0, 0)).save(RACINE / f"{dossier}electric_barrier_side.png")
	catalogue["images"]["electric_barrier"] = {"fichier": f"res://{dossier}electric_barrier.png",
		"taille": list(active.size)}
	catalogue["images"]["electric_barrier_side"] = {
		"fichier": f"res://{dossier}electric_barrier_side.png", "taille": [4, 4]}
	catalogue_chemin.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")
	print(f"electric_barrier : {active.width} × {active.height}")


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 17) ; une section absente est créée en fin de fichier."""
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
	print(f"manifeste : {ajouts} entrée(s) de la série 18 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------

## Couleurs des plans à l'échelle (1 case = CASE_PLANCHE).
COULEURS_PLAN = {"K": (64, 46, 38), ".": (214, 192, 150), "D": (110, 196, 120), "X": (110, 196, 120),
	"S": (110, 170, 220), "T": (240, 200, 90), "B": (250, 225, 80), "w": (55, 105, 160),
	"r": (150, 120, 90), "i": (150, 155, 165), "m": (90, 95, 110)}
MEUBLE = (160, 118, 82)


def _plan(grille: str, cadre: Image.Image | None = None) -> Image.Image:
	"""La grille en aplats à l'échelle de la planche (vérifie emprises et sorties d'un coup d'œil)."""
	rangees = lire_grille(grille)
	image = Image.new("RGBA", (len(rangees[0]) * CASE_PLANCHE, len(rangees) * CASE_PLANCHE))
	d = ImageDraw.Draw(image)
	for y, rangee in enumerate(rangees):
		for x, c in enumerate(rangee):
			boite = (x * CASE_PLANCHE, y * CASE_PLANCHE, (x + 1) * CASE_PLANCHE - 1,
				(y + 1) * CASE_PLANCHE - 1)
			d.rectangle(boite, fill=COULEURS_PLAN.get(c, MEUBLE) + (255,), outline=(0, 0, 0, 90))
	return image


def _ref(nom: str, cases_haut: float | None = None, hauteur: int | None = None) -> Image.Image:
	image = _recadrage(nom).convert("RGBA")
	if hauteur is None:
		vue, _ = REFS[nom]
		hauteur = round(image.height / PX_CASE[vue] * CASE_PLANCHE) if cases_haut is None else round(
			cases_haut * CASE_PLANCHE)
	return _echelle(image, max(1, hauteur) / image.height)


def _vue_jeu(nom: str, grille: str) -> Image.Image:
	"""Vue d'ensemble entière étirée à la taille de la grille (comme la préparation d'une coque)."""
	largeur, hauteur = _taille_grille(grille)
	return _recadrage(nom).convert("RGBA").resize((largeur * CASE_PLANCHE, hauteur * CASE_PLANCHE),
		Image.LANCZOS)


def _si(relatif: str, etiquette: str, fonction=_asset):
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def _j15(relatif: str, etiquette: str, facteur: float = 0.5, pose: bool = False) -> list:
	"""Asset préparé de la série 17 (local, sinon `BRANCHE_J15`) à l'échelle de la planche."""
	image = _image_preparee(relatif)
	if image is None:
		return []
	if pose:
		image = image.crop((0, 0, image.width // 4, image.height // 4))
	return [(_echelle(image, facteur), etiquette + " (s. 17)")]


def _tache(rvb: tuple[int, int, int], largeur: float, hauteur: float) -> Image.Image:
	"""Aplat de la taille en jeu d'un élément sans référence (meubles, effet)."""
	aplat = Image.new("RGBA", (round(largeur * CASE_PLANCHE), round(hauteur * CASE_PLANCHE)),
		rvb + (255,))
	ImageDraw.Draw(aplat).rectangle((0, 0, aplat.width - 1, aplat.height - 1), outline=(0, 0, 0, 160))
	return aplat


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso(f"{_C}heros_sheet.png"), "héros (échelle)")
	w, c = _W, _C
	p = _Planche(3000, "S.S. Anne et Arène de Carmin — kit de la série 18 (T1, jalon 16) : "
		"1 case = 48 px ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS (navire et Carmin : série 17, `main`)", [
		heros,
		*_j15(f"{w}buildings/bldg_ss_anne_proue_01.png", "navire amarré :\nproue"),
		*_j15(f"{w}buildings/bldg_ss_anne_milieu_01.png", "milieu"),
		*_j15(f"{w}buildings/bldg_ss_anne_poupe_01.png", "poupe\n(étape animate)"),
		*_j15(f"{w}props/prop_jeune_arbre_arene_01.png", "jeune arbre\n(arbuste à couper)"),
		*_j15(f"{w}props/prop_caisses_port_01.png", "caisses k 2 × 1\n(pont inférieur)"),
		(_asset(f"{w}interiors/int_plante.png"), "plantes x\n(pont principal)"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball\nobjets visibles"),
	], (40, 90, 50))
	persos = [("rival", "rival : rival n° 4"), ("dresseuse", "lass : Fillette\nLéna (cabine A)"),
		("scout", "scout : Basile\n(cabine B)"), ("voyageur", "traveler :\npassager_1"),
		("marchand", "clerk : serveur\n(restaurant)"), ("guide_arene", "gym_guide :\nguide (Arène)")]
	p.section("1 bis. PERSONNAGES RÉUTILISÉS", [
		heros,
		*_j15(f"{c}marin_sheet.png", "sailor : marin, matelot,\n6 Marins Dresseurs", pose=True),
		*[x for nom, etiquette in persos for x in _si(f"{c}{nom}_sheet.png", etiquette, _cellule_perso)],
	], (40, 90, 50))

	p.section("2. VARIATIONS SANS NOUVEL ASSET", [
		*_j15(f"{w}ground/ground_planches_quai_01.png", "pont de teck : planches\ndu quai éclaircies"),
		(_echelle(Image.open(RACINE / f"{w}ground/ground_eau_01.png").convert("RGBA").crop(
			(0, 0, 192, 192)), 0.5), "mer : ground_eau_01\nassombrie (shader)"),
		(_plan("ss_anne_cabine_a"), "cabines A, B, C :\nune coque, 3 cartes"),
	], (110, 90, 40))

	p.section("3. NOUVEAUX : COQUES À L'ÉCHELLE (vue validée étirée à la grille, puis plan)", [
		(_vue_jeu("REF_PP_SALLE", "ss_anne_pont_principal"), "INT_SS_ANNE_PONT_PRINCIPAL_COQUE\n"
			"26 × 13 (vague 1, recalée)"),
		(_plan("ss_anne_pont_principal"), "grille 26 × 13"),
		(_vue_jeu("REF_AC_SALLE", "carmin_arene"), "INT_ARENE_CARMIN_COQUE 17 × 15\n"
			"(vague 1 ; Champion : 3 rangées)"),
		(_plan("carmin_arene"), "grille 17 × 15"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : COQUES SANS VUE (vague 2, rendu du pont principal joint)", [
		(_plan("ss_anne_couloir_capitaine"), "COULOIR 18 × 7\n(bande recadrée)"),
		(_plan("ss_anne_cabine_capitaine"), "CABINE_CAPITAINE\n14 × 10"),
		(_plan("ss_anne_restaurant"), "RESTAURANT 18 × 11\n(passe-plat)"),
		(_plan("ss_anne_pont_inferieur"), "PONT_INFERIEUR 22 × 11\n(escalier montant)"),
		(_plan("ss_anne_cabine_a"), "CABINE 12 × 9\n(A, B, C)"),
	], (130, 70, 40))
	p.section("3 ter. NOUVEAUX : PONT EXTÉRIEUR (carte d'extérieur 26 × 11)", [
		heros,
		(_vue_jeu("REF_PE_PONT", "ss_anne_pont_exterieur"), "vue validée étirée à la grille\n"
			"(sol : teck = quai éclairci ; mer : shader)"),
		(_plan("ss_anne_pont_exterieur"), "grille 26 × 11"),
		(_ref("REF_PE_BASTINGAGE_N", 0.9), "PONT_EXTERIEUR_PLANCHE :\nbastingages N ×2"),
		(_ref("REF_PE_BASTINGAGE_S", 1.6), "bastingage S + flanc,\nE, angles"),
		(_ref("REF_PE_CHAISES", 1.2), "chaises longues l\n2 × 1"),
		(_ref("REF_PE_BOUEE", 1), "bouée u"),
		(_ref("REF_PE_SUPERSTRUCTURE", 7.5), "SUPERSTRUCTURE_OUEST\n1,3 × 7,5 (porte D)"),
	], (130, 70, 40))
	p.section("3 quater. NOUVEAUX : MOBILIER (référence ou aplat à la taille en jeu)", [
		heros,
		(_ref("REF_PP_BANQUETTE", 1.2), "PLANCHE_A : banquette b\n2 × 1 (×3)"),
		(_ref("REF_PP_COMPTOIR", 1.3), "comptoir d'accueil c\n4 × 1"),
		(_tache((240, 240, 235), 2, 1.3), "table de restaurant t\n2 × 1 (×4)"),
		(_tache((200, 205, 210), 4, 1.3), "comptoir de cuisine c\n4 × 1"),
		(_tache((40, 60, 110), 2, 2.4), "lit de cabine L\n2 × 2 (+ capitaine)"),
		(_tache((110, 60, 40), 1, 1.8), "armoire a\n(cache cabine B)"),
		(_tache((130, 80, 50), 2, 1.3), "PLANCHE_B : table\nsous hublot n 2 × 1"),
		(_tache((110, 60, 40), 3, 1.3), "bureau du\ncapitaine N 3 × 1"),
		(_echelle(_asset(f"{w}interiors/int_lavabo_01.png"), 0.5), "lavabo v 1 × 1\n(l'actuel fait 2)"),
		(_tache((200, 180, 130), 2, 1.3), "table à cartes g\n2 × 1"),
		(_tache((150, 110, 70), 2, 2.3), "caisses de cale k\n2 × 2"),
		(_tache((150, 110, 70), 3, 2.3), "caisses de cale k\n3 × 2"),
	], (130, 100, 40))
	p.section("3 quinquies. NOUVEAUX : ARÈNE (une poubelle ×15, armoires, barrière)", [
		heros,
		(_ref("REF_AC_POUBELLE", 1), "ARENE_CARMIN_PLANCHE :\npoubelle i ×15 (identiques)"),
		(_ref("REF_AC_ARMOIRES", 1.5), "armoires électriques m\nA, B (×10)"),
		(_ref("REF_AC_BARRIERE", 1.5), "barrière B 3 × 1 :\nactive / coupée / absente"),
	], (130, 70, 40))
	p.section("3 sexies. NOUVEAUX : PERSONNAGES (128 px), EFFET, SAC, COMBAT", [
		heros,
		(heros[0], "PNJ_CAPITAINE\n(+ attente, + malade)"),
		(heros[0], "PNJ_MAJOR_BOB\n(+ attente)"),
		(heros[0], "PNJ_GENTLEMAN : Armand,\nÉmile, Victor, Louis"),
		(heros[0], "PNJ_ROCKEUR : Axel\n(Arène)"),
		(heros[0], "PNJ_HOTESSE\n(pont principal)"),
		(heros[0], "PNJ_PASSAGERE : pont\next., convive"),
		(_tache((225, 240, 255), 2, 2), "FX_COUPE_PLANCHE\n4 images, ≈ 2 cases"),
		*[(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
			"UI_OBJETS_J16 : Anti-Para,\nRéveil (style)") for i in ("antidote",)
			if (RACINE / f"assets/ui/items/{i}.webp").exists()],
		(_ref("REF_PP_TAPIS", hauteur=120), "COMBAT_DECOR\nSS_ANNE_SALON"),
		(_ref("REF_PE_TECK", hauteur=120), "COMBAT_DECOR\nSS_ANNE_PONT"),
		(_ref("REF_AC_SOL", hauteur=120), "COMBAT_DECOR\nGYM_CARMIN"),
	], (130, 100, 40))
	p.section("3 septies. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_ref("REF_PE_TECK", hauteur=96), "GROUND_PONT_TECK_01 si le\nquai éclairci ne suffit pas"),
		(heros[0], "PNJ_CUISINIER\n(sans case : Kevin)"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_PP_SALLE", hauteur=200), "faisceaux de lumière dorée\n(jeu : NE + LightGlow)"),
		(_ref("REF_AC_CHAMPION", 2), "zone du Champion\n2 rangées → 3 (grille)"),
		(_ref("REF_AC_BARRIERE", hauteur=80), "lueur bleue peinte\n(jeu : profil + glow)"),
		(_ref("REF_PE_MOUETTES", hauteur=60), "mouettes\n(faune non-Pokémon)"),
		(_ref("REF_PP_PASSERELLE", 2), "passerelle large\n(grille : 2 cases)"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T2) : la dernière révision présente de chaque image
	(_r4 … _r1) sur fond gris moyen, nom et révision dessous. Les conditionnels ne sont pas montrés."""
	cellule, marge, colonnes = 440, 24, 5
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
	police = _police(17)
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
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "J16_KIT_v1.png"))
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon16_assets" / "serie18_contact.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--malade" in arguments:
		capitaine_malade()
	elif "--objets-arene" in arguments:
		objets_arene()
	else:
		generer(set(arguments))
