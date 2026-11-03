#!/usr/bin/env python3
"""Planches de l'entrée des Champions (captures réelles de tools/capture_champions.sh) :
docs/design/fiches-assets/entree-champions/<arene>.jpg (entrée, lancer, VS en 2340 × 1080,
empilés) et entree-champions-ensemble.jpg (le VS des 8 Champions).

  tools/art/planches_champions.py [--apercu]   # --apercu : planches réduites dans build/champions/
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
CAPT = RACINE / "build" / "champions"
SORTIE = RACINE / "docs" / "design" / "fiches-assets" / "entree-champions"
ARENES = [("argenta", "Pierre — Arène d'Argenta"), ("azuria", "Ondine — Arène d'Azuria"),
	("carmin", "Major Bob — Arène de Carmin-sur-Mer"), ("celadopole", "Erika — Arène de Céladopole"),
	("parmanie", "Koga — Arène de Parmanie"), ("safrania", "Morgane — Arène de Safrania"),
	("cramois", "Auguste — Arène de Cramois'Île"), ("jadielle", "Giovanni — Arène de Jadielle")]
MOMENTS = [("entree", "entrée"), ("lancer", "lancer"), ("vs", "« VS »")]


def _fonte(taille: int) -> ImageFont.FreeTypeFont:
	for f in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"):
		if Path(f).exists():
			return ImageFont.truetype(f, taille)
	return ImageFont.load_default()


def planche_arene(ident: str, titre: str, echelle: float = 1.0) -> Image.Image:
	w, h = round(2340 * echelle), round(1080 * echelle)
	entete = round(70 * echelle)
	p = Image.new("RGB", (w, entete + 3 * (h + entete)), (18, 22, 28))
	d = ImageDraw.Draw(p)
	d.text((20, entete // 4), f"Entrée des combats de Dresseur — {titre} (captures réelles 2340 × 1080)",
		font=_fonte(round(40 * echelle)), fill=(235, 220, 170))
	for i, (nom, leg) in enumerate(MOMENTS):
		y = entete + i * (h + entete) + entete
		d.text((20, y - entete + entete // 4), f"{i + 1}. {leg}", font=_fonte(round(34 * echelle)),
			fill=(220, 220, 220))
		chemin = CAPT / ident / f"{nom}.png"
		if chemin.exists():
			p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (0, y))
	return p


def ensemble(echelle: float = 0.4) -> Image.Image:
	w, h = round(2340 * echelle), round(1080 * echelle)
	m, entete = 12, 40
	p = Image.new("RGB", (2 * w + 3 * m, 4 * (h + entete) + m), (18, 22, 28))
	d = ImageDraw.Draw(p)
	for k, (ident, titre) in enumerate(ARENES):
		x, y = m + (k % 2) * (w + m), (k // 2) * (h + entete) + entete
		d.text((x, y - 32), f"« VS » — {titre}", font=_fonte(24), fill=(235, 220, 170))
		chemin = CAPT / ident / "vs.png"
		if chemin.exists():
			p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
	return p


if __name__ == "__main__":
	apercu = "--apercu" in sys.argv
	dossier = CAPT if apercu else SORTIE
	dossier.mkdir(parents=True, exist_ok=True)
	for ident, titre in ARENES:
		planche_arene(ident, titre, 0.4 if apercu else 1.0).save(dossier / f"{ident}.jpg", quality=84)
	ensemble().save((CAPT if apercu else SORTIE.parent) / "entree-champions-ensemble.jpg", quality=86)
	print(dossier)
