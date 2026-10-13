extends SceneTree
## Captures du compagnon sur les vraies cartes (jalon 11, T20d) :
##   xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_companion_t20d.gd \
##     -- --out=build/captures/jalon11_t20d
## Images : viridian_follow (Jadielle, il suit parmi les passants), forest_follow (Forêt de Jade,
## sentier), forest_talk (bulle « ♪ » et phrase de la forêt), pallet_pond (au bord de l'étang),
## route1_ledge (il saute le rebord au pas suivant).

var _boot: Node
var _router: Node
var _companion: Node
var _out_dir: String = "build/captures/jalon11_t20d"


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
	await _frames(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _step(direction: Vector2i) -> void:
	_player().script_step(direction)
	await _frames(1)
	while _player().is_moving():
		await process_frame
	await _frames(12)


func _go(map_id: StringName, spawn: StringName, facing: Vector2i) -> void:
	_router.call(&"change_map", map_id, spawn, facing)
	while _map().map_id != map_id or bool(_router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)


## Pose le joueur sur [param cell] ; le compagnon le rejoint au premier pas.
func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	_companion.call(&"on_cutscene_started")
	_companion.call(&"on_cutscene_finished")
	await _frames(10)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_city")
	_boot.set(&"start_spawn", &"from_center")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as StoryFlags).set_flag(&"starter_chosen")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmander", 12, GameRng.new(7)))
	state.call(&"set_companion", party.get_at(0))
	_companion = _boot.call(&"get_companion_controller")
	_companion.call(&"refresh")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	_boot.call(&"get_dialogue_runner").set(&"chars_per_second", 0.0)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _shot("viridian_follow")
	# Forêt de Jade : sentier, deux pas vers l'ouest (hors de la vue de Théo).
	await _go(&"viridian_forest", &"before_theo", Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	await _shot("forest_follow")
	_player().face(Vector2i.RIGHT)
	await _frames(4)
	_companion.call(&"talk")
	await _frames(12)
	(_boot.call(&"get_hud") as CanvasLayer).visible = true
	await _shot("forest_talk")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	for i: int in 6:
		if not bool(_boot.call(&"get_dialogue_runner").call(&"is_running")):
			break
		Input.action_press(&"interact")
		await _frames(2)
		Input.action_release(&"interact")
		await _frames(4)
	# Bourg Palette : au bord de l'étang.
	await _go(&"pallet_town", &"start", Vector2i.DOWN)
	var grid := _map().get_grid()
	var spot := Vector2i(-1, -1)
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if spot.x >= 0 or not grid.is_free(cell) or not grid.is_free(cell + Vector2i.UP):
				continue
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if grid.is_in_bounds(cell + Vector2i(dx, dy)) \
							and grid.is_water(cell + Vector2i(dx, dy)):
						spot = cell
	if spot.x < 0:
		print("CAPTURE pas de bord d'étang")
	else:
		await _put(spot, Vector2i.UP)
		await _step(Vector2i.UP)
		_player().face(Vector2i.DOWN)
		await _frames(4)
		await _shot("pallet_pond")
	# Route 1 : un rebord, le compagnon saute au pas suivant.
	await _go(&"route_1", &"from_pallet_w", Vector2i.UP)
	grid = _map().get_grid()
	var ledge := Vector2i(-1, -1)
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if ledge.x < 0 and grid.get_ledge(cell) == GridWorld.Ledge.DOWN \
					and grid.is_free(cell + Vector2i.UP) and grid.is_free(cell + Vector2i.UP * 2) \
					and grid.is_free(cell + Vector2i.DOWN) and grid.is_free(cell + Vector2i.DOWN * 2):
				ledge = cell
	await _put(ledge + Vector2i.UP * 2, Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	_player().script_step(Vector2i.DOWN)
	var node: Node = _companion.call(&"get_node_2d")
	for i: int in 30:
		await process_frame
		if bool(node.call(&"is_jumping")):
			await _frames(4)
			break
	await _shot("route1_ledge")
	print("CAPTURE_COMPANION_T20D terminé")
	quit()
