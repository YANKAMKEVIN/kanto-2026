#!/usr/bin/env python3
"""Peinture d'Ébènelle (arc des Pierres, JOHP3 ; suite de `joh_ambiance_lot2.py`). Façades, porche de
l'Antre, lanterne, coques et meubles des maisons du clan, peints par Codex : même méthode que les lots 1
et 2 (gabarit = un objet VALIDÉ du kit, contenu = recadrage de la vue générale validée).
Prompts : `prompts/johp3_ebenelle/`.
Usage : tools/art/johp3_ebenelle.py --refs           (recadrages `build/art/REF_*`)
        tools/art/johp3_ebenelle.py [--tour N] [IDENTIFIANT ...]
        tools/art/johp3_ebenelle.py --preparer   (images retenues → assets/, catalogue ; puis
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
from serie06 import ADN, LUMIERE_NE  # noqa: E402 (ADN : prompts)

RACINE = Path(__file__).resolve().parents[2]
BAT = RACINE / "assets/world/buildings"
PROPS = RACINE / "assets/world/props"
RELIEF = RACINE / "assets/world/relief"
INT = RACINE / "assets/world/interiors"
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "johp3_ebenelle"
VUE = "blackthorn-city-vue-generale-v1.png"

# Recadrages : identifiant → (image, rectangle en pixels).
REFS = {
	"REF_EBENELLE_MAISON": (VUE, (280, 230, 550, 450)),
	"REF_EBENELLE_AIEULE": (VUE, (540, 160, 940, 445)),
	"REF_EBENELLE_ANTRE": (VUE, (1225, 350, 1435, 520)),
}
CLAN = ("dans l'esprit de la maison du clan des dragons d'Ébènelle : bois sombre presque noir, "
	"laque rouge sombre en petites touches, ferrures de laiton patiné, sobre et ancien")


def meuble(gabarit: Path, description: str) -> tuple[str, list[Path]]:
	return (f"""IMAGE 1 : {gabarit.stem}, un meuble VALIDÉ du jeu. C'est le GABARIT : même rendu peint, même angle de vue (vue de dessus de trois quarts, face sud visible, aucun point de fuite), même lumière neutre, même finesse, même encombrement au sol et mêmes proportions à l'image.
IMAGE 2 : REF_EBENELLE_AIEULE, extrait de la vue générale VALIDÉE : matériaux et couleurs du clan, son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}, {CLAN}.
Format : PNG haute définition, l'objet seul et entier, centré, sur fond transparent, sans sol ni ombre portée, sans personnage, sans texte.
""", [gabarit, ART / "REF_EBENELLE_AIEULE.png"])


def coque(description: str) -> tuple[str, list[Path]]:
	return (f"""IMAGE 1 : int_maison_argenta_coque, une pièce VALIDÉE du jeu, vide. C'est le GABARIT DE GÉOMÉTRIE : on garde EXACTEMENT son cadrage, la place de chaque mur, de chaque pilier, des deux fenêtres, le contour du plancher, le renfoncement de la porte en bas au milieu et le paillasson, au pixel près. Même format d'image (3:2), mêmes bords noirs.
IMAGE 2 : REF_EBENELLE_AIEULE, extrait de la vue générale VALIDÉE : matériaux et couleurs des maisons du clan ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : repeindre la même pièce vide avec d'autres matériaux : {description}
Aucun meuble, aucun objet posé au sol, aucun personnage, aucun texte. Lumière neutre.
""", [INT / "int_maison_argenta_coque.png", ART / "REF_EBENELLE_AIEULE.png"])


ASSETS = {
	"BLDG_MAISON_AIEULE": (batiment("bldg_maison_rosalia_01", "REF_EBENELLE_AIEULE", 8, 6,
		"la MAISON DE L'AÏEULE d'Ébènelle : grande demeure de clan à toit de tuiles noires épaisses, à "
		"quatre pans et faîtage relevé aux angles, murs de pierre sombre et de bois brun foncé, soubassement "
		"de pierre grise ; au milieu de la façade sud, un porche à petit toit noir à pignon sur deux piliers "
		"de bois, abritant une double porte de bois sombre FERMÉE à deux anneaux de laiton, d'UNE case de "
		"large exactement au milieu de la façade ; de chaque côté du porche, une longue bannière rouge "
		"sombre tombant du toit, unie et sans motif, puis une fenêtre à petits carreaux bleutés. "
		"Parfaitement symétrique."),
		[BAT / "bldg_maison_rosalia_01.png", ART / "REF_EBENELLE_AIEULE.png"]),
	"BLDG_MAISON_EBENELLE": (batiment("bldg_maison_rosalia_01", "REF_EBENELLE_MAISON", 7, 6,
		"une MAISON d'Ébènelle, plus modeste que la demeure de l'Aïeule : toit de tuiles noires épaisses à "
		"quatre pans, faîtage aux bouts relevés, murs de pierre sombre et de poutres brun foncé, "
		"soubassement de pierre grise ; au milieu de la façade sud, une double porte de bois FERMÉE d'UNE "
		"case de large, sous un linteau de bois ; une fenêtre à petits carreaux bleutés de chaque côté ; "
		"au pied de la façade, de part et d'autre de la porte, une haie basse bien taillée. Symétrique."),
		[BAT / "bldg_maison_rosalia_01.png", ART / "REF_EBENELLE_MAISON.png"]),
	"RELIEF_PORCHE_ANTRE": (objet("relief_entree_grotte_01", "REF_EBENELLE_ANTRE",
		"le PORCHE DE L'ANTRE DU DRAGON : une bouche de grotte voûtée, très sombre à l'intérieur, cerclée "
		"de pierres taillées grises, encadrée de deux hauts piliers de pierre carrés à chapiteau plat, "
		"chacun sculpté en bas-relief d'un dragon serpentin dressé. Vue de face, pierre gris foncé avec un "
		"peu de mousse verte. Le bas de l'image est droit et s'arrête au sol. Largeur de l'ensemble : "
		"3,2 cases ; hauteur : 3,4 cases ; bouche d'1,4 case de large. Fond transparent, sans sol."),
		[RELIEF / "relief_entree_grotte_01.png", ART / "REF_EBENELLE_ANTRE.png"]),
	"PROP_LANTERNE_EBENELLE": (objet("prop_stele_01", "REF_EBENELLE_ANTRE",
		"une LANTERNE DE PIERRE de village de montagne : pied de pierre grise taillée, petite cage carrée "
		"à ouvertures claires (lumière ÉTEINTE de jour), chapeau de pierre noire à bords relevés comme les "
		"toits d'Ébènelle, un peu de mousse au pied. Hauteur 1,6 case, largeur 0,6 case. Fond transparent."),
		[PROPS / "prop_stele_01.png", ART / "REF_EBENELLE_ANTRE.png"]),
	"INT_COQUE_AIEULE": coque("plancher de bois très sombre ciré, murs de planches brun foncé sur "
		"soubassement de pierre sombre, poutres noires, et sur le mur du fond, entre les fenêtres, deux "
		"bannières rouge sombre unies du clan."),
	"INT_COQUE_EBENELLE": coque("plancher de bois sombre ciré, murs de planches brun foncé sur "
		"soubassement de pierre sombre, poutres noires, sans bannière."),
	"INT_ARMOIRE_CLAN": meuble(INT / "int_frigo_01.png", "une haute armoire étroite à deux portes"),
	"INT_BUFFET_CLAN": meuble(INT / "int_cuisine_01.png",
		"un long buffet bas à portes coulissantes, trois bols et une théière posés dessus"),
	"INT_BRASERO_CLAN": meuble(INT / "int_cuisiniere_hotte_01.png",
		"un brasero de fonte sur pied, braises éteintes, une bouilloire de fer suspendue au-dessus"),
	"INT_TABLE_BASSE_CLAN": meuble(INT / "int_table_repas_01.png",
		"une table très basse à plateau de bois sombre, entourée de coussins de sol rouge sombre"),
	"INT_BANQUETTE_CLAN": meuble(INT / "int_canape_01.png",
		"une longue banquette de bois sombre à dossier bas, garnie d'un coussin rouge sombre"),
	"INT_LANTERNE_CLAN": meuble(INT / "int_chevet_lampe_01.png",
		"une lanterne de papier sur pied de bois sombre, posée au sol"),
	"INT_TABLE_THE": meuble(INT / "int_table_basse_01.png",
		"une petite table à thé de bois sombre, service de thé en fonte posé dessus"),
	"INT_BONSAI": meuble(INT / "int_plante.png", "un vieux pin bonsaï dans une coupe de grès sombre"),
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
	for ident, (image, rect) in REFS.items():
		Image.open(REFERENCE / image).convert("RGB").crop(rect).save(ART / f"{ident}.png")
		print(ident)


# Coques : éclaircies [D] (le parquet sombre doit laisser lire les personnages).
ECLAIRAGE_COQUE = 1.75


def preparer_retenus() -> None:
	"""Prépare les images d'Ébènelle du manifeste seulement (catalogue existant conservé)."""
	import json
	import preparer
	from PIL import Image, ImageEnhance
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	sources = {f"{i}_r1.png" for i in ASSETS}
	for e in manifeste["objets"]:
		if e["source"] in sources:
			image = preparer._recadrer(Image.open(ART / e["source"]).convert("RGBA"), e)
			image = preparer._mettre_a_taille(preparer._silhouette(image), e["axe"], e["cases"], p.case)
			p._objet(e["id"], e["sortie"], image, e["ombre"], e["contact"])
	for e in manifeste["pieces"]:
		if e["source"] in sources:
			taille = (e["cases"][0] * p.case, e["cases"][1] * p.case)
			image = Image.open(ART / e["source"]).convert("RGB").resize(taille, Image.LANCZOS)
			ImageEnhance.Brightness(image).enhance(ECLAIRAGE_COQUE).save(RACINE / e["sortie"])
			p.catalogue["images"][e["id"]] = {"fichier": f"res://{e['sortie']}", "taille": list(taille)}
	p.ecrire_catalogue()


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--preparer"]:
		preparer_retenus()
		sys.exit(0)
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
