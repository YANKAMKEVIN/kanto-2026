#!/usr/bin/env python3
"""DAF.7 « Identité » : icône de l'application (adaptive icon Android) et icône du projet.

Sources (gardées dans docs/design/fiches-assets/daf-7-identite/) :
- fond-icone-codex.png : paysage peint à l'heure dorée (Codex, prompt-fond-icone.txt) ;
- le « K » est détouré du logo validé (assets/ui/opening/logo_kanto_2026.png, OUV.1).

Sorties (assets/ui/icon/) :
- icon_fond_432.png         fond de l'adaptive icon (108 dp à xxxhdpi), plein cadre ;
- icon_premier_plan_432.png premier plan (K + ombre douce), dans la zone sûre de 66 dp ;
- icon_monochrome_432.png   icône thématique d'Android 13+ (silhouette blanche du K) ;
- icon_192.png              icône classique (Android < 8), carré arrondi ;
et assets/ui/icon.png (512, icône du projet et de l'éditeur, carré arrondi).

Usage : python3 tools/art/identite_daf7.py   (depuis la racine du dépôt)
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
SOURCES = RACINE / "docs/design/fiches-assets/daf-7-identite"
LOGO = RACINE / "assets/ui/opening/logo_kanto_2026.png"
SORTIE = RACINE / "assets/ui/icon"

CADRE = 432          # 108 dp × 4 (xxxhdpi)
ZONE_SURE = 264      # cercle de 66 dp : le premier plan n'en sort pas
LARGEUR_K = 196      # largeur du K dans le cadre de 432 (diagonale < zone sûre)
OMBRE = (14, 22, 40)  # bleu nuit du contour du logo


def detourer_k() -> Image.Image:
	"""Le K du logo, séparé du A qui le touche au pied (même géométrie que le logo 1280 × 602)."""
	im = np.array(Image.open(LOGO).convert("RGBA"))
	a = im[..., 3]
	h, w = a.shape
	yy, xx = np.mgrid[0:h, 0:w]
	cy, cx = yy - 110, xx - 20
	limite = np.interp(cy, [0, 40, 100, 200, 255], [345, 330, 292, 268, 283])
	zone_a = (cy < 255) & (cx > limite)
	plein = (a >= 250) & ~zone_a
	vu = np.zeros_like(plein)
	file = deque([(250, 150)])
	vu[250, 150] = True
	while file:
		y, x = file.popleft()
		for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			ny, nx = y + dy, x + dx
			if 0 <= ny < h and 0 <= nx < w and plein[ny, nx] and not vu[ny, nx]:
				vu[ny, nx] = True
				file.append((ny, nx))
	ys, xs = np.where(vu)
	k = im.copy()
	k[..., 3] = np.where(vu, a, 0)
	k = k[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
	# Amorce du contour du A restée collée à la jambe du K.
	for x in range(246, 278):
		k[150:int(218 + (x - 250) * 0.52), x, 3] = 0
	return Image.fromarray(k)


def premier_plan(k: Image.Image, cadre: int, largeur: int) -> Image.Image:
	echelle = largeur / k.width
	kk = k.resize((largeur, round(k.height * echelle)), Image.LANCZOS)
	calque = Image.new("RGBA", (cadre, cadre), (0, 0, 0, 0))
	pos = ((cadre - kk.width) // 2, (cadre - kk.height) // 2)
	# Ombre douce bleu nuit derrière le K : lisible sur le ciel orangé.
	alpha = Image.new("L", (cadre, cadre), 0)
	alpha.paste(kk.split()[3], pos)
	ombre_a = alpha.filter(ImageFilter.GaussianBlur(cadre * 0.035)).point(lambda v: int(v * 0.75))
	ombre = Image.new("RGBA", (cadre, cadre), OMBRE + (0,))
	ombre.putalpha(ombre_a)
	calque.alpha_composite(ombre, (0, round(cadre * 0.008)))
	calque.alpha_composite(kk, pos)
	return calque


def fond(cadre: int) -> Image.Image:
	src = Image.open(SOURCES / "fond-icone-codex.png").convert("RGB")
	s = src.width
	# La partie visible (72 dp sur 108) montre le soleil en haut et l'herbe en bas.
	cote = round(s * 0.74)
	cx, cy = s // 2, round(s * 0.55)
	boite = (cx - cote // 2, cy - cote // 2, cx + cote // 2, cy + cote // 2)
	return src.crop(boite).resize((cadre, cadre), Image.LANCZOS).convert("RGBA")


def carre_arrondi(img: Image.Image, rayon: float) -> Image.Image:
	masque = Image.new("L", (img.width * 4, img.height * 4), 0)
	ImageDraw.Draw(masque).rounded_rectangle(
		(0, 0, masque.width - 1, masque.height - 1), radius=round(rayon * 4), fill=255)
	masque = masque.resize(img.size, Image.LANCZOS)
	out = img.copy()
	out.putalpha(masque)
	return out


def icone_classique(k: Image.Image, cote: int) -> Image.Image:
	"""Ce qu'un lanceur montre de l'adaptive icon (72 dp centraux), en carré arrondi."""
	grand = fond(CADRE)
	grand.alpha_composite(premier_plan(k, CADRE, LARGEUR_K))
	marge = (CADRE - 288) // 2
	vue = grand.crop((marge, marge, CADRE - marge, CADRE - marge))
	vue = vue.resize((cote, cote), Image.LANCZOS)
	return carre_arrondi(vue, cote * 0.22)


def main() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	k = detourer_k()
	fond(CADRE).convert("RGB").save(SORTIE / "icon_fond_432.png")
	premier_plan(k, CADRE, LARGEUR_K).save(SORTIE / "icon_premier_plan_432.png")
	mono = premier_plan(k, CADRE, LARGEUR_K)
	blanc = Image.new("RGBA", mono.size, (255, 255, 255, 0))
	cadre_k = Image.new("L", mono.size, 0)
	kk = k.resize((LARGEUR_K, round(k.height * LARGEUR_K / k.width)), Image.LANCZOS)
	cadre_k.paste(kk.split()[3], ((CADRE - kk.width) // 2, (CADRE - kk.height) // 2))
	blanc.putalpha(cadre_k)
	blanc.save(SORTIE / "icon_monochrome_432.png")
	icone_classique(k, 192).save(SORTIE / "icon_192.png")
	icone_classique(k, 512).save(RACINE / "assets/ui/icon.png")
	print("Icônes écrites dans", SORTIE.relative_to(RACINE), "et assets/ui/icon.png")


if __name__ == "__main__":
	main()
