extends SceneTree
## Captures des transitions de l'ouverture (OUV.3) sur le vrai Boot lancé en scène courante,
## sauvegarde et réglages en mémoire (le vrai `user://` n'est jamais lu ni écrit) :
##   01_shrink             « Allez… en route ! » fini : le portrait du joueur rétrécit
##   02_dissolve           il se dissout dans la lumière, le blanc chaud monte
##   03_white              blanc chaud opaque
##   04_bedroom_from_white la chambre apparaît depuis le blanc
##   05_bedroom            la chambre, contrôle rendu (aucun titre de zone, aucun texte)
##   06_first_exit_legend  première sortie : « BOURG PALETTE / Le commencement de toute aventure »
##   07_reduced_white      « Réduire les animations » : pas de rétrécissement, blanc direct
##   08_reduced_bedroom    idem, la chambre depuis le blanc
##
##   godot --path . --resolution 2340x1080 --fixed-fps 60 \
##     -s res://tools/capture_transitions_ouv3.gd -- --out=build/captures/ouv3

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const FIXTURE_V4: String = "res://tests/fixtures/save/v4_kevin_s21.json"
const SAVE_PATH: String = "user://cap_ouv3_save.json"
const ABSENT: String = "user://cap_ouv3_absent.json"
const LAST_LINE: int = 31

var _out_dir: String = "build/captures/ouv3"
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
	await _launch(fixture)
	await _new_game()
	await _to_step(LAST_LINE)
	_real_speed()
	_intro().call(&"advance")
	await _until(func() -> bool: return _picture_scale() < 0.75)
	await _shot("01_shrink")
	await _until(func() -> bool: return _fade_alpha() > 0.35)
	await _shot("02_dissolve")
	await _until(func() -> bool: return _fade_alpha() >= 1.0)
	await _shot("03_white")
	await _until(func() -> bool: return _in_bedroom() and _fade_alpha() < 0.5)
	await _shot("04_bedroom_from_white")
	await _until(func() -> bool: return _player_free())
	await _frames(20)
	await _shot("05_bedroom")
	# Première sortie : escalier, rez-de-chaussée (Maman déjà saluée), porte.
	var state: Node = root.get_node(^"GameState")
	(state.get(&"flags") as RefCounted).call(&"set_flag", &"mom_greeted")
	var router: Node = root.get_node(^"SceneRouter")
	await router.call(&"change_map", &"player_house_1f", &"stairs")
	await _frames(10)
	await router.call(&"change_map", &"pallet_town", &"player_house_door")
	await _frames(30)
	await _shot("06_first_exit_legend")
	_kill()
	await _launch(fixture, true)
	await _new_game()
	await _to_step(LAST_LINE)
	_real_speed()
	_intro().call(&"advance")
	await _until(func() -> bool: return _fade_alpha() > 0.45)
	await _shot("07_reduced_white")
	await _until(func() -> bool: return _in_bedroom() and _fade_alpha() < 0.5)
	await _shot("08_reduced_bedroom")
	_kill()
	print("CAPTURE_OUV3 terminé : %s" % _out_dir)
	quit()


## La fin de l'introduction à vitesse réelle (le reste a été joué instantanément).
func _real_speed() -> void:
	_opening().set(&"speed_scale", 1.0)
	_stage().set(&"speed_scale", 1.0)


## Boot comme lancé par le moteur (scène courante), sur une sauvegarde en mémoire.
func _launch(save: String, reduce_motion: bool = false) -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	if not save.is_empty():
		(_fs.get(&"files") as Dictionary)[SAVE_PATH] = save
	var store: RefCounted = (load(STORE) as GDScript).new(_fs, "user://cap_ouv3.json")
	if reduce_motion:
		var settings: RefCounted = (load("res://game/systems/settings/game_settings.gd")
			as GDScript).new()
		settings.set(&"reduce_motion", true)
		store.call(&"save_settings", settings)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", (load(SAVE) as GDScript).new(_fs, SAVE_PATH))
	_boot.set(&"settings_store", store)
	_boot.set(&"debug_start_path", ABSENT)
	_boot.set(&"debug_unlocks_path", ABSENT)
	_boot.set(&"opening_speed_scale", 0.0)
	var boot := _boot
	boot.tree_entered.connect(func() -> void: current_scene = boot, CONNECT_ONE_SHOT)
	root.add_child(boot)
	await _frames(45)


## Nouvelle partie confirmée, jusqu'au début de l'introduction.
func _new_game() -> void:
	var screen: Node = _opening().call(&"get_screen")
	screen.call(&"get_entry_button", &"new_game").pressed.emit()
	await _frames(20)
	screen.call(&"get_confirm").call(&"get_confirm_button").pressed.emit()
	await _until(func() -> bool: return _intro() != null)
	await _frames(10)


## Avance l'introduction jusqu'à l'étape [param index] (scène posée, texte entier).
func _to_step(index: int) -> void:
	for i: int in 3000:
		var intro: Node = _intro()
		var reader: RefCounted = intro.call(&"get_reader")
		if int(reader.call(&"index")) >= index and not intro.call(&"is_staging"):
			break
		if not intro.call(&"is_staging"):
			if intro.call(&"is_waiting_for_name"):
				var prompt: StringName = (reader.call(&"current") as RefCounted).get(&"name")
				intro.call(&"submit_name", "Sacha" if prompt == &"player_name" else "Gary")
			elif intro.call(&"is_waiting_for_choice"):
				intro.call(&"answer", true)
			else:
				intro.call(&"advance")
		await process_frame
	if not _intro().call(&"is_text_complete"):
		_intro().call(&"advance")
	await _frames(30)


func _until(done: Callable, max_frames: int = 600) -> void:
	for i: int in max_frames:
		if done.call():
			return
		await process_frame
	push_warning("capture : condition jamais atteinte")


func _picture_scale() -> float:
	var stage: Node = _stage()
	if stage == null:
		return 0.0
	var holder: Node = stage.call(&"get_holder", &"player")
	return (holder.get_node(^"Picture") as Control).scale.x if holder != null else 0.0


func _fade_alpha() -> float:
	return float((_boot.call(&"get_fade") as Node).call(&"get_alpha"))


func _in_bedroom() -> bool:
	var map: Node = _boot.call(&"get_map")
	return map != null and map.get(&"map_id") == &"player_house_2f"


func _player_free() -> bool:
	return (_boot.call(&"get_player") as Node).call(&"is_input_enabled") \
		and bool((_boot.call(&"get_hud") as Node).get(&"visible"))


func _opening() -> Node:
	return _boot.call(&"get_opening")


func _intro() -> Node:
	return _opening().call(&"get_intro")


func _stage() -> Node:
	return _opening().call(&"get_intro_stage")


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
