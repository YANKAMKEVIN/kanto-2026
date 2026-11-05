#!/usr/bin/env python3
"""Départs de débogage du jalon JOHP2 (`docs/tech/jalon-joh-pierres.md` §4) : l'état de sortie du
JOHP1 (Tour Radio finie, quête ouverte, Pierre Mémoire en poche), sans passer par les Ruines, qui se
codent en parallèle. Rien ne pose `johto_stones_quest` dans le jeu avant la bascule du JOHP3 : ces
départs sont le seul chemin jusqu'ici. Équipe de Johto de l'acte 1 (33–36), équipe de Kanto
confisquée. L'objet clé `stone_memory` (JOHP1) n'entre au Sac qu'après la fusion du JOHP1.

Usage : python3 -I tools/gen_johp2_debug_starts.py
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "debug_start")

with open(os.path.join(OUT, "johto_radio_tower_office.json"), encoding="utf-8") as handle:
	OFFICE = json.load(handle)

# Sortie de la Tour Radio (dossier JOH-11 §6, étapes 1 à 3), puis Ruines d'Alpha (étapes 4 à 8).
ARC = OFFICE["flags"] + ["johto_radio_office_done", "radio_exp_share_given", "johto_stones_quest",
	"johto_alph_met", "johto_alph_tiles_done"]
MEMORY = ARC + ["johto_stone_memory"]
OPEN = MEMORY + ["johto_ferry_open"]
ARRIVED = OPEN + ["johto_cianwood_arrived"]
VALVES = ARRIVED + ["johto_tide_valve_1", "johto_tide_valves_done"]
BEATEN = VALVES + ["beaten_tide_grunt_z", "beaten_tide_hold_chief"]
LOST = BEATEN + ["johto_stone_tide_lost"]

PARTY = [{"species": "quilava", "level": 36}, {"species": "flaaffy", "level": 35},
	{"species": "noctowl", "level": 34}, {"species": "togetic", "level": 33}]
SURF_PARTY = [{"species": "croconaw", "level": 30,
	"moves": ["surf", "bite", "water_gun", "scary_face"]}]
BAG = {"poke_ball": 10, "great_ball": 5, "super_potion": 8, "hyper_potion": 3, "antidote": 3,
	"escape_rope": 2, "exp_all": 1, "mission_order": 1, "radio_card": 1, "super_rod": 1}

STARTS = {
	"johto_johp2_olivine_stranger": {"map": "olivine_city", "spawn": "from_goeland", "facing": "left",
		"flags": ARC},
	"johto_johp2_olivine": {"map": "olivine_city", "spawn": "from_goeland", "facing": "left",
		"flags": MEMORY},
	"johto_johp2_deck": {"map": "goeland_deck", "spawn": "from_quai", "facing": "right",
		"flags": OPEN + ["johto_goeland_outbound"]},
	"johto_johp2_cianwood": {"map": "cianwood_city", "spawn": "from_goeland", "facing": "left",
		"flags": OPEN, "rest_point": "cianwood_center"},
	"johto_johp2_cianwood_autosave": {"map": "cianwood_city", "spawn": "retour_centre", "facing": "down",
		"flags": ARRIVED, "rest_point": "cianwood_center", "autosave": True},
	"johto_johp2_cianwood_night": {"map": "cianwood_city", "spawn": "retour_centre", "facing": "down",
		"flags": ARRIVED, "rest_point": "cianwood_center", "period": "night"},
	"johto_johp2_tide_1f": {"map": "tide_cave_1f", "spawn": "from_city", "facing": "left",
		"flags": ARRIVED, "rest_point": "cianwood_center"},
	"johto_johp2_tide_b1f": {"map": "tide_cave_b1f", "spawn": "from_1f", "facing": "down",
		"flags": ARRIVED + ["beaten_tide_grunt_z"], "rest_point": "cianwood_center"},
	"johto_johp2_chief": {"map": "tide_cave_b1f", "spawn": "rive_sud", "facing": "left",
		"flags": VALVES + ["beaten_tide_grunt_z"], "rest_point": "cianwood_center"},
	"johto_johp2_socle": {"map": "tide_cave_b1f", "spawn": "rive_sud", "facing": "left",
		"flags": BEATEN, "rest_point": "cianwood_center"},
	"johto_johp2_return": {"map": "goeland_deck", "spawn": "from_quai", "facing": "right",
		"flags": LOST, "rest_point": "cianwood_center"},
	"johto_johp2_rosalia": {"map": "ecruteak_city", "spawn": "from_center", "facing": "down",
		"flags": LOST + ["johto_goulven_rosalia_told"]},
	# A-13 : la mer au sud d'Oliville, en Surf, avant l'acte 2 (sur la rangée 39, côté Route 40).
	"johto_johp2_south_sea": {"map": "olivine_city", "spawn": "from_route_40_3", "facing": "up",
		"flags": ARC, "party": SURF_PARTY},
}


def main():
	for name, spec in STARTS.items():
		start = {"map": spec["map"], "spawn": spec["spawn"], "facing": spec["facing"],
			"flags": spec["flags"], "party": spec.get("party", PARTY), "companion": 0, "bag": BAG,
			"confiscated": OFFICE["confiscated"], "money": 9000}
		for key in ("rest_point", "period", "autosave"):
			if key in spec:
				start[key] = spec[key]
		path = os.path.join(OUT, name + ".json")
		with open(path, "w", encoding="utf-8") as handle:
			handle.write(json.dumps(start, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", os.path.relpath(path, ROOT))


if __name__ == "__main__":
	main()
