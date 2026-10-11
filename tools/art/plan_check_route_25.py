#!/usr/bin/env python3
"""Vérifie la grille de la Route 25 et du Cap d'Azuria (jalon 14, brouillon du 2026-10-11).

Grille : `tools/plans/route_25.txt`. Lecture par `plan_grille.lire` ; déplacements de
`plan_check.Monde` (4 directions, rebords sautés vers le sud seulement), avec une **porte
terminale** : la porte de la maison de Léo (`D`) mène à l'intérieur, on y entre, on ne la traverse
pas. Les positions `bloque` (Dresseurs, PNJ, Pokémon d'ambiance, objets, panneaux, case cachée)
bloquent leurs cases.

Critères (défauts de la règle 4, passe docs/design/passes/j14-v2-alignement.md §3 ; à reprendre
par les tests de la carte au J14) :
  - taille 80 × 28 ; raccord ouest = 3 rangées (13..15), warps et spawns compris (relais vers la
    Route 24 nord du J13) ; carte fermée partout ailleurs ;
  - maison de Léo 8 × 6, porte sur les 4e et 5e colonnes du bas, warp sur la porte, à l'est ;
  - entrée ouest → porte de la maison dans les bornes ;
  - V2 : 5 à 7 Dresseurs, majorité facultative ; ici D1 et D2 inévitables (première case vue à
    ≥ 3 cases), D3 à D6 évitables un à un et ensemble, D5 et D6 sans détour ;
  - hautes herbes : H3 incontournable, cases obligatoires dans les bornes, H1, H2 et H4
    évitables sans détour, aucune case obligatoire hors de H3 ;
  - rebord : ne se monte pas, raccourcit la sortie de la terrasse, l'aller ne l'emprunte pas ;
  - objets : 3 visibles et 1 caché (« cache »), atteignables, hors des lignes de vue ;
  - l'approche d'un Dresseur ne ferme aucun passage ;
  - chemin principal d'au moins 2 cases de large (compagnon, J11) hors des goulets des
    Dresseurs et de H3 ;
  - PNJ, Pokémon d'ambiance, panneaux et points d'apparition bien placés.
Imprime la longueur du chemin principal et une estimation de la durée de traversée.

Usage : python3 tools/art/plan_check.py tools/plans/route_25.txt
        (ou python3 tools/art/plan_check_route_25.py [grille])   code 1 si un critère échoue
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import HERBES, PORTE, REBORD, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
Case = tuple[int, int]

TAILLE = (80, 28)
RACCORD_OUEST = [13, 14, 15]       # relais vers la Route 24 nord (J13 aligne son bord est)
MAISON = "M"
MAISON_EMPRISE = (8, 6, (3, 4))    # largeur, hauteur, colonnes de la porte (comme le Centre)
SOL = set(".=s")                   # sol où poser personnages, objets et points d'apparition
ZONES = ("H1", "H2", "H3", "H4")
HERBES_OBLIGATOIRES = (3, 6)       # défaut : une seule bande courte, juste avant le Cap
CHEMIN = (70, 110)                 # pas, entrée ouest → porte de Léo (défaut)
DETECTION_MIN = 3
DRESSEURS = {"D1": 5, "D2": 5, "D3": 3, "D4": 2, "D5": 3, "D6": 4}
INEVITABLES = ("D1", "D2")
SANS_DETOUR = ("D5", "D6")
OBJETS = {"O1": "objet_visible", "O2": "objet_visible", "O3": "objet_visible", "O4": "cache"}
LARGEUR_MIN = 2
# Estimation de la traversée (méthode de la Route 3) : pas mesuré sur S21, combats à deux
# Pokémon, taux de rencontre de la Route 2 nord.
S_PAR_PAS = 0.72
S_COMBAT_2 = 120
S_SAUVAGE = 50
TAUX = 25 / 256


class Route(Monde):
	"""`plan_check.Monde` avec une porte terminale (maison de Léo)."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset()) -> None:
		super().__init__(plan, bloquees)
		self.portes = set(plan.cells_of(PORTE))

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Route":
		return Route(self.plan, self.bloquees | set(cases))


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _composantes(cases: set[Case]) -> list[set[Case]]:
	reste, groupes = set(cases), []
	while reste:
		germe = reste.pop()
		groupe, pile = {germe}, [germe]
		while pile:
			c = pile.pop()
			for d in DIRECTIONS:
				n = _decale(c, d)
				if n in reste:
					reste.remove(n)
					groupe.add(n)
					pile.append(n)
		groupes.append(groupe)
	return sorted(groupes, key=lambda g: (min(x for x, _ in g), min(y for _, y in g)))


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _acces(monde: Route, p) -> list[Case]:
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if monde.libre(_decale(c, d)) and _decale(c, d) not in monde.portes]


def _chemin_le_plus_court(monde: Route, depart: list[Case], cibles: list[Case]) -> list[Case]:
	"""Un plus court chemin (cases) de [depart] à la plus proche des [cibles] (parcours en largeur)."""
	parent: dict[Case, Case | None] = {c: None for c in depart}
	file = list(depart)
	for c in file:
		if c in cibles:
			chemin = [c]
			while parent[chemin[-1]] is not None:
				chemin.append(parent[chemin[-1]])
			return chemin[::-1]
		for n in monde.voisins(c):
			if n not in parent:
				parent[n] = c
				file.append(n)
	return []


def verifier_route_25(chemin: Path) -> bool:
	plan = lire(chemin)
	ok = True

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	monde = Route(plan)
	pos = plan.positions
	nom = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {nom} : {plan.width} × {plan.height}")
	critere((plan.width, plan.height) == TAILLE,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE[0]} × {TAILLE[1]})")

	# 1. Raccord ouest, carte fermée ailleurs.
	entree = [(0, y) for y in range(plan.height) if monde.libre((0, y))]
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	attendu = [(0, y) for y in RACCORD_OUEST]
	critere(entree == warps == spawns == attendu,
		f"raccord ouest : rangées {[y for _, y in entree]} praticables, warps "
		f"{[y for _, y in warps]}, spawns {[y for _, y in spawns]} (attendu {RACCORD_OUEST})")
	bords = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and monde.libre((x, y))]
	critere(sorted(bords) == sorted(entree), "carte fermée : seul le raccord ouest touche le bord")

	# 2. Maison de Léo.
	maisons = _composantes(set(plan.cells_of(MAISON)) | set(plan.cells_of(PORTE)))
	portes = plan.cells_of(PORTE)
	if len(maisons) != 1 or not portes:
		critere(False, f"une maison (M + D) attendue, {len(maisons)} trouvée(s)")
		return False
	xs = [x for x, _ in maisons[0]]
	ys = [y for _, y in maisons[0]]
	larg, haut, cols = MAISON_EMPRISE
	taille_m = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
	attendues = sorted((min(xs) + i, max(ys)) for i in cols)
	critere(taille_m == (larg, haut) and len(maisons[0]) == larg * haut
		and sorted(portes) == attendues and min(xs) >= plan.width * 0.75,
		f"maison de Léo ({min(xs)}..{max(xs)}, {min(ys)}..{max(ys)}) : {taille_m[0]} × "
		f"{taille_m[1]}, porte {sorted(portes)} sur la façade sud, au bout du Cap")
	warps_c = {c for p in plan.of_kind("warp") for c in p.cells}
	critere(set(portes) <= warps_c, "warp sur la porte de la maison")

	# 3. Chemin principal.
	dist = monde.distances(entree)
	aller = min(dist.get(c, INF) for c in portes)
	critere(CHEMIN[0] <= aller <= CHEMIN[1],
		f"entrée ouest → porte de Léo : {aller} pas (attendu {CHEMIN[0]} à {CHEMIN[1]})")
	if aller >= INF:
		return False
	sortie = pos["from_bill_house"].cells

	def jusqua(m: Route, cibles: list[Case]) -> int:
		return min(m.distances(entree).get(c, INF) for c in cibles)

	# 4. Hautes herbes.
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ZONES)
	if len(zones) != len(ZONES) or sorted(nommees) != sorted(ZONES):
		critere(False, f"zones H1..H4 attendues : {len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	for n in ZONES:
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	h1, h2, h3, h4 = (nommees[n] for n in ZONES)
	g_min = min(monde.herbes_min(entree, lambda c: c in toutes).get(c, INF) for c in portes)
	critere(HERBES_OBLIGATOIRES[0] <= g_min <= HERBES_OBLIGATOIRES[1],
		f"cases de hautes herbes obligatoires jusqu'à Léo : {g_min} "
		f"(attendu {HERBES_OBLIGATOIRES[0]} à {HERBES_OBLIGATOIRES[1]})")
	critere(jusqua(monde.sans(h3), portes) >= INF, "H3 incontournable")
	for n, zone in (("H1", h1), ("H2", h2), ("H4", h4)):
		d = jusqua(monde.sans(zone), portes)
		critere(d == aller, f"{n} évitable sans détour ({d} pas sans y entrer)")
	hors = min(monde.herbes_min(entree, lambda c: c in toutes and c not in h3).get(c, INF)
		for c in portes)
	critere(hors == 0, f"aucune case obligatoire hors de H3 (minimum hors : {hors})")

	# 5. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	critere(sorted(dresseurs) == sorted(DRESSEURS), f"6 Dresseurs D1..D6 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(DRESSEURS):
		return False
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vue = ligne_de_vue(monde, p)
		vues[role] = vue
		vision = int(p.attrs.get("sight", "0"))
		critere(vision == DRESSEURS[role] and len(vue) == vision and plan.at(*p.cells[0]) in SOL,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs.get('facing')} : vision {len(vue)}/"
			f"{vision} cases dégagées ({''.join(plan.at(*c) for c in vue)})")
	for role in INEVITABLES:
		sans = jusqua(monde.sans(vues[role]), portes)
		premiere = premiere_detection(monde, entree, vues[role])
		critere(sans >= INF and premiere >= DETECTION_MIN,
			f"{role} {dresseurs[role].ident} inévitable (maison : "
			f"{'fermée' if sans >= INF else sans}) ; première case vue à {premiere} cases "
			f"(attendu ≥ {DETECTION_MIN})")
	evitables = [r for r in DRESSEURS if r not in INEVITABLES]
	for role in evitables:
		d = jusqua(monde.sans(vues[role]), portes)
		detour = role in SANS_DETOUR
		critere(d < INF and (not detour or d == aller),
			f"{role} {dresseurs[role].ident} évitable : maison en {d} pas hors de sa vue"
			+ (" (sans détour)" if detour else f" (+{d - aller})"))
	tous = set().union(*(vues[r] for r in evitables))
	d_tous = jusqua(monde.sans(tous), portes)
	critere(d_tous < INF, f"D3 à D6 évitables ensemble : maison en {d_tous} pas "
		f"({len(INEVITABLES)} combats inévitables sur {len(DRESSEURS)} : majorité facultative)")

	# 6. Rebord(s) : ne se montent pas, raccourcissent le retour vers le chemin.
	rebords = _composantes(set(plan.cells_of(REBORD)))
	critere(len(rebords) >= 1, f"{len(rebords)} rebord(s)")
	for i, r in enumerate(rebords, 1):
		montable = any(monde.pas((x, y + 1), (0, -1)) is not None for x, y in r)
		lateral = any(monde.pas((x - dx, y), (dx, 0)) is not None for x, y in r for dx in (-1, 1))
		hauts = [(x, y - 1) for x, y in r if monde.libre((x, y - 1))]
		avec = min(min(monde.distances([h]).get(c, INF) for c in portes) for h in hauts)
		sans = min(min(monde.sans(r).distances([h]).get(c, INF) for c in portes) for h in hauts)
		x0, y0 = min(r)
		critere(not montable and not lateral and avec < sans,
			f"rebord L{i} ({x0}..{max(x for x, _ in r)}, {y0}) : ne se monte pas ; depuis le haut, "
			f"maison en {avec} pas contre {sans if sans < INF else '∞'} sans lui")
	aller_sans = jusqua(monde.sans(plan.cells_of(REBORD)), portes)
	critere(aller_sans == aller, f"l'aller n'emprunte pas de rebord ({aller_sans} pas sans eux)")

	# 7. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	conformes = sorted(objets) == sorted(OBJETS) and all(
		objets[r].kind == k for r, k in OBJETS.items() if r in objets)
	critere(conformes, "objets O1..O3 visibles, O4 caché")
	tout = monde.distances(entree + list(sortie))
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((dist.get(a, INF) for a in _acces(monde, p)), default=INF)
		sol = plan.at(*c)
		bon = atteint < INF and c not in lignes
		if p.kind == "cache":
			bon &= p.bloque and sol not in SOL and "indice" in p.attrs
		else:
			bon &= sol in SOL
		critere(bon, f"{role} {p.ident} {c} sur « {sol} » ({p.attrs.get('item')}"
			+ (f", indice {p.attrs.get('indice')}" if p.kind == "cache" else "")
			+ f") : atteint en {atteint} pas, hors des lignes de vue")

	# 8. Un Dresseur qui s'approche ne ferme jamais un passage (jalon 9 §6.9).
	cibles = [list(portes), [entree[0]]] + [_acces(monde, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in tout:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Route(plan)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	critere(not fermes, "l'approche d'un Dresseur ne ferme aucun passage "
		f"{fermes[:3] if fermes else ''}")

	# 9. Largeur du chemin principal (compagnon) : sur le plus court chemin, chaque case a une
	# voisine latérale praticable, sauf dans les goulets assumés (vue de D1 / D2) et H3.
	trace = _chemin_le_plus_court(monde, entree, portes)
	assumes = set(vues["D1"]) | set(vues["D2"]) | h3 | set(portes)
	etroits = []
	for i in range(1, len(trace) - 1):
		c = trace[i]
		if c in assumes:
			continue
		d = (trace[i + 1][0] - trace[i - 1][0], trace[i + 1][1] - trace[i - 1][1])
		lat = [(0, 1), (0, -1)] if d[1] == 0 else [(1, 0), (-1, 0)] if d[0] == 0 else DIRECTIONS
		if not any(monde.libre(_decale(c, l)) for l in lat):
			etroits.append(c)
	critere(not etroits, f"chemin principal d'au moins {LARGEUR_MIN} cases de large "
		f"({len(trace)} cases vérifiées){' : ' + str(etroits[:5]) if etroits else ''}")

	# 10. PNJ, Pokémon d'ambiance, panneaux, points d'apparition.
	fautes: list[str] = []
	for p in plan.of_kind("pnj") + plan.of_kind("pokemon") + plan.of_kind("panneau"):
		for c in p.cells:
			if c in lignes or plan.at(*c) == HERBES:
				fautes.append(f"{p.ident} {c} sur une ligne de vue ou dans les herbes")
			if p.kind in ("pnj", "panneau") and plan.at(*c) not in SOL - {"="}:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} » (hors du sol attendu)")
			if p.kind == "pnj" and "facing" not in p.attrs:
				fautes.append(f"{p.ident} sans facing")
		if not any(a in tout for a in _acces(monde, p)):
			fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
	for p in plan.of_kind("spawn") + plan.of_kind("herbes"):
		for c in p.cells:
			if c not in tout and c not in entree:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if plan.at(*c) not in SOL:
				fautes.append(f"{p.ident} sur « {plan.at(*c)} » en {c}")
	critere(not fautes, "PNJ, Pokémon, panneaux et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))

	# Statistiques et durée.
	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes "
		f"({', '.join(f'{n} {len(nommees[n])}' for n in ZONES)})")
	rencontres = g_min * TAUX
	duree = aller * S_PAR_PAS + len(INEVITABLES) * S_COMBAT_2 + rencontres * S_SAUVAGE
	print(f"  traversée directe estimée : {aller} pas × {S_PAR_PAS} s + D1 et D2 "
		f"{len(INEVITABLES)} × {S_COMBAT_2} s + {rencontres:.2f} rencontre(s) attendue(s) × "
		f"{S_SAUVAGE} s = {duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s) ; "
		f"marche seule {aller * S_PAR_PAS:.0f} s")
	return ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/route_25.txt"
	bon = verifier_route_25(chemin.resolve())
	print("Plan conforme." if bon else "Plan NON conforme.")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
