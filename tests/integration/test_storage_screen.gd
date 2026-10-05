extends GutTest
## Écran Stockage (jalon 7, T15 ; jalon-07.md §6.9) avec les vraies vues de StorageViews : glisser =
## un signal (le même que le bouton), sélection + bouton, refus = tremblement + raison, LIBÉRER
## seulement dans le menu « ⋯ », confirmation, favori sans contournement, défiler ne sélectionne
## rien, zones tactiles et marges à 1920 et 2340.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const GameStateScript := preload("res://game/autoload/game_state.gd")
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _data: PokemonData
var _state: Node
var _selection: StorageSelection
var _events: Array = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	for spec: Array in [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10]]:
		_state.party.add(PokemonFactory.create(_data, spec[0], spec[1], _state.rng))
	for i: int in 14:
		var species: StringName = [&"pidgey", &"rattata", &"squirtle"][i % 3]
		_state.storage.add(PokemonFactory.create(_data, species, 5 + i, _state.rng))
	_selection = StorageSelection.new(StorageRules.Place.PARTY, 0)
	_events.clear()


func after_each() -> void:
	_state.free()


func _view() -> StorageView:
	return StorageViews.build(_state, _data, _selection)


## Écran seul dans un menu à [param width] ; se comporte comme le directeur pour la sélection
## (renvoie la vue neuve) et note tous les signaux dans [member _events].
func _menu_in(width: int) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_storage(_view())
	menu.open_animated()
	await wait_frames(3)
	menu.storage_selected.connect(func(p: int, i: int) -> void:
		_events.append([&"selected", p, i])
		_selection = StorageSelection.new(p as StorageRules.Place, i)
		menu.show_storage(_view()))
	menu.storage_deposit_requested.connect(func(i: int) -> void:
		_events.append([&"deposit", i]))
	menu.storage_withdraw_requested.connect(func(i: int) -> void:
		_events.append([&"withdraw", i]))
	menu.storage_favorite_toggled.connect(func(p: int, i: int) -> void:
		_events.append([&"favorite", p, i]))
	menu.storage_release_requested.connect(func(p: int, i: int) -> void:
		_events.append([&"release", p, i]))
	menu.storage_release_confirmed.connect(func(p: int, i: int) -> void:
		_events.append([&"confirmed", p, i]))
	menu.back_requested.connect(func() -> void: _events.append([&"back"]))
	return menu


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


## Appui long sur [param card], glissé jusqu'à [param target] (position globale), relâché.
func _drag(card: StorageCard, target: Vector2) -> void:
	var start := card.size * 0.5
	var origin := card.get_global_transform_with_canvas().origin
	card._gui_input(_mouse(true, start))
	card._process(UiTokens.LONG_PRESS + 0.05)
	card._gui_input(_motion(target - origin))
	card._gui_input(_mouse(false, target - origin))


func _count(kind: StringName) -> int:
	var n := 0
	for event: Array in _events:
		if event[0] == kind:
			n += 1
	return n


func test_screen_shows_party_storage_and_titles() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_eq(menu.get_current_screen(), screen)
	assert_eq(screen.get_party_cards().size(), 6)
	assert_eq(screen.get_storage_cards().size(), 14)
	assert_eq(screen.get_party_cards()[0].get_name_text(), "Salamèche")
	assert_true(screen.get_party_cards()[3].is_empty(), "emplacement vide neutre")
	assert_eq(screen.get_party_cards()[0].get_look(), TeamSlotCard.Look.SELECTED)
	assert_eq(screen.get_action_texts(), PackedStringArray(["DÉPOSER", "FAVORI"]))
	assert_eq(screen.get_back_button().text, "RETOUR")


func test_grid_columns_follow_width() -> void:
	var narrow := await _menu_in(1920)
	assert_eq(narrow.get_storage().get_grid_columns(), 2)
	var wide := await _menu_in(2340)
	assert_eq(wide.get_storage().get_grid_columns(), 3)


func test_drag_party_to_storage_emits_one_deposit() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_party_cards()[1]
	_drag(card, screen.get_grid_zone().get_global_rect().get_center())
	assert_eq(_events, [[&"deposit", 1]], "un seul signal, avec l'index")


func test_drag_storage_to_party_emits_one_withdraw() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_storage_cards()[3]
	_drag(card, screen.get_party_zone().get_global_rect().get_center())
	assert_eq(_events, [[&"withdraw", 3]])


func test_drag_dropped_elsewhere_or_on_own_list_emits_nothing() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	_drag(screen.get_party_cards()[0], screen.get_party_zone().get_global_rect().get_center())
	_drag(screen.get_storage_cards()[0], screen.get_grid_zone().get_global_rect().get_center())
	_drag(screen.get_party_cards()[0], Vector2(1200.0, 40.0))
	assert_true(_events.is_empty(), "pas de réordonnancement, pas de dépôt hors zone")
	assert_false(screen.is_dragging())
	assert_false(screen.is_drop_zone_shown())


func test_drag_shows_ghost_and_target_frame() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_party_cards()[0]
	card._gui_input(_mouse(true, card.size * 0.5))
	card._process(UiTokens.LONG_PRESS + 0.05)
	assert_true(screen.is_dragging())
	assert_true(screen.get_ghost().visible)
	assert_true(screen.is_drop_zone_shown())
	assert_eq(screen.get_drop_place(), StorageRules.Place.STORAGE)
	assert_eq(card.get_look(), TeamSlotCard.Look.SOURCE)
	card._gui_input(_mouse(false, card.size * 0.5))
	assert_false(screen.is_dragging())


func test_short_press_is_a_selection_not_a_drag() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_party_cards()[2]
	card._gui_input(_mouse(true, card.size * 0.5))
	card._gui_input(_mouse(false, card.size * 0.5))
	assert_eq(_events, [[&"selected", StorageRules.Place.PARTY, 2]])
	assert_eq(screen.get_party_cards()[2].get_look(), TeamSlotCard.Look.SELECTED)


func test_select_then_button_emits_the_same_signals_as_drag() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_party_cards()[1]
	card._gui_input(_mouse(true, card.size * 0.5))
	card._gui_input(_mouse(false, card.size * 0.5))
	screen.get_primary_button().pressed.emit()
	assert_eq(_events[1], [&"deposit", 1], "DÉPOSER = le glisser")
	_events.clear()
	var stored := screen.get_storage_cards()[4]
	stored._gui_input(_mouse(true, stored.size * 0.5))
	stored._gui_input(_mouse(false, stored.size * 0.5))
	assert_eq(screen.get_primary_button().text, "REPRENDRE")
	screen.get_primary_button().pressed.emit()
	assert_eq(_events[1], [&"withdraw", 4], "REPRENDRE = le glisser")


func test_favorite_button_emits_selection() -> void:
	var menu := await _menu_in(2340)
	menu.get_storage().get_favorite_button().pressed.emit()
	assert_eq(_events, [[&"favorite", StorageRules.Place.PARTY, 0]])


func test_favorite_state_is_shown() -> void:
	_state.party.get_at(0).favorite = true
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_true(screen.get_party_cards()[0].is_favorite_shown())
	assert_eq(screen.get_favorite_button().theme_type_variation, &"TeamActionOn")


func test_release_only_in_secondary_menu() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_null(screen.get_release_button(), "pas de LIBÉRER en bouton principal")
	assert_false("LIBÉRER" in screen.get_action_texts())
	screen.get_more_button().pressed.emit()
	assert_true(screen.is_menu_open())
	var release := screen.get_release_button()
	assert_not_null(release)
	assert_eq(release.text, "LIBÉRER")
	release.pressed.emit()
	assert_eq(_events, [[&"release", StorageRules.Place.PARTY, 0]])
	assert_false(screen.is_menu_open(), "le menu se referme")
	assert_false(screen.get_choice().is_showing(), "la confirmation vient du directeur")


func test_confirmation_release_confirms_and_cancel_does_nothing() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	menu.ask_storage_release(StorageViews.release_choice("Salamèche"),
		StorageRules.Place.PARTY, 0)
	assert_true(screen.get_choice().is_showing())
	assert_true("Libérer Salamèche ?" in screen.get_choice().get_texts())
	screen.get_choice().get_cancel_button().pressed.emit()
	assert_eq(_count(&"confirmed"), 0, "ANNULER ne fait rien")
	menu.ask_storage_release(StorageViews.release_choice("Salamèche"),
		StorageRules.Place.STORAGE, 5)
	screen.get_choice().get_confirm_button().pressed.emit()
	assert_eq(_events, [[&"confirmed", StorageRules.Place.STORAGE, 5]])


func test_android_back_closes_confirmation_then_menu_then_leaves() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_false(menu.storage_back(), "rien d'ouvert : l'hôte quitte")
	screen.get_more_button().pressed.emit()
	assert_true(menu.storage_back())
	assert_false(screen.is_menu_open())
	menu.ask_storage_release(StorageViews.release_choice("Salamèche"),
		StorageRules.Place.PARTY, 0)
	assert_true(menu.storage_back())
	assert_false(screen.get_choice().is_showing())
	assert_eq(_count(&"confirmed"), 0, "retour = ANNULER")
	assert_false(menu.storage_back())
	screen.get_back_button().pressed.emit()
	assert_eq(_count(&"back"), 1)


func test_refusal_shakes_the_card_and_writes_the_reason() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	menu.speed_scale = 1.0
	screen.speed_scale = 1.0
	var card := screen.get_party_cards()[0]
	var base := card.position
	menu.show_storage_refusal(StorageRules.Place.PARTY, 0, StorageViews.LAST_POKEMON_TEXT)
	assert_eq(screen.get_refusal_text(), "Tu dois garder au moins un Pokémon avec toi.")
	assert_true(screen.is_shaking())
	assert_eq(screen.get_shaking_card(), card)
	await wait_seconds(UiTokens.PICKER_SHAKE_TIME * 0.5)
	assert_ne(card.position.x, base.x, "la carte bouge pendant le tremblement")
	await wait_seconds(UiTokens.PICKER_SHAKE_TIME)
	assert_eq(card.position, base, "elle revient à sa place")
	assert_true(_events.is_empty(), "un refus n'émet rien")


func test_favorite_refusal_has_no_workaround() -> void:
	var favorite: Pokemon = _state.storage.get_at(2)
	favorite.favorite = true
	_selection = StorageSelection.new(StorageRules.Place.STORAGE, 2)
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var result := StorageRules.release(_state.party, _state.storage,
		StorageRules.Place.STORAGE, 2)
	menu.show_storage_refusal(StorageRules.Place.STORAGE, 2,
		StorageViews.result_text(result, _data))
	assert_true(screen.get_refusal_text().begins_with("Retire d'abord"))
	assert_false(screen.get_choice().is_showing(), "pas de confirmation")
	assert_eq(screen.get_action_texts().size(), 2, "pas de bouton de contournement")
	assert_eq(screen.get_primary_button().text, "REPRENDRE")


func test_new_view_clears_refusal() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	menu.show_storage_refusal(StorageRules.Place.PARTY, 0, "Raison")
	menu.show_storage(_view())
	assert_eq(screen.get_refusal_text(), "")


func test_swipe_over_cards_selects_nothing() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_storage_cards()[1]
	var from := card.get_global_rect().get_center()
	var finger := TouchFinger.new(screen.get_viewport())
	finger.swipe(from, Vector2(0.0, -150.0))
	finger.swipe(from, Vector2(40.0, 0.0))
	await wait_process_frames(2)
	assert_true(_events.is_empty(), "défiler ne sélectionne ni ne déplace rien")
	assert_eq(screen.get_scroll().scroll_deadzone, roundi(UiTokens.TAP_SLOP))
	finger.tap(screen.get_storage_cards()[1].get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(_count(&"selected"), 1, "un toucher court sélectionne")


func test_long_hold_without_move_in_grid_starts_drag_not_scroll() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_storage_cards()[0]
	card._gui_input(_mouse(true, card.size * 0.5))
	card._process(UiTokens.LONG_PRESS + 0.05)
	assert_true(screen.is_dragging())
	assert_eq(screen.get_drop_place(), StorageRules.Place.PARTY)
	card._gui_input(_mouse(false, card.size * 0.5))


func test_scrolling_moves_before_long_press_cancel_the_press() -> void:
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	var card := screen.get_storage_cards()[0]
	card._gui_input(_mouse(true, card.size * 0.5))
	card._gui_input(_motion(card.size * 0.5 + Vector2(0.0, UiTokens.TAP_SLOP + 10.0)))
	card._process(UiTokens.LONG_PRESS + 0.05)
	assert_false(screen.is_dragging(), "un doigt qui défile ne devient pas un glisser")


func test_empty_storage_shows_the_phrase() -> void:
	while _state.storage.size() > 0:
		_state.storage.remove_at(0)
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_eq(screen.get_storage_cards().size(), 0)
	assert_true(screen.get_view().empty_text == "Le stockage est vide.")


func test_selection_in_storage_actions() -> void:
	_selection = StorageSelection.new(StorageRules.Place.STORAGE, 0)
	var menu := await _menu_in(2340)
	var screen := menu.get_storage()
	assert_eq(screen.get_action_texts(), PackedStringArray(["REPRENDRE", "FAVORI"]))
	assert_eq(screen.get_storage_cards()[0].get_look(), TeamSlotCard.Look.SELECTED)


func test_touch_targets_and_margins() -> void:
	for width: int in WIDTHS:
		var menu := await _menu_in(width)
		var screen := menu.get_storage()
		screen.get_more_button().pressed.emit()
		var targets: Array[Control] = [screen.get_back_button(), screen.get_primary_button(),
			screen.get_favorite_button(), screen.get_more_button(),
			screen.get_release_button()]
		targets.append_array(screen.get_party_cards())
		targets.append_array(screen.get_storage_cards().slice(0, 6))
		for control: Control in targets:
			if control == null or not control.is_visible_in_tree():
				continue
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, UiTokens.TOUCH_MIN - 0.5, "zone ≥ 128 (%s)" % control.name)
			assert_gte(rect.size.x, UiTokens.TOUCH_MIN - 0.5)
			assert_gte(rect.position.x, UiTokens.SAFE_MARGIN - 0.5)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN + 0.5)
			assert_lte(rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5)


func test_team_screen_storage_button_only_when_available() -> void:
	var menu := await _menu_in(2340)
	var unlocks := MenuUnlocks.new(_state.flags, _state.party)
	var view := TeamViews.build(_state.party, _data, null, _state.pokedex, unlocks)
	assert_false(view.storage_available)
	menu.show_team(view, 0)
	assert_false(menu.get_team().get_storage_button().visible, "absent hors du Centre")
	view.storage_available = true
	var routes: Array = []
	menu.route_requested.connect(func(r: MenuRoute) -> void: routes.append(r))
	menu.show_team(view, 0)
	var button := menu.get_team().get_storage_button()
	assert_true(button.visible)
	assert_false(button.disabled)
	button.pressed.emit()
	assert_eq(routes.size(), 1)
	assert_eq((routes[0] as MenuRoute).screen, MenuRoute.STORAGE)
