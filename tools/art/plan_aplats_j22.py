#!/usr/bin/env python3
"""Plans en aplats des grilles du jalon 22 (lot 22.0, T6), pour la relecture de Kevin.

Une image par grille (aplats + Dresseurs et leurs vues, objets, portes, raccords, cases pêchables, Piste
et pente) et une PLANCHE D'ENSEMBLE : les cartes posées à leurs raccords (Route 12 sud → 13 → 14 → 15 →
Parmanie à l'est ; poste 16 → Route 16 ouest → 17 → 18 → Parmanie à l'ouest), les postes en encart et la
légende. Rendu autonome (Pillow), sur le modèle de plan_aplats_j17.py ; ces images annotées ne sont PAS
destinées à Codex.

Usage : python3 -I tools/art/plan_aplats_j22.py
        → docs/design/reference/plans-j22/<grille>-plan-v1.png et j22-plans-v1.png
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
SORTIE = RACINE / "docs" / "design" / "reference" / "plans-j22"
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}

COULEURS = {
	"T": (46, 92, 52), ".": (150, 196, 110), "=": (206, 178, 124), "h": (88, 150, 64), "q": (170, 128, 86),
	"y": (232, 214, 160), "w": (70, 120, 180), "f": (64, 186, 214), "~": (52, 92, 150), "R": (128, 118, 108),
	"c": (240, 236, 222), "x": (60, 120, 60), "n": (150, 104, 60), "P": (176, 140, 98), "m": (196, 120, 96),
	"D": (70, 46, 30), "k": (120, 124, 132), "s": (150, 154, 166), "b": (236, 236, 236), "S": (160, 120, 80),
	"O": (90, 140, 210), "C": (214, 84, 84), "F": (170, 110, 170), "Z": (120, 80, 150), "g": (176, 206, 120),
	"K": (92, 80, 72), "X": (70, 46, 30), "U": (210, 190, 120), "N": (150, 104, 60), "B": (120, 86, 56),
	"J": (60, 60, 70), "V": (20, 20, 24),
}
LEGENDE = [
	("T", "arbres, forêt serrée"), (".", "herbe rase"), ("=", "chemin"), ("h", "hautes herbes"),
	("q", "ponton"), ("y", "sable"), ("w", "eau (non pêchable)"), ("f", "eau PÊCHABLE"), ("~", "mer (décor)"),
	("R", "rochers, falaise"), ("c", "clôture"), ("x", "buissons"), ("k", "PISTE (plat)"),
	("s", "PISTE en PENTE (dérive ↓)"), ("b", "barrière de la Piste"), ("P", "poste"), ("m", "maison"),
	("D", "porte"), ("C", "Centre"), ("O", "Boutique"), ("F", "Salle de réunion"), ("Z", "Arène"),
	("S", "Parc Safari"), ("g", "enclos"),
]
SYMBOLES = [
	((230, 40, 40), "Dresseur et sa vue (I = inévitable)"), ((255, 220, 40), "objet visible (rond) / caché (étoile)"),
	((255, 120, 220), "warp vers une carte"), ((255, 150, 40), "« À venir » (J23 / J24)"),
	((80, 150, 255), "PNJ"), ((190, 90, 230), "Pokémon peint"), ((255, 255, 255), "panneau / jumelles"),
]
GRILLES = ["route_12_sud", "route_13", "route_14", "route_15", "route_15_gate", "route_16_gate", "route_16_west",
	"route_17", "route_18", "route_18_gate", "parmanie"]
TITRES = {
	"route_12_sud": "Route 12 sud (30 × 70)", "route_13": "Route 13 (90 × 27)", "route_14": "Route 14 (30 × 81)",
	"route_15": "Route 15 (90 × 27)", "route_15_gate": "Poste 15 — 1F | 2F (25 × 10)",
	"route_16_gate": "Poste 16 (14 × 10)", "route_16_west": "Route 16 ouest (40 × 27)",
	"route_17": "Route 17 — Piste Cyclable (30 × 150)", "route_18": "Route 18 (75 × 27)",
	"route_18_gate": "Poste 18 (12 × 10)", "parmanie": "Parmanie (60 × 54)",
}


def fonte(t: int, gras: bool = False):
	for chemin in (f"/System/Library/Fonts/Supplemental/Arial{' Bold' if gras else ''}.ttf",
			"/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
		try:
			return ImageFont.truetype(chemin, t)
		except OSError:
			continue
	return ImageFont.load_default(size=t)


def dessiner_carte(img: Image.Image, plan: Plan, ox: int, oy: int, case: int, *, annote: bool = True,
		texte: bool = True) -> None:
	d = ImageDraw.Draw(img, "RGBA")
	for y, row in enumerate(plan.rows):
		for x, ch in enumerate(row):
			x0, y0 = ox + x * case, oy + y * case
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=COULEURS.get(ch, (255, 0, 255)))
			if case >= 6:
				if ch == "f" and (x + y) % 2 == 0:
					d.line([x0 + 1, y0 + case // 2, x0 + case - 2, y0 + case // 2], fill=(220, 250, 255), width=1)
				elif ch == "s":
					cx = x0 + case // 2
					d.line([cx, y0 + 2, cx, y0 + case - 3], fill=(90, 94, 104), width=1)
					d.line([cx - case // 4, y0 + case // 2, cx, y0 + case - 3], fill=(90, 94, 104), width=1)
					d.line([cx + case // 4, y0 + case // 2, cx, y0 + case - 3], fill=(90, 94, 104), width=1)
				elif ch == "T" and case >= 10:
					d.ellipse([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=(36, 76, 42))
				elif ch == "h" and case >= 8:
					d.line([x0 + 2, y0 + case - 2, x0 + case // 2, y0 + 2], fill=(60, 120, 44), width=1)
	if not annote:
		return
	police = fonte(max(9, min(15, case - 1)))
	petite = fonte(max(8, min(13, case - 3)))

	def centre(c):
		return ox + (c[0] + 0.5) * case, oy + (c[1] + 0.5) * case

	def boite(cells, couleur, largeur=2):
		xs = [x for x, _ in cells]
		ys = [y for _, y in cells]
		d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1,
			oy + (max(ys) + 1) * case - 1], outline=couleur, width=largeur)

	def etiquette(c, t, couleur, dy=-0.9):
		if not texte:
			return
		cx, cy = centre(c)
		cy += dy * case
		b = d.textbbox((cx, cy), t, font=petite, anchor="mm")
		d.rectangle([b[0] - 2, b[1] - 1, b[2] + 2, b[3] + 1], fill=(0, 0, 0, 170))
		d.text((cx, cy), t, font=petite, fill=couleur, anchor="mm")

	libres = lambda c: (0 <= c[0] < plan.width and 0 <= c[1] < plan.height  # noqa: E731
		and plan.at(*c) in plan.praticables and not any(p.bloque and c in p.cells for p in plan.positions.values()))
	for p in plan.of_kind("warp"):
		cs = "coming_soon" in p.attrs
		boite(p.cells, (255, 150, 40, 255) if cs else (255, 120, 220, 255), 2 if case >= 8 else 1)
		cible = p.attrs.get("coming_soon") if cs else p.attrs.get("to", "")
		etiquette(p.cells[0], ("À venir : " if cs else "→ ") + cible, (255, 200, 140) if cs else (255, 190, 240))
	for p in plan.of_kind("dresseur"):
		f = FACINGS[p.attrs["facing"]]
		c = p.cells[0]
		for k in range(1, int(p.attrs["sight"]) + 1):
			v = (c[0] + f[0] * k, c[1] + f[1] * k)
			if not libres(v):
				break
			d.rectangle([ox + v[0] * case, oy + v[1] * case, ox + (v[0] + 1) * case - 1, oy + (v[1] + 1) * case - 1],
				fill=(230, 40, 40, 110))
		cx, cy = centre(c)
		r = max(3, case * 0.42)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(230, 40, 40, 255), outline=(0, 0, 0, 255))
		d.line([cx, cy, cx + f[0] * r * 1.4, cy + f[1] * r * 1.4], fill=(255, 255, 255, 255), width=2)
		nom = p.attrs.get("trainer", p.ident).replace("route_", "R")
		etiquette(c, nom + (" (I)" if p.attrs.get("inevitable") == "oui" else ""),
			(255, 120, 120) if p.attrs.get("inevitable") != "oui" else (255, 230, 60))
	for p in plan.of_kind("objet_visible") + plan.of_kind("cache"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.38)
		if p.kind == "cache":
			pts = []
			import math
			for i in range(10):
				a = -math.pi / 2 + i * math.pi / 5
				rr = r if i % 2 == 0 else r * 0.45
				pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
			d.polygon(pts, fill=(255, 220, 40, 255), outline=(0, 0, 0, 255))
		else:
			d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 220, 40, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.attrs.get("item", ""), (255, 235, 120), dy=0.95)
	for p in plan.of_kind("pnj"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.38)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 150, 255, 255), outline=(0, 0, 0, 255))
	for p in plan.of_kind("pokemon"):
		cx, cy = centre(p.cells[0])
		r = max(3, case * 0.42)
		d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(190, 90, 230, 255), outline=(0, 0, 0, 255))
		etiquette(p.cells[0], p.attrs.get("species", p.ident), (230, 190, 255), dy=0.95)
	for p in plan.of_kind("panneau"):
		x0, y0 = ox + p.cells[0][0] * case, oy + p.cells[0][1] * case
		m = max(1, case // 5)
		d.rectangle([x0 + m, y0 + m, x0 + case - 1 - m, y0 + case - 1 - m], fill=(255, 255, 255, 255),
			outline=(60, 40, 20, 255))
	for p in plan.of_kind("repere"):
		if p.attrs.get("role") in ("palier", "regle_piste"):
			boite(p.cells, (255, 255, 255, 200), 1)


def legende(img: Image.Image, x: int, y: int, colonnes: int = 2, t: int = 15) -> int:
	d = ImageDraw.Draw(img, "RGBA")
	police = fonte(t)
	larg = 300
	for i, (ch, nom) in enumerate(LEGENDE):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		d.rectangle([cx, cy, cx + t, cy + t], fill=COULEURS[ch], outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), f"{ch}  {nom}", font=police, fill=(240, 240, 240))
	y += ((len(LEGENDE) + colonnes - 1) // colonnes) * (t + 8) + 8
	for i, (coul, nom) in enumerate(SYMBOLES):
		cx, cy = x + (i % colonnes) * larg, y + (i // colonnes) * (t + 8)
		d.ellipse([cx, cy, cx + t, cy + t], fill=coul, outline=(0, 0, 0))
		d.text((cx + t + 8, cy - 1), nom, font=police, fill=(240, 240, 240))
	return y + ((len(SYMBOLES) + colonnes - 1) // colonnes) * (t + 8)


def image_grille(nom: str) -> Path:
	plan = lire(PLANS / f"{nom}.txt")
	case = max(8, min(36, int(1700 / max(plan.width, plan.height))))
	marge, haut, bas = 40, 56, 230
	w = max(plan.width * case + 2 * marge, 640)
	img = Image.new("RGB", (w, plan.height * case + haut + bas), (28, 30, 34))
	ox = (w - plan.width * case) // 2
	dessiner_carte(img, plan, ox, haut, case)
	d = ImageDraw.Draw(img)
	d.text((ox, 14), f"{TITRES[nom]} — tools/plans/{nom}.txt", font=fonte(22, True), fill=(255, 255, 255))
	petite = fonte(11)
	pas = 5 if case >= 14 else 10
	for x in range(0, plan.width, pas):
		d.text((ox + (x + 0.5) * case, haut - 8), str(x), font=petite, fill=(200, 200, 200), anchor="mm")
	for y in range(0, plan.height, pas):
		d.text((ox - 14, haut + (y + 0.5) * case), str(y), font=petite, fill=(200, 200, 200), anchor="mm")
	legende(img, 20, haut + plan.height * case + 16, colonnes=max(2, min(4, w // 320)), t=13)
	SORTIE.mkdir(parents=True, exist_ok=True)
	sortie = SORTIE / f"{nom.replace('_', '-')}-plan-v1.png"
	img.save(sortie)
	return sortie


# Planche d'ensemble : origine de chaque carte en cases « monde » (raccords alignés).
POSE = {"route_12_sud": (0, 0), "route_13": (-90, 46), "route_14": (-120, 46), "route_15": (-210, 101),
	"parmanie": (-270, 89), "route_18": (-345, 101), "route_17": (-345, -49), "route_16_west": (-345, -76)}
VOISINES = {"Route 12 nord (J21, 39 × 102)": ((0, -102), (39, 102)), "Route 16 est (J21, 44 × 28)": ((-296, -77), (44, 28))}


def planche() -> Path:
	case = 5
	xs = [x for x, _ in POSE.values()] + [v[0][0] for v in VOISINES.values()]
	ys = [y for _, y in POSE.values()] + [v[0][1] for v in VOISINES.values()]
	plans = {n: lire(PLANS / f"{n}.txt") for n in GRILLES}
	x1 = max(max(POSE[n][0] + plans[n].width for n in POSE), max(v[0][0] + v[1][0] for v in VOISINES.values()))
	y1 = max(max(POSE[n][1] + plans[n].height for n in POSE), max(v[0][1] + v[1][1] for v in VOISINES.values()))
	x0, y0 = min(xs), min(ys)
	marge, panneau = 60, 760
	W = (x1 - x0) * case + 2 * marge + panneau
	H = max((y1 - y0) * case + 2 * marge + 60, 1500)
	img = Image.new("RGB", (W, H), (24, 26, 30))
	d = ImageDraw.Draw(img, "RGBA")
	titre = fonte(30, True)
	d.text((marge, 18), "Jalon 22 — les deux chemins vers Parmanie : grilles v1 (T6, à valider)", font=titre,
		fill=(255, 255, 255))
	ox, oy = marge - x0 * case, marge + 50 - y0 * case
	for nom, ((vx, vy), (vw, vh)) in VOISINES.items():
		d.rectangle([ox + vx * case, oy + vy * case, ox + (vx + vw) * case, oy + (vy + vh) * case],
			fill=(60, 62, 70), outline=(140, 140, 150), width=2)
		d.text((ox + (vx + vw / 2) * case, oy + (vy + vh / 2) * case), nom, font=fonte(16), fill=(210, 210, 220),
			anchor="mm")
	for nom, (px, py) in POSE.items():
		dessiner_carte(img, plans[nom], ox + px * case, oy + py * case, case, texte=False)
		d.rectangle([ox + px * case - 1, oy + py * case - 1, ox + (px + plans[nom].width) * case,
			oy + (py + plans[nom].height) * case], outline=(255, 255, 255), width=2)
	noms = {"route_12_sud": ("Route 12 sud", (15, 35)), "route_13": ("Route 13", (45, 24)),
		"route_14": ("Route 14", (15, 76)), "route_15": ("Route 15", (60, 24)), "parmanie": ("PARMANIE", (30, 21)),
		"route_18": ("Route 18", (55, 25)), "route_17": ("Route 17 — Piste", (22, 60)),
		"route_16_west": ("Route 16 ouest", (20, -2))}
	for n, (t, (cx, cy)) in noms.items():
		px, py = POSE[n]
		b = d.textbbox((ox + (px + cx) * case, oy + (py + cy) * case), t, font=fonte(20, True), anchor="mm")
		d.rectangle([b[0] - 4, b[1] - 3, b[2] + 4, b[3] + 3], fill=(0, 0, 0, 190))
		d.text((ox + (px + cx) * case, oy + (py + cy) * case), t, font=fonte(20, True), fill=(255, 255, 255), anchor="mm")
	# chemins (traits) : est en bleu, ouest en orange
	def pt(n, c):
		return ox + (POSE[n][0] + c[0] + 0.5) * case, oy + (POSE[n][1] + c[1] + 0.5) * case
	est = [pt("route_12_sud", (25, 0)), pt("route_12_sud", (25, 62)), pt("route_13", (60, 16)), pt("route_13", (5, 9)),
		pt("route_14", (19, 9)), pt("route_14", (6, 67)), pt("route_15", (70, 12)), pt("route_15", (5, 12)),
		pt("parmanie", (55, 24))]
	ouest = [pt("route_16_west", (35, 18)), pt("route_16_west", (13, 24)), pt("route_17", (13, 75)),
		pt("route_17", (13, 148)), pt("route_18", (13, 10)), pt("route_18", (60, 12)), pt("parmanie", (5, 24))]
	d.line(est, fill=(80, 170, 255, 230), width=4)
	d.line(ouest, fill=(255, 150, 40, 230), width=4)
	lien = [ox + (-296 + 15) * case, oy + (-77 + 21) * case]
	d.line([tuple(lien), pt("route_16_west", (35, 18))], fill=(255, 150, 40, 230), width=4)
	# panneau de droite : légende, postes en encart, lecture
	px0 = W - panneau + 20
	y = 80
	d.text((px0, y), "Légende", font=fonte(22, True), fill=(255, 255, 255))
	y = legende(img, px0, y + 34, colonnes=2, t=15) + 16
	d.line([(px0, y), (px0 + 60, y)], fill=(80, 170, 255), width=4)
	d.text((px0 + 70, y - 9), "chemin EST à pied : R12 sud → R13 → R14 → R15 → Parmanie", font=fonte(15),
		fill=(230, 230, 230))
	y += 24
	d.line([(px0, y), (px0 + 60, y)], fill=(255, 150, 40), width=4)
	d.text((px0 + 70, y - 9), "chemin OUEST à vélo : poste 16 → R16 ouest → R17 → R18 → Parmanie", font=fonte(15),
		fill=(230, 230, 230))
	y += 36
	for nom in ("route_16_gate", "route_15_gate", "route_18_gate"):
		plan = plans[nom]
		c = 16 if plan.width <= 14 else 13
		d.text((px0, y), TITRES[nom], font=fonte(17, True), fill=(255, 255, 255))
		dessiner_carte(img, plan, px0, y + 26, c, texte=False)
		y += 26 + plan.height * c + 18
	note = ["Chaque route : au plus UN Dresseur inévitable (I),", "un chemin évite tous les autres.",
		"Pente (s) sur la Route 17 seulement, 3 paliers plats (k).", "Aucune eau pêchable (f) au contact de la Piste.",
		"Contrôle : python3 -I tools/art/plan_check_j22.py"]
	for t in note:
		d.text((px0, y), t, font=fonte(15), fill=(220, 220, 220))
		y += 22
	sortie = SORTIE / "j22-plans-v1.png"
	img.save(sortie)
	return sortie


def main() -> int:
	for nom in GRILLES:
		print(image_grille(nom))
	print(planche())
	return 0


if __name__ == "__main__":
	sys.exit(main())
