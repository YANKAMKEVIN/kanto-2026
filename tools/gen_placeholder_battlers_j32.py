#!/usr/bin/env python3
"""Sprites de combat provisoires (64 × 64) des espèces ajoutées par le jalon 32 (Élektek, Porygon,
Électhor, Minidraco) : `test_battle_art.gd` exige une face et un dos par espèce des données.
Face = artwork officiel réduit, dos = dos « cadrage B » réduit (`assets/sprites/pokemon/dos/`),
pieds au bas de l'image. Le lot d'art remplacera ces images.

    python3 tools/gen_placeholder_battlers_j32.py && godot --headless --path . --import
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/pokemon/placeholder")
SPECIES = {"electabuzz": 125, "porygon": 137, "zapdos": 145, "dratini": 147}
SIZE = 64


def fit(path: str) -> Image.Image:
    src = Image.open(path).convert("RGBA")
    box = src.getbbox() or (0, 0, src.width, src.height)
    src = src.crop(box)
    scale = (SIZE - 4) / max(src.width, src.height)
    src = src.resize((max(1, round(src.width * scale)), max(1, round(src.height * scale))),
                     Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(src, ((SIZE - src.width) // 2, SIZE - 3 - src.height), src)
    return out


for species, dex in SPECIES.items():
    fit(os.path.join(ROOT, f"assets/sprites/pokemon/official/{dex}.png")).save(
        os.path.join(OUT, f"{species}_front.png"))
    fit(os.path.join(ROOT, f"assets/sprites/pokemon/dos/dos_rb_{dex}.png")).save(
        os.path.join(OUT, f"{species}_back.png"))
print(f"Sprites de combat provisoires du J32 OK ({len(SPECIES)} espèces)")
