#!/usr/bin/env python3
"""Vérifie les grilles du Manoir Pokémon (jalon 25, dossier 28 §4.5).

Lit `tools/plans/manoir_1f.txt`, `_2f`, `_3f`, `_b1f` et explore l'espace des états
(étage, case, interrupteur) : marche sur 4 directions, escaliers (case `U` / `V` → spawn de même
`paire` sur l'étage `vers`), trous (case `O` → spawn `arrivee` de l'étage `vers`), statues
(Action depuis la case sous la statue : l'interrupteur global bascule). Portes : `a` ouverte
seulement sur MARCHE, `b` seulement sur ARRÊT. Départ : porte principale, interrupteur sur ARRÊT
(il y est remis à chaque entrée depuis Cramois'Île).

Critères :
  1. structure : escaliers appariés, spawns d'arrivée praticables, trous sur `O` et arrivées
     praticables, sorties sur `E` ;
  2. la Clé Secrète (objet `item=secret_key`) est atteignable depuis l'entrée ;
  3. **anti-blocage** : depuis tout état atteignable, une sortie est atteignable ;
  4. sans toucher aux statues, ni la Clé ni le B1F ne sont atteignables (puzzle nécessaire) ;
  5. au plus un Dresseur **inévitable** par étage (un Dresseur est inévitable si, sans entrer
     dans son champ de vision, on ne peut plus prendre la Clé puis ressortir) ;
  6. objets, journaux et statues accessibles (une case voisine atteignable ; statue : la case
     du dessous).

Usage : python3 tools/art/plan_check_manoir.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
ETAGES = {
	"pokemon_mansion_1f": "manoir_1f.txt",
	"pokemon_mansion_2f": "manoir_2f.txt",
	"pokemon_mansion_3f": "manoir_3f.txt",
	"pokemon_mansion_b1f": "manoir_b1f.txt",
}
ENTREE = ("pokemon_mansion_1f", "depuis_ile")
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
VUE = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
Case = tuple[int, int]
Etat = tuple[str, int, int, int]


class Manoir:
	def __init__(self) -> None:
		self.plans: dict[str, Plan] = {m: lire(RACINE / "tools" / "plans" / f) for m, f in ETAGES.items()}
		self.bloquees: dict[str, set[Case]] = {}
		for m, plan in self.plans.items():
			self.bloquees[m] = {c for p in plan.positions.values() if p.bloque for c in p.cells}
		self.interdites: dict[str, set[Case]] = {m: set() for m in self.plans}

	def spawn(self, carte: str, ident: str) -> Case:
		return self.plans[carte].positions[ident].cells[0]

	def spawn_paire(self, carte: str, paire: str) -> Case | None:
		for p in self.plans[carte].of_kind("spawn"):
			if p.attrs.get("paire") == paire:
				return p.cells[0]
		return None

	def libre(self, carte: str, c: Case, inter: int) -> bool:
		plan = self.plans[carte]
		x, y = c
		if not (0 <= x < plan.width and 0 <= y < plan.height):
			return False
		if c in self.bloquees[carte] or c in self.interdites[carte]:
			return False
		ch = plan.at(x, y)
		if ch == "a":
			return inter == 1
		if ch == "b":
			return inter == 0
		return ch in plan.praticables

	def passage(self, carte: str, c: Case) -> tuple[str, Case] | None:
		"""Escalier ou trou sur la case c : (carte d'arrivée, case d'arrivée)."""
		plan = self.plans[carte]
		for p in plan.of_kind("escalier"):
			if p.cells[0] == c:
				vers = p.attrs["vers"]
				return vers, self.spawn_paire(vers, p.attrs["paire"])
		for p in plan.of_kind("trou"):
			if p.cells[0] == c:
				vers = p.attrs["vers"]
				return vers, self.spawn(vers, p.attrs["arrivee"])
		return None

	def statue_au_dessus(self, carte: str, c: Case) -> bool:
		au_dessus = (c[0], c[1] - 1)
		return any(p.cells[0] == au_dessus for p in self.plans[carte].of_kind("statue"))

	def voisins(self, e: Etat, statues: bool = True):
		carte, x, y, inter = e
		if statues and self.statue_au_dessus(carte, (x, y)):
			yield (carte, x, y, 1 - inter)
		for dx, dy in DIRECTIONS:
			n = (x + dx, y + dy)
			if not self.libre(carte, n, inter):
				continue
			arrivee = self.passage(carte, n)
			if arrivee is not None:
				yield (arrivee[0], arrivee[1][0], arrivee[1][1], inter)
			else:
				yield (carte, n[0], n[1], inter)

	def explorer(self, depart: list[Etat], statues: bool = True) -> set[Etat]:
		vus = set(depart)
		file = deque(depart)
		while file:
			e = file.popleft()
			for n in self.voisins(e, statues):
				if n not in vus:
					vus.add(n)
					file.append(n)
		return vus

	def sortie(self, e: Etat) -> bool:
		carte, x, y, _ = e
		return carte == "pokemon_mansion_1f" and self.plans[carte].at(x, y) == "E"

	def depart(self) -> Etat:
		c = self.spawn(*ENTREE)
		return (ENTREE[0], c[0], c[1], 0)

	def cle(self) -> tuple[str, Case]:
		for m, plan in self.plans.items():
			for p in plan.of_kind("objet_visible"):
				if p.attrs.get("item") == "secret_key":
					return m, p.cells[0]
		raise ValueError("Clé Secrète absente des grilles")

	def pres_de(self, etats: set[Etat], carte: str, c: Case) -> bool:
		return any(e[0] == carte and abs(e[1] - c[0]) + abs(e[2] - c[1]) == 1 for e in etats)


def champ_de_vision(m: Manoir, carte: str, p) -> set[Case]:
	portee = int(p.attrs.get("sight", "0"))
	if portee <= 0:
		return set()
	dx, dy = VUE[p.attrs.get("facing", "down")]
	x, y = p.cells[0]
	cases: set[Case] = set()
	for _ in range(portee):
		x, y = x + dx, y + dy
		plan = m.plans[carte]
		if not (0 <= x < plan.width and 0 <= y < plan.height) or plan.at(x, y) == "#":
			break
		cases.add((x, y))
	return cases


def cle_puis_sortie(m: Manoir) -> bool:
	carte_cle, case_cle = m.cle()
	atteints = m.explorer([m.depart()])
	pres = [e for e in atteints if e[0] == carte_cle and abs(e[1] - case_cle[0]) + abs(e[2] - case_cle[1]) == 1]
	if not pres:
		return False
	return any(m.sortie(e) for e in m.explorer(pres))


def verifier() -> bool:
	m = Manoir()
	ok = True

	def echec(msg: str) -> None:
		nonlocal ok
		ok = False
		print(f"ÉCHEC  {msg}")

	# 1. structure
	for carte, plan in m.plans.items():
		for p in plan.of_kind("escalier"):
			vers = p.attrs.get("vers")
			if vers not in m.plans:
				echec(f"{carte} {p.ident} : vers={vers} inconnu")
				continue
			if plan.at(*p.cells[0]) not in "UV":
				echec(f"{carte} {p.ident} : pas sur une case U/V")
			if not any(q.attrs.get("paire") == p.attrs["paire"] for q in m.plans[vers].of_kind("escalier")):
				echec(f"{carte} {p.ident} : pas d'escalier de paire {p.attrs['paire']} sur {vers}")
			arrivee = m.spawn_paire(vers, p.attrs["paire"])
			if arrivee is None or not m.libre(vers, arrivee, 0) and not m.libre(vers, arrivee, 1):
				echec(f"{carte} {p.ident} : arrivée absente ou bloquée sur {vers}")
		for p in plan.of_kind("trou"):
			if plan.at(*p.cells[0]) != "O":
				echec(f"{carte} {p.ident} : pas sur une case O")
			vers, arrivee = p.attrs["vers"], m.spawn(p.attrs["vers"], p.attrs["arrivee"])
			if m.plans[vers].at(*arrivee) != ".":
				echec(f"{carte} {p.ident} : arrivée {arrivee} sur {vers} n'est pas un plancher ordinaire")
	sorties = m.plans["pokemon_mansion_1f"].cells_of("E")
	print(f"ok     structure : {sum(len(p.of_kind('escalier')) for p in m.plans.values())} escaliers, "
		f"{len(m.plans['pokemon_mansion_3f'].of_kind('trou'))} trous, {len(sorties)} cases de sortie")

	# 2. Clé atteignable
	atteints = m.explorer([m.depart()])
	carte_cle, case_cle = m.cle()
	if m.pres_de(atteints, carte_cle, case_cle):
		print(f"ok     Clé Secrète atteignable ({carte_cle} {case_cle}) ; {len(atteints)} états atteignables")
	else:
		echec("Clé Secrète inatteignable")

	# 3. anti-blocage
	vers_sortie = {e for e in atteints if m.sortie(e)}
	# exploration inverse : états d'où l'on atteint une sortie (graphe orienté à cause des trous)
	pred: dict[Etat, list[Etat]] = {}
	for e in atteints:
		for n in m.voisins(e):
			pred.setdefault(n, []).append(e)
	bons = set(vers_sortie)
	file = deque(vers_sortie)
	while file:
		e = file.popleft()
		for p in pred.get(e, []):
			if p not in bons:
				bons.add(p)
				file.append(p)
	bloques = atteints - bons
	if bloques:
		echec(f"{len(bloques)} états sans retour vers la sortie, ex. {sorted(bloques)[:5]}")
	else:
		print("ok     anti-blocage : aucun état atteignable sans retour vers la sortie")

	# 4. puzzle nécessaire
	sans = m.explorer([m.depart()], statues=False)
	if m.pres_de(sans, carte_cle, case_cle) or any(e[0] == "pokemon_mansion_b1f" for e in sans):
		echec("la Clé ou le B1F est atteignable sans toucher aux statues")
	else:
		print("ok     puzzle nécessaire : ni la Clé ni le B1F sans les statues")

	# 5. Dresseurs inévitables
	for carte, plan in m.plans.items():
		inevitables = []
		for p in plan.of_kind("dresseur"):
			champ = champ_de_vision(m, carte, p)
			if not champ:
				continue
			m.interdites[carte] = champ
			if not cle_puis_sortie(m):
				inevitables.append(p.ident)
			m.interdites[carte] = set()
		if len(inevitables) > 1:
			echec(f"{carte} : {len(inevitables)} Dresseurs inévitables {inevitables}")
		else:
			print(f"ok     {carte} : Dresseurs inévitables {inevitables or 'aucun'}")

	# 6. accès aux objets, journaux, statues
	for carte, plan in m.plans.items():
		for p in plan.of_kind("objet_visible") + plan.of_kind("journal"):
			if not m.pres_de(atteints, carte, p.cells[0]):
				echec(f"{carte} {p.ident} inaccessible")
		for p in plan.of_kind("objet_cache"):
			c = p.cells[0]
			if not any(e[0] == carte and (e[1], e[2]) == c for e in atteints) and not m.pres_de(atteints, carte, c):
				echec(f"{carte} {p.ident} inaccessible")
		for p in plan.of_kind("statue"):
			dessous = (p.cells[0][0], p.cells[0][1] + 1)
			if not any(e[0] == carte and (e[1], e[2]) == dessous for e in atteints):
				echec(f"{carte} {p.ident} : case du dessous inatteignable")
	print("ok     accès aux objets, journaux et statues vérifié" if ok else "")
	return ok


if __name__ == "__main__":
	sys.exit(0 if verifier() else 1)
