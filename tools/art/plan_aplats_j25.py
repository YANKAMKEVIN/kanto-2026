#!/usr/bin/env python3
"""Plans en aplats du jalon 25 (dossier 28) : Manoir Pokémon (4 étages), Arène de Cramois'Île,
réserve du Musée d'Argenta (le Laboratoire est au J24), pour les vues générales peintes.

Grilles : `tools/plans/manoir_*.txt`, `cramois_*.txt`, `argenta_musee_reserve.txt`. Script séparé
de `plan_aplats.py` (partagé avec les autres jalons, règle d'ancienneté) ; il en reprend
quelques fonctions. Sorties dans `build/art/` : image nette (jointe à Codex) et version
annotée `_annote.png` (relecture seulement, JAMAIS jointe à Codex).

État dessiné : interrupteur sur ARRÊT (état d'arrivée) : grilles du jeu A fermées, jeu B ouvertes.

Usage : python3 tools/art/plan_aplats_j25.py [manoir|arene|reserve|tout]   (défaut : tout)
"""
from __future__ import annotations

import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import plan_aplats as pa  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
SORTIE = RACINE / "build" / "art"

# --- Manoir : bois brûlé, parquet chaud, lumière dorée par les fenêtres --------------------------
M_FOND = (22, 18, 16)                # vide entre les étages
M_ETAGES = {
	# étage : (mur, parquet)
	"1F": ((70, 52, 44), (168, 128, 92)),
	"2F": ((74, 56, 46), (174, 134, 96)),
	"3F": ((78, 60, 50), (180, 140, 100)),
	"B1F": ((56, 48, 46), (138, 118, 100)),   # sous-sol : plus froid, carrelage de labo usé
}
M_LATTE = 0.12                       # joints du parquet
M_GRILLE = (60, 62, 70)              # grille fermée (fer)
M_GRILLE_OUVERTE = (110, 104, 96)    # rail au sol d'une grille ouverte
M_STATUE = (196, 192, 184)
M_STATUE_BORD = (70, 66, 62)
M_PUPITRE = (110, 74, 46)
M_PAGE = (240, 232, 210)
M_TROU = (12, 10, 10)
M_TROU_BORD = (96, 70, 50)
M_MONTE = (206, 176, 136)
M_DESCEND = (40, 30, 26)
M_SORTIE = (226, 200, 150)
M_SUIE = (52, 40, 34)
M_CLE = (226, 186, 70)
M_MEUBLE = (104, 70, 44)             # petit bloc isolé dans une pièce : mobilier lourd (RB)
M_NOMS = {"manoir_1f": "1F", "manoir_2f": "2F", "manoir_3f": "3F", "manoir_b1f": "B1F"}
# Disposition 2 × 2 (paysage 1536 × 1024) : en haut 2F | 3F, en bas 1F | B1F.
M_DISPO = [("manoir_2f", 0, 0), ("manoir_3f", 1, 0), ("manoir_1f", 0, 1), ("manoir_b1f", 1, 1)]


def _ball(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, haut=pa.BALL_ROUGE) -> None:
	d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=haut)
	d.pieslice([cx - r, cy - r, cx + r, cy + r], 0, 180, fill=pa.BLANC)
	d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=pa.BALL_BORD, width=1)


def _meubles_et_vide(plan: Plan) -> tuple[set, set]:
	"""Cases « # » à peindre en mobilier (composante de murs de ≤ 4 cases entourée de sol) et cases
	de vide (aucune case praticable à moins de 2 cases : hors du bâtiment)."""
	murs = set(plan.cells_of("#"))
	vus, meubles = set(), set()
	for c in murs:
		if c in vus:
			continue
		comp, pile = [], [c]
		vus.add(c)
		while pile:
			x, y = pile.pop()
			comp.append((x, y))
			for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
				if n in murs and n not in vus:
					vus.add(n)
					pile.append(n)
		bord = any(x in (0, plan.width - 1) or y in (0, plan.height - 1) for x, y in comp)
		if len(comp) <= 4 and not bord:
			meubles.update(comp)
	vide = {(x, y) for x, y in murs if all(
		not (0 <= x + dx < plan.width and 0 <= y + dy < plan.height) or plan.at(x + dx, y + dy) == "#"
		for dx in range(-2, 3) for dy in range(-2, 3))}
	return meubles, vide


def _peindre_manoir(d: ImageDraw.ImageDraw, plan: Plan, etage: str, ox: int, oy: int, case: int) -> None:
	mur, sol = M_ETAGES[etage]
	meubles, vide = _meubles_et_vide(plan)

	def coin(x: int, y: int) -> tuple[int, int]:
		return ox + x * case, oy + y * case

	def centre(x: int, y: int) -> tuple[float, float]:
		return ox + (x + 0.5) * case, oy + (y + 0.5) * case

	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			if c == "#":
				if (x, y) in vide:
					continue
				if (x, y) in meubles:
					d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=sol)
					d.rounded_rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], radius=max(1, case // 5),
						fill=M_MEUBLE)
					continue
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=mur)
				continue
			fond = sol
			if c == "E":
				fond = M_SORTIE
			latte = pa._melange(fond, (0, 0, 0), M_LATTE)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=latte)
			d.rectangle([x0, y0 + 1, x0 + case - 1, y0 + case - 2], fill=fond)
	for y, row in enumerate(plan.rows):
		for x, c in enumerate(row):
			x0, y0 = coin(x, y)
			cx, cy = centre(x, y)
			r = case / 2
			if c == "a":     # grille fermée (état ARRÊT)
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=pa._melange(sol, M_GRILLE, 0.25))
				for i in range(1, 4):
					xi = x0 + i * case / 4
					d.line([xi, y0, xi, y0 + case - 1], fill=M_GRILLE, width=max(2, case // 8))
				d.line([x0, y0 + 2, x0 + case - 1, y0 + 2], fill=M_GRILLE, width=max(2, case // 8))
			elif c == "b":   # grille ouverte : rail au sol
				d.line([x0, cy, x0 + case - 1, cy], fill=M_GRILLE_OUVERTE, width=max(1, case // 10))
			elif c == "O":
				d.ellipse([x0 + 1, y0 + 2, x0 + case - 2, y0 + case - 2], fill=M_TROU, outline=M_TROU_BORD,
					width=max(1, case // 8))
			elif c == "T":
				d.rectangle([x0 + 1, y0 + case * 0.55, x0 + case - 2, y0 + case - 1], fill=M_STATUE_BORD)
				d.ellipse([cx - r * 0.55, y0 + 1, cx + r * 0.55, y0 + case * 0.7], fill=M_STATUE,
					outline=M_STATUE_BORD)
			elif c == "P":
				d.rectangle([x0 + 1, y0 + 2, x0 + case - 2, y0 + case - 2], fill=M_PUPITRE)
				d.rectangle([x0 + case * 0.2, y0 + case * 0.25, x0 + case * 0.8, y0 + case * 0.6], fill=M_PAGE)
			elif c in "UV":
				for i in range(4):
					t = i / 3
					teinte = (pa._melange(M_MONTE, sol, 0.6 * (1 - t)) if c == "U"
						else pa._melange(sol, M_DESCEND, 0.35 + 0.65 * t))
					ya = y0 + 1 + i * (case - 2) / 4
					d.rectangle([x0 + 1, ya, x0 + case - 2, ya + (case - 2) / 4 - 1], fill=teinte)
	for p in plan.of_kind("objet_visible"):
		cx, cy = centre(*p.cells[0])
		_ball(d, cx, cy, max(3, case * 0.3), M_CLE if p.attrs.get("item") == "secret_key" else pa.BALL_ROUGE)


def dessiner_manoir(sortie: Path, annote: bool = False) -> Path:
	plans = {g: lire(PLANS / f"{g}.txt") for g, _, _ in M_DISPO}
	largeur, hauteur = 1536, 1024
	ecart = 2                                         # cases de vide entre deux étages
	case = min((largeur - 40) // (60 + ecart), (hauteur - 40) // (56 + ecart))
	img = Image.new("RGB", (largeur, hauteur), M_FOND)
	d = ImageDraw.Draw(img)
	larg_col = 30 * case
	x_cols = [(largeur - 2 * larg_col - ecart * case) // 2, (largeur - 2 * larg_col - ecart * case) // 2 + larg_col + ecart * case]
	haut_rang = [28 * case, 28 * case]
	y_rangs = [(hauteur - sum(haut_rang) - ecart * case) // 2]
	y_rangs.append(y_rangs[0] + haut_rang[0] + ecart * case)
	places = {}
	for g, col, rang in M_DISPO:
		plan = plans[g]
		ox = x_cols[col]
		oy = y_rangs[rang] + (haut_rang[rang] - plan.height * case) // 2
		_peindre_manoir(d, plan, M_NOMS[g], ox, oy, case)
		places[g] = (ox, oy)
	img.save(sortie)
	if annote:
		_annoter(img, plans, places, case, sortie.with_name(sortie.stem + "_annote.png"))
	return sortie


def _annoter(img: Image.Image, plans: dict[str, Plan], places: dict[str, tuple[int, int]], case: int,
		sortie: Path) -> None:
	"""Relecture : étages, escaliers (paire), trous (→ arrivée), statues, journaux, Dresseurs, objets cachés."""
	calque = img.convert("RGBA")
	d = ImageDraw.Draw(calque)
	f, g = pa._fonte(11), pa._fonte(20)

	def lab(x, y, t, coul=(255, 255, 255), fonte=f):
		b = d.textbbox((x, y), t, font=fonte, anchor="mm")
		d.rectangle([b[0] - 2, b[1] - 1, b[2] + 2, b[3] + 1], fill=(0, 0, 0, 190))
		d.text((x, y), t, font=fonte, fill=coul, anchor="mm")

	for nom, plan in plans.items():
		ox, oy = places[nom]

		def c(p):
			x, y = p.cells[0]
			return ox + (x + 0.5) * case, oy + (y + 0.5) * case
		lab(ox + 30, oy - 8 if oy > 12 else oy + 8, M_NOMS.get(nom, nom), (255, 230, 150), g)
		for p in plan.of_kind("escalier"):
			lab(*c(p), f"{p.attrs['paire']}{'↑' if p.attrs['sens'] == 'monte' else '↓'}", (180, 220, 255))
		for p in plan.of_kind("trou"):
			lab(*c(p), "→" + p.attrs["vers"].rsplit("_", 1)[1].upper(), (255, 120, 120))
		for p in plan.of_kind("statue"):
			lab(*c(p), "S", (255, 255, 120))
		for p in plan.of_kind("journal"):
			lab(*c(p), p.ident.replace("journal_", "J"), (200, 255, 200))
		for p in plan.of_kind("dresseur"):
			lab(*c(p), p.ident.rsplit("_", 2)[-2][:3] + f" v{p.attrs.get('sight')}", (255, 170, 90))
		for p in plan.of_kind("objet_cache"):
			lab(*c(p), "?", (220, 160, 255))
	calque.convert("RGB").save(sortie)


# --- Arène : roche volcanique, braises, herses ------------------------------------------------
A_FOND = (26, 18, 16)
A_MUR = (58, 40, 36)
A_SOL = (150, 112, 88)
A_BRAISE = (232, 110, 40)
A_HERSE = (92, 70, 64)
A_MACHINE = (90, 120, 150)
A_ECRAN = (170, 220, 240)
A_SORTIE = (226, 200, 150)


def dessiner_arene(sortie: Path, annote: bool = False) -> Path:
	plan = lire(PLANS / "cramois_arene.txt")
	taille = 1024
	case = (taille - 64) // max(plan.width, plan.height)
	img = Image.new("RGB", (taille, taille), A_FOND)
	d = ImageDraw.Draw(img)
	ox, oy = (taille - plan.width * case) // 2, (taille - plan.height * case) // 2
	for y, row in enumerate(plan.rows):
		for x, ch in enumerate(row):
			x0, y0 = ox + x * case, oy + y * case
			if ch == "#":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=A_MUR)
				continue
			fond = A_SORTIE if ch == "E" else A_SOL
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=pa._melange(fond, (0, 0, 0), 0.1))
			d.rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=fond)
			if ch == "p":
				for i in range(1, 4):
					xi = x0 + i * case / 4
					d.line([xi, y0, xi, y0 + case - 1], fill=A_HERSE, width=max(3, case // 8))
			elif ch == "Q":
				d.rectangle([x0 + 3, y0 + 3, x0 + case - 4, y0 + case - 3], fill=A_MACHINE)
				d.rectangle([x0 + case * 0.2, y0 + case * 0.15, x0 + case * 0.8, y0 + case * 0.5], fill=A_ECRAN)
	img.save(sortie)
	if annote:
		calque = img.copy()
		dd = ImageDraw.Draw(calque)
		f = pa._fonte(14)
		for p in plan.positions.values():
			x, y = p.cells[0]
			t = {"herse": "P", "quiz": "Q", "dresseur": "D", "champion": "AUGUSTE"}.get(p.kind)
			if not t:
				continue
			n = p.ident.rsplit("_", 1)[-1] if p.kind != "champion" else ""
			dd.text((ox + (x + 0.5) * case, oy + (y + 0.5) * case), t + n, font=f, fill=(255, 255, 255),
				anchor="mm", stroke_width=2, stroke_fill=(0, 0, 0))
		calque.save(sortie.with_name(sortie.stem + "_annote.png"))
	return sortie


# --- Laboratoire et réserve du Musée : intérieurs clairs -----------------------------------------
L_FOND = (30, 32, 38)
L_MUR = (120, 132, 146)
L_SOL = (214, 218, 222)
L_MEUBLE = (150, 160, 170)
L_PLANTE = (70, 140, 80)
L_PORTE = (96, 110, 128)
L_SORTIE = (226, 200, 150)
L_MACHINE = (110, 170, 190)
L_PC = (70, 90, 120)
R_SOL = (196, 176, 146)              # réserve du Musée : parquet ancien
R_MUR = (122, 98, 76)
R_VITRINE = (226, 196, 110)
R_CAISSE = (140, 104, 66)


def _peindre_interieur(d, plan: Plan, ox: int, oy: int, case: int, sol, mur) -> None:
	couleurs = {"t": L_MEUBLE, "x": L_PLANTE, "c": L_PC, "M": L_MACHINE, "V": R_VITRINE, "r": R_CAISSE}
	for y, row in enumerate(plan.rows):
		for x, ch in enumerate(row):
			x0, y0 = ox + x * case, oy + y * case
			if ch == "K":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=mur)
				continue
			fond = {"X": L_SORTIE, "D": L_PORTE}.get(ch, sol)
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=pa._melange(fond, (0, 0, 0), 0.08))
			d.rectangle([x0 + 1, y0 + 1, x0 + case - 2, y0 + case - 2], fill=fond)
			if ch in couleurs:
				d.rounded_rectangle([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], radius=case // 6,
					fill=couleurs[ch])


def dessiner_reserve(sortie: Path) -> Path:
	"""Réserve du Musée d'Argenta (le Laboratoire de Cramois'Île appartient au J24)."""
	reserve = lire(PLANS / "argenta_musee_reserve.txt")
	case = 56
	img = Image.new("RGB", (1024, 1024), L_FOND)
	_peindre_interieur(ImageDraw.Draw(img), reserve, (1024 - 15 * case) // 2, (1024 - 10 * case) // 2,
		case, R_SOL, R_MUR)
	img.save(sortie)
	return sortie


if __name__ == "__main__":
	quoi = sys.argv[1] if len(sys.argv) > 1 else "tout"
	SORTIE.mkdir(parents=True, exist_ok=True)
	if quoi in ("manoir", "tout"):
		print(dessiner_manoir(SORTIE / "PLAN_MANOIR_v1.png", annote=True))
	if quoi in ("arene", "tout"):
		print(dessiner_arene(SORTIE / "PLAN_CRAMOIS_ARENE_v1.png", annote=True))
	if quoi in ("reserve", "tout"):
		print(dessiner_reserve(SORTIE / "PLAN_ARGENTA_RESERVE_v1.png"))
