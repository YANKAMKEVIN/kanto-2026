extends GutTest
## Écran Sac du menu (jalon 6, T11) : un toucher = un aperçu (jamais un usage), UTILISER → choix
## du Pokémon, Pokémon incompatible visible avec sa raison et sans target_chosen, résultat et
## UTILISER À NOUVEAU (un seul repeat_requested), onglet vide absent, objet de combat hors combat
## (mention, pas de bouton), appui long = favori, tri, zones tactiles et marges à 1920 et 2340.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _data: PokemonData
var _items: ItemLibrary
var _bag: Bag
var _party: Party
var _previews: Array[StringName] = []
var _uses: Array[StringName] = []
var _favorites: Array[StringName] = []
var _sorts: Array[int] = []
var _targets: Array = []
var _repeats: int = 0
var _categories: Array[StringName] = []


func _item(name: String, category: String, extra: Dictionary = {}) -> Dictionary:
	var entry := {"name": name, "plural": name + "s", "feminine": true, "category": category,
		"description": name + "."}
	entry.merge(extra)
	return entry


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	assert_true(_items.add_from_dict({
		"poke_ball": _item("Poké Ball", "ball", {"catch_bonus": 1}),
		"potion": _item("Potion", "heal", {"heal_amount": 20}),
		"super_potion": _item("Super Potion", "heal", {"heal_amount": 50}),
		"x_attack": _item("Attaque +", "battle"),
	}, "test"), str(_items.get_errors()))


func before_each() -> void:
	_bag = Bag.new()
	_bag.add(&"potion", 3)
	_bag.add(&"super_potion", 1)
	_bag.add(&"poke_ball", 5)
	_party = Party.new()
	var rng := GameRng.new(11)
	for spec: Array in [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10]]:
		_party.add(PokemonFactory.create(_data, spec[0], spec[1], rng))
	_party.get_at(0).hp = 5
	_party.get_at(2).hp = 0
	_previews.clear()
	_uses.clear()
	_favorites.clear()
	_sorts.clear()
	_targets.clear()
	_repeats = 0
	_categories.clear()


func _view(context: StringName = BagQuery.CONTEXT_FIELD, target: int = -1) -> BagView:
	return BagQuery.view(_bag, _items, context, BagQuery.Sort.RELEVANCE, &"heal", _party,
		target, _data)


func _screen_in(width: int, view: BagView) -> BagScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_bag(view)
	menu.open_animated()
	await wait_frames(3)
	var screen := menu.get_bag()
	screen.category_opened.connect(func(c: StringName) -> void: _categories.append(c))
	screen.item_previewed.connect(func(i: StringName) -> void: _previews.append(i))
	screen.use_requested.connect(func(i: StringName) -> void: _uses.append(i))
	screen.favorite_toggled.connect(func(i: StringName) -> void: _favorites.append(i))
	screen.sort_changed.connect(func(s: int) -> void: _sorts.append(s))
	screen.target_chosen.connect(func(i: StringName, n: int) -> void: _targets.append([i, n]))
	screen.repeat_requested.connect(func() -> void: _repeats += 1)
	return screen


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	return event


func _tap(tile: BagTile) -> void:
	var pos := tile.size * 0.5
	tile._gui_input(_mouse(true, pos))
	tile._gui_input(_mouse(false, pos))


func _picker_view(item: StringName = &"potion", selected: int = -1) -> PartyPickerView:
	return BagQuery.targets(_party, _bag, _items.get_item(item), BagQuery.CONTEXT_FIELD, _data,
		selected)


func test_opens_on_heal_with_first_card_previewed_and_nothing_used() -> void:
	var screen := await _screen_in(2340, _view())
	assert_eq(screen.get_open_category(), &"heal")
	assert_eq(screen.get_selected_id(), &"potion")
	assert_eq(screen.get_detail_name(), "Potion")
	assert_eq(screen.get_detail_quantity(), "×3")
	assert_true(_uses.is_empty() and _previews.is_empty(), "l'ouverture n'utilise rien")


func test_tap_previews_and_never_uses() -> void:
	var screen := await _screen_in(2340, _view())
	_tap(screen.get_card(&"super_potion"))
	assert_eq(screen.get_selected_id(), &"super_potion")
	assert_eq(_previews, [&"super_potion"])
	assert_true(_uses.is_empty(), "un toucher n'utilise rien")
	assert_true(_targets.is_empty())


func test_use_button_requests_use_once() -> void:
	var screen := await _screen_in(2340, _view())
	screen.get_action_button().pressed.emit()
	assert_eq(_uses, [&"potion"])
	assert_true(_targets.is_empty(), "UTILISER ne choisit aucun Pokémon")


func test_tab_tap_opens_category_once() -> void:
	var screen := await _screen_in(2340, _view())
	_tap(screen.get_tab(&"ball"))
	assert_eq(screen.get_open_category(), &"ball")
	assert_eq(_categories, [&"ball"])
	assert_eq(screen.get_action_button().text, "LANCER")
	_tap(screen.get_tab(&"ball"))
	assert_eq(_categories.size(), 1, "l'onglet déjà ouvert n'émet rien")


func test_empty_tab_is_absent() -> void:
	var screen := await _screen_in(2340, _view())
	assert_not_null(screen.get_tab(&"heal"))
	assert_null(screen.get_tab(&"field"), "aucun objet AVENTURE : pas d'onglet")
	assert_null(screen.get_tab(&"key"))
	assert_null(screen.get_tab(&"favorites"), "aucun favori : pas de rangée FAVORIS")


func test_battle_item_outside_battle_has_note_and_no_button() -> void:
	_bag.add(&"x_attack", 2)
	var screen := await _screen_in(2340, _view())
	_tap(screen.get_tab(&"battle"))
	assert_eq(screen.get_detail_note(), "Utilisable en combat")
	assert_false(screen.get_action_button().visible, "aucun bouton")
	screen.get_action_button().pressed.emit()
	assert_true(_uses.is_empty())


func test_ball_outside_battle_has_note_and_no_button() -> void:
	var screen := await _screen_in(2340, _view())
	_tap(screen.get_tab(&"ball"))
	assert_eq(screen.get_detail_note(), "Utilisable en combat")
	assert_false(screen.get_action_button().visible)


func test_long_press_toggles_favorite_without_preview() -> void:
	var screen := await _screen_in(2340, _view())
	var card := screen.get_card(&"super_potion")
	card._gui_input(_mouse(true, card.size * 0.5))
	card._process(UiTokens.LONG_PRESS + 0.05)
	card._gui_input(_mouse(false, card.size * 0.5))
	assert_eq(_favorites, [&"super_potion"])
	assert_true(_previews.is_empty(), "l'appui long n'est pas un toucher")


func test_favorites_tab_first_and_star_shown() -> void:
	_bag.set_favorite(&"potion", true)
	var screen := await _screen_in(2340, _view())
	assert_not_null(screen.get_tab(&"favorites"))
	assert_true(screen.get_card(&"potion").is_favorite_shown())
	assert_false(screen.get_card(&"super_potion").is_favorite_shown())
	assert_true(screen.is_favorite_pill_shown(), "FAVORI en texte et étoile")
	_tap(screen.get_tab(&"favorites"))
	assert_eq(screen.get_cards().size(), 1)


func test_sort_button_emits_next_sort() -> void:
	var screen := await _screen_in(2340, _view())
	assert_string_contains(screen.get_sort_button().text, "Pertinence")
	screen.get_sort_button().pressed.emit()
	assert_eq(_sorts, [BagQuery.Sort.NAME])


func test_show_bag_again_keeps_tab_and_item_without_replaying_entry() -> void:
	var screen := await _screen_in(2340, _view())
	_tap(screen.get_tab(&"ball"))
	_bag.add(&"poke_ball", 1)
	screen.show_bag(_view())
	assert_eq(screen.get_open_category(), &"ball", "l'onglet ouvert est gardé")
	assert_eq(screen.get_detail_quantity(), "×6", "la quantité est à jour")
	_tap(screen.get_tab(&"heal"))
	_tap(screen.get_card(&"super_potion"))
	screen.show_bag(_view())
	assert_eq(screen.get_selected_id(), &"super_potion", "l'objet aperçu est gardé")


func test_picker_shows_whole_team_with_reasons_and_no_target_for_incompatible() -> void:
	var screen := await _screen_in(2340, _view())
	screen.show_targets(_picker_view())
	await wait_frames(2)
	var picker := screen.get_picker()
	assert_true(screen.is_picker_open())
	assert_eq(picker.get_cards().size(), 3)
	assert_eq(picker.get_card(1).get_reason_text(), "PV déjà au maximum")
	assert_eq(picker.get_card(2).get_reason_text(), "Ce Pokémon est K.O.")
	assert_eq(picker.get_card(2).get_status_text(), "K.O.")
	_tap(picker.get_card(1))
	_tap(picker.get_card(2))
	assert_true(_targets.is_empty(), "aucun target_chosen pour un Pokémon incompatible")
	_tap(picker.get_card(0))
	assert_eq(_targets, [[&"potion", 0]])


func test_picker_cancel_and_go_back_close_without_signal() -> void:
	var screen := await _screen_in(2340, _view())
	screen.show_targets(_picker_view())
	await wait_frames(2)
	screen.get_picker().get_cancel_button().pressed.emit()
	await wait_frames(2)
	assert_false(screen.is_picker_open())
	assert_true(_targets.is_empty() and _uses.is_empty())
	screen.show_targets(_picker_view())
	await wait_frames(2)
	assert_true(screen.go_back(), "le retour referme le choix")
	assert_false(screen.is_picker_open())
	assert_false(screen.go_back(), "puis le retour suit son cours")


func test_result_and_repeat_emit_one_signal() -> void:
	var screen := await _screen_in(2340, _view())
	screen.show_result("+20 PV — Salamèche 25/39", true)
	var bar := screen.get_result_bar()
	assert_true(bar.visible)
	assert_eq(bar.get_text(), "+20 PV — Salamèche 25/39")
	assert_true(bar.is_repeat_shown())
	bar.get_repeat_button().pressed.emit()
	assert_eq(_repeats, 1)
	screen.show_result("+20 PV — Salamèche 39/39", false)
	assert_false(screen.get_result_bar().is_repeat_shown(), "plus d'exemplaire : pas de bouton")


func test_result_stays_until_next_gesture() -> void:
	var screen := await _screen_in(2340, _view())
	screen.show_result("+20 PV — Salamèche 25/39", true)
	screen.show_bag(_view())
	assert_true(screen.get_result_bar().visible, "une mise à jour de la vue ne la retire pas")
	_tap(screen.get_card(&"super_potion"))
	assert_false(screen.get_result_bar().visible, "un geste la retire")


func test_from_team_has_no_picker_and_names_pokemon() -> void:
	var screen := await _screen_in(2340, _view(BagQuery.CONTEXT_TEAM, 0))
	assert_eq(screen.get_caption_text(), "Pour Salamèche")
	screen.get_action_button().pressed.emit()
	assert_eq(_uses, [&"potion"])
	assert_false(screen.is_picker_open())


func test_from_team_full_hp_target_shows_reason_not_button() -> void:
	var screen := await _screen_in(2340, _view(BagQuery.CONTEXT_TEAM, 1))
	assert_eq(screen.get_detail_note(), "PV déjà au maximum")
	assert_false(screen.get_action_button().visible)


func test_empty_bag_says_so() -> void:
	_bag.clear()
	var screen := await _screen_in(2340, _view())
	assert_true(screen.get_empty_label().visible)
	assert_eq(screen.get_empty_label().text, "Ton Sac est vide.")
	assert_false(screen.is_detail_shown())
	assert_eq(screen.get_tabs().size(), 0)


func _interactive(node: Node, found: Array[Control]) -> void:
	var control := node as Control
	if control != null and control.is_visible_in_tree() and (control is BaseButton
			or control is BagTile) and control.get_global_rect().size.x > 0.0:
		found.append(control)
	for child: Node in node.get_children():
		_interactive(child, found)


func test_touch_targets_and_safe_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _view())
		screen.show_result("+20 PV — Salamèche 25/39", true)
		await wait_frames(2)
		var found: Array[Control] = []
		_interactive(screen, found)
		assert_gt(found.size(), 5, "des éléments interactifs à %d" % width)
		for control: Control in found:
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, UiTokens.TOUCH_MIN - 0.5,
				"%s ≥ TOUCH_MIN à %d" % [control.name, width])
			assert_gte(rect.position.x, UiTokens.SAFE_MARGIN - 0.5, "marge gauche %d" % width)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN + 0.5, "marge droite %d" % width)
			assert_gte(rect.position.y, UiTokens.SAFE_MARGIN - 0.5)
			assert_lte(rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5, "marge basse")


func test_picker_touch_targets_and_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _view())
		screen.show_targets(_picker_view())
		await wait_frames(3)
		var found: Array[Control] = []
		_interactive(screen.get_picker(), found)
		assert_eq(found.size(), 4, "trois cartes et ANNULER")
		for control: Control in found:
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, UiTokens.TOUCH_MIN - 0.5)
			assert_gte(rect.position.x, UiTokens.SAFE_MARGIN - 0.5)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN + 0.5)
			assert_lte(rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5)
