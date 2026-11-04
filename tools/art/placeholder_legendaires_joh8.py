#!/usr/bin/env python3
"""Apparences de carte PROVISOIRES d'Entei et de Ho-Oh (JOH8, sommet de la Tour Carillon) [D].

Aucun artwork de Johto n'existe encore (lot d'art du JOH0, levier 4) : sans image, `CharacterLook`
donnait l'apparence générique d'un PNJ humain. Ici, deux silhouettes dessinées (Entei : corps
fauve, crinière grise, nuage de fumée ; Ho-Oh : grand oiseau rouge et or, ailes ouvertes), image
fixe pour les quatre directions, à l'échelle de Mewtwo (190 px pour 2 m) : Entei 2,1 m → 180 px,
Ho-Oh 3,8 m → 240 px (réduit [D]). Un fichier déjà présent n'est **pas** remplacé (l'art d'un
autre jalon, le JOH6 pour Entei, gagne).

  python3 tools/art/placeholder_legendaires_joh8.py && godot --headless --path . --import
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "assets" / "sprites" / "pokemon" / "painted"

FRAMES = """[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/pokemon/painted/{image}" id="1_img"]

[sub_resource type="AtlasTexture" id="AtlasTexture_img"]
atlas = ExtResource("1_img")
region = Rect2(0, 0, {largeur}, {hauteur})

[resource]
animations = [{animations}]
"""
ANIMATION = """{{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_img")
}}],
"loop": true,
"name": &"{nom}",
"speed": 1.0
}}"""


def entei() -> Image.Image:
	img = Image.new("RGBA", (200, 180), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	brown, dark, mane, cream = (150, 82, 40), (90, 45, 25), (190, 190, 200), (235, 220, 180)
	for x in (40, 70, 128, 156):
		d.rounded_rectangle((x, 110, x + 18, 176), 6, fill=dark)
	d.ellipse((28, 62, 176, 140), fill=brown, outline=dark, width=3)
	d.polygon([(70, 70), (100, 20), (140, 30), (150, 72)], fill=mane, outline=(120, 120, 130))
	d.ellipse((120, 40, 186, 104), fill=brown, outline=dark, width=3)
	d.polygon([(150, 44), (168, 4), (176, 48)], fill=cream)
	d.ellipse((160, 64, 170, 74), fill=(250, 220, 60))
	d.ellipse((60, 18, 120, 48), fill=(130, 130, 140, 160))
	return img


def ho_oh() -> Image.Image:
	img = Image.new("RGBA", (260, 240), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	red, gold, green, white = (205, 50, 40), (240, 190, 60), (60, 160, 90), (245, 240, 230)
	d.polygon([(130, 110), (6, 40), (30, 120), (12, 170), (110, 150)], fill=red, outline=gold)
	d.polygon([(130, 110), (254, 40), (230, 120), (248, 170), (150, 150)], fill=red, outline=gold)
	d.polygon([(20, 60), (60, 120), (14, 150)], fill=green)
	d.polygon([(240, 60), (200, 120), (246, 150)], fill=green)
	d.ellipse((92, 80, 168, 200), fill=red, outline=gold, width=3)
	d.ellipse((104, 120, 156, 190), fill=white)
	d.ellipse((106, 36, 154, 90), fill=red, outline=gold, width=3)
	d.polygon([(126, 76), (134, 76), (130, 92)], fill=gold)
	d.polygon([(130, 40), (118, 6), (138, 30), (150, 4), (144, 40)], fill=gold)
	d.rounded_rectangle((110, 196, 122, 236), 4, fill=gold)
	d.rounded_rectangle((138, 196, 150, 236), 4, fill=gold)
	d.ellipse((120, 56, 128, 64), fill=(30, 30, 30))
	return img


def write(species: str, image: Image.Image) -> None:
	frames = SORTIE / f"{species}_frames.tres"
	if frames.exists():
		print(f"{frames.name} existe déjà : gardé")
		return
	name = f"{species}_provisoire.png"
	image.save(SORTIE / name)
	noms = ["idle", "idle_down", "idle_left", "idle_right", "idle_up"]
	frames.write_text(FRAMES.format(image=name, largeur=image.width, hauteur=image.height,
		animations=", ".join(ANIMATION.format(nom=n) for n in noms)), encoding="utf-8")
	print(f"{name} : {image.width} × {image.height}")


def rainbow_wing_icon() -> None:
	"""Icône provisoire du Sac de la Plume Arc-en-ciel (256 × 256, `assets/ui/items/`)."""
	path = RACINE / "assets" / "ui" / "items" / "rainbow_wing.webp"
	if path.exists():
		return
	img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	colors = [(230, 60, 50), (240, 140, 40), (245, 210, 60), (90, 190, 90), (70, 140, 230),
		(150, 90, 200)]
	for i, color in enumerate(colors):
		inset = i * 9
		d.ellipse((70 + inset, 20 + inset * 2, 186 - inset, 220 - inset), fill=color + (255,))
	d.line((128, 30, 128, 246), fill=(250, 245, 230, 255), width=6)
	img = img.rotate(-30, resample=Image.BICUBIC)
	img.save(path, "WEBP", lossless=True)
	print("rainbow_wing.webp : 256 × 256")


def main() -> None:
	write("entei", entei())
	write("ho_oh", ho_oh())
	rainbow_wing_icon()


if __name__ == "__main__":
	main()
