#!/usr/bin/env python3
"""Lecture d'une grille fonctionnelle de carte (`tools/plans/<carte>.txt`).

Format (voir l'en-tête de `tools/plans/route_2.txt`) : section `GRILLE L H` (une rangée par
ligne, « NN » + espace + L caractères), `FIN`, puis section `POSITIONS` (une ligne par élément :
identifiant, type, cases, `bloque` | `libre`, commentaire après `#`), `FIN`.
Utilisé par `plan_aplats.py` (plan en aplats) et `plan_check.py` (recherche de chemin).
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

# Cases praticables ; tout autre caractère de la légende est bloqué.
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


@dataclass
class Plan:
	width: int
	height: int
	rows: list[str]
	positions: dict[str, Position] = field(default_factory=dict)

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


def lire(chemin: str | Path) -> Plan:
	lignes = Path(chemin).read_text(encoding="utf-8").splitlines()
	section = ""
	rows: list[str] = []
	width = height = 0
	positions: dict[str, Position] = {}
	for brute in lignes:
		ligne = brute.split("#", 1)[0].rstrip() if section != "GRILLE" else brute.rstrip()
		if not ligne.strip():
			continue
		mots = ligne.split()
		if mots[0] == "GRILLE":
			section, width, height = "GRILLE", int(mots[1]), int(mots[2])
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
			note = brute.split("#", 1)[1].strip() if "#" in brute else ""
			ident, kind, cases, etat = mots[:4]
			if etat not in ("bloque", "libre"):
				raise ValueError(f"{ident} : « {etat} » au lieu de bloque / libre")
			if ident in positions:
				raise ValueError(f"{ident} en double")
			positions[ident] = Position(ident, kind, _cases(cases), etat == "bloque", note)
	if len(rows) != height:
		raise ValueError(f"{len(rows)} rangées au lieu de {height}")
	plan = Plan(width, height, rows, positions)
	for p in positions.values():
		for x, y in p.cells:
			if not (0 <= x < width and 0 <= y < height):
				raise ValueError(f"{p.ident} : case ({x}, {y}) hors carte")
	return plan
