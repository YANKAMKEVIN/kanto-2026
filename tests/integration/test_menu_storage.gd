extends GutTest
## Le Stockage jouable (jalon 7 T16, jalon-07.md §6.4, §6.9 ; dossier 09 §8, §19) avec la vraie
## scène Boot, le vrai écran Stockage (T15), la vraie carte du Centre, la partie du départ de
## débogage `storage_qa` (6 en équipe dont un K.O., 10 au stockage dont un favori, devant le
## terminal) et une sauvegarde en mémoire :
## - EXAMINER le terminal ouvre le Stockage seul (aucune réplique), retour Android = fermer ;
## - déposer (bouton et glisser), reprendre, équipe pleine refusée, dernier Pokémon refusé ;
## - libérer : favori protégé (raison, sans confirmation), confirmation, ANNULER par le retour,
##   puis LIBÉRER ; fermeture → sauvegarde relue ;
## - le combat suivant envoie le premier Pokémon valide du nouvel ordre ;
## - le bouton STOCKAGE de l'Équipe n'existe qu'au Centre ; rien hors du Centre.
## Menu ouvert = arbre en pause : on attend des images, jamais `wait_until` (§15.12, point 10).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const START := "res://tools/debug_start/storage_qa.json"
const SAVE_PATH := "user://test_menu_storage_save.json"
const DATE := "2026-10-05T18:30:00"
const FADE := 0.05
const TIMEOUT := 12.0
const MAX_FRAMES := 600
const TERMINAL_CELL := Vector2i(1, 4)
const PARTY := StorageRules.Place.PARTY
const STORAGE := StorageRules.Place.STORAGE

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _menu: MenuDirector
var _screen: TrainerMenu
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	Haptics.sink = func(_ms: int) -> void: pass


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot (sauvegarde en mémoire, autosave actif) devant le terminal du Centre (ou ailleurs), puis
## la partie de `storage_qa`, appliquée à la main (un départ de débogage n'écrirait rien).
func _start(map: StringName = &"viridian_center", spawn: StringName = &"terminal",
		facing: Vector2i = Vector2i.UP) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	_menu = _boot.get_menu_director()
	_screen = _boot.get_trainer_menu()
	_screen.speed_scale = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_runner.page_started.connect(func(_i: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


## Images jusqu'à [param condition] (le menu ouvert gèle les minuteries de GUT).
func _frames_until(condition: Callable) -> bool:
	for i: int in MAX_FRAMES:
		if condition.call():
			return true
		await wait_process_frames(1)
	return bool(condition.call())


## EXAMINER le terminal (face à lui) : le Stockage s'ouvre à la fin du dialogue sans réplique.
func _use_the_terminal() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _frames_until(func() -> bool: return _menu.is_open())
	await wait_process_frames(2)


func _storage() -> StorageScreen:
	return _screen.get_storage()


func _species(list: Array[Pokemon]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for pokemon: Pokemon in list:
		ids.append(pokemon.species_id)
	return ids


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	event.global_position = pos
	return event


func _motion(pos: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	return event


## Toucher court sur [param card] (sélection).
func _tap(card: StorageCard) -> void:
	card._gui_input(_mouse(true, card.size * 0.5))
	card._gui_input(_mouse(false, card.size * 0.5))
	await wait_process_frames(1)


## Appui long sur [param card], glissé jusqu'à [param target] (position globale), relâché.
func _drag(card: StorageCard, target: Vector2) -> void:
	var origin := card.get_global_transform_with_canvas().origin
	card._gui_input(_mouse(true, card.size * 0.5))
	card._process(UiTokens.LONG_PRESS + 0.05)
	card._gui_input(_motion(target - origin))
	card._gui_input(_mouse(false, target - origin))
	await wait_process_frames(1)


func test_storage_qa_starts_in_front_of_the_terminal() -> void:
	await _start()
	assert_eq(_boot.get_map().map_id, &"viridian_center")
	assert_eq(_player.get_cell(), TERMINAL_CELL)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.storage.size(), 10)
	assert_true(GameState.storage.get_at(2).favorite, "le Piafabec favori")
	assert_push_error_count(0)


func test_the_terminal_opens_the_storage_alone_and_back_closes_it() -> void:
	await _start()
	var writes := _writes()
	await _use_the_terminal()
	assert_true(_menu.is_open(), "le Stockage s'ouvre")
	assert_true(_menu.get_navigator().is_standalone(), "écran seul")
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.STORAGE)
	assert_true(get_tree().paused, "monde en pause")
	assert_eq(_pages.size(), 0, "aucune réplique : le terminal ouvre l'écran")
	var screen := _storage()
	assert_not_null(screen, "le vrai StorageScreen")
	if screen == null:
		return
	assert_true(screen.is_visible_in_tree(), "affiché")
	assert_eq(screen.get_party_cards().size(), 6)
	assert_eq(screen.get_storage_cards().size(), 10)
	assert_true(screen.get_view().selection.equals(StorageSelection.new(PARTY, 0)), "tête")
	assert_eq(screen.get_primary_button().text, StorageViews.DEPOSIT_LABEL)
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(_menu.is_open(), "retour Android = fermer")
	assert_false(get_tree().paused)
	await wait_process_frames(4)
	assert_eq(_writes(), writes, "rien n'a changé : pas d'autosave")
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_push_error_count(0)


func test_deposit_withdraw_and_refusals_on_the_real_screen() -> void:
	await _start()
	await _use_the_terminal()
	var screen := _storage()
	var lead := GameState.party.get_at(0)
	var refused: Array[Array] = []
	_menu.storage_refused.connect(func(place: int, index: int, _text: String) -> void:
		refused.append([place, index]))
	# Équipe pleine : REPRENDRE refusé, la carte tremble, la raison s'écrit, rien ne change.
	await _tap(screen.get_storage_cards()[0])
	assert_eq(screen.get_primary_button().text, StorageViews.WITHDRAW_LABEL)
	screen.get_primary_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.get_refusal_text(), StorageViews.PARTY_FULL_TEXT)
	assert_eq(refused, [[STORAGE, 0]] as Array[Array], "la carte refusée tremble")
	assert_eq([GameState.party.size(), GameState.storage.size()], [6, 10])
	# DÉPOSER la tête (bouton) : à la fin du stockage, la sélection la suit.
	await _tap(screen.get_party_cards()[0])
	screen.get_primary_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq([GameState.party.size(), GameState.storage.size()], [5, 11])
	assert_eq(GameState.storage.get_at(10), lead, "même instance, à la fin")
	assert_true(screen.get_view().selection.equals(StorageSelection.new(STORAGE, 10)))
	assert_eq(screen.get_storage_cards().size(), 11, "la grille suit")
	# REPRENDRE en glissant (STOCKAGE → ÉQUIPE) : en fin d'équipe.
	await _drag(screen.get_storage_cards()[10], screen.get_party_zone().get_global_rect()
		.get_center())
	assert_eq(GameState.party.get_at(5), lead, "repris en fin d'équipe")
	assert_eq(GameState.storage.size(), 10)
	# Déposer en glissant (ÉQUIPE → STOCKAGE) jusqu'au dernier valide.
	for i: int in 4:
		await _drag(screen.get_party_cards()[0], screen.get_grid_zone().get_global_rect()
			.get_center())
	assert_eq(_species(GameState.party.get_all()), [&"mankey", &"charmander"] as Array[StringName],
		"Roucool, Rattata K.O., Piafabec et Nidoran♀ déposés")
	await _drag(screen.get_party_cards()[0], screen.get_grid_zone().get_global_rect()
		.get_center())
	assert_eq(GameState.party.size(), 1, "Férosinge déposé")
	await _tap(screen.get_party_cards()[0])
	screen.get_primary_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.get_refusal_text(), StorageViews.LAST_POKEMON_TEXT,
		"« Tu dois garder au moins un Pokémon avec toi. »")
	assert_eq(GameState.party.size(), 1, "le dernier reste")
	_menu.close()
	await wait_process_frames(2)
	assert_push_error_count(0)


func test_release_protects_the_favorite_confirms_and_saves() -> void:
	await _start()
	await _use_the_terminal()
	var screen := _storage()
	var writes := _writes()
	var favorite := GameState.storage.get_at(2)
	var released := GameState.storage.get_at(0)
	# Favori : « ⋯ » → LIBÉRER → refus et raison, aucune confirmation.
	await _tap(screen.get_storage_cards()[2])
	screen.get_more_button().pressed.emit()
	await wait_process_frames(1)
	screen.get_release_button().pressed.emit()
	await wait_process_frames(1)
	assert_eq(screen.get_refusal_text(), StorageViews.FAVORITE_TEXT
		% favorite.display_name(_boot.get_pokemon_data()))
	assert_false(screen.get_choice().is_showing(), "aucun contournement")
	assert_eq(GameState.storage.size(), 10)
	# Un autre : confirmation ; retour Android = ANNULER, rien ne change, l'écran reste.
	await _tap(screen.get_storage_cards()[0])
	screen.get_more_button().pressed.emit()
	await wait_process_frames(1)
	screen.get_release_button().pressed.emit()
	await wait_process_frames(1)
	assert_true(screen.get_choice().is_showing(), "« Libérer Roucool ? »")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(screen.get_choice().is_showing(), "confirmation fermée")
	assert_true(_menu.is_open(), "le Stockage reste ouvert")
	assert_eq(GameState.storage.size(), 10, "ANNULER : rien")
	# LIBÉRER.
	screen.get_more_button().pressed.emit()
	await wait_process_frames(1)
	screen.get_release_button().pressed.emit()
	await wait_process_frames(1)
	screen.get_choice().get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(GameState.storage.size(), 9, "libéré")
	assert_false(GameState.storage.get_all().has(released))
	assert_true(GameState.pokedex.is_caught(&"pidgey"), "le Pokédex ne bouge pas")
	assert_eq(_writes(), writes, "rien d'écrit menu ouvert")
	# Fermeture : autosave, relu.
	_menu.close()
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	var reloaded: Node = autofree(GameStateScript.new())
	assert_true(reloaded.load_dict(SaveSystem.new(_fs, SAVE_PATH).read(),
		_boot.get_pokemon_data()))
	assert_eq(reloaded.party.size(), 6)
	assert_eq(reloaded.storage.size(), 9)
	assert_eq(_species(reloaded.storage.get_all()), _species(GameState.storage.get_all()))
	assert_true(reloaded.storage.get_at(1).favorite, "le favori, désormais en 2e place")
	assert_push_error_count(0)


func test_the_next_battle_sends_the_first_able_of_the_new_order() -> void:
	await _start()
	await _use_the_terminal()
	var writes := _writes()
	# Salamèche et Roucool déposés : Rattata (K.O.) en tête, Piafabec premier valide.
	_screen.storage_deposit_requested.emit(0)
	_screen.storage_deposit_requested.emit(0)
	await wait_process_frames(1)
	assert_eq(GameState.party.get_lead().species_id, &"rattata")
	_menu.close()
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	var saved: Dictionary = SaveSystem.new(_fs, SAVE_PATH).read()
	var order: Array[String] = []
	for entry: Variant in saved["party"]:
		order.append(String((entry as Dictionary)["species"]))
	assert_eq(order, ["rattata", "spearow", "nidoran_f", "mankey"] as Array[String], "écrit")
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	var sent: Array[StringName] = []
	_boot.get_battle_director().event_played.connect(func(event: BattleEvent) -> void:
		if event.kind == BattleEvent.Kind.SENT_OUT and event.side == BattleEvent.SideId.PLAYER:
			sent.append(event.species_id))
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 3, &"route_1_grass")))
	await wait_until(func() -> bool: return not sent.is_empty(), TIMEOUT)
	assert_eq(sent, [&"spearow"] as Array[StringName], "le K.O. sauté : Piafabec entre")
	assert_push_error_count(0)


func test_the_team_storage_button_exists_only_in_the_center() -> void:
	await _start()
	assert_true(_menu.open(MenuRoute.team()))
	await wait_process_frames(2)
	var team := _screen.get_team()
	assert_true(team.get_storage_button().visible, "STOCKAGE au Centre")
	team.get_storage_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.STORAGE)
	assert_false(_menu.get_navigator().is_standalone(), "dans le menu, au-dessus de l'Équipe")
	assert_true(_storage().is_visible_in_tree())
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.TEAM, "retour = l'Équipe")
	_menu.close()
	await wait_process_frames(2)
	assert_push_error_count(0)


func test_nothing_outside_the_center() -> void:
	await _start(&"viridian_city", &"from_center", Vector2i.DOWN)
	assert_false(_menu.open(MenuRoute.storage(), true), "pas de Stockage en ville")
	assert_false(get_tree().paused)
	assert_true(_menu.open(MenuRoute.team()))
	await wait_process_frames(2)
	assert_false(_screen.get_team().get_storage_button().visible, "pas de bouton STOCKAGE")
	assert_false(_menu.go(MenuRoute.storage()))
	_menu.close()
	await wait_process_frames(2)
	assert_push_error_count(0)
