extends SceneTree
## Construit game/world/maps/route_22.tscn (Route 22, 46 × 27 cases, lumière golden_hour) d'après
## le plan du prototype (proto_route22.gd, 46 × 20) et le dossier 09 §12–§13.
##
##   godot --headless --path . -s res://tools/build_route_22.gd
##   godot --headless --path . --import
##   (première fois : relancer l'outil après l'import, il lit le masque de sol importé)
##
## Plan (les coordonnées du prototype sont décalées de [constant OY] rangées : le fond peint du
## Plateau Indigo occupe le haut de la carte, que le prototype laissait « hors carte ») :
## - chemin de terre à l'est (sortie vers Jadielle, warps PUSH vers la droite) qui file vers
##   l'ouest ; colonne 0 solide, la route s'arrête dans l'herbe ; **jalon 29** : trois warps PUSH
##   vers la gauche en (1, 16..18) mènent à la partie ouest (`route_22_west`, rival n° 7, poste de
##   la Ligue) — aucune autre case ne change (grille relevée : `tools/plans/route_22.txt`) ;
## - falaise basse **continue** (relief peint de la couche du sol, emprise = la rangée de la face)
##   dont l'escalier est la **seule** case libre : il mène au niveau supérieur, un sentier
##   vers le point de vue sur le Plateau Indigo (le futur rival n° 2, T25, s'y tient) ;
## - trois champs de hautes herbes peintes (deux touffes par case) branchés sur la table
##   `route_22` ; clairières sans arbres autour d'eux ;
## - forêt : arbres peints dont la cime masque le bord ; rochers ;
## - voyageur et Pokémon d'ambiance dans data/npcs/route_22.json ;
## - scène du rival n° 2 (T25) : déclencheur `RivalVista` en haut de l'escalier (pas vers l'ouest
##   sur les deux rangées du sentier), rival et jeune Dresseur face à face sur (6..9, 13), dans
##   data/npcs/route_22.json (présents après l'activation du Pokédex, avant le combat).
## Le TileMapLayer `Ground` est la source logique (solide, hautes herbes), invisible ; l'image
## vient du sol peint (masque G = chemin de terre), des décalcomanies et des objets peints.

const OUT_PATH: String = "res://game/world/maps/route_22.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_22_ground.png"
const PROPS: String = "res://game/world/props/painted/"
const BACKDROP: String = "res://assets/world/backdrops/backdrop_plateau_indigo_01.png"
const FADE_SHADER: String = "res://game/world/ground/backdrop_fade.gdshader"
const WIND_MATERIAL: String = "res://game/world/lighting/materials/world_object_wind.tres"
const SEED: int = 22
## Rognure du fond peint (pixels de l'image, hauteur) et rangée de son bord haut.
const BACKDROP_CROP: float = 700.0
const BACKDROP_TOP: float = 3.5
const WIDTH: int = 46
## Rangées ajoutées au-dessus du plan du prototype (fond peint et forêt du nord).
const OY: int = 7
const HEIGHT: int = 20 + OY
const SIZE := Vector2i(WIDTH, HEIGHT)
const TILE: int = 96

## Bords bloqués : colonne 0 (aucun passage vers l'ouest) et colonne 45 (la poussée vers l'est
## déclenche le warp, comme le sud de la Route 1).
const EAST_EDGE: int = 45
## Warps PUSH vers Jadielle : une case par rangée du chemin (3 de large).
const ROAD_ROWS: Array[int] = [17, 18, 19]
const EAST_CELL: int = 44
const WARP_TARGET: StringName = &"viridian_city"
const WARP_SPAWN: StringName = &"from_route_22"
const PUSH: int = 1
## Jalon 29 : warps PUSH vers l'ouest (`route_22_west`, spawn `from_route_22`), sur l'herbe rase
## libre du bord ouest (la colonne 0 reste solide : on pousse contre le bord, comme à l'est).
const WEST_ROWS: Array[int] = [16, 17, 18]
const WEST_CELL: int = 1
const WEST_TARGET: StringName = &"route_22_west"
const WEST_SPAWN: StringName = &"from_route_22"

## Points d'apparition (Marker2D enfants de `Spawns`). `from_viridian` : bord est ;
## `vista` : le sentier du point de vue (débogage, captures) ; `stair_foot` : pied de l'escalier
## (départ de débogage `rival_2_weak`, T25 : quelques pas jusqu'à la scène du rival).
const SPAWNS: Dictionary = {
	"from_viridian": Vector2i(44, 18),
	"vista": Vector2i(11, 13),
	"stair_foot": Vector2i(16, 16),
}
## Jalon 29 : arrivée depuis la partie ouest (tourné vers l'est). Hors de [constant SPAWNS] : le
## plan des arbres (qui laisse libres les abords des points d'apparition) ne change pas.
const WEST_ARRIVAL_SPAWN := "from_route_22_west"
const WEST_ARRIVAL := Vector2i(1, 17)
## Déclencheurs de scène [nom, ancre (bas-gauche), taille, direction du pas, scène] : en haut de
## l'escalier, le premier pas vers l'ouest sur le sentier (rangées 12 et 13) lance la scène du
## rival n° 2 (ses variantes décident : Pokédex activé, pas encore affronté).
const TRIGGERS: Array = [
	["RivalVista", Vector2i(14, 13), Vector2i(1, 2), Vector2i.LEFT, &"rival_route22"],
]

## Rectangles [x, y, largeur, hauteur] du prototype (décalés de OY au dessin).
const WALKABLE_LOWER := Rect2i(1, 8, 44, 10)
const WALKABLE_UPPER := Rect2i(1, 5, 16, 2)
const WALKABLE_POCKET := Rect2i(30, 1, 15, 7)
const ROAD := Rect2i(14, 10, 31, 3)
const STAIR_FOOT := Rect2i(15, 8, 2, 2)
const STAIR_GAP := Rect2i(15, 7, 2, 1)
const UPPER_PATH := Rect2i(2, 5, 15, 2)
const FIELDS: Array[Rect2i] = [Rect2i(20, 13, 8, 4), Rect2i(32, 3, 7, 4), Rect2i(5, 13, 6, 4)]
## Sans arbres : abords de la falaise (prototype `DEGAGES`, hors le point de vue).
const CLEAR: Array[Rect2] = [Rect2(0, 7, 18, 3), Rect2(17, 7, 13, 2)]

## Falaise continue : [x du pied (bord de case), y du pied] (prototype, y décalé de OY).
const CLIFFS_UPPER: Array[float] = [2.0, 6.0, 10.0, 14.0]
const CLIFFS_UPPER_Y: float = 4.2
const CLIFFS_LOWER: Array[float] = [2.0, 6.0, 10.0, 13.0, 19.0, 23.0, 27.0]
const CLIFFS_LOWER_Y: float = 8.0
const STAIR_FOOT_POS := Vector2(16.0, 8.4)
## Rochers [x, y du pied] du prototype.
const ROCKS: Array[Vector2] = [Vector2(30.0, 14.4), Vector2(41.0, 7.6), Vector2(12.6, 16.8)]

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}
var _kinds: Array = []
var _path_cells: Dictionary = {}
var _tree_cells: Array[Vector2i] = []
var _keep_free: Array[Vector2i] = []


func _init() -> void:
	_tiles = load("res://game/world/overworld_tiles.gd")
	_rng.seed = SEED
	var root := Node2D.new()
	root.name = "Route22"
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", &"route_22")
	root.set(&"display_name", "Route 22")
	root.set(&"region", "Jadielle — Plateau Indigo")
	root.set(&"size", SIZE)
	root.set(&"light_profile", &"golden_hour")
	root.set(&"blocked_cells", _blocked_cells())

	_plan_ground()
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	# Source logique seulement : l'image est le sol peint.
	ground.visible = false
	detail.visible = false
	obstacles.visible = false
	_paint_ground(ground)

	var mask_texture := _write_mask()
	if mask_texture == null:
		print("build_route_22 : masque écrit ; importer (--import) puis relancer l'outil")
		root.free()
		quit(2)
		return
	var painted := Node2D.new()
	painted.set_script(load("res://game/world/ground/painted_ground.gd"))
	painted.name = "PaintedGround"
	painted.set(&"size", SIZE)
	painted.set(&"mask", mask_texture)
	_attach(root, root, painted)
	_add_backdrop(root)

	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = -1
	_attach(root, root, decals)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	_add_spawns(root)
	_add_warps(root)
	_add_triggers(root)

	_place_border_decals(root, decals)
	_place_relief(root, decals)
	_place_rocks(root, entities)
	_place_trees(root, entities)
	_place_tall_grass(root, entities)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_PATH)
	print("route_22 : %s (%d entités, %d arbres)" % [
		error_string(err), entities.get_child_count(), _tree_cells.size()])
	root.free()
	quit()


# --- Plan logique -----------------------------------------------------------------------


## Décalage d'un rectangle du prototype (rangées de OY en plus).
func _r(rect: Rect2i) -> Rect2i:
	return Rect2i(rect.position + Vector2i(0, OY), rect.size)


func _blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in HEIGHT:
		cells.append(Vector2i(0, y))
		cells.append(Vector2i(EAST_EDGE, y))
	return cells


func _plan_ground() -> void:
	_kinds.resize(SIZE.x * SIZE.y)
	_kinds.fill(_tiles.Kind["FOREST"])
	for rect: Rect2i in [WALKABLE_LOWER, WALKABLE_UPPER, WALKABLE_POCKET]:
		_fill(_r(rect), "GRASS")
	# Le chemin de terre (aussi le masque G du sol peint) : la route, le pied de l'escalier, le
	# passage de la falaise, le sentier du niveau supérieur.
	for rect: Rect2i in [ROAD, STAIR_FOOT, STAIR_GAP, UPPER_PATH]:
		_fill(_r(rect), "DIRT")
		for y: int in range(_r(rect).position.y, _r(rect).end.y):
			for x: int in range(rect.position.x, rect.end.x):
				_path_cells[Vector2i(x, y)] = true
	# Le chemin file jusqu'au bord est de l'image (colonne 45, solide : poussée = warp).
	for y: int in ROAD_ROWS:
		_path_cells[Vector2i(EAST_EDGE, y)] = true
	for rect: Rect2i in FIELDS:
		_fill(_r(rect), "TALL_GRASS")
	# Colonne 0 : toujours de la forêt (aucun passage vers l'ouest).
	for y: int in HEIGHT:
		_kinds[y * SIZE.x] = _tiles.Kind["FOREST"]
		_kinds[y * SIZE.x + EAST_EDGE] = _tiles.Kind["FOREST"]
	for spawn: Vector2i in SPAWNS.values():
		_keep_free.append(spawn)
	for y: int in ROAD_ROWS:
		_keep_free.append(Vector2i(EAST_CELL, y))
	# Cases des habitants (data/npcs/route_22.json) : pas d'arbre dessus ni à côté.
	var roster: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/route_22.json"))
	for key: String in roster:
		var entry: Dictionary = roster[key]
		_keep_free.append(Vector2i(int(entry["cell"][0]), int(entry["cell"][1])))
		if entry.has("route"):
			for cell: Array in entry["route"]["cells"]:
				_keep_free.append(Vector2i(int(cell[0]), int(cell[1])))


func _fill(rect: Rect2i, kind_name: String) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_kinds[y * SIZE.x + x] = _tiles.Kind[kind_name]


func _kind_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= SIZE.x or cell.y >= SIZE.y:
		return _tiles.Kind["FOREST"]
	return _kinds[cell.y * SIZE.x + cell.x]


func _paint_ground(layer: TileMapLayer) -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var kind: int = _kinds[y * SIZE.x + x]
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


## Masque du sol peint (G = chemin de terre), écrit dans assets/world/maps/. Null tant que
## l'image n'est pas importée.
func _write_mask() -> Texture2D:
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	var image: Image = script.call(&"build", SIZE, [], _path_cells)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MASK_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(MASK_PATH))
	if not ResourceLoader.exists(MASK_PATH):
		return null
	return load(MASK_PATH) as Texture2D


# --- Scène ------------------------------------------------------------------------------


func _add_spawns(root: Node) -> void:
	for spawn_name: String in SPAWNS:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(SPAWNS[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)
	var west := Marker2D.new()
	west.name = WEST_ARRIVAL_SPAWN
	west.position = _world(WEST_ARRIVAL)
	_attach(root, root.get_node(^"Spawns"), west)


func _add_triggers(root: Node) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in TRIGGERS:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"cutscene_id", entry[4])
		_attach(root, root.get_node(^"Triggers"), point)


func _add_warps(root: Node) -> void:
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	var number := 0
	for y: int in ROAD_ROWS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "ViridianEast%d" % number
		number += 1
		point.position = _world(Vector2i(EAST_CELL, y))
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.RIGHT)
		point.set(&"target_map", WARP_TARGET)
		point.set(&"target_spawn", WARP_SPAWN)
		point.set(&"arrival_facing", Vector2i.RIGHT)
		_attach(root, root.get_node(^"Warps"), point)
	number = 0
	for y: int in WEST_ROWS:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = "RouteWest%d" % number
		number += 1
		point.position = _world(Vector2i(WEST_CELL, y))
		point.set(&"trigger", PUSH)
		point.set(&"direction", Vector2i.LEFT)
		point.set(&"target_map", WEST_TARGET)
		point.set(&"target_spawn", WEST_SPAWN)
		point.set(&"arrival_facing", Vector2i.LEFT)
		_attach(root, root.get_node(^"Warps"), point)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer


## Fond peint du Plateau Indigo, rogné (ciel, mesa, lac) et posé pour que le point de vue du
## niveau supérieur le voie en entier : mesa vers les rangées 6 à 8, lac au-dessus de la falaise, bas fondu dans l'herbe juste
## au-dessus de la falaise haute (rangée 11). Les rangées au-dessus, jamais visibles depuis un
## endroit praticable (la caméra suit le joueur), restent de l'herbe. Bords droit et bas fondus.
func _add_backdrop(root: Node) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "BackdropPlateau"
	sprite.texture = load(BACKDROP)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 1536, BACKDROP_CROP)
	sprite.position = Vector2(-0.5, BACKDROP_TOP) * TILE
	sprite.scale = Vector2(1.13, 1.0)
	sprite.z_index = -3
	var material := ShaderMaterial.new()
	material.shader = load(FADE_SHADER)
	material.set_shader_parameter(&"region", Vector4(0.0, 0.0, 1.0, BACKDROP_CROP / 1024.0))
	sprite.material = material
	_attach(root, root, sprite)


func _scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PROPS + id + ".tscn")
	return _scenes[id]


func _add_prop(root: Node, parent: Node, id: String, foot: Vector2, node_name: String) -> Node2D:
	var prop := _scene(id).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = (foot * TILE).round()
	_attach(root, parent, prop)
	return prop


## Décalcomanies du bord du chemin (terre et touffes ; pas de pavés sur une route de terre).
func _place_border_decals(root: Node, decals: Node2D) -> void:
	var script := load("res://game/world/ground/border_decals.gd") as GDScript
	var plan: Array = script.call(&"plan", _path_cells, SIZE, SEED)
	var kept: Array[Dictionary] = []
	for decal: Dictionary in plan:
		if not String(decal["texture"]).contains("decal_pave"):
			kept.append(decal)
	script.call(&"place", kept, decals, root)


## Falaise continue et escalier : relief peint de la couche du sol. L'escalier d'abord (les
## falaises le recouvrent un peu sur les côtés, comme au prototype).
func _place_relief(root: Node, decals: Node2D) -> void:
	var stair := _add_prop(root, decals, "relief_escalier_01",
		STAIR_FOOT_POS + Vector2(0, OY), "Stair")
	stair.name = "Stair"
	var index := 0
	for x: float in CLIFFS_UPPER:
		_add_prop(root, decals, "relief_falaise_01", Vector2(x, CLIFFS_UPPER_Y + OY),
			"CliffUpper%02d" % index)
		index += 1
	index = 0
	for x: float in CLIFFS_LOWER:
		_add_prop(root, decals, "relief_falaise_01", Vector2(x, CLIFFS_LOWER_Y + OY),
			"CliffLower%02d" % index)
		index += 1


func _place_rocks(root: Node, entities: Node2D) -> void:
	var index := 0
	for rock: Vector2 in ROCKS:
		_add_prop(root, entities, "prop_rocher_01", rock + Vector2(0, OY), "Rock%02d" % index)
		index += 1


## Deux touffes par case de haute herbe, décalées et de tailles variées (prototype) : pas de
## rangées visibles. Les touffes ne sont pas solides ; la donnée `tall_grass` est dans Ground.
func _place_tall_grass(root: Node, entities: Node2D) -> void:
	var wind: Material = load(WIND_MATERIAL)
	var index := 0
	for field: Rect2i in FIELDS:
		var rect := _r(field)
		for x: int in range(rect.position.x, rect.end.x):
			for y: int in range(rect.position.y, rect.end.y):
				for k: int in 2:
					var foot := Vector2(x, y) + Vector2(_rng.randf_range(0.25, 0.75),
						0.55 + 0.45 * k)
					var tuft := _add_prop(root, entities, "ground_hautes_herbes_01", foot,
						"Tuft%03d" % index)
					index += 1
					var scale := _rng.randf_range(1.0, 1.3)
					tuft.scale = Vector2(scale, scale)
					var sprite := tuft.get_node(^"Sprite")
					sprite.set(&"material", wind)
					sprite.set(&"flip_h", _rng.randf() < 0.5)


# --- Forêt ------------------------------------------------------------------------------


func _is_walkable_kind(kind: int) -> bool:
	return kind != _tiles.Kind["FOREST"]


func _near_kind(cell: Vector2i, kinds: Array[String], radius: int) -> bool:
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			for kind_name: String in kinds:
				if _kind_at(cell + Vector2i(dx, dy)) == _tiles.Kind[kind_name]:
					return true
	return false


func _clear_zone(p: Vector2) -> bool:
	for zone: Rect2 in CLEAR:
		if Rect2(zone.position + Vector2(0, OY), zone.size).grow(1.0).has_point(p):
			return true
	# Clairière autour des champs : plus large au sud, où des arbres hauts de 4 à 5 cases
	# cacheraient le champ.
	for field: Rect2i in FIELDS:
		var rect := Rect2(_r(field))
		if Rect2(rect.position - Vector2(2, 2), rect.size + Vector2(4, 7)).has_point(p):
			return true
	return false


func _near_free(cell: Vector2i) -> bool:
	for keep: Vector2i in _keep_free:
		if absi(keep.x - cell.x) <= 1 and absi(keep.y - cell.y) <= 1:
			return true
	return false


## Arbres : sur l'herbe rase (loin du chemin, des herbes, des clairières), puis forêt dense
## sur les cases solides. Un arbre a une emprise d'une case (déjà solide en forêt).
func _place_trees(root: Node, entities: Node2D) -> void:
	var poses: Array[Vector2] = []
	var grass: int = _tiles.Kind["GRASS"]
	var forest: int = _tiles.Kind["FOREST"]
	# 1. Herbe rase.
	for attempt: int in 2200:
		var p := Vector2(_rng.randf_range(0.5, WIDTH - 0.5), _rng.randf_range(0.5, HEIGHT - 0.2))
		var cell := Vector2i(p)
		if _kind_at(cell) != grass or _near_free(cell) or _clear_zone(p) \
				or _near_kind(cell, ["DIRT", "TALL_GRASS"], 1) or _too_close(poses, p, 2.1):
			continue
		poses.append(p)
		_tree(root, entities, p)
	# 2. Forêt dense sur les cases solides, hors point de vue et falaise, à bonne distance
	# des cases praticables (la cime déborde de 1,4 case).
	for attempt: int in 6000:
		var p := Vector2(_rng.randf_range(0.5, WIDTH - 0.5), _rng.randf_range(0.5, HEIGHT - 0.2))
		var cell := Vector2i(p)
		if _kind_at(cell) != forest:
			continue
		# Sans arbre : le niveau supérieur et son fond peint (en haut à gauche) et la rangée
		# de la falaise (les arbres y marcheraient sur le relief).
		if p.x < 16.0 and p.y < 14.0 or p.x < 29.0 and cell.y == OY + 7:
			continue
		if _walkable_near(p, 1.5) or _too_close(poses, p, 1.55):
			continue
		poses.append(p)
		_tree(root, entities, p)


func _too_close(poses: Array[Vector2], p: Vector2, distance: float) -> bool:
	for other: Vector2 in poses:
		if other.distance_to(p) < distance:
			return true
	return false


## Vrai si une case praticable est à moins de [param radius] cases du point.
func _walkable_near(p: Vector2, radius: float) -> bool:
	var reach := ceili(radius)
	var cell := Vector2i(p)
	for dx: int in range(-reach, reach + 1):
		for dy: int in range(-reach, reach + 1):
			var other := cell + Vector2i(dx, dy)
			if _is_walkable_kind(_kind_at(other)) and other.x > 0 and other.x < EAST_EDGE:
				var center := Vector2(other) + Vector2(0.5, 0.5)
				if center.distance_to(p) < radius + 0.5:
					return true
	return false


func _tree(root: Node, entities: Node2D, p: Vector2) -> void:
	var id := "tree_b_01" if _rng.randf() < 0.6 else "tree_a_01"
	_add_prop(root, entities, id, p, "Tree%03d" % _tree_cells.size())
	_tree_cells.append(Vector2i(p))
