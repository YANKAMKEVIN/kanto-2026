#!/usr/bin/env python3
"""Vérifie les grilles des routes du jalon 20 (dossier 23 §3 à §6) par recherche de chemin.

Grilles : `tools/plans/route_8.txt`, `route_7.txt`, `souterrain_7_8.txt`, `souterrain_entree.txt`
(enveloppe commune aux deux routes), `poste_safrania.txt` (enveloppe commune aux deux routes).
Lecture par `plan_grille.lire` ; déplacements de `plan_check.Monde` (4 directions, un pas par
case, rebords sautés vers le sud seulement) avec des **portes terminales** : une porte de
bâtiment (`D`), un escalier (`E`) et une sortie d'intérieur (`X`) mènent à une autre carte, on y
entre, on ne les traverse pas.

Critères :
  Route 8 (80 × 26) : raccord est (79, 10..12) ↔ Lavanville (0, 10..12), grille du J18 ; deux bâtiments
    7 × 4 (poste au sud-ouest, entrée du souterrain au nord-ouest) ; D1, D2, D4, D5 inévitables
    (première case vue à ≥ 3 cases) ; D4 et D5 côte à côte, vues parallèles ; D3, D6, D7 évitables
    un à un et ensemble ; chemins haut et bas (chacun suffit, tous deux coupés ferment la
    route ; D3 sur le haut, herbes H2 sur le bas) ; H1 obligatoire (4 à 8 cases), H2 et H3
    évitables ; rebord : ne se monte pas ; objets (Super Potion visible sur le chemin haut,
    Rappel caché près de la corniche, hors des lignes de vue) ; l'approche d'un Dresseur ne
    ferme aucun passage ; PNJ / panneaux / points d'apparition bien placés.
  Route 7 (28 × 24) : raccord ouest (0, 10..12) ↔ Céladopole (69, 21..23) ; deux bâtiments 7 × 4 ;
    aucun Dresseur ; 2 zones d'herbes évitables ; pas de rebord.
  Souterrain (48 × 10) : escaliers aux deux bouts ; itinéraire de 2 cases de large au moins ;
    niche au tiers ouest, coude au milieu ; 2 objets cachés atteignables ; aucune herbe,
    aucun Dresseur.
  Bâtiment d'entrée / poste : sortie, escalier ou porte fermée, habitant ou garde.
  Raccords entre cartes (`verifier_raccords`) : portes de bâtiment ↔ sorties d'intérieur,
    escaliers ↔ bouts du souterrain, cible et point d'apparition cohérents dans les deux sens ;
    traversée complète Lavanville → souterrain → Route 7 → Céladopole, et retour.

Usage : python3 tools/art/plan_check_routes_j20.py            (les cinq grilles + raccords)
        python3 tools/art/plan_check_routes_j20.py route_8     (une seule)
Code 1 si un critère échoue.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check import (DIRECTIONS, INF, Monde, boite, ligne_brute,  # noqa: E402
	ligne_de_vue, nommer_zones, premiere_detection, zones_herbes)
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools/plans"
Case = tuple[int, int]

BATIMENT = (7, 4, 3)               # largeur, hauteur, colonne de la porte (comme le poste de la Route 2)
SOL = set(".=")                    # sol où poser un personnage ou un point d'apparition
DETECTION_MIN = 3                  # première case vue à ≥ 3 cases (≥ 2 libres entre eux)
CELADON_RACCORD = (69, (21, 22, 23))   # imposé : colonne et rangées de la sortie est de Céladopole
S_PAR_PAS = 0.72
S_COMBAT = 120


class Carte(Monde):
	"""`plan_check.Monde` avec des cases terminales (portes, escaliers, sorties d'intérieur)."""

	def __init__(self, plan: Plan, bloquees: set[Case] = frozenset(), terminales: str = "DEX") -> None:
		super().__init__(plan, bloquees)
		self.terminales = terminales
		self.portes = {c for t in terminales for c in plan.cells_of(t)}
		self._departs: set[Case] = set()

	def voisins(self, c: Case):
		if c in self.portes and c not in self._departs:
			return
		yield from super().voisins(c)

	def distances(self, departs: list[Case]) -> dict[Case, int]:
		self._departs = set(departs)
		return super().distances(departs)

	def herbes_min(self, departs: list[Case], compte) -> dict[Case, int]:
		self._departs = set(departs)
		return super().herbes_min(departs, compte)

	def sans(self, cases) -> "Carte":
		return Carte(self.plan, self.bloquees | set(cases), self.terminales)


class Rapport:
	def __init__(self) -> None:
		self.ok = True

	def critere(self, vrai: bool, texte: str) -> bool:
		self.ok &= bool(vrai)
		print(f"  [{'OK' if vrai else 'ÉCHEC'}] {texte}")
		return bool(vrai)


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


def _acces(monde: Carte, p) -> list[Case]:
	"""Cases d'où l'on prend / examine / parle à p : les voisines libres de ses cases."""
	return [_decale(c, d) for c in p.cells for d in DIRECTIONS
		if monde.libre(_decale(c, d)) and _decale(c, d) not in monde.portes]


def _bord(plan: Plan, monde: Carte) -> list[Case]:
	return sorted((x, y) for y in range(plan.height) for x in range(plan.width)
		if (x in (0, plan.width - 1) or y in (0, plan.height - 1)) and monde.libre((x, y)))


def _en_tete(chemin: Path, nom: str) -> tuple[Plan, Carte, "Rapport"]:
	plan = lire(chemin)
	rel = chemin.relative_to(RACINE) if chemin.is_relative_to(RACINE) else chemin
	print(f"Grille {rel} : {plan.width} × {plan.height}")
	return plan, Carte(plan), Rapport()


def _batiments(r: Rapport, plan: Plan, monde: Carte) -> list[set[Case]]:
	"""Bâtiments « P » + porte « D » : 7 × 4, porte à la 4e colonne de la rangée du bas."""
	blocs = _composantes(set(plan.cells_of("P")) | set(plan.cells_of("D")))
	larg, haut, col = BATIMENT
	warps = {c for p in plan.of_kind("warp") for c in p.cells}
	for b in blocs:
		xs, ys = [x for x, _ in b], [y for _, y in b]
		taille = (max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
		porte = (min(xs) + col, max(ys))
		r.critere(taille == (larg, haut) and len(b) == larg * haut
			and plan.cells_of("D") and plan.at(*porte) == "D" and porte in warps,
			f"bâtiment ({min(xs)}..{max(xs)}, {min(ys)}..{max(ys)}) : {taille[0]} × {taille[1]} "
			f"(attendu {larg} × {haut}), porte {porte} (4e colonne du bas), warp posé")
	return blocs


def _ligne_vue_ok(plan: Plan, monde: Carte, p, vues: dict[str, list[Case]], role: str,
		vision: int, r: Rapport) -> None:
	vue = ligne_de_vue(monde, p)
	vues[role] = vue
	r.critere(len(vue) == vision == int(p.attrs.get("sight", "0")) and plan.at(*p.cells[0]) in SOL | {"."},
		f"{role} {p.ident} {p.cells[0]} tourné {p.attrs.get('facing')} : vision {len(vue)}/{vision} "
		f"cases dégagées ({''.join(plan.at(*c) for c in vue)})")


def premiere_union(monde: Carte, departs: list[Case], vues: list[list[Case]]) -> int:
	"""Comme `premiere_detection`, pour plusieurs Dresseurs à la fois : le joueur est arrêté par la
	première ligne de vue qu'il touche ; rang = distance au Dresseur de cette ligne."""
	rang: dict[Case, int] = {}
	for vue in vues:
		for i, c in enumerate(vue):
			rang[c] = min(rang.get(c, INF), i + 1)
	return premiere_detection(monde, departs, [c for c, _ in sorted(rang.items(), key=lambda kv: kv[1])])


def _placement(r: Rapport, plan: Plan, monde: Carte, atteint: dict[Case, int], lignes: set[Case],
		entree: list[Case]) -> None:
	"""PNJ, Pokémon d'ambiance, panneaux, points d'apparition bien placés (profil Route 3)."""
	fautes: list[str] = []
	for p in plan.of_kind("pnj") + plan.of_kind("pokemon") + plan.of_kind("panneau"):
		for c in p.cells:
			if c in lignes or plan.at(*c) == "h":
				fautes.append(f"{p.ident} {c} sur une ligne de vue ou dans les herbes")
			if p.kind in ("pnj", "panneau") and plan.at(*c) not in SOL - {"="}:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} » (herbe rase attendue)")
			if p.kind == "pnj" and "facing" not in p.attrs:
				fautes.append(f"{p.ident} sans facing")
			if p.kind == "pokemon" and plan.at(*c) not in SOL:
				fautes.append(f"{p.ident} {c} sur « {plan.at(*c)} »")
		if not any(a in atteint for a in _acces(monde, p)):
			fautes.append(f"{p.ident} {p.cells[0]} sans case voisine atteignable")
	for p in plan.of_kind("spawn") + plan.of_kind("herbes"):
		for c in p.cells:
			if c not in atteint and c not in entree:
				fautes.append(f"{p.ident} {c} hors d'atteinte")
	for p in plan.of_kind("spawn"):
		for c in p.cells:
			if plan.at(*c) not in SOL | {"e"}:
				fautes.append(f"{p.ident} sur « {plan.at(*c)} » en {c}")
	r.critere(not fautes, "PNJ, Pokémon, panneaux et points d'apparition bien placés"
		+ (" : " + " ; ".join(fautes) if fautes else ""))


# --- Route 8 ------------------------------------------------------------------------------------

R8_TAILLE = (80, 26)
R8_RACCORD = [(79, 10), (79, 11), (79, 12)]
R8_DRESSEURS = {"D1": 5, "D2": 5, "D3": 4, "D4": 5, "D5": 5, "D6": 6, "D7": 6}
R8_INEVITABLES = ("D1", "D2", "D4", "D5")
R8_EVITABLES = ("D3", "D6", "D7")
R8_H1 = (4, 8)                       # cases de hautes herbes obligatoires (défaut des routes)


def verifier_route_8(chemin: Path) -> bool:
	plan, monde, r = _en_tete(chemin, "route_8")
	pos = plan.positions
	texte = chemin.read_text(encoding="utf-8")
	r.critere((plan.width, plan.height) == R8_TAILLE, f"taille {plan.width} × {plan.height} (attendu 80 × 26)")

	# 1. Raccord est (recalé sur Lavanville, J18) ; carte fermée ailleurs.
	entree = [c for c in _bord(plan, monde)]
	warps = sorted(c for c in pos["raccord_est"].cells)
	spawns = sorted(pos["from_lavender"].cells)
	r.critere(entree == warps == spawns == R8_RACCORD,
		f"raccord est : {entree} praticables, warps {warps}, spawns {spawns} (attendu (79, 10..12))")
	r.critere("J18" in texte and "provisoire" not in pos["raccord_est"].attrs,
		"raccord est recalé sur Lavanville (J18) : (79, 10..12) ↔ (0, 10..12)")
	r.critere(all(c[0] == plan.width - 1 for c in entree) and plan.at(0, 12) == "T",
		"aucun raccord à l'ouest : la porte du poste ferme l'ouest")

	# 2. Bâtiments.
	blocs = _batiments(r, plan, monde)
	if len(blocs) != 2:
		r.critere(False, f"2 bâtiments attendus, {len(blocs)}")
		return False
	poste = next((b for b in blocs if min(y for _, y in b) >= 10), None)
	sout = next((b for b in blocs if max(y for _, y in b) < 10), None)
	r.critere(poste is not None and sout is not None and min(x for x, _ in poste) <= 3
		and max(x for x, _ in sout) < 20,
		"poste de garde au sud-ouest (bord ouest), entrée du souterrain au nord-ouest")
	porte_poste = next(c for c in poste if plan.at(*c) == "D")
	porte_sout = next(c for c in sout if plan.at(*c) == "D")
	r.critere(pos["porte_poste"].cells == [porte_poste] and pos["porte_souterrain"].cells == [porte_sout]
		and pos["from_poste"].cells == [(porte_poste[0], porte_poste[1] + 1)]
		and pos["from_souterrain"].cells == [(porte_sout[0], porte_sout[1] + 1)],
		f"warps et sorties alignés sur les portes {porte_poste} et {porte_sout} (spawn juste en dessous)")

	# 3. Chemin principal.
	dist = monde.distances(entree)
	aller = dist.get(porte_sout, INF)
	vers_poste = dist.get(porte_poste, INF)
	r.critere(aller < INF and vers_poste < INF,
		f"entrée est → porte du souterrain : {aller} pas ; → porte du poste : {vers_poste} pas")
	if aller >= INF or vers_poste >= INF:
		return False
	r.critere(70 <= aller <= 110, f"chemin principal {aller} pas (attendu 70 à 110 : la route se traverse d'un bout à l'autre)")

	def jusqua(m: Carte, cible: Case) -> int:
		return m.distances(entree).get(cible, INF)

	# 4. Dresseurs.
	dresseurs = _role(plan, "dresseur")
	r.critere(sorted(dresseurs) == sorted(R8_DRESSEURS), f"7 Dresseurs D1..D7 : {sorted(dresseurs)}")
	if sorted(dresseurs) != sorted(R8_DRESSEURS):
		return False
	vues: dict[str, list[Case]] = {}
	for role in sorted(dresseurs):
		_ligne_vue_ok(plan, monde, dresseurs[role], vues, role, R8_DRESSEURS[role], r)
	for role in sorted(dresseurs):
		attendu = "oui" if role in R8_INEVITABLES else "non"
		r.critere(dresseurs[role].attrs.get("inevitable") == attendu,
			f"{role} déclaré inevitable={attendu}")
	d4, d5 = dresseurs["D4"], dresseurs["D5"]
	r.critere(d4.cells[0][1] == d5.cells[0][1] and abs(d4.cells[0][0] - d5.cells[0][0]) == 1
		and d4.attrs["facing"] == d5.attrs["facing"],
		f"D4 {d4.cells[0]} et D5 {d5.cells[0]} côte à côte, même direction (combats successifs)")
	for role in R8_INEVITABLES:
		bloque = set(vues[role])
		sans = jusqua(monde.sans(bloque), porte_sout)
		sans_p = jusqua(monde.sans(bloque), porte_poste)
		groupe = [vues[role]] + ([vues["D5" if role == "D4" else "D4"]] if role in ("D4", "D5") else [])
		premiere = premiere_union(monde, entree, groupe)
		if role == "D1":   # D1 ne garde que le souterrain : le poste reste libre
			bon = sans >= INF and sans_p < INF
			txt_p = f"poste : {sans_p} pas (hors de sa vue)"
		else:
			bon = sans >= INF and sans_p >= INF
			txt_p = f"poste : {'fermé' if sans_p >= INF else sans_p}"
		# D4 et D5 : la première case vue est mesurée depuis l'est (on arrive par l'arrivée).
		r.critere(bon and premiere >= DETECTION_MIN,
			f"{role} {dresseurs[role].ident} inévitable (souterrain : {'fermé' if sans >= INF else sans}, "
			f"{txt_p}) ; première case vue à {premiere} cases (attendu ≥ {DETECTION_MIN})")
	tous = set().union(*(vues[x] for x in R8_EVITABLES))
	for role in R8_EVITABLES:
		d = jusqua(monde.sans(vues[role]), porte_sout)
		dp = jusqua(monde.sans(vues[role]), porte_poste)
		r.critere(d < INF and dp < INF,
			f"{role} {dresseurs[role].ident} évitable : souterrain en {d} pas (+{d - aller}), "
			f"poste en {dp} pas hors de sa vue")
	d_tous = jusqua(monde.sans(tous), porte_sout)
	r.critere(d_tous < INF, f"D3, D6 et D7 évitables ensemble : souterrain en {d_tous} pas "
		f"(+{d_tous - aller}) ; seuls D1, D2 et le duo D4 / D5 sont obligatoires")

	# 5. Deux chemins en ③ ; D3 sur le haut, herbes H2 sur le bas.
	iti = _role(plan, "itineraire")
	if sorted(iti) != ["bas", "haut"]:
		r.critere(False, f"coupes itineraire haut et bas attendues : {sorted(iti)}")
		return False
	haut, bas = set(iti["haut"].cells), set(iti["bas"].cells)
	cut_h = {c for c in haut if monde.libre(c)}
	cut_b = {c for c in bas if monde.libre(c)}
	# Coupes (x 38..48) : terrasse y 5..9 pour le chemin haut, y 11..16 pour le bas (y 10 = corniche).
	d_h = jusqua(monde.sans(cut_h), porte_sout)   # haut fermé -> par le bas
	d_b = jusqua(monde.sans(cut_b), porte_sout)   # bas fermé -> par le haut
	d_hb = jusqua(monde.sans(cut_h | cut_b), porte_sout)
	r.critere(d_h < INF and d_b < INF and d_hb >= INF,
		f"deux chemins : par le bas {d_h} pas, par le haut {d_b} pas ; les deux coupés : "
		f"{'fermé' if d_hb >= INF else d_hb}")
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ("H1", "H2", "H3"))
	if len(zones) != 3 or sorted(nommees) != ["H1", "H2", "H3"]:
		r.critere(False, f"zones H1..H3 attendues : {len(zones)} trouvées, nommées {sorted(nommees)}")
		return False
	h1, h2, h3 = nommees["H1"], nommees["H2"], nommees["H3"]
	for n in ("H1", "H2", "H3"):
		print(f"  {n} : {boite(nommees[n])}")
	r.critere(set(vues["D3"]) <= haut and h2 <= bas | {c for c in h2 if c[0] in (x for x, _ in bas)},
		f"D3 {dresseurs['D3'].cells[0]} sur le chemin haut (vue {vues['D3'][0]}..{vues['D3'][-1]}), "
		f"H2 sur le chemin bas")
	# Éviter D3 sans passer par H2 est impossible ; éviter H2 revient à subir D3.
	r.critere(jusqua(monde.sans(set(vues["D3"]) | h2), porte_sout) >= INF,
		"D3 ou les herbes H2 : on ne les évite pas tous les deux (le chemin bas coûte des herbes)")
	h_bas = monde.herbes_min(entree, lambda c: c in h2)
	via_bas = Carte(plan, set(vues["D3"]) | cut_h)
	cout_bas = via_bas.herbes_min(entree, lambda c: c in h2).get(porte_sout, INF)
	r.critere(cout_bas == 8, f"chemin bas : {cout_bas} cases de H2 à traverser (attendu 8)")

	# 6. Hautes herbes.
	g_min = monde.herbes_min(entree, lambda c: c in zones_toutes(zones)).get(porte_sout, INF)
	r.critere(R8_H1[0] <= g_min <= R8_H1[1],
		f"cases de hautes herbes obligatoires jusqu'au souterrain : {g_min} "
		f"(attendu {R8_H1[0]} à {R8_H1[1]}, toutes dans H1)")
	r.critere(jusqua(monde.sans(h1), porte_sout) >= INF and jusqua(monde.sans(h1), porte_poste) >= INF,
		"H1 incontournable (souterrain et poste)")
	r.critere(jusqua(monde.sans(h3), porte_sout) == aller,
		f"H3 évitable sans détour ({jusqua(monde.sans(h3), porte_sout)} pas)")
	r.critere(jusqua(monde.sans(h2), porte_sout) < INF,
		f"H2 évitable (par le chemin haut : {jusqua(monde.sans(h2), porte_sout)} pas)")
	hors = monde.herbes_min(entree, lambda c: c in zones_toutes(zones) and c not in h1).get(porte_sout, INF)
	r.critere(hors == 0, f"aucune case obligatoire hors de H1 (minimum hors : {hors})")

	# 7. Rebord.
	rebords = _composantes(set(plan.cells_of("v")))
	r.critere(len(rebords) == 1, f"{len(rebords)} rebord (corniche)")
	for reb in rebords:
		montable = any(monde.pas((x, y + 1), (0, -1)) is not None for x, y in reb)
		lateral = any(monde.pas((x - dx, y), (dx, 0)) is not None for x, y in reb for dx in (-1, 1))
		saute = all(monde.pas((x, y - 1), (0, 1)) == (x, y + 1) for x, y in reb
			if monde.libre((x, y - 1)) and monde.libre((x, y + 1)))
		x0, y0 = min(reb)
		r.critere(not montable and not lateral and saute,
			f"corniche ({x0}..{max(x for x, _ in reb)}, {y0}) : ne se monte pas, ne se traverse pas "
			f"de côté, se saute vers le sud")
		sans_reb = monde.sans(reb)
		a, b = (43, 9), (43, 11)
		r.critere(monde.distances([a]).get(b, INF) == 1 and sans_reb.distances([a]).get(b, INF) > 2,
			f"le saut de la terrasse (43, 9) au chemin bas (43, 11) : 1 pas contre "
			f"{sans_reb.distances([a]).get(b, INF)} sans la corniche")

	# 8. Objets.
	objets = {**_role(plan, "objet_visible"), **_role(plan, "cache")}
	r.critere(sorted(objets) == ["O1", "O2"] and objets["O1"].kind == "objet_visible"
		and objets["O1"].attrs["item"] == "super_potion" and objets["O2"].kind == "cache"
		and objets["O2"].attrs["item"] == "revive" and "indice" in objets["O2"].attrs,
		"1 Super Potion visible (O1), 1 Rappel caché (O2, type « cache », indice)")
	lignes = {c for p in dresseurs.values() for c in ligne_brute(plan, p)}
	o1, o2 = objets["O1"].cells[0], objets["O2"].cells[0]
	r.critere(36 <= o1[0] <= 55 and 5 <= o1[1] <= 9 and any(c in monde.sans(cut_b).distances(entree) for c in _acces(monde, objets["O1"])),
		f"Super Potion {o1} sur la terrasse du chemin haut, atteinte sans passer par le chemin bas")
	proche = min(max(abs(o2[0] - x), abs(o2[1] - y)) for x, y in rebords[0])
	r.critere(proche <= 1, f"Rappel {o2} à {proche} case de la corniche")
	for role in sorted(objets):
		p = objets[role]
		c = p.cells[0]
		atteint = min((dist.get(a, INF) for a in _acces(monde, p)), default=INF)
		sol = plan.at(*c)
		bon = atteint < INF and sol == "." and c not in lignes
		if p.kind == "cache":
			bon &= p.bloque
		r.critere(bon, f"{role} {p.ident} {c} sur « {sol} » ({p.attrs['item']}) : atteint en "
			f"{atteint} pas, hors des lignes de vue")

	# 9. L'approche d'un Dresseur ne ferme aucun passage.
	cibles = [[porte_sout], [porte_poste], [entree[0]]] + [_acces(monde, p) for p in objets.values()]
	fermes: list[str] = []
	for role, p in sorted(dresseurs.items()):
		for i, v in enumerate(vues[role]):
			if v not in dist:
				continue
			arret = vues[role][i - 1] if i >= 1 else p.cells[0]
			m = Carte(plan)
			m.bloquees.discard(p.cells[0])
			m.bloquees.add(arret)
			d = m.distances([v])
			if any(not any(c in d for c in groupe) for groupe in cibles):
				fermes.append(f"{role} vu en {v} → arrêt {arret}")
	r.critere(not fermes, f"l'approche d'un Dresseur ne ferme aucun passage {fermes[:3] if fermes else ''}")

	# 10. Placement, panneaux, Pas d'arbuste à Couper.
	_placement(r, plan, monde, dist, lignes, entree)
	r.critere(set(plan.cells_of("v")) and not any(p.kind == "arbuste" for p in pos.values()),
		"pas d'arbuste à Couper (dossier §3.1)")
	pan = {p.ident: p for p in plan.of_kind("panneau")}
	r.critere(sorted(pan) == ["panneau_route", "panneau_souterrain"]
		and all(any(a in dist for a in _acces(monde, p)) for p in pan.values()),
		"panneaux « ROUTE 8 » (est) et « PASSAGE SOUTERRAIN » (entrée du souterrain), lisibles")

	n_prat = sum(1 for y in range(plan.height) for x in range(plan.width) if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {n_prat} cases praticables sur {plan.width * plan.height} "
		f"({100 * n_prat / (plan.width * plan.height):.0f} %), herbes "
		f"{', '.join(f'{n} {len(nommees[n])}' for n in ('H1', 'H2', 'H3'))}")
	duree = aller * S_PAR_PAS + 4 * S_COMBAT
	print(f"  traversée estimée est → souterrain : {aller} pas × {S_PAR_PAS} s + 4 combats "
		f"inévitables (D1, D2, D4, D5) × {S_COMBAT} s = {duree:.0f} s ; marche seule "
		f"{aller * S_PAR_PAS:.0f} s")
	return r.ok


def zones_toutes(zones: list[set[Case]]) -> set[Case]:
	return set().union(*zones)


# --- Route 7 ------------------------------------------------------------------------------------

R7_TAILLE = (28, 24)
R7_RACCORD = [(0, 10), (0, 11), (0, 12)]


def verifier_route_7(chemin: Path) -> bool:
	plan, monde, r = _en_tete(chemin, "route_7")
	pos = plan.positions
	r.critere((plan.width, plan.height) == R7_TAILLE, f"taille {plan.width} × {plan.height} (attendu 28 × 24)")
	entree = _bord(plan, monde)
	warps = sorted(pos["warp_ouest"].cells)
	spawns = sorted(pos["from_celadon"].cells)
	r.critere(entree == warps == spawns == R7_RACCORD,
		f"raccord ouest : {entree} praticables, warps {warps}, spawns {spawns} (attendu (0, 10..12))")
	col, rangees = CELADON_RACCORD
	celadon = PLANS / "celadopole.txt"
	celadon = celadon if celadon.exists() else None
	decalage = {y - ry for y, ry in zip(rangees, (10, 11, 12))}
	r.critere(decalage == {11}, f"Céladopole ({col}, {rangees[0]}..{rangees[-1]}) ↔ Route 7 (0, 10..12) : "
		"trois rangées consécutives, décalage de 11, aucune rangée en trop")
	if celadon is not None:
		ville = lire(celadon)
		cases = sorted(c for p in ville.of_kind("warp") for c in p.cells if c[0] == col)
		r.critere(cases == [(col, y) for y in rangees] and ville.width == col + 1,
			f"grille de Céladopole {celadon.name} : sortie ouest-route (69, 21..23) = {cases}")
	else:
		print("  [--] grille de Céladopole absente (autre session) : valeur imposée (69, 21..23) "
			"déclarée, à recouper à la fusion")

	blocs = _batiments(r, plan, monde)
	if len(blocs) != 2:
		r.critere(False, f"2 bâtiments attendus, {len(blocs)}")
		return False
	poste = next((b for b in blocs if max(y for _, y in b) < 10), None)
	sout = next((b for b in blocs if min(y for _, y in b) >= 10), None)
	r.critere(poste is not None and sout is not None and min(x for x, _ in poste) >= 16
		and min(x for x, _ in sout) >= 16,
		"poste de garde à l'est (nord-est), entrée du souterrain au sud-est")
	pp = next(c for c in poste if plan.at(*c) == "D")
	ps = next(c for c in sout if plan.at(*c) == "D")
	r.critere(pos["porte_poste"].cells == [pp] and pos["porte_souterrain"].cells == [ps]
		and pos["from_poste"].cells == [(pp[0], pp[1] + 1)]
		and pos["from_souterrain"].cells == [(ps[0], ps[1] + 1)],
		f"warps et sorties alignés sur les portes {pp} et {ps} (spawn juste en dessous)")
	dist = monde.distances(entree)
	r.critere(dist.get(pp, INF) < INF and dist.get(ps, INF) < INF,
		f"entrée ouest → poste : {dist.get(pp, INF)} pas ; → entrée du souterrain : {dist.get(ps, INF)} pas")
	r.critere(not plan.of_kind("dresseur") and not plan.of_kind("objet_visible")
		and not plan.of_kind("cache"), "aucun Dresseur (RB, dossier §5) ni objet")
	r.critere(not plan.cells_of("v"), "aucun rebord (la pente est de l'art)")
	zones = zones_herbes(plan)
	nommees = nommer_zones(plan, ("H1", "H2"))
	r.critere(len(zones) == 2 and sorted(nommees) == ["H1", "H2"], f"2 zones d'herbes : {sorted(nommees)}")
	if len(zones) != 2 or sorted(nommees) != ["H1", "H2"]:
		return False
	for n, z in nommees.items():
		print(f"  {n} : {boite(z)}")
		bon = all(monde.sans(z).distances(entree).get(c, INF) == dist[c] for c in (pp, ps))
		r.critere(bon, f"{n} évitable sans détour (poste et entrée du souterrain)")
	_placement(r, plan, monde, dist, set(), entree)
	pan = {p.ident for p in plan.of_kind("panneau")}
	r.critere(pan == {"panneau_route", "panneau_souterrain"}, "panneaux « ROUTE 7 » et « PASSAGE SOUTERRAIN »")
	n_prat = sum(1 for y in range(plan.height) for x in range(plan.width) if plan.at(x, y) in plan.praticables)
	print(f"  statistiques : {n_prat} cases praticables sur {plan.width * plan.height} "
		f"({100 * n_prat / (plan.width * plan.height):.0f} %)")
	return r.ok


# --- Souterrain ---------------------------------------------------------------------------------

TUN_TAILLE = (48, 10)


def verifier_souterrain(chemin: Path) -> bool:
	plan, monde, r = _en_tete(chemin, "souterrain_7_8")
	pos = plan.positions
	r.critere((plan.width, plan.height) == TUN_TAILLE, f"taille {plan.width} × {plan.height} (attendu 48 × 10)")
	r.critere(not _bord(plan, monde), "carte fermée : aucune case praticable sur le bord")
	e_ouest = sorted(pos["escalier_ouest"].cells)
	e_est = sorted(pos["escalier_est"].cells)
	r.critere(e_ouest == [(2, 5), (2, 6)] == sorted(c for c in plan.cells_of("E") if c[0] < 10)
		and e_est == [(45, 7), (45, 8)] == sorted(c for c in plan.cells_of("E") if c[0] > 40),
		f"escaliers aux deux bouts : ouest {e_ouest} (Route 7), est {e_est} (Route 8), seuls « E » de la carte")
	s_o, s_e = sorted(pos["from_entree_r7"].cells), sorted(pos["from_entree_r8"].cells)
	r.critere(s_o == [(3, 5), (3, 6)] and s_e == [(44, 7), (44, 8)]
		and all(plan.at(*c) == "." for c in s_o + s_e),
		f"points d'apparition devant chaque escalier : {s_o} et {s_e}")
	dist = monde.distances(s_o)
	long = min(dist.get(c, INF) for c in e_est)
	r.critere(long < INF, f"escalier ouest → escalier est : {long} pas")
	if long >= INF:
		return False
	tout = {c for c, d in dist.items()}
	caches = {c for p in plan.of_kind("cache") for c in p.cells}
	praticables = {(x, y) for y in range(plan.height) for x in range(plan.width)
		if plan.at(x, y) in plan.praticables and (x, y) not in caches}
	r.critere(praticables <= tout | set(e_ouest), f"toutes les cases praticables sont atteignables "
		f"({len(praticables)} cases)")
	# Largeur : chaque case praticable (hors escaliers) est dans un carré 2 × 2 praticable.
	def prat(c: Case) -> bool:
		return plan.at(*c) in plan.praticables
	larges: set[Case] = set()
	for y in range(plan.height - 1):
		for x in range(plan.width - 1):
			carre = [(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)]
			if all(prat(c) for c in carre):
				larges.update(carre)
	etroits = sorted(c for c in praticables if c not in larges)
	r.critere(not etroits, f"couloir de 2 cases de large au moins partout (compagnon) : cases étroites {etroits}")
	large = Carte(plan, {c for c in praticables if c not in larges}).distances(s_o)
	r.critere(min(large.get(c, INF) for c in e_est) == long,
		f"l'itinéraire le plus court ({long} pas) ne passe que par des cases larges")
	# Niche (tiers ouest), coude (milieu), galerie en coude (impasse).
	niche = {c for c in pos["repere_niche"].cells}
	coude = {c for c in pos["repere_coude"].cells}
	galerie = {c for c in pos["repere_galerie"].cells}
	r.critere(all(x < plan.width / 3 for x, _ in niche) and all(plan.width / 3 <= x < 2 * plan.width / 3 for x, _ in coude),
		f"niche au tiers ouest (x {min(x for x, _ in niche)}..{max(x for x, _ in niche)}), "
		f"coude au milieu (x {min(x for x, _ in coude)}..{max(x for x, _ in coude)})")
	# Pas de labyrinthe : retirer la niche ou la galerie ne coupe pas l'itinéraire ; ce sont des impasses.
	sans_n = Carte(plan, niche - {c for c in niche if c[1] >= 5}).distances(s_o)
	sans_g = Carte(plan, galerie).distances(s_o)
	r.critere(min(sans_n.get(c, INF) for c in e_est) == long and min(sans_g.get(c, INF) for c in e_est) == long,
		"la niche et la galerie sont des impasses (l'itinéraire passe sans elles) : pas de labyrinthe")
	# Le coude : l'itinéraire change de rangées (5..6 → 7..8).
	ys_ouest = {y for x, y in large if x < 20 and plan.at(x, y) == "."}
	r.critere({5, 6} <= ys_ouest and plan.at(30, 7) == "." and plan.at(30, 5) == "K",
		"le coude : couloir ouest en rangées 5..6, couloir est en rangées 7..8")
	# Objets cachés.
	objets = _role(plan, "cache")
	r.critere(sorted(objets) == ["O1", "O2"] and objets["O1"].attrs["item"] == "nugget"
		and objets["O2"].attrs["item"] == "super_potion"
		and all("indice" in p.attrs and p.bloque for p in objets.values()),
		"2 objets cachés : Pépite (niche), Super Potion à la place de l'Huile (galerie en coude)")
	r.critere(objets["O1"].cells[0] in niche and objets["O2"].cells[0] in galerie,
		f"Pépite {objets['O1'].cells[0]} dans la niche, Super Potion {objets['O2'].cells[0]} au bout de la galerie")
	for role, p in sorted(objets.items()):
		a = [x for x in _acces(monde, p) if x in dist]
		r.critere(bool(a) and plan.at(*p.cells[0]) == ".",
			f"{role} {p.ident} {p.cells[0]} atteignable de face depuis {a[:2]}")
	r.critere(not plan.of_kind("dresseur") and not plan.of_kind("herbes") and not plan.cells_of("h")
		and not plan.cells_of("v"), "aucun Dresseur, aucune herbe, aucun rebord (aucune rencontre)")
	print(f"  statistiques : {len(praticables)} cases praticables sur {plan.width * plan.height}")
	print(f"  traversée : {long} pas × {S_PAR_PAS} s = {long * S_PAR_PAS:.0f} s")
	return r.ok


# --- Bâtiment d'entrée et poste de garde -------------------------------------------------------

def _interieur(plan: Plan, monde: Carte, r: Rapport) -> list[Case]:
	r.critere((plan.width, plan.height) == (12, 10), f"taille {plan.width} × {plan.height} (attendu 12 × 10)")
	r.critere(not [c for c in _bord(plan, monde)], "carte fermée : aucune case praticable sur le bord")
	sortie = sorted(plan.positions["sortie"].cells)
	r.critere(sortie == [(5, 8), (6, 8)] == sorted(plan.cells_of("X"))
		and sorted(plan.positions["entree"].cells) == sortie,
		f"sortie sur la rangée 8 : {sortie}, spawn « entree » sur les mêmes cases")
	return sortie


def verifier_entree(chemin: Path) -> bool:
	plan, monde, r = _en_tete(chemin, "souterrain_entree")
	pos = plan.positions
	sortie = _interieur(plan, monde, r)
	esc = sorted(pos["escalier"].cells)
	r.critere(esc == [(5, 2), (6, 2)] == sorted(plan.cells_of("E")),
		f"escalier {esc} (cases « E »)")
	dist = monde.distances([(5, 7), (6, 7)])
	r.critere(all(c in dist for c in esc) and all(c in dist for c in sortie),
		f"de la porte à l'escalier : {min(dist.get(c, INF) for c in esc)} pas")
	r.critere(sorted(pos["from_underground"].cells) == [(5, 3), (6, 3)]
		and all(plan.at(*c) == "." for c in pos["from_underground"].cells),
		"retour du souterrain en (5..6, 3), sous l'escalier, tourné ↓")
	hab = [p for p in plan.of_kind("pnj")]
	pan = [p for p in plan.of_kind("panneau")]
	r.critere(len(hab) == 1 and len(pan) == 1 and not plan.of_kind("dresseur"),
		"un habitant, un panneau, aucun Dresseur")
	for p in hab + pan:
		r.critere(any(a in dist for a in _acces(monde, p)) and plan.at(*p.cells[0]) == ".",
			f"{p.ident} {p.cells[0]} atteignable de face")
	r.critere(all(k in pos["sortie"].attrs for k in ("vers_r7", "vers_r8", "spawn_r7", "spawn_r8"))
		and pos["sortie"].attrs["vers_r7"] == "route_7" and pos["sortie"].attrs["vers_r8"] == "route_8",
		"sortie : cibles des deux instances déclarées (route_7 / route_8)")
	return r.ok


def verifier_poste(chemin: Path) -> bool:
	plan, monde, r = _en_tete(chemin, "poste_safrania")
	pos = plan.positions
	sortie = _interieur(plan, monde, r)
	porte = sorted(pos["porte_safrania"].cells)
	garde = pos["garde"].cells[0]
	r.critere(porte == [(5, 2), (6, 2)] == sorted(plan.cells_of("S"))
		and all(not monde.libre(c) for c in porte),
		f"porte de Safrania {porte} fermée (non praticable)")
	r.critere(not [p for p in plan.of_kind("warp") if p.ident != "sortie"],
		"aucun warp vers Safrania (dossier §6 : aucun drapeau, fermée « pour le moment »)")
	devant = [(x, 3) for x, _ in porte]
	barrage = {garde} | {c for c in devant if plan.at(*c) == "B"}
	r.critere(set(devant) <= barrage and garde in devant,
		f"le garde {garde} et la barrière occupent les cases devant la porte : on ne s'en approche pas")
	dist = monde.distances([(5, 7), (6, 7)])
	r.critere(not any(c in dist for c in porte), "la porte de Safrania est inatteignable")
	r.critere(len([p for p in plan.of_kind("pnj")]) == 1 and not plan.of_kind("dresseur"),
		"un seul PNJ (le garde, tourné vers le joueur), aucun Dresseur")
	r.critere(pos["garde"].attrs.get("facing") == "down"
		and any(a in dist for a in _acces(monde, pos["garde"])), "le garde est atteignable de face")
	r.critere(all(k in pos["sortie"].attrs for k in ("vers_r7", "vers_r8", "spawn_r7", "spawn_r8")),
		"sortie : cibles des deux instances déclarées (route_7 / route_8)")
	return r.ok


# --- Raccords entre cartes ----------------------------------------------------------------------

def verifier_raccords() -> bool:
	print("Raccords entre cartes")
	r = Rapport()
	plans = {n: lire(PLANS / f"{n}.txt") for n in
		("route_8", "route_7", "souterrain_7_8", "souterrain_entree", "poste_safrania")}
	cartes = {n: Carte(p) for n, p in plans.items()}
	p8, p7, pt, pe, pp = (plans[n] for n in ("route_8", "route_7", "souterrain_7_8",
		"souterrain_entree", "poste_safrania"))
	k8, k7, kt, ke, kp = (cartes[n] for n in ("route_8", "route_7", "souterrain_7_8",
		"souterrain_entree", "poste_safrania"))

	# Identifiants de cartes : une enveloppe, deux instances.
	def a(p: Plan, ident: str, cle: str) -> str:
		return p.positions[ident].attrs.get(cle, "")

	# 1. Portes de bâtiment <-> sorties d'intérieur.
	for inst, route, pl in (("r8", "route_8", p8), ("r7", "route_7", p7)):
		for porte, env, plan_int, sp in (("porte_souterrain", "underground_entrance", pe, "from_souterrain"),
				("porte_poste", "safrania_gate", pp, "from_poste")):
			w = pl.positions[porte]
			cible = f"{env}_{inst}"
			bon = (a(pl, porte, "vers") == cible and a(pl, porte, "spawn") == "entree"
				and a(plan_int, "sortie", f"vers_{inst}") == route
				and a(plan_int, "sortie", f"spawn_{inst}") == sp
				and sp in pl.positions and "entree" in plan_int.positions)
			sp_cell = pl.positions[sp].cells[0]
			r.critere(bon and sp_cell == (w.cells[0][0], w.cells[0][1] + 1),
				f"{route} {porte} {w.cells[0]} → {cible} (spawn « entree ») ; sortie → {route} spawn "
				f"« {sp} » {sp_cell} (juste sous la porte)")

	# 2. Escaliers <-> bouts du souterrain.
	for inst, bout, spawn_t, esc_t in (("r7", "ouest", "from_entree_r7", "escalier_ouest"),
			("r8", "est", "from_entree_r8", "escalier_est")):
		bon_t = (a(pt, esc_t, "vers") == f"underground_entrance_{inst}"
			and a(pt, esc_t, "spawn") == "from_underground" and "from_underground" in pe.positions)
		bon_e = (a(pe, "escalier", f"vers_{inst}") == "underground_path_7_8"
			and a(pe, "escalier", f"spawn_{inst}") == spawn_t and spawn_t in pt.positions)
		r.critere(bon_t and bon_e,
			f"escalier du souterrain ({bout}) ↔ bâtiment d'entrée {inst} : escalier → spawn « from_underground » "
			f"(5..6, 3) ; escalier du bâtiment → spawn « {spawn_t} » {pt.positions[spawn_t].cells}")
	r.critere(pt.positions["escalier_ouest"].cells[0][0] < pt.width / 2 < pt.positions["escalier_est"].cells[0][0],
		"le bout ouest du souterrain est côté Route 7, le bout est côté Route 8 (RB)")

	# 3. Raccords de bord.
	r.critere(sorted(p7.positions["warp_ouest"].cells) == [(0, 10), (0, 11), (0, 12)]
		and a(p7, "warp_ouest", "vers") == "celadon_city",
		f"Route 7 (0, 10..12) → Céladopole (69, 21..23) [imposé] : décalage de 11")
	r.critere(sorted(p8.positions["raccord_est"].cells) == [(79, 10), (79, 11), (79, 12)],
		"Route 8 (79, 10..12) → Lavanville (0, 10..12) (grille du J18)")

	# 4. Traversée complète (Lavanville → souterrain → Route 7 → Céladopole) et retour.
	def pas(carte: Carte, depart: list[Case], cible: list[Case]) -> int:
		d = carte.distances(depart)
		return min((d.get(c, INF) for c in cible), default=INF)

	def cells(pl: Plan, ident: str) -> list[Case]:
		return pl.positions[ident].cells

	p_r8 = pas(k8, cells(p8, "from_lavender"), cells(p8, "porte_souterrain"))
	p_e8 = pas(ke, cells(pe, "entree"), cells(pe, "escalier"))
	p_t = pas(kt, cells(pt, "from_entree_r8"), cells(pt, "escalier_ouest"))
	p_e7 = pas(ke, cells(pe, "from_underground"), cells(pe, "sortie"))
	p_r7 = pas(k7, cells(p7, "from_souterrain"), cells(p7, "warp_ouest"))
	total = p_r8 + p_e8 + p_t + p_e7 + p_r7
	r.critere(max(p_r8, p_e8, p_t, p_e7, p_r7) < INF,
		f"Lavanville → Céladopole : Route 8 {p_r8} + entrée {p_e8} + souterrain {p_t} + entrée {p_e7} + "
		f"Route 7 {p_r7} = {total} pas ({total * S_PAR_PAS:.0f} s de marche)")
	b_r7 = pas(k7, cells(p7, "from_celadon"), cells(p7, "porte_souterrain"))
	b_e7 = pas(ke, cells(pe, "entree"), cells(pe, "escalier"))
	b_t = pas(kt, cells(pt, "from_entree_r7"), cells(pt, "escalier_est"))
	b_e8 = pas(ke, cells(pe, "from_underground"), cells(pe, "sortie"))
	b_r8 = pas(k8, cells(p8, "from_souterrain"), cells(p8, "raccord_est"))
	retour = b_r7 + b_e7 + b_t + b_e8 + b_r8
	r.critere(max(b_r7, b_e7, b_t, b_e8, b_r8) < INF,
		f"Céladopole → Lavanville : Route 7 {b_r7} + entrée {b_e7} + souterrain {b_t} + entrée {b_e8} + "
		f"Route 8 {b_r8} = {retour} pas")
	# Postes : accessibles depuis chaque route, impasses.
	r.critere(pas(k8, cells(p8, "from_lavender"), cells(p8, "porte_poste")) < INF
		and pas(k7, cells(p7, "from_celadon"), cells(p7, "porte_poste")) < INF,
		"le poste de garde est atteignable depuis chaque route (et n'est qu'une impasse)")
	return r.ok


# --- Programme principal ------------------------------------------------------------------------

VERIFICATEURS = {"route_8": verifier_route_8, "route_7": verifier_route_7,
	"souterrain_7_8": verifier_souterrain, "souterrain_entree": verifier_entree,
	"poste_safrania": verifier_poste}


def main() -> int:
	noms = sys.argv[1:] or list(VERIFICATEURS)
	ok = True
	for n in noms:
		n = Path(n).stem
		if n not in VERIFICATEURS:
			print(f"{n} : aucune règle connue (attendu : {', '.join(VERIFICATEURS)})")
			ok = False
			continue
		bon = VERIFICATEURS[n](PLANS / f"{n}.txt")
		print("Plan conforme." if bon else "Plan NON conforme.")
		ok &= bon
	if not sys.argv[1:]:
		bon = verifier_raccords()
		print("Raccords conformes." if bon else "Raccords NON conformes.")
		ok &= bon
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
