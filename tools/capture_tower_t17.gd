extends SceneTree
## Captures du J19 T17 : rez-de-chaussée de la Tour Pokémon, gardienne, escalier, 2F, sur le vrai
## Boot, les vraies cartes, les vraies scènes :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_tower_t17.gd -- --out=build/captures/j19_t17
## Images : 1f_entree, 1f_scene (page 2), 1f_gardienne (rangée en (18, 3)), 2f_arrivee,
## 1f_retour (joueur en (17, 3)), 1f_apres (dialogue §15.1.5).

const BOOT_SCENE: String = "res://game/boot.tscn"

var _boot: Node
var _out_dir: String = "build/captures/j19_t17"
var _box: Node
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
	_boot.set(&"start_map", &"pokemon_tower_2f")
	_boot.set(&"start_spawn", &"arrivee_T12")
	_boot.set(&"start_facing", Vector2i.LEFT)
	root.add_child(_boot)
	await _frames(20)
	_box = _boot.call(&"get_dialogue_box")
	_player = _boot.call(&"get_player")
	_cutscenes = _boot.call(&"get_cutscene_director")
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	for flag: StringName in [&"starter_chosen", &"lavender_reached", &"tower_stairs_open"]:
		state.get(&"flags").call(&"set_flag", flag)
	await _frames(20)
	await _shot("2f_arrivee")
	await _hold(&"move_up", func() -> bool: return _player.call(&"get_cell").y <= 7)
	await _hold(&"move_left", func() -> bool: return _player.call(&"get_cell").x <= 14)
	Input.action_press(&"move_up")
	await _until(func() -> bool: return _cutscenes.call(&"is_running"), 300)
	Input.action_release(&"move_up")
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("…"), 600)
	await _frames(30)
	await _shot("rival_intro_1")
	_box.emit_signal(&"advance_requested")
	await _frames(40)
	await _shot("rival_intro_2")
	_boot.call(&"get_map").call(&"spawn_player_at", _player, Vector2i(4, 7), Vector2i.RIGHT)
	await _frames(10)
	print("CAPTURE_TOWER_T17 terminé")
	quit()


func _hold(action: StringName, done: Callable) -> void:
	Input.action_press(action)
	await _until(done, 900)
	Input.action_release(action)
	await _frames(8)


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
	var path := _out_dir.path_join("t17_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
