extends SceneTree
## Captures de la vie de la Route 25 (jalon 14 T16) sur le vrai Boot (départ `route_25`) :
## `--scene=spot` (D1 interpelle : « ! » puis réplique « avant »), `cove` (la crique, D4 et la
## Potion), `cape` (le Cap : panneau, maison, vieil homme), `terrace` (D3, CT19), `open` (le
## chemin à l'ouest : promeneur, D1).
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/r25.png --fixed-fps 15 \
##     -s res://tools/capture_route_25_life.gd -- --scene=spot --out=build/captures/j14_t16

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/route_25.json"

var _out_dir: String = ""
var _scene: String = "spot"
var _boot: Node
var _player: Node2D


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	root.get_node(^"SceneRouter").set(&"fade_in_duration", 0.1)
	_run()


func _place(cell: Vector2i, facing: Vector2i) -> void:
	_boot.call(&"get_map").call(&"spawn_player_at", _player, cell, facing)


func _run() -> void:
	await _seconds(2.0)
	_player = _boot.call(&"get_player")
	var runner: Object = _boot.call(&"get_dialogue_runner")
	runner.set(&"chars_per_second", 0.0)
	match _scene:
		"spot":
			_place(Vector2i(15, 14), Vector2i.RIGHT)
			await _seconds(0.5)
			Input.action_press(&"move_right")
			var jules: Node = _boot.call(&"get_map").call(&"get_npc", &"youngster_jules")
			for i in 150:
				await process_frame
				if jules.call(&"is_emoting"):
					break
			Input.action_release(&"move_right")
			await _frames(2)
			await _shot("1_exclamation")
			await _seconds(1.5)
			await _shot("2_approche")
			await _seconds(1.5)
			await _shot("3_replique_avant")
		"cove":
			_place(Vector2i(38, 15), Vector2i.DOWN)
			await _seconds(1.0)
			await _shot("cove_d4")
			_place(Vector2i(36, 19), Vector2i.RIGHT)
			await _seconds(1.0)
			await _shot("cove_potion")
		"cape":
			_place(Vector2i(69, 13), Vector2i.UP)
			await _seconds(1.0)
			await _shot("cape_panneau")
			_place(Vector2i(64, 14), Vector2i.RIGHT)
			await _seconds(1.0)
			await _shot("cape_maison")
			_place(Vector2i(64, 19), Vector2i.DOWN)
			await _seconds(1.0)
			await _shot("cape_coquillage")
			Input.action_press(&"interact")
			await _seconds(0.2)
			Input.action_release(&"interact")
			await _seconds(1.0)
			await _shot("cape_coquillage_texte")
		"terrace":
			_place(Vector2i(28, 8), Vector2i.RIGHT)
			await _seconds(1.0)
			await _shot("terrasse")
		"open":
			_place(Vector2i(9, 14), Vector2i.RIGHT)
			await _seconds(1.0)
			await _shot("ouest")
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
