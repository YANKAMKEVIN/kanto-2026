#!/usr/bin/env python3
"""Mur des Pokémon de la bande-annonce : part de quelques Pokémon en grand, recule jusqu'à les
montrer tous. Écrit build/trailer/<dossier>/mur_pokemon.avi (muet), lu par assemble.py comme une scène.

    python3 tools/trailer/pokemon_wall.py [--raw raw_v3]
"""
from __future__ import annotations

import argparse
import random
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/sprites/pokemon/official"
W, H, FPS = 2340, 1080, 30
COLS, ROWS, CELL = 21, 10, 300
BG = (0x14, 0x0F, 0x0B)
# Au centre du mur, vus en grand au début : Pikachu, les starters de Kanto, Mewtwo, Évoli, Ho-Oh, Lugia.
CENTER = ["025", "006", "009", "003", "150", "133", "250", "249", "001", "004", "007", "143"]
Z_START, SECONDS, HOLD = 3.8, 4.2, 0.9


def wall() -> Image.Image:
    files = sorted(ART.glob("[0-9][0-9][0-9].png"))  # pas atlas_128.png
    rng = random.Random(7)
    rest = [f for f in files if f.stem not in CENTER]
    rng.shuffle(rest)
    picks = {f.stem: f for f in files}
    cells = [(c, r) for r in range(ROWS) for c in range(COLS)]
    mid = ((COLS - 1) / 2, (ROWS - 1) / 2)
    cells.sort(key=lambda p: (p[0] - mid[0]) ** 2 + (2.17 * (p[1] - mid[1])) ** 2)
    order = [picks[s] for s in CENTER if s in picks] + rest
    # Plus de cases que de Pokémon : les cases vides tombent aux coins, les plus loin du centre.
    canvas = Image.new("RGB", (COLS * CELL, ROWS * CELL), BG)
    for path, (c, r) in zip(order, cells):
        art = Image.open(path).convert("RGBA")
        art.thumbnail((CELL - 16, CELL - 16), Image.LANCZOS)
        canvas.paste(art, (c * CELL + (CELL - art.width) // 2, r * CELL + (CELL - art.height) // 2), art)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", default="raw_v3")
    args = parser.parse_args()
    canvas = wall()
    out = ROOT / "build/trailer" / args.raw / "mur_pokemon.avi"
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
           "-r", str(FPS), "-i", "-", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-shortest",
           "-c:v", "mjpeg", "-q:v", "2", "-pix_fmt", "yuvj420p", "-c:a", "pcm_s16le", str(out)]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    full_w, full_h = canvas.size
    fit = min(full_w / W, full_h / H)  # recul maximal : le mur entier à l'écran
    frames = int(SECONDS * FPS)
    moving = int((SECONDS - HOLD) * FPS)
    for i in range(frames):
        t = min(i / moving, 1.0)
        ease = 1 - (1 - t) ** 3
        scale = fit / (Z_START + (1.0 - Z_START) * ease)
        vw, vh = W * scale, H * scale
        x, y = (full_w - vw) / 2, (full_h - vh) / 2
        view = canvas.transform((W, H), Image.AFFINE, (vw / W, 0, x, 0, vh / H, y), Image.BILINEAR)
        proc.stdin.write(view.tobytes())
    proc.stdin.close()
    proc.wait()
    print(out, frames, "images")


if __name__ == "__main__":
    main()
