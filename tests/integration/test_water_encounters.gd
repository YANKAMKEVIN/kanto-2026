extends GutTest
## Rencontres « water » (passe systèmes 2, T16, `systemes-2.md` §2.5.6) : terrain connu des tables,
## table d'eau lue d'un fichier (copie d'essai, sous `tests/fixtures/encounters_water/`, de la table
## de la carte de QA retirée en S2Z, T33), `EncounterDirector.terrain_at` rend « water » sur une case
## surfable (rien ailleurs : sable, eau décor, herbes inchangées), et un pas en Surf lance le
## combat de la table.

const PLAYER_SCENE := "res://game/player/player.tscn"
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const MAP_ID := &"essai_mer"
const WATER_FIXTURES := "res://tests/fixtures/encounters_water"
const WATER_CELL := Vector2i(5, 5)
const DECOR_WATER := Vector2i(8, 5)
const SAND_CELL := Vector2i(4, 5)
const GRASS_CELL := Vector2i(3, 5)
const WIN_ROLLS: Array[int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]


class FakeBattleDirector extends BattleDirector:
	var runs: int = 0
	var last_request: BattleRequest = null
	var _fake_running: bool = false

	func run_request(request: BattleRequest, _map: GameMap) -> int:
		runs += 1
		last_request = request
		_fake_running = true
		await get_tree().process_frame
		_fake_running = false
		return Battle.Outcome.WIN

	func is_running() -> bool:
		return _fake_running


class FakeRouter extends Node:
	func is_transitioning() -> bool:
		return false


var _data: PokemonData
var _state: Node
var _map: GameMap
var _player: Player
var _fake: FakeBattleDirector
var _director: EncounterDirector


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	var library := EncounterLibrary.new(_data)
	library.add_from_dict({
		"test_water": {
			"maps": ["test_sea"], "terrain": "water", "rate": 25,
			"slots": [{"species": "goldeen", "levels": [15, 15], "weight": 20}],
		},
		"test_grass": {
			"maps": ["test_sea"], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
	}, "test")
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.party.add(PokemonFactory.create(_data, &"squirtle", 20, GameRng.new(1)))
	_map = GameMap.new()
	_map.size = Vector2i(12, 12)
	var entities := Node2D.new()
	entities.name = "Entities"
	_map.add_child(entities)
	add_child_autofree(_map)
	_map.map_id = &"test_sea"
	_map.get_grid().set_surfable(WATER_CELL)
	_map.get_grid().set_water(DECOR_WATER, true)
	_map.get_grid().set_tall_grass(GRASS_CELL)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.add_child(_player)
	_player.enter_map(_map.get_grid(), SAND_CELL, Vector2i.RIGHT, _map.get_pixel_rect())
	_fake = FakeBattleDirector.new()
	_fake.speed_scale = 0.0
	add_child_autofree(_fake)
	var router := FakeRouter.new()
	add_child_autofree(router)
	_director = EncounterDirector.new()
	add_child_autofree(_director)
	_director.setup(library, _data, _state, _player, _fake, router, null)
	_director.set_map(_map)
	await wait_process_frames(2)


func test_water_is_a_known_terrain_and_a_water_table_loads() -> void:
	assert_true(&"water" in EncounterTable.TERRAINS)
	assert_eq(EncounterTable.TERRAINS.back(), &"water", "ajouté en fin")
	var game := EncounterLibrary.new(_data)
	assert_true(game.load_dir(), "\n".join(game.get_errors()))
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir(WATER_FIXTURES), "\n".join(library.get_errors()))
	assert_true(library.has_table(MAP_ID, &"water"))
	assert_false(library.has_table(MAP_ID, &"grass"))
	var table := library.get_table(MAP_ID, &"water")
	assert_eq(table.rate, 25)
	var species: Array[StringName] = []
	for slot: EncounterSlot in table.slots:
		species.append(slot.species)
		assert_true(_data.has_species(slot.species), String(slot.species))
	for expected: StringName in [&"goldeen", &"horsea", &"shellder", &"staryu"]:
		assert_true(expected in species, String(expected))
	assert_false(library.has_table(&"route_1", &"water"))


func test_terrain_at_is_water_only_on_surfable_cells() -> void:
	assert_eq(_director.terrain_at(WATER_CELL), &"water")
	assert_eq(_director.terrain_at(DECOR_WATER), &"", "eau décor")
	assert_eq(_director.terrain_at(SAND_CELL), &"", "terre")
	assert_eq(_director.terrain_at(GRASS_CELL), &"grass", "herbes inchangées")
	assert_eq(_director.terrain_at(Vector2i(-1, 0)), &"", "hors carte")


func test_a_winning_roll_on_water_starts_the_water_table_battle() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_player.moved.emit(WATER_CELL)
	await wait_until(func() -> bool: return _fake.runs > 0, 3.0)
	assert_eq(_fake.runs, 1)
	var foe := _fake.last_request.foe_party.get_lead()
	assert_eq([foe.species_id, foe.level], [&"goldeen", 15], "table « water » de la carte")
	assert_true(_state.pokedex.is_seen(&"goldeen"))
	await wait_until(func() -> bool: return not _director.is_running(), 3.0)
	assert_true(_player.is_input_enabled())


func test_no_roll_on_decor_water() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_player.moved.emit(DECOR_WATER)
	await wait_process_frames(2)
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage")


func test_a_map_without_water_table_ignores_surfable_cells() -> void:
	var library := EncounterLibrary.new(_data)
	library.add_from_dict({
		"test_grass": {
			"maps": ["test_sea"], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
	}, "test")
	_director.setup(library, _data, _state, _player, _fake, null, null)
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_player.moved.emit(WATER_CELL)
	await wait_process_frames(2)
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size())
