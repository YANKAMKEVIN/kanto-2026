#!/usr/bin/env python3
"""Lot DAF.9 « Cramois'Île » (phase DA, RP-024) : l'île (`cinnabar_island`), l'Arène d'Auguste
(`cinnabar_gym`) et le Manoir Pokémon sur 4 niveaux (`pokemon_mansion_1f` à `_b1f`), restés en tuiles
provisoires et en aplats à la clôture du J25. Fiche : `docs/design/fiches-assets/daf-9/fiche.md`.

Deux sources :
- le **kit de la série 28** (J25, validé par Kevin le 2026-10-19 : sols, murs, mobilier du Manoir,
  machines, herses et statue de l'Arène), généré mais jamais intégré ; il est lu dans
  `build/art/serie28/` (copie de la branche `j25-kit-art`, préparée par `serie28.py`) ;
- des **images neuves** de ce lot (Codex CLI, sans dépense d'API) : trois façades de l'île (Manoir en
  ruine, Arène, Labo de Cramois), sol volcanique, sable noir et roche volcanique des récifs.

Méthode : seconde passe d'image sur les cartes (`tools/build_daf9_cramois.gd`, modèle
`build_daf4_caves.gd` et `build_daf4_exterieurs.gd`) : la logique ne bouge pas (gel du J33,
`tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après).

Usage :
  tools/art/daf9.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf9.py [GROUPE ...]         génère avec Codex (sans argument : tout ce qui manque)
  tools/art/daf9.py --modules            kit de la série 28, sols et façades → assets/ (catalogue)
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

PROMPTS = ICI / "prompts" / "daf9"
KIT28 = ART / "serie28"
_W = "assets/world/"
_G, _R, _P, _B = f"{_W}ground/", f"{_W}relief/", f"{_W}props/", f"{_W}buildings/"
CENTRE = f"{_B}bldg_centre_01.png"
BOUTIQUE = f"{_B}bldg_boutique_01.png"
LABO = f"{_B}bldg_labo_01.png"
MUSEE = f"{_B}bldg_musee_argenta_01.png"
CHEMIN = f"{_G}ground_chemin_01.png"
SABLE = f"{_G}ground_sable_01.png"
ROCHE = f"{_G}ground_masse_roche_01.png"

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu étalonne lui-même la "
	"carte en « golden hour ») : AUCUNE teinte dorée ni orangée, AUCUN halo, aucune ombre portée au sol.")
VALEURS_CRAMOIS = ("VALEURS DE CRAMOIS'ÎLE (une petite île VOLCANIQUE au sud de Kanto, chaude et un peu "
	"austère, battue par le vent de la mer : un volcan fume au nord-est) : terre volcanique brun-gris, "
	"cendre, basalte noir-brun, touffes d'herbe sèche jaune paille, quelques buissons vert sombre ; bâtiments "
	"de pierre claire. " + LUMIERE)

SOLS = [
	("WORLD_GROUND_VOLCANIQUE_01", "ground_volcanique_01",
		"texture du SOL de la ville de Cramois'Île, vue strictement de dessus : terre VOLCANIQUE tassée brun-gris "
		"chaud (luminosité environ 45 à 52 %), fine cendre plus claire par plaques, petits graviers de basalte "
		"sombre épars, de RARES petites touffes d'herbe sèche jaune paille (moins de 5 % de la surface) ; plat, "
		"praticable, sans gros rocher.",
		[CHEMIN], VALEURS_CRAMOIS),
	("WORLD_GROUND_SABLE_NOIR_01", "ground_sable_noir_01",
		"texture de la PLAGE de SABLE NOIR volcanique de Cramois'Île, vue strictement de dessus : sable fin "
		"gris anthracite à reflets brun chaud (luminosité environ 22 à 30 %, jamais noir pur), légères rides "
		"laissées par le vent, quelques petits galets de basalte et grains clairs épars ; plat.",
		[SABLE], VALEURS_CRAMOIS),
	("WORLD_GROUND_ROCHE_VOLCANIQUE_01", "ground_roche_volcanique_01",
		"texture des RÉCIFS et de la côte rocheuse de Cramois'Île, vue de dessus : un chaos serré de BLOCS DE "
		"BASALTE brun-noir arrondis par la mer (luminosité environ 22 à 35 %), arêtes éclairées en brun chaud, "
		"creux sombres brun-violet (jamais noir pur), quelques touffes d'herbe sèche jaune dans les fentes.",
		[ROCHE], VALEURS_CRAMOIS),
]

## (identifiant, asset, largeur, profondeur (cases), porte (colonne depuis 1, nombre), description,
## ancres). Taille = largeur × 96, profondeur × 96 + 24 (rebord du toit).
FACADES = [
	("WORLD_BLDG_MANOIR_RUINE_01", "bldg_manoir_ruine_01", 9, 6, (4, 2),
		"le MANOIR POKÉMON de Cramois'Île, façade de face : une grande demeure de pierre grise à DEUX étages, "
		"ABANDONNÉE et INCENDIÉE, 9 cases de large et environ 6,25 de haut : le TOIT s'est en partie effondré "
		"(charpente noircie à nu, poutres brisées, tuiles sombres manquantes), murs de pierre grise tachés de "
		"suie, fenêtres aux vitres brisées et aux volets arrachés, quelques gravats et planches calcinées au pied "
		"des murs, des herbes sèches qui poussent contre la façade. Au bas, sur les 4e et 5e colonnes, l'ENTRÉE : "
		"une large porte double de bois sombre ENTROUVERTE, l'intérieur sombre, un seuil de pierre fissuré, le "
		"passage LIBRE (aucun gravat devant). Inquiétant mais pas horrible, sans aucune lueur.",
		[MUSEE, LABO]),
	("WORLD_BLDG_ARENE_CRAMOIS_01", "bldg_arene_cramois_01", 9, 6, (5, 2),
		"l'ARÈNE de Cramois'Île (Champion de type Feu), façade de face : un bâtiment public de pierre claire "
		"crème, 9 cases de large et environ 6,25 de haut, un grand TOIT ROUGE BRIQUE à quatre pans, une frise "
		"de pierre rouge sombre en bas du toit, des piliers de pierre de part et d'autre de l'entrée, des "
		"fenêtres régulières ; au milieu du toit au-dessus de la porte, un FRONTON de pierre orné d'une FLAMME "
		"stylisée sculptée en relief (sans cercle) ; au bas, sur les 5e et 6e colonnes, une PORTE DOUBLE de "
		"bois brun foncé fermée, deux marches de pierre. Solide, un peu solennel, de la même main que les "
		"bâtiments joints.",
		[CENTRE, BOUTIQUE, MUSEE]),
	("WORLD_BLDG_LABO_CRAMOIS_01", "bldg_labo_cramois_01", 9, 6, (4, 2),
		"le LABORATOIRE POKÉMON de Cramois'Île, façade de face : un bâtiment de recherche MODERNE, 9 cases de "
		"large et environ 6,25 de haut, un seul grand volume à TOIT PLAT gris clair (rebord épais, quelques "
		"blocs de climatisation, une cheminée d'aération et une petite antenne parabolique grise sur le toit), "
		"murs BLANCS et gris perle nets, un long bandeau de FENÊTRES bleu-vert sur toute la largeur ; au bas, sur "
		"les 4e et 5e colonnes, une PORTE DOUBLE de bois brun sous un petit auvent de béton, une marche. Propre, "
		"scientifique, de la même main que les bâtiments joints.",
		[LABO, CENTRE, BOUTIQUE]),
]

## Recalage des portes : Codex centre la porte ; milieu de la porte mesuré sur l'image ramenée à 864 px
## (planche `build/daf9/portes.jpg`) → la façade est étirée de part et d'autre (deux segments
## linéaires) pour que ce milieu tombe sur celui des cases de porte de la grille.
PORTES_SOURCE = {"bldg_manoir_ruine_01": 425, "bldg_arene_cramois_01": 432, "bldg_labo_cramois_01": 429}


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


## Kit de la série 28 (préparé par `serie28.py` dans `build/art/serie28/`) → assets/.
KIT_DOSSIERS = {"sols": _G, "relief": _R, "objets": _P, "decals": f"{_W}decals/"}


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
			f"peint, même angle de vue, même lumière neutre).\n\n{ADN}\n{VALEURS_CRAMOIS}\n\nASSET : {description}\n"
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


def preparer_modules() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	# Kit de la série 28 : déjà aux dimensions du jeu (sols 384 px, faces 192 px, objets au pied).
	for dossier, sortie in KIT_DOSSIERS.items():
		for source in sorted((KIT28 / dossier).glob("*.png")):
			(RACINE / sortie).mkdir(parents=True, exist_ok=True)
			shutil.copyfile(source, RACINE / sortie / source.name)
			print(f"{sortie}{source.name}")
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = catalogue
	sols = [{"id": asset, "source": daf3._source(ident), "sortie": f"{_G}{asset}.png", "taille": 384,
		"contraste": 0.85, "couleur": 1.0, "raccord": 24} for ident, asset, *_r in SOLS
		if (ART / daf3._source(ident)).exists()]
	p.m = dict(manifeste, sols=sols)
	p.sols()
	for ident, asset, largeur, profondeur, porte, *_r in FACADES:
		source = ART / daf3._source(ident)
		if source.exists():
			image = preparer._silhouette(Image.open(source).convert("RGBA")).resize(
				(largeur * CASE, profondeur * CASE + 24), Image.LANCZOS)
			image = _recaler_porte(image, asset, *porte)
			daf3._ecrire_avec_ombres(image, asset, p.catalogue, manifeste)
			print(f"{asset} : {image.size}")
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--modules"]:
		preparer_modules()
	else:
		generer(set(args))
