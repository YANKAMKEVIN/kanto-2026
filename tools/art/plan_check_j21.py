#!/usr/bin/env python3
"""Vérifie les trois grilles du jalon 21 (lot 21.0, dossier 24 §6, §9, §10) par recherche de chemin.

Grilles : `tools/plans/pokemon_tower_7f.txt`, `route_12.txt` (Route 12 nord), `route_16.txt` (Route 16
est). Lecture par `plan_grille.lire` ; un pas = une case, 4 directions ; une porte (`D`) et un escalier
(`V`) mènent à une autre carte : on y entre, on ne les traverse pas — sauf les deux portes du poste de la
Route 12, reliées par l'intérieur (attribut `lie=`), qui forment un passage.

Voisines relues (fichier de `tools/plans/` s'il existe, sinon `git show <branche>:<fichier>` sur la
première branche qui l'a ; introuvable = échec, `--sans-voisines` les saute) : `pokemon_tower_6f`
(jalon 19), `lavanville` (J18), `route_11` (J17), `celadopole` (J20).

Critères :
  7F (20 × 18) : dimensions, bord, légende ; paire T67 avec le 6F (même case (9, 16), sens opposés,
    arrivée voisine) ; 3 Sbires Rocket sur les cases de RB, vues pleines (3 cases) ; INÉVITABLES : aucun
    chemin de l'arrivée à Fuji hors de leur vue, et ils se rencontrent dans l'ordre 1, 2, 3 ; Fuji
    atteignable ; aucun objet ; rien ne couvre l'arrivée ; tout le sol atteignable.
  Route 12 (39 × 102) : bords fermés sauf trois raccords (nord (21..23, 0) ↔ Lavanville (21..23, 35),
    ouest (0, 93..94) ↔ Route 11 (75, 14..15), sud fermé « À venir ») ; le poste est un passage
    obligatoire (sans lui, le sud est inatteignable) ; 4 Pêcheurs, vues, inévitabilité (1 oui, 2 à 4
    non) ; tout le ponton atteignable ; aucune herbe ; Ronflex reste sur la Route 11 (aucune case de la
    Route 12 ne lui est voisine : pas de repère face_ronflex).
  Route 16 (44 × 28) : bords fermés sauf (43, 21..23) ↔ Céladopole (0, 21..23) ; Ronflex 2 × 2 sans
    contournement (avec lui, ni goulet ni porte ; sans lui, tout est atteignable) ; porte du poste
    fermée (coming_soon) ; voie haute et arbre à Couper infranchissables ; ni herbe, ni Dresseur, ni
    objet, ni panneau.

Usage : python3 tools/art/plan_check_j21.py [pokemon_tower_7f|route_12|route_16 ...] [--sans-voisines]
        [--apercu]    (sans nom : les trois ; code 1 si un critère échoue)

Enregistrement dans `plan_check.py` (non fait ici : J17, J19 et J20 modifient les mêmes lignes ; à
appliquer à l'intégration, comme `_profil` du J20) :
    from plan_check_j21 import VERIFICATEURS as _J21 ; VERIFICATEURS.update(_J21)
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
S_PAR_PAS = 0.72  # pas mesuré sur S21 (plan_check_tour_pokemon.py)
SANS_VOISINES = "--sans-voisines" in sys.argv

# Branches où chercher une grille voisine absente de `tools/plans/` (première qui l'a).
REFS = {
	"pokemon_tower_6f": ["origin/jalon-19", "jalon-19", "origin/main", "main"],
	"lavanville": ["origin/docs/dossier-j18", "docs/dossier-j18", "origin/main", "main"],
	"route_11": ["origin/jalon-17", "jalon-17", "origin/main", "main"],
	"celadopole": ["docs/dossier-23-j20", "origin/docs/dossier-23-j20", "origin/main", "main"],
}


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


def voisine(nom: str) -> tuple[Plan | None, str]:
	"""Grille voisine : `tools/plans/<nom>.txt`, sinon la première branche connue qui l'a."""
	chemin = PLANS / f"{nom}.txt"
	if chemin.exists():
		return lire(chemin), f"tools/plans/{nom}.txt"
	for ref in REFS.get(nom, []):
		res = subprocess.run(["git", "-C", str(RACINE), "show", f"{ref}:tools/plans/{nom}.txt"],
			capture_output=True, text=True)
		if res.returncode == 0 and res.stdout.strip():
			with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
				f.write(res.stdout)
			try:
				return lire(f.name), f"{ref}:tools/plans/{nom}.txt"
			finally:
				Path(f.name).unlink(missing_ok=True)
	return None, ""


class Carte:
	"""Une grille et ses règles de déplacement."""

	def __init__(self, nom: str, plan: Plan | None = None) -> None:
		self.nom = nom
		self.plan = plan if plan is not None else lire(PLANS / f"{nom}.txt")
		p = self.plan
		self.largeur, self.hauteur = p.width, p.height
		self.pos = p.positions
		self.occupees: set[Case] = {c for q in self.pos.values() if q.bloque
			and q.kind not in ("decor", "repere") for c in q.cells}

	def car(self, c: Case) -> str:
		return self.plan.rows[c[1]][c[0]]

	def dans(self, c: Case) -> bool:
		return 0 <= c[0] < self.largeur and 0 <= c[1] < self.hauteur

	def libre(self, c: Case, occupees: set[Case] | None = None) -> bool:
		o = self.occupees if occupees is None else occupees
		return self.dans(c) and self.car(c) in self.plan.praticables and c not in o

	def cases(self, chars: str) -> list[Case]:
		return [(x, y) for y in range(self.hauteur) for x in range(self.largeur)
			if self.car((x, y)) in chars]

	def terminales(self) -> set[Case]:
		return {c for c in self.cases("DV")}

	def distances(self, departs: list[Case], interdites: set[Case] = frozenset(),
			occupees: set[Case] | None = None, portails: bool = True) -> dict[Case, int]:
		"""BFS ; une case D / V est atteinte mais jamais traversée, sauf une porte à `lie=` (poste
		de la Route 12) : y entrer ressort de l'autre porte, sur sa case de sortie (+ 1 pas)."""
		term = self.terminales()
		dist = {c: 0 for c in departs if c not in interdites}
		file = deque(dist)
		while file:
			c = file.popleft()
			suites: list[Case] = []
			if c in term and dist[c] > 0:
				q = self.porte_de(c)
				if portails and q is not None and "lie" in q.attrs:
					autre = self.pos[q.attrs["lie"]]
					suites = [s for s in self.sorties_de(autre.ident) if s not in dist]
					for s in suites:
						dist[s] = dist[c] + 1
						file.append(s)
				continue
			for dx, dy in DIRS:
				n = (c[0] + dx, c[1] + dy)
				if n in dist or n in interdites or not self.libre(n, occupees):
					continue
				dist[n] = dist[c] + 1
				file.append(n)
		return dist

	def porte_de(self, c: Case):
		for q in self.pos.values():
			if q.kind == "warp" and c in q.cells and "lie" in q.attrs:
				return q
		return None

	def sorties_de(self, porte: str) -> list[Case]:
		"""Cases d'apparition (`from_*`) de la porte : la rangée voisine, du côté route."""
		q = self.pos[porte]
		cle = "from_poste_nord" if porte.endswith("nord") else "from_poste_sud"
		return list(self.pos[cle].cells) if cle in self.pos else q.cells

	def vue(self, q) -> list[Case]:
		"""Cases vues par un Dresseur : la ligne s'arrête à la première case infranchissable ou
		occupée (TrainerRules.sight_distance)."""
		d = FACINGS[q.attrs["facing"]]
		autres = self.occupees - set(q.cells)
		cases: list[Case] = []
		for k in range(1, int(q.attrs["sight"]) + 1):
			c = (q.cells[0][0] + d[0] * k, q.cells[0][1] + d[1] * k)
			if not self.libre(c, autres):
				break
			cases.append(c)
		return cases

	def bord(self) -> dict[str, list[Case]]:
		"""Cases praticables de chaque bord de la carte."""
		L, H = self.largeur, self.hauteur
		bords = {"nord": [(x, 0) for x in range(L)], "sud": [(x, H - 1) for x in range(L)],
			"ouest": [(0, y) for y in range(H)], "est": [(L - 1, y) for y in range(H)]}
		return {k: [c for c in v if self.car(c) in self.plan.praticables] for k, v in bords.items()}


def voisins(c: Case) -> list[Case]:
	return [(c[0] + dx, c[1] + dy) for dx, dy in DIRS]


def contigu(cases: list[Case]) -> bool:
	s = set(cases)
	if not s:
		return False
	file = deque([next(iter(s))])
	vus = {file[0]}
	while file:
		c = file.popleft()
		for n in voisins(c):
			if n in s and n not in vus:
				vus.add(n)
				file.append(n)
	return vus == s


def dims_et_legende(r: Rapport, k: Carte, largeur: int, hauteur: int, legende: str,
		praticables: str) -> None:
	p = k.plan
	inconnus = {c for row in p.rows for c in row} - set(legende)
	r.critere(p.width == largeur and p.height == hauteur,
		f"{k.nom} : {p.width} × {p.height} (attendu {largeur} × {hauteur})")
	r.critere(not inconnus, f"{k.nom} : légende {sorted(set(legende))} ({sorted(inconnus) or 'ok'})")
	r.critere(set(p.praticables) == set(praticables), f"{k.nom} : praticables {sorted(p.praticables)}")


def natures(r: Rapport, k: Carte, regles: dict[str, str]) -> None:
	"""`regles` : genre de position → caractères permis. Aucune superposition de bloquants."""
	mauvais: list[str] = []
	for q in k.pos.values():
		permis = regles.get(q.kind)
		if permis is None:
			continue
		for c in q.cells:
			if k.car(c) not in permis:
				mauvais.append(f"{q.ident}{c}=« {k.car(c)} »")
	r.critere(not mauvais, f"{k.nom} : {len(k.pos)} positions sur la bonne nature {mauvais or ''}")
	vus: dict[Case, str] = {}
	doubles = []
	for q in k.pos.values():
		if q.kind in ("repere", "decor", "spawn", "warp"):
			continue
		for c in q.cells:
			if c in vus:
				doubles.append(f"{q.ident}/{vus[c]}{c}")
			vus[c] = q.ident
	r.critere(not doubles, f"{k.nom} : aucune superposition de personnages / panneaux {doubles or ''}")


def acces_cases(e: Carte, d: dict[Case, int]) -> list[Case]:
	"""Cases de la carte atteignables, plus les cases voisines d'un obstacle posé (personnages)."""
	return [c for c in d]


# --------------------------------------------------------------------------- 7F


def verifier_7f(r: Rapport, apercu: bool) -> None:
	k = Carte("pokemon_tower_7f")
	pos = k.pos
	r.titre("1. Dimensions, bord, légende")
	dims_et_legende(r, k, 20, 18, "#.TSV", ".V")
	bord = all(k.car((x, y)) == "#" for x in range(20) for y in (0, 17)) and \
		all(k.car((x, y)) == "#" for y in range(18) for x in (0, 19))
	r.critere(bord, "bord de carte entièrement mur (convention des étages)")
	r.critere(not k.plan.cells_of("U") and not k.plan.cells_of("Z"),
		"pas d'escalier qui monte ni de zone purifiée au 7F")
	natures(r, k, {"escalier": "V", "spawn": ".", "dresseur": ".", "pnj": ".", "repere": ".S"})

	r.titre("2. Escalier T67 et arrivée (paire avec le 6F)")
	esc = pos["escalier_bas"]
	arr = pos["arrivee_T67"]
	ok = (len(esc.cells) == 1 and k.car(esc.cells[0]) == "V" and esc.attrs.get("sens") == "descend"
		and esc.attrs.get("paire") == "T67" and esc.attrs.get("vers") == "pokemon_tower_6f")
	r.critere(ok, f"escalier V {esc.cells[0]} : sens=descend, paire=T67, vers=pokemon_tower_6f")
	r.critere(len(k.cases("V")) == 1 and k.cases("V")[0] == (9, 16),
		"un seul escalier, en (9, 16) (RB : warp 9, 16 → 6F)")
	a = arr.cells[0]
	r.critere(arr.attrs.get("paire") == "T67" and arr.attrs.get("facing") == "right"
		and abs(a[0] - esc.cells[0][0]) + abs(a[1] - esc.cells[0][1]) == 1 and k.car(a) == "."
		and k.libre(a), f"arrivée T67 {a} voisine de l'escalier, sol libre, tournée → (loin de l'escalier)")
	p6, src = voisine("pokemon_tower_6f")
	if p6 is None:
		r.critere(SANS_VOISINES, "grille du 6F introuvable (--sans-voisines pour passer)")
	else:
		e6 = Carte("pokemon_tower_6f", p6)
		u = e6.pos.get("escalier_7f")
		r.critere(u is not None and u.cells == esc.cells and u.attrs.get("paire") == "T67"
			and u.attrs.get("sens") == "monte" and u.attrs.get("vers") == "pokemon_tower_7f"
			and e6.car(u.cells[0]) == "U",
			f"6F ({src}) : escalier_7f U en {u.cells[0] if u else '?'} = notre V, paire T67, sens monte")
		v6 = (a[0], a[1])
		r.critere(e6.car(v6) == "." and e6.libre(v6, set()),
			f"6F : la case {v6} (arrivée du 7F, voisine du U) est un sol libre")
		trig = e6.pos.get("declencheur_spectre")
		absente = "arrivee_T67" not in e6.pos
		r.info(f"6F : arrivee_T67 {'absente : à poser' if absente else 'déjà posée'} en {v6}, tournée →, "
			f"case du déclencheur du SPECTRE {trig.cells[0] if trig else '?'} (inactif : "
			"ghost_marowak_calmed)")

	r.titre("3. Sbires Rocket : cases RB, vues, ordre")
	attendu = {"tower_rocket_1": ((9, 11), "right"), "tower_rocket_2": ((12, 9), "left"),
		"tower_rocket_3": ((9, 7), "right")}
	rockets = {i: pos[i] for i in attendu if i in pos}
	r.critere(set(rockets) == set(attendu) and sum(1 for q in pos.values() if q.kind == "dresseur") == 3,
		"3 Sbires tower_rocket_1..3, aucun autre Dresseur")
	vues: dict[str, list[Case]] = {}
	for i, (cell, facing) in attendu.items():
		q = rockets[i]
		vues[i] = k.vue(q)
		ok = (q.cells == [cell] and q.attrs.get("facing") == facing and q.attrs.get("sight") == "3"
			and q.attrs.get("trainer") == i and q.attrs.get("inevitable") == "oui" and q.bloque)
		r.critere(ok, f"{i} {q.cells[0]} facing={q.attrs.get('facing')} sight={q.attrs.get('sight')} "
			f"(RB {cell} {facing})")
		ligne = [(x, cell[1]) for x in range(20) if k.car((x, cell[1])) == "."]
		complet = set(ligne) == set(vues[i]) | {cell}
		r.critere(len(vues[i]) == 3 and complet,
			f"{i} : vue {vues[i]} = TOUTE sa rangée (3 cases libres + sa case)")
	interdits = {esc.cells[0], a} | set(pos["fuji"].cells)
	r.critere(not any(set(v) & interdits for v in vues.values()),
		"aucune vue ne couvre l'arrivée, l'escalier ni Fuji")
	r.critere(all(abs(attendu[i][0][1] - attendu[j][0][1]) >= 2 for i in attendu for j in attendu if i < j),
		"deux Sbires ne partagent jamais une rangée (au moins une rangée libre entre eux)")

	r.titre("4. Fuji et inévitabilité")
	fuji = pos["fuji"]
	fc = fuji.cells[0]
	r.critere(fc == (10, 3) and fuji.kind == "pnj" and fuji.attrs.get("unless") == "fuji_rescued"
		and fuji.attrs.get("facing") == "up" and fuji.bloque,
		f"Fuji pnj en {fc} (RB (10, 3)), facing=up [D], unless=fuji_rescued")
	autel = set(pos["repere_autel"].cells)
	r.critere(autel == {(10, 2), (11, 2)} and all(k.car(c) == "S" for c in autel)
		and all(abs(c[0] - fc[0]) + abs(c[1] - fc[1]) <= 2 for c in autel),
		"autel S (10..11, 2) juste devant Fuji")
	depart = a
	d = k.distances([depart])
	lectures = [c for c in voisins(fc) if k.libre(c) and c in d]
	r.critere(len(lectures) >= 2, f"Fuji se lit depuis {sorted(lectures)} (atteintes avec les 3 Sbires en place)")
	sol = k.cases(".")
	manque = [c for c in sol if c not in d and c not in k.occupees]
	r.critere(not manque, f"tout le sol atteignable depuis {depart} ({len(sol)} cases) {manque or ''}")
	base = {c: d[c] for c in lectures}
	r.info(f"chemin direct : arrivée → lecture de Fuji en {min(base.values())} pas")
	# Inévitables : bloquer la vue + la case d'un Sbire coupe l'accès à Fuji.
	for i, q in rockets.items():
		interdit = set(vues[i]) | set(q.cells)
		sans = k.distances([depart], interdit)
		coupe = not any(c in sans for c in lectures)
		r.critere(coupe, f"{i} INÉVITABLE : aucun chemin vers Fuji hors de sa vue {vues[i]}")
	# Ordre de rencontre : le Sbire i+1 n'est atteignable qu'en traversant la vue du Sbire i.
	ordre = ["tower_rocket_1", "tower_rocket_2", "tower_rocket_3"]
	for n in range(1, 3):
		avant = set()
		for i in ordre[:n]:
			avant |= set(vues[i]) | set(rockets[i].cells)
		sans = k.distances([depart], avant)
		suivants = vues[ordre[n]] + list(rockets[ordre[n]].cells)
		r.critere(not any(c in sans for c in suivants),
			f"ordre : la vue de {ordre[n]} n'est atteignable qu'après {ordre[n - 1]}")
	# Chaque Sbire vaincu reste debout : la rangée garde 3 cases libres (le passage ne se ferme pas).
	apres = k.distances([depart])
	r.critere(all(any((x, attendu[i][0][1]) in apres for x in range(20)) for i in attendu),
		"chaque rangée de Sbire reste traversable (le Sbire vaincu reste à sa place)")

	r.titre("5. Aucun objet, rencontres")
	objets = [q.ident for q in pos.values() if q.kind in ("objet_visible", "cache", "objet_don")
		or "item" in q.attrs]
	r.critere(not objets, f"aucun objet au sol ni caché (RB : aucun) {objets or ''}")
	r.critere(not k.plan.cells_of("Z"), f"terrain `floor` : {len(sol)} cases de rencontre (taux 15), aucune zone calme")

	r.titre("6. Durée de traversée (information)")
	pas = min(base.values())
	r.info(f"{pas} pas arrivée → Fuji ≈ {pas * S_PAR_PAS:.0f} s de marche + 3 combats de Sbires")
	if apercu:
		apercu_carte(k, vues)


# --------------------------------------------------------------------------- Route 12

R12 = {
	"dims": (39, 102), "legende": "TwR=.PDi", "praticables": ".=D",
	"nord": [(21, 0), (22, 0), (23, 0)], "ouest": [(0, 93), (0, 94)],
	"sud": [(24, 101), (25, 101), (26, 101)],
}
FISHERS = {  # id → (case RB × 1,5 du plan, facing, inévitable)
	"route_12_fisher_1": ((30, 47), "left", True), "route_12_fisher_2": ((17, 59), "up", False),
	"route_12_fisher_3": ((27, 60), "left", False), "route_12_fisher_4": ((23, 78), "right", False),
}


def verifier_route_12(r: Rapport, apercu: bool) -> None:
	k = Carte("route_12")
	pos = k.pos
	r.titre("1. Dimensions, légende, bords")
	dims_et_legende(r, k, 39, 102, R12["legende"], R12["praticables"])
	b = k.bord()
	r.critere(b["est"] == [], "bord est entièrement fermé")
	r.critere(b["nord"] == R12["nord"], f"bord nord : seul raccord {b['nord']} (Lavanville)")
	r.critere(b["ouest"] == R12["ouest"], f"bord ouest : seul raccord {b['ouest']} (Route 11)")
	r.critere(b["sud"] == R12["sud"], f"bord sud : seul passage {b['sud']} (fermé « À venir »)")
	natures(r, k, {"warp": ".=D", "spawn": ".=", "dresseur": "=", "panneau": "=.", "repere": ".=",
		"decor": "PDi"})
	r.critere(not k.plan.cells_of("h") and not any(q.kind == "herbes" for q in pos.values()),
		"aucune herbe haute (RB : aucune sur ce tronçon) : pas de rencontre sauvage")
	r.critere(not any(q.kind in ("objet_visible", "cache") for q in pos.values()),
		"aucun objet (la CT Jackpot de RB (14, 35) n'est pas retenue par le dossier)")
	r.critere(len(k.cases("D")) == 6, "poste : 6 cases de porte « D » (3 au nord, 3 au sud)")

	r.titre("2. Raccords avec les cartes voisines")
	wn, ws, wo, wsud = (pos[n] for n in ("warp_nord", "from_lavender", "warp_ouest", "warp_sud"))
	r.critere(wn.cells == [(21, 0), (22, 0), (23, 0)] and ws.cells == wn.cells
		and ws.attrs.get("facing") == "down", "nord : warp et arrivée (21..23, 0), tournée ↓")
	r.critere(wo.cells == [(0, 93), (0, 94)] and pos["from_route_11"].cells == wo.cells
		and pos["from_route_11"].attrs.get("facing") == "right",
		"ouest : warp et arrivée (0, 93..94), tournée →")
	r.critere(wsud.cells == [(24, 101), (25, 101), (26, 101)] and wsud.attrs.get("coming_soon")
		== "route_12_sud", "sud : bord fermé coming_soon=route_12_sud")
	lav, src = voisine("lavanville")
	if lav is None:
		r.critere(SANS_VOISINES, "Lavanville introuvable (--sans-voisines pour passer)")
	else:
		L = Carte("lavanville", lav)
		w = L.pos["warp_sud"]
		avenue = [(x, 34) for x in (21, 22, 23)]
		r.critere(w.cells == [(21, 35), (22, 35), (23, 35)] and w.attrs.get("coming_soon") == "route_12",
			f"Lavanville ({src}) : warp_sud {w.cells} coming_soon=route_12 → devient notre raccord nord")
		r.critere(all(L.car(c) == "p" for c in avenue + w.cells),
			"Lavanville : avenue (21..23, 34) et bord (21..23, 35) praticables (pavé), 3 cases")
		r.critere(L.pos["from_route_12"].cells == avenue,
			"Lavanville : from_route_12 attendu en (21..23, 34) = rangée juste au nord du raccord")
		r.critere(L.largeur == 44 and L.hauteur == 36 and w.cells[0][1] == L.hauteur - 1,
			"Lavanville 44 × 36 : le bord sud est bien la rangée 35")
		r.critere(len(w.cells) == len(wn.cells) and [c[0] for c in w.cells] == [c[0] for c in wn.cells],
			"mêmes colonnes (21..23) des deux côtés, aucun décalage")
	r11, src = voisine("route_11")
	if r11 is None:
		r.critere(SANS_VOISINES, "Route 11 introuvable (--sans-voisines pour passer)")
	else:
		K = Carte("route_11", r11)
		e = K.pos["raccord_est"]
		ron = K.pos["ronflex"]
		r.critere(e.cells == [(75, 14), (75, 15)] and e.attrs.get("role") == "route_12",
			f"Route 11 ({src}) : raccord_est {e.cells} role=route_12 ↔ notre bord ouest (2 rangées)")
		r.critere(K.largeur == 76 and all(K.car((x, y)) == "=" for x in range(68, 76) for y in (14, 15)),
			"Route 11 : (68..75, 14..15) praticables (rive est), accessibles depuis le raccord")
		r.critere(ron.cells == [(66, 14), (67, 14), (66, 15), (67, 15)] and ron.bloque,
			f"Route 11 : Ronflex RESTE en {ron.cells[0]}..{ron.cells[-1]} (2 × 2, bloquant)")
		r.critere(len(e.cells) == len(wo.cells), "2 rangées de chaque côté")
		proche = [c for c in k.cases(".=D") if min(abs(c[0] + 76 - rc[0]) + abs(c[1] - 93 + 14 - rc[1])
			for rc in ron.cells) <= 1]
		r.critere(not proche and not any(q.attrs.get("role") == "face_ronflex" for q in pos.values()),
			"aucune case de la Route 12 voisine de Ronflex : pas de repère face_ronflex ici "
			"(on lui parle depuis la Route 11, (68, 14..15))")
		r.info("Ronflex n'est atteignable que par la carte de la Route 11 : de la Route 12, 8 cases de "
			"chaussée (Route 11 (68..75, 14..15)) puis (68, 14..15)")

	r.titre("3. Accessibilité et poste traversant")
	for n in ("porte_poste_nord", "porte_poste_sud"):
		q = pos[n]
		r.critere(q.kind == "warp" and all(k.car(c) == "D" for c in q.cells) and len(q.cells) == 3
			and q.attrs.get("lie") in pos and pos[q.attrs["lie"]].attrs.get("lie") == n,
			f"{n} {q.cells} : 3 cases D, reliée à {q.attrs.get('lie')} (symétrique)")
	nord, sud = pos["porte_poste_nord"].cells, pos["porte_poste_sud"].cells
	r.critere(set(nord) | set(sud) == set(k.cases("D")), "les 6 cases D sont exactement les deux portes")
	r.critere(pos["from_poste_nord"].cells == [(x, 23) for x in (24, 25, 26)]
		and pos["from_poste_sud"].cells == [(x, 33) for x in (24, 25, 26)],
		"sorties du poste : (24..26, 23) au nord, (24..26, 33) au sud, juste devant les portes")
	depart = pos["from_lavender"].cells[0]
	d = k.distances([depart])
	sol = k.cases(".=")
	manque = [c for c in sol if c not in d and c not in k.occupees]
	r.critere(not manque, f"tout le ponton atteignable depuis {depart} ({len(sol)} cases, le plus loin "
		f"à {max(d.values())} pas) {manque[:6] or ''}")
	sans_poste = k.distances([depart], portails=False)
	croisement = [(x, y) for x in (24, 25, 26) for y in (93, 94)]
	r.critere(not any(c in sans_poste for c in croisement + [(25, 101)] + [(0, 93)]),
		"sans traverser le poste, ni le croisement, ni le raccord ouest, ni le bord sud ne sont atteints")
	r.critere(all(c in d for c in croisement) and (0, 93) in d and (0, 94) in d and (25, 101) in d,
		"par le poste : croisement, raccord ouest (0, 93..94) et bord sud (24..26, 101) atteints")
	arr_ouest = k.distances([pos["from_route_11"].cells[0]])
	r.critere(depart in arr_ouest and croisement[0] in arr_ouest,
		"depuis la Route 11, on rejoint le croisement puis Lavanville (retour par le poste)")
	r.critere(len({c for c in k.cases(".=") if c in d and c[1] < 24}) > 0 and all(
		any(c in d for c in voisins(q.cells[0])) for q in pos.values() if q.kind in ("panneau", "dresseur")),
		"panneaux et Pêcheurs sont lus depuis une case atteignable")
	for n, q in pos.items():
		if q.kind == "panneau":
			lecture = {"panneau_route_12": (28, 19), "panneau_ponton": (25, 96)}[n]
			r.critere(lecture in d and abs(lecture[0] - q.cells[0][0]) + abs(lecture[1] - q.cells[0][1]) == 1,
				f"{n} {q.cells[0]} lu depuis {lecture}")
	but = (25, 93)
	r.info(f"Lavanville → poste (nord) {d[nord[1]]} pas ; → croisement {d[but]} pas ; → bord sud "
		f"{d[(25, 101)]} pas ; croisement → raccord Route 11 {arr_ouest[but]} pas")

	r.titre("4. Pêcheurs : cases, vues, inévitabilité")
	numeros = list(FISHERS)
	premier_pas = {}
	for i, (cell, facing, inev) in FISHERS.items():
		q = pos[i]
		v = k.vue(q)
		ok = (q.cells == [cell] and q.attrs.get("trainer") == i and q.attrs.get("facing") == facing
			and q.attrs.get("sight") == "6" and q.attrs.get("inevitable") == ("oui" if inev else "non")
			and q.bloque and k.car(cell) in "=")
		r.critere(ok, f"{i} {cell} facing={facing} sight=6 inevitable={q.attrs.get('inevitable')}")
		r.critere(len(v) >= 3, f"{i} : vue effective {len(v)} case(s) {v[0]}..{v[-1]}" if v else f"{i} : aucune vue")
		proteges = set(nord) | set(sud) | {c for n2 in ("from_poste_nord", "from_poste_sud", "from_lavender")
			for c in pos[n2].cells}
		r.critere(not (set(v) & proteges), f"{i} : sa vue ne couvre ni porte, ni sortie du poste, ni arrivée")
		# Inévitable = couper vue + case sépare Lavanville du croisement.
		sans = k.distances([depart], set(v) | set(q.cells))
		passe = any(c in sans for c in croisement)
		r.critere(passe != inev,
			f"{i} {'INÉVITABLE' if inev else 'ÉVITABLE'} : "
			f"{'aucun chemin' if inev else 'un chemin existe'} hors de sa vue jusqu'au croisement")
		# Évitable : on évite aussi TOUS les autres en même temps ?
		premier_pas[i] = min((d[c] for c in v if c in d), default=0)
	tous = set()
	for i in numeros[1:]:
		tous |= set(k.vue(pos[i])) | set(pos[i].cells)
	sans_tous = k.distances([depart], tous)
	r.critere(any(c in sans_tous for c in croisement), "une route évite les Pêcheurs 2, 3 et 4 à la fois")
	r.critere(list(premier_pas.values()) == sorted(premier_pas.values()),
		f"ordre de rencontre 1, 2, 3, 4 : première case vue à {list(premier_pas.values())} pas de Lavanville")

	r.titre("5. Durée de traversée (information)")
	pas = d[but]
	r.info(f"Lavanville → croisement : {pas} pas ≈ {pas * S_PAR_PAS / 60:.1f} min de marche, hors combats "
		"(4 Pêcheurs : 1 inévitable) et hors poste")
	if apercu:
		vues = {i: k.vue(pos[i]) for i in FISHERS}
		apercu_carte(k, vues)


# --------------------------------------------------------------------------- Route 16


def verifier_route_16(r: Rapport, apercu: bool) -> None:
	k = Carte("route_16")
	pos = k.pos
	r.titre("1. Dimensions, légende, bords")
	dims_et_legende(r, k, 44, 28, "TcRYWP=D", "=D")
	b = k.bord()
	est = [(43, 21), (43, 22), (43, 23)]
	r.critere(b["est"] == est and not b["nord"] and not b["sud"] and not b["ouest"],
		f"seul bord praticable : l'est {b['est']} (raccord Céladopole)")
	natures(r, k, {"warp": "=D", "spawn": "=", "pnj": "=", "repere": "=", "decor": "PYW"})
	interdits = [q.ident for q in pos.values() if q.kind in ("dresseur", "objet_visible", "cache",
		"panneau", "herbes", "examen")]
	r.critere(not interdits and not k.plan.cells_of("h"),
		f"aucun Dresseur, objet, panneau, examen ni herbe (RB : voie haute seule) {interdits or ''}")
	r.critere(pos["warp_est"].cells == est and pos["from_celadon"].cells == est
		and pos["from_celadon"].attrs.get("facing") == "left",
		"warp et arrivée (43, 21..23), tournée ←")

	r.titre("2. Raccord avec Céladopole")
	cel, src = voisine("celadopole")
	if cel is None:
		r.critere(SANS_VOISINES, "Céladopole introuvable (--sans-voisines pour passer)")
	else:
		C = Carte("celadopole", cel)
		passage = [(x, y) for x in range(4) for y in (21, 22, 23)]
		ouvert = all(C.car(c) == "p" for c in passage)
		if ouvert:
			w = C.pos.get("warp_ouest")
			r.critere(w is not None and w.cells == [(0, 21), (0, 22), (0, 23)]
				and w.attrs.get("to") == "route_16" and "obstacle_ouest" not in C.pos,
				f"Céladopole ({src}) : passage DÉJÀ ouvert, warp_ouest vers route_16, examen supprimé")
		else:
			r.critere(all(C.car(c) in "sT" for c in passage) and "obstacle_ouest" in C.pos,
				f"Céladopole ({src}) : les 12 cases (0..3, 21..23) sont encore haie « T » (x 2..3) et "
				"talus « s » (x 0..1) : À OUVRIR (en « p ») au lot 21.A")
			r.critere(C.pos["obstacle_ouest"].cells == [(3, 22)] and "warp_ouest" not in C.pos,
				"Céladopole : examen obstacle_ouest (3, 22) à SUPPRIMER ; warp_ouest et from_route_16 à créer")
		r.critere(all(C.car((4, y)) == "p" for y in (21, 22, 23)),
			"Céladopole : la case (4, 21..23) devant le passage est un pavé de l'avenue (3 rangées)")
		r.critere(all(C.car((x, y)) in "sT" for x in range(4) for y in (20, 24)),
			"Céladopole : les rangées 20 et 24 (haie, talus) restent fermées de chaque côté du passage")
		r.critere(C.car((4, 20)) == "p" and C.car((4, 24)) == ".",
			"Céladopole : l'avenue fait 5 rangées (20..24) en x 4 et se resserre à 3 au passage, comme à l'est")

	r.titre("3. Ronflex : goulet sans contournement")
	ron = pos["ronflex_16"]
	cases = set(ron.cells)
	r.critere(cases == {(24, 22), (25, 22), (24, 23), (25, 23)} and ron.kind == "pnj" and ron.bloque
		and ron.attrs.get("unless") == "snorlax_route_16_done" and ron.attrs.get("role") == "R1",
		"ronflex_16 : pnj 2 × 2 en (24..25, 22..23), unless=snorlax_route_16_done (dossier §9.4)")
	for x in (24, 25):
		col = [y for y in range(28) if k.car((x, y)) in "=D"]
		r.critere(col == [22, 23], f"colonne x = {x} : seules cases praticables {col} = les 2 rangées de Ronflex "
			"(goulet 2 cases, il le ferme en entier)")
	depart = pos["from_celadon"].cells[0]
	d = k.distances([depart])
	porte = pos["poste_route_16"]
	r.critere(not any(c in d for c in porte.cells) and (23, 22) not in d,
		"avec Ronflex : la porte du poste et le goulet derrière lui sont INATTEIGNABLES (aucun contournement)")
	faces = pos["face_ronflex"].cells
	r.critere(all(c in d for c in faces) and faces == [(26, 22), (26, 23)],
		f"face_ronflex {faces} atteint depuis le raccord ({d.get((26, 22))} pas)")
	libre = k.distances([depart], occupees=k.occupees - cases)
	sol = k.cases("=D")
	manque = [c for c in sol if c not in libre and c not in k.occupees]
	r.critere(not manque, f"Ronflex parti : tout le chemin atteignable ({len(sol)} cases) {manque or ''}")
	r.critere(all(c in libre for c in porte.cells), "Ronflex parti : la porte du poste est atteinte "
		f"({libre[porte.cells[0]]} pas)")
	r.critere(len(d) < len(libre) and max(d, key=d.get)[0] >= 26, "Ronflex coupe la voie en deux : "
		f"{len(d)} cases avant lui, {len(libre) - len(d)} après")

	r.titre("4. Façade du poste, voie haute, arbre à Couper")
	r.critere(porte.kind == "warp" and porte.attrs.get("coming_soon") == "route_16_poste"
		and porte.cells == [(15, 20), (16, 20)] and all(k.car(c) == "D" for c in porte.cells),
		"porte du poste (15..16, 20) : D × 2, coming_soon=route_16_poste (« À venir »), repère poste_route_16")
	parvis = pos["parvis_poste"].cells
	r.critere(parvis == [(15, 21), (16, 21)] and all(c in libre for c in parvis),
		"parvis (15..16, 21) : case de lecture de la porte, atteinte")
	r.critere(len(k.cases("D")) == 2, "une seule porte dans la carte")
	façade = [(x, y) for x in range(10, 22) for y in range(13, 20)]
	r.critere(all(k.car(c) == "P" for c in façade) and k.car((10, 20)) == "P" and k.car((21, 20)) == "P",
		"façade P : emprise 12 × 8 (x 10..21, y 13..20), porte dans la rangée du bas")
	haut = set(pos["voie_haute"].cells)
	r.critere(haut == {c for c in k.cases("Y")} - {(38, 17), (39, 17), (38, 18), (39, 18)}
		and not any(k.car(c) in "=D" for c in haut), "voie haute (26..42, 9..16) : décor, aucune case praticable")
	w = set(pos["arbre_coupe_decor"].cells)
	r.critere(w == set(k.cases("W")) == {(38, 19), (39, 19), (38, 20), (39, 20)} and k.car((38, 21)) == "="
		and not any(q.kind == "examen" or q.attrs.get("condition") for q in pos.values()),
		"arbre à Couper (38..39, 19..20) : 2 × 2 en décor, ni examen ni condition de Coupe (CS Vol hors jalon)")
	atteintes = set(libre)
	r.critere(not any(c in atteintes for c in k.cases("Y") + k.cases("W")),
		"jamais d'accès à la voie haute ni à l'arbre")

	r.titre("5. Durée de traversée (information)")
	r.info(f"raccord → Ronflex {d[(26, 22)]} pas ; raccord → porte du poste {libre[porte.cells[0]]} pas "
		f"≈ {libre[porte.cells[0]] * S_PAR_PAS:.0f} s de marche")
	if apercu:
		apercu_carte(k, {})


def apercu_carte(k: Carte, vues: dict[str, list[Case]]) -> None:
	print(f"\n=== {k.nom} ({k.largeur} × {k.hauteur}) ===")
	grille = [list(row) for row in k.plan.rows]
	for v in vues.values():
		for c in v:
			if grille[c[1]][c[0]] in ".=":
				grille[c[1]][c[0]] = "~"
	sym = {"dresseur": "E", "pnj": "N", "spawn": "a", "panneau": "i"}
	for q in k.pos.values():
		s = sym.get(q.kind)
		if s is None:
			continue
		for c in q.cells:
			if s != "a" or grille[c[1]][c[0]] in ".=":
				grille[c[1]][c[0]] = s
	for y, row in enumerate(grille):
		print(f"{y:3d} " + "".join(row))
	print("    ~ vue d'un Dresseur  E Dresseur  N PNJ  a arrivée  i panneau")


VERIFICATEURS = {}
PROFILS = {"pokemon_tower_7f": verifier_7f, "route_12": verifier_route_12, "route_16": verifier_route_16}


def _enveloppe(nom: str):
	def verifier(chemin: Path | None = None) -> bool:
		r = Rapport()
		print(f"\n##### {nom}")
		PROFILS[nom](r, "--apercu" in sys.argv)
		print("\n" + ("OK" if r.ok else "ÉCHEC"))
		return r.ok
	return verifier


VERIFICATEURS.update({n: _enveloppe(n) for n in PROFILS})


def main() -> int:
	noms = [a for a in sys.argv[1:] if not a.startswith("--")] or list(PROFILS)
	ok = True
	for nom in noms:
		nom = Path(nom).stem
		if nom not in PROFILS:
			print(f"{nom} : aucune règle connue (attendu : {', '.join(PROFILS)})")
			ok = False
			continue
		ok &= VERIFICATEURS[nom]()
	print("\n" + ("TOUT EST CONFORME" if ok else "NON CONFORME"))
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
