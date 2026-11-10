#!/usr/bin/env python3
"""Refonte des attaques Eau (direction A « eau peinte », bleus clairs et turquoise, écume blanche, docs/tech/attaques-eau.md).
Même chaîne et mêmes cadrages que `serie_cv_fx_feu.py`. Les masses d'eau épaisses sont détourées sur MAGENTA (`norm`) et
posées en mélange normal pour garder leurs bleus sur le décor clair ; bulles, jets fins et pluie restent additifs sur noir.
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_eau.json."""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image

import serie_cv_fx as b
import serie_cv_fx_electrik as e

b.MANIFESTE = "manifeste_eau.json"
b.TITRE = "Attaques Eau, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-eau"
b.PROMPTS = b.ART / "prompts" / "cv_fx_eau"

ADN_A = """ADN VISUEL — EAU PEINTE (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, eau vivante, transparences et reflets de lumière. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : bleus clairs, turquoise, bleu ciel, écume BLANCHE, reflets blancs ; quelques bleus moyens pour le volume. AUCUN rose, AUCUN magenta, AUCUN violet, AUCUN vert, AUCUN orange.
- Lumière NEUTRE : l'effet est éclairé de façon neutre ; aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("coque_eau", "add", "carre", False, 320, "COQUE D'EAU PROTECTRICE",
		"une grande BULLE d'eau translucide en forme de dôme ovale vertical, centrée, qui occupe 85 % de la case : "
		"une paroi d'eau fine qui reflète la lumière, reflets blancs courbes sur le haut, ondulations qui courent sur "
		"la surface, petit remous d'eau à la base. L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : les reflets glissent et la "
		"paroi ondule d'une image à l'autre."),
	("jet_fin_eau", "add", "bande", False, 320, "PETIT JET D'EAU FIN",
		"UN SEUL jet d'eau FIN et vif, horizontal, qui part exactement du bord GAUCHE et arrive exactement au bord DROIT "
		"de la case, sans interruption : filet d'eau mince (environ un dixième de la hauteur de la case), cœur blanc "
		"brillant, bords bleu clair, quelques gouttelettes qui s'en échappent. Boucle : l'eau coule vers la droite."),
	("eclabousse_eau", "add", "carre", True, 320, "PETITE ÉCLABOUSSURE D'IMPACT",
		"une éclaboussure d'eau centrée, jouée UNE fois : image 1 un point blanc, images 2 à 4 une couronne de "
		"gouttes et d'écume qui jaillit dans toutes les directions, images 5 à 7 les gouttes retombent et "
		"s'éparpillent, image 8 presque vide."),
	("chute_eau", "norm", "pleine", False, 384, "CASCADE QUI S'ABAT",
		"une CHUTE D'EAU VERTICALE qui tombe du bord HAUT exact jusqu'au bord BAS exact de la case, large d'environ "
		"la moitié de la case : rideau d'eau épais bleu clair et turquoise, stries verticales blanches d'écume, bords "
		"qui se déchirent en filets et en gouttes, embruns blancs en bas. Boucle : l'eau tombe d'une image à l'autre."),
	("gerbe_eau", "norm", "carre", True, 384, "GRANDE GERBE D'EAU AU SOL",
		"une grande gerbe d'eau qui jaillit du sol, centrée en bas de la case, jouée UNE fois : image 1 un remous "
		"plat, images 2 à 4 une couronne d'eau et d'écume qui monte haut et s'évase, images 5 à 7 elle retombe en "
		"gouttes et en embruns, image 8 il ne reste que quelques gouttes."),
	("vague", "norm", "carre", False, 384, "GRANDE VAGUE QUI DÉFERLE VERS LA DROITE",
		"une GRANDE VAGUE vue de profil qui déferle vers la DROITE, qui remplit la case : corps de la vague turquoise "
		"et bleu clair, transparent près de la crête, CRÊTE recourbée vers la droite couronnée d'écume blanche qui "
		"s'effondre, embruns qui s'envolent, base large d'écume au bas de la case. Boucle : la crête roule et l'écume "
		"se renouvelle."),
	("torrent_spirale", "norm", "bande", False, 384, "JET D'EAU SOUS PRESSION EN SPIRALE",
		"un JET D'EAU ÉNORME et ÉPAIS, horizontal, du bord GAUCHE exact jusqu'au bord DROIT exact de la case, sans "
		"interruption, épaisseur environ les deux tiers de la hauteur de la case : un cœur d'eau blanc sous pression "
		"entouré d'anneaux d'eau turquoise qui tournent en SPIRALE autour de lui, écume et gouttes arrachées sur les "
		"bords. Boucle : la spirale tourne et avance vers la droite."),
	("explosion_eau", "norm", "carre", True, 384, "EXPLOSION D'EAU",
		"une énorme explosion d'eau centrée, jouée UNE fois : image 1 un point d'impact blanc, images 2 à 4 une "
		"gerbe d'eau immense qui jaillit en étoile jusqu'aux bords de la case, écume blanche, images 5 à 7 elle se "
		"brise en paquets d'eau et en gouttes, image 8 il ne reste que des gouttes."),
	("pluie", "add", "pleine", False, 384, "PLUIE QUI TOMBE",
		"une PLUIE dense qui tombe sur toute la case : de longs traits de pluie fins, blancs et bleu pâle, légèrement "
		"inclinés vers la gauche en descendant, répartis sur toute la case du haut en bas, plus quelques gouttes plus "
		"grosses. Aucun nuage, aucun sol. Boucle : les traits descendent d'une image à l'autre."),
]

b.PARTICULES = [
	("part_o", "add", [
		("petite_bulle", "une petite bulle d'eau ronde et translucide, reflet blanc en haut à gauche"),
		("goutte_claire", "une goutte d'eau claire, bleu ciel, reflet blanc"),
		("anneau_eau", "un anneau d'onde à la surface de l'eau, fin, bleu clair, vide au centre"),
		("eclat_lumiere", "un scintillement de lumière sur l'eau, quatre branches fines, cœur blanc"),
		("mousse_eau", "un petit paquet d'écume blanche mousseuse"),
		("embrun", "un nuage d'embruns fins, gouttelettes blanches"),
		("filet_eau", "un filet d'eau vertical mince et ondulé, bleu clair"),
		("halo_eau", "une lueur ronde très douce, bleu pâle, qui s'estompe jusqu'au noir"),
	]),
	("part_p", "norm", [
		("valve_eau", "UNE valve de coquillage faite d'eau, grande coquille Saint-Jacques vue de face, nervures en "
			"éventail, turquoise translucide, bord d'écume blanche, ouverture tournée vers le BAS"),
		("pince_eau", "une énorme PINCE de crabe faite d'eau, ouverte, turquoise translucide, écume blanche sur les "
			"bords, gouttes qui s'en détachent"),
		("goutte_lourde", "une grosse goutte d'eau bleu clair, reflet blanc"),
		("paquet_eau", "un paquet d'eau éclaté en vol, bleu clair, écume"),
		("eclat_ecume", "une petite gerbe d'écume blanche et de gouttes"),
		("vaguelette", "une petite vague recourbée bleu clair, crête d'écume"),
		("flaque", "une flaque d'eau plate, vue de biais, reflets blancs"),
		("ride_eau", "des cercles concentriques sur l'eau, vue de biais, bleu clair"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
_INFO = {i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS}
## Celle de la chaîne de base (l'import de l'Électrik a remplacé `b._prompt_particules` par la sienne).
_prompt_particules_base = e._prompt_particules_base


def _prompt_flipbook(ident: str, mode: str, titre: str, consigne: str) -> str:
	fond = b.FOND_NOIR if mode == "add" else b.FOND_MAGENTA
	bande = _INFO[ident][0] == "bande"
	cases = ("divisée de façon invisible en 8 BANDES HORIZONTALES égales (2 colonnes × 4 rangées), de 768 × 256 chacune"
		if bande else "divisée de façon invisible en 8 cases égales (4 colonnes × 2 rangées), de 384 × 512 chacune")
	bord = ("l'effet remplit sa bande en largeur mais ne déborde jamais en hauteur sur la bande voisine"
		if bande else "l'effet ne déborde pas sur la case voisine")
	return (f"CV_FX_{ident.upper()} — NOUVELLE image : une PLANCHE de 8 images d'animation (images clés) d'un "
		f"effet d'attaque de combat : {titre}.\n\n{ADN_A}\n\n"
		f"Format : image 1536 × 1024, {cases}. Lecture : de gauche à droite puis rangée suivante. Même échelle, même "
		f"cadrage et même position de l'effet dans chaque case ; {bord} ; aucune ligne de séparation.\n"
		f"SUJET : {consigne}\n{fond}\n")


def _prompt_particules(ident: str, mode: str, sprites: list[tuple[str, str]]) -> str:
	return _prompt_particules_base(ident, mode, sprites).replace(b.ADN_FX, ADN_A)


b._prompt_flipbook = _prompt_flipbook
b._prompt_particules = _prompt_particules


def preparer() -> None:
	b.SORTIE.mkdir(parents=True, exist_ok=True)
	manifeste = {"flipbooks": {}, "particules": {}}
	for nom, mode, _t in b._images():
		src = b._revision(nom)
		if not src:
			print("manquant :", nom)
			continue
		if nom.startswith("CV_FX_PART"):
			cases = [b._alpha(c, mode) for c in b._cases(Image.open(src))]
			ident = next(i for i, _m, _s in b.PARTICULES if f"CV_FX_{i.upper()}_" in nom)
			sprites = next(s for i, _m, s in b.PARTICULES if i == ident)
			for (n, _d), im in zip(sprites, b._recadrer(cases, b.PART, False)):
				im.save(b.SORTIE / f"p_{n}.webp", lossless=True)
				manifeste["particules"][n] = {"fichier": f"p_{n}.webp", "taille": b.PART, "melange": mode}
		else:
			ident = next(i for i in _INFO if f"CV_FX_{i.upper()}_" in nom)
			cadrage, once, cote = _INFO[ident]
			cases = [b._alpha(c, mode) for c in e._cases(Image.open(src), cadrage)]
			if cadrage == "carre":
				cles = b._recadrer(cases, cote, True)
				if once:
					cles = [e._vignette(c) for c in cles]
			else:
				cles = [c.resize((cote, cote), Image.LANCZOS) for c in cases]
				if cadrage == "pleine":
					cles = [e._fondre_bas(c, 0.3) for c in cles]
				else:
					cles = [e._effiler(c) for c in cles]
			images = (e._unique if once else b._interpoler)(cles, b.NB_FINAL)
			b._atlas(images, 4).save(b.SORTIE / f"fb_{ident}.webp", lossless=True)
			manifeste["flipbooks"][ident] = {"fichier": f"fb_{ident}.webp", "images": b.NB_FINAL, "colonnes": 4,
				"taille": cote, "melange": mode, "boucle": not once}
		print("ok", nom, "←", src.name)
	(b.SORTIE / b.MANIFESTE).write_text(json.dumps(manifeste, indent=1, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		b.prompts()
	elif a[:1] == ["--preparer"]:
		preparer()
	elif a[:1] == ["--planche"]:
		b.planche()
	else:
		b.generer(a)
