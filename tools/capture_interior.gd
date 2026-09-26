extends SceneTree
## Outil de vérification visuelle (Movie Maker) : une carte + le joueur, sans SceneRouter.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 30 --quit-after 20 \
##     -s res://tools/capture_interior.gd -- --size=2340x1080 --map=player_house_2f \
##     [--spawn=start | --cell=6,5] [--facing=down|up|left|right] [--walk=up:3]
##     [--npcs=res://tests/fixtures/npcs/:sample_map]
##
## Instancie game/world/maps/<map>.tscn et game/player/player.tscn, place le joueur au
## spawn (ou sur la case) et laisse la caméra du joueur cadrer la pièce (CameraFraming).
## `--walk=<direction>:<cases>` tient la direction jusqu'à parcourir ce nombre de cases.
## `--npcs=<dossier>:<fichier>` : PNJ lus dans `<dossier><fichier>.json` au lieu de
## `data/npcs/<map>.json` (vérification de la scène Npc avec des données d'essai).
## Affiche « CAPTURE frame=<n> cell=… » quand l'image est stable : garder la dernière image.

const PLAYER_SCENE: String = "res://game/player/player.tscn"
const MAPS_DIR: String = "res://game/world/maps/"
const DIRECTIONS: Dictionary = {
	"down": Vector2i.DOWN, "up": Vector2i.UP, "left": Vector2i.LEFT, "right": Vector2i.RIGHT,
}

var _args: Dictionary = {}
var _player: Node2D
var _frame: int = 0
var _walk_action: StringName = &""
var _walk_goal: Vector2i = Vector2i(-1, -1)


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1]
	if _args.has("size"):
		var parts: PackedStringArray = String(_args["size"]).split("x")
		DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map_id: String = _args.get("map", "player_house_2f")
	var map := (load(MAPS_DIR + map_id + ".tscn") as PackedScene).instantiate()
	if _args.has("npcs"):
		var spec := String(_args["npcs"])
		var cut := spec.rfind(":")
		map.set(&"npcs_dir", spec.substr(0, cut))
		map.set(&"map_id", StringName(spec.substr(cut + 1)))
	root.add_child(map)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	var facing: Vector2i = DIRECTIONS.get(_args.get("facing", "down"), Vector2i.DOWN)
	if _args.has("cell"):
		var xy: PackedStringArray = String(_args["cell"]).split(",")
		var cell := Vector2i(int(xy[0]), int(xy[1]))
		map.get_node(^"Entities").add_child(_player)
		_player.call(&"enter_map", map.call(&"get_grid"), cell, facing,
			map.call(&"get_pixel_rect"))
	else:
		map.call(&"spawn_player", _player, StringName(_args.get("spawn", "start")), facing)
	if _args.has("walk"):
		var walk: PackedStringArray = String(_args["walk"]).split(":")
		var direction: Vector2i = DIRECTIONS[walk[0]]
		_walk_action = StringName("move_" + walk[0])
		_walk_goal = _player.call(&"get_cell") + direction * int(walk[1])
	print("capture : %s, vue %s, case %s" % [map_id, root.get_visible_rect().size,
		_player.call(&"get_cell")])
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	var cell: Vector2i = _player.call(&"get_cell")
	if _walk_action != &"":
		if cell == _walk_goal or _frame > 200:
			Input.action_release(_walk_action)
			_walk_action = &""
		elif _frame >= 3:
			Input.action_press(_walk_action)
		return
	if not _player.call(&"is_moving"):
		print("CAPTURE frame=%d cell=%s facing=%s pos=%s" % [
			_frame, cell, _player.call(&"get_facing"), _player.position])
