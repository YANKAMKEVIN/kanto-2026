extends GutTest
## Kits de construction des cartes du jalon 18 (T11, docs/tech/jalon-18.md §5.2) : la boîte des
## grottes lit la Grotte Sombre (`e`, échelles A et B, murs `K` de la Tour) sans changer le
## Mont Sélénite ; la boîte d'eau lit la Route 10 (`Q` en terre, `w` solide) ; la table des
## lettres → assets (`tools/j18_asset_refs.gd`) ne demande aucun fichier de la série 21 et que ses
## replis et assets réutilisés existent. Aucune carte du J18 n'est construite ici.

const CaveKit := preload("res://tools/cave_map_kit.gd")
const WaterKit := preload("res://tools/cerulean_map_kit.gd")
const Refs := preload("res://tools/j18_asset_refs.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const DARK: Dictionary[StringName, Vector2i] = {
	&"dark_cave_1f": Vector2i(56, 49), &"dark_cave_b1f": Vector2i(48, 38),
}


func _dark(map_id: StringName) -> RefCounted:
	return CaveKit.new(CaveKit.PLANS[map_id], DARK[map_id], 1, 2, CaveKit.DARK_CAVE_WALKABLE)


func test_dark_cave_grids_load_with_the_extended_walkables() -> void:
	for map_id: StringName in DARK:
		assert_eq(_dark(map_id).errors, PackedStringArray(), String(map_id))
	assert_eq(CaveKit.DARK_CAVE_WALKABLE, CaveKit.WALKABLE + "e")


func test_mt_moon_keeps_its_walkables_and_rejects_the_dark_cave_line() -> void:
	var strict := CaveKit.new(CaveKit.PLANS[&"dark_cave_1f"], DARK[&"dark_cave_1f"], 1, 2)
	assert_false(strict.errors.is_empty(), "la ligne « .gjUVEe » n'est pas celle du Mont Sélénite")
	assert_eq(CaveKit.WALKABLE, ".gjUVE")


func test_dark_cave_logic_layer_walks_e_and_blocks_the_landmarks() -> void:
	var kit := _dark(&"dark_cave_1f")
	var root: Node2D = kit.make_root("Floor", &"dark_cave_1f", "Grotte Sombre", &"")
	var ground := root.get_node(^"Ground") as TileMapLayer
	var plan: Object = kit.plan
	var seen := {}
	for y: int in DARK[&"dark_cave_1f"].y:
		for x: int in DARK[&"dark_cave_1f"].x:
			var cell := Vector2i(x, y)
			var mark: String = plan.call(&"at", cell)
			seen[mark] = true
			var walkable := ".gjUVEe".contains(mark)
			assert_eq(ground.get_cell_tile_data(cell).get_custom_data(OverworldTiles.DATA_SOLID),
				not walkable, "%s « %s »" % [cell, mark])
	assert_true(seen.has("e"), "la sortie sud « e » est dans la grille")
	assert_eq(kit.errors, PackedStringArray())
	root.free()


func test_dark_cave_b1f_solid_landmarks_are_solid() -> void:
	var kit := _dark(&"dark_cave_b1f")
	var root: Node2D = kit.make_root("Floor", &"dark_cave_b1f", "Grotte Sombre", &"")
	var ground := root.get_node(^"Ground") as TileMapLayer
	for mark: String in ["K", "w", "f", "r", "o"]:
		var cells: Array = kit.plan.call(&"cells_of", mark)
		assert_gt(cells.size(), 0, "« %s » dans B1F" % mark)
		for cell: Vector2i in cells:
			assert_true(ground.get_cell_tile_data(cell).get_custom_data(
				OverworldTiles.DATA_SOLID), "%s « %s » solide" % [cell, mark])
	root.free()


func test_dark_cave_ladders_pair_a_and_b() -> void:
	var kit := _dark(&"dark_cave_1f")
	var links: Array[Dictionary] = kit.ladder_links()
	assert_eq(kit.errors, PackedStringArray())
	assert_eq(links.size(), 2)
	for link: Dictionary in links:
		assert_eq(link["target_map"], &"dark_cave_b1f")
		assert_eq(link["target_spawn"], &"arrivee_%s" % String(link["pair"]).to_lower())
		# À l'opposé de l'échelle (règle du Mont Sélénite) : A (44, 2) → arrivée (44, 3) tournée
		# vers le bas ; B (44, 34) → arrivée (43, 34) tournée vers l'ouest (le commentaire de
		# `grotte_sombre_b1f.txt` dit « → » : à trancher au T13, signalé au compte rendu du T11).
		assert_eq(link["facing"], Vector2i.DOWN if link["pair"] == "A" else Vector2i.LEFT)
	var down := _dark(&"dark_cave_b1f")
	for link: Dictionary in down.ladder_links():
		assert_eq(link["target_map"], &"dark_cave_1f")
	assert_eq(down.errors, PackedStringArray())


func test_mt_moon_ladders_are_unchanged_by_the_new_plans() -> void:
	var kit := CaveKit.new(CaveKit.PLANS[&"mt_moon_1f"], Vector2i(60, 46), 1, 2)
	kit.ladder_links()
	assert_eq(kit.errors, PackedStringArray())


func test_wall_settings_default_to_the_mt_moon_modules() -> void:
	var kit := CaveKit.new(CaveKit.PLANS[&"mt_moon_1f"], Vector2i(60, 46), 1, 2)
	assert_eq(kit.wall_marks, CaveKit.WALL_MARKS)
	assert_eq(kit.mass_mark, CaveKit.MASS_MARK)
	assert_eq(kit.wall_faces, CaveKit.WALL_FACES)
	assert_eq(kit.wall_side, CaveKit.WALL_SIDE)
	assert_eq(kit.wall_lip, CaveKit.WALL_LIP)


func test_tower_grid_loads_on_the_cave_kit_with_k_walls() -> void:
	var kit := CaveKit.new("res://tools/plans/tour_pokemon_rdc.txt", Vector2i(20, 18), 1, 2, ".XS")
	assert_eq(kit.errors, PackedStringArray())
	kit.wall_marks = "K"
	kit.mass_mark = "K"
	assert_true(kit.is_mass(Vector2i(0, 0)))
	assert_false(kit.is_mass(Vector2i(9, 10)))
	assert_true(kit.is_face_cell(Vector2i(5, 2)), "bas du mur du fond = face")


func test_route_10_reads_on_the_water_kit() -> void:
	var kit: RefCounted = WaterKit.new("res://tools/plans/route_10.txt", Vector2i(34, 76), 1, 2)
	assert_eq(kit.get(&"errors"), PackedStringArray())
	assert_eq(kit.get(&"plan").get(&"walkable"), ".=hoDQP")
	kit.call(&"set_marks", ".=hoDQP", "K", "o")
	var root: Node2D = kit.call(&"make_root", "Route10", &"route_10", "Route 10", "", &"", "")
	var grid: GridWorld = (root as GameMap).get_grid()
	var plan: Object = kit.get(&"plan")
	var mouth: Array = plan.call(&"cells_of", "Q")
	assert_eq(mouth.size(), 4)
	for cell: Vector2i in mouth:
		assert_false(grid.is_solid(cell), "bouche %s praticable" % cell)
		assert_true((kit.get(&"path_cells") as Dictionary).has(cell), "sentier sous la bouche")
	var ground := root.get_node(^"Ground") as TileMapLayer
	for cell: Vector2i in mouth:
		assert_eq(ground.get_cell_tile_data(cell).get_custom_data(OverworldTiles.DATA_SOLID), false)
	for cell: Vector2i in plan.call(&"cells_of", "w"):
		assert_true(grid.is_water(cell), "eau %s" % cell)
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			assert_false(grid.can_enter(cell, side), "eau %s jamais praticable" % cell)
	for cell: Vector2i in plan.call(&"cells_of", "E"):
		assert_true(grid.is_solid(cell), "centrale %s bloquée" % cell)
	root.free()


func test_asset_tables_never_require_a_series_21_file() -> void:
	for table_name: StringName in Refs.tables():
		var table: Dictionary = Refs.tables()[table_name]
		for role: StringName in table:
			var entry: Dictionary = table[role]
			var label := "%s/%s" % [table_name, role]
			assert_ne(Refs.status(entry), &"missing", label + " : ni asset ni repli")
			if entry.has("reused"):
				assert_false(entry.has("new"), label)
			else:
				for id: String in entry["fallback"]:
					assert_true(Refs.exists(id, entry["kind"]), "%s : repli %s" % [label, id])
				assert_false((entry["new"] as Array).is_empty(), label)


func test_pick_prefers_new_assets_only_when_all_exist() -> void:
	var entry := {"kind": &"prop", "new": ["prop_rocher_grotte_01", "inexistant_zz"],
		"fallback": ["prop_rocher_01"]}
	assert_eq(Refs.status(entry), &"fallback")
	assert_eq(Refs.pick(entry), ["prop_rocher_01"] as Array[String])
	entry["new"] = ["prop_rocher_grotte_01", "prop_rocher_grotte_02"]
	assert_eq(Refs.status(entry), &"new")
	assert_eq(Refs.pick(entry).size(), 2)
	var optional := {"kind": &"prop", "new": ["inexistant_zz"], "fallback": [], "optional": true}
	assert_eq(Refs.status(optional), &"skipped")
	assert_true(Refs.pick(optional).is_empty())
	var required := {"kind": &"prop", "new": ["inexistant_zz"], "fallback": []}
	assert_eq(Refs.status(required), &"missing")


func test_letters_of_the_tables_exist_in_their_grids() -> void:
	var plans := {&"dark_cave": ["grotte_sombre_1f", "grotte_sombre_b1f"],
		&"routes": ["route_10"], &"lavender": ["lavanville"], &"tower": ["tour_pokemon_rdc"]}
	for table_name: StringName in plans:
		var letters := ""
		for grid_name: String in plans[table_name]:
			var grid := PlanGrid.new()
			assert_true(grid.load_file("res://tools/plans/%s.txt" % grid_name))
			for row: String in grid.rows:
				letters += row
		for role: StringName in Refs.tables()[table_name]:
			var letter: String = Refs.tables()[table_name][role]["letter"]
			if letter.is_empty():
				continue
			assert_true(letters.contains(letter), "%s/%s : « %s » absente des grilles" % [
				table_name, role, letter])
