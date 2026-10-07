extends SceneTree
## Vérification visuelle de la destination « à venir » (depuis le jalon 8 T5 : la porte du
## poste de la Route 2, jalon-08.md §2.2) : Boot sur la Route 2 devant la porte, move_up injecté
## jusqu'à l'écran « FORÊT DE JADE — À venir », puis retour devant la porte, tourné vers le sud.
## (Jalon 5 : bord nord de la Route 1 ; jalon 7 : sortie nord de Jadielle.)
##
## Sur le Mac (2340×1080 via override.cfg temporaire) :
##   godot --path . --always-on-top --fixed-fps 30 --quit-after 600 \
##     -s res://tools/capture_coming_soon.gd -- --out=build/captures/jalon08_t5/porte
## Images : before (devant la porte, avant), screen (écran « à venir »), after (retour).

const BOOT_SCENE: String = "res://game/boot.tscn"

var _boot: Node
var _player: Node
var _router: Node
var _out_dir: String = "build/captures/jalon08_t5/porte"
var _frame: int = 0
var _state: String = "before"
var _wait: int = 0
var _shot_name: String = ""


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run",
			&"interact"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_2")
	_boot.set(&"start_spawn", &"from_forest_gate")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	_router = root.get_node(^"SceneRouter")
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if not _shot_name.is_empty():
		_save(_shot_name)
		_shot_name = ""
	if _player == null:
		_player = _boot.call(&"get_player")
		return
	var screen: Node = _boot.call(&"get_coming_soon_screen")
	match _state:
		"before":
			if _frame == 40:
				_mark("before")
				Input.action_press(&"move_up")
				_state = "walk"
		"walk":
			if screen.call(&"is_showing"):
				Input.action_release(&"move_up")
				_state = "screen"
				_wait = 0
		"screen":
			var label: Label = screen.call(&"get_label")
			if label.modulate.a >= 0.99:
				_wait += 1
				if _wait == 20:
					_mark("screen")
					_state = "back"
		"back":
			if not screen.call(&"is_showing") and not _router.call(&"is_transitioning"):
				_wait = 0
				_state = "after"
		"after":
			_wait += 1
			if _wait == 20:
				_mark("after")
				_state = "done"
		"done":
			_wait += 1
			if _wait == 5:
				quit()


func _mark(capture_name: String) -> void:
	print("CAPTURE %s frame=%d cell=%s facing=%s" % [capture_name, _frame,
		_player.call(&"get_cell"), _player.call(&"get_facing")])
	_shot_name = capture_name


func _save(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	if not DisplayServer.window_can_draw():
		RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	print("  → %s" % path)
