extends SceneTree
## Captures du départ du S.S. Anne et de l'arbuste de l'Arène (jalon 16 T15) avec le vrai Boot,
## une sauvegarde **en mémoire** (le vrai `user://save.json` n'est jamais touché) et un départ de
## débogage ; entrées injectées (`move_*`, `interact`), pages tournées, choix répondus.
##
##   godot --path . -s res://tools/capture_ss_anne_departure.gd -- --scenario=departure \
##     [--out=build/captures/j16_t15]
##
## Scénarios :
##   departure  `ss_anne_exit` : pas vers la passerelle, DEP-01 (capture du choix), PARTIR,
##              quai (légende DEP-02), navire en route, quai après le départ.
##   cut        `cut_ready` : arbuste avant, COUPER, arbuste coupé (porte de l'Arène libre).
## Images : `<out>/<scénario>_NN_<moment>.png` (image affichée, lue après le dessin).
## 2340 × 1080 : `override.cfg` temporaire à la racine, à retirer après.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")

var _args: Dictionary = {}
var _boot: Node
var _out: String = "res://build/captures/j16_t15"
var _shots: int = 0
var _confirm: bool = true


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	_out = String(_args.get("out", _out))
	if not _out.begins_with("res://") and not _out.begins_with("/"):
		_out = "res://" + _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var scenario := String(_args.get("scenario", "departure"))
	var start_name := "ss_anne_exit" if scenario == "departure" else "cut_ready"
	var start: RefCounted = (load("res://game/systems/debug/debug_start.gd") as Script).new()
	var data: RefCounted = (load("res://game/pokemon/pokemon_data.gd") as Script).new()
	data.call(&"load_dir")
	var items: RefCounted = (load("res://game/items/item_library.gd") as Script).new()
	items.call(&"load_dir")
	if not start.call(&"load_file", "res://tools/debug_start/%s.json" % start_name, data, items):
		push_error("capture : départ %s refusé" % start_name)
		quit(1)
		return
	var save_script: Script = load("res://game/systems/save/save_system.gd")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"save_system", save_script.new(MemoryFs.new(), "user://capture_j16_t15.json"))
	_boot.set(&"start_map", start.get(&"map"))
	_boot.set(&"start_spawn", start.get(&"spawn"))
	_boot.set(&"start_facing", start.get(&"facing"))
	root.add_child(_boot)
	await _frames(10)
	var state: Node = root.get_node(^"GameState")
	start.call(&"apply", state, _boot.call(&"get_pokemon_data"))
	var map: Node = _boot.call(&"get_map")
	map.call(&"refresh_npcs", state.get(&"flags"))
	_boot.call(&"get_dialogue_runner").set(&"chars_per_second", 0.0)
	await _frames(20)
	if scenario == "departure":
		await _departure()
	else:
		await _cut()
	print("capture_ss_anne_departure : %d images dans %s" % [_shots, _out])
	quit(0)


func _departure() -> void:
	await _shot("deck_before")
	Input.action_press(&"move_down")
	await _until(func() -> bool: return _box().call(&"is_open"), 300)
	Input.action_release(&"move_down")
	await _frames(20)
	await _shot("dep01")
	await _play_until(func() -> bool: return _box().call(&"is_choice_showing"), 600)
	await _frames(15)
	await _shot("choice")
	_confirm = true
	var director: Node = _boot.call(&"get_cutscene_director")
	var caption: Node = _boot.call(&"get_hud").call(&"get_caption")
	await _play_until(func() -> bool: return caption.call(&"is_showing"), 1200)
	await _frames(30)
	await _shot("caption")
	await _until(func() -> bool:
		return String(director.call(&"get_cutscene_id")) == "ss_anne_departure" \
			and not caption.call(&"is_showing"), 1200)
	await _frames(100)
	await _shot("ship_leaving")
	await _until(func() -> bool: return not director.call(&"is_running"), 1200)
	await _frames(30)
	await _shot("dock_after")


func _cut() -> void:
	await _shot("tree_before")
	_confirm = true
	for attempt: int in 20:
		Input.action_press(&"interact")
		await _frames(3)
		Input.action_release(&"interact")
		await _frames(3)
		if _box().call(&"is_open"):
			break
	await _play_until(func() -> bool: return _box().call(&"is_choice_showing"), 600)
	await _frames(15)
	await _shot("choice")
	var director: Node = _boot.call(&"get_cutscene_director")
	await _play_until(func() -> bool:
		return not director.call(&"is_running") and not _box().call(&"is_open"), 600)
	await _frames(30)
	await _shot("tree_after")


func _box() -> Node:
	return _boot.call(&"get_dialogue_box")


## Tourne les pages et répond aux choix jusqu'à [param done] (au plus [param limit] images).
func _play_until(done: Callable, limit: int) -> void:
	for i: int in limit:
		if done.call():
			return
		var box := _box()
		if box.call(&"is_choice_showing") and not done.call():
			var cards: Node = box.call(&"get_choice_cards")
			var button: Node = cards.call(&"get_confirm_button") if _confirm \
				else cards.call(&"get_cancel_button")
			button.emit_signal(&"pressed")
		elif box.call(&"is_open") and not _boot.call(&"get_dialogue_runner").call(
				&"is_awaiting_choice"):
			box.emit_signal(&"advance_requested")
		await process_frame
	push_warning("capture : délai dépassé")


func _until(done: Callable, limit: int) -> void:
	for i: int in limit:
		if done.call():
			return
		await process_frame
	push_warning("capture : délai dépassé")


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%02d_%s.png" % [_out, String(_args.get("scenario", "departure")),
		_shots, label]
	_shots += 1
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE %s" % path)
