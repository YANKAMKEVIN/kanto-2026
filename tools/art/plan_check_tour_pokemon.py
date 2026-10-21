#!/usr/bin/env python3
"""Vérifie les grilles de la Tour Pokémon, 2F à 6F (jalon 19, lot 19.0, dossier 22 §4 à §9).

Grilles : `tools/plans/pokemon_tower_2f.txt` … `pokemon_tower_6f.txt` (lecture par
`plan_grille.lire`, ligne PRATICABLES `.ZUV`). Un étage = 20 × 18 cases ; un pas = une case, 4
directions ; entrer sur une case d'escalier (U / V) est une sortie : on ne la traverse pas.

Critères :
  1. dimensions 20 × 18, bord de carte entièrement mur, légende connue ;
  2. escaliers : chaque paire (T23, T34, T45, T56) existe aux deux étages, sens opposés, même case
     (RB), une arrivée (spawn de même paire) voisine de l'escalier, zigzag gauche / droite ; T12
     (vers le 1F, J18) et T67 (vers le 7F, hors J19) n'ont qu'un bout ; case d'escalier = U (monte)
     / V (descend) ;
  3. nature des cases : chaque position sur la bonne case (sol, escalier, zone) ;
  4. accessibilité (BFS, tous les personnages bloquants) : tout le sol, toute arrivée, tout objet
     (par une case voisine) et tout personnage (idem) est atteignable depuis l'arrivée du bas ;
     l'arrivée du haut est reliée à celle du bas ;
  5. Dresseurs : 9 Exorcistes tower_channeler_1..9 aux bons étages, prénoms, facing, sight 2–3,
     inevitable conformes au dossier §8 ; une vue ne couvre ni arrivée, ni escalier, ni objet ;
  6. INÉVITABLES (3 : _3 au 4F, _8 et _9 au 6F) : aucun chemin de l'arrivée à la sortie de
     l'étage n'évite leur vue (ni leur case) ; ÉVITABLES : un chemin existe qui évite la vue de
     toutes les facultatives à la fois, et de chacune ;
  7. rival (2F) : sa case et ses deux cases de déclenchement coupent seules l'arrivée de l'escalier
     du 3F ; il peut repartir par l'escalier du bas ; 6F : l'escalier du 7F n'est atteignable que
     par la case du SPECTRE, qui n'est pas dans une vue, et dont la case de recul est voisine ;
  8. zone purifiée (5F) : 2 × 2, cases Z, exactement les cases de la position `zone`, et ni elle ni
     ses abords (8 voisines) dans la vue d'un Dresseur ;
  9. objets du dossier §4.2 : 3F 1, 4F 2, 5F 1, 6F 1 (identifiants indicatifs) ;
 10. durée estimée de la montée (pas de 0,72 s mesuré sur S21, combats et scènes en défaut).

Usage : python3 tools/art/plan_check_tour_pokemon.py   [--apercu : dessine chaque étage]
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
ETAGES = (2, 3, 4, 5, 6)
Case = tuple[int, int]

LARGEUR, HAUTEUR = 20, 18
LEGENDE = set("#.TSZUV")
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
SENS_CAR = {"monte": "U", "descend": "V"}
OPPOSE = {"monte": "descend", "descend": "monte"}

# Dossier 22 §8 : id → (étage, prénom, inévitable).
EXORCISTES = {
	1: (3, "Hortense", False), 2: (3, "Odile", False),
	3: (4, "Solange", True), 4: (4, "Mireille", False),
	5: (5, "Bérénice", False), 6: (5, "Marthe", False), 7: (5, "Ysée", False),
	8: (6, "Paulette", True), 9: (6, "Clémence", True),
}
# Dossier 22 §4.2 : objets visibles par étage.
OBJETS = {3: ["escape_rope"], 4: ["awakening", "super_potion"], 5: ["nugget"],
	6: ["super_potion"]}
# Paires d'escaliers : nom → (étage du bas, étage du haut). T12 et T67 sont hors de ces cinq cartes.
PAIRES = {"T23": (2, 3), "T34": (3, 4), "T45": (4, 5), "T56": (5, 6)}
# Côté de l'escalier qui monte (zigzag RB) : 2F gauche, 3F droite, 4F gauche, 5F droite.
COTE_MONTE = {2: 3, 3: 18, 4: 3, 5: 18}

S_PAR_PAS = 0.72
S_ESCALIER = 2.0
S_RIVAL, S_EXORCISTE_INEVITABLE, S_SPECTRE = 150, 70, 60


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def titre(self, texte: str) -> None:
		print(f"\n{texte}")

	def critere(self, condition: bool, texte: str) -> None:
		print(f"  [{'OK' if condition else 'ÉCHEC'}] {texte}")
		if not condition:
			self.ok = False

	def info(self, texte: str) -> None:
		print(f"  {texte}")


def nom(n: int) -> str:
	return f"pokemon_tower_{n}f"


class Etage:
	def __init__(self, n: int) -> None:
		self.n = n
		self.plan: Plan = lire(PLANS / f"{nom(n)}.txt")
		p = self.plan
		self.pos = p.positions
		# Cases bloquées par un personnage ou un objet (état initial).
		self.occupees: set[Case] = {c for q in self.pos.values() if q.bloque for c in q.cells}
		self.escaliers = {q.ident: q for q in p.of_kind("escalier")}
		self.spawns = {q.ident: q for q in p.of_kind("spawn")}
		self.exorcistes = {q.ident: q for q in p.of_kind("dresseur")}

	def car(self, c: Case) -> str:
		return self.plan.rows[c[1]][c[0]]

	def dans(self, c: Case) -> bool:
		return 0 <= c[0] < LARGEUR and 0 <= c[1] < HAUTEUR

	def libre(self, c: Case, occupees: set[Case] | None = None) -> bool:
		o = self.occupees if occupees is None else occupees
		return self.dans(c) and self.car(c) in self.plan.praticables and c not in o

	def sol(self) -> list[Case]:
		return [(x, y) for y in range(HAUTEUR) for x in range(LARGEUR)
			if self.car((x, y)) in ".Z"]

	def cases_escalier(self) -> set[Case]:
		return {(x, y) for y in range(HAUTEUR) for x in range(LARGEUR) if self.car((x, y)) in "UV"}

	def distances(self, departs: list[Case], interdites: set[Case] = frozenset(),
			occupees: set[Case] | None = None) -> dict[Case, int]:
		"""BFS ; les escaliers sont atteints mais jamais traversés ; `interdites` = cases évitées."""
		term = self.cases_escalier()
		dist = {c: 0 for c in departs if c not in interdites}
		file = deque(dist)
		while file:
			c = file.popleft()
			if c in term and dist[c] > 0:
				continue
			for dx, dy in DIRS:
				n = (c[0] + dx, c[1] + dy)
				if n in dist or n in interdites or not self.libre(n, occupees):
					continue
				dist[n] = dist[c] + 1
				file.append(n)
		return dist

	def vue(self, q) -> list[Case]:
		"""Cases vues par un Dresseur (TrainerRules.sight_distance) : la ligne s'arrête à la
		première case infranchissable ou occupée."""
		d = FACINGS[q.attrs["facing"]]
		autres = self.occupees - set(q.cells)
		cases: list[Case] = []
		for k in range(1, int(q.attrs["sight"]) + 1):
			c = (q.cells[0][0] + d[0] * k, q.cells[0][1] + d[1] * k)
			if not self.libre(c, autres):
				break
			cases.append(c)
		return cases

	def arrivee_bas(self) -> Case:
		return self.pos[f"arrivee_{self.escalier_bas().attrs['paire']}"].cells[0]

	def escalier_bas(self):
		return self.escaliers["escalier_bas"]

	def escalier_haut(self):
		return self.escaliers.get("escalier_haut") or self.escaliers["escalier_7f"]


def charger(r: Rapport) -> dict[int, Etage] | None:
	etages: dict[int, Etage] = {}
	for n in ETAGES:
		try:
			etages[n] = Etage(n)
		except (ValueError, FileNotFoundError, KeyError) as e:
			r.critere(False, f"{nom(n)} : lecture impossible ({e})")
			return None
	return etages


def critere_dimensions(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("1. Dimensions, bord, légende")
	for n, e in E.items():
		p = e.plan
		bord = all(e.car((x, y)) == "#" for x in range(LARGEUR) for y in (0, HAUTEUR - 1)) and \
			all(e.car((x, y)) == "#" for y in range(HAUTEUR) for x in (0, LARGEUR - 1))
		inconnus = {c for row in p.rows for c in row} - LEGENDE
		r.critere(p.width == LARGEUR and p.height == HAUTEUR and bord and not inconnus,
			f"{n}F : {p.width} × {p.height}, bord fermé, légende {sorted(inconnus) or 'ok'}")
		r.critere(set(p.praticables) == set(".ZUV"), f"{n}F : praticables {sorted(p.praticables)}")
		if n != 5:
			r.critere(not e.plan.cells_of("Z"), f"{n}F : pas de zone purifiée")


def critere_escaliers(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("2. Escaliers et arrivées")
	for n, e in E.items():
		for q in e.escaliers.values():
			c = q.cells[0]
			sens = q.attrs.get("sens")
			r.critere(len(q.cells) == 1 and sens in SENS_CAR and e.car(c) == SENS_CAR[sens]
				and "vers" in q.attrs and "paire" in q.attrs,
				f"{n}F {q.ident} {c} : sens={sens}, case « {e.car(c)} », vers={q.attrs.get('vers')}")
		hauts = [q for q in e.escaliers.values() if q.attrs.get("sens") == "monte"]
		bas = [q for q in e.escaliers.values() if q.attrs.get("sens") == "descend"]
		r.critere(len(hauts) == 1 and len(bas) == 1, f"{n}F : un escalier qui monte, un qui descend")
		# Arrivée : un spawn par paire, sur une case voisine de l'escalier de même paire.
		for q in e.escaliers.values():
			paire = q.attrs["paire"]
			if paire == "T67":
				r.critere(q.attrs["vers"] == "pokemon_tower_7f" and n == 6,
					f"{n}F : le warp du 7F est présent (jamais atteint au J19, pas d'arrivée)")
				continue
			sp = e.spawns.get(f"arrivee_{paire}")
			ok = sp is not None and sp.attrs.get("paire") == paire and sp.attrs.get("facing") in FACINGS
			if ok:
				c = sp.cells[0]
				voisin = abs(c[0] - q.cells[0][0]) + abs(c[1] - q.cells[0][1]) == 1
				ok = voisin and e.car(c) == "." and e.libre(c)
			r.critere(ok, f"{n}F : arrivée de {paire} voisine de {q.ident}, sol libre")
	for paire, (bas, haut) in PAIRES.items():
		q1 = next((q for q in E[bas].escaliers.values() if q.attrs["paire"] == paire), None)
		q2 = next((q for q in E[haut].escaliers.values() if q.attrs["paire"] == paire), None)
		ok = (q1 is not None and q2 is not None and q1.attrs["sens"] == "monte"
			and q2.attrs["sens"] == "descend" and q1.attrs["vers"] == nom(haut)
			and q2.attrs["vers"] == nom(bas) and q1.cells == q2.cells)
		r.critere(ok, f"{paire} : {bas}F ↑ {nom(haut)} ⇄ {haut}F ↓ {nom(bas)}, même case "
			f"{q1.cells[0] if q1 else '?'}")
	for n, x in COTE_MONTE.items():
		q = E[n].escalier_haut()
		r.critere(q.cells[0] == (x, 9), f"zigzag : escalier qui monte du {n}F en x = {x}, y = 9")
	q = E[2].escalier_bas()
	r.critere(q.attrs["paire"] == "T12" and q.attrs["vers"] == "pokemon_tower_1f"
		and q.cells[0] == (18, 9), "T12 : le 2F descend au 1F (J18) en (18, 9)")
	q = E[6].escalier_haut()
	r.critere(q.cells[0] == (9, 16), "T67 : l'escalier du 7F est en (9, 16) (RB)")


def critere_natures(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("3. Nature des cases des positions")
	for n, e in E.items():
		mauvais: list[str] = []
		for q in e.pos.values():
			for c in q.cells:
				k = e.car(c)
				if q.kind == "escalier":
					bon = k in "UV"
				elif q.kind == "zone":
					bon = k == "Z"
				elif q.kind == "repere":
					bon = k in ".S"
				else:
					bon = k == "."
				if not bon:
					mauvais.append(f"{q.ident}{c}=« {k} »")
		r.critere(not mauvais, f"{n}F : {len(e.pos)} positions sur la bonne nature {mauvais or ''}")
		# Deux positions bloquantes ne se superposent pas.
		vus: dict[Case, str] = {}
		doubles = []
		for q in e.pos.values():
			if q.kind in ("declencheur", "zone", "recul"):
				continue
			for c in q.cells:
				if c in vus:
					doubles.append(f"{q.ident}/{vus[c]}{c}")
				vus[c] = q.ident
		r.critere(not doubles, f"{n}F : aucune superposition {doubles or ''}")


def depart(e: Etage) -> Case:
	return e.arrivee_bas()


def occupees_apres(e: Etage) -> set[Case]:
	"""État de l'étage une fois le rival parti (2F) ; ailleurs, l'état initial."""
	if e.n == 2:
		return e.occupees - set(e.pos["tower_rival"].cells)
	return e.occupees


def accessibles(e: Etage) -> dict[Case, int]:
	return e.distances([depart(e)], occupees=occupees_apres(e))


def critere_acces(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("4. Accessibilité (tous les personnages bloquent ; 2F : rival parti)")
	for n, e in E.items():
		d = accessibles(e)
		manque = [c for c in e.sol() if c not in d and c not in e.occupees]
		r.critere(not manque, f"{n}F : tout le sol atteignable depuis l'arrivée {depart(e)} "
			f"({len(e.sol())} cases, plus loin à {max(d.values())} pas) {manque or ''}")
		for q in e.pos.values():
			if q.kind == "escalier":
				ok = q.cells[0] in d
			elif q.bloque:
				ok = any((q.cells[0][0] + dx, q.cells[0][1] + dy) in d for dx, dy in DIRS) \
					or q.kind == "rival"
			else:
				ok = all(c in d for c in q.cells)
			if not ok:
				r.critere(False, f"{n}F : {q.ident} {q.cells} inaccessible")
		r.critere(True, f"{n}F : escaliers, arrivées, déclencheurs, objets et personnages "
			"accessibles")
		# L'arrivée du haut est reliée à celle du bas (à pied, dans les deux sens).
		if n != 6:
			hau = e.pos[f"arrivee_{e.escalier_haut().attrs['paire']}"].cells[0]
			r.critere(hau in d and e.distances([hau], occupees=occupees_apres(e)).get(depart(e)) is not None,
				f"{n}F : arrivée du haut {hau} reliée à celle du bas, dans les deux sens")
		# Culs-de-sac : chacun mène à quelque chose (position à ≤ 2 cases).
		quelque = {c for q in e.pos.values() if q.kind != "repere" for c in q.cells}
		nus = []
		for c in e.sol():
			voisins = sum(1 for dx, dy in DIRS if e.libre((c[0] + dx, c[1] + dy), set()))
			if voisins == 1 and c in d and not any(
					abs(c[0] - a[0]) + abs(c[1] - a[1]) <= 2 for a in quelque):
				nus.append(c)
		if nus:
			r.info(f"{n}F : culs-de-sac sans rien à moins de 2 cases (information) {nus}")


def sortie(e: Etage) -> Case:
	"""Fin de la route principale de l'étage : l'escalier du haut (6F : la case du SPECTRE)."""
	if e.n == 6:
		return e.pos["declencheur_spectre"].cells[0]
	return e.escalier_haut().cells[0]


def critere_dresseurs(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("5. Exorcistes : ids, prénoms, vues")
	vus_ids = set()
	for n, e in E.items():
		for ident, q in e.exorcistes.items():
			num = int(ident.rsplit("_", 1)[1]) if ident.startswith("tower_channeler_") else 0
			attendu = EXORCISTES.get(num)
			ok = (attendu is not None and attendu[0] == n and q.attrs.get("prenom") == attendu[1]
				and q.attrs.get("facing") in FACINGS and q.attrs.get("sight") in ("2", "3")
				and q.attrs.get("inevitable") == ("oui" if attendu[2] else "non")
				and len(q.cells) == 1 and q.bloque)
			r.critere(ok, f"{ident} {n}F {q.cells[0]} {q.attrs.get('prenom')} "
				f"facing={q.attrs.get('facing')} sight={q.attrs.get('sight')} "
				f"inevitable={q.attrs.get('inevitable')}")
			vus_ids.add(num)
			v = e.vue(q)
			r.critere(len(v) >= 2 and len(v) <= int(q.attrs["sight"]),
				f"{ident} : vue effective {len(v)} case(s) {v}")
			interdits = {c for s in e.escaliers.values() for c in s.cells}
			interdits |= {s.cells[0] for s in e.spawns.values()}
			interdits |= {c for s in e.pos.values() if s.kind == "objet_visible" for c in s.cells}
			r.critere(not (set(v) & interdits), f"{ident} : sa vue ne couvre ni arrivée, "
				"ni escalier, ni objet")
	r.critere(vus_ids == set(EXORCISTES), f"9 Exorcistes tower_channeler_1..9 : {sorted(vus_ids)}")
	for n, e in E.items():
		pnjs = [q for q in e.pos.values() if q.kind == "pnj"]
		if n in (2, 5):
			r.critere(len(pnjs) == 1 and pnjs[0].attrs.get("combat") == "non",
				f"{n}F : une Exorciste qui ne combat pas")
		else:
			r.critere(not pnjs, f"{n}F : aucun PNJ non combattant")


def critere_evitement(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("6. Inévitables inévitables, facultatives évitables")
	for n in (3, 4, 5, 6):
		e = E[n]
		d0, but = depart(e), sortie(e)
		base = e.distances([d0])
		r.critere(but in base, f"{n}F : sortie {but} atteinte depuis {d0} en {base.get(but)} pas")
		vues = {i: (e.vue(q), q) for i, q in e.exorcistes.items()}
		facultatives = [i for i, (_, q) in vues.items() if q.attrs["inevitable"] == "non"]
		inevitables = [i for i, (_, q) in vues.items() if q.attrs["inevitable"] == "oui"]
		for i in inevitables:
			v, q = vues[i]
			interdit = set(v) | set(q.cells)
			d = e.distances([d0], interdit)
			r.critere(but not in d, f"{n}F {i} INÉVITABLE : aucun chemin vers la sortie hors de "
				f"sa vue {v}")
			# Première case vue, en venant de l'arrivée : distance à l'Exorciste.
			rang = {c: k + 1 for k, c in enumerate(v)}
			premiere = min((rang[c] for c in rang if c in base and any(
				(c[0] + dx, c[1] + dy) in d for dx, dy in DIRS)), default=0)
			if premiere:
				r.info(f"   {i} : première case vue à {premiere} case(s) de l'Exorciste "
					"(passage étroit, vue latérale)")
		for i in facultatives:
			v, q = vues[i]
			d = e.distances([d0], set(v) | set(q.cells))
			r.critere(but in d, f"{n}F {i} évitable : chemin hors de sa vue en {d.get(but)} pas "
				f"(direct {base[but]})")
		if facultatives:
			tout = set()
			for i in facultatives:
				tout |= set(vues[i][0]) | set(vues[i][1].cells)
			d = e.distances([d0], tout)
			r.critere(but in d, f"{n}F : une route évite TOUTES les facultatives à la fois "
				f"({d.get(but)} pas)")
		# Objets : atteignables hors de toute vue des facultatives = information.
		for q in e.pos.values():
			if q.kind != "objet_visible":
				continue
			acces = [(q.cells[0][0] + dx, q.cells[0][1] + dy) for dx, dy in DIRS]
			fac = {i: vq for i, vq in vues.items() if vq[1].attrs["inevitable"] == "non"}
			hors_vue = [c for c in acces if c in e.distances([d0], interdits_toutes(e, fac))]
			r.critere(bool(hors_vue), f"{q.ident} ({q.attrs['item']}) : atteignable sans croiser "
				"la vue d'une facultative")


def interdits_toutes(e: Etage, vues) -> set[Case]:
	s: set[Case] = set()
	for v, q in vues.values():
		s |= set(v) | set(q.cells)
	return s


def vues_couvrant(e: Etage, vues, cases) -> set[str]:
	return {i for i, (v, _) in vues.items() if set(v) & set(cases)}


def critere_rival(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("7. Rival (2F) et SPECTRE (6F)")
	e = E[2]
	rival = e.pos["tower_rival"]
	trig = e.pos["declencheur_rival"]
	rc = rival.cells[0]
	r.critere(rival.attrs.get("inevitable") == "oui" and rival.bloque and rival.kind == "rival",
		f"rival {rc} inévitable, bloquant")
	r.critere(set(trig.cells) == {(15, 5), (14, 6)}, f"déclencheurs {trig.cells} = (15, 5), (14, 6)")
	r.critere(all(abs(c[0] - rc[0]) + abs(c[1] - rc[1]) == 1 for c in trig.cells),
		"chaque case de déclenchement est voisine du rival")
	d0, but = depart(e), sortie(e)
	d = e.distances([d0])
	r.critere(but not in d, "2F : rival en place, l'escalier du 3F n'est pas atteignable")
	# Seul passage : sans la case du rival, tout chemin passe par un déclenchement.
	libre = e.occupees - {rc}
	d_libre = e.distances([d0], set(), libre)
	r.critere(but in d_libre, "2F : escalier du 3F atteint une fois le rival parti")
	# Chemin évitant les deux cases de déclenchement ET la case du rival : doit être impossible.
	sans = e.distances([d0], set(trig.cells) | {rc}, libre)
	r.critere(but not in sans, "2F : aucun chemin vers l'escalier du 3F sans passer par une case de "
		"déclenchement du rival (il est sur le seul passage)")
	# Au moins un des deux déclenchements est effectivement emprunté selon le côté d'arrivée.
	for c in trig.cells:
		r.critere(c in d, f"2F : la case de déclenchement {c} est atteignable depuis l'arrivée")
	# Cases voisines de la case du rival hors déclenchement : toutes murées.
	libres = [(rc[0] + dx, rc[1] + dy) for dx, dy in DIRS
		if e.libre((rc[0] + dx, rc[1] + dy), set())]
	r.critere(sorted(libres) == sorted(list(trig.cells) + [(13, 5)]),
		f"voisines libres du rival = ses deux déclenchements + le couloir ouest (13, 5) {libres}")
	# Il repart par l'escalier du bas.
	reste = e.distances([rc], set(), libre)
	r.critere(e.escalier_bas().cells[0] in reste, "2F : le rival peut repartir par l'escalier du bas")

	e = E[6]
	trig = e.pos["declencheur_spectre"]
	recul = e.pos["recul_spectre"].cells[0]
	t = trig.cells[0]
	esc = e.escalier_haut().cells[0]
	d = e.distances([depart(e)])
	r.critere(esc in d, f"6F : l'escalier du 7F {esc} est atteint depuis l'arrivée (par le SPECTRE)")
	sans = e.distances([depart(e)], {t})
	r.critere(esc not in sans, f"6F : l'escalier du 7F inatteignable sans passer par la case du "
		f"SPECTRE {t}")
	voisins_esc = [(esc[0] + dx, esc[1] + dy) for dx, dy in DIRS if e.libre((esc[0] + dx, esc[1] + dy), set())]
	r.critere(voisins_esc == [t], f"6F : la case du SPECTRE est la seule voisine libre de l'escalier "
		f"{voisins_esc}")
	r.critere(abs(recul[0] - t[0]) + abs(recul[1] - t[1]) == 1 and e.car(recul) == "."
		and recul in d and recul != esc,
		f"6F : case de recul {recul} voisine du déclencheur, sol libre, atteignable")
	# Le recul s'éloigne de l'escalier (écart au dossier : « vers le sud » impossible ici).
	r.critere(abs(recul[0] - esc[0]) + abs(recul[1] - esc[1]) > abs(t[0] - esc[0]) + abs(t[1] - esc[1]),
		"6F : le recul s'éloigne de l'escalier du 7F")
	vues = [c for q in e.exorcistes.values() for c in e.vue(q)]
	r.critere(t not in vues and recul not in vues,
		"6F : ni le déclencheur ni le recul ne sont dans la vue d'un Dresseur")
	r.critere(e.pos["declencheur_spectre"].attrs.get("flag") == "ghost_marowak_calmed",
		"6F : drapeau ghost_marowak_calmed (posé au J20)")


def critere_zone(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("8. Zone purifiée (5F)")
	e = E[5]
	zone = e.pos["zone_purifiee"]
	z = set(zone.cells)
	car = set(e.plan.cells_of("Z"))
	xs, ys = sorted({c[0] for c in z}), sorted({c[1] for c in z})
	r.critere(z == car and len(z) == 4 and xs == [10, 11] and ys == [8, 9],
		f"2 × 2 en (10..11, 8..9), cases Z = position `zone` {sorted(z)}")
	r.critere(not z & e.occupees and all(c in accessibles(e) for c in z),
		"zone libre de tout personnage et atteignable")
	abords = {(c[0] + dx, c[1] + dy) for c in z for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
	touchees = [(i, sorted(set(e.vue(q)) & abords)) for i, q in e.exorcistes.items()
		if set(e.vue(q)) & abords]
	r.critere(not touchees, f"ni la zone ni ses abords (8 voisines) dans la vue d'un Dresseur "
		f"{touchees or ''}")
	cx, cy = (10 + 11) / 2, (8 + 9) / 2
	r.critere(abs(cx - 9.5) < 1.5 and abs(cy - 8.5) < 1.5, "zone au centre du 5F (centre de la carte (9,5 ; 8,5))")
	pnj = e.pos["exorciste_calme"]
	r.critere(any(abs(pnj.cells[0][0] - c[0]) + abs(pnj.cells[0][1] - c[1]) == 1 for c in z),
		f"l'Exorciste qui ne combat pas {pnj.cells[0]} est contre la zone")


def critere_objets(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("9. Objets visibles (dossier 22 §4.2)")
	total = 0
	for n in ETAGES:
		items = sorted(q.attrs["item"] for q in E[n].pos.values() if q.kind == "objet_visible")
		attendu = sorted(OBJETS.get(n, []))
		total += len(items)
		r.critere(items == attendu, f"{n}F : {items} (attendu {attendu})")
	r.critere(total == 5, f"total {total} objets visibles (3F 1, 4F 2, 5F 1, 6F 1)")


def critere_duree(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("10. Estimation de la montée 2F → 6F (information)")
	pas = 0
	for n in ETAGES:
		e = E[n]
		d = e.distances([depart(e)], occupees=e.occupees - {e.pos["tower_rival"].cells[0]}
			if n == 2 else None)
		pas += d[sortie(e)]
		r.info(f"{n}F : {d[sortie(e)]} pas (route directe, personnages en place)")
	nb = 4  # escaliers T23, T34, T45, T56
	combats = S_RIVAL + 3 * S_EXORCISTE_INEVITABLE + S_SPECTRE
	total = pas * S_PAR_PAS + nb * S_ESCALIER + combats
	r.info(f"{pas} pas + 4 escaliers + rival, 3 Exorcistes inévitables et SPECTRE ≈ "
		f"{total / 60:.1f} min, hors combats sauvages")


def encounters(r: Rapport, E: dict[int, Etage]) -> None:
	r.titre("Terrain `floor` (information)")
	for n in ETAGES:
		sol = [c for c in E[n].sol() if E[n].car(c) == "."]
		r.info(f"{n}F : {len(sol)} cases de rencontre, {len(E[n].sol()) - len(sol)} calmes (Z)")


def apercu(E: dict[int, Etage]) -> None:
	for n, e in E.items():
		print(f"\n=== {n}F (20 × 18) ===")
		grille = [list(row) for row in e.plan.rows]
		vue: set[Case] = set()
		for q in e.exorcistes.values():
			vue |= set(e.vue(q))
		for c in vue:
			if grille[c[1]][c[0]] == ".":
				grille[c[1]][c[0]] = "~"
		sym = {"dresseur": "E", "rival": "R", "pnj": "N", "objet_visible": "o", "spawn": "a",
			"declencheur": "!", "recul": "r"}
		for q in e.pos.values():
			s = sym.get(q.kind)
			if s is None:
				continue
			if q.kind == "dresseur":
				s = {"up": "^", "down": "v", "left": "<", "right": ">"}[q.attrs["facing"]]
				s = "E"
			for c in q.cells:
				grille[c[1]][c[0]] = s
		print("   " + "".join(str(x % 10) for x in range(LARGEUR)))
		for y, row in enumerate(grille):
			print(f"{y:2d} " + "".join(row))
		print("   # mur  . sol  T tombe  S stèle  Z zone  U/V escalier  ~ vue d'un Dresseur"
			"  E Exorciste  R rival  N PNJ  o objet  a arrivée  ! déclencheur  r recul")


def main() -> int:
	r = Rapport()
	E = charger(r)
	if E is None:
		print("\nÉCHEC")
		return 1
	critere_dimensions(r, E)
	critere_escaliers(r, E)
	critere_natures(r, E)
	critere_acces(r, E)
	critere_dresseurs(r, E)
	critere_evitement(r, E)
	critere_rival(r, E)
	critere_zone(r, E)
	critere_objets(r, E)
	critere_duree(r, E)
	encounters(r, E)
	if "--apercu" in sys.argv:
		apercu(E)
	print("\n" + ("OK" if r.ok else "ÉCHEC"))
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
