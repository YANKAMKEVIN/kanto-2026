#!/usr/bin/env python3
"""Vérifie la grille de la Route 9 (jalon 18, dossier 21 §3, §13.1) par recherche de chemin.

Grille : `tools/plans/route_9.txt`. Lecture par `plan_grille.lire` ; déplacements de
`plan_check.Monde` (4 directions, un pas par case, rebords sautés vers le sud seulement). Les
positions `bloque` (Dresseurs, Pokémon d'ambiance, objets, panneau) bloquent leurs cases.

Critères :
  - taille 80 × 36 ; raccord ouest = rangées de l'arbre à couper d'Azuria (`azuria.txt`, warp_est,
    x = largeur - 1) ; raccord est = rangées du raccord ouest de la Route 10 (`route_10.txt`) ;
    carte fermée partout ailleurs ; aucune porte de bâtiment ;
  - 7 Dresseurs R9-1..R9-7 ; R9-1 et R9-5 INÉVITABLES (leur ligne de vue couvre les 3 rangées du
    goulet, première case vue à ≥ 3 cases) ; les 5 autres évitables, un à un et ensemble ;
  - deux itinéraires (haut / bas) : chacun suffit, couper les deux ferme la route ; Adam sur le
    plateau, Jules dans la poche d'herbes de l'itinéraire bas ; le haut n'a aucune herbe ;
  - rebord : ne se monte pas, seule descente du plateau ;
  - hautes herbes : H4 incontournable, H2 sur l'itinéraire bas seulement, H1 et H3 évitables ;
  - 3 objets visibles atteignables, hors des lignes de vue ; l'approche d'un Dresseur ne ferme
    aucun passage ; Pokémon, panneau et points d'apparition bien placés.
Imprime la longueur du chemin principal et une estimation de la durée de traversée.

Usage : python3 tools/art/plan_check_route_9.py [grille]   code 1 si un critère échoue
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import HERBES, REBORD, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
Case = tuple[int, int]

TAILLE = (80, 36)
SOL = set(".=o")
ZONES = ("H1", "H2", "H3", "H4")
HERBES_OBLIGATOIRES = (4, 6)       # défaut : trajet le moins herbeux (itinéraire haut + H4)
CHEMIN = (100, 125)                 # pas, raccord ouest → raccord est (défaut)
DETECTION_MIN = 3
DRESSEURS = {"R9-1": 5, "R9-2": 3, "R9-3": 3, "R9-4": 3, "R9-5": 5, "R9-6": 4, "R9-7": 4}
INEVITABLES = ("R9-1", "R9-5")
OBJETS = {"O1": "super_potion", "O2": "antidote", "O3": "poke_ball"}
S_PAR_PAS = 0.72
S_COMBAT = {"R9-1": 150, "R9-5": 130}
S_SAUVAGE = 50
TAUX = 25 / 256


class Route(Monde):
	"""`plan_check.Monde` avec `sans` : le même monde, des cases de plus bloquées."""

	def sans(self, cases) -> "Route":
		return Route(self.plan, self.bloquees | set(cases))


def _chemin(monde: Route, entree: list[Case], sortie: list[Case]) -> list[Case]:
	"""Un plus court chemin (liste de cases) de l'entrée à la sortie, en préférant continuer
	tout droit (les changements de direction ne sont comptés que quand le terrain les impose)."""
	from collections import deque
	inverse: dict[Case, list[Case]] = {}
	for y in range(monde.plan.height):
		for x in range(monde.plan.width):
			for n in monde.voisins((x, y)):
				inverse.setdefault(n, []).append((x, y))
	dist = {c: 0 for c in sortie}
	file = deque(sortie)
	while file:
		c = file.popleft()
		for n in inverse.get(c, []):
			if n not in dist:
				dist[n] = dist[c] + 1
				file.append(n)
	c = min(entree, key=lambda e: dist.get(e, INF))
	chemin = [c]
	d_prec = None
	while c not in sortie:
		cand = [(d, monde.pas(c, d)) for d in DIRECTIONS]
		cand = [(d, n) for d, n in cand if n is not None and dist.get(n, INF) == dist[c] - 1]
		cand.sort(key=lambda t: 0 if t[0] == d_prec else 1)
		d_prec, c = cand[0]
		chemin.append(c)
	return chemin


def _virages(chemin: list[Case]) -> tuple[int, list[int]]:
	"""Changements de direction du chemin, simplifié aux axes dominants (un virage = passer de
	l'axe est-ouest à l'axe nord-sud sur au moins 6 cases)."""
	axes: list[str] = []
	for a, b in zip(chemin, chemin[1:]):
		axes.append("h" if a[1] == b[1] else "v")
	segments: list[tuple[str, int]] = []
	for ax in axes:
		if segments and segments[-1][0] == ax:
			segments[-1] = (ax, segments[-1][1] + 1)
		else:
			segments.append((ax, 1))
	# fusionne les segments de moins de 3 pas (à-coups de contournement) dans leurs voisins
	fusion: list[tuple[str, int]] = []
	for ax, n in segments:
		if n < 3 and fusion:
			fusion[-1] = (fusion[-1][0], fusion[-1][1] + n)
		elif fusion and fusion[-1][0] == ax:
			fusion[-1] = (ax, fusion[-1][1] + n)
		else:
			fusion.append((ax, n))
	return len(fusion) - 1, [n for _, n in fusion]


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _acces(monde: Route, p) -> list[Case]:
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS if monde.libre(_decale(c, d))]


def _rangees(chemin: Path, carte: str, ident: str, colonne: int) -> list[int]:
	autre = lire(chemin.with_name(f"{carte}.txt"))
	col = autre.width - 1 if colonne < 0 else colonne
	return sorted(y for x, y in autre.positions[ident].cells if x == col)


def verifier_route_9(chemin: Path) -> bool:
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
	critere((plan.width, plan.height) == TAILLE, f"taille {plan.width} × {plan.height} "
		f"(attendu {TAILLE[0]} × {TAILLE[1]})")

	# 1. Raccords.
	bord_o = [(0, y) for y in range(plan.height) if monde.libre((0, y))]
	bord_e = [(plan.width - 1, y) for y in range(plan.height) if monde.libre((plan.width - 1, y))]
	az = _rangees(chemin, "azuria", "warp_est", -1)
	r10 = _rangees(chemin, "route_10", "warp_ouest", 0)
	for lbl, bord, att, cote in (("ouest", bord_o, az, 0), ("est", bord_e, r10, plan.width - 1)):
		w = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == cote)
		s = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == cote)
		attendu = [(cote, y) for y in att]
		critere(bord == w == s == attendu, f"raccord {lbl} : rangées {[y for _, y in bord]} "
			f"praticables, warps, spawns = {'Azuria (est)' if cote == 0 else 'Route 10 (ouest)'} "
			f"{att}")
	bords = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and monde.libre((x, y))]
	critere(sorted(bords) == sorted(bord_o + bord_e) and not plan.cells_of("D"),
		"carte fermée : seuls les raccords ouest et est touchent le bord ; aucune porte")

	# 2. Chemin principal.
	entree, sortie = bord_o, bord_e
	dist = monde.distances(entree)
	aller = min(dist.get(c, INF) for c in sortie)
	critere(CHEMIN[0] <= aller < INF and aller <= CHEMIN[1],
		f"chemin principal {aller} pas (attendu {CHEMIN[0]} à {CHEMIN[1]})")
	if aller >= INF:
		return False
	retour = monde.distances(sortie)
	critere(min(retour.get(c, INF) for c in entree) < INF, "retour possible vers Azuria")

	def jusqua(m: Route, cibles: list[Case] = sortie, depart: list[Case] = entree) -> int:
		return min(m.distances(depart).get(c, INF) for c in cibles)

	# 3. Herbes.
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ZONES)
	if len(zones) != len(ZONES) or sorted(nommees) != sorted(ZONES):
		critere(False, f"zones H1..H4 attendues : {len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	for n in ZONES:
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	h1, h2, h3, h4 = (nommees[n] for n in ZONES)
	g_min = min(monde.herbes_min(entree, lambda c: c in toutes).get(c, INF) for c in sortie)
	critere(HERBES_OBLIGATOIRES[0] <= g_min <= HERBES_OBLIGATOIRES[1],
		f"cases de hautes herbes obligatoires : {g_min} (attendu {HERBES_OBLIGATOIRES[0]} à "
		f"{HERBES_OBLIGATOIRES[1]})")
	critere(jusqua(monde.sans(h4)) >= INF, "H4 incontournable")
	critere(jusqua(monde.sans(h1)) == aller and jusqua(monde.sans(h3)) == aller,
		"H1 et H3 évitables sans détour")
	critere(min(monde.herbes_min(entree, lambda c: c in toutes and c not in h4).get(c, INF)
		for c in sortie) == 0, "aucune case obligatoire hors de H4")

	# 4. Deux couloirs sur la terrasse haute.
	iti = _role(plan, "itineraire")
	if sorted(iti) != ["bas", "haut"]:
		critere(False, f"coupes itineraire haut et bas attendues : {sorted(iti)}")
		return False
	bas, haut = set(iti["bas"].cells), set(iti["haut"].cells)
	d_sans_bas, d_sans_haut = jusqua(monde.sans(bas)), jusqua(monde.sans(haut))
	d_aucun = jusqua(monde.sans(bas | haut))
	critere(d_sans_bas < INF and d_sans_haut < INF and d_aucun >= INF,
		f"deux itinéraires : par le haut {d_sans_bas} pas, par le bas {d_sans_haut} pas ; les deux "
		f"coupés : {'fermé' if d_aucun >= INF else d_aucun}")
	critere(d_sans_haut == aller and 0 <= d_sans_bas - d_sans_haut <= 12,
		f"le couloir bas est le plus court ({d_sans_haut} pas), le haut un peu plus long "
		f"(+{d_sans_bas - d_sans_haut})")
	herbes_haut = min(monde.sans(bas).herbes_min(entree, lambda c: c in toutes - h4).get(c, INF)
		for c in sortie)
	herbes_bas = min(monde.sans(haut).herbes_min(entree, lambda c: c in toutes - h4).get(c, INF)
		for c in sortie)
	critere(herbes_haut == 0 and herbes_bas == len({x for x, _ in h2}),
		f"couloir haut sans herbe ({herbes_haut}), couloir bas : {herbes_bas} cases de H2")

	# Le sentier serpente : changements de direction francs sur le chemin principal.
	chemin_pas = _chemin(monde, entree, sortie)
	virages, segments = _virages(chemin_pas)
	critere(virages >= 3 and all(n >= 6 for n in segments[:-1]),
		f"le chemin principal serpente à angles droits : {virages} changements de direction, "
		f"segments droits de {segments} pas (aucun tronçon droit de plus de {max(segments)} pas)")
	critere(max(segments) <= 30, "aucun tronçon droit de plus de 30 pas (pas d'effet couloir)")

	# 5. Rebord : unique, ne se monte pas, la poche de Gilles n'est pas un piège.
	rebord = plan.cells_of(REBORD)
	montable = any(monde.pas((x, y + 1), (0, -1)) is not None for x, y in rebord)
	lateral = any(monde.pas((x - dx, y), (dx, 0)) is not None for x, y in rebord for dx in (-1, 1))
	critere(bool(rebord) and not montable and not lateral,
		f"rebord {rebord[0]}..{rebord[-1]} : ne se monte pas, saut vers le sud seulement")
	atterrissage = [(x, y + 1) for x, y in rebord]
	retour_poche = [min(monde.distances([c]).get(e, INF) for e in entree) for c in atterrissage]
	critere(all(r < INF for r in retour_poche),
		f"la poche du rebord n'est pas un piège : retour à pied vers Azuria depuis l'atterrissage "
		f"({min(retour_poche)} pas)")
	sans_r = monde.sans(rebord)
	critere(jusqua(sans_r) == aller, "le rebord ne change pas l'aller (poche facultative)")

	# 6. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	critere(sorted(dresseurs) == sorted(DRESSEURS), f"7 Dresseurs R9-1..R9-7 : {sorted(dresseurs)}")
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
		bloque = set(vues[role])
		sans = jusqua(monde.sans(bloque))
		premiere = premiere_detection(monde, entree, vues[role])
		goulet = [c for c in vues[role] if plan.at(*c) == "="]
		critere(sans >= INF and premiere >= DETECTION_MIN and len(goulet) == 3,
			f"{role} {dresseurs[role].ident} inévitable ({'fermé' if sans >= INF else sans}) ; "
			f"couvre les {len(goulet)} rangées du goulet ; première case vue à {premiere} cases "
			f"(attendu ≥ {DETECTION_MIN})")
	evitables = [r for r in DRESSEURS if r not in INEVITABLES]
	for role in evitables:
		d = jusqua(monde.sans(vues[role]))
		critere(d < INF, f"{role} {dresseurs[role].ident} évitable : sortie en {d} pas hors de sa "
			f"vue (+{d - aller})")
	tous = set().union(*(vues[r] for r in evitables))
	d_tous = jusqua(monde.sans(tous))
	critere(d_tous < INF, f"les 5 évitables évitables ensemble : sortie en {d_tous} pas "
		"(seuls R9-1 et R9-5 sont obligatoires)")
	adam, jules = dresseurs["R9-2"], dresseurs["R9-3"]
	couloir_haut = {(x, y) for y in range(8, 12) for x in range(29, 44)}
	critere(adam.cells[0] in couloir_haut and set(vues["R9-2"]) <= couloir_haut
		and len(vues["R9-2"]) == 3 and (jules.cells[0][0], jules.cells[0][1] + 1) in h2
		and set(vues["R9-3"]) <= h2,
		f"Adam {adam.cells[0]} couvre toute la largeur du couloir haut, Jules {jules.cells[0]} "
		"garde H2 (couloir bas) ; chacun évitable par l'autre couloir")
	d_adam_bas = jusqua(monde.sans(haut | set(vues["R9-3"])))
	critere(d_adam_bas < INF, "l'itinéraire bas reste libre si seul Jules est évité")

	# 7. Objets.
	objets = _role(plan, "objet_visible")
	critere(sorted(objets) == sorted(OBJETS) and all(
		objets[r].attrs.get("item") == it for r, it in OBJETS.items() if r in objets),
		"3 objets : Super Potion, Antidote, Poké Ball x2")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((dist.get(a, INF) for a in _acces(monde, p)), default=INF)
		critere(atteint < INF and plan.at(*c) in SOL and c not in lignes and not any(
			plan.at(*a) == HERBES for a in [c]),
			f"{role} {p.ident} {c} sur « {plan.at(*c)} » ({p.attrs.get('item')}) : atteint en "
			f"{atteint} pas, hors des lignes de vue")

	# 8. Un Dresseur qui s'approche ne ferme jamais un passage.
	tout = monde.distances(entree + list(sortie))
	cibles = [list(sortie), [entree[0]]] + [_acces(monde, p) for p in objets.values()]
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
	critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3] if fermes else ''}")

	# 9. Pokémon, panneau, points d'apparition.
	fautes: list[str] = []
	for p in plan.of_kind("pokemon") + plan.of_kind("panneau"):
		for c in p.cells:
			if c in lignes or plan.at(*c) == HERBES:
				fautes.append(f"{p.ident} {c} sur une ligne de vue ou dans les herbes")
			if p.kind == "panneau" and plan.at(*c) not in SOL - {"="}:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} »")
		if not any(a in tout for a in _acces(monde, p)):
			fautes.append(f"{p.ident} sans case voisine atteignable")
	for p in plan.of_kind("spawn") + plan.of_kind("herbes"):
		for c in p.cells:
			if c not in tout:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if plan.at(*c) not in SOL:
				fautes.append(f"{p.ident} sur « {plan.at(*c)} »")
	critere(not fautes, "Pokémon, panneau et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and plan.at(x, y) != REBORD
		and (x, y) not in monde.bloquees and (x, y) not in tout]
	critere(not orphelines, "toutes les cases praticables (hors cases de rebord, qu'on ne fait que sauter) "
		f"sont connexes {orphelines[:4]}")

	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes "
		f"({', '.join(f'{n} {len(nommees[n])}' for n in ZONES)})")
	duree = aller * S_PAR_PAS + sum(S_COMBAT.values()) + g_min * TAUX * S_SAUVAGE
	print(f"  traversée directe estimée : {aller} pas × {S_PAR_PAS} s + 2 inévitables "
		f"{sum(S_COMBAT.values())} s + {g_min * TAUX:.2f} rencontre(s) × {S_SAUVAGE} s = "
		f"{duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s)")
	return ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/route_9.txt"
	bon = verifier_route_9(chemin.resolve())
	print("Plan conforme." if bon else "Plan NON conforme.")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
