#!/usr/bin/env python3
"""Décodeur de l'Arène de Safrania et du Dojo de Combat de Rouge/Bleu (jalon 27, T2) : géométrie
de référence des grilles `tools/plans/safrania_arene.txt` et `safrania_dojo.txt`, graphe des
téléporteurs de l'Arène.

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt, données
non fiables : ce script ne fait que LIRE des fichiers). Bibliothèque standard seulement ; à lancer
avec `python3 -I`. Réutilise les lecteurs de `silph_rb_decode.py` (blocs 2 × 2, collision de la
tuile en bas à gauche, warps, objets).

Fichiers lus : `maps/SaffronGym.blk` (10 × 9 blocs, FACILITY), `maps/FightingDojo.blk` (5 × 6
blocs, DOJO = blocset `gym`), `gfx/blocksets/facility.bst`, `gym.bst`,
`data/tilesets/collision_tile_ids.asm`, `data/maps/objects/SaffronGym.asm`, `FightingDojo.asm`,
`scripts/SaffronGym.asm`, `FightingDojo.asm` (portées de vue des Dresseurs).

  python3 -I tools/art/saffron_gym_rb_decode.py <pokered>            grilles RB brutes
  python3 -I tools/art/saffron_gym_rb_decode.py <pokered> --positions  brouillon de POSITIONS
  python3 -I tools/art/saffron_gym_rb_decode.py <pokered> --graphe     tapis → destination

Légende brute : # mur · M mobilier · . sol · T tapis de téléportation (warp de l'Arène vers
elle-même) · E sortie · objets : Z Morgane, C Exorciste (Channeler), P Médium (Psychic),
G guide, K maître, B Karatéka, o Poké Ball.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from silph_rb_decode import _coll, _objets, _tuile, _warps  # noqa: E402

CARTES = {
	"gym": ("SaffronGym", 10, 9, "facility", "Facility", "saffron_gym"),
	"dojo": ("FightingDojo", 5, 6, "gym", "Dojo", "fighting_dojo"),
}
LETTRES = {"OPP_SABRINA": "Z", "OPP_CHANNELER": "C", "OPP_PSYCHIC_TR": "P",
	"SPRITE_GYM_GUIDE": "G", "OPP_BLACKBELT": "B", "SPRITE_POKE_BALL": "o"}


def _vues(src: str) -> list[int]:
	return [int(v) for v in re.findall(r"trainer EVENT_\w+,\s*(\d+),", src)]


def decoder(pokered: Path, cle: str) -> dict:
	nom, w, h, bst_nom, coll_nom, _carte = CARTES[cle]
	blk = (pokered / f"maps/{nom}.blk").read_bytes()
	bst = (pokered / f"gfx/blocksets/{bst_nom}.bst").read_bytes()
	coll = _coll(pokered, coll_nom)
	objets_src = (pokered / f"data/maps/objects/{nom}.asm").read_text()
	script_src = (pokered / f"scripts/{nom}.asm").read_text()
	warps = _warps(objets_src)
	objets = _objets(objets_src)
	vues = _vues(script_src)
	k = 0
	for o in objets:
		# Le premier objet à classe OPP_ est le Champion / le maître (parlé, pas d'en-tête).
		if o.classe and o.rang > 1:
			o.vue = vues[k] if k < len(vues) else 0
			k += 1
	rangs = []
	for y in range(h * 2):
		ligne = ""
		for x in range(w * 2):
			t = _tuile(blk, bst, w, x, y)
			ligne += "." if t in coll else "#"
		rangs.append(list(ligne))
	for i, (x, y, cible, _n) in enumerate(warps):
		rangs[y][x] = "E" if cible == "LAST_MAP" else "T"
	return {"rangs": rangs, "warps": warps, "objets": objets, "w": w * 2, "h": h * 2}


def brut(d: dict) -> list[str]:
	rangs = [r[:] for r in d["rangs"]]
	for o in d["objets"]:
		lettre = LETTRES.get(o.classe) or LETTRES.get(o.sprite, "?")
		if o.classe == "OPP_BLACKBELT" and o.rang == 1:
			lettre = "K"
		rangs[o.y][o.x] = lettre
	return ["%02d %s" % (y, "".join(r)) for y, r in enumerate(rangs)]


def graphe(d: dict) -> list[str]:
	lignes = []
	for i, (x, y, cible, n) in enumerate(d["warps"], start=1):
		if cible == "LAST_MAP":
			continue
		tx, ty, _c, _k = d["warps"][n - 1]
		lignes.append("tapis %2d (%2d, %2d) → tapis %2d (%2d, %2d)" % (i, x, y, n, tx, ty))
	return lignes


def main(argv: list[str]) -> int:
	if len(argv) < 2:
		print(__doc__)
		return 1
	pokered = Path(argv[1])
	for cle in CARTES:
		d = decoder(pokered, cle)
		print("== %s (%d × %d)" % (CARTES[cle][0], d["w"], d["h"]))
		if "--graphe" in argv:
			print("\n".join(graphe(d)))
		elif "--positions" in argv:
			for o in d["objets"]:
				print("objet %d (%d, %d) %s %s %s vue=%d %s" % (o.rang, o.x, o.y, o.sprite,
					o.facing, o.classe, o.vue, o.equipe))
		else:
			print("\n".join(brut(d)))
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
