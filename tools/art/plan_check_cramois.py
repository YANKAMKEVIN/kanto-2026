#!/usr/bin/env python3
"""Vérifie les grilles de l'Arène, du Laboratoire de Cramois'Île et de la réserve du Musée
d'Argenta (jalon 25, dossier 28 §6 à §8). Le Manoir a son propre contrôle (`plan_check_manoir.py`).

**Arène** (`cramois_arene.txt`) : herses `p` fermées sans leur drapeau ; on ouvre les herses une à
une dans l'ordre 1 → 6 et l'on vérifie à chaque étape :
  1. la machine N et son Dresseur sont atteignables dès que les herses 1..N−1 sont ouvertes, et
     pas avant (sauf la machine 1 et le Dresseur 2, atteints dès l'entrée) ;
  2. Auguste n'est atteignable qu'avec les six herses ouvertes ;
  3. le Dresseur 1 (sans machine) est atteignable après la herse 1 ;
  4. aucune herse ne se contourne (fermer la herse N coupe tout ce qui est derrière) ;
  5. chaque machine se lit depuis la case du dessous.

**Laboratoire** (4 grilles) et **réserve du Musée** : toutes les positions atteignables depuis
l'entrée (une case voisine), portes du hall reliées aux salles.

Usage : python3 tools/art/plan_check_cramois.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
Case = tuple[int, int]

ok = True


def echec(msg: str) -> None:
	global ok
	ok = False
	print(f"ÉCHEC  {msg}")


def atteignables(plan: Plan, depart: Case, fermees: set[Case] = frozenset()) -> set[Case]:
	bloquees = {c for p in plan.positions.values() if p.bloque for c in p.cells} | set(fermees)
	vus = {depart}
	file = deque([depart])
	while file:
		x, y = file.popleft()
		for dx, dy in DIRECTIONS:
			n = (x + dx, y + dy)
			if n in vus or not (0 <= n[0] < plan.width and 0 <= n[1] < plan.height):
				continue
			if n in bloquees or plan.at(*n) not in plan.praticables:
				continue
			vus.add(n)
			file.append(n)
	return vus


def voisin(zone: set[Case], c: Case) -> bool:
	return any((c[0] + dx, c[1] + dy) in zone for dx, dy in DIRECTIONS)


def verifier_arene() -> None:
	plan = lire(PLANS / "cramois_arene.txt")
	depart = plan.positions["depuis_ile"].cells[0]
	herses = {int(p.ident.split("_")[1]): set(p.cells) for p in plan.of_kind("herse")}
	machines = {int(p.ident.split("_")[1]): p for p in plan.of_kind("quiz")}
	dresseurs = {int(p.ident.rsplit("_", 1)[1]): p.cells[0] for p in plan.of_kind("dresseur")}
	auguste = plan.positions["auguste"].cells[0]
	if sorted(herses) != list(range(1, 7)) or sorted(machines) != list(range(1, 7)):
		echec("arène : il faut 6 herses et 6 machines")
		return
	for n in range(0, 7):
		fermees = set().union(*(herses[k] for k in range(n + 1, 7)))
		zone = atteignables(plan, depart, fermees)
		for k, m in machines.items():
			dessous = (m.cells[0][0], m.cells[0][1] + 1)
			if (dessous in zone) != (k <= n + 1):
				echec(f"arène, herses 1..{n} ouvertes : machine {k} {'inatteignable' if k <= n + 1 else 'déjà atteignable'}")
			if not plan.at(*dessous) in plan.praticables:
				echec(f"arène : la machine {k} ne se lit pas depuis {dessous}")
			d = dresseurs[k + 1]
			if voisin(zone, d) != (k <= n + 1):
				echec(f"arène, herses 1..{n} ouvertes : Dresseur {k + 1} {'inatteignable' if k <= n + 1 else 'déjà atteignable'}")
		if voisin(zone, dresseurs[1]) != (n >= 1):
			echec(f"arène, herses 1..{n} ouvertes : Dresseur 1 mal placé")
		if voisin(zone, auguste) != (n == 6):
			echec(f"arène, herses 1..{n} ouvertes : Auguste {'atteignable trop tôt' if n < 6 else 'inatteignable'}")
	# 4. une herse fermée seule coupe la suite
	for k in range(1, 7):
		zone = atteignables(plan, depart, herses[k])
		if voisin(zone, auguste):
			echec(f"arène : la herse {k} se contourne")
	if ok:
		print("ok     arène : ordre Q1 → P1 → … → Q6 → P6 → Auguste respecté, aucune herse contournable")


def verifier_interieur(fichier: str, entree: str = "entree") -> None:
	plan = lire(PLANS / fichier)
	zone = atteignables(plan, plan.positions[entree].cells[0])
	manquants = [p.ident for p in plan.positions.values()
		if p.bloque and not any(voisin(zone, c) for c in p.cells)
		or not p.bloque and not any(c in zone or voisin(zone, c) for c in p.cells)]
	if manquants:
		echec(f"{fichier} : inatteignables {manquants}")
	else:
		print(f"ok     {fichier} : {len(plan.positions)} positions atteignables")


def verifier_labo() -> None:
	hall = lire(PLANS / "cramois_labo.txt")
	for p in hall.of_kind("warp"):
		vers = p.attrs.get("vers", "")
		if vers.startswith("cinnabar_lab_"):
			salle = lire(PLANS / f"cramois_labo_{vers.removeprefix('cinnabar_lab_')}.txt")
			if salle.positions["sortie"].attrs.get("vers") != "cinnabar_lab":
				echec(f"{vers} : la sortie ne ramène pas au hall")
			if hall.at(*p.cells[0]) != "D":
				echec(f"hall : {p.ident} n'est pas sur une porte D")
	for f in ("cramois_labo.txt", "cramois_labo_reunion.txt", "cramois_labo_recherche.txt",
			"cramois_labo_test.txt", "argenta_musee_reserve.txt"):
		verifier_interieur(f)


if __name__ == "__main__":
	verifier_arene()
	verifier_labo()
	sys.exit(0 if ok else 1)
