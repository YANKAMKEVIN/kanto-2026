extends SceneTree
## Captures du jalon 9 (T12) : le « ! » d'un Dresseur, l'approche, la réplique « avant », puis le
## Dresseur battu (drapeau posé) qui dit sa réplique « après ». Depuis la clôture du J9 (T23) :
## sur la vraie Forêt de Jade (départ `trainers_weak_qa`, spawn `before_theo`, quatre pas à
## l'ouest de la vue de Scout Théo).
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/t12.png --fixed-fps 15 \
##     -s res://tools/capture_trainer_spotted.gd -- --out=build/captures/jalon09_t12

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/trainers_weak_qa.json"

var _out_dir: String = ""
var _boot: Node
var _player: Node2D
var _theo: Node2D
var _after_only: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		if arg == "--after":
			_after_only = true
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	root.get_node(^"SceneRouter").set(&"fade_in_duration", 0.1)
	_run()


func _run() -> void:
	await _seconds(2.0)
	_player = _boot.call(&"get_player")
	_theo = _boot.call(&"get_map").call(&"get_npc", &"scout_theo")
	if _after_only:
		var flags: Object = root.get_node(^"GameState").get(&"flags")
		flags.call(&"set_flag", &"beaten_forest_scout_theo")
		var map: Node = _boot.call(&"get_map")
		map.call(&"spawn_player_at", _player, Vector2i(30, 68), Vector2i.UP)
		await _seconds(0.5)
		Input.action_press(&"interact")
		await _seconds(0.2)
		Input.action_release(&"interact")
		await _seconds(1.5)
		await _shot("6_replique_apres")
		quit()
		return
	await _shot("1_avant_la_ligne")
	Input.action_press(&"move_left")
	for i in 150:
		await process_frame
		if _theo.call(&"is_emoting"):
			break
	Input.action_release(&"move_left")
	# « ! » : quelques images après l'apparition (rebond puis tenue).
	await _frames(1)
	await _shot("2_exclamation_rebond")
	await _frames(1)
	await _shot("3_exclamation_tenue")
	await _seconds(1.0)
	await _shot("4_approche")
	await _seconds(1.5)
	await _shot("5_replique_avant")
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await _frames(ceili(seconds * 15.0))


func _shot(capture_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURE %s cell=%s out=%s" % [capture_name, _player.call(&"get_cell"), _out_dir])
	OS.delay_msec(1)
	if _out_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(_out_dir.path_join("%s.png" % capture_name))
