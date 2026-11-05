#!/usr/bin/env python3
"""Planches provisoires des Pokémon du monde du JOH6 (`docs/tech/jalon-joh6.md` §2.3) : Raikou,
Entei et Suicune (silhouettes de combat provisoires agrandies), Persian (artwork officiel) et le
**Léviator rouge** (artwork officiel, teinte tournée comme en combat : `PokemonVariant`, 0,42 tour).
Une image fixe par planche, animations « idle » et « idle_<direction> » (comme Artikodin) : ces
Pokémon ne marchent pas (ils disparaissent en fondu). Sans planche, la carte saute un Pokémon du
décor (`GameMap.awaits_painted_look`). À remplacer par l'art (Reportés).

Usage : python3 tools/gen_joh6_world_pokemon.py   (Pillow)
"""

import colorsys
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "pokemon", "painted")
SRC = os.path.join(ROOT, "assets", "sprites", "pokemon")
# nom de la planche (`pokemon/<nom>`) → (source, hauteur affichée en px, rotation de teinte)
SHEETS = {
	"raikou": ("placeholder/raikou_front.png", 150, 0.0),
	"entei": ("placeholder/entei_front.png", 150, 0.0),
	"suicune": ("placeholder/suicune_front.png", 150, 0.0),
	"persian": ("official/053.png", 110, 0.0),
	"gyarados_red": ("official/130.png", 230, 0.42),
	# Arc des Pierres (JOHP3) : le Dracolosse de Corentin, le Farfuret de Cenere.
	"dragonite": ("official/149.png", 180, 0.0),
	"sneasel": ("placeholder/sneasel_front.png", 100, 0.0),
}
DIRECTIONS = ["", "_down", "_left", "_right", "_up"]


def hue_shift(image, shift):
	pixels = image.load()
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, a = pixels[x, y]
			if a == 0:
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			r2, g2, b2 = colorsys.hsv_to_rgb((h + shift) % 1.0, s, v)
			pixels[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
	return image


def main():
	for name, (source, height, shift) in SHEETS.items():
		image = Image.open(os.path.join(SRC, source)).convert("RGBA")
		box = image.getbbox()
		image = image.crop(box)
		width = round(image.width * height / image.height)
		resample = Image.NEAREST if source.startswith("placeholder") else Image.LANCZOS
		image = image.resize((width, height), resample)
		if shift:
			image = hue_shift(image, shift)
		sheet = "%s_world_sheet.png" % name
		image.save(os.path.join(OUT, sheet))
		animations = []
		for direction in DIRECTIONS:
			animations.append('{\n"frames": [{\n"duration": 1.0,\n"texture": SubResource("frame")\n}],\n'
				'"loop": true,\n"name": &"idle%s",\n"speed": 1.0\n}' % direction)
		text = ('[gd_resource type="SpriteFrames" format=3]\n\n'
			'[ext_resource type="Texture2D" path="res://assets/sprites/pokemon/painted/%s" id="1_sheet"]\n\n'
			'[sub_resource type="AtlasTexture" id="frame"]\natlas = ExtResource("1_sheet")\n'
			'region = Rect2(0, 0, %d, %d)\n\n[resource]\nanimations = [%s]\n'
			% (sheet, width, height, ", ".join(animations)))
		with open(os.path.join(OUT, "%s_frames.tres" % name), "w", encoding="utf-8") as handle:
			handle.write(text)
		print("écrit :", sheet, "(%d × %d)" % (width, height))


if __name__ == "__main__":
	main()
