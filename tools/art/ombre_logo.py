#!/usr/bin/env python3
"""DAF.7b : ombre douce propre du logo de l'écran titre (dossier 13 : logo « posé sur le monde
avec une ombre douce »). Même cadre que le logo (1280 × 602) : l'écran titre la pose sous lui,
au même rectangle, pour que « 2026 » se lise aussi sur les toits clairs de Bourg Palette.

Usage : python3 tools/art/ombre_logo.py   (depuis la racine du dépôt)
Sortie : assets/ui/opening/logo_kanto_2026_ombre.png
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
LOGO = RACINE / "assets/ui/opening/logo_kanto_2026.png"
SORTIE = RACINE / "assets/ui/opening/logo_kanto_2026_ombre.png"
TEINTE = (10, 16, 32)       # bleu nuit du contour du logo, plus sombre
PROCHE = (6, 14, 0.85)      # dilatation (px), flou (px), opacité : ombre portée serrée
VOILE = (10, 40, 0.78)      # voile large et doux sous tout le logo (lisibilité de « 2026 »)


def couche(masque: Image.Image, dilatation: int, flou: float, opacite: float) -> np.ndarray:
	m = masque
	if dilatation > 0:
		m = m.filter(ImageFilter.MaxFilter(dilatation * 2 + 1))
	m = m.filter(ImageFilter.GaussianBlur(flou))
	return np.asarray(m, dtype=np.float32) / 255.0 * opacite


def main() -> None:
	logo = Image.open(LOGO).convert("RGBA")
	alpha = np.asarray(logo.split()[3])
	masque = Image.fromarray(np.where(alpha >= 200, 255, 0).astype(np.uint8))
	a = np.maximum(couche(masque, *PROCHE), couche(masque, *VOILE))
	out = np.zeros((logo.height, logo.width, 4), dtype=np.uint8)
	out[..., :3] = TEINTE
	out[..., 3] = np.clip(a * 255.0, 0, 255).astype(np.uint8)
	Image.fromarray(out).save(SORTIE)
	print(SORTIE.relative_to(RACINE))


if __name__ == "__main__":
	main()
