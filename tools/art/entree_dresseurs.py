#!/usr/bin/env python3
"""Lot d'art de l'entrée des combats de Dresseur (fiche docs/design/fiches-assets/entree-dresseurs.md).

Cible : les trois maquettes validées docs/design/reference/entree-dresseur-*-v1.png. Chaque génération
Codex reçoit la ou les maquettes ENTIÈRES et des agrandissements de l'élément visé (cible exacte).

  tools/art/entree_dresseurs.py refs                 # agrandissements des maquettes → build/art/entree/
  tools/art/entree_dresseurs.py generer ED_HUGO [r]  # Codex → build/art/ED_HUGO_r<r>.png
  tools/art/entree_dresseurs.py exporter             # détourage, recadrage, export WebP aux chemins de la fiche
  tools/art/entree_dresseurs.py planches             # planche du lot + montage de contrôle sur les maquettes

Prompts : tools/art/entree_dresseurs/prompts/<ID>.txt. Les sources retenues (révision) sont dans RETENUS.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parents[2]
ART = RACINE / "build" / "art"
ENT = ART / "entree"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "prompts"
REF = RACINE / "docs" / "design" / "reference"
M1 = REF / "entree-dresseur-ordinaire-v1.png"
M2 = REF / "entree-dresseur-lancer-v1.png"
M3 = REF / "entree-dresseur-vs-v1.png"
SPR = RACINE / "assets" / "sprites" / "trainers" / "battle"
VS = RACINE / "assets" / "ui" / "battle" / "vs"

# Agrandissements de référence : (maquette, boîte, nom, facteur).
REFS = [
	(M1, (1200, 230, 1380, 480), "ref_hugo_debout.png", 3),
	(M2, (1190, 180, 1420, 480), "ref_hugo_lancer.png", 3),
	(M1, (360, 330, 700, 820), "ref_joueur_debout.png", 2),
	(M2, (180, 330, 600, 840), "ref_joueur_lancer.png", 2),
	(M3, (1240, 320, 1380, 580), "ref_pierre_debout.png", 3),
	(M3, (400, 280, 640, 620), "ref_joueur_vs.png", 2),
	(M3, (1480, 0, 1844, 250), "ref_buste_pierre.png", 2),
	(M3, (0, 530, 360, 853), "ref_buste_kevin.png", 2),
	(M3, (560, 0, 1844, 260), "ref_banderole_rouge.png", 1),
	(M3, (0, 560, 1180, 853), "ref_banderole_bleue.png", 1),
	(M3, (770, 240, 1080, 580), "ref_vs.png", 2),
	(M2, (1000, 195, 1250, 270), "ref_ball.png", 4),
]

# Images jointes par génération (maquettes entières d'abord, puis agrandissements).
JOINTES = {
	"ED_HUGO": [M1, M2, ENT / "ref_hugo_debout.png", ENT / "ref_hugo_lancer.png"],
	"ED_PIERRE": [M3, ENT / "ref_pierre_debout.png", M2],
	"ED_JOUEUR": [M1, M2, ENT / "ref_joueur_debout.png", ENT / "ref_joueur_lancer.png"],
	"ED_BUSTE_PIERRE": [M3, ENT / "ref_buste_pierre.png"],
	"ED_BUSTE_KEVIN": [M3, ENT / "ref_buste_kevin.png"],
	"ED_BANDEROLES": [M3, ENT / "ref_banderole_rouge.png", ENT / "ref_banderole_bleue.png"],
	"ED_EMBLEME": [M3, ENT / "ref_vs.png"],
	"ED_JOUEUR_RETOUCHE": [ART / "ED_JOUEUR_r2.png"],
	"ED_DECOR_ROUTE3": [M1, M2],
	"ED_DECOR_ARENE": [M3],
	# Itération 4 (revue de Codex sur le comparatif v3).
	"ED_DECOR_ARENE_V3": [M3],
	"ED_BUSTE_PIERRE_V2": [M3, ENT / "ref_buste_pierre.png", ART / "ED_BUSTE_PIERRE_r1.png"],
	"ED_BUSTE_KEVIN_V2": [M3, ENT / "ref_buste_kevin.png", ART / "ED_BUSTE_KEVIN_r1.png"],
	"ED_HUGO_LANCER_V2": [M2, ENT / "ref_hugo_lancer.png", ENT / "gamin_lancer_actuel.png"],
	"ED_BALL_FX": [M2, ENT / "ref_ball.png"],
}
# Décors v2 : composition retenue → deux tuiles repeintes en plus grand (recette de
# tools/art/combat_decors/preparer_decor.py, manifeste tools/art/combat_decors/decors.json).
DECORS = {"ROUTE3": ("ED_DECOR_ROUTE3_r1.png", "ED_TUILE_ROUTE3"),
	"ARENE": ("ED_DECOR_ARENE_r1.png", "ED_TUILE_ARENE"),
	# Itération 4 : Arène v3, vue de trois-quarts (r2 retenue : r1 restait frontale).
	"ARENE_V3": ("ED_DECOR_ARENE_V3_r2.png", "ED_TUILE_ARENE")}
PORTIONS = {"TL": (0, 0, 1000, 852), "TR": (846, 0, 1846, 852)}


def tuiles() -> None:
	"""Découpe les portions des compositions (images jointes des tuiles)."""
	for compo, _ in DECORS.values():
		im = Image.open(ART / compo).convert("RGB")
		for cote, boite in PORTIONS.items():
			im.crop(boite).save(ENT / compo.replace(".png", f"_{cote}_src.png"))


def generer_tuile(decor: str, cote: str) -> None:
	compo, prompt = DECORS[decor]
	sortie = compo.replace(".png", f"_{cote}")
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), sortie, str(PROMPTS / f"{prompt}.txt"),
		str(ENT / compo.replace(".png", f"_{cote}_src.png"))]
	rc = subprocess.call(cmd, cwd=RACINE)
	# generer.sh ajoute « .png » à l'identifiant : rien d'autre à renommer.
	sys.exit(rc)


def refs() -> None:
	ENT.mkdir(parents=True, exist_ok=True)
	for maquette, boite, nom, f in REFS:
		x = Image.open(maquette).convert("RGB").crop(boite)
		x.resize((x.width * f, x.height * f), Image.LANCZOS).save(ENT / nom)


def generer(ident: str, rev: str = "1", sans_jointes: bool = False) -> None:
	jointes = [] if sans_jointes else [str(p) for p in JOINTES.get(ident, [])]
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"{ident}_r{rev}",
		str(PROMPTS / f"{ident}.txt"), *jointes]
	sys.exit(subprocess.call(cmd, cwd=RACINE))


# Sources retenues (révision) par élément.
RETENUS = {
	"ED_HUGO": "1", "ED_PIERRE": "1", "ED_JOUEUR_RETOUCHE": "1", "ED_BUSTE_PIERRE": "1",
	"ED_BUSTE_KEVIN": "1", "ED_BANDEROLES": "1", "ED_EMBLEME": "1",
	# Itération 4 : bustes cadrés poitrine, lancer d'Hugo plus projeté, Ball et traînée.
	"ED_BUSTE_PIERRE_V2": "1", "ED_BUSTE_KEVIN_V2": "1", "ED_HUGO_LANCER_V2": "1", "ED_BALL_FX": "1",
}
# Lancer d'Hugo v2 : une seule pose, peinte un peu plus grande que la planche d'origine ; ramenée
# à l'échelle de la pose debout (largeur de la casquette mesurée sur les deux images).
HUGO_LANCER_V2_ECHELLE = 0.9
FX = SPR / "fx"


def source(ident: str) -> Image.Image:
	return Image.open(ART / f"{ident}_r{RETENUS[ident]}.png").convert("RGBA")


def _plages(masque: np.ndarray, largeur_min: int = 50) -> list[tuple[int, int]]:
	"""Plages de colonnes non vides (une par pose)."""
	plages, debut = [], None
	for i, v in enumerate(list(masque.any(0)) + [False]):
		if v and debut is None:
			debut = i
		elif not v and debut is not None:
			if i - debut >= largeur_min:
				plages.append((debut, i))
			debut = None
	return plages


def _nettoyer(image: Image.Image) -> Image.Image:
	"""Alpha faible remis à zéro (voile résiduel), couleur des bords gardée."""
	a = np.asarray(image).copy()
	a[..., 3] = np.where(a[..., 3] < 8, 0, a[..., 3])
	return Image.fromarray(a)


def poses(ident: str) -> list[Image.Image]:
	"""Les poses d'une planche (gauche → droite), recadrées au plus juste."""
	im = _nettoyer(source(ident))
	masque = np.asarray(im)[..., 3] > 96
	sorties = []
	for x0, x1 in _plages(masque):
		sous = im.crop((x0, 0, x1, im.height))
		boite = sous.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
		sorties.append(sous.crop(boite))
	return sorties


def mettre_en_toile(images: list[Image.Image], toile: tuple[int, int], marge_haut: int,
		marge_cote: int = 4) -> list[Image.Image]:
	"""Même échelle pour toutes les poses (pas de saut de taille au changement de pose), pieds
	sur le bord bas, boîte centrée horizontalement. Jamais d'agrandissement."""
	w, h = toile
	echelle = min(1.0, *[(h - marge_haut) / i.height for i in images],
		*[(w - 2 * marge_cote) / i.width for i in images])
	sorties = []
	for i in images:
		r = i.resize((round(i.width * echelle), round(i.height * echelle)), Image.LANCZOS)
		t = Image.new("RGBA", toile, (0, 0, 0, 0))
		t.alpha_composite(r, ((w - r.width) // 2, h - r.height))
		sorties.append(t)
	print(f"  échelle {echelle:.3f}")
	return sorties


def _centre_pieds(image: Image.Image, part: float = 0.06) -> float:
	"""x du milieu des pieds : milieu de l'étendue des pixels opaques des `part` lignes du bas."""
	a = np.asarray(image)[..., 3] > 96
	bas = a[int(a.shape[0] * (1 - part)):]
	xs = np.where(bas.any(0))[0]
	return (xs[0] + xs[-1]) / 2.0 if len(xs) else image.width / 2.0


def poses_en_toile(debout: Image.Image, lancer: Image.Image, toile: tuple[int, int],
		marge_haut: int) -> tuple[Image.Image, Image.Image]:
	"""Itération 4 : le jeu met la pose debout à la hauteur voulue (pixels visibles) et donne la
	MÊME échelle à la pose de lancer, centrée en x, pieds au bas. La pose debout remplit donc sa
	toile (512 × 768) ; la pose de lancer garde la même échelle et le milieu des pieds au centre,
	sur une toile de même hauteur ÉLARGIE si le bras dépasse (le bras n'est jamais rogné)."""
	w, h = toile
	echelle = min(1.0, (h - marge_haut) / debout.height, (w - 8) / debout.width,
		(h - marge_haut) / lancer.height)
	sorties = []
	for i in (debout, lancer):
		r = i.resize((round(i.width * echelle), round(i.height * echelle)), Image.LANCZOS)
		pieds = _centre_pieds(r)
		demi = max(pieds, r.width - pieds) + 4
		largeur = max(w, int(np.ceil(demi)) * 2)
		t = Image.new("RGBA", (largeur, h), (0, 0, 0, 0))
		t.alpha_composite(r, (round(largeur / 2 - pieds), h - r.height))
		sorties.append(t)
	print(f"  échelle {echelle:.3f}, toiles {sorties[0].size} et {sorties[1].size}")
	return sorties[0], sorties[1]


def _webp(image: Image.Image, chemin: Path, qualite: int = 92) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	image.save(chemin, "WEBP", quality=qualite, method=6, exact=True)
	print(f"  {chemin.relative_to(RACINE)} {image.size}")


def buste(ident: str, toile=(540, 720), marge_haut: int = 18) -> Image.Image:
	"""Tête et épaules, largeur de la toile, haut de la tête près du bord haut, bas rogné."""
	im = _nettoyer(source(ident))
	boite = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
	im = im.crop((0, boite[1], im.width, im.height))
	echelle = toile[0] / im.width
	r = im.resize((toile[0], round(im.height * echelle)), Image.LANCZOS)
	t = Image.new("RGBA", toile, (0, 0, 0, 0))
	t.alpha_composite(r.crop((0, 0, toile[0], toile[1] - marge_haut)), (0, marge_haut))
	return t


def banderoles(toile=(2048, 300)) -> list[Image.Image]:
	"""Deux bandes horizontales ; allongées à 2048 px en répétant leur milieu (fondu enchaîné),
	sans étirer la peinture, puis mises à 300 px d'épaisseur."""
	im = _nettoyer(source("ED_BANDEROLES"))
	a = np.asarray(im)[..., 3] > 96
	lignes, debut, plages = a.any(1), None, []
	for i, v in enumerate(list(lignes) + [False]):
		if v and debut is None:
			debut = i
		elif not v and debut is not None:
			if i - debut > 80:
				plages.append((debut, i))
			debut = None
	sorties = []
	for y0, y1 in plages:
		bande = im.crop((0, y0, im.width, y1))
		boite = bande.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
		bande = bande.crop((boite[0], 0, boite[2], bande.height))
		echelle = toile[1] / bande.height
		bande = bande.resize((round(bande.width * echelle), toile[1]), Image.LANCZOS)
		bande = _allonger(bande, toile[0])
		sorties.append(bande)
	return sorties


def _allonger(bande: Image.Image, largeur: int, fondu: int = 160) -> Image.Image:
	"""Insère des copies du tronçon central (après le bout déchiré) avec fondu enchaîné."""
	src = np.asarray(bande).astype(np.float64)
	debut = int(bande.width * 0.45)
	troncon = src[:, debut:]
	sortie = src.copy()
	while sortie.shape[1] < largeur:
		n = sortie.shape[1]
		t = np.linspace(0, 1, fondu)[None, :, None]
		melange = sortie[:, n - fondu:] * (1 - t) + troncon[:, :fondu] * t
		sortie = np.concatenate([sortie[:, :n - fondu], melange, troncon[:, fondu:]], axis=1)
	return Image.fromarray(np.clip(sortie[:, :largeur], 0, 255).astype(np.uint8))


def embleme(largeur: int = 720) -> Image.Image:
	im = _nettoyer(source("ED_EMBLEME"))
	boite = im.getchannel("A").point(lambda v: 255 if v > 4 else 0).getbbox()
	im = im.crop(boite)
	if im.width > largeur:
		im = im.resize((largeur, round(im.height * largeur / im.width)), Image.LANCZOS)
	return im


def exporter() -> None:
	print("ED_HUGO + ED_HUGO_LANCER_V2")
	debout = poses("ED_HUGO")[0]
	lancer = poses("ED_HUGO_LANCER_V2")[0]
	lancer = lancer.resize((round(lancer.width * HUGO_LANCER_V2_ECHELLE),
		round(lancer.height * HUGO_LANCER_V2_ECHELLE)), Image.LANCZOS)
	debout, lancer = poses_en_toile(debout, lancer, (512, 768), 16)
	_webp(debout, SPR / "gamin.webp")
	_webp(lancer, SPR / "gamin_lancer.webp")
	for ident, nom, toile, marge in (("ED_PIERRE", "pierre", (512, 768), 16), ("ED_JOUEUR_RETOUCHE", "dos_hero", (640, 960), 16)):
		print(ident)
		debout, lancer = poses_en_toile(*poses(ident), toile, marge)
		_webp(debout, SPR / f"{nom}.webp")
		_webp(lancer, SPR / f"{nom}_lancer.webp")
	_webp(buste("ED_BUSTE_PIERRE_V2"), VS / "pierre.webp")
	# Buste du joueur au cadrage de la maquette 3 (pas encore de chemin dans la fiche §3).
	_webp(buste("ED_BUSTE_KEVIN_V2"), VS / "hero.webp")
	rouge, bleue = banderoles()
	_webp(rouge, VS / "banderole_rouge.webp")
	_webp(bleue, VS / "banderole_bleue.webp")
	_webp(embleme(), VS / "emblem.webp")
	trainee, ball = fx()
	_webp(trainee, FX / "ball_trail.webp")
	_webp(ball, FX / "ball.webp")


def fx() -> tuple[Image.Image, Image.Image]:
	"""Traînée (bande du haut, pointe à droite, bout épais à gauche) et Ball (bande du bas)."""
	im = _nettoyer(source("ED_BALL_FX"))
	a = np.asarray(im)[..., 3] > 24
	lignes = a.any(1)
	milieu = im.height // 2
	haut = im.crop((0, 0, im.width, milieu))
	bas = im.crop((0, milieu, im.width, im.height))
	trainee = haut.crop(haut.getchannel("A").point(lambda v: 255 if v > 4 else 0).getbbox())
	ball = _rogne(bas)
	ball = ball.resize((256, round(ball.height * 256 / ball.width)), Image.LANCZOS)
	return trainee, ball


# ---------------------------------------------------------------- planche et montage de contrôle

FONTE = RACINE / "assets" / "fonts" / "cinzel" / "Cinzel.ttf"
DECORS_V2 = RACINE / "assets" / "battle" / "decors"


def _fonte(taille: int, cinzel: bool = False) -> ImageFont.FreeTypeFont:
	if cinzel:
		return ImageFont.truetype(str(FONTE), taille)
	for f in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"):
		if Path(f).exists():
			return ImageFont.truetype(f, taille)
	return ImageFont.load_default()


def _rogne(image: Image.Image) -> Image.Image:
	return image.crop(image.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox())


def _poser(fond: Image.Image, sprite: Path, pieds: tuple[int, int], hauteur: int) -> None:
	"""Sprite (rogné) à la hauteur du personnage de la maquette, milieu du bas sur `pieds`."""
	s = _rogne(Image.open(sprite).convert("RGBA"))
	s = s.resize((round(s.width * hauteur / s.height), hauteur), Image.LANCZOS)
	fond.alpha_composite(s, (pieds[0] - s.width // 2, pieds[1] - s.height))


def _ombre(fond: Image.Image, pieds: tuple[int, int], largeur: int) -> None:
	calque = Image.new("RGBA", fond.size, (0, 0, 0, 0))
	ImageDraw.Draw(calque).ellipse((pieds[0] - largeur // 2, pieds[1] - largeur // 8,
		pieds[0] + largeur // 2, pieds[1] + largeur // 8), fill=(40, 25, 10, 110))
	fond.alpha_composite(calque.filter(ImageFilter.GaussianBlur(largeur / 14)))


def _decor(nom: str, taille: tuple[int, int]) -> Image.Image:
	return Image.open(DECORS_V2 / f"{nom}_back.webp").convert("RGBA").resize(taille, Image.LANCZOS)


def _banderole(fond, texture, bout, angle, nom, titre, buste, buste_boite, buste_dessus) -> None:
	"""Banderole (texture inclinée) + nom en Cinzel + buste, approximativement au cadrage de la
	maquette 3 (le jeu fait la mise en page réelle)."""
	t = Image.open(texture).convert("RGBA")
	larg, haut = bout[2] - bout[0], bout[3] - bout[1]
	t = t.resize((larg, haut), Image.LANCZOS)
	if "bleue" in texture.name:
		t = t.transpose(Image.FLIP_LEFT_RIGHT)
	d = ImageDraw.Draw(t)
	f = _fonte(int(haut * 0.42), True)
	cx = larg * (0.40 if titre else 0.55)
	d.text((cx, haut * (0.40 if titre else 0.52)), nom, font=f, anchor="mm", fill=(250, 226, 160),
		stroke_width=3, stroke_fill=(70, 40, 15))
	if titre:
		d.text((cx, haut * 0.78), titre, font=_fonte(int(haut * 0.15), True), anchor="mm",
			fill=(245, 236, 215))
	# buste_boite = (x, y, largeur, bas) : buste mis à `largeur`, posé en (x, y), rogné à `bas`.
	bx, by, bl, bbas = buste_boite
	b = Image.open(buste).convert("RGBA")
	b = b.resize((bl, round(b.height * bl / b.width)), Image.LANCZOS)
	b = b.crop((0, 0, bl, max(1, min(b.height, bbas - by))))
	t = t.rotate(angle, resample=Image.BICUBIC, expand=True)
	if not buste_dessus:
		fond.alpha_composite(b, (bx, by))
	fond.alpha_composite(t, (bout[0] - (t.width - larg) // 2, bout[1] - (t.height - haut) // 2))
	if buste_dessus:
		fond.alpha_composite(b, (bx, by))


def recompositions() -> list[Image.Image]:
	"""Les trois maquettes refaites avec le lot (décors v2 + sprites aux mêmes places et aux
	mêmes hauteurs que les personnages des maquettes, mesurées sur les maquettes)."""
	taille = Image.open(M1).size
	scenes = []
	# 1. Entrée ordinaire : Hugo debout, joueur bras tendu (pose lancer de dos).
	f = _decor("route_3_roche_v2", taille)
	_ombre(f, (1292, 466), 120)
	_poser(f, SPR / "gamin.webp", (1292, 470), 224)
	_poser(f, SPR / "dos_hero_lancer.webp", (500, 808), 470)
	scenes.append(f)
	# 2. Lancer : Hugo lance, joueur en garde.
	f = _decor("route_3_roche_v2", taille)
	_ombre(f, (1312, 466), 150)
	_poser(f, SPR / "gamin_lancer.webp", (1300, 472), 250)
	_poser(f, SPR / "dos_hero.webp", (388, 830), 490)
	t = Image.open(FX / "ball_trail.webp").convert("RGBA")
	t = t.resize((200, max(1, round(t.height * 200 / t.width))), Image.LANCZOS)
	f.alpha_composite(t, (1040, 214))
	b = Image.open(FX / "ball.webp").convert("RGBA").resize((46, 46), Image.LANCZOS)
	f.alpha_composite(b, (1012, 211))
	scenes.append(f)
	# 3. VS : Pierre debout, joueur de dos, banderoles, bustes, emblème.
	f = _decor("pewter_gym_roche_v3", taille)
	_ombre(f, (1312, 562), 110)
	_poser(f, SPR / "pierre.webp", (1312, 566), 232)
	_poser(f, SPR / "dos_hero.webp", (520, 640), 345)
	_banderole(f, VS / "banderole_rouge.webp", (960, 70, 1900, 245), 4, "PIERRE",
		"Champion d’Arène d’Argenta", VS / "pierre.webp", (1510, 0, 330, 250), True)
	_banderole(f, VS / "banderole_bleue.webp", (-60, 600, 1180, 800), 4, "KEVIN", "",
		VS / "hero.webp", (10, 520, 380, 853), True)
	e = Image.open(VS / "emblem.webp").convert("RGBA")
	e = e.resize((300, round(e.height * 300 / e.width)), Image.LANCZOS)
	f.alpha_composite(e, (925 - 150, 420 - e.height // 2))
	scenes.append(f)
	return scenes


def planches() -> None:
	# Montage de contrôle : maquette | recomposition avec le lot.
	scenes = recompositions()
	w, h = Image.open(M1).size
	s = 0.5
	lw, lh = int(w * s), int(h * s)
	marge, entete = 16, 34
	montage = Image.new("RGB", (2 * lw + 3 * marge, 3 * (lh + entete) + marge), (18, 22, 28))
	d = ImageDraw.Draw(montage)
	noms = ["1. Entrée ordinaire", "2. Lancer", "3. Séquence « VS »"]
	for i, (maquette, scene) in enumerate(zip((M1, M2, M3), scenes)):
		y = i * (lh + entete) + entete
		for j, (img, leg) in enumerate(((Image.open(maquette).convert("RGB"), "maquette validée"),
				(scene.convert("RGB"), "lot d'art pilote (décors v2 et v3, sprites aux mêmes places et échelles)"))):
			x = marge + j * (lw + marge)
			montage.paste(img.resize((lw, lh), Image.LANCZOS), (x, y))
			d.text((x, y - 26), f"{noms[i]} — {leg}", font=_fonte(20), fill=(235, 220, 170))
	montage.save(RACINE / "docs/design/fiches-assets/entree-dresseurs-art-pilote-controle.jpg",
		quality=88)

	# Planche du lot : chaque fichier sur fond neutre, avec son chemin.
	elements = [SPR / f for f in ("gamin.webp", "gamin_lancer.webp", "pierre.webp",
		"pierre_lancer.webp", "dos_hero.webp", "dos_hero_lancer.webp")]
	elements += [VS / f for f in ("pierre.webp", "hero.webp", "emblem.webp")]
	elements += [FX / "ball.webp", FX / "ball_trail.webp"]
	cellule, haut = 300, 420
	planche = Image.new("RGB", (cellule * 11 + 20, 1400), (30, 34, 40))
	d = ImageDraw.Draw(planche)
	damier = Image.new("RGBA", (cellule - 10, haut), (0, 0, 0, 0))
	dd = ImageDraw.Draw(damier)
	for yy in range(0, haut, 20):
		for xx in range(0, cellule - 10, 20):
			dd.rectangle((xx, yy, xx + 19, yy + 19),
				fill=(78, 84, 92) if (xx // 20 + yy // 20) % 2 else (64, 70, 78))
	for k, p in enumerate(elements):
		x = 10 + k * cellule
		fond = damier.copy()
		im = Image.open(p).convert("RGBA")
		r = min((cellule - 20) / im.width, (haut - 10) / im.height)
		im = im.resize((round(im.width * r), round(im.height * r)), Image.LANCZOS)
		fond.alpha_composite(im, ((fond.width - im.width) // 2, haut - im.height))
		planche.paste(fond.convert("RGB"), (x, 40))
		d.text((x, 470), str(p.relative_to(RACINE / "assets")), font=_fonte(14), fill=(220, 220, 220))
		d.text((x, 490), f"{Image.open(p).size[0]} × {Image.open(p).size[1]}", font=_fonte(14),
			fill=(160, 160, 160))
	d.text((10, 10), "Entrée des combats de Dresseur — lot d'art pilote (2026-11-02)", font=_fonte(22),
		fill=(235, 220, 170))
	y = 530
	for p in (VS / "banderole_rouge.webp", VS / "banderole_bleue.webp"):
		im = Image.open(p).convert("RGBA")
		im = im.resize((1300, round(im.height * 1300 / im.width)), Image.LANCZOS)
		fond = Image.new("RGBA", im.size, (70, 76, 84, 255))
		fond.alpha_composite(im)
		planche.paste(fond.convert("RGB"), (10, y))
		d.text((1320, y + 70), str(p.relative_to(RACINE / "assets")) + "  2048 × 300", font=_fonte(14),
			fill=(220, 220, 220))
		y += im.height + 20
	for k, nom in enumerate(("route_3_roche_v2", "pewter_gym_roche_v2", "pewter_gym_roche_v3")):
		im = Image.open(DECORS_V2 / f"{nom}_back.webp").convert("RGB")
		im = im.resize((1300, 600), Image.LANCZOS).resize((640, 295), Image.LANCZOS)
		x = 10 + k * 660
		planche.paste(im, (x, y))
		d.text((x, y + 300), f"battle/decors/{nom}_back.webp  2340 × 1080", font=_fonte(14),
			fill=(220, 220, 220))
	planche = planche.crop((0, 0, planche.width, y + 330))
	planche.save(RACINE / "docs/design/fiches-assets/entree-dresseurs-art-pilote.jpg", quality=88)


if __name__ == "__main__":
	action = sys.argv[1]
	if action == "refs":
		refs()
	elif action == "tuile":
		generer_tuile(sys.argv[2], sys.argv[3])
	elif action == "generer":
		generer(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "1", "--seul" in sys.argv)
	else:
		globals()[action]()
