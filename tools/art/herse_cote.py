"""Herse de l'Arène de Cramois'Île vue de profil, fermée et ouverte (audit du 2026-11-14).

La herse n° 4 (6..7, 16..17) coupe le mur nord-sud entre les deux salles du bas une fois le mur du
bas ajouté : elle se lit de profil, comme les grilles du Manoir (`grille_manoir_cote.py`). Source :
`build/art/INT_HERSE_COTE_r1.png` (Codex, planche fermée à gauche, ouverte à droite, fond magenta,
référence `int_herse_fermee_01` et `_ouverte_01` ; prompt dans le commit). Détourée, coupée en deux,
mise à l'échelle commune (hauteur HAUTEUR), élargie de ELARGIR pour rester lisible.

    python3 tools/art/herse_cote.py
"""
from PIL import Image

from grille_manoir_cote import detoure

SOURCE = "build/art/INT_HERSE_COTE_r1.png"
CIBLES = ("assets/world/props/int_herse_fermee_cote_01.png",
	"assets/world/props/int_herse_ouverte_cote_01.png")
HAUTEUR = 262  # 2 cases + le chapeau du pilier du fond, comme la grille du Manoir
ELARGIR = 2.2


def main() -> None:
	planche = Image.open(SOURCE).convert("RGBA")
	moities = [planche.crop((0, 0, planche.width // 2, planche.height)),
		planche.crop((planche.width // 2, 0, planche.width, planche.height))]
	images = [detoure(m) for m in moities]
	echelle = HAUTEUR / images[0].height
	for image, cible in zip(images, CIBLES):
		taille = (round(image.width * echelle * ELARGIR), round(image.height * echelle))
		image.resize(taille, Image.LANCZOS).save(cible)
		print(cible, taille)


if __name__ == "__main__":
	main()
