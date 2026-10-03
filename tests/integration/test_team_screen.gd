extends GutTest
## Écran Équipe (jalon 6, T7) : glisser-déposer et DÉPLACER (un seul `member_moved`),
## emplacements vides inertes, favori (étoile et texte), K.O. en texte, aucune condition
## d'évolution, zones tactiles et marges à 1920 et 2340 de large.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _data: PokemonData
var _zones: ZoneLibrary
var _moved: Array = []
var _favorites: Array[int] = []
var _items: Array[int] = []
var _selected: Array[int] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_moved.clear()
	_favorites.clear()
	_items.clear()
	_selected.clear()


## Vraie vue d'Équipe (TeamViews) ; le troisième est K.O. si [param ko].
func _view(count: int = 3, favorite: bool = false, ko: bool = true,
		activated: bool = true) -> TeamView:
	var state: Node = GameStateScript.new()
	state.new_game(7)
	var specs: Array = [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10],
		[&"bulbasaur", 8], [&"squirtle", 7], [&"pidgey", 6]]
	for i: int in count:
		var pokemon := PokemonFactory.create(_data, specs[i][0], specs[i][1], state.rng)
		state.party.add(pokemon)
		state.stamp_meeting(pokemon, Pokemon.Origin.CAPTURE, &"route_1")
	state.party.get_at(0).favorite = favorite
	if ko and count > 2:
		state.party.get_at(2).hp = 0
	if activated:
		state.pokedex.mark_seen(&"charmeleon")
		state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var view := TeamViews.build(state.party, _data, _zones, state.pokedex, unlocks)
	state.free()
	return view


func _menu_in(width: int, view: TeamView, selected: int = 0) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_team(view, selected)
	menu.open_animated()
	await wait_frames(3)
	var team := menu.get_team()
	team.member_moved.connect(func(a: int, b: int) -> void: _moved.append([a, b]))
	team.favorite_toggled.connect(func(i: int) -> void: _favorites.append(i))
	team.use_item_requested.connect(func(i: int) -> void: _items.append(i))
	team.member_selected.connect(func(i: int) -> void: _selected.append(i))
	return menu


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	return event


func _motion(pos: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = pos
	return event


func _tap(slot: TeamSlotCard) -> void:
	var pos := slot.size * 0.5
	slot._gui_input(_mouse(true, pos))
	slot._gui_input(_mouse(false, pos))


## Appui long sur [param from], glissé jusqu'au centre de [param to], relâché.
func _drag(from: TeamSlotCard, to: TeamSlotCard) -> void:
	var start := from.size * 0.5
	from._gui_input(_mouse(true, start))
	from._process(UiTokens.LONG_PRESS + 0.05)
	var end := start + (to.get_global_transform_with_canvas().origin
		- from.get_global_transform_with_canvas().origin)
	from._gui_input(_motion(end))
	from._gui_input(_mouse(false, end))


func _texts_of(node: Node) -> Array[String]:
	var texts: Array[String] = []
	var label := node as Label
	if label != null:
		texts.append(label.text)
	for child: Node in node.get_children():
		texts.append_array(_texts_of(child))
	return texts


func test_drag_a_on_b_emits_one_move() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	_drag(team.get_slot(0), team.get_slot(2))
	assert_eq(_moved, [[0, 2]], "un seul member_moved")


func test_short_press_is_a_tap_not_a_drag() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	_tap(team.get_slot(1))
	assert_eq(_moved, [])
	assert_eq(_selected, [1])
	assert_eq(team.get_selected(), 1)
	assert_eq(team.get_showcase().get_name_text(), "Roucool")


func test_drag_on_empty_slot_or_itself_emits_nothing() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	_drag(team.get_slot(0), team.get_slot(4))
	_drag(team.get_slot(0), team.get_slot(0))
	assert_eq(_moved, [])
	assert_false(team.get_ghost().visible)


func test_move_button_then_second_slot_same_signal() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	team.get_move_button().pressed.emit()
	assert_true(team.is_move_mode())
	assert_eq(team.get_move_source(), 0)
	assert_string_contains(team.get_hint_text(), "Salamèche")
	_tap(team.get_slot(2))
	assert_eq(_moved, [[0, 2]])
	assert_false(team.is_move_mode())


func test_move_mode_empty_slot_and_same_slot() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	team.get_move_button().pressed.emit()
	_tap(team.get_slot(5))
	assert_eq(_moved, [])
	assert_true(team.is_move_mode(), "un vide ne fait rien")
	_tap(team.get_slot(0))
	assert_false(team.is_move_mode(), "retoucher A annule")
	team.get_move_button().pressed.emit()
	team.get_move_button().pressed.emit()
	assert_false(team.is_move_mode(), "ANNULER")
	assert_eq(_moved, [])


func test_single_pokemon_cannot_be_moved() -> void:
	var team := (await _menu_in(2340, _view(1))).get_team()
	team.get_move_button().pressed.emit()
	assert_false(team.is_move_mode())
	assert_ne(team.get_hint_text(), "", "la raison est écrite")


func test_empty_slots_are_neutral_and_inert() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	for i: int in range(3, 6):
		var slot := team.get_slot(i)
		assert_true(slot.is_empty())
		assert_eq(slot.get_all_text(), "", "aucun texte (pas de « Ajouter un Pokémon »)")
		_tap(slot)
		_drag(slot, team.get_slot(0))
	assert_eq(_moved, [])
	assert_eq(_selected, [])


func test_swap_animation_plays_when_the_view_returns() -> void:
	var menu := await _menu_in(2340, _view())
	menu.speed_scale = 1.0
	var team := menu.get_team()
	team.speed_scale = 1.0
	team.member_moved.connect(func(_a: int, _b: int) -> void: team.show_team(_view(), 2))
	_drag(team.get_slot(0), team.get_slot(2))
	assert_true(team.is_swapping())
	assert_eq(team.get_selected(), 2, "la sélection suit le Pokémon déplacé")
	await wait_seconds(UiTokens.TEAM_SWAP_TIME + 0.2)
	assert_false(team.is_swapping())
	assert_eq(team.get_slot(0).position, Vector2.ZERO, "retour à sa place")


func test_favorite_star_and_text() -> void:
	var menu := await _menu_in(2340, _view(3, false))
	var team := menu.get_team()
	assert_eq(team.get_showcase().get_favorite_text(), "", "pas de favori : rien")
	assert_false(team.get_slot(0).is_favorite_shown())
	var off_icon := team.get_favorite_button().icon
	team.get_favorite_button().pressed.emit()
	assert_eq(_favorites, [0])
	menu.show_team(_view(3, true), 0)
	assert_eq(team.get_showcase().get_favorite_text(), "Favori", "texte, pas qu'une couleur")
	assert_true(team.get_slot(0).is_favorite_shown())
	assert_ne(team.get_favorite_button().icon, off_icon, "l'étoile change")
	assert_string_contains(team.get_favorite_button().text, "RETIRER")


func test_use_item_signal() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	_tap(team.get_slot(1))
	team.get_use_button().pressed.emit()
	assert_eq(_items, [1])


func test_ko_is_written_out() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	assert_eq(team.get_slot(2).get_status_text(), "K.O.")
	assert_eq(team.get_slot(0).get_status_text(), "")
	_tap(team.get_slot(2))
	assert_eq(team.get_showcase().get_status_text(), "K.O.")


func test_no_evolution_condition_anywhere() -> void:
	for activated: bool in [false, true]:
		var team := (await _menu_in(2340, _view(3, false, true, activated))).get_team()
		for i: int in 3:
			_tap(team.get_slot(i))
			for text: String in _texts_of(team.get_sheet().get_evolution_row()):
				assert_false(text.to_lower().contains("niveau") or text.contains("Nv"),
					"pas de condition : " + text)
				for digit: String in "0123456789":
					assert_false(text.contains(digit), "pas de nombre : " + text)


func test_unknown_stage_has_no_image() -> void:
	var team := (await _menu_in(2340, _view(3, false, true, false))).get_team()
	var row := team.get_sheet().get_evolution_row()
	var unknown := 0
	for node: Node in row.get_children():
		if "???" in _texts_of(node):
			unknown += 1
			for tex: Node in node.find_children("*", "TextureRect", true, false):
				assert_null((tex as TextureRect).texture)
	assert_eq(unknown, 1, "un seul « ??? » avant l'activation")


func test_tabs_pages_and_kept_on_update() -> void:
	var menu := await _menu_in(2340, _view())
	var team := menu.get_team()
	var sheet := team.get_sheet()
	assert_true(sheet.get_page(PokemonSheet.Tab.OVERVIEW).visible)
	sheet.select_tab(PokemonSheet.Tab.MOVES)
	assert_true(sheet.get_page(PokemonSheet.Tab.MOVES).visible)
	assert_false(sheet.get_page(PokemonSheet.Tab.OVERVIEW).visible)
	assert_gt(sheet.get_move_cards().size(), 0)
	menu.show_team(_view(3, true), 1)
	assert_eq(sheet.get_tab(), PokemonSheet.Tab.MOVES, "l'onglet reste ouvert")
	assert_eq(team.modulate.a, 1.0, "pas de nouvelle entrée")
	sheet.select_tab(PokemonSheet.Tab.HISTORY)
	assert_gt(sheet.get_history_container().get_child_count(), 0)


func test_move_card_opens_the_detail_sheet_and_a_tap_closes_it() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	team.get_sheet().select_tab(PokemonSheet.Tab.MOVES)
	team.get_sheet().get_move_cards()[0].tapped.emit()
	await wait_frames(2)
	assert_true(team.is_move_sheet_open())
	assert_eq(team.get_move_sheet().get_name_text(), "GRIFFE")
	team.get_overlay().gui_input.emit(_mouse(false, Vector2(5, 5)))
	assert_false(team.is_move_sheet_open())


func test_sprite_is_integer_nearest_x6() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	var sprite := team.get_showcase().get_sprite()
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(sprite.scale, Vector2(6, 6))
	assert_eq(team.get_showcase().get_sprite_shown_size(), Vector2(384, 384))


func test_breathing_is_a_vertical_offset_only() -> void:
	var menu := await _menu_in(2340, _view())
	menu.speed_scale = 1.0
	var team := menu.get_team()
	team.speed_scale = 1.0
	menu.show_team(_view(), 0)
	await wait_seconds(0.6)
	var sprite := team.get_showcase().get_sprite()
	assert_true(team.get_showcase().is_breathing())
	assert_eq(sprite.scale, Vector2(6, 6), "jamais d'échelle non entière")
	assert_eq(sprite.position.x, 0.0)
	assert_true(sprite.position.y <= 0.0 and sprite.position.y >= -UiTokens.TEAM_BREATH_PX)


func test_touch_targets_and_safe_margins() -> void:
	for width: int in WIDTHS:
		var team := (await _menu_in(width, _view())).get_team()
		var controls: Array[Control] = [team.get_back_button(), team.get_use_button(),
			team.get_move_button(), team.get_favorite_button()]
		for tab: PokemonSheet.Tab in PokemonSheet.TAB_TEXTS:
			controls.append(team.get_sheet().get_tab_button(tab))
		for slot: TeamSlotCard in team.get_slots():
			controls.append(slot)
		for control: Control in controls:
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN) - 0.5, "hauteur %s" % control.name)
			assert_gte(rect.size.x, float(UiTokens.TOUCH_MIN), "largeur %s" % control.name)
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5)
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5)
			assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5)
			assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5)


func test_slot_texts() -> void:
	var team := (await _menu_in(2340, _view())).get_team()
	var slot := team.get_slot(0)
	assert_eq(slot.get_name_text(), "Salamèche")
	assert_eq(slot.get_level_text(), "Nv. 14")
	assert_string_contains(slot.get_hp_text(), " / ")
