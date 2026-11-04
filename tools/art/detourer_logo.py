#!/usr/bin/env python3
"""Détourage reproductible du logo du jeu (OUV.1, dossier 13 §9.0 bis ; J34 : logo « Pokemake »).

Le logo validé (« Kanto 2026 » r2 `build/art/VALIDE_LOGO_KANTO_2026.png`, puis « Pokemake »
`build/art/VALIDE_LOGO_POKEMAKE.png`, 1536 × 1024, hors dépôt) est peint sur un fond sombre
lumineux : lettres dorées à contour bleu nuit, halo doré qui va jusqu'aux bords de l'image. Ce
script en tire, pour un nom de sortie NOM (défaut `pokemake`) :

  assets/ui/opening/logo_NOM.png    logo détouré (écran titre), halo doux gardé
  assets/ui/opening/splash_NOM.png  image de démarrage 1920 × 1080 : le logo détouré
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
  python3 tools/art/detourer_logo.py [chemin du logo validé] [NOM]
(défaut : build/art/VALIDE_LOGO_POKEMAKE.png du dépôt principal, NOM « pokemake » ; l'ancien
logo : `detourer_logo.py build/art/VALIDE_LOGO_KANTO_2026.png kanto_2026`).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = Path("/Users/kevinyankam/dev/kanto-2026/build/art/VALIDE_LOGO_POKEMAKE.png")
DEFAULT_NAME = "pokemake"
OUT_DIR = ROOT / "assets" / "ui" / "opening"

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
HALO_STRENGTH = 0.6  # J34 : 0,85 faisait un rectangle pâle visible sur l'herbe du titre
HALO_GAMMA = 1.15
# Extinction du halo vers les bords de l'image source (px).
EDGE_FADE = 220  # J34 : extinction plus large, halo plus doux
# Seuil d'alpha du recadrage et marge gardée autour (px source).
CROP_ALPHA = 4
CROP_MARGIN = 12
LOGO_WIDTH = 1280
# Image de démarrage : taille, fond uni (aussi `application/boot_splash/bg_color`), largeur du logo.
SPLASH_SIZE = (1920, 1080)
SPLASH_BG = (20, 16, 11)
# J34 : vignette radiale (fond SPLASH_BG au centre vers SPLASH_EDGE aux coins), logo un peu plus
# petit et remonté (centre à SPLASH_LOGO_CENTER_Y de la hauteur) : la ligne dorée ne coupe plus
# l'image en deux.
SPLASH_EDGE = (9, 7, 5)
SPLASH_LOGO_WIDTH = 1100
SPLASH_LOGO_CENTER_Y = 0.45


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


def _detour_arrays(source: Path) -> tuple:
    """RGBA détouré (taille source), masque du cœur (0–1), RGB source et boîte de recadrage."""
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
    box = Image.fromarray((rgba[..., 3] > CROP_ALPHA).astype(np.uint8) * 255).getbbox()
    if box is None:
        raise SystemExit("logo vide après détourage")
    left, top, right, bottom = box
    box = (max(left - CROP_MARGIN, 0), max(top - CROP_MARGIN, 0),
           min(right + CROP_MARGIN, width), min(bottom + CROP_MARGIN, height))
    return rgba, core, rgb, box


def detour(source: Path) -> Image.Image:
    rgba, _core, _rgb, box = _detour_arrays(source)
    return Image.fromarray(rgba).crop(box)


def _resized(image: Image.Image, target_width: int) -> Image.Image:
    target_height = round(image.height * target_width / image.width)
    return image.resize((target_width, target_height), Image.LANCZOS)


def _splash_background() -> Image.Image:
    """Fond du splash : vignette radiale douce, SPLASH_BG au centre, SPLASH_EDGE dans les coins."""
    width, height = SPLASH_SIZE
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float64)
    dx = (xs - width / 2) / (width / 2)
    dy = (ys - height / 2) / (height / 2)
    d = np.clip(np.sqrt(dx * dx + dy * dy) / np.sqrt(2.0), 0.0, 1.0)
    k = (d * d * (3.0 - 2.0 * d))[..., None]
    rgb = (1.0 - k) * np.array(SPLASH_BG, dtype=np.float64) + k * np.array(SPLASH_EDGE, dtype=np.float64)
    rgba = np.dstack([rgb, np.full((height, width), 255.0)]).round().astype(np.uint8)
    return Image.fromarray(rgba)


# Pièces du logo pour l'ident animé (J34, demande de Kevin : les lettres entrent une à une) :
# lettres et filet découpés dans le cœur opaque (sans halo), dans le cadre du logo détouré.
PARTS_ALPHA = 0.5
# Au-dessus de cette part des colonnes pleines, une rangée appartient aux lettres ; en dessous,
# au filet (le filet est une ligne fine : peu de pixels par rangée en proportion).
LETTER_COUNT = 8


def _parts(core_rgba: np.ndarray) -> dict:
    """Découpe le cœur (RGBA, cadre du logo) en LETTER_COUNT lettres + le filet.

    Rangées : la bande des lettres est la plus haute des bandes pleines, le filet la plus basse.
    Colonnes : les contours et les empattements se touchent d'une lettre à l'autre ; on compte
    donc, par colonne, les pixels **dorés** (luminance ≥ CORE_LUMA) et une colonne n'est pleine
    qu'au-dessus d'une part de la hauteur de la bande (les pointes d'empattements ne comptent
    pas). Le seuil est cherché jusqu'à obtenir LETTER_COUNT groupes ; les colonnes entre deux
    lettres sont partagées au milieu de l'intervalle."""
    alpha = core_rgba[..., 3] > PARTS_ALPHA * 255
    rows = alpha.any(axis=1)
    bands = _runs(rows)
    if len(bands) < 2:
        raise SystemExit(f"bandes horizontales trouvées : {len(bands)} (attendu : lettres + filet)")
    bands.sort(key=lambda b: b[0])
    letters_band, rule_band = bands[0], bands[-1]
    y0, y1 = letters_band
    gold = (core_rgba[y0:y1, :, :3].max(axis=2) >= CORE_LUMA * 255) & alpha[y0:y1]
    counts = gold.sum(axis=0)
    letter_runs = []
    for share in [x / 100.0 for x in range(6, 41, 2)]:
        letter_runs = _runs(counts >= share * (y1 - y0))
        if len(letter_runs) == LETTER_COUNT:
            break
    if len(letter_runs) != LETTER_COUNT:
        raise SystemExit(f"lettres trouvées : {len(letter_runs)} (attendu {LETTER_COUNT}) : "
                         + str(letter_runs))
    xs_on = np.where(alpha[y0:y1].any(axis=0))[0]
    bounds = [int(xs_on[0])]
    for (_a0, a1), (b0, _b1) in zip(letter_runs, letter_runs[1:]):
        bounds.append((a1 + b0) // 2)
    bounds.append(int(xs_on[-1]) + 1)
    pieces = []
    for x0, x1 in zip(bounds, bounds[1:]):
        sub = alpha[y0:y1, x0:x1]
        ys = np.where(sub.any(axis=1))[0]
        xs = np.where(sub.any(axis=0))[0]
        pieces.append({"x": x0 + int(xs[0]), "y": y0 + int(ys[0]),
                       "w": int(xs[-1] - xs[0]) + 1, "h": int(ys[-1] - ys[0]) + 1})
    rule_cols = alpha[rule_band[0]:rule_band[1]].any(axis=0)
    xs = np.where(rule_cols)[0]
    rule = {"x": int(xs[0]), "y": int(rule_band[0]), "w": int(xs[-1] - xs[0] + 1),
            "h": int(rule_band[1] - rule_band[0])}
    return {"letters": pieces, "rule": rule}


def _runs(mask_1d: np.ndarray) -> list:
    runs, start = [], None
    for i, on in enumerate(list(mask_1d) + [False]):
        if on and start is None:
            start = i
        elif not on and start is not None:
            runs.append((start, i))
            start = None
    return runs


def core_image(source: Path) -> Image.Image:
    """Le logo sans halo (lettres + contour seulement), recadré comme [detour] et à LOGO_WIDTH."""
    _rgba, core, rgb, box = _detour_arrays(source)
    rgba = np.dstack([rgb, core * 255.0]).round().clip(0, 255).astype(np.uint8)
    return _resized(Image.fromarray(rgba).crop(box), LOGO_WIDTH)


def write_parts(source: Path, name: str, logo_size: tuple) -> None:
    import json
    core = core_image(source)
    parts = _parts(np.asarray(core))
    out_dir = OUT_DIR / f"logo_{name}_parts"
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    for i, piece in enumerate(parts["letters"]):
        core.crop((piece["x"], piece["y"], piece["x"] + piece["w"], piece["y"] + piece["h"])) \
            .save(out_dir / f"letter_{i}.png", optimize=True)
    r = parts["rule"]
    core.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])).save(out_dir / "rule.png", optimize=True)
    manifest = {"frame": [logo_size[0], logo_size[1]], "letters": parts["letters"], "rule": r}
    (out_dir / "parts.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(f"{out_dir.relative_to(ROOT)} : {len(parts['letters'])} lettres + filet, parts.json")


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    name = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_NAME
    logo_out = OUT_DIR / f"logo_{name}.png"
    splash_out = OUT_DIR / f"splash_{name}.png"
    if not source.exists():
        raise SystemExit(f"logo validé introuvable : {source}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    logo = detour(source)
    _resized(logo, LOGO_WIDTH).save(logo_out, optimize=True)
    splash = _splash_background()
    small = _resized(logo, SPLASH_LOGO_WIDTH)
    offset = ((SPLASH_SIZE[0] - small.width) // 2,
              round(SPLASH_SIZE[1] * SPLASH_LOGO_CENTER_Y - small.height / 2))
    splash.alpha_composite(small, offset)
    splash.convert("RGB").save(splash_out, optimize=True)
    print(f"{logo_out.relative_to(ROOT)} : {LOGO_WIDTH} px de large")
    write_parts(source, name, _resized(logo, LOGO_WIDTH).size)
    print(f"{splash_out.relative_to(ROOT)} : {SPLASH_SIZE[0]} × {SPLASH_SIZE[1]}")


if __name__ == "__main__":
    main()
