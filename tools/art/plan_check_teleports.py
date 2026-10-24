#!/usr/bin/env python3
"""Contrôle générique des téléporteurs et des portes à carte (`docs/tech/systemes-2.md` §2.9, §2.10, T27).

Réutilisable par les jalons de contenu (J26 Sylphe SARL, J27 Arène de Morgane) sur leurs propres
grilles (une ou plusieurs cartes ; les téléporteurs peuvent changer de carte). Vérifie :

- chaque téléporteur (`teleporteur`, `vers=<carte>:<spawn>`) mène à un point d'apparition qui
  existe et qui est praticable ; chaque « T » de la grille porte un téléporteur ; un téléporteur ne
  mène pas sur sa propre case ; **arriver sur un téléporteur ne le déclenche pas** (aucune boucle :
  seul un pas sur la case transporte) ;
- **paires** (attribut facultatif `paire=X`) : chaque paire compte exactement deux téléporteurs,
  réciproques (A mène sur ou à côté de B, et B sur ou à côté de A) ; aucune paire orpheline ;
- but atteignable depuis le départ ; Carte Magnétique (objet `item=card_key`) atteignable sans
  porte ; quand il y a des portes, but inatteignable sans la carte ; retour au départ toujours
  possible depuis tout état atteignable (états = carte, case, carte en poche) ;
- **graphe des salles** imprimé pour la revue : composantes connexes de cases praticables à pied
  (sans téléportation, portes `K` comptées comme murs), arêtes = téléporteurs et portes ; pour
  chaque salle, les salles atteignables et par quoi ; une salle isolée (avec point d'apparition,
  téléporteur, but ou carte) est refusée.

Le contrôle de base (états, but, carte, retour) est celui de `plan_check_systemes2.py`
(`verifier_teleporteurs`), importé ici.

Usage : python3 -I tools/art/plan_check_teleports.py [grille.txt ...]   (sans argument : grilles d'essai
        tests/fixtures/plans/essai_teleport*.txt, anciennes cartes de QA retirées en S2Z)
        python3 -I tools/art/plan_check_teleports.py --autotest        (le contrôle refuse des pièges connus)
Code 1 si un critère échoue.
"""
from __future__ import annotations

import sys
import tempfile
from collections import defaultdict, deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_check_systemes2 import (  # noqa: E402
	DIRECTIONS, PLANS, Case, Rapport, _bloquees, _cases, _dans, _plus, verifier_teleporteurs,
)
from plan_grille import lire  # noqa: E402


def _proches(a: Case, b: Case) -> bool:
	"""Sur la case ou à côté (distance de Manhattan <= 1)."""
	return abs(a[0] - b[0]) + abs(a[1] - b[1]) <= 1


def _pads(plans: dict) -> dict:
	"""(carte, case) -> (ident, carte d'arrivée, case d'arrivée) pour les téléporteurs valides."""
	spawns = {(carte, p.ident): p.cells[0] for carte, plan in plans.items()
		for p in plan.positions.values() if p.kind in ("spawn", "depart")}
	pads = {}
	for carte, plan in plans.items():
		for p in plan.of_kind("teleporteur"):
			vers = p.attrs.get("vers", "")
			if ":" not in vers:
				continue
			cible = tuple(vers.split(":", 1))
			if cible in spawns:
				pads[(carte, p.cells[0])] = (p.ident, cible[0], spawns[cible])
	return pads


def verifier_paires(plans: dict, pads: dict, r: Rapport) -> None:
	groupes: dict[str, list] = defaultdict(list)
	for carte, plan in plans.items():
		for p in plan.of_kind("teleporteur"):
			if p.attrs.get("paire"):
				groupes[p.attrs["paire"]].append((carte, p))
	for nom, membres in sorted(groupes.items()):
		if not r.ok(len(membres) == 2,
				f"paire « {nom} » : {len(membres)} téléporteur(s) au lieu de 2 (paire orpheline)"):
			continue
		(ca, a), (cb, b) = membres
		da = pads.get((ca, a.cells[0]))
		db = pads.get((cb, b.cells[0]))
		if da is None or db is None:
			continue  # déjà signalé par le contrôle de base
		ok_ab = da[1] == cb and _proches(da[2], b.cells[0])
		ok_ba = db[1] == ca and _proches(db[2], a.cells[0])
		r.ok(ok_ab and ok_ba,
			f"paire « {nom} » non réciproque : {ca}/{a.ident} -> {da[1]} {da[2]} "
			f"et {cb}/{b.ident} -> {db[1]} {db[2]} (chacun doit arriver sur ou à côté de l'autre)")
		if ok_ab and ok_ba:
			r.note(f"paire « {nom} » : {ca}/{a.ident} <-> {cb}/{b.ident}")


def _graphe_salles(plans: dict, pads: dict, r: Rapport) -> None:
	portes = {(carte, c) for carte, plan in plans.items() for c in plan.cells_of("K")}
	fixes = {carte: _bloquees(plan, ("porte_carte",)) for carte, plan in plans.items()}

	def libre(carte: str, c: Case) -> bool:
		plan = plans[carte]
		return (_dans(plan, c) and plan.at(*c) in plan.praticables and c not in fixes[carte]
			and (carte, c) not in portes and (carte, c) not in pads)

	salle: dict[tuple[str, Case], int] = {}
	nb = 0
	for carte, plan in plans.items():
		for y in range(plan.height):
			for x in range(plan.width):
				if (carte, (x, y)) in salle or not libre(carte, (x, y)):
					continue
				salle[(carte, (x, y))] = nb
				file = deque([(x, y)])
				while file:
					c = file.popleft()
					for d in DIRECTIONS:
						n = _plus(c, d)
						if libre(carte, n) and (carte, n) not in salle:
							salle[(carte, n)] = nb
							file.append(n)
				nb += 1
	for carte, c in sorted(pads):  # un téléporteur fait partie de la salle de ses voisines
		for d in DIRECTIONS:
			if (carte, _plus(c, d)) in salle:
				salle[(carte, c)] = salle[(carte, _plus(c, d))]
				break
		else:
			salle[(carte, c)] = nb
			nb += 1
	noms: dict[int, str] = {}
	compte: dict[str, int] = defaultdict(int)
	for (carte, c), i in sorted(salle.items(), key=lambda kv: (kv[0][0], kv[0][1][1], kv[0][1][0])):
		if i not in noms:
			compte[carte] += 1
			noms[i] = f"{carte}#{compte[carte]}"
	contenu: dict[int, list[str]] = defaultdict(list)
	arcs: dict[int, list] = defaultdict(list)  # salle -> [(cible, libellé, porte ?)]
	for carte, plan in plans.items():
		for p in plan.positions.values():
			if p.kind in ("depart", "but", "spawn"):
				i = salle.get((carte, p.cells[0]))
				if i is not None:
					contenu[i].append(p.kind if p.kind != "spawn" else f"arrivée {p.ident}")
	cartes_salles: set[int] = set()
	for carte, plan in plans.items():
		for p in plan.of_kind("objet"):
			if p.attrs.get("item") == "card_key":
				for c in p.cells:
					for d in DIRECTIONS:
						i = salle.get((carte, _plus(c, d)))
						if i is not None:
							cartes_salles.add(i)
							if "carte magnétique" not in contenu[i]:
								contenu[i].append("carte magnétique")
	for (carte, c), (ident, cc, dest) in sorted(pads.items()):
		a = salle[(carte, c)]
		b = salle.get((cc, dest))
		contenu[a].append(f"téléporteur {ident}")
		if b is not None:
			arcs[a].append((b, f"téléporteur {ident} {c}", False))
	for carte, c in sorted(portes):
		voisines = sorted({salle[(carte, _plus(c, d))] for d in DIRECTIONS if (carte, _plus(c, d)) in salle})
		for a in voisines:
			for b in voisines:
				if a != b:
					arcs[a].append((b, f"porte K {carte} {c}", True))
	departs = [salle.get((carte, p.cells[0])) for carte, plan in plans.items() for p in plan.of_kind("depart")]
	debut = departs[0] if len(departs) == 1 and departs[0] is not None else None

	def atteignables(depart: int, portes_ouvertes: bool) -> set[int]:
		vus = {depart}
		file = deque([depart])
		while file:
			a = file.popleft()
			for b, _, porte in arcs[a]:
				if (portes_ouvertes or not porte) and b not in vus:
					vus.add(b)
					file.append(b)
		return vus

	sans = atteignables(debut, False) if debut is not None else set()
	avec = atteignables(debut, True) if debut is not None and (cartes_salles & sans or not portes) else sans
	r.note(f"graphe des salles : {len(noms)} salle(s)")
	for i in sorted(noms, key=lambda k: noms[k]):
		etat = "" if debut is None else (" [sans carte]" if i in sans else
			" [avec carte]" if i in avec else " [INATTEIGNABLE]")
		r.note(f"  {noms[i]}{etat} : {', '.join(contenu[i]) or 'vide'}")
		for b, par, porte in sorted(arcs[i], key=lambda t: (noms[t[0]], t[1])):
			r.note(f"      -> {noms[b]} par {par}{' (exige la carte)' if porte else ''}")
		if debut is not None:
			r.ok(i in avec or not contenu[i],
				f"salle {noms[i]} isolée (inatteignable depuis le départ) : {', '.join(contenu[i])}")


def verifier_teleports(chemins: list[Path]) -> Rapport:
	plans = {c.stem: lire(c) for c in chemins}
	r = Rapport("Téléporteurs (générique) : " + ", ".join(c.name for c in chemins))
	verifier_teleporteurs(chemins, r)
	pads = _pads(plans)
	for (carte, c), (ident, cc, dest) in sorted(pads.items()):
		r.ok(not (cc == carte and dest == c), f"{carte}/{ident} : mène sur sa propre case (boucle)")
	verifier_paires(plans, pads, r)
	_graphe_salles(plans, pads, r)
	return r


# --- Autotest -------------------------------------------------------------------------------------

_BON = """PRATICABLES .TK
GRILLE 14 5
00 ##############
01 #...T#....#T.#
02 #....K....#..#
03 #o...#....#..#
04 ##############
FIN
POSITIONS
depart  depart       2,2   libre
arr_a   spawn        4,1   libre
arr_r   spawn        11,1  libre
tp_a    teleporteur  4,1   libre   vers=bon:arr_r  paire=p
tp_r    teleporteur  11,1  libre   vers=bon:arr_a  paire=p
carte   objet        1,3   bloque  item=card_key
porte   porte_carte  5,2   bloque  cle=card_key
but     but          8,2   libre
FIN
"""


def _variante(texte: str, *remplacements: tuple[str, str]) -> str:
	for ancien, nouveau in remplacements:
		assert ancien in texte, ancien
		texte = texte.replace(ancien, nouveau)
	return texte


_PIEGES = [
	("spawn_inexistant", "n'existe pas",
		_variante(_BON, ("vers=bon:arr_r", "vers=bon:fantome"))),
	("paire_orpheline", "paire orpheline",
		_variante(_BON, ("vers=bon:arr_a  paire=p", "vers=bon:arr_a"))),
	("paire_non_reciproque", "non réciproque",
		_variante(_BON, ("arr_a   spawn        4,1", "arr_a   spawn        12,3"),
			("vers=bon:arr_r  paire=p", "vers=bon:arr_r  paire=p"))),
	("salle_sans_retour", "retour au départ",
		_variante(_BON, ("tp_r    teleporteur  11,1  libre   vers=bon:arr_a  paire=p\n", ""),
			("#...T#....#T.#", "#...T#....#..#"), ("  paire=p", ""))),
	("but_sans_carte", "le but exige la carte",
		_variante(_BON, ("02 #....K....#..#", "02 #....K....#..#"),
			("01 #...T#....#T.#", "01 #...T.....#T.#"))),
	("t_sans_teleporteur", "sans téléporteur",
		_variante(_BON, ("tp_r    teleporteur  11,1  libre   vers=bon:arr_a  paire=p\n", ""),
			("  paire=p", ""))),
]


def autotest() -> bool:
	ok = True
	with tempfile.TemporaryDirectory() as dossier:
		chemin = Path(dossier) / "bon.txt"
		chemin.write_text(_BON, encoding="utf-8")
		r = verifier_teleports([chemin])
		bon = not r.echecs
		print(f"autotest grille_correcte : {'acceptée comme attendu' if bon else 'REFUSÉE : ' + str(r.echecs)}")
		ok = ok and bon
		for nom, attendu, texte in _PIEGES:
			chemin = Path(dossier) / "bon.txt"  # le « vers=bon:… » désigne la carte « bon »
			chemin.write_text(texte, encoding="utf-8")
			r = verifier_teleports([chemin])
			refuse = any(attendu in e for e in r.echecs)
			print(f"autotest {nom} : {'refusé comme attendu' if refuse else 'NON REFUSÉ ' + str(r.echecs)}")
			ok = ok and refuse
	return ok


# Grilles d'essai par défaut (anciennes cartes de QA de la passe, retirées en S2Z).
ESSAIS = Path(__file__).resolve().parents[2] / "tests" / "fixtures" / "plans"


def main() -> int:
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	if "--autotest" in sys.argv:
		return 0 if autotest() else 1
	chemins = [Path(a) for a in args] or [ESSAIS / "essai_teleport.txt",
		ESSAIS / "essai_teleport_2.txt"]
	ok = verifier_teleports(chemins).imprimer()
	print("TOUT EST CONFORME" if ok else "NON CONFORME")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
