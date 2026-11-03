extends SceneTree
## Plans de la bande-annonce de l'ident (J34) : la vraie scène Boot lancée sur un départ de
## débogage nommé (`tools/debug_start/<nom>.json`), HUD d'exploration caché, puis une capture du
## viewport une fois le décor posé. À lancer sur le Mac (pas en headless), en 2340 × 1080 :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_trailer.gd \
##     -- --start=pallet_town --out=build/captures/trailer/pallet_town.png [--frames=90]
##     [--walk=down:3,left:2] [--hud]
##
## `--walk` : pas du joueur avant la capture (actions `move_*` tenues), pour s'éloigner du point
## d'apparition ; `--hud` garde le HUD (défaut : caché, la bande-annonce montre le monde).
## Série : `tools/capture_trailer.sh`.

const ABSENT: String = "user://cap_trailer_absent.json"

var _start: String = "pallet_town"
var _out: String = "build/captures/trailer/shot.png"
var _frames: int = 90
var _walk: Array[Array] = []
var _hud: bool = false
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			_start = arg.trim_prefix("--start=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frames="):
			_frames = int(arg.trim_prefix("--frames="))
		elif arg.begins_with("--walk="):
			for step: String in arg.trim_prefix("--walk=").split(",", false):
				var parts := step.split(":")
				_walk.append([parts[0], int(parts[1]) if parts.size() > 1 else 1])
		elif arg == "--hud":
			_hud = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out.get_base_dir())
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % _start)
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_unlocks_path", ABSENT)
	root.add_child(_boot)
	await _wait(30)
	if not _hud:
		var hud: CanvasLayer = _boot.call(&"get_hud")
		if hud != null:
			hud.visible = false
	for step: Array in _walk:
		var action: StringName = StringName("move_" + str(step[0]))
		for _i: int in int(step[1]):
			Input.action_press(action)
			await _wait(14)
			Input.action_release(action)
			await _wait(4)
	await _wait(_frames)
	root.get_texture().get_image().save_png(_out)
	print("TRAILER : %s → %s" % [_start, _out])
	quit()


func _wait(n: int) -> void:
	for _i: int in n:
		await process_frame
