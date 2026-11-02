#!/usr/bin/env python3
"""Reliquats du chantier « Menu Dresseur peint » (demande de Kevin du 2026-11-02).

Peint les dernières icônes d'objets teintées :
  - la MASTER BALL (teinture violette de la Poké Ball, J26) ; la Super Ball et l'Hyper Ball
    (`great_ball`, `ultra_ball`) sont déjà peintes (séries 22 bis et DAF.5), pas des teintures ;
  - les CT (RP-256) : [D] un DISQUE DE CT peint par TYPE de capacité (les 13 types des CT du jeu),
    réutilisé par toutes les CT de ce type (`assets/ui/items/tm_<type>.webp`, résolu par
    [MenuArt.item_icon] via le type de la capacité enseignée), au lieu d'une image par CT. Les CS
    gardent leurs disques jaunes peints (un par CS, déjà peints).

Même gabarit que `menu_peint.py` (planches 1536 × 1024, 4 colonnes, carré 256, fond transparent).

Usage :
  tools/art/menu_peint_reliquats.py --prompts | --generer [PLANCHE…] | --preparer | --planche
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import menu_peint  # noqa: E402
import preparer_menu  # noqa: E402

RACINE = menu_peint.RACINE
ART = menu_peint.ART
PROMPTS = menu_peint.PROMPTS
ITEMS = menu_peint.ITEMS
FICHE = menu_peint.FICHE
_I = "assets/ui/items/"

_DISQUE = ("un DISQUE DE CT identique aux CT jointes (même forme, même taille, même angle de trois quarts) : "
	"socle ÉPAIS BLEU MARINE bien visible en dessous (aussi haut que sur les disques joints, jamais un disque plat), anneau de chrome brillant, FACE bombée et vernie de la couleur du "
	"type, petit TROU central cerclé de métal, et un SYMBOLE BLANC simple et plein à droite du trou")
_ANCRES_CT = [f"{_I}tm13.webp", f"{_I}tm38.webp", f"{_I}tm21.webp"]

# Types des CT du jeu (data/items : `teaches` → type de la capacité) : symbole, couleur de la face.
TYPES: list[tuple[str, str]] = [
	("normal", "face BEIGE GRISÉ (#A8A77A), symbole : un simple ANNEAU blanc épais (cercle vide)"),
	("fighting", "face ROUGE BRIQUE (#C22E28), symbole : un POING fermé blanc"),
	("flying", "face LAVANDE (#A98FF3), symbole : une AILE blanche déployée"),
	("poison", "face VIOLETTE (#A33EA1), symbole : une GOUTTE de poison blanche avec deux petites bulles"),
	("ground", "face OCRE SABLE (#E2BF65), symbole : deux COLLINES de terre stratifiées blanches"),
	("rock", "face OCRE OLIVE (#B6A136), symbole : un ROCHER facetté blanc"),
	("electric", "face JAUNE (#F7D02C), symbole : un ÉCLAIR blanc en zigzag"),
	("fire", "face ORANGE (#EE8130), symbole : une FLAMME blanche"),
	("water", "face BLEU FRANC (#6390F0), symbole : une GOUTTE d'eau blanche"),
	("grass", "face VERT FEUILLE (#7AC74C), symbole : une FEUILLE blanche"),
	("ice", "face BLEU GLACE (#96D9D6), symbole : un FLOCON de neige blanc"),
	("psychic", "face ROSE (#F95587), symbole : une SPIRALE blanche"),
	("dragon", "face INDIGO (#6F35FC), symbole : un CROC de dragon blanc recourbé"),
]


def _ct(ident: str, texte: str) -> tuple[str, str]:
	return (f"tm_{ident}", f"{_DISQUE} ; CT de type {ident.upper()} : {texte}")


PLANCHES: list[tuple[str, list[tuple[str, str]], list[str], str]] = [
	# Planche 1 refaite (1er essai : disques plats sans socle) avec les disques des planches 2 et 3.
	("UI_CT_TYPES_1", [_ct(*t) for t in TYPES[0:4]],
		[f"{_I}tm_fire.webp", f"{_I}tm_water.webp", f"{_I}tm_grass.webp"], "objet"),
	("UI_CT_TYPES_2", [_ct(*t) for t in TYPES[4:8]], _ANCRES_CT, "objet"),
	("UI_CT_TYPES_3", [_ct(*t) for t in TYPES[8:12]], _ANCRES_CT, "objet"),
	("UI_CT_TYPES_4", [_ct(*TYPES[12]),
		("master_ball", "la MASTER BALL : une sphère comme la Super Ball et l'Hyper Ball jointes (même modèle, "
			"même taille, même bande noire et même bouton blanc) : moitié haute VIOLETTE profonde avec deux "
			"petits DISQUES ROSE fuchsia ronds en relief de part et d'autre, et une lettre M BLANCHE au "
			"centre de la moitié haute (seule lettre autorisée) ; moitié basse blanche")],
		_ANCRES_CT[:1] + [f"{_I}great_ball.webp", f"{_I}ultra_ball.webp"], "objet"),
]
CT_IDS = [f"tm_{t}" for t, _ in TYPES]


def _prompt(ident: str, objets: list[tuple[str, str]], ancres: list[str], categorie: str) -> str:
	texte = menu_peint._prompt(ident, objets, ancres, categorie)
	# Les disques de CT reprennent le modèle des CT jointes (seuls la couleur et le symbole changent).
	texte = texte.replace("; n'en reproduis pas les objets.", "; les DISQUES DE CT reprennent EXACTEMENT "
		"le modèle des disques joints (seules la couleur de la face et le symbole changent), le reste n'est "
		"qu'une référence de rendu.")
	# La Master Ball porte son M : seule exception à l'interdiction des lettres.
	if any(i == "master_ball" for i, _ in objets):
		texte = texte.replace("Interdit : texte, lettres,", "Interdit (sauf le M de la Master Ball) : texte,")
	return texte


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for ident, objets, ancres, categorie in PLANCHES:
		fichier = PROMPTS / f"{ident}_r1.txt"
		fichier.write_text(_prompt(ident, objets, ancres, categorie), encoding="utf-8")
		print(fichier)


def generer(choix: set[str]) -> None:
	prompts()
	for ident, _o, ancres, _c in PLANCHES:
		nom = f"{ident}_r1"
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


def preparer() -> None:
	for ident, objets, _a, _c in PLANCHES:
		source = ART / f"{ident}_r1.png"
		if not source.exists():
			print(f"{source.name} : absente, ignorée")
			continue
		propre = ART / f"{ident}_r1_alpha.png"
		menu_peint._transparente(Image.open(source)).save(propre)
		preparer_menu._objets(propre, ITEMS, [i for i, _ in objets])
		for i, _ in objets:
			_nettoyer(ITEMS / f"{i}.webp")
		print(f"{source.name} → {', '.join(i for i, _ in objets)}")


def _plage(pleins: list[bool]) -> tuple[int, int]:
	"""Plus longue suite de colonnes (ou lignes) occupées."""
	meilleure, debut = (0, 0), -1
	for k, plein in enumerate(pleins + [False]):
		if plein and debut < 0:
			debut = k
		elif not plein and debut >= 0:
			if k - debut > meilleure[1] - meilleure[0]:
				meilleure = (debut, k)
			debut = -1
	return meilleure


def _nettoyer(chemin: Path) -> None:
	"""Retire les éclats d'une icône voisine restés au bord de la bande (séparés de l'objet par du
	vide), puis recentre et remet l'objet à la taille du gabarit (marge 8)."""
	icone = Image.open(chemin).convert("RGBA")
	alpha = icone.getchannel("A").point(lambda a: 255 if a > 24 else 0)
	colonnes = [alpha.crop((x, 0, x + 1, alpha.height)).getbbox() is not None for x in range(alpha.width)]
	gauche, droite = _plage(colonnes)
	lignes = [alpha.crop((gauche, y, droite, y + 1)).getbbox() is not None for y in range(alpha.height)]
	haut, bas = _plage(lignes)
	objet = icone.crop((gauche, haut, droite, bas))
	taille, marge = preparer_menu.OBJET_TAILLE, preparer_menu.OBJET_MARGE
	echelle = (taille - 2 * marge) / max(objet.size)
	objet = objet.resize((round(objet.width * echelle), round(objet.height * echelle)), Image.LANCZOS)
	carre = Image.new("RGBA", (taille, taille), (0, 0, 0, 0))
	carre.alpha_composite(objet, ((taille - objet.width) // 2, (taille - objet.height) // 2))
	carre.save(chemin, "WEBP", quality=preparer_menu.QUALITE, method=6)


def planche() -> None:
	"""Planche de validation à l'échelle : 256 px (détail) et 112 px (liste du Sac) sur PANEL_BG_STRONG."""
	FICHE.mkdir(parents=True, exist_ok=True)
	police, petite = menu_peint._police(30), menu_peint._police(22)
	lignes = [("Disques de CT par type [D] (1/2)", CT_IDS[:7]), ("Disques de CT par type [D] (2/2)", CT_IDS[7:]),
		("Balls : Master Ball repeinte (Poké, Super, Hyper pour comparaison)",
			["poke_ball", "great_ball", "ultra_ball", "master_ball"])]
	largeur = 40 + 7 * 290
	image = Image.new("RGBA", (largeur, len(lignes) * 476 + 20), (20, 28, 41, 255))
	dessin = ImageDraw.Draw(image)
	y = 20
	for titre, ids in lignes:
		dessin.text((40, y), titre, font=police, fill=(245, 197, 66, 255))
		y += 50
		for k, ident in enumerate(ids):
			x = 40 + k * 290
			chemin = ITEMS / f"{ident}.webp"
			if not chemin.exists():
				dessin.text((x, y + 100), f"{ident} absent", font=petite, fill=(255, 90, 79, 255))
				continue
			icone = Image.open(chemin).convert("RGBA")
			image.alpha_composite(icone, (x, y))
			image.alpha_composite(icone.resize((112, 112), Image.LANCZOS), (x, y + 266))
			dessin.text((x + 125, y + 310), ident, font=petite, fill=(184, 196, 214, 255))
		y += 426
	sortie = FICHE / "reliquats.png"
	image.convert("RGB").save(sortie)
	print(sortie)


CAPTURES = RACINE / "build" / "captures" / "menu_peint"
CAPTURES_ORDRE = ["title_continue_3b", "title_continue_8b", "bag_ball_8b", "bag_tm_8b", "map_full_8b",
	"map_full_3b"]


def planche_captures() -> None:
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
	sortie = FICHE / "reliquats-captures.jpg"
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
		planche_captures()
	else:
		print(__doc__)
