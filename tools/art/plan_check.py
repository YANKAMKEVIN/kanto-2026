#!/usr/bin/env python3
"""Vérifie une grille fonctionnelle de carte par recherche de chemin (jalon 8 T0, jalon 9 T14).

Mêmes règles de déplacement que `GridWorld` (game/world/grid_world.gd) : 4 directions, une case
de rebord ne s'entre que dans son sens (vers le sud) et fait atterrir sur la case suivante
(saut = un pas). Cases bloquées : tout caractère hors des praticables de la grille (ligne
`PRATICABLES`, défaut `. = h v D p`) et les positions `bloque`.

**Route 2** (`route_2.txt`, docs/tech/jalon-08.md §3, T0 ; repris par test_route_2 au T5) :
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

**Forêt de Jade** (`viridian_forest.txt`, docs/tech/jalon-09.md §2.7.1 et §7 ; repris par
test_viridian_forest) : voir `verifier_foret`. Grille agrandie le 2026-10-08 (profil
`FORET_PROFILS` : 70 × 90, 330 à 360 pas, H3 et H5 obligatoires, Théo et Milo inévitables).

**Route 3** (`route_3.txt`, jalon 12, dossier 15 §3) : `verifier_route_3`, dans
`plan_check_route_3.py` (raccord sur Argenta, Centre, grotte, D1 et D2 inévitables, deux
itinéraires, rebords, herbes obligatoires, objet caché « cache », durée de traversée).

**Jalon 13** (dossier 16) : `route_4.txt`, `azuria.txt`, `route_24.txt`, `azuria_arene.txt`,
`azuria_velos.txt`, `azuria_maison.txt` → `plan_check_azuria.py` (recouvrement exact du sas, raccords
entre cartes, rebord unique, eau et ponts, Centre premier bâtiment, rival, Ondine, pont Pépite).

Usage : python3 tools/art/plan_check.py [grille.txt ...]   (code 1 si un critère échoue)
        sans argument : toutes les grilles connues (Route 2, Forêt de Jade, Route 3, J13).
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import HERBES, PORTE, REBORD, Plan, lire  # noqa: E402

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
		return c not in self.bloquees and self.plan.at(x, y) in self.plan.praticables

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


def verifier_route_2(chemin: Path) -> bool:
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


# --- Forêt de Jade (jalon 9, T14) -------------------------------------------------------------

FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
# Sol où poser un personnage, un point d'apparition ou un objet caché : herbe rase, clairière,
# chemin, sortie (jamais les hautes herbes : un objet caché y serait confondu avec une rencontre).
SOL_RAS = set(".C=gL")
# Dossier 10 : taille, longueur, herbes obligatoires (par profil de grille), visions, objets.
# « zones » : noms des zones de hautes herbes ; sans position « herbes » (role=Hn) dans la grille,
# elles sont nommées du sud au nord dans cet ordre. « obligatoires » : zone → (min, max) de cases
# traversées sur le trajet le moins herbeux ; les autres zones sont évitables sans détour.
FORET_PROFILS = {
	# Forêt agrandie (décision de Kevin, 2026-10-08 ; remplace la grille 58 × 74 du T14) :
	# 7 traversées, une 2e zone obligatoire courte (H5, défaut 4 à 6 cases) en plus de H3.
	"viridian_forest": {
		"taille": (70, 90), "chemin": (330, 360),
		"zones": ("H1", "H2", "H3", "H4", "H5"), "obligatoires": {"H3": (6, 8), "H5": (4, 6)},
	},
}
# Estimation de la traversée directe (chantier « Forêt agrandie ») : pas mesuré sur S21 (T22 :
# 233 pas en 2 min 48 s), combat de Théo mesuré, combat sauvage estimé (défaut, à mesurer).
FORET_S_PAR_PAS = 0.72
FORET_S_THEO = 100
FORET_S_MILO = 120                 # défaut (deux Pokémon), Milo inévitable (XL-1, 2026-10-08)
FORET_S_SAUVAGE = 50
FORET_TAUX = 25 / 256              # data/encounters/viridian_forest.json, « rate »
FORET_VISIONS = {"D1": 4, "D2": 5, "D3": 4, "D4": 5, "D5": 5}
FORET_OBJETS = {"O1": "objet_visible", "O2": "objet_visible", "O3": "objet_cache",
	"O4": "objet_cache", "O5": "objet_visible", "O6": "objet_cache"}
FORET_O1_MAX = 25                  # pas depuis l'entrée
FORET_O6_MAX = 15                  # pas depuis la porte du poste nord
FORET_DETECTION_D1 = 3             # distance minimale de la première case vue de Théo (≥ 2 libres)
FORET_INEVITABLES = ("D1", "D4")   # Théo, et Milo depuis la décision XL-1 (2026-10-08)
FORET_CLAIRIERE = (7, 5)           # C1–C3 : au moins 7 × 5 cases (caméra ≈ 24,4 × 11,25)


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def ligne_de_vue(monde: Monde, p) -> list[Case]:
	"""Cases vues par un Dresseur (TrainerRules.sight_distance) : la ligne s'arrête à la première
	case infranchissable ou occupée ; les hautes herbes ne la coupent pas."""
	d = FACINGS[p.attrs["facing"]]
	cases: list[Case] = []
	for k in range(1, int(p.attrs["sight"]) + 1):
		c = _decale(p.cells[0], d, k)
		if not monde.libre(c):
			break
		cases.append(c)
	return cases


def ligne_brute(plan: Plan, p) -> list[Case]:
	"""La ligne de vue déclarée, sans tenir compte des obstacles (pour les contrôles)."""
	d = FACINGS[p.attrs["facing"]]
	return [_decale(p.cells[0], d, k) for k in range(1, int(p.attrs["sight"]) + 1)
		if 0 <= _decale(p.cells[0], d, k)[0] < plan.width
		and 0 <= _decale(p.cells[0], d, k)[1] < plan.height]


def premiere_detection(monde: Monde, departs: list[Case], vue: list[Case]) -> int:
	"""Plus petite distance (1..vision) au Dresseur d'une case de sa ligne qu'un joueur venu de
	[departs] peut atteindre en entrant dans la ligne pour la première fois (INF : jamais)."""
	rang = {c: i + 1 for i, c in enumerate(vue)}
	vu = set(departs)
	file = deque(departs)
	mini = INF
	while file:
		c = file.popleft()
		for n in monde.voisins(c):
			if n in vu:
				continue
			vu.add(n)
			if n in rang:
				mini = min(mini, rang[n])  # détecté : on ne va pas plus loin
			else:
				file.append(n)
	return mini


def acces(monde: Monde, p) -> list[Case]:
	"""Cases d'où l'on prend un objet : la sienne (caché, libre) ou ses voisines (visible)."""
	c = p.cells[0]
	if not p.bloque:
		return [c]
	return [_decale(c, d) for d in DIRECTIONS if monde.libre(_decale(c, d))]


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def nommer_zones(plan: Plan, noms: tuple[str, ...]) -> dict[str, set[Case]]:
	"""Zones de hautes herbes par nom : d'après les positions « herbes » (role=Hn, une case dans
	la zone) s'il y en a, sinon du sud au nord dans l'ordre de [noms]."""
	zones = zones_herbes(plan)
	marques = {p.attrs.get("role", p.ident): p.cells[0] for p in plan.of_kind("herbes")}
	if not marques:
		return dict(zip(noms, zones))
	nommees: dict[str, set[Case]] = {}
	for nom, c in marques.items():
		for zone in zones:
			if c in zone:
				nommees[nom] = zone
	return nommees


def verifier_foret(chemin: Path) -> bool:
	plan = lire(chemin)
	ok = True
	profil = FORET_PROFILS[chemin.stem]
	FORET_TAILLE = profil["taille"]
	FORET_CHEMIN = profil["chemin"]

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= vrai
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	monde = Monde(plan)
	print(f"Grille {chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin} : "
		f"{plan.width} × {plan.height}")
	critere((plan.width, plan.height) == FORET_TAILLE,
		f"taille {plan.width} × {plan.height} (attendu {FORET_TAILLE[0]} × "
		f"{FORET_TAILLE[1]})")

	# Entrée sud, porte nord, bords fermés.
	bas = plan.height - 1
	entree = [c for c in plan.cells_of("g") if c[1] == bas]
	portes = plan.cells_of(PORTE)
	if not entree or len(portes) != 1:
		critere(False, f"sortie sud ({len(entree)} case(s) « g » en bas) et une porte « D » "
			f"({len(portes)}) attendues")
		return False
	porte = portes[0]
	bords = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, bas)) and monde.libre((x, y))]
	critere(sorted(bords) == sorted(entree),
		f"carte fermée : seules les cases de la sortie sud {entree} touchent le bord")
	warps = {c for p in plan.of_kind("warp") for c in p.cells}
	critere(set(entree) <= warps and porte in warps,
		"warps sur toute la sortie sud et sur la porte du poste nord")

	# 1. Chemin principal.
	dist = monde.distances(entree)
	aller = dist.get(porte, INF)
	critere(FORET_CHEMIN[0] <= aller <= FORET_CHEMIN[1],
		f"chemin principal le plus court : {aller} pas (attendu {FORET_CHEMIN[0]} à "
		f"{FORET_CHEMIN[1]})")
	if aller >= INF:
		return False
	retour = monde.distances([porte])

	# 1 bis. Largeur (décision de Kevin, 2026-10-07) : le chemin principal fait au moins 2 cases
	# de large. Une case est « large » si elle appartient à un carré 2 × 2 de terrain praticable ;
	# tout le sentier (= g) l'est, et le trajet le plus court se fait sur des cases larges (plus
	# la porte). Les passages d'une case (passage_o3, alcôve de Théo, sentes) restent des recoins.
	def terrain(c: Case) -> bool:
		return 0 <= c[0] < plan.width and 0 <= c[1] < plan.height \
			and plan.at(*c) in plan.praticables
	larges: set[Case] = set()
	for y in range(plan.height - 1):
		for x in range(plan.width - 1):
			carre = [(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)]
			if all(terrain(c) for c in carre):
				larges.update(carre)
	etroits = [c for c in plan.cells_of("=") + plan.cells_of("g") if c not in larges]
	hors_larges = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x, y) not in larges and (x, y) != porte}
	large = Monde(plan, hors_larges).distances(entree).get(porte, INF)
	critere(not etroits and large == aller,
		f"chemin principal ≥ 2 cases de large : sentier sans goulet ({len(etroits)} case(s) "
		f"étroite(s) {etroits[:4]}), trajet le plus court sur cases larges {large} pas")

	# 2. Hautes herbes : zones nommées (H1..H4, H5), seules les obligatoires du profil traversées.
	zones = zones_herbes(plan)
	noms = profil["zones"]
	obligatoires: dict[str, tuple[int, int]] = profil["obligatoires"]
	nommees = nommer_zones(plan, noms)
	if len(zones) != len(noms) or sorted(nommees) != sorted(noms) \
			or len({id(z) for z in nommees.values()}) != len(noms):
		critere(False, f"{len(noms)} zones de hautes herbes {', '.join(noms)} attendues, "
			f"{len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	for nom in noms:
		print(f"  {nom}{' (obligatoire)' if nom in obligatoires else ''} : {boite(nommees[nom])}")
	toutes = set().union(*zones)
	requises = set().union(*(nommees[n] for n in obligatoires))
	g_min = monde.herbes_min(entree, lambda c: c in toutes).get(porte, INF)
	hors = monde.herbes_min(entree, lambda c: c in toutes and c not in requises).get(porte, INF)
	par_zone: dict[str, int] = {}
	for nom, (lo, hi) in obligatoires.items():
		zone = nommees[nom]
		n = monde.herbes_min(entree, lambda c, z=zone: c in z).get(porte, INF)
		par_zone[nom] = n
		sans = Monde(plan, zone).distances(entree).get(porte, INF)
		critere(lo <= n <= hi and sans >= INF,
			f"{nom} obligatoire et courte : {n} cases traversées au moins (attendu {lo} à {hi}), "
			f"incontournable : {'oui' if sans >= INF else 'NON'}")
	critere(hors == 0 and g_min == sum(par_zone.values()),
		f"herbes obligatoires : {g_min} cases en tout ({' + '.join(f'{n} {k}' for k, n in par_zone.items())}), "
		f"aucune hors {', '.join(obligatoires)} (minimum hors de ces zones : {hors})")
	for nom in noms:
		if nom in obligatoires:
			continue
		d = Monde(plan, nommees[nom]).distances(entree).get(porte, INF)
		critere(d == aller, f"{nom} évitable sans détour ({d} pas sans y entrer)")
	h2 = nommees["H2"]

	# 3. Dresseurs : visions, inévitabilité de Théo, évitabilité des autres.
	dresseurs = _role(plan, "dresseur")
	critere(sorted(dresseurs) == sorted(FORET_VISIONS),
		f"5 Dresseurs D1..D5 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(FORET_VISIONS):
		return False
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vision = int(p.attrs.get("sight", "0"))
		vue = ligne_de_vue(monde, p)
		vues[role] = vue
		critere(vision == FORET_VISIONS[role] and len(vue) == vision
			and plan.at(*p.cells[0]) in SOL_RAS,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs.get('facing')} : vision {len(vue)}/"
			f"{vision} cases dégagées (dossier : {FORET_VISIONS[role]}), "
			f"{''.join(plan.at(*c) for c in vue)}")
	for role in FORET_INEVITABLES:
		p = dresseurs[role]
		sans = Monde(plan, set(vues[role])).distances(entree).get(porte, INF)
		premiere = premiere_detection(monde, entree, vues[role])
		# Le Dresseur couvre toute la largeur du sentier là où sa ligne le croise.
		sentier_vu = [c for c in vues[role] if plan.at(*c) == "="]
		critere(len(sentier_vu) >= 2,
			f"{role} {p.ident} couvre toute la largeur du sentier : {sentier_vu}")
		critere(sans >= INF and premiere >= FORET_DETECTION_D1,
			f"{role} inévitable ({'oui' if sans >= INF else f'NON, {sans} pas sans le croiser'}) ; "
			+ (f"première case vue à {premiere} cases ({premiere - 1} libres entre eux, attendu "
			f"≥ {FORET_DETECTION_D1 - 1})" if premiere < INF else "jamais vu"))
	for role in ("D2", "D3", "D5"):
		d = Monde(plan, set(vues[role])).distances(entree).get(porte, INF)
		critere(d < INF, f"{role} évitable : porte atteinte en {d} pas hors de sa vue")

	# 4. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "objet_cache")}
	critere(sorted(objets) == sorted(FORET_OBJETS)
		and all(objets[r].kind == k for r, k in FORET_OBJETS.items() if r in objets),
		"6 objets O1..O6 : O1, O2, O5 visibles ; O3, O4, O6 cachés")
	if sorted(objets) != sorted(FORET_OBJETS):
		return False
	def au_plus_pres(dists: dict[Case, int], p) -> int:
		return min((dists.get(c, INF) for c in acces(monde, p)), default=INF)
	for role in sorted(objets):
		p = objets[role]
		sol = plan.at(*p.cells[0])
		critere(au_plus_pres(dist, p) < INF and sol in SOL_RAS - {"="}
			if p.kind == "objet_cache" else au_plus_pres(dist, p) < INF and sol in SOL_RAS,
			f"{role} {p.ident} {p.cells[0]} sur « {sol} » : atteint en {au_plus_pres(dist, p)} pas")
	critere(au_plus_pres(dist, objets["O1"]) < FORET_O1_MAX,
		f"O1 près du début : {au_plus_pres(dist, objets['O1'])} pas (< {FORET_O1_MAX})")
	critere(au_plus_pres(retour, objets["O6"]) < FORET_O6_MAX,
		f"O6 près de la sortie : {au_plus_pres(retour, objets['O6'])} pas de la porte "
		f"(< {FORET_O6_MAX})")
	sans_h2 = Monde(plan, h2).distances(entree)
	critere(min((sans_h2.get(c, INF) for c in acces(monde, objets["O2"])), default=INF) >= INF,
		"O2 au fond du cul-de-sac occidental : inaccessible sans traverser H2")
	passage = plan.positions.get("passage_o3")
	if passage is None:
		critere(False, "repère passage_o3 (passage d'une case vers O3) manquant")
	else:
		c = passage.cells[0]
		sans_p = Monde(plan, {c}).distances(entree)
		voisins = sum(1 for d in DIRECTIONS if monde.libre(_decale(c, d)))
		critere(monde.libre(c) and voisins == 2 and min((sans_p.get(a, INF)
			for a in acces(monde, objets["O3"])), default=INF) >= INF,
			f"O3 derrière la grande souche, par le passage d'une case {c}")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	sur_ligne = [r for r, p in objets.items() if p.kind == "objet_visible" and p.cells[0] in lignes]
	critere(not sur_ligne, f"aucun objet visible sur une ligne de vue de Dresseur {sur_ligne}")

	# 5. Un Dresseur qui s'approche ne ferme jamais un passage (jalon 9 §6.9, §6.10).
	# Cibles : la porte, l'entrée et chaque objet (par l'une de ses cases d'accès).
	cibles = [[porte], [entree[0]]] + [acces(monde, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in dist:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Monde(plan)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	critere(not fermes, "l'approche d'un Dresseur ne ferme aucun passage "
		f"{fermes[:3] if fermes else ''}")

	# 6. PNJ, Pokémon d'ambiance : hors herbes, hors lignes de vue.
	for p in plan.of_kind("pnj") + plan.of_kind("pokemon") + plan.of_kind("decor"):
		mauvais = [c for c in p.cells if c in lignes or plan.at(*c) == HERBES]
		if p.kind == "pnj":
			mauvais += [c for c in p.cells if plan.at(*c) not in SOL_RAS]
		else:
			pres = any(monde.libre(_decale(c, d)) or plan.at(*_decale(c, d)) in SOL_RAS
				for c in p.cells for d in DIRECTIONS
				if 0 <= _decale(c, d)[0] < plan.width and 0 <= _decale(c, d)[1] < plan.height)
			if not pres:
				mauvais.append("loin de toute case praticable")
		if mauvais:
			critere(False, f"{p.ident} ({p.kind}) mal placé : {mauvais}")

	# 7. Repères sud → nord, clairières (respirations).
	def moy_y(car: str) -> float:
		cases = plan.cells_of(car)
		return sum(y for _, y in cases) / len(cases) if cases else -1
	tronc, souche, rai = moy_y("I"), moy_y("S"), moy_y("L")
	critere(min(tronc, souche, rai) >= 0 and tronc > souche > rai,
		f"repères du sud au nord : tronc incliné (y ≈ {tronc:.0f}) → grande souche "
		f"(y ≈ {souche:.0f}) → clairière lumineuse (y ≈ {rai:.0f})")
	vus = all(any(_decale(c, d) in dist or c in dist for c in plan.cells_of(car) for d in DIRECTIONS)
		for car in "ISL")
	critere(vus, "repères au bord d'une case atteignable")
	for p in sorted(plan.of_kind("clairiere"), key=lambda p: p.attrs.get("role", p.ident)):
		xs = [x for x, _ in p.cells]
		ys = [y for _, y in p.cells]
		taille = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
		ouverte = all(plan.at(*c) in plan.praticables for c in p.cells)
		mini = p.attrs.get("role", "").startswith("C")
		critere(ouverte and (not mini or (taille[0] >= FORET_CLAIRIERE[0]
			and taille[1] >= FORET_CLAIRIERE[1])),
			f"clairière {p.attrs.get('role', p.ident)} {p.ident} : {taille[0]} × {taille[1]} "
			f"cases ouvertes{' (≥ 7 × 5)' if mini else ''}")

	# 8. Positions sur des cases cohérentes.
	for p in plan.of_kind("spawn") + plan.of_kind("repere"):
		for c in p.cells:
			if plan.at(*c) not in SOL_RAS:
				critere(False, f"{p.ident} sur « {plan.at(*c)} » en {c}")

	# Statistiques.
	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes "
		f"({', '.join(f'{n} {len(nommees[n])}' for n in noms)}) ; porte → sortie "
		f"{retour.get(entree[0], INF)} pas")
	rencontres = g_min * FORET_TAUX
	duree = aller * FORET_S_PAR_PAS + FORET_S_THEO + FORET_S_MILO + rencontres * FORET_S_SAUVAGE
	print(f"  traversée directe estimée : {aller} pas × {FORET_S_PAR_PAS} s + Théo {FORET_S_THEO} s "
		f"+ Milo {FORET_S_MILO} s "
		f"+ {rencontres:.2f} rencontre(s) attendue(s) × {FORET_S_SAUVAGE} s = {duree:.0f} s "
		f"({int(duree // 60)} min {int(duree % 60):02d} s)")
	return ok


def verifier_route_3(chemin: Path) -> bool:
	"""Route 3 (jalon 12, dossier 15 §3) : profil dans `plan_check_route_3.py` (import tardif,
	ce module importe celui-ci)."""
	from plan_check_route_3 import verifier_route_3 as verifier
	return verifier(chemin)


def verifier_route_6(chemin: Path) -> bool:
	"""Route 6 (jalon 15, dossier 18 §6) : profil dans `plan_check_carmin.py`."""
	from plan_check_carmin import verifier_route_6 as verifier
	return verifier(chemin)


def verifier_vermilion_city(chemin: Path) -> bool:
	"""Carmin-sur-Mer (jalon 15, dossier 18 §8) : profil dans `plan_check_carmin.py`."""
	from plan_check_carmin import verifier_vermilion_city as verifier
	return verifier(chemin)


def _azuria(nom: str):
	"""Grilles du jalon 13 : profils dans `plan_check_azuria.py` (import tardif, comme la Route 3)."""
	def verifier(chemin: Path) -> bool:
		import plan_check_azuria
		return plan_check_azuria.VERIFICATEURS[nom](chemin)
	return verifier


VERIFICATEURS = {"route_2": verifier_route_2, "viridian_forest": verifier_foret,
	"route_3": verifier_route_3, "route_6": verifier_route_6,
	"vermilion_city": verifier_vermilion_city,
	**{n: _azuria(n) for n in ("route_4", "azuria", "route_24", "azuria_arene", "azuria_velos",
		"azuria_maison")}}


def main() -> int:
	chemins = [Path(a) for a in sys.argv[1:]] or [RACINE / f"tools/plans/{n}.txt"
		for n in VERIFICATEURS]
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
