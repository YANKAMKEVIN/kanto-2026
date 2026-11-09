#!/usr/bin/env python3
"""Audit décor / collisions, étape 2 : signale les cases dont l'aspect contredit la grille.

Lit build/audit_decor/<carte>.png et .grid.txt (tools/audit_decor_render.gd). Chaque carte sert de
référence à elle-même : on compare chaque case de bordure aux cases éloignées (k plus proches
voisins sur la couleur et la texture) ; une case bloquée qui ressemble au sol libre de sa carte, ou
une case libre qui ressemble à ses obstacles, est suspecte.

    python3 tools/audit_decor_compare.py [carte ...] [--seuil 0.8] [--min 2]

Sortie : build/audit_decor/rapport/<carte>.png (encadrés) et rapport.json. Rouge : bloquée, a l'air
libre (mur invisible). Jaune : libre, a l'air bloquée (on marche sur le décor).
Sans dépendance hors numpy et Pillow.
"""
import argparse
import json
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFont

Image.MAX_IMAGE_PIXELS = None
BASE = pathlib.Path('build/audit_decor')
PX = 32
MARGE = 6
K = 25
RAYON_EXCLU = 4
MAX_REF = 8000
RED, YEL = (255, 40, 40), (255, 220, 0)


def features(img, l, h):
    """Par case : couleur moyenne, contraste et densité d'arêtes du centre de la case."""
    arr = np.asarray(img, dtype=np.float32)[:, :, :3] / 255.0
    lum = arr.mean(axis=2)
    dx = np.abs(np.diff(lum, axis=1, append=lum[:, -1:]))
    dy = np.abs(np.diff(lum, axis=0, append=lum[-1:, :]))
    ar = dx + dy
    out = np.zeros((h, l, 7), dtype=np.float32)
    for y in range(h):
        for x in range(l):
            y0, y1 = y * PX + MARGE, (y + 1) * PX - MARGE
            x0, x1 = x * PX + MARGE, (x + 1) * PX - MARGE
            c, s = arr[y0:y1, x0:x1].reshape(-1, 3), lum[y0:y1, x0:x1]
            m = c.mean(axis=0)
            out[y, x] = (m[0], m[1], m[2], m.max() - m.min(), s.std() * 2, np.quantile(s, 0.15), ar[y0:y1, x0:x1].mean() * 3)
    return out


def analyser(carte, seuil, taille_min):
    lignes = (BASE / f'{carte}.grid.txt').read_text().splitlines()
    h, l = len(lignes), len(lignes[0])
    bloque = np.array([[ch in '#~' for ch in ligne] for ligne in lignes], dtype=bool)
    eau = np.array([[ch == '~' for ch in ligne] for ligne in lignes], dtype=bool)
    img = Image.open(BASE / f'{carte}.png').convert('RGB')
    if img.size != (l * PX, h * PX):
        return None
    if bloque.mean() < 0.02 or bloque.mean() > 0.98:
        return {'carte': carte, 'groupes': []}
    f = features(img, l, h)
    v = f.reshape(-1, 7)
    v = (v - v.mean(axis=0)) / (v.std(axis=0) + 1e-6)
    ys, xs = np.mgrid[0:h, 0:l]
    ys, xs, lab = ys.ravel(), xs.ravel(), bloque.ravel()
    rng = np.random.default_rng(1)
    idx = np.arange(len(lab))
    # Référence équilibrée : autant de cases libres que bloquées, l'eau écartée.
    ok = idx[~eau.ravel()]
    libres, bloques = ok[~lab[ok]], ok[lab[ok]]
    n = min(MAX_REF // 2, len(libres), len(bloques))
    if n < K:
        return {'carte': carte, 'groupes': []}
    ref = np.concatenate([rng.choice(libres, n, replace=False), rng.choice(bloques, n, replace=False)])
    voisin_oppose = np.zeros_like(bloque)
    voisin_oppose[1:] |= bloque[1:] != bloque[:-1]
    voisin_oppose[:-1] |= bloque[1:] != bloque[:-1]
    voisin_oppose[:, 1:] |= bloque[:, 1:] != bloque[:, :-1]
    voisin_oppose[:, :-1] |= bloque[:, 1:] != bloque[:, :-1]
    # Cases à juger : bordure libre/bloqué et cases proches, hors eau.
    zone = voisin_oppose & ~eau
    score = np.zeros_like(bloque, dtype=np.float32)
    for y, x in zip(*np.nonzero(zone)):
        i = y * l + x
        d = ((v[ref] - v[i]) ** 2).sum(axis=1)
        loin = (np.abs(ys[ref] - y) > RAYON_EXCLU) | (np.abs(xs[ref] - x) > RAYON_EXCLU)
        cand = np.nonzero(loin)[0]
        if len(cand) < K:
            continue
        pris = cand[np.argpartition(d[cand], K)[:K]]
        score[y, x] = (lab[ref[pris]] != bloque[y, x]).mean()
    groupes = []
    vu = np.zeros_like(bloque)
    for y, x in zip(*np.nonzero(score >= seuil)):
        if vu[y, x]:
            continue
        pile, membres, typ = [(y, x)], [], bool(bloque[y, x])
        vu[y, x] = True
        while pile:
            cy, cx = pile.pop()
            membres.append((int(cx), int(cy)))
            for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                if 0 <= ny < h and 0 <= nx < l and not vu[ny, nx] and score[ny, nx] >= seuil and bool(bloque[ny, nx]) == typ:
                    vu[ny, nx] = True
                    pile.append((ny, nx))
        if len(membres) >= taille_min:
            groupes.append({'type': 'mur_invisible' if typ else 'marche_sur_decor',
                            'cases': sorted(membres),
                            'score': round(float(np.mean([score[b, a] for a, b in membres])), 3)})
    groupes.sort(key=lambda g: (-len(g['cases']) * g['score']))
    return {'carte': carte, 'groupes': groupes, 'taille': [l, h], 'image': img, 'score': score, 'bloque': bloque}


def dessiner(res):
    img, l, h = res['image'].copy(), *res['taille']
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default(size=12)
    for n, g in enumerate(res['groupes']):
        col = RED if g['type'] == 'mur_invisible' else YEL
        for x, y in g['cases']:
            d.rectangle((x * PX, y * PX, (x + 1) * PX - 1, (y + 1) * PX - 1), outline=col, width=2)
        x, y = g['cases'][0]
        d.text((x * PX + 3, y * PX + 3), str(n), fill=(255, 255, 255), font=font, stroke_width=2, stroke_fill=(0, 0, 0))
    return img


def main():
    p = argparse.ArgumentParser()
    p.add_argument('cartes', nargs='*')
    p.add_argument('--seuil', type=float, default=0.8)
    p.add_argument('--min', type=int, default=2)
    a = p.parse_args()
    (BASE / 'rapport').mkdir(parents=True, exist_ok=True)
    cartes = a.cartes or sorted(f.name[:-9] for f in BASE.glob('*.grid.txt'))
    bilan = []
    for carte in cartes:
        res = analyser(carte, a.seuil, a.min)
        if res is None:
            print('ÉCART DE TAILLE', carte)
            continue
        if res['groupes']:
            dessiner(res).save(BASE / 'rapport' / f'{carte}.png')
        nb_r = sum(len(g['cases']) for g in res['groupes'] if g['type'] == 'mur_invisible')
        nb_j = sum(len(g['cases']) for g in res['groupes'] if g['type'] != 'mur_invisible')
        bilan.append({'carte': carte, 'mur_invisible': nb_r, 'marche_sur_decor': nb_j, 'groupes': res['groupes']})
        print(f'{carte:32s} groupes {len(res["groupes"]):3d}  rouge {nb_r:4d}  jaune {nb_j:4d}')
    (BASE / 'rapport.json').write_text(json.dumps(bilan, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
