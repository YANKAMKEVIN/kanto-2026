extends GutTest
## Le badge en jeu, de bout en bout (jalon 10 T19 ; jalon-10.md §2.11, §2.15, Q-2 ; dossier 12 §9,
## §13, §16) avec la vraie scène Boot, les vraies cartes (Arène, Argenta), les vraies scènes
## (`pewter_gym_brock`, `route_3_guard`), les vraies entrées `move_*` / `interact`, l'autoload
## SceneRouter (fondus raccourcis), le combat instantané et une sauvegarde en mémoire :
## - victoire contre Pierre : `badge_boulder`, Grand moment « badge » avec l'équipe, objectif
##   « continuer vers la Route 3. » ; le drapeau `route_3_guard_cleared` n'existe pas encore ;
## - au premier passage à Argenta : « Badge Roche confirmé. / Bonne route ! », le garde fait un
##   pas de côté vers (48, 23), `route_3_guard_cleared`, le joueur reste libre sur place ;
## - deuxième passage : plus de scène (le garde ne le dit qu'une fois) ; la sortie est mène à
##   la vraie Route 3, en (0, 26) tourné vers l'est (jalon 12 T8, jalon-12.md §2.17 ; jusqu'au
##   J11 : « ROUTE 3 — À venir »), et le bord ouest de la Route 3 ramène sur la case de sortie ;
## - sauvegarde et rechargement : le garde est toujours décalé, jamais en double, le drapeau et le
##   Grand moment sont relus ;
## - écran Dresseur : le Badge Roche, les sept autres en silhouette.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const WEAK_START := "res://tools/debug_start/brock_weak.json"
const SAVE_PATH := "user://test_pewter_badge_save.json"
const GYM := &"pewter_gym"
const CITY := &"pewter_city"
const DATE := "2026-10-09T18:00:00"
const FADE := 0.05
const TIMEOUT := 14.0
const SCENE_TIMEOUT_MS := 90000
const WALK_STOP := &"test_walk_stop"
const ENTRANCE := Vector2i(7, 9)
const TALK_CELL := Vector2i(7, 3)
const GUARD_HOME := Vector2i(48, 24)
const GUARD_ASIDE := Vector2i(48, 23)
const LOCK_CELL := Vector2i(48, 26)
const BEFORE_LOCK := Vector2i(47, 26)
const EXIT_CELL := Vector2i(51, 26)
const ROUTE_3 := &"route_3"
const ROUTE_3_ARRIVAL := Vector2i(0, 26)
const CLEARED := "Badge Roche confirmé.\nBonne route !"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _scenes: Array[StringName] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_pages.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot dans l'Arène (départ `brock_weak`, Liam battu) ou, sans départ, la partie relue de la
## sauvegarde en mémoire.
func _boot_up(from_save: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	if not from_save:
		_boot.start_map = GYM
		_boot.start_spawn = &"entrance"
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if not from_save:
		var start := DebugStart.new()
		assert_true(start.load_file(WEAK_START, _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(7)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_runner().get_session().get_text()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Déroule la scène en cours : pages avancées, combat piloté (Braise à chaque tour).
func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var card := _boot.get_hud().get_champion_card()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		if card.is_showing():
			card.skip_hold()
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(3)
	assert_false(director.is_running(), "scène finie")


func _badge_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(BadgeMoment.TYPE):
			found.append(moment)
	return found


func _objective() -> String:
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	return objectives.current(GameState.flags)


## Pierre vaincu d'emblée (Dracaufeu fort, Braise) : le badge est pris par la vraie scène.
func _win_the_badge() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 40,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)
	await _walk(Vector2i.UP, TALK_CELL)
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"pewter_gym_brock")
	await _finish_scene()


## Va à Argenta, devant le verrou de la Route 3 (47, 26), tourné vers l'est.
func _go_to_the_lock() -> void:
	await SceneRouter.change_map(CITY, &"from_gym", Vector2i.DOWN)
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, BEFORE_LOCK, Vector2i.RIGHT)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, CITY)


func test_the_badge_from_the_gym_to_the_east_exit_and_the_reload() -> void:
	await _boot_up(false)
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), ENTRANCE)
	assert_eq(_objective(), "obtenir le Badge Roche.")
	await _win_the_badge()
	assert_true(GameState.flags.has_flag(&"badge_boulder"), "badge obtenu")
	assert_false(GameState.flags.has_flag(&"route_3_guard_cleared"), "le garde n'a rien dit")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		var team := BadgeMoment.team_of(moments[0]["details"])
		assert_eq(team.size(), GameState.party.size(), "avec l'équipe")
		assert_eq(BadgeMoment.badge_of(moments[0]["details"]), &"boulder")
	assert_eq(_objective(), "continuer vers la Route 3.")

	# Premier passage : la réplique, le pas de côté, le drapeau ; le joueur reste libre.
	await _go_to_the_lock()
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"route_3_guard"), "garde à son poste")
	assert_null(map.get_npc(&"route_3_guard_aside"))
	assert_eq(map.get_npc(&"route_3_guard").get_cell(), GUARD_HOME)
	_pages.clear()
	_scenes.clear()
	await _walk(Vector2i.RIGHT, LOCK_CELL)
	await wait_process_frames(5)
	await _finish_scene()
	assert_eq(_scenes, [&"route_3_guard"] as Array[StringName])
	assert_eq(_pages, [CLEARED] as Array[String], "une seule réplique")
	assert_true(GameState.flags.has_flag(&"route_3_guard_cleared"))
	assert_eq(map.get_npc(&"route_3_guard").get_cell(), GUARD_ASIDE, "pas de côté vers le nord")
	assert_eq(_player.get_cell(), LOCK_CELL, "le joueur n'est pas repoussé")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_eq(_boot.get_map().map_id, CITY)

	# Deuxième passage : le garde ne redit rien et reste décalé.
	_pages.clear()
	_scenes.clear()
	await _walk(Vector2i.LEFT, BEFORE_LOCK)
	await _walk(Vector2i.RIGHT, LOCK_CELL)
	await wait_process_frames(10)
	assert_eq(_pages, [] as Array[String], "plus de réplique")
	assert_eq(map.get_npc(&"route_3_guard").get_cell(), GUARD_ASIDE, "toujours décalé")
	assert_true(_player.is_input_enabled())

	# La sortie est : la Route 3 (J12 T8), puis retour par son bord ouest sur la même case.
	await _walk(Vector2i.RIGHT, EXIT_CELL)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return _boot.get_map().map_id == ROUTE_3, TIMEOUT)
	Input.action_release(&"move_right")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_false(_boot.get_coming_soon_screen().is_showing(), "plus d'écran « à venir »")
	assert_eq(_player.get_cell(), ROUTE_3_ARRIVAL, "Route 3, rangée du milieu")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "tourné vers l'est")
	assert_true(_player.is_input_enabled())
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return _boot.get_map().map_id == CITY, TIMEOUT)
	Input.action_release(&"move_left")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)
	assert_eq(_player.get_cell(), EXIT_CELL, "retour sur la case de sortie")
	assert_eq(_player.get_facing(), Vector2i.LEFT)
	assert_true(_player.is_input_enabled())

	# Sauvegarde puis rechargement : garde décalé, jamais en double, tout relu.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_pages.clear()
	_scenes.clear()
	await _boot_up(true)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_true(_boot.has_resumed(), "partie relue")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_true(GameState.flags.has_flag(&"badge_boulder"))
	assert_true(GameState.flags.has_flag(&"route_3_guard_cleared"), "drapeau relu")
	assert_eq(_badge_moments().size(), 1, "Grand moment relu")
	assert_null(_boot.get_map().get_npc(&"route_3_guard"), "plus de garde à son poste")
	var aside := _boot.get_map().get_npc(&"route_3_guard_aside")
	assert_not_null(aside, "garde décalé au rechargement")
	if aside != null:
		assert_eq(aside.get_cell(), GUARD_ASIDE)
		assert_eq(aside.get_facing(), Vector2i.DOWN)
	_boot.get_map().spawn_player_at(_player, BEFORE_LOCK, Vector2i.RIGHT)
	await wait_process_frames(3)
	await _walk(Vector2i.RIGHT, LOCK_CELL)
	await wait_process_frames(10)
	assert_eq(_pages, [] as Array[String], "aucune réplique après le rechargement")
	assert_eq(_objective(), "continuer vers la Route 3.")

	# Écran Dresseur : le Badge Roche, les sept autres en silhouette.
	assert_true(_boot.get_menu_director().open(MenuRoute.trainer()))
	await wait_process_frames(5)
	var slots := _boot.get_trainer_menu().get_trainer().get_badge_slots()
	assert_eq(slots.size(), 8)
	assert_eq(slots[0].get_text(), "Roche")
	assert_eq(slots[0].get_view().name, "Badge Roche")
	for index: int in range(1, slots.size()):
		assert_true(slots[index].is_muted(), "emplacement %d en silhouette" % index)
	_boot.get_menu_director().close()
	assert_push_error_count(0)
