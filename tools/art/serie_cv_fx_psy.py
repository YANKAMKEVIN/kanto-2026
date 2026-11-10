#!/usr/bin/env python3
"""Refonte des attaques Psy (direction A « psy peint », rose vif, magenta et violet, docs/tech/attaques-psy.md).
Même chaîne et mêmes cadrages que `serie_cv_fx_eau.py`. L'art Psy est rose : les masses denses sont détourées sur
VERT (`vert`, jamais sur magenta) et posées en mélange normal pour garder leurs roses sur le décor clair ; les lueurs
(œil, éclats, colonne de Téléport) restent additives sur noir.
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_psy.json."""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image

import serie_cv_fx as b
import serie_cv_fx_electrik as e

b.MANIFESTE = "manifeste_psy.json"
b.TITRE = "Attaques Psy, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-psy"
b.PROMPTS = b.ART / "prompts" / "cv_fx_psy"

ADN_A = """ADN VISUEL — PSY PEINT (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, énergie mentale dense et lumineuse. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : rose vif, magenta, violet, cœurs blanc rosé très lumineux ; quelques violets profonds pour le volume. AUCUN vert, AUCUN bleu ciel, AUCUN orange, AUCUN cœur (forme de cœur) ni étoile dessinée.
- Matière DENSE et bien visible, jamais pâle ni transparente au point de disparaître.
- Lumière NEUTRE : l'effet brille de lui-même ; aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("onde_choc_psy", "vert", "carre", True, 320, "ONDE DE CHOC MENTALE COMPACTE",
		"une onde de distorsion psychique centrée, jouée UNE fois : image 1 un petit nœud de lumière rose, images 2 à 4 "
		"un anneau épais rose et magenta qui se tord en vagues et s'élargit jusqu'aux trois quarts de la case, l'air "
		"autour ondule, images 5 à 7 l'anneau se resserre et se brise en volutes, image 8 presque vide."),
	("implosion_psy", "vert", "carre", True, 384, "SPHÈRE PSYCHIQUE QUI ÉCRASE PUIS EXPLOSE",
		"une énorme pression mentale centrée, jouée UNE fois : images 1 et 2 une grande SPHÈRE rose et violette dense, "
		"paroi épaisse veinée de lumière, qui occupe presque toute la case ; images 3 et 4 elle se COMPRIME vers le "
		"centre, de plus en plus petite et brillante ; images 5 à 7 elle EXPLOSE en une gerbe immense de lumière rose et "
		"blanche, éclats et volutes magenta jusqu'aux bords ; image 8 il ne reste que des volutes qui se dissipent."),
	("rayon_anneaux", "vert", "bande", False, 384, "RAYON D'ANNEAUX PSYCHIQUES",
		"UN rayon horizontal du bord GAUCHE exact jusqu'au bord DROIT exact de la case, sans interruption : un faisceau "
		"rose au cœur blanc, enfilé d'une suite d'ANNEAUX psychiques épais, rose vif et magenta aux reflets irisés, vus "
		"de biais, bien espacés, épaisseur environ la moitié de la hauteur de la bande. Boucle : les anneaux avancent "
		"vers la droite."),
	("onde_sinus", "vert", "bande", False, 384, "ONDES PSYCHIQUES SINUSOÏDALES",
		"DEUX ondes psychiques épaisses qui ondulent en SINUSOÏDE horizontale du bord GAUCHE exact au bord DROIT exact "
		"de la case, entrelacées, rose vif et violet, cœur blanc rosé, environ trois vagues sur la longueur, amplitude "
		"de la moitié de la hauteur de la bande. Boucle : les ondulations courent vers la droite."),
	("colonne_psy", "add", "pleine", False, 384, "COLONNE DE LUMIÈRE PSYCHIQUE",
		"une COLONNE VERTICALE de lumière psychique qui tombe du bord HAUT exact jusqu'au bord BAS exact de la case, "
		"large d'environ la moitié de la case : cœur blanc éclatant, rayons rose vif et magenta, stries verticales, "
		"anneaux lumineux qui descendent le long de la colonne. Boucle : la lumière descend d'une image à l'autre."),
	("oeil_lumiere", "add", "carre", False, 320, "ŒIL DE LUMIÈRE PSYCHIQUE",
		"un ŒIL stylisé fait de lumière, en amande horizontale, centré, qui occupe 80 % de la largeur de la case : "
		"paupières tracées en traits lumineux rose vif, iris rond magenta au cœur blanc, rayons fins qui en partent. "
		"Boucle : l'iris pulse et les rayons tournent doucement."),
	("eclat_psy", "add", "carre", True, 320, "ÉCLAT D'IMPACT PSYCHIQUE",
		"un impact psychique centré, joué UNE fois : image 1 un point blanc, images 2 à 4 une étoile de lumière rose "
		"et blanche avec un anneau d'onde qui s'ouvre, images 5 à 7 l'anneau s'élargit et les rayons s'éteignent, "
		"image 8 presque vide."),
	("anneau_hypnose", "vert", "carre", False, 320, "ANNEAU HYPNOTIQUE EN SPIRALE",
		"UN anneau HYPNOTIQUE vu de face, centré, qui occupe 80 % de la case : une SPIRALE épaisse rose vif et magenta "
		"qui s'enroule vers le centre, liserés blancs, centre vide. Boucle : la spirale tourne sur elle-même."),
	("spirale_hypnose", "vert", "carre", False, 320, "SPIRALES HYPNOTIQUES AUTOUR D'UNE TÊTE",
		"trois spirales hypnotiques rose vif et violettes qui tournent en ORBITE autour du centre vide de la case, en "
		"ellipse aplatie (comme autour d'une tête), traînées lumineuses, petites volutes de sommeil. Le centre reste "
		"vide. Boucle : les spirales tournent autour du centre."),
	("colonne_teleport", "add", "pleine", False, 384, "COLONNE DE TÉLÉPORTATION",
		"une colonne verticale de lumière du bord BAS jusqu'au bord HAUT de la case, large d'un tiers de la case, cœur "
		"blanc éclatant, bords rose vif, fragments de lumière et étincelles qui MONTENT le long de la colonne. Boucle : "
		"les fragments montent."),
	("aura_psy", "vert", "carre", False, 320, "AURA PSYCHIQUE PUISSANTE",
		"une aura psychique en forme de flamme ovale verticale, centrée, qui occupe 85 % de la case : contour épais de "
		"volutes rose vif et violettes qui montent, ondes de pression, liseré blanc. L'INTÉRIEUR RESTE VIDE. Boucle : "
		"les volutes montent et ondulent."),
	("aura_vitesse", "vert", "carre", False, 320, "TRAÎNÉES DE VITESSE PSYCHIQUES",
		"des TRAÎNÉES DE VITESSE psychiques autour du centre vide de la case : longs rubans rose vif et magenta qui "
		"filent à l'HORIZONTALE vers la GAUCHE, en arcs autour du centre, liserés blancs, comme des images rémanentes "
		"étirées. Le centre reste vide. Boucle : les rubans filent vers la gauche."),
	("lueur_repos", "add", "carre", False, 320, "LUEUR DE REPOS",
		"une lueur de soin ronde et douce mais bien visible, centrée, rose pâle et blanc, scintillements qui montent "
		"lentement, anneau lumineux au sol en bas de la case. Boucle : la lueur respire."),
	("z_sommeil", "vert", "carre", False, 320, "LETTRES Z DE SOMMEIL",
		"EXCEPTION À L'INTERDIT DES LETTRES : trois lettres « Z » de sommeil, de tailles croissantes, peintes en rose "
		"vif et lilas épais avec un contour blanc, qui MONTENT en zigzag du bas-gauche vers le haut-droite de la case. "
		"Rien d'autre comme texte. Boucle : les Z montent et grossissent."),
	("mur_hexagones", "vert", "carre", False, 384, "MUR DE CRISTAL HEXAGONAL",
		"un MUR vertical de CRISTAL psychique vu de face, qui occupe 85 % de la case : alvéoles HEXAGONALES à facettes "
		"rose et violet translucides, arêtes blanches lumineuses, reflets. Boucle : une lueur parcourt les alvéoles."),
	("panneau_verre", "vert", "carre", False, 384, "PANNEAU DE VERRE RÉFLÉCHISSANT",
		"un grand PANNEAU de verre rectangulaire vertical, LISSE, vu légèrement de biais, qui occupe 85 % de la case : "
		"surface rose pâle brillante, larges reflets blancs en diagonale, cadre fin lumineux rose vif. Boucle : un "
		"reflet glisse sur la surface."),
	("rideau_lumiere", "vert", "carre", False, 384, "RIDEAU DE LUMIÈRE",
		"un RIDEAU vertical fait de BANDES DE LUMIÈRE verticales serrées, dorées et rosées, qui descendent du haut de la "
		"case jusqu'en bas, occupe 85 % de la case, cœurs blancs, scintillements. Boucle : les bandes ondulent et "
		"descendent."),
	("voile_miroir", "vert", "carre", False, 384, "VOILE MIROIR COURBE",
		"une grande surface de MIROIR COURBE, en arc de cercle vertical comme un bouclier bombé, qui occupe 85 % de la "
		"case : reflets IRISÉS rose, lilas et blanc, bord lumineux rose vif. Boucle : les reflets irisés tournent."),
]

b.PARTICULES = [
	("part_psy_a", "vert", [
		("cuiller_psy", "UNE cuiller de métal tordue, posée en diagonale, nimbée de lumière rose, reflets blancs"),
		("fragment_cristal", "un éclat de cristal psychique rose et violet à facettes, arête blanche"),
		("bulle_reve", "une bulle de rêve rose pâle et lilas, reflet blanc, petite lueur au centre"),
		("volute_psy", "une volute de brume psychique rose et violette, enroulée"),
		("z_flottant", "EXCEPTION : une seule lettre « Z » de sommeil épaisse, rose vif, contour blanc"),
		("eclat_hexagone", "un petit hexagone de cristal rose translucide, arêtes blanches"),
		("plume_lumiere", "une petite plume de lumière rose pâle"),
		("goutte_psy", "une goutte d'énergie psychique magenta, cœur blanc"),
	]),
	("part_psy_b", "add", [
		("anneau_psy_rose", "un anneau d'onde psychique fin, rose vif, cœur blanc, vide au centre"),
		("etincelle_psy", "une étincelle de lumière rose à quatre branches fines, cœur blanc"),
		("halo_psy", "une lueur ronde rose, très douce, qui s'estompe jusqu'au noir"),
		("trait_vitesse", "un trait de vitesse horizontal, rose et blanc, effilé aux deux bouts"),
		("point_lumiere", "un point de lumière blanc rosé avec un petit halo"),
		("onde_fine", "une onde sinusoïdale courte, rose vif, cœur blanc"),
		("scintille_rose", "un scintillement rose et blanc, croix fine et halo"),
		("poussiere_psy", "une poignée de poussière lumineuse rose et lilas"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
_INFO = {i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS}
## Celle de la chaîne de base (l'import de l'Électrik a remplacé `b._prompt_particules` par la sienne).
_prompt_particules_base = e._prompt_particules_base


def _prompt_flipbook(ident: str, mode: str, titre: str, consigne: str) -> str:
	fond = b.FOND_NOIR if mode == "add" else b.FOND_VERT
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


def _densifier(im: Image.Image, gamma: float = 0.6) -> Image.Image:
	"""Matière plus dense : les voiles translucides du détourage deviennent de la matière."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32) / 255.0
	im.putalpha(Image.fromarray((alpha ** gamma * 255).astype(np.uint8)))
	return im


def _creuser(im: Image.Image, rayon: float = 0.85) -> Image.Image:
	"""Centre transparent : la lueur de Repos entoure le lanceur sans le cacher."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32)
	h, l = alpha.shape
	y, x = np.mgrid[0:h, 0:l]
	r = np.hypot((x - l / 2) / (l / 2), (y - h / 2) / (h / 2))
	im.putalpha(Image.fromarray((alpha * np.clip((r - rayon * 0.5) / (rayon * 0.5), 0.0, 1.0)).astype(np.uint8)))
	return im


## Lueurs creusées au centre (posées sur le lanceur, voir `_creuser`).
_CREUSES = {"lueur_repos"}


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
				if mode != "add":
					im = _densifier(im)
				im.save(b.SORTIE / f"p_{n}.webp", lossless=True)
				manifeste["particules"][n] = {"fichier": f"p_{n}.webp", "taille": b.PART, "melange": mode}
		else:
			ident = next(i for i in _INFO if f"CV_FX_{i.upper()}_" in nom)
			cadrage, once, cote = _INFO[ident]
			cases = [b._alpha(c, mode) for c in e._cases(Image.open(src), cadrage)]
			if cadrage == "carre":
				cles = b._recadrer(cases, cote, True)
			else:
				cles = [c.resize((cote, cote), Image.LANCZOS) for c in cases]
				cles = [e._fondre_bas(c, 0.3) if cadrage == "pleine" else e._effiler(c) for c in cles]
			if mode != "add":
				cles = [_densifier(c) for c in cles]
			if once and cadrage == "carre":
				# Après la densification, qui raidirait le fondu : une explosion qui touche sa case
				# n'y laisse pas de bord carré.
				cles = [e._vignette(c, 0.6) for c in cles]
			if ident in _CREUSES:
				cles = [_creuser(c) for c in cles]
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
