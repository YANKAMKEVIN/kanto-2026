extends SceneTree
## Vidéo de l'ident de démarrage (J34) : Boot lancé comme par le moteur (scène courante), sans
## sauvegarde, vitesse réelle ; l'ident joue, le titre apparaît, on tient une seconde, puis on quitte.
## À lancer en Movie Maker (image fixe à 30 i/s, rendu déterministe), puis convertir en mp4 :
##
##   godot --path . --resolution 2340x1080 --write-movie build/captures/j34/ident.avi \
##     --fixed-fps 30 -s res://tools/capture_ident_video.gd
##   ffmpeg -y -i build/captures/j34/ident.avi -vf scale=1170:-2 -c:v libx264 -pix_fmt yuv420p \
##     -crf 20 build/captures/j34/ident.mp4
##
## Option : `-- --skip-at=2.5` passe l'ident par un toucher simulé à 2,5 s (test du passage).

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const ABSENT: String = "user://cap_ident_absent.json"
const TAIL_SECONDS: float = 1.2

var _boot: Node
var _skip_at: float = -1.0
var _elapsed: float = 0.0
var _skipped: bool = false
var _tail: float = -1.0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--skip-at="):
			_skip_at = float(arg.trim_prefix("--skip-at="))
	process_frame.connect(_launch, CONNECT_ONE_SHOT)


func _launch() -> void:
	var fs: RefCounted = (load(MEMORY_FS) as GDScript).new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(fs, "user://cap_ident_save.json"))
	_boot.set(&"settings_store", (load(STORE) as GDScript).new(fs, "user://cap_ident_settings.json"))
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	_boot.set(&"opening_speed_scale", 1.0)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	var opening: Node = _boot.call(&"get_opening")
	opening.connect(&"title_revealed", _on_title_revealed)
	print("IDENT : lancé (passage à %.1f s)" % _skip_at if _skip_at >= 0.0 else "IDENT : lancé")


func _process(delta: float) -> bool:
	_elapsed += delta
	if _skip_at >= 0.0 and not _skipped and _elapsed >= _skip_at and _boot != null:
		var opening: Node = _boot.call(&"get_opening")
		var ident: Node = opening.call(&"get_ident")
		if ident != null:
			ident.call(&"skip")
			_skipped = true
			print("IDENT : passé à %.2f s" % _elapsed)
	if _tail >= 0.0:
		_tail -= delta
		if _tail <= 0.0:
			print("IDENT : fin à %.2f s" % _elapsed)
			quit()
	return false


func _on_title_revealed() -> void:
	print("IDENT : titre découvert à %.2f s" % _elapsed)
	_tail = TAIL_SECONDS
