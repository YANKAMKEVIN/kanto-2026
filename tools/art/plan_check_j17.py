#!/usr/bin/env python3
"""Vérifie les grilles du jalon 17 (dossier 20, « Les chemins retrouvés ») par recherche de chemin.

Grilles : `tools/plans/route_11.txt`, `digletts_cave.txt`, `route_2_east.txt`,
`route_2_east_gate.txt`, et les retouches de la Route 2 sud (`route_2_j17_retouches.txt`, appliquées
EN MÉMOIRE sur `route_2.txt`, qui n'est pas modifié). Lecture par `plan_grille.lire` ; déplacements de
`plan_check.Monde` (4 directions, un pas par case), avec :
  - des **cases terminales** (bouche de Cave `Q`, porte du poste `D`, sorties `E`) : on y entre, on ne
    les traverse pas (elles mènent à une autre carte) ;
  - des **cases libérées** : l'arbuste coupable (`A`, position `arbuste`, drapeau `flag=`) et Ronflex
    (cases de la position `ronflex`) sont des obstacles dans l'état initial et peuvent être levés
    pour une contre-épreuve (« sans lui, le passage existe : il est donc bien le seul »).
Les positions `bloque` (Dresseurs, PNJ, Pokémon d'ambiance, objets, panneaux, case cachée, arbuste,
Ronflex) bloquent leurs cases. Module autonome : n'utilise de `plan_check.py` que `Monde` et ses
fonctions de ligne de vue (celles de `main`), donc aucun profil du J12 n'est nécessaire.

Critères principaux (repris par les tests des cartes au 17A/17B) :
  Route 11 : raccord ouest = (63, 11..13) de Carmin, carte fermée ; bouche de la Cave dans la paroi au
    nord-ouest ; D2 (Arthur) seul Dresseur inévitable (goulet du chemin principal, première case vue à
    ≥ 3 cases), les sept autres évitables un à un ET ensemble ; trois parcours (herbes / centre /
    clôtures) qui suffisent chacun et dont la coupe commune ferme la route ; herbes obligatoires
    seulement sur le parcours nord ; Ronflex 2 × 2 dans un goulet de 2 cases, seul passage : sans lui
    le bord est est atteignable, avec lui non ; objets (2 visibles, 1 caché) atteignables hors lignes
    de vue ; l'approche d'un Dresseur ne ferme aucun passage.
  Cave : bouches alignées sur la Route 11 et la Route 2 est ; traversable bouche à bouche, linéaire ;
    gravats en zones nommées G1..G4 séparées par des couloirs calmes ; deux renfoncements en impasse,
    l'un avec la Corde Sortie.
  Route 2 est : bord ouest = (41, 43..44) de la Route 2 sud ; le poste est atteignable depuis la Cave
    SANS couper l'arbuste ; la partie sud (Pierre Lune, Super Bonbon) et le bord ouest ne le sont
    qu'avec l'arbuste coupé ; aucune herbe, aucun Dresseur.
  Poste (intérieur) : porte, assistant, visiteur atteignables.
  Retouches de la Route 2 sud : seules les cases annoncées changent ; la clairière FUTUR A n'est
    atteignable qu'avec l'arbuste (4, 19) coupé ; le sentier « b » n'est relié à Jadielle qu'avec la
    barrière (34, 43..44) ouverte, et atteignable depuis le bord est dans tous les cas.
Imprime les longueurs de parcours et une estimation de durée de traversée.

Usage : python3 -I tools/art/plan_check_j17.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import HERBES, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]

# Défauts (règle 4), dossier 20 §3.
TAILLE_R11 = (76, 36)
TAILLE_CAVE = (34, 80)
TAILLE_R2E = (16, 48)
TAILLE_POSTE = (15, 10)
CARMIN_EST = (11, 12, 13)          # vermilion_city.txt : warp_est (63, 11..13), si le fichier existe
SOL = set(".=oq")                  # sol où poser personnages, objets et points d'apparition
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases
DRESSEURS = {"D1": 5, "D2": 4, "D3": 3, "D4": 3, "D5": 3, "D6": 3, "D7": 3, "D8": 3}
INEVITABLE = "D2"                  # H-13 : au plus 1 inévitable
HERBES_R11 = ("H1", "H2", "H3")
OBJETS_R11 = {"O1": ("objet_visible", "super_potion"), "O2": ("objet_visible", "awakening"),
	"O3": ("cache", "poke_ball")}
CAVE_PAS = (90, 170)              # pas bouche à bouche
CAVE_GRAVATS = (6, 16)             # cases de gravats obligatoires (trajet le moins exposé)
CAVE_PART_CALME = 0.85
CAVE_ECART_ZONES = 6               # couloir calme entre deux zones de gravats
# Estimation de durée (méthode du J12) : pas mesuré sur S21, combats à deux Pokémon.
S_PAR_PAS = 0.72
S_COMBAT_2 = 120
S_SAUVAGE = 50
TAUX = 25 / 256


class Carte(Monde):
	"""`plan_check.Monde` avec cases terminales et cases libérées (arbuste, Ronflex)."""

	def __init__(self, plan: Plan, bloquees=frozenset(), liberees=frozenset(), portes=frozenset()):
		super().__init__(plan, bloquees)
		self.liberees = set(liberees)
		self.bloquees -= self.liberees
		self.portes = set(portes)

	def libre(self, c: Case) -> bool:
		if c in self.liberees:
			return 0 <= c[0] < self.plan.width and 0 <= c[1] < self.plan.height
		return super().libre(c)

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Carte":
		cases = set(cases)
		return Carte(self.plan, self.bloquees | cases, self.liberees - cases, self.portes)

	def avec(self, cases) -> "Carte":
		"""Même carte, ces cases libérées (arbuste coupé, Ronflex parti)."""
		return Carte(self.plan, self.bloquees, self.liberees | set(cases), self.portes)


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def critere(self, vrai, texte: str) -> bool:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")
		return bool(vrai)

	def titre(self, texte: str) -> None:
		print(f"\n{texte}")


def _d(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _lire(nom: str) -> Plan:
	return lire(PLANS / f"{nom}.txt")


def _dist(carte: Carte, departs, cibles) -> int:
	d = carte.distances(list(departs))
	return min((d.get(c, INF) for c in cibles), default=INF)


def _acces(carte: Carte, p) -> list[Case]:
	"""Cases d'où l'on prend / examine / parle à p : ses voisines libres (hors cases terminales)."""
	return [_d(c, d) for c in p.cells for d in DIRECTIONS
		if carte.libre(_d(c, d)) and _d(c, d) not in carte.portes and _d(c, d) not in p.cells]


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _bord(plan: Plan, carte: Carte) -> list[Case]:
	return [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and carte.libre((x, y))]


def _cases(plan: Plan, ident: str) -> list[Case]:
	return plan.positions[ident].cells


def _autour_paroi(plan: Plan, cases: list[Case], paroi: str) -> bool:
	"""Une ouverture dans la paroi : paroi au-dessus de chaque case et à chaque bout de la rangée."""
	xs = [x for x, _ in cases]
	y = cases[0][1]
	return (all(plan.at(x, y - 1) == paroi for x in xs)
		and plan.at(min(xs) - 1, y) == paroi and plan.at(max(xs) + 1, y) == paroi)


def _composantes(cases: set[Case]) -> list[set[Case]]:
	reste, groupes = set(cases), []
	while reste:
		germe = reste.pop()
		groupe, pile = {germe}, [germe]
		while pile:
			c = pile.pop()
			for d in DIRECTIONS:
				n = _d(c, d)
				if n in reste:
					reste.remove(n)
					groupe.add(n)
					pile.append(n)
		groupes.append(groupe)
	return groupes


def _nom(chemin: Path) -> str:
	return str(chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin)


def _rangees_carmin() -> list[int]:
	f = PLANS / "vermilion_city.txt"
	if f.exists():
		p = lire(f)
		return sorted(y for x, y in p.positions["warp_est"].cells if x == p.width - 1)
	return list(CARMIN_EST)


# --------------------------------------------------------------------------------- Route 11 --

def verifier_route_11() -> bool:
	r = Rapport()
	plan = _lire("route_11")
	pos = plan.positions
	print(f"Grille {_nom(PLANS / 'route_11.txt')} : {plan.width} × {plan.height}")
	r.critere((plan.width, plan.height) == TAILLE_R11,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE_R11[0]} × {TAILLE_R11[1]})")
	mouth = plan.cells_of("Q")
	ronflex = pos["ronflex"]
	terminales = set(mouth)
	carte = Carte(plan, portes=terminales, liberees=())
	sans_ronflex = carte.avec(ronflex.cells)

	# 1. Raccord ouest sur Carmin ; carte fermée ailleurs ; bord est non relié.
	rangees = _rangees_carmin()
	entree = [(0, y) for y in range(plan.height) if carte.libre((0, y))]
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	attendu = [(0, y) for y in rangees]
	r.critere(entree == warps == spawns == attendu,
		f"raccord ouest : rangées {[y for _, y in entree]} praticables, warps {[y for _, y in warps]}, "
		f"spawns {[y for _, y in spawns]} = bord est de Carmin (63, {rangees[0]}..{rangees[-1]}), "
		"mêmes rangées, aucun décalage")
	est = pos["raccord_est"].cells
	bords = _bord(plan, carte)
	r.critere(sorted(bords) == sorted(entree + est) and all(c[0] == plan.width - 1 for c in est)
		and not any(p.kind in ("warp", "spawn") and set(p.cells) & set(est) for p in pos.values()),
		f"carte fermée : seuls le raccord ouest et le bord est {est} (sans warp) touchent le bord")

	# 2. Bouche de la Cave.
	nord_ouest = all(x < plan.width / 2 and y < plan.height / 3 for x, y in mouth)
	r.critere(len(mouth) == 2 and _autour_paroi(plan, mouth, "K") and nord_ouest
		and set(mouth) == set(_cases(plan, "entree_cave")),
		f"bouche de la Cave {mouth} : ouverture dans le talus (K au-dessus et des deux côtés), au "
		"nord-ouest, warp posé dessus")
	arrivee = _cases(plan, "from_cave")
	r.critere(all(plan.at(*c) in SOL and (c[0], c[1] - 1) in mouth for c in arrivee),
		f"arrivée de la Cave {arrivee} : sol praticable devant la bouche")

	# 3. Chemin principal et Ronflex.
	distances = carte.distances(entree)
	vers_cave = min(distances.get(c, INF) for c in mouth)
	xs = sorted({x for x, _ in ronflex.cells})
	ys = sorted({y for _, y in ronflex.cells})
	devant = [(xs[0] - 1, y) for y in ys]            # cases juste à l'ouest de Ronflex
	derriere = [(xs[-1] + 1, y) for y in ys]
	jusqu_a_ronflex = min(distances.get(c, INF) for c in devant)
	r.critere(vers_cave < INF and jusqu_a_ronflex < INF,
		f"entrée ouest → bouche de la Cave : {vers_cave} pas ; → devant Ronflex {devant} : "
		f"{jusqu_a_ronflex} pas")
	if vers_cave >= INF or jusqu_a_ronflex >= INF:
		return r.ok
	r.critere(len(ronflex.cells) == 4 and len(xs) == 2 and len(ys) == 2
		and ronflex.bloque and all(plan.at(*c) == "=" for c in ronflex.cells),
		f"Ronflex {ronflex.cells} : 2 × 2 cases bloquées, sur le chemin de terre")
	goulet = all(sorted(y for y in range(plan.height) if sans_ronflex.libre((x, y)) and
		abs(y - ys[0]) <= 8) == ys for x in xs)
	r.critere(goulet, f"goulet : sur les colonnes {xs} de Ronflex, seules les rangées {ys} sont "
		"praticables (cases voisines bloquées, aucune case contournable)")
	apres = carte.distances(entree)
	derriere_ok = any(c in apres for c in derriere) or any(c in apres for c in est)
	d_sans = sans_ronflex.distances(entree)
	r.critere(not derriere_ok and all(c in d_sans for c in est),
		f"Ronflex est le SEUL passage : avec lui, ni l'est du goulet ni le bord est {est} ne sont "
		"atteignables ; sans lui, le bord est l'est")
	est_zone = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if x > xs[-1] and sans_ronflex.libre((x, y))}
	r.critere(est_zone and not (est_zone & set(apres)),
		f"aucune case du secteur est ({len(est_zone)} cases libres au-delà de x = {xs[-1]}) n'est "
		"atteignable avec Ronflex ; il ferme la route")
	ligne = [(x, ys[0]) for x in range(xs[0] - 20, xs[0])]
	r.critere(all(plan.at(*c) == "=" for c in ligne),
		f"Ronflex se voit de loin : 20 cases de chemin droit dégagé à l'ouest (x {ligne[0][0]}.."
		f"{ligne[-1][0]})")
	retour = carte.distances(list(_cases(plan, "from_cave")))
	r.critere(min(retour.get(c, INF) for c in entree) < INF,
		f"retour : Cave → Carmin {min(retour.get(c, INF) for c in entree)} pas")

	# 4. Hautes herbes.
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, HERBES_R11)
	if sorted(nommees) != sorted(HERBES_R11) or len(zones) != len(HERBES_R11):
		r.critere(False, f"zones H1..H3 attendues : {len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	for n in HERBES_R11:
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	g_min = min(carte.herbes_min(entree, lambda c: c in toutes).get(c, INF) for c in devant)
	g_cave = min(carte.herbes_min(entree, lambda c: c in toutes).get(c, INF) for c in mouth)
	r.critere(g_min == 0 and g_cave == 0,
		f"aucune herbe obligatoire : jusqu'à Ronflex {g_min}, jusqu'à la Cave {g_cave} (le chemin "
		"principal et les clôtures n'en traversent pas)")

	# 5. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	if sorted(dresseurs) != sorted(DRESSEURS):
		r.critere(False, f"8 Dresseurs D1..D8 attendus : {sorted(dresseurs)}")
		return False
	r.critere(True, f"8 Dresseurs D1..D8 : {', '.join(dresseurs[k].ident for k in sorted(dresseurs))}")
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vue = ligne_de_vue(carte, p)
		vues[role] = vue
		vision = int(p.attrs["sight"])
		r.critere(vision == DRESSEURS[role] and len(vue) == vision and plan.at(*p.cells[0]) in SOL,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs['facing']} : vision {len(vue)}/{vision} "
			f"cases dégagées ({''.join(plan.at(*c) for c in vue)})")
	cibles = {"la Cave": mouth, "Ronflex": devant}
	for nom, cib in cibles.items():
		bloque = set(vues[INEVITABLE])
		sans = _dist(carte.sans(bloque), entree, cib)
		premiere = premiere_detection(carte, entree, vues[INEVITABLE])
		r.critere(sans >= INF and premiere >= DETECTION_MIN,
			f"{INEVITABLE} {dresseurs[INEVITABLE].ident} inévitable vers {nom} : "
			f"{'fermé' if sans >= INF else sans} hors de sa vue ; première case vue à {premiere} "
			f"cases (attendu ≥ {DETECTION_MIN})")
	autres = [k for k in DRESSEURS if k != INEVITABLE]
	for role in autres:
		for nom, cib in cibles.items():
			d = _dist(carte.sans(vues[role]), entree, cib)
			r.critere(d < INF, f"{role} {dresseurs[role].ident} évitable vers {nom} : {d} pas "
				"hors de sa vue" + (f" (+{d - min(distances.get(c, INF) for c in cib)})"
				if d < INF else ""))
	tous = set().union(*(vues[k] for k in autres))
	for nom, cib in cibles.items():
		d_tous = _dist(carte.sans(tous), entree, cib)
		r.critere(d_tous < INF, f"D1 et D3..D8 évitables ENSEMBLE vers {nom} : {d_tous} pas (seul "
			f"{INEVITABLE} est obligatoire, H-13)")
	# La vue de D2 est bien dans le goulet du chemin principal (le chemin le plus court la traverse).
	goulet_d2 = set(vues[INEVITABLE])
	r.critere(goulet_d2 <= {c for c in goulet_d2 if plan.at(*c) in ".="}
		and sum(1 for c in goulet_d2 if plan.at(*c) == "=") == 2,
		f"D2 garde un goulet du chemin principal : 2 cases de chemin dans sa ligne de vue, "
		f"{len(goulet_d2)} cases vues")

	# 6. Trois parcours.
	iti = _role(plan, "itineraire")
	if sorted(iti) != ["centre", "nord", "sud"]:
		r.critere(False, f"coupes itineraire nord, centre, sud attendues : {sorted(iti)}")
		return False
	coupes = {k: set(iti[k].cells) for k in iti}
	longueurs = {}
	for k in ("nord", "centre", "sud"):
		autres_c = set().union(*(coupes[o] for o in coupes if o != k))
		longueurs[k] = _dist(carte.sans(autres_c), entree, devant)
	d_aucun = _dist(carte.sans(set().union(*coupes.values())), entree, devant)
	r.critere(all(v < INF for v in longueurs.values()) and d_aucun >= INF,
		f"trois parcours : par le nord (herbes) {longueurs['nord']} pas, par le centre "
		f"{longueurs['centre']} pas, par le sud (clôtures, digue) {longueurs['sud']} pas ; les trois "
		f"coupés : {'fermé' if d_aucun >= INF else d_aucun}")
	nord_herbes = min(carte.sans(coupes["centre"] | coupes["sud"]).herbes_min(
		entree, lambda c: c in toutes).get(c, INF) for c in devant)
	h2 = nommees["H2"]
	n_h2 = min(carte.sans(coupes["centre"] | coupes["sud"]).herbes_min(
		entree, lambda c: c in h2).get(c, INF) for c in devant)
	r.critere(6 <= nord_herbes <= 10 and n_h2 == nord_herbes,
		f"parcours nord : {nord_herbes} cases de hautes herbes obligatoires (attendu 6 à 10), toutes "
		"dans H2 ; centre et sud : 0")
	sud_c = sorted(coupes["sud"])
	r.critere(all(plan.at(*c) == "q" for c in sud_c) and plan.at(sud_c[0][0], sud_c[0][1] - 1) == "c",
		"le parcours sud est la digue (q), bordée au nord d'une rangée de clôtures (c)")

	# 7. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	conformes = sorted(objets) == sorted(OBJETS_R11) and all(
		objets[k].kind == t and objets[k].attrs.get("item") == it
		for k, (t, it) in OBJETS_R11.items() if k in objets)
	r.critere(conformes, "objets O1 (Super Potion) et O2 (Réveil) visibles, O3 (Poké Ball) caché")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((distances.get(a, INF) for a in _acces(carte, p)), default=INF)
		sol = plan.at(*c)
		bon = atteint < INF and sol in SOL and c not in lignes and sol != "h"
		if p.kind == "cache":
			bon &= p.bloque and sol != "=" and "indice" in p.attrs
		r.critere(bon, f"{role} {p.ident} {c} sur « {sol} » ({p.attrs.get('item')}"
			+ (f", indice {p.attrs.get('indice')}" if p.kind == "cache" else "")
			+ f") : atteint en {atteint} pas, hors des lignes de vue")

	# 8. Un Dresseur qui s'approche ne ferme jamais un passage.
	tout = carte.distances(entree + list(arrivee))
	cibles_p = [list(mouth), list(devant), [entree[0]]] + [_acces(carte, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in tout:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Carte(plan, portes=terminales)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles_p):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	r.critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3] if fermes else ''}")

	# 9. PNJ, Pokémon d'ambiance, panneaux, points d'apparition.
	fautes: list[str] = []
	for p in plan.of_kind("pokemon") + plan.of_kind("panneau"):
		for c in p.cells:
			if c in lignes or plan.at(*c) == HERBES:
				fautes.append(f"{p.ident} {c} sur une ligne de vue ou dans les herbes")
			if p.kind == "panneau" and plan.at(*c) not in SOL - {"="}:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} »")
		if not any(a in tout for a in _acces(carte, p)):
			fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
	for ident, lecture in (("panneau_ouest", (3, 11)), ("panneau_cave", (17, 9))):
		c = pos[ident].cells[0]
		if (c[0], c[1] + 1) != lecture or lecture not in tout or lecture in lignes:
			fautes.append(f"{ident} : case de lecture {lecture} (↑) fautive")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if c not in tout or plan.at(*c) not in SOL:
				fautes.append(f"{p.ident} {c} hors d'atteinte ou sur « {plan.at(*c)} »")
	for p in plan.of_kind("herbes"):
		if p.cells[0] not in tout:
			fautes.append(f"{p.ident} hors d'atteinte")
	r.critere(not fautes, "Pokémon d'ambiance, panneaux (T-10 près de la Cave, T-12 à l'entrée "
		"ouest) et points d'apparition bien placés" + (" : " + " ; ".join(fautes) if fautes else ""))

	# Statistiques et durée.
	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	mer = sum(1 for y in range(plan.height) for x in range(plan.width) if plan.at(x, y) == "W")
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), mer {mer} cases, "
		f"{len(toutes)} cases d'herbes ({', '.join(f'{n} {len(nommees[n])}' for n in HERBES_R11)})")
	duree = jusqu_a_ronflex * S_PAR_PAS + S_COMBAT_2
	print(f"  traversée directe estimée (Carmin → devant Ronflex) : {jusqu_a_ronflex} pas × "
		f"{S_PAR_PAS} s + Arthur {S_COMBAT_2} s = {duree:.0f} s ; Cave : {vers_cave} pas "
		f"({vers_cave * S_PAR_PAS + S_COMBAT_2:.0f} s avec Arthur)")
	return r.ok


# ------------------------------------------------------------------------------------- Cave --

def verifier_cave() -> bool:
	r = Rapport()
	plan = _lire("digletts_cave")
	pos = plan.positions
	print(f"Grille {_nom(PLANS / 'digletts_cave.txt')} : {plan.width} × {plan.height}")
	r.critere((plan.width, plan.height) == TAILLE_CAVE,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE_CAVE[0]} × {TAILLE_CAVE[1]})")
	sorties = set(plan.cells_of("E"))
	carte = Carte(plan, portes=sorties)
	sud = sorted(c for c in sorties if c[1] == plan.height - 1)
	nord = sorted(c for c in sorties if c[1] == 0)
	r.critere(len(sud) == 2 and len(nord) == 2 and len(sorties) == 4,
		f"deux bouches de 2 cases : sud {sud}, nord {nord}")
	bords = _bord(plan, carte)
	r.critere(sorted(bords) == sorted(sud + nord), "carte fermée : seules les deux bouches touchent le bord")
	warps = {c for p in plan.of_kind("warp") for c in p.cells}
	spawns = {c for p in plan.of_kind("spawn") for c in p.cells}
	r.critere(warps == set(sud + nord) and spawns == {(x, y + 1 if y == 0 else y - 1) for x, y in sud + nord}
		and all(plan.at(*c) == "." for c in spawns),
		"warps sur les bouches, arrivées sur la case voisine à l'intérieur (sol calme)")
	r11 = _lire("route_11")
	q = r11.cells_of("Q")
	r.critere(sorted(x for x, _ in q) == sorted(x for x, _ in sud),
		f"bouche sud (x {[x for x, _ in sud]}) alignée sur la bouche de la Route 11 (x "
		f"{sorted(x for x, _ in q)}, y {q[0][1]})")
	r2 = _lire("route_2_east")
	q2 = r2.cells_of("Q")
	print(f"  bouche nord (x {[x for x, _ in nord]}) ↔ Route 2 est (bouche x {sorted(x for x, _ in q2)}) : "
		"carte différente, alignement libre (arrivée posée par le spawn)")

	depart = _cases(plan, "from_route_11")
	arrivee = _cases(plan, "from_route_2_east")
	aller = carte.distances(depart)
	pas = min(aller.get(c, INF) for c in nord)
	retour = carte.distances(arrivee)
	pas_retour = min(retour.get(c, INF) for c in sud)
	r.critere(pas < INF and pas_retour < INF and CAVE_PAS[0] <= pas <= CAVE_PAS[1],
		f"traversable bouche à bouche : sud → nord {pas} pas, nord → sud {pas_retour} pas "
		f"(attendu {CAVE_PAS[0]} à {CAVE_PAS[1]}, « courte »)")
	if pas >= INF:
		return False
	r.critere(pas / (plan.height - 2) <= 2.0,
		f"tunnel principalement linéaire : {pas} pas pour {plan.height - 2} rangées "
		f"(rapport {pas / (plan.height - 2):.2f} ≤ 2,0)")
	largeurs = [sum(1 for x in range(plan.width) if plan.at(x, y) in plan.praticables)
		for y in range(1, plan.height - 1)]
	r.critere(all(w >= 4 for w in largeurs) and max(largeurs) <= 20,
		f"couloirs de 4 à 20 cases de large (rangée la plus étroite {min(largeurs)}, la plus large "
		f"{max(largeurs)} : salles et renfoncements compris)")

	# Gravats.
	zones = {p.attrs["role"]: next(z for z in _composantes(set(plan.cells_of("g")))
		if p.cells[0] in z) for p in plan.of_kind("gravats")}
	r.critere(sorted(zones) == ["G1", "G2", "G3", "G4"]
		and sum(len(z) for z in zones.values()) == len(plan.cells_of("g")),
		f"4 zones de gravats nommées G1..G4 : {', '.join(f'{k} {boite(z)}' for k, z in sorted(zones.items()))}")
	toutes = set().union(*zones.values())
	g_min = min(carte.herbes_min(depart, lambda c: c in toutes).get(c, INF) for c in nord)
	r.critere(CAVE_GRAVATS[0] <= g_min <= CAVE_GRAVATS[1],
		f"cases de gravats obligatoires sur le trajet le moins exposé : {g_min} "
		f"(attendu {CAVE_GRAVATS[0]} à {CAVE_GRAVATS[1]})")
	obligatoires = []
	for k, z in sorted(zones.items()):
		sans = _dist(carte.sans(z), depart, nord)
		if sans >= INF:
			obligatoires.append(k)
		else:
			print(f"  {k} évitable : {sans} pas hors de la zone (+{sans - pas})")
	r.critere(obligatoires == ["G2"],
		f"gravats obligatoires : {obligatoires} (G2, pleine largeur ; G1, G3, G4 laissent une colonne calme)")
	ecarts = [min(max(abs(a[0] - b[0]), abs(a[1] - b[1])) for a in za for b in zb)
		for i, (ka, za) in enumerate(sorted(zones.items())) for kb, zb in sorted(zones.items())[i + 1:]]
	r.critere(min(ecarts) >= CAVE_ECART_ZONES,
		f"zones séparées par des couloirs calmes : écart minimal entre deux zones {min(ecarts)} "
		f"cases (attendu ≥ {CAVE_ECART_ZONES})")
	d_g = carte.herbes_min(depart, lambda c: c in toutes)
	# part calme du trajet le moins exposé (le plus court parmi ceux-là)
	sans_evitables = carte.sans(zones["G1"] | zones["G3"] | zones["G4"])
	pas_calme = _dist(sans_evitables, depart, nord)
	part = 1 - g_min / pas_calme
	r.critere(part >= CAVE_PART_CALME,
		f"part de couloirs calmes sur le trajet : {100 * part:.0f} % ({pas_calme} pas dont {g_min} de "
		f"gravats ; attendu ≥ {100 * CAVE_PART_CALME:.0f} %)")

	# Renfoncements.
	niches = _role(plan, "repere")
	r.critere(sorted(niches) == ["R1", "R2"], f"deux renfoncements nommés R1, R2 : {sorted(niches)}")
	objets = plan.of_kind("objet_visible")
	total = len(carte.distances(depart))
	for k in ("R1", "R2"):
		cases = set(niches[k].cells)
		libres_niche = [c for c in cases if c in aller]
		sans_niche = len(carte.sans(cases).distances(depart))
		bord_niche = [c for c in cases for d in DIRECTIONS if carte.libre(_d(c, d)) and _d(c, d) not in cases]
		impasse = sans_niche == total - len(libres_niche)
		dedans = [p for p in objets if p.cells[0] in cases]
		r.critere(impasse and pas == _dist(carte.sans(cases), depart, nord) and len(bord_niche) <= 4,
			f"renfoncement {k} {sorted(cases)[0]}..{sorted(cases)[-1]} : impasse facultative "
			f"({len(bord_niche)} case(s) d'ouverture), le tunnel se traverse sans y entrer"
			+ (f" ; contient {dedans[0].attrs['item']}" if dedans else " ; vide"))
	r.critere(len(objets) == 1 and objets[0].attrs.get("item") == "escape_rope"
		and objets[0].cells[0] in niches["R1"].cells and plan.at(*objets[0].cells[0]) == ".",
		"un seul objet visible : la Corde Sortie, dans R1, sur du sol calme")
	acces = min((aller.get(a, INF) for a in _acces(carte, objets[0])), default=INF)
	r.critere(acces < INF, f"Corde Sortie atteinte en {acces} pas depuis la bouche sud")

	# Taupiqueur d'ambiance : ne ferment rien.
	fautes = []
	for p in plan.of_kind("pokemon"):
		c = p.cells[0]
		if plan.at(*c) != "g":
			fautes.append(f"{p.ident} {c} hors des gravats")
		if not any(a in aller for a in _acces(carte, p)):
			fautes.append(f"{p.ident} sans case voisine atteignable")
	r.critere(not fautes and len(plan.of_kind("pokemon")) >= 3,
		f"Taupiqueur d'ambiance ({len(plan.of_kind('pokemon'))}) sur le bord des gravats, aucun n'obstrue "
		"le tunnel" + (" : " + " ; ".join(fautes) if fautes else ""))
	duree = pas * S_PAR_PAS + g_min * TAUX * S_SAUVAGE
	print(f"  durée estimée : {pas} pas × {S_PAR_PAS} s + {g_min * TAUX:.2f} rencontre(s) × "
		f"{S_SAUVAGE} s = {duree:.0f} s ; {sum(1 for _ in plan.cells_of('.'))} cases de sol calme, "
		f"{len(toutes)} de gravats")
	return r.ok


# ------------------------------------------------------------------------------ Route 2 est --

def _bord_ouest_route_2() -> list[int]:
	"""Rangées du bord est de la Route 2 sud où le sentier « b » arrive (route_2.txt)."""
	p = _lire("route_2")
	return sorted(y for y in range(p.height) if p.at(p.width - 1, y) == "b")


def verifier_route_2_est() -> bool:
	r = Rapport()
	plan = _lire("route_2_east")
	pos = plan.positions
	print(f"Grille {_nom(PLANS / 'route_2_east.txt')} : {plan.width} × {plan.height}")
	r.critere((plan.width, plan.height) == TAILLE_R2E,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE_R2E[0]} × {TAILLE_R2E[1]})")
	bouche = plan.cells_of("Q")
	porte = plan.cells_of("D")
	arbuste = pos["arbuste"]
	terminales = set(bouche) | set(porte)
	carte = Carte(plan, portes=terminales)
	coupe = carte.avec(arbuste.cells)

	# 1. Raccord ouest ; carte fermée.
	rangees = _bord_ouest_route_2()
	entree = [(0, y) for y in range(plan.height) if carte.libre((0, y))]
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	attendu = [(0, y) for y in rangees]
	r.critere(entree == warps == spawns == attendu and len(entree) == 2,
		f"raccord ouest : rangées {[y for _, y in entree]} (2 cases), warps {[y for _, y in warps]}, "
		f"spawns {[y for _, y in spawns]} = sentier « b » de la Route 2 sud (41, {rangees[0]}.."
		f"{rangees[-1]}), mêmes rangées")
	bords = _bord(plan, carte)
	r.critere(sorted(bords) == sorted(entree), "carte fermée : seul le raccord ouest touche le bord")

	# 2. Bouche nord de la Cave et éboulis au nord-ouest.
	r.critere(len(bouche) == 2 and _autour_paroi(plan, bouche, "K") and bouche[0][1] <= 4
		and set(bouche) == set(_cases(plan, "warp_cave")),
		f"bouche nord de la Cave {bouche} : ouverture dans la paroi (K au-dessus et des deux côtés), "
		"au nord de la carte, warp posé dessus")
	eb = plan.cells_of("E") + plan.cells_of("e")
	atteint = carte.avec(arbuste.cells).distances(_cases(plan, "from_cave"))
	r.critere(eb and all(x < 6 and y < 10 for x, y in eb) and not any(c in atteint for c in eb)
		and set(eb) <= set(pos["eboulis_nord"].cells),
		f"arrière des éboulis de la Route 2 nord (E {len(plan.cells_of('E'))} cases, sentier peint "
		f"{len(plan.cells_of('e'))} cases) au nord-ouest, visible, bloqué, inatteignable")

	# 3. Poste, arbuste, partie sud.
	posts = _composantes(set(plan.cells_of("P")) | set(porte))
	xs = [x for c in posts[0] for x in [c[0]]] if posts else []
	ys = [c[1] for c in posts[0]] if posts else []
	ok_poste = (len(posts) == 1 and (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1) == (7, 4)
		and len(porte) == 1 and porte[0] == (min(xs) + 3, max(ys)))
	r.critere(ok_poste, f"poste ({min(xs)}..{max(xs)}, {min(ys)}..{max(ys)}) : 7 × 4 comme les postes "
		f"de la forêt, porte {porte} (4e colonne, rangée du bas), emprise bloquée")
	spawn_cave = _cases(plan, "from_cave")
	d_initial = carte.distances(spawn_cave)
	vers_poste = min((d_initial.get(_d(c, (0, 1)), INF) for c in porte), default=INF)
	r.critere(vers_poste < INF and porte[0] in d_initial,
		f"poste atteignable depuis la bouche nord SANS couper l'arbuste : porte atteinte en "
		f"{d_initial.get(porte[0], INF)} pas")
	objets = _role(plan, "objet_visible")
	r.critere(sorted(objets) == ["O1", "O2"] and objets["O1"].attrs["item"] == "moon_stone"
		and objets["O2"].attrs["item"] == "rare_candy", "objets : O1 Pierre Lune, O2 Super Bonbon (visibles)")
	sud_initial = [a for p in objets.values() for a in _acces(carte, p) if a in d_initial]
	d_coupe = coupe.distances(spawn_cave)
	for k, p in sorted(objets.items()):
		avant = min((d_initial.get(a, INF) for a in _acces(carte, p)), default=INF)
		apres = min((d_coupe.get(a, INF) for a in _acces(coupe, p)), default=INF)
		sol = plan.at(*p.cells[0])
		r.critere(avant >= INF and apres < INF and sol in SOL - {"="},
			f"{k} {p.ident} {p.cells[0]} sur « {sol} » : inatteignable sans l'arbuste, atteint en "
			f"{apres} pas une fois coupé")
	r.critere(not sud_initial and not any(c in d_initial for c in entree),
		"partie sud et bord ouest inatteignables depuis la Cave tant que l'arbuste n'est pas coupé")
	r.critere(all(c in d_coupe for c in entree),
		f"arbuste coupé : bord ouest atteint en {min(d_coupe.get(c, INF) for c in entree)} pas depuis "
		"la Cave (le sentier vers la barrière de FUTUR B est ouvert)")
	cases_arbuste = set(arbuste.cells)
	cou = [y for y in range(plan.height) if any(plan.at(x, y) == "A" for x in range(plan.width))]
	largeur = sorted(x for x in range(plan.width) if coupe.libre((x, cou[0])))
	r.critere(set(plan.cells_of("A")) == cases_arbuste and len(cou) == 1
		and sorted(x for x in range(plan.width) if carte.libre((x, cou[0] - 1))) == [x for x, _ in sorted(cases_arbuste)],
		f"l'arbuste {sorted(cases_arbuste)} ferme tout le goulet : la rangée y {cou[0] - 1} n'a que "
		f"{len(largeur)} cases praticables, les siennes ; il est en travers du chemin")
	depuis_ouest = carte.distances(entree)
	r.critere(all(any(a in depuis_ouest for a in _acces(carte, p)) for p in objets.values())
		and not any(c in depuis_ouest for c in spawn_cave),
		"depuis le bord ouest, la partie sud est atteignable mais pas la Cave : l'arbuste est le "
		"verrou entre elles (arrivé par l'ouest, on le coupe depuis le sud)")

	# 4. Rien d'autre : herbes, Dresseurs, rencontres.
	r.critere(not plan.cells_of("h") and not plan.of_kind("dresseur") and not plan.of_kind("herbes"),
		"aucune herbe haute, aucun Dresseur, aucune rencontre")
	c = pos["panneau_cave"].cells[0]
	r.critere(plan.at(*c) in SOL - {"="} and (c[0], c[1] + 1) in d_initial
		and abs(c[0] - bouche[0][0]) <= 4 and c[1] - bouche[0][1] <= 3,
		f"panneau T-11 {c} près de la Cave, lu depuis {(c[0], c[1] + 1)}")
	fautes = [f"{p.ident} {c} hors d'atteinte ou sur « {plan.at(*c)} »" for p in plan.of_kind("spawn")
		for c in p.cells if c not in d_coupe or plan.at(*c) not in SOL]
	r.critere(not fautes, "points d'apparition sur du sol atteignable" + (" : " + "; ".join(fautes) if fautes else ""))
	chemin_total = d_coupe.get(entree[0], INF)
	print(f"  bouche → poste {d_initial.get(porte[0], INF)} pas ; bouche → bord ouest (arbuste coupé) "
		f"{chemin_total} pas ; praticables {sum(1 for y in range(plan.height) for x in range(plan.width) if plan.at(x, y) in plan.praticables)} cases")
	return r.ok


def verifier_poste() -> bool:
	r = Rapport()
	plan = _lire("route_2_east_gate")
	pos = plan.positions
	print(f"Grille {_nom(PLANS / 'route_2_east_gate.txt')} : {plan.width} × {plan.height}")
	r.critere((plan.width, plan.height) == TAILLE_POSTE,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE_POSTE[0]} × {TAILLE_POSTE[1]}, comme les "
		"maisons d'Argenta)")
	sortie = plan.cells_of("X")
	carte = Carte(plan, portes=set(sortie))
	entree = _cases(plan, "entree")
	d = carte.distances([(x, y - 1) for x, y in entree])
	r.critere(set(_cases(plan, "sortie")) == set(sortie) and set(sortie) <= {(x, plan.height - 2) for x in range(plan.width)}
		and entree[0] in sortie, f"sortie {sortie} sur la rangée du bas, spawn d'entrée {entree[0]}")
	for ident in ("assistant", "visiteur"):
		p = pos[ident]
		acces = [a for a in _acces(carte, p) if a in d]
		r.critere(p.bloque and acces and p.attrs.get("facing"),
			f"{ident} {p.cells[0]} tourné {p.attrs.get('facing')} : atteignable (par {acces[0] if acces else '—'})")
	a = pos["assistant"].cells[0]
	r.critere((a[0], a[1] + 1) in d and plan.at(a[0], a[1] - 1) == "N",
		"l'assistant est derrière son bureau, face à la porte, parlable de face (au sud)")
	libres = [c for c in plan.cells_of(".") if carte.libre(c)]
	r.critere(all(c in d for c in libres), "toute case de sol est atteignable (aucune case orpheline)")
	return r.ok


# ------------------------------------------------------------------- Retouches de la Route 2 --

def _route_2_retouchee() -> tuple[Plan, set[Case], dict[str, object]]:
	"""Route 2 sud avec les rangées de route_2_j17_retouches.txt ; cases modifiées."""
	base = (PLANS / "route_2.txt").read_text(encoding="utf-8").split("\n")
	ret = (PLANS / "route_2_j17_retouches.txt").read_text(encoding="utf-8").split("\n")
	nouvelles: dict[int, str] = {}
	section = ""
	positions_ret: list[str] = []
	supprime: set[str] = set()
	for ligne in ret:
		mots = ligne.split("#", 1)[0].split()
		if not mots:
			continue
		if mots[0] in ("GRILLE_RETOUCHEE", "POSITIONS_RETOUCHEES", "SUPPRIME"):
			section = mots[0]
			continue
		if mots[0] == "FIN":
			section = ""
			continue
		if section == "GRILLE_RETOUCHEE":
			nouvelles[int(mots[0])] = mots[1]
		elif section == "POSITIONS_RETOUCHEES":
			positions_ret.append(ligne)
		elif section == "SUPPRIME":
			supprime.add(mots[0])
	sortie, dans_grille = [], False
	for ligne in base:
		m = re.match(r"^(\d\d) (\S{42})$", ligne)
		if m and int(m[1]) in nouvelles:
			ligne = f"{m[1]} {nouvelles[int(m[1])]}"
		mots = ligne.split("#", 1)[0].split()
		if mots and mots[0] in supprime:
			continue
		if ligne.strip() == "FIN" and dans_grille is True:
			pass
		if mots and mots[0] == "POSITIONS":
			sortie.append(ligne)
			sortie += positions_ret
			continue
		if mots and mots[0] == "GRILLE":
			dans_grille = True
		sortie.append(ligne)
	avant = lire(PLANS / "route_2.txt")
	with tempfile.TemporaryDirectory() as tmp:
		f = Path(tmp) / "route_2_retouchee.txt"
		f.write_text("\n".join(sortie), encoding="utf-8")
		apres = lire(f)
	modifiees = {(x, y) for y in range(avant.height) for x in range(avant.width)
		if avant.at(x, y) != apres.at(x, y)}
	return apres, modifiees, avant


def verifier_retouches_route_2() -> bool:
	r = Rapport()
	apres, modifiees, avant = _route_2_retouchee()
	print(f"Retouches {_nom(PLANS / 'route_2_j17_retouches.txt')} sur route_2.txt "
		f"({apres.width} × {apres.height}, route_2.txt inchangé)")
	zone_claire = {(x, y) for x in range(0, 4) for y in range(16, 23)}
	clairiere = {c for c in zone_claire if apres.at(*c) == "."}   # (3, 16) reste forêt
	sentier = {(x, y) for x in range(35, 42) for y in (43, 44)}
	r.critere(modifiees <= zone_claire | sentier,
		f"{len(modifiees)} cases modifiées, toutes dans la clairière (0..3, 16..22) ou le sentier "
		"(35..41, 43..44)")
	r.critere(all(avant.at(*c) in "aT" for c in modifiees & clairiere) and apres.at(3, 16) == "T"
		and all(avant.at(*c) == "b" and apres.at(*c) == "=" for c in modifiees & sentier)
		and len(modifiees & sentier) == len(sentier),
		f"clairière : {len(modifiees & clairiere)} cases (sentier peint « a » et forêt → herbe) ; "
		f"sentier « b » : {len(modifiees & sentier)} cases → chemin de terre")
	arbuste = apres.positions["arbuste_futur_a"]
	r.critere(arbuste.cells == [(4, 19)] and apres.at(4, 19) == "A"
		and "examen_arbre_dense" not in apres.positions,
		"l'arbuste coupable (4, 19) remplace l'arbre dense (case « A », bloquée jusqu'au drapeau)")
	barriere = [(34, 43), (34, 44)]
	r.critere(all(apres.at(*c) == "B" for c in barriere),
		f"la barrière {barriere} reste « B » (bloquée) dans la grille")

	entree_sud = [(x, apres.height - 1) for x in (19, 20, 21)]
	carte = Carte(apres, portes=set())
	ret_arbuste = carte.avec(arbuste.cells)
	# FUTUR A.
	d0 = carte.distances(entree_sud)
	d1 = ret_arbuste.distances(entree_sud)
	obj = apres.positions["route_2_item_5"].cells[0]
	acces = [_d(obj, d) for d in DIRECTIONS if ret_arbuste.libre(_d(obj, d))]
	r.critere(not (clairiere & set(d0)) and (clairiere - {obj}) <= set(d1)
		and any(a in d1 for a in acces) and not any(a in d0 for a in acces),
		f"clairière FUTUR A : inatteignable avec l'arbuste (4, 19), atteignable une fois coupé "
		f"({len(clairiere & set(d1))}/{len(clairiere)} cases) ; Super Potion {obj} atteinte en "
		f"{min(d1.get(a, INF) for a in acces)} pas")
	r.critere(obj[0] <= 3 and apres.at(*obj) == "." and obj[1] != 19,
		f"objet de la clairière {obj} hors de la ligne de l'arbuste (rangée 19), au fond")
	# La porte du poste sud reste atteignable sans rien couper (Route 2 d'origine inchangée).
	porte = apres.cells_of("D")[0]
	r.critere(porte in d0, f"porte du poste sud toujours atteignable sans rien couper ({d0.get(porte)} pas)")
	# FUTUR B.
	est = [(41, 43), (41, 44)]
	r.critere(all(apres.at(*c) == "=" for c in est) and apres.width - 1 == 41,
		f"le sentier atteint le bord est {est} (raccord de route_2_east, mêmes rangées)")
	est_a = Carte(apres).distances(est)
	cote_est = {(x, y) for x in range(35, 42) for y in (43, 44)}
	r.critere(cote_est <= set(est_a) and not any(c in est_a for c in [(33, 43), (33, 44)]),
		"depuis le bord est, tout le sentier (35..41) est atteignable, jusqu'à la barrière seulement "
		"(la barrière ferme)")
	d_sud = Carte(apres).distances(entree_sud)
	r.critere(not any(c in d_sud for c in est),
		"depuis Jadielle, le sentier n'est PAS atteignable tant que la barrière est fermée")
	ouvert = Carte(apres, liberees=set(barriere))
	d_o = ouvert.distances(entree_sud)
	d_oe = ouvert.distances(est)
	r.critere(all(c in d_o for c in est) and any(c in d_oe for c in entree_sud),
		f"barrière ouverte : Jadielle ↔ bord est reliés (Jadielle → (41, 43) en "
		f"{min(d_o.get(c, INF) for c in est)} pas, définitivement, dans les deux sens)")
	return r.ok


# ---------------------------------------------------------------------------- Chaîne complète --

def verifier_chaine() -> bool:
	"""Carmin → Route 11 → Cave → Route 2 est : raccords bout à bout."""
	r = Rapport()
	r11 = _lire("route_11")
	cave = _lire("digletts_cave")
	r2e = _lire("route_2_east")
	c11 = Carte(r11, portes=set(r11.cells_of("Q")))
	cc = Carte(cave, portes=set(cave.cells_of("E")))
	ce = Carte(r2e, portes=set(r2e.cells_of("Q")) | set(r2e.cells_of("D")))
	cce = ce.avec(r2e.positions["arbuste"].cells)
	a = _dist(c11, [(0, y) for y in _rangees_carmin()], r11.cells_of("Q"))
	b = _dist(cc, _cases(cave, "from_route_11"), [c for c in cave.cells_of("E") if c[1] == 0])
	c = _dist(ce, _cases(r2e, "from_cave"), [_d(p, (0, 1)) for p in r2e.cells_of("D")])
	d = _dist(cce, _cases(r2e, "from_cave"), [(0, 43), (0, 44)])
	print("\nChaîne Carmin → Cave → Route 2 est")
	r.critere(max(a, b, c, d) < INF,
		f"Carmin → bouche de la Cave (Route 11) {a} pas ; Cave {b} pas ; bouche nord → poste {c} pas "
		f"(sans Coupe) ; bouche nord → bord ouest {d} pas (avec Coupe) ; total jusqu'au poste "
		f"{a + b + c} pas ({(a + b + c) * S_PAR_PAS + S_COMBAT_2:.0f} s avec Arthur)")
	return r.ok


def main() -> int:
	ok = True
	for fonction in (verifier_route_11, verifier_cave, verifier_route_2_est, verifier_poste,
			verifier_retouches_route_2, verifier_chaine):
		print()
		ok &= bool(fonction())
	print("\nPlans conformes." if ok else "\nPlans NON conformes.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
