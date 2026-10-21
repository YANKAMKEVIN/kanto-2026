extends SceneTree
## Relecture d'interface de la Grotte Sombre (jalon 18 T21) : le vrai `Boot` avec un départ
## `dark_cave_*`, piloté par un petit scénario (`--seq=`), captures 2340 × 1080 enregistrées par
## `Viewport.get_texture()` (fenêtre réelle, pas `--headless`).
##
##   godot --path . --fixed-fps 60 -s res://tools/capture_dark_cave_ui.gd -- \
##     --start=dark_cave_1f_flash --out=build/captures/j18_t21/x --seq="wait:120;shot:a"
##
## Jetons de `--seq` (séparés par « ; ») : `wait:N` (images), `shot:nom`, `press:action`
## (3 images), `hold:action` / `release:action`, `tp:x,y,dir` (pose le joueur), `tap:x,y` (clic en pixels), `touch:x,y,x2,y2` / `untouch` (doigt gauche posé puis glissé), `flag:nom`,
## `mash:N` (N « interagir » espacés de 25 images), `quit`.

var _args: Dictionary = {}
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % String(_args["start"]))
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	for i in 3:
		await process_frame
	for token: String in String(_args["seq"]).split(";", false):
		var parts := token.split(":", true, 1)
		var arg := parts[1] if parts.size() > 1 else ""
		match parts[0]:
			"wait":
				for i in int(arg):
					await process_frame
			"shot":
				await _shot(arg)
			"press":
				_event(arg, true)
				for i in 3:
					await process_frame
				_event(arg, false)
			"hold":
				_event(arg, true)
			"release":
				_event(arg, false)
			"mash":
				for k in int(arg):
					_event("interact", true)
					for i in 3:
						await process_frame
					_event("interact", false)
					for i in 22:
						await process_frame
			"tp":
				var p := arg.split(",")
				var cell := Vector2i(int(p[0]), int(p[1]))
				_boot.call(&"get_map").call(&"spawn_player_at", _boot.call(&"get_player"),
					cell, _dir(p[2]))
			"tap":
				var q := arg.split(",")
				await _tap(Vector2(float(q[0]), float(q[1])))
			"touch":
				var t := arg.split(",")
				var down := InputEventScreenTouch.new()
				down.index = 0
				down.position = Vector2(float(t[0]), float(t[1]))
				down.pressed = true
				Input.parse_input_event(down)
				for i in 4:
					await process_frame
				var drag := InputEventScreenDrag.new()
				drag.index = 0
				drag.position = Vector2(float(t[2]), float(t[3]))
				Input.parse_input_event(drag)
				for i in 4:
					await process_frame
			"untouch":
				var up := InputEventScreenTouch.new()
				up.index = 0
				up.pressed = false
				Input.parse_input_event(up)
			"flag":
				root.get_node(^"GameState").get(&"flags").call(&"set_flag", StringName(arg))
			"quit":
				break
	quit()


## Appui d'un doigt (souris émulée) à la position [param at], en pixels de la fenêtre.
func _tap(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		for i in 4:
			await process_frame


## Vraie entrée (InputEventAction) : `Input.action_press` seul n'atteint pas `_unhandled_input`.
func _event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = StringName(action)
	event.pressed = pressed
	Input.parse_input_event(event)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s_%s.png" % [String(_args["out"]), name]
	img.save_png(path)
	print("shot ", path, " ", img.get_size())


func _dir(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
