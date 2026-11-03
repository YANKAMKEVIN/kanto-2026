#!/usr/bin/env python3
"""Image provisoire de la page Johto de la Carte (JOH0, docs/tech/jalon-joh0.md §2.13).

Dessine `assets/ui/map/johto_placeholder.webp` (1586×992, même taille que l'illustration de Kanto)
et `johto_placeholder_areas.json` (rectangle de chaque zone) d'après la géographie du dossier
JOH-00 §3 : Oliville sur la côte ouest, Rosalia au nord, Doublonville au centre, Écorcia au sud,
Acajou à l'est. Valeurs [D] ; l'illustration sera refaite en phase DA.

Usage : python3 -I tools/make_johto_map_placeholder.py
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "map")
W, H = 1586, 992
TOWNS = {
	"olivine_city": ((300, 540), "Oliville"),
	"ecruteak_city": ((560, 250), "Rosalia"),
	"goldenrod_city": ((880, 520), "Doublonville"),
	"azalea_town": ((880, 840), "Écorcia"),
	"mahogany_town": ((1320, 250), "Acajou"),
}
ROADS = [("olivine_city", "ecruteak_city"), ("ecruteak_city", "goldenrod_city"),
	("goldenrod_city", "azalea_town"), ("ecruteak_city", "mahogany_town")]


def main() -> None:
	img = Image.new("RGB", (W, H), (214, 206, 178))
	d = ImageDraw.Draw(img)
	d.rectangle([0, 0, 230, H], fill=(126, 168, 196))
	d.polygon([(0, 760), (420, 760), (520, H), (0, H)], fill=(126, 168, 196))
	d.rectangle([1180, 0, W, 420], fill=(168, 160, 150))
	d.ellipse([560, 620, 860, 900], fill=(118, 150, 98))
	for a, b in ROADS:
		d.line([TOWNS[a][0], TOWNS[b][0]], fill=(236, 226, 196), width=34)
	try:
		font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 34)
	except OSError:
		font = ImageFont.load_default()
	areas = {}
	for zone_id, ((x, y), name) in TOWNS.items():
		w, h = 200, 110
		x0, y0 = x - w // 2, y - h // 2
		d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=18, fill=(232, 120, 96),
			outline=(90, 40, 30), width=4)
		tw = d.textlength(name, font=font)
		d.text((x - tw / 2, y - 20), name, fill=(255, 255, 255), font=font)
		areas[zone_id] = {"area": [x0, y0, w, h]}
	d.text((40, 40), "JOHTO — carte provisoire (JOH0)", fill=(40, 40, 40), font=font)
	img.save(os.path.join(OUT, "johto_placeholder.webp"), quality=80, method=6)
	doc = {
		"_comment": "Rectangles [x, y, w, h] des zones de Johto sur assets/ui/map/johto_placeholder.webp "
			"(1586x992, image PROVISOIRE dessinee par tools/make_johto_map_placeholder.py au JOH0 d'apres "
			"la geographie du dossier JOH-00 §3 ; refaite en phase DA). Seule la geometrie vit ici ; "
			"l'identite des zones est dans data/world/zones.json.",
		"image": "res://assets/ui/map/johto_placeholder.webp", "image_size": [W, H], "zones": areas,
	}
	with open(os.path.join(OUT, "johto_placeholder_areas.json"), "w", encoding="utf-8") as f:
		f.write(json.dumps(doc, ensure_ascii=False, indent="\t") + "\n")


if __name__ == "__main__":
	main()
