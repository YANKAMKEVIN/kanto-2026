extends GutTest
## Rencontres sur les gravats (jalon 12, T20 ; `jalon-12.md` §2.5, dossier 15 §6) sur une
## mini-carte : une colonne de gravats, deux cases de hautes herbes, du sol calme ; un vrai Player,
## un BattleDirector factice et un ScriptedRng (modèle de `test_encounter_director`).
## Gravats → table « rubble » de la carte, éboulis sous les pieds (origine = la case du joueur),
## point d'accroche du son, demi-tour du héros, puis combat ; sol calme → aucun tirage ; herbes
## inchangées ; un seul compteur de pas calmes ; sans table de gravats → rien ; durée de l'intro
## au pas près (temps simulé).

const PLAYER_SCENE := "res://game/player/player.tscn"
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const MAP_ID := &"test_cave_map"
const MAP_SIZE := Vector2i(12, 12)
## Le joueur part de (5, 6), tourné vers le nord : gravats au nord, herbes à l'est, sol calme à
## l'ouest.
const START_CELL := Vector2i(5, 6)
const RUBBLE_CELLS: Array[Vector2i] = [Vector2i(5, 5), Vector2i(5, 4), Vector2i(5, 3)]
const GRASS_CELLS: Array[Vector2i] = [Vector2i(6, 6), Vector2i(7, 6)]
const CALM_CELL := Vector2i(4, 6)
## Tirage gagnant (taux, poids, niveau, puis PokemonFactory) ; perdant : le taux seul.
const WIN_ROLLS: Array[int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
const LOSE_ROLLS: Array[int] = [256]


class FakeBattleDirector extends BattleDirector:
	var runs: int = 0
	var last_request: BattleRequest = null
	var frames_to_run: int = 3
	var _fake_running: bool = false

	func run_request(request: BattleRequest, _map: GameMap) -> int:
		runs += 1
		last_request = request
		_fake_running = true
		for i: int in frames_to_run:
			await get_tree().process_frame
		_fake_running = false
		return Battle.Outcome.WIN

	func is_running() -> bool:
		return _fake_running


class FakeRouter extends Node:
	func is_transitioning() -> bool:
		return false


var _data: PokemonData
var _library: EncounterLibrary
var _state: Node
var _map: GameMap
var _player: Player
var _fake: FakeBattleDirector
var _director: EncounterDirector
var _sounds: int = 0
var _cries: Array[StringName] = []


func before_each() -> void:
	_sounds = 0
	_cries.clear()
	_data = PokemonData.new()
	_data.load_dir()
	_library = EncounterLibrary.new(_data)
	_library.add_from_dict({
		"test_cave_grass": {
			"maps": [String(MAP_ID)], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
		"test_cave_rubble": {
			"maps": [String(MAP_ID)], "terrain": "rubble", "rate": 25,
			"ramp": {"from_step": 15, "max_steps": 20},
			"slots": [{"species": "zubat", "levels": [9, 9], "weight": 20}],
		},
	}, "test")
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.party.add(PokemonFactory.create(_data, &"charmander", 12, GameRng.new(1)))
	_map = GameMap.new()
	_map.size = MAP_SIZE
	var entities := Node2D.new()
	entities.name = "Entities"
	_map.add_child(entities)
	add_child_autofree(_map)
	_map.map_id = MAP_ID
	for cell: Vector2i in RUBBLE_CELLS:
		_map.get_grid().set_rubble(cell)
	for cell: Vector2i in GRASS_CELLS:
		_map.get_grid().set_tall_grass(cell)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.add_child(_player)
	_player.enter_map(_map.get_grid(), START_CELL, Vector2i.UP, _map.get_pixel_rect())
	_fake = FakeBattleDirector.new()
	_fake.speed_scale = 0.0
	add_child_autofree(_fake)
	var router := FakeRouter.new()
	add_child_autofree(router)
	_director = EncounterDirector.new()
	add_child_autofree(_director)
	_director.setup(_library, _data, _state, _player, _fake, router, null)
	_director.set_map(_map)
	_director.rubble_sound_requested.connect(func() -> void: _sounds += 1)
	_director.cry_requested.connect(_cries.append)
	await wait_process_frames(2)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


func _one_step(dir: Vector2i, goal: Vector2i) -> void:
	_player.script_step(dir)
	await wait_until(func() -> bool:
		return _player.get_cell() == goal and not _player.is_moving(), 3.0)
	await wait_process_frames(2)


func _wait_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), 3.0)


# --- Déclenchement -------------------------------------------------------------------------

func test_terrain_of_each_cell() -> void:
	assert_eq(_director.terrain_at(RUBBLE_CELLS[0]), &"rubble")
	assert_eq(_director.terrain_at(GRASS_CELLS[0]), &"grass")
	assert_eq(_director.terrain_at(CALM_CELL), &"", "sol calme")
	assert_eq(_director.terrain_at(Vector2i(-1, 0)), &"", "hors carte")


func test_a_winning_roll_on_rubble_plays_the_rockslide_then_the_battle() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _one_step(Vector2i.UP, RUBBLE_CELLS[0])
	await wait_until(func() -> bool: return _fake.runs > 0, 3.0)
	assert_eq(_fake.runs, 1, "combat lancé")
	var foe := _fake.last_request.foe_party.get_lead()
	assert_eq([foe.species_id, foe.level], [&"zubat", 9], "table des gravats de la carte")
	assert_eq(_fake.last_request.origin_cell, RUBBLE_CELLS[0],
		"l'éboulis part sous les pieds (même si la case devant est aussi en gravats)")
	assert_eq(_sounds, 1, "point d'accroche « pierres qui roulent »")
	assert_eq(_cries, [&"zubat"] as Array[StringName], "cri accroché")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "le héros s'est retourné")
	assert_true(_state.pokedex.is_seen(&"zubat"))
	await _wait_end()
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_eq(_director.get_quiet_steps(), 0)


func test_no_roll_on_calm_floor() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _one_step(Vector2i.LEFT, CALM_CELL)
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage sur le sol calme")
	assert_eq(_director.get_quiet_steps(), 0, "la série n'avance pas")


func test_grass_is_unchanged_next_to_rubble() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _one_step(Vector2i.RIGHT, GRASS_CELLS[0])
	await wait_until(func() -> bool: return _fake.runs > 0, 3.0)
	var foe := _fake.last_request.foe_party.get_lead()
	assert_eq(foe.species_id, &"pidgey", "table des herbes")
	assert_eq(_fake.last_request.origin_cell, GRASS_CELLS[1], "l'herbe devant le joueur")
	assert_eq(_sounds, 0, "pas d'éboulis dans l'herbe")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "tourné vers l'herbe qui bouge")
	await _wait_end()


func test_one_quiet_step_counter_for_both_terrains() -> void:
	_state.rng = ScriptedRng.new([256, 256, 256])
	await _one_step(Vector2i.UP, RUBBLE_CELLS[0])
	assert_eq(_director.get_quiet_steps(), 1, "un pas de gravats sans rencontre")
	await _one_step(Vector2i.DOWN, START_CELL)
	assert_eq(_director.get_quiet_steps(), 1, "sol calme : rien")
	await _one_step(Vector2i.RIGHT, GRASS_CELLS[0])
	assert_eq(_director.get_quiet_steps(), 2, "l'herbe continue la même série")
	await _one_step(Vector2i.RIGHT, GRASS_CELLS[1])
	assert_eq(_director.get_quiet_steps(), 3)
	assert_eq(_state.rng.remaining(), 0, "un tirage par pas d'herbe ou de gravats")
	assert_eq(_fake.runs, 0)


func test_rubble_without_a_table_does_nothing() -> void:
	var library := EncounterLibrary.new(_data)
	library.add_from_dict({
		"grass_only": {
			"maps": [String(MAP_ID)], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
	}, "test")
	_director.setup(library, _data, _state, _player, _fake, null, null)
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _one_step(Vector2i.UP, RUBBLE_CELLS[0])
	assert_false(_director.is_running())
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage sans table de gravats")


# --- Durée de l'intro (temps simulé) --------------------------------------------------------

func test_rockslide_intro_takes_its_duration_then_the_hero_turns() -> void:
	_player.enter_map(_map.get_grid(), RUBBLE_CELLS[0], Vector2i.UP, _map.get_pixel_rect())
	_fake.speed_scale = 1.0
	_state.rng = ScriptedRng.new([1, 1, 1, 1, 1, 1, 1])
	var clock := TweenClock.new(get_tree())
	assert_true(_director.start_encounter(WildEncounter.new(&"geodude", 9, &"test_cave_rubble")))
	assert_eq(_sounds, 1, "le son s'accroche au début de l'éboulis")
	var expected := roundi(RubbleBurst.DURATION / TweenClock.STEP)
	for i: int in expected - 1:
		clock.step()
	assert_eq(_fake.runs, 0, "pas de combat avant la fin de l'éboulis")
	assert_eq(_player.get_facing(), Vector2i.UP, "pas encore retourné")
	clock.step()
	if _fake.runs == 0:
		clock.step()
	assert_eq(_fake.runs, 1, "combat à la fin de l'éboulis (au plus un pas de plus)")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "demi-tour, puis combat")
	clock.release()
	await _wait_end()
