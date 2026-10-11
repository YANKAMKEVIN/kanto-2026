extends SceneTree
## Captures de l'introduction du Prof. Chen (OUV.2) sur le vrai Boot lancé en scène courante,
## sauvegarde et réglages en mémoire (le vrai `user://` n'est jamais lu ni écrit) :
##   01_chen               Chen seul, au centre (première réplique)
##   02_chen_nidorino      Chen à gauche, Nidorino sorti de sa Poké Ball à droite
##   02b_pokeball          l'éclair de la Poké Ball (vitesse réelle)
##   03_player             le joueur au centre (« Mais parlons un peu de toi. »)
##   04_name_entry         écran de prénom, champ vide
##   04b_name_typed        « Sacha » tapé (pastille mise en avant, VALIDER actif)
##   04c_name_help         caractère refusé : aide sous le champ
##   05_confirm            « Sacha ! C'est bien ça ? » Oui / Non
##   06_rival_chen         le rival au centre, Chen à gauche (« Et lui… »)
##   07_rival_name         prénom du rival (pastille « Gary » touchée)
##   08_last_line          le joueur seul au centre (« Allez… en route ! »)
##   09_bedroom            la chambre (fondu simple ; OUV.3 fera le blanc chaud)
##   10_prologue_rival     une réplique du prologue : l'étiquette est le prénom du rival
##   11_battle_rival       message de combat contre le rival (« Gary veut se battre ! »)
##   12_reduced_motion     Chen + Nidorino avec « Réduire les animations » (pas de montée)
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_intro_ouv2.gd \
##     -- --out=build/captures/ouv2

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const SAVE: String = "res://game/systems/save/save_system.gd"
const FIXTURE_V4: String = "res://tests/fixtures/save/v4_kevin_s21.json"
const SAVE_PATH: String = "user://cap_ouv2_save.json"
const ABSENT: String = "user://cap_ouv2_absent.json"

var _out_dir: String = "build/captures/ouv2"
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
	await _launch(fixture, 0.0)
	await _new_game()
	await _to_step(1)
	await _shot("01_chen")
	await _to_step(5)
	await _shot("02_chen_nidorino")
	await _to_step(11)
	await _shot("03_player")
	await _to_step(13)
	await _shot("04_name_entry")
	var entry: Node = _stage().call(&"get_name_entry")
	entry.call(&"type_text", "Sacha")
	await _frames(5)
	await _shot("04b_name_typed")
	entry.call(&"type_text", "Sacha7")
	await _frames(5)
	await _shot("04c_name_help")
	entry.call(&"type_text", "Sacha")
	(entry.call(&"get_validate_button") as Button).pressed.emit()
	await _frames(5)
	await _reveal()
	await _frames(30)
	await _shot("05_confirm")
	_intro().call(&"answer", true)
	await _to_step(18)
	await _shot("06_rival_chen")
	await _to_step(23)
	var chips: Array = entry.call(&"get_chips")
	(chips[2] as Button).pressed.emit()
	await _frames(5)
	await _shot("07_rival_name")
	(entry.call(&"get_validate_button") as Button).pressed.emit()
	await _frames(5)
	_intro().call(&"answer", true)
	await _to_step(31)
	await _shot("08_last_line")
	_intro().call(&"advance")
	await _frames(90)
	await _shot("09_bedroom")
	var runner: Node = _boot.call(&"get_dialogue_runner")
	print("réplique du rival jouée : %s" % runner.call(&"play", &"rival_starter_pick"))
	await _frames(90)
	await _shot("10_prologue_rival")
	runner.call(&"_advance")
	await _frames(40)
	await _battle_shot()
	_kill()
	await _launch(fixture, 1.0, true)
	await _new_game()
	await _to_step(2)
	_intro().call(&"advance")
	await _frames(8)
	await _shot("02b_pokeball")
	await _to_step(5)
	await _frames(30)
	await _shot("12_reduced_motion")
	_kill()
	print("CAPTURE_OUV2 terminé : %s" % _out_dir)
	quit()


## Combat contre le rival (Route 22 : « … veut se battre ! ») avec un Salamèche dans l'équipe.
func _battle_shot() -> void:
	var state: Node = root.get_node(^"GameState")
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	state.set(&"starter_species", &"charmander")
	var party: RefCounted = state.get(&"party")
	party.call(&"add", factory.call(&"create", data, &"charmander", 9, state.get(&"rng")))
	var director: Node = _boot.call(&"get_battle_director")
	director.call(&"run", &"rival_route22", _boot.call(&"get_map"),
		{} as Dictionary[StringName, StringName])
	for i: int in 400:
		await process_frame
		var hud: Node = _boot.call(&"get_battle_hud")
		var text: String = str(hud.call(&"get_message_banner").call(&"get_text"))
		if text.contains("veut se battre"):
			await _frames(20)
			break
	await _shot("11_battle_rival")


## Boot comme lancé par le moteur (scène courante), sur une sauvegarde en mémoire.
func _launch(save: String, speed: float, reduce_motion: bool = false) -> void:
	_fs = (load(MEMORY_FS) as GDScript).new()
	if not save.is_empty():
		(_fs.get(&"files") as Dictionary)[SAVE_PATH] = save
	var store: RefCounted = (load(STORE) as GDScript).new(_fs, "user://cap_ouv2.json")
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
	_boot.set(&"opening_speed_scale", speed)
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
	for i: int in 200:
		await process_frame
		if _intro() != null:
			break
	await _frames(10)


## Avance l'introduction jusqu'à l'étape [param index] (scène posée, texte entier).
func _to_step(index: int) -> void:
	for i: int in 2000:
		var intro: Node = _intro()
		var reader: RefCounted = intro.call(&"get_reader")
		if int(reader.call(&"index")) >= index and not intro.call(&"is_staging"):
			break
		if not intro.call(&"is_staging"):
			if intro.call(&"is_waiting_for_choice"):
				intro.call(&"answer", true)
			elif not intro.call(&"is_waiting_for_name"):
				intro.call(&"advance")
		await process_frame
	await _reveal()
	await _frames(30)


func _reveal() -> void:
	var intro: Node = _intro()
	if not intro.call(&"is_text_complete"):
		intro.call(&"advance")
	await _frames(2)


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
