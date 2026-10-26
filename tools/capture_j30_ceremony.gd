extends SceneTree
## Captures de la cérémonie du jalon 30 (T15 à T17) sur le vrai Boot : départ
## `league_champion_charmander`, cinq victoires posées, arrivée dans la salle du Champion → Chen,
## Panthéon (un Pokémon, l'équipe), générique (début, équipe, fin), Bourg Palette. Dialogues
## avancés tout seuls ; le toucher de fin du Panthéon est simulé.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_j30_ceremony.gd \
##     -- --out=build/captures/jalon30_ceremonie

const START := "res://tools/debug_start/league_champion_charmander.json"
const TIMEOUT_FRAMES: int = 30 * 240

var _boot: Node
var _out_dir: String = "build/captures/jalon30_ceremonie"
var _shots: Dictionary = {}


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
	if _shots.has(shot_name):
		return
	_shots[shot_name] = true
	await _frames(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot_name])
	print("CAPTURE ", shot_name)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"league_champion")
	_boot.set(&"start_spawn", &"from_south")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	var state: Node = root.get_node(^"GameState")
	var debug: RefCounted = load("res://game/systems/debug/debug_start.gd").new()
	var data: Variant = _boot.call(&"get_pokemon_data")
	if not debug.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error(str(debug.call(&"get_errors")))
	debug.call(&"apply", state, data)
	state.set(&"player_name", "Kevin")
	var flags: Object = state.get(&"flags")
	for flag: String in ["league_attempt_active", "league_stage_0_cleared",
			"league_stage_1_cleared", "league_stage_2_cleared", "league_stage_3_cleared",
			"league_stage_4_cleared", "beaten_rival_champion"]:
		flags.call(&"set_flag", StringName(flag))
	(_boot.call(&"get_dialogue_runner") as Object).set(&"chars_per_second", 0.0)
	var router: Node = root.get_node(^"SceneRouter")
	router.call(&"change_map", &"league_champion", &"from_south", Vector2i.UP)
	var box: Object = _boot.call(&"get_dialogue_box")
	var hall: Object = _boot.call(&"get_hall_of_fame_screen")
	var credits: Object = _boot.call(&"get_credits_screen")
	var director: Object = _boot.call(&"get_cutscene_director")
	var page_frames := 0
	var hall_frames := 0
	var credit_frames := 0
	for frame: int in TIMEOUT_FRAMES:
		await process_frame
		if frame % 300 == 0:
			var here: Node = _boot.call(&"get_map")
			print("[capture] image %d : carte %s, scène %s, boîte %s, Panthéon %s, générique %s" % [
				frame, here.get(&"map_id") if is_instance_valid(here) else &"?",
				director.call(&"get_cutscene_id"), box.call(&"is_open"),
				hall.call(&"is_showing"), credits.call(&"is_showing")])
		if box.call(&"is_open"):
			page_frames += 1
			if page_frames == 20:
				var text: String = box.call(&"get_text")
				if text.contains("Félicitations"):
					await _shot("01_chen_felicitations")
				elif text.contains("Bienvenue au Panthéon"):
					await _shot("02_pantheon_bienvenue")
				elif text.contains("légende"):
					await _shot("05_fin_narration")
			if page_frames >= 30:
				box.emit_signal(&"advance_requested")
				page_frames = 0
			continue
		page_frames = 0
		if hall.call(&"is_showing"):
			hall_frames += 1
			if int(hall.call(&"get_team_size")) == 0 and hall_frames == 45:
				await _shot("03_pantheon_pokemon")
			if int(hall.call(&"get_team_size")) > 0:
				await _frames(60)
				await _shot("04_pantheon_equipe")
				var tap := InputEventScreenTouch.new()
				tap.pressed = true
				tap.position = Vector2(400, 400)
				Input.parse_input_event(tap)
				await _frames(2)
				tap = tap.duplicate() as InputEventScreenTouch
				tap.pressed = false
				Input.parse_input_event(tap)
				await _frames(30)
			continue
		if credits.call(&"is_showing"):
			credit_frames += 1
			if credit_frames == 60:
				await _shot("06_generique_debut")
			elif credit_frames == 360:
				await _shot("07_generique_equipe")
			elif credit_frames == 361:
				credits.set(&"speed_scale", 0.2)
			continue
		var map: Node = _boot.call(&"get_map")
		if is_instance_valid(map) and map.get(&"map_id") == &"pallet_town" \
				and _boot.call(&"is_stable"):
			await _frames(30)
			await _shot("08_bourg_palette")
			break
	print("CAPTURE_J30_CEREMONIE terminé (%d)" % _shots.size())
	quit()
