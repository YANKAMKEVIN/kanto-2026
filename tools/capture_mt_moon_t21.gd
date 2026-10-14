extends SceneTree
## Captures de la vie du Mont Sélénite (jalon 12, T21) sur le vrai Boot :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_mt_moon_t21.gd \
##     -- --out=build/captures/jalon12_t21
## Images : compagnon_rondoudou (Rondoudou suit dans la galerie du hall), randonneur (sa
## réplique ouverte), camp (caisses R et lampe abandonnée), camp_caisse (examen d'une caisse),
## cache_indice (face à l'éclat clair : bouton EXAMINER), cache_trouve (toast du Réveil),
## corde_au_sol (la Ball de la Corde Sortie), compagnon_nosferapti (Nosferapti en vol dans la
## galerie est), potion_b1f.

var _boot: Node
var _companion: Node
var _out_dir: String = "build/captures/jalon12_t21"


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


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_player().enter_map(_map().get_grid(), cell, facing, _map().get_pixel_rect())
	_companion.call(&"on_cutscene_started")
	_companion.call(&"on_cutscene_finished")
	await _frames(10)


func _interact() -> void:
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	await _frames(30)


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


func _set_companion(species: StringName, level: int) -> void:
	var state: Node = root.get_node(^"GameState")
	var party: Party = state.get(&"party")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var mon := PokemonFactory.create(data, species, level, GameRng.new(11))
	party.add(mon)
	state.call(&"set_companion", mon)
	_companion.call(&"refresh")


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"mt_moon_1f")
	_boot.set(&"start_spawn", &"from_route_3_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var state: Node = root.get_node(^"GameState")
	var flags := state.get(&"flags") as StoryFlags
	for flag: StringName in [&"starter_chosen", &"pokedex_activated", &"badge_boulder"]:
		flags.set_flag(flag)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	(state.get(&"party") as Party).add(PokemonFactory.create(data, &"charmeleon", 18,
		GameRng.new(7)))
	_companion = _boot.call(&"get_companion_controller")
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	_set_companion(&"jigglypuff", 14)
	# Hall du puits de jour : Rondoudou suit, le randonneur à côté.
	await _put(Vector2i(31, 41), Vector2i.UP)
	await _step(Vector2i.UP)
	await _step(Vector2i.RIGHT)
	await _frames(15)
	_shot("compagnon_rondoudou")
	await _put(Vector2i(35, 38), Vector2i.LEFT)
	await _step(Vector2i.DOWN)
	await _step(Vector2i.UP)
	_player().script_step(Vector2i.LEFT)
	await _frames(15)
	await _interact()
	_shot("randonneur")
	await _close()
	# Camp abandonné.
	await _put(Vector2i(7, 18), Vector2i.UP)
	await _step(Vector2i.UP)
	await _frames(15)
	_shot("camp")
	await _put(Vector2i(4, 17), Vector2i.UP)
	await _step(Vector2i.UP)
	_player().script_step(Vector2i.UP)
	await _frames(10)
	await _interact()
	_shot("camp_caisse")
	await _close()
	# Corde Sortie au sol.
	await _put(Vector2i(9, 27), Vector2i.DOWN)
	await _frames(10)
	_shot("corde_au_sol")
	# Réveil caché : face à l'indice (57, 19) depuis (56, 19).
	await _put(Vector2i(55, 19), Vector2i.RIGHT)
	await _step(Vector2i.RIGHT)
	await _frames(15)
	_shot("cache_indice")
	await _interact()
	await _frames(10)
	_shot("cache_trouve")
	await _close()
	# Nosferapti en vol dans la galerie est.
	_set_companion(&"zubat", 12)
	await _put(Vector2i(52, 36), Vector2i.UP)
	await _step(Vector2i.UP)
	await _step(Vector2i.UP)
	await _frames(20)
	_shot("compagnon_nosferapti")
	# Potion du B1F.
	var router: Node = root.get_node(^"SceneRouter")
	router.call(&"change_map", &"mt_moon_b1f", &"arrivee_a", Vector2i.DOWN)
	while _map().map_id != &"mt_moon_b1f" or bool(router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)
	await _put(Vector2i(16, 22), Vector2i.UP)
	await _frames(15)
	_shot("potion_b1f")
	print("CAPTURE_MT_MOON_T21 terminé")
	quit()
