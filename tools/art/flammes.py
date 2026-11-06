#!/usr/bin/env python3
"""Découpe `build/art/INT_FLAMMES_PLANCHE.png` (prompt : `tools/art/prompts/decor_souvenir/`) en six
flammes `int_flamme_0N` pour le souvenir de Dante. Usage : python3 tools/art/flammes.py
"""
from PIL import Image


def main() -> None:
	source = Image.open("build/art/INT_FLAMMES_PLANCHE.png").convert("RGBA")
	for numero in range(6):
		colonne, ligne = numero % 3, numero // 3
		case = source.crop((colonne * 512, ligne * 512, (colonne + 1) * 512, (ligne + 1) * 512))
		flamme = case.crop(case.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox())
		hauteur = 110 if numero % 2 else 86
		largeur = round(flamme.width * hauteur / flamme.height)
		flamme.resize((largeur, hauteur), Image.LANCZOS).save(
			f"assets/world/interiors/int_flamme_{numero + 1:02d}.png")


if __name__ == "__main__":
	main()
