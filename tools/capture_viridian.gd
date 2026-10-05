extends SceneTree
## Captures de Jadielle (jalon 7 T4, agrandie au T5) avec la vraie scène Boot et le départ de débogage
## `tools/debug_start/viridian.json` (entrée sud, prologue fait) :
##
##   godot --path . --write-movie build/cap/viridian.avi --fixed-fps 30 \
##     -s res://tools/capture_viridian.gd -- --out=build/captures/jalon07_t4
##   godot --path . -s res://tools/capture_viridian.gd -- --perf=20
##
## 2340 × 1080 sur le Mac : `override.cfg` temporaire à la racine ([display]
## window/size/window_width_override=2340, window_height_override=1080), à retirer après.
##
## Déroulé (images enregistrées sous --out, lues depuis la texture du viewport) :
## - viridian_arrival_00_entry : arrivée (titre JADIELLE) ; « haut » tenu jusqu'à la scène ;
##   _01_run (l'enfant derrière son Rattata), _02_pidgey (le Roucool s'envole),
##   _03_traveler (le voyageur croise le joueur), _04_after (contrôles rendus) ; la durée
##   de la scène est écrite dans le journal ;
## - viridian_square : retour par la porte du Centre (nouvelle visite : habitants et routines) ;
##   viridian_square_east, viridian_north_stair, viridian_south_quarter, viridian_west_exit
##   (vers la Route 22), viridian_gym_stair (terrasse de l'Arène) ;
## - viridian_gym : devant l'Arène, porte examinée (« La porte est verrouillée. ») ;
## - viridian_north_exit : sous l'arche ; viridian_route2_soon : écran « ROUTE 2 — À venir ».
## `--perf=<s>` : place centrale, habitants en mouvement, journal `[perf]` (fps, mémoire des
## textures) pendant <s> secondes sans synchronisation verticale, puis quitte.
## `--perf-map=<carte>` : même mesure ailleurs (spawn « start »), pour comparer.

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/viridian.json"

var _out_dir: String = ""
var _perf: float = 0.0
## Carte de la mesure (comparaison) ; défaut Jadielle.
var _perf_map: StringName = &"viridian_city"
var _boot: Node
var _player: Node2D
var _router: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--perf-map="):
			_perf_map = StringName(arg.trim_prefix("--perf-map="))
		elif arg.begins_with("--perf="):
			_perf = float(arg.trim_prefix("--perf="))
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	_router = root.get_node(^"SceneRouter")
	_router.set(&"fade_out_duration", 0.15)
	_router.set(&"fade_in_duration", 0.15)
	_run()


func _run() -> void:
	await _frames(3)
	_player = _boot.call(&"get_player")
	if _perf > 0.0:
		await _run_perf()
		return
	await _seconds(1.0)
	await _shot("viridian_arrival_00_entry")
	var director: Node = _boot.call(&"get_cutscene_director")
	Input.action_press(&"move_up")
	await _until(func() -> bool: return director.call(&"is_running"), 5.0)
	Input.action_release(&"move_up")
	var started := Time.get_ticks_msec()
	var frame_start := Engine.get_process_frames()
	await _seconds(0.55)
	await _shot("viridian_arrival_01_run")
	await _until(func() -> bool: return int(director.call(&"get_step_index")) >= 2, 4.0)
	await _seconds(0.15)
	await _shot("viridian_arrival_02_pidgey")
	await _seconds(0.6)
	await _shot("viridian_arrival_03_traveler")
	await _until(func() -> bool: return not director.call(&"is_running"), 6.0)
	print("ARRIVAL scene : %d images (à 30 i/s fixes : %.2f s de jeu), %d ms réels" % [
		Engine.get_process_frames() - frame_start,
		(Engine.get_process_frames() - frame_start) / 30.0, Time.get_ticks_msec() - started])
	await _seconds(0.3)
	await _shot("viridian_arrival_04_after")
	# Nouvelle visite : retour par la porte du Centre.
	_router.call(&"change_map", &"viridian_city", &"from_center", Vector2i.DOWN)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	_teleport(Vector2i(28, 22), Vector2i.UP)
	await _seconds(3.0)
	await _shot("viridian_square")
	_teleport(Vector2i(33, 23), Vector2i.RIGHT)
	await _seconds(2.0)
	await _shot("viridian_square_east")
	_teleport(Vector2i(28, 14), Vector2i.UP)
	await _seconds(1.0)
	await _shot("viridian_north_stair")
	_teleport(Vector2i(28, 28), Vector2i.DOWN)
	await _seconds(1.0)
	await _shot("viridian_south_quarter")
	_teleport(Vector2i(2, 22), Vector2i.LEFT)
	await _seconds(1.0)
	await _shot("viridian_west_exit")
	_teleport(Vector2i(10, 15), Vector2i.UP)
	await _seconds(1.0)
	await _shot("viridian_gym_stair")
	_teleport(Vector2i(10, 10), Vector2i.UP)
	await _seconds(0.8)
	await _shot("viridian_gym_front")
	await _tap_interact()
	await _seconds(1.5)
	await _shot("viridian_gym")
	await _tap_interact()
	await _seconds(0.6)
	_teleport(Vector2i(28, 3), Vector2i.UP)
	await _seconds(0.8)
	await _shot("viridian_north_exit")
	Input.action_press(&"move_up")
	var screen: Node = _boot.call(&"get_coming_soon_screen")
	await _until(func() -> bool: return screen.call(&"is_showing"), 5.0)
	Input.action_release(&"move_up")
	await _seconds(0.5)
	await _shot("viridian_route2_soon")
	await _seconds(3.0)
	quit()


## Place centrale, habitants en mouvement, journal [perf] pendant _perf secondes.
func _run_perf() -> void:
	root.get_node(^"GameState").get(&"flags").call(&"set_flag", &"viridian_arrived")
	if _perf_map == &"viridian_city":
		_router.call(&"change_map", &"viridian_city", &"from_center", Vector2i.DOWN)
		await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
		_teleport(Vector2i(28, 22), Vector2i.UP)
	else:
		_router.call(&"change_map", _perf_map, &"start", Vector2i.DOWN)
		await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	await _seconds(1.0)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if _boot.get_node_or_null(^"PerfCounter") == null:
		var counter: Node = (load("res://game/systems/debug/perf_counter.gd") as Script).new()
		root.add_child(counter)
	print("perf : mémoire des textures %.1f Mo" % [
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
	await _seconds(_perf)
	quit()


## Appui bref sur `interact` passé par la file d'entrée (just_pressed fiable).
func _tap_interact() -> void:
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(3)
	var release := InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(2)


func _teleport(cell: Vector2i, facing: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, cell, facing)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _until(condition: Callable, timeout: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await process_frame
		waited += root.get_process_delta_time()


func _shot(capture_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE %s cell=%s" % [capture_name, _player.call(&"get_cell")])
	if _out_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  → %s" % path)
