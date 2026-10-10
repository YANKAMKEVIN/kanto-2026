extends SceneTree
## Captures de l'écran titre (OUV.1) sur le vrai Boot lancé en scène courante, sauvegarde et
## réglages en mémoire (le vrai `user://` n'est jamais lu ni écrit) :
##   title_none         sans sauvegarde
##   title_valid        sauvegarde valide (partie de Kevin en v4, fixture)
##   title_corrupt      sauvegarde corrompue (mise de côté)
##   title_newer        sauvegarde d'une version plus récente
##   title_confirm      Nouvelle partie sur une sauvegarde valide : la confirmation
##   title_settings     Paramètres depuis le titre (catégorie JEU, sans « Sauvegarder maintenant »)
##   title_left_handed  titre en mode gaucher (réglage changé depuis les Paramètres du titre)
##   bedroom            après la confirmation : la chambre (départ inchangé)
##   continue           après Continuer : la partie reprise
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_title_ouv1.gd \
##     -- --out=build/captures/ouv1

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const FIXTURE_V4: String = "res://tests/fixtures/save/v4_kevin_depuis_s24_j8.json"
const SAVE_PATH: String = "user://cap_ouv1_save.json"
const ABSENT: String = "user://cap_ouv1_absent.json"

var _out_dir: String = "build/captures/ouv1"
var _boot: Node
var _fs: RefCounted


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var fixture := FileAccess.get_file_as_string(FIXTURE_V4)
	var version: int = (load(SAVE) as GDScript).get(&"VERSION")
	await _launch("")
	await _shot("title_none")
	_kill()
	await _launch(fixture)
	await _shot("title_valid")
	_kill()
	await _launch("{ pas du json")
	await _shot("title_corrupt")
	_kill()
	await _launch(JSON.stringify({"version": version + 1, "map": "route_1"}))
	await _shot("title_newer")
	_kill()
	await _launch(fixture)
	var screen: Node = _opening().call(&"get_screen")
	screen.call(&"get_entry_button", &"new_game").pressed.emit()
	await _frames(20)
	await _shot("title_confirm")
	screen.call(&"get_confirm").call(&"get_confirm_button").pressed.emit()
	await _frames(60)
	await _shot("bedroom")
	_kill()
	await _launch(fixture)
	screen = _opening().call(&"get_screen")
	screen.call(&"get_entry_button", &"settings").pressed.emit()
	await _frames(20)
	await _shot("title_settings")
	var settings: Node = screen.call(&"get_settings")
	settings.emit_signal(&"setting_changed", &"left_handed", true)
	await _frames(5)
	settings.call(&"get_back_button").pressed.emit()
	await _frames(20)
	await _shot("title_left_handed")
	screen.call(&"get_entry_button", &"continue").pressed.emit()
	await _frames(60)
	await _shot("continue")
	_kill()
	print("CAPTURE_OUV1 terminé : %s" % _out_dir)
	quit()


## Boot comme lancé par le moteur (scène courante), sur une sauvegarde en mémoire ([param save] :
## texte du fichier, vide = aucune sauvegarde).
func _launch(save: String) -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	if not save.is_empty():
		(_fs.get(&"files") as Dictionary)[SAVE_PATH] = save
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(_fs, SAVE_PATH))
	_boot.set(&"settings_store", (load(STORE) as GDScript).new(_fs, "user://cap_ouv1.json"))
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	_boot.set(&"opening_speed_scale", 0.0)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	# Le décor se charge, la caméra se pose, le rideau se lève.
	await _frames(45)


func _opening() -> Node:
	return _boot.call(&"get_opening")


func _kill() -> void:
	current_scene = null
	_boot.free()
	_boot = null


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : %s/%s.png" % [_out_dir, name])
