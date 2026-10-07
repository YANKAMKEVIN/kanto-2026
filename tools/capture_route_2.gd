extends SceneTree
## Capture de la Route 2 (jalon 8 T5) avec les vrais composants (carte, joueur peint et sa
## caméra, PNJ peints, WorldLighting + profil de la carte), pour Movie Maker.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 40 \
##     -s res://tools/capture_route_2.gd -- --cell=20,57 [--facing=up] [--steps=up:3]
##
## Options : `--cell=x,y` case du joueur (défaut : le spawn `from_viridian_c`), `--facing=`
## up|down|left|right, `--steps=dir:n` (le joueur marche n cases par script avant la capture),
## `--aim=x,y` (cases) + `--zoom=z` : caméra libre au lieu de celle du joueur (carte entière :
## `--aim=21,30 --zoom=0.18`), `--noplayer`, `--perf` : journal des appels de dessin et de la
## mémoire des textures toutes les 30 images ; `--boot` : la vraie scène `game/boot.tscn` (HUD,
## lumière de Boot) avec le départ de débogage `tools/debug_start/route_2.json`, puis le joueur
## posé sur `--cell` ; `--interact` (avec `--boot`) : appui sur « interagir » après 10 images.
## Série complète du T5 : `tools/capture_route_2.sh`.
## 2340 × 1080 : `override.cfg` temporaire à la racine ([display] window/size/
## window_width_override=2340, window_height_override=1080), à retirer après.

const MAP_PATH: String = "res://game/world/maps/route_2.tscn"
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
	var map: Node2D = (load(MAP_PATH) as PackedScene).instantiate()
	root.add_child(map)
	var cell: Vector2i = map.call(&"get_spawn_cell", &"from_viridian_c")
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
	print("capture_route_2 : vue %s, joueur %s" % [root.get_visible_rect().size, cell])
	if _args.has("perf"):
		process_frame.connect(_report)


func _setup_boot() -> void:
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/route_2.json")
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 3:
		await process_frame
	var map: Node = boot.call(&"get_map")
	var player: Node = boot.call(&"get_player")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		map.call(&"spawn_player_at", player, Vector2i(int(parts[0]), int(parts[1])),
			_direction(String(_args.get("facing", "up"))))
	print("capture_route_2 (boot) : carte %s, joueur %s" % [map.get("map_id"),
		player.call(&"get_cell")])
	if _args.has("steps"):
		var step: PackedStringArray = String(_args["steps"]).split(":")
		_walk(player, _direction(step[0]), int(step[1]))
	if _args.has("interact"):
		# T7 : le joueur appuie sur « interagir » (PRENDRE, examiner…) ; --dismiss=n appuie
		# sur la boîte de dialogue n fois ensuite (une page par appui).
		for i in 10:
			await process_frame
		Input.action_press(&"interact")
		for i in 3:
			await process_frame
		Input.action_release(&"interact")
		var box: Node = boot.call(&"get_dialogue_box")
		for i in int(_args.get("dismiss", "0")):
			for k in 40:
				await process_frame
			box.emit_signal(&"advance_requested")
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


func _direction(name: String) -> Vector2i:
	match name:
		"down":
			return Vector2i.DOWN
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.UP
