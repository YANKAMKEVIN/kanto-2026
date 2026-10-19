#!/usr/bin/env python3
"""Contrôle des grilles du jalon 23 (dossier 26) : Parc Safari, Porte, maisons, Arène de Koga.

Lancé à part (comme `plan_check_azuria_j14.py`) :
        python3 tools/art/plan_check_safari.py            (code 1 si un critère échoue)

Mêmes règles de déplacement que `plan_check.py` (4 directions, cases de PRATICABLES, positions
`bloque` bloquantes ; pas de rebord dans ces cartes). Critères :

**Parc** (`safari_centre`, `safari_est`, `safari_nord`, `safari_ouest`, `safari_porte`) :
  1. chaque raccord a un vis-à-vis réciproque (mêmes cases, dans l'autre carte) ;
  2. toute herbe haute « h » est atteignable depuis la Porte ; aucune case « n » n'est praticable ;
  3. chaque objet visible, objet caché et panneau a une case voisine atteignable ;
  4. **une visite suffit** (dossier 26 §2.2, N-3) : pas comptés depuis le passage nord de la Porte
     jusqu'à la Maison Secrète (entrée et sortie comprises), puis jusqu'à une case voisine des
     Dents d'Or : ≤ 300 ; le rapport donne aussi le retour à la Porte (pour information : la fin
     de visite ramène le joueur à la Porte, le retour à pied n'est pas nécessaire) ;
  5. les maisons de chaque zone mènent à `safari_maison_repos` / `safari_maison_secrete`.

**Maison du Gardien** (`parmanie_maison_gardien`) : pour chaque position atteignable du rocher
(une poussée depuis chaque côté libre, règle de Force : la case d'arrivée doit être du sol libre),
la case devant la porte reste libre, le rocher ne touche ni la porte ni le Gardien, et la case
de lecture du Super Bonbon (11, 3) devient atteignable après une poussée.

**Arène** (`parmanie_arene`) : la case devant Koga est atteignable depuis l'entrée ; tous les
Dresseurs sont atteignables (une case voisine) ; rapport des Dresseurs **inévitables** (tout chemin
entrée → Koga traverse leur ligne de vue, arrêtée par les cases bloquées) ; nombre de murs
invisibles « i ».
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
DIRS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
ZONES = ["safari_centre", "safari_est", "safari_nord", "safari_ouest"]
Case = tuple[int, int]
erreurs: list[str] = []


def verifier(cond: bool, message: str) -> None:
	print(("  ok   " if cond else "  ÉCHEC ") + message)
	if not cond:
		erreurs.append(message)


def bloquees(plan: Plan, sauf: set[str] = frozenset()) -> set[Case]:
	b: set[Case] = set()
	for p in plan.positions.values():
		if p.bloque and p.ident not in sauf:
			b.update(p.cells)
	return b


def libre(plan: Plan, c: Case, bl: set[Case]) -> bool:
	x, y = c
	return 0 <= x < plan.width and 0 <= y < plan.height and c not in bl and plan.at(x, y) in plan.praticables


def distances(plan: Plan, departs: list[Case], bl: set[Case] | None = None) -> dict[Case, int]:
	bl = bloquees(plan) if bl is None else bl
	dist = {c: 0 for c in departs if libre(plan, c, bl)}
	file = deque(dist)
	while file:
		x, y = file.popleft()
		for dx, dy in DIRS.values():
			n = (x + dx, y + dy)
			if n not in dist and libre(plan, n, bl):
				dist[n] = dist[(x, y)] + 1
				file.append(n)
	return dist


def voisines(c: Case) -> list[Case]:
	return [(c[0] + dx, c[1] + dy) for dx, dy in DIRS.values()]


def cible(texte: str) -> tuple[str, list[Case]]:
	carte, _, cases = texte.partition(":")
	if not cases:
		return carte, []
	xs, ys = cases.split(",")

	def plage(t: str) -> list[int]:
		if ".." in t:
			a, b = t.split("..")
			return list(range(int(a), int(b) + 1))
		return [int(t)]

	return carte, [(x, y) for y in plage(ys) for x in plage(xs)]


def parc() -> None:
	print("Parc Safari")
	plans = {n: lire(PLANS / f"{n}.txt") for n in ZONES + ["safari_porte"]}
	# 1. raccords réciproques
	for nom, plan in plans.items():
		for p in plan.of_kind("raccord"):
			carte, cases = cible(p.attrs["vers"])
			autre = plans.get(carte)
			ok = autre is not None and any(
				q.kind == "raccord" and set(q.cells) == set(cases) and cible(q.attrs["vers"]) == (nom, sorted(p.cells, key=lambda c: (c[1], c[0])))
				or (q.kind == "raccord" and set(q.cells) == set(cases) and cible(q.attrs["vers"])[0] == nom and set(cible(q.attrs["vers"])[1]) == set(p.cells))
				for q in autre.positions.values())
			verifier(ok, f"{nom} : raccord {p.ident} ↔ {p.attrs['vers']} réciproque")
	# 2. et 3. atteignabilité depuis le passage nord de la Porte, à travers les quatre zones (dans
	# RB, la moitié nord du Centre ne s'atteint que par l'Ouest et le Nord : point fixe sur les raccords)
	depart = plans["safari_centre"].positions["arrivee_porte"].cells
	entrees: dict[str, set[Case]] = {n: set() for n in ZONES}
	entrees["safari_centre"].update(depart)
	atteint: dict[str, dict[Case, int]] = {}
	change = True
	while change:
		change = False
		for nom in ZONES:
			if not entrees[nom]:
				continue
			atteint[nom] = distances(plans[nom], sorted(entrees[nom]))
			for p in plans[nom].of_kind("raccord"):
				if any(c in atteint[nom] for c in p.cells):
					carte, cases = cible(p.attrs["vers"])
					if carte in ZONES and not set(cases) <= entrees[carte]:
						entrees[carte].update(cases)
						change = True
	verifier(set(atteint) == set(ZONES), "les quatre zones sont atteignables depuis la Porte")
	for nom in ZONES:
		plan, dist = plans[nom], atteint.get(nom, {})
		herbes = plan.cells_of("h")
		perdues = [c for c in herbes if c not in dist and c not in bloquees(plan)]
		verifier(not perdues, f"{nom} : {len(herbes)} cases d'herbe, toutes atteignables {perdues[:5]}")
		verifier("n" not in plan.praticables, f"{nom} : « n » n'est pas praticable")
		for p in plan.positions.values():
			if p.kind in ("objet_visible", "objet_cache", "panneau"):
				ok = any(v in dist for c in p.cells for v in voisines(c))
				verifier(ok, f"{nom} : {p.kind} {p.ident} {p.cells[0]} atteignable")
		for p in plan.of_kind("porte"):
			verifier(p.attrs["vers"] in ("safari_maison_repos", "safari_maison_secrete") and p.cells[0] in dist,
				f"{nom} : porte {p.ident} atteignable, vers {p.attrs['vers']}")
	# 4. budget de pas (une visite suffit)
	budget = pas_visite(plans)
	verifier(budget[0] <= 300, f"Porte → Maison Secrète → Dents d'Or : {budget[0]} pas (≤ 300) ; "
		f"retour à la Porte : +{budget[1]} (total {budget[0] + budget[1]} sur 500)")


def pas_entre(plans: dict[str, Plan], carte_dep: str, dep: list[Case], carte_but: str, but: list[Case]) -> int:
	"""Plus court chemin multi-cartes (Dijkstra sur les raccords) ; franchir un raccord = un pas."""
	import heapq
	tas = [(0, carte_dep, tuple(dep))]
	vus: set[tuple[str, tuple]] = set()
	while tas:
		cout, carte, cases = heapq.heappop(tas)
		if (carte, cases) in vus:
			continue
		vus.add((carte, cases))
		plan = plans[carte]
		dist = distances(plan, list(cases))
		if carte == carte_but:
			d = [dist[c] for c in but if c in dist]
			if d:
				return cout + min(d)
		for p in plan.of_kind("raccord"):
			d = [dist[c] for c in p.cells if c in dist]
			arr, cases_arr = cible(p.attrs["vers"])
			if d and arr in ZONES:
				heapq.heappush(tas, (cout + min(d) + 1, arr, tuple(cases_arr)))
	return 10 ** 9


def pas_visite(plans: dict[str, Plan]) -> tuple[int, int]:
	porte_parc = plans["safari_centre"].positions["arrivee_porte"].cells
	ouest = plans["safari_ouest"]
	maison = ouest.positions["porte_maison_secrete"].cells
	sortie = ouest.positions["arrivee_maison_secrete"].cells
	dents = ouest.positions["dents_or"].cells[0]
	a = 1 + pas_entre(plans, "safari_centre", porte_parc, "safari_ouest", maison)  # 1 : passage nord → parc
	interieur = 2 * 3  # entrée (5..6, 7) → devant le Pêcheur (5, 5) et retour, dans la Maison Secrète
	b = 1 + pas_entre(plans, "safari_ouest", sortie, "safari_ouest", [v for v in voisines(dents)])
	c = pas_entre(plans, "safari_ouest", [v for v in voisines(dents) if v in distances(ouest, sortie)],
		"safari_centre", plans["safari_centre"].positions["raccord_porte"].cells)
	return a + interieur + b, c


def gardien() -> None:
	print("Maison du Gardien")
	plan = lire(PLANS / "parmanie_maison_gardien.txt")
	rocher = plan.positions["rocher"].cells[0]
	porte = set(plan.positions["sortie"].cells)
	devant = (7, 7)
	gardien_c = plan.positions["gardien"].cells[0]
	lecture = (11, 3)
	base = bloquees(plan, {"rocher"})
	positions = {rocher}
	acces = distances(plan, plan.positions["entree"].cells, base | {rocher})
	for d in DIRS.values():
		pousse_depuis = (rocher[0] - d[0], rocher[1] - d[1])
		arrivee = (rocher[0] + d[0], rocher[1] + d[1])
		if pousse_depuis in acces and libre(plan, arrivee, base):
			positions.add(arrivee)
	verifier(len(positions) > 1, f"le rocher (11, 3) peut être poussé : positions {sorted(positions)}")
	for r in positions:
		verifier(r != devant and r not in porte, f"rocher en {r} : la case devant la porte {devant} reste libre")
		verifier(all(v not in porte and v != gardien_c for v in voisines(r)), f"rocher en {r} : ne touche ni la porte ni le Gardien")
		if r != rocher:
			ok = lecture in distances(plan, plan.positions["entree"].cells, base | {r})
			verifier(ok, f"rocher en {r} : le Super Bonbon se lit depuis {lecture}")
	verifier(lecture not in distances(plan, plan.positions["entree"].cells, base | {rocher}),
		"rocher en place (J23) : le Super Bonbon est hors d'atteinte")


def arene() -> None:
	print("Arène de Koga")
	plan = lire(PLANS / "parmanie_arene.txt")
	entree = plan.positions["entree"].cells
	koga = plan.positions["koga"]
	devant_koga = (koga.cells[0][0], koga.cells[0][1] + 1)
	bl = bloquees(plan)
	dist = distances(plan, entree, bl)
	verifier(devant_koga in dist, f"la case devant Koga {devant_koga} est atteignable ({dist.get(devant_koga)} pas)")
	verifier(len(plan.cells_of("i")) > 0, f"{len(plan.cells_of('i'))} murs invisibles « i »")
	for p in plan.of_kind("dresseur"):
		verifier(any(v in dist for v in voisines(p.cells[0])), f"dresseur {p.ident} atteignable")
	# inévitables : retirer la ligne de vue et voir si Koga reste atteignable
	for p in plan.of_kind("dresseur"):
		d = DIRS[p.attrs["facing"]]
		vue: set[Case] = set()
		c = p.cells[0]
		for _ in range(int(p.attrs["sight"])):
			c = (c[0] + d[0], c[1] + d[1])
			if not libre(plan, c, bl):
				break
			vue.add(c)
		evitable = devant_koga in distances(plan, entree, bl | vue)
		print(f"  info {p.ident} : {'évitable' if evitable else 'INÉVITABLE'} (vue {sorted(vue)})")


def main() -> int:
	parc()
	gardien()
	arene()
	print(f"\n{len(erreurs)} échec(s)")
	return 1 if erreurs else 0


if __name__ == "__main__":
	sys.exit(main())
