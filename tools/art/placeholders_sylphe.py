#!/usr/bin/env python3
"""OBSOLÈTE depuis DAF.3 (étages en modules, `tools/build_silph_co.gd`, images retirées) — Art PROVISOIRE de la Sylphe SARL (jalon 26, T7) : enveloppes des onze étages et de la cabine,
dessinées d'après les grilles fonctionnelles `tools/plans/sylphe_*.txt`, aux dimensions finales
(cases x 96 px). Remplacer par l'art définitif = changer les images (mêmes noms, mêmes
dimensions), pas les cartes.

  python3 tools/art/placeholders_sylphe.py

Lisibilité d'abord (règle 3 : fonctionnel sur téléphone) :
  - sol de bureau clair (moquette gris-bleu), murs à face visible au sud ;
  - mobilier `M` selon sa tache connexe : 1 case = plante, 2 cases = console de labo,
    3 cases et plus = rangée de bureaux (plateau bois, écrans) ;
  - dalle de téléportation `T` : disque violet et cyan cerclé de blanc, bien visible ;
  - escaliers `U` / `D` (marches et flèche), porte d'ascenseur `L`, sortie `E` (paillasson) ;
  - case de porte électronique `K` : seuil gris à bandes jaunes (le battant fermé est un autre
    objet, posé par l'outil de construction et effacé à l'ouverture) ;
  - cabine : panneau d'étages `P` sur le mur du fond, portes en bas.

Écrit dans `assets/world/interiors/placeholder/` : `ph_silph_co_1f.png` … `ph_silph_co_11f.png`,
`ph_silph_co_elevator.png`, et les battants des portes électroniques fermées
`ph_silph_door_v.png` (96 x 192, porte verticale) et `ph_silph_door_h.png` (192 x 96).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "assets" / "world" / "interiors" / "placeholder"
CASE = 96

CARTES = {"silph_co_%df" % n: "sylphe_%df" % n for n in range(1, 12)}
CARTES["silph_co_elevator"] = "sylphe_ascenseur"

SOL_A, SOL_B = (178, 188, 204), (170, 180, 197)
MUR = (84, 98, 124)
VIDE = (26, 30, 40)
BOIS, BOIS_FACE = (176, 132, 88), (124, 88, 56)
ECRAN = (70, 190, 230)


def _shade(color, k):
    return tuple(max(0, min(255, int(c * k))) for c in color)


def _lire_grille(nom: str) -> list[str]:
    rangees: list[str] = []
    actif = False
    for ligne in (RACINE / "tools" / "plans" / (nom + ".txt")).read_text().splitlines():
        if ligne.startswith("GRILLE"):
            actif = True
            continue
        if actif and ligne.startswith("FIN"):
            break
        if actif and ligne[:2].isdigit():
            rangees.append(ligne.split(" ", 1)[1].rstrip())
    return rangees


def _taches(rangees: list[str], car: str) -> dict[tuple[int, int], int]:
    """Taille de la tache connexe (4-voisins) de chaque case portant [car]."""
    taille: dict[tuple[int, int], int] = {}
    h, w = len(rangees), len(rangees[0])
    for y in range(h):
        for x in range(w):
            if rangees[y][x] != car or (x, y) in taille:
                continue
            pile, tache = [(x, y)], []
            vus = {(x, y)}
            while pile:
                cx, cy = pile.pop()
                tache.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and rangees[ny][nx] == car \
                            and (nx, ny) not in vus:
                        vus.add((nx, ny))
                        pile.append((nx, ny))
            for case in tache:
                taille[case] = len(tache)
    return taille


def _volume(g, x, y, w, h, dessus, face, hauteur):
    g.rectangle((x, y + hauteur, x + w - 1, y + h - 1), fill=face)
    g.rectangle((x, y, x + w - 1, y + h - 1 - hauteur), fill=dessus)
    g.rectangle((x, y, x + w - 1, y + h - 1), outline=_shade(face, 0.65), width=2)


def _face_mur(g, px, py, fenetre: bool):
    g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=MUR)
    g.rectangle((px, py + CASE - 14, px + CASE - 1, py + CASE - 1), fill=_shade(MUR, 0.7))
    g.rectangle((px, py + 8, px + CASE - 1, py + 14), fill=_shade(MUR, 1.25))
    if fenetre:
        g.rectangle((px + 14, py + 24, px + CASE - 15, py + 62), fill=(150, 200, 236),
                    outline=(220, 228, 240), width=3)
        g.line((px + CASE // 2, py + 24, px + CASE // 2, py + 62), fill=(220, 228, 240), width=3)


def _plante(g, px, py):
    g.rectangle((px + 30, py + 58, px + 66, py + 88), fill=(150, 96, 70),
                outline=(96, 60, 44), width=3)
    for k, (dx, dy) in enumerate(((0, 0), (-16, 10), (16, 10), (-8, -14), (10, -12))):
        g.ellipse((px + 30 + dx, py + 22 + dy, px + 66 + dx, py + 56 + dy),
                  fill=(64, 150, 84) if k % 2 else (84, 172, 96))


def _console(g, px, py):
    _volume(g, px + 6, py + 8, CASE - 12, CASE - 12, (210, 214, 222), (150, 156, 168), 30)
    g.rectangle((px + 16, py + 16, px + CASE - 17, py + 40), fill=(40, 60, 80))
    for k in range(4):
        g.rectangle((px + 20 + k * 14, py + 22, px + 28 + k * 14, py + 34),
                    fill=(90, 230, 150) if k % 2 else (240, 200, 80))


def _bureau(g, px, py, x, y):
    _volume(g, px + 2, py + 10, CASE - 4, CASE - 14, BOIS, BOIS_FACE, 28)
    if (x + y) % 2 == 0:
        g.rectangle((px + 26, py + 14, px + 70, py + 44), fill=(40, 44, 54))
        g.rectangle((px + 30, py + 18, px + 66, py + 40), fill=ECRAN)
    else:
        g.rectangle((px + 20, py + 20, px + 50, py + 40), fill=(244, 244, 236),
                    outline=(180, 180, 170), width=2)
        g.rectangle((px + 58, py + 18, px + 74, py + 34), fill=(230, 80, 70))


def _teleporteur(g, px, py):
    cx, cy = px + CASE // 2, py + CASE // 2
    g.rectangle((px + 4, py + 4, px + CASE - 5, py + CASE - 5), fill=(70, 74, 96),
                outline=(200, 210, 240), width=3)
    g.ellipse((cx - 38, cy - 38, cx + 38, cy + 38), fill=(64, 34, 120), outline=(255, 255, 255),
              width=4)
    g.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=(150, 90, 230))
    g.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(110, 230, 250))
    g.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(255, 255, 255))


def _escalier(g, px, py, monte):
    g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=(64, 70, 84))
    for i in range(5):
        teinte = 0.62 + 0.09 * (i if monte else 4 - i)
        g.rectangle((px + 6, py + 8 + i * 17, px + CASE - 7, py + 22 + i * 17),
                    fill=_shade((214, 218, 226), teinte))
    fleche = ([(px + 36, py + 72), (px + 60, py + 72), (px + 48, py + 50)] if monte
              else [(px + 36, py + 50), (px + 60, py + 50), (px + 48, py + 72)])
    g.polygon(fleche, fill=(240, 200, 60))


def _porte_ascenseur(g, px, py):
    g.rectangle((px + 4, py, px + CASE - 5, py + CASE - 1), fill=(176, 182, 194))
    g.rectangle((px + 10, py + 6, px + CASE - 11, py + CASE - 1), fill=(126, 134, 148))
    g.line((px + CASE // 2, py + 6, px + CASE // 2, py + CASE - 1), fill=(60, 66, 76), width=3)
    g.ellipse((px + CASE // 2 - 7, py - 3, px + CASE // 2 + 7, py + 11), fill=(90, 220, 130))


def _seuil_porte(g, px, py):
    g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=(128, 132, 142))
    for k in range(0, CASE, 24):
        g.polygon([(px + k, py), (px + k + 12, py), (px + k, py + 12)], fill=(236, 196, 60))
        g.polygon([(px + k, py + CASE - 1), (px + k + 12, py + CASE - 1),
                   (px + k, py + CASE - 13)], fill=(236, 196, 60))


def _sortie(g, px, py):
    g.rectangle((px + 6, py + 14, px + CASE - 7, py + CASE - 1), fill=(150, 40, 48))
    g.rectangle((px + 6, py + 14, px + CASE - 7, py + 20), fill=(250, 210, 80))


def _panneau(g, px, py):
    g.rectangle((px + 14, py + 10, px + CASE - 15, py + CASE - 18), fill=(54, 60, 74),
                outline=(214, 218, 226), width=3)
    for k in range(6):
        cx = px + 32 + (k % 2) * 30
        cy = py + 22 + (k // 2) * 18
        g.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=(240, 200, 80) if k == 0
                  else (156, 162, 174))


def enveloppe(plan: str) -> Image.Image:
    rangees = _lire_grille(plan)
    cols, lignes = len(rangees[0]), len(rangees)
    cabine = plan == "sylphe_ascenseur"
    image = Image.new("RGB", (cols * CASE, lignes * CASE), VIDE)
    g = ImageDraw.Draw(image)
    meubles = _taches(rangees, "M")

    def at(x, y):
        return rangees[y][x] if 0 <= x < cols and 0 <= y < lignes else "#"

    def mur(c):
        return c in "#P"

    for y in range(lignes):
        for x in range(cols):
            if mur(at(x, y)):
                continue
            px, py = x * CASE, y * CASE
            g.rectangle((px, py, px + CASE - 1, py + CASE - 1),
                        fill=SOL_A if (x + y) % 2 == 0 else SOL_B)
            g.line((px, py, px + CASE - 1, py), fill=_shade(SOL_B, 0.9), width=2)
            g.line((px, py, px, py + CASE - 1), fill=_shade(SOL_B, 0.9), width=2)
    for y in range(lignes):
        for x in range(cols):
            if not mur(at(x, y)):
                continue
            px, py = x * CASE, y * CASE
            if not mur(at(x, y + 1)) or (cabine and y == 0):
                _face_mur(g, px, py, fenetre=(y == 0 and x % 4 == 2 and not cabine))
            else:
                g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=_shade(MUR, 0.42))
    for y in range(lignes):
        for x in range(cols):
            c = at(x, y)
            px, py = x * CASE, y * CASE
            if c == "M":
                taille = meubles[(x, y)]
                if taille == 1:
                    _plante(g, px, py)
                elif taille == 2:
                    _console(g, px, py)
                else:
                    _bureau(g, px, py, x, y)
            elif c == "T":
                _teleporteur(g, px, py)
            elif c == "U":
                _escalier(g, px, py, True)
            elif c == "D":
                _escalier(g, px, py, False)
            elif c == "L":
                _porte_ascenseur(g, px, py)
            elif c == "K":
                _seuil_porte(g, px, py)
            elif c == "E":
                _sortie(g, px, py)
            elif c == "P":
                _panneau(g, px, py)
    return image


def battant(vertical: bool) -> Image.Image:
    """Porte électronique fermée sur deux cases (battant gris, voyant rouge, lecteur de carte)."""
    w, h = (CASE, 2 * CASE) if vertical else (2 * CASE, CASE)
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(image)
    g.rectangle((2, 2, w - 3, h - 3), fill=(140, 146, 156), outline=(64, 70, 82), width=5)
    g.rectangle((14, 14, w - 15, h - 15), outline=(196, 200, 210), width=3)
    if vertical:
        g.line((8, CASE, w - 9, CASE), fill=(64, 70, 82), width=4)
    else:
        g.line((CASE, 8, CASE, h - 9), fill=(64, 70, 82), width=4)
    cx, cy = w // 2, h // 2
    g.rectangle((cx - 16, cy - 22, cx + 16, cy + 22), fill=(44, 48, 58), outline=(20, 20, 24),
                width=2)
    g.rectangle((cx - 10, cy - 4, cx + 10, cy + 2), fill=(20, 20, 24))
    g.ellipse((cx - 6, cy - 18, cx + 6, cy - 6), fill=(230, 50, 50))
    return image


def main() -> None:
    SORTIE.mkdir(parents=True, exist_ok=True)
    for carte, plan in CARTES.items():
        image = enveloppe(plan)
        image.save(SORTIE / ("ph_%s.png" % carte))
        print("ph_%s.png" % carte, image.size)
    battant(True).save(SORTIE / "ph_silph_door_v.png")
    battant(False).save(SORTIE / "ph_silph_door_h.png")
    print("ph_silph_door_v.png, ph_silph_door_h.png")


if __name__ == "__main__":
    main()
