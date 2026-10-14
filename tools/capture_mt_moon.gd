extends SceneTree
## Capture des étages du Mont Sélénite (jalon 12 T9, docs/tech/jalon-12.md §2.4) avec les vrais
## composants (carte, joueur peint et sa caméra bornée, WorldLighting + profil de la carte,
## halos), pour Movie Maker, et **fiche de la caméra** pour la mesure de luminance
## (`tools/art/luminance_grotte.py`).
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/f.png --fixed-fps 60 \
##     --quit-after 40 -s res://tools/capture_mt_moon.gd -- --map=mt_moon_1f --cell=29,40
##
## Options : `--map=<id>` (défaut mt_moon_1f), `--cell=x,y` (défaut : premier point
## d'apparition), `--facing=`, `--steps=dir:n` (pas joués par le joueur), `--aim=x,y` +
## `--zoom=z` (caméra libre), `--overview` (carte entière à l'écran), `--noplayer`, `--perf`
## (fps, appels de dessin, mémoire des textures toutes les 30 images), `--meta=<fichier.json>`
## (écrit à l'image 20 : carte, centre de l'écran en pixels du monde, zoom, taille de la vue,
## case du joueur). Série complète : `tools/capture_mt_moon.sh`.

const MAPS_DIR: String = "res://game/world/maps/"
const TILE: int = 96
const META_FRAME: int = 20

var _args: Dictionary = {}
var _frame: int = 0
var _map: Node2D
var _player: Node
var _camera: Camera2D


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map_id := String(_args.get("map", "mt_moon_1f"))
	_map = (load(MAPS_DIR + map_id + ".tscn") as PackedScene).instantiate()
	root.add_child(_map)
	var first: Node = _map.get_node(^"Spawns").get_child(0)
	var cell: Vector2i = _map.call(&"get_spawn_cell", StringName(first.name))
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		cell = Vector2i(int(parts[0]), int(parts[1]))
	var facing := _direction(String(_args.get("facing", "down")))
	if not _args.has("noplayer"):
		_player = (load("res://game/player/player.tscn") as PackedScene).instantiate()
		_map.call(&"spawn_player_at", _player, cell, facing)
		_player.call(&"set_input_enabled", false)
		if _args.has("steps"):
			var step: PackedStringArray = String(_args["steps"]).split(":")
			_walk(_player, _direction(step[0]), int(step[1]))
	if _args.has("aim") or _args.has("overview"):
		_camera = Camera2D.new()
		var size: Vector2i = _map.get(&"size")
		var view := root.get_visible_rect().size
		var zoom := float(_args.get("zoom", "1"))
		var aim := Vector2(size) * TILE / 2.0
		if _args.has("overview"):
			zoom = minf(view.x / (size.x * TILE), view.y / (size.y * TILE))
		else:
			var parts: PackedStringArray = String(_args["aim"]).split(",")
			aim = Vector2(float(parts[0]), float(parts[1])) * TILE
		_camera.position = aim
		_camera.zoom = Vector2(zoom, zoom)
		root.add_child(_camera)
		_camera.make_current()
	var lighting: CanvasLayer = (load("res://game/world/lighting/world_lighting.gd")
		as Script).new()
	root.add_child(lighting)
	var library: Object = (load("res://game/world/lighting/lighting_library.gd") as Script).new()
	library.call(&"load_file")
	lighting.call(&"apply", library.call(&"get_profile", _map.get("light_profile")), _map)
	print("capture_mt_moon : %s, vue %s, joueur %s" % [map_id, root.get_visible_rect().size,
		cell])
	process_frame.connect(_tick)


func _tick() -> void:
	_frame += 1
	if _frame == META_FRAME and _args.has("meta"):
		_write_meta()
	if _args.has("perf") and _frame % 30 == 0:
		print("[perf] image %d : fps=%d draw=%d objets=%d tex=%.1f Mo" % [_frame,
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


## Fiche de la caméra : de quoi retrouver la case du monde sous chaque pixel de la capture.
func _write_meta() -> void:
	var camera := root.get_viewport().get_camera_2d()
	var view := root.get_visible_rect().size
	var center := camera.get_screen_center_position() if camera != null else view / 2.0
	var zoom := camera.zoom.x if camera != null else 1.0
	var data := {
		"map": String(_map.get(&"map_id")),
		"tile": TILE,
		"center": [center.x, center.y],
		"zoom": zoom,
		"view": [view.x, view.y],
		"player": [] if _player == null else [(_player.call(&"get_cell") as Vector2i).x,
			(_player.call(&"get_cell") as Vector2i).y],
	}
	var file := FileAccess.open(String(_args["meta"]), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _walk(player: Node, direction: Vector2i, count: int) -> void:
	for i: int in count:
		player.call(&"script_step", direction)
		await create_timer(0.3).timeout


func _direction(name: String) -> Vector2i:
	match name:
		"up":
			return Vector2i.UP
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.DOWN
