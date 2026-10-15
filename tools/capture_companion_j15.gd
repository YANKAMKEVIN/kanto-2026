extends SceneTree
## Captures du compagnon sur les cartes du jalon 15 (T20) sur le vrai Boot : Miaouss N17 suit le
## héros dans le passage souterrain (galerie, renflement du passant), à Carmin-sur-Mer (rue et
## quai), sur la Route 5 et la Route 6. HUD masqué.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_companion_j15.gd \
##     -- --out=build/captures/j15_t20
## (pas en headless : il faut un rendu).

var _boot: Node
var _router: Node
var _companion: Node
var _out_dir: String = "build/captures/j15_t20"


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
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name, " ", image.get_size())


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _step(direction: Vector2i) -> void:
	if not _player().script_step(direction):
		print("capture_companion_j15 : pas refusé ", direction, " depuis ", _player().get_cell())
		return
	await _frames(1)
	while _player().is_moving():
		await process_frame
	await _frames(6)


func _walk(directions: Array[Vector2i]) -> void:
	for direction: Vector2i in directions:
		await _step(direction)


func _go(map_id: StringName, spawn: StringName) -> void:
	_router.call(&"change_map", map_id, spawn)
	while _map().map_id != map_id or bool(_router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	_companion.call(&"on_cutscene_started")
	_companion.call(&"on_cutscene_finished")
	await _frames(10)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"underground_path")
	_boot.set(&"start_spawn", &"from_route_5_w")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	var state: Node = root.get_node(^"GameState")
	var flags: StoryFlags = state.get(&"flags")
	for flag: StringName in [&"starter_chosen", &"route_5_entered", &"vermilion_reached"]:
		flags.set_flag(flag)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"meowth", 17, GameRng.new(17)))
	state.call(&"ensure_unique_uids")
	state.call(&"set_companion", party.get_at(0))
	_companion = _boot.call(&"get_companion_controller")
	_companion.call(&"refresh")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	# Souterrain : la galerie nord (descente), puis le renflement du passant (11, 14).
	await _walk([Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT])
	_shot("souterrain_galerie")
	await _put(Vector2i(8, 13), Vector2i.RIGHT)
	await _walk([Vector2i.RIGHT, Vector2i.RIGHT])
	_shot("souterrain_renflement")
	# Carmin-sur-Mer : la rue nord, puis vers le quai.
	await _go(&"vermilion_city", &"from_route_6_c")
	await _walk([Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.LEFT])
	_shot("carmin_rue")
	await _put(Vector2i(31, 20), Vector2i.DOWN)
	await _walk([Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.LEFT, Vector2i.LEFT])
	_shot("carmin_quai")
	# Routes 5 et 6.
	await _go(&"route_5", &"from_cerulean_c")
	await _walk([Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN, Vector2i.RIGHT])
	_shot("route_5")
	await _go(&"route_6", &"from_underground")
	await _walk([Vector2i.DOWN, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT])
	_shot("route_6")
	print("CAPTURE_COMPANION_J15 fini")
	quit()
