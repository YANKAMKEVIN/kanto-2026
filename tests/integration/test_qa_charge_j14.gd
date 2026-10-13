extends GutTest
## Carte de QA `qa_charge_j14` et départs `charge_qa` / `teleport_qa` (jalon 14, T10) : retirés
## au T24 avec la carte.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const MAP_ID := &"qa_charge_j14"
const STARTS := "res://tools/debug_start/"

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _load_map() -> GameMap:
	var map := (load(MapCatalog.scene_path(MAP_ID)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func test_map_loads_with_spawns_exit_and_tall_grass() -> void:
	assert_true(MapCatalog.has_map(MAP_ID))
	assert_true(MapCatalog.is_qa_map(MAP_ID))
	var map := _load_map()
	assert_eq(map.size, Vector2i(24, 14))
	var grid := map.get_grid()
	for spawn: StringName in [&"charge_start", &"teleport_start"]:
		assert_true(map.has_spawn(spawn), String(spawn))
		assert_true(grid.is_free(map.get_spawn_cell(spawn)), "%s : case libre" % spawn)
	assert_true(grid.is_tall_grass(map.get_spawn_cell(&"teleport_start") + Vector2i.DOWN),
		"le départ Téléport est au bord des hautes herbes")
	var tall := 0
	for y in 14:
		for x in 24:
			if grid.is_tall_grass(Vector2i(x, y)):
				tall += 1
	assert_eq(tall, 24, "hautes herbes 6 x 4")
	assert_eq(map.get_node(^"Warps").get_child_count(), 3, "sortie sud vers Jadielle")


func test_trainers_are_declared_and_reachable_from_the_charge_start() -> void:
	var roster := NpcRoster.load_for_map(MAP_ID)
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	assert_eq(roster.size(), 3)
	var trainers := TrainerLibrary.new(_data)
	assert_true(trainers.load_dir(), "\n".join(trainers.get_errors()))
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var map := _load_map()
	var grid := map.get_grid()
	var start := map.get_spawn_cell(&"charge_start")
	var reachable := grid.find_reachable(start)
	for spec: NpcSpec in roster.get_all():
		assert_true(trainers.has_trainer(spec.trainer_id), String(spec.trainer_id))
		assert_eq(trainers.get_trainer(spec.trainer_id).ai, &"smart")
		for id: StringName in [spec.before_dialogue, spec.dialogue]:
			assert_true(dialogues.has_dialogue(id), "dialogue « %s »" % id)
		assert_true(reachable.has(spec.cell + Vector2i.LEFT),
			"%s : joignable depuis le départ" % spec.trainer_id)


func test_trainer_teams_carry_the_tested_moves() -> void:
	var trainers := TrainerLibrary.new(_data)
	trainers.load_dir()
	var moves: Array[StringName] = []
	for id: StringName in [&"qa_charge_dig", &"qa_charge_sleep", &"qa_charge_para"]:
		for slot in trainers.get_trainer(id).team:
			moves.append_array(slot.moves)
	for move: StringName in [&"dig", &"sleep_powder", &"thunder_wave"]:
		assert_true(moves.has(move), String(move))


func _load_start(file_name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(STARTS + file_name + ".json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq(start.map, MAP_ID)
	assert_false(start.autosave, "ne touche jamais la sauvegarde")
	var map := _load_map()
	assert_true(map.has_spawn(start.spawn))
	return start


func _party(start: DebugStart) -> Array[Pokemon]:
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var party: Array[Pokemon] = []
	party.assign(state.party.get_all())
	return party


func test_charge_qa_start() -> void:
	var start := _load_start("charge_qa")
	assert_eq([start.spawn, start.facing], [&"charge_start", Vector2i.RIGHT])
	var party := _party(start)
	assert_eq(party[0].species_id, &"kadabra")
	assert_true(party[0].knows_move(&"dig"), "Kadabra connaît Tunnel")
	var species: Array = party.map(func(p: Pokemon) -> StringName: return p.species_id)
	assert_true(species.has(&"pidgey"), "un Pokémon Vol pour l'immunité")
	assert_true(species.has(&"butterfree"), "de quoi endormir")
	assert_true(species.has(&"pikachu"), "de quoi paralyser")
	assert_gte(start.bag.get(&"poke_ball", 0), 10)
	assert_false(start.wild.is_empty())


func test_teleport_qa_start() -> void:
	var start := _load_start("teleport_qa")
	assert_eq([start.spawn, start.facing], [&"teleport_start", Vector2i.DOWN])
	assert_gte(start.bag.get(&"poke_ball", 0), 20)
	var slots: Array = start.wild["slots"]
	assert_eq(slots.size(), 1)
	assert_eq(slots[0]["species"], "abra", "Abra à coup sûr")
	var species: Array = _party(start).map(func(p: Pokemon) -> StringName: return p.species_id)
	assert_true(species.has(&"butterfree"), "Poudre Dodo pour endormir Abra")
