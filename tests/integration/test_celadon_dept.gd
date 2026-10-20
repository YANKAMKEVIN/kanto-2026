extends GutTest
## Grand magasin de Céladopole (jalon 20 T16, docs/tech/jalon-20.md §2.1, §2.2, §2.3.1 ; dossier
## 23 §9) : sept cartes (RdC, 2e, 3e, 4e, 5e, toit, cabine d'ascenseur) sur leur vraie scène :
## **grille de la scène = grille fonctionnelle** `tools/plans/celadopole_magasin_*.txt`, enveloppes
## de la taille de la carte, escaliers à l'ouest (S montant (2..3, 2), Z descendant (4..5, 2)) qui
## se répondent d'un étage à l'autre, porte de l'ascenseur à l'est (16..17, 2) sur chacun des cinq
## étages, sortie du RdC vers la ville (`from_dept_w|e`), **toit atteint par l'escalier du 5e
## seulement** (jamais par l'ascenseur), cabine (panneau d'étages, sortie vers le RdC).
## **En attente du T13** : le trajet d'ascenseur (RdC → 5e → sortie au 5e) dépend du moteur
## (`ElevatorDirector`, §2.3.3) : voir `test_elevator_ride_waits_for_the_engine`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const FLOORS: Array = [
	[&"celadon_dept_gf", "celadopole_magasin_rdc", "gf", Vector2i(20, 13)],
	[&"celadon_dept_2f", "celadopole_magasin_2e", "2f", Vector2i(20, 13)],
	[&"celadon_dept_3f", "celadopole_magasin_3e", "3f", Vector2i(20, 13)],
	[&"celadon_dept_4f", "celadopole_magasin_4e", "4f", Vector2i(20, 13)],
	[&"celadon_dept_5f", "celadopole_magasin_5e", "5f", Vector2i(20, 13)],
]
const ROOF := &"celadon_dept_roof"
const CABIN := &"celadon_dept_elevator"
const ALL: Array[StringName] = [&"celadon_dept_gf", &"celadon_dept_2f", &"celadon_dept_3f",
	&"celadon_dept_4f", &"celadon_dept_5f", &"celadon_dept_roof", &"celadon_dept_elevator"]
const PLANS := {
	&"celadon_dept_roof": ["celadopole_magasin_toit", Vector2i(20, 11)],
	&"celadon_dept_elevator": ["celadopole_magasin_ascenseur", Vector2i(6, 6)],
}
const STAIRS_UP: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 2)]
const STAIRS_DOWN: Array[Vector2i] = [Vector2i(4, 2), Vector2i(5, 2)]
const LIFT_DOORS: Array[Vector2i] = [Vector2i(16, 2), Vector2i(17, 2)]

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for id: StringName in ALL:
		assert_true(MapCatalog.has_map(id), "carte %s" % id)
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/%s.txt" % _plan_name(id)), plan.error)
		_plans[id] = plan


func after_all() -> void:
	for map: Variant in _maps.values():
		(map as Node).free()


func _plan_name(id: StringName) -> String:
	for floor_entry: Array in FLOORS:
		if floor_entry[0] == id:
			return floor_entry[1]
	return PLANS[id][0]


func _size(id: StringName) -> Vector2i:
	for floor_entry: Array in FLOORS:
		if floor_entry[0] == id:
			return floor_entry[3]
	return PLANS[id][1]


func _warps_of(id: StringName) -> Array[Warp]:
	return (_maps[id] as GameMap).get_warps().get_all()


func test_every_floor_is_an_interior_with_its_light_and_shell() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var interiors := MapCatalog.load_interiors()
	for id: StringName in ALL:
		var map: GameMap = _maps[id]
		assert_eq(map.size, _size(id), "%s : taille" % id)
		assert_true(map.interior, "%s : intérieur (toit compris, [D])" % id)
		assert_true(interiors.has(id), "%s dans interiors.json" % id)
		assert_eq(map.display_name, "Céladopole")
		var expected := &"golden_hour" if id == ROOF else &"interior_warm"
		assert_eq(map.light_profile, expected, id)
		assert_eq(lighting.get_map_profile(id), expected)
		var shell := map.get_node(^"Shell") as Sprite2D
		assert_eq(shell.texture.get_size(), Vector2(map.size * 96), "%s : enveloppe" % id)


func test_scene_grid_is_the_functional_grid() -> void:
	for id: StringName in ALL:
		var map: GameMap = _maps[id]
		var plan: PlanGrid = _plans[id]
		var grid := map.get_grid()
		var mismatches := 0
		for y: int in map.size.y:
			for x: int in map.size.x:
				var cell := Vector2i(x, y)
				var solid := not plan.is_walkable(cell)
				if grid.is_solid(cell) != solid:
					mismatches += 1
					if mismatches <= 5:
						fail_test("%s %s « %s » : solide %s" % [id, cell, plan.at(cell),
							grid.is_solid(cell)])
		assert_eq(mismatches, 0, "%s = sa grille" % id)
		assert_eq(plan.walkable, ".X" if id == CABIN else ".XSZV")


func test_stairs_answer_each_other_floor_by_floor() -> void:
	for i: int in FLOORS.size():
		var id: StringName = FLOORS[i][0]
		var map: GameMap = _maps[id]
		var up_target: StringName = ROOF if i == FLOORS.size() - 1 else FLOORS[i + 1][0]
		for cell: Vector2i in STAIRS_UP:
			var warp := map.get_warps().find_on_step(cell, Vector2i.ZERO)
			assert_not_null(warp, "%s : escalier montant %s" % [id, cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], [up_target, &"from_down"])
		if i > 0:
			var down_target: StringName = FLOORS[i - 1][0]
			for cell: Vector2i in STAIRS_DOWN:
				var warp := map.get_warps().find_on_step(cell, Vector2i.ZERO)
				assert_not_null(warp, "%s : escalier descendant %s" % [id, cell])
				if warp != null:
					assert_eq([warp.target_map, warp.target_spawn], [down_target, &"from_up"])
		# Arrivées : devant l'escalier, tournées vers le bas, sur une case libre.
		assert_eq(map.get_spawn_cell(&"from_up"), Vector2i(2, 3), "%s : from_up" % id)
		if i > 0:
			assert_eq(map.get_spawn_cell(&"from_down"), Vector2i(4, 3), "%s : from_down" % id)
		assert_eq(map.get_spawn_cell(&"from_elevator"), Vector2i(16, 3))
	# Aller-retour : monter puis redescendre ramène devant l'escalier du départ.
	for i: int in range(FLOORS.size() - 1):
		var upper: GameMap = _maps[FLOORS[i + 1][0]]
		var arrival: Vector2i = upper.get_spawn_cell(&"from_down")
		var back := upper.get_warps().find_on_step(arrival + Vector2i.UP, Vector2i.ZERO)
		assert_not_null(back, "retour depuis l'étage %d" % (i + 1))
		if back != null:
			assert_eq(back.target_map, FLOORS[i][0])
			var lower: GameMap = _maps[FLOORS[i][0]]
			assert_eq(lower.get_spawn_cell(back.target_spawn), STAIRS_UP[0] + Vector2i.DOWN)
	for id: StringName in ALL:
		var map: GameMap = _maps[id]
		for warp: Warp in _warps_of(id):
			if not _maps.has(warp.target_map):
				continue
			var target: GameMap = _maps[warp.target_map]
			assert_true(target.has_spawn(warp.target_spawn),
				"%s → %s / %s : arrivée existante" % [id, warp.target_map, warp.target_spawn])
			var arrival := target.get_spawn_cell(warp.target_spawn)
			assert_false(target.get_grid().is_solid(arrival), "arrivée libre %s" % arrival)
			assert_false(map.get_grid().is_solid(warp.cell), "passage %s franchissable" % warp.cell)


func test_the_roof_is_reached_by_the_stairs_of_the_5th_floor_only() -> void:
	var sources: Dictionary = {}
	for id: StringName in ALL:
		for warp: Warp in _warps_of(id):
			if warp.target_map == ROOF:
				sources[id] = true
	assert_eq(sources.keys(), [&"celadon_dept_5f"], "seul l'escalier du 5e mène au toit")
	for warp: Warp in _warps_of(&"celadon_dept_5f"):
		if warp.target_map == ROOF:
			assert_eq(warp.cell.y, 2)
			assert_true(STAIRS_UP.has(warp.cell), "par l'escalier montant")
	# Ni porte d'ascenseur sur le toit, ni étage « toit » dans les données de l'ascenseur.
	var roof: GameMap = _maps[ROOF]
	for warp: Warp in _warps_of(ROOF):
		assert_ne(warp.target_map, CABIN, "pas d'ascenseur au toit")
	assert_eq(roof.get_spawn_cell(&"from_down"), Vector2i(2, 3))
	var library := ElevatorLibrary.new()
	assert_true(library.load_file(), "données de l'ascenseur")
	var lift := library.for_car(CABIN)
	assert_not_null(lift)
	if lift != null:
		var maps: Array[StringName] = []
		for floor_entry: Dictionary in lift.floors:
			maps.append(StringName(floor_entry["map"]))
		assert_eq(maps, [&"celadon_dept_gf", &"celadon_dept_2f", &"celadon_dept_3f",
			&"celadon_dept_4f", &"celadon_dept_5f"] as Array[StringName], "RdC → 5e sans le toit")
		for floor_entry: Dictionary in lift.floors:
			var target: GameMap = _maps[StringName(floor_entry["map"])]
			assert_true(target.has_spawn(StringName(floor_entry["spawn"])),
				"%s : arrivée de l'ascenseur" % floor_entry["map"])


func test_every_floor_has_the_lift_door_and_the_cabin_leads_back_to_the_ground_floor() -> void:
	for floor_entry: Array in FLOORS:
		var map: GameMap = _maps[floor_entry[0]]
		for cell: Vector2i in LIFT_DOORS:
			var warp := map.get_warps().find_on_step(cell, Vector2i.UP)
			assert_not_null(warp, "%s : porte de l'ascenseur %s" % [floor_entry[0], cell])
			if warp != null:
				assert_eq([warp.target_map, warp.target_spawn], [CABIN, &"entrance"])
	var cabin: GameMap = _maps[CABIN]
	assert_eq(cabin.get_spawn_cell(&"entrance"), Vector2i(2, 4))
	for cell: Vector2i in [Vector2i(2, 4), Vector2i(3, 4)]:
		var out := cabin.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie de la cabine %s" % cell)
		if out != null:
			# Par défaut, le premier étage (le moteur du T13 la réoriente vers l'étage courant).
			assert_eq([out.target_map, out.target_spawn], [&"celadon_dept_gf", &"from_elevator"])
	var panel: InteractPoint = null
	for child: Node in cabin.get_node(^"Interactables").get_children():
		panel = child as InteractPoint
	assert_not_null(panel, "panneau d'étages")
	if panel != null:
		assert_eq([panel.get_cell(), panel.size, panel.facing],
			[Vector2i(2, 1), Vector2i(2, 1), Vector2i.UP], "lu depuis (2..3, 2) ↑")
	# La cabine est fermée : seulement sa sortie.
	assert_eq(cabin.get_warps().size(), 2)


func test_ground_floor_exit_board_and_clients() -> void:
	var ground: GameMap = _maps[&"celadon_dept_gf"]
	assert_eq(ground.get_spawn_cell(&"entrance"), Vector2i(9, 11))
	var expected := {Vector2i(9, 11): &"from_dept_w", Vector2i(10, 11): &"from_dept_e"}
	for cell: Vector2i in expected:
		var out := ground.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie %s" % cell)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"celadon_city", expected[cell]])
	var city := (load(MapCatalog.scene_path(&"celadon_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	assert_eq(city.get_spawn_cell(&"from_dept_w"), Vector2i(10, 16))
	assert_eq(city.get_spawn_cell(&"from_dept_e"), Vector2i(11, 16))
	# Les autres étages n'ont aucune sortie vers la ville.
	for id: StringName in ALL:
		if id == &"celadon_dept_gf":
			continue
		for warp: Warp in _warps_of(id):
			assert_ne(warp.target_map, &"celadon_city", "%s : pas de sortie directe" % id)
	var board: InteractPoint = null
	for child: Node in ground.get_node(^"Interactables").get_children():
		board = child as InteractPoint
	assert_not_null(board, "tableau des étages")
	if board != null:
		assert_eq([board.get_cell(), board.size, board.facing],
			[Vector2i(9, 2), Vector2i(2, 1), Vector2i.UP])
		assert_eq(board.dialogue_id, &"celadon_dept_board")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_eq(dialogues.get_dialogue(&"celadon_dept_board").variants[0].pages[0].text,
		"RdC Accueil · 2e Soins et CT · 3e Jeux · 4e Cadeaux et pierres · 5e Salon · Toit",
		"texte 22")


func test_npc_cells_are_free_and_reachable_without_cutting_the_floor() -> void:
	for id: StringName in ALL:
		var plan: PlanGrid = _plans[id]
		var map: GameMap = _maps[id]
		var npc_cells: Array[Vector2i] = []
		for pos: String in plan.positions:
			if plan.positions[pos]["kind"] in ["pnj", "dresseur", "pokemon"]:
				npc_cells.append_array(plan.cells_at(pos))
		var terrain := GridPaths.relief(map.get_grid(), map.size)
		var start := map.get_spawn_cell(&"entrance" if id == CABIN else (
			&"from_down" if id == ROOF else &"from_up"))
		var open := GridPaths.distances(terrain, [start])
		for cell: Vector2i in npc_cells:
			assert_false(map.get_grid().is_solid(cell), "%s %s : case libre" % [id, cell])
			assert_true(open.has(cell), "%s %s : atteignable" % [id, cell])
			terrain.set_solid(cell)
		var reach := GridPaths.distances(terrain, [start])
		for cell: Vector2i in plan.cells_of(".XSZV"):
			if npc_cells.has(cell):
				continue
			assert_true(reach.has(cell), "%s %s : jamais coupée par un habitant" % [id, cell])


## Le trajet RdC → 5e → sortie au 5e dépend du moteur d'ascenseur (T13).
func test_elevator_ride_waits_for_the_engine() -> void:
	if not ClassDB.class_exists(&"ElevatorDirector") \
			and not FileAccess.file_exists("res://game/world/elevator/elevator_director.gd"):
		pending("trajet d'ascenseur RdC → 5e → sortie au 5e : en attente du T13 (ElevatorDirector)")
		return
	pending("à brancher sur test_elevator_flow du T13")
