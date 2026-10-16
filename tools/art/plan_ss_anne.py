#!/usr/bin/env python3
"""Planche des plans fonctionnels du jalon 16 (S.S. Anne et Arène de Carmin, dossier 19).

Dessine chaque grille `tools/plans/ss_anne_*.txt` et `carmin_arene.txt` en aplats, avec les
positions étiquetées (Dresseurs et leur vue, PNJ, objets, objets cachés, warps), et les assemble
sur une planche. Géométrie seulement : la DA vient de la vue générale peinte.

Usage : python3 tools/art/plan_ss_anne.py [sortie.png]
        (défaut : docs/design/reference/ss-anne-plans-v1.png)
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from plan_check_ss_anne import DIRS, bloquees, vue  # noqa: E402
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
CASE = 28
MARGE = 24
ORDRE = [
	("ss_anne_pont_principal", "Pont principal"), ("ss_anne_couloir_capitaine", "Couloir du capitaine"),
	("ss_anne_cabine_capitaine", "Cabine du capitaine"), ("ss_anne_restaurant", "Restaurant"),
	("ss_anne_pont_inferieur", "Pont inférieur"), ("ss_anne_pont_exterieur", "Pont extérieur"),
	("ss_anne_cabine_a", "Cabine A"), ("ss_anne_cabine_b", "Cabine B"), ("ss_anne_cabine_c", "Cabine C"),
	("carmin_arene", "Arène de Carmin"),
]
COULEURS = {
	"K": (70, 52, 40), ".": (214, 190, 150), "X": (120, 200, 120), "D": (120, 200, 120),
	"S": (110, 170, 220), "T": (240, 200, 90), "w": (60, 110, 160), "r": (150, 120, 90),
	"B": (250, 230, 80), "m": (90, 95, 110), "i": (150, 155, 165),
}
MOBILIER = (160, 120, 85)
TYPES = {
	"dresseur": ((200, 60, 60), "D"), "pnj": ((60, 90, 200), "P"), "objet": ((230, 140, 30), "o"),
	"cache": ((170, 90, 200), "?"), "interactif": ((40, 40, 40), ""), "barriere": ((250, 230, 80), ""),
}


def _fonte(taille: int):
	for nom in ("DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
			"/System/Library/Fonts/Supplemental/Arial Bold.ttf"):
		try:
			return ImageFont.truetype(nom, taille)
		except OSError:
			continue
	return ImageFont.load_default()


def dessiner(nom: str, titre: str) -> Image.Image:
	plan = lire(PLANS / f"{nom}.txt")
	img = Image.new("RGB", (plan.width * CASE + 2 * MARGE, plan.height * CASE + 2 * MARGE + 22), "white")
	d = ImageDraw.Draw(img)
	petite, moyenne = _fonte(11), _fonte(15)
	d.text((MARGE, 4), f"{titre} — {nom} ({plan.width} × {plan.height})", font=moyenne, fill="black")
	oy = MARGE + 18

	def boite(x: int, y: int):
		return [MARGE + x * CASE, oy + y * CASE, MARGE + (x + 1) * CASE - 1, oy + (y + 1) * CASE - 1]

	for y in range(plan.height):
		for x in range(plan.width):
			d.rectangle(boite(x, y), fill=COULEURS.get(plan.at(x, y), MOBILIER), outline=(0, 0, 0, 40))
	bloc = bloquees(plan)
	for p in plan.positions.values():
		if p.kind == "dresseur":
			for c in vue(plan, p, bloc):
				d.rectangle(boite(*c), fill=(240, 160, 150))
	for p in plan.positions.values():
		couleur, lettre = TYPES.get(p.kind, (None, ""))
		for (x, y) in p.cells:
			if p.kind == "interactif":
				d.text((boite(x, y)[0] + CASE / 2, boite(x, y)[1] + CASE / 2), p.attrs.get("index", ""),
					font=petite, fill="white", anchor="mm")
			elif couleur:
				b = boite(x, y)
				d.ellipse([b[0] + 4, b[1] + 4, b[2] - 4, b[3] - 4], fill=couleur)
				if lettre:
					d.text(((b[0] + b[2]) / 2, (b[1] + b[3]) / 2), lettre, font=petite, fill="white", anchor="mm")
				if "facing" in p.attrs:
					dx, dy = DIRS[p.attrs["facing"]]
					cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
					d.line([cx, cy, cx + dx * CASE * 0.45, cy + dy * CASE * 0.45], fill="black", width=3)
		if p.kind in ("dresseur", "pnj", "objet", "cache", "warp"):
			x, y = p.cells[0]
			b = boite(x, y)
			etiquette = p.attrs.get("role", p.ident) if p.kind != "warp" else p.ident.replace("porte_", "→")
			d.text((b[0] + CASE / 2, b[1] - 1), etiquette, font=petite, fill="black", anchor="md")
	return img


def main() -> int:
	sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "docs/design/reference/ss-anne-plans-v1.png"
	images = [dessiner(n, t) for n, t in ORDRE]
	colonnes = 2
	largeur = max(i.width for i in images)
	lignes = [images[k:k + colonnes] for k in range(0, len(images), colonnes)]
	hauteur = sum(max(i.height for i in ligne) for ligne in lignes)
	planche = Image.new("RGB", (largeur * colonnes, hauteur + 60), "white")
	d = ImageDraw.Draw(planche)
	d.text((MARGE, 12), "J16 — S.S. Anne et Arène de Carmin : plans fonctionnels v1 (dossier 19, à valider)",
		font=_fonte(20), fill="black")
	d.text((MARGE, 38), "vert : sortie / porte · bleu : escalier · jaune : déclencheur du rival / barrière · "
		"rose : vue d'un Dresseur · D Dresseur · P PNJ · o objet · ? objet caché · 1..15 objets à fouiller",
		font=_fonte(12), fill=(60, 60, 60))
	y = 60
	for ligne in lignes:
		for k, img in enumerate(ligne):
			planche.paste(img, (k * largeur, y))
		y += max(i.height for i in ligne)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	planche.save(sortie)
	print(sortie)
	return 0


if __name__ == "__main__":
	sys.exit(main())
