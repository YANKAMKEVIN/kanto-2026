extends SceneTree
## Captures de l'animation du Vol (2026-11-19) : la vraie scène Boot sur un départ de débogage,
## un Vol lancé, les dialogues passés tout seuls, une image tous les `--every` images.
## À lancer sur le Mac (pas en headless), en 2340 × 1080 :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_fly_frames.gd \
##     -- --start=fly_qa --zone=viridian_city --out=build/captures/vol [--every=6] [--count=80]

const ABSENT := "res://tools/debug_start/__absent__.json"

var _start: String = "fly_qa"
var _zone: String = "viridian_city"
var _out: String = "build/captures/vol"
var _every: int = 6
var _count: int = 80
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			_start = arg.trim_prefix("--start=")
		elif arg.begins_with("--zone="):
			_zone = arg.trim_prefix("--zone=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--every="):
			_every = int(arg.trim_prefix("--every="))
		elif arg.begins_with("--count="):
			_count = int(arg.trim_prefix("--count="))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % _start)
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_unlocks_path", ABSENT)
	root.add_child(_boot)
	for _i: int in 90:
		await process_frame
	var fly: Node = _boot.call(&"get_fly_director")
	print("VOL : check → %d" % int(fly.call(&"check", StringName(_zone))))
	fly.call(&"fly", StringName(_zone))
	for shot: int in _count:
		for _i: int in _every:
			await process_frame
		# Passe les dialogues (envol, atterrissage) : un appui bref sur « interact ».
		if shot % 4 == 0:
			Input.action_press(&"interact")
			await process_frame
			Input.action_release(&"interact")
		var image := root.get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path("res://") + "%s/%03d.png" % [_out, shot])
	quit()
