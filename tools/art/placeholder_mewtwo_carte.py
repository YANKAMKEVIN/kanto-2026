#!/usr/bin/env python3
"""Apparence de carte PROVISOIRE de Mewtwo (jalon 31, QA A17 du 2026-10-24).

Sans planche peinte, `CharacterLook` donnait l'apparence générique (un PNJ humain) au Mewtwo du
B1F de la Grotte Azurée. En attendant l'art (planche du catalogue, `build_character_frames.gd`,
comme Artikodin), ce script réduit l'artwork officiel n° 150 à l'échelle d'Artikodin (171 px de
haut pour 1,7 m ; Mewtwo, 2,0 m : 190 px [D]) et écrit une image fixe pour les quatre directions.
Remplacer par le vrai art = régénérer `mewtwo_frames.tres` avec l'outil des planches.

  python3 tools/art/placeholder_mewtwo_carte.py

Écrit dans `assets/sprites/pokemon/painted/` : `mewtwo_provisoire.png` et `mewtwo_frames.tres`
(`idle`, `idle_down|left|right|up`, une image chacune ; `"sprite": "pokemon/mewtwo"`).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parents[2]
SOURCE = RACINE / "assets" / "sprites" / "pokemon" / "official" / "150.png"
SORTIE = RACINE / "assets" / "sprites" / "pokemon" / "painted"
IMAGE = "mewtwo_provisoire.png"
HAUTEUR = 190

FRAMES = """[gd_resource type="SpriteFrames" format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/pokemon/painted/{image}" id="1_mewtwo"]

[sub_resource type="AtlasTexture" id="AtlasTexture_mewtwo"]
atlas = ExtResource("1_mewtwo")
region = Rect2(0, 0, {largeur}, {hauteur})

[resource]
animations = [{animations}]
"""

ANIMATION = """{{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_mewtwo")
}}],
"loop": true,
"name": &"{nom}",
"speed": 1.0
}}"""


def main() -> None:
    artwork = Image.open(SOURCE).convert("RGBA")
    artwork = artwork.crop(artwork.getbbox())
    largeur = round(artwork.width * HAUTEUR / artwork.height)
    image = artwork.resize((largeur, HAUTEUR), Image.LANCZOS)
    image.save(SORTIE / IMAGE)
    noms = ["idle", "idle_down", "idle_left", "idle_right", "idle_up"]
    animations = ", ".join(ANIMATION.format(nom=nom) for nom in noms)
    (SORTIE / "mewtwo_frames.tres").write_text(
        FRAMES.format(image=IMAGE, largeur=largeur, hauteur=HAUTEUR, animations=animations),
        encoding="utf-8")
    print(f"mewtwo_provisoire.png : {largeur} × {HAUTEUR}")


if __name__ == "__main__":
    main()
