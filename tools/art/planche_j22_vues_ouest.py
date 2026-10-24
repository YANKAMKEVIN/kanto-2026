import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
R = Path(sys.argv[1]); REF = R / "docs/design/reference"; PL = R / "build/plans/j22o"
def f(t):
	try: return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", t)
	except OSError: return ImageFont.load_default()
ITEMS = [("Route 16 ouest", "route-16-ouest-vue-generale-v1.png", "PLAN_R16O.png"),
	("Route 18", "route-18-vue-generale-v1.png", "PLAN_R18.png"),
	("Parmanie", "parmanie-vue-generale-v1.png", "PLAN_PARMANIE.png"),
	("Poste 16", "poste-16-v1.png", "PLAN_P16.png"),
	("Poste 18", "poste-18-v1.png", "PLAN_P18.png"),
	("Route 17 — tronçon 1 (nord)", "route-17-vue-generale-v1-t1.png", "PLAN_R17_1.png"),
	("Route 17 — tronçon 2 (milieu)", "route-17-vue-generale-v1-t2.png", "PLAN_R17_2.png"),
	("Route 17 — tronçon 3 (sud)", "route-17-vue-generale-v1-t3.png", "PLAN_R17_3.png")]
H = 560; M = 24; T = 44
cells = []
for titre, vue, plan in ITEMS:
	v = Image.open(REF / vue).convert("RGB"); p = Image.open(PL / plan).convert("RGB")
	v = v.resize((round(v.width * H / v.height), H)); p = p.resize((round(p.width * H / p.height), H))
	c = Image.new("RGB", (p.width + v.width + M, H + T), (28, 30, 34))
	c.paste(p, (0, T)); c.paste(v, (p.width + M, T))
	ImageDraw.Draw(c).text((0, 8), titre + "  —  plan (grille) | vue", font=f(26), fill=(235, 235, 235))
	cells.append(c)
# 3 rangées : [R16O, R18], [Parmanie, P16, P18], [R17 x3]
rangs = [cells[0:2], cells[2:5], cells[5:8]]
W = max(sum(c.width for c in r) + M * (len(r) - 1) for r in rangs) + 2 * M
Ht = sum(max(c.height for c in r) for r in rangs) + M * (len(rangs) + 1) + 60
out = Image.new("RGB", (W, Ht), (28, 30, 34))
ImageDraw.Draw(out).text((M, 14), "J22 T9 — vues générales, chemin ouest et Parmanie (v1) : la grille fait foi", font=f(32), fill=(255, 255, 255))
y = 60 + M
for r in rangs:
	x = M
	for c in r:
		out.paste(c, (x, y)); x += c.width + M
	y += max(c.height for c in r) + M
out.save(REF / "j22-vues-ouest-v1.png", optimize=True); print(out.size)
