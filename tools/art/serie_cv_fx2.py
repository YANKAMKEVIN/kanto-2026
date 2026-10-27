#!/usr/bin/env python3
"""Combat vivant, vague 2 d'art : ce dont le lot P1 a besoin et que la vague 1 n'a pas fait
(docs/tech/combat-vivant-lots.md, P1 = 40 attaques : contact, statuts, son, poison, vent, plante, eau).
Même chaîne que `serie_cv_fx.py` (qu'on importe et dont on remplace les listes) ; trois fonds selon la couleur :
noir (lumière, mélange additif), magenta (matière), vert (matière violette ou rose, que la clé magenta détruirait).
Usage : identique (--prompts, génération, --preparer, --planche). Fiche : docs/design/fiches-assets/serie-cv-fx-2.md"""
from __future__ import annotations

import sys

import serie_cv_fx as b

b.MANIFESTE = "manifeste_vague2.json"
b.TITRE = "CV.1 vague 2 (lot P1)"
b.FICHE = b.RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-2"
b.PROMPTS = b.ART / "prompts" / "cv_fx2"

b.FLIPBOOKS = [
	("bulles_eclatent", "norm", "BULLES QUI ÉCLATENT (Écume)",
		"une grappe de cinq à sept bulles de savon translucides de tailles variées, reflets blancs et arc-en-ciel "
		"pâle, bord fin bleuté, qui jaillissent vers la droite : image 1 trois petites bulles, puis la grappe "
		"grossit (2 à 4), certaines bulles éclatent en gouttelettes et en petits éclats d'écume (5 à 7), image 8 "
		"quelques gouttes seulement."),
	("nuage_poison", "vert", "NUAGE DE POISON (Purédpois / Poudre Toxik)",
		"un nuage de gaz toxique violet en bouffée ronde irrégulière centrée dans la case, avec des volutes et "
		"de petites bulles violettes qui y flottent ; il gonfle et se déforme doucement d'une image à l'autre "
		"(boucle). Cœur violet clair presque lilas, violet vif, bord pourpre sombre ; quelques taches rose-violet."),
	("giclee_poison", "vert", "GICLÉE DE POISON (Acide / Détritus)",
		"une giclée de liquide visqueux violet qui part du bord GAUCHE vers la droite, large d'environ le tiers "
		"de la case, avec des gouttes épaisses qui s'en détachent et des bulles qui éclatent à la surface ; le "
		"jet ondule d'une image à l'autre (boucle). Violet vif, reflets lilas clairs, bord pourpre sombre."),
	("tourbillon_vent", "norm", "TOURBILLON DE VENT (Tornade / Cyclone)",
		"un tourbillon de vent vu de côté, en spirale verticale centrée dans la case, fait de fines bandes d'air "
		"blanc-bleuté translucides et de quelques petites feuilles et plumes entraînées ; il tourne d'une image à "
		"l'autre : les bandes avancent le long de la spirale (boucle). Blanc, bleu glacé très pâle, bord bleu-gris."),
	("onde_sonore", "add", "ONDE SONORE (Rugissement / Berceuse / Ultrason)",
		"des ondes sonores : trois à cinq arcs concentriques lumineux qui partent du bord GAUCHE vers la droite "
		"et s'élargissent en s'éloignant ; image 1 un seul petit arc, image 8 grands arcs fins presque dissipés, "
		"entre-temps les arcs avancent et s'épaississent légèrement. Cœur blanc, bleu clair, bord bleu profond."),
	("fumee_volutes", "norm", "FUMÉE (Brouillard / retombée)",
		"un nuage de fumée grise en volutes arrondies, qui se lève et se déploie : image 1 petite bouffée à la "
		"base de la case, puis le nuage gonfle en volutes (2 à 5) et s'étire vers le haut-droite en s'effilochant "
		"(6 à 8). Gris-bleu clair au sommet, gris sombre aux creux, bords vaporeux."),
	("lumiere_soin", "add", "LUMIÈRE DE SOIN (Repos / Soin)",
		"une lumière de soin : une colonne douce de lumière verte qui monte, avec des petits brillants en forme "
		"de croix scintillantes qui s'élèvent et s'effacent, et un halo ; image 1 un halo au sol, puis la colonne "
		"se forme (2 à 4), brillants qui montent (5 à 7), image 8 presque éteinte. Cœur blanc, vert tendre, vert "
		"émeraude au bord."),
	("aura_montante", "add", "AURA MONTANTE (Armure / Croissance / Puissance)",
		"une aura qui monte autour d'un volume invisible centré dans la case : des flammèches de lumière blanc-"
		"bleutée qui s'élèvent en lignes verticales ondulantes, plus denses au centre, avec de petits points "
		"lumineux ; elles montent d'une image à l'autre (boucle). Cœur blanc, bleu clair, bord bleu profond. "
		"Aucun personnage ni silhouette dessinés."),
	("onde_choc", "add", "ONDE DE CHOC (Charge / contact « corps »)",
		"une onde de choc ronde vue de face, centrée dans la case : image 1 un point d'impact blanc, puis un "
		"anneau lumineux qui s'élargit (2 à 6), accompagné de fines stries rayonnantes et de petits éclats ; "
		"image 8 un grand anneau fin presque dissipé. Cœur blanc, jaune pâle, bord orange."),
	("entailles_griffes", "add", "ENTAILLES DE GRIFFES (Griffe / Tranche)",
		"trois entailles de griffes lumineuses, parallèles et légèrement courbes, qui apparaissent comme tracées "
		"d'un geste du haut-gauche vers le bas-droite : image 1 le début du tracé, entailles qui s'allongent "
		"(2 à 4), plein tracé avec éclats (5), puis qui s'éteignent en étincelles (6 à 8). Cœur blanc, bleu "
		"clair, bord bleu profond."),
	("jet_sable", "norm", "JET DE SABLE (Jet de Sable)",
		"un jet de sable qui part du bord GAUCHE vers la droite : un flot de petits grains beige-doré et de "
		"nuages de poussière fine, plus dense à gauche et plus épars à droite, qui ondule d'une image à l'autre "
		"(boucle). Beige doré, ombres brun clair, cœur crème."),
	("lianes_fouet", "norm", "LIANES FOUET (Fouet Lianes / Ligotage)",
		"deux lianes vertes souples avec quelques feuilles qui fouettent de la gauche vers la droite : image 1 "
		"lianes enroulées et tendues vers l'arrière, puis elles se déroulent (2 à 4), claquent avec une courbe en "
		"S (5 à 6), puis retombent (7 à 8). Verts du vert-jaune au vert sapin, nervures légères, bord plus sombre."),
]

b.PARTICULES = [
	("part_d", "add", [
		("brillant_soin", "un brillant de soin : petite croix scintillante à quatre branches, blanc, vert tendre, halo vert émeraude"),
		("fleche_haut", "une flèche lumineuse qui monte : chevron épais pointé vers le haut, blanc-bleuté, halo bleu clair, bord bleu profond"),
		("oeil_menacant", "un œil menaçant seul : œil en amande à la pupille fendue, lumineux rouge-orangé à cœur jaune, halo, sans visage autour"),
		("anneau_choc", "un anneau de choc : fin anneau lumineux régulier, blanc au cœur, jaune pâle, bord orange, vide au centre"),
		("bouclier_eclat", "un éclat de bouclier : hexagone translucide bleu-blanc avec reflet en diagonale, bord lumineux, vide à l'intérieur"),
		("note_musique", "une note de musique : croche peinte lumineuse, blanc-bleuté, halo bleu clair"),
		("croissant_coupe", "un croissant de coupe : mince croissant courbe lumineux, blanc, bord bleu-gris, pointes effilées"),
		("etincelle_bleue", "une étincelle électrique : petit éclat en Z lumineux à ramifications, blanc, jaune et bord bleu-violet"),
	]),
	("part_e", "norm", [
		("grain_sable", "un petit tas de grains de sable beige-doré projetés, quelques grains plus gros, éclats de lumière"),
		("fil_soie", "un fil de soie blanc-crème qui forme une boucle souple avec un petit nœud, fin et brillant"),
		("liane", "un segment de liane verte souple en S avec deux petites feuilles, vert-jaune à vert sapin"),
		("ecume", "un amas d'écume blanche : cinq petites bulles accolées, blanc, reflets bleutés pâles, bord bleu clair"),
		("gouttelettes", "une gerbe de cinq petites gouttes d'eau bleu clair, de tailles inégales, reflets blancs"),
		("epine", "une épine brun-vert, longue, effilée, avec une base arrondie, ombre propre brun-violet"),
		("lame_herbe", "une lame d'herbe verte longue et fine, incurvée, vert-jaune à vert sapin, nervure centrale"),
		("eclats_pierre", "trois petits éclats de pierre gris-bleu anguleux, arêtes éclairées, ombre propre brun-violet"),
	]),
	("part_f", "vert", [
		("bulle_poison", "une bulle de poison : sphère translucide violette, reflets lilas, bord pourpre sombre"),
		("goutte_poison", "une goutte de poison épaisse en poire, violette, reflet lilas, bord pourpre sombre"),
		("vapeur_poison", "une volute de vapeur toxique violet pâle, arrondie, bord vaporeux, cœur lilas"),
		("coeur", "un petit cœur rose vif, brillant, bord rose sombre, reflet blanc"),
		("orbe_ombre", "un orbe d'ombre : sphère violet-noir avec un halo violet sombre vaporeux et un reflet pâle"),
		("fleche_bas", "une flèche qui descend : chevron épais pointé vers le bas, rose-violet vif, bord pourpre sombre, léger halo"),
		("oeil_psy", "un œil psychique seul : œil en amande rose vif à pupille ronde claire, halo rose-violet, sans visage autour"),
		("anneau_psy", "un anneau psychique : fin anneau rose-violet lumineux, plus clair au cœur, bord pourpre, vide au centre"),
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
