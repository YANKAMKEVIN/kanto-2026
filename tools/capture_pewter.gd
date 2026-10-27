extends SceneTree
## Captures de la Route 2 nord et d'Argenta (jalon 10 T11) avec les vrais composants (carte,
## joueur peint et sa caméra, PNJ peints, WorldLighting + profil de la carte), pour Movie Maker.
## Modèle : `tools/capture_route_2.gd`.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 40 \
##     -s res://tools/capture_pewter.gd -- --map=pewter_city --cell=18,43 [--facing=up]
##
## Options : `--map=` route_2_north | pewter_city (défaut) | viridian_forest_gate_north,
## `--cell=x,y` case du joueur (défaut : le spawn `--spawn=`, sinon le premier), `--facing=`
## up|down|left|right, `--steps=dir:n` (n pas scriptés avant la capture), `--aim=x,y` (cases) +
## `--zoom=z` : caméra libre (vue d'ensemble), `--noplayer`, `--perf` : journal des appels de
## dessin et de la mémoire des textures toutes les 30 images ; `--boot` : la vraie scène
## `game/boot.tscn` (HUD, titre de zone, garde, scènes) avec le départ `--start=` (défaut
## `pewter`) puis le joueur posé sur `--cell` ; `--interact` (avec `--boot`) : « interagir »
## après 10 images ; `--flags=a,b` (avec `--boot`) : drapeaux levés avant de poser le joueur ;
## `--mount=bike`, `--pose=fish_wait` : héros en selle ou en pose de pêche (DAF.5) ;
## `--hold=right` (avec `--boot`) : direction maintenue après 10 images (poussée contre un bord
## de carte, jalon 12 T8). Série complète : `tools/capture_pewter.sh`. 2340 × 1080 : `override.cfg` temporaire à la
## racine (taille de fenêtre), retiré après.

const TILE: int = 96

var _args: Dictionary = {}
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	if _args.has("boot"):
		_setup_boot()
		return
	var map_id := String(_args.get("map", "pewter_city"))
	var map: Node2D = (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	root.add_child(map)
	var cell := Vector2i.ZERO
	if _args.has("spawn"):
		cell = map.call(&"get_spawn_cell", StringName(_args["spawn"]))
	else:
		cell = map.call(&"get_spawn_cell", (map.get_node(^"Spawns").get_child(0)).name)
	if _args.has("cell"):
		cell = _cell(String(_args["cell"]))
	var facing := _direction(String(_args.get("facing", "up")))
	if not _args.has("noplayer"):
		var player: Node = (load("res://game/player/player.tscn") as PackedScene).instantiate()
		map.call(&"spawn_player_at", player, cell, facing)
		player.call(&"set_input_enabled", false)
		if _args.get("mount", "") == "bike":  # DAF.5 : héros à vélo (série 25)
			player.call(&"set_mount", Mount.Kind.BIKE, true)
		if _args.has("pose"):  # DAF.5 : pose tenue (fish_cast, fish_wait)
			player.call(&"set_pose", StringName(_args["pose"]))
		if _args.has("steps"):
			var step: PackedStringArray = String(_args["steps"]).split(":")
			_walk(player, _direction(step[0]), int(step[1]))
	if _args.has("aim"):
		var aim: PackedStringArray = String(_args["aim"]).split(",")
		var camera := Camera2D.new()
		camera.position = Vector2(float(aim[0]), float(aim[1])) * TILE
		var zoom := float(_args.get("zoom", "1"))
		camera.zoom = Vector2(zoom, zoom)
		root.add_child(camera)
		camera.make_current()
	var lighting: CanvasLayer = (load("res://game/world/lighting/world_lighting.gd")
		as Script).new()
	root.add_child(lighting)
	var library: Object = (load("res://game/world/lighting/lighting_library.gd") as Script).new()
	library.call(&"load_file")
	lighting.call(&"apply", library.call(&"get_profile", map.get("light_profile")), map)
	print("capture_pewter : %s, vue %s, joueur %s" % [map_id, root.get_visible_rect().size, cell])
	if _args.has("perf"):
		process_frame.connect(_report)


func _setup_boot() -> void:
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/%s.json"
		% String(_args.get("start", "pewter")))
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 3:
		await process_frame
	var state: Node = root.get_node(^"GameState")
	for flag: String in String(_args.get("flags", "")).split(",", false):
		state.get(&"flags").call(&"set_flag", StringName(flag))
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	if _args.has("flags"):
		map.call(&"refresh_npcs", state.get(&"flags"))
	if _args.has("cell"):
		map.call(&"spawn_player_at", player, _cell(String(_args["cell"])),
			_direction(String(_args.get("facing", "up"))))
	print("capture_pewter (boot) : carte %s, joueur %s" % [map.get("map_id"),
		player.call(&"get_cell")])
	if _args.has("steps"):
		var step: PackedStringArray = String(_args["steps"]).split(":")
		_walk(player, _direction(step[0]), int(step[1]))
	if _args.has("hold"):
		# Direction maintenue (vraie entrée `move_*`) : poussée contre un bord de carte (J12 T8).
		for i in 10:
			await process_frame
		Input.action_press(StringName("move_" + String(_args["hold"])))
	if _args.has("mash"):
		# Ferme les dialogues d'entrée (avertissement de la grotte) : « interagir » répété.
		for k in int(_args["mash"]):
			for i in 20:
				await process_frame
			Input.action_press(&"interact")
			for i in 2:
				await process_frame
			Input.action_release(&"interact")
	if _args.has("interact"):
		for i in 10:
			await process_frame
		Input.action_press(&"interact")
		for i in 3:
			await process_frame
		Input.action_release(&"interact")
	if _args.has("perf"):
		process_frame.connect(_report)


func _report() -> void:
	_frame += 1
	if _frame % 30 != 0:
		return
	print("[perf] image %d : fps=%d draw=%d objets=%d tex=%.1f Mo" % [_frame,
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _walk(player: Node, direction: Vector2i, count: int) -> void:
	for i: int in count:
		player.call(&"script_step", direction)
		await create_timer(0.3).timeout


func _cell(text: String) -> Vector2i:
	var parts: PackedStringArray = text.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
