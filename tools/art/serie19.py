#!/usr/bin/env python3
"""Série 19 — Route 11, Cave Taupiqueur, Route 2 est et son poste (jalon 17, lumière neutre).
Liste : docs/tech/jalon-17.md §1.4 ; fiche : docs/design/fiches-assets/serie-19-chemins.md.
**Numéro** : 19 (constaté le 2026-10-15 sur `origin/*` et sur toutes les copies : 01, 12 à 17 pris ;
18 réservé au J16 par le plan du J17 §1.4, rien dessus pour l'instant). « Le second fusionné
renumérote » : à revérifier au push (fiche, ce fichier, `prompts/serie19/`, mentions des docs).

Méthode des J8–J15 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées, `docs/design/reference/{route-11,cave-taupiqueur,route-2-est}-vue-generale-v1.png` ;
**la grille fait foi** : `tools/plans/route_11.txt`, `digletts_cave.txt`, `route_2_east.txt`,
`route_2_east_gate.txt`, `route_2_j17_retouches.txt`). Repris : herbe, chemin, hautes herbes jaunes,
forêt (feuillus et épicéas), buissons, rochers, clôture de bois, panneaux, mer et rivage rocheux,
parois beiges moussues (série 12), kit de grotte (série 14), poste de garde (série 17), coque et
meubles d'Argenta, scientifique, naturaliste, Gamin. Générées :
  - sols : digue de pierre claire, sable de la Cave, dessus des masses de grès ;
  - relief : deux bouches de Cave vues de dehors (talus de la Route 11, paroi de la Route 2 est),
    planche de six parois de grès sans mousse, planche des deux bouches vues de l'intérieur, planche
    des bords sud de la digue ;
  - accessoire : barrière blanche OUVERTE (FUTUR B, Route 2 sud) ;
  - intérieur du poste : planche de quatre éléments (étagère de lampes de grotte et bocaux, carte
    murale, table de lecture, caisse de lampes) ;
  - personnages : Joueur (Gambler), Ingénieur (Engineer) — marche + attente ; l'assistant de Chen
    (`chercheur`) et le visiteur (`naturaliste`) sont REPRIS (décision de la fiche) ;
  - Pokémon du monde : Soporifik (marche 4 directions), Taupiqueur « sort du sol » et Ronflex
    endormi (« Pokémon fixe » : repos + réaction) ;
  - Sac : icône de la CS05 ; combat : décors `route_11_coast` et `digletts_cave_rock` (chaîne CB.3).
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_BLDG_POSTE_ASSISTANT_01 (si la façade du poste de
Safrania, reprise, ne se lit pas comme un poste de recherche), WORLD_PROP_AFFLEUREMENTS_PLANCHE (si
`relief_paroi_04` et les rochers repris ne tiennent pas les blocs `R` des goulets).
Les dos de combat (T13, méthode Colab) et l'intégration (T14) ne sont PAS dans cet outil.

Lumière : NE pour tout ; la lueur dorée des bouches et les rais de lumière de la Cave sont ajoutés
par le jeu (profil `cave_sand`, `LightGlow`) : la lisibilité de la Cave est DANS LA VALEUR PEINTE
(sol clair, faces moyennes, dessus des masses sombre).

**Les prompts sont versionnés** : `tools/art/prompts/serie19/<NOM>.txt` (un par image),
`tools/art/attente/prompts/<NOM>_ATTENTE.txt` et `tools/art/combat_decors/prompts/`, écrits par
`--prompts` à partir des tables ci-dessous. Corriger une image = corriger la table, relancer
`--prompts`, relire le diff ; une correction après génération se lance en `_r2` (table CORRECTIONS).
**Règle de Kevin pour Codex** : toujours AVEC les images d'ancrage d'abord ; si refus (aucune image),
réessai SANS pièce jointe (prompt seul) ; chaque refus est consigné dans `$ART/refus_serie19.log`.

Usage :
  tools/art/serie19.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie19.py --refs                  recadre les REF_R11_*, REF_CT_*, REF_R2E_* dans $ART
  tools/art/serie19.py --ancres                copie les ancres de style absentes dans $ART
  tools/art/serie19.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie19.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/J17_KIT_v1.png)
  tools/art/serie19.py --contact [sortie.png]  planche de contact À L'ÉCHELLE DU JEU des images
                                               générées (T12 ; 1 case = 96 px, héros 128 px)
  tools/art/serie19.py --manifeste             ajoute les entrées en fin de manifeste.json (T14 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie19.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T14)
  tools/art/serie19.py [IDENTIFIANT ...]       génère avec Codex, par vagues (sans argument : la
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
	_miroir, _Planche)
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
_PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026")


def _sources_ancres() -> list[Path]:
	"""Ancres validées : checkout principal, puis toutes les copies de travail (les séries 14 à 17
	n'existent parfois que dans une copie) ; la première trouvée gagne."""
	copies = sorted((_PRINCIPAL / ".claude" / "worktrees").glob("*/build/art"))
	return [_PRINCIPAL / "build" / "art", *copies]


REFERENCE = RACINE / "docs/design/reference"
VUES = {
	"R11": REFERENCE / "route-11-vue-generale-v1.png",  # 1536 × 1024 (≈ 28 px par case : Dresseurs)
	"CT": REFERENCE / "cave-taupiqueur-vue-generale-v1.png",  # 1024 × 1536 (≈ 25 px par case)
	"R2E": REFERENCE / "route-2-est-vue-generale-v1.png",  # 1024 × 1536 (≈ 26 px par case : poste)
}
PX_CASE = {"R11": 28.0, "CT": 25.0, "R2E": 26.0}
PROMPTS = ICI / "prompts" / "serie19"
ATTENTES = ICI / "attente" / "prompts"
DECORS_COMBAT = ICI / "combat_decors" / "prompts"

## Recadrages des vues validées : (vue, boîte en pixels de la vue). Agrandis × 3 au plus, sans
## dépasser 1 536 px. Boîtes recalées à l'œil (T11).
REFS = {
	# Route 11
	"REF_R11_BOUCHE": ("R11", (90, 0, 520, 250)),
	"REF_R11_DIGUE": ("R11", (600, 566, 745, 606)),
	"REF_R11_DIGUE_BORD": ("R11", (575, 590, 1235, 680)),
	"REF_R11_RIVAGE": ("R11", (0, 590, 575, 700)),
	"REF_R11_MER": ("R11", (0, 700, 1536, 1024)),
	"REF_R11_RONFLEX": ("R11", (1320, 285, 1520, 445)),
	"REF_R11_AFFLEUREMENT": ("R11", (1280, 140, 1470, 335)),
	"REF_R11_AFFLEUREMENT_S": ("R11", (1280, 395, 1470, 625)),
	"REF_R11_SOPORIFIK": ("R11", (1295, 105, 1375, 190)),
	"REF_R11_JOUEURS": ("R11", (745, 525, 1035, 615)),
	"REF_R11_INGENIEUR": ("R11", (785, 425, 865, 500)),
	"REF_R11_GAMINS": ("R11", (215, 205, 560, 300)),
	"REF_R11_PRAIRIE": ("R11", (660, 120, 1100, 540)),
	# Cave Taupiqueur
	"REF_CT_SOL": ("CT", (440, 580, 700, 780)),
	"REF_CT_MASSE": ("CT", (780, 560, 1024, 830)),
	"REF_CT_PAROI": ("CT", (400, 775, 720, 880)),
	"REF_CT_ANGLE": ("CT", (240, 650, 480, 830)),
	"REF_CT_GRAVATS": ("CT", (300, 870, 410, 1035)),
	"REF_CT_BOUCHE_N": ("CT", (370, 0, 610, 100)),
	"REF_CT_BOUCHE_S": ("CT", (370, 1430, 620, 1536)),
	"REF_CT_TAUPIQUEUR": ("CT", (515, 180, 585, 240)),
	"REF_CT_GALERIE": ("CT", (230, 650, 780, 1060)),
	# Route 2 est
	"REF_R2E_BOUCHE": ("R2E", (270, 0, 700, 180)),
	"REF_R2E_POSTE": ("R2E", (540, 245, 765, 400)),
	"REF_R2E_ARBUSTE": ("R2E", (450, 585, 565, 720)),
	"REF_R2E_CLAIRIERE": ("R2E", (190, 735, 490, 1260)),
}
AGRANDIR = 3
REF_MAX = 1536

## Ancres de style (images validées des séries précédentes, dans $ART ; `--ancres` les copie).
STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]
HEROS = "PERSO_P2_PEINT_r1.png"
RATTATA = "POKE_RATTATA_P2_r1.png"
POKE_ANCRE_FIXE = "POKE_RACAILLOU_FIXE_NE_r1.png"  # planche d'un Pokémon fixe validé (gabarit)
POSTE_FORET = "WORLD_BLDG_POSTE_FORET_01_NE_r1.png"
POSTE_SAFRANIA = "WORLD_BLDG_POSTE_SAFRANIA_01_NE_r1.png"  # série 17
PAROI_BEIGE = "WORLD_RELIEF_PAROI_PLANCHE_NE_r1.png"  # série 12 (parois beiges moussues)
ENTREE_GROTTE = "WORLD_RELIEF_ENTREE_GROTTE_01_NE_r2.png"  # série 14 (bouche d'ardoise)
PAROI_GROTTE = "WORLD_RELIEF_PAROI_GROTTE_PLANCHE_NE_r1.png"  # série 14 (gabarit des modules)
SOL_GROTTE = "WORLD_GROUND_GROTTE_01_NE_r2.png"  # série 14
GRAVATS = "WORLD_GROUND_GRAVATS_01_NE_r1.png"  # série 14
MASSE_ROCHE = "WORLD_GROUND_MASSE_ROCHE_01_NE_r1.png"  # série 14
DALLES = "WORLD_GROUND_DALLES_SOUTERRAIN_01_NE_r1.png"  # série 17
PAVE = "WORLD_GROUND_PAVE_A_01_CENTRE_NE_r1.webp"
ROCHER = "WORLD_PROP_ROCHER_01_NE_r1.png"
CLOTURE_V = "assets/world/props/prop_cloture_piquets_v_01.png"  # préparée (la source brute est perdue)
CAISSES = "WORLD_PROP_CAISSES_01_NE_r1.png"
ROCKET_PLANCHE = "WORLD_PROP_ROCKET_PLANCHE_NE_r1.png"  # série 14 (lampes de chantier, caisses)
GRANDE_ETAGERE = "INT_GRANDE_ETAGERE_01_NE_r1.png"
LONG_COMPTOIR = "INT_LONG_COMPTOIR_01_NE_r1.png"
BUREAU_CHEN = "assets/world/interiors/int_bureau_chen_01.png"  # préparé
ETAGERE_LABO = "assets/world/interiors/int_etagere_labo_01.png"  # préparée (bocaux)
TABLE_REPAS = "assets/world/interiors/int_table_repas_01.png"  # préparée
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
POTION = "assets/ui/items/potion.webp"
PIERRE_LUNE = "assets/ui/items/moon_stone.webp"
GARDE = "PNJ_GARDE_NE_r1.png"
DOCKER = "PNJ_DOCKER_NE_r1.png"  # série 17
FAN_CLUB = "PNJ_PRESIDENT_FAN_CLUB_NE_r1.png"  # série 17
ANCRES = [*STYLE, HEROS, RATTATA, POKE_ANCRE_FIXE, POSTE_FORET, POSTE_SAFRANIA, PAROI_BEIGE,
	ENTREE_GROTTE, PAROI_GROTTE, SOL_GROTTE, GRAVATS, MASSE_ROCHE, DALLES, PAVE, ROCHER, CAISSES,
	ROCKET_PLANCHE, GRANDE_ETAGERE, LONG_COMPTOIR, MENU_OBJETS, GARDE, DOCKER, FAN_CLUB]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, AUCUN emblème rond de type balle (ni "
	"cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou faune "
	"non-Pokémon (oiseaux, mouettes, poissons, insectes, chauves-souris), Pikachu et tout Pokémon non "
	"demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune), "
	"élément effrayant.")

VALEURS_SABLE = ("VALEURS DE CAVE SABLEUSE (exception de palette à l'ADN : le sous-sol est chaud et "
	"clair) : grès beige-crème, terre cuite pâle, brun sienne chaud, rose sable ; lumière NEUTRE, diffuse "
	"et blanche, venant légèrement du haut à gauche, aucune teinte dorée ni orangée (la lueur des bouches "
	"et les rais de lumière sont ajoutés par le jeu : ne peins NI rayon, NI flaque de lumière dorée, NI "
	"halo). La lisibilité est DANS LA VALEUR PEINTE : le sol praticable est CLAIR, les faces verticales "
	"de paroi sont moyennes, le dessus des masses rocheuses est SOMBRE ; rapport de luminosité entre le "
	"sol et le dessus des masses d'au moins 2,5. Aucune ombre portée peinte, aucun vignettage.")

VALEURS_PIERRE_CLAIRE = ("Valeurs : pierre calcaire claire et chaude, lumière NEUTRE de milieu de "
	"journée, contraste doux, aucune ombre portée.")

# --- Tables ------------------------------------------------------------------------------

## Textures de sol (opaques, raccordables) : (identifiant, référence, description, ancres,
## valeurs, vague).
SOLS = [
	("WORLD_GROUND_DIGUE_01", "REF_R11_DIGUE",
		"texture de la DIGUE de pierre de la Route 11 (la promenade qui longe la mer), vue strictement de "
		"dessus : grands BLOCS DE PIERRE DE TAILLE calcaire crème rosé, très clair, posés en assises "
		"HORIZONTALES régulières (chaque bloc fait environ une case de large et une demi-case de haut ; "
		"1 case = 256 px sur cette texture), joints fins et nets un peu plus sombres, arêtes légèrement "
		"émoussées, très fines nuances de crème, de sable clair et de gris-rose d'un bloc à l'autre, "
		"quelques taches de sel pâles et un peu de mousse jaune-vert dans de RARES joints ; propre, solide, "
		"ensoleillée ; plus claire, plus chaude et plus régulière que les dalles gris-beige du souterrain "
		"jointes (à ne pas copier) ; aucune fissure marquée, aucune flaque, aucune corde, aucun objet.",
		[DALLES, PAVE], VALEURS_PIERRE_CLAIRE, 1),
	("WORLD_GROUND_SABLE_GROTTE_01", "REF_CT_SOL",
		"texture du SOL PRATICABLE de la Cave Taupiqueur (couloirs et salles calmes, sans rencontre) : "
		"sable de grès fin, battu et tassé, crème clair à beige pâle, le sol le PLUS CLAIR de la scène "
		"(luminosité environ 75 à 85 %), très fines ondulations douces du sable damé, minuscules "
		"gravillons beiges isolés, quelques petits cailloux clairs, de la poussière fine ; reposant, "
		"chaleureux mais jamais jaune vif (pas du sable de plage doré) ; plus clair, plus lisse et plus "
		"chaud que le sol de grotte gris-bleu joint (à ne pas copier) et plus clair que les gravats bruns "
		"joints ; aucune flaque, aucun tas, aucune empreinte, aucun gros rocher.",
		[SOL_GROTTE, GRAVATS], VALEURS_SABLE, 1),
	("WORLD_GROUND_MASSE_SABLE_01", "REF_CT_MASSE",
		"texture du DESSUS DES MASSES ROCHEUSES de la Cave Taupiqueur (cases de paroi vues de dessus, "
		"infranchissables) : gros BLOCS ARRONDIS et facettés de grès brun chaud (brun sienne, brun ocre, "
		"brun rosé) vus de dessus, entassés comme les rochers de la référence jointe, arêtes à peine plus "
		"claires, creux brun très sombre entre les blocs, quelques fines racines minuscules qui "
		"serpentent (même brun chaud) ; se lit comme une masse pleine et inaccessible ; luminosité "
		"environ 25 à 35 %, nettement plus sombre que le sol sableux de la grotte (rapport d'au moins "
		"2,5) mais jamais noire ; aucune mousse, aucune herbe, aucun cristal, aucune lumière.",
		[MASSE_ROCHE, SOL_GROTTE], VALEURS_SABLE, 1),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_RELIEF_BOUCHE_TALUS_01", "REF_R11_BOUCHE", 4, 3,
		"la BOUCHE DE LA CAVE TAUPIQUEUR sur la Route 11 : un module de TALUS ROCHEUX de 4 cases de large "
		"et 3 de haut, de la même hauteur et de la même manière que les modules de la planche de parois "
		"jointe WORLD_RELIEF_PAROI_PLANCHE (il se raccorde à gauche et à droite) mais dans la roche de la "
		"référence : blocs de grès gris-beige légèrement rosé, arrondis et empilés, touffes de mousse et d'herbe vert vif sur les "
		"replats, quelques fleurs blanches ; percé au MILIEU de son bas d'une OUVERTURE de grotte "
		"arrondie de 2 cases de large et environ 1,5 case de haut, brun-bleu sombre à l'intérieur (on ne "
		"voit rien dedans, juste un peu de profondeur et un seuil de terre claire), coiffée d'un linteau "
		"de gros blocs ; le talus s'étale en gros blocs posés au sol de chaque côté de l'ouverture. "
		"Reproduire la bouche de la vue jointe (plus nette) et même main que l'entrée d'ardoise jointe "
		"WORLD_RELIEF_ENTREE_GROTTE_01 (dont c'est la sœur, ici en roche chaude et moussue). Aucun étai de "
		"bois, aucune marche, AUCUN ESCALIER, aucune porte, aucune grille, aucun panneau, aucune lanterne.",
		[PAROI_BEIGE, ENTREE_GROTTE], LUMIERE_NE, 1),
	("WORLD_RELIEF_BOUCHE_PAROI_01", "REF_R2E_BOUCHE", 4, 3,
		"la BOUCHE NORD DE LA CAVE TAUPIQUEUR vue de dehors, sur la Route 2 est : un module de PAROI de "
		"4 cases de large et 3 de haut, de la même roche et de la même hauteur que les modules de la "
		"planche de parois jointe WORLD_RELIEF_PAROI_PLANCHE (il se raccorde à gauche et à droite) : "
		"gros blocs de grès gris-beige taillés en assises irrégulières, un peu de mousse sur les replats ; "
		"percé au MILIEU de son bas d'une OUVERTURE en arche de 2 cases de large et environ 1,5 case de "
		"haut, sombre à l'intérieur (profondeur brun-bleu, jamais noire), encadrée de gros blocs "
		"d'imposte, avec un SEUIL de dalles de pierre claire plates au pied de l'ouverture ; plus "
		"régulière, plus « mur de roche » et moins moussue que la bouche en talus de la Route 11. Aucun "
		"escalier, aucune porte, aucune grille, aucun panneau, aucune lanterne.",
		[PAROI_BEIGE, ENTREE_GROTTE], LUMIERE_NE, 1),
	("WORLD_PROP_BARRIERE_OUVERTE_01", None, 1, "2,4",
		"la BARRIÈRE BLANCHE OUVERTE de la Route 2 (FUTUR B), vue de dessus en trois quarts : la même "
		"barrière que la clôture blanche à piquets pointus jointe (prop_cloture_piquets_v_01 : mêmes "
		"piquets blancs à pointe, mêmes traverses, même peinture patinée), mais OUVERTE comme un portail : "
		"deux gros poteaux blancs plantés au sol, haut et bas de l'image, séparés par un passage libre "
		"de 2 cases ; les deux battants sont rabattus contre les poteaux, chacun replié le long de la "
		"clôture (un battant au nord, un au sud). Silhouette VERTICALE (la clôture court du haut vers le "
		"bas de l'image), environ 1 case de large et 2,4 cases de haut, le passage au milieu totalement "
		"dégagé. Sans cadenas, sans chaîne, sans panneau, sans herbe.",
		[CLOTURE_V], LUMIERE_NE, 1),
]

## Conditionnels : mêmes champs que SERIE.
SERIE_COND = [
	("WORLD_BLDG_POSTE_ASSISTANT_01", "REF_R2E_POSTE", 7, 4,
		"le POSTE DE RECHERCHE de l'assistant du Professeur Chen sur la Route 2 est, façade de face (base "
		"de 7 cases de large, environ 4 cases de haut avec le toit), même famille que les postes joints "
		"WORLD_BLDG_POSTE_FORET_01 et WORLD_BLDG_POSTE_SAFRANIA_01 (même pierre claire gris-beige, même "
		"toit bas d'ARDOISES BLEU-GRIS) mais plus chaleureux : poutres de bois apparentes autour de la "
		"porte, une PORTE DOUBLE de bois brun MOYEN (ouvrable, sans lanterne) au milieu exact du bas (4e "
		"colonne sur 7), de petites fenêtres à carreaux, une jardinière de fleurs sous une fenêtre, une "
		"petite antenne sur le toit. Sans panneau, sans garde, aucune inscription.",
		[POSTE_FORET, POSTE_SAFRANIA], LUMIERE_NE, 2),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
PLANCHES = [
	("WORLD_RELIEF_PAROI_SABLE_PLANCHE", ["REF_CT_PAROI", "REF_CT_ANGLE", "REF_CT_GALERIE"],
		"PLANCHE de 6 modules de PAROI de la Cave Taupiqueur (les bords des masses de grès qui entourent "
		"le tunnel), dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
		"512 × 512), un module par cellule, centré, la base de chacun sur une même ligne horizontale à 40 "
		"px du bas de sa cellule, à une échelle COMMUNE : 1 case = 150 px. Roche de GRÈS BRUN CHAUD sans "
		"aucune mousse ni herbe : le DESSUS des masses est sombre (comme la texture jointe de masse), les "
		"FACES verticales sont moyennes, en colonnes et facettes verticales serrées comme des tuyaux "
		"d'orgue, avec une arête claire en haut et un pied sableux clair qui touche le sol (le sol, "
		"sableux et très clair, n'est PAS dessiné). MÊMES rôles, MÊMES découpes et même manière de "
		"peindre que la planche jointe WORLD_RELIEF_PAROI_GROTTE_PLANCHE (gabarit des modules : ici le "
		"grès chaud remplace l'ardoise froide).\n"
		"1 (ligne 1, à gauche) : FACE A, bord SUD d'une masse vu de face, 3 cases de large × 2 de haut : "
		"en haut une bande du dessus sombre, puis l'arête claire, puis la face verticale ; bord bas "
		"droit et net. 2 (ligne 1, au milieu) : FACE B, identique en hauteur, une fissure verticale et "
		"deux ou trois blocs tombés au pied ; 1 et 2 se raccordent bout à bout par leurs bords gauche et "
		"droit. 3 (ligne 1, à droite) : ANGLE SAILLANT, 2 cases × 2 : l'extrémité gauche d'une face, qui "
		"tourne vers le haut de l'image et devient un bord latéral. 4 (ligne 2, à gauche) : ANGLE "
		"RENTRANT, 2 cases × 2 : le coin intérieur d'une salle, où un bord latéral (à gauche) rejoint "
		"une face (en haut). 5 (ligne 2, au milieu) : BORD LATÉRAL, bande VERTICALE d'une case de large "
		"et 3 de haut : le côté gauche ou droit d'une masse vu de dessus, une arête claire et une mince "
		"bande de face. 6 (ligne 2, à droite) : LÈVRE NORD, bande HORIZONTALE de 3 cases de large et "
		"une de haut : le bord d'une masse située au sud d'un couloir, vu de dessus, juste une arête "
		"claire légèrement en surplomb, sans face visible.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[PAROI_GROTTE, PAROI_BEIGE, MASSE_ROCHE], VALEURS_SABLE, 1),
	("WORLD_RELIEF_BOUCHES_CAVE_PLANCHE", ["REF_CT_BOUCHE_S", "REF_CT_BOUCHE_N"],
		"PLANCHE de 2 BOUCHES de la Cave Taupiqueur VUES DE L'INTÉRIEUR (les deux sorties naturelles du "
		"tunnel, au bord de la carte), dans une image 1536 × 1024 : grille invisible de 2 colonnes × 1 "
		"ligne (cellules de 768 × 1024), un module par cellule, centré verticalement, à une échelle "
		"COMMUNE : 1 case = 180 px. Même grès brun chaud sans mousse que la planche de parois (dessus "
		"sombre, faces verticales moyennes en colonnes, pied sableux clair) ; ce qu'on voit À TRAVERS "
		"l'ouverture est la lumière du jour : herbe vert tendre et fleurs claires, éclat de ciel, peints "
		"dans leur propre couleur (c'est le paysage dehors, PAS un rayon ni un halo autour de la bouche).\n"
		"1 (colonne de gauche) : BOUCHE SUD, la sortie vers la Route 11 est vers le BAS de l'image : un "
		"module de 4 cases de large × 1,6 de haut, dont les deux cases du milieu sont une OUVERTURE "
		"franche (sol de sable qui continue vers l'herbe ensoleillée du dehors, tout en bas), encadrée "
		"de deux jambages de grès (une case chacun) et fermée en haut par un linteau de blocs ; le haut "
		"de l'image est transparent au-dessus du linteau.\n"
		"2 (colonne de droite) : BOUCHE NORD, la sortie vers la Route 2 est vers le HAUT de l'image : "
		"un module de 4 cases de large × 1,8 de haut : un grand ARC de roche vu de l'intérieur, dont le "
		"dessous s'ouvre sur la lumière verte du dehors (herbe, feuillage, clarté), encadré de deux "
		"jambages de grès ; le bas de l'image est transparent sous les jambages (le sable du jeu "
		"s'y raccorde).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée, aucun "
		"rayon de lumière, aucun halo.",
		[PAROI_GROTTE, ENTREE_GROTTE, SOL_GROTTE], VALEURS_SABLE, 1),
	("WORLD_RELIEF_DIGUE_PLANCHE", ["REF_R11_DIGUE_BORD", "REF_R11_RIVAGE"],
		"PLANCHE de 2 MODULES DE BORD SUD DE DIGUE (la face de pierre de la digue de la Route 11, entre "
		"la promenade et la mer) dans une image 1536 × 1024 : grille invisible de 2 colonnes × 1 ligne "
		"(cellules de 768 × 1024), un module par cellule, centré verticalement, à une échelle COMMUNE de "
		"1 case = 200 px, tous vus de dessus en trois quarts. Matière : la même pierre de taille "
		"calcaire crème rosé, très claire, que la promenade (texture jointe WORLD_GROUND_DIGUE_01) : une "
		"rangée de blocs de couronnement vus de dessus en haut, puis la FACE verticale de la digue (deux "
		"assises de blocs) qui descend vers l'eau en bas, avec une fine ligne d'eau mouillée sombre et "
		"quelques algues vert sombre au pied ; ANGLES DROITS : chaque module est un rectangle net qui se "
		"raccorde bout à bout avec son semblable.\n"
		"1 (colonne de gauche) : BORD SUD A, 2 cases de long × environ 0,9 de haut (≈ 400 × 180 px), la "
		"mer est AU SUD (en bas). 2 (colonne de droite) : BORD SUD B, même gabarit, un bloc ébréché et "
		"une touffe d'algues différents, une assise un peu plus sombre ; 1 et 2 se raccordent bout à "
		"bout.\n"
		"Fond avec une vraie transparence (canal alpha), aucune eau dessinée, aucune écume, aucune "
		"promenade (le sol du jeu la fournit), aucun rocher, aucune ombre portée.",
		[DALLES], VALEURS_PIERRE_CLAIRE, 1),
	("INT_J17_PLANCHE", ["REF_R2E_POSTE"],
		"PLANCHE de 4 ÉLÉMENTS d'intérieur du poste de recherche de la Route 2 est (un petit poste de "
		"terrain en bois, cartes de Kanto, bocaux, lampes de grotte : rappel de Flash) dans une image "
		"1536 × 1024 : grille invisible de 2 colonnes × 2 lignes (cellules de 768 × 512), un élément par "
		"cellule, centré, la base de chacun sur une même ligne horizontale à 30 px du bas de sa "
		"cellule, à une échelle COMMUNE de 1 case = 150 px. Vue de dessus en trois quarts : on voit le "
		"dessus et la face avant, jamais les côtés.\n"
		"1 (ligne 1, à gauche) : ÉTAGÈRE DE LAMPES DE GROTTE ET BOCAUX, un meuble haut de bois miel de 2 "
		"cases de large (≈ 300 px) et environ 2 de haut : sur ses étagères, des LAMPES-TEMPÊTE de métal "
		"noir au verre ambré ÉTEINT (rangées de trois), des bocaux de verre de minéraux et de mousses "
		"colorés, un casque de spéléologue beige, des rouleaux de cordage ; même rendu et même main que "
		"l'étagère jointe INT_GRANDE_ETAGERE_01 et que l'étagère de laboratoire à bocaux jointe. 2 (ligne "
		"1, à droite) : CARTE MURALE DE KANTO, un grand cadre de bois sombre de 2 cases de large (≈ 300 "
		"px) et environ 1,3 de haut, contenant une carte peinte de la région (côte bleue à gauche, "
		"montagnes beiges, forêt verte, routes de terre, quelques petites épingles de couleur), SANS "
		"aucun nom, aucune lettre, aucun chiffre ; suspendue (le bas de l'image est le bas du cadre).\n"
		"3 (ligne 2, à gauche) : TABLE DE LECTURE, une grande table de bois clair de 3 cases de large "
		"(≈ 450 px) et 2 de profondeur, recouverte de cartes dépliées SANS écriture, d'une loupe, d'un "
		"compas et d'un carnet ouvert (pages sans écriture lisible), une lampe de bureau éteinte ; "
		"quatre pieds droits, SANS chaises ; plus « bureau de terrain » que la table à nappe à carreaux "
		"jointe. 4 (ligne 2, à droite) : CAISSE DE LAMPES DE GROTTE, une caisse de bois ouverte d'une case "
		"(≈ 150 px) et environ 0,8 de haut, d'où dépassent quatre lampes-tempête de métal noir au verre "
		"ambré éteint et un rouleau de corde, même rendu que les caisses de la planche Rocket jointe.\n"
		"Même rendu que les meubles joints (même main, même angle) ; fond avec une vraie transparence "
		"(canal alpha), aucun sol, aucun tapis, aucun personnage, aucune ombre portée, aucune lueur "
		"(les lampes sont éteintes).",
		[GRANDE_ETAGERE, LONG_COMPTOIR, ETAGERE_LABO, BUREAU_CHEN, ROCKET_PLANCHE], LUMIERE_NE, 2),
]

## Conditionnels : planches.
PLANCHES_COND = [
	("WORLD_PROP_AFFLEUREMENTS_PLANCHE", ["REF_R11_AFFLEUREMENT", "REF_R11_AFFLEUREMENT_S"],
		"PLANCHE de 4 AFFLEUREMENTS ROCHEUX de la Route 11 (les blocs qui serrent les goulets d'Arthur "
		"et de Ronflex), dans une image 1536 × 1024 : grille invisible de 2 colonnes × 2 lignes "
		"(cellules de 768 × 512), un module par cellule, centré, la base de chacun sur une même ligne "
		"horizontale à 30 px du bas de sa cellule, à une échelle COMMUNE de 1 case = 150 px. Roche de "
		"grès beige rosé moussue, même main et même roche que le rocher et la planche de parois joints.\n"
		"1 (ligne 1, à gauche) : GRAND AFFLEUREMENT A, un amas haut de grosses roches arrondies et "
		"empilées, 3 cases de large × 3 de haut (≈ 450 × 450 px), mousse et petites fleurs sur les "
		"replats. 2 (ligne 1, à droite) : GRAND AFFLEUREMENT B, même gabarit, silhouette différente (une "
		"dalle haute à gauche, un petit éboulis au pied). 3 (ligne 2, à gauche) : AFFLEUREMENT MOYEN, 2 "
		"cases × 2 (≈ 300 px). 4 (ligne 2, à droite) : PETIT AFFLEUREMENT, 1,5 case × 1,2 (≈ 225 × 180 "
		"px).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune herbe autour, aucune ombre "
		"portée.",
		[ROCHER, PAROI_BEIGE], LUMIERE_NE, 2),
]

## Personnages (marche + attente) : (identifiant, références, hauteur en jeu, rôle court, tenue,
## pose d'attente, ancres de marche supplémentaires, vague de la marche). Tenues = défauts (règle 4).
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
PERSONNAGES = [
	("PNJ_PARIEUR", ["REF_R11_JOUEURS"], 128, "un Joueur (parieur) de la Route 11",
		"un JOUEUR (parieur de casino) d'environ 40 ans, élégant et un peu louche : FEUTRE gris-brun à "
		"ruban jaune moutarde, MOUSTACHE fine noire, petites lunettes de soleil rondes teintées relevées sur "
		"le front, VESTE de sport marron chocolat ouverte sur un GILET jaune moutarde, chemise crème, foulard "
		"noir noué au cou, pantalon noir à fines rayures grises, souliers bruns à bout clair, un dé à jouer "
		"blanc dans la main droite. Taille d'un adulte. Différent du héros, du garde joint (ni uniforme "
		"bleu, ni képi), du docker joint et du président du Fan Club joint (ni bordeaux, ni costume trois "
		"pièces) ; aucun texte.",
		f"{PIEDS_JOINTS}, une main dans la poche du pantalon et l'autre tenant le dé près du ventre, un "
		"sourire en coin", [GARDE, FAN_CLUB], 1),
	("PNJ_INGENIEUR", ["REF_R11_INGENIEUR"], 128, "un Ingénieur de la Route 11",
		"un INGÉNIEUR de chantier d'environ 30 ans, sérieux et bricoleur : CASQUE DE CHANTIER jaune vif avec "
		"des lunettes de protection claires relevées dessus, petite barbe de trois jours châtain, T-SHIRT "
		"orange, SALOPETTE de travail bleu moyen, gants de travail beiges glissés à la ceinture, ceinture à "
		"outils de cuir brun avec une clé à molette, grosses bottes brun foncé. Taille d'un adulte, plutôt "
		"carré. Différent du héros, du docker joint (ni bonnet de laine, ni pull marin, ni corde) et du "
		"garde joint ; aucun texte.",
		f"{PIEDS_JOINTS}, les poings sur les hanches, le regard sérieux", [DOCKER, GARDE], 1),
]

## Pokémon du monde. Marche 4 × 4 : (identifiant, hauteur en jeu, ancre, description, mouvement, vol).
POKEMON_MARCHE = [
	("POKE_SOPORIFIK", 76, RATTATA,
		"Soporifik, de Pokémon Rouge/Bleu, fidèle à son design officiel : Pokémon psychique bipède de "
		"type tapir, corps jaune-ocre, longue trompe souple crème à deux narines, petits yeux noirs "
		"mi-clos et endormis, deux petites oreilles pointues, large collerette de fourrure crème autour "
		"du cou, bas du corps et mains brun chaud, doigts à griffes courtes. Allure somnolente et "
		"mystérieuse.",
		"marche lentement sur ses deux jambes en 4 images, pas traînants de somnambule, la trompe et les "
		"bras qui balancent mollement", False),
]

## Référence de la vue pour un Pokémon marcheur (couleurs seulement).
REF_POKE = {"POKE_SOPORIFIK": "REF_R11_SOPORIFIK"}

## Pokémon d'ambiance immobiles (format « Pokémon fixe » du J9 : 4 poses, repos et réaction de
## face, repos et réaction de profil gauche) : (identifiant, référence, description, repos, réaction,
## hauteur en jeu, échelle en px de haut sur la planche à générer, la pose de réaction peut
## montrer un Pokémon absent).
POKEMON_FIXES = [
	("POKE_TAUPIQUEUR_FIXE", "REF_CT_TAUPIQUEUR",
		"Taupiqueur, le Pokémon taupe de Pokémon Rouge/Bleu, fidèle à son design officiel : petite tête "
		"ronde brun clair rosé, gros museau rond rose, deux petits yeux noirs ronds et vifs ; il ne "
		"montre JAMAIS que sa tête et le haut de son cou, car le reste est sous terre ; il sort d'un "
		"petit TERTRE rond de terre meuble brun foncé, bordé de quelques mottes et de cailloux, au "
		"milieu d'un cercle de terre retournée. Le tertre fait environ 1 case de large.",
		"la TÊTE sortie du tertre, le regard curieux tourné vers le spectateur, le museau rose levé",
		"il vient de s'ENFONCER : plus AUCUNE partie du Pokémon n'est visible, il ne reste que le tertre "
		"de terre meuble, un trou sombre rond au sommet et quelques mottes qui retombent (le Pokémon est "
		"ABSENT de cette pose)", 44, 150, True),
	("POKE_RONFLEX_FIXE", "REF_R11_RONFLEX",
		"Ronflex, de Pokémon Rouge/Bleu, fidèle à son design officiel : ÉNORME Pokémon bleu-vert très "
		"sombre (gris-bleu foncé) à la silhouette massive et ronde, gros ventre crème rond, petite tête "
		"ronde aux petites oreilles pointues, visage crème, YEUX FERMÉS, deux petites dents du bas qui "
		"dépassent, gros pieds crème à trois griffes, courts bras épais. Il est ENDORMI EN TRAVERS D'UNE "
		"ROUTE, ASSIS lourdement par terre, penché en avant, le menton sur le ventre, les bras posés sur "
		"le ventre. Il occupe un carré d'environ 2 cases sur 2 : AUSSI LARGE QUE HAUT, ramassé.",
		"endormi, immobile, le gros ventre au repos, la tête penchée",
		"il INSPIRE profondément dans son sommeil : le gros ventre crème est un peu plus gonflé et les "
		"épaules un peu relevées, les yeux restent fermés (différence douce, même silhouette)", 168, 230,
		False),
]

## Planche d'icônes du Sac (chaîne de `preparer_menu.py`, comme MENU_OBJETS_PLANCHE : 4 colonnes).
UI = ("UI_OBJETS_J17_PLANCHE",
	"PLANCHE d'UNE icône d'objet peinte pour le Sac, dans une image 1536 × 1024 divisée en quatre "
	"colonnes invisibles de 384 px : une icône CENTRÉE dans la PREMIÈRE colonne (x de 0 à 384), de 260 px "
	"de large au plus et 260 px de haut au plus, avec au moins 60 px de marge vide de chaque côté ; les "
	"trois autres colonnes restent VIDES (transparentes) ; dans le style EXACT de la planche jointe "
	"MENU_OBJETS_PLANCHE et des icônes jointes de la Potion et de la Pierre Lune (même rendu, même "
	"angle de trois quarts, même lumière).\n"
	"1 (colonne 1) : la CS05, une capsule technique : un DISQUE plat et lustré vu de trois quarts, "
	"dessus JAUNE VIF avec un large anneau argenté et un petit trou au centre, tranche épaisse bleu "
	"marine, et au centre du dessus une petite AMPOULE blanche stylisée (le symbole de la lumière, sans "
	"rayons) ; objet simple et propre, jamais un cercle partagé en deux, aucune bande médiane, aucun "
	"bouton.\n"
	"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : l'objet est net, avec seulement "
	"son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).",
	[MENU_OBJETS, POTION, PIERRE_LUNE], 1)

## Décors de combat (chaîne des décors de combat, tools/art/combat_decors/) : (identifiant, images
## jointes dans l'ordre, texte). Plan §1.4 : `route_11_coast` et `digletts_cave_rock`.
_FORMAT_COMBAT = ("FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande "
	"résolution possible, OPAQUE, cadrage plein, sans bord.")
_RENDU_COMBAT = ("RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne "
	"« HD-2D peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points "
	"ni en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches "
	"sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à hauteur "
	"d'yeux, un peu plongeante, le sol recule nettement vers l'horizon.")
DECORS_COMBAT_TABLE = [
	("COMBAT_DECOR_ROUTE11_COTE_r1",
		["docs/design/reference/combat-v1.webp", "docs/design/reference/combat-decors-planche-v1.webp",
			"docs/design/reference/route-11-vue-generale-v1.png"],
		"DÉCOR DE COMBAT — ROUTE 11, PRAIRIE CÔTIÈRE (Kanto 2026). Image de PRODUCTION : le fond peint d'un "
		"écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, AUCUNE "
		"interface, AUCUN texte.\n\n"
		"Images jointes.\n"
		"IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement "
		"plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité "
		"de peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le "
		"coucher de soleil orange.\n"
		"IMAGE 2 : une planche d'intention de décors de combat (guide de facture).\n"
		"IMAGE 3 : la vue générale (de dessus) de la Route 11 : prairie fleurie, chemin de terre clair, "
		"hautes herbes jaune-vert, bosquets de feuillus, talus de roche beige moussue, digue de pierre "
		"claire, mer bleu profond étincelante (guide de palette).\n\n"
		f"{_FORMAT_COMBAT}\n\n"
		"LIEU : la prairie côtière de la Route 11. Sol d'herbe courte vert tendre et de terre battue "
		"claire, petites fleurs sauvages blanches, roses et jaunes ; à GAUCHE, au-delà d'un rivage de "
		"rochers beiges où la mer vient ourler d'écume, la MER bleu profond étincelante qui va jusqu'à "
		"l'horizon ; à DROITE, des bosquets de feuillus ronds vert profond et un talus de roche beige "
		"moussue. Golden hour. Aucun bâtiment, aucune clôture, aucun panneau, aucun bateau.\n\n"
		"COMPOSITION (fractions depuis le coin haut gauche) :\n"
		"- Horizon vers 33 % de la hauteur : la mer à gauche et au centre ; les feuillus et le talus de "
		"roche à droite (x 62 à 100 %), entre 15 et 45 % de la hauteur. Le rivage de rochers beiges et "
		"d'écume court en plan moyen entre 40 et 48 % de la hauteur, côté gauche et centre.\n"
		"- De 50 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT d'herbe courte et de terre "
		"battue claire.\n"
		"- Point A (x 67 %, y 56 %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien "
		"de haut dans un rayon de 12 % de la largeur autour.\n"
		"- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier "
		"plan. Rien de haut autour.\n"
		"- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de "
		"détails et peu de contraste, valeurs simples (ciel et mer calmes).\n"
		"- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol "
		"simple, presque sans objet, valeurs moyennes, sans contraste fort.\n"
		"- Les deux coins du bas restent du SOL nu : pas de buisson ni de rocher en gros plan.\n"
		"- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés "
		"sur certains écrans).\n\n"
		"LUMIÈRE : golden hour, soleil bas venant du haut à gauche (hors cadre), reflets dorés sur la "
		"mer, lumière dorée chaude sur l'herbe et les feuillages, ombres douces ; ciel bleu pâle voilé, "
		"nuages légers teintés de rose doré, pas de soleil visible, pas de contre-jour.\n\n"
		f"{_RENDU_COMBAT}\n\n"
		"INTERDITS : Pokémon, animal, oiseau, mouette, poisson, personnage, silhouette, texte, lettres, "
		"chiffres, panneau lisible, logo, signature, filigrane, cadre, interface, bateau, maison, "
		"bâtiment, digue, clôture, grue, véhicule, pixel art, flou, vignettage.\n"),
	("COMBAT_DECOR_CAVE_TAUPIQUEUR_r1",
		["docs/design/reference/combat-v1.webp", "docs/design/reference/combat-decors-planche-v1.webp",
			"docs/design/reference/cave-taupiqueur-vue-generale-v1.png"],
		"DÉCOR DE COMBAT — CAVE TAUPIQUEUR, ROCHE CLAIRE ET SABLEUSE (Kanto 2026). Image de PRODUCTION : "
		"le fond peint d'un écran de combat Pokémon sur smartphone en paysage, À L'INTÉRIEUR d'une "
		"grotte. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.\n\n"
		"Images jointes.\n"
		"IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement "
		"plongeante, grand sol dégagé au centre), sa profondeur et sa qualité de peinture. Ne reprends "
		"PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le ciel.\n"
		"IMAGE 2 : une planche d'intention de décors de combat ; prends la dernière case (« Argenta — "
		"intérieur de l'Arène de Pierre », roche en blocs, sol de poussière, lumière tombant d'en haut) "
		"comme guide de la facture d'une salle de roche.\n"
		"IMAGE 3 : la vue générale (de dessus) de la Cave Taupiqueur : tunnel de sable clair entre des "
		"parois de grès brun chaud, gravats, petits cailloux gris. Tu vois ce lieu à hauteur d'yeux.\n\n"
		f"{_FORMAT_COMBAT}\n\n"
		"LIEU : un large tunnel creusé dans le grès, peu profond. Parois et plafond en GRÈS BRUN CHAUD "
		"(colonnes et blocs de roche sienne, ocre et rosé, arêtes douces, quelques racines fines qui "
		"pendent), SOL de sable de grès crème clair, tassé, semé de petits cailloux beiges et de "
		"gravillons. LISIBLE : la scène n'est JAMAIS noire ; une lumière naturelle chaude et diffuse, "
		"venue de loin et d'en haut par une ouverture hors cadre, éclaire le sol central ; les parois "
		"restent brun moyen (sombres mais détaillées). Aucune lampe, aucun outil, aucune trace "
		"humaine.\n\n"
		"COMPOSITION (positions en fractions de la largeur et de la hauteur de l'image, depuis le coin "
		"haut gauche) — à respecter précisément :\n"
		"- Fond (30 à 36 % de la hauteur) : le tunnel s'enfonce vers un fond de roche et un passage "
		"clair au centre-gauche, avec une lueur chaude lointaine ; parois à gauche et à droite qui se "
		"resserrent.\n"
		"- De 40 % de la hauteur jusqu'en bas : un GRAND SOL DÉGAGÉ et PLAT de sable clair et de fins "
		"gravillons, où deux créatures pourront se faire face.\n"
		"- Point A (x 67 %, y 50 %) : sol plat et lisible, clair, une créature y posera les pieds. Rien "
		"de haut dans un rayon de 12 % de la largeur autour ; derrière lui seulement la paroi lointaine.\n"
		"- Point B (x 31 %, y 97 %) : sol plat de sable, une grande créature vue de dos y sera au "
		"premier plan. Rien de haut autour.\n"
		"- Plan moyen (35 à 48 % de la hauteur) : de gros blocs de grès et un pilier de roche sur les "
		"côtés, quelques petits cailloux gris, un petit tertre de terre meuble discret à droite.\n"
		"- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de "
		"détails et peu de contraste, valeurs simples (paroi lisse brun moyen).\n"
		"- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol "
		"simple, presque sans objet, valeurs moyennes, sans contraste fort.\n"
		"- Les deux coins du bas restent du SOL nu : pas de gros rocher en gros plan.\n"
		"- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés "
		"sur certains écrans).\n\n"
		"SOL : sable de grès crème et poussière fine avec cailloux (zones plus claires et plus sombres), "
		"jamais une surface uniforme ; nettement plus clair que les parois.\n\n"
		"LUMIÈRE : lumière CHAUDE et diffuse de grès, venant du haut à gauche et de l'ouverture lointaine "
		"; ombres douces brun-rosé (jamais noires) ; sol nettement plus clair que les parois ; contraste "
		"modéré.\n\n"
		f"{_RENDU_COMBAT}\n\n"
		"INTERDITS : Pokémon, animal, chauve-souris, personnage, silhouette, texte, lettres, chiffres, "
		"logo, signature, filigrane, cadre, interface, ciel, soleil visible, végétation, caisse, lampe, "
		"outil, échelle, eau, cristal, noir pur, pixel art, flou, vignettage.\n"),
]

## Corrections (T12) : (identifiant sans _NE_rN, révision) → texte qui remplace la description
## d'origine (planche ou objet). Vide à la rédaction du kit.
CORRECTIONS: dict[tuple[str, int], str] = {}

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return " et ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées "
		"de la Route 11, de la Cave Taupiqueur et de la Route 2 est (minuscules, ambiance dorée : n'en "
		"copie ni le rendu ni la lumière) ; ")


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
	format_ = ("Format : PNG paysage 1536 × 1024 ; l'élément occupe environ 1 300 px dans sa plus grande "
		"dimension, centré")
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


SOL_POKE = ("les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même "
	"taille dans toutes les cellules")


def _prompt_pokemon_marche(identifiant: str, ancre: str, description: str, mouvement: str,
		vol: bool, hauteur: int, ref: str | None = None) -> str:
	"""Planche de marche 4 × 4 d'un Pokémon du monde (modèle de serie14_pokemon, J12)."""
	nom = ancre.removesuffix(".png")
	texte_ref = (f"\nLa troisième image jointe ({ref}) est un minuscule recadrage de la vue d'ensemble "
		"validée : couleurs et allure du Pokémon seulement (rendu à NE PAS copier).") if ref else ""
	return f"""{identifiant} — planche d'animation d'un Pokémon du monde (compagnon du héros).
Style : exactement le rendu de la première planche jointe (le héros du jeu) : Pokémon peint simplifié, même finesse, même contour fin coloré sans trait noir, même manière de peindre les volumes. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

POKÉMON (identique dans toutes les images) : {description}

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose du Pokémon, entier, centré horizontalement, {SOL_POKE} (environ 200 px de haut). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran).
- Colonnes : {mouvement}.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus du Pokémon). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.

La deuxième image jointe ({nom}) est un autre Pokémon du jeu, déjà validé : même rendu, même finesse, même gabarit de planche ; garde ses proportions comme repère de style (ce Pokémon-ci est bipède et d'environ {hauteur} px de haut dans le jeu, donc nettement plus grand que le repère).{texte_ref}
{INTERDITS}
"""


def _prompt_pokemon_fixe(identifiant: str, ref: str | None, description: str, repos: str,
		reaction: str, hauteur: int, haut_planche: int, absent: bool) -> str:
	"""Planche d'un Pokémon d'ambiance IMMOBILE à 4 poses (modèle de serie12, J10) ; `absent` : la
	pose de réaction peut ne montrer que le décor du Pokémon (Taupiqueur enfoncé)."""
	jointes = (f"{HEROS[:-4]} (le héros validé) et {RATTATA[:-4]} (un petit Pokémon validé) = ancres de "
		"style")
	if ref:
		jointes += f" ; {ref} = couleurs et taille relative seulement (minuscule, rendu à NE PAS copier)"
	meme = ("Les couleurs, les proportions et le visage doivent être EXACTEMENT les mêmes dans les poses "
		"de repos ; seule la posture change entre repos et réaction"
		+ (" (dans la pose de réaction le Pokémon est absent, mais le tertre est le MÊME)." if absent
			else "."))
	return (f"{identifiant} — planche d'un Pokémon d'ambiance IMMOBILE (il ne marche jamais) : 4 poses.\n"
		f"Images jointes : {jointes}.\nStyle : exactement le rendu des ancres : Pokémon peint simplifié, "
		"même finesse, même contour fin coloré sans trait noir. Ni pixel art, ni 3D, ni anime aux contours "
		f"noirs. Formes simples et lisibles pour rester net une fois réduit à environ {hauteur} px de "
		f"haut.\n{LUMIERE_NE}\n\nPOKÉMON (identique dans les poses de repos, le SEUL Pokémon de l'image) : "
		f"{description}\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chaque pose dans une colonne invisible de "
		"384 px de large, bien séparées par du vide, l'ensemble entier dans chaque colonne, à la MÊME "
		f"ÉCHELLE dans les 4 poses (environ {haut_planche} px de haut au repos), la base des 4 poses sur "
		"une même ligne horizontale.\n"
		f"- Pose 1 : au repos, vu de face (tourné vers le bas de l'écran) : {repos}.\n"
		f"- Pose 2 : même vue de face, RÉACTION : {reaction}.\n"
		f"- Pose 3 : au repos, de profil, tourné vers la GAUCHE : {repos}.\n"
		f"- Pose 4 : même profil gauche, RÉACTION : {reaction}.\n"
		"Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus). Pas de sol, pas "
		"d'outil, pas de personnage, pas d'ombre au sol, pas de texte, pas de numéros, pas de cadres. "
		f"{meme}\n{INTERDITS}\n")


def _prompt_ui(identifiant: str, description: str, format_: str) -> str:
	return (f"{identifiant} — NOUVELLE image pour l'interface (Sac) du jeu Kanto 2026, pas une capture "
		"d'écran.\nLes images jointes donnent la direction artistique et la forme des objets ; n'en "
		f"reproduis ni la mise en page ni les textes.\n\n{RENDU}\n\nIMAGE : {description}\nFormat : "
		f"{format_}.\n{INTERDITS}\n")


def _images() -> list[dict]:
	"""Toutes les images de la série : nom (sans .png), fichier de prompt, texte, jointes (noms dans
	$ART, ou chemins relatifs à la racine quand ils contiennent « / »), vague, conditionnel, groupe."""
	images: list[dict] = []

	def ajouter(nom, fichier, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, ref, description, ancres_, valeurs, vague in SOLS:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_texture(ident, ref, description, ancres_, valeurs),
			[f"{ref}.png"] + STYLE + ancres_, vague, groupe=ident)
	for liste, conditionnel in ((SERIE, False), (SERIE_COND, True)):
		for ident, ref, largeur, hauteur, description, ancres_, valeurs, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
				ancres_, valeurs), ([f"{ref}.png"] if ref else []) + STYLE + ancres_, vague, conditionnel,
				groupe=ident)
	for liste, conditionnel in ((PLANCHES, False), (PLANCHES_COND, True)):
		for ident, refs, description, ancres_, valeurs, vague in liste:
			nom = f"{ident}_NE_r1"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_, valeurs),
				[f"{r}.png" for r in refs] + ancres_, vague, conditionnel, groupe=ident)
	for ident, refs, hauteur, role, tenue, pose, ancres_, vague in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, refs, tenue, ancres_),
			[HEROS] + [f"{r}.png" for r in refs] + ancres_, vague, groupe=ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, pose), [f"{nom}.png"], vague + 1, groupe=ident)
	for ident, hauteur, ancre, description, mouvement, vol in POKEMON_MARCHE:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_pokemon_marche(ident, ancre, description, mouvement,
			vol, hauteur, REF_POKE.get(ident)), [HEROS, ancre] + ([f"{REF_POKE[ident]}.png"]
			if ident in REF_POKE else []), 1, groupe=ident)
	for ident, ref, description, repos, reaction, hauteur, haut_planche, absent in POKEMON_FIXES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_pokemon_fixe(ident, f"{ref}" if ref else None,
			description, repos, reaction, hauteur, haut_planche, absent),
			[HEROS, RATTATA, POKE_ANCRE_FIXE] + ([f"{ref}.png"] if ref else []), 1, groupe=ident)
	ident, description, ancres_, vague = UI
	ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description,
		"PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)"), list(ancres_), vague, groupe=ident)
	for ident, jointes, texte in DECORS_COMBAT_TABLE:
		ajouter(ident, DECORS_COMBAT / f"{ident}.txt", texte, jointes, 1, groupe=ident.rsplit("_", 1)[0])
	for (ident, rev), description in CORRECTIONS.items():
		nom = f"{ident}_NE_r{rev}"
		groupe = f"{ident}_r{rev}"
		base = next((t for t in PLANCHES + PLANCHES_COND if t[0] == ident), None)
		if base is not None:
			_, refs, _, ancres_, valeurs, _ = base
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_planche(ident, refs, description, ancres_,
				valeurs), [f"{r}.png" for r in refs] + ancres_, 3, True, groupe=groupe)
			continue
		objet = next((t for t in SERIE + SERIE_COND if t[0] == ident), None)
		if objet is not None:
			_, ref, largeur, hauteur, _, ancres_, valeurs, _ = objet
			precedent = f"{ident}_NE_r{rev - 1}.png"
			ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_objet(ident, ref, largeur, hauteur, description,
				[precedent] + ancres_, valeurs), ([f"{ref}.png"] if ref else []) + [precedent] + STYLE
				+ ancres_, 3, True, groupe=groupe)
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
	print(f"{len(REFS)} références REF_R11_*, REF_CT_*, REF_R2E_* dans {ART}")


def _jointes_art() -> set[str]:
	generees = {i["nom"] + ".png" for i in _images()}
	return {j for i in _images() for j in i["jointes"]
		if "/" not in j and not j.startswith("REF_") and j not in generees}


def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	manquantes = []
	sources = _sources_ancres()
	for nom in sorted(set(a for a in ANCRES if "/" not in a) | _jointes_art()):
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


JOURNAL_REFUS = "refus_serie19.log"
SANS_JOINTE = ("(Aucune image n'est jointe à cette demande : les « images jointes » citées plus bas ne "
	"sont PAS disponibles ; applique leur description écrite et ne cherche pas à les voir.)\n\n")
ESSAIS_AVEC = 2
ESSAIS_SANS = 2


def _consigner(nom: str, ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with (ART / JOURNAL_REFUS).open("a") as journal:
		journal.write(f"{nom} : {ligne}\n")


def _generer(image: dict) -> str:
	"""Règle de Kevin : d'abord AVEC les images d'ancrage (ESSAIS_AVEC essais, le filtre de Codex
	refuse parfois au hasard) ; si refus, SANS pièce jointe (prompt seul, ESSAIS_SANS essais) ; chaque
	refus est consigné."""
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	texte = image["fichier"].read_text()
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	derniere = ""
	for essai in range(ESSAIS_AVEC):
		derniere = serie10._lancer(nom, texte, jointes)
		if derniere.endswith(": ok"):
			return derniere + (f" (essai {essai + 1} avec ancres)" if essai else "")
		_consigner(nom, f"refus ou échec AVEC ancres, essai {essai + 1} : {derniere[-160:]}")
	if not jointes:
		return derniere
	for essai in range(ESSAIS_SANS):
		derniere = serie10._lancer(nom, SANS_JOINTE + texte, [])
		if derniere.endswith(": ok"):
			_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + " (SANS pièce jointe)"
		_consigner(nom, f"refus ou échec SANS pièce jointe, essai {essai + 1} : {derniere[-160:]}")
	return derniere


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


# --- Manifeste (T14) --------------------------------------------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"
_P = "assets/sprites/pokemon/painted/"


def _revision(base: str) -> str:
	"""Dernière révision présente dans $ART pour `base` (sans `_rN.png`), `_r1` par défaut."""
	for rev in (4, 3, 2, 1):
		if (ART / f"{base}_r{rev}.png").exists():
			return f"{base}_r{rev}.png"
	return f"{base}_r1.png"


def _planche_objets(base: str, dossier: str, colonnes: int, lignes: int, ids: list[str],
		cases: list[float], contact: float | None, nettoyer: bool = False,
		boites: list[list[int]] | None = None) -> dict:
	entree = {"source": _revision(base), "dossier": f"{_W}{dossier}/", "colonnes": colonnes,
		"lignes": lignes, "ids": ids, "cases": cases, "contact": contact}
	if nettoyer:
		entree["nettoyer"] = True
	if boites:
		entree["boites"] = boites
	return entree


def _sol(ident: str, base: str, contraste: float = 1.0, couleur: float = 1.0) -> dict:
	return {"id": ident, "source": _revision(base), "sortie": f"{_W}ground/{ident}.png",
		"taille": 384, "contraste": contraste, "couleur": couleur, "raccord": 24}


## Rôles des modules (fiche, §« Alignement ») ; ordre de lecture des planches.
PAROI_SABLE_IDS = ["relief_paroi_sable_01", "relief_paroi_sable_02", "relief_paroi_sable_03",
	"relief_paroi_sable_04", "relief_paroi_sable_05", "relief_paroi_sable_06"]
BOUCHES_CAVE_IDS = ["relief_bouche_cave_sud_01", "relief_bouche_cave_nord_01"]
DIGUE_IDS = ["relief_digue_bord_01", "relief_digue_bord_02"]
INT_IDS = ["int_etagere_lampes_01", "int_carte_murale_01", "int_table_lecture_01",
	"int_caisse_lampes_01"]
AFFLEUREMENTS_IDS = ["prop_affleurement_01", "prop_affleurement_02", "prop_affleurement_03",
	"prop_affleurement_04"]


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T14 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T14 sur la planche de contrôle. `cases` = largeur en cases de chaque élément."""
	return {
		"objets": [
			{"id": "relief_bouche_talus_01", "source": _revision("WORLD_RELIEF_BOUCHE_TALUS_01_NE"),
				"sortie": f"{_W}relief/relief_bouche_talus_01.png", "axe": "w", "cases": 4,
				"ombre": False, "contact": 0.0},
			{"id": "relief_bouche_paroi_01", "source": _revision("WORLD_RELIEF_BOUCHE_PAROI_01_NE"),
				"sortie": f"{_W}relief/relief_bouche_paroi_01.png", "axe": "w", "cases": 4,
				"ombre": False, "contact": 0.0},
			# Même hauteur que la clôture blanche fermée (3,4 cases) à 2,4 cases : le passage de 2 cases
			# est libre entre les poteaux ; ancrage au poteau sud (réglé au T14).
			{"id": "prop_barriere_ouverte_01", "source": _revision("WORLD_PROP_BARRIERE_OUVERTE_01_NE"),
				"sortie": f"{_W}props/prop_barriere_ouverte_01.png", "axe": "h", "cases": 2.4,
				"ombre": False, "contact": 0.3},
		],
		"sols": [
			_sol("ground_digue_01", "WORLD_GROUND_DIGUE_01_NE", 0.9, 1.0),
			_sol("ground_sable_grotte_01", "WORLD_GROUND_SABLE_GROTTE_01_NE", 0.7, 1.0),
			_sol("ground_masse_sable_01", "WORLD_GROUND_MASSE_SABLE_01_NE", 0.6, 0.9),
		],
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_PAROI_SABLE_PLANCHE_NE", "relief", 3, 2, PAROI_SABLE_IDS,
				[3, 3, 2, 2, 1, 3], 0.0),
			_planche_objets("WORLD_RELIEF_BOUCHES_CAVE_PLANCHE_NE", "relief", 2, 1, BOUCHES_CAVE_IDS,
				[4, 4], 0.0),
			_planche_objets("WORLD_RELIEF_DIGUE_PLANCHE_NE", "relief", 2, 1, DIGUE_IDS, [2, 2], 0.0),
			_planche_objets("INT_J17_PLANCHE_NE", "interiors", 2, 2, INT_IDS, [2, 2, 3, 1], 0.2,
				nettoyer=True),
		],
		"personnages": [
			{"id": nom, "source": _revision(f"PNJ_{ident}_NE"), "sortie": f"{_C}{nom}_sheet.png",
				"hauteur": 128} for nom, ident, _ in _PERSOS
		],
		"attentes": [
			{"id": f"{nom}_idle", "source": _revision(f"{ident}_ATTENTE"),
				"sortie": f"{_C}{nom}_idle_sheet.png", "marche": nom} for nom, ident, _ in _PERSOS
		],
		"pokemon": [
			{"id": "soporifik", "source": _revision("POKE_SOPORIFIK_NE"),
				"sortie": f"{_P}soporifik_sheet.png", "hauteur": 76},
		],
		"pokemon_fixes": [
			{"id": "taupiqueur", "source": _revision("POKE_TAUPIQUEUR_FIXE_NE"),
				"sortie": f"{_P}taupiqueur_sheet.png", "hauteur": 44},
			{"id": "ronflex", "source": _revision("POKE_RONFLEX_FIXE_NE"),
				"sortie": f"{_P}ronflex_sheet.png", "hauteur": 168},
		],
	}


## (planche préparée, identifiant de fiche, look du jeu) ; looks en fin de LOOKS au T14.
_PERSOS = [("parieur", "PARIEUR", "gambler"), ("ingenieur", "INGENIEUR", "engineer")]
PERSONNAGES_JEU = [(nom, look, 128) for nom, _, look in _PERSOS]
## Pokémon du monde (T14, `build_character_frames.gd`) : marche → `soporifik` (drowzee) ; fixes →
## `taupiqueur` (diglett), `ronflex` (snorlax).
## Icône du Sac (T14, `preparer_menu.py` : planche de 4 colonnes, la première occupée) →
## `assets/ui/items/hm05.webp`.
ICONES_IDS = ["hm05"]


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
	print(f"manifeste : {ajouts} entrée(s) de la série 19 ajoutée(s)")


# --- Planche de contrôle du kit (sans Codex) --------------------------------------------


def _ref(nom: str, cases_haut: float | None = None, hauteur: int | None = None) -> Image.Image:
	image = _recadrage(nom).convert("RGBA")
	if hauteur is None:
		vue, _ = REFS[nom]
		hauteur = round(image.height / PX_CASE[vue] * CASE_PLANCHE) if cases_haut is None else round(
			cases_haut * CASE_PLANCHE)
	return _echelle(image, max(1, hauteur) / image.height)


def _si(relatif: str, etiquette: str, fonction=_asset):
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def _sol_extrait(nom: str, role: str) -> tuple[Image.Image, str]:
	image = Image.open(RACINE / f"{_W}ground/{nom}.png").convert("RGBA").crop((0, 0, 192, 192))
	return (_echelle(image, 0.5), f"{nom}\n{role}")


def _cellules(relatif: str, colonnes: int, lignes: int, choix: list[tuple[int, int]]) -> Image.Image:
	feuille = Image.open(RACINE / relatif).convert("RGBA")
	largeur, hauteur = feuille.width // colonnes, feuille.height // lignes
	bande = Image.new("RGBA", (largeur * len(choix), hauteur), (0, 0, 0, 0))
	for i, (colonne, ligne) in enumerate(choix):
		bande.alpha_composite(feuille.crop((colonne * largeur, ligne * hauteur,
			(colonne + 1) * largeur, (ligne + 1) * hauteur)), (i * largeur, 0))
	return bande


def _jeu(relatif: str, facteur: float = 1.0) -> Image.Image:
	image = Image.open(RACINE / relatif).convert("RGBA")
	return image if facteur == 1.0 else _echelle(image, facteur)


def _present(relatif: str, etiquette: str, fonction=_jeu) -> list:
	return [(fonction(relatif), etiquette)] if (RACINE / relatif).exists() else []


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso(f"{_C}heros_sheet.png"), "héros (échelle)")
	w, c, po = _W, _C, _P
	p = _Planche(2800, "Route 11, Cave Taupiqueur, Route 2 est — kit de la série 19 (T11, jalon 17) : "
		"1 case = 48 px ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS — extérieurs", [
		heros,
		*[(_asset(f"{w}relief/relief_paroi_0{i}.png"), f"relief_paroi_0{i}\ntalus K, paroi R2E") for i in (1, 2, 3, 4)],
		(_asset(f"{w}relief/relief_falaise_01.png"), "falaise\n(rebord)"),
		(_asset(f"{w}props/prop_rocher_01.png"), "rochers R\ngoulets"),
		(_asset(f"{w}props/prop_grande_pierre_01.png"), "grande pierre"),
		(_asset(f"{w}props/prop_rocher_mer_01.png"), "rocher de mer\n(poche du rivage)"),
		*[(_asset(f"{w}relief/relief_rivage_0{i}.png"), f"rivage 0{i}\nbord de mer R") for i in (1, 2, 4)],
		(_asset(f"{w}props/prop_cloture_01.png"), "clôture c\n(digue)"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneaux T-10 T-11\nT-12"),
		(_asset(f"{w}props/prop_buisson_a_01.png"), "buissons x"),
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 3, 5, 6)],
		(_asset(f"{w}props/prop_indice_caillou_01.png"), "indice caillou\nO3 (62, 9)"),
		(_asset(f"{w}props/prop_racines_01.png"), "racines (Cave)"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball\nobjets visibles"),
		(_asset(f"{w}buildings/bldg_poste_safrania_01.png"), "poste de garde\n(poste R2E, 7 × 4)"),
		(_asset(f"{w}props/prop_cloture_piquets_v_01.png"), "barrière fermée\nFUTUR B (existe)"),
	], (40, 90, 50))
	p.section("1 bis. SOLS RÉUTILISÉS (extrait 2 × 2 cases)", [
		_sol_extrait("ground_herbe_01", "herbe ."), _sol_extrait("ground_chemin_01", "chemin ="),
		_sol_extrait("ground_roche_01", "sol rocheux o\n(clairière Cave, devant\nla bouche R2E, poche rivage)"),
		_sol_extrait("ground_eau_01", "mer W (assombrie,\ncomme le port de Carmin)"),
		_sol_extrait("ground_gravats_01", "gravats g (Cave)\nbrun ocre : tient"),
		(_echelle(Image.open(RACINE / f"{w}ground/ground_hautes_herbes_jaune_01.png").convert("RGBA"), 0.5),
			"hautes herbes jaunes h"),
		_sol_extrait("ground_masse_roche_01", "(contraste) masse\ngrotte J12, ardoise"),
	], (40, 90, 50))
	p.section("1 ter. INTÉRIEUR DU POSTE RÉUTILISÉ (coque × 0,5)", [
		heros,
		(_echelle(_asset(f"{w}interiors/int_maison_argenta_coque.png"), 0.5),
			"coque maison d'Argenta\n(15 × 10, comme le plan)"),
		*[(_asset(f"{w}interiors/{n}.png"), l) for n, l in (
			("int_bureau_chen_01", "bureau N (7..9, 3)"), ("int_chaise_bureau_01", "chaise (8, 4)"),
			("int_classeur_01", "classeur f (10, 3)"), ("int_bibliotheque_cote_01", "bibliothèque B\n(1..4, 3) × 4"),
			("int_plante", "plantes x"), ("int_grande_etagere_01", "repli étagère E"))],
	], (40, 90, 50))
	persos = [("chercheur", "chercheur : ASSISTANT\nde Chen (a)"), ("naturaliste", "naturaliste :\nVISITEUR (v)"),
		("jeune_dresseur", "jeune_dresseur :\nGamins D1..D4"), ("voyageur", "voyageur (au besoin)"),
		("montagnard", "montagnard\n(au besoin)")]
	p.section("1 quater. PERSONNAGES ET POKÉMON RÉUTILISÉS", [heros,
		*[x for nom, etiquette in persos for x in _si(f"{c}{nom}_sheet.png", etiquette, _cellule_perso)],
		*[x for nom, etiquette in (("rattata", "Rattata"), ("piafabec", "Piafabec (piafabec_1)"),
			("abo", "Abo (abo_1)")) for x in _si(f"{po}{nom}_sheet.png", etiquette,
				lambda r: _cellules(r, 4, 4, [(0, 0)]))]], (40, 90, 50))

	p.section("2. VARIATIONS SANS NOUVEL ASSET", [
		(_ref("REF_R11_MER", hauteur=96), "mer : ground_eau_01 assombrie\n(Shade, bleu profond)"),
		(_miroir(_asset(f"{w}relief/relief_paroi_01.png")), "parois en miroir\n(± variété du talus)"),
		(_ref("REF_R11_AFFLEUREMENT", 3), "affleurements R :\nrelief_paroi_04 (massif) +\nrochers (cond. planche)"),
		(_ref("REF_CT_GRAVATS", 2), "gravats : ground_gravats_01\n(sans nouvel asset)"),
		(_ref("REF_R2E_ARBUSTE", 2), "arbuste du goulet :\ncelui du J16 (provisoire :\nbuisson)"),
	], (110, 90, 40))
	p.section("3. NOUVEAUX : SOLS (référence recadrée)", [
		heros,
		(_ref("REF_R11_DIGUE", hauteur=96), "GROUND_DIGUE_01\npierre de taille claire"),
		(_ref("REF_CT_SOL", hauteur=130), "GROUND_SABLE_GROTTE_01\nsol clair de la Cave"),
		(_ref("REF_CT_MASSE", hauteur=130), "GROUND_MASSE_SABLE_01\ndessus des masses"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : RELIEF ET ACCESSOIRES", [
		heros,
		(_ref("REF_R11_BOUCHE", 3.2), "RELIEF_BOUCHE_TALUS_01 4 × 3\n(Route 11, (15..16, 7))"),
		(_ref("REF_R2E_BOUCHE", 3.2), "RELIEF_BOUCHE_PAROI_01 4 × 3\n(Route 2 est, (6..7, 3))"),
		(_ref("REF_CT_PAROI", 2), "PAROI_SABLE_PLANCHE\n6 modules"),
		(_ref("REF_CT_ANGLE", 4.5), "angles, bords"),
		(_ref("REF_CT_BOUCHE_S", 2), "BOUCHES_CAVE_PLANCHE\nsud (79) et nord (0)"),
		(_ref("REF_R11_DIGUE_BORD", 1.8), "DIGUE_PLANCHE\nbord sud A / B"),
		(_asset(f"{w}props/prop_cloture_piquets_v_01.png"), "BARRIERE_OUVERTE_01\n(34, 43..44) : version\nouverte de celle-ci"),
	], (130, 70, 40))
	p.section("3 ter. NOUVEAUX : INTÉRIEUR DU POSTE, PERSONNAGES, POKÉMON, SAC, COMBAT", [
		heros,
		(_asset(f"{w}interiors/int_etagere_labo_01.png"), "INT_J17_PLANCHE : étagère de\nlampes et bocaux, carte murale,\n"
			"table de lecture, caisse de lampes"),
		(_ref("REF_R11_JOUEURS", 1.7), "PNJ_PARIEUR 128 px\n(Joueurs D5, D6)"),
		(_ref("REF_R11_INGENIEUR", 1.8), "PNJ_INGENIEUR 128 px\n(Ingénieurs D7, D8)"),
		(_ref("REF_R11_SOPORIFIK", 1.8), "POKE_SOPORIFIK 76 px\nmarche 4 directions"),
		(_ref("REF_CT_TAUPIQUEUR", 1.4), "POKE_TAUPIQUEUR_FIXE 44 px\ntête sortie / caché"),
		(_ref("REF_R11_RONFLEX", 3.4), "POKE_RONFLEX_FIXE 2 × 2\nendormi / inspire (vue : trop\ngrand, la grille décide)"),
		*[(_echelle(Image.open(RACINE / f"assets/ui/items/{i}.webp").convert("RGBA"), 0.4),
			f"{i}.webp (modèle)\nCS05 = hm05.webp") for i in ("potion",)
			if (RACINE / f"assets/ui/items/{i}.webp").exists()],
		(_ref("REF_R11_PRAIRIE", hauteur=150), "COMBAT_DECOR_ROUTE11_COTE\n(route_11_coast)"),
		(_ref("REF_CT_GALERIE", hauteur=150), "COMBAT_DECOR_CAVE_TAUPIQUEUR\n(digletts_cave_rock)"),
	], (130, 100, 40))
	p.section("3 quater. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_ref("REF_R2E_POSTE", 4), "BLDG_POSTE_ASSISTANT_01\nsi le poste de Safrania\nne se lit pas « recherche »"),
		(_ref("REF_R11_AFFLEUREMENT_S", 3), "AFFLEUREMENTS_PLANCHE\nsi paroi_04 + rochers\nne tiennent pas les R"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_R11_GAMINS", hauteur=64), "casquettes bleue / rouge / verte\n(Gamins : un seul modèle)"),
		(_ref("REF_R11_RONFLEX", 2), "Ronflex trop grand dans la vue\n(≈ 5 cases : la grille dit 2 × 2)"),
		(_ref("REF_CT_GALERIE", hauteur=180), "canyon vu du ciel, rais\n(Cave : profil `cave_sand`\net `LightGlow`, pas de peinture)"),
		(_ref("REF_R2E_CLAIRIERE", hauteur=180), "clairières trop larges\nR2E (la grille décide) ; trouée\nFUTUR A = outil de carte"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


# --- Planche de contrôle des assets PRÉPARÉS (T14) ---------------------------------------


def controle(sortie: Path) -> Path:
	"""Planche de contrôle du T14 : les assets **préparés** (assets/), à 1:1 (1 case = 96 px)."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(6000, "Série 19 préparée (T14, jalon 17) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	donnees = manifeste_donnees()
	elements = [x for planche_ in donnees["planches_objets"] for ident in planche_["ids"]
		for x in _present(f"{planche_['dossier']}{ident}.png", ident)]
	p.section("1. PLANCHES DÉCOUPÉES (parois, bouches, digue, intérieur du poste)", [heros, *elements],
		(60, 80, 110))
	p.section("2. BOUCHES ET BARRIÈRE", [heros, *[x for e in donnees["objets"]
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
	p.section("5. POKÉMON DU MONDE : Soporifik (marche), Taupiqueur et Ronflex (repos, réaction)", [
		heros,
		*_present(f"{_P}soporifik_sheet.png", "soporifik 76 px\nmarche",
			lambda r: _cellules(r, 4, 4, [(0, 0), (1, 1), (1, 2), (0, 3)])),
		*[x for nom in ("taupiqueur", "ronflex") for x in _present(f"{_P}{nom}_sheet.png",
			f"{nom}\nface repos, face réaction, profil", lambda r: _cellules(r, 6, 1, [(0, 0), (1, 0), (2, 0)]))],
	], (110, 90, 40))
	p.section("6. ICÔNE DU SAC (256 px)", [
		*[x for ident in ICONES_IDS for x in _present(f"assets/ui/items/{ident}.webp", ident)],
	], (120, 40, 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


# --- Planche de contact à l'échelle du jeu (T12) -----------------------------------------

CASE_JEU = 96  # px en jeu : 1 case
## Échelle de génération des planches (px par case dans l'image générée), d'après leur prompt.
GEN_PX_CASE = {"WORLD_RELIEF_PAROI_SABLE_PLANCHE": 150, "WORLD_RELIEF_BOUCHES_CAVE_PLANCHE": 180,
	"WORLD_RELIEF_DIGUE_PLANCHE": 200, "INT_J17_PLANCHE": 150, "WORLD_PROP_AFFLEUREMENTS_PLANCHE": 150}
## Largeur en cases des objets isolés (ancrés sur le tracé visible).
LARGEUR_OBJET = {ident: largeur for ident, _, largeur, *_ in SERIE + SERIE_COND}
HAUTEUR_PERSO = {ident: hauteur for ident, _, hauteur, *_ in PERSONNAGES}
HAUTEUR_POKE_MARCHE = {ident: hauteur for ident, hauteur, *_ in POKEMON_MARCHE}
HAUTEUR_POKE_FIXE = {ident: hauteur for ident, _, _, _, _, hauteur, *_ in POKEMON_FIXES}


def _boite_visible(image: Image.Image) -> Image.Image:
	"""Recadre sur le tracé visible (alpha > 40), image entière si elle est opaque."""
	alpha = image.getchannel("A").point(lambda v: 255 if v > 40 else 0)
	boite = alpha.getbbox()
	return image.crop(boite) if boite else image


def _poses_bande(image: Image.Image, nombre: int) -> list[Image.Image]:
	"""Les `nombre` poses d'une ligne (colonnes égales), chacune recadrée sur son tracé."""
	largeur = image.width // nombre
	return [_boite_visible(image.crop((i * largeur, 0, (i + 1) * largeur, image.height)))
		for i in range(nombre)]


def _bande(poses: list[Image.Image], hauteur: float, reference: float) -> Image.Image:
	"""Les poses côte à côte, bas aligné, à l'échelle hauteur / reference."""
	reduites = [_echelle(p, hauteur / reference) for p in poses]
	largeur = sum(p.width for p in reduites) + 12 * len(reduites)
	composite = Image.new("RGBA", (largeur, max(p.height for p in reduites)), (0, 0, 0, 0))
	x = 0
	for p in reduites:
		composite.alpha_composite(p, (x, composite.height - p.height))
		x += p.width + 12
	return composite


def _lignes_4x4(image: Image.Image) -> list[Image.Image]:
	"""Première colonne d'une planche de marche 4 × 4 : face, gauche, droite, dos."""
	return [_boite_visible(image.crop((0, r * image.height // 4, image.width // 4,
		(r + 1) * image.height // 4))) for r in range(4)]


def _a_l_echelle(nom: str, image: Image.Image) -> list[tuple[Image.Image, str]]:
	"""Les éléments à montrer pour une image générée, à l'échelle du jeu (1 case = 96 px)."""
	base = nom.rsplit("_NE_r", 1)[0] if "_NE_r" in nom else nom.rsplit("_r", 1)[0]
	image = image.convert("RGBA")
	if base.startswith("WORLD_GROUND_"):
		tuile = image.resize((384, 384), Image.LANCZOS)
		deux = Image.new("RGBA", (768, 384))
		deux.paste(tuile, (0, 0))
		deux.paste(tuile, (384, 0))
		return [(deux, f"{base}\n4 × 4 cases, posée 2 fois (couture)")]
	if base in GEN_PX_CASE:
		return [(_echelle(image, CASE_JEU / GEN_PX_CASE[base]),
			f"{base}\nplanche entière, 1 case = 96 px")]
	if base in LARGEUR_OBJET:
		visible = _boite_visible(image)
		cases = LARGEUR_OBJET[base]
		return [(_echelle(visible, cases * CASE_JEU / visible.width), f"{base}\n{cases} cases de large")]
	if base in HAUTEUR_PERSO or base in HAUTEUR_POKE_MARCHE:
		hauteur = HAUTEUR_PERSO.get(base) or HAUTEUR_POKE_MARCHE[base]
		lignes = _lignes_4x4(image)
		return [(_bande(lignes, hauteur, lignes[0].height),
			f"{base}\n{hauteur} px : face, gauche, droite, dos")]
	if base.endswith("_ATTENTE"):
		hauteur = HAUTEUR_PERSO.get("PNJ_" + base.removesuffix("_ATTENTE"), 128)
		poses = _poses_bande(image, 4)
		return [(_bande(poses, hauteur, poses[0].height), f"{base}\nattente, {hauteur} px")]
	if base in HAUTEUR_POKE_FIXE:
		hauteur = HAUTEUR_POKE_FIXE[base]
		poses = _poses_bande(image, 4)  # une seule échelle : le repos de face = `hauteur`
		return [(_bande(poses, hauteur, poses[0].height),
			f"{base}\n{hauteur} px : repos, réaction, repos profil, réaction profil")]
	if base.startswith("UI_"):
		visible = _boite_visible(image.crop((0, 0, image.width // 4, image.height)))
		return [(_echelle(visible, 256 / max(visible.size)), f"{base}\nicône 256 px")]
	if base.startswith("COMBAT_DECOR"):
		return [(_echelle(image, 900 / image.width), f"{base}\ndécor de combat (réduit)")]
	return [(_echelle(image, 400 / max(image.size)), base)]


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T12) à l'échelle du jeu : la dernière révision
	présente de chaque image (_r4 … _r1), 1 case = 96 px, héros de 128 px pour jauger. Les
	conditionnels ne sont montrés que s'ils ont été générés."""
	heros = (_cellules(f"{_C}heros_sheet.png", 4, 4, [(0, 0)]), "héros 128 px")
	p = _Planche(3000, "Série 19 générée (T12, jalon 17) : À L'ÉCHELLE DU JEU, 1 case = 96 px ; "
		"héros 128 px")
	groupes: dict[str, list] = {"SOLS (extrait 4 × 4 cases)": [], "RELIEF, BOUCHES, BARRIÈRE": [],
		"PLANCHES (entières, 1 case = 96 px)": [], "PERSONNAGES": [], "POKÉMON": [],
		"ICÔNE ET DÉCORS DE COMBAT": []}
	n = 0
	for image in _images():
		base = image["nom"].rsplit("_r", 1)[0]
		fichier = None
		for rev in (4, 3, 2, 1):
			candidat = ART / f"{base}_r{rev}.png"
			if candidat.exists():
				fichier = candidat
				break
		if fichier is None:
			continue
		nom = fichier.stem
		elements = _a_l_echelle(nom, Image.open(fichier))
		if base.startswith("WORLD_GROUND_"):
			cle = "SOLS (extrait 4 × 4 cases)"
		elif base.startswith(("WORLD_RELIEF_BOUCHE", "WORLD_PROP_BARRIERE", "WORLD_BLDG_")):
			cle = "RELIEF, BOUCHES, BARRIÈRE"
		elif base in GEN_PX_CASE or base.startswith(("WORLD_", "INT_")):
			cle = "PLANCHES (entières, 1 case = 96 px)"
		elif base.startswith(("PNJ_", )) or base.endswith("_ATTENTE"):
			cle = "PERSONNAGES"
		elif base.startswith("POKE_"):
			cle = "POKÉMON"
		else:
			cle = "ICÔNE ET DÉCORS DE COMBAT"
		groupes[cle].extend(elements)
		n += 1
	for titre, elements in groupes.items():
		if elements:
			p.section(titre, [heros, *elements] if titre not in ("ICÔNE ET DÉCORS DE COMBAT",
				"SOLS (extrait 4 × 4 cases)") else elements, (60, 80, 110))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	print(f"{n} images")
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
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "J17_KIT_v1.png"))
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon17_assets" / "serie19_contact.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		autres = [a for a in arguments if a != "--controle"]
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon17_assets" / "serie19_controle.png"))
	else:
		generer(set(arguments))
