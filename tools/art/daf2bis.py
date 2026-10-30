#!/usr/bin/env python3
"""DAF.2 bis (J33, RP-157, RP-278, RP-279) : cinq fonds de combat dédiés **dérivés** de fonds peints
existants (Codex à sa limite d'usage) : étalonnage, miroir, voiles de couleur. Même format que les
fonds actuels (2340 × 1080, WEBP qualité 90) ; mêmes ancres et même ligne d'horizon que la source
(`data/battle/decors.json`). Fiche : docs/design/fiches-assets/daf-10d/fiche.md.

    python3 tools/art/daf2bis.py
"""
import os

import numpy as np
from PIL import Image, ImageEnhance

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
DECORS = os.path.join(RACINE, "assets", "battle", "decors")

# id : (source, horizon de la source, miroir, réglages)
#   mul : gain RVB ; sat : saturation ; con : contraste ; lum : luminosité ;
#   haut / bas : (couleur, opacité) d'un voile en dégradé au-dessus / au-dessous de l'horizon ;
#   sol_teinte : (teinte cible RVB, force) appliquée au seul sol (sous l'horizon).
FONDS = {
    # Arène de Parmanie (Koga) : dojo assombri, lumière de crépuscule violette, sol plus sombre.
    "fuchsia_gym_ninja": ("fighting_dojo_salle", 340, True, {
        "mul": (0.86, 0.78, 0.92), "sat": 0.80, "con": 1.08, "lum": 0.82,
        "haut": ((70, 40, 110), 0.50), "bas": ((40, 20, 60), 0.28)}),
    # Arène de Cramois'Île (Auguste) : salle de pierre d'Argenta embrasée, braises et rouge volcan.
    "cinnabar_gym_volcan": ("pewter_gym_roche", 460, True, {
        "mul": (1.0, 0.76, 0.64), "sat": 0.95, "con": 1.15, "lum": 0.78,
        "haut": ((60, 12, 8), 0.45), "bas": ((90, 30, 20), 0.20)}),
    # Sylphe SARL 1F : hall d'accueil, bureaux en miroir, moquette passée en dallage clair.
    "silph_co_hall": ("silph_co_bureaux", 330, True, {
        "mul": (1.0, 1.0, 1.0), "sat": 0.95, "con": 1.02, "lum": 1.05,
        "sol_teinte": ((232, 212, 178), 0.85)}),
    # Centrale (provisoire [D], DAF.10c attend Codex) : hangar du repaire, lumière jaune électrique.
    "power_plant_centrale": ("rocket_hideout_repaire", 433, False, {
        "mul": (1.0, 0.92, 0.62), "sat": 0.85, "con": 1.12, "lum": 0.74,
        "haut": ((255, 220, 60), 0.14), "bas": ((30, 26, 10), 0.28)}),
    # Parc Safari : prairie des Routes 5-6 en miroir, herbes dorées de savane.
    "safari_zone_savane": ("route_5_6_prairie", 440, True, {
        "mul": (1.08, 1.0, 0.72), "sat": 1.05, "con": 1.04, "lum": 1.0,
        "bas": ((210, 170, 60), 0.18)}),
}


def voile(img, horizon, couleur, alpha, dessus):
    """Dégradé de [couleur] : plein au bord (haut ou bas), nul à l'horizon."""
    a = np.asarray(img).astype(np.float32)
    h = a.shape[0]
    y = np.arange(h, dtype=np.float32)
    if dessus:
        t = np.clip(1.0 - y / max(horizon, 1), 0.0, 1.0)
    else:
        t = np.clip((y - horizon) / max(h - horizon, 1), 0.0, 1.0)
    t = (0.35 + 0.65 * t) * alpha
    if dessus:
        t[horizon:] = 0.0
    else:
        t[:horizon] = 0.0
    t = t[:, None, None]
    a = a * (1.0 - t) + np.array(couleur, dtype=np.float32)[None, None, :] * t
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def sol_teinte(img, horizon, cible, force):
    """Remplace la teinte du sol (sous l'horizon) en gardant sa luminance (motif, reflets)."""
    a = np.asarray(img).astype(np.float32)
    lum = a @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    ref = float(np.dot(np.array(cible, dtype=np.float32), [0.299, 0.587, 0.114]))
    teinte = lum[..., None] / ref * np.array(cible, dtype=np.float32)[None, None, :]
    m = np.zeros(a.shape[0], dtype=np.float32)
    fondu = 24
    for y in range(a.shape[0]):
        m[y] = np.clip((y - horizon + fondu) / fondu, 0.0, 1.0) * force
    m = m[:, None, None]
    a = a * (1.0 - m) + teinte * m
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def deriver(ident, source, horizon, miroir, r):
    img = Image.open(os.path.join(DECORS, source + "_back.webp")).convert("RGB")
    if miroir:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    if "sol_teinte" in r:
        img = sol_teinte(img, horizon, *r["sol_teinte"])
    a = np.asarray(img).astype(np.float32) * np.array(r["mul"], dtype=np.float32)[None, None, :]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    img = ImageEnhance.Color(img).enhance(r["sat"])
    img = ImageEnhance.Contrast(img).enhance(r["con"])
    img = ImageEnhance.Brightness(img).enhance(r["lum"])
    if "haut" in r:
        img = voile(img, horizon, r["haut"][0], r["haut"][1], True)
    if "bas" in r:
        img = voile(img, horizon, r["bas"][0], r["bas"][1], False)
    assert img.size == (2340, 1080)
    dest = os.path.join(DECORS, ident + "_back.webp")
    img.save(dest, "WEBP", quality=90, method=6)
    print(dest, os.path.getsize(dest))


def main():
    for ident, (source, horizon, miroir, r) in FONDS.items():
        deriver(ident, source, horizon, miroir, r)


if __name__ == "__main__":
    main()
