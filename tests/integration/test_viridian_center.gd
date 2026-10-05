extends GutTest
## Carte du Centre Pokémon de Jadielle (jalon 7 T8, jalon-07.md §6.3 ; dossier 09 §7, arbitrages
## « pas de Leveinard », « pas d'escalier ») : métadonnées et lumière, enveloppe et meubles
## peints (emprises solides), murs relevés sur l'enveloppe, sortie sur le paillasson, infirmière
## derrière le comptoir (inaccessible), parler par-dessus le comptoir, point de repos devant le
## comptoir, machine de soin, terminal posé **inerte** (T16), Dresseuse et son Roucool au repos
## sur des cases libres, toute la salle atteignable depuis l'entrée.

const MAP_PATH := "res://game/world/maps/viridian_center.tscn"
const SIZE := Vector2i(15, 10)
const EXIT := [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
const ENTRANCE := Vector2i(7, 8)
const HEAL := Vector2i(7, 5)
const NURSE := Vector2i(7, 3)
const COUNTER := [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4)]
const TERMINAL := [Vector2i(1, 3), Vector2i(2, 3)]

var _map: GameMap
var _grid: GridWorld
var _terrain: GridWorld


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_solid(Vector2i(x, y)):
				_terrain.set_solid(Vector2i(x, y))


func after_all() -> void:
	_map.free()


func test_metadata_and_light() -> void:
	assert_eq(_map.map_id, &"viridian_center")
	assert_eq(_map.display_name, "Jadielle", "titre des intérieurs = la ville")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior)
	assert_eq(_map.light_profile, &"interior_warm")
	var shell := _map.get_node_or_null(^"Shell") as Sprite2D
	assert_not_null(shell, "enveloppe peinte")
	if shell != null:
		assert_eq(shell.texture.get_size(), Vector2(SIZE * Grid.TILE_SIZE), "1:1, 15 × 10 cases")
		assert_lt(shell.z_index, 0, "sous les personnages")
	assert_true(_map.get_entities().y_sort_enabled)


func test_furniture_is_painted_and_solid() -> void:
	var expected := {
		&"Counter": "int_centre_comptoir", &"StorageTerminal": "int_centre_terminal",
		&"BenchWest": "int_centre_banquette", &"BenchEast": "int_centre_banquette",
		&"PlantNorthEast": "int_plante", &"PlantSouthWest": "int_plante",
		&"PlantSouthEast": "int_plante",
	}
	for node_name: StringName in expected:
		var prop := _map.get_entities().get_node_or_null(NodePath(node_name)) as WorldProp
		assert_not_null(prop, String(node_name))
		if prop == null:
			continue
		assert_string_contains(prop.scene_file_path, expected[node_name])
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(_grid.is_solid(cell), "%s : %s solide" % [node_name, cell])
	for cell: Vector2i in COUNTER + TERMINAL:
		assert_true(_grid.is_solid(cell), "meuble en %s" % cell)
	# Pas d'escalier, pas de Leveinard (arbitrages du dossier 09).
	for child: Node in _map.get_entities().get_children():
		assert_false(String(child.name).to_lower().contains("stair"), String(child.name))


func test_walls_follow_the_shell() -> void:
	for x: int in SIZE.x:
		for y: int in [0, 1, 2, SIZE.y - 1]:
			assert_true(_grid.is_solid(Vector2i(x, y)), "mur (%d, %d)" % [x, y])
		if not EXIT.has(Vector2i(x, 8)):
			assert_true(_grid.is_solid(Vector2i(x, 8)), "mur du bas (%d, 8)" % x)
	for y: int in SIZE.y:
		assert_true(_grid.is_solid(Vector2i(0, y)))
		assert_true(_grid.is_solid(Vector2i(SIZE.x - 1, y)))


func test_exit_on_the_mat_leads_back_to_viridian() -> void:
	assert_eq(_map.get_spawn_cell(&"entrance"), ENTRANCE)
	for cell: Vector2i in EXIT:
		assert_false(_grid.is_solid(cell), "paillasson praticable %s" % cell)
		var exit := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(exit, "sortie %s" % cell)
		if exit != null:
			assert_eq([exit.target_map, exit.target_spawn], [&"viridian_city", &"from_center"])


func test_the_nurse_is_behind_the_counter_and_out_of_reach() -> void:
	var nurse := _map.get_npc(&"nurse")
	assert_not_null(nurse, "infirmière")
	if nurse == null:
		return
	assert_eq(nurse.get_cell(), NURSE)
	assert_eq(nurse.get_spec().sprite, &"nurse")
	assert_true(CharacterLook.resolve(&"nurse").painted, "apparence peinte")
	assert_false(nurse.get_spec().is_interactive(), "on lui parle par le comptoir")
	var reach := _terrain.find_reachable(ENTRANCE)
	for cell: Vector2i in [NURSE, Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 3),
			Vector2i(9, 3)]:
		assert_false(reach.has(cell), "derrière le comptoir : %s inaccessible" % cell)


func test_talking_to_the_nurse_across_the_counter() -> void:
	var table := _map.get_interactions()
	for x: int in [6, 7, 8]:
		var interaction := InteractionFinder.find(_grid, table, Vector2i(x, 5), Vector2i.UP)
		assert_not_null(interaction, "devant le comptoir (%d, 5)" % x)
		if interaction != null:
			assert_eq(interaction.dialogue_id, &"nurse")
			assert_eq(interaction.kind, Interaction.Kind.TALK, "PARLER")
	assert_null(InteractionFinder.find(_grid, table, Vector2i(7, 5), Vector2i.LEFT),
		"seulement face au comptoir")


func test_rest_point_is_in_front_of_the_counter() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"viridian_center")
	assert_not_null(point)
	if point == null:
		return
	assert_true(point.registers, "un Centre s'enregistre")
	assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	assert_eq(point.facing, Vector2i.UP, "réveil face à l'infirmière")
	assert_eq(_map.get_spawn_cell(point.spawn), HEAL)
	assert_false(_grid.is_solid(HEAL))
	assert_not_null(InteractionFinder.find(_grid, _map.get_interactions(), HEAL, point.facing),
		"au réveil, l'infirmière est devant")


func test_heal_machine_sits_on_the_counter() -> void:
	var machine := _map.get_node_or_null(^"%HealMachine") as HealMachine
	assert_not_null(machine, "%HealMachine")
	if machine == null:
		return
	assert_eq(machine.attendant, &"nurse")
	assert_eq(machine.get_slots().size(), HealMachine.SLOT_COUNT, "six alvéoles")
	var counter := _map.get_entities().get_node(^"Counter") as Node2D
	assert_gt(machine.position.y, counter.position.y, "dessinée devant le comptoir")
	assert_true(machine.get_animation_player().has_animation(HealMachine.ANIMATION))
	for slot: Sprite2D in machine.get_slots():
		assert_eq(slot.modulate.a, 0.0, "éteinte au repos")


func test_terminal_is_inert_until_the_storage_task() -> void:
	var table := _map.get_interactions()
	for cell: Vector2i in TERMINAL:
		for from: Vector2i in [cell + Vector2i.DOWN, cell + Vector2i.RIGHT]:
			if _grid.is_solid(from):
				continue
			var facing := cell - from
			assert_null(InteractionFinder.find(_grid, table, from, facing),
				"terminal inerte (T16) depuis %s" % from)


func test_resting_trainer_and_her_pidgey() -> void:
	var lass := _map.get_npc(&"center_lass")
	var pidgey := _map.get_npc(&"center_lass_pidgey")
	assert_not_null(lass)
	assert_not_null(pidgey)
	if lass == null or pidgey == null:
		return
	assert_eq(lass.get_spec().dialogue, &"center_lass")
	assert_eq(pidgey.get_spec().sprite, &"pokemon/pidgey", "aucune espèce nouvelle")
	assert_eq(pidgey.get_spec().idle_react_every, 6.0)
	for npc: Npc in [lass, pidgey]:
		assert_false(_terrain.is_solid(npc.get_cell()), "%s sur une case libre" % npc.get_id())
		assert_true(_terrain.find_reachable(ENTRANCE).has(npc.get_cell()))


func test_the_whole_room_is_reachable_with_the_inhabitants_in_place() -> void:
	var free := _terrain.find_reachable(ENTRANCE)
	var crowded := _grid.find_reachable(ENTRANCE)
	assert_true(crowded.has(HEAL), "devant le comptoir")
	for cell: Vector2i in free:
		if _grid.is_occupied(cell):
			continue
		assert_true(crowded.has(cell), "les habitants ne ferment aucune case : %s" % cell)
	# Le terminal s'utilisera depuis la salle (T16).
	assert_true(free.has(Vector2i(1, 4)) or free.has(Vector2i(2, 4)), "devant le terminal")
