#!/usr/bin/env python3
"""Série 06 — extérieur de Bourg Palette (lumière neutre).

Compose le prompt de chaque asset (ADN visuel v1 du cahier §1.3 + lumière NE + fiche) et
le génère avec Codex (tools/art/generer.sh), trois à la fois. Références : recadrages de
docs/design/reference/bourg-palette-vue-generale-v1.png (REF_BP_*) et ancres de style
déjà validées (build/art/, non versionné).
Usage : tools/art/serie06.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
ART = RACINE / "build" / "art"
PROMPTS = ART / "prompts"

ADN = (RACINE / "docs/design/cahier-art-monde-v0.1.md").read_text().split("```text\n")[1].split("```")[0]
LUMIERE_NE = ("LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement "
	"du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun "
	"liseré chaud ; ombres propres neutres, légèrement bleutées.")
STYLE = ["WORLD_BLDG_MAISON_A_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]

OBJET_FIN = ("Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné. La base de l'objet "
	"est une ligne de sol droite et horizontale ; rien sous cette ligne ; aucun sol autour, aucune ombre portée.\n"
	"Interdit : personnage, Pokémon, sol, herbe ou pavés autour, texte, lettres, chiffres, ombre portée.")
TEXTURE_FIN = ("Format : PNG carré 1024 × 1024, OPAQUE, qui couvre toute l'image. Texture de sol vue strictement "
	"de dessus, à plat, RACCORDABLE sans couture sur ses quatre bords (elle se répète en mosaïque) ; motif "
	"régulier sans élément remarquable qui trahirait la répétition ; aucune perspective, aucun objet, aucun bord.\n"
	"Interdit : personnage, Pokémon, objet, texte, ombre portée, vignettage.")

# (identifiant, référence REF_BP_* ou None, largeur en cases, description) ; largeur None = texture.
SERIE = [
	("WORLD_BLDG_MAISON_JOUEUR_01", "REF_BP_MAISON_JOUEUR", 6,
		"maison du joueur à Bourg Palette, petite maison familiale chaleureuse d'un étage. Toit à deux pans "
		"de tuiles rouges, cheminée claire à droite, murs crème, porte en bois brun au centre sous un petit "
		"auvent de bois, deux marches de pierre, une fenêtre de chaque côté de la porte, une petite fenêtre "
		"sous le pignon, jardinières fleuries aux fenêtres. Sans clôture, sans vélo, sans boîte aux lettres."),
	("WORLD_BLDG_MAISON_RIVAL_01", "REF_BP_MAISON_RIVAL", 6,
		"maison du rival à Bourg Palette, sœur de la maison du joueur mais reconnaissable : même taille, toit à "
		"deux pans de tuiles rouges un peu plus sombres, cheminée à GAUCHE, murs crème, porte en bois peinte "
		"en vert sapin sous un auvent, deux marches de pierre, volets verts, une lucarne dans le toit. "
		"Sans clôture, sans boîte aux lettres."),
	("WORLD_BLDG_LABO_01", "REF_BP_LABO", 10,
		"laboratoire du Professeur Chen, le plus grand bâtiment du village mais sobre : bâtiment moderne de "
		"plain-pied, murs gris clair, toit plat avec panneaux solaires, une antenne et un petit bloc "
		"technique, grandes fenêtres bleutées, entrée vitrée à double porte au centre de la façade, emblème "
		"Poké Ball rouge et blanc au-dessus de l'entrée (le seul emblème autorisé), quelques bacs de plantes "
		"intégrés au pied de la façade. Sans camionnette, sans vélo."),
	("WORLD_BLDG_SERRE_01", "REF_BP_SERRE", 3,
		"petite serre de recherche : armature métallique blanche, parois et toit à deux pans en verre "
		"légèrement bleuté et transparent, plantes vertes et fleurs visibles à l'intérieur, porte vitrée "
		"fermée sur la face avant."),
	("WORLD_TREE_ANCIEN_01", "REF_BP_ARBRE_ANCIEN", 6,
		"le grand arbre ancien de la place de Bourg Palette, repère émotionnel du village : chêne très vieux "
		"et majestueux, tronc épais et noueux aux racines visibles, large couronne arrondie en grandes masses "
		"de feuillage, planté au centre d'un îlot circulaire de fleurs variées (blanches, jaunes, roses) bordé "
		"d'une margelle de pierre claire. L'objet comprend l'arbre ET son îlot."),
	("WORLD_PROP_CLOTURE_PIQUETS_01", None, 4,
		"tronçon droit de clôture à piquets blancs, peinture légèrement patinée, deux traverses, piquets "
		"pointus régulièrement espacés ; les deux extrémités sont coupées net au milieu d'un intervalle pour "
		"se raccorder bout à bout. Hauteur environ 0,9 case."),
	("WORLD_PROP_VELO_01", "REF_BP_MAISON_JOUEUR", 1.8,
		"vélo de ville rouge garé, vu de profil légèrement de dessus, béquille dépliée, panier à l'avant."),
	("WORLD_PROP_CAMIONNETTE_01", "REF_BP_LABO", 2.6,
		"camionnette utilitaire blanche du laboratoire, garée, vue de face (côté sud) et de dessus, "
		"compacte et arrondie, petite bande bleue sur le côté, sans aucune inscription ni logo."),
	("WORLD_GROUND_CHAMP_01", "REF_BP_CHAMP", 6,
		"champ cultivé rectangulaire vu de dessus : terre brune labourée en rangées parallèles horizontales "
		"régulières de jeunes plants verts, bordure d'herbe fine. Objet à plat, sans clôture."),
	("WORLD_PROP_PONTON_01", "REF_BP_PONTON", 5,
		"ponton de pêche en bois sur pilotis, vu de dessus et de face : plancher de planches, rambarde de "
		"rondins sur les côtés, pilotis qui descendent dans l'eau (l'eau n'est PAS dessinée : les pilotis "
		"s'arrêtent net)."),
	("WORLD_PROP_RONCES_01", "REF_BP_SENTIER_SECRET", 2,
		"amas de ronces et de broussailles enchevêtrées, tiges épineuses brun-vert, quelques feuilles sombres, "
		"dense et clairement infranchissable ; bouche l'entrée d'un ancien sentier."),
	("WORLD_PROP_TRONC_COUCHE_01", "REF_BP_SENTIER_SECRET", 3,
		"vieux tronc d'arbre couché, moussu, écorce brune, quelques champignons et du lierre, posé "
		"horizontalement."),
	("WORLD_PROP_ROCHER_MER_01", "REF_BP_COTE", 2,
		"rocher marin brun-gris arrondi, sommet sec, base mouillée plus sombre ; il émerge de l'eau mais "
		"l'eau n'est PAS dessinée."),
	("WORLD_RELIEF_ESCALIER_BOIS_01", "REF_BP_PONTON", 2,
		"escalier extérieur en bois qui descend vers une plage, vu de face et de dessus : marches de planches, "
		"rambardes de rondins de chaque côté ; le haut de l'escalier est en haut de l'image."),
	("WORLD_GROUND_SABLE_01", "REF_BP_PONTON", None,
		"texture de sable de plage clair et chaud, grain fin peint, quelques ondulations douces et rares "
		"petits coquillages discrets."),
	("WORLD_GROUND_EAU_01", "REF_BP_COTE", None,
		"texture d'océan turquoise et bleu, vue de dessus, petites vagues peintes en touches claires, reflets "
		"doux ; ni écume de rivage ni rocher."),
	("WORLD_GROUND_ECUME_01", "REF_BP_COTE", 4,
		"bande horizontale d'écume blanche et de vaguelettes qui viennent mourir sur un rivage, à poser à la "
		"jonction entre le sable (au-dessus) et l'eau (en dessous) ; bords gauche et droit raccordables ; "
		"seulement l'écume, le reste transparent."),
]


def prompt(identifiant: str, ref: str | None, largeur, description: str) -> str:
	jointes = "Images jointes : "
	if ref:
		jointes += (f"{ref} = référence de forme, de matériaux et de couleurs, extraite de la vue d'ensemble de "
			"Bourg Palette : dessine l'objet comme s'il avait été extrait de cette image puis agrandi, avec le "
			"même angle. ")
	jointes += ("WORLD_BLDG_MAISON_A_01_NE_r1 et WORLD_TREE_A_01_NE_r1 = ancres de style de la série (rendu "
		"peint, contour coloré, finesse, même angle de vue, même lumière neutre).")
	if largeur is None:
		corps = f"ASSET : {description}\n{TEXTURE_FIN}"
		entete = f"{identifiant} — NOUVELLE image : une texture de sol de jeu, pas une scène."
	else:
		corps = (f"ASSET : {description}\nFormat : PNG carré 1024 × 1024 ; l'objet occupe environ 900 px dans sa "
			f"plus grande dimension, centré. Échelle : {largeur} cases de large.\n{OBJET_FIN}")
		entete = f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène."
	return f"{entete}\n{jointes}\n\n{ADN}\n{LUMIERE_NE}\n\n{corps}\n"


def generer(entree) -> str:
	identifiant, ref, largeur, description = entree
	nom = f"{identifiant}_NE_r1"
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(prompt(identifiant, ref, largeur, description))
	jointes = ([str(ART / f"{ref}.png")] if ref else []) + [str(ART / s) for s in STYLE]
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier), *jointes],
		cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


if __name__ == "__main__":
	choix = set(sys.argv[1:])
	entrees = [e for e in SERIE if not choix or e[0] in choix]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(generer, entrees):
			print(ligne, flush=True)
