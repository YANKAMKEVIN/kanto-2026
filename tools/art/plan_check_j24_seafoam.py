#!/usr/bin/env python3
"""Vérifie les cinq étages des Îles Écume (jalon 24, T2 ; dossier 27 §6, §7 ; plan jalon-24 §2.6).

Grilles : `tools/plans/seafoam_1f.txt`, `seafoam_b1f.txt`, `seafoam_b2f.txt`, `seafoam_b3f.txt`,
`seafoam_b4f.txt` (30 × 18, coordonnées de RB). Lecture par `plan_grille.lire`. Le déplacement n'est
PAS celui de `plan_check.Monde` (qui lit « v » comme un rebord) : les Îles Écume ont leurs règles
(deux niveaux de sol, Surf, courants, rochers), codées ici sur un **graphe unique des cinq étages**
(plus les sorties vers la Route 20), comme `plan_check_mont_selenite.py` relie ses cartes.

Règles (dossier §5, §6.3, §7 ; collisions par paires de RB, voir `seafoam_rb_decode.py`) :
  - marche : 4 directions ; sol bas `.` et sol haut `:` ne se touchent pas ; l'escalier `=` touche
    les deux ; entrer dans une échelle (`U` `V`), un passage d'eau ou une case `E` transfère le joueur
    (on n'y reste pas) ; un trou non bouché (`O`) fait tomber au point d'atterrissage de l'étage
    du dessous ;
  - Surf (conditions réunies) : on monte sur l'eau `w` depuis le sol bas, un escalier ou une
    échelle (jamais depuis le sol haut) ; on en descend de même ; un rocher dans l'eau bloque ;
  - courant : entrer sur une case fléchée **active** emporte le joueur le long des flèches jusqu'à la
    fin (passage, escalier ou eau calme) ; actif tant que les deux trous de l'étage du dessus ne
    sont pas tous deux bouchés (B3F : trous du B2F ; B4F : trous du B3F) ;
  - escalier `surf_interdit` du B4F : on n'y monte pas en Surf tant que le courant 2 est actif ;
  - poussée (§6.3) : le joueur marche contre le rocher ; le rocher avance d'une case ; refus si la
    case suivante est un mur, de l'eau, un escalier, une échelle, une entrée, un changement de
    niveau de sol, un autre rocher, une case d'objet caché ou un occupant ; un trou la fait tomber
    (le trou est bouché pour de bon, drapeau posé) ;
  - état d'un étage (§7.3) : calculé des 8 drapeaux de chute (trous bouchés, rochers tombés aux
    points F, rochers d'origine moins les trous remplis, courants).

Critères (code 1 si l'un échoue) :
  a. fichiers, légende, échelles appariées, trous, points de chute, courants cohérents ;
  b. règles de poussée et de Surf (tests sur de petites grilles) ;
  c. anti-blocage exhaustif (§7.6) : tous les états de rochers obtenables par poussée, pour chaque
     configuration d'étage (celles des 256 combinaisons de drapeaux), depuis chaque arrivée : une
     sortie de l'étage reste atteignable (par des poussées au besoin : pas d'**impasse**, un état d'où
     aucune suite de poussées ne rejoint une échelle, un passage ou une entrée) ; sur le graphe
     entier, pour les 256 combinaisons, de toute position atteignable on sort du donjon ; en plus,
     **reprise d'une sauvegarde** faite sur n'importe quelle case debout (rochers revenus à leur
     place, §7.3) : un piège possible est signalé en [ATTENTION], sans faire échouer le contrôle ;
  d. solution complète (8 chutes) et rochers indispensables à Artikodin ;
  e. courant 1 (bassin du B3F → B4F, mer est) et courant 2 (salle d'Artikodin fermée) ;
  f. traversée entrée ouest → entrée est en Surf seul, sans Force (et l'inverse) ;
  g. objets cachés, Artikodin et panneaux atteignables ; aucune case praticable orpheline.

Usage : python3 -I tools/art/plan_check_j24_seafoam.py   (code 1 si un critère échoue)
Options : --rochers-derniers   diagnostic : B3F à l'ancienne règle « derniers de la liste » (la reprise
                               d'une sauvegarde sur le trou (3,16) bouché y est piégée) ;
          --plans <dossier>    lit les cinq grilles ailleurs (essais de mutation).
"""
from __future__ import annotations

import sys
import time
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS  # noqa: E402
from plan_grille import Plan, Position, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
ETAGES = ["1F", "B1F", "B2F", "B3F", "B4F"]
CARTES = {"1F": "seafoam_1f", "B1F": "seafoam_b1f", "B2F": "seafoam_b2f",
	"B3F": "seafoam_b3f", "B4F": "seafoam_b4f"}
ID_VERS_ETAGE = {v: k for k, v in CARTES.items()}
LARGEUR, HAUTEUR = 30, 18
# Trous : (étage, n), dans l'ordre des drapeaux du dossier §7.2.
TROUS = [(f, n) for f in ETAGES[:4] for n in (1, 2)]
FLECHES = {"^": (0, -1), "v": (0, 1), "<": (-1, 0), ">": (1, 0)}
NOMS_DIR = {(0, -1): "↑", (0, 1): "↓", (-1, 0): "←", (1, 0): "→"}
LEGENDE = set("#|.:=w~^v<>sBOFUVEonx")
MURS = set("#|~onx")
EAU_CARS = set("ws^v<>")
Noeud = tuple[str, int]


# Rochers libres du B3F quand des trous sont bouchés : « derniers de la liste » (dossier §7.3 ancien,
# diagnostic seulement, option --rochers-derniers) ou « désignés » (défaut, décision du 2026-10-16 : le
# rocher `trou=n` de chaque trou n bouché est retiré, quel que soit le rocher poussé).
REGLE_B3F = "designes"


def nom_drapeau(f: str, n: int) -> str:
	return f"seafoam_{f.lower()}_hole_{n}_filled"


def _case(texte: str) -> tuple[int, int]:
	x, y = texte.split(",")
	return int(x), int(y)


# ---------------------------------------------------------------------------------------------
# Un étage : lecture de la grille et des positions.
# ---------------------------------------------------------------------------------------------
class Etage:
	def __init__(self, nom: str, plan: Plan) -> None:
		self.nom = nom
		self.plan = plan
		self.L, self.H = plan.width, plan.height
		self.n = self.L * self.H
		self.car = [plan.rows[i // self.L][i % self.L] for i in range(self.n)]
		pos = plan.positions
		self.trous: dict[int, int] = {}            # n → case
		self.trou_de: dict[int, int] = {}          # case → n
		self.f_cases: dict[int, int] = {}          # n → case du point de chute du rocher
		self.f_eau: set[int] = set()
		self.atterrissages: dict[int, int] = {}    # n → case d'atterrissage du joueur
		self.atterr_surf: dict[int, bool] = {}
		self.rochers0: list[int] = []
		self.rocher_trou: dict[int, int] = {}
		self.objets: dict[int, Position] = {}
		self.statiques: set[int] = set()           # occupants fixes (Artikodin)
		self.interdits: set[int] = set()
		self.panneaux: dict[int, Position] = {}
		self.echelles: dict[int, Position] = {}
		self.passages: dict[int, Position] = {}
		self.entrees: dict[int, Position] = {}
		self.spawns: dict[str, int] = {}
		self.courants: dict[int, Position] = {}
		self.artikodin: Position | None = None
		for p in sorted(pos.values(), key=lambda q: q.ident):
			cases = [self.idx(c) for c in p.cells]
			k = p.kind
			if k == "trou":
				self.trous[int(p.attrs["n"])] = cases[0]
				self.trou_de[cases[0]] = int(p.attrs["n"])
			elif k == "chute_rocher":
				n = int(p.attrs["depuis"].split(":")[1])
				self.f_cases[n] = cases[0]
				if p.attrs["sol"] == "eau":
					self.f_eau.add(cases[0])
			elif k == "chute_joueur":
				n = int(p.attrs["depuis"].split(":")[1])
				self.atterrissages[n] = cases[0]
				self.atterr_surf[n] = p.attrs["surf"] == "oui"
			elif k == "rocher":
				self.rochers0.append(cases[0])
				if "trou" in p.attrs:
					self.rocher_trou[cases[0]] = int(p.attrs["trou"])
			elif k == "objet_cache":
				self.objets[cases[0]] = p
			elif k == "rencontre":
				self.statiques.add(cases[0])
				self.artikodin = p
			elif k == "surf_interdit":
				self.interdits.add(cases[0])
			elif k == "panneau":
				self.panneaux[cases[0]] = p
			elif k == "echelle":
				self.echelles[cases[0]] = p
			elif k == "passage":
				self.passages[cases[0]] = p
			elif k == "entree":
				for c in cases:
					self.entrees[c] = p
			elif k == "spawn":
				self.spawns[p.attrs["paire"]] = cases[0]
			elif k == "courant":
				self.courants[int(p.attrs["id"])] = p
		# Les rochers sont dans l'ordre de l'attribut `ordre`.
		ordre = {self.idx(p.cells[0]): int(p.attrs["ordre"]) for p in pos.values() if p.kind == "rocher"}
		self.rochers0.sort(key=lambda c: ordre[c])
		self.fleche = {i: FLECHES[c] for i, c in enumerate(self.car) if c in FLECHES}

	def idx(self, c: tuple[int, int]) -> int:
		return c[1] * self.L + c[0]

	def xy(self, i: int) -> tuple[int, int]:
		return i % self.L, i // self.L

	def eau(self, i: int) -> bool:
		c = self.car[i]
		return c in EAU_CARS or (c == "F" and i in self.f_eau)

	def mur(self, i: int) -> bool:
		return self.car[i] in MURS or self.car[i] not in LEGENDE

	def terminal_statique(self, i: int) -> bool:
		"""Cases où l'on est transféré en y entrant (échelle, passage, entrée)."""
		return i in self.echelles or i in self.passages or i in self.entrees

	def niveau(self, i: int) -> int:
		"""0 sol bas, 1 sol haut, 2 escalier, 3 transfert (compatible avec tout)."""
		c = self.car[i]
		if self.terminal_statique(i):
			return 3
		if c == ":":
			return 1
		if c == "=":
			return 2
		return 0

	def voisin(self, i: int, d: tuple[int, int]) -> int | None:
		x, y = self.xy(i)
		x, y = x + d[0], y + d[1]
		if 0 <= x < self.L and 0 <= y < self.H:
			return y * self.L + x
		return None


def compat(a: int, b: int) -> bool:
	return a >= 2 or b >= 2 or a == b


# ---------------------------------------------------------------------------------------------
# Graphe d'un étage pour une configuration (trous bouchés, courant) ; les rochers sont à part.
# ---------------------------------------------------------------------------------------------
class Graphe:
	def __init__(self, e: Etage, plugged: frozenset[int], courant: bool) -> None:
		self.e = e
		self.plugged = plugged
		self.courant = courant
		self.adj: dict[int, list[tuple[int, str]]] = {}
		self.terminaux: dict[int, tuple[str, object]] = {}
		self.glisse_cases: dict[int, list[int]] = {}   # source de glissade → cases traversées
		for i in range(e.n):
			if e.terminal_statique(i):
				kind = "echelle" if i in e.echelles else "passage" if i in e.passages else "entree"
				self.terminaux[i] = (kind, e.echelles.get(i) or e.passages.get(i) or e.entrees.get(i))
			elif i in e.trou_de and e.trou_de[i] not in plugged:
				self.terminaux[i] = ("trou", e.trou_de[i])
		for i in range(e.n):
			if e.mur(i) or i in e.statiques or i in self.terminaux:
				continue
			if courant and e.car[i] in FLECHES and e.eau(i):
				continue   # on ne s'arrête jamais sur une case de courant active
			liste = []
			for d in DIRECTIONS:
				t = e.voisin(i, d)
				if t is None or e.mur(t) or t in e.statiques:
					continue
				r = self._pas(i, t)
				if r is not None:
					liste.append(r)
			self.adj[i] = liste

	def _pas(self, i: int, t: int) -> tuple[int, str] | None:
		e = self.e
		depart_eau, arrivee_eau = e.eau(i), e.eau(t)
		if arrivee_eau:
			if not depart_eau:
				if e.niveau(i) == 1:                 # eau ↔ sol haut : collision par paires
					return None
				if i in e.interdits and self.courant:
					return None                      # T-14, SURFER refusé
				genre = "monte"
			else:
				genre = "nage"
		elif depart_eau:
			if e.niveau(t) == 1:
				return None
			genre = "descend"
		else:
			if not compat(e.niveau(i), e.niveau(t)):
				return None
			genre = "marche"
		if t in self.terminaux:
			return t, genre
		if self.courant and arrivee_eau and t in e.fleche:
			return self.glisse(t), "courant"
		return t, genre

	def glisse(self, t: int) -> int:
		"""Fin de la glissade qui commence sur la case fléchée t : une case (ou un terminal)."""
		e = self.e
		pos, vus, trace = t, set(), []
		while True:
			if pos in vus:
				raise ValueError(f"{e.nom} : boucle de courant en {e.xy(pos)}")
			vus.add(pos)
			trace.append(pos)
			if pos in self.terminaux:
				break
			d = e.fleche.get(pos)
			if d is None:
				break
			nxt = e.voisin(pos, d)
			if nxt is None or e.mur(nxt) or nxt in e.statiques:
				raise ValueError(f"{e.nom} : le courant bute en {e.xy(pos)}")
			if e.eau(nxt):
				pos = nxt
				continue
			trace.append(nxt)
			pos = nxt                                # débarquement sur la rive
			break
		self.glisse_cases[t] = trace
		return pos


_cache_graphes: dict[tuple, Graphe] = {}


def graphe(e: Etage, plugged: frozenset[int], courant: bool) -> Graphe:
	cle = (id(e), plugged, courant)
	if cle not in _cache_graphes:
		_cache_graphes[cle] = Graphe(e, plugged, courant)
	return _cache_graphes[cle]


# ---------------------------------------------------------------------------------------------
# Configuration d'un étage depuis les 8 drapeaux (dossier §7.3).
# ---------------------------------------------------------------------------------------------
def configuration(e: Etage, flags: frozenset[tuple[str, int]]) -> tuple[frozenset[int], frozenset[int], bool]:
	"""(rochers, trous bouchés, courant actif) de l'étage e pour l'ensemble de drapeaux `flags`."""
	f = e.nom
	i = ETAGES.index(f)
	plugged = frozenset(n for n in (1, 2) if (f, n) in flags)
	rocks: set[int] = set()
	if f == "1F":
		rocks = {c for c in e.rochers0 if (f, e.rocher_trou[c]) not in flags}
	elif f in ("B1F", "B2F"):
		haut = ETAGES[i - 1]
		rocks = {e.f_cases[n] for n in (1, 2) if (haut, n) in flags and (f, n) not in flags}
	elif f == "B3F":
		if REGLE_B3F == "designes":
			rocks = {c for c in e.rochers0 if e.rocher_trou.get(c) not in plugged}
		else:
			rocks = set(e.rochers0[:len(e.rochers0) - len(plugged)])
		rocks |= {e.f_cases[n] for n in (1, 2) if ("B2F", n) in flags}
	elif f == "B4F":
		rocks = {e.f_cases[n] for n in (1, 2) if ("B3F", n) in flags}
	courant = False
	if f == "B3F":
		courant = not all(("B2F", n) in flags for n in (1, 2))
	elif f == "B4F":
		courant = not all(("B3F", n) in flags for n in (1, 2))
	return frozenset(rocks), plugged, courant


# ---------------------------------------------------------------------------------------------
# Poussée d'un rocher (dossier §6.3).
# ---------------------------------------------------------------------------------------------
def destination_rocher(e: Etage, plugged: frozenset[int], rocks: frozenset[int], r: int,
		d: tuple[int, int]) -> tuple[str, int] | None:
	"""Ce qui arrive au rocher r poussé vers d : ("sol", case), ("trou", n) ou None (refus)."""
	c2 = e.voisin(r, d)
	if c2 is None or e.mur(c2) or e.eau(c2) or c2 in rocks or c2 in e.objets or c2 in e.statiques:
		return None
	if e.terminal_statique(c2) or e.niveau(c2) != 0:      # escalier, échelle, entrée, niveau de sol
		return None
	if c2 in e.trou_de and e.trou_de[c2] not in plugged:
		return "trou", e.trou_de[c2]
	return "sol", c2


def pousse_possible(e: Etage, plugged: frozenset[int], rocks: frozenset[int], r: int,
		d: tuple[int, int], p: int) -> bool:
	"""Le joueur en p (à pied) peut-il pousser le rocher r vers d ?"""
	if e.voisin(p, d) != r or e.eau(p) or e.niveau(p) == 3:
		return False
	if not compat(e.niveau(p), e.niveau(r)):              # le joueur doit pouvoir avancer en r
		return False
	return destination_rocher(e, plugged, rocks, r, d) is not None


# ---------------------------------------------------------------------------------------------
# Exploration locale : tous les états de rochers obtenables par poussée (anti-blocage).
# ---------------------------------------------------------------------------------------------
class Exploration:
	def __init__(self) -> None:
		self.etats = 0                  # composantes (état de rochers × zone du joueur)
		self.configs: set[tuple] = set()
		self.cellules: set[int] = set()
		self.sans_sortie: list[tuple] = []     # composantes sans sortie immédiate (sans nouvelle poussée)
		self.impasses: list[tuple] = []        # composantes d'où AUCUNE suite de poussées ne mène à une sortie
		self.sans_sortie_montante: int = 0
		self.meta: dict[tuple, tuple] = {}
		self.plugged_atteints: dict[frozenset[int], tuple] = {}
		self.terminaux: set[int] = set()
		self.rocheres: set[int] = set()         # cases où un rocher peut s'arrêter


def composante(g: Graphe, rocks: frozenset[int], depart: int) -> tuple[set[int], set[int]]:
	cellules = {depart}
	terms: set[int] = set()
	file = [depart]
	adj = g.adj
	while file:
		u = file.pop()
		for v, _ in adj.get(u, ()):
			if v in rocks:
				continue
			if v in g.terminaux:
				terms.add(v)
			elif v not in cellules:
				cellules.add(v)
				file.append(v)
	return cellules, terms


def explorer(e: Etage, plugged0: frozenset[int], rocks0: frozenset[int], courant: bool,
		departs: list[int], limite: int = 3_000_000) -> Exploration:
	"""Tous les états de rochers obtenables par poussée depuis les cases `departs`.

	Une composante est une zone où le joueur marche sans pousser. Elle est « sans sortie
	immédiate » si elle ne touche aucune échelle, aucun passage ni aucune entrée ; c'est une
	**impasse** si, de plus, aucune suite de poussées ne mène à une composante qui en a une
	(le joueur est alors bloqué : la case doit être retirée de la grille, §7.6.2)."""
	ex = Exploration()
	vus: dict[tuple, set[int]] = {}
	comps: dict[tuple, list[tuple[set[int], tuple]]] = {}
	file: deque = deque((rocks0, plugged0, s, None, None) for s in departs)
	aretes: dict[tuple, list[tuple]] = {}
	avec_sortie: set[tuple] = set()
	while file:
		rocks, plugged, joueur, prec, desc = file.popleft()
		cle_etat = (rocks, plugged)
		deja = vus.setdefault(cle_etat, set())
		if joueur in deja:
			continue
		g = graphe(e, plugged, courant)
		cellules, terms = composante(g, rocks, joueur)
		deja |= cellules
		ckey = (rocks, plugged, min(cellules))
		comps.setdefault(cle_etat, []).append((cellules, ckey))
		ex.etats += 1
		if ex.etats > limite:
			raise RuntimeError("exploration trop grande")
		ex.meta[ckey] = (prec, desc)
		ex.configs.add(cle_etat)
		ex.cellules |= cellules
		ex.terminaux |= terms
		ex.rocheres |= rocks
		ex.plugged_atteints.setdefault(plugged, ckey)
		sorties = [t for t in terms if g.terminaux[t][0] in ("echelle", "passage", "entree")]
		if sorties:
			avec_sortie.add(ckey)
		else:
			ex.sans_sortie.append(ckey)
		suites = aretes.setdefault(ckey, [])
		for r in rocks:
			for d in DIRECTIONS:
				p = e.voisin(r, (-d[0], -d[1]))
				if p is None or p not in cellules or not pousse_possible(e, plugged, rocks, r, d, p):
					continue
				dest = destination_rocher(e, plugged, rocks, r, d)
				assert dest is not None
				if dest[0] == "trou":
					nouveau = (rocks - {r}, plugged | {dest[1]})
					decrit = (r, d, f"trou {dest[1]}")
				else:
					nouveau = ((rocks - {r}) | {dest[1]}, plugged)
					decrit = (r, d, dest[1])
				suites.append((nouveau[0], nouveau[1], r))
				file.append((nouveau[0], nouveau[1], r, ckey, decrit))
	# Co-accessibilité : quelles composantes mènent (par des poussées) à une sortie ?
	inverse: dict[tuple, list[tuple]] = {}
	for ckey, suites in aretes.items():
		for rocks, plugged, p in suites:
			for cellules, autre in comps[(rocks, plugged)]:
				if p in cellules:
					inverse.setdefault(autre, []).append(ckey)
					break
	bons = set(avec_sortie)
	file2 = deque(avec_sortie)
	while file2:
		c = file2.popleft()
		for src in inverse.get(c, ()):
			if src not in bons:
				bons.add(src)
				file2.append(src)
	ex.impasses = [c for c in aretes if c not in bons]
	return ex


def chemin_pousses(e: Etage, ex: Exploration, ckey: tuple) -> list[tuple]:
	pousses = []
	while ckey is not None:
		prec, desc = ex.meta[ckey]
		if desc is not None:
			pousses.append(desc)
		ckey = prec
	pousses.reverse()
	return pousses


def texte_pousses(e: Etage, pousses: list[tuple]) -> str:
	"""« (5,14) ←← · (9,14) ↑↑ … » : un groupe par rocher et par direction."""
	groupes: list[list] = []
	for r, d, dest in pousses:
		if groupes and groupes[-1][0] == d and groupes[-1][2] == r and isinstance(groupes[-1][3], int):
			groupes[-1][1] += 1
			groupes[-1][2] = e.voisin(r, d) if isinstance(dest, int) else None
			groupes[-1][3] = dest
			continue
		groupes.append([d, 1, e.voisin(r, d) if isinstance(dest, int) else None, dest, r])
	morceaux = []
	for g in groupes:
		d, k, _, dest, depart = g
		fin = f" → {dest}" if not isinstance(dest, int) else ""
		morceaux.append(f"{e.xy(depart)} {NOMS_DIR[d] * k}{fin}")
	return " · ".join(morceaux)


# ---------------------------------------------------------------------------------------------
# Graphe unique des cinq étages.
# ---------------------------------------------------------------------------------------------
class Donjon:
	def __init__(self, etages: dict[str, Etage]) -> None:
		self.e = etages
		self.arrivees: dict[tuple[str, str], int] = {}     # (étage, paire) → case
		for nom, e in etages.items():
			for paire, c in e.spawns.items():
				self.arrivees[(nom, paire)] = c

	def config(self, nom: str, flags) -> tuple[Graphe, frozenset[int]]:
		rocks, plugged, courant = configuration(self.e[nom], flags)
		return graphe(self.e[nom], plugged, courant), rocks

	def placer(self, nom: str, c: int, flags, trace: list[str]):
		"""Le joueur arrive en c sur l'étage nom ; applique le courant s'il y a lieu.
		Retourne ("noeud", nom, case) ou ("sortie", cote)."""
		g, _ = self.config(nom, flags)
		if g.courant and c in g.e.fleche and g.e.eau(c):
			trace.append(f"courant {nom} ({g.e.xy(c)[0]},{g.e.xy(c)[1]})")
			c = g.glisse(c)
		if c in g.terminaux:
			return self.terminal(nom, c, flags, trace, g)
		return ("noeud", nom, c)

	def terminal(self, nom: str, c: int, flags, trace: list[str], g: Graphe | None = None,
			chutes: bool = True):
		g = g or self.config(nom, flags)[0]
		kind, pos = g.terminaux[c]
		e = self.e[nom]
		if kind == "entree":
			return ("sortie", pos.attrs["cote"])
		if kind == "trou":
			if not chutes:
				return None
			bas = ETAGES[ETAGES.index(nom) + 1]
			trace.append(f"chute {nom} trou {pos}")
			return self.placer(bas, self.e[bas].atterrissages[pos], flags, trace)
		paire = pos.attrs["paire"]
		vers = ID_VERS_ETAGE[pos.attrs["vers"]]
		if (vers, paire) not in self.arrivees:
			return None
		trace.append(f"{'échelle' if kind == 'echelle' else 'passage'} {paire} {nom}→{vers}")
		return self.placer(vers, self.arrivees[(vers, paire)], flags, trace)

	def successeurs(self, n: Noeud, flags, chutes: bool = True):
		nom, c = n
		g, rocks = self.config(nom, flags)
		for v, genre in g.adj.get(c, ()):
			if v in rocks:
				continue
			trace: list[str] = []
			if v in g.terminaux:
				r = self.terminal(nom, v, flags, trace, g, chutes)
			elif genre == "courant":
				r = ("noeud", nom, v)
				trace.append("courant")
			else:
				r = ("noeud", nom, v)
			if r is None:
				continue
			if r[0] == "sortie":
				yield "SORTIE:" + r[1], genre, trace
			else:
				yield (r[1], r[2]), genre, trace

	def atteignables(self, flags, departs: list[Noeud], chutes: bool = True):
		dist = {d: 0 for d in departs}
		parent: dict = {}
		sorties: dict[str, Noeud] = {}
		file = deque(departs)
		while file:
			n = file.popleft()
			for v, genre, trace in self.successeurs(n, flags, chutes):
				if isinstance(v, str):
					if v not in sorties:
						sorties[v] = n
						parent[v] = (n, genre, trace)
					continue
				if v not in dist:
					dist[v] = dist[n] + 1
					parent[v] = (n, genre, trace)
					file.append(v)
		return dist, parent, sorties

	def chemin(self, parent: dict, fin) -> list[tuple]:
		etapes = []
		while fin in parent:
			prec, genre, trace = parent[fin]
			etapes.append((prec, fin, genre, trace))
			fin = prec
		etapes.reverse()
		return etapes

	def departs_entrees(self) -> dict[str, Noeud]:
		e = self.e["1F"]
		return {"ouest": ("1F", e.spawns["EO"]), "est": ("1F", e.spawns["EE"])}


# ---------------------------------------------------------------------------------------------
# Rapport.
# ---------------------------------------------------------------------------------------------
class Rapport:
	def __init__(self) -> None:
		self.ok = True
		self.attentions = 0

	def titre(self, texte: str) -> None:
		print(f"\n{texte}")

	def critere(self, vrai: bool, texte: str) -> bool:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")
		return bool(vrai)

	def info(self, texte: str) -> None:
		print(f"  {texte}")

	def attention(self, texte: str) -> None:
		self.attentions += 1
		print(f"  [ATTENTION] {texte}")


def charger() -> dict[str, Etage]:
	return {nom: Etage(nom, lire(PLANS / f"{CARTES[nom]}.txt")) for nom in ETAGES}


def pt(e: Etage, i: int) -> str:
	x, y = e.xy(i)
	return f"({x},{y})"


# ---------------------------------------------------------------------------------------------
# a. Structure.
# ---------------------------------------------------------------------------------------------
def verifier_structure(r: Rapport, etages: dict[str, Etage], donjon: Donjon) -> None:
	r.titre("a. Fichiers, légende, échelles appariées, trous, chutes, courants")
	erreurs: list[str] = []
	for nom, e in etages.items():
		if (e.L, e.H) != (LARGEUR, HAUTEUR):
			erreurs.append(f"{nom} : {e.L} × {e.H} au lieu de {LARGEUR} × {HAUTEUR}")
		inconnus = sorted({c for c in e.car if c not in LEGENDE})
		if inconnus:
			erreurs.append(f"{nom} : caractères hors légende {inconnus}")
		pratiq = set(e.plan.praticables)
		if not set(".:=wBOFs^v<>UVE") <= pratiq:
			erreurs.append(f"{nom} : ligne PRATICABLES incomplète")
	r.critere(not erreurs, f"5 grilles de {LARGEUR} × {HAUTEUR} (1:1 avec RB), légende respectée {erreurs}")

	# Échelles, passages, entrées : correspondance grille ↔ positions.
	erreurs = []
	for nom, e in etages.items():
		for char, table in (("U", e.echelles), ("V", e.echelles), ("E", e.entrees)):
			cases = {i for i, c in enumerate(e.car) if c == char}
			ici = {i for i in table if e.car[i] == char}
			if cases != ici:
				erreurs.append(f"{nom} : cases « {char} » {sorted(pt(e, i) for i in cases ^ ici)} sans position")
		for i, p in e.echelles.items():
			attendu = "V" if p.attrs["sens"] == "descend" else "U"
			bas = ETAGES.index(ID_VERS_ETAGE[p.attrs["vers"]]) > ETAGES.index(nom)
			if e.car[i] != attendu or (p.attrs["sens"] == "descend") != bas:
				erreurs.append(f"{nom} {p.ident} : sens {p.attrs['sens']} incohérent avec la grille ou l'étage visé")
		for i, p in e.passages.items():
			if not e.eau(i):
				erreurs.append(f"{nom} {p.ident} : un passage d'eau doit être sur de l'eau")
	# Appariement : chaque échelle a son arrivée (voisine) et sa jumelle sur l'autre carte.
	for nom, e in etages.items():
		for table in (e.echelles, e.passages):
			for i, p in table.items():
				vers = ID_VERS_ETAGE[p.attrs["vers"]]
				paire = p.attrs["paire"]
				autre = etages[vers]
				if paire not in autre.spawns:
					erreurs.append(f"{nom} {p.ident} : pas d'arrivée « {paire} » sur {vers}")
					continue
				arrivee = autre.spawns[paire]
				if paire != "W1":   # W1 : sens unique, la jumelle n'existe pas
					jumelles = [q for q in list(autre.echelles.values()) + list(autre.passages.values())
						if q.attrs["paire"] == paire and ID_VERS_ETAGE[q.attrs["vers"]] == nom]
					if len(jumelles) != 1:
						erreurs.append(f"{nom} {p.ident} : {len(jumelles)} jumelle(s) sur {vers}")
					elif jumelles[0].attrs["sens"] == p.attrs["sens"]:
						erreurs.append(f"{nom} {p.ident} : sens identique à sa jumelle")
				if autre.mur(arrivee) or arrivee in autre.terminal_statique_set():
					erreurs.append(f"{vers} arrivée {paire} : case non praticable")
		for paire, s in e.spawns.items():
			tout = {**e.echelles, **e.passages, **e.entrees}
			voisins = [t for t in (e.voisin(s, d) for d in DIRECTIONS) if t in tout
				and tout[t].attrs.get("paire") == paire]
			if paire not in ("W1", "W2") and not voisins:
				erreurs.append(f"{nom} arrivée {paire} {pt(e, s)} : pas contre son échelle")
			if s in e.rochers0:
				erreurs.append(f"{nom} arrivée {paire} : sur un rocher d'origine")
	r.critere(not erreurs, f"échelles et passages : tous appariés (sens, arrivée voisine, jumelle) {erreurs}")
	n_ech = sum(len(e.echelles) for e in etages.values())
	r.info(f"{n_ech} échelles (12 paires = 24 bouts), 2 passages d'eau (W1 sens unique, W2), 4 cases d'entrée")

	# Cartes fermées : le bord est la limite du monde ; seules les cases E sortent.
	bords = {nom: sum(1 for i, c in enumerate(e.car) if (i % e.L in (0, e.L - 1) or i // e.L in (0, e.H - 1))
		and not e.mur(i)) for nom, e in etages.items()}
	sorties_ok = {i for i, c in enumerate(etages["1F"].car) if c == "E"}
	autres_e = {nom: sum(1 for c in e.car if c == "E") for nom, e in etages.items() if nom != "1F"}
	r.critere(len(sorties_ok) == 4 and not any(autres_e.values()),
		"cartes fermées : seules les 4 cases E du 1F sortent de la grotte ; le bord est la limite du monde "
		f"(cases de sol ou d'eau au bord, comme RB : {bords})")

	# Trous, points de chute, atterrissages.
	erreurs = []
	for nom in ETAGES[:4]:
		e, bas = etages[nom], etages[ETAGES[ETAGES.index(nom) + 1]]
		trous_grille = sorted(i for i, c in enumerate(e.car) if c == "O")
		if trous_grille != sorted(e.trous.values()) or sorted(e.trous) != [1, 2]:
			erreurs.append(f"{nom} : trous de la grille et positions différents")
		if [e.xy(e.trous[1])[0], e.xy(e.trous[2])[0]] != sorted(e.xy(e.trous[n])[0] for n in (1, 2)):
			erreurs.append(f"{nom} : trou 1 n'est pas le plus à l'ouest")
		for n in (1, 2):
			p = next(q for q in e.plan.positions.values() if q.kind == "trou" and q.attrs["n"] == str(n))
			if p.attrs["drapeau"] != nom_drapeau(nom, n) or ID_VERS_ETAGE[p.attrs["chute"]] != bas.nom:
				erreurs.append(f"{nom} trou {n} : drapeau ou étage visé incohérent")
			if bas.f_cases.get(n) is None or bas.car[bas.f_cases[n]] != "F":
				erreurs.append(f"{bas.nom} : point de chute F {n} absent")
			if n not in bas.atterrissages:
				erreurs.append(f"{bas.nom} : atterrissage {n} absent")
			else:
				a = bas.atterrissages[n]
				if bas.mur(a) or (bas.atterr_surf[n] != bas.eau(a)):
					erreurs.append(f"{bas.nom} : atterrissage {n} {pt(bas, a)} (surf={bas.atterr_surf[n]}) incohérent avec le terrain")
				if bas.eau(bas.f_cases[n]) != (bas.f_cases[n] in bas.f_eau):
					erreurs.append(f"{bas.nom} : sol= du point de chute {n}")
			if bas.f_cases.get(n) in bas.f_eau and not any(
					bas.eau(t) for t in (bas.voisin(bas.f_cases[n], d) for d in DIRECTIONS) if t is not None):
				erreurs.append(f"{bas.nom} : point de chute {n} dans l'eau sans eau autour")
	cases_f = {nom: sorted(i for i, c in enumerate(e.car) if c == "F") for nom, e in etages.items()}
	for nom in ETAGES[1:]:
		e = etages[nom]
		if cases_f[nom] != sorted(e.f_cases.values()):
			erreurs.append(f"{nom} : cases F et points de chute différents")
	if cases_f["1F"]:
		erreurs.append("1F : un point de chute F n'a pas d'étage au-dessus")
	r.critere(not erreurs, f"8 trous (drapeaux du dossier §7.2), 8 points de chute et 8 atterrissages {erreurs}")

	# Rochers d'origine : 1F : 2 ; B3F : 4 ; sur sol bas ; pas d'autre « B ».
	erreurs = []
	attendus = {"1F": 2, "B1F": 0, "B2F": 0, "B3F": 4, "B4F": 0}
	for nom, e in etages.items():
		cases_b = sorted(i for i, c in enumerate(e.car) if c == "B")
		if cases_b != sorted(e.rochers0) or len(cases_b) != attendus[nom]:
			erreurs.append(f"{nom} : rochers d'origine {len(cases_b)} (attendu {attendus[nom]})")
	for i, n in etages["1F"].rocher_trou.items():
		pass
	if sorted(etages["1F"].rocher_trou.values()) != [1, 2]:
		erreurs.append("1F : chaque rocher doit désigner son trou (trou=1, trou=2)")
	r.critere(not erreurs, f"rochers d'origine : 1F 2, B3F 4 (positions RB), aucun ailleurs {erreurs}")

	# Courants : flèches sur l'eau, trajets finis, sources, fin déclarée.
	erreurs = []
	for nom, e in etages.items():
		for i in e.fleche:
			if not e.eau(i):
				erreurs.append(f"{nom} : flèche hors de l'eau {pt(e, i)}")
	resume = []
	for nom, ident, fin_attendue in (("B3F", 1, "passage"), ("B4F", 2, "escalier")):
		e = etages[nom]
		g = graphe(e, frozenset(), True)
		p = e.courants[ident]
		fin_declaree = p.attrs["fin"]
		fins = set()
		couvertes: set[int] = set()
		for s in (e.idx(c) for c in p.cells):
			f = g.glisse(s)
			couvertes |= set(g.glisse_cases[s])
			fins.add(f)
		fleches = set(e.fleche)
		for i in fleches - couvertes:
			erreurs.append(f"{nom} : flèche {pt(e, i)} hors de tout trajet du courant {ident}")
		if len(fins) != 1:
			erreurs.append(f"{nom} courant {ident} : plusieurs fins {sorted(pt(e, f) for f in fins)}")
			continue
		f = next(iter(fins))
		if fin_attendue == "passage":
			bon = f in e.passages and fin_declaree == f"passage:{e.passages[f].attrs['paire']}"
		else:
			x, y = e.xy(f)
			bon = e.car[f] == "=" and fin_declaree == f"escalier:{x},{y}"
		if not bon:
			erreurs.append(f"{nom} courant {ident} : fin {pt(e, f)} ≠ « {fin_declaree} »")
		resume.append(f"courant {ident} ({nom}) : {len(fleches)} cases fléchées, {len(p.cells)} sources, fin {pt(e, f)}")
	r.critere(not erreurs, f"courants : flèches sur l'eau, trajets finis, une seule fin, tous les cases fléchées utiles {erreurs}")
	for t in resume:
		r.info(t)

	# Objets cachés : sol calme, indice x contre l'objet, un indice par objet.
	erreurs = []
	total_x = 0
	for nom, e in etages.items():
		indices = [i for i, c in enumerate(e.car) if c == "x"]
		total_x += len(indices)
		for i, p in e.objets.items():
			voisins_x = [t for t in (e.voisin(i, d) for d in DIRECTIONS) if t is not None and e.car[t] == "x"]
			if e.car[i] not in ".:" or e.eau(i) or not voisins_x:
				erreurs.append(f"{nom} {p.ident} {pt(e, i)} : sol « {e.car[i]} », indice x {voisins_x}")
		if len(indices) != len(e.objets):
			erreurs.append(f"{nom} : {len(indices)} indice(s) x pour {len(e.objets)} objet(s)")
	r.critere(not erreurs and total_x == 3, f"3 objets cachés (Pépite B2F, Max Élixir B3F, Hyper Ball B4F), chacun sur sol calme "
		f"avec son indice x contre lui {erreurs}")
	# Panneaux, Artikodin.
	erreurs = []
	for nom, e in etages.items():
		cases_n = {i for i, c in enumerate(e.car) if c == "n"}
		if cases_n != set(e.panneaux):
			erreurs.append(f"{nom} : panneaux de la grille et positions différents")
	b4 = etages["B4F"]
	textes = sorted(p.attrs["texte"] for e in etages.values() for p in e.panneaux.values())
	if textes != ["T-11"] * 4 + ["T-12", "T-13"]:
		erreurs.append(f"panneaux {textes} (attendu 4 × T-11, T-12, T-13)")
	if b4.artikodin is None or b4.car[next(iter(b4.statiques))] != ":":
		erreurs.append("Artikodin : absent ou pas sur du sol haut")
	r.critere(not erreurs, f"panneaux : 4 × T-11 (étages à rochers), T-12 et T-13 (B4F) ; Artikodin posé dans sa salle {erreurs}")


def _terminal_statique_set(self: Etage) -> set[int]:
	return set(self.echelles) | set(self.passages) | set(self.entrees)


Etage.terminal_statique_set = _terminal_statique_set   # type: ignore[attr-defined]


# ---------------------------------------------------------------------------------------------
# b. Règles : tests sur de petites grilles.
# ---------------------------------------------------------------------------------------------
def mini_etage(rangs: list[str], positions: list[Position] | None = None) -> Etage:
	plan = Plan(len(rangs[0]), len(rangs), rangs, {p.ident: p for p in positions or []},
		set(".:=wBOFs^v<>UVE"))
	# Les rochers de la mini-grille (B) sont des rochers d'origine ordonnés par lecture.
	cases = [(x, y) for y, row in enumerate(rangs) for x, c in enumerate(row) if c == "B"]
	for k, c in enumerate(cases):
		plan.positions[f"r{k}"] = Position(f"r{k}", "rocher", [c], True, "", {"ordre": str(k)})
	return Etage("mini", plan)


def verifier_regles(r: Rapport) -> None:
	r.titre("b. Règles de poussée (§6.3) et de Surf (§5), sur de petites grilles")
	erreurs: list[str] = []

	def pousse(rangs: list[str], depart: tuple[int, int], direction: tuple[int, int],
			positions: list[Position] | None = None, plugged=frozenset()):
		e = mini_etage(rangs, positions)
		rocks = frozenset(e.rochers0)
		joueur = e.idx(depart)
		r_i = e.voisin(joueur, direction)
		rocher = r_i
		if rocher not in rocks:
			return "pas de rocher"
		if not pousse_possible(e, plugged, rocks, rocher, direction, joueur):
			return "refus"
		d = destination_rocher(e, plugged, rocks, rocher, direction)
		return d[0] if d else "refus"

	def attendre(nom: str, obtenu, voulu) -> None:
		if obtenu != voulu:
			erreurs.append(f"{nom} : {obtenu} au lieu de {voulu}")

	E = (1, 0)
	attendre("rocher → sol libre", pousse(["#.B.#"], (1, 0), E), "sol")
	attendre("rocher → mur", pousse(["#.B#"], (1, 0), E), "refus")
	attendre("rocher → arête", pousse(["#.B|"], (1, 0), E), "refus")
	attendre("rocher → eau", pousse(["#.Bw#"], (1, 0), E), "refus")
	attendre("rocher → eau (case de courant)", pousse(["#.B>#"], (1, 0), E), "refus")
	attendre("rocher → escalier", pousse(["#.B=."], (1, 0), E), "refus")
	attendre("rocher → échelle", pousse(["#.BU."], (1, 0), E,
		[Position("u", "echelle", [(3, 0)], False, "", {"paire": "X", "sens": "monte", "vers": "seafoam_1f"})]), "refus")
	attendre("rocher → entrée", pousse(["#.BE."], (1, 0), E,
		[Position("e", "entree", [(3, 0)], False, "", {"cote": "ouest"})]), "refus")
	attendre("rocher → changement de niveau (sol haut)", pousse(["#.B:."], (1, 0), E), "refus")
	attendre("rocher → autre rocher", pousse(["#.BB."], (1, 0), E), "refus")
	attendre("rocher → case d'objet caché", pousse(["#.B.x"], (1, 0), E,
		[Position("o", "objet_cache", [(3, 0)], False, "", {"item": "x"})]), "refus")
	attendre("rocher → panneau", pousse(["#.Bn."], (1, 0), E), "refus")
	attendre("rocher → occupant (Artikodin)", pousse(["#.B:."], (1, 0), E,
		[Position("a", "rencontre", [(3, 0)], True, "", {})]), "refus")
	attendre("rocher → trou", pousse(["#.BO."], (1, 0), E,
		[Position("t", "trou", [(3, 0)], False, "", {"n": "1"})]), "trou")
	attendre("rocher → trou bouché (devient du sol)", pousse(["#.BO."], (1, 0), E,
		[Position("t", "trou", [(3, 0)], False, "", {"n": "1"})], plugged=frozenset({1})), "sol")
	attendre("joueur sur sol haut, rocher sur sol bas (changement de niveau)", pousse([":B."], (0, 0), E), "refus")
	attendre("joueur sur escalier, rocher sur sol bas", pousse(["=B."], (0, 0), E), "sol")
	attendre("joueur dans l'eau ne pousse pas", pousse(["wB."], (0, 0), E), "refus")

	# Surf : monter et descendre.
	def adj(rangs: list[str], depart: tuple[int, int], arrivee: tuple[int, int], courant=False,
			positions: list[Position] | None = None):
		e = mini_etage(rangs, positions)
		g = Graphe(e, frozenset(), courant)
		a, b = e.idx(depart), e.idx(arrivee)
		return any(v == b for v, _ in g.adj.get(a, ()))

	attendre("monter en Surf depuis le sol bas", adj([".w"], (0, 0), (1, 0)), True)
	attendre("monter en Surf depuis un escalier", adj(["=w"], (0, 0), (1, 0)), True)
	attendre("monter en Surf depuis le sol haut (refus)", adj([":w"], (0, 0), (1, 0)), False)
	attendre("descendre sur le sol bas", adj(["w."], (0, 0), (1, 0)), True)
	attendre("descendre sur un escalier", adj(["w="], (0, 0), (1, 0)), True)
	attendre("descendre sur le sol haut (refus)", adj(["w:"], (0, 0), (1, 0)), False)
	attendre("traverser de l'eau", adj(["ww"], (0, 0), (1, 0)), True)
	attendre("marcher sur un mur (refus)", adj([".#"], (0, 0), (1, 0)), False)
	attendre("bas → haut à pied (refus)", adj([".:"], (0, 0), (1, 0)), False)
	attendre("bas → escalier → haut", adj([".=:"], (0, 0), (1, 0)) and adj([".=:"], (1, 0), (2, 0)), True)
	interdit = [Position("i", "surf_interdit", [(0, 0)], False, "", {"tant_que": "courant_2"})]
	attendre("escalier interdit au Surf, courant actif", adj(["=w"], (0, 0), (1, 0), True, interdit), False)
	attendre("escalier interdit au Surf, courant calme", adj(["=w"], (0, 0), (1, 0), False, interdit), True)
	# Courant : glissade jusqu'à la fin ; calme = eau ordinaire.
	e = mini_etage([".>>v", "###w"])
	g = Graphe(e, frozenset(), True)
	attendre("courant actif : on est emporté jusqu'à la fin", [e.xy(v) for v, _ in g.adj[e.idx((0, 0))]], [(3, 1)])
	g2 = Graphe(e, frozenset(), False)
	attendre("courant calme : on entre sur la case fléchée comme sur de l'eau",
		[e.xy(v) for v, _ in g2.adj[e.idx((0, 0))]], [(1, 0)])
	# Débarquement à la fin d'un courant : l'escalier.
	e = mini_etage(["w>=:"])
	g = Graphe(e, frozenset(), True)
	attendre("courant : la glissade se termine sur la rive", [e.xy(v) for v, _ in g.adj[e.idx((0, 0))]], [(2, 0)])
	r.critere(not erreurs, f"règles de poussée et de Surf : {len(erreurs)} écart(s) {erreurs}")


# ---------------------------------------------------------------------------------------------
# c. Anti-blocage.
# ---------------------------------------------------------------------------------------------
def configs_distinctes(etages: dict[str, Etage], nom: str):
	"""Pour un étage : les configurations (rochers, trous bouchés, courant) des 256 combinaisons."""
	vues: dict[tuple, frozenset] = {}
	for masque in range(256):
		flags = frozenset(t for k, t in enumerate(TROUS) if masque >> k & 1)
		vues.setdefault(configuration(etages[nom], flags), flags)
	return vues


def verifier_anti_blocage(r: Rapport, etages: dict[str, Etage], donjon: Donjon,
		coutes: dict[str, Exploration]) -> None:
	r.titre("c. Anti-blocage exhaustif (§7.6)")
	t0 = time.time()
	total_etats = 0
	for nom in ETAGES:
		e = etages[nom]
		toutes = configs_distinctes(etages, nom)
		departs = sorted(set(e.spawns.values()) | set(e.atterrissages.values()))
		departs = [d for d in departs if not e.eau(d) or True]
		fautes = []
		fautes_reprise: list = []
		reprises: list[int] = []
		stats = []
		for (rocks, plugged, courant), flags in sorted(toutes.items(), key=lambda t: (sorted(t[0][1]), sorted(t[0][0]), t[0][2])):
			# Départs : les arrivées de l'étage qui ne sont pas sur un rocher ; l'atterrissage sur
			# une case de courant actif est résolu par la glissade.
			g = graphe(e, plugged, courant)
			starts: list[int] = []
			for s in departs:
				if s in rocks:
					continue
				if courant and s in e.fleche and e.eau(s):
					s = g.glisse(s)
				if s in g.terminaux or s in rocks:
					continue
				starts.append(s)
			if nom == "1F":
				starts += [s for s in (e.spawns["EO"], e.spawns["EE"]) if s not in starts]
			ex = explorer(e, plugged, rocks, courant, starts)
			# Reprise d'une sauvegarde : le joueur peut être n'importe où sur une case debout, les
			# rochers étant revenus à leur place (§7.3).
			toutes_cases = [c for c in g.adj if c not in rocks]
			ex_reprise = explorer(e, plugged, rocks, courant, toutes_cases)
			reprises.append(len(ex_reprise.impasses))
			if ex_reprise.impasses:
				fautes_reprise.append((sorted(plugged), [pt(e, c) for c in sorted(rocks)],
					[(sorted(pt(e, i) for i in k[0]), pt(e, k[2])) for k in ex_reprise.impasses[:2]]))
			total_etats += ex.etats + ex_reprise.etats
			coutes[(nom, rocks, plugged, courant)] = ex
			if ex.impasses:
				fautes.append((sorted(plugged), [pt(e, c) for c in sorted(rocks)],
					[(sorted(pt(e, i) for i in k[0]), pt(e, k[2])) for k in ex.impasses[:2]]))
			stats.append(f"{len(rocks)} rocher(s), trous bouchés {sorted(plugged)}, courant {'oui' if courant else 'non'} : "
				f"{len(ex.configs)} configurations de rochers, {ex.etats} états, "
				f"{len(ex.sans_sortie)} sans sortie immédiate, {len(ex.impasses)} impasse(s)")
		r.critere(not fautes, f"{nom} : {len(toutes)} configuration(s) d'étage, de toute position atteignable par poussée, une "
			f"sortie de l'étage (échelle, passage d'eau ou entrée) reste atteignable (aucune impasse) {fautes[:2]}")
		for s in stats:
			r.info("    " + s)
		if fautes_reprise:
			r.attention(f"{nom} : reprise d'une sauvegarde faite sur une case enfermée par les rochers revenus à leur place "
				f"(rochers de départ, trous bouchés, composantes piégées) {fautes_reprise[:2]} : prévoir le garde-fou de reprise "
				f"(§5.7) (ancienne règle « derniers » : option --rochers-derniers)")
		else:
			r.critere(True, f"{nom} : reprise d'une sauvegarde faite n'importe où dans l'étage (rochers revenus à leur place) : "
				"aucune impasse non plus, depuis chaque case debout (aucun joueur piégé)")
	r.info(f"{total_etats} états (rochers × zone du joueur) explorés en {time.time() - t0:.1f} s")
	return None


def verifier_graphe_entier(r: Rapport, etages: dict[str, Etage], donjon: Donjon) -> dict:
	"""Pour chacune des 256 combinaisons de drapeaux : de toute position atteignable, on sort."""
	r.titre("c bis. Graphe des cinq étages : de toute position atteignable, une sortie du donjon (256 combinaisons)")
	departs = list(donjon.departs_entrees().values())
	cases_vues: set[Noeud] = set()
	pires = []
	nb_nodes = 0
	for masque in range(256):
		flags = frozenset(t for k, t in enumerate(TROUS) if masque >> k & 1)
		dist, parent, sorties = donjon.atteignables(flags, departs)
		# Arrivées possibles (échelles, atterrissages) : le joueur peut s'y trouver.
		tous = set(dist)
		for nom, e in etages.items():
			for c in list(e.spawns.values()) + list(e.atterrissages.values()):
				g, rocks = donjon.config(nom, flags)
				trace: list[str] = []
				res = donjon.placer(nom, c, flags, trace)
				if res[0] == "noeud":
					tous.add((res[1], res[2]))
		# Fermeture inverse : qui atteint une sortie ?
		succ = {}
		pile = deque(tous)
		vus = set(tous)
		while pile:
			n = pile.popleft()
			liste = []
			for v, _, _ in donjon.successeurs(n, flags):
				liste.append(v)
				if not isinstance(v, str) and v not in vus:
					vus.add(v)
					pile.append(v)
			succ[n] = liste
		inverse: dict = {}
		for n, vs in succ.items():
			for v in vs:
				inverse.setdefault(v, []).append(n)
		bons = set()
		file = deque(v for v in inverse if isinstance(v, str))
		while file:
			v = file.popleft()
			for n in inverse.get(v, []):
				if n not in bons:
					bons.add(n)
					file.append(n)
		mauvais = [n for n in vus if n not in bons]
		nb_nodes = max(nb_nodes, len(vus))
		cases_vues |= vus
		if mauvais:
			pires.append((sorted(f"{a}{b}" for a, b in flags), [(n[0], etages[n[0]].xy(n[1])) for n in mauvais[:3]]))
	r.critere(not pires, f"256 combinaisons de drapeaux : toute position atteignable ou d'arrivée mène à une sortie du donjon "
		f"(≤ {nb_nodes} positions par combinaison) {pires[:2]}")
	return {"cases": cases_vues}


# ---------------------------------------------------------------------------------------------
# d. Solution complète.
# ---------------------------------------------------------------------------------------------
def verifier_solution(r: Rapport, etages: dict[str, Etage], donjon: Donjon) -> dict:
	r.titre("d. Solution complète (8 chutes) et rochers indispensables à Artikodin")
	departs = list(donjon.departs_entrees().values())
	vide = frozenset()
	tous = frozenset(TROUS)
	cache_explo: dict = {}

	def options(flags):
		"""Chutes possibles (étage, n) depuis l'état `flags` : accessibilité globale + poussées locales."""
		dist, _, _ = donjon.atteignables(flags, departs)
		sortie = []
		for nom in ETAGES[:4]:
			e = etages[nom]
			rocks, plugged, courant = configuration(e, flags)
			if len(plugged) == 2:
				continue
			cases = tuple(sorted(c for (n, c) in dist if n == nom and c not in rocks))
			if not cases:
				continue
			cle = (nom, rocks, plugged, courant, cases)
			if cle not in cache_explo:
				cache_explo[cle] = explorer(e, plugged, rocks, courant, list(cases))
			ex = cache_explo[cle]
			for n in (1, 2):
				if n in plugged:
					continue
				cible = plugged | {n}
				for p, ck in ex.plugged_atteints.items():
					if n in p and p <= cible | plugged and (p - plugged) == {n}:
						sortie.append((nom, n, chemin_pousses(e, ex, ck)))
						break
		return sortie, dist

	# Parcours en largeur de l'espace des drapeaux.
	debut = time.time()
	parent: dict = {vide: None}
	file = deque([vide])
	profondeur = {vide: 0}
	chemins_pousses: dict = {}
	suivants: dict = {}
	while file:
		flags = file.popleft()
		opts, _ = options(flags)
		suivants[flags] = {flags | {(nom, n)} for nom, n, _ in opts}
		for nom, n, pousses in opts:
			nxt = flags | {(nom, n)}
			if nxt not in parent:
				parent[nxt] = (flags, (nom, n))
				chemins_pousses[nxt] = pousses
				profondeur[nxt] = profondeur[flags] + 1
				file.append(nxt)
	atteignables = set(parent)
	r.critere(tous in parent, f"solution complète : les 8 trous peuvent être bouchés ({len(atteignables)} combinaisons de "
		f"drapeaux atteignables sur 256, {time.time() - debut:.1f} s)")
	# Une solution (la plus courte en chutes).
	if tous in parent:
		suite = []
		f = tous
		while parent[f] is not None:
			prec, chute = parent[f]
			suite.append((chute, chemins_pousses[f]))
			f = prec
		suite.reverse()
		r.info("solution trouvée (un ordre possible, pousses du rocher : départ, direction, fin) :")
		for k, ((nom, n), pousses) in enumerate(suite, 1):
			e = etages[nom]
			r.info(f"  {k}. {nom} trou {n} {pt(e, e.trous[n])} → {texte_pousses(e, pousses)}")
		# Chaque combinaison atteignable permet toujours d'achever la solution.
		impasses = [sorted(f"{a}{b}" for a, b in fl) for fl in atteignables
			if fl != tous and not suivants.get(fl)]
		r.critere(not impasses, "de chaque combinaison atteignable, on peut encore boucher le trou suivant jusqu'au 8e "
			f"(aucune impasse) {impasses[:3]}")
	# Rochers indispensables à Artikodin.
	b4 = etages["B4F"]
	obs = b4.idx(_case(b4.artikodin.attrs["observe"]))
	voit = {}
	for fl in atteignables:
		dist, _, _ = donjon.atteignables(fl, departs)
		voit[fl] = ("B4F", obs) in dist
	minimaux = sorted((fl for fl, v in voit.items() if v and all(not voit[g] for g in atteignables if g < fl)),
		key=lambda fl: (len(fl), sorted(fl)))
	b3_seuls = frozenset({("B3F", 1), ("B3F", 2)})
	r.critere(voit.get(b3_seuls, False), "Artikodin atteignable avec les seuls 2 trous du B3F bouchés (aucune chute en haut)")
	r.critere(minimaux == [b3_seuls], "ensemble minimal de chutes pour la salle d'Artikodin : exactement les 2 trous du B3F "
		f"({[sorted(f'{a}{b}' for a, b in m) for m in minimaux]})")
	r.critere(not any(voit[fl] for fl in atteignables if not b3_seuls <= fl),
		"sans les 2 trous du B3F bouchés, la salle d'Artikodin est inaccessible (courant 2), quel que soit le reste")
	if b3_seuls in parent:
		suite = []
		f = b3_seuls
		while parent[f] is not None:
			prec, chute = parent[f]
			suite.append((chute, chemins_pousses[f]))
			f = prec
		suite.reverse()
		r.info("chemin le plus court vers Artikodin (rochers du B3F seulement) :")
		for k, ((nom, n), pousses) in enumerate(suite, 1):
			e = etages[nom]
			r.info(f"  {k}. {nom} trou {n} {pt(e, e.trous[n])} → {texte_pousses(e, pousses)}")
	return {"atteignables": atteignables, "parent": parent, "suivants": suivants}


# ---------------------------------------------------------------------------------------------
# e. Courants.
# ---------------------------------------------------------------------------------------------
def verifier_courants(r: Rapport, etages: dict[str, Etage], donjon: Donjon, atteignables) -> None:
	r.titre("e. Courants 1 (B3F → B4F mer est) et 2 (salle d'Artikodin)")
	b3, b4 = etages["B3F"], etages["B4F"]
	vide = frozenset()
	g1 = graphe(b3, frozenset(), True)
	bons = []
	for c in sorted(b3.courants[1].cells):
		i = b3.idx(c)
		trace: list[str] = []
		fin = g1.glisse(i)
		res = donjon.placer("B3F", i, vide, trace)
		bons.append((c, res))
	attendu = ("noeud", "B4F", b4.spawns["W1"])
	r.critere(all(res == attendu for _, res in bons),
		"courant 1 : des trois sources (escalier (15,7), chenal (18..19,7)) le joueur arrive au B4F, mer est, "
		f"case {pt(b4, b4.spawns['W1'])} en Surf forcé ({[(c, res[0]) for c, res in bons]})")
	trajet = g1.glisse_cases[b3.idx((15, 8))]
	r.info("trajet depuis (15,8) : " + " ".join(f"{b3.xy(i)[0]},{b3.xy(i)[1]}" for i in trajet))
	r.critere(b4.car[b4.spawns["W1"]] == "s" and b3.car[b3.spawns["W2"]] == "s" and b4.car[b4.spawns["W2"]] == "s",
		"les trois arrivées dans l'eau par passage sont des cases « s » (Surf forcé)")
	# Le courant n'est actif qu'avec au moins un trou du B2F ouvert.
	etats = {}
	for k in range(4):
		fl = frozenset(("B2F", n) for n in (1, 2) if k >> (n - 1) & 1)
		etats[k] = configuration(b3, fl)[2]
	r.critere(etats == {0: True, 1: True, 2: True, 3: False},
		"courant 1 : actif tant que les deux trous du B2F ne sont pas tous deux bouchés")
	# Courant 1 coupé : le bassin est libre, les rochers tombés bouchent le chenal.
	fl = frozenset({("B2F", 1), ("B2F", 2)})
	rocks, _, courant = configuration(b3, fl)
	r.critere(not courant and rocks >= set(b3.f_cases.values()),
		"courant 1 coupé : les deux rochers tombés sont posés dans l'eau, en travers du chenal (18..19, 6)")
	g_calme = graphe(b3, frozenset(), False)
	cases, _ = composante(g_calme, rocks, b3.idx((15, 8)))
	r.critere(b3.idx((19, 8)) in cases and b3.idx((22, 11)) in cases and b3.idx((15, 11)) in cases,
		"courant 1 coupé : le bassin entier se nage librement (escalier (15,7) → escalier (23,9))")
	# Courant 2.
	g2 = graphe(b4, frozenset(), True)
	fins = set()
	for c in b4.courants[2].cells:
		trace = []
		fins.add(donjon.placer("B4F", b4.idx(c), vide, trace))
	plate = ("noeud", "B4F", b4.idx((7, 11)))
	r.critere(fins == {plate}, "courant 2 : depuis ses deux atterrissages (4,14) et (5,14), le joueur est emporté jusqu'à "
		"l'escalier (7,11) de la plateforme centrale, où il descend")
	obs = ("B4F", b4.idx(_case(b4.artikodin.attrs["observe"])))
	departs = list(donjon.departs_entrees().values())
	resultats = {}
	for k in range(4):
		fl = frozenset(("B3F", n) for n in (1, 2) if k >> (n - 1) & 1)
		dist, _, _ = donjon.atteignables(fl, departs)
		resultats[k] = obs in dist
	r.critere(resultats == {0: False, 1: False, 2: False, 3: True},
		"salle d'Artikodin : fermée tant que les deux trous du B3F ne sont pas tous deux bouchés (0 ou 1 trou : inaccessible)")
	dist, _, _ = donjon.atteignables(vide, departs)
	r.critere(("B4F", b4.idx((7, 11))) in dist and ("B4F", b4.idx((7, 12))) not in dist,
		"courant 2 actif : la plateforme et l'escalier (7,11) s'atteignent, mais pas l'eau (7,12) (T-14)")
	# Une fois les 4 trous du dessus bouchés, plus de courant du tout, l'escalier (7,11) ouvre la mer ouest.
	fl = frozenset({("B3F", 1), ("B3F", 2)})
	dist, _, _ = donjon.atteignables(fl, departs)
	r.critere(("B4F", b4.idx((7, 12))) in dist and ("B4F", b4.idx(_case("7,4"))) in dist,
		"courant 2 coupé : depuis l'escalier (7,11), l'eau (7,12) puis (7,4) devant l'escalier (7,3) de la salle s'atteignent")


# ---------------------------------------------------------------------------------------------
# f. Traversées.
# ---------------------------------------------------------------------------------------------
def verifier_traversee(r: Rapport, etages: dict[str, Etage], donjon: Donjon) -> bool:
	r.titre("f. Traversée entrée ouest → entrée est en Surf seul, sans Force (et l'inverse)")
	departs = donjon.departs_entrees()
	vide = frozenset()
	ok_global = True
	for sens, (depart, cote) in {"ouest → est": (departs["ouest"], "SORTIE:est"),
			"est → ouest": (departs["est"], "SORTIE:ouest")}.items():
		for chutes in (False, True):
			dist, parent, sorties = donjon.atteignables(vide, [depart], chutes=chutes)
			etiquette = "sans sauter dans un trou" if not chutes else "trous autorisés"
			trouve = cote in sorties
			if not chutes:
				ok_global &= trouve
			r.critere(trouve or chutes, f"traversée {sens} ({etiquette}) : aucun rocher poussé, aucun drapeau posé : "
				f"{'atteinte' if trouve else 'IMPOSSIBLE'}")
			if trouve:
				fin = sorties[cote]
				etapes = donjon.chemin(parent, fin) + [(fin, cote, "sortie", [])]
				etapes[-1] = (fin, fin, "sortie", [])
				noms = []
				pas = 0
				etages_vus = [depart[0]]
				for prec, nxt, genre, trace in etapes[:-1]:
					pas += 1
					for t in trace:
						if t.startswith(("échelle", "passage", "chute", "courant")):
							noms.append(t)
					if not isinstance(nxt, str) and nxt[0] != etages_vus[-1]:
						etages_vus.append(nxt[0])
				nage = sum(1 for prec, nxt, genre, trace in etapes[:-1] if genre in ("nage", "monte", "courant"))
				r.info(f"    {pas} pas ; étages : {' → '.join(etages_vus)} ; {nage} pas en Surf")
				r.info("    transferts : " + " · ".join(noms))
	if not ok_global:
		print("\n  " + "!" * 76)
		print("  !!! LA TRAVERSÉE ENTRÉE OUEST ↔ ENTRÉE EST EN SURF SEUL ÉCHOUE")
		print("  !!! Ne pas corriger la géométrie : option de repli P-6 (chenal au sud de l'île), à décider avec Kevin.")
		print("  " + "!" * 76)
	return ok_global


# ---------------------------------------------------------------------------------------------
# g. Objets, Artikodin, panneaux, cases orphelines.
# ---------------------------------------------------------------------------------------------
def verifier_atteignables(r: Rapport, etages: dict[str, Etage], donjon: Donjon, atteignables,
		coutes: dict, vus_global: dict) -> None:
	r.titre("g. Objets cachés, Artikodin, panneaux atteignables ; aucune case praticable orpheline")
	departs = list(donjon.departs_entrees().values())
	tous = frozenset(TROUS)
	union: dict[str, set[int]] = {n: set() for n in ETAGES}
	for fl in atteignables | {tous}:
		dist, _, _ = donjon.atteignables(fl, departs)
		for nom, c in dist:
			union[nom].add(c)
	for (nom, noeuds) in [(n, ex.cellules) for (n, *_), ex in coutes.items()]:
		union[nom] |= noeuds
	for nom, c in vus_global["cases"]:
		union[nom].add(c)
	# Les terminaux (échelles, passages, entrées, trous) touchés depuis une case atteinte comptent.
	for fl in atteignables | {tous}:
		dist, _, _ = donjon.atteignables(fl, departs)
		for (nom, c) in dist:
			g, _ = donjon.config(nom, fl)
			for v, _ in g.adj.get(c, ()):
				if v in g.terminaux:
					union[nom].add(v)
	rocheres: dict[str, set[int]] = {n: set() for n in ETAGES}
	for (nom, *_), ex in coutes.items():
		union[nom] |= ex.terminaux
		rocheres[nom] |= ex.rocheres
	# Les cases traversées par les glissades de courant comptent.
	for nom, e in etages.items():
		for plugged in (frozenset(), frozenset({1}), frozenset({2}), frozenset({1, 2})):
			g = graphe(e, plugged, True)
			for s, cases in g.glisse_cases.items():
				union[nom] |= set(cases)
	acces = {}
	for nom, e in etages.items():
		for i, p in e.objets.items():
			ok = i in union[nom]
			acces[p.ident] = ok
			r.critere(ok, f"objet caché {p.ident} {nom} {pt(e, i)} ({p.attrs['item']}) atteignable, "
				f"indice x {[pt(e, t) for t in (e.voisin(i, d) for d in DIRECTIONS) if t is not None and e.car[t] == 'x']}")
	b4 = etages["B4F"]
	obs = b4.idx(_case(b4.artikodin.attrs["observe"]))
	r.critere(("B4F", obs) in {(n, c) for n in ["B4F"] for c in union["B4F"]} and
		b4.voisin(obs, (0, -1)) in b4.statiques,
		f"Artikodin {pt(b4, next(iter(b4.statiques)))} : case d'observation {pt(b4, obs)} atteignable, juste en dessous de lui")
	for nom, e in etages.items():
		for i, p in e.panneaux.items():
			voisins = [t for t in (e.voisin(i, d) for d in DIRECTIONS) if t is not None and t in union[nom] and not e.eau(t)]
			r.critere(bool(voisins), f"panneau {p.ident} {nom} {pt(e, i)} ({p.attrs['texte']}) lisible depuis {[pt(e, t) for t in voisins][:2]}")
	# Orphelines : toute case praticable doit être vue.
	orphelines = []
	for nom, e in etages.items():
		for i, c in enumerate(e.car):
			if e.mur(i) or c in "~":
				continue
			if i in e.statiques or i in e.f_eau:
				continue   # Artikodin ; points de chute dans l'eau : le joueur n'y est jamais (rocher ou courant)
			if i not in union[nom] and i not in rocheres[nom]:
				orphelines.append((nom, e.xy(i), c))
	# Une case où seul un rocher s'arrête (jamais le joueur) n'est pas orpheline : elle sert la poussée.
	r.critere(not orphelines, f"aucune case praticable orpheline (chaque case est atteinte à pied, en Surf, par une chute ou "
		f"par un courant) {orphelines[:6]}")
	total = sum(1 for e in etages.values() for i in range(e.n) if not e.mur(i) and e.car[i] != "~")
	r.info(f"{total} cases praticables sur les 5 étages")


# ---------------------------------------------------------------------------------------------
def main() -> int:
	global REGLE_B3F, PLANS
	if "--plans" in sys.argv:
		PLANS = Path(sys.argv[sys.argv.index("--plans") + 1])
	if "--rochers-derniers" in sys.argv:
		REGLE_B3F = "derniers"
		print("Diagnostic : rochers du B3F retirés « derniers de la liste » (ancienne règle)")
	r = Rapport()
	etages = charger()
	donjon = Donjon(etages)
	verifier_structure(r, etages, donjon)
	verifier_regles(r)
	coutes: dict = {}
	verifier_anti_blocage(r, etages, donjon, coutes)
	vus_global = verifier_graphe_entier(r, etages, donjon)
	sol = verifier_solution(r, etages, donjon)
	verifier_courants(r, etages, donjon, sol["atteignables"])
	traversee = verifier_traversee(r, etages, donjon)
	verifier_atteignables(r, etages, donjon, sol["atteignables"], coutes, vus_global)
	print("\n" + (("TOUT EST CONFORME" + (f" ({r.attentions} attention(s) : lignes [ATTENTION])" if r.attentions else ""))
		if r.ok else "ÉCHEC : voir les lignes [ÉCHEC] ci-dessus")
		+ ("" if traversee else "  (la traversée en Surf seul échoue : voir l'encadré, décision P-6)"))
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
