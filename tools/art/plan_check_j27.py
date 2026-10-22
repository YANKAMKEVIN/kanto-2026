#!/usr/bin/env python3
"""Contrôle des grilles du jalon 27 (`docs/tech/jalon-27.md` §2.1, §2.3) : Arène de Safrania
(`tools/plans/safrania_arene.txt`) et Dojo de Combat (`safrania_dojo.txt`).

Complète `plan_check_teleports.py` (paires, retour, graphe des salles), qui doit passer aussi.

Arène :
- la case d'où l'on parle à Morgane (`but`) n'est atteinte qu'en passant par le tapis du centre
  (un seul tapis mène dans sa salle : « le bon parcours ») ;
- arbitrage 3 (Dresseurs facultatifs selon le parcours) : pour CHAQUE Dresseur, un parcours de
  l'entrée à Morgane évite sa ligne de vue (cases vues en ligne droite, jusqu'à `sight`, arrêtées
  par un mur ou une autre personne) ; et un parcours les évite TOUS (aucun combat imposé) ;
- le parcours le plus court (nombre de tapis) est imprimé pour la revue.
Dojo :
- la sortie, le maître (case devant lui) et les deux Poké Balls (case devant elles) sont
  atteignables depuis l'entrée ; les deux Balls sont voisines et sur l'estrade.

Usage : python3 -I tools/art/plan_check_j27.py      Code 1 si un critère échoue.
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
ARENE = RACINE / "tools/plans/safrania_arene.txt"
DOJO = RACINE / "tools/plans/safrania_dojo.txt"
DIRS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
VOISINS = list(DIRS.values())

Case = tuple[int, int]


class Rapport:
	def __init__(self) -> None:
		self.echecs = 0

	def ok(self, cond: bool, texte: str) -> bool:
		print(("   ok    " if cond else "   ÉCHEC ") + texte)
		if not cond:
			self.echecs += 1
		return cond


def _praticable(plan, c: Case, occupees: set[Case]) -> bool:
	x, y = c
	return 0 <= x < plan.width and 0 <= y < plan.height and plan.at(x, y) in plan.praticables \
		and c not in occupees


def _occupees(plan) -> set[Case]:
	return {c for p in plan.positions.values() if p.bloque for c in p.cells}


def _vue(plan, p, occupees: set[Case]) -> set[Case]:
	dx, dy = DIRS[p.attrs.get("facing", "down")]
	x, y = p.cells[0]
	vues = set()
	for _ in range(int(p.attrs.get("sight", "0"))):
		x, y = x + dx, y + dy
		if not _praticable(plan, (x, y), occupees):
			break
		vues.add((x, y))
	return vues


def _tapis(plan) -> dict[Case, Case]:
	spawns = {p.ident: p.cells[0] for p in plan.of_kind("spawn")}
	return {p.cells[0]: spawns[p.attrs["vers"].split(":")[1]] for p in plan.of_kind("teleporteur")}


def _chemin(plan, interdites: set[Case]) -> list[Case] | None:
	"""BFS sur (case) ; un pas sur un tapis transporte (pas compté) ; renvoie les tapis pris."""
	occupees = _occupees(plan)
	tapis = _tapis(plan)
	depart = plan.of_kind("depart")[0].cells[0]
	but = plan.of_kind("but")[0].cells[0]
	file = deque([depart])
	pere: dict[Case, tuple[Case | None, Case | None]] = {depart: (None, None)}
	while file:
		c = file.popleft()
		if c == but:
			pris = []
			while pere[c][0] is not None:
				if pere[c][1] is not None:
					pris.append(pere[c][1])
				c = pere[c][0]
			return list(reversed(pris))
		for dx, dy in VOISINS:
			n = (c[0] + dx, c[1] + dy)
			if not _praticable(plan, n, occupees) or n in interdites:
				continue
			via = None
			if n in tapis:
				via, n = n, tapis[n]
			if n not in pere:
				pere[n] = (c, via)
				file.append(n)
	return None


def verifier_arene(r: Rapport) -> None:
	print("== %s" % ARENE.name)
	plan = lire(ARENE)
	occupees = _occupees(plan)
	but = plan.of_kind("but")[0].cells[0]
	r.ok(plan.positions["morgane"].cells[0] == (but[0], but[1] - 1), "Morgane juste au nord du but")
	salle_morgane = {(x, y) for x in range(7, 13) for y in range(7, 12)}
	entrees = [c for c, d in _tapis(plan).items() if d in salle_morgane and c not in salle_morgane]
	r.ok(len(entrees) == 1, "un seul tapis mène dans la salle de Morgane : %s" % entrees)
	court = _chemin(plan, set())
	if r.ok(court is not None, "Morgane atteignable depuis l'entrée"):
		print("         parcours le plus court : %d tapis %s" % (len(court), court))
		r.ok(court[-1] == entrees[0], "le parcours finit par le tapis du centre")
	dresseurs = plan.of_kind("dresseur")
	toutes: set[Case] = set()
	for p in dresseurs:
		vue = _vue(plan, p, occupees)
		toutes |= vue
		r.ok(_chemin(plan, vue) is not None, "%s (%s) évitable" % (p.ident, p.attrs["trainer"]))
	r.ok(_chemin(plan, toutes) is not None, "un parcours évite tous les Dresseurs")


def verifier_dojo(r: Rapport) -> None:
	print("== %s" % DOJO.name)
	plan = lire(DOJO)
	occupees = _occupees(plan)
	depart = plan.of_kind("depart")[0].cells[0]
	vus = {depart}
	file = deque([depart])
	while file:
		c = file.popleft()
		for dx, dy in VOISINS:
			n = (c[0] + dx, c[1] + dy)
			if n not in vus and _praticable(plan, n, occupees):
				vus.add(n)
				file.append(n)
	sortie = plan.positions["sortie_ville"].cells
	r.ok(any((x, y - 1) in vus for x, y in sortie), "sortie atteignable")
	m = plan.positions["maitre"].cells[0]
	r.ok((m[0], m[1] + 1) in vus, "case devant le maître atteignable")
	balls = [plan.positions["ball_hitmonlee"].cells[0], plan.positions["ball_hitmonchan"].cells[0]]
	r.ok(abs(balls[0][0] - balls[1][0]) + abs(balls[0][1] - balls[1][1]) == 1, "Balls voisines")
	for b in balls:
		r.ok(any((b[0] + dx, b[1] + dy) in vus for dx, dy in VOISINS), "Ball %s examinable" % (b,))
	for p in plan.of_kind("dresseur"):
		r.ok(p.attrs.get("sight", "") != "", "%s : vue RB écrite" % p.ident)


def main() -> int:
	r = Rapport()
	verifier_arene(r)
	verifier_dojo(r)
	print("TOUT EST CONFORME" if r.echecs == 0 else "%d ÉCHEC(S)" % r.echecs)
	return 1 if r.echecs else 0


if __name__ == "__main__":
	sys.exit(main())
