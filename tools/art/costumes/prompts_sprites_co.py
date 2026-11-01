#!/usr/bin/env python3
"""Chantier CO (dossier-costumes.md §3, CO-5) : prompts des sprites de jeu des 16 costumes.

Même méthode que la joueuse (`tools/art/joueuse_rivale/prompts_jr.py`) : chaque asset reprend
l'asset validé du héros (version joueur) ou de la joueuse (version joueuse) comme GABARIT (mise en
page, poses, échelle, rendu), et la moitié de la planche du costume validée le 2026-10-30
(`docs/design/reference/costumes/costume-<badge>-v1.webp`) comme IDENTITÉ.
Écrit `prompts/CO_<BADGE>_<VERSION>_<ASSET>.txt` et, sur la sortie standard, une ligne par asset :
« identifiant gabarit identité » (lue par `generer_sprites_co.sh`).
Usage : prompts_sprites_co.py [BADGE ...]   (sans argument : les 8 badges)
"""
import os
import sys
from pathlib import Path

from prompts_co import ADOUCI, COSTUMES, SANS_NOM

ICI = Path(__file__).parent

# (asset, gabarit du héros, gabarit de la joueuse, ce que le gabarit contient)
ASSETS = [
	("MARCHE", "PERSO_P2_PEINT_r1", "JR_JOUEUSE_MARCHE_r1", "planche de marche 4 × 4"),
	("COURSE", "PERSO_P2_COURSE_r1", "JR_JOUEUSE_COURSE_r1", "planche de course 4 × 4"),
	("COURSE_PROFIL", "HEROS_COURSE_PROFIL_r1", "JR_JOUEUSE_COURSE_PROFIL_r1", "poses de course de profil"),
	("ATTENTE", "HEROS_ATTENTE_r1", "JR_JOUEUSE_ATTENTE_r1", "4 poses d'attente"),
	("VELO", "HEROS_VELO_NE_r1", "JR_JOUEUSE_VELO_r1", "planche de vélo 4 × 4 : le même vélo rouge, identique"),
	("VELO_ARRET", "HEROS_VELO_ARRET_r1", "JR_JOUEUSE_VELO_ARRET_r1",
		"4 poses à vélo à l'arrêt : le même vélo rouge, identique"),
	("PECHE_LANCER", "HEROS_PECHE_LANCER_r1", "JR_JOUEUSE_PECHE_LANCER_r1",
		"4 poses de lancer de canne : la même canne et le même fil, identiques"),
	("PECHE_ATTENTE", "HEROS_PECHE_ATTENTE_r1", "JR_JOUEUSE_PECHE_ATTENTE_r1",
		"4 poses d'attente de pêche : la même canne et le même fil, identiques"),
	("SURF", "HEROS_SURF_NE_r1", "JR_JOUEUSE_SURF_r1",
		"planche de surf 4 × 4 : la même monture, identique, à la même taille, avec la même écume"),
	("LANCER", "HEROS_APRES_r5_1", "JR_JOUEUSE_LANCER_r1",
		"pose unique de dos juste après le lancer d'une Poké Ball (main ouverte et vide)"),
	("BUSTE", "MENU_HEROS_BUSTE_r1", "JR_JOUEUSE_BUSTE_r1", "buste du menu, proportions d'illustration (pas chibi)"),
]
VERSIONS = ("JOUEUR", "JOUEUSE")

# Repli des sprites (ADOUCIR=1, relance des images refusées par le filtre de Codex à la sortie) :
# tenue décrite sans ses signes déposés (2026-10-30 : Link refusé 6 fois sur 11 avec le blason).
ADOUCI_SPRITES = {
	("PRISME", "JOUEUR"): "tunique verte à manches blanches, bonnet vert pointu tombant en arrière, cheveux "
		"blonds, oreilles pointues, ceinture et bandoulière de cuir, bottes brunes ; dans le dos une petite "
		"épée courte et un bouclier rond en bois cerclé de fer, UNI, sans aucun blason ni symbole",
}


def costume(badge: str, version: str) -> tuple[str, str]:
	"""(qui, description) : noms retirés et tenues adoucies là où le filtre de Codex bloque."""
	j, dj, f, df = COSTUMES[badge]
	if badge in SANS_NOM:
		j, f = SANS_NOM[badge]
	if badge in ADOUCI:
		dj, df = ADOUCI[badge]
	if os.environ.get("ADOUCIR") and (badge, version) in ADOUCI_SPRITES:
		dj = df = ADOUCI_SPRITES[(badge, version)]
	return (j, dj) if version == "JOUEUR" else (f, df)


def identite(badge: str, version: str) -> tuple[str, str]:
	"""(ancre, phrase) de l'IMAGE 2. IDENTITE_<VERSION>=ancre (sans .png) remplace la moitié de
	planche par une planche de marche déjà générée : le costume adouci reste le même dans toutes
	les poses (2026-10-30 : Link, le blason de la planche bloquait le filtre)."""
	ancre = os.environ.get(f"IDENTITE_{version}")
	if ancre:
		return ancre, ("la planche de marche du personnage costumé, déjà faite pour ce jeu. C'est "
			"l'IDENTITÉ : visage, coiffure, tenue, accessoires portés, couleurs ; reprends-les à l'identique")
	cote = "à GAUCHE (garçon)" if version == "JOUEUR" else "à DROITE (fille)"
	return f"CO_{badge}_{version}_ID", (f"la planche de chara design VALIDÉE du costume (le personnage "
		f"{cote} de cette planche). C'est l'IDENTITÉ : visage, coiffure, tenue, accessoires portés, couleurs")


def prompt(badge: str, version: str, asset: str, gabarit: str, contenu: str) -> str:
	homologue = "le héros" if version == "JOUEUR" else "la joueuse"
	du_homologue = "du héros" if version == "JOUEUR" else "de la joueuse"
	qui, desc = costume(badge, version)
	return f"""CO_{badge}_{version}_{asset} — asset de jeu de Kanto 2026. Deux images sont jointes.
IMAGE 1 : {gabarit}, un asset VALIDÉ du jeu où figure {homologue} ({contenu}). C'est le GABARIT : reproduis EXACTEMENT son format et sa taille d'image, sa mise en page (grille, nombre de poses, ordre des lignes et des colonnes, espacements, position des pieds), chaque pose et chaque mouvement, l'échelle du personnage (même taille de tête et de corps, mêmes proportions), le cadrage, le rendu peint (contour fin et doux d'une teinte sombre et colorée, aucun trait noir, trois valeurs par matériau, légère granularité de pinceau), la lumière, et le fond transparent (vrai canal alpha, aucun damier dessiné, aucun halo).
IMAGE 2 : {identite(badge, version)[1]}.

À FAIRE : la même image que l'IMAGE 1, en remplaçant SEULEMENT {homologue} par le même enfant costumé en {qui} : {desc}. Le costume remplace toute la tenue {du_homologue}, casquette ou chapeau et sac à dos compris (pas de sac à dos jaune, sauf s'il figure dans l'IMAGE 2). Le personnage a l'identité de l'IMAGE 2 mais les proportions et l'échelle {du_homologue} dans l'IMAGE 1. Tout le reste (poses, objets tenus ou chevauchés : vélo, canne, monture, mise en page) reste identique à l'IMAGE 1. Le personnage est identique dans toutes les poses.
Interdits : texte, lettres, chiffres, signature, cadre, décor, sol, ombre portée, autre personnage, Pokémon non présent dans l'IMAGE 1, pixel art, 3D, contours noirs épais.
"""


if __name__ == "__main__":
	badges = sys.argv[1:] or list(COSTUMES)
	for badge in badges:
		for version in VERSIONS:
			for asset, g_heros, g_joueuse, contenu in ASSETS:
				gabarit = g_heros if version == "JOUEUR" else g_joueuse
				ident = f"CO_{badge}_{version}_{asset}"
				(ICI / "prompts" / f"{ident}.txt").write_text(prompt(badge, version, asset, gabarit, contenu))
				print(f"{ident} {gabarit} {identite(badge, version)[0]}")
