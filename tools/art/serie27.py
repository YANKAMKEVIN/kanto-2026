#!/usr/bin/env python3
"""Série 27 — lot d'art 24.0 du jalon 24 (« Les Îles Écume et Artikodin » : Routes 19, 20, 21,
Îles Écume, Cramois'Île et son Labo). Fiche : docs/design/fiches-assets/serie-27-iles-ecume.md ;
conception : dossier 27 §5.4, §6.4, §7.1, §8.1, §9, §10.1, §14.4 ; plan `docs/tech/jalon-24.md`
§2.12 (T5).

**Numéro** : 27 (vérifié le 2026-10-19 sur toutes les branches distantes : séries 17 à 24 prises,
25 et 26 laissées aux J22 et J23, plus anciens). À revérifier au push (fiche, ce fichier,
`prompts/serie27/`, mentions des docs).

Ce que contient la série (SANS intégration : ni `assets/`, ni manifeste, ni `.tres`, ni
`combat_decors/decors.json`) :
  - SURF_MONTURE + HEROS_SURF : monture de Surf générique et joueur en Surf, 4 directions × 4 images ;
  - PNJ_NAGEUR_EAU + PNJ_NAGEUSE_EAU : les Nageurs du J13 dans l'eau (tête et épaules), 4 × 4 ;
  - PNJ_TOPDRESSEUR + PNJ_TOPDRESSEUSE : marche 4 × 4 ;
  - WORLD_PROP_FORCE_PLANCHE : rocher de Force, rocher tombé dans l'eau, trou, trou bouché ;
  - POKE_ARTIKODIN_MONDE : Artikodin posé dans le monde (respiration, souffle froid) ;
  - WORLD_GROUND_COURANT_01, WORLD_GROUND_EAU_GROTTE_01, WORLD_GROUND_GLACE_01 : textures ;
  - COMBAT_DECOR_MER_OUVERTE, COMBAT_DECOR_GROTTE_GLACEE (+ tuiles _TL / _TR, recette CB.3) ;
  - DOS_ARTIKODIN, DOS_KABUTO, DOS_AMONITA : dos de combat provisoires IA ;
  - INT_LABO_CRAMOIS_{HALL,RD,FOSSILES,REUNION}_COQUE : coques du Labo de Cramois'Île ;
  - CONCEPT_*_VUE_GENERALE : vues générales (plans de `plan_aplats_j24.py`).

**Les prompts sont versionnés** : `tools/art/prompts/serie27/<NOM>_rN.txt`, écrits par `--prompts`.
**Règle de Kevin pour Codex** : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais) ;
refus consignés dans `$ART/refus_serie27.log`.

Usage :
  tools/art/serie27.py --prompts            écrit les prompts (sans Codex)
  tools/art/serie27.py --ancres             copie dans $ART les ancres absentes (checkout principal)
  tools/art/serie27.py --commandes          liste les appels generer.sh
  tools/art/serie27.py [NOM|GROUPE ...]     génère avec Codex (sans argument : tout le lot)
  tools/art/serie27.py --tuiles             découpe les compositions de combat (portions _TL / _TR)
  tools/art/serie27.py --contact [sortie]   planche de contact À L'ÉCHELLE DU JEU
                                            (défaut build/art/J24_KIT_v1.png)
  tools/art/serie27.py --vues               copie les vues retenues et leurs plans dans
                                            docs/design/reference/ (VUES_RETENUES)
Groupes : surf, nageurs, top, force, artikodin, sols, combat, tuiles, dos, labo, vues.
"""
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie10  # noqa: E402
from serie06 import ADN, LUMIERE_NE, RACINE, TEXTURE_FIN  # noqa: E402
from serie10 import _Planche, _echelle  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026")
PROMPTS = ICI / "prompts" / "serie27"
PLANS = RACINE / "build" / "plans"
REFERENCE = "docs/design/reference"
OFFICIEL = "assets/sprites/pokemon/official"
PAINTED = "assets/sprites/characters/painted"

HEROS = "PERSO_P2_PEINT_r1.png"
GARDE = "PNJ_GARDE_NE_r1.png"
NAGEUR = f"{PAINTED}/nageur_sheet.png"
NAGEUSE = f"{PAINTED}/nageuse_sheet.png"
DRESSEUSE = f"{PAINTED}/dresseuse_sheet.png"
RAPASDEPIC = "assets/sprites/pokemon/painted/rapasdepic_sheet.png"
ROUCOUPS = "assets/sprites/pokemon/painted/roucoups_sheet.png"
ROCHER_GROTTE = "assets/world/props/prop_rocher_grotte_01.png"
ROCHER = "assets/world/props/prop_rocher_01.png"
ROCHER_MER = "assets/world/props/prop_rocher_mer_01.png"
SOL_EAU = "assets/world/ground/ground_eau_01.png"
SOL_GROTTE = "assets/world/ground/ground_grotte_01.png"
COQUE_LABO = "assets/world/interiors/int_labo_coque.png"
COQUE_CENTRE = "assets/world/interiors/int_centre_coque.png"
COMBAT_REF = f"{REFERENCE}/combat-v1.webp"
COMBAT_PLANCHE = f"{REFERENCE}/combat-decors-planche-v1.webp"
VUE_ROUTE25 = f"{REFERENCE}/route-25-vue-generale-v1.png"
VUE_CARMIN = f"{REFERENCE}/carmin-vue-generale-v1.png"
VUE_SELENITE = f"{REFERENCE}/mont-selenite-vue-generale-v1.png"
DOS_ANCRES = ["assets/sprites/pokemon/battle_proto/dos_ia_095.png",
	"assets/sprites/pokemon/battle_proto/dos_ia_093.png"]

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, AUCUN emblème rond de type balle (ni "
	"cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou faune "
	"non-Pokémon (oiseaux, mouettes, poissons, dauphins, phoques, insectes), Pikachu et tout Pokémon non "
	"demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune) sauf "
	"quand le héros est demandé, élément effrayant.")
SANS_EAU = ("L'eau elle-même n'est PAS dessinée (le jeu la peint dessous) : seulement ce qui dépasse de la "
	"surface, et un fin anneau d'écume blanche et de petites rides claires autour, à la ligne de "
	"flottaison ; tout le reste de la cellule est transparent.")

# --- Personnages et monture -----------------------------------------------------------------------

MONTURE = ("une MONTURE AQUATIQUE GÉNÉRIQUE (ce n'est AUCUN Pokémon connu, ni Lokhlass, ni Otaria, ni "
	"Carapuce) : une créature de dessin animé douce et ronde, sorte de gros coussin vivant qui flotte, au "
	"corps ovale et lisse BLEU CLAIR (bleu ciel un peu gris) avec un ventre et un museau CRÈME, une petite "
	"tête ronde à l'avant avec deux yeux noirs doux et un léger sourire, deux petites nageoires "
	"arrondies sur les flancs et une courte queue en éventail à l'arrière ; aucune corne, aucune "
	"carapace, aucun coquillage, aucune selle, aucun harnais. Vue de dessus de trois quarts, elle est "
	"à moitié immergée : on voit son dos bombé, le haut de sa tête et ses nageoires ; sa longueur "
	"est environ une fois et demie sa largeur.")


def prompt_monture(identifiant: str) -> str:
	return f"""{identifiant} — planche d'animation d'une MONTURE de Surf pour Kanto 2026 (le joueur s'assiera dessus pour traverser la mer).
Style : exactement le rendu de la planche jointe {HEROS[:-4]} (le héros validé) et de la planche de Pokémon jointe (Rapasdepic du jeu) : créature peinte simplifiée, même finesse, même contour fin coloré sans trait noir, même manière de peindre les volumes. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

CRÉATURE (identique dans toutes les images) : {MONTURE}

PLANCHE D'ANIMATION (spritesheet) : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 384 × 256 px et contient UNE pose de la monture, entière, centrée, à la MÊME taille dans toutes les cellules (environ 240 px de long de profil, 150 px de large de face ou de dos). Aucune pose ne déborde de sa cellule.
- Ligne 1 : vue de face (elle avance vers le bas de l'écran : on voit sa tête devant, son dos derrière).
- Ligne 2 : de profil, tournée vers la gauche.
- Ligne 3 : de profil, tournée vers la droite.
- Ligne 4 : de dos (elle avance vers le haut de l'écran : on voit sa queue et son dos, la tête au loin).
- Colonnes : 1 = à l'arrêt ; 2 = légère ondulation (le corps monte un peu, les nageoires s'ouvrent) ; 3 = à l'arrêt ; 4 = ondulation inverse (le corps descend un peu, les nageoires se ferment). Aux colonnes 2 et 4, un petit SILLAGE d'écume blanche en V part de l'arrière, dans le sens opposé à la marche.
{SANS_EAU}
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus). Pas de perspective, pas d'ombre portée, pas de texte, pas de numéros, pas de cadres autour des cellules, aucun personnage sur la monture.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.
{INTERDITS}
"""


def prompt_heros_surf(identifiant: str) -> str:
	return f"""{identifiant} — planche d'animation du HÉROS EN SURF pour Kanto 2026 : le héros de la planche jointe {HEROS[:-4]}, assis sur la monture de la planche jointe SURF_MONTURE_NE_r1, traverse la mer.
Style : exactement le rendu des deux planches jointes : personnage et créature peints simplifiés, chibi d'environ 3 têtes pour le héros, même finesse, même contour fin coloré sans trait noir. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

PERSONNAGE : EXACTEMENT le héros joint (même visage, même casquette, mêmes cheveux, mêmes vêtements, mêmes couleurs, même sac), à la MÊME ÉCHELLE que dans sa planche (sa tête a la même taille). Il est ASSIS À CALIFOURCHON sur le dos de la monture, le buste droit, les mains posées devant lui sur le dos de la monture ; ses jambes repliées se devinent le long des flancs. On voit tout son buste, ses bras et sa tête.
MONTURE : EXACTEMENT celle de la planche jointe SURF_MONTURE_NE_r1 (même forme, mêmes couleurs, même taille relative), à moitié immergée.

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose (le héros ET sa monture), entière, centrée horizontalement, la ligne de flottaison de la monture sur la même ligne horizontale à 70 px du bas de la cellule, à la même taille dans toutes les cellules. Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (ils avancent vers le bas de l'écran ; la tête de la monture devant le héros).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (ils avancent vers le haut de l'écran ; on voit le dos du héros et son sac).
- Colonnes : 1 = à l'arrêt ; 2 = légère ondulation (l'ensemble monte un peu) ; 3 = à l'arrêt ; 4 = ondulation inverse (l'ensemble descend un peu). Aux colonnes 2 et 4, un petit SILLAGE d'écume blanche en V derrière la monture. Le héros garde la même pose, il suit seulement le mouvement.
{SANS_EAU}
Vue : la même vue de dessus de trois quarts que le jeu. Pas de perspective, pas d'ombre portée, pas de texte, pas de numéros, pas de cadres autour des cellules, aucun autre personnage, aucun Pokémon.
Le visage, les couleurs, les proportions et les vêtements doivent être EXACTEMENT les mêmes dans les 16 poses.
"""


def prompt_nageur_eau(identifiant: str, feminin: bool) -> str:
	qui = "la NAGEUSE" if feminin else "le NAGEUR"
	planche = "nageuse_sheet" if feminin else "nageur_sheet"
	tenue = ("EXACTEMENT la Nageuse de la planche jointe nageuse_sheet (même visage, même chignon brun, mêmes "
		"lunettes de natation bleues remontées sur le front, même maillot turquoise, mêmes couleurs), mais "
		"sans serviette ni paréo (elle est dans l'eau)") if feminin else ("EXACTEMENT le Nageur de la "
		"planche jointe nageur_sheet (même visage, mêmes cheveux bruns en épis, mêmes lunettes de natation "
		"bleues remontées sur le front, même débardeur de bain bleu nuit, mêmes couleurs), mais sans "
		"serviette (il est dans l'eau)")
	return f"""{identifiant} — planche d'animation d'un Dresseur de Kanto 2026 qui NAGE dans la mer : {qui} déjà validé(e) dans le jeu, cette fois dans l'eau.
Style : exactement le rendu des planches jointes ({HEROS[:-4]}, le héros validé, et {planche}, ce même personnage à terre) : personnage peint simplifié, chibi d'environ 3 têtes, même finesse, même contour fin coloré sans trait noir. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

PERSONNAGE (identique dans toutes les images) : {tenue}. Il / elle nage la brasse, le corps dans l'eau : on ne voit QUE la tête, le cou et le haut des épaules au-dessus de la surface, et par moments les mains qui écartent l'eau devant lui / elle. La tête a EXACTEMENT la même taille que dans la planche jointe à terre.

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose, centrée horizontalement, la ligne de flottaison sur la même ligne horizontale à 120 px du bas de la cellule, à la même taille dans toutes les cellules. Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (il / elle nage vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran : l'arrière de la tête et des épaules).
- Colonnes : brasse en 4 images : 1 = mains jointes devant le menton ; 2 = mains qui s'écartent à la surface, la tête monte un peu ; 3 = bras ouverts, la tête redescend ; 4 = mains qui reviennent. De petites rides et un peu d'écume autour des épaules et des mains.
{SANS_EAU}
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit le dessus de la tête). Pas de perspective, pas d'ombre portée, pas de texte, pas de numéros, pas de cadres autour des cellules, aucun Pokémon, aucune bouée.
Le visage, les couleurs et les proportions doivent être EXACTEMENT les mêmes dans les 16 poses.
{INTERDITS}
"""


TOPDRESSEUR = ("un TOPDRESSEUR, jeune homme d'environ 20 ans, dresseur d'élite sûr de lui et sportif : "
	"cheveux noirs courts coiffés en arrière avec une mèche, sourcils marqués, regard décidé ; VESTE de "
	"survêtement courte VERT SAPIN à col montant et deux fines bandes blanches sur les manches, "
	"ouverte sur un t-shirt NOIR ; GANTS de dresseur noirs sans doigts ; pantalon de jogging GRIS "
	"ANTHRACITE ; baskets blanches à semelle verte ; une ceinture noire à petites pochettes carrées. "
	"Taille d'un adulte, mince et athlétique. Différent du héros joint (ni casquette, ni rouge, ni sac à "
	"dos) et du garde joint ; aucun insigne lisible, aucun texte.")
TOPDRESSEUSE = ("une TOPDRESSEUSE, jeune femme d'environ 20 ans, dresseuse d'élite assurée et élégante : "
	"longs cheveux AUBURN attachés en queue de cheval haute, frange sur le côté, regard décidé ; VESTE "
	"courte sans manches VIOLET PRUNE à col montant sur un haut moulant NOIR à manches longues ; GANTS "
	"de dresseuse noirs sans doigts ; jupe-short noire sur collant noir ; BOTTES blanches montantes à "
	"semelle violette ; une ceinture noire à petites pochettes carrées. Taille d'une adulte, mince et "
	"athlétique. Différente du héros joint, de la Dresseuse jointe (ni robe, ni chapeau) ; aucun "
	"insigne lisible, aucun texte.")


def prompt_marche(identifiant: str, ref: str, tenue: str) -> str:
	texte_ref = f" ; {ref} = même main et même finesse pour un adulte (à NE PAS copier : autre visage, autre tenue)"
	return MODELE_MARCHE.format(ident=identifiant, ref=texte_ref, tenue=tenue) + INTERDITS + "\n"


# --- Accessoires de Force, Artikodin --------------------------------------------------------------

def prompt_force(identifiant: str) -> str:
	return f"""{identifiant} — NOUVELLE image : planche de 4 accessoires de jeu (les rochers de Force et les trous des Îles Écume), pas une scène.
Images jointes : prop_rocher_grotte_01, prop_rocher_01 et prop_rocher_mer_01 = rochers DÉCOR déjà présents dans le jeu (rendu peint, finesse, angle de vue, lumière neutre) ; le rocher de Force doit s'en DISTINGUER au premier coup d'œil. ground_grotte_01 = sol de grotte du jeu (matière autour d'un trou).

{ADN}
{LUMIERE_NE}

PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné), divisée en quatre colonnes invisibles de 384 px ; UN élément CENTRÉ dans chaque colonne, avec au moins 50 px de marge vide de chaque côté, les quatre à la MÊME échelle (1 case de jeu ≈ 220 px sur cette planche).
1 : le ROCHER DE FORCE (poussable) : un gros rocher ARRONDI, presque en boule un peu aplatie, d'environ 1 case de large et 1,1 case de haut ; pierre GRIS CLAIR un peu chaude (plus claire que tous les rochers décor joints), surface lisse et polie par l'eau, UNE grande FISSURE nette en éclair qui le traverse en diagonale sur sa face avant, deux ou trois petits éclats ; posé sur une base plate (ligne de sol droite et horizontale), rien sous cette ligne. Il doit paraître lourd mais déplaçable, et se lire comme « un rocher qu'on peut pousser ».
2 : le MÊME rocher de Force TOMBÉ DANS L'EAU : seule sa moitié haute dépasse de la surface (même pierre, même fissure, un peu mouillée et plus sombre en bas), entourée d'un anneau d'écume blanche et de petites rides claires ; l'eau elle-même n'est pas dessinée (transparente autour de l'anneau).
3 : un TROU dans le sol de la grotte, vu strictement de dessus : une ouverture ronde d'environ 0,9 case, noire et bleu nuit au fond, au bord de pierre bleutée un peu givrée (fins cristaux de glace sur le rebord) ; seul le rebord et le trou sont dessinés, rien autour (transparent hors du rebord).
4 : le MÊME TROU BOUCHÉ : le rocher de Force est tombé dedans et le remplit au ras du sol : on voit le dessus arrondi et fissuré du rocher, enchâssé dans le rebord givré, un peu de poussière et de gravier clair autour ; plat, on peut marcher dessus.
Aucune ombre portée, aucun sol autour (sauf le rebord des trous), aucun personnage.
{INTERDITS}
"""


ARTIKODIN = ("ARTIKODIN (Articuno, n° 144 de la première génération), l'oiseau légendaire de glace, fidèle à son "
	"design officiel (voir l'artwork joint) : un grand oiseau élégant au plumage BLEU GLACE, à la longue "
	"QUEUE de plumes bleu pâle, à la crête de trois longues plumes bleu sombre sur le front, aux yeux "
	"rouge sombre calmes, au bec gris-bleu fin ; ventre et cou bleu très pâle. Majestueux, calme, jamais "
	"agressif.")


ARTIKODIN_R2 = (
	"\nCORRECTIONS (2e essai : le 1er était fidèle mais rendu comme un artwork officiel, de trois quarts "
	"tourné vers la gauche) :\n"
	"1. STYLE DU MONDE, pas d'artwork : rendu PEINT SIMPLIFIÉ exactement comme les planches jointes "
	"rapasdepic_sheet et roucoups_sheet (formes rondes et douces, proportions un peu trapues, tête un peu "
	"plus grosse, peu de plumes détaillées, contour fin coloré), à la même main que le héros joint.\n"
	"2. Strictement DE FACE et SYMÉTRIQUE (tourné vers le bas de l'écran, vers le spectateur) : les deux yeux "
	"visibles, le bec au milieu, la crête droite, la longue queue qui part derrière lui et retombe sur un côté.\n"
	"3. Fond entièrement transparent, aucune lueur ni halo bleu autour de lui.\n")


OISEAU_GLACE = ("un grand OISEAU DE GLACE de dessin animé, élégant et majestueux, au plumage BLEU GLACE, à la "
	"très longue QUEUE de plumes bleu pâle ondulées, à la crête de trois longues plumes pointues bleu sombre "
	"sur le front, aux yeux rouge sombre calmes, au bec gris-bleu fin, au ventre et au cou bleu très pâle, "
	"aux pattes grises fines ; jamais agressif.")


def prompt_artikodin(identifiant: str, avec_ancres: bool = True, variante: int = 1) -> str:
	if variante == 3:
		# r2 refusé 4 fois par le filtre (avec et sans pièce jointe) : sans aucun nom, ancres = r1 + Rapasdepic.
		texte = prompt_artikodin(identifiant, avec_ancres, 2).replace(ARTIKODIN, OISEAU_GLACE)
		texte = texte.replace("Images jointes : le héros du jeu PERSO_P2_PEINT_r1 ; rapasdepic_sheet et "
			"roucoups_sheet", "Images jointes : POKE_ARTIKODIN_MONDE_NE_r1 = le même oiseau (anatomie et couleurs "
			"seulement, PAS son rendu d'artwork ni sa pose de trois quarts) ; rapasdepic_sheet et roucoups_sheet")
		return texte.replace("un Pokémon du monde de Kanto 2026", "une créature du monde de Kanto 2026").replace(
			"POKÉMON (identique", "CRÉATURE (identique")
	if variante == 2:
		texte = prompt_artikodin(identifiant, avec_ancres).replace(
			"Images jointes : l'artwork officiel d'Artikodin (anatomie, couleurs et proportions seulement, "
			"pas son rendu ni sa pose) ; rapasdepic_sheet", "Images jointes : le héros du jeu PERSO_P2_PEINT_r1 ; "
			"rapasdepic_sheet")
		return texte + ARTIKODIN_R2
	ancres = ("Images jointes : l'artwork officiel d'Artikodin (anatomie, couleurs et proportions seulement, "
		"pas son rendu ni sa pose) ; rapasdepic_sheet et roucoups_sheet = oiseaux Pokémon déjà peints pour le "
		"monde du jeu : même rendu peint simplifié, même contour fin coloré, même finesse, même angle de "
		"vue.") if avec_ancres else "Aucune image n'est jointe."
	return f"""{identifiant} — planche d'animation d'un Pokémon du monde de Kanto 2026 : un grand oiseau de glace POSÉ au fond d'une grotte, qui attend le joueur.
{ancres}
Style : Pokémon peint simplifié comme les planches du jeu, contour fin coloré sans trait noir, volumes doux. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

POKÉMON (identique dans toutes les images) : {ARTIKODIN}
POSE : POSÉ au sol, debout sur ses deux pattes, de FACE (tourné vers le bas de l'écran), les AILES REPLIÉES le long du corps, la longue queue posée derrière lui et qui retombe sur le côté, la tête haute. Vue de dessus de trois quarts comme le jeu (caméra un peu au-dessus).

PLANCHE D'ANIMATION : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné). UNE seule ligne de 4 images, de gauche à droite, chacune dans une colonne invisible de 384 px, à la MÊME échelle (environ 330 px de haut, crête comprise), les pattes de toutes les images sur une même ligne horizontale à 170 px du bas de l'image :
- Image 1 : au repos.
- Image 2 : il INSPIRE (la poitrine se gonfle un peu, la tête monte légèrement, les plumes de la crête bougent).
- Image 3 : il EXPIRE un léger SOUFFLE FROID : une petite brume blanc-bleu pâle et quelques minuscules cristaux de givre sortent de son bec et descendent devant lui (discret, transparent sur les bords, jamais un rayon).
- Image 4 : retour au repos, le souffle se dissipe (à peine visible).
Aucune ombre portée, aucun sol, aucune glace sous ses pattes, aucun décor, aucun texte.
{INTERDITS}
"""


# --- Textures -------------------------------------------------------------------------------------

def prompt_texture(identifiant: str, asset: str, ancres: str) -> str:
	return f"""{identifiant} — NOUVELLE image : une texture de sol de jeu, pas une scène.
Images jointes : {ancres} = ancres de style (rendu peint, finesse, lumière neutre) ; n'en copie pas le motif.

{ADN}

Valeurs : lumière neutre, aucune ombre portée, aucun vignettage.

ASSET : {asset}
{TEXTURE_FIN}
{INTERDITS}
"""


COURANT = ("texture d'un COURANT MARIN FORT qui s'écoule VERS LE BAS de l'image (vers le sud), vue strictement "
	"de dessus : eau bleu turquoise un peu plus claire et plus agitée que la mer jointe, traversée de "
	"longues TRAÎNÉES D'ÉCUME blanche orientées VERTICALEMENT (toutes dans le même sens), en chevrons "
	"souples qui pointent vers le bas, petites vagues allongées dans le sens du courant ; la direction du "
	"flux se lit sans ambiguïté. Raccordable sur ses quatre bords (le jeu la fait défiler vers le bas et "
	"la tourne pour les autres directions).")
EAU_GROTTE = ("texture d'une EAU CALME de grotte glacée, vue strictement de dessus : eau profonde BLEU "
	"TURQUOISE froid vers le bleu nuit, très lisse, quelques reflets clairs bleu glace et de fines rides "
	"douces, un soupçon de transparence qui laisse deviner un fond de roche bleutée ; aucune écume, aucun "
	"rivage, aucune glace flottante.")
GLACE = ("texture du SOL d'une grotte de GLACE et de pierre (Îles Écume), vue strictement de dessus : roche "
	"gris-bleu clair un peu givrée, plaques de glace mate bleu pâle irrégulières entre les pierres plates, "
	"fines craquelures, petits cristaux de givre blanc, quelques graviers ; lumineux et froid, jamais "
	"blanc pur, plus clair et plus bleu que le sol de grotte joint.")


# --- Combat ---------------------------------------------------------------------------------------

def prompt_combat(identifiant: str, lieu: str, image3: str, description: str, composition: str,
		lumiere: str, interdits: str) -> str:
	return f"""DÉCOR DE COMBAT — {lieu} (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.

Images jointes.
IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité de peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont.
IMAGE 2 : une planche d'intention de décors de combat (guide de facture).
IMAGE 3 : {image3}

FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution possible, OPAQUE, cadrage plein, sans bord.

LIEU : {description}

COMPOSITION (fractions depuis le coin haut gauche) :
{composition}
- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de détails et peu de contraste, valeurs simples.
- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : surface simple, presque sans objet, valeurs moyennes, sans contraste fort.
- Les deux coins du bas restent dégagés : pas de rocher en gros plan.
- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur certains écrans).

LUMIÈRE : {lumiere}

RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à hauteur d'yeux, un peu plongeante, la surface recule nettement vers l'horizon.

INTERDITS : {interdits}
"""


MER_DESC = ("la HAUTE MER entre Parmanie et Cramois'Île, en plein Surf : il n'y a PAS de sol, les deux "
	"créatures flotteront sur l'eau. Toute la moitié basse de l'image est une MER OUVERTE turquoise puis "
	"bleu profond, à la houle douce et régulière, de petites vagues aux crêtes d'écume claire, des reflets "
	"de lumière ; au loin, sur l'horizon à droite, la silhouette basse d'une île aux FALAISES BLANCHES "
	"(les Îles Écume) et quelques récifs gris ; ciel de fin d'après-midi.")
MER_COMPO = ("- Horizon vers 33 % de la hauteur : la mer jusqu'à l'horizon, l'île aux falaises blanches entre x "
	"68 % et 90 %, basse (entre 24 et 34 % de la hauteur) ; deux ou trois petits récifs gris au plan moyen "
	"vers x 15 % et x 85 %, entre 36 et 44 % de la hauteur.\n"
	"- De 45 % de la hauteur jusqu'en bas : EAU LIBRE, sans rocher, la houle de plus en plus grande vers le "
	"premier plan.\n"
	"- Point A (x 67 %, y 58 %) : eau calme et lisible, une créature y flottera ; rien de haut dans un rayon "
	"de 12 % de la largeur autour, une zone un peu plus claire et plus lisse de l'eau.\n"
	"- Point B (x 31 %, y 97 %) : eau calme, une grande créature vue de dos y flottera au premier plan.")
MER_LUMIERE = ("golden hour, soleil bas du haut à gauche (hors cadre), reflets dorés sur la mer, ciel bleu "
	"pâle voilé aux nuages légers, pas de soleil visible.")
MER_INTERDITS = ("Pokémon, animal, oiseau, mouette, poisson, personnage, silhouette, texte, lettres, chiffres, "
	"logo, signature, filigrane, cadre, interface, bateau, voilier, bouée, maison, bâtiment, phare, plage au "
	"premier plan, sol, pixel art, flou, vignettage.")

GROTTE_DESC = ("une salle des ÎLES ÉCUME, une grotte de glace et d'écume au milieu de la mer : parois de roche "
	"bleu-gris couvertes de GLACE bleutée translucide, quelques STALACTITES de glace qui pendent du "
	"plafond au fond, une large bande d'EAU calme turquoise au fond de la salle (à gauche), embruns ; "
	"au premier plan et au centre, un GRAND SOL plat de roche bleutée givrée et de plaques de glace mate, "
	"quelques petits cristaux, flaques gelées.")
GROTTE_COMPO = ("- Fond (25 à 38 % de la hauteur) : la paroi du fond, roche bleu-gris et glace, stalactites de "
	"glace ; à gauche (x 8 à 40 %), une bande d'eau calme turquoise au pied de la paroi, avec un peu d'écume ; "
	"à droite (x 75 à 92 %), deux gros blocs de glace bleutée.\n"
	"- De 40 % de la hauteur jusqu'en bas : un GRAND SOL DÉGAGÉ et PLAT de roche bleutée givrée et de glace "
	"mate (pas glissante comme un miroir), où deux créatures pourront se faire face.\n"
	"- Point A (x 67 %, y 50 %) : sol plat, clair et lisible. Rien de haut dans un rayon de 12 % de la "
	"largeur autour.\n"
	"- Point B (x 31 %, y 97 %) : sol plat, une grande créature vue de dos y sera au premier plan.")
GROTTE_LUMIERE = ("froide et claire : une lumière blanc-bleu pâle tombe d'une fente du plafond hors cadre en "
	"haut à gauche et se diffuse dans la glace (la glace rayonne doucement en bleu) ; ombres bleu nuit et "
	"violet froid, jamais noires ; le centre du sol est lumineux et net.")
GROTTE_INTERDITS = ("Pokémon, animal, personnage, silhouette, texte, lettres, chiffres, logo, signature, filigrane, "
	"cadre, interface, ciel, soleil, végétation, flammes, lave, cristaux géants, décor féerique, échelle, "
	"objet humain, noir pur, pixel art, flou, vignettage.")

TUILE = (ICI / "combat_decors" / "prompts" / "COMBAT_DECOR_TUILE_r1.txt")
## Portions des tuiles (fractions de la composition, comme 1000 / 1846 des décors existants).
TUILE_PART = 1000 / 1846


# --- Dos de combat ---------------------------------------------------------------------------------

DOS = {
	"ARTIKODIN": ("144", "Artikodin (Articuno, n° 144)", "un grand OISEAU de glace élégant au plumage bleu "
		"glace, à la très longue queue de plumes bleu pâle, à la crête de trois longues plumes bleu sombre ; "
		"vu de dos, posé, les AILES À DEMI OUVERTES (on voit le dessus de ses ailes bleu glace aux longues "
		"rémiges), la queue qui descend vers le bas de l'image ; la tête tournée vers le haut à droite, on "
		"devine le profil de son bec gris-bleu. Silhouette haute et fine, plus haute que large."),
	"KABUTO": ("140", "Kabuto (n° 140)", "une petite créature fossile ronde dont tout le corps est caché sous "
		"une CARAPACE EN DÔME brun-orangé brillante et lisse, à la bordure un peu plus foncée ; vue de dos, "
		"on voit le dôme de la carapace, une petite arête au sommet et, dessous, l'extrémité de quelques "
		"petites pattes noires ; deux petits yeux jaunes brillants se devinent sur le côté, sous le bord "
		"de la carapace, tournés vers le haut à droite. Silhouette basse, plus large que haute."),
	"AMONITA": ("138", "Amonita (Omanyte, n° 138)", "une petite créature fossile qui vit dans une COQUILLE "
		"EN SPIRALE beige crème striée de brun, avec une courte pointe ; vue de dos, la coquille occupe "
		"presque tout le corps, son enroulement en spirale bien visible ; dessous, quelques petits "
		"TENTACULES bleu ciel dépassent ; on devine sur le côté un grand œil, tourné vers le haut à droite. "
		"Silhouette ronde, aussi large que haute."),
}


def prompt_dos(identifiant: str, espece: str, avec_ancres: bool) -> str:
	numero, nom, sujet = DOS[espece]
	ancres = (f"IMAGE 1 : l'artwork officiel de face de {nom} : anatomie, couleurs, proportions et style de "
		"rendu (pas la pose : on le veut de dos).\nIMAGE 2 : un autre Pokémon de dos déjà produit pour ce jeu "
		"(Onix, dos) : reprends son ANGLE de vue (trois quarts dos, regard vers le haut à droite), son cadrage "
		"et sa famille de rendu (contour brun foncé fin, aplats nuancés, transparence) ; ne reprends ni sa "
		"forme ni ses couleurs.\nIMAGE 3 : un autre Pokémon de dos, même rendu.") if avec_ancres \
		else "Aucune image jointe."
	return f"""ILLUSTRATION DE JEU VIDÉO : une créature de dessin animé vue de DOS, pour l'écran d'un jeu de combat au tour par tour (Kanto 2026, projet personnel). La créature est {nom}, de la première génération.

{ancres}

SUJET : {sujet}

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). AUCUN visage de face.

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE, centrée, qui occupe environ 85 % de la hauteur, son bas à environ 120 px du bord bas ; rien n'est coupé par les bords. Une seule image fixe.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
"""


# --- Coques du Labo de Cramois'Île ----------------------------------------------------------------

LABO_SALLES = {
	"HALL": ("labo_hall", 27, 12, "le HALL d'accueil du Labo Pokémon de Cramois'Île",
		"Au mur du fond, de gauche à droite : un grand CADRE doré contenant une PHOTO ancienne en noir et "
		"blanc d'un vieux savant (visage flou, méconnaissable, AUCUN texte) aux cases (4..5) ; trois "
		"PORTES COULISSANTES métalliques gris clair, fermées, à hublot rond, sur 2 cases de large chacune "
		"(cases 12..13, 18..19, 24..25), qui mènent aux trois salles ; entre elles, de grands panneaux de "
		"verre dépoli et des plinthes bleu acier."),
	"RD": ("labo_rd", 15, 10, "la SALLE DE RECHERCHE ET DÉVELOPPEMENT du Labo",
		"Contre le mur du fond, à gauche (cases 1..3) : une rangée de trois ORDINATEURS anciens (écrans "
		"bombés allumés en bleu pâle, claviers, sans texte lisible) sur un long plan de travail ; au "
		"milieu-droite (cases 9..11) : une grande MACHINE DE RECHERCHE blanche et grise, panneaux de "
		"voyants, petit écran rond ; le reste du mur : étagères murales vides et un tableau blanc vierge."),
	"FOSSILES": ("labo_fossiles", 15, 10, "la SALLE DES FOSSILES du Labo, où l'on ressuscite les Pokémon fossiles",
		"Contre le mur du fond, à gauche (cases 2..6) : la grande MACHINE DE RÉSURRECTION, un appareil "
		"blanc et argent de 5 cases de large, avec au centre une CAPSULE de verre vide (cylindre "
		"transparent éclairé de turquoise), des tuyaux et câbles qui courent vers le mur, un panneau de "
		"commande à voyants ; à droite (cases 9..10) : deux VITRINES murales de verre éclairées, VIDES "
		"(socles nus) ; aucun fossile visible."),
	"REUNION": ("labo_reunion", 15, 10, "la SALLE DE RÉUNION du Labo",
		"Le mur du fond porte un grand TABLEAU BLANC vierge, une étagère de classeurs colorés sans "
		"étiquette et une fenêtre sur la mer (bleu clair, horizon) ; plinthes bleu acier."),
}


def prompt_coque(identifiant: str, salle: str) -> str:
	_, largeur, profondeur, nom, mur = LABO_SALLES[salle]
	return f"""{identifiant} — NOUVELLE image : l'enveloppe d'une pièce intérieure de jeu (murs, sol et ce qui est fixé au mur du fond ; aucun meuble posé au sol).
Images jointes : IMAGE 1 = le PLAN de la pièce en aplats (composition EXACTE à suivre : murs gris foncé, sol à damier clair, paillasson vert de la sortie en bas, et les éléments fixés au mur du fond) ; IMAGE 2 et IMAGE 3 = coques du Labo du Professeur Chen et du Centre Pokémon du jeu : ancres de style des intérieurs (rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière neutre) : respecte-les exactement, sans en copier le contenu.

{ADN}
{LUMIERE_NE}

EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en trois quarts, image opaque qui remplit le cadre.
Géométrie (respecte EXACTEMENT le plan joint, c'est un plan de jeu) : Format : PNG paysage 1536 × 1024, opaque ; la pièce fait {largeur} cases de large × {profondeur} de profondeur, à l'emplacement exact du plan (les bandes noir uni du plan, s'il y en a, restent NOIR UNI). Vue de dessus en projection oblique frontale : le MUR DU FOND occupe toute la largeur en haut, on voit sa face avant ; les murs latéraux gauche et droit ne sont visibles que par leur épaisseur vue de dessus (bandes droites et verticales, SANS perspective) ; le mur du bas (au premier plan) n'est visible que par son épaisseur vue de dessus, interrompu par l'ENTRÉE à l'endroit du paillasson vert (paillasson vert uni, aucun emblème).
Pièce : {nom}, île volcanique et savante : un laboratoire BLANC et MODERNE, propre et lumineux ; murs blanc cassé, plinthes et encadrements BLEU ACIER, sol de grandes dalles blanches et gris perle légèrement brillantes, quelques fines lignes de joint ; plafonniers éteints non visibles.
{mur}
Interdit : meubles posés au sol (tables, chaises, plantes, lampes, canapé), personnages, Pokémon, fossile, perspective avec point de fuite, vue isométrique, murs latéraux en biais, flaques de lumière peintes au sol, ombre portée, texte, lettres, chiffres, logo, emblème rond de type balle.
"""


# --- Vues générales --------------------------------------------------------------------------------

RENDU_VUE = """RENDU (ADN visuel Kanto 2026 v1)
- Illustration 2D peinte numériquement, dans l'esprit d'un RPG Pokémon moderne au rendu « HD-2D peint » : formes simples, lisibles et arrondies, détails fins mais ordonnés. Ni pixel art, ni 3D, ni photo, ni aquarelle, ni cartoon en aplats.
- Perspective : vue de dessus, axes de l'image alignés sur la grille, projection oblique frontale, sans point de fuite et SANS ISOMÉTRIE. Les verticales restent verticales. On voit le dessus des objets et leur face avant (côté sud).
- Aucun trait noir : contours fins et doux, plus sombres et plus saturés que la couleur locale. Ombres colorées bleu-vert ou violet froid, jamais grises.
- Pas de minimap, pas de flèche, pas de cadre, pas d'interface."""

REGLE_ANGLES = ("RÈGLE ABSOLUE DES BORDS : le joueur se déplace case par case, seulement à l'horizontale et à la "
	"verticale ; rivages, plages, récifs, falaises et bords des zones suivent une grille : uniquement des "
	"segments horizontaux et verticaux à ANGLES DROITS, AUCUNE courbe, aucun segment en diagonale. Les "
	"rochers et l'écume peuvent être irréguliers EN SURFACE, mais chaque zone garde des bords droits et "
	"lisibles.")
REGLE_GROTTE = ("RÈGLE ABSOLUE DES PASSAGES : le joueur se déplace case par case, seulement à l'horizontale et à "
	"la verticale ; galeries, salles, bassins et bords suivent une grille : segments horizontaux et "
	"verticaux à ANGLES DROITS, AUCUNE galerie en diagonale ni en courbe. Les parois peuvent être "
	"irrégulières EN SURFACE, mais le sol praticable et l'eau gardent des bords droits et lisibles.")

LEGENDE_MER = """- bleu = la MER (eau où l'on navigue en Surf) ; liseré blanc = écume le long des rivages ;
- gris moucheté de cailloux clairs = RÉCIFS et rivage rocheux (gros rochers qui sortent de l'eau, infranchissables) ;
- vert très foncé = forêt dense infranchissable ;
- beige clair = SABLE (plages et îlots) ; traits beige foncé en travers d'une plage = petits REBORDS de sable (marches basses qu'on saute vers le sud) ;
- vert moyen = herbe rase ; vert-jaune = HAUTES HERBES ;
- blanc strié de gris-bleu = hautes FALAISES BLANCHES ; rectangle sombre au pied d'une falaise = ENTRÉE DE GROTTE ;
- petits carrés ocre = panneaux en bois SANS TEXTE ; disque rouge et blanc = une Poké Ball posée au sol."""

LEGENDE_GROTTE = """- bleu ardoise foncé = ROCHE ET PAROIS infranchissables ; bande plus claire au bas d'une paroi = sa face rocheuse visible ;
- gris-bleu clair = SOL BAS de la grotte (roche bleutée givrée) ; gris-bleu presque blanc = SOL HAUT (plateaux de glace et de neige tassée, un niveau plus haut, bordés de petites falaises de glace) ;
- bande gris-bleu moyen = ARÊTE (rebord de glace entre le sol bas et le sol haut, infranchissable) ;
- gris clair rayé de traits horizontaux = ESCALIERS taillés dans la glace entre les deux niveaux ;
- bleu = EAU calme d'un bassin souterrain ; bleu plus sombre = eau profonde hors d'atteinte ;
- chevrons blancs sur l'eau = COURANT violent (écume orientée dans le sens des chevrons, petites vagues) ;
- gros disque gris clair fendu = ROCHER DE FORCE (rocher rond et clair, fissuré, qu'on peut pousser) ;
- ovale noir cerclé de bleu = TROU dans le sol, vers l'étage du dessous ;
- petite échelle brune = ÉCHELLE qui monte ; échelle sur un disque noir = ÉCHELLE qui descend par un trou ;
- rectangle beige très clair au bord de l'image = ENTRÉE de la grotte, lumière du dehors ;
- petits disques ardoise = petits rochers fixes ; minuscule caillou blanc = un caillou clair ; petit carré ocre = panneau SANS TEXTE."""

AMBIANCE_GROTTE = """AMBIANCE — « deux îles de glace et d'écume » : un donjon froid au milieu de la mer, glace bleutée, écume, vent, gouttes. Mystérieux, beau et silencieux, JAMAIS effrayant ni illisible.
- Palette : BLEU GLACE, gris-bleu, turquoise de l'eau, blanc de l'écume et du givre ; ombres bleu nuit et violet froid ; pas de filtre uniforme.
- LISIBILITÉ AVANT TOUT : le sol praticable est nettement plus clair que la roche ; le sol haut se distingue du sol bas par sa couleur plus blanche et par la petite falaise de glace qui le borde ; l'eau se lit d'un coup d'œil.
- Stalactites et stalagmites de glace discrètes contre les parois, givre sur les rochers, gouttes ; quelques reflets de lumière dans la glace."""

PERSONNE = "PERSONNE : aucun personnage, aucun Pokémon, aucun animal."
INTERDITS_VUE = ("INTERDITS : texte, lettres, chiffres, étiquettes, panneaux lisibles, logo, signature, filigrane, "
	"cadre, interface, minimap, flèche ; tout élément non prévu par le plan ; bords courbes ou en diagonale ; "
	"brouillard épais, flou de profondeur, vignettage ; pixel art ; vue isométrique.")


def _entete_vue(titre: str, image2: str, format_: str) -> str:
	return f"""CONCEPT ART — {titre} (Kanto 2026), image de référence de direction artistique.

Deux images sont jointes.
IMAGE 2 : {image2}
Format : {format_}, vue plongeante, exactement comme le plan.
"""


def prompt_vue(nom: str) -> str:
	v = VUES[nom]
	return f"""{_entete_vue(v['titre'], v['image2'], v['format'])}
IMAGE 1 : un PLAN SCHÉMATIQUE en aplats de couleur, vu du dessus, qui donne la COMPOSITION EXACTE à suivre. {v['plan']}
Légende du plan :
{v['legende']}
Respecte ce plan À LA LETTRE : la forme et la place de chaque zone. Le plan ne donne que la composition : son style en aplats ne doit pas apparaître.

{v['regle']}

{RENDU_VUE}

{v['ambiance']}

{v.get('vie', PERSONNE)}

{INTERDITS_VUE} {v.get('interdits', '')}

L'image doit raconter, sans texte : {v['recit']}
"""


AMBIANCE_MER = ("AMBIANCE — « Kanto s'ouvre vers le large » : golden hour, lumière dorée rasante venant du haut "
	"à gauche, la mer scintille, embruns, vent.\n- Palette : MER turquoise près des rivages, bleu profond au "
	"large, reflets dorés ; écume blanche autour des récifs ; SABLE clair et chaud ; roches grises et beiges.")

VUES: dict[str, dict] = {
	"route19": {
		"titre": "VUE GÉNÉRALE DE LA ROUTE 19, LA PLAGE ET LA MER AU SUD DE PARMANIE", "plan_png": "PLAN_ROUTE19_v1.png",
		"image2": "la vue générale de la Route 25, une autre route côtière du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même mer, mêmes rochers de rivage, même sable, même saturation, MÊME LUMIÈRE. Ne reprends PAS sa composition (ni maison, ni chemin de terre, ni champ).",
		"format": "PORTRAIT 1024 × 1536",
		"plan": "La carte est une bande verticale : en haut, une PLAGE de sable sous la ville de Parmanie (hors de l'image, au nord), encadrée de forêt, avec des rebords de sable et un étroit couloir de sable à droite ; puis, sur presque toute la hauteur, la MER entre deux lignes de récifs, qui s'ouvre vers l'ouest tout en bas à gauche (vers la Route 20).",
		"legende": LEGENDE_MER, "regle": REGLE_ANGLES,
		"ambiance": AMBIANCE_MER + "\n- La plage est vivante mais calme : deux ou trois PARASOLS REPLIÉS plantés dans le sable, une serviette, des traces de pas ; la mer est grande et ouverte, la houle se lit.",
		"vie": "VIE (très discrète, personnages petits, aucun ne ressemble au héros à casquette rouge) : sur la plage, deux TOPDRESSEURS (jeunes dresseurs sportifs en veste de survêtement) qui s'échauffent ; dans la mer, quatre ou cinq NAGEURS dont on ne voit que la tête et les épaules, répartis en quinconce sur toute la hauteur. Aucun Pokémon, aucun animal.",
		"recit": "on quitte la plage de Parmanie, et la mer s'ouvre, grande, peuplée de nageurs, vers le large.",
	},
	"route20": {
		"titre": "VUE GÉNÉRALE DE LA ROUTE 20 ET DE L'ÎLE DES ÎLES ÉCUME", "plan_png": "PLAN_ROUTE20_v1.png",
		"image2": "la vue générale de la Route 25, une autre route côtière du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même mer, mêmes rochers, même sable, même saturation, MÊME LUMIÈRE. Ne reprends PAS sa composition (ni maison, ni forêt, ni chemin).",
		"format": "PAYSAGE 1536 × 1024",
		"plan": "La carte est une longue bande de MER horizontale (le haut et le bas de l'image, hors de la bande, sont aussi de la mer, plus loin). Au centre, l'ÎLE des Îles Écume : un plateau de sable entouré de hautes FALAISES BLANCHES, avec DEUX ENTRÉES DE GROTTE (une en haut à gauche de l'île, une en bas à droite) ; une longue ligne de RÉCIFS descend de l'île vers le bas à droite et coupe la mer en deux ; à gauche de l'île, une petite POCHE d'eau fermée par des récifs ; à gauche, un petit ÎLOT de sable isolé (l'îlot de l'Ornithologue) avec une Poké Ball.",
		"legende": LEGENDE_MER, "regle": REGLE_ANGLES,
		"ambiance": AMBIANCE_MER + "\n- L'île est le grand repère : falaises BLANCHES comme de la craie, striées, couronnées d'un peu d'herbe rase et de givre, embruns et écume tout autour ; les deux entrées de grotte sont des ouvertures sombres d'où sort un léger souffle froid (brume pâle).",
		"vie": "VIE (très discrète, personnages petits) : quelques NAGEURS et NAGEUSES dont on ne voit que la tête et les épaules, dispersés dans la mer de part et d'autre de la ligne de récifs ; sur l'îlot de gauche, un ORNITHOLOGUE (homme à casquette de baroudeur et gilet à poches, jumelles au cou) assis qui attend. Aucun Pokémon, aucun animal.",
		"recit": "au milieu de la mer, une île de falaises blanches percée de deux grottes froides, que les nageurs contournent, et un petit îlot perdu.",
	},
	"route21_nord": {
		"titre": "VUE GÉNÉRALE DE LA ROUTE 21 (MOITIÉ NORD), LA MER AU SUD DE BOURG PALETTE", "plan_png": "PLAN_ROUTE21_NORD_v1.png",
		"image2": "la vue générale de la Route 25, une autre route côtière du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même mer, mêmes rochers, même herbe, mêmes hautes herbes, mêmes arbres, même saturation, MÊME LUMIÈRE. Ne reprends PAS sa composition (ni maison, ni chemin, ni falaise).",
		"format": "PORTRAIT 1024 × 1536",
		"plan": "Le haut de la carte touche la côte sud de Bourg Palette (hors de l'image) par un étroit CANAL d'eau en haut à gauche. Juste à droite du canal, une PRAIRIE d'herbe rase puis de HAUTES HERBES, bordée de récifs, qu'on n'atteint que par l'eau ; à gauche et à droite, des bois denses. Puis la MER, large, entre deux lignes de récifs ; un petit ÎLOT de sable vers le haut de la mer, à gauche (l'îlot d'un pêcheur).",
		"legende": LEGENDE_MER, "regle": REGLE_ANGLES,
		"ambiance": AMBIANCE_MER + "\n- La prairie est un petit monde à part, sauvage, l'herbe haute ondule au vent ; l'îlot du pêcheur porte une canne à pêche plantée et un seau.",
		"vie": "VIE (très discrète, personnages petits) : un PÊCHEUR (chapeau de pêche, gilet) assis au bord de l'îlot, sa canne tendue vers l'eau ; deux NAGEURS dont on ne voit que la tête et les épaules dans la mer. Aucun Pokémon, aucun animal.",
		"recit": "au sud de Bourg Palette, un canal mène à une prairie sauvage, puis à la grande mer où un pêcheur attend sur son îlot.",
	},
	"route21_sud": {
		"titre": "VUE GÉNÉRALE DE LA ROUTE 21 (MOITIÉ SUD), LA MER AU NORD DE CRAMOIS'ÎLE", "plan_png": "PLAN_ROUTE21_SUD_v1.png",
		"image2": "la vue générale de la Route 25, une autre route côtière du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même mer, mêmes rochers, même sable, même saturation, MÊME LUMIÈRE. Ne reprends PAS sa composition.",
		"format": "PORTRAIT 1024 × 1536",
		"plan": "La carte est une bande verticale de MER entre deux lignes de récifs ; vers le milieu, à droite, un petit ÎLOT de sable avec une Poké Ball (l'îlot d'un pêcheur) ; tout en bas, la côte nord de Cramois'Île (hors de l'image) : une POINTE DE SABLE NOIR volcanique y touche le bord bas, à droite, et le chenal d'eau continue en bas à gauche.",
		"legende": LEGENDE_MER + "\n- beige tout en bas = la pointe de SABLE NOIR VOLCANIQUE de Cramois'Île (peins-la gris anthracite, pas beige).",
		"regle": REGLE_ANGLES,
		"ambiance": AMBIANCE_MER + "\n- En descendant vers le sud, la côte devient VOLCANIQUE : récifs plus sombres, presque noirs, sable noir sur la pointe du bas ; une très légère fumée lointaine s'élève hors champ en bas.",
		"vie": "VIE (très discrète, personnages petits) : un PÊCHEUR assis au bord de l'îlot, sa canne tendue vers l'eau ; trois NAGEURS dont on ne voit que la tête et les épaules. Aucun Pokémon, aucun animal.",
		"recit": "la mer descend vers une île volcanique au sable noir, un pêcheur attend sur son îlot.",
	},
	"cramois_ile": {
		"titre": "VUE GÉNÉRALE DE CRAMOIS'ÎLE, L'ÎLE VOLCANIQUE ET SAVANTE", "plan_png": "PLAN_CRAMOIS_ILE_v1.png",
		"image2": "la vue générale de Carmin-sur-Mer, une ville portuaire du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même mer, même saturation, MÊME LUMIÈRE, même échelle des bâtiments ; le CENTRE POKÉMON et la BOUTIQUE sont EXACTEMENT les mêmes bâtiments (identiques dans toutes les villes : Centre au toit rouge avec l'emblème Poké Ball blanc et la grande porte vitrée ; Boutique au toit bleu, même emblème, même porte vitrée). Ne reprends PAS sa composition (ni quai, ni paquebot, ni place pavée).",
		"format": "PAYSAGE 1536 × 1024",
		"plan": "Une petite ÎLE au milieu de la mer : la ville occupe un plateau de SOL VOLCANIQUE brun-gris ; de la mer tout autour (bande d'eau à gauche, grande mer en bas, mince bande d'eau à droite) ; une PLAGE DE SABLE NOIR (bande gris anthracite) au sud de la ville ; des RÉCIFS de roche volcanique sombre à gauche, en bas et en haut à droite. Cinq bâtiments : en haut à gauche le MANOIR POKÉMON (grand bâtiment incendié, toit noirci et éventré, gravats devant la porte) ; en haut à droite l'ARÈNE (toit rouge brique, porte double) ; au milieu à gauche le LABO POKÉMON (bâtiment blanc et moderne, toit gris bleuté) ; en bas au centre le CENTRE POKÉMON (toit rouge) ; en bas à droite la BOUTIQUE (toit bleu). Une large allée de sol volcanique monte vers le nord entre le Manoir et l'Arène (vers la Route 21).",
		"legende": """- bleu = la MER ; liseré blanc = écume le long des rivages ;
- brun-gris moucheté de cailloux = RÉCIFS et rochers de roche volcanique sombre (infranchissables) ;
- brun-gris clair = SOL VOLCANIQUE de la ville (terre et roche tassées, praticable) ;
- gris anthracite = PLAGE DE SABLE NOIR volcanique ;
- grand bloc au toit noir troué en haut à gauche = le MANOIR incendié ; petits cailloux sombres devant sa façade = GRAVATS qui bouchent son entrée ;
- toit rouge brique en haut à droite = l'ARÈNE ; toit gris bleuté et façade blanche = le LABO ; toit rouge et façade blanche = le CENTRE POKÉMON ; toit bleu et façade blanche = la BOUTIQUE ; rectangles bruns = portes ;
- petits carrés ocre = panneaux en bois SANS TEXTE.""",
		"regle": REGLE_ANGLES,
		"ambiance": """AMBIANCE — « l'île volcanique et savante » : golden hour, lumière dorée rasante du haut à gauche, la mer scintille.
- Palette : ROCHE VOLCANIQUE sombre (brun-noir, gris anthracite), sol de terre brun-gris, sable NOIR scintillant ; touches de vert sombre très rares (quelques arbustes rustiques dans les marges, pas de forêt) ; le LABO blanc éclatant tranche sur la roche.
- Légères FUMEROLLES blanches qui s'élèvent de fissures dans les rochers en haut à droite, derrière l'Arène (le volcan est au fond, hors de l'image).
- Le MANOIR est une ruine : murs noircis par un vieil incendie, toit effondré par endroits, poutres calcinées, entrée bouchée par des gravats ; triste, jamais effrayant.
- Le LABO est moderne et propre : façade blanche, grandes vitres, antennes sur le toit.""",
		"vie": "VIE (très discrète, personnages petits, aucun ne ressemble au héros à casquette rouge) : une FILLE qui marche sur l'allée centrale, un HOMME immobile près de l'Arène. Aucun Pokémon, aucun animal.",
		"interdits": "Aucune lave, aucun volcan en éruption, aucun palmier, aucune route goudronnée ni véhicule.",
		"recit": "une petite île volcanique où se dressent un laboratoire blanc, un manoir en ruine, une Arène, un Centre et une Boutique, au milieu de la mer.",
	},
}

ETAGES = {
	"iles_ecume_1f": ("1F", "PLAN_ILES_ECUME_1F_v1.png", "le PREMIER ÉTAGE, juste sous la surface : le plus clair ; la lumière du dehors entre par les DEUX ENTRÉES du bas (une à gauche, une à droite) et éclaire le sol en longues taches pâles ; quelques puits de jour au plafond.",
		"On entre par le BAS, par deux entrées. Un grand plateau de SOL HAUT occupe le haut à gauche ; le SOL BAS occupe le bas et la droite, coupé par une longue ARÊTE verticale ; deux ROCHERS DE FORCE et deux TROUS dans la partie droite ; des échelles."),
	"iles_ecume_b1f": ("B1F", "PLAN_ILES_ECUME_B1F_v1.png", "le premier sous-sol : un peu plus sombre et plus froid ; lumière bleutée diffuse qui tombe de quelques fentes, givre sur les parois.",
		"Plateaux de SOL HAUT à gauche et au centre, SOL BAS en couloirs autour ; deux TROUS au centre-droite, séparés par une arête (les rochers tombés de l'étage du dessus arrivent à côté plus tard : ils ne sont PAS dessinés) ; échelles."),
	"iles_ecume_b2f": ("B2F", "PLAN_ILES_ECUME_B2F_v1.png", "le deuxième sous-sol : encore plus sombre, bleu froid ; la glace luit doucement d'elle-même, embruns qui montent d'en dessous.",
		"Grands plateaux de SOL HAUT au milieu et à droite, SOL BAS en haut et en bas ; au centre-haut, deux TROUS de part et d'autre d'une double arête (aucun rocher dessiné) ; échelles."),
	"iles_ecume_b3f": ("B3F", "PLAN_ILES_ECUME_B3F_v1.png", "le troisième sous-sol : sombre et froid, mais l'EAU luit en turquoise ; le grand bassin central est agité par un COURANT violent dont l'écume se voit de loin (chevrons blancs) ; en bas à gauche, une poche de SOL BAS avec quatre ROCHERS DE FORCE, des petits rochers et deux TROUS.",
		"Grands plateaux de SOL HAUT à gauche, au centre et à droite ; au centre, un BASSIN d'eau parcouru par un COURANT (chevrons) qui descend jusqu'en bas ; en haut, un chenal d'eau profonde ; en bas à gauche, la poche des rochers et des trous ; échelles et escaliers."),
	"iles_ecume_b4f": ("B4F", "PLAN_ILES_ECUME_B4F_v1.png", "le fond du donjon : deux MERS souterraines séparées, l'eau turquoise sombre, le plafond bas ; un COURANT agite la mer de gauche (chevrons). EN HAUT À GAUCHE, au-dessus de l'escalier, la petite SALLE D'ARTIKODIN est NETTEMENT PLUS CLAIRE que tout le reste : une lumière blanc-bleu pâle tombe d'une fente du plafond sur un sol de glace lisse ; c'est le cœur du donjon, calme et solennel.",
		"Deux mers séparées par une langue de SOL HAUT au centre : la mer de gauche (verticale, avec un courant en bas à gauche) et la grande mer de droite ; au centre, une plateforme de SOL HAUT avec une échelle ; en haut à gauche, la petite salle d'Artikodin (SOL HAUT, au-dessus d'un escalier) ; en haut à droite, un plateau avec une échelle et un panneau ; en bas au centre, un plateau avec un panneau."),
}
for _cle, (_etage, _plan, _lumiere, _forme) in ETAGES.items():
	VUES[_cle] = {
		"titre": f"VUE GÉNÉRALE DES ÎLES ÉCUME, ÉTAGE {_etage} (grotte de glace)", "plan_png": _plan,
		"image2": "la vue générale du Mont Sélénite, une autre grotte du même jeu. Respecte EXACTEMENT son style de rendu : même pinceau, même saturation, même finesse de détail, même traitement de la ROCHE et des parois, même lisibilité du sol. Ne reprends RIEN de sa composition ni de ses couleurs chaudes : ici, tout est GLACE et EAU (ni lampes, ni caisses, ni échelles de chantier en dehors de celles du plan, ni fossiles).",
		"format": "PAYSAGE 1536 × 1024",
		"plan": f"Un étage d'une grotte de glace, vu du dessus. {_forme}",
		"legende": LEGENDE_GROTTE, "regle": REGLE_GROTTE,
		"ambiance": AMBIANCE_GROTTE + f"\n- La lumière BAISSE à chaque étage. Ici : {_lumiere}",
		"vie": ("VIE : dans la petite salle claire en haut à gauche, ARTIKODIN, le grand oiseau légendaire de glace "
			"(plumage bleu glace, longue queue de plumes bleu pâle, crête de trois plumes bleu sombre), POSÉ au sol, "
			"ailes repliées, tourné vers le bas, un léger souffle de givre devant son bec ; petit à l'échelle de la "
			"carte (environ deux cases de haut). Aucun autre Pokémon, aucun personnage, aucun animal.")
			if _cle == "iles_ecume_b4f" else
			"PERSONNE : aucun personnage, aucun Pokémon, aucun animal (les rochers de Force sont des rochers ronds clairs et fendus, pas des créatures).",
		"interdits": "Ni lave, ni lampe, ni caisse, ni champignon lumineux, ni cristaux géants, ni ciel.",
		"recit": f"un étage d'un donjon de glace et d'eau ({_etage}), où l'on pousse des rochers dans des trous pour calmer les courants.",
	}

## Vue → révision retenue après relecture (2026-10-19) : toutes en r1.
VUES_RETENUES: dict[str, int] = {nom: 1 for nom in ("route19", "route20", "route21_nord", "route21_sud",
	"cramois_ile", "iles_ecume_1f", "iles_ecume_b1f", "iles_ecume_b2f", "iles_ecume_b3f", "iles_ecume_b4f")}
NOMS_REFERENCE = {"route19": "route-19", "route20": "route-20", "route21_nord": "route-21-nord",
	"route21_sud": "route-21-sud", "cramois_ile": "cramois-ile", "iles_ecume_1f": "iles-ecume-1f",
	"iles_ecume_b1f": "iles-ecume-b1f", "iles_ecume_b2f": "iles-ecume-b2f", "iles_ecume_b3f": "iles-ecume-b3f",
	"iles_ecume_b4f": "iles-ecume-b4f"}
IMAGE2_VUE = {"route19": VUE_ROUTE25, "route20": VUE_ROUTE25, "route21_nord": VUE_ROUTE25,
	"route21_sud": VUE_ROUTE25, "cramois_ile": VUE_CARMIN}


def _ident_vue(nom: str) -> str:
	return f"CONCEPT_{nom.upper()}_VUE_GENERALE"


# --- Table des images ------------------------------------------------------------------------------

def _images() -> list[dict]:
	images: list[dict] = []

	def ajouter(base: str, texte: str, jointes: list[str], groupe: str, rev: int | None = 1) -> None:
		nom = f"{base}_r{rev}" if rev is not None else base
		images.append({"nom": nom, "base": base, "texte": texte, "jointes": jointes, "groupe": groupe,
			"fichier": PROMPTS / f"{nom}.txt"})

	ajouter("SURF_MONTURE_NE", prompt_monture("SURF_MONTURE"), [HEROS, RAPASDEPIC], "surf")
	ajouter("HEROS_SURF_NE", prompt_heros_surf("HEROS_SURF"), [HEROS, "SURF_MONTURE_NE_r1.png"], "surf")
	ajouter("PNJ_NAGEUR_EAU_NE", prompt_nageur_eau("PNJ_NAGEUR_EAU", False), [HEROS, NAGEUR], "nageurs")
	ajouter("PNJ_NAGEUSE_EAU_NE", prompt_nageur_eau("PNJ_NAGEUSE_EAU", True), [HEROS, NAGEUSE], "nageurs")
	ajouter("PNJ_TOPDRESSEUR_NE", prompt_marche("PNJ_TOPDRESSEUR", GARDE[:-4], TOPDRESSEUR), [HEROS, GARDE], "top")
	ajouter("PNJ_TOPDRESSEUSE_NE", prompt_marche("PNJ_TOPDRESSEUSE", "dresseuse_sheet", TOPDRESSEUSE),
		[HEROS, DRESSEUSE], "top")
	ajouter("WORLD_PROP_FORCE_PLANCHE_NE", prompt_force("WORLD_PROP_FORCE_PLANCHE"),
		[ROCHER_GROTTE, ROCHER, ROCHER_MER, SOL_GROTTE], "force")
	ajouter("POKE_ARTIKODIN_MONDE_NE", prompt_artikodin("POKE_ARTIKODIN_MONDE"),
		[f"{OFFICIEL}/144.png", RAPASDEPIC, ROUCOUPS], "artikodin")
	ajouter("POKE_ARTIKODIN_MONDE_NE", prompt_artikodin("POKE_ARTIKODIN_MONDE", variante=2),
		[HEROS, RAPASDEPIC, ROUCOUPS], "artikodin2", rev=2)
	ajouter("POKE_ARTIKODIN_MONDE_NE", prompt_artikodin("POKE_ARTIKODIN_MONDE", variante=3),
		["POKE_ARTIKODIN_MONDE_NE_r1.png", RAPASDEPIC, ROUCOUPS], "artikodin3", rev=3)
	ajouter("WORLD_GROUND_COURANT_01_NE", prompt_texture("WORLD_GROUND_COURANT_01", COURANT, "ground_eau_01"),
		[SOL_EAU], "sols")
	ajouter("WORLD_GROUND_EAU_GROTTE_01_NE", prompt_texture("WORLD_GROUND_EAU_GROTTE_01", EAU_GROTTE,
		"ground_eau_01 et ground_grotte_01"), [SOL_EAU, SOL_GROTTE], "sols")
	ajouter("WORLD_GROUND_GLACE_01_NE", prompt_texture("WORLD_GROUND_GLACE_01", GLACE, "ground_grotte_01"),
		[SOL_GROTTE], "sols")
	ajouter("COMBAT_DECOR_MER_OUVERTE", prompt_combat("COMBAT_DECOR_MER_OUVERTE", "MER OUVERTE, EN SURF",
		"la vue générale (de dessus) de la Route 20 : mer turquoise et bleu profond, île aux falaises blanches, "
		"récifs gris (guide de palette).", MER_DESC, MER_COMPO, MER_LUMIERE, MER_INTERDITS),
		[COMBAT_REF, COMBAT_PLANCHE, "CONCEPT_ROUTE20_VUE_GENERALE_r1.png"], "combat")
	ajouter("COMBAT_DECOR_GROTTE_GLACEE", prompt_combat("COMBAT_DECOR_GROTTE_GLACEE", "GROTTE GLACÉE, ÎLES ÉCUME",
		"la vue générale (de dessus) d'un étage des Îles Écume : roche bleu-gris, glace, eau turquoise (guide de "
		"palette).", GROTTE_DESC, GROTTE_COMPO, GROTTE_LUMIERE, GROTTE_INTERDITS),
		[COMBAT_REF, COMBAT_PLANCHE, "CONCEPT_ILES_ECUME_B3F_VUE_GENERALE_r1.png"], "combat")
	tuile = TUILE.read_text()
	for decor in ("COMBAT_DECOR_MER_OUVERTE", "COMBAT_DECOR_GROTTE_GLACEE"):
		for cote in ("TL", "TR"):
			ajouter(f"{decor}_r1_{cote}", tuile, [f"{decor}_r1_{cote}_SOURCE.png"], "tuiles", rev=None)
	for espece in DOS:
		ajouter(f"DOS_{espece}", prompt_dos(f"DOS_{espece}", espece, True),
			[f"{OFFICIEL}/{DOS[espece][0]}.png", *DOS_ANCRES], "dos")
	for salle, (plan, *_reste) in LABO_SALLES.items():
		ajouter(f"INT_LABO_CRAMOIS_{salle}_COQUE_NE", prompt_coque(f"INT_LABO_CRAMOIS_{salle}_COQUE", salle),
			[f"build/plans/PLAN_{plan.upper()}_v1.png", COQUE_LABO, COQUE_CENTRE], "labo")
	for nom in VUES:
		image2 = IMAGE2_VUE.get(nom, VUE_SELENITE)
		ajouter(_ident_vue(nom), prompt_vue(nom), [f"build/plans/{VUES[nom]['plan_png']}", image2], "vues")
	return images


def ecrire_prompts() -> None:
	changes = 0
	images = _images()
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in images:
		if not image["fichier"].exists() or image["fichier"].read_text() != image["texte"]:
			image["fichier"].write_text(image["texte"])
			changes += 1
	print(f"{len(images)} prompts ({changes} écrit(s)) : {PROMPTS.relative_to(RACINE)}")


def ancres() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	manquantes = []
	sources = [PRINCIPAL / "build" / "art",
		*sorted((PRINCIPAL / ".claude" / "worktrees").glob("*/build/art"))]
	for nom in sorted({j for i in _images() for j in i["jointes"] if "/" not in j}):
		if (ART / nom).exists():
			continue
		source = next((s / nom for s in sources if (s / nom).exists()), None)
		if source is None:
			manquantes.append(nom)
		else:
			shutil.copy2(source, ART / nom)
	print("ancres copiées" + (f" ; ABSENTES (ou générées par la série) : {', '.join(manquantes)}"
		if manquantes else ""))


def _chemin(j: str) -> Path:
	return RACINE / j if "/" in j else ART / j


def commandes() -> str:
	lignes = [f"ART={ART}"]
	for i in _images():
		jointes = " ".join(str(_chemin(j)) for j in i["jointes"])
		lignes.append(f"tools/art/generer.sh {i['nom']} {i['fichier'].relative_to(RACINE)} {jointes}".rstrip())
	return "\n".join(lignes)


JOURNAL_REFUS = "refus_serie27.log"
SANS_JOINTE = ("(Aucune image n'est jointe à cette demande : les « images jointes » citées plus bas ne "
	"sont PAS disponibles ; applique leur description écrite et ne cherche pas à les voir.)\n\n")


def _consigner(nom: str, ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with (ART / JOURNAL_REFUS).open("a") as journal:
		journal.write(f"{nom} : {ligne}\n")


def _generer(image: dict) -> str:
	nom = image["nom"]
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	jointes = [_chemin(j) for j in image["jointes"]]
	derniere = ""
	for essai in range(2):
		derniere = serie10._lancer(nom, image["texte"], jointes)
		if derniere.endswith(": ok"):
			return derniere + (f" (essai {essai + 1} avec ancres)" if essai else "")
		_consigner(nom, f"refus ou échec AVEC ancres, essai {essai + 1} : {derniere[-160:]}")
	if not jointes or image["groupe"] in ("tuiles", "vues", "labo"):
		# Sans le plan ou la portion à agrandir, l'image n'a pas de sens : pas d'essai sans pièce jointe.
		return derniere
	for essai in range(2):
		derniere = serie10._lancer(nom, SANS_JOINTE + image["texte"], [])
		if derniere.endswith(": ok"):
			_consigner(nom, f"obtenu SANS pièce jointe (essai {essai + 1})")
			return derniere + " (SANS pièce jointe)"
		_consigner(nom, f"refus ou échec SANS pièce jointe, essai {essai + 1} : {derniere[-160:]}")
	return derniere


def generer(choix: set[str]) -> None:
	ancres()
	for image in _images():
		if choix and image["nom"] not in choix and image["base"] not in choix and image["groupe"] not in choix:
			continue
		if not image["fichier"].exists():
			print(f"prompt absent (lancer --prompts) : {image['fichier']}")
			sys.exit(1)
		print(_generer(image), flush=True)


def tuiles() -> None:
	"""Portions TL / TR des compositions de combat (comme les décors existants : moitié + 154 px sur
	1846), jointes à Codex pour l'agrandissement (prompt COMBAT_DECOR_TUILE_r1)."""
	for decor in ("COMBAT_DECOR_MER_OUVERTE", "COMBAT_DECOR_GROTTE_GLACEE"):
		source = ART / f"{decor}_r1.png"
		if not source.exists():
			print(f"{source.name} absent")
			continue
		im = Image.open(source).convert("RGB")
		w, h = im.size
		part = round(w * TUILE_PART)
		im.crop((0, 0, part, h)).save(ART / f"{decor}_r1_TL_SOURCE.png")
		im.crop((w - part, 0, w, h)).save(ART / f"{decor}_r1_TR_SOURCE.png")
		print(f"{decor} : portions [0, 0, {part}, {h}] et [{w - part}, 0, {w}, {h}]")


# --- Planche de contact à l'échelle du jeu -------------------------------------------------------

def _boite_visible(image: Image.Image) -> Image.Image:
	alpha = image.getchannel("A").point(lambda v: 255 if v > 40 else 0)
	boite = alpha.getbbox()
	return image.crop(boite) if boite else image


def _cellules(image: Image.Image, colonnes: int, lignes: int) -> list[list[Image.Image]]:
	cw, ch = image.width // colonnes, image.height // lignes
	return [[image.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)) for c in range(colonnes)]
		for r in range(lignes)]


def _juxtaposer(poses: list[Image.Image], ecart: int = 14) -> Image.Image:
	largeur = sum(p.width for p in poses) + ecart * len(poses)
	composite = Image.new("RGBA", (largeur, max(p.height for p in poses)), (0, 0, 0, 0))
	x = 0
	for p in poses:
		composite.alpha_composite(p, (x, composite.height - p.height))
		x += p.width + ecart
	return composite


def _sur_eau(image: Image.Image, marge: int = 10) -> Image.Image:
	"""Pose une image sur un aplat d'eau (rendu en jeu : l'eau est peinte dessous)."""
	eau = Image.open(RACINE / SOL_EAU).convert("RGBA")
	fond = Image.new("RGBA", (image.width + 2 * marge, image.height + 2 * marge))
	for y in range(0, fond.height, eau.height):
		for x in range(0, fond.width, eau.width):
			fond.alpha_composite(eau, (x, y))
	fond.alpha_composite(image, (marge, marge))
	return fond


def _derniere(base: str) -> Path | None:
	for rev in (5, 4, 3, 2, 1):
		candidat = ART / f"{base}_r{rev}.png"
		if candidat.exists():
			return candidat
	return None


def _planche_4x4(image: Image.Image, colonnes: int, lignes: int, hauteur_face: int,
		toutes_colonnes: bool = False) -> Image.Image:
	"""Les 4 orientations (1re colonne) à l'échelle du jeu, même facteur pour toutes : la pose de
	face mesure `hauteur_face` ; avec `toutes_colonnes`, la ligne de face entière (animation)."""
	cells = _cellules(image, colonnes, lignes)
	face = _boite_visible(cells[0][0])
	facteur = hauteur_face / face.height
	if toutes_colonnes:
		poses = [_boite_visible(c) for c in cells[0]] + [_boite_visible(cells[r][0]) for r in range(1, lignes)]
	else:
		poses = [_boite_visible(cells[r][0]) for r in range(lignes)]
	return _juxtaposer([_echelle(p, facteur) for p in poses])


def _vignette(chemin: Path, largeur: int) -> Image.Image:
	im = Image.open(chemin).convert("RGBA")
	return _echelle(im, largeur / im.width)


def contact(sortie: Path) -> Path:
	"""Les images GÉNÉRÉES de la série à l'échelle du jeu : 1 case = 96 px, héros de 128 px (repère).
	Monture et héros en Surf, Nageurs dans l'eau : posés sur l'eau du jeu. Dernière révision présente
	de chaque image."""
	heros_sheet = RACINE / PAINTED / "heros_sheet.png"
	h = Image.open(heros_sheet).convert("RGBA")
	heros = (_boite_visible(h.crop((0, 0, h.width // 4, h.height // 4))), "héros 128 px\n(repère)")
	nageur = Image.open(RACINE / NAGEUR).convert("RGBA")
	nageur_terre = (_boite_visible(nageur.crop((0, 0, nageur.width // 4, nageur.height // 4))),
		"nageur à terre\n(J13, réemploi)")
	p = _Planche(3000, "Série 27 générée (lot 24.0, jalon 24) : À L'ÉCHELLE DU JEU, 1 case = 96 px ; héros 128 px")
	sections: dict[str, list[tuple[Image.Image, str]]] = {}

	def montrer(section: str, image: Image.Image, texte: str) -> None:
		sections.setdefault(section, []).append((image, texte))

	f = _derniere("SURF_MONTURE_NE")
	if f:
		im = Image.open(f).convert("RGBA")
		cells = _cellules(im, 4, 4)
		profil = _boite_visible(cells[1][0])
		facteur = 104 / profil.width   # monture ≈ 1,1 case de long de profil [D]
		poses = [_echelle(_boite_visible(cells[r][0]), facteur) for r in range(4)]
		anim = [_echelle(_boite_visible(c), facteur) for c in cells[1]]
		montrer("SURF (sur l'eau du jeu)", _sur_eau(_juxtaposer(poses)), f"{f.stem}\nface, gauche, droite, dos (≈ 104 px)")
		montrer("SURF (sur l'eau du jeu)", _sur_eau(_juxtaposer(anim)), f"{f.stem}\nprofil gauche : 4 images")
	f = _derniere("HEROS_SURF_NE")
	if f:
		im = Image.open(f).convert("RGBA")
		# Même échelle que la planche de marche du héros (cellule 256 × 384, héros ≈ 320 px → 128 px).
		cells = _cellules(im, 4, 4)
		poses = [_echelle(_boite_visible(cells[r][0]), 0.4) for r in range(4)]
		anim = [_echelle(_boite_visible(c), 0.4) for c in cells[0]]
		montrer("SURF (sur l'eau du jeu)", heros[0], heros[1])
		montrer("SURF (sur l'eau du jeu)", _sur_eau(_juxtaposer(poses)), f"{f.stem}\n× 0,4 (échelle de la marche)")
		montrer("SURF (sur l'eau du jeu)", _sur_eau(_juxtaposer(anim)), f"{f.stem}\nface : 4 images")
	for base, titre in (("PNJ_NAGEUR_EAU_NE", "nageur"), ("PNJ_NAGEUSE_EAU_NE", "nageuse")):
		f = _derniere(base)
		if f:
			im = Image.open(f).convert("RGBA")
			cells = _cellules(im, 4, 4)
			poses = [_echelle(_boite_visible(cells[r][0]), 0.4) for r in range(4)]
			montrer("NAGEURS DANS L'EAU (sur l'eau du jeu)", _sur_eau(_juxtaposer(poses)),
				f"{f.stem}\n× 0,4 (échelle de la marche)")
	if "NAGEURS DANS L'EAU (sur l'eau du jeu)" in sections:
		sections["NAGEURS DANS L'EAU (sur l'eau du jeu)"].insert(0, nageur_terre)
	for base in ("PNJ_TOPDRESSEUR_NE", "PNJ_TOPDRESSEUSE_NE"):
		f = _derniere(base)
		if f:
			im = Image.open(f).convert("RGBA")
			montrer("TOPDRESSEURS (128 px)", _planche_4x4(im, 4, 4, 128), f"{f.stem}\nface, gauche, droite, dos")
	if "TOPDRESSEURS (128 px)" in sections:
		sections["TOPDRESSEURS (128 px)"].insert(0, heros)
	f = _derniere("WORLD_PROP_FORCE_PLANCHE_NE")
	if f:
		im = Image.open(f).convert("RGBA")
		cols = [_boite_visible(c) for c in _cellules(im, 4, 1)[0]]
		facteur = 96 / cols[0].width   # rocher de Force = 1 case de large
		montrer("FORCE ET ARTIKODIN", heros[0], heros[1])
		for i, (c, t) in enumerate(zip(cols, ("rocher de Force", "rocher dans l'eau", "trou", "trou bouché"))):
			image = _echelle(c, facteur)
			montrer("FORCE ET ARTIKODIN", _sur_eau(image) if i == 1 else image, f"{f.stem}\n{t} (1 case = 96)")
		autres = Image.open(RACINE / ROCHER_GROTTE).convert("RGBA")
		montrer("FORCE ET ARTIKODIN", autres, "rocher décor de grotte\n(existant)")
	f = _derniere("POKE_ARTIKODIN_MONDE_NE")
	if f:
		im = Image.open(f).convert("RGBA")
		poses = [_boite_visible(c) for c in _cellules(im, 4, 1)[0]]
		facteur = 163 / poses[0].height   # ≈ 1,7 case [D]
		montrer("FORCE ET ARTIKODIN", _juxtaposer([_echelle(q, facteur) for q in poses]),
			f"{f.stem}\n≈ 163 px (1,7 case) : repos, inspire, souffle, repos")
	for base, texte in (("WORLD_GROUND_COURANT_01_NE", "courant (vers le bas)"),
			("WORLD_GROUND_EAU_GROTTE_01_NE", "eau de grotte"), ("WORLD_GROUND_GLACE_01_NE", "sol de glace")):
		f = _derniere(base)
		if f:
			im = Image.open(f).convert("RGBA").resize((384, 384), Image.LANCZOS)
			grand = Image.new("RGBA", (768, 384))
			grand.alpha_composite(im, (0, 0))
			grand.alpha_composite(im, (384, 0))
			montrer("SOLS (384 px = 4 cases, répétés 2 fois)", grand, f"{f.stem}\n{texte}")
	for decor in ("COMBAT_DECOR_MER_OUVERTE", "COMBAT_DECOR_GROTTE_GLACEE"):
		f = _derniere(decor)
		if f:
			montrer("COMBAT (fonds réduits, dos réduits)", _vignette(f, 900), f"{f.stem}\nfond de combat (réduit)")
	for espece in DOS:
		f = _derniere(f"DOS_{espece}")
		if f:
			v = _boite_visible(Image.open(f).convert("RGBA"))
			montrer("COMBAT (fonds réduits, dos réduits)", _echelle(v, 300 / v.height),
				f"{f.stem}\ndos de combat (≈ 300 px)")
	for salle in LABO_SALLES:
		f = _derniere(f"INT_LABO_CRAMOIS_{salle}_COQUE_NE")
		if f:
			montrer("LABO DE CRAMOIS'ÎLE (coques réduites)", _vignette(f, 700), f"{f.stem}\ncoque (réduite)")
	for titre, elements in sections.items():
		fond = (30, 34, 48) if titre.startswith(("COMBAT", "LABO")) else (60, 80, 110)
		p.section(titre, elements, fond)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	print(f"{sum(len(e) for e in sections.values())} éléments")
	return sortie


def vues() -> None:
	"""Copie les vues RETENUES (VUES_RETENUES) et leurs plans dans docs/design/reference/."""
	for nom, rev in VUES_RETENUES.items():
		source = ART / f"{_ident_vue(nom)}_r{rev}.png"
		cible = RACINE / REFERENCE / f"{NOMS_REFERENCE[nom]}-vue-generale-v1.png"
		shutil.copyfile(source, cible)
		shutil.copyfile(PLANS / VUES[nom]["plan_png"], RACINE / REFERENCE / f"{NOMS_REFERENCE[nom]}-plan-v1.png")
		print(cible.relative_to(RACINE))


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		ecrire_prompts()
	elif "--ancres" in arguments:
		ancres()
	elif "--commandes" in arguments:
		print(commandes())
	elif "--tuiles" in arguments:
		tuiles()
	elif "--contact" in arguments:
		autres = [a for a in arguments if a != "--contact"]
		print(contact(Path(autres[0]) if autres else RACINE / "build" / "art" / "J24_KIT_v1.png"))
	elif "--vues" in arguments:
		vues()
	else:
		generer(set(arguments))
