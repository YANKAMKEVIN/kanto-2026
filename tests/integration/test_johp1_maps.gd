extends GutTest
## Arc des Pierres, JOHP1 (`docs/tech/jalon-joh-pierres.md` §3.1) : les quatre cartes et la variante
## ARC de la Route 36, relues contre leurs grilles (qui font foi) : cases, passages, arrivées,
## examens, déclencheurs, dalles, porte du fond, Corde Sortie.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const MAPS: Array[StringName] = [&"ruins_of_alph", &"alph_tent", &"alph_gallery", &"alph_chamber"]
const QUEST: StringName = &"johto_stones_quest"

var _cache: Dictionary = {}


func after_all() -> void:
	for map: Variant in _cache.values():
		(map as Node).free()
	_cache.clear()



func test_ruins_are_painted_without_placeholders() -> void:
	for map_id: StringName in [&"ruins_of_alph", &"alph_gallery", &"alph_chamber"]:
		var map := _map(map_id)
		assert_not_null(map.get_node_or_null(^"PaintedGround"), String(map_id))
		assert_false(map.get_node(^"Ground").visible, "%s : tuiles masquées" % map_id)
		for child: Node in map.get_node(^"Decor").get_children():
			assert_false(child is Polygon2D, "%s : aplat %s" % [map_id, child.name])
	var tent := _map(&"alph_tent")
	assert_not_null(tent.get_node_or_null(^"JohAmbAlphaFond"))
	assert_eq(tent.get_node(^"Decor").get_child_count(), 0, "plus d'aplat provisoire")
	assert_not_null(_map(&"ruins_of_alph").get_node_or_null(^"Entities/JohAmbTente"))


func test_gates_of_the_ruins_show_their_paintings() -> void:
	var door := _map(&"alph_gallery").get_node(^"Entities/PorteFond")
	assert_not_null(door.get_node_or_null(^"JohAmbAlphaImage"), "porte du fond")
	var stone := _map(&"alph_chamber").get_node(^"Decor/PierreMemoire")
	assert_not_null(stone.get_node_or_null(^"JohAmbAlphaImage"), "Pierre Mémoire")

func _map(id: StringName) -> GameMap:
	if not _cache.has(id):
		var map := (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate() as GameMap
		_cache[id] = map
		map.get_grid()
	return _cache[id]


func _plan(id: StringName, variant: String = "") -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % id, variant), plan.error)
	return plan


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	for warp: Warp in map.get_warps().get_all():
		if warp.cell == cell:
			return warp
	return null


func _gate(map: GameMap, path: NodePath) -> FlagGate:
	return map.get_node_or_null(path) as FlagGate


func test_size_and_cells_follow_the_grids() -> void:
	for id: StringName in MAPS:
		var map := _map(id)
		var plan := _plan(id)
		assert_eq(map.size, Vector2i(plan.width, plan.height), String(id))
		var grid := map.get_grid()
		var blocked: Dictionary = {}
		for key: String in plan.positions:
			var entry: Dictionary = plan.positions[key]
			if entry["kind"] in ["cache", "panneau"]:
				for cell: Vector2i in entry["cells"]:
					blocked[cell] = true
		var mismatches: Array[Vector2i] = []
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				# Bord nord (leçon du JOH1) : la rangée 0 des Ruines reste bloquée.
				var free: bool = plan.is_walkable(cell) and not blocked.has(cell) \
					and not (id == &"ruins_of_alph" and y == 0)
				if free == grid.is_solid(cell):
					mismatches.append(cell)
		assert_eq(mismatches, [] as Array[Vector2i], "%s : cases en désaccord avec la grille" % id)


func test_every_warp_reaches_a_free_arrival() -> void:
	for id: StringName in MAPS:
		for warp: Warp in _map(id).get_warps().get_all():
			assert_false(warp.is_coming_soon(), "%s : aucun passage « À venir »" % id)
			if warp.target_map == &"route_36":
				continue
			var target := _map(warp.target_map)
			assert_true(target.has_spawn(warp.target_spawn), "%s → %s" % [id, warp.target_spawn])
			assert_false(target.get_grid().is_solid(target.get_spawn_cell(warp.target_spawn)))


func test_route_36_arc_variant_is_laid_on_the_map() -> void:
	var road := _map(&"route_36")
	var ruins := _map(&"ruins_of_alph")
	for i: int in 2:
		var cell := Vector2i(40 + i, 19)
		assert_false(road.get_grid().is_solid(cell), "bord sud ouvert")
		var down := _warp_at(road, cell)
		assert_not_null(down, str(cell))
		assert_eq(down.target_map, &"ruins_of_alph")
		assert_eq(ruins.get_spawn_cell(down.target_spawn), Vector2i(17 + i, 1), "case à case, rangée 1")
		var up := _warp_at(ruins, Vector2i(17 + i, 1))
		assert_not_null(up, "retour")
		assert_eq(up.target_map, &"route_36")
		assert_eq(road.get_spawn_cell(up.target_spawn), cell)
	var fence := _gate(road, ^"Entities/Johp1Barriere")
	assert_not_null(fence, "barrière de chantier")
	assert_eq(fence.unless_flags, [QUEST] as Array[StringName])
	assert_eq(fence.blocking_cells, [Vector2i(40, 18), Vector2i(41, 18)] as Array[Vector2i])
	var point := road.get_node_or_null(^"Triggers/Johp1BarriereRuines") as EventTriggerPoint
	assert_not_null(point)
	assert_eq(point.get_cells().size(), 2, "toute la largeur du chemin")
	assert_eq(point.direction, Vector2i.DOWN)
	assert_eq(point.cutscene_id, &"route_36_ruins_gate")


func test_gallery_tiles_cover_the_three_rows() -> void:
	var map := _map(&"alph_gallery")
	var plan := _plan(&"alph_gallery")
	var good: Dictionary = {Vector2i(16, 10): &"alph_tile_good_1", Vector2i(18, 7): &"alph_tile_good_2",
		Vector2i(15, 4): &"alph_tile_good_3"}
	for row: String in ["dalles_r1", "dalles_r2", "dalles_r3"]:
		for cell: Vector2i in plan.positions[row]["cells"]:
			var point := map.get_node_or_null("Triggers/Dalle_%d_%d" % [cell.x, cell.y]) as EventTriggerPoint
			assert_not_null(point, str(cell))
			assert_eq(point.cutscene_id, good.get(cell, &"alph_tile_wrong"), str(cell))
			assert_not_null(map.get_node_or_null("Decor/Signe_%d_%d" % [cell.x, cell.y]), "signe %s" % cell)


## Le signe de la bonne dalle est celui du mur de son rang : l'énigme se lit à l'écran.
func test_good_tiles_show_the_sign_of_their_wall() -> void:
	var map := _map(&"alph_gallery")
	var pairs: Dictionary = {^"Decor/Signe_16_10": ^"Decor/Mur1Signe", ^"Decor/Signe_18_7": ^"Decor/Mur2Signe",
		^"Decor/Signe_15_4": ^"Decor/Mur3Signe"}
	var seen: Array[int] = []
	for tile: NodePath in pairs:
		var wall := map.get_node_or_null(pairs[tile]) as AlphGlyph
		assert_not_null(wall, str(pairs[tile]))
		assert_eq((map.get_node(tile) as AlphGlyph).sign_kind, wall.sign_kind, str(tile))
		seen.append(wall.sign_kind)
	assert_eq(seen, [AlphGlyph.Sign.MEMORY, AlphGlyph.Sign.RETURN, AlphGlyph.Sign.BREATH] as Array[int])
	# Chaque rang montre le signe une seule fois.
	for row: Array in [[10, AlphGlyph.Sign.MEMORY], [7, AlphGlyph.Sign.RETURN], [4, AlphGlyph.Sign.BREATH]]:
		var count := 0
		for x: int in range(15, 19):
			if (map.get_node("Decor/Signe_%d_%d" % [x, row[0]]) as AlphGlyph).sign_kind == row[1]:
				count += 1
		assert_eq(count, 1, "rang %d" % row[0])


func test_gallery_door_holds_the_stairs_until_the_last_tile() -> void:
	var door := _gate(_map(&"alph_gallery"), ^"Entities/PorteFond")
	assert_not_null(door)
	assert_eq(door.unless_flags, [&"johto_alph_tiles_done"] as Array[StringName])
	assert_eq(door.blocking_cells, [Vector2i(16, 2), Vector2i(17, 2)] as Array[Vector2i])


func test_only_rubble_cells_bring_encounters() -> void:
	var plan := _plan(&"alph_gallery")
	var grid := _map(&"alph_gallery").get_grid()
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_rubble(cell), plan.at(cell) == "g", "gravats %s" % cell)


func test_escape_rope_leads_to_the_stairs() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), str(caves.get_errors()))
	for id: StringName in [&"alph_gallery", &"alph_chamber"]:
		assert_true(caves.is_cave(id), String(id))
	var exit := caves.escape_target(&"alph_chamber")
	assert_eq(exit.map, &"ruins_of_alph")
	assert_true(_map(&"ruins_of_alph").has_spawn(exit.spawn), "devant l'escalier de la Galerie")


func test_tent_is_an_interior() -> void:
	assert_true(_map(&"alph_tent").interior)
	assert_false(_map(&"alph_gallery").interior, "grotte, pas intérieur")
	assert_eq(_map(&"alph_tent").light_profile, &"interior_warm")
