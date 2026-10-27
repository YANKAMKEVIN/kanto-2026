#!/usr/bin/env python3
"""Lot DAF.4 « Fin du jeu », suite (phase DA) : Route Victoire 1F à 3F (J29), Grotte Azurée 1F, 2F,
B1F (J31), Route 23 et fonds de combat dédiés. Fiche : `docs/design/fiches-assets/daf-4/fiche.md`.
La part déjà faite (Arène de Jadielle) est dans `tools/art/daf3.py`, dont ce script reprend les
outils (prompts de modules, génération Codex avec la règle de Kevin, découpe des planches, recette
des fonds de combat).

Méthode : seconde passe d'image sur les cartes en tuiles provisoires (`tools/build_daf4_caves.gd`,
modèle `build_route_22_west.gd`) : la logique ne bouge pas ; le sol peint porte deux niveaux (sol bas
= base, sol haut `:` et escaliers `=` = canal R, parois `#` = canal G), les parois sont les modules
du Mont Sélénite (`cave_map_kit.gd`), les rebords, escaliers, interrupteurs et barrières viennent des
planches de ce lot. RP-133 : le sol haut doit se distinguer du sol bas au premier coup d'œil.

Usage :
  tools/art/daf4.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf4.py [GROUPE ...]         génère avec Codex (vagues ; sans argument : tout ce qui manque)
  tools/art/daf4.py --tuiles             portions TL / TR des fonds de combat (avant la vague 2)
  tools/art/daf4.py --modules            sols et planches → assets/ (catalogue)
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

PROMPTS = ICI / "prompts" / "daf4"
_W = "assets/world/"
_G, _R, _P = f"{_W}ground/", f"{_W}relief/", f"{_W}props/"
PAROIS = [f"{_R}relief_paroi_grotte_0{i}.png" for i in (1, 5, 6)]
GROTTE = f"{_G}ground_grotte_01.png"
EAU_GROTTE = f"{_G}ground_eau_grotte_01.png"
ROCHER = f"{_P}prop_rocher_force_01.png"
ECHELLE = f"{_P}prop_echelle_monte_01.png"

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu ajoute lui-même la "
	"pénombre de la grotte et ses halos) : AUCUNE teinte dorée, AUCUN halo, AUCUNE flaque de lumière, aucune "
	"ombre portée au sol.")
VALEURS_VICTOIRE = ("VALEURS DE LA ROUTE VICTOIRE (la dernière grotte avant la Ligue : roche brune et ocre, "
	"solennelle et rude, jamais effrayante) : grès brun-ocre, roche brun-rouge sombre, poussière beige ; "
	+ LUMIERE)
VALEURS_AZUREE = ("VALEURS DE LA GROTTE AZURÉE (une grotte mystérieuse et froide derrière Azuria : roche bleu-gris "
	"et violacée, eau calme bleu profond, jamais effrayante) : pierre bleu ardoise, gris-violet, touches de "
	"bleu glacier ; " + LUMIERE)

SOLS = [
	("WORLD_GROUND_VICTOIRE_BAS_01", "ground_victoire_bas_01",
		"texture du SOL BAS de la Route Victoire, vue strictement de dessus : terre battue et gravillons BRUN "
		"MOYEN (luminosité environ 38 à 45 %), petits cailloux épars, fines traînées de poussière, quelques "
		"fissures ; un peu plus sombre et plus chaud que le sol de grotte joint ; aucun gros rocher.",
		[GROTTE], VALEURS_VICTOIRE),
	("WORLD_GROUND_VICTOIRE_HAUT_01", "ground_victoire_haut_01",
		"texture du SOL HAUT (plateaux surélevés) de la Route Victoire, vue strictement de dessus : grandes "
		"DALLES de GRÈS OCRE CLAIR naturelles et usées, plates (luminosité environ 62 à 70 %, NETTEMENT plus "
		"claires que le sol bas joint, pour qu'on voie au premier coup d'œil que c'est un autre niveau), joints "
		"irréguliers fins, un peu de sable clair dans les creux.",
		[GROTTE], VALEURS_VICTOIRE),
	("WORLD_GROUND_AZUREE_BAS_01", "ground_azuree_bas_01",
		"texture du SOL BAS de la Grotte Azurée, vue strictement de dessus : roche et gravier BLEU-GRIS ardoise "
		"(luminosité environ 36 à 44 %), petits cailloux, quelques flaques sèches plus sombres, fissures fines.",
		[GROTTE, EAU_GROTTE], VALEURS_AZUREE),
	("WORLD_GROUND_AZUREE_HAUT_01", "ground_azuree_haut_01",
		"texture du SOL HAUT (corniches surélevées) de la Grotte Azurée, vue strictement de dessus : dalles de "
		"pierre GRIS-BLEU PÂLE et lavande, plates et lisses (luminosité environ 62 à 70 %, NETTEMENT plus "
		"claires que le sol bas), joints fins, veines de quartz blanc très discrètes.",
		[GROTTE], VALEURS_AZUREE),
]

_FORMAT = daf3._CELLULES + ", à une échelle COMMUNE de 1 case = 150 px, vus de dessus en trois quarts (on voit le dessus et la face avant sud)"


def _planche(lieu: str, matiere: str, haut: str, extra: str) -> str:
	return (f"PLANCHE d'ÉLÉMENTS de la {lieu}, {_FORMAT}. Matière : {matiere}.\n"
		"1 (ligne 1, à gauche) : REBORD, la FACE AVANT d'un plateau surélevé vue de face (le sol bas est au SUD, "
		f"le sol haut {haut} au NORD) : une petite falaise de roche d'EXACTEMENT 1 case de large (≈ 150 px) et "
		"environ 0,6 case de haut, avec en haut un liseré du sol haut vu de dessus ; bords gauche et droit COUPÉS "
		"NET en ligne droite (il se juxtapose bout à bout en longues rangées), bas droit.\n"
		"2 (ligne 1, au milieu) : BORD LATÉRAL, le côté d'un plateau dont le sol bas est à DROITE : une bande "
		"VERTICALE de roche vue de dessus, environ 0,25 case de large × EXACTEMENT 1 case de haut, coupée net en "
		"haut et en bas (juxtaposable verticalement).\n"
		"3 (ligne 1, à droite) : ESCALIER, des MARCHES de pierre taillées dans la roche qui MONTENT vers le nord "
		"(le haut de l'image), vues de dessus en trois quarts, EXACTEMENT 1 case de large × 1 case de haut, trois "
		f"ou quatre marches, base droite.\n{extra}"
		"Fond avec une vraie transparence (canal alpha), aucun sol autour, aucune ombre portée, aucun texte.")


PLANCHES = [
	("INT_VICTOIRE_PLANCHE", _planche("ROUTE VICTOIRE", "roche brun-ocre et grès, le dessus du plateau en dalles "
		"de grès ocre clair comme la texture jointe ground_victoire_haut", "(dalles ocre clair)",
		"4 (ligne 2, à gauche) : INTERRUPTEUR, une grande DALLE de pierre carrée posée au sol, vue de dessus, 1 "
		"case × 1 case, avec au centre un gros BOUTON rond de pierre bleu-gris en relief, RELEVÉ, cerclé d'un "
		"anneau de bronze (aucun symbole, aucune lettre).\n"
		"5 (ligne 2, au milieu) : INTERRUPTEUR ENFONCÉ, la MÊME dalle, le bouton enfoncé au ras de la dalle, "
		"l'anneau de bronze plus visible.\n"
		"6 (ligne 2, à droite) : BARRIÈRE, un mur de BLOCS de pierre brun sombre empilés, cerclé de fer, qui ferme "
		"un passage, vu de face en trois quarts, EXACTEMENT 1 case de large et environ 1,3 case de haut, base "
		"droite.\n"),
		PAROIS + [GROTTE, ROCHER], VALEURS_VICTOIRE,
		["WORLD_GROUND_VICTOIRE_BAS_01_NE_r1.png", "WORLD_GROUND_VICTOIRE_HAUT_01_NE_r1.png"]),
	("INT_AZUREE_PLANCHE", _planche("GROTTE AZURÉE", "roche bleu-gris ardoise et violacée, le dessus des "
		"corniches en dalles gris-bleu pâle comme la texture jointe ground_azuree_haut", "(dalles gris-bleu pâle)",
		"(ligne 2) : les trois cellules restent VIDES.\n"),
		PAROIS + [GROTTE], VALEURS_AZUREE,
		["WORLD_GROUND_AZUREE_BAS_01_NE_r1.png", "WORLD_GROUND_AZUREE_HAUT_01_NE_r1.png"]),
]
PLANCHE_IDS = {
	"INT_VICTOIRE_PLANCHE": (["relief_rebord_victoire_01", "relief_rebord_victoire_cote_01",
		"relief_escalier_victoire_01", "decal_interrupteur_victoire_01", "decal_interrupteur_victoire_enfonce_01",
		"prop_barriere_victoire_01"], [1, 0.25, 1, 1, 1, 1]),
	"INT_AZUREE_PLANCHE": (["relief_rebord_azuree_01", "relief_rebord_azuree_cote_01",
		"relief_escalier_azuree_01"], [1, 0.25, 1]),
}

# --- Fonds de combat ------------------------------------------------------------------------------

_SOL_AB = daf3._SOL_AB
COMBATS = [
	("COMBAT_DECOR_ROUTE_23", "ROUTE 23, AU PIED DU PLATEAU INDIGO", f"{_G}ground_roche_01.png",
		"la ROUTE 23, une route de montagne rocheuse au pied du Plateau Indigo : sol de terre et de roche "
		"claire, quelques touffes d'herbe rase, de hautes FALAISES de roche grise et brune sur les côtés, au loin "
		"les sommets de la montagne et, tout petit au fond, un grand bâtiment au toit rouge sur un plateau "
		"(sans détail, sans lettre) ; ciel de fin d'après-midi.",
		"- Horizon et fond (de 0 à 38 % de la hauteur) : falaises à gauche (x 0 à 25 %) et à droite (x 75 à 100 "
		"%), montagnes au loin au centre, le bâtiment minuscule vers x 55 %.\n- De 40 % de la hauteur jusqu'en "
		"bas : GRAND SOL DÉGAGÉ et PLAT de terre et de roche claire.\n" + _SOL_AB,
		"golden hour, soleil bas du haut à gauche (hors cadre), lumière chaude sur les falaises, ciel bleu pâle "
		"voilé ; ombres bleu-violet douces.",
		daf3._INTERDITS_COMBAT + " Route goudronnée, voiture, panneau, drapeau."),
	("COMBAT_DECOR_ROUTE_VICTOIRE", "ROUTE VICTOIRE (GROTTE)", f"{_G}ground_victoire_haut_01.png",
		"la ROUTE VICTOIRE, la grande grotte avant la Ligue : parois de roche brun-ocre, un PLATEAU surélevé de "
		"dalles de grès clair au fond à droite avec trois marches taillées, quelques gros rochers ronds sur les "
		"côtés, au premier plan un GRAND SOL de terre battue brune et de gravillons.",
		"- Fond (de 0 à 38 % de la hauteur) : la paroi du fond, le plateau et ses marches à droite (x 70 à 92 %), "
		"deux gros rochers à gauche (x 10 à 22 %).\n- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et "
		"PLAT de terre battue.\n" + _SOL_AB,
		"lumière de grotte chaude et douce venant d'une ouverture hors cadre en haut à gauche, le centre du sol "
		"nettement lisible ; ombres brun-violet, jamais noires.",
		daf3._INTERDITS_COMBAT + " Lave, cristal géant, torche, échafaudage."),
	("COMBAT_DECOR_GROTTE_AZUREE", "GROTTE AZURÉE", f"{_G}ground_azuree_haut_01.png",
		"la GROTTE AZURÉE, une grotte mystérieuse et froide : parois de roche bleu-gris et violacée, une large "
		"bande d'EAU calme bleu profond au fond à gauche, quelques stalagmites, de petites concrétions de quartz "
		"pâle, au premier plan un GRAND SOL plat de roche gris-bleu.",
		"- Fond (de 0 à 38 % de la hauteur) : la paroi du fond, l'eau calme à gauche (x 8 à 42 %), deux "
		"stalagmites à droite (x 78 à 90 %).\n- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de "
		"roche gris-bleu.\n" + _SOL_AB,
		"lumière froide et claire, bleu pâle, venant du haut à gauche, l'eau reflète doucement ; le centre du sol "
		"lumineux ; ombres bleu nuit et violettes, jamais noires.",
		daf3._INTERDITS_COMBAT + " Cristal géant lumineux, décor féerique, lave."),
]
COMBAT_IDS = {"COMBAT_DECOR_ROUTE_23": "route_23_roche", "COMBAT_DECOR_ROUTE_VICTOIRE": "victory_road_grotte",
	"COMBAT_DECOR_GROTTE_AZUREE": "cerulean_cave_azuree"}


def _images() -> list[dict]:
	import serie27
	images = []
	for ident, _asset, description, ancres, valeurs in SOLS:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 1,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, [], True), "jointes": ancres})
	for ident, description, ancres, valeurs, v1 in PLANCHES:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 2,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, v1, False), "jointes": ancres + v1})
	for ident, lieu, image3, description, compo, lumiere, interdits in COMBATS:
		images.append({"nom": f"{ident}_r1", "groupe": ident, "vague": 2,
			"texte": serie27.prompt_combat(ident, lieu, "une texture du lieu : guide de PALETTE et de matières "
				"seulement.", description, compo, lumiere, interdits),
			"jointes": [serie27.COMBAT_REF, serie27.COMBAT_PLANCHE, image3]})
		for cote in ("TL", "TR"):
			images.append({"nom": f"{ident}_r1_{cote}", "groupe": f"{ident}_TUILES", "vague": 3,
				"texte": serie27.TUILE.read_text(), "jointes": [f"{ident}_r1_{cote}_SOURCE.png"]})
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
	print(f"{len(_images())} prompts dans {PROMPTS}")


def generer(choix: set[str]) -> None:
	for vague in (1, 2, 3):
		images = [i for i in _images() if i["vague"] == vague and (
			not choix or i["groupe"] in choix or i["nom"] in choix)]
		images = [i for i in images if all((RACINE / j if "/" in j else ART / j).exists() for j in i["jointes"])]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(daf3._generer, images):
				print(ligne, flush=True)


def tuiles() -> None:
	import serie27
	for ident, *_r in COMBATS:
		source = ART / f"{ident}_r1.png"
		if not source.exists():
			print(f"{source.name} absent")
			continue
		im = Image.open(source).convert("RGB")
		w, h = im.size
		part = round(w * serie27.TUILE_PART)
		im.crop((0, 0, part, h)).save(ART / f"{ident}_r1_TL_SOURCE.png")
		im.crop((w - part, 0, w, h)).save(ART / f"{ident}_r1_TR_SOURCE.png")
		print(f"{ident} : portions [0, 0, {part}, {h}] et [{w - part}, 0, {w}, {h}]")


def preparer_modules() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	sols = [{"id": asset, "source": daf3._source(ident), "sortie": f"{_G}{asset}.png", "taille": 384,
		"contraste": 0.85, "couleur": 1.0, "raccord": 24} for ident, asset, *_r in SOLS
		if (ART / daf3._source(ident)).exists()]
	p.m = dict(manifeste, sols=sols)
	p.sols()
	daf3_decals = daf3.DECALS
	daf3.DECALS = ("decal_interrupteur_victoire_01", "decal_interrupteur_victoire_enfonce_01")
	for ident, (ids, cases) in PLANCHE_IDS.items():
		if not (ART / daf3._source(ident)).exists():
			print(f"{ident} : absente")
			continue
		for asset, element in daf3._decouper(daf3._source(ident), ids, cases):
			dossier = _P if asset.startswith("prop_") else (_R if asset.startswith("relief_") else
				f"{_W}interiors/")
			p._objet(asset, f"{dossier}{asset}.png", element, False, 0.0 if dossier == _R else 0.12)
	daf3.DECALS = daf3_decals
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--tuiles"]:
		tuiles()
	elif args[:1] == ["--modules"]:
		preparer_modules()
	else:
		generer(set(args))
