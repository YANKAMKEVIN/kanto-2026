extends SceneTree
## Captures du J19 T14 : le SPECTRE qui barre le 6F (déclencheur, recul) et un combat d'Exorciste,
## sur le vrai Boot, les vraies cartes, les vraies scènes :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_tower_t14.gd -- --out=build/captures/j19_t14
## Images : 6f_avant, 6f_declencheur (« …Va-t'en… Intrus… »), 6f_combat, 6f_recul (joueur en
## (10, 15), « Quelque chose refuse qu'on passe. »), exorciste_vue (réplique possédée, voix
## d'esprit), exorciste_combat (écran de combat contre Hortense), exorciste_apres.

const BOOT_SCENE: String = "res://game/boot.tscn"

var _boot: Node
var _out_dir: String = "build/captures/j19_t14"
var _hud: CanvasLayer
var _director: Node
var _box: CanvasLayer
var _player: Node
var _cutscenes: Node


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"pokemon_tower_6f")
	_boot.set(&"start_spawn", &"devant_spectre")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(20)
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_director = _boot.call(&"get_battle_director")
	_box = _boot.call(&"get_dialogue_box")
	_player = _boot.call(&"get_player")
	_cutscenes = _boot.call(&"get_cutscene_director")
	_setup_state()
	await _frames(20)
	await _ghost()
	await _channeler()
	print("CAPTURE_TOWER_T14 terminé")
	quit()


func _setup_state() -> void:
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", &"charmeleon")
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(999)
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var lead: RefCounted = factory.call(&"create", data, &"kadabra", 70, rng)
	var moves: Array = lead.get(&"moves")
	moves.clear()
	moves.append(load("res://game/pokemon/move_slot.gd").new(&"psychic", 10))
	party.call(&"add", lead)
	state.set(&"party", party)
	state.get(&"bag").call(&"add", &"poke_ball", 10)


func _ghost() -> void:
	await _shot("6f_avant")
	Input.action_press(&"move_down")
	await _until(func() -> bool: return _cutscenes.call(&"is_running"), 300)
	Input.action_release(&"move_down")
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("Intrus"), 600)
	await _frames(20)
	await _shot("6f_declencheur")
	_box.emit_signal(&"advance_requested")
	await _until(func() -> bool: return _director.call(&"is_running"), 600)
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	await _frames(15)
	await _shot("6f_combat")
	while _director.call(&"is_running"):
		if int(_hud.call(&"get_zone")) == 1:
			_hud.emit_signal(&"action_selected", &"run")
		await _frames(2)
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("refuse"), 900)
	await _frames(20)
	await _shot("6f_recul")
	await _close_box()
	await _until(func() -> bool: return not _cutscenes.call(&"is_running"), 300)
	await _frames(20)


func _channeler() -> void:
	var router: Node = root.get_node(^"SceneRouter")
	router.call(&"change_map", &"pokemon_tower_3f", &"arrivee_T23", Vector2i.RIGHT)
	await _until(func() -> bool: return (_boot.call(&"get_map").map_id == &"pokemon_tower_3f"
		and not bool(router.call(&"is_transitioning"))), 600)
	await _frames(30)
	var map: GameMap = _boot.call(&"get_map")
	map.spawn_player_at(_player, Vector2i(9, 3), Vector2i.RIGHT)
	await _frames(40)
	Input.action_press(&"move_right")
	var started: bool = await _until(func() -> bool: return _cutscenes.call(&"is_running"), 300)
	Input.action_release(&"move_right")
	print("[info] scène lancée : ", started, " case ", _player.call(&"get_cell"))
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("Laisse"), 900)
	await _frames(25)
	await _shot("exorciste_vue")
	_box.emit_signal(&"advance_requested")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 1200)
	await _frames(15)
	await _shot("exorciste_combat")
	while _director.call(&"is_running"):
		var zone := int(_hud.call(&"get_zone"))
		if zone == 1:
			_hud.emit_signal(&"action_selected", &"attack")
		elif zone == 2:
			_hud.emit_signal(&"move_selected", 0)
		if bool(_box.call(&"is_open")):
			_box.emit_signal(&"advance_requested")
		await _frames(2)
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("esprits"), 900)
	await _frames(20)
	await _shot("exorciste_apres")


func _close_box() -> void:
	for i: int in 120:
		if not bool(_box.call(&"is_open")):
			return
		_box.emit_signal(&"advance_requested")
		await _frames(3)


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
	var path := _out_dir.path_join("t14_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
