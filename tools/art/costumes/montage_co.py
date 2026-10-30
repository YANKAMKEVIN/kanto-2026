#!/usr/bin/env python3
"""Chantier CO : montage à l'échelle du jeu (1:1, fond d'herbe) des planches d'un ou plusieurs
badges, comme `reference/joueuse-rivale-jeu-v1.webp`. Chaque version est précédée de la marche de
son homologue (héros ou joueuse) pour comparer l'échelle ; tant que la joueuse n'est pas dans la
branche, JOUEUSE=chemin/vers/joueuse_sheet.png la fournit.
Usage : tools/art/costumes/montage_co.py SORTIE.webp BADGE [BADGE ...]
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parents[3]
P = RACINE / "assets/sprites/characters/painted"
C = P / "costumes"
FOND = (106, 150, 84, 255)
MARGE = 24


def _img(chemin: Path) -> Image.Image | None:
	return Image.open(chemin).convert("RGBA") if chemin.exists() else None


def _ligne(images: list[Image.Image | None]) -> Image.Image:
	images = [i for i in images if i is not None]
	largeur = sum(i.width for i in images) + MARGE * (len(images) + 1)
	hauteur = max(i.height for i in images) + 2 * MARGE
	ligne = Image.new("RGBA", (largeur, hauteur), FOND)
	x = MARGE
	for i in images:
		ligne.alpha_composite(i, (x, hauteur - MARGE - i.height))
		x += i.width + MARGE
	return ligne


def _bloc(badge: str, version: str, homologue: Path) -> Image.Image:
	b = f"{badge.lower()}_{version}"
	f = lambda suffixe: _img(C / f"{b}_{suffixe}")  # noqa: E731
	buste = f("bust.webp")
	if buste is not None:
		buste = buste.resize((buste.width * 384 // buste.height, 384), Image.LANCZOS)
	lignes = [
		_ligne([_img(homologue), f("sheet.png"),
			f("run_sheet.png"), f("idle_sheet.png")]),
		_ligne([f("bike_sheet.png"), f("bike_idle_sheet.png"), f("surf_sheet.png")]),
		_ligne([f("fish_cast_sheet.png"), f("fish_wait_sheet.png"), f("lancer.png"), buste]),
	]
	largeur = max(l.width for l in lignes)
	bloc = Image.new("RGBA", (largeur, sum(l.height for l in lignes)), FOND)
	y = 0
	for l in lignes:
		bloc.alpha_composite(l, (0, y))
		y += l.height
	return bloc


def main() -> None:
	sortie, badges = Path(sys.argv[1]), sys.argv[2:]
	blocs = []
	for badge in badges:
		joueuse = Path(os.environ.get("JOUEUSE", P / "joueuse_sheet.png"))
		blocs.append(_ligne([_bloc(badge, "joueur", P / "heros_sheet.png"),
			_bloc(badge, "joueuse", joueuse)]))
	largeur = max(b.width for b in blocs)
	montage = Image.new("RGBA", (largeur, sum(b.height for b in blocs)), FOND)
	y = 0
	for b in blocs:
		montage.alpha_composite(b, (0, y))
		y += b.height
	montage.convert("RGB").save(sortie, quality=88, method=6)
	print(f"{sortie} : {montage.width} × {montage.height}")


if __name__ == "__main__":
	main()
