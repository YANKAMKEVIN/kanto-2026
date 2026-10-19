#!/usr/bin/env python3
"""Vérifie les grilles de Lavanville et du rez-de-chaussée de la Tour Pokémon (jalon 18).

Grilles : `tools/plans/lavanville.txt` (44 × 36) et `tour_pokemon_rdc.txt` (20 × 18),
dossier 21 §6, §7, §13.1, §14. Lecture par `plan_grille.lire`, déplacements de
`plan_check_azuria.Carte` (portes terminales `D`, positions `bloque` bloquantes).

Lavanville : taille ; raccord nord de 3 cases au milieu du bord, spawn et légende ; bords ouest et
sud fermés « À venir » (coming_soon) et aucune autre ouverture sur le pourtour ; toutes les cases
praticables connexes ; 6 portes atteignables, emprises des bâtiments ; la Tour = plus haute
emprise, au nord-est, porte au sud ; 4 PNJ dehors dont aucun ne bloque un passage (le réseau reste
identique PNJ en place) ; panneaux lisibles ; peu d'arbres.
Tour : taille, entrée sud de 2 cases, escalier d'une case de large inatteignable tant que la Médium
l'occupe (et atteignable sans elle), les 36 tombes lisibles depuis une case libre, 5 examens
nommés, comptoir lisible, PNJ sans blocage, bougies sur des chandeliers.

Usage : python3 tools/art/plan_check_lavanville.py   (les deux cartes ; code 1 si un critère échoue)
        python3 tools/art/plan_check_lavanville.py tools/plans/lavanville.txt
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS, INF  # noqa: E402
from plan_check_azuria import Carte, Rapport, _decale, _dans  # noqa: E402
from plan_grille import lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]

# Emprises : caractère → (largeur, hauteur, colonnes de la porte dans la rangée du bas).
EMPRISES = {
	"C": (8, 7, (3, 4)),     # Centre (bldg_centre_01 réutilisé)
	"O": (8, 7, (3, 4)),     # Boutique (bldg_boutique_01 réutilisé)
	"F": (8, 7, (3, 4)),     # Maison des Pokémon (neuve)
	"m": (7, 6, (3,)),       # Maison 1
	"N": (7, 6, (3,)),       # Maison 2
	"U": (12, 11, (5, 6)),   # Tour Pokémon (neuve, la plus haute)
}
PORTES_BATIMENT = {"C": "porte_centre", "O": "porte_boutique", "F": "porte_fuji",
	"m": "porte_maison_1", "N": "porte_maison_2", "U": "porte_tour"}


def _boite(cases: list[Case]) -> tuple[int, int, int, int]:
	xs = [x for x, _ in cases]
	ys = [y for _, y in cases]
	return min(xs), min(ys), max(xs), max(ys)


def _voisines_libres(carte: Carte, c: Case, dist: dict[Case, int]) -> list[Case]:
	return [n for d in DIRECTIONS if carte.libre(n := _decale(c, d)) and n in dist
		and n not in carte.portes]


def _perimetre(plan) -> list[Case]:
	return [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1))]


def _avec(carte: Carte, cases) -> Carte:
	"""Copie de la carte avec des cases bloquées en plus (sans relire les positions)."""
	copie = Carte(carte.plan, set(), carte.portes)
	copie.bloquees = (carte.bloquees | set(cases))
	return copie


def verifier_lavanville(chemin: Path) -> bool:
	plan = lire(chemin)
	pos = plan.positions
	r = Rapport(f"Lavanville ({chemin.name})")
	r.critere((plan.width, plan.height) == (44, 36), f"taille {plan.width} × {plan.height}")
	carte = Carte(plan)
	nord = pos["warp_nord"].cells
	entree = pos["from_route_10"].cells
	dist = carte.distances(entree)

	# 1. Raccords : nord (3 cases, milieu), ouest et sud fermés « À venir », rien d'autre.
	milieu = (plan.width - 1) / 2
	centre_nord = sum(x for x, _ in nord) / len(nord)
	r.critere(len(nord) == 3 and all(y == 0 for _, y in nord) and abs(centre_nord - milieu) <= 1
		and all(carte.libre(c) for c in nord) and entree == nord,
		f"raccord nord : 3 cases {nord[0]}..{nord[-1]}, au milieu du bord (milieu {milieu}), "
		"spawn sur les mêmes cases (à raccorder au bord sud de route_10, milieu du bord)")
	ouest = pos["warp_ouest"]
	sud = pos["warp_sud"]
	r.critere(len(ouest.cells) == 3 and all(x == 0 for x, _ in ouest.cells)
		and ouest.attrs.get("coming_soon") == "route_8" and all(carte.libre(c) for c in ouest.cells),
		f"bord ouest {ouest.cells[0]}..{ouest.cells[-1]} fermé « ROUTE 8 — À venir » (coming_soon)")
	r.critere(len(sud.cells) == 3 and all(y == plan.height - 1 for _, y in sud.cells)
		and sud.attrs.get("coming_soon") == "route_12" and all(carte.libre(c) for c in sud.cells),
		f"bord sud {sud.cells[0]}..{sud.cells[-1]} fermé « ROUTE 12 — À venir » (coming_soon)")
	ouvertures = {c for c in _perimetre(plan) if plan.at(*c) in plan.praticables}
	declarees = set(nord) | set(ouest.cells) | set(sud.cells)
	r.critere(ouvertures == declarees,
		f"seules ouvertures du pourtour = les 3 raccords ({len(ouvertures)} cases praticables sur "
		"le bord, toutes déclarées) ; aucun autre passage")
	r.critere(all(c in dist for c in ouest.cells + sud.cells),
		"les raccords ouest et sud sont atteignables depuis l'arrivée nord")

	# 2. Connexité : toutes les cases praticables (non bloquées par une position).
	praticables = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if carte.libre((x, y))]
	isolees = [c for c in praticables if c not in dist and c not in carte.portes]
	portes_isolees = [c for c in carte.portes if not any(n in dist for n in
		(_decale(c, d) for d in DIRECTIONS))]
	r.critere(not isolees and not portes_isolees,
		f"{len(praticables)} cases praticables, toutes connexes à l'arrivée nord "
		f"(isolées : {isolees[:6]})")

	# 3. Bâtiments : emprises exactes, portes atteignables, warps sur les portes.
	hauteurs: dict[str, int] = {}
	tour_boite = None
	for car, (w, h, cols) in EMPRISES.items():
		cases = plan.cells_of(car) + [c for c in plan.cells_of("D")
			if _decale(c, (0, 0)) and plan.at(c[0], c[1] - 1) == car]
		x0, y0, x1, y1 = _boite(cases)
		plein = len(cases) == w * h and (x1 - x0 + 1, y1 - y0 + 1) == (w, h)
		portes = [(x0 + c, y1) for c in cols]
		warp = pos[PORTES_BATIMENT[car]].cells
		haut = all(plan.at(*c) == "D" for c in portes) and sorted(warp) == sorted(portes)
		devant = all(_decale(c, (0, 1)) in dist and plan.at(*_decale(c, (0, 1))) in "p."
			for c in portes)
		cible = [c for c in portes if min((dist.get(_decale(c, d), INF) for d in DIRECTIONS)) < INF]
		r.critere(plein and haut and devant and len(cible) == len(portes),
			f"{car} : {w} × {h} en ({x0}, {y0}), porte(s) {portes} = warp, case devant libre, "
			"atteignable")
		hauteurs[car] = h
		if car == "U":
			tour_boite = (x0, y0, x1, y1)
	toutes_portes = set(plan.cells_of("D"))
	declarees_portes = {c for n in PORTES_BATIMENT.values() for c in pos[n].cells}
	r.critere(toutes_portes == declarees_portes and len(toutes_portes) == 10,
		f"{len(toutes_portes)} cases de porte, toutes déclarées comme warps (6 bâtiments)")

	# 4. La Tour : plus haute emprise, nord-est, porte au sud.
	x0, y0, x1, y1 = tour_boite
	r.critere(hauteurs["U"] > max(h for c, h in hauteurs.items() if c != "U")
		and (x0 + x1) / 2 > plan.width / 2 and (y0 + y1) / 2 < plan.height / 3
		and plan.at(34, y1) == "D" and y1 + 1 < plan.height,
		f"la Tour occupe le nord-est ({x0}..{x1}, {y0}..{y1}), {hauteurs['U']} de haut (la plus "
		"haute), porte au sud")

	# 5. PNJ : 4 dehors, aucun ne bloque un passage ; panneaux lisibles.
	pnjs = pos_pnj = [p for p in plan.of_kind("pnj")]
	cases_pnj = {p.cells[0] for p in pnjs}
	sans_pnj = Carte(plan, set(), carte.portes)
	sans_pnj.bloquees -= cases_pnj
	d_sans = sans_pnj.distances(entree)
	r.critere(len(pnjs) == 4 and all(plan.at(*p.cells[0]) in plan.praticables for p in pnjs),
		f"4 PNJ dehors : {', '.join(p.attrs['role'] for p in pnjs)}, sur des cases praticables")
	d_avec = dist
	reste_libre = set(d_sans) - cases_pnj
	r.critere(reste_libre == set(d_avec),
		"les 4 PNJ réunis ne coupent aucun passage : les mêmes cases restent atteignables, portes "
		"et raccords compris")
	mini = INF
	for p in pnjs:
		c = p.cells[0]
		libres = [n for d in DIRECTIONS if (n := _decale(c, d)) in d_avec]
		# largeur du passage au droit du PNJ : cases praticables alignées perpendiculairement
		for ax in ((1, 0), (0, 1)):
			ligne = 1
			for s in (1, -1):
				k = 1
				while carte.libre(_decale(c, ax, s * k)) and (_decale(c, ax, s * k)) not in cases_pnj:
					ligne += 1
					k += 1
			mini = min(mini, ligne) if ax == (1, 0) or ligne > 1 else mini
		r.critere(len(libres) >= 2, f"PNJ {p.attrs['role']} en {c} : {len(libres)} voisines libres")
	panneaux = plan.of_kind("panneau")
	lisibles = {p.ident: [n for d in DIRECTIONS if (n := _decale(p.cells[0], d)) in dist]
		for p in panneaux}
	r.critere(len(panneaux) == 3 and all(lisibles.values()),
		f"3 panneaux (T-18, T-19, T-20) lisibles depuis une case libre : {lisibles}")

	# 6. Style : angles droits, peu d'arbres, haies, fleurs.
	pave = set(plan.cells_of("p"))
	arbres = plan.cells_of("G")
	r.critere(len(arbres) <= 6 and plan.cells_of("x") and plan.cells_of("y"),
		f"peu d'arbres repères ({len(arbres)}), haies taillées ({len(plan.cells_of('x'))} cases), "
		f"fleurs pâles ({len(plan.cells_of('y'))} cases)")
	r.critere(all(len([n for d in DIRECTIONS if _decale(c, d) in pave]) >= 2 for c in pave),
		"rues pavées : aucune case de pavé en cul-de-sac ou en pointe (largeur ≥ 2 partout)")
	diag = [c for c in pave if (_decale(c, (1, 0)) not in pave) != (_decale(c, (0, 1)) not in pave)
		and _decale(c, (1, 1)) in pave]
	r.critere(not [c for c in pave if _decale(c, (1, 1)) in pave and _decale(c, (1, 0)) not in pave
		and _decale(c, (0, 1)) not in pave],
		"aucune diagonale de pavé : rues à angles droits")

	# 7. Distances de repère (pas) depuis l'arrivée.
	def pas(nom: str) -> int:
		return min(dist.get(_decale(c, (0, 1)), INF) for c in pos[nom].cells) + 1
	r.info(f"depuis l'arrivée nord : Maison des Pokémon {pas('porte_fuji')} pas, Centre "
		f"{pas('porte_centre')}, Boutique {pas('porte_boutique')}, Tour {pas('porte_tour')}, "
		f"sortie ouest {min(dist[c] for c in ouest.cells)}, sortie sud {min(dist[c] for c in sud.cells)}")
	return r.ok


def verifier_tour(chemin: Path) -> bool:
	plan = lire(chemin)
	pos = plan.positions
	r = Rapport(f"Tour Pokémon, rez-de-chaussée ({chemin.name})")
	r.critere((plan.width, plan.height) == (20, 18), f"taille {plan.width} × {plan.height}")
	carte = Carte(plan)
	sortie = pos["sortie"].cells
	r.critere(len(sortie) == 2 and all(y == plan.height - 2 for _, y in sortie)
		and all(plan.at(*c) == "X" for c in sortie) and pos["entree"].cells[0] in sortie
		and len(plan.cells_of("X")) == 2,
		"entrée au sud : 2 cases, dans l'axe, spawn sur le paillasson")
	depart = [_decale(c, (0, -1)) for c in sortie]
	pnjs = {p.attrs["role"]: p for p in plan.of_kind("pnj")}
	cases_pnj = {p.cells[0] for p in pnjs.values()}
	carte.bloquees -= cases_pnj                          # le plan nu, sans personnages
	dist = carte.distances(depart)
	sol = [(x, y) for y in range(plan.height) for x in range(plan.width) if plan.at(x, y) == "."]
	medium = pnjs["M"].cells[0]
	escalier = pos["escalier"].cells[0]
	r.critere(len(pnjs) == 5 and len(plan.cells_of("S")) == 1 and plan.at(*escalier) == "S",
		"3 visiteurs, un gardien et la Médium ; un seul escalier (1 case de large)")
	isolees = [c for c in sol if c not in dist]
	r.critere(not isolees, f"{len(sol)} cases de sol, toutes connexes à l'entrée (isolées : {isolees})")

	# Escalier : accessible par la seule case de la Médium ; inatteignable avec elle.
	acces = [n for d in DIRECTIONS if carte.libre(n := _decale(escalier, d)) and n != escalier]
	murs = [_decale(escalier, d) for d in ((-1, 0), (1, 0), (0, -1))]
	r.critere(acces == [medium] and all(plan.at(*m) == "K" for m in murs),
		f"l'escalier ({escalier}) est dans le mur du fond, flanqué de murs ; sa seule case "
		f"d'accès est celle de la Médium {medium}")
	avec = _avec(carte, cases_pnj).distances(depart)
	sans = _avec(carte, cases_pnj - {medium}).distances(depart)
	r.critere(escalier not in avec and medium not in avec and escalier in sans,
		"Médium en place : l'escalier est INATTEIGNABLE ; sans elle (J19), il l'est")
	autour = [n for d in DIRECTIONS if (n := _decale(medium, d)) in avec]
	r.critere(len(autour) >= 2, f"la Médium peut être parlée depuis {len(autour)} cases libres")

	# PNJ : aucun ne coupe un passage (hors Médium, qui coupe uniquement l'escalier).
	seul = sans
	base = carte.distances(depart)
	manquantes = [c for c in base if c not in seul and c not in cases_pnj and c != escalier]
	r.critere(not manquantes and all(base.get(c) is not None for c in cases_pnj),
		"les 4 autres PNJ ne bloquent aucune case ni aucun passage")
	r.critere(all(any(n in avec for n in (_decale(p.cells[0], d) for d in DIRECTIONS))
		for p in pnjs.values()), "chaque PNJ est parlable depuis une case libre")
	comptoir = plan.cells_of("W")
	g_cell = pnjs["V1"].cells[0]
	r.critere(len(comptoir) == 4 and _decale(g_cell, (0, 1)) in comptoir
		and _decale(g_cell, (0, 2)) in avec,
		"gardien derrière un comptoir de 4 cases, parlé depuis la case devant le comptoir")

	# Tombes.
	tombes = plan.cells_of("g")
	illisibles = [c for c in tombes if not _voisines_libres(carte, c, avec)]
	r.critere(len(tombes) == 36 and not illisibles,
		f"{len(tombes)} tombes, toutes lisibles depuis au moins une case libre (illisibles : "
		f"{illisibles})")
	examens = [p for p in plan.of_kind("examen")]
	r.critere(len(examens) == 5 and all(p.cells[0] in tombes for p in examens)
		and len({p.cells[0] for p in examens}) == 5,
		"5 tombes examinables nommées (T-36 à T-40) ; les 31 autres : « Une tombe bien entretenue. »")
	rangees = sorted({y for _, y in tombes})
	r.critere(all(_decale((x, y), (0, 1)) not in tombes and _decale((x, y), (0, -1)) not in tombes
		for x, y in tombes), f"rangées de tombes isolées par des allées (y {rangees}), angles droits")

	# Bougies, bancs.
	chandeliers = set(plan.cells_of("b"))
	lampes = {p.cells[0] for p in plan.of_kind("lamp")}
	r.critere(chandeliers == lampes and len(lampes) >= 4,
		f"{len(lampes)} bougies : un halo `lamp` par chandelier, en positions")
	r.critere(len(plan.cells_of("n")) >= 4 and all(_voisines_libres(carte, c, avec)
		for c in plan.cells_of("n")), "bancs accessibles")
	return r.ok


VERIFICATEURS = {"lavanville": verifier_lavanville, "tour_pokemon_rdc": verifier_tour}


def main() -> int:
	chemins = [Path(a) for a in sys.argv[1:]] or [PLANS / f"{n}.txt" for n in VERIFICATEURS]
	ok = True
	for chemin in chemins:
		verifier = VERIFICATEURS.get(chemin.stem)
		if verifier is None:
			print(f"{chemin} : aucune règle connue (attendu : {', '.join(VERIFICATEURS)})")
			ok = False
			continue
		bon = verifier(chemin.resolve())
		print("Plan conforme." if bon else "Plan NON conforme.")
		ok &= bon
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
