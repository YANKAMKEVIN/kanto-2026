#!/usr/bin/env python3
"""Peinture du Mont Argenté et de la Route 28 (JOH9) : neige, parois enneigées, sapins, forêt sous la neige,
muraille de glace, Centre enneigé, bouche de la grotte, marches, blocs du sommet, mer de nuages, poste et
maison du gardien, peints par Codex : même méthode que les lots de Johto (gabarit = un objet VALIDÉ du kit,
contenu = recadrage de la vue générale validée). Assets en lumière neutre. Prompts : `prompts/joh9_argente/`.
Usage : tools/art/joh9_argente.py --refs            (recadrages `build/art/REF_*`)
        tools/art/joh9_argente.py [--tour N] [IDENTIFIANT ...]
        tools/art/joh9_argente.py --preparer        (images retenues → assets/, catalogue ; puis
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
W = RACINE / "assets/world"
BAT, PROPS, RELIEF, GROUND = W / "buildings", W / "props", W / "relief", W / "ground"
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "joh9_argente"
EXT = "mont-argente-exterieur-vue-generale-v1.png"
SENTIER = "sentier-mont-argente-vue-generale-v1.png"
SOMMET = "mont-argente-sommet-vue-generale-v1.png"
ROUTE = "route-28-vue-generale-v1.png"
TROIS = "mont-argente-3f-vue-generale-v1.png"

# Recadrages : identifiant → (image, rectangle en pixels).
REFS = {
	"REF_ARG_NEIGE": (EXT, (800, 380, 1000, 480)),
	"REF_ARG_PAROI": (EXT, (0, 230, 290, 720)),
	"REF_ARG_SAPIN": (EXT, (270, 640, 400, 790)),
	"REF_ARG_ROCHER": (EXT, (355, 345, 440, 415)),
	"REF_ARG_HERBES": (EXT, (310, 430, 520, 625)),
	"REF_ARG_PLANTES": (EXT, (830, 340, 1010, 460)),
	"REF_ARG_BOUCHE": (EXT, (600, 30, 920, 170)),
	"REF_ARG_MARCHES": (EXT, (610, 150, 905, 350)),
	"REF_ARG_CENTRE": (SENTIER, (150, 165, 450, 435)),
	"REF_ARG_MURAILLE": (SENTIER, (120, 855, 485, 918)),
	"REF_ARG_FORET": (SENTIER, (0, 100, 130, 640)),
	"REF_ARG_BLOC": (SOMMET, (390, 150, 790, 350)),
	"REF_ARG_TRAPPE": (SOMMET, (1085, 105, 1180, 190)),
	"REF_ARG_NUAGES": (SOMMET, (1375, 300, 1536, 700)),
	"REF_ARG_POSTE": (ROUTE, (75, 300, 265, 495)),
	"REF_ARG_MAISON": (ROUTE, (680, 278, 940, 495)),
	"REF_ARG_GIVRE": (TROIS, (320, 415, 710, 480)),
}

NEIGE = ("Neige fraîche, poudreuse et moelleuse, blanc très légèrement bleuté, peinte en petits "
	"coussins arrondis ; ombres bleu pâle, jamais grises.")


def sol(gabarit: str, ref: str, description: str) -> tuple[str, list[Path]]:
	return (f"""IMAGE 1 : {gabarit}, une texture de sol VALIDÉE du jeu. C'est le GABARIT DE STYLE : même rendu peint, même finesse, même échelle (une case de jeu = un quart de l'image).
IMAGE 2 : {ref}, extrait de la vue générale VALIDÉE. C'est le CONTENU ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}
Texture vue strictement de dessus, qui remplit toute l'image jusqu'aux bords, SANS COUTURE (les bords opposés se raccordent), répartition régulière, aucun motif isolé qui se remarquerait en se répétant, aucun objet, aucune ombre portée. Format carré, haute définition.
""", [GROUND / f"{gabarit}.png", ART / f"{ref}.png"])


def planche(gabarits: list[Path], ref: str, description: str) -> tuple[str, list[Path]]:
	noms = ", ".join(g.stem for g in gabarits)
	return (f"""IMAGES {'1 à ' + str(len(gabarits)) if len(gabarits) > 1 else '1'} : {noms}, objets VALIDÉS du jeu. C'est le GABARIT DE STYLE : même rendu peint, même angle de vue (vue de dessus de trois quarts, face sud visible, aucun point de fuite), même lumière neutre, mêmes proportions.
IMAGE SUIVANTE : {ref}, extrait de la vue générale VALIDÉE. C'est le CONTENU ; son rendu un peu pixelisé ne doit PAS être copié.

À FAIRE : {description}
Format : PNG haute définition, fond transparent, éléments bien séparés les uns des autres par du vide, sans sol ni ombre portée, sans personnage, sans texte.
""", [*gabarits, ART / f"{ref}.png"])


def _arbres(ids: list[str]) -> list[Path]:
	return [PROPS / f"{i}.png" for i in ids]


ASSETS = {
	"GROUND_NEIGE": sol("ground_glace_01", "REF_ARG_NEIGE",
		f"une texture de NEIGE au sol. {NEIGE} Luminosité élevée mais pas blanc pur (environ 88 à 94 %), "
		"pour que les personnages et le chemin restent lisibles."),
	"GROUND_NUAGES": sol("ground_glace_01", "REF_ARG_NUAGES",
		"une MER DE NUAGES vue d'en haut : bourrelets de nuages doux, blanc bleuté, ombres bleu-gris pâle, "
		"cotonneux, sans horizon ni ciel."),
	"RELIEF_PAROI_NEIGE_PLANCHE": planche([RELIEF / "relief_paroi_ardoise_01.png", RELIEF / "relief_paroi_ardoise_04.png"],
		"REF_ARG_PAROI",
		"PLANCHE 2 × 2 de quatre modules de PAROI DE MONTAGNE, chacun un massif de roche grise stratifiée "
		"en colonnes verticales, de 5 cases de large et 3 cases de haut comme les gabarits, couronné d'une "
		"épaisse couche de neige sur tous ses dessus et rebords. Le pied de chaque module est droit. "
		"Roche gris neutre légèrement bleuté (pas noir, pas brun) avec arêtes claires. Quatre silhouettes "
		"différentes, chacune au milieu de son quart."),
	"GROUND_HERBES_NEIGE": (objet("ground_hautes_herbes_jaune_01", "REF_ARG_HERBES",
		"une TOUFFE de hautes herbes de montagne vert olive pâle, aux pointes chargées de neige, même "
		"silhouette et même encombrement que le gabarit. Fond transparent."),
		[GROUND / "ground_hautes_herbes_jaune_01.png", ART / "REF_ARG_HERBES.png"]),
	"TREE_SAPIN_NEIGE": (objet("tree_foret_05", "REF_ARG_SAPIN",
		"un SAPIN vert sombre aux branches étagées, chargées de neige épaisse, le tronc court brun visible en "
		"bas. Même encombrement que le gabarit. Fond transparent, sans sol."),
		[PROPS / "tree_foret_05.png", ART / "REF_ARG_SAPIN.png"]),
	"TREE_FORET_NEIGE_A": planche(_arbres(["tree_foret_01", "tree_foret_02", "tree_foret_03", "tree_foret_04"]),
		"REF_ARG_FORET", "PLANCHE 2 × 2 : les QUATRE arbres gabarits, dans le même ordre (lecture gauche à "
		"droite, haut en bas), mêmes silhouettes et mêmes proportions, repeints SOUS LA NEIGE : feuillage "
		"gardé mais cimes et branches chargées d'une épaisse couche de neige, comme l'image de contenu."),
	"TREE_FORET_NEIGE_B": planche(_arbres(["tree_foret_05", "tree_foret_06", "tree_foret_07", "tree_foret_08"]),
		"REF_ARG_FORET", "PLANCHE 2 × 2 : les QUATRE arbres gabarits, dans le même ordre (lecture gauche à "
		"droite, haut en bas), mêmes silhouettes et mêmes proportions, repeints SOUS LA NEIGE : feuillage "
		"gardé mais cimes et branches chargées d'une épaisse couche de neige, comme l'image de contenu."),
	"PROP_BUISSON_NEIGE": planche(_arbres(["prop_buisson_a_01", "prop_buisson_b_01", "prop_buisson_c_01"]),
		"REF_ARG_FORET", "PLANCHE 3 × 1 : les TROIS buissons gabarits, dans le même ordre, mêmes silhouettes, "
		"repeints sous une épaisse couche de neige, un peu de vert sombre visible dessous."),
	"PROP_ROCHER_NEIGE": planche([PROPS / "prop_rocher_01.png"], "REF_ARG_ROCHER",
		"PLANCHE 2 × 1 : deux ROCHERS ronds gris sombre, chacun d'une case de large, coiffés d'une calotte "
		"de neige. Deux silhouettes différentes."),
	"PROP_PLANTES_NEIGE": planche([PROPS / "prop_rocher_01.png"], "REF_ARG_PLANTES",
		"PLANCHE 3 × 2 de six toutes petites PLANTES DE MONTAGNE posées dans la neige, chacune d'un quart de "
		"case : deux touffes d'herbe vert pâle, deux bouquets de baies rouges sur feuilles vertes, deux "
		"bouquets de petites fleurs blanches."),
	"PROP_MURAILLE_GLACE": planche([RELIEF / "relief_mur_ligue_glace_01.png"], "REF_ARG_MURAILLE",
		"UN module de MURAILLE DE GLACE : longue barrière basse de blocs de glace bleu clair translucide, "
		"cannelés verticalement, coiffée de neige, 5 cases de large et 1 case et demie de haut. Vue de face. "
		"Les bords gauche et droit sont droits (les modules se suivent), le pied est droit."),
	"BLDG_CENTRE_NEIGE": (batiment("bldg_centre_01", "REF_ARG_CENTRE", 8, 7,
		"le CENTRE POKÉMON du Mont Argenté : EXACTEMENT le bâtiment gabarit (toit rouge, cercle blanc sans "
		"logo, façade crème, double porte vitrée bleue de DEUX cases au milieu de la façade), au même "
		"cadrage et à la même échelle, mais le toit et l'auvent portent de larges plaques de neige et deux "
		"buissons enneigés flanquent la porte."),
		[BAT / "bldg_centre_01.png", ART / "REF_ARG_CENTRE.png"]),
	"RELIEF_BOUCHE_NEIGE": (objet("relief_entree_grotte_01", "REF_ARG_BOUCHE",
		"la BOUCHE de la grotte du Mont Argenté : une ouverture noire d'une case et demie de large, à linteau "
		"de roche grise, encadrée de massifs de roche enneigés. Largeur de l'ensemble 4 cases, hauteur 3 "
		"cases ; le bas de l'image est droit et s'arrête au sol. Fond transparent, sans sol."),
		[RELIEF / "relief_entree_grotte_01.png", ART / "REF_ARG_BOUCHE.png"]),
	"RELIEF_MARCHES_NEIGE": (objet("relief_escalier_temple_01", "REF_ARG_MARCHES",
		"un large ESCALIER de pierre enfoui sous la neige : six marches larges et basses, vues de face, le "
		"nez de chaque marche marqué par une ombre bleu pâle, aucune roche visible. 11 cases de large et 7 "
		"cases de haut : image pleine, OPAQUE jusqu'aux bords gauche, droit, haut et bas."),
		[RELIEF / "relief_escalier_temple_01.png", ART / "REF_ARG_MARCHES.png"]),
	"PROP_BLOCS_NEIGE": planche([RELIEF / "relief_paroi_ardoise_01.png"], "REF_ARG_BLOC",
		"PLANCHE 3 × 2 de six BLOCS de roche grise taillée en colonnes, coiffés de neige : les trois du haut "
		"sont hauts (1 case de large, 1,6 case de haut, murets de la falaise du sommet), les trois du bas "
		"sont bas (1 case de large, 1 case de haut, pierres en ruine). Six silhouettes différentes."),
	"RELIEF_TRAPPE_SOMMET": (objet("prop_echelle_descend_01", "REF_ARG_TRAPPE",
		"une TRAPPE dans la neige : un trou carré à bord de planches sombres, une échelle de bois qui "
		"descend dans le noir, vue du dessus, une case de large, un peu de neige sur le bord. Fond "
		"transparent."),
		[PROPS / "prop_echelle_descend_01.png", ART / "REF_ARG_TRAPPE.png"]),
	"BLDG_POSTE_ROUTE_28": (batiment("bldg_poste_route_22_01", "REF_ARG_POSTE", 5, 5,
		"le POSTE de la Route 28 : petit bâtiment à toit d'ardoise bleu-gris à deux pans, murs crème sur "
		"soubassement de pierre claire, une porte bleue d'UNE case exactement au milieu de la façade, un petit "
		"panneau de bois vierge fixé à gauche sur le toit, sans lettre. Parfaitement droit."),
		[BAT / "bldg_poste_route_22_01.png", ART / "REF_ARG_POSTE.png"]),
	"BLDG_MAISON_GARDIEN": (batiment("bldg_maison_argenta_01", "REF_ARG_MAISON", 7, 6,
		"la MAISON DU GARDIEN de la Route 28 : maison simple à grand toit de tuiles rouge brique à deux pans, "
		"murs crème sur soubassement de pierre claire, une porte bleue d'UNE case exactement au milieu de la "
		"façade, une fenêtre à petits carreaux de chaque côté."),
		[BAT / "bldg_maison_argenta_01.png", ART / "REF_ARG_MAISON.png"]),
	"INT_COQUE_POSTE_28": ("""IMAGE 1 : int_poste_foret_coque, une pièce VALIDÉE du jeu, vide. C'est le GABARIT DE GÉOMÉTRIE : on garde EXACTEMENT son cadrage, la place de chaque mur, le contour du plancher, l'ouverture en haut au milieu et la porte en bas au milieu, au pixel près. Même format d'image, mêmes bords noirs.
IMAGE 2 : poste-route-28-v1, la vue VALIDÉE de ce poste : matériaux et couleurs.

À FAIRE : repeindre la même pièce vide avec les matériaux de l'image 2 : plancher de bois clair à longues lames, murs crème sur lambris de bois brun, poutres brunes ; l'ouverture du haut est une double porte de bois ouverte sur un chemin de montagne avec un peu de neige ; deux paillassons rouges devant chaque porte. Aucune plante, aucun meuble, aucun personnage, aucun texte. Lumière neutre.
""", [W / "interiors/int_poste_foret_coque.png", REFERENCE / "poste-route-28-v1.png"]),
	"RELIEF_GIVRE": planche([RELIEF / "relief_rebord_azuree_01.png"], "REF_ARG_GIVRE",
		"PLANCHE 2 × 2 de quatre traînées de GIVRE au sol : longues plaques minces et irrégulières de neige "
		"soufflée blanc bleuté, aux bords effilés, vues de dessus, 3 cases de long et une demi-case de large."),
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


# Objets du catalogue : identifiant du jeu → (image retenue, dossier, largeur en cases, ombre, contact).
RETENUS = {
	"bldg_centre_neige_01": ("BLDG_CENTRE_NEIGE_r1.png", BAT, 8, True, 0.12),
	"bldg_poste_route_28_01": ("BLDG_POSTE_ROUTE_28_r1.png", BAT, 5, True, 0.12),
	"bldg_maison_gardien_01": ("BLDG_MAISON_GARDIEN_r1.png", BAT, 7, True, 0.12),
	"tree_sapin_neige_01": ("TREE_SAPIN_NEIGE_r1.png", PROPS, 2.4, False, 0.1),
	"relief_bouche_neige_01": ("RELIEF_BOUCHE_NEIGE_r1.png", RELIEF, 4, False, 0.0),
	"relief_trappe_sommet_01": ("RELIEF_TRAPPE_SOMMET_r1.png", RELIEF, 1.1, False, None),
}
# Planches : [image, dossier, colonnes, lignes, identifiants, largeurs en cases].
PLANCHES = [
	{"source": "PROP_ROCHER_NEIGE_r1.png", "dossier": "assets/world/props/", "colonnes": 2, "lignes": 1,
		"ids": ["prop_rocher_neige_01", "prop_rocher_neige_02"], "cases": [1, 1], "contact": 0.15},
	{"source": "PROP_BLOCS_NEIGE_r1.png", "dossier": "assets/world/props/", "colonnes": 3, "lignes": 2,
		"ids": [f"prop_bloc_neige_0{i}" for i in range(1, 7)], "cases": [1.1, 1.1, 1.1, 1, 1, 1],
		"contact": 0.15},
	{"source": "RELIEF_GIVRE_r1.png", "dossier": "assets/world/relief/", "colonnes": 2, "lignes": 2,
		"ids": [f"relief_givre_0{i}" for i in range(1, 5)], "cases": [3, 3, 3, 3], "contact": None},
]
PAROIS = {"source": "RELIEF_PAROI_NEIGE_PLANCHE_r1.png", "dossier": "assets/world/relief/",
	"ids": [f"relief_paroi_neige_0{i}" for i in range(1, 5)], "hauteurs_px": [288] * 4, "contact": 0.0}
SOLS = {"ground_neige_01": ("GROUND_NEIGE_r1.png", 0.8), "ground_nuages_01": ("GROUND_NUAGES_r1.png", 1.0)}
# Mêmes tailles que les originaux : la forêt est plantée d'après eux, seule la texture change.
ARBRES = {"TREE_FORET_NEIGE_A_r1.png": ["tree_foret_01", "tree_foret_02", "tree_foret_03", "tree_foret_04"],
	"TREE_FORET_NEIGE_B_r1.png": ["tree_foret_05", "tree_foret_06", "tree_foret_07", "tree_foret_08"]}
BUISSONS = ["prop_buisson_a_01_bourg", "prop_buisson_b_01_bourg", "prop_buisson_c_01_bourg"]
PLANTE_PX = 60
# Herbes un peu ravivées : à leur taille en jeu, le vert se perd sous les pointes de neige [D].
HERBES_COULEUR = 1.6
MARCHES_TAILLE = (1056, 672)
MARCHES_FONDU = 40
NUAGES_BORD_PX = 120


def _fondre_bords(image, marge: int):
	"""Alpha en rampe sur `marge` px à gauche, à droite et en haut (l'escalier se perd dans la neige)."""
	import numpy as np
	from PIL import Image
	a = np.ones((image.height, image.width))
	rampe = np.linspace(0.0, 1.0, marge)
	a[:, :marge] *= rampe
	a[:, -marge:] *= rampe[::-1]
	a[:marge, :] *= rampe[:, None]
	a[-marge:, :] *= rampe[::-1][:, None]
	sortie = image.convert("RGBA")
	sortie.putalpha(Image.fromarray((a * 255).astype("uint8")))
	return sortie


def preparer_retenus() -> None:
	import json
	import numpy as np
	import preparer
	from PIL import Image, ImageChops, ImageEnhance
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	for ident, (source, contraste) in SOLS.items():
		image = Image.open(ART / source).convert("RGB").resize((384, 384), Image.LANCZOS)
		image = preparer.raccorder(ImageEnhance.Contrast(image).enhance(contraste), 24)
		image.save(GROUND / f"{ident}.png")
		p.catalogue["images"][ident] = {"fichier": f"res://assets/world/ground/{ident}.png", "taille": [384, 384]}
	for ident, (source, dossier, cases, ombre, contact) in RETENUS.items():
		image = preparer._silhouette(Image.open(ART / source).convert("RGBA"))
		image = preparer._mettre_a_taille(image, "w", cases, p.case)
		p._objet(ident, str((dossier / f"{ident}.png").relative_to(RACINE)), image, ombre, contact)
	p.m = {**manifeste, "planches_objets": PLANCHES, "planches_arbres": [PAROIS]}
	p.planches_objets()
	p.planches_arbres()
	# Escalier enneigé : plein, ses bords se fondent dans la neige.
	marches = Image.open(ART / "RELIEF_MARCHES_NEIGE_r1.png").convert("RGB").resize(MARCHES_TAILLE, Image.LANCZOS)
	p._objet("relief_marches_neige_01", "assets/world/relief/relief_marches_neige_01.png",
		_fondre_bords(marches, MARCHES_FONDU), False, None)
	# Muraille de glace : image répétée par `joh_ambiance_neige.gd`.
	mur = preparer._silhouette(Image.open(ART / "PROP_MURAILLE_GLACE_r1.png").convert("RGBA"))
	preparer._mettre_a_taille(mur, "w", 5, p.case).save(PROPS / "prop_muraille_glace_01.png")
	# Bord de la mer de nuages : la texture, alpha en rampe du haut vers le bas.
	nuages = Image.open(GROUND / "ground_nuages_01.png").convert("RGBA").crop((0, 0, 384, NUAGES_BORD_PX))
	nuages.putalpha(Image.fromarray(np.tile((np.clip(np.linspace(0, 1.8, NUAGES_BORD_PX), 0, 1) * 255
		).astype("uint8")[:, None], (1, 384))))
	nuages.save(GROUND / "ground_nuages_bord_01.png")
	# Hautes herbes sous la neige : taille de l'original.
	herbes = preparer._silhouette(Image.open(ART / "GROUND_HERBES_NEIGE_r1.png").convert("RGBA"))
	taille = Image.open(GROUND / "ground_hautes_herbes_jaune_01.png").size
	herbes = ImageEnhance.Color(herbes.resize(taille, Image.LANCZOS)).enhance(HERBES_COULEUR)
	herbes.save(GROUND / "ground_hautes_herbes_neige_01.png")
	# Forêt et buissons sous la neige : mêmes tailles que les originaux.
	for source, ids in ARBRES.items():
		planche = Image.open(ART / source).convert("RGBA")
		x, y = preparer._coupe_la_plus_vide(planche)
		quarts = [(0, 0, x, y), (x, 0, planche.width, y), (0, y, x, planche.height), (x, y, planche.width, planche.height)]
		for ident, quart in zip(ids, quarts):
			taille = Image.open(PROPS / f"{ident}.png").size
			preparer._silhouette(planche.crop(quart)).resize(taille, Image.LANCZOS).save(PROPS / f"{ident}_neige.png")
	planche = Image.open(ART / "PROP_BUISSON_NEIGE_r1.png").convert("RGBA")
	taches = sorted(preparer._taches(planche), key=lambda t: t[0][0])
	for ident, (boite, masque) in zip(BUISSONS, taches):
		element = planche.copy()
		element.putalpha(ImageChops.multiply(planche.getchannel("A"), masque))
		taille = Image.open(PROPS / f"{ident}.png").size
		preparer._silhouette(element.crop(boite)).resize(taille, Image.LANCZOS).save(PROPS / f"{ident}_neige.png")
	# Coque du poste : taille de celle qu'elle remplace.
	taille = Image.open(W / "interiors/int_poste_foret_coque.png").size
	Image.open(ART / "INT_COQUE_POSTE_28_r1.png").convert("RGB").resize(taille, Image.LANCZOS).save(
		W / "interiors/int_poste_route_28_coque.png")
	# Plantes de montagne : décalcomanies.
	planche = Image.open(ART / "PROP_PLANTES_NEIGE_r1.png").convert("RGBA")
	for numero, (boite, masque) in enumerate(preparer._taches(planche), 1):
		element = planche.copy()
		element.putalpha(ImageChops.multiply(planche.getchannel("A"), masque))
		element = preparer._silhouette(element.crop(boite))
		element.thumbnail((PLANTE_PX, PLANTE_PX), Image.LANCZOS)
		element.save(GROUND / "decals" / f"decal_plante_neige_{numero}.png")
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
