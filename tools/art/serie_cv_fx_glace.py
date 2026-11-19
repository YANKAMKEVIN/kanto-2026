#!/usr/bin/env python3
"""Refonte des attaques Glace (direction A « givre peint », bleus glacier pâles, cyan clair et blanc, cristaux à facettes,
docs/tech/attaques-glace.md). Même chaîne et mêmes cadrages que `serie_cv_fx_plante.py`. Les masses denses (rayon de glace,
cristaux, tempête, neige, brume sombre) sont détourées sur MAGENTA (`norm` : la glace n'a ni rose ni violet) et posées en
mélange normal ; le ruban d'Onde Boréale, qui a du rose et du violet, est détouré sur VERT (`vert`, sans vert dans le
ruban) ; les lueurs (voile de Brume, étoile de contact, étincelles) restent additives sur noir.
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_glace.json."""
from __future__ import annotations

import sys

import serie_cv_fx as b
import serie_cv_fx_eau as eau

b.MANIFESTE = "manifeste_glace.json"
b.TITRE = "Attaques Glace, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-glace"
b.PROMPTS = b.ART / "prompts" / "cv_fx_glace"

ADN_A = """ADN VISUEL — GIVRE PEINT (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, glace DENSE et massive, cristaux à facettes avec reflets, neige poudreuse, contraste fort. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : bleus glacier pâles, cyan clair, bleu ciel, BLANC pur pour les cœurs, les reflets et la neige ; liserés bleu moyen à bleu profond pour le volume des cristaux. Rose, violet et turquoise SEULEMENT dans le ruban d'aurore quand il est demandé. AUCUN magenta, AUCUN vert, AUCUN orange.
- Lumière NEUTRE : l'effet est éclairé de façon neutre ; aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("ruban_aurore", "vert", "bande", False, 384, "RUBAN D'AURORE BORÉALE",
		"UN RUBAN de lumière d'aurore boréale qui ondule en vague sinueuse horizontale, du bord GAUCHE exact jusqu'au bord "
		"DROIT exact de la case, sans interruption : ruban large et dense, dégradé cyan clair, bleu ciel, rose pâle et violet "
		"doux, stries verticales de lumière comme une aurore, cœur blanc, petits cristaux de givre et étincelles blanches qui "
		"s'en échappent. Épaisseur environ la moitié de la hauteur de la case. AUCUN VERT dans le ruban. Boucle : la vague "
		"du ruban avance vers la droite d'une image à l'autre."),
	("eclat_givre", "norm", "carre", True, 384, "ÉCLAT DE GIVRE",
		"un impact de givre centré, joué UNE fois : image 1 un point blanc, images 2 à 4 une étoile de givre à huit "
		"branches de cristaux bleu glacier et blancs qui jaillit, petits éclats de glace qui volent, images 5 à 7 les "
		"cristaux se fendent et retombent en poudre de neige, image 8 quelques flocons seulement."),
	("rayon_glace", "norm", "bande", False, 384, "RAYON DE GLACE ÉPAIS",
		"UN RAYON DE GLACE épais et droit, horizontal, du bord GAUCHE exact jusqu'au bord DROIT exact de la case, sans "
		"interruption, épaisseur environ la moitié de la hauteur de la case : cœur BLANC éclatant, gaine cyan clair et bleu "
		"glacier, cristaux de glace à facettes qui poussent le long du rayon et s'en détachent, givre et poudre de neige sur "
		"les bords. Boucle : la lumière coule vers la droite et les cristaux scintillent."),
	("bloc_glace", "norm", "carre", True, 384, "CRISTAUX DE GLACE QUI ENFERMENT PUIS ÉCLATENT",
		"des cristaux de glace qui jaillissent et emprisonnent, joués UNE fois : image 1 du givre au bas de la case, images "
		"2 à 4 de GRANDS CRISTAUX de glace bleu glacier à facettes poussent en couronne serrée et forment une CAGE ovale "
		"verticale hérissée de pics, images 5 et 6 la cage est complète, reflets blancs, images 7 et 8 les cristaux "
		"éclatent en gros éclats qui volent vers l'extérieur. L'INTÉRIEUR DE LA CAGE RESTE VIDE (fond)."),
	("rafale_blizzard", "norm", "carre", False, 384, "MUR DE BLIZZARD QUI DÉFERLE VERS LA DROITE",
		"un IMMENSE MUR DE TEMPÊTE DE NEIGE vu de côté qui déferle vers la DROITE et occupe toute la case : tourbillons "
		"épais de neige blanche et de vent bleu glacier, gros éclats de glace à facettes emportés dedans, front de la "
		"tempête très dense à droite, traînées de vent vers la gauche. Boucle : la neige tourbillonne d'une image à l'autre."),
	("tempete_neige", "norm", "pleine", False, 384, "NEIGE DE BLIZZARD QUI TOMBE",
		"une NEIGE de blizzard dense qui balaie toute la case : des centaines de gros flocons blancs et de traits de neige "
		"fouettés par le vent, fortement inclinés vers la droite en descendant, répartis sur toute la case du haut en bas, "
		"quelques petits éclats de glace bleu pâle. Aucun nuage, aucun sol. Boucle : la neige file vers le bas à droite "
		"d'une image à l'autre."),
	("explosion_glace", "norm", "carre", True, 384, "EXPLOSION DE GLACE",
		"une énorme explosion de glace centrée, jouée UNE fois : image 1 un point blanc, images 2 à 4 une gerbe de GRANDS "
		"PICS de glace bleu glacier à facettes qui jaillissent dans toutes les directions jusqu'aux bords de la case, nuage "
		"de neige blanche, images 5 à 7 les pics se brisent en éclats et poudre de neige, image 8 quelques éclats seulement."),
	("etoile_cristaux", "norm", "carre", True, 384, "ÉTOILE DE CRISTAUX AU CONTACT",
		"un coup de poing de glace au contact, joué UNE fois : image 1 un éclat blanc au centre, images 2 à 4 une ÉTOILE de "
		"longs cristaux de glace bleu glacier à facettes qui jaillit en éventail tout autour du centre, givre qui gagne en "
		"cercle, images 5 à 7 les cristaux restent puis se fendent, image 8 des éclats et de la poudre de neige."),
	("voile_brume", "add", "carre", False, 320, "VOILE DE BRUME PROTECTRICE",
		"un VOILE DE BRUME blanche et bleu très pâle en forme d'ovale vertical qui occupe 85 % de la case : rubans de brume "
		"épais qui tournent en spirale autour, scintillements de givre et petits flocons lumineux. L'INTÉRIEUR RESTE VIDE "
		"ET NOIR. Boucle : les rubans de brume tournent et scintillent."),
]

b.PARTICULES = [
	("part_g", "norm", [
		("cristal_glace", "UN cristal de glace à facettes bleu glacier, allongé, reflet blanc, pointe vers la droite"),
		("pic_glace", "UN grand pic de glace effilé, bleu glacier à cœur blanc, arêtes nettes"),
		("flocon_peint", "UN gros flocon de neige à six branches, blanc et bleu pâle, peint"),
		("eclat_cristal", "une gerbe compacte de trois petits éclats de glace qui s'écartent"),
		("neige_lourde", "une petite boule de neige poudreuse blanche, bords qui s'effritent"),
		("nappe_buee", "une LARGE NAPPE de brume froide très sombre, bleu nuit et gris ardoise, épaisse et opaque, en "
			"volutes horizontales, bords effilochés ; occupe toute la largeur de sa case"),
		("volute_buee", "une volute de brume froide sombre, bleu nuit et gris ardoise, épaisse"),
		("glacon", "UN petit bloc de glace cubique translucide bleu pâle, arêtes blanches"),
	]),
	("part_h", "add", [
		("etincelle_givre", "une étincelle blanche et cyan à quatre branches fines"),
		("lueur_givre", "une lueur ronde très douce, bleu glacier pâle, qui s'estompe jusqu'au noir"),
		("scintille_givre", "trois petits scintillements blancs en étoile"),
		("poussiere_givre", "un nuage de poussière de givre blanche et bleu pâle scintillante"),
		("contact_givre", "une étoile de choc froide à huit branches fines de lumière blanche et cyan, cœur blanc éclatant, "
			"anneau de choc bleu pâle autour"),
		("flocon_lumiere", "UN flocon de neige lumineux blanc à six branches, halo cyan"),
		("reflet_aurore", "une courte traînée de lumière d'aurore, cyan, rose pâle et violet doux"),
		("brume_lumiere", "une petite volute de brume blanche lumineuse"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
## La préparation de `serie_cv_fx_eau` lit `_INFO`, `_BORDS` et `_QUATRE_COLONNES` dans son module.
eau._INFO.clear()
eau._INFO.update({i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS})
eau._BORDS.clear()
eau._BORDS.add("rafale_blizzard")
## Le mur de blizzard remplit sa case : bords fondus plus loin que la vague de Surf.
_fondre_bords_eau = eau._fondre_bords
eau._fondre_bords = lambda im, part=0.36: _fondre_bords_eau(im, part)
eau._QUATRE_COLONNES.clear()
eau.ADN_A = ADN_A
_prompt_flipbook_eau = eau._prompt_flipbook


def _prompt_flipbook(ident: str, mode: str, titre: str, consigne: str) -> str:
	"""Ruban d'aurore (rose et violet) : fond VERT (le magenta se confondrait avec lui)."""
	texte = _prompt_flipbook_eau(ident, mode, titre, consigne)
	return texte.replace(b.FOND_MAGENTA, b.FOND_VERT) if mode == "vert" else texte


b._prompt_flipbook = _prompt_flipbook

## Particules qui ont attrapé un bout de la nappe de brume voisine (planche part_g) : bande effacée
## (côté, part de la largeur).
_BAVURES = {"neige_lourde": ("droite", 0.16), "volute_buee": ("gauche", 0.16), "glacon": ("gauche", 0.16)}


def _nettoyer() -> None:
	from PIL import Image
	for nom, (cote, part) in _BAVURES.items():
		chemin = b.SORTIE / f"p_{nom}.webp"
		im = Image.open(chemin).convert("RGBA")
		l, h = im.size
		bande = int(l * part)
		x0 = l - bande if cote == "droite" else 0
		im.paste((0, 0, 0, 0), (x0, 0, x0 + bande, h))
		im.save(chemin, lossless=True)
	# Nappes de Buée Noire peintes jusqu'au bord de leur case : bords fondus (pas d'arête droite).
	for nom in ("nappe_buee", "volute_buee"):
		chemin = b.SORTIE / f"p_{nom}.webp"
		_fondre_bords_eau(Image.open(chemin).convert("RGBA"), 0.32).save(chemin, lossless=True)


if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		b.prompts()
	elif a[:1] == ["--preparer"]:
		eau.preparer()
		_nettoyer()
	elif a[:1] == ["--planche"]:
		b.planche()
	else:
		b.generer(a)
