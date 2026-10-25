#!/usr/bin/env python3
"""Décodeur des Îles Écume de Rouge/Bleu (jalon 24, T2) : géométrie de référence des grilles.

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt) :
`<pokered>/maps/SeafoamIslands*.blk`, `gfx/blocksets/cavern.bst`,
`data/maps/objects/SeafoamIslands*.asm`, `data/events/hidden_item_coords.asm`. Le code ne
dépend que de la bibliothèque standard ; à lancer avec `python3 -I`.

Comment RB range une carte : 15 × 9 blocs de 2 × 2 « cases » de 16 px (soit 30 × 18 cases de
jeu) ; la collision d'une case est celle de la **tuile en bas à gauche** de son carré de 2 × 2
tuiles (blocset : 16 octets par bloc, 4 par rangée). Collisions : tuiles passables
`Cavern_Coll` ; **collisions par paires** (`TilePairCollisionsLand`) : le sol bas `$20` ne
touche pas le sol haut `$05` (on ne passe de l'un à l'autre que par un escalier `$15`) ;
`TilePairCollisionsWater` : l'eau `$14` ne touche pas le sol haut `$05` (on ne monte et on ne
descend du Surf que sur sol bas, escalier ou échelle).

Sorties :
  python3 -I tools/art/seafoam_rb_decode.py <pokered>              les 5 étages décodés (RB brut)
  python3 -I tools/art/seafoam_rb_decode.py <pokered> --brouillon   les mêmes, dans les caractères
                                                                    des grilles du projet
  python3 -I tools/art/seafoam_rb_decode.py <pokered> --ecarts      les écarts entre les grilles
                                                                    `tools/plans/seafoam_*.txt` et
                                                                    RB (case par case)

Légende « RB brut » : # mur · | arête (tuile $1c, bloquée) · ~ eau · . sol bas · : sol haut ·
S escalier · L échelle ou trou-warp · E entrée · O trou · r petit rocher fixe · n panneau ·
B rocher de Force (objet à mouvement) · b rocher qui apparaît après une chute · A Artikodin.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

LARGEUR, HAUTEUR = 30, 18
ETAGES = ["1F", "B1F", "B2F", "B3F", "B4F"]
NOM_CARTE = {"1F": "seafoam_1f", "B1F": "seafoam_b1f", "B2F": "seafoam_b2f",
	"B3F": "seafoam_b3f", "B4F": "seafoam_b4f"}
RB_BRUT = {0x20: ".", 0x05: ":", 0x14: "~", 0x15: "S", 0x18: "L", 0x1a: "L", 0x21: "E",
	0x22: "O", 0x12: "r", 0x1e: "n", 0x1c: "|"}
# RB brut → caractère des grilles du projet (les échelles U / V sont résolues par les warps).
VERS_PROJET = {".": ".", ":": ":", "~": "w", "S": "=", "L": "L", "E": "E", "O": "O", "r": "o",
	"n": "n", "|": "|", "#": "#"}

Case = tuple[int, int]


class EtageRB:
	def __init__(self, nom: str, tuiles: list[list[int]]) -> None:
		self.nom = nom
		self.tuiles = tuiles
		self.warps: list[tuple[int, int, str, int]] = []
		self.rochers: list[tuple[int, int, bool]] = []   # (x, y, mobile)
		self.panneaux: list[Case] = []
		self.oiseau: Case | None = None
		self.caches: list[Case] = []

	def brut(self) -> list[list[str]]:
		g = [[RB_BRUT.get(t, "#") for t in rang] for rang in self.tuiles]
		for x, y, mobile in self.rochers:
			g[y][x] = "B" if mobile else "b"
		if self.oiseau:
			g[self.oiseau[1]][self.oiseau[0]] = "A"
		return g


def _tuile(blk: bytes, bst: bytes, x: int, y: int) -> int:
	bloc = blk[(y // 2) * (LARGEUR // 2) + x // 2]
	return bst[bloc * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]


def decoder(pokered: Path) -> dict[str, EtageRB]:
	bst = (pokered / "gfx/blocksets/cavern.bst").read_bytes()
	caches: dict[str, list[Case]] = {}
	for m in re.finditer(r"hidden_item\s+SEAFOAM_ISLANDS_(\w+),\s*(\d+),\s*(\d+)",
			(pokered / "data/events/hidden_item_coords.asm").read_text()):
		caches.setdefault(m.group(1), []).append((int(m.group(2)), int(m.group(3))))
	etages: dict[str, EtageRB] = {}
	for nom in ETAGES:
		fichier = f"SeafoamIslands{nom}"
		blk = (pokered / f"maps/{fichier}.blk").read_bytes()
		assert len(blk) == (LARGEUR // 2) * (HAUTEUR // 2), nom
		e = EtageRB(nom, [[_tuile(blk, bst, x, y) for x in range(LARGEUR)]
			for y in range(HAUTEUR)])
		src = (pokered / f"data/maps/objects/{fichier}.asm").read_text()
		e.warps = [(int(x), int(y), d, int(k)) for x, y, d, k in re.findall(
			r"warp_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\d+)", src)]
		for m in re.finditer(r"object_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\w+),\s*(\w+)", src):
			x, y, sprite, _, mouvement = m.groups()
			if sprite == "SPRITE_BOULDER":
				e.rochers.append((int(x), int(y), mouvement != "NONE"))
			elif sprite == "SPRITE_BIRD":
				e.oiseau = (int(x), int(y))
		e.panneaux = [(int(x), int(y)) for x, y in re.findall(r"bg_event\s+(\d+),\s*(\d+)", src)]
		e.caches = caches.get(nom, [])
		etages[nom] = e
	return etages


def brouillon(e: EtageRB) -> list[str]:
	"""L'étage dans les caractères du projet (sans les ajouts de conception)."""
	g = [[VERS_PROJET[c] for c in rang] for rang in
		([RB_BRUT.get(t, "#") for t in r] for r in e.tuiles)]
	for x, y, mobile in e.rochers:
		if mobile:
			g[y][x] = "B"
	return ["".join(r) for r in g]


def _afficher(titre: str, rangs: list[str]) -> None:
	print(f"--- {titre}")
	print("    " + "".join(str(x // 10) for x in range(LARGEUR)))
	print("    " + "".join(str(x % 10) for x in range(LARGEUR)))
	for y, r in enumerate(rangs):
		print(f"{y:2d}  {r}")


def _ecarts(etages: dict[str, EtageRB], plans: Path) -> None:
	"""Compare les grilles du projet à RB : une ligne par case qui diffère (hors ajouts connus)."""
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_grille import lire  # noqa: E402
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
				if a != b and not (a == "L" and b in "UV"):
					diffs.append(f"({x},{y}) RB « {a} » → projet « {b} »")
		print(f"{nom} : {plan.width} × {plan.height} (RB {LARGEUR} × {HAUTEUR}), "
			f"{len(diffs)} case(s) qui diffèrent")
		for d in diffs:
			print("   " + d)


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
		if "--brouillon" in argv:
			_afficher(nom + " (caractères du projet)", brouillon(e))
		else:
			_afficher(nom, ["".join(r) for r in e.brut()])
		print("  warps :", [(x, y, d.replace("SEAFOAM_ISLANDS_", ""), k) for x, y, d, k in e.warps])
		print("  rochers :", e.rochers, "· panneaux :", e.panneaux, "· cachés :", e.caches,
			"· oiseau :", e.oiseau)
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
