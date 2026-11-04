#!/usr/bin/env python3
"""Sprites provisoires du monde pour le jalon JOH7 (`docs/tech/jalon-joh7.md` §0 « Art ») : Suicune,
Lugia et Lokhlass posés dans les Îles Tourbillon (`pokemon/<espèce>` des PNJ), sans planche peinte
(lot d'art de Johto à venir, « Reportés »).

Même format que `tools/gen_placeholder_npcs.gd` : feuille `<espèce>_sheet.png` (2 colonnes × 4
rangées : bas, haut, gauche, droite ; colonne 1 = respiration) et `<espèce>_frames.tres`
(animations `idle_<dir>`), dans `assets/sprites/characters/placeholder/` ; affichées ×2. Silhouettes
simples (ellipses), couleurs de l'espèce ; Lugia plus grand (64 px natifs).

Usage : python3 tools/build_joh7_placeholders.py ; puis godot --headless --path . --import
"""

import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "assets", "sprites", "characters", "placeholder")
DIRECTIONS = ["down", "up", "left", "right"]
OUTLINE = (28, 28, 40, 255)

# espèce → taille de case, i/s, couleurs (corps, accent, ventre / détail)
SPECIES = {
	"suicune": (48, 1.4, (96, 176, 222), (140, 96, 190), (246, 248, 252)),
	"lugia": (64, 1.0, (232, 236, 244), (52, 82, 150), (150, 170, 210)),
	"lapras": (48, 1.6, (82, 150, 214), (196, 190, 170), (240, 230, 200)),
}


def draw(species, size, direction, breath, body, accent, belly):
	img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	s = size / 48.0
	up = -1 if breath else 0

	def e(cx, cy, rx, ry, color):
		d.ellipse([cx * s - rx * s, (cy + up) * s - ry * s, cx * s + rx * s, (cy + up) * s + ry * s],
			fill=color, outline=OUTLINE)

	side = direction in ("left", "right")
	flip = direction == "left"
	if species == "lapras":
		e(24, 34, 15, 9, body)                     # corps sur l'eau
		e(24, 30, 11, 7, accent)                   # carapace
		hx = 12 if flip else 36
		if side:
			d.line([(24 * s, 28 * s), (hx * s, 12 * s)], fill=body, width=int(5 * s))
			e(hx, 11, 5, 4, body)
		else:
			d.line([(24 * s, 28 * s), (24 * s, 12 * s)], fill=body, width=int(5 * s))
			e(24, 11, 5, 4, body)
			if direction == "down":
				e(22, 11, 1, 1, OUTLINE)
				e(26, 11, 1, 1, OUTLINE)
	elif species == "suicune":
		e(24, 30, 13, 9, body)                     # corps
		for x in (14, 20, 28, 34):                 # pattes
			d.rectangle([x * s - 2 * s, 34 * s, x * s + 2 * s, 42 * s], fill=body, outline=OUTLINE)
		hx = 11 if flip else (37 if side else 24)
		hy = 20 if side else 18
		e(hx, hy, 7, 6, body)                      # tête
		e(hx, hy - 6, 5, 4, accent)                # crinière
		d.line([((hx - 2) * s, (hy - 4) * s), ((hx + 12) * s, (hy + 14) * s)], fill=belly,
			width=int(2 * s))                      # rubans
		d.line([((hx + 2) * s, (hy - 4) * s), ((hx - 10) * s, (hy + 16) * s)], fill=belly,
			width=int(2 * s))
		if direction == "down":
			e(hx - 2, hy, 1, 1, OUTLINE)
			e(hx + 2, hy, 1, 1, OUTLINE)
	else:  # lugia
		e(24, 28, 9, 13, body)                     # corps
		e(24, 30, 6, 9, belly)                     # plaques
		for sign in (-1, 1):                       # ailes
			wx = 24 + sign * 16
			d.polygon([(24 * s, 22 * s), (wx * s, (14 + up) * s), ((wx + sign * 4) * s, 30 * s),
				(24 * s, 32 * s)], fill=body, outline=OUTLINE)
			d.line([((24 + sign * 8) * s, 24 * s), (wx * s, (16 + up) * s)], fill=accent,
				width=int(2 * s))
		e(24, 12, 6, 6, body)                      # tête
		e(24, 9, 4, 2, accent)                     # crête
		if direction == "down":
			e(22, 12, 1.2, 1.2, accent)
			e(26, 12, 1.2, 1.2, accent)
	return img


def frames_tres(species, size, fps):
	lines = ['[gd_resource type="SpriteFrames" format=3]', "",
		'[ext_resource type="Texture2D" path="res://assets/sprites/characters/placeholder/%s_sheet.png" id="1_sheet"]' % species,
		""]
	for row in range(4):
		for col in range(2):
			lines += ['[sub_resource type="AtlasTexture" id="f_%d_%d"]' % (row, col),
				'atlas = ExtResource("1_sheet")',
				"region = Rect2(%d, %d, %d, %d)" % (col * size, row * size, size, size), ""]
	anims = []
	for row, direction in enumerate(DIRECTIONS):
		anims.append('{\n"frames": [{\n"duration": 1.0,\n"texture": SubResource("f_%d_0")\n}, {\n'
			'"duration": 1.0,\n"texture": SubResource("f_%d_1")\n}],\n"loop": true,\n'
			'"name": &"idle_%s",\n"speed": %s\n}' % (row, row, direction, fps))
	lines += ["[resource]", "animations = [" + ", ".join(anims) + "]", ""]
	return "\n".join(lines)


def main():
	for species, (size, fps, body, accent, belly) in SPECIES.items():
		sheet = Image.new("RGBA", (size * 2, size * 4), (0, 0, 0, 0))
		for row, direction in enumerate(DIRECTIONS):
			for col in range(2):
				sheet.paste(draw(species, size, direction, col == 1, body, accent, belly),
					(col * size, row * size))
		sheet.save(os.path.join(DIR, species + "_sheet.png"))
		with open(os.path.join(DIR, species + "_frames.tres"), "w", encoding="utf-8") as handle:
			handle.write(frames_tres(species, size, fps))
		print("écrit :", species)


if __name__ == "__main__":
	main()
