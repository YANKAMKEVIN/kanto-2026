#!/usr/bin/env python3
"""Planches de contrôle de l'audit J33 T2 : 4 captures 2340x1080 par planche (2x2), nom en légende.

  python3 tools/art/t2_planche.py <dossier de PNG> <dossier de sortie> [par_planche=4]
"""
import sys, pathlib
from PIL import Image, ImageDraw

src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
n = int(sys.argv[3]) if len(sys.argv) > 3 else 4
out.mkdir(parents=True, exist_ok=True)
files = sorted(src.glob("*.png"))
for i in range(0, len(files), n):
    sheet = Image.new("RGB", (2340, 1080), (20, 20, 20))
    for j, f in enumerate(files[i:i + n]):
        im = Image.open(f).convert("RGB").resize((1170, 540), Image.LANCZOS)
        ImageDraw.Draw(im).text((8, 6), f.stem, fill=(255, 255, 0))
        sheet.paste(im, ((j % 2) * 1170, (j // 2) * 540))
    sheet.save(out / f"planche_{i // n + 1:02d}.png")
    print(out / f"planche_{i // n + 1:02d}.png", [f.stem for f in files[i:i + n]])
