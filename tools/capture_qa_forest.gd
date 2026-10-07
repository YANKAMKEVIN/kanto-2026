extends SceneTree
## Captures de la carte de QA du jalon 9 (jalon-09.md §2.6, T6) : départ `poison_qa` (le garde
## interpelle le joueur), puis déplacement et plans de la carte.
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/qa.png --fixed-fps 15 \
##     -s res://tools/capture_qa_forest.gd -- --out=build/captures/jalon09_t6

const BOOT_SCENE := "res://game/boot.tscn"
const START_DIR := "res://tools/debug_start/"

var _out_dir: String = ""
var _boot: Node
var _player: Node2D


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START_DIR + "poison_qa.json")
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	root.get_node(^"SceneRouter").set(&"fade_in_duration", 0.1)
	_run()


func _run() -> void:
	await _seconds(2.0)
	_player = _boot.call(&"get_player")
	var flags: Object = root.get_node(^"GameState").get(&"flags")
	print("poison_unlocked après l'arrivée : ", flags.call(&"has_flag", &"poison_unlocked"))
	await _shot("1_poison_garde_auto")
	# Ferme le dialogue (appuis sur interact), puis le drapeau doit être posé.
	for i in 12:
		if _player.call(&"is_input_enabled") and i > 1:
			break
		Input.action_press(&"interact")
		await _seconds(0.3)
		Input.action_release(&"interact")
		await _seconds(0.5)
	print("poison_unlocked après le dialogue : ", flags.call(&"has_flag", &"poison_unlocked"))
	_teleport(Vector2i(7, 17), Vector2i.LEFT)
	await _seconds(0.5)
	await _shot("2_herbes_avant")
	Input.action_press(&"move_left")
	await _seconds(0.9)
	Input.action_release(&"move_left")
	await _seconds(0.4)
	await _shot("3_herbes_apres")
	_teleport(Vector2i(20, 12), Vector2i.LEFT)
	await _seconds(0.5)
	await _shot("4_couloir_theo")
	_teleport(Vector2i(10, 4), Vector2i.RIGHT)
	await _seconds(0.5)
	await _shot("5_clairiere_noe_milo")
	_teleport(Vector2i(20, 3), Vector2i.RIGHT)
	await _seconds(0.5)
	await _shot("6_tom_eli")
	quit()


func _teleport(cell: Vector2i, facing: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, cell, facing)


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
	var path := _out_dir.path_join("%s.png" % capture_name)
	root.get_texture().get_image().save_png(path)
