extends GutTest
## Carte bill_house (jalon 14 T14, docs/tech/jalon-14.md §1.3, §2.1 ; dossier 17) sur la vraie
## scène : titre « Cap d'Azuria » (nom de la zone, `test_zone_library`), lumière chaude,
## enveloppe 16 × 11, **cases solides = grille** `tools/plans/bill_house.txt` (meubles,
## cabines A et B, console, écran, module, bibliothèques, bureau, lit), sortie sur le
## paillasson et arrivée tournée vers le nord, meubles posés sur les cases de la grille,
## PNJ, points d'examen, déclencheur et lueurs du T17.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH := "res://tools/plans/bill_house.txt"
const SIZE := Vector2i(16, 11)
const EXITS := [Vector2i(7, 10), Vector2i(8, 10)]
## Meuble (nom du nœud) → case de la grille où son emprise doit tomber (un caractère).
const FURNITURE: Dictionary = {
	"CabinA": "A", "CabinB": "B", "Screen": "E", "Console": "C", "Module": "m",
	"BookshelfWest": "b", "BookshelfEast": "b", "Desk": "N", "DeskChair": "N", "Bed": "L",
	"Plant": "x",
}

var _map: GameMap
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MapCatalog.scene_path(&"bill_house")) as PackedScene).instantiate() as GameMap
	add_child(_map)


func after_all() -> void:
	_map.free()


func test_metadata_light_and_shell() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(_map.map_id, &"bill_house")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.display_name, "Cap d'Azuria", "nom de la zone (test_zone_library)")
	assert_eq(zones.zone_name_of(&"bill_house"), "Cap d'Azuria")
	assert_true(_map.interior)
	assert_eq(_map.light_profile, &"interior_warm")
	assert_eq(lighting.get_map_profile(&"bill_house"), &"interior_warm", "au plan de lumière")
	assert_true(MapCatalog.load_interiors().has(&"bill_house"), "liste des intérieurs")
	var shell := _map.get_node(^"Shell") as Sprite2D
	assert_eq(shell.texture.get_size(), Vector2(SIZE * Grid.TILE_SIZE))
	assert_true(_map.get_entities().y_sort_enabled)


func test_solid_cells_follow_the_room_grid() -> void:
	var grid := _map.get_grid()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			assert_eq(grid.is_solid(cell), not ".X".contains(_plan.at(cell)),
				"%s « %s »" % [cell, _plan.at(cell)])


func test_exit_leads_back_to_the_cape_with_the_planned_spawns() -> void:
	var fronts := [&"from_bill_house_w", &"from_bill_house_e"]
	for i: int in EXITS.size():
		var cell: Vector2i = EXITS[i]
		assert_false(_map.get_grid().is_solid(cell), "sortie %s praticable" % cell)
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie %s" % cell)
		if warp != null:
			assert_eq([warp.target_map, warp.target_spawn, warp.facing],
				[&"route_25", fronts[i], Vector2i.DOWN])
	assert_eq(_map.get_warps().size(), 2)
	assert_true(_map.has_spawn(&"from_route_25"))
	assert_true((EXITS as Array).has(_map.get_spawn_cell(&"from_route_25")),
		"on arrive sur le paillasson")


func test_furniture_stands_on_its_grid_cells() -> void:
	var seen: Array[String] = []
	for child: Node in _map.get_entities().get_children():
		if not FURNITURE.has(String(child.name)):
			continue
		seen.append(String(child.name))
		var prop := child as WorldProp
		assert_not_null(prop, String(child.name))
		if prop == null:
			continue
		var cells := prop.get_solid_cells()
		assert_false(cells.is_empty(), "%s : emprise" % child.name)
		for cell: Vector2i in cells:
			assert_true(_plan.at(cell) in [FURNITURE[String(child.name)], "K"],
				"%s : case %s « %s »" % [child.name, cell, _plan.at(cell)])
	seen.sort()
	var expected: Array = FURNITURE.keys()
	expected.sort()
	assert_eq(seen, expected, "tous les meubles de la grille sont posés")


func test_machine_cells_are_all_covered() -> void:
	# Cabines, écran, console, module : chaque case de la grille est couverte par un meuble.
	var covered: Dictionary = {}
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp:
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				covered[cell] = true
	for mark: String in ["A", "B", "E", "C", "m", "b", "N", "L", "x"]:
		for cell: Vector2i in _plan.cells_of(mark):
			assert_true(covered.has(cell), "« %s » %s sans meuble" % [mark, cell])


## T17 : trois points d'examen (écran, module, console) tournés vers le nord depuis la case au
## sud, un déclencheur d'entrée (premier pas vers le nord depuis le paillasson), trois lueurs.
func test_examine_points_entry_trigger_and_hints() -> void:
	var interactions := _map.get_interactions()
	var expected := {
		Vector2i(5, 3): &"bill_screen", Vector2i(10, 3): &"bill_module",
		Vector2i(7, 3): &"bill_console", Vector2i(8, 3): &"bill_console",
	}
	for cell: Vector2i in expected:
		var found := interactions.find(cell, Vector2i.UP)
		assert_not_null(found, "examen en %s" % cell)
		if found != null:
			assert_eq([found.kind, found.dialogue_id], [Interaction.Kind.EXAMINE, expected[cell]])
		assert_null(interactions.find(cell, Vector2i.DOWN), "pas de dos au mur %s" % cell)
	for cell: Vector2i in [Vector2i(7, 9), Vector2i(8, 9)]:
		assert_not_null(_map.get_triggers().find_on_step(cell, Vector2i.UP), "entrée %s" % cell)
		assert_null(_map.get_triggers().find_on_step(cell, Vector2i.DOWN), "pas en sortant %s" % cell)
	var gates := get_tree().get_nodes_in_group(FlagGate.GROUP).filter(
		func(node: Node) -> bool: return _map.is_ancestor_of(node))
	assert_eq(gates.size(), 3, "lueurs de l'écran, du module et de la console")
	for gate: FlagGate in gates:
		assert_true((gate.get_child(0) as LightGlow).is_lit(), "type « hint » : %s" % gate.name)


func test_the_two_npcs_of_the_house_are_in_the_roster() -> void:
	var roster := NpcRoster.load_for_map(&"bill_house")
	assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
	var clefairy := roster.get_spec(&"bill_clefairy")
	var bill := roster.get_spec(&"bill")
	assert_eq(clefairy.cell, Vector2i(6, 5), "un cran au nord de la grille (6, 6) : le bureau la cache")
	assert_eq(bill.cell, Vector2i(12, 5))
	assert_eq(clefairy.unless_flags, [&"bill_in_cabin"] as Array[StringName])
	assert_eq(bill.if_flags, [&"bill_restored"] as Array[StringName])


func test_every_floor_cell_is_reachable_from_the_entrance() -> void:
	var terrain := GridPaths.relief(_map.get_grid(), SIZE)
	var dist := GridPaths.distances(terrain, [Vector2i(7, 10)])
	for cell: Vector2i in _plan.cells_of("."):
		assert_true(dist.has(cell), "sol %s atteignable" % cell)
	# Les cases d'examen devant l'écran, le module et la console (T17).
	for cell: Vector2i in [Vector2i(5, 4), Vector2i(10, 4), Vector2i(7, 4), Vector2i(8, 4),
			Vector2i(3, 5)]:
		assert_true(dist.has(cell), "point d'examen %s atteignable" % cell)


const GridPaths := preload("res://tests/helpers/grid_paths.gd")
