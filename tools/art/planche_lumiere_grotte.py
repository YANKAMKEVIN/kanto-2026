#!/usr/bin/env python3
"""Planches comparatives AVANT / APRÈS de la passe « lumière rare » du Mont Sélénite.

Lit deux séries de `tools/capture_mt_moon.sh` (dossiers avec `<vue>.png` et, facultatif,
`mesures.json` de `luminance_grotte.py --json`) et écrit deux planches : vues 1:1 aux repères
(hall et puits, carrefour, camp, guetteur, couloir des lampes, chambre) avec leurs mesures, et
vues d'ensemble des trois étages.

    python3 tools/art/planche_lumiere_grotte.py build/captures/mt_moon_avant \
        build/captures/mt_moon_apres build/captures/planche_lumiere_grotte
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

VUES = [
	("hall_1f", "1F — hall et puits de jour"),
	("carrefour_1f", "1F — carrefour (colonne)"),
	("camp_1f", "1F — camp Rocket"),
	("guetteur_b1f", "B1F — guetteur (lampes)"),
	("couloir_b2f", "B2F — couloir des lampes"),
	("chambre_b2f", "B2F — chambre des fossiles"),
]
ENSEMBLES = [("ensemble_1f", "1F"), ("ensemble_b1f", "B1F"), ("ensemble_b2f", "B2F")]
L, H, MARGE, TITRE, LEGENDE = 1000, 462, 16, 34, 28
FOND = (24, 26, 32)
CLAIR = (235, 235, 240)


def police(taille: int):
	try:
		return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", taille)
	except OSError:
		return ImageFont.load_default()


def mesures(dossier: Path) -> dict:
	fichier = dossier / "mesures.json"
	if not fichier.exists():
		return {}
	return {r["vue"]: r for r in json.loads(fichier.read_text())}


def legende(r: dict | None) -> str:
	if not r:
		return ""
	return (f"sol de la vue {r['sol']:.3f} · près du joueur {r.get('sol_joueur') or 0:.3f} · "
		f"repères {r.get('sol_reperes') or 0:.3f} · centre / pourtour {r.get('ecart')} · "
		f"sol / paroi {r.get('rapport_proche')}")


def planche(dossiers: list[Path], vues: list, titre: str, avec_mesures: bool) -> Image.Image:
	ligne = H + TITRE + (LEGENDE if avec_mesures else 0) + MARGE
	image = Image.new("RGB", (2 * L + 3 * MARGE, 60 + len(vues) * ligne), FOND)
	dessin = ImageDraw.Draw(image)
	dessin.text((MARGE, 16), titre, fill=CLAIR, font=police(24))
	toutes = [mesures(d) for d in dossiers]
	y = 60
	for vue, nom in vues:
		for i, dossier in enumerate(dossiers):
			x = MARGE + i * (L + MARGE)
			dessin.text((x, y), f"{nom} — {'avant' if i == 0 else 'après'}", fill=CLAIR,
				font=police(24))
			capture = Image.open(dossier / f"{vue}.png").convert("RGB").resize((L, H),
				Image.LANCZOS)
			image.paste(capture, (x, y + TITRE))
			if avec_mesures:
				dessin.text((x, y + TITRE + H + 4), legende(toutes[i].get(vue)),
					fill=(200, 205, 215), font=police(19))
		y += ligne
	return image


def main() -> int:
	if len(sys.argv) != 4:
		print(__doc__)
		return 2
	avant, apres, sortie = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
	planche([avant, apres], VUES, "Mont Sélénite — passe « lumière rare » : AVANT (gauche) / "
		"APRÈS (droite), captures Mac 2340 × 1080", True).save(f"{sortie}.png")
	planche([avant, apres], ENSEMBLES, "Mont Sélénite — vues d'ensemble AVANT / APRÈS",
		False).save(f"{sortie}_ensembles.png")
	print(f"{sortie}.png, {sortie}_ensembles.png")
	return 0


if __name__ == "__main__":
	sys.exit(main())
