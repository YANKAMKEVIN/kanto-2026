#!/usr/bin/env python3
"""Plan en aplats de la Centrale (jalon 32, lot 32G), pour la relecture de Kevin sur téléphone.

Lit `tools/plans/power_plant.txt` (proposition RB 1:1) et la Route 10 (`tools/plans/route_10.txt`)
pour l'encart du raccord proposé (Surf sur la rivière, quai, porte). Rendu autonome (Pillow), sur le
modèle de `plan_aplats_j22.py` ; image annotée, PAS destinée à Codex.

Usage : python3 tools/art/plan_aplats_power_plant.py → docs/design/reference/centrale-plan-v1.png
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "docs/design/reference/centrale-plan-v1.png"
CASE = 30
MARGE = 40
FOND = (246, 242, 232)
ENCRE = (34, 34, 40)

SOL = (214, 206, 182)
MUR = (78, 82, 96)
COULEURS = {"#": MUR, ".": SOL, "E": (196, 120, 60), "O": (196, 120, 60), "x": (120, 124, 136)}
R10 = {"K": (120, 104, 92), "T": (46, 92, 52), ".": (150, 196, 110), "=": (206, 178, 124),
	"h": (88, 150, 64), "w": (70, 120, 180), "E": (90, 90, 110), "R": (128, 118, 108),
	"C": (214, 84, 84), "D": (70, 46, 30), "Q": (60, 50, 44), "o": (190, 170, 130)}


def fonte(t: int, gras: bool = False):
	for chemin in (f"/System/Library/Fonts/Supplemental/Arial{' Bold' if gras else ''}.ttf",
			"/System/Library/Fonts/Supplemental/Arial.ttf", "DejaVuSans.ttf"):
		try:
			return ImageFont.truetype(chemin, t)
		except OSError:
			continue
	return ImageFont.load_default(size=t)


def pastille(d: ImageDraw.ImageDraw, x0: int, y0: int, c: int, couleur, texte: str, f) -> None:
	d.ellipse([x0 + 3, y0 + 3, x0 + c - 3, y0 + c - 3], fill=couleur, outline=ENCRE, width=2)
	d.text((x0 + c / 2, y0 + c / 2), texte, fill=(255, 255, 255), font=f, anchor="mm")


def main() -> int:
	plan = lire(RACINE / "tools/plans/power_plant.txt")
	route = lire(RACINE / "tools/plans/route_10.txt")
	W, H = plan.width * CASE, plan.height * CASE
	encart_cases = (18, 26)    # Route 10 nord : x 16..33, y 0..25
	CE = 22
	largeur = MARGE * 3 + W + encart_cases[0] * CE
	hauteur = MARGE * 2 + 110 + max(H, encart_cases[1] * CE + 40) + 380
	img = Image.new("RGB", (largeur, hauteur), FOND)
	d = ImageDraw.Draw(img)
	titre, f26, f20, f17, f14 = fonte(40, True), fonte(26, True), fonte(21), fonte(17, True), fonte(15)
	d.text((MARGE, MARGE), "Centrale (Power Plant) — proposition de grille v1", fill=ENCRE, font=titre)
	d.text((MARGE, MARGE + 52), "Relevé 1:1 de Rouge/Bleu (pokered) · 40 × 36 cases · "
		"À VALIDER PAR KEVIN avant toute construction", fill=(150, 40, 40), font=f20)
	ox, oy = MARGE, MARGE + 110
	for y in range(plan.height):
		for x in range(plan.width):
			c = plan.at(x, y)
			x0, y0 = ox + x * CASE, oy + y * CASE
			d.rectangle([x0, y0, x0 + CASE - 1, y0 + CASE - 1], fill=COULEURS.get(c, MUR))
			if c == "x":
				d.text((x0 + CASE / 2, y0 + CASE / 2), "?", fill=(255, 255, 255), font=f17, anchor="mm")
	for i in range(0, plan.width + 1, 5):
		d.text((ox + i * CASE, oy - 6), str(i), fill=ENCRE, font=f14, anchor="mb")
	for j in range(0, plan.height + 1, 5):
		d.text((ox - 6, oy + j * CASE), str(j), fill=ENCRE, font=f14, anchor="rm")
	for p in plan.positions.values():
		(x, y) = p.cells[0]
		x0, y0 = ox + x * CASE, oy + y * CASE
		if p.kind == "rencontre" and p.attrs.get("espece") == "zapdos":
			d.rectangle([x0 - 3, y0 - 3, x0 + CASE + 2, y0 + CASE + 2], outline=(230, 190, 20), width=4)
			pastille(d, x0, y0, CASE, (230, 190, 20), "Z", f17)
			d.text((x0 + CASE + 6, y0 + CASE / 2), "Électhor N50", fill=ENCRE, font=f17, anchor="lm")
		elif p.kind == "rencontre":
			pastille(d, x0, y0, CASE, (200, 60, 60), "V" if p.attrs["espece"] == "voltorb" else "É", f14)
		elif p.kind == "objet":
			pastille(d, x0, y0, CASE, (60, 120, 200), "o", f14)
		elif p.kind == "objet_cache":
			d.rectangle([x0 + 8, y0 + 8, x0 + CASE - 9, y0 + CASE - 9], outline=(60, 120, 200), width=3)
		elif p.kind == "spawn":
			for (sx, sy) in p.cells:
				d.text((ox + sx * CASE + CASE / 2, oy + sy * CASE + CASE / 2), "▲", fill=(196, 120, 60),
					font=f17, anchor="mm")
	d.text((ox + 4 * CASE, oy + H + 6), "Entrée sud ← Route 10", fill=(160, 80, 30), font=f17)
	d.text((ox, oy + 11 * CASE - 26), "Porte ouest", fill=(160, 80, 30), font=f14)

	# Encart : raccord proposé sur la Route 10 (rien n'est construit).
	ex, ey = ox + W + MARGE, oy
	d.text((ex, ey - 34), "Accès proposé (Route 10, nord)", fill=ENCRE, font=f26)
	for yy in range(encart_cases[1]):
		for xx in range(encart_cases[0]):
			x, y = 16 + xx, yy
			c = route.at(x, y)
			col = R10.get(c, (90, 90, 90))
			if c == "w" and y <= 22:
				col = (64, 150, 214)                      # eau surfable proposée
			if (x, y) in {(29, 10), (30, 10), (31, 10)}:
				col = (232, 214, 160)                     # quai proposé
			if (x, y) == (30, 9):
				col = (196, 120, 60)                      # porte proposée
			d.rectangle([ex + xx * CE, ey + yy * CE, ex + xx * CE + CE - 1, ey + yy * CE + CE - 1], fill=col)
	def ec(x, y):
		return ex + (x - 16) * CE + CE / 2, ey + y * CE + CE / 2
	d.text(ec(31, 6), "Centrale", fill=(255, 255, 255), font=f14, anchor="mm")
	d.text(ec(30, 9), "P", fill=(255, 255, 255), font=f17, anchor="mm")
	d.text(ec(21, 16), "Belvédère", fill=ENCRE, font=f14, anchor="mm")
	d.text(ec(21.5, 19.5), "Ronflex N-18", fill=(150, 40, 40), font=f14, anchor="mm")
	fx, fy = ec(23, 15)
	tx, ty = ec(28, 11)
	d.line([fx, fy, ec(26, 15)[0], fy, ec(26, 11)[0], ty, tx, ty], fill=(255, 255, 255), width=4)
	d.text((ex, ey + encart_cases[1] * CE + 8), "Surf depuis le belvédère (23, 12..18) → quai\n"
		"(29..31, 10) → porte P (30, 9) ↑", fill=ENCRE, font=f17)

	# Légende.
	ly = oy + max(H, encart_cases[1] * CE + 40) + 50
	lignes = [
		((MUR, ""), "Mur, cloison, machine (bloqué)"), ((SOL, ""), "Sol de l'usine (praticable)"),
		(((196, 120, 60), ""), "Portes : sud (entrée) et ouest, vers la Route 10"),
		(((120, 124, 136), "?"), "Objet caché dans une machine (pris depuis la case voisine encadrée)"),
		(((230, 190, 20), "Z"), "Électhor N50 (4, 9), une seule rencontre (N-17 : revient après la Ligue)"),
		(((200, 60, 60), "V"), "Fausse Poké Ball : Voltorbe N40 (×6) ou Électrode N43 (É, ×2), RB"),
		(((60, 120, 200), "o"), "Objets RB : PV Plus, Super Bonbon, Carbone, CT25 Fatal-Foudre, CT33 Protection"),
		(((64, 150, 214), ""), "Encart : rivière de la Route 10 rendue surfable (proposition)"),
	]
	for i, ((couleur, lettre), texte) in enumerate(lignes):
		y0 = ly + i * 40
		d.rectangle([MARGE, y0, MARGE + 30, y0 + 30], fill=couleur, outline=ENCRE)
		if lettre:
			d.text((MARGE + 15, y0 + 15), lettre, fill=(255, 255, 255), font=f17, anchor="mm")
		d.text((MARGE + 44, y0 + 15), texte, fill=ENCRE, font=f20, anchor="lm")
	d.text((MARGE, ly + len(lignes) * 40 + 10), "Rencontres : Voltorbe, Magnéti, Pikachu, Magnéton, "
		"Élektek et Raichu (union Rouge + Bleu) · aucun Dresseur · entrée → Électhor : 154 pas",
		fill=ENCRE, font=f17)
	SORTIE.parent.mkdir(parents=True, exist_ok=True)
	img.save(SORTIE, optimize=True)
	print(f"{SORTIE.relative_to(RACINE)} ({img.width} × {img.height})")
	return 0


if __name__ == "__main__":
	sys.exit(main())
