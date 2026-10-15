extends SceneTree
## Captures de la Guérison cachée du souterrain (jalon 15 T19) sur le vrai Boot :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_underground_t19.gd \
##     -- --out=build/captures/underground
## Images : cache_avant (face à la pierre descellée : bouton EXAMINER), cache_phrase (T-19 en page),
## cache_toast (toast « Guérison obtenue »), cache_apres (plus de bouton), passant (T-18).

var _boot: Node
var _out_dir: String = "build/captures/underground"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	await _frames(15)


func _interact() -> void:
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	await _frames(20)


func _close() -> void:
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	for i: int in 300:
		if not runner.is_running() and not director.is_running():
			break
		if box.is_open():
			box.advance_requested.emit()
		await _frames(2)
	await _frames(10)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"underground_path")
	_boot.set(&"start_spawn", &"from_route_5_w")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(30)
	var state: Node = root.get_node(^"GameState")
	var flags := state.get(&"flags") as StoryFlags
	for flag: StringName in [&"starter_chosen", &"pokedex_activated", &"badge_boulder"]:
		flags.set_flag(flag)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	(state.get(&"party") as Party).add(PokemonFactory.create(data, &"charmeleon", 18,
		GameRng.new(7)))
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	await _put(Vector2i(11, 10), Vector2i.UP)
	_shot("cache_avant")
	await _interact()
	_shot("cache_phrase")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	box.advance_requested.emit()
	await _frames(12)
	_shot("cache_toast")
	await _close()
	await _frames(60)
	_shot("cache_apres")
	await _put(Vector2i(11, 13), Vector2i.DOWN)
	await _interact()
	_shot("passant")
	await _close()
	quit()
