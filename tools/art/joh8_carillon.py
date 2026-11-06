#!/usr/bin/env python3
"""Peinture du JOH8 (Bois de la Tour, Tour Carillon, sommet) : ce que le lot 3 d'ambiance
(`joh_ambiance_lot3.py`, qui garde façade, lanternes, colonnes, autel, cloche, rambardes et fond)
n'a pas, peint par Codex : même méthode (gabarit = un objet VALIDÉ du kit, contenu = recadrage de la
vue générale validée). Prompts : `prompts/joh8_carillon/`.
Usage : tools/art/joh8_carillon.py --refs           (recadrages `build/art/REF_*`)
        tools/art/joh8_carillon.py [--tour N] [IDENTIFIANT ...]
        tools/art/joh8_carillon.py --tuiles NOM     (tuiles du décor de combat NOM, ex. COMBAT_DECOR_CARILLON_r1)
        tools/art/joh8_carillon.py --preparer   (images retenues → assets/, catalogue ; puis
        `godot --headless --path . --import` et `tools/build_painted_props.gd -- --nouveaux`)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from joh_ambiance_lot2 import objet  # noqa: E402
from serie06 import ADN, LUMIERE_NE, TEXTURE_FIN  # noqa: E402 (ADN : prompts)

RACINE = Path(__file__).resolve().parents[2]
BAT = RACINE / "assets/world/buildings"
PROPS = RACINE / "assets/world/props"
RELIEF = RACINE / "assets/world/relief"
INT = RACINE / "assets/world/interiors"
GROUND = RACINE / "assets/world/ground"
BACKDROPS = RACINE / "assets/world/backdrops"
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "joh8_carillon"
PROMPTS_DECOR = Path(__file__).parent / "combat_decors" / "prompts"

HALL = "tour-carillon-1f-vue-generale-v1.png"
ETAGE = "tour-carillon-2f-vue-generale-v1.png"
SOMMET = "tour-carillon-sommet-vue-generale-v1.png"
# Recadrages des vues générales : identifiant → (image, rectangle en fractions de l'image).
REFS = {
	"REF_J8_SOL": (HALL, (0.33, 0.35, 0.60, 0.62)),
	"REF_J8_MUR": (HALL, (0.24, 0.0, 0.40, 0.13)),
	"REF_J8_COTE": (HALL, (0.20, 0.25, 0.27, 0.55)),
	"REF_J8_PORTE": (HALL, (0.44, 0.86, 0.64, 1.0)),
	"REF_J8_ESCALIER": (HALL, (0.69, 0.0, 0.81, 0.18)),
	"REF_J8_DALLES": (SOMMET, (0.30, 0.58, 0.72, 0.90)),
	"REF_J8_CAGE": (SOMMET, (0.50, 0.28, 0.64, 0.56)),
	"REF_J8_PALIER": (SOMMET, (0.18, 0.0, 0.36, 0.24)),
	"REF_J8_ERABLE": ("bois-de-la-tour-vue-generale-v1.png", (0.20, 0.13, 0.33, 0.30)),
}


def texture(ref: str, description: str) -> str:
	return f"""IMAGE 1 : {ref}, extrait d'une vue générale VALIDÉE : couleur et esprit du sol ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}
{TEXTURE_FIN}"""


def meuble(gabarit: Path, contenu: str, description: str) -> tuple[str, list[Path]]:
	return (objet(gabarit.stem, contenu, description), [gabarit, ART / f"{contenu}.png"])


ASSETS = {
	"TREE_ERABLE_BOIS": meuble(PROPS / "tree_automne_01.png", "REF_J8_ERABLE",
		"un ÉRABLE du Bois de la Tour : tronc brun court et noueux, ramure ronde et dense de feuillage "
		"vert franc, parsemée de grosses grappes de feuilles rouge vif. Deux cases et demie de large "
		"(240 px en jeu)."),
	"GROUND_PLANCHER_CARILLON": (texture("REF_J8_SOL",
		"un parquet de temple ancien : longues planches de bois clair couleur miel, posées est-ouest, "
		"joints fins, légèrement cirées et usées par les pas ; valeur moyenne, sans tache marquante, "
		"pour que les personnages s'y lisent."), [ART / "REF_J8_SOL.png"]),
	"GROUND_DALLES_SOMMET": (texture("REF_J8_DALLES",
		"un dallage de toit-terrasse : pierres rectangulaires gris chaud posées en appareil décalé, de "
		"tailles variées, joints sombres fins, surface usée par le vent ; valeur moyenne, sans tache "
		"marquante."), [ART / "REF_J8_DALLES.png"]),
	"RELIEF_MUR_CARILLON_FACE": meuble(RELIEF / "relief_mur_souterrain_01.png", "REF_J8_MUR",
		"un module de MUR de temple japonais vu de face, est-ouest : en haut une bande de fenêtres de "
		"papier blanc à croisillons de bois sombre, en bas un lambris de bois brun foncé, un poteau de "
		"bois à chaque bord. Deux cases de large, une case de haut : image rectangulaire pleine, OPAQUE "
		"jusqu'aux bords, les bords gauche et droit se raccordent à eux-mêmes."),
	"RELIEF_MUR_CARILLON_CAP": meuble(RELIEF / "relief_mur_souterrain_03.png", "REF_J8_COTE",
		"le COURONNEMENT d'un mur de temple vu de dessus, est-ouest : longue poutre de bois brun foncé. "
		"Image rectangulaire pleine, très allongée (six fois plus large que haute), OPAQUE jusqu'aux "
		"bords, les bords gauche et droit se raccordent à eux-mêmes."),
	"RELIEF_MUR_CARILLON_COTE": meuble(RELIEF / "relief_mur_souterrain_04.png", "REF_J8_COTE",
		"le BORD LATÉRAL d'un mur de temple vu de dessus, nord-sud : poutre étroite de bois brun foncé. "
		"Image rectangulaire pleine, verticale (quatre fois plus haute que large), OPAQUE jusqu'aux "
		"bords, le haut et le bas se raccordent à eux-mêmes."),
	"RELIEF_ESCALIER_CARILLON": meuble(RELIEF / "relief_escalier_tour_01.png", "REF_J8_ESCALIER",
		"un ESCALIER de bois pris dans un mur de temple : marches de bois brun qui montent vers le nord "
		"dans une ouverture sombre, joues de bois foncé à gauche et à droite. Une case de large (96 px "
		"en jeu), une case et demie de haut."),
	"INT_PORTE_CARILLON": meuble(RELIEF / "relief_escalier_tour_01.png", "REF_J8_PORTE",
		"la GRANDE PORTE de la Tour Carillon vue de l'intérieur : deux lourds battants de bois sombre "
		"ouverts vers l'intérieur de part et d'autre d'un seuil clair, anneaux de bronze. Deux cases de "
		"large pour le seuil (192 px en jeu), trois cases en tout avec les battants, une case de haut."),
	"PROP_CAGE_FEU": meuble(PROPS / "prop_stele_01.png", "REF_J8_CAGE",
		"la CAGE DE FEU de Dante, en forme de U ouvert vers le sud : barreaux de fer noir dressés, reliés "
		"par une traverse, sur trois côtés (nord, ouest, est), le côté sud reste entièrement ouvert et "
		"vide ; des flammes orange et jaunes courent le long des barreaux et s'élèvent au-dessus de la "
		"traverse. Trois cases de large (288 px en jeu), trois cases et demie de haut. Aucun Pokémon "
		"dedans, aucune lueur au sol."),
	"INT_CLOISON_PALIER": meuble(INT / "int_comptoir_tour_01.png", "REF_J8_PALIER",
		"un module de CLOISON basse du palier : cadre de bois laqué rouge et panneau de papier blanc "
		"crème. Deux cases de large (192 px en jeu), une case de haut ; les bords gauche et droit se "
		"raccordent à eux-mêmes."),
}
DECOR = """DÉCOR DE COMBAT — SOMMET DE LA TOUR CARILLON, À L'AUBE (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat Pokémon sur smartphone en paysage. AUCUN Pokémon, AUCUN personnage, AUCUNE interface, AUCUN texte.

Images jointes.
IMAGE 1 : un écran de combat de référence. Reprends sa VUE (caméra à hauteur d'yeux, légèrement plongeante, horizon dans le tiers haut, grand sol dégagé au centre), sa profondeur et sa qualité de peinture. Ne reprends PAS : les Pokémon, les cartes, les boutons, la rivière, le pont, le coucher de soleil orange.
IMAGE 2 : une planche d'intention de décors de combat (guide de facture).
IMAGE 3 : la vue générale (de dessus) du sommet de la Tour Carillon : dalles de pierre gris chaud, rambarde laquée rouge, grande cloche de bronze sous un portique rouge, collines bleues et érables rouges dans la brume (guide de palette).

FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution possible, OPAQUE, cadrage plein, sans bord.

LIEU : le toit-terrasse d'une tour sacrée, tout en haut, juste avant le lever du soleil. Sol de dalles de pierre gris chaud ; au fond, une rambarde de bois laqué rouge court d'un bord à l'autre ; derrière elle le vide, des collines bleues embrumées et des érables rouges très loin en contrebas, sous un ciel rose et bleu pâle. À DROITE, le pied du portique rouge et la grande cloche de bronze, coupée par le bord de l'image.

COMPOSITION (fractions depuis le coin haut gauche) :
- Horizon vers 33 % de la hauteur ; la rambarde entre 36 et 46 % de la hauteur. La cloche et son portique à droite (x 72 à 100 %), entre 0 et 46 % de la hauteur.
- De 48 % de la hauteur jusqu'en bas : GRAND SOL DÉGAGÉ et PLAT de dalles.
- Point A (x 67 %, y 56 %) : sol nu, plat et bien lisible, une créature y posera les pieds. Rien de haut dans un rayon de 12 % de la largeur autour.
- Point B (x 31 %, y 97 %) : sol plat et nu, une grande créature vue de dos y sera au premier plan. Rien de haut autour.
- ZONE CALME en HAUT À GAUCHE (de 0 à 50 % de la largeur, de 0 à 45 % de la hauteur) : peu de détails et peu de contraste, valeurs simples.
- ZONE CALME en BAS À DROITE (de 50 à 100 % de la largeur, de 55 à 100 % de la hauteur) : sol simple, presque sans objet, valeurs moyennes, sans contraste fort.
- Les deux coins du bas restent du SOL nu.
- Les 9 % de gauche et de droite de l'image ne contiennent rien d'important (ils seront rognés sur certains écrans).

LUMIÈRE : aube douce, rose et dorée, soleil pas encore visible à gauche hors cadre ; ombres longues bleu-violet très légères.

RENDU (ADN visuel Kanto 2026) : illustration 2D peinte numériquement, RPG Pokémon moderne « HD-2D peint », formes simples, lisibles et arrondies, grandes masses douces (jamais en petits points ni en pixels), aucun trait noir (contours fins et doux plus sombres que la couleur), couleurs riches sans être fluo. Netteté partout (aucun flou de profondeur, pas de vignettage). Perspective à hauteur d'yeux, un peu plongeante, le sol recule nettement vers l'horizon.

INTERDITS : Pokémon, animal, oiseau, personnage, silhouette, texte, lettres, chiffres, panneau lisible, logo, signature, filigrane, cadre, interface, véhicule, pixel art, flou, vignettage, flammes, cage."""
TUILE = (Path(__file__).parent / "combat_decors" / "prompts" / "COMBAT_DECOR_TUILE_r1.txt")


def lancer(nom: str, fichier: Path, jointes: list[Path]) -> str:
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier),
		*[str(j) for j in jointes]], cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


def generer(ident: str, tour: int) -> str:
	nom = f"{ident}_r{tour}"
	if ident == "COMBAT_DECOR_CARILLON":
		fichier = PROMPTS_DECOR / f"{nom}.txt"
		fichier.write_text(DECOR + "\n")
		return lancer(nom, fichier, [REFERENCE / "combat-v1.webp",
			REFERENCE / "combat-decors-planche-v1.webp", REFERENCE / SOMMET])
	texte, jointes = ASSETS[ident]
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(f"{nom} — asset de jeu de Kanto 2026 (Chapitre Johto).\n\n{ADN}\n{LUMIERE_NE}\n\n{texte}\n")
	return lancer(nom, fichier, jointes)


def tuiles(nom: str) -> None:
	"""Moitiés de la composition [nom], repeintes en plus grand (`preparer_decor.py`)."""
	from PIL import Image
	image = Image.open(ART / f"{nom}.png").convert("RGB")
	w, h = image.size
	largeur = int(w * 0.5417)
	portions = {"TL": (0, 0, largeur, h), "TR": (w - largeur, 0, w, h)}
	print(portions)

	def une(cote: str) -> str:
		source = ART / f"{nom}_{cote}_src.png"
		image.crop(portions[cote]).save(source)
		return lancer(f"{nom}_{cote}", TUILE, [source])

	with ThreadPoolExecutor(max_workers=2) as pool:
		for ligne in pool.map(une, portions):
			print(ligne, flush=True)


def recadrer_references() -> None:
	from PIL import Image
	ART.mkdir(parents=True, exist_ok=True)
	for ident, (image, f) in REFS.items():
		im = Image.open(REFERENCE / image).convert("RGB")
		w, h = im.size
		im.crop((int(f[0] * w), int(f[1] * h), int(f[2] * w), int(f[3] * h))).save(ART / f"{ident}.png")
		print(ident)


# Objets du catalogue : identifiant du jeu → (image retenue, dossier, largeur en cases, ombre, contact).
RETENUS = {
	"bldg_tour_carillon_base_01": ("BLDG_TOUR_CARILLON_BASE_r1.png", BAT, 9.7, False, 0.12),
	"tree_erable_bois_01": ("TREE_ERABLE_BOIS_r1.png", PROPS, 2.5, False, 0.1),
	"prop_lanterne_pierre_01": ("PROP_LANTERNE_PIERRE_r1.png", PROPS, 0.8, False, 0.1),
	"int_colonne_rouge_01": ("INT_COLONNE_ROUGE_r1.png", INT, 1, False, 0.1),
	"int_autel_carillon_01": ("INT_AUTEL_CARILLON_r1.png", INT, 6, False, 0.1),
	"int_brule_parfum_01": ("INT_BRULE_PARFUM_r1.png", INT, 1, False, 0.1),
	"int_grande_cloche_01": ("INT_GRANDE_CLOCHE_r1.png", INT, 4, False, 0.1),
}
# Images posées telles quelles par les outils de carte : identifiant → (image, dossier, largeur, hauteur).
SPRITES = {
	"prop_cage_feu_01": ("PROP_CAGE_FEU_r1.png", PROPS, 288, 0),
	"relief_escalier_carillon_01": ("RELIEF_ESCALIER_CARILLON_r1.png", RELIEF, 160, 144),
	"int_porte_carillon_01": ("INT_PORTE_CARILLON_r1.png", INT, 288, 0),
	"int_rambarde_rouge_h_01": ("INT_RAMBARDE_ROUGE_H_r1.png", INT, 384, 96),
	"int_rambarde_rouge_v_01": ("INT_RAMBARDE_ROUGE_V_r1.png", INT, 48, 384),
	"int_cloison_palier_01": ("INT_CLOISON_PALIER_r1.png", INT, 192, 96),
}
SOLS = {"ground_plancher_carillon_01": "GROUND_PLANCHER_CARILLON_r1.png",
	"ground_dalles_sommet_01": "GROUND_DALLES_SOMMET_r1.png",
	"ground_planches_cedent_01": "GROUND_PLANCHES_CEDENT_r1.png"}
# Modules de mur, aux tailles de `relief_mur_souterrain_*` (`tools/module_walls.gd`).
FACE_TAILLE = (192, 120)
CHAPEAU_TAILLE = (192, 33)
COTE_TAILLE = (34, 146)
MASSE_VALEUR = 0.42
# Lueur de la cage, posée sous elle (additive) : rayon en pixels.
LUEUR_TAILLE = 448


def _rogner(image, marge: float = 0.0):
	"""Silhouette de [image], moins [marge] (fraction) de chaque côté : garde le plein des modules."""
	boite = image.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()
	image = image.crop(boite)
	dx, dy = int(image.width * marge), int(image.height * marge)
	return image.crop((dx, dy, image.width - dx, image.height - dy))


def preparer_retenus() -> None:
	"""Images retenues → `assets/` et catalogue existant complété."""
	import json
	import numpy as np
	import preparer
	from PIL import Image, ImageChops
	for ident, source in SOLS.items():
		Image.open(ART / source).convert("RGB").resize((384, 384), Image.LANCZOS).save(
			GROUND / f"{ident}.png")
	for ident, (source, dossier, largeur, hauteur) in SPRITES.items():
		image = Image.open(ART / source).convert("RGBA")
		image = image.crop(image.getchannel("A").point(lambda a: 255 if a > 128 else 0).getbbox())
		if hauteur == 0:
			hauteur = round(image.height * largeur / image.width)
		image.resize((largeur, hauteur), Image.LANCZOS).save(dossier / f"{ident}.png")
	# Masse des murs : le bois du mur, très assombri [D].
	bois = Image.open(ART / "RELIEF_MUR_CARILLON_COTE_r1.png").convert("RGB")
	bois = bois.crop((0, 0, bois.width, bois.width)).resize((384, 384), Image.LANCZOS)
	bois.point(lambda v: int(v * MASSE_VALEUR)).save(GROUND / "ground_masse_carillon_01.png")
	BACKDROPS.mkdir(parents=True, exist_ok=True)
	Image.open(ART / "BACKDROP_VUE_CARILLON_r1.png").convert("RGB").save(
		BACKDROPS / "backdrop_vue_carillon_01.png")
	centre = (LUEUR_TAILLE - 1) / 2.0
	ys, xs = np.mgrid[0:LUEUR_TAILLE, 0:LUEUR_TAILLE]
	distance = np.clip(np.hypot(xs - centre, ys - centre) / centre, 0.0, 1.0)
	lueur = np.zeros((LUEUR_TAILLE, LUEUR_TAILLE, 4), dtype=np.uint8)
	lueur[..., 0], lueur[..., 1], lueur[..., 2] = 255, 128, 40
	lueur[..., 3] = (255 * (1.0 - distance) ** 2).astype(np.uint8)
	Image.fromarray(lueur).save(PROPS / "prop_lueur_cage_01.png")
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	for ident, (source, dossier, cases, ombre, contact) in RETENUS.items():
		image = preparer._silhouette(Image.open(ART / source).convert("RGBA"))
		image = preparer._mettre_a_taille(image, "w", cases, p.case)
		p._objet(ident, str((dossier / f"{ident}.png").relative_to(RACINE)), image, ombre, contact)
	face = _rogner(Image.open(ART / "RELIEF_MUR_CARILLON_FACE_r1.png").convert("RGBA"), 0.01)
	face = face.resize(FACE_TAILLE, Image.LANCZOS)
	chapeau = _rogner(Image.open(ART / "RELIEF_MUR_CARILLON_CAP_r1.png").convert("RGBA"), 0.01)
	cote = _rogner(Image.open(ART / "RELIEF_MUR_CARILLON_COTE_r1.png").convert("RGBA"), 0.01)
	modules = {"relief_mur_carillon_01": face,
		"relief_mur_carillon_02": ImageChops.offset(face, FACE_TAILLE[0] // 2, 0),
		"relief_mur_carillon_03": chapeau.resize(CHAPEAU_TAILLE, Image.LANCZOS),
		"relief_mur_carillon_04": cote.resize(COTE_TAILLE, Image.LANCZOS)}
	for ident, image in modules.items():
		p._objet(ident, str((RELIEF / f"{ident}.png").relative_to(RACINE)), image, False, 0.0)
	p.ecrire_catalogue()


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--refs"]:
		recadrer_references()
		sys.exit(0)
	if args[:1] == ["--tuiles"]:
		tuiles(args[1])
		sys.exit(0)
	if args[:1] == ["--preparer"]:
		preparer_retenus()
		sys.exit(0)
	tour = 1
	if args[:1] == ["--tour"]:
		tour, args = int(args[1]), args[2:]
	PROMPTS.mkdir(parents=True, exist_ok=True)
	choix = [a for a in [*ASSETS, "COMBAT_DECOR_CARILLON"] if not args or a in args]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(lambda i: generer(i, tour), choix):
			print(ligne, flush=True)
