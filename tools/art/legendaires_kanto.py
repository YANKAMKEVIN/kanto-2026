#!/usr/bin/env python3
"""Électhor, Sulfura et Mewtwo posés sur la carte (RP-132, RP-141), sur le modèle d'Artikodin.

Écrit les prompts dans `tools/art/prompts/legendaires_kanto/`, un par planche de 4 images
(repos, inspire, effet, repos), au format de `prompt_artikodin` (`serie27.py`).

`--sulfura` découpe `build/art/POKE_SULFURA_MONDE.png` en `sulfura_sheet.png` : le milieu des
pattes de chaque image au milieu du bas de sa cellule (la queue de flammes dépasse à droite).

`--electhor` fait de même pour `build/art/POKE_ELECTHOR_MONDE.png` (planche de Kevin, ChatGPT).

`--mewtwo` traite `build/art/POKE_MEWTWO_MONDE.png` (planche de Kevin, ChatGPT), dont le damier est
dessiné : le gris neutre devient transparent. Le halo de l'image 3, peint par-dessus le
damier, ne se détoure pas : l'image 3 reprend l'image 2 avec un halo calculé.

Usage : python3 tools/art/legendaires_kanto.py [--sulfura | --electhor | --mewtwo]
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ICI = Path(__file__).resolve().parent
SORTIE = ICI / "prompts" / "legendaires_kanto"
FICHES = {
	"POKE_ELECTHOR_MONDE": {
		"lieu": "un grand oiseau électrique POSÉ dans une centrale abandonnée, qui attend le joueur",
		"portrait": "ÉLECTHOR (Zapdos, n° 145), l'oiseau légendaire de foudre, fidèle à son design officiel : "
			"plumage JAUNE vif hérissé en pointes, dessous des ailes et queue en pointes noires, long bec "
			"pointu orange, pattes orange, regard vif. Puissant, sur le qui-vive.",
		"pose": "POSÉ au sol, debout sur ses deux pattes, de FACE, les ailes à demi repliées, les plumes "
			"hérissées, la tête haute",
		"effet": "de petits ARCS ÉLECTRIQUES jaune pâle courent sur ses plumes (discrets, fins, jamais un rayon)",
		"hauteur": 330,
	},
	"POKE_SULFURA_MONDE": {
		"lieu": "un grand oiseau de feu POSÉ au fond d'une grotte, qui attend le joueur",
		"portrait": "SULFURA (Moltres, n° 146), l'oiseau légendaire de feu, fidèle à son design officiel : "
			"plumage JAUNE ORANGÉ, longues ailes bordées de flammes, crête et longue queue faites de FLAMMES "
			"orange et jaunes, bec fin gris-jaune, longues pattes fines. Fier, solennel.",
		"pose": "POSÉ au sol, debout sur ses deux pattes, de FACE, les ailes à demi repliées, la queue de "
			"flammes qui retombe sur le côté, la tête haute",
		"effet": "les FLAMMES de sa crête et de ses ailes s'élèvent un peu plus haut, quelques braises montent "
			"(discret, transparent sur les bords, jamais un jet de feu)",
		"hauteur": 330,
	},
	"POKE_MEWTWO_MONDE": {
		"lieu": "une créature légendaire DEBOUT, immobile, au fond d'une grotte, qui attend le joueur",
		"portrait": "MEWTWO (n° 150), fidèle à son design officiel : silhouette humanoïde mince au corps "
			"gris-mauve pâle, ventre et longue queue épaisse VIOLETS, tête aux deux courtes cornes, tube "
			"reliant la nuque au dos, mains à trois doigts ronds, yeux violets graves. Calme, menaçant.",
		"pose": "DEBOUT, de FACE, les bras le long du corps, légèrement écartés, la queue qui passe derrière "
			"et ressort sur le côté, la tête droite",
		"effet": "une très légère LUEUR VIOLETTE l'entoure et la pointe de sa queue se soulève (discret, "
			"transparent sur les bords, jamais un rayon)",
		"hauteur": 300,
	},
}
MODELE = """{id} — planche d'animation d'un Pokémon du monde de Kanto 2026 : {lieu}.
Images jointes : l'artwork officiel (anatomie, couleurs et proportions seulement, pas son rendu ni sa pose) ; artikodin_sheet et rapasdepic_sheet = Pokémon déjà peints pour le monde du jeu : même rendu peint simplifié, même contour fin coloré, même finesse, même angle de vue.
Style : Pokémon peint simplifié comme les planches du jeu, contour fin coloré sans trait noir, volumes doux. Ni pixel art, ni 3D, ni anime aux contours noirs.
Lumière neutre et douce, venue du haut à gauche.

POKÉMON (identique dans toutes les images) : {portrait}
POSE : {pose}. Vue de dessus de trois quarts comme le jeu (caméra un peu au-dessus).

PLANCHE D'ANIMATION : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné). UNE seule ligne de 4 images, de gauche à droite, chacune dans une colonne invisible de 384 px, à la MÊME échelle (environ {hauteur} px de haut), les pieds de toutes les images sur la même ligne.
- Image 1 : au repos.
- Image 2 : il INSPIRE (la poitrine se gonfle un peu, la tête monte légèrement).
- Image 3 : {effet}.
- Image 4 : retour au repos, l'effet se dissipe.
Aucune ombre portée, aucun sol, aucun décor, aucun texte, aucun chiffre, aucun logo.
"""


def decouper_sulfura() -> None:
	source = Image.open("build/art/POKE_SULFURA_MONDE.png").convert("RGBA")
	# Alpha faible (halo de flammes) retiré, comme `seuil_alpha` d'Artikodin.
	alpha = source.getchannel("A").point(lambda a: 0 if a < 24 else a)
	source.putalpha(alpha)
	pattes_x, pieds_y, haut_y, demi = (172, 555, 937, 1320), 712, 262, 204
	echelle = 165 / (pieds_y - haut_y)
	largeur, hauteur = round(demi * 2 * echelle), 171
	planche = Image.new("RGBA", (largeur * 4, hauteur), (0, 0, 0, 0))
	for colonne, x in enumerate(pattes_x):
		image = source.crop((x - demi, haut_y, x + demi, pieds_y)).resize((largeur, 165), Image.LANCZOS)
		planche.paste(image, (colonne * largeur, hauteur - 165))
	planche.save("assets/sprites/pokemon/painted/sulfura_sheet.png")
	print(f"cellule {largeur} × {hauteur}")


def decouper_electhor() -> None:
	source = Image.open("build/art/POKE_ELECTHOR_MONDE.png").convert("RGBA")
	source.putalpha(source.getchannel("A").point(lambda a: 0 if a < 24 else a))
	pattes_x, pieds_y, haut_y, demi, hauteur = (178, 562, 947, 1330), 700, 290, 210, 150
	debuts_x = (20, 405, 788, 1172)
	echelle = hauteur / (pieds_y - haut_y)
	largeur = round(demi * 2 * echelle)
	planche = Image.new("RGBA", (largeur * 4, hauteur), (0, 0, 0, 0))
	for colonne, x in enumerate(pattes_x):
		image = source.crop((x - demi, haut_y, x + demi, pieds_y))
		# L'aile droite de l'image précédente entre dans la fenêtre : on l'efface.
		image.paste((0, 0, 0, 0), (0, 0, debuts_x[colonne] - (x - demi), image.height))
		planche.paste(image.resize((largeur, hauteur), Image.LANCZOS), (colonne * largeur, 0))
	planche.save("assets/sprites/pokemon/painted/electhor_sheet.png")
	print(f"cellule {largeur} × {hauteur}")


def retirer_damier(image: Image.Image) -> Image.Image:
	"""Gris neutre → transparent, y compris entre les bras et dans la boucle de la queue (le corps
	est toujours teinté, son contour sombre est gardé) ; le filtre médian retire les points isolés."""
	pixels = np.array(image.convert("RGB")).astype(np.int16)
	saturation = pixels.max(axis=2) - pixels.min(axis=2)
	fond = (saturation < 7) & (pixels.max(axis=2) >= 95)
	alpha = Image.fromarray(np.where(fond, 0, 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
	sortie = image.convert("RGBA")
	sortie.putalpha(alpha)
	return sortie


def halo(image: Image.Image) -> Image.Image:
	"""Lueur violette derrière la silhouette, transparente sur les bords."""
	lueur = image.getchannel("A").filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(9))
	couche = Image.new("RGBA", image.size, (168, 96, 235, 0))
	couche.putalpha(lueur.point(lambda a: round(a * 0.62)))
	couche.alpha_composite(image)
	return couche


def decouper_mewtwo() -> None:
	source = retirer_damier(Image.open("build/art/POKE_MEWTWO_MONDE.png"))
	pattes_x, pieds_y, haut_y, demi, hauteur = (175, 560, 945, 1328), 742, 278, 214, 160
	echelle = hauteur / (pieds_y - haut_y)
	largeur = round(demi * 2 * echelle)
	images = [source.crop((x - demi, haut_y, x + demi, pieds_y)) for x in pattes_x]
	for image, x, debut in zip(images, pattes_x, (40, 424, 808, 1192)):
		# La queue de l'image précédente entre dans la fenêtre : on l'efface.
		image.paste((0, 0, 0, 0), (0, 0, debut - (x - demi), image.height))
	images[2] = halo(images[1])
	planche = Image.new("RGBA", (largeur * 4, hauteur), (0, 0, 0, 0))
	for colonne, image in enumerate(images):
		planche.paste(image.resize((largeur, hauteur), Image.LANCZOS), (colonne * largeur, 0))
	planche.save("assets/sprites/pokemon/painted/mewtwo_sheet.png")
	print(f"cellule {largeur} × {hauteur}")


def main() -> None:
	if "--mewtwo" in sys.argv:
		decouper_mewtwo()
		return
	if "--sulfura" in sys.argv:
		decouper_sulfura()
		return
	if "--electhor" in sys.argv:
		decouper_electhor()
		return
	SORTIE.mkdir(parents=True, exist_ok=True)
	for identifiant, fiche in FICHES.items():
		(SORTIE / f"{identifiant}.txt").write_text(MODELE.format(id=identifiant, **fiche), encoding="utf-8")


if __name__ == "__main__":
	main()
