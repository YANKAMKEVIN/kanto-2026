#!/usr/bin/env python3
"""Lot DAF.10a « Parmanie et Parc Safari » (phase DA, RP-269, RP-270, RP-271, RP-272 en partie) :
façades neuves de la ville (Arène, pavillon d'accueil du Parc) ; le reste vient du kit existant.
Fiche : `docs/design/fiches-assets/daf-10a/fiche.md`. Même méthode que DAF.9 (`daf9.py`) : Codex CLI
(sans dépense d'API), prompts versionnés dans `tools/art/prompts/daf10a/`, recalage des portes.

Usage :
  tools/art/daf10a.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf10a.py [GROUPE ...]         génère avec Codex (sans argument : tout ce qui manque)
  tools/art/daf10a.py --modules            façades retenues → assets/ (catalogue)
"""
from __future__ import annotations

import json
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import daf3  # noqa: E402
from daf3 import ADN, ART, CASE, INTERDITS, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "daf10a"
_W = "assets/world/"
_G, _R, _P, _B = f"{_W}ground/", f"{_W}relief/", f"{_W}props/", f"{_W}buildings/"
ARENE_CEL = f"{_B}bldg_arene_celadopole_01.png"
MAISON = f"{_B}bldg_maison_pecheur_01.png"
CENTRE = f"{_B}bldg_centre_01.png"
BOUTIQUE = f"{_B}bldg_boutique_01.png"
LABO = f"{_B}bldg_labo_01.png"
MUSEE = f"{_B}bldg_musee_argenta_01.png"
CHEMIN = f"{_G}ground_chemin_01.png"
SABLE = f"{_G}ground_sable_01.png"
ROCHE = f"{_G}ground_masse_roche_01.png"

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu étalonne lui-même la "
	"carte en « golden hour ») : AUCUNE teinte dorée ni orangée, AUCUN halo, aucune ombre portée au sol.")
VALEURS_PARMANIE = ("VALEURS DE PARMANIE (une ville verte, basse et ouverte au bord de la mer, de petites maisons "
	"crépies crème à toits de tuiles, une ambiance de jardin zen discret) : crépi crème, bois brun chaud, tuiles "
	"colorées franches, buissons fleuris. " + LUMIERE)

SOLS = []

## (identifiant, asset, largeur, profondeur (cases), porte (colonne depuis 1, nombre), description, ancres).
FACADES = [
	("WORLD_BLDG_ARENE_PARMANIE_01", "bldg_arene_parmanie_01", 12, 7, (7, 2),
		"l'ARÈNE de Parmanie (Champion Poison, esprit « ninja » discret), façade de face : un long bâtiment bas de "
		"crépi crème, 12 cases de large et environ 7,25 de haut, un grand TOIT de tuiles VIOLET franc à quatre pans "
		"avec un fin rebord clair, une corniche de bois sombre ; au bas, sur les 7e et 8e colonnes, une PORTE DOUBLE "
		"vitrée à cadre de bois sombre sous un petit auvent, deux marches de pierre ; de part et d'autre de la porte, "
		"un petit JARDIN ZEN encadré d'une bordure de pierre : un pin bonsaï taillé en nuage, des roches grises et "
		"du gravier ratissé ; quelques fenêtres étroites. Sobre, soigné, de la même main que les bâtiments joints.",
		[ARENE_CEL, CENTRE, BOUTIQUE]),
	("WORLD_BLDG_PAVILLON_SAFARI_01", "bldg_pavillon_safari_01", 10, 6, (5, 2),
		"le PAVILLON D'ACCUEIL du Parc Safari, façade de face : un grand bâtiment d'entrée bas, 10 cases de large et "
		"environ 6,25 de haut, charpente de bois brun sur murs de crépi crème, un large TOIT de tuiles VERT OLIVE "
		"à deux pans très étalé avec des avant-toits profonds ; au bas, sur les 5e et 6e colonnes, une PORTE DOUBLE "
		"de bois brun, trois marches de pierre et une courte allée de dalles ; des jardinières fleuries sous les "
		"fenêtres, deux grandes lanternes de bois de part et d'autre de l'entrée. Chaleureux, d'esprit « réserve "
		"naturelle », de la même main que les bâtiments joints.",
		[MAISON, CENTRE, BOUTIQUE]),
	# Rétablie le 2026-10-31 (le dérivé `preparer_cabane_secours` attendait la fin de la limite d'usage).
	("WORLD_BLDG_CABANE_SAFARI_01", "bldg_cabane_safari_01", 4, 3, (2, 1),
		"une petite CABANE DE REPOS du Parc Safari, façade de face : une maisonnette basse de rondins et de "
		"planches de bois brun chaud, 4 cases de large et environ 3,25 de haut, un TOIT de chaume doré à deux pans "
		"avec un petit avant-toit ; au bas, sur la 2e colonne depuis la gauche, une PORTE de bois simple, une "
		"marche de pierre ; à droite de la porte, une petite fenêtre à volets verts et une jardinière ; un banc de "
		"bois contre le mur. Rustique et accueillante, de la même main que les bâtiments joints.",
		[MAISON, CENTRE, BOUTIQUE]),
]

## Recalage des portes : Codex centre la porte ; milieu de la porte mesuré sur l'image ramenée à 864 px
## (planche `build/daf9/portes.jpg`) → la façade est étirée de part et d'autre (deux segments
## linéaires) pour que ce milieu tombe sur celui des cases de porte de la grille.
PORTES_SOURCE: dict[str, int] = {"bldg_arene_parmanie_01": 730}


def _recaler_porte(image: Image.Image, asset: str, colonne: int, nombre: int) -> Image.Image:
	source = PORTES_SOURCE.get(asset)
	if source is None:
		return image
	cible = round((colonne - 1 + nombre / 2) * CASE)
	w, h = image.size
	gauche = image.crop((0, 0, source, h)).resize((cible, h), Image.LANCZOS)
	droite = image.crop((source, 0, w, h)).resize((w - cible, h), Image.LANCZOS)
	sortie = Image.new("RGBA", (w, h))
	sortie.paste(gauche, (0, 0))
	sortie.paste(droite, (cible, 0))
	return sortie




def _images() -> list[dict]:
	images = []
	for ident, _asset, description, ancres, valeurs in SOLS:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, [], True), "jointes": ancres})
	for ident, asset, largeur, profondeur, porte, description, ancres in FACADES:
		taille = (largeur * CASE, profondeur * CASE + 24)
		gen = daf3._format(*taille)
		ew, eh = daf3._boite(gen, taille)
		texte = (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\nImages jointes : "
			f"{', '.join(Path(a).stem for a in ancres)} = bâtiments déjà peints du jeu : ancres de style (rendu "
			f"peint, même angle de vue, même lumière neutre).\n\n{ADN}\n{VALEURS_PARMANIE}\n\nASSET : {description}\n"
			f"{daf3._porte(largeur, *porte)}\nFormat : PNG {gen[0]} × {gen[1]}, l'élément occupe environ {ew} × {eh} px "
			f"(rapport {taille[0] / taille[1]:.2f} : 1, à RESPECTER : l'image est ramenée telle quelle à {taille[0]} × "
			f"{taille[1]} px, 1 case = 96 px), centré, tout le bâtiment visible.\n{daf3.OBJET_FIN}\n{INTERDITS}\n")
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "texte": texte, "jointes": ancres})
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
	print(f"{len(_images())} prompts dans {PROMPTS}")


def generer(choix: set[str]) -> None:
	images = [i for i in _images() if not choix or i["groupe"] in choix or i["nom"] in choix]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(daf3._generer, images):
			print(ligne, flush=True)


def preparer_modules(choix: set[str] = set()) -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = catalogue
	sols = [{"id": asset, "source": daf3._source(ident), "sortie": f"{_G}{asset}.png", "taille": 384,
		"contraste": 0.85, "couleur": 1.0, "raccord": 24} for ident, asset, *_r in SOLS
		if (ART / daf3._source(ident)).exists()]
	p.m = dict(manifeste, sols=sols)
	p.sols()
	for ident, asset, largeur, profondeur, porte, *_r in FACADES:
		source = ART / daf3._source(ident)
		if source.exists() and (not choix or ident in choix):
			image = preparer._silhouette(Image.open(source).convert("RGBA")).resize(
				(largeur * CASE, profondeur * CASE + 24), Image.LANCZOS)
			image = _recaler_porte(image, asset, *porte)
			daf3._ecrire_avec_ombres(image, asset, p.catalogue, manifeste)
			print(f"{asset} : {image.size}")
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


def preparer_cabane_secours() -> None:
	"""Cabane de repos du Parc (4 × 3 cases, porte à la 2e colonne) tirée de `bldg_maison_toit_01`
	(toit d'ardoise, 5 cases) réduite ×0,8 et recalée sur la porte : l'image dédiée demandée à Codex
	(`WORLD_BLDG_CABANE_SAFARI_01`) attend la fin de la limite d'usage. Remplaçable à l'identique."""
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	source = Image.open(RACINE / _B / "bldg_maison_toit_01.png").convert("RGBA")
	image = source.resize((4 * CASE, round(source.height * 4 * CASE / source.width)), Image.LANCZOS)
	cible = round(1.5 * CASE)
	w, h = image.size
	gauche = image.crop((0, 0, w // 2, h)).resize((cible, h), Image.LANCZOS)
	droite = image.crop((w // 2, 0, w, h)).resize((w - cible, h), Image.LANCZOS)
	sortie = Image.new("RGBA", (w, h))
	sortie.paste(gauche, (0, 0))
	sortie.paste(droite, (cible, 0))
	import preparer
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = catalogue
	daf3._ecrire_avec_ombres(sortie, "bldg_cabane_safari_01", p.catalogue, manifeste)
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")
	print(f"bldg_cabane_safari_01 : {sortie.size}")


def preparer_arene() -> None:
	"""Lame d'indice de l'Arène de Parmanie (murs invisibles, N-15) : le parquet clair du Dojo assombri
	de 10 % et réchauffé, pour que l'indice au sol reste discret."""
	source = Image.open(RACINE / _G / "ground_parquet_dojo_01.png").convert("RGBA")
	r, g, b, a = source.split()
	r = r.point(lambda v: int(v * 0.90))
	g = g.point(lambda v: int(v * 0.86))
	b = b.point(lambda v: int(v * 0.80))
	Image.merge("RGBA", (r, g, b, a)).save(RACINE / _G / "ground_parquet_dojo_indice_01.png")
	print("ground_parquet_dojo_indice_01")


def preparer_coque() -> None:
	"""Enveloppe 12 × 10 de la Porte et de la Maison Secrète du Parc : la coque des maisons d'Argenta
	(15 × 10) recoupée (bandes 0..1,5 + 3..12 + 13,5..15 cases) ; la porte reste centrée."""
	source = Image.open(RACINE / _W / "interiors" / "int_maison_argenta_coque.png").convert("RGBA")
	sortie = Image.new("RGBA", (12 * CASE, source.height))
	x = 0
	for a, b in ((0, 1.5), (3.0, 12.0), (13.5, 15.0)):
		bande = source.crop((round(a * CASE), 0, round(b * CASE), source.height))
		sortie.paste(bande, (x, 0))
		x += bande.width
	sortie.save(RACINE / _W / "interiors" / "int_safari_12x10_coque.png")
	print("int_safari_12x10_coque", sortie.size)


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--coque"]:
		preparer_coque()
	elif args[:1] == ["--arene"]:
		preparer_arene()
	elif args[:1] == ["--cabane"]:
		preparer_cabane_secours()
	elif args[:1] == ["--modules"]:
		preparer_modules(set(args[1:]))
	else:
		generer(set(args))
