#!/usr/bin/env python3
"""Départs de débogage du JOHP3 (`docs/tech/jalon-joh-pierres.md` §5.4), écrits depuis celui du
bureau de la Tour Radio : mêmes drapeaux de Kanto et de l'acte 1, puis ceux de l'arc jusqu'au point
voulu. Équipe de Johto de 4 Pokémon, équipe de Kanto confisquée de 5 (9 en tout : écran des 6).

Usage : python3 -I tools/gen_johp3_debug_starts.py
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "tools", "debug_start")

ARC = ["johto_radio_office_done", "radio_exp_share_given", "johto_stones_quest", "johto_alph_met",
	"johto_alph_tiles_done", "johto_stone_memory", "johto_ferry_open", "johto_cianwood_arrived",
	"johto_tide_valve_1", "johto_tide_valves_done", "johto_stone_tide_lost"]
CLAN = ["johto_clan_called", "johto_blackthorn_arrived"]
TRIAL = ["johto_clan_trial_open"]
GUARDIANS = ["beaten_den_guardian_water", "beaten_den_guardian_stone", "beaten_den_guardian_sky",
	"johto_clan_guardians_done"]
YSOLDE = ["johto_clan_trial_done", "johto_stone_breath"]
AWAKENED = ["johto_stones_awakened"]

TEAM_40 = [{"species": "typhlosion", "level": 41}, {"species": "ampharos", "level": 40},
	{"species": "noctowl", "level": 39}, {"species": "togetic", "level": 39}]
TEAM_58 = [{"species": "typhlosion", "level": 58}, {"species": "ampharos", "level": 58},
	{"species": "noctowl", "level": 58}, {"species": "togetic", "level": 58}]
BAG = {"poke_ball": 5, "super_potion": 5, "hyper_potion": 5, "antidote": 2, "stone_memory": 1,
	"exp_all": 1}

# nom → carte, arrivée, orientation, drapeaux de l'arc, équipe, objets clés en plus
STARTS = {
	"johto_rosalia_corentin": ("ecruteak_city", "retour_sages", "down", ARC, TEAM_40, {}),
	"johto_blackthorn": ("blackthorn_city", "from_dragon", "up", ARC + CLAN, TEAM_40, {}),
	"johto_den_1f": ("dragons_den_1f", "from_city", "up", ARC + CLAN + TRIAL, TEAM_40, {}),
	"johto_den_sanctuary": ("dragons_den_sanctuary", "from_1f", "up",
		ARC + CLAN + TRIAL + GUARDIANS, TEAM_40, {}),
	"johto_den_altar": ("dragons_den_sanctuary", "altar_front", "up",
		ARC + CLAN + TRIAL + GUARDIANS + YSOLDE, TEAM_40, {"stone_breath": 1}),
	"johto_den_cenere": ("dragons_den_sanctuary", "altar_front", "up",
		ARC + CLAN + TRIAL + GUARDIANS + YSOLDE + AWAKENED, TEAM_58, {}),
	# QA du retour de l'équipe : Cenere battue, mallette pas encore rendue (écran des 6, reprise).
	"johto_den_return": ("dragons_den_sanctuary", "altar_front", "up",
		ARC + CLAN + TRIAL + GUARDIANS + YSOLDE + AWAKENED + ["johto_cenere_defeated_arc"], TEAM_58, {}),
}


def main():
	with open(os.path.join(DIR, "johto_radio_tower_office.json"), encoding="utf-8") as handle:
		base = json.load(handle)
	for name, (map_id, spawn, facing, flags, team, extra) in STARTS.items():
		start = dict(base)
		start.update({"map": map_id, "spawn": spawn, "facing": facing,
			"flags": base["flags"] + flags, "party": team})
		bag = dict(BAG)
		if "johto_stones_awakened" in flags:
			del bag["stone_memory"]
		bag.update(extra)
		start["bag"] = bag
		path = os.path.join(DIR, name + ".json")
		with open(path, "w", encoding="utf-8") as handle:
			handle.write(json.dumps(start, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", os.path.relpath(path, ROOT))


if __name__ == "__main__":
	main()
