#!/usr/bin/env python3
"""Lot DAF.10b « Routes 13 à 21 » (J33, gel fonctionnel ; RP-272 partie postes, RP-273, RP-274).
Fiche : `docs/design/fiches-assets/daf-10b/fiche.md`.

Images neuves (Codex CLI, sans dépense d'API) ; tout le reste vient du kit existant (forêt serrée,
herbe, chemin, sable, mer de Bourg Palette, rivage rocheux, clôtures, rebords, façades) :
- façade du **poste traversant** est-ouest (Routes 15 et 18 : 8 × 9 cases, ouvertures latérales) ;
- enveloppes des postes : 1F traversant (Routes 15 et 18, 12 × 10, ouvertures ouest et est), 2F
  du poste de la Route 15 (12 × 10, fenêtres sur la campagne), poste de la Route 16 (14 × 10, deux
  couloirs nord-sud) ; références de composition validées `reference/poste-15|16|18-v1.png` ;
- jumelles du 2F (objet) ; béton de la Piste Cyclable (sol, 384 px).

Méthode : seconde passe d'image (`tools/build_daf10b_routes.gd`, `tools/build_daf10b_postes.gd`) :
`tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.

Usage :
  tools/art/daf10b.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf10b.py [GROUPE ...]         génère avec Codex (sans argument : tout ce qui manque)
  tools/art/daf10b.py --modules            images retenues → assets/ (catalogue)
"""
from __future__ import annotations

import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import daf3  # noqa: E402
from daf3 import ADN, ART, CASE, INTERDITS, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "daf10b"
_W = "assets/world/"
_G, _P, _B, _I = f"{_W}ground/", f"{_W}props/", f"{_W}buildings/", f"{_W}interiors/"
_REF = "docs/design/reference/"
POSTE_OUEST = f"{_B}bldg_poste_safrania_ouest_01.png"
POSTE_EST = f"{_B}bldg_poste_safrania_est_01.png"
POSTE_FORET = f"{_B}bldg_poste_foret_nord_01.png"
COQUE_FORET = f"{_I}int_poste_foret_coque.png"
COQUE_ARGENTA = f"{_I}int_maison_argenta_coque.png"
PAVES = f"{_G}ground_paves_01.png"
DIGUE = f"{_G}ground_digue_01.png"

LUMIERE = ("LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à "
	"gauche ; aucune teinte dorée ou orangée, aucun halo ; ombres propres neutres, légèrement bleutées (le jeu "
	"étalonne lui-même la carte en « golden hour »).")
VALEURS = ("VALEURS DES ROUTES DU SUD DE KANTO (Routes 13 à 18, entre Lavanville et Parmanie : prés, forêt serrée, "
	"Piste Cyclable en bord de mer) : pierre crème, bois miel, toits d'ardoise bleue comme les postes de Safrania "
	"joints. " + LUMIERE)

ENVELOPPE = ("EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en trois "
	"quarts, image OPAQUE qui remplit tout le cadre (le vide autour des murs est un brun-noir bleuté uni).")
ENVELOPPE_INTERDITS = ("Interdit : meubles, comptoir, bibliothèque, plantes, jumelles, bancs, escalier (ils sont ajoutés "
	"séparément), personnages, Pokémon, porte fermée, flaques de lumière peintes au sol, texte, lettres, chiffres, "
	"logo, emblème rond de type balle, perspective avec point de fuite, vue isométrique, ombre portée.")

## (identifiant, asset, cases (l, h), description, ancres).
COQUES = [
	("INT_POSTE_TRAVERSANT_COQUE", "int_poste_traversant_coque", (12, 10),
		"Géométrie (respecte-la exactement, c'est un plan de jeu) : Format : PNG paysage 1536 × 1024, opaque ; la "
		"pièce fait 12 cases de large × 10 de profondeur (la préparation l'étire à 1 152 × 960 : 1 case = 128 px de "
		"large et ≈ 102 px de haut dans l'image demandée). Vue de dessus en projection oblique frontale. Le MUR DU "
		"FOND occupe toute la largeur en haut : on voit sa face avant sur les 3 cases du haut (y 0 à ≈ 307) : "
		"lambris de bois miel en bas, enduit crème au-dessus, poutre de bois en haut, deux petites fenêtres à "
		"petits bois. Le SOL (parquet de lattes claires, LIBRE et VIDE) va de x ≈ 128 à x ≈ 1408 et de y ≈ 307 à "
		"y ≈ 820. Les murs latéraux gauche (x 0 à 128) et droit (x 1408 à 1536) ne sont visibles que par leur "
		"épaisseur vue de dessus (bois et enduit crème, ≈ 60 px, le reste en vide sombre) ; CHAQUE mur latéral est "
		"interrompu par une OUVERTURE de 2 cases, de y ≈ 512 à y ≈ 717 : un passage ouvert vers l'extérieur (on "
		"devine la lumière du jour et un peu d'herbe), un paillasson brun uni posé au sol juste à l'intérieur. Le "
		"MUR DU BAS (y ≈ 820 à 1024) n'est visible que par son épaisseur de bois puis sa face extérieure de pierre "
		"crème, sans ouverture.\nPièce : le rez-de-chaussée d'un POSTE DE GARDE que l'on traverse d'ouest en est, "
		"mêmes matériaux et même main que l'enveloppe jointe int_poste_foret_coque. La référence jointe "
		"poste-15-v1 (pièce de GAUCHE) donne la composition et l'ambiance : n'en reprends NI les meubles NI les "
		"plantes.",
		[COQUE_FORET, f"{_REF}poste-15-v1.png", f"{_REF}poste-18-v1.png"]),
	("INT_POSTE_ETAGE_COQUE", "int_poste_etage_coque", (12, 10),
		"Géométrie (respecte-la exactement, c'est un plan de jeu) : Format : PNG paysage 1536 × 1024, opaque ; la "
		"pièce fait 12 cases de large × 10 de profondeur (la préparation l'étire à 1 152 × 960 : 1 case = 128 px de "
		"large et ≈ 102 px de haut dans l'image demandée). Vue de dessus en projection oblique frontale. Le MUR DU "
		"FOND occupe toute la largeur en haut : on voit sa face avant sur les 3 cases du haut (y 0 à ≈ 307) : "
		"lambris de bois miel en bas, enduit crème au-dessus, poutre de bois en haut, et DEUX GRANDES FENÊTRES à "
		"cadre de bois qui donnent sur une campagne verte ensoleillée (prés, arbres, collines bleutées, ciel bleu) : "
		"l'une centrée sur x ≈ 320 (≈ 2 cases de large), l'autre centrée sur x ≈ 960 (≈ 2 cases de large). Le SOL "
		"(parquet de lattes claires, LIBRE et VIDE) va de x ≈ 128 à x ≈ 1408 et de y ≈ 307 à y ≈ 820. Les murs "
		"latéraux gauche (x 0 à 128) et droit (x 1408 à 1536) ne sont visibles que par leur épaisseur vue de dessus "
		"(bois et enduit crème, ≈ 60 px, le reste en vide sombre), SANS ouverture. Le MUR DU BAS (y ≈ 820 à 1024) "
		"n'est visible que par son épaisseur de bois puis sa face extérieure de pierre crème, sans ouverture.\n"
		"Pièce : l'ÉTAGE d'un poste de garde, un belvédère tranquille, mêmes matériaux et même main que l'enveloppe "
		"jointe int_poste_foret_coque. La référence jointe poste-15-v1 (pièce de DROITE) donne la composition et "
		"l'ambiance : n'en reprends NI les jumelles, NI le banc, NI les plantes, NI l'escalier.",
		[COQUE_FORET, f"{_REF}poste-15-v1.png"]),
	("INT_POSTE_16_COQUE", "int_poste_16_coque", (14, 10),
		"Géométrie (respecte-la exactement, c'est un plan de jeu) : Format : PNG paysage 1536 × 1024, opaque ; la "
		"pièce fait 14 cases de large × 10 de profondeur (la préparation l'étire à 1 344 × 960 : 1 case ≈ 110 px "
		"de large et ≈ 102 px de haut dans l'image demandée). DEUX COULOIRS est-ouest superposés, séparés par un "
		"MUR épais. Couloir du HAUT : son mur du fond (face avant visible) occupe y 0 à ≈ 205, percé de DEUX "
		"PASSAGES OUVERTS de 2 cases (x ≈ 220 à 440 et x ≈ 1100 à 1320) qui mènent vers le nord (lumière du jour), "
		"un paillasson brun devant chacun ; son sol de grandes dalles claires va de y ≈ 205 à y ≈ 410, de x ≈ 110 "
		"à x ≈ 1426. Mur de SÉPARATION : y ≈ 410 à 512 (épaisseur vue de dessus puis face avant du mur du fond du "
		"couloir du bas : lambris de bois sombre et enduit crème). Couloir du BAS : sol de dalles claires de y ≈ "
		"512 à y ≈ 820, de x ≈ 110 à x ≈ 1426 ; son mur du BAS (y ≈ 820 à 1024) n'est visible que par son "
		"épaisseur, percé de DEUX PASSAGES OUVERTS de 2 cases (x ≈ 220 à 440 et x ≈ 1100 à 1320) vers le sud, un "
		"paillasson brun devant chacun. Murs latéraux : seulement leur épaisseur vue de dessus (≈ 60 px), sans "
		"ouverture ; vide sombre autour.\nPièce : le poste de la Route 16 (deux passages séparés, celui du haut "
		"pour la voie haute, celui du bas pour la Piste Cyclable), mêmes matériaux que l'enveloppe jointe "
		"int_poste_foret_coque. La référence jointe poste-16-v1 donne la composition (deux couloirs, dalles "
		"claires, lambris) : n'en reprends NI les comptoirs NI les plantes, et les passages sont OUVERTS (pas de "
		"portes fermées).",
		[COQUE_FORET, f"{_REF}poste-16-v1.png"]),
]

FACADES = [
	("WORLD_BLDG_POSTE_TRAVERSANT_01", "bldg_poste_traversant_01", 8, 9,
		"le POSTE DE GARDE d'une route, que l'on TRAVERSE D'OUEST EN EST, vu de face en trois quarts : un bâtiment "
		"de pierre crème de 8 cases de large et environ 9,25 cases de haut sur l'image, presque tout en TOITURE : un "
		"grand toit d'ARDOISE BLEUE à quatre pans vu de dessus (faîtage est-ouest, arêtes de pierre claire, une "
		"petite lucarne au milieu), puis au bas la FACE SUD de pierre crème (≈ 2 cases de haut) avec deux petites "
		"fenêtres à petits bois et deux lanternes, SANS porte sur cette face. Sur les côtés GAUCHE et DROIT, à "
		"mi-profondeur (entre 45 % et 70 % de la hauteur de l'image), un PASSAGE COUVERT ouvert de 2 cases de haut : "
		"un renfoncement sombre sous un petit auvent d'ardoise, encadré de deux piliers de pierre, par où la route "
		"entre et sort (comme les ouvertures latérales des postes de Safrania joints). Solide, accueillant, de la "
		"même main que les postes joints.",
		[POSTE_OUEST, POSTE_EST, POSTE_FORET]),
]

OBJETS = [
	("WORLD_INT_JUMELLES_01", "int_jumelles_01", (96, 168),
		"une LONGUE-VUE / JUMELLES PANORAMIQUES sur pied, comme sur un belvédère : un pied de métal gris acier sur "
		"une petite base ronde, une tête à deux oculaires tournée vers le haut de l'image (vers la fenêtre), "
		"métal gris bleuté et laiton ; 1 case de large, ≈ 1,75 case de haut.",
		[f"{_I}int_plante.png" if (RACINE / f"{_I}int_plante.png").exists() else COQUE_FORET, f"{_REF}poste-15-v1.png"]),
]

SOLS = [
	("WORLD_GROUND_PISTE_01", "ground_piste_01",
		"texture du revêtement de la PISTE CYCLABLE, vue strictement de dessus : grandes dalles de BÉTON lissé gris "
		"clair légèrement chaud (luminosité environ 72 à 80 %), joints fins réguliers formant des rectangles d'environ "
		"2 × 1 cases, très légères traces de pneus et poussière claire, quelques fines fissures ; plat, sans "
		"marquage peint, sans lettre.",
		[PAVES, DIGUE], VALEURS),
]

## Hauteur de l'enveloppe ramenée (cases × 96).
TAILLE_OBJET = {o[1]: o[2] for o in OBJETS}


def _images() -> list[dict]:
	images = []
	for ident, _asset, (l, h), description, ancres in COQUES:
		texte = (f"{ident} — NOUVELLE image : l'enveloppe d'une pièce intérieure de jeu (murs, sol, fenêtres ; aucun "
			f"meuble).\nImages jointes : {', '.join(Path(a).stem for a in ancres)} = enveloppe déjà peinte du jeu "
			"(ancre de style : rendu peint, contour coloré, finesse, angle de vue, géométrie d'une enveloppe, lumière "
			"neutre) et pièce de référence validée (composition) : respecte-les.\n\n"
			f"{ADN}\n{LUMIERE}\n\n{ENVELOPPE}\n{description}\n{ENVELOPPE_INTERDITS}\n")
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "texte": texte, "jointes": ancres})
	for ident, _asset, largeur, profondeur, description, ancres in FACADES:
		taille = (largeur * CASE, profondeur * CASE + 24)
		gen = daf3._format(*taille)
		ew, eh = daf3._boite(gen, taille)
		texte = (f"{ident} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\nImages jointes : "
			f"{', '.join(Path(a).stem for a in ancres)} = bâtiments déjà peints du jeu : ancres de style (rendu "
			f"peint, même angle de vue, même lumière neutre, mêmes matériaux).\n\n{ADN}\n{VALEURS}\n\nASSET : "
			f"{description}\nFormat : PNG {gen[0]} × {gen[1]}, l'élément occupe environ {ew} × {eh} px (rapport "
			f"{taille[0] / taille[1]:.2f} : 1, à RESPECTER : l'image est ramenée telle quelle à {taille[0]} × "
			f"{taille[1]} px, 1 case = 96 px), centré, tout le bâtiment visible.\n{daf3.OBJET_FIN}\n{INTERDITS}\n")
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "texte": texte, "jointes": ancres})
	for ident, _asset, taille, description, ancres in OBJETS:
		gen = daf3._format(*taille)
		ew, eh = daf3._boite(gen, taille)
		texte = (f"{ident} — NOUVELLE image : un seul objet de jeu isolé, pas une scène.\nImages jointes : "
			f"{', '.join(Path(a).stem for a in ancres)} = ancres de style (rendu peint, angle de vue, lumière).\n\n"
			f"{ADN}\n{LUMIERE}\n\nASSET : {description}\nFormat : PNG {gen[0]} × {gen[1]}, l'objet occupe environ "
			f"{ew} × {eh} px, centré, entier.\n{daf3.OBJET_FIN}\n{INTERDITS}\n")
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "texte": texte, "jointes": ancres})
	for ident, _asset, description, ancres, valeurs in SOLS:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, [], True), "jointes": ancres})
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
	print(f"{len(_images())} prompts dans {PROMPTS}")


def generer(choix: set[str]) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	images = [i for i in _images() if not choix or i["groupe"] in choix or i["nom"] in choix]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(daf3._generer, images):
			print(ligne, flush=True)


def preparer_modules() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	for ident, asset, (l, h), *_r in COQUES:
		source = ART / daf3._source(ident)
		if source.exists():
			image = Image.open(source).convert("RGB").resize((l * CASE, h * CASE), Image.LANCZOS)
			image.save(RACINE / _I / f"{asset}.png", optimize=True)
			catalogue["images"][asset] = {"fichier": f"res://{_I}{asset}.png", "taille": list(image.size)}
			print(f"{asset} : {image.size}")
	for ident, asset, largeur, profondeur, *_r in FACADES:
		source = ART / daf3._source(ident)
		if source.exists():
			image = preparer._silhouette(Image.open(source).convert("RGBA")).resize(
				(largeur * CASE, profondeur * CASE + 24), Image.LANCZOS)
			daf3._ecrire_avec_ombres(image, asset, catalogue, manifeste)
			print(f"{asset} : {image.size}")
	for ident, asset, taille, *_r in OBJETS:
		source = ART / daf3._source(ident)
		if source.exists():
			image = preparer._silhouette(Image.open(source).convert("RGBA"))
			image = image.crop(image.getbbox())
			echelle = taille[1] / image.height
			image = image.resize((round(image.width * echelle), taille[1]), Image.LANCZOS)
			image.save(RACINE / _I / f"{asset}.png", optimize=True)
			catalogue["objets"][asset] = {"fichier": f"res://{_I}{asset}.png", "taille": list(image.size)}
			print(f"{asset} : {image.size}")
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = catalogue
	sols = [{"id": asset, "source": daf3._source(ident), "sortie": f"{_G}{asset}.png", "taille": 384,
		"contraste": 0.85, "couleur": 1.0, "raccord": 24} for ident, asset, *_r in SOLS
		if (ART / daf3._source(ident)).exists()]
	p.m = dict(manifeste, sols=sols)
	p.sols()
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--modules"]:
		preparer_modules()
	else:
		generer(set(args))
