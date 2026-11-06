extends RefCounted
## Neige du Mont Argenté (JOH9), appelée par `tools/build_joh_ambiance.gd` sur les cartes à clé
## « snow » : image seule, aucune emprise (les cases sont celles de la grille, tout est `Sprite2D`
## ou objet à emprise retirée). Art : `tools/art/joh9_argente.py`.
## Clés : « row » (au-dessus de cette rangée, forêt, herbes et repères sont sous la neige),
## « paved » (la neige est le canal des pavés), « base » (la neige est le sol de base),
## « south_tree » (arbre repère sous « row »), « plants » (plantes dans la neige), « ice »
## (rectangles de muraille de glace), « blocks » (blocs de roche sur `R`, pierres sur `K`),
## « rim » (rangée `R` du bord sud en blocs bas : la paroi s'y arrête), « cloud_row » (mer de nuages à partir de cette rangée et tout autour de la carte).

const SNOW: String = "res://assets/world/ground/ground_neige_01.png"
const CLOUDS: String = "res://assets/world/ground/ground_nuages_01.png"
const CLOUD_EDGE: String = "res://assets/world/ground/ground_nuages_bord_01.png"
const GRASS: String = "res://assets/world/ground/ground_hautes_herbes_neige_01.png"
const ICE: String = "res://assets/world/props/prop_muraille_glace_01.png"
const PROP_MATERIAL: String = "res://game/world/lighting/materials/world_object.tres"
const PLANT: String = "res://assets/world/ground/decals/decal_plante_neige_%d.png"
const PLANTS: int = 6
const TILE: int = 96
## Blocs du sommet : hauts sur les falaises `R`, bas sur les pierres `K`.
const TALL_BLOCKS: Array[String] = ["prop_bloc_neige_01", "prop_bloc_neige_02", "prop_bloc_neige_03"]
const LOW_BLOCKS: Array[String] = ["prop_bloc_neige_04", "prop_bloc_neige_05", "prop_bloc_neige_06"]
const ROCKS: Array[String] = ["prop_rocher_neige_01", "prop_rocher_neige_02"]
const SNOW_TREE: String = "tree_sapin_neige_01"
## Marge de nuages autour de la carte (cases) : la caméra peut montrer plus large que le sommet.
const CLOUD_MARGIN: int = 16


## Textures du sol peint.
static func ground(painted: Node2D, spec: Dictionary) -> void:
	var snow: Dictionary = spec.get("snow", {})
	if snow.get("paved", false):
		painted.set(&"r_texture", load(SNOW))
	if snow.get("base", false):
		painted.set(&"base_texture", load(SNOW))
		painted.set(&"r_texture", load(SNOW))


## Habille la carte une fois la forêt posée.
static func dress(kit: Object, source: Object, decals: Node2D, entities: Node2D,
		spec: Dictionary) -> void:
	var snow: Dictionary = spec["snow"]
	var limit: float = float(snow["row"]) * TILE
	_cover(entities, limit)
	_rocks(kit, entities)
	if snow.has("south_tree"):
		_south_trees(kit, entities, limit, snow["south_tree"])
	_plants(kit, source, decals, int(snow.get("plants", 0)), limit)
	for rect: Rect2i in snow.get("ice", []):
		_ice_wall(kit, entities, rect)
	if snow.get("blocks", false):
		_blocks(kit, source, entities)
	if snow.has("rim"):
		_rim(kit, source, entities, snow["rim"])


## Mer de nuages derrière la carte (toute la vue) et sur les cases de « cloud_row ».
static func clouds(root: Node, spec: Dictionary) -> void:
	var snow: Dictionary = spec.get("snow", {})
	if not snow.has("cloud_row"):
		return
	for old_name: String in ["JohAmbNuages", "JohAmbNuagesBord"]:
		var old := root.get_node_or_null(NodePath(old_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var map_size: Vector2i = (root.get_node(^"PaintedGround") as Node2D).get(&"size")
	var sea := Sprite2D.new()
	sea.name = "JohAmbNuages"
	sea.texture = load(CLOUDS)
	sea.centered = false
	sea.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sea.region_enabled = true
	var outer := map_size + Vector2i.ONE * CLOUD_MARGIN * 2
	sea.region_rect = Rect2(Vector2.ZERO, Vector2(outer * TILE))
	sea.position = -Vector2.ONE * CLOUD_MARGIN * TILE
	sea.z_index = -20
	sea.z_as_relative = false
	root.add_child(sea)
	sea.owner = root
	root.move_child(sea, 0)
	var edge := Sprite2D.new()
	edge.name = "JohAmbNuagesBord"
	edge.texture = load(CLOUD_EDGE)
	edge.centered = false
	edge.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	edge.region_enabled = true
	var row: int = snow["cloud_row"]
	# Une case de plus de chaque côté : les blocs débordent un peu de la carte.
	edge.region_rect = Rect2(0, 0, (map_size.x + 2) * TILE, edge.texture.get_height())
	edge.position = Vector2(-TILE, (row + 1) * TILE - edge.texture.get_height())
	root.add_child(edge)
	edge.owner = root
	root.move_child(edge, root.get_node(^"Entities").get_index() + 1)


## Forêt, buissons et hautes herbes au-dessus de [param limit] : leur version sous la neige.
static func _cover(entities: Node2D, limit: float) -> void:
	for child: Node in entities.get_children():
		if not child is Sprite2D or (child as Node2D).position.y >= limit:
			continue
		var sprite := child as Sprite2D
		var id := sprite.texture.resource_path.get_file().get_basename()
		if id.begins_with("tree_foret_"):
			sprite.texture = load("res://assets/world/props/%s_neige.png" % id)
		elif id.begins_with("prop_buisson_"):
			sprite.texture = load("res://assets/world/props/%s_neige.png" % id)
		elif String(child.name).begins_with("Tuft"):
			sprite.texture = load(GRASS)


## Rochers `o` : coiffés de neige.
static func _rocks(kit: Object, entities: Node2D) -> void:
	var index := 0
	for child: Node in entities.get_children():
		if not String(child.name).begins_with("SeaRock"):
			continue
		var foot := (child as Node2D).position
		entities.remove_child(child)
		child.free()
		var rock: Node2D = kit.call(&"add_prop", entities, ROCKS[index % ROCKS.size()], foot,
			"SnowRock%02d" % index)
		kit.call(&"clear_footprint", rock)
		index += 1


## Arbres repères sous la neige au nord, arbre de [param id] au sud.
static func _south_trees(kit: Object, entities: Node2D, limit: float, id: String) -> void:
	for child: Node in entities.get_children():
		var name := String(child.name)
		if not name.begins_with("Tree") or (child as Node2D).position.y < limit:
			continue
		var foot := (child as Node2D).position
		entities.remove_child(child)
		child.free()
		var tree: Node2D = kit.call(&"add_prop", entities, id, foot, name)
		kit.call(&"clear_footprint", tree)


## Plantes de montagne sur la neige (cases praticables hors chemin, au-dessus de [param limit]).
static func _plants(kit: Object, source: Object, decals: Node2D, wanted: int, limit: float) -> void:
	var cells: Array[Vector2i] = source.cells_of("n")
	if cells.is_empty() or wanted == 0:
		return
	var rng: RandomNumberGenerator = kit.get(&"decor_rng")
	for index: int in wanted:
		var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		if float(cell.y) * TILE >= limit:
			continue
		var at := Vector2(cell) + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8))
		kit.call(&"decal", decals, PLANT % rng.randi_range(1, PLANTS), at * TILE, 1.0)


## Muraille de glace sur [param rect] : un sprite répété, trié par ses pieds (bas de la rangée).
static func _ice_wall(kit: Object, entities: Node2D, rect: Rect2i) -> void:
	var wall := Sprite2D.new()
	wall.name = "Muraille%02d" % rect.position.x
	wall.texture = load(ICE)
	wall.material = load(PROP_MATERIAL)
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.region_enabled = true
	var height: float = wall.texture.get_height()
	wall.region_rect = Rect2(0, 0, rect.size.x * TILE, height)
	wall.centered = false
	wall.offset = Vector2(0, -height)
	wall.position = Vector2(rect.position.x * TILE, (rect.position.y + 1) * TILE)
	kit.call(&"attach", entities, wall)


## Sommet : falaise `R` et pierres `K` en blocs (pieds au bas de chaque case).
static func _blocks(kit: Object, source: Object, entities: Node2D) -> void:
	var index := 0
	for mark: String in ["R", "K"]:
		var ids: Array[String] = TALL_BLOCKS if mark == "R" else LOW_BLOCKS
		for cell: Vector2i in source.cells_of(mark):
			var block: Sprite2D = kit.call(&"add_sprite", entities, ids[index % ids.size()],
				(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Bloc%03d" % index)
			block.flip_h = index % 2 == 1
			index += 1


## Rangée [param row] de la bordure `R` : blocs bas (la paroi en modules ne descend pas jusque-là).
static func _rim(kit: Object, source: Object, entities: Node2D, row: int) -> void:
	var index := 0
	for cell: Vector2i in source.cells_of("R"):
		if cell.y != row:
			continue
		var block: Sprite2D = kit.call(&"add_sprite", entities, TALL_BLOCKS[index % TALL_BLOCKS.size()],
			(Vector2(cell) + Vector2(0.5, 1.0)) * TILE, "Rim%03d" % index)
		block.flip_h = index % 2 == 1
		index += 1
