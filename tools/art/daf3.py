#!/usr/bin/env python3
"""Lot DAF.3 « Safrania et Sylphe » (phase DA, `docs/design/phase-da-cadrage.md` §3) : façades de
Safrania, modules de la Sylphe SARL, Arène de Morgane, Dojo ; et la part du lot DAF.4 déjà dans
`main` (Arène de Jadielle). Fiche : `docs/design/fiches-assets/daf-3/fiche.md`.

Règle de remplacement (série 22 bis, DA-1 à DA-9) : chaque façade garde l'identifiant, les
dimensions en pixels et l'emprise de son PROVISOIRE (`placeholders_safrania.py`) ; `--preparer`
ramène l'image retenue aux dimensions EXACTES du provisoire et refait ses ombres (comme
`placeholders_safrania.py`). Les cartes, collisions, portes et tests ne bougent pas.

Aucune vue générale peinte de Safrania n'a été validée (T5 du J26 non fait) : la cible vient du
dossier (« centre économique et technologique », `vision.md`), du poste peint du J20
(`bldg_poste_safrania_01`, même ville, même main) et des façades peintes de Céladopole.

Méthode des séries 19 à 22 bis : prompts versionnés (`tools/art/prompts/daf3/`), ancres = assets
préparés du dépôt ; règle de Kevin pour Codex : AVEC les images jointes (2 essais), puis SANS pièce
jointe (2 essais), refus consignés dans `$ART/refus_daf3.log`.

Usage :
  tools/art/daf3.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf3.py [GROUPE ...]         génère avec Codex (sans argument : tout ce qui manque)
  tools/art/daf3.py --preparer           images retenues → assets/ (dimensions exactes, ombres)
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
import serie10  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
PROMPTS = ICI / "prompts" / "daf3"
CASE = 96

_W = "assets/world/"
STYLE = [f"{_W}props/prop_souche_01.png", f"{_W}props/tree_a_01.png"]
POSTE = f"{_W}buildings/bldg_poste_safrania_01.png"  # J20, peint : même ville
MUSEE = f"{_W}buildings/bldg_musee_argenta_01.png"
MAGASIN = f"{_W}buildings/bldg_grand_magasin_01.png"
RESIDENCE = f"{_W}buildings/bldg_residence_01.png"
HOTEL = f"{_W}buildings/bldg_hotel_01.png"
MAISON_CHEF = f"{_W}buildings/bldg_maison_chef_01.png"
MAISON_ARGENTA = f"{_W}buildings/bldg_maison_argenta_01.png"
COIN_LOTS = f"{_W}buildings/bldg_coin_lots_01.png"
ARENE_CELADOPOLE = f"{_W}buildings/bldg_arene_celadopole_01.png"

INTERDITS = ("Interdits du lot : texte, lettres, chiffres, logo, enseigne écrite, inscription, la lettre R ou "
	"tout emblème de la Team Rocket, AUCUN emblème rond de type balle (ni cercle partagé en deux, ni médaillon "
	"à bande centrale), animaux réels, Pikachu et tout Pokémon, personnage (même s'il figure sur une image "
	"jointe), flou de profondeur, vignettage, pixel art, contour noir épais, aplats.")

LUMIERE_FACADE = (LUMIERE_NE + " La carte est étalonnée par le jeu en « golden hour » : peins la lumière NEUTRE "
	"et les couleurs LOCALES des matériaux, AUCUNE teinte dorée ni orangée, AUCUN halo ni lueur aux fenêtres "
	"(le jeu allume lui-même les vitres).")

VALEURS_VILLE = ("VALEURS DE SAFRANIA (« centre économique et technologique » de Kanto, une ville moderne, nette "
	"et prospère, de la MÊME main que le poste joint bldg_poste_safrania_01, sa référence directe) : pierre de "
	"taille gris clair et grège, enduits clairs, ARDOISE BLEUE des toits, verre bleu-gris, acier brossé, menuiseries "
	"bleu nuit, touches de laiton ; rues propres, fenêtres régulières ; peu de fleurs (quelques buis en pot). "
	+ LUMIERE_FACADE)


def _ord(n: int) -> str:
	return "1re" if n == 1 else f"{n}e"


def _porte(largeur: int, col: int, nombre: int) -> str:
	cols = _ord(col) if nombre == 1 else f"{_ord(col)} et {_ord(col + 1)}"
	un = "UNE case" if nombre == 1 else "DEUX cases"
	return (f"PORTE : {un} de large, au bas de la façade, exactement sur la {cols} colonne{'s' if nombre > 1 else ''} "
		f"sur {largeur} (1 colonne = 1/{largeur} de la largeur du bâtiment, 1 case = 96 px dans le jeu) ; "
		"le reste du bas de la façade ne porte AUCUNE autre porte ; le seuil est au ras du bas de l'image.")


def _format(largeur: int, hauteur: int) -> tuple[int, int]:
	rapport = largeur / hauteur
	if rapport >= 1.2:
		return (1536, 1024)
	if rapport <= 0.9:
		return (1024, 1536)
	return (1024, 1024)


def _boite(gen: tuple[int, int], final: tuple[int, int]) -> tuple[int, int]:
	maxi = (gen[0] - 136, gen[1] - 84) if gen[0] > gen[1] else (gen[0] - 84, gen[1] - 84)
	echelle = min(maxi[0] / final[0], maxi[1] / final[1])
	return round(final[0] * echelle), round(final[1] * echelle)


# --- A. Façades de Safrania ---------------------------------------------------------------------

## (identifiant, asset, largeur, profondeur (cases), porte (colonne depuis 1, nombre) ou texte,
## description, ancres). Taille finale = celle du provisoire (lue sur le fichier).
## Le poste est est le MIROIR du poste ouest (`MIROIRS`) : même bâtiment, porte de l'autre côté.
FACADES = [
	("WORLD_BLDG_SYLPHE_01", "bldg_sylphe_safrania_01", 14, 17, (7, 2),
		"la TOUR de la SYLPHE SARL, siège de la plus grande entreprise de Kanto, le bâtiment le PLUS HAUT et le "
		"plus moderne du jeu, vu en trois quarts de dessus : en HAUT de l'image (environ les 10 premières cases "
		"sur 17,25), le TOIT-TERRASSE plat vu de dessus : dalles gris clair, un acrotère net tout autour, trois "
		"blocs de climatisation métalliques alignés, des gaines, et au centre une aire d'hélicoptère marquée "
		"d'un simple CERCLE jaune (SANS lettre) ; en BAS (les 7 dernières cases), la FAÇADE sud : un mur-rideau "
		"de VERRE bleu-gris à montants d'acier brossé, SEPT niveaux de bandeaux de fenêtres réguliers, des "
		"pilastres de pierre gris clair aux angles, un socle de pierre au rez-de-chaussée ; au MILIEU du bas, "
		"une grande PORTE DOUBLE vitrée à cadre de laiton sous un auvent de verre, deux marches basses, deux "
		"petits buis taillés en pot. Imposante, propre, technologique. Aucune enseigne, aucun nom, aucun logo "
		"(le provisoire joint porte « SYLPHE SARL » et « H » : ne les reproduis pas).",
		[POSTE, MAGASIN, COIN_LOTS]),
	("WORLD_BLDG_ARENE_SAFRANIA_01", "bldg_arene_safrania_01", 12, 7, (7, 1),
		"l'ARÈNE de Safrania (Champion de type Psy, Morgane), façade de face : un HALL élégant et un peu "
		"mystérieux de 12 cases de large et environ 7,25 de haut en tout ; un toit d'ARDOISE PRUNE (violet "
		"sombre) à pans doux, avec au centre une petite COUPOLE de verre mauve et un lanternon ; des murs de "
		"pierre LAVANDE pâle en assises fines, deux rangées de hautes fenêtres étroites en ARC aux vitres "
		"mauves, des pilastres de pierre claire, une frise géométrique discrète (losanges, cercles concentriques "
		"abstraits) sous la corniche ; sur la 7e colonne, une PORTE de bois sombre d'UNE case sous un arc de "
		"pierre, une marche. Calme, symétrique, solennel. Aucune enseigne, aucune lettre (le provisoire joint "
		"porte le mot « ARENE » : ne le reproduis pas). Sans arbre, sans personnage.",
		[POSTE, ARENE_CELADOPOLE, MUSEE]),
	("WORLD_BLDG_DOJO_SAFRANIA_01", "bldg_dojo_safrania_01", 10, 7, (5, 2),
		"le DOJO de Safrania (le Dojo des arts martiaux, rival de l'Arène voisine), façade de face : un "
		"bâtiment traditionnel de 10 cases de large et environ 7,25 de haut en tout ; un grand TOIT de TUILES "
		"ROUGE BRIQUE sombre à larges débords et faîtage relevé aux extrémités ; des murs d'enduit crème "
		"rythmés de POTEAUX et de poutres de bois brun foncé (colombages verticaux réguliers), un soubassement "
		"de pierre grise, des fenêtres à claustras de bois clair ; au MILIEU du bas (5e et 6e colonnes), une "
		"grande PORTE COULISSANTE de bois à deux vantaux sous un auvent de tuiles, une marche de pierre. Sobre, "
		"robuste, accueillant. Aucune enseigne, aucune calligraphie, aucune lettre (le provisoire joint porte "
		"le mot « DOJO » : ne le reproduis pas). Sans arbre, sans personnage.",
		[POSTE, MAISON_ARGENTA]),
	("WORLD_BLDG_MAISON_SAFRANIA_01", "bldg_maison_safrania_01", 7, 6, (4, 1),
		"une MAISON de ville de Safrania (celle du Copieur), façade de face : 7 cases de large et environ 6,25 "
		"de haut en tout, deux niveaux ; toit de TUILES TERRE CUITE à quatre pans avec une cheminée de pierre, "
		"murs d'enduit SABLE chaud, encadrements de pierre claire, trois fenêtres à petits carreaux et volets "
		"bleu nuit, sur la 4e colonne une PORTE de bois brun d'UNE case sous un petit auvent, une marche, deux "
		"petits pots de buis. Soignée, sobre. Sans arbre, sans clôture, sans personnage, aucune inscription.",
		[POSTE, MAISON_CHEF]),
	("WORLD_BLDG_MAISON_SAFRANIA_02", "bldg_maison_safrania_02", 7, 6, (4, 1),
		"une MAISON de ville de Safrania (celle du Roucool messager), façade de face : 7 cases de large et "
		"environ 6,25 de haut en tout, deux niveaux ; toit d'ARDOISE VERT-GRIS à quatre pans avec une lucarne, "
		"murs d'enduit VERT SAUGE pâle, encadrements de pierre claire, trois fenêtres à petits carreaux, une "
		"petite jardinière, sur la 4e colonne une PORTE de bois brun d'UNE case, une marche. Même main et même "
		"gabarit que la maison jointe, couleurs différentes. Sans arbre, sans personnage, aucune inscription.",
		[POSTE, MAISON_CHEF]),
	("WORLD_BLDG_MAISON_SAFRANIA_03", "bldg_maison_safrania_03", 7, 6, (4, 1),
		"une MAISON de ville de Safrania (celle de M. Psy), façade de face : 7 cases de large et environ 6,25 de "
		"haut en tout, deux niveaux ; toit d'ARDOISE BLEU-VIOLET à quatre pans avec une cheminée, murs d'enduit "
		"LILAS très pâle, encadrements de pierre claire, trois fenêtres à petits carreaux et volets gris "
		"perle, sur la 4e colonne une PORTE de bois sombre d'UNE case sous un petit fronton, une marche, deux "
		"pots de lavande. Même main et même gabarit que la maison jointe, couleurs différentes. Sans arbre, sans "
		"personnage, aucune inscription.",
		[POSTE, MAISON_CHEF]),
	("WORLD_BLDG_IMMEUBLE_SAFRANIA_01", "bldg_immeuble_safrania_01", 7, 6, None,
		"un IMMEUBLE de bureaux de Safrania, façade de face : 7 cases de large et environ 6,25 de haut en tout, "
		"vu en trois quarts de dessus (on voit le TOIT PLAT gris à acrotère, avec un petit édicule et une "
		"bouche de ventilation, puis la façade) ; façade de pierre GRÈGE (sable clair) à trois niveaux de "
		"fenêtres régulières à montants d'acier, corniche nette, socle de pierre plus sombre. AUCUNE PORTE "
		"(on ne peut pas y entrer). Sans enseigne, sans arbre, sans personnage.",
		[POSTE, HOTEL]),
	("WORLD_BLDG_IMMEUBLE_SAFRANIA_02", "bldg_immeuble_safrania_02", 7, 6, None,
		"un IMMEUBLE de bureaux de Safrania, façade de face : 7 cases de large et environ 6,25 de haut en tout, "
		"vu en trois quarts de dessus (TOIT PLAT gris foncé à acrotère, deux blocs de climatisation) ; façade de "
		"pierre GRIS PERLE et grands bandeaux de VERRE bleu-gris sur trois niveaux, montants d'acier brossé, "
		"socle de pierre. AUCUNE PORTE. Même main que l'immeuble joint, matières différentes. Sans enseigne, "
		"sans arbre, sans personnage.",
		[POSTE, COIN_LOTS]),
	("WORLD_BLDG_IMMEUBLE_SAFRANIA_03", "bldg_immeuble_safrania_03", 7, 6, None,
		"un IMMEUBLE d'habitation de Safrania, façade de face : 7 cases de large et environ 6,25 de haut en "
		"tout, vu en trois quarts de dessus (TOIT de zinc brun-gris à deux pans, une cheminée) ; façade de "
		"BRIQUE ROSÉE et de pierre claire sur trois niveaux, fenêtres hautes à petits carreaux, petits "
		"balconnets de fer. AUCUNE PORTE. Sans enseigne, sans arbre, sans personnage.",
		[POSTE, RESIDENCE]),
	("WORLD_BLDG_IMMEUBLE_BAS_SAFRANIA_01", "bldg_immeuble_bas_safrania_01", 8, 4, None,
		"un BÂTIMENT BAS de Safrania (entrepôt ou annexe de bureaux, au bord sud de la ville), façade de face : "
		"8 cases de large et environ 4,25 de haut en tout, vu en trois quarts de dessus (TOIT PLAT gris à "
		"acrotère, puis un mur de façade d'environ 2 cases de haut) ; pierre grège et une rangée de fenêtres "
		"basses régulières, socle sombre. AUCUNE PORTE. Sans enseigne, sans arbre, sans personnage.",
		[POSTE, COIN_LOTS]),
	("WORLD_BLDG_IMMEUBLE_BAS_SAFRANIA_02", "bldg_immeuble_bas_safrania_02", 6, 4, None,
		"un petit BÂTIMENT BAS de Safrania, façade de face : 6 cases de large et environ 4,25 de haut en tout, "
		"vu en trois quarts de dessus (toit d'ARDOISE BLEUE à faible pente, puis un mur de façade d'environ 2 "
		"cases de haut) ; enduit sable chaud, une rangée de trois fenêtres à volets bleu nuit. AUCUNE PORTE. "
		"Sans enseigne, sans arbre, sans personnage.",
		[POSTE, MAISON_CHEF]),
	("WORLD_BLDG_POSTE_SAFRANIA_NORD_01", "bldg_poste_safrania_nord_01", 4, 3, (2, 2),
		"le POSTE DE GARDE NORD de Safrania (le passage vers la Route 5), façade de face : EXACTEMENT le "
		"bâtiment du poste joint bldg_poste_safrania_01 (même pierre de taille claire, même ARDOISE BLEUE à "
		"quatre pans, même porte double bleu nuit, mêmes petites lanternes), en plus petit : 4 cases de large et "
		"environ 3,25 de haut en tout ; un mur de façade bas, une petite fenêtre de chaque côté de la porte. "
		"Sans enseigne (le provisoire joint porte le mot « POSTE » : ne le reproduis pas), sans personnage.",
		[POSTE]),
	("WORLD_BLDG_POSTE_SAFRANIA_SUD_01", "bldg_poste_safrania_sud_01", 4, 3,
		"VU DE DOS : on arrive sur ce poste par le NORD. Le bâtiment est vu en trois quarts de dessus depuis le "
		"sud comme tous les autres, donc on n'en voit QUE LE TOIT (aucun mur, aucune façade) : le grand toit "
		"d'ARDOISE BLEUE à quatre pans occupe toute l'image ; dans le bord HAUT (nord) du toit, sur les 2e et 3e "
		"colonnes sur 4, un PASSAGE ouvert : une échancrure rectangulaire dans le toit, d'environ 2 cases de "
		"large et 0,8 case de haut, qui laisse voir l'intérieur SOMBRE du porche (dallage de pierre dans "
		"l'ombre, deux marches qui descendent vers le sud) encadrée de pierre claire. L'image va jusqu'aux "
		"quatre bords : rien au-dessus du toit.",
		"le POSTE DE GARDE SUD de Safrania (le passage vers la Route 6), même bâtiment que le poste joint "
		"bldg_poste_safrania_01 (même pierre claire, même ARDOISE BLEUE), 4 cases de large et 3 cases de haut.",
		[POSTE]),
	("WORLD_BLDG_POSTE_SAFRANIA_OUEST_01", "bldg_poste_safrania_ouest_01", 3, 5,
		"PORTE SUR LE FLANC DROIT (est) : on entre par la DROITE, pas par le bas. Vu en trois quarts de dessus, le "
		"bâtiment montre son TOIT (environ les 3,8 premières cases depuis le haut) puis un mur sud bas (environ "
		"1,4 case) SANS porte. Sur le bord DROIT du bâtiment, à hauteur des 3e et 4e rangées sur 5 depuis le "
		"haut, un PORCHE ouvert : le toit y forme une avancée en auvent et laisse voir un passage SOMBRE de 2 "
		"cases de haut, encadré de pierre claire, qui touche le bord droit de l'image. Rien d'autre sur les côtés.",
		"le POSTE DE GARDE OUEST de Safrania (le passage vers la Route 7), même bâtiment que le poste joint "
		"bldg_poste_safrania_01 (même pierre claire, même ARDOISE BLEUE à quatre pans, mêmes lanternes), mais "
		"ÉTROIT et LONG du nord au sud : 3 cases de large et environ 5,25 de haut en tout.",
		[POSTE]),
]
## Postes miroir : asset → (asset source, retournement horizontal).
MIROIRS = {"bldg_poste_safrania_est_01": "bldg_poste_safrania_ouest_01"}


def _taille(asset: str) -> tuple[int, int]:
	with Image.open(RACINE / f"{_W}buildings/{asset}.png") as image:
		return image.size


def _prompt_facade(ident, asset, largeur, profondeur, porte, description, ancres) -> str:
	final = _taille(asset)
	gen = _format(*final)
	ew, eh = _boite(gen, final)
	prov = f"{_W}buildings/{asset}.png"
	jointes = (f"Images jointes : {Path(prov).stem} = le PROVISOIRE actuel (un dessin schématique en aplats) : il "
		"ne donne QUE la géométrie (emprise, proportions, position de la porte, hauteur du mur de façade par "
		"rapport au toit) ; n'en copie NI le rendu en aplats, NI les couleurs plates, NI les mots écrits dessus ; "
		f"{', '.join(Path(a).stem for a in ancres)} = bâtiments déjà peints du jeu : ancres de style (rendu peint, "
		"contour coloré fin, finesse, MÊME angle de vue en trois quarts de dessus, même lumière neutre, même "
		"échelle de détail).")
	if isinstance(porte, tuple):
		ligne_porte = _porte(largeur, *porte)
	elif isinstance(porte, str):
		ligne_porte = porte
	else:
		ligne_porte = "AUCUNE PORTE : aucune ouverture, aucun seuil, aucune marche."
	corps = (f"ASSET : {description}\n{ligne_porte}\nFormat : PNG {gen[0]} × {gen[1]}, l'élément occupe environ "
		f"{ew} × {eh} px (rapport largeur / hauteur {final[0] / final[1]:.2f} : 1, à RESPECTER : l'image est "
		f"ramenée telle quelle à {final[0]} × {final[1]} px, soit 1 case = 96 px), centré, TOUT le bâtiment "
		f"visible, rien ne dépasse du cadre. Échelle : {largeur} cases de large et {final[1] / 96:.2f} de haut "
		f"(profondeur de l'emprise : {profondeur} cases) ; un adulte mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n{ADN}\n"
		f"{VALEURS_VILLE}\n\n{corps}\n")


# --- B. Modules : Sylphe SARL, Arène de Morgane, Dojo, Arène de Jadielle --------------------------
#
# Méthode du repaire Rocket (série 22 bis, Q-2) : sol peint raccordable + masse sombre (canal G de
# `cave_map_kit.gd`), murs aux rôles de la Tour (`module_walls.gd`), mobilier et marques au sol
# d'UNE case, posés par la grille. Une seule série de textures pour les 11 étages : la mémoire de
# la Sylphe ne dépend plus du nombre d'étages en cache (RP-143 : 161 Mo au 7F avec les coques).

_G = f"{_W}ground/"
_R = f"{_W}relief/"
_I = f"{_W}interiors/"
MURS_TOUR = [f"{_R}relief_mur_tour_0{i}.png" for i in (1, 2, 3, 4, 5)]
MURS_REPAIRE = [f"{_R}relief_mur_repaire_0{i}.png" for i in (1, 2, 3, 4, 5)]
DALLES_TOUR = f"{_G}ground_dalles_tour_01.png"
BETON = f"{_G}ground_beton_repaire_01.png"
MOQUETTE_CASINO = f"{_G}ground_moquette_casino_01.png"

TEXTURE_FIN = ("Format : PNG carré 1024 × 1024, OPAQUE, qui couvre toute l'image. Texture vue strictement de "
	"dessus, à plat, RACCORDABLE sans couture sur ses quatre bords (elle se répète en mosaïque) ; motif régulier "
	"sans élément remarquable qui trahirait la répétition ; aucune perspective, aucun objet, aucun bord, aucun "
	"vignettage.")
_CELLULES = ("dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de 512 × 512), "
	"un élément par cellule, centré, la base de chacun sur une même ligne horizontale à 40 px du bas de sa "
	"cellule, les éléments bien SÉPARÉS les uns des autres par du vide")
_MURS_ROLES = ("MÊMES rôles, MÊMES découpes, MÊMES proportions et même manière de peindre que les modules joints "
	"relief_mur_repaire_01 à _05 (face A, face B, couronnement, bord latéral, angle) : gabarit de la Tour ; ANGLES "
	"DROITS : chaque module est un rectangle net qui se raccorde bout à bout.")
INTERIEUR = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu ajoute lui-même "
	"l'ambiance) : AUCUNE teinte dorée, AUCUN halo, AUCUNE flaque de lumière, AUCUNE lueur d'écran, aucune ombre "
	"portée au sol.")
VALEURS_SYLPHE = ("VALEURS DE LA SYLPHE SARL (le siège d'une grande entreprise technologique, propre, clair et "
	"moderne, JAMAIS sinistre même occupé par la Team Rocket) : moquette gris-bleu, cloisons crème et gris "
	"perle, plinthes et montants d'acier brossé, bois clair des bureaux, touches de bleu nuit et de cyan ; " + INTERIEUR)
VALEURS_MORGANE = ("VALEURS DE L'ARÈNE DE SAFRANIA (Champion de type Psy : salles calmes, mystérieuses et "
	"symétriques) : dallage lavande et prune, pierre claire veinée de mauve, montants d'argent ; " + INTERIEUR)
VALEURS_DOJO = ("VALEURS DU DOJO (une salle d'arts martiaux traditionnelle, sobre et chaleureuse) : parquet de bois "
	"blond, poteaux et poutres de bois brun, cloisons d'enduit crème, papier de riz ; " + INTERIEUR)
VALEURS_JADIELLE = ("VALEURS DE L'ARÈNE DE JADIELLE (l'arène du chef de la Team Rocket, type Sol : austère, terre "
	"et pierre, imposante, JAMAIS effrayante) : dallage de grès ocre et brun, murs de pierre sombre brun-gris, "
	"plinthes de bronze ; " + INTERIEUR + " Aucune lettre R, aucun emblème.")

## Textures : (identifiant, asset, description, ancres, valeurs).
SOLS = [
	("WORLD_GROUND_MOQUETTE_SYLPHE_01", "ground_moquette_sylphe_01",
		"texture du SOL DE BUREAU de la Sylphe SARL (tous étages) : une MOQUETTE de bureau en DALLES CARRÉES gris-bleu "
		"moyen (luminosité environ 55 à 65 %, assez claire pour que des bureaux de bois et un tapis de téléporteur "
		"violet ressortent nettement), environ une dalle par case (1 case = 256 px sur cette texture), dalles posées "
		"droites avec un très léger changement de sens du velours d'une dalle à l'autre (damier à peine visible), "
		"joints presque invisibles, grain fin de moquette rase ; propre et neutre ; aucune tache, aucune ligne peinte.",
		[DALLES_TOUR, MOQUETTE_CASINO], VALEURS_SYLPHE),
	("WORLD_GROUND_MASSE_BATIMENT_01", "ground_masse_batiment_01",
		"texture du DESSUS DES MURS ÉPAIS et des zones hors plan d'un grand bâtiment moderne vus de dessus : une matière "
		"MATE gris ardoise bleuté très sombre (luminosité environ 14 à 20 %), grain fin de béton lissé, très légères "
		"nuances ; AUCUNE ligne de joint, aucun motif ; sombre mais jamais noir pur ; sert à remplir de grandes surfaces.",
		[BETON], VALEURS_SYLPHE),
	("WORLD_GROUND_DALLES_MORGANE_01", "ground_dalles_morgane_01",
		"texture du SOL de l'ARÈNE de SAFRANIA (Psy) : grandes DALLES CARRÉES de pierre polie LAVANDE pâle veinée de "
		"mauve (luminosité environ 60 %), une dalle par case (1 case = 256 px sur cette texture), joints fins prune, "
		"posées droites ; calme et lisse ; assez claire pour qu'un tapis de téléporteur violet sombre ressorte.",
		[DALLES_TOUR], VALEURS_MORGANE),
	("WORLD_GROUND_PARQUET_DOJO_01", "ground_parquet_dojo_01",
		"texture du SOL du DOJO : un PARQUET de lames de bois BLOND larges posées HORIZONTALEMENT (de gauche à droite), "
		"2 lames par case (1 case = 256 px sur cette texture), extrémités décalées d'une rangée à l'autre, fins joints "
		"brun clair, veinage doux, légère patine ; chaleureux et propre.",
		[DALLES_TOUR], VALEURS_DOJO),
	("WORLD_GROUND_DALLES_JADIELLE_01", "ground_dalles_jadielle_01",
		"texture du SOL de l'ARÈNE de JADIELLE (type Sol) : grandes DALLES CARRÉES de GRÈS OCRE sable (luminosité environ "
		"50 à 58 %, pour qu'une flèche JAUNE et un disque CLAIR peints dessus ressortent), une dalle par case (1 case = "
		"256 px sur cette texture), joints fins brun sombre, surface mate un peu usée, très légères nuances.",
		[BETON, DALLES_TOUR], VALEURS_JADIELLE),
]


def _planche_murs(lieu: str, matiere: str, face_b: str) -> str:
	return (f"PLANCHE de 5 MODULES DE MUR {lieu}, {_CELLULES}, à une échelle COMMUNE : 1 case = 150 px, tous vus "
		f"de dessus en trois quarts. Matière : {matiere} ; " + _MURS_ROLES + "\n"
		"1 (ligne 1, à gauche) : FACE A, un mur vu de face (le sol est au SUD), 2 cases de large × 2 de haut : en "
		"haut le couronnement vu de dessus, puis la face du mur, puis la plinthe ; bord bas droit et net. "
		f"2 (ligne 1, au milieu) : FACE B, même gabarit, {face_b} ; 1 et 2 se raccordent bout à bout. "
		"3 (ligne 1, à droite) : COURONNEMENT, le dessus d'un mur dont le sol est au NORD : une bande HORIZONTALE "
		"vue de dessus, 2 cases × environ 0,4, sans face visible.\n"
		"4 (ligne 2, à gauche) : BORD LATÉRAL, le côté d'un mur dont le sol est à DROITE : une bande VERTICALE de "
		"couronnement vu de dessus avec une mince bande de face, environ 0,35 case de large × 2 de haut. "
		"5 (ligne 2, au milieu) : ANGLE, le coin d'un mur vu de dessus (un couronnement en équerre), environ 0,35 × "
		"0,6 case. (ligne 2, à droite) : cellule VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée.")


## Planches : (identifiant, description, ancres, valeurs, jointes de la vague 1 (noms dans $ART)).
PLANCHES = [
	("WORLD_RELIEF_MUR_SYLPHE_PLANCHE", _planche_murs("de la SYLPHE SARL (cloisons de bureaux, tous étages)",
		"CLOISONS de bureau à panneaux CRÈME et GRIS PERLE séparés par de fins montants d'ACIER brossé, un bandeau "
		"bleu nuit à mi-hauteur, couronnement de dessus gris clair, plinthe d'acier ; propres, nettes, modernes",
		"avec au milieu une large FENÊTRE INTÉRIEURE (vitrage bleu-gris pâle, sans reflet, sans rien derrière) à "
		"cadre d'acier"), MURS_REPAIRE + MURS_TOUR[:1], VALEURS_SYLPHE, ["WORLD_GROUND_MOQUETTE_SYLPHE_01_NE_r1.png"]),
	("WORLD_RELIEF_MUR_MORGANE_PLANCHE", _planche_murs("de l'ARÈNE de SAFRANIA (cloisons entre les salles)",
		"PIERRE claire LAVANDE en panneaux lisses encadrés de fines moulures d'ARGENT, une frise de petits losanges "
		"prune sous le couronnement, couronnement prune vu de dessus, plinthe prune ; calme, symétrique",
		"avec au milieu un grand MÉDAILLON de pierre à cercles concentriques abstraits gravés (sans lettre, sans "
		"balle)"), MURS_REPAIRE, VALEURS_MORGANE, ["WORLD_GROUND_DALLES_MORGANE_01_NE_r1.png"]),
	("WORLD_RELIEF_MUR_DOJO_PLANCHE", _planche_murs("du DOJO (murs et piliers de la salle)",
		"ENDUIT crème entre des POTEAUX et une lisse de BOIS brun foncé, panneaux de papier de riz à croisillons "
		"fins, couronnement de bois brun vu de dessus, plinthe de bois sombre ; sobre et chaleureux",
		"avec au milieu un RÂTELIER de bois portant deux bâtons d'entraînement et une petite étagère (aucune "
		"calligraphie, aucune affiche écrite)"), MURS_REPAIRE, VALEURS_DOJO, ["WORLD_GROUND_PARQUET_DOJO_01_NE_r1.png"]),
	("WORLD_RELIEF_MUR_JADIELLE_PLANCHE", _planche_murs("de l'ARÈNE de JADIELLE (murs du labyrinthe)",
		"gros BLOCS de PIERRE brun-gris taillés en assises régulières, joints sombres, couronnement de dalles de "
		"pierre plus claire vu de dessus, PLINTHE de bronze patiné ; massif et austère",
		"avec au milieu un pilastre de pierre plus clair et une applique de bronze ÉTEINTE (sans halo)"),
		MURS_REPAIRE, VALEURS_JADIELLE, ["WORLD_GROUND_DALLES_JADIELLE_01_NE_r1.png"]),
	("INT_SYLPHE_PLANCHE",
		f"PLANCHE de 6 ÉLÉMENTS de MOBILIER de la SYLPHE SARL, {_CELLULES}, à une échelle COMMUNE de 1 case = 120 px, "
		"tous vus de dessus en trois quarts (on voit le dessus et la face avant sud) ; même main que les meubles et les "
		"murs joints.\n"
		"1 (ligne 1, à gauche) : BUREAU, UNE case de bureau de bois clair à plateau large, vu de face en trois quarts, "
		"EXACTEMENT 1 case de large (≈ 120 px) et environ 1,25 case de haut, avec dessus un petit ÉCRAN plat d'ordinateur "
		"(écran SOMBRE, sans image, sans lueur) et quelques feuilles ; ses bords gauche, droit, haut et bas sont droits : "
		"il se JUXTAPOSE en rangées et en blocs (2 × 2, 2 × 8, 6 × 2) avec lui-même sans couture visible.\n"
		"2 (ligne 1, au milieu) : ARMOIRE DE SERVEURS, une baie informatique d'acier gris clair à portes grillagées, "
		"voyants peints minuscules (sans lueur), 1 case de large, environ 1,5 case de haut ; elle se juxtapose en "
		"colonnes (l'une au-dessus de l'autre) et en rangées.\n"
		"3 (ligne 1, à droite) : PLANTE de bureau, un grand ficus en pot de céramique blanche, 1 case de large, environ "
		"1,6 case de haut.\n"
		"4 (ligne 2, à gauche) : ESCALIER QUI MONTE, une ouverture dans un mur de cloison crème : des marches de pierre "
		"claire qui MONTENT vers le haut de l'image et disparaissent dans l'ombre douce, rampe d'acier, 1 case de large, "
		"environ 1,5 case de haut, base droite.\n"
		"5 (ligne 2, au milieu) : ESCALIER QUI DESCEND, même cadre et même largeur, des marches qui DESCENDENT dans "
		"l'ombre douce (on voit le haut des premières marches), rampe d'acier, 1 case de large, environ 1,5 case de haut.\n"
		"6 (ligne 2, à droite) : PORTE D'ASCENSEUR, une porte coulissante d'ACIER brossé à deux vantaux FERMÉS dans un "
		"encadrement de cloison crème, un petit bouton d'appel, 1 case de large, environ 1,5 case de haut, base droite.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée, aucun texte.",
		[f"{_I}int_bureau_pc_01.png", f"{_I}int_plante.png", f"{_I}int_console_repaire_01.png",
			f"{_I}int_escalier_repaire_monte_01.png", f"{_I}int_porte_ascenseur_repaire_01.png"],
		VALEURS_SYLPHE, ["WORLD_GROUND_MOQUETTE_SYLPHE_01_NE_r1.png", "WORLD_RELIEF_MUR_SYLPHE_PLANCHE_NE_r1.png"]),
	("INT_SYLPHE_DALLES_PLANCHE",
		f"PLANCHE de 5 ÉLÉMENTS PLATS ou BAS de la SYLPHE SARL, {_CELLULES}, à une échelle COMMUNE de 1 case = 150 px, "
		"vus de dessus en trois quarts.\n"
		"1 (ligne 1, à gauche) : TAPIS DE TÉLÉPORTEUR, une dalle technologique CARRÉE posée à plat au sol, vue de dessus, "
		"1 case × 1 case (≈ 150 × 150 px) : un cadre d'acier clair, à l'intérieur un disque VIOLET profond cerclé d'un "
		"anneau CYAN et d'un anneau blanc, petit motif de cercles concentriques ; peint, mat, SANS halo ni lueur ; très "
		"lisible sur une moquette gris-bleu.\n"
		"2 (ligne 1, au milieu) : SEUIL DE PORTE ÉLECTRONIQUE, une bande de sol plate vue de dessus, 1 case × 1 case : "
		"rail d'acier gris au milieu et bandes de sécurité JAUNES et grises en diagonale sur les bords.\n"
		"3 (ligne 1, à droite) : PAILLASSON d'entrée, un grand tapis plat rectangulaire gris anthracite à bord bleu "
		"nuit, vu de dessus, 2 cases de large × 1 case de haut.\n"
		"4 (ligne 2, à gauche) : PORTE ÉLECTRONIQUE HORIZONTALE fermée, un battant coulissant d'ACIER brossé à bande "
		"JAUNE de sécurité et petit lecteur de carte à voyant ROUGE peint (sans lueur), vu de face en trois quarts, "
		"2 cases de large × 1 case de haut (≈ 300 × 150 px), bords nets.\n"
		"5 (ligne 2, au milieu) : PORTE ÉLECTRONIQUE VERTICALE fermée, le même battant pour une porte tournée nord-sud : "
		"vu de dessus, une longue cloison d'acier 1 case de large × 2 cases de haut (≈ 150 × 300 px), bande jaune et "
		"lecteur de carte. (ligne 2, à droite) : cellule VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol autour, aucune ombre portée, aucun texte.",
		[f"{_I}int_cabine_teleport_01.png", f"{_I}decal_arret_repaire_01.png", f"{_I}hideout_office_door.png"],
		VALEURS_SYLPHE, ["WORLD_GROUND_MOQUETTE_SYLPHE_01_NE_r1.png", "WORLD_RELIEF_MUR_SYLPHE_PLANCHE_NE_r1.png"]),
]

COQUE_CABINE = ("INT_SILPH_CO_ELEVATOR_COQUE", "int_silph_co_elevator_coque",
	"la CABINE D'ASCENSEUR de la Sylphe SARL, une pièce entière vue de dessus en projection oblique frontale, 4 × 4 "
	"cases (1 case = 256 px sur cette image) : le MUR DU FOND (rangée du haut) est une cloison d'acier brossé et de "
	"panneaux crème ; sur la 4e colonne du mur du fond (tout à droite), un PANNEAU D'ÉTAGES : une plaque d'acier "
	"avec deux colonnes de petits boutons ronds (sans chiffre) ; le SOL (rangées 2 à 4) est une moquette gris-bleu ; "
	"les murs latéraux sont de minces bandes d'acier ; en bas, sur les 2e et 3e colonnes, les PORTES coulissantes "
	"ouvertes de la cabine (une bande sombre au ras du bas de l'image). Format : PNG 1024 × 1024 OPAQUE, la pièce "
	"remplit toute l'image.",
	[f"{_I}int_rocket_hideout_elevator_coque.png", f"{_I}int_celadon_dept_elevator_coque.png"], VALEURS_SYLPHE)


def _prompt_module(ident: str, sujet: str, ancres: list[str], valeurs: str, v1: list[str], texture: bool) -> str:
	jointes = (f"Images jointes : {', '.join(Path(a).stem for a in ancres)} = assets déjà peints du jeu : ancres de "
		"style (rendu peint, contour coloré fin, même angle de vue, même lumière neutre, même échelle de détail)"
		+ (f" ; {', '.join(Path(a).stem for a in v1)} = éléments DÉJÀ GÉNÉRÉS de ce lot : MÊME matière, mêmes "
			"couleurs, même main (raccord exact)" if v1 else "") + ".")
	fin = TEXTURE_FIN if texture else ""
	return (f"{ident} — NOUVELLE image pour un jeu vidéo.\n{jointes}\n\n{ADN}\n{valeurs}\n\nASSET : {sujet}\n{fin}\n"
		f"{INTERDITS}\n")


def _images() -> list[dict]:
	images = []
	for ident, asset, largeur, profondeur, porte, description, ancres in FACADES:
		prov = f"{_W}buildings/{asset}.png"
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "asset": asset, "vague": 1,
			"texte": _prompt_facade(ident, asset, largeur, profondeur, porte, description, ancres),
			"jointes": [prov, *ancres]})
	for ident, _asset, description, ancres, valeurs in SOLS:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 1,
			"texte": _prompt_module(ident, description, ancres, valeurs, [], True), "jointes": ancres})
	for ident, description, ancres, valeurs, v1 in PLANCHES:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 2 if ident.startswith("WORLD") else 3,
			"texte": _prompt_module(ident, description, ancres, valeurs, v1, False), "jointes": ancres + v1})
	ident, _asset, description, ancres, valeurs = COQUE_CABINE
	images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 1,
		"texte": _prompt_module(ident, description, ancres, valeurs, [], False), "jointes": ancres})
	for (ident, rev), complement in CORRECTIONS.items():
		base = next(i for i in images if i["groupe"] == ident)
		precedent = f"{ident}_NE_r{rev - 1}.png"
		images.append({"nom": f"{ident}_NE_r{rev}", "groupe": f"{ident}_r{rev}", "vague": 4,
			"texte": base["texte"] + f"\nCORRECTION (révision {rev}) : {complement}\nL'image jointe "
				f"{precedent[:-4]} est la révision précédente : garde ce qui va, corrige seulement ce qui est dit.\n",
			"jointes": base["jointes"] + [precedent]})
	return images


## Corrections après relecture : (identifiant, révision) → texte ajouté.
CORRECTIONS: dict[tuple[str, int], str] = {}

## Révision retenue par asset (défaut r1).
RETENUES: dict[str, int] = {}


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
		print(PROMPTS / f"{image['nom']}.txt")


SANS_JOINTE = ("(Aucune image n'est jointe à cette demande : les « images jointes » citées plus bas ne "
	"sont PAS disponibles ; applique leur description écrite et ne cherche pas à les voir.)\n\n")


def _consigner(nom: str, ligne: str) -> None:
	with (ART / "refus_daf3.log").open("a") as journal:
		journal.write(f"{nom} : {ligne}\n")


def _generer(image: dict) -> str:
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	derniere = ""
	for essai in range(2):
		derniere = serie10._lancer(nom, image["texte"], jointes)
		if derniere.endswith(": ok"):
			return derniere
		_consigner(nom, f"échec AVEC images, essai {essai + 1} : {derniere[-160:]}")
	for essai in range(2):
		derniere = serie10._lancer(nom, SANS_JOINTE + image["texte"], [])
		if derniere.endswith(": ok"):
			_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + " (SANS pièce jointe)"
		_consigner(nom, f"échec SANS pièce jointe, essai {essai + 1} : {derniere[-160:]}")
	return derniere


def generer(choix: set[str]) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	for vague in (1, 2, 3, 4):
		images = [i for i in _images() if i["vague"] == vague and (
			not choix or i["groupe"] in choix or i["nom"] in choix)]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(_generer, images):
				print(ligne, flush=True)


def _ecrire_avec_ombres(image: Image.Image, asset: str, catalogue: dict, manifest: dict) -> None:
	import preparer
	rel = f"{_W}buildings/{asset}.png"
	image.save(RACINE / rel, optimize=True)
	entry = {"fichier": "res://" + rel, "taille": list(image.size)}
	ombre, decalage, reduction = preparer.ombre_portee(image, manifest["ombre_portee"])
	nom = rel.replace(".png", "_shadow.png")
	ombre.save(RACINE / nom, optimize=True)
	entry["ombre"] = {"fichier": "res://" + nom, "decalage": list(decalage), "echelle": reduction,
		"taille": list(ombre.size)}
	ombre, decalage, reduction = preparer.ombre_contact(image, 0.12, manifest["ombre_contact"])
	nom = rel.replace(".png", "_contact.png")
	ombre.save(RACINE / nom, optimize=True)
	entry["contact"] = {"fichier": "res://" + nom, "decalage": list(decalage), "echelle": reduction,
		"taille": list(ombre.size)}
	catalogue["objets"][asset] = entry


def preparer_facades(seulement: set[str] | None = None) -> None:
	"""Façades retenues → `assets/world/buildings/` aux dimensions EXACTES du provisoire, ombres
	portée et de contact refaites, entrées du catalogue mises à jour (comme `placeholders_safrania.py`)."""
	import preparer
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	manifest = json.loads((ICI / "manifeste.json").read_text())
	faites: dict[str, Image.Image] = {}
	for ident, asset, *_reste in FACADES:
		if seulement and asset not in seulement:
			continue
		source = ART / f"{ident}_NE_r{RETENUES.get(asset, 1)}.png"
		if not source.exists():
			print(f"{asset} : source absente ({source.name})")
			continue
		attendue = _taille(asset)
		image = preparer._silhouette(Image.open(source).convert("RGBA")).resize(attendue, Image.LANCZOS)
		_ecrire_avec_ombres(image, asset, catalogue, manifest)
		faites[asset] = image
		print(f"{asset} : {image.size} ← {source.name}")
	for asset, depuis in MIROIRS.items():
		if depuis in faites and (not seulement or asset in seulement or depuis in seulement):
			image = faites[depuis].transpose(Image.FLIP_LEFT_RIGHT)
			if image.size != _taille(asset):
				raise SystemExit(f"{asset} : miroir {image.size} ≠ {_taille(asset)}")
			_ecrire_avec_ombres(image, asset, catalogue, manifest)
			print(f"{asset} : miroir de {depuis}")
	catalogue_path.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--preparer"]:
		preparer_facades(set(args[1:]) or None)
	else:
		generer(set(args))
