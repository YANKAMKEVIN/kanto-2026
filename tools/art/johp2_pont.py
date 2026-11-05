#!/usr/bin/env python3
"""Pont du Goéland (JOHP2) : met à l'échelle le bateau de Codex sur la grille, ajoute l'écume autour de
la coque et compose une mer raccordable à partir de celle de la vue générale.

Entrées : `build/art/WORLD_PROP_GOELAND_PONT_NE_r1.png`, `docs/design/reference/goeland-deck-vue-generale-v1.png`.
Sorties : `assets/world/props/prop_goeland_pont_01.png`, `assets/world/ground/ground_mer_goeland_01.png` ;
la position du bateau s'affiche, à reporter dans `DECK_BOAT_AT` de `tools/build_johp2_maps.gd`.

Usage : python3 tools/art/johp2_pont.py
"""
import random

import numpy as np
from PIL import Image, ImageChops, ImageFilter

SOURCE = "build/art/WORLD_PROP_GOELAND_PONT_NE_r1.png"
VIEW = "docs/design/reference/goeland-deck-vue-generale-v1.png"
BOAT = "assets/world/props/prop_goeland_pont_01.png"
SEA = "assets/world/ground/ground_mer_goeland_01.png"
# Plancher dans l'image source (pixels) et sur la grille (pixels de carte).
FLOOR_SOURCE = (70, 265)
FLOOR_MAP = (96, 192)
SCALE = (1.05, 0.965)
FOAM_PAD = 64
SEA_SIZE = (2048, 1024)
PATCH = (360, 170)
PATCHES = 520


def noise(size, blur, seed):
	rng = np.random.default_rng(seed)
	grain = Image.fromarray((rng.random((size[1], size[0])) * 255).astype("uint8"))
	values = np.asarray(grain.filter(ImageFilter.GaussianBlur(blur)), dtype=float)
	return (values - values.min()) / max(values.max() - values.min(), 1)


def boat():
	image = Image.open(SOURCE).convert("RGBA")
	box = image.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
	image = image.crop(box)
	size = (round(image.size[0] * SCALE[0]), round(image.size[1] * SCALE[1]))
	image = image.resize(size, Image.LANCZOS)
	canvas_size = (size[0] + FOAM_PAD * 2, size[1] + FOAM_PAD * 2)
	alpha = Image.new("L", canvas_size, 0)
	alpha.paste(image.getchannel("A"), (FOAM_PAD, FOAM_PAD))
	# Écume : halo autour de la coque, troué par un bruit, plus dense contre le bois.
	near = np.asarray(alpha.filter(ImageFilter.GaussianBlur(16)), dtype=float) / 255
	grain = noise(canvas_size, 3, 7) * 0.55 + noise(canvas_size, 9, 8) * 0.45
	rank = grain.ravel().argsort().argsort().reshape(grain.shape) / grain.size
	foam = np.clip((rank + near * 1.15 - 1.02) * 5.0, 0, 1) * np.clip(near * 3.0, 0, 1)
	foam_alpha = Image.fromarray((foam * 200).astype("uint8")).filter(ImageFilter.GaussianBlur(0.8))
	foam_alpha = ImageChops.subtract(foam_alpha, alpha)
	out = Image.merge("RGBA", (Image.new("L", canvas_size, 236), Image.new("L", canvas_size, 245),
		Image.new("L", canvas_size, 250), foam_alpha))
	out.alpha_composite(image, (FOAM_PAD, FOAM_PAD))
	out.save(BOAT, optimize=True)
	x = FLOOR_MAP[0] + (box[0] - FLOOR_SOURCE[0]) * SCALE[0] - FOAM_PAD
	y = FLOOR_MAP[1] + (box[1] - FLOOR_SOURCE[1]) * SCALE[1] - FOAM_PAD
	print("bateau", out.size, "DECK_BOAT_AT", round(x), round(y))


def sea():
	view = Image.open(VIEW).convert("RGB")
	bands = [view.crop((0, 0, view.width, 186)), view.crop((0, 838, view.width, view.height))]
	mean = tuple(int(v) for v in np.asarray(bands[0]).reshape(-1, 3).mean(axis=0))
	canvas = Image.new("RGB", SEA_SIZE, mean)
	feather = Image.new("L", PATCH, 0)
	feather.paste(255, (46, 46, PATCH[0] - 46, PATCH[1] - 46))
	feather = feather.filter(ImageFilter.GaussianBlur(20))
	rng = random.Random(11)
	for _ in range(PATCHES):
		band = rng.choice(bands)
		sx = rng.randrange(0, band.width - PATCH[0])
		sy = rng.randrange(0, band.height - PATCH[1] + 1)
		patch = band.crop((sx, sy, sx + PATCH[0], sy + PATCH[1]))
		x, y = rng.randrange(SEA_SIZE[0]), rng.randrange(SEA_SIZE[1])
		# Raccord : le morceau revient de l'autre côté de l'image.
		for dx in (0, -SEA_SIZE[0]):
			for dy in (0, -SEA_SIZE[1]):
				canvas.paste(patch, (x + dx, y + dy), feather)
	canvas.save(SEA, optimize=True)
	print("mer", canvas.size)


if __name__ == "__main__":
	boat()
	sea()
