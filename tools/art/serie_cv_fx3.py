#!/usr/bin/env python3
"""Combat vivant, art de la vague 2 « Effets fidèles à Rouge » (2026-11-04) : ce que les 22 lignes de l'audit
demandent et que les vagues d'art 1 et 2 n'ont pas (pièces de Jackpot, œuf, cuiller, pince, rochers, langue,
coquille, foudre qui tombe du ciel, explosion, fissure…). Même chaîne que `serie_cv_fx.py` (qu'on importe et dont
on remplace les listes) ; trois fonds selon la couleur : noir (lumière, mélange additif), magenta (matière), vert
(matière rose ou violette, que la clé magenta détruirait).
Usage : identique (--prompts, génération, --preparer, --planche). Manifeste : manifeste_vague3.json."""
from __future__ import annotations

import sys

import serie_cv_fx as b

b.MANIFESTE = "manifeste_vague3.json"
b.TITRE = "Effets fidèles à Rouge, vague 2"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-3"
b.PROMPTS = b.ART / "prompts" / "cv_fx3"

b.FLIPBOOKS = [
	("explosion", "add", "EXPLOSION (Explosion / Destruction / Bomb'Œuf)",
		"une explosion vue de face, centrée dans la case : image 1 un point blanc éblouissant, puis une boule de feu "
		"ronde qui enfle (2 à 4) avec des langues de feu et des éclats projetés en étoile, puis elle se déchire en "
		"volutes de flammes orangées (5 à 6) qui s'assombrissent en fumée rousse (7 à 8). Cœur blanc-jaune, orange "
		"vif, bord rouge sombre ; la fumée finale reste lumineuse sur ses bords."),
	("foudre", "add", "FOUDRE QUI TOMBE DU CIEL (Fatal-Foudre)",
		"un éclair VERTICAL qui tombe du HAUT de la case jusqu'en BAS, large d'environ le quart de la case, tronc "
		"principal brisé en zigzag avec deux ou trois ramifications ; d'une image à l'autre le tracé se reforme "
		"différemment et crépite (boucle) ; au bas de la case, un petit éclat en étoile là où il frappe. Cœur blanc "
		"pur, jaune électrique, bord bleu-violet."),
	("fissure", "norm", "FISSURE QUI S'OUVRE DANS LE SOL (Abîme)",
		"une crevasse vue de trois quarts, posée à plat dans la moitié basse de la case : image 1 une fine fêlure "
		"sombre, puis elle s'élargit en zigzag (2 à 5), ses lèvres de terre brune se soulèvent, des mottes et de la "
		"poussière jaillissent (5 à 7), image 8 une large crevasse noire aux bords éboulés. Terre brun clair, "
		"brun-roux, fond de la crevasse brun très sombre presque noir ; aucune herbe, aucun décor autour."),
]

b.PARTICULES = [
	("part_g", "norm", [
		("piece_or", "une pièce d'or ronde vue légèrement de biais, tranche épaisse visible, gravure en relief simple, reflet blanc, or chaud et bord brun doré"),
		("oeuf", "un œuf crème légèrement ovale, quelques taches beige, reflet blanc, ombre propre brun clair"),
		("cuiller", "une cuiller argentée à long manche, tordue au milieu à angle d'environ trente degrés, reflets bleutés et blancs, ombre propre gris-bleu"),
		("pince", "une grosse pince de crabe rouge-orangé, ouverte, deux mâchoires dentelées, reflets crème, ombre propre brun-rouge"),
		("rocher", "un gros rocher gris-brun anguleux, arêtes éclairées, quelques fissures, ombre propre brun-violet"),
		("motte_terre", "une motte de terre brune humide avec quelques petits cailloux, bords effrités, ombre propre brun sombre"),
		("boulet", "une boule ronde et lisse beige clair, comme une graine dure, reflet blanc, ombre propre brun clair"),
		("coquille_oeuf", "trois éclats de coquille d'œuf crème, courbes, bords cassés, intérieur blanc, ombre propre beige"),
	]),
	("part_h", "vert", [
		("langue", "une longue langue rose vif tirée et légèrement recourbée vers le haut, humide et brillante, reflet blanc, bord rose sombre"),
		("coquille", "une demi-coquille de bivalve violette nacrée, côtes rayonnantes, bord crénelé, reflets lilas et blancs, ombre propre pourpre"),
		("fumee_noire", "une bouffée ronde de fumée noire épaisse en volutes, gris anthracite, reflets gris clair sur le dessus, bords vaporeux"),
		("smog", "une bouffée de fumée toxique brun-violet sale, volutes lourdes, cœur mauve terne, bord brun sombre vaporeux"),
		("brume", "une nappe de brume sombre gris-violet, allongée à l'horizontale, très vaporeuse, bords effilochés"),
		("salive", "trois gouttes de salive transparentes bleu très pâle, brillantes, reflet blanc"),
		("goutte_cascade", "un filet d'eau qui tombe verticalement, épais en haut, éclaté en gouttes en bas, bleu clair, reflets blancs, bord bleu profond"),
		("eclat_rose", "un petit éclat de lumière rose et lilas en étoile à quatre branches, cœur blanc, bord rose sombre"),
	]),
	("part_i", "add", [
		("eclair_vertical", "un éclair vertical en zigzag, tronc brisé avec une petite ramification, cœur blanc, jaune électrique, bord bleu-violet"),
		("orbe_folie", "une lueur étrange : sphère lumineuse irisée qui change de couleur du jaune au rose et au cyan, cœur blanc, halo arc-en-ciel pâle"),
		("etincelle_or", "un scintillement doré : petite étoile à quatre branches fines, cœur blanc, or chaud, halo ambré"),
		("eclat_explosion", "un éclat d'explosion : étoile à huit branches irrégulières, cœur blanc éblouissant, jaune, orange, bord rouge"),
		("etoile_filante", "une étoile à cinq branches lumineuse avec une courte traînée de lumière derrière elle vers la gauche, cœur blanc, jaune pâle, bord doré"),
		("flash_blanc", "une lueur blanche ronde très douce et éblouissante, cœur blanc pur, halo blanc-bleuté qui s'estompe"),
		("anneau_folie", "un anneau de lumière irisé, fin, régulier, du rose au cyan et au jaune, vide au centre"),
		("braise_explosion", "une braise d'explosion : petit fragment incandescent orange avec une traînée de fumée lumineuse, cœur jaune"),
	]),
]

if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		b.prompts()
	elif a[:1] == ["--preparer"]:
		b.preparer()
	elif a[:1] == ["--planche"]:
		b.planche()
	else:
		b.generer(a)
