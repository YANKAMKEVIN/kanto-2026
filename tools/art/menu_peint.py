#!/usr/bin/env python3
"""Chantier « Menu Dresseur peint » (demande de Kevin du 2026-11-01 : « peint tout »).

Peint ce qui restait en SVG teinté ou en icône teintée dans le Menu Dresseur :
  - les 8 badges de Kanto (formes de Rouge/Bleu) → `assets/ui/badges/<id>.webp` (256 × 256,
    fond transparent), plus le gabarit neutre `unknown.webp` du badge non obtenu (dossier 08 §6 :
    le même pour les huit emplacements, il ne dit rien du badge) ;
  - les icônes d'objets provisoires teintées (RP-265 : Protéine, Fer, Calcium, Éther, Élixir,
    3 Repousses, Cherch'Objet, Multi Exp) → `assets/ui/items/<id>.webp`, gabarit de
    `preparer_menu.py` (carré 256, marge 8). [D] Les frères teintés du même flacon (Carbone, PV
    Plus, PP Plus, Éther Max, Élixir Max) sont repeints dans les mêmes planches, sinon leurs familles
    (vitamines, PP) auraient deux formes.

Planches 1536 × 1024 en 4 colonnes invisibles de 384 px (découpe de `preparer_menu._bandes`).
Images brutes (hors dépôt) dans $ART (défaut build/art).

Usage :
  tools/art/menu_peint.py --prompts     écrit les prompts dans build/art/prompts/
  tools/art/menu_peint.py --generer     génère les planches absentes (Codex, generer.sh)
  tools/art/menu_peint.py --preparer    découpe les planches présentes → assets/
  tools/art/menu_peint.py --planche     planche de validation docs/design/fiches-assets/menu-peint/
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import preparer_menu  # noqa: E402

RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
PROMPTS = ART / "prompts"
ITEMS = RACINE / "assets" / "ui" / "items"
BADGES = RACINE / "assets" / "ui" / "badges"
FICHE = RACINE / "docs" / "design" / "fiches-assets" / "menu-peint"
_I = "assets/ui/items/"

RENDU = ("RENDU : icône 2D peinte numériquement pour l'interface d'un RPG Pokémon moderne « HD-2D peint » : "
	"formes simples et lisibles, contour fin et doux plus sombre que la couleur (aucun trait noir), volumes "
	"doux à trois valeurs, reflets nets, pinceau propre. Ni pixel art, ni 3D, ni photo. Lumière douce et "
	"neutre venant du haut à gauche.")
STYLE = (" dans le style EXACT des icônes jointes (même rendu peint, même contour fin et coloré, même angle "
	"de trois quarts, même lumière, même finesse, même taille d'environ 240 px)")

_BADGE = ("un BADGE d'arène métallique (broche émaillée, comme les badges de Pokémon Rouge et Bleu), vu presque "
	"de face avec une très légère inclinaison, tranche fine de métal visible, émail lisse et brillant, "
	"reflet net en haut à gauche, contour métallique un peu plus sombre ; silhouette fidèle au badge de Rouge "
	"et Bleu : ")
_VITAMINE = ("un petit FLACON de vitamines en verre (pilulier trapu et arrondi, épaule douce), un gros BOUCHON à vis "
	"strié, une ÉTIQUETTE blanche unie autour du corps portant un petit symbole (aucun texte)")
_FIOLE = ("une FIOLE de verre en forme de goutte (corps rond, col court et étroit, bouchon de verre rond facetté), "
	"remplie aux trois quarts")
_AEROSOL = ("une BOMBE AÉROSOL cylindrique trapue en métal laqué (épaule arrondie, petit diffuseur blanc sur le dessus, "
	"sans capuchon), avec une large bande médiane blanche portant une "
	"petite empreinte de patte stylisée barrée (aucun texte)")

# (identifiant de la planche, [(id, description)], ancres de style, catégorie)
PLANCHES: list[tuple[str, list[tuple[str, str]], list[str], str]] = [
	("UI_BADGES_PLANCHE_1", [
		("boulder", _BADGE + "le BADGE ROCHE, un OCTOGONE à facettes taillées comme une pierre, GRIS argenté, "
			"facettes claires et sombres bien lisibles"),
		("cascade", _BADGE + "le BADGE CASCADE, une GOUTTE d'eau (pointe en haut), BLEU ciel limpide, "
			"bord bleu plus foncé, petit reflet blanc"),
		("thunder", _BADGE + "le BADGE FOUDRE, une ÉTOILE à huit pointes arrondies comme un soleil, ORANGE doré, "
			"avec un disque central JAUNE clair"),
		("rainbow", _BADGE + "le BADGE PRISME, une FLEUR à huit pétales arrondis aux couleurs de l'arc-en-ciel "
			"(rouge, orange, jaune, vert, bleu, indigo, violet, rose) autour d'un petit cœur blanc"),
	], [f"{_I}nugget.webp", f"{_I}moon_stone.webp"], "badge"),
	("UI_BADGES_PLANCHE_2", [
		("soul", _BADGE + "le BADGE ÂME, un CŒUR bombé ROSE fuchsia, bord rose plus sombre"),
		("marsh", _BADGE + "le BADGE MARAIS, un DISQUE d'OR fait de trois ANNEAUX concentriques en relief, "
			"or jaune chaud"),
		("volcano", _BADGE + "le BADGE VOLCAN, une FLAMME stylisée ROUGE vif en losange à pointes, avec un "
			"losange intérieur plus clair orange"),
		("earth", _BADGE + "le BADGE TERRE, un emblème VERT feuille à quatre lobes pointus disposés en croix "
			"autour d'un centre vert clair, comme une plante stylisée"),
	], [f"{_I}nugget.webp", f"{_I}moon_stone.webp"], "badge"),
	("UI_BADGE_INCONNU", [
		("unknown", "un EMPLACEMENT DE BADGE VIDE : un petit CREUX rond et peu profond, bordé d'un anneau de métal "
			"GRIS ARDOISE mat, le fond du creux en velours gris-bleu sombre ; aucun badge dedans, aucun motif, "
			"aucun symbole ; sobre et neutre, en valeurs grises désaturées seulement"),
	], [f"{_I}nugget.webp"], "badge"),
	("UI_OBJETS_VITAMINES", [
		("protein", _VITAMINE + " : la PROTÉINE, verre ambré, bouchon ROUGE, symbole un petit POING rouge"),
		("iron", "le MÊME flacon (même forme, même taille) : le FER, verre ambré, bouchon GRIS ACIER, symbole un "
			"petit BOUCLIER gris"),
		("calcium", "le MÊME flacon : le CALCIUM, verre ambré, bouchon BLEU franc, symbole une petite ÉTOILE bleue"),
		("carbos", "le MÊME flacon : le CARBONE, verre ambré, bouchon VERT franc, symbole une petite AILE verte"),
	], [f"{_I}rare_candy.webp", f"{_I}potion.webp"], "objet"),
	("UI_OBJETS_PV_PP_DETECT", [
		("hp_up", "le MÊME flacon de vitamines que la planche des vitamines (pilulier trapu en verre ambré, gros "
			"bouchon à vis strié, étiquette blanche) : le PV PLUS, bouchon ROSE-ROUGE, symbole un petit CŒUR rose"),
		("pp_up", "le MÊME flacon de vitamines : le PP PLUS, bouchon JAUNE doré, symbole une petite FLÈCHE vers le "
			"haut jaune"),
		("itemfinder", "le CHERCH'OBJET : un petit appareil de détection portatif, boîtier arrondi ROUGE et gris "
			"clair tenu à la main, petit écran rond de radar VERT avec des cercles concentriques, courte "
			"ANTENNE argentée"),
		("exp_all", "le MULTI EXP : un petit boîtier émetteur arrondi BLEU et blanc, comme un badge électronique "
			"à pince, avec trois petits VOYANTS verts alignés et un court cordon gris"),
	], [f"{_I}rare_candy.webp", f"{_I}poke_flute.webp"], "objet"),
	("UI_OBJETS_PP", [
		("ether", _FIOLE + " : l'ÉTHER, liquide BLEU clair limpide"),
		("max_ether", "la MÊME fiole (même forme), un peu plus grande : l'ÉTHER MAX, liquide BLEU profond, bouchon "
			"et petit anneau au col DORÉS"),
		("elixir", "la MÊME fiole (même forme et taille que l'Éther) : l'ÉLIXIR, liquide ROSE-VIOLET"),
		("max_elixir", "la MÊME fiole un peu plus grande : l'ÉLIXIR MAX, liquide VIOLET profond, bouchon et anneau "
			"au col DORÉS"),
	], [f"{_I}potion.webp", f"{_I}rare_candy.webp"], "objet"),
	("UI_OBJETS_REPOUSSES", [
		("repel", _AEROSOL + " : la REPOUSSE, bombe VIOLET pâle"),
		("super_repel", "la MÊME bombe (même forme, même taille, même bande) : la SUPER REPOUSSE, bombe JAUNE "
			"moutarde"),
		("max_repel", "la MÊME bombe : la MAX REPOUSSE, bombe VERT émeraude, diffuseur DORÉ"),
	], [f"{_I}potion.webp", f"{_I}escape_rope.webp"], "objet"),
]
# Ordre de la planche de validation (badges d'abord).
BADGE_IDS = ["boulder", "cascade", "thunder", "rainbow", "soul", "marsh", "volcano", "earth"]
RP265 = ["protein", "iron", "calcium", "ether", "elixir", "repel", "super_repel", "max_repel",
	"itemfinder", "exp_all"]
FRERES = ["carbos", "hp_up", "pp_up", "max_ether", "max_elixir"]


def _nom(planche: str) -> str:
	return f"{planche}_r1"


def _prompt(ident: str, objets: list[tuple[str, str]], ancres: list[str], categorie: str) -> str:
	n = len(objets)
	noms = ", ".join(Path(a).stem for a in ancres)
	colonnes = ("la PREMIÈRE colonne (x de 0 à 384)" if n == 1 else
		f"chacune des {n} PREMIÈRES colonnes (de gauche à droite)")
	vides = "" if n == 4 else f" ; les {4 - n} dernières colonnes restent VIDES (transparentes)"
	lignes = "\n".join(f"{i + 1} (colonne {i + 1}) : {texte}." for i, (_, texte) in enumerate(objets))
	sujet = ("badges d'arène pour l'écran Dresseur" if categorie == "badge"
		else "icônes d'objets pour le Sac")
	meme = (" Tous les badges ont la MÊME taille apparente, la MÊME épaisseur et le MÊME métal : ils forment une "
		"collection." if categorie == "badge" and n > 1 else "")
	return (f"{ident} — NOUVELLE image : une planche de {sujet} du jeu Kanto 2026, pas une scène.\n"
		f"Images jointes : {noms} = icônes déjà peintes du jeu, ANCRES de style{STYLE} ; n'en reproduis pas "
		"les objets.\n\n"
		f"{RENDU}\n\n"
		f"PLANCHE de {n} icône{'s' if n > 1 else ''} peinte{'s' if n > 1 else ''}, dans une image 1536 × 1024 "
		f"divisée en quatre colonnes invisibles de 384 px : une icône CENTRÉE dans {colonnes}, de 260 px de "
		f"large au plus et 260 px de haut au plus, avec au moins 60 px de marge vide de chaque côté{vides}."
		f"{meme}\n{lignes}\n"
		"AUCUN halo, AUCUNE lueur, AUCUNE étincelle, AUCUN dégradé autour : chaque objet est net, avec seulement "
		"son contour fin, sur un fond entièrement transparent (canal alpha, aucun damier dessiné, aucune "
		"ombre). Interdit : texte, lettres, chiffres, logo, la lettre R, personnage, Pokémon.\n")


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for ident, objets, ancres, categorie in PLANCHES:
		fichier = PROMPTS / f"{_nom(ident)}.txt"
		fichier.write_text(_prompt(ident, objets, ancres, categorie), encoding="utf-8")
		print(fichier)


def generer(choix: set[str]) -> None:
	prompts()
	for ident, _o, ancres, _c in PLANCHES:
		nom = _nom(ident)
		if choix and ident not in choix:
			continue
		if (ART / f"{nom}.png").exists():
			print(f"{nom} : déjà là", flush=True)
			continue
		commande = [str(ICI / "generer.sh"), nom, str(PROMPTS / f"{nom}.txt")] + \
			[str(RACINE / a) for a in ancres]
		resultat = subprocess.run(commande, capture_output=True, text=True)
		etat = "ok" if resultat.returncode == 0 else "ÉCHEC " + resultat.stderr.strip()[-200:]
		print(f"{nom} : {etat}", flush=True)


def _transparente(image: Image.Image) -> Image.Image:
	"""Codex rend parfois un fond opaque uni (blanc, gris ou damier clair) malgré la consigne :
	le fond relié aux bords devient transparent (remplissage depuis les coins, tolérance douce)."""
	rgba = image.convert("RGBA")
	alpha = rgba.getchannel("A")
	if alpha.getextrema()[0] < 16:
		return rgba
	from PIL import ImageChops
	masque = Image.new("L", rgba.size, 0)
	rgb = rgba.convert("RGB")
	for coin in [(0, 0), (rgba.width - 1, 0), (0, rgba.height - 1), (rgba.width - 1, rgba.height - 1)]:
		copie = rgb.copy()
		ImageDraw.floodfill(copie, coin, (255, 0, 255), thresh=40)
		diff = ImageChops.difference(copie, Image.new("RGB", rgba.size, (255, 0, 255))).convert("L")
		masque = ImageChops.lighter(masque, diff.point(lambda v: 255 if v < 8 else 0))
	rgba.putalpha(ImageChops.subtract(alpha, masque))
	return rgba


def preparer() -> None:
	BADGES.mkdir(parents=True, exist_ok=True)
	for ident, objets, _a, categorie in PLANCHES:
		source = ART / f"{_nom(ident)}.png"
		if not source.exists():
			print(f"{source.name} : absente, ignorée")
			continue
		propre = ART / f"{_nom(ident)}_alpha.png"
		_transparente(Image.open(source)).save(propre)
		dossier = BADGES if categorie == "badge" else ITEMS
		preparer_menu._objets(propre, dossier, [i for i, _ in objets])
		print(f"{source.name} → {dossier.relative_to(RACINE)} : {', '.join(i for i, _ in objets)}")


def _police(taille: int) -> ImageFont.ImageFont:
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default(taille)


def planche() -> None:
	"""Planche de validation à l'échelle du jeu : chaque icône à sa taille d'affichage (badge 72 px
	dans l'emplacement, 256 px en détail ; objet 112 px dans la liste du Sac, 256 en détail) sur le
	fond sombre des panneaux (PANEL_BG_STRONG)."""
	FICHE.mkdir(parents=True, exist_ok=True)
	fond = (20, 28, 41, 255)
	police, petite = _police(30), _police(22)
	lignes = [("Badges obtenus", BADGES, BADGE_IDS), ("Badge non obtenu (gabarit neutre)", BADGES, ["unknown"]),
		("Objets RP-265", ITEMS, RP265), ("Frères repeints [D]", ITEMS, FRERES)]
	largeur, haut = 40 + 10 * 290, 0
	for _t, _d, ids in lignes:
		haut += 60 + 256 + 120 + 40
	image = Image.new("RGBA", (largeur, haut), fond)
	dessin = ImageDraw.Draw(image)
	y = 20
	for titre, dossier, ids in lignes:
		dessin.text((40, y), titre, font=police, fill=(245, 197, 66, 255))
		y += 50
		for k, ident in enumerate(ids):
			x = 40 + k * 290
			chemin = dossier / f"{ident}.webp"
			if not chemin.exists():
				dessin.text((x, y + 100), "absent", font=petite, fill=(255, 90, 79, 255))
				continue
			icone = Image.open(chemin).convert("RGBA")
			image.alpha_composite(icone, (x, y))
			petit = icone.resize((72, 72) if dossier == BADGES else (112, 112), Image.LANCZOS)
			image.alpha_composite(petit, (x, y + 266))
			dessin.text((x + 130, y + 300), ident, font=petite, fill=(184, 196, 214, 255))
		y += 256 + 120 + 40
	sortie = FICHE / "planche.png"
	image.convert("RGB").save(sortie)
	print(sortie)
	_planche_captures()


CAPTURES = RACINE / "build" / "captures" / "menu_peint"
## Captures du jeu (tools/capture_menu_peint.gd, 2340 × 1080) montées à mi-échelle, deux par ligne.
CAPTURES_ORDRE = ["trainer_8b", "trainer_3b", "trainer_moments_8b", "dashboard_8b", "bag_field_8b",
	"bag_key_8b", "map_cerulean_city_8b", "map_ss_anne_8b"]


def _planche_captures() -> None:
	images = [CAPTURES / f"{nom}.png" for nom in CAPTURES_ORDRE if (CAPTURES / f"{nom}.png").exists()]
	if not images:
		print("aucune capture dans", CAPTURES)
		return
	largeur, hauteur, marge = 1170, 540, 16
	lignes = (len(images) + 1) // 2
	montage = Image.new("RGB", (2 * largeur + 3 * marge, lignes * (hauteur + marge) + marge), (20, 28, 41))
	for k, chemin in enumerate(images):
		capture = Image.open(chemin).convert("RGB").resize((largeur, hauteur), Image.LANCZOS)
		montage.paste(capture, (marge + (k % 2) * (largeur + marge), marge + (k // 2) * (hauteur + marge)))
	sortie = FICHE / "captures.jpg"
	montage.save(sortie, quality=88)
	print(sortie)


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--prompts" in arguments:
		prompts()
	elif "--generer" in arguments:
		generer({a for a in arguments if not a.startswith("--")})
	elif "--preparer" in arguments:
		preparer()
	elif "--planche" in arguments:
		planche()
	else:
		print(__doc__)
