#!/usr/bin/env python3
"""Décodeur de l'Arène de Jadielle de Rouge/Bleu (jalon 28, T2) : géométrie de référence de la
grille `tools/plans/jadielle_arene.txt`.

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt ; ce
script ne fait que LIRE des fichiers). Bibliothèque standard seulement ; à lancer avec `python3 -I`.

Fichiers lus : `maps/ViridianGym.blk` (10 × 9 blocs = 20 × 18 cases), `gfx/blocksets/gym.bst`,
`data/tilesets/collision_tile_ids.asm` (`Gym_Coll`), `data/maps/objects/ViridianGym.asm`,
`scripts/ViridianGym.asm` (table `ViridianGymArrowTilePlayerMovement` : 12 dalles, chacune un
déplacement en ligne droite d'un nombre fixe de pas).

Règle RB : collision d'une case = tuile en bas à gauche de son carré de 2 × 2 tuiles.

Sortie : la grille RB brute (# bloqué, . praticable, < > ^ v dalle de départ, o fin de glisse RB,
X sortie), les objets, et la liste des dalles (départ, direction, pas, arrivée, cases traversées).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

W, H = 10, 9
PAD = {"PAD_UP": (0, -1, "^"), "PAD_DOWN": (0, 1, "v"), "PAD_LEFT": (-1, 0, "<"),
	"PAD_RIGHT": (1, 0, ">")}


def coll(pokered: Path) -> set[int]:
	t = (pokered / "data/tilesets/collision_tile_ids.asm").read_text()
	m = re.search(r"Gym_Coll::\s*coll_tiles ([^\n]*)", t)
	return {int(v.strip().lstrip("$"), 16) for v in m.group(1).split(",")}


def grille(pokered: Path) -> list[list[str]]:
	blk = (pokered / "maps/ViridianGym.blk").read_bytes()
	bst = (pokered / "gfx/blocksets/gym.bst").read_bytes()
	ok = coll(pokered)
	g = []
	for y in range(H * 2):
		row = []
		for x in range(W * 2):
			bloc = blk[(y // 2) * W + x // 2]
			tuile = bst[bloc * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]
			row.append("." if tuile in ok else "#")
		g.append(row)
	return g


def dalles(pokered: Path) -> list[tuple]:
	t = (pokered / "scripts/ViridianGym.asm").read_text()
	table = re.findall(r"map_coord_movement\s+(\d+),\s*(\d+),\s*(\w+)", t)
	out = []
	for x, y, nom in table:
		m = re.search(nom + r":\s*db (PAD_\w+), (\d+)", t)
		dx, dy, ch = PAD[m.group(1)]
		n = int(m.group(2))
		x, y = int(x), int(y)
		cases = [(x + dx * k, y + dy * k) for k in range(1, n + 1)]
		out.append(((x, y), ch, n, cases[-1], cases))
	return out


def objets(pokered: Path) -> list[str]:
	t = (pokered / "data/maps/objects/ViridianGym.asm").read_text()
	return re.findall(r"(?:object|warp)_event[^\n]*", t)


def main() -> int:
	pokered = Path(sys.argv[1])
	g = grille(pokered)
	ds = dalles(pokered)
	for (x, y), ch, _n, fin, _c in ds:
		g[y][x] = ch
	for (_s, _ch, _n, (fx, fy), _c) in ds:
		if g[fy][fx] == ".":
			g[fy][fx] = "o"
	for x in (16, 17):
		g[17][x] = "X"
	print("     " + "".join(str(i % 10) for i in range(W * 2)))
	for y, row in enumerate(g):
		print(f"{y:02d}   " + "".join(row))
	print()
	for (s, ch, n, fin, cases) in ds:
		bloque = [c for c in cases if g[c[1]][c[0]] == "#"]
		print(f"dalle {s} {ch} {n} → {fin}" + (f"  BLOQUÉ {bloque}" if bloque else ""))
	print()
	for o in objets(pokered):
		print(o.strip())
	return 0


if __name__ == "__main__":
	sys.exit(main())
