#!/usr/bin/env python3
"""Détourage reproductible du logo « Kanto 2026 » validé (OUV.1, dossier 13 §9.0 bis).

Le logo validé (r2, `build/art/VALIDE_LOGO_KANTO_2026.png`, 1536 × 1024, hors dépôt) est peint
sur un fond sombre lumineux : lettres dorées à contour bleu nuit, « 2026 » bleu clair, halo doré
qui va jusqu'aux bords de l'image. Ce script en tire :

  assets/ui/opening/logo_kanto_2026.png    logo détouré (écran titre), halo doux gardé
  assets/ui/opening/splash_kanto_2026.png  image de démarrage 1920 × 1080 : le logo détouré
                                           posé sur un fond uni sombre et chaud (SPLASH_BG)

Méthode (aucune retouche à la main, relançable) :
  1. **cœur opaque** : les lettres (or et bleu clair : luminance haute) et leur contour bleu nuit
     (bleu nettement au-dessus du rouge), refermé puis adouci d'un pixel (anticrénelage) ;
  2. **halo** : partout ailleurs, le fond est noir ; un pixel du halo est « couleur × alpha »
     sur du noir. Alpha = luminance (max des canaux) au-dessus du plancher du fond, multipliée par
     HALO_STRENGTH ; couleur = pixel / luminance (désaturation nulle, teinte gardée) ;
  3. le halo s'éteint en douceur vers les bords de l'image (EDGE_FADE px), sinon il serait coupé
     net ; puis recadrage sur ce qui reste visible et mise à la largeur LOGO_WIDTH.

Usage :
  python3 tools/art/detourer_logo.py [chemin du logo validé]
(défaut : build/art/VALIDE_LOGO_KANTO_2026.png du dépôt principal, voir DEFAULT_SOURCE).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = Path("/Users/kevinyankam/dev/kanto-2026/build/art/VALIDE_LOGO_KANTO_2026.png")
OUT_DIR = ROOT / "assets" / "ui" / "opening"
LOGO_OUT = OUT_DIR / "logo_kanto_2026.png"
SPLASH_OUT = OUT_DIR / "splash_kanto_2026.png"

# Cœur : luminance (0–1) au-dessus de laquelle un pixel est une lettre.
CORE_LUMA = 0.8
# Contour bleu nuit : bleu − rouge (0–255) au moins, bleu au moins…
OUTLINE_BLUE_EXCESS = 22
OUTLINE_BLUE_MIN = 30
# …et rouge au plus : le contour est un bleu nuit presque sans rouge (le halo bleuté de « 2026 »
# en a beaucoup).
OUTLINE_RED_MAX = 40
# Liseré gardé opaque autour des lettres (px source).
OUTLINE_RING = 2
# Halo : plancher du fond (luminance) et force du halo gardé (1 = tel quel sur du noir).
HALO_FLOOR = 0.02
HALO_STRENGTH = 0.85
HALO_GAMMA = 1.15
# Extinction du halo vers les bords de l'image source (px).
EDGE_FADE = 140
# Seuil d'alpha du recadrage et marge gardée autour (px source).
CROP_ALPHA = 4
CROP_MARGIN = 12
LOGO_WIDTH = 1280
# Image de démarrage : taille, fond uni (aussi `application/boot_splash/bg_color`), largeur du logo.
SPLASH_SIZE = (1920, 1080)
SPLASH_BG = (20, 16, 11)
SPLASH_LOGO_WIDTH = 1240


def _core_mask(rgb: np.ndarray) -> np.ndarray:
    luma = rgb.max(axis=2) / 255.0
    r, b = rgb[..., 0], rgb[..., 2]
    letters = luma >= CORE_LUMA
    outline = ((b - r) >= OUTLINE_BLUE_EXCESS) & (b >= OUTLINE_BLUE_MIN) & (r <= OUTLINE_RED_MAX)
    # Liseré autour de l'or (OUTLINE_RING px) : le contour brun des filets, que la teinte ne
    # distingue pas du halo.
    ring = Image.fromarray((letters * 255).astype(np.uint8))
    ring = np.asarray(ring.filter(ImageFilter.MaxFilter(2 * OUTLINE_RING + 1))) > 0
    mask = Image.fromarray(((letters | outline | ring) * 255).astype(np.uint8))
    # Fermeture (trous d'un pixel entre l'or et le contour), puis bord adouci.
    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    mask = mask.filter(ImageFilter.GaussianBlur(0.8))
    return np.asarray(mask).astype(np.float64) / 255.0


def _edge_fade(height: int, width: int) -> np.ndarray:
    ys = np.minimum(np.arange(height), np.arange(height)[::-1]) / EDGE_FADE
    xs = np.minimum(np.arange(width), np.arange(width)[::-1]) / EDGE_FADE
    fade = np.clip(np.minimum(ys[:, None], xs[None, :]), 0.0, 1.0)
    return fade * fade * (3.0 - 2.0 * fade)


def detour(source: Path) -> Image.Image:
    rgb = np.asarray(Image.open(source).convert("RGB")).astype(np.float64)
    height, width = rgb.shape[:2]
    core = _core_mask(rgb)
    luma = rgb.max(axis=2) / 255.0
    halo = np.clip((luma - HALO_FLOOR) / (1.0 - HALO_FLOOR), 0.0, 1.0) ** HALO_GAMMA
    halo *= HALO_STRENGTH * _edge_fade(height, width)
    # Couleur du halo : le pixel « dé-multiplié » par sa luminance (sur fond noir).
    glow = rgb / np.maximum(luma, 1e-3)[..., None]
    color = core[..., None] * rgb + (1.0 - core[..., None]) * np.clip(glow, 0.0, 255.0)
    alpha = np.maximum(core, halo)
    rgba = np.dstack([color, alpha * 255.0]).round().clip(0, 255).astype(np.uint8)
    image = Image.fromarray(rgba)
    box = Image.fromarray((rgba[..., 3] > CROP_ALPHA).astype(np.uint8) * 255).getbbox()
    if box is None:
        raise SystemExit("logo vide après détourage")
    left, top, right, bottom = box
    box = (max(left - CROP_MARGIN, 0), max(top - CROP_MARGIN, 0),
           min(right + CROP_MARGIN, width), min(bottom + CROP_MARGIN, height))
    return image.crop(box)


def _resized(image: Image.Image, target_width: int) -> Image.Image:
    target_height = round(image.height * target_width / image.width)
    return image.resize((target_width, target_height), Image.LANCZOS)


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not source.exists():
        raise SystemExit(f"logo validé introuvable : {source}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    logo = detour(source)
    _resized(logo, LOGO_WIDTH).save(LOGO_OUT, optimize=True)
    splash = Image.new("RGBA", SPLASH_SIZE, SPLASH_BG + (255,))
    small = _resized(logo, SPLASH_LOGO_WIDTH)
    offset = ((SPLASH_SIZE[0] - small.width) // 2, (SPLASH_SIZE[1] - small.height) // 2)
    splash.alpha_composite(small, offset)
    splash.convert("RGB").save(SPLASH_OUT, optimize=True)
    print(f"{LOGO_OUT.relative_to(ROOT)} : {LOGO_WIDTH} px de large")
    print(f"{SPLASH_OUT.relative_to(ROOT)} : {SPLASH_SIZE[0]} × {SPLASH_SIZE[1]}")


if __name__ == "__main__":
    main()
