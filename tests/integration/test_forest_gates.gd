extends GutTest
## Postes de garde de la Forêt de Jade (jalon 9 T19, jalon-09.md §2.7.2, dossier 10 §3) : deux
## scènes générées par **une seule définition** (`_forest_gate(side)` de
## `tools/build_painted_interiors.gd`) : même enveloppe, mêmes meubles, garde à la même place ;
## seuls changent l'identifiant, la réplique du garde (fichier de PNJ) et les passages.

const SOUTH := &"viridian_forest_gate_south"
const NORTH := &"viridian_forest_gate_north"
const SIZE := Vector2i(10, 8)
const SHELL := "res://assets/world/interiors/int_poste_foret_coque.png"
const GUARD_CELL := Vector2i(7, 4)
const NORTH_DOOR: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 1)]
const SOUTH_DOOR: Array[Vector2i] = [Vector2i(4, 7), Vector2i(5, 7)]

var _south: GameMap
var _north: GameMap


func before_all() -> void:
	_south = (load(MapCatalog.scene_path(SOUTH)) as PackedScene).instantiate() as GameMap
	_north = (load(MapCatalog.scene_path(NORTH)) as PackedScene).instantiate() as GameMap
	add_child(_south)
	add_child(_north)


func after_all() -> void:
	_south.free()
	_north.free()


func _props(map: GameMap) -> Dictionary:
	var props: Dictionary = {}
	for child: Node in map.get_entities().get_children():
		if child is WorldProp:
			props[String(child.name)] = [child.scene_file_path, (child as Node2D).position]
	return props


func test_two_scenes_of_one_definition() -> void:
	for map: GameMap in [_south, _north]:
		assert_eq(map.size, SIZE, "%s : 10 × 8 cases" % map.map_id)
		assert_true(map.interior, "%s : intérieur" % map.map_id)
		assert_eq(map.light_profile, &"interior_warm")
		assert_eq(map.display_name, "Forêt de Jade")
		var shell := map.get_node_or_null(^"Shell") as Sprite2D
		assert_not_null(shell)
		if shell != null:
			assert_eq(shell.texture.resource_path, SHELL, "enveloppe commune")
	assert_eq(_south.map_id, SOUTH)
	assert_eq(_north.map_id, NORTH)
	assert_eq(_props(_south), _props(_north), "mêmes meubles aux mêmes places")
	assert_eq(_props(_south).size(), 4, "deux plantes, un meuble bas, un porte-manteau")
	assert_eq(_south.blocked_cells, _north.blocked_cells, "mêmes murs")
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(SOUTH), &"viridian_forest", "le poste sud est de la forêt")
	assert_eq(zones.zone_of(NORTH), &"viridian_forest", "le poste nord aussi")


func test_walkable_floor_and_doors() -> void:
	var grid := _south.get_grid()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var floor_cell := x >= 1 and x <= 8 and y >= 2 and y <= 6
			var door := NORTH_DOOR.has(cell) or SOUTH_DOOR.has(cell)
			var furniture := false
			for child: Node in _south.get_entities().get_children():
				if child is WorldProp and (child as WorldProp).get_solid_cells().has(cell):
					furniture = true
			assert_eq(grid.is_solid(cell), not (floor_cell or door) or furniture,
				"case %s" % cell)
	# Le passage central reste libre (colonnes 4..5 de l'ouverture nord au paillasson).
	assert_true(grid.find_reachable(Vector2i(4, 7)).has(Vector2i(4, 1)),
		"traversée du sud au nord")


func test_the_guards_stand_at_the_same_place_with_their_own_lines() -> void:
	var expected := {SOUTH: &"forest_gate_south_guard", NORTH: &"forest_gate_north_guard"}
	for map_id: StringName in expected:
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
		var guard := roster.get_spec(&"guard")
		assert_not_null(guard, "%s : garde" % map_id)
		if guard == null:
			continue
		assert_eq(guard.cell, GUARD_CELL)
		assert_eq(guard.facing, Vector2i.LEFT, "tourné vers le passage")
		assert_eq(guard.sprite, &"guard", "apparence peinte « garde »")
		assert_eq(guard.dialogue, expected[map_id])
		assert_true(ResourceLoader.exists(
			"res://assets/sprites/characters/painted/guard_frames.tres"), "planche du garde")
	assert_not_null(_south.get_npc(&"guard"))
	assert_not_null(_north.get_npc(&"guard"))
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var auto := false
	for variant: Variant in dialogues.get_dialogue(&"forest_gate_south_guard").variants:
		auto = auto or variant.auto
	assert_true(auto, "le garde sud parle à l'arrivée (poison, Q-4)")


func test_south_gate_links_route_2_and_the_forest() -> void:
	assert_eq(_south.get_spawn_cell(&"from_route_2"), Vector2i(4, 6))
	assert_eq(_south.get_spawn_cell(&"from_forest"), Vector2i(4, 2))
	for cell: Vector2i in SOUTH_DOOR:
		var warp := _south.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_not_null(warp, "paillasson %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_2", &"from_forest_gate", Vector2i.DOWN])
	for cell: Vector2i in NORTH_DOOR:
		var warp := _south.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "ouverture nord %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"viridian_forest", &"from_gate_south", Vector2i.UP])
			assert_false(warp.is_coming_soon())


func test_north_gate_links_the_forest_and_route_2_north_coming_soon() -> void:
	assert_eq(_north.get_spawn_cell(&"from_forest"), Vector2i(4, 6))
	assert_eq(_north.get_spawn_cell(&"north_door"), Vector2i(4, 2))
	for cell: Vector2i in SOUTH_DOOR:
		var warp := _north.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_not_null(warp, "paillasson %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"viridian_forest", &"from_gate_north", Vector2i.DOWN])
	for cell: Vector2i in NORTH_DOOR:
		var warp := _north.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "ouverture nord %s" % cell)
		if warp != null:
			assert_true(warp.is_coming_soon())
			assert_eq(warp.coming_soon.to_upper(), "ROUTE 2 NORD")
			assert_eq(warp.target_spawn, &"north_door")
			assert_eq(warp.facing, Vector2i.DOWN, "retour tourné vers le sud")
