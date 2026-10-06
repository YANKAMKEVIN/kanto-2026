extends SceneTree
## Vérification visuelle du bug « carte de PV du joueur absente après une Potion » (jalon 7,
## branche j7-carte-pv) avec la vraie scène Boot, le combat du rival n° 2 (Route 22) et le Sac :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_potion_card.gd -- --out=build/captures/jalon07_carte_pv
##
## Images : potion_1_before (grille, PV bas), potion_2_bag (Sac ouvert), potion_3_after (grille
## du tour suivant : la carte du joueur est là, PV soignés).

var _out_dir: String = "build/captures/jalon07_carte_pv"
var _boot: Node
var _player: Node2D
var _battle: Node
var _hud: Node
var _router: Node
var _director: Node
var _step: int = 0
var _wait: int = 0
var _stage: int = 0
var _hp_before: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_city")
	_boot.set(&"start_spawn", &"from_route_22")
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	start.call(&"load_file", "res://tools/debug_start/route_22.json", data,
		_boot.call(&"get_item_library"))
	var state := root.get_node(^"/root/GameState")
	start.call(&"apply", state, data)
	state.set(&"rng", load("res://game/systems/random/game_rng.gd").new(7))
	state.get(&"party").call(&"get_lead").set(&"hp", 4)
	_player = _boot.call(&"get_player")
	_director = _boot.call(&"get_cutscene_director")
	_battle = _boot.call(&"get_battle_director")
	_hud = _boot.call(&"get_battle_hud")
	_router = root.get_node(^"/root/SceneRouter")
	_router.call(&"change_map", &"route_22", &"stair_foot", Vector2i.UP)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_wait += 1
	match _step:
		0:
			if _wait > 40 and not _router.call(&"is_transitioning"):
				Input.action_press(&"move_up")
				_step = 1
		1:
			if _player.call(&"get_cell") == Vector2i(16, 13):
				Input.action_release(&"move_up")
				Input.action_press(&"move_left")
				_step = 2
		2:
			if _director.call(&"is_running"):
				Input.action_release(&"move_left")
				_step = 3
		3:
			_drive()


func _drive() -> void:
	var box: Node = _boot.call(&"get_dialogue_box")
	if box.call(&"is_open") and _wait % 20 == 0:
		box.emit_signal(&"advance_requested")
	if not _battle.call(&"is_running"):
		return
	var battle: Object = _battle.call(&"get_battle")
	var panel: Object = _battle.call(&"get_bag_panel")
	var picker: Object = _battle.call(&"get_party_picker")
	if picker != null and picker.call(&"is_shown") and _stage == 2:
		_stage = 3
		picker.emit_signal(&"target_chosen", 0)
	elif panel != null and panel.call(&"is_shown") and not panel.call(&"is_answered"):
		if _stage == 1:
			_stage = 2
			_wait = 0
			panel.call(&"open_category", &"heal")
			panel.call(&"select_item", &"potion")
		elif _stage == 2 and _wait == 25:
			_shot("potion_2_bag")
			panel.call(&"get_action_button").emit_signal(&"pressed")
	elif battle != null and battle.call(&"get_state") == 1 \
			and int(_hud.call(&"get_zone")) == 1:
		if _stage == 0:
			if _wait > 60:
				_shot("potion_1_before")
				_stage = 1
				_hud.emit_signal(&"action_selected", &"bag")
		elif _stage == 3:
			if _wait > 120:
				_shot("potion_3_after")
				quit()
	if _stage == 3 and _wait % 1 == 0 and _wait > 400:
		quit(1)


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
