#!/usr/bin/env python3
"""Série 22 bis — Céladopole et repaire Rocket : façades, intérieurs, modules du repaire et du Casino,
icônes du Sac, compagnon Évoli (reste du kit du jalon 20).
Fiche : docs/design/fiches-assets/serie-22bis-celadopole.md (source de vérité du lot) ; plan :
docs/tech/jalon-20.md §1.4, §2.1, §10.3 ; conception : docs/design/dossier-23-celadopole.md §2, §7-§13, §21.

Règle de remplacement (fiche) : chaque asset garde l'identifiant, les dimensions en pixels et l'emprise de
son PROVISOIRE (`assets/world/buildings/bldg_*_01.png`, `assets/world/props/prop_fontaine_01.png`,
`assets/world/interiors/placeholder/ph_*.png`) ; `--preparer` ramène chaque image retenue aux dimensions
EXACTES du provisoire. Dérogation Q-2 (Kevin, 2026-10-21) : le repaire (B1F à B4F) et le Casino sont en
MODULES (sol, murs, caisses, conduites, consoles, escaliers, flèches, disque d'arrêt, machines...) sur
`cave_map_kit.gd`, comme la Tour en série 21 ; les autres cartes restent en coque peinte (mobilier cuit).

Méthode des séries 19 à 22 : prompts versionnés (`tools/art/prompts/serie22bis/`), recadrages `REF_CB_*`
de la vue validée `celadopole-vue-generale-v1.png` (façades), ancres = assets préparés du dépôt, vagues,
règle de Kevin pour Codex : AVEC les images jointes d'abord (2 essais), puis SANS pièce jointe (2 essais) ;
chaque refus est consigné dans `$ART/refus_serie22bis.log`. La grille fait foi : `tools/plans/celadopole.txt`,
`celadopole_*.txt`, `casino.txt`, `repaire_*.txt`.

Lumière : NEUTRE (« NE ») pour tout. Façades : le profil `golden_hour` de la carte fait l'heure dorée (on ne
la peint pas : les recadrages de la vue sont dorés, on n'en reprend ni la lumière ni les halos des fenêtres) ;
intérieurs : `interior_warm` ; Casino : halos `neon` du jeu ; repaire : profil froid et néons du jeu.

Images (vagues 1, 2, 3 ; 3 = conditionnels, jamais lancés sans leur nom) :
  A. façades + fontaine (11, vague 1) ;
  B. coques d'intérieur : une coque par GÉOMÉTRIE distincte, déclinée par étage à la préparation (voir
     `COQUES`) ; vague 1 : rez-de-chaussée, toits, maison du toit, restaurant, maison du chef, hôtel,
     Arène, ascenseur du magasin ; vague 2 : étages qui joignent le rez-de-chaussée, ascenseur du repaire ;
  C. repaire : sol, murs (vague 1) puis deux planches de modules (vague 2) ;
  D. Casino : moquette, murs (vague 1) puis planche de mobilier (vague 2) ;
  E. icônes du Sac (29, 8 planches 4 × 1) ;
  F. Évoli compagnon : planche de marche 4 × 4 (SANS image jointe) et d'attente 4 × 1.
Voltali et Pyroli (dos de combat) : hors lot (Q-4).

Usage :
  tools/art/serie22bis.py --prompts               écrit les prompts versionnés (sans Codex)
  tools/art/serie22bis.py --refs                  recadre les REF_CB_* de la vue de Céladopole
  tools/art/serie22bis.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie22bis.py --preparer              images retenues → $ART/serie22bis/ aux dimensions EXACTES
                                                  des provisoires (sans Codex)
  tools/art/serie22bis.py --contact               planches de contact pour Kevin : $ART/SERIE22BIS_CONTACT_*.png
  tools/art/serie22bis.py --manifeste             ajoute les entrées en fin de manifeste.json (NE PAS lancer
                                                  avant la validation des images)
  tools/art/serie22bis.py [IDENTIFIANT ...]       génère avec Codex, par vagues (sans argument : la série
                                                  sans les conditionnels ; --refs fait d'abord)
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie10  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE, TEXTURE_FIN  # noqa: E402
from serie10 import (CASE_PLANCHE, _asset, _cellule_perso, _echelle, _fin_de_liste,  # noqa: E402
	_Planche)


ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
SORTIE = ART / "serie22bis"
PROMPTS = ICI / "prompts" / "serie22bis"

REFERENCE = RACINE / "docs/design/reference"
VUE = REFERENCE / "celadopole-vue-generale-v1.png"  # 1536 × 1024, validée le 2026-10-15

## Recadrages de la vue validée : (boîte en pixels de la vue). Agrandis × 3 au plus, sans dépasser 1 536 px.
## Boîtes recalées à l'œil sur la vue (2026-10-21) : chaque boîte tombe sur un seul bâtiment. Les
## personnages (fillette du magasin, Rocket en civil du Casino) restent dans deux recadrages : les prompts
## demandent de les ignorer.
REFS = {
	"REF_CB_MAGASIN": (112, 40, 424, 305),      # grand magasin : trois niveaux, auvents verts, toit-terrasse
	"REF_CB_TOIT_MAGASIN": (118, 45, 418, 150),  # toit-terrasse : parasols, bacs, édicule, garde-corps
	"REF_CB_RESIDENCE": (512, 92, 788, 322),    # Résidence : pierre miel, ardoise, lucarnes, jardinières
	"REF_CB_ESCALIER": (636, 10, 730, 115),     # tourelle de l'escalier de service, au nord de la Résidence
	"REF_CB_CASINO": (736, 512, 998, 692),      # toit magenta, façade violette, bandeau de néons, cordons
	"REF_CB_COIN_LOTS": (1030, 515, 1220, 688),  # ancien Coin à lots : béton, vitrine éteinte
	"REF_CB_SERRE": (128, 556, 404, 795),       # Arène : serre, verrière, palmiers, porte vitrée en arc
	"REF_CB_RESTAURANT": (742, 740, 924, 898),  # tuiles orange, store rayé, jardinières
	"REF_CB_HOTEL": (980, 740, 1224, 898),      # ardoise bleue à lucarnes, volets bleus
	"REF_CB_CHEF": (522, 740, 698, 898),        # maison de ville, tuiles terre cuite
	"REF_CB_FONTAINE": (608, 556, 684, 640),    # vasque de pierre claire, jet d'eau
}
AGRANDIR = 3
REF_MAX = 1536

# --- Ancres (assets préparés du dépôt, toujours présents) -------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"
_PH = f"{_W}interiors/placeholder/"
STYLE = [f"{_W}props/prop_souche_01.png", f"{_W}props/tree_a_01.png"]
MUSEE = f"{_W}buildings/bldg_musee_argenta_01.png"
POSTE = f"{_W}buildings/bldg_poste_safrania_01.png"
BOUTIQUE = f"{_W}buildings/bldg_boutique_01.png"
SERRE = f"{_W}buildings/bldg_serre_01.png"
ARENE_AZURIA = f"{_W}buildings/bldg_arene_azuria_01.png"
PENSION = f"{_W}buildings/bldg_pension_01.png"
FAN_CLUB = f"{_W}buildings/bldg_fan_club_01.png"
MAISON_ARGENTA = f"{_W}buildings/bldg_maison_argenta_01.png"
MAISON_POKEMON = f"{_W}buildings/bldg_maison_pokemon_01.png"
CENTRALE = f"{_W}buildings/bldg_centrale_lointaine_01.png"
TOUR_POKEMON = f"{_W}buildings/bldg_tour_pokemon_01.png"
MARE = f"{_W}props/prop_mare_grotte_01.png"
PAVE = f"{_W}ground/ground_paves_01.png"
DALLES_SO = f"{_W}ground/ground_dalles_souterrain_01.png"  # série 17
DALLES_TOUR = f"{_W}ground/ground_dalles_tour_01.png"  # série 21
MURS_TOUR = [f"{_W}relief/relief_mur_tour_0{i}.png" for i in (1, 2, 3, 4, 5)]  # gabarit des rôles
MURS_SO = [f"{_W}relief/relief_mur_souterrain_0{i}.png" for i in (1, 3, 4)]  # gabarit des rôles
ESCALIER_SO = f"{_W}props/prop_escalier_souterrain_monte_01.png"
COMPTOIR = f"{_W}interiors/int_comptoir_pension_01.png"
COQUE_CENTRE = f"{_W}interiors/int_centre_coque.png"
COQUE_BOUTIQUE = f"{_W}interiors/int_boutique_coque.png"
COQUE_MAISON = f"{_W}interiors/int_maison_argenta_coque.png"
COQUE_RESTAURANT = f"{_W}interiors/int_ss_anne_restaurant_coque.png"
COQUE_ARENE = f"{_W}interiors/int_arene_azuria_coque.png"
COQUE_MUSEE = f"{_W}interiors/int_musee_coque.png"
ICONES = f"assets/ui/items/"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, enseigne, inscription, plaque écrite, "
	"la lettre R ou tout emblème de la Team Rocket, AUCUN emblème rond de type balle (ni cercle partagé en "
	"deux, ni médaillon à bande centrale) sauf sur le Centre existant, animaux réels, Pikachu et tout Pokémon "
	"non demandé, personnage (même s'il figure sur une image jointe : ne le reproduis pas), flou de "
	"profondeur, vignettage.")

LUMIERE_FACADE = (LUMIERE_NE + " La carte est étalonnée par le jeu en « golden hour » (profil `golden_hour`) : "
	"peins la lumière NEUTRE et les couleurs LOCALES des matériaux, AUCUNE teinte dorée ni orangée, AUCUN "
	"halo ni lueur aux fenêtres (le jeu allume lui-même les vitres).")

VALEURS_VILLE = ("VALEURS DE CÉLADOPOLE (exception de palette à l'ADN : une ville élégante et prospère) : pierre de "
	"taille crème et miel, ardoise bleu-gris, tuiles terre cuite et orange, vert sauge et vert franc des "
	"jardinières et des haies, bois brun chaud des portes, touches de laiton doré ; fleurs de printemps "
	"(blanc, rose, lavande, jaune) en jardinières ; propre, soigné, accueillant. " + LUMIERE_FACADE)

VALEURS_INTERIEUR = ("VALEURS DES INTÉRIEURS DE CÉLADOPOLE (palette de l'ADN, intérieurs élégants et chaleureux : bois "
	"clair et miel, pierre crème, tissus et accents de couleur selon la pièce) ; lumière NEUTRE, diffuse et "
	"blanche venant légèrement du haut à gauche (le jeu ajoute lui-même l'ambiance chaude `interior_warm` : "
	"AUCUNE teinte dorée ni orangée, AUCUNE flaque de lumière, AUCUN halo, aucune ombre portée au sol hors des "
	"ombres propres sous les meubles). Les fenêtres montrent du ciel pâle ou du feuillage, jamais un décor.")

VALEURS_REPAIRE = ("VALEURS DU REPAIRE ROCKET (exception de palette à l'ADN : une base souterraine industrielle, propre, "
	"froide et un peu austère, JAMAIS effrayante) : béton gris-bleu, acier brossé, gris anthracite, touches de "
	"jaune sécurité et de rouge sombre ; lumière NEUTRE, diffuse et blanche (le jeu ajoute lui-même "
	"l'ambiance froide, les néons et la pénombre : ne peins NI pénombre, NI flaque de lumière, NI halo, NI "
	"rayon, NI lueur d'écran) ; contraste doux, aucune ombre portée. Aucune lettre R, aucun logo, aucun "
	"emblème, aucun texte, aucune inscription.")

VALEURS_CASINO = ("VALEURS DU CASINO DE CÉLADOPOLE (exception de palette à l'ADN : un salon de jeu élégant, fermé pour "
	"inventaire) : prune et violet profond, bordeaux, laiton et or, crème, bois sombre verni ; lumière "
	"NEUTRE, diffuse et blanche (les halos `neon` du jeu font la lumière : ne peins RIEN de lumineux au-delà "
	"des tubes eux-mêmes, NI halo, NI lueur, NI reflet coloré sur le sol) ; aucune ombre portée. Aucun "
	"jeton, aucune carte, aucun chiffre, aucun symbole de jeu lisible, aucun texte.")

# --- A. Façades et fontaine --------------------------------------------------------------

## Dimensions finales = celles du provisoire (la fiche, §A) ; relues sur le fichier à la préparation, qui
## signale tout écart avec cette table.
TAILLES = {
	"bldg_grand_magasin_01": (1344, 888), "bldg_residence_01": (1152, 792),
	"bldg_escalier_service_01": (384, 408), "bldg_casino_01": (1152, 696),
	"bldg_coin_lots_01": (768, 696), "bldg_arene_celadopole_01": (1152, 696),
	"bldg_restaurant_01": (768, 696), "bldg_hotel_01": (960, 696), "bldg_maison_chef_01": (672, 600),
	"bldg_maison_toit_01": (480, 408), "prop_fontaine_01": (192, 186),
}


def _ord(n: int) -> str:
	return "1re" if n == 1 else f"{n}e"


def _porte(largeur: int, col: int, nombre: int) -> str:
	"""Position de la porte (colonnes comptées depuis 1, à gauche) : fixée en toutes lettres."""
	cols = _ord(col) if nombre == 1 else f"{_ord(col)} et {_ord(col + 1)}"
	un = "UNE case" if nombre == 1 else "DEUX cases"
	return (f"PORTE : {un} de large, au bas de la façade, exactement sur la {cols} colonne{'s' if nombre > 1 else ''} "
		f"sur {largeur} (1 colonne = 1/{largeur} de la largeur du bâtiment, 1 case = 96 px dans le jeu) ; "
		"le reste du bas de la façade ne porte AUCUNE autre porte ; le seuil est au ras du bas de l'image.")


## Façades : (identifiant, asset, référence principale, références supplémentaires, largeur en cases,
## profondeur, colonne de la porte (depuis 1) et nombre de cases, description, ancres, vague).
## La largeur en pixels du provisoire = largeur × 96 ; sa hauteur = profondeur × 96 + 24 (rebord de toit).
FACADES = [
	("WORLD_BLDG_GRAND_MAGASIN_01", "bldg_grand_magasin_01", "REF_CB_MAGASIN", ["REF_CB_TOIT_MAGASIN"], 14, 9, (7, 2),
		"le GRAND MAGASIN de Céladopole, façade de face : le bâtiment le PLUS HAUT de la ville, de pierre de taille "
		"CRÈME en assises régulières, 14 cases de large et environ 9,25 de haut en tout (vu en trois quarts de "
		"dessus : on voit la façade ET, en haut de l'image, le TOIT-TERRASSE) ; reproduire la vue jointe en plus "
		"net. TROIS NIVEAUX de hautes fenêtres à petits carreaux (huit par niveau environ), balconnets de fer fin et "
		"jardinières fleuries au premier niveau, pilastres et corniches de pierre claire entre les niveaux ; "
		"REZ-DE-CHAUSSÉE de grandes VITRINES aux étalages colorés (objets en boîtes, sans texte), "
		"surmontées d'AUVENTS VERTS rayés, et de part et d'autre de la porte quelques petits buis en pot ; "
		"au MILIEU du bas, une PORTE DOUBLE vitrée à cadre de laiton, deux marches basses. TOIT-TERRASSE : un "
		"dallage clair bordé d'un garde-corps de pierre, des PARASOLS crème, des plantes en BACS, de petits "
		"arbustes, un ÉDICULE (cage d'escalier) en pierre à droite ; reproduire le toit de la vue jointe. "
		"Sans arbre autour, sans massif, sans haie, sans personnage, sans enseigne, sans lettre (le provisoire "
		"joint porte le mot « GRAND MAGASIN » : ne le reproduis pas).",
		[MUSEE, POSTE, BOUTIQUE], 1),
	("WORLD_BLDG_RESIDENCE_01", "bldg_residence_01", "REF_CB_RESIDENCE", [], 12, 8, (6, 2),
		"la RÉSIDENCE CÉLADON, façade de face : une maison bourgeoise de pierre MIEL (jaune doré clair) aux "
		"chaînages de pierre claire, 12 cases de large et environ 8,25 de haut en tout, deux niveaux de hautes "
		"fenêtres à petits carreaux encadrées de pierre claire, un TOIT MANSARDÉ d'ARDOISE gris-bleu avec TROIS "
		"LUCARNES à fronton, deux CHEMINÉES de pierre, des JARDINIÈRES FLEURIES (blanc, rose, lavande) sous les "
		"fenêtres et un petit balcon de fer au-dessus de la porte ; au MILIEU du bas, une PORTE DOUBLE de bois "
		"brun sous un petit fronton de pierre, un PERRON de deux ou trois marches. Reproduire la vue jointe en "
		"plus net. Sans haie, sans arbre, sans banc, sans massif au sol, sans personnage, aucune inscription.",
		[MUSEE, MAISON_POKEMON], 1),
	("WORLD_BLDG_ESCALIER_SERVICE_01", "bldg_escalier_service_01", "REF_CB_ESCALIER", ["REF_CB_RESIDENCE"], 4, 4, (2, 2),
		"la petite TOURELLE de l'ESCALIER DE SERVICE de la Résidence (accès au toit), façade de face : un "
		"petit bâtiment carré de pierre MIEL, au MÊME appareil de pierre et à la MÊME ardoise que la Résidence "
		"jointe, 4 cases de large et environ 4,25 de haut en tout, un toit d'ARDOISE gris-bleu à quatre pans, "
		"une PORTE DE SERVICE sobre à deux battants de bois sombre sous un linteau de pierre, une marche, une "
		"petite fenêtre haute de chaque côté de la porte ; sobre et utilitaire. SANS enseigne et SANS "
		"inscription (le provisoire joint porte le mot « SERVICE » : ne le reproduis pas). Sans arbre, sans "
		"massif, sans personnage.",
		[MAISON_POKEMON, MUSEE], 1),
	("WORLD_BLDG_CASINO_01", "bldg_casino_01", "REF_CB_CASINO", [], 12, 7, (6, 2),
		"le CASINO de Céladopole, façade de face : le SEUL bâtiment aux NÉONS de la ville ; 12 cases de large et "
		"environ 7,25 de haut en tout ; un TOIT MAGENTA à pans plats cerclé d'un liseré d'or, une FAÇADE "
		"VIOLETTE (prune profond) avec pilastres et moulures dorées, un BANDEAU de TUBES de néon MAGENTA et "
		"OR sous la corniche (de simples tubes peints : motifs géométriques, étoiles, volutes, JAMAIS des lettres "
		"ni des mots), quelques fenêtres hautes sombres, de petits buis en pot de chaque côté de l'entrée, des "
		"CORDONS de velours rouge sur potelets dorés devant la porte ; au MILIEU du bas, une PORTE DOUBLE vitrée "
		"à cadre doré, deux marches basses. Reproduire la vue jointe en plus net ; rien de lumineux n'est peint "
		"au-delà des tubes eux-mêmes (le jeu ajoute les halos de néon). Sans personnage (ignore le monsieur "
		"à chapeau de la vue jointe), sans enseigne, sans lettre (le provisoire joint porte le mot « CASINO » : "
		"ne le reproduis pas).",
		[POSTE, BOUTIQUE], 1),
	("WORLD_BLDG_COIN_LOTS_01", "bldg_coin_lots_01", "REF_CB_COIN_LOTS", [], 8, 7, None,
		"l'ancien COIN À LOTS de Céladopole, FERMÉ, façade de face : un bâtiment commercial de BÉTON gris "
		"(gris chaud, un peu sale, patine de pluie) de 8 cases de large et environ 7,25 de haut en tout, toit plat "
		"gris foncé avec un rebord de béton, au bas une grande VITRINE en bandeau horizontal ÉTEINTE (vitres "
		"sombres gris-bleu, VIDES, sans étalage) avec des petits-bois noirs, des VOLETS roulants métalliques "
		"baissés sur les côtés, quelques traînées de patine ; reproduire la vue jointe en plus net. AUCUNE "
		"PORTE (le bas de la façade est un mur plein et la vitrine ; rien qui invite à entrer), aucune enseigne, "
		"aucun écriteau, aucune lumière, aucun jeton, aucun objet de jeu, aucune affiche. Sans arbre, sans "
		"personnage.",
		[CENTRALE, POSTE], 1),
	("WORLD_BLDG_ARENE_CELADOPOLE_01", "bldg_arene_celadopole_01", "REF_CB_SERRE", [], 12, 7, (6, 2),
		"l'ARÈNE de Céladopole, une SERRE élégante, façade de face : charpente BLANCHE fine (montants et "
		"arceaux), VERRIÈRE vert d'eau en grands pans vitrés à petits-bois, un corps central plus haut en berceau "
		"et deux ailes basses, 12 cases de large et environ 7,25 de haut en tout, un soubassement de pierre claire ; "
		"à travers les vitres on devine des PALMIERS, du feuillage tropical et des fleurs (touches de rose, "
		"orange et blanc) ; des massifs de fleurs et des buis au pied des ailes ; au MILIEU du bas, des PORTES "
		"VITRÉES en ARC à cadre blanc, deux marches basses. Reproduire la vue jointe en plus net. Sans haie "
		"(l'enclos de haies est fait par la carte), sans chemin dallé, sans personnage, aucune inscription, "
		"aucun emblème.",
		[SERRE, ARENE_AZURIA], 1),
	("WORLD_BLDG_RESTAURANT_01", "bldg_restaurant_01", "REF_CB_RESTAURANT", [], 8, 7, (4, 2),
		"le RESTAURANT de Céladopole, façade de face : une maison de ville de 8 cases de large et environ 7,25 de "
		"haut en tout, un grand TOIT de TUILES ORANGE à quatre pans avec deux petites cheminées, des murs crépis "
		"CRÈME et un soubassement de pierre ; au-dessus de la devanture un STORE RAYÉ crème et orange à "
		"bord festonné, deux fenêtres à petits carreaux, des JARDINIÈRES fleuries et des pots de fleurs au pied "
		"des murs ; au MILIEU du bas, une PORTE DOUBLE de bois brun. Reproduire la vue jointe en plus net. Sans "
		"enseigne, sans menu, sans table dehors, sans arbre, sans personnage, aucune inscription.",
		[PENSION, FAN_CLUB], 1),
	("WORLD_BLDG_HOTEL_01", "bldg_hotel_01", "REF_CB_HOTEL", [], 10, 7, (5, 2),
		"l'HÔTEL de Céladopole, façade de face : un hôtel de ville de 10 cases de large et environ 7,25 de haut en "
		"tout, un toit d'ARDOISE BLEUE à quatre pans avec TROIS LUCARNES à fronton, des murs de pierre CRÈME en "
		"assises, de hautes fenêtres à petits carreaux flanquées de VOLETS BLEUS, des jardinières fleuries et "
		"de petits buis en pot ; au MILIEU du bas, une PORTE DOUBLE de bois brun sous une petite MARQUISE "
		"de verre et de laiton (sobre) et une petite plaque de laiton lisse à côté, SANS AUCUNE inscription ; "
		"AUCUNE enseigne lumineuse. Reproduire la vue jointe en plus net. Sans arbre, sans personnage.",
		[POSTE, FAN_CLUB, MAISON_ARGENTA], 1),
	("WORLD_BLDG_MAISON_CHEF_01", "bldg_maison_chef_01", "REF_CB_CHEF", [], 7, 6, (4, 1),
		"la MAISON DU CHEF de Céladopole, façade de face : une maison de ville de 7 cases de large et environ 6,25 de "
		"haut en tout, un TOIT de TUILES TERRE CUITE à quatre pans avec une cheminée de pierre, des murs crépis "
		"CRÈME, un soubassement de pierre ; DEUX fenêtres à petits carreaux avec jardinières fleuries, des pots "
		"de fleurs au pied des murs ; sur la 4e colonne, une PORTE de bois brun d'UNE case sans auvent. "
		"Reproduire la vue jointe en plus net ; même gabarit et même main que la maison jointe. Sans arbre, "
		"sans clôture, sans personnage, aucune inscription.",
		[MAISON_ARGENTA, PENSION], 1),
	("WORLD_BLDG_MAISON_TOIT_01", "bldg_maison_toit_01", "REF_CB_RESIDENCE", ["REF_CB_ESCALIER"], 5, 4, (3, 1),
		"la petite MAISON DU TOIT de la Résidence (posée sur la terrasse d'ardoise du toit ; absente de la vue "
		"générale, dont les recadrages joints ne donnent que la MATIÈRE) : une petite maison de 5 cases de large et "
		"environ 4,25 de haut en tout, de pierre MIEL au MÊME appareil que la Résidence jointe, un toit "
		"d'ARDOISE gris-bleu à deux pans de la MÊME ardoise, une petite cheminée, une porte de bois brun "
		"d'UNE case sur la 3e colonne, DEUX petites fenêtres à petits carreaux, des POTS de fleurs (rose, "
		"blanc, lavande) devant les murs ; chaleureuse et soignée (c'est là qu'on reçoit Évoli). Sans terrasse "
		"autour, sans parapet, sans arbre, sans personnage, aucune inscription.",
		[MAISON_ARGENTA, MAISON_POKEMON], 1),
]

FONTAINE = ("WORLD_PROP_FONTAINE_01", "prop_fontaine_01", "REF_CB_FONTAINE", 2, 2,
	"la FONTAINE de la place de Céladopole, image FIXE (sans animation) : une VASQUE ronde de pierre CLAIRE "
	"(crème) à margelle épaisse arrondie posée sur un petit socle, remplie d'une eau limpide bleu-vert aux "
	"petites vaguelettes claires, et au centre un JET D'EAU fin qui monte puis retombe en gouttes dans la "
	"vasque ; 2 cases de large et environ 1,95 de haut avec le jet ; reproduire la fontaine de la vue jointe "
	"en plus net. Sans pavés autour, sans banc, sans fleurs, sans personnage (ignore le garçon de la vue "
	"jointe), sans poisson, sans pièce, aucun halo, aucune lueur autour de l'eau.",
	[MARE])


# --- B. Coques d'intérieur -----------------------------------------------------------------

_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur en haut, "
	"on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur épaisseur vue de "
	"dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue de dessus. Même "
	"construction, même angle et même finesse que les pièces jointes (celles-ci sont VIDES : toi, tu ajoutes "
	"le mobilier décrit plus bas).")


def _lire_grille(nom: str) -> list[str]:
	rangees: list[str] = []
	actif = False
	for ligne in (RACINE / "tools" / "plans" / (nom + ".txt")).read_text().splitlines():
		if ligne.startswith("GRILLE"):
			actif = True
			continue
		if actif and ligne.startswith("FIN"):
			break
		if actif and ligne[:2].isdigit():
			rangees.append(ligne.split(" ", 1)[1].strip())
	return rangees


def _composantes(rangees: list[str], car: str) -> list[tuple[int, int, int, int]]:
	"""Boîtes (x0, y0, x1, y1) des composantes connexes (4 voisins) du caractère `car`, en ordre de lecture."""
	vu: set[tuple[int, int]] = set()
	boites = []
	for y, rangee in enumerate(rangees):
		for x, c in enumerate(rangee):
			if c != car or (x, y) in vu:
				continue
			pile, cases = [(x, y)], []
			vu.add((x, y))
			while pile:
				cx, cy = pile.pop()
				cases.append((cx, cy))
				for vx, vy in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
					if (0 <= vy < len(rangees) and 0 <= vx < len(rangees[vy]) and rangees[vy][vx] == car
							and (vx, vy) not in vu):
						vu.add((vx, vy))
						pile.append((vx, vy))
			xs, ys = [p[0] for p in cases], [p[1] for p in cases]
			boites.append((min(xs), min(ys), max(xs), max(ys)))
	return sorted(boites, key=lambda b: (b[1], b[0]))


def _format_generation(largeur: int, hauteur: int) -> tuple[int, int]:
	"""Format de génération le plus proche du rapport de l'image finale (les trois formats de Codex)."""
	rapport = largeur / hauteur
	if rapport >= 1.2:
		return (1536, 1024)
	if rapport <= 0.8:
		return (1024, 1536)
	return (1024, 1024)


def _pct(valeur: float, total: int) -> int:
	return round(100 * valeur / total)


def _plan_texte(nom: str, legende: dict[str, str], gen: tuple[int, int]) -> str:
	"""Description CASE PAR CASE de la grille `nom` (tools/plans/<nom>.txt) pour une image de `gen` pixels :
	murs, sol et chaque élément (composante connexe) en colonnes, rangées et fractions de l'image. La grille
	fait foi : le texte est calculé, jamais écrit à la main."""
	rangees = _lire_grille(nom)
	h, w = len(rangees), len(rangees[0])
	sol = [y for y, r in enumerate(rangees) if "." in r]
	haut, bas = sol[0], h - 1 - sol[-1]
	cases_sol = [x for r in rangees[haut:h - bas] for x, c in enumerate(r) if c != "K"]
	gauche, droite = min(cases_sol), w - 1 - max(cases_sol)
	cw, ch = gen[0] / w, gen[1] / h
	lignes = [f"L'image ({gen[0]} × {gen[1]} px) est une GRILLE de {w} colonnes × {h} rangées ; une case mesure "
		f"environ {cw:.0f} × {ch:.0f} px dans l'image (elle sera ramenée à 96 × 96 px). Colonnes comptées depuis "
		"1 à GAUCHE, rangées comptées depuis 1 EN HAUT ; les pourcentages sont des fractions de la largeur "
		"(colonnes) ou de la hauteur (rangées) de l'image.",
		f"- MUR DU FOND : rangées 1 à {haut} (de 0 % à {_pct(haut, h)} % de la hauteur), pleine largeur, face avant "
		f"visible. MURS LATÉRAUX : {gauche} colonne{'s' if gauche > 1 else ''} à gauche (de 0 % à "
		f"{_pct(gauche, w)} %) et {droite} à droite (de {_pct(w - droite, w)} % à 100 %), épaisseur vue de "
		f"dessus. MUR DU BAS : rangées {h - bas + 1} à {h} (de {_pct(h - bas, h)} % à 100 %), épaisseur vue de "
		f"dessus. SOL : colonnes {gauche + 1} à {w - droite}, rangées {haut + 1} à {h - bas}, LIBRE et VIDE sauf "
		"les éléments ci-dessous (tout le reste du sol reste dégagé : on y place des personnages)."]
	for car in sorted({c for r in rangees for c in r} - {"K", "."}):
		for x0, y0, x1, y1 in _composantes(rangees, car):
			quoi = legende.get(car, f"élément « {car} »")
			col = f"colonne {x0 + 1}" if x0 == x1 else f"colonnes {x0 + 1} à {x1 + 1}"
			rang = f"rangée {y0 + 1}" if y0 == y1 else f"rangées {y0 + 1} à {y1 + 1}"
			lignes.append(f"- {quoi} : {col} (de {_pct(x0, w)} % à {_pct(x1 + 1, w)} % de la largeur), {rang} (de "
				f"{_pct(y0, h)} % à {_pct(y1 + 1, h)} % de la hauteur), soit {x1 - x0 + 1} × {y1 - y0 + 1} case(s).")
	return "\n".join(lignes)


## Légendes (caractère de la grille → élément à peindre). Les cases « libres » (.) restent vides.
_L_DEPT = {
	"S": "ESCALIER qui MONTE vers l'étage au-dessus, pris dans le mur du fond (marches de pierre claire et rampes "
		"qui montent vers le haut de l'image)",
	"Z": "ESCALIER qui DESCEND vers l'étage en dessous, pris dans le mur du fond (rampes, marches qui s'enfoncent "
		"vers le bas de l'image)",
	"V": "PORTE D'ASCENSEUR dans le mur du fond : double porte coulissante en métal brossé clair à cadre de laiton, "
		"fermée",
	"X": "SORTIE : ouverture dans le mur du bas, seuil de pierre et PAILLASSON uni de la couleur de l'accent",
	"B": "COMPTOIR de vente en bois clair verni à dessus de pierre crème, un côté ouvert vers le haut de "
		"l'image (le vendeur est derrière), caisse enregistreuse sans écran lisible",
	"e": "RAYONNAGE (étagères et vitrine garnies de boîtes, flacons et objets colorés SANS texte, bloquant)",
	"m": "MACHINE : distributeur ou borne en décor (corps de métal et de couleur d'accent, écran sombre sans image)",
	"t": "TABLE basse ronde ou carrée de bois clair avec des objets posés",
	"c": "CANAPÉ (banquette capitonnée de la couleur de l'accent, vue de face)",
	"n": "BANC de bois clair",
	"p": "grande PLANTE en pot (feuillage vert, pot de terre cuite)",
	"P": "TABLEAU DES ÉTAGES : grand panneau de laiton encadré au mur du fond, SANS texte ni chiffre : une colonne "
		"de cinq pastilles de couleur (sarcelle, rose, violet, ambre, bleu) sur fond crème",
}
_L_MANSION = {
	"S": "ESCALIER MONTANT dans le mur du fond (marches de pierre, rampe de bois sombre, tapis rouge sombre au "
		"milieu qui monte vers le haut de l'image)",
	"Z": "ESCALIER DESCENDANT dans le mur du fond (marches qui s'enfoncent vers le bas de l'image, rampe de bois)",
	"X": "SORTIE : ouverture dans le mur du bas, seuil de pierre et paillasson de laine bordeaux",
	"c": "CANAPÉ de salon de velours bordeaux, vu de face",
	"t": "TABLE basse de bois sombre avec un vase de fleurs",
	"n": "BANC capitonné de bois sombre et de velours",
	"p": "grande PLANTE en pot (grand pot de céramique, feuillage vert)",
	"f": "PORTE FERMÉE à deux battants de bois sombre dans le mur du fond, plaque de laiton VIERGE (aucune inscription)",
}
_L_RESTAURANT = {
	"X": "SORTIE : ouverture dans le mur du bas, seuil de pierre et paillasson uni",
	"B": "COMPTOIR de service en bois verni à dessus de marbre crème, avec une cuisine ouverte derrière (plan de "
		"travail inox, casseroles, étagère de vaisselle), vu de face",
	"t": "TABLE NAPPÉE (nappe blanche, couverts et verres simples, petit vase) avec ses chaises",
	"c": "BANQUETTE capitonnée",
	"p": "grande PLANTE en pot",
	"e": "ÉTAGÈRE murale de bouteilles et de vaisselle",
}
_L_MAISON = {
	"X": "SORTIE : ouverture dans le mur du bas, seuil de pierre et paillasson",
	"c": "CANAPÉ de salon, vu de face",
	"t": "TABLE basse avec des objets simples",
	"p": "grande PLANTE en pot",
	"e": "ÉTAGÈRE / bibliothèque pleine de livres (sans titre lisible) et de bibelots",
	"B": "COMPTOIR de réception en bois clair verni",
}
_L_HOTEL = dict(_L_MAISON, B="COMPTOIR de RÉCEPTION en bois verni et marbre crème, sonnette de laiton, casiers à "
	"clés derrière (sans numéro), vu de face", c="BANQUETTE / canapé de salon d'hôtel",
	e="ÉTAGÈRE murale avec livres et petits vases")
_L_TOIT = {
	"Z": "ESCALIER DESCENDANT (cage d'escalier ouverte de la terrasse : marches qui s'enfoncent vers le bas de "
		"l'image, rampe de métal)",
	"m": "DISTRIBUTEUR de boissons (grand caisson de métal clair, vitre sombre, sans texte ni image, tranche de "
		"couleur différente pour chacun)",
	"n": "BANC de bois clair",
	"p": "grand BAC de plantes (bac de bois clair, feuillage vert, fleurs)",
	"N": "MAISON DU TOIT (emprise réservée : peins ici UNIQUEMENT le dallage de la terrasse, la maison est "
		"ajoutée par le jeu)",
	"D": "PORTE de la maison du toit (emprise réservée : dallage seulement)",
}
_L_GYM = {
	"w": "BASSIN d'eau limpide bleu-vert bordé d'une margelle de pierre claire, nénuphars discrets",
	"x": "HAIE taillée de buis vert sauge, basse et dense (bande continue)",
	"j": "MASSIF taillé de fleurs (blanc, rose, lavande) dans un cadre de pierre",
	"W": "ARBUSTE ROND épais à tailler (feuillage vert franc, clairement différent d'une haie : un buisson dense "
		"isolé dans une ouverture de la haie)",
	"X": "SORTIE : ouverture dans le mur du bas, dalle de pierre et seuil",
}
_L_ASCENSEUR_MAGASIN = {
	"P": "PANNEAU D'ÉTAGES : 2 cases de large dans le mur du fond, grand cadre de laiton avec cinq boutons ronds "
		"alignés de couleurs différentes, SANS aucun chiffre ni texte",
	"X": "SORTIE : double porte coulissante en métal brossé, ouverte sur le seuil, dans le mur du bas",
}
_L_ASCENSEUR_REPAIRE = {
	"P": "PANNEAU D'ÉTAGES : une case dans le mur du fond, boîtier d'acier avec trois boutons alignés, un "
		"petit voyant éteint, SANS aucun chiffre ni texte",
	"L": "DEUX PORTES D'ASCENSEUR coulissantes dans le mur du fond, en acier brossé gris-bleu, fermées",
}

## Coques : une image par GÉOMÉTRIE distincte. (identifiant, cartes servies [la première nomme le provisoire
## joint], grille, légende, ancres, vague, jointes de la vague 1, description de la pièce).
## Géométrie comparée le 2026-10-21 : les 5 étages du magasin ont 4 grilles (le 2e et le 4e sont IDENTIQUES), les
## 4 étages de la Résidence en ont 3 (le 1er et le 2e sont IDENTIQUES) : les étages identiques partagent
## une coque, déclinée (accent du magasin) par recoloration à la préparation (`DECLINAISONS`).
MAGASIN = ("un GRAND MAGASIN élégant de la ville (comme la façade : pierre crème, bois clair verni, laiton), "
	"sol de PARQUET clair en larges lames avec un grand TAPIS d'allée central de la couleur de l'accent, murs "
	"de pierre crème et de lambris clair, une PLINTHE et un LISERÉ de la couleur de l'accent le long des murs, "
	"hautes fenêtres à petits carreaux dans le mur du fond montrant un ciel pâle, quelques appliques de laiton "
	"(sans halo) ; ")
COQUES = [
	("INT_CELADON_DEPT_GF_COQUE", ["celadon_dept_gf"], "celadopole_magasin_rdc", _L_DEPT,
		[COQUE_BOUTIQUE, COQUE_CENTRE, ESCALIER_SO], 1, [],
		"le RAYON D'ACCUEIL du grand magasin, rez-de-chaussée : " + MAGASIN + "ACCENT SARCELLE (bleu-vert). Un "
		"grand COMPTOIR d'accueil central (hôtesse derrière, non dessinée), le tableau des étages au centre "
		"du mur du fond, deux petites plantes en pot devant le mur du fond, deux grandes plantes dans les angles du "
		"bas ; le plus calme et le plus aéré des étages."),
	("INT_CELADON_DEPT_2F_COQUE", ["celadon_dept_2f", "celadon_dept_4f"], "celadopole_magasin_2e", _L_DEPT,
		[COQUE_BOUTIQUE, COQUE_CENTRE, ESCALIER_SO], 2, ["INT_CELADON_DEPT_GF_COQUE_NE_r1.png"],
		"un ÉTAGE DE VENTE du grand magasin (2e et 4e étages : la même salle, l'accent change à la préparation) : "
		+ MAGASIN + "ACCENT ROSE (rose franc, pas fuchsia) ; DEUX comptoirs de vente séparés (un par vendeur) et "
		"de HAUTS rayonnages tout le long des murs gauche et droit ; une allée libre au centre."),
	("INT_CELADON_DEPT_3F_COQUE", ["celadon_dept_3f"], "celadopole_magasin_3e", _L_DEPT,
		[COQUE_BOUTIQUE, COQUE_CENTRE, ESCALIER_SO], 2, ["INT_CELADON_DEPT_GF_COQUE_NE_r1.png"],
		"le RAYON DES JEUX du grand magasin (3e étage) : " + MAGASIN + "ACCENT VIOLET ; quatre BORNES de jeu "
		"vidéo en décor alignées contre le mur du fond (écrans sombres, aucune image), une TABLE de jeu avec deux "
		"fauteuils au centre-gauche, quelques coussins de couleur ; ambiance de salle de jeux calme et propre."),
	("INT_CELADON_DEPT_5F_COQUE", ["celadon_dept_5f"], "celadopole_magasin_5e", _L_DEPT,
		[COQUE_BOUTIQUE, COQUE_CENTRE, ESCALIER_SO], 2, ["INT_CELADON_DEPT_GF_COQUE_NE_r1.png"],
		"le SALON du 5e étage du grand magasin : " + MAGASIN + "ACCENT BLEU ; deux paires de CANAPÉS au fond, "
		"deux grands ensembles de TABLES avec chaises dans le bas, un petit comptoir de salon de thé au milieu "
		"(tasses et théière sans texte) ; calme et aéré, un peu plus lumineux."),
	("INT_CELADON_DEPT_ROOF_COQUE", ["celadon_dept_roof"], "celadopole_magasin_toit", _L_TOIT,
		[COQUE_ARENE, PAVE], 1, [],
		"le TOIT-TERRASSE du grand magasin, à CIEL OUVERT (plus de plafond) : au lieu de murs, un PARAPET "
		"de pierre crème à garde-corps de métal fin (le « mur du fond » est le parapet vu de face, avec une "
		"légère vue sur les toits et la cime des arbres au-delà, en bleuté lointain, sur les 2 premières "
		"rangées seulement), DALLAGE clair de grandes dalles de pierre, trois DISTRIBUTEURS de boissons alignés au "
		"fond, un banc, quelques BACS plantés aux angles du bas, des guirlandes de fanions crème (sans texte) ; "
		"cohérent avec le toit-terrasse de la façade (parasols crème, plantes en bacs) ; aucun nuage dessiné "
		"dans la pièce."),
	("INT_CELADON_DEPT_ELEVATOR_COQUE", ["celadon_dept_elevator"], "celadopole_magasin_ascenseur", _L_ASCENSEUR_MAGASIN,
		[COQUE_CENTRE, COQUE_BOUTIQUE], 1, [],
		"la CABINE D'ASCENSEUR du grand magasin, petite et claire : parois de MÉTAL BROSSÉ CLAIR à moulures de "
		"laiton, un grand MIROIR dans les parois latérales, une MAIN COURANTE de laiton, sol de damier crème et "
		"sarcelle, plafond hors cadre ; le panneau d'étages au centre du mur du fond ; propre et lumineuse "
		"(lumière neutre, aucun halo)."),
	("INT_CELADON_MANSION_GF_COQUE", ["celadon_mansion_gf"], "celadopole_residence_rdc", _L_MANSION,
		[COQUE_MAISON, COQUE_MUSEE], 1, [],
		"le HALL de la Résidence Céladon : une demeure bourgeoise (comme la façade : pierre miel et bois "
		"sombre) ; sol de PARQUET en point de Hongrie miel foncé avec un grand TAPIS bordeaux à franges au "
		"centre, murs de pierre miel à BOISERIES de bois sombre et moulures, hautes fenêtres à petits carreaux "
		"dans le mur du fond, appliques de laiton (sans halo), un grand ESCALIER à gauche, un salon à droite "
		"(canapés de velours) et une table avec un vase de fleurs au centre-gauche ; chaleureux et cossu."),
	("INT_CELADON_MANSION_1F_COQUE", ["celadon_mansion_1f", "celadon_mansion_2f"], "celadopole_residence_1er", _L_MANSION,
		[COQUE_MAISON, COQUE_MUSEE], 2, ["INT_CELADON_MANSION_GF_COQUE_NE_r1.png"],
		"un PALIER de la Résidence Céladon (1er et 2e étages : le même palier) : même parquet, mêmes boiseries et "
		"mêmes appliques que le hall joint ; deux escaliers côte à côte dans le mur du fond (un qui monte, un "
		"qui descend), un BANC capitonné contre le mur du fond à droite de l'escalier, un grand tapis couloir "
		"bordeaux, des tableaux ENCADRÉS aux motifs abstraits (paysages flous, sans texte) aux murs ; une "
		"plante en pot dans chaque angle du bas."),
	("INT_CELADON_MANSION_3F_COQUE", ["celadon_mansion_3f"], "celadopole_residence_3e", _L_MANSION,
		[COQUE_MAISON, COQUE_MUSEE], 2, ["INT_CELADON_MANSION_GF_COQUE_NE_r1.png"],
		"le DERNIER PALIER de la Résidence Céladon (3e étage) : même parquet, mêmes boiseries et mêmes appliques "
		"que le hall joint ; un seul escalier (qui descend) dans le mur du fond ; au centre du mur du fond, sur "
		"la 9e colonne, la PORTE du bureau privé (bois sombre à deux battants, plaque de laiton vierge, FERMÉE) ; "
		"un banc capitonné à droite, des tableaux encadrés ; l'air plus solennel (un peu plus sombre, "
		"plus de bois)."),
	("INT_CELADON_MANSION_ROOF_COQUE", ["celadon_mansion_roof"], "celadopole_residence_toit", _L_TOIT,
		[COQUE_ARENE, DALLES_SO], 1, [],
		"le TOIT PRATICABLE de la Résidence, à CIEL OUVERT : une TERRASSE de dalles d'ARDOISE gris-bleu "
		"bordée d'un PARAPET de pierre miel (même pierre que la façade ; le « mur du fond » est le parapet "
		"vu de face, avec les toits de la ville au-delà en bleuté lointain), une cage d'escalier ouverte "
		"en haut à gauche, un banc, deux bacs de fleurs aux angles ; la zone de la maison du toit (colonnes 9 "
		"à 13, rangées 3 à 6) est un DALLAGE d'ardoise plat où le jeu pose la maison : n'y dessine ni maison "
		"ni porte."),
	("INT_CELADON_MANSION_ROOF_HOUSE_COQUE", ["celadon_mansion_roof_house"], "celadopole_residence_maison_toit", _L_MAISON,
		[COQUE_MAISON], 1, [],
		"l'INTÉRIEUR de la MAISON DU TOIT : une petite pièce chaleureuse et lumineuse, parquet de bois miel "
		"clair, murs crème à lambris de bois clair, deux petites fenêtres à petits carreaux dans le mur du fond "
		"(ciel pâle), des rideaux crème, un petit tapis rond ; au centre-haut, sur la 4e à la 6e colonne, une "
		"TABLE de bois (3 cases de large) avec une nappe et un petit vase ; deux plantes en pot ; c'est "
		"là qu'on offre Évoli : ne peins aucune Poké Ball ni aucun objet sur la table."),
	("INT_CELADON_RESTAURANT_COQUE", ["celadon_restaurant"], "celadopole_restaurant", _L_RESTAURANT,
		[COQUE_RESTAURANT, COQUE_MAISON], 1, [],
		"la SALLE du RESTAURANT de Céladopole : une salle accueillante (comme la façade : tuiles orange, "
		"crème), sol de CARREAUX de terre cuite damier crème et orange pâle, murs crème à lambris de bois "
		"clair, deux fenêtres à petits carreaux et un store rayé orange et crème dans le mur du fond (ciel "
		"pâle), un COMPTOIR de service à gauche avec une cuisine ouverte derrière, des TABLES NAPPÉES (blanc) "
		"avec chaises, une étagère de bouteilles à droite ; aucun menu, aucun jeton, aucun texte."),
	("INT_CELADON_CHIEF_HOUSE_COQUE", ["celadon_chief_house"], "celadopole_maison_chef", _L_MAISON,
		[COQUE_MAISON], 1, [],
		"l'INTÉRIEUR de la MAISON DU CHEF : un salon familial douillet, parquet de bois miel, murs crème à "
		"lambris de bois clair, deux fenêtres à petits carreaux dans le mur du fond (ciel pâle), un CANAPÉ "
		"de tissu bleu-gris à gauche, une grande bibliothèque à droite, une TABLE de salle à manger avec "
		"chaises au centre-droit, un tapis, des plantes ; même famille que la pièce jointe int_maison_argenta."),
	("INT_CELADON_HOTEL_COQUE", ["celadon_hotel"], "celadopole_hotel", _L_HOTEL,
		[COQUE_MUSEE, COQUE_CENTRE], 1, [],
		"le HALL de l'HÔTEL de Céladopole : une réception élégante (comme la façade : pierre crème, bleu "
		"ardoise, volets bleus), sol de DALLES crème avec un grand tapis bleu marine à liseré clair, murs crème à "
		"boiseries bleu-gris, hautes fenêtres à petits carreaux dans le mur du fond, un COMPTOIR de RÉCEPTION "
		"central à dessus de marbre avec des casiers de clés (sans numéro) derrière, un coin salon (un "
		"canapé bleu-gris de 2 cases) en bas à gauche, une étagère de livres en haut à gauche, un canapé en haut à droite, "
		"des plantes ; calme, aucune enseigne."),
	("INT_CELADON_GYM_COQUE", ["celadon_gym"], "celadopole_arene", _L_GYM,
		[COQUE_ARENE, SERRE], 1, [],
		"l'ARÈNE d'Erika, une SERRE élégante vue de l'intérieur (comme la façade et comme la pièce jointe int_arene_"
		"azuria, mais VÉGÉTALE) : sol de dalles de pierre claire et de chemins de gravier fin, murs de "
		"pierre claire à montants BLANCS, hautes VERRIÈRES vert d'eau dans le mur du fond (feuillage de "
		"palmiers derrière), des HAIES de buis taillées qui forment deux lacets et un vestibule, deux BASSINS "
		"de part et d'autre de la serre d'Erika au fond, un petit BASSIN décoratif au coin sud-ouest, des "
		"massifs fleuris ; lumière neutre (le jeu ajoute le vert filtré `greenhouse`) ; AUCUNE ombre portée, "
		"aucun personnage, aucun Pokémon."),
	("INT_ROCKET_HIDEOUT_ELEVATOR_COQUE", ["rocket_hideout_elevator"], "repaire_ascenseur", _L_ASCENSEUR_REPAIRE,
		[COQUE_CENTRE, COQUE_BOUTIQUE], 2, ["INT_CELADON_DEPT_ELEVATOR_COQUE_NE_r1.png"],
		"la CABINE D'ASCENSEUR du REPAIRE Rocket : la MÊME construction que la cabine du grand magasin jointe "
		"(même gabarit de parois, de main courante et de miroir) mais PLUS FROIDE et plus industrielle : parois "
		"d'ACIER gris-bleu brossé, rivets, main courante d'acier, sol de plaques d'acier à damier gris, bande de "
		"jaune sécurité au pied des parois, deux portes coulissantes d'acier dans le mur du fond (6 cases "
		"de large, 2 cases pour les portes) ; aucun miroir, aucun laiton, aucun décor chaleureux ; aucune lettre, "
		"aucun emblème."),
]

## Conditionnel : si la recoloration du 2e étage en ambre (`DECLINAISONS`) ne passe pas.
COQUES_COND = [
	("INT_CELADON_DEPT_4F_COQUE", ["celadon_dept_4f"], "celadopole_magasin_4e", _L_DEPT,
		[COQUE_BOUTIQUE, COQUE_CENTRE, ESCALIER_SO], 3, ["INT_CELADON_DEPT_2F_COQUE_NE_r1.png",
			"INT_CELADON_DEPT_GF_COQUE_NE_r1.png"],
		"le 4e ÉTAGE du grand magasin (Poupée Poké et Pierres d'évolution), EXACTEMENT la même salle que le 2e "
		"étage joint (mêmes comptoirs, mêmes rayonnages, même parquet, même construction) mais à ACCENT AMBRE "
		"(jaune ambré doré) au lieu du rose : tapis d'allée, plinthes, liserés, paillasson et tissus ambre ; "
		"des rayonnages de petits coffrets de pierres colorées (rouge, bleu, jaune, vert) sans texte."),
]

## Déclinaisons à la préparation : (carte, carte source, teinte de départ, teinte d'arrivée) en degrés. Le
## 2e étage rose (343°) donne le 4e ambre (38°) ; le 1er étage de la Résidence sert tel quel au 2e (copie,
## entrée `pieces` du manifeste). Si la coque conditionnelle du 4e étage existe dans $ART, elle prime.
DECLINAISONS = [("celadon_dept_4f", "celadon_dept_2f", 343, 38)]


# --- C et D. Modules du repaire et du Casino (modèle exact de la Tour, série 21) ---------------

_CELLULES = ("dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
	"512 × 512), un élément par cellule, centré, la base de chacun sur une même ligne horizontale à 40 "
	"px du bas de sa cellule")

## Textures de sol (opaques, raccordables, 384 px préparées) : (identifiant, asset, description, ancres,
## valeurs, vague). Pas de recadrage de vue : le repaire et le Casino n'ont aucune vue peinte.
SOLS = [
	("WORLD_GROUND_BETON_REPAIRE_01", "ground_beton_repaire_01",
		"texture du SOL DU REPAIRE ROCKET (couloirs et salles, tous étages) : grandes DALLES CARRÉES de BÉTON "
		"gris-bleu moyen (luminosité environ 42 à 52 %, assez sombre pour qu'une flèche JAUNE et un disque CLAIR "
		"peints dessus ressortent nettement), environ une dalle par case (1 case = 256 px sur cette texture), "
		"posées droites en quadrillage régulier, joints fins gris plus sombres, surface lisse et un peu "
		"usée, très fines nuances d'une dalle à l'autre et quelques micro-éclats ; propre, industriel et "
		"froid ; plus sombre, plus bleuté et plus régulier que les dalles beiges du souterrain jointes (à ne "
		"pas copier) ; aucune flèche, aucune ligne peinte, aucune tache d'huile marquante, aucune grille, "
		"aucun câble, aucun motif central.",
		[DALLES_SO, DALLES_TOUR], VALEURS_REPAIRE, 1),
	("WORLD_GROUND_MOQUETTE_CASINO_01", "ground_moquette_casino_01",
		"texture du SOL DU CASINO de Céladopole : une MOQUETTE épaisse BORDEAUX-PRUNE profond (luminosité "
		"environ 30 à 40 %) au motif tissé de LOSANGES réguliers très discrets (fins filets laiton doré, "
		"environ un losange par demi-case, 1 case = 256 px sur cette texture), grain de laine visible, "
		"tonal et riche ; raccordable ; plus sombre et plus violacée que la dalle de la Tour jointe (à ne pas "
		"copier) ; aucun jeton, aucune carte, aucun symbole, aucun chiffre, aucune tache, aucun élément "
		"remarquable qui trahirait la répétition.",
		[DALLES_TOUR, PAVE], VALEURS_CASINO, 1),
]

## Planches : (identifiant, description, ancres, valeurs, vague, jointes de la vague 1).
_MURS_ROLES = ("MÊMES rôles, MÊMES découpes et même manière de peindre que les modules joints relief_mur_tour_01 à "
	"_05 (face A, face B, couronnement, bord latéral, angle) : gabarit de la Tour ; ANGLES DROITS : chaque "
	"module est un rectangle net qui se raccorde bout à bout.")
V1_REPAIRE = ["WORLD_GROUND_BETON_REPAIRE_01_NE_r1.png", "WORLD_RELIEF_MUR_REPAIRE_PLANCHE_NE_r1.png"]
V1_CASINO = ["WORLD_GROUND_MOQUETTE_CASINO_01_NE_r1.png", "WORLD_RELIEF_MUR_CASINO_PLANCHE_NE_r1.png"]
PLANCHES = [
	("WORLD_RELIEF_MUR_REPAIRE_PLANCHE",
		f"PLANCHE de 5 MODULES DE MUR du REPAIRE Rocket (couloirs, salles, bureau, tous étages), {_CELLULES}, à "
		"une échelle COMMUNE : 1 case = 150 px, tous vus de dessus en trois quarts. Matière : PANNEAUX de BÉTON "
		"brut gris-bleu séparés par des joints fins, quelques rivets, couronnement de dalles de béton plus "
		"claires, plinthe d'ACIER sombre au pied ; murs épais, propres, froids et industriels ; " + _MURS_ROLES + "\n"
		"1 (ligne 1, à gauche) : FACE A, un mur vu de face (le sol est au SUD), 2 cases de large × 2 de "
		"haut : en haut le couronnement vu de dessus, puis la face de béton à panneaux, puis la plinthe d'acier ; "
		"bord bas droit et net. 2 (ligne 1, au milieu) : FACE B, même gabarit, avec une GRILLE D'AÉRATION "
		"rectangulaire à lamelles au milieu et un faisceau de câbles gris qui monte le long d'un joint ; 1 et 2 "
		"se raccordent bout à bout. 3 (ligne 1, à droite) : COURONNEMENT, le dessus d'un mur dont le sol est au "
		"NORD : une bande HORIZONTALE de dalles de béton claires vue de dessus, 2 cases × environ 0,4, sans face "
		"visible.\n"
		"4 (ligne 2, à gauche) : BORD LATÉRAL, le côté d'un mur dont le sol est à DROITE : une bande VERTICALE de "
		"couronnement vu de dessus avec une mince bande de face, environ 0,35 case de large × 2 de haut. "
		"5 (ligne 2, au milieu) : ANGLE, le coin d'un mur vu de dessus (un couronnement en équerre), environ "
		"0,35 × 0,6 case. (ligne 2, à droite) : cellule VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée.",
		[*MURS_TOUR, *MURS_SO[:1]], VALEURS_REPAIRE, 1, []),
	("WORLD_RELIEF_MUR_CASINO_PLANCHE",
		f"PLANCHE de 5 MODULES DE MUR du CASINO de Céladopole (intérieur), {_CELLULES}, à une échelle COMMUNE : 1 "
		"case = 150 px, tous vus de dessus en trois quarts. Matière : une TENTURE de velours PRUNE profond en "
		"panneaux verticaux séparés par des PILASTRES de bois sombre verni à chapiteaux de laiton, une MOULURE "
		"dorée fine, un couronnement de bois sombre à corniche, une PLINTHE de bois sombre ; élégant, riche et "
		"un peu théâtral ; " + _MURS_ROLES + "\n"
		"1 (ligne 1, à gauche) : FACE A, un mur vu de face (le sol est au SUD), 2 cases de large × 2 de haut : "
		"en haut le couronnement vu de dessus, puis la face de tenture prune à pilastres, puis la plinthe ; bord "
		"bas droit et net. 2 (ligne 1, au milieu) : FACE B, même gabarit, avec au milieu un grand CADRE "
		"doré vide (une glace sombre, sans reflet, sans motif) et deux appliques de laiton ÉTEINTES (sans halo) ; 1 "
		"et 2 se raccordent bout à bout. 3 (ligne 1, à droite) : COURONNEMENT, le dessus d'un mur dont le sol "
		"est au NORD : une bande HORIZONTALE de bois sombre verni vue de dessus, 2 cases × environ 0,4, sans "
		"face visible.\n"
		"4 (ligne 2, à gauche) : BORD LATÉRAL, le côté d'un mur dont le sol est à DROITE : une bande VERTICALE de "
		"couronnement vu de dessus avec une mince bande de face, environ 0,35 case de large × 2 de haut. "
		"5 (ligne 2, au milieu) : ANGLE, le coin d'un mur vu de dessus (un couronnement en équerre), environ "
		"0,35 × 0,6 case. (ligne 2, à droite) : cellule VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée. Aucun tube de "
		"néon sur les murs (le bandeau de néons est sur la façade, pas à l'intérieur).",
		[*MURS_TOUR], VALEURS_CASINO, 1, []),
	("INT_REPAIRE_PLANCHE",
		f"PLANCHE de 6 ÉLÉMENTS du REPAIRE Rocket (mobilier industriel), {_CELLULES}, à une échelle COMMUNE de 1 "
		"case = 120 px, tous vus de dessus en trois quarts ; même main que les meubles joints de la Tour "
		"(int_tombe_tour_01, int_comptoir_tour_01, ...) et que les murs et le sol joints du repaire (même matière, même gris-bleu froid).\n"
		"1 (ligne 1, à gauche) : CAISSE, une caisse de stockage industrielle en métal gris-vert à coins "
		"renforcés jaune sécurité et sangles, vue de face en trois quarts, 1 case de large (≈ 120 px), environ "
		"1,2 case de haut ; sans inscription ; elle se juxtapose en blocs de 2 × 2. 2 (ligne 1, au milieu) : "
		"CONDUITE, un tronçon de gros tuyau d'ACIER gris posé sur le sol et qui court du NORD au SUD (on voit son "
		"dessus arrondi et sa face avant), 1 case de large × EXACTEMENT 1 case de long, une bride (anneau) "
		"à chaque bout ; les deux extrémités (haut et bas de l'élément) sont coupées net, de même section, "
		"pour se raccorder exactement bout à bout avec lui-même. 3 (ligne 1, à droite) : CONSOLE, un pupitre "
		"de contrôle en acier gris-bleu avec un écran SOMBRE (aucune image, aucun chiffre, aucune lueur) et "
		"quelques rangées de boutons colorés, 1 case de large, environ 1,1 case de haut ; il se juxtapose "
		"côte à côte en rangées.\n"
		"4 (ligne 2, à gauche) : BUREAU DE GIOVANNI, un grand bureau de direction, 4 cases de large (≈ 480 px) "
		"× 2 cases de profondeur, plateau de bois NOIR laqué avec un sous-main de cuir, une lampe, un "
		"téléphone, un classeur fermé, panneau avant uni à filets dorés (SANS emblème, SANS lettre), vu de face "
		"en trois quarts ; sobre, imposant, froid. 5 (ligne 2, au milieu) : ESCALIER QUI MONTE, une cage "
		"d'escalier de béton et d'acier : des marches de béton à nez de métal qui MONTENT vers le haut de "
		"l'image jusque dans l'ombre douce de l'étage au-dessus (pas de noir total), une rampe d'acier de "
		"chaque côté, 1 case de large, environ 1,3 case de haut. 6 (ligne 2, à droite) : ESCALIER QUI DESCEND, "
		"une cage d'escalier de béton qui s'ouvre dans le sol : des marches de béton qui DESCENDENT vers le bas "
		"de l'image et s'enfoncent dans l'ombre douce (pas de noir total), une rampe d'acier de chaque côté, "
		"1 case de large, environ 1,3 case de haut ; même gabarit que l'escalier qui monte.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune dalle, aucune ombre portée.",
		[f"{_W}interiors/int_tombe_tour_01.png", f"{_W}interiors/int_comptoir_tour_01.png",
			f"{_W}interiors/int_armoire_electrique_01.png", f"{_W}interiors/int_bureau_pc_01.png"],
		VALEURS_REPAIRE, 2, V1_REPAIRE),
	("INT_DALLES_REPAIRE_PLANCHE",
		f"PLANCHE de 4 ÉLÉMENTS du REPAIRE Rocket (marquages au sol et portes), {_CELLULES}, à une échelle COMMUNE "
		"de 1 case = 150 px ; même sol de béton gris-bleu que la texture jointe, mêmes murs d'acier et de "
		"béton que la planche de murs jointe.\n"
		"1 (ligne 1, à gauche) : FLÈCHE PEINTE AU SOL, une grande flèche de jaune sécurité un peu écaillée "
		"pointant vers la DROITE, vue STRICTEMENT DE DESSUS (à plat, sans perspective, aucune épaisseur), "
		"symétrique de haut en bas : pointe triangulaire pleine à droite et fût court à gauche ; elle occupe "
		"un carré d'EXACTEMENT 1 case (≈ 130 px de large et de haut), bien centrée dans sa cellule ; fond "
		"transparent (SEUL le marquage est peint : aucune dalle, aucun fond de béton). 2 (ligne 1, au "
		"milieu) : DISQUE D'ARRÊT, un disque CLAIR (blanc cassé légèrement écaillé) peint au sol, vu "
		"STRICTEMENT DE DESSUS, avec un mince anneau gris-bleu à l'extérieur, diamètre ≈ 130 px (1 case), "
		"AUCUNE marque ni aucun symbole à l'intérieur (un disque plein et uni : ni cercle partagé en deux, ni "
		"bouton central) ; fond transparent. 3 (ligne 1, à droite) : PORTE D'ASCENSEUR, deux battants "
		"coulissants d'acier brossé gris clair, fermés, dans un cadre d'acier plus sombre à rivets, 2 cases "
		"de large (≈ 300 px) × environ 1,2 case de haut, vue de face (comme une face de mur), un petit "
		"voyant ÉTEINT au-dessus, SANS chiffre ni flèche.\n"
		"4 (ligne 2, à gauche) : PORTE DU BUREAU DE GIOVANNI, une lourde porte à deux battants d'acier "
		"sombre à filets dorés fins dans un cadre de béton, fermée, vue de face comme une face de mur, EXACTEMENT "
		"2 cases de large (≈ 300 px) × 1 case de haut (≈ 150 px) : un RECTANGLE de rapport 2 : 1 qui se "
		"raccorde aux murs du repaire ; sobre, imposante ; aucun emblème, aucune lettre, aucune poignée "
		"dorée voyante. (ligne 2, au milieu et à droite) : cellules VIDES.\n"
		"Fond avec une vraie transparence (canal alpha), aucune ombre portée.",
		[*MURS_TOUR[:2]], VALEURS_REPAIRE, 2, V1_REPAIRE),
	("INT_CASINO_PLANCHE",
		f"PLANCHE de 6 ÉLÉMENTS du CASINO de Céladopole (fermé pour inventaire : tout est du DÉCOR), {_CELLULES}, à "
		"une échelle COMMUNE de 1 case = 120 px, tous vus de dessus en trois quarts ; même main que la planche "
		"de meubles joints de la Tour (int_tombe_tour_01, int_comptoir_tour_01, int_banc_tour_01) et même ton prune et laiton que la moquette et les murs joints du "
		"Casino.\n"
		"1 (ligne 1, à gauche) : MACHINE A, une machine à sous éteinte vue de face en trois quarts : caisson "
		"de bois verni prune et laiton, une fenêtre vitrée SOMBRE au milieu (SANS rouleaux, SANS symbole, SANS "
		"chiffre), un levier de laiton sur le côté droit, un petit plateau en bas ; 1 case de large (≈ 120 px), "
		"environ 1,3 case de haut ; elle s'empile en colonne avec la même machine (le haut de l'une touche le "
		"bas de la suivante). 2 (ligne 1, au milieu) : MACHINE B, même gabarit et même taille que la machine A "
		"mais caisson BLEU NUIT et laiton, le levier à gauche ; elle alterne avec la machine A dans une "
		"colonne. 3 (ligne 1, à droite) : TABOURET, un tabouret rond à assise capitonnée bordeaux et pied de "
		"laiton, 1 case de large, environ 0,8 case de haut.\n"
		"4 (ligne 2, à gauche) : COMPTOIR, un élément de comptoir d'accueil de bois sombre verni à dessus de "
		"marbre crème, vu de face, 1 case de large × 1 de profondeur (≈ 120 px de large, environ 1,1 case de "
		"haut), SANS caisse ni objet dessus, qui se juxtapose BOUT À BOUT (bords gauche et droit identiques) "
		"en comptoir de 8 cases. 5 (ligne 2, au milieu) : AFFICHE, une affiche encadrée au MUR : un cadre doré "
		"fin contenant un motif ABSTRAIT (une grande étoile dorée à huit branches sur fond prune, sans "
		"aucun texte, aucun personnage, aucune lettre), 1 case de large × 1,4 de haut, vue de face. "
		"6 (ligne 2, à droite) : PAN DE MUR COULISSANT, un panneau de mur de la MÊME facture que la face A de "
		"la planche de murs jointe (tenture prune, pilastres de bois sombre, moulure dorée, plinthe), "
		"EXACTEMENT 1 case de large × 1 case de haut (≈ 120 × 120 px), un fin joint de chaque côté qui "
		"le fait paraître mobile ; un carré net.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune dalle, aucune ombre portée.",
		[f"{_W}interiors/int_tombe_tour_01.png", f"{_W}interiors/int_comptoir_tour_01.png",
			f"{_W}interiors/int_banc_tour_01.png", COMPTOIR], VALEURS_CASINO, 2, V1_CASINO),
]


# --- E. Icônes du Sac -----------------------------------------------------------------------

_I = ICONES
ICONES_STYLE = (" dans le style EXACT des icônes jointes (même rendu peint, même contour fin et coloré, même angle "
	"de trois quarts, même lumière, même finesse, même taille d'environ 240 px)")
_DISQUE = ("un DISQUE plat et lustré vu de trois quarts, anneau argenté et petit trou au centre, tranche épaisse bleu "
	"marine, EXACTEMENT comme la CS05 jointe (hm05)")
## Planches (4 colonnes de 384 px, gabarit de `preparer_menu.py`) : (identifiant, [(id d'objet, description)],
## ancres, vague, jointes de la vague 1). Identifiants vérifiés dans data/items/*.json (2026-10-21).
ICONES_PLANCHES = [
	("UI_OBJETS_22BIS_PLANCHE_1", [
		("great_ball", "la SUPER BALL : une sphère comme la Poké Ball jointe (même modèle, même taille, même bande "
			"médiane et même bouton central), mais le dessus est BLEU franc avec deux petites bandes ROUGES "
			"sur les côtés, le dessous blanc crème"),
		("revive", "le RAPPEL : un CRISTAL taillé en losange allongé, jaune citron translucide à facettes nettes "
			"et reflets blancs crème, posé sur sa pointe basse, brillant mais net"),
		("poke_doll", "la POUPÉE POKÉ : une petite POUPÉE de tissu ronde et potelée, corps crème, bonnet et "
			"nœud ROUGES, deux gros yeux boutons noirs, petits bras écartés, assise ; mignonne, générique (ce "
			"n'est AUCUN Pokémon existant)"),
		("silph_scope", "le SCOPE SYLPHE : de grosses LUNETTES de visée de métal gris-bleu à large monture "
			"épaisse et à UNE grosse LENTILLE ronde rose-rouge translucide (un viseur technique), une "
			"sangle noire courte de chaque côté ; objet unique et un peu mystérieux"),
	], [f"{_I}poke_ball.webp", f"{_I}potion.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_2", [
		("x_attack", "l'ATTAQUE + : une FIOLE d'apothicaire (corps de verre rond et trapu, col court, bouchon de "
			"liège) remplie d'un liquide ROUGE franc, avec une petite PLAQUE blanche collée sur le corps portant "
			"une petite ÉPÉE stylisée rouge (symbole, aucun texte)"),
		("x_defend", "la DÉFENSE + : la MÊME fiole (même forme, même taille, même bouchon) au liquide JAUNE doré, "
			"plaque blanche portant un petit BOUCLIER stylisé jaune"),
		("x_speed", "la VITESSE + : la MÊME fiole au liquide BLEU vif, plaque blanche portant une petite AILE "
			"stylisée bleue"),
		("x_special", "le SPÉCIAL + : la MÊME fiole au liquide VIOLET, plaque blanche portant une petite ÉTOILE à "
			"cinq branches violette"),
	], [f"{_I}potion.webp", f"{_I}super_potion.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_3", [
		("x_accuracy", "la PRÉCISION + : la MÊME fiole d'apothicaire que les quatre « + » (corps de verre rond et "
			"trapu, col court, bouchon de liège), au liquide VERT franc, plaque blanche portant une petite "
			"FLÈCHE droite stylisée verte"),
		("dire_hit", "le MUSCLE + : la MÊME fiole au liquide ORANGE foncé, plaque blanche portant un petit POING "
			"fermé stylisé orange"),
		("burn_heal", "l'ANTI-BRÛLE : le MÊME flacon vaporisateur que l'Antidote jointe (même forme, même "
			"taille, même gâchette) mais au corps ROUGE-ORANGÉ, gâchette et bouchon blancs"),
		("ice_heal", "l'ANTIGEL : le même flacon vaporisateur, au corps TURQUOISE glacé pâle, gâchette et bouchon "
			"blancs"),
	], [f"{_I}antidote.webp", f"{_I}super_potion.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_4", [
		("fire_stone", "la PIERRE FEU : une pierre OVALE polie et lustrée à facettes douces, rouge-orangé chaud "
			"translucide, avec une petite flamme claire gravée en relief au centre"),
		("water_stone", "la PIERRE EAU : la même pierre ovale (même forme et même taille), BLEU limpide "
			"translucide, avec une petite goutte claire gravée en relief"),
		("thunder_stone", "la PIERRE FOUDRE : la même pierre ovale, JAUNE vif translucide, avec un petit éclair "
			"clair gravé en relief"),
		("leaf_stone", "la PIERRE PLANTE : la même pierre ovale, VERT feuille translucide veinée, avec une petite "
			"feuille claire gravée en relief"),
	], [f"{_I}moon_stone.webp", f"{_I}nugget.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_5", [
		("fresh_water", "l'EAU FRAÎCHE : une bouteille d'eau en plastique transparent bleuté, bouchon blanc, "
			"étiquette bleu clair UNIE à vague blanche (aucun texte), quelques gouttes de condensation"),
		("soda_pop", "le SODA COOL : une canette cylindrique ROUGE vif à bande médiane blanche ondulée, "
			"languette d'aluminium, aucun texte"),
		("lemonade", "la LIMONADE : une bouteille de verre jaune clair trouble, bouchon à capsule, une "
			"rondelle de CITRON coincée sur le goulot et une paille rayée blanche et jaune ; aucun texte"),
		("lift_key", "la CLÉ ASCENSEUR : une CLÉ de métal argenté à large tête RECTANGULAIRE bordée de laiton et à "
			"panneton simple, avec un petit anneau de laiton ; aucun texte, aucun emblème, aucune lettre R"),
	], [f"{_I}potion.webp", f"{_I}escape_rope.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_6", [
		("hm01", "la CS01 (COUPE) : " + _DISQUE + " (le dessus JAUNE VIF des CS), et au centre du dessus une petite "
			"LAME de faucille blanche stylisée"),
		("tm01", "la CT01 (ULTIMAPOING) : " + _DISQUE + " mais le dessus est CRÈME clair (type Normal), "
			"et au centre un petit POING fermé blanc stylisé"),
		("tm11", "la CT11 (BULLES D'O) : " + _DISQUE + " mais le dessus est BLEU franc (type Eau), "
			"et au centre trois petites BULLES blanches"),
	], [f"{_I}hm05.webp", f"{_I}rare_candy.webp"], 1, []),
	("UI_OBJETS_22BIS_PLANCHE_7", [
		("tm13", "la CT13 (LASER GLACE) : " + _DISQUE + " mais le dessus est BLEU GLACE clair (type Glace), "
			"et au centre un petit FLOCON à six branches blanc"),
		("tm19", "la CT19 (FRAPPE ATLAS) : " + _DISQUE + " mais le dessus est ROUGE BRIQUE (type Combat), "
			"et au centre un petit ARC de lancer blanc (une flèche courbe qui monte puis retombe)"),
		("tm21", "la CT21 (MÉGA-SANGSUE) : " + _DISQUE + " mais le dessus est VERT feuille (type Plante), "
			"et au centre une petite FEUILLE blanche avec une goutte"),
	], [f"{_I}hm05.webp", f"{_I}rare_candy.webp"], 2, ["UI_OBJETS_22BIS_PLANCHE_6_r1.png"]),
	("UI_OBJETS_22BIS_PLANCHE_8", [
		("tm24", "la CT24 (TONNERRE) : " + _DISQUE + " mais le dessus est JAUNE DORÉ ambré (type Électrik, plus "
			"orangé que le jaune vif des CS), et au centre un petit ÉCLAIR blanc"),
		("tm28", "la CT28 (TUNNEL) : " + _DISQUE + " mais le dessus est BRUN terre (type Sol), "
			"et au centre une petite PELLE blanche"),
		("tm34", "la CT34 (PATIENCE) : " + _DISQUE + " mais le dessus est GRIS-BEIGE clair (type Normal, plus "
			"gris que la CT01), et au centre un petit SABLIER blanc"),
	], [f"{_I}hm05.webp", f"{_I}rare_candy.webp"], 2, ["UI_OBJETS_22BIS_PLANCHE_6_r1.png"]),
]
ICONES_IDS = [objet for planche in ICONES_PLANCHES for objet, _texte in planche[1]]
ICONES_DOSSIER = RACINE / "assets" / "ui" / "items"


# --- F. Évoli compagnon -----------------------------------------------------------------------

## Hauteur en jeu par défaut 56 px (règle 4 ; Rattata 56, Miaouss 64), comme `serie22.EVOLI_HAUTEUR`.
EVOLI_HAUTEUR = 56
EVOLI_SUJET = ("petit mammifère quadrupède brun-roux chaud, fidèle à son design officiel : grande collerette de "
	"fourrure crème duveteuse autour du cou, très grandes oreilles pointues brunes dressées, grands yeux bruns, "
	"petit museau, queue touffue et large, brune avec le bout crème, relevée en panache. Allure curieuse et "
	"affectueuse.")


# --- Prompts -----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return ", ".join(Path(f).stem for f in fichiers)


def _serie(jointes: list[str]) -> str:
	"""Ligne des images de la série déjà générées et jointes (raccord exact avec ce qui est déjà validé)."""
	if not jointes:
		return ""
	return (f"\nImages de la série déjà générées et jointes : {_noms(jointes)} = MÊME matière, mêmes couleurs, même "
		"main, même échelle : l'élément doit s'y raccorder exactement.")


def _taille(relatif: str, defaut: tuple[int, int] | None = None) -> tuple[int, int]:
	chemin = RACINE / relatif
	if chemin.exists():
		with Image.open(chemin) as image:
			return image.size
	if defaut is None:
		raise SystemExit(f"provisoire absent : {relatif}")
	return defaut


def _boite(gen: tuple[int, int], final: tuple[int, int]) -> tuple[int, int]:
	"""Taille de l'élément dans l'image générée : le rapport de l'image finale, dans la marge de la page."""
	maxi = (gen[0] - 136, gen[1] - 84) if gen[0] > gen[1] else (gen[0] - 84, gen[1] - 84)
	echelle = min(maxi[0] / final[0], maxi[1] / final[1])
	return round(final[0] * echelle), round(final[1] * echelle)


def _prompt_facade(ident: str, asset: str, ref: str, refs_sup: list[str], largeur: int, profondeur: int,
		porte, description: str, ancres: list[str], provisoire: str) -> str:
	final = TAILLES[asset]
	gen = _format_generation(*final) if final[0] / final[1] >= 1.3 else (1024, 1024)
	ew, eh = _boite(gen, final)
	refs = ", ".join([ref, *refs_sup])
	jointes = (f"Images jointes : {refs} = forme, matériaux et couleurs, extraits de la vue d'ensemble validée de "
		"la ville (minuscules, en lumière dorée de fin de journée avec des vitres allumées : n'en copie ni le "
		"rendu, ni la lumière dorée, ni les vitres allumées, ni les personnages) ; "
		f"{Path(provisoire).stem} = le PROVISOIRE actuel (un dessin schématique en aplats) : il ne donne QUE la "
		"géométrie (emprise, proportions, position de la porte) ; n'en copie NI le rendu en aplats, NI les "
		"couleurs plates, NI les mots écrits dessus ; "
		f"{_noms(ancres)} = ancres de style (rendu peint, contour coloré, finesse, même angle de vue, même "
		"lumière neutre).")
	rapport = final[0] / final[1]
	ligne_porte = (_porte(largeur, *porte) if porte else "AUCUNE PORTE : aucune ouverture, aucun seuil, aucune marche.")
	corps = (f"ASSET : {description}\n{ligne_porte}\nFormat : PNG {gen[0]} × {gen[1]}, l'élément occupe environ "
		f"{ew} × {eh} px (rapport largeur / hauteur {rapport:.2f} : 1, à RESPECTER : l'image est ramenée telle "
		f"quelle à {final[0]} × {final[1]} px, soit 1 case = 96 px), centré, TOUT le bâtiment visible, "
		f"rien ne dépasse du cadre. Échelle : {largeur} cases de large et {final[1] / 96:.2f} de haut (profondeur "
		f"de l'emprise : {profondeur} cases + le rebord du toit) ; un adulte mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n{ADN}\n"
		f"{VALEURS_VILLE}\n\n{corps}\n")


def _prompt_fontaine(provisoire: str) -> str:
	ident, asset, ref, largeur, _profondeur, description, ancres = FONTAINE
	final = TAILLES[asset]
	ew, eh = _boite((1024, 1024), final)
	jointes = (f"Images jointes : {ref} = forme et matériaux, extraits de la vue d'ensemble validée de la ville "
		"(minuscule, en lumière dorée : n'en copie ni le rendu, ni la lumière, ni le personnage) ; "
		f"{Path(provisoire).stem} = le PROVISOIRE actuel (dessin schématique) : seulement l'emprise et les "
		f"proportions ; {_noms(ancres)} = ancre de style pour l'eau (rendu peint, contour coloré, finesse).")
	corps = (f"ASSET : {description}\nFormat : PNG 1024 × 1024, l'élément occupe environ {ew} × {eh} px (rapport "
		f"largeur / hauteur {final[0] / final[1]:.2f} : 1, à RESPECTER : l'image est ramenée telle quelle à "
		f"{final[0]} × {final[1]} px), centré. Échelle : {largeur} cases de large ; un adulte mesure 1,33 "
		f"case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n{ADN}\n"
		f"{VALEURS_VILLE}\n\n{corps}\n")


def _prompt_coque(ident: str, cartes: list[str], grille: str, legende: dict, ancres: list[str],
		texte: str, jointes_v1: list[str], provisoire: str) -> str:
	final = _taille(provisoire)
	gen = _format_generation(*final)
	plan = _plan_texte(grille, legende, gen)
	etirement = (f"{final[0]} × {final[1]} px : 1 case = 96 px" if final[0] % 96 == 0 and final[1] % 96 == 0
		else f"{final[0]} × {final[1]} px")
	declinaison = ""
	if len(cartes) > 1:
		declinaison = (f" Cette même image sert à {len(cartes)} cartes ({', '.join(cartes)}) : aucun détail propre à "
			"un seul étage (ni numéro, ni inscription).")
	return (f"{ident} — NOUVELLE image : une pièce intérieure de jeu COMPLÈTE (murs, sol, fenêtres ET mobilier "
		"cuit dans l'image).\n"
		f"Images jointes : {_noms(ancres)} = ancres de style des intérieurs (rendu peint, contour coloré, finesse, "
		"angle de vue, géométrie d'une enveloppe, lumière neutre) : respecte-les exactement ; ces pièces sont "
		f"VIDES, toi tu ajoutes le mobilier ; {Path(provisoire).stem} = le PLAN de la pièce (le provisoire actuel, "
		"dessiné en aplats d'après la grille) : il ne donne QUE la position et la taille des murs, des ouvertures et "
		"des meubles ; n'en copie NI le rendu en aplats, NI les couleurs plates, NI les mots écrits dessus, "
		f"NI le dessin simpliste.{_serie(jointes_v1)}\n\n"
		f"{ADN}\n{VALEURS_INTERIEUR}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en trois "
		"quarts, image opaque qui remplit tout le cadre.\n"
		f"Format : PNG {gen[0]} × {gen[1]}, opaque, qui remplit tout le cadre ; la pièce est ramenée telle quelle à "
		f"{etirement}.{declinaison}\n"
		f"{_BASE_COQUE}\n"
		f"Géométrie (respecte-la exactement, c'est un plan de jeu calculé case par case) :\n{plan}\n"
		f"Pièce : {texte}\n"
		"Interdit : meuble ou objet hors de la liste ci-dessus, personnages, Pokémon (ni Pikachu), porte fermée "
		"là où le plan place une sortie, flaques de lumière peintes au sol, ombres portées au sol, texte, lettres, "
		"chiffres, logo, la lettre R ou tout emblème de la Team Rocket, emblème rond de type balle, perspective "
		"avec point de fuite, vue isométrique.\n")


def _prompt_texture(ident: str, description: str, ancres: list[str], valeurs: str) -> str:
	jointes = (f"Images jointes : {_noms(ancres)} = ancres de style (rendu peint, finesse, grain, lumière neutre : "
		"respecte la finesse, pas la couleur).")
	return (f"{ident} — NOUVELLE image : une texture de sol de jeu, pas une scène.\n{jointes}\n\n{ADN}\n{valeurs}\n\n"
		f"ASSET : {description}\n{TEXTURE_FIN}\n{INTERDITS}\n")


def _prompt_planche(ident: str, description: str, ancres: list[str], valeurs: str, v1: list[str]) -> str:
	return (f"{ident} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages jointes : "
		f"{_noms(ancres)} = ancres de style (rendu peint, contour coloré, finesse, angle de vue, lumière "
		f"neutre) : respecte-les exactement.{_serie(v1)}\n\n"
		f"{ADN}\n{valeurs}\n\n"
		"EXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une même planche, chacun "
		f"entier dans sa cellule, sans cadre ni séparation.\n{description}\n{INTERDITS}\n")


def _prompt_icones(ident: str, objets: list[tuple[str, str]], ancres: list[str], v1: list[str]) -> str:
	n = len(objets)
	colonnes = ("la PREMIÈRE colonne (x de 0 à 384)" if n == 1 else
		f"chacune des {n} PREMIÈRES colonnes (de gauche à droite)")
	vides = "" if n == 4 else f" ; les {4 - n} dernière{'s' if 4 - n > 1 else ''} colonne{'s' if 4 - n > 1 else ''} restent VIDES (transparentes)"
	lignes = "\n".join(f"{i + 1} (colonne {i + 1}) : {texte}." for i, (_, texte) in enumerate(objets))
	return (f"{ident} — NOUVELLE image : une planche d'icônes d'objets peintes pour le Sac, pas une scène.\n"
		f"Images jointes : {_noms(ancres)} = icônes existantes du jeu, ANCRES de style{ICONES_STYLE}.{_serie(v1)}\n\n"
		f"PLANCHE de {n} icône{'s' if n > 1 else ''} d'objets peinte{'s' if n > 1 else ''} pour le Sac, dans une image "
		f"1536 × 1024 divisée en quatre colonnes invisibles de 384 px : une icône CENTRÉE dans {colonnes}, de "
		f"260 px de large au plus et 260 px de haut au plus, avec au moins 60 px de marge vide de chaque côté{vides}.\n"
		f"{lignes}\n"
		"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec seulement "
		"son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre). Interdit : texte, "
		"lettres, chiffres, logo, la lettre R, personnage.\n")


def _prompt_evoli() -> str:
	"""Planche de marche d'Évoli au gabarit de `serie14_pokemon.prompt`, SANS image jointe (le r1 de la série
	22, avec image, a été refusé par Codex) : le style et la taille sont décrits par écrit."""
	return f"""POKE_EVOLI — planche d'animation d'un Pokémon du monde (compagnon du héros).
Style : Pokémon peint simplifié pour un RPG Pokémon moderne « HD-2D peint » : même finesse que les personnages du jeu, silhouette chibi trapue et rassurante, formes simples et arrondies, contour fin et doux d'une teinte plus sombre que la couleur locale (aucun trait noir), trois valeurs nettes par matériau, légère granularité de pinceau. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

POKÉMON (identique dans toutes les images) : {EVOLI_SUJET}

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose du Pokémon, entier, centré horizontalement, les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même taille dans toutes les cellules (environ 170 px de haut). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran).
- Colonnes : trotte à quatre pattes en 4 images (1 = pattes rassemblées en passage, 2 = foulée avec la patte avant gauche en avant, 3 = pattes rassemblées en passage, 4 = foulée avec la patte avant droite en avant), petits pas légers, oreilles et queue qui rebondissent.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus du Pokémon). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Taille : Évoli est de la taille d'un petit chat (un humain adulte mesurerait environ trois fois sa hauteur dans le même jeu).
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.
Interdit : texte, lettres, chiffres, logo, personnage, autre Pokémon, Poké Ball.
"""


def _prompt_evoli_attente() -> str:
	"""Attente 4 × 1 d'Évoli (modèle de tools/art/attente/prompts/RATTATA_ATTENTE.txt), calée sur la marche."""
	marche = "POKE_EVOLI_NE_r1"
	return (f"EVOLI_ATTENTE — POSE D'ATTENTE (immobile, au repos) du même Pokémon que la planche jointe {marche} (sa "
		f"planche de marche 4 × 4) : Évoli, {EVOLI_SUJET} Même main peinte, mêmes couleurs, mêmes proportions, "
		"même taille. Ce n'est PAS une marche : il ne bouge pas, il attend.\n"
		"Style : illustration 2D peinte numériquement, contour fin et doux d'une teinte sombre et colorée, aucun "
		"trait noir, trois valeurs nettes par matériau, légère granularité de pinceau, lumière neutre de milieu de "
		"journée, diffuse et blanche, venant légèrement du haut à gauche, aucune teinte dorée. Formes simplifiées et "
		f"lisibles pour rester net une fois réduit à environ {EVOLI_HAUTEUR} px de haut. Ni pixel art, ni 3D.\n\n"
		"PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier "
		"dessiné). UNE seule ligne de 4 poses, de gauche à droite, chaque pose dans une colonne invisible de 384 px "
		"de large, bien séparées par du vide, le Pokémon entier dans chaque colonne, à la même taille dans les 4 "
		f"poses (même taille que dans la planche jointe), les pattes des 4 poses sur une même ligne horizontale. "
		"Pas de sol, pas d'ombre, pas de texte, pas de numéros, pas de cadres.\n"
		f"- Pose 1 : tourné vers le BAS (vu de face), comme la ligne 1 de {marche}.\n"
		f"- Pose 2 : tourné vers la GAUCHE (de profil), comme la ligne 2 de {marche}.\n"
		f"- Pose 3 : tourné vers la DROITE (de profil), comme la ligne 3 de {marche}.\n"
		f"- Pose 4 : tourné vers le HAUT (vu de dos), comme la ligne 4 de {marche}.\n"
		"POSE D'ATTENTE dans les 4 vues : à quatre pattes, immobile et calme, les QUATRE pattes posées au sol sous "
		"le corps (pattes avant côte à côte, pattes arrière côte à côte), aucune patte levée ni tendue (pas une "
		"foulée) ; de profil, les pattes avant se superposent et les pattes arrière se superposent, le corps "
		"compact, la queue au repos, les grandes oreilles dressées. Mêmes proportions que les lignes de profil "
		f"de {marche} (ni plus haut, ni plus gros).\nInterdit : texte, lettres, chiffres, logo, personnage, autre "
		"Pokémon.\n")


def _images() -> list[dict]:
	"""Toutes les images de la série : nom (sans .png), fichier de prompt, texte, jointes (noms dans $ART, ou
	chemins relatifs à la racine quand ils contiennent « / »), vague, conditionnel, groupe."""
	images: list[dict] = []

	def ajouter(nom, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": PROMPTS / f"{nom}.txt", "texte": texte, "jointes": jointes,
			"vague": vague, "conditionnel": conditionnel, "groupe": groupe or nom.rsplit("_r", 1)[0]})

	# A. Façades et fontaine (vague 1)
	for ident, asset, ref, refs_sup, largeur, profondeur, porte, description, ancres, vague in FACADES:
		prov = f"{_W}buildings/{asset}.png"
		ajouter(f"{ident}_NE_r1", _prompt_facade(ident, asset, ref, refs_sup, largeur, profondeur, porte,
			description, ancres, prov), [f"{r}.png" for r in (ref, *refs_sup)] + [prov] + ancres, vague,
			groupe=ident)
	prov = f"{_W}props/{FONTAINE[1]}.png"
	ajouter(f"{FONTAINE[0]}_NE_r1", _prompt_fontaine(prov), [f"{FONTAINE[2]}.png", prov, *FONTAINE[6]], 1,
		groupe=FONTAINE[0])
	# B. Coques (vagues 1 et 2) ; conditionnel en vague 3
	for conditionnel, table in ((False, COQUES), (True, COQUES_COND)):
		for ident, cartes, grille, legende, ancres, vague, jointes_v1, texte in table:
			prov = f"{_PH}ph_{cartes[0]}.png"
			ajouter(f"{ident}_NE_r1", _prompt_coque(ident, cartes, grille, legende, ancres, texte, jointes_v1,
				prov), [prov] + ancres + jointes_v1, vague, conditionnel, groupe=ident)
	# C et D. Sols et planches de modules
	for ident, _asset_id, description, ancres, valeurs, vague in SOLS:
		ajouter(f"{ident}_NE_r1", _prompt_texture(ident, description, ancres, valeurs), ancres, vague,
			groupe=ident)
	for ident, description, ancres, valeurs, vague, v1 in PLANCHES:
		jointes = v1 + ancres  # le sol et les murs de la vague 1 donnent la matière (raccord exact)
		ajouter(f"{ident}_NE_r1", _prompt_planche(ident, description, ancres, valeurs, v1), jointes, vague,
			groupe=ident)
	# E. Icônes
	for ident, objets, ancres, vague, v1 in ICONES_PLANCHES:
		ajouter(f"{ident}_r1", _prompt_icones(ident, objets, ancres, v1), ancres + v1, vague, groupe=ident)
	# F. Évoli : marche (vague 1, SANS image jointe) puis attente (vague 2, joint la marche)
	ajouter("POKE_EVOLI_NE_r1", _prompt_evoli(), [], 1, groupe="POKE_EVOLI")
	ajouter("EVOLI_ATTENTE_r1", _prompt_evoli_attente(), ["POKE_EVOLI_NE_r1.png"], 2, groupe="EVOLI_ATTENTE")
	# Corrections (relecture de Kevin) : texte ajouté et révision précédente jointe.
	for (ident, rev), complement in CORRECTIONS.items():
		base = next(i for i in images if i["groupe"] == ident and i["nom"].endswith("_r1"))
		nom = base["nom"][:-2] + f"r{rev}"
		precedent = base["nom"][:-2] + f"r{rev - 1}.png"
		ajouter(nom, f"{base['texte']}\nCORRECTION (révision {rev}) : {complement}\nL'image jointe {precedent[:-4]} est la "
			"révision précédente : garde ce qui va, corrige seulement ce qui est dit ci-dessus.\n",
			base["jointes"] + [precedent], 3, True, groupe=f"{ident}_r{rev}")
	return images


## Corrections (après la relecture de Kevin) : (identifiant sans _NE_rN, révision) → texte ajouté au prompt
## d'origine. Vide tant que rien n'a été relu.
CORRECTIONS: dict[tuple[str, int], str] = {}


def ecrire_prompts() -> None:
	changes = 0
	images = _images()
	for image in images:
		fichier: Path = image["fichier"]
		fichier.parent.mkdir(parents=True, exist_ok=True)
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	manquantes = sorted({j for i in images for j in i["jointes"] if "/" in j and not (RACINE / j).exists()})
	print(f"{len(images)} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}")
	if manquantes:
		print("ANCRES ABSENTES du dépôt : " + ", ".join(manquantes))


# --- Références et génération ----------------------------------------------------------


def references(dossier: Path | None = None) -> None:
	dossier = dossier or ART
	dossier.mkdir(parents=True, exist_ok=True)
	vue = Image.open(VUE).convert("RGB")
	for nom, boite in REFS.items():
		ref = vue.crop(boite)
		facteur = min(AGRANDIR, REF_MAX / max(ref.size))
		if facteur != 1:
			ref = ref.resize((round(ref.width * facteur), round(ref.height * facteur)), Image.LANCZOS)
		ref.save(dossier / f"{nom}.png")
	print(f"{len(REFS)} références REF_CB_* dans {dossier}")


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


JOURNAL_REFUS = "refus_serie22bis.log"
SANS_JOINTE = ("(Aucune image n'est jointe à cette demande : les « images jointes » citées plus bas ne "
	"sont PAS disponibles ; applique leur description écrite et ne cherche pas à les voir.)\n\n")
ESSAIS_AVEC = 2
ESSAIS_SANS = 2


def _consigner(nom: str, ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with (ART / JOURNAL_REFUS).open("a") as journal:
		journal.write(f"{nom} : {ligne}\n")


def _generer(image: dict) -> str:
	"""Règle de Kevin : d'abord AVEC les images jointes (ESSAIS_AVEC essais), puis SANS pièce jointe
	(ESSAIS_SANS essais) ; chaque refus est consigné. Une image sans jointe (Évoli) : ESSAIS_SANS essais."""
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	texte = image["fichier"].read_text()
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	derniere = ""
	if jointes:
		for essai in range(ESSAIS_AVEC):
			derniere = serie10._lancer(nom, texte, jointes)
			if derniere.endswith(": ok"):
				return derniere + (f" (essai {essai + 1} avec images)" if essai else "")
			_consigner(nom, f"refus ou échec AVEC images, essai {essai + 1} : {derniere[-160:]}")
	for essai in range(ESSAIS_SANS):
		derniere = serie10._lancer(nom, (SANS_JOINTE if jointes else "") + texte, [])
		if derniere.endswith(": ok"):
			if jointes:
				_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + (" (SANS pièce jointe)" if jointes else "")
		_consigner(nom, f"refus ou échec SANS pièce jointe, essai {essai + 1} : {derniere[-160:]}")
	return derniere


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


# --- Entrées du manifeste (préparées, NON lancées) ----------------------------------------


def _revision(base: str) -> str:
	"""Dernière révision présente dans $ART pour `base` (sans `_rN.png`), `_r1` par défaut."""
	for rev in (4, 3, 2, 1):
		if (ART / f"{base}_r{rev}.png").exists():
			return f"{base}_r{rev}.png"
	return f"{base}_r1.png"


def _planche_objets(base: str, dossier: str, ids: list[str], cases: list[float], contact: float,
		colonnes: int = 3, lignes: int = 2) -> dict:
	return {"source": _revision(base), "dossier": f"{_W}{dossier}/", "colonnes": colonnes, "lignes": lignes,
		"ids": ids, "cases": cases, "contact": contact}


def _provisoire_de(ident: str) -> str | None:
	"""Chemin (relatif à la racine) du provisoire qu'un identifiant remplace."""
	if ident.startswith("bldg_"):
		return f"{_W}buildings/{ident}.png"
	if ident == "prop_fontaine_01":
		return f"{_W}props/{ident}.png"
	if ident in ("game_corner_wall", "hideout_office_door"):
		return f"{_PH}ph_{ident}.png"
	if ident.startswith("int_") and ident.endswith("_coque"):
		return f"{_PH}ph_{ident[4:-6]}.png"
	return None


MUR_IDS = [f"relief_mur_{lieu}_0{i}" for lieu in ("repaire", "casino") for i in range(1, 6)]
INT_REPAIRE_IDS = ["int_caisse_repaire_01", "int_conduite_repaire_01", "int_console_repaire_01",
	"int_bureau_giovanni_01", "int_escalier_repaire_monte_01", "int_escalier_repaire_descend_01"]
INT_DALLES_IDS = ["decal_fleche_repaire_01", "decal_arret_repaire_01", "int_porte_ascenseur_repaire_01",
	"hideout_office_door"]
INT_CASINO_IDS = ["int_machine_casino_01", "int_machine_casino_02", "int_tabouret_casino_01",
	"int_comptoir_casino_01", "int_affiche_casino_01", "game_corner_wall"]
## Variantes dérivées à la préparation (le préparateur du jeu ne sait pas les produire) : la flèche pointe
## vers la droite ; haut = quart de tour anti-horaire, bas = quart de tour horaire, gauche = demi-tour.
ROTATIONS = {"haut": 90, "bas": -90, "gauche": 180}
## Éléments d'une planche qui prennent la taille EXACTE de leur provisoire (au lieu d'une largeur en cases) ;
## les décalcomanies sont inscrites dans un carré d'une case.
EXACTS = ("game_corner_wall", "hideout_office_door")
DECALS = ("decal_fleche_repaire_01", "decal_arret_repaire_01")


def _objet(asset: str, base: str, dossier: str, ombre: bool = True, contact: float | None = 0.12) -> dict:
	largeur, hauteur = TAILLES[asset]
	return {"id": asset, "source": _revision(base), "sortie": f"{_W}{dossier}/{asset}.png",
		"taille_cases": [largeur / 96, hauteur / 96], "ombre": ombre, "contact": contact}


def _piece(carte: str, base: str, cases: tuple[int, int], note: str | None = None) -> dict:
	entree = {"id": f"int_{carte}_coque", "source": _revision(base),
		"sortie": f"{_W}interiors/int_{carte}_coque.png", "cases": list(cases)}
	if note:
		entree["note"] = note
	return entree


def _cases_de(carte: str) -> tuple[int, int]:
	largeur, hauteur = _taille(f"{_PH}ph_{carte}.png")
	return largeur // 96, hauteur // 96


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (après validation seulement, en fin de chaque section). Réglages = défauts
	(règle 4), à ajuster sur la planche de contact. Les variantes dérivées (4e étage ambre du magasin,
	flèches haut / bas / gauche, tailles EXACTES de `game_corner_wall` et `hideout_office_door`) ne sont
	produites que par `serie22bis.py --preparer` : copier alors les fichiers de `$ART/serie22bis/`."""
	objets = [_objet(f[1], f"{f[0]}_NE", "buildings") for f in FACADES]
	objets.append({"id": "prop_fontaine_01", "source": _revision("WORLD_PROP_FONTAINE_01_NE"),
		"sortie": f"{_W}props/prop_fontaine_01.png",
		"taille_cases": [TAILLES["prop_fontaine_01"][0] / 96, TAILLES["prop_fontaine_01"][1] / 96],
		"ombre": False, "contact": 0.1})
	pieces = []
	for ident, cartes, *_reste in COQUES:
		carte = cartes[0]
		base = f"{ident}_NE"
		pieces.append(_piece(carte, base, _cases_de(carte)))
		if carte == "celadon_mansion_1f":  # même géométrie : copie
			pieces.append(_piece("celadon_mansion_2f", base, _cases_de("celadon_mansion_2f"),
				"même image que le 1er étage (grilles identiques)"))
	return {
		"objets": objets,
		"pieces": pieces,
		"sols": [
			{"id": "ground_beton_repaire_01", "source": _revision("WORLD_GROUND_BETON_REPAIRE_01_NE"),
				"sortie": f"{_W}ground/ground_beton_repaire_01.png", "taille": 384, "contraste": 0.8,
				"couleur": 1.0, "raccord": 24},
			{"id": "ground_moquette_casino_01", "source": _revision("WORLD_GROUND_MOQUETTE_CASINO_01_NE"),
				"sortie": f"{_W}ground/ground_moquette_casino_01.png", "taille": 384, "contraste": 0.8,
				"couleur": 1.0, "raccord": 24},
		],
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_MUR_REPAIRE_PLANCHE_NE", "relief", MUR_IDS[:5], [2, 2, 2, 0.35, 0.35], 0.0),
			_planche_objets("WORLD_RELIEF_MUR_CASINO_PLANCHE_NE", "relief", MUR_IDS[5:], [2, 2, 2, 0.35, 0.35], 0.0),
			_planche_objets("INT_REPAIRE_PLANCHE_NE", "interiors", INT_REPAIRE_IDS, [1, 1, 1, 4, 1, 1], 0.2),
			_planche_objets("INT_DALLES_REPAIRE_PLANCHE_NE", "interiors", INT_DALLES_IDS, [1, 1, 2, 2], 0.0),
			_planche_objets("INT_CASINO_PLANCHE_NE", "interiors", INT_CASINO_IDS, [1, 1, 1, 1, 1, 1], 0.2),
		],
		"pokemon": [{"id": "evoli", "source": _revision("POKE_EVOLI_NE"),
			"sortie": "assets/sprites/pokemon/painted/evoli_sheet.png", "hauteur": EVOLI_HAUTEUR,
			"note": "J20 T22 ; compagnon `eevee` (data/pokemon/companions.json) ; hauteur 56 par défaut (règle 4)"}],
		"attentes": [{"id": "evoli_idle", "source": _revision("EVOLI_ATTENTE"),
			"sortie": "assets/sprites/pokemon/painted/evoli_idle_sheet.png", "marche": "evoli"}],
	}


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries 10 à 21) ; une
	section absente est créée en fin de fichier. NE PAS lancer avant la validation des images."""
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
	lignes = ", ".join(f'("UI_OBJETS_22BIS_PLANCHE_{i + 1}_r1.png", {[o for o, _ in objets]})'
		for i, (_, objets, *_r) in enumerate(ICONES_PLANCHES))
	print(f"manifeste : {ajouts} entrée(s) de la série 22 bis ajoutée(s)")
	print("À ajouter à `PLANCHES_OBJETS_SUIVANTES` de tools/art/preparer_menu.py (icônes, hors manifeste) :\n" + lignes)


# --- Préparation (sans Codex) ---------------------------------------------------------------


def _ecrire(image: Image.Image, relatif: str) -> Path:
	"""Écrit dans $ART/serie22bis/ en reproduisant l'arborescence `assets/` (sans le préfixe)."""
	chemin = SORTIE / Path(relatif).relative_to("assets")
	chemin.parent.mkdir(parents=True, exist_ok=True)
	image.save(chemin, optimize=True) if chemin.suffix == ".png" else image.save(chemin)
	return chemin


def _source(nom: str) -> Image.Image | None:
	chemin = ART / nom
	return Image.open(chemin) if chemin.exists() else None


def _recolorer(image: Image.Image, depart: float, arrivee: float, tolerance: float = 24.0,
		sat_min: float = 0.28) -> Image.Image:
	"""Décline l'ACCENT d'une coque (magasin, 2e étage rose → 4e étage ambre) : seuls les pixels saturés dont
	la teinte est à `tolerance` degrés de `depart` sont décalés vers `arrivee` ; parquet, pierre et laiton (teintes
	chaudes de 20 à 60°, ou peu saturées) ne bougent pas."""
	import numpy as np
	hsv = np.asarray(image.convert("RGB").convert("HSV")).astype(np.float64)
	teinte = hsv[..., 0] * 360 / 255
	ecart = (teinte - depart + 180) % 360 - 180
	masque = (np.abs(ecart) <= tolerance) & (hsv[..., 1] / 255 >= sat_min)
	hsv[..., 0][masque] = ((teinte[masque] + (arrivee - depart)) % 360) * 255 / 360
	canaux = np.clip(hsv, 0, 255).astype(np.uint8)
	return Image.merge("HSV", [Image.fromarray(canaux[..., i]) for i in range(3)]).convert("RGB")


def _decal_carre(image: Image.Image, cote: int = 96) -> Image.Image:
	"""Décalcomanie d'UNE case : la silhouette tient dans un carré cote × cote, centrée (rotations exactes)."""
	import preparer
	forme = preparer._silhouette(image)
	echelle = cote / max(forme.size)
	forme = forme.resize((max(1, round(forme.width * echelle)), max(1, round(forme.height * echelle))),
		Image.LANCZOS)
	carre = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
	carre.alpha_composite(forme, ((cote - forme.width) // 2, (cote - forme.height) // 2))
	return carre


def _decouper_planche(planche: dict) -> list[tuple[str, Image.Image]]:
	"""Éléments d'une planche (taches de la silhouette, ordre de lecture, comme preparer.planches_objets) mis à
	leur largeur en cases ; les éléments de `EXACTS` prennent la taille de leur provisoire, ceux de `DECALS`
	sont inscrits dans un carré d'une case."""
	import preparer
	from PIL import ImageChops
	image = Image.open(ART / planche["source"]).convert("RGBA")
	taches = preparer._taches(image)
	if len(taches) != len(planche["ids"]):
		raise SystemExit(f"{planche['source']} : {len(taches)} éléments trouvés, {len(planche['ids'])} attendus")
	taches.sort(key=lambda t: t[0][1] + t[0][3])
	ordre = []
	for ligne in range(planche["lignes"]):
		rangee = taches[ligne * planche["colonnes"]:(ligne + 1) * planche["colonnes"]]
		ordre += sorted(rangee, key=lambda t: t[0][0] + t[0][2])
	sortie = []
	for ident, cases, (boite, masque) in zip(planche["ids"], planche["cases"], ordre):
		element = image.copy()
		element.putalpha(ImageChops.multiply(image.getchannel("A"), masque))
		element = element.crop(boite)
		if ident in DECALS:
			element = _decal_carre(element)
		elif ident in EXACTS:
			cible = _taille(_provisoire_de(ident))
			element = preparer._silhouette(element).resize(cible, Image.LANCZOS)
		else:
			element = preparer._mettre_a_taille(preparer._silhouette(element), "w", cases, 96)
		sortie.append((ident, element))
	return sortie


def preparer_tout() -> list[tuple[str, tuple[int, int], tuple[int, int] | None]]:
	"""Prépare les images retenues de $ART dans $ART/serie22bis/ (arborescence `assets/`), aux dimensions
	EXACTES des provisoires. Renvoie (nom, taille obtenue, taille attendue ou None) et affiche les écarts."""
	import preparer as pm
	donnees = manifeste_donnees()
	rapports: list[tuple[str, tuple[int, int], tuple[int, int] | None]] = []

	def noter(nom: str, image: Image.Image, attendue: tuple[int, int] | None) -> None:
		rapports.append((nom, image.size, attendue))
		etat = "ok" if attendue is None or attendue == image.size else f"ÉCART (attendu {attendue})"
		print(f"{nom} : {image.width} × {image.height}  {etat}")

	def manquant(nom: str) -> None:
		print(f"{nom} : image source absente (à générer)")

	# Façades et fontaine : silhouette → dimensions exactes du provisoire.
	for e in donnees["objets"]:
		source = _source(e["source"])
		if source is None:
			manquant(e["id"])
			continue
		attendue = _taille(_provisoire_de(e["id"]))
		if attendue != tuple(round(c * 96) for c in e["taille_cases"]):
			print(f"  ATTENTION {e['id']} : provisoire {attendue}, table TAILLES {e['taille_cases']}")
		image = pm._silhouette(source.convert("RGBA")).resize(attendue, Image.LANCZOS)
		_ecrire(image, e["sortie"])
		noter(e["id"], image, attendue)
	# Coques : image entière étirée à la taille du provisoire ; déclinaisons.
	coques: dict[str, Image.Image] = {}
	for e in donnees["pieces"]:
		carte = e["id"][4:-6]
		attendue = _taille(f"{_PH}ph_{carte}.png")
		source = _source(e["source"])
		if source is None:
			manquant(e["id"])
			continue
		image = source.convert("RGB").resize(attendue, Image.LANCZOS)
		coques[carte] = image
		_ecrire(image, e["sortie"])
		noter(e["id"], image, attendue)
	for carte, origine, depart, arrivee in DECLINAISONS:
		if origine not in coques:
			continue
		attendue = _taille(f"{_PH}ph_{carte}.png")
		propre = _source(_revision(f"INT_{carte.upper()}_COQUE_NE"))
		if propre is not None:  # coque conditionnelle générée : elle prime sur la recoloration
			image = propre.convert("RGB").resize(attendue, Image.LANCZOS)
		else:
			image = _recolorer(coques[origine].resize(attendue, Image.LANCZOS), depart, arrivee)
		_ecrire(image, f"{_W}interiors/int_{carte}_coque.png")
		noter(f"int_{carte}_coque", image, attendue)
	# Sols.
	from PIL import ImageEnhance
	for e in donnees["sols"]:
		source = _source(e["source"])
		if source is None:
			manquant(e["id"])
			continue
		image = source.convert("RGB").resize((e["taille"], e["taille"]), Image.LANCZOS)
		image = ImageEnhance.Contrast(image).enhance(e["contraste"])
		image = pm.raccorder(image, e["raccord"])
		_ecrire(image, e["sortie"])
		noter(e["id"], image, (e["taille"], e["taille"]))
	# Planches de modules, flèches dans les 4 directions.
	for planche in donnees["planches_objets"]:
		if not (ART / planche["source"]).exists():
			manquant(planche["source"])
			continue
		for ident, element in _decouper_planche(planche):
			attendue = _taille(_provisoire_de(ident)) if ident in EXACTS else None
			_ecrire(element, f"{planche['dossier']}{ident}.png")
			noter(ident, element, attendue)
			if ident == "decal_fleche_repaire_01":
				for nom, angle in ROTATIONS.items():
					tourne = element.rotate(angle, expand=True)
					_ecrire(tourne, f"{planche['dossier']}{ident}_{nom}.png")
					noter(f"{ident}_{nom}", tourne, (96, 96))
	# Icônes : 256 × 256 webp, découpe de preparer_menu.
	import preparer_menu
	dossier = SORTIE / "ui" / "items"
	dossier.mkdir(parents=True, exist_ok=True)
	for i, (ident, objets, *_r) in enumerate(ICONES_PLANCHES):
		if not (ART / _revision(ident)).exists():
			manquant(ident)
			continue
		preparer_menu._objets(ART / _revision(ident), dossier, [o for o, _ in objets])
		for o, _ in objets:
			with Image.open(dossier / f"{o}.webp") as icone:
				rapports.append((o, icone.size, (256, 256)))
				print(f"{o} : {icone.width} × {icone.height}  {'ok' if icone.size == (256, 256) else 'ÉCART'}")
	# Évoli : planche de marche 4 × 4 au format des compagnons, puis attente 4 × 1.
	import decouper_perso
	import decouper_attente
	marche = ART / _revision("POKE_EVOLI_NE")
	sortie_marche = SORTIE / "sprites" / "pokemon" / "painted" / "evoli_sheet.png"
	if marche.exists():
		sortie_marche.parent.mkdir(parents=True, exist_ok=True)
		cellule = decouper_perso.decouper(str(marche), str(sortie_marche), EVOLI_HAUTEUR)
		print(f"evoli_sheet : cellule {cellule[0]} × {cellule[1]} (4 × 4, hauteur {EVOLI_HAUTEUR})")
		attente = ART / _revision("EVOLI_ATTENTE")
		if attente.exists():
			sortie_attente = sortie_marche.with_name("evoli_idle_sheet.png")
			c = decouper_attente.decouper(str(attente), str(sortie_marche), str(sortie_attente), None, None)
			print(f"evoli_idle_sheet : cellule {c[0]} × {c[1]} (4 × 1)")
		else:
			manquant("EVOLI_ATTENTE")
	else:
		manquant("POKE_EVOLI_NE")
	ecarts = [r for r in rapports if r[2] is not None and r[1] != r[2]]
	print(f"{len(rapports)} fichier(s) préparé(s) dans {SORTIE} ; {len(ecarts)} écart(s) de taille")
	return rapports


# --- Planches de contact (sans Codex) -----------------------------------------------------


def _vignette(chemin: Path, facteur: float) -> Image.Image | None:
	if not chemin.exists():
		return None
	return _echelle(Image.open(chemin).convert("RGBA"), facteur)


def _paire(p, titre_section: str, paires: list[tuple[str, str | None, Path | None, float]], couleur,
		heros: Image.Image | None) -> None:
	"""Une section : chaque asset PRÉPARÉ à côté de son provisoire, à l'échelle `facteur` (1 = taille du jeu)."""
	elements = [(heros, "héros (échelle)")] if heros is not None else []
	for ident, provisoire, prepare, facteur in paires:
		if provisoire:
			vignette = _vignette(RACINE / provisoire, facteur)
			if vignette is not None:
				elements.append((vignette, f"{ident}\nPROVISOIRE {vignette.width * 1 / facteur:.0f} px"))
		if prepare is None:
			continue
		vignette = _vignette(prepare, facteur)
		if vignette is not None:
			elements.append((vignette, f"{ident}\nSÉRIE 22 BIS (échelle {facteur:g})"))
		else:
			elements.append((Image.new("RGBA", (120, 40), (90, 40, 40, 255)), f"{ident}\n(pas encore préparé)"))
	p.section(titre_section, elements, couleur)


def _heros(facteur: float) -> Image.Image | None:
	chemin = RACINE / f"{_C}heros_sheet.png"
	if not chemin.exists():
		return None
	feuille = Image.open(chemin).convert("RGBA")
	return _echelle(feuille.crop((0, 0, feuille.width // 4, feuille.height // 4)), facteur)


def contact() -> list[Path]:
	"""Planches de contact pour Kevin (`$ART/SERIE22BIS_CONTACT_*.png`) : chaque asset préparé (dans
	`$ART/serie22bis/`, `--preparer` d'abord) à côté de son provisoire, à l'échelle du jeu réduite."""
	donnees = manifeste_donnees()
	sorties = []

	def rendre(nom: str, titre: str, remplir) -> None:
		p = _Planche(2700, titre)
		remplir(p)
		chemin = ART / f"SERIE22BIS_CONTACT_{nom}.png"
		chemin.parent.mkdir(parents=True, exist_ok=True)
		p.rendre().convert("RGB").save(chemin, optimize=True)
		sorties.append(chemin)

	def facades(p) -> None:
		paires = [(e["id"], _provisoire_de(e["id"]), SORTIE / Path(e["sortie"]).relative_to("assets"), 0.25)
			for e in donnees["objets"][:-1]]
		_paire(p, "1. FAÇADES : provisoire | série 22 bis, 1 case = 24 px (héros 128 px = 32 px)", paires,
			(130, 70, 40), _heros(0.25))
		e = donnees["objets"][-1]
		_paire(p, "2. FONTAINE, à l'échelle 1 (192 × 186)", [(e["id"], _provisoire_de(e["id"]),
			SORTIE / Path(e["sortie"]).relative_to("assets"), 1.0)], (130, 70, 40), _heros(1.0))

	def interieurs(p) -> None:
		cartes = [(e["id"], _provisoire_de(e["id"]), SORTIE / Path(e["sortie"]).relative_to("assets"), 0.2)
			for e in donnees["pieces"]]
		cartes += [(f"int_{c}_coque", f"{_PH}ph_{c}.png", SORTIE / "world" / "interiors" / f"int_{c}_coque.png", 0.2)
			for c, *_ in DECLINAISONS]
		_paire(p, "1. COQUES D'INTÉRIEUR : provisoire | série 22 bis, 1 case = 19 px", cartes, (60, 80, 110),
			_heros(0.2))

	def modules(p) -> None:
		w = SORTIE / "world"
		_paire(p, "1. SOLS (384 px, à 1:2)", [(e["id"], None, w / "ground" / f"{e['id']}.png", 0.5)
			for e in donnees["sols"]], (130, 100, 40), None)
		for titre, ids, dossier, couleur in (
				("2. MURS DU REPAIRE ET DU CASINO (1:2, 1 case = 48 px)", MUR_IDS, "relief", (60, 80, 110)),
				("3. MOBILIER DU REPAIRE (1:2)", INT_REPAIRE_IDS, "interiors", (60, 80, 110)),
				("4. FLÈCHES, DISQUE, PORTES (1:2)", INT_DALLES_IDS + [f"decal_fleche_repaire_01_{n}"
					for n in ROTATIONS], "interiors", (60, 80, 110)),
				("5. MOBILIER DU CASINO (1:2)", INT_CASINO_IDS, "interiors", (110, 50, 90))):
			_paire(p, titre, [(i, _provisoire_de(i), w / dossier / f"{i}.png", 0.5) for i in ids], couleur,
				_heros(0.5))
		# Contexte : les provisoires des cartes en modules.
		_paire(p, "6. CONTEXTE : cartes en modules (provisoires à 1:10)", [
			(f"ph_{c}", f"{_PH}ph_{c}.png", None, 0.1) for c in
			("rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f", "rocket_hideout_b4f",
				"celadon_game_corner")], (80, 80, 80), None)

	def icones(p) -> None:
		dossier = SORTIE / "ui" / "items"
		refs = [(Image.open(ICONES_DOSSIER / f"{n}.webp").convert("RGBA"), f"{n}\n(existant)")
			for n in ("poke_ball", "potion", "hm05", "moon_stone") if (ICONES_DOSSIER / f"{n}.webp").exists()]
		p.section("0. ICÔNES EXISTANTES (référence de style)", refs, (80, 80, 80))
		for i, (ident, objets, *_r) in enumerate(ICONES_PLANCHES):
			elements = []
			for o, _ in objets:
				chemin = dossier / f"{o}.webp"
				elements.append((Image.open(chemin).convert("RGBA") if chemin.exists()
					else Image.new("RGBA", (120, 40), (90, 40, 40, 255)), f"{o}\n256 × 256" if chemin.exists()
					else f"{o}\n(pas encore préparé)"))
			p.section(f"{i + 1}. {ident}", elements, (110, 50, 90))

	def evoli(p) -> None:
		autres = RACINE / "assets/sprites/pokemon/painted"
		dossier = SORTIE / "sprites" / "pokemon" / "painted"
		elements = []
		for etiquette, chemin in (("rattata_sheet (référence, hauteur 56)", autres / "rattata_sheet.png"),
				("rattata_idle_sheet (référence)", autres / "rattata_idle_sheet.png"),
				("evoli_sheet (série 22 bis)", dossier / "evoli_sheet.png"),
				("evoli_idle_sheet (série 22 bis)", dossier / "evoli_idle_sheet.png")):
			image = _vignette(chemin, 1.0)
			elements.append((image if image is not None else Image.new("RGBA", (120, 40), (90, 40, 40, 255)),
				etiquette + ("" if image is not None else "\n(pas encore préparé)")))
		p.section("ÉVOLI COMPAGNON : planches du jeu à 1:1 (cellules au format des compagnons)", elements,
			(130, 100, 40))

	rendre("FACADES", "Série 22 bis — façades et fontaine de Céladopole", facades)
	rendre("INTERIEURS", "Série 22 bis — coques d'intérieur (mobilier compris)", interieurs)
	rendre("MODULES", "Série 22 bis — modules du repaire Rocket et du Casino", modules)
	rendre("ICONES", "Série 22 bis — icônes du Sac (29)", icones)
	rendre("EVOLI", "Série 22 bis — Évoli compagnon", evoli)
	return sorties


if __name__ == "__main__":
	arguments = sys.argv[1:]
	autres = [a for a in arguments if not a.startswith("--")]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--refs" in arguments:
		references(Path(autres[0]) if autres else None)
	elif "--commandes" in arguments:
		print(commandes())
	elif "--preparer" in arguments:
		preparer_tout()
	elif "--contact" in arguments:
		for chemin in contact():
			print(chemin)
	elif "--manifeste" in arguments:
		manifeste()
	else:
		generer(set(arguments))
