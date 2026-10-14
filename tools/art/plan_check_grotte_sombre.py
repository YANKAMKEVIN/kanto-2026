#!/usr/bin/env python3
"""Vérifie les grilles de la Grotte Sombre (jalon 18, dossier 21 §5, §13.1, §14).

Grilles : `tools/plans/grotte_sombre_1f.txt` et `grotte_sombre_b1f.txt`. Lecture par
`plan_grille.lire` ; déplacements de `plan_check.Monde`, sur un **graphe unique** qui relie les
deux étages par leurs échelles (entrer dans la case d'une échelle fait arriver, après le fondu, sur
le `spawn` de même paire de l'autre carte ; on ne s'arrête jamais sur une échelle). L'entrée nord
(`E`) et la sortie sud (`e`) sont des sorties : on y entre, on n'en repart pas.

Critères :
  1. tailles dans l'enveloppe, cartes fermées (seules `E` et `e` touchent le bord du 1F),
     surface totale ≈ 4 000 cases ;
  2. échelles : deux paires, chacune sur les deux étages **aux mêmes coordonnées** (aplomb), sens
     cohérent, une arrivée voisine de chaque bout ;
  3. le 1F a exactement **deux moitiés non reliées** (nord : entrée + échelle A ; sud : arrivée B +
     sortie) ; elles ne communiquent que par le B1F ;
  4. chemin principal entrée nord → sortie sud (≈ 180 pas), détail par étage, 2 échelles ;
  5. Dresseurs : G-1 et G-4 inévitables (vus à ≥ 3 cases), G-2, G-3, G-5 évitables sans détour et
     sans fermer un passage ;
  6. objets (3 visibles + 1 caché) atteignables, hors des lignes de vue ; l'objet caché est sur sol
     calme, contre des racines ; embranchements : 2 au 1F nord, 3 au B1F, bout à ≤ 15 pas du
     chemin principal, finissant sur un objet, un Dresseur ou une vue ;
  7. gravats : ≈ 10 cases sur le chemin le moins exposé, chaque gravat obligatoire est précédé de
     deux cases de sol en ligne droite avant d'y entrer (jamais dans l'angle mort d'un virage),
     toutes les zones nommées, plus de gravats que le Mont Sélénite (part des cases praticables) ;
  8. passage étroit : 6 cases de 1 de large juste avant l'échelle B ; repères présents ;
  9. halos : 1 filet de jour (contre la paroi fendue) + 2 à 3 lampes ; lampes hors des goulets ;
 10. retour à l'entrée nord possible de partout ; aucune case orpheline ; culs-de-sac utiles ;
 11. estimation de durée (méthode du Mont Sélénite).

Usage : python3 tools/art/plan_check_grotte_sombre.py   (code 1 si un critère échoue)
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
CARTES = {"1F": "grotte_sombre_1f", "B1F": "grotte_sombre_b1f"}
Case = tuple[int, int]
Noeud = tuple[str, int, int]

TAILLES_MAX = {"1F": (56, 50), "B1F": (48, 38)}
SURFACE = (3800, 4700)             # « ≈ 4 000 cases » (somme des surfaces ; agrandie pour les moitiés)
GRAVATS = "g"
CALME = set(".j")
ENTREE, SORTIE = "E", "e"
CHEMIN = (170, 190)                # « ≈ 180 pas »
GRAVATS_SUR_CHEMIN = (8, 12)       # « ≈ 10 cases »
BRANCHE_MAX = 15
DETECTION_MIN = 3
PASSAGE = 6
CUL_DE_SAC_RAYON = 2
LAMPES = (2, 3)
# Durée (méthode du Mont Sélénite) : 0,72 s par pas mesuré sur S21, fondu d'échelle 2 s.
S_PAR_PAS = 0.72
S_ECHELLE = 2.0
S_COMBATS = {"G-1": 120, "G-4": 110}   # 4 Pokémon Nv. 17-19 ; 3 Pokémon Nv. 20
S_SAUVAGE = 50
TAUX = 25 / 256


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
	def __init__(self, plans: dict[str, Plan], bloquees: dict[str, set[Case]] | None = None,
			sans_dresseurs: bool = False) -> None:
		self.plans = plans
		self.mondes: dict[str, Monde] = {}
		for nom, plan in plans.items():
			monde = Monde(plan)
			if sans_dresseurs:
				for p in plan.of_kind("dresseur"):
					monde.bloquees.difference_update(p.cells)
			monde.bloquees.update((bloquees or {}).get(nom, set()))
			self.mondes[nom] = monde
		arrivees = {(nom, p.attrs["paire"]): p.cells[0] for nom, plan in plans.items()
			for p in plan.of_kind("spawn") if "paire" in p.attrs}
		self.echelles: dict[Noeud, Noeud] = {}
		for nom, plan in plans.items():
			for p in plan.of_kind("echelle"):
				autre = [n for n in plans if n != nom]
				if len(autre) == 1 and (autre[0], p.attrs["paire"]) in arrivees:
					self.echelles[(nom, *p.cells[0])] = (autre[0], *arrivees[(autre[0], p.attrs["paire"])])
		self.sorties = {("1F", x, y) for c in (ENTREE, SORTIE) for x, y in plans["1F"].cells_of(c)}

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


def composantes(plan: Plan, monde: Monde, echelles: set[Case]) -> list[set[Case]]:
	"""Composantes connexes d'un seul étage (échelles et sorties exclues des traversées)."""
	cases = {(x, y) for y in range(plan.height) for x in range(plan.width) if monde.libre((x, y))}
	reste, res = set(cases), []
	while reste:
		germe = reste.pop()
		comp, pile = {germe}, [germe]
		while pile:
			c = pile.pop()
			if c in echelles:
				continue
			for dx, dy in DIRECTIONS:
				v = (c[0] + dx, c[1] + dy)
				if v in reste:
					reste.remove(v)
					comp.add(v)
					pile.append(v)
		res.append(comp)
	return res


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


def mont_selenite_gravats() -> tuple[int, int]:
	"""(cases de gravats, cases praticables) du Mont Sélénite, pour la comparaison."""
	g = p = 0
	for n in ("1f", "b1f", "b2f"):
		plan = lire(PLANS / f"mont_selenite_{n}.txt")
		g += len(plan.cells_of(GRAVATS))
		p += sum(1 for y in range(plan.height) for x in range(plan.width)
			if plan.at(x, y) in plan.praticables)
	return g, p


def verifier() -> bool:
	r = Rapport()
	plans = {nom: lire(PLANS / f"{f}.txt") for nom, f in CARTES.items()}
	r.titre("Grotte Sombre : " + ", ".join(f"{n} {p.width} × {p.height}" for n, p in plans.items()))

	# 1. Tailles, bords, surface.
	for nom, plan in plans.items():
		lmax, hmax = TAILLES_MAX[nom]
		r.critere(plan.width <= lmax and plan.height <= hmax,
			f"{nom} : {plan.width} × {plan.height} dans l'enveloppe ({lmax} × {hmax})")
		bord = [(x, y) for y in range(plan.height) for x in range(plan.width)
			if (x in (0, plan.width - 1) or y in (0, plan.height - 1))
			and plan.at(x, y) in plan.praticables]
		attendu = {ENTREE, SORTIE} if nom == "1F" else set()
		r.critere(all(plan.at(*c) in attendu for c in bord)
			and {plan.at(*c) for c in bord} == attendu,
			f"{nom} fermé : cases praticables au bord = {sorted(bord)}")
	surface = sum(p.width * p.height for p in plans.values())
	r.critere(SURFACE[0] <= surface <= SURFACE[1], f"surface totale {surface} cases "
		f"(≈ 4 000 ; Mont Sélénite 5 860)")

	# 2. Échelles.
	fautes = []
	for paire in ("A", "B"):
		bouts = {nom: next((p for p in plan.of_kind("echelle") if p.attrs["paire"] == paire), None)
			for nom, plan in plans.items()}
		if None in bouts.values():
			fautes.append(f"{paire} : manque un bout")
			continue
		if bouts["1F"].cells[0] != bouts["B1F"].cells[0]:
			fautes.append(f"{paire} : pas à l'aplomb {bouts['1F'].cells[0]} / {bouts['B1F'].cells[0]}")
		for nom, p in bouts.items():
			car = plans[nom].at(*p.cells[0])
			attendu = "V" if nom == "1F" else "U"
			sens = "descend" if nom == "1F" else "monte"
			arr = [q for q in plans[nom].of_kind("spawn") if q.attrs.get("paire") == paire]
			pres = len(arr) == 1 and abs(arr[0].cells[0][0] - p.cells[0][0]) \
				+ abs(arr[0].cells[0][1] - p.cells[0][1]) == 1
			if car != attendu or p.attrs["sens"] != sens or not pres:
				fautes.append(f"{paire} {nom} « {car} » sens {p.attrs['sens']}, arrivée voisine {pres}")
	r.critere(not fautes, "échelles A et B appariées, à l'aplomb l'une de l'autre "
		f"(A en {plans['1F'].positions['echelle_a'].cells[0]}, B en "
		f"{plans['1F'].positions['echelle_b'].cells[0]}) {fautes}")
	if fautes:
		return False

	# 3. Deux moitiés non reliées.
	initial = Grotte(plans)
	m1 = initial.mondes["1F"]
	lad = {p.cells[0] for p in plans["1F"].of_kind("echelle")}
	comps = composantes(plans["1F"], m1, lad)
	haut = [c for c in comps if (27, 1) in c]
	r.critere(len(comps) == 2, f"1F : {len(comps)} composantes connexes "
		f"({', '.join(str(len(c)) for c in comps)} cases) — attendu 2")
	if len(comps) != 2:
		return False
	nord = haut[0] if haut else comps[0]
	sud = next(c for c in comps if c is not nord)
	ea, eb = (plans["1F"].positions[k].cells[0] for k in ("echelle_a", "echelle_b"))
	sortie = set(plans["1F"].cells_of(SORTIE))
	entree = set(plans["1F"].cells_of(ENTREE))
	r.critere(ea in nord and entree <= nord and eb in sud and sortie <= sud,
		"nord = entrée + échelle A ; sud = échelle B + sortie ; aucune case commune")
	ys_n = [c[1] for c in nord]
	ys_s = [c[1] for c in sud]
	r.info(f"moitié nord : rangées {min(ys_n)}–{max(ys_n)}, {len(nord)} cases ; moitié sud : "
		f"rangées {min(ys_s)}–{max(ys_s)}, {len(sud)} cases ; roche entre les deux : "
		f"{min(ys_s) - max(ys_n) - 1} rangées")
	# Les deux moitiés ne se voient jamais : écran ≈ 20 × 11 cases (24 colonnes sur S24), halo de
	# Flash ≈ 7–9 cases. Pour toute paire (case nord, case sud) : |dy| ≥ 12 ou |dx| ≥ 25.
	pire = min((min(abs(a[1] - b[1]) for b in sud if abs(a[0] - b[0]) < 25)
		for a in nord if any(abs(a[0] - b[0]) < 25 for b in sud)), default=INF)
	r.critere(pire >= 12, f"moitiés jamais visibles l'une depuis l'autre : écart vertical minimal "
		f"{pire} rangées pour les paires à moins de 25 colonnes (≥ 12 attendu)")

	# 4. Chemin principal.
	sans = Grotte(plans, sans_dresseurs=True)
	depart = ("1F", *plans["1F"].positions["from_route_10_n"].cells[0])
	but = {("1F", x, y) for x, y in sortie}
	dist, parent = sans.bfs([depart])
	atteint = [b for b in but if b in dist]
	aller = min((dist[b] for b in atteint), default=INF)
	lo, hi = CHEMIN
	r.critere(lo <= aller <= hi, f"entrée nord → sortie sud : {aller} pas (≈ 180 : {lo} à {hi})")
	if aller >= INF:
		return False
	trajet = chemin(parent, min(atteint, key=lambda b: dist[b]))
	par_carte: dict[str, int] = {}
	echelles = 0
	segments = []
	for a, b in zip(trajet, trajet[1:]):
		if a[0] != b[0]:
			echelles += 1
		par_carte[a[0]] = par_carte.get(a[0], 0) + 1
	cur, n0 = trajet[0][0], 0
	for i, n in enumerate(trajet):
		if n[0] != cur or i == len(trajet) - 1:
			segments.append(f"{cur} {i - n0}")
			cur, n0 = n[0], i
	r.critere(echelles == 2, f"{echelles} passages d'échelle ; segments : {' → '.join(segments)} ")
	# Cases du chemin principal = toutes les cases sur un plus court chemin.
	vers_but, _ = sans.bfs([depart])
	inv: dict[Noeud, list[Noeud]] = {}
	for n in vers_but:
		for v in sans.voisins(n):
			inv.setdefault(v, []).append(n)
	butn = min(atteint, key=lambda b: dist[b])
	retour_but = {butn: 0}
	file = deque([butn])
	while file:
		n = file.popleft()
		for v in inv.get(n, []):
			if v not in retour_but:
				retour_but[v] = retour_but[n] + 1
				file.append(v)
	axe = {n for n in dist if n in retour_but and dist[n] + retour_but[n] == aller}
	r.info(f"corridor du chemin principal (cases sur un plus court chemin) : {len(axe)} cases")

	# 5. Dresseurs.
	dresseurs = {p.attrs["role"]: (nom, p) for nom, plan in plans.items()
		for p in plan.of_kind("dresseur")}
	r.critere(sorted(dresseurs) == ["G-1", "G-2", "G-3", "G-4", "G-5"],
		f"Dresseurs : {sorted(dresseurs)} (G-1, G-2 au 1F nord ; G-3, G-4 au B1F ; G-5 au 1F sud)")
	vues: dict[str, list[Case]] = {}
	for role, (nom, p) in sorted(dresseurs.items()):
		vue = ligne_de_vue(initial.mondes[nom], p)
		vues[role] = vue
		sight = int(p.attrs.get("sight", "0"))
		r.critere(len(vue) == sight and plans[nom].at(*p.cells[0]) in CALME,
			f"{role} {p.ident} {nom} {p.cells[0]} tourné {p.attrs['facing']} : vision "
			f"{len(vue)}/{sight} dégagée {vue[0]}…{vue[-1]}")
	zone_nord = {"G-1": nord, "G-2": nord, "G-5": sud}
	objets = [(nom, p) for nom, plan in plans.items()
		for p in plan.of_kind("objet_visible") + plan.of_kind("objet_cache")]
	for role, (nom, p) in sorted(dresseurs.items()):
		inev = p.attrs.get("inevitable") == "oui"
		g = Grotte(plans, bloquees={nom: set(vues[role])}, sans_dresseurs=True)
		d = g.bfs([depart])[0]
		contournable = min((d[b] for b in but if b in d), default=INF)
		if inev:
			if role == "G-1":
				dep = ("1F", *plans["1F"].positions["from_route_10_n"].cells[0])
			else:
				dep = ("B1F", *plans["B1F"].positions["arrivee_a"].cells[0])
			premiere = premiere_detection(sans, dep, nom, vues[role])
			# G-4 bloque aussi le passage par sa case.
			bloc = Grotte(plans, bloquees={nom: set(p.cells)}, sans_dresseurs=True).bfs([depart])[0]
			par_place = not any(b in bloc for b in but)
			r.critere((contournable >= INF or par_place) and premiere >= DETECTION_MIN,
				f"{role} inévitable ({'par la ligne de vue' if contournable >= INF else ''}"
				f"{' et par sa place' if par_place else ''}) ; première case vue à {premiere} cases "
				f"(attendu ≥ {DETECTION_MIN})")
		else:
			sur_axe = [c for c in vues[role] if (nom, *c) in axe]
			g2 = Grotte(plans, bloquees={nom: set(p.cells)}, sans_dresseurs=True)
			d2 = g2.bfs([depart])[0]
			ferme = [n for n2, o in objets for n in [acces(g2, n2, o)] if not any(c in d2 for c in n)]
			r.critere(contournable == aller and not sur_axe and not ferme,
				f"{role} évitable sans détour : sortie en {contournable} pas hors de sa vue ; vue "
				f"hors du corridor principal ({'oui' if not sur_axe else sur_axe}) ; ne ferme aucun objet")

	# 6. Objets, embranchements.
	lignes = {(nom, *c) for role, (nom, p) in dresseurs.items() for c in vues[role]}
	for nom, p in objets:
		a = [n for n in acces(sans, nom, p) if n in dist]
		dmin = min((dist[n] for n in a), default=INF)
		texte = f"{p.kind} {p.ident} {nom} {p.cells[0]} ({p.attrs.get('item', '?')}) : atteint en {dmin} pas"
		vrai = dmin < INF
		if p.kind == "objet_cache":
			c = p.cells[0]
			sol = plans[nom].at(*c)
			racines = [(c[0] + dx, c[1] + dy) for dx, dy in DIRECTIONS
				if plans[nom].at(c[0] + dx, c[1] + dy) == "r"]
			vrai &= sol in CALME and len(racines) >= 2
			texte += f", sol « {sol} », racines {racines}"
		else:
			vrai &= (nom, *p.cells[0]) not in lignes
		r.critere(vrai, texte)
	r.critere(sum(1 for _, p in objets if p.kind == "objet_visible") == 3
		and sum(1 for _, p in objets if p.kind == "objet_cache") == 1,
		"3 objets visibles (Corde Sortie, Super Potion, Antidote) + 1 caché (Super Potion)")
	items = sorted(p.attrs["item"] for _, p in objets)
	r.critere(items == ["antidote", "escape_rope", "super_potion", "super_potion"], f"objets : {items}")
	branches = [(nom, p) for nom, plan in plans.items() for p in plan.of_kind("branche")]
	n1 = sum(1 for nom, p in branches if nom == "1F" and p.cells[0][1] <= max(c[1] for c in nord))
	nb = sum(1 for nom, p in branches if nom == "B1F")
	r.critere(n1 >= 2 and nb == 3, f"embranchements : {n1} au 1F nord (2 attendus ; "
		f"{sum(1 for nom, p in branches if nom == '1F') - n1} au 1F sud en plus), {nb} au B1F (3 attendus)")
	pos_tout = {(nom, c): p for nom, plan in plans.items() for p in plan.positions.values()
		for c in p.cells}
	for nom, p in sorted(branches, key=lambda b: (b[0], b[1].ident)):
		fin = (nom, *p.cells[0])
		a = acces(sans, nom, plans[nom].positions[p.attrs["of"]]) if p.attrs["contenu"] != "vue" \
			else [fin]
		# Distance minimale du corridor du chemin principal à la fin de la branche.
		dd = {n: 0 for n in axe}
		file = deque(axe)
		while file:
			n = file.popleft()
			for v in sans.voisins(n):
				if v not in dd:
					dd[v] = dd[n] + 1
					file.append(v)
		k = min((dd.get(n, INF) for n in a), default=INF)
		contenu = p.attrs["contenu"]
		cible = plans[nom].positions[p.attrs["of"]]
		bon = k <= BRANCHE_MAX and cible.kind in ("objet_visible", "objet_cache", "dresseur", "halo")
		r.critere(bon, f"branche {p.ident} ({nom}) : bout à {k} pas du chemin principal "
			f"(≤ {BRANCHE_MAX}), finit sur {contenu} « {p.attrs['of']} »")

	# 7. Gravats.
	est_gravats = lambda n: plans[n[0]].at(n[1], n[2]) == GRAVATS  # noqa: E731
	cout = sans.gravats_min([depart], est_gravats)
	gmin = min((cout[b] for b in but if b in cout), default=INF)
	lo, hi = GRAVATS_SUR_CHEMIN
	zones_nommees: dict[str, tuple[str, set[Case]]] = {}
	for nom, plan in plans.items():
		zones = zones_gravats(plan)
		marques = {p.attrs["role"]: p.cells[0] for p in plan.of_kind("gravats")}
		for role, c in marques.items():
			for z in zones:
				if c in z:
					zones_nommees[f"{nom}-{role}"] = (nom, z)
		nommees = [z for (n, z) in zones_nommees.values() if n == nom]
		r.critere(len(marques) == len(zones) == len(nommees),
			f"{nom} : {len(zones)} zone(s) de gravats, toutes nommées "
			f"({', '.join(k.split('-')[1] + ' ' + str(len(z)) for k, (n, z) in zones_nommees.items() if n == nom)})")
	obligatoires = {}
	for cle, (nom, zone) in zones_nommees.items():
		g = Grotte(plans, bloquees={nom: zone}, sans_dresseurs=True)
		if not any(b in g.bfs([depart])[0] for b in but):
			n = sans.gravats_min([depart], lambda v, z=zone, m=nom: v[0] == m and (v[1], v[2]) in z)
			obligatoires[cle] = min(n[b] for b in but if b in n)
	r.critere(lo <= gmin <= hi, f"gravats sur le chemin le moins exposé : {gmin} cases "
		f"({lo} à {hi}) ; zones incontournables : "
		f"{', '.join(f'{k} ({v} cases)' for k, v in obligatoires.items())}")
	sur_court = sum(1 for n in trajet if est_gravats(n))
	r.info(f"le plus court en pas traverse {sur_court} cases de gravats")
	# Visibilité : chaque entrée dans une zone obligatoire se fait après deux cases de sol en ligne
	# droite (praticables, hors gravats) — jamais dans l'angle mort d'un virage.
	fautes_vue = []
	for cle in obligatoires:
		nom, zone = zones_nommees[cle]
		monde = sans.mondes[nom]
		for (x, y) in zone:
			for dx, dy in DIRECTIONS:
				c = (x - dx, y - dy)            # case d'où l'on entre dans (x, y)
				if c in zone or not monde.libre(c):
					continue
				derriere = [(c[0] - dx * k, c[1] - dy * k) for k in (1, 2)]
				if not all(monde.libre(q) and q not in zone for q in derriere):
					fautes_vue.append(f"{cle} entrée {c}→{(x, y)}")
	r.critere(not fautes_vue, "chaque gravat obligatoire est visible ≥ 2 cases avant d'y marcher, "
		f"en ligne droite {fautes_vue[:4]}")
	tot_g = tot_p = 0
	for nom, plan in plans.items():
		prat = sum(1 for y in range(plan.height) for x in range(plan.width)
			if plan.at(x, y) in plan.praticables)
		gr = len(plan.cells_of(GRAVATS))
		tot_g += gr
		tot_p += prat
		r.info(f"{nom} : {prat} cases praticables, dont {gr} de gravats ({100 * gr / prat:.0f} %)")
	mg, mp = mont_selenite_gravats()
	r.critere(tot_g / tot_p > mg / mp, f"part de gravats {100 * tot_g / tot_p:.1f} % "
		f"({tot_g} / {tot_p}) > Mont Sélénite {100 * mg / mp:.1f} % ({mg} / {mp})")

	# 8. Passage étroit, repères.
	b1 = plans["B1F"]
	pas = b1.positions["repere_passage"]
	etroit = all(b1.at(x, y - 1) not in b1.praticables and b1.at(x, y + 1) not in b1.praticables
		and b1.at(x, y) in CALME for x, y in pas.cells) and len(pas.cells) == PASSAGE
	g4 = dresseurs["G-4"][1]
	apres = Grotte(plans, sans_dresseurs=True)
	eb_arr = ("B1F", *b1.positions["arrivee_b"].cells[0])
	# Sans le passage, l'échelle B n'est plus atteignable.
	coupe = Grotte(plans, bloquees={"B1F": set(pas.cells)}, sans_dresseurs=True).bfs([depart])[0]
	r.critere(etroit and g4.cells[0] in pas.cells and eb_arr not in coupe,
		f"passage étroit : {len(pas.cells)} cases de 1 de large, Marcel dedans, seul accès à "
		f"l'échelle B ({'oui' if eb_arr not in coupe else 'NON'})")
	noms = {p.attrs.get("role") for plan in plans.values() for p in plan.of_kind("repere")}
	r.critere({"colonne", "paroi", "flaque", "racines", "passage"} <= noms
		and plans["1F"].positions["panneau_randonneur"].kind == "panneau",
		"repères : colonne, paroi fendue, racines, flaque, passage étroit (B1F) + panneau (1F nord)")
	r.critere(all(len(plan.cells_of(c)) >= n for plan, c, n in
		((b1, "K", 10), (b1, "w", 6), (b1, "f", 1), (b1, "r", 2), (b1, "j", 3))),
		"colonne ≥ 10 cases, flaque ≥ 6, paroi fendue, racines, filet de jour")

	# 9. Halos.
	halos = [(nom, p) for nom, plan in plans.items() for p in plan.of_kind("halo")]
	filets = [(n, p) for n, p in halos if p.attrs.get("type") == "shaft"]
	lampes = [(n, p) for n, p in halos if p.attrs.get("type") == "lamp"]
	f_ok = len(filets) == 1 and any(
		b1.at(filets[0][1].cells[0][0] + dx, filets[0][1].cells[0][1] + dy) == "f"
		for dx, dy in DIRECTIONS + [(0, 0)] + [(0, -2)])
	r.critere(f_ok and LAMPES[0] <= len(lampes) <= LAMPES[1],
		f"halos : 1 filet de jour près de la paroi fendue, {len(lampes)} lampes "
		f"({LAMPES[0]} à {LAMPES[1]})")
	goulets_lampes = []
	for nom, p in lampes:
		x, y = p.cells[0]
		ouverts = sum(1 for dx, dy in DIRECTIONS
			if plans[nom].at(x + dx, y + dy) in plans[nom].praticables)
		if ouverts < 3:
			goulets_lampes.append((nom, p.ident))
	r.critere(not goulets_lampes, f"aucune lampe dans un goulet {goulets_lampes}")

	# 10. Retour, orphelines, culs-de-sac.
	noeuds = set(dist) - sans.sorties
	inverse: dict[Noeud, list[Noeud]] = {}
	for n in noeuds:
		for v in sans.voisins(n):
			inverse.setdefault(v, []).append(n)
	ent = {("1F", *c) for c in entree}
	retour = set(ent & set(dist))
	file = deque(retour)
	while file:
		n = file.popleft()
		for v in inverse.get(n, []):
			if v not in retour:
				retour.add(v)
				file.append(v)
	sans_retour = sorted(noeuds - retour)
	r.critere(not sans_retour, f"retour à pied à l'entrée nord possible depuis les {len(noeuds)} "
		f"cases atteignables {sans_retour[:4]}")
	orphelins = []
	for nom, plan in plans.items():
		monde = sans.mondes[nom]
		for y in range(plan.height):
			for x in range(plan.width):
				n = (nom, x, y)
				if monde.libre((x, y)) and n not in dist and n not in sans.echelles:
					orphelins.append(n)
	r.critere(not orphelins, f"aucune case praticable orpheline {orphelins[:4]}")
	marques = {(nom, c) for nom, plan in plans.items() for p in plan.positions.values()
		if p.kind not in ("gravats",) for c in p.cells}
	inutiles, goulets = [], 0
	for nom, plan in plans.items():
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
				if not carre and (nom, x, y) in set(trajet):
					goulets += 1
	r.critere(not inutiles, f"aucun cul-de-sac inutile {inutiles[:6]}")
	r.info(f"goulets d'une case sur le chemin principal (compagnon masqué) : {goulets} cases")

	# 11. Durée.
	rencontres = gmin * TAUX
	combats = sum(S_COMBATS.values())
	duree = aller * S_PAR_PAS + echelles * S_ECHELLE + combats + rencontres * S_SAUVAGE
	r.info(f"traversée directe estimée : {aller} pas × {S_PAR_PAS} s + {echelles} échelles × "
		f"{S_ECHELLE} s + combats inévitables {' + '.join(f'{k} {v} s' for k, v in S_COMBATS.items())}"
		f" + {rencontres:.2f} rencontre(s) attendue(s) × {S_SAUVAGE} s = {duree:.0f} s "
		f"({int(duree // 60)} min {int(duree % 60):02d} s) ; cible 6 à 8 min")
	r.critere(360 <= duree <= 480, "durée estimée entre 6 et 8 minutes")
	return r.ok


def main() -> int:
	ok = verifier()
	print("\nPlan conforme." if ok else "\nPlan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
