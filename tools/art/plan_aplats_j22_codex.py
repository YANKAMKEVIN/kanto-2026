"""Plans en aplats SANS annotation (pour Codex) des grilles ouest du J22. Usage: python3 plans_codex.py RACINE SORTIE"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw
R = Path(sys.argv[1]); OUT = Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "tools/art"))
from plan_grille import lire
import plan_aplats_j22 as pj
C = dict(pj.COULEURS)
C.update({"m": (200, 196, 186), "P": (214, 206, 190), "O": (236, 232, 222), "C": (236, 232, 222),
	"F": (232, 222, 200), "Z": (200, 196, 190), "S": (214, 196, 160), "K": (150, 132, 112), "X": (90, 60, 40),
	"g": (196, 186, 140)})
TOITS = {"m": (176, 86, 62), "P": (84, 100, 130), "O": (60, 110, 190), "C": (200, 60, 50), "F": (70, 140, 112),
	"Z": (96, 70, 120), "S": (120, 140, 70)}
FORET = (46, 92, 52)

def rendre(nom, rows_range=None, taille=None):
	plan = lire(R / "tools/plans" / f"{nom}.txt")
	rows = plan.rows if rows_range is None else plan.rows[rows_range[0]:rows_range[1]]
	y_off = 0 if rows_range is None else rows_range[0]
	w, h = len(rows[0]), len(rows)
	if taille is None:
		taille = (1536, 1024) if w >= h else (1024, 1536)
	case = int(min(taille[0] / w, taille[1] / h))
	img = Image.new("RGB", taille, FORET if nom not in ("route_16_gate", "route_18_gate") else (40, 34, 30))
	ox, oy = (taille[0] - w * case) // 2, (taille[1] - h * case) // 2
	d = ImageDraw.Draw(img)
	interieur = nom.endswith("_gate")
	panneaux = {c for p in plan.of_kind("panneau") for c in p.cells}
	def at(x, y):
		return rows[y][x] if 0 <= y < h and 0 <= x < w else None
	for y, row in enumerate(rows):
		for x, ch in enumerate(row):
			x0, y0 = ox + x * case, oy + y * case
			if ch == "D":
				voisin = next((at(x + dx, y + dy) for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)) if at(x + dx, y + dy) in TOITS), None)
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=C.get(voisin, C["m"]))
				d.rectangle([x0 + case // 6, y0 + case // 5, x0 + case - case // 6 - 1, y0 + case - 1], fill=(80, 50, 30))
				continue
			fond = C.get(ch, (255, 0, 255))
			if interieur and ch in ".x":
				fond = (214, 190, 146)
			if ch in "nx" or (x, y + y_off) in panneaux:
				fond = C["."] if ch != "n" else C["k"]
			d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=fond)
			if ch == "T":
				d.ellipse([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=(36, 76, 42))
			elif ch == "h":
				for k in range(2):
					d.line([x0 + 3 + k * case // 2, y0 + case - 3, x0 + case // 4 + k * case // 2, y0 + 3], fill=(60, 120, 44), width=2)
			elif ch == "s":
				cx = x0 + case // 2
				d.line([cx - case // 4, y0 + case // 3, cx, y0 + case * 2 // 3, cx + case // 4, y0 + case // 3], fill=(110, 114, 124), width=2)
			elif ch == "x" and interieur:
				d.ellipse([x0 + 8, y0 + 8, x0 + case - 9, y0 + case - 9], fill=(60, 130, 60), outline=(30, 70, 30))
			elif ch == "x":
				d.ellipse([x0 + 2, y0 + 2, x0 + case - 3, y0 + case - 3], fill=(60, 120, 60), outline=(30, 70, 30))
			elif ch == "n":
				d.rectangle([x0 + 2, y0 + case // 3, x0 + case - 3, y0 + case * 2 // 3], fill=(150, 104, 60))
			elif ch == "c":
				d.rectangle([x0, y0, x0 + case - 1, y0 + case - 1], fill=C["."])
				d.rectangle([x0, y0 + case // 2 - 2, x0 + case - 1, y0 + case // 2 + 2], fill=(240, 236, 222))
				if at(x, y - 1) == "c" or at(x, y + 1) == "c":
					d.rectangle([x0 + case // 2 - 2, y0, x0 + case // 2 + 2, y0 + case - 1], fill=(240, 236, 222))
				if not (at(x - 1, y) == "c" or at(x + 1, y) == "c"):
					d.rectangle([x0, y0 + case // 2 - 2, x0 + case - 1, y0 + case // 2 + 2], fill=C["."])
			elif ch == "f" and (x + y) % 2 == 0:
				d.line([x0 + 3, y0 + case // 2, x0 + case - 4, y0 + case // 2], fill=(200, 236, 250), width=1)
			if (x, y + y_off) in panneaux:
				m = case // 4
				d.rectangle([x0 + m, y0 + m, x0 + case - m - 1, y0 + case - m - 1], fill=(206, 150, 60), outline=(110, 70, 30))
	# toits : partie haute de chaque emprise
	vus = set()
	for y, row in enumerate(rows):
		for x, ch in enumerate(row):
			if ch in TOITS and (x, y) not in vus:
				pile, groupe = [(x, y)], []
				vus.add((x, y))
				while pile:
					cx, cy = pile.pop(); groupe.append((cx, cy))
					for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
						v = (cx + dx, cy + dy)
						if v not in vus and at(*v) in (ch, "D") and at(*v) == ch:
							vus.add(v); pile.append(v)
				xs = [a for a, _ in groupe]; ys = [b for _, b in groupe]
				hh = max(ys) - min(ys) + 1
				toit = round(hh * 3 / 5) if nom not in ("route_16_west", "route_18") or ch != "P" else round(hh * 3 / 5)
				d.rectangle([ox + min(xs) * case, oy + min(ys) * case, ox + (max(xs) + 1) * case - 1, oy + (min(ys) + toit) * case - 1], fill=TOITS[ch])
	for y, row in enumerate(rows):
		for x, ch in enumerate(row):
			if ch in "DX":
				x0, y0 = ox + x * case, oy + y * case
				d.rectangle([x0 + case // 6, y0 + case // 5, x0 + case - case // 6 - 1, y0 + case - 1], fill=(80, 50, 30))
	return img

def sauver(img, nom):
	p = OUT / nom; img.save(p); print(p, img.size)

sauver(rendre("route_16_west"), "PLAN_R16O.png")
sauver(rendre("route_18"), "PLAN_R18.png")
sauver(rendre("parmanie", taille=(1024, 1024)).resize((1024, 1024)), "PLAN_PARMANIE.png")
for i, (a, b) in enumerate(((0, 50), (50, 100), (100, 150))):
	sauver(rendre("route_17", (a, b)), f"PLAN_R17_{i+1}.png")
sauver(rendre("route_16_gate"), "PLAN_P16.png")
sauver(rendre("route_18_gate"), "PLAN_P18.png")
