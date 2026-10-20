#!/usr/bin/env python3
"""Vérifie le Casino de Céladopole et le repaire Rocket (jalon 20, dossier 23 §12–§13).

Grilles : `tools/plans/casino.txt`, `repaire_b1f.txt`, `repaire_b2f.txt`, `repaire_b3f.txt`,
`repaire_b4f.txt`, `repaire_ascenseur.txt`. Lecture par `plan_grille.lire`. Géométrie de Rouge/Bleu
case pour case (cartes pret/pokered RocketHideoutB1F..B4F, GameCorner, RocketHideoutElevator).

Contrôles LOCAUX (chaque grille, sur son propre fichier) :
  1. dimensions RB, caractères connus, cartes closes (aucune case praticable au bord, sauf les deux
     sorties du Casino) ;
  2. DALLES (B2F, B3F ; aucune ailleurs) : chaque flèche, suivie selon la règle « glisse en ligne
     droite, une flèche rencontrée change la direction, arrêt sur un disque `o` », mène à une case
     d'arrêt praticable sans traverser de bloc ni sortir de la grille, sans boucle ; chaque disque est
     l'arrêt d'au moins une dalle ; les trajets recopiés de RB (kind=dalle : dir=, trajet=, arret=)
     sont identiques à ceux de la simulation, et rien (Dresseur, PNJ, objet) ne se trouve sur un
     trajet de glisse ;
  3. positions : Dresseurs et PNJ sur du sol, objets sur du sol (ou `sur=decor`), objets cachés lisibles
     depuis une case adjacente praticable, escaliers (glyphe = sens), portes d'ascenseur, arrivées
     voisines de leur escalier, effectifs du dossier §12–§13.2 (10 Dresseurs hors Giovanni, 5 PNJ du
     Casino, objets par étage) ; aucune arrivée n'est dans la ligne de vue d'un Dresseur.

Contrôles GLOBAUX (lancés par le profil `repaire_ascenseur`, ou par ce script sans argument) :
  4. raccords : chaque escalier déclare `vers=<carte>:<x>,<y>` ; la paire existe de l'autre côté, aux
     coordonnées déclarées, de sens opposé, avec une arrivée voisine ; portes d'ascenseur ↔ cabine ↔
     arrivées des trois étages (B1F, B2F, B4F, rien d'autre) ;
  5. atteignabilité, en tenant compte des dalles (on ne se pose jamais sur une flèche : on arrive à
     la case d'arrêt) et des Dresseurs qui restent en place : six états (Rocket de l'affiche, interrupteur,
     avant/après la Clé, gardes, Giovanni) ; tous les Dresseurs, PNJ, objets (visibles et cachés) et
     sorties sont atteignables à leur état ; retour possible à la ville depuis toute case atteinte ;
  6. B4F : les deux moitiés sont DISJOINTES à pied (même sans aucun Dresseur, porte ouverte) ; la Clé
     et son sbire sont à l'ouest ; gardes, Giovanni, Scope à l'est (derrière l'ascenseur).

Usage : python3 tools/art/plan_check_repaire.py             (les six grilles, code 1 si échec)
        python3 tools/art/plan_check.py tools/plans/repaire_b2f.txt   (une grille)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, Position, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"

CARTES = {
	"casino": "game_corner",
	"repaire_b1f": "rocket_hideout_b1f",
	"repaire_b2f": "rocket_hideout_b2f",
	"repaire_b3f": "rocket_hideout_b3f",
	"repaire_b4f": "rocket_hideout_b4f",
	"repaire_ascenseur": "rocket_hideout_elevator",
}
STEMS = {v: k for k, v in CARTES.items()}
DIMS = {"game_corner": (20, 18), "rocket_hideout_b1f": (30, 28), "rocket_hideout_b2f": (30, 28),
	"rocket_hideout_b3f": (30, 28), "rocket_hideout_b4f": (30, 24),
	"rocket_hideout_elevator": (6, 8)}
GLYPHES = {
	"game_corner": set("#.tMCASE"),
	"rocket_hideout_elevator": set("#.LP"),
	"rocket_hideout_b1f": set("#.XPMUDL"),
	"rocket_hideout_b2f": set("#.XPMUDL<>^vo"),
	"rocket_hideout_b3f": set("#.XPMUDL<>^vo"),
	"rocket_hideout_b4f": set("#.XPMUDLB"),
}
AVEC_DALLES = {"rocket_hideout_b2f", "rocket_hideout_b3f"}
FLECHES = {">": (1, 0), "<": (-1, 0), "^": (0, -1), "v": (0, 1)}
NSEO = {"N": (0, -1), "S": (0, 1), "E": (1, 0), "O": (-1, 0)}
INV_NSEO = {v: k for k, v in NSEO.items()}
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
DIRS = list(NSEO.values())
ETAGES = {"B1F": "rocket_hideout_b1f", "B2F": "rocket_hideout_b2f", "B4F": "rocket_hideout_b4f"}
Case = tuple[int, int]
Noeud = tuple  # (carte, x, y, étage_de_la_cabine | None)

# Effectifs du dossier 23 §12 et §13.2 (Dresseurs hors Giovanni : 10 en tout, Casino compris).
DRESSEURS = {"game_corner": 1, "rocket_hideout_b1f": 3, "rocket_hideout_b2f": 1,
	"rocket_hideout_b3f": 2, "rocket_hideout_b4f": 4}      # B4F : sbire à la Clé, 2 gardes, Giovanni
OBJETS = {"rocket_hideout_b1f": (2, 1), "rocket_hideout_b2f": (4, 0), "rocket_hideout_b3f": (2, 1),
	"rocket_hideout_b4f": (5, 1)}                           # (visibles, cachés)
PNJ_CASINO = 5


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def titre(self, texte: str) -> None:
		print(f"\n{texte}")

	def critere(self, vrai: bool, texte: str) -> None:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	def info(self, texte: str) -> None:
		print(f"  {texte}")


def _case(texte: str) -> Case:
	x, y = texte.split(",")
	return int(x), int(y)


def _voisines(c: Case) -> list[Case]:
	return [(c[0] + d[0], c[1] + d[1]) for d in DIRS]


def charger(dossier: Path) -> dict[str, Plan]:
	return {ident: lire(dossier / f"{stem}.txt") for stem, ident in CARTES.items()}


# --------------------------------------------------------------------------- dalles
def rle(pas: list[Case]) -> str:
	suite: list[list] = []
	for p in pas:
		n = INV_NSEO[p]
		if suite and suite[-1][0] == n:
			suite[-1][1] += 1
		else:
			suite.append([n, 1])
	return ",".join(f"{n}{c}" for n, c in suite)


def glisse(plan: Plan, depart: Case) -> tuple[str, Case | None, str, list[Case]]:
	"""Glisse depuis la case d'une flèche : (trajet RLE, case d'arrêt, erreur, cases traversées)."""
	x, y = depart
	d = FLECHES[plan.at(x, y)]
	pas: list[Case] = []
	traversees: list[Case] = [depart]
	vus: set = set()
	for _ in range(plan.width * plan.height * 4 + 4):
		x, y = x + d[0], y + d[1]
		if not (0 <= x < plan.width and 0 <= y < plan.height):
			return rle(pas), None, "sort de la grille", traversees
		g = plan.at(x, y)
		if g not in plan.praticables:
			return rle(pas), None, f"traverse un bloc « {g} » en ({x}, {y})", traversees
		pas.append(d)
		traversees.append((x, y))
		if g == "o":
			return rle(pas), (x, y), "", traversees
		if g in FLECHES:
			d = FLECHES[g]
		elif g in "UDLE":
			return rle(pas), None, f"traverse un passage « {g} » en ({x}, {y})", traversees
		if (x, y, d) in vus:
			return rle(pas), None, f"boucle infinie en ({x}, {y})", traversees
		vus.add((x, y, d))
	return rle(pas), None, "boucle infinie", traversees


def dalles(plan: Plan) -> dict[Case, tuple[str, Case | None, str, list[Case]]]:
	return {c: glisse(plan, c) for g in FLECHES for c in plan.cells_of(g)}


# --------------------------------------------------------------------------- contrôles locaux
def lignes_de_vue(plan: Plan, p: Position) -> set[Case]:
	"""Cases vues par un Dresseur (portée `sight`, dans son sens, arrêtée par un bloc)."""
	vues: set[Case] = set()
	d = FACINGS[p.attrs["facing"]]
	x, y = p.cells[0]
	for _ in range(int(p.attrs.get("sight", "0"))):
		x, y = x + d[0], y + d[1]
		if not (0 <= x < plan.width and 0 <= y < plan.height) or plan.at(x, y) not in plan.praticables:
			break
		vues.add((x, y))
	return vues


def verifier_local(r: Rapport, ident: str, plan: Plan, plans: dict[str, Plan]) -> None:
	l_att, h_att = DIMS[ident]
	r.critere((plan.width, plan.height) == (l_att, h_att),
		f"{ident} : {plan.width} × {plan.height} cases (RB : {l_att} × {h_att})")
	inconnus = {c for row in plan.rows for c in row} - GLYPHES[ident]
	r.critere(not inconnus, f"caractères tous connus de la légende {sorted(inconnus) if inconnus else ''}")
	bord = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and plan.at(x, y) in plan.praticables]
	if ident == "game_corner":
		hors = [c for c in plan.cells_of("E") if c[1] != plan.height - 1]
		r.critere(len(plan.cells_of("E")) == 2 and not hors and
			len({x for x, _ in plan.cells_of("E")}) == 2,
			f"Casino : exactement 2 cases de sortie `E`, au bas de la salle {plan.cells_of('E')}")
	else:
		r.critere(not bord, f"carte close : aucune case praticable au bord {bord[:4]}")

	# 2. Dalles.
	arrets = plan.cells_of("o")
	sim = dalles(plan)
	traversees: set[Case] = set()
	if ident in AVEC_DALLES:
		erreurs = [(c, v[2]) for c, v in sim.items() if v[1] is None]
		r.critere(not erreurs, f"{len(sim)} dalles : toutes mènent à une case d'arrêt sans bloc, sans "
			f"sortie de grille ni boucle {erreurs[:3] if erreurs else ''}")
		for v in sim.values():
			traversees.update(v[3])
		atteints = {v[1] for v in sim.values() if v[1] is not None}
		r.critere(set(arrets) == atteints, f"{len(arrets)} cases d'arrêt, toutes atteintes par au "
			f"moins une dalle (orphelines : {sorted(set(arrets) - atteints)})")
		decl = {p.cells[0]: p for p in plan.of_kind("dalle")}
		r.critere(set(decl) == set(sim), f"les {len(decl)} dalles de POSITIONS sont exactement les "
			f"{len(sim)} flèches de la grille")
		ecarts = []
		for c, p in decl.items():
			if c not in sim:
				continue
			trajet, arret, _, _ = sim[c]
			if (p.attrs.get("trajet") != trajet or p.attrs.get("dir") != trajet[0]
					or _case(p.attrs.get("arret", "-1,-1")) != arret):
				ecarts.append((c, p.attrs.get("trajet"), trajet))
		r.critere(not ecarts, f"trajets RB recopiés = simulation sur la grille {ecarts[:3] if ecarts else ''}")
		pas_max = max((len(v[3]) - 1 for v in sim.values()), default=0)
		r.info(f"trajet de glisse le plus long : {pas_max} cases")
	else:
		r.critere(not (set(FLECHES) & {c for row in plan.rows for c in row}) and not arrets
			and not plan.of_kind("dalle"), "aucune dalle ni case d'arrêt sur cette carte")

	# 3. Positions.
	occ: dict[Case, str] = {}
	doubles = []
	for p in plan.positions.values():
		if p.kind in ("dresseur", "pnj", "objet_visible"):
			for c in p.cells:
				if c in occ:
					doubles.append((c, occ[c], p.ident))
				occ[c] = p.ident
	r.critere(not doubles, f"aucune case occupée deux fois {doubles[:3] if doubles else ''}")
	mal = []
	for p in plan.positions.values():
		if p.kind in ("dresseur", "pnj"):
			c = p.cells[0]
			if not p.bloque or plan.at(*c) not in ".t":
				mal.append(f"{p.ident} sur « {plan.at(*c)} » ou non bloquant")
			if c in traversees:
				mal.append(f"{p.ident} sur un trajet de glisse")
			if p.kind == "dresseur":
				if p.attrs.get("facing") not in FACINGS or not p.attrs.get("sight", "x").isdigit() \
						or "trainer" not in p.attrs:
					mal.append(f"{p.ident} : facing / sight / trainer incomplets")
		elif p.kind == "objet_visible":
			c = p.cells[0]
			g = plan.at(*c)
			if not (g == "." or (g in "MP" and p.attrs.get("sur") == "decor")) or c in traversees:
				mal.append(f"{p.ident} sur « {g} » (ou sur un trajet de glisse)")
		elif p.kind == "objet_cache":
			c = p.cells[0]
			depuis = _case(p.attrs.get("depuis", "-1,-1"))
			f = NSEO.get(p.attrs.get("face", "?"))
			if (depuis not in _voisines(c) or plan.at(*depuis) not in plan.praticables
					or f is None or (depuis[0] + f[0], depuis[1] + f[1]) != c):
				mal.append(f"{p.ident} : lecture depuis {depuis} face={p.attrs.get('face')} incohérente")
	r.critere(not mal, f"positions cohérentes avec la grille {mal[:4] if mal else ''}")
	if ident in DRESSEURS:
		n = len(plan.of_kind("dresseur"))
		r.critere(n == DRESSEURS[ident], f"{n} Dresseur(s) (dossier : {DRESSEURS[ident]}"
			f"{', Giovanni compris' if ident.endswith('b4f') else ''})")
	if ident == "game_corner":
		r.critere(len(plan.of_kind("pnj")) == PNJ_CASINO, f"{len(plan.of_kind('pnj'))} PNJ (dossier : 5)")
		machines = [c for p in plan.of_kind("machine") for c in p.cells]
		r.critere(sorted(machines) == sorted(plan.cells_of("M")), f"les {len(machines)} cases de "
			"machines de POSITIONS sont exactement les cases `M` de la grille")
	if ident in OBJETS:
		v = len(plan.of_kind("objet_visible"))
		h = len(plan.of_kind("objet_cache"))
		r.critere((v, h) == OBJETS[ident], f"{v} objet(s) visible(s) et {h} caché(s) "
			f"(dossier : {OBJETS[ident][0]} et {OBJETS[ident][1]})")
	# Escaliers et portes.
	for p in plan.of_kind("escalier"):
		c = p.cells[0]
		attendu = {"monte": "U", "descend": "D"}[p.attrs["sens"]]
		if ident == "game_corner":
			attendu = "S"
		arr = [s for s in plan.of_kind("spawn") if s.attrs.get("paire") == p.attrs["paire"]]
		ok = (plan.at(*c) == attendu and len(arr) == 1 and arr[0].cells[0] in _voisines(c)
			and plan.at(*arr[0].cells[0]) in plan.praticables)
		r.critere(ok, f"escalier {p.ident} ({c[0]}, {c[1]}) « {plan.at(*c)} » sens={p.attrs['sens']}, "
			f"arrivée {arr[0].cells[0] if arr else '—'} voisine et praticable")
	for p in plan.of_kind("ascenseur"):
		xs = sorted(x for x, _ in p.cells)
		ok = (len(p.cells) == 2 and all(plan.at(*c) == "L" for c in p.cells) and xs[1] - xs[0] == 1
			and len({y for _, y in p.cells}) == 1 and len(plan.cells_of("L")) == 2)
		arr = [s for s in plan.of_kind("spawn") if s.attrs.get("paire") == "ascenseur"]
		y = p.cells[0][1]
		ok &= (len(arr) == 1 and arr[0].cells[0][1] == y - 1 and arr[0].cells[0][0] in xs
			and plan.at(*arr[0].cells[0]) in plan.praticables)
		r.critere(ok, f"ascenseur {p.attrs['etage']} : 2 portes `L` côte à côte {p.cells}, arrivée "
			f"{arr[0].cells[0] if arr else '—'} juste devant")
	# Aucune arrivée dans la ligne de vue d'un Dresseur.
	vues: dict[Case, str] = {}
	for p in plan.of_kind("dresseur"):
		for c in lignes_de_vue(plan, p):
			vues[c] = p.ident
	pris = [(s.ident, vues[s.cells[0]]) for s in plan.of_kind("spawn") if s.cells[0] in vues]
	r.critere(not pris, f"aucune arrivée dans la ligne de vue d'un Dresseur {pris if pris else ''}")


# --------------------------------------------------------------------------- monde global
class Repaire:
	"""Les six cartes reliées ; un état = drapeaux d'histoire qui ouvrent ou ferment des passages."""

	def __init__(self, plans: dict[str, Plan], *, rocket_battu: bool, interrupteur: bool, cle: bool,
			gardes: bool, giovanni: bool) -> None:
		self.plans = plans
		self.etat = dict(rocket_battu=rocket_battu, interrupteur=interrupteur, cle=cle,
			gardes=gardes, giovanni=giovanni)
		self.occupees: dict[str, set[Case]] = {i: set() for i in plans}
		for ident, plan in plans.items():
			for p in plan.of_kind("dresseur") + plan.of_kind("pnj"):
				c = p.cells[0]
				if p.ident == "rocket_affiche" and rocket_battu:
					c = _case(p.attrs["apres"])
				if p.ident == "giovanni" and giovanni:
					continue
				self.occupees[ident].add(c)
		self.glisses = {i: dalles(pl) for i, pl in plans.items() if i in AVEC_DALLES}
		# Escaliers : case → (carte d'arrivée, case d'arrivée).
		self.escaliers: dict[tuple[str, Case], tuple[str, Case]] = {}
		for ident, plan in plans.items():
			for p in plan.of_kind("escalier"):
				cible = p.attrs["vers"].split(":")[0]
				for s in plans[cible].of_kind("spawn"):
					if s.attrs.get("paire") == p.attrs["paire"]:
						self.escaliers[(ident, p.cells[0])] = (cible, s.cells[0])
		self.sorties_cabine = {}
		cab = plans["rocket_hideout_elevator"]
		self.entrees_cabine = {s.attrs["role"]: s.cells[0] for s in cab.of_kind("spawn")}
		self.panneau = cab.positions["panneau"]
		self.arrivee_etage = {}
		for etage, ident in ETAGES.items():
			for s in plans[ident].of_kind("spawn"):
				if s.attrs.get("paire") == "ascenseur":
					self.arrivee_etage[etage] = (ident, s.cells[0])

	def passable(self, ident: str, c: Case) -> bool:
		plan = self.plans[ident]
		x, y = c
		if not (0 <= x < plan.width and 0 <= y < plan.height) or c in self.occupees[ident]:
			return False
		g = plan.at(x, y)
		if g == "B":
			return self.etat["gardes"]
		if g == "S":
			return self.etat["interrupteur"]
		return g in plan.praticables

	def pas(self, n: Noeud, d: Case) -> Noeud | None:
		ident, x, y, etage = n
		plan = self.plans[ident]
		c = (x + d[0], y + d[1])
		if not self.passable(ident, c):
			return None
		g = plan.at(*c)
		if g in FLECHES:
			arret = self.glisses[ident][c][1]
			return (ident, arret[0], arret[1], None) if arret else None
		if g in "UDS" and ident != "rocket_hideout_elevator":
			cible, arr = self.escaliers[(ident, c)]
			return (cible, arr[0], arr[1], None)
		if g == "E":
			return ("ville", 0, 0, None)
		if g == "L":
			if ident == "rocket_hideout_elevator":
				cible, arr = self.arrivee_etage[etage]
				return (cible, arr[0], arr[1], None)
			niveau = [p for p in plan.of_kind("ascenseur")][0].attrs["etage"]
			gauche = min(x for x, _ in plan.cells_of("L"))
			role = "entree_g" if c[0] == gauche else "entree_d"
			e = self.entrees_cabine[role]
			return ("rocket_hideout_elevator", e[0], e[1], niveau)
		return (ident, c[0], c[1], etage)

	def successeurs(self, n: Noeud):
		if n[0] in ("ville",):
			return
		for d in DIRS:
			s = self.pas(n, d)
			if s is not None:
				yield s
		# Panneau d'étages : lu depuis sa case d'accès, uniquement avec la Clé.
		if n[0] == "rocket_hideout_elevator" and self.etat["cle"] \
				and (n[1], n[2]) == _case(self.panneau.attrs["depuis"]):
			for etage in self.panneau.attrs["etages"].split(","):
				yield (n[0], n[1], n[2], etage)

	def explorer(self, depart: Noeud) -> tuple[dict[Noeud, int], dict[Noeud, list[Noeud]]]:
		dist = {depart: 0}
		adj: dict[Noeud, list[Noeud]] = {}
		file = deque([depart])
		while file:
			n = file.popleft()
			adj[n] = list(self.successeurs(n))
			for s in adj[n]:
				if s not in dist:
					dist[s] = dist[n] + 1
					file.append(s)
		return dist, adj


def peut_revenir(adj: dict[Noeud, list[Noeud]], but: Noeud) -> set[Noeud]:
	inverse: dict[Noeud, list[Noeud]] = {}
	for n, ss in adj.items():
		for s in ss:
			inverse.setdefault(s, []).append(n)
	vus = {but}
	file = deque([but])
	while file:
		n = file.popleft()
		for p in inverse.get(n, []):
			if p not in vus:
				vus.add(p)
				file.append(p)
	return vus


def verifier_global(r: Rapport, plans: dict[str, Plan]) -> None:
	r.titre("Raccords entre cartes")
	# 4. Escaliers.
	paires: dict[str, list[tuple[str, Position]]] = {}
	for ident, plan in plans.items():
		for p in plan.of_kind("escalier"):
			paires.setdefault(p.attrs["paire"], []).append((ident, p))
	for paire, lots in sorted(paires.items()):
		ok = len(lots) == 2
		detail = ""
		if ok:
			(ia, pa), (ib, pb) = lots
			va, vb = pa.attrs["vers"].split(":"), pb.attrs["vers"].split(":")
			ok = (va[0] == ib and vb[0] == ia and _case(va[1]) == pb.cells[0]
				and _case(vb[1]) == pa.cells[0] and {pa.attrs["sens"], pb.attrs["sens"]} == {"monte", "descend"})
			detail = (f"{ia} ({pa.cells[0][0]}, {pa.cells[0][1]}) {pa.attrs['sens']} ↔ "
				f"{ib} ({pb.cells[0][0]}, {pb.cells[0][1]}) {pb.attrs['sens']}")
		r.critere(ok, f"paire « {paire} » : {detail} (coordonnées déclarées des deux côtés, sens opposés)")
	# Ascenseur.
	cab = plans["rocket_hideout_elevator"]
	panneau = cab.positions["panneau"]
	etages = panneau.attrs["etages"].split(",")
	r.critere(etages == list(ETAGES), f"panneau d'étages = {etages} (B1F, B2F, B4F, rien d'autre)")
	for etage, ident in ETAGES.items():
		asc = [p for p in plans[ident].of_kind("ascenseur") if p.attrs["etage"] == etage]
		arr = [s for s in plans[ident].of_kind("spawn") if s.attrs.get("paire") == "ascenseur"]
		r.critere(len(asc) == 1 and len(arr) == 1 and asc[0].attrs["vers"] == "rocket_hideout_elevator",
			f"{etage} : portes {asc[0].cells if asc else '—'} ↔ cabine, arrivée {arr[0].cells[0] if arr else '—'}")
	depuis = _case(panneau.attrs["depuis"])
	r.critere(cab.at(*depuis) in cab.praticables and
		(depuis[0] + NSEO[panneau.attrs["face"]][0], depuis[1] + NSEO[panneau.attrs["face"]][1]) == panneau.cells[0],
		f"panneau {panneau.cells[0]} lisible depuis {depuis}")
	sortie = plans["game_corner"].positions["sortie_ville"]
	r.info(f"à raccorder à la grille de Céladopole : sortie du Casino {sortie.cells} → {sortie.attrs['vers']}")

	# 5. Atteignabilité.
	r.titre("Atteignabilité (dalles comprises ; Dresseurs vaincus restent en place)")
	gc = plans["game_corner"]
	depart: Noeud = ("game_corner", *gc.positions["entree_ville"].cells[0], None)
	scenarios = [
		("1 Rocket de l'affiche en place", dict(rocket_battu=False, interrupteur=False, cle=False, gardes=False, giovanni=False)),
		("2 Rocket battu, interrupteur pas encore pressé", dict(rocket_battu=True, interrupteur=False, cle=False, gardes=False, giovanni=False)),
		("3 interrupteur pressé, sans la Clé", dict(rocket_battu=True, interrupteur=True, cle=False, gardes=False, giovanni=False)),
		("4 avec la Clé, gardes en place", dict(rocket_battu=True, interrupteur=True, cle=True, gardes=False, giovanni=False)),
		("5 gardes battus, Giovanni en place", dict(rocket_battu=True, interrupteur=True, cle=True, gardes=True, giovanni=False)),
		("6 Giovanni battu", dict(rocket_battu=True, interrupteur=True, cle=True, gardes=True, giovanni=True)),
	]
	resultats = {}
	for nom, etat in scenarios:
		monde = Repaire(plans, **etat)
		dist, adj = monde.explorer(depart)
		resultats[nom] = (monde, dist, adj)
	nom1, nom2, nom3, nom4, nom5, nom6 = (s[0] for s in scenarios)

	def vus_de(nom: str) -> set[Noeud]:
		return set(resultats[nom][1])

	def cartes_atteintes(nom: str) -> set[str]:
		return {n[0] for n in vus_de(nom)} - {"ville"}

	def lieux(ident: str, p: Position, v: set[Noeud]) -> bool:
		if p.kind == "objet_cache":
			return (ident, *_case(p.attrs["depuis"]), None) in v
		return any((ident, *c, None) in v for c in [p.cells[0], *_voisines(p.cells[0])])

	# État 1 : Casino seul.
	v1 = vus_de(nom1)
	r.critere(cartes_atteintes(nom1) == {"game_corner"},
		f"{nom1} : seul le Casino est atteint (escalier muré) ; {len({n for n in v1})} cases")
	manques = [p.ident for p in gc.of_kind("pnj") + gc.of_kind("dresseur") if not lieux("game_corner", p, v1)]
	r.critere(not manques, f"  Rocket et 5 PNJ du Casino atteignables {manques if manques else ''}")
	affiche = gc.positions["affiche"]
	r.critere(_case(affiche.attrs["depuis"]) not in {(n[1], n[2]) for n in v1 if n[0] == "game_corner"},
		"  l'affiche n'est pas lisible tant que le Rocket est devant")
	# État 2 : Rocket parti.
	v2 = vus_de(nom2)
	r.critere(cartes_atteintes(nom2) == {"game_corner"} and ("game_corner", *_case(affiche.attrs["depuis"]), None) in v2,
		f"{nom2} : l'affiche est lisible depuis {affiche.attrs['depuis']}, l'escalier reste muré")
	apres = _case(plans["game_corner"].positions["rocket_affiche"].attrs["apres"])
	esc = gc.positions["vers_b1f"].cells[0]
	arr = gc.positions["arrivee_b1f"].cells[0]
	r.critere(("game_corner", *arr, None) in v2 and gc.at(*apres) == "." and apres not in (arr, esc),
		f"  le Rocket rangé en {apres} laisse la coursive libre jusqu'à l'escalier {esc}")
	# État 3 : repaire sans Clé.
	v3 = vus_de(nom3)
	c3 = cartes_atteintes(nom3)
	r.critere({"rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f", "rocket_hideout_b4f",
		"rocket_hideout_elevator"} <= c3, f"{nom3} : B1F à B4F et la cabine atteints ({len(v3)} lieux)")

	def verifier_etat(nom: str, ident: str, noms: list[str], attendu: bool) -> None:
		v = vus_de(nom)
		plan = plans[ident]
		faux = []
		for p in plan.of_kind("dresseur") + plan.of_kind("pnj") + plan.of_kind("objet_visible") \
				+ plan.of_kind("objet_cache"):
			if p.ident in noms and lieux(ident, p, v) != attendu:
				faux.append(p.ident)
		verbe = "atteignables" if attendu else "inaccessibles"
		r.critere(not faux, f"  {ident} : {', '.join(noms)} {verbe} {faux if faux else ''}")

	# Tous les éléments hors moitié est, hors B4F-est, sont atteints à l'état 3.
	est_b4f = {"garde_est", "garde_ouest", "giovanni", "scope_sylphe", "super_potion_cachee", "fer"}
	for ident in ("rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f"):
		noms = [p.ident for p in plans[ident].of_kind("dresseur") + plans[ident].of_kind("objet_visible")
			+ plans[ident].of_kind("objet_cache")]
		verifier_etat(nom3, ident, noms, True)
	ouest = ["sbire_cle", "cle_ascenseur", "ct02", "pv_plus"]
	verifier_etat(nom3, "rocket_hideout_b4f", ouest, True)
	verifier_etat(nom3, "rocket_hideout_b4f", sorted(est_b4f), False)
	# État 4 : Clé, gardes en place.
	verifier_etat(nom4, "rocket_hideout_b4f", ["garde_est", "garde_ouest", "fer"], True)
	verifier_etat(nom4, "rocket_hideout_b4f", ["giovanni", "scope_sylphe", "super_potion_cachee"], False)
	# État 5 : porte ouverte.
	verifier_etat(nom5, "rocket_hideout_b4f", ["giovanni"], True)
	# État 6 : tout.
	for ident in ("rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f", "rocket_hideout_b4f"):
		plan = plans[ident]
		noms = [p.ident for p in plan.of_kind("dresseur") + plan.of_kind("objet_visible")
			+ plan.of_kind("objet_cache") if p.ident != "giovanni"]
		verifier_etat(nom6, ident, noms, True)
	# Cases de sol jamais atteintes à l'état final : on écarte les cases occupées par un personnage
	# resté en place et celles que seule une glisse traverse (informatif).
	monde6, v6d, _ = resultats[nom6]
	v6 = set(v6d)
	for ident, plan in plans.items():
		if ident == "rocket_hideout_elevator":
			continue
		glisse_cases = set()
		for v in monde6.glisses.get(ident, {}).values():
			glisse_cases.update(v[3])
		orph = [(x, y) for y in range(plan.height) for x in range(plan.width)
			if plan.at(x, y) in ".to" and (ident, x, y, None) not in v6
			and (x, y) not in monde6.occupees[ident] and (x, y) not in glisse_cases]
		r.info(f"{ident} : {len(orph)} case(s) de sol hors de portée à pied, hors cases occupées et "
			f"hors trajets de glisse {orph[:8] if orph else ''}")
	# Retour à la ville depuis toute case atteinte, à chaque état.
	for nom in (nom1, nom2, nom3, nom4, nom5, nom6):
		_, dist, adj = resultats[nom]
		ville = ("ville", 0, 0, None)
		if ville not in dist:
			r.info(f"{nom} : la ville n'est pas atteignable (sortie du Casino)")
			continue
		revient = peut_revenir(adj, ville)
		piege = [n for n in dist if n not in revient]
		r.critere(not piege, f"{nom} : retour à la ville possible depuis les {len(dist)} lieux atteints "
			f"{piege[:3] if piege else ''}")

	# 6. B4F : deux moitiés disjointes à pied.
	r.titre("B4F : deux moitiés disjointes")
	b4 = plans["rocket_hideout_b4f"]
	ouest_dep = b4.positions["arrivee_b3f"].cells[0]
	est_dep = b4.positions["arrivee_ascenseur"].cells[0]

	def composante(depart_b4: Case, avec_dresseurs: bool) -> set[Case]:
		bloq = {p.cells[0] for p in b4.of_kind("dresseur")} if avec_dresseurs else set()
		sol = set(b4.praticables) | {"B"}
		vus = {depart_b4}
		file = deque([depart_b4])
		while file:
			c = file.popleft()
			for n in _voisines(c):
				if (0 <= n[0] < b4.width and 0 <= n[1] < b4.height and n not in vus
						and b4.at(*n) in sol and n not in bloq and b4.at(*n) not in "UDL"):
					vus.add(n)
					file.append(n)
		return vus
	for avec in (True, False):
		w, e = composante(ouest_dep, avec), composante(est_dep, avec)
		r.critere(w.isdisjoint(e) and len(w) > 20 and len(e) > 20,
			f"{'avec' if avec else 'sans'} Dresseurs, porte du bureau ouverte : moitié ouest {len(w)} cases, "
			f"moitié est {len(e)} cases, aucune case commune")
	w = composante(ouest_dep, False)
	e = composante(est_dep, False)
	moitie = lambda ident: "ouest" if b4.positions[ident].cells[0] in w or any(  # noqa: E731
		n in w for n in _voisines(b4.positions[ident].cells[0])) else (
		"est" if b4.positions[ident].cells[0] in e or any(
			n in e for n in _voisines(b4.positions[ident].cells[0])) else "?")
	reparti = {i: moitie(i) for i in ("sbire_cle", "cle_ascenseur", "ct02", "pv_plus", "fer", "garde_ouest",
		"garde_est", "giovanni", "scope_sylphe", "super_potion_cachee")}
	r.critere(all(reparti[i] == "ouest" for i in ("sbire_cle", "cle_ascenseur", "ct02", "pv_plus"))
		and all(reparti[i] == "est" for i in ("garde_ouest", "garde_est", "giovanni", "scope_sylphe",
		"super_potion_cachee", "fer")), "Clé, sbire, CT02, PV Plus à l'ouest ; gardes, Giovanni, Scope, "
		"objet caché, Fer à l'est : " + ", ".join(f"{k} {v}" for k, v in reparti.items()))
	r.info("écart avec le dossier §13.2 : en RB le Fer (12, 20) est dans la moitié EST (couloir sud), pas à l'ouest")
	cle = b4.positions["cle_ascenseur"].cells[0]
	sbire = b4.positions["sbire_cle"].cells[0]
	r.critere(cle in _voisines(sbire), f"la Clé {cle} est « à côté » du sbire {sbire}")


# --------------------------------------------------------------------------- profils
def verifier(stem: str, chemin: Path, global_: bool) -> bool:
	r = Rapport()
	dossier = chemin.parent
	plans = charger(dossier)
	ident = CARTES[stem]
	r.titre(f"{stem} ({ident}) : {plans[ident].width} × {plans[ident].height}")
	verifier_local(r, ident, plans[ident], plans)
	if global_:
		verifier_global(r, plans)
	else:
		r.info("raccords et atteignabilité globaux : voir le profil repaire_ascenseur (ou "
			"python3 tools/art/plan_check_repaire.py)")
	return r.ok


def profil(stem: str):
	def f(chemin: Path) -> bool:
		return verifier(stem, chemin, global_=(stem == "repaire_ascenseur"))
	return f


VERIFICATEURS = {stem: profil(stem) for stem in CARTES}


def main() -> int:
	ok = True
	for stem in CARTES:
		r = Rapport()
		plans = charger(PLANS)
		ident = CARTES[stem]
		r.titre(f"{stem} ({ident}) : {plans[ident].width} × {plans[ident].height}")
		verifier_local(r, ident, plans[ident], plans)
		ok &= r.ok
	r = Rapport()
	verifier_global(r, charger(PLANS))
	ok &= r.ok
	print("\nPlan conforme." if ok else "\nPlan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
