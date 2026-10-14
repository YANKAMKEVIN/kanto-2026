#!/usr/bin/env python3
"""Vérifie les grilles de Céladopole (jalon 20, dossier 23 §7 à §11 ; préparées le 2026-10-14).

Grilles : `tools/plans/celadopole.txt` (ville, 70 × 46), `celadopole_arene.txt`,
`celadopole_magasin_{rdc,2e,3e,4e,5e,toit,ascenseur}.txt`,
`celadopole_residence_{rdc,1er,2e,3e,toit,maison_toit}.txt`, `celadopole_restaurant.txt`,
`celadopole_maison_chef.txt`, `celadopole_hotel.txt`. Le Centre Pokémon réutilise l'intérieur
EXISTANT : aucune grille. Lecture par `plan_grille.lire` ; déplacements de
`plan_check_azuria.Carte` (4 directions, portes `D` terminales dans la ville).

Critères, par carte :
  Ville — 70 × 46 ; raccord EST imposé (69, 21..23) ↔ Route 7 (0, 10..12), déclaré dans l'en-tête
    (et recoupé avec `route_7.txt` s'il existe) ; carte fermée partout ailleurs, sortie OUEST
    fermée par une haie d'arbres et un talus (examen, aucun warp) ; toutes les portes atteignables
    depuis l'entrée est ; **Arène inaccessible sans l'arbuste à Couper** (case conditionnelle),
    **toute la ville accessible sans** ; Casino à 2 cases de porte, façade de l'ancien Coin à lots
    sans porte ; escalier de service au NORD de la Résidence ; emprises rectangulaires et portes
    en bas de façade ; angles droits ; eau jamais praticable ; 12 habitants + 2 Rocket, aucun sur
    une case de passage (aucune coupure, devant de porte libre) ; objet caché atteignable.
  Arène — 17 × 16 ; Erika atteignable par le tour SANS le second arbuste (et le raccourci le
    raccourcit d'au moins 8 pas) ; **E5 inévitable** (sa ligne couvre l'unique accès à la
    porte-haie), E1..E4 évitables (séparément et ensemble, avec et sans arbuste).
  Intérieurs — tailles, sortie, escaliers/ascenseur aux mêmes cases à chaque étage, PNJ bien
    placés (accès, aucune coupure), toutes les cases connexes.
  Graphe des warps — cibles et arrivées existantes, retours réciproques, ascenseur du magasin
    (RdC → 5e, jamais le toit), **toit de la Résidence atteignable UNIQUEMENT par l'escalier de
    service** (pas par l'escalier principal), maison du toit atteignable seulement par le toit.

Usage : python3 tools/art/plan_check_celadopole.py            (toutes les grilles ; code 1 si échec)
        python3 tools/art/plan_check_celadopole.py tools/plans/celadopole_arene.txt
(Non encore branché sur `plan_check.py` : une ligne d'enregistrement à l'intégration.)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import INF, ligne_de_vue  # noqa: E402
from plan_check_azuria import (Carte, Rapport, _acces, _boite, _composantes, _decale,  # noqa: E402
	_en_diagonale, _approche_ferme, _largeur_min, _libres_du_bord, _nom, _role)
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]

# ------------------------------------------------------------------------------ constantes
VILLE = (70, 46)
RACCORD_EST = ("celadon_city", 69, (21, 23))      # colonne 69, rangées 21..23
RACCORD_ROUTE_7 = ("route_7", 0, (10, 12))         # colonne 0, rangées 10..12 (autre session)
HABITANTS = 12
ROCKET = 2
# Emprises (caractère → largeur, hauteur, colonnes de porte relatives dans la rangée du bas ;
# None = aucune porte).
EMPRISES = {
	"H": (14, 9, (6, 7)),    # grand magasin
	"R": (12, 8, (5, 6)),    # Résidence
	"U": (4, 4, (1, 2)),     # escalier de service
	"C": (8, 7, (3, 4)),     # Centre (bldg_centre_01 réutilisé)
	"K": (12, 7, (5, 6)),    # Casino
	"L": (8, 7, None),       # façade de l'ancien Coin à lots
	"Z": (12, 7, (5, 6)),    # Arène
	"M": (7, 6, (3,)),       # maison du chef
	"Q": (8, 7, (3, 4)),     # restaurant
	"I": (10, 7, (4, 5)),    # hôtel
}
# Porte (ident du warp) → (caractère de l'emprise, carte cible).
PORTES = {
	"porte_magasin": ("H", "celadon_dept_gf"), "porte_residence": ("R", "celadon_mansion_gf"),
	"porte_service": ("U", "celadon_mansion_roof"), "porte_centre": ("C", "celadon_center"),
	"porte_casino": ("K", "celadon_game_corner"), "porte_arene": ("Z", "celadon_gym"),
	"porte_chef": ("M", "celadon_chief_house"), "porte_restaurant": ("Q", "celadon_restaurant"),
	"porte_hotel": ("I", "celadon_hotel"),
}
CASINO_PORTE = [(39, 32), (40, 32)]
IDS = {
	"celadopole": "celadon_city",
	"celadopole_magasin_rdc": "celadon_dept_gf", "celadopole_magasin_2e": "celadon_dept_2f",
	"celadopole_magasin_3e": "celadon_dept_3f", "celadopole_magasin_4e": "celadon_dept_4f",
	"celadopole_magasin_5e": "celadon_dept_5f", "celadopole_magasin_toit": "celadon_dept_roof",
	"celadopole_magasin_ascenseur": "celadon_dept_elevator",
	"celadopole_residence_rdc": "celadon_mansion_gf", "celadopole_residence_1er": "celadon_mansion_1f",
	"celadopole_residence_2e": "celadon_mansion_2f", "celadopole_residence_3e": "celadon_mansion_3f",
	"celadopole_residence_toit": "celadon_mansion_roof",
	"celadopole_residence_maison_toit": "celadon_mansion_roof_house",
	"celadopole_arene": "celadon_gym", "celadopole_restaurant": "celadon_restaurant",
	"celadopole_maison_chef": "celadon_chief_house", "celadopole_hotel": "celadon_hotel",
}
FICHIER = {v: k for k, v in IDS.items()}
# Cartes d'une autre session ou existantes : on ne vérifie que la déclaration côté Céladopole.
EXTERNES = {"route_7", "celadon_center", "celadon_game_corner"}
TAILLES = {
	"celadopole_arene": (17, 16), "celadopole_magasin_ascenseur": (6, 6),
	"celadopole_magasin_toit": (20, 11), "celadopole_residence_toit": (16, 10),
	"celadopole_residence_maison_toit": (10, 8),
	**{n: (20, 13) for n in ("celadopole_magasin_rdc", "celadopole_magasin_2e",
		"celadopole_magasin_3e", "celadopole_magasin_4e", "celadopole_magasin_5e")},
	**{n: (16, 11) for n in ("celadopole_residence_rdc", "celadopole_residence_1er",
		"celadopole_residence_2e", "celadopole_residence_3e")},
	**{n: (15, 10) for n in ("celadopole_restaurant", "celadopole_maison_chef",
		"celadopole_hotel")},
}
ETAGES_MAGASIN = ["gf", "2f", "3f", "4f", "5f"]
ETAGES_RESIDENCE = ["gf", "1f", "2f", "3f"]
GAIN_RACCOURCI = 8                  # l'arbuste intérieur économise au moins 8 pas
TOUR_MIN = 24                       # le tour fait au moins 24 pas


# ------------------------------------------------------------------------------- utilitaires
def _fmt(cells: list[Case]) -> str:
	xs = sorted({x for x, _ in cells})
	ys = sorted({y for _, y in cells})
	if len(ys) == 1:
		return f"({xs[0]}, {ys[0]})" if len(xs) == 1 else f"({xs[0]}..{xs[-1]}, {ys[0]})"
	return f"({xs[0]}, {ys[0]}..{ys[-1]})" if len(xs) == 1 else f"({xs[0]}..{xs[-1]}, {ys[0]}..{ys[-1]})"


def _en_tete(chemin: Path) -> str:
	return "\n".join(ligne for ligne in chemin.read_text(encoding="utf-8").splitlines()
		if ligne.startswith("#"))


def _avec_cases(plan: Plan, chars: str) -> Plan:
	"""Copie du plan où `chars` est praticable et où les arbustes à Couper (kind « coupe ») ne
	bloquent plus : la ville / la salle APRÈS la Coupe."""
	positions = {i: p for i, p in plan.positions.items() if p.kind != "coupe"}
	return Plan(plan.width, plan.height, plan.rows, positions, plan.praticables | set(chars))


def _coupes(plan: Plan) -> list[Case]:
	return [c for p in plan.of_kind("coupe") for c in p.cells]


def _orphelines(plan: Plan, carte: Carte, dist: dict[Case, int]) -> list[Case]:
	return [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in carte.bloquees and (x, y) not in dist]


def _warps(plan: Plan):
	return plan.of_kind("warp")


# ===================================================================================== ville
def verifier_celadopole(chemin: Path) -> bool:
	plan = lire(chemin)
	r = Rapport(f"Céladopole — {_nom(chemin)} : {plan.width} × {plan.height}")
	pos = plan.positions
	entete = _en_tete(chemin)
	carte = Carte(plan)                                   # sans Coupe
	plan_c = _avec_cases(plan, "W")
	coupes = _coupes(plan)
	carte_c = Carte(plan_c)                               # avec Coupe : l'arbuste devient du sol
	r.critere((plan.width, plan.height) == VILLE,
		f"taille {plan.width} × {plan.height} (attendu {VILLE[0]} × {VILLE[1]})")

	# 1. Raccord est.
	_, col, (ya, yb) = RACCORD_EST
	_, col7, (y7a, y7b) = RACCORD_ROUTE_7
	est = [(col, y) for y in range(ya, yb + 1)]
	warps_est = sorted(pos["warp_est"].cells)
	spawns_est = sorted(pos["from_route_7"].cells)
	bords = _libres_du_bord(carte)
	r.critere(bords == est and warps_est == est and spawns_est == est
		and pos["warp_est"].attrs.get("to") == "route_7",
		f"raccord est : bord praticable = warps = spawns = (69, {ya}..{yb}) ; aucun autre bord ouvert "
		f"({len(bords)} case(s) libre(s) au bord)")
	motif = rf"Route 7 \({col7}, {y7a}\.\.{y7b}\)"
	r.critere(bool(re.search(motif, entete)) and f"({col}, {ya}..{yb})" in entete
		and len(est) == 3,
		f"raccord déclaré dans l'en-tête : Céladopole ({col}, {ya}..{yb}) ↔ Route 7 ({col7}, "
		f"{y7a}..{y7b}), 3 rangées de part et d'autre")
	route_7 = chemin.with_name("route_7.txt")
	if route_7.exists():
		p7 = lire(route_7)
		ouest = sorted(c for c in (_libres_du_bord(Carte(p7))) if c[0] == 0)
		r.critere([y for _, y in ouest] == list(range(y7a, y7b + 1)),
			f"route_7.txt présent : bord ouest praticable rangées {[y for _, y in ouest]} = "
			f"{y7a}..{y7b}")
	else:
		r.info("route_7.txt absent (autre session) : raccord ouest de la Route 7 non recoupé ici")
	avenue_est = all(plan.at(x, y) in plan.praticables for x in range(62, 70) for y in (21, 22, 23)
		) and all(plan.at(x, y) not in plan.praticables for x in range(62, 70) for y in (20, 24))
	r.critere(avenue_est, "l'avenue fait exactement 3 cases (y 21..23) de x 62 au raccord")

	# 2. Sortie ouest fermée (H-4).
	ouest_ok = all(plan.at(x, y) not in plan.praticables for x in range(0, 4) for y in range(plan.height))
	haie = plan.at(2, 22) == "T" and plan.at(3, 22) == "T" and plan.at(0, 22) == "s"
	examen = pos["obstacle_ouest"]
	w_ouest = [c for p in _warps(plan) for c in p.cells if c[0] <= 3]
	r.critere(ouest_ok and haie and not w_ouest and examen.cells == [(3, 22)]
		and carte.libre((4, 22)),
		"sortie ouest fermée : haie d'arbres (x 2..3) + talus (x 0..1), examen (3, 22) lu depuis "
		"(4, 22), aucun warp, aucun panneau")
	r.critere(not any(p.kind == "panneau" and p.cells[0][0] < 8 and 18 <= p.cells[0][1] <= 26
			for p in plan.positions.values()),
		"aucun panneau près de l'obstacle ouest : aucune promesse (modèle du Sentier d'Argenta)")

	# 3. Eau, étang, angles droits.
	eau = set(plan.cells_of("w"))
	x0, y0, x1, y1 = _boite(eau)
	quai = set(plan.cells_of("q"))
	pec = pos["h1_pecheur"].cells[0]
	r.critere("w" not in plan.praticables and not any(carte.libre(c) for c in eau)
		and len(eau) == (x1 - x0 + 1) * (y1 - y0 + 1) and len(_composantes(eau)) == 1
		and not [p.ident for p in plan.positions.values() if p.kind != "repere"
			for c in p.cells if c in eau],
		f"étang {x1 - x0 + 1} × {y1 - y0 + 1} (x {x0}..{x1}, y {y0}..{y1}) : eau jamais praticable, "
		"aucune position sur l'eau")
	r.critere(plan.at(*pec) == "q" and any(_decale(pec, d) in eau for d in DIRS)
		and all(plan.at(x, y) == "q" for x in range(x0 - 2, x1 + 3) for y in (y0 - 2, y0 - 1, y1 + 1))
		and all(plan.at(x, y) == "q" for x in (x0 - 2, x0 - 1, x1 + 1, x1 + 2)
			for y in range(y0 - 2, y1 + 2)),
		f"pêcheur {pec} sur le quai, au bord de l'eau ; quai praticable tout autour (2 cases au nord, à l'ouest et à l'est)")
	diag = {c: _en_diagonale(plan, c) for c in "wxqnjFGHRUCKLZMQI"}
	r.critere(not any(diag.values()), "angles droits : aucune diagonale de 2 × 2 (étang, haies, "
		f"quai, bâtiments, massifs) {[(c, d[:2]) for c, d in diag.items() if d]}")

	# 4. Emprises et portes.
	fautes_emprise = []
	for car, (larg, haut, cols) in EMPRISES.items():
		cases = set(plan.cells_of(car))
		if not cases:
			fautes_emprise.append(f"{car} absent")
			continue
		bx0, by0, bx1, by1 = _boite(cases)
		if (bx1 - bx0 + 1, by1 - by0 + 1) != (larg, haut):
			fautes_emprise.append(f"{car} {bx1 - bx0 + 1}×{by1 - by0 + 1} au lieu de {larg}×{haut}")
			continue
		tout = {(x, y) for y in range(by0, by1 + 1) for x in range(bx0, bx1 + 1)}
		interdits = [c for c in tout if plan.at(*c) not in (car, "D")]
		portes_car = sorted(c for c in tout if plan.at(*c) == "D")
		attendu = [(bx0 + k, by1) for k in cols] if cols else []
		if interdits or portes_car != attendu:
			fautes_emprise.append(f"{car} portes {portes_car} au lieu de {attendu} / étrangères "
				f"{interdits[:2]}")
	r.critere(not fautes_emprise,
		"emprises rectangulaires aux dimensions déclarées, portes sur la rangée du bas, aux colonnes "
		f"centrales {fautes_emprise}")
	cases_d = set(plan.cells_of("D"))
	cases_warps = {c for ident, p in pos.items() if ident in PORTES for c in p.cells}
	r.critere(cases_d == cases_warps and set(PORTES) <= set(pos)
		and all(pos[i].attrs.get("to") == cible for i, (_, cible) in PORTES.items()),
		f"chaque case « D » est une porte déclarée et réciproquement ({len(PORTES)} portes : "
		"magasin, Résidence, escalier de service, Centre, Casino, Arène, chef, restaurant, hôtel)")
	en_tete_ok = all(_fmt(pos[i].cells) in entete for i in PORTES)
	r.critere(en_tete_ok, "toutes les portes sont déclarées dans l'en-tête avec leurs coordonnées")
	casino = pos["porte_casino"].cells
	r.critere(casino == CASINO_PORTE and len(casino) == 2
		and all(plan.at(*c) == "D" and plan.at(c[0], c[1] - 1) == "K" for c in casino)
		and all(carte.libre((c[0], c[1] + 1)) for c in casino),
		f"porte du Casino {_fmt(casino)} : 2 cases en bas de la façade, parvis (39..40, 33) libre ; "
		"intérieur : porte d'entrée en bas, 2 cases")
	facade = set(plan.cells_of("L"))
	r.critere(len(facade) == 56 and not any(c in cases_warps for c in facade)
		and not any(plan.at(*c) == "D" for c in facade)
		and not any(p.kind in ("warp", "panneau", "examen") and any(c in facade for c in p.cells)
			for p in plan.positions.values()) and "facade_lots" in pos,
		"façade de l'ancien Coin à lots (8 × 7) : décor, SANS porte, sans warp ni texte")
	service = pos["porte_service"].cells
	rx0, ry0, rx1, ry1 = _boite(set(plan.cells_of("R")) | set(pos["porte_residence"].cells))
	ux0, uy0, ux1, uy1 = _boite(set(plan.cells_of("U")) | set(service))
	r.critere(uy1 < ry0 and ux0 >= rx0 and ux1 <= rx1 and uy1 == service[0][1],
		f"escalier de service {_fmt(service)} : tour U (x {ux0}..{ux1}, y {uy0}..{uy1}) au NORD de "
		f"la Résidence (y {ry0}..{ry1}), porte au bas de la tour, côté ruelle de service")

	# 5. Accessibilité : sans / avec Coupe.
	entrees = est
	dist = carte.distances(entrees)
	dist_c = carte_c.distances(entrees)
	enclos = sorted(set(dist_c) - set(dist))
	devant = {i: [(c[0], c[1] + 1) for c in p.cells] for i, p in pos.items() if i in PORTES}
	hors_arene = [i for i in PORTES if i != "porte_arene"]
	r.critere(all(any(c in dist for c in pos[i].cells) or all(
		d in dist for d in devant[i]) for i in hors_arene)
		and all(d in dist for i in hors_arene for d in devant[i]),
		"toutes les portes (hors Arène) atteignables depuis l'entrée est, SANS Coupe : "
		+ ", ".join(f"{i[6:]} {min(dist[d] for d in devant[i])}" for i in hors_arene
			if all(d in dist for d in devant[i])) + " pas")
	arene_devant = devant["porte_arene"]
	r.critere(len(coupes) == 1 and coupes == [(19, 37)] and plan.at(19, 37) == "W"
		and plan.at(18, 37) == "." and plan.at(20, 37) == "p"
		and not any(c in dist for c in pos["porte_arene"].cells + arene_devant)
		and all(c in dist_c for c in pos["porte_arene"].cells + arene_devant),
		f"Arène INACCESSIBLE sans l'arbuste à Couper {coupes} (aucune case de l'enclos atteinte), "
		f"accessible avec : porte à {min(dist_c[c] for c in arene_devant)} pas de l'entrée est")
	bx0, by0, bx1, by1 = _boite(enclos) if enclos else (0, 0, 0, 0)
	r.critere(bool(enclos) and bx0 >= 4 and bx1 <= 19 and by0 >= 27 and by1 <= 39
		and not any(c in enclos for p in plan.of_kind("pnj") for c in p.cells)
		and not any(c in enclos for p in plan.positions.values() if p.kind in ("panneau", "cache")
			for c in p.cells),
		f"derrière l'arbuste : seulement l'enclos de l'Arène ({len(enclos)} cases, x {bx0}..{bx1}, "
		f"y {by0}..{by1}) ; rien d'autre n'y est caché (PNJ, panneau, objet)")
	orph = _orphelines(plan_c, carte_c, dist_c)
	r.critere(not orph, f"avec la Coupe, toutes les cases praticables sont connexes {orph[:3]}")
	r.critere(not (set(dist_c) - set(dist) - set(enclos)) and len(dist) + len(enclos) == len(dist_c),
		f"sans la Coupe, TOUTE la ville reste accessible ({len(dist)} cases) : seul l'enclos "
		"(Arène) ne l'est pas")

	# 6. Habitants.
	hab = _role(plan, "pnj")
	h = {k: p for k, p in hab.items() if k.startswith("H")}
	rk = {k: p for k, p in hab.items() if k.startswith("R")}
	r.critere(len(h) == HABITANTS and len(rk) == ROCKET and len(hab) == HABITANTS + ROCKET,
		f"{len(h)} habitants + {len(rk)} Rocket en civil (hypothèse : les Rocket en plus des 12)")
	fautes = []
	fronts = {c for cs in devant.values() for c in cs}
	lus = {_decale(p.cells[0], d) for p in plan.positions.values() if p.kind in ("panneau", "cache")
		for d in DIRS}
	for ident, p in sorted(hab.items()):
		c = p.cells[0]
		if plan.at(*c) not in ".pq":
			fautes.append(f"{ident} sur « {plan.at(*c)} »")
		if c in est or c in fronts or any(_decale(c, d) in fronts or _decale(c, d) in est
				for d in DIRS):
			fautes.append(f"{ident} devant une porte ou le raccord")
		if not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"{ident} inatteignable")
		if "facing" not in p.attrs:
			fautes.append(f"{ident} sans facing")
		if c in enclos:
			fautes.append(f"{ident} dans l'enclos")
	# `carte` bloque déjà TOUS les PNJ à la fois : toute case praticable (hors enclos) y reste
	# atteignable, donc aucun PNJ n'est sur une case de coupure.
	orph_pnj = [c for c in _orphelines(plan, carte, dist) if c not in enclos]
	r.critere(not fautes and not orph_pnj,
		"PNJ hors des cases de passage : aucun sur un devant de porte, le raccord ou une coupure "
		f"(tous bloquants à la fois, la ville reste connexe) {fautes[:3]}")
	# largeur des passages en présence des PNJ (≥ 2) : rues, ruelles, quais
	sans_pnj = Carte(Plan(plan.width, plan.height, plan.rows,
		{i: p for i, p in plan.positions.items() if p.kind != "pnj"}, plan.praticables))
	pied_cache = {_decale(cache_c, d) for p in plan.of_kind("cache") for cache_c in p.cells
		for d in DIRS}                    # le pied d'un objet caché : pointe de ruelle tolérée
	etr = []
	for c in sorted(dist):
		if plan.at(*c) in "pq" and c not in pied_cache and _largeur_min(sans_pnj, c) < 2:
			etr.append(c)
	r.critere(not etr, f"pavés et quais ≥ 2 cases de large partout (compagnon) {etr[:4]}")
	# panneaux, objet caché
	cache = pos["celadon_hidden_1"]
	lecteurs = [a for a in _acces(carte, cache) if a in dist]
	r.critere(len(lecteurs) >= 1 and plan.at(*cache.cells[0]) == "p" and cache.attrs.get("item")
		and all(any(a in dist for a in _acces(carte, pos[i])) for i in ("panneau_ville",
			"panneau_arene")) and (21, 35) in dist and (61, 23) in dist and (46, 28) in dist,
		"1 objet caché (ruelle sombre) lu depuis (46, 28) ; panneaux lus depuis (61, 23) et (21, 35)")
	rues = all(plan.at(x, y) == "p" for x in range(20, 24) for y in range(4, 45)
		if (x, y) != (20, 35)) and all(plan.at(x, y) == "p" for x in range(56, 60)
		for y in range(4, 45))
	r.critere(rues, "deux rues nord-sud de 4 cases (rue A x 20..23, rue B x 56..59, de y 4 à y 44)")
	ruelle = all(plan.at(x, y) == "p" for x in range(24, 36) for y in (5, 6)) and all(
		plan.at(x, 4) in "xUD" for x in range(24, 37)) and plan.at(36, 5) == plan.at(36, 6) == "x"
	sombre = all(plan.at(x, y) == "p" for x in (46, 47) for y in range(27, 33)) and all(
		plan.at(x, 26) == "x" for x in (46, 47))
	r.critere(ruelle and sombre, "ruelle de service (y 5..6) et ruelle sombre du Casino (x 46..47) : "
		"culs-de-sac fermés par des haies")
	service_av = [(x, 5) for x in service_front(pos)]
	r.critere(all(c in dist for c in service_av),
		f"ruelle de service atteignable par la rue A : devant l'escalier {_fmt(service_av)} à "
		f"{min(dist[c] for c in service_av)} pas")

	# 7. Statistiques.
	prat = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	r.info(f"statistiques : {prat} cases praticables sur {plan.width * plan.height} "
		f"({100 * prat // (plan.width * plan.height)} %) ; entrée est → Centre "
		f"{min(dist[d] for d in devant['porte_centre'])} pas, → grand magasin "
		f"{min(dist[d] for d in devant['porte_magasin'])}, → Casino "
		f"{min(dist[d] for d in devant['porte_casino'])}, → escalier de service "
		f"{min(dist[d] for d in service_av)}, → Arène (avec Coupe) "
		f"{min(dist_c[c] for c in arene_devant)}")
	graphe = verifier_graphe(chemin.parent)
	return r.ok and graphe


def service_front(pos) -> list[int]:
	return [c[0] for c in pos["porte_service"].cells]


# ======================================================================================= Arène
def verifier_arene(chemin: Path) -> bool:
	plan = lire(chemin)
	r = Rapport(f"Arène d'Erika — {_nom(chemin)} : {plan.width} × {plan.height}")
	pos = plan.positions
	carte = Carte(plan, portes=set())
	plan_c = _avec_cases(plan, "W")
	coupes = _coupes(plan)
	carte_c = Carte(plan_c, portes=set())
	r.critere((plan.width, plan.height) == TAILLES["celadopole_arene"],
		f"taille {plan.width} × {plan.height} (≈ 17 × 15 du dossier)")
	entree = pos["entree"].cells[0]
	sortie = pos["sortie"].cells
	r.critere(sortie == [(x, plan.height - 2) for x in (7, 8, 9)] and plan.cells_of("X") == sortie
		and entree == (8, plan.height - 2) and all(
		plan.at(x, plan.height - 1) == "K" for x in range(plan.width)),
		f"sortie {sortie[0]}…{sortie[-1]} sur l'avant-dernière rangée, entrée {entree} sur la dalle")
	eau = plan.cells_of("w")
	r.critere("w" not in plan.praticables and not any(carte.libre(c) for c in eau)
		and len(_composantes(set(eau))) == 3,
		f"3 bassins décoratifs ({len(eau)} cases : deux au fond autour de la serre d'Erika, un au "
		"coin de l'entrée) : jamais praticables")
	r.critere(len(coupes) == 1 and coupes == [(8, 10)] and plan.at(8, 10) == "W"
		and sum(1 for c in plan.cells_of("W")) == 1,
		f"UN second arbuste à Couper intérieur {coupes} (case conditionnelle) dans la haie du "
		"premier lacet")
	erika = pos["erika"].cells[0]
	parler = pos["parler_erika"].cells[0]
	porte_haie = [(x, 4) for x in range(plan.width) if plan.at(x, 4) in plan.praticables]
	dist = carte.distances([entree])
	dist_c = carte_c.distances([entree])
	tour = dist.get(parler, INF)
	court = dist_c.get(parler, INF)
	r.critere(tour < INF and porte_haie == [(8, 4)] and parler == (8, erika[1] + 1)
		and Carte(plan, {(8, 4)}, portes=set()).distances([entree]).get(parler, INF) >= INF,
		f"Erika atteignable par le TOUR, SANS le second arbuste : {tour} pas jusqu'à {parler} ; "
		"unique accès = la porte-haie (8, 4)")
	r.critere(tour >= TOUR_MIN and court <= tour - GAIN_RACCOURCI,
		f"le raccourci est un vrai raccourci et reste facultatif : {court} pas avec l'arbuste, "
		f"{tour} sans (économie ≥ {GAIN_RACCOURCI}, tour ≥ {TOUR_MIN})")
	dress = _role(plan, "dresseur")
	r.critere(sorted(dress) == ["E1", "E2", "E3", "E4", "E5"], f"5 Dresseuses E1..E5 ({sorted(dress)})")
	vues = {k: ligne_de_vue(carte, p) for k, p in dress.items()}
	complet = all(len(vues[k]) == int(p.attrs["sight"]) for k, p in dress.items())
	r.critere(complet and all(plan.at(*c) == "." for v in vues.values() for c in v),
		"chaque Dresseuse voit toute sa ligne (sur le sol) : "
		+ ", ".join(f"{k} {len(v)}" for k, v in sorted(vues.items())))
	e5 = vues["E5"]
	for nom, c in (("sans arbuste", carte), ("avec arbuste", carte_c)):
		d = c.sans(e5).distances([entree]).get(parler, INF)
		r.critere(d >= INF, f"E5 INÉVITABLE {nom} : sa ligne {e5[0]}…{e5[-1]} couvre l'unique accès "
			"à la porte-haie ; sans ces cases Erika est inatteignable")
	e5_pos = dress["E5"].cells[0]
	r.critere(e5 == [(8, 5), (8, 4)] and dress["E5"].attrs.get("mandatory") == "1"
		and e5_pos == (8, 6) and abs(e5_pos[1] - erika[1]) <= 4,
		f"E5 {e5_pos} : juste avant Erika (porte-haie à 2 cases d'elle), obligatoire")
	for nom, c in (("sans arbuste", carte), ("avec arbuste", carte_c)):
		ok = True
		det = []
		for k in ("E1", "E2", "E3", "E4"):
			d = c.sans(vues[k]).distances([entree]).get(parler, INF)
			ok &= d < INF
			det.append(f"{k} {d}")
		tous = set().union(*(vues[k] for k in ("E1", "E2", "E3", "E4")))
		d_tous = c.sans(tous).distances([entree]).get(parler, INF)
		r.critere(ok and d_tous < INF, f"E1..E4 évitables {nom} : séparément ({', '.join(det)} pas) "
			f"et ensemble ({d_tous} pas, E5 mis à part)")
	cibles = [[parler], list(sortie)]
	sauf_e5 = {k: p for k, p in dress.items() if k != "E5"}
	fermes = _approche_ferme(plan, carte, sauf_e5, vues, cibles, dist)
	r.critere(not fermes, f"l'approche de E1..E4 ne ferme aucun passage (E5 est détectée sur (8, 5), elle ne bouge pas) {fermes[:3]}")
	orph = _orphelines(plan, carte, dist)
	r.critere(not orph, f"sans Coupe, toutes les cases praticables connexes (bloquants compris) "
		f"{orph[:3]}")
	fautes = [i for i in ("erika", "dresseuse_e1", "dresseuse_e2", "dresseuse_e3", "dresseuse_e4",
		"dresseuse_e5") if plan.at(*pos[i].cells[0]) not in ".w" or "facing" not in pos[i].attrs]
	fautes += [i for i in ("erika",) if plan.at(*pos[i].cells[0]) != "."]
	r.critere(not fautes, f"Erika et les Dresseuses sur le sol, orientées {fautes}")
	r.critere(plan.height > 11 and plan.width <= 24,
		f"salle {plan.width} × {plan.height} : plus haute que l'écran, la caméra suit en hauteur")
	r.info(f"entrée → Erika : {tour} pas par le tour, {court} avec le raccourci")
	return r.ok


# ================================================================================= intérieurs
def _etage(stem: str) -> str:
	return IDS[stem].rsplit("_", 1)[-1]


def verifier_interieur(chemin: Path) -> bool:
	stem = chemin.stem
	plan = lire(chemin)
	r = Rapport(f"Intérieur {stem} ({IDS[stem]}) — {_nom(chemin)} : {plan.width} × {plan.height}")
	pos = plan.positions
	carte = Carte(plan, portes=set())
	r.critere((plan.width, plan.height) == TAILLES[stem],
		f"taille {plan.width} × {plan.height} (attendu {TAILLES[stem][0]} × {TAILLES[stem][1]})")
	h, w = plan.height, plan.width
	murs = all(plan.at(x, 0) == "K" and plan.at(x, 1) in "KP" for x in range(w)) and all(
		plan.at(0, y) == "K" and plan.at(w - 1, y) == "K" for y in range(h)) and all(
		plan.at(x, h - 1) == "K" for x in range(w))
	r.critere(murs, "murs : fond sur 2 rangées au moins, parois, dernière rangée")
	depart_cases = [c for p in pos.values() if p.kind == "spawn" for c in p.cells]
	depart = pos["entree"].cells[0] if "entree" in pos else depart_cases[0]
	dist = carte.distances([depart])
	dehors = [c for p in pos.values() if p.kind == "spawn" for c in p.cells if c not in dist]
	r.critere(not dehors, f"tous les points d'arrivée sont dans la même salle connexe {dehors[:3]}")
	# sortie
	exit_attendu = stem in ("celadopole_magasin_rdc", "celadopole_residence_rdc", "celadopole_arene",
		"celadopole_residence_maison_toit", "celadopole_restaurant", "celadopole_maison_chef",
		"celadopole_hotel", "celadopole_magasin_ascenseur")
	xs = plan.cells_of("X")
	if exit_attendu:
		sortie = pos["sortie"].cells
		r.critere(xs == sortie and all(y == h - 2 for _, y in xs) and depart in sortie
			and all(plan.at(x, h - 1) == "K" for x, _ in xs) and depart in dist
			or stem == "celadopole_magasin_ascenseur" and xs == sortie,
			f"sortie {_fmt(sortie)} sur l'avant-dernière rangée (paillasson), entrée {depart}")
	else:
		r.critere(not xs and "sortie" not in pos, "pas de sortie sur la rue (étage)")
	# warps
	for p in _warps(plan):
		accessible = any(a in dist for c in p.cells for a in _voisines(carte, c))
		r.critere(accessible and "to" in p.attrs and "spawn" in p.attrs,
			f"warp {p.ident} {_fmt(p.cells)} → {p.attrs.get('to')} atteignable, cible déclarée")
	# PNJ
	fautes = []
	for p in plan.positions.values():
		if p.kind not in ("pnj", "pokemon", "dresseur"):
			continue
		c = p.cells[0]
		if plan.at(*c) != ".":
			fautes.append(f"{p.ident} sur « {plan.at(*c)} »")
		libre = any(a in dist for a in _acces(carte, p))
		comptoir = any(plan.at(*_decale(c, d)) == "B" and _decale(_decale(c, d), d) in dist
			for d in DIRS)
		if not (libre or comptoir):
			fautes.append(f"{p.ident} sans accès")
		if p.kind == "pnj" and "facing" not in p.attrs:
			fautes.append(f"{p.ident} sans facing")
		if p.attrs.get("shop") or p.attrs.get("role", "").startswith("V"):
			d = [d for d in DIRS if plan.at(*_decale(c, d)) == "B"]
			if not d:
				fautes.append(f"{p.ident} sans comptoir devant lui")
			elif _decale(_decale(c, d[0]), d[0]) not in dist:
				fautes.append(f"{p.ident} : case devant le comptoir inaccessible")
	orph = _orphelines(plan, carte, dist)
	r.critere(not fautes and not orph, "PNJ bien placés, accessibles (comptoir compris) et aucune "
		f"coupure ; toutes les cases praticables connexes {fautes[:3]} {orph[:3]}")
	for p in plan.of_kind("panneau") + plan.of_kind("examen") + plan.of_kind("decor") + \
			plan.of_kind("objet_don"):
		if p.cells[0][1] == 0:
			continue
		lisible = any(a in dist for a in _acces(carte, p))
		r.critere(lisible, f"{p.ident} {_fmt(p.cells)} lisible depuis une case atteignable")
	# spécifiques
	if stem.startswith("celadopole_magasin") and stem != "celadopole_magasin_ascenseur":
		_verifier_etage_magasin(r, plan, stem)
	if stem.startswith("celadopole_residence"):
		_verifier_residence(r, plan, stem)
	if stem == "celadopole_magasin_ascenseur":
		_verifier_ascenseur(r, plan)
	if stem == "celadopole_residence_maison_toit":
		ball = pos["poke_ball_evoli"]
		r.critere(ball.kind == "objet_don" and ball.cells == [(4, 3)] and plan.at(4, 3) == "t"
			and (4, 4) in dist and ball.attrs.get("item") == "eevee",
			"Poké Ball d'Évoli sur la table (4, 3), prise depuis (4, 4) ↑ ; aucun PNJ")
		r.critere(not plan.of_kind("pnj"), "aucun PNJ dans la maison du toit")
	return r.ok


def _voisines(carte: Carte, c: Case) -> list[Case]:
	return [_decale(c, d) for d in DIRS if carte.libre(_decale(c, d))] + [c]


def _verifier_etage_magasin(r: Rapport, plan: Plan, stem: str) -> None:
	niv = _etage(stem)
	montants = plan.cells_of("S")
	descendants = plan.cells_of("Z")
	ascenseur = plan.cells_of("V")
	if niv == "roof":
		r.critere(not montants and not ascenseur and descendants == [(2, 2), (3, 2)],
			"toit : un SEUL escalier (descendant, x 2..3) vers le 5e ; ni ascenseur ni escalier montant")
		dist = [p for p in plan.of_kind("decor") if p.attrs.get("item")]
		r.critere(len(dist) == 3 and sorted(int(p.attrs["price"]) for p in dist) == [200, 300, 350],
			"3 distributeurs : Eau Fraîche 200, Soda Cool 300, Limonade 350 (§9)")
		r.critere(len(plan.of_kind("pnj")) == 1, "la fillette du toit (échange de boisson)")
		return
	attendu_s = [(2, 2), (3, 2)]
	r.critere(montants == attendu_s and ascenseur == [(16, 2), (17, 2)]
		and (descendants == [(4, 2), (5, 2)] if niv != "gf" else not descendants),
		"escaliers à l'OUEST (S x 2..3, Z x 4..5), ascenseur à l'EST (V x 16..17), rangée 2, "
		"mêmes cases à chaque étage" + ("" if niv != "gf" else " ; le RdC n'a pas d'escalier descendant"))
	vend = [p for p in plan.of_kind("pnj") if p.attrs.get("role", "").startswith("V")]
	attendu = {"gf": 1, "2f": 2, "3f": 0, "4f": 2, "5f": 1}[niv]
	r.critere(len(vend) == attendu,
		f"{len(vend)} vendeur(s)/hôtesse (attendu {attendu} : accueil, 2 vendeurs au 2e, 2 au 4e, "
		"0 au 3e, Objets X conditionnel au 5e)")


def _verifier_residence(r: Rapport, plan: Plan, stem: str) -> None:
	niv = _etage(stem)
	montants = plan.cells_of("S")
	if niv == "gf":
		r.critere(montants == [(2, 2), (3, 2)] and not plan.cells_of("Z") and len(plan.of_kind("pnj")) == 1,
			"hall : un escalier montant, la vieille dame qui ne donne rien")
	elif niv in ("1f", "2f"):
		r.critere(montants == [(2, 2), (3, 2)] and plan.cells_of("Z") == [(4, 2), (5, 2)]
			and len(plan.of_kind("pnj")) == 2, "palier : S + Z, 2 habitants")
	elif niv == "3f":
		r.critere(not montants and plan.cells_of("Z") == [(4, 2), (5, 2)] and plan.at(8, 2) == "f"
			and plan.of_kind("examen")[0].cells == [(8, 2)] and not plan.of_kind("warp")[1:2]
			and len(_warps(plan)) == 1,
			"3e : AUCUN escalier montant (pas d'accès au toit), porte « Bureau privé » fermée en "
			"(8, 2), sans warp")
	elif niv == "roof":
		warps = {p.attrs["to"] for p in _warps(plan)}
		r.critere(plan.cells_of("Z") == [(2, 2), (3, 2)] and not montants
			and warps == {"celadon_city", "celadon_mansion_roof_house"} and not plan.of_kind("pnj"),
			"toit : seul l'escalier de service le relie à l'extérieur ; porte de la maison du toit ; "
			"aucun PNJ")
		n = set(plan.cells_of("N"))
		x0, y0, x1, y1 = _boite(n | set(plan.cells_of("D")))
		r.critere((x1 - x0 + 1, y1 - y0 + 1) == (5, 4) and plan.cells_of("D") == [(10, 5)],
			"maison du toit 5 × 4, porte en (10, 5)")


def _verifier_ascenseur(r: Rapport, plan: Plan) -> None:
	p = plan.positions["panneau_etages"]
	sortie = plan.positions["sortie"]
	r.critere(p.attrs["floors"] == "gf,2f,3f,4f,5f" == sortie.attrs["floors"]
		and sortie.attrs["to"] == "@origin" and "roof" not in p.attrs["floors"],
		"l'ascenseur du magasin dessert RdC, 2e, 3e, 4e, 5e ; PAS le toit ; aucune clé exigée")


# ==================================================================================== graphe
def _charger(dossier: Path) -> dict[str, Plan]:
	return {IDS[s]: lire(dossier / f"{s}.txt") for s in IDS}


def verifier_graphe(dossier: Path, r_parent: Rapport | None = None) -> bool:
	r = Rapport("Graphe des warps de Céladopole (18 cartes + 3 externes)")
	cartes = _charger(dossier)
	aretes: dict[str, list[tuple[str, str, str]]] = {m: [] for m in cartes}   # (cible, ident, spawn)
	fautes = []
	for mid, plan in cartes.items():
		for p in _warps(plan):
			cible, spawn = p.attrs.get("to", ""), p.attrs.get("spawn", "")
			cibles = (plan.positions.get("sortie", p).attrs.get("floors", "").split(",")
				if cible == "@origin" else [cible])
			for c in cibles:
				m = f"celadon_dept_{c}" if cible == "@origin" else c
				aretes[mid].append((m, p.ident, spawn))
				if m in EXTERNES:
					continue
				if m not in cartes:
					fautes.append(f"{mid}.{p.ident} → carte inconnue {m}")
					continue
				ident_spawn = "entree" if spawn == "entrance" else spawn
				cible_plan = cartes[m]
				sp = cible_plan.positions.get(ident_spawn)
				if sp is None or sp.kind != "spawn":
					fautes.append(f"{mid}.{p.ident} → {m} : arrivée « {spawn} » absente")
				else:
					bad = [c2 for c2 in sp.cells if cible_plan.at(*c2) not in cible_plan.praticables
						or cible_plan.at(*c2) in "SZVD"]
					if bad:
						fautes.append(f"{m}.{ident_spawn} sur une case non praticable ou une porte {bad}")
	r.critere(not fautes, f"chaque warp a une cible et une arrivée existantes, sur une case libre "
		f"{fautes[:3]}")
	# retours réciproques
	sans_retour = []
	for mid, liste in aretes.items():
		for (m, ident, _) in liste:
			if m in EXTERNES:
				continue
			if not any(t == mid for (t, _, _) in aretes[m]):
				sans_retour.append(f"{mid}→{m}")
	r.critere(not sans_retour, f"tout passage a son retour (aller-retour sur chaque porte) {sans_retour[:3]}")
	# accessibilité depuis l'entrée est
	def atteints(interdits: set[tuple[str, str]]) -> set[str]:
		vus, pile = {"celadon_city"}, ["celadon_city"]
		while pile:
			m = pile.pop()
			for (t, ident, _) in aretes.get(m, []):
				if (m, ident) in interdits or t in EXTERNES or t in vus:
					continue
				vus.add(t)
				pile.append(t)
		return vus
	tout = atteints(set())
	r.critere(tout == set(cartes), f"toutes les cartes atteignables depuis la ville "
		f"({len(tout)}/{len(cartes)}) {sorted(set(cartes) - tout)[:3]}")
	sans_service = atteints({("celadon_city", "porte_service")})
	toit = {"celadon_mansion_roof", "celadon_mansion_roof_house"}
	r.critere(not (sans_service & toit) and toit <= tout,
		"le toit de la Résidence et sa maison (Évoli) NE sont PAS atteignables par l'escalier "
		"principal (sans la porte de service) ; ils le sont par l'escalier de service")
	r.critere([t for (t, ident, _) in aretes["celadon_city"] if t == "celadon_mansion_roof"]
		== ["celadon_mansion_roof"] and sum(1 for m, l in aretes.items() for (t, _, _) in l
			if t == "celadon_mansion_roof") == 2 and all(
		t != "celadon_mansion_roof" for m, l in aretes.items() if m.startswith("celadon_mansion_")
		and m not in toit for (t, _, _) in l),
		"seuls l'escalier de service (ville) et la maison du toit mènent au toit ; aucun étage n'y mène")
	roof_dept = sum(1 for m, l in aretes.items() for (t, _, _) in l if t == "celadon_dept_roof")
	r.critere(roof_dept == 1 and any(t == "celadon_dept_roof" for (t, _, _) in aretes["celadon_dept_5f"]),
		"le toit du grand magasin ne se rejoint que par l'escalier du 5e (pas par l'ascenseur)")
	asc = [(m, i) for m, l in aretes.items() for (t, i, _) in l if t == "celadon_dept_elevator"]
	r.critere(sorted(m for m, _ in asc) == sorted(f"celadon_dept_{e}" for e in ETAGES_MAGASIN)
		and sorted(t for (t, _, _) in aretes["celadon_dept_elevator"]) == sorted(
		f"celadon_dept_{e}" for e in ETAGES_MAGASIN),
		"ascenseur : porte à chaque étage RdC..5e, et sorties vers ces 5 étages seulement")
	ok = r.ok
	if r_parent is not None:
		r_parent.ok &= ok
	return ok


# ======================================================================================= main
VERIFICATEURS = {"celadopole": verifier_celadopole, "celadopole_arene": verifier_arene,
	**{s: verifier_interieur for s in IDS if s not in ("celadopole", "celadopole_arene")}}


def main() -> int:
	chemins = [Path(a) for a in sys.argv[1:]] or [PLANS / f"{n}.txt" for n in VERIFICATEURS]
	ok = True
	for chemin in chemins:
		verifier = VERIFICATEURS.get(chemin.stem)
		if verifier is None:
			print(f"{chemin} : aucune règle connue")
			ok = False
			continue
		bon = verifier(chemin.resolve())
		print("Plan conforme." if bon else "Plan NON conforme.")
		ok &= bon
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
