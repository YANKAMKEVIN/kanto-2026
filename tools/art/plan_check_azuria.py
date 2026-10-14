#!/usr/bin/env python3
"""Vérifie les grilles du jalon 13 (Route 4, Azuria, Route 24, Arène, magasin de vélos, maison).

Grilles : `tools/plans/route_4.txt`, `azuria.txt`, `route_24.txt`, `azuria_arene.txt`,
`azuria_velos.txt`, `azuria_maison.txt` (dossier 16). Lecture par `plan_grille.lire` ;
déplacements de `plan_check.Monde` (4 directions, un pas par case, rebords sautés vers le sud
seulement), avec des **portes terminales** (`D` : on y entre, on ne la traverse pas). Les positions
`bloque` (Dresseurs, PNJ, objets, panneaux, indices) bloquent leurs cases.

Critères, par carte (repris par les tests des cartes au 13A–13C) :
  Route 4 — 64 × 24 ; **recouvrement exact du sas** (`route_4_sas.txt`) : mêmes cases, mêmes
    positions, toute case praticable du sas reste praticable et mène au raccord est ; raccord est
    = rangées d'Azuria (ouest) ; le **rebord** (unique descente) ne se monte pas, la grotte n'est
    plus atteignable depuis la plaine ; herbes (H2 obligatoire, H1 et H3 évitables) ; Clara
    évitable ; Poké Ball visible.
  Azuria — 56 × 46 ; raccords ouest (Route 4) et nord (Route 24) ; eau jamais praticable, canal
    en L, aucun canal ni pont en diagonale, quais et ponts ≥ 2 cases, 3 ponts ; **Centre =
    premier bâtiment de l'avenue d'arrivée**, avant toute bifurcation ; Arène de l'autre côté du
    canal ; sortie nord par le pont central, visible depuis la place ; sud fermé, est fermé par l'ARBRE À COUPER
    (« k », J18 : raccord Route 9 derrière, atteignable une fois coupé) sans
    promesse ; Grotte Azurée hors d'atteinte ; maison cambriolée (porte fermée, trou impraticable,
    policier) ; 6 habitants ; emprises des bâtiments ; toutes les cases praticables connexes.
  Route 24 — 56 × 62 ; raccord sud = sortie nord d'Azuria ; **rival inévitable** (vue sur toute la
    largeur du goulet, à ≥ 3 cases) ; **Ondine inaccessible avant le rival** ; pont de 2 cases ;
    **P1..P5 et recruteur inévitables** (quinconce), aucune approche ne coince ; l'espace nord
    n'est atteint qu'après le recruteur ; herbes évitables ; Potion visible, Antidote caché.
  Arène — Ondine atteignable, Nageur et Jeune Dresseuse **évitables** (séparément et ensemble),
    bassin jamais praticable, guide à l'entrée.
  Vélos, maison — sortie et PNJ atteignables (enveloppe 15 × 10 de la maison d'Argenta).
Imprime les longueurs de chemin principal (pas) et une estimation de durée (méthode du J12).

Usage : python3 tools/art/plan_check.py tools/plans/route_4.txt   (ou sans argument : tout)
        python3 tools/art/plan_check_azuria.py   (les six cartes ; code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from dataclasses import replace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute, ligne_de_vue,  # noqa: E402
	nommer_zones, premiere_detection, zones_herbes)
from plan_grille import HERBES, REBORD, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]

TAILLES = {"route_4": (64, 24), "azuria": (56, 41), "route_24": (56, 62),
	"azuria_arene": (17, 13), "azuria_velos": (15, 10), "azuria_maison": (15, 10)}
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases (≥ 2 libres entre eux)
SOL = set(".=")                    # sol où poser un personnage ou un objet
EAU = "w"
# Emprises des bâtiments d'Azuria (caractère → largeur, hauteur, colonnes de la porte dans la
# rangée du bas) : source unique reprise par les fiches d'assets.
EMPRISES = {
	"C": (8, 7, (3, 4)),     # bldg_centre_01 réutilisé
	"O": (8, 7, (3, 4)),     # bldg_boutique_01 réutilisé
	"Z": (12, 7, (5, 6)),    # bldg_arene_azuria_01 (neuf)
	"V": (8, 7, (3, 4)),     # bldg_velos_azuria_01 (neuf)
	"m": (7, 6, (3,)),       # bldg_maison_azuria_01 (maison ouverte)
	"M": (7, 6, (3,)),       # bldg_maison_cambriolee_01 (neuf ; porte fermée « f »)
}
# Durée (méthode du J12) : pas mesuré sur S21 (0,72 s/case), combats par défaut.
S_PAR_PAS = 0.72
S_SAUVAGE = 50
TAUX = 25 / 256
S_COMBATS = {"rival": 150, "ondine_scene": 40, "P1": 120, "P2": 110, "P3": 80, "P4": 80,
	"P5": 60, "recruteur": 160}
CHEMIN_ROUTE_4 = (60, 90)          # pas, arrivée du sas → raccord est (défaut)
CHEMIN_ROUTE_24 = (70, 110)       # pas, raccord sud → raccord est (défaut)


class Carte(Monde):
	"""`plan_check.Monde` avec portes terminales (`D`) : on y entre, on ne la traverse pas."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset(),
			portes: set[Case] | None = None) -> None:
		super().__init__(plan, bloquees)
		self.portes = set(plan.cells_of("D")) if portes is None else set(portes)

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Carte":
		return Carte(self.plan, self.bloquees | set(cases), self.portes)

	def avec(self, retire=(), ajoute=()) -> "Carte":
		return Carte(self.plan, (self.bloquees - set(retire)) | set(ajoute), self.portes)


class Rapport:
	def __init__(self, titre: str) -> None:
		self.ok = True
		print(f"\n{titre}")

	def critere(self, vrai: bool, texte: str) -> None:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	def info(self, texte: str) -> None:
		print(f"  {texte}")


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _dans(plan: Plan, c: Case) -> bool:
	return 0 <= c[0] < plan.width and 0 <= c[1] < plan.height


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
	return sorted(groupes, key=lambda g: (min(y for _, y in g), min(x for x, _ in g)))


def _boite(cases) -> tuple[int, int, int, int]:
	xs = [x for x, _ in cases]
	ys = [y for _, y in cases]
	return min(xs), min(ys), max(xs), max(ys)


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _libres_du_bord(carte: Carte) -> list[Case]:
	p = carte.plan
	return sorted((x, y) for y in range(p.height) for x in range(p.width)
		if (x in (0, p.width - 1) or y in (0, p.height - 1)) and carte.libre((x, y)))


def _acces(carte: Carte, p) -> list[Case]:
	"""Cases d'où l'on prend / examine / parle à p : les voisines libres de ses cases."""
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if carte.libre(_decale(c, d)) and _decale(c, d) not in carte.portes]


def _joignable(carte: Carte, dist: dict[Case, int], p) -> int:
	return min((dist.get(a, INF) for a in _acces(carte, p)), default=INF)


def _en_diagonale(plan: Plan, car: str) -> list[Case]:
	"""Fenêtres 2 × 2 en damier pour `car` (deux cases en diagonale, les deux autres non) : un
	canal ou un pont qui ne serait pas à angles droits."""
	mauvais = []
	for y in range(plan.height - 1):
		for x in range(plan.width - 1):
			a, b = plan.at(x, y) == car, plan.at(x + 1, y) == car
			c, d = plan.at(x, y + 1) == car, plan.at(x + 1, y + 1) == car
			if (a and d and not b and not c) or (b and c and not a and not d):
				mauvais.append((x, y))
	return mauvais


def _approche_ferme(plan: Plan, base: Carte, dresseurs: dict, vues: dict, cibles: list[list[Case]],
		atteignables: dict[Case, int]) -> list[str]:
	"""Un Dresseur qui s'approche (il s'arrête sur la case voisine du joueur vu) ne ferme jamais un
	passage (jalon 9 §6.9) : toutes les `cibles` restent atteignables depuis la case de détection."""
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in atteignables:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = base.avec(retire=[p.cells[0]], ajoute=[arret])
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	return fermes


def _cases_praticables(plan: Plan) -> int:
	return sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)


def _nom(chemin: Path) -> str:
	return str(chemin.relative_to(RACINE)) if chemin.is_relative_to(RACINE) else str(chemin)


# ===================================================================================== Route 4

def verifier_route_4(chemin: Path) -> bool:
	plan = lire(chemin)
	sas = lire(chemin.with_name("route_4_sas.txt"))
	azuria = lire(chemin.with_name("azuria.txt"))
	r = Rapport(f"Route 4 — {_nom(chemin)} : {plan.width} × {plan.height}")
	carte = Carte(plan)
	pos = plan.positions
	r.critere((plan.width, plan.height) == TAILLES["route_4"],
		f"taille {plan.width} × {plan.height} (attendu {TAILLES['route_4'][0]} × "
		f"{TAILLES['route_4'][1]})")

	# 1. Recouvrement exact du sas (x 0..23, y 0..13).
	diffs = [((x, y), sas.at(x, y), plan.at(x, y)) for y in range(sas.height)
		for x in range(sas.width) if sas.at(x, y) != plan.at(x, y)]
	attendues = {(23, 6): ("e", "="), (23, 7): ("e", "=")}
	r.critere({c: (a, b) for c, a, b in diffs} == attendues,
		f"sas recopié case pour case (24 × 14) : {len(diffs)} différence(s), seulement le raccord "
		f"« AZURIA — À venir » (23, 6..7) devenu chemin ; {sas.width * sas.height - len(diffs)} "
		"cases identiques")
	memes = all(i in pos and pos[i].kind == p.kind and pos[i].cells == p.cells
		and pos[i].bloque == p.bloque and pos[i].attrs == p.attrs
		for i, p in sas.positions.items() if i not in ("raccord_est", "repere_plaine"))
	r.critere(memes and pos["sortie_grotte"].cells == [(2, 6)]
		and pos["from_mt_moon"].cells == [(3, 6)] and pos["panneau_route_4"].cells == [(6, 5)],
		"positions du sas identiques : sortie de grotte (2, 6), arrivée « from_mt_moon » (3, 6), "
		"panneau (6, 5)")
	sas_cases = [(x, y) for y in range(sas.height) for x in range(sas.width)
		if sas.at(x, y) in sas.praticables]
	base = Monde(plan)               # non terminal : on repart de n'importe quelle case
	est_sas = base.distances([c for c in sas_cases if c != (2, 6)])
	praticables = [c for c in sas_cases if plan.at(*c) in plan.praticables]
	r.critere(len(praticables) == len(sas_cases),
		f"toute case praticable du sas ({len(sas_cases)}) reste praticable dans la Route 4 : une "
		"partie sauvegardée retombe sur une case praticable")
	raccord_est = [(plan.width - 1, y) for y in range(plan.height) if carte.libre((plan.width - 1, y))]
	sans_issue = [c for c in sas_cases if c != (2, 6) and not any(
		e in base.distances([c]) for e in raccord_est)]
	r.critere(not sans_issue, "depuis chaque case praticable du sas (sauvegarde), le raccord est "
		f"reste atteignable {sans_issue[:3] if sans_issue else ''}")

	# 2. Raccord est = rangées d'Azuria (ouest) ; carte fermée ailleurs.
	ouest_azuria = sorted(c for p in azuria.of_kind("warp") for c in p.cells if c[0] == 0)
	rangees = [y for _, y in ouest_azuria]
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == plan.width - 1)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == plan.width - 1)
	attendu = [(plan.width - 1, y) for y in rangees]
	r.critere(raccord_est == warps == spawns == attendu and rangees == [19, 20, 21],
		f"raccord est : rangées {[y for _, y in raccord_est]} praticables, warps "
		f"{[y for _, y in warps]}, spawns {[y for _, y in spawns]} = ouest d'Azuria "
		f"(0, {rangees[0]}..{rangees[-1]}), aucun décalage")
	bords = _libres_du_bord(carte)
	r.critere(sorted(bords) == sorted(raccord_est),
		"carte fermée : seul le raccord est touche le bord (la bouche de la grotte est intérieure)")

	# 3. Rebord : unique descente, ne se monte pas, pas de retour vers la grotte.
	rebord = plan.cells_of(REBORD)
	arrivee = pos["from_mt_moon"].cells[0]
	grotte = pos["sortie_grotte"].cells[0]
	montable = any(carte.pas((x, y + 1), (0, -1)) is not None for x, y in rebord)
	laterale = any(carte.pas((x - dx, y), (dx, 0)) is not None for x, y in rebord for dx in (-1, 1))
	x0, y0, x1, y1 = _boite(rebord)
	r.critere(len(_composantes(set(rebord))) == 1 and y0 == y1 and not montable and not laterale,
		f"rebord ({x0}..{x1}, {y0}) : une seule bande d'une rangée, saut vers le SUD seulement, "
		"ne se monte pas")
	dist = carte.distances([arrivee])
	aller = min(dist.get(c, INF) for c in raccord_est)
	sans_rebord = carte.sans(rebord).distances([arrivee])
	r.critere(aller < INF and min(sans_rebord.get(c, INF) for c in raccord_est) >= INF,
		f"le rebord est l'UNIQUE descente : sans lui le raccord est est inatteignable ; avec lui "
		f"{aller} pas depuis l'arrivée (3, 6)")
	palier = [(x, y1 + 1) for x in range(x0, x1 + 1)]
	depuis_plaine = base.distances(raccord_est + palier)
	r.critere(all(c in depuis_plaine for c in palier) and grotte not in depuis_plaine
		and arrivee not in depuis_plaine and all(c not in depuis_plaine for c in sas_cases),
		"depuis la plaine (palier, raccord est) on ne remonte NI vers la grotte NI vers le sas : "
		"aucune case du sas atteignable (retour seulement par l'échelle, côté plateau)")
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and plan.at(x, y) != REBORD
		and (x, y) not in carte.bloquees and (x, y) not in dist]
	r.critere(not orphelines, f"toutes les cases praticables sont atteignables depuis l'arrivée "
		f"{orphelines[:3] if orphelines else ''}")
	r.critere(CHEMIN_ROUTE_4[0] <= aller <= CHEMIN_ROUTE_4[1],
		f"chemin principal {aller} pas (attendu {CHEMIN_ROUTE_4[0]} à {CHEMIN_ROUTE_4[1]})")

	# 4. Hautes herbes : H2 obligatoire (sur la rue), H1 et H3 évitables sans détour.
	zones = zones_herbes(plan)
	noms = ("H1", "H2", "H3")
	nommees = nommer_zones(plan, noms)
	if len(zones) != 3 or sorted(nommees) != list(noms):
		r.critere(False, f"3 zones d'herbes H1..H3 attendues : {len(zones)} trouvées")
		return False
	for n in noms:
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	g_min = min(carte.herbes_min([arrivee], lambda c: c in toutes).get(c, INF) for c in raccord_est)
	r.critere(4 <= g_min <= 7, f"cases de hautes herbes obligatoires : {g_min} (attendu 4 à 7)")
	h1, h2, h3 = (nommees[n] for n in noms)
	sans_h2 = min(carte.sans(h2).distances([arrivee]).get(c, INF) for c in raccord_est)
	r.critere(sans_h2 >= INF, "H2 incontournable (rue entre deux murs d'arbres) : sa traversée "
		"est obligatoire")
	for n, z in (("H1", h1), ("H3", h3)):
		d = min(carte.sans(z).distances([arrivee]).get(c, INF) for c in raccord_est)
		r.critere(d == aller, f"{n} évitable sans détour ({d} pas sans y entrer)")
	hors = min(carte.herbes_min([arrivee], lambda c: c in toutes and c not in h2).get(c, INF)
		for c in raccord_est)
	r.critere(hors == 0, f"aucune case obligatoire hors de H2 (minimum hors : {hors})")

	# 5. Clara.
	dresseurs = _role(plan, "dresseur")
	clara = dresseurs.get("D1")
	r.critere(list(dresseurs) == ["D1"], f"un seul Dresseur : {sorted(dresseurs)}")
	if clara is None:
		return False
	vue = ligne_de_vue(carte, clara)
	vision = int(clara.attrs["sight"])
	r.critere(len(vue) == vision == 3 and plan.at(*clara.cells[0]) in SOL,
		f"Clara {clara.cells[0]} tournée {clara.attrs['facing']} : vision {len(vue)}/{vision} "
		f"cases dégagées ({''.join(plan.at(*c) for c in vue)})")
	d = min(carte.sans(vue).distances([arrivee]).get(c, INF) for c in raccord_est)
	r.critere(d < INF and d - aller <= 2, f"Clara évitable : raccord est en {d} pas hors de sa "
		f"vue (+{d - aller})")
	ligne = set(ligne_brute(plan, clara))
	cibles = [raccord_est]
	objets = _role(plan, "objet_visible")
	cibles += [_acces(carte, p) for p in objets.values()]
	fermes = _approche_ferme(plan, carte, dresseurs, {"D1": vue}, cibles, dist)
	r.critere(not fermes, f"l'approche de Clara ne ferme aucun passage {fermes[:3] if fermes else ''}")

	# 6. Objet visible, PNJ, panneau, points d'apparition.
	r.critere(sorted(objets) == ["O1"] and objets["O1"].attrs.get("item") == "poke_ball",
		"1 Poké Ball visible (O1)")
	o1 = objets["O1"]
	c = o1.cells[0]
	atteint = _joignable(carte, dist, o1)
	r.critere(atteint < INF and plan.at(*c) in SOL and c not in ligne
		and plan.at(*c) != "=",
		f"Poké Ball {c} sur « {plan.at(*c)} » (poche ouest sous le versant) : atteinte en "
		f"{atteint} pas, hors de la vue de Clara")
	fautes: list[str] = []
	for p in plan.of_kind("panneau"):
		if not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"{p.ident} sans case voisine atteignable")
	for p in plan.of_kind("spawn"):
		for cc in p.cells:
			if cc not in dist and cc not in raccord_est:
				fautes.append(f"{p.ident} {cc} hors d'atteinte")
	r.critere(not fautes, "panneau et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))

	# Statistiques et durée.
	rencontres = g_min * TAUX
	duree = aller * S_PAR_PAS + rencontres * S_SAUVAGE
	r.info(f"statistiques : {_cases_praticables(plan)} cases praticables sur "
		f"{plan.width * plan.height} ({100 * _cases_praticables(plan) / (plan.width * plan.height):.0f} %), "
		f"{len(toutes)} cases d'herbes ({', '.join(f'{n} {len(nommees[n])}' for n in noms)})")
	r.info(f"traversée directe estimée : {aller} pas × {S_PAR_PAS} s + {rencontres:.2f} "
		f"rencontre(s) attendue(s) × {S_SAUVAGE} s = {duree:.0f} s ({int(duree // 60)} min "
		f"{int(duree % 60):02d} s) ; marche seule {aller * S_PAR_PAS:.0f} s ; sans compter Clara "
		"(évitable) ni l'entraînement dans les herbes")
	return r.ok


# ===================================================================================== Azuria

def _largeur_min(carte: Carte, c: Case) -> int:
	"""Largeur d'une case de quai : min (course horizontale, course verticale) de cases libres."""
	def course(d: Case) -> int:
		n = 1
		for sens in (1, -1):
			k = 1
			while carte.libre(_decale(c, d, sens * k)):
				k += 1
				n += 1
		return n
	return min(course((1, 0)), course((0, 1)))


def verifier_azuria(chemin: Path) -> bool:
	plan = lire(chemin)
	route_4 = lire(chemin.with_name("route_4.txt"))
	route_24 = lire(chemin.with_name("route_24.txt"))
	r = Rapport(f"Azuria — {_nom(chemin)} : {plan.width} × {plan.height}")
	carte = Carte(plan)
	pos = plan.positions
	r.critere((plan.width, plan.height) == TAILLES["azuria"],
		f"taille {plan.width} × {plan.height} (attendu {TAILLES['azuria'][0]} × "
		f"{TAILLES['azuria'][1]})")

	# 1. Raccords : ouest (Route 4, mêmes rangées), nord (Route 24, mêmes colonnes).
	entree = sorted(c for c in _libres_du_bord(carte) if c[0] == 0)
	nord = sorted(c for c in _libres_du_bord(carte) if c[1] == 0)
	est_r4 = sorted(c for p in route_4.of_kind("warp") for c in p.cells if c[0] == route_4.width - 1)
	sud_r24 = sorted(c for p in route_24.of_kind("warp") for c in p.cells if c[1] == route_24.height - 1)
	w_ouest = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	s_ouest = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	r.critere(entree == w_ouest == s_ouest and [y for _, y in entree] == [y for _, y in est_r4],
		f"raccord ouest : rangées {[y for _, y in entree]} praticables, warps, spawns = est de la "
		f"Route 4 (63, {est_r4[0][1]}..{est_r4[-1][1]}), aucun décalage")
	w_nord = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == 0)
	s_nord = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[1] == 0)
	r.critere(nord == w_nord == s_nord and [x for x, _ in nord] == [x for x, _ in sud_r24],
		f"raccord nord : colonnes {[x for x, _ in nord]} praticables, warps, spawns = sud de la "
		f"Route 24 (colonnes {[x for x, _ in sud_r24]})")
	# Raccord est (J18, dossier 21 §9) : derrière l'arbre à couper « k », atteignable seulement une
	# fois l'arbre coupé (J16) ; mêmes rangées que le raccord ouest de la Route 9.
	route_9 = lire(PLANS / "route_9.txt")
	ouest_r9 = sorted(c for p in route_9.of_kind("warp") for c in p.cells if c[0] == 0)
	est = sorted(c for c in _libres_du_bord(carte) if c[0] == plan.width - 1)
	w_est = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == plan.width - 1)
	s_est = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == plan.width - 1)
	r.critere(est == w_est == s_est and [y for _, y in est] == [y for _, y in ouest_r9],
		f"raccord est : rangées {[y for _, y in est]} praticables, warps, spawns = ouest de la "
		f"Route 9 (0, {ouest_r9[0][1]}..{ouest_r9[-1][1]}), aucun décalage")
	bords = _libres_du_bord(carte)
	r.critere(sorted(bords) == sorted(entree + nord + est),
		"carte fermée : seuls les raccords ouest, nord et est touchent le bord (sud fermé)")
	eau_nord = sorted(x for x in range(plan.width) if plan.at(x, 0) == EAU and x < 40)
	eau_r24 = sorted(x for x in range(route_24.width) if route_24.at(x, route_24.height - 1) == EAU)
	r.critere(eau_nord == eau_r24, f"le canal descend de la Route 24 : eau en colonnes "
		f"{eau_nord[0]}..{eau_nord[-1]} au bord nord, mêmes colonnes en bas de la Route 24")

	# 2. Eau : jamais praticable ; canal en L ; angles droits ; ponts ; quais.
	eau = set(plan.cells_of(EAU))
	praticables_eau = [c for c in eau if carte.libre(c)] + [c for c in eau if EAU in plan.praticables]
	sur_eau = [p.ident for p in plan.positions.values() for c in p.cells
		if c in eau and p.kind not in ("repere",)]
	r.critere(EAU not in plan.praticables and not praticables_eau and not sur_eau,
		f"eau jamais praticable ({len(eau)} cases), aucune position sur l'eau {sur_eau}")
	pont_cases = set(plan.cells_of("B"))
	comp_eau = _composantes(eau | pont_cases)
	r.critere(len(comp_eau) == 1, "une seule masse d'eau (canal en L + baie), coupée seulement par "
		f"les ponts : {len(comp_eau)}")
	eau_pont = eau | pont_cases
	colonnes_h = sorted(x for x in range(plan.width) if plan.at(x, 0) == EAU and x < 40)
	vertical = (colonnes_h[0], colonnes_h[-1])
	haut_h = [y for y in range(plan.height) if plan.at(35, y) == EAU]
	coin = haut_h[0]
	vertical_ok = all((x, y) in eau_pont for x in range(vertical[0], vertical[1] + 1)
		for y in range(0, coin)) and all(
		plan.at(vertical[0] - 1, y) != EAU and plan.at(vertical[1] + 1, y) != EAU
		for y in range(0, coin))
	r.critere(vertical_ok and vertical[1] - vertical[0] + 1 == 4 and len(haut_h) == 4
		and haut_h == list(range(coin, coin + 4)),
		f"canal en L : segment vertical x {vertical[0]}..{vertical[1]} (4 de large) du bord nord "
		f"au coin (y {coin}), puis segment horizontal y {coin}..{haut_h[-1]} (4 de haut) vers "
		"l'est jusqu'à la baie")
	diag_eau = _en_diagonale(plan, EAU)
	diag_pont = _en_diagonale(plan, "B")
	r.critere(not diag_eau and not diag_pont,
		f"tous les angles sont droits : aucun canal ni pont en diagonale {diag_eau[:3]} "
		f"{diag_pont[:3]}")
	ponts = _composantes(pont_cases)
	details = []
	ponts_ok = len(ponts) == 3
	for k, b in enumerate(ponts, 1):
		x0, y0, x1, y1 = _boite(b)
		larg, haut = x1 - x0 + 1, y1 - y0 + 1
		plein = len(b) == larg * haut
		# traversée dans le sens où le tablier mesure 4 de long (l'eau), largeur = l'autre
		long_, large = (haut, larg) if haut >= larg else (larg, haut)
		sens = (0, 1) if haut >= larg else (1, 0)
		bouts = [(c, s) for c in b for s in (-1, 1)
			if _decale(c, sens, s) not in b and carte.libre(_decale(c, sens, s))]
		deux_rives = (sum(1 for c, s in bouts if s == -1) >= large
			and sum(1 for c, s in bouts if s == 1) >= large)
		ponts_ok &= plein and large >= 2 and deux_rives
		details.append(f"pont {k} (x {x0}..{x1}, y {y0}..{y1}) : {large} de large, {long_} de long")
	r.critere(ponts_ok, "3 ponts, rectangulaires, ≥ 2 de large, rives praticables aux deux "
		"bouts : " + " ; ".join(details))
	quais = [c for c in plan.cells_of("q") if carte.libre(c)]
	etroits = [c for c in quais if _largeur_min(carte, c) < 2]
	# avec les habitants bloquants : la largeur reste ≥ 2 (aucun PNJ ne ferme un quai ou un pont)
	habitants = _role(plan, "pnj")
	avec_pnj = carte.sans(c for p in habitants.values() for c in p.cells)
	etroits_pnj = [c for c in list(quais) + list(pont_cases)
		if avec_pnj.libre(c) and _largeur_min(avec_pnj, c) < 2]
	r.critere(not etroits and not etroits_pnj,
		f"quais et ponts ≥ 2 cases de large partout ({len(quais)} cases de quai), PNJ compris "
		f"{etroits[:3]} {etroits_pnj[:3]}")

	# 3. Bâtiments (emprises) et portes.
	portes = {c for p in plan.of_kind("warp") for c in p.cells}
	autres_portes: dict[str, list[Case]] = {}
	emprises_ok = True
	for car, (larg, haut, cols) in EMPRISES.items():
		extra = {"M": "f"}.get(car, "")
		cases = set(plan.cells_of(car)) | set(plan.cells_of(extra) if extra else [])
		groupes = _composantes(cases | {c for c in plan.cells_of("D") if any(
			plan.at(*_decale(c, d)) == car for d in DIRECTIONS if _dans(plan, _decale(c, d)))})
		for g in groupes:
			x0, y0, x1, y1 = _boite(g)
			taille = (x1 - x0 + 1, y1 - y0 + 1)
			attendues = {(x0 + i, y1) for i in cols}
			portes_g = {c for c in g if plan.at(*c) in ("D", "f")}
			bon = taille == (larg, haut) and len(g) == larg * haut and portes_g == attendues
			emprises_ok &= bon
			r.critere(bon, f"« {car} » ({x0}..{x1}, {y0}..{y1}) : {taille[0]} × {taille[1]} "
				f"(attendu {larg} × {haut}), porte {sorted(portes_g)} "
				f"(colonnes {list(cols)} de la rangée du bas)")
			autres_portes[car] = sorted(attendues)
	cdoor = autres_portes["C"]
	r.critere(len(plan.cells_of("C")) + 2 == 56 and {c for c in plan.cells_of("D")} == {
		c for k, v in autres_portes.items() if k != "M" for c in v},
		"Centre, Boutique, Arène, magasin de vélos, maison ouverte : 5 portes praticables ; la "
		"maison cambriolée a sa porte « f » fermée (6 emprises)")

	# 4. Chemin principal : Centre en premier, avant toute bifurcation.
	dist = carte.distances(entree)
	# Variante « arbre coupé » (Coupe, J16) : « k » devient praticable, la case de l'arbre se libère.
	arbre_k = plan.cells_of("k")
	coupee = Carte(replace(plan, praticables=plan.praticables | {"k"}), carte.bloquees)
	coupee.bloquees -= set(arbre_k)
	dist_coupe = coupee.distances(entree)
	d_centre = min(dist.get(c, INF) for c in cdoor)
	autres = {"Boutique": autres_portes["O"], "magasin de vélos": autres_portes["V"],
		"Arène": autres_portes["Z"], "maison ouverte": autres_portes["m"]}
	d_autres = {n: min(dist.get(c, INF) for c in cs) for n, cs in autres.items()}
	d_nord = min(dist.get(c, INF) for c in nord)
	r.critere(d_centre < INF and all(v < INF for v in d_autres.values()) and d_nord < INF,
		f"depuis l'entrée ouest : Centre {d_centre} pas, "
		+ ", ".join(f"{n} {v}" for n, v in d_autres.items()) + f", sortie nord {d_nord} pas")
	x_porte = max(x for x, _ in cdoor)
	y_porte = cdoor[0][1]
	base = Monde(plan)

	def region(colonne: int) -> set[Case]:
		"""Cases atteignables depuis l'entrée en restant dans les colonnes ≤ `colonne`."""
		vus, pile = set(entree), list(entree)
		while pile:
			c = pile.pop()
			for n in base.voisins(c):
				if n[0] <= colonne and n not in vus and n not in carte.portes:
					vus.add(n)
					pile.append(n)
		return vus
	premiere_branche = next(col for col in range(plan.width) if any(
		c[1] < y_porte or c[1] > 21 or c in pont_cases or c in carte.portes
		for c in region(col)))
	avenue = region(x_porte + 1)
	r.critere(d_centre < min(d_autres.values()) and d_centre < d_nord
		and premiere_branche > x_porte + 1 and all(y_porte <= c[1] <= 21 for c in avenue),
		f"le Centre est le PREMIER bâtiment de l'avenue d'arrivée : porte atteinte en {d_centre} "
		f"pas, avant toute bifurcation (jusqu'à la colonne {x_porte + 1}, l'avenue n'a ni rue "
		f"latérale ni autre porte ; la première rue part en x {premiere_branche}) et avant tout "
		"autre bâtiment, pont ou sortie")

	# 5. Arène de l'autre côté du canal ; sortie nord par le pont, visible depuis la place.
	sans_ponts = carte.sans(pont_cases).distances(entree)
	arene = autres_portes["Z"]
	r.critere(all(c not in sans_ponts for c in arene) and all(c not in sans_ponts for c in nord),
		"l'Arène et la sortie nord sont de l'autre côté du canal : inatteignables sans les ponts "
		f"(Arène à {d_autres['Arène']} pas, sortie nord à {d_nord} pas)")
	central = ponts[next(i for i, b in enumerate(ponts) if _boite(b)[0] == 31)]
	sans_central = carte.sans(central).distances(entree)
	r.critere(min(sans_central.get(c, INF) for c in nord) < INF,
		"la sortie nord reste joignable par un autre pont (ouest puis promenade) si le pont "
		"central est occupé")
	axe = nord[1][0]
	place_y = max(y for y in range(plan.height) if plan.at(axe, y) == "p" and y < 28)
	colonne = [(axe, y) for y in range(0, place_y + 1)]
	r.critere(all(carte.libre(c) for c in colonne),
		f"sortie nord visible depuis la place : colonne x {axe}, de la place (y {place_y}) à "
		f"l'exit (y 0), {len(colonne)} cases libres alignées (pont central compris)")
	r.critere(_largeur_min(carte, (axe, 1)) >= 3, "sortie nord de 3 cases de large")

	# 6. Fermetures sans promesse : est (arbre + clôture), sud (palissade).
	arbre = plan.cells_of("k")
	palissade = plan.cells_of("s")
	acces_est = [c for c in arbre for d in DIRECTIONS if carte.libre(_decale(c, d))
		and _decale(c, d) in dist]
	acces_sud = [c for c in palissade for d in DIRECTIONS if carte.libre(_decale(c, d))
		and _decale(c, d) in dist]
	warps_ferme = [p.ident for p in plan.of_kind("warp")
		if any(c[1] >= plan.height - 3 for c in p.cells)]
	derriere = [(x, y) for x in (54, 55) for y in (22, 23, 24)]
	r.critere(len(arbre) == 1 and arbre[0] == (53, 23) and len(palissade) >= 5 and acces_est
		and acces_sud and not warps_ferme and plan.at(53, 22) == "c" and plan.at(53, 24) == "c"
		and plan.at(32, 40) == "a",
		"est : arbre à couper « k » (53, 23) entre deux pans de clôture ; sud : palissade de chantier ; "
		f"les deux routes y mènent et s'arrêtent là ; AUCUN warp au sud {warps_ferme}")
	r.critere(all(plan.at(*c) == "=" for c in derriere) and all(c not in dist for c in derriere)
		and all(c in dist_coupe for c in derriere) and all(c in dist_coupe for c in est)
		and not any(c in dist for c in est),
		"derrière l'arbre : sentier de 3 × 2 cases inatteignable tant que l'arbre est debout, "
		"atteignable (raccord est compris) une fois coupé")
	r.critere(min(dist_coupe.get(c, INF) for c in est) - max(dist.get(c, INF)
		for c in [(52, 23)]) == 3 and dist_coupe[(53, 23)] == dist[(52, 23)] + 1,
		"l'arbre est le seul verrou : une fois coupé, le raccord est se trouve à 3 pas de la case "
		"devant l'arbre")

	# 7. Grotte Azurée : repère hors d'atteinte, au-delà de l'eau.
	grotte = pos["grotte_azuree"]
	voisins_g = [_decale(c, d) for c in grotte.cells for d in DIRECTIONS
		if _dans(plan, _decale(c, d)) and _decale(c, d) not in grotte.cells]
	r.critere(grotte.bloque and all(not carte.libre(c) for c in grotte.cells)
		and not any(carte.libre(c) for c in voisins_g)
		and all(c not in dist for c in grotte.cells + voisins_g)
		and plan.cells_of("A") and all(plan.at(*c) in "KAw" for c in grotte.cells),
		"Grotte Azurée visible au loin : îlot rocheux bloqué, entouré d'eau, aucun accès")

	# 8. Maison cambriolée.
	f = plan.cells_of("f")
	trou = pos["trou_cloture"].cells[0]
	arrachee = pos["cloture_arrachee"].cells[0]
	jardin = plan.cells_of("j")
	policier = pos["h4_policier"].cells[0]
	voisine = pos["h3_voisine"].cells[0]
	porte_f = f[0]
	devant = _decale(porte_f, (0, 1))
	acces_arrachee = [_decale(arrachee, d) for d in DIRECTIONS if carte.libre(_decale(arrachee, d))
		and _decale(arrachee, d) in dist]
	cote_trou = [_decale(trou, d) for d in DIRECTIONS if _dans(plan, _decale(trou, d))
		and carte.libre(_decale(trou, d))]
	r.critere(len(f) == 1 and not carte.libre(porte_f) and plan.at(*porte_f) not in plan.praticables
		and not any(porte_f in p.cells for p in plan.of_kind("warp"))
		and devant in dist and abs(policier[0] - porte_f[0]) <= 2
		and abs(policier[1] - devant[1]) <= 1,
		f"porte fermée {porte_f} (aucun warp), lue depuis {devant} ; policier {policier} devant "
		"elle")
	r.critere(plan.at(*trou) == "y" and not carte.libre(trou) and not cote_trou
		and all(not carte.libre(c) and c not in dist for c in jardin)
		and plan.at(*arrachee) == "c" and acces_arrachee,
		f"jardin clos ({len(jardin)} cases) inaccessible ; clôture arrachée {arrachee} examinable "
		f"depuis {acces_arrachee} ; trou {trou} dans la clôture est : impraticable, aucune case "
		"praticable de l'autre côté")
	r.critere(abs(voisine[0] - plan.cells_of("m")[0][0]) <= 8 and abs(voisine[1] - porte_f[1]) <= 3,
		f"voisine H3 {voisine} devant sa maison, à côté de la maison cambriolée")

	# 9. Habitants H1..H6 (+ H7, T17 : près de la sortie est fermée, texte 17), panneaux, spawns.
	roles = sorted(habitants)
	r.critere(roles == ["H1", "H2", "H3", "H4", "H5", "H6", "H7"],
		f"7 habitants H1..H7 (H7 près de la sortie fermée) : {roles}")
	fautes: list[str] = []
	places = {"H1": lambda c: plan.at(*c) == "q" and c[0] < 26,
		"H2": lambda c: plan.at(*c) == "B",
		"H3": lambda c: plan.at(*c) == "=" and c[1] == 10,
		"H4": lambda c: plan.at(*c) == "=" and c[1] == 10,
		"H5": lambda c: plan.at(*c) == "p" and c[0] > 34 and c[1] <= 12,
		"H6": lambda c: plan.at(*c) == "p" and c[1] <= 22 and c[0] > 30,
		"H7": lambda c: plan.at(*c) == "=" and c[0] >= 49}
	devant_portes = {_decale(c, (0, 1)) for c in portes if c in dist}
	for role, p in habitants.items():
		c = p.cells[0]
		if not places[role](c):
			fautes.append(f"{role} {p.ident} {c} sur « {plan.at(*c)} » hors de la place attendue")
		if c in devant_portes or plan.at(*c) == "D":
			fautes.append(f"{role} devant ou sur une porte {c}")
		if "facing" not in p.attrs:
			fautes.append(f"{role} sans facing")
		if not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"{role} sans case voisine atteignable")
	for p in plan.of_kind("panneau"):
		c = p.cells[0]
		if plan.at(*c) not in ".=p" or not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"{p.ident} {c} mal placé")
	for p in plan.of_kind("examen"):
		if not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"examen {p.ident} {p.cells[0]} sans case d'accès")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if c not in dist_coupe:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	r.critere(not fautes, "habitants, panneaux, examens et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else
		" (aucun devant une porte, tous atteignables)"))

	# 10. Connexité.
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in carte.bloquees
		and (x, y) not in dist_coupe]
	r.critere(not orphelines, "toutes les cases praticables sont connexes (atteignables depuis "
		f"l'entrée ouest) {orphelines[:4] if orphelines else ''}")
	r.critere(all(any(e in Monde(plan).distances([c]) for e in entree)
		for c in (autres_portes["Z"][0], nord[0], autres_portes["O"][0])),
		"retour possible vers l'entrée ouest depuis l'Arène, la Boutique et la sortie nord")

	# Statistiques et durée.
	r.info(f"statistiques : {_cases_praticables(plan)} cases praticables sur "
		f"{plan.width * plan.height} ({100 * _cases_praticables(plan) / (plan.width * plan.height):.0f} %), "
		f"{len(eau)} cases d'eau")
	marche = d_nord
	r.info(f"entrée ouest → Centre {d_centre} pas ; → sortie nord {d_nord} pas "
		f"(≈ {d_nord * S_PAR_PAS:.0f} s à la marche) ; → Arène {d_autres['Arène']} pas ; "
		f"→ Boutique {d_autres['Boutique']} pas ; → magasin de vélos "
		f"{d_autres['magasin de vélos']} pas ; Centre → sortie nord "
		f"{min(Monde(plan).distances(cdoor).get(c, INF) for c in nord)} pas")
	return r.ok


# ==================================================================================== Route 24

def verifier_route_24(chemin: Path) -> bool:
	plan = lire(chemin)
	azuria = lire(chemin.with_name("azuria.txt"))
	r = Rapport(f"Route 24 — {_nom(chemin)} : {plan.width} × {plan.height}")
	carte = Carte(plan)
	pos = plan.positions
	r.critere((plan.width, plan.height) == TAILLES["route_24"],
		f"taille {plan.width} × {plan.height} (attendu {TAILLES['route_24'][0]} × "
		f"{TAILLES['route_24'][1]})")

	# 1. Raccord sud = sortie nord d'Azuria ; raccord est coming_soon ; carte fermée ailleurs.
	bas = plan.height - 1
	entree = [(x, bas) for x in range(plan.width) if carte.libre((x, bas))]
	nord_az = sorted(c for p in azuria.of_kind("warp") for c in p.cells if c[1] == 0)
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == bas)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[1] == bas)
	r.critere(entree == warps == spawns and [x for x, _ in entree] == [x for x, _ in nord_az],
		f"raccord sud : colonnes {[x for x, _ in entree]} praticables, warps, spawns = sortie "
		f"nord d'Azuria ({[x for x, _ in nord_az]}), mêmes colonnes")
	est = [(plan.width - 1, y) for y in range(plan.height) if carte.libre((plan.width - 1, y))]
	raccord = pos["raccord_est"]
	bords = _libres_du_bord(carte)
	r.critere(sorted(bords) == sorted(entree + est) and sorted(est) == sorted(raccord.cells)
		and "coming_soon" in raccord.attrs and len(est) == 3,
		f"raccord est {est} « ROUTE 25 — À venir » (coming_soon) ; carte fermée : seuls les "
		"raccords sud et est touchent le bord")

	# 2. Eau, tablier, canal.
	r.critere(EAU not in plan.praticables and not any(carte.libre(c) for c in plan.cells_of(EAU)),
		f"eau jamais praticable ({len(plan.cells_of(EAU))} cases)")
	tablier = plan.cells_of("B")
	x0, y0, x1, y1 = _boite(tablier)
	r.critere(len(tablier) == (x1 - x0 + 1) * (y1 - y0 + 1) and x1 - x0 + 1 == 2 and y1 - y0 + 1 >= 20
		and not _en_diagonale(plan, "B") and not _en_diagonale(plan, EAU),
		f"Pont Pépite : tablier rectangulaire de 2 cases de large (x {x0}..{x1}), {y1 - y0 + 1} "
		f"de long (y {y0}..{y1}) ; aucun pont ni canal en diagonale")
	r.critere(all(carte.libre((x, y0 - 1)) for x in (x0, x1)) and carte.libre((x0, y1 + 1)),
		"le tablier relie la rive sud (place du pied du pont) et la rive nord")

	# 3. Le rival : vue sur toute la largeur du goulet, inévitable ; Ondine derrière lui.
	dist = carte.distances(entree)
	dresseurs = _role(plan, "dresseur")
	roles = sorted(dresseurs)
	r.critere(roles == ["P1", "P2", "P3", "P4", "P5", "R", "RC"],
		f"7 Dresseurs : rival R, P1..P5, recruteur RC ({roles})")
	if roles != ["P1", "P2", "P3", "P4", "P5", "R", "RC"]:
		return False
	vues = {}
	attendu_vision = {"R": 5, "P1": 3, "P2": 3, "P3": 3, "P4": 3, "P5": 3, "RC": 3}
	for role in roles:
		p = dresseurs[role]
		vues[role] = ligne_de_vue(carte, p)
		vision = int(p.attrs["sight"])
		sol = plan.at(*p.cells[0])
		r.critere(vision == attendu_vision[role] and len(vues[role]) == vision
			and sol in ".=B" and sol != "h",
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs['facing']} sur « {sol} » : vision "
			f"{len(vues[role])}/{vision} cases dégagées ({''.join(plan.at(*c) for c in vues[role])})")
	rival = dresseurs["R"]
	ligne = vues["R"]
	goulet = [c for c in plan.cells_of("=") if c[1] == rival.cells[0][1]]
	r.critere(set(goulet) <= set(ligne) and rival.cells[0][0] > max(x for x, _ in goulet)
		and plan.at(rival.cells[0][0] - 1, rival.cells[0][1]) == ".",
		f"vue du rival {rival.cells[0]} → {ligne[-1]} : couvre toute la largeur du goulet "
		f"(x {min(x for x, _ in goulet)}..{max(x for x, _ in goulet)}, rangée {rival.cells[0][1]}), "
		"depuis une niche en retrait (modèle de Théo)")
	nord_bank = [(x, y0 - 1) for x in range(x0, x1 + 1)]
	cibles_nord = nord_bank + est
	sans_r = carte.sans(ligne)
	d_sans = sans_r.distances(entree)
	premiere = premiere_detection(carte, entree, ligne)
	r.critere(all(c not in d_sans for c in cibles_nord) and premiere >= DETECTION_MIN,
		f"rival inévitable (rive nord et raccord est : fermés sans traverser sa vue) ; première "
		f"case vue à {premiere} cases (attendu ≥ {DETECTION_MIN})")
	ondine = pos["ondine"]
	acces_o = _acces(carte, ondine)
	r.critere(acces_o and all(c not in d_sans for c in acces_o)
		and all(c in dist for c in acces_o) and ondine.cells[0] not in ligne
		and plan.at(*ondine.cells[0]) == "p",
		f"Ondine {ondine.cells[0]} sur la berge, au-delà du rival : inaccessible avant le combat "
		f"({len(acces_o)} cases d'accès, toutes fermées sans passer par sa vue), joignable après")
	panneau = pos["panneau_pont"].cells[0]
	entrees_pont = [(x, y1) for x in range(x0, x1 + 1) if carte.libre((x, y1 + 1))]
	r.critere(panneau == (x1, y1 + 1) and not carte.libre(panneau) and entrees_pont == [(x0, y1)],
		f"panneau « PONT PÉPITE » {panneau} au pied du pont : il ferme la file est, on n'entre "
		f"sur le tablier que par la file ouest {entrees_pont}")

	# 4. P1..P5 et recruteur : en quinconce, inévitables, première case vue à ≥ 3.
	chaine = ["P1", "P2", "P3", "P4", "P5", "RC"]
	files = [dresseurs[k].cells[0][0] for k in chaine]
	rangees = [dresseurs[k].cells[0][1] for k in chaine]
	quinconce = (all(files[i] != files[i + 1] for i in range(5)) and set(files) == {x0, x1}
		and all(rangees[i] - rangees[i + 1] == 4 for i in range(5)))
	r.critere(quinconce, f"quinconce : files {files}, rangées {rangees} (une rangée sur quatre, "
		"alternées ouest/est)")
	for k in chaine:
		vue = vues[k]
		d = carte.sans(vue).distances(entree)
		premiere = premiere_detection(carte, entree, vue)
		ferme = all(c not in d for c in nord_bank)
		r.critere(ferme and premiere >= DETECTION_MIN,
			f"{k} inévitable (rive nord fermée sans traverser sa vue) ; première case vue à "
			f"{premiere} cases (attendu ≥ {DETECTION_MIN})")
	apres = carte.distances(entree)
	r.critere(all(c in apres for c in nord_bank + est),
		"corps des Dresseurs restés sur le pont : la rive nord et le raccord est restent "
		"atteignables en changeant de file à chaque étape")
	atteignables = carte.distances(entree)
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	cibles = [entree, nord_bank, est] + [_acces(carte, p) for p in objets.values()]
	fermes = _approche_ferme(plan, carte, dresseurs, vues, cibles, atteignables)
	r.critere(not fermes, "l'approche d'un Dresseur ne ferme aucun passage (le joueur n'est jamais "
		f"coincé entre deux Dresseurs) {fermes[:3] if fermes else ''}")

	# 5. L'espace nord : fermé tant que le recruteur n'est pas passé ; herbes, objets.
	d_rc = carte.sans(vues["RC"]).distances(entree)
	nord_cases = [c for c in atteignables if c[1] < y0]
	r.critere(nord_cases and all(c not in d_rc for c in nord_cases),
		f"espace nord ({len(nord_cases)} cases) : inatteignable sans traverser la vue du recruteur")
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ("H1", "H2"))
	if len(zones) != 2 or sorted(nommees) != ["H1", "H2"]:
		r.critere(False, f"2 zones d'herbes H1, H2 attendues : {len(zones)} trouvées")
		return False
	for n in ("H1", "H2"):
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	aller = min(atteignables.get(c, INF) for c in est)
	for n in ("H1", "H2"):
		d = min(carte.sans(nommees[n]).distances(entree).get(c, INF) for c in est)
		r.critere(d == aller, f"{n} évitable sans détour ({d} pas sans y entrer)")
	r.critere(sorted(objets) == ["O1", "O2"] and objets["O1"].kind == "objet_visible"
		and objets["O1"].attrs["item"] == "potion" and objets["O2"].kind == "cache"
		and objets["O2"].attrs["item"] == "antidote" and "indice" in objets["O2"].attrs,
		"Potion visible (O1) et Antidote caché (O2, type « cache »)")
	toutes_lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for k, p in sorted(objets.items()):
		c = p.cells[0]
		d = _joignable(carte, atteignables, p)
		bon = d < INF and plan.at(*c) == "." and c not in toutes_lignes and c[1] < y0 and p.bloque
		r.critere(bon, f"{k} {p.ident} {c} sur « {plan.at(*c)} » ({p.attrs['item']}"
			+ (f", indice {p.attrs['indice']}" if p.kind == "cache" else "")
			+ f") : atteint en {d} pas, dans l'espace nord, hors des lignes de vue")

	# 6. Placement : PNJ, panneau, spawns.
	fautes = []
	for p in plan.of_kind("pnj") + plan.of_kind("panneau"):
		for c in p.cells:
			if plan.at(*c) == HERBES or c in toutes_lignes:
				fautes.append(f"{p.ident} {c} sur les herbes ou une ligne de vue")
		if not any(a in atteignables for a in _acces(carte, p)):
			fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if c not in atteignables:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in carte.bloquees
		and (x, y) not in atteignables]
	r.critere(not fautes and not orphelines, "PNJ, panneau, points d'apparition bien placés ; "
		f"toutes les cases praticables connexes {orphelines[:3] if orphelines else ''}"
		+ (" : " + " ; ".join(fautes) if fautes else ""))

	# Statistiques et durée.
	r.critere(CHEMIN_ROUTE_24[0] <= aller <= CHEMIN_ROUTE_24[1],
		f"chemin principal {aller} pas (attendu {CHEMIN_ROUTE_24[0]} à {CHEMIN_ROUTE_24[1]})")
	au_pont = min(atteignables.get(c, INF) for c in nord_bank)
	au_rival = min(atteignables.get(c, INF) for c in ligne)
	r.info(f"statistiques : {_cases_praticables(plan)} cases praticables sur "
		f"{plan.width * plan.height} ({100 * _cases_praticables(plan) / (plan.width * plan.height):.0f} %), "
		f"{len(toutes)} cases d'herbes (H1 {len(nommees['H1'])}, H2 {len(nommees['H2'])})")
	r.info(f"raccord sud → rival {au_rival} pas ; → pied du pont "
		f"{min(atteignables.get(c, INF) for c in [(x0, y1 + 1)])} pas ; → rive nord {au_pont} pas ; "
		f"→ raccord est {aller} pas")
	combats = sum(S_COMBATS.values())
	duree = aller * S_PAR_PAS + combats
	r.info(f"traversée directe estimée : {aller} pas × {S_PAR_PAS} s + rival {S_COMBATS['rival']} "
		f"s + scène d'Ondine {S_COMBATS['ondine_scene']} s + P1..P5 "
		f"{sum(S_COMBATS[k] for k in ('P1', 'P2', 'P3', 'P4', 'P5'))} s + recruteur "
		f"{S_COMBATS['recruteur']} s = {duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s) ; "
		f"marche seule {aller * S_PAR_PAS:.0f} s ; aucune herbe obligatoire")
	return r.ok


# ====================================================================================== Arène

def verifier_arene(chemin: Path) -> bool:
	plan = lire(chemin)
	r = Rapport(f"Arène d'Azuria — {_nom(chemin)} : {plan.width} × {plan.height}")
	carte = Carte(plan, portes=set())
	pos = plan.positions
	r.critere((plan.width, plan.height) == TAILLES["azuria_arene"],
		f"taille {plan.width} × {plan.height} (attendu 17 × 13)")
	entree = pos["entree"].cells[0]
	sortie = pos["sortie"].cells
	r.critere(sortie == [(x, plan.height - 2) for x in (7, 8, 9)] and plan.cells_of("X") == sortie
		and entree == (8, plan.height - 2),
		f"sortie {sortie[0]}…{sortie[-1]} au mur du bas (avant-dernière rangée), entrée {entree} "
		"sur la dalle")
	bassin = plan.cells_of("W")
	x0, y0, x1, y1 = _boite(bassin)
	r.critere("W" not in plan.praticables and not any(carte.libre(c) for c in bassin)
		and len(bassin) == (x1 - x0 + 1) * (y1 - y0 + 1) and (x1 - x0 + 1, y1 - y0 + 1) == (7, 5),
		f"bassin central {x1 - x0 + 1} × {y1 - y0 + 1} (x {x0}..{x1}, y {y0}..{y1}) bloqué : "
		"jamais praticable")
	dist = carte.distances([entree])
	# Chemins secs autour : anneau de cases libres sur les quatre côtés du bassin.
	anneau = [(x, y) for y in range(y0 - 2, y1 + 3) for x in range(x0 - 3, x1 + 4)
		if (x, y) not in bassin and carte.libre((x, y)) and (
		x < x0 or x > x1 or y < y0 or y > y1)]
	cotes = {"nord": any(carte.libre((x, y0 - 1)) for x in range(x0, x1 + 1)),
		"sud": any(carte.libre((x, y1 + 1)) for x in range(x0, x1 + 1)),
		"ouest": any(carte.libre((x0 - 1, y)) for y in range(y0, y1 + 1)),
		"est": any(carte.libre((x1 + 1, y)) for y in range(y0, y1 + 1))}
	r.critere(all(cotes.values()) and all(c in dist for c in anneau),
		"chemins secs sur les quatre côtés du bassin, tous reliés à l'entrée : le bassin est "
		"contournable par l'ouest comme par l'est")
	ondine = pos["ondine"]
	parler = pos["parler_ondine"].cells[0]
	r.critere(plan.at(*ondine.cells[0]) == "O" and ondine.cells[0][1] == y0 - 1
		and x0 <= ondine.cells[0][0] <= x1 and ondine.attrs.get("condition") == "misty_invited"
		and parler in dist and abs(parler[0] - ondine.cells[0][0]) + abs(parler[1] - ondine.cells[0][1]) == 1,
		f"Ondine {ondine.cells[0]} au fond nord, au bord du bassin, à la condition misty_invited ; "
		f"on lui parle depuis {parler} ({dist.get(parler, INF)} pas de l'entrée)")
	dresseurs = _role(plan, "dresseur")
	r.critere(sorted(dresseurs) == ["A1", "A2"], f"2 Dresseurs : Nageur A1, Jeune Dresseuse A2 "
		f"({sorted(dresseurs)})")
	vues = {}
	for role, p in sorted(dresseurs.items()):
		vues[role] = ligne_de_vue(carte, p)
		vision = int(p.attrs["sight"])
		sur_chemin = all(plan.at(*c) == "." for c in vues[role])
		lateral = p.cells[0][0] < x0 or p.cells[0][0] > x1
		r.critere(len(vues[role]) == vision and sur_chemin and lateral,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs['facing']} sur le chemin "
			f"{'ouest' if p.cells[0][0] < x0 else 'est'} : vision {len(vues[role])}/{vision}")
	direct = dist.get(parler, INF)
	for role, vue in sorted(vues.items()):
		d = carte.sans(vue).distances([entree]).get(parler, INF)
		r.critere(d < INF, f"{role} évitable : Ondine atteinte en {d} pas hors de sa vue "
			f"(direct : {direct})")
	tous = set().union(*vues.values())
	d_tous = carte.sans(tous).distances([entree]).get(parler, INF)
	r.critere(d_tous < INF, f"les deux Dresseurs évitables ensemble : Ondine en {d_tous} pas")
	for role, vue in sorted(vues.items()):
		r.critere(any(plan.at(*c) == "." for c in vue) and not any(c in vue for c in sortie),
			f"{role} combattable : sa ligne {vue[0]}…{vue[-1]} est sur le sol sec")
	cibles = [[parler], list(sortie)]
	fermes = _approche_ferme(plan, carte, dresseurs, vues, cibles, dist)
	r.critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3] if fermes else ''}")
	guide = pos["guide"].cells[0]
	r.critere(plan.at(*guide) == "G" and abs(guide[0] - entree[0]) <= 3 and guide[1] == entree[1] - 1
		and guide not in sortie and (guide[0], guide[1] - 1) in dist,
		f"guide {guide} à l'entrée, hors de la sortie")
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in carte.bloquees
		and (x, y) not in dist]
	r.critere(not orphelines, "toutes les cases praticables connexes")
	r.critere(plan.height > 11 and plan.width <= 24,
		f"salle {plan.width} × {plan.height} : plus haute que l'écran (11,25 rangées), la caméra "
		"suit en hauteur ; Ondine visible une fois près du bassin")
	r.info(f"entrée → Ondine {direct} pas par le chemin le plus court ; {d_tous} pas hors de la "
		"vue des deux Dresseurs")
	return r.ok


# ==================================================================================== Intérieurs

def verifier_interieur(chemin: Path) -> bool:
	plan = lire(chemin)
	r = Rapport(f"Intérieur {chemin.stem} — {_nom(chemin)} : {plan.width} × {plan.height}")
	carte = Carte(plan, portes=set())
	pos = plan.positions
	r.critere((plan.width, plan.height) == (15, 10),
		f"taille {plan.width} × {plan.height} (enveloppe 15 × 10 réutilisée, comme Argenta)")
	sortie = pos["sortie"].cells
	entree = pos["entree"].cells[0]
	r.critere(sortie == [(x, 8) for x in (6, 7, 8)] and plan.cells_of("X") == sortie
		and entree == (7, 8) and all(plan.at(x, 9) == "K" for x in range(15)),
		f"sortie {sortie[0]}…{sortie[-1]} sur l'avant-dernière rangée (paillasson), entrée {entree}")
	murs = all(plan.at(x, y) == "K" for y in range(3) for x in range(15)) and all(
		plan.at(0, y) == "K" and plan.at(14, y) == "K" for y in range(10))
	r.critere(murs, "mur du fond sur 3 rangées, colonnes 0 et 14 : convention des intérieurs")
	dist = carte.distances([entree])
	fautes = []
	for p in plan.of_kind("pnj"):
		c = p.cells[0]
		if plan.at(*c) not in "vh":
			fautes.append(f"{p.ident} sur « {plan.at(*c)} »")
		if not any(a in dist for a in _acces(carte, p)):
			fautes.append(f"{p.ident} sans case voisine atteignable")
		if "facing" not in p.attrs:
			fautes.append(f"{p.ident} sans facing")
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in carte.bloquees
		and (x, y) not in dist]
	r.critere(not fautes and not orphelines, "PNJ bien placé et atteignable ; toutes les cases "
		"praticables connexes" + (" : " + " ; ".join(fautes) if fautes else ""))
	if chemin.stem == "azuria_velos":
		bikes = [c for c in plan.cells_of("b")]
		r.critere(len(_composantes(set(bikes))) == 4 and 2 <= len(_composantes(set(bikes))) <= 4
			and all(plan.at(c[0], c[1]) == "b" for c in bikes),
			f"vélos exposés : {len(_composantes(set(bikes)))} (2 cases chacun, bloqués)")
	return r.ok


VERIFICATEURS = {
	"route_4": verifier_route_4,
	"azuria": verifier_azuria,
	"route_24": verifier_route_24,
	"azuria_arene": verifier_arene,
	"azuria_velos": verifier_interieur,
	"azuria_maison": verifier_interieur,
}


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
