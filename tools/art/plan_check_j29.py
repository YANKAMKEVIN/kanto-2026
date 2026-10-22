#!/usr/bin/env python3
"""Contrôle des grilles du jalon 29 (`docs/tech/jalon-29.md` §2.1, §2.2, §2.4, §6 point 2).

Toutes les cartes ensemble, de la Route 22 du J7 au Plateau Indigo : `route_22`, `route_22_ouest`,
`poste_ligue`, `route_23`, `route_victoire_1f`, `_2f`, `_3f`, `plateau_indigo`.

- **Raccords** : chaque warp (et échelle) vise une carte du jalon et un point d'apparition de sa
  grille, sur une case praticable ; chaque carte a un chemin de retour.
- **Anti-blocage de la Force** (exigence du dossier J29) : exploration exhaustive des états
  atteignables (carte, case, rochers, drapeaux) avec les règles de `BoulderRules` **et les
  niveaux de sol** (on ne passe du sol bas `.` au sol haut `:` que par un escalier `=` ; un rocher
  ne change jamais de niveau ; une échelle `L` est de tout niveau), les rochers remis à leur
  origine à chaque entrée sur une carte, les drapeaux gardés (interrupteurs, trous bouchés), les
  rochers conditionnels (`si=`, rocher tombé du 3F au 2F) ; depuis **chaque** état atteint, une
  suite de coups mène encore au Plateau Indigo (aucun blocage définitif) ; chaque interrupteur
  s'enfonce, chaque barrière s'ouvre, chaque trou se bouche.
- **Contrôles des Badges** : avec les huit Badges, le Plateau est atteignable ; sans un seul
  Badge, il ne l'est plus (chaque poste arrête) et le retour à Jadielle reste possible de partout ;
  la Route Victoire est le seul passage entre le sud et le nord de la Route 23.
- **Eau** (Route 23) : seulement là où RB en a (contrôle des écarts : `j29_rb_decode.py --ecarts`).

Hypothèses du contrôle : le joueur a Surf et Force (modèle hybride du J16 : CS03, CS04, Pokémon,
Badges Âme et Prisme) ; le rival n° 7 est battu (il bloque la porte du poste tant qu'il ne l'est
pas) ; les Dresseurs, Sulfura et les gardes occupent leur case pour toujours (prudent).

Usage : python3 -I tools/art/plan_check_j29.py            (contrôle, visites bornées à
                                                           MAX_ETATS_VISITE états, signalées)
        python3 -I tools/art/plan_check_j29.py --complet  (sans borne : plusieurs heures)
        python3 -I tools/art/plan_check_j29.py --autotest (le contrôle refuse des pièges connus)
Code 1 si un critère échoue.
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
# États explorés au plus par visite (carte, région de départ, drapeaux) ; au-delà, la visite est
# « partielle » (signalée) : ses états explorés sont contrôlés, les autres non. `--complet` lève la
# limite (plusieurs heures : le 3F a des millions d'états, ses rochers n° 1 et 2 parcourant 159 cases).
MAX_ETATS_VISITE = 150_000

# Carte du jeu → grille.
GRILLES = {
	"route_22": "route_22",
	"route_22_west": "route_22_ouest",
	"route_22_gate": "poste_ligue",
	"route_23": "route_23",
	"victory_road_1f": "route_victoire_1f",
	"victory_road_2f": "route_victoire_2f",
	"victory_road_3f": "route_victoire_3f",
	"indigo_plateau": "plateau_indigo",
}
# Cartes à niveaux de sol (Route Victoire).
A_NIVEAUX = {"victory_road_1f", "victory_road_2f", "victory_road_3f"}
# Cartes hors grilles du jalon (destinations admises).
EXTERNES = {"viridian_city", "indigo_plateau_lobby"}
DEPART = ("route_22", "from_viridian")
BUT_CARTE = "indigo_plateau_lobby"
BADGES = ["badge_boulder", "badge_cascade", "badge_thunder", "badge_rainbow", "badge_soul",
	"badge_marsh", "badge_volcano", "badge_earth"]
SORTIES = ("warp", "echelle")
BAS, HAUT, ESCALIER, TOUT = 1, 2, 3, 0


def _plus(c: Case, d: Case) -> Case:
	return (c[0] + d[0], c[1] + d[1])


class Carte:
	"""Une grille lue, avec ses données statiques pour l'exploration."""

	def __init__(self, ident: str, plan: Plan) -> None:
		self.ident = ident
		self.plan = plan
		self.niveaux = ident in A_NIVEAUX
		self.fixes: set[Case] = {c for p in plan.positions.values() if p.bloque
			and p.kind not in ("rocher", "barriere", "trou") for c in p.cells}
		self.rochers: list[tuple[Case, int, str]] = []  # origine, trou désigné, condition si=
		for p in plan.of_kind("rocher"):
			self.rochers.append((p.cells[0], int(p.attrs.get("trou", "0")), p.attrs.get("si", "")))
		for c in plan.cells_of("B"):
			self.rochers.append((c, 0, ""))
		self.trous = {p.cells[0]: (p.attrs.get("n", ""), p.attrs.get("drapeau", ""),
			p.attrs.get("chute", "")) for p in plan.of_kind("trou")}
		self.inters = {p.cells[0]: p.attrs.get("drapeau", "") for p in plan.of_kind("interrupteur")}
		self.barrieres = {c: p.attrs.get("ouverte_si", "") for p in plan.of_kind("barriere")
			for c in p.cells}
		self.controles = {c: p.attrs.get("badge", "") for p in plan.of_kind("controle")
			for c in p.cells}
		self.interdits = {c for p in plan.of_kind("interdit_rocher") for c in p.cells}
		self.sorties: dict[Case, tuple[str, str]] = {}
		for kind in SORTIES:
			for p in plan.of_kind(kind):
				carte, _, spawn = p.attrs.get("vers", ":").partition(":")
				for c in p.cells:
					self.sorties[c] = (carte, spawn)
		self.spawns: dict[str, Case] = {p.ident: p.cells[0] for p in plan.positions.values()
			if p.kind in ("spawn", "depart")}
		self.chutes = {p.attrs.get("depuis", ""): p.cells[0] for p in plan.of_kind("chute_joueur")}
		# Drapeaux qui changent quelque chose sur cette carte (les autres n'y comptent pas).
		self.pertinents = frozenset(set(self.inters.values()) | {t[1] for t in self.trous.values()}
			| set(self.barrieres.values()) | {si for _, _, si in self.rochers if si})

	def dans(self, c: Case) -> bool:
		return 0 <= c[0] < self.plan.width and 0 <= c[1] < self.plan.height

	def niveau(self, c: Case) -> int:
		if not self.niveaux:
			return TOUT
		ch = self.plan.at(*c)
		return {":": HAUT, "=": ESCALIER, "L": TOUT}.get(ch, BAS)

	def sol(self, c: Case) -> bool:
		return self.dans(c) and self.plan.at(*c) in self.plan.praticables and c not in self.fixes

	@staticmethod
	def compatibles(a: int, b: int) -> bool:
		return a == b or TOUT in (a, b) or ESCALIER in (a, b)

	# --- Ensembles de cases en bits (exploration rapide) -------------------------------------

	def bit(self, c: Case) -> int:
		return 1 << (c[1] * self.plan.width + c[0])

	def masques(self) -> None:
		"""Masques fixes : sol, niveaux, colonnes de bord, sorties."""
		w, h = self.plan.width, self.plan.height
		self.plein = (1 << (w * h)) - 1
		col0 = sum(1 << (y * w) for y in range(h))
		self.sans_col0 = self.plein & ~col0
		self.sans_der = self.plein & ~(col0 << (w - 1))
		self.m_sol = self.m_bas = self.m_haut = self.m_libre_niveau = 0
		for y in range(h):
			for x in range(w):
				c = (x, y)
				if not self.sol(c):
					continue
				b = self.bit(c)
				self.m_sol |= b
				n = self.niveau(c)
				if n == BAS:
					self.m_bas |= b
				elif n == HAUT:
					self.m_haut |= b
				else:
					self.m_libre_niveau |= b
		self.m_sorties = sum(self.bit(c) for c in self.sorties)
		self.m_bas_src = self.m_bas | self.m_libre_niveau
		self.m_haut_src = self.m_haut | self.m_libre_niveau

	def voisins(self, x: int) -> int:
		w = self.plan.width
		return (((x << 1) & self.sans_col0) | ((x >> 1) & self.sans_der) | (x << w) | (x >> w)) \
			& self.plein

	def voisins_permis(self, region: int) -> int:
		"""Cases voisines de la région où un pas est permis par les niveaux (sans les obstacles)."""
		return (self.voisins(region & self.m_bas_src) & self.m_bas) \
			| (self.voisins(region & self.m_haut_src) & self.m_haut) \
			| (self.voisins(region) & self.m_libre_niveau)


class Explorateur:
	def __init__(self, cartes: dict[str, Carte], badges: set[str]) -> None:
		self.cartes = cartes
		self.badges = frozenset(badges)
		self.etats = 0
		self.echecs: list[str] = []
		# (carte, entrée, drapeaux pertinents) → (jeux de sorties distincts, drapeaux posés) :
		# l'exploration d'une visite n'est faite qu'une fois.
		self._memo: dict[tuple, tuple] = {}
		self.drapeaux_vus: set[str] = set()
		# Visites dont l'exploration a atteint MAX_ETATS_VISITE : (carte, entrée, drapeaux, reste).
		self.partielles: list[tuple] = []

	def rochers_entree(self, carte: Carte, drapeaux: frozenset[str]) -> frozenset[Case]:
		pres = set()
		for c, trou, si in carte.rochers:
			if si and si not in drapeaux:
				continue
			if trou and any(t[0] == str(trou) and t[1] in drapeaux for t in carte.trous.values()):
				continue
			pres.add(c)
		return frozenset(pres)

	def ouverte(self, carte: Carte, c: Case, drapeaux: frozenset[str]) -> bool:
		if c in carte.barrieres and carte.barrieres[c] not in drapeaux:
			return False
		return c not in carte.controles or carte.controles[c] in self.badges

	def zone(self, carte: Carte, depart: Case, rochers: frozenset[Case],
			drapeaux: frozenset[str]) -> tuple[set[Case], list[tuple[str, Case | None, frozenset[str]]]]:
		"""Cases où le joueur marche, et les sorties atteintes (carte, case d'arrivée, drapeaux)."""
		vues = {depart}
		file = deque([depart])
		sorties = []
		while file:
			c = file.popleft()
			if c in carte.sorties:
				sorties.append(c)
			for d in DIRECTIONS:
				n = _plus(c, d)
				if n in vues or not carte.sol(n) or n in rochers or not self.ouverte(carte, n, drapeaux):
					continue
				if not Carte.compatibles(carte.niveau(c), carte.niveau(n)):
					continue
				if n in carte.trous and carte.trous[n][1] not in drapeaux:
					sorties.append(("chute", n))
					continue
				vues.add(n)
				file.append(n)
		res = []
		for s in sorties:
			if isinstance(s, tuple) and s and s[0] == "chute":
				num, _, dessous = carte.trous[s[1]]
				cible = self.cartes.get(dessous)
				arrivee = cible.chutes.get(f"{carte.ident}:{num}") if cible else None
				res.append((dessous, arrivee, drapeaux))
			else:
				dest, spawn = carte.sorties[s]
				cible = self.cartes.get(dest)
				res.append((dest, cible.spawns.get(spawn) if cible else None, drapeaux))
		return vues, res

	def pousser(self, carte: Carte, rocher: Case, d: Case, rochers: frozenset[Case],
			drapeaux: frozenset[str]):
		cible = _plus(rocher, d)
		pousseur = (rocher[0] - d[0], rocher[1] - d[1])
		if not Carte.compatibles(carte.niveau(pousseur), carte.niveau(rocher)):
			return None
		if not carte.sol(cible) or carte.plan.at(*cible) in "w~L" or cible in carte.interdits:
			return None
		if carte.niveau(cible) != carte.niveau(rocher):
			return None
		if cible in rochers or not self.ouverte(carte, cible, drapeaux) or cible in carte.sorties:
			return None
		autres = rochers - {rocher}
		if cible in carte.trous and carte.trous[cible][1] not in drapeaux:
			return autres, drapeaux | {carte.trous[cible][1]}
		if cible in carte.inters and carte.inters[cible] not in drapeaux:
			return autres | {cible}, drapeaux | {carte.inters[cible]}
		return autres | {cible}, drapeaux

	def zone_bits(self, carte: Carte, depart: Case, rochers: frozenset[Case],
			drapeaux: frozenset[str]) -> tuple[int, list]:
		"""[zone] en bits : la région (entier) et les sorties atteintes."""
		bloque = 0
		for c in rochers:
			bloque |= carte.bit(c)
		for c, f in carte.barrieres.items():
			if f not in drapeaux:
				bloque |= carte.bit(c)
		for c, b in carte.controles.items():
			if b not in self.badges:
				bloque |= carte.bit(c)
		trous_ouverts = 0
		for c, t in carte.trous.items():
			if t[1] not in drapeaux:
				trous_ouverts |= carte.bit(c)
		libre = carte.m_sol & ~bloque & ~trous_ouverts
		region = carte.bit(depart)
		while True:
			nouvelle = region | (carte.voisins_permis(region) & libre)
			if nouvelle == region:
				break
			region = nouvelle
		sorties = []
		if region & carte.m_sorties:
			for c, (dest, spawn) in carte.sorties.items():
				if region & carte.bit(c):
					cible = self.cartes.get(dest)
					sorties.append((dest, cible.spawns.get(spawn) if cible else None, drapeaux))
		if trous_ouverts:
			atteints = carte.voisins_permis(region) & trous_ouverts
			for c, (num, _, dessous) in carte.trous.items():
				if atteints & carte.bit(c):
					cible = self.cartes.get(dessous)
					arrivee = cible.chutes.get(f"{carte.ident}:{num}") if cible else None
					sorties.append((dessous, arrivee, drapeaux))
		return region, sorties

	def visiter(self, ident: str, entree: Case, drapeaux0: frozenset[str]):
		"""Tous les états d'une visite de la carte : liste (état, sorties), successeurs de chaque
		état par une poussée, et états « incomplets » (exploration bornée : successeurs inconnus)."""
		carte = self.cartes[ident]
		if not hasattr(carte, "plein"):
			carte.masques()
		etats = []
		succ: list[set[int]] = []
		index: dict[tuple, int] = {}
		incomplets: set[int] = set()
		vus_joueur: dict[tuple, int] = {}
		file = deque([(entree, self.rochers_entree(carte, drapeaux0), drapeaux0, -1)])
		while file:
			joueur, rochers, drapeaux, parent = file.popleft()
			cle_j = (joueur, rochers, drapeaux)
			if cle_j in vus_joueur:
				k = vus_joueur[cle_j]
			else:
				region, sorties = self.zone_bits(carte, joueur, rochers, drapeaux)
				cle = (region, rochers, drapeaux)
				if cle in index:
					k = index[cle]
				else:
					k = len(etats)
					index[cle] = k
					etats.append((cle, sorties))
					succ.append(set())
					self.etats += 1
					if MAX_ETATS_VISITE and len(etats) >= MAX_ETATS_VISITE:
						self.partielles.append((ident, entree, sorted(drapeaux0), len(file)))
						incomplets.add(k)
						incomplets.update(p for *_, p in file if p >= 0)
						if parent >= 0:
							succ[parent].add(k)
						break
					for r in rochers:
						for d in DIRECTIONS:
							pousseur = (r[0] - d[0], r[1] - d[1])
							if not carte.dans(pousseur) or not region & carte.bit(pousseur):
								continue
							if not Carte.compatibles(carte.niveau(pousseur), carte.niveau(r)):
								continue
							res = self.pousser(carte, r, d, rochers, drapeaux)
							if res is not None:
								file.append((r, res[0], res[1], k))
				vus_joueur[cle_j] = k
			if parent >= 0:
				succ[parent].add(k)
		return etats, succ, incomplets

	def visiter_memo(self, ident: str, entree: Case, drapeaux: frozenset[str]):
		"""[visiter] avec les seuls drapeaux pertinents de la carte, mémorisé ; les sorties portent
		tous les drapeaux (ceux d'avant la visite et ceux posés pendant)."""
		carte = self.cartes[ident]
		if not hasattr(carte, "plein"):
			carte.masques()
		rel = drapeaux & carte.pertinents
		# Deux entrées dans la même région de départ (rochers à l'origine) ont la même visite.
		depart, _ = self.zone_bits(carte, entree, self.rochers_entree(carte, rel), rel)
		cle = (ident, depart, rel)
		if cle not in self._memo:
			# Seuls comptent, pour la suite, les jeux de sorties distincts des états de la visite
			# (un état = une région du joueur, des rochers, des drapeaux) et les drapeaux posés.
			etats, succ, incomplets = self.visiter(ident, entree, rel)
			# Sorties atteignables depuis chaque état, poussées comprises (point fixe : une
			# poussée peut rouvrir un chemin) ; un état incomplet (exploration bornée) n'est
			# jamais déclaré bloqué.
			atteintes = [frozenset(s) for _, s in etats]
			change = True
			while change:
				change = False
				for k in range(len(etats) - 1, -1, -1):
					union = atteintes[k]
					for n in succ[k]:
						union = union | atteintes[n]
					if union != atteintes[k]:
						atteintes[k] = union
						change = True
			jeux = {a for k, a in enumerate(atteintes) if k not in incomplets}
			poses: set[str] = set()
			for (_, _, dr), _ in etats:
				poses |= dr
			self._memo[cle] = (jeux, frozenset(poses))
		jeux, poses = self._memo[cle]
		self.drapeaux_vus |= poses
		return [frozenset((d, a, drapeaux | f) for d, a, f in jeu) for jeu in jeux]

	def explorer(self, depart: tuple[str, str], drapeaux0: frozenset[str] = frozenset()):
		"""Graphe des visites (carte, entrée, drapeaux) ; états de chaque visite et leurs sorties."""
		carte0 = self.cartes[depart[0]]
		v0 = (depart[0], carte0.spawns[depart[1]], drapeaux0)
		visites: dict[tuple, list] = {}
		file = deque([v0])
		while file:
			v = file.popleft()
			if v in visites or v[0] in EXTERNES:
				continue
			jeux = self.visiter_memo(*v)
			visites[v] = jeux
			for sorties in jeux:
				for dest, arrivee, dr in sorties:
					if dest in EXTERNES or arrivee is None:
						continue
					file.append((dest, arrivee, dr))
		return v0, visites


def _bons(visites: dict, but: str) -> set:
	"""Visites d'où l'on peut atteindre la carte [but] (point fixe arrière)."""
	bons: set = set()
	change = True
	while change:
		change = False
		for v, jeux in visites.items():
			if v in bons:
				continue
			for sorties in jeux:
				if any(d == but or (d, a, dr) in bons for d, a, dr in sorties):
					bons.add(v)
					change = True
					break
	return bons


def charger(dossier: Path = PLANS) -> dict[str, Carte]:
	return {ident: Carte(ident, lire(dossier / f"{g}.txt")) for ident, g in GRILLES.items()}


def verifier(dossier: Path = PLANS) -> list[str]:
	echecs: list[str] = []
	notes: list[str] = []
	cartes = charger(dossier)
	# Raccords.
	for ident, carte in cartes.items():
		for c, (dest, spawn) in carte.sorties.items():
			if dest in EXTERNES:
				continue
			if dest not in cartes:
				echecs.append(f"{ident} {c} : carte visée « {dest} » inconnue")
				continue
			cible = cartes[dest]
			if spawn not in cible.spawns:
				echecs.append(f"{ident} {c} : point d'apparition « {dest}:{spawn} » absent")
			elif not cible.sol(cible.spawns[spawn]):
				echecs.append(f"{ident} {c} : « {dest}:{spawn} » sur une case bloquée")
	if echecs:
		return echecs
	# Huit Badges : le but, l'anti-blocage, le retour.
	ex = Explorateur(cartes, set(BADGES))
	v0, visites = ex.explorer(DEPART)
	bons = _bons(visites, BUT_CARTE)
	retour = _bons(visites, "viridian_city")
	notes.append(f"huit Badges : {len(visites)} visites, {ex.etats} états explorés")
	for carte, entree, dr, reste in ex.partielles:
		notes.append(f"exploration PARTIELLE ({MAX_ETATS_VISITE} états, {reste} en file) : "
			f"{carte} depuis {entree}, drapeaux {dr}")
	if v0 not in bons:
		echecs.append("huit Badges : le Plateau Indigo n'est pas atteignable")
	cartes_vues = {v[0] for v in visites}
	for ident in GRILLES:
		if ident not in cartes_vues:
			echecs.append(f"huit Badges : {ident} jamais atteinte")
	bloques = 0
	exemple = None
	for v, jeux in visites.items():
		for sorties in jeux:
			ok = any(d == BUT_CARTE or (d, a, dr) in bons for d, a, dr in sorties)
			if not ok:
				bloques += 1
				exemple = exemple or (v[0], v[1], sorted(v[2]), sorted((d, a) for d, a, _ in sorties))
	if bloques:
		echecs.append(f"anti-blocage : {bloques} jeu(x) d'états d'où le Plateau n'est plus atteignable, "
			f"ex. {exemple}")
	pas_de_retour = [v for v in visites if v not in retour]
	if pas_de_retour:
		echecs.append(f"retour : {len(pas_de_retour)} visite(s) sans retour vers Jadielle, "
			f"ex. {pas_de_retour[0][:2]}")
	drapeaux_vus = ex.drapeaux_vus
	for ident in ("victory_road_1f", "victory_road_2f", "victory_road_3f"):
		c = cartes[ident]
		for drapeau in list(c.inters.values()) + [t[1] for t in c.trous.values()]:
			if drapeau not in drapeaux_vus:
				echecs.append(f"{ident} : « {drapeau} » ne peut pas être posé")
	# Un Badge manquant : le Plateau n'est plus atteignable, le retour l'est toujours.
	for manquant in BADGES:
		ex = Explorateur(cartes, set(BADGES) - {manquant})
		v0b, vis = ex.explorer(DEPART)
		if v0b in _bons(vis, BUT_CARTE):
			echecs.append(f"sans {manquant} : le Plateau reste atteignable (contournement)")
		ret = _bons(vis, "viridian_city")
		if any(v not in ret for v in vis):
			echecs.append(f"sans {manquant} : une visite sans retour vers Jadielle")
	# La Route Victoire est le seul passage entre le sud et le nord de la Route 23.
	sans_victoire = dict(cartes)
	r23 = cartes["route_23"]
	r23_sans = Carte("route_23", r23.plan)
	r23_sans.sorties = {c: s for c, s in r23.sorties.items() if not s[0].startswith("victory_road")}
	sans_victoire["route_23"] = r23_sans
	ex = Explorateur(sans_victoire, set(BADGES))
	v0c, vis = ex.explorer(DEPART)
	if v0c in _bons(vis, BUT_CARTE):
		echecs.append("Route 23 : le nord est atteignable sans la Route Victoire")
	for n in notes:
		print("   " + n)
	return echecs


def autotest() -> list[str]:
	"""Le contrôle refuse des pièges connus (copies modifiées des grilles)."""
	import shutil
	import tempfile
	erreurs = []
	pieges = {
		# Barrière du 1F sans interrupteur atteignable : drapeau impossible.
		"interrupteur muré": ("route_victoire_1f.txt",
			"interrupteur_1       interrupteur    17,13", "interrupteur_1       interrupteur    0,0  "),
		# Garde du Badge Volcan retiré : sans lui, le Plateau devient atteignable.
		"garde retiré": ("route_23.txt", "controle_2           controle        6..9,56;11..13,56",
			"controle_2           controle        0,0              "),
		# Passage ouvert dans la falaise entre le sud et le nord de la Route 23.
		"raccourci": ("route_23.txt", "37 ........######.....#", "37 ...................#"),
	}
	for nom, (fichier, avant, apres) in pieges.items():
		with tempfile.TemporaryDirectory() as tmp:
			for g in GRILLES.values():
				shutil.copy(PLANS / f"{g}.txt", Path(tmp) / f"{g}.txt")
			chemin = Path(tmp) / fichier
			texte = chemin.read_text(encoding="utf-8")
			if avant not in texte:
				erreurs.append(f"autotest « {nom} » : motif absent de {fichier}")
				continue
			chemin.write_text(texte.replace(avant, apres, 1), encoding="utf-8")
			if not verifier(Path(tmp)):
				erreurs.append(f"autotest « {nom} » : piège non détecté")
			else:
				print(f"   piège « {nom} » : refusé")
	return erreurs


def main(argv: list[str]) -> int:
	global MAX_ETATS_VISITE
	if "--complet" in argv:
		MAX_ETATS_VISITE = 0
	print("== Jalon 29 : Routes 22 et 23, Route Victoire, Plateau Indigo")
	echecs = autotest() if "--autotest" in argv else verifier()
	for e in echecs:
		print(f"   ÉCHEC : {e}")
	print("   conforme" if not echecs else f"   {len(echecs)} échec(s)")
	return 1 if echecs else 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
