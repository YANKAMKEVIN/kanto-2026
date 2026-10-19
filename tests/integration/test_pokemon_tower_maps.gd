extends GutTest
## Les cinq étages de la Tour Pokémon (2F à 6F, jalon 19 T9, docs/tech/jalon-19.md §2.1, §2.2,
## §2.8) sur les **vraies scènes** : métadonnées (extérieure), grille de la scène = grille du
## plan, paires d'escaliers aller-retour (T23 à T56), replis « à venir » (T12, T67), cases calmes
## du 5F, déclencheurs (zone purifiée à direction, rival, SPECTRE), budget de nœuds, halos,
## aucune `Light2D`, décors de combat, points d'apparition de QA.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const WALKABLE: String = ".ZUV"
const NODE_BUDGET: int = 3000
const MAX_GLOWS: int = 16
const SIZE := Vector2i(20, 18)
const FLOORS: Dictionary = {
	&"pokemon_tower_2f": "res://tools/plans/pokemon_tower_2f.txt",
	&"pokemon_tower_3f": "res://tools/plans/pokemon_tower_3f.txt",
	&"pokemon_tower_4f": "res://tools/plans/pokemon_tower_4f.txt",
	&"pokemon_tower_5f": "res://tools/plans/pokemon_tower_5f.txt",
	&"pokemon_tower_6f": "res://tools/plans/pokemon_tower_6f.txt",
}
## Déclencheurs à direction de la zone purifiée (jalon-19.md §2.8) : case → pas qui y entre.
const ZONE_TRIGGERS: Dictionary = {
	Vector2i(10, 8): [Vector2i.RIGHT],
	Vector2i(10, 9): [Vector2i.RIGHT, Vector2i.UP],
	Vector2i(11, 9): [Vector2i.LEFT, Vector2i.UP],
	Vector2i(11, 8): [Vector2i.LEFT],
}

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in FLOORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(FLOORS[map_id]), plan.error)
		_plans[map_id] = plan
		var scene := load(MapCatalog.scene_path(map_id)) as PackedScene
		if scene != null:
			var map := scene.instantiate() as GameMap
			add_child(map)
			_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _find_all(node: Node, out: Array[Node], test: Callable) -> void:
	if test.call(node):
		out.append(node)
	for child: Node in node.get_children():
		_find_all(child, out, test)


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


func _facing(text: String) -> Vector2i:
	return {"left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP,
		"down": Vector2i.DOWN}[text]


func test_floors_exist_as_outdoor_maps() -> void:
	for map_id: StringName in FLOORS:
		assert_true(_maps.has(map_id), "%s construite" % map_id)
		var map: GameMap = _maps.get(map_id)
		if map == null:
			continue
		assert_eq(map.map_id, map_id)
		assert_eq(map.display_name, "Tour Pokémon")
		assert_eq(map.size, SIZE)
		assert_false(map.interior, "%s : extérieure (compagnon visible)" % map_id)
		assert_not_null(map.get_node_or_null(^"PaintedGround"), "%s : sol peint" % map_id)


func test_scene_grid_matches_the_plan() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var grid := (_maps[map_id] as GameMap).get_grid()
		var wrong: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if grid.is_solid(cell) == WALKABLE.contains(plan.at(cell)):
					wrong.append(cell)
		assert_eq(wrong, [] as Array[Vector2i], "%s : cases différentes du plan" % map_id)


func test_no_grass_and_no_rubble() -> void:
	for map_id: StringName in _maps:
		var ground := (_maps[map_id] as GameMap).get_node(^"Ground") as TileMapLayer
		for y: int in SIZE.y:
			for x: int in SIZE.x:
				var data := ground.get_cell_tile_data(Vector2i(x, y))
				assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
				assert_false(data.get_custom_data(OverworldTiles.DATA_RUBBLE))


func test_stairs_pair_up_both_ways() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var map: GameMap = _maps[map_id]
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "escalier":
				continue
			var warp := _warp_at(map, plan.cell_of(id))
			assert_not_null(warp, "%s : escalier %s" % [map_id, id])
			if warp == null:
				continue
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, id)
			assert_eq(warp.direction, Vector2i.ZERO, "%s : escalier, toute direction" % id)
			var pair := plan.attr(id, "paire")
			var target := StringName(plan.attr(id, "vers"))
			if not _maps.has(target):
				continue  # replis, test dédié
			assert_eq(warp.target_map, target, id)
			var other: GameMap = _maps[target]
			var other_plan: PlanGrid = _plans[target]
			assert_true(other.has_spawn(warp.target_spawn), "%s → %s" % [id, warp.target_spawn])
			var arrival := other.get_spawn_cell(warp.target_spawn)
			assert_false(other.get_grid().is_solid(arrival), "%s : arrivée praticable" % id)
			assert_eq(other_plan.attr(String(warp.target_spawn), "paire"), pair)
			assert_eq(warp.facing, _facing(other_plan.attr(String(warp.target_spawn), "facing")),
				"%s : orientation de la grille" % id)
			var back: Warp = null
			for other_id: String in other_plan.positions:
				if other_plan.positions[other_id]["kind"] == "escalier" \
						and other_plan.attr(other_id, "paire") == pair:
					back = _warp_at(other, other_plan.cell_of(other_id))
			assert_not_null(back, "%s : escalier de retour (paire %s)" % [id, pair])
			if back == null:
				continue
			assert_true(Grid.is_cardinal(arrival - back.cell), "%s : arrivée à côté" % id)
			assert_eq(back.target_map, map_id)
			var home := map.get_spawn_cell(back.target_spawn)
			assert_true(Grid.is_cardinal(home - plan.cell_of(id)), "%s : retour à côté" % id)


## T16 : le 2F rejoint le rez-de-chaussée (spawn `from_pokemon_tower_2f`) ; seul le 6F → 7F reste
## un repli (hors J19).
func test_stairs_to_floors_outside_j19_are_coming_soon() -> void:
	var down := _warp_at(_maps.get(&"pokemon_tower_2f"), Vector2i(18, 9))
	assert_not_null(down, "2F → 1F")
	if down != null:
		assert_false(down.is_coming_soon(), "le 1F existe (T16)")
		assert_eq(down.target_map, &"pokemon_tower_1f")
		assert_eq(down.target_spawn, &"from_pokemon_tower_2f")
	for entry: Array in [[&"pokemon_tower_6f", Vector2i(9, 16), &"arrivee_T56"]]:
		var map: GameMap = _maps.get(entry[0])
		if map == null:
			fail_test("%s absente" % entry[0])
			continue
		var warp := _warp_at(map, entry[1])
		assert_not_null(warp, "%s %s" % [entry[0], entry[1]])
		if warp == null:
			continue
		assert_true(warp.is_coming_soon(), "%s : repli « à venir »" % entry[0])
		assert_eq(warp.coming_soon, "Tour Pokémon")
		assert_eq(warp.target_spawn, entry[2])
		assert_true(map.has_spawn(warp.target_spawn))


func test_spawns_match_the_plan_and_qa_spawns() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var map: GameMap = _maps[map_id]
		for id: String in plan.positions:
			if plan.positions[id]["kind"] == "spawn":
				assert_true(map.has_spawn(StringName(id)), "%s : %s" % [map_id, id])
				assert_eq(map.get_spawn_cell(StringName(id)), plan.cell_of(id))
	var two: GameMap = _maps.get(&"pokemon_tower_2f")
	var six: GameMap = _maps.get(&"pokemon_tower_6f")
	if two != null:
		assert_eq(two.get_spawn_cell(&"devant_rival"), Vector2i(16, 7))
	if six != null:
		assert_eq(six.get_spawn_cell(&"devant_spectre"), Vector2i(10, 14))


func test_calm_cells_only_on_fifth_floor() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		if map_id != &"pokemon_tower_5f":
			assert_eq(map.calm_cells.size(), 0, "%s : aucune case calme" % map_id)
			continue
		var plan: PlanGrid = _plans[map_id]
		var expected: Array[Vector2i] = []
		for zone: Vector2i in plan.cells_of("Z"):
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var near := zone + Vector2i(dx, dy)
					if plan.is_walkable(near) and not expected.has(near):
						expected.append(near)
		assert_gt(expected.size(), 4)
		assert_eq(map.calm_cells.size(), expected.size())
		for cell: Vector2i in expected:
			assert_has(map.calm_cells, cell)
		for cell: Vector2i in map.calm_cells:
			assert_false(map.get_grid().is_solid(cell), "%s : praticable" % cell)


func test_purified_zone_triggers_have_directions() -> void:
	var map: GameMap = _maps.get(&"pokemon_tower_5f")
	if map == null:
		fail_test("pokemon_tower_5f absente")
		return
	var triggers := map.get_triggers()
	for cell: Vector2i in _plans[&"pokemon_tower_5f"].cells_of("Z"):
		var found: Array[Vector2i] = []
		for trigger: EventTrigger in triggers.get_at(cell):
			assert_eq(trigger.cutscene_id, &"tower_purified_zone")
			assert_ne(trigger.direction, Vector2i.ZERO, "%s : direction obligatoire" % cell)
			found.append(trigger.direction)
		var expected: Array = ZONE_TRIGGERS[cell]
		assert_eq(found.size(), expected.size(), "%s : %s" % [cell, found])
		for step: Vector2i in expected:
			assert_has(found, step, "%s : pas %s" % [cell, step])
			assert_not_null(triggers.find_on_step(cell, step))
		# Un pas d'une case Z à une autre ne déclenche rien.
		for other: Vector2i in ZONE_TRIGGERS:
			if Grid.is_cardinal(other - cell):
				assert_null(triggers.find_on_step(cell, cell - other), "%s depuis %s" % [cell,
					other])


func test_rival_and_ghost_triggers() -> void:
	var two: GameMap = _maps.get(&"pokemon_tower_2f")
	if two != null:
		for cell: Vector2i in [Vector2i(15, 5), Vector2i(14, 6)]:
			var list := two.get_triggers().get_at(cell)
			assert_eq(list.size(), 1, str(cell))
			if list.is_empty():
				continue
			assert_eq(list[0].cutscene_id, &"tower_rival")
			assert_eq(list[0].direction, Vector2i.ZERO, "rival : sans direction")
		assert_eq(two.get_triggers().size(), 2)
	var six: GameMap = _maps.get(&"pokemon_tower_6f")
	if six != null:
		var list := six.get_triggers().get_at(Vector2i(10, 16))
		assert_eq(list.size(), 1)
		if not list.is_empty():
			assert_eq(list[0].cutscene_id, &"tower_6f_ghost")
			assert_eq(list[0].direction, Vector2i.ZERO)
		assert_eq(six.get_triggers().size(), 1)


## Seule la case (10, 16) mène à l'escalier du 7F : toutes ses autres voisines sont solides.
func test_seventh_floor_stairs_reachable_only_through_ghost_cell() -> void:
	var six: GameMap = _maps.get(&"pokemon_tower_6f")
	if six == null:
		fail_test("pokemon_tower_6f absente")
		return
	var stairs := Vector2i(9, 16)
	var open: Array[Vector2i] = []
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not six.get_grid().is_solid(stairs + step):
			open.append(stairs + step)
	assert_eq(open, [Vector2i(10, 16)] as Array[Vector2i])
	assert_false(six.get_grid().is_solid(Vector2i(10, 15)), "case de recul")


func test_glows_within_budget_and_no_light2d() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var glows: Array[Node] = []
		_find_all(map, glows, func(n: Node) -> bool: return n is LightGlow)
		assert_lte(glows.size(), MAX_GLOWS, "%s : %d halos" % [map_id, glows.size()])
		var lights: Array[Node] = []
		_find_all(map, lights, func(n: Node) -> bool: return n is Light2D)
		assert_eq(lights.size(), 0, "%s : aucune Light2D" % map_id)


func test_candle_and_purified_halos_and_one_mist_per_floor() -> void:
	var previous_alpha := 0.0
	for map_id: StringName in FLOORS:
		var map: GameMap = _maps[map_id]
		assert_eq(map.light_profile, &"tower", String(map_id))
		var steles: int = _plans[map_id].call(&"cells_of", "S").size()
		var candles: Array[Node] = []
		_find_all(map, candles, func(n: Node) -> bool:
			return n is LightGlow and (n as LightGlow).glow_type == &"candle")
		assert_eq(candles.size(), steles, "%s : un halo « candle » par stèle" % map_id)
		var purified: Array[Node] = []
		_find_all(map, purified, func(n: Node) -> bool:
			return n is LightGlow and (n as LightGlow).glow_type == &"purified")
		assert_eq(purified.size(), 1 if map_id == &"pokemon_tower_5f" else 0, String(map_id))
		var mists: Array[Node] = []
		_find_all(map, mists, func(n: Node) -> bool: return n is MistLayer)
		assert_eq(mists.size(), 1, "%s : une brume" % map_id)
		var mist := mists[0] as MistLayer
		assert_eq(mist.area, SIZE * 96, "%s : brume à la taille de la carte" % map_id)
		assert_lte(mist.alpha, MistLayer.ALPHA_MAX)
		assert_gt(mist.alpha, previous_alpha, "%s : plus brumeux que l'étage du dessous" % map_id)
		previous_alpha = mist.alpha
		assert_lt(mist.z_index, 0, "sous les personnages")
	assert_eq((_maps[&"pokemon_tower_6f"] as GameMap).get_node("Mist").get(&"alpha"),
		previous_alpha, "le 6F est le plus brumeux")


func test_node_budget() -> void:
	for map_id: StringName in _maps:
		var nodes := _count(_maps[map_id])
		gut.p("%s : %d nœuds" % [map_id, nodes])
		assert_lte(nodes, NODE_BUDGET, String(map_id))


func test_shade_gets_darker_floor_by_floor() -> void:
	var previous := 2.0
	for map_id: StringName in FLOORS:
		var map: GameMap = _maps.get(map_id)
		if map == null:
			continue
		var shade := map.get_node_or_null(^"CaveShade") as Sprite2D
		assert_not_null(shade, "%s : voile" % map_id)
		if shade == null:
			continue
		var image := shade.texture.get_image()
		var plan: PlanGrid = _plans[map_id]
		var per_cell := image.get_width() / SIZE.x
		var total := 0.0
		var count := 0
		for y: int in SIZE.y:
			for x: int in SIZE.x:
				if plan.is_walkable(Vector2i(x, y)):
					total += image.get_pixel(x * per_cell + per_cell / 2,
						y * per_cell + per_cell / 2).r
					count += 1
		var mean := total / maxf(count, 1)
		gut.p("%s : voile moyen %.3f" % [map_id, mean])
		# Le 5F est relevé par la lumière de la dalle purifiée : exempté de la comparaison.
		if map_id != &"pokemon_tower_5f":
			assert_lt(mean, previous, "%s plus sombre que l'étage du dessous" % map_id)
			previous = mean


func test_combat_decor_is_declared_for_each_floor() -> void:
	var text := FileAccess.get_file_as_string("res://data/battle/decors.json")
	var data: Dictionary = JSON.parse_string(text)
	assert_true((data["decors"] as Dictionary).has("tour_pokemon"))
	var decor: Dictionary = data["decors"]["tour_pokemon"]
	assert_true(ResourceLoader.exists(decor["back"]), "image du décor")
	for map_id: StringName in FLOORS:
		var places: Array = data["places"].get(String(map_id), [])
		assert_eq(places.size(), 1, String(map_id))
		if not places.is_empty():
			assert_eq(places[0]["decor"], "tour_pokemon")
