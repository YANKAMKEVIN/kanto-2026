extends SceneTree
## Captures des cartes habillées du jalon 16 (T10 : les 9 pièces du S.S. Anne et l'Arène de
## Carmin) dans la vraie scène `game/boot.tscn` (HUD, lumière, PNJ), depuis un départ de débogage
## de `tools/debug_start/` dont on remplace la carte et l'arrivée :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_j16_rooms.gd -- \
##     --start=ss_anne --map=ss_anne_restaurant --spawn=entrance --out=build/captures/jalon16_t10 \
##     [--name=restaurant] [--cell=8,5] [--facing=up] [--flags=a,b]
##
## Écrit `<out>/<name>.png` et affiche une ligne « [noeuds] » (nœuds de la carte) et « [perf] »
## (mémoire des textures, appels de dessin) sur la vue posée.

const TEMP_START := "user://capture_j16_start.json"

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var start_id := String(_args.get("start", "ss_anne"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/debug_start/%s.json" % start_id))
	data["map"] = String(_args.get("map", data["map"]))
	data["spawn"] = String(_args.get("spawn", data.get("spawn", "entrance")))
	if _args.has("facing"):
		data["facing"] = String(_args["facing"])
	if _args.has("flags"):
		var flags: Array = data.get("flags", [])
		for flag: String in String(_args["flags"]).split(","):
			flags.append(flag)
		data["flags"] = flags
	var file := FileAccess.open(TEMP_START, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var out := String(_args.get("out", "build/captures/jalon16_t10"))
	var name := String(_args.get("name", data["map"]))
	DirAccess.make_dir_recursive_absolute(out)
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", TEMP_START)
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
	for i in 40:
		await process_frame
	print("[noeuds] %s : %d nœuds (carte), joueur %s" % [map.get(&"map_id"), _count(map),
		player.call(&"get_cell")])
	print("[perf] %s : textures %.1f Mo, appels de dessin %d, fps %.0f" % [map.get(&"map_id"),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.TIME_FPS)])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("image : %s/%s.png" % [out, name])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_START))
	quit()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
