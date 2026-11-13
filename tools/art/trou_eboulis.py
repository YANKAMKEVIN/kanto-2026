"""Trous bouchés en « éboulis » : Îles Écume et Route Victoire (retour de Kevin, 2026-11-13).

Le rocher poussé dans un trou tombe à l'étage du dessous : le trou bouché montre des gravats et des
éclats de glace (ou de roche), plus un rocher entier. Sources Codex `build/art/DECAL_TROU_*_EBOULIS_r1.png`
(référence : le trou ouvert de la même grotte). Fond uni détouré, recadré sur l'anneau, réduit à 96 × 96.

    python3 tools/art/trou_eboulis.py
"""
from PIL import Image, ImageFilter

## Source Codex → image du jeu.
PAIRES = {
	"build/art/DECAL_TROU_ECUME_EBOULIS_r1.png": "assets/world/interiors/decal_trou_ecume_bouche_01.png",
	"build/art/DECAL_TROU_VICTOIRE_EBOULIS_r1.png": "assets/world/interiors/decal_trou_victoire_bouche_01.png",
}
TAILLE = 96
SEUIL = 22  # distance de couleur au fond en dessous de laquelle le pixel est transparent
DOUX = 18   # fondu du bord


def decoupe(source: str, cible: str) -> None:
	image = Image.open(source).convert("RGBA")
	fond = image.getpixel((4, 4))[:3]
	alpha = Image.new("L", image.size)
	px, pa = image.load(), alpha.load()
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, _ = px[x, y]
			d = max(abs(r - fond[0]), abs(g - fond[1]), abs(b - fond[2]))
			pa[x, y] = 0 if d <= SEUIL else min(255, (d - SEUIL) * 255 // DOUX)
	alpha = alpha.filter(ImageFilter.MinFilter(3))
	image.putalpha(alpha)
	image = image.crop(alpha.getbbox())
	cote = max(image.size)
	carre = Image.new("RGBA", (cote, cote))
	carre.alpha_composite(image, ((cote - image.width) // 2, (cote - image.height) // 2))
	carre.resize((TAILLE, TAILLE), Image.LANCZOS).save(cible)
	print(cible)


def main() -> None:
	for source, cible in PAIRES.items():
		decoupe(source, cible)


if __name__ == "__main__":
	main()
