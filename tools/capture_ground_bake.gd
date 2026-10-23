extends SceneTree
## Capture de contrôle de la cuisson du sol (moteur commun) : une carte, une caméra posée sur une
## case, le sol cuit (défaut) ou vivant (`--live`), pour comparer les deux images au pixel près.
## Movie Maker à cadence fixe : le temps du shader (eau) est le même d'une capture à l'autre.
##
##   godot --path . --write-movie build/bake/cuit.png --fixed-fps 60 --quit-after 30 \
##     -s res://tools/capture_ground_bake.gd -- --map=route_11 --aim=40,20 [--live] [--move=600]
##
## `--aim=x,y` : centre de la vue (cases) ; `--move=px` : la caméra glisse vers la droite de
## px pixels par seconde (morceaux rendus en route) ; `--live` : `PaintedGround.auto_bake` faux.

const TILE: int = 96

var _args: Dictionary = {}
var _camera: Camera2D
var _speed: float = 0.0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	PaintedGround.auto_bake = not _args.has("live")
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map_id := String(_args.get("map", "route_11"))
	var map: Node2D = (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	var aim: PackedStringArray = String(_args.get("aim", "10,10")).split(",")
	_camera = Camera2D.new()
	_camera.position = Vector2(float(aim[0]), float(aim[1])) * TILE
	root.add_child(_camera)
	_camera.make_current()
	root.add_child(map)
	var lighting := WorldLighting.new()
	root.add_child(lighting)
	var library := LightingLibrary.new()
	library.load_file()
	lighting.apply(library.get_profile(map.get("light_profile")), map)
	_speed = float(_args.get("move", "0"))
	if _speed != 0.0:
		process_frame.connect(_move)
	var ground := map.get_node_or_null(^"PaintedGround") as PaintedGround
	print("capture_ground_bake : %s, cuit=%s morceaux=%s eau=%s" % [map_id,
		ground != null and ground.is_baked(), ground != null and ground.is_chunked(),
		ground != null and ground.get_water() != null])


func _move() -> void:
	_camera.position.x += _speed / 60.0
