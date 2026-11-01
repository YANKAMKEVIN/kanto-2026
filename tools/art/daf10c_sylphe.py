#!/usr/bin/env python3
"""Reliquat Codex de DAF.10c / DAF.10d (2026-10-31) : mobilier propre à chaque étage de Sylphe SARL, peint
par Codex. Chaque étage garde ses bureaux (`M` en blocs) et ses armoires (`M` d'une case de large) aux mêmes
cases ; seule l'image change, d'après le service de l'étage [D] (le 5F, « étage type » validé, garde le kit
DAF.3). Mêmes gabarits que `int_bureau_sylphe_01` / `int_serveur_sylphe_01` : 1 case de large, origine au pied.
Fiche : `docs/design/fiches-assets/daf-10c/fiche.md`.

  tools/art/daf10c_sylphe.py --prompts      écrit les prompts (tools/art/prompts/daf10c_sylphe/)
  tools/art/daf10c_sylphe.py [GROUPE ...]   génère avec Codex (tout ce qui manque sans argument)
  tools/art/daf10c_sylphe.py --modules      découpe les planches → assets/ (catalogue)
  tools/art/daf10c_sylphe.py --cartes       branche les variantes dans les cartes des étages
"""
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import daf3  # noqa: E402
from daf3 import ADN, ART, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "daf10c_sylphe"
_I = "assets/world/interiors/"
_SCENES = "res://game/world/props/painted/"

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu ajoute lui-même la "
	"lumière des plafonniers) : AUCUNE lueur peinte, AUCUN halo, aucune ombre portée.")
VALEURS = ("VALEURS DE SYLPHE SARL (la grande entreprise de Safrania qui fabrique les Poké Balls : bureaux "
	"modernes, propres et clairs, blanc cassé, gris perle et bleu Sylphe, chaque étage a son service) ; " + LUMIERE)
_ECHELLE = daf3._CELLULES + ", à une échelle COMMUNE de 1 case = 150 px"
_FOND = "Fond avec une vraie transparence (canal alpha), aucun sol autour, aucune ombre portée, aucun texte."
_BUREAU = ("EXACTEMENT 1 case de large (≈ 150 px), environ 0,9 case de haut, vu de face en trois quarts (léger "
	"plongé), plateau rectangulaire bord à bord : les bureaux se juxtaposent en blocs serrés de 2 à 8, ils doivent "
	"se raccorder côte à côte et l'un derrière l'autre, avec sa chaise de bureau visible devant")
_ARMOIRE = ("EXACTEMENT 1 case de large (≈ 150 px), environ 1,85 case de haut, vue de face en trois quarts (léger "
	"plongé), base droite posée sur la ligne de base : elles se rangent en colonnes")

## Planches : (identifiant, texte, ancres).
PLANCHES = [
	("INT_SYLPHE_BUREAUX_PLANCHE",
		f"PLANCHE de 6 BUREAUX de Sylphe SARL, un par service, {_ECHELLE}. Ordre : ligne 1 = 1, 2, 3 ; ligne 2 = "
		"4, 5, 6. MÊME gabarit et même main que le bureau joint (int_bureau_sylphe_01), chacun " + _BUREAU + ".\n"
		"1 : ACCUEIL (rez-de-chaussée) : un élément de comptoir d'accueil blanc laqué à bandeau bleu, plateau "
		"clair, un petit écran plat et un pot à stylos, tabouret haut bleu.\n"
		"2 : ADMINISTRATION : bureau gris clair couvert de dossiers et de piles de papiers bien rangés, un "
		"téléphone de bureau, une lampe articulée éteinte, chaise grise.\n"
		"3 : RECHERCHE POKÉ BALL : paillasse blanche avec une Poké Ball ouverte en deux sur un support, des "
		"petits outils de précision et une loupe, tabouret de laboratoire.\n"
		"4 : INFORMATIQUE : bureau noir et bleu avec deux écrans plats éteints côte à côte et un clavier, "
		"fauteuil de bureau noir.\n"
		"5 : INGÉNIERIE : table à dessin inclinée avec un plan technique bleu (traits seulement, aucun texte), "
		"règle et compas, tabouret.\n"
		"6 : DIRECTION : bureau de direction en bois sombre verni, sous-main de cuir, lampe de bureau dorée "
		"éteinte, fauteuil de cuir bordeaux.\n" + _FOND,
		[f"{_I}int_bureau_sylphe_01.png", f"{_I}int_serveur_sylphe_01.png", f"{_I}int_plante_sylphe_01.png"]),
	("INT_SYLPHE_ARMOIRES_PLANCHE",
		f"PLANCHE de 6 ARMOIRES de Sylphe SARL, une par service, {_ECHELLE}. Ordre : ligne 1 = 1, 2, 3 ; ligne 2 = "
		"4, 5, 6. MÊME gabarit et même main que l'armoire jointe (int_serveur_sylphe_01), chacune " + _ARMOIRE + ".\n"
		"1 : ACCUEIL : une vitrine haute de verre et de métal blanc présentant des Poké Balls, Super Balls et "
		"Hyper Balls sur des étagères éclairées (sans lueur peinte).\n"
		"2 : ADMINISTRATION : une armoire à archives grise à rideau, classeurs colorés rangés sur les "
		"étagères, étiquettes vierges.\n"
		"3 : RECHERCHE POKÉ BALL : une armoire de stockage blanche à portes vitrées, rangées de coques de Poké "
		"Balls rouges et blanches non assemblées.\n"
		"4 : INFORMATIQUE : une baie réseau noire à porte grillagée, câbles bleus bien rangés, petits voyants "
		"éteints.\n"
		"5 : INGÉNIERIE : une armoire d'outillage bleu Sylphe, tiroirs métalliques, panneau à outils accroché "
		"en haut.\n"
		"6 : DIRECTION : un grand coffre-fort gris acier à roue de combinaison, posé sur un socle.\n" + _FOND,
		[f"{_I}int_serveur_sylphe_01.png", f"{_I}int_bureau_sylphe_01.png", f"{_I}int_plante_sylphe_01.png"]),
]
SERVICES = ["accueil", "administration", "recherche", "informatique", "ingenierie", "direction"]
## Assets découpés : identifiants (ordre de lecture), largeur en cases, dossier.
PLANCHE_IDS = {
	"INT_SYLPHE_BUREAUX_PLANCHE": ([f"int_bureau_sylphe_{s}_01" for s in SERVICES], [1] * 6, _I),
	"INT_SYLPHE_ARMOIRES_PLANCHE": ([f"int_armoire_sylphe_{s}_01" for s in SERVICES], [1] * 6, _I),
}
## Service de chaque étage [D] (le 5F garde le kit DAF.3 ; 10F et 11F = direction, le 11F n'a pas d'armoire).
ETAGES = {
	"silph_co_1f": "accueil", "silph_co_2f": "administration", "silph_co_3f": "administration",
	"silph_co_4f": "recherche", "silph_co_6f": "recherche", "silph_co_7f": "informatique",
	"silph_co_8f": "informatique", "silph_co_9f": "ingenierie", "silph_co_10f": "direction",
	"silph_co_11f": "direction",
}


def _images() -> list[dict]:
	return [{"nom": f"{ident}_NE_r1", "groupe": ident, "jointes": ancres,
		"texte": f"{ident} — NOUVELLE image de production (Kanto 2026).\nImages jointes : "
			f"{', '.join(Path(a).stem for a in ancres)} = assets déjà peints du jeu : ancres de style.\n\n{ADN}\n"
			f"{VALEURS}\n\n{texte}\n{daf3.OBJET_FIN}\n{daf3.INTERDITS}\n"} for ident, texte, ancres in PLANCHES]


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
	print(f"{len(_images())} prompts dans {PROMPTS}")


def generer(choix: set[str]) -> None:
	images = [i for i in _images() if not choix or i["groupe"] in choix]
	with ThreadPoolExecutor(max_workers=2) as pool:
		for ligne in pool.map(daf3._generer, images):
			print(ligne, flush=True)


def preparer_modules() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	anciens = (daf3.DECALS, daf3.EXACTS)
	daf3.DECALS, daf3.EXACTS = (), {}
	for ident, (ids, cases, dossier) in PLANCHE_IDS.items():
		if not (ART / daf3._source(ident)).exists():
			print(f"{ident} : absente")
			continue
		for asset, element in daf3._decouper(daf3._source(ident), ids, cases):
			p._objet(asset, f"{dossier}{asset}.png", element, False, 0.12)
			print(f"{asset} : {element.size}")
	daf3.DECALS, daf3.EXACTS = anciens
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


def brancher_cartes() -> None:
	"""Remplace, dans chaque étage, la scène des bureaux et des armoires par la variante du service
	(mêmes nœuds `Furniture*`, mêmes positions, même emprise d'une case)."""
	for carte, service in ETAGES.items():
		chemin = RACINE / "game" / "world" / "maps" / f"{carte}.tscn"
		texte = chemin.read_text()
		for ancien, nouveau in (("int_bureau_sylphe_01", f"int_bureau_sylphe_{service}_01"),
				("int_serveur_sylphe_01", f"int_armoire_sylphe_{service}_01")):
			texte = re.sub(rf'path="{_SCENES}{ancien}\.tscn"', f'path="{_SCENES}{nouveau}.tscn"', texte)
		chemin.write_text(texte)
		print(f"{carte} : {service}")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--modules"]:
		preparer_modules()
	elif args[:1] == ["--cartes"]:
		brancher_cartes()
	else:
		generer(set(args))
