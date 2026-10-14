#!/usr/bin/env python3
"""Planche de contact de la série 14 (Pokémon, T3) : découpe de jeu, échelle réelle.

Pour chaque espèce candidate (build/art/decoupe/<NOM>.png, produit par
`decouper_perso.py source sortie --hauteur H`) : les 4 directions (1re image de chaque ligne)
sur un fond d'herbe (1 case = 96 px), à côté du héros et de Rattata existants. Deux sorties :
  <sortie>_1x.png  échelle du jeu (1 px = 1 px de la référence 1920 × 1080)
  <sortie>_2x.png  zoom ×2 pour juger les silhouettes
Usage : tools/art/contact_serie14_pokemon.py sortie_sans_extension [NOM ...]
Aucune intégration : lecture seule des planches existantes de assets/.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
DEC = RACINE / "build/art/decoupe"
PEINT = RACINE / "assets/sprites/pokemon/painted"
NOMS = ["RONDOUDOU", "MELOFEE", "ABO", "PARAS", "NOSFERAPTI", "RACAILLOU_MARCHE", "ROUCOUPS",
	"NIDORINO", "NIDORINA", "RATTATAC", "RAPASDEPIC"]
REPERES = [("heros", RACINE / "assets/sprites/characters/painted/heros_sheet.png"),
	("rattata", PEINT / "rattata_sheet.png"), ("racaillou*", PEINT / "racaillou_sheet.png"),
	("nidoran_f", PEINT / "nidoran_f_sheet.png"), ("piafabec", PEINT / "piafabec_sheet.png")]
CASE = 96


def poses(chemin: Path) -> list[Image.Image]:
	planche = Image.open(chemin).convert("RGBA")
	w, h = planche.width // 4, planche.height // 4
	if planche.height < 120:  # planche d'attente d'une seule ligne (racaillou) : 1 pose
		return [planche.crop((0, 0, planche.width // 4, planche.height))] * 4
	return [planche.crop((0, r * h, w, (r + 1) * h)) for r in range(4)]


def fond(largeur: int, hauteur: int) -> Image.Image:
	image = Image.new("RGBA", (largeur, hauteur), (96, 140, 70, 255))
	d = ImageDraw.Draw(image)
	for x in range(0, largeur, CASE):
		d.line([(x, 0), (x, hauteur)], fill=(84, 126, 60, 255))
	for y in range(0, hauteur, CASE):
		d.line([(0, y), (largeur, y)], fill=(84, 126, 60, 255))
	return image


def main() -> None:
	sortie = sys.argv[1]
	noms = sys.argv[2:] or NOMS
	lignes = [(n, DEC / f"{n}.png") for n in noms if (DEC / f"{n}.png").exists()]
	lignes = [(n, p) for n, p in REPERES if p.exists()] + lignes
	largeur, hauteur = 4 * CASE + 16, CASE * 2 - 24
	colonnes = 4
	lignes_par_colonne = (len(lignes) + colonnes - 1) // colonnes
	toile = fond(colonnes * largeur, lignes_par_colonne * CASE * 2 // 1)
	d = ImageDraw.Draw(toile)
	for i, (nom, chemin) in enumerate(lignes):
		cx, cy = (i % colonnes) * largeur, (i // colonnes) * CASE * 2
		d.text((cx + 6, cy + 4), nom, fill=(255, 255, 255, 255))
		for k, pose in enumerate(poses(chemin)):
			x = cx + 8 + k * CASE + (CASE - pose.width) // 2
			y = cy + CASE * 2 - 28 - pose.height
			toile.alpha_composite(pose, (x, y))
	toile.save(f"{sortie}_1x.png")
	toile.resize((toile.width * 2, toile.height * 2), Image.LANCZOS).save(
		f"{sortie}_2x.png")
	print(f"{sortie}_1x.png {toile.size}")


if __name__ == "__main__":
	main()
