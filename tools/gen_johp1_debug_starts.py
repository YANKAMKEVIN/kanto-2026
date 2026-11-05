#!/usr/bin/env python3
"""Départs de débogage du jalon JOHP1 (`docs/tech/jalon-joh-pierres.md` §3) : l'état de l'arc des
Pierres tel que la bascule du JOHP3 le posera (hall de la Tour Radio, `johto_stones_quest`), équipe
de Johto 29–32, équipe de Kanto confisquée. Usage : python3 -I tools/gen_johp1_debug_starts.py"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "debug_start")

KANTO = ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
	"starter_chosen", "taken_squirtle", "taken_bulbasaur", "rival_lab_won", "rival_challenged",
	"rival_battle_done", "rival_left_lab", "viridian_arrived", "got_oak_parcel",
	"pokedex_activated", "poison_unlocked", "pewter_arrived", "cerulean_reached",
	"badge_boulder", "badge_cascade", "badge_thunder", "badge_rainbow", "badge_soul",
	"badge_marsh", "badge_volcano", "badge_earth", "league_champion_defeated",
	"league_credits_seen"]
# Sortie de la Tour Radio dans l'arc : `johto_act1` et `storage_offline` encore levés (par la clé
# « confiscated »), pas de `johto_team_returned` ni de `johto_act2`.
JOHTO = ["johto_letter_read", "johto_lugia_shadow", "johto_arrived", "johto_team_stolen",
	"johto_starter_chosen", "johto_rosalia_rockets_seen", "johto_tower_legend_heard",
	"johto_goldenrod_arrived", "johto_egg_received", "johto_radio_tower_closed_seen",
	"johto_azalea_clue", "johto_shrine_seen", "johto_kurt_told", "johto_brace_defeated",
	"johto_radio_pass", "johto_slowpoke_well_cleared", "johto_radio_impostor_defeated",
	"johto_radio_staff_freed", "johto_cenere_defeated", "johto_dante_revealed",
	"johto_radio_office_done", "radio_exp_share_given", "johto_stones_quest"]
PARTY = [
	{"species": "croconaw", "level": 32, "moves": ["bite", "water_gun", "scary_face", "slash"]},
	{"species": "noctowl", "level": 31},
	{"species": "ampharos", "level": 31},
	{"species": "azumarill", "level": 30},
]
FULL = PARTY + [{"species": "furret", "level": 30}, {"species": "togetic", "level": 29}]
CONFISCATED = {"party": [
	{"species": "charizard", "level": 62}, {"species": "blastoise", "level": 60},
	{"species": "pidgeot", "level": 58}, {"species": "machamp", "level": 56},
	{"species": "raichu", "level": 55}, {"species": "alakazam", "level": 57},
], "items": {"ultra_ball": 12, "full_restore": 5}}
BAG = {"great_ball": 15, "super_potion": 8, "hyper_potion": 4, "revive": 3, "escape_rope": 2,
	"antidote": 3, "exp_all": 1}
# Nom → carte, arrivée, sens, drapeaux en plus, équipe.
STARTS = {
	"johto_stones_hall": ("goldenrod_radio_tower_1f", "from_city", "up", [], PARTY),
	"johto_alph_route_36": ("route_36", "from_ruins", "up", [], PARTY),
	"johto_alph_ruins": ("ruins_of_alph", "from_route_36", "down", [], PARTY),
	"johto_alph_ruins_full": ("ruins_of_alph", "retour_tente", "down", [], FULL),
	"johto_alph_tent": ("alph_tent", "from_ruins", "up", [], PARTY),
	"johto_alph_gallery": ("alph_gallery", "from_ruins", "down", ["johto_alph_met"], PARTY),
	"johto_alph_tiles": ("alph_gallery", "retour_dalles", "up", ["johto_alph_met"], PARTY),
	"johto_alph_chamber": ("alph_chamber", "from_gallery", "up",
		["johto_alph_met", "johto_alph_tiles_done"], PARTY),
	"johto_alph_after": ("alph_tent", "from_ruins", "up", ["johto_alph_met", "johto_alph_tiles_done",
		"johto_alph_fake_defeated", "johto_stone_memory"], PARTY),
}


def main():
	for name, (map_id, spawn, facing, flags, party) in STARTS.items():
		start = {"map": map_id, "spawn": spawn, "facing": facing, "flags": KANTO + JOHTO + flags,
			"party": party, "companion": 0, "bag": dict(BAG), "money": 30000,
			"confiscated": CONFISCATED,
			"discovered": ["pallet_town", "olivine_city", "ecruteak_city", "goldenrod_city", "azalea_town"],
			"rest_point": "goldenrod_center"}
		if name == "johto_alph_after":
			start["bag"]["stone_memory"] = 1
		if name == "johto_alph_ruins_full":
			# QA de la capture à 6 (JH-71, P-58) : herbes de la poche sud-ouest, Rattata faciles.
			start["wild"] = {"rate": 255, "slots": [{"species": "rattata", "levels": [3, 4], "weight": 1}]}
		with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as handle:
			handle.write(json.dumps(start, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", name)


if __name__ == "__main__":
	main()
