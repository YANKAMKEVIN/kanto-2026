#!/usr/bin/env python3
"""Vérifie les grilles du jalon 10 par recherche de chemin (J10 T1, docs/tech/jalon-10.md §1.3).

Grilles : `tools/plans/route_2_nord.txt`, `argenta.txt`, `argenta_arene.txt`, `argenta_musee.txt`,
`argenta_musee_science.txt`. Lecture par `plan_grille.lire` ; déplacements de `plan_check.Monde`
(4 directions, un pas par case), avec deux différences propres à ces cartes :
  - cases praticables propres à chaque grille (`.=hvDp` dehors, plus `X` dans les intérieurs) ;
  - une **porte** (`D`, STEP_ON) termine un trajet : on peut y entrer, on ne la traverse pas.
Les positions `bloque` (PNJ, Pokémon, objets visibles, panneaux) bloquent leurs cases.

Critères (repris par les tests des cartes, T11, T13, T17) :
  Route 2 nord — raccord nord de 3 cases aligné sur Argenta ; porte du poste ↔ raccord nord ;
    H1 et H2 évitables ; Potion atteignable hors herbes ; éboulis : rien d'atteignable à l'est ;
    Montagnard hors du chemin et hors herbes ; positions cohérentes.
  Argenta — entrée sud de 3 cases ; toutes les portes atteignables depuis l'entrée sud ;
    emprises des bâtiments = EMPRISES (portes comprises) ; le Musée dans le cadre de la caméra
    au point d'arrivée ; le passage est (48, 25..27) seul accès à la sortie est ; aucune routine
    sur une porte, devant une porte ni sur un panneau ; panneaux hors de la rue.
    J25 (dossier 28 §7) : la porte arrière du Musée (`porte_reserve`) n'est pas une case `D` mais
    un warp PUSH derrière un arbre à Couper (`arbre_reserve`) : fermée tant que l'arbre est là,
    atteignable une fois l'arbre coupé (ses cases deviennent praticables), poussée vers le Musée.
  Arène — caméra immobile (Pierre visible depuis l'entrée) ; Pierre atteignable ; la vision de
    Liam couvre toute la largeur du passage central ; chemin direct dans sa vision, détour hors
    de sa vision ; son approche ne ferme aucun passage.
  Musée — sorties et passage entre salles atteignables, mêmes ouvertures dans les deux salles
    (une seule coque), chaque point d'examen a une case d'où on l'examine.

Usage : python3 tools/art/plan_check_argenta.py   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS, INF, Monde, zones_herbes  # noqa: E402
from plan_grille import HERBES, PORTE, PRATICABLES, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]

## Décalage entre les deux cartes : Argenta x = Route 2 nord x + RACCORD_DX (plan --empiler … 3).
RACCORD_DX = 3
## Vue de jeu sur le S24 (2340 × 1080 affichés, référence 1920 × 1080 en « expand ») en cases.
VUE_S24 = (2340 / 96, 1080 / 96)
## Plus petite vue garantie (16:9, 1920 × 1080) : une salle qui y tient a une caméra immobile.
VUE_MIN = (1920 // 96, 1080 // 96)
## Part minimale de l'emprise du Musée dans le cadre de la caméra au point d'arrivée (défaut).
MUSEE_PART_MIN = 1 / 3

## Emprises des bâtiments (caractère de la grille → largeur, hauteur en cases, colonnes de la
## porte dans la rangée de la porte, rangée de la porte : « bas » ou « haut »). Source unique
## reprise par la fiche de la série 12 et par `tools/art/serie12.py`.
EMPRISES = {
	"argenta": {
		"C": (8, 7, (3, 4), "bas"),    # bldg_centre_01 réutilisé : width 8, open (−1, 0), (0, 0)
		"O": (8, 7, (3, 4), "bas"),    # bldg_boutique_01 réutilisé
		"M": (12, 9, (5, 6), "bas"),   # bldg_musee_argenta_01 (neuf)
		"Z": (12, 7, (5, 6), "bas"),   # bldg_arene_argenta_01 (neuf)
		"m": (7, 6, (3,), "bas"),      # bldg_maison_argenta_01 (neuf, deux fois)
	},
	"route_2_nord": {
		"P": (7, 3, (3,), "haut"),     # bldg_poste_foret_nord_01 (neuf) : porte au bord haut
	},
}
## Liam : case, direction du regard, portée (bloc `trainer` du J9, `sight`).
## J25 : portes PUSH derrière un arbre à Couper (warp → arbuste, direction de la poussée). Ces
## portes ne sont pas des cases `D` ; l'arbre coupé (drapeau `cut_pewter_museum_tree`) libère ses
## cases, comme les arbustes du J17 (`plan_check.py`, cases libérées par un drapeau).
PORTES_COUPE = {"porte_reserve": ("arbre_reserve", (-1, 0))}
LIAM_SIGHT = 5
LIAM_REGARD = (1, 0)


class Carte(Monde):
	"""`plan_check.Monde` avec des cases praticables propres à la grille et des portes
	terminales (on y entre, on n'en ressort pas : c'est un passage vers une autre carte)."""

	def __init__(self, plan: Plan, praticables: str = "".join(sorted(PRATICABLES)),
			bloquees: set[Case] = frozenset()) -> None:
		super().__init__(plan, bloquees)
		self.praticables = set(praticables)
		self.portes = set(plan.cells_of(PORTE)) if PORTE in self.praticables else set()

	def libre(self, c: Case) -> bool:
		x, y = c
		if not (0 <= x < self.plan.width and 0 <= y < self.plan.height):
			return False
		return c not in self.bloquees and self.plan.at(x, y) in self.praticables

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Carte":
		carte = Carte(self.plan, "".join(self.praticables), self.bloquees | set(cases))
		return carte


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


def _cellules(plan: Plan, ident: str) -> list[Case]:
	return list(plan.positions[ident].cells)


def _composantes(cases: set[Case]) -> list[set[Case]]:
	reste, groupes = set(cases), []
	while reste:
		germe = reste.pop()
		groupe, pile = {germe}, [germe]
		while pile:
			x, y = pile.pop()
			for dx, dy in DIRECTIONS:
				n = (x + dx, y + dy)
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


def _bord(plan: Plan, carte: Carte, cote: str) -> list[Case]:
	if cote == "bas":
		return [(x, plan.height - 1) for x in range(plan.width) if carte.libre((x, plan.height - 1))]
	if cote == "haut":
		return [(x, 0) for x in range(plan.width) if carte.libre((x, 0))]
	return [(plan.width - 1, y) for y in range(plan.height) if carte.libre((plan.width - 1, y))]


def _acces(carte: Carte, dist: dict[Case, int], c: Case) -> Case | None:
	"""Case voisine atteignable d'où l'on examine / parle à c (la plus proche)."""
	voisines = [(c[0] + dx, c[1] + dy) for dx, dy in DIRECTIONS]
	voisines = [v for v in voisines if v in dist and v not in carte.portes]
	return min(voisines, key=lambda v: dist[v]) if voisines else None


def _positions(r: Rapport, plan: Plan, carte: Carte, dist: dict[Case, int], sol: str,
		marques: str = "") -> None:
	"""Cohérence : PNJ, Pokémon, objets et repères sur `sol` (les PNJ des intérieurs peuvent
	avoir leur caractère propre, `marques`) ; tout point d'examen, PNJ et objet a une case
	voisine atteignable."""
	fautes = []
	for p in plan.positions.values():
		for c in p.cells:
			car = plan.at(*c)
			permis = sol + (marques if p.kind in ("pnj", "dresseur") else "")
			if p.kind in ("pnj", "pokemon", "objet_visible", "dresseur", "repere", "spawn") \
					and car not in permis:
				fautes.append(f"{p.ident} sur « {car} » en {c}")
		if p.kind in ("pnj", "pokemon", "objet_visible", "dresseur", "examen", "panneau"):
			if not any(_acces(carte, dist, c) for c in p.cells):
				fautes.append(f"{p.ident} {p.cells[0]} sans case d'accès atteignable")
		if p.kind in ("repere", "spawn", "declencheur") and not all(c in dist for c in p.cells):
			fautes.append(f"{p.ident} {p.cells[0]} hors d'atteinte")
	r.critere(not fautes, "positions cohérentes" + (" : " + " ; ".join(fautes) if fautes else
		" (sur des cases praticables, chacune atteignable ou examinable)"))


# --- Route 2 nord -----------------------------------------------------------------------

def route_2_nord(r: Rapport, plan: Plan, argenta: Plan) -> None:
	r.titre(f"Route 2 nord ({plan.width} × {plan.height})")
	carte = Carte(plan)
	nord = _bord(plan, carte, "haut")
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == 0)
	sud_argenta = _bord(argenta, Carte(argenta), "bas")
	alignes = [(x - RACCORD_DX, 0) for x, _ in sud_argenta]
	r.critere(len(nord) == 3 and nord == warps == alignes,
		f"raccord nord {[x for x, _ in nord]} = warps {[x for x, _ in warps]} = entrée sud "
		f"d'Argenta {[x for x, _ in sud_argenta]} − {RACCORD_DX}")

	porte = plan.cells_of(PORTE)
	r.critere(len(porte) == 1, f"une porte (poste) : {porte}")
	porte = porte[0]
	arrivee = _cellules(plan, "arrivee_poste")[0]
	r.critere(arrivee == (porte[0], porte[1] - 1), f"arrivée du poste {arrivee} devant la porte")
	depuis_nord = carte.distances(nord)
	depuis_poste = carte.distances([arrivee])
	traversee = min(depuis_poste.get(c, INF) for c in nord)
	r.critere(porte in depuis_nord and traversee < INF,
		f"porte du poste ↔ raccord nord : {depuis_nord.get(porte, INF)} pas depuis le nord, "
		f"{traversee} pas du poste au bord nord (Q-4 : ≈ {traversee * 0.27:.0f} s à la marche)")

	zones = zones_herbes(plan)
	r.critere(len(zones) == 2, f"{len(zones)} zones de hautes herbes (H1 au sud, H2 au nord)")
	toutes = set().union(*zones) if zones else set()
	for nom, zone in zip(("H1", "H2"), zones):
		d = carte.sans(zone).distances([arrivee])
		r.critere(any(c in d for c in nord), f"{nom} ({len(zone)} cases) évitable")
	sans_herbes = carte.sans(toutes).distances([arrivee])
	r.critere(any(c in sans_herbes for c in nord), "H1 et H2 évitables ensemble")

	potion = _cellules(plan, "potion")[0]
	acces = _acces(carte, sans_herbes, potion)
	direct = traversee
	via = (sans_herbes[acces] + min(carte.distances([acces]).get(c, INF) for c in nord)
		if acces else INF)
	r.critere(acces is not None, f"Potion {potion} atteignable hors herbes, depuis {acces} ; "
		f"détour : {via - direct} pas de plus que la traversée directe")

	eboulis = plan.cells_of("E")
	x_eboulis = min(x for x, _ in eboulis)
	tout = carte.distances([arrivee] + nord)
	a_l_est = sorted(c for c in tout if c[0] >= x_eboulis)
	examen = _cellules(plan, "examen_eboulis")
	r.critere(sorted(examen) == sorted(eboulis) and not a_l_est
		and all(_acces(carte, tout, c) for c in eboulis),
		f"éboulis {eboulis[0]}…{eboulis[-1]} : rien d'atteignable à l'est (x ≥ {x_eboulis}), "
		f"examinés depuis {sorted({_acces(carte, tout, c) for c in eboulis})}")

	montagnard = _cellules(plan, "montagnard")
	r.critere(all(plan.at(*c) == "." for c in montagnard),
		f"Montagnard {montagnard[0]}…{montagnard[-1]} hors du chemin et hors herbes")
	panneaux = [c for p in plan.of_kind("panneau") for c in p.cells]
	r.critere(all(plan.at(*c) == "." for c in panneaux), f"panneau(x) {panneaux} hors du chemin")
	_positions(r, plan, carte, tout, ".=")


# --- Argenta ----------------------------------------------------------------------------

def _emprises(r: Rapport, plan: Plan, nom: str) -> dict[str, list[set[Case]]]:
	trouvees: dict[str, list[set[Case]]] = {}
	portes = set(plan.cells_of(PORTE))
	for car, (largeur, hauteur, colonnes, rangee) in EMPRISES[nom].items():
		groupes = _composantes(set(plan.cells_of(car)))
		trouvees[car] = []
		for groupe in groupes:
			x0, y0, x1, y1 = _boite(groupe)
			y_porte = y1 if rangee == "bas" else y0
			attendues = {(x0 + i, y_porte) for i in colonnes}
			bloc = groupe | attendues
			bx0, by0, bx1, by1 = _boite(bloc)
			taille = (bx1 - bx0 + 1, by1 - by0 + 1)
			plein = len(bloc) == taille[0] * taille[1]
			ses_portes = {c for c in portes if bx0 <= c[0] <= bx1 and by0 <= c[1] <= by1}
			r.critere(taille == (largeur, hauteur) and plein and ses_portes == attendues,
				f"« {car} » ({bx0}..{bx1}, {by0}..{by1}) : {taille[0]} × {taille[1]} "
				f"(attendu {largeur} × {hauteur}), porte {sorted(ses_portes)} "
				f"(colonnes {list(colonnes)} de la rangée du {rangee})")
			trouvees[car].append(bloc)
	return trouvees


def argenta(r: Rapport, plan: Plan) -> None:
	r.titre(f"Argenta ({plan.width} × {plan.height})")
	carte = Carte(plan)
	sud = _bord(plan, carte, "bas")
	warps_sud = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[1] == plan.height - 1)
	r.critere(len(sud) == 3 and sud == warps_sud,
		f"entrée sud {[x for x, _ in sud]} = warps {[x for x, _ in warps_sud]}")
	est = _bord(plan, carte, "est")
	r.critere(est == sorted(_cellules(plan, "warp_est")),
		f"sortie est {[y for _, y in est]} (x {plan.width - 1}) = warp_est")

	batiments = _emprises(r, plan, "argenta")
	dist = carte.distances(sud)
	portes = set(plan.cells_of(PORTE))
	warps_portes = {c for p in plan.of_kind("warp") if p.ident.startswith("porte_")
		and p.ident not in PORTES_COUPE for c in p.cells}
	r.critere(warps_portes == portes, f"positions porte_* = cases D ({len(portes)} cases)")
	manquantes = []
	for p in plan.of_kind("warp"):
		if not p.ident.startswith("porte_") or p.ident in PORTES_COUPE:
			continue
		devant = [(x, y + 1) for x, y in p.cells]
		if not all(c in dist for c in p.cells) or not all(c in dist for c in devant):
			manquantes.append(p.ident)
		r.info(f"{p.ident:18} {p.cells[0]} : {min(dist.get(c, INF) for c in p.cells)} pas de l'entrée")
	r.critere(not manquantes, "toutes les portes atteignables depuis l'entrée sud (STEP_ON ↑ "
		"depuis la case du dessous)" + (f" — manquantes : {manquantes}" if manquantes else ""))
	for ident, (arbre, (dx, dy)) in PORTES_COUPE.items():
		cases = _cellules(plan, ident)
		arbre_cases = _cellules(plan, arbre)
		coupe = Carte(plan, "".join(carte.praticables))
		coupe.bloquees -= set(arbre_cases)  # arbre coupé : ses cases redeviennent praticables
		dist_coupe = coupe.distances(sud)
		poussee = [(x + dx, y + dy) for x, y in cases]
		r.critere(plan.positions[arbre].kind == "arbuste" and plan.positions[arbre].bloque
			and not any(c in dist for c in cases) and all(c in dist_coupe for c in cases)
			and _acces(carte, dist, arbre_cases[0]) is not None
			and all(plan.at(*c) == "M" for c in poussee),
			f"{ident} {cases[0]} (J25) : fermée par {arbre} (examiné depuis "
			f"{_acces(carte, dist, arbre_cases[0])}), atteignable une fois l'arbre coupé "
			f"({min(dist_coupe.get(c, INF) for c in cases)} pas de l'entrée), poussée ({dx}, {dy}) "
			f"vers « {plan.at(*poussee[0])} » en {poussee[0]}")

	# Le Musée dans le cadre de la caméra au point d'arrivée (caméra bornée à la carte).
	musee = batiments["M"][0]
	mx0, my0, mx1, my1 = _boite(musee)
	vw, vh = VUE_S24
	parts, portes_vues = [], []
	porte_musee = _cellules(plan, "porte_musee")
	for x, y in sud:
		cx = min(max(x + 0.5, vw / 2), plan.width - vw / 2)
		cy = min(max(y + 0.5, vh / 2), plan.height - vh / 2)
		gx0, gy0, gx1, gy1 = cx - vw / 2, cy - vh / 2, cx + vw / 2, cy + vh / 2
		lx = max(0.0, min(gx1, mx1 + 1) - max(gx0, mx0))
		ly = max(0.0, min(gy1, my1 + 1) - max(gy0, my0))
		parts.append(lx * ly / ((mx1 - mx0 + 1) * (my1 - my0 + 1)))
		portes_vues.append(all(gx0 <= px and px + 1 <= gx1 and gy0 <= py and py + 1 <= gy1
			for px, py in porte_musee))
	r.critere(min(parts) >= MUSEE_PART_MIN and all(portes_vues),
		f"Musée dans le cadre à l'arrivée ({vw:.1f} × {vh:.2f} cases) : "
		f"{min(parts):.0%}–{max(parts):.0%} de son emprise et sa porte, depuis x 17..19 "
		f"(seuil {MUSEE_PART_MIN:.0%})")

	# Passage est : seul accès à la sortie est.
	passage = _cellules(plan, "verrou_route_3")
	sans_passage = carte.sans(passage).distances(sud)
	r.critere(all(c in dist for c in est) and not any(c in sans_passage for c in est)
		and sorted(passage) == [(48, 25), (48, 26), (48, 27)],
		f"passage est {passage[0]}…{passage[-1]} : seul accès à la sortie est "
		f"({min(dist.get(c, INF) for c in est)} pas de l'entrée sud)")
	apres = _cellules(plan, "garde_route_3_apres")[0]
	r.critere(apres in dist and apres not in passage,
		f"place du garde après le badge {apres} hors du passage")

	# Routines : ni sur une porte, ni devant, ni sur un panneau ; panneaux hors de la rue.
	devant = {(x, y + 1) for x, y in portes}
	panneaux = {c for p in plan.of_kind("panneau") for c in p.cells}
	fautes = [f"{p.ident} {c}" for p in plan.positions.values() if p.kind in ("pnj", "pokemon")
		for c in p.cells if c in portes or c in devant or c in panneaux]
	r.critere(not fautes, "aucune routine sur une porte, devant une porte ni sur un panneau"
		+ (f" — {fautes}" if fautes else ""))
	rue = [f"{p.ident} {c} « {plan.at(*c)} »" for p in plan.of_kind("panneau") for c in p.cells
		if plan.at(*c) != "."]
	r.critere(not rue, "panneaux sur l'herbe, hors de la rue et de la place"
		+ (f" — {rue}" if rue else ""))
	arrivee = _cellules(plan, "arrivee")
	r.critere(all(c in dist and plan.at(*c) == "=" for c in arrivee)
		and [x for x, _ in arrivee] == [x for x, _ in sud],
		f"déclencheur d'arrivée {arrivee[0]}…{arrivee[-1]} sur l'avenue, au-dessus de l'entrée")
	for car, attendu in (("R", (3, 3)), ("k", (3, 2))):
		groupes = _composantes(set(plan.cells_of(car)))
		tailles = [(b[2] - b[0] + 1, b[3] - b[1] + 1) for b in map(_boite, groupes)]
		r.critere(tailles == [attendu], f"« {car} » : emprise(s) {tailles} (attendu {attendu})")
	_positions(r, plan, carte, dist, ".=p")


# --- Arène ------------------------------------------------------------------------------

def arene(r: Rapport, plan: Plan) -> None:
	r.titre(f"Arène ({plan.width} × {plan.height})")
	carte = Carte(plan, ".X")
	r.critere(plan.width <= VUE_MIN[0] and plan.height <= VUE_MIN[1],
		f"salle {plan.width} × {plan.height} ≤ {VUE_MIN[0]} × {VUE_MIN[1]} : caméra immobile, "
		"Pierre visible depuis l'entrée")
	entree = _cellules(plan, "entree")[0]
	sortie = _cellules(plan, "sortie")
	# J10 T13 : sortie sur l'avant-dernière rangée (mur du bas peint sur 2 rangées, convention des
	# intérieurs), entrée sur la sortie (la dalle).
	r.critere(sortie == [(x, plan.height - 2) for x in (6, 7, 8)] and plan.cells_of("X") == sortie
		and entree == (7, plan.height - 2), f"sortie {sortie[0]}…{sortie[-1]} au mur du bas, "
		f"entrée {entree} sur la dalle")
	pierre = plan.cells_of("P")[0]
	parler = _cellules(plan, "parler_pierre")[0]
	dist = carte.distances([entree])
	r.critere(pierre == _cellules(plan, "pierre")[0] and parler == (pierre[0], pierre[1] + 1)
		and parler in dist, f"Pierre {pierre} atteignable : on lui parle depuis {parler}, "
		f"{dist.get(parler, INF)} pas de l'entrée")

	liam = plan.cells_of("L")[0]
	vision = []
	c = liam
	for _ in range(LIAM_SIGHT):
		c = (c[0] + LIAM_REGARD[0], c[1] + LIAM_REGARD[1])
		if not carte.libre(c):
			break
		vision.append(c)
	suivante = (vision[-1][0] + LIAM_REGARD[0], vision[-1][1] + LIAM_REGARD[1])
	r.critere(liam == _cellules(plan, "liam")[0] and not carte.libre(suivante),
		f"vision de Liam {liam} → : {vision[0]}…{vision[-1]} ({len(vision)} cases), arrêtée par "
		f"« {plan.at(*suivante)} » en {suivante} : toute la largeur du passage central")
	sans_vision = carte.sans(vision).distances([entree])
	direct, detour = dist.get(parler, INF), sans_vision.get(parler, INF)
	r.critere(direct < detour < INF,
		f"chemin direct {direct} pas, dans sa vision (inévitable par là) ; détour hors de sa "
		f"vision {detour} pas (évitable)")
	# Approche : Liam s'arrête sur la case voisine du joueur vu, puis y reste.
	fermes = []
	for vu in vision:
		arret = (vu[0] - LIAM_REGARD[0], vu[1] - LIAM_REGARD[1])
		deplace = Carte(plan, ".X", (carte.bloquees - {liam}) | {arret})
		if parler not in deplace.distances([entree]) or parler not in deplace.distances([vu]):
			fermes.append(arret)
	r.critere(not fermes, "son approche ne ferme aucun passage (Liam arrêté en "
		f"{[(v[0] - 1, v[1]) for v in vision]})" + (f" — fermé par {fermes}" if fermes else ""))
	_positions(r, plan, carte, dist, ".X", "PLG")


# --- Musée ------------------------------------------------------------------------------

def musee(r: Rapport, hall: Plan, science: Plan) -> None:
	r.titre(f"Musée (salle principale {hall.width} × {hall.height}, salle science "
		f"{science.width} × {science.height})")
	r.critere((hall.width, hall.height) == (science.width, science.height) == (15, 10),
		"deux salles de 15 × 10 (une seule coque)")
	carte = Carte(hall, ".DX")
	entree = _cellules(hall, "entree")[0]
	dist = carte.distances([entree])
	nord = _cellules(hall, "vers_science")
	r.critere(all(c in dist for c in nord) and all(c in dist for c in _cellules(hall, "sortie")),
		f"salle principale : passage nord {nord[0]}…{nord[-1]} à {min(dist[c] for c in nord)} pas "
		"de l'entrée, sortie atteignable")
	porte_labo = [c for c in science.cells_of("L")]
	r.critere(sorted(porte_labo) == sorted(nord) and sorted(_cellules(science, "sortie"))
		== sorted(_cellules(hall, "sortie")), "même arche nord (fermée par la porte du "
		"laboratoire dans la salle science) et même sortie dans les deux salles")
	_positions(r, hall, carte, dist, ".X")
	carte_s = Carte(science, ".X")
	dist_s = carte_s.distances([_cellules(science, "depuis_hall")[0]])
	r.critere(all(c in dist_s for c in _cellules(science, "sortie")),
		"salle science : retour vers la salle principale atteignable")
	_positions(r, science, carte_s, dist_s, ".X", "c")


def main() -> int:
	r = Rapport()
	plans = {nom: lire(PLANS / f"{nom}.txt") for nom in
		("route_2_nord", "argenta", "argenta_arene", "argenta_musee", "argenta_musee_science")}
	route_2_nord(r, plans["route_2_nord"], plans["argenta"])
	argenta(r, plans["argenta"])
	arene(r, plans["argenta_arene"])
	musee(r, plans["argenta_musee"], plans["argenta_musee_science"])
	print("\nGrilles conformes." if r.ok else "\nGrilles NON conformes.")
	return 0 if r.ok else 1


if __name__ == "__main__":
	sys.exit(main())
