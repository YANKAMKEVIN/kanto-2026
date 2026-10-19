extends SceneTree
## Captures de l'Arène de Carmin (jalon 16 T14) dans la vraie scène `game/boot.tscn` (HUD,
## lumière, PNJ) depuis un départ de débogage de `tools/debug_start/` :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_vermilion_gym.gd -- \
##     --start=vermilion_gym_solved --out=build/captures/jalon16_t14 --name=bob \
##     [--cell=8,4] [--facing=up] [--walk=up:3] [--talk=4]
##
## `--cell` / `--facing` replacent le joueur ; `--walk=<direction>:<cases>` maintient
## `move_<direction>` jusqu'à ce que le joueur ait avancé de ce nombre de cases (garde de 10 s)
## puis écrit `<name>_apres.png` ; `--talk=<pages>` appuie sur `interact`, fait défiler
## <pages> bulles puis écrit `<name>_parole.png` (la carte du Champion si elle est à l'écran).
## Écrit toujours `<out>/<name>.png` d'abord.

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var start := String(_args.get("start", "vermilion_gym_map"))
	var out := String(_args.get("out", "build/captures/jalon16_t14"))
	var name := String(_args.get("name", start))
	DirAccess.make_dir_recursive_absolute(out)
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/%s.json" % start)
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
	print("capture_vermilion_gym : %s, carte %s, joueur %s, vue %s" % [start,
		map.get(&"map_id"), player.call(&"get_cell"), root.get_visible_rect().size])
	for i in 30:
		await process_frame
	await _shot("%s/%s.png" % [out, name])
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
		await _shot("%s/%s_apres.png" % [out, name])
	if _args.has("talk"):
		var box: Node = boot.call(&"get_dialogue_box")
		boot.call(&"get_dialogue_runner").set(&"chars_per_second", 0.0)
		for i in 20:
			await process_frame
		Input.action_press(&"interact")
		for i in 6:
			await process_frame
		Input.action_release(&"interact")
		var pages := int(_args["talk"])
		var deadline := Time.get_ticks_msec() + 10000
		while pages > 0 and Time.get_ticks_msec() < deadline:
			await process_frame
			if box.call(&"is_open"):
				for i in 10:
					await process_frame
				box.emit_signal(&"advance_requested")
				pages -= 1
		for i in 40:
			await process_frame
		print("bulle ouverte : %s, pages restantes %d" % [box.call(&"is_open"), pages])
		await _shot("%s/%s_parole.png" % [out, name])
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
