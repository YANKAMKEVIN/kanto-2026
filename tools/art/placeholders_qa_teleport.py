#!/usr/bin/env python3
"""Art PROVISOIRE des cartes de QA `qa_teleport` et `qa_teleport_2` (passe systèmes 2, T28).

Enveloppes simples dessinées d'après les grilles `tools/plans/qa_teleport*.txt`, aux dimensions
finales (cases x 96 px) : murs et sol lisibles, téléporteurs (T) marqués d'un disque, portes à
carte (K) d'un fond gris (le battant est un nœud posé par l'outil de construction). Retirées avec
les cartes à la clôture de la passe (S2Z).

  python3 tools/art/placeholders_qa_teleport.py

Écrit dans `assets/world/interiors/placeholder/` : `ph_qa_teleport.png` (20 x 13),
`ph_qa_teleport_2.png` (10 x 8) et `ph_qa_key_door.png` (96 x 96, battant de porte à carte).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "assets" / "world" / "interiors" / "placeholder"
CASE = 96
CARTES = ["qa_teleport", "qa_teleport_2"]
# Teinte du sol par salle (A, B, C, D) pour se repérer.
SOLS = {"A": (122, 140, 168), "B": (150, 130, 168), "C": (128, 156, 130), "D": (176, 150, 112)}
MUR = (52, 56, 72)
MUR_FACE = (78, 84, 108)


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


def _salle(nom: str, x: int, y: int) -> str:
    if nom != "qa_teleport":
        return "C"
    if y < 6:
        return "A" if x < 10 else "B"
    return "C" if x < 10 else "D"


def _teleporteur(g: ImageDraw.ImageDraw, x: int, y: int) -> None:
    cx, cy = x * CASE + CASE // 2, y * CASE + CASE // 2
    g.ellipse([cx - 38, cy - 38, cx + 38, cy + 38], fill=(60, 30, 110),
              outline=(255, 255, 255), width=4)
    g.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(150, 90, 230))
    g.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(255, 255, 255))


def dessiner(nom: str) -> None:
    grille = _lire_grille(nom)
    h, w = len(grille), len(grille[0])
    img = Image.new("RGB", (w * CASE, h * CASE), MUR)
    g = ImageDraw.Draw(img)
    for y, rangee in enumerate(grille):
        for x, c in enumerate(rangee):
            x0, y0 = x * CASE, y * CASE
            if c == "#":
                g.rectangle([x0 + 4, y0 + 4, x0 + CASE - 5, y0 + CASE - 5],
                            outline=MUR_FACE, width=2)
                continue
            base = SOLS[_salle(nom, x, y)]
            teinte = tuple(v - 10 if (x + y) % 2 else v for v in base)
            g.rectangle([x0, y0, x0 + CASE - 1, y0 + CASE - 1], fill=teinte,
                        outline=tuple(v - 24 for v in base))
            if c == "E":
                g.rectangle([x0 + 8, y0 + 8, x0 + CASE - 9, y0 + CASE - 9],
                            outline=(240, 220, 90), width=4)
            elif c == "T":
                _teleporteur(g, x, y)
            elif c == "K":
                g.rectangle([x0, y0, x0 + CASE - 1, y0 + CASE - 1], fill=(120, 124, 132))
    SORTIE.mkdir(parents=True, exist_ok=True)
    img.save(SORTIE / f"ph_{nom}.png")
    print(f"ph_{nom}.png : {w} x {h} cases")


def battant() -> None:
    img = Image.new("RGBA", (CASE, CASE), (0, 0, 0, 0))
    g = ImageDraw.Draw(img)
    g.rectangle([2, 2, CASE - 3, CASE - 3], fill=(138, 142, 150), outline=(70, 74, 84), width=4)
    g.rectangle([14, 14, CASE - 15, CASE - 15], outline=(190, 194, 202), width=3)
    g.rectangle([CASE // 2 - 12, CASE // 2 - 6, CASE // 2 + 12, CASE // 2 + 10],
                fill=(200, 60, 60))
    g.rectangle([CASE // 2 - 6, CASE // 2 - 2, CASE // 2 + 6, CASE // 2 + 2], fill=(30, 30, 30))
    img.save(SORTIE / "ph_qa_key_door.png")
    print("ph_qa_key_door.png : 96 x 96")


if __name__ == "__main__":
    for carte in CARTES:
        dessiner(carte)
    battant()
