extends GutTest
## Résidence de Céladopole (jalon 20 T16, docs/tech/jalon-20.md §2.1, §2.2 ; dossier 23 §10) :
## six cartes (hall, 1er, 2e, 3e, toit, maison du toit) sur leur vraie scène : **grille de la
## scène = grille fonctionnelle** `tools/plans/celadopole_residence_*.txt`, escaliers qui se
## répondent, sortie du hall vers la ville (`from_mansion_w|e`), porte « BUREAU PRIVÉ » du 3e sans
## warp, **toit atteint seulement par l'escalier de service** de la ville (jamais par la Résidence),
## maison du toit (Poké Ball d'Évoli sur la table : sa case bloquée, don au T17).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const FLOORS: Array[StringName] = [&"celadon_mansion_gf", &"celadon_mansion_1f",
	&"celadon_mansion_2f", &"celadon_mansion_3f"]
const ROOF := &"celadon_mansion_roof"
const HOUSE := &"celadon_mansion_roof_house"
const ALL: Array[StringName] = [&"celadon_mansion_gf", &"celadon_mansion_1f",
	&"celadon_mansion_2f", &"celadon_mansion_3f", &"celadon_mansion_roof",
	&"celadon_mansion_roof_house"]
const PLANS := {
	&"celadon_mansion_gf": ["celadopole_residence_rdc", Vector2i(16, 11), ".XSZ"],
	&"celadon_mansion_1f": ["celadopole_residence_1er", Vector2i(16, 11), ".XSZ"],
	&"celadon_mansion_2f": ["celadopole_residence_2e", Vector2i(16, 11), ".XSZ"],
	&"celadon_mansion_3f": ["celadopole_residence_3e", Vector2i(16, 11), ".XSZ"],
	&"celadon_mansion_roof": ["celadopole_residence_toit", Vector2i(16, 10), ".ZD"],
	&"celadon_mansion_roof_house": ["celadopole_residence_maison_toit", Vector2i(10, 8), ".X"],
}
const STAIRS_UP: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 2)]
const STAIRS_DOWN: Array[Vector2i] = [Vector2i(4, 2), Vector2i(5, 2)]

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for id: StringName in ALL:
		assert_true(MapCatalog.has_map(id), "carte %s" % id)
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % PLANS[id][0]), plan.error)
		_plans[id] = plan


func after_all() -> void:
	for map: Variant in _maps.values():
		(map as Node).free()


func _warps_of(id: StringName) -> Array[Warp]:
	return (_maps[id] as GameMap).get_warps().get_all()


func test_maps_light_shell_and_grid() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var interiors := MapCatalog.load_interiors()
	for id: StringName in ALL:
		var map: GameMap = _maps[id]
		assert_eq(map.size, PLANS[id][1], "%s : taille" % id)
		assert_true(map.interior, "%s : intérieur" % id)
		assert_true(interiors.has(id), "%s dans interiors.json" % id)
		assert_eq(map.display_name, "Céladopole")
		var expected := &"golden_hour" if id == ROOF else &"interior_warm"
		assert_eq(map.light_profile, expected, id)
		assert_eq(lighting.get_map_profile(id), expected)
		assert_eq((map.get_node(^"Shell") as Sprite2D).texture.get_size(),
			Vector2(map.size * 96), "%s : enveloppe" % id)
		var plan: PlanGrid = _plans[id]
		assert_eq(plan.walkable, PLANS[id][2])
		var mismatches := 0
		for y: int in map.size.y:
			for x: int in map.size.x:
				var cell := Vector2i(x, y)
				if map.get_grid().is_solid(cell) != not plan.is_walkable(cell):
					mismatches += 1
					if mismatches <= 5:
						fail_test("%s %s « %s »" % [id, cell, plan.at(cell)])
		assert_eq(mismatches, 0, "%s = sa grille" % id)


func test_stairs_answer_each_other_and_the_hall_leaves_to_the_town() -> void:
	for i: int in FLOORS.size():
		var map: GameMap = _maps[FLOORS[i]]
		if i < FLOORS.size() - 1:
			for cell: Vector2i in STAIRS_UP:
				var warp := map.get_warps().find_on_step(cell, Vector2i.ZERO)
				assert_not_null(warp, "%s : escalier montant %s" % [FLOORS[i], cell])
				if warp != null:
					assert_eq([warp.target_map, warp.target_spawn],
						[FLOORS[i + 1], &"from_down"])
			assert_eq(map.get_spawn_cell(&"from_up"), Vector2i(2, 3))
		else:
			assert_null(map.get_warps().find_on_step(STAIRS_UP[0], Vector2i.ZERO),
				"3e : pas d'escalier montant (le toit n'est pas relié)")
		if i > 0:
			for cell: Vector2i in STAIRS_DOWN:
				var warp := map.get_warps().find_on_step(cell, Vector2i.ZERO)
				assert_not_null(warp, "%s : escalier descendant %s" % [FLOORS[i], cell])
				if warp != null:
					assert_eq([warp.target_map, warp.target_spawn], [FLOORS[i - 1], &"from_up"])
			assert_eq(map.get_spawn_cell(&"from_down"), Vector2i(4, 3))
	var hall: GameMap = _maps[&"celadon_mansion_gf"]
	assert_eq(hall.get_spawn_cell(&"entrance"), Vector2i(7, 9))
	var expected := {Vector2i(7, 9): &"from_mansion_w", Vector2i(8, 9): &"from_mansion_e"}
	for cell: Vector2i in expected:
		var out := hall.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie %s" % cell)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"celadon_city", expected[cell]])
	for id: StringName in [&"celadon_mansion_1f", &"celadon_mansion_2f", &"celadon_mansion_3f"]:
		for warp: Warp in _warps_of(id):
			assert_ne(warp.target_map, &"celadon_city", "%s : pas de sortie directe" % id)
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	assert_eq(city.get_spawn_cell(&"from_mansion_w"), Vector2i(29, 15))
	assert_eq(city.get_spawn_cell(&"from_mansion_e"), Vector2i(30, 15))


func test_the_roof_is_reached_by_the_service_stairs_only() -> void:
	# Aucune carte de la Résidence (hall, paliers) ne mène au toit.
	for id: StringName in FLOORS:
		for warp: Warp in _warps_of(id):
			assert_ne(warp.target_map, ROOF, "%s : pas d'accès au toit" % id)
	# Atteignable depuis le hall sans passer par la ville : seulement les quatre niveaux.
	var seen: Dictionary = {&"celadon_mansion_gf": true}
	var queue: Array[StringName] = [&"celadon_mansion_gf"]
	while not queue.is_empty():
		var id: StringName = queue.pop_back()
		if not _maps.has(id):
			continue
		for warp: Warp in _warps_of(id):
			if warp.target_map != &"celadon_city" and not seen.has(warp.target_map):
				seen[warp.target_map] = true
				queue.append(warp.target_map)
	assert_false(seen.has(ROOF), "toit hors de portée du hall")
	assert_false(seen.has(HOUSE))
	# La ville : l'escalier de service (30..31, 4) est la seule porte vers le toit.
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	var to_roof: Array[Vector2i] = []
	for warp: Warp in city.get_warps().get_all():
		if warp.target_map == ROOF:
			to_roof.append(warp.cell)
	to_roof.sort()
	assert_eq(to_roof, [Vector2i(30, 4), Vector2i(31, 4)] as Array[Vector2i],
		"escalier de service au nord de la Résidence")
	var roof: GameMap = _maps[ROOF]
	var expected := {Vector2i(2, 2): &"from_service_w", Vector2i(3, 2): &"from_service_e"}
	for cell: Vector2i in expected:
		var back := roof.get_warps().find_on_step(cell, Vector2i.ZERO)
		assert_not_null(back, "retour du toit %s" % cell)
		if back != null:
			assert_eq([back.target_map, back.target_spawn], [&"celadon_city", expected[cell]])
			assert_true(city.has_spawn(back.target_spawn))
	assert_eq(roof.get_spawn_cell(&"from_service"), Vector2i(2, 3))
	# Le toit n'a pas d'autre sortie que l'escalier et la porte de la maison.
	assert_eq(roof.get_warps().size(), 3)
	# Toute la Résidence reste joignable à pied : hall → 3e.
	for id: StringName in FLOORS:
		var map: GameMap = _maps[id]
		var terrain := GridPaths.relief(map.get_grid(), map.size)
		var start := map.get_spawn_cell(&"entrance" if id == &"celadon_mansion_gf"
			else &"from_down")
		var open := GridPaths.distances(terrain, [start])
		for warp: Warp in map.get_warps().get_all():
			assert_true(open.has(warp.cell), "%s : %s atteignable" % [id, warp.cell])


func test_private_office_door_has_no_warp() -> void:
	var top: GameMap = _maps[&"celadon_mansion_3f"]
	var door := Vector2i(8, 2)
	assert_true(top.get_grid().is_solid(door), "porte du bureau : case bloquée")
	for warp: Warp in _warps_of(&"celadon_mansion_3f"):
		assert_ne(warp.cell, door, "aucun warp sur la porte « BUREAU PRIVÉ »")
	var found: InteractPoint = null
	for child: Node in top.get_node(^"Interactables").get_children():
		found = child as InteractPoint
	assert_not_null(found)
	if found != null:
		assert_eq([found.get_cell(), found.facing, found.dialogue_id],
			[door, Vector2i.UP, &"celadon_mansion_office_door"])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	var pages := dialogues.get_dialogue(&"celadon_mansion_office_door").variants[0].pages
	assert_eq([pages[0].text, pages[1].text], ["BUREAU PRIVÉ", "C'est fermé."], "texte 27")


func test_roof_house_and_the_eevee_ball_cell() -> void:
	var roof: GameMap = _maps[ROOF]
	var house: GameMap = _maps[HOUSE]
	var door := roof.get_warps().find_on_step(Vector2i(10, 5), Vector2i.UP)
	assert_not_null(door, "porte de la maison du toit")
	if door != null:
		assert_eq([door.target_map, door.target_spawn], [HOUSE, &"entrance"])
	assert_eq(roof.get_spawn_cell(&"from_house"), Vector2i(10, 6))
	for x: int in range(8, 13):
		for y: int in range(2, 5):
			assert_true(roof.get_grid().is_solid(Vector2i(x, y)), "maison du toit %d,%d" % [x, y])
	assert_eq(house.get_spawn_cell(&"entrance"), Vector2i(4, 6))
	for cell: Vector2i in [Vector2i(4, 6), Vector2i(5, 6)]:
		var out := house.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [ROOF, &"from_house"])
	# La Poké Ball d'Évoli (4, 3) est sur la table : case bloquée, lue de (4, 4).
	assert_true(house.get_grid().is_solid(Vector2i(4, 3)))
	assert_false(house.get_grid().is_solid(Vector2i(4, 4)))


func test_npc_cells_are_free_and_do_not_cut_the_floors() -> void:
	for id: StringName in ALL:
		var plan: PlanGrid = _plans[id]
		var map: GameMap = _maps[id]
		var cells: Array[Vector2i] = []
		for pos: String in plan.positions:
			if plan.positions[pos]["kind"] in ["pnj", "pokemon"]:
				cells.append_array(plan.cells_at(pos))
		var terrain := GridPaths.relief(map.get_grid(), map.size)
		var start := map.get_spawn_cell(&"entrance" if map.has_spawn(&"entrance")
			else &"from_down" if map.has_spawn(&"from_down") else &"from_service")
		for cell: Vector2i in cells:
			assert_false(map.get_grid().is_solid(cell), "%s %s : case libre" % [id, cell])
			terrain.set_solid(cell)
		var reach := GridPaths.distances(terrain, [start])
		for cell: Vector2i in plan.cells_of(PLANS[id][2]):
			if not cells.has(cell):
				assert_true(reach.has(cell), "%s %s : jamais coupée" % [id, cell])
