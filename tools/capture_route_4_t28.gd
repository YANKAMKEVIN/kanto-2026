extends SceneTree
## Captures du sas de la Route 4 (jalon 12, T28) sur le vrai Boot, départ `route_4` :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_route_4_t28.gd \
##     -- --out=build/captures/jalon12_t28
## Images : sas_arrivee (arrivée de B2F, joueur et compagnon), sas_panneau (bulle « ROUTE 4 »),
## objectif_azuria (tableau de bord après le premier pas vers l'est), sas_raccord_est (devant le
## raccord « AZURIA — À venir »), azuria_a_venir (écran « à venir », build de développement).

const START := "res://tools/debug_start/route_4.json"
const TIMEOUT_MS := 30000

var _boot: Node
var _out_dir: String = "build/captures/jalon12_t28"


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
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _runner() -> DialogueRunner:
	return _boot.call(&"get_dialogue_runner")


func _step(direction: Vector2i) -> void:
	_player().script_step(direction)
	await _frames(1)
	while _player().is_moving():
		await process_frame
	await _frames(10)


func _interact() -> void:
	for attempt: int in 2:
		Input.action_press(&"interact")
		await _frames(3)
		Input.action_release(&"interact")
		await _frames(30)
		if _runner().is_running():
			return


func _close_dialogue() -> void:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	while _runner().is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await _frames(4)
	await _frames(20)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_4")
	_boot.set(&"start_spawn", &"from_mt_moon")
	_boot.set(&"start_facing", Vector2i.RIGHT)
	root.add_child(_boot)
	await _frames(5)
	var state: Node = root.get_node(^"GameState")
	var start := DebugStart.new()
	if not start.load_file(START, _boot.call(&"get_pokemon_data"),
			_boot.call(&"get_item_library")):
		push_error("\n".join(start.get_errors()))
		quit(1)
		return
	start.apply(state, _boot.call(&"get_pokemon_data"))
	_runner().chars_per_second = 0.0
	_map().refresh_npcs(state.get(&"flags") as StoryFlags)
	await _frames(60)
	await _shot("sas_arrivee")
	# Premier pas vers l'est : `route_4_reached` en silence.
	await _step(Vector2i.RIGHT)
	await _frames(20)
	print("route_4_reached = ", (state.get(&"flags") as StoryFlags).has_flag(&"route_4_reached"))
	# Panneau lu de face depuis (6, 6).
	await _step(Vector2i.RIGHT)
	await _step(Vector2i.RIGHT)
	_player().script_step(Vector2i.UP)
	await _frames(15)
	await _interact()
	await _frames(30)
	await _shot("sas_panneau")
	await _close_dialogue()
	# Objectif au tableau de bord.
	var menu: Node = _boot.call(&"get_menu_director")
	menu.call(&"open", MenuRoute.dashboard())
	await _frames(90)
	await _shot("objectif_azuria")
	menu.call(&"close")
	await _frames(60)
	# Raccord est.
	_player().enter_map(_map().get_grid(), Vector2i(21, 6), Vector2i.RIGHT,
		_map().get_pixel_rect())
	await _frames(30)
	await _shot("sas_raccord_est")
	await _step(Vector2i.RIGHT)
	Input.action_press(&"move_right")
	var screen: Node = _boot.call(&"get_coming_soon_screen")
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not bool(screen.call(&"is_showing")) and Time.get_ticks_msec() < deadline:
		await process_frame
	Input.action_release(&"move_right")
	await _frames(40)
	await _shot("azuria_a_venir")
	print("CAPTURE_ROUTE_4_T28 terminé")
	quit()
