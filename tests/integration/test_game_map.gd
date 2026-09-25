extends GutTest
## GameMap sur une mini-carte : cases solides/eau lues des tuiles, empreinte d'un
## prop 3×2, spawn, rectangle pixel. Empreintes de toutes les scènes de props (§4.3).

const MAP_SIZE := Vector2i(8, 6)
const PROPS_DIR := "res://game/world/props/"

var _map: GameMap


func before_each() -> void:
	_map = _make_mini_map()
	add_child_autofree(_map)


func _make_mini_map() -> GameMap:
	var tileset := load(OverworldTiles.TILESET_PATH) as TileSet
	var map := GameMap.new()
	map.name = "MiniMap"
	map.size = MAP_SIZE
	map.map_id = &"mini"
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	map.add_child(ground)
	var detail := TileMapLayer.new()
	detail.name = "Detail"
	detail.tile_set = tileset
	map.add_child(detail)
	var obstacles := TileMapLayer.new()
	obstacles.name = "Obstacles"
	obstacles.tile_set = tileset
	map.add_child(obstacles)
	for y: int in MAP_SIZE.y:
		for x: int in MAP_SIZE.x:
			_put(ground, Vector2i(x, y), OverworldTiles.Kind.GRASS, x + y)
	_put(ground, Vector2i(0, 0), OverworldTiles.Kind.FOREST, 0)
	_put(ground, Vector2i(1, 0), OverworldTiles.Kind.CROP, 1)
	_put(ground, Vector2i(0, 5), OverworldTiles.Kind.WATER, 2)
	_put(ground, Vector2i(1, 5), OverworldTiles.Kind.SHALLOW, 0)
	_put(ground, Vector2i(2, 5), OverworldTiles.Kind.BOARDWALK, 1)
	_put(detail, Vector2i(4, 1), OverworldTiles.Kind.FLOWERS, 0)
	_put(obstacles, Vector2i(7, 0), OverworldTiles.Kind.CLIFF, 1)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	var van := (load(PROPS_DIR + "van.tscn") as PackedScene).instantiate() as WorldProp
	van.position = Grid.cell_to_world(Vector2i(4, 4))
	entities.add_child(van)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	map.add_child(spawns)
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(Vector2i(2, 2))
	spawns.add_child(marker)
	return map


func _put(layer: TileMapLayer, cell: Vector2i, kind: OverworldTiles.Kind, variant: int) -> void:
	var coords := OverworldTiles.atlas_coords(kind, variant % OverworldTiles.variant_count(kind))
	layer.set_cell(cell, OverworldTiles.SOURCE_ID, coords)


func test_grid_marks_exactly_expected_cells() -> void:
	var grid := _map.get_grid()
	assert_eq(grid.get_size(), MAP_SIZE)
	var solid: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(7, 0)]
	for y: int in [3, 4]:
		for x: int in [3, 4, 5]:
			solid.append(Vector2i(x, y))
	var water: Array[Vector2i] = [Vector2i(0, 5), Vector2i(1, 5)]
	for y: int in MAP_SIZE.y:
		for x: int in MAP_SIZE.x:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_solid(cell), cell in solid, "solid %s" % cell)
			assert_eq(grid.is_water(cell), cell in water, "water %s" % cell)
			assert_eq(grid.get_ledge(cell), GridWorld.Ledge.NONE)


func test_spawn_cell_comes_from_marker() -> void:
	assert_eq(_map.get_spawn_cell(&"start"), Vector2i(2, 2))


func test_unknown_spawn_returns_invalid_cell() -> void:
	assert_eq(_map.get_spawn_cell(&"nowhere"), Vector2i(-1, -1))
	assert_push_error("spawn inconnu")


func test_pixel_rect_is_size_times_96() -> void:
	assert_eq(_map.get_pixel_rect(), Rect2i(0, 0, MAP_SIZE.x * 96, MAP_SIZE.y * 96))


func test_spawn_player_adds_to_entities_and_places_it() -> void:
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	_map.spawn_player(player, &"start", Vector2i.LEFT)
	assert_eq(player.get_parent(), _map.get_entities())
	assert_eq(player.get_cell(), Vector2i(2, 2))
	assert_eq(player.get_facing(), Vector2i.LEFT)
	assert_eq(player.position, Grid.cell_to_world(Vector2i(2, 2)))
	assert_eq(_map.get_grid().get_occupant(Vector2i(2, 2)), player)


# --- Empreintes des scènes de props (jalon 1 §4.3) -------------------------------

func _rect(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			cells.append(Vector2i(x, y))
	return cells


func _expected_footprints() -> Dictionary:
	var one: Array[Vector2i] = [Vector2i.ZERO]
	return {
		"house_player": _rect(-3, -4, 3, 0),
		"house_rival": _rect(-3, -4, 3, 0),
		"oak_lab": _rect(-6, -4, 6, 0),
		"plaza_tree": _rect(-2, -2, 2, 0),
		"tree_oak_a": one, "tree_oak_b": one, "tree_pine": one,
		"tree_birch": one, "tree_maple": one,
		"bush_a": one, "bush_b": one,
		"lamp_post": one,
		"bench": _rect(0, 0, 1, 0),
		"sign_pallet": one,
		"mailbox": one,
		"bicycle": one,
		"van": _rect(-1, -1, 1, 0),
		"greenhouse_large": _rect(-3, -1, 3, 0),
		"greenhouse_small": _rect(-1, -1, 1, 0),
		"vegetable_patch": _rect(-1, 0, 1, 0),
		"rock_small": one,
		"rock_large": _rect(0, 0, 1, 0),
		"brambles": one,
		"barrier_route21": _rect(0, -1, 0, 0),
	}


func _sorted(cells: Array[Vector2i]) -> Array[Vector2i]:
	var copy := cells.duplicate()
	copy.sort()
	return copy


func test_every_prop_scene_footprint_matches_plan() -> void:
	var expected := _expected_footprints()
	for prop_name: String in expected:
		var path := PROPS_DIR + prop_name + ".tscn"
		assert_true(ResourceLoader.exists(path), path)
		var prop := (load(path) as PackedScene).instantiate() as WorldProp
		assert_not_null(prop, "%s est un WorldProp" % path)
		if prop == null:
			continue
		assert_eq(_sorted(prop.get_footprint()), _sorted(expected[prop_name]), prop_name)
		var sprite := prop.get_node(^"Sprite") as Sprite2D
		assert_not_null(sprite.texture, "%s a une texture" % prop_name)
		prop.free()


func test_trees_have_at_least_four_variants() -> void:
	var trees := 0
	for file: String in DirAccess.get_files_at(PROPS_DIR):
		if file.begins_with("tree_") and file.ends_with(".tscn"):
			trees += 1
	assert_true(trees >= 4, "%d essences d'arbres" % trees)


func test_prop_sprite_bottom_center_sits_on_origin() -> void:
	# Le bas du sprite est sur l'origine, la case d'ancre est centrée sous l'origine.
	for prop_name: String in ["house_player", "oak_lab", "tree_oak_a", "bench", "van"]:
		var prop := (load(PROPS_DIR + prop_name + ".tscn") as PackedScene).instantiate()
		var sprite := prop.get_node(^"Sprite") as Sprite2D
		var rect := Rect2(sprite.offset, sprite.texture.get_size())
		assert_eq(rect.end.y, 0.0, prop_name)
		assert_eq(int(rect.position.x + Grid.HALF_TILE) % Grid.TILE_SIZE, 0, prop_name)
		prop.free()


func test_fence_footprint_follows_length_and_orientation() -> void:
	for style: String in ["fence_picket", "fence_wood"]:
		var scene := load(PROPS_DIR + style + ".tscn") as PackedScene
		var fence := scene.instantiate() as FenceProp
		assert_not_null(fence, style)
		fence.length = 3
		var horizontal: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
		assert_eq(fence.get_footprint(), horizontal)
		fence.vertical = true
		var vertical: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, -2)]
		assert_eq(fence.get_footprint(), vertical)
		add_child_autofree(fence)
		var sprite := fence.get_node(^"Sprite") as Sprite2D
		assert_eq(sprite.region_rect.size, Vector2(96, 288))
		assert_eq(sprite.offset, Vector2(-48, -288))


func test_prop_anchor_cell_from_position() -> void:
	var prop := (load(PROPS_DIR + "rock_small.tscn") as PackedScene).instantiate() as WorldProp
	prop.position = Grid.cell_to_world(Vector2i(6, 3))
	assert_eq(prop.get_anchor_cell(), Vector2i(6, 3))
	assert_eq(prop.get_solid_cells(), [Vector2i(6, 3)] as Array[Vector2i])
	prop.free()


func test_blocked_cells_are_solid_without_tile_or_prop() -> void:
	var map := _make_mini_map()
	map.blocked_cells = [Vector2i(5, 1)]
	add_child_autofree(map)
	var grid := map.rebuild_grid()
	assert_false(grid.can_enter(Vector2i(5, 1), Vector2i.UP))
	assert_true(grid.can_enter(Vector2i(5, 2), Vector2i.UP))
