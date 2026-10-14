extends GutTest
## Les trois étages du Mont Sélénite (jalon 12 T9, docs/tech/jalon-12.md §2.1, §2.2, §2.4,
## §2.18 ; dossier 15 §5) sur les **vraies scènes** : métadonnées (grotte = extérieure, profils
## `cave_*`), **grille de la scène = grille du plan** case par case, cases `g` = tuiles `RUBBLE`
## (et elles seules), échelles appariées (aller-retour, orientation à l'arrivée), entrée et sortie
## (repli « à venir » tant que la Route 3 / le sas du T8 n'existent pas), graphe des étages
## connexe et retour à l'entrée possible de toute case praticable (critère de
## `plan_check_mont_selenite.py`), goulets d'une case listés (compagnon, T20), halos ≤ 16, aucune
## `Light2D`, budget de nœuds, décors de combat, zone ; voile de pénombre et lumière du sol
## (passe « lumière rare »).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const WALKABLE: String = ".gjUVE"
const NODE_BUDGET: int = 3000
const MAX_GLOWS: int = 16
const FLOORS: Dictionary = {
	&"mt_moon_1f": ["res://tools/plans/mont_selenite_1f.txt", Vector2i(60, 46), &"cave_1f"],
	&"mt_moon_b1f": ["res://tools/plans/mont_selenite_b1f.txt", Vector2i(40, 30), &"cave_b1f"],
	&"mt_moon_b2f": ["res://tools/plans/mont_selenite_b2f.txt", Vector2i(50, 38), &"cave_b2f"],
}
## Cases bloquées par un décor posé sur une case praticable de la grille (position `bloque`).
const DECOR_BLOCKED: Dictionary = {&"mt_moon_1f": [Vector2i(26, 43)]}
const ENTRANCE: Array[Vector2i] = [Vector2i(29, 45), Vector2i(30, 45)]
## Goulets d'une case connus de la grille (dossier 15 §13 : le compagnon s'y masque).
const KNOWN_NARROWS: Dictionary = {
	&"mt_moon_1f": [Vector2i(7, 12)],
	&"mt_moon_b1f": [Vector2i(14, 1), Vector2i(14, 2), Vector2i(35, 27)],
}

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in FLOORS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(FLOORS[map_id][0]), plan.error)
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


# --- Métadonnées et lumière -----------------------------------------------------------------


func test_floors_exist_as_outdoor_cave_maps() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	for map_id: StringName in FLOORS:
		assert_true(_maps.has(map_id), "%s construite" % map_id)
		var map: GameMap = _maps.get(map_id)
		if map == null:
			continue
		assert_eq(map.map_id, map_id)
		assert_eq(map.display_name, "Mont Sélénite")
		assert_eq(map.region, "")
		assert_false(map.interior, "%s : grotte = extérieure (compagnon visible)" % map_id)
		assert_eq(map.size, FLOORS[map_id][1])
		assert_eq(map.light_profile, FLOORS[map_id][2])
		assert_true(caves.is_cave(map_id), "%s dans caves.json" % map_id)
		assert_not_null(map.get_node_or_null(^"PaintedGround"), "%s : sol peint" % map_id)


func test_light_profiles_get_darker_below() -> void:
	var library := LightingLibrary.new()
	assert_true(library.load_file())
	var first := library.get_profile(&"cave_1f")
	var b1 := library.get_profile(&"cave_b1f")
	var b2 := library.get_profile(&"cave_b2f")
	assert_not_null(first)
	assert_not_null(b1)
	assert_not_null(b2)
	var sum := func(p: LightProfile) -> float:
		return (p.grade_shadows + p.grade_midtones + p.grade_highlights).dot(Vector3.ONE)
	assert_gt(sum.call(first), sum.call(b1), "1F plus clair que B1F")
	assert_almost_eq(sum.call(b1), sum.call(b2), 0.0001, "B1F = B2F")
	for profile: LightProfile in [first, b1, b2]:
		assert_false(profile.has_cast_shadow(), "%s : pas de soleil, aucune ombre portée"
			% profile.id)
		assert_false(profile.has_wind(), "%s : aucun vent" % profile.id)
		assert_true(profile.has_contact_shadow(), "%s : ombres de contact" % profile.id)


func test_glows_within_budget_and_no_light2d() -> void:
	var library := LightGlow.library()
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var glows: Array[Node] = []
		_find_all(map, glows, func(n: Node) -> bool: return n is LightGlow)
		assert_between(glows.size(), 4, MAX_GLOWS, "%s : %d halos" % [map_id, glows.size()])
		for glow: Node in glows:
			assert_true(library.has_type((glow as LightGlow).glow_type), str(glow.name))
		var lights: Array[Node] = []
		_find_all(map, lights, func(n: Node) -> bool: return n is Light2D)
		assert_eq(lights.size(), 0, "%s : aucune Light2D" % map_id)


## Passe « lumière rare » (2026-10-14) : voile de pénombre (multiplication) puis lumière
## ajoutée au sol (addition), juste après `GroundDecals` (même `z`), donc sous `Entities` : les
## personnages ne sont jamais assombris. Le voile est plus sombre au pourtour qu'au centre des
## galeries, et le 1F est le plus clair (B1F ≥ B2F en moyenne sur les cases praticables).
func test_cave_shade_layers() -> void:
	var means: Dictionary = {}
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var shade := map.get_node_or_null(^"CaveShade") as Sprite2D
		var floor_light := map.get_node_or_null(^"CaveFloorLight") as Sprite2D
		assert_not_null(shade, "%s : voile" % map_id)
		assert_not_null(floor_light, "%s : lumière du sol" % map_id)
		if shade == null or floor_light == null:
			continue
		var decals := map.get_node(^"GroundDecals")
		assert_eq(shade.get_index(), decals.get_index() + 1, "%s : voile après le sol" % map_id)
		assert_eq(floor_light.get_index(), shade.get_index() + 1, String(map_id))
		var entities_z: int = (map.get_node(^"Entities") as Node2D).z_index
		for sprite: Sprite2D in [shade, floor_light]:
			assert_eq(sprite.z_index, (decals as Node2D).z_index, String(sprite.name))
			assert_lt(sprite.z_index, entities_z, "%s : sous Entities" % sprite.name)
		assert_eq((shade.material as CanvasItemMaterial).blend_mode,
			CanvasItemMaterial.BLEND_MODE_MUL)
		assert_eq((floor_light.material as CanvasItemMaterial).blend_mode,
			CanvasItemMaterial.BLEND_MODE_ADD)
		var size: Vector2i = FLOORS[map_id][1]
		assert_almost_eq(shade.texture.get_width() * shade.scale.x, float(size.x * Grid.TILE_SIZE),
			0.5, "%s : voile à la taille de la carte" % map_id)
		means[map_id] = _walkable_shade_mean(shade.texture.get_image(), map_id)
	if means.size() == 3:
		assert_gt(means[&"mt_moon_1f"], means[&"mt_moon_b1f"], "1F plus clair que B1F")
		assert_gte(means[&"mt_moon_b1f"], means[&"mt_moon_b2f"], "B1F ≥ B2F")
		for map_id: StringName in means:
			assert_lt(means[map_id], 0.95, "%s : la pénombre se voit" % map_id)


## Moyenne du voile (rouge, 0–1) au centre des cases praticables.
func _walkable_shade_mean(image: Image, map_id: StringName) -> float:
	var plan: PlanGrid = _plans[map_id]
	var size: Vector2i = FLOORS[map_id][1]
	var per_cell := image.get_width() / size.x
	var total := 0.0
	var count := 0
	for y: int in size.y:
		for x: int in size.x:
			if not plan.is_walkable(Vector2i(x, y)):
				continue
			total += image.get_pixel(x * per_cell + per_cell / 2, y * per_cell + per_cell / 2).r
			count += 1
	return total / maxf(count, 1)


func test_node_budget() -> void:
	for map_id: StringName in _maps:
		var nodes := _count(_maps[map_id])
		gut.p("%s : %d nœuds" % [map_id, nodes])
		assert_lte(nodes, NODE_BUDGET, String(map_id))


# --- Grille ---------------------------------------------------------------------------------


func test_scene_grid_matches_the_plan() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var grid := (_maps[map_id] as GameMap).get_grid()
		var decor: Array = DECOR_BLOCKED.get(map_id, [])
		var wrong: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var walkable := WALKABLE.contains(plan.at(cell)) and not decor.has(cell)
				if grid.is_solid(cell) == walkable:
					wrong.append(cell)
		assert_eq(wrong, [] as Array[Vector2i], "%s : cases différentes du plan" % map_id)


func test_rubble_tiles_exactly_on_g_cells() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var ground := (_maps[map_id] as GameMap).get_node(^"Ground") as TileMapLayer
		var count := 0
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				var data := ground.get_cell_tile_data(cell)
				var rubble: bool = data.get_custom_data(OverworldTiles.DATA_RUBBLE)
				assert_eq(rubble, plan.at(cell) == "g", "%s %s" % [map_id, cell])
				assert_false(data.get_custom_data(OverworldTiles.DATA_TALL_GRASS))
				if rubble:
					count += 1
		assert_gt(count, 0, "%s : des gravats" % map_id)


func test_single_cell_narrows_are_listed() -> void:
	for map_id: StringName in _maps:
		var grid := (_maps[map_id] as GameMap).get_grid()
		var plan: PlanGrid = _plans[map_id]
		var narrows: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				if grid.is_solid(cell):
					continue
				var across := grid.is_solid(cell + Vector2i.LEFT) \
					and grid.is_solid(cell + Vector2i.RIGHT)
				var along := grid.is_solid(cell + Vector2i.UP) \
					and grid.is_solid(cell + Vector2i.DOWN)
				if across or along:
					narrows.append(cell)
		gut.p("%s : goulets d'une case %s" % [map_id, narrows])
		for cell: Vector2i in KNOWN_NARROWS.get(map_id, []):
			assert_has(narrows, cell, "%s : goulet %s" % [map_id, cell])


# --- Échelles, entrée, sortie ---------------------------------------------------------------


## Passage de [param map] sur [param cell] (null si aucun).
func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


func test_ladders_pair_up_both_ways() -> void:
	for map_id: StringName in _maps:
		var plan: PlanGrid = _plans[map_id]
		var map: GameMap = _maps[map_id]
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "echelle":
				continue
			var cell := plan.cell_of(id)
			var warp := _warp_at(map, cell)
			assert_not_null(warp, "%s : échelle %s" % [map_id, id])
			if warp == null:
				continue
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, id)
			assert_eq(warp.direction, Vector2i.ZERO, "%s : escalier, toute direction" % id)
			var target := StringName(plan.attr(id, "vers"))
			if not _maps.has(target):
				continue  # sortie vers le sas : test dédié
			assert_eq(warp.target_map, target, id)
			var other: GameMap = _maps[target]
			var other_plan: PlanGrid = _plans[target]
			assert_true(other.has_spawn(warp.target_spawn), "%s → %s" % [id, warp.target_spawn])
			var arrival := other.get_spawn_cell(warp.target_spawn)
			assert_false(other.get_grid().is_solid(arrival), "%s : arrivée praticable" % id)
			# L'échelle de même paire de l'autre étage est voisine de l'arrivée ; on arrive
			# tourné à l'opposé, et elle ramène sur l'arrivée d'ici.
			var pair := plan.attr(id, "paire")
			var back: Warp = null
			for other_id: String in other_plan.positions:
				if other_plan.positions[other_id]["kind"] == "echelle" \
						and other_plan.attr(other_id, "paire") == pair:
					back = _warp_at(other, other_plan.cell_of(other_id))
			assert_not_null(back, "%s : échelle de retour (paire %s)" % [id, pair])
			if back == null:
				continue
			assert_true(Grid.is_cardinal(arrival - back.cell), "%s : arrivée à côté" % id)
			assert_eq(warp.facing, arrival - back.cell, "%s : tourné à l'opposé" % id)
			assert_eq(back.target_map, map_id)
			var home := map.get_spawn_cell(back.target_spawn)
			assert_true(Grid.is_cardinal(home - cell), "%s : retour à côté de l'échelle" % id)


func test_entrance_leads_to_route_3_or_is_coming_soon() -> void:
	var map: GameMap = _maps.get(&"mt_moon_1f")
	if map == null:
		fail_test("mt_moon_1f absente")
		return
	var built := MapCatalog.has_map(&"route_3")
	for i: int in ENTRANCE.size():
		var cell := ENTRANCE[i]
		var spawn := StringName("from_route_3_%s" % ["w", "e"][i])
		assert_true(map.has_spawn(spawn), String(spawn))
		assert_eq(map.get_spawn_cell(spawn), cell + Vector2i.UP)
		var warp := _warp_at(map, cell)
		assert_not_null(warp)
		if warp == null:
			continue
		assert_eq(warp.trigger, Warp.Trigger.STEP_ON)
		assert_eq(warp.direction, Vector2i.DOWN)
		if built:
			assert_false(warp.is_coming_soon(),
				"route_3 existe : relancer tools/build_mt_moon.gd")
			assert_eq(warp.target_map, &"route_3")
			assert_eq(warp.target_spawn, StringName("from_mt_moon_%s" % ["w", "e"][i]))
			assert_eq(warp.facing, Vector2i.DOWN)
		else:
			assert_true(warp.is_coming_soon(), "repli « Route 3 — À venir »")
			assert_eq(warp.target_spawn, spawn)
			assert_eq(warp.facing, Vector2i.UP)
	if not built:
		pending("route_3 pas encore construite (T8) : entrée en repli « à venir »")


func test_exit_ladder_leads_to_route_4_or_is_coming_soon() -> void:
	var map: GameMap = _maps.get(&"mt_moon_b2f")
	if map == null:
		fail_test("mt_moon_b2f absente")
		return
	var warp := _warp_at(map, Vector2i(11, 29))
	assert_not_null(warp, "échelle de sortie")
	if warp == null:
		return
	assert_eq(warp.direction, Vector2i.ZERO)
	assert_true(map.has_spawn(&"arrivee_s"))
	if MapCatalog.has_map(&"route_4"):
		assert_false(warp.is_coming_soon(), "route_4 existe : relancer tools/build_mt_moon.gd")
		assert_eq(warp.target_map, &"route_4")
		assert_eq(warp.target_spawn, &"from_mt_moon")
		assert_eq(warp.facing, Vector2i.RIGHT)
	else:
		assert_true(warp.is_coming_soon(), "repli « Route 4 — À venir »")
		assert_eq(warp.target_spawn, &"arrivee_s")
		assert_eq(map.get_spawn_cell(&"arrivee_s"), Vector2i(11, 30))
		pending("route_4 (sas) pas encore construite (T8) : sortie en repli « à venir »")


## Toutes les cases praticables des trois étages sont reliées à l'entrée du 1F, à pied et par
## les échelles (le graphe est non orienté : de partout, on peut revenir à l'entrée).
func test_every_walkable_cell_connects_back_to_the_entrance() -> void:
	if _maps.size() != FLOORS.size():
		fail_test("étages manquants")
		return
	var start := [&"mt_moon_1f", (_maps[&"mt_moon_1f"] as GameMap).get_spawn_cell(
		&"from_route_3_w")]
	var seen: Dictionary = {}
	var queue: Array = [start]
	seen[start] = true
	while not queue.is_empty():
		var node: Array = queue.pop_front()
		var map: GameMap = _maps[node[0]]
		var grid := map.get_grid()
		var nexts: Array = []
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var cell: Vector2i = node[1] + step
			if grid.is_in_bounds(cell) and not grid.is_solid(cell):
				nexts.append([node[0], cell])
		var warp := _warp_at(map, node[1])
		if warp != null and _maps.has(warp.target_map):
			var target: GameMap = _maps[warp.target_map]
			nexts.append([warp.target_map, target.get_spawn_cell(warp.target_spawn)])
		for next: Array in nexts:
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	for map_id: StringName in _maps:
		var grid := (_maps[map_id] as GameMap).get_grid()
		var missing: Array[Vector2i] = []
		var size: Vector2i = FLOORS[map_id][1]
		for y: int in size.y:
			for x: int in size.x:
				var cell := Vector2i(x, y)
				if not grid.is_solid(cell) and not seen.has([map_id, cell]):
					missing.append(cell)
		assert_eq(missing, [] as Array[Vector2i], "%s : cases coupées de l'entrée" % map_id)


# --- Données liées --------------------------------------------------------------------------


func test_battle_decors_gallery_and_chamber() -> void:
	var catalog := BattleDecorCatalog.load_file()
	for map_id: StringName in FLOORS:
		assert_eq(catalog.default_for(map_id).id, &"mt_moon_galerie", String(map_id))
	assert_eq(catalog.pick(&"mt_moon_b2f", Vector2i(26, 10)).id, &"mt_moon_galerie")
	assert_eq(catalog.pick(&"mt_moon_b2f", Vector2i(25, 16)).id, &"mt_moon_galerie",
		"gravats au-dessus du couloir")
	for cell: Vector2i in [Vector2i(25, 20), Vector2i(29, 24), Vector2i(25, 31),
			Vector2i(14, 30), Vector2i(36, 34)]:
		assert_eq(catalog.pick(&"mt_moon_b2f", cell).id, &"mt_moon_chambre", str(cell))


func test_zone_holds_the_three_floors() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for map_id: StringName in FLOORS:
		assert_eq(zones.zone_of(map_id), &"mt_moon", String(map_id))
