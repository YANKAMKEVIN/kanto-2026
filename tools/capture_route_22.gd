extends SceneTree
## Capture de la Route 22 avec les vrais composants (carte, joueur peint et sa caméra,
## PNJ peints, WorldLighting + profil de la carte), pour Movie Maker.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 40 \
##     -s res://tools/capture_route_22.gd -- --cell=11,13 [--facing=up] [--steps=right:4]
##
## Options : `--cell=x,y` case du joueur (défaut : le spawn `from_viridian`), `--facing=`
## up|down|left|right, `--steps=dir:n` (le joueur marche n cases par script avant la capture,
## 4 cases/s : prévoir assez d'images), `--aim=x,y` (cases) + `--zoom=z` : caméra libre au lieu
## de celle du joueur (carte entière : `--aim=23,13.5 --zoom=0.4`), `--noplayer`.
## 2340 × 1080 : `override.cfg` temporaire à la racine ([display] window/size/
## window_width_override=2340, window_height_override=1080), à retirer après.

const MAP_PATH: String = "res://game/world/maps/route_22.tscn"
const TILE: int = 96

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map: Node2D = (load(MAP_PATH) as PackedScene).instantiate()
	root.add_child(map)
	var cell: Vector2i = map.call(&"get_spawn_cell", &"from_viridian")
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		cell = Vector2i(int(parts[0]), int(parts[1]))
	var facing := _direction(String(_args.get("facing", "left")))
	var player: Node = null
	if not _args.has("noplayer"):
		player = (load("res://game/player/player.tscn") as PackedScene).instantiate()
		map.get_node(^"Entities").add_child(player)
		player.call(&"enter_map", map.call(&"get_grid"), cell, facing,
			map.call(&"get_pixel_rect"))
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
	print("capture_route_22 : vue %s, joueur %s, mémoire des textures %.1f Mo" % [
		root.get_visible_rect().size, cell,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _walk(player: Node, direction: Vector2i, count: int) -> void:
	for i: int in count:
		player.call(&"script_step", direction)
		await create_timer(0.3).timeout


func _direction(name: String) -> Vector2i:
	match name:
		"up":
			return Vector2i.UP
		"down":
			return Vector2i.DOWN
		"right":
			return Vector2i.RIGHT
	return Vector2i.LEFT
