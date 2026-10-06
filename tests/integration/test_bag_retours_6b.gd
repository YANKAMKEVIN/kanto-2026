extends GutTest
## Retours de Kevin sur le Sac (6B) : toucher un Pokémon inutilisable (tremblement, vibration,
## raison en style refus, rien de consommé), soin animé (barre, chiffre, éclat, puis résultat),
## en-tête avec le nom de la zone dans Équipe et Sac.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const PICKER_SCENE := preload("res://game/ui/bag/party_picker.tscn")

var _data: PokemonData
var _items: ItemLibrary
var _bag: Bag
var _party: Party
var _targets: Array = []
var _haptics: Array[int] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.add_from_dict({"potion": {"name": "Potion", "plural": "Potions", "feminine": true,
		"category": "heal", "description": "x.", "heal_amount": 20}}, "test")


func before_each() -> void:
	_bag = Bag.new()
	_bag.add(&"potion", 3)
	_party = Party.new()
	var rng := GameRng.new(11)
	for spec: Array in [[&"charmander", 14], [&"pidgey", 12], [&"rattata", 10]]:
		_party.add(PokemonFactory.create(_data, spec[0], spec[1], rng))
	_party.get_at(0).hp = 5
	_party.get_at(2).hp = 0
	_targets.clear()
	_haptics.clear()


func _view(selected: int = -1) -> PartyPickerView:
	return BagQuery.targets(_party, _bag, _items.get_item(&"potion"), BagQuery.CONTEXT_FIELD,
		_data, selected)


func _bag_view() -> BagView:
	return BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD, BagQuery.Sort.RELEVANCE,
		&"heal", _party, -1, _data)


func _tap(tile: BagTile) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = tile.size * 0.5
		tile._gui_input(event)


func _menu(speed: float) -> TrainerMenu:
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = speed
	add_child_autofree(menu)
	return menu


func _screen(speed: float) -> BagScreen:
	var menu := _menu(speed)
	menu.show_bag(_bag_view())
	menu.open_animated()
	await wait_frames(3)
	var screen := menu.get_bag()
	screen.get_picker().haptics_enabled = false
	screen.get_picker().haptic_played.connect(func(ms: int) -> void: _haptics.append(ms))
	screen.target_chosen.connect(func(i: StringName, n: int) -> void: _targets.append([i, n]))
	return screen


func _picker(speed: float) -> PartyPicker:
	var picker := PICKER_SCENE.instantiate() as PartyPicker
	picker.speed_scale = speed
	picker.haptics_enabled = false
	picker.size = Vector2(1200, 700)
	add_child_autofree(picker)
	return picker


func test_refusal_texts_name_the_pokemon() -> void:
	var view := _view()
	assert_eq(view.targets[1].refusal, "Roucool a déjà tous ses PV.")
	assert_eq(view.targets[2].refusal, "Rattata est K.O.")
	assert_eq(view.targets[0].refusal, "")


func test_refused_touch_shakes_vibrates_shows_reason_and_chooses_nothing() -> void:
	var screen := await _screen(1.0)
	screen.show_targets(_view())
	await wait_frames(2)
	var card := screen.get_picker().get_card(1)
	var base := card.position.x
	_tap(card)
	assert_true(card.is_shaking(), "la carte tremble")
	assert_true(_targets.is_empty(), "aucun target_chosen")
	assert_eq(_haptics, [UiTokens.HAPTIC_REFUSE_MS])
	var bar := screen.get_result_bar()
	assert_true(bar.visible)
	assert_eq(bar.get_text(), "Roucool a déjà tous ses PV.")
	assert_false(bar.is_repeat_shown())
	assert_eq(bar.theme_type_variation, &"ResultBarRefused", "style refus")
	assert_eq(_bag.count_of(&"potion"), 3, "rien n'est consommé")
	await get_tree().create_timer(UiTokens.PICKER_SHAKE_TIME + 0.15).timeout
	assert_false(card.is_shaking())
	assert_eq(card.position.x, base, "la carte revient à sa place")


func test_refused_in_battle_picker_writes_reason_in_title() -> void:
	var picker := _picker(0.0)
	picker.show_targets(_view())
	await wait_frames(2)
	var refused: Array = []
	picker.target_refused.connect(func(i: int, t: String) -> void: refused.append([i, t]))
	var chosen: Array[int] = []
	picker.target_chosen.connect(func(i: int) -> void: chosen.append(i))
	_tap(picker.get_card(2))
	assert_eq(refused, [[2, "Rattata est K.O."]])
	assert_eq(picker.get_title_text(), "Rattata est K.O.")
	assert_true(chosen.is_empty())


func test_heal_animates_bar_from_old_to_new_and_counts_the_number() -> void:
	var picker := _picker(1.0)
	picker.show_targets(_view())
	await wait_frames(2)
	var old_hp := _party.get_at(0).hp
	_party.get_at(0).hp = old_hp + 20
	# Temps simulé (TweenClock) : relevé à mi-HP_TWEEN exactement, quelle que soit la charge.
	var clock := TweenClock.new(get_tree())
	var finished: Array[bool] = [false]
	picker.heal_finished.connect(func() -> void: finished[0] = true, CONNECT_ONE_SHOT)
	picker.show_targets(_view(0))
	var card := picker.get_card(0)
	var bar := card.get_hp_bar()
	assert_true(picker.is_healing())
	assert_true(bar.is_animating())
	assert_eq(bar.get_shown_hp(), old_hp, "la barre part de l'ancienne valeur")
	assert_eq(card.get_hp_text(), "%d / 38" % old_hp)
	assert_gt(card.get_flash().modulate.a, 0.5, "éclat vert")
	clock.run_until(func() -> bool: return false, UiTokens.HP_TWEEN * 0.5)
	var mid := bar.get_shown_value()
	assert_true(mid > old_hp and mid < old_hp + 20, "en plein milieu : %s" % mid)
	clock.run_until(func() -> bool: return finished[0], 5.0)
	clock.release()
	assert_true(finished[0], "soin terminé")
	assert_eq(bar.get_shown_hp(), old_hp + 20)
	assert_eq(card.get_hp_text(), "%d / 38" % (old_hp + 20))
	assert_false(picker.is_healing())


func test_heal_completes_at_speed_zero_and_result_follows() -> void:
	var screen := await _screen(0.0)
	screen.show_targets(_view())
	await wait_frames(2)
	var mon := _party.get_at(0)
	var result := ItemUse.apply(_bag, _items.get_item(&"potion"), mon, BagQuery.CONTEXT_FIELD)
	screen.show_result(BagQuery.result_text(result, "Salamèche"), true)
	screen.show_targets(_view(0))
	await wait_frames(3)
	var card := screen.get_picker().get_card(0)
	assert_eq(card.get_hp_bar().get_shown_hp(), mon.hp)
	assert_eq(card.get_hp_text(), "%d / %d" % [mon.hp, _view().targets[0].member.max_hp])
	assert_false(card.is_healing())
	assert_true(screen.get_result_bar().visible, "le résultat apparaît après le soin")
	assert_true(screen.get_result_bar().get_text().begins_with("+"))


func test_result_waits_for_the_heal_animation() -> void:
	var screen := await _screen(1.0)
	screen.show_targets(_view())
	await wait_frames(2)
	var mon := _party.get_at(0)
	var result := ItemUse.apply(_bag, _items.get_item(&"potion"), mon, BagQuery.CONTEXT_FIELD)
	screen.show_result(BagQuery.result_text(result, "Salamèche"), true)
	screen.show_targets(_view(0))
	await wait_frames(2)
	assert_false(screen.get_result_bar().visible, "pas avant la fin de la barre")
	await screen.get_picker().heal_finished
	await wait_frames(2)
	assert_true(screen.get_result_bar().visible)


func test_header_pill_is_hidden_until_a_zone_is_named() -> void:
	var menu := _menu(0.0)
	await wait_frames(1)
	assert_false(menu.get_zone_pill().visible, "jamais l'icône seule")


func test_header_keeps_zone_name_in_team_and_bag() -> void:
	var menu := _menu(0.0)
	var dashboard := DashboardView.new()
	dashboard.zone_name = "Route 1"
	menu.show_dashboard(dashboard)
	menu.open_animated()
	menu.show_bag(_bag_view())
	await wait_frames(2)
	assert_eq(menu.get_zone_label().text, "Route 1")
	assert_true(menu.get_zone_pill().visible)
	var team := TeamView.new()
	menu.show_team(team, 0)
	await wait_frames(2)
	assert_eq(menu.get_zone_label().text, "Route 1")
	assert_true(menu.get_zone_pill().visible)
