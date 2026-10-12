#!/usr/bin/env python3
"""Vérifie Azuria « après J14 » : variante `J14` de `tools/plans/azuria.txt` (jalon 14 T20a).

Référence : dossier 17 §3.3, §6, §14 ; docs/tech/jalon-14.md §1.3 (table « Azuria : changements
du J14 ») et §2.12. La grille de base (J13, validée) n'est pas touchée : elle reste contrôlée par
`plan_check_azuria.py` ; ce contrôle lit la variante (`lire(chemin, "J14")`) et la compare à la
base. Déplacements de `plan_check_azuria.Carte` (portes terminales).

États évalués (conditions `if=` / `unless=` des positions, voir l'en-tête de la variante) :
  E0 {} → E1 {spotted} → E2 {spotted, beaten} → E3 {spotted, beaten, south_guard_left}.
Dans un état, une bande de déclenchement **active** est terminale (on y entre, la scène part :
on ne la dépasse pas dans cet état) ; c'est ce qui borne les cases où le joueur peut se trouver
(et donc sauvegarder) dans chaque état.

Critères :
  1. Base intacte : la variante ne change QUE les cases de la table du §1.3 ; identifiants stables
     (porte_cambriolee, trou_cloture, barriere_sud, h4_policier) aux cases du J13.
  2. Jardin : 14 cases (pot compris) praticables sauf le pot ; seul accès par la clôture arrachée
     (6, 2..3), elle-même atteignable depuis la rue.
  3. Poursuite : la bande (7, 2..3) coupe la rue du jardin (inévitable) ; le Rocket (13, 2) a un
     chemin jusqu'à son arrêt (21, 3) sans passer par la case du joueur.
  4. Impasse : 2 rangées, ≥ 6 cases de long, seul accès par le trou (14, 3), fermée à l'est ; trou
     examinable depuis (13, 3) tourné →.
  5. Combat : la bande couvre TOUTE la largeur de l'impasse (chaque rangée) et la coupe en deux ;
     arrêt du Rocket à l'est de la bande, tourné ←, aligné sur une rangée de la bande ; son
     approche (case voisine du joueur) ne ferme aucun passage et son départ vers le trou existe.
  6. Aucune case coincée : pour tout état Ei et tout état suivant Ej, chaque case où le joueur
     peut être en Ei est libre en Ej et relie l'entrée ouest ; une position qui apparaît en Ej ne
     tombe jamais sur une case possible en Ei (le point d'arrêt du Rocket n'apparaît qu'en E1, au
     fond, que le joueur n'atteint pas en E0) ; aucun décor n'apparaît sur le jardin ou l'impasse.
  7. Sortie sud : couloir de 3 ; en E0–E2 le policier et les barrières ferment toute la rangée
     (aucun passage), en E3 le bord sud est libre ; warp et spawns `from_route_5` sur les 3 cases
     du bord ; bande du sud sur toute la largeur du couloir ; seuls bords ouverts : ouest, nord,
     sud (Route 9 fermée).
  8. Maison : porte praticable avec warp, recouverte par le ruban jusqu'à la victoire, entrée
     possible ensuite ; policier H4 présent avant, absent après.
  9. Connexité en E3 : toutes les cases praticables atteignables depuis l'entrée ouest.

Usage : python3 tools/art/plan_check_azuria_j14.py [azuria.txt]   (code 1 si un critère échoue)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS, INF  # noqa: E402
from plan_check_azuria import Carte, Rapport, _decale, _libres_du_bord, _nom  # noqa: E402
from plan_grille import Plan, Position, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
VARIANTE = "J14"
Case = tuple[int, int]

SPOTTED = "cerulean_rocket_spotted"
BEATEN = "cerulean_rocket_beaten"
LEFT = "cerulean_south_guard_left"
ETATS: list[tuple[str, frozenset[str]]] = [
	("E0 avant", frozenset()),
	("E1 repéré", frozenset({SPOTTED})),
	("E2 battu", frozenset({SPOTTED, BEATEN})),
	("E3 sud ouvert", frozenset({SPOTTED, BEATEN, LEFT})),
]
# Table du §1.3 : les seules cases que la variante change.
JARDIN = {(x, y) for x in range(7, 14) for y in (2, 3)}
CLOTURE_OUEST = {(6, 2), (6, 3)}
TROU: Case = (14, 3)
IMPASSE = {(x, y) for x in range(15, 22) for y in (2, 3)}
PORTE: Case = (10, 9)
SUD = {(x, y) for x in range(31, 34) for y in (38, 39, 40)}
SUD_BORDS = {(x, y) for x in (30, 34) for y in (38, 39)}
CHANGEES = JARDIN | CLOTURE_OUEST | {TROU} | IMPASSE | {PORTE} | SUD | SUD_BORDS
STABLES = ("porte_cambriolee", "trou_cloture", "barriere_sud", "h4_policier")
LONGUEUR_MIN = 6
FACINGS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}


def _liste(p: Position, cle: str) -> set[str]:
	return {f for f in p.attrs.get(cle, "").split(",") if f}


def present(p: Position, drapeaux: frozenset[str]) -> bool:
	"""Vrai si la position existe avec ces drapeaux (`if=` tous levés, `unless=` aucun)."""
	return _liste(p, "if") <= drapeaux and not (_liste(p, "unless") & drapeaux)


def conditionnelle(p: Position) -> bool:
	return bool(_liste(p, "if") or _liste(p, "unless"))


class CarteEtat(Carte):
	"""`Carte` dont les cases bloquées sont données telles quelles (la `Carte` de base ajoute
	toutes les positions `bloque`, conditionnelles comprises)."""

	def __init__(self, plan: Plan, bloquees: set[Case], portes: set[Case] | None = None) -> None:
		super().__init__(plan, set(), portes)
		self.bloquees = set(bloquees)

	def sans(self, cases) -> "CarteEtat":
		return CarteEtat(self.plan, self.bloquees | set(cases), self.portes)

	def avec(self, retire=(), ajoute=()) -> "CarteEtat":
		return CarteEtat(self.plan, (self.bloquees - set(retire)) | set(ajoute), self.portes)


def carte_etat(plan: Plan, drapeaux: frozenset[str] | None) -> CarteEtat:
	"""Carte d'un état : seules les positions `bloque` présentes bloquent (None : seulement les
	positions sans condition)."""
	return CarteEtat(plan, {c for p in plan.positions.values() if p.bloque and (
		present(p, drapeaux) if drapeaux is not None else not conditionnelle(p)) for c in p.cells})


def bandes(plan: Plan, drapeaux: frozenset[str]) -> set[Case]:
	return {c for p in plan.of_kind("declencheur") if present(p, drapeaux) for c in p.cells}


def ou_peut_etre(carte: CarteEtat, entree: list[Case], terminales: set[Case]) -> set[Case]:
	"""Cases où le joueur peut se trouver dans l'état : depuis l'entrée, sans dépasser une bande
	active (on y entre, la scène part) ni une porte."""
	vus, pile = set(entree), list(entree)
	while pile:
		c = pile.pop()
		if c in terminales:
			continue
		for n in carte.voisins(c):
			if n not in vus:
				vus.add(n)
				pile.append(n)
	return vus


def coupe(carte: CarteEtat, depart: list[Case], cible: set[Case], retire: set[Case]) -> bool:
	"""Vrai si `cible` est atteignable depuis `depart`, mais plus du tout sans les cases `retire`."""
	avec = carte.distances(depart)
	sans = carte.sans(retire).distances(depart)
	return any(c in avec for c in cible) and not any(c in sans for c in cible)


def verifier_azuria_j14(chemin: Path) -> bool:
	base = lire(chemin)
	plan = lire(chemin, VARIANTE)
	pos = plan.positions
	r = Rapport(f"Azuria après J14 — {_nom(chemin)} (variante {VARIANTE}) : {plan.width} × "
		f"{plan.height}")

	# 1. Base intacte, changements limités à la table du §1.3, identifiants stables.
	diff = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if base.at(x, y) != plan.at(x, y)}
	r.critere((base.width, base.height) == (plan.width, plan.height) and diff == CHANGEES,
		f"la variante ne change que les cases du §1.3 ({len(diff)} cases : clôture ouest, jardin, "
		f"trou, impasse, porte, sortie sud) {sorted(diff ^ CHANGEES)[:6]}")
	stables = [i for i in STABLES if i not in base.positions or i not in pos
		or not set(pos[i].cells) <= set(base.positions[i].cells)]
	r.critere(not stables, "identifiants stables aux cases du J13 : "
		+ ", ".join(f"{i} {pos[i].cells[0]}" for i in STABLES if i in pos)
		+ (f" ; écarts {stables}" if stables else ""))
	inconnus = [p.ident for p in plan.positions.values()
		if conditionnelle(p) and not (_liste(p, "if") | _liste(p, "unless")) <= {SPOTTED, BEATEN, LEFT}]
	r.critere(not inconnus, f"conditions sur les drapeaux connus ({SPOTTED}, {BEATEN}, {LEFT}) "
		f"{inconnus}")

	e = {nom: carte_etat(plan, d) for nom, d in ETATS}
	tout = carte_etat(plan, None)
	entree = sorted(c for c in _libres_du_bord(tout) if c[0] == 0)
	pot = pos["pot_renverse"].cells[0]

	# 2. Jardin.
	jardin_libre = JARDIN - {pot}
	r.critere(all(tout.libre(c) for c in jardin_libre | CLOTURE_OUEST) and not tout.libre(pot)
		and all(plan.at(*c) == "J" for c in JARDIN),
		f"jardin ouvert : {len(jardin_libre)} cases praticables (pot renversé {pot} bloqué), "
		"clôture ouest arrachée (6, 2..3) praticable")
	r.critere(coupe(tout, entree, jardin_libre, CLOTURE_OUEST),
		"jardin atteignable depuis la rue, seulement par la clôture arrachée (6, 2..3)")

	# 3. Poursuite.
	poursuite = pos["poursuite"]
	fouille = pos["rocket_fouille"]
	arret = pos["rocket_arret"]
	r.critere(poursuite.attrs.get("dir") == "right" and set(poursuite.cells) == {(7, 2), (7, 3)}
		and coupe(tout, entree, jardin_libre - set(poursuite.cells), set(poursuite.cells)),
		f"bande de poursuite {poursuite.cells} (pas vers →) inévitable : tout le jardin est derrière")
	courses = []
	for joueur in poursuite.cells:
		m = e["E0 avant"].avec(retire=fouille.cells, ajoute=[joueur])
		d = m.distances(fouille.cells)
		courses.append(d.get(arret.cells[0], INF))
	r.critere(all(k < INF for k in courses) and fouille.attrs.get("facing") == "up",
		f"le Rocket fouille en {fouille.cells[0]} (dos au joueur) et court par le trou jusqu'à "
		f"{arret.cells[0]} sans croiser le joueur : {courses} pas")

	# 4. Impasse.
	xs = sorted({x for x, _ in IMPASSE})
	ys = sorted({y for _, y in IMPASSE})
	longueur = xs[-1] - xs[0] + 1
	voisines = {_decale(c, d) for c in IMPASSE for d in DIRECTIONS} - IMPASSE - {TROU}
	ouvertes = sorted(c for c in voisines if tout.libre(c))
	r.critere(all(tout.libre(c) for c in IMPASSE) and longueur >= LONGUEUR_MIN and len(ys) == 2,
		f"impasse x {xs[0]}..{xs[-1]}, y {ys[0]}..{ys[-1]} : {longueur} cases de long (≥ "
		f"{LONGUEUR_MIN}), 2 de large, toutes praticables")
	r.critere(not ouvertes and not tout.libre((xs[-1] + 1, ys[0]))
		and not tout.libre((xs[-1] + 1, ys[-1])) and coupe(tout, entree, IMPASSE, {TROU}),
		f"impasse fermée (est x {xs[-1] + 1} : forêt ; aucune case praticable autour) ; seul accès "
		f"par le trou {TROU} {ouvertes[:4]}")
	trou = pos["trou_cloture"]
	r.critere(plan.at(*TROU) == "Y" and tout.libre(TROU) and not trou.bloque
		and tout.libre(_decale(TROU, (-1, 0))) and plan.at(14, 2) == "c",
		f"trou {TROU} praticable, examinable (n° 29) depuis {_decale(TROU, (-1, 0))} tourné → ; "
		"la clôture (14, 2) reste bloquée")

	# 5. Combat : vue sur toute la largeur, arrêt, approche, départ.
	combat = pos["combat_rocket"]
	bande = set(combat.cells)
	colonne = {x for x, _ in bande}
	r.critere(len(colonne) == 1 and bande == {(x, y) for x in colonne for y in ys}
		and combat.attrs.get("dir") == "right",
		f"bande du combat {sorted(bande)} (pas vers →) : toute la largeur de l'impasse "
		f"(rangées {ys})")
	x_bande = colonne.pop() if len(colonne) == 1 else -1
	fond = {c for c in IMPASSE if c[0] > x_bande}
	ax, ay = arret.cells[0]
	r.critere(coupe(tout, entree, fond, bande) and ax > x_bande and ay in ys
		and arret.attrs.get("facing") == "left" and (ax, ay) in IMPASSE,
		f"arrêt du Rocket {arret.cells[0]} tourné ← au fond, derrière la bande : on ne l'atteint "
		f"pas sans la franchir ({len(fond)} cases derrière)")
	e1 = e["E1 repéré"]
	reste = (IMPASSE - {arret.cells[0]})
	d1 = e1.distances(entree)
	r.critere(all(c in d1 for c in reste),
		f"Rocket à l'arrêt : les {len(reste)} autres cases de l'impasse restent reliées à la rue")
	fautes = []
	for b in sorted(bande):
		pres = _decale(b, (1, 0))           # case voisine du joueur, côté Rocket
		m = e1.avec(retire=arret.cells, ajoute=[b])
		approche = m.distances(arret.cells).get(pres, INF)
		apres = e1.avec(retire=arret.cells, ajoute=[pres]).distances([b])
		depart = e1.avec(retire=arret.cells, ajoute=[b]).distances([pres]).get(TROU, INF)
		if approche == INF:
			fautes.append(f"joueur {b} : le Rocket n'a pas de chemin jusqu'à {pres}")
		if not any(c in apres for c in entree):
			fautes.append(f"joueur {b}, Rocket {pres} : le joueur est coincé")
		if depart == INF:
			fautes.append(f"joueur {b} : le Rocket ne peut pas repartir par le trou")
	r.critere(not fautes, "approche du Rocket (case voisine du joueur vu sur la bande) : aucun "
		"passage fermé, chemin d'approche et départ par le trou existent"
		+ (" : " + " ; ".join(fautes) if fautes else ""))

	# 6. Aucune case coincée, rien ne se bloque dans le jardin ni l'impasse.
	ou = {nom: ou_peut_etre(e[nom], entree, bandes(plan, d)) for nom, d in ETATS}
	coincees = []
	for i, (ni, _) in enumerate(ETATS):
		for nj, _ in ETATS[i:]:
			dj = e[nj].distances(entree)  # pas de rebord à Azuria : la relation est symétrique
			for c in sorted(ou[ni]):
				if c not in e[nj].portes and (not e[nj].libre(c) or c not in dj):
					coincees.append(f"{c} ({ni} → {nj})")
	r.critere(not coincees, "aucune case coincée : toute case où le joueur peut être (et "
		"sauvegarder) reste libre et reliée à l'entrée dans tous les états suivants "
		+ (str(coincees[:4]) if coincees else ""))
	apparitions, sur_place = [], []
	for p in plan.positions.values():
		if not p.bloque:
			continue
		for i, (ni, di) in enumerate(ETATS):
			for nj, dj_ in ETATS[i + 1:]:
				if present(p, dj_) and not present(p, di):
					apparitions.append(f"{p.ident} ({ni} → {nj})")
					if set(p.cells) & ou[ni]:
						sur_place.append(f"{p.ident} {p.cells[0]} ({ni} → {nj})")
	r.critere(not sur_place, "une position qui apparaît ne tombe jamais sur une case où le joueur "
		f"pouvait être : {', '.join(sorted(set(apparitions)))} " + (str(sur_place) if sur_place else ""))
	decor_zone = [p.ident for p in plan.positions.values() if p.bloque and _liste(p, "if")
		and p.kind != "pnj" and set(p.cells) & (JARDIN | IMPASSE | {TROU} | CLOTURE_OUEST)]
	r.critere(not decor_zone, "aucun décor qui apparaît (if=) sur le jardin, le trou ou "
		f"l'impasse (la planche clouée est sur la clôture) {decor_zone}")
	for nom, _ in ETATS:
		r.info(f"{nom} : joueur possible sur {len(ou[nom])} cases ; jardin "
			f"{len(ou[nom] & JARDIN)}, impasse {len(ou[nom] & IMPASSE)}, couloir sud "
			f"{len(ou[nom] & SUD)}")

	# 7. Sortie sud.
	policier = pos["policier_sud"]
	barrieres = pos["barriere_sud"]
	bande_sud = pos["barrage_sud"]
	warp_sud = pos["warp_sud"]
	spawns = pos["from_route_5"]
	rangee = {c for c in SUD if c[1] == 38}
	r.critere(all(tout.libre(c) for c in SUD) and all(not tout.libre(c) for c in SUD_BORDS)
		and set(policier.cells) | set(barrieres.cells) == rangee and len(policier.cells) == 1
		and policier.attrs.get("facing") == "up",
		f"couloir sud x 31..33, y 38..40 (3 de large) ; policier {policier.cells[0]} tourné ↑ + "
		f"barrières {barrieres.cells} = toute la rangée 38")
	bord_sud = {c for c in SUD if c[1] == plan.height - 1}
	ferme = [nom for nom, _ in ETATS[:3] if any(c in ou[nom] or c in e[nom].distances(entree)
		for c in bord_sud)]
	ouvert = all(c in e["E3 sud ouvert"].distances(entree) for c in bord_sud)
	r.critere(not ferme and ouvert, "sortie sud bloquée en E0, E1, E2 (aucun passage), libre en E3 "
		f"{ferme}")
	r.critere(set(warp_sud.cells) == bord_sud == set(spawns.cells)
		and bande_sud.attrs.get("dir") == "down"
		and set(bande_sud.cells) == {(x, 37) for x in range(31, 34)}
		and _liste(bande_sud, "if") == {BEATEN},
		f"raccord sud {sorted(bord_sud)} (warp « Route 5 — À venir », spawns from_route_5_w|c|e) ; "
		"bande (31..33, 37) pas vers ↓, après la victoire seulement")
	bords = {nom: sorted(_libres_du_bord(e[nom])) for nom, _ in ETATS}
	ouest = [c for c in bords["E3 sud ouvert"] if c[0] == 0]
	nord = [c for c in bords["E3 sud ouvert"] if c[1] == 0]
	r.critere(sorted(bords["E3 sud ouvert"]) == sorted(ouest + nord + sorted(bord_sud))
		and not any(c[0] == plan.width - 1 for c in bords["E3 sud ouvert"]),
		"bords ouverts : ouest (Route 4), nord (Route 24), sud (Route 5) ; est (Route 9) fermé")

	# 8. Maison cambriolée.
	porte = pos["porte_cambriolee"]
	ruban = pos["ruban_police"]
	h4 = pos["h4_policier"]
	devant = _decale(PORTE, (0, 1))
	entrees = {nom: PORTE in e[nom].distances(entree) for nom, _ in ETATS}
	r.critere(porte.kind == "warp" and porte.cells == [PORTE] and plan.at(*PORTE) == "D"
		and ruban.cells == [PORTE] and _liste(ruban, "unless") == {BEATEN}
		and not entrees["E0 avant"] and not entrees["E1 repéré"] and entrees["E2 battu"]
		and entrees["E3 sud ouvert"] and devant in e["E0 avant"].distances(entree),
		f"porte {PORTE} praticable avec warp ; ruban sur la case jusqu'à la victoire (examinable "
		f"depuis {devant}), entrée possible ensuite")
	r.critere(present(h4, ETATS[1][1]) and not present(h4, ETATS[2][1])
		and present(pos["planche_clouee"], ETATS[2][1])
		and not present(pos["planche_clouee"], ETATS[1][1]),
		f"policier H4 {h4.cells[0]} avant la victoire, absent après ; planche clouée (14, 2) "
		"après seulement")

	# 9. Connexité finale.
	d3 = e["E3 sud ouvert"].distances(entree)
	orphelines = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and e["E3 sud ouvert"].libre((x, y))
		and (x, y) not in d3]
	r.critere(not orphelines, f"E3 : toutes les cases praticables connexes {orphelines[:4]}")

	d0 = e["E0 avant"].distances(entree)
	r.info(f"entrée ouest → bande de poursuite {min(d0.get(c, INF) for c in poursuite.cells)} "
		f"pas ; → bande du combat {min(d1.get(c, INF) for c in bande)} pas ; → bord sud (E3) "
		f"{min(d3.get(c, INF) for c in bord_sud)} pas")
	return r.ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/azuria.txt"
	ok = verifier_azuria_j14(chemin.resolve())
	print("Plan conforme." if ok else "Plan NON conforme.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
