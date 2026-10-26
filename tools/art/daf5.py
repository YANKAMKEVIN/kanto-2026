#!/usr/bin/env python3
"""DAF.5 (phase DA, `docs/design/phase-da-cadrage.md`) — reliquats : icônes du Sac manquantes et les deux
objets de décor encore en pixel art de Bourg Palette (`breakfast`, `bed_items`).
Inventaire : `docs/design/inventaire-art.md` §4 (23 objets de `data/items/*.json` sans icône) et §7.
Méthode des séries précédentes : prompts versionnés (`tools/art/prompts/daf5/`), planches d'icônes au
gabarit de `serie22bis._prompt_icones` (4 colonnes de 384 px, ancres = icônes existantes), découpe de
`preparer_menu._objets` (256 × 256 webp). Décor : lumière NEUTRE, rendu des intérieurs peints
(`int_table_repas_01`, `int_lit_pokeball_01`, référence `chambre-joueur-v1.webp`), ramené à l'emprise du
provisoire (288 × 192 et 192 × 192, même ancrage, posé sur la table ou le lit).
Usage :
  tools/art/daf5.py --prompts          écrit les prompts (sans Codex)
  tools/art/daf5.py [NOM ...]          génère avec Codex (3 en parallèle ; sans argument : tout ce qui manque)
  tools/art/daf5.py --preparer         images de build/art/ → assets/ (icônes et décor)
  tools/art/daf5.py --planche          planche de validation docs/design/fiches-assets/daf-5-icones/planche.png
"""
from __future__ import annotations

import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import preparer_menu  # noqa: E402
from serie06 import ADN, LUMIERE_NE, RACINE  # noqa: E402
from serie22bis import _DISQUE, _prompt_icones  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
PROMPTS = ICI / "prompts" / "daf5"
ICONES = RACINE / "assets" / "ui" / "items"
_I = "assets/ui/items/"
_W = "assets/world/interiors/"
CHAMBRE = "docs/design/reference/chambre-joueur-v1.webp"

# --- Icônes du Sac (23) ------------------------------------------------------------------------
## (identifiant, [(id d'objet, description)], ancres). Identifiants vérifiés dans data/items/*.json
## (origin/main @ 5b33c3f1, 2026-10-25). Couleurs des disques par type, comme la série 22 bis :
## CS = jaune vif ; Normal = crème ; Glace = bleu glace ; Plante = vert feuille ; Feu = rouge-orangé.
ICONES_PLANCHES = [
	("UI_OBJETS_DAF5_PLANCHE_1", [
		("hyper_potion", "l'HYPER POTION : le MÊME flacon vaporisateur que la Potion jointe (même forme, même "
			"taille, même gâchette) mais au corps ROSE MAGENTA franc, gâchette et bouchon blancs"),
		("max_potion", "la POTION MAX : le même flacon vaporisateur au corps BLEU ROYAL profond, gâchette et "
			"bouchon DORÉS"),
		("full_heal", "le TOTAL SOIN : le même flacon vaporisateur au corps JAUNE PÂLE crème, une large bague "
			"VERTE au col, gâchette et bouchon blancs"),
		("ultra_ball", "l'HYPER BALL : une sphère comme la Super Ball jointe (même modèle, même taille, même "
			"bande médiane et même bouton central), mais le dessus est NOIR anthracite avec deux larges bandes "
			"JAUNE d'or qui descendent de part et d'autre du bouton (en forme de H), le dessous blanc crème"),
	], [f"{_I}potion.webp", f"{_I}great_ball.webp", f"{_I}full_restore.webp"]),
	("UI_OBJETS_DAF5_PLANCHE_2", [
		("max_revive", "le RAPPEL MAX : le MÊME cristal taillé en losange que le Rappel joint, mais PLUS LARGE "
			"et plus massif, jaune d'or plus profond, avec une petite ÉTOILE blanche à cinq branches gravée au "
			"centre"),
		("old_amber", "le VIEIL AMBRE : un gros morceau d'AMBRE poli, arrondi et irrégulier, orange miel "
			"translucide, avec une minuscule silhouette sombre d'insecte prisonnière au cœur ; ancien et précieux"),
		("poke_flute", "la POKÉ FLÛTE : une petite FLÛTE à bec trapue en bois clair verni, embouchure et "
			"bagues ROUGES et blanches, quatre trous visibles, posée en diagonale"),
		("secret_key", "la CLÉ SECRÈTE : une grande CLÉ ancienne de bronze sombre et cuivré, tête ronde ajourée "
			"sertie d'une petite pierre ROUGE, panneton travaillé ; aucun texte, aucun emblème, aucune lettre R"),
	], [f"{_I}revive.webp", f"{_I}lift_key.webp", f"{_I}moon_stone.webp"]),
	("UI_OBJETS_DAF5_PLANCHE_3", [
		("old_rod", "la CANNE : une canne à pêche SIMPLE en BAMBOU clair, courte, avec un fil enroulé au bout "
			"et un petit bouchon rouge et blanc, posée en diagonale (du bas à gauche vers le haut à droite)"),
		("good_rod", "la SUPER CANNE : une canne à pêche de métal ROUGE vif, poignée de liège, petit MOULINET "
			"argenté, même diagonale et même longueur que la Canne"),
		("super_rod", "la MÉGA CANNE : une canne à pêche BLEU MARINE à anneaux DORÉS, poignée noire, gros "
			"MOULINET doré, même diagonale et même longueur que les deux autres"),
		("bicycle", "la BICYCLETTE : un vélo de ville pliant ROUGE vif vu de profil, légèrement de trois quarts, "
			"deux roues noires aux jantes argentées, selle noire, guidon chromé, petit panier avant ; compact"),
	], [f"{_I}escape_rope.webp", f"{_I}silph_scope.webp"]),
	("UI_OBJETS_DAF5_PLANCHE_4", [
		("bike_voucher", "le BON DE COMMANDE : un TICKET de papier comme la Passe Bateau jointe (même forme, "
			"même bord dentelé, même inclinaison), crème et ROUGE, avec le dessin bleu marine d'une BICYCLETTE "
			"à la place du bateau ; aucun texte"),
		("card_key", "la CARTE MAGNÉTIQUE : une carte de plastique rectangulaire aux coins arrondis, gris "
			"argenté, bande BLEUE en haut et petite puce DORÉE, légèrement inclinée ; aucun texte, aucun logo"),
		("tm39", "la CT39 (MÉTÉORES) : " + _DISQUE + " mais le dessus est CRÈME clair (type Normal, comme la "
			"CT01), et au centre trois petites ÉTOILES blanches filantes"),
	], [f"{_I}ss_ticket.webp", f"{_I}hm05.webp", f"{_I}tm01.webp"]),
	("UI_OBJETS_DAF5_PLANCHE_5", [
		("hm02", "la CS02 (VOL) : " + _DISQUE + " (le dessus JAUNE VIF des CS), et au centre une petite AILE "
			"déployée blanche stylisée"),
		("hm03", "la CS03 (SURF) : " + _DISQUE + " (le dessus JAUNE VIF des CS), et au centre une petite VAGUE "
			"enroulée blanche stylisée"),
		("hm04", "la CS04 (FORCE) : " + _DISQUE + " (le dessus JAUNE VIF des CS), et au centre un petit ROCHER "
			"blanc stylisé avec une flèche qui le pousse"),
		("tm09", "la CT09 (BÉLIER) : " + _DISQUE + " mais le dessus est CRÈME clair (type Normal, comme la "
			"CT01), et au centre une petite CORNE de bélier enroulée blanche stylisée"),
	], [f"{_I}hm05.webp", f"{_I}hm01.webp", f"{_I}tm01.webp"]),
	("UI_OBJETS_DAF5_PLANCHE_6", [
		("tm14", "la CT14 (BLIZZARD) : " + _DISQUE + " mais le dessus est BLEU GLACE clair (type Glace, comme la "
			"CT13), et au centre une petite RAFALE de vent en spirale avec deux petits flocons blancs"),
		("tm22", "la CT22 (LANCE-SOLEIL) : " + _DISQUE + " mais le dessus est VERT feuille (type Plante, comme "
			"la CT21), et au centre un petit SOLEIL rayonnant blanc"),
		("tm35", "la CT35 (MÉTRONOME) : " + _DISQUE + " mais le dessus est CRÈME clair (type Normal, comme la "
			"CT01), et au centre un petit MÉTRONOME blanc stylisé (pyramide et balancier)"),
		("tm38", "la CT38 (DÉFLAGRATION) : " + _DISQUE + " mais le dessus est ROUGE-ORANGÉ vif (type Feu), et au "
			"centre une petite FLAMME blanche à cinq branches en étoile"),
	], [f"{_I}hm05.webp", f"{_I}tm13.webp", f"{_I}tm21.webp"]),
]
ICONES_IDS = [objet for _p, objets, _a in ICONES_PLANCHES for objet, _t in objets]

# --- Objets de décor (2) -----------------------------------------------------------------------
## (identifiant, asset, provisoire, taille de la toile = provisoire, boîte cible (x, y, l, h) dans
## la toile, description, ancres). La boîte cible pose l'objet sur le plateau de la table (sous le vase)
## ou sur la couverture du lit (repères : `int_table_repas_01` 288 × 251, `int_lit_pokeball_01` 192 × 268,
## mêmes colonnes que le provisoire, bas commun).
DECOR = [
	("INT_PETIT_DEJEUNER", "int_petit_dejeuner_01", "breakfast", (288, 192), (66, 34, 156, 52),
		"un PETIT-DÉJEUNER servi pour une personne, posé à plat sur une table (la table n'est PAS dessinée) : "
		"de gauche à droite, un verre de jus d'orange, une assiette blanche avec deux tranches de pain grillé "
		"et un œuf au plat, un bol bleu de céréales au lait avec une cuillère, une tasse blanche de café sur sa "
		"soucoupe. Les objets sont alignés en une rangée serrée et basse (l'ensemble est environ trois fois "
		"plus large que haut), vus de dessus de trois quarts EXACTEMENT comme la nappe de la table jointe "
		"(int_table_repas_01) : on voit l'intérieur de l'assiette, du bol et de la tasse. Aucune vapeur, "
		"aucune nappe, aucun plateau, aucun set de table.",
		[f"{_W}int_table_repas_01.png", f"{_W}int_sac_voyage_01.png", CHAMBRE]),
	("INT_LIT_AFFAIRES_RIVAL", "int_lit_affaires_rival_01", "bed_items", (192, 192), (14, 10, 164, 150),
		"les AFFAIRES du rival étalées à plat sur une couverture de lit (le lit n'est PAS dessiné) : en haut, "
		"une grande CARTE de Kanto DÉPLIÉE (papier crème marqué de plis en quatre, mer bleue, terres vertes, "
		"quelques petits points rouges de villes reliés par des chemins beiges, AUCUN texte, aucun nom) ; en "
		"bas à gauche, une paire de JUMELLES compactes noires et grises ; en bas à droite, un petit SAC à dos "
		"VERT sapin fermé, sa sangle posée. Le tout vu de dessus de trois quarts EXACTEMENT comme le lit "
		"joint (int_lit_pokeball_01), la carte bien à plat, l'ensemble à peu près aussi large que haut.",
		[f"{_W}int_lit_pokeball_01.png", f"{_W}int_sac_voyage_01.png", CHAMBRE]),
]

_VALEURS_DECOR = ("VALEURS DES INTÉRIEURS DE BOURG PALETTE (maison familiale chaleureuse : bois miel, tissus clairs, "
	"accents bleus et rouges) ; " + LUMIERE_NE + " Le jeu ajoute lui-même l'ambiance `interior_warm` : AUCUNE "
	"teinte dorée ni orangée, aucun halo. Ombres propres douces sous chaque objet (contact), aucune ombre "
	"portée hors des objets.")


def _prompt_decor(ident: str, description: str, ancres: list[str]) -> str:
	noms = ", ".join(Path(a).stem for a in ancres)
	return (f"{ident} — NOUVELLE image : un objet de décor peint pour un intérieur du jeu.\n"
		f"Images jointes : {noms} = mobilier déjà peint du jeu et référence d'intérieur, ANCRES de style "
		"(même rendu peint, même contour fin et coloré, même angle de vue, même finesse) ; n'en reproduis ni "
		"le mobilier ni le personnage.\n\n"
		f"{ADN}\n{_VALEURS_DECOR}\n\n"
		"EXCEPTION à la règle « Isolement » : un petit GROUPE d'objets posés ensemble, comme décrit.\n"
		f"SUJET : {description}\n"
		"Image 1536 × 1024, le groupe centré, environ 1100 px de large au plus, fond entièrement transparent "
		"(canal alpha, aucun damier dessiné), aucune table, aucun lit, aucun sol. Interdit : texte, lettres, "
		"chiffres, logo, personnage, Pokémon.\n")


def _images() -> list[tuple[str, str, list[str]]]:
	"""(nom de l'image sans .png, texte du prompt, jointes)."""
	images = [(f"{ident}_r1", _prompt_icones(ident, objets, ancres, []), ancres)
		for ident, objets, ancres in ICONES_PLANCHES]
	images += [(f"{ident}_NE_r1", _prompt_decor(ident, texte, ancres), ancres)
		for ident, _a, _s, _t, _b, texte, ancres in DECOR]
	return images


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for nom, texte, _j in _images():
		(PROMPTS / f"{nom}.txt").write_text(texte, encoding="utf-8")
		print(PROMPTS / f"{nom}.txt")


def _generer(image: tuple[str, str, list[str]]) -> str:
	nom, _t, jointes = image
	commande = [str(ICI / "generer.sh"), nom, str(PROMPTS / f"{nom}.txt")] + [str(RACINE / j) for j in jointes]
	for _essai in range(2):
		resultat = subprocess.run(commande, capture_output=True, text=True)
		if resultat.returncode == 0:
			return f"{nom} : ok"
	# Règle de Kevin : avec les images jointes d'abord, puis sans pièce jointe.
	resultat = subprocess.run(commande[:3], capture_output=True, text=True)
	return f"{nom} : {'ok (sans jointes)' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()}"


def generer(noms: list[str]) -> None:
	prompts()
	images = [i for i in _images() if (i[0] in noms if noms else not (ART / f"{i[0]}.png").exists())]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(_generer, images):
			print(ligne, flush=True)


def _revision(ident: str) -> Path:
	"""Dernière révision présente de [ident] dans $ART (r1, r2...)."""
	candidats = sorted(ART.glob(f"{ident}_r*.png"), key=lambda p: int(p.stem.rsplit("_r", 1)[1]))
	return candidats[-1]


def _sans_debris(image: Image.Image) -> Image.Image:
	"""Garde les morceaux opaques d'au moins 5 % du plus grand : une colonne de 384 px peut mordre sur
	l'objet voisin (cannes en diagonale, vélo), dont il ne reste alors qu'un petit éclat."""
	import numpy as np
	from collections import deque
	alpha = np.array(image.getchannel("A")) > 24
	etiquettes = np.zeros(alpha.shape, dtype=np.int32)
	tailles = [0]
	hauteur, largeur = alpha.shape
	for y0, x0 in zip(*np.nonzero(alpha)):
		if etiquettes[y0, x0]:
			continue
		n = len(tailles)
		etiquettes[y0, x0] = n
		file, taille = deque([(y0, x0)]), 0
		while file:
			y, x = file.popleft()
			taille += 1
			for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				v, u = y + dy, x + dx
				if 0 <= v < hauteur and 0 <= u < largeur and alpha[v, u] and not etiquettes[v, u]:
					etiquettes[v, u] = n
					file.append((v, u))
		tailles.append(taille)
	gardes = [i for i, t in enumerate(tailles) if i and t >= 0.05 * max(tailles)]
	pixels = np.array(image)
	pixels[~np.isin(etiquettes, gardes) & (etiquettes > 0), 3] = 0
	pixels[(etiquettes == 0), 3] = np.minimum(pixels[(etiquettes == 0), 3], 24)
	return Image.fromarray(pixels)


def preparer() -> None:
	for ident, objets, _a in ICONES_PLANCHES:
		planche = Image.open(_revision(ident)).convert("RGBA")
		bandes = preparer_menu._bandes(planche, len(objets))
		nettoyee = Image.new("RGBA", planche.size, (0, 0, 0, 0))
		for gauche, droite in bandes:
			nettoyee.paste(_sans_debris(planche.crop((gauche, 0, droite, planche.height))), (gauche, 0))
		source = ART / f"{ident}_net.png"
		nettoyee.save(source)
		preparer_menu._objets(source, ICONES, [o for o, _t in objets])
	for ident, asset, _s, toile, boite, _t, _a in DECOR:
		objet = preparer_menu._silhouette(Image.open(_revision(f"{ident}_NE")).convert("RGBA"))
		x, y, largeur, hauteur = boite
		echelle = min(largeur / objet.width, hauteur / objet.height)
		objet = objet.resize((round(objet.width * echelle), round(objet.height * echelle)), Image.LANCZOS)
		sortie = Image.new("RGBA", toile, (0, 0, 0, 0))
		# Centré dans la boîte, posé sur son bas.
		sortie.alpha_composite(objet, (x + (largeur - objet.width) // 2, y + hauteur - objet.height))
		sortie.save(RACINE / _W / f"{asset}.png")
		print(RACINE / _W / f"{asset}.png", objet.size)


# --- Planche de validation -----------------------------------------------------------------------

def _police(taille: int) -> ImageFont.FreeTypeFont:
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default()


def _sur_place(fond: str, decor: str, ancrage_fond: tuple[int, int], ancrage_decor: tuple[int, int],
		taille: tuple[int, int]) -> Image.Image:
	"""Meuble peint + décor posés comme en jeu (coordonnées monde relatives), sur un sol neutre."""
	image = Image.new("RGBA", taille, (176, 150, 118, 255))
	image.alpha_composite(Image.open(RACINE / fond).convert("RGBA"), ancrage_fond)
	image.alpha_composite(Image.open(RACINE / decor).convert("RGBA"), ancrage_decor)
	return image


def planche() -> Path:
	cellule, colonnes = 200, 8
	titre, legende = _police(30), _police(17)
	existants = ["potion", "great_ball", "revive", "lift_key", "ss_ticket", "hm05", "tm01", "tm21"]
	lignes_nouv = (len(ICONES_IDS) + colonnes - 1) // colonnes
	# Décor : avant (provisoire) et après, posés sur leur meuble à 1:1, agrandis × 2.
	ph = "assets/tiles/placeholder/props/interior/"
	table = ("assets/world/interiors/int_table_repas_01.png", (0, 0), (0, 59), (288, 251))
	lit = ("assets/world/interiors/int_lit_pokeball_01.png", (0, 0), (0, 76), (192, 268))
	paires = [
		("breakfast (player_house_1f)", _sur_place(table[0], f"{ph}breakfast.png", *table[1:]),
			_sur_place(table[0], f"{_W}int_petit_dejeuner_01.png", *table[1:])),
		("bed_items (rival_house)", _sur_place(lit[0], f"{ph}bed_items.png", *lit[1:]),
			_sur_place(lit[0], f"{_W}int_lit_affaires_rival_01.png", *lit[1:])),
	]
	hauteur_decor = 2 * 268 + 70
	largeur = max(cellule * colonnes + 40, 20 + sum(2 * (a.width * 2 + 16) + 40 for _n, a, _b in paires))
	hauteur = 70 + 50 + cellule + 50 + lignes_nouv * cellule + 60 + hauteur_decor + 20
	page = Image.new("RGBA", (largeur, hauteur), (34, 40, 52, 255))
	d = ImageDraw.Draw(page)
	d.text((20, 18), "DAF.5 — 23 icônes du Sac et 2 objets de décor (à valider par Kevin)", font=titre,
		fill=(240, 240, 240))
	y = 80
	d.text((20, y), "Icônes existantes (référence de style)", font=legende, fill=(180, 190, 200))
	y += 30

	def icone(nom: str, x: int, y: int, couleur: tuple[int, int, int]) -> None:
		image = Image.open(ICONES / f"{nom}.webp").convert("RGBA").resize((160, 160), Image.LANCZOS)
		page.alpha_composite(image, (x + 20, y))
		d.text((x + 20, y + 164), nom, font=legende, fill=couleur)

	for i, nom in enumerate(existants):
		icone(nom, 20 + i * cellule, y, (160, 170, 180))
	y += cellule + 20
	d.text((20, y), "Nouvelles icônes (256 × 256, affichées à 160)", font=legende, fill=(250, 210, 120))
	y += 30
	for i, nom in enumerate(ICONES_IDS):
		icone(nom, 20 + (i % colonnes) * cellule, y + (i // colonnes) * cellule, (250, 230, 180))
	y += lignes_nouv * cellule + 20
	d.text((20, y), "Décor posé sur son meuble comme en jeu (× 2) : provisoire pixel → peint", font=legende,
		fill=(250, 210, 120))
	y += 30
	x = 20
	for nom, avant, apres in paires:
		d.text((x, y), nom, font=legende, fill=(240, 240, 240))
		for k, image in enumerate((avant, apres)):
			grande = image.resize((image.width * 2, image.height * 2), Image.LANCZOS)
			page.alpha_composite(grande, (x + k * (grande.width + 16), y + 26))
		x += 2 * (avant.width * 2 + 16) + 40
	sortie = RACINE / "docs/design/fiches-assets/daf-5-icones/planche.png"
	sortie.parent.mkdir(parents=True, exist_ok=True)
	page.convert("RGB").save(sortie)
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		prompts()
	elif "--preparer" in arguments:
		preparer()
	elif "--planche" in arguments:
		print(planche())
	else:
		generer(arguments)
