#!/usr/bin/env python3
"""Reliquats Codex de DAF.10d (2026-10-31) : faces de mur dédiées des salles de la Ligue et du Panthéon,
et objets de thème, peints par Codex en remplacement à l'identique des emprunts de `build_daf10d.gd`
(mêmes gabarits : faces de 2 cases de large, objets de 1 ou 2 cases au pied de la case). Fiche :
`docs/design/fiches-assets/daf-10d/fiche.md`.

  tools/art/daf10d_codex.py --prompts      écrit les prompts (tools/art/prompts/daf10d_codex/)
  tools/art/daf10d_codex.py [GROUPE ...]   génère avec Codex (tout ce qui manque sans argument)
  tools/art/daf10d_codex.py --modules      découpe les planches → assets/ (catalogue)
"""
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import daf3  # noqa: E402
from daf3 import ADN, ART, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "daf10d_codex"
_W = "assets/world/"
_G, _R, _P, _I = f"{_W}ground/", f"{_W}relief/", f"{_W}props/", f"{_W}interiors/"

LUMIERE = ("Lumière NEUTRE, diffuse et blanche venant légèrement du haut à gauche (le jeu ajoute lui-même la "
	"pénombre, le voile des murs et les lueurs colorées) : AUCUNE lueur peinte, AUCUN halo, aucune ombre portée.")
VALEURS = ("VALEURS DE LA LIGUE POKÉMON (le sanctuaire final de Kanto, au bout de la Route Victoire : cinq salles "
	"solennelles, chacune au thème de son Dresseur, majestueuses et belles, jamais effrayantes ni gores) ; "
	+ LUMIERE)
_ECHELLE = daf3._CELLULES + ", à une échelle COMMUNE de 1 case = 150 px"
_FACE = ("une FACE DE MUR vue de face (le sol est au SUD), EXACTEMENT 2 cases de large (≈ 300 px) et environ "
	"1,95 case de haut (≈ 290 px) : en haut une étroite bande du dessus du mur vue de dessus, puis la face ; bords "
	"gauche et droit COUPÉS NET en ligne droite (elle se juxtapose bout à bout en longues rangées, le motif doit "
	"se raccorder), bas droit et net")
_FOND = "Fond avec une vraie transparence (canal alpha), aucun sol autour, aucune ombre portée, aucun texte."


## Planches : (identifiant, texte, ancres).
PLANCHES = [
	("WORLD_RELIEF_MURS_LIGUE_A_PLANCHE",
		f"PLANCHE de 6 FACES DE MUR de la Ligue Pokémon, {_ECHELLE}. Ordre : ligne 1 = 1, 2, 3 ; ligne 2 = 4, 5, 6. "
		"MÊME gabarit et même manière de peindre que les modules de mur joints (relief_mur_tour_01, "
		"relief_mur_casino_01).\n"
		"1 et 2 : salle d'OLGA (type Glace) : " + _FACE + " ; 1 = GLACE SCULPTÉE : blocs de glace bleu pâle "
		"translucide taillés en pilastres réguliers, givre blanc, frise de cristaux en haut ; 2 = la même, avec une "
		"niche centrale ornée d'un flocon de glace sculpté en relief.\n"
		"3 et 4 : salle d'ALDO (type Combat) : " + _FACE + " ; 3 = TEMPLE DE PIERRE brute : gros blocs de granit "
		"brun-gris appareillés, joints épais, une corniche de pierre ; 4 = la même, avec deux colonnes trapues "
		"engagées et une plaque de pierre gravée d'un poing stylisé (sans lettre).\n"
		"5 et 6 : salle d'AGATHA (type Spectre) : " + _FACE + " ; 5 = CRYPTE : pierre violet-gris ancienne, "
		"arcades gothiques aveugles, lierre sombre, un peu de mousse ; 6 = la même, avec un vitrail rond éteint "
		"aux tons mauves au milieu (aucun crâne).\n" + _FOND,
		[f"{_R}relief_mur_tour_01.png", f"{_R}relief_mur_casino_01.png", f"{_G}ground_glace_01.png",
			f"{_G}ground_dalles_tour_01.png"]),
	("WORLD_RELIEF_MURS_LIGUE_B_PLANCHE",
		f"PLANCHE de 6 FACES DE MUR de la Ligue Pokémon, {_ECHELLE}. Ordre : ligne 1 = 1, 2, 3 ; ligne 2 = 4, 5, 6. "
		"MÊME gabarit et même manière de peindre que les modules de mur joints (relief_mur_arene_01, "
		"relief_mur_casino_01).\n"
		"1 et 2 : salle de PETER (type Dragon) : " + _FACE + " ; 1 = TEMPLE DU DRAGON : pierre rouge sombre et "
		"bronze, frise d'écailles sculptées, piliers ronds laqués ; 2 = la même, avec un grand bas-relief de "
		"dragon serpentin doré au milieu.\n"
		"3 et 4 : SALLE DU CHAMPION : " + _FACE + " ; 3 = marbre blanc veiné et or, pilastres cannelés, haute "
		"plinthe bordeaux ; 4 = la même, avec une grande tenture rouge frappée d'une Poké Ball dorée stylisée "
		"(sans lettre).\n"
		"5 et 6 : PANTHÉON (salle de la gloire) : " + _FACE + " ; 5 = boiseries sombres et dorures, panneaux "
		"moulurés, appliques éteintes ; 6 = la même, avec trois cadres dorés vides (portraits flous, sans "
		"visage reconnaissable).\n" + _FOND,
		[f"{_R}relief_mur_arene_01.png", f"{_R}relief_mur_casino_01.png", f"{_G}ground_dalles_morgane_01.png"]),
	("INT_LIGUE_PLANCHE",
		f"PLANCHE de 6 OBJETS DE THÈME de la Ligue Pokémon, {_ECHELLE}, vus de face en trois quarts (léger "
		"plongé), base droite posée sur la ligne de base. Ordre : ligne 1 = 1, 2, 3 ; ligne 2 = 4, 5, 6. Même "
		"main que les objets joints.\n"
		"1 : COLONNE DE GLACE (salle d'Olga) : un pilier de glace bleu pâle translucide taillé en facettes, "
		"chapiteau de cristaux, 1 case de large, environ 1,7 case de haut.\n"
		"2 : BRASERO DE PIERRE (salle d'Aldo) : une vasque de pierre taillée sur un pied trapu, garnie de "
		"bûches ÉTEINTES (aucune flamme), 1 case de large, environ 1,3 case de haut.\n"
		"3 : CANDÉLABRE (salle d'Agatha) : un haut chandelier de fer noir à trois branches, bougies violettes "
		"ÉTEINTES, 1 case de large, environ 1,6 case de haut.\n"
		"4 : STATUE DE DRAGON (salle de Peter) : un dragon serpentin de pierre rouge et bronze dressé sur un "
		"socle carré, ailes repliées, 1 case de large, environ 1,8 case de haut.\n"
		"5 : COLONNE D'HONNEUR (salle du Champion) : une colonne de marbre blanc cannelée, chapiteau et base "
		"dorés, une petite Poké Ball dorée au sommet, 1 case de large, environ 1,8 case de haut.\n"
		"6 : MACHINE DU PANTHÉON : la grande machine d'enregistrement de la salle de la gloire, une console "
		"incurvée de métal argenté et or avec un socle à six alvéoles pour Poké Balls et un écran ÉTEINT, "
		"EXACTEMENT 2 cases de large, environ 1,4 case de haut.\n" + _FOND,
		[f"{_P}int_statue_arene_01.png", f"{_I}int_bougeoir_tour_01.png", f"{_I}int_machines_labo_01.png"]),
]
## Assets découpés : identifiants (ordre de lecture), largeur en cases, dossier.
PLANCHE_IDS = {
	"WORLD_RELIEF_MURS_LIGUE_A_PLANCHE": (["relief_mur_ligue_glace_01", "relief_mur_ligue_glace_02",
		"relief_mur_ligue_roche_01", "relief_mur_ligue_roche_02", "relief_mur_ligue_spectre_01",
		"relief_mur_ligue_spectre_02"], [2] * 6, _R),
	"WORLD_RELIEF_MURS_LIGUE_B_PLANCHE": (["relief_mur_ligue_dragon_01", "relief_mur_ligue_dragon_02",
		"relief_mur_ligue_champion_01", "relief_mur_ligue_champion_02", "relief_mur_ligue_pantheon_01",
		"relief_mur_ligue_pantheon_02"], [2] * 6, _R),
	"INT_LIGUE_PLANCHE": (["int_colonne_glace_01", "int_brasero_ligue_01", "int_candelabre_ligue_01",
		"int_statue_dragon_01", "int_colonne_champion_01", "int_machine_pantheon_01"], [1, 1, 1, 1, 1, 2], _I),
}
## Faces : gabarit commun 192 × 186 (2 cases, hauteur des parois du Mont Sélénite).
EXACTS = {ident: (192, 186) for ident in PLANCHE_IDS["WORLD_RELIEF_MURS_LIGUE_A_PLANCHE"][0]
	+ PLANCHE_IDS["WORLD_RELIEF_MURS_LIGUE_B_PLANCHE"][0]}


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
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(daf3._generer, images):
			print(ligne, flush=True)


def preparer_modules() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	anciens = (daf3.DECALS, daf3.EXACTS)
	daf3.DECALS, daf3.EXACTS = (), EXACTS
	for ident, (ids, cases, dossier) in PLANCHE_IDS.items():
		if not (ART / daf3._source(ident)).exists():
			print(f"{ident} : absente")
			continue
		for asset, element in daf3._decouper(daf3._source(ident), ids, cases):
			p._objet(asset, f"{dossier}{asset}.png", element, False, 0.0 if dossier == _R else 0.12)
			print(f"{asset} : {element.size}")
	daf3.DECALS, daf3.EXACTS = anciens
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		ecrire_prompts()
	elif args[:1] == ["--modules"]:
		preparer_modules()
	else:
		generer(set(args))
