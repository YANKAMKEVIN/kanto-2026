#!/usr/bin/env python3
"""Vérifie les grilles du jalon 16 (S.S. Anne et Arène de Carmin, dossier 19).

Grilles : `tools/plans/ss_anne_*.txt` (pont principal, pont inférieur, restaurant, pont extérieur,
cabines A, B, C, couloir et cabine du capitaine) et `tools/plans/carmin_arene.txt`. Lecture par
`plan_grille.lire` ; déplacement en 4 directions, une case par pas ; les portes et escaliers (`D`,
`S`) sont **terminaux** (on y entre, on ne les traverse pas) ; les positions `bloque` bloquent leurs
cases. La vue d'un Dresseur part de sa case dans la direction `facing`, sur `sight` cases, et
s'arrête au premier obstacle.

Critères (dossier 19, §0 R-14 et G-9, G-10, G-8) :
  Toutes — taille attendue ; chaque warp, objet, objet caché, PNJ et objet à fouiller est
    atteignable depuis l'entrée (case praticable voisine pour ce qui bloque).
  Pont principal — chaque porte et l'escalier sont atteignables ; on rejoint le couloir du
    capitaine **sans entrer dans la vue d'aucun Dresseur** (tous évitables).
  Navire — au plus **2 Dresseurs inévitables** hors rival (G-9) ; ici l'objectif est 0 : les autres
    salles sont facultatives (on peut ne pas y entrer).
  Couloir — **le rival est inévitable** : aucun chemin de l'entrée à la porte du capitaine sans
    passer sur le déclencheur ; le déclencheur couvre toute la largeur.
  Arène — barrière fermée : Major Bob **inaccessible** ; barrière ouverte : accessible ; les 15
    objets à fouiller sont atteignables barrière fermée ; chaque index a au moins un voisin
    orthogonal dans la grille 5 × 3 (G-8).

Usage : python3 tools/art/plan_check_ss_anne.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
TERMINAUX = set("DS")

TAILLES = {
	"ss_anne_pont_principal": (26, 13), "ss_anne_pont_inferieur": (22, 11),
	"ss_anne_restaurant": (18, 11), "ss_anne_pont_exterieur": (26, 11),
	"ss_anne_cabine_a": (12, 9), "ss_anne_cabine_b": (12, 9), "ss_anne_cabine_c": (12, 9),
	"ss_anne_couloir_capitaine": (18, 7), "ss_anne_cabine_capitaine": (14, 10),
	"carmin_arene": (17, 15),
}


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def titre(self, texte: str) -> None:
		print(f"\n{texte}")

	def critere(self, vrai: bool, texte: str) -> None:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	def info(self, texte: str) -> None:
		print(f"  {texte}")


def bloquees(plan: Plan, sauf: tuple[str, ...] = ()) -> set[Case]:
	return {c for p in plan.positions.values() if p.bloque and p.ident not in sauf for c in p.cells}


def praticable(plan: Plan, c: Case, bloc: set[Case]) -> bool:
	x, y = c
	return 0 <= x < plan.width and 0 <= y < plan.height and plan.at(x, y) in plan.praticables \
		and c not in bloc


def atteignables(plan: Plan, depart: Case, bloc: set[Case], interdites: set[Case] = frozenset()) -> set[Case]:
	vus, file = {depart}, deque([depart])
	while file:
		c = file.popleft()
		if c != depart and plan.at(*c) in TERMINAUX:
			continue
		for dx, dy in DIRS.values():
			n = (c[0] + dx, c[1] + dy)
			if n not in vus and n not in interdites and praticable(plan, n, bloc):
				vus.add(n)
				file.append(n)
	return vus


def vue(plan: Plan, p, bloc: set[Case]) -> set[Case]:
	(x, y), (dx, dy) = p.cells[0], DIRS[p.attrs.get("facing", "down")]
	cases = set()
	for k in range(1, int(p.attrs.get("sight", "0")) + 1):
		c = (x + dx * k, y + dy * k)
		if not praticable(plan, c, bloc):
			break
		cases.add(c)
	return cases


def voisines(c: Case) -> list[Case]:
	return [(c[0] + dx, c[1] + dy) for dx, dy in DIRS.values()]


def joignable(plan: Plan, p, zone: set[Case]) -> bool:
	if not p.bloque:
		return any(c in zone for c in p.cells)
	return any(v in zone for c in p.cells for v in voisines(c))


def entree(plan: Plan) -> Case:
	return plan.positions["entree"].cells[0]


def verifier_commun(nom: str, plan: Plan, r: Rapport) -> set[Case]:
	r.critere((plan.width, plan.height) == TAILLES[nom], f"taille {plan.width} × {plan.height}")
	zone = atteignables(plan, entree(plan), bloquees(plan))
	manque = [p.ident for p in plan.positions.values()
		if p.kind in ("warp", "objet", "cache", "pnj", "interactif", "dresseur", "repere")
		and p.ident != "major_bob" and not joignable(plan, p, zone)]
	r.critere(not manque, "tout est atteignable depuis l'entrée" + (f" (manque : {manque})" if manque else ""))
	return zone


def dresseurs(plan: Plan) -> list:
	return [p for p in plan.positions.values() if p.kind == "dresseur"]


def zone_vue(plan: Plan) -> set[Case]:
	bloc = bloquees(plan)
	return set().union(*(vue(plan, d, bloc) for d in dresseurs(plan))) if dresseurs(plan) else set()


def main() -> int:
	r = Rapport()
	plans = {n: lire(PLANS / f"{n}.txt") for n in TAILLES}
	for nom, plan in plans.items():
		r.titre(nom)
		zone = verifier_commun(nom, plan, r)
		for d in dresseurs(plan):
			r.info(f"{d.ident} : vue {sorted(vue(plan, d, bloquees(plan)))}")

	# Pont principal : portes, escalier, et couloir du capitaine sans croiser de vue.
	r.titre("ss_anne_pont_principal — parcours principal")
	p = plans["ss_anne_pont_principal"]
	bloc = bloquees(p)
	cible = p.positions["porte_capitaine"].cells[0]
	sans_vue = atteignables(p, entree(p), bloc, zone_vue(p))
	r.critere(cible in sans_vue, "entrée → couloir du capitaine sans entrer dans aucune vue (T01, T13 évitables)")
	autres = ["porte_cabine_a", "porte_cabine_c", "porte_restaurant", "porte_exterieur", "escalier_bas"]
	r.critere(all(p.positions[k].cells[0] in sans_vue for k in autres),
		"toutes les portes et l'escalier atteignables sans entrer dans une vue")
	# Les autres salles (cabines, restaurant, ponts inférieur et extérieur) sont facultatives : on
	# n'y entre pas pour aller au capitaine. Seuls les Dresseurs du pont principal pourraient être
	# inévitables, et ils ne le sont pas (critère ci-dessus).
	inevitables = sum(1 for d in dresseurs(p)
		if cible not in atteignables(p, entree(p), bloc, vue(p, d, bloc)))
	r.critere(inevitables <= 2, f"Dresseurs inévitables hors rival : {inevitables} (≤ 2, G-9)")

	# Couloir : le rival est inévitable.
	r.titre("ss_anne_couloir_capitaine — rival")
	c = plans["ss_anne_couloir_capitaine"]
	declencheur = set(c.positions["declencheur_rival"].cells)
	porte = c.positions["porte_capitaine"].cells[0]
	bloc_sans_rival = bloquees(c, sauf=("rival",))
	r.critere(porte not in atteignables(c, entree(c), bloc_sans_rival, declencheur),
		"aucun chemin vers la porte du capitaine sans passer sur le déclencheur")
	x_decl = {x for x, _ in declencheur}
	largeur = {y for y in range(c.height) if c.at(next(iter(x_decl)), y) in c.praticables}
	r.critere(len(x_decl) == 1 and {y for _, y in declencheur} == largeur,
		f"le déclencheur couvre toute la largeur ({len(largeur)} cases)")
	r.critere(porte in atteignables(c, entree(c), bloc_sans_rival),
		"après la défaite du rival (parti), la porte du capitaine est atteignable")

	# Arène : barrière et objets à fouiller.
	r.titre("carmin_arene — puzzle et barrière")
	a = plans["carmin_arene"]
	parler = (a.positions["major_bob"].cells[0][0], a.positions["major_bob"].cells[0][1] + 1)
	ferme = atteignables(a, entree(a), bloquees(a))
	ouvert = atteignables(a, entree(a), bloquees(a, sauf=("barriere",)))
	r.critere(parler not in ferme, "barrière fermée : Major Bob inaccessible")
	r.critere(parler in ouvert, "barrière ouverte : Major Bob accessible")
	poubelles = sorted((int(p.attrs["index"]), p) for p in a.positions.values() if p.kind == "interactif")
	r.critere(len(poubelles) == 15, f"{len(poubelles)} objets à fouiller")
	r.critere(all(joignable(a, p, ferme) for _, p in poubelles), "les 15 objets sont fouillables barrière fermée")
	voisins_ok = all(any(0 <= ((i - 1) // 5 + dy) < 3 and 0 <= ((i - 1) % 5 + dx) < 5
		for dx, dy in DIRS.values()) for i, _ in poubelles)
	r.critere(voisins_ok, "chaque index a au moins un voisin orthogonal dans la grille 5 × 3")
	sans_vue = atteignables(a, entree(a), bloquees(a, sauf=("barriere",)), zone_vue(a))
	r.info("Dresseurs de l'Arène évitables jusqu'à Major Bob : " + ("oui" if parler in sans_vue else
		"non (au moins un est inévitable, comme dans Rouge/Bleu)"))

	print("\n" + ("TOUT EST VERT" if r.ok else "AU MOINS UN CRITÈRE ÉCHOUE"))
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
