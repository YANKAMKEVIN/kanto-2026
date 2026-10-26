extends SceneTree
## Captures du jalon Son (Son.0, T5) sur le vrai Boot, réglages et sauvegarde en mémoire (le
## vrai `user://` n'est jamais lu ni écrit) :
##   menu_sound        Paramètres du Menu Dresseur, catégorie SON (défauts 70 / 80 / 80)
##   menu_sound_muted  même écran après avoir mis la Musique à 0
##   title_sound       Paramètres de l'écran titre, catégorie SON
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_settings_son.gd \
##     -- --out=build/captures/son0

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const ABSENT: String = "user://cap_son0_absent.json"

var _out_dir: String = "build/captures/son0"
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	# Menu Dresseur, sur la Route 1.
	var fs: RefCounted = (load(MEMORY_FS) as GDScript).new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	_boot.set(&"settings_store", (load(STORE) as GDScript).new(fs, "user://cap_son0.json"))
	root.add_child(_boot)
	await _frames(60)
	_boot.call(&"get_trainer_menu").set(&"speed_scale", 0.0)
	var director: Node = _boot.call(&"get_menu_director")
	director.call(&"open", load("res://game/systems/menu/menu_route.gd").call(&"settings"))
	await _frames(10)
	var screen: Node = _boot.call(&"get_trainer_menu").call(&"get_settings")
	screen.call(&"select_category", &"sound")
	await _frames(10)
	await _shot("menu_sound")
	screen.emit_signal(&"setting_changed", &"music_volume", 0.0)
	await _frames(10)
	await _shot("menu_sound_muted")
	_boot.free()
	_boot = null

	# Écran titre, sans sauvegarde.
	fs = (load(MEMORY_FS) as GDScript).new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(fs, "user://cap_son0_save.json"))
	_boot.set(&"settings_store", (load(STORE) as GDScript).new(fs, "user://cap_son0_t.json"))
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	_boot.set(&"opening_speed_scale", 0.0)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	await _frames(45)
	var title: Node = _boot.call(&"get_opening").call(&"get_screen")
	title.call(&"get_entry_button", &"settings").pressed.emit()
	await _frames(20)
	var settings: Node = title.call(&"get_settings")
	settings.call(&"select_category", &"sound")
	await _frames(10)
	await _shot("title_sound")
	current_scene = null
	_boot.free()
	print("CAPTURE_SON0 terminé : %s" % _out_dir)
	quit()


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : %s/%s.png" % [_out_dir, name])
