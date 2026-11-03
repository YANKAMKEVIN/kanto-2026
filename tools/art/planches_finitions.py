#!/usr/bin/env python3
"""Planches des finitions de l'entrée des combats de Dresseur (captures réelles 2340 × 1080 de
tools/capture_finitions.sh ; fiche docs/design/fiches-assets/entree-dresseurs.md §13) :

- docs/design/fiches-assets/entree-mer-comparatif.jpg : même combat (Route 19, Nageur Yann), banc
  de sable actuel / Surf, à l'entrée, au lancer de l'adversaire et au lancer du joueur ;
- docs/design/fiches-assets/entree-finitions.jpg : la joueuse en Surf, les Routes 16 ouest et 18
  sur la Piste, le Karatéka (monde et combat) et les deux feuilles du monde.

  tools/art/planches_finitions.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from planches_champions import _fonte  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
CAPT = RACINE / "build" / "finitions"
FICHES = RACINE / "docs" / "design" / "fiches-assets"
MONDE = RACINE / "assets" / "sprites" / "characters" / "painted"
FOND = (18, 22, 28)
OR = (235, 220, 170)
GRIS = (220, 220, 220)
ECH = 0.5
W, H = round(2340 * ECH), round(1080 * ECH)
M, ENTETE = 16, 54


def _grille(titre: str, rangees: list[tuple[str, list[tuple[str, str, str]]]]) -> Image.Image:
	"""rangees : (légende de la rangée, [(capture, cliché, légende de la case)])."""
	col = max(len(c) for _, c in rangees)
	largeur = col * W + (col + 1) * M
	hauteur = ENTETE + len(rangees) * (H + 2 * ENTETE) + M
	p = Image.new("RGB", (largeur, hauteur), FOND)
	d = ImageDraw.Draw(p)
	d.text((M, 12), titre, font=_fonte(34), fill=OR)
	y = ENTETE
	for legende, cases in rangees:
		d.text((M, y + 10), legende, font=_fonte(30), fill=OR)
		y += ENTETE
		for k, (capture, cliche, sous) in enumerate(cases):
			x = M + k * (W + M)
			d.text((x, y + 8), sous, font=_fonte(24), fill=GRIS)
			zoom = cliche.endswith("@zoom")  # agrandissement × 2 du centre (apparences du monde)
			chemin = CAPT / capture / f"{cliche.removesuffix('@zoom')}.png"
			if chemin.exists():
				im = Image.open(chemin).convert("RGB")
				if zoom:
					im = im.crop((im.width // 4, im.height // 4, im.width * 3 // 4, im.height * 3 // 4))
				p.paste(im.resize((W, H), Image.LANCZOS), (x, y + ENTETE))
		y += H + ENTETE
	return p


def comparatif() -> Image.Image:
	moments = [("entree", "entrée"), ("lancer", "lancer de l'adversaire"),
		("lancer_joueur", "lancer du joueur")]
	return _grille("Mer des Routes 19 à 21 — même combat (Route 19, Nageur Yann), captures réelles "
		"2340 × 1080", [
		("A. Banc de sable actuel (sea_open_v2, mise en scène à pied, réglage par défaut)",
			[("mer_sable", c, s) for c, s in moments]),
		("B. Surf (sea_surf : mer ouverte, joueur sur la monture du monde, Nageur dans l'eau)",
			[("mer_surf", c, s) for c, s in moments]),
	])


def _feuilles() -> Image.Image:
	"""Les deux feuilles du monde (4 × 4) côte à côte, agrandies × 2, sur fond de sol."""
	ims = [Image.open(MONDE / f"{n}_sheet.png").convert("RGBA") for n in ("karateka", "maitre_dojo")]
	ims = [i.resize((i.width * 2, i.height * 2), Image.LANCZOS) for i in ims]
	t = Image.new("RGBA", (sum(i.width for i in ims) + 60, max(i.height for i in ims)), (196, 186, 160, 255))
	x = 0
	for i in ims:
		t.alpha_composite(i, (x, 0))
		x += i.width + 60
	return t.convert("RGB")


def finitions() -> Image.Image:
	p = _grille("Finitions de l'entrée des Dresseurs — captures réelles 2340 × 1080", [
		("1. Surf, la joueuse (Route 20, Nageuse Solène ; réglage forcé pour la capture)",
			[("mer_surf_joueuse", "entree", "entrée"), ("mer_surf_joueuse", "lancer_joueur", "lancer du joueur")]),
		("1. Surf, le héros (Route 19, Nageur Yann)",
			[("mer_surf", "entree", "entrée"), ("mer_surf", "lancer_joueur", "lancer du joueur")]),
		("3. Route 16 ouest sur route_17_cyclable (Loubard)",
			[("route_16_ouest", "entree", "entrée"), ("route_16_ouest", "lancer", "lancer")]),
		("3. Route 18 sur route_17_cyclable (Ornithologue)",
			[("route_18", "entree", "entrée"), ("route_18", "lancer", "lancer")]),
		("2. Karatéka : sa feuille du monde (Dojo de Safrania, Maître du Dojo au fond ; Arène de Jadielle)",
			[("karateka", "monde", "Dojo : monde"), ("karateka_jadielle", "monde", "Arène de Jadielle : monde")]),
		("2. Le Dojo, centre agrandi × 2 (quatre Karatékas, le Maître du Dojo en haut)",
			[("karateka", "monde@zoom", "Dojo de Safrania")]),
		("2. Karatéka en combat (Dojo de Safrania)",
			[("karateka", "entree", "entrée"), ("karateka", "lancer", "lancer")]),
	])
	f = _feuilles()
	f = f.resize((round(f.width * 0.9), round(f.height * 0.9)), Image.LANCZOS)
	out = Image.new("RGB", (p.width, p.height + f.height + 2 * ENTETE), FOND)
	out.paste(p, (0, 0))
	d = ImageDraw.Draw(out)
	d.text((M, p.height + 10), "2. Feuilles du monde peintes : karateka (blackbelt) et maitre_dojo "
		"(karate_master), 4 × 4, 128 px", font=_fonte(30), fill=OR)
	out.paste(f, (M, p.height + ENTETE + 10))
	return out


if __name__ == "__main__":
	comparatif().save(FICHES / "entree-mer-comparatif.jpg", quality=86)
	finitions().save(FICHES / "entree-finitions.jpg", quality=86)
	print(FICHES / "entree-mer-comparatif.jpg")
	print(FICHES / "entree-finitions.jpg")
