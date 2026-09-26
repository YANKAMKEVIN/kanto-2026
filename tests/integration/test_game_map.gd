extends GutTest
## GameMap sur une mini-carte : cases solides/eau lues des tuiles, empreinte d'un
## prop 3×2, spawn, rectangle pixel, warps (jalon 2 §2.3). Empreintes de toutes les
## scènes de props (§4.3 ; portes ouvertes, jalon 2 §4.2) et du mobilier d'intérieur
## (jalon 2 §4.1, §4.3, §4.4). Cadrage caméra d'une pièce 10×8 (jalon 2 §2.7).
## PNJ créés depuis les données et points d'examen (jalon 3A §2.2, §2.3).

const MAP_SIZE := Vector2i(8, 6)
const PROPS_DIR := "res://game/world/props/"
const INTERIOR_DIR := "res://game/world/props/interior/"
const PLAYER_SCENE := "res://game/player/player.tscn"
const DOOR_CELL := Vector2i(2, 1)
const MAT_CELL := Vector2i(6, 5)

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
	var warps := Node2D.new()
	warps.name = "Warps"
	map.add_child(warps)
	warps.add_child(_warp_point(&"Door", DOOR_CELL, Warp.Trigger.STEP_ON, Vector2i.UP))
	warps.add_child(_warp_point(&"Mat", MAT_CELL, Warp.Trigger.PUSH, Vector2i.DOWN))
	return map


func _warp_point(
	node_name: StringName, cell: Vector2i, trigger: Warp.Trigger, direction: Vector2i
) -> WarpPoint:
	var point := WarpPoint.new()
	point.name = node_name
	point.position = Grid.cell_to_world(cell)
	point.trigger = trigger
	point.direction = direction
	point.target_map = &"elsewhere"
	point.target_spawn = &"entrance"
	return point


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
		# Case de porte (ancre) praticable : jalon 2 §4.2.
		"house_player": _without_door(_rect(-3, -4, 3, 0)),
		"house_rival": _without_door(_rect(-3, -4, 3, 0)),
		"oak_lab": _without_door(_rect(-6, -4, 6, 0)),
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


func _without_door(cells: Array[Vector2i]) -> Array[Vector2i]:
	cells.erase(Vector2i.ZERO)
	return cells


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


func test_building_door_cell_is_not_in_footprint() -> void:
	for prop_name: String in ["house_player", "house_rival", "oak_lab"]:
		var prop := (load(PROPS_DIR + prop_name + ".tscn") as PackedScene).instantiate() as WorldProp
		assert_false(Vector2i.ZERO in prop.get_footprint(), "porte de %s ouverte" % prop_name)
		assert_true(Vector2i.UP in prop.get_footprint(), "façade de %s pleine" % prop_name)
		prop.free()


# --- Mobilier d'intérieur (jalon 2 §4.1, §4.3 à §4.7) ----------------------------

## nom → [largeur, hauteur (cases), empreinte]. Ancre = case en bas à gauche.
func _expected_interior() -> Dictionary:
	var one: Array[Vector2i] = [Vector2i.ZERO]
	var none: Array[Vector2i] = []
	# Bureau d'angle en L (mur du fond + mur ouest), coin libre pour la chaise.
	var corner: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(0, 0)]
	return {
		"window": [2, 1, none],
		"window_lab": [3, 1, none],
		"wall_map": [2, 1, none],
		"bed": [2, 3, _rect(0, -1, 1, 0)],
		"plant": [1, 2, one],
		"kitchen_counter": [3, 2, _rect(0, 0, 2, 0)],
		"fridge": [1, 3, one],
		"dining_table": [3, 2, _rect(0, -1, 2, 0)],
		"starter_table": [3, 2, _rect(0, -1, 2, 0)],
		"lab_bench": [3, 2, _rect(0, 0, 2, 0)],
		# Chambre du joueur (§4.3).
		"poster": [1, 1, none],
		"window_curtains": [2, 1, none],
		"nightstand_lamp": [1, 2, one],
		"small_shelf": [1, 2, one],
		"laptop_desk": [3, 2, _rect(0, 0, 2, 0)],
		"desk_chair": [1, 1, one],
		"tall_bookshelf": [2, 3, _rect(0, -1, 1, 0)],
		"tv_console_side": [1, 3, _rect(0, -1, 0, 0)],
		"travel_bag": [1, 1, one],
		"low_cabinet": [3, 1, _rect(0, 0, 2, 0)],
		"low_cabinet_small": [1, 1, one],
		"pokeball_crate": [2, 1, _rect(0, 0, 1, 0)],
		"rug_pokeball": [4, 3, none],
		"rug_check": [2, 1, none],
		"door_side": [1, 2, none],
		# Rez-de-chaussée du joueur (§4.4).
		"stairs_up_side": [2, 3, _rect(0, -1, 1, -1)],
		"sofa": [3, 2, _rect(0, 0, 2, 0)],
		"coffee_table": [2, 1, _rect(0, 0, 1, 0)],
		"coat_rack": [1, 2, one],
		"dresser_pokeball": [1, 2, one],
		"front_door": [1, 2, none],
		"rug_plaid": [5, 4, none],
		"rug_living": [3, 3, none],
		# Maison du rival (§4.5).
		"range_hood_stove": [1, 2, one],
		"stairs_up_wide": [3, 3, _rect(0, -2, 2, 0)],
		"corner_desk_pc": [2, 2, corner],
		"gamer_chair": [1, 1, one],
		"dresser": [2, 2, _rect(0, 0, 1, 0)],
		"bed_pokeball": [2, 3, _rect(0, -2, 1, 0)],
		"nightstand_bag": [1, 2, one],
		"wall_tv_side": [1, 3, _rect(0, -1, 0, 0)],
		"shoe_rack": [1, 1, one],
		"bathroom_sink": [2, 2, _rect(0, 0, 1, 0)],
		"shower": [1, 3, _rect(0, -1, 0, 0)],
		"partition": [1, 1, one],
		"partition_h": [1, 1, one],
		"rival_posters": [2, 1, none],
		"rug_bath": [2, 1, none],
		"rug_bedroom_grey": [3, 2, none],
		"rug_living_blue": [4, 3, none],
		# Laboratoire (§4.7).
		"aquarium": [1, 2, one],
		"incubator": [2, 3, _rect(0, -1, 1, 0)],
		"lab_computers": [2, 2, _rect(0, 0, 1, 0)],
		"oak_desk": [3, 2, _rect(0, 0, 2, 0)],
		"file_cabinet": [1, 2, one],
		"display_case": [1, 3, _rect(0, -2, 0, 0)],
		"long_counter": [5, 2, _rect(0, 0, 4, 0)],
		"sofa_side": [1, 2, _rect(0, -1, 0, 0)],
		"stool": [1, 1, one],
		"wall_screen_side": [1, 3, _rect(0, -1, 0, 0)],
		"stairs_deco": [3, 2, _rect(0, -1, 2, 0)],
		"pokemon_poster": [1, 1, none],
		"lab_doorway": [2, 1, none],
		"rug_red": [4, 3, none],
		# Jalon 3A (§3.2) : décor posé sur un meuble, sans empreinte.
		"breakfast": [3, 2, none],
		"bed_items": [2, 2, none],
	}


func test_every_interior_prop_matches_plan() -> void:
	var expected := _expected_interior()
	for prop_name: String in expected:
		var spec: Array = expected[prop_name]
		var path := INTERIOR_DIR + prop_name + ".tscn"
		assert_true(ResourceLoader.exists(path), path)
		if not ResourceLoader.exists(path):
			continue
		var prop := (load(path) as PackedScene).instantiate() as WorldProp
		assert_not_null(prop, "%s est un WorldProp" % path)
		if prop == null:
			continue
		assert_eq(_sorted(prop.get_footprint()), _sorted(spec[2]), prop_name)
		# Seule la plante devient transparente (retouche QA jalon 2 §8).
		assert_eq(prop.fade_when_covering, prop_name == "plant", "%s : transparence" % prop_name)
		var sprite := prop.get_node(^"Sprite") as Sprite2D
		assert_not_null(sprite.texture, "%s a une texture" % prop_name)
		if sprite.texture != null:
			var size := Vector2(spec[0], spec[1]) * Grid.TILE_SIZE
			assert_eq(sprite.texture.get_size(), size, "%s : taille du sprite" % prop_name)
			# Bas du sprite sur l'origine, ancre = case en bas à gauche.
			var rect := Rect2(sprite.offset, sprite.texture.get_size())
			assert_eq(rect.end.y, 0.0, "%s : bas du sprite" % prop_name)
			assert_eq(rect.position.x, -float(Grid.HALF_TILE), "%s : ancre à gauche" % prop_name)
		prop.free()


func test_no_unplanned_interior_prop() -> void:
	var expected := _expected_interior()
	for file: String in DirAccess.get_files_at(INTERIOR_DIR):
		if file.ends_with(".tscn"):
			assert_true(expected.has(file.get_basename()), "prop prévu : %s" % file)


func test_rugs_have_no_footprint_and_default_z() -> void:
	# Les cartes les posent sous `Detail` (voir test_interiors) : ni empreinte ni z propre.
	for prop_name: String in ["rug_pokeball", "rug_check", "rug_plaid", "rug_living",
			"rug_bath", "rug_bedroom_grey", "rug_living_blue", "rug_red"]:
		var prop := (load(INTERIOR_DIR + prop_name + ".tscn") as PackedScene).instantiate()
		assert_eq((prop as Node2D).z_index, 0, prop_name)
		assert_true((prop as WorldProp).get_footprint().is_empty(), prop_name)
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


# --- Warps, spawns, intérieur (jalon 2 §2.3) ---------------------------------------

func test_interior_is_false_by_default() -> void:
	assert_false(_map.interior)


func test_warp_point_converts_to_warp() -> void:
	var point := _warp_point(&"P", Vector2i(3, 2), Warp.Trigger.PUSH, Vector2i.DOWN)
	point.arrival_facing = Vector2i.LEFT
	assert_eq(point.get_cell(), Vector2i(3, 2))
	var warp := point.to_warp()
	assert_eq(warp.cell, Vector2i(3, 2))
	assert_eq(warp.trigger, Warp.Trigger.PUSH)
	assert_eq(warp.direction, Vector2i.DOWN)
	assert_eq(warp.target_map, &"elsewhere")
	assert_eq(warp.target_spawn, &"entrance")
	assert_eq(warp.facing, Vector2i.LEFT)
	point.free()


func test_warps_found_on_step_and_on_push() -> void:
	var warps := _map.get_warps()
	assert_eq(warps.size(), 2)
	var door := warps.find_on_step(DOOR_CELL, Vector2i.UP)
	assert_not_null(door)
	if door != null:
		assert_eq(door.target_map, &"elsewhere")
	assert_null(warps.find_on_step(DOOR_CELL, Vector2i.DOWN), "porte : pas vers le haut exigé")
	assert_null(warps.find_on_push(DOOR_CELL, Vector2i.UP), "porte : pas de poussée")
	var mat := warps.find_on_push(MAT_CELL, Vector2i.DOWN)
	assert_not_null(mat)
	if mat != null:
		assert_eq(mat.trigger, Warp.Trigger.PUSH)
	assert_null(warps.find_on_step(MAT_CELL, Vector2i.DOWN), "tapis : un pas ne suffit pas")
	assert_null(warps.find_on_push(MAT_CELL, Vector2i.LEFT))


func test_map_without_warps_node_has_empty_table() -> void:
	var map := GameMap.new()
	map.size = Vector2i(4, 4)
	add_child_autofree(map)
	assert_not_null(map.get_warps())
	assert_true(map.get_warps().is_empty())


func test_conflicting_step_warps_push_error() -> void:
	var map := _make_mini_map()
	var warps := map.get_node(^"Warps")
	warps.add_child(_warp_point(&"Clash", DOOR_CELL, Warp.Trigger.STEP_ON, Vector2i.ZERO))
	add_child_autofree(map)
	assert_push_error("warp invalide")
	assert_eq(map.get_warps().size(), 2, "le warp en conflit est écarté")


func test_invalid_warp_push_error() -> void:
	var map := _make_mini_map()
	var point := _warp_point(&"NoTarget", Vector2i(5, 1), Warp.Trigger.STEP_ON, Vector2i.UP)
	point.target_map = &""
	map.get_node(^"Warps").add_child(point)
	add_child_autofree(map)
	assert_push_error("warp invalide")
	assert_null(map.get_warps().find_on_step(Vector2i(5, 1), Vector2i.UP))


func test_has_spawn_without_error() -> void:
	assert_true(_map.has_spawn(&"start"))
	assert_false(_map.has_spawn(&"nowhere"))
	assert_false(_map.has_spawn(&""))
	assert_push_error_count(0)


# --- Cadrage caméra d'une petite pièce (jalon 2 §2.7) ----------------------------

func _make_room(room_size: Vector2i) -> GameMap:
	var map := GameMap.new()
	map.name = "Room"
	map.size = room_size
	map.interior = true
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	map.add_child(spawns)
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(Vector2i(3, 4))
	spawns.add_child(marker)
	return map


func _camera_limits(camera: Camera2D) -> Rect2i:
	return Rect2i(camera.limit_left, camera.limit_top,
		camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)


func test_small_room_camera_limits_follow_camera_framing() -> void:
	var room := _make_room(Vector2i(10, 8))
	add_child_autofree(room)
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	room.spawn_player(player, &"start", Vector2i.DOWN)
	var view := player.get_viewport_rect().size
	var expected := CameraFraming.limits_for(room.get_pixel_rect(), view)
	assert_eq(_camera_limits(player.get_camera()), expected)
	assert_eq(player.get_camera().zoom, Vector2.ONE)
	# La pièce est centrée : autant de marge à gauche qu'à droite (à 1 px près).
	var rect := room.get_pixel_rect()
	var left := rect.position.x - expected.position.x
	var right := expected.end.x - rect.end.x
	assert_true(absi(left - right) <= 1, "marges %d / %d" % [left, right])


func test_camera_limits_recomputed_on_viewport_size_changed() -> void:
	var room := _make_room(Vector2i(10, 8))
	add_child_autofree(room)
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	room.spawn_player(player, &"start", Vector2i.DOWN)
	var camera := player.get_camera()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1
	camera.limit_bottom = 1
	player.get_viewport().size_changed.emit()
	var expected := CameraFraming.limits_for(
		room.get_pixel_rect(), player.get_viewport_rect().size)
	assert_eq(_camera_limits(camera), expected)


# --- PNJ et points d'examen (jalon 3A §2.2, §2.3) ----------------------------------

const NPC_FIXTURES := "res://tests/fixtures/npcs/"
## Case de la table sous le Pokémon posé (fixture : charmander, lift 56).
const TABLE_CELL := Vector2i(11, 5)


## Carte 20 × 18 sans tuiles, avec les PNJ de tests/fixtures/npcs/sample_map.json.
func _make_npc_map(map_size: Vector2i = Vector2i(20, 18)) -> GameMap:
	var map := GameMap.new()
	map.name = "SampleMap"
	map.map_id = &"sample_map"
	map.npcs_dir = NPC_FIXTURES
	map.size = map_size
	map.blocked_cells = [TABLE_CELL]
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		map.add_child(node)
	(map.get_node(^"Entities") as Node2D).y_sort_enabled = true
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(Vector2i(2, 2))
	map.get_node(^"Spawns").add_child(marker)
	return map


func _interact_point(anchor: Vector2i, point_size: Vector2i, dialogue: StringName) -> InteractPoint:
	var point := InteractPoint.new()
	point.name = "Point_" + String(dialogue)
	point.position = Grid.cell_to_world(anchor)
	point.size = point_size
	point.dialogue_id = dialogue
	return point


func test_npcs_default_dir_is_data_npcs() -> void:
	var map := GameMap.new()
	assert_eq(map.npcs_dir, NpcRoster.DATA_DIR)
	map.free()
	assert_eq(NpcRoster.DATA_DIR, "res://data/npcs/")


func test_npcs_created_in_entities_on_their_cells_and_occupying() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var npcs := map.get_npcs()
	assert_eq(npcs.size(), 4)
	var expected: Dictionary[StringName, Vector2i] = {
		&"mom": Vector2i(7, 4), &"charmander": TABLE_CELL,
		&"rival": Vector2i(13, 4), &"pidgey_1": Vector2i(19, 16),
	}
	var order: Array[StringName] = [&"mom", &"charmander", &"rival", &"pidgey_1"]
	for i: int in npcs.size():
		var npc := npcs[i]
		assert_eq(npc.get_id(), order[i], "ordre du fichier")
		assert_eq(npc.get_parent(), map.get_entities())
		assert_eq(npc.get_cell(), expected[npc.get_id()])
		assert_eq(npc.position, Grid.cell_to_world(npc.get_cell()))
		assert_same(map.get_grid().get_occupant(npc.get_cell()), npc)
		assert_null(npc.owner, "jamais sauvé dans la scène")
	assert_push_error_count(0)


func test_get_npc_by_id() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var rival := map.get_npc(&"rival")
	assert_not_null(rival)
	if rival != null:
		assert_eq(rival.get_cell(), Vector2i(13, 4))
		assert_eq(rival.get_facing(), Vector2i.RIGHT)
		assert_false(rival.get_spec().turn_to_player)
	assert_null(map.get_npc(&"nobody"))


func test_get_npcs_returns_copy() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	map.get_npcs().clear()
	assert_eq(map.get_npcs().size(), 4)


func test_lifted_pokemon_sprite_raised_on_solid_table_cell() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var charmander := map.get_npc(&"charmander")
	assert_true(map.get_grid().is_solid(TABLE_CELL), "case de table solide")
	assert_same(map.get_grid().get_occupant(TABLE_CELL), charmander, "occupe quand même")
	assert_eq(charmander.get_cell(), TABLE_CELL, "la case ne change pas")
	assert_eq(charmander.position, Grid.cell_to_world(TABLE_CELL))
	var sprite := charmander.get_node(^"%Sprite") as Node2D
	assert_eq(sprite.global_position.y, charmander.global_position.y - 56.0)
	assert_eq(charmander.get_interaction().kind, Interaction.Kind.OBSERVE)


func test_non_interactive_pidgey_has_null_interaction() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	assert_null(map.get_npc(&"pidgey_1").get_interaction())


func test_finder_finds_npc_in_front_of_player() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var found := InteractionFinder.find(map.get_grid(), map.get_interactions(),
		Vector2i(7, 5), Vector2i.UP)
	assert_not_null(found)
	if found != null:
		assert_same(found.source, map.get_npc(&"mom"))
		assert_eq(found.dialogue_id, &"mom")


func test_rebuild_grid_keeps_npcs_on_their_cells() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var grid := map.rebuild_grid()
	for npc: Npc in map.get_npcs():
		assert_same(grid.get_occupant(npc.get_cell()), npc)
	assert_eq(map.get_npcs().size(), 4, "pas de doublon")
	assert_eq(map.get_entities().get_child_count(), 4)


func test_npc_out_of_map_is_not_created() -> void:
	var map := _make_npc_map(Vector2i(15, 15))
	add_child_autofree(map)
	assert_push_error("pidgey_1")
	assert_eq(map.get_npcs().size(), 3)
	assert_null(map.get_npc(&"pidgey_1"))


func test_npc_on_occupied_cell_is_not_created() -> void:
	var map := _make_npc_map()
	var blocker := RefCounted.new()
	map.get_grid().occupy(Vector2i(13, 4), blocker)
	add_child_autofree(map)
	assert_push_error("occupée")
	assert_null(map.get_npc(&"rival"))
	assert_same(map.get_grid().get_occupant(Vector2i(13, 4)), blocker)
	assert_eq(map.get_npcs().size(), 3)


func test_map_without_npc_file_has_no_npc_and_no_error() -> void:
	var map := _make_npc_map()
	map.map_id = &"no_such_map"
	add_child_autofree(map)
	assert_eq(map.get_npcs().size(), 0)
	assert_eq(map.get_entities().get_child_count(), 0)
	assert_push_error_count(0)


func test_interact_point_3x2_gives_six_interactions() -> void:
	var map := _make_npc_map()
	var table := _interact_point(Vector2i(3, 10), Vector2i(3, 2), &"breakfast_table")
	map.get_node(^"Interactables").add_child(table)
	add_child_autofree(map)
	var interactions := map.get_interactions()
	assert_eq(interactions.size(), 6)
	for y: int in [9, 10]:
		for x: int in [3, 4, 5]:
			var found := interactions.find(Vector2i(x, y), Vector2i.UP)
			assert_not_null(found, "case (%d, %d)" % [x, y])
			if found != null:
				assert_eq(found.dialogue_id, &"breakfast_table")
				assert_eq(found.kind, Interaction.Kind.EXAMINE)
				assert_null(found.source)
	assert_null(interactions.find(Vector2i(3, 8), Vector2i.UP))
	assert_null(interactions.find(Vector2i(6, 10), Vector2i.UP))
	assert_push_error_count(0)


func test_interact_point_found_from_neighbour_cell() -> void:
	var map := _make_npc_map()
	map.get_node(^"Interactables").add_child(
		_interact_point(Vector2i(3, 10), Vector2i(3, 2), &"breakfast_table"))
	add_child_autofree(map)
	var found := InteractionFinder.find(map.get_grid(), map.get_interactions(),
		Vector2i(4, 11), Vector2i.UP)
	assert_not_null(found)
	assert_null(InteractionFinder.find(map.get_grid(), map.get_interactions(),
		Vector2i(4, 11), Vector2i.DOWN), "rien derrière")


func test_interact_point_cells_and_facing() -> void:
	var point := _interact_point(Vector2i(2, 6), Vector2i(2, 3), &"kanto_map")
	point.facing = Vector2i.UP
	var cells: Array[Vector2i] = [Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5),
		Vector2i(3, 5), Vector2i(2, 4), Vector2i(3, 4)]
	assert_eq(point.get_cell(), Vector2i(2, 6))
	assert_eq(point.get_cells(), cells)
	for interaction: Interaction in point.to_interactions():
		assert_eq(interaction.facing, Vector2i.UP)
		assert_true(interaction.accepts(Vector2i.UP))
		assert_false(interaction.accepts(Vector2i.LEFT))
	point.free()


func test_conflicting_interact_points_push_error() -> void:
	var map := _make_npc_map()
	var interactables := map.get_node(^"Interactables")
	interactables.add_child(_interact_point(Vector2i(3, 10), Vector2i(3, 2), &"breakfast_table"))
	interactables.add_child(_interact_point(Vector2i(5, 10), Vector2i(1, 1), &"other"))
	add_child_autofree(map)
	assert_push_error("interaction invalide")
	assert_eq(map.get_interactions().size(), 6, "le point en conflit est écarté")
	assert_eq(map.get_interactions().find(Vector2i(5, 10), Vector2i.UP).dialogue_id,
		&"breakfast_table")


func test_interact_point_without_dialogue_push_error() -> void:
	var map := _make_npc_map()
	map.get_node(^"Interactables").add_child(_interact_point(Vector2i(3, 10), Vector2i.ONE, &""))
	add_child_autofree(map)
	assert_push_error("interaction invalide")
	assert_true(map.get_interactions().is_empty())


func test_map_without_interactables_node_has_empty_table() -> void:
	var map := GameMap.new()
	map.size = Vector2i(4, 4)
	add_child_autofree(map)
	assert_not_null(map.get_interactions())
	assert_true(map.get_interactions().is_empty())


# --- Jalon 3B (T2) : déclencheurs de scène -------------------------------------------

func _trigger_point(node_name: StringName, cell: Vector2i, point_size: Vector2i,
		cutscene: StringName, direction: Vector2i = Vector2i.ZERO) -> EventTriggerPoint:
	var point := EventTriggerPoint.new()
	point.name = node_name
	point.position = Grid.cell_to_world(cell)
	point.size = point_size
	point.cutscene_id = cutscene
	point.direction = direction
	return point


func _add_triggers_node(map: GameMap) -> Node2D:
	var triggers := Node2D.new()
	triggers.name = "Triggers"
	map.add_child(triggers)
	return triggers


func test_event_trigger_point_2x1_gives_two_triggers() -> void:
	var map := _make_mini_map()
	_add_triggers_node(map).add_child(
		_trigger_point(&"Grass", Vector2i(5, 3), Vector2i(2, 1), &"route1_grass"))
	add_child_autofree(map)
	var triggers := map.get_triggers()
	assert_eq(triggers.size(), 2)
	for cell: Vector2i in [Vector2i(5, 3), Vector2i(6, 3)]:
		var found := triggers.find_on_step(cell, Vector2i.UP)
		assert_not_null(found, "case %s" % cell)
		if found != null:
			assert_eq(found.cutscene_id, &"route1_grass")
		assert_not_null(triggers.find_on_step(cell, Vector2i.LEFT), "toutes directions")
	assert_null(triggers.find_on_step(Vector2i(5, 2), Vector2i.UP))
	assert_null(triggers.find_on_step(Vector2i(7, 3), Vector2i.UP))
	assert_push_error_count(0)


func test_event_trigger_point_cells() -> void:
	var point := _trigger_point(&"P", Vector2i(2, 6), Vector2i(2, 2), &"s")
	var cells: Array[Vector2i] = [Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5),
		Vector2i(3, 5)]
	assert_eq(point.get_cell(), Vector2i(2, 6))
	assert_eq(point.get_cells(), cells)
	assert_eq(point.to_triggers().size(), 4)
	point.free()


func test_trigger_direction_is_respected() -> void:
	var map := _make_mini_map()
	_add_triggers_node(map).add_child(
		_trigger_point(&"Up", Vector2i(5, 3), Vector2i.ONE, &"s", Vector2i.UP))
	add_child_autofree(map)
	var triggers := map.get_triggers()
	assert_not_null(triggers.find_on_step(Vector2i(5, 3), Vector2i.UP))
	assert_null(triggers.find_on_step(Vector2i(5, 3), Vector2i.DOWN))
	assert_null(triggers.find_on_step(Vector2i(5, 3), Vector2i.LEFT))


func test_conflicting_trigger_points_push_error() -> void:
	var map := _make_mini_map()
	var node := _add_triggers_node(map)
	node.add_child(_trigger_point(&"Grass", Vector2i(5, 3), Vector2i(2, 1), &"a"))
	node.add_child(_trigger_point(&"Clash", Vector2i(6, 3), Vector2i.ONE, &"b"))
	add_child_autofree(map)
	assert_push_error("déclencheur invalide")
	assert_eq(map.get_triggers().size(), 2, "le déclencheur en conflit est écarté")
	assert_eq(map.get_triggers().find_on_step(Vector2i(6, 3), Vector2i.UP).cutscene_id, &"a")


func test_trigger_without_cutscene_push_error() -> void:
	var map := _make_mini_map()
	_add_triggers_node(map).add_child(_trigger_point(&"Empty", Vector2i(5, 3), Vector2i.ONE, &""))
	add_child_autofree(map)
	assert_push_error("déclencheur invalide")
	assert_true(map.get_triggers().is_empty())


func test_rebuild_grid_rebuilds_the_trigger_table() -> void:
	var map := _make_mini_map()
	var node := _add_triggers_node(map)
	add_child_autofree(map)
	assert_true(map.get_triggers().is_empty())
	var before := map.get_triggers()
	node.add_child(_trigger_point(&"Late", Vector2i(5, 3), Vector2i.ONE, &"s"))
	map.rebuild_grid()
	assert_ne(map.get_triggers(), before, "nouvelle table")
	assert_eq(map.get_triggers().size(), 1)


func test_map_without_triggers_node_has_empty_table() -> void:
	var map := GameMap.new()
	map.size = Vector2i(4, 4)
	add_child_autofree(map)
	assert_not_null(map.get_triggers())
	assert_true(map.get_triggers().is_empty())


# --- PNJ ajoutés par une scène (jalon 3B §2.5, T3) --------------------------------------

func _added_spec(id: StringName, cell: Vector2i) -> NpcSpec:
	var spec := NpcSpec.new()
	spec.id = id
	spec.cell = cell
	spec.facing = Vector2i.UP
	spec.sprite = &"oak"
	return spec


func test_add_npc_on_a_free_cell() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var npc := map.add_npc(_added_spec(&"oak", Vector2i(4, 12)))
	assert_not_null(npc)
	if npc == null:
		return
	assert_eq(npc.get_parent(), map.get_entities())
	assert_same(map.get_npc(&"oak"), npc)
	assert_same(map.get_grid().get_occupant(Vector2i(4, 12)), npc)
	assert_eq(npc.get_cell(), Vector2i(4, 12))
	assert_eq(npc.get_facing(), Vector2i.UP)
	assert_eq(npc.position, Grid.cell_to_world(Vector2i(4, 12)))
	assert_eq(map.get_npcs().size(), 5)
	assert_null(npc.owner, "jamais sauvé dans la scène")
	assert_push_error_count(0)


func test_add_npc_on_a_taken_cell_returns_null_with_error() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	assert_null(map.add_npc(_added_spec(&"oak", Vector2i(7, 4))), "case de Maman")
	assert_push_error("occupée")
	assert_same(map.get_grid().get_occupant(Vector2i(7, 4)), map.get_npc(&"mom"))
	assert_null(map.get_npc(&"oak"))
	assert_eq(map.get_entities().get_child_count(), 4)


func test_add_npc_outside_or_with_a_known_id_returns_null_with_error() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	assert_null(map.add_npc(_added_spec(&"oak", Vector2i(30, 3))))
	assert_push_error("hors de la carte")
	assert_null(map.add_npc(_added_spec(&"mom", Vector2i(4, 12))))
	assert_push_error("déjà présent")
	assert_false(map.get_grid().is_occupied(Vector2i(4, 12)))
	assert_eq(map.get_npcs().size(), 4)


func test_remove_npc_frees_its_cell() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var npc := map.add_npc(_added_spec(&"oak", Vector2i(4, 12)))
	map.remove_npc(&"oak")
	assert_false(map.get_grid().is_occupied(Vector2i(4, 12)))
	assert_null(map.get_npc(&"oak"))
	assert_eq(map.get_npcs().size(), 4)
	assert_true(npc.is_queued_for_deletion())
	map.remove_npc(&"rival")
	assert_false(map.get_grid().is_occupied(Vector2i(13, 4)), "PNJ du fichier aussi")
	map.remove_npc(&"nobody")
	assert_push_error_count(0)


func test_rebuild_grid_keeps_added_and_walked_npcs() -> void:
	var map := _make_npc_map()
	add_child_autofree(map)
	var npc := map.add_npc(_added_spec(&"oak", Vector2i(4, 12)))
	assert_true(npc.step(Vector2i.UP))
	npc.set_process(false)
	for i: int in 30:
		npc._process(1.0 / 60.0)
	assert_eq(npc.get_cell(), Vector2i(4, 11))
	var grid := map.rebuild_grid()
	assert_same(grid.get_occupant(Vector2i(4, 11)), npc, "sur sa case courante")
	assert_false(grid.is_occupied(Vector2i(4, 12)))
	for other: Npc in map.get_npcs():
		assert_same(grid.get_occupant(other.get_cell()), other)
	assert_eq(map.get_npcs().size(), 5, "pas de doublon")
	assert_true(npc.step(Vector2i.UP), "marche sur la grille reconstruite")
	assert_push_error_count(0)
