#!/usr/bin/env python3
"""DAF.4, reliquat (RP-136) — sprites de terrain du Conseil des 4 : Olga, Aldo, Agatha, Peter.
Remplace les sprites provisoires `cooltrainer_f`, `docker`, `channeler`, `traveler` dans
`data/npcs/league_*.json`. Le Maître (`rival`) et Chen (`oak`) étaient déjà peints.
Prompts : tools/art/prompts/daf4_ligue/ ; génération : tools/art/generer.sh ; Codex CLI, sans API.

Usage :
  tools/art/daf4_ligue.py --manifeste   ajoute les 4 entrées au manifeste (idempotent)
  tools/art/daf4_ligue.py --preparer    build/art → assets/ (ces entrées seulement) ; puis
                                        godot --headless --script tools/build_character_frames.gd
  tools/art/daf4_ligue.py --planche     planche docs/design/fiches-assets/daf-4/planche-8-ligue.jpg
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import preparer  # noqa: E402

RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
MANIFESTE = ICI / "manifeste.json"
_C = "assets/sprites/characters/painted/"
PERSOS = [
	("olga", "PNJ_OLGA_NE_r1.png", "Olga (lorelei), remplace cooltrainer_f"),
	("aldo", "PNJ_ALDO_NE_r1.png", "Aldo (bruno), remplace docker"),
	("agatha", "PNJ_AGATHA_NE_r1.png", "Agatha, remplace channeler ; canne dans la main"),
	("peter", "PNJ_PETER_NE_r1.png", "Peter (lance), remplace traveler ; cape"),
]
ENTREES = [{"id": i, "source": s, "sortie": f"{_C}{i}_sheet.png", "hauteur": 128, "nettoyer": True,
	"note": "DAF.4 reliquat (RP-136) ; " + n} for i, s, n in PERSOS]


def manifeste() -> None:
	m = json.loads(MANIFESTE.read_text())
	connus = {e["id"] for e in m["personnages"]}
	m["personnages"] += [e for e in ENTREES if e["id"] not in connus]
	MANIFESTE.write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n")


def preparer_images() -> None:
	m = json.loads(MANIFESTE.read_text())
	ids = {e["id"] for e in ENTREES}
	sous = dict(m)
	sous["personnages"] = [e for e in m["personnages"] if e["id"] in ids]
	for k in ("attentes", "pokemon_fixes", "pokemon", "pokemon_boucles"):
		sous[k] = []
	p = preparer.Preparateur(sous, ART)
	p.catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())
	p.personnages()
	p.ecrire_catalogue()


def planche() -> None:
	"""Une rangée par personnage : les quatre directions (colonne 0 de chaque ligne de la marche) à
	1,5 × l'échelle du jeu, puis la capture de la salle (build/captures/daf4_ligue/)."""
	police = ImageFont.load_default()
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(chemin).exists():
			police = ImageFont.truetype(chemin, 26)
			break
	cat = json.loads((RACINE / "assets/world/catalogue.json").read_text())["personnages"]
	caps = RACINE / "build/captures/daf4_ligue"
	rang = []
	for i, _s, n in PERSOS:
		img = Image.open(RACINE / f"{_C}{i}_sheet.png").convert("RGBA")
		l, h = cat[i]["cellule"]
		poses = [img.crop((c, r * h, c + l, (r + 1) * h)) for r in range(4) for c in (0, l, 2 * l)[:1]]
		poses = [p.resize((round(p.width * 2), round(p.height * 2)), Image.LANCZOS) for p in poses]
		cap = Image.open(caps / f"{i}.png").convert("RGB")
		cap = cap.crop((200, 0, 1400, 780) if i == "peter" else (570, 0, 1770, 780)).resize((600, 390), Image.LANCZOS)
		ligne = Image.new("RGB", (1500, 400), (118, 150, 96))
		d = ImageDraw.Draw(ligne)
		d.text((10, 6), f"{i} - {n}", fill=(255, 255, 255), font=police)
		x = 10
		for p in poses:
			ligne.paste(p, (x, 40), p)
			x += p.width + 10
		ligne.paste(cap, (890, 5))
		rang.append(ligne)
	feuille = Image.new("RGB", (1500, 400 * len(rang)))
	for k, r in enumerate(rang):
		feuille.paste(r, (0, 400 * k))
	sortie = RACINE / "docs/design/fiches-assets/daf-4/planche-8-ligue.jpg"
	feuille.save(sortie, quality=88)
	print(sortie)


if __name__ == "__main__":
	arg = sys.argv[1] if len(sys.argv) > 1 else ""
	{"--manifeste": manifeste, "--preparer": preparer_images, "--planche": planche}.get(arg, lambda: print(__doc__))()
