#!/usr/bin/env python3
"""Contrôle des grilles du jalon 26 (`docs/tech/jalon-26.md` §2.1, T2) : Safrania, ses intérieurs,
les onze étages de la Sylphe SARL et la cabine de l'ascenseur.

**Sylphe SARL** (`sylphe_1f.txt` … `sylphe_11f.txt`, `sylphe_ascenseur.txt`, puzzles à 1:1 de RB) :
  - profils (identifiant de carte `CARTE`, taille RB), légende commune (`plan_check.py --legende`)
    et contrôle générique des téléporteurs (`plan_check_teleports.py` : spawns, paires, « T »,
    graphe des salles imprimé, salle isolée refusée) sur les 12 grilles ;
  - escaliers appariés (aller et retour, même paire, arrivée une case devant), ascenseur sans clé
    qui dessert les 11 étages, portes électroniques de deux cases (même id, sur « K »), aucun
    téléporteur qui renvoie sur un autre téléporteur que son partenaire (pas de boucle) ;
  - exploration des états (carte, case, Carte Magnétique en poche) : chaque étage atteignable
    depuis le 1F ; la Carte du 5F atteignable SANS la Carte ; le 11F de Giovanni atteignable AVEC
    la Carte et PAS SANS ; le rival du 7F sur le chemin obligatoire (Giovanni inatteignable quand
    la salle du rival est fermée à ses cases de déclenchement) ; retour au 1F toujours possible
    depuis tout état atteignable, avec et sans la Carte ;
  - Dresseurs `silph_co_<n>f_<k>` (k = 1, 2, 3… sans trou), objets du projet ou repli existant,
    rival, Giovanni, président, hôtesse, employé du Lokhlass, Carte `silph_co_5f_card_key`.
**Safrania** (`safrania.txt`) : profil, portes et leurs arrivées (une case devant, dans le sens de la
  porte), raccords des quatre postes (poste de la Route 5 et postes J20 des Routes 7 et 8 :
  `north_door` de `build_painted_interiors.gd` ; Route 6 : `porte_safrania` de `route_6.txt`), arrivée
  du Vol (`fly_points.json`), atteignabilité en deux états (occupation : seules les portes du
  Copieur, du Roucool et de l'Arène sont fermées, par leur sbire ; libérée : toutes ouvertes), aucun
  PNJ sur un passage obligé, panneaux lisibles.
**Intérieurs** (`safrania_*.txt`) : profils, sortie vers une arrivée de Safrania, escalier du Copieur.

Usage : python3 -I tools/art/plan_check_j26.py [grille.txt ...]   (sans argument : tout le J26,
        graphe des salles imprimé, « TOUT EST CONFORME » à la fin). Code 1 si un critère échoue.
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict, deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import verifier_legende  # noqa: E402
from plan_check_systemes2 import KINDS_CARTE, Rapport, passages  # noqa: E402
from plan_check_teleports import verifier_teleports  # noqa: E402
from plan_grille import Plan, lire  # noqa: E402
from plan_grille import carte as carte_de  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRECTIONS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
VOISINS = list(DIRECTIONS.values())
ETAGES = [f"sylphe_{n}f" for n in range(1, 12)]
CABINE = "sylphe_ascenseur"
TAILLES_ETAGES = {1: (30, 18), 2: (30, 18), 3: (30, 18), 4: (30, 18), 5: (30, 18), 6: (26, 18),
	7: (26, 18), 8: (26, 18), 9: (26, 18), 10: (16, 18), 11: (18, 18)}
PROFILS: dict[str, tuple[str, int, int]] = {
	**{f"sylphe_{n}f": (f"silph_co_{n}f", w, h) for n, (w, h) in TAILLES_ETAGES.items()},
	CABINE: ("silph_co_elevator", 4, 4),
	"safrania": ("saffron_city", 60, 50),
	"safrania_centre": ("saffron_center", 15, 10),
	"safrania_boutique": ("saffron_mart", 15, 10),
	"safrania_maison_psy": ("saffron_psychic_house", 15, 10),
	"safrania_maison_roucool": ("saffron_pidgey_house", 15, 10),
	"safrania_maison_copieur_1f": ("saffron_copycat_house_1f", 15, 10),
	"safrania_maison_copieur_2f": ("saffron_copycat_house_2f", 15, 10),
}
INTERIEURS = [s for s in PROFILS if s.startswith("safrania_")]
# Postes de Safrania : porte de la ville → (carte, point d'apparition visé, arrivée dans la ville).
POSTES = {"porte_poste_r5": ("route_5_gate", "north_door", "from_gate_r5"),
	"porte_poste_r6": ("route_6", "from_saffron", "from_gate_r6"),
	"porte_poste_r7": ("route_7_gate", "north_door", "from_gate_r7"),
	"porte_poste_r8": ("route_8_gate", "north_door", "from_gate_r8")}
FERMEES_OCCUPATION = {"porte_copieur", "porte_roucool", "porte_arene"}
LIBERATION = "silph_giovanni_defeated"


def _plus(c: Case, d: Case) -> Case:
	return (c[0] + d[0], c[1] + d[1])


def _dans(plan: Plan, c: Case) -> bool:
	return 0 <= c[0] < plan.width and 0 <= c[1] < plan.height


def _cases(texte: str) -> Case:
	x, y = texte.split(",")
	return (int(x), int(y))


def _objets_du_projet() -> set[str]:
	ids: set[str] = set()
	for f in sorted((RACINE / "data/items").glob("*.json")):
		d = json.loads(f.read_text(encoding="utf-8"))
		items = d.get("items", d)
		ids |= set(items) if isinstance(items, dict) else {x.get("id") for x in items}
	return ids


def _charger(stems: list[str]) -> dict[str, Plan]:
	return {s: lire(PLANS / f"{s}.txt") for s in stems}


def verifier_profil(r: Rapport, stem: str) -> Plan | None:
	chemin = PLANS / f"{stem}.txt"
	if not r.ok(chemin.exists(), f"{chemin.name} absent"):
		return None
	plan = lire(chemin)
	carte, w, h = PROFILS[stem]
	r.ok(carte_de(chemin) == carte, f"{stem} : CARTE {carte_de(chemin)} au lieu de {carte}")
	r.ok((plan.width, plan.height) == (w, h), f"{stem} : {plan.width} × {plan.height} au lieu de {w} × {h}")
	for e in verifier_legende(chemin):
		r.ok(False, f"légende commune : {e}")
	return plan


# --- Sylphe SARL -----------------------------------------------------------------------------

class Sylphe:
	"""Les 11 étages et la cabine, indexés par identifiant de carte."""

	def __init__(self) -> None:
		self.stems = ETAGES + [CABINE]
		self.plans = {PROFILS[s][0]: lire(PLANS / f"{s}.txt") for s in self.stems}
		self.spawns = {(c, p.ident): p.cells[0] for c, plan in self.plans.items()
			for p in plan.positions.values() if p.kind in ("spawn", "depart")}
		self.pads: dict[tuple[str, Case], tuple[str, Case]] = {}
		for c, plan in self.plans.items():
			for p in plan.of_kind("teleporteur"):
				cible = tuple(p.attrs.get("vers", "").split(":", 1))
				if cible in self.spawns:
					self.pads[(c, p.cells[0])] = (cible[0], self.spawns[cible])
		self.liens = passages(self.plans, self.spawns)
		self.portes = {(c, q) for c, plan in self.plans.items()
			for p in plan.of_kind("porte_carte") for q in p.cells}
		self.cles = {(c, q) for c, plan in self.plans.items() for k in KINDS_CARTE
			for p in plan.of_kind(k) if p.attrs.get("item") == "card_key" for q in p.cells}
		self.fixes = {c: {q for p in plan.positions.values() if p.bloque
			and p.kind not in ("porte_carte",) + KINDS_CARTE for q in p.cells}
			for c, plan in self.plans.items()}
		d = self.spawns.get(("silph_co_1f", "depart"))
		self.depart = ("silph_co_1f", d)

	def voisins(self, etat, fermees: frozenset = frozenset()):
		carte, c, cle = etat
		plan = self.plans[carte]
		for d in VOISINS:
			n = _plus(c, d)
			if not _dans(plan, n) or plan.at(*n) not in plan.praticables or n in self.fixes[carte] \
					or (carte, n) in fermees:
				continue
			if (carte, n) in self.portes and not cle:
				continue
			if (carte, n) in self.pads:
				yield (*self.pads[(carte, n)], cle)
			elif (carte, n) in self.liens:
				for dest in self.liens[(carte, n)]:
					yield (*dest, cle)
			else:
				yield (carte, n, cle)
		if not cle and any((carte, _plus(c, d)) in self.cles for d in VOISINS):
			yield (carte, c, True)

	def explorer(self, debut, ramasser: bool = True, fermees: frozenset = frozenset()) -> set:
		vus = {debut}
		file = deque([debut])
		while file:
			e = file.popleft()
			for n in self.voisins(e, fermees):
				if n[2] and not ramasser and not e[2]:
					continue
				if n not in vus:
					vus.add(n)
					file.append(n)
		return vus

	def cases(self, carte: str, kind: str, prefixe: str = "") -> set[tuple[str, Case]]:
		return {(carte, q) for p in self.plans[carte].of_kind(kind) if p.ident.startswith(prefixe)
			for q in p.cells}


def _num(carte: str) -> int:
	return int(carte.split("_")[2].rstrip("f"))


def verifier_sylphe(r: Rapport) -> None:
	s = Sylphe()
	objets = _objets_du_projet()
	r.ok(s.depart[1] is not None, "silph_co_1f : position « depart » absente")
	# Escaliers appariés, arrivée une case devant.
	for carte, plan in s.plans.items():
		for p in plan.of_kind("escalier"):
			cible = p.attrs.get("vers", "").split(":", 1)
			if not r.ok(len(cible) == 2 and tuple(cible) in s.spawns,
					f"{carte}/{p.ident} : vers={p.attrs.get('vers')} n'existe pas"):
				continue
			autre, spawn = cible
			retour = [q for q in s.plans[autre].of_kind("escalier") if q.attrs.get("paire") == p.attrs.get("paire")]
			r.ok(len(retour) == 1 and retour[0].attrs.get("vers", "").split(":")[0] == carte,
				f"{carte}/{p.ident} : pas d'escalier retour de paire {p.attrs.get('paire')} dans {autre}")
			arrivee = s.plans[autre].positions[spawn]
			r.ok(arrivee.attrs.get("paire") == p.attrs.get("paire"),
				f"{autre}/{spawn} : paire ≠ {p.attrs.get('paire')}")
			if retour:
				r.ok(arrivee.cells[0] == _plus(retour[0].cells[0], (0, 1)),
					f"{autre}/{spawn} : pas une case devant l'escalier {retour[0].ident}")
			sens = "monte" if _num(autre) > _num(carte) else "descend"
			r.ok(p.attrs.get("sens") == sens, f"{carte}/{p.ident} : sens={p.attrs.get('sens')} au lieu de {sens}")
			r.ok(plan.at(*p.cells[0]) == ("U" if sens == "monte" else "D"),
				f"{carte}/{p.ident} : case « {plan.at(*p.cells[0])} » au lieu de U / D")
	# Ascenseur : chaque étage, une porte vers la cabine et une arrivée devant ; cabine sans clé.
	cabine = s.plans["silph_co_elevator"]
	sorties = [d for p in cabine.of_kind("sortie") for d in p.attrs.get("etages", "").split(";")]
	panneau = cabine.of_kind("panneau")
	r.ok(len(panneau) == 1 and "cle" not in panneau[0].attrs
		and panneau[0].attrs.get("etages", "").split(",") == [f"{n}F" for n in range(1, 12)],
		"cabine : un panneau sans clé, étages 1F à 11F")
	for n in range(1, 12):
		carte = f"silph_co_{n}f"
		plan = s.plans[carte]
		asc = plan.of_kind("ascenseur")
		ok = r.ok(len(asc) == 1 and asc[0].attrs.get("vers") == "silph_co_elevator:entrance"
			and plan.at(*asc[0].cells[0]) == "L", f"{carte} : une porte d'ascenseur « L » vers la cabine")
		r.ok(f"{carte}:from_elevator" in sorties, f"cabine : l'étage {n}F n'est pas desservi")
		if ok and (carte, "from_elevator") in s.spawns:
			r.ok(s.spawns[(carte, "from_elevator")] == _plus(asc[0].cells[0], (0, 1)),
				f"{carte} : from_elevator pas une case devant la porte")
	# Portes électroniques : deux cases voisines, même id, sur « K » ; chaque « K » a sa porte.
	for carte, plan in s.plans.items():
		ids: dict[str, list[Case]] = defaultdict(list)
		for p in plan.of_kind("porte_carte"):
			ids[p.attrs.get("id", "?")].append(p.cells[0])
			r.ok(p.attrs.get("cle") == "card_key" and p.bloque, f"{carte}/{p.ident} : cle=card_key, bloque")
		for i, cs in ids.items():
			r.ok(len(cs) == 2 and abs(cs[0][0] - cs[1][0]) + abs(cs[0][1] - cs[1][1]) == 1,
				f"{carte} : porte {i} sur {cs} (attendu deux cases voisines)")
		r.ok(set(plan.cells_of("K")) == {c for cs in ids.values() for c in cs},
			f"{carte} : cases « K » et positions porte_carte différentes")
	# Téléporteurs : jamais vers un autre téléporteur que le partenaire de paire (aucune boucle).
	paire_de = {(c, p.cells[0]): p.attrs.get("paire") for c, plan in s.plans.items()
		for p in plan.of_kind("teleporteur")}
	for (c, q), (cc, dest) in sorted(s.pads.items()):
		r.ok((cc, dest) != (c, q), f"{c} {q} : téléporteur vers sa propre case")
		if (cc, dest) in s.pads:
			r.ok(paire_de[(cc, dest)] == paire_de[(c, q)],
				f"{c} {q} : arrive sur le téléporteur {cc} {dest}, qui n'est pas son partenaire")
	# Points d'apparition praticables, hors des positions bloquantes.
	for (c, ident), q in sorted(s.spawns.items()):
		plan = s.plans[c]
		r.ok(plan.at(*q) in plan.praticables and q not in s.fixes[c], f"{c}/{ident} : case {q} non praticable")
	# Dresseurs, objets, personnages.
	for n in range(1, 12):
		carte = f"silph_co_{n}f"
		plan = s.plans[carte]
		dresseurs = plan.of_kind("dresseur")
		ks = [int(p.attrs.get("trainer", "x_0").rsplit("_", 1)[1]) for p in dresseurs]
		r.ok(ks == list(range(1, len(ks) + 1)), f"{carte} : Dresseurs numérotés {ks}")
		for p in dresseurs:
			r.ok(re.fullmatch(rf"silph_co_{n}f_\d+", p.attrs.get("trainer", "")) is not None
				and p.attrs.get("facing") in DIRECTIONS and p.attrs.get("sight", "").isdigit()
				and re.search(r"OPP_(ROCKET|SCIENTIST|JUGGLER), \d+", p.note) is not None,
				f"{carte}/{p.ident} : trainer=, facing=, sight= et équipe RB")
		for p in plan.of_kind("objet_visible") + plan.of_kind("objet_cache"):
			item, repli = p.attrs.get("item", ""), p.attrs.get("fallback", "")
			r.ok(item in objets or repli in objets, f"{carte}/{p.ident} : {item} sans repli existant")
	trouve = lambda carte, kind, **a: [p for p in s.plans[carte].of_kind(kind)  # noqa: E731
		if all(p.attrs.get(k) == v for k, v in a.items())]
	r.ok(len(trouve("silph_co_5f", "objet_visible", item="card_key")) == 1
		and "silph_co_5f_card_key" in s.plans["silph_co_5f"].positions, "5F : Carte silph_co_5f_card_key")
	r.ok(len(trouve("silph_co_7f", "rival", trainer="rival_silph")) == 1, "7F : rival rival_silph")
	r.ok(len(trouve("silph_co_7f", "pnj", role="silph_co_7f_lapras_giver")) == 1, "7F : employé du Lokhlass")
	r.ok(len(trouve("silph_co_11f", "giovanni", trainer="silph_co_giovanni")) == 1, "11F : Giovanni")
	r.ok(len(trouve("silph_co_11f", "pnj", role="silph_co_president")) == 1, "11F : président")
	r.ok(len(trouve("silph_co_1f", "pnj", role="silph_co_1f_receptionist")) == 1, "1F : hôtesse")

	# Exploration.
	if s.depart[1] is None:
		return
	d = (*s.depart, False)
	sans = s.explorer(d, ramasser=False)
	tout = s.explorer(d)
	giovanni = s.cases("silph_co_11f", "declencheur", "declencheur_giovanni")
	rival = s.cases("silph_co_7f", "declencheur", "declencheur_rival") | s.cases("silph_co_7f", "rival")
	for n in range(1, 12):
		r.ok(any(e[0] == f"silph_co_{n}f" for e in sans), f"{n}F inatteignable depuis le 1F (sans la Carte)")
	r.ok(any(e[0] == "silph_co_elevator" for e in sans), "cabine inatteignable")
	r.ok(any(e[2] for e in tout), "la Carte Magnétique du 5F est inatteignable sans la Carte")
	r.ok(any((e[0], e[1]) in giovanni for e in tout), "Giovanni (11F) inatteignable avec la Carte")
	r.ok(not any((e[0], e[1]) in giovanni for e in sans), "Giovanni (11F) atteignable SANS la Carte")
	r.ok(any((e[0], _plus(e[1], v)) in rival or (e[0], e[1]) in rival for e in tout for v in VOISINS),
		"le rival du 7F est inatteignable")
	contourne = s.explorer(d, fermees=frozenset(rival))
	r.ok(not any((e[0], e[1]) in giovanni for e in contourne),
		"le rival du 7F n'est PAS sur le chemin obligatoire de Giovanni")
	# Retour au 1F : graphe inverse des états, depuis toutes les cases de départ.
	inverse: dict = defaultdict(set)
	for e in tout:
		for n in s.voisins(e):
			inverse[n].add(e)
	retour = {e for e in tout if (e[0], e[1]) == s.depart}
	file = deque(retour)
	while file:
		e = file.popleft()
		for p in inverse[e]:
			if p not in retour:
				retour.add(p)
				file.append(p)
	coinces = sorted(tout - retour)
	r.ok(not coinces, f"retour au 1F impossible depuis {len(coinces)} état(s), par ex. {coinces[:3]}")
	etages_atteints = {e[0] for e in tout}
	r.note(f"Sylphe : {len(sans)} états sans la Carte, {len(tout)} avec ; {len(etages_atteints)} cartes "
		f"atteintes ; Giovanni : avec la Carte oui, sans non ; salle du rival fermée → Giovanni "
		f"inatteignable ; retour au 1F depuis les {len(tout)} états (avec et sans la Carte).")
	_imprimer_liaisons(r, s)


def _imprimer_liaisons(r: Rapport, s: Sylphe) -> None:
	"""Tableau des liaisons (pour la revue) : escaliers, ascenseur, téléporteurs, portes."""
	r.note("Liaisons de la Sylphe (case → carte:point d'apparition) :")
	for n in range(1, 12):
		carte = f"silph_co_{n}f"
		plan = s.plans[carte]
		lignes = []
		for p in plan.positions.values():
			if p.kind in ("escalier", "ascenseur", "teleporteur", "warp"):
				lignes.append(f"{p.kind} {p.cells[0]} → {p.attrs.get('vers')}")
		portes = sorted({p.attrs['id'] for p in plan.of_kind('porte_carte')})
		r.note(f"  {n}F : " + " ; ".join(lignes) + (f" ; portes {', '.join(portes)}" if portes else ""))


# --- Safrania --------------------------------------------------------------------------------

def _monde_ville(plan: Plan, etat: str) -> tuple[set[Case], set[Case]]:
	"""(cases bloquées, cases de porte) de Safrania pour « occupation » ou « liberee »."""
	bloquees: set[Case] = set()
	for p in plan.positions.values():
		if not p.bloque:
			continue
		if p.attrs.get("unless") == LIBERATION and etat != "occupation":
			continue
		if p.attrs.get("if") == LIBERATION and etat != "liberee":
			continue
		bloquees.update(p.cells)
	portes = {c for p in plan.of_kind("warp") for c in p.cells}
	return bloquees, portes


def _atteint_ville(plan: Plan, depart: Case, bloquees: set[Case], portes: set[Case]) -> set[Case]:
	vus = {depart}
	file = deque([depart])
	while file:
		c = file.popleft()
		for d in VOISINS:
			n = _plus(c, d)
			if _dans(plan, n) and n not in vus and plan.at(*n) in plan.praticables \
					and n not in bloquees and n not in portes:
				vus.add(n)
				file.append(n)
	return vus


def verifier_safrania(r: Rapport) -> None:
	plan = lire(PLANS / "safrania.txt")
	pos = plan.positions
	# Portes : case « D », arrivée « from_* » juste devant, dans le sens opposé au pas.
	portes = plan.of_kind("warp")
	for p in portes:
		d = DIRECTIONS.get(p.attrs.get("dir", ""))
		if not r.ok(d is not None and p.attrs.get("to") and p.attrs.get("spawn"),
				f"safrania/{p.ident} : dir=, to=, spawn="):
			continue
		r.ok(all(plan.at(*c) == "D" for c in p.cells), f"safrania/{p.ident} : pas sur « D »")
		devant = sorted(_plus(c, (-d[0], -d[1])) for c in p.cells)
		arrivees = [q for q in plan.of_kind("spawn") if sorted(q.cells) == devant]
		r.ok(len(arrivees) >= 1, f"safrania/{p.ident} : aucune arrivée en {devant}")
		for q in arrivees:
			r.ok(DIRECTIONS.get(q.attrs.get("facing", "")) == (-d[0], -d[1]),
				f"safrania/{q.ident} : facing={q.attrs.get('facing')} (attendu dos à la porte)")
	# Raccords des quatre postes.
	gd = (RACINE / "tools/build_painted_interiors.gd").read_text(encoding="utf-8")
	for ident, (carte, spawn, arrivee) in POSTES.items():
		p = pos.get(ident)
		if not r.ok(p is not None, f"safrania : porte {ident} absente"):
			continue
		r.ok((p.attrs.get("to"), p.attrs.get("spawn")) == (carte, spawn),
			f"safrania/{ident} : vers {p.attrs.get('to')}:{p.attrs.get('spawn')} au lieu de {carte}:{spawn}")
		r.ok(arrivee in pos and pos[arrivee].kind == "spawn", f"safrania : arrivée {arrivee} absente")
	r.ok(re.search(r'func _route_5_gate\(\).*?"north_door"', gd, re.S) is not None,
		"build_painted_interiors.gd : route_5_gate sans point d'apparition north_door")
	r.ok(re.search(r'func _saffron_gate\(.*?"north_door".*?&"saffron_city", StringName\("from_gate_r%d"',
		gd, re.S) is not None, "build_painted_interiors.gd : _saffron_gate ne vise pas saffron_city:from_gate_r<n>")
	r6 = lire(PLANS / "route_6.txt")
	porte6 = r6.positions.get("porte_safrania")
	if r.ok(porte6 is not None and porte6.cells == [(36, 7)], "route_6 : porte_safrania (36, 7)"):
		r.ok(r6.at(36, 8) in r6.praticables, "route_6 : (36, 8), arrivée from_saffron, non praticable")
		npc = json.loads((RACINE / "data/npcs/route_6.json").read_text(encoding="utf-8"))
		garde = next((v for v in (npc.get("npcs", npc)).values() if isinstance(v, dict)
			and v.get("dialogue") == "route_6_guard"), None)
		r.ok(garde is not None and garde.get("moved", {}).get("cell") != [36, 8],
			"route_6 : le garde ne libère pas (36, 8) quand les postes s'ouvrent")
	# Vol.
	fly = json.loads((RACINE / "data/world/fly_points.json").read_text(encoding="utf-8"))
	vols = [v for v in _iter_dicts(fly) if v.get("zone") == "saffron_city"]
	r.ok(len(vols) == 1 and vols[0].get("spawn") in pos and vols[0].get("map") == "saffron_city",
		"fly_points.json : saffron_city / from_center absent de la grille")
	r.ok(any(p.attrs.get("ville") == "saffron_city" and p.cells[0] in pos["from_center"].cells
		for p in plan.of_kind("vol_arrivee")), "safrania : vol_arrivee sur from_center")
	# Panneaux lisibles.
	for p in plan.of_kind("panneau"):
		de = _cases(p.attrs.get("depuis", "-1,-1"))
		r.ok(plan.at(*p.cells[0]) == "n" and de in [_plus(p.cells[0], v) for v in VOISINS]
			and plan.at(*de) in plan.praticables, f"safrania/{p.ident} : panneau illisible depuis {de}")
	# Atteignabilité, deux états.
	for etat in ("occupation", "liberee"):
		bloquees, cases_portes = _monde_ville(plan, etat)
		depart = pos["from_gate_r8"].cells[0]
		atteint = _atteint_ville(plan, depart, bloquees, cases_portes)
		for _, (_, _, arrivee) in POSTES.items():
			r.ok(pos[arrivee].cells[0] in atteint, f"{etat} : {arrivee} inatteignable depuis le poste est")
		fermees = set()
		for p in portes:
			d = DIRECTIONS[p.attrs["dir"]]
			if not any(_plus(c, (-d[0], -d[1])) in atteint for c in p.cells):
				fermees.add(p.ident)
		attendu = FERMEES_OCCUPATION if etat == "occupation" else set()
		r.ok(fermees == attendu, f"{etat} : portes fermées {sorted(fermees)} au lieu de {sorted(attendu)}")
		# Aucun PNJ sur un passage obligé : sans PNJ, on n'atteint pas plus que les cases des PNJ
		# et les cases devant les portes qu'ils ferment.
		libre = _atteint_ville(plan, depart, {c for p in plan.positions.values() if p.bloque
			and p.kind != "pnj" for c in p.cells}, cases_portes)
		pnj = {c for p in plan.of_kind("pnj") for c in p.cells}
		perdues = libre - atteint - pnj
		r.ok(not perdues, f"{etat} : des PNJ coupent la ville ({sorted(perdues)[:4]})")
		r.note(f"Safrania, {etat} : {len(atteint)} cases atteintes depuis le poste est ; portes fermées : "
			f"{', '.join(sorted(fermees)) or 'aucune'}")
	r.ok(pos["garde_arene"].cells[0] == _plus(pos["porte_arene"].cells[0], (0, 1))
		and len(pos["porte_arene"].cells) == 1, "le sbire de l'Arène n'est pas devant sa porte")
	r.ok(pos["porte_dojo"].attrs.get("a_venir") == "oui" and pos["porte_arene"].attrs.get("a_venir") == "oui",
		"portes du Dojo et de l'Arène « À venir » (J27)")


def _iter_dicts(o):
	if isinstance(o, dict):
		yield o
		for v in o.values():
			yield from _iter_dicts(v)
	elif isinstance(o, list):
		for v in o:
			yield from _iter_dicts(v)


def verifier_raccords_interieurs(r: Rapport) -> None:
	ville = lire(PLANS / "safrania.txt")
	cibles = {(p.attrs.get("to"), p.attrs.get("spawn")) for p in ville.of_kind("warp")}
	cartes = {PROFILS[s][0]: lire(PLANS / f"{s}.txt") for s in INTERIEURS}
	cartes["silph_co_1f"] = lire(PLANS / "sylphe_1f.txt")
	for carte, spawn in sorted(c for c in cibles if c[0] in cartes):
		r.ok(spawn in cartes[carte].positions, f"safrania → {carte}:{spawn} : point d'apparition absent")
	for stem in INTERIEURS:
		plan = lire(PLANS / f"{stem}.txt")
		carte = PROFILS[stem][0]
		for p in plan.of_kind("warp"):
			r.ok(p.attrs.get("to") == "saffron_city" and p.attrs.get("spawn") in ville.positions,
				f"{stem}/{p.ident} : sortie vers saffron_city:{p.attrs.get('spawn')} absente")
			r.ok(any(w.attrs.get("to") == carte for w in ville.of_kind("warp")) or stem.endswith("_2f"),
				f"{stem} : aucune porte de Safrania vers {carte}")
		for p in plan.of_kind("escalier"):
			cible = p.attrs.get("vers", ":").split(":", 1)
			autre = next((lire(PLANS / f"{s}.txt") for s in INTERIEURS if PROFILS[s][0] == cible[0]), None)
			r.ok(autre is not None and cible[1] in autre.positions, f"{stem}/{p.ident} : {p.attrs.get('vers')} absent")
		for q in plan.of_kind("spawn"):
			r.ok(all(plan.at(*c) in plan.praticables for c in q.cells), f"{stem}/{q.ident} : case non praticable")
	sortie = cartes["silph_co_1f"].positions.get("sortie_ville")
	r.ok(sortie is not None and sortie.attrs.get("vers") == "saffron_city:from_silph", "sylphe_1f : sortie vers from_silph")


# --- Entrées -----------------------------------------------------------------------------------

def verifier_tout() -> bool:
	rapports = []
	r = Rapport("Profils et légende commune des grilles du J26")
	for stem in PROFILS:
		verifier_profil(r, stem)
	rapports.append(r)
	rapports.append(verifier_teleports([PLANS / f"{s}.txt" for s in ETAGES + [CABINE]]))
	r = Rapport("Sylphe SARL : escaliers, ascenseur, portes, Carte, rival, Giovanni, retour")
	verifier_sylphe(r)
	rapports.append(r)
	r = Rapport("Safrania : portes, postes, Vol, occupation et libération")
	verifier_safrania(r)
	rapports.append(r)
	r = Rapport("Intérieurs de Safrania et sortie de la Sylphe")
	verifier_raccords_interieurs(r)
	rapports.append(r)
	return all([x.imprimer() for x in rapports])


def _un(stem: str):
	def verifier(chemin: Path) -> bool:
		r = Rapport(f"J26 : {chemin.name}")
		verifier_profil(r, chemin.stem)
		if stem == CABINE:  # comme le repaire : la cabine lance les contrôles de toute la Sylphe
			verifier_sylphe(r)
		elif stem == "safrania":
			verifier_safrania(r)
			verifier_raccords_interieurs(r)
		return r.imprimer()
	return verifier


VERIFICATEURS = {s: _un(s) for s in PROFILS}


def main() -> int:
	args = [Path(a) for a in sys.argv[1:] if not a.startswith("--")]
	if args:
		ok = all([VERIFICATEURS[a.stem](a.resolve()) for a in args if a.stem in VERIFICATEURS])
		ok = ok and all(a.stem in VERIFICATEURS for a in args)
	else:
		ok = verifier_tout()
	print("TOUT EST CONFORME" if ok else "NON CONFORME")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
