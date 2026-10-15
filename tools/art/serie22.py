#!/usr/bin/env python3
"""Série 22 — lot d'art 20.0a du jalon 20 (Céladopole) : espèces, personnages, décors de combat.

Fiche : docs/design/fiches-assets/serie-22-celadopole.md ; plan : docs/tech/jalon-20.md §1.4, T2,
T3 ; conception : docs/design/dossier-23-celadopole.md §3.2, §7.3, §11, §13, §15.1, §23.
Tâches (A) : rien n'est branché dans le jeu (ni manifeste, ni decors.json, ni BattleArt, ni
build_character_frames.gd) ; l'intégration revient au T10.

Trois familles, méthodes reprises des séries précédentes :
  1. DOS_<ESPÈCE> : dos de combat provisoires peints par Codex (voie de Fantominus, série 20, et
     d'Hypno, J17 T13 : aucun modèle 3D X/Y installé pour ces espèces, Colab non lancé) au format
     des `battle_proto/dos_ia_NNN.png` (1024², sujet ≈ 85 % de la hauteur, bas à 120 px) ;
  2. PNJ_<NOM> + <NOM>_ATTENTE : planches de marche 4 × 4 et d'attente 4 × 1 (modèle des séries
     10–19 : MODELE_MARCHE de serie12, attente de serie17), 128 px en jeu ;
  3. COMBAT_DECOR_<NOM> : décors CB.3 (composition 2,17 : 1 + deux tuiles TL / TR repeintes,
     recalées et cousues par combat_decors/preparer_decor.master, 2340 × 1080, WebP 90).
Faces et artworks du Pokédex : artworks officiels, déjà présents (assets/sprites/pokemon/official).

Usage :
  tools/art/serie22.py --prompts               écrit les prompts versionnés (r1 à r3)
  tools/art/serie22.py --refs                  recadre les références de la vue de Céladopole
  tools/art/serie22.py --commandes             liste les appels generer.sh
  tools/art/serie22.py --generer NOM [NOM ...]  lance generer.sh (3 à la fois)
  tools/art/serie22.py --tuiles ESSAI          découpe les portions TL / TR d'une composition
  tools/art/serie22.py --decor ESSAI SORTIE    master 2340 × 1080 → $ART/serie22/<SORTIE>_back.{png,webp}
  tools/art/serie22.py --detourer              prépare les essais retenus (RETENUS) dans $ART/serie22/
  tools/art/serie22.py --contact               planches de contact à l'échelle du jeu
  tools/art/serie22.py --kit                   planche du kit (existant réutilisé + à produire)
"""
from __future__ import annotations

import json
import math
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
sys.path.insert(0, str(ICI / "combat_decors"))
from serie06 import LUMIERE_NE  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
SORTIE = ART / "serie22"
PROMPTS = ICI / "prompts" / "serie22"
ATTENTES = ICI / "attente" / "prompts"
PROMPTS_DECOR = ICI / "combat_decors" / "prompts"
REFERENCE = RACINE / "docs/design/reference"
VUE = REFERENCE / "celadopole-vue-generale-v1.png"  # 1536 × 1024
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026/build/art")
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PROTO = RACINE / "assets/sprites/pokemon/battle_proto"
PERSOS = RACINE / "assets/sprites/characters/painted"
DECORS = RACINE / "assets/battle/decors"
HEROS = PRINCIPAL / "PERSO_P2_PEINT_r1.png"

REFS = {
	"REF_CE_SERRE": (95, 470, 455, 850),     # serre d'Erika, haies, massifs (vue validée)
	"REF_CE_AVENUE": (470, 320, 1250, 540),  # pavés clairs, massifs, haies, bancs
	"REF_CE_CIVIL": (780, 600, 1050, 710),   # les deux Rocket en civil devant le Casino
	"REF_CE_JARDIN": (100, 300, 460, 420),   # massifs fleuris, bancs, haies taillées
}

FIN_DETOURE = ("FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun "
	"fond coloré, aucun sol, aucune ombre portée.")

# --- 1. Dos de combat ------------------------------------------------------------------
## (identifiant, numéro, nom français, nom anglais, taille RB en m, priorité, sujet de dos)
ESPECES = [
	("EVOLI", "133", "Évoli", "Eevee", 0.3, 1,
		"petit mammifère quadrupède brun-roux chaud, assis ou debout sur ses quatre pattes, GRANDE "
		"COLLERETTE de fourrure crème duveteuse autour du cou (qui déborde sur les épaules, visible de "
		"dos), très grandes oreilles pointues brunes dressées, queue touffue et large, brune avec le BOUT "
		"CRÈME, relevée en panache"),
	("CANINOS", "058", "Caninos", "Growlithe", 0.7, 1,
		"chiot quadrupède robuste au pelage ORANGE vif rayé de BANDES NOIRES sur le dos et les flancs, "
		"touffe de fourrure CRÈME sur le haut de la tête et en collerette sur la poitrine (débordant un "
		"peu sur les côtés), queue touffue crème, oreilles arrondies"),
	("GOUPIX", "037", "Goupix", "Vulpix", 0.6, 1,
		"petit renard quadrupède au pelage ROUX-ROUGE, une grosse boucle de fourrure orange clair sur le "
		"haut de la tête, et SIX QUEUES ondulées roux-orangé aux pointes bouclées, en éventail derrière "
		"lui (bien visibles de dos), petites pattes brun clair"),
	("EMPIFLOR", "071", "Empiflor", "Victreebel", 1.7, 1,
		"grande plante carnivore en forme de CLOCHE / urne JAUNE-VERT pâle, ouverte vers le haut, avec une "
		"longue LIANE brune qui sort du dessus et retombe en boucle derrière, deux grandes feuilles vert "
		"franc sur les côtés ; de dos on voit le dos lisse de la cloche jaune tacheté de petits points "
		"bruns, la liane et les feuilles ; pas de pieds (la cloche repose au sol)"),
	("RAFFLESIA", "045", "Rafflesia", "Vileplume", 1.2, 1,
		"plante trapue sur deux petits pieds : corps bleu foncé rond, surmonté d'une ÉNORME FLEUR à cinq "
		"grands PÉTALES ROUGES tachetés de grosses taches blanc rosé, au cœur violet sombre ; de dos on voit "
		"le dessous des pétales rouges qui débordent tout autour de la tête et le dos bleu foncé"),
	("ARCANIN", "059", "Arcanin", "Arcanine", 1.9, 2,
		"grand chien majestueux quadrupède, pelage ORANGE vif zébré de BANDES NOIRES, épaisse CRINIÈRE "
		"CRÈME touffue autour de la tête et des épaules, touffes crème aux pattes, longue queue crème en "
		"panache"),
	("FEUNARD", "038", "Feunard", "Ninetales", 1.1, 2,
		"renard élégant au pelage CRÈME DORÉ très clair, collerette duveteuse, NEUF LONGUES QUEUES souples "
		"crème aux pointes ORANGE PÂLE, en éventail ample derrière lui (dominantes de dos), longues pattes "
		"fines"),
	("AQUALI", "134", "Aquali", "Vaporeon", 1.0, 2,
		"quadrupède aquatique BLEU CLAIR à la peau lisse, COLLERETTE blanc crème en volants autour du cou, "
		"grandes NAGEOIRES-OREILLES bleu pâle sur les côtés de la tête, une petite crête dorsale foncée, "
		"longue QUEUE de sirène terminée par une large nageoire bleu foncé"),
	("VOLTALI", "135", "Voltali", "Jolteon", 0.8, 2,
		"quadrupède fin au pelage JAUNE vif tout HÉRISSÉ en PIQUANTS pointus (surtout le dos, la croupe et "
		"la queue), COLLERETTE blanche en pointes autour du cou, grandes oreilles pointues jaunes"),
	("PYROLI", "136", "Pyroli", "Flareon", 0.9, 2,
		"quadrupède trapu au pelage ROUGE-ORANGÉ, très grosse COLLERETTE de fourrure JAUNE CRÈME duveteuse "
		"autour du cou, touffe jaune sur le front, longues oreilles rouges, grosse QUEUE touffue jaune "
		"crème en panache"),
	("OSSELAIT", "104", "Osselait", "Cubone", 0.4, 2,
		"petit bipède BRUN-ROUX au ventre crème, la tête entièrement couverte d'un CASQUE-CRÂNE blanc os "
		"(de dos on voit l'arrière lisse et arrondi du crâne blanc et ses deux petites pointes), une petite "
		"queue courte à pointe, tenant un OS blanc dans une main (dépasse sur le côté)"),
]
ANGLE = PROTO / "dos_ia_025.png"  # trois quarts dos, regard vers le haut à droite (lot pilote)

DOS = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). {nom}

{ancres}

SUJET : {sujet}.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
{fin}
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage."""

DOS_NOM = {
	1: "Le Pokémon est {fr} ({en}, n° {num}), de la première génération.",
	2: "La créature est un animal fantastique de jeu vidéo.",
	3: "La créature est un animal fantastique de jeu vidéo.",
}
DOS_ANCRES = {
	1: ("IMAGE 1 : l'artwork officiel de face de ce Pokémon : anatomie, couleurs, proportions et style de "
		"rendu (pas la pose : on le veut de dos).\nIMAGE 2 : un autre Pokémon de dos déjà produit pour ce "
		"jeu : reprends son ANGLE de vue (trois quarts dos, regard vers le haut à droite), son cadrage et sa "
		"famille de rendu ; ne reprends ni sa forme ni ses couleurs."),
	2: ("IMAGE 1 : une illustration de face de la créature : couleurs, proportions et style (pas la pose).\n"
		"IMAGE 2 : une autre créature vue de dos dans ce jeu : reprends son ANGLE de vue et son cadrage, pas "
		"sa forme."),
	3: "Aucune image jointe.",
}

# --- 2. Personnages ----------------------------------------------------------------------
PIEDS_JOINTS = "debout, calme et naturel, le poids réparti sur les deux jambes"
## (identifiant, priorité, rôle court, tenue [défaut, règle 4], pose d'attente, ancres de marche)
PERSONNAGES = [
	("PNJ_ERIKA", 1, "Erika, la Championne de l'Arène de Céladopole (type Plante)",
		"ERIKA, une jeune femme d'environ 20 ans, douce, calme et un peu rêveuse : cheveux NOIRS coupés en "
		"CARRÉ court avec une frange droite, un BANDEAU ROUGE noué dans les cheveux ; KIMONO court VERT JADE "
		"aux larges manches, semé de petites fleurs pâles (blanc, rose pâle), CEINTURE OBI JAUNE MOUTARDE "
		"nouée dans le dos, HAKAMA (jupe-culotte plissée) rouge sombre aux genoux, chaussettes blanches et "
		"sandales de bois. Silhouette fine, maintien élégant. Taille d'une jeune adulte, un peu plus petite "
		"qu'un homme adulte. Différente du héros et de la Championne jointe (ni cheveux roux, ni tenue de "
		"bain) ; aucun texte, aucun logo.",
		f"{PIEDS_JOINTS}, les mains jointes devant elle à hauteur de la ceinture, les yeux mi-clos, l'air "
		"paisible et un peu somnolent", ["ondine_sheet.png"]),
	("PNJ_GIOVANNI", 1, "le chef de la Team Rocket, dans son bureau du repaire",
		"un homme d'environ 45 ans, grand, calme et autoritaire, sûr de lui sans aucune caricature : "
		"cheveux BRUN FONCÉ courts PLAQUÉS en arrière, visage carré aux traits marqués, sourcils épais, "
		"regard froid ; COSTUME TROIS PIÈCES élégant BRUN ORANGÉ sombre (terre cuite foncée), veste longue "
		"croisée à revers larges, CHEMISE NOIRE, CRAVATE NOIRE, un minuscule insigne ROUGE au revers (simple "
		"pastille, sans lettre), chaussures noires cirées. Plus grand et plus large d'épaules que les autres "
		"adultes (environ 1,1 fois un adulte ordinaire). Ni chapeau, ni arme, ni lunettes noires, ni pose "
		"théâtrale, pas un méchant de dessin animé ; différent du héros, du Sbire joint et du président joint "
		"(ni bordeaux, ni moustache) ; aucun texte.",
		f"{PIEDS_JOINTS}, les mains dans le dos, le menton légèrement levé, l'air de celui qui attend une "
		"explication", ["sbire_h_sheet.png", "president_fan_club_sheet.png"]),
	("PNJ_ROCKET_CIVIL", 3, "un membre de la Team Rocket en civil, posté devant le Casino",
		"un homme d'environ 30 ans en CIVIL élégant, l'air fermé et désœuvré : COSTUME NOIR ajusté, chemise "
		"blanche, CRAVATE ROUGE (le seul détail rouge), CHAPEAU FEUTRE NOIR à ruban noir, petites lunettes "
		"de soleil sombres, chaussures noires. Taille d'un adulte, mince. Différent du Sbire joint (aucun "
		"uniforme, aucune casquette, aucun R, aucun insigne) et du héros ; aucun texte.",
		f"{PIEDS_JOINTS}, les bras croisés, la tête un peu tournée, l'air de surveiller la rue",
		["sbire_h_sheet.png"]),
	("PNJ_INTELLO", 3, "un Intello, Dresseur de la Route 8, passionné de calculs et de machines",
		"un jeune homme d'environ 22 ans, maigre, l'air absorbé : grosses LUNETTES rondes épaisses, cheveux "
		"bruns en bataille, chemise à manches courtes blanc cassé avec une POCHE pleine de stylos, NŒUD "
		"PAPILLON vert, pantalon beige trop court, chaussettes blanches et mocassins bruns, un petit "
		"CARNET dans une main. Taille d'un adulte, épaules étroites. Différent du héros, du chercheur joint "
		"(pas de blouse blanche) ; aucun texte.",
		f"{PIEDS_JOINTS}, le carnet ouvert tenu des deux mains devant lui, un doigt sur la page, l'air "
		"concentré", ["chercheur_sheet.png"]),
	("PNJ_BEAUTE", 4, "une Beauté, Dresseuse de l'Arène d'Erika",
		"une jeune femme d'environ 24 ans, élégante et sûre d'elle : longs cheveux CHÂTAIN CLAIR ondulés "
		"sur les épaules, ROBE d'été ROSE PÂLE à bretelles, mi-longue et évasée, petit sac à main blanc, "
		"escarpins blancs, un bracelet doré. Silhouette fine, taille d'une jeune adulte. Différente du "
		"héros et de la Dresseuse jointe (ni casquette, ni jupe plissée) ; aucun texte.",
		f"{PIEDS_JOINTS}, une main sur la hanche et l'autre qui tient son sac, l'air assuré",
		["dresseuse_sheet.png"]),
	("PNJ_TOPDRESSEUSE", 4, "une Topdresseuse, la Dresseuse confirmée qui garde Erika",
		"une Dresseuse confirmée d'environ 20 ans, sportive et sérieuse : cheveux AUBURN attachés en queue "
		"de cheval haute, VESTE courte BLEU MARINE à col montant ouverte sur un haut blanc, JUPE courte "
		"bleu marine, BOTTES noires montantes, gants sans doigts noirs, une ceinture à Poké Balls (petites "
		"sphères rouge et blanc, sans motif). Taille d'une jeune adulte. Différente du héros, de la "
		"Dresseuse jointe et de la Championne jointe ; aucun texte.",
		f"{PIEDS_JOINTS}, les bras croisés, l'air attentif et confiant",
		["dresseuse_sheet.png", "ondine_sheet.png"]),
]
INTERDITS_PNJ = ("Interdits : texte, lettres, chiffres, logo, filigrane, signature, Pokémon, Poké Ball "
	"tenue en main, cadre, sol, ombre portée, pixel art, 3D.")

# --- 3. Décors de combat -----------------------------------------------------------------
COMPOSITION = """COMPOSITION (fractions depuis le coin haut gauche) — à respecter précisément :
{lieu_compo}
- Point A (x 67 %, y {ya} %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien de haut dans un rayon de 12 % de la largeur autour.
- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier plan. Rien de haut autour.
- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de détails et peu de contraste, valeurs simples.
- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol simple, presque sans objet, valeurs moyennes, sans contraste fort.
- Les deux coins du bas restent du SOL nu : pas de buisson ni de gros objet en gros plan.
- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur certains écrans)."""

RENDU_DECOR = ("RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne "
	"« HD-2D peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni "
	"en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches sans "
	"être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à hauteur d'yeux, "
	"un peu plongeante, le sol recule nettement vers le fond.")

DECORS_COMBAT = {
	"URBAINE": {
		"sortie": "route_7_8_urbaine", "zone": "route_8", "variant": "urbaine",
		"titre": "ROUTES 7 ET 8, ENTRE LAVANVILLE ET CÉLADOPOLE",
		"image3": "IMAGE 3 : un extrait de la vue de dessus de Céladopole (validée) : pavés clairs, massifs fleuris, haies taillées, bancs (guide de palette et de matériaux, vu ici à hauteur d'yeux).",
		"ref": "REF_CE_AVENUE",
		"lieu": "une route aux portes d'une grande ville prospère : une large bande d'herbe courte et de hautes herbes vert tendre bordée d'un CHEMIN DE PAVÉS CLAIRS qui s'éloigne ; de part et d'autre, des HAIES TAILLÉES basses, un muret de pierre claire, deux réverbères de fer noir élégants ; au loin, au-dessus des arbres, les TOITS et le haut de quelques immeubles clairs de la ville (pierre claire, ardoise, verre), petits et bleutés par la distance. Golden hour. Ni panneau lisible, ni voiture.",
		"lieu_compo": "- Horizon vers 33 % de la hauteur : à GAUCHE, une rangée de feuillus ronds et une haie en plan moyen ; au CENTRE et à DROITE, les toits lointains de la ville sur un ciel clair, pas plus hauts que 30 % de la hauteur ; un réverbère en plan moyen à droite (x 80 à 88 %).\n- De 45 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT d'herbe courte, le chemin de pavés clairs qui arrive du bas à gauche et s'éloigne vers le centre.",
		"ya": 55,
		"lumiere": "LUMIÈRE : golden hour, soleil bas venant du haut à gauche (hors cadre), lumière dorée chaude sur l'herbe, les pavés et les façades lointaines, ombres douces, lointains froids bleutés ; ciel bleu pâle voilé, nuages légers rose doré, pas de soleil visible.",
		"interdits": "INTERDITS : Pokémon, animal, personnage, silhouette, texte, lettres, chiffres, panneau lisible, enseigne, logo, signature, filigrane, cadre, interface, voiture, route goudronnée, néon, eau, pixel art, flou, vignettage.",
		"tuile": "une route aux portes d'une ville : herbe, pavés clairs, haies taillées, réverbères, toits lointains",
	},
	"SERRE": {
		"sortie": "celadon_gym_serre", "zone": "celadon_gym", "variant": "serre",
		"titre": "ARÈNE DE CÉLADOPOLE, LA SERRE D'ERIKA",
		"image3": "IMAGE 3 : un extrait de la vue de dessus de Céladopole (validée) : la serre de verre et d'acier blanc dans son enclos de haies (guide de matériaux et de palette, vu ici de l'INTÉRIEUR, à hauteur d'yeux).",
		"ref": "REF_CE_SERRE",
		"lieu": "l'intérieur d'une grande SERRE élégante, jardin botanique d'une Championne de type Plante : une VERRIÈRE de verre et de fines armatures de fer blanc en arcs, au-dessus et au fond ; des ALLÉES de dalles claires entre des HAIES TAILLÉES vert profond, des massifs de FLEURS PÂLES (blanc, rose pâle, lilas, jaune doux), quelques palmiers et fougères en pots ; au fond, un BASSIN calme à margelle de pierre claire, eau verte et nénuphars. Calme, élégant, paisible.",
		"lieu_compo": "- Fond (de 0 à 38 % de la hauteur) : la verrière en arcs et, à son pied, les haies et les massifs du fond ; le bassin au fond à DROITE (x 60 à 90 %), sa margelle vers 36 % de la hauteur.\n- De 42 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de dalles claires et d'herbe rase, bordé de haies basses seulement sur les côtés extrêmes.",
		"ya": 52,
		"lumiere": "LUMIÈRE : lumière du jour FILTRÉE par la verrière, douce et VERDÂTRE, quelques rais de soleil pâle obliques venant du haut à gauche, sans éblouissement ; ombres vert froid douces, jamais noires ; aucun scintillement excessif.",
		"interdits": "INTERDITS : Pokémon, animal, personnage, silhouette, texte, lettres, chiffres, panneau, logo, signature, filigrane, cadre, interface, ciel ouvert sans vitrage, statue, pixel art, flou, vignettage.",
		"tuile": "l'intérieur d'une serre : verrière, haies taillées, fleurs pâles, bassin, dalles claires",
	},
	"REPAIRE": {
		"sortie": "rocket_hideout_repaire", "zone": "rocket_hideout", "variant": "repaire",
		"titre": "REPAIRE SOUTERRAIN D'UNE ORGANISATION, SOUS UN CASINO",
		"image3": "",
		"ref": None,
		"lieu": "une grande salle technique d'un repaire souterrain moderne : murs de BÉTON gris clair à panneaux, PILIERS d'acier, CONDUITES et faisceaux de CÂBLES le long des murs et du plafond bas, quelques CAISSES de bois et de métal empilées sur les côtés, une console éteinte au fond ; des RAMPES DE NÉONS BLANCS au plafond. Sol de béton lisse gris, quelques marques de peinture de sol jaunes au bord (lignes, jamais de lettres). Organisé, propre, crédible : ni ruine, ni cachot. Tendu sans être angoissant.",
		"lieu_compo": "- Fond (de 0 à 38 % de la hauteur) : le mur du fond en béton, des conduites, une porte d'acier fermée au centre-gauche, des caisses empilées à droite (x 78 à 92 %), base du mur vers 36 % de la hauteur.\n- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de béton gris lisse.",
		"ya": 50,
		"lumiere": "LUMIÈRE : lumière BLANCHE et un peu dure des néons, venant du haut, froide et uniforme, le centre du sol nettement lisible ; ombres gris-bleu froides, jamais noires. Aucune obscurité, aucune lumière rouge d'alarme.",
		"interdits": "INTERDITS : Pokémon, animal, personnage, silhouette, texte, lettres (aucun R, aucun logo), chiffres, panneau, écran allumé, arme, sang, signature, filigrane, cadre, interface, ciel, fenêtre, végétation, pixel art, flou, vignettage.",
		"tuile": "une salle technique souterraine : béton, acier, conduites, câbles, caisses, néons blancs",
	},
}

DECOR = """DÉCOR DE COMBAT — {titre} (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.

Images jointes.
IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement plongeante, grand sol dégagé au centre), sa profondeur et sa qualité de peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le coucher de soleil orange.
IMAGE 2 : une planche d'intention de décors de combat (guide de facture).
{image3}

FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution possible, OPAQUE, cadrage plein, sans bord.

LIEU : {lieu}

{compo}

{lumiere}

{rendu}

{interdits}"""

TUILE = """AGRANDISSEMENT D'UNE PORTION DE DÉCOR (Kanto 2026). L'image jointe est une portion d'un décor peint ({quoi}). Produis EXACTEMENT LA MÊME IMAGE, à une résolution plus élevée, avec plus de finesse dans la peinture.

RÈGLES ABSOLUES :
- Même cadrage au pixel près : même largeur et même hauteur relatives, chaque élément exactement à la même place et à la même taille. N'ajoute rien, n'enlève rien, ne déplace rien, ne recadre pas, ne prolonge pas l'image.
- Mêmes couleurs, même lumière, même style (illustration 2D peinte « HD-2D peint », masses douces, aucun trait noir).
- Seulement plus de netteté et de détails fins dans le pinceau, comme une version haute définition du même tableau.
- Aucun flou, aucun texte, aucune lettre, aucun personnage, aucune créature, aucun cadre.

FORMAT : même rapport largeur / hauteur que l'image jointe (environ 1,17 : 1, légèrement plus large que haute), la plus grande résolution possible, OPAQUE."""

## Essais retenus après relecture (voir la fiche) : clé = asset, valeur = nom de l'essai.
RETENUS: dict[str, str] = {
	"DOS_EVOLI": "DOS_EVOLI_r1", "DOS_GOUPIX": "DOS_GOUPIX_r1", "DOS_CANINOS": "DOS_CANINOS_r2",
	"DOS_RAFFLESIA": "DOS_RAFFLESIA_r2", "DOS_EMPIFLOR": "DOS_EMPIFLOR_r3", "DOS_OSSELAIT": "DOS_OSSELAIT_r2",
	"PNJ_ERIKA": "PNJ_ERIKA_NE_r1", "PNJ_ERIKA_ATTENTE": "ERIKA_ATTENTE_r1",
	"PNJ_GIOVANNI": "PNJ_GIOVANNI_NE_r1", "PNJ_GIOVANNI_ATTENTE": "GIOVANNI_ATTENTE_r1",
	# Reprise du 2026-10-16 (quota revenu).
	"DOS_AQUALI": "DOS_AQUALI_r3", "DOS_ARCANIN": "DOS_ARCANIN_r2", "DOS_FEUNARD": "DOS_FEUNARD_r3",
	"PNJ_ROCKET_CIVIL": "PNJ_ROCKET_CIVIL_NE_r1", "PNJ_ROCKET_CIVIL_ATTENTE": "ROCKET_CIVIL_ATTENTE_r1",
	"PNJ_INTELLO": "PNJ_INTELLO_NE_r1", "PNJ_INTELLO_ATTENTE": "INTELLO_ATTENTE_r1",
	"PNJ_BEAUTE": "PNJ_BEAUTE_NE_r1", "PNJ_BEAUTE_ATTENTE": "BEAUTE_ATTENTE_r1",
	"PNJ_TOPDRESSEUSE": "PNJ_TOPDRESSEUSE_NE_r1", "PNJ_TOPDRESSEUSE_ATTENTE": "TOPDRESSEUSE_ATTENTE_r1",
}
RETENUS_DECOR: dict[str, str] = {"URBAINE": "COMBAT_DECOR_URBAINE_r1", "SERRE": "COMBAT_DECOR_SERRE_r1",
	"REPAIRE": "COMBAT_DECOR_REPAIRE_r1"}


# --- Prompts --------------------------------------------------------------------------
def _ecrire(chemin: Path, texte: str) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	chemin.write_text(texte.strip() + "\n")


def _prompt_attente(ident: str, role: str, tenue: str, pose: str) -> str:
	"""Modèle des attentes des séries 10–19 (serie17._prompt_attente)."""
	nom = ident.removeprefix("PNJ_")
	marche = f"{ident}_NE_r1"
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
		"128 px de haut. Ni pixel art, ni 3D.\n"
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
		f"{posture}\n{INTERDITS_PNJ}\n")


def _prompt_marche(ident: str, tenue: str, ancres: list[str]) -> str:
	noms = " et ".join(f"la planche {Path(a).stem}" for a in ancres)
	ref = (f" ; {noms} = même main et même finesse pour un adulte du jeu (à NE PAS copier : autre visage, "
		"autre tenue)") if ancres else ""
	return MODELE_MARCHE.format(ident=ident, ref=ref, tenue=tenue) + INTERDITS_PNJ + "\n"


def images() -> list[dict]:
	"""Toutes les images de la série : nom, fichier de prompt, texte, jointes (chemins), priorité."""
	liste = []
	for ident, num, fr, en, _h, prio, sujet in ESPECES:
		for r in (1, 2, 3):
			jointes = [str(OFFICIEL / f"{num}.png"), str(ANGLE)] if r < 3 else []
			liste.append({"nom": f"DOS_{ident}_r{r}", "fichier": PROMPTS / f"DOS_{ident}_r{r}.txt",
				"texte": DOS.format(nom=DOS_NOM[r].format(fr=fr, en=en, num=num), ancres=DOS_ANCRES[r],
					sujet=sujet, fin=FIN_DETOURE), "jointes": jointes, "priorite": prio, "repli": r > 1})
	for ident, prio, role, tenue, pose, ancres in PERSONNAGES:
		nom = f"{ident}_NE_r1"
		liste.append({"nom": nom, "fichier": PROMPTS / f"{nom}.txt",
			"texte": _prompt_marche(ident, tenue, ancres),
			"jointes": [str(HEROS)] + [str(PERSOS / a) for a in ancres], "priorite": 2 if prio == 1 else prio,
			"repli": False})
		court = ident.removeprefix("PNJ_")
		liste.append({"nom": f"{court}_ATTENTE_r1", "fichier": ATTENTES / f"{court}_ATTENTE.txt",
			"texte": _prompt_attente(ident, role, tenue, pose), "jointes": [str(ART / f"{nom}.png")],
			"priorite": 2 if prio == 1 else prio, "repli": False})
	for cle, d in DECORS_COMBAT.items():
		ident = f"COMBAT_DECOR_{cle}_r1"
		jointes = [str(REFERENCE / "combat-v1.webp"), str(REFERENCE / "combat-decors-planche-v1.webp")]
		if d["ref"]:
			jointes.append(str(ART / f"{d['ref']}.png"))
		compo = COMPOSITION.format(lieu_compo=d["lieu_compo"], ya=d["ya"])
		liste.append({"nom": ident, "fichier": PROMPTS_DECOR / f"{ident}.txt",
			"texte": DECOR.format(titre=d["titre"], image3=d["image3"], lieu=d["lieu"], compo=compo,
				lumiere=d["lumiere"], rendu=RENDU_DECOR, interdits=d["interdits"]),
			"jointes": jointes, "priorite": 3, "repli": False})
		for cote in ("TL", "TR"):
			liste.append({"nom": f"{ident}_{cote}", "fichier": PROMPTS_DECOR / f"COMBAT_DECOR_TUILE_{cle}_r1.txt",
				"texte": TUILE.format(quoi=d["tuile"]), "jointes": [str(ART / f"{ident}_crop{cote}.png")],
				"priorite": 3, "repli": False})
	# Compagnon d'Évoli (si budget) : planche 4 × 4 du monde, gabarit de serie14_pokemon.
	liste.append({"nom": "POKE_EVOLI_NE_r1", "fichier": PROMPTS / "POKE_EVOLI_NE_r1.txt",
		"texte": _prompt_compagnon_evoli(), "jointes": [str(HEROS), str(PRINCIPAL / "POKE_RATTATA_P2_r1.png")],
		"priorite": 5, "repli": False})
	return liste


## Compagnon d'Évoli : hauteur en jeu par défaut 56 px (règle 4 ; Rattata 56, Miaouss 64).
EVOLI_HAUTEUR = 56


def _prompt_compagnon_evoli() -> str:
	import serie14_pokemon as s14  # noqa: E402
	entree = ("POKE_EVOLI", EVOLI_HAUTEUR, "POKE_RATTATA_P2_r1.png",
		"petit mammifère quadrupède brun-roux chaud, fidèle à son design officiel : grande collerette "
		"de fourrure crème duveteuse autour du cou, très grandes oreilles pointues brunes dressées, "
		"grands yeux bruns, petit museau, queue touffue et large, brune avec le bout crème, relevée en "
		"panache. Allure curieuse et affectueuse.",
		"trotte à quatre pattes en 4 images, petits pas légers, oreilles et queue qui rebondissent", False)
	if not any(e[0] == "POKE_EVOLI" for e in s14.SERIE):
		s14.SERIE.append(entree)
	return s14.prompt("POKE_EVOLI")


def prompts() -> None:
	for im in images():
		_ecrire(im["fichier"], im["texte"])
	print(len(images()), "images, prompts écrits")


def refs() -> None:
	vue = Image.open(VUE).convert("RGB")
	for nom, boite in REFS.items():
		im = vue.crop(boite)
		k = min(3, 1536 / max(im.size))
		im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
		im.save(ART / f"{nom}.png")
		print(ART / f"{nom}.png", im.size)


def commandes() -> None:
	for im in sorted(images(), key=lambda i: i["priorite"]):
		print(f"# P{im['priorite']}{' (repli)' if im['repli'] else ''}")
		print("tools/art/generer.sh %s %s %s" % (im["nom"], im["fichier"].relative_to(RACINE),
			" ".join(im["jointes"])))


def _lancer(nom: str) -> str:
	im = next(i for i in images() if i["nom"] == nom)
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	r = subprocess.run([str(ICI / "generer.sh"), nom, str(im["fichier"]), *im["jointes"]],
		cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if r.returncode == 0 else 'ÉCHEC ' + r.stderr.strip()[-300:]}"


def generer(noms: list[str]) -> None:
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(_lancer, noms):
			print(ligne, flush=True)


# --- Décors : tuiles et master -----------------------------------------------------------
TAILLE_DECOR = (2340, 1080)


def portions(largeur: int, hauteur: int) -> list[list[int]]:
	w = round(hauteur * 1000 / 852)
	return [[0, 0, w, hauteur], [largeur - w, 0, largeur, hauteur]]


def tuiles(essai: str) -> None:
	comp = Image.open(ART / f"{essai}.png").convert("RGB")
	for cote, p in zip(("TL", "TR"), portions(*comp.size)):
		comp.crop(p).save(ART / f"{essai}_crop{cote}.png")
		print(cote, p, comp.size)


def entree_decor(essai: str) -> dict:
	comp = Image.open(ART / f"{essai}.png")
	tl, tr = portions(*comp.size)
	return {"composition": f"{essai}.png",
		"tuiles": [{"image": f"{essai}_TL.png", "portion": tl}, {"image": f"{essai}_TR.png", "portion": tr}],
		"taille": list(TAILLE_DECOR), "qualite": 90}


def decor(essai: str, sortie: str) -> None:
	import preparer_decor  # noqa: E402
	preparer_decor.ART = str(ART)
	entree = entree_decor(essai)
	fond, _ = preparer_decor.master(entree, TAILLE_DECOR)
	SORTIE.mkdir(parents=True, exist_ok=True)
	fond.save(SORTIE / f"{sortie}_back.png")
	fond.save(SORTIE / f"{sortie}_back.webp", "WEBP", quality=90, method=6)
	print(json.dumps(entree, ensure_ascii=False))


def decor_brut(essai: str, sortie: str) -> None:
	"""Repli sans tuiles : composition seule agrandie à 2340 × 1080 (aperçu, pas un master)."""
	SORTIE.mkdir(parents=True, exist_ok=True)
	im = Image.open(ART / f"{essai}.png").convert("RGB").resize(TAILLE_DECOR, Image.LANCZOS)
	im.save(SORTIE / f"{sortie}_back_apercu.png")


# --- Détourage ------------------------------------------------------------------------
def _recadrer(im: Image.Image, seuil: int = 8) -> Image.Image:
	boite = im.getchannel("A").point(lambda a: 255 if a > seuil else 0).getbbox()
	return im.crop(boite) if boite else im


def _poser(sujet: Image.Image, cote: int, utile: int, bas: int) -> Image.Image:
	k = min(utile / sujet.width, utile / sujet.height)
	s = sujet.resize((round(sujet.width * k), round(sujet.height * k)), Image.LANCZOS)
	out = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
	out.alpha_composite(s, ((cote - s.width) // 2, cote - bas - s.height))
	return out


def detourer() -> None:
	"""Dos retenus → $ART/serie22/dos_ia_NNN.png (format de dos_ia_093) ; PNJ → planches de jeu."""
	SORTIE.mkdir(parents=True, exist_ok=True)
	for ident, num, *_ in ESPECES:
		essai = RETENUS.get(f"DOS_{ident}")
		if not essai:
			continue
		dos = _recadrer(Image.open(ART / f"{essai}.png").convert("RGBA"))
		_poser(dos, 1024, 870, 120).save(SORTIE / f"dos_ia_{num}.png")
		print("dos", ident, essai)
	for ident, *_ in PERSONNAGES:
		court = ident.removeprefix("PNJ_").lower()
		marche, attente = RETENUS.get(ident), RETENUS.get(f"{ident}_ATTENTE")
		if not marche:
			continue
		planche = SORTIE / f"{court}_sheet.png"
		subprocess.run([sys.executable, str(ICI / "decouper_perso.py"), str(ART / f"{marche}.png"),
			str(planche), "--hauteur", "128"], check=True)
		if attente:
			subprocess.run([sys.executable, str(ICI / "decouper_attente.py"), str(ART / f"{attente}.png"),
				str(planche), str(SORTIE / f"{court}_idle_sheet.png")], check=True)
		print("pnj", ident, marche, attente)
	if RETENUS.get("POKE_EVOLI"):
		subprocess.run([sys.executable, str(ICI / "decouper_perso.py"), str(ART / f"{RETENUS['POKE_EVOLI']}.png"),
			str(SORTIE / "evoli_sheet.png"), "--hauteur", str(EVOLI_HAUTEUR)], check=True)
		print("compagnon evoli", RETENUS["POKE_EVOLI"])


# --- Planches de contact --------------------------------------------------------------
PLAYER_FEET = (-0.42, 0.90)
FOE_FEET = (0.36, 0.50)
PRESENCE = {True: 0.31, False: 0.27}
MAX_BOX = {True: (0.80, 0.40), False: (0.50, 0.38)}


def _echelle(box, hauteur_m: float, joueur: bool, vue_h: float) -> float:
	ratio = min(max(math.pow(max(hauteur_m, 0.05) / 0.6, 0.4), 0.73), 1.73)
	limite = (MAX_BOX[joueur][0] * vue_h, MAX_BOX[joueur][1] * vue_h)
	return min(PRESENCE[joueur] * ratio * vue_h / math.sqrt(box[0] * box[1]),
		limite[0] / box[0], limite[1] / box[1])


def _placer(fond: Image.Image, image: Image.Image, hauteur_m: float, joueur: bool) -> None:
	im = _recadrer(image.convert("RGBA"), 16)
	w, h = fond.size
	ancre = PLAYER_FEET if joueur else FOE_FEET
	pieds = (w / 2 + ancre[0] * h, ancre[1] * h)
	k = _echelle(im.size, hauteur_m, joueur, h)
	s = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
	ombre = Image.new("RGBA", fond.size, (0, 0, 0, 0))
	rx, ry = s.width * 0.36, s.width * 0.07
	ImageDraw.Draw(ombre).ellipse((pieds[0] - rx, pieds[1] - ry, pieds[0] + rx, pieds[1] + ry),
		fill=(20, 20, 30, 110))
	fond.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(6)))
	fond.alpha_composite(s, (round(pieds[0] - s.width / 2), round(pieds[1] - s.height)))


def _police(taille: int) -> ImageFont.ImageFont:
	for c in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(c).exists():
			return ImageFont.truetype(c, taille)
	return ImageFont.load_default()


def _fond_decor(nom: str) -> Image.Image:
	for chemin in (SORTIE / f"{nom}_back.png", SORTIE / f"{nom}_back_apercu.png"):
		if chemin.exists():
			return Image.open(chemin).convert("RGBA")
	return Image.open(DECORS / "route_5_6_prairie_back.webp").convert("RGBA")


def contact_combat(sortie: Path) -> None:
	"""Chaque dos retenu, en bas à gauche, face à l'artwork officiel de la même espèce, aux règles
	de BattleLayout, sur le décor de sa zone ; écran S24 (2340 × 1080) réduit de moitié."""
	zone = {"EVOLI": "route_7_8_urbaine", "CANINOS": "route_7_8_urbaine", "GOUPIX": "route_7_8_urbaine",
		"ARCANIN": "route_7_8_urbaine", "FEUNARD": "route_7_8_urbaine", "EMPIFLOR": "celadon_gym_serre",
		"RAFFLESIA": "celadon_gym_serre", "AQUALI": "rocket_hideout_repaire",
		"VOLTALI": "rocket_hideout_repaire", "PYROLI": "rocket_hideout_repaire",
		"OSSELAIT": "rocket_hideout_repaire"}
	panneaux = []
	for ident, num, fr, _en, h, _p, _s in ESPECES:
		dos = SORTIE / f"dos_ia_{num}.png"
		if not dos.exists():
			continue
		fond = _fond_decor(zone[ident])
		_placer(fond, Image.open(OFFICIEL / f"{num}.png"), h, False)
		_placer(fond, Image.open(dos), h, True)
		fond = fond.resize((1170, 540), Image.LANCZOS)
		ImageDraw.Draw(fond).text((16, 12), f"{fr} ({num}, {h} m) — dos IA provisoire / face officielle",
			fill="white", font=_police(22), stroke_width=2, stroke_fill="black")
		panneaux.append(fond)
	if not panneaux:
		print("aucun dos retenu")
		return
	col = 2
	lig = (len(panneaux) + col - 1) // col
	pl = Image.new("RGB", (col * 1170 + 30, lig * 550 + 10), (24, 24, 30))
	for i, p in enumerate(panneaux):
		pl.paste(p.convert("RGB"), (10 + (i % col) * 1180, 10 + (i // col) * 550))
	pl.save(sortie)
	print(sortie, pl.size)


def contact_pnj(sortie: Path) -> None:
	"""Planches découpées (1re image de chaque direction + attente) à 1:1 (1 case = 96 px) à côté du
	héros et de PNJ existants ; deuxième fichier zoomé × 2."""
	reperes = [("heros", PERSOS / "heros_sheet.png", PERSOS / "heros_idle_sheet.png"),
		("ondine", PERSOS / "ondine_sheet.png", PERSOS / "ondine_idle_sheet.png"),
		("sbire_h", PERSOS / "sbire_h_sheet.png", PERSOS / "sbire_h_idle_sheet.png")]
	lignes = list(reperes)
	for ident, *_ in PERSONNAGES:
		court = ident.removeprefix("PNJ_").lower()
		if (SORTIE / f"{court}_sheet.png").exists():
			lignes.append((court, SORTIE / f"{court}_sheet.png", SORTIE / f"{court}_idle_sheet.png"))
	if (SORTIE / "evoli_sheet.png").exists():
		lignes += [("rattata (repère)", RACINE / "assets/sprites/pokemon/painted/rattata_sheet.png", Path("-")),
			("evoli (compagnon)", SORTIE / "evoli_sheet.png", Path("-"))]
	case = 96
	larg, haut = 9 * case, 2 * case
	toile = Image.new("RGBA", (larg * 2, haut * ((len(lignes) + 1) // 2)), (96, 140, 70, 255))
	d = ImageDraw.Draw(toile)
	for x in range(0, toile.width, case):
		d.line([(x, 0), (x, toile.height)], fill=(84, 126, 60, 255))
	for y in range(0, toile.height, case):
		d.line([(0, y), (toile.width, y)], fill=(84, 126, 60, 255))
	for i, (nom, marche, attente) in enumerate(lignes):
		ox, oy = (i % 2) * larg, (i // 2) * haut
		d.text((ox + 4, oy + 2), nom, fill="white", font=_police(14))
		m = Image.open(marche).convert("RGBA")
		cw, ch = m.width // 4, m.height // 4
		poses = [m.crop((0, r * ch, cw, (r + 1) * ch)) for r in range(4)]
		if attente.exists():
			a = Image.open(attente).convert("RGBA")
			poses += [a.crop((k * a.width // 4, 0, (k + 1) * a.width // 4, a.height)) for k in range(4)]
		for k, p in enumerate(poses):
			x = ox + 8 + k * 105 + (case - p.width) // 2
			toile.alpha_composite(p, (x, oy + haut - 20 - p.height))
	toile.save(f"{sortie}_1x.png")
	toile.resize((toile.width * 2, toile.height * 2), Image.LANCZOS).save(f"{sortie}_2x.png")
	print(f"{sortie}_1x.png", toile.size)


def contact_decors(sortie: Path) -> None:
	noms = [d["sortie"] for d in DECORS_COMBAT.values()]
	fonds = [(n, _fond_decor(n)) for n in noms if any((SORTIE / f"{n}_back{s}.png").exists()
		for s in ("", "_apercu"))]
	if not fonds:
		return
	pl = Image.new("RGB", (1170 + 20, len(fonds) * 550 + 10), (24, 24, 30))
	for i, (n, f) in enumerate(fonds):
		f = f.copy()
		_placer(f, Image.open(OFFICIEL / "133.png"), 0.3, False)
		evoli = SORTIE / "dos_ia_133.png"
		_placer(f, Image.open(evoli if evoli.exists() else PROTO / "dos_ia_025.png"), 0.4, True)
		f = f.resize((1170, 540), Image.LANCZOS)
		ImageDraw.Draw(f).text((16, 12), n, fill="white", font=_police(24), stroke_width=2, stroke_fill="black")
		pl.paste(f.convert("RGB"), (10, 10 + i * 550))
	pl.save(sortie)
	print(sortie, pl.size)


def kit(sortie: Path) -> None:
	"""Planche du kit : faces officielles des 16 espèces (avec la nature du dos prévue) et PNJ
	réutilisés, à côté des nouveaux (cases vides étiquetées)."""
	especes = [(n, f) for n, f in [("CANINOS", "058"), ("ARCANIN", "059"), ("GOUPIX", "037"),
		("FEUNARD", "038"), ("EVOLI", "133"), ("AQUALI", "134"), ("VOLTALI", "135"), ("PYROLI", "136"),
		("EMPIFLOR", "071"), ("RAFFLESIA", "045"), ("SAQUEDENEU", "114"), ("RHINOCORNE", "111"),
		("KANGOUREX", "115"), ("FANTOMINUS", "092"), ("SPECTRUM", "093"), ("OSSELAIT", "104")]]
	dos = {"SAQUEDENEU": "provisoire pixel (T7)", "RHINOCORNE": "provisoire pixel (T7)",
		"KANGOUREX": "provisoire pixel (T7)", "FANTOMINUS": "J19 (dos_ia_092)", "SPECTRUM": "existant (dos_ia_093)"}
	f = _police(16)
	pl = Image.new("RGB", (8 * 220 + 20, 2 * 250 + 330), (30, 32, 38))
	d = ImageDraw.Draw(pl)
	for i, (nom, num) in enumerate(especes):
		x, y = 10 + (i % 8) * 220, 10 + (i // 8) * 250
		im = _recadrer(Image.open(OFFICIEL / f"{num}.png").convert("RGBA"))
		im.thumbnail((190, 190), Image.LANCZOS)
		pl.paste(im, (x + (200 - im.width) // 2, y + 195 - im.height), im)
		d.text((x, y + 200), f"{num} {nom}", fill="white", font=f)
		d.text((x, y + 220), "dos : " + dos.get(nom, "Codex (série 22)"), fill=(200, 200, 140), font=f)
	y0 = 2 * 250 + 20
	d.text((10, y0), "PNJ réutilisés : parieur (J17, « Joueur »), dresseuse (Jeune Dresseuse), fillette, "
		"sbire_h / sbire_f, jardinière, vieil homme, vieille dame…", fill="white", font=f)
	reuse = ["dresseuse_sheet.png", "fillette_sheet.png", "sbire_h_sheet.png", "sbire_f_sheet.png",
		"vieil_homme_sheet.png", "vieille_dame_sheet.png"]
	for k, nom in enumerate(reuse):
		m = Image.open(PERSOS / nom).convert("RGBA")
		p = m.crop((0, 0, m.width // 4, m.height // 4))
		pl.paste(p, (10 + k * 110, y0 + 30 + 160 - p.height), p)
	d.text((700, y0 + 40), "Nouveaux : Erika, Giovanni, Rocket en civil, Intello, Beauté, Topdresseuse\n"
		"(marche 4 × 4 + attente, 128 px)\nDécors CB.3 : route_7_8_urbaine, celadon_gym_serre, "
		"rocket_hideout_repaire", fill=(200, 200, 140), font=f)
	pl.save(sortie)
	print(sortie, pl.size)


def main() -> None:
	args = sys.argv[1:]
	ART.mkdir(parents=True, exist_ok=True)
	if not args or args[0] == "--prompts":
		prompts()
	elif args[0] == "--refs":
		refs()
	elif args[0] == "--commandes":
		commandes()
	elif args[0] == "--generer":
		generer(args[1:])
	elif args[0] == "--tuiles":
		tuiles(args[1])
	elif args[0] == "--decor":
		decor(args[1], args[2])
	elif args[0] == "--decor-brut":
		decor_brut(args[1], args[2])
	elif args[0] == "--detourer":
		detourer()
	elif args[0] == "--contact":
		contact_combat(ART / "SERIE22_CONTACT_COMBAT_v1.png")
		contact_pnj(ART / "SERIE22_CONTACT_PNJ_v1")
		contact_decors(ART / "SERIE22_CONTACT_DECORS_v1.png")
	elif args[0] == "--kit":
		kit(ART / "J20_KIT_v1.png")
	else:
		sys.exit(__doc__)


if __name__ == "__main__":
	main()
