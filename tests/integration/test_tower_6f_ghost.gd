extends GutTest
## Le SPECTRE qui barre le 6F de la Tour Pokémon (jalon 19 T14, `jalon-19.md` §2.4 ; dossier 22
## §6.3, §15.3.7-8, §16 n° 6, 7 et 10) sur la vraie scène Boot, départ de débogage
## `tower_6f_block` (rival n° 5 non battu, case `devant_spectre` en (10, 14)) :
## - le pas sur (10, 16) → « …Va-t'en… Intrus… » → combat SPECTRE → fuite → joueur en (10, 15) →
##   « Quelque chose refuse qu'on passe. » ;
## - le déclencheur se réarme : on recommence, même déroulé ;
## - l'escalier du 7F (9, 16) n'est jamais atteint ;
## - avec le compagnon : ni blocage ni chevauchement après le recul ;
## - rien au Pokédex (ni Osselait, ni Ossatueur, ni l'espèce du combat scripté).

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const START := "res://tools/debug_start/tower_6f_block.json"
const SAVE_PATH := "user://test_tower_6f_ghost_save.json"
const FADE := 0.05
const TIMEOUT := 25.0
const TRIGGER := Vector2i(10, 16)
const BACK := Vector2i(10, 15)
const STAIRS_7F := Vector2i(9, 16)
const WARNING: String = "…Va-t'en… Intrus…"
const AFTER: String = "Quelque chose refuse qu'on passe."

var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _shown_lines: Array[String] = []
var _visited: Array[Vector2i] = []
var _fades: Array = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:00:00")
	_pages.clear()
	_shown_lines.clear()
	_visited.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _start(companion: int = -1) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.force_debug_start = true
	_boot.debug_start_path = START
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_hud().get_message_banner().message_shown.connect(
		func(text: String, _wait: bool) -> void: _shown_lines.append(text))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	_player.moved.connect(func(cell: Vector2i) -> void: _visited.append(cell))
	# Le 6F a des rencontres sauvages (sol, taux 15) et l'aléatoire du départ n'est pas fixé : un
	# SPECTRE sauvage sur le pas (10, 14) → (10, 15) bloquait la marche avant le déclencheur
	# (échec intermittent, ~6 % par pas). Le test porte sur la scène scriptée, dont le combat
	# passe par le BattleDirector, pas par l'EncounterDirector.
	_boot.get_encounter_director().enabled = false
	if companion >= 0:
		GameState.set_companion(GameState.party.get_at(companion))
		_boot.get_companion_controller().refresh()
		await wait_process_frames(2)


## Un pas vers le sud depuis (10, 14) jusqu'au déclencheur, puis la scène : le combat est fui.
## Renvoie l'issue du combat.
func _walk_into_the_ghost(from: Vector2i) -> int:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var box := _boot.get_dialogue_box()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, o: int) -> void: outcome[0] = o
	battles.battle_finished.connect(on_finished)
	if _player.get_cell() != from:
		_boot.get_map().spawn_player_at(_player, from, Vector2i.DOWN)
		await wait_process_frames(3)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return cutscenes.is_running(), TIMEOUT)
	Input.action_release(&"move_down")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (cutscenes.is_running() or _runner.is_running() or battles.is_running()
			or SceneRouter.is_transitioning()) and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.RUN)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	battles.battle_finished.disconnect(on_finished)
	assert_false(cutscenes.is_running(), "scène finie")
	await wait_process_frames(10)
	return outcome[0]


func _check_round() -> void:
	var outcome := await _walk_into_the_ghost(Vector2i(10, 14))
	assert_eq(outcome, Battle.Outcome.FLED, "la fuite réussit")
	var expected: Array[String] = [WARNING, AFTER]
	assert_eq(_pages, expected, "§15.3.7 puis §15.3.8")
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	assert_eq(_player.get_cell(), BACK, "repoussé en (10, 15)")
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_6f", "toujours au 6F")
	assert_true(_player.is_input_enabled(), "contrôle rendu")


func test_ghost_blocks_the_seventh_floor_stairs_and_pushes_back() -> void:
	await _start()
	assert_false(GameState.flags.has_flag(&"rival_tower_won"), "rival n° 5 non battu")
	assert_false(GameState.flags.has_flag(&"ghost_marowak_calmed"))
	assert_false(GameState.flags.has_flag(&"tower_ghost_met"), "SPECTRE du 6F jamais vu")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file(), "\n".join(objectives.get_errors()))
	assert_eq(objectives.current_id(GameState.flags), &"climb_tower", "dossier 22 §15.7")
	watch_signals(GameState.pokedex)
	await _check_round()
	# Dossier 22 §13 et §15.7 (clôture T24) : la première rencontre pose `tower_ghost_met`.
	assert_true(GameState.flags.has_flag(&"tower_ghost_met"), "posé à la fin de la scène")
	assert_eq(objectives.current_id(GameState.flags), &"see_the_ghosts", "dossier 22 §15.7")
	assert_true(_visited.has(TRIGGER), "le pas sur (10, 16) a déclenché la scène")
	assert_false(_visited.has(STAIRS_7F), "l'escalier du 7F n'est jamais atteint")
	assert_signal_not_emitted(GameState.pokedex, "recorded", "rien au Pokédex")
	for species: StringName in [&"marowak", &"cubone"]:
		assert_false(GameState.pokedex.is_seen(species), "%s jamais vu" % species)
	var name := _boot.get_pokemon_data().get_species(&"marowak").name
	for line: String in _shown_lines + _pages:
		assert_false(line.contains(name), "espèce jamais nommée : %s" % line)
	assert_push_error_count(0)


func test_trigger_rearms_and_replays_the_same_sequence() -> void:
	await _start()
	await _check_round()
	_pages.clear()
	_shown_lines.clear()
	await _check_round()
	assert_false(_visited.has(STAIRS_7F), "l'escalier du 7F n'est jamais atteint")
	assert_eq(GameState.pokedex.seen_count(), _seen_baseline(), "toujours rien au Pokédex")
	assert_push_error_count(0)


## Pokédex de départ du `tower_6f_block` (les espèces de l'équipe sont « capturées »).
func _seen_baseline() -> int:
	var species: Array[StringName] = []
	for member: Pokemon in GameState.party.get_all():
		if not species.has(member.species_id):
			species.append(member.species_id)
	return species.size()


func test_the_companion_is_pushed_back_with_the_player_without_overlap() -> void:
	await _start(1)
	var companion := _boot.get_companion_controller()
	assert_not_null(companion.get_chosen(), "compagnon choisi")
	# Un seul pas vers (10, 15) d'abord (touche relâchée au début du pas), pour que le compagnon
	# soit sorti et sur la case d'où le joueur part vers le déclencheur.
	var on_started := func(_from: Vector2i, _to: Vector2i, _kind: StringName) -> void:
		Input.action_release(&"move_down")
	_player.step_started.connect(on_started, CONNECT_ONE_SHOT)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == BACK, TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return (not _player.is_moving()
		and not companion.get_node_2d().is_moving()), TIMEOUT)
	await wait_process_frames(10)
	assert_eq(_player.get_cell(), BACK, "un seul pas")
	assert_true(companion.is_shown(), "le compagnon est sorti")
	var outcome := await _walk_into_the_ghost(BACK)
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_eq(_player.get_cell(), BACK, "joueur repoussé en (10, 15)")
	assert_true(_player.is_input_enabled(), "aucun blocage")
	await wait_until(func() -> bool: return companion.is_shown(), TIMEOUT)
	assert_true(companion.is_shown(), "le compagnon suit")
	assert_ne(companion.get_node_2d().get_cell(), _player.get_cell(), "pas de chevauchement")
	# Il suit encore : un pas vers le nord, il suit derrière.
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell() == BACK + Vector2i.UP, TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return (not _player.is_moving()
		and not companion.get_node_2d().is_moving()), TIMEOUT)
	assert_ne(companion.get_node_2d().get_cell(), _player.get_cell())
	assert_push_error_count(0)
