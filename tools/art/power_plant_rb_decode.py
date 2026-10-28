#!/usr/bin/env python3
"""Décodeur de la Centrale de Rouge/Bleu (jalon 32, lot 32G, N-11) : géométrie de référence de la
grille `tools/plans/power_plant.txt`.

Même méthode que `cerulean_cave_rb_decode.py` (J31) : **lit un désassemblage `pokered` local passé
en argument** (jamais embarqué dans le dépôt) : `<pokered>/maps/PowerPlant.blk`,
`gfx/blocksets/facility.bst`, `data/tilesets/collision_tile_ids.asm` (`Facility_Coll`),
`data/maps/objects/PowerPlant.asm`, `data/events/hidden_events.asm`. Bibliothèque standard
seulement ; à lancer avec `python3 -I`.

Rappel RB : 20 × 18 blocs de 2 × 2 cases de 16 px (40 × 36 cases de jeu) ; la collision d'une case
est celle de la **tuile en bas à gauche** de son carré de 2 × 2 tuiles (16 octets par bloc). Le
tileset FACILITY n'a pas de collisions par paires.

Sorties :
  python3 -I tools/art/power_plant_rb_decode.py <pokered>              grille RB brute + objets
  python3 -I tools/art/power_plant_rb_decode.py <pokered> --brouillon  caractères du projet
  python3 -I tools/art/power_plant_rb_decode.py <pokered> --ecarts     écarts avec la grille du dépôt

Légende « RB brute » : # mur ou machine · . sol · Z Électhor · v fausse Poké Ball (Voltorbe ou
Électrode) · o objet visible · c objet caché (sur un mur) · E entrée sud · O porte ouest.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

LARGEUR, HAUTEUR = 40, 36
BLOCS = (20, 18)
VERS_PROJET = {"#": "#", ".": ".", "E": "E", "O": "O", "c": "x", "Z": ".", "v": ".", "o": "."}


def lire_collisions(pokered: Path) -> set[int]:
	texte = (pokered / "data/tilesets/collision_tile_ids.asm").read_text()
	bloc = re.search(r"Facility_Coll::\s*\n\s*coll_tiles([^\n]*)", texte)
	if not bloc:
		raise SystemExit("Facility_Coll introuvable")
	return {int(v, 16) for v in re.findall(r"\$([0-9a-fA-F]{2})", bloc.group(1))}


def grille_rb(pokered: Path) -> list[list[str]]:
	blk = (pokered / "maps/PowerPlant.blk").read_bytes()
	bst = (pokered / "gfx/blocksets/facility.bst").read_bytes()
	passables = lire_collisions(pokered)
	if len(blk) != BLOCS[0] * BLOCS[1]:
		raise SystemExit(f"PowerPlant.blk : {len(blk)} octets, {BLOCS[0] * BLOCS[1]} attendus")
	g = [["#"] * LARGEUR for _ in range(HAUTEUR)]
	for by in range(BLOCS[1]):
		for bx in range(BLOCS[0]):
			tuiles = bst[blk[by * BLOCS[0] + bx] * 16:][:16]
			for cy in range(2):
				for cx in range(2):
					tuile = tuiles[(cy * 2 + 1) * 4 + cx * 2]
					g[by * 2 + cy][bx * 2 + cx] = "." if tuile in passables else "#"
	return g


def objets(pokered: Path) -> dict[str, list]:
	texte = (pokered / "data/maps/objects/PowerPlant.asm").read_text()
	warps = [(int(x), int(y)) for x, y in re.findall(r"warp_event\s+(\d+),\s*(\d+)", texte)]
	evts = re.findall(r"object_event\s+(\d+),\s*(\d+),\s*(\w+),[^,]*,[^,]*,\s*\w+,\s*(\w+)(?:,\s*(\d+))?",
		texte)
	cachés = (pokered / "data/events/hidden_events.asm").read_text()
	bloc = cachés.split("hidden_events_for POWER_PLANT", 1)[1].split("db -1", 1)[0]
	caches = [(int(x), int(y), o.lower()) for x, y, o in
		re.findall(r"hidden_event\s+(\d+),\s*(\d+),\s*HiddenItems,\s*(\w+)", bloc)]
	return {
		"warps": warps,
		"zapdos": [(int(x), int(y), int(n)) for x, y, s, e, n in evts if e == "ZAPDOS"],
		"balls": [(int(x), int(y), e.lower(), int(n)) for x, y, s, e, n in evts
			if e in ("VOLTORB", "ELECTRODE")],
		"objets": [(int(x), int(y), e.lower()) for x, y, s, e, n in evts
			if s == "SPRITE_POKE_BALL" and e not in ("VOLTORB", "ELECTRODE")],
		"caches": caches,
	}


def annotee(pokered: Path) -> list[list[str]]:
	g = grille_rb(pokered)
	o = objets(pokered)
	sud = [(x, y) for x, y in o["warps"] if y == HAUTEUR - 1]
	for x, y in o["warps"]:
		g[y][x] = "E" if (x, y) in sud else "O"
	for x, y, _ in o["zapdos"]:
		g[y][x] = "Z"
	for x, y, *_ in o["balls"]:
		g[y][x] = "v"
	for x, y, _ in o["objets"]:
		g[y][x] = "o"
	for x, y, _ in o["caches"]:
		g[y][x] = "c"
	return g


def main() -> int:
	if len(sys.argv) < 2:
		print(__doc__)
		return 2
	pokered = Path(sys.argv[1])
	mode = sys.argv[2] if len(sys.argv) > 2 else ""
	g = annotee(pokered)
	if mode == "--brouillon":
		for y, rang in enumerate(g):
			print(f"{y:02d} " + "".join(VERS_PROJET[c] for c in rang))
		return 0
	if mode == "--ecarts":
		depot = Path(__file__).resolve().parents[2] / "tools/plans/power_plant.txt"
		texte = depot.read_text().splitlines()
		debut = next(i for i, l in enumerate(texte) if l.startswith("GRILLE ")) + 1
		lignes = texte[debut:debut + HAUTEUR]
		ecarts = 0
		for y, ligne in enumerate(lignes):
			for x, c in enumerate(ligne[3:]):
				attendu = VERS_PROJET[g[y][x]]
				if c != attendu:
					ecarts += 1
					print(f"({x}, {y}) : dépôt « {c} », RB « {attendu} »")
		print(f"{ecarts} écart(s)")
		return 0
	for y, rang in enumerate(g):
		print(f"{y:02d} " + "".join(rang))
	for cle, valeurs in objets(pokered).items():
		print(cle, valeurs)
	return 0


if __name__ == "__main__":
	sys.exit(main())
