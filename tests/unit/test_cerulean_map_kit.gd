extends GutTest
## Boîte à outils des canaux (`tools/cerulean_map_kit.gd`, jalon 13 T6) sur la carte d'essai
## (`tests/fixtures/maps/canal_essai.txt`, canal en L) et sur les vraies grilles d'Azuria et de la
## Route 24 : praticables de la grille, eau solide (et vue par `GridWorld.is_water`), ponts et quais
## praticables, rivage sans sable à angles droits, quais sur toute la frontière eau / sol sans
## jamais couvrir une case praticable, ponts rectangulaires orientés, graines fixes. Sans
## enregistrer de scène (T7, T8) ; les images de la série 15 manquantes sont des provisoires.

const Kit := preload("res://tools/cerulean_map_kit.gd")
const ESSAI: String = "res://tests/fixtures/maps/canal_essai.txt"
const GRIDS: Dictionary[String, Vector2i] = {
	"res://tests/fixtures/maps/canal_essai.txt": Vector2i(24, 11),
	"res://tools/plans/azuria.txt": Vector2i(56, 46),
	"res://tools/plans/route_24.txt": Vector2i(56, 62),
}


func _kit(path: String = ESSAI, quay_seed: int = 3) -> RefCounted:
	var kit: RefCounted = Kit.new(path, GRIDS[path], 1, 2, quay_seed)
	kit.set(&"allow_placeholders", true)
	return kit


## Carte construite en mémoire : sol, quais, ponts.
func _build(kit: RefCounted) -> Node2D:
	var root: Node2D = kit.call(&"make_root", "Essai", &"canal_essai", "Essai", "", &"", "")
	kit.call(&"add_ground_in_memory", {})
	kit.call(&"place_quays")
	kit.call(&"place_bridges", {})
	return root


func test_grids_keep_their_own_walkables() -> void:
	var expected := {ESSAI: ".=qB", "res://tools/plans/azuria.txt": ".=pqBD",
		"res://tools/plans/route_24.txt": ".=hpBe"}
	for path: String in GRIDS:
		var kit := _kit(path)
		assert_eq(kit.get(&"errors"), PackedStringArray(), path)
		assert_eq(kit.get(&"plan").get(&"walkable"), expected[path], path)


func test_water_is_solid_bridges_and_quays_are_walkable() -> void:
	for path: String in GRIDS:
		var kit := _kit(path)
		var root: Node2D = kit.call(&"make_root", "Essai", &"essai", "Essai", "", &"", "")
		var grid: GridWorld = (root as GameMap).get_grid()
		var plan: Object = kit.get(&"plan")
		var size: Vector2i = GRIDS[path]
		var counts := {"w": 0, "B": 0}
		for y: int in size.y:
			for x: int in size.x:
				var cell := Vector2i(x, y)
				var mark: String = plan.call(&"at", cell)
				match mark:
					"w":
						counts["w"] += 1
						assert_true(grid.is_water(cell), "%s %s : eau" % [path, cell])
						for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT,
								Vector2i.RIGHT]:
							assert_false(grid.can_enter(cell, side),
								"%s %s : jamais praticable" % [path, cell])
					"B":
						counts["B"] += 1
						assert_true(grid.can_enter(cell, Vector2i.UP),
							"%s %s : pont" % [path, cell])
						assert_false(grid.is_water(cell), "%s %s : pont sec" % [path, cell])
					"q":
						assert_false(grid.is_solid(cell), "%s %s : quai" % [path, cell])
						assert_false(grid.is_water(cell))
		assert_gt(counts["w"], 0, "%s : de l'eau" % path)
		assert_gt(counts["B"], 0, "%s : un pont" % path)
		root.free()


func test_water_mask_has_no_sand_and_covers_water_and_bridges() -> void:
	for path: String in GRIDS:
		var kit := _kit(path)
		var root: Node2D = kit.call(&"make_root", "Essai", &"essai", "Essai", "", &"", "")
		var mask: Image = kit.call(&"build_water_mask")
		var plan: Object = kit.get(&"plan")
		for y: int in mask.get_height():
			for x: int in mask.get_width():
				var cell := Vector2i(x, y)
				var mark: String = plan.call(&"at", cell)
				assert_eq(mask.get_pixelv(cell).r, 0.0, "%s %s : aucun sable" % [path, cell])
				assert_eq(GroundMask.shore_at(mask, cell) == GroundMask.Kind.WATER,
					mark == "w" or mark == "B", "%s %s « %s »" % [path, cell, mark])
		root.free()


func test_ground_draws_canal_water_square_without_foam() -> void:
	var kit := _kit()
	var root := _build(kit)
	var ground := root.get_node(^"PaintedGround") as PaintedGround
	assert_not_null(ground.shore_mask)
	assert_true(ground.square_shore, "angles droits")
	assert_eq(ground.foam_strength, 0.0, "aucune écume contre un quai")
	assert_not_null(ground.water_texture)
	assert_string_contains(ground.water_texture.resource_name, "PROVISOIRE",
		"texture de canal provisoire tant que la série 15 n'est pas livrée")
	var material := ground.get_shader_material()
	assert_eq(material.get_shader_parameter(&"water_texture"), ground.water_texture)
	root.free()


func test_quays_cover_every_water_land_edge_and_no_walkable_cell() -> void:
	for path: String in GRIDS:
		var kit := _kit(path)
		var root := _build(kit)
		assert_eq(kit.get(&"errors"), PackedStringArray(), path)
		var pieces: Array[Dictionary] = kit.get(&"quay_pieces")
		assert_gt(pieces.size(), 0, path)
		for piece: Dictionary in pieces:
			for cell: Vector2i in Kit.cells_of_rect(piece["rect"]):
				assert_false(kit.call(&"is_walkable", cell), "%s %s : %s sur %s" % [path,
					piece["id"], piece["rect"], cell])
				assert_true((kit.get(&"water_cells") as Dictionary).has(cell),
					"%s : quai dans l'eau %s" % [path, cell])
		# Chaque bord eau / sol est sous un module de son côté.
		var water: Dictionary = kit.get(&"water_cells")
		for cell: Vector2i in water:
			for side: StringName in Kit.SIDES:
				if not kit.call(&"is_land", cell + Kit.SIDES[side]):
					continue
				var covered := false
				for piece: Dictionary in pieces:
					if piece["side"] == side and Kit.cells_of_rect(piece["rect"]).has(cell):
						covered = true
						break
				assert_true(covered, "%s : bord %s de %s couvert" % [path, side, cell])
		root.free()


func test_l_canal_corners() -> void:
	var kit := _kit()
	var root := _build(kit)
	# Le coin intérieur du L : la case d'eau (10, 4) ne touche le quai (11, 3) qu'en diagonale.
	assert_eq(kit.call(&"corner_cells", &"ne"), [Vector2i(10, 4)] as Array[Vector2i])
	# Le coin extérieur (8, 6) : sol à l'ouest et au sud, deux bords qui se rejoignent.
	var sides: Array[StringName] = []
	for piece: Dictionary in kit.get(&"quay_pieces"):
		if Kit.cells_of_rect(piece["rect"]).has(Vector2i(8, 6)):
			sides.append(piece["side"])
	assert_true(sides.has(&"w") and sides.has(&"s"), "angle extérieur : %s" % [sides])
	root.free()


func test_bridges_are_rectangles_with_their_crossing_axis() -> void:
	var kit := _kit()
	var root := _build(kit)
	var bridges: Array[Dictionary] = kit.get(&"bridges")
	assert_eq(bridges.size(), 2)
	assert_eq(bridges[0]["rect"], Rect2i(8, 1, 3, 2))
	assert_eq(bridges[0]["axis"], &"ew", "pont du canal vertical : d'ouest en est")
	assert_eq(bridges[1]["rect"], Rect2i(16, 4, 2, 3))
	assert_eq(bridges[1]["axis"], &"ns", "pont du canal horizontal : du nord au sud")
	root.free()
	# Vraies grilles : chaque case de pont dans un rectangle plein, traversé du praticable au
	# praticable.
	for path: String in ["res://tools/plans/azuria.txt", "res://tools/plans/route_24.txt"]:
		var real := _kit(path)
		var map := _build(real)
		assert_eq(real.get(&"errors"), PackedStringArray(), path)
		var total := 0
		for bridge: Dictionary in real.get(&"bridges"):
			var rect: Rect2i = bridge["rect"]
			total += rect.get_area()
			var ends: Array[Vector2i] = []
			if bridge["axis"] == &"ns":
				ends = [Vector2i(rect.position.x, rect.position.y - 1),
					Vector2i(rect.position.x, rect.end.y)]
			else:
				ends = [Vector2i(rect.position.x - 1, rect.position.y),
					Vector2i(rect.end.x, rect.position.y)]
			for cell: Vector2i in ends:
				if cell.x >= 0 and cell.y >= 0 and cell.x < GRIDS[path].x \
						and cell.y < GRIDS[path].y:
					assert_true(real.call(&"is_walkable", cell), "%s : bout %s" % [path, cell])
		assert_eq(total, (real.get(&"bridge_cells") as Dictionary).size(), path)
		map.free()
	# Azuria : trois ponts (central, Arène, ouest) ; Route 24 : le Pont Pépite, 2 × 25.
	var azuria := _kit("res://tools/plans/azuria.txt")
	var a_root: Node2D = azuria.call(&"make_root", "A", &"a", "A", "", &"", "")
	assert_eq((azuria.call(&"bridge_rects") as Array).size(), 3)
	a_root.free()
	var route := _kit("res://tools/plans/route_24.txt")
	var r_root: Node2D = route.call(&"make_root", "R", &"r", "R", "", &"", "")
	var pepite: Array = route.call(&"bridge_rects")
	assert_eq(pepite.size(), 1)
	assert_eq((pepite[0] as Dictionary)["rect"], Rect2i(32, 20, 2, 25))
	assert_eq((pepite[0] as Dictionary)["axis"], &"ns")
	r_root.free()


func test_same_seeds_same_quays() -> void:
	var placed: Array = []
	for attempt: int in 2:
		var kit := _kit("res://tools/plans/azuria.txt", 7)
		var root := _build(kit)
		var summary: Array = []
		for piece: Dictionary in kit.get(&"quay_pieces"):
			summary.append([piece["id"], piece["side"], piece["rect"]])
		placed.append(summary)
		root.free()
	assert_eq(placed[0], placed[1])


func test_missing_series_15_art_is_an_error_without_placeholders() -> void:
	var kit: RefCounted = Kit.new(ESSAI, GRIDS[ESSAI], 1, 2, 3)
	var root: Node2D = kit.call(&"make_root", "Essai", &"canal_essai", "Essai", "", &"", "")
	kit.call(&"add_ground_in_memory", {})
	kit.call(&"place_quays")
	kit.call(&"place_bridges", {})
	var errors := "\n".join(kit.get(&"errors") as PackedStringArray)
	if not ResourceLoader.exists(Kit.CANAL_WATER_TEXTURE):
		assert_string_contains(errors, "ground_eau_canal_01")
	if not ResourceLoader.exists(Kit.PROPS + "relief_quai_01.tscn"):
		assert_string_contains(errors, "relief_quai_01")
	assert_string_contains(errors, "tablier de pont absent", "aucun tablier choisi")
	assert_eq((kit.get(&"quay_pieces") as Array).size(), 0, "rien posé sans image")
	root.free()


func test_no_border_decal_on_water() -> void:
	var kit := _kit("res://tools/plans/azuria.txt")
	var root := _build(kit)
	kit.call(&"place_border_decals", 5)
	var water: Dictionary = kit.get(&"water_cells")
	var bridges: Dictionary = kit.get(&"bridge_cells")
	for node: Node in root.get_node(^"GroundDecals").get_children():
		if String(node.name).begins_with("Quai") or String(node.name).begins_with("Pont"):
			continue
		var cell := Vector2i(((node as Node2D).position / 96.0).floor())
		assert_false(water.has(cell) or bridges.has(cell), "%s sur l'eau %s" % [node.name, cell])
	root.free()
