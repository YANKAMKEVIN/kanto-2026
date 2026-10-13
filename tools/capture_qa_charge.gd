extends SceneTree
## Captures de la carte de QA du jalon 14 (T10) : départ `charge_qa` (carte, Dresseur qui
## interpelle, combat) ou `teleport_qa` (herbes, combat contre Abra).
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/qa.png --fixed-fps 15 \
##     -s res://tools/capture_qa_charge.gd -- --start=charge_qa --out=build/captures/jalon14_t10

const BOOT_SCENE := "res://game/boot.tscn"
const START_DIR := "res://tools/debug_start/"

var _out_dir: String = ""
var _start_name: String = "charge_qa"
var _boot: Node
var _player: Node2D


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--start="):
			_start_name = arg.trim_prefix("--start=")
	process_frame.connect(_begin, CONNECT_ONE_SHOT)


func _begin() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START_DIR + _start_name + ".json")
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	root.get_node(^"SceneRouter").set(&"fade_in_duration", 0.1)
	_run()


func _run() -> void:
	await _seconds(2.0)
	_player = _boot.call(&"get_player")
	await _shot("1_%s_depart" % _start_name)
	if _start_name == "charge_qa":
		Input.action_press(&"move_right")
		await _seconds(1.2)
		Input.action_release(&"move_right")
		await _seconds(1.0)
		await _shot("2_dresseur_interpelle")
	else:
		Input.action_press(&"move_down")
		for i in 40:
			await _seconds(0.4)
			if not _player.call(&"is_input_enabled"):
				break
		Input.action_release(&"move_down")
		await _seconds(1.0)
		await _shot("2_herbes_rencontre")
	for i in 8:
		Input.action_press(&"interact")
		await _seconds(0.3)
		Input.action_release(&"interact")
		await _seconds(1.0)
	await _seconds(2.0)
	await _shot("3_combat")
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
