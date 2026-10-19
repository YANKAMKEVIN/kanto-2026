extends GutTest
## Rival n° 5 au 2F de la Tour Pokémon (jalon 19 T17, jalon-19.md §2.6 ; dossier 22 §7, §15.2, §15.4),
## avec la vraie scène Boot, la vraie carte, la vraie scène `tower_rival`, SceneRouter (fondus
## raccourcis), le combat instantané et une sauvegarde en mémoire :
## - inévitable : aucun chemin de l'arrivée vers l'escalier du 3F n'évite (15, 5) ni (14, 6) ;
## - équipe de cinq selon le starter, sans Rattatac, IA `smart` avec `switch`, `moment: "win"` ;
## - défaite : §15.2.7, réveil au Centre, `rival_tower_lost_once` sans `_won` ni Grand moment ;
##   retour : §15.2.6, `retried` ; victoire : silence, §15.2.4-5, il part, `rival_tower_won`,
##   exactement un Grand moment ; il ne revient pas (repassage, rechargement, nouvelle entrée) ;
## - l'Exorciste calme du 2F (§15.4) ne combat pas.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/tower_rival.json"
const WEAK_START := "res://tools/debug_start/tower_rival_weak.json"
const SAVE_PATH := "user://test_rival_tower_save.json"
const DATE := "2026-10-19T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const FOOT := Vector2i(17, 9)
const MAP_SIZE := Vector2i(20, 18)
const STAIRS_UP := Vector2i(4, 9)
var INTRO: Array[String] = []
const WON_LINES: Array[String] = [
	"…Il y a des choses, plus haut.\nDes Pokémon que personne\nn'arrive à voir.", "Laisse tomber.",
]
const RESUME: Array[String] = ["Encore toi. …Vas-y."]
const LOST_LINES: Array[String] = ["…Rentre. Ce n'est pas un endroit pour toi."]
const CALM_LINES: Array[String] = [
	"On dit que Sylphe SARL a inventé un appareil qui révèle les spectres.",
	"Un Scope… Avec ça, on saurait enfin ce qui hante cette tour.",
]
const RIVAL_ID := &"tower_rival"
const TRAINER_ID := &"rival_tower"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _emotes: Array[StringName] = []
var _rival_cell_at_first_page := Vector2i(-1, -1)
var _player_cell_at_first_page := Vector2i(-1, -1)


func before_each() -> void:
	INTRO = ["…", "%s. …Tu es venu pour quoi ?" % GameState.player_name, "Peu importe."]
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_emotes.clear()
	_rival_cell_at_first_page = Vector2i(-1, -1)
	_player_cell_at_first_page = Vector2i(-1, -1)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)


## Boot (sauvegarde en mémoire), partie de [param start_path], puis arrivée au 2F. [param strong] : starter remplacé par un Salamèche Nv. 60.
func _start(start_path: String, strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"lavender_town"
	_boot.start_spawn = &"from_route_10"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	if strong:
		_make_strong()
	await wait_process_frames(2)
	await SceneRouter.change_map(&"pokemon_tower_2f", &"arrivee_T12", Vector2i.LEFT)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_2f")
	assert_eq(_player.get_cell(), FOOT)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _make_weak() -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


## Retour au 2F par l'escalier (case d'arrivée) après un réveil.
func _back_to_route() -> void:
	await SceneRouter.change_map(&"pokemon_tower_2f", &"arrivee_T12", Vector2i.LEFT)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	_pages.clear()
	_emotes.clear()


## De l'arrivée (17, 9) : en haut jusqu'à la rangée 7, à l'ouest jusqu'à la colonne 14, puis
## (14, 6), l'une des deux cases qui déclenchent la scène.
func _step_into_view() -> void:
	await _walk_to(Vector2i(17, 7))
	await _walk_to(Vector2i(14, 7))
	await _walk_to(Vector2i(14, 6))
	await wait_process_frames(2)


## Déroule la scène (et ce qui s'enchaîne) : pages avancées, combat piloté (ATTAQUER, 1re
## capacité). Vrai si un combat a eu lieu.
func _play_through() -> bool:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			seen_battle = true
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty():
				var rival := _boot.get_map().get_npc(RIVAL_ID)
				if rival != null:
					_rival_cell_at_first_page = rival.get_cell()
				_player_cell_at_first_page = _player.get_cell()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return seen_battle


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _rival_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(GameState.MOMENT_RIVAL_BATTLE) \
				and (moment.get("details", {}) as Dictionary).get("trainer") == "rival_tower":
			found.append(moment)
	return found


func _assert_lines(lines: Array[String], present: bool, label: String) -> void:
	for line: String in lines:
		assert_eq(_pages.has(line), present, "« %s » %s (%s)" % [
			line, "jouée" if present else "PAS jouée", label])


# --- Données ----------------------------------------------------------------------------------

func test_the_team_follows_the_starter_with_five_pokemon_and_no_raticate() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(TRAINER_ID)
	assert_not_null(trainer)
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch)
	assert_true(trainer.moment_on_win, "Grand moment à la victoire seulement")
	assert_false(trainer.can_lose)
	for starter: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		var team := library.build_team(TRAINER_ID, starter, GameRng.new(1))
		assert_not_null(team, "équipe contre %s" % starter)
		if team == null:
			continue
		var all := team.get_all()
		assert_eq(all.size(), 5, "cinq Pokémon contre %s" % starter)
		assert_true(all.all(func(p: Pokemon) -> bool: return p.species_id != &"raticate"),
			"pas de Rattatac")
		assert_true(all.any(func(p: Pokemon) -> bool: return p.species_id == &"kadabra"))


# --- Vue inévitable ---------------------------------------------------------------------------

func test_no_path_to_the_third_floor_stairs_avoids_the_two_trigger_cells() -> void:
	await _start(START)
	var map := _boot.get_map()
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in map.get_triggers().get_all():
		if trigger.cutscene_id == &"tower_rival":
			cells.append(trigger.cell)
			assert_eq(trigger.direction, Vector2i.ZERO, "toutes directions")
	cells.sort()
	assert_eq(cells, [Vector2i(14, 6), Vector2i(15, 5)] as Array[Vector2i])
	var terrain := GridPaths.relief(map.get_grid(), MAP_SIZE)
	assert_true(terrain.find_reachable(FOOT).has(STAIRS_UP), "sans la scène, l'escalier s'atteint")
	for cell: Vector2i in cells:
		terrain.set_solid(cell)
	assert_false(terrain.find_reachable(FOOT).has(STAIRS_UP), "aucun chemin hors des deux cases")
	assert_eq(map.get_npc(RIVAL_ID).get_cell(), Vector2i(14, 5))
	var calm := map.get_npc(&"exorciste_calme")
	assert_not_null(calm)
	assert_eq(calm.get_spec().trainer_id, &"", "l'Exorciste calme ne combat pas")
	assert_push_error_count(0)


func test_the_calm_exorcist_speaks_without_fighting() -> void:
	await _start(START)
	var map := _boot.get_map()
	var calm := map.get_npc(&"exorciste_calme")
	map.spawn_player_at(_player, calm.get_cell() + Vector2i.RIGHT, Vector2i.LEFT)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _boot.get_dialogue_box().is_open(), 5.0)
	assert_eq(_boot.get_dialogue_box().get_text(), CALM_LINES[0])
	assert_false(_boot.get_battle_director().is_running())
	await _play_through()
	assert_push_error_count(0)


# --- Défaites, reprise, victoire --------------------------------------------------------------

func test_defeat_does_not_set_won_then_retry_and_victory_with_a_single_moment() -> void:
	await _start(WEAK_START)
	GameState.heal_map = &"lavender_center"
	GameState.heal_spawn = &"heal"
	var map := _boot.get_map()
	assert_not_null(map.get_npc(RIVAL_ID))
	await _step_into_view()
	assert_true(_boot.get_cutscene_director().is_running(), "scène lancée par la vue")
	assert_true(await _play_through(), "le combat a eu lieu")
	_assert_lines(INTRO, true, "1re rencontre")
	_assert_lines(LOST_LINES, true, "défaite")
	_assert_lines(RESUME + WON_LINES, false, "1re rencontre")
	assert_false(GameState.flags.has_flag(&"rival_tower_won"), "une défaite ne pose pas won")
	assert_true(GameState.flags.has_flag(&"rival_tower_lost_once"))
	assert_false(GameState.flags.has_flag(&"rival_tower_retried"))
	assert_eq(_boot.get_map().map_id, &"lavender_center", "réveil au Centre")
	assert_true(_rival_moments().is_empty(), "aucun Grand moment pour une défaite")
	# Retour : réplique de reprise, deuxième défaite.
	await _back_to_route()
	assert_not_null(_boot.get_map().get_npc(RIVAL_ID), "il attend toujours")
	await _step_into_view()
	assert_true(await _play_through(), "second combat")
	_assert_lines(RESUME, true, "reprise")
	_assert_lines(INTRO + WON_LINES, false, "reprise")
	assert_true(GameState.flags.has_flag(&"rival_tower_retried"))
	assert_false(GameState.flags.has_flag(&"rival_tower_won"))
	assert_true(_rival_moments().is_empty())
	# Victoire.
	await _back_to_route()
	_make_strong()
	await _step_into_view()
	assert_true(await _play_through(), "troisième combat")
	_assert_lines(WON_LINES, true, "victoire")
	_assert_lines(LOST_LINES + INTRO, false, "victoire")
	assert_true(GameState.flags.has_flag(&"rival_tower_won"))
	var moments := _rival_moments()
	assert_eq(moments.size(), 1, "exactement un Grand moment")
	if moments.size() == 1:
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "win")
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_2f")
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "il est parti")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true((_saved().get("flags", []) as Array).has("rival_tower_won"), "sauvegardé")
	# Il ne revient pas : repassage, nouvelle entrée par l'escalier.
	await _back_to_route()
	assert_null(_boot.get_map().get_npc(RIVAL_ID), "absent en revenant")
	await _step_into_view()
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène rejouée")
	await _walk_to(Vector2i(14, 7))
	await _walk_to(Vector2i(15, 7))
	await _walk_to(Vector2i(15, 5))
	assert_false(_boot.get_cutscene_director().is_running())
	assert_eq(_rival_moments().size(), 1)
	assert_push_error_count(0)


func test_he_leaves_after_the_silence_and_the_player_is_free() -> void:
	await _start(START, true)
	await _step_into_view()
	assert_true(_boot.get_cutscene_director().is_running())
	assert_true(await _play_through())
	assert_true(GameState.flags.has_flag(&"rival_tower_won"))
	assert_null(_boot.get_map().get_npc(RIVAL_ID))
	assert_eq(_rival_moments().size(), 1)
	assert_push_error_count(0)


# --- Entrées ----------------------------------------------------------------------------------

func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	if delta == Vector2i.ZERO:
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var action: StringName = DIRECTIONS[direction]
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		var cell := _player.get_cell()
		if _player.is_moving() and cell + direction == goal:
			Input.action_release(action)
		if cell == goal and not _player.is_moving():
			break
		if not _player.is_input_enabled():
			break
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
