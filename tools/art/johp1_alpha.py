#!/usr/bin/env python3
"""Peinture des Ruines d'Alpha (arc des Pierres, JOHP1) : façades, murets, sols et meubles que le kit
peint n'a pas, peints par Codex : même méthode que les lots d'ambiance de Johto (gabarit = un objet
VALIDÉ du kit, contenu = recadrage de la vue générale validée).
Prompts : `prompts/johp1_alpha/`.
Usage : tools/art/johp1_alpha.py --refs           (recadrages `build/art/REF_*`)
        tools/art/johp1_alpha.py [--tour N] [IDENTIFIANT ...]
        tools/art/johp1_alpha.py --preparer   (images retenues → assets/, catalogue ; puis
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
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "johp1_alpha"

RUINES = "ruins-of-alph-vue-generale-v1.png"
TENTE = "alph-tent-vue-generale-v1.png"
GALERIE = "alph-gallery-vue-generale-v1.png"
CHAMBRE = "alph-chamber-vue-generale-v1.png"
# Recadrages des vues générales : identifiant → (image, rectangle en fractions de l'image).
REFS = {
	"REF_RU_TENTE": (RUINES, (0.17, 0.24, 0.40, 0.49)),
	"REF_RU_MURET": (RUINES, (0.565, 0.325, 0.73, 0.41)),
	"REF_RU_FACADE": (RUINES, (0.34, 0.59, 0.65, 0.70)),
	"REF_RU_PILIER": (RUINES, (0.38, 0.535, 0.415, 0.595)),
	"REF_RU_ESCALIER": (RUINES, (0.46, 0.60, 0.525, 0.68)),
	"REF_RU_DALLES": (RUINES, (0.37, 0.69, 0.62, 0.96)),
	"REF_TE_CAISSES": (TENTE, (0.09, 0.10, 0.92, 0.31)),
	"REF_TE_TABLE": (TENTE, (0.13, 0.34, 0.47, 0.73)),
	"REF_GA_MUR": (GALERIE, (0.08, 0.09, 0.42, 0.26)),
	"REF_GA_SOL": (GALERIE, (0.15, 0.27, 0.42, 0.34)),
	"REF_GA_DALLE": (GALERIE, (0.62, 0.22, 0.79, 0.29)),
	"REF_GA_ESCALIER": (GALERIE, (0.64, 0.05, 0.77, 0.18)),
	"REF_GA_CAMP": (GALERIE, (0.12, 0.16, 0.27, 0.29)),
	"REF_CH_FRISE": (CHAMBRE, (0.26, 0.04, 0.70, 0.19)),
	"REF_CH_SOCLE": (CHAMBRE, (0.43, 0.22, 0.57, 0.36)),
	"REF_CH_SOL": (CHAMBRE, (0.35, 0.44, 0.65, 0.76)),
}
PIERRE = RACINE / "assets/ui/items/stone_memory.webp"


def texture(ref: str, description: str) -> str:
	return f"""IMAGE 1 : {ref}, extrait d'une vue générale VALIDÉE : couleur et esprit du sol ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}
{TEXTURE_FIN}"""


def meuble(gabarit: Path, contenu: str, description: str) -> tuple[str, list[Path]]:
	return (objet(gabarit.stem, contenu, description), [gabarit, ART / f"{contenu}.png"])


ASSETS = {
	# Ruines.
	"BLDG_TENTE_ALPHA": (batiment("bldg_maison_toit_01", "REF_RU_TENTE", 7, 6,
		"la grande TENTE de fouilles d'Héloïse : tente de toile écrue à deux pans, mâts et cordes de "
		"bois clair, bord festonné, piquets au sol ; au milieu de la façade sud, une ouverture de "
		"toile sombre d'UNE case de large, les pans relevés de chaque côté. Aucune fenêtre."),
		[BAT / "bldg_maison_toit_01.png", ART / "REF_RU_TENTE.png"]),
	"PROP_MURET_ALPHA": meuble(PROPS / "prop_stele_01.png", "REF_RU_MURET",
		"un MURET de ruine très ancien, est-ouest : pierre grise moussue, un court pilier rond à chaque "
		"bout, au milieu un panneau de pierre gravé de motifs géométriques en losanges, sans lettre. "
		"Cinq cases de large (480 px en jeu), une case et demie de haut."),
	"PROP_MURET_TEMPLE": meuble(PROPS / "prop_stele_01.png", "REF_RU_FACADE",
		"une aile du MUR DE FAÇADE d'un temple enterré, est-ouest : blocs de pierre grise moussue, deux "
		"courts piliers ronds cerclés de pierre posés sur le mur, lierre par endroits. Cinq cases de "
		"large (480 px en jeu), une case et demie de haut."),
	"PROP_PILIER_ALPHA": meuble(PROPS / "prop_stele_01.png", "REF_RU_PILIER",
		"un PILIER DE RUINE trapu et cassé : tambour de pierre grise moussue sur un socle carré. Une "
		"case de large (96 px en jeu), une case de haut."),
	"RELIEF_ESCALIER_TEMPLE": meuble(RELIEF / "relief_escalier_tour_01.png", "REF_RU_ESCALIER",
		"l'ENTRÉE d'un temple enterré : un escalier de pierre qui descend vers le sud dans l'obscurité, "
		"vu de dessus, marches grises de plus en plus sombres, joues de pierre à gauche et à droite. "
		"Deux cases de large (192 px en jeu), une case et demie de long."),
	"GROUND_DALLES_ALPHA": (texture("REF_RU_DALLES",
		"un dallage de temple très ancien : grandes dalles carrées de pierre grise, exactement quatre "
		"sur quatre dans l'image, joints sombres, mousse verte dans les joints, usure douce ; valeur "
		"moyenne pour que les personnages s'y lisent."), [ART / "REF_RU_DALLES.png"]),
	# Tente.
	"INT_FOND_TENTE": ("""IMAGE 1 : la vue générale VALIDÉE de l'intérieur de la tente.

À FAIRE : EXACTEMENT la même image, même cadrage, mêmes toiles, mêmes mâts, même plancher, même sortie au sud, mais la pièce est VIDE : retire la rangée de caisses du fond, la table et le tapis ; le plancher continue à leur place, la toile du fond descend jusqu'au plancher.
Format : PNG paysage 1536 × 1024, OPAQUE ; pas de texte, pas de personnage.""",
		[REFERENCE / TENTE]),
	"INT_CAISSES_TENTE": meuble(INT / "int_comptoir_tour_01.png", "REF_TE_CAISSES",
		"EXACTEMENT la rangée de l'image 2 : sept caisses de bois côte à côte, chargées de carnets, "
		"pinceaux, moulages et fragments de pierre, sans aucune lettre. Sept cases de large (672 px en "
		"jeu), une case et demie de haut ; rien autour."),
	"INT_TABLE_TENTE": meuble(INT / "int_comptoir_tour_01.png", "REF_TE_TABLE",
		"EXACTEMENT la table de l'image 2 : table de bois à deux tiroirs, deux lampes de laiton, "
		"carnets, pinceaux, moulages de pierre, sans le tapis et sans aucune lettre. Deux cases de "
		"large (192 px en jeu), une case et demie de haut ; rien autour."),
	"INT_TAPIS_TENTE": meuble(INT / "int_tapis_salon_01.png", "REF_TE_TABLE",
		"EXACTEMENT le tapis de l'image 2, seul et entier, vu de dessus : tapis tressé de jute beige "
		"clair, bord à grosse tresse, sans motif ; la table est retirée. Trois cases de large (288 px en "
		"jeu), deux cases et demie de long ; rien autour."),
	# Galerie et Chambre.
	"GROUND_SOL_ALPHA": (texture("REF_GA_SOL",
		"un sol de grandes dalles de pierre grise usée, rectangulaires et irrégulières, joints sombres, "
		"poussière ; valeur moyenne, froide, sans tache marquante."), [ART / "REF_GA_SOL.png"]),
	"GROUND_SOL_CHAMBRE": (texture("REF_CH_SOL",
		"un sol de très grandes dalles de pierre claire légèrement bleutée, posées avec soin, joints "
		"fins, polies par le temps ; valeur moyenne, sans tache marquante."), [ART / "REF_CH_SOL.png"]),
	"RELIEF_MUR_ALPHA_FACE": meuble(RELIEF / "relief_mur_souterrain_01.png", "REF_GA_MUR",
		"un module de MUR de temple vu de face, est-ouest : gros blocs de pierre grise appareillés, "
		"quelques gravures géométriques très discrètes, pied un peu sombre, arête claire en haut. Deux "
		"cases de large, une case de haut : image rectangulaire pleine, OPAQUE jusqu'aux bords, les "
		"bords gauche et droit se raccordent à eux-mêmes."),
	"RELIEF_MUR_ALPHA_CAP": meuble(RELIEF / "relief_mur_souterrain_03.png", "REF_GA_MUR",
		"le COURONNEMENT d'un mur de temple vu de dessus, est-ouest : long bandeau de pierre claire "
		"usée. Image rectangulaire pleine, très allongée (six fois plus large que haute), OPAQUE "
		"jusqu'aux bords, les bords gauche et droit se raccordent à eux-mêmes."),
	"RELIEF_MUR_ALPHA_COTE": meuble(RELIEF / "relief_mur_souterrain_04.png", "REF_GA_MUR",
		"le BORD LATÉRAL d'un mur de temple vu de dessus, nord-sud : bandeau étroit de blocs de pierre "
		"claire usée. Image rectangulaire pleine, verticale (quatre fois plus haute que large), OPAQUE "
		"jusqu'aux bords, le haut et le bas se raccordent à eux-mêmes."),
	"RELIEF_DALLE_GLYPHE": meuble(RELIEF / "relief_mur_souterrain_03.png", "REF_GA_DALLE",
		"UNE dalle carrée de pierre claire vue strictement de dessus, cadre taillé en léger creux, centre "
		"lisse et VIDE (aucun signe, le jeu en pose un par-dessus). Une case. Image carrée pleine, OPAQUE."),
	"RELIEF_ESCALIER_GALERIE": meuble(RELIEF / "relief_escalier_tour_01.png", "REF_GA_ESCALIER",
		"un ESCALIER de pierre pris dans un mur de temple : marches grises qui montent vers le nord dans "
		"une ouverture sombre, joues de pierre à gauche et à droite. Deux cases de large (192 px en "
		"jeu), une case et demie de haut."),
	"PROP_PORTE_ALPHA": meuble(RELIEF / "relief_escalier_tour_01.png", "REF_GA_ESCALIER",
		"la PORTE DU FOND de la Galerie, FERMÉE : une lourde dalle de pierre sombre dressée, gravée de "
		"cercles concentriques sans lettre, qui bouche entièrement un escalier. Deux cases de large "
		"(192 px en jeu), une case et demie de haut."),
	"PROP_CAMP_ALPHA": meuble(PROPS / "prop_stele_01.png", "REF_GA_CAMP",
		"le coin de fouilles de l'image 2 : une bâche de toile écrue tendue sur deux piquets de bois. Deux "
		"cases de large (192 px en jeu), une case et demie de haut ; rien autour."),
	"RELIEF_FRISE_ALPHA": meuble(RELIEF / "relief_mur_souterrain_01.png", "REF_CH_FRISE",
		"la grande FRISE gravée de la Chambre de la Mémoire : long bas-relief de pierre grise, cercles "
		"concentriques au centre, méandres et motifs géométriques de chaque côté, sans lettre ni "
		"personnage. Huit cases de large (768 px en jeu), une case et demie de haut : image pleine, "
		"OPAQUE jusqu'aux bords."),
	"PROP_SOCLE_ALPHA": meuble(PROPS / "prop_socle_maree_01.png", "REF_CH_SOCLE",
		"le SOCLE de la Chambre : bloc rectangulaire bas de pierre claire, arêtes usées, dessus nu. Deux "
		"cases de large (192 px en jeu), une case de profondeur."),
	"PROP_PIERRE_MEMOIRE": (objet("prop_socle_maree_01", "stone_memory",
		"EXACTEMENT la pierre de l'image 2, peinte dans le rendu du jeu, posée droite, seule : mêmes "
		"forme et couleurs. Une demi-case de large (48 px en jeu)."),
		[PROPS / "prop_socle_maree_01.png", ART / "REF_PIERRE_MEMOIRE.png"]),
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
	Image.open(PIERRE).convert("RGBA").save(ART / "REF_PIERRE_MEMOIRE.png")


# Objets du catalogue : identifiant du jeu → (image retenue, dossier, largeur en cases, ombre, contact).
RETENUS = {
	"bldg_tente_alpha_01": ("BLDG_TENTE_ALPHA_r1.png", BAT, 7, True, 0.12),
	"prop_muret_alpha_01": ("PROP_MURET_ALPHA_r1.png", PROPS, 5, False, 0.1),
	"prop_muret_temple_01": ("PROP_MURET_TEMPLE_r1.png", PROPS, 5, False, 0.1),
	"prop_pilier_alpha_01": ("PROP_PILIER_ALPHA_r1.png", PROPS, 1, False, 0.1),
	"relief_escalier_temple_01": ("RELIEF_ESCALIER_TEMPLE_r1.png", RELIEF, 2, False, 0.0),
}
# Images posées telles quelles par les outils de carte : identifiant → (image, largeur, hauteur).
SPRITES = {
	"prop_socle_alpha_01": ("PROP_SOCLE_ALPHA_r1.png", 200, 0),
	"prop_pierre_memoire_01": ("PROP_PIERRE_MEMOIRE_r1.png", 56, 0),
	"prop_porte_alpha_01": ("PROP_PORTE_ALPHA_r1.png", 192, 144),
	"prop_camp_alpha_01": ("PROP_CAMP_ALPHA_r1.png", 192, 0),
	"relief_frise_alpha_01": ("RELIEF_FRISE_ALPHA_r1.png", 768, 120),
	"relief_dalle_glyphe_01": ("RELIEF_DALLE_GLYPHE_r1.png", 92, 92),
	"relief_escalier_galerie_01": ("RELIEF_ESCALIER_GALERIE_r1.png", 192, 144),
}
SOLS = {"ground_dalles_alpha_01": "GROUND_DALLES_ALPHA_r1.png",
	"ground_sol_alpha_01": "GROUND_SOL_ALPHA_r1.png",
	"ground_sol_chambre_01": "GROUND_SOL_CHAMBRE_r1.png"}
# Modules de mur, aux tailles de `relief_mur_souterrain_*` (`tools/module_walls.gd`).
FACE_TAILLE = (192, 120)
CHAPEAU_TAILLE = (192, 33)
COTE_TAILLE = (34, 146)
TENTE_TAILLE = (864, 672)
MEUBLES = {"int_caisses_tente_01": ("INT_CAISSES_TENTE_r1.png", 672),
	"int_table_tente_01": ("INT_TABLE_TENTE_r1.png", 208),
	"int_tapis_tente_01": ("INT_TAPIS_TENTE_r1.png", 288)}


def _rogner(image, marge: float = 0.0):
	"""Silhouette de [image], moins [marge] (fraction) de chaque côté : garde le plein des modules."""
	boite = image.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()
	image = image.crop(boite)
	dx, dy = int(image.width * marge), int(image.height * marge)
	return image.crop((dx, dy, image.width - dx, image.height - dy))


def _a_largeur(image, largeur: int, hauteur: int = 0):
	from PIL import Image
	if hauteur == 0:
		hauteur = round(image.height * largeur / image.width)
	return image.resize((largeur, hauteur), Image.LANCZOS)


def preparer_retenus() -> None:
	import json
	import preparer
	from PIL import Image, ImageChops
	for ident, source in SOLS.items():
		Image.open(ART / source).convert("RGB").resize((384, 384), Image.LANCZOS).save(
			RACINE / f"assets/world/ground/{ident}.png")
	for ident, (source, largeur, hauteur) in SPRITES.items():
		dossier = RELIEF if ident.startswith("relief") else PROPS
		image = Image.open(ART / source).convert("RGBA")
		image = image.crop(image.getchannel("A").getbbox())
		_a_largeur(image, largeur, hauteur).save(dossier / f"{ident}.png")
	Image.open(ART / "INT_FOND_TENTE_r1.png").convert("RGB").resize(TENTE_TAILLE,
		Image.LANCZOS).save(INT / "int_fond_tente_01.png")
	for ident, (source, largeur) in MEUBLES.items():
		image = Image.open(ART / source).convert("RGBA")
		_a_largeur(image.crop(image.getchannel("A").getbbox()), largeur).save(INT / f"{ident}.png")
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	for ident, (source, dossier, cases, ombre, contact) in RETENUS.items():
		image = preparer._silhouette(Image.open(ART / source).convert("RGBA"))
		image = preparer._mettre_a_taille(image, "w", cases, p.case)
		p._objet(ident, str((dossier / f"{ident}.png").relative_to(RACINE)), image, ombre, contact)
	face = _rogner(Image.open(ART / "RELIEF_MUR_ALPHA_FACE_r1.png").convert("RGBA"), 0.01)
	face = face.resize(FACE_TAILLE, Image.LANCZOS)
	chapeau = _rogner(Image.open(ART / "RELIEF_MUR_ALPHA_CAP_r1.png").convert("RGBA"), 0.01)
	cote = _rogner(Image.open(ART / "RELIEF_MUR_ALPHA_COTE_r1.png").convert("RGBA"), 0.01)
	modules = {"relief_mur_alpha_01": face,
		"relief_mur_alpha_02": ImageChops.offset(face, FACE_TAILLE[0] // 2, 0),
		"relief_mur_alpha_03": chapeau.resize(CHAPEAU_TAILLE, Image.LANCZOS),
		"relief_mur_alpha_04": cote.resize(COTE_TAILLE, Image.LANCZOS)}
	for ident, image in modules.items():
		p._objet(ident, str((RELIEF / f"{ident}.png").relative_to(RACINE)), image, False, 0.0)
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
