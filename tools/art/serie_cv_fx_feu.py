#!/usr/bin/env python3
"""Refonte des attaques Feu (direction A « flamme peinte », orange et jaune chauds, docs/tech/attaques-feu.md).
Même chaîne et mêmes cadrages que `serie_cv_fx_electrik.py` (carre, bande, pleine), plus « pleine_sol » : colonne qui
monte du bas de la case et s'estompe vers le haut (Feu Sacré).
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_feu.json."""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image

import serie_cv_fx as b
import serie_cv_fx_electrik as e

b.MANIFESTE = "manifeste_feu.json"
b.TITRE = "Attaques Feu, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-feu"
b.PROMPTS = b.ART / "prompts" / "cv_fx_feu"

ADN_A = """ADN VISUEL — FLAMME PEINTE (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, langues de feu vivantes et organiques. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : feu CHAUD. Cœur jaune pâle presque blanc, jaune vif, orange franc, bords orange profond à rouge-orangé, quelques braises. AUCUN bleu, AUCUN violet, AUCUN vert, AUCUN rose.
- Lumière NEUTRE : l'effet brille de lui-même ; aucun éclairage de scène, aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("flammeches", "add", "carre", False, 320, "PETITE GERBE DE FLAMMÈCHES EN VOL",
		"une PETITE gerbe de trois ou quatre flammèches qui volent ensemble vers la DROITE : une flammèche de tête plus "
		"grosse (cœur jaune pâle) et deux ou trois plus petites qui la suivent, chacune avec une courte queue de feu "
		"tirée vers la GAUCHE. Le groupe occupe environ la moitié de la largeur de la case, centré. Boucle : les "
		"flammes ondulent et changent de forme à chaque image."),
	("tourbillon_feu", "add", "carre", False, 384, "TOURBILLON DE FEU QUI ENFERME",
		"un TOURBILLON de feu en forme de colonne évasée, centré dans la case, qui occupe 80 % de la largeur et presque "
		"toute la hauteur : quatre ou cinq rubans de flammes qui s'enroulent en spirale autour d'un VIDE central, du bas "
		"vers le haut, comme une prison de feu qui tourne. L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : les rubans "
		"montent et tournent d'une image à l'autre."),
	("anneau_feu", "add", "carre", False, 320, "ROUE DE FEU AUTOUR D'UN CORPS",
		"un grand ANNEAU DE FEU ovale vertical, centré, qui occupe 85 % de la hauteur de la case : un cercle épais de "
		"flammes qui TOURNE comme une roue, les langues de feu étirées dans le sens de la rotation. L'INTÉRIEUR DE "
		"L'ANNEAU RESTE VIDE ET NOIR. Boucle : la roue tourne, les flammes changent à chaque image."),
	("trainee_feu", "add", "bande", False, 320, "TRAÎNÉE DE FEU D'UNE CHARGE",
		"une traînée de flammes horizontale laissée par quelque chose qui fonce vers la droite : épaisse et vive contre "
		"le bord DROIT, elle s'effiloche en langues de feu et en braises de plus en plus clairsemées jusqu'au bord "
		"GAUCHE. Flammes couchées vers la gauche. Tracé différent à chaque image."),
	("jet_flammes", "add", "bande", False, 384, "JET DE FLAMMES CONTINU ET ÉPAIS",
		"un JET DE FLAMMES CONTINU, horizontal, du bord GAUCHE exact jusqu'au bord DROIT exact de la case, sans "
		"interruption : un fleuve de feu épais (environ la moitié de la hauteur de la case) qui ondule doucement, cœur "
		"jaune pâle au centre, orange autour, bords orange profond qui se déchirent en petites langues. Boucle : les "
		"flammes coulent vers la droite d'une image à l'autre."),
	("colonne_feu", "add", "pleine_sol", False, 384, "COLONNE DE FLAMMES SACRÉES QUI JAILLIT DU SOL",
		"une colonne de flammes VERTICALE qui jaillit du bord BAS exact de la case et monte jusqu'au bord HAUT, large "
		"d'environ la moitié de la case : à la base, un évasement éclatant de feu en couronne ; un fût de flammes "
		"dorées et orange qui monte, cœur jaune pâle très lumineux, quelques rubans de feu qui s'enroulent autour ; le "
		"haut se dissout en langues de feu. Boucle : les flammes montent et se reforment à chaque image."),
	("etoile_feu", "add", "carre", False, 384, "ÉTOILE DE FEU À CINQ BRANCHES",
		"une grande ÉTOILE DE FEU À CINQ BRANCHES, pointe vers le haut, parfaitement centrée, qui occupe 85 % de la "
		"case : chaque branche est faite de flammes tirées vers sa pointe, cœur jaune pâle au centre de l'étoile, "
		"orange vif sur les branches, langues de feu qui débordent des arêtes. Boucle : les flammes des branches "
		"ondulent, la forme d'étoile reste nette et lisible."),
	("explosion_feu", "add", "carre", True, 384, "EMBRASEMENT DE L'ÉTOILE DE FEU",
		"un embrasement énorme centré, joué UNE fois : image 1 une étoile de feu compacte qui se fend de lumière, "
		"images 2 à 4 elle éclate en une boule de flammes immense jusqu'aux bords de la case, images 5 à 6 la boule se "
		"déchire en grandes langues de feu et en braises, images 7 à 8 il ne reste que des flammèches et des braises "
		"qui s'éteignent."),
	("eclat_feu", "add", "carre", True, 320, "EXPLOSION DE FLAMMES AU CONTACT",
		"une explosion de flammes COMPACTE et concentrée, centrée, jouée UNE fois : image 1 un point jaune pâle, "
		"image 2 une étoile de feu dure et serrée, images 3 à 5 les flammes jaillissent en gerbe dans toutes les "
		"directions avec des braises, images 6 à 8 les flammes s'effilochent et s'éteignent."),
	("rayons_soleil", "add", "pleine", False, 384, "SOLEIL ARDENT ET RAYONS",
		"un SOLEIL éclatant dans le coin HAUT DROIT de la case (disque jaune pâle presque blanc, halo doré), d'où "
		"partent de longs RAYONS de lumière chaude dorée qui descendent en éventail vers le bas et la gauche à travers "
		"toute la case, de plus en plus transparents. Boucle : les rayons scintillent et respirent doucement."),
]

b.PARTICULES = [
	("part_f", "add", [
		("flammeche", "une petite langue de feu dressée, cœur jaune pâle, bord orange"),
		("braise_vive", "un minuscule éclat incandescent orange et jaune avec une courte traînée"),
		("contact_flamme", "une étoile d'impact compacte à six pointes dures faites de flammes, cœur jaune pâle"),
		("halo_feu", "une lueur ronde large et très douce, orange pâle, jaune au centre, qui s'estompe jusqu'au noir"),
		("anneau_flamme", "un anneau fin de petites flammes, vide au centre"),
		("langue_feu", "une langue de feu recourbée en crochet, effilée, orange vif"),
		("eclat_soleil", "un scintillement de lumière dorée à quatre branches fines, cœur blanc chaud"),
		("volute_chaleur", "une volute de chaleur translucide orange pâle, ondulée, très douce"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
_INFO = {i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS}
## Détourés sur fond noir mais posés en mélange normal : matière dense qui garde ses couleurs sur un décor clair
## (en additif, ces grandes surfaces virent au blanc). Valeur : part de réchauffement (voir `_rechauffer`).
_MATIERE = {"tourbillon_feu": 0.1, "jet_flammes": 0.12, "colonne_feu": 0.15, "explosion_feu": 0.15}
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


def _rechauffer(im: Image.Image, part: float) -> Image.Image:
	"""Remonte les demi-tons vers l'orange chaud : détourée, la matière perd la lumière du noir."""
	a = np.asarray(im).astype(np.float32) / 255.0
	a[..., :3] = a[..., :3] * (1.0 - part) + np.array([1.0, 0.72, 0.3]) * part
	return Image.fromarray((a * 255).astype(np.uint8))


def _fondre_haut(im: Image.Image, part: float = 0.25) -> Image.Image:
	"""Estompe le haut d'une colonne qui monte du sol (le bas reste net, posé au pied de la cible)."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32)
	h = alpha.shape[0]
	rampe = np.clip(np.arange(h) / (h * part), 0.0, 1.0)
	im.putalpha(Image.fromarray((alpha * rampe[:, None]).astype(np.uint8)))
	return im


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
			if ident in _MATIERE:
				cases = [_rechauffer(c, _MATIERE[ident]) for c in cases]
			if cadrage == "carre":
				cles = b._recadrer(cases, cote, True)
				if once:
					cles = [e._vignette(c) for c in cles]
			else:
				cles = [c.resize((cote, cote), Image.LANCZOS) for c in cases]
				if cadrage == "pleine":
					cles = [e._fondre_bas(c, 0.3) for c in cles]
				elif cadrage == "pleine_sol":
					cles = [_fondre_haut(c) for c in cles]
				else:
					cles = [e._effiler(c) for c in cles]
			images = (e._unique if once else b._interpoler)(cles, b.NB_FINAL)
			b._atlas(images, 4).save(b.SORTIE / f"fb_{ident}.webp", lossless=True)
			manifeste["flipbooks"][ident] = {"fichier": f"fb_{ident}.webp", "images": b.NB_FINAL, "colonnes": 4,
				"taille": cote, "melange": "norm" if ident in _MATIERE else mode, "boucle": not once}
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
