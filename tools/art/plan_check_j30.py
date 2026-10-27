#!/usr/bin/env python3
"""Contrôle des grilles de la Ligue (jalon 30, T2 ; `docs/tech/jalon-30.md` §2.1, §2.2).

Six salles, dans l'ordre : `league_lorelei` (Olga), `league_bruno` (Aldo), `league_agatha`,
`league_lance` (Peter), `league_champion`, `hall_of_fame` (Panthéon). Le hall du Plateau
(`indigo_plateau_lobby`) est une carte du J29, hors grilles du jalon.

- **Chaîne** : hall → 5 salles → Panthéon. Chaque salle de combat a **une seule** entrée (porte
  sud, vers la salle d'avant ou le hall) et **une seule** sortie (porte nord, vers la suivante) ;
  le Panthéon n'a aucune porte (la cérémonie enchaîne sur le générique). Chaque warp vise un point
  d'apparition existant, sur une case praticable.
- **Conditions** (`LeagueAttempt`) : la porte nord de l'étape k s'ouvre `si=league_stage_k_cleared` ;
  la porte sud est fermée pendant la tentative (`unless=league_attempt_active`) ; le dresseur de
  l'étape k est celui de `LeagueAttempt.TRAINERS` (et de `data/trainers/league.json`).
- **Accessibilité** : depuis l'entrée, membres et Chen étant des obstacles, on atteint la case
  devant le membre (pour lui parler) et la porte nord ; depuis `from_north` aussi ; au Panthéon,
  la case devant Chen. Aucune case de sol isolée (tout le sol est atteignable depuis l'entrée).
- **Combat inévitable** : on n'atteint pas la porte nord sans passer sur le déclencheur d'appel
  (`appel_<membre>`, `combat=<dresseur>` : RB amène le joueur devant le membre) ou dans sa vue —
  ceinture et bretelles : la porte est de toute façon fermée tant qu'il n'est pas battu.

Usage : python3 -I tools/art/plan_check_j30.py            (contrôle complet)
        python3 -I tools/art/plan_check_j30.py --autotest (le contrôle refuse des pièges connus)
Code 1 si un critère échoue.
"""
from __future__ import annotations

import copy
import json
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from plan_grille import Plan, lire  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"
Case = tuple[int, int]
DIRECTIONS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
FACING = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0)}

# Carte du jeu → grille, dans l'ordre de la tentative.
SALLES = {
	"league_lorelei": "ligue_olga",
	"league_bruno": "ligue_aldo",
	"league_agatha": "ligue_agatha",
	"league_lance": "ligue_peter",
	"league_champion": "ligue_champion",
	"hall_of_fame": "pantheon",
}
ORDRE = list(SALLES)
HALL = "indigo_plateau_lobby"
# LeagueAttempt.TRAINERS (game/systems/league/league_attempt.gd).
DRESSEURS = ["league_lorelei", "league_bruno", "league_agatha", "league_lance", "rival_champion"]


def _plus(c: Case, d: Case) -> Case:
	return (c[0] + d[0], c[1] + d[1])


def _praticable(plan: Plan, c: Case) -> bool:
	return 0 <= c[0] < plan.width and 0 <= c[1] < plan.height and plan.at(*c) in plan.praticables


def _obstacles(plan: Plan) -> set[Case]:
	return {c for p in plan.positions.values() if p.bloque for c in p.cells}


def _atteignables(plan: Plan, depart: Case, interdites: set[Case]) -> set[Case]:
	vu = {depart}
	file = deque([depart])
	while file:
		c = file.popleft()
		for d in DIRECTIONS:
			n = _plus(c, d)
			if n not in vu and n not in interdites and _praticable(plan, n):
				vu.add(n)
				file.append(n)
	return vu


def _vue(plan: Plan, membre) -> set[Case]:
	d = FACING[membre.attrs.get("facing", "down")]
	portee = int(membre.attrs.get("sight", "0"))
	vue: set[Case] = set()
	c = membre.cells[0]
	for _ in range(portee):
		c = _plus(c, d)
		if not _praticable(plan, c):
			break
		vue.add(c)
	return vue


def controler(plans: dict[str, Plan], dresseurs_json: set[str]) -> list[str]:
	erreurs: list[str] = []
	for i, ident in enumerate(ORDRE):
		plan = plans[ident]
		nom = SALLES[ident]
		warps = plan.of_kind("warp")
		spawns = {p.ident: p for p in plan.of_kind("spawn")}
		obstacles = _obstacles(plan)
		entree = spawns.get("from_south")
		if entree is None or not _praticable(plan, entree.cells[0]):
			erreurs.append(f"{nom} : pas d'entrée « from_south » praticable")
			continue
		depart = entree.cells[0]
		tout = _atteignables(plan, depart, set())
		sol = {(x, y) for y in range(plan.height) for x in range(plan.width)
			if _praticable(plan, (x, y))}
		if sol - tout:
			erreurs.append(f"{nom} : sol isolé {sorted(sol - tout)[:6]}")
		libres = _atteignables(plan, depart, obstacles)
		if ident == "hall_of_fame":
			if warps:
				erreurs.append(f"{nom} : le Panthéon n'a pas de porte ({[w.ident for w in warps]})")
			chen = plan.positions.get("chen")
			if chen is None:
				erreurs.append(f"{nom} : Chen absent")
			elif _plus(chen.cells[0], FACING[chen.attrs.get("facing", "down")]) not in libres:
				erreurs.append(f"{nom} : la case devant Chen est inaccessible")
			continue
		# Une seule entrée, une seule sortie.
		noms = sorted(w.ident for w in warps)
		if noms != ["porte_nord", "porte_sud"]:
			erreurs.append(f"{nom} : warps {noms} au lieu de porte_nord + porte_sud")
			continue
		sud, nord = plan.positions["porte_sud"], plan.positions["porte_nord"]
		precedente = HALL if i == 0 else ORDRE[i - 1]
		carte_sud = sud.attrs.get("vers", ":").split(":")[0]
		if carte_sud != precedente:
			erreurs.append(f"{nom} : la porte sud mène à {carte_sud}, pas à {precedente}")
		if sud.attrs.get("unless") != "league_attempt_active":
			erreurs.append(f"{nom} : porte sud non fermée pendant la tentative")
		carte_nord, spawn_nord = nord.attrs.get("vers", ":").split(":")
		if carte_nord != ORDRE[i + 1]:
			erreurs.append(f"{nom} : la porte nord mène à {carte_nord}, pas à {ORDRE[i + 1]}")
		elif spawn_nord not in {p.ident for p in plans[carte_nord].of_kind("spawn")}:
			erreurs.append(f"{nom} : point d'arrivée {carte_nord}:{spawn_nord} absent")
		if nord.attrs.get("si") != f"league_stage_{i}_cleared":
			erreurs.append(f"{nom} : porte nord sans « si=league_stage_{i}_cleared »")
		if i > 0:
			_, spawn_sud = sud.attrs.get("vers", ":").split(":")
			if spawn_sud not in {p.ident for p in plans[precedente].of_kind("spawn")}:
				erreurs.append(f"{nom} : point d'arrivée {precedente}:{spawn_sud} absent")
		for porte in (sud, nord):
			if not all(_praticable(plan, c) for c in porte.cells):
				erreurs.append(f"{nom} : {porte.ident} sur une case bloquée")
		# Membre.
		membres = plan.of_kind("dresseur")
		if len(membres) != 1:
			erreurs.append(f"{nom} : {len(membres)} dresseur(s) au lieu d'un")
			continue
		membre = membres[0]
		if membre.attrs.get("trainer") != DRESSEURS[i]:
			erreurs.append(f"{nom} : dresseur {membre.attrs.get('trainer')} au lieu de {DRESSEURS[i]}")
		if dresseurs_json and DRESSEURS[i] not in dresseurs_json:
			erreurs.append(f"{nom} : {DRESSEURS[i]} absent de data/trainers/league.json")
		devant = _plus(membre.cells[0], FACING[membre.attrs.get("facing", "down")])
		if devant not in libres:
			erreurs.append(f"{nom} : la case devant le membre {devant} est inaccessible")
		if not any(c in libres for c in nord.cells):
			erreurs.append(f"{nom} : porte nord inaccessible depuis l'entrée")
		if not any(c in libres for c in sud.cells):
			erreurs.append(f"{nom} : porte sud inaccessible depuis l'entrée")
		retour = spawns.get("from_north")
		if retour is None or retour.cells[0] not in libres:
			erreurs.append(f"{nom} : « from_north » absent ou inaccessible")
		# Combat inévitable : sans traverser la vue ni le déclencheur d'appel, la porte nord est
		# hors d'atteinte.
		vue = _vue(plan, membre)
		appel = {c for p in plan.of_kind("declencheur")
			if p.attrs.get("combat") == DRESSEURS[i] for c in p.cells}
		if not appel:
			erreurs.append(f"{nom} : pas de déclencheur d'appel du membre")
		if depart in appel:
			erreurs.append(f"{nom} : l'entrée est sur le déclencheur")
		sans_vue = _atteignables(plan, depart, obstacles | vue | appel)
		if any(c in sans_vue for c in nord.cells):
			erreurs.append(f"{nom} : la porte nord s'atteint sans passer devant le membre")
	return erreurs


def charger() -> dict[str, Plan]:
	return {ident: lire(PLANS / f"{grille}.txt") for ident, grille in SALLES.items()}


def dresseurs() -> set[str]:
	chemin = RACINE / "data" / "trainers" / "league.json"
	return set(json.loads(chemin.read_text(encoding="utf-8"))) if chemin.exists() else set()


def autotest() -> int:
	"""Le contrôle doit refuser des grilles piégées."""
	base = charger()
	pieges = []

	def piege(nom: str, modif) -> None:
		plans = copy.deepcopy(base)
		modif(plans)
		pieges.append((nom, plans))

	def murer_couloir(p):  # le couloir d'Olga coupé : porte nord inaccessible
		plan = p["league_lorelei"]
		plan.rows[6] = "#" * plan.width

	def porte_ouverte(p):  # porte sud sans condition
		p["league_bruno"].positions["porte_sud"].attrs.pop("unless")

	def mauvais_ordre(p):  # Agatha mène au Champion
		p["league_agatha"].positions["porte_nord"].attrs["vers"] = "league_champion:from_south"

	def porte_pantheon(p):
		pan = p["hall_of_fame"]
		pan.positions["sortie"] = copy.deepcopy(base["league_lorelei"].positions["porte_sud"])
		pan.positions["sortie"].ident = "sortie"

	def contournement(p):  # ni vue ni appel : la porte se gagne sans passer devant Aldo
		p["league_bruno"].positions["aldo"].attrs["sight"] = "0"
		p["league_bruno"].positions.pop("appel_aldo")

	def mauvais_membre(p):
		p["league_lance"].positions["peter"].attrs["trainer"] = "league_agatha"

	for nom, f in [("couloir muré", murer_couloir), ("porte sud ouverte", porte_ouverte),
			("ordre", mauvais_ordre), ("porte au Panthéon", porte_pantheon),
			("membre aveugle", contournement), ("mauvais membre", mauvais_membre)]:
		piege(nom, f)
	code = 0
	if controler(base, dresseurs()):
		print("autotest : les vraies grilles devraient passer")
		code = 1
	for nom, plans in pieges:
		if not controler(plans, dresseurs()):
			print(f"autotest : piège « {nom} » non détecté")
			code = 1
	print("autotest :", "OK" if code == 0 else "ÉCHEC", f"({len(pieges)} pièges)")
	return code


def main(argv: list[str]) -> int:
	if "--autotest" in argv:
		return autotest()
	erreurs = controler(charger(), dresseurs())
	for e in erreurs:
		print("ÉCHEC :", e)
	if not erreurs:
		print("OK : hall → Olga → Aldo → Agatha → Peter → Champion → Panthéon ; une entrée et une"
			" sortie par salle, portes conditionnelles, membres accessibles, combats inévitables.")
	return 1 if erreurs else 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
