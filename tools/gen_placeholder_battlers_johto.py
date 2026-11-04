#!/usr/bin/env python3
"""Sprites de combat provisoires (64 × 64) des 51 espèces de Johto (Chapitre Johto, JOH2 [D]).

L'art de Johto (artworks officiels, dos peints) est un lot à part (JOH0, levier 4) : en attendant,
le combat n'affichait **rien** pour une espèce de Johto (BattleArt : ni artwork, ni sprite
provisoire). Ici : une silhouette neutre (ovale teinté par le type principal, numéro du Pokédex),
face et dos (dos plus sombre), pieds au bas de l'image, pour que les rencontres des Routes 39 et 38
et de Rosalia se jouent et se testent. Le lot d'art remplacera ces images.

    python3 tools/gen_placeholder_battlers_johto.py && godot --headless --path . --import
"""
import json
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/pokemon/placeholder")
SPECIES = os.path.join(ROOT, "data/pokemon/species/johto.json")
SIZE = 64
TYPE_COLORS = {
	"normal": (168, 160, 140), "fire": (230, 110, 60), "water": (80, 130, 220),
	"grass": (100, 180, 80), "electric": (240, 200, 60), "ice": (140, 210, 220),
	"fighting": (190, 60, 50), "poison": (150, 70, 170), "ground": (210, 170, 90),
	"flying": (150, 160, 230), "psychic": (240, 90, 140), "bug": (160, 180, 50),
	"rock": (170, 150, 90), "ghost": (110, 90, 150), "dragon": (110, 70, 230),
	"dark": (90, 70, 60), "steel": (170, 170, 190), "fairy": (230, 150, 190),
}


def silhouette(color, dex, back):
	img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	shade = 0.55 if back else 1.0
	fill = tuple(int(c * shade) for c in color) + (255,)
	edge = tuple(max(0, int(c * shade) - 50) for c in color) + (255,)
	draw.ellipse((10, 14, 54, 61), fill=fill, outline=edge, width=2)
	draw.ellipse((18, 4, 46, 30), fill=fill, outline=edge, width=2)
	if not back:
		draw.ellipse((24, 12, 29, 17), fill=(20, 20, 20, 255))
		draw.ellipse((35, 12, 40, 17), fill=(20, 20, 20, 255))
	draw.text((22 if dex < 100 else 19, 36), str(dex), fill=(255, 255, 255, 255))
	return img


def main():
	with open(SPECIES, encoding="utf-8") as handle:
		data = json.load(handle)
	species = data.get("species", data)
	count = 0
	for sid, entry in species.items():
		color = TYPE_COLORS.get(entry["types"][0], (160, 160, 160))
		for back in (False, True):
			path = os.path.join(OUT, "%s_%s.png" % (sid, "back" if back else "front"))
			if os.path.exists(path):
				continue
			silhouette(color, int(entry["dex"]), back).save(path)
			count += 1
	print("Sprites de combat provisoires de Johto : %d image(s) écrite(s)" % count)


if __name__ == "__main__":
	main()
