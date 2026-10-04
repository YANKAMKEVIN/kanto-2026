#!/usr/bin/env python3
"""Étalonnage commun de la série 01 (cahier de l'art du monde, cran A).

Ramène les jaunes / verts-jaunes vers le vert et les ombres turquoise vers le
vert-bleu, pour coller aux verts émeraude des références J7.
Usage : tools/art/etalonner.py entree.(png|webp) sortie.png
"""
import sys
from PIL import Image

# Teintes sur 0–255 (échelle HSV de Pillow).
JAUNES = (34, 70, 0.45)   # [début, fin[, force : tirées vers la fin (en dessous de 34 : pierre beige, bois)
TURQUOISES = (95, 125, 0.35)  # ]début, fin], force : tirées vers le début
SATURATION = 0.95
# Seuls les pixels assez saturés (la végétation) sont corrigés : la pierre
# beige a une teinte proche des jaunes mais une saturation faible.
SEUIL_SATURATION = 90


def _teinte(x: int) -> int:
    debut, fin, force = JAUNES
    if debut <= x < fin:
        return int(x + (fin - x) * force)
    debut, fin, force = TURQUOISES
    if debut < x <= fin:
        return int(x - (x - debut) * force)
    return x


def etalonner(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    h, s, v = rgb.convert("HSV").split()
    masque = s.point(lambda x: 255 if x >= SEUIL_SATURATION else 0)
    h = h.point(_teinte)
    s = s.point(lambda x: int(x * SATURATION))
    corrige = Image.merge("HSV", (h, s, v)).convert("RGB")
    sortie = Image.composite(corrige, rgb, masque)
    sortie.putalpha(alpha)
    return sortie


if __name__ == "__main__":
    etalonner(Image.open(sys.argv[1])).save(sys.argv[2])
