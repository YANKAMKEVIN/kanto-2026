#!/usr/bin/env python3
"""Refonte des attaques électriques (direction A « foudre peinte », or et blanc, docs/tech/attaques-electriques.md).
Même chaîne que `serie_cv_fx.py` (fond, détourage, interpolation), avec trois cadrages de planche :
  - « carre »  : 8 cases 4 × 2 de 384 × 512, effet centré, recadrage commun carré ;
  - « bande »  : 8 cases 2 × 4 de 768 × 256, effet horizontal qui touche les bords gauche et droit ; case entière
    ramenée au carré (anamorphose : le jeu l'étire entre le lanceur et la cible) ;
  - « pleine » : 8 cases 4 × 2 de 384 × 512, case entière ramenée au carré (colonne de foudre, du haut en bas).
`once` : flipbook joué une seule fois (l'interpolation ne reboucle pas sur la première image).
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_electrik.json."""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image

import serie_cv_fx as b

b.MANIFESTE = "manifeste_electrik.json"
b.TITRE = "Attaques électriques, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-electrik"
b.PROMPTS = b.ART / "prompts" / "cv_fx_electrik"

ADN_A = """ADN VISUEL — FOUDRE PEINTE (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne : coups de pinceau visibles, légère granularité picturale, filaments vivants et organiques. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : UNIQUEMENT or et blanc. Cœur blanc pur éblouissant, jaune doré franc, bord or chaud ambré. AUCUN bleu, AUCUN violet, AUCUN cyan.
- Lumière NEUTRE : l'effet brille de lui-même ; aucun éclairage de scène, aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("eclair_fin", "add", "bande", False, 320, "ÉCLAIR FIN",
		"UNE SEULE décharge électrique FINE et nerveuse, horizontale, qui part exactement du bord GAUCHE et arrive "
		"exactement au bord DROIT de la case, sans interruption. Tronc mince (environ un douzième de la hauteur de la "
		"case), zigzags vifs et courts, quatre ou cinq petites ramifications. Le tracé est DIFFÉRENT à chaque image."),
	("courant_tresse", "add", "bande", False, 384, "COURANT DE FOUDRE TRESSÉE",
		"un COURANT ÉPAIS de foudre TRESSÉE, horizontal : cinq à sept filaments ondulants blancs et or qui s'entrelacent "
		"comme les torons d'une corde, du bord GAUCHE exact jusqu'au bord DROIT exact de la case, sans la moindre "
		"interruption. Épaisseur totale : environ la moitié de la hauteur de la case, régulière d'un bout à l'autre. "
		"Cœur blanc éblouissant au milieu de la tresse, de fines vrilles dorées s'en échappent. Boucle : d'une image à "
		"l'autre les torons glissent, se croisent et se recroisent (la dernière image enchaîne avec la première)."),
	("trainee_foudre", "add", "bande", False, 320, "TRAÎNÉE DE FOUDRE D'UNE CHARGE",
		"une traînée de foudre horizontale laissée par quelque chose qui fonce vers la droite : très dense, large et "
		"blanche contre le bord DROIT, elle s'effiloche en stries et filaments dorés de plus en plus clairsemés jusqu'au "
		"bord GAUCHE. Stries presque parallèles, quelques petits arcs qui sautent entre elles. Tracé différent à chaque image."),
	("cage_eclair", "add", "carre", False, 320, "CAGE DE FILAMENTS ÉLECTRIQUES",
		"une cage en forme de ballon faite de CINQ OU SIX ANNEAUX DE FOUDRE dorée, ellipses aplaties, libres et irrégulières, "
		"empilées du bas vers le haut et chacune légèrement inclinée d'un côté différent, centrée dans la case, qui occupe "
		"80 % de la largeur. Pas de méridiens ni de quadrillage : uniquement ces anneaux horizontaux inclinés, au tracé "
		"vivant et ondulé, comme des fils lumineux jetés autour de quelque chose. L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : "
		"les anneaux glissent et s'inclinent un peu d'une image à l'autre, petits arcs qui sautent de l'un à l'autre."),
	("aura_etincelle", "add", "carre", False, 320, "CORPS COUVERT D'ÉLECTRICITÉ",
		"une vingtaine de PETITS ARCS ÉLECTRIQUES courts, dorés et blancs, ÉPARPILLÉS et séparés les uns des autres dans "
		"un volume ovale vertical (la place d'un corps) : plus nombreux vers les bords, quelques-uns au milieu, certains "
		"jaillissent vers l'extérieur. SURTOUT PAS d'anneau, de contour continu ni de cercle : aucun arc ne touche son "
		"voisin, on doit voir beaucoup de noir entre eux. Tracés et positions tous différents d'une image à l'autre (ça grésille)."),
	("impact_foudre", "add", "carre", True, 320, "IMPACT DE FOUDRE",
		"un impact de foudre centré dans la case, joué UNE fois : image 1 un petit point blanc, puis un éclat blanc qui "
		"gonfle (2 à 3), de longues fourches de foudre dorée qui jaillissent dans toutes les directions (4 à 5), puis les "
		"fourches se brisent en étincelles (6 à 7), presque vide à la fin (8)."),
	("onde_choc_foudre", "add", "carre", True, 320, "ONDE DE CHOC ÉLECTRIQUE CONCENTRÉE",
		"un coup unique, très concentré, centré dans la case, joué UNE fois : image 1 un point blanc minuscule, image 2 "
		"une étoile blanche très dure et compacte, images 3 à 5 un anneau de choc net et brillant s'ouvre autour d'elle, "
		"avec des aiguilles de foudre très courtes et droites, images 6 à 8 l'anneau s'amincit et se dissipe."),
	("colonne_foudre", "add", "pleine", False, 384, "COLONNE DE FOUDRE COLOSSALE",
		"une colonne de foudre ÉNORME et VERTICALE qui remplit la case du bord HAUT exact au bord BAS exact, large "
		"d'environ la moitié de la case : un fût de plusieurs troncs de foudre serrés, blanc éblouissant au centre, or "
		"sur les bords, avec des ramifications latérales dorées, et un évasement éclatant en bas de la case. Le tracé "
		"se reforme à chaque image (ça tonne, boucle)."),
	("nuages_orage", "norm", "bande", False, 320, "PLAFOND DE NUAGES D'ORAGE",
		"un plafond de lourds nuages d'orage anthracite vu de face, qui remplit la moitié haute de la case d'un bord à "
		"l'autre, avec au centre un œil en spirale éclairé d'or de l'intérieur ; le bas des nuages s'effiloche et se "
		"dissout en vapeurs. De petits éclairs dorés courent dans les volutes. Boucle : les volutes tournent lentement "
		"autour de l'œil. Couleurs : gris anthracite, gris-brun, or chaud. Aucun rose, aucun magenta dans les nuages."),
	("sphere_instable", "add", "carre", False, 384, "ÉNORME SPHÈRE ÉLECTRIQUE INSTABLE",
		"une énorme sphère d'énergie électrique DENSE, parfaitement centrée dans la case, qui occupe 85 % de la largeur : "
		"intérieur bouillonnant de plasma doré en masses boursouflées, surface striée d'éclairs blancs qui courent en "
		"réseau, quelques arcs qui s'échappent de la sphère et claquent vers l'extérieur. Elle paraît lourde et sur le "
		"point d'éclater. Boucle : la surface se tord et palpite, le réseau d'éclairs change à chaque image."),
	("explosion_foudre", "add", "carre", True, 384, "EXPLOSION DE LA SPHÈRE ÉLECTRIQUE",
		"une gigantesque explosion électrique centrée, jouée UNE fois : image 1 une sphère dorée compacte qui se fend de "
		"lumière blanche, images 2 à 4 elle enfle brutalement en une boule immense de foudre dorée et blanche, longues "
		"fourches jusqu'aux bords de la case, images 5 à 6 la boule se déchire en lambeaux et en réseaux d'éclairs, "
		"images 7 à 8 il ne reste que des filaments dorés et des étincelles qui s'éteignent."),
]

b.PARTICULES = [
	("part_e", "add", [
		("fil_foudre", "un petit filament de foudre sinueux, blanc et or, très fin, légèrement bouclé"),
		("fourche_foudre", "une courte fourche d'éclair à trois branches, cœur blanc, or chaud"),
		("halo_or", "une lueur ronde large et très douce, or pâle, blanche au centre, qui s'estompe jusqu'au noir"),
		("anneau_foudre", "un anneau fin et crépitant de foudre dorée, vide au centre, léger tremblement du trait"),
		("eclair_or", "un éclair vertical doré, tronc brisé du haut en bas de la case, deux petites ramifications"),
		("braise_foudre", "un minuscule éclat incandescent blanc-or avec une courte traînée lumineuse"),
		("arc_joue", "un petit arc électrique en boucle serrée, comme un crépitement sur une joue, blanc et or"),
		("etoile_contact", "une étoile d'impact compacte à six pointes dures, cœur blanc, or chaud sur les pointes"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
_INFO = {i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS}
## Détourés sur fond noir mais posés en mélange normal : matière dense qui garde son or sur un décor clair
## (en additif, ces grandes surfaces virent au blanc).
## Valeur : part du dorage (voir `_dorer`) ; assez faible pour garder le contraste du tracé sur le décor.
_MATIERE = {"courant_tresse": 0.12, "colonne_foudre": 0.25, "sphere_instable": 0.18, "explosion_foudre": 0.2}
_prompt_particules_base = b._prompt_particules


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


def _cases(img: Image.Image, cadrage: str) -> list[Image.Image]:
	if cadrage != "bande":
		return b._cases(img)
	l, h = img.size
	cw, ch = l // 2, h // 4
	return [img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)) for r in range(4) for c in range(2)]


def _unique(images: list[Image.Image], n: int) -> list[Image.Image]:
	"""Interpolation d'un flipbook joué une fois : de la première à la dernière image, sans reboucler."""
	k = len(images) - 1
	sortie = []
	for i in range(n):
		t = i * k / (n - 1)
		a, f = min(int(t), k - 1), t - min(int(t), k - 1)
		sortie.append(Image.blend(images[a].convert("RGBa"), images[a + 1].convert("RGBa"), f).convert("RGBA"))
	return sortie


def _dorer(im: Image.Image, part: float = 0.4) -> Image.Image:
	"""Remonte l'orange des demi-tons vers l'or : détourée, la matière perd la lumière du noir."""
	a = np.asarray(im).astype(np.float32) / 255.0
	a[..., :3] = a[..., :3] * (1.0 - part) + np.array([1.0, 0.92, 0.55]) * part
	return Image.fromarray((a * 255).astype(np.uint8))


def _vignette(im: Image.Image, debut: float = 0.82) -> Image.Image:
	"""Bords d'un impact fondus en rond : une explosion qui touche sa case n'y laisse pas d'arête droite."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32)
	h, l = alpha.shape
	y, x = np.mgrid[0:h, 0:l]
	r = np.hypot((x - l / 2) / (l / 2), (y - h / 2) / (h / 2))
	im.putalpha(Image.fromarray((alpha * np.clip((1.0 - r) / (1.0 - debut), 0.0, 1.0)).astype(np.uint8)))
	return im


def _effiler(im: Image.Image, gauche: float = 0.05, droite: float = 0.08) -> Image.Image:
	"""Bouts d'une bande fondus : un courant qui s'allonge n'a pas d'extrémité coupée au carré."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32)
	l = alpha.shape[1]
	x = np.arange(l)
	rampe = np.clip(x / (l * gauche), 0.0, 1.0) * np.clip((l - x) / (l * droite), 0.0, 1.0)
	im.putalpha(Image.fromarray((alpha * rampe[None, :]).astype(np.uint8)))
	return im


def _fondre_bas(im: Image.Image, part: float = 0.14) -> Image.Image:
	"""Estompe le bas d'une colonne, coupé net au bord de sa case (l'impact recouvre la jonction)."""
	alpha = np.asarray(im.getchannel("A")).astype(np.float32)
	h = alpha.shape[0]
	rampe = np.clip((h - np.arange(h)) / (h * part), 0.0, 1.0)
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
			cases = [b._alpha(c, mode) for c in _cases(Image.open(src), cadrage)]
			if ident in _MATIERE:
				cases = [_dorer(c, _MATIERE[ident]) for c in cases]
			if cadrage == "carre":
				cles = b._recadrer(cases, cote, True)
				if once:
					cles = [_vignette(c) for c in cles]
			else:
				cles = [c.resize((cote, cote), Image.LANCZOS) for c in cases]
				cles = [_fondre_bas(c) if cadrage == "pleine" else _effiler(c) for c in cles]
			images = (_unique if once else b._interpoler)(cles, b.NB_FINAL)
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
