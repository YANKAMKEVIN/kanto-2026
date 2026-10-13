extends SceneTree
## Capture de la carte de QA PROVISOIRE `qa_daycare` (J15 T6 ; retirée au T23) dans la vraie
## scène `game/boot.tscn`, avec un départ de `tools/debug_start/` (copié dans `user://`, forcé
## dans Boot) :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_qa_daycare.gd -- \
##     --start=daycare_ready --out=build/captures/j15_t6 [--cell=7,6] [--facing=up] [--walk=left:4]
##
## Écrit `<out>/<start>.png` (et `<out>/<start>_apres.png` avec `--walk=<direction>:<cases>`).

const START_PATH: String = "user://t6_capture_start.json"

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var start := String(_args.get("start", "daycare_qa"))
	var out := String(_args.get("out", "build/captures/j15_t6"))
	DirAccess.make_dir_recursive_absolute(out)
	var source := "res://tools/debug_start/%s.json" % start
	var file := FileAccess.open(START_PATH, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(source))
	file.close()
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", START_PATH)
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 60:
		await process_frame
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		map.call(&"spawn_player_at", player, Vector2i(int(parts[0]), int(parts[1])),
			_direction(String(_args.get("facing", "up"))))
	print("capture_qa_daycare : %s, carte %s, joueur %s, vue %s" % [start,
		map.get(&"map_id"), player.call(&"get_cell"), root.get_visible_rect().size])
	for i in 30:
		await process_frame
	await _shot("%s/%s.png" % [out, start])
	if _args.has("walk"):
		var walk: PackedStringArray = String(_args["walk"]).split(":")
		var from: Vector2i = player.call(&"get_cell")
		var action := StringName("move_" + walk[0])
		var steps := int(walk[1])
		var deadline := Time.get_ticks_msec() + 10000
		Input.action_press(action)
		while (player.call(&"get_cell") - from).length() < steps \
				and Time.get_ticks_msec() < deadline:
			await process_frame
		Input.action_release(action)
		for i in 30:
			await process_frame
		print("déplacement %s : %s → %s" % [action, from, player.call(&"get_cell")])
		await _shot("%s/%s_apres.png" % [out, start])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(START_PATH))
	quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("image : ", path)


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
