#!/usr/bin/env python3
"""Planches de validation des lots DAF.10d et DAF.2 bis (DA-6), à partir des captures de
tools/capture_daf10d.sh (build/daf10d/avant|apres) et de tools/capture_t2_combat.gd
(build/daf10d/combats). Sortie : docs/design/fiches-assets/daf-10d/.

    python3 tools/art/planches_daf10d.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(RACINE, "build", "daf10d")
SORTIE = os.path.join(RACINE, "docs", "design", "fiches-assets", "daf-10d")


def police(t):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(p):
            return ImageFont.truetype(p, t)
    return ImageFont.load_default()


def recadre(chemin, largeur):
    """Capture 2340 × 1080 : on garde la carte (bandes noires latérales retirées)."""
    im = Image.open(chemin).convert("RGB")
    bbox = im.point(lambda v: 255 if v > 14 else 0).convert("L").getbbox() or (0, 0, *im.size)
    im = im.crop((bbox[0], 0, bbox[2], im.size[1]))
    h = int(im.size[1] * largeur / im.size[0])
    return im.resize((largeur, h))


def planche_avant_apres(cartes, titre, nom, largeur=520):
    f, ft = police(26), police(38)
    lignes = []
    for carte, etiquette in cartes:
        a = recadre(os.path.join(B, "avant", carte + ".png"), largeur)
        p = recadre(os.path.join(B, "apres", carte + ".png"), largeur)
        lignes.append((etiquette, a, p))
    w = 2 * largeur + 60
    h = 80 + sum(max(a.size[1], p.size[1]) + 56 for _, a, p in lignes)
    out = Image.new("RGB", (w, h), (24, 24, 28))
    d = ImageDraw.Draw(out)
    d.text((20, 20), titre, font=ft, fill=(255, 255, 255))
    y = 80
    for etiquette, a, p in lignes:
        d.text((20, y + 6), etiquette + " : avant / après", font=f, fill=(255, 220, 120))
        out.paste(a, (20, y + 44))
        out.paste(p, (40 + largeur, y + 44))
        y += max(a.size[1], p.size[1]) + 56
    out.save(os.path.join(SORTIE, nom), quality=86)
    print(nom, out.size)


def planche_grille(cartes, titre, nom, largeur, colonnes=2):
    f, ft = police(26), police(38)
    ims = [(e, recadre(c, largeur)) for c, e in cartes]
    hl = max(i.size[1] for _, i in ims) + 50
    rangs = (len(ims) + colonnes - 1) // colonnes
    out = Image.new("RGB", (colonnes * (largeur + 20) + 20, 80 + rangs * hl), (24, 24, 28))
    d = ImageDraw.Draw(out)
    d.text((20, 20), titre, font=ft, fill=(255, 255, 255))
    for k, (e, im) in enumerate(ims):
        x = 20 + (k % colonnes) * (largeur + 20)
        y = 80 + (k // colonnes) * hl
        d.text((x, y + 4), e, font=f, fill=(255, 220, 120))
        out.paste(im, (x, y + 40))
    out.save(os.path.join(SORTIE, nom), quality=86)
    print(nom, out.size)


def main():
    os.makedirs(SORTIE, exist_ok=True)
    planche_avant_apres([("league_lorelei", "Olga (glace)"), ("league_bruno", "Aldo (roche)"),
                         ("league_agatha", "Agatha (spectre)")],
                        "DAF.10d — Ligue (1/2)", "planche-1-ligue.jpg", 560)
    planche_avant_apres([("league_lance", "Peter (dragon)"), ("league_champion", "Champion"),
                         ("hall_of_fame", "Panthéon")],
                        "DAF.10d — Ligue (2/2) et Panthéon", "planche-2-ligue-pantheon.jpg", 600)
    planche_avant_apres([("cinnabar_lab", "Labo de Cramois'Île"), ("silph_co_5f", "Sylphe SARL 5F (étage type)")],
                        "DAF.10d — Labo et Sylphe", "planche-3-labo-sylphe.jpg", 900)
    c = os.path.join(B, "combats")
    planche_grille([(os.path.join(c, "cb3_silph_co_1f_actions.png"), "Sylphe SARL 1F — silph_co_hall"),
                    (os.path.join(c, "cb3_fuchsia_gym_actions.png"), "Arène de Parmanie — fuchsia_gym_ninja"),
                    (os.path.join(c, "cb3_cinnabar_gym_actions.png"), "Arène de Cramois'Île — cinnabar_gym_volcan"),
                    (os.path.join(c, "cb3_power_plant_actions.png"), "Centrale [D] — power_plant_centrale"),
                    (os.path.join(c, "cb3_safari_zone_savane_roucool.png"), "Parc Safari — safari_zone_savane")],
                   "DAF.2 bis — fonds de combat dérivés", "planche-4-fonds-combat.jpg", 900)


if __name__ == "__main__":
    main()
