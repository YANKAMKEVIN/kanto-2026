#!/usr/bin/env python3
"""Vérifie les grilles du jalon 15 : Route 6 et Carmin-sur-Mer (dossier 18 §2, §6, §7, §8, §11).

Grilles : `tools/plans/route_6.txt`, `vermilion_city.txt`. Lecture par `plan_grille.lire` ;
déplacements de `plan_check.Monde` (4 directions, un pas par case), avec des **portes terminales**
(`D`, et `E` l'accès au S.S. Anne : on y entre, on ne les traverse pas). Les positions `bloque`
(Dresseurs, PNJ, Pokémon d'ambiance, objets visibles, panneaux, case cachée) bloquent leurs cases.

Critères :
  Route 6 — 42 × 56 ; raccord sud de 3 cases = entrée nord de Carmin (− 5 colonnes) ; carte
    fermée ailleurs ; bâtiment de sortie du souterrain et poste de garde 7 × 3 (porte au milieu de
    la rangée du bas) ; poste FERMÉ (porte inatteignable : le garde occupe la case devant) ;
    D1 inévitable (aucun chemin vers Carmin hors de sa vue, première case vue à ≥ 3 cases) ;
    D2 à D6 évitables, un à un et ensemble (règle « aucun combat inévitable contournable ») ;
    étang d'un seul tenant, non praticable, pêcheur au bord ; objets (1 visible, 1 caché avec
    indice) atteignables hors des lignes de vue ; chemins d'au moins 2 cases de large ; l'approche
    d'un Dresseur ne ferme aucun passage ; PNJ, panneaux, repères bien placés.
  Carmin — ≤ 64 × 48 ; raccord nord (3 cases) et est (3 cases, « À venir »), carte fermée ailleurs ;
    emprises des bâtiments (Centre et Boutique 8 × 7, Arène 12 × 7, Fan Club 8 × 6, maisons 7 × 6) ;
    portes atteignables depuis l'entrée nord, sauf l'Arène (arbre) qui l'est sans l'arbre ; Centre
    dans le cadre de la caméra à l'arrivée ; coque du S.S. Anne rectangulaire et parallèle au quai,
    passerelle perpendiculaire gardée (inatteignable avec le marin, atteignable sans lui) ; pontons
    rectilignes perpendiculaires au rivage ; quai et rues d'au moins 2 cases ; PNJ bien placés.

Usage : python3 tools/art/plan_check_carmin.py [route_6|vermilion_city]   (code 1 si un critère
        échoue ; sans argument, les deux grilles)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import PORTE, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]

## Décalage entre les deux cartes : Carmin x = Route 6 x + RACCORD_DX.
RACCORD_DX = 5
TAILLE_ROUTE_6 = (42, 56)
TAILLE_MAX_CARMIN = (64, 48)
## Vue de jeu sur le S24 (2340 × 1080 affichés, référence 1920 × 1080 en « expand ») en cases.
VUE_S24 = (2340 / 96, 1080 / 96)
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases (≥ 2 libres entre eux)
DRESSEURS = {"D1": 5, "D2": 4, "D3": 4, "D4": 4, "D5": 4, "D6": 4}
INEVITABLES = ("D1",)              # F-11 : 1 inévitable au plus
SOL_ROUTE = set(".")               # sol où poser PNJ, Pokémon, objets et panneaux de la Route 6
S_PAR_PAS = 0.72                   # pas mesuré sur S21 (T22 du J9)
S_COMBAT_2 = 120
S_COMBAT_1 = 70
S_SAUVAGE = 50
TAUX = 25 / 256

## Emprises : caractère → (largeur, hauteur, colonnes de la porte dans la rangée du bas).
EMPRISES_ROUTE_6 = {"U": (7, 3, (3,)), "P": (7, 3, (3,))}
EMPRISES_CARMIN = {
	"C": (8, 7, (3, 4)),     # bldg_centre_01 réutilisé
	"O": (8, 7, (3, 4)),     # bldg_boutique_01 réutilisé
	"Z": (12, 7, (5, 6)),    # Arène de Major Bob (neuve, même gabarit que celle d'Argenta)
	"F": (8, 6, (3, 4)),     # Fan Club (neuf)
	"m": (7, 6, (3,)),       # maison (neuve ; trois exemplaires)
}


class Carte(Monde):
	"""`plan_check.Monde` avec portes terminales : D et E (accès au navire)."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset(),
			libres: str = "") -> None:
		super().__init__(plan, bloquees)
		self.extra = set(libres)
		self.portes = set(plan.cells_of(PORTE)) | set(plan.cells_of("E"))

	def libre(self, c: Case) -> bool:
		x, y = c
		if not (0 <= x < self.plan.width and 0 <= y < self.plan.height):
			return False
		return c not in self.bloquees and (
			self.plan.at(x, y) in self.plan.praticables or self.plan.at(x, y) in self.extra)

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Carte":
		return Carte(self.plan, self.bloquees | set(cases), "".join(self.extra))

	def avec(self, cases, libres: str = "") -> "Carte":
		"""Même carte sans les obstacles [cases] (PNJ retiré) et avec [libres] praticables."""
		c = Carte(self.plan, self.bloquees, "".join(self.extra) + libres)
		c.bloquees -= set(cases)
		return c


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def critere(self, vrai: bool, texte: str) -> None:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	def info(self, texte: str) -> None:
		print(f"  {texte}")


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
	return sorted(groupes, key=lambda g: (min(y for _, y in g), min(x for x, _ in g)))


def _bb(cases) -> tuple[int, int, int, int]:
	xs = [x for x, _ in cases]
	ys = [y for _, y in cases]
	return min(xs), min(ys), max(xs), max(ys)


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _acces(carte: Carte, p) -> list[Case]:
	"""Cases d'où l'on prend / examine / parle à p : les voisines libres de ses cases."""
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if carte.libre(_decale(c, d)) and _decale(c, d) not in carte.portes]


def _bord(plan: Plan, carte: Carte, cote: str) -> list[Case]:
	if cote == "haut":
		return [(x, 0) for x in range(plan.width) if carte.libre((x, 0))]
	if cote == "bas":
		return [(x, plan.height - 1) for x in range(plan.width) if carte.libre((x, plan.height - 1))]
	if cote == "est":
		return [(plan.width - 1, y) for y in range(plan.height) if carte.libre((plan.width - 1, y))]
	return [(0, y) for y in range(plan.height) if carte.libre((0, y))]


def _bords_libres(plan: Plan, carte: Carte) -> list[Case]:
	return [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and carte.libre((x, y))]


def _chemin(carte: Carte, depart: Case, cible: Case) -> list[Case]:
	"""Plus court chemin (liste de cases) de depart à cible, [] s'il n'existe pas."""
	pere: dict[Case, Case | None] = {depart: None}
	file = [depart]
	for c in file:
		if c == cible:
			break
		for n in carte.voisins(c):
			if n not in pere:
				pere[n] = c
				file.append(n)
	if cible not in pere:
		return []
	chemin, c = [], cible
	while c is not None:
		chemin.append(c)
		c = pere[c]
	return chemin[::-1]


def _largeur(carte: Carte, chemin: list[Case]) -> list[Case]:
	"""Cases du chemin sans voisine libre perpendiculaire au sens de marche (hors dernier pas
	vers une porte) : un chemin d'au moins 2 cases (compagnon du J11)."""
	etroites = []
	for a, b in zip(chemin, chemin[1:]):
		if b in carte.portes:
			continue
		d = (b[0] - a[0], b[1] - a[1])
		perp = [(-d[1], d[0]), (d[1], -d[0])]
		if not any(carte.libre(_decale(b, p)) and _decale(b, p) not in carte.portes
				for p in perp):
			etroites.append(b)
	return etroites


def _emprises(r: Rapport, plan: Plan, table: dict[str, tuple[int, int, tuple[int, ...]]]) \
		-> dict[str, list[set[Case]]]:
	trouvees: dict[str, list[set[Case]]] = {}
	portes = set(plan.cells_of(PORTE))
	for car, (largeur, hauteur, colonnes) in table.items():
		trouvees[car] = []
		for groupe in _composantes(set(plan.cells_of(car))):
			x0, y0, x1, y1 = _bb(groupe)
			attendues = {(x0 + i, y1) for i in colonnes}
			bloc = groupe | attendues
			bx0, by0, bx1, by1 = _bb(bloc)
			taille = (bx1 - bx0 + 1, by1 - by0 + 1)
			plein = len(bloc) == taille[0] * taille[1]
			ses_portes = {c for c in portes if bx0 <= c[0] <= bx1 and by0 <= c[1] <= by1}
			r.critere(taille == (largeur, hauteur) and plein and ses_portes == attendues,
				f"« {car} » ({bx0}..{bx1}, {by0}..{by1}) : {taille[0]} × {taille[1]} (attendu "
				f"{largeur} × {hauteur}), porte {sorted(ses_portes)} (colonnes {list(colonnes)} "
				"de la rangée du bas)")
			trouvees[car].append(bloc)
	return trouvees


def _positions(r: Rapport, plan: Plan, carte: Carte, dist: dict[Case, int], sol: set[str],
		lignes: set[Case], exemptes: tuple[str, ...] = ()) -> None:
	"""PNJ, Pokémon, objets, panneaux et repères sur `sol`, hors des lignes de vue ; tout PNJ,
	Pokémon, panneau, objet et point d'examen a une case voisine atteignable ; spawns et
	déclencheurs atteignables."""
	fautes = []
	devant_portes = {(x, y + 1) for x, y in plan.cells_of(PORTE)}
	panneaux = {c for p in plan.of_kind("panneau") for c in p.cells}
	for p in plan.positions.values():
		if p.ident in exemptes:
			continue
		for c in p.cells:
			car = plan.at(*c)
			if p.kind in ("pnj", "pokemon", "objet_visible", "cache", "panneau") and car not in sol:
				fautes.append(f"{p.ident} sur « {car} » en {c}")
			if p.kind in ("pnj", "pokemon", "panneau") and c in lignes:
				fautes.append(f"{p.ident} {c} sur une ligne de vue")
			if p.kind in ("pnj", "pokemon") and (c in devant_portes or c in panneaux):
				fautes.append(f"{p.ident} {c} devant une porte ou sur un panneau")
			if p.kind == "pnj" and "facing" not in p.attrs:
				fautes.append(f"{p.ident} sans facing")
		if p.kind in ("pnj", "pokemon", "objet_visible", "cache", "panneau", "examen"):
			if not any(a in dist for a in _acces(carte, p)):
				fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
		if p.kind in ("spawn", "declencheur") and not all(c in dist for c in p.cells):
			fautes.append(f"{p.ident} {p.cells[0]} hors d'atteinte")
	r.critere(not fautes, "PNJ, Pokémon, objets, panneaux et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))


def _approche(r: Rapport, plan: Plan, carte: Carte, dist: dict[Case, int],
		dresseurs: dict, vues: dict, cibles: list[list[Case]]) -> None:
	"""Un Dresseur qui s'approche (s'arrête sur la case voisine du joueur vu) ne ferme pas de
	passage (jalon 9 §6.9)."""
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in dist:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = carte.avec(p.cells)
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	r.critere(not fermes, "l'approche d'un Dresseur ne ferme aucun passage"
		+ (f" : {fermes[:3]}" if fermes else ""))


# --- Route 6 ----------------------------------------------------------------------------

def route_6(r: Rapport, plan: Plan, carmin: Plan) -> None:
	print(f"\nRoute 6 ({plan.width} × {plan.height})")
	carte = Carte(plan)
	pos = plan.positions
	r.critere((plan.width, plan.height) == TAILLE_ROUTE_6,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE_ROUTE_6[0]} × {TAILLE_ROUTE_6[1]})")

	# 1. Raccord sud sur Carmin, carte fermée ailleurs.
	sud = _bord(plan, carte, "bas")
	nord_carmin = _bord(carmin, Carte(carmin), "haut")
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == plan.height - 1)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[1] == plan.height - 1)
	r.critere(len(sud) == 3 and sud == warps == spawns
		and [(x + RACCORD_DX, 0) for x, _ in sud] == nord_carmin,
		f"raccord sud {[x for x, _ in sud]} = warps = spawns = entrée nord de Carmin "
		f"{[x for x, _ in nord_carmin]} − {RACCORD_DX}")
	r.critere(sorted(_bords_libres(plan, carte)) == sud, "carte fermée : seul le raccord sud "
		"touche le bord (le nord est le bâtiment de sortie du souterrain)")

	# 2. Bâtiments : sortie du souterrain, poste de garde.
	portes = set(plan.cells_of(PORTE))
	batiments = _emprises(r, plan, EMPRISES_ROUTE_6)
	bat_u, bat_p = batiments["U"][0], batiments["P"][0]
	porte_u = pos["warp_souterrain"].cells[0]
	porte_p = pos["porte_safrania"].cells[0]
	arrivee = pos["from_souterrain"].cells[0]
	garde = pos["garde_safrania"].cells[0]
	r.critere({porte_u, porte_p} == portes and porte_u in bat_u and porte_p in bat_p
		and arrivee == (porte_u[0], porte_u[1] + 1) and garde == (porte_p[0], porte_p[1] + 1),
		f"porte du souterrain {porte_u} (arrivée {arrivee} devant), porte du poste {porte_p} "
		f"(garde {garde} devant)")
	dist = carte.distances([arrivee])
	r.critere(porte_u in dist and arrivee in dist,
		f"retour dans le souterrain possible : porte à {dist.get(porte_u, INF)} pas de l'arrivée")
	libre_garde = carte.avec([garde])
	r.critere(porte_p not in dist and porte_p in libre_garde.distances([arrivee])
		and garde in dist or any(a in dist for a in _acces(carte, pos["garde_safrania"])),
		"poste vers Safrania FERMÉ : porte inatteignable avec le garde, atteignable s'il se "
		"décale (déblocage futur) ; le garde est atteignable")
	verrou = pos["verrou_safrania"].cells
	r.critere(all(c in dist for c in verrou) and garde not in verrou
		and all(abs(c[0] - garde[0]) <= 1 and 0 <= c[1] - garde[1] <= 1 for c in verrou),
		f"zone de déclenchement du garde {len(verrou)} cases autour de lui, atteignable")

	# 3. Chemin principal.
	aller = min(dist.get(c, INF) for c in sud)
	r.critere(aller < INF, f"souterrain → Carmin : {aller} pas")
	if aller >= INF:
		return
	principal = _chemin(carte, arrivee, min(sud, key=lambda c: dist.get(c, INF)))
	etroites = _largeur(carte, principal)
	r.critere(not etroites, "chemin principal d'au moins 2 cases de large"
		+ (f" — étroit en {etroites[:4]}" if etroites else ""))

	# 4. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	r.critere(sorted(dresseurs) == sorted(DRESSEURS), f"6 Dresseurs D1..D6 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(DRESSEURS):
		return
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vue = ligne_de_vue(carte, p)
		vues[role] = vue
		vision = int(p.attrs.get("sight", "0"))
		r.critere(vision == DRESSEURS[role] and len(vue) == vision
			and plan.at(*p.cells[0]) in SOL_ROUTE,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs.get('facing')} : vision {len(vue)}/"
			f"{vision} cases dégagées ({''.join(plan.at(*c) for c in vue)})")
	for role in INEVITABLES:
		bloque = set(vues[role])
		sans = min(carte.sans(bloque).distances([arrivee]).get(c, INF) for c in sud)
		premiere = premiere_detection(carte, [arrivee], vues[role])
		r.critere(sans >= INF and premiere >= DETECTION_MIN,
			f"{role} {dresseurs[role].ident} inévitable (Carmin : "
			f"{'fermé' if sans >= INF else sans}) ; première case vue à {premiere} cases "
			f"(attendu ≥ {DETECTION_MIN})")
	evitables = [k for k in DRESSEURS if k not in INEVITABLES]
	# Hors de la vue de D1 (elle coupe le goulet) : la règle porte sur chacun des autres.
	for role in evitables:
		d = min(carte.sans(vues[role]).distances([arrivee]).get(c, INF) for c in sud)
		r.critere(d < INF, f"{role} {dresseurs[role].ident} évitable : Carmin en {d} pas hors de "
			f"sa vue (+{d - aller if d < INF else '∞'} pas)")
	tous = set().union(*(vues[k] for k in evitables))
	d_tous = min(carte.sans(tous).distances([arrivee]).get(c, INF) for c in sud)
	r.critere(d_tous < INF, f"D2 à D6 évitables ensemble : Carmin en {d_tous} pas "
		"(un seul combat inévitable, D1)")
	# Aucune vue d'un évitable ne coupe toute la largeur du chemin principal.
	sur_principal = [k for k in evitables if set(vues[k]) & set(principal)]
	r.info(f"Dresseurs évitables dont la vue touche le chemin principal : {sur_principal} "
		"(le joueur peut les dépasser par la case libre voisine)")
	d1 = dresseurs["D1"].cells[0]
	d2 = dresseurs["D2"].cells[0]
	d4, d5 = dresseurs["D4"].cells[0], dresseurs["D5"].cells[0]
	r.critere(d2[1] == d1[1] and abs(d2[0] - d1[0]) <= 3 and d4[0] == d5[0]
		and abs(d4[1] - d5[1]) <= 3,
		f"voisinages du §6.2 : Lucas {d2} à côté de Chloé {d1} ; Mathis {d4} et Manon {d5}")
	d6 = dresseurs["D6"].cells[0]
	vue_port = pos["vue_port"].cells[0]
	r.critere(vue_port in dist and abs(vue_port[0] - d6[0]) <= 2 and abs(vue_port[1] - d6[1]) <= 4,
		f"D6 {d6} garde le belvédère (vue sur le port {vue_port}, atteint en {dist.get(vue_port, INF)} pas)")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}

	# 5. Étang.
	eau = set(plan.cells_of("W"))
	r.critere(len(_composantes(eau)) == 1 and len(eau) >= 50 and not eau & set(dist),
		f"étang d'un seul tenant, {len(eau)} cases, non praticable (obstacle)")
	pecheur = pos["pecheur"]
	r.critere(any(_decale(pecheur.cells[0], d) in eau for d in DIRECTIONS)
		and any(a in dist for a in _acces(carte, pecheur)),
		f"pêcheur {pecheur.cells[0]} au bord de l'étang, atteignable")

	# 6. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	r.critere(sorted(objets) == ["O1", "O2"] and objets["O1"].kind == "objet_visible"
		and objets["O2"].kind == "cache" and "indice" in objets["O2"].attrs,
		"2 objets : O1 visible (Poké Ball), O2 caché (Super Potion, avec indice EXAMINER)")
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((dist.get(a, INF) for a in _acces(carte, p)), default=INF)
		bon = atteint < INF and plan.at(*c) in SOL_ROUTE and c not in lignes and p.bloque
		r.critere(bon, f"{role} {p.ident} {c} ({p.attrs.get('item')}) : atteint en {atteint} pas, "
			"hors des lignes de vue, hors des hautes herbes et du chemin")

	# 7. Hautes herbes : toutes évitables (route ouverte).
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ("H1", "H2", "H3", "H4"))
	r.critere(len(zones) == 4 and sorted(nommees) == ["H1", "H2", "H3", "H4"],
		f"4 zones de hautes herbes : {', '.join(f'{n} {boite(z)}' for n, z in sorted(nommees.items()))}")
	toutes = set().union(*zones) if zones else set()
	obligatoires = min(carte.herbes_min([arrivee], lambda c: c in toutes).get(c, INF) for c in sud)
	r.critere(obligatoires == 0 and aller == min(carte.sans(toutes).distances([arrivee]).get(c, INF)
		for c in sud), f"hautes herbes évitables sans détour (cases obligatoires : {obligatoires})")

	# 8. Approche des Dresseurs, positions.
	cibles = [list(sud), [arrivee]] + [_acces(carte, p) for p in objets.values()]
	_approche(r, plan, carte, dist, dresseurs, vues, cibles)
	tout = carte.distances([arrivee] + sud)
	_positions(r, plan, carte, tout, SOL_ROUTE, lignes, ("garde_safrania",))

	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	rencontres = obligatoires * TAUX
	duree = aller * S_PAR_PAS + S_COMBAT_1 * 1 + rencontres * S_SAUVAGE
	r.info(f"statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes")
	r.info(f"traversée directe estimée : {aller} pas × {S_PAR_PAS} s + Chloé {S_COMBAT_1} s = "
		f"{duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s) ; marche seule "
		f"{aller * S_PAR_PAS:.0f} s")


# --- Carmin-sur-Mer ---------------------------------------------------------------------

def carmin(r: Rapport, plan: Plan, route: Plan) -> None:
	print(f"\nCarmin-sur-Mer ({plan.width} × {plan.height})")
	carte = Carte(plan)
	pos = plan.positions
	r.critere(plan.width <= TAILLE_MAX_CARMIN[0] and plan.height <= TAILLE_MAX_CARMIN[1],
		f"taille {plan.width} × {plan.height} ≤ {TAILLE_MAX_CARMIN[0]} × {TAILLE_MAX_CARMIN[1]} "
		"(le quai du S.S. Anne reste dans la carte)")

	# 1. Raccords.
	nord = _bord(plan, carte, "haut")
	est = _bord(plan, carte, "est")
	sud_route = _bord(route, Carte(route), "bas")
	warps_n = sorted(c for c in pos["warp_nord"].cells)
	spawns_n = sorted(c for c in pos["from_route_6"].cells)
	r.critere(len(nord) == 3 and nord == warps_n == spawns_n
		and nord == [(x + RACCORD_DX, 0) for x, _ in sud_route],
		f"raccord nord {[x for x, _ in nord]} = warps = spawns = sortie sud de la Route 6 "
		f"{[x for x, _ in sud_route]} + {RACCORD_DX}")
	r.critere(len(est) == 3 and est == sorted(pos["warp_est"].cells) == sorted(pos["from_route_11"].cells),
		f"raccord est {[y for _, y in est]} (x {plan.width - 1}) = warp « ROUTE 11 — À venir »")
	r.critere(sorted(_bords_libres(plan, carte)) == sorted(nord + est),
		"carte fermée : seuls le raccord nord et le raccord est touchent le bord (sud = mer)")

	# 2. Bâtiments et portes.
	batiments = _emprises(r, plan, EMPRISES_CARMIN)
	portes = set(plan.cells_of(PORTE))
	warps_portes = {c for p in plan.of_kind("warp") if p.ident.startswith("porte_") for c in p.cells}
	r.critere(warps_portes == portes and len(portes) == 11,
		f"positions porte_* = cases D ({len(portes)} cases : Centre, Boutique, Arène, Fan Club, "
		"Pêcheur, 2 maisons)")
	arbre = set(plan.cells_of("A"))
	porte_arene = set(pos["porte_arene"].cells)
	dist = carte.distances(nord)
	bloquees = []
	for p in plan.of_kind("warp"):
		if not p.ident.startswith("porte_"):
			continue
		devant = [(x, y + 1) for x, y in p.cells]
		atteinte = all(c in dist for c in p.cells) and all(c in dist for c in devant)
		if p.ident == "porte_arene":
			continue
		if not atteinte:
			bloquees.append(p.ident)
		r.info(f"{p.ident:16} {p.cells[0]} : {min(dist.get(c, INF) for c in p.cells)} pas de l'entrée")
	r.critere(not bloquees, "toutes les portes atteignables depuis l'entrée nord (STEP_ON ↑ depuis "
		"la case du dessous)" + (f" — manquantes : {bloquees}" if bloquees else ""))
	sans_arbre = carte.avec([], "A")
	d_sans = sans_arbre.distances(nord)
	r.critere(not any(c in dist for c in porte_arene) and all(c in d_sans for c in porte_arene)
		and arbre == set(pos["examen_arbre"].cells) and len(arbre) == 2,
		f"Arène : porte {sorted(porte_arene)} INATTEIGNABLE tant que le jeune arbre {sorted(arbre)} "
		f"tient, atteignable sans lui ({min(d_sans.get(c, INF) for c in porte_arene)} pas) ; "
		"EXAMINER depuis la rue")

	# 3. Le Centre dans le cadre de la caméra à l'arrivée (caméra bornée à la carte).
	vw, vh = VUE_S24
	for car, nom in (("C", "Centre"), ("O", "Boutique")):
		x0, y0, x1, y1 = _bb(batiments[car][0])
		parts = []
		for x, y in nord:
			cx = min(max(x + 0.5, vw / 2), plan.width - vw / 2)
			cy = min(max(y + 0.5, vh / 2), plan.height - vh / 2)
			gx0, gy0, gx1, gy1 = cx - vw / 2, cy - vh / 2, cx + vw / 2, cy + vh / 2
			lx = max(0.0, min(gx1, x1 + 1) - max(gx0, x0))
			ly = max(0.0, min(gy1, y1 + 1) - max(gy0, y0))
			parts.append(lx * ly / ((x1 - x0 + 1) * (y1 - y0 + 1)))
		r.critere(min(parts) >= 0.999,
			f"{nom} ({x0}..{x1}, {y0}..{y1}) entièrement dans le cadre à l'arrivée "
			f"({vw:.1f} × {vh:.2f} cases) : {min(parts):.0%}")

	# 4. S.S. Anne, quai, passerelle, pontons.
	coque = set(plan.cells_of("N")) | set(plan.cells_of("E"))
	cx0, cy0, cx1, cy1 = _bb(coque)
	quai = {c for c in plan.cells_of("q")}
	# La nappe de planches au nord de la coque (caisses et bittes comprises, posées dessus).
	quai_haut = {c for c in quai | set(plan.cells_of("k")) | set(plan.cells_of("z"))
		if c[1] < cy0 - 1}
	qx0, qy0, qx1, qy1 = _bb(quai_haut)
	largeur_c, hauteur_c = cx1 - cx0 + 1, cy1 - cy0 + 1
	r.critere(len(coque) == largeur_c * hauteur_c and largeur_c > hauteur_c
		and qx0 <= cx0 and cx1 <= qx1 and cy0 > qy1
		and (qx1 - qx0 + 1) * (qy1 - qy0 + 1) == len(quai_haut),
		f"S.S. Anne : grand rectangle bloqué {largeur_c} × {hauteur_c} ({cx0}..{cx1}, {cy0}..{cy1}), "
		f"coque PARALLÈLE au quai ({qx0}..{qx1}, {qy0}..{qy1}), dans sa longueur")
	passerelle = sorted(plan.cells_of("g"))
	acces = sorted(plan.cells_of("E"))
	marin, cordage = pos["marin"].cells[0], pos["cordage_passerelle"].cells[0]
	gx0, gy0, gx1, gy1 = _bb(passerelle)
	r.critere(passerelle == [(x, gy0) for x in range(gx0, gx1 + 1)] and gx1 - gx0 + 1 == 2
		and acces == [(x, gy0 + 1) for x in range(gx0, gx1 + 1)] and all(c in coque or c in acces
			for c in [(gx0, gy0 + 1)]) and gy0 == qy1 + 1
		and sorted([marin, cordage]) == [(gx0, qy1), (gx1, qy1)] and plan.at(*cordage) == "z"
		and sorted(c for c in pos["embarquement"].cells) == acces,
		f"passerelle {passerelle[0]}…{passerelle[-1]} perpendiculaire au quai, accès au navire "
		f"{acces[0]}…{acces[-1]}, gardée par le marin {marin} et le cordage {cordage}")
	r.critere(not any(c in dist for c in passerelle + acces), "avec le marin : passerelle et "
		"navire INATTEIGNABLES (réplique provisoire du J15, identique avec ou sans Passe Bateau)")
	sans_marin = carte.avec([marin, cordage], "z")
	d_sm = sans_marin.distances(nord)
	r.critere(all(c in d_sm for c in passerelle + acces), "sans le marin (J16) : passerelle et accès "
		f"au navire atteignables en {min(d_sm.get(c, INF) for c in acces)} pas")
	pontons = _composantes(quai - quai_haut)
	pontons = [p | {c for c in plan.cells_of("z") if c not in quai_haut
		and any(_decale(c, d) in p for d in DIRECTIONS)} for p in pontons]
	bons = []
	for p in pontons:
		x0, y0, x1, y1 = _bb(p)
		bons.append((x1 - x0 + 1 == 2 and y1 - y0 + 1 >= 5 and y0 == qy1 + 1
			and len(p) == 2 * (y1 - y0 + 1) and any((x, y0 - 1) in quai_haut for x, _ in p)
			and not p & coque))
	r.critere(len(pontons) == 2 and all(bons),
		f"2 pontons rectilignes de 2 cases, perpendiculaires au rivage : "
		f"{[ _bb(p) for p in pontons]}")
	r.critere(all(c in dist for p in pontons for c in p if plan.at(*c) == "q"),
		"pontons atteignables depuis le quai")
	# Largeur du quai : au moins 2 cases libres (hors PNJ) dans chaque colonne de la nappe.
	etroits = []
	for x in range(qx0, qx1 + 1):
		libres = [y for y in range(qy0, qy1 + 1) if carte.libre((x, y))
			and (x, y) not in {c for p in plan.positions.values() if p.kind != "pnj" and p.bloque
				for c in p.cells}]
		if len(libres) < 2:
			etroits.append(x)
	r.critere(not etroits, "quai d'au moins 2 cases de large partout (hors PNJ)"
		+ (f" — étroit en x {etroits}" if etroits else ""))

	# 5. Angles droits : emprises rectangulaires pour chaque objet à contour fixe.
	autres = []
	for car in "Akgz":
		for groupe in _composantes(set(plan.cells_of(car))):
			x0, y0, x1, y1 = _bb(groupe)
			if len(groupe) != (x1 - x0 + 1) * (y1 - y0 + 1):
				autres.append(f"« {car} » {x0}..{x1}, {y0}..{y1}")
	r.critere(not autres, "angles droits : coque, arbre, passerelle, caisses et bittes en "
		"rectangles" + (f" — non rectangulaires : {autres}" if autres else ""))

	# 6. Largeur des rues vers chaque porte, vers la passerelle et vers l'est.
	etroites: list[str] = []
	cibles = {p.ident: min(p.cells, key=lambda c: dist.get(c, INF)) for p in plan.of_kind("warp")
		if p.ident.startswith("porte_") and p.ident != "porte_arene"}
	cibles["est"] = min(est, key=lambda c: dist.get(c, INF))
	cibles["passerelle"] = passerelle[0]
	for nom, cible in cibles.items():
		chemin = _chemin(sans_marin if nom == "passerelle" else carte, nord[1], cible)
		e = _largeur(sans_marin if nom == "passerelle" else carte, chemin)
		if e:
			etroites.append(f"{nom} {e[:2]}")
	r.critere(not etroites, "chemins d'au moins 2 cases de large (entrée → chaque porte, "
		"passerelle, Route 11)" + (f" — étroits : {etroites}" if etroites else ""))
	r.critere(est[0] in dist, "sortie est (Route 11) atteignable à "
		f"{min(dist.get(c, INF) for c in est)} pas de l'entrée")

	# 7. PNJ.
	dockers = [p for p in plan.of_kind("pnj") if p.ident.startswith("docker")]
	r.critere(len(dockers) == 2 and all(plan.at(*p.cells[0]) == "q" for p in dockers)
		and plan.at(*marin) == "q", "un marin à la passerelle, deux dockers sur le quai")
	_positions(r, plan, carte, dist, set(".pq"), set())
	for p in plan.of_kind("panneau"):
		r.critere(plan.at(*p.cells[0]) != "=", f"{p.ident} {p.cells[0]} hors de la rue")


def verifier_route_6(chemin: Path) -> bool:
	r = Rapport()
	route_6(r, lire(chemin), lire(chemin.with_name("vermilion_city.txt")))
	return r.ok


def verifier_vermilion_city(chemin: Path) -> bool:
	r = Rapport()
	carmin(r, lire(chemin), lire(chemin.with_name("route_6.txt")))
	return r.ok


def main() -> int:
	r = Rapport()
	cible = sys.argv[1] if len(sys.argv) > 1 else ""
	plans = {n: lire(PLANS / f"{n}.txt") for n in ("route_6", "vermilion_city")}
	if cible in ("", "route_6"):
		route_6(r, plans["route_6"], plans["vermilion_city"])
	if cible in ("", "vermilion_city"):
		carmin(r, plans["vermilion_city"], plans["route_6"])
	print("\nGrilles conformes." if r.ok else "\nGrilles NON conformes.")
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
