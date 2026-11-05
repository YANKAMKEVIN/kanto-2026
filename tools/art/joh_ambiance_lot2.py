#!/usr/bin/env python3
"""Ambiance du Chapitre Johto, lot 2 (JOH3, JOH4, JOH5, JOH7 ; suite de `joh_ambiance.py`). Façades
et objets propres à ces zones que le kit peint n'a pas, peints par Codex : même méthode que le
lot 1 (gabarit = un objet VALIDÉ du kit, contenu = recadrage de la vue générale validée).
Prompts : `prompts/joh_ambiance_lot2/`.
Usage : tools/art/joh_ambiance_lot2.py --refs           (recadrages `build/art/REF_*`)
        tools/art/joh_ambiance_lot2.py [--tour N] [IDENTIFIANT ...]
        tools/art/joh_ambiance_lot2.py --preparer   (images retenues → assets/, catalogue ; puis
        `godot --headless --path . --import` et `tools/build_painted_props.gd -- --nouveaux`)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from joh_ambiance import FIN, batiment  # noqa: E402
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, TEXTURE_FIN  # noqa: E402 (ADN : prompts)

RACINE = Path(__file__).resolve().parents[2]
BAT = RACINE / "assets/world/buildings"
PROPS = RACINE / "assets/world/props"
INT = RACINE / "assets/world/interiors"
ART = RACINE / "build/art"
REFERENCE = RACINE / "docs/design/reference"
PROMPTS = Path(__file__).parent / "prompts" / "joh_ambiance_lot2"

# Recadrages des vues générales : identifiant → (image, rectangle en pixels).
REFS = {
	"REF_DOUBLON_TOUR_RADIO": ("doublonville-vue-generale-v1.png", (217, 0, 425, 281)),
	"REF_DOUBLON_GARE": ("doublonville-vue-generale-v1.png", (975, 628, 1306, 787)),
	"REF_R36_GRILLE": ("route-36-vue-generale-v1.png", (770, 230, 1110, 450)),
	"REF_ECORCIA_CHARBONNERIE": ("ecorcia-vue-generale-v1.png", (240, 105, 540, 330)),
	"REF_ECORCIA_MAISON": ("ecorcia-vue-generale-v1.png", (285, 700, 565, 905)),
	"REF_ECORCIA_PUITS": ("ecorcia-vue-generale-v1.png", (1070, 120, 1290, 270)),
	"REF_BOIS_AUTEL": ("bois-aux-chenes-vue-generale-v1.png", (680, 200, 830, 290)),
	"REF_R41_ILE": ("route-41-vue-generale-v1.png", (530, 280, 990, 720)),
	"REF_R41_TOURBILLON": ("route-41-vue-generale-v1.png", (420, 200, 560, 260)),
	"REF_SOUTERRAIN_BOUTIQUE": ("souterrain-doublonville-vue-generale-v1.png", (120, 262, 320, 410)),
	"REF_RADIO_SOL": ("tour-radio-1f-vue-generale-v1.png", (1045, 482, 1445, 771)),
	"REF_RADIO_COMPTOIR": ("tour-radio-1f-vue-generale-v1.png", (484, 282, 1046, 455)),
	"REF_RADIO_LOGO": ("tour-radio-1f-vue-generale-v1.png", (702, 104, 835, 215)),
	"REF_RADIO_ENTREE": ("tour-radio-1f-vue-generale-v1.png", (668, 804, 868, 1003)),
	"REF_RADIO_STUDIO": ("tour-radio-2f-vue-generale-v1.png", (335, 186, 1201, 741)),
	"REF_RADIO_PUPITRE_HP": ("tour-radio-2f-vue-generale-v1.png", (668, 741, 912, 952)),
	"REF_RADIO_RAYONNAGE": ("tour-radio-3f-vue-generale-v1.png", (124, 226, 646, 370)),
	"REF_RADIO_REGIE": ("tour-radio-4f-vue-generale-v1.png", (268, 264, 701, 453)),
	"REF_RADIO_ECRANS": ("tour-radio-4f-vue-generale-v1.png", (390, 97, 1067, 220)),
	"REF_RADIO_DIFFUSION": ("tour-radio-5f-vue-generale-v1.png", (641, 479, 895, 646)),
	"REF_RADIO_BAIE": ("tour-radio-5f-vue-generale-v1.png", (69, 834, 1467, 990)),
}


def objet(gabarit: str, contenu: str, description: str) -> str:
	return f"""IMAGE 1 : {gabarit}, un objet VALIDÉ du jeu. C'est le GABARIT DE STYLE : même rendu peint, même angle de vue (vue de dessus de trois quarts, face sud visible, aucun point de fuite), même lumière neutre, même finesse.
IMAGE 2 : {contenu}, extrait de la vue générale VALIDÉE. C'est le CONTENU : forme, couleurs, matériaux ; son rendu un peu pixelisé ne doit PAS être copié, ni son cadrage.

À FAIRE : {description}
Format : PNG haute définition, l'objet occupe presque toute l'image.
{OBJET_FIN}"""


ASSETS = {
	"BLDG_TOUR_RADIO": (batiment("bldg_sylphe_safrania_01", "REF_DOUBLON_TOUR_RADIO", 10, 12,
		"la TOUR RADIO de Doublonville : immeuble moderne de bureaux de cinq étages, façades de verre "
		"bleu clair à bandeaux blancs horizontaux, toit plat gris clair avec deux petits locaux "
		"techniques, et au milieu du toit une haute antenne de radio rayée rouge et blanc ; au "
		"rez-de-chaussée, une double porte vitrée de DEUX cases de large exactement au milieu de la "
		"façade sud, sous un petit auvent blanc. Le point haut de la ville, élégant et lumineux."),
		[BAT / "bldg_sylphe_safrania_01.png", ART / "REF_DOUBLON_TOUR_RADIO.png"]),
	"BLDG_GARE_DOUBLONVILLE": (batiment("bldg_hotel_01", "REF_DOUBLON_GARE", 14, 8,
		"la GARE de Doublonville : long bâtiment classique de plain-pied à un étage, pierre claire, toit "
		"d'ardoise bleue à deux pans ; au centre, un fronton avec une grande horloge ronde sans "
		"chiffres, au-dessous une large baie vitrée bleutée à trois portes vitrées FERMÉES ; de chaque "
		"côté, des fenêtres hautes et des jardinières fleuries roses au pied de la façade."),
		[BAT / "bldg_hotel_01.png", ART / "REF_DOUBLON_GARE.png"]),
	"BLDG_GRILLE_PARC": (objet("bldg_poste_foret_01", "REF_R36_GRILLE",
		"la GRILLE du Parc National, Route 36 : un grand portail de fer forgé noir à deux battants "
		"FERMÉS, à barreaux hauts et pointes, entre deux gros piliers de pierre grise coiffés d'un "
		"chapeau de pierre, prolongé de chaque côté par un petit muret de pierre surmonté de la même "
		"grille. Largeur de l'ensemble : 8 cases (768 px en jeu), hauteur : 3 cases et demie. Le portail "
		"est vu de face, légèrement du dessus ; à travers les barreaux, rien : transparence."),
		[BAT / "bldg_poste_foret_01.png", ART / "REF_R36_GRILLE.png"]),
	"BLDG_CHARBONNERIE": (batiment("bldg_maison_chef_01", "REF_ECORCIA_CHARBONNERIE", 8, 6,
		"la CHARBONNERIE d'Écorcia : long bâtiment bas de bois noirci, grand toit à deux pans de "
		"bardeaux gris anthracite, grosse cheminée de pierre sur le faîtage ; façade sud à rangée de "
		"petites fenêtres à croisillons et une large porte de grange en bois FERMÉE à droite ; au pied "
		"de la façade, à gauche, des sacs de charbon en toile empilés. Rustique et sombre, mais propre."),
		[BAT / "bldg_maison_chef_01.png", ART / "REF_ECORCIA_CHARBONNERIE.png"]),
	"BLDG_MAISON_ECORCIA": (batiment("bldg_maison_a_01", "REF_ECORCIA_MAISON", 7, 6,
		"une MAISON TRADITIONNELLE d'Écorcia : maison basse à épais toit de CHAUME doré et brun aux bords "
		"arrondis, murs crème à colombages de bois sombre, une porte coulissante en bois au milieu de la "
		"façade sud (même place et même taille que la porte de l'IMAGE 1), deux fenêtres à croisillons "
		"de part et d'autre. Même largeur, même hauteur de façade et même position de porte que l'IMAGE 1."),
		[BAT / "bldg_maison_a_01.png", ART / "REF_ECORCIA_MAISON.png"]),
	"PROP_PUITS_ECORCIA": (objet("prop_rocher_01", "REF_ECORCIA_PUITS",
		"le PUITS d'Écorcia : au bord bas de l'image, un puits rond à margelle basse de pierre grise, "
		"large de 3 cases (288 px en jeu), son ouverture noire au milieu, le haut d'une échelle de bois "
		"qui y descend ; derrière, sur 2 cases de profondeur, une petite cour de dalles de pierre "
		"grise bien jointes, à bords droits (angles droits, pas d'herbe). Image presque carrée."),
		[PROPS / "prop_rocher_01.png", ART / "REF_ECORCIA_PUITS.png"]),
	"PROP_AUTEL_BOIS": (objet("prop_stele_01", "REF_BOIS_AUTEL",
		"l'AUTEL du Bois aux Chênes : un très petit sanctuaire de bois ancien sur un socle de pierre "
		"moussue, sous un petit toit à deux pans de bardeaux couverts de mousse verte, portes de bois "
		"fermées, une offrande discrète posée devant. Largeur d'une case et demie, hauteur de deux "
		"cases. Sobre, vénérable, entretenu ; aucun symbole religieux réel."),
		[PROPS / "prop_stele_01.png", ART / "REF_BOIS_AUTEL.png"]),
	"RELIEF_ILE_TOURBILLON": (f"""IMAGE 1 : relief_paroi_01, un module de falaise VALIDÉ du jeu. C'est le GABARIT DE STYLE : même rendu peint, même lumière neutre, même finesse.
IMAGE 2 : REF_R41_ILE, extrait de la vue générale VALIDÉE de la Route 41. C'est le CONTENU : forme, couleurs, matériaux ; son rendu ne doit PAS être copié, ni son cadrage.

À FAIRE : la GRANDE ÎLE des Îles Tourbillon, vue de dessus de trois quarts, aucun point de fuite : un bloc rocheux à angles droits, de plan CARRÉ, sommet plat de roche grise avec des plaques de mousse et d'herbe rase ; à l'est, à l'ouest et surtout au sud, de hautes falaises de roche grise striée verticalement qui tombent droit dans la mer. Sur le bord OUEST (côté gauche de l'image), EXACTEMENT à mi-hauteur de l'image, une ouverture de grotte sombre en arche, au ras de l'eau, large d'une case (un dixième environ de la largeur de l'image). La base de la falaise s'arrête net : pas d'eau, pas d'écume, pas de plage.
Format : PNG CARRÉ haute définition, l'île occupe TOUTE l'image jusqu'aux bords.
{FIN}""", [RACINE / "assets/world/relief/relief_paroi_01.png", ART / "REF_R41_ILE.png"]),
}


def meuble(gabarit: Path, contenu: str, description: str) -> tuple[str, list[Path]]:
	return (objet(gabarit.stem, contenu, description), [gabarit, ART / f"{contenu}.png"])


ASSETS.update({
	"GROUND_CARRELAGE_RADIO": (f"""IMAGE 1 : REF_RADIO_SOL, extrait de la vue générale VALIDÉE de la Tour Radio : couleur et esprit du sol.

À FAIRE : le carrelage du hall de la Tour Radio : grandes dalles carrées beige rosé très clair, finement marbrées, joints fins légèrement plus sombres, quatre dalles par côté de l'image, éclairage égal, sobre et propre.
{TEXTURE_FIN}""", [ART / "REF_RADIO_SOL.png"]),
	"INT_COMPTOIR_RADIO": meuble(INT / "int_comptoir_tour_01.png", "REF_RADIO_COMPTOIR",
		"le COMPTOIR d'accueil de la Tour Radio : long comptoir de bois clair verni, façade à panneaux "
		"de bois, plateau un peu débordant ; à gauche un écran d'ordinateur noir de dos, à droite un "
		"petit présentoir de dépliants bleus sans texte. Largeur 8 cases (768 px en jeu), profondeur 2 "
		"cases : image très allongée, rapport 3 pour 1 environ."),
	"INT_LOGO_RADIO": meuble(INT / "int_carte_murale_01.png", "REF_RADIO_LOGO",
		"le LOGO mural de la Tour Radio : un disque bleu nuit à fin liseré d'argent, avec au centre un "
		"pictogramme blanc d'antenne qui émet des ondes en arcs. Aucun texte. Vu de face, plat."),
	"INT_PORTE_ENTREE_RADIO": meuble(INT / "int_porte_labo_01.png", "REF_RADIO_ENTREE",
		"la DOUBLE PORTE vitrée d'entrée de la Tour Radio vue depuis l'intérieur : deux battants de verre "
		"bleuté à cadre gris clair, poignées verticales, un linteau gris ; à ses pieds un paillasson "
		"brun rectangulaire. Largeur 2 cases et demie, hauteur 2 cases."),
	"INT_TABLE_STUDIO": meuble(INT / "int_table_cartes_01.png", "REF_RADIO_STUDIO",
		"une TABLE de studio de radio ronde en bois clair sur pied central sombre, deux micros de studio "
		"sur petits bras noirs et un casque audio noir posés dessus. Largeur 2 cases et demie."),
	"INT_VITRE_STUDIO_H": meuble(INT / "int_cloison_h_01.png", "REF_RADIO_STUDIO",
		"un MODULE de paroi de verre de studio, orientation est-ouest : un panneau de verre bleuté "
		"transparent à reflets obliques, cadre fin d'aluminium gris en haut, en bas et aux deux bouts ; "
		"le verre doit rester visiblement translucide (canal alpha partiel). Largeur 2 cases (192 px en "
		"jeu), hauteur 1 case et demie, se raccorde bout à bout à lui-même."),
	"INT_VITRE_STUDIO_V": meuble(INT / "int_cloison_v_01.png", "REF_RADIO_STUDIO",
		"un MODULE de paroi de verre de studio, orientation nord-sud, vue de dessus de trois quarts : une "
		"paroi très étroite vue presque par la tranche, chant d'aluminium gris et mince bande de verre "
		"bleuté translucide. Largeur 1/3 de case, hauteur 2 cases, se raccorde bout à bout à lui-même."),
	"INT_PUPITRE_ORATEUR_RADIO": meuble(INT / "int_comptoir_tour_01.png", "REF_RADIO_PUPITRE_HP",
		"à gauche un PUPITRE d'orateur en bois clair, à droite, tout contre lui, une grosse ENCEINTE noire "
		"sur pied métallique. Ensemble large de 2 cases et haut de 3 cases."),
	"INT_RAYONNAGE_ARCHIVES": meuble(INT / "int_grande_etagere_01.png", "REF_RADIO_RAYONNAGE",
		"un RAYONNAGE d'archives de radio, vu de face légèrement du dessus : meuble bas de bois sombre à "
		"deux étages de casiers remplis de cartons beiges, de piles de bobines de bande et de boîtes "
		"rondes de film. Largeur 4 cases (384 px en jeu), profondeur 2 cases, se raccorde bout à bout."),
	"INT_PUPITRE_REGIE": meuble(INT / "int_pupitre_centrale_01.png", "REF_RADIO_REGIE",
		"un PUPITRE de régie de radio : grande console sombre gris anthracite, inclinée, couverte de "
		"curseurs, de boutons colorés et de trois petits écrans bleus à courbes d'onde, sans texte. "
		"Largeur 5 cases (480 px en jeu), profondeur 2 cases."),
	"INT_MUR_ECRANS_RADIO": meuble(INT / "int_ecran_diagnostic_01.png", "REF_RADIO_ECRANS",
		"le MUR D'ÉCRANS de la régie : une longue console basse contre le mur, surmontée d'une rangée de "
		"dix écrans bleus à courbes d'onde et à barres de niveau, sans texte. Largeur 10 cases (960 px "
		"en jeu), hauteur 2 cases : image très allongée."),
	"INT_TABLE_DIFFUSION": meuble(INT / "int_table_cartes_01.png", "REF_RADIO_DIFFUSION",
		"la TABLE de diffusion du studio : petite table basse de bois clair, un gros micro de studio "
		"argenté sur pied au milieu, à gauche un casque noir, à droite une petite console à boutons. "
		"Largeur 2 cases (192 px en jeu), profondeur 1 case et demie."),
	"INT_BAIE_VILLE": meuble(INT / "int_cloison_h_01.png", "REF_RADIO_BAIE",
		"un MODULE de baie vitrée du dernier étage, au mur sud : quatre vitres à cadre de bois clair qui "
		"donnent sur un panorama de ville de jour, toits rouges, arbres et ciel bleu clair, tous petits "
		"et lointains. Largeur 4 cases (384 px en jeu), hauteur 1 case, se raccorde bout à bout."),
	"PROP_HAUT_PARLEUR": meuble(PROPS / "prop_lampadaire_01.png", "REF_RADIO_PUPITRE_HP",
		"le HAUT-PARLEUR de la place de Doublonville : un poteau métallique gris fin, planté sur un "
		"petit socle, avec en haut deux pavillons de haut-parleur gris clair orientés de part et "
		"d'autre, un petit boîtier et un câble. Largeur 1 case, hauteur 2 cases et demie."),
	"FX_TOURBILLON": (f"""IMAGE 1 : REF_R41_TOURBILLON, extrait de la vue générale VALIDÉE de la Route 41 : couleur et esprit.

À FAIRE : UN TOURBILLON de mer vu strictement de dessus, peint : spirale d'écume blanche à trois bras autour d'un petit cœur bleu nuit, bords qui s'effilochent en écume, sans eau autour. La forme doit pouvoir tourner sur elle-même : pas de haut ni de bas, centrée exactement.
{LUMIERE_NE}
Format : PNG carré, fond avec une vraie transparence (canal alpha), aucun damier dessiné.
Interdit : texte, personnage, Pokémon, ombre portée.""", [ART / "REF_R41_TOURBILLON.png"]),
	"INT_BOUTIQUE_FERMEE": meuble(RACINE / "assets/world/relief/relief_mur_souterrain_01.png",
		"REF_SOUTERRAIN_BOUTIQUE",
		"une BOUTIQUE FERMÉE de galerie souterraine : devanture de béton sombre sous un auvent de "
		"tôle, grand rideau de fer baissé à lames horizontales gris sombre, un peu rouillé, sans texte ni "
		"enseigne écrite. Largeur 4 cases (384 px en jeu), hauteur 2 cases et demie, se raccorde bout à "
		"bout à elle-même."),
})


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


# Images retenues → `assets/` (silhouette recadrée, largeur = emprise, origine aux pieds, ombres,
# entrée du catalogue) : [identifiant du jeu, image retenue] ; réglages dans `manifeste.json`.
RETENUS: dict[str, str] = {
	"bldg_tour_radio_01": "BLDG_TOUR_RADIO_r1.png",
	"bldg_gare_doublonville_01": "BLDG_GARE_DOUBLONVILLE_r1.png",
	"bldg_grille_parc_01": "BLDG_GRILLE_PARC_r1.png",
	"bldg_charbonnerie_01": "BLDG_CHARBONNERIE_r1.png",
	"bldg_maison_ecorcia_01": "BLDG_MAISON_ECORCIA_r1.png",
	"prop_puits_ecorcia_01": "PROP_PUITS_ECORCIA_r1.png",
	"prop_autel_bois_01": "PROP_AUTEL_BOIS_r1.png",
	"relief_ile_tourbillon_01": "RELIEF_ILE_TOURBILLON_r1.png",
	"prop_haut_parleur_01": "PROP_HAUT_PARLEUR_r1.png",
	"int_comptoir_radio_01": "INT_COMPTOIR_RADIO_r1.png",
	"int_logo_radio_01": "INT_LOGO_RADIO_r1.png",
	"int_porte_entree_radio_01": "INT_PORTE_ENTREE_RADIO_r1.png",
	"int_table_studio_01": "INT_TABLE_STUDIO_r1.png",
	"int_vitre_studio_h_01": "INT_VITRE_STUDIO_H_r1.png",
	"int_pupitre_orateur_radio_01": "INT_PUPITRE_ORATEUR_RADIO_r1.png",
	"int_rayonnage_archives_01": "INT_RAYONNAGE_ARCHIVES_r1.png",
	"int_pupitre_regie_01": "INT_PUPITRE_REGIE_r1.png",
	"int_mur_ecrans_radio_01": "INT_MUR_ECRANS_RADIO_r1.png",
	"int_table_diffusion_01": "INT_TABLE_DIFFUSION_r1.png",
	"int_baie_ville_01": "INT_BAIE_VILLE_r1.png",
	"int_boutique_fermee_01": "INT_BOUTIQUE_FERMEE_r1.png",
	"int_vitre_studio_v_01": "INT_VITRE_STUDIO_V_r1.png",
}


def preparer_textures() -> None:
	"""Carrelage de la Tour Radio (384 px : quatre dalles, une par case) et tourbillon (192 px)."""
	from PIL import Image
	Image.open(ART / "GROUND_CARRELAGE_RADIO_r1.png").convert("RGB").resize((384, 384),
		Image.LANCZOS).save(RACINE / "assets/world/ground/ground_carrelage_radio_01.png")
	tourbillon = Image.open(ART / "FX_TOURBILLON_r1.png").convert("RGBA")
	tourbillon.crop(tourbillon.getbbox()).resize((192, 192), Image.LANCZOS).save(
		RACINE / "assets/world/fx/fx_tourbillon_01.png")


def ecume_ile() -> None:
	"""Eau claire et écume autour de la grande île (image calculée, pas de Codex) : 16 cases + 3 de
	marge de chaque côté, 24 px par case, à afficher ×4 sous l'île."""
	import math
	import random
	from PIL import Image, ImageFilter
	case, marge, ile = 24, 3, 16
	cote = (ile + 2 * marge) * case
	graine = random.Random(4101)
	bruit = Image.new("L", (cote // 6, cote // 6))
	bruit.putdata([graine.randrange(256) for _ in range(bruit.width * bruit.height)])
	bruit = bruit.resize((cote, cote), Image.BICUBIC).filter(ImageFilter.GaussianBlur(3))
	bord_bas, bord_haut = marge * case, (marge + ile) * case
	image = Image.new("RGBA", (cote, cote))
	pixels = image.load()
	for y in range(cote):
		for x in range(cote):
			dx = max(bord_bas - x, 0, x - bord_haut)
			dy = max(bord_bas - y, 0, y - bord_haut)
			d = math.hypot(dx, dy) / case + (bruit.getpixel((x, y)) - 128) / 128 * 0.5
			if d > 2.6:
				continue
			eclat = max(0.0, 1.0 - max(d, 0.0) / 2.6)
			blanc = max(0.0, 1.0 - abs(d - 0.2) / 0.5)
			r = int(90 + 165 * blanc)
			g = int(225 + 30 * blanc)
			b = int(215 + 40 * blanc)
			pixels[x, y] = (r, g, b, int(255 * min(1.0, 0.5 * eclat + 0.75 * blanc)))
	image.save(RACINE / "assets/world/decals/decal_ecume_ile_01.png")


def preparer_retenus() -> None:
	"""Prépare les images retenues de [RETENUS] seulement (catalogue existant conservé)."""
	preparer_textures()
	ecume_ile()
	import json
	import preparer
	from PIL import Image
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	entrees = {e["id"]: e for e in manifeste["objets"]}
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	for ident, source in RETENUS.items():
		e = entrees[ident]
		image = preparer._recadrer(Image.open(ART / source).convert("RGBA"), e)
		image = preparer._mettre_a_taille(preparer._silhouette(image), e["axe"], e["cases"],
			p.case)
		p._objet(ident, e["sortie"], image, e["ombre"], e["contact"])
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
