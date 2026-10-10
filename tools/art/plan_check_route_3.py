#!/usr/bin/env python3
"""Vérifie la grille de la Route 3 (jalon 12, dossier 15 §3, §4, §12) par recherche de chemin.

Grille : `tools/plans/route_3.txt`. Lecture par `plan_grille.lire` ; déplacements de
`plan_check.Monde` (4 directions, un pas par case, rebords sautés vers le sud seulement), avec
des **portes terminales** : la porte du Centre (`D`) et l'entrée du Mont Sélénite (`Q`) mènent à
une autre carte, on y entre, on ne les traverse pas. Les positions `bloque` (Dresseurs, PNJ,
Pokémon d'ambiance, objets, panneaux, case cachée) bloquent leurs cases.

Critères (repris par les tests de la carte au 12A) :
  - taille 82 × 38 ; raccord ouest = les rangées de la sortie est d'Argenta (`argenta.txt`,
    warp_est), warps et spawns compris ; carte fermée partout ailleurs ;
  - Centre 8 × 7 (bldg_centre_01, porte sur les 4e et 5e colonnes du bas) ; entrée de la grotte
    dans la paroi, au nord-est ; la montagne grandit vers l'est ;
  - entrée ouest → porte du Centre et → entrée de la grotte ; le Centre avant la grotte ;
  - D1 et D2 inévitables (comme Théo et Milo : impossible d'atteindre la grotte ni le Centre sans
    entrer dans leur ligne de vue ; première case vue à ≥ 3 cases) ; D3 à D6 évitables, un à un
    et ensemble (seulement 2 combats inévitables, B-8) ; D5 et D6 sans détour ;
  - deux itinéraires en ② : chacun suffit, couper les deux ferme la route ; D3 sur le nord, D4 sur
    le sud ;
  - rebords : ne se montent pas, chacun raccourcit le retour, l'aller ne les emprunte pas ;
  - hautes herbes : H4 incontournable, H2 ou H3 selon l'itinéraire, H1 évitable sans détour ;
    cases obligatoires sur le trajet le moins herbeux dans les bornes (imprimées) ;
  - objets : 3 visibles (Poké Ball, Potion, Anti-Para), 1 caché (Réveil, type « cache ») ;
    aucun sur une ligne de vue ; l'approche d'un Dresseur ne ferme aucun passage ;
  - PNJ, Pokémon d'ambiance, panneaux et points d'apparition bien placés.
Imprime la longueur du chemin principal et une estimation de la durée de traversée.

Usage : python3 tools/art/plan_check.py tools/plans/route_3.txt
        (ou python3 tools/art/plan_check_route_3.py [grille])   code 1 si un critère échoue
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, FACINGS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import HERBES, PORTE, REBORD, Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
Case = tuple[int, int]

TAILLE = (82, 38)                  # dossier 15 §3.1 (≈ 82 × 38, défaut recalé sur la grille)
GROTTE = "Q"
PAROI = "K"
CENTRE = "C"
CENTRE_EMPRISE = (8, 7, (3, 4))    # bldg_centre_01 : largeur, hauteur, colonnes de la porte
SOL = set(".=o")                   # sol où poser personnages, objets et points d'apparition
ZONES = ("H1", "H2", "H3", "H4")
HERBES_OBLIGATOIRES = (6, 10)      # défaut (Route 2 : 5 à 7 ; forêt : 11 à 14)
CHEMIN = (85, 130)                 # pas, entrée ouest → entrée de la grotte (défaut)
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases (≥ 2 libres entre eux)
DRESSEURS = {"D1": 5, "D2": 5, "D3": 3, "D4": 3, "D5": 4, "D6": 3}
INEVITABLES = ("D1", "D2")         # B-8
OBJETS = {"O1": ("objet_visible", "poke_ball"), "O2": ("objet_visible", "potion"),
	"O3": ("objet_visible", "paralyze_heal"), "O4": ("cache", "awakening")}
# Estimation de la traversée (méthode du profil forêt) : pas mesuré sur S21 (T22 du J9),
# combats de Dresseurs à deux Pokémon (Milo, défaut), rencontres de la Route 2 nord (§3.3).
S_PAR_PAS = 0.72
S_COMBAT_2 = 120
S_SAUVAGE = 50
TAUX = 25 / 256


class Route(Monde):
	"""`plan_check.Monde` avec portes terminales (porte du Centre, entrée de la grotte)."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset()) -> None:
		super().__init__(plan, bloquees)
		self.portes = set(plan.cells_of(PORTE)) | set(plan.cells_of(GROTTE))

	def voisins(self, c: Case):
		if c in self.portes:
			return
		yield from super().voisins(c)

	def sans(self, cases) -> "Route":
		return Route(self.plan, self.bloquees | set(cases))


def _decale(c: Case, d: Case, k: int = 1) -> Case:
	return (c[0] + d[0] * k, c[1] + d[1] * k)


def _composantes(cases: set[Case]) -> list[set[Case]]:
	reste, groupes = set(cases), []
	while reste:
		germe = reste.pop()
		groupe, pile = {germe}, [germe]
		while pile:
			c = pile.pop()
			for d in DIRECTIONS:
				n = _decale(c, d)
				if n in reste:
					reste.remove(n)
					groupe.add(n)
					pile.append(n)
		groupes.append(groupe)
	return sorted(groupes, key=lambda g: (min(x for x, _ in g), min(y for _, y in g)))


def _role(plan: Plan, kind: str) -> dict[str, object]:
	return {p.attrs.get("role", p.ident): p for p in plan.of_kind(kind)}


def _acces(monde: Route, p) -> list[Case]:
	"""Cases d'où l'on prend / examine / parle à p : les voisines libres de ses cases."""
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if monde.libre(_decale(c, d)) and _decale(c, d) not in monde.portes]


def _rangees_est_argenta(chemin: Path) -> list[int]:
	argenta = lire(chemin.with_name("argenta.txt"))
	return sorted(y for x, y in argenta.positions["warp_est"].cells if x == argenta.width - 1)


def verifier_route_3(chemin: Path) -> bool:
	plan = lire(chemin)
	ok = True

	def critere(vrai: bool, texte: str) -> None:
		nonlocal ok
		ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")

	monde = Route(plan)
	pos = plan.positions
	nom = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {nom} : {plan.width} × {plan.height}")
	critere((plan.width, plan.height) == TAILLE,
		f"taille {plan.width} × {plan.height} (attendu {TAILLE[0]} × {TAILLE[1]})")

	# 1. Raccord ouest sur la sortie est d'Argenta, carte fermée ailleurs.
	rangees = _rangees_est_argenta(chemin)
	entree = [(0, y) for y in range(plan.height) if monde.libre((0, y))]
	warps = sorted(c for p in plan.of_kind("warp") for c in p.cells if c[0] == 0)
	spawns = sorted(c for p in plan.of_kind("spawn") for c in p.cells if c[0] == 0)
	attendu = [(0, y) for y in rangees]
	critere(entree == warps == spawns == attendu,
		f"raccord ouest : rangées {[y for _, y in entree]} praticables, warps "
		f"{[y for _, y in warps]}, spawns {[y for _, y in spawns]} = sortie est d'Argenta "
		f"(51, {rangees[0]}..{rangees[-1]})")
	bords = [(x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and monde.libre((x, y))]
	critere(sorted(bords) == sorted(entree), "carte fermée : seul le raccord ouest touche le bord")

	# 2. Centre, entrée de la grotte, montagne.
	centres = _composantes(set(plan.cells_of(CENTRE)) | set(plan.cells_of(PORTE)))
	portes = plan.cells_of(PORTE)
	if len(centres) != 1 or not portes:
		critere(False, f"un Centre (C + D) attendu, {len(centres)} trouvé(s)")
		return False
	xs = [x for x, _ in centres[0]]
	ys = [y for _, y in centres[0]]
	larg, haut, cols = CENTRE_EMPRISE
	taille_c = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
	attendues = sorted((min(xs) + i, max(ys)) for i in cols)
	critere(taille_c == (larg, haut) and len(centres[0]) == larg * haut
		and sorted(portes) == attendues,
		f"Centre ({min(xs)}..{max(xs)}, {min(ys)}..{max(ys)}) : {taille_c[0]} × {taille_c[1]} "
		f"(attendu {larg} × {haut}, comme à Argenta), porte {sorted(portes)} sur la façade sud")
	grotte = plan.cells_of(GROTTE)
	paroi_autour = all(plan.at(x, y - 1) == PAROI for x, y in grotte) and all(
		plan.at(x, y) == PAROI for x, y in ((min(gx for gx, _ in grotte) - 1, grotte[0][1]),
			(max(gx for gx, _ in grotte) + 1, grotte[0][1])))
	nord_est = all(x >= plan.width * 0.75 and y < plan.height / 2 for x, y in grotte)
	critere(bool(grotte) and paroi_autour and nord_est,
		f"entrée du Mont Sélénite {grotte} : ouverture dans la paroi (K au-dessus et des deux "
		f"côtés), au nord-est")
	tiers = []
	for i in range(3):
		x0, x1 = plan.width * i // 3, plan.width * (i + 1) // 3
		tiers.append(sum(1 for y in range(plan.height) for x in range(x0, x1)
			if plan.at(x, y) == PAROI))
	critere(tiers[0] < tiers[1] < tiers[2],
		f"la montagne grandit vers l'est : {tiers[0]} → {tiers[1]} → {tiers[2]} cases de paroi "
		f"par tiers de la carte")
	warps_c = {c for p in plan.of_kind("warp") for c in p.cells}
	critere(set(portes) <= warps_c and set(grotte) <= warps_c,
		"warps sur la porte du Centre et sur l'entrée de la grotte")

	# 3. Chemin principal.
	dist = monde.distances(entree)
	aller = min(dist.get(c, INF) for c in grotte)
	vers_centre = min(dist.get(c, INF) for c in portes)
	critere(aller < INF and vers_centre < INF,
		f"entrée ouest → porte du Centre : {vers_centre} pas ; → entrée de la grotte : {aller} pas")
	if aller >= INF or vers_centre >= INF:
		return False
	critere(CHEMIN[0] <= aller <= CHEMIN[1] and vers_centre < aller,
		f"chemin principal {aller} pas (attendu {CHEMIN[0]} à {CHEMIN[1]}) ; le Centre avant "
		f"la grotte ({vers_centre} < {aller})")
	sortie = pos["from_mt_moon"].cells
	retour = monde.distances(sortie)
	retour_ouest = min(retour.get(c, INF) for c in entree)
	grotte_centre = min(retour.get(c, INF) for c in portes)
	critere(retour_ouest < INF and grotte_centre < INF,
		f"retour : grotte → Centre {grotte_centre} pas, grotte → Argenta {retour_ouest} pas")

	def jusqua(m: Route, cibles: list[Case]) -> int:
		return min(m.distances(entree).get(c, INF) for c in cibles)

	# 4. Hautes herbes.
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ZONES)
	if len(zones) != len(ZONES) or sorted(nommees) != sorted(ZONES):
		critere(False, f"zones H1..H4 attendues : {len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	for n in ZONES:
		print(f"  {n} : {boite(nommees[n])}")
	toutes = set().union(*zones)
	g_min = monde.herbes_min(entree, lambda c: c in toutes)
	g_grotte = min(g_min.get(c, INF) for c in grotte)
	h1, h2, h3, h4 = (nommees[n] for n in ZONES)
	critere(HERBES_OBLIGATOIRES[0] <= g_grotte <= HERBES_OBLIGATOIRES[1],
		f"cases de hautes herbes obligatoires jusqu'à la grotte : {g_grotte} "
		f"(attendu {HERBES_OBLIGATOIRES[0]} à {HERBES_OBLIGATOIRES[1]})")
	n_h4 = min(monde.herbes_min(entree, lambda c: c in h4).get(c, INF) for c in grotte)
	critere(jusqua(monde.sans(h4), grotte) >= INF and jusqua(monde.sans(h4), portes) >= INF,
		f"H4 incontournable (Centre et grotte) : {n_h4} cases traversées au moins")
	sans_23 = jusqua(monde.sans(h2 | h3), grotte)
	d_sans_h2 = jusqua(monde.sans(h2), grotte)
	d_sans_h3 = jusqua(monde.sans(h3), grotte)
	critere(sans_23 >= INF and d_sans_h2 < INF and d_sans_h3 < INF,
		f"H2 ou H3 selon l'itinéraire : sans H2 {d_sans_h2} pas, sans H3 {d_sans_h3} pas, "
		f"sans les deux : {'fermé' if sans_23 >= INF else sans_23}")
	d_sans_h1 = jusqua(monde.sans(h1), grotte)
	critere(d_sans_h1 == aller, f"H1 évitable sans détour ({d_sans_h1} pas sans y entrer)")
	requises = h2 | h3 | h4
	hors = min(monde.herbes_min(entree, lambda c: c in toutes and c not in requises).get(c, INF)
		for c in grotte)
	critere(hors == 0, f"aucune case obligatoire hors de H2 / H3 et H4 (minimum hors : {hors})")

	# 5. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	critere(sorted(dresseurs) == sorted(DRESSEURS), f"6 Dresseurs D1..D6 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(DRESSEURS):
		return False
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		p = dresseurs[role]
		vue = ligne_de_vue(monde, p)
		vues[role] = vue
		vision = int(p.attrs.get("sight", "0"))
		critere(vision == DRESSEURS[role] and len(vue) == vision and plan.at(*p.cells[0]) in SOL,
			f"{role} {p.ident} {p.cells[0]} tourné {p.attrs.get('facing')} : vision {len(vue)}/"
			f"{vision} cases dégagées ({''.join(plan.at(*c) for c in vue)})")
	for role in INEVITABLES:
		bloque = set(vues[role])
		sans = jusqua(monde.sans(bloque), grotte)
		sans_c = jusqua(monde.sans(bloque), portes)
		premiere = premiere_detection(monde, entree, vues[role])
		critere(sans >= INF and sans_c >= INF and premiere >= DETECTION_MIN,
			f"{role} {dresseurs[role].ident} inévitable (grotte : "
			f"{'fermée' if sans >= INF else sans}, Centre : {'fermé' if sans_c >= INF else sans_c}) ; "
			f"première case vue à {premiere} cases (attendu ≥ {DETECTION_MIN})")
	evitables = [r for r in DRESSEURS if r not in INEVITABLES]
	for role in evitables:
		d = jusqua(monde.sans(vues[role]), grotte)
		detour = role in ("D5", "D6")
		critere(d < INF and (not detour or d == aller),
			f"{role} {dresseurs[role].ident} évitable : grotte en {d} pas hors de sa vue"
			+ (" (sans détour)" if detour else f" (+{d - aller})"))
	tous = set().union(*(vues[r] for r in evitables))
	d_tous = jusqua(monde.sans(tous), grotte)
	critere(d_tous < INF, f"D3 à D6 évitables ensemble : grotte en {d_tous} pas "
		"(seuls D1 et D2 sont obligatoires, B-8)")

	# 6. Deux itinéraires en ② ; D3 au nord, D4 au sud.
	iti = _role(plan, "itineraire")
	if sorted(iti) != ["nord", "sud"]:
		critere(False, f"coupes itineraire nord et sud attendues : {sorted(iti)}")
		return False
	nord, sud = set(iti["nord"].cells), set(iti["sud"].cells)
	d_n = jusqua(monde.sans(nord), grotte)
	d_s = jusqua(monde.sans(sud), grotte)
	d_ns = jusqua(monde.sans(nord | sud), grotte)
	critere(d_n < INF and d_s < INF and d_ns >= INF,
		f"deux itinéraires : par le sud {d_n} pas, par le nord {d_s} pas ; les deux coupés : "
		f"{'fermé' if d_ns >= INF else d_ns}")
	d3, d4 = dresseurs["D3"], dresseurs["D4"]
	critere(set(d3.cells + vues["D3"]) <= nord and set(d4.cells + vues["D4"]) <= sud,
		f"D3 {d3.cells[0]} sur l'itinéraire nord, D4 {d4.cells[0]} sur l'itinéraire sud")

	# 7. Rebords.
	# Numérotés d'est en ouest (L1 = plateau du Centre, L2 = sentier de la jonction), comme le plan.
	rebords = sorted(_composantes(set(plan.cells_of(REBORD))), key=lambda r: -min(r)[0])
	sans_rebords = monde.sans(plan.cells_of(REBORD))
	critere(len(rebords) >= 1, f"{len(rebords)} rebord(s)")
	for i, r in enumerate(rebords, 1):
		montable = any(monde.pas((x, y + 1), (0, -1)) is not None for x, y in r)
		lateral = any(monde.pas((x - dx, y), (dx, 0)) is not None for x, y in r for dx in (-1, 1))
		hauts = [(x, y - 1) for x, y in r if monde.libre((x, y - 1))]
		avec = min(min(monde.distances([h]).get(c, INF) for c in entree) for h in hauts)
		sans = min(min(monde.sans(r).distances([h]).get(c, INF) for c in entree) for h in hauts)
		x0, y0 = min(r)
		critere(not montable and not lateral and avec < sans,
			f"rebord L{i} ({x0}..{max(x for x, _ in r)}, {y0}) : ne se monte pas ; retour vers "
			f"Argenta depuis le haut : {avec} pas contre {sans if sans < INF else '∞'} sans lui")
	r_sans = min(sans_rebords.distances(sortie).get(c, INF) for c in entree)
	aller_sans = jusqua(sans_rebords, grotte)
	critere(retour_ouest < r_sans and aller_sans == aller,
		f"rebords = raccourcis de retour : grotte → Argenta {retour_ouest} pas contre {r_sans} ; "
		f"aller inchangé ({aller_sans})")

	# 8. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	conformes = sorted(objets) == sorted(OBJETS) and all(
		objets[r].kind == k and objets[r].attrs.get("item") == it for r, (k, it) in OBJETS.items()
		if r in objets)
	critere(conformes, "objets O1..O3 visibles (Poké Ball, Potion, Anti-Para), O4 caché (Réveil)")
	tout = monde.distances(entree + list(sortie))
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((dist.get(a, INF) for a in _acces(monde, p)), default=INF)
		sol = plan.at(*c)
		bon = atteint < INF and sol in SOL and c not in lignes
		if p.kind == "cache":
			bon &= p.bloque and sol != "=" and "indice" in p.attrs
		critere(bon, f"{role} {p.ident} {c} sur « {sol} » ({p.attrs.get('item')}"
			+ (f", indice {p.attrs.get('indice')}" if p.kind == "cache" else "")
			+ f") : atteint en {atteint} pas, hors des lignes de vue")

	# 9. Un Dresseur qui s'approche ne ferme jamais un passage (jalon 9 §6.9).
	cibles = [list(grotte), list(portes), [entree[0]]] + [_acces(monde, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in tout:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Route(plan)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	critere(not fermes, "l'approche d'un Dresseur ne ferme aucun passage "
		f"{fermes[:3] if fermes else ''}")

	# 10. PNJ, Pokémon d'ambiance, panneaux, points d'apparition.
	fautes: list[str] = []
	for p in plan.of_kind("pnj") + plan.of_kind("pokemon") + plan.of_kind("panneau"):
		for c in p.cells:
			if c in lignes or plan.at(*c) == HERBES:
				fautes.append(f"{p.ident} {c} sur une ligne de vue ou dans les herbes")
			if p.kind in ("pnj", "panneau") and plan.at(*c) not in SOL - {"="}:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} » (hors du chemin attendu)")
			if p.kind == "pnj" and "facing" not in p.attrs:
				fautes.append(f"{p.ident} sans facing")
		if not any(a in tout for a in _acces(monde, p)):
			fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
	for p in plan.of_kind("spawn") + plan.of_kind("herbes"):
		for c in p.cells:
			if c not in tout and c not in entree:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if plan.at(*c) not in SOL:
				fautes.append(f"{p.ident} sur « {plan.at(*c)} » en {c}")
	critere(not fautes, "PNJ, Pokémon, panneaux et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))

	# Statistiques et durée.
	praticables = sum(1 for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {praticables} cases praticables sur {plan.width * plan.height} "
		f"({100 * praticables / (plan.width * plan.height):.0f} %), {len(toutes)} cases d'herbes "
		f"({', '.join(f'{n} {len(nommees[n])}' for n in ZONES)})")
	rencontres = g_grotte * TAUX
	duree = aller * S_PAR_PAS + 2 * S_COMBAT_2 + rencontres * S_SAUVAGE
	print(f"  traversée directe estimée : {aller} pas × {S_PAR_PAS} s + Hugo et Léa "
		f"2 × {S_COMBAT_2} s + {rencontres:.2f} rencontre(s) attendue(s) × {S_SAUVAGE} s = "
		f"{duree:.0f} s ({int(duree // 60)} min {int(duree % 60):02d} s) ; marche seule "
		f"{aller * S_PAR_PAS:.0f} s")
	return ok


def main() -> int:
	chemin = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "tools/plans/route_3.txt"
	bon = verifier_route_3(chemin.resolve())
	print("Plan conforme." if bon else "Plan NON conforme.")
	return 0 if bon else 1


if __name__ == "__main__":
	sys.exit(main())
