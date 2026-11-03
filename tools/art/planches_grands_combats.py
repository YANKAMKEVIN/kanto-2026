#!/usr/bin/env python3
"""Planches de l'entrée des autres grands combats (captures réelles de
tools/capture_grands_combats.sh) : docs/design/fiches-assets/entree-grands-combats/<lieu>.jpg
(entrée, lancer, « VS » en 2340 × 1080 pour chaque combat du lieu) et
entree-grands-combats-ensemble.jpg (le « VS » de tous les combats).

  tools/art/planches_grands_combats.py [--apercu]   # --apercu : planches réduites dans build/grands/
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from planches_champions import MOMENTS, _fonte  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
CAPT = RACINE / "build" / "grands"
SORTIE = RACINE / "docs" / "design" / "fiches-assets" / "entree-grands-combats"
# Lieu → combats (dossier de captures, légende).
LIEUX: dict[str, tuple[str, list[tuple[str, str]]]] = {
	"labo-chen": ("Laboratoire du Prof. Chen", [("rival_labo", "Rival, 1er combat")]),
	"route-22": ("Route 22", [("rival_route22", "Rival, 2e combat"),
		("rival_route22_final", "Rival, avant la Route Victoire")]),
	"route-24": ("Route 24, Pont Pépite", [("rival_route24", "Rival, à Azuria")]),
	"ss-anne": ("S.S. Anne, couloir du capitaine", [("rival_ss_anne", "Rival")]),
	"tour-pokemon": ("Tour Pokémon, 2e étage", [("rival_tour", "Rival")]),
	"sylphe": ("Sylphe SARL", [("rival_sylphe", "Rival, 7e étage"),
		("giovanni_sylphe", "Giovanni, 11e étage")]),
	"repaire-rocket": ("Repaire de la Team Rocket", [("giovanni_repaire", "Giovanni")]),
	"ligue": ("Ligue Pokémon, Conseil des 4", [("olga", "Olga"), ("aldo", "Aldo"),
		("agatha", "Agatha"), ("peter", "Peter")]),
	"ligue-maitre": ("Ligue Pokémon, salle du Maître", [("maitre", "Rival, Champion de la Ligue"),
		("rivale_maitre", "Rivale, Champion de la Ligue")]),
}


def planche_lieu(titre: str, combats: list[tuple[str, str]], echelle: float = 1.0) -> Image.Image:
	w, h = round(2340 * echelle), round(1080 * echelle)
	entete = round(70 * echelle)
	n = len(combats) * 3
	p = Image.new("RGB", (w, entete + n * (h + entete)), (18, 22, 28))
	d = ImageDraw.Draw(p)
	d.text((20, entete // 4), f"Entrée des grands combats — {titre} (captures réelles 2340 × 1080)",
		font=_fonte(round(40 * echelle)), fill=(235, 220, 170))
	k = 0
	for ident, leg in combats:
		for nom, moment in MOMENTS:
			y = entete + k * (h + entete) + entete
			d.text((20, y - entete + entete // 4), f"{leg} — {moment}", font=_fonte(round(34 * echelle)),
				fill=(220, 220, 220))
			chemin = CAPT / ident / f"{nom}.png"
			if chemin.exists():
				p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (0, y))
			k += 1
	return p


def ensemble(echelle: float = 0.4) -> Image.Image:
	tous = [(ident, f"{titre} — {leg}") for titre, combats in LIEUX.values() for ident, leg in combats]
	w, h = round(2340 * echelle), round(1080 * echelle)
	m, entete = 12, 40
	rangs = (len(tous) + 1) // 2
	p = Image.new("RGB", (2 * w + 3 * m, rangs * (h + entete) + m), (18, 22, 28))
	d = ImageDraw.Draw(p)
	for k, (ident, titre) in enumerate(tous):
		x, y = m + (k % 2) * (w + m), (k // 2) * (h + entete) + entete
		d.text((x, y - 32), f"« VS » — {titre}", font=_fonte(24), fill=(235, 220, 170))
		chemin = CAPT / ident / "vs.png"
		if chemin.exists():
			p.paste(Image.open(chemin).convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
	return p


if __name__ == "__main__":
	apercu = "--apercu" in sys.argv
	dossier = CAPT / "apercu" if apercu else SORTIE
	dossier.mkdir(parents=True, exist_ok=True)
	for lieu, (titre, combats) in LIEUX.items():
		planche_lieu(titre, combats, 0.4 if apercu else 1.0).save(dossier / f"{lieu}.jpg", quality=84)
	ensemble().save((dossier if apercu else SORTIE.parent) / "entree-grands-combats-ensemble.jpg",
		quality=86)
	print(dossier)
