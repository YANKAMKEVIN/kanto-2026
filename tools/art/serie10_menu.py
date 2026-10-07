#!/usr/bin/env python3
"""Série 10 — art du Menu Dresseur (MM.0, plan docs/tech/menu-maquettes.md).

Portrait peint du héros en buste, 6 illustrations des cartes du tableau de bord, icônes peintes
des objets (existants et prévus par les dossiers : Antidote au J9). Références : maquettes
docs/design/reference/menu-*-v1.jpg (DA seulement, règle 10), héros validé PERSO_P2_PEINT_r1.
Pokémon du menu = artworks officiels (déjà là), pas de génération.
Usage : tools/art/serie10_menu.py [IDENTIFIANT ...]   (sans argument : toute la série)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
ART = RACINE / "build" / "art"
PROMPTS = ART / "prompts"
REF = RACINE / "docs" / "design" / "reference"

RENDU = ("RENDU : illustration 2D peinte numériquement, dans le style d'un RPG Pokémon moderne « HD-2D "
	"peint » : formes simples et arrondies, contour fin et doux plus sombre que la couleur, aucun trait "
	"noir, volumes doux, couleurs chaudes et lumineuses, pinceau net. Ni pixel art, ni 3D, ni photo. "
	"Lumière douce de jour venant du haut à gauche.")
INTERDITS = "Interdit : texte, lettres, chiffres, logo (sauf l'emblème Poké Ball demandé), signature, filigrane, cadre."

# (identifiant, référence jointe ou None, format, description)
SERIE = [
	("MENU_HEROS_BUSTE", "menu-tableau-de-bord-v1.jpg", "PNG portrait 1024 × 1536, fond TRANSPARENT (canal alpha)",
		"le héros du jeu (EXACTEMENT celui de la planche jointe PERSO_P2_PEINT_r1 : casquette rouge et blanche, "
		"cheveux bruns, t-shirt blanc, gilet rouge, sac à dos) en portrait de trois quarts, de la tête à la "
		"taille, souriant et confiant, regard vers la gauche de l'image ; proportions d'illustration (pas chibi), "
		"comme le personnage de la maquette jointe. Seul, sans Pokémon, sans décor."),
	("MENU_CARTE_EQUIPE", "menu-tableau-de-bord-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Équipe » du menu : Bulbizarre, Salamèche et Carapuce côte à côte, joyeux, "
		"dans une prairie ensoleillée, cadrés en haut de l'image (le bas sera couvert par un titre)."),
	("MENU_CARTE_POKEDEX", "menu-tableau-de-bord-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Pokédex » : un Pokédex rouge moderne et arrondi, ouvert, posé dans l'herbe, "
		"cadré en haut de l'image, fond de végétation floue."),
	("MENU_CARTE_SAC", "menu-tableau-de-bord-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Sac » : un sac à dos de voyage jaune moutarde et brun avec un emblème Poké "
		"Ball, posé contre une souche, cadré en haut de l'image, fond de forêt floue."),
	("MENU_CARTE_CARTE", "menu-carte-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Carte » : vue aérienne peinte d'une région côtière verdoyante avec des "
		"villages, des routes, des montagnes et la mer turquoise, sans aucun nom écrit."),
	("MENU_CARTE_DRESSEUR", "menu-tableau-de-bord-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Dresseur » : une carte de Dresseur bleu clair posée de biais, avec une "
		"silhouette de profil et des emplacements ronds de badges vides, SANS aucun texte, fond violet doux "
		"et lumineux."),
	("MENU_CARTE_PARAMETRES", "menu-tableau-de-bord-v1.jpg", "PNG paysage 1536 × 1024, OPAQUE, cadrage plein",
		"illustration de la carte « Paramètres » : un grand engrenage gris argenté peint, en relief doux, sur "
		"un fond gris-bleu sombre et feutré, ambiance calme."),
	("MENU_OBJETS_PLANCHE", "menu-sac-v1.jpg", "PNG paysage 1536 × 1024, fond TRANSPARENT (canal alpha)",
		"PLANCHE de 4 icônes d'objets peintes, alignées sur une ligne, chacune dans une colonne invisible de "
		"384 px, bien séparées par du vide, même taille (environ 280 px) : 1) une Poké Ball rouge et blanche ; "
		"2) une Potion, flacon spray violet et blanc ; 3) un Antidote, flacon spray jaune et vert ; 4) un colis "
		"en papier kraft ficelé (colis pour le professeur). Vues de trois quarts, comme les objets de la maquette "
		"jointe."),
]


def _prompt(identifiant: str, fmt: str, description: str) -> str:
	return (f"{identifiant} — NOUVELLE image pour l'interface (menu) du jeu Kanto 2026, pas une capture d'écran.\n"
		"Les images jointes donnent la direction artistique ; n'en reproduis ni la mise en page ni les textes.\n\n"
		f"{RENDU}\n\nIMAGE : {description}\nFormat : {fmt}.\n{INTERDITS}\n")


def generer(entree) -> str:
	identifiant, ref, fmt, description = entree
	nom = f"{identifiant}_r1"
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(_prompt(identifiant, fmt, description))
	jointes = [str(ART / "PERSO_P2_PEINT_r1.png")] if identifiant == "MENU_HEROS_BUSTE" else []
	if ref:
		jointes.append(str(REF / ref))
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier), *jointes],
		cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-160:]}"


if __name__ == "__main__":
	choix = set(sys.argv[1:])
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(generer, [e for e in SERIE if not choix or e[0] in choix]):
			print(ligne, flush=True)
