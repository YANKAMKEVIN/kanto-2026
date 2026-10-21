#!/usr/bin/env python3
"""Série 20 — lot d'art 19.0 du jalon 19 (Tour Pokémon), hors planche Exorciste (J18).

Fiche : docs/design/fiches-assets/serie-20-tour-pokemon.md ; conception : dossier 22 §6.2, §11,
§12.4, §12.5. Quatre assets, aucun code de jeu, aucune intégration Godot :
  1. SPECTRE_COMBAT : silhouette SPECTRE de combat, face adverse (brume violette indistincte) ;
  2. DOS_FANTOMINUS : dos de combat de Fantominus (092), provisoire IA (pas de modèle 3D X/Y) ;
  3. COMBAT_DECOR_TOUR_POKEMON : décor CB.3 `tour_pokemon` (composition + deux tuiles) ;
  4. WORLD_PROP_PANNEAU_SCOPE_01 : panneau publicitaire du Scope Sylphe à Lavanville (42, 11).

Prompts versionnés : tools/art/prompts/serie20/<NOM>_rN.txt et
tools/art/combat_decors/prompts/COMBAT_DECOR_TOUR_POKEMON_r1.txt (+ tuile). Sources et sorties
dans $ART (défaut : build/art de cette copie).

Usage :
  tools/art/serie20.py --prompts            écrit les prompts (sans Codex)
  tools/art/serie20.py --refs               recadre les références de la vue générale dans $ART
  tools/art/serie20.py --commandes          liste les commandes generer.sh
  tools/art/serie20.py --tuiles ESSAI       découpe les portions TL / TR d'une composition de décor
  tools/art/serie20.py --decor ESSAI        assemble le master 2340 × 1080 (sorties dans $ART/serie20/)
  tools/art/serie20.py --detourer           prépare silhouette, dos et panneau (essais retenus)
  tools/art/serie20.py --controle [sortie]  planche de contrôle à l'échelle du jeu
"""
from __future__ import annotations

import json
import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
sys.path.insert(0, str(ICI / "combat_decors"))
from serie06 import ADN, LUMIERE_NE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
SORTIE = ART / "serie20"
PROMPTS = ICI / "prompts" / "serie20"
PROMPTS_DECOR = ICI / "combat_decors" / "prompts"
REFERENCE = RACINE / "docs/design/reference"
VUE = REFERENCE / "tour-pokemon-vue-generale-v1.png"  # 1024 × 1536 (2F/3F, 4F/5F, 6F)
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026/build/art")
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PROTO = RACINE / "assets/sprites/pokemon/battle_proto"
DECORS = RACINE / "assets/battle/decors"

## Recadrages de la vue validée (boîtes en px de la vue 1024 × 1536).
REFS = {
	"REF_TP_SALLE": (60, 150, 500, 470),   # 2F : stèles, fleurs, bougies, dalles
	"REF_TP_6F": (300, 1000, 760, 1300),   # 6F : dalles, deux stèles, bougies (sans le spectre)
}

## Essais retenus (mis à jour après relecture ; voir la fiche).
RETENUS = {
	"SPECTRE_COMBAT": "SPECTRE_COMBAT_r1",
	"DOS_FANTOMINUS": "DOS_FANTOMINUS_r1",
	"PANNEAU": "WORLD_PROP_PANNEAU_SCOPE_01_NE_r1",
	"DECOR": "COMBAT_DECOR_TOUR_POKEMON_r1",
}

## Décor : entrée au format de tools/art/combat_decors/decors.json (proposée, non ajoutée).
TAILLE_DECOR = (2340, 1080)

FIN_DETOURE = ("FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun "
	"fond coloré, aucun sol, aucune ombre portée.")

SILHOUETTE = """SILHOUETTE DE COMBAT « SPECTRE » (Kanto 2026). Une seule image : l'apparition qu'un joueur voit en face de lui dans un combat, au fond d'une tour funéraire, tant qu'il n'a pas l'objet qui révèle les esprits. Ce n'est PAS une créature identifiable : c'est une présence de brume.

{ancre}

SUJET : une forme spectrale INDISTINCTE faite de brume violette, qui flotte au-dessus du sol. Une masse de vapeur plus dense au cœur (violet profond, lavande), qui se défait en volutes et en filaments vers les bords, de plus en plus transparente. La masse est À PEU PRÈS AUSSI LARGE QUE HAUTE (rapport proche de 1 : 1,1), irrégulière et asymétrique, comme une fumée lente qui s'enroule sur elle-même ; le bas s'amincit en une traîne de brume qui touche presque le bas de l'image, au centre (c'est là que sera posée l'ombre au sol). Quelques lueurs pâles diffuses à l'intérieur de la brume, sans forme.

CE QU'ELLE N'EST PAS (à respecter absolument) :
- AUCUN œil, aucune paire de points lumineux, aucune bouche, aucun visage, aucun crâne ;
- AUCUNE silhouette humaine ni humanoïde : pas de tête ronde posée sur des épaules, pas de capuche, pas de cape, pas de robe, pas de bras, pas de mains, pas de silhouette de moine ou de fantôme en drap ;
- AUCUNE forme d'animal ou de créature connue : pas d'oreilles, pas de pointes, pas de queue, pas de cornes, pas de dents, pas de sphère nette ;
- pas de contour noir ni de trait de contour : les bords sont de la brume qui s'efface.

RENDU : peinture numérique douce, de la même famille que les décors peints du jeu (illustration 2D « HD-2D peint », grandes masses douces, aucune texture photographique). Calme, triste et mystérieux, JAMAIS effrayant : pas de mouvement agressif, pas de griffes de fumée, pas de cri. Couleurs : violets et lavandes froids, quelques reflets bleu pâle ; jamais noir pur, jamais vert.

CADRAGE : image CARRÉE 1024 × 1024, la forme entière, centrée horizontalement, qui occupe environ 80 % de la hauteur et 75 % de la largeur ; rien n'est coupé par les bords.
{fin}
INTERDITS : texte, lettres, chiffres, logo, signature, cadre, sol, décor, personnage, Pokémon, œil, visage, main, capuche, contour noir, pixel art, 3D."""

SILHOUETTE_ANCRE = {
	1: "IMAGE JOINTE : une vue de dessus de la tour (pierre gris violacé, bougies, brume violette au bas de l'image). Prends-y SEULEMENT la couleur de la brume violette et l'ambiance douce ; ne reprends PAS la silhouette encapuchonnée qui s'y trouve (c'est précisément l'erreur à éviter).",
	2: "Aucune image jointe.",
	3: "Aucune image jointe.",
}

SILHOUETTE_R3 = ("\n\nPRÉCISION (essai 3) : pense à une NAPPE DE BRUME qui s'est levée du sol et s'enroule en "
	"un tourbillon lent, plus large en haut qu'en bas, comme un nuage d'orage violet très doux vu de près ; "
	"le haut est un bord de nuage irrégulier, en plusieurs lobes de tailles différentes, jamais un dôme rond "
	"unique ; aucune symétrie gauche-droite.")

DOS = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). {nom}

{ancres}

SUJET : {sujet}

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit l'arrière de la sphère ; AUCUN œil, aucune bouche, aucun visage : ils sont tournés vers l'avant, hors de vue (au plus, le bord d'un profil). La brume enveloppe la sphère tout autour et déborde un peu derrière elle, vers le spectateur.

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE avec sa brume, centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe.
{fin}
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage."""

DOS_SUJET = ("une créature-fantôme faite d'une SPHÈRE de gaz sombre, presque noire (noir violacé, reflets "
	"gris-violet), d'environ la moitié de la largeur de l'image, entourée d'une ÉPAISSE AURA DE GAZ violet "
	"lavande, translucide et ondoyante, plus large que la sphère, qui forme une couronne de volutes tout "
	"autour. Pas de bras, pas de jambes, pas de queue, pas d'oreilles.")

DOS_NOM = {
	1: "Le Pokémon est FANTOMINUS (Gastly, n° 092), de la première génération.",
	2: "La créature est un esprit de gaz de jeu vidéo, original.",
	3: "La créature est un esprit de gaz de jeu vidéo, original.",
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

DECOR = """DÉCOR DE COMBAT — TOUR POKÉMON, LAVANVILLE (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat Pokémon sur smartphone en paysage, à l'intérieur d'une tour funéraire où l'on vient se souvenir des Pokémon disparus. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.

Trois images sont jointes.
IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement plongeante, grand sol dégagé au centre), sa profondeur et sa qualité de peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le ciel.
IMAGE 2 : une planche d'intention de décors de combat ; prends la dernière case (intérieur de pierre éclairé, sol de poussière) comme guide de la facture d'une salle de pierre. Ne reprends PAS sa teinte orange ni ses rochers.
IMAGE 3 : un extrait de la vue de dessus de la tour (validée) : dalles de pierre gris violacé, stèles basses arrondies, fleurs pâles et offrandes à leur pied, bougies dans des niches. C'est la MATIÈRE et la PALETTE à reprendre, vues ici à hauteur d'yeux.

FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution possible, OPAQUE, cadrage plein, sans bord.

LIEU : une grande salle d'un étage de la tour. Murs de blocs de pierre taillée gris violacé, plafond bas qu'on devine à peine. Contre le mur du fond, une RANGÉE DE STÈLES BASSES (pierres tombales arrondies, petites, à hauteur de genou, sans aucune inscription), avec à leur pied des fleurs fanées et des fleurs fraîches pâles (blanc, lilas, rose pâle) et quelques petites offrandes (un bol, un ruban). Une BOUGIE allumée sur deux ou trois stèles importantes et dans deux NICHES du mur du fond : petites flammes chaudes et calmes, halo doux et limité. Une BRUME LÉGÈRE, lilas pâle, qui glisse au ras du sol au fond et sur les côtés, transparente, sans jamais cacher le sol du centre. Quelques particules de poussière dans l'air, très discrètes.

AMBIANCE : CALME ET SOLENNELLE, recueillie, triste et douce. AUCUNE horreur : ni crâne, ni os, ni toile d'araignée, ni sang, ni ombre menaçante, ni silhouette.

COMPOSITION (positions en fractions de la largeur et de la hauteur de l'image, depuis le coin haut gauche) — à respecter précisément :
- Fond (de 0 à 36 % de la hauteur) : le mur du fond et la rangée de stèles à son pied (base des stèles vers 34 à 38 % de la hauteur), une niche à bougie à x 24 % et une à x 76 %.
- De 40 % de la hauteur jusqu'en bas : un GRAND SOL DÉGAGÉ et PLAT de dalles de pierre gris violacé, aux joints nets, où deux créatures pourront se faire face.
- Point A (x 67 %, y 50 %) : sol plat, clair et lisible, un peu plus éclairé que le reste. Rien de haut dans un rayon de 12 % de la largeur autour.
- Point B (x 31 %, y 97 %) : sol plat de dalles, une grande créature vue de dos y sera au premier plan. Rien de haut autour.
- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de détails et peu de contraste, valeurs simples (mur lisse gris violacé, lisible) ; la niche de x 24 % y reste douce.
- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : dalles simples, presque sans objet, valeurs moyennes, sans contraste fort.
- Les deux coins du bas restent du SOL nu : ni stèle, ni bougie, ni fleur en gros plan.
- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur certains écrans).

SOL : dalles de pierre gris violacé de tailles variées, usées, quelques pétales tombés près des stèles, jamais uniforme ; rien dans la zone centrale.

PERSPECTIVE : à hauteur d'yeux, un peu plongeante ; le sol recule nettement vers le fond. Netteté partout (aucun flou de profondeur, pas de vignettage).

RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches sans être fluo.
LUMIÈRE : douce et FROIDE (gris violacé, lilas, bleu pâle) sur toute la salle, le centre du sol nettement lisible ; seules les bougies donnent de petits points chauds, limités à leur voisinage. Ombres violet froid, jamais noires. Jamais sombre au point de perdre le sol.

INTERDITS : Pokémon, personnage, silhouette, fantôme, visage, crâne, os, texte (aucune inscription sur les stèles), chiffres, logo, signature, filigrane, cadre, interface, ciel, fenêtre ouverte sur l'extérieur, végétation verte, eau, noir pur, pixel art, flou, vignettage."""

TUILE = """AGRANDISSEMENT D'UNE PORTION DE DÉCOR (Kanto 2026). L'image jointe est une portion d'un décor peint (l'intérieur d'une tour funéraire : dalles, stèles, bougies, brume légère). Produis EXACTEMENT LA MÊME IMAGE, à une résolution plus élevée, avec plus de finesse dans la peinture.

RÈGLES ABSOLUES :
- Même cadrage au pixel près : même largeur et même hauteur relatives, chaque élément (stèles, fleurs, bougies, niches, joints des dalles, blocs du mur, nappes de brume) exactement à la même place et à la même taille. N'ajoute rien, n'enlève rien, ne déplace rien, ne recadre pas, ne prolonge pas l'image.
- Mêmes couleurs, même lumière, même style (illustration 2D peinte « HD-2D peint », masses douces, aucun trait noir).
- Seulement plus de netteté et de détails fins dans le pinceau (grain de la pierre, pétales, flammes), comme une version haute définition du même tableau.
- Aucun flou, aucun texte, aucune inscription, aucun personnage, aucune créature, aucun cadre.

FORMAT : même rapport largeur / hauteur que l'image jointe (environ 1,17 : 1, légèrement plus large que haute), la plus grande résolution possible, OPAQUE."""

PANNEAU = """{adn}

FICHE — WORLD_PROP_PANNEAU_SCOPE_01 (Kanto 2026, ville de Lavanville, devant une tour funéraire). Un PANNEAU PUBLICITAIRE MODERNE d'une grande entreprise de technologie, posé au bord d'un parvis pavé. C'est un objet du monde, vu en vue de dessus de trois quarts (on voit la face avant et un peu le dessus du cadre).

{ancre}

OBJET : un panneau sur pied, propre et moderne, qui tranche doucement avec la ville ancienne : cadre en métal gris clair laqué aux angles arrondis, deux pieds fins plantés dans un petit socle de béton clair, une affiche rectangulaire en paysage tenue dans le cadre, un petit auvent métallique au-dessus avec deux petites lampes éteintes. L'AFFICHE est une illustration publicitaire sans aucun mot : sur un fond dégradé blanc et bleu clair, un appareil élégant en gros plan — une paire de LUNETTES-SCOPE high-tech (monture blanche et argent, verres bleu-violet brillants), avec quelques rayons de lumière stylisés et des formes géométriques douces (bandes, cercles) en bleu et turquoise. La zone du bas de l'affiche est une simple bande colorée unie, SANS AUCUN TEXTE. Aucune lettre, aucun logo-lettre, aucun chiffre nulle part (le texte est donné par le jeu).

TAILLE ET PROPORTIONS : à l'échelle d'un panneau de bois existant du jeu (environ 2 cases de haut sur 1,8 case de large, 1 case = 1 mètre ; un adulte mesure 1,33 case) : le panneau entier fait environ 2 m de haut et 1,8 m de large, l'affiche environ 1,5 m sur 1 m.

{lumiere}

CADRAGE : image PORTRAIT 1024 × 1536, l'objet entier, centré, la base des pieds et du socle sur une ligne de sol droite et horizontale près du bas ; rien sous cette ligne.
{fin}
INTERDITS : texte, lettres, chiffres, logo, filigrane, signature, personnage, Pokémon, Poké Ball, sol, herbe ou pavés autour, ombre portée, pixel art."""

PANNEAU_ANCRE = {
	1: "IMAGE JOINTE : le panneau de bois du jeu (même vue, même échelle, même rendu peint) : reprends sa VUE, son ÉCHELLE et sa facture, pas son matériau ni sa forme.",
	2: "IMAGE JOINTE : le panneau de bois du jeu : reprends sa VUE, son ÉCHELLE et sa facture, pas son matériau ni sa forme.",
	3: "Aucune image jointe.",
}


def _ecrire(chemin: Path, texte: str) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	chemin.write_text(texte.strip() + "\n")
	print(chemin.relative_to(RACINE))


def prompts() -> None:
	for r in (1, 2, 3):
		t = SILHOUETTE.format(ancre=SILHOUETTE_ANCRE[r], fin=FIN_DETOURE)
		if r == 3:
			t += SILHOUETTE_R3
		_ecrire(PROMPTS / f"SPECTRE_COMBAT_r{r}.txt", t)
		_ecrire(PROMPTS / f"DOS_FANTOMINUS_r{r}.txt", DOS.format(
			nom=DOS_NOM[r], ancres=DOS_ANCRES[r], sujet=DOS_SUJET, fin=FIN_DETOURE))
		_ecrire(PROMPTS / f"WORLD_PROP_PANNEAU_SCOPE_01_NE_r{r}.txt", PANNEAU.format(
			adn=ADN, ancre=PANNEAU_ANCRE[r], lumiere=LUMIERE_NE, fin=FIN_DETOURE))
	_ecrire(PROMPTS_DECOR / "COMBAT_DECOR_TOUR_POKEMON_r1.txt", DECOR)
	_ecrire(PROMPTS_DECOR / "COMBAT_DECOR_TUILE_TOUR_r1.txt", TUILE)


def refs() -> None:
	vue = Image.open(VUE).convert("RGB")
	for nom, boite in REFS.items():
		im = vue.crop(boite)
		im = im.resize((im.width * 3, im.height * 3), Image.LANCZOS)
		im.save(ART / f"{nom}.png")
		print(ART / f"{nom}.png", im.size)


def jointes() -> dict[str, list[str]]:
	return {
		"SPECTRE_COMBAT_r1": [str(VUE)],
		"SPECTRE_COMBAT_r2": [],
		"SPECTRE_COMBAT_r3": [],
		"DOS_FANTOMINUS_r1": [str(OFFICIEL / "092.png"), str(PROTO / "dos_ia_093.png")],
		"DOS_FANTOMINUS_r2": [str(OFFICIEL / "092.png"), str(PROTO / "dos_ia_093.png")],
		"DOS_FANTOMINUS_r3": [],
		"WORLD_PROP_PANNEAU_SCOPE_01_NE_r1": [str(PRINCIPAL / "WORLD_PROP_PANNEAU_01_NE_r1.png")],
		"WORLD_PROP_PANNEAU_SCOPE_01_NE_r2": [str(RACINE / "assets/world/props/prop_panneau_01.png")],
		"WORLD_PROP_PANNEAU_SCOPE_01_NE_r3": [],
		"COMBAT_DECOR_TOUR_POKEMON_r1": [str(REFERENCE / "combat-v1.webp"),
			str(REFERENCE / "combat-decors-planche-v1.webp"), str(ART / "REF_TP_SALLE.png")],
	}


def commandes() -> None:
	for ident, images in jointes().items():
		dossier = PROMPTS_DECOR if ident.startswith("COMBAT_DECOR") else PROMPTS
		print("tools/art/generer.sh %s %s %s" % (ident, (dossier / f"{ident}.txt").relative_to(RACINE),
			" ".join(images)))
	print("# tuiles (après --tuiles ESSAI) :")
	for cote in ("TL", "TR"):
		print("tools/art/generer.sh COMBAT_DECOR_TOUR_POKEMON_r1_%s "
			"tools/art/combat_decors/prompts/COMBAT_DECOR_TUILE_TOUR_r1.txt "
			"build/art/COMBAT_DECOR_TOUR_POKEMON_r1_crop%s.png" % (cote, cote))


def portions(largeur: int, hauteur: int) -> list[list[int]]:
	"""Deux portions qui se chevauchent (rapport ≈ 1,17 : 1), comme les décors existants."""
	w = round(hauteur * 1000 / 852)
	return [[0, 0, w, hauteur], [largeur - w, 0, largeur, hauteur]]


def tuiles(essai: str) -> None:
	comp = Image.open(ART / f"{essai}.png").convert("RGB")
	for cote, p in zip(("TL", "TR"), portions(*comp.size)):
		comp.crop(p).save(ART / f"{essai}_crop{cote}.png")
		print(cote, p)


def entree_decor(essai: str) -> dict:
	comp = Image.open(ART / f"{essai}.png")
	tl, tr = portions(*comp.size)
	return {
		"composition": f"{essai}.png",
		"tuiles": [{"image": f"{essai}_TL.png", "portion": tl}, {"image": f"{essai}_TR.png", "portion": tr}],
		"taille": list(TAILLE_DECOR),
		"qualite": 90,
	}


def decor(essai: str) -> None:
	import preparer_decor  # noqa: E402
	preparer_decor.ART = str(ART)
	entree = entree_decor(essai)
	fond, _ = preparer_decor.master(entree, TAILLE_DECOR)
	SORTIE.mkdir(parents=True, exist_ok=True)
	fond.save(SORTIE / "tour_pokemon_back.png")
	fond.save(SORTIE / "tour_pokemon_back.webp", "WEBP", quality=90, method=6)
	print(json.dumps(entree, ensure_ascii=False))
	print("%s : %.0f Ko" % (SORTIE / "tour_pokemon_back.webp",
		os.path.getsize(SORTIE / "tour_pokemon_back.webp") / 1024))


def _recadrer(im: Image.Image, seuil: int = 8) -> Image.Image:
	boite = im.getchannel("A").point(lambda a: 255 if a > seuil else 0).getbbox()
	return im.crop(boite) if boite else im


def _poser(sujet: Image.Image, cote: int, utile: int, bas: int) -> Image.Image:
	"""Sujet réduit dans un carré `utile` et posé centré, bas à `bas` px du bas d'un carré `cote`."""
	k = min(utile / sujet.width, utile / sujet.height)
	s = sujet.resize((round(sujet.width * k), round(sujet.height * k)), Image.LANCZOS)
	out = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
	out.alpha_composite(s, ((cote - s.width) // 2, cote - bas - s.height))
	return out


def detourer() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	# 1. Silhouette : format des faces adverses (artwork officiel 475 × 475, cadre utile ≈ 431 px).
	sp = _recadrer(Image.open(ART / f"{RETENUS['SPECTRE_COMBAT']}.png").convert("RGBA"))
	_poser(sp, 475, 431, 22).save(SORTIE / "spectre_face.png")
	_poser(sp, 1024, 930, 48).save(SORTIE / "spectre_face_1024.png")
	# 2. Dos : format des dos IA (1024 × 1024, ≈ 85 % de la hauteur, comme dos_ia_093).
	dos = _recadrer(Image.open(ART / f"{RETENUS['DOS_FANTOMINUS']}.png").convert("RGBA"))
	_poser(dos, 1024, 870, 120).save(SORTIE / "dos_ia_092.png")
	# 3. Panneau : 2 cases de haut (axe h, cases 2), comme prop_panneau_01 (171 × 192).
	pa = _recadrer(Image.open(ART / f"{RETENUS['PANNEAU']}.png").convert("RGBA"))
	k = 192 / pa.height
	pa.resize((round(pa.width * k), 192), Image.LANCZOS).save(SORTIE / "prop_panneau_scope_01.png")
	for f in ("spectre_face.png", "dos_ia_092.png", "prop_panneau_scope_01.png"):
		im = Image.open(SORTIE / f)
		print(SORTIE / f, im.size, im.getchannel("A").getbbox())


# --- Planche de contrôle : reprise de BattleLayout (game/battle/battle_layout.gd) ---
PLAYER_FEET = (-0.42, 0.90)
FOE_FEET = (0.36, 0.50)
PRESENCE = {True: 0.31, False: 0.27}
MAX_BOX = {True: (0.80, 0.40), False: (0.50, 0.38)}


def _echelle(box: tuple[int, int], hauteur_m: float, joueur: bool, vue_h: float) -> float:
	ratio = min(max(math.pow(max(hauteur_m, 0.05) / 0.6, 0.4), 0.73), 1.73)
	limite = (MAX_BOX[joueur][0] * vue_h, MAX_BOX[joueur][1] * vue_h)
	plus_grand = min(limite[0] / box[0], limite[1] / box[1])
	return min(PRESENCE[joueur] * ratio * vue_h / math.sqrt(box[0] * box[1]), plus_grand)


def _placer(fond: Image.Image, image: Image.Image, hauteur_m: float, joueur: bool) -> None:
	im = _recadrer(image.convert("RGBA"), 16)
	w, h = fond.size
	ancre = PLAYER_FEET if joueur else FOE_FEET
	pieds = (w / 2 + ancre[0] * h, ancre[1] * h)
	k = _echelle(im.size, hauteur_m, joueur, h)
	s = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
	# Ombre au sol (ellipse floutée), comme battle_shadow.
	ombre = Image.new("RGBA", fond.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(ombre)
	rx, ry = s.width * 0.36, s.width * 0.07
	d.ellipse((pieds[0] - rx, pieds[1] - ry, pieds[0] + rx, pieds[1] + ry), fill=(20, 10, 40, 110))
	fond.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(8)))
	fond.alpha_composite(s, (round(pieds[0] - s.width / 2), round(pieds[1] - s.height)))


def _police(taille: int) -> ImageFont.ImageFont:
	for c in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(c).exists():
			return ImageFont.truetype(c, taille)
	return ImageFont.load_default()


def controle(sortie: Path) -> None:
	decor_png = SORTIE / "tour_pokemon_back.png"
	fond0 = Image.open(decor_png if decor_png.exists() else DECORS / "mt_moon_chambre_back.webp").convert("RGBA")
	spectre = Image.open(SORTIE / "spectre_face.png")
	dos = Image.open(SORTIE / "dos_ia_092.png")
	# Haut : SPECTRE (taille de Fantominus, 1,3 m) contre le dos de Fantominus.
	a = fond0.copy()
	_placer(a, spectre, 1.3, False)
	_placer(a, dos, 1.3, True)
	# Bas : face existante (Spectrum 093, 1,6 m) contre le dos IA existant de Spectrum.
	b = fond0.copy()
	_placer(b, Image.open(OFFICIEL / "093.png"), 1.6, False)
	_placer(b, Image.open(PROTO / "dos_ia_093.png"), 1.6, True)
	# Panneau à l'échelle du monde (1 case = 96 px) à côté du panneau de bois et d'une case.
	panneau = Image.open(SORTIE / "prop_panneau_scope_01.png")
	bois = Image.open(RACINE / "assets/world/props/prop_panneau_01.png")
	monde = Image.new("RGBA", (96 * 8, 96 * 4), (128, 122, 132, 255))
	dm = ImageDraw.Draw(monde)
	for x in range(0, monde.width, 96):
		dm.line((x, 0, x, monde.height), fill=(110, 104, 116, 255))
	for y in range(0, monde.height, 96):
		dm.line((0, y, monde.width, y), fill=(110, 104, 116, 255))
	sol = 96 * 3
	monde.alpha_composite(bois, (96 * 1 + (96 - bois.width) // 2 + 48, sol - bois.height))
	monde.alpha_composite(panneau, (96 * 5 + (96 - panneau.width) // 2, sol - panneau.height))
	marge = 40
	larg = a.width
	haut = a.height * 2 + monde.height + marge * 4 + 120
	pl = Image.new("RGBA", (larg, haut), (24, 22, 30, 255))
	d = ImageDraw.Draw(pl)
	f = _police(34)
	y = marge
	d.text((marge, y), "Série 20 — SPECTRE (face, 1,3 m) et dos de Fantominus (IA provisoire) sur le décor tour_pokemon", fill="white", font=f)
	y += 50
	pl.alpha_composite(a, (0, y))
	y += a.height + marge
	d.text((marge, y), "Comparaison : face existante de Spectrum (093, 1,6 m) et dos_ia_093", fill="white", font=f)
	y += 50
	pl.alpha_composite(b, (0, y))
	y += b.height + marge
	d.text((marge, y - 4), "Monde, 1 case = 96 px : prop_panneau_01 (bois) | panneau du Scope Sylphe (42, 11)", fill="white", font=f)
	pl.alpha_composite(monde, (marge, y + 40))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	pl.convert("RGB").save(sortie)
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
	elif args[0] == "--tuiles":
		tuiles(args[1])
	elif args[0] == "--decor":
		decor(args[1])
	elif args[0] == "--detourer":
		detourer()
	elif args[0] == "--controle":
		controle(Path(args[1]) if len(args) > 1 else ART / "SERIE20_CONTROLE_v1.png")
	else:
		sys.exit(__doc__)


if __name__ == "__main__":
	main()
