extends SceneTree
## Capture d'une carte du jalon 15 T14 (Route 6, Carmin-sur-Mer, intérieurs) avec les vrais
## composants (carte, PNJ, joueur peint et sa caméra, WorldLighting + profil de la carte), pour
## Movie Maker. Modèle : `capture_cape.gd`.
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 40 \
##     -s res://tools/capture_vermilion.gd -- --map=vermilion_city --cell=31,24 [--facing=down]
##
## Options : `--map=` (défaut vermilion_city) ; `--cell=x,y` case du joueur (défaut : premier
## spawn) ; `--facing=` ; `--steps=dir:n` ; `--aim=x,y` + `--zoom=z` (caméra libre) ;
## `--noplayer` ; `--flags=a,b` : drapeaux levés avant l'arrivée (navire parti, arbre coupé…).
## 2340 × 1080 : `override.cfg` temporaire à la racine, à retirer après.

const TILE: int = 96

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map_id := String(_args.get("map", "vermilion_city"))
	var map: Node2D = (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	root.add_child(map)
	var flags: RefCounted = (load("res://game/systems/story/story_flags.gd") as Script).new()
	if _args.has("flags"):
		for flag: String in String(_args["flags"]).split(","):
			flags.call(&"set_flag", StringName(flag))
	map.call(&"refresh_npcs", flags)
	var spawns: Node = map.get_node(^"Spawns")
	var cell: Vector2i = map.call(&"get_spawn_cell", StringName(spawns.get_child(0).name))
	if _args.has("cell"):
		var parts: PackedStringArray = String(_args["cell"]).split(",")
		cell = Vector2i(int(parts[0]), int(parts[1]))
	var facing := _direction(String(_args.get("facing", "down")))
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
	print("capture_vermilion : %s, vue %s, joueur %s" % [map_id, root.get_visible_rect().size,
		cell])


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
