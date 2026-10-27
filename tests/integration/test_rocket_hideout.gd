extends GutTest
## Repaire Rocket (rocket_hideout_b1f à b4f et cabine, jalon 20 T20, docs/tech/jalon-20.md §2.1,
## §2.4, §2.7.1 ; dossier 23 §13) sur les vraies scènes : **grille de chaque scène = grille
## fonctionnelle** `tools/plans/repaire_*.txt`, lumière `hideout`, catégorie « grotte » (Corde Sortie
## → `from_casino_w`), `SpinTiles` = les flèches et les arrêts de la grille, **chaque dalle mène à
## une case d'arrêt praticable** (celle de la grille), B4F coupé en deux moitiés à pied (la porte
## du bureau fermée), deux secteurs au B1F, escaliers et ascenseur aller-retour, nœuds. Dresseurs,
## objets, Clé, Giovanni : T21.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAPS: Dictionary[StringName, String] = {
	&"rocket_hideout_b1f": "repaire_b1f", &"rocket_hideout_b2f": "repaire_b2f",
	&"rocket_hideout_b3f": "repaire_b3f", &"rocket_hideout_b4f": "repaire_b4f",
	&"rocket_hideout_elevator": "repaire_ascenseur",
}
const SIZES: Dictionary[StringName, Vector2i] = {
	&"rocket_hideout_b1f": Vector2i(30, 28), &"rocket_hideout_b2f": Vector2i(30, 28),
	&"rocket_hideout_b3f": Vector2i(30, 28), &"rocket_hideout_b4f": Vector2i(30, 24),
	&"rocket_hideout_elevator": Vector2i(6, 8),
}
const ARROWS: Dictionary[String, Vector2i] = {
	"<": Vector2i.LEFT, ">": Vector2i.RIGHT, "^": Vector2i.UP, "v": Vector2i.DOWN,
}
const DOOR_CELLS: Array[Vector2i] = [Vector2i(24, 11), Vector2i(25, 11)]
const NODE_BUDGET: int = 3000

var _maps: Dictionary[StringName, GameMap] = {}
var _plans: Dictionary[StringName, PlanGrid] = {}


func before_all() -> void:
	for map_id: StringName in MAPS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % MAPS[map_id]), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


## Terrain à pied : le relief de la scène, la porte du bureau fermée (occupée par sa FlagGate).
func _terrain(map_id: StringName, door_closed: bool = true) -> GridWorld:
	var grid := GridPaths.relief(_maps[map_id].get_grid(), SIZES[map_id])
	if map_id == &"rocket_hideout_b4f":
		for cell: Vector2i in DOOR_CELLS:
			grid.set_solid(cell, door_closed)
	return grid


func test_metadata_light_and_cave_category() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var caves := CaveLibrary.new()
	assert_true(caves.load_file(), str(caves.get_errors()))
	var interiors := MapCatalog.load_interiors()
	for map_id: StringName in MAPS:
		var map := _maps[map_id]
		assert_eq(map.map_id, map_id)
		assert_eq(map.size, SIZES[map_id], String(map_id))
		assert_false(map.interior, "%s : grotte, pas un intérieur (compagnon visible)" % map_id)
		assert_false(interiors.has(map_id), "%s : pas dans interiors.json" % map_id)
		assert_eq(map.light_profile, &"hideout", String(map_id))
		assert_eq(lighting.get_map_profile(map_id), &"hideout", String(map_id))
		assert_true(caves.is_cave(map_id), "%s : catégorie grotte" % map_id)
		assert_eq(caves.cave_of(map_id), &"rocket_hideout")
		assert_false(caves.is_dark(map_id), "aucune obscurité punitive")
		if map_id == &"rocket_hideout_elevator":
			# La cabine reste une coque peinte, aux dimensions de la grille.
			assert_eq((map.get_node(^"Shell") as Sprite2D).texture.get_size(),
				Vector2(SIZES[map_id] * 96), "%s : coque aux dimensions de la grille" % map_id)
		else:
			# Étages en modules (série 22 bis, Q-2) : sol peint, aucune enveloppe, aucune couche
			# logique du kit (la collision vient de `blocked_cells`, voir la grille ci-dessous).
			assert_null(map.get_node_or_null(^"Shell"), "%s : plus d'enveloppe" % map_id)
			assert_not_null(map.get_node_or_null(^"PaintedGround"), "%s : sol peint" % map_id)
			assert_null(map.get_node_or_null(^"Ground"), "%s : pas de Ground logique" % map_id)
	var hideout := lighting.get_profile(&"hideout")
	assert_not_null(hideout, "profil hideout")
	assert_eq(caves.get_maps(&"rocket_hideout").size(), 5)


## Arbitrage R-6 (Kevin, 2026-10-26) : le titre « REPAIRE ROCKET » s'affiche en descendant du
## Casino (intérieur, sans titre), puis « CÉLADOPOLE » de nouveau en ressortant en ville.
func test_hideout_title_replaces_the_city_title() -> void:
	for map_id: StringName in MAPS:
		assert_eq(_maps[map_id].display_name, "Repaire Rocket", String(map_id))
	var announcer := ZoneAnnouncer.new()
	assert_true(announcer.should_announce("Céladopole", false), "en ville")
	assert_false(announcer.should_announce("Céladopole", true), "Casino : intérieur")
	assert_true(announcer.should_announce(_maps[&"rocket_hideout_b1f"].display_name, false), "B1F")
	assert_false(announcer.should_announce(_maps[&"rocket_hideout_b2f"].display_name, false), "B2F")
	assert_false(announcer.should_announce("Céladopole", true), "retour au Casino")
	assert_true(announcer.should_announce("Céladopole", false), "de nouveau en ville")


func test_scene_grid_equals_the_functional_grid() -> void:
	for map_id: StringName in MAPS:
		var plan := _plans[map_id]
		var grid := _maps[map_id].get_grid()
		assert_eq(Vector2i(plan.width, plan.height), SIZES[map_id], String(map_id))
		var mismatches := 0
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				# La porte du bureau (B) est praticable dans `Ground` : sa FlagGate occupe la case.
				var solid := not plan.is_walkable(cell) and plan.at(cell) != "B"
				if grid.is_solid(cell) != solid:
					mismatches += 1
					if mismatches <= 5:
						fail_test("%s %s « %s » : solide %s" % [map_id, cell, plan.at(cell),
							grid.is_solid(cell)])
		assert_eq(mismatches, 0, "%s : grille de la scène = grille fonctionnelle" % map_id)


func test_no_wild_encounters_in_the_hideout() -> void:
	# Sol de béton sans rencontre : aucune case d'herbe haute.
	for map_id: StringName in MAPS:
		var grid := _maps[map_id].get_grid()
		for y: int in SIZES[map_id].y:
			for x: int in SIZES[map_id].x:
				assert_false(grid.is_tall_grass(Vector2i(x, y)), "%s (%d, %d)" % [map_id, x, y])


func test_spin_tiles_equal_the_grid() -> void:
	var expected := {&"rocket_hideout_b2f": 43, &"rocket_hideout_b3f": 16}
	for map_id: StringName in MAPS:
		var plan := _plans[map_id]
		var field := _maps[map_id].get_node_or_null(^"SpinTiles") as SpinTileField
		if not expected.has(map_id):
			assert_null(field, "%s : aucune dalle" % map_id)
			assert_eq(plan.cells_of("<>^v").size(), 0)
			continue
		assert_not_null(field, "%s : SpinTiles" % map_id)
		if field == null:
			continue
		assert_true(field.is_in_group(SpinTileField.GROUP))
		assert_eq(field.arrows.size(), expected[map_id], "%s : nombre de dalles" % map_id)
		for character: String in ARROWS:
			for cell: Vector2i in plan.cells_of(character):
				assert_eq(field.arrows.get(cell), ARROWS[character], "%s %s" % [map_id, cell])
		for cell: Vector2i in field.arrows:
			assert_true(ARROWS.has(plan.at(cell)), "%s : %s est une flèche de la grille" % [
				map_id, cell])
		var stops := plan.cells_of("o")
		assert_eq(field.stops.size(), stops.size(), "%s : cases d'arrêt" % map_id)
		for cell: Vector2i in stops:
			assert_true(field.stops.has(cell), "%s : arrêt %s" % [map_id, cell])
		_assert_floor_marks(map_id, plan)


## Une décalcomanie par dalle, orientée comme la flèche de la grille, et un disque par arrêt,
## posés sur leur case (couche du sol, sans emprise).
func _assert_floor_marks(map_id: StringName, plan: PlanGrid) -> void:
	var images := {
		"<": "decal_fleche_repaire_01_gauche", ">": "decal_fleche_repaire_01",
		"^": "decal_fleche_repaire_01_haut", "v": "decal_fleche_repaire_01_bas",
		"o": "decal_arret_repaire_01",
	}
	var found: Dictionary = {}
	for child: Node in _maps[map_id].get_node(^"GroundDecals").get_children():
		var sprite := child.get_node_or_null(^"Sprite") as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var image := sprite.texture.resource_path.get_file().get_basename()
		if not image.begins_with("decal_"):
			continue
		var prop := child as Node2D
		var cell := Vector2i(floori(prop.position.x / 96.0), floori(prop.position.y / 96.0) - 1)
		found[cell] = image
		assert_eq((prop as WorldProp).get_footprint().size(), 0, "%s %s : sans emprise" % [
			map_id, cell])
	var expected := 0
	for character: String in images:
		for cell: Vector2i in plan.cells_of(character):
			expected += 1
			assert_eq(found.get(cell, ""), images[character], "%s %s « %s »" % [map_id, cell,
				character])
	assert_eq(found.size(), expected, "%s : une marque par dalle et par arrêt" % map_id)


func test_every_slide_ends_on_a_walkable_stop_of_the_grid() -> void:
	for map_id: StringName in [&"rocket_hideout_b2f", &"rocket_hideout_b3f"]:
		var plan := _plans[map_id]
		var grid := _maps[map_id].get_grid()
		var field := _maps[map_id].get_node(^"SpinTiles") as SpinTileField
		var walkable := func(cell: Vector2i) -> bool:
			return grid.is_in_bounds(cell) and not grid.is_solid(cell)
		assert_eq(field.check(walkable), PackedStringArray(), "%s : check_field" % map_id)
		var checked := 0
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "dalle":
				continue
			var start := plan.cell_of(id)
			var slide := field.slide_from(start, walkable)
			assert_eq(slide.status, SpinSlide.Status.OK, "%s %s" % [map_id, id])
			var stop := PlanGrid.parse_cells(plan.attr(id, "arret"))[0]
			assert_eq(slide.end, stop, "%s %s : case d'arrêt de la grille (RB)" % [map_id, id])
			assert_true(field.stops.has(slide.end), "%s %s : un disque d'arrêt" % [map_id, id])
			assert_false(grid.is_solid(slide.end), "%s %s : arrêt praticable" % [map_id, id])
			checked += 1
		assert_eq(checked, field.arrows.size(), "%s : un trajet par dalle" % map_id)


func test_b4f_halves_are_disjoint_on_foot() -> void:
	var map_id := &"rocket_hideout_b4f"
	var west_start := _maps[map_id].get_spawn_cell(&"from_b3f")
	var east_start := _maps[map_id].get_spawn_cell(&"from_elevator")
	assert_eq(west_start, Vector2i(19, 11))
	assert_eq(east_start, Vector2i(25, 14))
	for closed: bool in [true, false]:
		var west := GridPaths.distances(_terrain(map_id, closed), [west_start])
		var east := GridPaths.distances(_terrain(map_id, closed), [east_start])
		assert_gt(west.size(), 40, "moitié ouest (porte %s)" % closed)
		assert_gt(east.size(), 40, "moitié est (porte %s)" % closed)
		for cell: Vector2i in west:
			assert_false(east.has(cell), "%s dans les deux moitiés (porte fermée %s)" % [cell,
				closed])
		# Ouest : le sbire de la Clé (11, 2) et la Clé (10, 2) ; est : gardes et couloir sud.
		assert_true(west.has(Vector2i(10, 2)) and west.has(Vector2i(11, 3)))
		assert_true(east.has(Vector2i(24, 12)) and east.has(Vector2i(11, 22)))
	# Le bureau de Giovanni : hors d'atteinte porte fermée, dans la moitié est porte ouverte.
	var shut := GridPaths.distances(_terrain(map_id, true), [east_start])
	var open := GridPaths.distances(_terrain(map_id, false), [east_start])
	for cell: Vector2i in [Vector2i(25, 3), Vector2i(25, 2), Vector2i(25, 10)]:
		assert_false(shut.has(cell), "bureau fermé : %s" % cell)
		assert_true(open.has(cell), "bureau ouvert : %s" % cell)


func test_b4f_office_door_is_a_flag_gate_over_walkable_cells() -> void:
	var map := _maps[&"rocket_hideout_b4f"]
	var gate := map.get_node_or_null(^"Entities/OfficeDoor") as FlagGate
	assert_not_null(gate, "porte du bureau")
	if gate == null:
		return
	assert_eq(gate.unless_flags, [&"rocket_hideout_b4f_door_open"] as Array[StringName])
	assert_eq(gate.blocking_cells, DOOR_CELLS)
	map.apply_flag_gates(null)
	for cell: Vector2i in DOOR_CELLS:
		assert_true(map.get_grid().is_occupied(cell), "fermée : %s occupée" % cell)
	var flags := StoryFlags.new()
	flags.set_flag(&"rocket_hideout_b4f_door_open")
	map.apply_flag_gates(flags)
	for cell: Vector2i in DOOR_CELLS:
		assert_false(map.get_grid().is_occupied(cell), "ouverte : %s libre" % cell)
		assert_false(map.get_grid().is_solid(cell))
	map.apply_flag_gates(null)


func test_b1f_has_two_sectors_separated_on_foot() -> void:
	var map_id := &"rocket_hideout_b1f"
	var map := _maps[map_id]
	var north := GridPaths.distances(_terrain(map_id), [map.get_spawn_cell(&"from_casino")])
	var south := GridPaths.distances(_terrain(map_id), [map.get_spawn_cell(&"from_b2f_south")])
	for cell: Vector2i in north:
		assert_false(south.has(cell), "%s dans les deux secteurs" % cell)
	# Le nord : escalier du B2F, ascenseur, Corde Sortie ; le sud-ouest : second escalier.
	for name: StringName in [&"from_b2f_north", &"from_elevator"]:
		assert_true(north.has(map.get_spawn_cell(name)), "%s dans le secteur nord" % name)
		assert_false(south.has(map.get_spawn_cell(name)))
	assert_true(north.has(Vector2i(11, 14)) and north.has(Vector2i(20, 15)), "Corde, cache")
	assert_true(south.has(Vector2i(9, 17)) and south.has(Vector2i(18, 17)), "sbire 3, objet")


func test_every_arrival_is_walkable_and_named_by_its_pair() -> void:
	var expected := {
		&"rocket_hideout_b1f": [&"from_casino", &"from_b2f_north", &"from_b2f_south",
			&"from_elevator"],
		&"rocket_hideout_b2f": [&"from_b1f_north", &"from_b1f_south", &"from_b3f",
			&"from_elevator"],
		&"rocket_hideout_b3f": [&"from_b2f", &"from_b4f"],
		&"rocket_hideout_b4f": [&"from_b3f", &"from_elevator"],
		&"rocket_hideout_elevator": [&"entrance_w", &"entrance_e"],
	}
	for map_id: StringName in expected:
		for name: StringName in expected[map_id]:
			assert_true(_maps[map_id].has_spawn(name), "%s : %s" % [map_id, name])
			assert_false(_maps[map_id].get_grid().is_solid(_maps[map_id].get_spawn_cell(name)),
				"%s : arrivée %s praticable" % [map_id, name])


func _stairs_of(map: GameMap) -> Array[Warp]:
	var result: Array[Warp] = []
	for warp: Warp in map.get_warps().get_all():
		if warp.target_map != &"rocket_hideout_elevator" and warp.target_map != &"celadon_city":
			result.append(warp)
	return result


func test_stairs_are_two_way_between_floors() -> void:
	var casino := (load(MapCatalog.scene_path(&"celadon_game_corner")) as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(casino)
	var all: Dictionary[StringName, GameMap] = _maps.duplicate()
	all[&"celadon_game_corner"] = casino
	var counted := 0
	for map_id: StringName in _maps:
		if map_id == &"rocket_hideout_elevator":
			continue  # la cabine : test_elevator_doors_and_the_car
		for warp: Warp in _stairs_of(_maps[map_id]):
			counted += 1
			assert_eq(warp.trigger, Warp.Trigger.STEP_ON, "escalier")
			assert_eq(warp.direction, Vector2i.ZERO, "sans direction (J12)")
			var target: GameMap = all[warp.target_map]
			assert_true(target.has_spawn(warp.target_spawn),
				"%s %s → %s/%s" % [map_id, warp.cell, warp.target_map, warp.target_spawn])
			var arrival := target.get_spawn_cell(warp.target_spawn)
			var back: Warp = null
			for other: Warp in target.get_warps().get_all():
				if other.target_map == map_id and Grid.is_cardinal(other.cell - arrival):
					back = other
			assert_not_null(back, "retour de %s/%s vers %s" % [warp.target_map, arrival, map_id])
			if back != null:
				var home := _maps[map_id].get_spawn_cell(back.target_spawn)
				assert_true(Grid.is_cardinal(warp.cell - home),
					"%s : le retour arrive devant l'escalier %s" % [map_id, warp.cell])
	assert_eq(counted, 9, "Casino-B1F, B1F-B2F (×2), B2F-B3F, B3F-B4F, et leurs retours")


func test_elevator_doors_and_the_car() -> void:
	var expected := {&"rocket_hideout_b1f": 19, &"rocket_hideout_b2f": 19,
		&"rocket_hideout_b4f": 15}
	for map_id: StringName in expected:
		var y: int = expected[map_id]
		var left := _maps[map_id].get_warps().find_on_step(Vector2i(24, y), Vector2i.DOWN)
		var right := _maps[map_id].get_warps().find_on_step(Vector2i(25, y), Vector2i.DOWN)
		assert_not_null(left, "%s : porte gauche" % map_id)
		assert_not_null(right, "%s : porte droite" % map_id)
		if left != null and right != null:
			assert_eq([left.target_map, left.target_spawn],
				[&"rocket_hideout_elevator", &"entrance_w"])
			assert_eq([right.target_map, right.target_spawn],
				[&"rocket_hideout_elevator", &"entrance_e"])
		assert_eq(_maps[map_id].get_spawn_cell(&"from_elevator"), Vector2i(25, y - 1),
			"%s : sortie de la cabine une case devant la porte" % map_id)
	var car := _maps[&"rocket_hideout_elevator"]
	assert_eq(car.get_spawn_cell(&"entrance_w"), Vector2i(2, 2))
	assert_eq(car.get_spawn_cell(&"entrance_e"), Vector2i(3, 2))
	assert_eq(car.get_warps().size(), 2)
	for x: int in [2, 3]:
		var out := car.get_warps().find_on_step(Vector2i(x, 1), Vector2i.UP)
		assert_not_null(out, "porte de cabine (%d, 1)" % x)
		if out != null:
			assert_eq([out.target_map, out.target_spawn],
				[&"rocket_hideout_b1f", &"from_elevator"])
	# Panneau d'étages : un seul point d'examen `elevator_panel`, lu depuis (1, 2) vers le nord.
	var panels: Array[InteractPoint] = []
	for child: Node in car.get_node(^"Interactables").get_children():
		if child is InteractPoint:
			panels.append(child)
	assert_eq(panels.size(), 1)
	if panels.size() == 1:
		assert_eq([panels[0].get_cell(), panels[0].dialogue_id, panels[0].facing],
			[Vector2i(1, 1), &"elevator_panel", Vector2i.UP])
		assert_true(car.get_grid().is_solid(Vector2i(1, 1)), "le panneau est un mur")
	# Les arrivées de `elevators.json` existent dans chaque étage (le test des ascenseurs).
	var library := ElevatorLibrary.new()
	assert_true(library.load_file(), str(library.get_errors()))
	var hideout := library.get_elevator(&"rocket_hideout")
	assert_eq(hideout.car, &"rocket_hideout_elevator")
	for entry: Dictionary in hideout.floors:
		assert_true(_maps.has(entry["map"]), "étage %s" % entry["map"])
		assert_true(_maps[entry["map"]].has_spawn(entry["spawn"]))
	assert_true(hideout.floor_for_map(&"rocket_hideout_b3f").is_empty(), "le B3F n'est pas desservi")


func test_escape_rope_leads_to_the_casino_door() -> void:
	var caves := CaveLibrary.new()
	caves.load_file()
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	for map_id: StringName in MAPS:
		var exit := caves.escape_target(map_id)
		assert_not_null(exit, String(map_id))
		if exit == null:
			continue
		assert_eq([exit.map, exit.spawn, exit.facing], [&"celadon_city", &"from_casino_w",
			Vector2i.DOWN], String(map_id))
	assert_eq(city.get_spawn_cell(&"from_casino_w"), Vector2i(39, 33))
	assert_false(city.get_grid().is_solid(Vector2i(39, 33)))


func test_node_budget() -> void:
	for map_id: StringName in MAPS:
		var total := GridPaths.count_nodes(_maps[map_id])
		gut.p("%s : %d nœuds" % [map_id, total])
		assert_lte(total, NODE_BUDGET, "%s : ≤ %d nœuds" % [map_id, NODE_BUDGET])
