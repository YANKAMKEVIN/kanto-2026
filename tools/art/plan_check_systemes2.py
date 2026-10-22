#!/usr/bin/env python3
"""Contrôle des grilles de QA de la passe systèmes 2 (`docs/tech/systemes-2.md` §1.3, §2.14, T3c).

Quatre contrôles **génériques**, réutilisables par les jalons de contenu (J24, J26, J27, J29) sur
leurs propres grilles :

- **Force** (`verifier_force`) : exploration exhaustive des états atteignables par poussée (rochers,
  trous bouchés, interrupteurs enfoncés, barrières ouvertes) avec les règles de `BoulderRules`
  (`jalon-24`, plan §2.7) ; **anti-blocage** : depuis chaque état atteignable, une sortie (warp,
  échelle ou trou ouvert) reste atteignable ; chaque trou se bouche, chaque interrupteur s'enfonce,
  chaque barrière s'ouvre, le but s'atteint.
- **Téléporteurs et portes à carte** (`verifier_teleporteurs`, plusieurs cartes) : chaque
  téléporteur mène à un point d'apparition existant et praticable ; arriver sur un téléporteur ne le
  déclenche pas ; le but s'atteint ; la carte est atteignable sans porte ; le but ne l'est pas sans
  carte ; retour toujours possible au départ ; graphe imprimé.
- **Surf et courants** (`verifier_mer`) : règles de `SurfRules` (monter de la terre vers l'eau
  surfable, nager, descendre) ; toute eau surfable est atteignable ; l'eau décor jamais ; chaque
  courant se termine (eau calme, terre ou passage) sans boucle ni blocage ; un Nageur est sur l'eau.
- **Monture** (`verifier_monture`, `verifier_liens_monture`) : pentes seulement sur la Piste, dérive de
  chaque case de pente jusqu'à un palier, Dresseur dont la vue coupe la pente, dormeur qui ferme une
  zone, rebord, porte d'intérieur ; warps entre qa_mount, qa_mount_piste et qa_mount_interieur.

Caractères communs (légende de chaque grille, ligne `PRATICABLES`) : `w` eau surfable, `~` eau
décor, `^ v < >` courant **sur l'eau** (grilles de mer) ou rebord `v` (grilles à terre : seul `v`),
`B` rocher (origine), `O` trou, `F` point de chute d'un rocher, `S` interrupteur, `|` barrière,
`T` téléporteur, `K` porte à carte, `/` pente, `s` Surf forcé, `E` entrée.

Usage : python3 -I tools/art/plan_check_systemes2.py           (grilles de QA de la passe)
        python3 -I tools/art/plan_check_systemes2.py --autotest (le contrôle refuse des pièges connus)
Code 1 si un critère échoue.
"""
from __future__ import annotations

import sys
import tempfile
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import verifier_legende  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402
from plan_grille import carte as carte_de  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
FLECHES = {"^": (0, -1), "v": (0, 1), "<": (-1, 0), ">": (1, 0)}
SORTIES = ("warp", "echelle", "passage")
MAX_ETATS = 500_000
MAX_COURANT = 64
Case = tuple[int, int]


def _plus(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _dans(plan: Plan, c: Case) -> bool:
	return 0 <= c[0] < plan.width and 0 <= c[1] < plan.height


def _cases(plan: Plan, kind: str) -> list[Case]:
	return [c for p in plan.of_kind(kind) for c in p.cells]


def _bloquees(plan: Plan, sauf: tuple[str, ...] = ()) -> set[Case]:
	return {c for p in plan.positions.values() if p.bloque and p.kind not in sauf for c in p.cells}


class Rapport:
	def __init__(self, titre: str) -> None:
		self.titre = titre
		self.echecs: list[str] = []
		self.notes: list[str] = []

	def ok(self, condition: bool, message: str) -> bool:
		if not condition:
			self.echecs.append(message)
		return condition

	def note(self, message: str) -> None:
		self.notes.append(message)

	def imprimer(self) -> bool:
		print(f"== {self.titre}")
		for n in self.notes:
			print(f"   {n}")
		for e in self.echecs:
			print(f"   ÉCHEC : {e}")
		print("   conforme" if not self.echecs else f"   {len(self.echecs)} échec(s)")
		return not self.echecs


# --- Force ------------------------------------------------------------------------------------

def verifier_force(chemin: Path, rapport: Rapport | None = None) -> Rapport:
	"""Anti-blocage et résolubilité d'une carte à rochers (une seule carte : changer de carte remet
	les rochers à leur origine, seuls les drapeaux restent). Générique (T21) : toutes les entrées de
	la carte à pied (`depart`, `spawn`, `chute_joueur`, sauf `surf=oui`), avec tous les jeux de
	drapeaux atteints lors d'une visite précédente ; un rocher désigné d'un trou bouché (`trou=`)
	ne revient pas. Sans Surf ni niveaux de sol : les Îles Écume gardent le contrôle du J24."""
	plan = lire(chemin)
	r = rapport or Rapport(f"Force : {chemin.name}")
	rochers0 = frozenset(plan.cells_of("B") + _cases(plan, "rocher"))
	trous = {c: p.attrs.get("drapeau", p.ident) for p in plan.of_kind("trou") for c in p.cells}
	inters = {c: p.attrs.get("drapeau", p.ident) for p in plan.of_kind("interrupteur")
		for c in p.cells}
	barrieres: dict[Case, str] = {c: p.attrs.get("ouverte_si", p.attrs.get("unless", ""))
		for p in plan.of_kind("barriere") for c in p.cells}
	trou_n = {p.attrs.get("n"): p.attrs.get("drapeau", p.ident) for p in plan.of_kind("trou")}
	designes = {c: trou_n.get(p.attrs.get("trou", ""), "") for p in plan.of_kind("rocher")
		for c in p.cells}
	interdits = set(_cases(plan, "interdit_rocher"))
	sorties = {c for k in SORTIES for c in _cases(plan, k)}
	buts = set(_cases(plan, "but"))
	fixes = _bloquees(plan, ("rocher", "barriere", "trou"))
	r.ok(all(d in inters.values() for d in barrieres.values()),
		"chaque barrière s'ouvre par le drapeau d'un interrupteur")
	r.ok(bool(sorties), "au moins une sortie (warp, échelle, passage)")
	entrees = [c for k in ("depart", "spawn", "chute_joueur") for p in plan.of_kind(k)
		if p.attrs.get("surf") != "oui" for c in p.cells]
	if not r.ok(bool(entrees), "au moins une entrée à pied (depart, spawn, chute_joueur)"):
		return r

	def sol(c: Case) -> bool:
		return _dans(plan, c) and plan.at(*c) in plan.praticables and c not in fixes

	def ouverte(c: Case, drapeaux: frozenset[str]) -> bool:
		return c not in barrieres or barrieres[c] in drapeaux

	def zone(depart_c: Case, rochers: frozenset[Case], drapeaux: frozenset[str]) -> tuple[set[Case], bool]:
		"""Cases où le joueur marche ; vrai si une sortie est atteinte (un trou ouvert compte :
		le joueur y tombe et quitte la carte)."""
		vues = {depart_c}
		file = deque([depart_c])
		sortie = depart_c in sorties
		while file:
			c = file.popleft()
			for d in DIRECTIONS:
				n = _plus(c, d)
				if n in vues or not sol(n) or n in rochers or not ouverte(n, drapeaux):
					continue
				if plan.at(*n) in "w~":
					continue
				if n in trous and trous[n] not in drapeaux:
					sortie = True  # chute : sortie de la carte
					continue
				vues.add(n)
				sortie = sortie or n in sorties
				file.append(n)
		return vues, sortie

	def pousser(rocher: Case, d: Case, rochers: frozenset[Case], drapeaux: frozenset[str]):
		cible = _plus(rocher, d)
		if not sol(cible) or plan.at(*cible) in "w~v" or cible in interdits:
			return None
		if cible in rochers or not ouverte(cible, drapeaux):
			return None
		autres = rochers - {rocher}
		if cible in trous and trous[cible] not in drapeaux:
			return autres, drapeaux | {trous[cible]}, "FELL"
		if cible in inters and inters[cible] not in drapeaux:
			return autres | {cible}, drapeaux | {inters[cible]}, "ON_SWITCH"
		return autres | {cible}, drapeaux, "MOVED"

	def entrer(drapeaux: frozenset[str]) -> list[tuple]:
		"""Arrivée sur la carte avec ces drapeaux : rochers à l'origine, sauf les désignés tombés."""
		rochers = frozenset(c for c in rochers0 if not designes.get(c) or designes[c] not in drapeaux)
		return [(e, rochers, drapeaux) for e in entrees]

	vus = set()
	file = deque(entrer(frozenset()))
	jeux_entres = {frozenset()}
	bloques: list[tuple] = []
	drapeaux_vus: set[str] = set()
	but_atteint = False
	refus_eau = False
	while file and len(vus) < MAX_ETATS:
		joueur, rochers, drapeaux = file.popleft()
		region, sortie = zone(joueur, rochers, drapeaux)
		cle = (min(region), rochers, drapeaux)
		if cle in vus:
			continue
		vus.add(cle)
		drapeaux_vus |= drapeaux
		if drapeaux not in jeux_entres:
			jeux_entres.add(drapeaux)
			file.extend(entrer(drapeaux))
		but_atteint = but_atteint or bool(region & buts)
		if not sortie:
			bloques.append((joueur, sorted(rochers), sorted(drapeaux)))
		for c in region:
			for d in DIRECTIONS:
				rocher = _plus(c, d)
				if rocher not in rochers:
					continue
				cible = _plus(rocher, d)
				if _dans(plan, cible) and plan.at(*cible) == "w":
					refus_eau = True
				res = pousser(rocher, d, rochers, drapeaux)
				if res is not None:
					file.append((rocher, res[0], res[1]))
	r.ok(len(vus) < MAX_ETATS, f"exploration complète (< {MAX_ETATS} états)")
	r.note(f"{len(vus)} états atteignables, {len(rochers0)} rochers, {len(trous)} trous, "
		f"{len(inters)} interrupteurs, {len(entrees)} entrée(s), {len(jeux_entres)} jeu(x) de drapeaux")
	r.ok(not bloques, f"anti-blocage : {len(bloques)} état(s) sans sortie, ex. {bloques[:1]}")
	for drapeau in sorted(set(trous.values()) | set(inters.values())):
		r.ok(drapeau in drapeaux_vus, f"« {drapeau} » peut être posé")
	if buts:
		r.ok(but_atteint, "le but est atteignable")
	if any(plan.at(*c) == "w" for y in range(plan.height) for c in [(x, y) for x in range(plan.width)]):
		r.ok(refus_eau, "un rocher peut être poussé contre l'eau (refus testé en QA)")
	if interdits:
		r.note(f"{len(interdits)} case(s) interdite(s) aux rochers")
	return r


def verifier_etage_inferieur(chemin: Path, dessus: Path) -> Rapport:
	"""Étage d'arrivée des chutes : points de chute praticables, sortie atteignable depuis chaque
	atterrissage, même avec tous les rochers tombés."""
	plan = lire(chemin)
	haut = lire(dessus)
	r = Rapport(f"Force, étage inférieur : {chemin.name}")
	tombes = set(_cases(plan, "chute_rocher"))
	sorties = {c for k in SORTIES for c in _cases(plan, k)}
	fixes = _bloquees(plan, ("chute_rocher",)) | tombes

	def sol(c: Case) -> bool:
		return _dans(plan, c) and plan.at(*c) in plan.praticables and c not in fixes

	trous_haut = {p.attrs.get("n") for p in haut.of_kind("trou")}
	trous_bas = {p.attrs.get("depuis", "").split(":")[-1] for p in plan.of_kind("chute_rocher")}
	r.ok(trous_haut == trous_bas, f"un point de chute par trou du dessus ({trous_haut} / {trous_bas})")
	r.ok(all(plan.at(*c) == "F" for c in tombes), "chaque point de chute est sur un « F »")
	for p in plan.of_kind("chute_joueur"):
		c = p.cells[0]
		vues, file = {c}, deque([c])
		while file:
			x = file.popleft()
			for d in DIRECTIONS:
				n = _plus(x, d)
				if n not in vues and sol(n):
					vues.add(n)
					file.append(n)
		r.ok(sol(c), f"{p.ident} : case libre")
		r.ok(bool(vues & sorties), f"{p.ident} : une sortie atteignable, rochers tombés compris")
	return r


# --- Téléporteurs et portes à carte -------------------------------------------------------------

# Objet qui donne la carte magnétique (grilles de QA : « objet » ; jalon 26 : « objet_visible »).
KINDS_CARTE = ("objet", "objet_visible")
# Passages entre cartes du lot (jalon 26, Sylphe SARL : étages reliés par escaliers et ascenseur) :
# un pas sur la case transporte, comme un téléporteur, vers `vers=<carte>:<repère>` ; la sortie de
# cabine d'ascenseur (`sortie`) liste ses destinations dans `etages=<carte>:<repère>;…`. Seules
# comptent les cibles présentes dans le lot de grilles contrôlé (les autres sorties sont ignorées).
KINDS_PASSAGE = ("escalier", "ascenseur", "warp", "sortie")


def passages(plans: dict[str, Plan], spawns: dict[tuple[str, str], Case]) \
		-> dict[tuple[str, Case], list[tuple[str, Case]]]:
	"""(carte, case) → destinations (carte, case) des passages qui visent une carte du lot."""
	out: dict[tuple[str, Case], list[tuple[str, Case]]] = {}
	for nom, plan in plans.items():
		for p in plan.positions.values():
			if p.kind not in KINDS_PASSAGE:
				continue
			cibles = [v for v in p.attrs.get("etages", "").split(";") if ":" in v]
			if ":" in p.attrs.get("vers", ""):
				cibles.append(p.attrs["vers"])
			dests = [(c, spawns[(c, s)]) for c, s in (v.split(":", 1) for v in cibles)
				if (c, s) in spawns]
			if dests:
				for c in p.cells:
					out[(nom, c)] = dests
	return out


def verifier_teleporteurs(chemins: list[Path], rapport: Rapport | None = None) -> Rapport:
	plans = {carte_de(c): lire(c) for c in chemins}
	r = rapport or Rapport("Téléporteurs : " + ", ".join(c.name for c in chemins))
	spawns: dict[tuple[str, str], Case] = {}
	for carte_, plan in plans.items():
		for p in plan.positions.values():
			if p.kind in ("spawn", "depart"):
				spawns[(carte_, p.ident)] = p.cells[0]
	liens = passages(plans, spawns)
	pads: dict[tuple[str, Case], tuple[str, Case]] = {}
	for carte, plan in plans.items():
		for p in plan.of_kind("teleporteur"):
			vers = p.attrs.get("vers", "")
			if not r.ok(":" in vers, f"{carte}/{p.ident} : vers=<carte>:<spawn>"):
				continue
			cible_carte, cible_spawn = vers.split(":", 1)
			cle = (cible_carte, cible_spawn)
			if not r.ok(cle in spawns, f"{carte}/{p.ident} : {vers} n'existe pas"):
				continue
			cc = spawns[cle]
			cible_plan = plans[cible_carte]
			r.ok(cible_plan.at(*cc) in cible_plan.praticables, f"{carte}/{p.ident} : arrivée praticable")
			r.ok(plan.at(*p.cells[0]) == "T", f"{carte}/{p.ident} : sur un « T »")
			pads[(carte, p.cells[0])] = (cible_carte, cc)
			r.note(f"{carte} {p.cells[0]} → {cible_carte} {cc}")
	for carte, plan in plans.items():
		for c in plan.cells_of("T"):
			r.ok((carte, c) in pads, f"{carte} {c} : « T » sans téléporteur")
	departs = [(k[0], c) for k, c in spawns.items() if k[1] == "depart"]
	if not r.ok(len(departs) == 1, "une seule position « depart »"):
		return r
	cles = {(carte, c) for carte, plan in plans.items() for k in KINDS_CARTE for p in plan.of_kind(k)
		if p.attrs.get("item") == "card_key" for c in p.cells}
	buts = {(carte, c) for carte, plan in plans.items() for c in _cases(plan, "but")}
	portes = {(carte, c) for carte, plan in plans.items() for c in plan.cells_of("K")}
	r.ok(all(plans[k].of_kind("porte_carte") for k, _ in portes) or not portes,
		"chaque carte à portes déclare ses « porte_carte »")

	# Un objet au sol se ramasse depuis une case voisine puis disparaît : il ne bloque pas.
	fixes_par_carte = {nom: _bloquees(plan, ("porte_carte",) + KINDS_CARTE) for nom, plan in plans.items()}

	def voisins(etat):
		carte, c, cle = etat
		plan = plans[carte]
		fixes = fixes_par_carte[carte]
		for d in DIRECTIONS:
			n = _plus(c, d)
			if not _dans(plan, n) or n in fixes or plan.at(*n) not in plan.praticables:
				continue
			if (carte, n) in portes and not cle:
				continue
			if (carte, n) in pads:  # un pas sur un téléporteur : transport
				dest = pads[(carte, n)]
				yield (dest[0], dest[1], cle)
			elif (carte, n) in liens:  # escalier, ascenseur, sortie de cabine (jalon 26)
				for dest in liens[(carte, n)]:
					yield (dest[0], dest[1], cle)
			else:
				yield (carte, n, cle)
		# ramasser la carte magnétique depuis une case voisine
		if not cle and any((carte, _plus(c, d)) in cles for d in DIRECTIONS):
			yield (carte, c, True)

	def explorer(debut, avec_cle_permise: bool = True):
		vus = {debut}
		file = deque([debut])
		while file:
			e = file.popleft()
			for n in voisins(e):
				if n[2] and not avec_cle_permise:
					continue
				if n not in vus:
					vus.add(n)
					file.append(n)
		return vus

	d = (departs[0][0], departs[0][1], False)
	tout = explorer(d)
	sans_cle = explorer(d, False)
	r.ok(any((e[0], e[1]) in buts for e in tout), "le but est atteignable")
	if portes:
		r.ok(any(e[2] for e in tout), "la carte magnétique est atteignable sans porte")
		r.ok(not any((e[0], e[1]) in buts for e in sans_cle), "le but exige la carte (porte testée)")
	# Retour au départ : une exploration du graphe inverse depuis les états posés sur le départ
	# (équivaut à explorer depuis chaque état, en temps linéaire).
	inverse: dict = {}
	for e in tout:
		for n in voisins(e):
			inverse.setdefault(n, set()).add(e)
	revient = {e for e in tout if (e[0], e[1]) == (d[0], d[1])}
	file = deque(revient)
	while file:
		e = file.popleft()
		for p in inverse.get(e, ()):
			if p not in revient:
				revient.add(p)
				file.append(p)
	retour_impossible = [e for e in tout if e not in revient]
	r.ok(not retour_impossible, f"retour au départ toujours possible ({retour_impossible[:2]})")
	r.note(f"{len(tout)} états (carte, case, carte magnétique) atteignables")
	return r


# --- Surf et courants ---------------------------------------------------------------------------

def verifier_mer(chemin: Path, rapport: Rapport | None = None) -> Rapport:
	plan = lire(chemin)
	r = rapport or Rapport(f"Surf : {chemin.name}")
	fixes = _bloquees(plan)
	terminaux = {c for k in SORTIES for c in _cases(plan, k)}

	def surfable(c: Case) -> bool:
		return _dans(plan, c) and (plan.at(*c) in "w^v<>s") and c not in fixes

	def terre(c: Case) -> bool:
		return _dans(plan, c) and plan.at(*c) in plan.praticables and not surfable(c) \
			and plan.at(*c) != "~" and c not in fixes

	def courant(c: Case) -> Case | None:
		return FLECHES.get(plan.at(*c)) if _dans(plan, c) else None

	traverses: set[Case] = set()

	def glisser(c: Case) -> tuple[str, Case]:
		vus = set()
		while True:
			traverses.add(c)
			if c in terminaux:
				return "PASSAGE", c
			d = courant(c)
			if d is None:
				return "CALME", c
			if c in vus or len(vus) > MAX_COURANT:
				return "BOUCLE", c
			vus.add(c)
			n = _plus(c, d)
			if surfable(n):
				c = n
			elif terre(n):
				return "TERRE", n
			else:
				return "BLOQUE", c

	# chaque case de courant mène à une fin valide
	fins: dict[str, int] = {}
	for y in range(plan.height):
		for x in range(plan.width):
			if courant((x, y)) and surfable((x, y)):
				statut, fin = glisser((x, y))
				fins[statut] = fins.get(statut, 0) + 1
				r.ok(statut in ("PASSAGE", "CALME", "TERRE"), f"courant {(x, y)} : {statut} en {fin}")
	r.note(f"cases de courant par fin : {fins}")
	depart = _cases(plan, "depart")
	if not r.ok(len(depart) == 1, "une seule position « depart »"):
		return r
	# états : (case, en Surf)
	debut = (depart[0], surfable(depart[0]))
	vus = {debut}
	file = deque([debut])
	atteint_terminal = set()
	while file:
		c, surf = file.popleft()
		for d in DIRECTIONS:
			n = _plus(c, d)
			if not surf:
				if terre(n):
					nouvel = (n, False)
				elif surfable(n):  # monter
					nouvel = (n, True)
				else:
					continue
			else:
				if surfable(n):
					nouvel = (n, True)
				elif terre(n):  # descendre
					nouvel = (n, False)
				else:
					continue
			if nouvel[1] and courant(nouvel[0]):
				statut, fin = glisser(nouvel[0])
				if statut == "PASSAGE":
					atteint_terminal.add(fin)
					continue
				nouvel = (fin, statut != "TERRE")
			if nouvel[0] in terminaux:
				atteint_terminal.add(nouvel[0])
			if nouvel not in vus:
				vus.add(nouvel)
				file.append(nouvel)
	cases = {c for c, _ in vus} | traverses
	toutes_eaux = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if surfable((x, y))}
	r.ok(toutes_eaux <= cases, f"toute eau surfable est atteignable ({len(toutes_eaux - cases)} isolée(s))")
	r.ok(not any(plan.at(*c) == "~" for c in cases), "l'eau décor n'est jamais atteinte")
	for p in plan.of_kind("pnj"):
		if p.attrs.get("move_mode") == "surf":
			r.ok(plan.at(*p.cells[0]) in "w^v<>s", f"{p.ident} : Nageur sur l'eau")
	for p in plan.positions.values():
		if p.kind in SORTIES:
			r.ok(any(c in atteint_terminal for c in p.cells) or any(c in cases for c in p.cells),
				f"{p.ident} : sortie atteinte")
	for p in plan.of_kind("spawn"):
		if p.attrs.get("surf") == "oui":
			r.ok(surfable(p.cells[0]), f"{p.ident} : arrivée en Surf sur l'eau")
	r.note(f"{len(cases)} cases atteintes, {len(toutes_eaux)} cases d'eau surfable")
	return r


# --- Monture (Vélo, Piste, pente, Flûte) ----------------------------------------------------------

def verifier_monture(chemin: Path, rapport: Rapport | None = None) -> Rapport:
	"""Une carte de la monture. Contrôles par contenu : pentes (seulement sur la Piste, dérive
	jusqu'à un palier, Dresseur dont la vue les coupe, atteignables), rebord, porte d'intérieur et
	dormeur (extérieur). `cycling_road` étant un booléen par carte (T9 [D]), la Piste est une carte
	à part : une carte sans pente ne les contrôle pas ; les liens entre cartes sont dans
	`verifier_liens_monture`."""
	plan = lire(chemin)
	r = rapport or Rapport(f"Monture : {chemin.name}")
	pistes = {c for p in plan.of_kind("piste") for c in p.cells}
	pentes = plan.cells_of("/")
	fixes = _bloquees(plan)

	def libre(c: Case) -> bool:
		return _dans(plan, c) and plan.at(*c) in plan.praticables and c not in fixes

	entrees = [c for k in ("spawn", "depart") for p in plan.of_kind(k) for c in p.cells]
	if pentes:
		r.ok(all(c in pistes for c in pentes), "pentes seulement sur la Piste")
		# dérive vers le bas : s'arrête sur un palier (case praticable sans pente) ou un obstacle
		paliers = set()
		for c in pentes:
			x = c
			while plan.at(*x) == "/":
				n = _plus(x, (0, 1))
				if not libre(n):
					break
				x = n
			r.ok(plan.at(*x) != "/" or not libre(_plus(x, (0, 1))), f"dérive depuis {c} : fin")
			r.ok(x in pistes, f"dérive depuis {c} : reste sur la Piste")
			paliers.add(x)
		r.note(f"{len(pentes)} cases de pente, {len(paliers)} cases d'arrêt de dérive")
		# Dresseur dont la vue coupe la pente
		vues = 0
		for p in plan.of_kind("dresseur"):
			d = {"left": (-1, 0), "right": (1, 0), "up": (0, -1), "down": (0, 1)}[p.attrs["facing"]]
			portee = int(p.attrs.get("sight", "4"))
			ligne = [_plus(p.cells[0], d, k) for k in range(1, portee + 1)]
			if any(_dans(plan, c) and plan.at(*c) == "/" for c in ligne):
				vues += 1
		r.ok(vues >= 1, "un Dresseur voit une case de pente")
	if not r.ok(bool(entrees), "au moins une entrée (depart ou spawn)"):
		return r

	def atteint(depart: Case) -> set[Case]:
		vus = {depart}
		file = deque([depart])
		while file:
			c = file.popleft()
			for d in DIRECTIONS:
				n = _plus(c, d)
				if not libre(n):
					continue
				if plan.at(*n) == "v":
					if d != (0, 1):
						continue
					n = _plus(n, d)
					if not libre(n):
						continue
				if n not in vus:
					vus.add(n)
					file.append(n)
		return vus

	zone: set[Case] = set()
	for e in entrees:
		zone |= atteint(e)
	if pentes:
		r.ok(bool(set(pentes) & zone), "la pente est atteignable")
	depart = _cases(plan, "depart")
	if depart:
		r.ok(bool(plan.cells_of("v")), "au moins un rebord")
		portes = [p for p in plan.of_kind("warp") if p.attrs.get("interieur") == "oui"]
		r.ok(any(c in zone for p in portes for c in p.cells), "une porte d'intérieur atteignable")
	for p in plan.of_kind("dormeur"):
		autour = {_plus(c, d) for c in p.cells for d in DIRECTIONS} - set(p.cells)
		r.ok(bool(autour & zone), f"{p.ident} : on peut jouer de la Flûte à côté")
		derriere = set(_cases(plan, "derriere_dormeur"))
		r.ok(bool(derriere) and not (derriere & zone), f"{p.ident} : la zone derrière est fermée")
		# réveillé, le dormeur ne bloque plus : la zone derrière s'ouvre
		fixes_sans = fixes - set(p.cells)
		vus = {depart[0]}
		file = deque([depart[0]])
		while file:
			c = file.popleft()
			for d in DIRECTIONS:
				n = _plus(c, d)
				if _dans(plan, n) and plan.at(*n) in plan.praticables and n not in fixes_sans \
						and n not in vus and plan.at(*n) != "v":
					vus.add(n)
					file.append(n)
		r.ok(bool(derriere & vus), f"{p.ident} : réveillé, la zone derrière s'ouvre")
	return r


def verifier_liens_monture(chemins: list[Path], rapport: Rapport | None = None) -> Rapport:
	"""Warps entre les cartes de QA de la monture : chaque `vers=carte:repère` mène à un repère
	(spawn) qui existe, praticable, et chaque warp a son retour."""
	plans = {c.stem: lire(c) for c in chemins}
	r = rapport or Rapport("Monture, liens : " + ", ".join(c.name for c in chemins))
	for carte, plan in plans.items():
		for p in plan.of_kind("warp"):
			vers = p.attrs.get("vers", "")
			if not r.ok(":" in vers, f"{carte}/{p.ident} : vers=<carte>:<spawn>"):
				continue
			cible, repere = vers.split(":", 1)
			if not r.ok(cible in plans, f"{carte}/{p.ident} : carte {cible} absente"):
				continue
			dest = plans[cible]
			spawns = {q.ident: q for q in dest.positions.values() if q.kind in ("spawn", "depart")}
			if not r.ok(repere in spawns, f"{carte}/{p.ident} : repère {repere} absent de {cible}"):
				continue
			c = spawns[repere].cells[0]
			r.ok(dest.at(*c) in dest.praticables, f"{carte}/{p.ident} : arrivée praticable")
			retours = [q for q in dest.of_kind("warp")
				if q.attrs.get("vers", "").startswith(carte + ":")]
			r.ok(bool(retours), f"{carte}/{p.ident} : {cible} a un warp de retour vers {carte}")
			r.note(f"{carte}/{p.ident} -> {vers}")
	return r


# --- Auto-test : le contrôle refuse des pièges connus ---------------------------------------------

_PIEGE_FORCE = """PRATICABLES .BOE
GRILLE 7 5
00 #######
01 #.....#
02 #.B...#
03 #.....#
04 ##E####
FIN
POSITIONS
depart  depart  2,3  libre
sortie  warp    2,4  libre
FIN
"""
# Le rocher (2, 2) poussé vers le sud en (2, 3) se pousse encore jusqu'en (2, 4) : la sortie est
# murée et le joueur, au nord, est enfermé.

_PIEGE_TELEPORT = """PRATICABLES .TE
GRILLE 6 3
00 ######
01 #T..E#
02 ######
FIN
POSITIONS
depart  depart       3,1  libre
pad     teleporteur  1,1  libre  vers=qa_x:nulle_part
FIN
"""

_PIEGE_COURANT = """PRATICABLES .w<>E
GRILLE 6 3
00 ######
01 #.><w#
02 ######
FIN
POSITIONS
depart  depart  1,1  libre
FIN
"""

_PIEGE_ENTREE = """PRATICABLES .BE
GRILLE 7 5
00 #######
01 #.#...#
02 #.#.B.#
03 #.#...#
04 #E##E##
FIN
POSITIONS
depart     depart  1,1  libre
sortie_o   warp    1,4  libre
sortie_e   warp    4,4  libre
arrivee_e  spawn   4,1  libre
FIN
"""
# Depuis « depart », tout va bien ; depuis l'arrivée de l'est, le rocher (4, 2) poussé deux fois
# vers le sud mure la sortie (4, 4) : seul un contrôle de toutes les entrées le voit.

_PIEGE_PENTE = """PRATICABLES ./
GRILLE 5 5
00 #####
01 #./.#
02 #/..#
03 #...#
04 #####
FIN
POSITIONS
depart  depart  1,1  libre
FIN
"""
# Pentes « / » hors de toute position « piste » : refusées.

_PIEGE_LEGENDE = """PRATICABLES .BSE
GRILLE 6 3
00 ######
01 #.BS.#
02 ####E#
FIN
POSITIONS
depart        depart        1,1  libre
rocher_1      rocher        2,1  bloque  ordre=1 trou=9
interrupteur  interrupteur  3,1  libre
FIN
"""
# Légende commune (plan_check.py --legende) : le rocher vise un trou absent, l'interrupteur n'a
# pas de drapeau.


def autotest() -> bool:
	ok = True
	with tempfile.TemporaryDirectory() as dossier:
		for nom, texte, fonction, attendu in [
			("piege_force", _PIEGE_FORCE, verifier_force, "anti-blocage"),
			("piege_entree", _PIEGE_ENTREE, verifier_force, "anti-blocage"),
			("qa_x", _PIEGE_TELEPORT, lambda p: verifier_teleporteurs([p]), "n'existe pas"),
			("piege_courant", _PIEGE_COURANT, verifier_mer, "BOUCLE"),
			("piege_pente", _PIEGE_PENTE, verifier_monture, "seulement sur la Piste"),
		]:
			chemin = Path(dossier) / f"{nom}.txt"
			chemin.write_text(texte, encoding="utf-8")
			r = fonction(chemin)
			refuse = any(attendu in e for e in r.echecs)
			print(f"autotest {nom} : {'refusé comme attendu' if refuse else 'NON REFUSÉ'}")
			ok = ok and refuse
		chemin = Path(dossier) / "piege_legende.txt"
		chemin.write_text(_PIEGE_LEGENDE, encoding="utf-8")
		erreurs = verifier_legende(chemin)
		refuse = any("trou 9" in e for e in erreurs) and any("drapeau" in e for e in erreurs)
		print(f"autotest piege_legende : {'refusé comme attendu' if refuse else 'NON REFUSÉ'}")
		ok = ok and refuse
	return ok


def main() -> int:
	if "--autotest" in sys.argv:
		return 0 if autotest() else 1
	rapports = [
		verifier_monture(PLANS / "qa_mount.txt"),
		verifier_monture(PLANS / "qa_mount_piste.txt"),
		verifier_monture(PLANS / "qa_mount_interieur.txt"),
		verifier_liens_monture([PLANS / "qa_mount.txt", PLANS / "qa_mount_piste.txt",
			PLANS / "qa_mount_interieur.txt"]),
		verifier_mer(PLANS / "qa_sea.txt"),
		verifier_mer(PLANS / "qa_sea_2.txt"),
		verifier_force(PLANS / "qa_strength.txt"),
		verifier_etage_inferieur(PLANS / "qa_strength_b1.txt", PLANS / "qa_strength.txt"),
		verifier_teleporteurs([PLANS / "qa_teleport.txt", PLANS / "qa_teleport_2.txt"]),
	]
	ok = all([r.imprimer() for r in rapports])
	legende = [e for f in sorted(PLANS.glob("qa_*.txt")) for e in verifier_legende(f)]
	for e in legende:
		print(f"  [ÉCHEC] légende commune : {e}")
	ok = ok and not legende
	print("TOUT EST CONFORME" if ok else "NON CONFORME")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
