#!/usr/bin/env python3
"""Coque de l'Arène de Céladopole repeinte d'après la grille (audit du 2026-11-14 ; Kevin :
« repeins les arènes »). La coque de la série 22 bis peignait aussi des haies, une jardinière
et des bassins placés selon une ancienne mise en page : on marchait sur des haies peintes et
sur l'eau. Les haies et le massif sont déjà des objets peints posés par
`tools/build_celadon_gym.gd` sur les cases `x` et `j` du plan ; la coque ne garde donc que le
sol, les murs, la verrière et les bassins `w`, reposés sur leurs cases.

  - Sol : toutes les cases de sol reprennent un bloc de dalles propre (même phase de motif).
  - Mur du bas descendu d'une rangée (son dessus couvrait la rangée 13, praticable) ; parois
    latérales avancées de 40 px (colonnes 1 et 15 bloquées).
  - Bassins : le bassin isolé du coin sud-ouest (margelle comprise) sert de modèle, recadré à
    la taille du bloc `w` (3 × 2 en haut, 2 × 2 en bas ; pour 2 × 2, le milieu est retiré).

Repart toujours de la coque d'origine (commit SOURCE), donc relançable.

  python3 tools/art/coque_celadon.py
"""
import io
import os
import subprocess

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = "a85e8fc31"
SHELL = "assets/world/interiors/int_celadon_gym_coque.png"
PLAN = "tools/plans/celadopole_arene.txt"
TILE = 96
# Bassin modèle (margelle comprise).
POOL = (175, 1035, 442, 1228)
FLOOR_X = range(2, 15)
FLOOR_Y = range(2, 14)
# Haut du mur du bas peint (px) et descente pour qu'il commence à la rangée 14.
BOTTOM_WALL_Y = 1256
WALL_DROP = 14 * TILE - BOTTOM_WALL_Y
SIDE_STRIP = 170
SIDE_SHIFT = 40


def original() -> Image.Image:
    data = subprocess.run(["git", "show", f"{SOURCE}:{SHELL}"], cwd=ROOT, check=True,
                          capture_output=True).stdout
    return Image.open(io.BytesIO(data)).convert("RGBA")


def plan_rows() -> list:
    rows = []
    for line in open(os.path.join(ROOT, PLAN), encoding="utf-8"):
        if len(line) > 3 and line[:2].isdigit() and line[2] == " ":
            rows.append(line[3:].rstrip("\n"))
    return rows


def pool_image(src: Image.Image, cols: int, rows: int) -> Image.Image:
    pool = src.crop(POOL)
    w, h = cols * TILE, rows * TILE
    if pool.width > w + 40:
        # Bassin étroit : on retire le milieu (margelles gauche et droite intactes).
        left = w * 4 // 7
        right = w - left
        cut = Image.new("RGBA", (w, pool.height))
        cut.paste(pool.crop((0, 0, left, pool.height)), (0, 0))
        cut.paste(pool.crop((pool.width - right, 0, pool.width, pool.height)), (left, 0))
        pool = cut
    return pool.resize((w, h), Image.LANCZOS)


def blocks(rows: list, char: str) -> list:
    seen, out = set(), []
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c != char or (x, y) in seen:
                continue
            x1 = x
            while x1 + 1 < len(row) and row[x1 + 1] == char:
                x1 += 1
            y1 = y
            while y1 + 1 < len(rows) and all(rows[y1 + 1][i] == char for i in range(x, x1 + 1)):
                y1 += 1
            for yy in range(y, y1 + 1):
                for xx in range(x, x1 + 1):
                    seen.add((xx, yy))
            out.append((x, y, x1 - x + 1, y1 - y + 1))
    return out


def main() -> None:
    src = original()
    w, h = src.size
    out = src.copy()
    # Mur du bas : peint une rangée trop haut (son dessus couvrait la rangée 13, praticable) ;
    # descendu de WALL_DROP px, le bas de l'image (dehors) est rogné. Les parois latérales
    # comblent le vide avec la rangée de paroi du dessus.
    out.paste(src.crop((0, BOTTOM_WALL_Y, w, h - WALL_DROP)), (0, BOTTOM_WALL_Y + WALL_DROP))
    for x0 in (0, w - 2 * TILE):
        band = src.crop((x0, BOTTOM_WALL_Y - WALL_DROP, x0 + 2 * TILE, BOTTOM_WALL_Y))
        out.paste(band, (x0, BOTTOM_WALL_Y))
    walls = out.copy()
    # Sol : toutes les cases praticables reprennent le bloc de dalles propre (rangées 11..12,
    # colonnes 5..14), même phase de motif (colonnes et rangées de même parité).
    for y in FLOOR_Y:
        for x in FLOOR_X:
            sx = x if x >= 5 else x + 10
            sy = 11 + (y - 11) % 2
            out.paste(src.crop((sx * TILE, sy * TILE, (sx + 1) * TILE, (sy + 1) * TILE)),
                      (x * TILE, y * TILE))
    # Parois latérales : elles laissaient ~40 px de sol peint sur les colonnes 1 et 15 (bloquées).
    # La bande de paroi d'origine (sans le sol) avance de SIDE_SHIFT px ; posée avant les bassins.
    out.paste(walls.crop((0, 0, SIDE_STRIP, h)), (SIDE_SHIFT, 0))
    out.paste(walls.crop((w - SIDE_STRIP, 0, w, h)), (w - SIDE_STRIP - SIDE_SHIFT, 0))
    for x, y, bw, bh in blocks(plan_rows(), "w"):
        img = pool_image(src, bw, bh)
        out.paste(img, (x * TILE, y * TILE), img)
        print(f"bassin {bw}×{bh} en ({x}, {y})")
    out.save(os.path.join(ROOT, SHELL))
    print(f"{SHELL} : repeinte d'après {PLAN}")


if __name__ == "__main__":
    main()
