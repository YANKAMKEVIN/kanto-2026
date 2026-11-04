#!/usr/bin/env python3
"""Départs de débogage du jalon JOH9 (`docs/tech/jalon-joh9.md` §3, T9) : état de fin du JOH8
(drapeaux des dossiers joh-02 à joh-09, §« Drapeaux » ; Dante en fuite, acte 3), équipe 68–75 avec
Surf, Force, Flash et Vol, CS dans le Sac. Usage : python3 -I tools/gen_joh9_debug_starts.py"""

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
# Fin du JOH8 (acte 1 et ses drapeaux retirés au JOH5 : `johto_act1`, `storage_offline`).
JOHTO = ["johto_letter_read", "johto_lugia_shadow", "johto_arrived", "johto_team_stolen",
	"johto_starter_chosen", "johto_rosalia_rockets_seen", "johto_tower_legend_heard",
	"johto_goldenrod_arrived", "johto_egg_received", "johto_radio_tower_closed_seen",
	"johto_azalea_clue", "johto_shrine_seen", "johto_kurt_told", "johto_brace_defeated",
	"johto_radio_pass", "johto_slowpoke_well_cleared", "johto_radio_impostor_defeated",
	"johto_radio_staff_freed", "johto_cenere_defeated", "johto_dante_revealed",
	"johto_team_returned", "johto_act2", "johto_burned_tower_open", "johto_beasts_awakened",
	"johto_raikou_taken", "johto_dante_plan_known", "johto_toll_cleared", "johto_red_gyarados_done",
	"johto_hideout_found", "johto_dante_flashback_seen", "johto_brace_defeated_2",
	"johto_raikou_done", "johto_whirl_clue", "johto_suicune_seen", "johto_cenere_defeated_2",
	"johto_suicune_done", "johto_lugia_done", "johto_bell_tower_clue", "johto_bell_tower_open",
	"johto_dante_met", "johto_dante_defeated_1", "johto_ho_oh_seen", "johto_dante_fled_1",
	"johto_entei_done", "johto_ho_oh_done", "johto_act3"]
PARTY = [
	{"species": "blastoise", "level": 74, "moves": ["surf", "hydro_pump", "ice_beam", "bite"]},
	{"species": "typhlosion", "level": 70},
	{"species": "pidgeot", "level": 70, "moves": ["fly", "wing_attack", "quick_attack", "sky_attack"]},
	{"species": "machamp", "level": 70, "moves": ["strength", "submission", "seismic_toss",
		"karate_chop"]},
	{"species": "raichu", "level": 70, "moves": ["flash", "thunderbolt", "thunder", "quick_attack"]},
	{"species": "ho_oh", "level": 72},
]
BAG = {"hm02": 1, "hm03": 1, "hm04": 1, "hm05": 1, "ultra_ball": 30, "full_restore": 10,
	"max_revive": 5, "hyper_potion": 10, "escape_rope": 3}

STARTS = {
	"johto_mt_silver": ("silver_trail", "from_lake", "right", [], "Sentier, entrée ouest"),
	"johto_mt_silver_outside": ("mt_silver_outside", "from_trail", "up", [], "Extérieur, relais"),
	"johto_mt_silver_1f": ("mt_silver_1f", "from_outside", "up", ["johto_rival_relay"],
		"Grotte 1F : Sbires, lac, rochers"),
	"johto_mt_silver_2f": ("mt_silver_2f", "from_1f", "down", ["johto_rival_relay"],
		"Grotte 2F : noir, Flash, rival"),
	"johto_mt_silver_summit": ("mt_silver_summit", "from_3f", "down",
		["johto_rival_relay", "johto_rival_healed"], "Sommet, sous la trappe : Dante, Giovanni, rival"),
	"johto_mt_silver_rival": ("mt_silver_summit", "from_3f", "down",
		["johto_rival_relay", "johto_rival_healed", "johto_summit_reached",
			"johto_dante_defeated_2", "johto_giovanni_seen"], "Sommet : retour contre le rival"),
	"johto_route_28": ("mt_silver_1f", "from_2f", "down",
		["johto_rival_relay", "johto_rival_healed", "johto_summit_reached",
			"johto_dante_defeated_2", "johto_giovanni_seen", "johto_rival_final_met",
			"johto_rival_final_done"], "Descente : 1F, Route 28, poste, Route 22"),
	"johto_kanto_gate": ("route_22_west", "from_route_28_gate", "left", [],
		"Route 22 ouest (Kanto), devant la porte neuve : A-48 et recul"),
	"johto_route_28_gate": ("route_28_gate", "from_route_28", "down",
		["johto_rival_relay", "johto_rival_healed", "johto_summit_reached",
			"johto_dante_defeated_2", "johto_giovanni_seen", "johto_rival_final_met",
			"johto_rival_final_done"], "Poste de la Route 28, côté Johto : A-47, porte de la Route 22"),
	"johto_epilogue": ("pallet_town", "oak_lab_door", "up",
		["johto_rival_relay", "johto_rival_healed", "johto_summit_reached",
			"johto_dante_defeated_2", "johto_giovanni_seen", "johto_rival_final_met",
			"johto_rival_final_done", "johto_route28_open"], "Bourg Palette, devant le labo"),
	"johto_after_chapter": ("mt_silver_summit", "from_3f", "down",
		["johto_rival_relay", "johto_rival_healed", "johto_summit_reached",
			"johto_dante_defeated_2", "johto_giovanni_seen", "johto_rival_final_met",
			"johto_rival_final_done", "johto_route28_open", "johto_chapter_done",
			"johto_green_ball_received"], "Sommet vide (A-52)"),
}


def main():
	for name, (map_id, spawn, facing, extra, _doc) in STARTS.items():
		data = {"map": map_id, "spawn": spawn, "facing": facing,
			"flags": KANTO + JOHTO + extra, "party": PARTY, "bag": BAG, "money": 80000,
			"rest_point": "mt_silver_center", "period": "day"}
		if name == "johto_after_chapter":
			data["bag"] = dict(BAG, green_ball=1)
		path = os.path.join(OUT, name + ".json")
		with open(path, "w", encoding="utf-8") as handle:
			handle.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", os.path.relpath(path, ROOT))


if __name__ == "__main__":
	main()
