"""Grille du Manoir vue de profil, fermée et ouverte (retour de Kevin, 2026-11-13).

Les grilles posées dans un mur nord-sud (passage est-ouest) étaient dessinées de face. Source :
`build/art/INT_GRILLE_MANOIR_COTE_r1.png` (Codex, planche fermée à gauche, ouverte à droite, fond
magenta, référence `int_grille_manoir_fermee_01` et `_ouverte_01`). Détourée, coupée en deux,
mise à l'échelle commune (hauteur HAUTEUR pour la fermée), élargie de ELARGIR pour rester lisible.

    python3 tools/art/grille_manoir_cote.py
"""
from PIL import Image, ImageFilter

SOURCE = "build/art/INT_GRILLE_MANOIR_COTE_r1.png"
CIBLES = ("assets/world/props/int_grille_manoir_fermee_cote_01.png",
	"assets/world/props/int_grille_manoir_ouverte_cote_01.png")
HAUTEUR = 262  # 2 cases + le chapeau du pilier du fond
ELARGIR = 2.6
SEUIL, DOUX = 40, 30


def detoure(image: Image.Image) -> Image.Image:
	fond = image.getpixel((5, 5))[:3]
	alpha = Image.new("L", image.size)
	px, pa = image.load(), alpha.load()
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, _ = px[x, y]
			d = max(abs(r - fond[0]), abs(g - fond[1]), abs(b - fond[2]))
			pa[x, y] = 0 if d <= SEUIL else min(255, (d - SEUIL) * 255 // DOUX)
	image.putalpha(alpha.filter(ImageFilter.MinFilter(3)))
	return image.crop(image.getchannel("A").getbbox())


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
