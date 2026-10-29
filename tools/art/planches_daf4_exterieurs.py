#!/usr/bin/env python3
"""Planches du dernier morceau du lot DAF.4 : sol peint de la Route 23 et du Plateau Indigo
(`tools/build_daf4_exterieurs.gd`), captures 2340 × 1080 avant / après. Mêmes mises en page que
`planches_daf4.py` ; les planches déjà validées ne sont pas réécrites.

  tools/capture_daf4.sh build/captures/daf4_avant 'route_23|plateau'   (avant la passe, une fois)
  tools/capture_daf4.sh build/captures/daf4_apres 'route_23|plateau'
  python3 tools/art/planches_daf4_exterieurs.py

Écrit `docs/design/fiches-assets/daf-4/planche-7-route-23-plateau.jpg` et
`daf-4/synthese-telephone-exterieurs.jpg`.
"""
from __future__ import annotations

from PIL import Image, ImageDraw

import planches_daf3 as p3

p3.AVANT = p3.RACINE / "build/captures/daf4_avant"
p3.APRES = p3.RACINE / "build/captures/daf4_apres"
DAF4 = p3.DAF4
PAIRES = [("route_23_sud", "Route 23 sud (contrôle du Badge Cascade)"),
	("route_23_milieu", "Route 23 milieu (hautes herbes, eau)"),
	("route_23_nord", "Route 23 nord (rochers, Route Victoire)"),
	("plateau_indigo", "Plateau Indigo")]


def main() -> None:
	p3._ecrire(p3._avant_apres(PAIRES, "DAF.4 — sol peint de la Route 23 et du Plateau Indigo"),
		DAF4 / "planche-7-route-23-plateau.jpg")
	lw = 1080
	hh = lw * 1080 // 2340
	bloc = 2 * hh + 110
	syn = Image.new("RGB", (lw, 140 + len(PAIRES) * bloc), p3.FOND)
	d = ImageDraw.Draw(syn)
	d.text((24, 30), "DAF.4 (fin) : avant / après", font=p3._police(54), fill=p3.TEXTE)
	y = 140
	for nom, legende in PAIRES:
		d.text((24, y), legende, font=p3._police(40), fill=p3.TEXTE)
		for k, (dossier, mot) in enumerate(((p3.AVANT, "avant"), (p3.APRES, "après"))):
			yy = y + 56 + k * (hh + 4)
			syn.paste(Image.open(dossier / f"{nom}.png").convert("RGB").resize((lw, hh), Image.LANCZOS), (0, yy))
			d.rectangle((0, yy, 150, yy + 46), fill=p3.FOND)
			d.text((12, yy + 4), mot, font=p3._police(34), fill=p3.TEXTE if k else p3.GRIS)
		y += bloc
	p3._ecrire(syn, DAF4 / "synthese-telephone-exterieurs.jpg")


if __name__ == "__main__":
	main()
