#!/usr/bin/env python3
"""Audit des emprises, étape 2 : cases bloquées près d'un bâtiment où rien n'est peint.

Lit build/audit_decor/batiments.json (tools/audit_building_dump.gd) et les rendus et grilles de
tools/audit_decor_render.gd. Une case est proposée si, à la fois :
  - elle est bloquée seulement par une tuile logique et/ou l'emprise d'un bâtiment ;
  - un bâtiment peint visible est à moins de PORTEE cases ;
  - moins de SEUIL de sa surface est couverte par un objet peint visible ;
  - dans le rendu réel, elle ressemble à la case de sol libre par laquelle on l'atteint ;
  - elle touche le sol libre, directement ou par une case déjà ouverte (on pèle de l'extérieur) ;
  - aucun passage, point d'examen ni déclencheur n'y est posé ;
  - l'ouvrir ne relie pas deux zones de la carte jusque-là séparées.

    python3 tools/audit_building_margins.py        # écrit build/audit_decor/marges.json
"""
import collections
import json
import pathlib

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
B = pathlib.Path('build/audit_decor')
CELL = 96
PX = 32
SEUIL = 0.10
PORTEE = 2
ECART_COULEUR = 0.075
ECART_TEXTURE = 0.07
EXCLUES = {'pallet_town'}  # corrigée à la main et validée par Kevin le 2026-11-09
AXES = ((1, 0), (-1, 0), (0, 1), (0, -1))
TEXTURES = {}


def alpha(path):
    if path not in TEXTURES:
        TEXTURES[path] = np.asarray(Image.open(path.replace('res://', '')).convert('RGBA'))[:, :, 3] >= 128
    return TEXTURES[path]


def peindre(masque, prop):
    """Porte l'opacité du sprite sur un masque de la carte, à 1 pixel pour 4 unités monde."""
    s = prop['sprite']
    a = alpha(s['path'])
    h, l = a.shape
    ox, oy = (s['offset'][0] - l / 2, s['offset'][1] - h / 2) if s['centered'] else s['offset']
    sx, sy = prop['scale'][0] * s['scale'][0], prop['scale'][1] * s['scale'][1]
    x0 = prop['pos'][0] + prop['scale'][0] * (s['at'][0] + ox * s['scale'][0])
    y0 = prop['pos'][1] + prop['scale'][1] * (s['at'][1] + oy * s['scale'][1])
    H, L = masque.shape
    ys = np.arange(max(0, int(y0 / 4)), min(H, int((y0 + h * sy) / 4) + 1))
    xs = np.arange(max(0, int(x0 / 4)), min(L, int((x0 + l * sx) / 4) + 1))
    if ys.size == 0 or xs.size == 0:
        return
    iy = np.clip(((ys * 4 + 2 - y0) / sy).astype(int), 0, h - 1)
    ix = np.clip(((xs * 4 + 2 - x0) / sx).astype(int), 0, l - 1)
    if s['flip']:
        ix = l - 1 - ix
    masque[np.ix_(ys, xs)] |= a[np.ix_(iy, ix)]


def composantes(libre):
    h, l = libre.shape
    lab = -np.ones_like(libre, dtype=int)
    n = 0
    for y0, x0 in zip(*np.nonzero(libre)):
        if lab[y0, x0] >= 0:
            continue
        pile = [(y0, x0)]
        lab[y0, x0] = n
        while pile:
            y, x = pile.pop()
            for dx, dy in AXES:
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < l and libre[ny, nx] and lab[ny, nx] < 0:
                    lab[ny, nx] = n
                    pile.append((ny, nx))
        n += 1
    return lab


def aspect(rendu, x, y):
    c = rendu[y * PX + 4:(y + 1) * PX - 4, x * PX + 4:(x + 1) * PX - 4]
    return c.reshape(-1, 3).mean(axis=0), c.mean(axis=2).std()


def semblable(rendu, a, b):
    ca, ta = aspect(rendu, *a)
    cb, tb = aspect(rendu, *b)
    return np.abs(ca - cb).max() < ECART_COULEUR and abs(ta - tb) < ECART_TEXTURE


def analyser(m):
    L, H = m['size']
    lignes = (B / f"{m['map']}.grid.txt").read_text().splitlines()
    grille = [list(s) for s in lignes]
    libre = np.array([[c in '.g' for c in s] for s in lignes], dtype=bool)
    rendu = np.asarray(Image.open(B / f"{m['map']}.png").convert('RGB'), dtype=np.float32) / 255
    masque = np.zeros((H * CELL // 4, L * CELL // 4), dtype=bool)
    bats = np.zeros_like(masque)
    for p in m['props']:
        if p['visible'] and 'sprite' in p:
            peindre(masque, p)
            if '/bldg_' in p['scene']:
                peindre(bats, p)
    tuiles = collections.defaultdict(set)
    for x, y, couche in m['tiles']:
        tuiles[(x, y)].add(couche)
    bloquees = {tuple(c) for c in m['blocked']}
    objets = collections.defaultdict(list)
    for p in m['props']:
        for dx, dy in p['footprint']:
            objets[(p['anchor'][0] + dx, p['anchor'][1] + dy)].append(p)
    reperes = {(a, b) for a, b, _, _ in m['markers']}
    lab = composantes(libre)
    eligibles = set()
    for y in range(H):
        for x in range(L):
            if grille[y][x] != '#' or (x, y) in reperes or (x, y) in bloquees:
                continue
            if any('/bldg_' not in p['scene'] for p in objets[(x, y)]):
                continue
            if not tuiles[(x, y)] and not objets[(x, y)]:
                continue  # bloquée par autre chose (PNJ, objet posé)
            if masque[y * 24:(y + 1) * 24, x * 24:(x + 1) * 24].mean() >= SEUIL:
                continue
            r = PORTEE * 24
            if not bats[max(0, y * 24 - r):(y + 1) * 24 + r, max(0, x * 24 - r):(x + 1) * 24 + r].any():
                continue
            eligibles.add((x, y))
    # On pèle depuis le sol libre : chaque case doit ressembler à celle qui l'atteint.
    ouvertes, front = set(), []
    for x, y in sorted(eligibles):
        for dx, dy in AXES:
            v = (x + dx, y + dy)
            if 0 <= v[1] < H and 0 <= v[0] < L and libre[v[1], v[0]] and semblable(rendu, (x, y), v):
                ouvertes.add((x, y))
                front.append((x, y))
                break
    while front:
        x, y = front.pop()
        for dx, dy in AXES:
            v = (x + dx, y + dy)
            if v in eligibles and v not in ouvertes and semblable(rendu, v, (x, y)):
                ouvertes.add(v)
                front.append(v)
    retenues, refus, vu = set(), set(), set()
    for c in sorted(ouvertes):
        if c in vu:
            continue
        groupe, pile = [], [c]
        vu.add(c)
        while pile:
            x, y = pile.pop()
            groupe.append((x, y))
            for dx, dy in AXES:
                v = (x + dx, y + dy)
                if v in ouvertes and v not in vu:
                    vu.add(v)
                    pile.append(v)
        zones = {int(lab[y + dy, x + dx]) for x, y in groupe for dx, dy in AXES
                 if 0 <= y + dy < H and 0 <= x + dx < L and lab[y + dy, x + dx] >= 0}
        (retenues if len(zones) == 1 else refus).update(groupe)
    if not retenues and not refus:
        return None
    instances = []
    for p in m['props']:
        retire = [[x - p['anchor'][0], y - p['anchor'][1]] for x, y in sorted(retenues) if p in objets[(x, y)]]
        if retire:
            instances.append({'nom': p['name'], 'anchor': p['anchor'], 'retirer': retire})
    return {'carte': m['map'], 'ouvrir': sorted(retenues), 'refus': sorted(refus), 'instances': instances,
            'couches': {f'{x},{y}': sorted(tuiles[(x, y)]) for x, y in sorted(retenues) if tuiles[(x, y)]}}


def main():
    tout = []
    for m in json.load(open(B / 'batiments.json')):
        if m['map'] in EXCLUES:
            continue
        r = analyser(m)
        if r:
            tout.append(r)
    json.dump(tout, open(B / 'marges.json', 'w'), ensure_ascii=False, indent=0)
    print('cartes', len(tout), 'cases à ouvrir', sum(len(t['ouvrir']) for t in tout),
          'refusées (relieraient deux zones)', sum(len(t['refus']) for t in tout),
          'emprises d\'objets à réduire', sum(len(t['instances']) for t in tout))
    print('couches', collections.Counter(c for t in tout for v in t['couches'].values() for c in v))
    for t in sorted(tout, key=lambda t: -len(t['ouvrir'])):
        print('%-24s ouvrir %3d  refus %3d' % (t['carte'], len(t['ouvrir']), len(t['refus'])))


if __name__ == '__main__':
    main()
