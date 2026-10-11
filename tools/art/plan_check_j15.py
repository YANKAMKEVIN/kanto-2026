#!/usr/bin/env python3
"""Vérifie les grilles du jalon 15 : la Route 5 et le passage souterrain (dossier 18).

Grilles : `tools/plans/route_5.txt`, `tools/plans/underground_path.txt`. Lecture par
`plan_grille.lire` ; déplacements de `plan_check.Monde` (4 directions, un pas par case) avec des
**portes terminales** (portes, postes, escaliers : on y entre, on ne les traverse pas). Les
positions `bloque` (PNJ, objets, panneaux, case cachée) bloquent leurs cases.

Route 5 (profil `verifier_route_5`) :
  - taille 42 × 62 ; raccord nord (19..21, 0) = warps = spawns, carte fermée ailleurs ;
  - Pension (7 × 6, porte au bas), jardin clos (clôture fermée, fleurs inatteignables, visible
    depuis le chemin), poste de garde (7 × 4) et bâtiment du souterrain (7 × 4) : emprises exactes ;
  - arrivée → Pension, poste, souterrain ; retour vers Azuria depuis chacun ; ordre ①②③ ;
  - chemins d'au moins 2 cases de large (fenêtres 2 × 2) jusqu'aux trois portes ;
  - hautes herbes : H1 et H2, blocs rectangulaires nets, évitables (distance inchangée) ;
  - aucun Dresseur ; 2 PNJ ; 1 objet visible, 1 caché (case bloquée, indice, atteignable) ;
  - pas de contact en diagonale seule (angles droits).
Passage souterrain (profil `verifier_souterrain`) :
  - taille 26 × 30 ; escaliers aux deux extrémités, spawns devant ; aucune herbe, aucun Dresseur ;
  - trajet nord ↔ sud ≤ 50 pas ; trois segments, deux coudes à angle droit (V → H → V) ;
  - trois alcôves 3 × 3 ouvertes sur un seul côté ; une pierre descellée (cache, case bloquée,
    indice) au fond d'une alcôve, atteignable de face ; un passant au milieu qui laisse 2 cases ;
  - galerie d'au moins 2 cases de large de bout en bout.

Usage : python3 tools/art/plan_check_j15.py [grille]   (défaut : les deux ; code 1 si échec)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import DIRECTIONS, INF, Monde, boite, zones_herbes  # noqa: E402
from plan_grille import HERBES, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
Case = tuple[int, int]


class Terminal(Monde):
	"""`Monde` où certaines cases (portes, escaliers) sont terminales."""

	def __init__(self, plan: Plan, terminales: str, bloquees: set[Case] = frozenset()) -> None:
		super().__init__(plan, bloquees)
		self.terminales = terminales
		self.portes = {c for ch in terminales for c in plan.cells_of(ch)}

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Terminal":
		return Terminal(self.plan, self.terminales, self.bloquees | set(cases))


def _d(c: Case, d: Case) -> Case:
	return (c[0] + d[0], c[1] + d[1])


def _fenetres_2x2(monde: Monde, exclure: set[Case]) -> set[Case]:
	"""Cases appartenant à un carré libre 2 × 2 (hors cases `exclure`)."""
	libres = {(x, y) for y in range(monde.plan.height) for x in range(monde.plan.width)
		if monde.libre((x, y)) and (x, y) not in exclure}
	ok: set[Case] = set()
	for (x, y) in libres:
		bloc = {(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)}
		if bloc <= libres:
			ok |= bloc
	return ok


def _largeur_2(plan: Plan, depart: list[Case], arrivees: list[Case], terminales: str,
		exclure: set[Case]) -> bool:
	"""Un chemin existe depuis `depart` jusqu'à une case de `arrivees` en restant dans des
	carrés libres 2 × 2 (les extrémités terminales comptent comme leur voisine)."""
	m = Terminal(plan, terminales)
	ok = _fenetres_2x2(m, exclure | m.portes)
	vus = {c for c in depart if c in ok}
	pile = list(vus)
	while pile:
		c = pile.pop()
		for d in DIRECTIONS:
			n = _d(c, d)
			if n in ok and n not in vus:
				vus.add(n)
				pile.append(n)
	return any(_d(a, d) in vus or a in vus for a in arrivees for d in DIRECTIONS)


def _diagonales(plan: Plan, m: Monde) -> list[Case]:
	"""Fenêtres 2 × 2 où seules deux cases opposées sont praticables (contact en diagonale)."""
	fautes = []
	for y in range(plan.height - 1):
		for x in range(plan.width - 1):
			a, b = m.libre((x, y)), m.libre((x + 1, y))
			c, d = m.libre((x, y + 1)), m.libre((x + 1, y + 1))
			if (a and d and not b and not c) or (b and c and not a and not d):
				fautes.append((x, y))
	return fautes


def _rect(plan: Plan, char: str) -> tuple[int, int, int, int, int]:
	"""(x0, y0, largeur, hauteur, nombre de cases) du groupe de cases `char`."""
	cases = plan.cells_of(char)
	xs, ys = [x for x, _ in cases], [y for _, y in cases]
	return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1, len(cases)


def _est_rect(plan: Plan, chars: str, taille: tuple[int, int]) -> bool:
	cases = [c for ch in chars for c in plan.cells_of(ch)]
	xs, ys = [x for x, _ in cases], [y for _, y in cases]
	l, h = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
	return (l, h) == taille and len(cases) == l * h


def _acces(m: Terminal, p) -> list[Case]:
	return [_d(c, d) for c in p.cells for d in DIRECTIONS
		if m.libre(_d(c, d)) and _d(c, d) not in m.portes]


def _bords_libres(plan: Plan, m: Monde) -> list[Case]:
	return sorted((x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and m.libre((x, y)))


def _outil(nom: str):
	etat = {"ok": True}

	def critere(vrai: bool, texte: str) -> None:
		etat["ok"] &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")
	return etat, critere


# ----------------------------------------------------------------------------------------------
def verifier_route_5(chemin: Path) -> bool:
	plan = lire(chemin)
	etat, critere = _outil("route_5")
	m = Terminal(plan, "DGE")
	pos = plan.positions
	nom = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {nom} : {plan.width} × {plan.height}")
	critere((plan.width, plan.height) == (42, 62), f"taille {plan.width} × {plan.height} (42 × 62)")

	# 1. Raccord nord, carte fermée.
	entree = [(x, 0) for x in range(plan.width) if m.libre((x, 0))]
	warps = sorted(c for c in pos["warp_nord"].cells)
	spawns = sorted(c for c in pos["from_cerulean"].cells)
	critere(entree == warps == spawns == [(19, 0), (20, 0), (21, 0)],
		f"raccord nord : {entree} praticables = warps = spawns (3 cases)")
	critere(_bords_libres(plan, m) == entree, "carte fermée : seul le raccord nord touche le bord")
	critere(not plan.cells_of("v"), "aucun rebord (route de plaine)")

	# 2. Bâtiments.
	pension_ok = _est_rect(plan, "WD", (7, 6)) and plan.cells_of("D") == [(27, 27)] \
		and _rect(plan, "D")[1] == _rect(plan, "W")[1] + 5
	x0, y0, l, h, _ = _rect(plan, "W")
	critere(pension_ok, f"Pension ({x0}..{x0 + 6}, {y0}..{y0 + 5}) : 7 × 6, porte (27, 27) sur "
		"la rangée du bas")
	critere(_est_rect(plan, "PG", (7, 4)) and plan.cells_of("G") == [(34, 44)],
		"poste de garde 7 × 4, porte (34, 44) au bas (modèle de la Route 2)")
	critere(_est_rect(plan, "UE", (7, 4)) and plan.cells_of("E") == [(11, 56)],
		"bâtiment du souterrain 7 × 4, porte (11, 56) au bas")
	warps_pos = {c for p in plan.of_kind("warp") for c in p.cells}
	critere({(27, 27), (34, 44), (11, 56)} <= warps_pos, "warps sur les trois portes")

	# 3. Jardin clos.
	jardin = set(plan.cells_of("j"))
	clot = set(plan.cells_of("c"))
	jx = [x for x, _ in jardin]
	jy = [y for _, y in jardin]
	voisins_j = {_d(c, d) for c in jardin for d in DIRECTIONS} - jardin
	ferme = voisins_j <= clot
	coins = {(x + dx, y + dy) for x, y in jardin for dx in (-1, 1) for dy in (-1, 1)} - jardin
	ferme &= coins <= clot
	tout = m.distances(entree)
	inatteignable = not (jardin & set(tout)) and not (clot & set(tout))
	critere(ferme and inatteignable and len(jardin) == 5 * 8,
		f"jardin clos ({min(jx)}..{max(jx)}, {min(jy)}..{max(jy)}) : {len(jardin)} cases de fleurs "
		"entourées de clôture sans trou, inatteignable")
	# Visible depuis le chemin : une case du chemin voit la clôture en ligne droite sans obstacle.
	vu = False
	for (cx, cy) in plan.cells_of("="):
		if cx > 22:
			continue
		for fx, fy in clot:
			if fy == cy and fx > cx and all(m.libre((x, cy)) for x in range(cx + 1, fx)):
				vu = True
	critere(vu, "jardin visible depuis le chemin (ligne droite dégagée du chemin à la clôture)")
	dist_jardin = min(abs(21 - fx) for fx, _ in clot)
	critere(dist_jardin <= 12, f"clôture à {dist_jardin} cases du chemin (≤ 12)")
	# Pension à l'est du chemin, avant le carrefour (ordre ① ② ③).
	porte_p, porte_g, porte_e = (27, 27), (34, 44), (11, 56)
	d_p, d_g, d_e = (tout.get(c, INF) for c in (porte_p, porte_g, porte_e))
	critere(max(d_p, d_g, d_e) < INF, f"arrivée → Pension {d_p} pas, → poste {d_g} pas, "
		f"→ souterrain {d_e} pas")
	critere(d_p < d_g and d_p < d_e, "ordre ① ② ③ : la Pension avant le carrefour")

	# 4. Retour vers Azuria.
	for nom_p, spawn in (("Pension", "from_pension"), ("poste", "from_poste"),
			("souterrain", "from_souterrain")):
		sp = pos[spawn].cells
		retour = m.distances(sp)
		r = min(retour.get(c, INF) for c in entree)
		critere(r < INF and all(plan.at(*c) in ".=" for c in sp),
			f"retour {nom_p} → Azuria : {r} pas (spawn {sp[0]} sur sol)")

	# 5. Largeur d'au moins 2 cases.
	exclure = {c for p in plan.positions.values() if p.bloque for c in p.cells}
	cibles = [[_d(porte_p, (0, 1))], [_d(porte_g, (0, 1))], [_d(porte_e, (0, 1))]]
	larges = [_largeur_2(plan, entree, c, "DGE", exclure) for c in cibles]
	critere(all(larges), "chemins d'au moins 2 cases de large (carrés 2 × 2 libres) jusqu'aux "
		"trois portes, PNJ et objets exclus")

	# 6. Herbes.
	zones = zones_herbes(plan)
	critere(len(zones) == 2, f"deux blocs d'hautes herbes : {len(zones)}")
	zones.sort(key=lambda z: min(y for _, y in z))
	toutes = set().union(*zones)
	for i, z in enumerate(zones, 1):
		xs, ys = [x for x, _ in z], [y for _, y in z]
		net = len(z) == (max(xs) - min(xs) + 1) * (max(ys) - min(ys) + 1)
		print(f"  H{i} : {boite(z)} ({len(z)} cases)")
		critere(net, f"H{i} est un rectangle net")
	for nom_p, cible in (("Pension", porte_p), ("poste", porte_g), ("souterrain", porte_e)):
		herbe = m.herbes_min(entree, lambda c: c in toutes).get(cible, INF)
		critere(herbe == 0, f"{nom_p} atteinte sans hautes herbes (H1, H2 évitables)")
	critere(not plan.cells_of(HERBES) or all(
		plan.at(*c) != HERBES for p in plan.of_kind("pnj") for c in p.cells),
		"aucun PNJ dans les herbes")

	# 7. Dresseurs, PNJ, objets.
	critere(not plan.of_kind("dresseur"), "aucun Dresseur (RB)")
	pnj = plan.of_kind("pnj")
	critere(len(pnj) == 2 and all("facing" in p.attrs for p in pnj), "2 PNJ, orientés")
	visibles = plan.of_kind("objet_visible")
	caches = plan.of_kind("cache")
	critere(len(visibles) == 1 and len(caches) == 1, "1 objet visible, 1 objet caché")
	for p in visibles + caches:
		c = p.cells[0]
		acces = [a for a in _acces(m, p) if a in tout]
		bon = bool(acces) and plan.at(*c) == "." and p.bloque
		if p.kind == "cache":
			bon &= "indice" in p.attrs
		critere(bon, f"{p.attrs.get('role')} {p.ident} {c} ({p.attrs.get('item')}) sur sol, "
			f"bloqué, atteignable de face depuis {acces[:2]}"
			+ (f", indice {p.attrs.get('indice')}" if p.kind == "cache" else ""))
	fautes = []
	for p in pnj + plan.of_kind("panneau"):
		c = p.cells[0]
		if plan.at(*c) != "." or not [a for a in _acces(m, p) if a in tout]:
			fautes.append(f"{p.ident} {c}")
	critere(not fautes, "PNJ et panneaux sur l'herbe rase, atteignables" + (f" : {fautes}" if fautes else ""))
	sp = [c for p in plan.of_kind("spawn") for c in p.cells]
	critere(all(c in tout or c in entree or c in {(27, 28), (34, 45), (11, 57)} for c in sp),
		"points d'apparition atteignables")

	# 8. Angles droits.
	diag = _diagonales(plan, m)
	critere(not diag, f"angles droits : aucun contact en diagonale seule {diag[:3] if diag else ''}")

	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes ; "
		f"arrivée → souterrain {d_e} pas")
	return etat["ok"]


# ----------------------------------------------------------------------------------------------
def verifier_souterrain(chemin: Path) -> bool:
	plan = lire(chemin)
	etat, critere = _outil("souterrain")
	m = Terminal(plan, "E")
	pos = plan.positions
	nom = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {nom} : {plan.width} × {plan.height}")
	critere((plan.width, plan.height) == (26, 30), f"taille {plan.width} × {plan.height} (26 × 30)")
	critere(not _bords_libres(plan, m), "carte fermée : aucune case praticable au bord")
	critere(not plan.cells_of("h") and not plan.of_kind("dresseur") and not plan.of_kind("herbes"),
		"aucune herbe, aucun Dresseur (aucune rencontre)")

	# Escaliers et trajet.
	nord, sud = pos["escalier_nord"].cells, pos["escalier_sud"].cells
	critere(sorted(plan.cells_of("E")) == sorted(nord + sud) and len(nord) == len(sud) == 2,
		f"escaliers {nord} et {sud} (2 cases chacun), seules cases E")
	a, b = pos["from_route_5"].cells, pos["from_route_6"].cells
	critere(all(_d(c, (0, -1)) in nord for c in a) and all(_d(c, (0, 1)) in sud for c in b),
		"points d'apparition devant les escaliers")
	dist = m.distances(a)
	trajet = min(dist.get(c, INF) for c in b)
	retour = min(m.distances(b).get(c, INF) for c in a)
	critere(trajet < INF and retour == trajet and trajet <= 50,
		f"trajet Route 5 → Route 6 : {trajet} pas, retour {retour} pas (≤ 50)")
	critere(all(c in dist for c in nord + sud), "les deux escaliers sont atteignables")

	# Galerie : segments et coudes.
	seg = {p.attrs["role"]: p for p in plan.of_kind("galerie")}
	critere(sorted(seg) == ["s1", "s2", "s3"], f"trois segments de galerie : {sorted(seg)}")
	if sorted(seg) != ["s1", "s2", "s3"]:
		return False
	def boite_de(p):
		xs, ys = [x for x, _ in p.cells], [y for _, y in p.cells]
		return min(xs), min(ys), max(xs), max(ys)
	b1, b2, b3 = (boite_de(seg[r]) for r in ("s1", "s2", "s3"))
	vert = lambda b: (b[3] - b[1]) > (b[2] - b[0])
	critere(vert(b1) and not vert(b2) and vert(b3),
		"orientations vertical → horizontal → vertical : deux coudes à angle droit")
	largeur = [min(b[2] - b[0], b[3] - b[1]) + 1 for b in (b1, b2, b3)]
	critere(min(largeur) >= 2, f"segments de {largeur} cases de large (≥ 2, compagnon)")
	coudes = plan.of_kind("repere")
	c1 = {(x, y) for x in range(b1[0], b1[2] + 1) for y in range(b1[1], b1[3] + 1)} & \
		{(x, y) for x in range(b2[0], b2[2] + 1) for y in range(b2[1], b2[3] + 1)}
	c2 = {(x, y) for x in range(b2[0], b2[2] + 1) for y in range(b2[1], b2[3] + 1)} & \
		{(x, y) for x in range(b3[0], b3[2] + 1) for y in range(b3[1], b3[3] + 1)}
	critere(len(c1) == len(c2) == 4 and all(m.libre(c) for c in c1 | c2),
		f"coudes 2 × 2 en {boite(c1)} et {boite(c2)}, praticables")
	galerie = set()
	for r in ("s1", "s2", "s3"):
		galerie |= set(seg[r].cells)

	# Alcôves.
	alcoves = sorted(plan.of_kind("alcove"), key=lambda p: p.attrs["role"])
	critere(len(alcoves) == 3, f"trois alcôves : {[p.attrs['role'] for p in alcoves]}")
	reste = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables} - galerie - set(nord) - set(sud)
	reste_alc = set()
	for p in alcoves:
		xs, ys = [x for x, _ in p.cells], [y for _, y in p.cells]
		taille = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
		cellules = set(p.cells)
		ouvertures = {(c, _d(c, d)) for c in cellules for d in DIRECTIONS
			if _d(c, d) in galerie}
		bords_ouverts = {c[0] if p.attrs["ouvre"] in ("ouest", "est") else c[1] for c, _ in ouvertures}
		sens = {"ouest": (-1, 0), "est": (1, 0), "nord": (0, -1), "sud": (0, 1)}[p.attrs["ouvre"]]
		largeur_ouv = len(ouvertures)
		bon = (taille == (3, 3) and not (cellules & galerie) and largeur_ouv == 3
			and len(bords_ouverts) == 1 and all(_d(c, sens) in galerie for c, _ in ouvertures))
		reste_alc |= cellules
		critere(bon, f"alcôve {p.attrs['role']} {boite(cellules)} : 3 × 3, ouverte sur un seul "
			f"côté ({p.attrs['ouvre']}, {largeur_ouv} cases)")
	renfl = pos["renflement"].cells
	attendu = galerie | reste_alc | set(renfl)
	pierre = set(plan.cells_of("n")) | set(plan.cells_of("r"))
	critere(((reste | pierre) - set(renfl) - reste_alc) <= pierre and reste_alc | set(renfl) <= reste | pierre,
		"toutes les cases praticables sont galerie, alcôves ou renflement")
	critere(set(renfl) <= {(x, 14) for x in range(8, 15)} and all(
		_d(c, (0, -1)) in galerie for c in renfl), "renflement d'une rangée accolé à S2")

	# Largeur 2 de bout en bout (PNJ exclus), passant, pierre descellée.
	exclure = {c for p in plan.positions.values() if p.bloque for c in p.cells}
	critere(_largeur_2(plan, a, b, "E", exclure),
		"galerie d'au moins 2 cases de large de bout en bout, passant et objets exclus")
	passant = pos["passant"].cells[0]
	milieu = trajet / 2
	chemin_a = m.distances(a)
	critere(abs(chemin_a.get(_d(passant, (0, -1)), INF) - milieu) <= 6,
		f"passant {passant} au milieu du trajet ({chemin_a.get(_d(passant, (0, -1)))} pas sur {trajet})")
	cache = plan.of_kind("cache")
	critere(len(cache) == 1, "un seul objet caché")
	p = cache[0]
	c = p.cells[0]
	fond = any(c in a_.cells for a_ in alcoves)
	acces = [x for x in _acces(m, p) if x in dist]
	critere(fond and plan.at(*c) == "n" and p.bloque and "indice" in p.attrs and acces
		and p.attrs.get("item") == "full_heal",
		f"{p.ident} {c} : pierre descellée « n » (case bloquée) au fond d'une alcôve, Guérison "
		f"(full_heal), indice {p.attrs.get('indice')}, atteignable de face depuis {acces}")
	critere(m.libre(c) is False, "la pierre descellée ne se traverse pas")
	diag = _diagonales(plan, m)
	critere(not diag, f"angles droits : aucun contact en diagonale seule {diag[:3] if diag else ''}")
	print(f"  statistiques : {len(attendu)} cases de galerie, alcôves et renflement ; "
		f"trajet {trajet} pas ({trajet * 0.72:.0f} s de marche)")
	return etat["ok"]


def main() -> int:
	args = sys.argv[1:]
	cibles = [Path(a) for a in args] if args else [RACINE / "tools/plans/route_5.txt",
		RACINE / "tools/plans/underground_path.txt"]
	bon = True
	for chemin in cibles:
		chemin = chemin.resolve()
		verif = verifier_souterrain if "underground" in chemin.name else verifier_route_5
		bon &= verif(chemin)
	print("Plans conformes." if bon else "Plans NON conformes.")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
