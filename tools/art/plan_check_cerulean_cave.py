#!/usr/bin/env python3
"""Vérifie les grilles de la Grotte Inconnue (jalon 31, T3 ; plan `docs/tech/jalon-31.md` §2.2, §5).

Grilles : `tools/plans/cerulean_cave_1f.txt`, `_2f.txt`, `_b1f.txt` (relevé 1:1 de Rouge/Bleu,
`cerulean_cave_rb_decode.py`). Lecture par `plan_grille.lire`, sur un **graphe unique** d'états
(étage, case, à pied ou en Surf) qui relie les trois étages par leurs échelles.

Règles de déplacement (celles de `GridWorld.can_enter_as`, passe systèmes 2 et J24) :
  - à pied : sol bas `.`, sol haut `:`, escalier `=`, échelles `U` `V`, bouche `E` ; jamais l'eau ;
  - **niveaux de sol** (collisions par paires de RB, `GridWorld.Level`) : sol bas (avec l'eau et la
    bouche) et sol haut ne se touchent pas ; l'escalier et les échelles vont avec tout ;
  - Surf (si permis) : monter sur l'eau `w` depuis une case compatible (donc jamais depuis le sol
    haut), nager, descendre sur une case praticable compatible ;
  - entrer dans une échelle fait arriver sur le `spawn` de même paire de l'autre étage, à pied ;
    la bouche `E` est la sortie vers Azuria (on y entre, on n'en repart pas) ;
  - les positions `bloque` (objets visibles, Mewtwo) occupent leur case.

Critères :
  1. trois grilles 30 × 18, caractères de la légende seulement ; aucun Dresseur (§8.1, [D]) ;
  2. échelles appariées : chaque paire a une échelle sur chacun de ses deux étages, de sens
     opposés, qui se désignent l'une l'autre, et une arrivée praticable voisine de chaque échelle ;
  3. avec le Surf : depuis l'entrée, toute l'eau et tout le sol sont atteints (aucune case
     orpheline), chaque échelle est utilisée, chaque objet visible et Mewtwo se touchent depuis une
     case de sol voisine, chaque objet caché se prend depuis sa case (voisine de son indice x) ;
  4. retour à la bouche possible depuis **tout** état atteignable (aucun piège) ;
  5. sans le Surf : Mewtwo n'est pas atteignable (le Surf est requis, §2.2) ; ce qui l'est est
     imprimé (objets, étages) ;
  6. chemin le plus court entrée → Mewtwo imprimé (pas, échelles, cases d'eau).

Usage : python3 -I tools/art/plan_check_cerulean_cave.py              (code 1 si un critère échoue)
        python3 -I tools/art/plan_check_cerulean_cave.py --autotest   (le contrôle refuse des pièges)
"""
from __future__ import annotations

import sys
import tempfile
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
CARTES = {"1F": "cerulean_cave_1f", "2F": "cerulean_cave_2f", "B1F": "cerulean_cave_b1f"}
LARGEUR, HAUTEUR = 30, 18
LEGENDE = set("#.:=wUVEx")
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
A_PIED = set(".:=UVE")
BAS, HAUT, TOUT = "bas", "haut", "tout"
NIVEAU = {".": BAS, "E": BAS, "w": BAS, ":": HAUT}
SORTIE = ("SORTIE", -1, -1, False)

Case = tuple[int, int]
Etat = tuple[str, int, int, bool]    # (étage, x, y, en Surf)


def _niveau(c: str) -> str:
	return NIVEAU.get(c, TOUT)


def compatibles(a: str, b: str) -> bool:
	na, nb = _niveau(a), _niveau(b)
	return na == nb or TOUT in (na, nb)


class Grotte:
	def __init__(self, plans: dict[str, Plan]) -> None:
		self.plans = plans
		self.nom_vers_etage = {CARTES[e]: e for e in plans}
		self.bloquees = {e: {c for p in plan.positions.values() if p.bloque for c in p.cells}
			for e, plan in plans.items()}
		self.echelles: dict[tuple[str, Case], tuple[str, Case]] = {}
		self.erreurs: list[str] = []
		self._apparier()

	def _apparier(self) -> None:
		for e, plan in self.plans.items():
			for p in plan.of_kind("echelle"):
				paire, vers = p.attrs.get("paire", ""), p.attrs.get("vers", "")
				autre = self.nom_vers_etage.get(vers)
				if autre is None:
					self.erreurs.append(f"{e} {p.ident} : vers={vers} inconnu")
					continue
				arrivees = [q for q in self.plans[autre].of_kind("spawn")
					if q.attrs.get("paire") == paire]
				if len(arrivees) != 1:
					self.erreurs.append(f"{e} {p.ident} : {len(arrivees)} arrivée(s) {paire} en {autre}")
					continue
				self.echelles[(e, p.cells[0])] = (autre, arrivees[0].cells[0])

	def car(self, e: str, c: Case) -> str:
		plan = self.plans[e]
		if not (0 <= c[0] < plan.width and 0 <= c[1] < plan.height):
			return "#"
		return plan.at(*c)

	def libre(self, e: str, c: Case) -> bool:
		return c not in self.bloquees[e]

	def voisins(self, s: Etat, surf_permis: bool) -> list[Etat]:
		e, x, y, surf = s
		ici = self.car(e, (x, y))
		result: list[Etat] = []
		for dx, dy in DIRECTIONS:
			n = (x + dx, y + dy)
			c = self.car(e, n)
			if not self.libre(e, n) or not compatibles(ici, c):
				continue
			if c == "w":
				if surf or surf_permis:
					result.append((e, n[0], n[1], True))
				continue
			if c not in A_PIED:
				continue
			if c == "E":
				result.append(SORTIE)
			elif c in "UV":
				dest = self.echelles.get((e, n))
				if dest:
					result.append((dest[0], dest[1][0], dest[1][1], False))
			else:
				result.append((e, n[0], n[1], False))
		return result

	def depart(self) -> Etat:
		p = self.plans["1F"].positions["entree"]
		return ("1F", p.cells[0][0], p.cells[0][1], False)

	def parcours(self, surf_permis: bool) -> tuple[set[Etat], dict[Etat, Etat | None]]:
		d = self.depart()
		vus: dict[Etat, Etat | None] = {d: None}
		file = deque([d])
		while file:
			s = file.popleft()
			if s == SORTIE:
				continue
			for n in self.voisins(s, surf_permis):
				if n not in vus:
					vus[n] = s
					file.append(n)
		return set(vus), vus


class Rapport:
	def __init__(self) -> None:
		self.echecs: list[str] = []
		self.notes: list[str] = []

	def ok(self, cond: bool, msg: str) -> bool:
		if not cond:
			self.echecs.append(msg)
		return cond


def verifier(dossier: Path = PLANS, bavard: bool = True) -> Rapport:
	r = Rapport()
	plans = {e: lire(dossier / f"{nom}.txt") for e, nom in CARTES.items()}
	# 1. formes et légende
	for e, plan in plans.items():
		r.ok((plan.width, plan.height) == (LARGEUR, HAUTEUR), f"{e} : 30 × 18")
		autres = {c for row in plan.rows for c in row} - LEGENDE
		r.ok(not autres, f"{e} : caractères hors légende {sorted(autres)}")
		r.ok(not plan.of_kind("pnj"), f"{e} : aucun Dresseur ni PNJ (§8.1)")
		for p in plan.positions.values():
			if p.kind in ("objet", "rencontre"):
				r.ok(p.bloque and plan.at(*p.cells[0]) in A_PIED,
					f"{e} {p.ident} : bloquant, posé sur du sol")
	g = Grotte(plans)
	for err in g.erreurs:
		r.ok(False, err)
	# 2. échelles appariées
	for (e, c), (autre, arrivee) in g.echelles.items():
		ident = next(p for p in plans[e].of_kind("echelle") if p.cells[0] == c)
		sens = ident.attrs.get("sens")
		r.ok(plans[e].at(*c) == ("U" if sens == "monte" else "V"), f"{e} {ident.ident} : U / V et sens")
		retour = [p for p in plans[autre].of_kind("echelle")
			if p.attrs.get("paire") == ident.attrs.get("paire")]
		r.ok(len(retour) == 1 and g.nom_vers_etage.get(retour[0].attrs.get("vers")) == e
			and retour[0].attrs.get("sens") != sens, f"{e} {ident.ident} : paire réciproque")
		r.ok(plans[autre].at(*arrivee) in ".:=" and g.libre(autre, arrivee),
			f"{autre} arrivée {ident.attrs.get('paire')} praticable")
		if retour:
			rc = retour[0].cells[0]
			r.ok(abs(rc[0] - arrivee[0]) + abs(rc[1] - arrivee[1]) == 1,
				f"{autre} arrivée {ident.attrs.get('paire')} voisine de son échelle")
	paires = {p.attrs.get("paire") for plan in plans.values() for p in plan.of_kind("echelle")}
	r.notes.append(f"échelles : {len(g.echelles)} bouts, {len(paires)} paires")
	if r.echecs:
		return r
	# 3. atteignabilité avec le Surf
	etats, parents = g.parcours(True)
	r.ok(SORTIE in etats, "la bouche est atteignable depuis l'entrée")
	for e, plan in plans.items():
		cases = {(s[1], s[2]) for s in etats if s[0] == e}
		toutes = {(x, y) for y in range(plan.height) for x in range(plan.width)
			if plan.at(x, y) in ".:=w" and g.libre(e, (x, y))}
		orphelines = sorted(toutes - cases)
		r.ok(not orphelines, f"{e} : {len(orphelines)} case(s) orpheline(s) {orphelines}")
		eau = sum(1 for c in toutes if plan.at(*c) == "w")
		r.notes.append(f"{e} : {len(toutes)} cases praticables dont {eau} d'eau, "
			f"{len(toutes & cases)} atteintes")
		utilisees = {(e, c) for c in plan.cells_of("U") + plan.cells_of("V")}
		for ec in utilisees:
			arr = g.echelles.get(ec)
			r.ok(arr is not None and (arr[0], arr[1][0], arr[1][1], False) in etats,
				f"{e} échelle {ec[1]} utilisée")
	a_pied = {(s[0], s[1], s[2]) for s in etats if s != SORTIE and not s[3]}
	partout = {(s[0], s[1], s[2]) for s in etats if s != SORTIE}

	def touchable(e: str, c: Case, ensemble: set[tuple[str, int, int]]) -> bool:
		return any((e, c[0] + dx, c[1] + dy) in ensemble
			and compatibles(plans[e].at(c[0] + dx, c[1] + dy), plans[e].at(*c)) for dx, dy in DIRECTIONS)

	for e, plan in plans.items():
		for p in plan.of_kind("objet") + plan.of_kind("rencontre"):
			# Comme dans RB, un objet se ramasse aussi depuis l'eau, en Surf (Max Élixir du 1F).
			r.ok(touchable(e, p.cells[0], partout), f"{e} {p.ident} touché (à pied ou en Surf)")
			if not touchable(e, p.cells[0], a_pied):
				r.notes.append(f"{e} {p.ident} : se touche seulement en Surf")
		for p in plan.of_kind("objet_cache"):
			c = p.cells[0]
			r.ok((e, c[0], c[1]) in a_pied, f"{e} {p.ident} : sa case est atteinte à pied")
			r.ok(any(plan.at(c[0] + dx, c[1] + dy) == "x" for dx, dy in DIRECTIONS
				if 0 <= c[0] + dx < plan.width and 0 <= c[1] + dy < plan.height),
				f"{e} {p.ident} : voisin de son indice x")
	# 4. retour toujours possible
	inverse: dict[Etat, list[Etat]] = {}
	for s in etats:
		if s == SORTIE:
			continue
		for n in g.voisins(s, True):
			inverse.setdefault(n, []).append(s)
	revient = {SORTIE}
	file = deque([SORTIE])
	while file:
		s = file.popleft()
		for p in inverse.get(s, []):
			if p not in revient:
				revient.add(p)
				file.append(p)
	pieges = sorted(etats - revient)
	r.ok(not pieges, f"retour à la bouche impossible depuis {pieges[:6]}")
	# 5. sans le Surf
	sans, _ = g.parcours(False)
	sans_pied = {(s[0], s[1], s[2]) for s in sans if s != SORTIE}
	mewtwo = plans["B1F"].positions["mewtwo"].cells[0]
	r.ok(not touchable("B1F", mewtwo, sans_pied), "sans Surf, Mewtwo n'est pas atteignable")
	atteints = []
	for e, plan in plans.items():
		for p in plan.of_kind("objet") + plan.of_kind("objet_cache"):
			c = p.cells[0]
			ok = (e, c[0], c[1]) in sans_pied if p.kind == "objet_cache" else touchable(e, c, sans_pied)
			if ok:
				atteints.append(f"{e}:{p.attrs.get('item')}")
	etages = sorted({s[0] for s in sans_pied})
	r.notes.append(f"sans Surf : étages {etages}, objets {atteints or 'aucun'}")
	# 6. chemin vers Mewtwo
	cibles = [s for s in etats if s[0] == "B1F" and not s[3]
		and abs(s[1] - mewtwo[0]) + abs(s[2] - mewtwo[1]) == 1]
	if r.ok(bool(cibles), "Mewtwo atteint"):
		dist = {}
		d0 = g.depart()
		dist[d0] = 0
		file = deque([d0])
		while file:
			s = file.popleft()
			if s == SORTIE:
				continue
			for n in g.voisins(s, True):
				if n not in dist:
					dist[n] = dist[s] + 1
					parents[n] = s
					file.append(n)
		but = min(cibles, key=lambda s: dist[s])
		chemin = [but]
		while parents[chemin[-1]] is not None:
			chemin.append(parents[chemin[-1]])
		chemin.reverse()
		echelles = sum(1 for a, b in zip(chemin, chemin[1:]) if a[0] != b[0])
		eau = sum(1 for s in chemin if s[3])
		r.notes.append(f"entrée → Mewtwo : {dist[but]} pas, {echelles} échelles, {eau} cases en Surf, "
			f"étages {' → '.join(dict.fromkeys(s[0] for s in chemin))}")
	if bavard:
		for n in r.notes:
			print("   " + n)
	return r


def autotest() -> bool:
	"""Le contrôle refuse des pièges connus : Mewtwo muré, échelle sans retour, eau isolée."""
	ok = True
	def poser(texte: str, cases: list[Case], car: str) -> str:
		lignes = texte.split("\n")
		debut = lignes.index(f"GRILLE {LARGEUR} {HAUTEUR}") + 1
		for x, y in cases:
			rang = lignes[debut + y]
			lignes[debut + y] = rang[:3 + x] + car + rang[4 + x:]
		return "\n".join(lignes)

	pieges = {
		"Mewtwo muré": ("cerulean_cave_b1f",
			lambda t: poser(t, [(26, 13), (28, 13), (27, 12), (27, 14)], "#")),
		"échelle sans paire": ("cerulean_cave_2f", lambda t: t.replace("paire=P1 sens=descend",
			"paire=P9 sens=descend")),
		"escaliers de la salle de Mewtwo changés en sol haut (eau contre sol haut)":
			("cerulean_cave_b1f", lambda t: poser(t, [(26, 15), (27, 15)], ":")),
		"échelle du B1F murée (piège sans retour)": ("cerulean_cave_b1f",
			lambda t: poser(t, [(3, 6)], "#")),
	}
	for nom, (carte, changer) in pieges.items():
		with tempfile.TemporaryDirectory() as tmp:
			for f in CARTES.values():
				texte = (PLANS / f"{f}.txt").read_text(encoding="utf-8")
				(Path(tmp) / f"{f}.txt").write_text(changer(texte) if f == carte else texte,
					encoding="utf-8")
			r = verifier(Path(tmp), bavard=False)
			refuse = bool(r.echecs)
			print(f"   piège « {nom} » : {'refusé' if refuse else 'ACCEPTÉ (défaut du contrôle)'}")
			ok = ok and refuse
	return ok


def main(argv: list[str]) -> int:
	if "--autotest" in argv:
		print("== Autotest du contrôle de la Grotte Inconnue")
		return 0 if autotest() else 1
	print("== Grotte Inconnue (1F, 2F, B1F)")
	r = verifier()
	for e in r.echecs:
		print(f"   ÉCHEC : {e}")
	print("   conforme" if not r.echecs else f"   {len(r.echecs)} échec(s)")
	return 0 if not r.echecs else 1


if __name__ == "__main__":
	sys.exit(main(sys.argv))
