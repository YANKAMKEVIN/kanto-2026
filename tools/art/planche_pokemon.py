#!/usr/bin/env python3
"""Dérivés et planche de validation des portraits de Pokémon (lot pilote).

Pour chaque portrait généré (fond transparent) : recadrage sur l'alpha, vignette de la grille du
Pokédex, silhouette (Pokémon inconnu, aplat sombre). La planche montre, à l'échelle du jeu
(référence 1920 × 1080) : la grille du Pokédex (vus puis inconnus), un grand portrait et les
silhouettes.
Usage :
  tools/art/planche_pokemon.py sortie.png portrait1.png portrait2.png ... [--grand portrait.png]
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FOND = (18, 26, 32, 255)
CASE = (34, 46, 54, 255)
CASE_BORD = (60, 76, 86, 255)
SILHOUETTE = (14, 20, 26, 235)
TEXTE = (220, 228, 232, 255)
NUMEROS = {"BULBIZARRE": 1, "SALAMECHE": 4, "CARAPUCE": 7, "ROUCOOL": 16, "RATTATA": 19,
	"PIAFABEC": 21, "NIDORAN_F": 29, "NIDORAN_M": 32, "FEROSINGE": 56}
TUILE = 112  # vignette de la grille, en pixels de référence (maquette : ≈ 105)
MARGE = 24


def recadrer(image: Image.Image) -> Image.Image:
	"""Recadre sur les pixels visibles (alpha > 16)."""
	alpha = image.getchannel("A").point(lambda a: 255 if a > 16 else 0)
	boite = alpha.getbbox()
	return image.crop(boite) if boite else image


def ajuster(image: Image.Image, cote: int) -> Image.Image:
	"""Réduit pour tenir dans un carré `cote` × `cote`, proportions gardées."""
	echelle = cote / max(image.size)
	taille = (max(1, round(image.width * echelle)), max(1, round(image.height * echelle)))
	return image.resize(taille, Image.LANCZOS)


def silhouette(image: Image.Image) -> Image.Image:
	plein = Image.new("RGBA", image.size, SILHOUETTE)
	plein.putalpha(image.getchannel("A").point(lambda a: min(a, SILHOUETTE[3])))
	return plein


def police(taille: int) -> ImageFont.ImageFont:
	for chemin in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default()


def tuile(image: Image.Image, numero: str, inconnu: bool) -> Image.Image:
	case = Image.new("RGBA", (TUILE, TUILE), (0, 0, 0, 0))
	dessin = ImageDraw.Draw(case)
	dessin.rounded_rectangle((0, 0, TUILE - 1, TUILE - 1), 14, fill=CASE, outline=CASE_BORD, width=2)
	sujet = ajuster(image, TUILE - 30)
	if inconnu:
		sujet = silhouette(sujet)
	case.alpha_composite(sujet, ((TUILE - sujet.width) // 2, TUILE - 8 - sujet.height))
	dessin.text((9, 6), numero, font=police(16), fill=TEXTE)
	return case


def main() -> None:
	arguments = argparse.ArgumentParser()
	arguments.add_argument("sortie")
	arguments.add_argument("portraits", nargs="+")
	arguments.add_argument("--grand", help="portrait affiché en grand (défaut : le premier)")
	options = arguments.parse_args()

	portraits = [(Path(p).stem, recadrer(Image.open(p).convert("RGBA"))) for p in options.portraits]
	colonnes = 5
	lignes = -(-len(portraits) // colonnes)
	largeur_grille = colonnes * TUILE + (colonnes - 1) * 10
	hauteur_grille = lignes * TUILE + (lignes - 1) * 10
	grand = recadrer(Image.open(options.grand).convert("RGBA")) if options.grand else portraits[0][1]
	grand = ajuster(grand, 520)

	largeur = MARGE * 4 + largeur_grille * 2 + 560
	hauteur = max(hauteur_grille, 560) + MARGE * 2 + 40
	planche = Image.new("RGBA", (largeur, hauteur), FOND)
	dessin = ImageDraw.Draw(planche)
	titre = police(22)
	x_vus, x_inconnus = MARGE, MARGE * 2 + largeur_grille
	x_grand = MARGE * 3 + largeur_grille * 2
	dessin.text((x_vus, MARGE), "Grille — vus", font=titre, fill=TEXTE)
	dessin.text((x_inconnus, MARGE), "Grille — inconnus (silhouettes)", font=titre, fill=TEXTE)
	dessin.text((x_grand, MARGE), "Portrait de la fiche", font=titre, fill=TEXTE)
	for rang, (nom, image) in enumerate(portraits):
		x = (rang % colonnes) * (TUILE + 10)
		y = MARGE + 40 + (rang // colonnes) * (TUILE + 10)
		espece = nom.removeprefix("POKE_").split("_FACE")[0]
		numero = f"{NUMEROS.get(espece, rang + 1):03d}"
		planche.alpha_composite(tuile(image, numero, False), (x_vus + x, y))
		planche.alpha_composite(tuile(image, numero, True), (x_inconnus + x, y))
	planche.alpha_composite(grand, (x_grand + (560 - grand.width) // 2, MARGE + 40 + 560 - grand.height))
	planche.save(options.sortie)
	print(options.sortie, planche.size)


if __name__ == "__main__":
	main()
