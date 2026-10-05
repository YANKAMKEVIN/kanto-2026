#!/usr/bin/env python3
"""Reconstruit un sprite de combat (pixel art) en petite illustration Kanto 2026, sans IA.

Image par image (l'animation est conservée) :
1. les traits (pixels sombres : contour, œil, bouche, séparations) sont séparés des masses ;
   sous eux, les masses reprennent la couleur voisine ;
2. agrandissement ×ECHELLE, masses aux angles arrondis et transitions adoucies : palette et
   volumes d'origine conservés, aucun détail ajouté ;
3. les traits gardent leur tracé, affinés et lissés en courbes nettes, recolorés en teinte
   sombre chaude (couleur voisine × CONTOUR), jamais noirs : le contour coloré du monde ;
4. silhouette identique, escaliers remplacés par une courbe nette ;
5. grain pictural très léger.

Usage :
  tools/art/reconstruire_sprite.py planche.png sortie.png --cadre 46x46 --images 55
      [--colonnes N] [--echelle 8]
La planche d'entrée est une bande horizontale (ou une grille de --colonnes) d'images de la
taille --cadre ; la sortie est une grille d'au plus 4096 px de large.
"""
import argparse
import random

from PIL import Image, ImageChops, ImageFilter

SEUIL_TRAIT = 70        # luminance (0-255) sous laquelle un pixel opaque est un trait
CONTOUR = (0.50, 0.34, 0.36)  # trait : couleur voisine × ce facteur par canal (sombre chaud)
GRAIN = 3               # amplitude du grain (niveaux de 0-255)


def _luma(c):
	return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def _voisins(px, w, h, x, y, accepte):
	out = []
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
		nx, ny = x + dx, y + dy
		if 0 <= nx < w and 0 <= ny < h and accepte(nx, ny):
			out.append(px[nx, ny])
	return out


def nettoyer(image):
	"""Sépare les traits (pixels sombres) des masses de couleur. Rend (masses RGBA, où chaque
	pixel de trait prend la couleur moyenne de ses voisins non-traits ; masque des traits ;
	couleur de chaque trait = couleur voisine assombrie et réchauffée, jamais noire)."""
	img = image.convert("RGBA")
	w, h = img.size
	px = img.load()
	trait = {(x, y) for y in range(h) for x in range(w)
		if px[x, y][3] > 128 and _luma(px[x, y]) < SEUIL_TRAIT}
	vide = lambda x, y: not (0 <= x < w and 0 <= y < h) or px[x, y][3] <= 128
	# Contour extérieur (touche le vide, diagonales comprises) : redessiné plus loin le long
	# de la silhouette ; un trait collé à lui fait aussi partie du contour.
	autour = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
	exterieur = {(x, y) for (x, y) in trait if any(vide(x + dx, y + dy) for dx, dy in autour)}
	exterieur |= {(x, y) for (x, y) in trait - exterieur
		if sum((x + dx, y + dy) in exterieur for dx, dy in autour) >= 3}
	masses = img.copy()
	pm = masses.load()
	a_remplir = set(trait)
	for _ in range(8):
		fait = {}
		for (x, y) in a_remplir:
			cols = _voisins(pm, w, h, x, y,
				lambda nx, ny: pm[nx, ny][3] > 128 and (nx, ny) not in a_remplir)
			if cols:
				fait[(x, y)] = tuple(sum(c[i] for c in cols) // len(cols) for i in range(3))
		for (x, y), c in fait.items():
			pm[x, y] = c + (px[x, y][3],)
		a_remplir -= set(fait)
		if not a_remplir:
			break
	masque = Image.new("L", (w, h), 0)
	couleur_traits = Image.new("RGB", (w, h), (0, 0, 0))
	mq, ct = masque.load(), couleur_traits.load()
	for (x, y) in trait - exterieur:
		mq[x, y] = 255
	for (x, y) in trait:
		r, g, b, _a = pm[x, y]
		ct[x, y] = (int(r * CONTOUR[0]), int(g * CONTOUR[1]), int(b * CONTOUR[2]))
	return masses, masque, couleur_traits


def _etendre(couleurs, rayon):
	"""Étend les couleurs opaques vers l'extérieur (évite les franges sombres au flou)."""
	base = couleurs.copy()
	for _ in range(rayon):
		grand = base.filter(ImageFilter.MaxFilter(3))
		base = Image.composite(base, grand,
			base.getchannel("A").point(lambda a: 255 if a > 0 else 0))
		base.putalpha(255)
	return base


def _courbe(masque, echelle, flou, seuil, pente):
	"""Masque agrandi puis lissé en courbe nette : escaliers → courbe, sans flou visible."""
	W, H = masque.width * echelle, masque.height * echelle
	m = masque.resize((W, H), Image.NEAREST).filter(ImageFilter.GaussianBlur(echelle * flou))
	return m.point(lambda a: max(0, min(255, int((a - seuil) * pente + 128))))


def reconstruire(image, echelle):
	masses, traits, couleur_traits = nettoyer(image)
	w, h = masses.size
	marge = 2
	def encadrer(im, mode, fond):
		c = Image.new(mode, (w + 2 * marge, h + 2 * marge), fond)
		c.paste(im, (marge, marge))
		return c
	masses = encadrer(masses, "RGBA", (0, 0, 0, 0))
	traits = encadrer(traits, "L", 0)
	couleur_traits = encadrer(couleur_traits, "RGB", (0, 0, 0))
	W, H = masses.width * echelle, masses.height * echelle
	# Masses : agrandies, angles arrondis (petit filtre de mode), transitions adoucies.
	plein = _etendre(masses, 3).convert("RGB").resize((W, H), Image.NEAREST)
	plein = plein.filter(ImageFilter.ModeFilter(max(3, echelle // 2) | 1))
	plein = plein.filter(ImageFilter.GaussianBlur(echelle * 0.3))
	# Couleur sombre chaude des traits, étendue pour couvrir les tracés lissés.
	ct = Image.composite(couleur_traits, Image.merge("RGB", [c.point(
		lambda v, k=k: int(v * k)) for c, k in zip(masses.convert("RGB").split(), CONTOUR)]),
		traits.point(lambda v: 255 if v else 0))
	ct = ct.resize((W, H), Image.NEAREST).filter(ImageFilter.GaussianBlur(echelle * 0.5))
	# Traits intérieurs (œil, bouche, séparations) : même tracé, lissé en courbe continue.
	t = _courbe(traits, echelle, 0.4, 105, 4)
	plein = Image.composite(ct, plein, t)
	# Silhouette : même forme, bord en courbe nette.
	alpha = _courbe(masses.getchannel("A"), echelle, 0.7, 128, 7)
	# Contour extérieur : bande continue d'épaisseur régulière le long de la silhouette.
	epaisseur = max(5, echelle) | 1
	bande = ImageChops.subtract(alpha, alpha.filter(ImageFilter.MinFilter(epaisseur)))
	plein = Image.composite(ct, plein, bande.filter(ImageFilter.GaussianBlur(0.6)))
	# Grain pictural très léger.
	random.seed(4)
	bruit = Image.effect_noise((W, H), 40).filter(ImageFilter.GaussianBlur(1.2))
	bruit = bruit.point(lambda v: 128 + int((v - 128) * GRAIN / 40))
	plein = ImageChops.add(plein, Image.merge("RGB", (bruit,) * 3), 1.0, -128)
	sortie = plein.convert("RGBA")
	sortie.putalpha(alpha)
	return sortie


def main():
	args = argparse.ArgumentParser()
	args.add_argument("planche")
	args.add_argument("sortie")
	args.add_argument("--cadre", required=True, help="LxH d'une image, ex. 46x46")
	args.add_argument("--images", type=int, required=True)
	args.add_argument("--colonnes", type=int, default=0)
	args.add_argument("--echelle", type=int, default=8)
	o = args.parse_args()
	fw, fh = (int(v) for v in o.cadre.split("x"))
	colonnes = o.colonnes or o.images
	planche = Image.open(o.planche).convert("RGBA")
	images = []
	for i in range(o.images):
		x, y = (i % colonnes) * fw, (i // colonnes) * fh
		images.append(reconstruire(planche.crop((x, y, x + fw, y + fh)), o.echelle))
	cw, ch = images[0].size
	cols = max(1, 4096 // cw)
	rows = -(-len(images) // cols)
	sortie = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))
	for i, im in enumerate(images):
		sortie.alpha_composite(im, ((i % cols) * cw, (i // cols) * ch))
	sortie.save(o.sortie)
	print(o.sortie, sortie.size, "cadre", (cw, ch), "colonnes", cols)


if __name__ == "__main__":
	main()
