#!/usr/bin/env python3
"""Vérifie les grilles du Mont Sélénite et du sas de la Route 4 (jalon 12, dossier 15 §5–§14).

Grilles : `tools/plans/mont_selenite_1f.txt`, `mont_selenite_b1f.txt`, `mont_selenite_b2f.txt`,
`route_4_sas.txt`. Lecture par `plan_grille.lire` ; déplacements de `plan_check.Monde` (4
directions, un pas par case), sur un **graphe unique** qui relie les quatre cartes :
  - entrer dans la case d'une échelle (position `echelle`, attribut `paire=`) fait arriver, après
    le fondu, sur le `spawn` de même paire de l'autre carte (un pas) ; on ne s'arrête jamais sur
    une échelle ;
  - l'entrée du 1F (`E`) et le raccord est du sas (`e`) sont des sorties (on y entre, on n'en
    repart pas) ;
  - deux états : **initial** (toutes les positions `bloque`) et **après les combats** (les trois
    Sbires sont partis, le chercheur s'est rangé sur sa case `apres=`).

Critères :
  1. échelles toutes appariées (deux bouts sur deux cartes, sens cohérent avec la grille, une
     arrivée voisine de chaque bout) ; cartes fermées (seules `E` et `e` touchent le bord) ;
  2. entrée du 1F → raccord est du sas atteignable ; longueur du parcours principal, détail par
     étage et nombre d'échelles ;
  3. R3 et le chercheur inévitables ; R1 selon son attribut `inevitable` ; R2 évitable ; le
     chercheur n'est atteignable qu'après la vue de R3 ; aucune approche de Dresseur ne ferme un
     passage ;
  4. chaque objet visible, fossile et objet caché atteignable ; un objet caché est sur du sol
     calme, avec un indice `x` contre lui ; aucun objet visible sur une ligne de vue ;
  5. retour à l'entrée possible depuis toute case praticable ; aucune case praticable orpheline ;
  6. gravats : cases obligatoires sur le trajet le moins exposé (borne GRAVATS_OBLIGATOIRES),
     zones obligatoires nommées, part de couloirs calmes sur le parcours ;
  7. culs-de-sac : chacun mène à quelque chose (échelle, objet, Dresseur, repère…) ;
  8. estimation de durée (méthode de la Forêt de Jade, combats Rocket et chercheur compris).

Usage : python3 tools/art/plan_check_mont_selenite.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS, FACINGS, INF, Monde  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
CARTES = {
	"1F": "mont_selenite_1f",
	"B1F": "mont_selenite_b1f",
	"B2F": "mont_selenite_b2f",
	"sas": "route_4_sas",
}
Case = tuple[int, int]
Noeud = tuple[str, int, int]

# Défauts (règle 4), dossier 15 §5.1 et §14.
TAILLES_MAX = {"1F": (68, 54), "B1F": (44, 36), "B2F": (56, 42), "sas": (24, 14)}
GRAVATS = "g"
CALME = set(".j")                  # sol de grotte calme (et puits de jour)
SORTIES = {"1F": "E", "sas": "e"}
GRAVATS_OBLIGATOIRES = (6, 12)     # cases de gravats au moins, sur le trajet le moins exposé
PART_CALME_MIN = 0.85              # part du parcours principal hors gravats
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases (≥ 2 libres entre eux)
CUL_DE_SAC_RAYON = 2               # un cul-de-sac a une position à ≤ 2 cases (Manhattan)
# Durée (méthode de verifier_foret) : pas mesuré sur S21, combats par défaut.
S_PAR_PAS = 0.72
S_ECHELLE = 2.0                    # fondu d'une échelle (comme une porte)
S_COMBATS = {"R1": 100, "R3": 150, "chercheur": 130}   # R3 : trois Pokémon + scène (3 bulles)
S_SCENES = 30                      # partage, choix du fossile, Grand moment
S_SAUVAGE = 50
TAUX = 25 / 256                    # taux des herbes repris pour les gravats (dossier 15 §6)


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


class Grotte:
	"""Les quatre cartes reliées par leurs échelles ; `bloquees` : cases bloquées en plus (ou
	libérées, `liberees`) par carte, pour simuler un état."""

	def __init__(self, plans: dict[str, Plan], apres_combats: bool,
			bloquees: dict[str, set[Case]] | None = None) -> None:
		self.plans = plans
		self.mondes: dict[str, Monde] = {}
		for nom, plan in plans.items():
			monde = Monde(plan)
			if apres_combats:
				for p in plan.of_kind("dresseur"):
					monde.bloquees.difference_update(p.cells)
					if "apres" in p.attrs:
						monde.bloquees.add(_case(p.attrs["apres"]))
			monde.bloquees.update((bloquees or {}).get(nom, set()))
			self.mondes[nom] = monde
		# Échelles : case → nœud d'arrivée (le spawn de même paire sur l'autre carte).
		arrivees = {(nom, p.attrs["paire"]): p.cells[0] for nom, plan in plans.items()
			for p in plan.of_kind("spawn") if "paire" in p.attrs}
		self.echelles: dict[Noeud, Noeud] = {}
		for nom, plan in plans.items():
			for p in plan.of_kind("echelle"):
				autre = [n for n, pl in plans.items() if n != nom and any(
					q.attrs.get("paire") == p.attrs["paire"] for q in pl.of_kind("echelle"))]
				if len(autre) == 1 and (autre[0], p.attrs["paire"]) in arrivees:
					self.echelles[(nom, *p.cells[0])] = (autre[0], *arrivees[(autre[0], p.attrs["paire"])])
		self.sorties = {(nom, x, y) for nom, car in SORTIES.items() for x, y in plans[nom].cells_of(car)}

	def voisins(self, n: Noeud):
		if n in self.sorties or n in self.echelles:
			return
		nom, x, y = n
		for c in self.mondes[nom].voisins((x, y)):
			v = (nom, *c)
			yield self.echelles.get(v, v)

	def bfs(self, departs: list[Noeud]) -> tuple[dict[Noeud, int], dict[Noeud, Noeud]]:
		dist = {d: 0 for d in departs}
		parent: dict[Noeud, Noeud] = {}
		file = deque(departs)
		while file:
			n = file.popleft()
			for v in self.voisins(n):
				if v not in dist:
					dist[v] = dist[n] + 1
					parent[v] = n
					file.append(v)
		return dist, parent

	def gravats_min(self, departs: list[Noeud], compte) -> dict[Noeud, int]:
		cout = {d: 0 for d in departs}
		file = deque(departs)
		while file:
			n = file.popleft()
			for v in self.voisins(n):
				k = cout[n] + (1 if compte(v) else 0)
				if k < cout.get(v, INF):
					cout[v] = k
					(file.append if k > cout[n] else file.appendleft)(v)
		return cout


def zones_gravats(plan: Plan) -> list[set[Case]]:
	reste = set(plan.cells_of(GRAVATS))
	zones = []
	while reste:
		germe = reste.pop()
		zone, pile = {germe}, [germe]
		while pile:
			x, y = pile.pop()
			for dx, dy in DIRECTIONS:
				v = (x + dx, y + dy)
				if v in reste:
					reste.remove(v)
					zone.add(v)
					pile.append(v)
		zones.append(zone)
	return zones


def ligne_de_vue(monde: Monde, p) -> list[Case]:
	d = FACINGS[p.attrs["facing"]]
	cases = []
	for k in range(1, int(p.attrs.get("sight", "0")) + 1):
		c = (p.cells[0][0] + d[0] * k, p.cells[0][1] + d[1] * k)
		if not monde.libre(c):
			break
		cases.append(c)
	return cases


def premiere_detection(grotte: Grotte, depart: Noeud, nom: str, vue: list[Case]) -> int:
	rang = {(nom, *c): i + 1 for i, c in enumerate(vue)}
	vu, file, mini = {depart}, deque([depart]), INF
	while file:
		n = file.popleft()
		for v in grotte.voisins(n):
			if v in vu:
				continue
			vu.add(v)
			if v in rang:
				mini = min(mini, rang[v])
			else:
				file.append(v)
	return mini


def acces(grotte: Grotte, nom: str, p) -> list[Noeud]:
	"""Nœuds d'où l'on prend / examine p : sa case (libre) ou ses voisines praticables."""
	if not p.bloque:
		return [(nom, *c) for c in p.cells]
	monde = grotte.mondes[nom]
	return [(nom, c[0] + dx, c[1] + dy) for c in p.cells for dx, dy in DIRECTIONS
		if monde.libre((c[0] + dx, c[1] + dy))]


def chemin(parent: dict[Noeud, Noeud], fin: Noeud) -> list[Noeud]:
	trajet = [fin]
	while trajet[-1] in parent:
		trajet.append(parent[trajet[-1]])
	return trajet[::-1]


def verifier() -> bool:
	r = Rapport()
	plans = {nom: lire(PLANS / f"{fichier}.txt") for nom, fichier in CARTES.items()}
	r.titre("Mont Sélénite et sas de la Route 4 : "
		+ ", ".join(f"{n} {p.width} × {p.height}" for n, p in plans.items()))

	# 1. Tailles, bords, échelles.
	for nom, plan in plans.items():
		lmax, hmax = TAILLES_MAX[nom]
		r.critere(plan.width <= lmax and plan.height <= hmax,
			f"{nom} : {plan.width} × {plan.height} dans l'enveloppe du dossier ({lmax} × {hmax})")
		monde = Monde(plan)
		bord = [(x, y) for y in range(plan.height) for x in range(plan.width)
			if (x in (0, plan.width - 1) or y in (0, plan.height - 1))
			and plan.at(x, y) in plan.praticables]
		sortie = SORTIES.get(nom)
		r.critere(all(plan.at(*c) == sortie for c in bord) and (sortie is None or bord),
			f"{nom} fermé : cases praticables au bord = {sorted(bord)} "
			f"({'sortie « ' + sortie + ' »' if sortie else 'aucune attendue'})")
		del monde
	paires: dict[str, list[tuple[str, object]]] = {}
	for nom, plan in plans.items():
		for p in plan.of_kind("echelle"):
			paires.setdefault(p.attrs["paire"], []).append((nom, p))
	fautes = []
	for paire, bouts in sorted(paires.items()):
		if len(bouts) != 2 or bouts[0][0] == bouts[1][0]:
			fautes.append(f"{paire} : {[b[0] for b in bouts]}")
			continue
		for nom, p in bouts:
			plan = plans[nom]
			car = plan.at(*p.cells[0])
			attendu = "U" if p.attrs["sens"] == "monte" else ("D" if nom == "sas" else "V")
			arr = [q for q in plan.of_kind("spawn") if q.attrs.get("paire") == paire]
			pres = len(arr) == 1 and abs(arr[0].cells[0][0] - p.cells[0][0]) \
				+ abs(arr[0].cells[0][1] - p.cells[0][1]) == 1
			if car != attendu or not pres:
				fautes.append(f"{paire} {nom} {p.cells[0]} « {car} » (attendu « {attendu} »), "
					f"arrivée voisine : {'oui' if pres else 'NON'}")
		sens = sorted(p.attrs["sens"] for _, p in bouts)
		if sens != ["descend", "monte"]:
			fautes.append(f"{paire} : sens {sens}")
	orphelines = [(nom, c) for nom, plan in plans.items() for car in "UV" for c in plan.cells_of(car)
		if not any(p.cells[0] == c for p in plan.of_kind("echelle"))]
	r.critere(not fautes and not orphelines,
		f"échelles appariées : {', '.join(f'{k} ({a[0]} ↔ {b[0]})' for k, (a, b) in sorted(paires.items()) if len(paires[k]) == 2)}"
		+ (f" ; fautes {fautes} {orphelines}" if fautes or orphelines else ""))
	if fautes:
		return False

	# 2. Parcours principal (état « après les combats » : les Sbires battus restent dans leur
	#    niche le temps du combat, le chercheur se range ; la longueur est la même).
	apres = Grotte(plans, apres_combats=True)
	initial = Grotte(plans, apres_combats=False)
	depart = ("1F", *plans["1F"].positions["from_route_3"].cells[0])
	but = {("sas", x, y) for x, y in plans["sas"].cells_of("e")}
	entree = {("1F", x, y) for x, y in plans["1F"].cells_of("E")}
	dist, parent = apres.bfs([depart])
	atteint = [b for b in but if b in dist]
	aller = min((dist[b] for b in atteint), default=INF)
	r.critere(aller < INF, f"entrée du 1F → raccord est du sas : {aller} pas")
	if aller >= INF:
		return False
	trajet = chemin(parent, min(atteint, key=lambda b: dist[b]))
	par_carte: dict[str, int] = {}
	echelles = 0
	for a, b in zip(trajet, trajet[1:]):
		if a[0] != b[0]:
			echelles += 1
		par_carte[a[0]] = par_carte.get(a[0], 0) + 1
	ordre = []
	for n in trajet:
		if not ordre or ordre[-1] != n[0]:
			ordre.append(n[0])
	r.info(f"parcours : {' → '.join(ordre)} ; {echelles} passages d'échelle ; pas par carte : "
		+ ", ".join(f"{k} {v}" for k, v in par_carte.items()))

	# 3. Dresseurs.
	dresseurs = {p.attrs["role"]: (nom, p) for nom, plan in plans.items()
		for p in plan.of_kind("dresseur")}
	r.critere(sorted(dresseurs) == ["R1", "R2", "R3", "chercheur"],
		f"Dresseurs : {sorted(dresseurs)} (R1, R2 en B1F ; R3, chercheur en B2F)")
	vues: dict[str, list[Case]] = {}
	for role, (nom, p) in sorted(dresseurs.items()):
		vue = ligne_de_vue(initial.mondes[nom], p)
		vues[role] = vue
		sight = int(p.attrs.get("sight", "0"))
		r.critere(len(vue) == sight and plans[nom].at(*p.cells[0]) in CALME,
			f"{role} {p.ident} {nom} {p.cells[0]} tourné {p.attrs['facing']} : vision {len(vue)}/"
			f"{sight} dégagée {vue}")

	def sans(nom: str, cases) -> Grotte:
		g = Grotte(plans, apres_combats=True, bloquees={nom: set(cases)})
		return g

	for role, (nom, p) in sorted(dresseurs.items()):
		inev = p.attrs.get("inevitable") == "oui"
		if role == "chercheur":
			# Inévitable par la place : il occupe le seul accès à l'échelle de sortie.
			bloque_seul = Grotte(plans, apres_combats=True, bloquees={nom: set(p.cells)})
			d = bloque_seul.bfs([depart])[0]
			coupe = not any(b in d for b in but)
			r.critere(inev and coupe and p.attrs.get("scene") == "oui",
				f"chercheur inévitable : sa case {p.cells[0]} est le seul accès à l'échelle de "
				f"sortie ({'oui' if coupe else 'NON'}), combat lancé par la scène, rangé ensuite "
				f"en {p.attrs.get('apres')}")
			continue
		g = sans(nom, vues[role])
		d = g.bfs([depart])[0]
		contournable = min((d[b] for b in but if b in d), default=INF)
		if inev:
			arrivee = {"B1F": "arrivee_a", "B2F": "arrivee_d"}[nom]
			premiere = premiere_detection(initial, (nom, *plans[nom].positions[arrivee].cells[0]),
				nom, vues[role])
			r.critere(contournable >= INF and premiere >= DETECTION_MIN,
				f"{role} inévitable ({'oui' if contournable >= INF else f'NON, {contournable} pas'}) ; "
				f"première case vue à {premiere} cases (attendu ≥ {DETECTION_MIN})")
		else:
			r.critere(contournable == aller,
				f"{role} évitable sans détour : sas atteint en {contournable} pas hors de sa vue")
	# Le chercheur ne se rencontre qu'après R3 : ses cases d'accès sont derrière la vue de R3.
	nom3, p3 = dresseurs["R3"]
	nomc, pc = dresseurs["chercheur"]
	d = Grotte(plans, apres_combats=False, bloquees={nom3: set(vues["R3"])}).bfs([depart])[0]
	avant = [n for n in acces(initial, nomc, pc) if n in d]
	r.critere(not avant, f"chercheur derrière R3 : aucune case d'accès atteignable sans passer "
		f"par la vue de R3 {avant}")

	# Approches : un Dresseur qui s'avance ne ferme aucun passage (sortie, entrée, objets).
	objets = [(nom, p) for nom, plan in plans.items()
		for p in plan.of_kind("objet_visible") + plan.of_kind("objet_cache") + plan.of_kind("fossile")]
	fermes = []
	for role, (nom, p) in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			g = Grotte(plans, apres_combats=False, bloquees={nom: {arret}})
			g.mondes[nom].bloquees.discard(p.cells[0])
			if role != "chercheur":
				g.mondes[nomc].bloquees.discard(pc.cells[0])
			dv = g.bfs([(nom, *v)])[0]
			cibles = [but, entree] + [set(acces(g, n, o)) for n, o in objets]
			if any(not any(c in dv for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v}")
	r.critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3]}")

	# 4. Objets.
	lignes = {(nom, *c) for role, (nom, p) in dresseurs.items() for c in vues[role]}
	for nom, p in objets:
		a = [n for n in acces(apres, nom, p) if n in dist]
		dmin = min((dist[n] for n in a), default=INF)
		texte = f"{p.kind} {p.ident} {nom} {p.cells[0]} ({p.attrs.get('item', '?')}) : atteint en {dmin} pas"
		vrai = dmin < INF
		if p.kind == "objet_cache":
			c = p.cells[0]
			sol = plans[nom].at(*c)
			indice = [(c[0] + dx, c[1] + dy) for dx, dy in DIRECTIONS
				if plans[nom].at(c[0] + dx, c[1] + dy) == "x"]
			vrai &= sol in CALME and bool(indice)
			texte += f", sol « {sol} », indice x en {indice}"
		if p.kind == "objet_visible":
			vrai &= (nom, *p.cells[0]) not in lignes
		r.critere(vrai, texte)
	visibles = sum(1 for _, p in objets if p.kind == "objet_visible")
	caches = sum(1 for _, p in objets if p.kind == "objet_cache")
	r.info(f"{visibles} objets visibles, {caches} cachés, {sum(1 for _, p in objets if p.kind == 'fossile')} fossiles")
	indices = [(nom, c) for nom, plan in plans.items() for c in plan.cells_of("x")]
	r.critere(len(indices) == caches, f"un indice « x » par objet caché ({len(indices)})")

	# 5. Retour à l'entrée depuis toute case praticable ; aucune case orpheline.
	noeuds = set(dist) - apres.sorties
	inverse: dict[Noeud, list[Noeud]] = {}
	for n in noeuds:
		for v in apres.voisins(n):
			inverse.setdefault(v, []).append(n)
	retour = set(entree & set(dist))
	file = deque(retour)
	while file:
		n = file.popleft()
		for v in inverse.get(n, []):
			if v not in retour:
				retour.add(v)
				file.append(v)
	sans_retour = sorted(noeuds - retour)
	r.critere(not sans_retour, f"retour à l'entrée possible depuis les {len(noeuds)} cases "
		f"atteignables (sorties exclues) {sans_retour[:4]}")
	orphelins = []
	for nom, plan in plans.items():
		monde = apres.mondes[nom]
		for y in range(plan.height):
			for x in range(plan.width):
				n = (nom, x, y)
				if monde.libre((x, y)) and n not in dist and n not in apres.echelles:
					orphelins.append(n)
	r.critere(not orphelins, f"aucune case praticable orpheline {orphelins[:4]}")

	# 6. Gravats.
	noms_zones = {}
	for nom, plan in plans.items():
		zones = zones_gravats(plan)
		marques = {p.attrs["role"]: p.cells[0] for p in plan.of_kind("gravats")}
		for role, c in marques.items():
			for z in zones:
				if c in z:
					noms_zones[f"{nom}-{role}"] = (nom, z)
		r.critere(len(marques) == len(zones) == len({id(z) for z in
			(zz for (n, zz) in noms_zones.values() if n == nom)}),
			f"{nom} : {len(zones)} zone(s) de gravats, toutes nommées "
			f"({', '.join(f'{k} {len(z)}' for k, (n, z) in noms_zones.items() if n == nom)})")
	est_gravats = lambda n: plans[n[0]].at(n[1], n[2]) == GRAVATS  # noqa: E731
	cout = apres.gravats_min([depart], est_gravats)
	gmin = min((cout[b] for b in but if b in cout), default=INF)
	lo, hi = GRAVATS_OBLIGATOIRES
	obligatoires = []
	for cle, (nom, zone) in noms_zones.items():
		g = Grotte(plans, apres_combats=True, bloquees={nom: zone})
		d = g.bfs([depart])[0]
		if not any(b in d for b in but):
			n = apres.gravats_min([depart], lambda v, z=zone, m=nom: v[0] == m and (v[1], v[2]) in z)
			obligatoires.append(f"{cle} ({min(n[b] for b in but if b in n)} cases)")
	r.critere(lo <= gmin <= hi, f"gravats obligatoires sur le trajet le moins exposé : {gmin} "
		f"cases (borne {lo} à {hi}) ; zones incontournables : {', '.join(obligatoires)}")
	part = (aller - gmin) / aller
	sur_trajet = sum(1 for n in trajet if est_gravats(n))
	r.critere(part >= PART_CALME_MIN, f"part de couloirs calmes sur le parcours : "
		f"{100 * part:.0f} % (au moins {100 * PART_CALME_MIN:.0f} %) ; le plus court en pas "
		f"traverse {sur_trajet} cases de gravats")
	for nom, plan in plans.items():
		prat = sum(1 for y in range(plan.height) for x in range(plan.width)
			if plan.at(x, y) in plan.praticables)
		gr = len(plan.cells_of(GRAVATS))
		r.info(f"{nom} : {prat} cases praticables, dont {gr} de gravats ({100 * gr / prat:.0f} %)")

	# 7. Culs-de-sac et goulets.
	marques = {(nom, c) for nom, plan in plans.items() for p in plan.positions.values()
		if p.kind not in ("gravats",) for c in p.cells}
	inutiles, goulets = [], 0
	sur_parcours = set(trajet)
	for nom, plan in plans.items():
		monde = initial.mondes[nom]
		for y in range(plan.height):
			for x in range(plan.width):
				if plan.at(x, y) not in plan.praticables:
					continue
				ouverts = sum(1 for dx, dy in DIRECTIONS if 0 <= x + dx < plan.width
					and 0 <= y + dy < plan.height and plan.at(x + dx, y + dy) in plan.praticables)
				if ouverts == 1 and not any((nom, (x + dx, y + dy)) in marques
						for dx in range(-CUL_DE_SAC_RAYON, CUL_DE_SAC_RAYON + 1)
						for dy in range(-CUL_DE_SAC_RAYON, CUL_DE_SAC_RAYON + 1)
						if abs(dx) + abs(dy) <= CUL_DE_SAC_RAYON):
					inutiles.append((nom, x, y))
				carre = any(all(0 <= x + a < plan.width and 0 <= y + b < plan.height
					and plan.at(x + a, y + b) in plan.praticables for a, b in
					((0, 0), (sx, 0), (0, sy), (sx, sy))) for sx in (-1, 1) for sy in (-1, 1))
				if not carre and (nom, x, y) in sur_parcours:
					goulets += 1
		del monde
	r.critere(not inutiles, f"aucun cul-de-sac inutile {inutiles[:6]}")
	r.info(f"goulets d'une case sur le parcours principal (compagnon masqué) : {goulets} cases")

	# 8. Durée.
	rencontres = gmin * TAUX
	combats = sum(S_COMBATS.values())
	duree = aller * S_PAR_PAS + echelles * S_ECHELLE + combats + S_SCENES + rencontres * S_SAUVAGE
	r.info(f"traversée directe estimée : {aller} pas × {S_PAR_PAS} s + {echelles} échelles × "
		f"{S_ECHELLE} s + combats {' + '.join(f'{k} {v} s' for k, v in S_COMBATS.items())} + "
		f"scènes {S_SCENES} s + {rencontres:.2f} rencontre(s) attendue(s) × {S_SAUVAGE} s = "
		f"{duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s)")
	sas = ("sas", *plans["sas"].positions["from_mt_moon"].cells[0])
	retour_pas = min((d for n, d in apres.bfs([sas])[0].items() if n in entree), default=INF)
	r.info(f"retour à pied du sas à l'entrée : {retour_pas} pas")
	return r.ok


def main() -> int:
	ok = verifier()
	print("\nPlan conforme." if ok else "\nPlan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
