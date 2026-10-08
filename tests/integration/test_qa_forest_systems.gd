extends GutTest
## Carte de QA du jalon 9 (`qa_forest_systems`, jalon-09.md §2.6, T6) : sortie vers Jadielle,
## points d'apparition des départs de débogage, hautes herbes de la table de la forêt, garde,
## et **gabarit des Dresseurs** (posés au T12) : couloir de Théo inévitable, croisement de Noé
## et de Milo, Tom abordable de côté.

const MAP_ID := &"qa_forest_systems"
const SIZE := Vector2i(26, 20)
## Cases réservées (contrat avec tools/build_qa_forest_systems.gd, `TRAINER_SLOTS`) :
## [case, orientation, vision].
const THEO := [Vector2i(16, 8), Vector2i.DOWN, 4]
const NOE := [Vector2i(7, 3), Vector2i.RIGHT, 5]
const MILO := [Vector2i(11, 1), Vector2i.DOWN, 5]
const TOM := [Vector2i(19, 4), Vector2i.LEFT, 4]
const ELI := [Vector2i(23, 1), Vector2i.DOWN, 5]
const START_GRASS := Rect2i(2, 15, 5, 4)

var _map: GameMap
var _grid: GridWorld


func before_each() -> void:
	_map = (load(MapCatalog.scene_path(MAP_ID)) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	_grid = _map.get_grid()


## Cases vues par un Dresseur (ligne droite, arrêtée par la première case solide).
func _sight(slot: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell: Vector2i = slot[0]
	for i: int in range(1, int(slot[2]) + 1):
		cell += slot[1] as Vector2i
		if not _grid.is_in_bounds(cell) or _grid.is_solid(cell):
			break
		cells.append(cell)
	return cells


## Cases atteignables depuis [param from] sans entrer dans [param blocked] ni franchir une case
## solide ni un PNJ.
func _reach(from: Vector2i, blocked: Array[Vector2i] = []) -> Dictionary:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + dir
			if seen.has(next) or blocked.has(next) or not _grid.is_in_bounds(next):
				continue
			if _grid.is_solid(next) or _grid.is_occupied(next):
				continue
			seen[next] = true
			queue.append(next)
	return seen


func test_scene_is_a_provisional_qa_map() -> void:
	assert_eq(_map.map_id, MAP_ID)
	assert_eq(_map.size, SIZE)
	assert_true(MapCatalog.is_qa_map(_map.map_id))
	assert_true(_map.light_profile.is_empty(), "aucune lumière")
	assert_false(_map.interior)


func test_exit_leads_to_viridian_in_front_of_the_center() -> void:
	var warps := _map.get_warps()
	assert_eq(warps.size(), 3)
	for x: int in [10, 11, 12]:
		var warp := warps.find_on_push(Vector2i(x, 18), Vector2i.DOWN)
		assert_not_null(warp, "sortie en (%d, 18)" % x)
		assert_eq([warp.target_map, warp.target_spawn], [&"viridian_city", &"from_center"])
		assert_true(_grid.is_solid(Vector2i(x, 19)), "bordure solide sous la sortie")
	assert_null(warps.find_on_push(Vector2i(9, 18), Vector2i.DOWN), "trois cases, pas plus")
	var viridian := (load(MapCatalog.scene_path(&"viridian_city")) as PackedScene).instantiate()
	assert_true((viridian as GameMap).has_spawn(&"from_center"), "spawn existant, Jadielle intacte")
	viridian.free()


func test_no_warp_leads_to_the_qa_map() -> void:
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if not file.ends_with(".tscn") or file.begins_with("qa_"):
			continue
		var scene := load(MapCatalog.MAPS_DIR + file) as PackedScene
		var map := scene.instantiate() as GameMap
		for warp: Warp in map.get_warps().get_all():
			assert_ne(warp.target_map, MAP_ID, "%s : aucun passage vers la carte de QA" % file)
		map.free()


func test_spawns_of_the_debug_starts() -> void:
	var guard_cell := Vector2i(11, 15)
	for spawn: StringName in [&"poison_start", &"evolution_start", &"theo_corridor"]:
		assert_true(_map.has_spawn(spawn), String(spawn))
		var cell := _map.get_spawn_cell(spawn)
		assert_true(_grid.is_free(cell), "%s : case libre" % spawn)
	assert_eq(_map.get_spawn_cell(&"poison_start"), guard_cell + Vector2i.DOWN, "devant le garde")
	# Au bord des hautes herbes, tourné vers elles.
	var edge := _map.get_spawn_cell(&"evolution_start")
	assert_true(_grid.is_tall_grass(edge + Vector2i.LEFT))
	assert_false(_grid.is_tall_grass(edge))
	# Dans le couloir, à 4 cases de la ligne de vue de Théo.
	var corridor := _map.get_spawn_cell(&"theo_corridor")
	assert_eq(corridor, Vector2i(THEO[0].x + 4, 12))


func test_start_grass_is_5_by_4_and_uses_the_forest_table() -> void:
	var grass := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_tall_grass(Vector2i(x, y)):
				grass += 1
	for cell: Vector2i in _cells(START_GRASS):
		assert_true(_grid.is_tall_grass(cell), str(cell))
	assert_eq(grass, 20 + 3, "5 × 4 au sud + la bande de contournement de Milo")
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(MAP_ID))
	var table := library.get_table(MAP_ID)
	assert_eq(table.id, &"viridian_forest_grass")
	assert_eq(table.slots.size(), 5)
	assert_false(library.has_table(&"qa_other"))


func _cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


func test_south_guard_stands_north_of_the_start_and_talks() -> void:
	var guard := _map.get_npc(&"south_guard")
	assert_not_null(guard)
	assert_eq(guard.get_cell(), Vector2i(11, 15))
	assert_eq(guard.get_spec().dialogue, &"forest_gate_south_guard")
	assert_true(guard.get_spec().is_interactive())
	# Il ne bouche pas le chemin du couloir : de la sortie à l'entrée de la montée est.
	var reach := _reach(_map.get_spawn_cell(&"poison_start"))
	assert_true(reach.has(Vector2i(24, 14)), "montée vers le couloir atteignable")
	assert_true(reach.has(Vector2i(11, 18)), "sortie atteignable")


func test_corridor_is_one_cell_wide() -> void:
	for x: int in range(9, 24):
		var cell := Vector2i(x, 12)
		assert_false(_grid.is_solid(cell), "couloir %s" % cell)
		if x != THEO[0].x:
			assert_true(_grid.is_solid(cell + Vector2i.UP), "mur au nord de %s" % cell)
		assert_true(_grid.is_solid(cell + Vector2i.DOWN), "mur au sud de %s" % cell)


func test_theo_corridor_cannot_be_crossed_without_entering_his_sight() -> void:
	var start := _map.get_spawn_cell(&"theo_corridor")
	var north := Vector2i(8, 6)
	assert_true(_reach(start).has(north), "la zone nord est atteignable")
	var sight := _sight(THEO)
	assert_eq(sight, [Vector2i(16, 9), Vector2i(16, 10), Vector2i(16, 11), Vector2i(16, 12)])
	assert_false(_reach(start, sight).has(north), "inévitable : aucun détour")
	assert_false(_reach(_map.get_spawn_cell(&"poison_start"), sight).has(north),
		"inévitable depuis le sud aussi")
	# La case de détection (la première de la ligne rencontrée) laisse 3 cases à Théo pour
	# s'approcher : ≥ 2 cases entre lui et le joueur.
	var detection: Vector2i = sight[sight.size() - 1]
	assert_gte(detection.y - THEO[0].y - 1, 2)
	# Il reste dans son alcôve en s'approchant : le couloir n'est jamais fermé.
	var after := _reach(start, [Vector2i(16, 11)])
	assert_true(after.has(Vector2i(8, 12)), "Théo en (16, 11) laisse le couloir ouvert")
	assert_true(after.has(north), "…et la montée vers le nord")


func test_noe_and_milo_sights_cross_and_milo_can_be_bypassed_through_grass() -> void:
	var noe := _sight(NOE)
	var milo := _sight(MILO)
	assert_eq(noe.size(), 5)
	assert_eq(milo, [Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4)], "coupée par l'arbre")
	var crossing: Array[Vector2i] = []
	for cell: Vector2i in noe:
		if milo.has(cell):
			crossing.append(cell)
	assert_eq(crossing, [Vector2i(11, 3)], "un seul croisement : un seul défi à la fois")
	var entry := Vector2i(8, 6)
	var east := Vector2i(19, 3)
	# Les Dresseurs eux-mêmes occupent leur case (Milo ferme la rangée du haut).
	var lines: Array[Vector2i] = noe + milo
	lines.append(NOE[0])
	lines.append(MILO[0])
	assert_true(_reach(entry, lines).has(east), "les deux sont contournables")
	var grass: Array[Vector2i] = []
	for x: int in [10, 11, 12]:
		assert_true(_grid.is_tall_grass(Vector2i(x, 6)))
		grass.append(Vector2i(x, 6))
	var all_blocked: Array[Vector2i] = lines + grass
	assert_false(_reach(entry, all_blocked).has(east), "le détour passe par les hautes herbes")


func test_tom_can_be_reached_from_the_side_and_eli_at_the_far_end() -> void:
	var cell: Vector2i = TOM[0]
	assert_false(_grid.is_solid(cell))
	assert_eq(_sight(TOM).size(), 4)
	for side: Vector2i in [cell + Vector2i.UP, cell + Vector2i.DOWN]:
		assert_false(_grid.is_solid(side), "case de côté %s" % side)
		assert_false(_sight(TOM).has(side), "hors de sa vision")
	var blocked: Array[Vector2i] = _sight(NOE) + _sight(MILO)
	blocked.append(NOE[0])
	blocked.append(MILO[0])
	var reach := _reach(Vector2i(8, 6), blocked)
	assert_true(reach.has(cell + Vector2i.UP), "abordable de côté sans passer par sa vision")
	var eli: Vector2i = ELI[0]
	var near_eli := _reach(Vector2i(8, 6))
	assert_true(near_eli.has(eli + Vector2i.DOWN), "Éli est atteignable (case devant lui)")
	assert_eq(_sight(ELI).size(), 5)


func test_every_trainer_slot_is_free_ground() -> void:
	for slot: Array in [THEO, NOE, MILO, TOM, ELI]:
		assert_false(_grid.is_solid(slot[0]), str(slot[0]))
		assert_false(_grid.is_tall_grass(slot[0]), "pas dans les hautes herbes : %s" % slot[0])


## Jalon 9 (T12) : les cinq Dresseurs sont posés sur leurs cases réservées, avec la vision, le
## regard et les répliques prévus ; aucun ne se tient dans l'axe d'un passage d'une case.
func test_trainers_are_posed_on_their_reserved_slots() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"theo": [THEO, &"forest_scout_theo"], &"noe": [NOE, &"forest_scout_noe"],
		&"milo": [MILO, &"forest_scout_milo"], &"tom": [TOM, &"forest_youngster_tom"],
		&"eli": [ELI, &"forest_scout_eli"],
	}
	for id: StringName in expected:
		var npc := _map.get_npc(id)
		assert_not_null(npc, String(id))
		if npc == null:
			continue
		var slot: Array = expected[id][0]
		var spec := npc.get_spec()
		assert_eq(spec.cell, slot[0], "%s : case" % id)
		assert_eq(spec.facing, slot[1], "%s : regard" % id)
		assert_eq(spec.sight, slot[2], "%s : vision" % id)
		assert_eq(spec.trainer_id, expected[id][1])
		assert_eq(spec.before_dialogue, StringName(String(spec.trainer_id) + "_before"))
		assert_eq(spec.dialogue, StringName(String(spec.trainer_id) + "_after"))
		assert_true(spec.is_trainer())
		assert_eq(npc.get_cell(), slot[0], "%s : posé sur la grille" % id)


func test_no_trainer_stands_in_the_axis_of_a_one_cell_passage() -> void:
	# Le couloir (rangée 12) est perpendiculaire à la vision de Théo : on le traverse, on ne
	# marche jamais le long de sa ligne ; aucune case du couloir n'est dans la vision d'un autre.
	for slot: Array in [NOE, MILO, TOM, ELI]:
		for cell: Vector2i in _sight(slot):
			assert_ne(cell.y, 12, "la vision de %s ne longe pas le couloir" % str(slot[0]))
