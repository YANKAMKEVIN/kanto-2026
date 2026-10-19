extends SceneTree
## Captures du J19 T16 : rez-de-chaussée de la Tour Pokémon, gardienne, escalier, 2F, sur le vrai
## Boot, les vraies cartes, les vraies scènes :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_tower_t16.gd -- --out=build/captures/j19_t16
## Images : 1f_entree, 1f_scene (page 2), 1f_gardienne (rangée en (18, 3)), 2f_arrivee,
## 1f_retour (joueur en (17, 3)), 1f_apres (dialogue §15.1.5).

const BOOT_SCENE: String = "res://game/boot.tscn"

var _boot: Node
var _out_dir: String = "build/captures/j19_t16"
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
	_boot.set(&"start_map", &"pokemon_tower_1f")
	_boot.set(&"start_spawn", &"entrance")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	_box = _boot.call(&"get_dialogue_box")
	_player = _boot.call(&"get_player")
	_cutscenes = _boot.call(&"get_cutscene_director")
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.get(&"flags").call(&"set_flag", &"lavender_reached")
	await _frames(20)
	await _shot("1f_entree")
	Input.action_press(&"move_up")
	await _until(func() -> bool: return _cutscenes.call(&"is_running"), 300)
	Input.action_release(&"move_up")
	await _until(func() -> bool: return String(_box.call(&"get_text")).contains("Pardonnez"), 600)
	await _frames(20)
	await _shot("1f_scene")
	for i: int in 900:
		if not _cutscenes.call(&"is_running"):
			break
		if _box.call(&"is_open"):
			_box.emit_signal(&"advance_requested")
		await _frames(6)
	await _frames(30)
	await _shot("1f_gardienne")
	# Marche jusqu'à (17, 4) puis l'escalier.
	_boot.call(&"get_map").call(&"spawn_player_at", _player, Vector2i(17, 3), Vector2i.UP)
	await _frames(20)
	await _hold(&"move_up", func() -> bool:
		return _boot.call(&"get_map").get(&"map_id") == &"pokemon_tower_2f")
	await _frames(60)
	await _shot("2f_arrivee")
	await _hold(&"move_right", func() -> bool:
		return _boot.call(&"get_map").get(&"map_id") == &"pokemon_tower_1f")
	await _frames(60)
	await _shot("1f_retour")
	_player.call(&"script_step", Vector2i.DOWN)
	await _frames(20)
	_player.call(&"script_step", Vector2i.RIGHT)
	await _frames(20)
	print("CAPTURE_TOWER_T16 terminé")
	quit()


## Marche (clavier simulé) jusqu'à [param cell] : par l'allée centrale jusqu'à la rangée 4 (le
## visiteur tient (17, 5)), puis vers l'est.
func _walk_to(cell: Vector2i) -> void:
	var here: Vector2i = _player.call(&"get_cell")
	var horizontal: StringName = &"move_right" if cell.x > here.x else &"move_left"
	await _hold(horizontal, func() -> bool: return _player.call(&"get_cell").x == cell.x)
	await _hold(&"move_up", func() -> bool: return _player.call(&"get_cell").y <= cell.y)
	await _frames(10)


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
	var path := _out_dir.path_join("t16_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
