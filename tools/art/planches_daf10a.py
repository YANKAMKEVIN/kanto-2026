#!/usr/bin/env python3
"""Planches de validation du lot DAF.10a (règle DA-6) : captures « avant » / « après » 2340 × 1080
(`tools/capture_daf10a.sh`) assemblées en JPEG dans `docs/design/fiches-assets/daf-10a/`.

  python3 tools/art/planches_daf10a.py
"""
import unicodedata
from pathlib import Path
from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
AVANT = RACINE / "build/captures/avant_10a"
APRES = RACINE / "build/captures/apres_10a"
SORTIE = RACINE / "docs/design/fiches-assets/daf-10a"
LARGEUR = 1500


def _vue(dossier: Path, carte: str, rogner: bool = True) -> Image.Image:
	image = Image.open(dossier / f"{carte}.png").convert("RGB")
	if rogner:  # retire les bandes noires de part et d'autre de la carte
		fond = image.getpixel((5, 5))
		boite = Image.eval(image.convert("L"), lambda v: 255 if v > 12 else 0).getbbox()
		if boite:
			image = image.crop(boite)
	return image


def _etiquette(image: Image.Image, texte: str) -> Image.Image:
	haut = 44
	sortie = Image.new("RGB", (image.width, image.height + haut), (24, 24, 28))
	sortie.paste(image, (0, haut))
	ascii_ = unicodedata.normalize("NFKD", texte.replace("—", "-")).encode("ascii", "ignore").decode()
	ImageDraw.Draw(sortie).text((14, 12), ascii_, fill=(240, 235, 220))
	return sortie


def _paire(carte: str, titre: str, colonnes: int = 2) -> Image.Image:
	vues = []
	for nom, dossier in (("avant", AVANT), ("après", APRES)):
		if (dossier / f"{carte}.png").exists():
			vue = _vue(dossier, carte)
			vue.thumbnail((LARGEUR // colonnes, 1400))
			vues.append(_etiquette(vue, f"{titre} — {nom}"))
	largeur = sum(v.width for v in vues) + 10 * (len(vues) - 1)
	sortie = Image.new("RGB", (largeur, max(v.height for v in vues)), (24, 24, 28))
	x = 0
	for v in vues:
		sortie.paste(v, (x, 0))
		x += v.width + 10
	return sortie


def _pile(images: list[Image.Image], nom: str) -> None:
	largeur = max(i.width for i in images)
	hauteur = sum(i.height for i in images) + 12 * (len(images) - 1)
	sortie = Image.new("RGB", (largeur, hauteur), (24, 24, 28))
	y = 0
	for i in images:
		sortie.paste(i, (0, y))
		y += i.height + 12
	sortie.save(SORTIE / nom, quality=88)
	print(nom, sortie.size)


def main() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	_pile([_paire("fuchsia_city", "Parmanie", 2)], "planche-1-parmanie.jpg")
	_pile([_paire("fuchsia_gym", "Arène de Parmanie", 2)], "planche-2-arene.jpg")
	_pile([_paire("safari_zone_center", "Parc Safari, Centre"),
		_paire("safari_zone_north", "Parc Safari, Nord")], "planche-3-parc.jpg")
	_pile([_paire("safari_zone_east", "Parc Safari, Est"),
		_paire("safari_zone_west", "Parc Safari, Ouest")], "planche-4-parc-est-ouest.jpg")
	_pile([_paire("safari_zone_gate", "Porte du Parc"),
		_paire("safari_zone_rest_house_north", "Maison de repos"),
		_paire("safari_zone_secret_house", "Maison Secrète")], "planche-5-interieurs.jpg")
	facades = []
	for asset in ("bldg_arene_parmanie_01", "bldg_pavillon_safari_01", "bldg_cabane_safari_01"):
		image = Image.open(RACINE / f"assets/world/buildings/{asset}.png").convert("RGBA")
		fond = Image.new("RGBA", image.size, (86, 140, 66, 255))
		fond.alpha_composite(image)
		facades.append(fond.convert("RGB"))
	hauteur = max(f.height for f in facades)
	feuille = Image.new("RGB", (sum(f.width for f in facades) + 20 * len(facades), hauteur + 20),
		(24, 24, 28))
	x = 10
	for f in facades:
		feuille.paste(f, (x, 10))
		x += f.width + 20
	feuille.thumbnail((LARGEUR, 600))
	feuille.save(SORTIE / "planche-6-facades.jpg", quality=88)
	print("planche-6-facades.jpg", feuille.size)


if __name__ == "__main__":
	main()
