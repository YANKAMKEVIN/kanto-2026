extends GutTest
## Carte de la Boutique de Jadielle (jalon 7 T12, jalon-07.md §6.4 ; dossier 09 §4, §9 ;
## agencement du prototype validé) : métadonnées et lumière, enveloppe et meubles peints
## (caisse, deux rayons muraux sans étiquette, deux présentoirs, une plante ; emprises
## solides), murs relevés sur l'enveloppe, sortie sur le paillasson bleu, marchand derrière la
## caisse (inaccessible), parler par-dessus la caisse, déclencheur de la première visite sur la
## rangée d'entrée (seul passage), livreur sur une case libre, toute la salle atteignable.

const MAP_PATH := "res://game/world/maps/viridian_mart.tscn"
const SIZE := Vector2i(15, 10)
const EXIT := [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]
const ENTRANCE := Vector2i(7, 8)
const COUNTER_SPOT := Vector2i(7, 5)
const CLERK := Vector2i(7, 3)
const COUNTER := [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4)]
const TRIGGER_ROW := [Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7),
	Vector2i(9, 7)]

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
	assert_eq(_map.map_id, &"viridian_mart")
	assert_eq(_map.display_name, "Jadielle", "titre des intérieurs = la ville")
	assert_eq(_map.size, SIZE)
	assert_true(_map.interior)
	assert_eq(_map.light_profile, &"interior_warm")
	var shell := _map.get_node_or_null(^"Shell") as Sprite2D
	assert_not_null(shell, "enveloppe peinte")
	if shell != null:
		assert_string_contains(shell.texture.resource_path, "int_boutique_coque")
		assert_eq(shell.texture.get_size(), Vector2(SIZE * Grid.TILE_SIZE), "1:1, 15 × 10 cases")
		assert_lt(shell.z_index, 0, "sous les personnages")
	assert_true(_map.get_entities().y_sort_enabled)


func test_furniture_is_painted_and_solid() -> void:
	var expected := {
		&"Counter": "int_boutique_caisse", &"ShelfWest": "int_boutique_rayon_mural",
		&"ShelfEast": "int_boutique_rayon_mural", &"StandWest": "int_boutique_presentoir",
		&"StandEast": "int_boutique_presentoir", &"PlantSouthEast": "int_plante",
	}
	var props := 0
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp:
			props += 1
	assert_eq(props, expected.size(), "caisse, deux rayons, deux présentoirs, une plante")
	for node_name: StringName in expected:
		var prop := _map.get_entities().get_node_or_null(NodePath(node_name)) as WorldProp
		assert_not_null(prop, String(node_name))
		if prop == null:
			continue
		assert_string_contains(prop.scene_file_path, expected[node_name])
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(_grid.is_solid(cell), "%s : %s solide" % [node_name, cell])
	for cell: Vector2i in COUNTER:
		assert_true(_grid.is_solid(cell), "caisse en %s" % cell)
	# Présentoirs symétriques de part et d'autre de l'allée du paillasson.
	for x: int in [2, 3, 4, 10, 11, 12]:
		assert_true(_grid.is_solid(Vector2i(x, 7)), "présentoir (%d, 7)" % x)


func test_walls_follow_the_shell() -> void:
	for x: int in SIZE.x:
		for y: int in [0, 1, 2, SIZE.y - 1]:
			assert_true(_grid.is_solid(Vector2i(x, y)), "mur (%d, %d)" % [x, y])
		if not EXIT.has(Vector2i(x, 8)):
			assert_true(_grid.is_solid(Vector2i(x, 8)), "mur du bas (%d, 8)" % x)
	for y: int in SIZE.y:
		assert_true(_grid.is_solid(Vector2i(0, y)))
		assert_true(_grid.is_solid(Vector2i(SIZE.x - 1, y)))


func test_exit_on_the_blue_mat_leads_back_to_viridian() -> void:
	assert_eq(_map.get_spawn_cell(&"entrance"), ENTRANCE)
	for cell: Vector2i in EXIT:
		assert_false(_grid.is_solid(cell), "paillasson praticable %s" % cell)
		var exit := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(exit, "sortie %s" % cell)
		if exit != null:
			assert_eq([exit.target_map, exit.target_spawn], [&"viridian_city", &"from_mart"])
			assert_eq(exit.facing, Vector2i.DOWN)


func test_the_clerk_is_behind_the_counter_and_out_of_reach() -> void:
	var clerk := _map.get_npc(&"clerk")
	assert_not_null(clerk, "marchand")
	if clerk == null:
		return
	assert_eq(clerk.get_cell(), CLERK)
	assert_eq(clerk.get_facing(), Vector2i.DOWN)
	assert_eq(clerk.get_spec().sprite, &"clerk")
	assert_true(CharacterLook.resolve(&"clerk").painted, "apparence peinte")
	assert_false(clerk.get_spec().is_interactive(), "on lui parle par la caisse")
	var reach := _terrain.find_reachable(ENTRANCE)
	for cell: Vector2i in [CLERK, Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 3),
			Vector2i(9, 3)]:
		assert_false(reach.has(cell), "derrière la caisse : %s inaccessible" % cell)


func test_talking_to_the_clerk_across_the_counter() -> void:
	var table := _map.get_interactions()
	for x: int in [6, 7, 8]:
		var interaction := InteractionFinder.find(_grid, table, Vector2i(x, 5), Vector2i.UP)
		assert_not_null(interaction, "devant la caisse (%d, 5)" % x)
		if interaction != null:
			assert_eq(interaction.dialogue_id, &"clerk")
			assert_eq(interaction.kind, Interaction.Kind.TALK, "PARLER")
	assert_null(InteractionFinder.find(_grid, table, COUNTER_SPOT, Vector2i.LEFT),
		"seulement face à la caisse")
	assert_eq(_map.get_spawn_cell(&"counter"), COUNTER_SPOT)


## Le déclencheur couvre toute la rangée qu'on traverse depuis le paillasson : sans lui, on
## n'atteint rien d'autre que le paillasson.
func test_the_first_visit_trigger_covers_the_only_way_in() -> void:
	var triggers := _map.get_triggers()
	for cell: Vector2i in TRIGGER_ROW:
		for facing: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var trigger := triggers.find_on_step(cell, facing)
			assert_not_null(trigger, "déclencheur %s (%s)" % [cell, facing])
			if trigger != null:
				assert_eq(trigger.cutscene_id, &"mart_parcel")
	var fenced := GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _terrain.is_solid(cell) or TRIGGER_ROW.has(cell):
				fenced.set_solid(cell)
	assert_eq(fenced.find_reachable(ENTRANCE).size(), EXIT.size(), "seul passage")
	assert_null(triggers.find_on_step(ENTRANCE, Vector2i.UP), "pas sur le paillasson")


func test_the_courier_stands_on_a_free_cell() -> void:
	var courier := _map.get_npc(&"mart_courier")
	assert_not_null(courier)
	if courier == null:
		return
	assert_eq(courier.get_spec().dialogue, &"mart_courier")
	assert_eq(courier.get_spec().sprite, &"courier")
	assert_false(_terrain.is_solid(courier.get_cell()))
	assert_true(_terrain.find_reachable(ENTRANCE).has(courier.get_cell()))


func test_the_whole_room_is_reachable_with_the_inhabitants_in_place() -> void:
	var free := _terrain.find_reachable(ENTRANCE)
	var crowded := _grid.find_reachable(ENTRANCE)
	assert_true(crowded.has(COUNTER_SPOT), "devant la caisse")
	for cell: Vector2i in free:
		if _grid.is_occupied(cell):
			continue
		assert_true(crowded.has(cell), "les habitants ne ferment aucune case : %s" % cell)
	assert_gt(free.size(), 30, "une vraie petite salle")
