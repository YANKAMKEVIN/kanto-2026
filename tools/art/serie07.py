#!/usr/bin/env python3
"""Série 07 — intérieurs de Bourg Palette (lumière neutre).

Méthode de la série 03 : enveloppe VIDE de chaque pièce (murs, fenêtres, sol) + meubles
isolés, pour que le jeu décide de l'agencement et des collisions. Pièces et mobilier :
plans du jalon 2 (docs/tech/jalon-02.md §4.3 à §4.7). Références de contenu : anciennes
vues (chambre-joueur-v1, ouverture-storyboard-v1, maison-rival-v1, labo-chen-v1, style
pixel à ne pas copier) ; ancres de style : intérieurs du Centre (série 03).
Usage : tools/art/serie07.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import ADN, ART, LUMIERE_NE, PROMPTS, RACINE  # noqa: E402

REFERENCES = RACINE / "docs" / "design" / "reference"
STYLE = ["INT_CENTRE_COQUE_NE_r1.png", "INT_CENTRE_BANQUETTE_NE_r1.png"]
## Références de contenu, converties en PNG dans build/art/.
CONTENU = {
	"CHAMBRE": "chambre-joueur-v1.webp", "RDC": "ouverture-storyboard-v1.webp",
	"RIVAL": "maison-rival-v1.webp", "LABO": "labo-chen-v1.png",
}

MEUBLE_FIN = ("Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné. La base du meuble est "
	"une ligne de sol droite et horizontale ; rien sous cette ligne ; aucun sol autour, aucune ombre portée.\n"
	"Interdit : personnage, Pokémon (ni peluche, ni figurine, ni image de Pokémon), sol, mur, texte, lettres, "
	"chiffres, logo écrit, ombre portée.")
TAPIS_FIN = ("Fond : PNG avec une vraie transparence. Le tapis est vu STRICTEMENT à plat, de dessus, comme sur un "
	"plan, sans épaisseur visible ni perspective.\nInterdit : personnage, Pokémon, meuble, texte, ombre portée.")

## Pièces : (identifiant, contenu, largeur, profondeur, description des murs et du sol).
PIECES = [
	("INT_CHAMBRE_JOUEUR_COQUE", "CHAMBRE", 14, 10,
		"chambre d'adolescent chaleureuse à l'étage. Parquet de bois chaud en lames. Mur du fond crème avec "
		"une plinthe de bois : à gauche deux affiches de paysage (montagne, lac) sans texte, au centre une "
		"fenêtre à petits carreaux avec des rideaux blancs et bleus, à droite une grande carte de Kanto "
		"punaisée (sans aucun nom écrit). Sur le mur de droite (épaisseur vue de dessus), une porte en bois "
		"fermée dessinée. L'ouverture du bas est le HAUT D'UN ESCALIER en bois qui descend (on voit les "
		"premières marches s'enfoncer vers le bas de l'image)."),
	("INT_MAISON_JOUEUR_RDC_COQUE", "RDC", 14, 10,
		"rez-de-chaussée familial chaleureux : cuisine et salon dans une seule pièce. Parquet de bois chaud. "
		"Mur du fond crème avec soubassement de bois : deux fenêtres à petits carreaux (une à gauche du "
		"centre, une à droite), une étagère murale avec des pots et des plantes, quelques cadres photo. "
		"L'ouverture du bas est la PORTE D'ENTRÉE de la maison, en bois, avec un paillasson à carreaux bleus."),
	("INT_MAISON_RIVAL_COQUE", "RIVAL", 18, 11,
		"maison familiale de plain-pied, plus grande. Parquet de bois chaud. Mur du fond crème avec "
		"soubassement de bois : une fenêtre à gauche (au-dessus de la future cuisine), une fenêtre à droite "
		"(au-dessus de la future chambre), à l'extrême droite deux affiches de sport et une bannière rouge et "
		"blanche à motif de Poké Ball. L'ouverture du bas (2 cases, un peu à droite du centre) est la porte "
		"d'entrée avec un paillasson."),
	("INT_LABO_COQUE", "LABO", 16, 11,
		"laboratoire de recherche lumineux. Sol en grandes dalles claires gris-beige. Mur du fond crème avec "
		"soubassement gris-bleu : à gauche une grande carte de Kanto (sans aucun nom écrit), au centre une "
		"large fenêtre à trois vantaux donnant sur des arbres, à droite une affiche scientifique avec un "
		"schéma de Poké Ball (sans texte), deux lampes suspendues industrielles. L'ouverture du bas (2 cases, "
		"au centre) est l'entrée vitrée avec un tapis rouge à motif de Poké Ball."),
]

## Meubles : (identifiant, contenu, largeur en cases, description) ; largeur négative = tapis à plat.
MEUBLES = [
	# Communs aux deux maisons.
	("INT_MEUBLE_BAS_01", "RDC", 3, "meuble bas en bois chaud à portes et tiroirs, dessus garni de cadres "
		"photo, d'une petite plante et de quelques livres."),
	("INT_CANAPE_01", "RDC", 3, "canapé trois places crème, moelleux, deux coussins bleus, vu de face."),
	("INT_TABLE_BASSE_01", "RDC", 2, "table basse rectangulaire en bois, quelques magazines et une petite plante."),
	("INT_TABLE_REPAS_01", "RDC", 3, "table de repas en bois avec nappe à carreaux bleus et blancs, un "
		"bouquet au centre, quatre chaises en bois (deux de chaque côté, vues de dessus)."),
	("INT_FRIGO_01", "RDC", 1, "réfrigérateur blanc arrondi à deux portes, quelques magnets colorés."),
	("INT_CUISINE_01", "RDC", 3, "bloc de cuisine en bois et plan de travail clair : évier avec robinet, "
		"plaques de cuisson, quelques ustensiles et pots, placards en dessous."),
	("INT_ESCALIER_MONTANT_01", "RDC", 2, "escalier intérieur en bois qui MONTE vers l'étage, vu de face et de "
		"dessus : les marches s'élèvent vers le haut de l'image, rampe en bois sur le côté droit."),
	("INT_TELE_01", "RDC", 2, "meuble télé bas en bois avec un écran plat noir posé dessus, vu de face, "
		"une console de jeu et des boîtiers rangés dessous."),
	("INT_PORTE_MANTEAU_01", "RDC", 1, "porte-manteau mural en bois avec une veste bleue et un chapeau de "
		"paille, petit banc à chaussures en dessous."),
	("INT_COMMODE_POKEBALL_01", "RDC", 1, "petite commode en bois à deux tiroirs, une Poké Ball posée "
		"dessus à côté d'une plante."),
	("INT_TAPIS_SALON_01", "RDC", -3, "tapis de salon rectangulaire bleu à motifs géométriques clairs."),
	("INT_TAPIS_PLAID_01", "RDC", -5, "grand tapis rectangulaire à carreaux bleus et beiges."),
	# Chambre du joueur.
	("INT_LIT_01", "CHAMBRE", 2, "lit simple en bois vu de dessus et de face, tête de lit contre le mur "
		"(en haut), couette à grands carreaux bleus et blancs, oreiller blanc avec un coussin à motif de Poké "
		"Ball. Le lit est plus long que large (3 cases de long)."),
	("INT_CHEVET_LAMPE_01", "CHAMBRE", 1, "table de chevet en bois avec une lampe à abat-jour crème allumée "
		"et un petit réveil."),
	("INT_PETITE_ETAGERE_01", "CHAMBRE", 1, "petite étagère en bois remplie de livres colorés et de boîtes."),
	("INT_BUREAU_PC_01", "CHAMBRE", 3, "bureau en bois à tiroirs avec un ordinateur portable ouvert (écran "
		"bleu clair sans texte), une lampe d'architecte, des livres, un pot à crayons, une plante."),
	("INT_CHAISE_BUREAU_01", "CHAMBRE", 1, "chaise de bureau à roulettes bleu marine, vue de dos."),
	("INT_GRANDE_ETAGERE_01", "CHAMBRE", 2, "grande bibliothèque en bois haute de trois cases : livres, "
		"globe terrestre en haut, une Poké Ball décorative, une boîte rouge, une plante retombante."),
	("INT_SAC_VOYAGE_01", "CHAMBRE", 1, "sac de voyage bleu marine à sangles brunes, posé au sol, prêt pour "
		"l'aventure."),
	("INT_CAISSE_POKEBALLS_01", "CHAMBRE", 2, "caisse en bois basse remplie de Poké Balls rouges et blanches."),
	("INT_TAPIS_POKEBALL_01", "CHAMBRE", -4, "grand tapis gris-bleu clair avec un grand motif de Poké Ball "
		"stylisé, plus sombre, en son centre."),
	("INT_TAPIS_CARREAUX_01", "CHAMBRE", -2, "petit tapis à carreaux bleus et blancs."),
	# Maison du rival.
	("INT_CUISINIERE_HOTTE_01", "RIVAL", 1, "cuisinière avec four et plaques, hotte en inox au-dessus."),
	("INT_BUREAU_ANGLE_PC_01", "RIVAL", 2, "bureau d'angle en bois foncé avec un ordinateur fixe, deux écrans "
		"(sans texte), clavier, figurines de voitures, étagère au-dessus garnie de trophées juniors dorés."),
	("INT_CHAISE_GAMER_01", "RIVAL", 1, "chaise de jeu noire et rouge à roulettes, vue de dos."),
	("INT_COMMODE_01", "RIVAL", 2, "commode basse en bois à quatre tiroirs, dessus avec une lampe et des "
		"trophées."),
	("INT_LIT_POKEBALL_01", "RIVAL", 2, "lit simple vu de dessus, tête de lit contre le mur (en haut), "
		"couette rouge, blanche et noire imitant une Poké Ball, oreillers blancs. 3 cases de long."),
	("INT_LAVABO_01", "RIVAL", 2, "meuble lavabo de salle de bain en bois clair avec vasque blanche, miroir "
		"au-dessus, quelques flacons et une plante."),
	("INT_DOUCHE_01", "RIVAL", 1, "cabine de douche vitrée, faïence blanche et bleu clair, vue de face."),
	("INT_MEUBLE_CHAUSSURES_01", "RIVAL", 1, "petit meuble à chaussures en bois, deux paires de baskets."),
	("INT_CLOISON_V_01", "RIVAL", 0.4, "cloison intérieure basse vue de dessus et de face, orientée du haut "
		"vers le bas de l'image (verticale), longue de 3 cases et fine : dessus en bois, face crème, comme "
		"l'épaisseur des murs de la pièce."),
	("INT_CLOISON_H_01", "RIVAL", 5, "cloison intérieure horizontale longue de 5 cases : épaisseur de mur "
		"vue de dessus (bois) et face avant crème avec plinthe, hauteur d'un mur bas."),
	# Laboratoire.
	("INT_AQUARIUM_01", "LABO", 1, "aquarium rectangulaire éclairé sur un meuble bas, plantes aquatiques "
		"et cailloux (sans Pokémon)."),
	("INT_INCUBATEUR_01", "LABO", 2, "grande machine cylindrique métallique de recherche, hublot vitré "
		"éclairé de bleu, câbles et tuyaux à sa base, petit écran de contrôle (sans texte)."),
	("INT_MACHINES_LABO_01", "LABO", 2, "établi technique avec deux ordinateurs à écrans (sans texte), "
		"boîtiers, voyants, câbles, tiroirs métalliques."),
	("INT_BUREAU_CHEN_01", "LABO", 3, "grand bureau en bois du professeur : écran d'ordinateur, piles de "
		"dossiers et de livres, tasse, lampe de bureau, une plante."),
	("INT_CLASSEUR_01", "LABO", 1, "meuble classeur métallique gris à tiroirs, quelques dossiers dessus."),
	("INT_ETAGERE_LABO_01", "LABO", 2, "grande étagère de laboratoire en bois, haute de trois cases : "
		"classeurs colorés, livres, boîtes, bocaux, une plante."),
	("INT_VITRINE_POKEBALLS_01", "LABO", 1, "vitrine haute vitrée à étagères où sont rangées des Poké Balls."),
	("INT_LONG_COMPTOIR_01", "LABO", 5, "long comptoir bas en bois, garni de livres, d'un écran (sans texte), "
		"de boîtes de rangement et de plantes."),
	("INT_TABLE_STARTERS_01", "LABO", 3, "table d'exposition métallique claire sur laquelle reposent trois "
		"Poké Balls rouges et blanches sur trois petits socles, un bloc-notes à côté."),
	("INT_PAILLASSE_01", "LABO", 3, "paillasse de laboratoire blanche : microscope, terrarium vitré avec "
		"plantes, flacons, carnet ouvert, tasse."),
	("INT_TABOURET_01", "LABO", 1, "tabouret de laboratoire rond gris à roulettes."),
	("INT_ESCALIER_DECO_01", "LABO", 3, "escalier intérieur en bois avec rampe qui monte vers la gauche, vu "
		"de face et de dessus, quelques cadres au mur le long."),
	("INT_TAPIS_ROUGE_01", "LABO", -4, "tapis rectangulaire rouge brique à bordure ornée."),
	("INT_TAPIS_LABO_POKEBALL_01", "LABO", -4, "grand tapis clair avec un grand motif de Poké Ball rouge et "
		"bleu marine au centre."),
]


def _contenu(cle: str) -> str:
	sortie = ART / f"REF_BP_INT_{cle}.png"
	if not sortie.exists():
		Image.open(REFERENCES / CONTENU[cle]).convert("RGB").save(sortie)
	return str(sortie)


def _jointes(cle: str) -> str:
	return (f"Images jointes : REF_BP_INT_{cle} = référence de CONTENU et d'ambiance (meubles, matériaux, "
		"couleurs) d'une ancienne version : son rendu (touche pixel art, lumière dorée) et son angle ne doivent "
		"PAS être copiés. INT_CENTRE_COQUE_NE_r1 et INT_CENTRE_BANQUETTE_NE_r1 = ancres de style de la série "
		"(rendu peint, contour coloré, finesse, angle de vue, lumière neutre) : respecte-les exactement.")


def prompt_piece(identifiant: str, cle: str, largeur: int, profondeur: int, description: str) -> str:
	case = round(1536 / largeur)
	return (f"{identifiant} — NOUVELLE image : l'enveloppe VIDE d'une pièce intérieure de jeu (murs et sol, aucun "
		f"meuble).\n{_jointes(cle)}\n\n{ADN}\n{LUMIERE_NE}\n\n"
		"EXCEPTION à la règle « Isolement » de l'ADN : l'image est une pièce entière vue de dessus en trois quarts, "
		f"image opaque qui remplit tout le cadre.\nFormat : PNG paysage, opaque, proportions {largeur} × "
		f"{profondeur}.\nGéométrie (respecte-la exactement, c'est un plan de jeu) : la pièce fait {largeur} cases "
		f"de large × {profondeur} cases de profondeur ; 1 case ≈ {case} px. Vue de dessus en projection oblique "
		"frontale : le MUR DU FOND occupe toute la largeur en haut, on voit sa face avant sur les 2 cases du haut ; "
		"les murs latéraux gauche et droit ne sont visibles que par leur épaisseur vue de dessus (bande fine le "
		"long des bords gauche et droit) ; le mur du bas (au premier plan) n'est visible que par son épaisseur "
		"vue de dessus (bande fine en bas), interrompue par l'ouverture décrite ci-dessous. Tout le reste est du "
		f"SOL, entièrement libre et vide.\nPièce : {description}\n"
		"Interdit : meubles, plantes, tapis (sauf le paillasson demandé), personnages, Pokémon, texte, lettres, "
		"chiffres, logo écrit, perspective avec point de fuite, vue isométrique, ombre portée.\n")


def prompt_meuble(identifiant: str, cle: str, largeur: float, description: str) -> str:
	tapis = largeur < 0
	return (f"{identifiant} — NOUVELLE image : un seul {'tapis' if tapis else 'meuble'} isolé pour un intérieur "
		f"de jeu, pas une scène.\n{_jointes(cle)}\n\n{ADN}\n{LUMIERE_NE}\n\nASSET : {description}\n"
		"Format : PNG carré 1024 × 1024 ; l'objet occupe environ 900 px dans sa plus grande dimension, centré. "
		f"Échelle : {abs(largeur)} case(s) de large ; un adulte mesure 1,33 case.\n"
		f"{TAPIS_FIN if tapis else MEUBLE_FIN}\n")


def generer(entree) -> str:
	identifiant, cle = entree[0], entree[1]
	nom = f"{identifiant}_NE_r1"
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	texte = prompt_piece(*entree) if len(entree) == 5 else prompt_meuble(*entree)
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(texte)
	jointes = [_contenu(cle)] + [str(ART / s) for s in STYLE]
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier), *jointes],
		cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


if __name__ == "__main__":
	choix = set(sys.argv[1:])
	entrees = [e for e in PIECES + MEUBLES if not choix or e[0] in choix]
	for cle in CONTENU:
		_contenu(cle)
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(generer, entrees):
			print(ligne, flush=True)
