extends SceneTree
## Capture de la Bourg Palette peint (DA.2) avec les vrais composants (carte, joueur peint et sa
## caméra, PNJ peints, WorldLighting + profil de la carte), pour Movie Maker.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 40 \
##     -s res://tools/capture_pallet_town.gd -- --cell=23,40 [--facing=up] [--steps=up:3]
##
## Options : `--cell=x,y` case du joueur (défaut : le spawn `start`), `--facing=`
## up|down|left|right, `--steps=dir:n` (le joueur marche n cases par script avant la capture),
## `--aim=x,y` (cases) + `--zoom=z` : caméra libre au lieu de celle du joueur (carte entière :
## `--aim=24,22 --zoom=0.25`), `--noplayer`, `--perf` : journal des appels de dessin et de la
## mémoire des textures toutes les 30 images ; `--boot` : la vraie scène `game/boot.tscn` (HUD,
## lumière de Boot) avec le départ de débogage `tools/debug_start/pallet_town.json`, puis le joueur
## posé sur `--cell` (les options de caméra libre et `--noplayer` sont alors ignorées).
## `--prologue=<dossier>` : nouvelle partie dans Boot, joueur en (23, 6) qui monte vers les
## hautes herbes ; la scène de Chen se joue (répliques avancées seules) et trois images sont
## écrites dans le dossier : Chen qui accourt, Chen à côté du joueur, la marche vers le labo.
## 2340 × 1080 : `override.cfg` temporaire à la racine ([display] window/size/
## window_width_override=2340, window_height_override=1080), à retirer après.

const MAP_PATH: String = "res://game/world/maps/pallet_town.tscn"
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
	if _args.has("prologue"):
		_setup_prologue()
		return
	if _args.has("boot"):
		_setup_boot()
		return
	var map: Node2D = (load(MAP_PATH) as PackedScene).instantiate()
	root.add_child(map)
	var cell: Vector2i = map.call(&"get_spawn_cell", &"start")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		cell = Vector2i(int(parts[0]), int(parts[1]))
	var facing := _direction(String(_args.get("facing", "up")))
	if not _args.has("noplayer"):
		var player: Node = (load("res://game/player/player.tscn") as PackedScene).instantiate()
		map.call(&"spawn_player_at", player, cell, facing)
		player.call(&"set_input_enabled", false)
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
	print("capture_pallet_town : vue %s, joueur %s" % [root.get_visible_rect().size, cell])
	if _args.has("perf"):
		process_frame.connect(_report)


func _setup_boot() -> void:
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/pallet_town.json")
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 45:
		await process_frame
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		map.call(&"spawn_player_at", player, Vector2i(int(parts[0]), int(parts[1])),
			_direction(String(_args.get("facing", "up"))))
	print("capture_pallet_town (boot) : carte %s, joueur %s" % [map.get("map_id"),
		player.call(&"get_cell")])
	if _args.has("steps"):
		var step: PackedStringArray = String(_args["steps"]).split(":")
		_walk(player, _direction(step[0]), int(step[1]))
	if _args.has("perf"):
		process_frame.connect(_report)


func _setup_prologue() -> void:
	var out := String(_args["prologue"])
	DirAccess.make_dir_recursive_absolute(out)
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"start_map", &"pallet_town")
	root.add_child(boot)
	for i in 45:
		await process_frame
	boot.call(&"get_dialogue_runner").set(&"chars_per_second", 0.0)
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	map.call(&"spawn_player_at", player, Vector2i(23, 6), Vector2i.UP)
	for i in 10:
		await process_frame
	Input.action_press(&"move_up")
	var shots := {"chen_accourt": false, "chen_arrete": false, "marche_labo": false}
	var frame := 0
	var running_seen := false
	while frame < 3000:
		await process_frame
		frame += 1
		var director: Node = boot.call(&"get_cutscene_director")
		var running: bool = director.call(&"is_running")
		running_seen = running_seen or running
		if running_seen and not running:
			break
		map = boot.call(&"get_map")
		var oak: Node = map.call(&"get_npc", &"oak") if map.get(&"map_id") == &"pallet_town" \
			else null
		var box: Node = boot.call(&"get_dialogue_box")
		if oak != null and not shots["chen_accourt"] and oak.call(&"get_cell").y <= 9:
			_shot(out + "/prologue_1_chen_accourt.png")
			shots["chen_accourt"] = true
		if oak != null and not shots["chen_arrete"] and box.call(&"is_open") \
				and oak.call(&"get_cell").y == 3:
			_shot(out + "/prologue_2_chen_arrete.png")
			shots["chen_arrete"] = true
		if oak != null and not shots["marche_labo"] and player.call(&"get_cell").y >= 6:
			_shot(out + "/prologue_3_marche_labo.png")
			shots["marche_labo"] = true
		if box.call(&"is_open") and frame % 20 == 0:
			box.emit_signal(&"advance_requested")
	Input.action_release(&"move_up")
	print("capture_pallet_town (prologue) : %s, %d images" % [shots, frame])
	quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("image : ", path)


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


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
