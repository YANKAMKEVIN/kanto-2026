#!/usr/bin/env python3
"""Vérifie les grilles du jalon JOH1 (Chapitre Johto, dossier docs/design/dossier-joh-02-oliville.md).

Grilles : `tools/plans/grotte_marine_1.txt`, `grotte_marine_2.txt` (30 × 40) et `oliville.txt`
(50 × 40). Lecture par `plan_grille.lire` ; déplacements propres à ce contrôle : 4 directions, eau
(w, d) et courants (> v) accessibles en Surf depuis la terre et inversement, une case de courant
pousse dans son sens jusqu'à la première case sans courant ; positions `bloque` bloquantes.

Grotte 1 : taille ; entrée nord de 4 cases d'eau ; sortie sud jointe à la salle 2 (mêmes colonnes) ;
la Perle et la sortie atteignables depuis l'entrée.
Grotte 2 : taille ; raccord nord ; acte 1 : la plage et la sortie atteignables depuis le nord, le
nord INatteignable depuis la plage (courant) ; acte 2 (courant calme) : les deux sens ; le Rappel
Max et la rangée de l'ombre de Lugia atteignables.
Oliville : taille ; toutes les cases praticables connexes (en Surf compris) ; portes, sortie est,
bouche de la grotte et bord sud (Route 40) atteignables depuis l'arrivée de la grotte ; aucune
autre ouverture sur le pourtour ; le garde ne bloque pas l'avenue une fois rangé.

Usage : python3 tools/art/plan_check_joh1.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
EAU = set("wd")
COURANTS = {">": (1, 0), "<": (-1, 0), "v": (0, 1), "^": (0, -1)}
DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1))

echecs: list[str] = []


def verifie(cond: bool, message: str) -> None:
	print(("  ok   " if cond else "  ÉCHEC ") + message)
	if not cond:
		echecs.append(message)


def bloquees(plan) -> set[tuple[int, int]]:
	return {c for p in plan.positions.values() if p.bloque for c in p.cells}


def atteignables(plan, depart, courants_actifs: bool = True, retirer: set | None = None) -> set:
	bloc = bloquees(plan) - (retirer or set())

	def libre(x, y):
		return 0 <= x < plan.width and 0 <= y < plan.height \
			and plan.at(x, y) in plan.praticables and (x, y) not in bloc

	vus = set(c for c in depart if libre(*c))
	file = deque(vus)
	while file:
		x, y = file.popleft()
		c = plan.at(x, y)
		if courants_actifs and c in COURANTS:
			dirs = (COURANTS[c],)
		else:
			dirs = DIRS
		for dx, dy in dirs:
			n = (x + dx, y + dy)
			if libre(*n) and n not in vus:
				vus.add(n)
				file.append(n)
	return vus


def cases(plan, ident):
	return plan.positions[ident].cells


def grotte_1() -> None:
	print("grotte_marine_1")
	p = lire(PLANS / "grotte_marine_1.txt")
	verifie((p.width, p.height) == (30, 40), "taille 30 × 40")
	entree = cases(p, "warp_nord")
	verifie(len(entree) == 4 and all(p.at(x, y) == "w" for x, y in entree), "entrée nord : 4 cases d'eau")
	r = atteignables(p, entree)
	verifie(all(c in r for c in cases(p, "warp_sud")), "sortie sud atteignable")
	verifie(cases(p, "objet_perle")[0] in r, "Perle atteignable")
	q = lire(PLANS / "grotte_marine_2.txt")
	verifie([x for x, _ in cases(p, "warp_sud")] == [x for x, _ in cases(q, "warp_nord")],
		"raccord salle 1 ↔ salle 2 sur les mêmes colonnes")


def grotte_2() -> None:
	print("grotte_marine_2")
	p = lire(PLANS / "grotte_marine_2.txt")
	verifie((p.width, p.height) == (30, 40), "taille 30 × 40")
	nord, sortie = cases(p, "warp_nord"), cases(p, "warp_sud")
	r1 = atteignables(p, nord)
	verifie(all(c in r1 for c in sortie), "acte 1 : sortie vers Oliville atteignable depuis le nord")
	retour1 = atteignables(p, cases(p, "from_olivine_city"))
	verifie(not any(c in retour1 for c in nord), "acte 1 : le nord est inatteignable depuis la plage (courant)")
	retour2 = atteignables(p, cases(p, "from_olivine_city"), courants_actifs=False)
	verifie(all(c in retour2 for c in nord), "acte 2 : courant calme, la grotte se traverse dans les deux sens")
	verifie(cases(p, "objet_rappel_max")[0] in r1, "Rappel Max atteignable")
	verifie(all(c in r1 for c in cases(p, "ombre_lugia")), "rangée de l'ombre de Lugia atteignable")


def oliville() -> None:
	print("oliville")
	p = lire(PLANS / "oliville.txt")
	verifie((p.width, p.height) == (50, 40), "taille 50 × 40")
	depart = cases(p, "from_sea_cave")
	r = atteignables(p, depart)
	bloc = bloquees(p)
	toutes = {(x, y) for y in range(p.height) for x in range(p.width)
		if p.at(x, y) in p.praticables and (x, y) not in bloc}
	verifie(toutes <= r, f"toutes les cases praticables connexes ({len(toutes - r)} isolées)")
	for ident in ("porte_centre", "porte_boutique", "porte_maison_1", "porte_maison_2",
			"warp_est", "warp_grotte", "warp_sud_mer"):
		verifie(all(c in r for c in cases(p, ident)), f"{ident} atteignable")
	ouvertures = set(cases(p, "warp_est")) | set(cases(p, "warp_sud_mer")) | set(cases(p, "warp_grotte"))
	bord = {c for c in toutes if c[0] in (0, p.width - 1) or c[1] in (0, p.height - 1)}
	verifie(bord <= ouvertures, f"aucune autre ouverture sur le pourtour ({sorted(bord - ouvertures)[:5]})")
	garde = set(cases(p, "garde_est"))
	verifie(all(c in r for c in cases(p, "warp_est")),
		"le garde (PNJ) laisse l'avenue ouverte ; la barrière est un déclencheur")
	verifie(p.at(47, 19) in p.praticables and (47, 19) not in garde,
		"case de rangement du garde (47, 19) praticable, hors de l'avenue")


def main() -> int:
	grotte_1()
	grotte_2()
	oliville()
	print("JOH1 : " + ("tout est bon" if not echecs else f"{len(echecs)} échec(s)"))
	return 1 if echecs else 0


if __name__ == "__main__":
	sys.exit(main())
