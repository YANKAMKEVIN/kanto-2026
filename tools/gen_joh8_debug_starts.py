#!/usr/bin/env python3
"""Départs de débogage du JOH8 (`docs/tech/jalon-joh8.md` §2.8) : état de fin du JOH7 posé à la
main (drapeaux des dossiers JOH-02 à JOH-08 §« Drapeaux », équipe 62–68 du cadre §7).

Usage : python3 -I tools/gen_joh8_debug_starts.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "debug_start")

KANTO = ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
	"starter_chosen", "taken_charmander", "taken_squirtle", "rival_lab_won", "rival_challenged",
	"rival_battle_done", "rival_left_lab", "viridian_arrived", "got_oak_parcel", "pokedex_activated",
	"poison_unlocked", "pewter_arrived", "cerulean_reached", "badge_boulder", "badge_cascade",
	"badge_thunder", "badge_rainbow", "badge_soul", "badge_marsh", "badge_volcano", "badge_earth",
	"league_champion_defeated", "league_credits_seen", "oak_post_league_gifts_done"]
JOHTO = [
	# JOH1
	"johto_letter_read", "johto_lugia_shadow", "johto_arrived", "johto_slept", "johto_team_stolen",
	"johto_starter_offered", "johto_starter_chosen", "johto_orme_left",
	# JOH2
	"johto_rosalia_rockets_seen", "johto_tower_legend_heard",
	# JOH3
	"johto_goldenrod_arrived", "johto_egg_received", "johto_radio_tower_closed_seen",
	"johto_azalea_clue",
	# JOH4
	"johto_shrine_seen", "johto_kurt_told", "johto_brace_defeated", "johto_radio_pass",
	"johto_slowpoke_well_cleared",
	# JOH5
	"johto_radio_impostor_defeated", "johto_radio_staff_freed", "johto_cenere_defeated",
	"johto_dante_revealed", "johto_team_returned", "radio_exp_share_given", "johto_act2",
	# JOH6
	"johto_burned_tower_open", "johto_beasts_awakened", "johto_raikou_taken",
	"johto_dante_plan_known", "johto_toll_cleared", "johto_red_gyarados_done",
	"johto_hideout_found", "johto_dante_flashback_seen", "johto_brace_defeated_2",
	"johto_raikou_done", "johto_whirl_clue",
	# JOH7
	"johto_suicune_seen", "johto_cenere_defeated_2", "johto_suicune_done", "johto_lugia_done",
	"johto_bell_tower_clue",
]
# Équipe de fin d'acte 2 (cadre §7 : 62–68) [D] : starter de Johto, équipe de Kanto rendue.
PARTY = [
	{"species": "feraligatr", "level": 66, "moves": ["surf", "crunch", "slash", "ice_beam"]},
	{"species": "charizard", "level": 65},
	{"species": "venusaur", "level": 64},
	{"species": "ampharos", "level": 62},
	{"species": "pidgeot", "level": 63},
	{"species": "nidoking", "level": 63},
]
BAG = {"ultra_ball": 20, "great_ball": 10, "full_restore": 5, "hyper_potion": 10,
	"max_revive": 3, "revive": 5, "escape_rope": 3, "hm03": 1}
DISCOVERED = ["pallet_town", "olivine_city", "ecruteak_city"]

STARTS = {
	# Rosalia, le doyen pas encore vu (JOH2 fusionné) : sage blessé, doyen, garde, Bois.
	"johto_bell_tower_rosalia": {"map": "ecruteak_city", "spawn": "from_center", "facing": "down",
		"extra": []},
	# Bois de la Tour, tour ouverte : Sbire de guet, objets, porte.
	"johto_bell_tower_woods": {"map": "bell_tower_woods", "spawn": "from_ecruteak", "facing": "up",
		"extra": ["johto_bell_tower_open"]},
	# 2F : planches qui cèdent, Hiroshi, Sbire W, long escalier.
	"johto_bell_tower_2f": {"map": "bell_tower_2f", "spawn": "from_1f", "facing": "down",
		"extra": ["johto_bell_tower_open"]},
	# Sommet, à l'arrivée : scène (H-13 à H-33), aube forcée.
	"johto_bell_tower_roof": {"map": "bell_tower_roof", "spawn": "from_2f", "facing": "down",
		"extra": ["johto_bell_tower_open"]},
	# Même chose, en écrivant la vraie sauvegarde (reprise après coupure ; QA A17).
	"johto_bell_tower_roof_autosave": {"map": "bell_tower_roof", "spawn": "from_2f",
		"facing": "down", "extra": ["johto_bell_tower_open"], "autosave": True},
	# Sommet, Dante parti, Entei libre (reprise du dossier §12).
	"johto_bell_tower_entei": {"map": "bell_tower_roof", "spawn": "from_2f", "facing": "down",
		"extra": ["johto_bell_tower_open", "johto_dante_met", "johto_dante_defeated_1",
			"johto_ho_oh_seen", "johto_dante_fled_1"]},
	# Rosalia après le sommet : doyen H-34, Orme H-35 / H-36, habitante H-37.
	"johto_bell_tower_after": {"map": "ecruteak_city", "spawn": "from_center", "facing": "down",
		"extra": ["johto_bell_tower_open", "johto_dante_met", "johto_dante_defeated_1",
			"johto_ho_oh_seen", "johto_dante_fled_1", "johto_entei_done", "johto_entei_caught",
			"johto_ho_oh_done", "got_rainbow_wing"], "bag": {"rainbow_wing": 1}},
}


def main():
	for name, spec in STARTS.items():
		data = {"map": spec["map"], "spawn": spec["spawn"], "facing": spec["facing"],
			"flags": KANTO + JOHTO + spec["extra"], "party": PARTY, "companion": 0,
			"bag": dict(BAG, **spec.get("bag", {})), "money": 80000, "discovered": DISCOVERED,
			"rest_point": "ecruteak_center"}
		if spec.get("autosave"):
			data["autosave"] = True
		path = os.path.join(OUT, name + ".json")
		with open(path, "w", encoding="utf-8") as handle:
			handle.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
		print("écrit :", os.path.relpath(path, ROOT))


if __name__ == "__main__":
	main()
