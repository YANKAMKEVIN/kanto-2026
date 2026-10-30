#!/usr/bin/env python3
"""Planches de validation du lot DAF.10c (DA-6), à partir de tools/capture_daf10c.sh
(build/daf10c/avant|apres) et de tools/capture_daf10c_details.sh (build/daf10c/details).
Sortie : docs/design/fiches-assets/daf-10c/.

    python3 tools/art/planches_daf10c.py
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from planches_daf10d import police, recadre  # noqa: E402
import planches_daf10d  # noqa: E402

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(RACINE, "build", "daf10c")
SORTIE = os.path.join(RACINE, "docs", "design", "fiches-assets", "daf-10c")
FOND = (24, 24, 28)
JAUNE = (255, 220, 120)


def avant_apres(cartes, titre, nom, largeur):
    planches_daf10d.B = B
    planches_daf10d.SORTIE = SORTIE
    planches_daf10d.planche_avant_apres(cartes, titre, nom, largeur)


def details(images, titre, nom, largeur=1170):
    f, ft = police(26), police(38)
    ims = [(e, Image.open(os.path.join(B, "details", c + ".png")).convert("RGB")) for c, e in images]
    ims = [(e, im.resize((largeur, im.size[1] * largeur // im.size[0]))) for e, im in ims]
    h = 80 + sum(im.size[1] + 50 for _, im in ims)
    out = Image.new("RGB", (largeur + 40, h), FOND)
    d = ImageDraw.Draw(out)
    d.text((20, 20), titre, font=ft, fill=(255, 255, 255))
    y = 80
    for e, im in ims:
        d.text((20, y + 4), e, font=f, fill=JAUNE)
        out.paste(im, (20, y + 40))
        y += im.size[1] + 50
    out.save(os.path.join(SORTIE, nom), quality=86)
    print(nom, out.size)


def synthese():
    """Format téléphone (1080 de large) : un avant / après par zone et deux gros plans."""
    l = 1040
    f, ft, fp = police(30), police(44), police(26)
    blocs = [
        ("Îles Écume B3F : avant", recadre(os.path.join(B, "avant", "seafoam_b3f.png"), l)),
        ("après", recadre(os.path.join(B, "apres", "seafoam_b3f.png"), l)),
        ("à l'échelle du jeu : courants et rochers", Image.open(os.path.join(B, "details", "ecume_courants.png"))
            .convert("RGB").resize((l, l * 1080 // 2340))),
        ("Centrale : avant", recadre(os.path.join(B, "avant", "power_plant.png"), l)),
        ("après", recadre(os.path.join(B, "apres", "power_plant.png"), l)),
        ("à l'échelle du jeu : salle d'Électhor", Image.open(os.path.join(B, "details", "centrale_electhor.png"))
            .convert("RGB").resize((l, l * 1080 // 2340))),
    ]
    h = 230 + sum(im.size[1] + 52 for _, im in blocs)
    out = Image.new("RGB", (1080, h), FOND)
    d = ImageDraw.Draw(out)
    d.text((20, 24), "DAF.10c — Îles Écume et Centrale", font=ft, fill=(255, 255, 255))
    d.text((20, 84), "RP-275, RP-276 · art seul, logique identique (12 relevés)", font=fp, fill=(200, 200, 210))
    d.text((20, 120), "Kit provisoire dérivé ; images Codex à l'identique ensuite", font=fp, fill=(200, 200, 210))
    d.text((20, 156), "À valider : lisibilité des rochers, courants, salles", font=fp, fill=JAUNE)
    y = 220
    for e, im in blocs:
        d.text((20, y), e, font=f, fill=JAUNE)
        out.paste(im, (20, y + 44))
        y += im.size[1] + 52
    out.save(os.path.join(SORTIE, "synthese-telephone.jpg"), quality=84)
    print("synthese-telephone.jpg", out.size)


def main():
    os.makedirs(SORTIE, exist_ok=True)
    avant_apres([("seafoam_1f", "Îles Écume 1F"), ("seafoam_b1f", "Îles Écume B1F"),
                 ("seafoam_b2f", "Îles Écume B2F")], "DAF.10c — Îles Écume (1/2)", "planche-1-ecume.jpg", 760)
    avant_apres([("seafoam_b3f", "Îles Écume B3F"), ("seafoam_b4f", "Îles Écume B4F")],
                "DAF.10c — Îles Écume (2/2)", "planche-2-ecume.jpg", 760)
    avant_apres([("power_plant", "Centrale")], "DAF.10c — Centrale", "planche-3-centrale.jpg", 900)
    details([("ecume_rochers", "B3F : rochers de Force (ronds, fissurés) et petits rochers fixes, trous"),
             ("ecume_courants", "B3F : courants (eau vive qui défile + flèches), escaliers, échelles"),
             ("ecume_1f", "1F : sol haut glacé, sol bas, arête et rebords"),
             ("centrale_electhor", "Centrale : salle d'Électhor"),
             ("centrale_salle", "Centrale : salle du sud, objets et fausses Poké Balls")],
            "DAF.10c — à l'échelle du jeu (zoom 1)", "planche-4-echelle-jeu.jpg")
    avant_apres([("silph_co_2f", "Sylphe 2F"), ("silph_co_3f", "Sylphe 3F"), ("silph_co_4f", "Sylphe 4F"),
                 ("silph_co_6f", "Sylphe 6F")], "DAF.10c — Sylphe SARL (1/2), reste de RP-280",
                "planche-5-sylphe.jpg", 640)
    avant_apres([("silph_co_7f", "Sylphe 7F"), ("silph_co_8f", "Sylphe 8F"), ("silph_co_9f", "Sylphe 9F"),
                 ("silph_co_10f", "Sylphe 10F"), ("silph_co_11f", "Sylphe 11F")],
                "DAF.10c — Sylphe SARL (2/2), reste de RP-280", "planche-6-sylphe.jpg", 640)
    synthese()


if __name__ == "__main__":
    main()
