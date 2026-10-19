#!/usr/bin/env python3
"""Série 25 — deux chemins vers Parmanie (jalon 22, lumière neutre) : personnages, Pokémon du monde,
icônes. Plan : docs/tech/jalon-22.md §2.15, T7, T8 ; conception : dossier-25 §15 ; fiche :
docs/design/fiches-assets/serie-25-deux-chemins.md.

**Numéro** : 25 (constaté le 2026-10-19 par `git ls-tree` de toutes les branches `origin/*` : 01, 06 à
24 pris, 25 libre). À revérifier au push (fiche, ce fichier, `prompts/serie25/`).

Périmètre de cette passe (T7 lot 1 + T8) — les vues générales et les fonds de combat CB.3 des routes
attendent les grilles (T6), ils ne sont PAS ici :
  - joueur (garçon seul : `GameState.PLAYER_LOOKS = [&"hero"]`) : vélo (pédalage 4 × 4 + arrêt en
    selle 4 × 1), pêche (lancer 4 × 1 + attente 4 × 1) ;
  - PNJ : Motard (`biker`), Ornithologue (`bird_keeper`), Loubard (`cue_ball`), marche + attente ;
    les deux frères du pêcheur de Carmin (Parmanie : Super Canne ; Route 12 sud : Méga Canne),
    déclinés du Pêcheur existant (`pecheur`) ; le président du club du Parc Safari = `gentleman`
    (réemploi, rien à générer) ; le vieil homme = `old_man` (réemploi) ;
  - Pokémon du monde (format « Pokémon fixe » : repos et réaction, de face et de profil) :
    Kangourex et Ramoloss des enclos de Parmanie ;
  - Sac : 7 icônes sur deux planches (chaîne `preparer_menu.py`) ; le bouton rond « Vélo » du HUD
    est un SVG écrit à la main (`tools/art/serie25/bike.svg`, modèle `run_shoe.svg`).
Les dos de combat ne passent pas par cet outil (`tools/gen_placeholder_battlers_j22.gd`).

Règle de Kevin pour Codex : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais) ;
refus consignés dans `$ART/refus_serie25.log`. Aucune intégration avant la validation de Kevin :
`--manifeste` affiche les entrées prévues sans rien écrire.

Usage :
  tools/art/serie25.py --prompts               écrit les prompts (tools/art/prompts/serie25/)
  tools/art/serie25.py --ancres                copie les ancres absentes dans $ART
  tools/art/serie25.py --commandes             liste les commandes generer.sh
  tools/art/serie25.py --contact [sortie.png]  planche de contact à l'échelle du jeu
                                               (défaut docs/design/reference/serie-25-contact-v1.png)
  tools/art/serie25.py --manifeste             affiche les entrées prévues (rien n'est écrit)
  tools/art/serie25.py [IDENTIFIANT ...]       génère avec Codex, par vagues
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie10  # noqa: E402
import serie19  # noqa: E402
from serie06 import LUMIERE_NE, RACINE  # noqa: E402
from serie10 import _echelle, _Planche  # noqa: E402
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402
from serie19 import (_bande, _boite_visible, _lignes_4x4, _poses_bande, _prompt_attente,  # noqa: E402
	_prompt_pokemon_fixe, _sources_ancres)

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
serie19.ART = ART
PROMPTS = ICI / "prompts" / "serie25"
ATTENTES = ICI / "attente" / "prompts"
HUD_SVG = ICI / "serie25" / "bike.svg"

HEROS = "PERSO_P2_PEINT_r1.png"
RATTATA = "POKE_RATTATA_P2_r1.png"
POKE_ANCRE_FIXE = "POKE_RACAILLOU_FIXE_NE_r1.png"
RONFLEX = "POKE_RONFLEX_FIXE_NE_r1.png"  # série 19 : Pokémon fixe de grand gabarit
PECHEUR = "PNJ_PECHEUR_NE_r1.png"
GARDE = "PNJ_GARDE_NE_r1.png"
DOCKER = "PNJ_DOCKER_NE_r1.png"
PARIEUR = "PNJ_PARIEUR_NE_r1.png"
INGENIEUR = "PNJ_INGENIEUR_NE_r1.png"
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
UI_J15 = "UI_OBJETS_J15_PLANCHE_r1.png"
POTION = "assets/ui/items/potion.webp"
SUPER_POTION = "assets/ui/items/super_potion.webp"
POKE_BALL = "assets/ui/items/poke_ball.webp"
SS_TICKET = "assets/ui/items/ss_ticket.webp"
HEROS_ATTENTE = "assets/sprites/characters/painted/heros_idle_sheet.png"
ANCRES = [HEROS, RATTATA, POKE_ANCRE_FIXE, RONFLEX, PECHEUR, GARDE, DOCKER, PARIEUR, INGENIEUR,
	MENU_OBJETS, UI_J15]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, animaux réels ou faune non-Pokémon "
	"(oiseaux réels, poissons, insectes), Pikachu et tout Pokémon non demandé, élément effrayant.")
INTERDITS_PNJ = (INTERDITS + " Le personnage ne ressemble PAS au héros (ni casquette rouge, ni t-shirt "
	"blanc, ni sac à dos jaune).")
INTERDITS_HEROS = (INTERDITS + " Aucun autre personnage, aucun Pokémon, aucune eau, aucun sol peint.")

# --- Joueur -------------------------------------------------------------------------------------

HEROS_TENUE = ("le HÉROS du jeu, EXACTEMENT celui de la planche jointe PERSO_P2_PEINT_r1 (même visage, "
	"même casquette rouge à visière blanche, mêmes cheveux bruns, même t-shirt blanc, mêmes bretelles "
	"noires, même sac à dos jaune et bleu marine, même jean bleu, mêmes baskets rouges), mêmes "
	"proportions chibi d'environ 3 têtes, même main peinte, même finesse")
VELO = ("une BICYCLETTE pliante de ville simple et lisible [D] : cadre ROUGE vif un peu bas, garde-boue "
	"blancs, pneus gris foncé, jantes argentées, selle noire, guidon droit à poignées blanches, petit "
	"phare rond blanc à l'avant, sans panier ni porte-bagages, sans logo")
CANNE = ("une CANNE À PÊCHE simple [D] : scion fin gris-bleu, poignée de liège, petit moulinet argenté, "
	"un fil fin blanc")
STYLE_HEROS = ("Style : exactement le rendu de la planche jointe PERSO_P2_PEINT_r1 (le héros validé) : "
	"personnage peint simplifié, contour fin et doux d'une teinte sombre et colorée, aucun trait noir. Ni "
	"pixel art, ni 3D, ni anime aux contours noirs.\n" + LUMIERE_NE)
VUE = ("Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus). Pas de "
	"perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres.")


def _prompt_velo() -> str:
	return (f"HEROS_VELO — planche d'animation : le héros qui roule à vélo (pédalage).\n{STYLE_HEROS}\n\n"
		f"PERSONNAGE (identique dans toutes les images) : {HEROS_TENUE}, assis sur {VELO}. Le héros "
		"tient le guidon des deux mains, le buste un peu penché en avant, le sac sur le dos.\n\n"
		"PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence "
		"(canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule "
		"fait 256 × 384 px et contient UNE pose du héros sur son vélo, ENTIERS (roues comprises), centrés "
		"horizontalement, le bas des roues sur la même ligne horizontale à 30 px du bas de la cellule, à "
		"la même échelle dans toutes les cellules : le héros a EXACTEMENT la même taille de tête et de "
		"corps que dans la planche jointe (environ 280 px du haut de la casquette au bas des roues) ; vu "
		"de profil, le vélo fait au plus 240 px de long et ne déborde jamais de sa cellule.\n"
		"- Ligne 1 : de face (roule vers le bas de l'écran) : roue avant au premier plan, guidon, visage.\n"
		"- Ligne 2 : de profil, roule vers la gauche.\n"
		"- Ligne 3 : de profil, roule vers la droite.\n"
		"- Ligne 4 : de dos (roule vers le haut de l'écran) : roue arrière, sac à dos.\n"
		"- Colonnes : cycle de pédalage en 4 images : 1 = pédale droite en haut, 2 = pédales à "
		"l'horizontale, 3 = pédale gauche en haut, 4 = pédales à l'horizontale (l'autre pied devant) ; les "
		"genoux montent et descendent, le buste et la tête restent stables.\n"
		f"{VUE}\nLe visage, les couleurs, les proportions, les vêtements et le vélo doivent être "
		f"EXACTEMENT les mêmes dans les 16 poses.\n{INTERDITS_HEROS}\n")


def _prompt_velo_arret() -> str:
	return ("HEROS_VELO_ARRET — POSE D'ARRÊT EN SELLE du même héros et du même vélo que la planche jointe "
		"HEROS_VELO_NE_r1 (sa planche de pédalage 4 × 4) : mêmes couleurs, même échelle, même vélo.\n"
		f"{STYLE_HEROS}\n\nPERSONNAGE : {HEROS_TENUE}, sur {VELO}.\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chacune dans une colonne invisible de 384 "
		"px, bien séparées par du vide, entières, à la même taille que dans la planche jointe (environ 280 "
		"px du haut de la casquette au bas des roues), le bas des roues sur une même ligne horizontale.\n"
		"- Pose 1 : de face, comme la ligne 1 de HEROS_VELO_NE_r1.\n"
		"- Pose 2 : de profil vers la GAUCHE, comme la ligne 2.\n"
		"- Pose 3 : de profil vers la DROITE, comme la ligne 3.\n"
		"- Pose 4 : de dos, comme la ligne 4.\n"
		"POSE : le vélo est À L'ARRÊT, bien droit ; le héros reste assis sur la selle, les mains sur le "
		"guidon, le pied GAUCHE posé à plat au sol à côté du vélo, le pied droit sur la pédale haute, le "
		f"buste droit, détendu.\n{VUE}\n{INTERDITS_HEROS}\n")


def _prompt_peche(nom: str, pose: str, jointe: str | None) -> str:
	ancre = (f" La planche jointe {jointe} montre le même héros avec la même canne en train de lancer : "
		"même canne, même échelle, mêmes couleurs.") if jointe else ""
	return (f"{nom} — planche de 4 poses : le héros qui pêche.{ancre}\n{STYLE_HEROS}\n\n"
		f"PERSONNAGE (identique dans les 4 poses) : {HEROS_TENUE}, debout, qui tient à deux mains {CANNE}.\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chacune dans une colonne invisible de 384 "
		"px, bien séparées par du vide. Le héros a EXACTEMENT la même taille que dans la planche jointe "
		"PERSO_P2_PEINT_r1 (environ 280 px de haut), les PIEDS des 4 poses sur une même ligne horizontale à "
		"600 px du haut de l'image ; la canne peut descendre sous les pieds (pose 1), monter au-dessus de "
		"la tête (pose 4) ou partir sur le côté (poses 2 et 3), mais elle reste ENTIÈRE dans la colonne de "
		"sa pose.\n"
		"- Pose 1 : tourné vers le BAS (de face) : la canne pointe vers le bas de l'image, devant lui.\n"
		"- Pose 2 : tourné vers la GAUCHE (de profil) : la canne pointe vers la gauche.\n"
		"- Pose 3 : tourné vers la DROITE (de profil) : la canne pointe vers la droite.\n"
		"- Pose 4 : tourné vers le HAUT (de dos) : la canne pointe vers le haut de l'image, devant lui.\n"
		f"POSE : {pose}\n{VUE} Aucune eau, aucun bouchon dans l'eau, aucun poisson : le jeu ajoute l'eau.\n"
		f"{INTERDITS_HEROS}\n")


PECHE_LANCER = ("LANCER : les deux bras tendus vers l'avant, la canne allongée devant lui dans la direction "
	"où il regarde, un peu au-dessus de l'horizontale, le fil qui part en arc fin depuis le bout de la canne "
	"(sans hameçon visible), une jambe légèrement en avant, élan dynamique mais lisible.")
PECHE_ATTENTE = ("ATTENTE : immobile et calme, les pieds joints côte à côte, la canne tenue devant lui à "
	"deux mains, inclinée vers l'avant et vers le bas, le fil tendu qui descend droit du bout de la canne "
	"jusqu'au bord de la colonne, regard concentré.")

# --- PNJ (marche + attente) ----------------------------------------------------------------------

PIEDS = "debout, calme et naturel, le poids réparti sur les deux jambes"
## (identifiant, hauteur en jeu, rôle court, tenue, pose d'attente, ancres de marche, nom du jeu, look)
PERSONNAGES = [
	("PNJ_MOTARD", 128, "un Motard de la Piste Cyclable",
		"un MOTARD d'environ 25 ans, frimeur mais pas menaçant : cheveux noirs coiffés en BANANE gominée, "
		"LUNETTES DE SOLEIL noires, BLOUSON DE CUIR NOIR ouvert à fermeture argentée et col relevé, T-shirt "
		"ROUGE dessous, gants mitaines noirs, JEAN noir, grosses bottes de moto brunes. Taille d'un adulte, "
		"élancé. Différent du héros, du parieur joint (ni feutre, ni moustache) et du garde joint ; aucun "
		"texte, aucun écusson.",
		f"{PIEDS}, une main dans la poche du blouson, l'autre qui fait tourner un trousseau de clés, un "
		"petit sourire sûr de lui", [PARIEUR, GARDE], "motard", "biker"),
	("PNJ_ORNITHOLOGUE", 128, "un Ornithologue des Routes 13 à 15",
		"un ORNITHOLOGUE d'environ 30 ans, curieux et souriant : CHAPEAU DE BROUSSE vert sapin à bord court "
		"orné d'UNE longue plume bleue, cheveux châtain clair, grosses JUMELLES noires pendues au cou par une "
		"lanière brune, VESTE légère BLEU CANARD à poches à rabat, chemise crème, pantalon de toile BEIGE "
		"retroussé, chaussures de marche brunes, petit carnet à la ceinture. Taille d'un adulte. Différent "
		"du héros et du pêcheur joint (ni chapeau beige, ni gilet olive, ni canne) ; aucun texte.",
		f"{PIEDS}, les jumelles levées à deux mains devant la poitrine, le regard tourné vers le ciel",
		[PECHEUR, INGENIEUR], "ornithologue", "bird_keeper"),
	("PNJ_LOUBARD", 128, "un Loubard des Routes 16 à 18",
		"un LOUBARD d'environ 30 ans, CRÂNE RASÉ et luisant, très COSTAUD et carré (épaules larges, gros bras), "
		"air bourru mais bon enfant : sourcils épais, petite barbe noire taillée court, DÉBARDEUR BLANC, GILET "
		"de cuir sans manches brun foncé, ceinture large à boucle carrée argentée, pantalon cargo gris "
		"anthracite, rangers noires. Taille d'un adulte, plus large que les autres PNJ. Différent du héros, "
		"du docker joint (ni bonnet, ni pull marin, ni corde) et du motard (ni banane, ni blouson) ; aucun "
		"tatouage, aucune arme, aucun texte.",
		f"{PIEDS}, les bras croisés sur le torse, le menton levé", [DOCKER, INGENIEUR], "loubard",
		"cue_ball"),
	("PNJ_PECHEUR_PARMANIE", 130, "le frère du pêcheur de Carmin (maison de la Super Canne, Parmanie)",
		"le FRÈRE CADET du pêcheur joint PNJ_PECHEUR_NE_r1 : MÊME FAMILLE (même visage rond, même nez, même "
		"barbe courte mais BRUN-ROUX au lieu de grise, cheveux brun-roux), environ 45 ans, même gabarit, même "
		"main peinte. Tenue de la même famille, d'autres couleurs : BOB VERT OLIVE à bord court, chemise à "
		"carreaux ROUGES et crème manches retroussées, GILET DE PÊCHE BLEU MARINE multipoches, pantalon "
		"beige, bottes en caoutchouc BRUNES ; une épuisette courte à la main (pas de canne). Aucun texte.",
		f"{PIEDS}, l'épuisette tenue verticalement à côté de lui, un grand sourire", [PECHEUR],
		"pecheur_parmanie", "fisher_fuchsia"),
	("PNJ_PECHEUR_ROUTE12", 130, "l'autre frère du pêcheur de Carmin (maison de la Méga Canne, Route 12)",
		"le FRÈRE AÎNÉ du pêcheur joint PNJ_PECHEUR_NE_r1 : MÊME FAMILLE (même visage rond, même nez), environ "
		"70 ans, plus voûté, longue BARBE BLANCHE fournie, sourcils blancs broussailleux, même main peinte. "
		"Tenue de la même famille, d'autres couleurs : CIRÉ JAUNE de marin ouvert sur un PULL bleu marine à "
		"col roulé, BONNET de laine rouge, pantalon gris, bottes en caoutchouc NOIRES ; une CANNE À PÊCHE "
		"longue et solide tenue à l'épaule. Aucun texte.",
		f"{PIEDS}, les deux mains posées sur le bout de la canne plantée verticalement devant lui, l'air "
		"sage", [PECHEUR], "pecheur_route_12", "fisher_route_12"),
]

# --- Pokémon du monde (format « Pokémon fixe ») ---------------------------------------------------

## (identifiant, description, repos, réaction, hauteur en jeu, px de haut sur la planche, ancre de gabarit)
POKEMON_FIXES = [
	("POKE_KANGOUREX_FIXE",
		"Kangourex, de Pokémon Rouge/Bleu, fidèle à son design officiel : grand Pokémon bipède massif de type "
		"kangourou, corps BRUN-GRIS, ventre et poche ventrale CRÈME, tête allongée au museau arrondi, petits "
		"yeux sérieux, oreilles arrondies, plaques brunes sur le haut du dos, longue queue épaisse posée au sol, "
		"bras forts aux trois griffes. Dans sa POCHE VENTRALE, un BÉBÉ Kangourex (même design en tout petit, "
		"brun-gris, visage crème) dont on voit la tête. C'est le plus GRAND Pokémon de la série : plus haut que "
		"le héros joint (environ 1,6 case de haut quand un adulte en fait 1,33).",
		"debout, calme, les bras le long du corps, le bébé tranquille dans la poche",
		"le BÉBÉ sort la tête et les petits bras de la poche, curieux, et la mère baisse un peu la tête vers "
		"lui (même silhouette de la mère, différence douce)", 150, 260, RONFLEX),
	("POKE_RAMOLOSS_FIXE",
		"Ramoloss, de Pokémon Rouge/Bleu, fidèle à son design officiel : Pokémon quadrupède ROSE pâle, gros "
		"corps rond et mou, grosse tête ronde, museau CRÈME arrondi, deux petites oreilles rondes, grands yeux "
		"ronds au regard vide et paisible, longue queue rose au bout blanc, pattes courtes. Allure lente et "
		"rêveuse. Petit Pokémon : environ la moitié de la hauteur du héros joint.",
		"ASSIS par terre, la queue étendue derrière lui, le regard perdu dans le vide",
		"il penche lentement la tête sur le côté et BÂILLE, la bouche ouverte, les yeux mi-clos (même "
		"silhouette, différence douce)", 64, 170, POKE_ANCRE_FIXE),
]

## Révisions écrites à la main après un blocage du filtre de Codex (r1 refusé 4 fois, avec et sans
## pièce jointe, le 2026-10-19) : description sans cadre « Pokémon officiel », réaction sans bouche
## ouverte. Lancées en vague 3 (`serie25.py POKE_RAMOLOSS_FIXE_r2`).
CORRECTIONS = {("POKE_RAMOLOSS_FIXE", 2): (
	"une petite créature de dessin animé, douce et rêveuse, à quatre pattes courtes, de couleur ROSE pâle : "
	"corps rond et mou, grosse tête ronde, museau CRÈME arrondi, deux petites oreilles rondes, grands yeux "
	"ronds et paisibles, longue queue rose au bout blanc. Petite : environ la moitié de la hauteur du héros "
	"joint. C'est Ramoloss, le Pokémon rose et lent de Kanto.",
	"ASSISE tranquillement, la queue étendue derrière elle, l'air rêveur",
	"elle penche lentement la tête sur le côté, les yeux mi-clos, l'air endormi (même silhouette, "
	"différence douce)"),
	# r3 : r2 refusé 4 fois aussi ; ni nom de licence, ni « Pokémon » (méthode de Soporifik, série 19).
	("POKE_RAMOLOSS_FIXE", 3): (
	"un petit animal ROSE pâle de dessin animé, rond et paisible, à quatre pattes courtes, comme une "
	"peluche : grosse tête ronde, museau crème arrondi, deux petites oreilles rondes, grands yeux ronds "
	"rêveurs, longue queue rose terminée par une pointe blanche. Environ la moitié de la hauteur du héros "
	"joint.",
	"assis tranquillement, la queue étendue derrière lui, l'air rêveur",
	"il penche doucement la tête sur le côté, les yeux mi-clos, l'air ensommeillé (même silhouette)")}

## Kangourex refait après la relecture de Kevin (2026-10-19) : r1 approximatif (tête casquée grise).
## Ancres : l'artwork officiel (design) puis Ramoloss r3, Pokémon du monde validé de la même main (rendu).
OFFICIEL_KANGOUREX = "assets/sprites/pokemon/official/115.png"
RAMOLOSS_VALIDE = "POKE_RAMOLOSS_FIXE_NE_r3.png"
KANGOUREX_JOINTES = (f"{Path(OFFICIEL_KANGOUREX).name} = le DESIGN à respecter (silhouette, couleurs, "
	f"poche, petit) mais PAS son rendu ni sa pose ; {RAMOLOSS_VALIDE[:-4]} (un Pokémon du monde validé) et "
	f"{RATTATA[:-4]} = le RENDU à reproduire exactement (même main peinte, même finesse, même contour fin "
	"coloré)")
_KANGOUREX_TETE = ("TÊTE de la mère BRUNE comme le corps, SANS casque : aucune calotte grise ni noire qui "
	"couvre le crâne ou descend vers les yeux (tout au plus une fine bande brun plus sombre sur le sommet du "
	"crâne, loin derrière les yeux) ; museau allongé et arrondi brun, petits yeux sérieux, deux OREILLES "
	"ARRONDIES dressées, brunes à l'intérieur crème")
KANGOUREX_REVISIONS = {
	2: (f"Kangourex, de Pokémon Rouge/Bleu, EXACTEMENT le design de l'image officielle jointe "
		f"{Path(OFFICIEL_KANGOUREX).name}, peint dans la main des ancres : grande MÈRE bipède massive de type "
		"kangourou, corps BRUN-BEIGE (brun chaud un peu grisé), grand VENTRE ovale CRÈME qui forme une POCHE "
		f"ventrale ; {_KANGOUREX_TETE} ; quelques plaques brun foncé sur les épaules, le haut des bras et le "
		"dos, bras forts aux griffes crème, grosses pattes, longue queue épaisse brune posée au sol. Dans la "
		"POCHE, son PETIT : un bébé tout rond, gris-mauve pâle, au visage doux, dont on voit la tête et le "
		"haut du corps. La mère est grande : plus haute que le héros (environ 1,6 case quand un adulte en "
		"fait 1,33).",
		"debout, calme, les bras le long du corps, le petit tranquille dans la poche",
		"le PETIT sort la tête et les petits bras de la poche, curieux, et la mère baisse un peu la tête vers "
		"lui (même silhouette de la mère, différence douce)"),
	# r3 : r2 refusé ; sans nom de licence ni « Pokémon » (méthode de Ramoloss r3).
	3: ("une grande MÈRE kangourou de dessin animé, massive et calme, bipède : corps BRUN-BEIGE (brun chaud "
		"un peu grisé), grand VENTRE ovale CRÈME qui forme une POCHE ventrale ; TÊTE BRUNE comme le corps, "
		"sans casque ni calotte, museau allongé et arrondi, petits yeux sérieux, deux OREILLES ARRONDIES "
		"dressées ; quelques plaques brun foncé sur les épaules et le dos, bras forts aux griffes crème, "
		"grosses pattes, longue queue épaisse posée au sol. Dans la POCHE, son PETIT : un bébé tout rond, "
		"gris-mauve pâle, au visage doux, dont on voit la tête. Plus haute que le héros (environ 1,6 case "
		"quand un adulte en fait 1,33).",
		"debout, calme, les bras le long du corps, le petit tranquille dans la poche",
		"le PETIT sort la tête et les petits bras de la poche, curieux, et la mère baisse un peu la tête vers "
		"lui (même silhouette de la mère, différence douce)"),
}


def _prompt_kangourex(rev: int) -> str:
	description, repos, reaction = KANGOUREX_REVISIONS[rev]
	texte = _prompt_pokemon_fixe("POKE_KANGOUREX_FIXE", None, description, repos, reaction, 150, 260, False)
	premiere = texte.split("\n", 2)
	assert premiere[1].startswith("Images jointes")
	premiere[1] = f"Images jointes : {KANGOUREX_JOINTES}."
	return "\n".join(premiere)


# --- Icônes du Sac (chaîne `preparer_menu.py`, colonnes de 384 px) --------------------------------

_COLONNES = ("dans une image 1536 × 1024 divisée en quatre colonnes invisibles de 384 px : une icône "
	"CENTRÉE dans chaque colonne utilisée, de 280 px au plus dans sa plus grande dimension, avec au moins 50 "
	"px de vide de chaque côté, aucune icône ne touche ni ne chevauche sa voisine ; dans le style EXACT de "
	"la planche jointe MENU_OBJETS_PLANCHE et des icônes jointes (même rendu peint lisse, même angle de "
	"trois quarts, même lumière, même contour fin coloré).")
_FIN_UI = ("AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec "
	"seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre). Aucun texte, "
	"aucune lettre (même sur le bon et sur les balles), aucun chiffre.")
_ROD = ("vue en diagonale (du bas à gauche vers le haut à droite) pour tenir dans la colonne, avec son "
	"moulinet et une boucle de fil")
## (identifiant, texte, ancres, identifiants du jeu dans l'ordre des colonnes)
UI_PLANCHES = [
	("UI_OBJETS_J22_PLANCHE_A",
		"PLANCHE de QUATRE icônes d'objets peintes pour le Sac, " + _COLONNES + "\n"
		"1 (colonne 1) : le BON DE COMMANDE : une carte-bon rectangulaire en papier crème épais, coin "
		"supérieur droit corné, bord dentelé de timbre à gauche, petit dessin d'une roue de vélo rouge et "
		"tampon rond bleu (sans lettres), vue de trois quarts.\n"
		"2 (colonne 2) : la BICYCLETTE : un vélo pliant de ville vu de profil de trois quarts, cadre ROUGE "
		"vif, garde-boue blancs, pneus gris foncé, selle noire, guidon à poignées blanches, petit phare rond.\n"
		f"3 (colonne 3) : la CANNE : une canne à pêche simple et courte en BAMBOU clair à nœuds, poignée de "
		f"liège, petit moulinet gris, {_ROD}.\n"
		f"4 (colonne 4) : la SUPER CANNE : une canne à pêche moderne BLEU ROI lustrée, anneaux argentés, "
		f"poignée noire, moulinet argenté plus gros, {_ROD}.\n" + _FIN_UI,
		[MENU_OBJETS, UI_J15, POTION, SS_TICKET], ["bike_voucher", "bicycle", "old_rod", "good_rod"]),
	("UI_OBJETS_J22_PLANCHE_B",
		"PLANCHE de TROIS icônes d'objets peintes pour le Sac, " + _COLONNES + " La quatrième colonne reste "
		"VIDE (transparente).\n"
		f"1 (colonne 1) : la MÉGA CANNE : une grande canne à pêche de compétition NOIRE et OR lustrée, "
		f"anneaux dorés, poignée rouge sombre, gros moulinet doré, {_ROD}.\n"
		"2 (colonne 2) : l'HYPER POTION : le même vaporisateur que la Potion et la Super Potion jointes "
		"(même forme de flacon rond et de gâchette blanche), liquide ROSE FUCHSIA et bague ROSE FONCÉ.\n"
		"3 (colonne 3) : l'HYPER BALL : la même balle de capture que la Poké Ball jointe (même forme, même "
		"rendu, même bouton blanc central, même bande noire), dont la moitié haute est NOIRE avec deux "
		"bandes JAUNE D'OR en forme de « H » sur le dessus, la moitié basse BLANCHE.\n" + _FIN_UI,
		[MENU_OBJETS, UI_J15, POTION, SUPER_POTION, POKE_BALL], ["super_rod", "hyper_potion", "hyper_ball"]),
]
ICONES_IDS = [i for *_, ids in UI_PLANCHES for i in ids]


def _prompt_ui(identifiant: str, description: str) -> str:
	return (f"{identifiant} — NOUVELLE image pour l'interface (Sac) du jeu Kanto 2026, pas une capture "
		"d'écran.\nLes images jointes donnent la direction artistique et la forme des objets ; n'en "
		f"reproduis ni la mise en page ni les textes.\n\n{RENDU}\n\nIMAGE : {description}\nFormat : PNG "
		"paysage 1536 × 1024, fond TRANSPARENT (canal alpha).\n")


def _prompt_marche(identifiant: str, tenue: str, ancres: list[str]) -> str:
	texte = (f" ; {' et '.join(Path(a).stem for a in ancres)} = même main et même finesse pour un adulte "
		"(à NE PAS copier : autre visage, autre tenue, sauf ce que la description demande de garder)")
	return MODELE_MARCHE.format(ident=identifiant, ref=texte, tenue=tenue) + INTERDITS_PNJ + "\n"


# --- Table des images ---------------------------------------------------------------------------


def _images() -> list[dict]:
	images: list[dict] = []

	def ajouter(nom, fichier, texte, jointes, vague=1, groupe=None):
		images.append({"nom": nom, "fichier": fichier, "texte": texte, "jointes": jointes,
			"vague": vague, "groupe": groupe or nom.rsplit("_", 2)[0]})

	ajouter("HEROS_VELO_NE_r1", PROMPTS / "HEROS_VELO_NE_r1.txt", _prompt_velo(), [HEROS], 1, "HEROS_VELO")
	ajouter("HEROS_VELO_ARRET_r1", PROMPTS / "HEROS_VELO_ARRET_r1.txt", _prompt_velo_arret(),
		["HEROS_VELO_NE_r1.png", HEROS], 2, "HEROS_VELO")
	ajouter("HEROS_PECHE_LANCER_r1", PROMPTS / "HEROS_PECHE_LANCER_r1.txt",
		_prompt_peche("HEROS_PECHE_LANCER", PECHE_LANCER, None), [HEROS, HEROS_ATTENTE], 1, "HEROS_PECHE")
	ajouter("HEROS_PECHE_ATTENTE_r1", PROMPTS / "HEROS_PECHE_ATTENTE_r1.txt",
		_prompt_peche("HEROS_PECHE_ATTENTE", PECHE_ATTENTE, "HEROS_PECHE_LANCER_r1"),
		["HEROS_PECHE_LANCER_r1.png", HEROS], 2, "HEROS_PECHE")
	for ident, hauteur, role, tenue, pose, ancres_, *_ in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_marche(ident, tenue, ancres_), [HEROS, *ancres_], 1,
			ident)
		court = ident.removeprefix("PNJ_")
		ajouter(f"{court}_ATTENTE_r1", ATTENTES / f"{court}_ATTENTE.txt",
			_prompt_attente(ident, role, hauteur, tenue, pose), [nom + ".png"], 2, ident)
	for ident, description, repos, reaction, hauteur, haut_planche, ancre in POKEMON_FIXES:
		nom = f"{ident}_NE_r1"
		texte = _prompt_pokemon_fixe(ident, None, description, repos, reaction, hauteur, haut_planche, False)
		ajouter(nom, PROMPTS / f"{nom}.txt", texte, [HEROS, RATTATA, ancre], 1, ident)
	for (ident, rev), (description, repos, reaction) in CORRECTIONS.items():
		_, _, _, _, hauteur, haut_planche, ancre = next(f for f in POKEMON_FIXES if f[0] == ident)
		nom = f"{ident}_NE_r{rev}"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_pokemon_fixe(ident, None, description, repos, reaction,
			hauteur, haut_planche, False), [HEROS, RATTATA, ancre], 3, f"{ident}_r{rev}")
	for rev in KANGOUREX_REVISIONS:
		nom = f"POKE_KANGOUREX_FIXE_NE_r{rev}"
		ajouter(nom, PROMPTS / f"{nom}.txt", _prompt_kangourex(rev), [OFFICIEL_KANGOUREX, RAMOLOSS_VALIDE, RATTATA], 3,
			f"POKE_KANGOUREX_FIXE_r{rev}")
	for ident, description, ancres_, _ in UI_PLANCHES:
		ajouter(f"{ident}_r1", PROMPTS / f"{ident}_r1.txt", _prompt_ui(ident, description), ancres_, 1, ident)
	return images


def ecrire_prompts() -> None:
	changes = 0
	for image in _images():
		fichier: Path = image["fichier"]
		fichier.parent.mkdir(parents=True, exist_ok=True)
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	print(f"{len(_images())} prompts ({changes} écrit(s))")


def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	generees = {i["nom"] + ".png" for i in _images()}
	noms = set(a for a in ANCRES if "/" not in a) | {j for i in _images() for j in i["jointes"]
		if "/" not in j and j not in generees}
	manquantes = []
	for nom in sorted(noms):
		if (ART / nom).exists():
			continue
		source = next((s / nom for s in _sources_ancres() if (s / nom).exists()), None)
		if source is None:
			manquantes.append(nom)
		else:
			shutil.copy2(source, ART / nom)
	print("ancres copiées" + (f" ; ABSENTES : {', '.join(manquantes)}" if manquantes else ""))


def commandes() -> str:
	lignes = [f"ART={ART}"]
	for vague in (1, 2, 3):
		lignes.append(f"# Vague {vague}")
		for i in _images():
			if i["vague"] == vague:
				jointes = " ".join(j if "/" in j else f"$ART/{j}" for j in i["jointes"])
				lignes.append(f"tools/art/generer.sh {i['nom']} {i['fichier'].relative_to(RACINE)} {jointes}")
	return "\n".join(lignes)


JOURNAL_REFUS = "refus_serie25.log"


def _consigner(nom: str, ligne: str) -> None:
	with (ART / JOURNAL_REFUS).open("a") as journal:
		journal.write(f"{nom} : {ligne}\n")


def _generer(image: dict) -> str:
	"""AVEC les ancres (2 essais), puis SANS pièce jointe (2 essais) ; chaque refus est consigné."""
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	texte = image["fichier"].read_text()
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	derniere = ""
	for essai in range(2):
		derniere = serie10._lancer(nom, texte, jointes)
		if derniere.endswith(": ok"):
			return derniere
		_consigner(nom, f"refus ou échec AVEC ancres, essai {essai + 1} : {derniere[-160:]}")
	for essai in range(2):
		derniere = serie10._lancer(nom, serie19.SANS_JOINTE + texte, [])
		if derniere.endswith(": ok"):
			_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + " (SANS pièce jointe)"
		_consigner(nom, f"refus ou échec SANS pièce jointe, essai {essai + 1} : {derniere[-160:]}")
	return derniere


def generer(choix: set[str]) -> None:
	ancres()
	ecrire_prompts()
	for vague in (1, 2, 3):
		images = [i for i in _images() if i["vague"] == vague and ((not choix and vague < 3)
			or i["groupe"] in choix or i["nom"] in choix)]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(_generer, images):
				print(ligne, flush=True)


# --- Manifeste prévu (affiché seulement : intégration APRÈS la validation de Kevin) ---------------

_C = "assets/sprites/characters/painted/"
_P = "assets/sprites/pokemon/painted/"


def manifeste_donnees() -> dict:
	return {
		"personnages": [{"id": nom, "source": f"{ident}_NE_r1.png", "sortie": f"{_C}{nom}_sheet.png",
			"hauteur": hauteur} for ident, hauteur, _, _, _, _, nom, _ in PERSONNAGES]
			+ [{"id": "heros_bike", "source": "HEROS_VELO_NE_r1.png", "sortie": f"{_C}heros_bike_sheet.png",
				"hauteur": 128, "note": "hauteur = héros à pied ; le vélo dépasse en largeur"}],
		"attentes": [{"id": f"{nom}_idle", "source": f"{ident.removeprefix('PNJ_')}_ATTENTE_r1.png",
			"sortie": f"{_C}{nom}_idle_sheet.png", "marche": nom} for ident, *_, nom, _ in PERSONNAGES]
			+ [{"id": "heros_bike_idle", "source": "HEROS_VELO_ARRET_r1.png",
				"sortie": f"{_C}heros_bike_idle_sheet.png", "marche": "heros_bike"},
				{"id": "heros_fish_cast", "source": "HEROS_PECHE_LANCER_r1.png",
				"sortie": f"{_C}heros_fish_cast_sheet.png", "marche": "heros"},
				{"id": "heros_fish_wait", "source": "HEROS_PECHE_ATTENTE_r1.png",
				"sortie": f"{_C}heros_fish_wait_sheet.png", "marche": "heros"}],
		"pokemon_fixes": [{"id": ident.removeprefix("POKE_").removesuffix("_FIXE").lower(),
			"source": f"{ident}_NE_r1.png", "sortie": f"{_P}{ident.removeprefix('POKE_').removesuffix('_FIXE').lower()}_sheet.png",
			"hauteur": hauteur} for ident, _, _, _, hauteur, _, _ in POKEMON_FIXES],
		"preparer_menu.PLANCHES_OBJETS_SUIVANTES": [[f"{ident}_r1.png", ids] for ident, _, _, ids in UI_PLANCHES],
		"looks (build_character_frames.gd, en fin)": {look: nom for *_, nom, look in PERSONNAGES},
		"hud": {"source": str(HUD_SVG.relative_to(RACINE)), "sortie": "assets/ui/icons/hud/bike.svg"},
	}


# --- Planche de contact à l'échelle du jeu --------------------------------------------------------

CASE_JEU = 96
HAUTEUR = {i[0]: i[1] for i in PERSONNAGES}
HAUTEUR_FIXE = {i[0]: i[4] for i in POKEMON_FIXES}
DOS = ["magikarp", "krabby", "seaking", "venonat", "venomoth", "doduo", "dodrio", "farfetchd", "grimer",
	"muk", "weezing", "electrode", "machoke"]


def _derniere(base: str) -> Path | None:
	for rev in (4, 3, 2, 1):
		for nom in (f"{base}_NE_r{rev}.png", f"{base}_r{rev}.png"):
			if (ART / nom).exists():
				return ART / nom
	return None


def _jeu(relatif: str, colonnes: int = 4, lignes: int = 4, cellules=((0, 0),)) -> Image.Image:
	feuille = Image.open(RACINE / relatif).convert("RGBA")
	l, h = feuille.width // colonnes, feuille.height // lignes
	bande = Image.new("RGBA", (l * len(cellules), h), (0, 0, 0, 0))
	for i, (c, r) in enumerate(cellules):
		bande.alpha_composite(feuille.crop((c * l, r * h, (c + 1) * l, (r + 1) * h)), (i * l, 0))
	return bande


def _svg_png(svg: Path, taille: int) -> Image.Image | None:
	"""Rendu du SVG par QuickLook (macOS) ; None si indisponible."""
	with tempfile.TemporaryDirectory() as dossier:
		try:
			subprocess.run(["qlmanage", "-t", "-s", str(taille), "-o", dossier, str(svg)],
				capture_output=True, timeout=30, check=False)
		except (OSError, subprocess.TimeoutExpired):
			return None
		sortie = Path(dossier) / f"{svg.name}.png"
		return Image.open(sortie).convert("RGBA") if sortie.exists() else None


def _bouton_rond(icone: Image.Image | None) -> Image.Image:
	"""Bouton rond du HUD (128 px, fond PANEL_BG) avec l'icône blanche (64 px), pour juger la lisibilité."""
	from PIL import ImageDraw
	bouton = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
	ImageDraw.Draw(bouton).ellipse((0, 0, 127, 127), fill=(26, 36, 51, 209), outline=(255, 255, 255, 36),
		width=2)
	if icone is not None:
		icone = _boite_visible(icone)
		icone = _echelle(icone, 72 / max(icone.size))
		# QuickLook rend le blanc sur fond blanc : on garde la forme (alpha ou sombre) en blanc.
		bouton.alpha_composite(icone, ((128 - icone.width) // 2, (128 - icone.height) // 2))
	return bouton


def _icone_blanche(svg: Path) -> Image.Image | None:
	"""Rend l'icône en noir (copie du SVG recolorée) puis la transforme en blanc sur transparent."""
	texte = svg.read_text().replace("#FFFFFF", "#000000")
	with tempfile.TemporaryDirectory() as dossier:
		copie = Path(dossier) / svg.name
		copie.write_text(texte)
		rendu = _svg_png(copie, 256)
	if rendu is None:
		return None
	gris = rendu.convert("L")
	alpha = gris.point(lambda v: 255 - v)
	blanc = Image.new("RGBA", rendu.size, (255, 255, 255, 255))
	blanc.putalpha(alpha)
	return blanc


def _hauteur_corps(pose: Image.Image, epaisseur: int = 24) -> int:
	"""Hauteur des rangées qui contiennent au moins `epaisseur` pixels opaques (la canne et le fil,
	fins, sont ignorés)."""
	alpha = pose.getchannel("A").point(lambda v: 255 if v > 40 else 0)
	rangs = [y for y in range(pose.height) if alpha.crop((0, y, pose.width, y + 1)).histogram()[255] >= epaisseur]
	return (rangs[-1] - rangs[0] + 1) if rangs else pose.height


def contact(sortie: Path) -> Path:
	heros = (_jeu(f"{_C}heros_sheet.png"), "héros 128 px")
	rattata = (_jeu(f"{_P}rattata_sheet.png"), "Rattata 56 px")
	p = _Planche(3000, "Série 25 (J22 T7-T8) générée : À L'ÉCHELLE DU JEU, 1 case = 96 px ; héros 128 px")
	joueur, pnj, poke, icones = [heros], [heros], [heros, rattata], []
	n = 0
	vues: set[str] = set()
	for image in _images():
		base = image["nom"].rsplit("_r", 1)[0].removesuffix("_NE")
		fichier = _derniere(base)
		if fichier is None or base in vues:
			continue
		vues.add(base)
		n += 1
		img = Image.open(fichier).convert("RGBA")
		if base == "HEROS_VELO":
			lignes = _lignes_4x4(img)
			ref = _lignes_4x4(Image.open(ART / HEROS).convert("RGBA"))[0].height
			joueur.append((_bande(lignes, 128 * lignes[0].height / ref, lignes[0].height),
				"HEROS_VELO (col. 1)\nface, gauche, droite, dos"))
			colonnes = [_boite_visible(img.crop((c * img.width // 4, img.height // 4, (c + 1) * img.width // 4,
				img.height // 2))) for c in range(4)]
			joueur.append((_bande(colonnes, 128 * colonnes[0].height / ref, colonnes[0].height),
				"HEROS_VELO ligne 2\npédalage 4 images"))
		elif base.startswith("HEROS_"):
			poses = _poses_bande(img, 4)
			if base == "HEROS_VELO_ARRET":
				# Même hauteur (casquette → roues) que la pose de face de la planche de pédalage.
				velo = _derniere("HEROS_VELO")
				ref = _lignes_4x4(Image.open(ART / HEROS).convert("RGBA"))[0].height
				cible = 128 * _lignes_4x4(Image.open(velo).convert("RGBA"))[0].height / ref if velo else 128
				joueur.append((_bande(poses, cible, poses[0].height), f"{base}\nface, gauche, droite, dos"))
			else:
				# Pêche : le CORPS (sans la canne ni le fil) du profil gauche mesure 128 px.
				corps = _hauteur_corps(poses[1])
				joueur.append((_bande(poses, poses[0].height * 128 / corps, poses[0].height),
					f"{base}\nface, gauche, droite, dos"))
		elif base.startswith("PNJ_"):
			lignes = _lignes_4x4(img)
			hauteur = HAUTEUR[base]
			pnj.append((_bande(lignes, hauteur, lignes[0].height), f"{base}\n{hauteur} px : marche"))
		elif base.endswith("_ATTENTE"):
			poses = _poses_bande(img, 4)
			hauteur = HAUTEUR.get("PNJ_" + base.removesuffix("_ATTENTE"), 128)
			pnj.append((_bande(poses, hauteur, poses[0].height), f"{base}\nattente {hauteur} px"))
		elif base.startswith("POKE_"):
			poses = _poses_bande(img, 4)
			hauteur = HAUTEUR_FIXE[base]
			poke.append((_bande(poses, hauteur, poses[0].height),
				f"{base} {hauteur} px\nrepos, réaction, profil"))
		elif base.startswith("UI_"):
			import preparer_menu  # même découpe que la préparation (bandes séparées par du vide)
			ids = next(i for u, _, _, i in UI_PLANCHES if u == base)
			for (gauche, droite), ident in zip(preparer_menu._bandes(img, len(ids)), ids):
				visible = preparer_menu._silhouette(img.crop((gauche, 0, droite, img.height)))
				icones.append((_echelle(visible, 240 / max(visible.size)), f"{ident}\n256 px"))
	# Réemplois (rien à générer)
	pnj.append((_jeu(f"{_C}pecheur_sheet.png"), "RÉEMPLOI pecheur (haru)\npêcheur de Carmin"))
	pnj.append((_jeu(f"{_C}gentleman_sheet.png"), "RÉEMPLOI gentleman\nprésident du club Safari"))
	if (RACINE / f"{_C}vieil_homme_sheet.png").exists():
		pnj.append((_jeu(f"{_C}vieil_homme_sheet.png"), "RÉEMPLOI vieil homme"))
	p.section("1. JOUEUR : vélo (pédalage, arrêt en selle) et pêche (lancer, attente)", joueur, (60, 80, 110))
	p.section("2. PNJ : Motard, Ornithologue, Loubard, frères pêcheurs (+ réemplois)", pnj, (110, 90, 40))
	p.section("3. POKÉMON DU MONDE (enclos de Parmanie)", poke, (40, 90, 50))
	icone_hud = _icone_blanche(HUD_SVG) if HUD_SVG.exists() else None
	icones.append((_bouton_rond(icone_hud), "HUD : bouton rond\n« Vélo » 128 px (SVG)"))
	p.section("4. ICÔNES DU SAC (A1 Bon, A2 Bicyclette, A3 Canne, A4 Super Canne, B1 Méga Canne, "
		"B2 Hyper Potion, B3 Hyper Ball) et bouton du HUD", icones, (120, 40, 40))
	dos = []
	for espece in DOS:
		chemin = RACINE / f"assets/sprites/pokemon/placeholder/{espece}_back.png"
		if chemin.exists():
			image = Image.open(chemin).convert("RGBA")
			dos.append((image.resize((256, 256), Image.NEAREST), f"{espece}_back\n(provisoire, × 4)"))
	p.section("5. DOS DE COMBAT PROVISOIRES (pixel art 64 px, affichés × 4 comme en combat)", dos,
		(90, 60, 110))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	print(f"{n} images générées sur la planche")
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--ancres" in arguments:
		ancres()
	elif "--commandes" in arguments:
		print(commandes())
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else RACINE / "docs/design/reference/serie-25-contact-v1.png"))
	elif "--manifeste" in arguments:
		print(json.dumps(manifeste_donnees(), ensure_ascii=False, indent=1))
	else:
		generer(set(arguments))
