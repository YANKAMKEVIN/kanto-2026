#!/usr/bin/env python3
"""Lecture d'une grille fonctionnelle de carte (`tools/plans/<carte>.txt`).

Format (voir l'en-tête de `tools/plans/route_2.txt`) : section `GRILLE L H` (une rangée par
ligne, « NN » + espace + L caractères), `FIN`, puis section `POSITIONS` (une ligne par élément :
identifiant, type, cases, `bloque` | `libre`, attributs facultatifs `cle=valeur`, commentaire
après `#`), `FIN`.
Ligne facultative avant la grille : `PRATICABLES <caractères>` (cases praticables de cette
grille ; défaut `.=hvDp`, la légende de la Route 2 et d'Argenta). Jalon 9 : la Forêt de Jade a sa légende.
Utilisé par `plan_aplats.py` (plan en aplats) et `plan_check.py` (recherche de chemin).

**Identifiant de carte** (jalon 26) : une ligne facultative `CARTE <identifiant>` avant la grille
donne l'identifiant de la carte du jeu quand le nom du fichier diffère (`sylphe_3f.txt` →
`silph_co_3f`) ; les `vers=<carte>:<repère>` des autres grilles visent cet identifiant. Sans elle,
la carte porte le nom du fichier. `lire` (et `tests/helpers/plan_grid.gd`) ignorent cette ligne.

**Variante** (jalon 14, T20a : Azuria « après J14 ») : après la grille de base, une grille peut
porter des sections `PRATICABLES_<V>`, `GRILLE_<V>` (rangées remplacées, même format « NN » +
rangée complète) et `POSITIONS_<V>` (positions ajoutées, ou remplaçant celles de même
identifiant), chacune fermée par `FIN`. Sans `variante`, elles sont ignorées : la grille de base
(celle d'un jalon déjà validé) se lit comme avant, ici comme dans `tests/helpers/plan_grid.gd`.
Avec `lire(chemin, "J14")`, la base reçoit les rangées et positions de la variante.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

# Cases praticables par défaut (Route 2, J10 : « p » pavé d'Argenta) ; tout autre caractère de
# la légende est bloqué. Une grille peut fixer les siennes (ligne `PRATICABLES`).
PRATICABLES = set(".=hvDp")
HERBES = "h"
REBORD = "v"
PORTE = "D"


@dataclass
class Position:
	ident: str
	kind: str
	cells: list[tuple[int, int]]
	bloque: bool
	note: str = ""
	# Attributs « cle=valeur » écrits après bloque / libre (jalon 9 : facing, sight, role…).
	attrs: dict[str, str] = field(default_factory=dict)


@dataclass
class Plan:
	width: int
	height: int
	rows: list[str]
	positions: dict[str, Position] = field(default_factory=dict)
	praticables: set[str] = field(default_factory=lambda: set(PRATICABLES))

	def at(self, x: int, y: int) -> str:
		return self.rows[y][x]

	def cells_of(self, char: str) -> list[tuple[int, int]]:
		return [(x, y) for y, row in enumerate(self.rows) for x, c in enumerate(row) if c == char]

	def of_kind(self, kind: str) -> list[Position]:
		return [p for p in self.positions.values() if p.kind == kind]


def _plage(texte: str) -> list[int]:
	if ".." in texte:
		a, b = texte.split("..")
		return list(range(int(a), int(b) + 1))
	return [int(texte)]


def _cases(texte: str) -> list[tuple[int, int]]:
	cases: list[tuple[int, int]] = []
	for groupe in texte.split(";"):
		xs, ys = groupe.split(",")
		cases += [(x, y) for y in _plage(ys) for x in _plage(xs)]
	return cases


def _position(brute: str, mots: list[str]) -> Position:
	note = brute.split("#", 1)[1].strip() if "#" in brute else ""
	ident, kind, cases, etat = mots[:4]
	if etat not in ("bloque", "libre"):
		raise ValueError(f"{ident} : « {etat} » au lieu de bloque / libre")
	attrs: dict[str, str] = {}
	for mot in mots[4:]:
		if "=" not in mot:
			raise ValueError(f"{ident} : attribut « {mot} » sans « = »")
		cle, valeur = mot.split("=", 1)
		attrs[cle] = valeur
	return Position(ident, kind, _cases(cases), etat == "bloque", note, attrs)


def lire(chemin: str | Path, variante: str | None = None) -> Plan:
	lignes = Path(chemin).read_text(encoding="utf-8").splitlines()
	section = ""
	rows: list[str] = []
	width = height = 0
	positions: dict[str, Position] = {}
	praticables = set(PRATICABLES)
	v_rows: dict[int, str] = {}
	v_positions: dict[str, Position] = {}
	v_praticables: set[str] | None = None
	suffixe = f"_{variante}" if variante else None
	for brute in lignes:
		dans_grille = section in ("GRILLE", "GRILLE_V")
		ligne = brute.split("#", 1)[0].rstrip() if not dans_grille else brute.rstrip()
		if not ligne.strip():
			continue
		mots = ligne.split()
		if suffixe and section == "":
			if mots[0] == "PRATICABLES" + suffixe:
				v_praticables = set(mots[1])
				continue
			if mots[0] == "GRILLE" + suffixe:
				section = "GRILLE_V"
				continue
			if mots[0] == "POSITIONS" + suffixe:
				section = "POSITIONS_V"
				continue
		if section == "GRILLE_V" and mots[0] != "FIN":
			numero, row = int(mots[0]), mots[1]
			if len(row) != width or not 0 <= numero < height or numero in v_rows:
				raise ValueError(f"variante {variante} : rangée {mots[0]} invalide")
			v_rows[numero] = row
			continue
		if section == "POSITIONS_V" and mots[0] != "FIN":
			p = _position(brute, mots)
			if p.ident in v_positions:
				raise ValueError(f"variante {variante} : {p.ident} en double")
			v_positions[p.ident] = p
			continue
		if mots[0] == "GRILLE":
			section, width, height = "GRILLE", int(mots[1]), int(mots[2])
			continue
		if mots[0] == "PRATICABLES" and section == "":
			praticables = set(mots[1])
			continue
		if mots[0] == "POSITIONS":
			section = "POSITIONS"
			continue
		if mots[0] == "FIN":
			section = ""
			continue
		if section == "GRILLE":
			numero, row = mots[0], mots[1]
			if int(numero) != len(rows) or len(row) != width:
				raise ValueError(f"rangée {numero} invalide (attendu n° {len(rows)}, {width} cases)")
			rows.append(row)
		elif section == "POSITIONS":
			p = _position(brute, mots)
			if p.ident in positions:
				raise ValueError(f"{p.ident} en double")
			positions[p.ident] = p
	if len(rows) != height:
		raise ValueError(f"{len(rows)} rangées au lieu de {height}")
	if variante:
		if not v_rows and not v_positions and v_praticables is None:
			raise ValueError(f"variante {variante} absente de {chemin}")
		rows = [v_rows.get(y, row) for y, row in enumerate(rows)]
		positions = {**positions, **v_positions}
		praticables = v_praticables if v_praticables is not None else praticables
	plan = Plan(width, height, rows, positions, praticables)
	for p in positions.values():
		for x, y in p.cells:
			if not (0 <= x < width and 0 <= y < height):
				raise ValueError(f"{p.ident} : case ({x}, {y}) hors carte")
	return plan


def carte(chemin: str | Path) -> str:
	"""Identifiant de carte d'une grille : ligne `CARTE <id>` avant la grille, sinon le nom du
	fichier."""
	for brute in Path(chemin).read_text(encoding="utf-8").splitlines():
		mots = brute.split("#", 1)[0].split()
		if not mots:
			continue
		if mots[0] in ("GRILLE", "POSITIONS"):
			break
		if mots[0] == "CARTE" and len(mots) == 2:
			return mots[1]
	return Path(chemin).stem


def index_cartes(dossier: str | Path) -> dict[str, Path]:
	"""Identifiant de carte → grille, pour toutes les grilles d'un dossier."""
	return {carte(f): f for f in sorted(Path(dossier).glob("*.txt"))}
