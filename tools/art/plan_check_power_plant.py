#!/usr/bin/env python3
"""Vérifie la grille de la Centrale (jalon 32, lot 32G, N-11 ; `tools/plans/power_plant.txt`).

Relevé 1:1 de Rouge/Bleu (`power_plant_rb_decode.py`). Règles : 4 directions, à pied seulement
(aucune eau dans l'usine) ; praticables `. E O` ; les positions `bloque` (Électhor, fausses
Poké Balls, objets) occupent leur case ; une fausse Poké Ball battue libère sa case (RB).

Critères :
  1. grille 40 × 36, caractères `# . E O x` seulement ; deux portes (E au sud, O à l'ouest) ;
  2. depuis l'arrivée sud, sans battre aucune fausse Poké Ball : Électhor, chaque objet visible et
     chaque fausse Poké Ball se touchent depuis une case de sol voisine, la porte ouest est atteinte ;
  3. chaque objet caché se prend depuis sa case, voisine de son indice `x`, atteinte ;
  4. en libérant toutes les fausses Poké Balls : tout le sol est atteint (aucune poche orpheline) ;
  5. chemin le plus court entrée → Électhor imprimé (pas).

Usage : python3 -I tools/art/plan_check_power_plant.py [grille]   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
GRILLE = RACINE / "tools" / "plans" / "power_plant.txt"
LARGEUR, HAUTEUR = 40, 36
LEGENDE = set("#.EOx")
PRATICABLES = set(".EO")
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]


def _distances(plan, depart, bloquees) -> dict:
	dist = {c: 0 for c in depart}
	file = deque(depart)
	while file:
		x, y = file.popleft()
		for dx, dy in DIRECTIONS:
			n = (x + dx, y + dy)
			if not (0 <= n[0] < plan.width and 0 <= n[1] < plan.height) or n in dist:
				continue
			if plan.at(*n) in PRATICABLES and n not in bloquees:
				dist[n] = dist[(x, y)] + 1
				file.append(n)
	return dist


def verifier_power_plant(chemin: Path = GRILLE) -> bool:
	plan = lire(chemin)
	erreurs: list[str] = []
	if (plan.width, plan.height) != (LARGEUR, HAUTEUR):
		erreurs.append(f"taille {plan.width} × {plan.height}, {LARGEUR} × {HAUTEUR} attendue")
	cars = {plan.at(x, y) for y in range(plan.height) for x in range(plan.width)}
	if not cars <= LEGENDE:
		erreurs.append(f"caractères hors légende : {sorted(cars - LEGENDE)}")
	bloquees = {c for p in plan.positions.values() if p.bloque for c in p.cells}
	leurres = {c for p in plan.of_kind("rencontre") if p.attrs.get("leurre") for c in p.cells}
	depart = plan.of_kind("spawn")[0].cells
	dist = _distances(plan, depart, bloquees)

	def touche(c) -> bool:
		return any((c[0] + dx, c[1] + dy) in dist for dx, dy in DIRECTIONS)

	for p in plan.of_kind("rencontre") + plan.of_kind("objet"):
		if not touche(p.cells[0]):
			erreurs.append(f"{p.ident} {p.cells[0]} : hors d'atteinte")
	for p in plan.of_kind("objet_cache"):
		c = p.cells[0]
		if c not in dist:
			erreurs.append(f"{p.ident} {c} : case de prise hors d'atteinte")
		if not any(plan.at(c[0] + dx, c[1] + dy) == "x" for dx, dy in DIRECTIONS
				if 0 <= c[0] + dx < plan.width and 0 <= c[1] + dy < plan.height):
			erreurs.append(f"{p.ident} {c} : aucun indice x voisin")
	for p in plan.of_kind("warp"):
		if not all(c in dist for c in p.cells):
			erreurs.append(f"{p.ident} : porte hors d'atteinte")
	libre = _distances(plan, depart, bloquees - leurres)
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in PRATICABLES and (x, y) not in bloquees and (x, y) not in libre]
	if orphelines:
		erreurs.append(f"sol orphelin : {orphelines}")
	zapdos = plan.of_kind("rencontre")
	zapdos = [p for p in zapdos if p.attrs.get("espece") == "zapdos"]
	if zapdos:
		z = zapdos[0].cells[0]
		pas = min((dist[(z[0] + dx, z[1] + dy)] for dx, dy in DIRECTIONS
			if (z[0] + dx, z[1] + dy) in dist), default=None)
		print(f"  entrée → Électhor : {pas} pas")
	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in PRATICABLES)
	print(f"  {praticables} cases praticables, {len(leurres)} fausses Poké Balls, "
		f"{len(plan.of_kind('objet'))} objets, {len(plan.of_kind('objet_cache'))} cachés")
	for e in erreurs:
		print(f"  [ÉCHEC] {e}")
	print("Centrale : " + ("conforme." if not erreurs else f"{len(erreurs)} erreur(s)."))
	return not erreurs


if __name__ == "__main__":
	sys.exit(0 if verifier_power_plant(Path(sys.argv[1]) if len(sys.argv) > 1 else GRILLE) else 1)
