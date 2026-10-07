#!/usr/bin/env python3
"""Prépare l'art du Menu Dresseur (série 10, MM.0 → MM.1, docs/tech/menu-maquettes.md).

Lit les images validées de `build/art/` (non versionné, Mac de Kevin) et écrit dans `assets/` des
fichiers aux **noms stables**, à la taille utile du menu (référence 1080 p de haut) :
  - `assets/ui/menu/cards/<écran>.webp` : les 6 illustrations du tableau de bord (opaques),
    640 × 427 (une carte fait au plus ~520 × 400 à 2340 de large ; réduction sans mipmaps) ;
  - `assets/ui/menu/hero_bust.webp` : le portrait peint du héros, recadré sur sa silhouette,
    720 px de haut (affiché ~640 dans la carte du Dresseur), fond transparent ;
  - `assets/ui/items/<objet>.webp` : icônes peintes des objets (planche 4 × 1 découpée en
    colonnes de 384 px), recadrées, centrées dans un carré de 256 px (marge 8 px).
Usage : tools/art/preparer_menu.py [--source DOSSIER]
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parents[2]

CARTES = {
	"team": "MENU_CARTE_EQUIPE_r1.png",
	"pokedex": "MENU_CARTE_POKEDEX_r1.png",
	"bag": "MENU_CARTE_SAC_r1.png",
	"map": "MENU_CARTE_CARTE_r1.png",
	"trainer": "MENU_CARTE_DRESSEUR_r1.png",
	"settings": "MENU_CARTE_PARAMETRES_r1.png",
}
CARTE_TAILLE = (640, 427)
HEROS = "MENU_HEROS_BUSTE_r1.png"
HEROS_HAUTEUR = 720
OBJETS = "MENU_OBJETS_PLANCHE_r1.png"
# Ordre de la planche (prompt de serie10_menu.py) → identifiants de data/items/items.json.
OBJETS_IDS = ["poke_ball", "potion", "antidote", "oak_parcel"]
OBJETS_COLONNE = 384
OBJET_TAILLE = 256
OBJET_MARGE = 8
QUALITE = 90


def _silhouette(image: Image.Image) -> Image.Image:
	masque = image.getchannel("A").point(lambda a: 255 if a > 24 else 0)
	return image.crop(masque.getbbox())


def _carte(source: Path, sortie: Path) -> None:
	image = Image.open(source).convert("RGB")
	largeur, hauteur = image.size
	cible = CARTE_TAILLE[0] / CARTE_TAILLE[1]
	if largeur / hauteur > cible:
		nouvelle = round(hauteur * cible)
		image = image.crop(((largeur - nouvelle) // 2, 0, (largeur + nouvelle) // 2, hauteur))
	else:
		nouvelle = round(largeur / cible)
		image = image.crop((0, 0, largeur, nouvelle))
	image.resize(CARTE_TAILLE, Image.LANCZOS).save(sortie, "WEBP", quality=QUALITE, method=6)


def _heros(source: Path, sortie: Path) -> None:
	image = _silhouette(Image.open(source).convert("RGBA"))
	largeur = round(image.width * HEROS_HAUTEUR / image.height)
	image.resize((largeur, HEROS_HAUTEUR), Image.LANCZOS).save(sortie, "WEBP", quality=QUALITE,
		method=6)


def _bandes(planche: Image.Image, nombre: int) -> list[tuple[int, int]]:
	"""Les [nombre] plages de colonnes occupées (alpha), séparées par du vide ; à défaut, des
	colonnes égales de OBJETS_COLONNE (un objet peut déborder de sa colonne théorique)."""
	alpha = planche.getchannel("A").point(lambda a: 255 if a > 24 else 0)
	largeur, hauteur = alpha.size
	pleines = [alpha.crop((x, 0, x + 1, hauteur)).getbbox() is not None for x in range(largeur)]
	bandes: list[tuple[int, int]] = []
	debut = -1
	for x, plein in enumerate(pleines + [False]):
		if plein and debut < 0:
			debut = x
		elif not plein and debut >= 0:
			if x - debut > 16:
				bandes.append((debut, x))
			debut = -1
	if len(bandes) != nombre:
		return [(r * OBJETS_COLONNE, (r + 1) * OBJETS_COLONNE) for r in range(nombre)]
	return bandes


def _objets(source: Path, dossier: Path) -> None:
	planche = Image.open(source).convert("RGBA")
	for (gauche, droite), identifiant in zip(_bandes(planche, len(OBJETS_IDS)), OBJETS_IDS):
		objet = _silhouette(planche.crop((gauche, 0, droite, planche.height)))
		utile = OBJET_TAILLE - 2 * OBJET_MARGE
		echelle = utile / max(objet.size)
		objet = objet.resize((round(objet.width * echelle), round(objet.height * echelle)),
			Image.LANCZOS)
		carre = Image.new("RGBA", (OBJET_TAILLE, OBJET_TAILLE), (0, 0, 0, 0))
		carre.alpha_composite(objet, ((OBJET_TAILLE - objet.width) // 2,
			(OBJET_TAILLE - objet.height) // 2))
		carre.save(dossier / f"{identifiant}.webp", "WEBP", quality=QUALITE, method=6)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--source", type=Path, default=RACINE / "build" / "art")
	args = parser.parse_args()
	cartes = RACINE / "assets" / "ui" / "menu" / "cards"
	objets = RACINE / "assets" / "ui" / "items"
	cartes.mkdir(parents=True, exist_ok=True)
	objets.mkdir(parents=True, exist_ok=True)
	for ecran, fichier in CARTES.items():
		_carte(args.source / fichier, cartes / f"{ecran}.webp")
	_heros(args.source / HEROS, RACINE / "assets" / "ui" / "menu" / "hero_bust.webp")
	_objets(args.source / OBJETS, objets)
	print("art du menu prêt :", cartes, objets)


if __name__ == "__main__":
	main()
