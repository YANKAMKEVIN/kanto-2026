#!/usr/bin/env python3
"""Planches de l'entrée des combats des Dresseurs ordinaires (captures réelles de
tools/capture_ordinaires.sh) : docs/design/fiches-assets/entree-ordinaires/<lot>.jpg (entrée et
lancer en 2340 × 1080 pour chaque classe du lot d'art, tools/art/entree_ordinaires.py) et
entree-ordinaires-ensemble.jpg (un lancer par classe).

  tools/art/planches_ordinaires.py [--apercu]   # --apercu : planches réduites dans build/ordinaires/
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from entree_ordinaires import PLANCHES  # noqa: E402
from planches_champions import _fonte  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
CAPT = RACINE / "build" / "ordinaires"
SORTIE = RACINE / "docs" / "design" / "fiches-assets" / "entree-ordinaires"
MOMENTS = [("entree", "entrée"), ("lancer", "lancer")]
LOTS = {**PLANCHES, "gamin": ["gamin"]}


def _legendes() -> dict[str, str]:
	"""Classe → « Préfixe — carte (Dresseur) » d'après tools/capture_ordinaires.sh."""
	classes = json.loads((RACINE / "data" / "battle" / "trainer_intro.json").read_text())["classes"]
	sh = (RACINE / "tools" / "capture_ordinaires.sh").read_text()
	out = {}
	for c, t, m in re.findall(r"^\s+([a-z_]+)\) echo \"(\S+) (\S+) \S+\"", sh, re.M):
		nom = classes[c]["prefix"] or "Sbire Rocket (femme)"
		out[c] = f"{nom} — {m} ({t})"
	return out


def planche_lot(classes: list[str], leg: dict[str, str], echelle: float = 1.0) -> Image.Image:
	w, h = round(2340 * echelle), round(1080 * echelle)
	entete = round(70 * echelle)
	n = len(classes) * len(MOMENTS)
	p = Image.new("RGB", (w, entete + n * (h + entete)), (18, 22, 28))
	d = ImageDraw.Draw(p)
	d.text((20, entete // 4), "Entrée des Dresseurs ordinaires (captures réelles 2340 × 1080)",
		font=_fonte(round(40 * echelle)), fill=(235, 220, 170))
	k = 0
	for c in classes:
		for nom, moment in MOMENTS:
			y = entete + k * (h + entete) + entete
			d.text((20, y - entete + entete // 4), f"{leg.get(c, c)} — {moment}",
				font=_fonte(round(34 * echelle)), fill=(220, 220, 220))
			chemin = CAPT / c / f"{nom}.png"
			if chemin.exists():
				p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (0, y))
			k += 1
	return p


def ensemble(leg: dict[str, str], echelle: float = 0.3) -> Image.Image:
	tous = sorted(leg)
	w, h = round(2340 * echelle), round(1080 * echelle)
	m, entete, col = 10, 34, 3
	rangs = (len(tous) + col - 1) // col
	p = Image.new("RGB", (col * w + (col + 1) * m, rangs * (h + entete) + m), (18, 22, 28))
	d = ImageDraw.Draw(p)
	for k, c in enumerate(tous):
		x, y = m + (k % col) * (w + m), (k // col) * (h + entete) + entete
		d.text((x, y - 28), leg[c], font=_fonte(20), fill=(235, 220, 170))
		chemin = CAPT / c / "lancer.png"
		if chemin.exists():
			p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
	return p


if __name__ == "__main__":
	apercu = "--apercu" in sys.argv
	dossier = CAPT / "apercu" if apercu else SORTIE
	dossier.mkdir(parents=True, exist_ok=True)
	leg = _legendes()
	for lot, classes in LOTS.items():
		planche_lot(classes, leg, 0.4 if apercu else 1.0).save(
			dossier / f"{lot.replace('_', '-')}.jpg", quality=76)
	ensemble(leg).save((dossier if apercu else SORTIE.parent) / "entree-ordinaires-ensemble.jpg",
		quality=86)
	print(dossier)
