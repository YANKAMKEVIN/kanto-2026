extends SceneTree
## Captures du J19 T12 : le VRAI combat SPECTRE (Boot, EncounterDirector, BattleDirector,
## BattleStage, BattleHud), puis une boîte de dialogue en voix d'esprit.
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 6000 \
##     -s res://tools/capture_ghost_t12.gd -- --out=build/captures/j19_t12
## Images (préfixe t12_) : apparition (« Un SPECTRE apparaît ! »), carte (SPECTRE Nv. ??),
## effraye (« trop peur pour bouger »), ball (refus de la Ball), voix (Exorciste possédée),
## voix_apres (la page suivante, voix normale).

const BOOT_SCENE: String = "res://game/boot.tscn"
const STARTER: StringName = &"charmander"

var _boot: Node
var _out_dir: String = "build/captures/j19_t12"
var _hud: CanvasLayer
var _director: Node
var _encounters: Node
var _banner: Node


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	_setup_state()
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_director = _boot.call(&"get_battle_director")
	_encounters = _boot.call(&"get_encounter_director")
	_banner = _hud.call(&"get_message_banner")
	(_boot.call(&"get_hud") as CanvasLayer).call(&"hide_interact")
	await _frames(20)
	await _battle()
	await _voice()
	print("CAPTURE_GHOST_T12 terminé")
	quit()


func _setup_state() -> void:
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", STARTER)
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(999)
	party.call(&"add", load("res://game/pokemon/pokemon_factory.gd").call(
		&"create", data, STARTER, 9, rng))
	state.set(&"party", party)
	state.get(&"bag").call(&"add", &"poke_ball", 12)


func _battle() -> void:
	var encounter: RefCounted = load("res://game/pokemon/encounters/wild_encounter.gd").new(
		&"gastly", 10)
	encounter.set(&"ghost", true)
	if not _encounters.call(&"start_encounter", encounter):
		push_error("rencontre refusée")
		return
	await _text_shown("Un SPECTRE")
	await _shot("apparition")
	await _text_shown("identifier")
	await _shot("identification")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	await _frames(15)
	await _shot("carte")
	_hud.emit_signal(&"action_selected", &"attack")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 2, 300)
	_hud.emit_signal(&"move_selected", 0)
	await _text_shown("peur")
	await _shot("effraye")
	await _text_shown("Va-t'en")
	await _shot("parole")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	_hud.emit_signal(&"action_selected", &"bag")
	var got: Array = [null]
	await _until(func() -> bool:
		got[0] = _director.call(&"get_bag_panel")
		return got[0] != null and got[0].visible and not got[0].call(&"is_sliding"), 300)
	await _frames(10)
	got[0].call(&"select_item", &"poke_ball")
	await _frames(6)
	(got[0].call(&"get_action_button") as Button).emit_signal(&"pressed")
	await _text_shown("Pas question")
	await _shot("ball")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	while _director.call(&"is_running"):
		if int(_hud.call(&"get_zone")) == 1:
			_hud.emit_signal(&"action_selected", &"run")
		await _frames(2)
	await _frames(40)


func _voice() -> void:
	var box: CanvasLayer = _boot.call(&"get_dialogue_box")
	box.call(&"open")
	await _frames(15)
	box.call(&"show_page", "Exorciste", "Tu… n'as… rien… à faire… ici…", false, &"spirit")
	box.call(&"set_visible_characters", -1)
	box.call(&"set_continue_visible", true)
	await _frames(10)
	await _shot("voix")
	box.call(&"show_page", "Exorciste", "Qu'est-ce que… J'étais possédée ?", false)
	box.call(&"set_visible_characters", -1)
	await _frames(10)
	await _shot("voix_apres")


func _text_shown(part: String) -> void:
	await _until(func() -> bool: return String(_banner.call(&"get_text")).contains(part), 900)
	await _frames(14)


func _until(done: Callable, frames: int) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await process_frame
	push_warning("attente dépassée")
	return false


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(name: String) -> void:
	paused = true
	for i: int in 6:
		await process_frame
	var path := _out_dir.path_join("t12_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
