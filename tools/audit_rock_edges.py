#!/usr/bin/env python3
"""Audit des bords de roche : la paroi peinte et la grille disent-elles la même chose ?

Lit build/audit_decor/batiments.json (tools/audit_building_dump.gd) et les rendus. Propose :
  - de BLOQUER une case libre si plus de SEUIL_ROCHE de sa surface est couverte par une paroi,
    à condition que la zone reste d'un seul tenant et que tout objet voisin reste accessible ;
  - d'OUVRIR une case bloquée par une tuile si rien n'y est peint, qu'une paroi est à moins de
    PORTEE cases, qu'elle ressemble au sol libre qui la touche et que l'ouverture ne relie pas
    deux zones séparées.

    python3 tools/audit_rock_edges.py        # écrit build/audit_decor/roche.json
"""
import collections
import json
import pathlib
import re

import numpy as np
from PIL import Image

from audit_building_margins import AXES, B, CELL, composantes, peindre, semblable

SEUIL_ROCHE = 0.6
SEUIL_VIDE = 0.10
PORTEE = 2
ROCHE = re.compile(r'relief_(paroi|falaise|escarpement|rocaille|corniche)')


def une_zone(libre, zone):
    """Vrai si les cases de zone (marquées libres dans libre) restent d'un seul tenant."""
    if not zone:
        return True
    depart = next(iter(zone))
    vu, pile = {depart}, [depart]
    while pile:
        y, x = pile.pop()
        for dx, dy in AXES:
            v = (y + dy, x + dx)
            if v in zone and v not in vu:
                vu.add(v)
                pile.append(v)
    return len(vu) == len(zone)


def analyser(m):
    L, H = m['size']
    lignes = (B / f"{m['map']}.grid.txt").read_text().splitlines()
    grille = [list(s) for s in lignes]
    libre = np.array([[c in '.g' for c in s] for s in lignes], dtype=bool)
    rendu = np.asarray(Image.open(B / f"{m['map']}.png").convert('RGB'), dtype=np.float32) / 255
    tout = np.zeros((H * CELL // 4, L * CELL // 4), dtype=bool)
    roche = np.zeros_like(tout)
    for p in m['props']:
        if p['visible'] and 'sprite' in p:
            peindre(tout, p)
            if ROCHE.search(p['scene']):
                peindre(roche, p)
    if not roche.any():
        return None
    tuiles = {(x, y) for x, y, _ in m['tiles']}
    bloquees = {tuple(c) for c in m['blocked']}
    objets = {(p['anchor'][0] + dx, p['anchor'][1] + dy) for p in m['props'] for dx, dy in p['footprint']}
    reperes = {(a, b) for a, b, _, _ in m['markers']}
    lab = composantes(libre)

    def couvert(mask, x, y):
        return float(mask[y * 24:(y + 1) * 24, x * 24:(x + 1) * 24].mean())

    a_bloquer = {(x, y) for y in range(H) for x in range(L)
                 if libre[y, x] and (x, y) not in reperes and couvert(roche, x, y) >= SEUIL_ROCHE}
    # Bloquer ne doit ni couper une zone, ni isoler un objet.
    cartes_zones = collections.defaultdict(set)
    for y, x in zip(*np.nonzero(libre)):
        cartes_zones[int(lab[y, x])].add((int(y), int(x)))
    refus_b = set()
    for n, zone in cartes_zones.items():
        ici = {(y, x) for y, x in zone if (x, y) in a_bloquer}
        if ici and not une_zone(libre, zone - ici):
            refus_b |= {(x, y) for y, x in ici}
    a_bloquer -= refus_b
    for x, y in sorted(a_bloquer):
        for dx, dy in AXES:
            sx, sy = x + dx, y + dy
            if not (0 <= sy < H and 0 <= sx < L) or grille[sy][sx] != '#' or (sx, sy) in tuiles:
                continue
            voisins = [(sx + a, sy + b) for a, b in AXES if 0 <= sy + b < H and 0 <= sx + a < L]
            if not any(libre[b, a] and (a, b) not in a_bloquer for a, b in voisins):
                refus_b.add((x, y))
    a_bloquer -= refus_b

    eligibles = set()
    for y in range(H):
        for x in range(L):
            if grille[y][x] != '#' or (x, y) not in tuiles or (x, y) in bloquees or (x, y) in objets or (x, y) in reperes:
                continue
            if couvert(tout, x, y) >= SEUIL_VIDE:
                continue
            r = PORTEE * 24
            if roche[max(0, y * 24 - r):(y + 1) * 24 + r, max(0, x * 24 - r):(x + 1) * 24 + r].any():
                eligibles.add((x, y))
    ouvertes, front = set(), []
    for x, y in sorted(eligibles):
        for dx, dy in AXES:
            v = (x + dx, y + dy)
            if 0 <= v[1] < H and 0 <= v[0] < L and libre[v[1], v[0]] and v not in a_bloquer and semblable(rendu, (x, y), v):
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
    retenues, refus_o, vu = set(), set(), set()
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
        (retenues if len(zones) == 1 else refus_o).update(groupe)
    if not retenues and not a_bloquer and not refus_b and not refus_o:
        return None
    return {'carte': m['map'], 'bloquer': sorted(a_bloquer), 'ouvrir': sorted(retenues),
            'refus_bloquer': sorted(refus_b), 'refus_ouvrir': sorted(refus_o)}


def main():
    tout = []
    for m in json.load(open(B / 'batiments.json')):
        r = analyser(m)
        if r:
            tout.append(r)
    json.dump(tout, open(B / 'roche.json', 'w'), ensure_ascii=False, indent=0)
    print('cartes', len(tout), 'à bloquer', sum(len(t['bloquer']) for t in tout), 'à ouvrir', sum(len(t['ouvrir']) for t in tout),
          'refus bloquer', sum(len(t['refus_bloquer']) for t in tout), 'refus ouvrir', sum(len(t['refus_ouvrir']) for t in tout))
    for t in sorted(tout, key=lambda t: -(len(t['bloquer']) + len(t['ouvrir']))):
        print('%-26s bloquer %3d ouvrir %3d  refus %d/%d' % (t['carte'], len(t['bloquer']), len(t['ouvrir']), len(t['refus_bloquer']), len(t['refus_ouvrir'])))


if __name__ == '__main__':
    main()
