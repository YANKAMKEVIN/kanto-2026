#!/usr/bin/env python3
"""Série 17 — Route 5, passage souterrain, Route 6 et Carmin-sur-Mer (jalon 15, lumière neutre).
Liste : docs/tech/jalon-15.md §1.4 ; fiches : docs/design/fiches-assets/serie-17-carmin.md.
**Numéro provisoire** : la série prend son numéro au push (contrat du J16, dossier 18 §17) ; 17 =
prochain numéro libre constaté le 2026-10-14 (16 = J14, branches locales `j14-*`).

Méthode des J8–J14 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées, `docs/design/reference/{souterrain,route-6,carmin}-vue-generale-v1.png` ; **la grille fait
foi** : `tools/plans/route_5.txt` (v2), `underground_path.txt`, `route_6.txt`, `vermilion_city.txt`).
La vue de la Route 5 n'existe pas encore : ses assets (Pension, indice du tronc) sont écrits d'après
la grille v2 et le dossier, **à recaler sur la vue Route 5** (une `_r2` si l'image validée les
contredit). Repris : sols, forêt, hautes herbes, buissons, rochers, clôtures, massifs, panneaux,
Centre, Boutique, maison d'Argenta (maisons 1 et 2 de Carmin), coques d'intérieur, eau, berges et
roseaux, bittes et piles de la série 15, masse rocheuse de la série 14, PNJ existants. Générées :
  - bâtiments : Pension, poste de garde (×2 routes), entrée du souterrain (×2 routes), Arène de
    Carmin, Fan Club, maison du Pêcheur ;
  - S.S. Anne : silhouette guide (vague 1) puis trois tranches à l'échelle du jeu (vague 2) ;
  - port : texture de planches, planche des bords de quai en bois, planche de Carmin (jeune arbre
    de l'Arène, passerelle, grue, bitte à amarre, rouleau de cordage, caisses du port) ;
  - routes : planche (indices tronc et joncs, nénuphars), vue lointaine du port (Route 6) ;
  - souterrain : dalles et traces (textures), planche des murs maçonnés, planche des objets
    (deux escaliers, stèle, banc, pierre descellée, applique) ;
  - intérieurs : planche de 6 meubles (Pension, escalier des entrées, Fan Club) ;
  - personnages : marin, docker, président du Fan Club, gardien de la Pension (marche + attente) ;
  - Sac : Super Potion, Guérison ; combat : décor `route_5_6_prairie` (chaîne CB.3).
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_GROUND_EAU_PORT_01 (si `ground_eau_01` assombri
ne donne pas le bleu profond du port), INT_FAN_CLUB_COQUE (si la coque de maison d'Argenta + meubles
ne suffit pas), WORLD_BLDG_MAISON_COTIERE_01 (si deux maisons d'Argenta identiques se voient).

Lumière : NE pour tout ; l'eau et l'écume restent celles du jeu (shader) ; les appliques du
souterrain sont peintes éteintes-neutres (verre ambré), la lueur vient de `LightGlow` (`sconce`).

**Les prompts sont versionnés** : `tools/art/prompts/serie17/<NOM>.txt` (un par image),
`tools/art/attente/prompts/<NOM>_ATTENTE.txt` et `tools/art/combat_decors/prompts/`, écrits par
`--prompts` à partir des tables ci-dessous. Corriger une image = corriger la table, relancer
`--prompts`, relire le diff ; une correction après génération se lance en `_r2` (table CORRECTIONS).

Usage :
  tools/art/serie17.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie17.py --refs                  recadre les REF_CA_*, REF_R6_*, REF_SO_*, REF_R5_* dans $ART
  tools/art/serie17.py --ancres                copie les ancres de style absentes dans $ART
  tools/art/serie17.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie17.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/J15_KIT_v1.png)
  tools/art/serie17.py --contact [sortie.png]  planche de contact des images générées (T9)
  tools/art/serie17.py --manifeste             ajoute les entrées en fin de manifeste.json (T11 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie17.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T11)
  tools/art/serie17.py [IDENTIFIANT ...]       génère avec Codex, par vagues (sans argument : la
                                               série sans les conditionnels ; --refs --ancres d'abord)
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
	_lancer, _miroir, _Planche)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
## Ancres validées : checkout principal (séries 01–13), puis toutes les copies de travail (séries
## 14 et 15 n'existent parfois que dans une copie) ; la première trouvée gagne.
_PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026")


def _sources_ancres() -> list[Path]:
	copies = sorted((_PRINCIPAL / ".claude" / "worktrees").glob("*/build/art"))
	return [_PRINCIPAL / "build" / "art", *copies]


REFERENCE = RACINE / "docs/design/reference"
VUES = {
	"CA": REFERENCE / "carmin-vue-generale-v1.png",  # 1536 × 1024, 64 × 43 cases (≈ 24 px)
	"R6": REFERENCE / "route-6-vue-generale-v1.png",  # 1024 × 1536, 42 × 56 cases (≈ 24 × 27 px)
	"SO": REFERENCE / "souterrain-vue-generale-v1.png",  # 1254², 26 × 30 cases (≈ 48 × 42 px)
	"R5": REFERENCE / "route-5-plan-v2.png",  # plan en aplats v2 (756 × 1116, 18 px) : pas de vue
}
PX_CASE = {"CA": 24.0, "R6": 26.0, "SO": 45.0, "R5": 18.0}
PROMPTS = ICI / "prompts" / "serie17"
ATTENTES = ICI / "attente" / "prompts"
DECORS_COMBAT = ICI / "combat_decors" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue). Agrandis × 3 au plus, sans
## dépasser 1 536 px. Boîtes calculées sur la grille (case × px par case), recalées à l'œil.
REFS = {
	# Carmin-sur-Mer
	"REF_CA_ARENE": ("CA", (1030, 60, 1385, 250)),
	"REF_CA_ARBRE": ("CA", (1150, 165, 1250, 250)),
	"REF_CA_FAN_CLUB": ("CA", (295, 85, 505, 245)),
	"REF_CA_MAISON": ("CA", (115, 90, 290, 245)),
	"REF_CA_PECHEUR": ("CA", (130, 375, 325, 540)),
	"REF_CA_QUAI": ("CA", (60, 560, 1480, 680)),
	"REF_CA_QUAI_BORD": ("CA", (280, 600, 760, 680)),
	"REF_CA_PONTON": ("CA", (220, 600, 300, 830)),
	"REF_CA_NAVIRE": ("CA", (430, 630, 1210, 850)),
	"REF_CA_PASSERELLE": ("CA", (735, 600, 800, 670)),
	"REF_CA_AMARRES": ("CA", (370, 590, 480, 670)),
	"REF_CA_CAISSES": ("CA", (75, 560, 210, 625)),
	"REF_CA_CAISSES_EST": ("CA", (1355, 555, 1475, 620)),
	"REF_CA_MER": ("CA", (0, 840, 1536, 1024)),
	"REF_CA_PLACE": ("CA", (560, 325, 975, 510)),
	# Route 6
	"REF_R6_SORTIE": ("R6", (95, 95, 265, 195)),
	"REF_R6_POSTE": ("R6", (785, 165, 965, 280)),
	"REF_R6_ETANG": ("R6", (275, 720, 550, 980)),
	"REF_R6_NENUPHARS": ("R6", (285, 735, 545, 965)),
	"REF_R6_ROCHERS": ("R6", (215, 555, 295, 630)),
	"REF_R6_PORT": ("R6", (830, 1415, 1024, 1536)),
	"REF_R6_PRAIRIE": ("R6", (660, 320, 980, 1000)),
	# Passage souterrain
	"REF_SO_ESCALIER_N": ("SO", (135, 30, 245, 115)),
	"REF_SO_ESCALIER_S": ("SO", (905, 1105, 1015, 1190)),
	"REF_SO_STELE": ("SO", (255, 210, 330, 305)),
	"REF_SO_PIERRE": ("SO", (540, 375, 625, 450)),
	"REF_SO_BANC": ("SO", (1005, 760, 1125, 840)),
	"REF_SO_APPLIQUE": ("SO", (235, 80, 285, 145)),
	"REF_SO_MUR": ("SO", (395, 555, 745, 655)),
	"REF_SO_ANGLE": ("SO", (215, 180, 375, 385)),
	"REF_SO_SOL": ("SO", (150, 490, 1000, 610)),
	"REF_SO_GALERIE": ("SO", (120, 30, 1030, 660)),
	"REF_SO_ROCHE": ("SO", (400, 700, 880, 1100)),
	# Route 5 : plan en aplats seulement (géométrie, pas de DA)
	"REF_R5_PENSION": ("R5", (425, 390, 690, 580)),
}
AGRANDIR = 3
REF_MAX = 1536

## Ancres de style (images validées des séries précédentes, dans $ART ; `--ancres` les copie).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"
MAISON_ARGENTA = "WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png"
POSTE_FORET = "WORLD_BLDG_POSTE_FORET_01_NE_r1.png"
POSTE_NORD = "WORLD_BLDG_POSTE_FORET_NORD_01_NE_r1.png"
ARENE_ARGENTA = "WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png"
ARENE_AZURIA = "WORLD_BLDG_ARENE_AZURIA_01_NE_r1.png"  # série 15
QUAIS = "WORLD_RELIEF_QUAI_PLANCHE_NE_r1.png"  # série 15 (gabarit des modules de bord)
VILLE_EAU = "WORLD_PROP_VILLE_EAU_PLANCHE_NE_r1.png"  # série 15 (bitte, lampadaire de quai)
PONTS = "WORLD_PROP_PONTS_PLANCHE_NE_r3.png"  # série 15 (tablier de bois, piles)
BERGES = "WORLD_RELIEF_BERGE_PLANCHE_NE_r1.png"  # série 15 (roseaux)
EAU_MER = "WORLD_GROUND_EAU_01_NE_r1.png"
PAVE = "WORLD_GROUND_PAVE_A_01_CENTRE_NE_r1.webp"
MASSE_ROCHE = "WORLD_GROUND_MASSE_ROCHE_01_NE_r1.png"  # série 14
SOL_GROTTE = "WORLD_GROUND_GROTTE_01_NE_r2.png"  # série 14
PAROI_GROTTE = "WORLD_RELIEF_PAROI_GROTTE_PLANCHE_NE_r1.png"  # série 14 (gabarit des modules)
ECHELLES = "WORLD_PROP_ECHELLES_PLANCHE_NE_r1.png"  # série 14
INDICES = "WORLD_PROP_INDICES_PLANCHE_NE_r2.png"  # série 14 (indices d'objets cachés)
TRONC = "WORLD_PROP_TRONC_COUCHE_01_NE_r1.png"
CAISSES = "WORLD_PROP_CAISSES_01_NE_r1.png"
TONNEAU = "WORLD_PROP_TONNEAU_01_NE_r1.png"
BARQUE = "WORLD_PROP_BARQUE_01_NE_r1.png"
COMPTOIR = "INT_LONG_COMPTOIR_01_NE_r1.png"
CANAPE = "INT_CANAPE_01_NE_r1.png"
ETAGERE = "INT_GRANDE_ETAGERE_01_NE_r1.png"
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
GARDE = "PNJ_GARDE_NE_r1.png"
PECHEUR = "PNJ_PECHEUR_NE_r1.png"
VIEIL_HOMME = "PNJ_VIEIL_HOMME_NE_r1.png"
# Images de la série 17 jointes aux vagues suivantes.
NAVIRE_GUIDE = "WORLD_BLDG_SS_ANNE_GUIDE_NE_r1.png"
DALLES = "WORLD_GROUND_DALLES_SOUTERRAIN_01_NE_r1.png"
PLANCHE_CARMIN = "WORLD_PROP_CARMIN_PLANCHE_NE_r1.png"
ANCRES = [*STYLE, HEROS, MAISON_ARGENTA, POSTE_FORET, POSTE_NORD, ARENE_ARGENTA, ARENE_AZURIA, QUAIS,
	VILLE_EAU, PONTS, BERGES, EAU_MER, PAVE, MASSE_ROCHE, SOL_GROTTE, PAROI_GROTTE, ECHELLES, INDICES,
	TRONC, CAISSES, TONNEAU, BARQUE, COMPTOIR, CANAPE, ETAGERE, MENU_OBJETS, GARDE, PECHEUR, VIEIL_HOMME]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, nom de navire, AUCUN emblème rond "
	"de type balle (ni cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou "
	"faune non-Pokémon (mouettes, oiseaux, poissons réels, crabes, insectes), Pikachu et tout Pokémon non "
	"demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune), élément "
	"effrayant.")

VALEURS_PIERRE = ("Valeurs : pierre ancienne gris-beige, lumière NEUTRE de milieu de journée (le jeu "
	"ajoute lui-même l'obscurité du souterrain et la lueur chaude des appliques : ne peins NI pénombre, "
	"NI flaque de lumière dorée, NI halo) ; contraste doux, aucune ombre portée.")

# --- Tables ------------------------------------------------------------------------------

## Textures de sol (opaques, raccordables) : (identifiant, référence, description, ancres,
## valeurs, vague).
SOLS = [
	("WORLD_GROUND_PLANCHES_QUAI_01", "REF_CA_QUAI",
		"texture des PLANCHES DU QUAI et des pontons de Carmin-sur-Mer, vue strictement de dessus : "
		"longues planches de bois brun miel chaud posées HORIZONTALEMENT (de gauche à droite), larges "
		"d'environ un quart de case (1 case = 256 px sur cette texture : 4 planches par case), joints "
		"fins et sombres réguliers, extrémités de planches décalées comme un vrai platelage, têtes de "
		"clous discrètes, nuances de bois d'une planche à l'autre (miel, brun clair, un peu de gris "
		"délavé par le sel) ; propre et solide ; aucune corde, aucune caisse, aucune flaque, aucun "
		"élément remarquable qui trahirait la répétition.",
		[PONTS], "Valeurs : bois clair et chaud, lumière neutre, aucune ombre portée ; contraste doux.", 1),
	("WORLD_GROUND_DALLES_SOUTERRAIN_01", "REF_SO_SOL",
		"texture du SOL DU PASSAGE SOUTERRAIN, un vieux couloir de pierre sous la ville : grandes "
		"DALLES rectangulaires de pierre gris-beige posées en assises régulières (environ une demi-case "
		"à une case chacune, 1 case = 256 px sur cette texture), joints fins plus sombres, bords un peu "
		"émoussés par le temps, très fines nuances de beige, de gris chaud et de gris-bleu d'une dalle à "
		"l'autre, quelques points de mousse minuscule dans de rares joints ; ancienne et soignée, jamais "
		"en ruine ; plus régulière, plus claire et plus taillée que le sol de grotte joint (à ne pas "
		"copier) ; aucune fissure marquée, aucune flaque, aucune trace.",
		[SOL_GROTTE, PAVE], VALEURS_PIERRE, 1),
	("WORLD_GROUND_TRACES_SOUTERRAIN_01", "REF_SO_GALERIE",
		"texture des TRACES DE PASSAGE du souterrain : EXACTEMENT les mêmes dalles que la texture jointe "
		"WORLD_GROUND_DALLES_SOUTERRAIN_01 (même pierre, même taille, même pose), mais POLIES et USÉES "
		"par des années de pas : surface un peu plus claire et plus lisse, arêtes arrondies, joints "
		"comblés de poussière claire, fines rayures d'usure dans le sens de la marche (de haut en bas), "
		"quelques traces de semelles très estompées ; la différence avec la texture jointe est douce "
		"(le jeu mélange les deux par un masque).",
		[DALLES, SOL_GROTTE], VALEURS_PIERRE, 2),
]

## Textures conditionnelles : (identifiant, référence, description, ancres, valeurs).
SOLS_COND = [
	("WORLD_GROUND_EAU_PORT_01", "REF_CA_MER",
		"texture de la MER DU PORT de Carmin-sur-Mer, vue strictement de dessus : eau BLEU PROFOND "
		"(bleu de Prusse vers le bleu outremer), plus sombre et plus dense que la mer jointe, petites "
		"vagues régulières en écailles, éclats de ciel clairs répartis uniformément et peints dans la "
		"valeur ; aucune écume, aucun rivage, aucun reflet de bateau ni de quai, aucun motif remarquable.",
		[EAU_MER], "Valeurs : eau profonde, lumière neutre, aucune ombre portée, aucun vignettage."),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_BLDG_PENSION_01", "REF_R5_PENSION", 7, 6,
		"la PENSION POKÉMON de la Route 5, une grande maison de campagne accueillante où un vieux "
		"monsieur garde les Pokémon des Dresseurs, façade de face (base de 7 cases de large, environ 6 "
		"cases de haut avec le toit), même main et même gabarit que la maison jointe "
		"WORLD_BLDG_MAISON_ARGENTA_01 mais une silhouette de FERME : murs crème à COLOMBAGES de bois "
		"brun, soubassement de pierre ; grand toit à deux pans de TUILES ROUGE-BRIQUE CHAUD (le « toit "
		"chaud » qui la fait reconnaître de loin, plus rouge et plus large que celui de la maison "
		"jointe) avec une lucarne et une cheminée de pierre ; au milieu exact du bas de la façade (4e "
		"colonne sur 7), une PORTE de bois vert sapin d'une case sous un petit AUVENT de bois porté par "
		"deux poteaux ; deux fenêtres à petits carreaux de chaque côté, volets verts, jardinières "
		"fleuries ; une petite girouette en forme de flèche sur le faîtage. Chaleureuse, bien tenue. "
		"Sans clôture, sans jardin, sans panneau, sans enseigne, sans Pokémon, aucune inscription. "
		"(La vue de la Route 5 n'existe pas encore : la référence jointe n'est qu'un plan en aplats qui "
		"donne la place et la couleur du toit.)",
		[MAISON_ARGENTA], LUMIERE_NE, 1),
	("WORLD_BLDG_POSTE_SAFRANIA_01", "REF_R6_POSTE", 7, "4,5",
		"un POSTE DE GARDE fermé sur la route de Safrania, petit bâtiment officiel et sobre, façade de "
		"face (base de 7 cases de large, environ 4,5 cases de haut avec le toit), même famille que les "
		"postes joints WORLD_BLDG_POSTE_FORET_01 et _NORD_01 (même pierre, même toit) : murs de PIERRE "
		"claire gris-beige appareillée, toit bas à quatre pans d'ARDOISES BLEU-GRIS ; au milieu exact du "
		"bas (4e colonne sur 7), une PORTE DOUBLE FERMÉE bleu-gris foncé d'une case de large sous un "
		"linteau de pierre ; une LANTERNE murale de fer noir de chaque côté de la porte (verre ambré, "
		"éteinte) ; deux petites fenêtres hautes à barreaux fins ; une marche de pierre. Fermé, calme, "
		"pas menaçant. Sans garde, sans barrière, sans panneau, aucune inscription, aucun écusson.",
		[POSTE_FORET, POSTE_NORD], LUMIERE_NE, 1),
	("WORLD_BLDG_ENTREE_SOUTERRAIN_01", "REF_R6_SORTIE", 7, 4,
		"le petit BÂTIMENT D'ENTRÉE DU PASSAGE SOUTERRAIN, façade de face (base de 7 cases de large, "
		"environ 4 cases de haut avec le toit), même famille que le poste joint WORLD_BLDG_POSTE_FORET_01 "
		"(même pierre claire gris-beige, même toit bas d'ARDOISES BLEU-GRIS), un peu plus ancien et plus "
		"massif : au milieu exact du bas (4e colonne sur 7), une large ARCHE de pierre OUVERTE d'une case "
		"et demie, sans porte, dans laquelle on devine les premières marches d'un escalier qui DESCEND "
		"et se perd dans l'ombre (intérieur sombre bleu-gris, jamais noir) ; une clé de voûte sculptée "
		"d'une simple vague ; de petits soupiraux à barreaux de chaque côté ; un peu de lierre au pied "
		"d'un angle. Accueillant malgré l'ombre. Sans lanterne, sans panneau, aucune inscription.",
		[POSTE_FORET], LUMIERE_NE, 1),
	("WORLD_BLDG_ARENE_CARMIN_01", "REF_CA_ARENE", 12, 7,
		"l'ARÈNE de Carmin-sur-Mer, celle d'un Champion de type Électrik surnommé « le Soldat de la "
		"Foudre », façade de face (base de 12 cases de large, environ 7 cases de haut avec le toit), même "
		"gabarit et même hauteur que les façades jointes WORLD_BLDG_ARENE_ARGENTA_01 et "
		"WORLD_BLDG_ARENE_AZURIA_01 : un long bâtiment solide de PIERRE grise et de MÉTAL riveté gris "
		"acier, toit à faible pente d'ARDOISES GRIS ANTHRACITE, deux PARATONNERRES de cuivre sur le "
		"faîtage, une bande de petites lampes jaunes éteintes sous la corniche ; au milieu exact du bas "
		"(6e et 7e colonnes sur 12), une PORTE DOUBLE de métal gris-bleu de 2 cases sous un fronton "
		"sculpté d'un ÉCLAIR en zigzag (un éclair, jamais un cercle ni un médaillon) ; des fenêtres "
		"hautes étroites à croisillons de fer. Martial, propre, impressionnant. Sans arbre devant "
		"l'entrée (il est posé à part), sans panneau, aucune inscription.",
		[ARENE_ARGENTA, ARENE_AZURIA], LUMIERE_NE, 1),
	("WORLD_BLDG_FAN_CLUB_01", "REF_CA_FAN_CLUB", 8, 6,
		"le FAN CLUB POKÉMON de Carmin-sur-Mer, une maison de club cossue et chaleureuse, façade de face "
		"(base de 8 cases de large, environ 6 cases de haut avec le toit), même main que la maison jointe "
		"WORLD_BLDG_MAISON_ARGENTA_01 : murs de pierre crème, grand toit de TUILES VERT SAPIN (la couleur "
		"qui le distingue), deux lucarnes ; au milieu exact du bas (4e et 5e colonnes sur 8), une PORTE "
		"DOUBLE de bois brun chaud vitrée de 2 cases sous une marquise de toile rayée vert et crème ; "
		"deux grandes fenêtres de chaque côté, rideaux crème, jardinières fleuries ; au-dessus de la "
		"porte, une ROSETTE de ruban rouge et or sculptée (un ruban de concours, pas un cercle plein). "
		"Sans panneau, sans Pokémon, aucune inscription.",
		[MAISON_ARGENTA], LUMIERE_NE, 1),
	("WORLD_BLDG_MAISON_PECHEUR_01", "REF_CA_PECHEUR", 7, 6,
		"la MAISON DU PÊCHEUR de Carmin-sur-Mer, petite maison côtière tournée vers le quai, façade de "
		"face (base de 7 cases de large, environ 6 cases de haut avec le toit), même gabarit et même "
		"main que la maison jointe WORLD_BLDG_MAISON_ARGENTA_01 mais côtière : murs blanchis à la chaux, "
		"soubassement de pierre, toit de TUILES BLEU ARDOISE MOYEN, volets de bois bleu délavé par le "
		"sel ; au milieu exact du bas (4e colonne sur 7), une PORTE de bois bleu d'une case ; un FILET "
		"DE PÊCHE brun suspendu en guirlande sous l'avant-toit, deux rames croisées fixées au mur, un "
		"petit casier de pêche contre le mur à droite. Modeste et vivante. Sans barque, sans panneau, "
		"aucune inscription.",
		[MAISON_ARGENTA, BARQUE], LUMIERE_NE, 1),
	("WORLD_BLDG_SS_ANNE_GUIDE", "REF_CA_NAVIRE", 29, "7,5",
		"le S.S. ANNE, un élégant PAQUEBOT DE CROISIÈRE amarré à quai, vu de dessus en trois quarts, "
		"COQUE PARALLÈLE au bas de l'image (proue à GAUCHE, poupe à DROITE) : image GUIDE qui fixe la "
		"silhouette, les proportions et les couleurs du navire entier (29 cases de long, environ 7,5 "
		"cases de haut au total : le pont vu de dessus sur 5,5 cases, la face avant de la coque sur 1,5 "
		"case en bas, la superstructure et la cheminée ne dépassant le haut du pont que d'une demi-case). Un LONG "
		"paquebot effilé, jamais un ferry trapu : coque BLEU MARINE profond à la ligne de flottaison "
		"rouge sombre, longue rangée régulière de HUBLOTS sur la face avant, proue élancée et inclinée, "
		"poupe arrondie de croiseur ; trois ponts étagés de SUPERSTRUCTURE BLANCHE aux longues "
		"promenades vitrées et aux bastingages fins ; une seule grande CHEMINÉE ROUGE à manchette noire "
		"au milieu ; un mât fin à l'avant et à l'arrière ; huit canots de sauvetage blanc et orange "
		"alignés ; ponts de teck clair ; au milieu du flanc NORD (côté quai, en haut de l'image), une "
		"ouverture de coupée où arrivera une passerelle (2 cases de large, aux 11e et 12e cases depuis "
		"la proue). Majestueux et accueillant. AUCUNE eau dessinée (la ligne de flottaison est le bas de "
		"l'objet), aucune vague, aucune amarre, aucun nom, aucune lettre, aucun drapeau à motif.",
		[ARENE_AZURIA, PONTS], LUMIERE_NE, 1),
	("WORLD_PROP_VUE_PORT_01", "REF_R6_PORT", 4, 4,
		"la VUE LOINTAINE DU PORT depuis le belvédère de la Route 6 : un petit groupe d'éléments du "
		"port de Carmin qui DÉPASSENT au loin au-dessus d'une lisière de forêt, à poser sur la cime des "
		"arbres au bout de la route : le haut d'une GRUE de port rouge et grise, deux MÂTS fins de "
		"voiliers, et le sommet de la CHEMINÉE ROUGE à manchette noire du paquebot joint "
		"WORLD_BLDG_SS_ANNE_GUIDE_NE_r1 ; un mince bandeau de mer bleu profond scintillante à "
		"l'horizon tout en bas ; le tout plus petit, plus clair et un peu plus bleuté qu'au premier "
		"plan (c'est LOIN), 4 cases de large, environ 4 de haut ; le bas de l'image se fond dans la "
		"transparence (les arbres du jeu le recouvrent). Aucune maison entière, aucun arbre peint.",
		[NAVIRE_GUIDE, PLANCHE_CARMIN], LUMIERE_NE, 2),
]

## Tranches du S.S. Anne (vague 2, jointe : la silhouette guide) : (identifiant, cases de la proue
## couvertes, largeur en cases, bords coupés, description de la partie).
_TRANCHES = [
	("WORLD_BLDG_SS_ANNE_PROUE", "0 à 10", 10, "le bord DROIT seulement",
		"la PROUE : la pointe élancée et inclinée de la coque à gauche, le mât avant, le pont avant de "
		"teck avec ses cabestans, le début de la superstructure blanche à droite"),
	("WORLD_BLDG_SS_ANNE_MILIEU", "10 à 19", 9, "les bords GAUCHE et DROIT",
		"le MILIEU : la superstructure blanche la plus haute, la grande CHEMINÉE ROUGE à manchette noire, "
		"les canots de sauvetage du centre, et sur le flanc nord (en haut), l'ouverture de COUPÉE de 2 "
		"cases (1re et 2e cases de la tranche)"),
	("WORLD_BLDG_SS_ANNE_POUPE", "19 à 29", 10, "le bord GAUCHE seulement",
		"la POUPE : la fin de la superstructure blanche à gauche, le mât arrière, le pont arrière de teck "
		"avec ses bittes d'amarrage, la poupe arrondie de croiseur à droite"),
]


def _tranche(ident: str, cases: str, largeur: int, bords: str, partie: str) -> tuple:
	return (ident, "REF_CA_NAVIRE", largeur, "7,5",
		f"une TRANCHE du paquebot S.S. Anne, à l'ÉCHELLE DU JEU : EXACTEMENT le navire de l'image guide "
		f"jointe WORLD_BLDG_SS_ANNE_GUIDE_NE_r1 (mêmes couleurs, mêmes hauteurs de ponts, même rangée de "
		f"hublots, même ligne de flottaison, même angle), redessiné GRAND et DÉTAILLÉ, seulement ses "
		f"cases {cases} (comptées depuis la proue, à gauche) : {partie}. La tranche fait {largeur} cases "
		f"de long et environ 7,5 de haut. La coque est "
		f"COUPÉE NET à la verticale sur {bords} : toutes les lignes horizontales (ligne de flottaison, "
		"hublots, bastingages, bords de ponts) arrivent à ce bord aux mêmes hauteurs que dans le guide, "
		"pour que les trois tranches se raccordent bout à bout sans couture. AUCUNE eau, aucune vague, "
		"aucune amarre, aucun nom, aucune lettre.",
		[NAVIRE_GUIDE], LUMIERE_NE, 2)


SERIE_VAGUE2 = [_tranche(*t) for t in _TRANCHES]
## Formats particuliers (remplacent la ligne « Format » générique) : les tranches sont à une échelle
## commune fixe pour se raccorder (1 case = 120 px, soit 1 200 / 1 080 × 900 px environ).
FORMATS = {ident: (f"Format : PNG paysage 1536 × 1024 ; échelle FIXE commune aux trois tranches : "
	f"1 case = 120 px, soit environ {largeur * 120} × 900 px pour la tranche, centrée")
	for ident, _, largeur, _, _ in _TRANCHES}

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("WORLD_RELIEF_QUAI_BOIS_PLANCHE", ["REF_CA_QUAI_BORD", "REF_CA_PONTON", "REF_CA_QUAI"],
		"PLANCHE de 6 MODULES DE BORD DE QUAI EN BOIS (le bord du quai et des pontons de Carmin-sur-Mer, "
		"entre le platelage et la mer) dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 "
		"lignes (cellules de 512 × 512), un module par cellule, centré, à une échelle COMMUNE de 1 case "
		"= 200 px, tous vus de dessus en trois quarts. Matière : la tranche du quai — une grosse POUTRE "
		"DE RIVE de bois brun sombre qui borde les planches, posée sur des PIEUX ronds de bois goudronné "
		"régulièrement espacés (un pieu par case) qui plongent vers l'eau, quelques algues vert sombre "
		"au pied des pieux, une fine ligne d'eau mouillée sombre en bas ; même famille que la planche de "
		"quais jointe WORLD_RELIEF_QUAI_PLANCHE (gabarit des rôles) et que le tablier de bois de la "
		"planche de ponts jointe ; ANGLES DROITS : chaque module est un rectangle net qui se raccorde bout "
		"à bout avec son semblable.\n"
		"1 (ligne 1, à gauche) : BORD SUD A, la mer est AU SUD : la poutre de rive vue de dessus en haut, "
		"sa face avant et les pieux qui descendent vers l'eau en dessous ; 2 cases de long × environ 0,7 "
		"de haut (≈ 400 × 140 px). 2 (ligne 1, au milieu) : BORD SUD B, même gabarit, pieux et algues "
		"différents, une planche un peu plus claire. 3 (ligne 1, à droite) : BORD DE CÔTÉ, la mer est À "
		"DROITE : la poutre de rive vue de dessus en bande verticale, les têtes des pieux visibles le long "
		"du bord droit ; 0,25 case de large × 2 de long (≈ 50 × 400 px).\n"
		"4 (ligne 2, à gauche) : BOUT DE PONTON, la mer est au SUD, À GAUCHE et À DROITE : l'extrémité "
		"d'un ponton de 2 cases de large, poutre de rive en U, deux gros pieux d'angle ; 2 cases × 0,7 "
		"(≈ 400 × 140 px). 5 (ligne 2, au milieu) : ANGLE INTÉRIEUR, là où un ponton part du quai : un "
		"coin de poutre en équerre, un gros pieu d'angle ; 0,5 × 0,7 case (≈ 100 × 140 px). 6 (ligne 2, "
		"à droite) : PIEU ISOLÉ, un gros pieu de bois goudronné cerclé de fer, une corde enroulée, à "
		"poser dans l'eau le long d'un ponton ; 0,4 case de large × 1 de haut (≈ 80 × 200 px).\n"
		"Fond avec une vraie transparence (canal alpha), aucune planche de platelage (le sol du jeu les "
		"ajoute), aucune eau dessinée, aucune écume, aucune ombre portée.",
		[QUAIS, PONTS], LUMIERE_NE, 1),
	("WORLD_PROP_CARMIN_PLANCHE", ["REF_CA_ARBRE", "REF_CA_PASSERELLE", "REF_CA_AMARRES", "REF_CA_CAISSES"],
		"PLANCHE de 6 ÉLÉMENTS de Carmin-sur-Mer dans une image 1536 × 1024 : grille invisible de 3 "
		"colonnes × 2 lignes (cellules de 512 × 512), un élément par cellule, centré, la base de chacun "
		"sur une même ligne horizontale à 30 px du bas de sa cellule, à une échelle COMMUNE de 1 case = "
		"150 px, tous vus de dessus en trois quarts.\n"
		"1 (ligne 1, à gauche) : JEUNE ARBRE devant l'Arène, un arbuste-arbre jeune et dense au tronc "
		"fin, couronne ronde et touffue vert vif, un peu plus petit qu'un arbre adulte (2 cases de large "
		"≈ 300 px, environ 2 cases de haut), planté seul ; on comprend qu'un jour on pourra le couper "
		"(tronc mince bien visible), sans hache ni entaille. 2 (ligne 1, au milieu) : PASSERELLE "
		"d'embarquement, une rampe de bois clair à deux mains courantes de corde blanche sur poteaux "
		"vernis, vue de dessus, qui part du quai (en haut) vers le navire (en bas) ; 2 cases de large × "
		"1,3 de long (≈ 300 × 195 px). 3 (ligne 1, à droite) : GRUE DE QUAI, une petite grue de port à "
		"flèche, pied de métal rouge sombre riveté sur socle, cabine grise, flèche tournée vers la "
		"gauche avec un crochet et un câble ; 2 cases d'emprise au sol (≈ 300 px), environ 3,2 cases de "
		"haut.\n"
		"4 (ligne 2, à gauche) : BITTE À AMARRE, une bitte de fonte noire trapue sur laquelle est "
		"enroulée une grosse AMARRE de chanvre qui part vers le bas de l'image ; 1 case (≈ 150 px). 5 "
		"(ligne 2, au milieu) : ROULEAU DE CORDAGE, un gros cordage de chanvre lové en spirale à plat sur "
		"le quai ; 0,8 case (≈ 120 px). 6 (ligne 2, à droite) : CAISSES DU PORT, une pile de deux "
		"grosses caisses de bois cerclées de fer et d'un tonneau, un filet de cordes jeté dessus ; 2 "
		"cases de large × 1 (≈ 300 px), environ 1,4 case de haut ; même main que les caisses et le "
		"tonneau joints, mais plus grandes.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucun quai, aucune eau, aucune ombre "
		"portée.",
		[CAISSES, TONNEAU, VILLE_EAU], LUMIERE_NE, 1),
	("WORLD_PROP_ROUTES_J15_PLANCHE", ["REF_R6_NENUPHARS", "REF_R6_ETANG"],
		"PLANCHE de 4 PETITS ÉLÉMENTS des Routes 5 et 6 dans une image 1536 × 1024 : grille invisible "
		"de 2 colonnes × 2 lignes (cellules de 768 × 512), un élément par cellule, centré, à une échelle "
		"COMMUNE de 1 case = 200 px, tous vus de dessus en trois quarts.\n"
		"1 (ligne 1, à gauche) : INDICE TRONC, un petit TRONC COUCHÉ court et moussu d'une teinte plus "
		"grise et plus claire que le tronc couché joint WORLD_PROP_TRONC_COUCHE_01 (il doit attirer "
		"l'œil sans briller), une branche cassée, un champignon ; 1 case de long × 0,6 de haut "
		"(≈ 200 × 120 px). 2 (ligne 1, à droite) : INDICE JONCS, une touffe de JONCS de berge un peu "
		"jaunis et couchés d'un côté, plus clairs que les roseaux verts joints, posée sur la terre ; 1 "
		"case (≈ 200 px), environ 1 case de haut. Les deux indices sont discrets mais lisibles, comme "
		"les indices joints WORLD_PROP_INDICES_PLANCHE.\n"
		"3 (ligne 2, à gauche) : NÉNUPHARS A, un petit groupe de trois feuilles de nénuphar vert frais "
		"posées à plat, une fleur blanc rosé ; environ 1 case (≈ 200 px), à plat. 4 (ligne 2, à droite) : "
		"NÉNUPHARS B, deux feuilles seulement, plus petites, sans fleur ; environ 0,6 case (≈ 120 px), à "
		"plat. Aucune eau dessinée autour des nénuphars.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune eau, aucune ombre portée.",
		[TRONC, INDICES, BERGES], LUMIERE_NE, 1),
	("WORLD_RELIEF_MUR_SOUTERRAIN_PLANCHE", ["REF_SO_MUR", "REF_SO_ANGLE", "REF_SO_GALERIE"],
		"PLANCHE de 6 MODULES DE MUR MAÇONNÉ du passage souterrain (les murs de pierre taillée qui "
		"bordent la galerie, entre le sol dallé et la roche brute) dans une image 1536 × 1024 : grille "
		"invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), un module par cellule, centré, à "
		"une échelle COMMUNE de 1 case = 200 px, tous vus de dessus en trois quarts. Matière : gros "
		"BLOCS DE PIERRE TAILLÉE gris-beige appareillés en assises régulières, joints fins, arêtes un "
		"peu usées, couronnement de pierre plus claire vu de dessus ; ancien, solide et propre ; même "
		"finesse que la planche de parois jointe WORLD_RELIEF_PAROI_GROTTE_PLANCHE (gabarit des rôles ; "
		"ici de la maçonnerie, pas de la roche brute) ; ANGLES DROITS, chaque module se raccorde bout à "
		"bout avec son semblable.\n"
		"1 (ligne 1, à gauche) : MUR AU NORD A, le sol est AU SUD : le couronnement vu de dessus en haut, "
		"puis la FACE du mur (trois assises de blocs) qui descend jusqu'au sol en bas ; 2 cases de long "
		"× 1 de haut (≈ 400 × 200 px). 2 (ligne 1, au milieu) : MUR AU NORD B, même gabarit, blocs "
		"différents, un bloc plus sombre, un peu de mousse dans un joint. 3 (ligne 1, à droite) : BORD "
		"SUD, le sol est AU NORD : seul le couronnement vu de dessus (on ne voit pas la face du mur, "
		"tournée vers le bas) ; 2 cases de long × 0,35 de haut (≈ 400 × 70 px).\n"
		"4 (ligne 2, à gauche) : BORD DE CÔTÉ, le sol est À DROITE : le couronnement vu de dessus en "
		"bande verticale ; 0,35 case de large × 2 de long (≈ 70 × 400 px). 5 (ligne 2, au milieu) : "
		"ANGLE EXTÉRIEUR, le sol est au SUD et À DROITE : un bloc d'angle, couronnement en équerre et "
		"face en bas ; 0,35 × 1 case (≈ 70 × 200 px). 6 (ligne 2, à droite) : ANGLE INTÉRIEUR, le sol ne "
		"touche que le coin en bas à droite : un petit bloc carré de couronnement ; 0,35 × 0,35 case "
		"(≈ 70 × 70 px).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune roche brute autour, aucune "
		"applique, aucune ombre portée.",
		[PAROI_GROTTE, MASSE_ROCHE], VALEURS_PIERRE, 1),
	("WORLD_PROP_SOUTERRAIN_PLANCHE", ["REF_SO_ESCALIER_N", "REF_SO_STELE", "REF_SO_PIERRE", "REF_SO_BANC",
			"REF_SO_APPLIQUE"],
		"PLANCHE de 6 ÉLÉMENTS du passage souterrain dans une image 1536 × 1024 : grille invisible de 3 "
		"colonnes × 2 lignes (cellules de 512 × 512), un élément par cellule, centré, à une échelle "
		"COMMUNE de 1 case = 200 px, tous vus de dessus en trois quarts ; même pierre taillée gris-beige "
		"ancienne que les murs du souterrain.\n"
		"1 (ligne 1, à gauche) : ESCALIER MONTANT, un escalier de pierre de 2 cases de large qui MONTE "
		"vers le haut de l'image (vers la sortie nord) : six marches vues de dessus dont les nez "
		"s'éclaircissent vers le haut, deux murets latéraux de pierre ; 2 × 1,3 cases (≈ 400 × 260 px). "
		"2 (ligne 1, au milieu) : ESCALIER DESCENDANT, le même escalier vu dans l'autre sens, qui part du "
		"sol de la galerie en haut et DESCEND vers le bas de l'image (vers la sortie sud) : on voit le "
		"dessus des marches qui s'enfoncent ; 2 × 1,3 cases (≈ 400 × 260 px). 3 (ligne 1, à droite) : "
		"STÈLE GRAVÉE, une stèle de pierre dressée aux angles adoucis, gravée d'un motif ancien de "
		"VAGUES et de SPIRALES (aucune lettre, aucun chiffre, aucun cercle partagé en deux) ; 1 case de "
		"large (≈ 200 px), environ 1,4 case de haut.\n"
		"4 (ligne 2, à gauche) : BANC DE PIERRE, un banc bas et court de pierre taillée sur deux pieds, "
		"vu de face ; 1 case de large (≈ 200 px), 0,6 de haut. 5 (ligne 2, au milieu) : PIERRE "
		"DESCELLÉE, un morceau de MUR maçonné d'une case (même face de mur que la planche des murs) dont "
		"UN bloc, au milieu, est un peu SORTI de son logement, de travers, avec un liseré de poussière "
		"claire et un joint ouvert : l'indice discret d'une cachette ; 1 × 1 case (≈ 200 × 200 px). 6 "
		"(ligne 2, à droite) : APPLIQUE MURALE, une lanterne de fer forgé noir fixée au mur par une "
		"potence, verre AMBRÉ peint dans sa couleur propre, SANS halo, sans rayons, sans lueur autour "
		"(le jeu l'allume) ; 0,45 case de large × 0,8 de haut (≈ 90 × 160 px).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée, aucune flaque "
		"de lumière.",
		[ECHELLES, INDICES, MASSE_ROCHE], VALEURS_PIERRE, 1),
	("INT_J15_PLANCHE", [],
		"PLANCHE de 6 MEUBLES d'intérieur (Pension Pokémon, bâtiments d'entrée du souterrain, Fan Club "
		"de Carmin) dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
		"512 × 512), un meuble par cellule, centré, la base de chacun sur une même ligne horizontale à "
		"30 px du bas de sa cellule, à une échelle COMMUNE de 1 case = 150 px. Vue de dessus en trois "
		"quarts : on voit le dessus et la face avant, jamais les côtés.\n"
		"1 (ligne 1, à gauche) : COMPTOIR DE LA PENSION, un comptoir de bois miel chaleureux de 3 cases "
		"de large (≈ 450 px), 1 case de profondeur, plateau sur lequel sont posés un grand REGISTRE "
		"ouvert (pages crème sans écriture lisible), une petite clochette de comptoir dorée et un bocal "
		"de BAIES colorées ; face avant à panneaux, même main que le comptoir joint INT_LONG_COMPTOIR_01. "
		"2 (ligne 1, au milieu) : ESCALIER DESCENDANT d'intérieur, une large ouverture dans le dallage "
		"d'où un escalier de pierre claire de 2 cases de large (≈ 300 px) DESCEND vers le bas de l'image "
		"et se perd dans une ombre bleu-gris, bordé d'une rambarde de fer noir sur les deux côtés et "
		"derrière ; environ 1,6 case de profondeur. 3 (ligne 1, à droite) : PANIER-COUCHETTE pour Pokémon, "
		"un grand panier d'osier rond et bas garni d'un coussin vert sauge (vide) ; 1 case (≈ 150 px).\n"
		"4 (ligne 2, à gauche) : FAUTEUIL DU PRÉSIDENT, un fauteuil club de velours bordeaux capitonné "
		"aux accoudoirs ronds, pieds de bois tourné, un petit coussin crème ; 1,2 case de large (≈ 180 px), "
		"environ 1,3 de haut. 5 (ligne 2, au milieu) : VITRINE DES RUBANS, une vitrine de bois sombre "
		"vitrée de 2 cases de large (≈ 300 px), environ 2 cases de haut, où sont exposées des ROSETTES de "
		"ruban (rouge, bleu, or), deux petites coupes dorées et des médailles de concours sur coussin "
		"(rubans et coupes, aucun cercle partagé en deux, aucune écriture). 6 (ligne 2, à droite) : "
		"TABLEAU MURAL, un grand cadre doré mouluré contenant une peinture d'un PORT au soleil (quai, "
		"voiliers, mer bleue), sans personnage ni Pokémon ; 1,5 case de large (≈ 225 px), environ 1 de "
		"haut.\n"
		"Même rendu que les meubles joints INT_LONG_COMPTOIR_01, INT_CANAPE_01 et INT_GRANDE_ETAGERE_01 "
		"(même main, même angle) ; fond avec une vraie transparence (canal alpha), aucun sol, aucun "
		"tapis, aucune ombre portée.",
		[COMPTOIR, CANAPE, ETAGERE], LUMIERE_NE, 1),
]

## Coques conditionnelles : (identifiant, largeur, profondeur, ancres, géométrie, matériaux).
_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus.")
COQUES_COND = [
	("INT_FAN_CLUB_COQUE", 15, 10, ["INT_MAISON_ARGENTA_COQUE_NE_r1.png", "WORLD_BLDG_FAN_CLUB_01_NE_r1.png"],
		"Format : PNG paysage 1536 × 1024, opaque ; la pièce fait 15 cases de large × 10 de profondeur "
		"(la préparation l'étire à 1 440 × 960 : 1 case = 96 px). " + _BASE_COQUE + " Face avant du mur "
		"du fond sur les 2 cases du haut ; épaisseur des murs latéraux ≈ 48 px ; mur du bas ≈ 60 px, "
		"interrompu au milieu par l'ENTRÉE : une ouverture de 2 cases exactement centrée, paillasson vert "
		"uni. Le mur du fond porte trois grands cadres dorés vides de peinture (toiles unies crème) et "
		"des appliques de laiton éteintes. Tout le sol est un PARQUET à chevrons de bois miel, LIBRE et "
		"VIDE (aucun meuble).",
		"le salon du Fan Club de Carmin-sur-Mer, un club cossu : boiseries vert sapin et papier peint "
		"crème à fines rayures, plinthes de bois sombre, mêmes matériaux que la façade jointe "
		"WORLD_BLDG_FAN_CLUB_01."),
]

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenues = défauts (règle 4).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_MARIN", [], 128, "un marin de l'équipage du S.S. Anne, qui garde la passerelle",
		"un MARIN d'équipage de paquebot d'environ 25 ans, droit et aimable : VAREUSE BLANCHE à grand "
		"COL MARIN bleu marine bordé de deux liserés blancs, petit foulard rouge noué, pantalon bleu "
		"marine à pont, chaussures noires cirées, BONNET DE MATELOT blanc (bachi sans pompon), cheveux "
		"bruns courts, teint hâlé. Taille d'un adulte. Différent du héros, du garde joint (ni uniforme "
		"bleu de garde, ni képi) et du pêcheur joint ; aucun insigne lisible, aucun texte.",
		f"{PIEDS_JOINTS}, les mains croisées dans le dos, l'air sérieux mais accueillant", [GARDE, PECHEUR], 1),
	("PNJ_DOCKER", [], 128, "un docker du port de Carmin-sur-Mer",
		"un DOCKER d'environ 35 ans, costaud et bonhomme : BONNET DE LAINE gris roulé, barbe courte "
		"châtain, gros PULL MARIN vert-de-gris aux manches retroussées, SALOPETTE de toile ocre brun, "
		"GANTS de cuir épais, grosses bottes de travail brun foncé, un rouleau de corde passé sur "
		"l'épaule gauche. Un peu plus large qu'un adulte ordinaire, même hauteur. Différent du héros, "
		"du pêcheur joint (ni ciré jaune ni chapeau) et du montagnard ; aucun texte.",
		f"{PIEDS_JOINTS}, les poings sur les hanches, l'air content de sa journée", [PECHEUR], 1),
	("PNJ_PRESIDENT_FAN_CLUB", [], 128, "le président du Fan Club Pokémon de Carmin-sur-Mer",
		"le PRÉSIDENT DU FAN CLUB, un monsieur d'environ 65 ans, rond, jovial et intarissable : "
		"MOUSTACHE blanche en guidon, crâne dégarni et couronne de cheveux blancs, joues roses, petites "
		"lunettes rondes cerclées d'or ; COSTUME TROIS PIÈCES bordeaux, gilet assorti avec la chaîne "
		"dorée d'une montre à gousset, chemise blanche, NŒUD PAPILLON vert sapin, une ROSETTE de ruban "
		"rouge et or à la boutonnière, chaussures vernies. Plus petit et plus rond que le héros. Différent "
		"du vieil homme joint (ni gilet de laine, ni canne) et du professeur Chen ; aucun texte.",
		f"{PIEDS_JOINTS}, une main sur le ventre et l'autre levée comme s'il racontait une histoire, l'air "
		"ravi", [VIEIL_HOMME], 1),
	("PNJ_GARDIEN_PENSION", [], 128, "le gardien de la Pension Pokémon de la Route 5",
		"le GARDIEN DE LA PENSION, un vieux monsieur d'environ 70 ans, doux et souriant, qui passe ses "
		"journées au jardin avec les Pokémon : CHAPEAU DE PAILLE à ruban vert, cheveux et sourcils blancs "
		"broussailleux, petite barbe blanche ; SALOPETTE de jardinier vert olive sur une chemise crème "
		"aux manches roulées, foulard rouge au cou, une paire de gants de jardin dans la poche avant, "
		"bottes de caoutchouc vert foncé. Un peu voûté, plus petit que le héros. Différent du vieil homme "
		"joint (ni gilet de laine, ni canne) ; aucun texte.",
		f"{PIEDS_JOINTS}, les mains jointes devant lui, l'air bienveillant", [VIEIL_HOMME], 1),
]

## Planche d'icônes du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE : 4 colonnes).
UI = ("UI_OBJETS_J15_PLANCHE",
	"PLANCHE de DEUX icônes d'objets peintes pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : une icône CENTRÉE dans chacune des DEUX PREMIÈRES colonnes (x de 0 à "
	"384, puis de 384 à 768), chacune de 260 px de large au plus et 260 px de haut au plus, avec au moins "
	"60 px de marge vide de chaque côté ; les deux dernières colonnes restent VIDES (transparentes) ; "
	"dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE et de l'icône jointe de la Potion "
	"(même rendu, même angle de trois quarts, même lumière).\n"
	"1 (colonne 1) : la SUPER POTION, le MÊME flacon vaporisateur que la Potion jointe (même forme, même "
	"taille, même gâchette) mais au liquide et au corps VIOLET-MAGENTA, gâchette et bouchon crème.\n"
	"2 (colonne 2) : la GUÉRISON, le même flacon vaporisateur au corps JAUNE D'OR lumineux, gâchette et "
	"bouchon blancs, une fine bande verte autour du col : l'objet de soin le plus précieux.\n"
	"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec "
	"seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).",
	[MENU_OBJETS, "assets/ui/items/potion.webp"], 1)

## Conditionnels.
SERIE_COND = [
	("WORLD_BLDG_MAISON_COTIERE_01", "REF_CA_MAISON", 7, 6,
		"une MAISON D'HABITANTS de Carmin-sur-Mer, façade de face (base de 7 cases de large, environ 6 "
		"cases de haut avec le toit), même gabarit et même main que la maison jointe "
		"WORLD_BLDG_MAISON_ARGENTA_01 (toit de tuiles ORANGE, porte au milieu exact du bas, 4e colonne "
		"sur 7) mais d'une autre silhouette : un étage, deux lucarnes, volets bleu ciel, une jardinière "
		"de géraniums sous chaque fenêtre. Sans panneau, aucune inscription.",
		[MAISON_ARGENTA], LUMIERE_NE),
]

## Décor de combat (chaîne des décors de combat, tools/art/combat_decors/) : (identifiant, images
## jointes dans l'ordre, texte). Plan §1.4 : `route_5_6_prairie`, partagé par les deux routes [D].
DECOR_COMBAT = ("COMBAT_DECOR_ROUTE5_6_PRAIRIE_r1",
	["docs/design/reference/combat-v1.webp", "docs/design/reference/combat-decors-planche-v1.webp",
		"docs/design/reference/route-6-vue-generale-v1.png"],
	"DÉCOR DE COMBAT — ROUTES 5 ET 6, PRAIRIE ENTRE AZURIA ET CARMIN-SUR-MER (Kanto 2026). Image de "
	"PRODUCTION : le fond peint d'un écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, "
	"AUCUN personnage, AUCUNE interface, AUCUN texte.\n\n"
	"Images jointes.\n"
	"IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement "
	"plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité de "
	"peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le coucher "
	"de soleil orange.\n"
	"IMAGE 2 : une planche d'intention de décors de combat (guide de facture).\n"
	"IMAGE 3 : la vue générale (de dessus) de la Route 6 : prairie fleurie, chemin de terre clair, "
	"forêt dense de feuillus, hautes herbes jaune-vert, petit étang (guide de palette).\n\n"
	"FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution "
	"possible, OPAQUE, cadrage plein, sans bord.\n\n"
	"LIEU : une prairie verdoyante et fleurie au sud d'Azuria, entre deux lisières de forêt. Sol d'herbe "
	"courte vert tendre et de terre battue claire, petites fleurs sauvages blanches, roses et jaunes ; "
	"derrière, des massifs de feuillus ronds vert profond et quelques touffes de hautes herbes. Golden "
	"hour. Aucun bâtiment, aucune clôture, aucun panneau, aucune eau.\n\n"
	"COMPOSITION (fractions depuis le coin haut gauche) :\n"
	"- Horizon vers 33 % de la hauteur : à GAUCHE, une lisière de forêt dense en plan moyen ; au CENTRE "
	"et à DROITE, la prairie s'éloigne vers des collines douces vert-bleu et un ciel clair ; un grand "
	"feuillu isolé en plan moyen à droite (x 75 à 90 %), pas plus haut que 35 % de la hauteur.\n"
	"- De 45 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT d'herbe courte et de terre "
	"battue, un sentier clair qui arrive du bas et s'éloigne.\n"
	"- Point A (x 67 %, y 55 %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien de "
	"haut dans un rayon de 12 % de la largeur autour.\n"
	"- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier plan. "
	"Rien de haut autour.\n"
	"- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de "
	"détails et peu de contraste, valeurs simples.\n"
	"- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol "
	"simple, presque sans objet, valeurs moyennes, sans contraste fort.\n"
	"- Les deux coins du bas restent du SOL nu : pas de buisson ni de gros objet en gros plan.\n"
	"- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur "
	"certains écrans).\n\n"
	"LUMIÈRE : golden hour, soleil bas venant du haut à gauche (hors cadre), lumière dorée chaude sur "
	"l'herbe et les feuillages, ombres douces, lointains froids bleutés ; ciel bleu pâle voilé, nuages "
	"légers teintés de rose doré, pas de soleil visible, pas de contre-jour.\n\n"
	"RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D "
	"peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni "
	"en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches "
	"sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à "
	"hauteur d'yeux, un peu plongeante, le sol recule nettement vers l'horizon.\n\n"
	"INTERDITS : Pokémon, animal, oiseau, mouette, personnage, silhouette, texte, lettres, chiffres, "
	"panneau lisible, logo, signature, filigrane, cadre, interface, bâtiment, maison, poste, clôture, "
	"étang, eau, mer, bateau, grue, route goudronnée, véhicule, pixel art, flou, vignettage.\n")

## Corrections (T9) : (identifiant sans _NE_rN, révision) → texte qui remplace la description
## d'origine (planche, coque ou décor). Vide au T8.
CORRECTIONS: dict[tuple[str, int], str] = {}

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées "
		"de Carmin-sur-Mer, de la Route 6 et du passage souterrain (minuscules, ambiance dorée ou "
		"souterraine : n'en copie ni le rendu ni la lumière) ; ")


def _prompt_texture(identifiant: str, ref: str, description: str, ancres: list[str],
		valeurs: str) -> str:
	jointes = (f"Images jointes : {ref} = matériau et couleurs, extrait d'une vue d'ensemble validée "
		f"(minuscule : n'en copie pas le rendu) ; {_noms(STYLE + ancres)} = ancres de style (rendu peint, "
		"finesse, lumière neutre).")
	return (f"{identifiant} — NOUVELLE image : une texture de sol de jeu, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\nASSET : {description}\n{TEXTURE_FIN}\n{INTERDITS}\n")


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
	format_ = FORMATS.get(identifiant, "Format : PNG paysage 1536 × 1024 ; l'élément occupe environ "
		"1 300 px dans sa plus grande dimension, centré")
	corps = (f"ASSET : {description}\n{format_}. Échelle : {largeur} cases de large et environ {hauteur} "
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
		"(rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre) "
		"et matériaux de la façade : respecte-les exactement.\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		"trois quarts, image opaque qui remplit tout le cadre.\n"
		f"Géométrie (respecte-la exactement, c'est un plan de jeu) : {geometrie}\n"
		f"Pièce : {materiaux}\n"
		"Interdit : meubles, vitrines, fauteuils, plantes, tapis (sauf le paillasson demandé), "
		"personnages, Pokémon (ni Pikachu), porte fermée, marche ou escalier d'entrée, flaques de lumière "
		"peintes au sol, texte, lettres, chiffres, logo, emblème rond de type balle, perspective avec "
		"point de fuite, vue isométrique, ombre portée.\n")


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
	"""Modèle des attentes des séries 10–16."""
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
	$ART, ou chemins relatifs à la racine quand ils contiennent « / »), vague, conditionnel, groupe."""
	images = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, ref, description, ancres_, valeurs, vague in SOLS:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres_, valeurs),
			[f"{ref}.png"] + STYLE + ancres_, vague, groupe=ident)
	for ident, ref, description, ancres_, valeurs in SOLS_COND:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres_, valeurs),
			[f"{ref}.png"] + STYLE + ancres_, 2, True, groupe=ident)
	for liste, conditionnel in ((SERIE + SERIE_VAGUE2, False), ([(*t, 2) for t in SERIE_COND], True)):
		for ident, ref, largeur, hauteur, description, ancres_, valeurs, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur,
				description, ancres_, valeurs), ([f"{ref}.png"] if ref else []) + STYLE + ancres_, vague,
				conditionnel, groupe=ident)
	for ident, refs, description, ancres_, valeurs, vague in PLANCHES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_, valeurs),
			[f"{r}.png" for r in refs] + ancres_, vague, groupe=ident)
	for ident, _largeur, _profondeur, ancres_, geometrie, materiaux in COQUES_COND:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_coque(ident, geometrie, materiaux, ancres_),
			ancres_, 2, True, groupe=ident)
	for ident, refs, hauteur, role, tenue, pose, ancres_, vague in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres_),
			[HEROS] + [f"{r}.png" for r in refs] + ancres_, vague, groupe=ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1,
			groupe=ident)
	ident, description, ancres_, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres_), vague, groupe=ident)
	ident, jointes, texte = DECOR_COMBAT
	ajouter(ident, DECORS_COMBAT / f"{ident}.txt", texte, jointes, 1, groupe=ident.rsplit("_", 1)[0])
	for (ident, rev), description in CORRECTIONS.items():
		nom = f"{ident}_NE_r{rev}"
		groupe = f"{ident}_r{rev}"
		base = next((t for t in PLANCHES if t[0] == ident), None)
		if base is not None:
			_, refs, _, ancres_, valeurs, _ = base
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_,
				valeurs), [f"{r}.png" for r in refs] + ancres_, 3, True, groupe=groupe)
			continue
		objet = next((t for t in SERIE + SERIE_VAGUE2 if t[0] == ident), None)
		if objet is not None:
			_, ref, largeur, hauteur, _, ancres_, valeurs, _ = objet
			precedent = f"{ident}_NE_r{rev - 1}.png"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
				[precedent] + ancres_, valeurs), [f"{ref}.png", precedent] + STYLE + ancres_, 3, True,
				groupe=groupe)
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
	print(f"{len(REFS)} références REF_CA_*, REF_R6_*, REF_SO_*, REF_R5_* dans {ART}")


def _jointes_art() -> set[str]:
	generees = {i["nom"] + ".png" for i in _images()}
	return {j for i in _images() for j in i["jointes"]
		if "/" not in j and not j.startswith("REF_") and j not in generees}


def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	manquantes = []
	sources = _sources_ancres()
	for nom in sorted(set(ANCRES) | _jointes_art()):
		if (ART / nom).exists():
			continue
		source = next((s / nom for s in sources if (s / nom).exists()), None)
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


# --- Manifeste (T11) --------------------------------------------------------------------

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


def _batiment(ident: str, base: str, cases: float, dossier: str = "buildings", ombre: bool = True,
		contact: float | None = 0.12) -> dict:
	return {"id": ident, "source": _revision(base), "sortie": f"{_W}{dossier}/{ident}.png", "axe": "w",
		"cases": cases, "ombre": ombre, "contact": contact}


## Rôles des modules (fiche, §« Alignement ») ; ordre de lecture des planches.
QUAI_BOIS_IDS = ["relief_quai_bois_01", "relief_quai_bois_02", "relief_quai_bois_03",
	"relief_quai_bois_04", "relief_quai_bois_05", "prop_pieu_quai_01"]
CARMIN_IDS = ["prop_jeune_arbre_arene_01", "prop_passerelle_01", "prop_grue_quai_01",
	"prop_bitte_amarre_01", "prop_cordage_01", "prop_caisses_port_01"]
ROUTES_IDS = ["prop_indice_tronc_01", "prop_indice_joncs_01", "prop_nenuphars_01",
	"prop_nenuphars_02"]
MUR_SO_IDS = ["relief_mur_souterrain_01", "relief_mur_souterrain_02", "relief_mur_souterrain_03",
	"relief_mur_souterrain_04", "relief_mur_souterrain_05", "relief_mur_souterrain_06"]
SOUTERRAIN_IDS = ["prop_escalier_souterrain_monte_01", "prop_escalier_souterrain_descend_01",
	"prop_stele_01", "prop_banc_souterrain_01", "prop_pierre_descellee_01", "prop_applique_01"]
INT_IDS = ["int_comptoir_pension_01", "int_escalier_descendant_01", "int_panier_pokemon_01",
	"int_fauteuil_president_01", "int_vitrine_rubans_01", "int_tableau_port_01"]
NAVIRE_IDS = ["bldg_ss_anne_proue_01", "bldg_ss_anne_milieu_01", "bldg_ss_anne_poupe_01"]


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T11 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T11 sur la planche de contrôle. `cases` = largeur en cases de chaque élément."""
	return {
		"objets": [
			_batiment("bldg_pension_01", "WORLD_BLDG_PENSION_01_NE", 7),
			_batiment("bldg_poste_safrania_01", "WORLD_BLDG_POSTE_SAFRANIA_01_NE", 7),
			_batiment("bldg_entree_souterrain_01", "WORLD_BLDG_ENTREE_SOUTERRAIN_01_NE", 7),
			_batiment("bldg_arene_carmin_01", "WORLD_BLDG_ARENE_CARMIN_01_NE", 12),
			_batiment("bldg_fan_club_01", "WORLD_BLDG_FAN_CLUB_01_NE", 8),
			_batiment("bldg_maison_pecheur_01", "WORLD_BLDG_MAISON_PECHEUR_01_NE", 7),
			# Navire : trois tranches sur la mer, sans ombre portée ni de contact (le jeu pose un
			# reflet / une ligne d'eau) ; un seul nœud parent sous la condition `ss_anne_departed`.
			_batiment("bldg_ss_anne_proue_01", "WORLD_BLDG_SS_ANNE_PROUE_NE", 10, ombre=False,
				contact=None),
			_batiment("bldg_ss_anne_milieu_01", "WORLD_BLDG_SS_ANNE_MILIEU_NE", 9, ombre=False,
				contact=None),
			_batiment("bldg_ss_anne_poupe_01", "WORLD_BLDG_SS_ANNE_POUPE_NE", 10, ombre=False,
				contact=None),
			_batiment("prop_vue_port_01", "WORLD_PROP_VUE_PORT_01_NE", 4, "props", ombre=False,
				contact=None),
		],
		"sols": [
			{"id": "ground_planches_quai_01", "source": _revision("WORLD_GROUND_PLANCHES_QUAI_01_NE"),
				"sortie": f"{_W}ground/ground_planches_quai_01.png", "taille": 384, "contraste": 1.0,
				"couleur": 1.0, "raccord": 24},
			{"id": "ground_dalles_souterrain_01",
				"source": _revision("WORLD_GROUND_DALLES_SOUTERRAIN_01_NE"),
				"sortie": f"{_W}ground/ground_dalles_souterrain_01.png", "taille": 384,
				"contraste": 1.0, "couleur": 1.0, "raccord": 24},
			{"id": "ground_traces_souterrain_01",
				"source": _revision("WORLD_GROUND_TRACES_SOUTERRAIN_01_NE"),
				"sortie": f"{_W}ground/ground_traces_souterrain_01.png", "taille": 384,
				"contraste": 1.0, "couleur": 1.0, "raccord": 24},
		],
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_QUAI_BOIS_PLANCHE_NE", "relief", 3, 2, QUAI_BOIS_IDS,
				[2, 2, 0.25, 2, 0.5, 0.4], 0.0),
			_planche_objets("WORLD_PROP_CARMIN_PLANCHE_NE", "props", 3, 2, CARMIN_IDS,
				[2, 2, 2, 1, 0.8, 2], 0.15),
			_planche_objets("WORLD_PROP_ROUTES_J15_PLANCHE_NE", "props", 2, 2, ROUTES_IDS,
				[1, 1, 1, 0.6], 0.1),
			_planche_objets("WORLD_RELIEF_MUR_SOUTERRAIN_PLANCHE_NE", "relief", 3, 2, MUR_SO_IDS,
				[2, 2, 2, 0.35, 0.35, 0.35], 0.0),
			_planche_objets("WORLD_PROP_SOUTERRAIN_PLANCHE_NE", "props", 3, 2, SOUTERRAIN_IDS,
				[2, 2, 1, 1, 1, 0.45], 0.1),
			_planche_objets("INT_J15_PLANCHE_NE", "interiors", 3, 2, INT_IDS,
				[3, 2, 1, 1.2, 2, 1.5], 0.2),
		],
		"personnages": [
			{"id": nom, "source": _revision(f"PNJ_{ident}_NE"), "sortie": f"{_C}{nom}_sheet.png",
				"hauteur": 128} for nom, ident, _ in _PERSOS
		],
		"attentes": [
			{"id": f"{nom}_idle", "source": _revision(f"{ident}_ATTENTE"),
				"sortie": f"{_C}{nom}_idle_sheet.png", "marche": nom} for nom, ident, _ in _PERSOS
		],
	}


## (planche préparée, identifiant de fiche, look du jeu) ; looks en fin de LOOKS au T11.
_PERSOS = [("marin", "MARIN", "sailor"), ("docker", "DOCKER", "docker"),
	("president_fan_club", "PRESIDENT_FAN_CLUB", "fan_club_chairman"),
	("gardien_pension", "GARDIEN_PENSION", "daycare_keeper")]
PERSONNAGES_JEU = [(nom, look, 128) for nom, _, look in _PERSOS]
## Icônes du Sac (T11, `preparer_menu.py` : planche de 4 colonnes, les 2 premières occupées) →
## `assets/ui/items/super_potion.webp`, `full_restore.webp`.
ICONES_IDS = ["super_potion", "full_restore"]


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 16) ; une section absente est créée en fin de fichier."""
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
	print(f"manifeste : {ajouts} entrée(s) de la série 17 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------


def _ref(nom: str, cases_haut: float | None = None, hauteur: int | None = None) -> Image.Image:
	image = _recadrage(nom).convert("RGBA")
	if hauteur is None:
		vue, _ = REFS[nom]
		hauteur = round(image.height / PX_CASE[vue] * CASE_PLANCHE) if cases_haut is None else round(
			cases_haut * CASE_PLANCHE)
	return _echelle(image, max(1, hauteur) / image.height)


def _si(relatif: str, etiquette: str, fonction=_asset):
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def _sol(nom: str, role: str) -> tuple[Image.Image, str]:
	image = Image.open(RACINE / f"{_W}ground/{nom}.png").convert("RGBA").crop((0, 0, 192, 192))
	return (_echelle(image, 0.5), f"{nom}\n{role}")


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso(f"{_C}heros_sheet.png"), "héros (échelle)")
	w, c = _W, _C
	p = _Planche(2800, "Routes 5 et 6, souterrain, Carmin-sur-Mer — kit de la série 17 (T8, jalon 15) : "
		"1 case = 48 px ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS — extérieurs", [
		heros,
		(_asset(f"{w}buildings/bldg_centre_01.png"), "Centre C\n(Carmin)"),
		(_asset(f"{w}buildings/bldg_boutique_01.png"), "Boutique O\n(Carmin)"),
		(_asset(f"{w}buildings/bldg_maison_argenta_01.png"), "maison d'Argenta\nmaisons 1 et 2 (m)"),
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 5)],
		(_asset(f"{w}props/tree_a_01.png"), "tree_a_01\ngrands arbres G"),
		(_asset(f"{w}props/prop_buisson_a_01.png"), "buissons x"),
		(_asset(f"{w}props/prop_rocher_01.png"), "rochers R\n(Route 6)"),
		(_asset(f"{w}props/prop_cloture_01.png"), "clôture c\n(jardin, Route 6)"),
		(_asset(f"{w}props/prop_cloture_v_01.png"), "clôture v\n(jardin)"),
		(_asset(f"{w}props/prop_platebande_01.png"), "plate-bande\njardin j"),
		(_asset(f"{w}props/prop_massif_01.png"), "massif\njardin j"),
		(_asset(f"{w}props/prop_hortensias_01.png"), "hortensias\njardin j"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneaux"),
		(_asset(f"{w}props/prop_banc_01.png"), "bancs n\n(place)"),
		*_si(f"{w}props/prop_bitte_01.png", "bitte z (s. 15)"),
		*_si(f"{w}props/prop_lampadaire_quai_01.png", "lampadaire\nde quai (s. 15)"),
		*_si(f"{w}props/prop_pont_pepite_pile_01.png", "pile (s. 15)\nbout de ponton"),
		*_si(f"{w}relief/relief_berge_01.png", "berges (s. 15)\nétang"),
		*_si(f"{w}relief/prop_roseaux_01.png", "roseaux (s. 15)\nétang"),
		(_asset(f"{w}props/prop_caisses_01.png"), "caisses"),
		(_asset(f"{w}props/prop_tonneau_01.png"), "tonneau"),
		(_asset(f"{w}props/prop_casiers_peche_01.png"), "casiers\n(Pêcheur)"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball\nO1"),
	], (40, 90, 50))
	p.section("1 bis. SOLS RÉUTILISÉS (extrait 2 × 2 cases)", [
		_sol("ground_herbe_01", "herbe ."), _sol("ground_chemin_01", "chemin, rue ="),
		_sol("ground_paves_01", "place p"), _sol("ground_eau_01", "mer W (assombrie)"),
		_sol("ground_eau_canal_01", "étang W (s. 15)"),
		_sol("ground_masse_roche_01", "roche autour\ndu souterrain (s. 14)"),
		(_echelle(Image.open(RACINE / f"{w}ground/ground_hautes_herbes_01.png").convert("RGBA"), 0.5),
			"hautes herbes h"),
	], (40, 90, 50))
	p.section("1 ter. INTÉRIEURS RÉUTILISÉS (coques réduites × 0,25)", [
		heros,
		(_echelle(_asset(f"{w}interiors/int_maison_argenta_coque.png"), 0.5),
			"maison d'Argenta : Pension, Fan Club,\nPêcheur, maisons 1 et 2"),
		(_echelle(_asset(f"{w}interiors/int_poste_foret_coque.png"), 0.5),
			"poste de la forêt : poste R5,\nentrées du souterrain ×2"),
		(_asset(f"{w}interiors/int_long_comptoir_01.png"), "long comptoir\n(repli Pension)"),
		(_asset(f"{w}interiors/int_plante.png"), "plantes"),
		(_asset(f"{w}interiors/int_petite_etagere_01.png"), "meuble bas\n(5, 2) poste R5"),
		(_asset(f"{w}interiors/int_canape_01.png"), "canapé\n(Fan Club)"),
	], (40, 90, 50))
	persos = [("vieil_homme", "old_man : vieil\nhabitant (Carmin)"), ("garde", "guard : 2 gardes"),
		("dresseuse", "lass : Chloé, Manon,\nhabitante"), ("campeur", "camper : Gabin,\nMathis"),
		("scout", "scout : Axel, Basile"), ("infirmiere", "nurse"), ("marchand", "clerk"),
		("pecheur", "haru : Pêcheur,\npêcheur R6"), ("voyageur", "traveler : voyageur,\npromeneur"),
		("randonneuse", "hiker : promeneuse\nR5"), ("enfant", "kid : enfant\n(Carmin)")]
	p.section("1 quater. PERSONNAGES RÉUTILISÉS", [heros, *[x for nom, etiquette in persos
		for x in _si(f"{c}{nom}_sheet.png", etiquette, _cellule_perso)]], (40, 90, 50))

	p.section("2. VARIATIONS SANS NOUVEL ASSET", [
		(_ref("REF_CA_MER", hauteur=96), "mer du port : ground_eau_01\nassombrie (Shade)"),
		(_miroir(_asset(f"{w}buildings/bldg_maison_argenta_01.png")), "maison 2 en miroir\n(porte centrée)"),
		(_ref("REF_SO_ROCHE", hauteur=150), "roche brute : masse_roche\nassombrie (profil underground)"),
	], (110, 90, 40))
	p.section("3. NOUVEAUX : BÂTIMENTS (référence recadrée à la taille en jeu)", [
		heros,
		(_ref("REF_R5_PENSION", 6), "BLDG_PENSION_01 7 × 6\n(plan seul : à recaler\nsur la vue Route 5)"),
		(_ref("REF_R6_POSTE", 4.5), "BLDG_POSTE_SAFRANIA_01\n7 × 4 (R5) / 7 × 3 (R6)"),
		(_ref("REF_R6_SORTIE", 4), "BLDG_ENTREE_SOUTERRAIN_01\n7 × 4 (R5) / 7 × 3 (R6)"),
		(_ref("REF_CA_ARENE", 7), "BLDG_ARENE_CARMIN_01 12 × 7\n(sans l'arbre)"),
		(_ref("REF_CA_FAN_CLUB", 6), "BLDG_FAN_CLUB_01 8 × 6"),
		(_ref("REF_CA_PECHEUR", 6), "BLDG_MAISON_PECHEUR_01 7 × 6"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : PORT ET S.S. ANNE (29 × 7 cases : guide + 3 tranches)", [
		heros,
		(_ref("REF_CA_NAVIRE", 8), "SS_ANNE_GUIDE (v1) puis PROUE 10,\nMILIEU 9, POUPE 10 (v2)"),
		(_ref("REF_CA_QUAI_BORD", 2), "QUAI_BOIS_PLANCHE\n(bords, bout de ponton, pieu)"),
		(_ref("REF_CA_PONTON", 9), "pontons 2 × 9"),
		(_ref("REF_CA_QUAI", hauteur=96), "GROUND_PLANCHES_QUAI_01\n(texture q, g)"),
		(_ref("REF_CA_ARBRE", 2), "CARMIN_PLANCHE : jeune\narbre A (retirable)"),
		(_ref("REF_CA_PASSERELLE", 1.6), "passerelle g"),
		(_ref("REF_CA_AMARRES"), "bitte à amarre z,\ncordage"),
		(_ref("REF_CA_CAISSES"), "caisses du port k\n(+ grue sur k est)"),
	], (130, 70, 40))
	p.section("3 ter. NOUVEAUX : ROUTES 5 ET 6", [
		heros,
		(_asset(f"{w}props/prop_tronc_couche_01.png"), "ROUTES_J15_PLANCHE :\nindice tronc 1 case\n(R5 (16, 31))"),
		*_si(f"{w}relief/prop_roseaux_01.png", "indice joncs 1 case\n(R6 (10, 32))"),
		(_ref("REF_R6_NENUPHARS", 4), "nénuphars ×2\n(étang, réduit)"),
		(_ref("REF_R6_PORT", 4.5), "PROP_VUE_PORT_01 4 × 4\n(belvédère, v2)"),
	], (130, 70, 40))
	p.section("3 quater. NOUVEAUX : PASSAGE SOUTERRAIN", [
		heros,
		(_ref("REF_SO_SOL", hauteur=110), "DALLES + TRACES\n(2 textures)"),
		(_ref("REF_SO_MUR", 2), "MUR_SOUTERRAIN_PLANCHE\n6 modules"),
		(_ref("REF_SO_ANGLE", 4.5), "angles, bords"),
		(_ref("REF_SO_ESCALIER_N", 2), "escalier montant (N)"),
		(_ref("REF_SO_ESCALIER_S", 2), "escalier descendant (S)"),
		(_ref("REF_SO_STELE", 2), "stèle (7, 6)"),
		(_ref("REF_SO_PIERRE", 1.6), "pierre descellée\n(11, 9) : Guérison"),
		(_ref("REF_SO_BANC", 1.6), "banc (23, 20)"),
		(_ref("REF_SO_APPLIQUE", 1.2), "applique ×6\n(+ LightGlow sconce)"),
	], (130, 70, 40))
	p.section("3 quinquies. NOUVEAUX : INTÉRIEURS, PERSONNAGES, SAC, COMBAT", [
		heros,
		(_asset(f"{w}interiors/int_long_comptoir_01.png"), "INT_J15_PLANCHE : comptoir\nPension, escalier, panier,\n"
			"fauteuil, vitrine, tableau"),
		(heros[0], "PNJ_MARIN 128 px\n(+ attente)"),
		(heros[0], "PNJ_DOCKER 128 px\n(×2 dockers)"),
		(heros[0], "PNJ_PRESIDENT_FAN_CLUB\n128 px"),
		(heros[0], "PNJ_GARDIEN_PENSION\n128 px (au lieu de clerk)"),
		*[(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
			f"{i}.webp\n(style des icônes)") for i in ("potion",)
			if (RACINE / f"assets/ui/items/{i}.webp").exists()],
		(_ref("REF_R6_PRAIRIE", hauteur=150), "COMBAT_DECOR_ROUTE5_6\n_PRAIRIE (CB.3)"),
	], (130, 100, 40))
	p.section("3 sexies. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_ref("REF_CA_MER", hauteur=96), "GROUND_EAU_PORT_01\nsi l'eau assombrie\nne suffit pas"),
		(_echelle(_asset(f"{w}interiors/int_maison_argenta_coque.png"), 0.5), "INT_FAN_CLUB_COQUE"),
		(_ref("REF_CA_MAISON", 6), "BLDG_MAISON_COTIERE_01\nsi maisons 1 et 2\nse répètent"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_CA_NAVIRE", 4), "navire court « ferry »\n(→ 29 × 7, paquebot)"),
		(_ref("REF_CA_CAISSES_EST", 2), "caisses hors cases k\n(la grille décide)"),
		(_ref("REF_R6_ROCHERS", 2), "rochers 2 × 2 → rochers\nexistants (pas de neuf)"),
		(_ref("REF_SO_GALERIE", hauteur=180), "lumière peinte de la vue\n(jeu : NE + LightGlow)"),
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
	"""Planche de contrôle du T11 : les assets **préparés** (assets/), à 1:1 (1 case = 96 px)."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(6000, "Série 17 préparée (T11, jalon 15) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	donnees = manifeste_donnees()
	elements = [x for planche_ in donnees["planches_objets"] for ident in planche_["ids"]
		for x in _present(f"{planche_['dossier']}{ident}.png", ident)]
	p.section("1. PLANCHES DÉCOUPÉES (quai, Carmin, routes, souterrain, meubles)", [heros, *elements],
		(60, 80, 110))
	p.section("2. BÂTIMENTS, NAVIRE, VUE DU PORT", [heros, *[x for e in donnees["objets"]
		for x in _present(e["sortie"], e["id"])]], (130, 70, 40))
	p.section("3. SOLS (extrait 384 px)", [x for e in donnees["sols"]
		for x in _present(e["sortie"], e["id"])], (130, 100, 40))
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


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T9) : la dernière révision présente de chaque image
	(_r4 … _r1) sur fond gris moyen, nom et révision dessous. Les conditionnels ne sont pas montrés."""
	from PIL import ImageDraw, ImageFont
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
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "J15_KIT_v1.png"))
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon15_assets" / "serie17_contact.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon15_assets" / "serie17_controle.png"))
	else:
		generer(set(arguments))
