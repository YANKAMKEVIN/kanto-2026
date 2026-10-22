#!/usr/bin/env python3
"""Vérifie les grilles « mer et ville » du jalon 24 (T2) : Routes 19, 20, 21, Cramois'Île et les
quatre pièces du Labo (dossier 27 §4, §5.2, §9, §10 ; passe j24-v2-alignement.md §2.1, §2.2, §2.6).

Grilles : `tools/plans/route_19.txt`, `route_20.txt`, `route_21.txt`, `cinnabar_island.txt`,
`cinnabar_labo_hall.txt`, `cinnabar_labo_reunion.txt`, `cinnabar_labo_rd.txt`,
`cinnabar_labo_fossiles.txt`. Lecture par `plan_grille.lire`. Les îles Écume (`seafoam_*`) sont
une autre tâche : leurs fichiers ne sont pas lus ici, sauf pour la règle « eau surfable ».

Modèle de déplacement (monde en plusieurs cartes, états = carte, case, mode) :
  - mode `walk` : cases praticables hors `w` ; un rebord `v` ne se saute que vers le sud (atterrissage
    sur la case suivante, non rebord) ; une porte (`D`, `X`) se pose dessus mais ne se traverse pas ;
  - mode `surf` : cases `w` ; de la terre à l'eau on embarque (face à l'eau, SURFER), de l'eau à la
    terre on débarque ; les rebords ne s'abordent pas depuis l'eau ;
  - les positions `bloque` (Dresseurs, PNJ, objets, panneaux, gravats) occupent leur case ;
  - raccords : table SEAMS (ci-dessous) ; le Surf est gardé d'une carte à l'autre.
Les raccords vers Parmanie (J22) et Bourg Palette sont **externes** : le contrôle les compare à
l'attendu documenté, et lit la grille de Bourg Palette dans `tools/build_pallet_town.gd` (sans la
modifier).

Critères (code 1 si l'un échoue) : tailles et légende ; raccords (largeurs, alignements RB × 1,5,
warps et spawns sur les cases ouvertes, eau jointe à l'eau, terre à la terre) ; raccords attendus de
Parmanie et de Bourg Palette ; composantes d'eau (mer est, mer ouest, poche : les deux mers de la
Route 20 ne communiquent pas, test explicite) ; atteignabilité de chaque Dresseur, objet, panneau,
porte, PNJ et de chaque raccord, selon la mer d'où l'on vient ; prairie de la Route 21 inaccessible à
pied ; lignes de vue complètes ; l'approche d'un Dresseur ne ferme aucun passage ; effectif des
Dresseurs et des objets (dossier §9.4, §9.5) ; aucune eau surfable hors de la liste ; intérieurs
fermés avec une seule porte vers l'extérieur.

Usage : python3 tools/art/plan_check_j24_mer.py        code 1 si un critère échoue
"""
from __future__ import annotations

import re
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
HAUT, BAS, GAUCHE, DROITE = (0, -1), (0, 1), (-1, 0), (1, 0)
DIRS = [HAUT, BAS, GAUCHE, DROITE]
FACINGS = {"up": HAUT, "down": BAS, "left": GAUCHE, "right": DROITE}
SURF = "w"
PORTES = set("DX")
REBORD = "v"
EAU_DECOR = "~"

EXTERIEURS = ("route_19", "route_20", "route_21", "cinnabar_island")
INTERIEURS = ("cinnabar_labo_hall", "cinnabar_labo_reunion", "cinnabar_labo_rd",
	"cinnabar_labo_fossiles")
TAILLES = {"route_19": (30, 81), "route_20": (150, 27), "route_21": (30, 135),
	"cinnabar_island": (34, 27), "cinnabar_labo_hall": (27, 12), "cinnabar_labo_reunion": (15, 10),
	"cinnabar_labo_rd": (15, 10), "cinnabar_labo_fossiles": (15, 10)}
LEGENDES = {
	"route_19": set("wvy~RT"), "route_20": set("wyDKR~"), "route_21": set(".hywRT~"),
	"cinnabar_island": set("wR.yXDMZLCO"),
	"cinnabar_labo_hall": set("K.XDPxT"), "cinnabar_labo_reunion": set("K.XSbdTx"),
	"cinnabar_labo_rd": set("K.XQMdTx"), "cinnabar_labo_fossiles": set("K.XMAdTx"),
}


def s(v: int) -> int:
	"""Première case de la plage RB × 1,5 d'une cellule RB : ⌈1,5 v⌉."""
	return (3 * v + 1) // 2


def plage_rb(a: int, b: int) -> tuple[int, int]:
	"""Cellules RB a..b → cases ×1,5 : (⌈1,5 a⌉, ⌈1,5 (b+1)⌉ - 1)."""
	return s(a), s(b + 1) - 1


def arrondi_vue(rb: int) -> int:
	return int(rb * 1.5 + 0.5)


# --- raccords RB (désassemblage pokered, passe §2.1) ---------------------------------------------
# Route 19 ↔ Route 20 : connexion `east, Route19, offset -18` (blocs) : R19 y = R20 y + 36 cellules,
# soit ×1,5 : + 54 ; R19 colonne 0 ouverte aux cellules 40..52 ; R20 colonne 99 ouverte aux
# cellules 4..16.
DECALAGE_19_20 = 54
RB_R19_OUVERT = (40, 52)
RB_R20_EST = (4, 16)
# Route 20 ↔ Cramois'Île : `west, CinnabarIsland, offset 0` ; rangées ouvertes RB 4..16.
RB_R20_OUEST = (4, 16)
# Route 21 ↔ Cramois'Île : décalage 0 ; eau RB x1..3, chemin RB x10..13.
RB_CINN_EAU = (1, 3)
RB_CINN_CHEMIN = (10, 13)
# Route 19 ↔ Parmanie : Parmanie 40 cellules RB, sortie sud RB x16..23, R19 colonne 0 = x10.
RB_PARMANIE_SORTIE = (16, 23)
RB_PARMANIE_DECALAGE_X = 10
PARMANIE_LARGEUR, PARMANIE_HAUTEUR = 60, 54
PARMANIE_COLONNE = 15            # colonne Parmanie = colonne Route 19 + 15 (10 × 1,5)
PALETTE_TAILLE = (48, 34)
PALETTE_DECALAGE = 3             # colonne Palette = colonne Route 21 + 3
PALETTE_CANAL = (10, 14)

# Raccords : (carte, côté) → fonction (x, y) de la case SORTIE (hors carte) → (carte, x, y) | None
# (None : bord fermé ; "EXT:parmanie" / "EXT:palette" : raccord externe).
def _raccord(carte: str, x: int, y: int, tailles: dict[str, tuple[int, int]]):
	w, h = tailles[carte]
	if carte == "route_19":
		if x < 0:
			return ("route_20", tailles["route_20"][0] - 1, y - DECALAGE_19_20)
		if y < 0:
			return ("EXT:parmanie", x + PARMANIE_COLONNE, PARMANIE_HAUTEUR - 1)
	if carte == "route_20":
		if x >= w:
			return ("route_19", 0, y + DECALAGE_19_20)
		if x < 0:
			return ("cinnabar_island", tailles["cinnabar_island"][0] - 1, y)
	if carte == "route_21":
		if y < 0:
			return ("EXT:palette", x + PALETTE_DECALAGE, PALETTE_TAILLE[1] - 1)
		if y >= h:
			return ("cinnabar_island", x, 0)
	if carte == "cinnabar_island":
		if y < 0:
			return ("route_21", x, tailles["route_21"][1] - 1)
		if x >= w:
			return ("route_20", 0, y)
	return None


class Monde:
	"""Plusieurs cartes reliées par leurs raccords, états (carte, case, mode)."""

	def __init__(self, plans: dict[str, Plan]) -> None:
		self.plans = plans
		self.tailles = {n: (p.width, p.height) for n, p in plans.items()}
		self.bloquees: dict[str, set[Case]] = {n: set() for n in plans}
		for n, p in plans.items():
			for q in p.positions.values():
				if q.bloque:
					self.bloquees[n].update(q.cells)

	def char(self, m: str, c: Case) -> str:
		return self.plans[m].at(*c)

	def terre(self, m: str, c: Case) -> bool:
		ch = self.char(m, c)
		return ch in self.plans[m].praticables and ch != SURF

	def genre(self, m: str, c: Case) -> str:
		"""'eau' | 'terre' | 'porte' | 'rebord' | 'mur'."""
		ch = self.char(m, c)
		if ch not in self.plans[m].praticables:
			return "mur"
		if ch == SURF:
			return "eau"
		if ch in PORTES:
			return "porte"
		if ch == REBORD:
			return "rebord"
		return "terre"

	def dans(self, m: str, c: Case) -> bool:
		w, h = self.tailles[m]
		return 0 <= c[0] < w and 0 <= c[1] < h

	def voisin(self, m: str, c: Case, d: Case):
		"""(carte, case, par_raccord) de la case voisine, ou None (hors carte fermé), ou ('EXT…')."""
		n = (c[0] + d[0], c[1] + d[1])
		if self.dans(m, n):
			return (m, n, False)
		r = _raccord(m, n[0], n[1], self.tailles)
		if r is None:
			return None
		if r[0].startswith("EXT:"):
			return (r[0], (r[1], r[2]), True)
		if not self.dans(r[0], (r[1], r[2])):
			return None
		return (r[0], (r[1], r[2]), True)

	def suivants(self, etat, extra: frozenset | set = frozenset(), embarquer: bool = True,
			externes: set | None = None):
		m, c, mode = etat
		if self.genre(m, c) == "porte":
			return
		for d in DIRS:
			v = self.voisin(m, c, d)
			if v is None:
				continue
			m2, c2, raccord = v
			if m2.startswith("EXT:"):
				if externes is not None:
					externes.add((m, c, mode, m2, c2))
				continue
			if (m2, c2) in extra or c2 in self.bloquees[m2]:
				continue
			g = self.genre(m2, c2)
			if g == "mur":
				continue
			if g == "eau":
				if mode == "walk" and (raccord or not embarquer):
					continue
				yield (m2, c2, "surf")
			elif g == "rebord":
				if mode != "walk" or d != BAS or raccord:
					continue
				a = (c2[0], c2[1] + 1)
				if not self.dans(m2, a) or a in self.bloquees[m2] or (m2, a) in extra:
					continue
				if self.genre(m2, a) in ("terre", "porte"):
					yield (m2, a, "walk")
			else:  # terre, porte
				if mode == "surf" and raccord:
					continue
				yield (m2, c2, "walk")

	def atteint(self, departs, extra=frozenset(), embarquer: bool = True,
			externes: set | None = None) -> set:
		vu = set(departs)
		file = deque(vu)
		while file:
			e = file.popleft()
			for n in self.suivants(e, extra, embarquer, externes):
				if n not in vu:
					vu.add(n)
					file.append(n)
		return vu


def cases_atteintes(etats: set) -> set[tuple[str, Case]]:
	return {(m, c) for m, c, _ in etats}


def bord(plan: Plan, cote: str) -> list[Case]:
	if cote == "N":
		return [(x, 0) for x in range(plan.width)]
	if cote == "S":
		return [(x, plan.height - 1) for x in range(plan.width)]
	if cote == "O":
		return [(0, y) for y in range(plan.height)]
	return [(plan.width - 1, y) for y in range(plan.height)]


def ouvertes(plan: Plan, cases: list[Case]) -> list[Case]:
	return [c for c in cases if plan.at(*c) in plan.praticables]


def pos_par_kind(plan: Plan, *kinds: str):
	return [p for p in plan.positions.values() if p.kind in kinds]


def lignes(cases: list[Case]) -> str:
	if not cases:
		return "aucune"
	return ", ".join(f"({c[0]},{c[1]})" for c in cases[:6]) + (" …" if len(cases) > 6 else "")


def intervalle(vals: list[int]) -> str:
	if not vals:
		return "∅"
	vals = sorted(vals)
	morceaux, debut, prec = [], vals[0], vals[0]
	for v in vals[1:]:
		if v == prec + 1:
			prec = v
			continue
		morceaux.append(f"{debut}..{prec}" if debut != prec else f"{debut}")
		debut = prec = v
	morceaux.append(f"{debut}..{prec}" if debut != prec else f"{debut}")
	return ";".join(morceaux)


def lire_palette() -> list[list[str]] | None:
	"""Types de sol de Bourg Palette (tools/build_pallet_town.gd, GROUND puis OBSTACLES)."""
	chemin = RACINE / "tools" / "build_pallet_town.gd"
	if not chemin.exists():
		return None
	texte = chemin.read_text(encoding="utf-8")
	m = re.search(r"const SIZE := Vector2i\((\d+), (\d+)\)", texte)
	if not m:
		return None
	w, h = int(m.group(1)), int(m.group(2))
	grille = [["" for _ in range(w)] for _ in range(h)]
	for bloc in ("GROUND", "OBSTACLES"):
		d = re.search(r"const %s: Array = \[(.*?)\n\]" % bloc, texte, re.S)
		if not d:
			return None
		for k, x0, y0, x1, y1 in re.findall(
				r'\["(\w+)",\s*\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\]\]', d.group(1)):
			for y in range(int(y0), int(y1) + 1):
				for x in range(int(x0), int(x1) + 1):
					grille[y][x] = k
	return grille


def verifier() -> bool:
	ok = True

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	plans: dict[str, Plan] = {}
	for n in EXTERIEURS + INTERIEURS:
		chemin = PLANS / f"{n}.txt"
		if not chemin.exists():
			print(f"  [ÉCHEC] grille absente : {chemin}")
			return False
		plans[n] = lire(chemin)
	monde = Monde({n: plans[n] for n in EXTERIEURS})
	print("== Tailles et légendes")
	for n, p in plans.items():
		critere((p.width, p.height) == TAILLES[n], f"{n} : {p.width} × {p.height} (attendu "
			f"{TAILLES[n][0]} × {TAILLES[n][1]})")
		chars = {c for r in p.rows for c in r}
		critere(chars <= LEGENDES[n], f"{n} : légende {''.join(sorted(chars))} "
			f"(hors légende : {''.join(sorted(chars - LEGENDES[n])) or 'aucune'})")
		critere("s" not in chars, f"{n} : aucun « s » (Surf forcé réservé au B3F/B4F)")
		if n in INTERIEURS:
			critere(SURF not in chars and SURF not in p.praticables,
				f"{n} : aucune eau surfable dans un intérieur")

	# ------------------------------------------------------------------ raccords
	print("== Raccords (largeurs et alignements RB × 1,5)")
	p19, p20, p21, pc = (plans[n] for n in EXTERIEURS)
	# Route 19 ↔ Route 20
	o19 = ouvertes(p19, bord(p19, "O"))
	o20 = ouvertes(p20, bord(p20, "E"))
	a, b = plage_rb(*RB_R19_OUVERT)
	critere([y for _, y in o19] == list(range(a, b + 1)),
		f"Route 19 bord ouest : rangées {intervalle([y for _, y in o19])} ouvertes "
		f"(attendu RB {RB_R19_OUVERT[0]}..{RB_R19_OUVERT[1]} × 1,5 = {a}..{b})")
	a2, b2 = plage_rb(*RB_R20_EST)
	critere([y for _, y in o20] == list(range(a2, b2 + 1)),
		f"Route 20 bord est : rangées {intervalle([y for _, y in o20])} ouvertes "
		f"(attendu RB {RB_R20_EST[0]}..{RB_R20_EST[1]} × 1,5 = {a2}..{b2})")
	critere(len(o19) == len(o20) and all(y19 - DECALAGE_19_20 == y20
		for (_, y19), (_, y20) in zip(o19, o20)),
		f"Route 19 (0, y) ↔ Route 20 ({p20.width - 1}, y - {DECALAGE_19_20}) : même largeur "
		f"({len(o19)}) et alignement (RB : 18 blocs = 36 cellules = 54 cases)")
	critere(DECALAGE_19_20 == s(36), "décalage 54 = 36 cellules RB × 1,5")
	# Route 20 ↔ Cramois'Île
	o20w = ouvertes(p20, bord(p20, "O"))
	ocn_e = ouvertes(pc, bord(pc, "E"))
	a3, b3 = plage_rb(*RB_R20_OUEST)
	critere([y for _, y in o20w] == [y for _, y in ocn_e] == list(range(a3, b3 + 1)),
		f"Route 20 bord ouest ↔ Cramois'Île bord est : rangées {intervalle([y for _, y in o20w])} "
		f"(attendu RB {RB_R20_OUEST[0]}..{RB_R20_OUEST[1]} × 1,5 = {a3}..{b3}, décalage 0)")
	# Route 21 ↔ Cramois'Île
	o21s = ouvertes(p21, bord(p21, "S"))
	ocn_n = ouvertes(pc, bord(pc, "N"))
	eau = plage_rb(*RB_CINN_EAU)
	chemin = plage_rb(*RB_CINN_CHEMIN)
	attendu = list(range(eau[0], eau[1] + 1)) + list(range(chemin[0], chemin[1] + 1))
	critere([x for x, _ in o21s] == [x for x, _ in ocn_n] == attendu,
		f"Route 21 bord sud ↔ Cramois'Île bord nord : colonnes {intervalle([x for x, _ in o21s])} "
		f"(attendu RB eau {RB_CINN_EAU} + chemin {RB_CINN_CHEMIN} × 1,5 = {eau[0]}..{eau[1]} ; "
		f"{chemin[0]}..{chemin[1]}, décalage 0)")

	def genre_ok(ma: str, ca: Case, mb: str, cb: Case) -> bool:
		return monde.genre(ma, ca) == monde.genre(mb, cb) and monde.genre(ma, ca) in ("eau", "terre")

	mauvais: list[str] = []
	for (ma, cote) in (("route_19", "O"), ("route_20", "E"), ("route_20", "O"),
			("cinnabar_island", "E"), ("route_21", "S"), ("cinnabar_island", "N")):
		for c in bord(plans[ma], cote):
			d = {"O": GAUCHE, "E": DROITE, "N": HAUT, "S": BAS}[cote]
			v = monde.voisin(ma, c, d)
			if v is None:
				if monde.genre(ma, c) != "mur":
					mauvais.append(f"{ma} {c} ouvert sans raccord")
				continue
			mb, cb, _ = v
			# réciproque
			inv = {GAUCHE: DROITE, DROITE: GAUCHE, HAUT: BAS, BAS: HAUT}[d]
			r = monde.voisin(mb, cb, inv)
			if r is None or (r[0], r[1]) != (ma, c):
				mauvais.append(f"{ma} {c} → {mb} {cb} non réciproque")
				continue
			ga, gb = monde.genre(ma, c), monde.genre(mb, cb)
			if (ga in ("eau", "terre") or gb in ("eau", "terre")) and not genre_ok(ma, c, mb, cb):
				mauvais.append(f"{ma} {c} ({ga}) ↔ {mb} {cb} ({gb})")
	critere(not mauvais, "raccords réciproques, eau jointe à l'eau, terre à la terre, mur à mur"
		+ (f" : {mauvais[:4]}" if mauvais else ""))
	# warps et spawns sur les cases ouvertes
	for (n, cote, nom_w) in (("route_19", "O", "warp_ouest"), ("route_20", "E", "warp_est"),
			("route_20", "O", "warp_ouest"), ("cinnabar_island", "E", "warp_est")):
		pl = plans[n]
		ouv = set(ouvertes(pl, bord(pl, cote)))
		w = set(pl.positions[nom_w].cells)
		spawn = {c for q in pos_par_kind(pl, "spawn") for c in q.cells
			if c in bord(pl, cote)}
		critere(ouv == w == spawn, f"{n} bord {cote} : cases ouvertes = warps = spawns "
			f"({len(ouv)} cases)")
	ouv = set(ouvertes(p21, bord(p21, "S"))) | set(ouvertes(pc, bord(pc, "N")))
	w21 = {c for q in pos_par_kind(p21, "warp") for c in q.cells if c[1] == p21.height - 1}
	sp21 = {c for q in pos_par_kind(p21, "spawn") for c in q.cells if c[1] == p21.height - 1}
	wc = {c for q in pos_par_kind(pc, "warp") for c in q.cells if c[1] == 0}
	spc = {c for q in pos_par_kind(pc, "spawn") for c in q.cells if c[1] == 0}
	critere({x for x, _ in o21s} == {x for x, _ in w21} == {x for x, _ in sp21}
		== {x for x, _ in wc} == {x for x, _ in spc},
		"Route 21 sud / Cramois'Île nord : cases ouvertes = warps = spawns des deux côtés")

	# ------------------------------------------------------------------ Parmanie (externe)
	print("== Raccord attendu côté Parmanie (J22) — Route 19, bord nord")
	o19n = [x for x, _ in ouvertes(p19, bord(p19, "N"))]
	attendu_parm = [x + PARMANIE_COLONNE for x in o19n]
	a, b = plage_rb(*RB_PARMANIE_SORTIE)
	critere(all(a <= x <= b for x in attendu_parm),
		f"colonnes Parmanie attendues {intervalle(attendu_parm)} (dernière rangée y = "
		f"{PARMANIE_HAUTEUR - 1} d'une carte de {PARMANIE_LARGEUR} × {PARMANIE_HAUTEUR}) : dans la "
		f"sortie RB x{RB_PARMANIE_SORTIE[0]}..{RB_PARMANIE_SORTIE[1]} × 1,5 = {a}..{b}")
	critere(PARMANIE_COLONNE == s(RB_PARMANIE_DECALAGE_X),
		f"décalage {PARMANIE_COLONNE} = colonne RB {RB_PARMANIE_DECALAGE_X} × 1,5")
	rep = p19.positions["raccord_parmanie"]
	critere(rep.attrs.get("parmanie_colonnes") == intervalle(attendu_parm),
		f"raccord_parmanie documenté ({rep.attrs.get('parmanie_colonnes')}) = calculé "
		f"({intervalle(attendu_parm)})")
	critere(set(p19.positions["warp_nord_terrasse"].cells) | set(p19.positions["warp_nord_couloir"].cells)
		== set(ouvertes(p19, bord(p19, "N"))) == set(p19.positions["from_fuchsia_city"].cells),
		"Route 19 nord : cases ouvertes = warps = spawns")

	# ------------------------------------------------------------------ Bourg Palette (externe)
	print("== Raccord attendu côté Bourg Palette — Route 21, bord nord")
	o21n = [x for x, _ in ouvertes(p21, bord(p21, "N"))]
	cols = [x + PALETTE_DECALAGE for x in o21n]
	critere((min(cols), max(cols)) == PALETTE_CANAL and len(o21n) == 5,
		f"canal de la Route 21 (colonnes {intervalle(o21n)}) ↔ Palette colonnes {intervalle(cols)}, "
		f"ligne {PALETTE_TAILLE[1] - 1} (décalage +{PALETTE_DECALAGE})")
	a, b = plage_rb(5, 7)
	critere(set(range(a, b + 1)) <= set(o21n) and (min(o21n) + max(o21n)) % 2 == 0,
		f"le canal contient les cases RB x5..7 × 1,5 ({a}..{b}) ; élargi à {len(o21n)} cases, centré")
	grille = lire_palette()
	if grille is None:
		critere(False, "grille de Bourg Palette illisible (tools/build_pallet_town.gd)")
	else:
		haut = len(grille)
		larg = len(grille[0])
		critere((larg, haut) == PALETTE_TAILLE, f"Bourg Palette : {larg} × {haut}")
		kinds = {grille[y][x] for y in (haut - 2, haut - 1) for x in range(*[PALETTE_CANAL[0],
			PALETTE_CANAL[1] + 1])}
		critere(kinds <= {"WATER", "SHALLOW"},
			f"Palette, cases ({PALETTE_CANAL[0]}..{PALETTE_CANAL[1]}, {haut - 2}..{haut - 1}) : "
			f"{sorted(kinds)} (eau attendue ; le ponton BOARDWALK (9, 32..33) est hors du canal)")
		plage = {grille[haut - 3][x] for x in range(PALETTE_CANAL[0], PALETTE_CANAL[1] + 1)}
		critere(plage == {"SAND"}, f"Palette, case au-dessus du canal (y = {haut - 3}) : "
			f"{sorted(plage)} (plage de sable pour embarquer)")
		hors = [x for x in range(larg) if grille[haut - 1][x] in ("WATER", "SHALLOW")
			and not PALETTE_CANAL[0] <= x <= PALETTE_CANAL[1]]
		critere(True, f"info : la ligne {haut - 1} de Palette est de l'eau sur {len(hors) + 5} "
			f"colonnes ; seules les colonnes {PALETTE_CANAL[0]}..{PALETTE_CANAL[1]} se prolongent "
			f"dans la Route 21 (le reste est un récif côté Route 21)")
		ferme = all(p21.at(x, 0) not in p21.praticables for x in range(p21.width)
			if x not in o21n)
		critere(ferme, "Route 21 rangée 0 : fermée hors du canal")

	# ------------------------------------------------------------------ eau
	print("== Composantes d'eau (les deux mers ne communiquent pas, P-6)")
	eau_cases = {(m, (x, y)) for m in EXTERIEURS for y in range(plans[m].height)
		for x in range(plans[m].width) if plans[m].at(x, y) == SURF}
	comp: dict[tuple[str, Case], int] = {}
	nb = 0
	for e in sorted(eau_cases):
		if e in comp:
			continue
		nb += 1
		comp[e] = nb
		pile = [e]
		while pile:
			m, c = pile.pop()
			for d in DIRS:
				v = monde.voisin(m, c, d)
				if v is None or v[0].startswith("EXT:"):
					continue
				k = (v[0], v[1])
				if k in eau_cases and k not in comp:
					comp[k] = nb
					pile.append(k)
	tailles_c = {i: sum(1 for v in comp.values() if v == i) for i in range(1, nb + 1)}
	critere(nb == 3, f"3 composantes d'eau surfable exactement (trouvées : {nb} de "
		f"{sorted(tailles_c.values(), reverse=True)} cases)")
	c_est = comp[("route_19", (10, 30))]
	c_est2 = comp[("route_20", (p20.width - 1, 10))]
	c_ouest = comp[("route_21", (9, 50))]
	c_ouest2 = comp[("route_20", (0, 10))]
	c_cinn = comp[("cinnabar_island", (3, 10))]
	c_poche = comp[("route_20", (67, 15))]
	critere(c_est == c_est2, "mer EST : Route 19 et bord est de la Route 20 communiquent")
	critere(c_ouest == c_ouest2 == c_cinn, "mer OUEST : Route 21, Cramois'Île et bord ouest de la "
		"Route 20 communiquent")
	critere(len({c_est, c_ouest, c_poche}) == 3,
		"TEST : mer est, mer ouest et poche fermée de la Route 20 sont trois composantes distinctes")
	noms_mer = {"est": c_est, "ouest": c_ouest, "poche": c_poche}
	crees = {m: {comp.get((m, (x, y))) for y in range(plans[m].height) for x in range(plans[m].width)}
		for m in EXTERIEURS}
	critere(crees["route_19"] == {None, c_est},
		"Route 19 : toute son eau est dans la mer est")
	critere(crees["route_21"] == {None, c_ouest}, "Route 21 : toute son eau est dans la mer ouest")
	critere(crees["route_20"] == {None, c_est, c_ouest, c_poche},
		"Route 20 : mer est, mer ouest et poche")
	porte_o = p20.positions["porte_ouest"].cells
	porte_e = p20.positions["porte_est"].cells

	# ------------------------------------------------------------------ atteignabilité
	print("== Atteignabilité (Surf, débarquement, rebords, portes terminales)")
	terrasse = list(p19.positions["warp_nord_terrasse"].cells)
	couloir = list(p19.positions["warp_nord_couloir"].cells)
	depart_a = {("route_19", c, "walk") for c in terrasse + couloir}
	depart_b = {("route_21", (x, 0), "surf") for x in o21n}
	externes: set = set()
	reach_a = monde.atteint(depart_a, externes=externes)
	reach_b = monde.atteint(depart_b, externes=externes)
	ca, cb = cases_atteintes(reach_a), cases_atteintes(reach_b)
	critere(not (ca & cb & {(m, c) for (m, c) in eau_cases}),
		"aucune case d'eau commune aux deux voyages (Parmanie par la Route 19 ; Bourg Palette par la "
		"Route 21)")
	# Du Parmanie : toute la Route 19, la mer est, l'île par la rive est, la poche.
	def libres(n: str) -> set[tuple[str, Case]]:
		"""Cases où l'on peut se tenir : praticables, ni rebord, ni occupées."""
		pl = plans[n]
		return {(n, (x, y)) for y in range(pl.height) for x in range(pl.width)
			if pl.at(x, y) in pl.praticables and pl.at(x, y) != REBORD
			and (x, y) not in monde.bloquees[n]}
	r19_praticables = libres("route_19")
	critere(r19_praticables <= ca, "depuis Parmanie : toutes les cases praticables de la Route 19 "
		"(plage, terrasse, couloir, mer) sont atteintes")
	r21_praticables = libres("route_21")
	critere(r21_praticables <= cb, "depuis Bourg Palette : toutes les cases praticables de la "
		"Route 21 (mer, prairie, îlots, pointe) sont atteintes")
	pcn = libres("cinnabar_island")
	critere(pcn <= cb, "depuis Bourg Palette : toute la ville de Cramois'Île est atteinte")
	critere(not (pcn & ca), "depuis Parmanie : Cramois'Île n'est PAS atteinte (il faut passer par les "
		"Îles Écume)")
	eau20 = {("route_20", c) for (m, c) in eau_cases if m == "route_20"
		and c not in monde.bloquees["route_20"]}
	est20 = {k for k in eau20 if comp[k] == c_est}
	ouest20 = {k for k in eau20 if comp[k] == c_ouest}
	poche20 = {k for k in eau20 if comp[k] == c_poche}
	critere(est20 <= ca and not (est20 & cb), "mer est de la Route 20 : atteinte depuis Parmanie "
		"seulement")
	critere(ouest20 <= cb and not (ouest20 & ca), "mer ouest de la Route 20 : atteinte depuis Bourg "
		"Palette seulement")
	critere(poche20 <= ca and not (poche20 & cb),
		"poche fermée : atteinte depuis Parmanie seulement (par la rive ouest de l'île)")
	# la poche ne touche que la terre de l'île ouest (RB : « rive ouest ») : sans ces cases, jamais.
	rive_poche = {("route_20", (x + dx, y + dy)) for (_, (x, y)) in poche20 for dx, dy in DIRS
		if p20.at(x + dx, y + dy) == "y"}
	critere(rive_poche and all(69 <= c[0] <= 83 and 9 <= c[1] <= 14 for _, c in rive_poche),
		f"la poche ne touche que la terre de l'île ouest ({len(rive_poche)} cases, x 69..83, y 9..14 : "
		f"RB x46..55, y6..9)")
	reach_sans_rive = monde.atteint(depart_a, extra=rive_poche)
	critere(not (poche20 & cases_atteintes(reach_sans_rive)),
		"sans ces cases de rive, la poche n'est atteinte d'aucune façon depuis Parmanie")
	critere(not (rive_poche & {("route_20", c) for c in
		[(x, y) for y in range(15, 18) for x in range(84, 93)]}),
		"la grève de l'entrée est ne touche pas la poche")
	# porte ouest / porte est
	def acces(m: str, cases) -> set[tuple[str, Case]]:
		return {(m, (c[0] + d[0], c[1] + d[1])) for c in cases for d in DIRS}
	porte_o_etats = {("route_20", c) for c in porte_o}
	porte_e_etats = {("route_20", c) for c in porte_e}
	critere(porte_o_etats <= ca and not (porte_o_etats & cb),
		"entrée OUEST (72..73, 8) : atteinte depuis la mer est (Parmanie), jamais depuis la mer ouest")
	critere(porte_e_etats <= cb and not (porte_e_etats & ca),
		"entrée EST (87..88, 14) : atteinte depuis la mer ouest (Bourg Palette), jamais depuis la mer est")
	# les deux mers ne communiquent pas, test sans Îles Écume : des deux départs, l'autre côté est
	# inatteignable (déjà prouvé) ; on prouve aussi que chaque mer touche sa propre entrée
	critere(porte_o and porte_e, "deux entrées de grotte")

	# Chaque raccord de chaque bord est atteignable
	touts = ca | cb
	for n, cote, nom in (("route_19", "O", "warp_ouest"), ("route_20", "E", "warp_est"),
			("route_20", "O", "warp_ouest"), ("cinnabar_island", "E", "warp_est"),
			("route_21", "S", "warp_sud_eau"), ("route_21", "S", "warp_sud_terre"),
			("cinnabar_island", "N", "warp_nord_eau"), ("cinnabar_island", "N", "warp_nord_terre"),
			("route_21", "N", "warp_nord")):
		cases = [(n, c) for c in plans[n].positions[nom].cells]
		critere(all(k in touts for k in cases),
			f"raccord {n} {nom} ({len(cases)} cases) : atteint")
	# Route 19 nord : terrasse à sens unique, couloir de retour
	r_terr = monde.atteint({("route_19", c, "surf") for c in [(9, 30)]})  # depuis la mer
	k_terr = cases_atteintes(r_terr)
	critere(all(("route_19", c) in k_terr for c in couloir),
		"Route 19 : du couloir (19..20, 0) on remonte vers Parmanie depuis la mer")
	critere(not any(("route_19", c) in k_terr for c in terrasse),
		"Route 19 : la terrasse de sable (9..17, 0) ne se remonte pas (rebords, sens unique)")

	# ------------------------------------------------------------------ prairie
	print("== Prairie de la Route 21 (herbes hautes, accessible seulement en Surf)")
	herbes = {("route_21", c) for c in p21.cells_of("h")}
	critere(len(herbes) == 81, f"{len(herbes)} cases d'herbes hautes (RB 36 × 2,25 = 81)")
	marche_depart = {("route_19", c, "walk") for c in terrasse + couloir}
	marche_depart |= {("cinnabar_island", c, "walk") for c in (q for q in
		[(x, 0) for x in range(15, 21)])}
	marche_depart |= {("route_21", (x, p21.height - 1), "walk") for x in range(15, 21)}
	a_pied = monde.atteint(marche_depart, embarquer=False)
	critere(not (herbes & cases_atteintes(a_pied)),
		"à pied (sans jamais embarquer), depuis chaque bord de terre : aucune case de la prairie")
	critere(any(m == "route_21" and p21.at(*c) == "y" for m, c, _ in a_pied),
		"à pied, la pointe de sable de la Route 21 est atteinte (raccord à pied de Cramois'Île)")
	critere(herbes <= cb, "en Surf depuis Bourg Palette : toute la prairie est atteinte")
	critere(not (herbes & ca), "en Surf depuis Parmanie : la prairie n'est pas atteinte")
	voisins_prairie = {("route_21", (x + dx, y + dy)) for _, (x, y) in herbes for dx, dy in DIRS}
	critere(not any(p21.at(*c) in ("y", ".") and k[0] == "route_21" and k not in herbes
		and p21.at(*k[1]) != "." for k in voisins_prairie for c in [k[1]]),
		"la prairie ne touche aucune terre hors d'elle-même (seulement eau et récifs)")

	# ------------------------------------------------------------------ positions
	print("== Positions : Dresseurs, objets, panneaux, PNJ, portes")
	attendu_n = {"route_19": 10, "route_20": 10, "route_21": 9}
	for n, k in attendu_n.items():
		d = pos_par_kind(plans[n], "dresseur")
		critere(len(d) == k, f"{n} : {len(d)} Dresseurs (dossier §9.4 : {k})")
	total = sum(len(pos_par_kind(plans[n], "dresseur")) for n in attendu_n)
	critere(total == 29, f"29 Dresseurs en tout (P-13) : {total}")
	nageurs = {n: sum(1 for q in pos_par_kind(plans[n], "dresseur") if q.attrs["mode"] == "nageur")
		for n in attendu_n}
	critere(nageurs == {"route_19": 8, "route_20": 9, "route_21": 5},
		f"Nageurs : {nageurs} (dossier : 8, 9, 5)")
	noms = {"route_19": ["hugo", "malo", "yann", "erwan", "loic", "tanguy", "gwen", "maelle",
			"anais", "lena"],
		"route_20": ["ronan", "solene", "iris", "lou", "mathis", "kilian", "bastien", "clara",
			"nina", "elsa"],
		"route_21": ["gilles", "marcel", "thibault", "dylan", "simon", "arthur", "noe", "rene",
			"yves"]}
	for n, liste in noms.items():
		critere(sorted(q.ident for q in pos_par_kind(plans[n], "dresseur")) == sorted(liste),
			f"{n} : positions nommées d'après le dossier §9.4 ({', '.join(liste)})")

	def libre_vue(n: str, c: Case) -> bool:
		g = monde.genre(n, c)
		return g in ("eau", "terre", "porte", "rebord") and c not in monde.bloquees[n]

	lignes_vue: dict[tuple[str, str], list[Case]] = {}
	for n in attendu_n:
		pl = plans[n]
		for q in pos_par_kind(pl, "dresseur"):
			c0 = q.cells[0]
			mode, fc = q.attrs["mode"], q.attrs["facing"]
			sg, rbsg = int(q.attrs["sight"]), int(q.attrs["rbsight"])
			rb = tuple(int(v) for v in q.attrs["rb"].split(","))
			ch = pl.at(*c0)
			attendu_c = (s(rb[0]), s(rb[1]))
			vue = []
			for k in range(1, sg + 1):
				c = (c0[0] + FACINGS[fc][0] * k, c0[1] + FACINGS[fc][1] * k)
				if not monde.dans(n, c) or not libre_vue(n, c):
					break
				vue.append(c)
			lignes_vue[(n, q.ident)] = vue
			critere(c0 == attendu_c and sg == arrondi_vue(rbsg)
				and ((mode == "nageur" and ch == SURF) or (mode == "pied" and monde.terre(n, c0)))
				and len(vue) == sg and ("sight" in q.attrs),
				f"{n} {q.ident} {c0} {fc} : RB {rb} → {attendu_c}, vue {rbsg} → {sg} "
				f"({len(vue)} cases dégagées), {mode} sur « {ch} » ({q.attrs['mer']})")
	# Atteignabilité par Dresseur, selon la mer (et à pied pour la plage)
	def etats_voisins(n: str, cases) -> set:
		return {(n, (c[0] + d[0], c[1] + d[1])) for c in cases for d in DIRS}

	a_pied_a = monde.atteint(depart_a, embarquer=False)
	for n in attendu_n:
		for q in pos_par_kind(plans[n], "dresseur"):
			cote = q.attrs["mer"]
			voisins = etats_voisins(n, q.cells)
			dans_a = bool(voisins & ca)
			dans_b = bool(voisins & cb)
			if cote in ("est", "poche", "plage"):
				bon = dans_a and not dans_b
			else:
				bon = dans_b and not dans_a
			if cote == "plage":
				bon &= bool(voisins & cases_atteintes(a_pied_a))
			if cote in ("ilot_nord", "ilot_sud"):
				bon &= q.attrs["mode"] == "pied"
			critere(bon, f"{n} {q.ident} atteignable ({cote}) : depuis Parmanie {dans_a}, depuis "
				f"Bourg Palette {dans_b}" + (", à pied" if cote == "plage" else ""))
	# objets
	for n in ("route_20", "route_21"):
		for q in pos_par_kind(plans[n], "objet_visible"):
			voisins = etats_voisins(n, q.cells)
			ch = plans[n].at(*q.cells[0])
			vue_toutes = {c for (nn, i), v in lignes_vue.items() if nn == n for c in v}
			cote_b = n == "route_21" or q.ident == "ilot_super_balls"
			bon = bool(voisins & cb) and not (voisins & ca) and cote_b and ch in ".y" \
				and q.cells[0] not in vue_toutes
			critere(bon, f"{n} objet {q.ident} {q.cells[0]} sur « {ch} » ({q.attrs.get('item')}"
				f"{' ×' + q.attrs['qty'] if 'qty' in q.attrs else ''}) : atteint depuis la mer ouest "
				f"seulement, hors des lignes de vue")
	nobj = sum(len(pos_par_kind(plans[n], "objet_visible")) for n in ("route_20", "route_21"))
	critere(nobj == 3, f"3 objets visibles répartis Route 20 / 21 (dossier §9.5) : {nobj}")
	critere({q.attrs["item"] for n in ("route_20", "route_21")
		for q in pos_par_kind(plans[n], "objet_visible")} == {"super_ball", "max_repel", "hyper_potion"},
		"objets : Super Ball ×3 (îlot de l'Ornithologue), Max Repousse (prairie), Hyper Potion (îlot sud)")
	critere(plans["route_20"].positions["ilot_super_balls"].attrs.get("qty") == "3", "Super Ball ×3")
	# panneaux
	for n in ("route_19", "route_20", "cinnabar_island"):
		for q in pos_par_kind(plans[n], "panneau"):
			c = q.cells[0]
			ch = plans[n].at(*c)
			atteints = ca if n == "route_19" else (cb if n == "cinnabar_island" else None)
			if n == "route_20":
				atteints = ca if q.ident == "panneau_ouest" else cb
				autre = cb if q.ident == "panneau_ouest" else ca
			else:
				autre = set()
			voisins = etats_voisins(n, q.cells)
			terre_voisine = {k for k in voisins if monde.dans(*k)
				and monde.genre(*k) in ("terre",) and k not in monde.bloquees[k[0]]}
			bon = ch in ".y" and bool(terre_voisine & atteints) and not (voisins & autre
				& {(m, cc) for (m, cc) in terre_voisine})
			critere(bon, f"{n} {q.ident} {c} sur « {ch} » : lisible depuis une case de terre atteinte")
	# PNJ, examens, déclencheurs
	for n in ("cinnabar_island",):
		for q in pos_par_kind(plans[n], "pnj", "examen"):
			ch = plans[n].at(*q.cells[0])
			voisins = etats_voisins(n, q.cells)
			terre = {k for k in voisins if monde.dans(*k) and monde.genre(*k) == "terre"
				and k[1] not in monde.bloquees[n] | set(q.cells)}
			critere(bool(terre & cb), f"{n} {q.ident} {q.cells[0]} sur « {ch} » : joignable")
	# portes de la ville
	for nom in ("porte_labo", "porte_centre", "porte_boutique"):
		q = pc.positions[nom]
		etats = {("cinnabar_island", c) for c in q.cells}
		critere(etats <= cb and all(pc.at(*c) == "D" for c in q.cells),
			f"Cramois'Île {nom} {intervalle([c[0] for c in q.cells])},{q.cells[0][1]} : porte atteinte")
	# bâtiments
	def emprise(ch: str) -> tuple[int, int, int, int, int]:
		cs = pc.cells_of(ch)
		xs, ys = [c[0] for c in cs], [c[1] for c in cs]
		x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
		portes = [c for c in pc.cells_of("D") + pc.cells_of("X")
			if x0 <= c[0] <= x1 and y0 <= c[1] <= y1 + 1]
		compte = len(cs) + len(portes)
		if portes:
			y1 = max(y1, max(c[1] for c in portes))
		return x0, y0, x1 - x0 + 1, y1 - y0 + 1, compte
	for ch, (w, h), nom in (("C", (8, 7), "Centre"), ("O", (8, 7), "Boutique"),
			("L", (9, 6), "Labo"), ("M", (9, 6), "Manoir"), ("Z", (9, 6), "Arène")):
		x0, y0, ww, hh, compte = emprise(ch)
		critere((ww, hh) == (w, h) and compte == w * h,
			f"{nom} : {ww} × {hh} en ({x0}, {y0}), {compte} cases avec la porte (gabarit {w} × {h})")
	# Manoir : entrée effondrée, aucun warp ; Arène : porte fermée, case de recul
	critere(not pc.cells_of("D") or all(
		c not in {cc for q in pos_par_kind(pc, "warp") for cc in q.cells}
		for c in pc.positions["porte_arene"].cells), "Arène : la porte n'est pas un warp")
	manoir_cases = set(pc.cells_of("M")) | set(pc.cells_of("X"))
	warps_manoir = [q.ident for q in pos_par_kind(pc, "warp")
		if any(c in manoir_cases or (c[0], c[1] - 1) in manoir_cases for c in q.cells)]
	critere(not warps_manoir and not any(
		pc.at(c[0] + dx, c[1] + dy) == "D" for c in manoir_cases for dx, dy in DIRS
		if monde.dans("cinnabar_island", (c[0] + dx, c[1] + dy))),
		"Manoir : aucune porte ni warp (entrée effondrée, gravats X), P-20")
	g = sorted(pc.cells_of("X"))
	critere(g == [(9, 5), (10, 5)] and set(g) == set(pc.positions["examen_manoir"].cells),
		"gravats = case d'examen du Manoir (T-43)")
	porte = pc.positions["porte_arene"]
	recul = pc.positions["recul_arene"]
	critere(porte.kind == "declencheur" and all(pc.at(*c) == "D" for c in porte.cells)
		and all((c[0], c[1] + 1) in recul.cells for c in porte.cells)
		and all(pc.at(*c) == "." for c in recul.cells)
		and ("cinnabar_island", recul.cells[0]) in cb,
		"Arène : porte D fermée (déclencheur, aucun warp) ; case de recul d'une case au sud, praticable")
	critere(sorted(p.ident for p in pos_par_kind(pc, "pnj")) == ["fille", "homme"], "2 PNJ (T-44, T-45)")
	critere(sorted(p.ident for p in pos_par_kind(pc, "panneau")) == ["panneau_arene", "panneau_ville"],
		"2 panneaux (T-40, T-41)")
	zone = pc.positions["fille"].cells
	critere(len(zone) >= 6 and len({c[1] for c in zone}) == 1 and all(pc.at(*c) == "." for c in zone),
		f"Fille : zone de marche de {len(zone)} cases sur une rangée de sol")
	# écarts RB × 1,5 pour les autres positions (info)
	ecarts = []
	for n in EXTERIEURS:
		for q in plans[n].positions.values():
			if q.kind in ("dresseur",) or "rb" not in q.attrs:
				continue
			rb = tuple(int(v) for v in q.attrs["rb"].split(","))
			ex = (s(rb[0]), s(rb[1]))
			e = max(abs(q.cells[0][0] - ex[0]), abs(q.cells[0][1] - ex[1]))
			if e > 2:
				ecarts.append(f"{n} {q.ident} {q.cells[0]} (×1,5 : {ex}, écart {e})")
	print(f"  [info] positions non-Dresseurs à plus de 2 cases du ×1,5 strict : "
		f"{len(ecarts)}" + (" : " + " ; ".join(ecarts) if ecarts else ""))

	# ------------------------------------------------------------------ approche des Dresseurs
	print("== Approche des Dresseurs : aucun passage fermé")
	fermes: list[str] = []
	nb_test = 0
	for n in attendu_n:
		pl = plans[n]
		for q in pos_par_kind(pl, "dresseur"):
			vue = lignes_vue[(n, q.ident)]
			if not vue:
				continue
			c0 = q.cells[0]
			pied = q.attrs["mode"] == "pied"
			for i, v in enumerate(vue):
				mode_v = "surf" if monde.genre(n, v) == "eau" else "walk"
				if (n, v, mode_v) not in (reach_a | reach_b):
					continue
				# case d'arrêt : dernière case de la ligne praticable pour le Dresseur avant v
				arret = c0
				for u in vue[:i]:
					g = monde.genre(n, u)
					if (pied and g in ("terre", "rebord")) or (not pied and g == "eau"):
						arret = u
					else:
						break
				base = monde.atteint({(n, v, mode_v)})
				m2 = Monde(monde.plans)
				m2.bloquees = {k: set(vv) for k, vv in monde.bloquees.items()}
				m2.bloquees[n].discard(c0)
				m2.bloquees[n].add(arret)
				apres = m2.atteint({(n, v, mode_v)})
				nb_test += 1
				perdu = {k for k in cases_atteintes(base) - cases_atteintes(apres) if k != (n, arret)}
				if perdu:
					fermes.append(f"{n} {q.ident} vu en {v} → arrêt {arret} ferme {len(perdu)} cases")
	critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage ({nb_test} cas)"
		+ (f" : {fermes[:3]}" if fermes else ""))

	# ------------------------------------------------------------------ eau surfable hors liste
	print("== Eau surfable : seulement sur les cartes autorisées")
	fautes = []
	hors_perimetre = []
	for f in sorted(PLANS.glob("*.txt")):
		nom = f.stem
		if nom in EXTERIEURS:
			continue
		if nom.startswith("seafoam_"):
			hors_perimetre.append(nom)
			continue
		for ligne in f.read_text(encoding="utf-8").splitlines():
			mots = ligne.split("#", 1)[0].split()
			if mots and mots[0].startswith("PRATICABLES") and len(mots) > 1 and SURF in mots[1]:
				fautes.append(f"{nom} ({mots[0]} {mots[1]})")
	critere(not fautes, f"aucune carte hors liste n'a de « {SURF} » praticable "
		f"({len(list(PLANS.glob('*.txt')))} grilles lues)" + (f" : {fautes}" if fautes else ""))
	print(f"  [info] hors périmètre de ce contrôle (autre tâche) : "
		f"{', '.join(hors_perimetre) if hors_perimetre else 'aucune grille seafoam_* présente'}")
	for n in INTERIEURS:
		critere(SURF not in plans[n].praticables, f"{n} : « {SURF} » absent des cases praticables")

	# ------------------------------------------------------------------ intérieurs
	print("== Intérieurs : fermés, une seule porte vers l'extérieur")
	for n in INTERIEURS:
		pl = plans[n]
		w, h = pl.width, pl.height
		bord_ouvert = [c for c in ouvertes(pl, bord(pl, "N") + bord(pl, "S") + bord(pl, "O")
			+ bord(pl, "E"))]
		critere(not bord_ouvert, f"{n} : aucune case praticable sur le bord de la grille")
		mats = pl.cells_of("X")
		sorties = [q for q in pos_par_kind(pl, "warp") if q.ident == "sortie"]
		critere(len(sorties) == 1 and set(sorties[0].cells) == set(mats) and len(mats) == 3
			and all(c[1] == h - 2 for c in mats),
			f"{n} : un paillasson de 3 cases sur l'avant-dernière rangée, un seul warp de sortie")
		spawns = [q for q in pos_par_kind(pl, "spawn") if q.ident == "entree"]
		critere(len(spawns) == 1 and spawns[0].cells[0] in mats, f"{n} : spawn d'entrée sur le paillasson")
		portes = pl.cells_of("D")
		autres = [q for q in pos_par_kind(pl, "warp") if q.ident != "sortie"]
		attendu_portes = 3 * 2 if n == "cinnabar_labo_hall" else 0
		critere(len(portes) == attendu_portes and len(autres) == (3 if attendu_portes else 0)
			and set(portes) == {c for q in autres for c in q.cells},
			f"{n} : {len(autres)} porte(s) de salle ({len(portes)} cases), chacune un warp")
		# atteignabilité
		depart = [("n", mats[0], "walk")]
		m = Monde({"n": pl})
		m.bloquees["n"] |= set()
		milieu = sorted(mats)[1]
		reach = cases_atteintes(m.atteint({("n", (milieu[0], milieu[1] - 1), "walk")}))
		sol = {c for c in [(x, y) for y in range(h) for x in range(w)] if pl.at(*c) in pl.praticables}
		libres = sol - m.bloquees["n"]
		critere(libres <= {c for _, c in reach} | set(portes) | m.bloquees["n"],
			f"{n} : toutes les cases praticables sont atteintes depuis l'entrée")
		for q in pl.positions.values():
			if q.kind in ("pnj", "examen"):
				voisins = {(c[0] + d[0], c[1] + d[1]) for c in q.cells for d in DIRS}
				critere(bool(voisins & {c for _, c in reach}) and (q.kind == "examen"
					or all(pl.at(*c) in pl.praticables for c in q.cells)),
					f"{n} {q.ident} {q.cells[0]} : joignable"
					+ (f" (zone de {len(q.cells)} cases)" if len(q.cells) > 1 else ""))
		# deux positions bloquantes ne se superposent pas
		vus: dict[Case, str] = {}
		sup = []
		for q in pl.positions.values():
			if q.bloque:
				for c in q.cells:
					if c in vus:
						sup.append(f"{q.ident}/{vus[c]} en {c}")
					vus[c] = q.ident
		critere(not sup, f"{n} : aucune superposition de positions bloquantes"
			+ (f" : {sup}" if sup else ""))
	hall = plans["cinnabar_labo_hall"]
	cibles = {"porte_reunion": "cinnabar_labo_reunion", "porte_rd": "cinnabar_labo_rd",
		"porte_fossiles": "cinnabar_labo_fossiles"}
	for nom, salle in cibles.items():
		sp = {"cinnabar_labo_reunion": "from_reunion", "cinnabar_labo_rd": "from_rd",
			"cinnabar_labo_fossiles": "from_fossiles"}[salle]
		cp = hall.positions[nom].cells
		cs = hall.positions[sp].cells
		critere(len(cp) == len(cs) == 2 and all((c[0], c[1] + 1) in cs for c in cp),
			f"hall {nom} → {salle} : porte (2 cases) et spawn de retour juste au sud")
		critere(salle.split("_")[-1] in plans[salle].positions["sortie"].note,
			f"{salle} : la sortie renvoie au hall (« {plans[salle].positions['sortie'].note} »)")
	critere(hall.positions["sortie"].note.find("cinnabar_island") >= 0, "hall : la sortie renvoie à la ville")
	print("== Centre et Boutique : gabarits existants, pas de grille (comme Carmin et Azuria)")
	critere(not (PLANS / "cinnabar_centre.txt").exists() and not (PLANS / "cinnabar_boutique.txt").exists()
		and not (PLANS / "vermilion_pokecenter.txt").exists(),
		"aucune grille d'intérieur de Centre ou de Boutique dans tools/plans (convention des cartes précédentes)")
	return ok


def main() -> int:
	bon = verifier()
	print("\nTOUT EST CONFORME" if bon else "\nNON CONFORME")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
