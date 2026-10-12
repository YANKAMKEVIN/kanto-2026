extends GutTest
## Carte de QA du jalon 13 (`qa_switch_j13`, jalon-13.md §2.21, T14) et départ `switch_qa` :
## sortie, points d'apparition, hautes herbes, Dresseurs d'essai (couloirs de vue séparés,
## `switch` pour deux sur trois), départ lisible (9 espèces au Pokédex, Vol-Vie, Bulles d'O,
## Acide, table forcée). Données `qa_*` retirées au T22.

const MAP_ID := &"qa_switch_j13"
const SIZE := Vector2i(24, 16)
const GRASS := Rect2i(1, 10, 5, 4)
const SLOTS := {
	&"rival": [Vector2i(5, 3), &"qa_switch_rival", true],
	&"misty": [Vector2i(11, 3), &"qa_switch_misty", true],
	&"witness": [Vector2i(17, 3), &"qa_switch_witness", false],
}
const NINE: Array[StringName] = [&"oddish", &"gloom", &"bellsprout", &"weepinbell",
	&"shellder", &"horsea", &"goldeen", &"staryu", &"starmie"]

var _map: GameMap
var _grid: GridWorld
var _data: PokemonData
var _items: ItemLibrary


func before_each() -> void:
	_map = (load(MapCatalog.scene_path(MAP_ID)) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	_grid = _map.get_grid()
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _sight(cell: Vector2i, length: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in range(1, length + 1):
		var next := cell + Vector2i(0, i)
		if _grid.is_solid(next):
			break
		cells.append(next)
	return cells


func test_scene_is_a_provisional_qa_map() -> void:
	assert_eq(_map.map_id, MAP_ID)
	assert_eq(_map.size, SIZE)
	assert_true(MapCatalog.is_qa_map(MAP_ID))
	assert_true(_map.light_profile.is_empty())


func test_exit_leads_to_viridian_center_and_nothing_leads_here() -> void:
	var warps := _map.get_warps()
	assert_eq(warps.size(), 3)
	for x: int in [10, 11, 12]:
		var warp := warps.find_on_push(Vector2i(x, 14), Vector2i.DOWN)
		assert_not_null(warp)
		assert_eq([warp.target_map, warp.target_spawn], [&"viridian_city", &"from_center"])
		assert_true(_grid.is_solid(Vector2i(x, 15)))
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if not file.ends_with(".tscn") or file.begins_with("qa_"):
			continue
		var map := (load(MapCatalog.MAPS_DIR + file) as PackedScene).instantiate() as GameMap
		for warp: Warp in map.get_warps().get_all():
			assert_ne(warp.target_map, MAP_ID, file)
		map.free()


func test_spawns_are_free_and_lanes_end_at_the_trainer_sight() -> void:
	for spawn: StringName in [&"switch_start", &"lane_rival", &"lane_misty", &"lane_witness"]:
		assert_true(_map.has_spawn(spawn), String(spawn))
		assert_true(_grid.is_free(_map.get_spawn_cell(spawn)), String(spawn))
	var lanes := {&"rival": &"lane_rival", &"misty": &"lane_misty",
		&"witness": &"lane_witness"}
	for key: StringName in SLOTS:
		var cell: Vector2i = SLOTS[key][0]
		var sight := _sight(cell, 5)
		assert_eq(sight.size(), 5, "%s : vision libre" % key)
		var spawn := _map.get_spawn_cell(lanes[key])
		assert_eq(spawn, cell + Vector2i(0, 6), "%s : une case sous la vision" % key)
		assert_false(sight.has(spawn))


func test_lanes_do_not_overlap() -> void:
	var seen: Dictionary = {}
	for key: StringName in SLOTS:
		for cell: Vector2i in _sight(SLOTS[key][0], 5):
			assert_false(seen.has(cell), "%s : couloir partagé en %s" % [key, cell])
			seen[cell] = true


func test_grass_patch_is_free_of_trainer_lanes_and_uses_the_forced_table() -> void:
	for y: int in range(GRASS.position.y, GRASS.end.y):
		for x: int in range(GRASS.position.x, GRASS.end.x):
			assert_true(_grid.is_tall_grass(Vector2i(x, y)))
	var count := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_tall_grass(Vector2i(x, y)):
				count += 1
	assert_eq(count, 20)
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/switch_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq(start.map, MAP_ID)
	assert_true(_map.has_spawn(start.spawn))
	assert_eq(start.wild["slots"].size(), 2)
	var species: Array = []
	for slot: Dictionary in start.wild["slots"]:
		species.append([slot["species"], int(slot["levels"][0])])
	assert_eq(species, [["oddish", 24], ["bellsprout", 21]])


func test_trainers_are_on_the_map_with_the_expected_switch_flags() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	for key: StringName in SLOTS:
		var npc := _map.get_npc(key)
		assert_not_null(npc, String(key))
		assert_eq(npc.get_cell(), SLOTS[key][0])
		assert_eq(npc.get_spec().facing, Vector2i.DOWN)
		assert_eq(npc.get_spec().sight, 5)
		assert_eq(npc.get_spec().trainer_id, SLOTS[key][1])
		var trainer := library.get_trainer(SLOTS[key][1])
		assert_not_null(trainer)
		assert_eq(trainer.can_switch, SLOTS[key][2], "%s : switch" % key)
		assert_eq(trainer.ai, &"smart")
	# Le témoin a la même équipe que « Ondine d'essai » : seule la clé change.
	var misty := library.get_trainer(&"qa_switch_misty")
	var witness := library.get_trainer(&"qa_switch_witness")
	assert_eq(misty.team.size(), witness.team.size())
	assert_eq(misty.team[0].species, &"staryu")
	assert_eq(misty.team[1].species, &"starmie")


func test_switch_qa_start_gives_nine_species_and_the_test_moves() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file("res://tools/debug_start/switch_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	var stored: Array[StringName] = []
	for member: Dictionary in start.storage:
		stored.append(StringName(member["species"]))
	assert_eq(stored, NINE, "les 9 espèces du J13, au Pokédex par le Stockage")
	assert_eq(start.party.size(), 6)
	assert_eq(StringName(start.party[0]["species"]), &"squirtle", "Carapuce en tête (rival)")
	var moves: Dictionary = {}
	for member: Dictionary in start.party:
		if member.has("moves"):
			moves[member["species"]] = member["moves"]
	assert_true(moves["oddish"].has("absorb"), "Vol-Vie")
	assert_true(moves["oddish"].has("acid"), "Acide")
	assert_true(moves["starmie"].has("bubble_beam"), "Bulles d'O")
	assert_true(start.flags.has(&"pokedex_activated"))
	assert_gt(int(start.bag.get(&"potion", 0)), 0)


func test_the_qa_rival_can_start_in_patience() -> void:
	# Cas « jamais en Patience » : Salamèche connaît Patience (bide), l'IA ne le change pas
	# tant qu'il est verrouillé (AiSwitchRule). Ici : la capacité est bien dans l'équipe.
	var library := TrainerLibrary.new(_data)
	library.load_dir()
	var rival := library.get_trainer(&"qa_switch_rival")
	assert_true(rival.team[0].moves.has(&"bide"))
