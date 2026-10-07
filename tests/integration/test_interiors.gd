extends GutTest
## Cartes d'intérieur (jalon 2 §4.3, §4.4, §4.5, §4.7) : invariants du §4.8 pour chaque pièce.
## Taille, structure, spawns et warps du plan, accessibilité de toutes les cases
## praticables (aucune poche), murs et mobilier inaccessibles, cases réservées libres,
## tapis de sortie sur la dernière rangée praticable.
## DA.3 (docs/tech/integration-da-bourg-route1.md) : pièces **peintes** (enveloppe, meubles
## peints, tapis à plat dans `GroundDecals`, murs en `blocked_cells`) ; la géométrie est celle
## du jalon 2, figée dans `tests/fixtures/maps/<carte>_logic.txt` (test_bourg_interiors_painted).
## Les ancres des meubles se comparent à la case en bas à gauche de leurs cases solides
## (convention du jalon 2), que le pied de l'image soit au milieu ou non.

const BACK := "back"
const BOX := "box"
const STEP_ON := Warp.Trigger.STEP_ON
const PUSH := Warp.Trigger.PUSH

## Plans : carte → spécification.
##   walls : gabarit (BACK : fond y 0–1 ; BOX : quatre côtés), openings : trous du mur bas.
##   from : spawn de départ du test d'accessibilité ; reserved : cases libres (PNJ futurs,
##   Chen au labo en 3B) ; npcs : cases réservées au jalon 2, occupées au jalon 3A par le
##   bon PNJ (data/npcs/<carte>.json).
##   warps : nœud → [case, déclenchement, direction, carte cible, spawn cible].
const PLANS: Dictionary = {
	&"player_house_2f": {
		"size": Vector2i(14, 10), "walls": BOX, "openings": [Vector2i(6, 9), Vector2i(7, 9)],
		"from": &"stairs", "mat": null, "reserved": [],
		"spawns": {&"start": Vector2i(3, 4), &"stairs": Vector2i(6, 8)},
		"warps": {
			&"StairsDownW": [Vector2i(6, 9), STEP_ON, Vector2i.DOWN, &"player_house_1f", &"stairs"],
			&"StairsDownE": [Vector2i(7, 9), STEP_ON, Vector2i.DOWN, &"player_house_1f", &"stairs"],
		},
	},
	&"player_house_1f": {
		"size": Vector2i(14, 10), "walls": BOX, "openings": [],
		"from": &"entrance", "mat": Vector2i(7, 8), "reserved": [],
		"npcs": {Vector2i(7, 4): &"mom"},
		"spawns": {&"entrance": Vector2i(7, 8), &"stairs": Vector2i(2, 4), &"heal": Vector2i(7, 5)},
		"warps": {
			&"StairsUpW": [Vector2i(1, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			&"StairsUpE": [Vector2i(2, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			&"Exit": [Vector2i(7, 8), PUSH, Vector2i.DOWN, &"pallet_town", &"player_house_door"],
		},
	},
	&"rival_house": {
		"size": Vector2i(18, 11), "walls": BOX, "openings": [],
		# Rival (sur le tapis de sa chambre).
		"from": &"entrance", "mat": Vector2i(9, 9), "reserved": [],
		"npcs": {Vector2i(13, 4): &"rival"},
		"spawns": {&"entrance": Vector2i(9, 9)},
		"warps": {
			&"Exit": [Vector2i(9, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"rival_house_door"],
		},
	},
	&"oak_lab": {
		"size": Vector2i(16, 11), "walls": BOX, "openings": [],
		"from": &"entrance", "mat": Vector2i(7, 9),
		# Chen (au-dessus du grand tapis) ; devant la table des starters : libres en 3A.
		"reserved": [Vector2i(8, 4), Vector2i(11, 6)],
		"npcs": {Vector2i(5, 3): &"maya"},
		"spawns": {&"entrance": Vector2i(7, 9)},
		"warps": {
			&"Exit": [Vector2i(7, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"oak_lab_door"],
		},
	},
}

var _maps: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in PLANS:
		var scene := load(MapCatalog.scene_path(map_id)) as PackedScene
		if scene == null:
			continue
		var map := scene.instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _is_wall(plan: Dictionary, cell: Vector2i) -> bool:
	var size: Vector2i = plan["size"]
	var wall := cell.y <= 1
	if plan["walls"] == BOX:
		wall = wall or cell.x == 0 or cell.x == size.x - 1 or cell.y == size.y - 1
	return wall and not cell in (plan["openings"] as Array)


func test_every_interior_exists() -> void:
	for map_id: StringName in PLANS:
		assert_true(MapCatalog.has_map(map_id), String(map_id))
		assert_true(_maps.has(map_id), "%s se charge" % map_id)


func test_metadata_and_structure() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var plan: Dictionary = PLANS[map_id]
		assert_eq(map.map_id, map_id)
		assert_true(map.interior, "%s est un intérieur" % map_id)
		assert_eq(map.size, plan["size"], String(map_id))
		assert_eq(map.get_grid().get_size(), plan["size"], String(map_id))
		assert_eq(map.display_name, "Bourg Palette")
		assert_eq(map.region, "Kanto")
		# DA.3 : enveloppe peinte à 1:1 sous les personnages, aucune tuile.
		var shell := map.get_node_or_null(^"Shell") as Sprite2D
		assert_not_null(shell, "%s/Shell" % map_id)
		if shell != null:
			assert_eq(shell.texture.get_size(), Vector2(map.size * Grid.TILE_SIZE), String(map_id))
			assert_lt(shell.z_index, 0)
		for child: Node in map.get_children():
			assert_false(child is TileMapLayer, "%s : tuiles %s" % [map_id, child.name])
		for path: String in ["Warps", "Spawns", "Triggers", "GroundDecals"]:
			assert_not_null(map.get_node_or_null(path), "%s/%s" % [map_id, path])
		assert_true(map.get_entities().y_sort_enabled)


func test_spawns_of_plan() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var spawns: Dictionary = PLANS[map_id]["spawns"]
		assert_eq(map.get_node(^"Spawns").get_child_count(), spawns.size(), String(map_id))
		for spawn_name: StringName in spawns:
			assert_true(map.has_spawn(spawn_name), "%s : spawn %s" % [map_id, spawn_name])
			assert_eq(map.get_spawn_cell(spawn_name), spawns[spawn_name],
				"%s : spawn %s" % [map_id, spawn_name])


func test_warps_of_plan() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var warps: Dictionary = PLANS[map_id]["warps"]
		assert_eq(map.get_warps().size(), warps.size(), "%s : nombre de warps" % map_id)
		for warp_name: StringName in warps:
			var spec: Array = warps[warp_name]
			var point := map.get_node_or_null(NodePath("Warps/" + String(warp_name))) as WarpPoint
			assert_not_null(point, "%s/%s" % [map_id, warp_name])
			if point == null:
				continue
			var label := "%s/%s" % [map_id, warp_name]
			assert_eq(point.get_cell(), spec[0], label)
			assert_eq(point.trigger, spec[1], label)
			assert_eq(point.direction, spec[2], label)
			assert_eq(point.target_map, spec[3], label)
			assert_eq(point.target_spawn, spec[4], label)
			assert_eq(map.get_warps().get_at(spec[0]).size(), 1, "%s dans la table" % label)


func test_every_walkable_cell_is_reachable() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var grid := map.get_grid()
		var from := map.get_spawn_cell(PLANS[map_id]["from"])
		var reachable := grid.find_reachable(from)
		var walkable := 0
		for y: int in map.size.y:
			for x: int in map.size.x:
				var cell := Vector2i(x, y)
				# Cases occupées par un PNJ (jalon 3A) : praticables mais pas atteignables.
				if not grid.is_solid(cell) and not grid.is_water(cell) \
						and not grid.is_occupied(cell):
					walkable += 1
					assert_true(reachable.has(cell), "%s : poche en %s" % [map_id, cell])
		assert_eq(reachable.size(), walkable, "%s : cases atteignables" % map_id)


func test_walls_and_furniture_are_not_reachable() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var plan: Dictionary = PLANS[map_id]
		var grid := map.get_grid()
		var reachable := grid.find_reachable(map.get_spawn_cell(plan["from"]))
		for y: int in map.size.y:
			for x: int in map.size.x:
				var cell := Vector2i(x, y)
				if _is_wall(plan, cell):
					assert_true(grid.is_solid(cell), "%s : mur en %s" % [map_id, cell])
					assert_false(reachable.has(cell), "%s : mur atteint en %s" % [map_id, cell])
		var furniture := 0
		for child: Node in map.get_entities().get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				furniture += 1
				assert_true(grid.is_solid(cell), "%s : %s solide en %s" % [map_id, prop.name, cell])
				assert_false(reachable.has(cell), "%s : %s atteint en %s" % [map_id, prop.name, cell])
		assert_gt(furniture, 0, "%s est meublé" % map_id)


func test_reserved_cells_are_free_and_reachable() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var plan: Dictionary = PLANS[map_id]
		var grid := map.get_grid()
		var reachable := grid.find_reachable(map.get_spawn_cell(plan["from"]))
		for cell: Vector2i in plan["reserved"]:
			assert_false(grid.is_solid(cell), "%s : réservée %s libre" % [map_id, cell])
			assert_false(grid.is_occupied(cell), "%s : réservée %s inoccupée" % [map_id, cell])
			assert_true(reachable.has(cell), "%s : réservée %s atteignable" % [map_id, cell])


func test_reserved_cells_now_hold_the_right_npc() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var npcs: Dictionary = PLANS[map_id].get("npcs", {})
		for cell: Vector2i in npcs:
			var npc := map.get_grid().get_occupant(cell) as Npc
			assert_not_null(npc, "%s : PNJ en %s" % [map_id, cell])
			if npc != null:
				assert_eq(npc.get_id(), npcs[cell], "%s : PNJ en %s" % [map_id, cell])
				assert_false(map.get_grid().is_solid(cell), "%s : %s praticable" % [map_id, cell])


func test_warp_cells_are_walkable() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var grid := map.get_grid()
		var reachable := grid.find_reachable(map.get_spawn_cell(PLANS[map_id]["from"]))
		for warp: Warp in map.get_warps().get_all():
			assert_false(grid.is_solid(warp.cell), "%s : warp %s praticable" % [map_id, warp.cell])
			assert_true(reachable.has(warp.cell), "%s : warp %s atteint" % [map_id, warp.cell])


func test_exit_mat_on_last_walkable_row() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var plan: Dictionary = PLANS[map_id]
		if plan["mat"] == null:
			continue
		var mat: Vector2i = plan["mat"]
		var last_row: int = map.size.y - (2 if plan["walls"] == BOX else 1)
		assert_eq(mat.y, last_row, "%s : tapis sur la dernière rangée" % map_id)
		# Le paillasson est peint dans l'enveloppe (DA.3).
		var exit := map.get_warps().find_on_push(mat, Vector2i.DOWN)
		assert_not_null(exit, "%s : sortie en poussant vers le bas" % map_id)
		# Le pas vers le bas est impossible : la poussée déclenche la sortie.
		assert_eq(map.get_grid().get_step_target(mat, Vector2i.DOWN), mat)


func test_stairs_are_enclosed_so_arrival_does_not_bounce_back() -> void:
	# Les cases d'escalier d'une chambre ne sont accessibles qu'en marchant vers elles :
	# en y arrivant d'en bas, on continue dans la pièce sans rebrousser chemin.
	var map: GameMap = _maps[&"player_house_2f"]
	var grid := map.get_grid()
	for cell: Vector2i in [Vector2i(6, 9), Vector2i(7, 9)]:
		assert_eq(grid.get_step_target(cell, Vector2i.DOWN), cell, "bord de carte sous %s" % cell)
	# Les marches qui descendent sont peintes dans l'enveloppe (DA.3).
	var first := _maps[&"player_house_1f"] as GameMap
	# Haut de l'escalier du rez-de-chaussée : solide ; les marches du bas portent les warps.
	for cell: Vector2i in [Vector2i(1, 2), Vector2i(2, 2)]:
		assert_true(first.get_grid().is_solid(cell), "haut de l'escalier %s" % cell)


func test_player_room_follows_reference_layout() -> void:
	# Agencement de la référence de Kevin (§4.3), tolérance ±1 case sur le mobilier.
	var map: GameMap = _maps[&"player_house_2f"]
	# DA.3 : le meuble télé du mur est (12, 4..5) = petite étagère + commode (SideCabinet).
	var expected := {
		&"Bed": Vector2i(1, 4), &"Desk": Vector2i(6, 2), &"DeskChair": Vector2i(7, 3),
		&"Bookshelf": Vector2i(9, 3), &"SideCabinet": Vector2i(12, 5),
		&"LowCabinet": Vector2i(1, 8), &"PokeballCrate": Vector2i(10, 8),
	}
	for prop_name: StringName in expected:
		var prop := map.get_entities().get_node_or_null(NodePath(prop_name)) as WorldProp
		assert_not_null(prop, String(prop_name))
		if prop == null:
			continue
		var delta: Vector2i = _bottom_left(prop) - expected[prop_name]
		assert_true(absi(delta.x) <= 1 and absi(delta.y) <= 1,
			"%s en %s" % [prop_name, prop.get_anchor_cell()])


func test_rugs_are_flat_in_ground_decals_not_in_entities() -> void:
	var rugs := 0
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		for child: Node in map.get_entities().get_children():
			assert_false(_is_rug(child), "%s : tapis %s dans Entities" % [map_id, child.name])
		for child: Node in map.get_node(^"GroundDecals").get_children():
			assert_true(_is_rug(child), String(child.name))
			assert_true((child as WorldProp).get_solid_cells().is_empty(), "tapis traversable")
			rugs += 1
	# DA.3 (prototype validé) : chambre : Poké Ball ; rez-de-chaussée : plaid, salon ;
	# rival : chambre ; labo : Poké Ball, rouge. Tapis de l'escalier et paillassons : enveloppe.
	assert_eq(rugs, 6, "tapis des quatre intérieurs")


func test_player_room_rugs_follow_reference() -> void:
	var decals := (_maps[&"player_house_2f"] as GameMap).get_node(^"GroundDecals")
	var rug := decals.get_node_or_null(^"RugPokeball") as WorldProp
	assert_not_null(rug, "RugPokeball")
	if rug != null:
		# Grand tapis Poké Ball sur (5..8, 4..6), comme au jalon 2.
		# À un demi-pixel près (image de hauteur impaire, pied arrondi).
		assert_almost_eq(_rug_centre(rug), Vector2(7.0, 5.5) * Grid.TILE_SIZE, Vector2.ONE)


func _is_rug(node: Node) -> bool:
	return node.scene_file_path.get_file().begins_with("int_tapis_")


## Centre de l'image d'un tapis (pixels de la carte).
func _rug_centre(rug: WorldProp) -> Vector2:
	var sprite := rug.get_node(^"%Sprite") as Sprite2D
	return ((rug.transform * sprite.transform) * sprite.get_rect()).get_center()


## Case en bas à gauche des cases solides d'un meuble (ancre du jalon 2).
func _bottom_left(prop: WorldProp) -> Vector2i:
	var cells := prop.get_solid_cells()
	if cells.is_empty():
		return prop.get_anchor_cell()
	var corner := Vector2i(cells[0].x, cells[0].y)
	for cell: Vector2i in cells:
		corner = Vector2i(mini(corner.x, cell.x), maxi(corner.y, cell.y))
	return corner


## Ancres attendues (tolérance ±1 case, écarts documentés dans tools/build_interiors.gd et
## tools/build_painted_interiors.gd).
func _assert_layout(map_id: StringName, expected: Dictionary) -> void:
	var map: GameMap = _maps[map_id]
	for prop_name: StringName in expected:
		var prop := map.get_entities().get_node_or_null(NodePath(prop_name)) as WorldProp
		assert_not_null(prop, "%s/%s" % [map_id, prop_name])
		if prop == null:
			continue
		var delta: Vector2i = _bottom_left(prop) - expected[prop_name]
		assert_true(absi(delta.x) <= 1 and absi(delta.y) <= 1,
			"%s/%s en %s" % [map_id, prop_name, _bottom_left(prop)])


func test_rival_house_follows_reference_layout() -> void:
	_assert_layout(&"rival_house", {
		&"Fridge": Vector2i(1, 2), &"Kitchen": Vector2i(2, 2), &"Stove": Vector2i(5, 2),
		# DA.3 : télé murale de l'ouest (1, 6..7) → petite étagère et lampe (LivingLamp).
		&"Stairs": Vector2i(7, 4), &"DiningTable": Vector2i(2, 5), &"LivingLamp": Vector2i(1, 7),
		&"Sofa": Vector2i(3, 7), &"CoffeeTable": Vector2i(3, 8),
		&"CornerDesk": Vector2i(11, 3), &"GamerChair": Vector2i(12, 3),
		&"Dresser": Vector2i(13, 2), &"Bed": Vector2i(15, 4), &"Nightstand": Vector2i(16, 5),
		&"CoatRack": Vector2i(11, 7), &"ShoeRack": Vector2i(11, 9),
		&"BathroomSink": Vector2i(13, 7), &"Shower": Vector2i(16, 8),
	})


func test_rival_house_partitions_and_blocked_stairs() -> void:
	var grid := (_maps[&"rival_house"] as GameMap).get_grid()
	var solid: Array[Vector2i] = [
		Vector2i(10, 2), Vector2i(10, 3), Vector2i(10, 4),  # cloison de la chambre
		Vector2i(7, 7), Vector2i(7, 8), Vector2i(7, 9),  # muret ouest du couloir
		Vector2i(10, 7), Vector2i(10, 8), Vector2i(10, 9),  # muret est du couloir
	]
	for x: int in range(13, 17):
		solid.append(Vector2i(x, 6))  # cloison de la salle de bain
	for y: int in range(2, 5):
		for x: int in range(7, 10):
			solid.append(Vector2i(x, y))  # escalier décoratif, bloqué
	for cell: Vector2i in solid:
		assert_true(grid.is_solid(cell), "solide en %s" % cell)
	# Couloir d'entrée ouvert au nord ; salle de bain ouverte par (12, 8).
	for cell: Vector2i in [Vector2i(8, 6), Vector2i(9, 6), Vector2i(12, 8), Vector2i(11, 8)]:
		assert_false(grid.is_solid(cell), "libre en %s" % cell)
	# Pas d'étage : aucun escalier ne mène ailleurs.
	assert_eq((_maps[&"rival_house"] as GameMap).get_warps().size(), 1)


func test_lab_follows_reference_layout() -> void:
	_assert_layout(&"oak_lab", {
		&"Aquarium": Vector2i(1, 2), &"Incubator": Vector2i(2, 3), &"Computers": Vector2i(4, 2),
		&"OakDesk": Vector2i(7, 2), &"DeskChair": Vector2i(8, 3),
		&"FileCabinet": Vector2i(10, 2), &"Bookshelf": Vector2i(11, 3),
		&"Fridge": Vector2i(13, 2), &"DisplayCase": Vector2i(14, 4),
		&"LongCounter": Vector2i(1, 5), &"StarterTable": Vector2i(11, 5),
		# DA.3 : canapé de côté (1, 6..7) → classeur et étagère (WestShelf) ; écran mural
		# (14, 6..7) → seconde vitrine (DisplayCaseEast).
		&"WestShelf": Vector2i(2, 7), &"CoffeeTable": Vector2i(3, 7), &"Bench": Vector2i(11, 8),
		&"DisplayCaseEast": Vector2i(14, 7), &"Stairs": Vector2i(1, 9), &"Stool": Vector2i(12, 7),
	})


func test_lab_starter_table_and_blocked_stairs() -> void:
	var map: GameMap = _maps[&"oak_lab"]
	var grid := map.get_grid()
	var table := map.get_entities().get_node(^"StarterTable") as WorldProp
	assert_eq(table.get_solid_cells().size(), 6, "table des starters 3 × 2")
	for cell: Vector2i in table.get_solid_cells():
		assert_true(grid.is_solid(cell), "table en %s" % cell)
	for y: int in range(8, 10):
		for x: int in range(1, 4):
			assert_true(grid.is_solid(Vector2i(x, y)), "escalier bloqué en %s" % Vector2i(x, y))
	assert_eq(map.get_warps().size(), 1, "seule sortie : le tapis")


## Jalon 4 (§13.6) : déclencheur LabExit sur le tapis de sortie, de tous côtés, scène
## oak_lab_exit ; seul déclencheur des intérieurs.
func test_lab_exit_trigger_on_the_mat() -> void:
	var map: GameMap = _maps[&"oak_lab"]
	var point := map.get_node_or_null(^"Triggers/LabExit") as EventTriggerPoint
	assert_not_null(point, "Triggers/LabExit")
	assert_eq(map.get_node(^"Triggers").get_child_count(), 1)
	assert_eq(map.get_triggers().size(), 1)
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var trigger := map.get_triggers().find_on_step(Vector2i(7, 9), direction)
		assert_not_null(trigger, "pas vers %s" % direction)
		if trigger != null:
			assert_eq(trigger.cutscene_id, &"oak_lab_exit")
	assert_not_null(map.get_warps().find_on_push(Vector2i(7, 9), Vector2i.DOWN), "warp PUSH")
	for map_id: StringName in _maps:
		if map_id != &"oak_lab":
			assert_true((_maps[map_id] as GameMap).get_triggers().is_empty(), String(map_id))


func test_lab_fits_the_screen() -> void:
	# 16 × 11 = 1536 × 1056 : la pièce tient dans la vue du S24 et de la référence.
	var rect := (_maps[&"oak_lab"] as GameMap).get_pixel_rect()
	assert_eq(rect, Rect2i(0, 0, 1536, 1056))
	assert_true(CameraFraming.is_static(rect, Vector2(2340, 1080)))
	assert_true(CameraFraming.is_static(rect, Vector2(1920, 1080)))


## Arène du combat du labo (jalon-04.md §14.4) : le tapis Poké Ball, 4 × 3 cases en (6, 5),
## sol dégagé ; les autres pièces n'en ont pas.
func test_lab_battle_arena_is_the_pokeball_rug() -> void:
	var lab: GameMap = _maps[&"oak_lab"]
	assert_eq(lab.battle_arena, Rect2i(6, 5, 4, 3))
	assert_eq(lab.get_battle_arena_rect(), Rect2(576, 480, 384, 288))
	var rug := lab.get_node(^"GroundDecals/RugPokeball") as WorldProp
	assert_almost_eq(_rug_centre(rug), Vector2(lab.get_battle_arena_rect().get_center()),
		Vector2.ONE, "le tapis est l'arène")
	for y: int in range(5, 8):
		for x: int in range(6, 10):
			assert_false(lab.get_grid().is_solid(Vector2i(x, y)), "arène dégagée %s" % [
				Vector2i(x, y)])
	for map_id: StringName in _maps:
		if map_id != &"oak_lab":
			assert_false((_maps[map_id] as GameMap).get_battle_arena_rect().has_area(), map_id)
