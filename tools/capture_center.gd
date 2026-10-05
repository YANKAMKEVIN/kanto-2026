extends SceneTree
## Captures du Centre Pokémon de Jadielle (jalon 7 T8) avec la vraie scène Boot, la partie du
## départ `tools/debug_start/center_qa.json` (équipe blessée, un K.O.) appliquée au démarrage :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_center.gd -- --out=build/captures/jalon07_t8
##
## Déroulé : center_00_entry (arrivée sur le paillasson) ; trois pas vers le comptoir ;
## center_01_counter (devant l'infirmière) ; parler ; center_02_question ; center_03_choice
## (SOIGNER / PAS MAINTENANT) ; SOIGNER touché ; center_04_ritual (alvéoles allumées),
## center_05_flash (éclat) ; center_06_done (« Voilà… ») ; center_07_toast (« Point de repos
## enregistré — Jadielle »). La durée du rituel est écrite dans le journal.

const START := "res://tools/debug_start/center_qa.json"

var _out_dir: String = "build/captures/jalon07_t8"
var _boot: Node
var _player: Node2D
var _runner: Node
var _box: Node
var _machine: Node2D
var _frame: int = 0
var _step: int = 0
var _wait: int = 0
var _chosen_ms: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_center")
	_boot.set(&"start_spawn", &"entrance")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_center : départ illisible")
	start.call(&"apply", root.get_node(^"/root/GameState"), data)
	_player = _boot.call(&"get_player")
	_runner = _boot.call(&"get_dialogue_runner")
	_box = _boot.call(&"get_dialogue_box")
	_machine = (_boot.call(&"get_map") as Node).get_node(^"%HealMachine")
	_runner.choice_requested.connect(func(_view: Object) -> void: _wait = 0)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	_wait += 1
	match _step:
		0:
			if _frame == 45:
				_shot("center_00_entry")
				Input.action_press(&"move_up")
				_next()
		1:
			if _player.call(&"get_cell") == Vector2i(7, 5):
				Input.action_release(&"move_up")
				_next()
		2:
			if _wait == 30:
				_shot("center_01_counter")
				Input.action_press(&"interact")
			elif _wait == 32:
				Input.action_release(&"interact")
				_next()
		3:
			if _box.call(&"is_open") and _wait == 25:
				_shot("center_02_question")
				_box.emit_signal(&"advance_requested")
				_next()
		4:
			if _box.call(&"is_choice_showing") and _wait == 20:
				_shot("center_03_choice")
				var cards: Object = _box.call(&"get_choice_cards")
				_chosen_ms = Time.get_ticks_msec()
				(cards.call(&"get_confirm_button") as Button).pressed.emit()
				_next()
		5:
			# 3 s à 30 i/s = 90 images : alvéoles toutes allumées vers 1,9 s, éclat à 2,3 s.
			if _wait == 62:
				_shot("center_04_ritual")
			elif _wait == 70:
				_shot("center_05_flash")
			elif _wait > 70 and not _machine.call(&"is_playing"):
				print("Rituel : %.2f s" % ((Time.get_ticks_msec() - _chosen_ms) / 1000.0))
				_next()
		6:
			if _wait == 40:
				_shot("center_06_done")
			elif _wait > 40 and _wait % 5 == 0:
				_box.emit_signal(&"advance_requested")
				if not _runner.call(&"is_running"):
					_next()
		7:
			if _wait == 20:
				_shot("center_07_toast")
			elif _wait == 30:
				quit()


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
