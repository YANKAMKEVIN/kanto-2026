#!/usr/bin/env python3
"""Lot de bruitages n° 1 du jalon Son (T12, SON-2 A) : packs **Kenney** (CC0, kenney.nl, sans
compte) → `assets/audio/sfx/`, et mise à jour de `data/audio/sfx.json` (fichiers présents :
« expected » faux). Les identifiants sans équivalent Kenney restent « expected » (silence) et
sont listés à la fin : ce sont les manques du lot (eau, téléportation, statuts, familles
d'attaques élémentaires…).

Packs (téléchargés le 2026-10-25, accord de Kevin « Oui, cris + bruitages ») :
- Interface Sounds (I) : kenney.nl/assets/interface-sounds, 834 Ko, 100 OGG ;
- UI Audio (U) : kenney.nl/assets/ui-audio, 412 Ko, 52 OGG ;
- Impact Sounds (P) : kenney.nl/assets/impact-sounds, 801 Ko, 130 OGG ;
- RPG Audio (R) : kenney.nl/assets/rpg-audio, 965 Ko, 52 OGG.

Usage : python3 tools/audio/import_kenney.py DOSSIER_DES_PACKS_DÉZIPPÉS
"""
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import prepare_sfx  # noqa: E402

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
PACKS = {"I": "kenney_interface-sounds", "U": "kenney_ui-audio",
	"P": "kenney_impact-sounds", "R": "kenney_rpg-audio"}
# Crête par famille [D] : l'interface et les pas restent discrets sous la musique.
PEAKS = {"ui": -12.0, "step": -14.0, "world": -8.0, "battle": -6.0, "move": -6.0}

# Identifiant → fichiers Kenney (pack/nom sans extension), autant que de variantes déclarées.
MAPPING = {
	"ui_confirm": ["I/confirmation_001"], "ui_back": ["I/back_001"],
	"ui_move": ["I/select_001"], "ui_refuse": ["I/error_004"],
	"ui_menu_open": ["I/open_001"], "ui_menu_close": ["I/close_001"],
	"ui_dialog_next": ["I/click_001"], "ui_yes_no": ["I/question_001"],
	"ui_saved": ["I/confirmation_002"], "ui_cash": ["R/handleCoins"],
	"ui_pc_on": ["I/maximize_003"], "ui_pc_off": ["I/minimize_003"],
	"ui_pc_move": ["I/drop_001"], "ui_favorite": ["I/pluck_001"], "ui_toast": ["I/bong_001"],
	"ui_map_open": ["R/bookOpen"], "ui_volume_test": ["I/tick_001"],
	"step_grass": ["P/footstep_grass_000", "P/footstep_grass_001", "P/footstep_grass_002",
		"P/footstep_grass_003"],
	"step_hard": ["P/footstep_concrete_000", "P/footstep_concrete_001",
		"P/footstep_concrete_002", "P/footstep_concrete_003"],
	"step_indoor": ["P/footstep_wood_000", "P/footstep_wood_001", "P/footstep_wood_002",
		"P/footstep_wood_003"],
	"step_sand": ["P/footstep_carpet_000", "P/footstep_carpet_001", "P/footstep_carpet_002",
		"P/footstep_carpet_003"],
	"step_snow": ["P/footstep_snow_000", "P/footstep_snow_001", "P/footstep_snow_002",
		"P/footstep_snow_003"],
	"bump": ["P/impactSoft_medium_000"], "ledge_jump": ["P/impactSoft_heavy_000"],
	"door": ["R/doorOpen_1"], "exit_mat": ["R/doorClose_1"], "bike_mount": ["R/metalClick"],
	"bike_bell": ["P/impactBell_heavy_000"], "cut": ["R/chop"],
	"strength_push": ["P/impactMining_000"], "strength_drop": ["P/impactMining_004"],
	"elevator_start": ["R/metalLatch"], "elevator_stop": ["P/impactMetal_light_000"],
	"elevator_ding": ["P/impactBell_heavy_001"], "switch": ["I/switch_001"],
	"gate": ["R/creak1"], "inspect": ["I/tick_002"], "ball_drop": ["P/impactPlate_light_000"],
	"ambient_fly_away": ["R/cloth3"], "bill_machine": ["I/glitch_002"],
	"rocks_fall": ["P/impactMining_002"], "door_slam": ["R/doorClose_4"],
	"trainer_spotted": ["I/pluck_002"],
	"send_out": ["I/maximize_001"], "recall": ["I/minimize_001"],
	"hit_normal": ["P/impactPunch_medium_000"], "hit_super": ["P/impactPunch_heavy_000"],
	"hit_weak": ["P/impactSoft_medium_001"], "no_effect": ["I/error_001"],
	"critical": ["P/impactPunch_heavy_002"], "faint": ["P/impactSoft_heavy_002"],
	"stat_up": ["I/maximize_002"], "stat_down": ["I/minimize_002"],
	"heal_hp": ["I/confirmation_003"], "item_use": ["I/drop_003"],
	"ball_bounce": ["P/impactPlate_light_001"], "ball_close": ["P/impactPlate_medium_000"],
	"ball_shake": ["P/impactPlate_light_002"], "ball_caught": ["I/confirmation_004"],
	"ball_escape": ["P/impactGlass_light_001"], "low_hp": ["I/error_005"],
	"pay_day": ["R/handleCoins2"],
	"move_hit": ["P/impactPunch_medium_001"], "move_heal": ["I/confirmation_001"],
	"move_explosion": ["P/impactMetal_heavy_000"], "move_rock": ["P/impactMining_001"],
	"move_ground": ["P/impactSoft_heavy_001"], "move_fighting": ["P/impactPunch_heavy_001"],
	"move_ice": ["P/impactGlass_medium_000"],
}


def family(sid):
	if sid.startswith("ui_"):
		return "ui"
	if sid.startswith("step_"):
		return "step"
	if sid.startswith("move_"):
		return "move"
	return "battle" if sid in BATTLE else "world"


BATTLE = {"battle_intro", "send_out", "recall", "hit_normal", "hit_super", "hit_weak",
	"no_effect", "miss", "critical", "faint", "stat_up", "stat_down", "heal_hp", "item_use",
	"ball_throw", "ball_bounce", "ball_close", "ball_shake", "ball_caught", "ball_escape", "flee",
	"low_hp", "pay_day", "ghost_voice", "exp_fill"}


def find(src, ref):
	pack, name = ref.split("/", 1)
	hits = glob.glob(os.path.join(src, PACKS[pack], "**", name + ".ogg"), recursive=True)
	if len(hits) != 1:
		raise FileNotFoundError(f"{ref} : {len(hits)} fichier(s)")
	return hits[0]


def main():
	src = sys.argv[1]
	path = os.path.join(RACINE, "data", "audio", "sfx.json")
	with open(path, encoding="utf-8") as f:
		data = json.load(f)
	out_dir = os.path.join(RACINE, "assets", "audio", "sfx")
	os.makedirs(out_dir, exist_ok=True)
	missing = []
	for sid, entry in data["sfx"].items():
		refs = MAPPING.get(sid)
		if refs is None:
			missing.append(sid)
			continue
		files = entry["files"]
		if len(refs) != len(files):
			raise SystemExit(f"{sid} : {len(refs)} sources pour {len(files)} variantes")
		for ref, res in zip(refs, files):
			prepare_sfx.convert(find(src, ref), os.path.join(RACINE, res[len("res://"):]),
				PEAKS[family(sid)])
		entry["expected"] = False
	with open(path, "w", encoding="utf-8") as f:
		f.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
	done = len(data["sfx"]) - len(missing)
	print(f"{done} bruitages importés, {len(missing)} manquants :")
	print(", ".join(missing))


if __name__ == "__main__":
	main()
