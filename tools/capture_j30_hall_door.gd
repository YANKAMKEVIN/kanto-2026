extends SceneTree
## Captures du jalon 30 après la fusion du J29 : question du garde devant la porte de la Ligue
## (hall du Plateau Indigo), écran Dresseur avec le lien « Panthéon » (Q30-4) et consultation du
## Panthéon (deux entrées). Départ `indigo_plateau`.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_j30_hall_door.gd \
##     -- --out=build/captures/jalon30_porte

const START := "res://tools/debug_start/indigo_plateau.json"

var _boot: Node
var _out_dir: String = "build/captures/jalon30_porte"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(shot_name: String) -> void:
	await _frames(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot_name])
	print("CAPTURE ", shot_name)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"indigo_plateau_lobby")
	_boot.set(&"start_spawn", &"league_door")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	var state: Node = root.get_node(^"GameState")
	var debug: RefCounted = load("res://game/systems/debug/debug_start.gd").new()
	var data: Variant = _boot.call(&"get_pokemon_data")
	debug.call(&"load_file", START, data, _boot.call(&"get_item_library"))
	debug.call(&"apply", state, data)
	state.set(&"player_name", "Kevin")
	(_boot.call(&"get_dialogue_runner") as Object).set(&"chars_per_second", 0.0)
	root.get_node(^"SceneRouter").call(&"change_map", &"indigo_plateau_lobby", &"league_door",
		Vector2i.UP)
	await _frames(60)
	(_boot.call(&"get_cutscene_director") as Object).call(&"play", &"league_guard_door")
	await _frames(45)
	await _shot("01_garde_question")
	# Q30-4 : deux entrées au Panthéon, écran Dresseur.
	var hall: Object = state.get(&"hall_of_fame")
	var party: Object = state.get(&"party")
	for date: String in ["2026-10-24T20:00:00", "2026-10-26T21:00:00"]:
		hall.call(&"add", HallOfFame.snapshot(party.call(&"get_all"), "Kevin", &"charmander",
			3600.0, date))
	# NON : le joueur recule ; la scène finie, le Menu s'ouvre.
	var runner: Object = _boot.call(&"get_dialogue_runner")
	var box: Object = _boot.call(&"get_dialogue_box")
	var director: Object = _boot.call(&"get_cutscene_director")
	for i: int in 600:
		if not director.call(&"is_running"):
			break
		if runner.call(&"is_awaiting_choice"):
			runner.call(&"choose", false)
		elif box.call(&"is_open"):
			box.emit_signal(&"advance_requested")
		await _frames(5)
	var menu: Object = _boot.call(&"get_menu_director")
	await _frames(30)
	menu.call(&"open")
	await _frames(30)
	menu.call(&"go", MenuRoute.trainer())
	await _frames(120)
	await _shot("02_dresseur_lien_pantheon")
	var screen: Object = _boot.call(&"get_hall_of_fame_screen")
	_boot.call(&"_browse_hall_of_fame")
	await _frames(90)
	await _shot("03_pantheon_consultation")
	quit()
