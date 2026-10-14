extends SceneTree
## Captures du moteur de la grotte (jalon 12, T20) sur le vrai Boot, au Mont Sélénite 1F :
##   godot --path . --resolution 1170x540 --fixed-fps 30 -s res://tools/capture_cave_t20.gd \
##     -- --out=build/captures/jalon12_t20
## Images : galerie_compagnon (le compagnon suit dans une galerie), eboulis_1 / eboulis_2
## (l'éboulis sous les pieds, ≈ 0,15 s et 0,4 s), eboulis_demi_tour (le héros s'est retourné,
## juste avant le combat), echelle_arrivee (arrivée par une échelle : jamais posé dessus),
## echelle_premier_pas (il sort au premier pas).

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _boot: Node
var _router: Node
var _companion: Node
var _out_dir: String = "build/captures/jalon12_t20"


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


func _step(direction: Vector2i) -> void:
	_player().script_step(direction)
	await _frames(1)
	while _player().is_moving():
		await process_frame
	await _frames(10)


func _go(map_id: StringName, spawn: StringName, facing: Vector2i) -> void:
	_router.call(&"change_map", map_id, spawn, facing)
	while _map().map_id != map_id or bool(_router.call(&"is_transitioning")):
		await process_frame


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	_companion.call(&"on_cutscene_started")
	_companion.call(&"on_cutscene_finished")
	await _frames(10)


func _calm_step() -> Vector2i:
	var grid := _map().get_grid()
	var cell := _player().get_cell()
	for direction: Vector2i in DIRECTIONS:
		var next := cell + direction
		if grid.is_free(next) and not grid.is_rubble(next) \
				and _map().get_warps().get_at(next).is_empty():
			return direction
	return Vector2i.ZERO


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"mt_moon_1f")
	_boot.set(&"start_spawn", &"from_route_3_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as StoryFlags).set_flag(&"starter_chosen")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmander", 15, GameRng.new(7)))
	state.call(&"set_companion", party.get_at(0))
	_companion = _boot.call(&"get_companion_controller")
	_companion.call(&"refresh")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	# Galerie : quelques pas vers le nord depuis l'entrée.
	for i: int in 4:
		await _step(Vector2i.UP)
	await _frames(10)
	_shot("galerie_compagnon")
	# Échelle A : arrivée au B1F (la case derrière le joueur est l'échelle).
	await _go(&"mt_moon_b1f", &"arrivee_a", Vector2i.DOWN)
	await _frames(20)
	_shot("echelle_arrivee")
	await _step(_calm_step())
	await _frames(10)
	_shot("echelle_premier_pas")
	# Gravats : table forcée (rencontre certaine au premier pas sur les gravats).
	var library: EncounterLibrary = _boot.call(&"get_encounter_library")
	library.override_table(_map().map_id, &"rubble", {"rate": 255,
		"slots": [{"species": "zubat", "levels": [9, 9], "weight": 1}]}, "capture")
	var grid := _map().get_grid()
	var spot := Vector2i(-1, -1)
	var toward := Vector2i.ZERO
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if spot.x >= 0 or not grid.is_free(cell) or grid.is_rubble(cell):
				continue
			for direction: Vector2i in DIRECTIONS:
				if grid.is_rubble(cell + direction) and grid.is_free(cell - direction):
					spot = cell
					toward = direction
					break
	await _put(spot, toward)
	await _step(-toward)
	await _step(toward)
	var director: EncounterDirector = _boot.call(&"get_encounter_director")
	_player().script_step(toward)
	while not director.is_running():
		await process_frame
	await _frames(4)
	_shot("eboulis_1")
	await _frames(8)
	_shot("eboulis_2")
	await _frames(7)
	_shot("eboulis_demi_tour")
	var battles: BattleDirector = _boot.call(&"get_battle_director")
	while director.is_running():
		if battles.is_running():
			# Fuite : on veut seulement l'intro.
			break
		await process_frame
	print("CAPTURE_CAVE_T20 éboulis terminé")
	quit()
