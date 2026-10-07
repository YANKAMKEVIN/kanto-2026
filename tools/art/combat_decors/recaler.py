#!/usr/bin/env python3
"""Recalage d'une tuile agrandie par Codex sur sa portion du master (CB.3).

Codex repeint la tuile au lieu de l'agrandir : son cadrage dérive un peu (échelle et décalage).
On cherche la transformation (échelle x, échelle y, décalage) qui superpose au mieux la tuile
réduite à la portion source, sur des images de bords (moins sensibles aux couleurs repeintes).

  python3 tools/art/combat_decors/recaler.py source.png x0 y0 x1 y1 tuile.png
Affiche : sx sy tx ty (la tuile, en px de la tuile, = (source - (x0, y0)) * (sx, sy) + (tx, ty)).
"""
import sys

import numpy as np
from PIL import Image, ImageFilter


def gris(image, taille):
    im = image.convert("L").resize(taille, Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(im, dtype=np.float32)
    gx = np.zeros_like(a)
    gy = np.zeros_like(a)
    gx[:, 1:] = a[:, 1:] - a[:, :-1]
    gy[1:, :] = a[1:, :] - a[:-1, :]
    g = np.hypot(gx, gy)
    return (g - g.mean()) / (g.std() + 1e-6)


def score(src, tuile_img, sx, sy, tx, ty, w, h, f):
    """Corrélation entre la portion source (w x h, réduite de f) et la tuile ramenée dessus."""
    # Point source p (px source relatifs) -> tuile : p * s + t. On échantillonne la tuile à la
    # taille réduite de la source.
    tw, th = tuile_img.size
    box = (tx, ty, tx + w * sx, ty + h * sy)
    if box[0] < -tw * 0.1 or box[1] < -th * 0.1 or box[2] > tw * 1.1 or box[3] > th * 1.1:
        return -1.0
    part = tuile_img.transform((int(w / f), int(h / f)), Image.EXTENT, box, Image.BILINEAR)
    b = gris(part, part.size)
    m = 6
    return float((src[m:-m, m:-m] * b[m:-m, m:-m]).mean())


def recaler(source_path, crop, tuile_path, f=4.0):
    source = Image.open(source_path).convert("RGB")
    x0, y0, x1, y1 = crop
    w, h = x1 - x0, y1 - y0
    tuile = Image.open(tuile_path).convert("RGB")
    k = tuile.size[0] / w
    src = gris(source.crop(crop), (int(w / f), int(h / f)))
    best = (-2.0, k, k, 0.0, 0.0)
    # Recherche grossière puis fine.
    for etape, (ds, dt, n) in enumerate([(0.04, 24.0, 4), (0.01, 6.0, 3), (0.003, 2.0, 3)]):
        _, bsx, bsy, btx, bty = best
        for i in range(-n, n + 1):
            for j in range(-n, n + 1):
                sx = bsx + i * ds * k
                sy = bsy + j * ds * k
                for a in range(-n, n + 1):
                    for b in range(-n, n + 1):
                        tx = btx + a * dt
                        ty = bty + b * dt
                        s = score(src, tuile, sx, sy, tx, ty, w, h, f)
                        if s > best[0]:
                            best = (s, sx, sy, tx, ty)
    return best


if __name__ == "__main__":
    s, sx, sy, tx, ty = recaler(sys.argv[1], tuple(int(v) for v in sys.argv[2:6]), sys.argv[6])
    print("score %.3f  sx %.4f sy %.4f tx %.1f ty %.1f" % (s, sx, sy, tx, ty))
