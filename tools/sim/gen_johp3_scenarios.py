#!/usr/bin/env python3
"""Scénarios d'équilibrage du JOHP3 (`docs/tech/jalon-joh-pierres.md` §5.2, §5.4), pour
`tools/simulate_mt_moon.gd` : Ysolde (cible 35–60 % du premier coup), Cenere après le Réveil
(70–80 %), puis Brace, Cenere des Îles Tourbillon et Dante (1) avec une équipe mixte (JH-78 : au
plus 80 %). Les Dresseurs viennent des données du jeu.

Usage : python3 -I tools/sim/gen_johp3_scenarios.py
        godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --scenario res://tools/sim/johp3_ysolde.json
"""

import glob
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tools", "sim")


def trainer(ident):
	for path in glob.glob(os.path.join(ROOT, "data", "trainers", "*.json")):
		with open(path, encoding="utf-8") as handle:
			data = json.load(handle)
		if ident in data:
			return data[ident]
	raise KeyError(ident)


def team(name, members):
	return {"name": name, "members": [{"species": s, "level": l} for s, l in members]}


JOHTO_SIX = [("typhlosion", 39), ("ampharos", 38), ("noctowl", 38), ("togetic", 37), ("furret", 37),
	("girafarig", 37)]
JOHTO_FOUR = [("feraligatr", 42), ("ampharos", 41), ("noctowl", 41), ("togetic", 40)]
JOHTO_THREE = [("meganium", 44), ("ampharos", 44), ("noctowl", 44)]
AWAKE = [("typhlosion", 58), ("ampharos", 58), ("noctowl", 58), ("togetic", 58), ("furret", 58),
	("girafarig", 58)]
AWAKE_LOW = [("feraligatr", 55), ("ampharos", 55), ("noctowl", 55), ("togetic", 55)]
def mixed(level):
	"""Trois de Johto et trois de Kanto, au niveau atteint à ce moment de l'acte 2 (dossier §9)."""
	return [("typhlosion", level), ("ampharos", level - 1), ("noctowl", level - 2),
		("charizard", level + 1), ("pidgeot", level), ("alakazam", level)]


VARIANTS = [
	{"name": "attentif, 3 Hyper Potions", "player": "attentif", "center": True,
		"items": {"hyper_potion": 3}, "optional": []},
	{"name": "naïf", "player": "naif", "center": True, "items": {}, "optional": []},
]

SCENARIOS = {
	"johp3_ysolde": ("Ysolde, Sanctuaire de l'Antre (JOHP3)", "Cible 35–60 % du premier coup.",
		[team("6 Pokémon 37–39", JOHTO_SIX), team("4 Pokémon 40–42", JOHTO_FOUR),
			team("3 Pokémon 44", JOHTO_THREE)],
		["den_ysolde"]),
	"johp3_cenere": ("Cenere après le Réveil (JOHP3)", "Cible 70–80 %, 80 % au plus (JH-74).",
		[team("6 Pokémon 58", AWAKE), team("4 Pokémon 55", AWAKE_LOW)],
		["den_cenere"]),
	"johp3_mixte_brace": ("Brace, repaire d'Acajou, équipe mixte (JH-78)", "Au plus 80 %.",
		[team("Mixte N59", mixed(59)), team("Mixte N61", mixed(61))],
		["mahogany_hideout_b3f_brace"]),
	"johp3_mixte_cenere": ("Cenere, Îles Tourbillon, équipe mixte (JH-78)", "Au plus 80 %.",
		[team("Mixte N61", mixed(61)), team("Mixte N63", mixed(63))],
		["whirl_islands_cenere"]),
	"johp3_mixte_dante": ("Dante (1), équipe mixte (JH-78)", "Au plus 80 %.",
		[team("Mixte N63", mixed(63)), team("Mixte N65", mixed(65))],
		["bell_tower_dante_1"]),
}


def steps_for(ids):
	steps = [{"label": "Soin", "center": True}]
	for ident in ids:
		steps.append({"label": ident, "trainer": ident})
		steps.append({"label": "Soin", "center": True})
	return steps


def main():
	for name, (title, description, teams, ids) in SCENARIOS.items():
		scenario = {"version": 1, "title": title, "description": description, "seeds": 300,
			"heal_at_start": True, "teams": teams, "tables": {},
			"trainers": {ident: trainer(ident) for ident in ids}, "steps": steps_for(ids),
			"variants": VARIANTS}
		path = os.path.join(OUT, name + ".json")
		with open(path, "w", encoding="utf-8") as handle:
			handle.write(json.dumps(scenario, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", os.path.relpath(path, ROOT))


if __name__ == "__main__":
	main()
