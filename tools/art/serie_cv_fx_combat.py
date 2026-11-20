#!/usr/bin/env python3
"""Refonte des attaques Combat (direction A « impact peint » : ondes de choc et étoiles d'impact blanc crème aux bords
déchirés, traînées de pinceau, poussière ocre, touches orange chaud ; docs/tech/attaques-combat.md). Même chaîne et mêmes
cadrages que `serie_cv_fx_glace.py`. Les marques, arcs, ondes et la poussière sont détourés sur MAGENTA (`norm`, aucun
magenta dans l'effet) et posés en mélange normal ; l'aura de Contre, la garde de Riposte et les étincelles restent
additives sur noir. Les consignes ne décrivent que des formes d'énergie (Codex refuse les scènes de coups).
Usage : identique à serie_cv_fx.py (--prompts, génération, --preparer, --planche). Manifeste : manifeste_combat.json."""
from __future__ import annotations

import sys

import serie_cv_fx as b
import serie_cv_fx_eau as eau

b.MANIFESTE = "manifeste_combat.json"
b.TITRE = "Attaques Combat, direction A"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-combat"
b.PROMPTS = b.ART / "prompts" / "cv_fx_combat"

ADN_A = """ADN VISUEL — IMPACT PEINT (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la main d'un RPG 2D HD moderne tout public : coups de pinceau visibles, légère granularité picturale, matière DENSE, bords déchirés au pinceau, contraste fort. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni rendu de moteur de particules.
- Couleur : BLANC pur et crème pour les cœurs et les ondes, jaune pâle et ORANGE CHAUD pour l'éclat et les liserés, ocre et brun clair pour la poussière et la terre. AUCUN magenta, AUCUN rose, AUCUN violet, AUCUN vert, AUCUN bleu.
- Lumière NEUTRE : l'effet est éclairé de façon neutre ; aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucune créature, aucun membre, aucune main, aucun pied.
- Interdits : texte, lettres, chiffres, onomatopées, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

## (identifiant, mode, cadrage, once, côté préparé, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("etoile_choc", "norm", "carre", True, 384, "ÉTOILE D'ÉCLAT",
		"une étoile d'éclat centrée, jouée UNE fois : image 1 un point blanc, images 2 à 4 une grande étoile blanche et "
		"crème à huit branches inégales aux bords déchirés au pinceau jaillit, liseré orange chaud, petits éclats blancs "
		"qui volent, images 5 à 7 l'étoile se disloque en traits de pinceau et en poussière crème, image 8 quelques "
		"éclats seulement."),
	("explosion_choc", "norm", "carre", True, 384, "GRANDE EXPLOSION D'ÉCLAT",
		"une énorme explosion d'éclat centrée, jouée UNE fois : image 1 un point blanc, images 2 à 4 une gerbe de longs "
		"rayons blancs et crème aux bords déchirés jusqu'aux bords de la case, anneau d'onde blanc, cœur jaune pâle et "
		"orange chaud, éclats de pierre ocre qui volent, images 5 à 7 les rayons se brisent en traînées de pinceau et en "
		"poussière ocre, image 8 de la poussière seulement."),
	("arc_tranchant", "norm", "carre", True, 384, "ARC LUMINEUX EN CROISSANT",
		"un arc lumineux en CROISSANT qui balaie la case en diagonale, du coin HAUT GAUCHE vers le coin BAS DROIT, joué UNE "
		"fois : image 1 un fin trait blanc en haut à gauche, images 2 à 4 le croissant épais blanc et crème au liseré "
		"orange se déploie en un grand arc de pinceau net, images 5 à 7 il s'effiloche en traits de pinceau, petite étoile "
		"blanche à son extrémité, image 8 quelques traits seulement."),
	("arc_rasant", "norm", "bande", True, 384, "ARC RASANT HORIZONTAL",
		"un arc lumineux RASANT et horizontal, du bord GAUCHE exact jusqu'au bord DROIT exact de la bande, légèrement "
		"courbé vers le haut à droite, joué UNE fois : image 1 un trait blanc à gauche, images 2 à 4 l'arc épais blanc et "
		"crème au liseré orange file vers la droite, poussière ocre soulevée sous lui, images 5 à 7 il s'effiloche, la "
		"poussière retombe, image 8 de la poussière seulement."),
	("arc_circulaire", "norm", "carre", True, 384, "ARC CIRCULAIRE EN SPIRALE",
		"un GRAND ARC CIRCULAIRE de lumière qui tourne autour du centre, en ellipse inclinée qui occupe 85 % de la case, "
		"joué UNE fois : image 1 un trait blanc à gauche, images 2 à 4 la traînée blanche et crème au liseré orange fait "
		"presque un tour complet en s'épaississant, images 5 à 7 elle s'effiloche en traits de pinceau et en spirale, "
		"image 8 quelques traits seulement. LE CENTRE RESTE VIDE (fond)."),
	("onde_sol", "norm", "bande", True, 384, "ONDE DE CHOC AU SOL",
		"une ONDE DE CHOC au sol vue en perspective : un anneau elliptique très aplati, horizontal, centré, joué UNE fois : "
		"image 1 un petit anneau blanc au centre, images 2 à 5 l'anneau blanc et crème au liseré orange s'élargit jusqu'aux "
		"bords gauche et droit de la bande, poussière ocre et petits cailloux soulevés tout autour, images 6 à 8 l'anneau "
		"s'efface, la poussière retombe. L'INTÉRIEUR DE L'ANNEAU RESTE VIDE (fond)."),
	("trainee_vitesse", "norm", "bande", False, 384, "TRAÎNÉE DE VITESSE",
		"UNE TRAÎNÉE DE VITESSE horizontale, du bord GAUCHE exact jusqu'au bord DROIT exact de la bande, sans interruption : "
		"faisceau de longs traits de pinceau blancs et crème, liserés orange chaud, plus dense et plus large à DROITE, "
		"effilé à gauche, petits éclats blancs le long. Épaisseur environ la moitié de la hauteur de la bande. Boucle : "
		"les traits filent vers la droite d'une image à l'autre."),
	("aura_combat", "add", "carre", False, 320, "AURA FLAMBOYANTE",
		"une AURA d'énergie flamboyante en forme d'ovale vertical qui occupe 85 % de la case : grandes flammèches de lumière "
		"orange vif, jaune et blanc qui montent tout autour du contour, étincelles qui s'en échappent vers le haut. "
		"L'INTÉRIEUR RESTE VIDE ET NOIR. Boucle : les flammèches montent et ondulent."),
	("garde_choc", "add", "carre", False, 320, "BOUCLIER LUMINEUX DE GARDE",
		"un BOUCLIER de lumière en forme d'ovale vertical bombé qui occupe 85 % de la case : panneau translucide de lumière "
		"crème et jaune pâle à fines facettes hexagonales, contour épais orange chaud, éclats blancs sur le bord, "
		"étincelles autour. Le centre est plus transparent que le bord. Boucle : la lumière glisse sur les facettes et le "
		"contour scintille."),
	("nuage_poussiere", "norm", "carre", True, 384, "NUAGE DE POUSSIÈRE",
		"un gros NUAGE DE POUSSIÈRE ocre et brun clair qui jaillit du bas de la case, joué UNE fois : image 1 une petite "
		"bouffée au bas, images 2 à 4 le nuage gonfle en grosses volutes peintes vers les côtés et vers le haut, petits "
		"cailloux qui volent, images 5 à 7 il s'étale et s'éclaircit, image 8 une poussière légère. Volutes épaisses aux "
		"bords effilochés."),
]

b.PARTICULES = [
	("part_g", "norm", [
		("caillou_ocre", "UN petit caillou gris ocre arrondi, peint, reflet clair"),
		("motte_ocre", "une petite motte de terre brune qui s'effrite"),
		("poussiere_ocre", "une bouffée de poussière ocre et brun clair, volutes douces"),
		("eclat_roche", "UN éclat de roche anguleux gris brun, arêtes claires"),
		("fumee_choc", "une volute de fumée crème claire, épaisse, bords effilochés"),
		("trait_elan", "UN long trait de pinceau blanc et crème horizontal, effilé aux deux bouts, liseré orange"),
		("eclat_creme", "UN éclat blanc et crème en forme de pointe, aux bords déchirés, liseré orange"),
		("arc_court", "UN petit arc de pinceau blanc et crème en croissant, liseré orange"),
	]),
	("part_h", "add", [
		("etincelle_choc", "une étincelle blanche et orange à quatre branches fines"),
		("eclat_choc_blanc", "une petite étoile de lumière blanche à huit branches, halo orange doux"),
		("flammeche_aura", "UNE flammèche de lumière orange vif et jaune qui monte, pointe vers le haut"),
		("scintille_choc", "trois petits scintillements blancs en étoile"),
		("braise_aura", "une petite braise ronde orange vif, halo doux"),
		("lueur_choc", "une lueur ronde très douce, orange pâle, qui s'estompe jusqu'au noir"),
		("eclair_riposte", "UN court éclair de lumière blanche et jaune pâle, horizontal, en zigzag léger"),
		("contact_choc", "une étoile de choc à huit branches fines de lumière blanche et orange, cœur blanc éclatant, "
			"anneau de choc orange pâle autour"),
	]),
]
b.FLIPBOOKS = [(i, m, t, c) for i, m, _ca, _o, _co, t, c in FLIPBOOKS]
## La préparation de `serie_cv_fx_eau` lit `_INFO`, `_BORDS` et `_QUATRE_COLONNES` dans son module.
eau._INFO.clear()
eau._INFO.update({i: (ca, o, co) for i, _m, ca, o, co, _t, _c in FLIPBOOKS})
eau._BORDS.clear()
eau._BORDS.update({"nuage_poussiere", "arc_rasant"})
eau._QUATRE_COLONNES.clear()
eau.ADN_A = ADN_A


if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		b.prompts()
	elif a[:1] == ["--preparer"]:
		eau.preparer()
	elif a[:1] == ["--planche"]:
		b.planche()
	else:
		b.generer(a)
