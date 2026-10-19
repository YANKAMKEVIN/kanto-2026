#!/usr/bin/env python3
"""Construit les prompts des planches de personnages du J18 (même gabarit que serie15 PNJ_*)."""
import os
ICI = os.path.dirname(os.path.abspath(__file__))
MODELE = os.path.join(ICI, "..", "serie15", "PNJ_HABITANTE_NE_r1.txt")
t = open(MODELE, encoding="utf-8").read().split("\n")
LUMIERE, TAIL = t[2], "\n".join(t[6:])
STYLE = ("Style : exactement le rendu de la planche jointe PERSO_P2_PEINT_r1 (le héros validé) ; "
	"PNJ_RANDONNEUSE_NE_r1 = autre personnage de la série, même main, même finesse, mêmes proportions "
	"(référence de facture, pas de tenue) : personnage peint simplifié, chibi d'environ 3 têtes, même "
	"finesse, même contour fin coloré sans trait noir, mêmes proportions, même manière de peindre le "
	"visage et les vêtements. Ni pixel art, ni 3D, ni anime aux contours noirs. Le personnage ne "
	"ressemble PAS au héros joint (autre visage, autres couleurs, autre tenue).")
PERSOS = {
	"PNJ_POKEMANIAC_NE": "un Pokémaniac, jeune adulte d'environ 24 ans, passionné et un peu timide, l'air "
		"enthousiaste : cheveux bruns en bataille, LUNETTES RONDES à fine monture, chemise À CARREAUX "
		"rouge brique et crème (manches courtes, boutonnée, col ouvert) sur un t-shirt blanc, pantalon "
		"de toile beige, baskets brunes usées, et un GRAND SAC À DOS vert mousse très rempli, plus large "
		"que ses épaules, à deux poches latérales, d'où dépasse un coin de carnet (sans texte). Lisible de "
		"dos comme de face grâce au sac. Différent du héros (ni casquette rouge, ni t-shirt blanc "
		"seul, ni sac jaune), du Randonneur et du Scout (pas de chapeau, pas de vert olive d'uniforme).",
	"PNJ_EXORCISTE_NE": "une Exorciste, femme d'environ 30 ans, sereine et digne, le regard doux, un "
		"léger sourire calme : cheveux brun foncé attachés en un chignon bas, recouverts d'un court VOILE "
		"blanc crème léger qui retombe dans le dos, une longue TUNIQUE crème à manches longues sous un "
		"scapulaire sobre gris-violet foncé (deux pans, devant et dans le dos) serré d'une ceinture de "
		"corde tressée, un CHAPELET de perles de bois brun clair autour du cou et des doigts, souliers "
		"plats sombres. Ton de peau chaud, joues légèrement colorées : elle est apaisante, JAMAIS "
		"effrayante, rien de pâle, de spectral ni de sombre autour du visage. Silhouette de servante de "
		"prière, couleurs sobres et douces (crème, gris-violet, brun).",
}
POSES = {
	"PNJ_POKEMANIAC_NE": "", "PNJ_EXORCISTE_NE": "",
}
SUP = ("Interdits supplémentaires : fantôme, spectre, halo, lueur surnaturelle, croix, symbole religieux "
	"réel, crâne, squelette, visage blafard, yeux vides.")
for n, p in PERSOS.items():
	txt = "\n".join([f"{n[:-3]} — planche d'animation de marche d'un PNJ de Kanto 2026.", STYLE, LUMIERE, "",
		f"PERSONNAGE (identique dans toutes les images) : {p}", "", TAIL])
	if "EXORCISTE" in n:
		txt += "\n" + SUP
	open(os.path.join(ICI, f"{n}_r1.txt"), "w", encoding="utf-8").write(txt)
