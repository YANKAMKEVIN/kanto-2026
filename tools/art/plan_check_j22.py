#!/usr/bin/env python3
"""Vérifie les grilles du jalon 22 (lot 22.0, T6 ; docs/tech/jalon-22.md §0.4, §2.3, §2.10, §2.11 ;
dossier 25 §4 à §11) par recherche de chemin, et les cases pêchables des cartes déjà livrées.

Grilles (tools/plans/) : route_12_sud, route_13, route_14, route_15, route_15_gate (1F + 2F côte à côte),
route_16_gate, route_16_west, route_17, route_18, route_18_gate, parmanie.

Critères :
  - lecture, dimensions (plan §2.11), légende connue, bords fermés sauf les raccords (warps) ;
  - raccords entre cartes : chaque warp `to=` vise une carte et un point d'arrivée qui existent ; les bords
    jumeaux ont le même nombre de cases (et les mêmes colonnes pour un bord nord-sud) ; Route 12 sud
    (25..26, 0) ↔ Route 12 du J21 (25..26, 101) (grille relue sur origin/jalon-21) ;
  - Parmanie : rangée 53, praticables EXACTEMENT 24..32 et 34..35, bord to=route_19 (joint au J24) ; recoupé avec
    la grille route_19.txt du J24 (colonne + 15) si elle est lisible ;
  - Parmanie atteignable par CHAQUE chemin : est (Route 12 sud → 13 → 14 → 15, sans aucune case de Piste) et
    ouest (poste 16 → Route 16 ouest → 17 → 18, à vélo) ; sans Bicyclette, le garde des postes 16 et 18
    ferme la Piste ; le couloir haut du poste 16 mène à la voie haute et jamais à la Piste ;
  - Dresseurs : les 40 ids du dossier §9, à leur carte ; portée = RB × 1,5 ; au plus UN inévitable par
    route, et il l'est vraiment ; un chemin évite tous les autres ; sur la Piste, Dresseurs en retrait ;
  - pente seulement sur la Route 17, au moins 3 paliers ; aucune case pêchable au contact de la Piste ;
  - objets du dossier §11 (visibles et cachés), atteignables ; portes J23 en coming_soon ; maisons des
    cannes ; poste 15 (assistant, jumelles) ;
  - data/world/fishable.json : rectangles exacts des eaux qui bordent une berge ou un quai sur les six
    cartes livrées (Carmin, Azuria (variante J14), Routes 6, 11, 24, 25).

Usage : python3 -I tools/art/plan_check_j22.py                 (code 1 si un critère échoue)
        python3 -I tools/art/plan_check_j22.py --ecrire-fishable  (réécrit data/world/fishable.json)
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
FISHABLE = RACINE / "data" / "world" / "fishable.json"
Case = tuple[int, int]
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
INF = 10 ** 9
PISTE = set("ks")
DOORS = set("DXU")

# carte (id du jeu) → (fichier de grille, taille attendue, caractères permis)
CARTES = {
	"route_12_south": ("route_12_sud", (30, 70), set("T.=hqwfRmxD")),
	"route_13": ("route_13", (90, 27), set("T.=hwfRcx")),
	"route_14": ("route_14", (30, 81), set("T.=h")),
	"route_15": ("route_15", (90, 27), set("T.=hPD")),
	"route_15_gate": ("route_15_gate", (25, 10), set("K.XUNBJxV")),
	"route_15_gate_2f": ("route_15_gate", (25, 10), set("K.XUNBJxV")),
	"route_16_gate": ("route_16_gate", (14, 10), set("K.XNx")),
	"route_16_west": ("route_16_west", (40, 27), set("T.hRPDmkb")),
	"route_17": ("route_17", (30, 150), set("~RT.ksbhn")),
	"route_18": ("route_18", (75, 27), set("T.=hkbPDwf")),
	"route_18_gate": ("route_18_gate", (12, 10), set("K.XNBx")),
	"fuchsia_city": ("parmanie", (60, 54), set("T.=ySOFZCmcgwfRxD")),
}
# Cartes d'autres jalons ou intérieurs modèles : destinations terminales (non parcourues ici).
EXTERNES = {"route_12", "route_16", "route_12_rod_house", "fuchsia_center", "fuchsia_mart",
	"fuchsia_meeting_room", "fuchsia_grandpa_house", "fuchsia_good_rod_house",
	# Maison de Vol : ouverte par le J22 (Q-9 de la passe systèmes 2, 2026-10-21).
	"route_16_fly_house",
	# Route 19 du J24 (fusion du J24 dans `main`, 2026-10-23) : raccord vérifié plus bas.
	"route_19"}

# Dossier §9 : id → (carte, portée RB). Portée du projet = RB × 1,5 arrondie au-dessus.
DRESSEURS = {
	"route_12_fisher_5": ("route_12_south", 1), "route_12_youngster": ("route_12_south", 4),
	"route_12_rocker": ("route_12_south", 4),
	"route_13_bird_1": ("route_13", 2), "route_13_lass_1": ("route_13", 2), "route_13_lass_2": ("route_13", 2),
	"route_13_lass_3": ("route_13", 4), "route_13_beauty": ("route_13", 2), "route_13_biker": ("route_13", 2),
	"route_13_bird_2": ("route_13", 4),
	"route_14_bird_1": ("route_14", 3), "route_14_bird_2": ("route_14", 4), "route_14_bird_3": ("route_14", 2),
	"route_14_bird_4": ("route_14", 4), "route_14_biker_1": ("route_14", 4), "route_14_biker_2": ("route_14", 3),
	"route_14_biker_3": ("route_14", 4),
	"route_15_lass_1": ("route_15", 2), "route_15_lass_2": ("route_15", 3), "route_15_lass_3": ("route_15", 3),
	"route_15_beauty_1": ("route_15", 3), "route_15_beauty_2": ("route_15", 2), "route_15_bird": ("route_15", 3),
	"route_15_biker": ("route_15", 3),
	"route_16_biker_1": ("route_16_west", 3), "route_16_cueball_1": ("route_16_west", 2),
	"route_16_cueball_2": ("route_16_west", 2), "route_16_biker_2": ("route_16_west", 2),
	"route_16_cueball_3": ("route_16_west", 2),
	"route_17_cueball_1": ("route_17", 3), "route_17_cueball_2": ("route_17", 4), "route_17_biker_1": ("route_17", 4),
	"route_17_biker_2": ("route_17", 4), "route_17_biker_3": ("route_17", 3), "route_17_cueball_3": ("route_17", 2),
	"route_17_biker_4": ("route_17", 3), "route_17_cueball_4": ("route_17", 2),
	"route_18_bird_1": ("route_18", 3), "route_18_bird_2": ("route_18", 3), "route_18_bird_3": ("route_18", 4),
}
INEVITABLES = {"route_12_rocker", "route_13_lass_3", "route_14_bird_3", "route_15_bird", "route_16_biker_2",
	"route_17_biker_2", "route_18_bird_2"}
PORTEE = {1: 2, 2: 3, 3: 5, 4: 6}
# Traversées où l'on contrôle les Dresseurs : carte → [(départ, arrivée)] (identifiants de positions).
TRAVERSEES = {
	"route_12_south": [("from_route_12", "warp_ouest")],
	"route_13": [("from_route_12_sud", "warp_ouest")],
	"route_14": [("from_route_13", "warp_ouest")],
	"route_15": [("from_route_14", "porte_poste_est"), ("from_poste_ouest", "warp_ouest")],
	"route_16_west": [("from_poste_bas", "warp_sud")],
	"route_17": [("from_route_16", "warp_sud")],
	"route_18": [("from_route_17", "porte_poste_ouest")],
}
# Dossier §11 : carte → [(type, objet, drapeau)].
OBJETS = {
	"route_12_south": [("objet_visible", "nugget", "got_route_12_item_1"), ("cache", "hyper_potion", "got_route_12_hidden_1")],
	"route_13": [("cache", "rare_candy", "got_route_13_hidden_1"), ("cache", "hyper_potion", "got_route_13_hidden_2")],
	"route_15": [("objet_visible", "tm20", "got_route_15_item_1")],
	"route_16_west": [("cache", "hyper_potion", "got_route_16_hidden_1")],
	"route_17": [("cache", "rare_candy", "got_route_17_hidden_1"), ("cache", "full_restore", "got_route_17_hidden_2"),
		("cache", "nugget", "got_route_17_hidden_3"), ("cache", "full_restore", "got_route_17_hidden_4"),
		("cache", "nugget", "got_route_17_hidden_5")],
}
PORTES_J23 = {("fuchsia_city", "porte_arene"), ("fuchsia_city", "porte_safari"), ("fuchsia_city", "porte_gardien")}
# Cartes livrées (M-8) : (fichier, variante, eau).
LIVREES = {
	"vermilion_city": ("vermilion_city", None, "W"), "cerulean_city": ("azuria", "J14", "w"),
	"route_6": ("route_6", None, "W"), "route_11": ("route_11", None, "W"),
	"route_24": ("route_24", None, "w"), "route_25": ("route_25", None, "w"),
}
# Cases praticables d'où l'on ne pêche pas (passerelle et accès du S.S. Anne).
PAS_DE_PECHE = set("gE")


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def critere(self, vrai, texte: str) -> bool:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")
		return bool(vrai)


def _d(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _plage(cases: list[Case]) -> str:
	xs = sorted({x for x, _ in cases})
	ys = sorted({y for _, y in cases})
	fx = f"{xs[0]}..{xs[-1]}" if len(xs) > 1 else str(xs[0])
	fy = f"{ys[0]}..{ys[-1]}" if len(ys) > 1 else str(ys[0])
	return f"({fx}, {fy})"


class Carte:
	"""Une carte du J22 : grille, cases bloquées par les positions, sous-zone (2F du poste 15)."""

	def __init__(self, ident: str, plan: Plan) -> None:
		self.ident, self.plan = ident, plan
		self.bloquees: set[Case] = set()
		for p in plan.positions.values():
			if p.bloque:
				self.bloquees.update(p.cells)
		self.warps = {c: p for p in plan.of_kind("warp") for c in p.cells}

	def libre(self, c: Case) -> bool:
		x, y = c
		if not (0 <= x < self.plan.width and 0 <= y < self.plan.height):
			return False
		return c not in self.bloquees and self.plan.at(x, y) in self.plan.praticables

	def spawn(self, nom: str) -> list[Case]:
		return self.plan.positions[nom].cells


def charger() -> dict[str, Carte]:
	cartes: dict[str, Carte] = {}
	for ident, (fichier, _, _) in CARTES.items():
		cartes[ident] = Carte(ident, lire(PLANS / f"{fichier}.txt"))
	return cartes


def parcourir(cartes: dict[str, Carte], departs: list[tuple[str, Case]], *, interdites=lambda m, c, d: False,
		arret: set[str] = frozenset(), sans: set[str] = frozenset()) -> dict[tuple[str, Case], tuple[int, tuple | None]]:
	"""Recherche en largeur sur toutes les cartes : un warp `to=` mène aux cases de son point d'arrivée.
	`interdites(carte, case, direction)` refuse un pas ; on ne ressort pas d'une carte de `arret` ; on
	n'entre jamais dans une carte de `sans`."""
	vus: dict[tuple[str, Case], tuple[int, tuple | None]] = {n: (0, None) for n in departs}
	file = deque(departs)
	while file:
		n = file.popleft()
		m, c = n
		carte = cartes[m]
		dist = vus[n][0]
		suivants: list[tuple[str, Case]] = []
		w = carte.warps.get(c)
		if w is not None and m not in arret:
			cible = w.attrs.get("to")
			if cible in cartes and cible not in sans and "coming_soon" not in w.attrs:
				suivants += [(cible, s) for s in cartes[cible].spawn(w.attrs["spawn"])]
		if m not in arret:
			for d in DIRS:
				v = _d(c, d)
				if carte.libre(v) and not interdites(m, v, d):
					# une porte (D, X, U) se prend, elle ne se traverse pas : on s'y arrête (warp au-dessus)
					suivants.append((m, v))
		for s in suivants:
			if s not in vus:
				vus[s] = (dist + 1, n)
				file.append(s)
	return vus


def _chemin_cartes(vus, fin) -> list[str]:
	sequence, n = [], fin
	while n is not None:
		if not sequence or sequence[-1] != n[0]:
			sequence.append(n[0])
		n = vus[n][1]
	return list(reversed(sequence))


def vue(carte: Carte, p) -> list[Case]:
	d = FACINGS[p.attrs["facing"]]
	cases = []
	for k in range(1, int(p.attrs["sight"]) + 1):
		c = _d(p.cells[0], d, k)
		if not carte.libre(c):
			break
		cases.append(c)
	return cases


def local(carte: Carte, departs: list[Case], arrivees: set[Case], bloquees: set[Case]) -> int:
	"""Plus court trajet dans une seule carte, sans passer par une porte (sauf l'arrivée)."""
	portes = {c for c in carte.warps if carte.plan.at(*c) in DOORS} - arrivees
	dist = {c: 0 for c in departs}
	file = deque(departs)
	while file:
		c = file.popleft()
		if c in arrivees:
			return dist[c]
		for d in DIRS:
			v = _d(c, d)
			if v in dist or v in bloquees or v in portes or not carte.libre(v):
				continue
			dist[v] = dist[c] + 1
			file.append(v)
	return INF


# ------------------------------------------------------------------------------------ critères --

def verifier_grilles(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nGrilles : dimensions, légende, bords")
	vues: set[str] = set()
	for ident, (fichier, taille, legende) in CARTES.items():
		if fichier in vues:
			continue
		vues.add(fichier)
		plan = cartes[ident].plan
		inconnus = {c for row in plan.rows for c in row} - legende
		r.critere((plan.width, plan.height) == taille and not inconnus,
			f"{fichier}.txt : {plan.width} × {plan.height} (attendu {taille[0]} × {taille[1]})"
			+ (f", caractères inconnus {sorted(inconnus)}" if inconnus else ", légende connue"))
		carte = cartes[ident]
		bord = [(x, y) for y in range(plan.height) for x in range(plan.width)
			if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and carte.libre((x, y))]
		hors = [c for c in bord if c not in carte.warps]
		r.critere(not hors, f"{fichier}.txt : bord fermé sauf les raccords ({len(bord)} cases de bord, toutes des warps)"
			if not hors else f"{fichier}.txt : cases de bord praticables sans warp {hors[:6]}")
		mauvais = []
		for p in plan.positions.values():
			for c in p.cells:
				ch = plan.at(*c)
				if p.kind in ("spawn", "cache") and ch not in plan.praticables:
					mauvais.append(f"{p.ident} sur « {ch} »")
				if p.kind == "cache" and ch == "h":
					mauvais.append(f"{p.ident} dans les herbes")
				if p.kind == "warp" and ch not in plan.praticables:
					mauvais.append(f"{p.ident} sur « {ch} »")
		r.critere(not mauvais, f"{fichier}.txt : positions posées sur des cases cohérentes"
			+ (f" — {mauvais[:4]}" if mauvais else ""))


def verifier_raccords(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nRaccords")
	for ident, carte in cartes.items():
		for p in carte.plan.of_kind("warp"):
			cible = p.attrs.get("to")
			if cible is None:
				r.critere("coming_soon" in p.attrs, f"{ident}.{p.ident} : coming_soon={p.attrs.get('coming_soon')}")
				continue
			if cible in EXTERNES:
				continue
			if cible not in cartes:
				r.critere(False, f"{ident}.{p.ident} : carte {cible} inconnue")
				continue
			sp = p.attrs.get("spawn")
			if sp not in cartes[cible].plan.positions:
				r.critere(False, f"{ident}.{p.ident} : point d'arrivée {cible}.{sp} absent")
				continue
			arrivee = cartes[cible].spawn(sp)
			plan = carte.plan
			if plan.at(*p.cells[0]) in DOORS:
				continue
			# bord jumeau : même nombre de cases ; bord nord-sud : mêmes colonnes
			nord_sud = all(y in (0, plan.height - 1) for _, y in p.cells)
			memes = len(arrivee) == len(p.cells) and (not nord_sud or sorted(x for x, _ in arrivee) == sorted(x for x, _ in p.cells))
			r.critere(memes, f"{ident} {_plage(p.cells)} ↔ {cible} {_plage(arrivee)}"
				+ (" (mêmes colonnes)" if nord_sud else f" ({len(p.cells)} cases)"))
	# Route 12 du J21
	r12 = _voisine("route_12.txt", ["origin/jalon-21", "jalon-21"])
	nord = cartes["route_12_south"].plan.positions["warp_nord"].cells
	if r12 is None:
		r.critere(nord == [(25, 0), (26, 0)], f"Route 12 sud nord {_plage(nord)} = (25..26, 0) (grille du J21 illisible : valeur du plan)")
	else:
		sud = r12.positions["warp_sud"].cells
		r.critere(sorted(x for x, _ in sud) == sorted(x for x, _ in nord) == [25, 26]
			and all(y == r12.height - 1 for _, y in sud) and all(y == 0 for _, y in nord),
			f"Route 12 (J21) warp_sud {_plage(sud)} ↔ Route 12 sud warp_nord {_plage(nord)} : 2 cases, mêmes colonnes")
	r16 = _voisine("route_16.txt", ["origin/jalon-21", "jalon-21"])
	if r16 is not None:
		porte = r16.positions["poste_route_16"].cells
		r.critere(porte == [(15, 20), (16, 20)], f"Route 16 (J21) : porte du poste {_plage(porte)} (2 cases) ↔ couloir bas "
			"(10..11, 8) du poste 16 ; T19 retire son coming_soon et crée la porte haute (en-tête de route_16_gate.txt)")
	# Parmanie, bord sud
	parm = cartes["fuchsia_city"]
	bas = parm.plan.height - 1
	prat = [x for x in range(parm.plan.width) if parm.plan.at(x, bas) in parm.plan.praticables]
	attendu = list(range(24, 33)) + [34, 35]
	w = parm.plan.positions["warp_sud"]
	# Raccord joint à la fusion du J24 dans `main` (2026-10-23) : bord vers la Route 19, arrivées
	# from_fuchsia_city de même rang.
	r.critere(prat == attendu and sorted(x for x, _ in w.cells) == attendu
		and "coming_soon" not in w.attrs and w.attrs.get("to") == "route_19"
		and w.attrs.get("spawn") == "from_fuchsia_city",
		f"Parmanie, rangée {bas} : praticables {prat[0]}..{prat[8]} et {prat[9]}..{prat[10]} ; "
		"warp_sud to=route_19 spawn=from_fuchsia_city")
	local19 = RACINE / "tools/plans/route_19.txt"
	r19 = lire(local19) if local19.exists() else _voisine("route_19.txt", ["origin/jalon-24", "jalon-24"])
	if r19 is not None:
		haut = [x + 15 for x in range(r19.width) if r19.at(x, 0) in r19.praticables]
		r.critere(haut == attendu, f"Route 19 (J24), rangée 0 : colonnes + 15 = {haut[0]}..{haut[8]}, {haut[9]}..{haut[10]} (identiques)")


def _voisine(fichier: str, branches: list[str]) -> Plan | None:
	for b in branches:
		try:
			txt = subprocess.run(["git", "-C", str(RACINE), "show", f"{b}:tools/plans/{fichier}"],
				capture_output=True, text=True, check=True).stdout
		except (subprocess.CalledProcessError, FileNotFoundError):
			continue
		with tempfile.TemporaryDirectory() as tmp:
			f = Path(tmp) / fichier
			f.write_text(txt, encoding="utf-8")
			return lire(f)
	return None


def verifier_chemins(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nDeux chemins vers Parmanie")
	piste_interdite = lambda m, c, d: cartes[m].plan.at(*c) in PISTE  # noqa: E731
	est = [("route_12_south", c) for c in cartes["route_12_south"].spawn("from_route_12")]
	vus = parcourir(cartes, est, interdites=piste_interdite, arret={"fuchsia_city"})
	arrivees = [n for n in vus if n[0] == "fuchsia_city"]
	if r.critere(arrivees, "EST : Route 12 sud → Parmanie à pied, sans aucune case de Piste"):
		fin = min(arrivees, key=lambda n: vus[n][0])
		print(f"         {' → '.join(_chemin_cartes(vus, fin))} ({vus[fin][0]} pas)")
	ouest = [("route_16_gate", c) for c in cartes["route_16_gate"].spawn("entrance_bas_est")]
	vus = parcourir(cartes, ouest, arret={"fuchsia_city"}, sans={"route_15", "route_14", "route_13", "route_12_south"})
	arrivees = [n for n in vus if n[0] == "fuchsia_city"]
	if r.critere(arrivees, "OUEST : poste 16 (porte de la Route 16 est) → Parmanie à vélo, sans les Routes 12 à 15"):
		fin = min(arrivees, key=lambda n: vus[n][0])
		seq = _chemin_cartes(vus, fin)
		print(f"         {' → '.join(seq)} ({vus[fin][0]} pas)")
		r.critere(all(m in seq for m in ("route_16_west", "route_17", "route_18")), "OUEST passe par la Route 16 ouest, la 17 et la 18")

	def sans_velo(m: str, c: Case, d: Case) -> bool:
		for p in cartes[m].plan.of_kind("repere"):
			if p.attrs.get("role") == "regle_piste" and c in p.cells and d == FACINGS[p.attrs["sens"]]:
				return True
		return False
	for m, sp in (("route_16_gate", "entrance_bas_est"), ("fuchsia_city", "from_route_18")):
		vus = parcourir(cartes, [(m, c) for c in cartes[m].spawn(sp)], interdites=sans_velo)
		piste = [n for n in vus if cartes[n[0]].plan.at(*n[1]) in PISTE]
		r.critere(not piste, f"sans Bicyclette, depuis {m}.{sp} : aucune case de Piste atteinte (garde du poste)")
	haut = [("route_16_gate", c) for c in cartes["route_16_gate"].spawn("entrance_haut_est")]
	vus = parcourir(cartes, haut)
	piste = [n for n in vus if cartes[n[0]].plan.at(*n[1]) in PISTE]
	cache = cartes["route_16_west"].plan.positions["route_16_hidden_1"].cells[0]
	porte_vol = cartes["route_16_west"].plan.positions["porte_maison_vol"].cells[0]
	r.critere(not piste and ("route_16_west", cache) in vus and ("route_16_west", porte_vol) in vus,
		"couloir haut du poste 16 → voie haute ouest (objet caché, porte de la maison de Vol), jamais la Piste")
	# Route 18 : depuis Parmanie, à pied, on atteint le poste (le garde refuse ensuite).
	vus = parcourir(cartes, [("fuchsia_city", c) for c in cartes["fuchsia_city"].spawn("from_route_18")], interdites=sans_velo)
	porte = cartes["route_18"].plan.positions["porte_poste_est"].cells
	r.critere(any(("route_18", c) in vus for c in porte), "depuis Parmanie, à pied : Route 18 est jusqu'au poste 18")


def verifier_dresseurs(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nDresseurs (dossier §9)")
	trouves: dict[str, tuple[str, object]] = {}
	for m, carte in cartes.items():
		if m == "route_15_gate_2f":
			continue
		for p in carte.plan.of_kind("dresseur"):
			trouves[p.attrs.get("trainer", p.ident)] = (m, p)
	r.critere(set(trouves) == set(DRESSEURS) and len(trouves) == 40,
		f"{len(trouves)} Dresseurs, ids et cartes du dossier"
		+ (f" — manquants {sorted(set(DRESSEURS) - set(trouves))}, en trop {sorted(set(trouves) - set(DRESSEURS))}"
			if set(trouves) != set(DRESSEURS) else ""))
	mauvais = []
	for ident, (m, p) in trouves.items():
		if ident not in DRESSEURS:
			continue
		carte_att, rb = DRESSEURS[ident]
		if m != carte_att or int(p.attrs["sight"]) != PORTEE[rb] or int(p.attrs.get("rbsight", -1)) != rb:
			mauvais.append(f"{ident} ({m}, sight {p.attrs['sight']}, attendu {carte_att}, {PORTEE[rb]})")
		if not vue(cartes[m], p):
			mauvais.append(f"{ident} ne voit aucune case")
		if (p.attrs.get("inevitable") == "oui") != (ident in INEVITABLES):
			mauvais.append(f"{ident} : inevitable={p.attrs.get('inevitable')}")
	r.critere(not mauvais, "portées = RB × 1,5, cartes, inévitables (I) du dossier" + (f" — {mauvais}" if mauvais else ""))
	for m, segments in TRAVERSEES.items():
		carte = cartes[m]
		dresseurs = [p for p in carte.plan.of_kind("dresseur")]
		inev = [p for p in dresseurs if p.attrs.get("inevitable") == "oui"]
		vues_autres = {c for p in dresseurs if p not in inev for c in vue(carte, p)}
		vues_toutes = vues_autres | {c for p in inev for c in vue(carte, p)}
		evitable, bloque_i, total = True, not inev, 0
		for dep, arr in segments:
			d0 = carte.spawn(dep)
			a0 = set(carte.plan.positions[arr].cells)
			sans_autres = local(carte, d0, a0, vues_autres)
			sans_tous = local(carte, d0, a0, vues_toutes)
			total += local(carte, d0, a0, set())
			evitable &= sans_autres < INF
			if inev and sans_tous >= INF:
				bloque_i = True
		noms = ", ".join(p.attrs["trainer"] for p in inev) or "aucun"
		r.critere(len(inev) <= 1 and evitable and bloque_i,
			f"{m} : {len(dresseurs)} Dresseurs ; inévitable : {noms} (aucun chemin hors de sa vue) ; un chemin évite "
			f"tous les autres ; traversée {total} pas")
	# Piste : en retrait
	retrait = []
	for m in ("route_16_west", "route_17", "route_18"):
		carte = cartes[m]
		for p in carte.plan.of_kind("dresseur"):
			cases = vue(carte, p)
			if carte.plan.at(*p.cells[0]) in PISTE or not cases or carte.plan.at(*cases[0]) not in PISTE:
				retrait.append(p.ident)
	r.critere(not retrait, "Dresseurs de la Piste en retrait : en alcôve hors des voies, tournés vers une voie"
		+ (f" — {retrait}" if retrait else ""))


def verifier_piste(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nPiste, pente, paliers, pêche")
	pentes = {m for m, c in cartes.items() if any("s" in row for row in c.plan.rows)}
	r.critere(pentes == {"route_17"}, f"cases de pente seulement sur la Route 17 ({sorted(pentes)})")
	r17 = cartes["route_17"].plan
	rangs = [y for y, row in enumerate(r17.rows) if "s" in row]
	paliers, courant = [], []
	for y in range(rangs[0], rangs[-1] + 1):
		if "s" in r17.rows[y]:
			if courant:
				paliers.append(courant)
			courant = []
		else:
			courant.append(y)
	r.critere(len(paliers) >= 3 and all(len(p) >= 2 for p in paliers),
		f"{len(paliers)} paliers sur la Route 17 : " + ", ".join(f"rangées {p[0]}..{p[-1]}" for p in paliers))
	fins = {}
	for y, row in enumerate(r17.rows):
		for x, ch in enumerate(row):
			if ch == "s" and (y + 1 >= r17.height or r17.at(x, y + 1) != "s"):
				dessous = r17.at(x, y + 1) if y + 1 < r17.height else "bord"
				fins[dessous] = fins.get(dessous, 0) + 1
	r.critere(set(fins) <= set("kTb"), f"chaque descente finit sur un palier (k) ou contre un obstacle : {fins}")
	contact = []
	for m, carte in cartes.items():
		plan = carte.plan
		for x, y in plan.cells_of("f"):
			for d in DIRS:
				v = _d((x, y), d)
				if 0 <= v[0] < plan.width and 0 <= v[1] < plan.height and plan.at(*v) in PISTE:
					contact.append((m, (x, y)))
	r.critere(not contact, "aucune case pêchable au contact d'une case de Piste" + (f" — {contact[:4]}" if contact else ""))
	inutiles = []
	for m in ("route_12_south", "route_13", "route_18", "fuchsia_city"):
		plan = cartes[m].plan
		f = plan.cells_of("f")
		utiles = [c for c in f if any(0 <= _d(c, d)[0] < plan.width and 0 <= _d(c, d)[1] < plan.height
			and plan.at(*_d(c, d)) in plan.praticables and plan.at(*_d(c, d)) not in PISTE for d in DIRS)]
		if not f or len(utiles) != len(f):
			inutiles.append(m)
		print(f"         {m} : {len(f)} cases pêchables")
	r.critere(not inutiles, "cases pêchables sur la Route 12 sud, la 13, la 18 (est) et Parmanie, toutes au bord "
		"d'une case praticable à pied" + (f" — {inutiles}" if inutiles else ""))


def verifier_contenu(r: Rapport, cartes: dict[str, Carte]) -> None:
	print("\nObjets, portes réservées, maisons, postes")
	for m, attendus in OBJETS.items():
		carte = cartes[m]
		trouves = [(p.kind, p.attrs.get("item"), p.attrs.get("drapeau")) for p in carte.plan.positions.values()
			if p.kind in ("objet_visible", "cache")]
		vus = parcourir(cartes, [(m, c) for p in carte.plan.of_kind("spawn") for c in p.cells])
		atteints = True
		for p in carte.plan.positions.values():
			if p.kind == "cache":
				atteints &= (m, p.cells[0]) in vus
			elif p.kind == "objet_visible":
				atteints &= any((m, _d(p.cells[0], d)) in vus for d in DIRS)
		r.critere(sorted(trouves) == sorted(attendus) and atteints,
			f"{m} : {len(trouves)} objet(s) du §11, atteignables ({', '.join(f'{i}' for _, i, _ in trouves)})")
	reservees = {(m, p.ident) for m, c in cartes.items() for p in c.plan.of_kind("warp")
		if "coming_soon" in p.attrs and p.attrs["coming_soon"] != "route_19"}
	r.critere(reservees == PORTES_J23, f"portes réservées au J23 (coming_soon) : {sorted(i for _, i in reservees)}")
	cannes = [(m, p.attrs.get("to")) for m, c in cartes.items() for p in c.plan.of_kind("warp")
		if p.attrs.get("to") in ("route_12_rod_house", "fuchsia_good_rod_house")]
	r.critere(len(cannes) == 2, f"maisons des cannes : {cannes}")
	g15 = cartes["route_15_gate"].plan
	assistant = g15.positions.get("assistant")
	jumelles = [p for p in g15.of_kind("panneau") if p.attrs.get("role") == "T-41"]
	r.critere(assistant is not None and assistant.cells[0][0] >= 13 and len(jumelles) == 2
		and all(p.cells[0][0] >= 13 for p in jumelles), "poste 15, 2F : assistant (sans cadeau) et deux jumelles")
	vus = parcourir(cartes, [("route_15", c) for c in cartes["route_15"].spawn("from_route_14")])
	r.critere(all(("route_15_gate_2f", _d(p.cells[0], (0, 1))) in vus for p in jumelles)
		and ("route_15_gate_2f", _d(assistant.cells[0], (0, 1))) in vus, "le 2F se rejoint depuis la Route 15 (escalier)")
	lecture = []
	for m, carte in cartes.items():
		for p in carte.plan.of_kind("panneau") + carte.plan.of_kind("pnj") + carte.plan.of_kind("pokemon"):
			if p.kind == "pokemon":
				continue
			if not any(carte.libre(_d(c, d)) for c in p.cells for d in DIRS):
				lecture.append(f"{m}.{p.ident}")
	r.critere(not lecture, "panneaux et PNJ abordables depuis une case libre" + (f" — {lecture}" if lecture else ""))


# --------------------------------------------------------------------------------- pêchables --

def eaux_peche(fichier: str, variante: str | None, eau: str) -> list[Case]:
	plan = lire(PLANS / f"{fichier}.txt", variante)
	sol = plan.praticables - PAS_DE_PECHE
	cases = []
	for y, row in enumerate(plan.rows):
		for x, ch in enumerate(row):
			if ch != eau:
				continue
			if any(0 <= x + dx < plan.width and 0 <= y + dy < plan.height and plan.at(x + dx, y + dy) in sol
					for dx, dy in DIRS):
				cases.append((x, y))
	return cases


def rectangles(cases: list[Case]) -> list[list[int]]:
	"""Rectangles [x, y, largeur, hauteur] : tronçons de rangée, fusionnés verticalement s'ils sont égaux."""
	ens = set(cases)
	troncons: dict[int, list[tuple[int, int]]] = {}
	for y in sorted({y for _, y in ens}):
		xs = sorted(x for x, yy in ens if yy == y)
		debut = prec = xs[0]
		for x in xs[1:] + [None]:
			if x is None or x != prec + 1:
				troncons.setdefault(y, []).append((debut, prec))
				if x is not None:
					debut = x
			if x is not None:
				prec = x
	ouverts: dict[tuple[int, int], list[int]] = {}
	fini: list[list[int]] = []
	for y in sorted(troncons):
		nouveaux: dict[tuple[int, int], list[int]] = {}
		for t in troncons[y]:
			if t in ouverts and ouverts[t][1] + ouverts[t][3] == y:
				ouverts[t][3] += 1
				nouveaux[t] = ouverts.pop(t)
			else:
				nouveaux[t] = [t[0], y, t[1] - t[0] + 1, 1]
		fini += list(ouverts.values())
		ouverts = nouveaux
	fini += list(ouverts.values())
	return sorted(fini, key=lambda r: (r[1], r[0]))


def fishable_attendu() -> dict:
	cartes = {m: rectangles(eaux_peche(*v)) for m, v in LIVREES.items()}
	return {
		"_doc": "Cases d'eau pêchables des cartes livrées avant le J22 (M-8 ; jalon-22.md §0.4 n° 2). Par carte, "
			"des rectangles [x, y, largeur, hauteur] en cases de grille : l'eau qui borde une berge, un quai ou un "
			"pont. Les cartes du J22 marquent leurs cases dans leur grille (« f »). Généré et contrôlé par "
			"tools/art/plan_check_j22.py (--ecrire-fishable).",
		"maps": cartes,
	}


def verifier_fishable(r: Rapport) -> None:
	print("\ndata/world/fishable.json (cartes livrées)")
	attendu = fishable_attendu()
	if not FISHABLE.exists():
		r.critere(False, "data/world/fishable.json absent (--ecrire-fishable)")
		return
	lu = json.loads(FISHABLE.read_text(encoding="utf-8"))
	for m, rects in attendu["maps"].items():
		n = sum(w * h for _, _, w, h in rects)
		r.critere(lu.get("maps", {}).get(m) == rects, f"{m} : {len(rects)} rectangle(s), {n} case(s)")
		if n <= 3:
			print(f"  [NOTE] {m} : presque aucune eau ne touche une case praticable (rive rocheuse) — à voir avec Kevin")
	r.critere(set(lu.get("maps", {})) == set(LIVREES), f"six cartes : {sorted(lu.get('maps', {}))}")


def main() -> int:
	if "--ecrire-fishable" in sys.argv:
		donnees = fishable_attendu()
		lignes = ["{", f"\t\"_doc\": {json.dumps(donnees['_doc'], ensure_ascii=False)},", "\t\"maps\": {"]
		cartes = list(donnees["maps"].items())
		for i, (m, rects) in enumerate(cartes):
			fin = "," if i < len(cartes) - 1 else ""
			if not rects:
				lignes.append(f"\t\t\"{m}\": []{fin}")
				continue
			lignes.append(f"\t\t\"{m}\": [")
			lignes += [f"\t\t\t{json.dumps(rc)}{',' if j < len(rects) - 1 else ''}" for j, rc in enumerate(rects)]
			lignes.append(f"\t\t]{fin}")
		lignes += ["\t}", "}"]
		FISHABLE.write_text("\n".join(lignes) + "\n", encoding="utf-8")
		print(f"écrit : {FISHABLE.relative_to(RACINE)}")
	r = Rapport()
	cartes = charger()
	verifier_grilles(r, cartes)
	verifier_raccords(r, cartes)
	verifier_chemins(r, cartes)
	verifier_dresseurs(r, cartes)
	verifier_piste(r, cartes)
	verifier_contenu(r, cartes)
	verifier_fishable(r)
	print("\nTOUT EST CONFORME" if r.ok else "\nNON CONFORME")
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
