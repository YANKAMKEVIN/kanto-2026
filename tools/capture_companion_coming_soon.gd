extends SceneTree
## Capture du compagnon après l'écran « à venir » (correctif QA finale 12D, jalon 12) :
##   godot --path . --resolution 1170x540 --fixed-fps 30 \
##     -s res://tools/capture_companion_coming_soon.gd -- --out=build/captures/j12_soon
## Sas de la Route 4 : un pas vers l'ouest (il suit), retour au bord est, poussée → « AZURIA — À
## venir » → retour ; images before (avant l'écran), returned (au retour, il attend une case) et
## after_step (premier pas vers l'ouest : il est de nouveau derrière le joueur).

var _boot: Node
var _companion: Node
var _out_dir: String = "build/captures/j12_soon"


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
	print("CAPTURE ", name, " shown=", _companion.call(&"is_shown"))


func _player() -> Player:
	return _boot.call(&"get_player")


func _walk(action: StringName) -> void:
	var start := _player().get_cell()
	Input.action_press(action)
	while _player().get_cell() == start:
		await process_frame
	Input.action_release(action)
	while _player().is_moving():
		await process_frame
	await _frames(15)


func _start() -> void:
	var router: Node = root.get_node(^"SceneRouter")
	router.set(&"coming_soon_enabled", true)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_4")
	_boot.set(&"start_spawn", &"from_cerulean_n")
	_boot.set(&"start_facing", Vector2i.LEFT)
	root.add_child(_boot)
	await _frames(30)
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as StoryFlags).set_flag(&"starter_chosen")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	party.add(PokemonFactory.create(data, &"pikachu", 12, GameRng.new(7)))
	state.call(&"set_companion", party.get_at(0))
	_companion = _boot.call(&"get_companion_controller")
	_companion.call(&"refresh")
	await _walk(&"move_left")
	await _walk(&"move_right")
	await _shot("before")
	var screen: Node = _boot.call(&"get_coming_soon_screen")
	screen.set(&"hold_duration", 0.5)
	Input.action_press(&"move_right")
	while not bool(screen.call(&"is_showing")):
		await process_frame
	Input.action_release(&"move_right")
	while bool(screen.call(&"is_showing")) or bool(router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)
	await _shot("returned")
	await _walk(&"move_left")
	await _shot("after_step")
	print("CAPTURE_COMPANION_COMING_SOON terminé")
	quit()
