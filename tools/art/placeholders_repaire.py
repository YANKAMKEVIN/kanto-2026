#!/usr/bin/env python3
"""Art PROVISOIRE du Casino de Céladopole et du repaire Rocket (jalon 20, T20) : enveloppes de
carte dessinées d'après les grilles fonctionnelles, aux dimensions finales.

Le kit d'art de la série 22 bis n'est pas là (`docs/tech/jalon-20.md` §1.4) : ce script dessine des
provisoires lisibles pour que cartes, collisions, dalles et tests existent. Remplacer par le vrai
kit = changer les images (mêmes noms, mêmes dimensions), pas les cartes.

  python3 tools/art/placeholders_repaire.py

Écrit dans `assets/world/interiors/placeholder/` :
  - `ph_celadon_game_corner.png` (20 × 18 cases), `ph_rocket_hideout_b1f|b2f|b3f|b4f.png`,
    `ph_rocket_hideout_elevator.png` (6 × 8) : sol, murs, mobilier, escaliers, dalles tournantes
    (flèches) et disques d'arrêt cuits dans l'image ;
  - `ph_game_corner_wall.png` (96 × 96) : le mur coulissant posé sur l'escalier (17, 4) tant que
    `game_corner_switch` n'est pas levé ;
  - `ph_hideout_office_door.png` (192 × 96) : la porte du bureau de Giovanni (24..25, 11) du B4F,
    posée tant que `rocket_hideout_b4f_door_open` n'est pas levé.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "assets" / "world" / "interiors" / "placeholder"
CASE = 96

# carte -> (grille, ambiance)
CARTES = {
    "celadon_game_corner": ("casino", "casino"),
    "rocket_hideout_b1f": ("repaire_b1f", "repaire"),
    "rocket_hideout_b2f": ("repaire_b2f", "repaire"),
    "rocket_hideout_b3f": ("repaire_b3f", "repaire"),
    "rocket_hideout_b4f": ("repaire_b4f", "repaire"),
    "rocket_hideout_elevator": ("repaire_ascenseur", "cabine"),
}
NEONS = [(255, 70, 180), (70, 220, 255), (255, 200, 70)]


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
            rangees.append(ligne.split(" ", 1)[1].strip())
    return rangees


def _volume(g, x, y, w, h, dessus, face, hauteur):
    """Volume vu de dessus et de face : le dessus est remonté de [hauteur] px."""
    g.rectangle((x, y + hauteur, x + w - 1, y + h - 1), fill=face)
    g.rectangle((x, y, x + w - 1, y + h - 1 - hauteur), fill=dessus)
    g.rectangle((x, y, x + w - 1, y + h - 1), outline=_shade(face, 0.65), width=2)


def _face_mur(g, px, py, mur, neon=None):
    g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=mur)
    g.rectangle((px, py + CASE - 14, px + CASE - 1, py + CASE - 1), fill=_shade(mur, 0.7))
    g.rectangle((px, py + 10, px + CASE - 1, py + 18), fill=_shade(mur, 1.18))
    if neon is not None:
        g.rectangle((px, py + 40, px + CASE - 1, py + 46), fill=neon)
        g.rectangle((px, py + 47, px + CASE - 1, py + 50), fill=_shade(neon, 0.5))


def _fleche(g, px, py, d):
    """Dalle tournante : plaque sombre, flèche jaune dans le sens de glisse."""
    g.rectangle((px + 4, py + 4, px + CASE - 5, py + CASE - 5), fill=(52, 56, 66),
                outline=(236, 196, 60), width=3)
    jaune = (250, 208, 64)
    if d == "^":
        pts = [(px + 48, py + 12), (px + 78, py + 46), (px + 60, py + 46), (px + 60, py + 84),
               (px + 36, py + 84), (px + 36, py + 46), (px + 18, py + 46)]
    elif d == "v":
        pts = [(px + 48, py + 84), (px + 78, py + 50), (px + 60, py + 50), (px + 60, py + 12),
               (px + 36, py + 12), (px + 36, py + 50), (px + 18, py + 50)]
    elif d == "<":
        pts = [(px + 12, py + 48), (px + 46, py + 18), (px + 46, py + 36), (px + 84, py + 36),
               (px + 84, py + 60), (px + 46, py + 60), (px + 46, py + 78)]
    else:
        pts = [(px + 84, py + 48), (px + 50, py + 18), (px + 50, py + 36), (px + 12, py + 36),
               (px + 12, py + 60), (px + 50, py + 60), (px + 50, py + 78)]
    g.polygon(pts, fill=jaune)


def _disque(g, px, py):
    g.ellipse((px + 12, py + 12, px + CASE - 13, py + CASE - 13), fill=(236, 240, 244),
              outline=(150, 156, 168), width=4)
    g.ellipse((px + 32, py + 32, px + CASE - 33, py + CASE - 33), fill=(196, 204, 214))


def _escalier(g, px, py, monte, fond):
    g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=fond)
    for i in range(5):
        teinte = 0.62 + 0.09 * (i if monte else 4 - i)
        g.rectangle((px + 6, py + 8 + i * 17, px + CASE - 7, py + 22 + i * 17),
                    fill=_shade((210, 214, 222), teinte))
    fleche = ([(px + 40, py + 70), (px + 56, py + 70), (px + 48, py + 54)] if monte
              else [(px + 40, py + 54), (px + 56, py + 54), (px + 48, py + 70)])
    g.polygon(fleche, fill=(50, 54, 62))


def _enveloppe(plan: str, ambiance: str) -> Image.Image:
    rangees = _lire_grille(plan)
    cols, lignes = len(rangees[0]), len(rangees)
    casino = ambiance == "casino"
    cabine = ambiance == "cabine"
    if casino:
        sol_a, sol_b, mur = (78, 42, 88), (68, 34, 78), (52, 38, 76)
    elif cabine:
        sol_a, sol_b, mur = (150, 156, 166), (140, 146, 156), (110, 118, 132)
    else:
        sol_a, sol_b, mur = (196, 198, 202), (186, 188, 194), (92, 102, 118)
    vide = (22, 22, 30)
    image = Image.new("RGB", (cols * CASE, lignes * CASE), vide)
    g = ImageDraw.Draw(image)

    def at(x, y):
        return rangees[y][x] if 0 <= x < cols and 0 <= y < lignes else "#"

    def est_mur(c):
        return c == "#" or (casino and c in "AS")  # affiche et escalier : posés sur le mur

    for y in range(lignes):
        for x in range(cols):
            c = at(x, y)
            px, py = x * CASE, y * CASE
            if est_mur(c):
                continue
            g.rectangle((px, py, px + CASE - 1, py + CASE - 1),
                        fill=sol_a if (x + y) % 2 == 0 else sol_b)
            if not casino:
                g.line((px, py, px + CASE - 1, py), fill=_shade(sol_b, 0.88), width=2)
                g.line((px, py, px, py + CASE - 1), fill=_shade(sol_b, 0.88), width=2)
    # Murs : la face se voit sous chaque mur qui touche du sol au sud.
    for y in range(lignes):
        for x in range(cols):
            if not est_mur(at(x, y)):
                continue
            px, py = x * CASE, y * CASE
            if not est_mur(at(x, y + 1)):
                neon = NEONS[(x // 3) % 3] if casino else None
                _face_mur(g, px, py, mur, neon)
                if not casino and not cabine and x % 4 == 1:
                    g.rectangle((px + 18, py + 56, px + 78, py + 62), fill=(236, 196, 60))
            else:
                g.rectangle((px, py, px + CASE - 1, py + CASE - 1), fill=_shade(mur, 0.4))
    # Éléments cuits dans l'image.
    for y in range(lignes):
        for x in range(cols):
            c = at(x, y)
            px, py = x * CASE, y * CASE
            if c == "X":
                _volume(g, px + 4, py + 6, CASE - 8, CASE - 10, (196, 150, 98), (142, 100, 62), 26)
                g.line((px + 8, py + 10, px + CASE - 9, py + CASE - 30), fill=(120, 84, 52),
                       width=3)
            elif c == "P":
                g.rectangle((px + 26, py, px + CASE - 27, py + CASE - 1), fill=(120, 128, 140))
                g.rectangle((px + 34, py, px + 44, py + CASE - 1), fill=(176, 184, 196))
                for k in (14, 70):
                    g.rectangle((px + 22, py + k, px + CASE - 23, py + k + 8), fill=(80, 86, 98))
            elif c == "M" and not casino:
                _volume(g, px + 6, py + 8, CASE - 12, CASE - 12, (84, 92, 112), (58, 64, 82), 34)
                g.rectangle((px + 18, py + 16, px + CASE - 19, py + 38), fill=(90, 190, 230))
                g.rectangle((px + 18, py + 44, px + 30, py + 50), fill=(236, 90, 80))
            elif c == "M" and casino:
                neon = NEONS[(x + y) % 3]
                _volume(g, px + 4, py + 4, CASE - 8, CASE - 6, (44, 44, 78), (30, 30, 58), 40)
                g.rectangle((px + 14, py + 12, px + CASE - 15, py + 34), fill=neon)
                g.rectangle((px + 14, py + 12, px + CASE - 15, py + 14), fill=(255, 255, 255))
                for k in range(3):
                    g.ellipse((px + 16 + k * 22, py + 44, px + 30 + k * 22, py + 56),
                              fill=NEONS[(k + x) % 3])
            elif c == "t":
                g.ellipse((px + 22, py + 30, px + CASE - 23, py + CASE - 18), fill=(150, 36, 52),
                          outline=(90, 20, 32), width=3)
            elif c == "C":
                _volume(g, px + 2, py + 8, CASE - 4, CASE - 12, (222, 178, 92), (150, 104, 56), 30)
            elif c == "A":
                g.rectangle((px + 14, py + 8, px + CASE - 15, py + 74), fill=(238, 228, 200),
                            outline=(120, 90, 60), width=4)
                g.ellipse((px + 30, py + 20, px + 66, py + 56), fill=(214, 60, 90))
                g.polygon([(px + 48, py + 24), (px + 54, py + 38), (px + 40, py + 38)],
                          fill=(255, 220, 90))
            elif c == "S":
                _escalier(g, px, py, False, (40, 30, 50))
            elif c == "E":
                g.rectangle((px + 6, py + 20, px + CASE - 7, py + CASE - 1), fill=(228, 214, 190))
                g.rectangle((px + 6, py + 20, px + CASE - 7, py + 26), fill=(255, 200, 70))
            elif c in "<>^v":
                _fleche(g, px, py, c)
            elif c == "o":
                _disque(g, px, py)
            elif c == "U":
                _escalier(g, px, py, True, (60, 64, 74))
            elif c == "D":
                _escalier(g, px, py, False, (60, 64, 74))
            elif c == "L":
                g.rectangle((px + 4, py, px + CASE - 5, py + CASE - 1), fill=(168, 176, 188))
                g.rectangle((px + 10, py + 6, px + CASE - 11, py + CASE - 1), fill=(120, 128, 142))
                g.line((px + CASE // 2, py + 6, px + CASE // 2, py + CASE - 1), fill=(60, 66, 76),
                       width=3)
                g.ellipse((px + CASE // 2 - 7, py - 3, px + CASE // 2 + 7, py + 11),
                          fill=(90, 220, 130))
            elif c == "B":  # seuil de la porte du bureau (la porte est un autre objet)
                g.rectangle((px, py + CASE - 14, px + CASE - 1, py + CASE - 1), fill=(236, 196, 60))
    if cabine:
        # Panneau d'étages (1, 1) : plaque à boutons.
        px, py = 1 * CASE, 1 * CASE
        g.rectangle((px + 10, py + 6, px + CASE - 11, py + CASE - 16), fill=(60, 66, 78),
                    outline=(210, 214, 222), width=3)
        for k in range(3):
            g.ellipse((px + 34, py + 14 + k * 20, px + 52, py + 30 + k * 20),
                      fill=(240, 200, 80) if k == 1 else (150, 156, 168))
    return image


def _panneau_mur() -> Image.Image:
    image = Image.new("RGB", (CASE, CASE), (52, 38, 76))
    _face_mur(ImageDraw.Draw(image), 0, 0, (52, 38, 76), NEONS[(17 // 3) % 3])
    return image


def _porte_bureau() -> Image.Image:
    image = Image.new("RGBA", (2 * CASE, CASE), (0, 0, 0, 0))
    g = ImageDraw.Draw(image)
    g.rectangle((2, 4, 2 * CASE - 3, CASE - 1), fill=(86, 94, 110), outline=(40, 44, 54), width=4)
    g.line((CASE, 4, CASE, CASE - 1), fill=(40, 44, 54), width=4)
    for k in range(0, 2 * CASE - 20, 28):
        g.polygon([(10 + k, CASE - 12), (30 + k, CASE - 12), (40 + k, CASE - 2),
                   (20 + k, CASE - 2)], fill=(236, 196, 60))
    g.rectangle((CASE - 16, 34, CASE - 8, 56), fill=(210, 60, 60))
    g.rectangle((CASE + 8, 34, CASE + 16, 56), fill=(210, 60, 60))
    return image


def main() -> None:
    SORTIE.mkdir(parents=True, exist_ok=True)
    for carte, (plan, ambiance) in CARTES.items():
        image = _enveloppe(plan, ambiance)
        image.save(SORTIE / ("ph_%s.png" % carte))
        print(carte, image.size)
    _panneau_mur().save(SORTIE / "ph_game_corner_wall.png")
    _porte_bureau().save(SORTIE / "ph_hideout_office_door.png")


if __name__ == "__main__":
    main()
