#!/usr/bin/env python3
"""Série 23 — lot d'art 21.0 du jalon 21 (« Le Repos des esprits » : 7F de la Tour, Route 12 nord,
Route 16 est). Fiche : docs/design/fiches-assets/serie-23-repos-des-esprits.md ; conception :
dossier 24 §14.4 et plan `docs/tech/jalon-21.md` §2.16 (T6, T7, T8).

**Numéro** : 23 (constaté le 2026-10-15 sur toutes les branches : fiches 01, 12 à 17, 19, 20 ; la 18
du J16 et les 21 / 22 laissées aux J18 et J20 par le plan §2.16). « Le second fusionné renumérote » :
à revérifier au push (fiche, ce fichier, `prompts/serie23/`, mentions des docs).

Ce que contient la série (SANS intégration : ni `assets/`, ni manifeste, ni `.tres`) :
  - PNJ_FUJI + PNJ_FUJI_PRIERE : M. Fuji, marche 4 × 4 et planche de prière agenouillée ;
  - POKE_OSSELAIT : Osselait, sprite de monde (≈ 56 px), marche 4 × 4 ;
  - DOS_RONFLEX : dos de combat de Ronflex (provisoire IA, pas de modèle 3D X/Y local) ;
  - FX_NOTES_PLANCHE : notes de musique de la Poké Flûte (effet `FluteNotes`) ;
  - FX_HALO_SPIRIT : halo pâle du `SpiritLight` ;
  - UI_OBJETS_J21_PLANCHE : icône peinte de la Poké Flûte (modèle des planches du Sac) ; l'icône
    vectorielle `poke_flute.svg` est écrite à la main par `--svg` (`assets/ui/icons/items/`, style
    de `potion.svg`) et reste dans build/ tant que Kevin n'a pas validé.
Les vues générales (7F, Route 12, Route 16) sont dans `plan_aplats_j21.py` + `prompts/CONCEPT_*`.

**Les prompts sont versionnés** : `tools/art/prompts/serie23/<NOM>_rN.txt`, écrits par `--prompts`.
**Règle de Kevin pour Codex** : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais) ;
refus consignés dans `$ART/refus_serie23.log`.

Usage :
  tools/art/serie23.py --prompts            écrit les prompts (sans Codex)
  tools/art/serie23.py --ancres             copie dans $ART les ancres absentes (checkout principal)
  tools/art/serie23.py --commandes          liste les appels generer.sh
  tools/art/serie23.py [NOM ...]            génère avec Codex (sans argument : tout le lot)
  tools/art/serie23.py --contact [sortie]   planche de contact À L'ÉCHELLE DU JEU
                                            (défaut build/art/J21_KIT_v1.png)
  tools/art/serie23.py --halo [sortie.png]  halo pâle PROCÉDURAL (FX_HALO_SPIRIT_NE_r2 : repli du r1 peint)
  tools/art/serie23.py --svg [sortie.svg]   icône vectorielle de la Poké Flûte
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
from serie06 import ADN, LUMIERE_NE, RACINE  # noqa: E402
from serie10 import _Planche, _echelle  # noqa: E402
from serie10_menu import RENDU  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
serie10.ART = ART
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026")
PROMPTS = ICI / "prompts" / "serie23"
OFFICIEL = "assets/sprites/pokemon/official"
CASE_JEU = 96

HEROS = "PERSO_P2_PEINT_r1.png"
RATTATA = "POKE_RATTATA_P2_r1.png"
CHEN = "PNJ_CHEN_NE_r1.png"
MENU_OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
DOS_ANCRES = ["assets/sprites/pokemon/battle_proto/dos_ia_095.png",
	"assets/sprites/pokemon/battle_proto/dos_ia_093.png"]
POTION = "assets/ui/items/potion.webp"
PIERRE_LUNE = "assets/ui/items/moon_stone.webp"
SOL_POKE = "les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule"

INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, AUCUN emblème rond de type balle (ni "
	"cercle partagé en deux, ni médaillon à bande centrale) nulle part, animaux réels ou faune "
	"non-Pokémon (oiseaux, mouettes, poissons, insectes, chauves-souris), Pikachu et tout Pokémon non "
	"demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac à dos jaune), "
	"élément effrayant.")

FUJI = ("M. FUJI, un VIEIL HOMME doux et bienveillant d'environ 75 ans, gardien d'une maison où l'on "
	"recueille des Pokémon : cheveux blancs mi-longs et fins, peignés en arrière, petite barbe blanche "
	"courte et soignée, petites LUNETTES rondes à fine monture dorée, sourcils blancs, regard bienveillant, "
	"joues un peu rosées ; une longue VESTE ample à col droit vert sapin (sans boutons apparents), une "
	"ceinture de tissu beige nouée, une chemise crème dessous, un pantalon brun clair large, des souliers "
	"de toile bruns, un CHAPELET de perles de bois brun autour du poignet gauche. Dos légèrement voûté, "
	"mains vides, AUCUNE canne. Différent du héros joint, du Professeur Chen joint (ni blouse blanche, ni "
	"cheveux bruns) et du vieil homme générique du jeu (qui est chauve, en gilet marron, avec une canne) ; "
	"aucun texte.")


def _jointes(noms: list[str]) -> str:
	return " et ".join(Path(n).stem for n in noms)


def prompt_fuji_marche(identifiant: str) -> str:
	texte_ref = f" ; {CHEN[:-4]} = même main et même finesse pour un vieil homme (à NE PAS copier : autre visage, autre tenue)"
	return MODELE_MARCHE.format(ident=identifiant, ref=texte_ref, tenue=FUJI) + INTERDITS + "\n"


def prompt_fuji_priere(identifiant: str) -> str:
	return f"""{identifiant} — planche de POSES de prière d'un PNJ de Kanto 2026 : le même personnage que la planche de marche jointe PNJ_FUJI_NE_r1, À GENOUX.
Style : exactement le rendu des planches jointes (le héros validé PERSO_P2_PEINT_r1 et la planche de marche de M. Fuji PNJ_FUJI_NE_r1) : personnage peint simplifié, chibi d'environ 3 têtes, même finesse, même contour fin coloré sans trait noir, mêmes proportions, même manière de peindre le visage et les vêtements. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

PERSONNAGE (identique dans toutes les images, EXACTEMENT celui de PNJ_FUJI_NE_r1) : {FUJI}

PLANCHE : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné). UNE seule ligne de 4 poses, de gauche à droite, chaque pose dans une colonne invisible de 384 px de large, bien séparées par du vide, la pose ENTIÈRE dans sa colonne, à la MÊME ÉCHELLE dans les 4 poses (environ 250 px de haut, c'est-à-dire un peu plus bas que le personnage debout puisqu'il est à genoux), la base des 4 poses (les genoux et les souliers) sur une même ligne horizontale.
Il est AGENOUILLÉ (les deux genoux au sol, assis sur ses talons), le dos droit, en PRIÈRE : les mains jointes devant la poitrine, le chapelet de bois entre les doigts, la tête légèrement inclinée.
- Pose 1 : de DOS (tourné vers le haut de l'écran, il prie face à un autel qu'on ne voit pas), mains jointes ; au repos.
- Pose 2 : de DOS, même pose, mais le dos et les épaules un peu plus inclinés vers l'avant, comme un souffle ou une inclinaison de la tête (différence douce, même silhouette).
- Pose 3 : de PROFIL, tourné vers la GAUCHE, agenouillé, mains jointes.
- Pose 4 : de FACE (tourné vers le bas de l'écran), agenouillé, mains jointes devant lui, les yeux fermés.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus de la tête). Pas de perspective, pas d'ombre au sol, pas de sol, pas de coussin, pas d'autel, pas de bougie, pas de texte, pas de numéros, pas de cadres.
Le visage, les couleurs, les proportions et les vêtements doivent être EXACTEMENT les mêmes que dans la planche de marche.
{INTERDITS}
"""


OSSELAIT = ("OSSELAIT (Cubone, n° 104 de la première génération), fidèle à son design officiel (voir l'artwork "
	"joint) : un tout petit Pokémon brun clair au corps rond et trapu, bipède, qui porte sur la tête un "
	"CRÂNE BLANC cassé de Pokémon (casque d'os crème, deux orbites sombres) dont on ne voit que la partie "
	"supérieure du visage : deux petits yeux noirs et brillants dans les trous du crâne, un petit museau "
	"brun ; une courte queue brune ; il tient devant lui, des deux mains, un petit OS crème (massue). Air "
	"triste, doux et solitaire, JAMAIS agressif ni effrayant ; le crâne est un casque, pas un visage "
	"fantomatique.")


OSSELAIT_R2 = ("un tout petit Pokémon de dessin animé, brun clair, au corps rond et trapu, bipède, qui porte "
	"sur la tête un grand CASQUE BLANC CRÈME en céramique, arrondi, aux bords un peu ébréchés, percé de deux "
	"trous ronds par lesquels on voit deux petits yeux noirs et brillants ; un petit museau brun, une courte "
	"queue brune ; il tient devant lui, des deux mains, un petit BÂTON CRÈME à bout arrondi. Air doux, "
	"timide et un peu triste, très mignon, comme un enfant qui attend quelqu'un ; le casque est un simple "
	"couvre-chef.")


def prompt_osselait(identifiant: str, variante: int = 1) -> str:
	creature = OSSELAIT if variante == 1 else OSSELAIT_R2
	ref3 = ("La troisième image jointe est l'artwork officiel d'Osselait : anatomie, couleurs et proportions "
		"seulement (pas son rendu).") if variante == 1 else ""
	return f"""{identifiant} — planche d'animation d'un Pokémon du monde (Pokémon d'ambiance, qui attend dans une maison).
Style : exactement le rendu de la première planche jointe (le héros du jeu) : Pokémon peint simplifié, même finesse, même contour fin coloré sans trait noir, même manière de peindre les volumes. Ni pixel art, ni 3D, ni anime aux contours noirs.
{LUMIERE_NE}

POKÉMON (identique dans toutes les images) : {creature}

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose du Pokémon, entier, centré horizontalement, {SOL_POKE} (environ 160 px de haut, un peu plus grand que le repère Rattata qui est l'autre image jointe). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran).
- Colonnes : marche lente en 4 images, petits pas trottinés, la queue et l'os qui balancent un peu ; aux images 1 et 3, pieds joints (passage).
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus du crâne). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.

La deuxième image jointe ({RATTATA[:-4]}) est un autre Pokémon du jeu, déjà validé : même rendu, même finesse, même gabarit de planche ; garde ses proportions comme repère de style (Osselait est un peu plus grand et bipède : environ 56 px de haut dans le jeu contre 40 px). {ref3}
{INTERDITS}
"""


def prompt_dos_ronflex(identifiant: str, avec_ancres: bool, variante: int = 1) -> str:
	ancres = ("IMAGE 1 : l'artwork officiel de face de Ronflex (Snorlax, n° 143) : anatomie, couleurs, "
		"proportions et style de rendu (pas la pose : on le veut de dos).\nIMAGE 2 : un autre Pokémon de dos "
		"déjà produit pour ce jeu (Onix, dos) : reprends son ANGLE de vue (trois quarts dos, regard vers le "
		"haut à droite), son cadrage et sa famille de rendu (contour brun foncé fin, aplats nuancés, "
		"transparence) ; ne reprends ni sa forme ni ses couleurs.\nIMAGE 3 : Spectrum de dos, même rendu.") \
		if avec_ancres else "Aucune image jointe."
	if variante == 3:
		return f"""ILLUSTRATION DE JEU VIDÉO : une grosse créature de dessin animé vue de dos, pour l'écran d'un jeu de combat au tour par tour. Aucune image n'est jointe.

SUJET : un énorme ours-chat paresseux et rond, bleu-vert très sombre (presque bleu nuit) sur le dos, les épaules et la tête, aux deux petites oreilles pointues, avec un gros ventre crème que l'on devine seulement sur le côté. Il est ASSIS DROIT, lourdement, comme sur une chaise basse, et il tourne le DOS au spectateur : on voit son énorme dos arrondi, ses larges épaules, ses deux courts bras épais le long du corps et l'arrière de sa grosse tête ronde avec les deux oreilles. Ses jambes sont devant lui, cachées par son corps : on ne voit AUCUNE plante de pied ni aucune patte, juste le bas du dos qui touche le sol. Vue de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; sa tête est tournée un peu vers la droite (on devine le bord de sa joue crème), il regarde vers le haut à droite de l'image. Silhouette ramassée, un peu plus large que haute.

STYLE : trait fin et doux, aplats nuancés, comme les artworks officiels de la franchise ; ni pixel art, ni 3D, ni photo. LUMIÈRE neutre, diffuse, légèrement du haut à gauche.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE, centrée, qui occupe environ 85 % de la hauteur avec une marge vide autour (rien ne touche les bords), son bas à environ 120 px du bord bas. FOND : PNG avec une vraie transparence (canal alpha), aucun damier, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, décor, autre créature, personnage.
"""
	if variante == 2:
		return f"""ILLUSTRATION DE JEU VIDÉO : une grosse créature de dessin animé vue de dos, pour l'écran d'un jeu de combat au tour par tour.

IMAGE 1 jointe : la créature vue de face (artwork officiel) : couleurs, proportions et rendu ; IMAGE 2 jointe : une autre créature déjà vue de dos dans ce jeu : angle de vue, cadrage et style de contour.

SUJET : un énorme ours-chat paresseux et rond, bleu-vert très sombre sur le dos et la tête, aux petites oreilles pointues, avec un gros ventre crème que l'on devine sur le côté, assis lourdement et tourné le DOS au spectateur. Vue de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; il regarde vers le haut à droite de l'image. Silhouette ramassée, plus large que haute, gros pieds crème.

STYLE : le trait fin et doux, les aplats nuancés et la palette de l'artwork de face ; ni pixel art, ni 3D, ni photo. LUMIÈRE neutre, diffuse, légèrement du haut à gauche.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE, centrée, environ 85 % de la hauteur, son bas à environ 120 px du bord bas. FOND : PNG avec une vraie transparence (canal alpha), aucun damier, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, décor, autre créature, personnage.
"""
	return f"""POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). Le Pokémon est RONFLEX (Snorlax, n° 143), de la première génération.

{ancres}

SUJET : Ronflex, ÉNORME et massif, bleu-vert très sombre (gris-bleu foncé) sur le dos et les épaules, la tête ronde aux petites oreilles pointues, les deux courts bras épais ; on aperçoit un peu de son ventre crème sur le côté (il est assis lourdement, le dos tourné au spectateur). Silhouette ramassée, plus large que haute.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; Ronflex regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant lui). On voit l'arrière de la tête, le dos large, le bas du dos, une partie du pied crème (la plante de son pied gauche qui dépasse) et le côté de la joue ; AUCUN visage de face.

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, Ronflex ENTIER, centré, qui occupe environ 85 % de la hauteur, son bas à environ 120 px du bord bas ; rien n'est coupé par les bords. Une seule image fixe.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
"""


def prompt_notes(identifiant: str) -> str:
	return f"""{identifiant} — NOUVELLE image d'effet pour le jeu Kanto 2026 : des NOTES DE MUSIQUE peintes (l'effet de la Poké Flûte, des notes qui s'élèvent), pas une scène.
Images jointes : {HEROS[:-4]} = ancre de rendu (peint simplifié, contour fin coloré) ; n'en reproduis aucun personnage.

{RENDU}

IMAGE : PLANCHE de 4 notes de musique peintes isolées, dans une image 1536 × 1024 divisée en quatre colonnes invisibles de 384 px, UNE note CENTRÉE dans chaque colonne, chacune de 220 à 260 px de haut au plus, avec au moins 60 px de marge de chaque côté :
1 : une CROCHE simple (une tête de note ronde pleine, une hampe, un seul crochet) ;
2 : une paire de DOUBLES-CROCHES reliées par une double barre (deux têtes pleines) ;
3 : une NOIRE (une tête pleine et sa hampe, sans crochet) ;
4 : une CROCHE simple, inclinée de 15 degrés vers la droite, un peu plus petite.
Style de CHAQUE note : formes douces et arrondies, dessinées comme un petit objet précieux en trois quarts : tête de note ovale et luisante, hampe épaisse aux bouts arrondis, un léger relief ; couleur BLEU-TURQUOISE clair et lumineux avec un contour fin plus foncé (bleu nuit) et un petit reflet blanc ; jamais noires. Aucune portée, aucune ligne de portée, aucune clé de sol, aucun texte.
AUCUN halo, AUCUNE lueur, AUCUNE étincelle autour : chaque note est nette, avec seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).
Format : PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha).
{INTERDITS}
"""


def prompt_halo(identifiant: str) -> str:
	return f"""{identifiant} — NOUVELLE image d'effet de lumière pour le jeu Kanto 2026 : le HALO PÂLE d'un esprit apaisé (effet `SpiritLight`), pas une scène.

IMAGE : un seul HALO circulaire, doux, qui sera ajouté en lumière (mode additif) sur un sol de pierre sombre : un cœur presque blanc légèrement lilas, qui s'estompe sans aucune limite visible vers un bord complètement transparent ; la couleur passe du blanc (centre) au lilas très pâle puis au bleu pâle, à peine saturée ; la brillance est LISSE et CONTINUE (un dégagement radial parfaitement doux, sans anneau, sans bande, sans palier, sans grain, sans étoile, sans rayon, sans motif) ; un voile très léger de brume pâle autour, jamais une forme. Parfaitement circulaire et centré.
Format : PNG CARRÉ 1024 × 1024, fond TRANSPARENT (canal alpha) : l'opacité est maximale au centre (environ 90 %) et tombe à 0 avant le bord de l'image (rayon utile ≈ 480 px), aucune bordure nette ; aucun damier dessiné ; aucun personnage, aucun sol, aucun objet.
Interdits : texte, lettres, chiffres, logo, étoile, croix, symbole, visage, silhouette, particule nette, pixel art, 3D.
"""


def prompt_flute(identifiant: str) -> str:
	return f"""{identifiant} — NOUVELLE image pour l'interface (Sac) du jeu Kanto 2026, pas une capture d'écran.
Les images jointes donnent la direction artistique et la forme des objets ; n'en reproduis ni la mise en page ni les textes.

{RENDU}

IMAGE : PLANCHE d'UNE icône d'objet peinte pour le Sac, dans une image 1536 × 1024 divisée en quatre colonnes invisibles de 384 px : une icône CENTRÉE dans la PREMIÈRE colonne (x de 0 à 384), de 260 px de large au plus et 260 px de haut au plus, avec au moins 60 px de marge vide de chaque côté ; les trois autres colonnes restent VIDES (transparentes) ; dans le style EXACT de la planche jointe MENU_OBJETS_PLANCHE et des icônes jointes de la Potion et de la Pierre Lune (même rendu, même angle de trois quarts, même lumière).
1 (colonne 1) : la POKÉ FLÛTE, une petite flûte traversière droite posée en DIAGONALE (du bas gauche vers le haut droit) : un tube de métal bleu-turquoise clair lustré et ses reflets blancs, quelques anneaux dorés fins, un embout rond crème, cinq petits trous ronds foncés alignés, et un petit ruban de tissu rose qui pend de l'extrémité basse ; objet simple, propre, élégant, reconnaissable comme un instrument de musique ; jamais un cercle partagé en deux, aucune bande médiane de type balle.
AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour, AUCUNE note de musique : l'objet est net, avec seulement son contour fin, sur un fond entièrement transparent (canal alpha, aucune ombre).
Format : PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha).
{INTERDITS}
"""


# Table : (identifiant, fonction de prompt, jointes [noms dans $ART ou chemins relatifs « / »], groupe).
def _images() -> list[dict]:
	images: list[dict] = []

	def ajouter(base: str, texte: str, jointes: list[str], groupe: str, rev: int = 1) -> None:
		nom = f"{base}_r{rev}"
		images.append({"nom": nom, "base": base, "texte": texte, "jointes": jointes, "groupe": groupe,
			"fichier": PROMPTS / f"{nom}.txt"})

	ajouter("PNJ_FUJI_NE", prompt_fuji_marche("PNJ_FUJI"), [HEROS, CHEN], "fuji")
	ajouter("PNJ_FUJI_PRIERE_NE", prompt_fuji_priere("PNJ_FUJI_PRIERE"), [HEROS, "PNJ_FUJI_NE_r1.png"], "fuji")
	ajouter("POKE_OSSELAIT_NE", prompt_osselait("POKE_OSSELAIT"), [HEROS, RATTATA, f"{OFFICIEL}/104.png"],
		"osselait")
	ajouter("POKE_OSSELAIT_NE", prompt_osselait("POKE_OSSELAIT", 2), [HEROS, RATTATA], "osselait2", 2)
	ajouter("DOS_RONFLEX", prompt_dos_ronflex("DOS_RONFLEX", True), [f"{OFFICIEL}/143.png", *DOS_ANCRES],
		"dos")
	ajouter("DOS_RONFLEX", prompt_dos_ronflex("DOS_RONFLEX", True, 2),
		[f"{OFFICIEL}/143.png", DOS_ANCRES[0]], "dos2", 2)
	ajouter("DOS_RONFLEX", prompt_dos_ronflex("DOS_RONFLEX", False, 3), [], "dos3", 3)
	ajouter("FX_NOTES_PLANCHE_NE", prompt_notes("FX_NOTES_PLANCHE"), [HEROS], "fx")
	ajouter("FX_HALO_SPIRIT_NE", prompt_halo("FX_HALO_SPIRIT"), [], "fx")
	ajouter("UI_OBJETS_J21_PLANCHE", prompt_flute("UI_OBJETS_J21_PLANCHE"),
		[MENU_OBJETS, POTION, PIERRE_LUNE], "ui")
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


JOURNAL_REFUS = "refus_serie23.log"
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
	if not jointes:
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


# --- Planche de contact à l'échelle du jeu ----------------------------------------------------

HAUTEUR_PERSO = {"PNJ_FUJI_NE": 128}
HAUTEUR_POKE_MARCHE = {"POKE_OSSELAIT_NE": 56}


def _boite_visible(image: Image.Image) -> Image.Image:
	alpha = image.getchannel("A").point(lambda v: 255 if v > 40 else 0)
	boite = alpha.getbbox()
	return image.crop(boite) if boite else image


def _poses_bande(image: Image.Image, nombre: int) -> list[Image.Image]:
	largeur = image.width // nombre
	return [_boite_visible(image.crop((i * largeur, 0, (i + 1) * largeur, image.height)))
		for i in range(nombre)]


def _bande(poses: list[Image.Image], hauteur: float, reference: float) -> Image.Image:
	reduites = [_echelle(p, hauteur / reference) for p in poses]
	largeur = sum(p.width for p in reduites) + 12 * len(reduites)
	composite = Image.new("RGBA", (largeur, max(p.height for p in reduites)), (0, 0, 0, 0))
	x = 0
	for p in reduites:
		composite.alpha_composite(p, (x, composite.height - p.height))
		x += p.width + 12
	return composite


def _lignes_4x4(image: Image.Image) -> list[Image.Image]:
	"""Face, gauche, droite, dos : première colonne de la planche ; hauteur de référence = la
	cellule entière (les pieds sont posés à hauteur fixe : même échelle pour toutes les poses)."""
	return [_boite_visible(image.crop((0, r * image.height // 4 + 12, image.width // 4,
		(r + 1) * image.height // 4 - 12))) for r in range(4)]


def _echelle_cellule(image: Image.Image, hauteur_jeu: int) -> list[Image.Image]:
	"""Les 4 orientations à l'échelle du jeu : la pose de face mesure `hauteur_jeu`, les autres
	gardent la MÊME échelle (pas de ré-étalement pose par pose)."""
	lignes = _lignes_4x4(image)
	facteur = hauteur_jeu / lignes[0].height
	return [_echelle(p, facteur) for p in lignes]


def _juxtaposer(poses: list[Image.Image]) -> Image.Image:
	largeur = sum(p.width for p in poses) + 14 * len(poses)
	composite = Image.new("RGBA", (largeur, max(p.height for p in poses)), (0, 0, 0, 0))
	x = 0
	for p in poses:
		composite.alpha_composite(p, (x, composite.height - p.height))
		x += p.width + 14
	return composite


def contact(sortie: Path) -> Path:
	"""Les images GÉNÉRÉES de la série à l'échelle du jeu : 1 case = 96 px, héros de 128 px (repère),
	Fuji à 128 px, Osselait à 56 px, dos de Ronflex comme au combat (réduit), notes et halo en taille
	d'effet, icône du Sac à 256 px. La dernière révision présente de chaque image est montrée."""
	heros_sheet = PRINCIPAL / "assets/sprites/characters/painted/heros_sheet.png"
	heros = None
	if heros_sheet.exists():
		h = Image.open(heros_sheet).convert("RGBA")
		heros = (h.crop((0, 0, h.width // 4, h.height // 4)), "héros 128 px")
	p = _Planche(2900, "Série 23 générée (T7, jalon 21) : À L'ÉCHELLE DU JEU, 1 case = 96 px ; héros 128 px")
	sections: dict[str, list[tuple[Image.Image, str]]] = {}
	vus: set[str] = set()
	for image in _images():
		if image["base"] in vus:
			continue
		vus.add(image["base"])
		fichier = None
		for rev in (4, 3, 2, 1):
			candidat = ART / f"{image['base']}_r{rev}.png"
			if candidat.exists():
				fichier = candidat
				break
		if fichier is None:
			continue
		im = Image.open(fichier).convert("RGBA")
		base, nom = image["base"], fichier.stem
		if base == "PNJ_FUJI_NE":
			sections.setdefault("M. FUJI (128 px)", []).append(
				(_juxtaposer(_echelle_cellule(im, 128)), f"{nom}\nmarche : face, gauche, droite, dos"))
		elif base == "PNJ_FUJI_PRIERE_NE":
			poses = _poses_bande(im, 4)
			ref = poses[0].height
			sections.setdefault("M. FUJI (128 px)", []).append(
				(_juxtaposer([_echelle(q, 100 / ref) for q in poses]),
				f"{nom}\nprière agenouillée : dos, dos, gauche, face"))
		elif base == "POKE_OSSELAIT_NE":
			lignes = _echelle_cellule(im, 56)
			sections.setdefault("OSSELAIT (56 px) et RONFLEX", []).append(
				(_juxtaposer(lignes), f"{nom}\n56 px : face, gauche, droite, dos"))
		elif base == "DOS_RONFLEX":
			v = _boite_visible(im)
			sections.setdefault("OSSELAIT (56 px) et RONFLEX", []).append(
				(_echelle(v, 330 / v.height), f"{nom}\ndos de combat (≈ 330 px d'écran)"))
		elif base == "FX_NOTES_PLANCHE_NE":
			poses = _poses_bande(im, 4)
			sections.setdefault("EFFETS ET ICÔNE", []).append(
				(_juxtaposer([_echelle(q, 120 / q.height) for q in poses]),
				f"{nom}\nnotes ≈ 120 px (1,25 case)"))
		elif base == "FX_HALO_SPIRIT_NE":
			v = _boite_visible(im)
			sections.setdefault("EFFETS ET ICÔNE", []).append(
				(_echelle(im, 288 / im.width), f"{nom}\nhalo 3 cases (288 px) sur fond sombre"))
		elif base == "UI_OBJETS_J21_PLANCHE":
			v = _boite_visible(im)
			sections.setdefault("EFFETS ET ICÔNE", []).append(
				(_echelle(v, 256 / max(v.size)), f"{nom}\nicône du Sac 256 px"))
	for titre, elements in sections.items():
		if titre.startswith(("M. FUJI", "OSSELAIT")) and heros is not None:
			elements = [heros, *elements]
		fond = (30, 34, 48) if titre.startswith("EFFETS") else (60, 80, 110)
		p.section(titre, elements, fond)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	print(f"{sum(len(e) for e in sections.values())} éléments")
	return sortie


# --- Icône vectorielle de la Poké Flûte -------------------------------------------------------

SVG_FLUTE = """<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <ellipse cx="64" cy="118" rx="38" ry="6" fill="#000000" fill-opacity="0.28"/>
  <g transform="rotate(-38 64 64)">
    <rect x="10" y="52" width="108" height="24" rx="12" fill="#5BC8D8"/>
    <rect x="10" y="52" width="108" height="24" rx="12" fill="none" stroke="#1E2530" stroke-width="4"/>
    <path d="M22 59 H106" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>
    <rect x="26" y="50" width="7" height="28" rx="3" fill="#F5C542" stroke="#1E2530" stroke-width="3"/>
    <rect x="90" y="50" width="7" height="28" rx="3" fill="#F5C542" stroke="#1E2530" stroke-width="3"/>
    <ellipse cx="22" cy="64" rx="6" ry="9" fill="#F4F6F8" stroke="#1E2530" stroke-width="3.5"/>
    <circle cx="44" cy="66" r="3.6" fill="#1E2530"/>
    <circle cx="56" cy="66" r="3.6" fill="#1E2530"/>
    <circle cx="68" cy="66" r="3.6" fill="#1E2530"/>
    <circle cx="80" cy="66" r="3.6" fill="#1E2530"/>
    <path d="M112 70 C120 84 108 98 100 104" fill="none" stroke="#1E2530" stroke-width="9" stroke-linecap="round"/>
    <path d="M112 70 C120 84 108 98 100 104" fill="none" stroke="#F58FB4" stroke-width="5" stroke-linecap="round"/>
  </g>
</svg>
"""


def svg(sortie: Path) -> Path:
	sortie.parent.mkdir(parents=True, exist_ok=True)
	sortie.write_text(SVG_FLUTE, encoding="utf-8")
	return sortie


# --- Halo procédural (repli du halo peint, rejeté : disque quasi opaque au bord franc) ----------


def halo(sortie: Path, taille: int = 512) -> Path:
	"""Halo pâle de `SpiritLight` : cœur presque blanc légèrement lilas, bleu très pâle vers le bord,
	opacité 92 % au centre qui tombe à 0 avant le bord (lisse, sans anneau ni palier ; un grain de
	±1 niveau contre les bandes). Pour la lumière additive ; 1 pixel = 1/512 du diamètre."""
	import numpy as np
	n = taille
	y, x = np.mgrid[0:n, 0:n].astype("float64")
	r = np.hypot(x - (n - 1) / 2, y - (n - 1) / 2) / (n / 2)
	fondu = np.clip((1.0 - r) / 0.25, 0.0, 1.0)
	fondu = fondu * fondu * (3 - 2 * fondu)  # smoothstep : 0 au bord, 1 dès r = 0,75
	alpha = 0.92 * np.exp(-3.4 * r * r) * fondu
	t = np.clip(r / 0.7, 0.0, 1.0)[..., None]
	coeur, lilas, bleu = (np.array(c, "float64") for c in ((252, 249, 255), (214, 204, 246), (170, 196, 250)))
	rvb = np.where(t < 0.5, coeur + (lilas - coeur) * (t / 0.5), lilas + (bleu - lilas) * ((t - 0.5) / 0.5))
	grain = np.random.default_rng(23).uniform(-1, 1, (n, n, 1))
	image = np.concatenate([np.clip(rvb + grain, 0, 255), np.clip(alpha[..., None] * 255 + grain, 0, 255)],
		axis=2).astype("uint8")
	sortie.parent.mkdir(parents=True, exist_ok=True)
	Image.fromarray(image).save(sortie)
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
		print(contact(Path(autres[0]) if autres else RACINE / "build" / "art" / "J21_KIT_v1.png"))
	elif "--halo" in arguments:
		autres = [a for a in arguments if a != "--halo"]
		print(halo(Path(autres[0]) if autres else ART / "FX_HALO_SPIRIT_NE_r2.png"))
	elif "--svg" in arguments:
		autres = [a for a in arguments if a != "--svg"]
		print(svg(Path(autres[0]) if autres else RACINE / "build" / "art" / "poke_flute.svg"))
	else:
		generer(set(arguments))
