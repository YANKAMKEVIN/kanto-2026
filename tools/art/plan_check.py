#!/usr/bin/env python3
"""Vérifie une grille fonctionnelle de la Route 2 par recherche de chemin (jalon 8, T0).

Mêmes règles de déplacement que `GridWorld` (game/world/grid_world.gd) : 4 directions, une case
de rebord ne s'entre que dans son sens (vers le sud) et fait atterrir sur la case suivante
(saut = un pas). Cases bloquées : tout caractère hors `. = h v D` et les positions `bloque`.

Critères (docs/tech/jalon-08.md §3, T0 ; repris par test_route_2 au T5) :
  1. la porte du poste est atteignable depuis l'entrée sud ;
  2. 5 ≤ cases de hautes herbes obligatoires ≤ 7, toutes dans H3 (H3 incontournable) ;
  3. H1 et H2 évitables (ensemble) sans allonger le minimum d'herbes ;
  4. H2 : la traversée est plus courte que le chemin sûr (globalement et entre les repères
     h2_sud → h2_nord) ;
  5. le rebord ne se monte pas et raccourcit le retour (globalement et entre les repères
     rebord_haut → rebord_bas) ;
  6. entrée sud = exactement 3 cases praticables sur la dernière rangée, en x 19–21, warps et
     spawns compris.
Zones H1, H2, H3 = composantes connexes de hautes herbes, du sud au nord.

Usage : python3 tools/art/plan_check.py [tools/plans/route_2.txt]   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import HERBES, PORTE, PRATICABLES, REBORD, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
SUD = (0, 1)
INF = 10 ** 9
Case = tuple[int, int]


class Monde:
	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset()) -> None:
		self.plan = plan
		self.bloquees = set(bloquees)
		for p in plan.positions.values():
			if p.bloque:
				self.bloquees.update(p.cells)

	def libre(self, c: Case) -> bool:
		x, y = c
		if not (0 <= x < self.plan.width and 0 <= y < self.plan.height):
			return False
		return c not in self.bloquees and self.plan.at(x, y) in PRATICABLES

	def entrer(self, c: Case, d: Case) -> bool:
		if not self.libre(c):
			return False
		return self.plan.at(*c) != REBORD or d == SUD

	def pas(self, c: Case, d: Case) -> Case | None:
		"""Case d'arrivée d'un pas (GridWorld.get_step_target), None si impossible."""
		suivante = (c[0] + d[0], c[1] + d[1])
		if not self.entrer(suivante, d):
			return None
		if self.plan.at(*suivante) != REBORD:
			return suivante
		atterrissage = (suivante[0] + d[0], suivante[1] + d[1])
		if not self.entrer(atterrissage, d) or self.plan.at(*atterrissage) == REBORD:
			return None
		return atterrissage

	def voisins(self, c: Case):
		for d in DIRECTIONS:
			n = self.pas(c, d)
			if n is not None:
				yield n

	def distances(self, departs: list[Case]) -> dict[Case, int]:
		dist = {c: 0 for c in departs}
		file = deque(departs)
		while file:
			c = file.popleft()
			for n in self.voisins(c):
				if n not in dist:
					dist[n] = dist[c] + 1
					file.append(n)
		return dist

	def herbes_min(self, departs: list[Case], compte) -> dict[Case, int]:
		"""0-1 BFS : nombre minimal de cases d'herbes (au sens de `compte`) traversées."""
		cout = {c: 0 for c in departs}
		file = deque(departs)
		while file:
			c = file.popleft()
			for n in self.voisins(c):
				k = cout[c] + (1 if compte(n) else 0)
				if k < cout.get(n, INF):
					cout[n] = k
					(file.append if k > cout[c] else file.appendleft)(n)
		return cout


def zones_herbes(plan: Plan) -> list[set[Case]]:
	restantes = set(plan.cells_of(HERBES))
	zones: list[set[Case]] = []
	while restantes:
		germe = restantes.pop()
		zone, file = {germe}, [germe]
		while file:
			x, y = file.pop()
			for dx, dy in DIRECTIONS:
				n = (x + dx, y + dy)
				if n in restantes:
					restantes.remove(n)
					zone.add(n)
					file.append(n)
		zones.append(zone)
	zones.sort(key=lambda z: -max(y for _, y in z))  # du sud au nord
	return zones


def boite(zone: set[Case]) -> str:
	xs = [x for x, _ in zone]
	ys = [y for _, y in zone]
	return f"x {min(xs)}–{max(xs)}, y {min(ys)}–{max(ys)}, {len(zone)} cases"


def verifier(chemin: Path) -> bool:
	plan = lire(chemin)
	ok = True

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= vrai
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	pos = plan.positions
	monde = Monde(plan)
	print(f"Grille {chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin} : "
		f"{plan.width} × {plan.height}")

	# 6. Entrée sud.
	bas = plan.height - 1
	entree = [(x, bas) for x in range(plan.width) if monde.libre((x, bas))]
	warps_sud = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == bas)
	spawns_sud = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[1] == bas)
	attendu = [(19, bas), (20, bas), (21, bas)]
	critere(entree == attendu and warps_sud == attendu and spawns_sud == attendu,
		f"entrée sud = {[x for x, _ in entree]} (praticables), warps {[x for x, _ in warps_sud]}, "
		f"spawns {[x for x, _ in spawns_sud]} ; attendu x 19–21")

	portes = plan.cells_of(PORTE)
	if len(portes) != 1:
		critere(False, f"une seule porte attendue, {len(portes)} trouvée(s)")
		return False
	porte = portes[0]

	# 1. Porte atteignable.
	dist = monde.distances(entree)
	aller = dist.get(porte, INF)
	critere(aller < INF, f"porte {porte} atteignable : trajet le plus court {aller} pas")
	if aller >= INF:
		return False

	zones = zones_herbes(plan)
	noms = ["H1", "H2", "H3"]
	if len(zones) != 3:
		critere(False, f"3 zones de hautes herbes attendues, {len(zones)} trouvées")
		return False
	h1, h2, h3 = zones
	for nom, zone in zip(noms, zones):
		print(f"  {nom} : {boite(zone)}")

	# 2. Herbes obligatoires.
	toutes = set(h1 | h2 | h3)
	g_min = monde.herbes_min(entree, lambda c: c in toutes).get(porte, INF)
	hors_h3 = monde.herbes_min(entree, lambda c: c in h1 or c in h2).get(porte, INF)
	sans_h1_h2 = Monde(plan, h1 | h2)
	g_sans = sans_h1_h2.herbes_min(entree, lambda c: c in toutes).get(porte, INF)
	sans_h3 = Monde(plan, h3).distances(entree).get(porte, INF)
	critere(5 <= g_min <= 7, f"cases d'herbes obligatoires : {g_min} (attendu 5 à 7)")
	critere(hors_h3 == 0 and sans_h3 >= INF and g_sans == g_min,
		f"toutes dans H3 : H3 incontournable ({'oui' if sans_h3 >= INF else 'NON'}), "
		f"minimum hors H3 = {hors_h3}, sans H1 ni H2 = {g_sans}")

	# 3. H1, H2 évitables.
	for nom, zone in (("H1", h1), ("H2", h2)):
		d = Monde(plan, zone).distances(entree).get(porte, INF)
		critere(d < INF, f"{nom} évitable : porte atteinte en {d} pas sans y entrer")
	d_sans_h1_h2 = sans_h1_h2.distances(entree).get(porte, INF)
	critere(d_sans_h1_h2 < INF, f"H1 et H2 évitables ensemble : {d_sans_h1_h2} pas (chemin sûr)")

	# 4. H2 plus courte que le chemin sûr.
	d_sans_h2 = Monde(plan, h2).distances(entree).get(porte, INF)
	a, b = pos["h2_sud"].cells[0], pos["h2_nord"].cells[0]
	loc_h2 = monde.distances([a]).get(b, INF)
	loc_sur = Monde(plan, h2).distances([a]).get(b, INF)
	critere(aller < d_sans_h2 and loc_h2 < loc_sur,
		f"H2 plus courte que le chemin sûr : trajet complet {aller} contre {d_sans_h2} pas ; "
		f"{a} → {b} : {loc_h2} contre {loc_sur} pas")

	# 5. Rebord : ne se monte pas, raccourci de retour.
	rebords = plan.cells_of(REBORD)
	montable = any(monde.pas((x, y + 1), (0, -1)) is not None for x, y in rebords)
	critere(bool(rebords) and not montable,
		f"rebord {rebords[0] if rebords else '?'}…{rebords[-1] if rebords else '?'} "
		f"({len(rebords)} cases) : ne se monte pas")
	sans_rebord = Monde(plan, set(rebords))
	retour = monde.distances([porte]).get(entree[1], INF)
	retour_sans = sans_rebord.distances([porte]).get(entree[1], INF)
	a, b = pos["rebord_haut"].cells[0], pos["rebord_bas"].cells[0]
	loc_r = monde.distances([a]).get(b, INF)
	loc_r_sans = sans_rebord.distances([a]).get(b, INF)
	aller_sans = sans_rebord.distances(entree).get(porte, INF)
	critere(retour < retour_sans and loc_r < loc_r_sans and aller_sans == aller,
		f"rebord = raccourci de retour : porte → entrée {retour} contre {retour_sans} pas ; "
		f"{a} → {b} : {loc_r} contre {loc_r_sans} pas ; aller inchangé ({aller_sans})")

	# Contrôles de cohérence des positions.
	for p in plan.positions.values():
		for c in p.cells:
			car = plan.at(*c)
			if p.kind in ("objet_cache", "spawn", "repere") and car not in ".=":
				critere(False, f"{p.ident} sur « {car} » en {c} (herbe rase ou chemin attendus)")
			if p.kind in ("pnj", "pokemon", "objet_visible") and car not in ".=":
				critere(False, f"{p.ident} sur « {car} » en {c} (case praticable attendue)")
	cibles = [p for p in plan.positions.values() if p.kind in ("objet_visible", "objet_cache")]
	for p in cibles:
		c = p.cells[0]
		acces = c if not p.bloque else next(
			((c[0] + dx, c[1] + dy) for dx, dy in DIRECTIONS
			if monde.libre((c[0] + dx, c[1] + dy)) and (c[0] + dx, c[1] + dy) in dist), None)
		if acces is None or acces not in dist:
			critere(False, f"{p.ident} {c} inaccessible")
	if ok:
		print("  positions : cohérentes")
	return ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/route_2.txt"
	ok = verifier(chemin.resolve())
	print("Plan conforme." if ok else "Plan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
