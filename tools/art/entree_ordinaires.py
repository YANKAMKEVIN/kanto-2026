#!/usr/bin/env python3
"""Étape 4 de l'entrée des combats de Dresseur : les classes de Dresseurs ordinaires (fiche
docs/design/fiches-assets/entree-dresseurs.md §1 et §12). Pilote : le Gamin (déjà peint).

  tools/art/entree_ordinaires.py refs                      # références → build/art/ordinaires/
  tools/art/entree_ordinaires.py prompts                   # prompts → tools/art/entree_dresseurs/ordinaires/
  tools/art/entree_ordinaires.py generer sbires [r]        # une planche (deux classes) via Codex
  tools/art/entree_ordinaires.py exporter [planche ...]    # détourage, toiles, WebP, mains, scale
  tools/art/entree_ordinaires.py mains                     # « hand » et « scale » → trainer_intro.json

Une planche = UNE image portrait 1024 × 1536 avec deux classes, une rangée par classe (à gauche
debout prêt, à droite lancer), dans la main de Pierre et du Gamin (IMAGES 1 et 2) ; IMAGES 3 et 4
= apparence du monde de chaque classe (face et profil de sa feuille peinte) quand elle est fidèle à
la classe. Une planche d'une seule classe reprend le gabarit des Champions (paysage 1536 × 1024).
Main du lancer (règle des grands combats, fiche §11) : bout des doigts + (0,061 ; 0,114), en part
de la hauteur de la toile depuis le milieu des pieds.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_champions as ec  # noqa: E402
import entree_dresseurs as ed  # noqa: E402
import entree_grands_combats as eg  # noqa: E402

RACINE = ed.RACINE
OR = ed.ART / "ordinaires"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "ordinaires"
MONDE = ec.MONDE
INTRO = RACINE / "data" / "battle" / "trainer_intro.json"
MAIN_DECALAGE = (0.061, 0.114)

# id → (feuille du monde fidèle à la classe ou None, scale [D], description, pose debout, lancer)
CLASSES: dict[str, tuple] = {
	"sbire_rocket": ("sbire_h", 1.16,
		"un SBIRE de la Team Rocket (homme d'environ 25 ans, carrure ordinaire, air arrogant de "
		"petite frappe, cheveux sombres courts) : CASQUETTE NOIRE, uniforme NOIR à manches longues "
		"avec un grand « R » ROUGE sur la poitrine, GANTS GRIS CLAIR, ceinture grise, pantalon noir, "
		"BOTTES GRISES montantes",
		"poings sur les hanches, menton levé, sourire mauvais",
		"geste brusque et agressif"),
	"sbire_rocket_f": ("sbire_f", 1.12,
		"une SBIRE de la Team Rocket (femme d'environ 22 ans, mince, air méprisant, cheveux sombres "
		"courts qui dépassent de la casquette) : CASQUETTE NOIRE, uniforme NOIR à manches longues avec "
		"un grand « R » ROUGE sur la poitrine, GANTS GRIS CLAIR, ceinture grise, pantalon noir, BOTTES "
		"GRISES montantes (même uniforme que le sbire homme)",
		"une main sur la hanche, l'autre pointant l'index vers la gauche, sourire narquois",
		"geste sec et méprisant"),
	"jeune_dresseuse": ("dresseuse", 1.05,
		"une JEUNE DRESSEUSE (fille d'environ 13 ans, sportive et décidée) : cheveux CHÂTAINS en "
		"queue de cheval, BANDEAU JAUNE, veste ORANGE sans manches ouverte sur un t-shirt blanc, short "
		"en jean, chaussettes blanches, baskets blanches et bleues",
		"poings serrés devant elle, prête à se battre, sourire décidé",
		"queue de cheval qui suit le mouvement"),
	"fillette": ("fillette", 1.0,
		"une FILLETTE (petite fille d'environ 10 ans, gaie) : longs cheveux CHÂTAINS ondulés, "
		"BARRETTE-FLEUR rose, ROBE BLEU CLAIR à col blanc, petit SAC ROSE en bandoulière, chaussettes "
		"blanches, chaussures marron",
		"mains jointes derrière le dos, buste penché en avant, sourire espiègle",
		"robe et cheveux qui volent, petit lancer enthousiaste"),
	"nageur": ("nageur", 1.16,
		"un NAGEUR (homme d'environ 20 ans, athlétique, bronzé) : cheveux CHÂTAINS en bataille, "
		"LUNETTES DE NATATION bleues relevées sur le front, SERVIETTE BLANCHE autour du cou, short de "
		"bain BLEU à liseré blanc, torse nu, sandales",
		"une main tenant le bout de la serviette, l'autre poing serré, sourire sportif",
		"serviette qui vole"),
	"nageuse": ("nageuse", 1.10,
		"une NAGEUSE (jeune femme d'environ 19 ans, sportive) : cheveux CHÂTAINS en chignon haut, "
		"LUNETTES DE NATATION bleues relevées sur le front, MAILLOT une pièce TURQUOISE, PARÉO BLANC "
		"noué à la taille, tongs blanches",
		"une main sur la hanche, l'autre réglant ses lunettes sur le front, sourire assuré",
		"paréo qui flotte"),
	"scientifique": ("chercheur", 1.16,
		"un SCIENTIFIQUE (homme d'environ 40 ans, sérieux, un peu inquiétant) : cheveux NOIRS courts "
		"grisonnants aux tempes, LUNETTES rondes, longue BLOUSE BLANCHE de laboratoire, pull sans "
		"manches VERT sur chemise blanche, cravate sombre, pantalon gris, chaussures marron, stylo "
		"dans la poche",
		"une main remontant ses lunettes, l'autre bras le long du corps, regard calculateur",
		"pans de la blouse qui volent"),
	"chercheur": ("chercheur", 1.12,
		"un CHERCHEUR (jeune homme d'environ 25 ans, curieux et passionné de fossiles) : cheveux NOIRS "
		"en bataille, LUNETTES rondes, BLOUSE BLANCHE ouverte, pull sans manches VERT, pantalon gris, "
		"carnet de notes brun",
		"carnet de notes tenu contre la poitrine d'une main, l'autre main levée, air enthousiaste",
		"blouse qui vole, le carnet gardé dans l'autre main"),
	"exorciste": ("exorciste", 1.06,
		"une EXORCISTE (femme d'environ 50 ans, mystique, yeux mi-clos) : VOILE CRÈME qui encadre le "
		"visage et tombe sur les épaules, longue ROBE BRUN SOMBRE, tablier plus foncé, gros CHAPELET "
		"de perles de bois au cou, sandales",
		"mains jointes en prière devant la poitrine, chapelet entre les doigts, tête un peu baissée",
		"voile et chapelet qui volent, geste habité"),
	"medium": (None, 1.14,
		"un MÉDIUM, dresseur de Pokémon Psy de l'Arène de Safrania (jeune homme d'environ 20 ans, "
		"mince, mystérieux) : cheveux NOIRS mi-longs qui tombent sur un œil, regard fixe, longue "
		"TUNIQUE VIOLET SOMBRE à col montant et liserés dorés, ceinture d'étoffe, pantalon noir ample, "
		"chaussures noires",
		"deux doigts posés sur la tempe, l'autre bras tendu vers le bas paume ouverte, concentré",
		"tunique soulevée comme par une force psychique"),
	"motard": ("motard", 1.20,
		"un MOTARD (homme d'environ 25 ans, frimeur) : banane NOIRE gominée, LUNETTES NOIRES, "
		"BLOUSON DE CUIR NOIR ouvert sur un t-shirt ROUGE, gants de cuir sans doigts, jean noir, "
		"bottes de moto noires",
		"pouces dans les poches du blouson, épaules roulées, sourire provocant",
		"blouson qui claque"),
	"loubard": ("loubard", 1.24,
		"un LOUBARD (homme d'environ 30 ans, massif et costaud) : CRÂNE CHAUVE luisant, barbe courte "
		"brune, sourcils froncés, GILET DE CUIR NOIR sans manches sur un débardeur blanc, bras "
		"musclés, pantalon cargo noir, ceinture cloutée, rangers noires",
		"poings serrés devant le torse, épaules massives, regard menaçant",
		"lancer brutal, muscles tendus"),
	"ornithologue": ("ornithologue", 1.16,
		"un ORNITHOLOGUE (homme d'environ 35 ans) : CHAPEAU de brousse VERT OLIVE avec une PLUME "
		"BLEUE, barbe courte brune, JUMELLES au cou, gilet bleu-vert sur chemise beige, pantalon "
		"beige, bottes de marche",
		"une main tenant les jumelles devant la poitrine, l'autre sur la hanche, sourire bienveillant",
		"plume du chapeau qui bouge"),
	"scout": ("scout", 1.0,
		"un SCOUT, chasseur d'insectes (garçon d'environ 10 ans) : CHAPEAU DE PAILLE, gilet VERT "
		"olive à poches sur t-shirt blanc, short beige, petite BOÎTE VERTE en bandoulière, chaussettes "
		"blanches, baskets vertes, FILET À PAPILLONS",
		"filet à papillons tenu droit dans une main, l'autre poing serré, grand sourire",
		"filet gardé dans l'autre main, chapeau qui se soulève"),
	"karateka": (None, 1.22,
		"un KARATÉKA (homme d'environ 28 ans, très musclé) : cheveux noirs courts, BANDEAU BLANC noué "
		"au front, KARATÉGI BLANC un peu ouvert sur le torse, CEINTURE NOIRE, PIEDS NUS",
		"garde de karaté, poings serrés, jambes fléchies, cri de concentration",
		"lancer puissant, karatégi qui claque"),
	"maitre_dojo": (None, 1.24,
		"le MAÎTRE DU DOJO de Safrania (homme d'environ 50 ans, trapu, très fort et digne) : crâne "
		"rasé, épaisse MOUSTACHE et barbiche grises, sourcils broussailleux, KARATÉGI BLANC à revers "
		"NOIRS, vieille CEINTURE NOIRE effilochée, PIEDS NUS",
		"bras croisés, jambes bien ancrées, regard sévère et calme",
		"lancer puissant et maîtrisé"),
	"montagnard": ("montagnard", 1.26,
		"un MONTAGNARD (homme d'environ 40 ans, corpulent, jovial) : BOB KAKI, épaisse barbe brune, "
		"CHEMISE À CARREAUX ROUGES aux manches retroussées, GROS SAC À DOS vert avec couverture "
		"roulée, pantalon olive, chaussures de marche",
		"poings sur les hanches, ventre en avant, grand rire",
		"sac à dos qui ballotte, lancer puissant"),
	"pokemaniac": ("pokemaniac", 1.12,
		"un POKÉMANIAC (jeune homme d'environ 20 ans, passionné un peu fébrile) : cheveux BRUNS en "
		"bataille, LUNETTES rondes, CHEMISE À CARREAUX rouges ouverte sur un t-shirt blanc, petit SAC "
		"À DOS olive, pantalon beige, baskets",
		"poings serrés près du menton, yeux brillants d'excitation",
		"lunettes qui brillent, geste fébrile"),
	"topdresseur": ("topdresseur", 1.14,
		"un TOPDRESSEUR, dresseur d'élite (homme d'environ 20 ans, confiant) : cheveux NOIRS en épis, "
		"regard intense, VESTE DE SURVÊTEMENT VERT FONCÉ à bandes blanches ouverte sur un t-shirt "
		"noir, gants sans doigts, pantalon noir, baskets noires et blanches",
		"bras croisés sur la poitrine, poids sur une jambe, sourire confiant (AUCUN bras tendu)",
		"veste qui claque"),
	"topdresseuse": ("topdresseuse", 1.10,
		"une TOPDRESSEUSE, dresseuse d'élite (jeune femme d'environ 19 ans, confiante) : longue QUEUE "
		"DE CHEVAL ROUSSE, VESTE COURTE BLEU MARINE ouverte sur un top blanc, mini-short noir, gants "
		"sans doigts, bottines noires",
		"une main sur la hanche, l'autre écartant une mèche, sourire assuré",
		"queue de cheval qui fouette l'air"),
	"jongleur": (None, 1.16,
		"un JONGLEUR, artiste de cirque (homme d'environ 30 ans, mince et théâtral) : cheveux NOIRS "
		"gominés, fine moustache, GILET À LOSANGES ROUGES ET JAUNES, chemise blanche à manches "
		"bouffantes, NŒUD PAPILLON, pantalon VIOLET, souliers pointus noirs",
		"une main levée tenant trois petites BALLES DE JONGLAGE rouge, jaune et bleue (pas des Poké "
		"Balls), l'autre main sur la hanche, sourire de showman",
		"geste théâtral de prestidigitateur"),
	"joueur": ("parieur", 1.18,
		"un JOUEUR, parieur (homme d'environ 45 ans, rusé) : FEDORA MARRON à ruban, fine MOUSTACHE "
		"noire, veste marron, GILET MOUTARDE, chemise blanche, cravate sombre, pantalon noir, souliers "
		"marron",
		"un gros DÉ blanc tenu entre deux doigts, l'autre main sur le revers de la veste, sourire en "
		"coin",
		"geste de joueur qui lance les dés"),
	"pillard": (None, 1.18,
		"un PILLARD, cambrioleur (homme d'environ 35 ans, louche) : BONNET NOIR, LOUP NOIR sur les "
		"yeux, barbe de trois jours, PULL RAYÉ gris foncé et noir, gants noirs, pantalon sombre, "
		"SAC DE TOILE beige en bandoulière dans le dos",
		"accroupi à demi, mains en avant doigts crochus, sourire de voleur",
		"geste furtif et vif"),
	"dompteur": ("docker", 1.24,
		"un DOMPTEUR (homme d'environ 45 ans, robuste et bourru) : BONNET GRIS, barbe brune épaisse, "
		"chemise VERT OLIVE aux manches retroussées, SALOPETTE OCRE, gants de cuir, FOUET enroulé "
		"accroché à la ceinture, bottes brunes",
		"une main tenant le fouet enroulé, l'autre poing sur la hanche, air bourru",
		"fouet gardé dans l'autre main"),
	"marin": ("marin", 1.20,
		"un MARIN (homme d'environ 25 ans, musclé, jovial) : BACHI BLANC de marin, cheveux noirs "
		"courts, haut blanc à COL MARIN BLEU MARINE à liserés blancs, FOULARD ROUGE noué, pantalon "
		"bleu marine, chaussures noires",
		"poings sur les hanches, torse bombé, grand sourire",
		"col marin qui claque, lancer vigoureux"),
	"gentleman": ("gentleman", 1.14,
		"un GENTLEMAN (homme âgé d'environ 65 ans, distingué) : CHAPEAU MELON noir, cheveux et "
		"MOUSTACHE BLANCS, costume trois pièces NOIR, cravate bleue, gants blancs, CANNE noire à "
		"pommeau d'argent, souliers vernis",
		"les deux mains posées sur le pommeau de la canne devant lui, port droit, sourire poli",
		"canne gardée dans l'autre main, geste élégant"),
	"pecheur": ("pecheur", 1.18,
		"un PÊCHEUR (homme d'environ 55 ans, bonhomme) : BOB BEIGE, barbe grise courte, GILET DE "
		"PÊCHE VERT OLIVE multipoches sur une chemise bleue, pantalon kaki, bottes de caoutchouc "
		"vertes, CANNE À PÊCHE",
		"canne à pêche tenue debout dans une main, l'autre pouce levé, sourire tranquille",
		"canne gardée dans l'autre main"),
	"ingenieur": ("ingenieur", 1.20,
		"un INGÉNIEUR (homme d'environ 35 ans, solide) : CASQUE DE CHANTIER JAUNE avec LUNETTES DE "
		"PROTECTION relevées, t-shirt ORANGE, SALOPETTE BLEUE, ceinture à outils, gants de travail "
		"beiges, chaussures de sécurité marron, CLÉ À MOLETTE",
		"clé à molette posée sur l'épaule, l'autre poing sur la hanche, sourire franc",
		"clé à molette gardée dans l'autre main"),
	"beaute": ("beaute", 1.10,
		"une BEAUTÉ (jeune femme d'environ 22 ans, élégante et sûre de son charme) : longs cheveux "
		"CHÂTAINS ondulés, ROBE D'ÉTÉ ROSE PÂLE à fines bretelles, petit SAC BLANC, bracelet, "
		"sandales blanches à talons",
		"une main dans les cheveux, l'autre tenant son sac, hanche de côté, sourire charmeur",
		"cheveux et robe qui volent, geste gracieux"),
	"rockeur": ("rockeur", 1.18,
		"un ROCKEUR (homme d'environ 25 ans, électrique) : cheveux NOIRS en épis, LUNETTES NOIRES, "
		"BLOUSON NOIR à étoiles dorées sur un t-shirt ROUGE, jean bleu, bottes noires, GUITARE "
		"ÉLECTRIQUE ROUGE en bandoulière",
		"jouant un accord sur sa guitare, tête rejetée, grand sourire",
		"guitare passée dans le dos, geste de rock star"),
	"campeur": ("campeur", 1.0,
		"un CAMPEUR (garçon d'environ 11 ans, débrouillard) : cheveux NOIRS en épis, CHEMISE KAKI de "
		"scout, FOULARD ROUGE noué, short OLIVE, petit sac à dos, chaussettes grises, chaussures de "
		"marche",
		"poings sur les hanches, grand sourire",
		"foulard qui vole"),
	"jeune_dresseur": (None, 1.05,
		"un JEUNE DRESSEUR (garçon d'environ 13 ans, sportif, un peu plus grand qu'un gamin) : cheveux "
		"BRUNS courts, CASQUETTE VERTE ET BLANCHE portée visière en avant, t-shirt JAUNE à col vert, "
		"short VERT FONCÉ, petit sac à dos vert, baskets blanches et vertes (surtout PAS de rouge : "
		"il ne doit pas ressembler au héros)",
		"poings serrés devant lui, prêt à se battre, sourire décidé",
		"casquette qui reste bien en place"),
	"intello": ("intello", 1.12,
		"un INTELLO (jeune homme d'environ 20 ans, mince) : cheveux BRUNS en bataille, LUNETTES "
		"rondes, chemise BLANCHE, NŒUD PAPILLON VERT, pantalon BEIGE, souliers marron, gros LIVRE",
		"un gros livre tenu sous le bras, l'autre index levé comme pour expliquer, air sûr de lui",
		"livre gardé sous l'autre bras"),
}

# Planches : identifiant → classes (une rangée chacune). Ordre : combats les plus vus d'abord.
PLANCHES: dict[str, list[str]] = {
	"sbires": ["sbire_rocket", "sbire_rocket_f"],
	"dresseuses": ["jeune_dresseuse", "fillette"],
	"nageurs": ["nageur", "nageuse"],
	"labo": ["scientifique", "chercheur"],
	"esprit": ["exorciste", "medium"],
	"route_cyclable": ["motard", "loubard"],
	"nature": ["ornithologue", "scout"],
	"dojo": ["karateka", "maitre_dojo"],
	"randonnee": ["montagnard", "pokemaniac"],
	"elite": ["topdresseur", "topdresseuse"],
	"jeux": ["jongleur", "joueur"],
	"pillard_dompteur": ["pillard", "dompteur"],
	"ss_anne": ["marin", "gentleman"],
	"metiers": ["pecheur", "ingenieur"],
	"beaute_rockeur": ["beaute", "rockeur"],
	"jeunes": ["campeur", "jeune_dresseur"],
	"intello": ["intello"],
}

DEUX = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD), DEUX classes de Dresseurs. Images jointes : IMAGE 1 = Pierre, Champion d'Argenta, sprites de combat VALIDÉS (à gauche debout prêt, à droite pose de lancer) : CIBLE EXACTE du rendu, de la main et de la pose de lancer pour un adulte ; IMAGE 2 = le Gamin, sprites de combat VALIDÉS (même main) : la référence pour un enfant{monde}.

PERSONNAGE DU HAUT : {desc_a}. Design moderne fidèle à la classe de Pokémon Rouge/Bleu.
PERSONNAGE DU BAS : {desc_b}. Design moderne fidèle à la classe de Pokémon Rouge/Bleu.

À FAIRE : UNE image PORTRAIT 1024 × 1536 en DEUX RANGÉES séparées par une large bande vide (au moins 100 px) : le personnage du HAUT dans la moitié haute, celui du BAS dans la moitié basse. Dans chaque rangée, DEUX poses du même personnage côte à côte, en pied, grandes (environ 560 px de haut, des cheveux aux semelles), bien séparées (au moins 80 px de vide entre elles), rien de coupé par les bords, pieds des deux poses à la même hauteur au bas de leur rangée :
- À GAUCHE : pose DEBOUT PRÊT : de trois-quarts face, corps tourné vers la gauche de l'image, tête tournée vers la gauche ({debout_a} pour le personnage du haut ; {debout_b} pour celui du bas).
- À DROITE : pose de LANCER comme celle de Pierre (IMAGE 1, à droite) : de trois-quarts face tourné vers la gauche, fente avant (jambe gauche de l'image avancée et fléchie, l'autre tendue en arrière), bras tendu loin vers la gauche à hauteur de poitrine, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre bras replié en arrière ({lancer_a} pour le haut ; {lancer_b} pour le bas).
Les deux personnages à la même échelle réelle (un adulte plus grand qu'un enfant). Mains à cinq doigts correctes, pieds entiers, même personnage, même tenue et mêmes proportions dans les deux poses d'une rangée.

STYLE (impératif) : exactement la main de Pierre et du Gamin (IMAGES 1 et 2) : illustration 2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir épais), aplats peints avec ombres douces et deux ou trois valeurs par matériau, légère granularité de pinceau, proportions réalistes-stylisées (PAS chibi), lumière neutre et douce venant de la gauche.

FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucun sol, aucune ombre portée, aucun halo, aucun texte, aucune lettre, aucun cadre, aucune Poké Ball.
"""


def _monde(nom: str) -> Image.Image:
	f = Image.open(MONDE / f"{nom}_sheet.png").convert("RGBA")
	cw, chh = f.width // 4, f.height // 4
	r = Image.new("RGBA", (cw * 2 + 10, chh), (0, 0, 0, 0))
	r.alpha_composite(f.crop((0, 0, cw, chh)), (0, 0))
	r.alpha_composite(f.crop((0, chh, cw, 2 * chh)), (cw + 10, 0))
	return r.resize((r.width * 4, r.height * 4), Image.LANCZOS)


def refs() -> None:
	OR.mkdir(parents=True, exist_ok=True)
	ec.CH.mkdir(parents=True, exist_ok=True)
	for nom, fichiers in (("pierre", ("pierre", "pierre_lancer")), ("gamin", ("gamin", "gamin_lancer"))):
		a, b = (Image.open(ed.SPR / f"{f}.webp").convert("RGBA") for f in fichiers)
		t = Image.new("RGBA", (a.width + b.width + 60, a.height), (0, 0, 0, 0))
		t.alpha_composite(a, (0, 0))
		t.alpha_composite(b, (a.width + 60, 0))
		t.save(OR / f"ref_{nom}_poses.png")
	for ident, (monde, *_r) in CLASSES.items():
		if monde:
			_monde(monde).save(OR / f"ref_monde_{ident}.png")


def _phrase_monde(classes: list[str]) -> str:
	parts, n = [], 3
	for ident, pos in zip(classes, ("du HAUT", "du BAS")):
		if CLASSES[ident][0]:
			parts.append(f" ; IMAGE {n} = l'apparence dans le monde du jeu du personnage {pos} "
				"(petit sprite de face et de profil) : sa tenue, sa coiffure et ses couleurs font foi")
			n += 1
	return "".join(parts)


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for planche, classes in PLANCHES.items():
		ident = f"EO_{planche.upper()}"
		if len(classes) == 2:
			a, b = (CLASSES[c] for c in classes)
			texte = DEUX.format(ident=ident, monde=_phrase_monde(classes), desc_a=a[2], desc_b=b[2],
				debout_a=a[3], debout_b=b[3], lancer_a=a[4], lancer_b=b[4])
		else:
			c = CLASSES[classes[0]]
			m = (" ; IMAGE 3 = son apparence dans le monde du jeu (petit sprite de face et de profil) : "
				"sa tenue et ses couleurs font foi") if c[0] else ""
			texte = ec.SPRITES.format(ident=ident, monde=m, desc=c[2] + ".", debout=c[3], lancer=c[4]) \
				.replace("pose DEBOUT PRÊT de Champion", "pose DEBOUT PRÊT") \
				.replace("IMAGE 2 = son buste « VS » validé (même main)",
					"IMAGE 2 = le Gamin, sprites de combat VALIDÉS (même main)") \
				.replace("(IMAGES 1 et 2)", "et du Gamin (IMAGES 1 et 2)")
		(PROMPTS / f"{planche}.txt").write_text(texte, encoding="utf-8")


def jointes(planche: str) -> list[Path]:
	j = [OR / "ref_pierre_poses.png", OR / "ref_gamin_poses.png"]
	for c in PLANCHES[planche]:
		if CLASSES[c][0]:
			j.append(OR / f"ref_monde_{c}.png")
	return j


def generer(planche: str, rev: str = "1") -> int:
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"EO_{planche}_r{rev}",
		str(PROMPTS / f"{planche}.txt"), *[str(p) for p in jointes(planche)]]
	return subprocess.call(cmd, cwd=RACINE)


# Révision retenue par planche ; absente = r1.
RETENUS: dict[str, str] = {"elite": "2", "jeunes": "2"}  # Topdresseur sans bras tendu ; Jeune Dresseur sans rouge (héros)


def _rangees(masque: np.ndarray, hauteur_min: int = 120) -> list[tuple[int, int]]:
	return ed._plages(masque.T, hauteur_min)


def _poses_rangee(im: Image.Image) -> list[Image.Image]:
	masque = np.asarray(im)[..., 3] > 96
	sorties = []
	for x0, x1 in ed._plages(masque):
		sous = im.crop((x0, 0, x1, im.height))
		sorties.append(sous.crop(sous.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()))
	if len(sorties) == 1:  # main du lancer au-dessus du coude de la pose debout : composantes connexes
		sorties = eg._separer(im)
	return sorties


def main_du_lancer(lancer: Image.Image) -> tuple[float, float]:
	"""Bout des doigts (pixel opaque le plus à gauche, y moyen des 6 colonnes de gauche) + décalage
	de la règle, en part de la hauteur de la toile depuis le milieu des pieds (centre de la toile)."""
	a = np.asarray(lancer)[..., 3] > 96
	haut = int(np.where(a.any(1))[0][0])
	a[haut + int((a.shape[0] - haut) * 0.55):] = False  # bras à hauteur de poitrine : pas le pied avant
	xs = np.where(a.any(0))[0]
	x0 = xs[0]
	ys = np.where(a[:, x0:x0 + 6].any(1))[0]
	h = lancer.height
	return (round((x0 - lancer.width / 2) / h + MAIN_DECALAGE[0], 3),
		round((ys.mean() - h) / h + MAIN_DECALAGE[1], 3))


def exporter(planches: list[str]) -> dict[str, tuple[float, float]]:
	mains = {}
	for planche in planches or list(PLANCHES):
		p = ed.ART / f"EO_{planche}_r{RETENUS.get(planche, '1')}.png"
		if not p.exists():
			continue
		im = ed._nettoyer(Image.open(p).convert("RGBA"))
		classes = PLANCHES[planche]
		if len(classes) == 1:
			rangees = [im]
		else:
			masque = np.asarray(im)[..., 3] > 96
			rangees = [im.crop((0, y0, im.width, y1)) for y0, y1 in _rangees(masque)]
		if len(rangees) != len(classes):
			print(f"{planche} : {len(rangees)} rangées pour {len(classes)} classes, ignorée")
			continue
		for ident, rangee in zip(classes, rangees):
			poses = _poses_rangee(rangee)
			print(ident, "poses", [i.size for i in poses])
			if len(poses) < 2:
				continue
			debout, lancer = ed.poses_en_toile(poses[0], poses[-1], (512, 768), 16)
			ed._webp(debout, ed.SPR / f"{ident}.webp")
			ed._webp(lancer, ed.SPR / f"{ident}_lancer.webp")
			mains[ident] = main_du_lancer(lancer)
	return mains


def ecrire_donnees(mains: dict[str, tuple[float, float]]) -> None:
	"""« hand » mesurée et « scale » [D] de chaque classe peinte, dans trainer_intro.json (clés
	ajoutées sans réordonner le fichier)."""
	texte = INTRO.read_text(encoding="utf-8")
	classes = json.loads(texte)["classes"]
	lignes = texte.split("\n")
	for ident, main in mains.items():
		entree = dict(classes[ident])
		entree["scale"] = CLASSES[ident][1]
		entree["hand"] = list(main)
		corps = ", ".join(f"{json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}"
			for k, v in entree.items())
		for i, ligne in enumerate(lignes):
			if ligne.startswith(f'\t\t"{ident}": {{'):
				fin = "," if ligne.rstrip().endswith(",") else ""
				lignes[i] = f'\t\t"{ident}": {{ {corps} }}{fin}'
	INTRO.write_text("\n".join(lignes), encoding="utf-8")


if __name__ == "__main__":
	act = sys.argv[1]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		sys.exit(generer(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "1"))
	elif act == "exporter":
		m = exporter(sys.argv[2:])
		ecrire_donnees(m)
		print(json.dumps(m))
