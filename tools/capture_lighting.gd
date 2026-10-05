extends SceneTree
## Place de Jadielle du prototype (série 01, `proto_da_jadielle.gd`, lumière C2) reconstruite
## avec les **vrais composants** du jeu (docs/tech/jalon-07.md T3) : `GameMap`, sol peint
## (`PaintedGround` + `GroundMask`), décalcomanies (`BorderDecals`, même graine), objets
## peints (`game/world/props/painted/`), PNJ peints (`Npc` + `CharacterLook`), joueur peint,
## `WorldLighting` + `data/world/lighting.json`. Sert aux captures côte à côte prototype /
## production et aux mesures (fps, mémoire des textures).
##
##   godot --path . --write-movie build/cap/f.png --fixed-fps 60 --quit-after 6 \
##     -s res://tools/capture_lighting.gd [-- --profile=golden_hour|none --still]
##   godot --path . -s res://tools/capture_lighting.gd -- --perf=20
##
## 2340 × 1080 sur le Mac : `override.cfg` temporaire à la racine ([display]
## window/size/window_width_override=2340, window_height_override=1080), à retirer après.
##
## `--profile` : profil de `lighting.json` (défaut golden_hour ; « none » = profil vide).
## `--perf=<s>` : journal `[perf]` (PerfCounter, avec la mémoire des textures) pendant <s>
## secondes, sans synchronisation verticale, puis quitte.
## `--zoom=<z>` et `--aim=<x>,<y>` (cases) : détail à inspecter.
## `--still` : PNJ immobiles (sinon trois habitants marchent pour la mesure).

const CASE := 96
const SIZE := Vector2i(26, 14)
## Zones pavées du prototype, en cases.
const PAVING: Array[Rect2i] = [Rect2i(2, 5, 22, 8), Rect2i(12, 13, 2, 1)]
const SEED := 2026
const PROPS_DIR := "res://game/world/props/painted/"
## Pied de l'arbre central (le massif est posé par son trou de terre au même point).
const CENTRAL_FOOT := Vector2(13.0, 9.8)
## Objets du prototype : [identifiant, x, y du pied en cases]. Positions exactes du prototype
## (non alignées sur la grille : la carte de Jadielle les alignera, T4).
const PROPS: Array = [
	[&"bldg_centre_01", 7.0, 7.0], [&"bldg_boutique_01", 19.0, 7.0],
	[&"tree_central_01", 13.0, 9.8],
	[&"tree_b_01", 1.0, 5.0], [&"tree_a_01", 1.0, 9.0], [&"tree_b_01", 1.2, 13.6],
	[&"tree_a_01", 25.0, 5.5], [&"tree_b_01", 24.8, 9.6], [&"tree_a_01", 25.0, 13.8],
	[&"prop_banc_01", 9.4, 10.7], [&"prop_banc_01", 16.6, 10.7],
	[&"prop_lampadaire_01", 10.4, 8.6], [&"prop_lampadaire_01", 15.6, 8.6],
	[&"prop_lampadaire_01", 3.2, 7.6], [&"prop_lampadaire_01", 22.8, 7.6],
]
## Habitants (première case du circuit du prototype) : [id, sprite, case, orientation,
## cases de la routine (voisines) pour la mesure, vide = immobile].
const PEOPLE: Array = [
	[&"infirmiere", &"nurse", Vector2i(5, 7), Vector2i.DOWN, []],
	[&"marchand", &"clerk", Vector2i(17, 7), Vector2i.DOWN, []],
	[&"livreur", &"courier", Vector2i(20, 8), Vector2i.RIGHT,
		[Vector2i(20, 8), Vector2i(21, 8), Vector2i(22, 8), Vector2i(23, 8), Vector2i(22, 8),
			Vector2i(21, 8)]],
	[&"enfant", &"kid", Vector2i(17, 12), Vector2i.RIGHT, []],
	[&"rattata", &"pokemon/rattata", Vector2i(17, 11), Vector2i.DOWN, []],
	[&"dresseuse", &"lass", Vector2i(16, 11), Vector2i.DOWN, []],
	[&"roucool", &"pokemon/pidgey", Vector2i(15, 11), Vector2i.DOWN, []],
	[&"vieil_homme", &"old_man", Vector2i(9, 9), Vector2i.RIGHT,
		[Vector2i(9, 9), Vector2i(10, 9)]],
	[&"voyageur", &"traveler", Vector2i(13, 13), Vector2i.UP, []],
	[&"rival", &"rival", Vector2i(10, 12), Vector2i.RIGHT,
		[Vector2i(10, 12), Vector2i(11, 12), Vector2i(12, 12), Vector2i(11, 12)]],
]
const PLAYER_CELL := Vector2i(4, 8)

var _args: Dictionary = {}
var _perf_seconds: float = 0.0
var _elapsed: float = 0.0
var _counter: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	var map := _build_map()
	root.add_child(map)
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate()
	map.get_node(^"Entities").add_child(player)
	player.call(&"enter_map", map.call(&"get_grid"), PLAYER_CELL, Vector2i.DOWN,
		map.call(&"get_pixel_rect"))
	player.call(&"set_input_enabled", false)
	for person: Array in PEOPLE:
		var spec: Object = (load("res://game/world/npc/npc_spec.gd") as Script).new()
		spec.set(&"id", person[0])
		spec.set(&"sprite", person[1])
		spec.set(&"cell", person[2])
		spec.set(&"facing", person[3])
		if not _args.has("still") and not (person[4] as Array).is_empty():
			var cells: Array[Vector2i] = []
			cells.assign(person[4])
			spec.set(&"route_cells", cells)
			spec.set(&"route_pause", 0.4)
		map.call(&"add_npc", spec)
	var camera := Camera2D.new()
	camera.position = Vector2(SIZE.x / 2.0, 7.3) * CASE
	if _args.has("zoom"):
		var zoom := float(_args["zoom"])
		camera.zoom = Vector2(zoom, zoom)
	if _args.has("aim"):
		var aim: PackedStringArray = String(_args["aim"]).split(",")
		camera.position = Vector2(float(aim[0]), float(aim[1])) * CASE
	root.add_child(camera)
	camera.make_current()
	var lighting: CanvasLayer = (load("res://game/world/lighting/world_lighting.gd")
		as Script).new()
	root.add_child(lighting)
	var profile_id := StringName(_args.get("profile", "golden_hour"))
	var profile: Object = null
	if profile_id != &"none":
		var library: Object = (load("res://game/world/lighting/lighting_library.gd")
			as Script).new()
		library.call(&"load_file")
		profile = library.call(&"get_profile", profile_id)
	lighting.call(&"apply", profile, map)
	print("capture_lighting : profil %s, vue %s, mémoire des textures %.1f Mo" % [
		profile_id, root.get_visible_rect().size,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
	if _args.has("perf"):
		_perf_seconds = float(_args["perf"])
		# Sans synchronisation verticale : la marge réelle (sinon plafonnée à l'écran).
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		_counter = (load("res://game/systems/debug/perf_counter.gd") as Script).new()
		root.add_child(_counter)
		process_frame.connect(_on_perf_frame)


func _on_perf_frame() -> void:
	_elapsed += get_root().get_process_delta_time()
	if _elapsed >= _perf_seconds:
		quit()


func _build_map() -> Node2D:
	var map: Node2D = (load("res://game/world/map.gd") as Script).new()
	map.name = "PlaceJadielle"
	map.set(&"size", SIZE)
	var paving := {}
	for zone: Rect2i in PAVING:
		for x in range(zone.position.x, zone.end.x):
			for y in range(zone.position.y, zone.end.y):
				paving[Vector2i(x, y)] = true
	var ground_script := load("res://game/world/ground/painted_ground.gd") as Script
	var ground: Node2D = ground_script.new()
	ground.name = "PaintedGround"
	ground.set(&"size", SIZE)
	var mask_script := load("res://game/world/ground/ground_mask.gd") as Script
	var mask: Image = mask_script.call(&"build", SIZE, paving)
	ground.set(&"mask", ImageTexture.create_from_image(mask))
	map.add_child(ground)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = -1
	map.add_child(decals)
	var border := load("res://game/world/ground/border_decals.gd") as Script
	border.call(&"place", border.call(&"plan", paving, SIZE, SEED), decals)
	var massif := _prop(&"prop_massif_01", CENTRAL_FOOT)
	decals.add_child(massif)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	for entry: Array in PROPS:
		entities.add_child(_prop(entry[0], Vector2(entry[1], entry[2])))
	return map


func _prop(id: StringName, foot_cells: Vector2) -> Node2D:
	var prop := (load(PROPS_DIR + String(id) + ".tscn") as PackedScene).instantiate() as Node2D
	prop.position = foot_cells * CASE
	return prop
