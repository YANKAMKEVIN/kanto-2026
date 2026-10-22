#!/usr/bin/env python3
"""Décodeur de la Grotte Inconnue de Rouge/Bleu (jalon 31, T3) : géométrie de référence des grilles.

Même méthode que le décodeur des Îles Écume du J24 (`seafoam_rb_decode.py`, branche `jalon-24`) :
**lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt) :
`<pokered>/maps/CeruleanCave{1F,2F,B1F}.blk`, `gfx/blocksets/cavern.bst`,
`data/maps/objects/CeruleanCave*.asm`, `data/events/hidden_item_coords.asm`. Bibliothèque
standard seulement ; à lancer avec `python3 -I`.

Rappel RB : 15 × 9 blocs de 2 × 2 cases de 16 px (30 × 18 cases de jeu) ; la collision d'une case
est celle de la **tuile en bas à gauche** de son carré de 2 × 2 tuiles (blocset : 16 octets par
bloc). Tuiles passables `Cavern_Coll` ; **collisions par paires** (`TilePairCollisionsLand`) : le
sol bas `$20` / `$21` ne touche pas le sol haut `$05` (on passe par un escalier `$15`) ;
`TilePairCollisionsWater` : l'eau `$14` ne touche pas le sol haut `$05`.

Sorties :
  python3 -I tools/art/cerulean_cave_rb_decode.py <pokered>              les 3 étages (RB brut)
  python3 -I tools/art/cerulean_cave_rb_decode.py <pokered> --brouillon   mêmes étages, caractères
                                                                         des grilles du projet
  python3 -I tools/art/cerulean_cave_rb_decode.py <pokered> --ecarts      écarts entre les grilles
                                                                         `tools/plans/cerulean_cave_*.txt`
                                                                         et RB (case par case)
  python3 -I tools/art/cerulean_cave_rb_decode.py <pokered> --objets      warps, objets, Mewtwo

Légende « RB brut » : # mur · ~ eau · . sol bas · : sol haut · S escalier · L échelle ·
E entrée (sortie vers Azuria) · M Mewtwo · o objet visible · c objet caché.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

LARGEUR, HAUTEUR = 30, 18
ETAGES = ["1F", "2F", "B1F"]
NOM_CARTE = {"1F": "cerulean_cave_1f", "2F": "cerulean_cave_2f", "B1F": "cerulean_cave_b1f"}
RB_BRUT = {0x20: ".", 0x21: "E", 0x05: ":", 0x14: "~", 0x15: "S", 0x18: "L", 0x1a: "L"}
# Les autres tuiles passables de `Cavern_Coll` ($22 trou, $2a, $2d, $30) n'apparaissent pas dans
# la Grotte Inconnue : le décodeur s'arrête si l'une d'elles y est.
AUTRES_PASSABLES = {0x22, 0x2a, 0x2d, 0x30}
VERS_PROJET = {".": ".", ":": ":", "~": "w", "S": "=", "L": "L", "E": "E", "#": "#"}

Case = tuple[int, int]


class EtageRB:
	def __init__(self, nom: str, tuiles: list[list[int]]) -> None:
		self.nom = nom
		self.tuiles = tuiles
		self.warps: list[tuple[int, int, str, int]] = []   # (x, y, carte, n° de warp d'arrivée)
		self.objets: list[tuple[int, int, str]] = []       # (x, y, objet)
		self.mewtwo: tuple[int, int, int] | None = None    # (x, y, niveau)
		self.caches: list[Case] = []

	def brut(self) -> list[list[str]]:
		g = [[RB_BRUT.get(t, "#") for t in rang] for rang in self.tuiles]
		for x, y, _ in self.objets:
			g[y][x] = "o"
		for x, y in self.caches:
			g[y][x] = "c"
		if self.mewtwo:
			g[self.mewtwo[1]][self.mewtwo[0]] = "M"
		return g


def _tuile(blk: bytes, bst: bytes, x: int, y: int) -> int:
	bloc = blk[(y // 2) * (LARGEUR // 2) + x // 2]
	return bst[bloc * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]


def decoder(pokered: Path) -> dict[str, EtageRB]:
	bst = (pokered / "gfx/blocksets/cavern.bst").read_bytes()
	caches: dict[str, list[Case]] = {}
	for m in re.finditer(r"hidden_item\s+CERULEAN_CAVE_(\w+),\s*(\d+),\s*(\d+)",
			(pokered / "data/events/hidden_item_coords.asm").read_text()):
		caches.setdefault(m.group(1), []).append((int(m.group(2)), int(m.group(3))))
	etages: dict[str, EtageRB] = {}
	for nom in ETAGES:
		fichier = f"CeruleanCave{nom}"
		blk = (pokered / f"maps/{fichier}.blk").read_bytes()
		assert len(blk) == (LARGEUR // 2) * (HAUTEUR // 2), nom
		e = EtageRB(nom, [[_tuile(blk, bst, x, y) for x in range(LARGEUR)]
			for y in range(HAUTEUR)])
		for rang in e.tuiles:
			assert not AUTRES_PASSABLES & set(rang), f"{nom} : tuile passable inattendue"
		src = (pokered / f"data/maps/objects/{fichier}.asm").read_text()
		e.warps = [(int(x), int(y), d, int(k)) for x, y, d, k in re.findall(
			r"warp_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\d+)", src)]
		for m in re.finditer(r"object_event\s+(\d+),\s*(\d+),\s*(\w+),[^\n]*?,\s*(\w+)(?:,\s*(\d+))?\s*$",
				src, re.MULTILINE):
			x, y, sprite, quoi, niveau = m.groups()
			if sprite == "SPRITE_POKE_BALL":
				e.objets.append((int(x), int(y), quoi.lower()))
			elif quoi == "MEWTWO":
				e.mewtwo = (int(x), int(y), int(niveau))
		e.caches = caches.get(nom, [])
		etages[nom] = e
	return etages


def brouillon(e: EtageRB) -> list[str]:
	"""L'étage dans les caractères du projet (sans les ajouts de conception)."""
	return ["".join(VERS_PROJET[RB_BRUT.get(t, "#")] for t in rang) for rang in e.tuiles]


def _afficher(titre: str, rangs: list[str]) -> None:
	print(f"--- {titre}")
	print("    " + "".join(str(x // 10) for x in range(LARGEUR)))
	print("    " + "".join(str(x % 10) for x in range(LARGEUR)))
	for y, r in enumerate(rangs):
		print(f"{y:2d}  {r}")


def _ecarts(etages: dict[str, EtageRB], plans: Path) -> int:
	"""Compare les grilles du projet à RB : une ligne par case qui diffère (hors ajouts connus :
	échelle L → U / V, case d'un objet caché RB → indice x)."""
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_grille import lire  # noqa: E402
	total = 0
	for nom, e in etages.items():
		chemin = plans / f"{NOM_CARTE[nom]}.txt"
		if not chemin.exists():
			print(f"{nom} : {chemin.name} absent")
			continue
		plan = lire(chemin)
		ref = brouillon(e)
		diffs = []
		for y in range(HAUTEUR):
			for x in range(LARGEUR):
				a, b = ref[y][x], plan.rows[y][x]
				if a == b or (a == "L" and b in "UV") or ((x, y) in e.caches and b == "x"):
					continue
				diffs.append(f"({x},{y}) RB « {a} » → projet « {b} »")
		total += len(diffs)
		print(f"{nom} : {plan.width} × {plan.height} (RB {LARGEUR} × {HAUTEUR}), "
			f"{len(diffs)} case(s) qui diffèrent")
		for d in diffs:
			print("   " + d)
	return total


def main(argv: list[str]) -> int:
	if len(argv) < 2:
		print(__doc__)
		return 2
	pokered = Path(argv[1])
	etages = decoder(pokered)
	if "--ecarts" in argv:
		_ecarts(etages, Path(__file__).resolve().parents[2] / "tools" / "plans")
		return 0
	for nom, e in etages.items():
		if "--objets" in argv:
			print(f"--- {nom}")
			for w in e.warps:
				print(f"   warp {w[0]},{w[1]} → {w[2]} n° {w[3]}")
			for o in e.objets:
				print(f"   objet {o[0]},{o[1]} {o[2]}")
			for c in e.caches:
				print(f"   caché {c[0]},{c[1]}")
			if e.mewtwo:
				print(f"   mewtwo {e.mewtwo[0]},{e.mewtwo[1]} N{e.mewtwo[2]}")
			continue
		rangs = brouillon(e) if "--brouillon" in argv else ["".join(r) for r in e.brut()]
		_afficher(f"{nom} ({'projet' if '--brouillon' in argv else 'RB brut'})", rangs)
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
