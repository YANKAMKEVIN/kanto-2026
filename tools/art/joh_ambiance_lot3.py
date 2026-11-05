#!/usr/bin/env python3
"""Ambiance du Chapitre Johto, lot 3 (JOH6, JOH8, JOH9 ; suite de `joh_ambiance_lot2.py`). Sols,
façades et objets propres à ces zones que le kit peint n'a pas, peints par Codex : même méthode
(gabarit = un objet VALIDÉ du kit, contenu = recadrage de la vue générale validée).
Prompts : `prompts/joh_ambiance_lot3/`.
Usage : tools/art/joh_ambiance_lot3.py --refs           (recadrages `build/art/REF_*`)
        tools/art/joh_ambiance_lot3.py [--tour N] [IDENTIFIANT ...]
        tools/art/joh_ambiance_lot3.py --preparer   (images retenues → assets/, catalogue ; puis
        `godot --headless --path . --import` et `tools/build_painted_props.gd -- --nouveaux`)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from joh_ambiance import batiment  # noqa: E402
from joh_ambiance_lot2 import objet  # noqa: E402
from serie06 import ADN, LUMIERE_NE, TEXTURE_FIN  # noqa: E402 (ADN : prompts)

RACINE = Path(__file__).resolve().parents[2]
BAT = RACINE / "assets/world/buildings"
PROPS = RACINE / "assets/world/props"
RELIEF = RACINE / "assets/world/relief"
INT = RACINE / "assets/world/interiors"
GROUND = RACINE / "assets/world/ground"
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "joh_ambiance_lot3"

# Recadrages des vues générales : identifiant → (image, rectangle en fractions de l'image).
REFS = {
	"REF_ACAJOU_BOUTIQUE": ("acajou-vue-generale-v1.png", (0.56, 0.20, 0.82, 0.52)),
	"REF_R42_PORTE": ("route-42-vue-generale-v1.png", (0.17, 0.26, 0.34, 0.45)),
	"REF_CENDREE_SOL": ("tour-cendree-1f-vue-generale-v1.png", (0.20, 0.60, 0.45, 0.85)),
	"REF_CENDREE_POUTRE": ("tour-cendree-1f-vue-generale-v1.png", (0.15, 0.25, 0.40, 0.36)),
	"REF_CENDREE_COLONNE": ("tour-cendree-b1f-vue-generale-v1.png", (0.30, 0.30, 0.42, 0.42)),
	"REF_REPAIRE_STATUE": ("repaire-acajou-b1f-vue-generale-v1.png", (0.24, 0.07, 0.33, 0.22)),
	"REF_REPAIRE_GENERATEUR": ("repaire-acajou-b3f-vue-generale-v1.png", (0.50, 0.15, 0.88, 0.45)),
	"REF_REPAIRE_CAGE": ("repaire-acajou-b3f-vue-generale-v1.png", (0.56, 0.45, 0.80, 0.70)),
	"REF_REPAIRE_CELLULE": ("repaire-acajou-b2f-vue-generale-v1.png", (0.08, 0.75, 0.52, 0.98)),
	"REF_SOUVENIRS_RAYON": ("boutique-souvenirs-acajou-v1.png", (0.26, 0.28, 0.72, 0.52)),
	"REF_SOUVENIRS_PRESENTOIR": ("boutique-souvenirs-acajou-v1.png", (0.14, 0.62, 0.32, 0.86)),
	"REF_BOIS_TOUR": ("bois-de-la-tour-vue-generale-v1.png", (0.30, 0.0, 0.70, 0.33)),
	"REF_BOIS_LANTERNE": ("bois-de-la-tour-vue-generale-v1.png", (0.40, 0.38, 0.60, 0.50)),
	"REF_CARILLON_AUTEL": ("tour-carillon-1f-vue-generale-v1.png", (0.30, 0.0, 0.72, 0.16)),
	"REF_CARILLON_COLONNE": ("tour-carillon-1f-vue-generale-v1.png", (0.20, 0.20, 0.34, 0.36)),
	"REF_CARILLON_ENCENS": ("tour-carillon-1f-vue-generale-v1.png", (0.08, 0.86, 0.22, 1.0)),
	"REF_CARILLON_PLANCHES": ("tour-carillon-2f-vue-generale-v1.png", (0.28, 0.20, 0.72, 0.34)),
	"REF_SOMMET_CLOCHE": ("tour-carillon-sommet-vue-generale-v1.png", (0.34, 0.0, 0.66, 0.30)),
	"REF_SOMMET_BRULE_PARFUM": ("tour-carillon-sommet-vue-generale-v1.png", (0.72, 0.02, 0.84, 0.20)),
	"REF_SOMMET_RAMBARDE": ("tour-carillon-sommet-vue-generale-v1.png", (0.16, 0.88, 0.50, 1.0)),
	"REF_SOMMET_VUE": ("tour-carillon-sommet-vue-generale-v1.png", (0.0, 0.0, 0.16, 1.0)),
	"REF_SENTIER_CENTRE": ("sentier-mont-argente-vue-generale-v1.png", (0.13, 0.11, 0.46, 0.31)),
	"REF_SENTIER_NEIGE": ("sentier-mont-argente-vue-generale-v1.png", (0.56, 0.05, 0.84, 0.18)),
	"REF_SENTIER_GLACE": ("sentier-mont-argente-vue-generale-v1.png", (0.10, 0.56, 0.46, 0.62)),
	"REF_SENTIER_SAPIN": ("sentier-mont-argente-vue-generale-v1.png", (0.56, 0.04, 0.74, 0.16)),
	"REF_EXT_ENTREE": ("mont-argente-exterieur-vue-generale-v1.png", (0.36, 0.0, 0.66, 0.40)),
	"REF_SOMMET_RUINE": ("mont-argente-sommet-vue-generale-v1.png", (0.22, 0.20, 0.44, 0.34)),
	"REF_SOMMET_NUAGES": ("mont-argente-sommet-vue-generale-v1.png", (0.0, 0.0, 0.08, 1.0)),
}


def texture(ref: str, description: str) -> str:
	return f"""IMAGE 1 : {ref}, extrait d'une vue générale VALIDÉE : couleur et esprit du sol ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}
{TEXTURE_FIN}"""


def meuble(gabarit: Path, contenu: str, description: str) -> tuple[str, list[Path]]:
	return (objet(gabarit.stem, contenu, description), [gabarit, ART / f"{contenu}.png"])


ASSETS = {
	# Sols.
	"GROUND_NEIGE": (texture("REF_SENTIER_NEIGE",
		"une neige fraîche et tassée, blanc légèrement bleuté dans les creux, à gros grains doux, "
		"quelques ondulations à peine marquées de vent, sans traces ; lumineuse mais pas brûlée : on "
		"doit encore lire le relief."), [ART / "REF_SENTIER_NEIGE.png"]),
	"GROUND_CENDRES": (texture("REF_CENDREE_SOL",
		"un sol de cendres grises et de suie sur du dallage noirci : poussière gris moyen, nappes plus "
		"claires, fines fissures, petits débris de charbon épars ; aucune tache marquante, valeur "
		"moyenne pour que les personnages s'y lisent."), [ART / "REF_CENDREE_SOL.png"]),
	"GROUND_PLANCHES_CEDENT": (texture("REF_CARILLON_PLANCHES",
		"de vieilles planches de bois sombre, usées, fendues, disjointes, posées est-ouest, plus "
		"sombres et plus abîmées qu'un parquet ordinaire : on sent qu'elles vont céder sous le pied."),
		[ART / "REF_CARILLON_PLANCHES.png"]),
	# Façades.
	"BLDG_BOUTIQUE_ACAJOU": (batiment("bldg_maison_argenta_01", "REF_ACAJOU_BOUTIQUE", 8, 7,
		"la BOUTIQUE DE SOUVENIRS d'Acajou : maison de montagne à colombages, murs crème, poutres "
		"brunes, large toit de tuiles rouge orangé à deux pans ; sur le faîtage, une ANTENNE métallique "
		"grise bien visible ; au milieu de la façade sud, une double porte en bois de DEUX cases de large "
		"sous un petit auvent ; de chaque côté, une fenêtre et une jardinière ; une petite enseigne de "
		"bois vierge au-dessus de la porte."),
		[BAT / "bldg_maison_argenta_01.png", ART / "REF_ACAJOU_BOUTIQUE.png"]),
	"BLDG_CENTRE_NEIGE": (batiment("bldg_centre_01", "REF_SENTIER_CENTRE", 8, 7,
		"EXACTEMENT le Centre Pokémon de l'image 1 (même forme, mêmes portes vitrées, même grande "
		"Poké Ball de façade), mais en plein hiver de montagne : une épaisse couche de neige sur le toit "
		"rouge et sur l'auvent, de petites stalactites au bord du toit, un peu de neige au pied des "
		"murs."), [BAT / "bldg_centre_01.png", ART / "REF_SENTIER_CENTRE.png"]),
	"BLDG_TOUR_CARILLON_BASE": (batiment("bldg_tour_carillon_01", "REF_BOIS_TOUR", 8, 5,
		"le PIED de la TOUR CARILLON vu de près : trois niveaux de pagode japonaise en bois clair et enduit "
		"blanc, toits courbes de tuiles rouges aux coins relevés, frises et balcons de bois sombre, "
		"fenêtres à claustras ; tout en bas, à gauche du milieu, une grande double porte de bois sombre "
		"de DEUX cases de large. La tour continue au-delà du haut de l'image : le haut est coupé net "
		"par un toit, aucun ciel."), [BAT / "bldg_tour_carillon_01.png", ART / "REF_BOIS_TOUR.png"]),
	# Reliefs et décors de la montagne.
	"RELIEF_PORTE_CREUSET": meuble(RELIEF / "relief_entree_grotte_01.png", "REF_R42_PORTE",
		"l'entrée FERMÉE du Mont Creuset : une bouche de grotte dans un contrefort rocheux gris, "
		"entièrement bouchée par un éboulement de rochers ; touffes d'herbe sur le dessus. Quatre cases "
		"de large (384 px en jeu)."),
	"RELIEF_MURAILLE_GLACE": meuble(RELIEF / "relief_paroi_glace_01.png", "REF_SENTIER_GLACE",
		"un module de MURAILLE DE GLACE : un muret bas de blocs de glace bleu clair translucide, "
		"cristaux à arêtes vives, un peu de neige sur le dessus. Quatre cases de large (384 px en jeu), "
		"une case et demie de haut ; les bords gauche et droit se raccordent à eux-mêmes."),
	"RELIEF_ENTREE_NEIGE": meuble(RELIEF / "relief_entree_grotte_01.png", "REF_EXT_ENTREE",
		"l'entrée de la grotte du Mont Argenté : une haute bouche noire dans une paroi de roche gris "
		"bleuté, couverte de neige sur les rebords, en haut d'un escalier de neige taillé dans la "
		"pente. Quatre cases de large (384 px en jeu)."),
	"PROP_RUINE_SOMMET": meuble(PROPS / "prop_rocher_01.png", "REF_SOMMET_RUINE",
		"une PIERRE DE RUINE du sommet : un bloc taillé très ancien, érodé, gris bleuté, à demi enfoui, "
		"coiffé de neige. Une case de large (96 px en jeu)."),
	"TREE_SAPIN_NEIGE": meuble(PROPS / "tree_foret_05.png", "REF_SENTIER_SAPIN",
		"EXACTEMENT le sapin de l'image 1 (même forme, même rendu), les branches chargées de neige "
		"fraîche : de larges paquets blancs sur chaque étage de branches, le vert sombre visible "
		"dessous, tronc sombre."),
	"TREE_FEUILLU_NEIGE": meuble(PROPS / "tree_foret_01.png", "REF_SENTIER_SAPIN",
		"EXACTEMENT l'arbre de l'image 1 (même forme, même rendu), la cime couverte d'une neige "
		"fraîche sur le dessus de chaque touffe, feuillage vert sombre et froid dessous, tronc sombre."),
	# Tour Cendrée.
	"PROP_POUTRE_CALCINEE_H": meuble(PROPS / "prop_tronc_couche_01.png", "REF_CENDREE_POUTRE",
		"une longue POUTRE CALCINÉE couchée au sol, est-ouest : bois carbonisé noir et gris, écailles de "
		"charbon, bouts cassés, quelques éclats de braise éteinte. Cinq cases de long (480 px en jeu), "
		"une case de large."),
	"PROP_POUTRE_CALCINEE_V": meuble(PROPS / "prop_tronc_incline_01.png", "REF_CENDREE_POUTRE",
		"une longue POUTRE CALCINÉE couchée au sol, nord-sud (vue dans le sens de la longueur, bout "
		"cassé en bas) : bois carbonisé noir et gris, écailles de charbon. Une case de large (96 px en "
		"jeu), cinq cases de long : image verticale."),
	"PROP_COLONNE_CALCINEE": meuble(PROPS / "prop_colonne_grotte_01.png", "REF_CENDREE_COLONNE",
		"un tronçon de COLONNE CALCINÉE : pilier de bois carré noirci, cassé à hauteur d'homme, sur un "
		"socle de pierre noircie. Une case de large (96 px en jeu)."),
	# Repaire d'Acajou.
	"INT_STATUE_PERSIAN": meuble(INT / "int_statue_manoir_01.png", "REF_REPAIRE_STATUE",
		"une STATUE de félin assis, patiné bronze doré, dans le style de l'image 2 : petit socle gris, "
		"silhouette de chat élégant à large tête, grand bijou rond sur le front, yeux rouges "
		"éteints. Une case de large (96 px en jeu), une case et demie de haut."),
	"INT_GENERATEUR_ONDES": meuble(INT / "int_generateur_centrale_01.png", "REF_REPAIRE_GENERATEUR",
		"le GÉNÉRATEUR D'ONDES du repaire : grosse machine sombre de tôle anthracite, trois bobines "
		"cuivrées sur le dessus, tuyaux, cadrans, panneau central à lumière bleu violet. Six cases de "
		"large (576 px en jeu), quatre cases de haut."),
	"INT_CAGE_ONDES": meuble(INT / "int_herse_fermee_01.png", "REF_REPAIRE_CAGE",
		"la CAGE À ONDES : portique métallique ouvert vers le sud, deux montants gris et un linteau, "
		"entre lesquels descendent des barreaux d'énergie violet lumineux ; câbles qui montent vers le "
		"haut. Trois cases de large (288 px en jeu), trois cases de haut."),
	"INT_RAYON_SOUVENIRS": meuble(INT / "int_boutique_rayon_mural.png", "REF_SOUVENIRS_RAYON",
		"un RAYON MURAL de boutique de souvenirs : meuble bas de bois chaud à trois étagères : mugs, "
		"boules à neige, petites peluches rondes et cartes postales sans inscription. Deux cases de "
		"large (192 px en jeu)."),
	"INT_PRESENTOIR_SOUVENIRS": meuble(INT / "int_boutique_presentoir.png", "REF_SOUVENIRS_PRESENTOIR",
		"un PRÉSENTOIR de boutique de souvenirs : petit meuble de bois sur lequel sont posés des boules "
		"à neige, des mugs et des cartes postales sans inscription. Deux cases de large (192 px en jeu)."),
	# Tour Carillon.
	"PROP_LANTERNE_PIERRE": meuble(PROPS / "prop_stele_01.png", "REF_BOIS_LANTERNE",
		"une LANTERNE DE PIERRE japonaise : pied de pierre grise, petite chambre à ouvertures carrées, "
		"chapeau de pierre aux coins relevés. Une case de large (96 px en jeu), une case et demie de "
		"haut."),
	"INT_COLONNE_ROUGE": meuble(INT / "int_colonne_glace_01.png", "REF_CARILLON_COLONNE",
		"une COLONNE de temple : fût laqué rouge sombre, chapiteau et socle de bois brun cerclés de "
		"laiton. Une case de large (96 px en jeu), deux cases de haut."),
	"INT_AUTEL_CARILLON": meuble(INT / "int_comptoir_tour_01.png", "REF_CARILLON_AUTEL",
		"l'AUTEL de la Tour Carillon : long meuble bas de bois sombre, nappe rouge, une coupe blanche "
		"au milieu, deux brûle-parfums de bronze, deux vases de fleurs blanches aux extrémités. Six "
		"cases de large (576 px en jeu), deux cases de profondeur."),
	"INT_BRULE_PARFUM": meuble(INT / "int_brasero_ligue_01.png", "REF_SOMMET_BRULE_PARFUM",
		"un grand BRÛLE-PARFUM de bronze patiné, à couvercle ajouré, sur un socle de pierre grise. Une "
		"case de large (96 px en jeu), une case et demie de haut."),
	"INT_RAMBARDE_ROUGE_H": meuble(INT / "int_comptoir_tour_01.png", "REF_SOMMET_RAMBARDE",
		"un module de RAMBARDE de temple, est-ouest : balustrade de bois laqué rouge à deux lisses et "
		"petits poteaux, ferrures de laiton. Quatre cases de large (384 px en jeu), une case de haut ; "
		"les bords gauche et droit se raccordent à eux-mêmes."),
	"INT_RAMBARDE_ROUGE_V": meuble(INT / "int_colonne_glace_01.png", "REF_SOMMET_RAMBARDE",
		"un module de RAMBARDE de temple, nord-sud (vue de dessus de trois quarts, on voit sa tranche "
		"étroite) : lisse de bois laqué rouge, petits poteaux, ferrures de laiton. Une demi-case de "
		"large (48 px en jeu), quatre cases de long : image verticale, le haut et le bas se raccordent "
		"à eux-mêmes."),
	"INT_GRANDE_CLOCHE": meuble(INT / "int_colonne_champion_01.png", "REF_SOMMET_CLOCHE",
		"la GRANDE CLOCHE de la Tour Carillon : une énorme cloche de bronze japonaise patinée, suspendue "
		"à un portique de deux colonnes laquées rouges sur socles de pierre, poutre transversale "
		"rouge et or. Quatre cases de large (384 px en jeu), quatre cases et demie de haut."),
	# Fonds.
	"BACKDROP_VUE_CARILLON": ("""IMAGE 1 : REF_SOMMET_VUE, extrait de la vue générale VALIDÉE du sommet de la Tour Carillon.

À FAIRE : le paysage vu depuis le sommet : à perte de vue des collines bleues embrumées et une forêt d'érables rouges et roses dans la brume au crépuscule, ciel rose et bleu en haut ; une vue large, reposante, très peu de contraste. Aucune tour au premier plan, aucune balustrade.
Format : PNG paysage 1536 × 1024, OPAQUE, aucun bord ; pas de texte, pas de personnage.""",
		[ART / "REF_SOMMET_VUE.png"]),
	"BACKDROP_MER_NUAGES": ("""IMAGE 1 : REF_SOMMET_NUAGES, extrait de la vue générale VALIDÉE du sommet du Mont Argenté.

À FAIRE : une mer de nuages blancs et bleu pâle vue de très haut, en plein soleil, à perte de vue, gros cumulus doux ; une image reposante et lumineuse. Rien d'autre : ni sommet, ni oiseau.
Format : PNG paysage 1536 × 1024, OPAQUE, aucun bord ; pas de texte.""",
		[ART / "REF_SOMMET_NUAGES.png"]),
}


def generer(ident: str, tour: int) -> str:
	texte, jointes = ASSETS[ident]
	nom = f"{ident}_r{tour}"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(f"{nom} — asset de jeu de Kanto 2026 (Chapitre Johto).\n\n{ADN}\n{LUMIERE_NE}\n\n{texte}\n")
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier),
		*[str(j) for j in jointes]], cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


def recadrer_references() -> None:
	from PIL import Image
	ART.mkdir(parents=True, exist_ok=True)
	for ident, (image, f) in REFS.items():
		im = Image.open(REFERENCE / image).convert("RGB")
		w, h = im.size
		im.crop((int(f[0] * w), int(f[1] * h), int(f[2] * w), int(f[3] * h))).save(ART / f"{ident}.png")
		print(ident)


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--refs"]:
		recadrer_references()
		sys.exit(0)
	tour = 1
	if args[:1] == ["--tour"]:
		tour, args = int(args[1]), args[2:]
	PROMPTS.mkdir(parents=True, exist_ok=True)
	choix = [a for a in ASSETS if not args or a in args]
	with ThreadPoolExecutor(max_workers=4) as pool:
		for ligne in pool.map(lambda i: generer(i, tour), choix):
			print(ligne, flush=True)
