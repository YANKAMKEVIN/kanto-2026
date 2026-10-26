#!/usr/bin/env python3
"""Planche avant / après du lot DAF.6 « Lumière et ambiance » (phase DA).

    python3 tools/art/planche_daf6.py [avant] [apres] [sortie]

Défauts : build/captures/daf6/avant, build/captures/daf6/apres (tools/capture_daf6.sh),
docs/design/fiches-assets/daf-6-lumiere/planche.png. Une rangée par vue (avant | après), une
section par lieu avec sa référence peinte en vignette.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BEFORE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build/captures/daf6/avant"
AFTER = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "build/captures/daf6/apres"
OUT = Path(sys.argv[3]) if len(sys.argv) > 3 else \
    ROOT / "docs/design/fiches-assets/daf-6-lumiere/planche.png"
REF = ROOT / "docs/design/reference"

SECTIONS = [
    ("Forêt de Jade — ombre de canopée au sol, lumière chaude des clairières, arbres plus sombres et plus bleus",
     "foret-jade-vue-generale-v1.png",
     [("foret_entree", "Entrée, clairière C1"), ("foret_theo", "Sentier, Théo"),
      ("foret_h3", "H3 sous la canopée"), ("foret_clairiere_rai", "Clairière C3 au rai")]),
    ("Intérieurs — étalonnage chaud, pénombre au pourtour, flaque chaude des fenêtres (tous les intérieurs `interior_warm`)",
     "chambre-joueur-v1.webp",
     [("int_chambre", "Chambre du joueur"), ("int_labo_chen", "Laboratoire de Chen"),
      ("int_centre_jadielle", "Centre Pokémon de Jadielle"), ("int_maison_1f", "Maison, rez-de-chaussée"),
      ("int_musee_argenta", "Musée d'Argenta")]),
    ("Mont Sélénite — sol de pierre chaude (profils moon_*), parois d'ardoise froides ; Îles Écume inchangées",
     "mont-selenite-vue-generale-v1.png",
     [("selenite_hall_1f", "1F, hall et puits de jour"), ("selenite_tranchee_b1f", "B1F, tranchée"),
      ("selenite_chambre_b2f", "B2F, chambre des fossiles")]),
]

W, H = 720, 332  # vue 2340 × 1080 réduite
GAP, MARGIN, HEAD, LABEL = 14, 28, 110, 40
REF_H = HEAD - 20


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{name}", size)


def main() -> None:
    rows = sum(len(views) for _, _, views in SECTIONS)
    width = MARGIN * 2 + W * 2 + GAP
    height = MARGIN * 2 + 110 + len(SECTIONS) * HEAD + rows * (LABEL + H + GAP)
    sheet = Image.new("RGB", (width, height), (18, 20, 26))
    draw = ImageDraw.Draw(sheet)
    draw.text((MARGIN, MARGIN), "DAF.6 — Lumière et ambiance : avant / après (captures Mac 2340 × 1080)",
              font=font(34, True), fill=(240, 240, 240))
    draw.text((MARGIN, MARGIN + 54), "Gauche : main avant DAF.6 · Droite : après DAF.6 · "
              "aucune image nouvelle (profils de lumière et shaders)", font=font(24), fill=(170, 175, 190))
    y = MARGIN + 110
    for title, ref_name, views in SECTIONS:
        draw.text((MARGIN, y + 20), title, font=font(21, True), fill=(255, 214, 140))
        ref = Image.open(REF / ref_name).convert("RGB")
        ref.thumbnail((REF_H * 3, REF_H))
        sheet.paste(ref, (width - MARGIN - ref.width, y + 8))
        draw.text((width - MARGIN - ref.width - 130, y + 60), "référence →", font=font(20),
                  fill=(170, 175, 190))
        y += HEAD
        for name, label in views:
            draw.text((MARGIN, y + 8), f"{label} — avant", font=font(24), fill=(200, 200, 205))
            draw.text((MARGIN + W + GAP, y + 8), "après", font=font(24, True), fill=(200, 230, 200))
            y += LABEL
            for i, folder in enumerate((BEFORE, AFTER)):
                shot = Image.open(folder / f"{name}.png").convert("RGB").resize((W, H), Image.LANCZOS)
                sheet.paste(shot, (MARGIN + i * (W + GAP), y))
            y += H + GAP
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Palette de 256 couleurs (poids du dépôt) : assez pour juger lumière et ambiance.
    sheet = sheet.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    sheet.save(OUT, optimize=True)
    print(OUT, sheet.size, f"{OUT.stat().st_size / 1e6:.1f} Mo")


if __name__ == "__main__":
    main()
