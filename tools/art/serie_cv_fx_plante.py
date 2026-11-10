#!/usr/bin/env python3
"""Refonte des attaques Plante (direction A « végétal peint », verts frais, feuilles à nervures, docs/tech/attaques-plante.md).
Même chaîne et mêmes cadrages que `serie_cv_fx_eau.py`. Les masses denses (lianes, coton, rayon solaire, explosion)
sont détourées sur MAGENTA (`norm`, les pétales roses sur VERT) et posées en mélange normal pour garder leurs couleurs sur le décor très vert ; les lueurs
(auras, rayon de Synthèse, orbes de sève) restent additives sur noir.
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_plante.json."""
from __future__ import annotations

import sys

import serie_cv_fx as b
import serie_cv_fx_eau as eau

b.MANIFESTE = "manifeste_plante.json"
b.TITRE = "Attaques Plante, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-plante"
b.PROMPTS = b.ART / "prompts" / "cv_fx_plante"

ADN_A = """ADN VISUEL — VÉGÉTAL PEINT (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, matière végétale DENSE et vivante, contraste fort. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : verts frais et tendres, vert émeraude, cœurs vert très pâle presque blanc, liserés vert profond ; feuilles et lianes avec leurs nervures. Rose et blanc seulement pour les pétales, blanc doré seulement pour la lumière solaire, blanc crème seulement pour le coton. AUCUN magenta, AUCUN violet, AUCUN bleu.
- Lumière NEUTRE : l'effet est éclairé de façon neutre ; aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("flot_seve", "add", "bande", False, 320, "FLOT DE SÈVE LUMINEUSE",
		"un FLOT continu de sphères de lumière verte (sève) qui coule horizontalement du bord GAUCHE exact jusqu'au bord "
		"DROIT exact de la case, sans interruption : une dizaine de sphères vert vif à cœur blanc, de tailles variées, reliées "
		"par un filet de lumière verte ondulant, petites étincelles autour. Épaisseur environ la moitié de la hauteur de la "
		"case. Boucle : les sphères avancent vers la droite d'une image à l'autre."),
	("eclat_seve", "add", "carre", True, 320, "SÈVE ARRACHÉE À LA CIBLE",
		"une gerbe de lumière verte arrachée d'un point central, jouée UNE fois : image 1 un point vert lumineux, images 2 à 4 "
		"un éclat de lumière verte en étoile d'où jaillissent des sphères vertes à cœur blanc, images 5 à 7 les sphères "
		"s'écartent et pâlissent, image 8 presque vide."),
	("aura_seve", "add", "carre", False, 320, "AURA DE SÈVE",
		"une aura de lumière verte en forme d'ovale vertical qui occupe 85 % de la case : contour lumineux vert vif, flammes "
		"de lumière verte qui montent, petites sphères de sève et petites feuilles lumineuses qui tournent autour. "
		"L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : la lumière ondule et les sphères tournent."),
	("liane_fouet", "norm", "bande", False, 384, "LIANE QUI FOUETTE",
		"DEUX LIANES ÉPAISSES torsadées l'une autour de l'autre, horizontales, du bord GAUCHE exact jusqu'au bord DROIT exact "
		"de la case, sans interruption : tiges vert franc à reflets clairs et liserés vert profond, nervures, quelques "
		"feuilles fraîches qui s'en détachent, bout recourbé qui claque à droite. Épaisseur environ la moitié de la hauteur "
		"de la case. Boucle : les lianes ondulent comme un fouet d'une image à l'autre."),
	("entailles_feuilles", "norm", "carre", True, 384, "ENTAILLES DE FEUILLES TRANCHANTES",
		"un impact de feuilles tranchantes centré, joué UNE fois : image 1 un éclat blanc-vert, images 2 à 4 trois grandes "
		"ENTAILLES courbes vert pâle lumineuses qui se croisent, des feuilles vertes coupées qui volent en éventail, images 5 "
		"à 7 les entailles s'effacent et les feuilles s'envolent, image 8 quelques feuilles seulement."),
	("tourbillon_petales", "vert", "carre", False, 384, "TOURBILLON DE PÉTALES",
		"un IMMENSE TOURBILLON de pétales de fleurs vu de face, qui occupe toute la case : des centaines de pétales roses, "
		"rose pâle et blancs, quelques fleurs entières, emportés en spirale serrée autour d'un CENTRE VIDE, traînées de vent "
		"blanches. Très dense sur les bords de la spirale. Boucle : le tourbillon tourne d'une image à l'autre."),
	("rayon_solaire", "norm", "bande", False, 384, "RAYON SOLAIRE ÉNORME",
		"un RAYON DE LUMIÈRE SOLAIRE énorme et éblouissant, horizontal, du bord GAUCHE exact jusqu'au bord DROIT exact de "
		"la case, sans interruption, épaisseur environ les deux tiers de la hauteur de la case : cœur BLANC pur, gaine "
		"jaune doré, bords vert clair lumineux, éclats et filaments de lumière qui s'en échappent. Boucle : la lumière "
		"pulse et coule vers la droite."),
	("explosion_solaire", "norm", "carre", True, 384, "EXPLOSION DE LUMIÈRE SOLAIRE",
		"une énorme explosion de lumière solaire centrée, jouée UNE fois : image 1 un point blanc, images 2 à 4 une sphère "
		"blanche éblouissante entourée de longs rayons jaune doré qui jaillissent jusqu'aux bords de la case, images 5 à 7 "
		"les rayons se brisent en éclats dorés et verts, image 8 quelques éclats seulement."),
	("aura_solaire", "add", "carre", False, 320, "LUMIÈRE DU SOLEIL ABSORBÉE",
		"une aura de lumière solaire en forme d'ovale vertical qui occupe 85 % de la case : contour jaune doré éclatant, "
		"rayons courts qui convergent vers l'intérieur, particules dorées aspirées vers le centre. L'INTÉRIEUR RESTE VIDE ET "
		"NOIR. Boucle : les rayons convergent et la lumière pulse."),
	("lianes_enserrent", "norm", "carre", True, 384, "LIANES QUI ENSERRENT",
		"des lianes qui jaillissent du bas de la case et s'enroulent, jouées UNE fois : image 1 une petite pousse au bas, "
		"images 2 à 4 quatre lianes épaisses vert franc avec feuilles qui montent en spirale et forment une CAGE ovale "
		"verticale serrée, images 5 à 7 les lianes se resserrent et de petites lumières vertes s'en échappent, image 8 les "
		"lianes enroulées restent. L'intérieur de la cage reste vide (fond)."),
	("coton_colle", "norm", "carre", True, 384, "COTON QUI SE COLLE",
		"des flocons de coton blancs qui arrivent et se collent, joués UNE fois : image 1 quelques flocons sur les bords, "
		"images 2 à 4 de gros flocons de coton blanc crème duveteux convergent et s'agglutinent en une couronne épaisse "
		"autour d'un CENTRE VIDE, images 5 à 7 la couronne de coton se tasse et des brins s'en échappent, image 8 la "
		"couronne de coton reste."),
	("rayon_synthese", "add", "pleine", False, 320, "RAYON DE SOLEIL VERTICAL",
		"un RAYON DE SOLEIL vertical qui tombe du bord HAUT exact jusqu'au bord BAS exact de la case, large d'environ la "
		"moitié de la case : colonne de lumière blanc doré, plus large en bas, stries de lumière verticales, poussières "
		"dorées et petites feuilles lumineuses qui flottent dedans. Boucle : les stries descendent et la lumière pulse."),
	("aura_synthese", "add", "carre", False, 320, "AURA DE PHOTOSYNTHÈSE",
		"une aura de lumière verte et dorée en forme d'ovale vertical qui occupe 85 % de la case : contour vert vif et or, "
		"rubans de lumière verte qui montent en spirale, feuilles lumineuses qui tournent et scintillements dorés. "
		"L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : les rubans montent et les feuilles tournent."),
]

b.PARTICULES = [
	("part_r", "norm", [
		("feuille_tranchante", "UNE feuille verte effilée en forme de lame, nervure centrale claire, bord tranchant blanc-vert "
			"lumineux, pointe vers la droite"),
		("graine_vampi", "UNE grosse graine brun clair en goutte, coque peinte avec reflet, petite fente verte d'où sort une "
			"pousse"),
		("flocon_coton", "UN gros flocon de coton blanc crème, duveteux et rond, brins fins sur les bords"),
		("feuille_double", "deux feuilles vertes fraîches attachées à une courte tige"),
		("feuille_vive", "UNE feuille verte fraîche et ronde, nervures visibles, reflet clair"),
		("touffe_coton", "une touffe de coton blanc effilochée, brins qui s'étirent"),
		("brin_herbe", "un brin d'herbe vert courbé, pointe claire"),
		("eclat_feuilles", "une gerbe compacte de trois petites feuilles vertes qui s'écartent"),
	]),
	("part_t", "vert", [
		("petale_rose", "UN pétale de fleur rose vif, dégradé rose pâle au bout, nervure fine"),
		("fleur_blanche", "UNE petite fleur blanche à cinq pétales, cœur jaune"),
		("fleur_rose", "UNE fleur rose entière à cinq pétales, cœur jaune pâle"),
		("petale_pale", "UN pétale rose très pâle presque blanc, courbé"),
		("petales_vol", "trois pétales roses qui volent ensemble"),
		("bouton_fleur", "UN bouton de fleur rose fermé"),
		("petale_courbe", "UN pétale rose vif enroulé sur lui-même, vu de profil"),
		("pluie_petales", "une petite volée serrée de pétales roses et blancs"),
	]),
	("part_s", "add", [
		("orbe_seve", "UNE sphère de lumière verte vive, cœur blanc, halo vert"),
		("claque_vert", "une étoile de choc à huit branches vert pâle lumineux, cœur blanc"),
		("etincelle_seve", "une petite étincelle verte à quatre branches fines"),
		("lueur_seve", "une lueur ronde très douce, vert pâle, qui s'estompe jusqu'au noir"),
		("poussiere_or", "un nuage de poussière dorée scintillante"),
		("rayon_court", "un court rayon de lumière dorée, effilé aux deux bouts"),
		("feuille_lumineuse", "une petite feuille de lumière vert vif, contour lumineux"),
		("pollen_dore", "trois grains de pollen doré lumineux"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
## La préparation de `serie_cv_fx_eau` lit `_INFO`, `_BORDS` et `_QUATRE_COLONNES` dans son module.
eau._INFO.clear()
eau._INFO.update({i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS})
eau._BORDS.clear()

eau._QUATRE_COLONNES.clear()
eau.ADN_A = ADN_A
_prompt_flipbook_eau = eau._prompt_flipbook


def _prompt_flipbook(ident: str, mode: str, titre: str, consigne: str) -> str:
	"""Pétales roses : fond VERT (le magenta se confondrait avec le rose)."""
	texte = _prompt_flipbook_eau(ident, mode, titre, consigne)
	return texte.replace(b.FOND_MAGENTA, b.FOND_VERT) if mode == "vert" else texte


b._prompt_flipbook = _prompt_flipbook


if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		b.prompts()
	elif a[:1] == ["--preparer"]:
		eau.preparer()
	elif a[:1] == ["--planche"]:
		b.planche()
	else:
		b.generer(a)
