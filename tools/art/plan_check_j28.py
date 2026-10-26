#!/usr/bin/env python3
"""Vérifie l'Arène de Jadielle (jalon 28, `docs/tech/jalon-28.md` §2.1) : `tools/plans/jadielle_arene.txt`.

Contrôles :
  1. dimensions (24 × 22), caractères connus, carte close (seule l'ouverture `X` du bas est au bord) ;
  2. DALLES, règle du moteur du J20 (`SpinTileRules.slide` : glisse en ligne droite, une flèche
     rencontrée change la direction, arrêt sur la première case `o`) : chaque flèche mène à un arrêt
     sans mur (BLOCKED), sans boucle (LOOP) ni trajet trop long (TOO_LONG, 256 pas) ; le trajet
     simulé est IDENTIQUE au trajet RB recopié en POSITIONS (kind=dalle : trajet=, arret=) ;
     chaque `o` est l'arrêt d'au moins une dalle ; rien (PNJ, Dresseur, objet, warp, spawn) sur
     une flèche ni sur un trajet ; aucune glissade ne finit sur un warp ;
  3. atteignabilité (Dresseurs et objet en place, on ne se pose jamais sur une flèche) : le devant
     de Giovanni, le guide, l'objet, chaque Dresseur et chaque arrêt sont atteignables depuis
     l'entrée ; l'entrée est atteignable depuis CHAQUE case atteinte (on peut toujours ressortir) ;
  4. Dresseurs : lignes de vue (cases où le joueur s'ARRÊTE : pas normal ou fin de glisse ; une
     ligne qui coupe le milieu d'un trajet ne compte pas) ; liste des Dresseurs évitables (Giovanni
     atteignable sans jamais s'arrêter dans leur ligne), et de ceux marqués `mandatory=1`, qui
     doivent être exactement les inévitables ; graphe des glissades imprimé pour la revue.

Usage : python3 tools/art/plan_check_j28.py      (code 1 si échec)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLAN = RACINE / "tools" / "plans" / "jadielle_arene.txt"
DIMS = (24, 22)
GLYPHES = set("K.<>^voX")
FLECHES = {">": (1, 0), "<": (-1, 0), "^": (0, -1), "v": (0, 1)}
NSEO = {"N": (0, -1), "S": (0, 1), "E": (1, 0), "O": (-1, 0)}
INV = {v: k for k, v in NSEO.items()}
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
DIRS = list(NSEO.values())
MAX_STEPS = 256


def main() -> int:
	plan = lire(PLAN)
	erreurs: list[str] = []
	w, h = plan.width, plan.height
	if (w, h) != DIMS:
		erreurs.append(f"dimensions {w} × {h} ≠ {DIMS}")
	for y in range(h):
		for x in range(w):
			c = plan.at(x, y)
			if c not in GLYPHES:
				erreurs.append(f"caractère inconnu {c!r} en ({x}, {y})")
			if c != "K" and c != "X" and (x in (0, w - 1) or y in (0, h - 1)):
				erreurs.append(f"case praticable au bord ({x}, {y})")

	def praticable(c: tuple[int, int]) -> bool:
		return 0 <= c[0] < w and 0 <= c[1] < h and plan.at(*c) in plan.praticables

	fleches = {(x, y): FLECHES[plan.at(x, y)] for y in range(h) for x in range(w)
		if plan.at(x, y) in FLECHES}
	arrets = set(plan.cells_of("o"))

	# 2. Dalles.
	trajets: dict[tuple[int, int], tuple[list, tuple[int, int]]] = {}
	for depart, d in fleches.items():
		cell, cases, vus, statut = depart, [], {(depart, d)}, "OK"
		while True:
			cell = (cell[0] + d[0], cell[1] + d[1])
			if not praticable(cell):
				statut = "BLOCKED"
				break
			cases.append(cell)
			if cell in arrets:
				break
			if cell in fleches:
				d = fleches[cell]
			if (cell, d) in vus:
				statut = "LOOP"
				break
			vus.add((cell, d))
			if len(cases) > MAX_STEPS:
				statut = "TOO_LONG"
				break
		if statut != "OK":
			erreurs.append(f"dalle {depart} : {statut}")
		else:
			trajets[depart] = (cases, cases[-1])
	rb = {p.cells[0]: p for p in plan.of_kind("dalle")}
	if set(rb) != set(fleches):
		erreurs.append(f"dalles de la grille {sorted(fleches)} ≠ dalles RB {sorted(rb)}")
	for depart, p in rb.items():
		if depart not in trajets:
			continue
		cases, fin = trajets[depart]
		attendu = p.attrs.get("trajet", "")
		d = NSEO[attendu[0]]
		n = int(attendu[1:])
		rb_cases = [(depart[0] + d[0] * k, depart[1] + d[1] * k) for k in range(1, n + 1)]
		arret = tuple(int(v) for v in p.attrs["arret"].split(","))
		if cases != rb_cases or fin != arret:
			erreurs.append(f"dalle {depart} : trajet {cases} ≠ RB {attendu} → {arret}")
	for o in arrets:
		if not any(fin == o for _c, fin in trajets.values()):
			erreurs.append(f"arrêt {o} : fin d'aucune dalle")
	occupe: dict[tuple[int, int], str] = {}
	for p in plan.positions.values():
		if p.kind in ("pnj", "dresseur", "objet", "warp", "spawn"):
			for c in p.cells:
				occupe[c] = p.ident
	for depart, (cases, _fin) in trajets.items():
		for c in [depart] + cases:
			if c in occupe and occupe[c] not in ("sortie", "entree"):
				erreurs.append(f"dalle {depart} : {occupe[c]} sur le trajet {c}")
			if c in occupe and occupe[c] == "sortie":
				erreurs.append(f"dalle {depart} : passe sur la sortie {c}")

	# 3. Atteignabilité.
	bloque = {c for p in plan.positions.values() if p.bloque for c in p.cells}
	entree = plan.positions["entree"].cells[0]

	def voisins(c, exclus=frozenset()):
		for d in DIRS:
			n = (c[0] + d[0], c[1] + d[1])
			if not praticable(n) or n in bloque:
				continue
			if n in fleches:
				if depart_ok := trajets.get(n):
					n = depart_ok[1]
				else:
					continue
			if n in exclus:
				continue
			yield n

	def bfs(depuis, exclus=frozenset()):
		vu = {depuis}
		file = deque([depuis])
		while file:
			c = file.popleft()
			for n in voisins(c, exclus):
				if n not in vu:
					vu.add(n)
					file.append(n)
		return vu

	atteint = bfs(entree)
	cible = plan.positions["parler_giovanni"].cells[0]
	if cible not in atteint:
		erreurs.append(f"devant de Giovanni {cible} inatteignable")
	for p in plan.positions.values():
		if p.kind in ("pnj", "dresseur", "objet"):
			c = p.cells[0]
			if not any((c[0] + d[0], c[1] + d[1]) in atteint for d in DIRS):
				erreurs.append(f"{p.ident} {c} inatteignable")
	for o in arrets:
		if o not in atteint:
			erreurs.append(f"arrêt {o} inatteignable depuis l'entrée")
	for c in sorted(atteint):
		if entree not in bfs(c):
			erreurs.append(f"impasse : l'entrée est inatteignable depuis {c}")

	# 4. Dresseurs.
	inevitables, evitables = [], []
	for p in sorted(plan.of_kind("dresseur"), key=lambda p: p.ident):
		c = p.cells[0]
		d = FACINGS[p.attrs["facing"]]
		ligne = []
		for k in range(1, int(p.attrs["sight"]) + 1):
			n = (c[0] + d[0] * k, c[1] + d[1] * k)
			if not praticable(n) or n in bloque:
				break
			ligne.append(n)
		vu = bfs(entree, frozenset(ligne)) if entree not in ligne else set()
		(evitables if cible in vu else inevitables).append(p.ident)
		marque = p.attrs.get("mandatory") == "1"
		if marque != (cible not in vu):
			erreurs.append(f"{p.ident} : mandatory={int(marque)} mais "
				f"{'inévitable' if cible not in vu else 'évitable'}")
		print(f"{p.ident:16s} {c} {p.attrs['facing']:5s} vue {ligne}")
	print(f"évitables : {evitables}")
	print(f"inévitables : {inevitables}")
	print("graphe des glissades :")
	for depart in sorted(trajets, key=lambda c: (c[1], c[0])):
		cases, fin = trajets[depart]
		print(f"  {depart} {INV[fleches[depart]]} {len(cases)} → {fin}")
	print(f"{len(fleches)} dalles, {len(arrets)} arrêts, {len(atteint)} cases atteintes")
	for e in erreurs:
		print("ERREUR", e)
	print("OK" if not erreurs else f"{len(erreurs)} erreur(s)")
	return 1 if erreurs else 0


if __name__ == "__main__":
	sys.exit(main())
