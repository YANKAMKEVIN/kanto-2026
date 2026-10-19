extends SceneTree
## Captures du J19 T18 : zone purifiée du 5F, Exorciste calme, objet caché et objet visible.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_tower_t18.gd -- --out=build/captures/j19_t18
## Images : zone_avant (devant la dalle), zone_soin (page 1), zone_fin (page 2), exorciste
## (calme, à l'est de la dalle), cache (devant l'offrande, bouton EXAMINER), objet (Pépite).

const BOOT_SCENE: String = "res://game/boot.tscn"

var _boot: Node
var _out_dir: String = "build/captures/j19_t18"
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
	_boot.set(&"start_map", &"pokemon_tower_5f")
	_boot.set(&"start_spawn", &"arrivee_T45")
	_boot.set(&"start_facing", Vector2i.RIGHT)
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
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, Vector2i(9, 9), Vector2i.RIGHT)
	await _frames(30)
	await _shot("zone_avant")
	_player.call(&"script_step", Vector2i.RIGHT)
	await _until(func() -> bool: return _cutscenes.call(&"is_running"), 120)
	await _until(func() -> bool: return _box.call(&"is_open"), 300)
	await _frames(30)
	await _shot("zone_soin")
	_box.emit_signal(&"advance_requested")
	await _frames(40)
	await _shot("zone_fin")
	for i: int in 300:
		if not _cutscenes.call(&"is_running"):
			break
		if _box.call(&"is_open"):
			_box.emit_signal(&"advance_requested")
		await _frames(6)
	await _frames(20)
	map.call(&"spawn_player_at", _player, Vector2i(12, 9), Vector2i.UP)
	await _frames(30)
	await _shot("exorciste")
	map.call(&"spawn_player_at", _player, Vector2i(4, 10), Vector2i.DOWN)
	await _frames(40)
	await _shot("cache")
	map.call(&"spawn_player_at", _player, Vector2i(6, 13), Vector2i.DOWN)
	await _frames(40)
	await _shot("objet")
	print("CAPTURE_TOWER_T18 terminé")
	quit()


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


func _shot(shot_name: String) -> void:
	paused = true
	for i: int in 6:
		await process_frame
	var path := _out_dir.path_join("t18_%s.png" % shot_name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
