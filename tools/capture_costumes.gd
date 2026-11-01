extends SceneTree
## Captures des costumes (dossier-costumes.md) sur le vrai Boot, sauvegarde et réglages en
## mémoire (le vrai `user://` n'est jamais lu ni écrit). Partie de Kevin (fixture v1) avec les
## badges Roche, Cascade et Foudre (état de capture), costume Roche porté :
##   01_title_continue     carte Continuer : le buste porte le costume
##   02_world              le joueur du monde en costume
##   03_trainer            écran Dresseur : section « Costumes » (tenue d'origine, 3 débloqués,
##                         5 silhouettes), portrait en costume
##   04_trainer_locked     une silhouette touchée : « Se débloque avec un nouveau badge. »
##   05_trainer_chosen     le costume Cascade choisi : portrait et section mis à jour
##   06_dashboard          tableau de bord : buste en costume
##   08_map               carte du menu : la tête du buste en costume dans le rond du joueur
##   07_world_toast        menu fermé, le joueur rhabillé, annonce « Nouveau costume : … » (CO-4)
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_costumes.gd \
##     -- --out=build/captures/costumes [--look=heroine]

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const SAVE_PATH: String = "user://cap_co_save.json"
const ABSENT: String = "user://cap_co_absent.json"
const FIXTURE: String = "res://tests/fixtures/save/v1_after_capture.json"

var _out_dir: String = "build/captures/costumes"
var _look: String = "hero"
var _boot: Node
var _fs: RefCounted


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--look="):
			_look = arg.trim_prefix("--look=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	(load(SAVE) as GDScript).call(&"upgrade", content)
	var flags: Array = content.get("flags", [])
	flags.append_array(["badge_boulder", "badge_cascade", "badge_thunder"])
	content["flags"] = flags
	content["player_look"] = _look
	content["player_costume"] = "boulder"
	var save: RefCounted = (load(SAVE) as GDScript).new(_fs, SAVE_PATH)
	save.call(&"write", content)
	var store: RefCounted = (load(STORE) as GDScript).new(_fs, "user://cap_co.json")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(_fs, SAVE_PATH))
	_boot.set(&"settings_store", store)
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	await _frames(60)
	await _shot("01_title_continue")
	var screen: Node = _boot.call(&"get_opening").call(&"get_screen")
	screen.call(&"get_entry_button", &"continue").pressed.emit()
	for i: int in 600:
		await process_frame
		if _boot.call(&"is_stable"):
			break
	await _frames(60)
	await _shot("02_world")
	var menu: Node = _boot.call(&"get_menu_director")
	var trainer_menu: Node = _boot.call(&"get_trainer_menu")
	trainer_menu.set(&"speed_scale", 0.0)
	menu.call(&"open", (load("res://game/systems/menu/menu_route.gd") as GDScript).call(&"trainer"))
	await _frames(30)
	await _shot("03_trainer")
	var slots: Array = trainer_menu.call(&"get_trainer").call(&"get_costume_slots")
	(slots[5].call(&"get_hit") as Button).pressed.emit()
	await _frames(10)
	await _shot("04_trainer_locked")
	(slots[2].call(&"get_hit") as Button).pressed.emit()
	await _frames(20)
	await _shot("05_trainer_chosen")
	menu.call(&"handle_back")
	await _frames(20)
	await _shot("06_dashboard")
	menu.call(&"go", (load("res://game/systems/menu/menu_route.gd") as GDScript).call(&"map"))
	await _frames(30)
	await _shot("08_map")
	menu.call(&"close")
	await _frames(30)
	var step: Object = (load("res://game/systems/cutscene/cutscene_step.gd") as GDScript).new()
	step.set(&"kind", (step.get_script() as Script).get_script_constant_map()["Kind"]["BADGE"])
	step.set(&"badge_id", &"thunder")
	_boot.call(&"_on_costume_badge_step", step)
	_boot.call(&"_announce_costume")
	await _frames(25)
	await _shot("07_world_toast")
	quit()


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : %s/%s.png" % [_out_dir, name])
