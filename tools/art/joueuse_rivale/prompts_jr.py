#!/usr/bin/env python3
"""Chantier JR (dossier-joueuse-rivale.md) : prompts des assets de la joueuse et de la rivale.

Chaque asset reprend l'asset validé de son homologue (héros ou rival) comme GABARIT (mise en
page, poses, échelle, rendu) et la planche de chara design validée (2026-10-30) comme IDENTITÉ.
Écrit `prompts/JR_<ID>.txt` ; `generer_jr.sh` lance Codex avec les deux images jointes.
"""
from pathlib import Path

ICI = Path(__file__).parent

JOUEUSE = ("la JOUEUSE, version fille du héros : fille d'environ 11 ans, chapeau rond rouge à large "
	"bord blanc avec un disque blanc frontal à point rouge, cheveux châtain foncé ondulés jusqu'aux "
	"épaules, t-shirt blanc à manches courtes, short en jean bleu marine à revers, chaussettes "
	"blanches montantes, baskets rouges à bande blanche, sac à dos jaune moutarde et bleu marine à "
	"bretelles bleu marine")
RIVALE = ("la RIVALE, version fille du rival : fille d'environ 11 ans, cheveux châtain-roux en queue de "
	"cheval haute et ébouriffée nouée d'un chouchou violet, mèches en épis sur le front, yeux gris "
	"sombre, sourire en coin ; gilet violet à capuche sans manches ouvert sur un haut noir sans "
	"manches, pendentif argenté, pantalon noir, baskets violettes à semelle blanche, sac à dos noir "
	"aux détails violets")

# (identifiant, gabarit joint, qui, ce que le gabarit contient en plus du personnage)
ASSETS = [
	("JOUEUSE_MARCHE", "PERSO_P2_PEINT_r1", "joueuse", "planche de marche 4 × 4"),
	("JOUEUSE_COURSE", "PERSO_P2_COURSE_r1", "joueuse", "planche de course 4 × 4"),
	("JOUEUSE_COURSE_PROFIL", "HEROS_COURSE_PROFIL_r1", "joueuse", "poses de course de profil"),
	("JOUEUSE_ATTENTE", "HEROS_ATTENTE_r1", "joueuse", "4 poses d'attente"),
	("JOUEUSE_VELO", "HEROS_VELO_NE_r1", "joueuse", "planche de vélo 4 × 4 : le même vélo rouge, identique"),
	("JOUEUSE_VELO_ARRET", "HEROS_VELO_ARRET_r1", "joueuse", "4 poses à vélo à l'arrêt : le même vélo rouge, identique"),
	("JOUEUSE_PECHE_LANCER", "HEROS_PECHE_LANCER_r1", "joueuse", "4 poses de lancer de canne : la même canne et le même fil, identiques"),
	("JOUEUSE_PECHE_ATTENTE", "HEROS_PECHE_ATTENTE_r1", "joueuse", "4 poses d'attente de pêche : la même canne et le même fil, identiques"),
	("JOUEUSE_SURF", "HEROS_SURF_NE_r1", "joueuse", "planche de surf 4 × 4 : la même monture, identique, à la même taille, avec la même écume"),
	("JOUEUSE_LANCER", "HEROS_APRES_r5_1", "joueuse", "pose unique de dos juste après le lancer d'une Poké Ball (main ouverte et vide)"),
	("JOUEUSE_PORTRAIT", "HEROS_PORTRAIT_NE_r1", "joueuse", "portrait en pied"),
	("JOUEUSE_BUSTE", "MENU_HEROS_BUSTE_r1", "joueuse", "buste du menu, proportions d'illustration (pas chibi)"),
	("RIVALE_MARCHE", "PNJ_RIVAL_NE_r1", "rivale", "planche de marche 4 × 4"),
	("RIVALE_ATTENTE", "RIVAL_ATTENTE_r1", "rivale", "4 poses d'attente"),
	("RIVALE_PORTRAIT", "VALIDE_PORTRAIT_RIVAL", "rivale", "portrait en pied, bras croisés"),
]


def prompt(ident: str, gabarit: str, qui: str, contenu: str) -> str:
	homologue = "le héros" if qui == "joueuse" else "le rival"
	du_homologue = "du héros" if qui == "joueuse" else "du rival"
	desc = JOUEUSE if qui == "joueuse" else RIVALE
	planche = "JR_PLANCHE_JOUEUSE_r1" if qui == "joueuse" else "JR_PLANCHE_RIVALE_r1"
	return f"""JR_{ident} — asset de jeu de Kanto 2026. Deux images sont jointes.
IMAGE 1 : {gabarit}, un asset VALIDÉ du jeu où figure {homologue} ({contenu}). C'est le GABARIT : reproduis EXACTEMENT son format et sa taille d'image, sa mise en page (grille, nombre de poses, ordre des lignes et des colonnes, espacements, position des pieds), chaque pose et chaque mouvement, l'échelle du personnage (même taille de tête et de corps, mêmes proportions), le cadrage, le rendu peint (contour fin et doux d'une teinte sombre et colorée, aucun trait noir, trois valeurs par matériau, légère granularité de pinceau), la lumière, et le fond transparent (vrai canal alpha, aucun damier dessiné, aucun halo).
IMAGE 2 : {planche}, la planche de chara design VALIDÉE du nouveau personnage. C'est l'IDENTITÉ : visage, coiffure, vêtements, couleurs.

À FAIRE : la même image que l'IMAGE 1, en remplaçant SEULEMENT {homologue} par {desc}. Elle a l'identité de l'IMAGE 2 mais les proportions et l'échelle {du_homologue} dans l'IMAGE 1. Tout le reste (poses, accessoires, objets, mise en page) reste identique à l'IMAGE 1. Le personnage est identique dans toutes les poses.
Interdits : texte, lettres, chiffres, logo, signature, cadre, décor, sol, ombre portée, autre personnage, Pokémon non présent dans l'IMAGE 1, pixel art, 3D, contours noirs épais. Design original : ce n'est la copie d'aucune héroïne officielle Pokémon.
"""


if __name__ == "__main__":
	for ident, gabarit, qui, contenu in ASSETS:
		(ICI / "prompts" / f"JR_{ident}.txt").write_text(prompt(ident, gabarit, qui, contenu))
		print(f"JR_{ident} {gabarit} {'JR_PLANCHE_JOUEUSE_r1' if qui == 'joueuse' else 'JR_PLANCHE_RIVALE_r1'}")
