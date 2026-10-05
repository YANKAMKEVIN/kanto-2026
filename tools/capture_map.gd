extends SceneTree
## Outil de vérification : affiche une carte entière (caméra dézoomée) pour Movie Maker.
##
##   godot --path . --write-movie build/cap/map.png --fixed-fps 10 --quit-after 6 \
##     -s res://tools/capture_map.gd -- --size=2304x1632 [--grid] [--map=viridian_city]
##
## 2304×1632 a le ratio de la carte (48×34) : la carte remplit exactement la vue.
## `--grid` superpose la grille et les coordonnées de cases (vérification du plan).

const MAP_PATH: String = "res://game/world/maps/pallet_town.tscn"
const TILE: int = 96

var _map: Node2D
var _font: Font


func _init() -> void:
	var window_size := _arg_size()
	if window_size != Vector2i.ZERO:
		DisplayServer.window_set_size(window_size)
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


## Taille de fenêtre passée après `--` : `--size=2304x1632` (la surcharge de taille du
## projet l'emporte sinon sur --resolution).
func _arg_size() -> Vector2i:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts := arg.trim_prefix("--size=").split("x")
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO


func _setup() -> void:
	var path := MAP_PATH
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			path = "res://game/world/maps/%s.tscn" % arg.trim_prefix("--map=")
	_map = (load(path) as PackedScene).instantiate()
	root.add_child(_map)
	var size: Vector2i = _map.get(&"size")
	var world := Vector2(size * TILE)
	var camera := Camera2D.new()
	camera.position = world / 2.0
	var view := Vector2(root.get_visible_rect().size)
	var zoom := minf(view.x / world.x, view.y / world.y)
	camera.zoom = Vector2(zoom, zoom)
	root.add_child(camera)
	camera.make_current()
	if "--grid" in OS.get_cmdline_user_args():
		_font = ThemeDB.fallback_font
		var overlay := Node2D.new()
		overlay.z_index = 100
		overlay.draw.connect(_draw_grid.bind(overlay, size))
		root.add_child(overlay)
	print("capture : vue %s, zoom %.3f" % [view, zoom])


func _draw_grid(overlay: Node2D, size: Vector2i) -> void:
	for x: int in size.x + 1:
		var c := Color(0, 0, 0, 0.55) if x % 4 == 0 else Color(0, 0, 0, 0.18)
		overlay.draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, size.y * TILE), c, 3.0)
	for y: int in size.y + 1:
		var c := Color(0, 0, 0, 0.55) if y % 4 == 0 else Color(0, 0, 0, 0.18)
		overlay.draw_line(Vector2(0, y * TILE), Vector2(size.x * TILE, y * TILE), c, 3.0)
	for y: int in range(0, size.y, 2):
		for x: int in range(0, size.x, 2):
			overlay.draw_string(_font, Vector2(x * TILE + 4, y * TILE + 34), "%d,%d" % [x, y],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.95))
