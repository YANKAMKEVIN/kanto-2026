#!/usr/bin/env python3
"""Série 21 — Route 9, Route 10, Grotte Sombre, Lavanville et Tour Pokémon (jalon 18, lumière neutre).
Plan : docs/tech/jalon-18.md §4.18, T1 ; fiche : docs/design/fiches-assets/serie-21-j18.md ;
conception : docs/design/dossier-21-grotte-sombre-lavanville.md (§3–7, §10.4, §13.1).

**Numéro 21** : 17 = J15, 18 réservé au J16, 19 = J17 (`origin/jalon-17`), 20 = J19 (`origin/jalon-19`),
constaté le 2026-10-15 sur toutes les branches `origin/*`. À revérifier au push.

Méthode des J8–J17 (consigne de Kevin : le plus petit kit modulaire qui donne la sensation des vues
validées ; **la grille fait foi** : `tools/plans/route_9.txt`, `route_10.txt`, `grotte_sombre_1f.txt`,
`grotte_sombre_b1f.txt`, `lavanville.txt`, `tour_pokemon_rdc.txt`). Vues validées :
`docs/design/reference/{route-9,route-10,grotte-sombre,lavanville}-vue-generale-v1.png`,
`grotte-sombre-etude-halo-v1.png` ; la vue des étages de la Tour (J19, `origin/jalon-19`) sert de
référence de famille pour l'intérieur (tombes, bougeoirs, dalles).

Réutilisé (fiche, section A) : forêt, herbe, chemin, hautes herbes, sol rocheux, parois beiges de la
série 12 (`relief_paroi_01..04`), falaise basse, rebords, rochers, Centre, Boutique, coques
d'intérieur, eau de canal et berges (série 15), gravats et échelles (série 14), lampes de chantier,
bancs, panneaux, bouches de grotte beiges de la série 19 (J17), personnages, fonds de combat (déjà
intégrés au J18, `a7b309a5`). Générées (16 images, 2 vagues) :
  - Grotte Sombre : sol, dessus des masses (textures), planche des parois (6 modules), planche des
    repères (paroi fendue, racines ×2, rochers ×2), grande colonne, flaque ;
  - Route 10 : centrale lointaine, silhouette lointaine de la Tour (vague 2) ;
  - Lavanville : pavés (texture), Tour Pokémon (extérieur 12 × 11), Maison des Pokémon, maison
    d'habitants (maisons 1 et 2), planche des haies, fleurs pâles et ifs ;
  - Tour (intérieur, **mutualisé avec les étages du J19**) : dalles (texture), planche des murs
    (5 modules + escalier montant), planche des meubles (tombes ×3, bougeoir, comptoir, banc).
CONDITIONNELS (jamais lancés sans leur nom) : WORLD_RELIEF_BOUCHE_GROTTE_SOMBRE_01 (si la bouche de
la série 19 manque ou ne se lit pas), WORLD_BLDG_MAISON_LAVANVILLE_02 (si les maisons 1 et 2 se
répètent), WORLD_RELIEF_TERRASSE_PLANCHE (si parois et falaise basse ne font pas les terrasses de la
Route 9), INT_TOUR_RDC_COQUE (si le rez-de-chaussée est construit en pièce peinte et non en modules).

Lumière : NEUTRE pour tout. La Grotte Sombre est peinte claire et lisible (le voile d'obscurité, le
halo et les profils `cave_*` font le noir : jamais de pénombre peinte) ; la Tour est peinte en lumière
neutre (profil `tower_cold` et halos `candle` du jeu) ; Lavanville en lumière neutre (profil
`lavender`, aucune brume peinte).

**Ancres = assets préparés du dépôt** (chemins `assets/...`, toujours présents) : la génération ne
dépend d'aucune image brute d'une autre copie. Références recadrées `REF_*` dans $ART (`--refs`).

**Règle de Kevin pour Codex** (série 19) : AVEC les images jointes d'abord (2 essais), puis SANS pièce
jointe (2 essais) ; chaque refus est consigné dans `$ART/refus_serie21.log`.

Usage :
  tools/art/serie21.py --prompts               écrit les fichiers de prompt (sans Codex)
  tools/art/serie21.py --refs                  recadre les REF_R9_*, REF_R10_*, REF_GS_*, REF_LA_*, REF_TP_*
  tools/art/serie21.py --commandes             liste les commandes generer.sh (sans Codex)
  tools/art/serie21.py --planche [sortie.png]  planche de contrôle du kit (défaut build/art/J18_KIT_v1.png)
  tools/art/serie21.py --contact [sortie.png]  planche de contact des images générées (T2)
  tools/art/serie21.py --manifeste             ajoute les entrées en fin de manifeste.json (T6 ;
                                               NE PAS lancer avant la validation des images)
  tools/art/serie21.py --controle [sortie.png] planche des assets PRÉPARÉS à l'échelle du jeu (T6)
  tools/art/serie21.py [IDENTIFIANT ...]       génère avec Codex, par vagues (sans argument : la
                                               série sans les conditionnels ; --refs d'abord)
"""
from __future__ import annotations

import json
import os
import subprocess
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


ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART

REFERENCE = RACINE / "docs/design/reference"
## Vues validées. La vue des étages de la Tour est sur `origin/jalon-19` (validée le 2026-10-15) :
## lue depuis git si le fichier n'est pas dans la copie (`_vue`).
VUES = {
	"R9": "route-9-vue-generale-v1.png",  # 1536 × 1024
	"R10": "route-10-vue-generale-v1.png",  # 1024 × 1536
	"GS": "grotte-sombre-vue-generale-v1.png",  # 1024 × 1536 (1F en haut, B1F en bas), r3 validée
	"HA": "grotte-sombre-etude-halo-v1.png",  # 1536 × 1024 (sans Flash | avec Flash)
	"LA": "lavanville-vue-generale-v1.png",  # 1536 × 1024
	"TP": "tour-pokemon-vue-generale-v1.png",  # 1024 × 1536, J19 (étages 2F–6F)
}
BRANCHE_TP = "origin/jalon-19"
## Pixels de la vue par case du jeu (la vue n'est pas à l'échelle exacte de la grille : estimé sur
## les bâtiments et les sentiers) ; sert seulement à la planche de contrôle.
PX_CASE = {"R9": 19.0, "R10": 21.0, "GS": 24.0, "HA": 64.0, "LA": 30.0, "TP": 22.0}
PROMPTS = ICI / "prompts" / "serie21"

## Recadrages des vues validées : (vue, boîte en pixels de la vue). Agrandis × 3 au plus, sans
## dépasser 1 536 px. Boîtes recalées à l'œil sur les vues (T1, 2026-10-15).
REFS = {
	# Route 9
	"REF_R9_FALAISE": ("R9", (300, 0, 1536, 300)),
	"REF_R9_TERRASSE": ("R9", (470, 190, 960, 310)),
	"REF_R9_TERRASSE_EST": ("R9", (1170, 395, 1510, 560)),
	"REF_R9_VALLON": ("R9", (530, 370, 910, 690)),
	# Route 10
	"REF_R10_BOUCHE_N": ("R10", (455, 85, 560, 175)),
	"REF_R10_BOUCHE_S": ("R10", (300, 770, 430, 870)),
	"REF_R10_FALAISE": ("R10", (0, 530, 645, 860)),
	"REF_R10_CENTRALE": ("R10", (715, 15, 830, 185)),
	"REF_R10_RIVIERE": ("R10", (630, 280, 800, 720)),
	"REF_R10_TOUR": ("R10", (290, 1260, 470, 1536)),
	# Grotte Sombre
	"REF_GS_SOL": ("GS", (360, 930, 600, 1010)),
	"REF_GS_MASSE": ("GS", (20, 380, 240, 640)),
	"REF_GS_PAROI": ("GS", (440, 640, 700, 760)),
	"REF_GS_ANGLE": ("GS", (190, 680, 380, 810)),
	"REF_GS_COLONNE": ("GS", (410, 1000, 560, 1170)),
	"REF_GS_FLAQUE": ("GS", (395, 1290, 560, 1405)),
	"REF_GS_RACINES": ("GS", (690, 1130, 900, 1390)),
	"REF_GS_FENTE": ("GS", (600, 820, 720, 950)),
	"REF_GS_ROCHERS": ("GS", (340, 960, 600, 1200)),
	"REF_GS_B1F": ("GS", (290, 820, 930, 1470)),
	"REF_HA_FLASH": ("HA", (770, 0, 1536, 1024)),
	# Lavanville
	"REF_LA_TOUR": ("LA", (925, 0, 1295, 305)),
	"REF_LA_FUJI": ("LA", (475, 110, 700, 295)),
	"REF_LA_MAISON": ("LA", (275, 135, 460, 295)),
	"REF_LA_MAISON_ARDOISE": ("LA", (1135, 450, 1335, 620)),
	"REF_LA_PAVES": ("LA", (740, 600, 850, 1024)),
	"REF_LA_RUE": ("LA", (290, 290, 760, 385)),
	"REF_LA_HAIES": ("LA", (270, 365, 760, 420)),
	"REF_LA_SQUARE": ("LA", (830, 680, 1340, 960)),
	"REF_LA_PARVIS": ("LA", (940, 180, 1300, 330)),
	# Tour Pokémon (étages du J19 : même famille que le rez-de-chaussée)
	"REF_TP_SALLE": ("TP", (60, 150, 500, 470)),
	"REF_TP_TOMBES": ("TP", (280, 210, 420, 310)),
	"REF_TP_BOUGIES": ("TP", (140, 375, 420, 445)),
	"REF_TP_MURS": ("TP", (60, 520, 500, 940)),
}
AGRANDIR = 3
REF_MAX = 1536

# --- Ancres (assets préparés du dépôt, toujours présents) -------------------------------

_W = "assets/world/"
_C = "assets/sprites/characters/painted/"
STYLE = [f"{_W}props/prop_souche_01.png", f"{_W}props/tree_a_01.png"]
SOL_GROTTE = f"{_W}ground/ground_grotte_01.png"  # série 14 (gris bleuté : à ne pas copier)
GRAVATS = f"{_W}ground/ground_gravats_01.png"  # série 14 (brun : repris tel quel)
MASSE_ROCHE = f"{_W}ground/ground_masse_roche_01.png"  # série 14
PAROI_GROTTE = [f"{_W}relief/relief_paroi_grotte_0{i}.png" for i in (1, 3, 5)]  # gabarit des rôles
COLONNE_MS = f"{_W}props/prop_colonne_grotte_01.png"  # série 14
MARE = f"{_W}props/prop_mare_grotte_01.png"  # série 14
RACINES = f"{_W}props/prop_racines_01.png"
ROCHER_GROTTE = f"{_W}props/prop_rocher_grotte_01.png"
ECHELLE = f"{_W}props/prop_echelle_descend_01.png"
PAROI_BEIGE = [f"{_W}relief/relief_paroi_01.png", f"{_W}relief/relief_paroi_04.png"]  # série 12
ENTREE_GROTTE = f"{_W}relief/relief_entree_grotte_01.png"  # série 14
MAISON_ARGENTA = f"{_W}buildings/bldg_maison_argenta_01.png"
MAISON_PECHEUR = f"{_W}buildings/bldg_maison_pecheur_01.png"
CENTRE = f"{_W}buildings/bldg_centre_01.png"
MUSEE = f"{_W}buildings/bldg_musee_argenta_01.png"
ARENE_AZURIA = f"{_W}buildings/bldg_arene_azuria_01.png"
POSTE = f"{_W}buildings/bldg_poste_safrania_01.png"
VUE_PORT = f"{_W}props/prop_vue_port_01.png"  # modèle d'un élément lointain (série 17)
PAVE = f"{_W}ground/ground_paves_01.png"
DALLES_SO = f"{_W}ground/ground_dalles_souterrain_01.png"  # série 17
MURS_SO = [f"{_W}relief/relief_mur_souterrain_0{i}.png" for i in (1, 3, 4)]  # gabarit des rôles
ESCALIER_SO = f"{_W}props/prop_escalier_souterrain_monte_01.png"
STELE = f"{_W}props/prop_stele_01.png"
BANC_SO = f"{_W}props/prop_banc_souterrain_01.png"
APPLIQUE = f"{_W}props/prop_applique_01.png"
COMPTOIR = f"{_W}interiors/int_comptoir_pension_01.png"
HAIE = f"{_W}props/prop_haie_01.png"
BUISSON = f"{_W}props/prop_buisson_a_01.png"
PLATEBANDE = f"{_W}props/prop_platebande_01.png"
FALAISE = f"{_W}relief/relief_falaise_01.png"
REBORD = f"{_W}relief/relief_rebord_01.png"
SOL_ROCHE = f"{_W}ground/ground_roche_01.png"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, inscription sur les tombes, AUCUN "
	"emblème rond de type balle (ni cercle partagé en deux, ni médaillon à bande centrale) sauf sur le "
	"Centre et la Boutique existants, animaux réels ou faune non-Pokémon (oiseaux, chauves-souris, "
	"insectes, araignées), Pikachu et tout Pokémon non demandé, personnage qui ressemble au héros "
	"(casquette rouge, t-shirt blanc, sac à dos jaune), squelette, crâne, fantôme, toile d'araignée, "
	"élément effrayant ou macabre, croix religieuse.")

VALEURS_GROTTE_SOMBRE = ("VALEURS DE LA GROTTE SOMBRE (exception de palette à l'ADN : un sous-sol de "
	"terre et de roche brune, humide et un peu froid) : brun chocolat, brun ocre, terre de Sienne "
	"ombrée, beige argileux, quelques reflets humides gris-bleu très discrets ; lumière NEUTRE, diffuse "
	"et blanche, venant légèrement du haut à gauche, aucune teinte dorée ni orangée. TRÈS IMPORTANT : "
	"le jeu ajoute lui-même l'obscurité (un voile sombre percé d'un halo autour du joueur) et la "
	"lumière des lampes : peins l'élément CLAIR ET LISIBLE comme en plein jour, NI pénombre, NI "
	"vignettage, NI flaque de lumière, NI halo, NI rayon. La lisibilité est DANS LA VALEUR PEINTE : "
	"le sol praticable est CLAIR (luminosité environ 60 à 72 %), les faces verticales de paroi sont "
	"moyennes (35 à 45 %), le dessus des masses rocheuses est SOMBRE (18 à 26 %) ; rapport de "
	"luminosité entre le sol et le dessus des masses d'au moins 2,5. Aucune ombre portée peinte.")

VALEURS_TOUR = ("VALEURS DE LA TOUR POKÉMON (exception de palette à l'ADN : un lieu de mémoire calme et "
	"digne) : pierre de taille gris perle, gris violacé doux, lavande désaturée, bois sombre, touches "
	"de crème et de vert tendre (fleurs) ; lumière NEUTRE, diffuse et blanche (le jeu ajoute la lumière "
	"froide du lieu et la lueur des bougies : ne peins NI pénombre, NI flaque de lumière, NI halo, NI "
	"brume) ; contraste doux, aucune ombre portée. Rien d'inquiétant : ni spectre, ni crâne, ni "
	"toile d'araignée, ni fissure menaçante.")

VALEURS_LAVANVILLE = ("VALEURS DE LAVANVILLE (exception de palette à l'ADN : la ville la plus calme de "
	"Kanto, mélancolique et respectueuse) : gris violacé, beige rosé, crème, vert sauge désaturé, "
	"prune doux, ardoise ; lumière NEUTRE de milieu de journée, diffuse et blanche (le jeu ajoute son "
	"étalonnage froid et violet léger : ne peins NI brume, NI crépuscule, NI fenêtre éclairée) ; "
	"contraste doux, aucune ombre portée.")

# --- Tables ------------------------------------------------------------------------------

## Textures de sol (opaques, raccordables) : (identifiant, référence, description, ancres,
## valeurs, vague).
SOLS = [
	("WORLD_GROUND_GROTTE_SOMBRE_01", "REF_GS_SOL",
		"texture du SOL PRATICABLE de la Grotte Sombre (couloirs et salles calmes, sans rencontre) : "
		"terre argileuse battue et tassée, beige ocre clair à beige rosé, le sol LE PLUS CLAIR de la "
		"grotte (luminosité environ 60 à 72 %), surface légèrement humide : quelques très fines zones "
		"plus sombres et satinées comme de la terre encore un peu mouillée, minuscules graviers bruns "
		"isolés, rares petits cailloux, poussière fine ; plus chaud et plus terreux que le sol de grotte "
		"gris bleuté joint (à ne pas copier), nettement plus clair et plus lisse que les gravats bruns "
		"joints (ne pas copier les cailloux) ; aucune flaque, aucun tas, aucune empreinte, aucune "
		"racine, aucun gros rocher.",
		[SOL_GROTTE, GRAVATS], VALEURS_GROTTE_SOMBRE, 1),
	("WORLD_GROUND_MASSE_GROTTE_SOMBRE_01", "REF_GS_MASSE",
		"texture du DESSUS DES MASSES ROCHEUSES de la Grotte Sombre (cases de paroi vues de dessus, "
		"infranchissables) : gros BLOCS ARRONDIS et facettés de roche brun chocolat et brun-rouge "
		"sombre vus de dessus, entassés serrés comme dans la référence jointe, arêtes à peine plus "
		"claires, quelques reflets humides discrets, creux brun très sombre entre les blocs, de très "
		"rares fines racines brunes qui serpentent entre deux blocs ; se lit comme une masse pleine et "
		"inaccessible ; luminosité environ 18 à 26 % (nettement plus sombre que le sol de la grotte, "
		"rapport d'au moins 2,5) mais jamais noire ; même grain que la masse grise jointe (à ne pas "
		"copier en couleur) ; aucune mousse verte, aucun cristal, aucune lumière.",
		[MASSE_ROCHE], VALEURS_GROTTE_SOMBRE, 1),
	("WORLD_GROUND_PAVES_LAVANVILLE_01", "REF_LA_PAVES",
		"texture des RUES PAVÉES de Lavanville, vue strictement de dessus : petits PAVÉS RECTANGULAIRES "
		"de pierre GRIS VIOLACÉ clair (gris lilas, gris perle, quelques pavés un peu plus rosés ou plus "
		"bleutés), posés en rangées HORIZONTALES décalées comme un appareil de briques (environ 4 pavés "
		"par case en largeur et 6 rangées par case, 1 case = 256 px sur cette texture), joints fins "
		"gris plus sombres, arêtes douces, très légère patine ; propre, calme, bien entretenu ; plus "
		"petit, plus régulier et plus froid que le pavé beige joint (à ne pas copier) ; aucune flaque, "
		"aucune mousse, aucune fleur, aucun élément remarquable.",
		[PAVE], VALEURS_LAVANVILLE, 1),
	("WORLD_GROUND_DALLES_TOUR_01", "REF_TP_SALLE",
		"texture du SOL DE LA TOUR POKÉMON (rez-de-chaussée et étages) : grandes DALLES CARRÉES de "
		"pierre gris perle légèrement violacé (environ une case chacune, 1 case = 256 px sur cette "
		"texture), posées droites en quadrillage régulier, joints fins gris plus sombres, surface "
		"polie par les pas, très fines nuances d'une dalle à l'autre (gris perle, gris lavande, gris "
		"chaud), un léger voile d'usure ; ancienne, propre et digne ; plus régulière, plus grande et "
		"plus froide que les dalles beiges du souterrain jointes (à ne pas copier) ; aucune fissure "
		"marquée, aucune fleur, aucune bougie, aucune inscription, aucun motif central.",
		[DALLES_SO], VALEURS_TOUR, 1),
]

## Décors isolés : (identifiant, référence, largeur en cases, hauteur visée en cases, description,
## ancres supplémentaires, valeurs, vague).
SERIE = [
	("WORLD_BLDG_TOUR_POKEMON_01", "REF_LA_TOUR", 12, 11,
		"la TOUR POKÉMON de Lavanville, extérieur, façade de face : le plus haut bâtiment de la ville, "
		"un mémorial de pierre HAUT, DIGNE et CALME (pas une église, pas un château hanté) ; base de 12 "
		"cases de large, environ 11 cases de haut en tout (la tour est vue en trois quarts de dessus : "
		"on voit la façade et les toits qui montent par étages) ; reproduire la vue jointe en plus net. "
		"Pierre de taille GRIS VIOLACÉ clair en assises régulières, toits d'ardoise VIOLET-GRIS sombre à "
		"pans raides, un CORPS CENTRAL qui s'élève en trois étages en retrait, coiffé d'un toit pointu "
		"sobre (sans croix, sans flèche gothique dentelée), deux ailes basses de chaque côté ; fenêtres "
		"hautes et étroites en arc, aux vitraux UNIS gris-bleu pâle (non éclairés, sans motif) ; au "
		"MILIEU exact du bas (6e et 7e colonnes sur 12), une PORTE DOUBLE de bois sombre sous un arc de "
		"pierre, deux marches basses ; corniches simples, contreforts discrets. Sans arbre, sans "
		"massif, sans haie, sans personnage, sans panneau, sans emblème, aucune inscription, aucune "
		"gargouille, aucun élément effrayant.",
		[MUSEE, ARENE_AZURIA], VALEURS_LAVANVILLE, 1),
	("WORLD_BLDG_MAISON_POKEMON_01", "REF_LA_FUJI", 8, 7,
		"la MAISON DES POKÉMON de Lavanville (la maison de M. Fuji, où il recueille des Pokémon "
		"seuls), façade de face (base de 8 cases de large, environ 7 cases de haut avec le toit), même "
		"main et même gabarit que la maison jointe WORLD_BLDG_MAISON_ARGENTA_01 mais plus large et plus "
		"accueillante : grand toit à deux pans de TUILES PRUNE-ROSÉ désaturé (vieux rose éteint), "
		"murs crépis CRÈME, soubassement de pierre grise ; au milieu exact du bas (4e et 5e colonnes "
		"sur 8), une PORTE DOUBLE de bois brun moyen, ouverte d'un battant, sous un petit auvent ; deux "
		"fenêtres à petits carreaux de chaque côté avec des jardinières de fleurs BLANCHES et MAUVE "
		"PÂLE ; une petite gamelle et un panier en osier près de la porte (seul indice des Pokémon). "
		"Sans clôture, sans jardin, sans arbre, sans panneau, sans Pokémon, aucune inscription.",
		[MAISON_ARGENTA], VALEURS_LAVANVILLE, 1),
	("WORLD_BLDG_MAISON_LAVANVILLE_01", "REF_LA_MAISON", 7, 6,
		"une MAISON D'HABITANTS de Lavanville, façade de face (base de 7 cases de large, environ 6 "
		"cases de haut avec le toit), même main et même gabarit que la maison jointe "
		"WORLD_BLDG_MAISON_ARGENTA_01 : toit simple à deux pans de TUILES BRUN GRIS (taupe, un peu "
		"violacé), petite cheminée de pierre grise, murs crépis CRÈME rosé, soubassement de pierre "
		"grise ; au milieu exact du bas (4e colonne sur 7), une PORTE de bois brun sombre d'une case "
		"sans auvent ; une fenêtre de chaque côté avec une jardinière de fleurs blanches ; sobre, "
		"soignée, un peu mélancolique. La même image sert deux fois (une en miroir) : aucun détail "
		"remarquable d'un seul côté. Sans clôture, sans arbre, sans panneau, aucune inscription.",
		[MAISON_ARGENTA, MAISON_PECHEUR], VALEURS_LAVANVILLE, 1),
	("WORLD_BLDG_CENTRALE_LOINTAINE_01", "REF_R10_CENTRALE", 5, 7,
		"la CENTRALE ÉLECTRIQUE vue DE LOIN, au-delà de la rivière de la Route 10 (on ne s'en approche "
		"jamais) : un bâtiment industriel ancien, bloc de béton et de brique GRIS-BLEU, toit plat, "
		"une haute CHEMINÉE cylindrique de brique sombre qui dépasse à droite, quelques fenêtres "
		"hautes et sombres, un petit transformateur à isolateurs sur le toit ; AUCUNE porte visible "
		"(façade tournée de trois quarts, côté aveugle), aucun éclair, aucune lumière, aucune fumée ; "
		"plus PETIT, plus PÂLE, plus bleuté et moins contrasté qu'un bâtiment au premier plan (c'est "
		"loin, au-delà de l'eau), même main que la vue lointaine jointe prop_vue_port_01 ; 5 cases de "
		"large, environ 7 de haut avec la cheminée. Le BAS est coupé net par une ligne horizontale "
		"(les arbres du jeu recouvrent le pied). Aucune inscription, aucun panneau.",
		[VUE_PORT, POSTE], LUMIERE_NE, 1),
	("WORLD_PROP_GRANDE_COLONNE_01", "REF_GS_COLONNE", 5, "5,5",
		"la GRANDE COLONNE de roche au centre du B1F de la Grotte Sombre (le repère principal, qu'on "
		"contourne et qu'on retrouve) : un énorme pilier naturel de roche brun chocolat, massif et "
		"facetté, qui part du sol et monte vers le plafond (vu de dessus en trois quarts : on voit son "
		"sommet coupé net en haut de l'image, comme s'il continuait dans le noir), 5 cases de large à "
		"la base et environ 5,5 cases de haut ; quelques blocs tombés à son pied, une ou deux fines "
		"racines qui descendent le long de sa face, reflets humides discrets ; même main que la "
		"colonne grise jointe (à ne pas copier en couleur) et que la référence jointe. Aucune "
		"lumière, aucun cristal, aucune mousse verte.",
		[COLONNE_MS, MASSE_ROCHE], VALEURS_GROTTE_SOMBRE, 2),
	("WORLD_PROP_FLAQUE_GROTTE_01", "REF_GS_FLAQUE", 8, 4,
		"la FLAQUE du B1F de la Grotte Sombre (repère : eau peu profonde, on ne la traverse pas), vue "
		"de dessus, À PLAT au niveau du sol : une nappe d'eau calme RECTANGULAIRE aux angles arrondis, "
		"de 8 cases de large et 4 de profondeur ; eau peu profonde et transparente bleu-vert sombre "
		"(on devine le fond de terre brune et quelques cailloux au bord, plus sombre au centre), "
		"petites vaguelettes claires peintes en touches, une ou deux gouttes en cercles ; un bord de "
		"terre brune humide et de petits cailloux bruns tout autour, un peu irrégulier (pas de "
		"margelle de pierre taillée) ; même main que la mare jointe (à ne pas copier : plus grande, "
		"plus brune, moins profonde). Aucune plante, aucun Pokémon, aucune lumière qui sort de l'eau.",
		[MARE, GRAVATS], VALEURS_GROTTE_SOMBRE, 2),
]

## Images de la vague 1 jointes aux images de la vague 2 (même matière, raccord exact).
TOUR_V1 = "WORLD_BLDG_TOUR_POKEMON_01_NE_r1.png"
SOL_GS_V1 = "WORLD_GROUND_GROTTE_SOMBRE_01_NE_r1.png"
MASSE_GS_V1 = "WORLD_GROUND_MASSE_GROTTE_SOMBRE_01_NE_r1.png"
PAROI_GS_V1 = "WORLD_RELIEF_PAROI_GROTTE_SOMBRE_PLANCHE_NE_r1.png"
DALLES_TP_V1 = "WORLD_GROUND_DALLES_TOUR_01_NE_r1.png"
MAISON_LA_V1 = "WORLD_BLDG_MAISON_LAVANVILLE_01_NE_r1.png"
VAGUE1 = {
	"WORLD_PROP_GRANDE_COLONNE_01": [PAROI_GS_V1, MASSE_GS_V1, SOL_GS_V1],
	"WORLD_PROP_FLAQUE_GROTTE_01": [SOL_GS_V1],
	"WORLD_PROP_TOUR_LOINTAINE_01": [TOUR_V1],
	"WORLD_PROP_GROTTE_SOMBRE_PLANCHE": [PAROI_GS_V1, SOL_GS_V1],
	"WORLD_RELIEF_MUR_TOUR_PLANCHE": [DALLES_TP_V1],
	"INT_TOUR_PLANCHE": [DALLES_TP_V1],
	"WORLD_BLDG_MAISON_LAVANVILLE_02": [MAISON_LA_V1],
}
SERIE_VAGUE2 = [
	("WORLD_PROP_TOUR_LOINTAINE_01", "REF_R10_TOUR", 5, 6,
		"la SILHOUETTE LOINTAINE de la Tour Pokémon, vue depuis la Route 10 sud au-dessus de la forêt "
		"(le repère qu'on découvre en sortant de la Grotte Sombre) : EXACTEMENT la tour jointe "
		f"{Path(TOUR_V1).stem} (mêmes toits, même pierre, mêmes fenêtres), mais seulement son CORPS "
		"CENTRAL et ses étages hauts, vus de loin : plus petite, plus pâle, plus bleutée et moins "
		"contrastée (lointain), 5 cases de large, environ 6 de haut ; le BAS est COUPÉ NET par une "
		"ligne horizontale droite (les arbres du jeu recouvrent cette ligne) ; rien en dessous, "
		"transparence totale. Aucune brume peinte, aucun arbre, aucun oiseau.",
		[VUE_PORT], LUMIERE_NE, 2),
]

## Conditionnels (mêmes champs que SERIE, vague 3).
SERIE_COND = [
	("WORLD_RELIEF_BOUCHE_GROTTE_SOMBRE_01", "REF_R10_BOUCHE_N", 4, 3,
		"une BOUCHE de la Grotte Sombre sur la Route 10 : un module de PAROI de 4 cases de large et 3 "
		"de haut, de la même roche beige en colonnes moussues et de la même hauteur que les modules "
		"joints relief_paroi_01 et relief_paroi_04 (il se raccorde à gauche et à droite), percé au "
		"MILIEU de son bas d'une OUVERTURE en arc de 2 cases de large et environ 1,5 case de haut, "
		"brun-bleu très sombre à l'intérieur (jamais noire), coiffée d'un linteau naturel de gros "
		"blocs, un seuil de terre claire au pied ; reproduire la bouche de la vue jointe (plus nette), "
		"même main que l'entrée d'ardoise jointe (sœur, ici en roche beige). Aucun étai, aucune "
		"marche, aucun escalier, aucune porte, aucune grille, aucun panneau, aucune lanterne.",
		[*PAROI_BEIGE, ENTREE_GROTTE], LUMIERE_NE),
	("WORLD_BLDG_MAISON_LAVANVILLE_02", "REF_LA_MAISON_ARDOISE", 7, 6,
		"une seconde MAISON D'HABITANTS de Lavanville, façade de face (base de 7 cases de large, "
		"environ 6 de haut), même main et même gabarit que la maison jointe WORLD_BLDG_MAISON_"
		"LAVANVILLE_01 (porte au milieu exact du bas, 4e colonne sur 7) mais toit d'ARDOISE GRIS-BLEU, "
		"murs crème, jardinières de fleurs mauve pâle, une lucarne. Aucune inscription.",
		[MAISON_ARGENTA], VALEURS_LAVANVILLE),
]

## Planches : (identifiant, références, description, ancres, valeurs, vague).
_CELLULES = ("dans une image 1536 × 1024 : grille invisible de 3 colonnes × 2 lignes (cellules de "
	"512 × 512), un élément par cellule, centré, la base de chacun sur une même ligne horizontale à 40 "
	"px du bas de sa cellule")
PLANCHES = [
	("WORLD_RELIEF_PAROI_GROTTE_SOMBRE_PLANCHE", ["REF_GS_PAROI", "REF_GS_ANGLE", "REF_GS_B1F"],
		f"PLANCHE de 6 modules de PAROI de la Grotte Sombre (les bords des masses rocheuses qui "
		f"entourent les galeries), {_CELLULES}, à une échelle COMMUNE : 1 case = 150 px. Roche BRUN "
		"CHOCOLAT humide en gros blocs arrondis et facettés (comme la vue jointe) : le DESSUS des "
		"masses est sombre (comme la texture jointe de masse), les FACES verticales sont moyennes, "
		"blocs empilés avec quelques reflets humides, une arête plus claire en haut et un pied de "
		"terre beige clair qui touche le sol (le sol n'est PAS dessiné) ; çà et là une fine racine "
		"brune qui sort d'un joint. MÊMES rôles, MÊMES découpes et même manière de peindre que les "
		"modules gris joints relief_paroi_grotte_01, _03 et _05 (gabarit : ici la roche brune et "
		"humide remplace l'ardoise froide).\n"
		"1 (ligne 1, à gauche) : FACE A, bord SUD d'une masse vu de face, 3 cases de large × 2 de haut : "
		"en haut une bande du dessus sombre, puis l'arête claire, puis la face verticale ; bord bas "
		"droit et net. 2 (ligne 1, au milieu) : FACE B, identique en hauteur, une fissure verticale et "
		"deux ou trois blocs tombés au pied ; 1 et 2 se raccordent bout à bout par leurs bords gauche et "
		"droit. 3 (ligne 1, à droite) : ANGLE SAILLANT, 2 cases × 2 : l'extrémité gauche d'une face, "
		"qui tourne vers le haut de l'image et devient un bord latéral. 4 (ligne 2, à gauche) : ANGLE "
		"RENTRANT, 2 cases × 2 : le coin intérieur d'une salle, où un bord latéral (à gauche) rejoint "
		"une face (en haut). 5 (ligne 2, au milieu) : BORD LATÉRAL, bande VERTICALE d'une case de large "
		"et 3 de haut : le côté gauche ou droit d'une masse vu de dessus, une arête claire et une mince "
		"bande de face. 6 (ligne 2, à droite) : LÈVRE NORD, bande HORIZONTALE de 3 cases de large et "
		"une de haut : le bord d'une masse située au sud d'un couloir, vu de dessus, juste une arête "
		"claire légèrement en surplomb, sans face visible.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[*PAROI_GROTTE, MASSE_ROCHE], VALEURS_GROTTE_SOMBRE, 1),
	("WORLD_PROP_GROTTE_SOMBRE_PLANCHE", ["REF_GS_FENTE", "REF_GS_RACINES", "REF_GS_ROCHERS"],
		f"PLANCHE de 5 REPÈRES de la Grotte Sombre, {_CELLULES}, à une échelle COMMUNE : 1 case = "
		"150 px ; même roche brun chocolat humide que la planche de parois jointe "
		"WORLD_RELIEF_PAROI_GROTTE_SOMBRE_PLANCHE_NE_r1 (même main, même angle).\n"
		"1 (ligne 1, à gauche) : PAROI FENDUE, un module de FACE de paroi de 3 cases de large × 2 de "
		"haut (exactement le gabarit de la face A jointe), fendu au MILIEU par une haute FISSURE "
		"verticale étroite (environ un tiers de case de large) par laquelle on aperçoit un mince filet "
		"de CIEL PÂLE gris-bleu et une feuille verte (la fissure monte jusqu'à la surface) : le ciel "
		"est peint dans sa propre couleur, SANS rayon, SANS halo, SANS lueur autour ; de la mousse "
		"vert sombre et quelques gouttes humides au bord de la fente.\n"
		"2 (ligne 1, au milieu) : RACINES A, des racines d'arbre brunes, noueuses et ramifiées qui "
		"PERCENT LE PLAFOND et descendent en rideau le long d'une paroi jusqu'au sol (on est sous la "
		"forêt), quelques radicelles pendantes, un peu de terre accrochée ; 1 case de large × environ 2 "
		"de haut ; plus sombres, plus fines et plus pendantes que la souche moussue jointe "
		"prop_racines_01 (à ne pas copier : aucune mousse vert vif).\n"
		"3 (ligne 1, à droite) : RACINES B, même famille, plus large : un faisceau de racines qui "
		"s'étale en éventail et touche le sol par trois pointes ; 2 cases de large × environ 2 de haut.\n"
		"4 (ligne 2, à gauche) : ROCHER A, un rocher isolé de la grotte, roche brune facettée, "
		"humide, 1 case (≈ 150 px), environ 0,8 case de haut ; même forme que le rocher gris joint "
		"prop_rocher_grotte_01 mais en roche brune. 5 (ligne 2, au milieu) : ROCHER B, un rocher plus "
		"bas et plus long, deux blocs serrés, 1 case, environ 0,6 de haut. (ligne 2, à droite) : "
		"cellule VIDE.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune ombre portée.",
		[*PAROI_GROTTE[:1], RACINES, ROCHER_GROTTE, MASSE_ROCHE], VALEURS_GROTTE_SOMBRE, 2),
	("WORLD_PROP_LAVANVILLE_PLANCHE", ["REF_LA_HAIES", "REF_LA_SQUARE", "REF_LA_PARVIS"],
		f"PLANCHE de 6 ÉLÉMENTS de jardin de Lavanville (haies taillées, fleurs pâles), {_CELLULES}, à "
		"une échelle COMMUNE de 1 case = 150 px, tous vus de dessus en trois quarts ; même main que "
		"la haie, le buisson et la plate-bande joints, mais d'un vert SAUGE plus sombre et plus "
		"désaturé, et des fleurs PÂLES (blanc, crème, lavande, mauve très pâle), jamais vives.\n"
		"1 (ligne 1, à gauche) : BUIS TAILLÉ A, une boule de buis taillée bien ronde et dense, vert "
		"sauge sombre, 1 case de large (≈ 150 px), environ 1 case de haut ; posée au sol sans pot, "
		"juxtaposable en rangées (comme la vue jointe). 2 (ligne 1, au milieu) : BUIS TAILLÉ B, même "
		"boule un peu plus haute et légèrement ovale, 1 case. 3 (ligne 1, à droite) : HAIE TAILLÉE, un "
		"bloc de haie de buis basse et carrée, coins arrondis, 2 cases de large × environ 1 de haut, "
		"qui se raccorde bout à bout par ses bords gauche et droit.\n"
		"4 (ligne 2, à gauche) : MASSIF PÂLE A, un petit parterre carré de fleurs blanches et lavande "
		"(marguerites, petites campanules) dans un feuillage sauge, à ras du sol, 1 case. 5 (ligne 2, "
		"au milieu) : MASSIF PÂLE B, un parterre rectangulaire de 2 cases × 1 de fleurs blanches, "
		"crème et mauve pâle, bordé d'une fine bordure de pierre grise. 6 (ligne 2, à droite) : IF "
		"TAILLÉ, un petit conifère taillé en cône, vert sombre, sobre et digne (à poser de part et "
		"d'autre de la porte de la Tour), 1 case de large, environ 1,8 case de haut.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune herbe autour, aucune "
		"ombre portée.",
		[HAIE, BUISSON, PLATEBANDE], VALEURS_LAVANVILLE, 1),
	("WORLD_RELIEF_MUR_TOUR_PLANCHE", ["REF_TP_MURS", "REF_TP_SALLE"],
		f"PLANCHE de 6 MODULES DE MUR de l'intérieur de la Tour Pokémon (rez-de-chaussée et étages), "
		f"{_CELLULES}, à une échelle COMMUNE : 1 case = 150 px, tous vus de dessus en trois quarts. "
		"Matière : PIERRE DE TAILLE gris perle légèrement violacé en assises régulières, joints fins, "
		"couronnement de grandes dalles plus claires, plinthe un peu plus sombre au pied ; murs "
		"épais, sobres, anciens et propres ; même famille que la référence jointe (les murs des "
		"étages) et MÊMES rôles, même manière que les modules du souterrain joints "
		"relief_mur_souterrain_01, _03 et _04 (gabarit : ici la pierre gris perle de la Tour) ; "
		"ANGLES DROITS : chaque module est un rectangle net qui se raccorde bout à bout.\n"
		"1 (ligne 1, à gauche) : FACE A, un mur vu de face (le sol est au SUD), 2 cases de large × 2 de "
		"haut : en haut le couronnement vu de dessus, puis la face de pierre de taille, puis la "
		"plinthe ; bord bas droit et net. 2 (ligne 1, au milieu) : FACE B, même gabarit, avec une "
		"petite NICHE vide en arc au milieu (sans statue, sans bougie, sans inscription) ; 1 et 2 se "
		"raccordent bout à bout. 3 (ligne 1, à droite) : COURONNEMENT, le dessus d'un mur dont le sol "
		"est au NORD : une bande HORIZONTALE de dalles claires vue de dessus, 2 cases × environ 0,4, "
		"sans face visible.\n"
		"4 (ligne 2, à gauche) : BORD LATÉRAL, le côté d'un mur dont le sol est à DROITE : une bande "
		"VERTICALE de couronnement vu de dessus avec une mince bande de face, environ 0,35 case de "
		"large × 2 de haut. 5 (ligne 2, au milieu) : ANGLE, le coin d'un mur vu de dessus (un "
		"couronnement en équerre), environ 0,35 × 0,6 case. 6 (ligne 2, à droite) : ESCALIER MONTANT "
		"pris dans un mur, 1 case de large × 2 de haut, du même gabarit que la face A : une ouverture "
		"étroite en arc dans la face de pierre, des marches de pierre gris perle qui MONTENT vers le "
		"haut de l'image et disparaissent dans l'ombre douce de l'étage au-dessus (pas de noir "
		"total), une rampe de pierre de chaque côté.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dallé dessiné, aucune ombre portée.",
		[*MURS_SO, ESCALIER_SO], VALEURS_TOUR, 2),
	("INT_TOUR_PLANCHE", ["REF_TP_TOMBES", "REF_TP_BOUGIES"],
		f"PLANCHE de 6 ÉLÉMENTS de l'intérieur de la Tour Pokémon (lieu de mémoire des Pokémon "
		f"disparus, calme et doux), {_CELLULES}, à une échelle COMMUNE de 1 case = 120 px, tous vus de "
		"dessus en trois quarts ; même main que la stèle, le banc et le comptoir joints ; même famille "
		"que les tombes de la référence jointe (étages de la Tour).\n"
		"1 (ligne 1, à gauche) : TOMBE A, une petite tombe basse de Pokémon : stèle de pierre gris perle "
		"au sommet ARRONDI, posée sur un socle bas, face lisse SANS AUCUNE inscription ni symbole, 1 "
		"case de large (≈ 120 px), environ 1 case de haut. 2 (ligne 1, au milieu) : TOMBE B, la même "
		"stèle avec un petit BOUQUET de fleurs fraîches blanches et roses pâles posé à son pied et "
		"quelques pétales, 1 case. 3 (ligne 1, à droite) : TOMBE C, une stèle un peu plus ancienne, "
		"légèrement plus haute et plus étroite, pierre un peu plus chaude, un brin de lavande et un "
		"petit caillou posé dessus (offrande), 1 case.\n"
		"4 (ligne 2, à gauche) : BOUGEOIR, un socle de pierre carré bas qui porte un PHOTOPHORE de fer "
		"sombre à vitres avec une grosse bougie crème allumée à petite flamme peinte simplement (SANS "
		"halo ni lueur autour : le jeu ajoute la lumière), 1 case de large, environ 1,2 case de haut. "
		"5 (ligne 2, au milieu) : COMPTOIR D'ACCUEIL du gardien, un comptoir bas de bois sombre et "
		"de pierre, 4 cases de large × 1 (≈ 480 px), avec un registre ouvert, un vase de fleurs "
		"blanches et un petit présentoir de bougies éteintes ; sobre, sans clochette ni objet gai. "
		"6 (ligne 2, à droite) : BANC DE RECUEILLEMENT, un banc de bois sombre sans dossier sur pieds "
		"de pierre, 1 case de long, qui se juxtapose bout à bout par ses bords gauche et droit (les "
		"rangées de 2 et 3 bancs du jeu).\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol, aucune dalle, aucune ombre portée.",
		[STELE, BANC_SO, COMPTOIR, APPLIQUE], VALEURS_TOUR, 2),
]

## Planches conditionnelles (vague 3).
PLANCHES_COND = [
	("WORLD_RELIEF_TERRASSE_PLANCHE", ["REF_R9_TERRASSE", "REF_R9_TERRASSE_EST", "REF_R9_FALAISE"],
		f"PLANCHE de 6 modules de TERRASSE ROCHEUSE de la Route 9 (les rebords bas qui séparent deux "
		f"niveaux de sentier), {_CELLULES}, à une échelle COMMUNE : 1 case = 150 px. Roche beige en "
		"colonnes avec des touffes de mousse vert vif sur les replats, exactement la roche des modules "
		"joints relief_paroi_01 et relief_falaise_01, mais en rebords d'UNE case de haut : 1 FACE A "
		"(3 cases × 1), 2 FACE B (3 × 1, une fissure), 3 ANGLE SAILLANT (1 × 1), 4 ANGLE RENTRANT "
		"(1 × 1), 5 BORD LATÉRAL (0,4 × 3, bande verticale), 6 RAMPE (2 × 1,5 : la terre du sentier "
		"qui monte en pente douce le long d'un rebord, sans marches). Fond transparent, aucun sol "
		"herbeux dessiné, aucune ombre portée.",
		[*PAROI_BEIGE, FALAISE, REBORD], LUMIERE_NE),
]

## Coque conditionnelle (vague 3) : (identifiant, largeur, profondeur, ancres, géométrie, matériaux).
_BASE_COQUE = ("Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur "
	"en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur "
	"épaisseur vue de dessus ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue "
	"de dessus.")
COQUES_COND = [
	("INT_TOUR_RDC_COQUE", 20, 18, [DALLES_SO, f"{_W}interiors/int_musee_coque.png"],
		"Format : PNG carré 1024 × 1024, opaque ; la pièce fait 20 cases de large × 18 de profondeur "
		"(la préparation l'étire à 1 920 × 1 728 : 1 case = 96 px). " + _BASE_COQUE + " Face avant du "
		"mur du fond sur les 3 rangées du haut ; épaisseur des murs latéraux ≈ 1 case ; mur du bas sur "
		"les 2 rangées du bas, interrompu au milieu par l'ENTRÉE : une ouverture de 2 cases exactement "
		"centrée (9e et 10e colonnes), paillasson gris uni. Dans le mur du fond, à la 18e colonne, une "
		"ouverture d'UNE case où un ESCALIER de pierre monte vers l'étage. Tout le sol est en grandes "
		"dalles carrées gris perle, LIBRE et VIDE (aucune tombe, aucun meuble).",
		"le rez-de-chaussée de la Tour Pokémon, mémorial calme et digne : pierre de taille gris perle "
		"légèrement violacé, plinthes plus sombres, hautes fenêtres étroites en arc aux vitraux unis "
		"gris-bleu pâle dans le mur du fond (sans motif ni lumière), aucune inscription."),
]

# --- Prompts ----------------------------------------------------------------------------


def _noms(fichiers: list[str]) -> str:
	return ", ".join(Path(f).stem for f in fichiers)


def _jointes_refs(refs: list[str]) -> str:
	if not refs:
		return ""
	return (f"{', '.join(refs)} = forme, matériaux et couleurs, extraits des vues d'ensemble validées "
		"(minuscules, en lumière d'ambiance : n'en copie ni le rendu, ni la lumière, ni la pénombre) ; ")


def _serie(identifiant: str) -> str:
	"""Ligne des images de la vague 1 jointes (raccord exact avec ce qui est déjà validé)."""
	jointes = VAGUE1.get(identifiant)
	if not jointes:
		return ""
	return (f"\nImages de la série déjà générées et jointes : {_noms(jointes)} = MÊME matière, mêmes "
		"couleurs, même main, même échelle : l'élément doit s'y raccorder exactement.")


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
		"l'élément garde la lumière NEUTRE des ancres (le jeu ajoute la lumière lui-même)."
		+ _serie(identifiant))
	corps = (f"ASSET : {description}\nFormat : PNG paysage 1536 × 1024 (portrait 1024 × 1536 si "
		"l'élément est plus haut que large) ; l'élément occupe environ 1 300 px dans sa plus grande "
		f"dimension, centré. Échelle : {largeur} cases de large et environ {hauteur} de haut ; un adulte "
		f"mesure 1,33 case.\n{OBJET_FIN}\n{INTERDITS}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{valeurs}\n\n{corps}\n")


def _prompt_planche(identifiant: str, refs: list[str], description: str, ancres: list[str],
		valeurs: str) -> str:
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages "
		f"jointes : {_jointes_refs(refs)}{_noms(ancres)} = ancres de style (rendu peint, contour coloré, "
		f"finesse, angle de vue, lumière neutre) : respecte-les exactement.{_serie(identifiant)}\n\n"
		f"{ADN}\n{valeurs}\n\n"
		"EXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une même planche, chacun "
		f"entier dans sa cellule, sans cadre ni séparation.\n{description}\n{INTERDITS}\n")


def _prompt_coque(identifiant: str, geometrie: str, materiaux: str, ancres: list[str]) -> str:
	return (f"{identifiant} — NOUVELLE image : l'enveloppe d'une pièce intérieure de jeu (murs, sol, "
		f"fenêtres ; aucun meuble).\nImages jointes : {_noms(ancres)} = ancres de style des intérieurs "
		"(rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre) "
		"et matériaux : respecte-les exactement.\n\n"
		f"{ADN}\n{VALEURS_TOUR}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en "
		"trois quarts, image opaque qui remplit tout le cadre.\n"
		f"Géométrie (respecte-la exactement, c'est un plan de jeu) : {geometrie}\n"
		f"Pièce : {materiaux}\n"
		"Interdit : meubles, tombes, bougies, plantes, tapis (sauf le paillasson demandé), "
		"personnages, Pokémon (ni Pikachu), porte fermée, flaques de lumière peintes au sol, texte, "
		"lettres, chiffres, logo, emblème rond de type balle, perspective avec point de fuite, vue "
		"isométrique, ombre portée.\n")


def _images() -> list[dict]:
	"""Toutes les images de la série : nom (sans .png), fichier de prompt, texte, jointes (noms dans
	$ART, ou chemins relatifs à la racine quand ils contiennent « / »), vague, conditionnel, groupe."""
	images = []

	def ajouter(nom, texte, jointes, vague=1, conditionnel=False, groupe=None):
		images.append({"nom": nom, "fichier": PROMPTS / f"{nom}.txt", "texte": texte,
			"jointes": jointes, "vague": vague, "conditionnel": conditionnel,
			"groupe": groupe or nom.rsplit("_", 2)[0]})

	for ident, ref, description, ancres_, valeurs, vague in SOLS:
		ajouter(f"{ident}_NE_r1", _prompt_texture(ident, ref, description, ancres_, valeurs),
			[f"{ref}.png"] + STYLE + ancres_, vague, groupe=ident)
	for ident, ref, largeur, hauteur, description, ancres_, valeurs, vague in SERIE + SERIE_VAGUE2:
		jointes = [f"{ref}.png"] + STYLE + ancres_ + VAGUE1.get(ident, [])
		ajouter(f"{ident}_NE_r1", _prompt_objet(ident, ref, largeur, hauteur, description, ancres_,
			valeurs), jointes, vague, groupe=ident)
	for ident, ref, largeur, hauteur, description, ancres_, valeurs in SERIE_COND:
		ajouter(f"{ident}_NE_r1", _prompt_objet(ident, ref, largeur, hauteur, description, ancres_,
			valeurs), [f"{ref}.png"] + STYLE + ancres_ + VAGUE1.get(ident, []), 3, True, groupe=ident)
	for ident, refs, description, ancres_, valeurs, vague in PLANCHES:
		jointes = [f"{r}.png" for r in refs] + ancres_ + VAGUE1.get(ident, [])
		ajouter(f"{ident}_NE_r1", _prompt_planche(ident, refs, description, ancres_, valeurs),
			jointes, vague, groupe=ident)
	for ident, refs, description, ancres_, valeurs in PLANCHES_COND:
		ajouter(f"{ident}_NE_r1", _prompt_planche(ident, refs, description, ancres_, valeurs),
			[f"{r}.png" for r in refs] + ancres_, 3, True, groupe=ident)
	for ident, _largeur, _profondeur, ancres_, geometrie, materiaux in COQUES_COND:
		ajouter(f"{ident}_NE_r1", _prompt_coque(ident, geometrie, materiaux, ancres_), ancres_, 3,
			True, groupe=ident)
	for (ident, rev), description in CORRECTIONS.items():
		base = next((t for t in PLANCHES if t[0] == ident), None)
		if base is not None:
			_, refs, _, ancres_, valeurs, _ = base
			ajouter(f"{ident}_NE_r{rev}", _prompt_planche(ident, refs, description, ancres_, valeurs),
				[f"{r}.png" for r in refs] + ancres_, 3, True, groupe=f"{ident}_r{rev}")
			continue
		sol = next((t for t in SOLS if t[0] == ident), None)
		if sol is not None:
			_, ref, _, ancres_, valeurs, _ = sol
			ajouter(f"{ident}_NE_r{rev}", _prompt_texture(ident, ref, description, ancres_, valeurs),
				[f"{ref}.png"] + STYLE + ancres_, 3, True, groupe=f"{ident}_r{rev}")
			continue
		objet = next((t for t in SERIE + SERIE_VAGUE2 if t[0] == ident), None)
		if objet is not None:
			_, ref, largeur, hauteur, _, ancres_, valeurs, _ = objet
			precedent = f"{ident}_NE_r{rev - 1}.png"
			ajouter(f"{ident}_NE_r{rev}", _prompt_objet(ident, ref, largeur, hauteur, description,
				[precedent] + ancres_, valeurs), [f"{ref}.png", precedent] + STYLE + ancres_, 3, True,
				groupe=f"{ident}_r{rev}")
	return images


## Corrections (T2) : (identifiant sans _NE_rN, révision) → texte qui remplace la description
## d'origine (planche ou objet). Vide au T1.
CORRECTIONS: dict[tuple[str, int], str] = {
	("WORLD_GROUND_PAVES_LAVANVILLE_01", 2): (
		"texture des RUES PAVÉES de Lavanville, vue strictement de dessus : de vrais PAVÉS DE RUE "
		"en pierre de taille IRRÉGULIÈRE, légèrement arrondis aux angles (pas de rangs réguliers, "
		"pas de joints de maçonnerie, pas d'aspect de mur de briques), de tailles variées (environ "
		"3 à 5 pavés par case), gris violacé et beige usé, quelques pavés nettement plus sombres, "
		"séparés par des joints de terre sombre avec par endroits un fil d'herbe fine ; "
		"motif organique SANS répétition visible ; raccordable ; aucune flaque, aucune fleur, "
		"aucun élément remarquable."),
}


def ecrire_prompts() -> None:
	changes = 0
	images = _images()
	for image in images:
		fichier: Path = image["fichier"]
		fichier.parent.mkdir(parents=True, exist_ok=True)
		if not fichier.exists() or fichier.read_text() != image["texte"]:
			fichier.write_text(image["texte"])
			changes += 1
	print(f"{len(images)} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}")


# --- Références et génération ----------------------------------------------------------


def _vue(cle: str) -> Path:
	"""Chemin de la vue ; la vue de la Tour (J19) est extraite de `origin/jalon-19` si besoin."""
	chemin = REFERENCE / VUES[cle]
	if chemin.exists():
		return chemin
	copie = RACINE / "build" / "art" / "_vues" / VUES[cle]
	if not copie.exists():
		copie.parent.mkdir(parents=True, exist_ok=True)
		contenu = subprocess.run(["git", "show", f"{BRANCHE_TP}:docs/design/reference/{VUES[cle]}"],
			cwd=RACINE, capture_output=True, check=True).stdout
		copie.write_bytes(contenu)
	return copie


def _recadrage(nom: str) -> Image.Image:
	vue, boite = REFS[nom]
	return Image.open(_vue(vue)).convert("RGB").crop(boite)


def references(dossier: Path | None = None) -> None:
	dossier = dossier or ART
	dossier.mkdir(parents=True, exist_ok=True)
	for nom in REFS:
		ref = _recadrage(nom)
		facteur = min(AGRANDIR, REF_MAX / max(ref.size))
		if facteur != 1:
			ref = ref.resize((round(ref.width * facteur), round(ref.height * facteur)), Image.LANCZOS)
		ref.save(dossier / f"{nom}.png")
	print(f"{len(REFS)} références REF_* dans {dossier}")


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


JOURNAL_REFUS = "refus_serie21.log"
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
	(ESSAIS_SANS essais) ; chaque refus est consigné."""
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	texte = image["fichier"].read_text()
	jointes = [RACINE / j if "/" in j else ART / j for j in image["jointes"]]
	derniere = ""
	for essai in range(ESSAIS_AVEC):
		derniere = serie10._lancer(nom, texte, jointes)
		if derniere.endswith(": ok"):
			return derniere + (f" (essai {essai + 1} avec images)" if essai else "")
		_consigner(nom, f"refus ou échec AVEC images, essai {essai + 1} : {derniere[-160:]}")
	for essai in range(ESSAIS_SANS):
		derniere = serie10._lancer(nom, SANS_JOINTE + texte, [])
		if derniere.endswith(": ok"):
			_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + " (SANS pièce jointe)"
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


# --- Manifeste (T6) ---------------------------------------------------------------------


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


def _objet(ident: str, base: str, cases: float, dossier: str, ombre: bool = True,
		contact: float | None = 0.12) -> dict:
	return {"id": ident, "source": _revision(base), "sortie": f"{_W}{dossier}/{ident}.png", "axe": "w",
		"cases": cases, "ombre": ombre, "contact": contact}


def _sol(ident: str, base: str, contraste: float, couleur: float) -> dict:
	return {"id": ident, "source": _revision(base), "sortie": f"{_W}ground/{ident}.png", "taille": 384,
		"contraste": contraste, "couleur": couleur, "raccord": 24}


## Rôles des modules (fiche, § « Alignement ») ; ordre de lecture des planches.
PAROI_GS_IDS = [f"relief_paroi_grotte_sombre_0{i}" for i in range(1, 7)]
REPERES_GS_IDS = ["relief_paroi_fendue_01", "prop_racines_plafond_01", "prop_racines_plafond_02",
	"prop_rocher_grotte_sombre_01", "prop_rocher_grotte_sombre_02"]
LAVANVILLE_IDS = ["prop_buis_taille_01", "prop_buis_taille_02", "prop_haie_taillee_01",
	"prop_fleurs_pales_01", "prop_fleurs_pales_02", "prop_if_taille_01"]
MUR_TOUR_IDS = ["relief_mur_tour_01", "relief_mur_tour_02", "relief_mur_tour_03",
	"relief_mur_tour_04", "relief_mur_tour_05", "relief_escalier_tour_01"]
INT_TOUR_IDS = ["int_tombe_tour_01", "int_tombe_tour_02", "int_tombe_tour_03",
	"int_bougeoir_tour_01", "int_comptoir_tour_01", "int_banc_tour_01"]


def manifeste_donnees() -> dict:
	"""Entrées du manifeste (T6 seulement, en fin de chaque section). Réglages = défauts (règle 4),
	à ajuster au T6 sur la planche de contrôle. `cases` = largeur en cases de chaque élément."""
	return {
		"objets": [
			_objet("bldg_tour_pokemon_01", "WORLD_BLDG_TOUR_POKEMON_01_NE", 12, "buildings"),
			_objet("bldg_maison_pokemon_01", "WORLD_BLDG_MAISON_POKEMON_01_NE", 8, "buildings"),
			_objet("bldg_maison_lavanville_01", "WORLD_BLDG_MAISON_LAVANVILLE_01_NE", 7, "buildings"),
			# Lointains : sans ombre ni contact (posés au-dessus de la forêt / au-delà de l'eau).
			_objet("bldg_centrale_lointaine_01", "WORLD_BLDG_CENTRALE_LOINTAINE_01_NE", 5, "buildings",
				ombre=False, contact=None),
			_objet("prop_tour_lointaine_01", "WORLD_PROP_TOUR_LOINTAINE_01_NE", 5, "props",
				ombre=False, contact=None),
			_objet("prop_grande_colonne_01", "WORLD_PROP_GRANDE_COLONNE_01_NE", 5, "props",
				ombre=False, contact=0.15),
			# Flaque à plat (couche du sol, comme prop_mare_grotte_01).
			_objet("prop_flaque_grotte_01", "WORLD_PROP_FLAQUE_GROTTE_01_NE", 8, "props",
				ombre=False, contact=None),
		],
		"sols": [
			_sol("ground_grotte_sombre_01", "WORLD_GROUND_GROTTE_SOMBRE_01_NE", 0.6, 1.0),
			_sol("ground_masse_grotte_sombre_01", "WORLD_GROUND_MASSE_GROTTE_SOMBRE_01_NE", 0.6, 0.9),
			_sol("ground_paves_lavanville_01", "WORLD_GROUND_PAVES_LAVANVILLE_01_NE", 0.7, 1.0),
			_sol("ground_dalles_tour_01", "WORLD_GROUND_DALLES_TOUR_01_NE", 0.8, 1.0),
		],
		"planches_objets": [
			_planche_objets("WORLD_RELIEF_PAROI_GROTTE_SOMBRE_PLANCHE_NE", "relief", 3, 2,
				PAROI_GS_IDS, [3, 3, 2, 2, 1, 3], 0.0),
			_planche_objets("WORLD_PROP_GROTTE_SOMBRE_PLANCHE_NE", "props", 3, 2, REPERES_GS_IDS,
				[3, 1, 2, 1, 1], 0.15),
			_planche_objets("WORLD_PROP_LAVANVILLE_PLANCHE_NE", "props", 3, 2, LAVANVILLE_IDS,
				[1, 1, 2, 1, 2, 1], 0.2),
			_planche_objets("WORLD_RELIEF_MUR_TOUR_PLANCHE_NE", "relief", 3, 2, MUR_TOUR_IDS,
				[2, 2, 2, 0.35, 0.35, 1], 0.0),
			_planche_objets("INT_TOUR_PLANCHE_NE", "interiors", 3, 2, INT_TOUR_IDS,
				[1, 1, 1, 1, 4, 1], 0.2),
		],
	}


def _cle(entree: dict) -> str:
	return entree.get("id") or entree["source"]


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, par insertion de texte (comme les séries
	10 à 19) ; une section absente est créée en fin de fichier."""
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
	print(f"manifeste : {ajouts} entrée(s) de la série 21 ajoutée(s)")


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


def _sol_extrait(nom: str, role: str) -> tuple[Image.Image, str]:
	image = Image.open(RACINE / f"{_W}ground/{nom}.png").convert("RGBA").crop((0, 0, 192, 192))
	return (_echelle(image, 0.5), f"{nom}\n{role}")


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso(f"{_C}heros_sheet.png"), "héros (échelle)")
	w, c = _W, _C
	p = _Planche(2800, "Routes 9 et 10, Grotte Sombre, Lavanville, Tour Pokémon — kit de la série 21 "
		"(T1, jalon 18) : 1 case = 48 px ; héros à l'échelle")

	p.section("1. RÉUTILISÉS TELS QUELS — routes 9 et 10", [
		heros,
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt T") for i in (1, 4)],
		(_asset(f"{w}relief/relief_paroi_01.png"), "relief_paroi_01..04\nfalaises K (s. 12)"),
		(_asset(f"{w}relief/relief_paroi_04.png"), "paroi_04 : masse K"),
		(_asset(f"{w}relief/relief_paroi_03.png"), "paroi_03 : pente\n(rampe, bords)"),
		(_asset(f"{w}relief/relief_falaise_01.png"), "relief_falaise_01\nterrasses 1 rangée"),
		(_asset(f"{w}relief/relief_rebord_01.png"), "relief_rebord_01\nrebord v (64..67, 15)"),
		(_asset(f"{w}props/prop_rocher_01.png"), "rochers R"),
		(_asset(f"{w}props/prop_grande_pierre_01.png"), "grande pierre R"),
		(_asset(f"{w}props/prop_pierres_01.png"), "pierres (accents)"),
		(_asset(f"{w}props/prop_souche_01.png"), "souche"),
		(_asset(f"{w}props/prop_tronc_couche_01.png"), "tronc couché"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneaux ×3"),
		(_asset(f"{w}buildings/bldg_centre_01.png"), "Centre C (R10)"),
		(_asset(f"{w}relief/relief_berge_01.png"), "berges (s. 15)\nrivière w"),
		(_asset(f"{w}props/prop_jeune_arbre_arene_01.png"), "repli de l'arbre\nà couper (Azuria)"),
		*_si("assets/sprites/objects/painted/poke_ball_ground.png", "Poké Ball\nobjets"),
	], (40, 90, 50))
	p.section("1 bis. RÉUTILISÉS — Grotte Sombre, Lavanville, intérieurs", [
		heros,
		(_asset(f"{w}props/prop_echelle_descend_01.png"), "échelle V (1F)"),
		(_asset(f"{w}props/prop_echelle_monte_01.png"), "échelle U (B1F)"),
		(_asset(f"{w}props/prop_lampe_chantier_01.png"), "lampes ×3\n(+ LightGlow lamp)"),
		(_asset(f"{w}props/prop_indice_caillou_01.png"), "indice de l'objet\ncaché (43, 32)"),
		(_asset(f"{w}buildings/bldg_boutique_01.png"), "Boutique O"),
		(_asset(f"{w}props/prop_banc_01.png"), "bancs n"),
		(_asset(f"{w}props/tree_a_01.png"), "arbres repères G"),
		(_echelle(_asset(f"{w}interiors/int_centre_coque.png"), 0.4), "Centres ×2 (coque)"),
		(_echelle(_asset(f"{w}interiors/int_boutique_coque.png"), 0.4), "Boutique (coque)"),
		(_echelle(_asset(f"{w}interiors/int_maison_argenta_coque.png"), 0.4),
			"Maison des Pokémon,\nmaisons 1 et 2 (coque)"),
		(_asset(f"{w}interiors/int_panier_pokemon_01.png"), "panier (Maison\ndes Pokémon)"),
	], (40, 90, 50))
	p.section("1 ter. SOLS RÉUTILISÉS (extrait 2 × 2 cases)", [
		_sol_extrait("ground_herbe_01", "herbe ."), _sol_extrait("ground_chemin_01", "chemin ="),
		_sol_extrait("ground_roche_01", "sol rocheux o"),
		_sol_extrait("ground_eau_canal_01", "rivière w (s. 15)"),
		_sol_extrait("ground_gravats_01", "gravats g (s. 14)"),
		(_echelle(Image.open(RACINE / f"{w}ground/ground_hautes_herbes_jaune_01.png").convert("RGBA"),
			0.5), "hautes herbes h"),
	], (40, 90, 50))
	persos = [("pokemaniac", "pokemaniac (J18)"), ("exorciste", "channeler (J18)"),
		("montagnard", "mountaineer"), ("dresseuse", "lass"), ("campeur", "camper"),
		("scout", "scout"), ("vieil_homme", "old_man : gardien"), ("vieille_dame", "vieille dame"),
		("enfant", "kid"), ("fillette", "lass_young"), ("voyageur", "traveler")]
	p.section("1 quater. PERSONNAGES RÉUTILISÉS (aucun nouveau au T1)", [heros, *[x for nom, etiquette
		in persos for x in _si(f"{c}{nom}_sheet.png", etiquette, _cellule_perso)]], (40, 90, 50))

	p.section("2. VARIATIONS SANS NOUVEL ASSET", [
		(_miroir(_asset(f"{w}props/prop_jeune_arbre_arene_01.png")), "arbre à couper : J16\n(repli : jeune arbre)"),
		(_ref("REF_R10_FALAISE", hauteur=150), "bande centrale R10 :\nforêt + faces de paroi"),
		(_ref("REF_GS_SOL", hauteur=80), "entrées E / e : sol j +\npuits de jour + halo"),
		(_ref("REF_LA_SQUARE", hauteur=120), "forêt, pelouse : profil\nlavender (désaturé)"),
		(_asset(f"{w}props/prop_rocher_grotte_01.png"), "rochers o : s. 14\nsi les bruns manquent"),
	], (110, 90, 40))
	p.section("3. NOUVEAUX : GROTTE SOMBRE (référence recadrée à la taille en jeu)", [
		heros,
		(_ref("REF_GS_SOL", hauteur=96), "GROUND_GROTTE_SOMBRE_01\nsol ."),
		(_ref("REF_GS_MASSE", hauteur=96), "GROUND_MASSE_GROTTE\n_SOMBRE_01 (#)"),
		(_ref("REF_GS_PAROI", 3), "PAROI_GROTTE_SOMBRE\n_PLANCHE (6 modules)"),
		(_ref("REF_GS_COLONNE", 5.5), "GRANDE_COLONNE_01\n5 × 5,5 (K)"),
		(_ref("REF_GS_FLAQUE", 4), "FLAQUE_GROTTE_01\n8 × 4 (w), à plat"),
		(_ref("REF_GS_FENTE", 3), "GROTTE_SOMBRE_PLANCHE :\nparoi fendue f"),
		(_ref("REF_GS_RACINES", 3), "racines r ×2"),
	], (130, 70, 40))
	p.section("3 bis. NOUVEAUX : ROUTE 10 ET LAVANVILLE", [
		heros,
		(_ref("REF_R10_CENTRALE", 7), "CENTRALE_LOINTAINE_01\n5 × 7 (E)"),
		(_ref("REF_R10_TOUR", 6), "TOUR_LOINTAINE_01\n5 × 6 (v2)"),
		(_ref("REF_LA_TOUR", 11), "BLDG_TOUR_POKEMON_01\n12 × 11 (U)"),
		(_ref("REF_LA_FUJI", 7), "MAISON_POKEMON_01\n8 × 7 (F)"),
		(_ref("REF_LA_MAISON", 6), "MAISON_LAVANVILLE_01\n7 × 6 (m, N miroir)"),
		(_ref("REF_LA_PAVES", hauteur=200), "PAVES_LAVANVILLE_01\n(p)"),
		(_ref("REF_LA_HAIES", 2), "LAVANVILLE_PLANCHE :\nbuis, haie, fleurs, if"),
	], (130, 70, 40))
	p.section("3 ter. NOUVEAUX : TOUR (intérieur, mutualisé avec le J19)", [
		heros,
		(_ref("REF_TP_SALLE", hauteur=200), "DALLES_TOUR_01 +\nMUR_TOUR_PLANCHE"),
		(_ref("REF_TP_MURS", hauteur=200), "murs (6 modules\ndont l'escalier S)"),
		(_ref("REF_TP_TOMBES", 2), "INT_TOUR_PLANCHE :\ntombes ×3 (g)"),
		(_ref("REF_TP_BOUGIES", 1.5), "bougeoir (b), comptoir\n(W), banc (n)"),
	], (130, 70, 40))
	p.section("3 quater. CONDITIONNELS (prompts prêts, jamais lancés par défaut)", [
		(_ref("REF_R10_BOUCHE_N", 3), "BOUCHE_GROTTE_SOMBRE_01\n(si la bouche s. 19 manque)"),
		(_ref("REF_LA_MAISON_ARDOISE", 6), "MAISON_LAVANVILLE_02\n(si répétition)"),
		(_ref("REF_R9_TERRASSE", 2), "TERRASSE_PLANCHE\n(si parois insuffisantes)"),
		(_ref("REF_TP_SALLE", hauteur=150), "INT_TOUR_RDC_COQUE\n(si pièce peinte)"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts des vues, non reproduits)", [
		(_ref("REF_HA_FLASH", hauteur=150), "pénombre et halos peints\n(→ voile + LightGlow)"),
		(_ref("REF_LA_PARVIS", hauteur=120), "fenêtres éclairées, brume\n(→ profil lavender)"),
		(_ref("REF_R9_VALLON", hauteur=150), "palissade de rondins,\nbordures de galets"),
		(_ref("REF_GS_B1F", hauteur=180), "Onix, Nosferapti peints\n(Pokémon d'ambiance)"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


def contact(sortie: Path) -> Path:
	"""Planche de contact des images GÉNÉRÉES (T2) : la dernière révision présente de chaque image
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


def _present(relatif: str, etiquette: str) -> list:
	chemin = RACINE / relatif
	return [(Image.open(chemin).convert("RGBA"), etiquette)] if chemin.exists() else []


def controle(sortie: Path) -> Path:
	"""Planche de contrôle du T6 : les assets **préparés** (assets/), à 1:1 (1 case = 96 px)."""
	heros_feuille = Image.open(RACINE / f"{_C}heros_sheet.png").convert("RGBA")
	heros = (heros_feuille.crop((0, 0, heros_feuille.width // 4, heros_feuille.height // 4)),
		"héros 128 px")
	p = _Planche(6000, "Série 21 préparée (T6, jalon 18) : assets du jeu à 1:1, 1 case = 96 px ; "
		"héros à l'échelle")
	donnees = manifeste_donnees()
	p.section("1. PLANCHES DÉCOUPÉES", [heros, *[x for planche_ in donnees["planches_objets"]
		for ident in planche_["ids"] for x in _present(f"{planche_['dossier']}{ident}.png", ident)]],
		(60, 80, 110))
	p.section("2. BÂTIMENTS, REPÈRES, LOINTAINS", [heros, *[x for e in donnees["objets"]
		for x in _present(e["sortie"], e["id"])]], (130, 70, 40))
	p.section("3. SOLS (384 px)", [x for e in donnees["sols"] for x in _present(e["sortie"], e["id"])],
		(130, 100, 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	autres = [a for a in arguments if not a.startswith("--")]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--refs" in arguments:
		references(Path(autres[0]) if autres else None)
	elif "--commandes" in arguments:
		print(commandes())
	elif "--planche" in arguments:
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "J18_KIT_v1.png"))
	elif "--contact" in arguments:
		print(contact(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon18_assets" / "serie21_contact.png"))
	elif "--manifeste" in arguments:
		manifeste()
	elif "--controle" in arguments:
		print(controle(Path(autres[0]) if autres else
			RACINE / "build" / "captures" / "jalon18_assets" / "serie21_controle.png"))
	else:
		generer(set(arguments))
