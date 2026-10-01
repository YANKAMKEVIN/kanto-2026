extends GutTest
## EncounterDirector (jalon 5 §3.6) sur une mini-carte : quelques cases de hautes herbes, un
## vrai Player qui marche, un BattleDirector factice (il ne joue rien, renvoie une issue) et un
## ScriptedRng. On vérifie qu'un pas terminé dans l'herbe avec un tirage gagnant bloque le
## joueur **dans le `moved`** (le pas suivant ne part pas, move_up tenu), construit la bonne
## requête (espèce, niveau, case d'origine), marque le sauvage « vu » au Pokédex, puis rend le
## contrôle et émet `encounter_finished`. Aucun tirage hors herbe, sans table, pendant une
## transition, un combat, un pas non libre (scène / dialogue), ni sans Pokémon valide.

const PLAYER_SCENE := "res://game/player/player.tscn"
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const MAP_ID := &"test_grass_map"
const MAP_SIZE := Vector2i(12, 12)
## Colonne verte : (5, 5) (5, 4) (5, 3). Le joueur part de (5, 6), tourné vers le nord.
const START_CELL := Vector2i(5, 6)
const GRASS_CELLS: Array[Vector2i] = [Vector2i(5, 5), Vector2i(5, 4), Vector2i(5, 3)]
## Tirage gagnant : taux (≤ 25), poids (1er emplacement), niveau ([3, 3]), puis les tirages de
## PokemonFactory.create (6 IV + sexe) que la valeur 1 satisfait toujours.
const WIN_ROLLS: Array[int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
## Tirage perdant : le taux n'est pas atteint (256 > 25), rien d'autre n'est tiré.
const LOSE_ROLLS: Array[int] = [256]


class FakeBattleDirector extends BattleDirector:
	var runs: int = 0
	var last_request: BattleRequest = null
	var outcome: int = Battle.Outcome.WIN
	## Nombre d'images pendant lesquelles le combat « tourne » (observation du verrou).
	var frames_to_run: int = 30
	var _fake_running: bool = false

	func run_request(request: BattleRequest, _map: GameMap) -> int:
		runs += 1
		last_request = request
		_fake_running = true
		for i: int in frames_to_run:
			await get_tree().process_frame
		_fake_running = false
		return outcome

	func is_running() -> bool:
		return _fake_running


class FakeRouter extends Node:
	var transitioning: bool = false

	func is_transitioning() -> bool:
		return transitioning


var _data: PokemonData
var _library: EncounterLibrary
var _state: Node
var _map: GameMap
var _player: Player
var _fake: FakeBattleDirector
var _router: FakeRouter
var _director: EncounterDirector
var _finished: Array[int] = []
var _started: Array[Array] = []


func before_each() -> void:
	_finished.clear()
	_started.clear()
	_data = PokemonData.new()
	_data.load_dir()
	_library = EncounterLibrary.new(_data)
	_library.add_from_dict({
		"test_grass_table": {
			"maps": [String(MAP_ID)], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
	}, "test")
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.party.add(PokemonFactory.create(_data, &"charmander", 5, GameRng.new(1)))
	_map = GameMap.new()
	_map.size = MAP_SIZE
	var entities := Node2D.new()
	entities.name = "Entities"
	_map.add_child(entities)
	add_child_autofree(_map)
	# map_id posé après _ready : _build_grid n'a pas besoin de PNJ (grille vide, cases libres).
	_map.map_id = MAP_ID
	for cell: Vector2i in GRASS_CELLS:
		_map.get_grid().set_tall_grass(cell)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.add_child(_player)
	_player.enter_map(_map.get_grid(), START_CELL, Vector2i.UP, _map.get_pixel_rect())
	_fake = FakeBattleDirector.new()
	_fake.speed_scale = 0.0
	add_child_autofree(_fake)
	_router = FakeRouter.new()
	add_child_autofree(_router)
	_director = EncounterDirector.new()
	add_child_autofree(_director)
	_director.setup(_library, _data, _state, _player, _fake, _router, null)
	_director.set_map(_map)
	_director.encounter_started.connect(func(s: StringName, l: int) -> void:
		_started.append([s, l]))
	_director.encounter_finished.connect(func(o: int) -> void: _finished.append(o))
	await wait_process_frames(2)


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


# --- Déclenchement -------------------------------------------------------------------

func test_a_winning_roll_in_grass_locks_the_player_and_runs_the_request() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _director.is_running(), 3.0)
	assert_true(_director.is_running(), "rencontre lancée")
	assert_eq(_player.get_cell(), GRASS_CELLS[0], "le joueur s'est arrêté dans l'herbe")
	assert_false(_player.is_input_enabled(), "verrou posé")
	assert_true(_player.is_blocked_by(EncounterDirector.REASON))
	# Le pas suivant ne part pas, move_up tenu.
	await wait_seconds(0.3)
	assert_eq(_player.get_cell(), GRASS_CELLS[0], "aucun pas de plus")
	# La requête décrit le bon sauvage et la bonne case d'origine (l'herbe devant).
	assert_eq(_fake.runs, 1, "le directeur de combat est appelé une fois")
	assert_not_null(_fake.last_request)
	assert_true(_fake.last_request.is_wild())
	var foe := _fake.last_request.foe_party.get_lead()
	assert_eq(foe.species_id, &"pidgey")
	assert_eq(foe.level, 3)
	assert_eq(_fake.last_request.origin_cell, Vector2i(5, 4), "la case d'herbe devant le joueur")
	assert_true(_state.pokedex.is_seen(&"pidgey"), "sauvage marqué « vu »")
	assert_eq(_started, [[&"pidgey", 3]] as Array[Array])
	# Fin : contrôle rendu, signal émis avec l'issue du directeur factice.
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return not _director.is_running(), 3.0)
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_eq(_finished, [Battle.Outcome.WIN] as Array[int])


func test_a_losing_roll_does_nothing() -> void:
	_state.rng = ScriptedRng.new(LOSE_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running(), "aucune rencontre")
	assert_eq(_fake.runs, 0)
	assert_true(_player.is_input_enabled())
	assert_eq(_player.get_cell(), GRASS_CELLS[0], "le pas s'est terminé normalement")


func test_no_encounter_outside_the_grass() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	# Pas vers le sud, hors des cases d'herbe.
	await _one_step(Vector2i.DOWN, Vector2i(5, 7))
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage hors herbe")


func test_no_encounter_without_a_table_for_the_map() -> void:
	_map.map_id = &"other_map"
	_director.set_map(_map)
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage sans table")


func test_no_encounter_during_a_transition() -> void:
	_router.transitioning = true
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)


func test_no_encounter_while_a_battle_is_running() -> void:
	_fake.frames_to_run = 200
	# Un combat déjà en cours (l'EncounterDirector n'en lance pas un second).
	_fake._fake_running = true
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)


func test_no_encounter_on_a_scripted_step_while_locked() -> void:
	# Joueur bloqué (dialogue / scène) : un pas scripté vers l'herbe ne déclenche rien.
	_player.set_input_enabled(false, &"scene")
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_player.script_step(Vector2i.UP)
	await wait_until(func() -> bool:
		return _player.get_cell() == GRASS_CELLS[0] and not _player.is_moving(), 3.0)
	await wait_process_frames(2)
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size(), "aucun tirage sur un pas scripté")


func test_no_encounter_without_an_able_pokemon() -> void:
	_state.party.clear()
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)


func test_disabled_director_never_rolls() -> void:
	_director.enabled = false
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	await _step_into_grass()
	assert_false(_director.is_running())
	assert_eq(_fake.runs, 0)
	assert_eq(_state.rng.remaining(), WIN_ROLLS.size())


func test_start_encounter_forces_a_rencontre() -> void:
	# Pas de tirage : la rencontre est imposée (scénario de capture, débogage).
	_state.rng = ScriptedRng.new([1, 1, 1, 1, 1, 1, 1])
	var ok := _director.start_encounter(WildEncounter.new(&"rattata", 4, &"test_grass_table"))
	assert_true(ok)
	await wait_until(func() -> bool: return _director.is_running(), 3.0)
	assert_false(_player.is_input_enabled(), "verrou posé")
	assert_true(_state.pokedex.is_seen(&"rattata"))
	await wait_until(func() -> bool: return not _director.is_running(), 3.0)
	assert_eq(_fake.runs, 1)
	assert_eq(_fake.last_request.foe_party.get_lead().species_id, &"rattata")
	assert_eq(_fake.last_request.foe_party.get_lead().level, 4)
	assert_true(_player.is_input_enabled(), "contrôle rendu")


func test_no_orphans_after_an_encounter() -> void:
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_fake.frames_to_run = 2
	await _step_into_grass()
	await wait_until(func() -> bool: return not _director.is_running(), 3.0)
	assert_no_new_orphans("le froissement d'herbe est libéré")


# --- Outils --------------------------------------------------------------------------

## Un seul pas (scripté, entrées libres) dans la première case d'herbe (5, 5), pour éprouver
## les gardes sans enchaîner de pas : le pas normal émet [signal Player.moved] et déclenche le
## tirage exactement une fois.
func _step_into_grass() -> void:
	await _one_step(Vector2i.UP, GRASS_CELLS[0])


## Un pas scripté vers [param dir] et attente de l'arrivée en [param goal].
func _one_step(dir: Vector2i, goal: Vector2i) -> void:
	_player.script_step(dir)
	await wait_until(func() -> bool:
		return _player.get_cell() == goal and not _player.is_moving(), 3.0)
	await wait_process_frames(2)
