#!/usr/bin/env python3
"""Électhor, Sulfura et Mewtwo posés sur la carte (RP-132, RP-141), sur le modèle d'Artikodin.

Écrit les prompts dans `tools/art/prompts/legendaires_kanto/`, un par planche de 4 images
(repos, inspire, effet, repos), au format de `prompt_artikodin` (`serie27.py`).

`--sulfura` découpe `build/art/POKE_SULFURA_MONDE.png` en `sulfura_sheet.png` : le milieu des
pattes de chaque image au milieu du bas de sa cellule (la queue de flammes dépasse à droite).

Usage : python3 tools/art/legendaires_kanto.py [--sulfura]
"""
import sys
from pathlib import Path

from PIL import Image

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


def main() -> None:
	if "--sulfura" in sys.argv:
		decouper_sulfura()
		return
	SORTIE.mkdir(parents=True, exist_ok=True)
	for identifiant, fiche in FICHES.items():
		(SORTIE / f"{identifiant}.txt").write_text(MODELE.format(id=identifiant, **fiche), encoding="utf-8")


if __name__ == "__main__":
	main()
