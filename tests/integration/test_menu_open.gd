extends GutTest
## Ouvrir, mettre en pause, fermer le Menu Dresseur (jalon-06.md §6.2, T4) avec la vraie scène
## Boot, un [SaveSystem] en mémoire et un écran factice (l'interface figée du §6.6) :
## garde d'ouverture, pause du monde, temps de jeu, autosave, retour Android (Q-3 : le jeu ne
## quitte jamais), action `menu`, arrière-plan menu ouvert.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t4_save.json"
const DATE := "2026-10-03T10:00:00"
const FADE := 0.05
const TIMEOUT := 12.0

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _menu: MenuDirector
var _screen: Node
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run", &"menu"]:
		Input.action_release(action)


func _start_boot(map: StringName = &"player_house_2f", spawn: StringName = &"start",
		facing: Vector2i = Vector2i.DOWN) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	await wait_process_frames(2)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(2)


## Départ en exploration libre dans la chambre (aucun dialogue automatique).
func _start_free() -> void:
	await _start_boot()
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _press_menu_action() -> void:
	var event := InputEventAction.new()
	event.action = &"menu"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	var release := InputEventAction.new()
	release.action = &"menu"
	release.pressed = false
	Input.parse_input_event(release)
	await wait_process_frames(1)


# --- Ouverture refusée ------------------------------------------------------------------

func test_open_is_refused_during_a_dialogue() -> void:
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	assert_false(_menu.open(), "refusé pendant le dialogue de Maman")
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)
	await _finish_dialogue()
	assert_true(_menu.open(), "accepté une fois le dialogue fini")
	_menu.close()


func test_open_is_refused_during_a_scene() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	GameState.flags.set_flag(&"starter_chosen")
	assert_true(_boot.get_cutscene_director().play(&"route_1_potion"))
	await wait_process_frames(2)
	assert_true(_boot.get_cutscene_director().is_running())
	assert_false(_menu.open(), "refusé pendant une scène")
	assert_false(get_tree().paused)
	await _finish_dialogue()
	await wait_until(func() -> bool: return not _boot.get_cutscene_director().is_running(),
		TIMEOUT)


func test_open_is_refused_during_a_transition() -> void:
	await _start_free()
	SceneRouter.change_map(&"player_house_1f", &"stairs")
	assert_true(SceneRouter.is_transitioning())
	assert_false(_menu.open(), "refusé pendant la transition")
	assert_false(get_tree().paused)
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)


func test_open_is_refused_during_an_encounter_and_a_battle() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var data := _boot.get_pokemon_data()
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(1)))
	var encounters := _boot.get_encounter_director()
	assert_true(encounters.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_process_frames(3)
	assert_true(encounters.is_running(), "rencontre en cours")
	assert_false(_menu.open(), "refusé pendant la rencontre")
	assert_false(get_tree().paused)
	var battle := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	var saw_battle := false
	while encounters.is_running() and Time.get_ticks_msec() < deadline:
		if battle.is_running():
			saw_battle = true
			assert_false(_menu.open(), "refusé pendant le combat")
			var fight := battle.get_battle()
			if fight != null and fight.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(saw_battle, "un combat a eu lieu")
	assert_false(get_tree().paused)


# --- Ouvert : le monde gèle -------------------------------------------------------------

func test_open_pauses_the_world_but_not_the_play_time() -> void:
	await _start_boot(&"route_1", &"from_pallet_w", Vector2i.UP)
	var traveler := _boot.get_map().get_npc(&"traveler")
	assert_not_null(traveler)
	# Le Voyageur marche bien menu fermé.
	var start_pos := traveler.position
	await wait_until(func() -> bool: return traveler.position != start_pos, TIMEOUT)
	assert_true(_menu.open())
	assert_true(_menu.is_open())
	assert_true(get_tree().paused, "l'arbre est en pause")
	assert_false(_boot.get_hud().are_controls_visible(), "contrôles cachés")
	assert_eq(_screen.opened_count, 1)
	var player_pos := _player.position
	var traveler_pos := traveler.position
	var traveler_cell := traveler.get_cell()
	var time := GameState.play_time
	Input.action_press(&"move_up")
	await wait_process_frames(90)
	assert_eq(_player.position, player_pos, "le joueur est immobile (move_up tenu)")
	assert_eq(traveler.position, traveler_pos, "le Voyageur est immobile")
	assert_eq(traveler.get_cell(), traveler_cell)
	assert_gt(GameState.play_time, time + 0.5, "le temps de jeu continue")
	Input.action_release(&"move_up")
	_menu.close()
	assert_false(get_tree().paused, "pause levée tout de suite")
	assert_true(_boot.get_hud().are_controls_visible(), "contrôles rendus")
	assert_eq(_screen.closed_count, 1)
	await wait_until(func() -> bool: return traveler.position != traveler_pos, TIMEOUT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.position != player_pos, TIMEOUT)
	Input.action_release(&"move_up")


func test_open_is_refused_twice_and_is_stable_stays_true() -> void:
	await _start_free()
	assert_true(_menu.open())
	assert_false(_menu.open(), "déjà ouvert")
	assert_true(_boot.is_stable(), "le menu ouvert est un état stable (§5.4)")
	_menu.close()


func test_dashboard_view_is_sent_on_open_and_a_placeholder_for_other_screens() -> void:
	await _start_free()
	assert_true(_menu.open())
	assert_eq(_screen.dashboards.size(), 1)
	var view: DashboardView = _screen.dashboards[0]
	assert_eq(view.cards.size(), 4, "avant le starter : 4 cartes (Q-2)")
	assert_eq(view.zone_name, "Bourg Palette")
	_screen.route_requested.emit(MenuRoute.for_screen(MenuRoute.BAG))
	assert_eq(_screen.placeholders, [MenuRoute.BAG] as Array[StringName], "écran provisoire")
	_screen.back_requested.emit()
	assert_eq(_screen.dashboards.size(), 2, "retour au tableau de bord : vue neuve")
	assert_true(_menu.is_open(), "un niveau en arrière seulement")
	_screen.close_requested.emit()
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)


# --- Action menu -------------------------------------------------------------------------

func test_menu_action_opens_then_closes() -> void:
	await _start_free()
	await _press_menu_action()
	assert_true(_menu.is_open(), "Échap / M ouvre")
	assert_true(get_tree().paused)
	await _press_menu_action()
	assert_false(_menu.is_open(), "puis ferme")
	assert_false(get_tree().paused)


# --- Retour Android ------------------------------------------------------------------------

func test_back_never_quits_the_game() -> void:
	assert_false(ProjectSettings.get_setting("application/config/quit_on_go_back", true),
		"quit_on_go_back = false (Q-3)")


func test_back_with_the_menu_open_goes_one_level_then_closes_without_quitting() -> void:
	await _start_free()
	assert_true(_menu.open())
	_menu.go(MenuRoute.for_screen(MenuRoute.BAG))
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(_menu.is_open(), "un niveau en arrière : le tableau de bord")
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.DASHBOARD)
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(_menu.is_open(), "à la racine : ferme")
	assert_false(get_tree().paused)
	assert_true(is_instance_valid(_boot) and _boot.is_inside_tree(), "le jeu tourne toujours")


func test_back_in_exploration_saves_then_opens_the_menu() -> void:
	await _start_free()
	await wait_process_frames(2)
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(_menu.is_open(), "ouvre le menu")
	assert_eq(_writes(), writes + 1, "sauvegarde immédiate")
	assert_true(is_instance_valid(_boot) and _boot.is_inside_tree(), "ne quitte pas")
	_menu.close()


func test_back_is_ignored_during_a_dialogue_and_a_transition() -> void:
	await _start_boot(&"player_house_1f", &"stairs", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running(), TIMEOUT)
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(_menu.is_open(), "dialogue : ignoré")
	assert_eq(_writes(), writes)
	await _finish_dialogue()
	SceneRouter.change_map(&"player_house_2f", &"stairs")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(_menu.is_open(), "transition : ignoré")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), TIMEOUT)


# --- Autosave ---------------------------------------------------------------------------

func test_autosave_on_close_only_if_the_state_changed() -> void:
	await _start_free()
	await wait_process_frames(2)
	var writes := _writes()
	assert_true(_menu.open())
	await wait_process_frames(3)
	_menu.close()
	await wait_process_frames(3)
	assert_eq(_writes(), writes, "rien n'a changé : aucune écriture")
	assert_true(_menu.open())
	_menu.mark_changed()
	_menu.close()
	await wait_process_frames(3)
	assert_eq(_writes(), writes + 1, "état changé : un autosave à la fermeture")
	assert_true(_menu.open())
	_menu.close()
	await wait_process_frames(3)
	assert_eq(_writes(), writes + 1, "le drapeau est remis à zéro")


func test_going_to_the_background_with_the_menu_open_writes_the_save() -> void:
	await _start_free()
	await wait_process_frames(2)
	assert_true(_menu.open())
	var writes := _writes()
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_writes(), writes + 1, "sauvegarde écrite menu ouvert")
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_menu.close()
