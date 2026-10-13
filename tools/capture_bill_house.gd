extends SceneTree
## Captures de la scène de Léo (jalon 14 T17), vrai Boot, vrais PNJ et scènes :
##   godot --path . --resolution 2340x1080 -s res://tools/capture_bill_house.gd
## Écrit dans build/captures/jalon14_t17/ : 01_melofee (accueil), 02_lueur (lueur sur l'écran),
## 03_flash (éclair), 04_leo_passe_bateau (remise du Passe Bateau), 05_leo_humain.

const OUT := "res://build/captures/jalon14_t17/"
var _boot: Node
var _player: Node


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _shot(name: String) -> void:
	await _wait(6)
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("CAPTURE ", name)


func _hold(action: StringName, until: Callable, limit: int = 600) -> void:
	Input.action_press(action)
	var n := 0
	while not until.call() and n < limit:
		await process_frame
		n += 1
	Input.action_release(action)
	await _wait(10)


func _left_of_9() -> bool:
	return _player.get_cell().x <= 8


func _scene_running() -> bool:
	return _boot.get_dialogue_runner().is_running() or _boot.get_cutscene_director().is_running()


func _advance_all() -> void:
	var director: Node = _boot.get_cutscene_director()
	var box: Node = _boot.get_dialogue_box()
	var n := 0
	while (director.is_running() or _boot.get_dialogue_runner().is_running()) and n < 3000:
		await process_frame
		n += 1
		if box.is_open():
			box.advance_requested.emit()


func _boot_up(flags: Array) -> void:
	if _boot != null:
		_boot.queue_free()
		await _wait(5)
	var scene: PackedScene = load("res://game/boot.tscn")
	_boot = scene.instantiate()
	_boot.start_map = &"bill_house"
	_boot.start_spawn = &"from_route_25"
	_boot.start_facing = Vector2i.UP
	_boot.save_system = SaveSystem.new(load("res://tests/helpers/memory_file_system.gd").new(),
		"user://cap_bill.json")
	root.add_child(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	start.load_file("res://tools/debug_start/bill_house.json", _boot.get_pokemon_data(),
		_boot.get_item_library())
	start.apply(_gs(), _boot.get_pokemon_data())
	for flag: String in flags:
		_gs().flags.set_flag(StringName(flag))
	await _wait(10)
	_boot.get_map().refresh_npcs(_gs().flags)


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(2340, 1080))
	await _boot_up([])
	var box: Node = _boot.get_dialogue_box()
	await _hold(&"move_up", _scene_running)
	var w := 0
	while not box.is_open() and w < 600:
		await process_frame
		w += 1
	await _wait(10)
	await _shot("01_melofee")
	await _advance_all()
	# Lueur sur l'écran (après la rencontre).
	_gs().flags.set_flag(&"bill_met")
	await _wait(10)
	await _shot("02_lueur")
	# Machine : Léo dans la cabine, console.
	await _boot_up(["bill_met", "bill_screen_checked", "bill_module_checked", "bill_in_cabin"])
	await _hold(&"move_up", func() -> bool: return _player.get_cell().y <= 9)
	await _advance_all()
	var map: Node = _boot.get_map()
	_player.enter_map(map.get_grid(), Vector2i(8, 4), Vector2i.UP, map.get_pixel_rect())
	await _wait(10)
	_player.face(Vector2i.UP)
	await _shot("02b_lueur_console")
	var director: Node = _boot.get_cutscene_director()
	box = _boot.get_dialogue_box()
	director.flash_started.connect(func(_c: int) -> void: _flash_pending = true)
	print("AT ", _player.get_cell(), _player.get_facing())
	Input.action_press(&"interact")
	await _wait(3)
	Input.action_release(&"interact")
	var n := 0
	var shot_flash := false
	var shot_ticket := false
	var shot_leo := false
	while (director.is_running() or _boot.get_dialogue_runner().is_running()) and n < 4000:
		await process_frame
		n += 1
		if _flash_pending and not shot_flash:
			shot_flash = true
			await _wait(12)
			await _shot("03_flash")
		if box.is_open():
			var text: String = box.get_text()
			if text.contains("Prends-le") and not shot_ticket:
				shot_ticket = true
				await _shot("05_leo_humain")
			if text.contains("PASSE BATEAU") and not shot_leo:
				shot_leo = true
				await _shot("04_leo_passe_bateau")
			box.advance_requested.emit()
	print("DONE")
	quit()


var _flash_pending := false


func _gs() -> Node:
	return root.get_node(^"GameState")
