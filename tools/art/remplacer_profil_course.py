#!/usr/bin/env python3
"""Remplace les rangées de profil (gauche, droite) d'une planche de course 4 × 4.

La source est une bande générée d'UNE ligne de 4 poses tournées vers la DROITE, dans l'ordre du
cycle : contact A, passage (suspension), contact B, passage. La rangée droite (ligne 3) reçoit ces
poses, la rangée gauche (ligne 2) leur miroir. Les rangées face et dos ne bougent pas.

- Jambe lointaine : la bande générée peint les deux jambes de la même couleur (Codex ne tient pas
  la consigne), donc les contacts A et B se ressemblent. Des polygones (coordonnées de la bande,
  une liste par pose) délimitent la jambe LOINTAINE, qui est assombrie et bleuie : arrière au
  contact A, genou haut au passage 1, avant au contact B, repliée au passage 2. La peau (main
  qui passe devant) est épargnée.
- Échelle : la plus haute pose de contact prend la hauteur de la plus haute ancienne pose de
  profil (même taille de personnage que le reste de la planche).
- Ancrage : centre de la tête au centre de la cellule ; pieds des contacts sur le bas de la
  cellule (origine aux pieds) ; positions verticales relatives de la source conservées, plus un
  léger rebond (`--rebond`) sur les images de passage.
- Ordre des colonnes : les animations `run_*` de player_frames.tres jouent les colonnes
  1, 2, 3, 0 ; la pose i du cycle va donc en colonne (i + 1) % 4.
Usage :
  tools/art/remplacer_profil_course.py bande.png planche.png [--rebond 3] [--jambes poly.json]
Normalement appelé par preparer.py (champ `profil_course` de l'entrée du manifeste).
"""
from __future__ import annotations

import argparse
import json

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from decouper_perso import _bandes, _centre_tete

COLONNES, LIGNES = 4, 4
LIGNE_GAUCHE, LIGNE_DROITE = 1, 2


def _masque(image: Image.Image) -> Image.Image:
	return image.getchannel("A").point(lambda a: 255 if a > 96 else 0)


def _hauteur(pose: Image.Image) -> int:
	boite = _masque(pose).getbbox()
	return 0 if boite is None else boite[3] - boite[1]


def assombrir_jambes(bande: Image.Image, polygones: list[list[list[int]]]) -> Image.Image:
	"""Assombrit (ombre bleutée) l'intérieur des polygones, sauf la peau ; bord adouci."""
	zone = Image.new("L", bande.size, 0)
	dessin = ImageDraw.Draw(zone)
	for polygone in polygones:
		dessin.polygon([tuple(point) for point in polygone], fill=255)
	zone = zone.filter(ImageFilter.GaussianBlur(3))
	rouge, vert, bleu, alpha = bande.split()
	donnees = Image.merge("RGB", (rouge, vert, bleu)).load()
	masque_peau = Image.new("L", bande.size, 0)
	sortie_peau = masque_peau.load()
	for y in range(bande.height):
		for x in range(bande.width):
			r, g, b = donnees[x, y]
			if r > 170 and g > 120 and r - b > 40 and r - g < 90:
				sortie_peau[x, y] = 255
	zone = ImageChops.subtract(zone, masque_peau.filter(ImageFilter.GaussianBlur(1)))
	sombre = Image.merge("RGB", (
		rouge.point(lambda v: int(v * 0.50)),
		vert.point(lambda v: int(v * 0.53)),
		bleu.point(lambda v: int(v * 0.70)),
	))
	resultat = Image.composite(sombre, Image.merge("RGB", (rouge, vert, bleu)), zone)
	resultat.putalpha(alpha)
	return resultat


def _poses_bande(bande: Image.Image) -> list[tuple[Image.Image, int, int]]:
	"""(pose recadrée, haut, bas) des 4 poses de la bande, de gauche à droite."""
	masque = _masque(bande)
	largeur, hauteur = masque.size
	donnees = masque.load()
	colonnes = [sum(1 for y in range(hauteur) if donnees[x, y]) for x in range(largeur)]
	poses = []
	for gauche, droite in _bandes(colonnes, COLONNES):
		cellule = bande.crop((gauche, 0, droite, hauteur))
		boite = _masque(cellule).getbbox()
		poses.append((cellule.crop(boite), boite[1], boite[3]))
	if len(poses) != COLONNES:
		raise SystemExit(f"{len(poses)} poses trouvées au lieu de {COLONNES}")
	return poses


def _elargir(planche: Image.Image, cellule_l: int, cellule_h: int, nouvelle: int) -> Image.Image:
	"""Recopie chaque cellule au centre d'une cellule plus large (le centre ne bouge pas)."""
	sortie = Image.new("RGBA", (nouvelle * COLONNES, cellule_h * LIGNES), (0, 0, 0, 0))
	decalage = (nouvelle - cellule_l) // 2
	for ligne in range(LIGNES):
		for colonne in range(COLONNES):
			cellule = planche.crop((colonne * cellule_l, ligne * cellule_h,
				(colonne + 1) * cellule_l, (ligne + 1) * cellule_h))
			sortie.paste(cellule, (colonne * nouvelle + decalage, ligne * cellule_h))
	return sortie


def remplacer(source: str, chemin_planche: str, rebond: int = 3,
		jambe_lointaine: list | None = None) -> tuple[int, int]:
	"""Remplace les rangées de profil ; renvoie la taille (éventuellement élargie) d'une cellule."""
	planche = Image.open(chemin_planche).convert("RGBA")
	cellule_l, cellule_h = planche.width // COLONNES, planche.height // LIGNES
	anciennes = [
		planche.crop((c * cellule_l, LIGNE_DROITE * cellule_h,
			(c + 1) * cellule_l, (LIGNE_DROITE + 1) * cellule_h))
		for c in range(COLONNES)
	]
	bande = Image.open(source).convert("RGBA")
	if jambe_lointaine:
		bande = assombrir_jambes(bande, [p for pose in jambe_lointaine for p in pose])
	poses = _poses_bande(bande)
	cible = max(_hauteur(p) for p in anciennes)
	echelle = cible / max(_hauteur(poses[0][0]), _hauteur(poses[2][0]))
	sol = max(poses[0][2], poses[2][2])  # pieds des contacts
	reduites = []
	demi = cellule_l / 2
	for pose, haut, _bas in poses:
		reduite = pose.resize((round(pose.width * echelle), round(pose.height * echelle)),
			Image.LANCZOS)
		tete = _centre_tete(pose) * echelle
		demi = max(demi, tete + 1, reduite.width - tete + 1)
		reduites.append((reduite, tete, haut))
	nouvelle = max(cellule_l, 2 * int(demi + 0.999) + (cellule_l % 2))
	if nouvelle > cellule_l:
		planche = _elargir(planche, cellule_l, cellule_h, nouvelle)
		print(f"cellules élargies : {cellule_l} → {nouvelle} px")
		cellule_l = nouvelle
	print(f"cellule {cellule_l} × {cellule_h}, échelle {echelle:.4f}")
	for index, (reduite, tete, haut) in enumerate(reduites):
		x = round(cellule_l / 2 - tete)
		y = cellule_h - round((sol - haut) * echelle) - (rebond if index % 2 else 0)
		droite = Image.new("RGBA", (cellule_l, cellule_h), (0, 0, 0, 0))
		droite.alpha_composite(reduite.crop((0, max(0, -y), reduite.width, reduite.height)),
			(x, max(0, y)))
		colonne = (index + 1) % COLONNES
		for ligne, image in ((LIGNE_DROITE, droite),
				(LIGNE_GAUCHE, droite.transpose(Image.FLIP_LEFT_RIGHT))):
			origine = (colonne * cellule_l, ligne * cellule_h)
			planche.paste(Image.new("RGBA", (cellule_l, cellule_h), (0, 0, 0, 0)), origine)
			planche.paste(image, origine)
		print(f"  pose {index + 1} → colonne {colonne} : {reduite.size}, x {x}, y {y}")
	planche.save(chemin_planche)
	return cellule_l, cellule_h


def main() -> None:
	arguments = argparse.ArgumentParser()
	arguments.add_argument("source")
	arguments.add_argument("planche")
	arguments.add_argument("--rebond", type=int, default=3)
	arguments.add_argument("--jambes", help="JSON : polygones de la jambe lointaine par pose")
	options = arguments.parse_args()
	jambes = json.loads(open(options.jambes).read()) if options.jambes else None
	remplacer(options.source, options.planche, options.rebond, jambes)


if __name__ == "__main__":
	main()
