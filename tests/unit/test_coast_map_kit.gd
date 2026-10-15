extends GutTest
## Boîte à outils côtière (`tools/coast_map_kit.gd`, jalon 14 T14) sur la vraie grille de la
## Route 25 : praticables de la grille (sable compris), mer solide (et vue par
## `GridWorld.is_water`), sable sans module, rôles des cases `R` d'après la mer (décompte de la
## fiche de la série 16 : 72 mer au sud, 26 à l'est, 8 à l'ouest, angles), modules posés
## seulement sur des `R` qui touchent la mer, jamais sur une case praticable, piliers en paroi,
## graines fixes. Sans enregistrer de scène.

const Kit := preload("res://tools/coast_map_kit.gd")
const PLAN := "res://tools/plans/route_25.txt"
const SIZE := Vector2i(80, 28)


func _kit(shore_seed: int = 3) -> RefCounted:
	return Kit.new(PLAN, SIZE, 1, 2, shore_seed)


## Carte construite en mémoire : sol, mer, rivage.
func _build(kit: RefCounted) -> Node2D:
	var root: Node2D = kit.call(&"make_root", "Essai", &"essai", "Essai", "", &"", "")
	kit.call(&"add_ground_in_memory", {})
	kit.call(&"place_shore")
	return root


func _roles(kit: RefCounted) -> Dictionary:
	var counts: Dictionary = {}
	var roles: Dictionary = kit.get(&"rock_roles")
	for cell: Vector2i in roles:
		counts[roles[cell]] = int(counts.get(roles[cell], 0)) + 1
	return counts


func test_grid_keeps_its_own_walkables() -> void:
	var kit := _kit()
	assert_eq(kit.get(&"errors"), PackedStringArray())
	assert_eq(kit.get(&"plan").get(&"walkable"), ".=hvsD")


func test_sea_is_water_and_sand_is_walkable() -> void:
	var kit := _kit()
	var root: Node2D = kit.call(&"make_root", "Essai", &"essai", "Essai", "", &"", "")
	var grid: GridWorld = (root as GameMap).get_grid()
	var plan: Object = kit.get(&"plan")
	for cell: Vector2i in plan.call(&"cells_of", "w"):
		assert_true(grid.is_water(cell), "mer %s" % cell)
	for cell: Vector2i in plan.call(&"cells_of", "s"):
		assert_false(grid.is_solid(cell), "sable %s" % cell)
		assert_false(grid.is_water(cell))
	assert_eq((kit.get(&"sand_cells") as Dictionary).size(), plan.call(&"cells_of", "s").size())
	root.free()


func test_rock_roles_match_the_sheet_of_the_series() -> void:
	var kit := _kit()
	var root: Node2D = kit.call(&"make_root", "Essai", &"essai", "Essai", "", &"", "")
	var counts := _roles(kit)
	gut.p("rôles des R : %s" % counts)
	assert_eq(int(counts.get(&"s", 0)) + int(counts.get(&"se", 0)) + int(counts.get(&"sw", 0)),
		72 + 3 + 3, "mer au sud, angles compris")
	assert_eq(int(counts.get(&"e", 0)), 26, "mer à l'est")
	assert_eq(int(counts.get(&"w", 0)), 8, "mer à l'ouest")
	assert_eq(int(counts.get(&"in_se", 0)), 2, "angles intérieurs sud-est")
	assert_eq(int(counts.get(&"in_sw", 0)), 2, "angles intérieurs sud-ouest")
	assert_eq(int(counts.get(&"far", 0)), 102, "R loin de l'eau")
	root.free()


func test_modules_sit_on_rocks_never_on_walkable_cells() -> void:
	var kit := _kit()
	var root: Node2D = _build(kit)
	assert_eq(kit.get(&"errors"), PackedStringArray())
	var pieces: Array = kit.get(&"shore_pieces")
	assert_gt(pieces.size(), 60)
	var rocks: Dictionary = kit.get(&"rock_cells")
	for piece: Dictionary in pieces:
		var rect: Rect2 = piece["rect"]
		for cell: Vector2i in Kit.cells_of_rect(rect.grow_individual(0.0, -19.2, 0.0, 0.0)):
			assert_true(rocks.has(cell), "%s %s : sur une case R" % [piece["id"], cell])
			assert_false(kit.call(&"is_walkable", cell))
	root.free()


func test_sand_gets_no_module_and_pillars_none_either() -> void:
	var kit := _kit()
	var root: Node2D = _build(kit)
	var sand: Dictionary = kit.get(&"sand_cells")
	var pillars: Dictionary = kit.get(&"pillar_cells")
	assert_gt(pillars.size(), 40, "deux piliers de roche loin de l'eau")
	for piece: Dictionary in kit.get(&"shore_pieces"):
		var rect: Rect2 = piece["rect"]
		for cell: Vector2i in Kit.cells_of_rect(rect.grow_individual(0.0, -19.2, 0.0, 0.0)):
			assert_false(sand.has(cell), "module sur le sable %s" % cell)
			assert_false(pillars.has(cell), "module sur un pilier %s" % cell)
	root.free()


func test_roles_pick_the_expected_images() -> void:
	var kit := _kit()
	var root: Node2D = _build(kit)
	var allowed := {&"s": ["relief_rivage_01", "relief_rivage_02"], &"e": ["relief_rivage_03"],
		&"w": ["relief_rivage_03"], &"se": ["relief_rivage_04"], &"sw": ["relief_rivage_04"],
		&"in_se": ["relief_rivage_05"], &"in_sw": ["relief_rivage_05"],
		&"block": ["relief_rivage_06"]}
	for piece: Dictionary in kit.get(&"shore_pieces"):
		assert_true((allowed[piece["role"]] as Array).has(piece["id"]),
			"%s : image du rôle %s" % [piece["id"], piece["role"]])
	root.free()


func test_same_seed_same_layout_other_seed_other_variants() -> void:
	var first := _kit(5)
	var first_root := _build(first)
	var again := _kit(5)
	var again_root := _build(again)
	assert_eq(_signature(first), _signature(again), "même graine, même rivage")
	var other := _kit(6)
	var other_root := _build(other)
	assert_ne(_signature(first), _signature(other), "autre graine : autres variantes")
	for root: Node2D in [first_root, again_root, other_root]:
		root.free()


func _signature(kit: RefCounted) -> Array:
	var out: Array = []
	for piece: Dictionary in kit.get(&"shore_pieces"):
		out.append([piece["id"], piece["role"], piece["rect"]])
	return out
