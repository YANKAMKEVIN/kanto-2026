#!/usr/bin/env python3
"""Données des Îles Écume, générées depuis les grilles (jalon 24, T9 ; plan jalon-24 §2.6, §2.11 ;
dossier 27 §7).

Lit les cinq grilles `tools/plans/seafoam_{1f,b1f,b2f,b3f,b4f}.txt` avec le lecteur et les règles de
`tools/art/plan_check_j24_seafoam.py` (même module : aucune règle n'est recopiée ici) et écrit :

1. `data/world/seafoam.json` (lu par `SeafoamState`) : par étage, les trous (numéro, case, drapeau,
   étage visé), les points de chute des rochers venus du dessus (case, eau ou sol, trou de l'étage
   qui les retire : règle du « rocher désigné », dossier §7.3), les atterrissages du joueur (Surf
   forcé ou non), les rochers d'origine (ordre, trou désigné), les courants (cases et direction,
   sources, drapeaux qui les coupent, fin : passage ou rive), les cases « Surf forcé » (cases `s` et
   atterrissages dans l'eau) et l'escalier interdit au Surf tant qu'un courant est actif (T-14).
2. `tests/fixtures/seafoam/seafoam_reference.json` (lu par `test_seafoam_state.gd`) : les résultats
   du contrôle Python, pour que les classes GDScript donnent les mêmes : état de chaque étage pour
   les 256 combinaisons de drapeaux, explorations par poussée (nombre de configurations de rochers,
   d'états, impasses, trous que l'on peut boucher), combinaisons atteignables de la solution et leurs
   suites, une solution complète (poussées).

Avant d'écrire, l'outil vérifie que la reconstruction des étages faite depuis le JSON est identique à
`configuration()` du contrôle pour les 256 combinaisons (sinon : code 1, rien n'est écrit).

Fichiers **générés** : en cas de conflit de fusion, régénérer, ne jamais fusionner à la main.
Usage : python3 -I tools/gen_seafoam_data.py   (≈ 10 s : il refait l'exploration du contrôle)
"""
from __future__ import annotations

import contextlib
import io
import json
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RACINE / "tools" / "art"))
import plan_check_j24_seafoam as pc  # noqa: E402

SORTIE_DONNEES = RACINE / "data" / "world" / "seafoam.json"
SORTIE_REFERENCE = RACINE / "tests" / "fixtures" / "seafoam" / "seafoam_reference.json"
NOMS_DIRECTIONS = {(0, -1): "up", (0, 1): "down", (-1, 0): "left", (1, 0): "right"}
# Étages dont les rochers tombés du dessus sont « libres » et désignés par le trou de même numéro
# (dossier §7.3 : B1F et B2F). Au B3F et au B4F, les rochers tombés sont dans l'eau et restent.
ETAGES_ROCHERS_TOMBES_DESIGNES = ("B1F", "B2F")


def _xy(e: pc.Etage, i: int) -> list[int]:
	x, y = e.xy(i)
	return [x, y]


def _masque_vers_flags(masque: int) -> frozenset:
	return frozenset(t for k, t in enumerate(pc.TROUS) if masque >> k & 1)


def _drapeaux_courant(nom: str) -> list[str]:
	"""Drapeaux qui, tous posés, coupent le courant de l'étage (règle de `configuration`)."""
	haut = {"B3F": "B2F", "B4F": "B3F"}[nom]
	return [pc.nom_drapeau(haut, n) for n in (1, 2)]


def donnees_etage(e: pc.Etage) -> dict:
	nom = e.nom
	i_etage = pc.ETAGES.index(nom)
	carte = pc.CARTES[nom]
	holes = []
	for n in sorted(e.trous):
		bas = pc.ETAGES[i_etage + 1]
		holes.append({"n": n, "cell": _xy(e, e.trous[n]), "flag": pc.nom_drapeau(nom, n),
			"falls_to": pc.CARTES[bas]})
	fall_points = []
	landings = []
	if i_etage > 0:
		haut = pc.ETAGES[i_etage - 1]
		for n in sorted(e.f_cases):
			fall_points.append({"from_flag": pc.nom_drapeau(haut, n), "cell": _xy(e, e.f_cases[n]),
				"water": e.f_cases[n] in e.f_eau,
				"hole": n if nom in ETAGES_ROCHERS_TOMBES_DESIGNES else 0})
		for n in sorted(e.atterrissages):
			landings.append({"from_flag": pc.nom_drapeau(haut, n),
				"cell": _xy(e, e.atterrissages[n]), "surf": e.atterr_surf[n]})
	boulders = [{"cell": _xy(e, c), "hole": e.rocher_trou.get(c, 0)} for c in e.rochers0]
	currents = []
	for ident in sorted(e.courants):
		p = e.courants[ident]
		g = pc.graphe(e, frozenset(), True)
		sources = [e.idx(c) for c in p.cells]
		fins = {g.glisse(s) for s in sources}
		assert len(fins) == 1, f"{nom} courant {ident} : plusieurs fins"
		fin = next(iter(fins))
		if fin in e.passages:
			end = {"kind": "warp", "cell": _xy(e, fin), "pair": e.passages[fin].attrs["paire"]}
		else:
			end = {"kind": "land", "cell": _xy(e, fin)}
		currents.append({
			"id": ident,
			"cells": [{"cell": _xy(e, i), "dir": NOMS_DIRECTIONS[e.fleche[i]]} for i in sorted(e.fleche)],
			"sources": [_xy(e, s) for s in sources],
			"stopped_by": _drapeaux_courant(nom),
			"end": end,
		})
	forced = sorted({i for i, c in enumerate(e.car) if c == "s"}
		| {e.atterrissages[n] for n in e.atterrissages if e.atterr_surf[n]})
	forbidden = []
	for p in e.plan.positions.values():
		if p.kind == "surf_interdit":
			ident = int(p.attrs["tant_que"].split("_")[-1])
			forbidden.append({"cell": list(p.cells[0]), "while_current": ident})
	return {
		"map": carte,
		"holes": holes,
		"fall_points": fall_points,
		"landings": landings,
		"boulders": boulders,
		"currents": currents,
		"forced_surf": [_xy(e, i) for i in forced],
		"surf_forbidden": forbidden,
	}


def reconstruire(etage: dict, flags_poses: set[str]) -> tuple[list[tuple[int, int]], list[int], dict]:
	"""Reconstruction depuis le JSON (même règle que `SeafoamState`) : rochers, trous bouchés, courants."""
	plugged = sorted(h["n"] for h in etage["holes"] if h["flag"] in flags_poses)
	rocks = []
	for b in etage["boulders"]:
		if b["hole"] == 0 or b["hole"] not in plugged:
			rocks.append(tuple(b["cell"]))
	for f in etage["fall_points"]:
		if f["from_flag"] in flags_poses and (f["hole"] == 0 or f["hole"] not in plugged):
			rocks.append(tuple(f["cell"]))
	courants = {c["id"]: not all(fl in flags_poses for fl in c["stopped_by"]) for c in etage["currents"]}
	return rocks, plugged, courants


def verifier_reconstruction(etages: dict[str, pc.Etage], donnees: dict) -> list[str]:
	erreurs = []
	for masque in range(256):
		flags = _masque_vers_flags(masque)
		poses = {pc.nom_drapeau(f, n) for f, n in flags}
		for nom, e in etages.items():
			rocks, plugged, courant = pc.configuration(e, flags)
			r2, p2, c2 = reconstruire(donnees["floors"][pc.CARTES[nom]], poses)
			attendu_rocks = sorted(e.xy(c) for c in rocks)
			if sorted(r2) != attendu_rocks or len(r2) != len(set(r2)):
				erreurs.append(f"{masque} {nom} : rochers {sorted(r2)} ≠ {attendu_rocks}")
			if p2 != sorted(plugged):
				erreurs.append(f"{masque} {nom} : trous bouchés {p2} ≠ {sorted(plugged)}")
			actif = any(c2.values())
			if actif != courant:
				erreurs.append(f"{masque} {nom} : courant {actif} ≠ {courant}")
	return erreurs


def departs_exploration(e: pc.Etage, rocks, plugged, courant) -> list[int]:
	"""Les départs de `verifier_anti_blocage` (même calcul)."""
	g = pc.graphe(e, plugged, courant)
	departs = sorted(set(e.spawns.values()) | set(e.atterrissages.values()))
	starts: list[int] = []
	for s in departs:
		if s in rocks:
			continue
		if courant and s in e.fleche and e.eau(s):
			s = g.glisse(s)
		if s in g.terminaux or s in rocks:
			continue
		starts.append(s)
	if e.nom == "1F":
		starts += [s for s in (e.spawns["EO"], e.spawns["EE"]) if s not in starts]
	return starts


def reference(etages: dict[str, pc.Etage], donjon: pc.Donjon) -> dict:
	configurations = {}
	for masque in range(256):
		flags = _masque_vers_flags(masque)
		par_etage = {}
		for nom, e in etages.items():
			rocks, plugged, courant = pc.configuration(e, flags)
			par_etage[pc.CARTES[nom]] = {"boulders": sorted(_xy(e, c) for c in rocks),
				"plugged": sorted(plugged), "current": courant}
		configurations[str(masque)] = par_etage
	explorations = []
	for nom in pc.ETAGES:
		e = etages[nom]
		for (rocks, plugged, courant) in sorted(pc.configs_distinctes(etages, nom),
				key=lambda t: (sorted(t[1]), sorted(t[0]), t[2])):
			starts = departs_exploration(e, rocks, plugged, courant)
			ex = pc.explorer(e, plugged, rocks, courant, starts)
			fillable = sorted({n for p in ex.plugged_atteints for n in p} - set(plugged))
			explorations.append({"map": pc.CARTES[nom], "boulders": sorted(_xy(e, c) for c in rocks),
				"plugged": sorted(plugged), "current": courant, "starts": sorted(_xy(e, s) for s in set(starts)),
				"configs": len(ex.configs), "states": ex.etats, "impasses": len(ex.impasses),
				"fillable": fillable})
	# Solution : combinaisons atteignables (parcours de `verifier_solution`), sans l'affichage.
	with contextlib.redirect_stdout(io.StringIO()):
		sol = pc.verifier_solution(pc.Rapport(), etages, donjon)
	masques = {fl: sum(1 << k for k, t in enumerate(pc.TROUS) if t in fl) for fl in sol["atteignables"]}
	successeurs = {}
	for fl, suivants in sol["suivants"].items():
		successeurs[str(masques[fl])] = sorted(
			[pc.CARTES[f], n] for f, n in (next(iter(s - fl)) for s in suivants))
	solution = []
	tous = frozenset(pc.TROUS)
	f = tous
	parent = sol["parent"]
	etapes = []
	while parent[f] is not None:
		prec, chute = parent[f]
		etapes.append((prec, chute, f))
		f = prec
	etapes.reverse()
	for prec, (nom, n), fl in etapes:
		e = etages[nom]
		rocks, plugged, courant = pc.configuration(e, prec)
		starts = departs_exploration(e, rocks, plugged, courant)
		ex = pc.explorer(e, plugged, rocks, courant, starts)
		ck = next(k for p, k in ex.plugged_atteints.items() if (p - plugged) == {n})
		pousses = pc.chemin_pousses(e, ex, ck)
		solution.append({"map": pc.CARTES[nom], "hole": n, "mask_before": masques[prec],
			"pushes": [{"boulder": _xy(e, r), "dir": NOMS_DIRECTIONS[d]} for r, d, _ in pousses]})
	return {
		"_doc": "Généré par tools/gen_seafoam_data.py depuis tools/art/plan_check_j24_seafoam.py : ne pas "
			"éditer. Masque : bit k = drapeau mask_order[k].",
		"mask_order": [pc.nom_drapeau(f, n) for f, n in pc.TROUS],
		"configurations": configurations,
		"explorations": explorations,
		"reachable_masks": sorted(masques.values()),
		"successors": successeurs,
		"solution": solution,
	}


def _ecrire(chemin: Path, contenu: dict, compact: bool = False) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	if compact:
		texte = json.dumps(contenu, ensure_ascii=False, separators=(",", ":"))
	else:
		texte = json.dumps(contenu, ensure_ascii=False, indent="\t")
		# Une case [x, y] sur une ligne.
		texte = re.sub(r"\[\s+(-?\d+),\s+(-?\d+)\s+\]", r"[\1, \2]", texte)
	chemin.write_text(texte + "\n", encoding="utf-8")


def main() -> int:
	etages = pc.charger()
	donjon = pc.Donjon(etages)
	donnees = {
		"_doc": "Îles Écume (jalon 24, dossier 27 §7, jalon-24.md §2.6) : fichier GÉNÉRÉ par "
			"tools/gen_seafoam_data.py depuis les grilles tools/plans/seafoam_*.txt (ne pas éditer à la "
			"main ; en cas de conflit, régénérer). Lu par SeafoamState. Cases [x, y] de la grille "
			"(30 × 18, 1:1). hole des rochers et des points de chute : trou de l'étage qui les retire "
			"quand il est bouché (« rocher désigné », §7.3 ; 0 : aucun). Un courant est actif tant que "
			"ses drapeaux stopped_by ne sont pas TOUS posés. forced_surf : arrivées dans l'eau (cases s, "
			"atterrissages dans l'eau). surf_forbidden : SURFER refusé (T-14) tant que le courant est actif.",
		"hole_flags": [pc.nom_drapeau(f, n) for f, n in pc.TROUS],
		"floors": {pc.CARTES[nom]: donnees_etage(etages[nom]) for nom in pc.ETAGES},
	}
	erreurs = verifier_reconstruction(etages, donnees)
	if erreurs:
		print("ÉCHEC : la reconstruction depuis le JSON diffère du contrôle :")
		print("\n".join(erreurs[:20]))
		return 1
	ref = reference(etages, donjon)
	_ecrire(SORTIE_DONNEES, donnees)
	_ecrire(SORTIE_REFERENCE, ref, compact=True)
	print(f"Écrit {SORTIE_DONNEES.relative_to(RACINE)} et {SORTIE_REFERENCE.relative_to(RACINE)} "
		f"(256 combinaisons vérifiées, {len(ref['explorations'])} explorations, "
		f"{len(ref['reachable_masks'])} combinaisons atteignables).")
	return 0


if __name__ == "__main__":
	sys.exit(main())
