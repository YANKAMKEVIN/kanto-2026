extends SceneTree
## Captures du choix de l'apparence (chantier JR) sur le vrai Boot, sauvegarde et réglages en
## mémoire (le vrai `user://` n'est jamais lu ni écrit) :
##   01_look_player_hero      choix du joueur, première carte (héros) choisie
##   02_look_player_heroine   seconde carte touchée : la joueuse habille le portrait
##   03_name_heroine          écran de prénom de la joueuse (Leaf, Céleste, Kelly)
##   04_look_rival_rivale     choix du rival, la rivale choisie
##   05_rival_page            « Et elle, tu la connais depuis toujours. C'est ma petite-fille. »
##   06_rival_name            écran de prénom de la rivale (Régine, Green, Iris)
##   07_bedroom               la chambre : la joueuse
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_jr_look.gd \
##     -- --out=build/captures/jr

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const SAVE_PATH: String = "user://cap_jr_save.json"
const ABSENT: String = "user://cap_jr_absent.json"

var _out_dir: String = "build/captures/jr"
var _boot: Node
var _fs: RefCounted


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	await _launch()
	await _new_game()
	await _until_look()
	await _shot("01_look_player_hero")
	_stage().call(&"select_look", 1)
	await _frames(30)
	await _shot("02_look_player_heroine")
	_stage().call(&"validate_look")
	await _until(func() -> bool: return _intro().call(&"is_waiting_for_name"))
	await _frames(20)
	await _shot("03_name_heroine")
	_intro().call(&"submit_name", "Leaf")
	await _until_look()
	_stage().call(&"select_look", 1)
	await _frames(30)
	await _shot("04_look_rival_rivale")
	_stage().call(&"validate_look")
	await _frames(10)
	await _reveal()
	await _frames(20)
	await _shot("05_rival_page")
	await _until(func() -> bool: return _intro().call(&"is_waiting_for_name"))
	await _frames(20)
	await _shot("06_rival_name")
	_intro().call(&"submit_name", "Régine")
	await _until(func() -> bool: return _opening().call(&"is_finished"))
	await _frames(90)
	await _shot("07_bedroom")
	current_scene = null
	_boot.free()
	quit()


func _launch() -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	var store: RefCounted = (load(STORE) as GDScript).new(_fs, "user://cap_jr.json")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(_fs, SAVE_PATH))
	_boot.set(&"settings_store", store)
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	_boot.set(&"opening_speed_scale", 0.2)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	await _frames(45)


func _new_game() -> void:
	var screen: Node = _opening().call(&"get_screen")
	screen.call(&"get_entry_button", &"new_game").pressed.emit()
	await _frames(20)
	var confirm: Node = screen.call(&"get_confirm")
	if confirm.call(&"is_showing"):
		confirm.call(&"get_confirm_button").pressed.emit()
	for i: int in 200:
		await process_frame
		if _intro() != null:
			break
	await _frames(10)


## Avance jusqu'au prochain choix d'apparence (cartes ouvertes).
func _until_look() -> void:
	await _until(func() -> bool: return _intro().call(&"is_waiting_for_look"))
	await _frames(30)


## Avance l'introduction (Oui aux confirmations) jusqu'à [param done].
func _until(done: Callable) -> void:
	for i: int in 3000:
		if done.call():
			return
		var intro: Node = _intro()
		if intro != null and intro.call(&"is_running") and not intro.call(&"is_staging"):
			if intro.call(&"is_waiting_for_choice"):
				intro.call(&"answer", true)
			elif not intro.call(&"is_waiting_for_name") and not intro.call(&"is_waiting_for_look"):
				intro.call(&"advance")
		await process_frame


func _reveal() -> void:
	var intro: Node = _intro()
	if intro != null and not intro.call(&"is_text_complete"):
		intro.call(&"advance")
	await _frames(2)


func _opening() -> Node:
	return _boot.call(&"get_opening")


func _intro() -> Node:
	return _opening().call(&"get_intro")


func _stage() -> Node:
	return _opening().call(&"get_intro_stage")


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("capture : %s/%s.png" % [_out_dir, name])
