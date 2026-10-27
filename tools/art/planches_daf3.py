#!/usr/bin/env python3
"""Planches de validation des lots DAF.3 « Safrania et Sylphe » et DAF.4 « Fin du jeu » (part déjà
dans `main`) pour Kevin : captures du jeu en 2340 × 1080 avant / après (`tools/capture_daf3.sh`),
façades et modules à l'échelle du jeu, fonds de combat.

  tools/capture_daf3.sh build/captures/daf3/avant     (avant le lot, une fois)
  tools/capture_daf3.sh build/captures/daf3/apres
  python3 tools/art/planches_daf3.py

Écrit `docs/design/fiches-assets/daf-3/planche-*.jpg`, `daf-4/planche-*.jpg` et la synthèse
lisible sur téléphone `daf-3/synthese-telephone.jpg` (portrait 1080 px de large).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
AVANT = RACINE / "build/captures/daf3/avant"
APRES = RACINE / "build/captures/daf3/apres"
DAF3 = RACINE / "docs/design/fiches-assets/daf-3"
DAF4 = RACINE / "docs/design/fiches-assets/daf-4"
FOND = (34, 38, 46)
TEXTE = (236, 238, 242)
GRIS = (160, 166, 178)


def _police(taille: int) -> ImageFont.FreeTypeFont:
	for chemin in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial Bold.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default(size=taille)


def _ecrire(image: Image.Image, chemin: Path) -> None:
	chemin = chemin.with_suffix(".jpg")  # JPEG : planches de relecture, poids du dépôt
	chemin.parent.mkdir(parents=True, exist_ok=True)
	image.convert("RGB").save(chemin, quality=88, optimize=True)
	print(chemin.relative_to(RACINE), image.size)


def _avant_apres(noms: list[tuple[str, str]], titre: str, largeur: int = 1170) -> Image.Image:
	"""Une rangée par capture : avant à gauche, après à droite (moitié de 2340 × 1080)."""
	h = largeur * 1080 // 2340
	entete = 90
	planche = Image.new("RGB", (2 * largeur + 30, entete + len(noms) * (h + 56)), FOND)
	d = ImageDraw.Draw(planche)
	d.text((16, 20), titre, font=_police(44), fill=TEXTE)
	y = entete
	for nom, legende in noms:
		d.text((16, y + 8), f"{legende} — avant", font=_police(28), fill=GRIS)
		d.text((largeur + 30, y + 8), "après", font=_police(28), fill=TEXTE)
		for x, dossier in ((0, AVANT), (largeur + 30, APRES)):
			chemin = dossier / f"{nom}.png"
			if chemin.exists():
				planche.paste(Image.open(chemin).convert("RGB").resize((largeur, h), Image.LANCZOS),
					(x, y + 48))
		y += h + 56
	return planche


def _contact(fichiers: list[tuple[str, str]], titre: str, echelle: float, largeur: int = 2400,
		fond=(96, 124, 92)) -> Image.Image:
	"""Assets à l'échelle du jeu × `echelle`, en rangées, nom dessous."""
	vignettes = []
	for chemin, nom in fichiers:
		image = Image.open(RACINE / chemin).convert("RGBA")
		image = image.resize((max(1, round(image.width * echelle)), max(1, round(image.height * echelle))),
			Image.LANCZOS)
		vignettes.append((image, nom))
	rangees, rangee, x = [], [], 0
	for v in vignettes:
		if x + v[0].width > largeur - 40 and rangee:
			rangees.append(rangee)
			rangee, x = [], 0
		rangee.append(v)
		x += v[0].width + 30
	rangees.append(rangee)
	hauteurs = [max(v[0].height for v in r) + 50 for r in rangees]
	planche = Image.new("RGB", (largeur, 90 + sum(hauteurs)), fond)
	d = ImageDraw.Draw(planche)
	d.text((16, 20), titre, font=_police(44), fill=TEXTE)
	y = 90
	for r, hr in zip(rangees, hauteurs):
		x = 20
		for image, nom in r:
			planche.paste(image, (x, y + hr - 50 - image.height), image)
			d.text((x, y + hr - 44), nom, font=_police(22), fill=TEXTE)
			x += image.width + 30
		y += hr
	return planche


FACADES = ["sylphe_safrania_01", "arene_safrania_01", "dojo_safrania_01", "maison_safrania_01",
	"maison_safrania_02", "maison_safrania_03", "immeuble_safrania_01", "immeuble_safrania_02",
	"immeuble_safrania_03", "immeuble_bas_safrania_01", "immeuble_bas_safrania_02", "poste_safrania_nord_01",
	"poste_safrania_sud_01", "poste_safrania_ouest_01", "poste_safrania_est_01"]


def planche_facades() -> None:
	_ecrire(_avant_apres([("safrania_sylphe", "Sylphe SARL et Centre"), ("safrania_nord", "Dojo et Arène"),
		("safrania_ouest", "Ouest, poste de la Route 7"), ("safrania_sud", "Sud, poste de la Route 6"),
		("safrania_centre", "Centre Pokémon"), ("safrania_est", "Est, poste de la Route 8")],
		"DAF.3 — Safrania : 15 façades peintes (captures 2340 × 1080)"), DAF3 / "planche-1-safrania.png")
	_ecrire(_contact([(f"assets/world/buildings/bldg_{f}.png", f) for f in FACADES],
		"DAF.3 — les 15 façades à 1/2 de l'échelle du jeu (1 case = 48 px ici)", 0.5),
		DAF3 / "planche-2-facades.png")


def planche_sylphe() -> None:
	_ecrire(_avant_apres([("sylphe_1f", "Sylphe 1F (hall)"), ("sylphe_3f", "Sylphe 3F (portes électroniques)"),
		("sylphe_7f", "Sylphe 7F (rival, téléporteurs)"), ("sylphe_11f", "Sylphe 11F (Giovanni)"),
		("sylphe_cabine", "Cabine d'ascenseur")],
		"DAF.3 — Sylphe SARL en modules (une seule série de textures pour 11 étages)"),
		DAF3 / "planche-3-sylphe.png")
	w, i, r, g = "assets/world/", "assets/world/interiors/", "assets/world/relief/", "assets/world/ground/"
	_ecrire(_contact([(f"{g}ground_moquette_sylphe_01.png", "moquette"), (f"{g}ground_masse_batiment_01.png", "masse"),
		*[(f"{r}relief_mur_sylphe_0{n}.png", f"mur_0{n}") for n in range(1, 6)],
		(f"{i}int_bureau_sylphe_01.png", "bureau"), (f"{i}int_serveur_sylphe_01.png", "serveurs"),
		(f"{i}int_plante_sylphe_01.png", "plante"), (f"{i}int_escalier_sylphe_monte_01.png", "monte"),
		(f"{i}int_escalier_sylphe_descend_01.png", "descend"), (f"{i}int_porte_ascenseur_sylphe_01.png", "ascenseur"),
		(f"{i}decal_teleporteur_sylphe_01.png", "téléporteur"), (f"{i}decal_seuil_sylphe_01.png", "seuil"),
		(f"{i}int_paillasson_sylphe_01.png", "paillasson"), (f"{i}int_porte_sylphe_h_01.png", "porte H"),
		(f"{i}int_porte_sylphe_v_01.png", "porte V"), (f"{i}int_silph_co_elevator_coque.png", "cabine")],
		"DAF.3 — kit de la Sylphe à l'échelle du jeu (1 case = 96 px)", 1.0), DAF3 / "planche-4-kit-sylphe.png")
	del w


def planche_arenes() -> None:
	_ecrire(_avant_apres([("arene_morgane", "Arène de Morgane"), ("dojo", "Dojo")],
		"DAF.3 — Arène de Morgane et Dojo en modules"), DAF3 / "planche-5-arene-dojo.png")
	_ecrire(_avant_apres([("arene_jadielle", "Arène de Jadielle")],
		"DAF.4 — Arène de Jadielle en modules (dalles fléchées et cases d'arrêt)"),
		DAF4 / "planche-1-arene-jadielle.png")


def planche_combats() -> None:
	fonds = [("silph_co_bureaux", "Sylphe : bureaux"), ("saffron_gym_psy", "Arène de Morgane"),
		("fighting_dojo_salle", "Dojo"), ("viridian_gym_sol", "Arène de Jadielle")]
	l, h = 1170, 540
	planche = Image.new("RGB", (2 * l + 30, 90 + 2 * (h + 56)), FOND)
	d = ImageDraw.Draw(planche)
	d.text((16, 20), "DAF.3 / DAF.4 — fonds de combat dédiés (remplacent les décors [D])", font=_police(44),
		fill=TEXTE)
	for k, (ident, legende) in enumerate(fonds):
		x, y = (k % 2) * (l + 30), 90 + (k // 2) * (h + 56)
		d.text((x + 8, y + 8), legende, font=_police(28), fill=TEXTE)
		chemin = RACINE / f"assets/battle/decors/{ident}_back.webp"
		if chemin.exists():
			planche.paste(Image.open(chemin).convert("RGB").resize((l, h), Image.LANCZOS), (x, y + 48))
	_ecrire(planche, DAF3 / "planche-6-fonds-combat.png")


def synthese() -> None:
	"""Portrait 1080 px : une paire avant / après par lieu, empilées (lisible sur téléphone)."""
	paires = [("safrania_sylphe", "Safrania"), ("safrania_nord", "Dojo et Arène (façades)"),
		("sylphe_7f", "Sylphe 7F"), ("arene_morgane", "Arène de Morgane"), ("dojo", "Dojo"),
		("arene_jadielle", "Arène de Jadielle")]
	l = 1080
	h = l * 1080 // 2340
	bloc = 2 * h + 110
	planche = Image.new("RGB", (l, 140 + len(paires) * bloc), FOND)
	d = ImageDraw.Draw(planche)
	d.text((24, 30), "DAF.3 + DAF.4 : avant / après", font=_police(54), fill=TEXTE)
	y = 140
	for nom, legende in paires:
		d.text((24, y), legende, font=_police(40), fill=TEXTE)
		for k, (dossier, mot) in enumerate(((AVANT, "avant"), (APRES, "après"))):
			yy = y + 56 + k * (h + 4)
			chemin = dossier / f"{nom}.png"
			if chemin.exists():
				planche.paste(Image.open(chemin).convert("RGB").resize((l, h), Image.LANCZOS), (0, yy))
			d.rectangle((0, yy, 150, yy + 46), fill=FOND)
			d.text((12, yy + 4), mot, font=_police(34), fill=TEXTE if k else GRIS)
		y += bloc
	_ecrire(planche, DAF3 / "synthese-telephone.png")


if __name__ == "__main__":
	planche_facades()
	planche_sylphe()
	planche_arenes()
	planche_combats()
	synthese()
