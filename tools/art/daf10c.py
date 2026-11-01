#!/usr/bin/env python3
"""Lot DAF.10c « Îles Écume et Centrale » (J33, gel fonctionnel ; RP-275, RP-276) : kit de grotte glacée
(sol bas, masse, parois, rebords, escaliers, trous, petits rochers) et kit d'usine électrique (sol, masse,
murs en modules, machines). Fiche : `docs/design/fiches-assets/daf-10c/fiche.md`.

Méthode de DAF.4 (`daf4.py`) : Codex CLI (sans dépense d'API), prompts versionnés dans
`tools/art/prompts/daf10c/`, règle de Kevin (AVEC les ancres d'abord, puis SANS) dans `daf3._generer` ;
seconde passe d'image sur les cartes (`tools/build_daf10c_seafoam.gd`, `tools/build_daf10c_centrale.gd`) :
la logique ne bouge pas. Réemplois : `ground_glace_01` (sol haut), `ground_eau_grotte_01` (eau froide),
`ground_courant_01` (courants), `prop_rocher_force_01` et `_eau_01` (rochers), échelles du Mont Sélénite.

Usage :
  tools/art/daf10c.py --prompts            écrit les prompts (sans Codex)
  tools/art/daf10c.py [GROUPE ...]         génère avec Codex (vagues ; sans argument : tout ce qui manque)
  tools/art/daf10c.py --tuiles             portions TL / TR du fond de combat (avant la vague 3)
  tools/art/daf10c.py --modules            sols et planches → assets/ (catalogue)
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
from daf3 import ADN, ART, INTERDITS, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "daf10c"
_W = "assets/world/"
_G, _R, _P, _I = f"{_W}ground/", f"{_W}relief/", f"{_W}props/", f"{_W}interiors/"
PAROIS = [f"{_R}relief_paroi_grotte_0{i}.png" for i in (1, 2, 5, 6)]
GLACE = f"{_G}ground_glace_01.png"
GROTTE = f"{_G}ground_grotte_01.png"
EAU_GROTTE = f"{_G}ground_eau_grotte_01.png"
MASSE_ROCHE = f"{_G}ground_masse_roche_01.png"
ROCHER = f"{_P}prop_rocher_force_01.png"
BETON = f"{_G}ground_beton_repaire_01.png"
MURS_REPAIRE = [f"{_R}relief_mur_repaire_0{i}.png" for i in (1, 2, 3, 4)]
MACHINES = [f"{_I}int_armoire_electrique_01.png", f"{_I}int_console_repaire_01.png"]

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu ajoute lui-même la "
	"pénombre et ses halos) : AUCUNE teinte dorée, AUCUN halo, AUCUNE lueur, aucune ombre portée au sol.")
VALEURS_ECUME = ("VALEURS DES ÎLES ÉCUME (une grotte marine GLACÉE au large de Kanto, froide, calme et belle, "
	"jamais effrayante) : roche bleu ardoise et gris-bleu, GIVRE blanc, GLACE bleu pâle translucide, neige "
	"tassée dans les creux, eau bleu profond ; " + LUMIERE)
VALEURS_CENTRALE = ("VALEURS DE LA CENTRALE (une usine électrique ABANDONNÉE de Kanto, envahie par des "
	"Pokémon Électrik : poussiéreuse, industrielle, un peu mystérieuse, JAMAIS sinistre) : béton gris-vert usé, "
	"tôles d'acier gris bleuté, peinture industrielle VERT D'EAU écaillée, bandes de sécurité JAUNES et noires "
	"usées, câbles noirs, isolateurs de céramique blanche, cuivre patiné ; " + LUMIERE)

## Textures : (identifiant, asset, description, ancres, valeurs).
SOLS = [
	("WORLD_GROUND_ECUME_BAS_01", "ground_ecume_bas_01",
		"texture du SOL BAS des Îles Écume, vue strictement de dessus : roche GELÉE bleu-gris ardoise (luminosité "
		"environ 40 à 48 %, NETTEMENT plus sombre que la glace jointe ground_glace_01 qui fait le sol haut), "
		"plaques de givre blanc éparses, petits cailloux gris-bleu, fines craquelures ; mate, aucun reflet.",
		[GLACE, GROTTE], VALEURS_ECUME),
	("WORLD_GROUND_MASSE_GLACE_01", "ground_masse_glace_01",
		"texture du DESSUS DES PAROIS (masses de roche hors du chemin) des Îles Écume, vue strictement de dessus : "
		"blocs de roche bleu nuit très sombre (luminosité environ 14 à 22 %) coiffés de GIVRE et de petites "
		"plaques de neige bleu pâle dans les creux, comme la masse jointe ground_masse_roche_01 mais froide ; "
		"sombre mais jamais noir pur ; sert à remplir de grandes surfaces.",
		[MASSE_ROCHE, GLACE], VALEURS_ECUME),
	("WORLD_GROUND_CENTRALE_01", "ground_centrale_01",
		"texture du SOL de la CENTRALE (une usine électrique), vue strictement de dessus : grandes DALLES de BÉTON "
		"gris-vert usé (luminosité environ 50 à 58 %), une dalle par case (1 case = 256 px sur cette texture), "
		"joints sombres, taches d'huile légères, poussière, quelques plaques d'ACIER antidérapant gaufré "
		"insérées çà et là, AUCUNE ligne peinte continue ; assez clair pour que des Poké Balls et des objets "
		"posés ressortent nettement.",
		[BETON], VALEURS_CENTRALE),
	("WORLD_GROUND_MASSE_CENTRALE_01", "ground_masse_centrale_01",
		"texture du DESSUS DES MACHINES et des murs épais de la Centrale vus de dessus : TÔLES d'acier gris bleuté "
		"SOMBRE (luminosité environ 16 à 24 %) rivetées, quelques GRILLES de ventilation, faisceaux de câbles "
		"noirs, très légères traces de rouille ; régulier, sans élément remarquable ; sombre mais jamais noir "
		"pur ; sert à remplir de grandes surfaces.",
		[BETON, MURS_REPAIRE[0]], VALEURS_CENTRALE),
]

_ECHELLE = (daf3._CELLULES + ", à une échelle COMMUNE de 1 case = 150 px, vus de dessus en trois quarts "
	"(on voit le dessus et la face avant sud)")
_FOND = "Fond avec une vraie transparence (canal alpha), aucun sol autour, aucune ombre portée, aucun texte."

## Planches : (identifiant, description, ancres, valeurs, jointes de la vague 1).
PLANCHES = [
	("WORLD_RELIEF_PAROI_GLACE_PLANCHE",
		f"PLANCHE de 4 MODULES DE PAROI de grotte GLACÉE des Îles Écume, {_ECHELLE}. MÊMES rôles, MÊMES "
		"découpes, MÊMES proportions et même manière de peindre que les modules joints relief_paroi_grotte_01, "
		"_02, _05 et _06 (les parois du Mont Sélénite), mais en roche BLEU ARDOISE froide coiffée de GIVRE et de "
		"neige tassée, avec des coulures et des stalactites de GLACE bleu pâle translucide sur les faces.\n"
		"1 (ligne 1, à gauche) : FACE A, une paroi vue de face (le sol est au SUD), EXACTEMENT 3 cases de large "
		"(≈ 450 px) et environ 1,95 case de haut : en haut une bande du dessus de la masse vue de dessus (givre), "
		"puis la face rocheuse ; bords gauche et droit COUPÉS NET (elle se juxtapose bout à bout), bas droit.\n"
		"2 (ligne 1, au milieu) : FACE B, même gabarit, avec une grande coulée de glace bleu pâle au milieu.\n"
		"3 (ligne 1, à droite) : BORD LATÉRAL, le côté d'une masse dont le sol est à DROITE : une bande VERTICALE "
		"de roche givrée vue de dessus, EXACTEMENT 1 case de large et environ 3,15 cases de haut, coupée net en "
		"haut et en bas (juxtaposable verticalement).\n"
		"4 (ligne 2, à gauche) : LÈVRE NORD, le bord d'une masse dont le sol est au NORD : une bande HORIZONTALE "
		"de rochers givrés vue de dessus, EXACTEMENT 3 cases de large et environ 0,85 case de haut, coupée net à "
		"gauche et à droite. (ligne 2, au milieu et à droite) : cellules VIDES.\n" + _FOND,
		PAROIS, VALEURS_ECUME, ["WORLD_GROUND_ECUME_BAS_01_NE_r1.png", "WORLD_GROUND_MASSE_GLACE_01_NE_r1.png"]),
	("INT_ECUME_PLANCHE",
		f"PLANCHE d'ÉLÉMENTS des ÎLES ÉCUME, {_ECHELLE}. Matière : roche bleu ardoise givrée ; le sol haut est la "
		"GLACE bleu pâle de la texture jointe ground_glace_01, le sol bas la roche gelée de "
		"WORLD_GROUND_ECUME_BAS_01.\n"
		"1 (ligne 1, à gauche) : REBORD, la FACE AVANT d'un plateau de glace surélevé vue de face (le sol bas est "
		"au SUD, le sol haut de glace au NORD) : une petite falaise de roche givrée et de glace d'EXACTEMENT 1 case "
		"de large (≈ 150 px) et environ 0,6 case de haut, avec en haut un liseré de glace pâle vu de dessus ; "
		"bords gauche et droit COUPÉS NET en ligne droite (il se juxtapose bout à bout en longues rangées), bas "
		"droit.\n"
		"2 (ligne 1, au milieu) : BORD LATÉRAL, le côté d'un plateau dont le sol bas est à DROITE : une bande "
		"VERTICALE de roche givrée vue de dessus, environ 0,25 case de large × EXACTEMENT 1 case de haut, coupée "
		"net en haut et en bas.\n"
		"3 (ligne 1, à droite) : ESCALIER, des MARCHES taillées dans la glace et la roche givrée qui MONTENT vers "
		"le nord (le haut de l'image), vues de dessus en trois quarts, EXACTEMENT 1 case de large × 1 case de "
		"haut, trois ou quatre marches nettes, base droite.\n"
		"4 (ligne 2, à gauche) : TROU OUVERT dans le sol de roche gelée, PLAT, vu strictement de dessus, 1 case × "
		"1 case : un puits rond aux bords de roche brisée et GIVRÉE, l'intérieur bleu nuit SOMBRE (jamais noir "
		"pur), un peu de neige au bord.\n"
		"5 (ligne 2, au milieu) : TROU BOUCHÉ, PLAT, vu strictement de dessus, le même trou rempli par un gros "
		"rocher rond gris clair enfoncé au ras du sol, givre autour, 1 case × 1 case.\n"
		"6 (ligne 2, à droite) : PETIT ROCHER FIXE, un bloc de roche gris-bleu coiffé de neige et de glace, vu de "
		"face en trois quarts, 1 case de large, environ 0,9 case de haut, base droite (il ne ressemble PAS au "
		"rocher rond fissuré joint prop_rocher_force_01, qui se pousse : il est anguleux, plus sombre et "
		"enneigé).\n" + _FOND,
		[GLACE, f"{_R}relief_rebord_azuree_01.png", f"{_R}relief_escalier_azuree_01.png",
			f"{_I}decal_trou_victoire_01.png", ROCHER], VALEURS_ECUME, ["WORLD_GROUND_ECUME_BAS_01_NE_r1.png"]),
	("WORLD_RELIEF_MUR_CENTRALE_PLANCHE", daf3._planche_murs("de la CENTRALE (les machines et cloisons de l'usine)",
		"MACHINES et cloisons d'usine : panneaux de TÔLE d'acier peints VERT D'EAU écaillé, rivets, armoires de "
		"commande à petits cadrans ronds et manettes, tuyaux et câbles noirs le long du bas, couronnement de tôle "
		"gris bleuté sombre vu de dessus, PLINTHE à bande de sécurité jaune et noire usée",
		"un TRANSFORMATEUR : un gros bloc gris à AILETTES de refroidissement verticales, deux grands isolateurs "
		"de céramique blanche dessus, des câbles qui en sortent"),
		MURS_REPAIRE + MACHINES, VALEURS_CENTRALE,
		["WORLD_GROUND_CENTRALE_01_NE_r1.png", "WORLD_GROUND_MASSE_CENTRALE_01_NE_r1.png"]),
	("INT_CENTRALE_PLANCHE",
		f"PLANCHE de 6 MACHINES de la CENTRALE, {daf3._CELLULES}, à une échelle COMMUNE de 1 case = 120 px, toutes "
		"vues de DESSUS en trois quarts (on voit surtout le dessus, un peu la face sud) : elles sont posées sur le "
		"haut des grands blocs de machines du jeu, de la même main que les murs et le sol joints.\n"
		"1 (ligne 1, à gauche) : GÉNÉRATEUR, une grosse turbine cylindrique couchée à carter vert d'eau, "
		"EXACTEMENT 2 cases de large × environ 1,6 case de haut, brides boulonnées, un câble noir.\n"
		"2 (ligne 1, au milieu) : TRANSFORMATEUR vu de dessus, un bloc gris à ailettes et trois isolateurs de "
		"céramique blanche, 1 case × environ 1,3 case.\n"
		"3 (ligne 1, à droite) : BOBINE, un grand enroulement de CUIVRE patiné sur un socle d'acier, cerclé "
		"d'isolateurs blancs, 1 case × environ 1,4 case (éteinte : aucun arc, aucune étincelle).\n"
		"4 (ligne 2, à gauche) : CONDENSATEURS, une rangée de quatre gros cylindres gris à capuchon de cuivre sur "
		"une plaque d'acier, 2 cases de large × environ 1 case de haut.\n"
		"5 (ligne 2, au milieu) : TABLEAU DE COMMANDE couché, un pupitre d'acier vert d'eau à cadrans ronds "
		"et manettes, vu de dessus, 1 case × environ 1,1 case (cadrans SANS chiffres, voyants éteints).\n"
		"6 (ligne 2, à droite) : TOURET DE CÂBLE, une grosse bobine de bois portant un câble noir enroulé, vue de "
		"dessus en trois quarts, 1 case × environ 1 case.\n"
		"Fond avec une vraie transparence (canal alpha), aucun sol dessiné, aucune ombre portée, aucun texte, aucun "
		"éclair, aucune lueur.",
		MACHINES + [MURS_REPAIRE[1]], VALEURS_CENTRALE,
		["WORLD_GROUND_MASSE_CENTRALE_01_NE_r1.png", "WORLD_RELIEF_MUR_CENTRALE_PLANCHE_NE_r1.png"]),
]
## Assets découpés : (identifiants, largeur en cases), dossier.
PLANCHE_IDS = {
	"WORLD_RELIEF_PAROI_GLACE_PLANCHE": ([f"relief_paroi_glace_0{i}" for i in (1, 2, 5, 6)], [3, 3, 1, 3], _R),
	"INT_ECUME_PLANCHE": (["relief_rebord_ecume_01", "relief_rebord_ecume_cote_01", "relief_escalier_ecume_01",
		"decal_trou_ecume_01", "decal_trou_ecume_bouche_01", "prop_rocher_glace_01"], [1, 0.25, 1, 1, 1, 1], None),
	"WORLD_RELIEF_MUR_CENTRALE_PLANCHE": ([f"relief_mur_centrale_0{i}" for i in range(1, 6)],
		[2, 2, 2, 0.35, 0.35], _R),
	"INT_CENTRALE_PLANCHE": (["int_generateur_centrale_01", "int_transformateur_centrale_01",
		"int_bobine_centrale_01", "int_condensateurs_centrale_01", "int_pupitre_centrale_01",
		"int_touret_centrale_01"], [2, 1, 1, 2, 1, 1], _I),
}
## Tailles exactes : les parois glacées reprennent le gabarit du Mont Sélénite (`cave_map_kit.gd`).
EXACTS = {"relief_paroi_glace_01": (288, 186), "relief_paroi_glace_02": (288, 195),
	"relief_paroi_glace_05": (96, 303), "relief_paroi_glace_06": (288, 81)}
DECALS = ("decal_trou_ecume_01", "decal_trou_ecume_bouche_01")

# --- Fond de combat de la Centrale (remplace le dérivé [D] de DAF.2 bis) ---------------------------

COMBATS = [
	("COMBAT_DECOR_CENTRALE", "CENTRALE (USINE ÉLECTRIQUE ABANDONNÉE)", f"{_G}ground_centrale_01.png",
		"la grande salle des machines de la CENTRALE, une usine électrique abandonnée : sol de dalles de béton "
		"gris-vert usé, au fond une rangée de grosses MACHINES vert d'eau écaillées (turbines, transformateurs à "
		"ailettes, armoires de commande à cadrans), des câbles noirs qui pendent, des isolateurs de céramique "
		"blanche, une passerelle d'acier en hauteur, de la poussière ; un peu mystérieux, jamais sinistre.",
		"- Fond (de 0 à 38 % de la hauteur) : les machines du fond, base du mur vers 36 % de la hauteur ; un "
		"transformateur à gauche (x 8 à 26 %), une turbine à droite (x 74 à 94 %).\n- De 40 % de la hauteur "
		"jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de béton gris-vert.\n" + daf3._SOL_AB,
		"lumière froide un peu jaune venant de hautes verrières sales en haut à gauche (hors cadre), le centre "
		"du sol bien lisible ; quelques petits voyants jaunes peints sur les machines, sans halo ; ombres "
		"bleu-vert, jamais noires.",
		daf3._INTERDITS_COMBAT + " Éclair, arc électrique, étincelle, feu, fumée, personnage en combinaison."),
]
## Reliquats DAF.10d (2026-10-31) : les quatre autres fonds dérivés de DAF.2 bis, peints par Codex.
_LIBRE = "- De 40 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT"
COMBATS += [
	("COMBAT_DECOR_PARMANIE", "ARÈNE DE PARMANIE (DOJO NINJA)", f"{_G}ground_parquet_dojo_01.png",
		"la salle de l'ARÈNE de PARMANIE, un dojo de ninja (Champion de type Poison) : grand parquet de bois "
		"clair ciré, au fond des cloisons coulissantes de papier shoji à cadre de bois sombre, des poutres, deux "
		"grandes tentures VIOLETTES unies, quelques lanternes de papier éteintes, un petit râtelier de bois vide ; "
		"des panneaux de bois discrets qui laissent deviner des murs cachés. Mystérieux, élégant, jamais sinistre.",
		"- Fond (de 0 à 36 % de la hauteur) : les cloisons shoji, base du mur vers 34 % de la hauteur ; une "
		"tenture violette à gauche (x 10 à 22 %), une autre à droite (x 78 à 90 %).\n" + _LIBRE +
		" de parquet clair.\n" + daf3._SOL_AB,
		"lumière douce et tamisée de fin de journée, filtrée par le papier shoji (violet-rose pâle) ; le centre "
		"du parquet bien éclairé ; ombres violet-bleu, jamais noires.",
		daf3._INTERDITS_COMBAT + " Arme, shuriken, sabre, fumée, poison visible, crâne."),
	("COMBAT_DECOR_CRAMOIS", "ARÈNE DE CRAMOIS'ÎLE (VOLCAN)", f"{_G}ground_roche_volcanique_01.png",
		"la salle de l'ARÈNE de CRAMOIS'ÎLE (Champion de type Feu) bâtie dans le flanc d'un volcan : sol de "
		"dalles de pierre volcanique sombre bien jointes, au fond une paroi de roche basaltique avec de fines "
		"veines de LAVE orange qui luisent, deux grands BRASEROS de fer forgé allumés de part et d'autre, une "
		"estrade de pierre au centre du fond ; chaleur, mais lieu sûr et entretenu.",
		"- Fond (de 0 à 38 % de la hauteur) : la paroi de basalte et ses veines de lave, base vers 36 % ; un "
		"brasero à gauche (x 12 à 20 %), un autre à droite (x 80 à 88 %), l'estrade au centre (x 40 à 60 %).\n"
		+ _LIBRE + " de dalles de pierre volcanique, sans fissure de lave au sol.\n" + daf3._SOL_AB,
		"lumière chaude orange et rouge venant des braseros et des veines de lave, plus un peu de jour froid "
		"tombant d'une ouverture hors cadre en haut à gauche ; le centre du sol lisible ; ombres brun-violet, "
		"jamais noires.",
		daf3._INTERDITS_COMBAT + " Lave au premier plan, rivière de lave, fumée épaisse, explosion."),
	("COMBAT_DECOR_SAFARI", "PARC SAFARI (SAVANE)", f"{_G}ground_hautes_herbes_jaune_01.png",
		"une clairière du PARC SAFARI de Parmanie, une réserve naturelle aux allures de savane : grand sol de "
		"terre battue claire et d'herbe rase dorée, au fond des HAUTES HERBES jaunes, quelques acacias à la cime "
		"plate, un enclos de rondins bas, des collines douces au loin ; ciel clair d'après-midi.",
		"- Horizon vers 40 % de la hauteur : collines lointaines, deux acacias (x 10 à 24 % et x 76 à 90 %), une "
		"bande de hautes herbes jaunes au pied, une clôture de rondins basse à droite.\n" + _LIBRE +
		" de terre claire et d'herbe rase dorée, sans hautes herbes au centre.\n" + daf3._SOL_AB,
		"golden hour douce, soleil bas du haut à gauche (hors cadre), ombres chaudes et longues, ciel bleu pâle "
		"aux nuages légers, pas de soleil visible.",
		daf3._INTERDITS_COMBAT + " Animal, girafe, éléphant, véhicule, jeep, bâtiment."),
	("COMBAT_DECOR_SYLPHE_HALL", "HALL D'ACCUEIL DE LA SYLPHE SARL", f"{_G}ground_moquette_sylphe_01.png",
		"le grand HALL D'ACCUEIL du siège de la Sylphe SARL (entreprise technologique, Safrania) : sol de grandes "
		"dalles claires crème et ivoire polies, au fond un long COMPTOIR d'accueil incurvé en bois clair et blanc, "
		"derrière une paroi de verre et de panneaux bleu pâle, deux portes d'ASCENSEUR métalliques fermées, "
		"des plantes vertes en pot, une banquette ; moderne, propre, lumineux.",
		"- Fond (de 0 à 36 % de la hauteur) : la paroi du fond, base vers 34 % ; le comptoir au centre gauche "
		"(x 22 à 50 %), les deux ascenseurs à droite (x 62 à 86 %), une plante à chaque bout.\n" + _LIBRE +
		" de dalles claires polies (reflets doux, pas un miroir).\n" + daf3._SOL_AB,
		"lumière de jour blanche et douce venant de grandes baies hors cadre à gauche, plafonniers discrets ; "
		"ombres gris-bleu légères, jamais noires.",
		daf3._INTERDITS_COMBAT + " Écran allumé, logo, enseigne, garde, Team Rocket."),
]
COMBAT_IDS = {"COMBAT_DECOR_CENTRALE": "power_plant_centrale", "COMBAT_DECOR_PARMANIE": "fuchsia_gym_ninja",
	"COMBAT_DECOR_CRAMOIS": "cinnabar_gym_volcan", "COMBAT_DECOR_SAFARI": "safari_zone_savane",
	"COMBAT_DECOR_SYLPHE_HALL": "silph_co_hall"}


def _images() -> list[dict]:
	import serie27
	images = []
	for ident, _asset, description, ancres, valeurs in SOLS:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 1,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, [], True), "jointes": ancres})
	for ident, description, ancres, valeurs, v1 in PLANCHES:
		images.append({"nom": f"{ident}_NE_r1", "groupe": ident, "vague": 2 if "PAROI" in ident or "MUR" in ident
			or "ECUME" in ident else 3,
			"texte": daf3._prompt_module(ident, description, ancres, valeurs, v1, False), "jointes": ancres + v1})
	for ident, lieu, image3, description, compo, lumiere, interdits in COMBATS:
		images.append({"nom": f"{ident}_r1", "groupe": ident, "vague": 2,
			"texte": serie27.prompt_combat(ident, lieu, "une texture du lieu : guide de PALETTE et de matières "
				"seulement.", description, compo, lumiere, interdits),
			"jointes": [serie27.COMBAT_REF, serie27.COMBAT_PLANCHE, image3]})
		for cote in ("TL", "TR"):
			images.append({"nom": f"{ident}_r1_{cote}", "groupe": f"{ident}_TUILES", "vague": 4,
				"texte": serie27.TUILE.read_text(), "jointes": [f"{ident}_r1_{cote}_SOURCE.png"]})
	return images


def ecrire_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for image in _images():
		(PROMPTS / f"{image['nom']}.txt").write_text(image["texte"])
	print(f"{len(_images())} prompts dans {PROMPTS}")


def generer(choix: set[str]) -> None:
	for vague in (1, 2, 3, 4):
		images = [i for i in _images() if i["vague"] == vague and (
			not choix or i["groupe"] in choix or i["nom"] in choix)]
		prets = [i for i in images if all((RACINE / j if "/" in j else ART / j).exists() for j in i["jointes"])]
		for i in images:
			if i not in prets:
				print(f"{i['nom']} : en attente (jointes absentes)", flush=True)
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(daf3._generer, prets):
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
	anciens = (daf3.DECALS, daf3.EXACTS)
	daf3.DECALS, daf3.EXACTS = DECALS, EXACTS
	for ident, (ids, cases, dossier) in PLANCHE_IDS.items():
		if not (ART / daf3._source(ident)).exists():
			print(f"{ident} : absente")
			continue
		for asset, element in daf3._decouper(daf3._source(ident), ids, cases):
			cible = dossier or (_P if asset.startswith("prop_") else (_R if asset.startswith("relief_") else _I))
			p._objet(asset, f"{cible}{asset}.png", element, False, 0.0 if cible == _R else 0.12)
			print(f"{asset} : {element.size}")
	daf3.DECALS, daf3.EXACTS = anciens
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")
	preparer.reglages_import(p.m)


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
