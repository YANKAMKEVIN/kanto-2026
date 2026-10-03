extends GutTest
## PartyPicker (jalon 6, T11) : toute l'équipe avec PV, raison visible d'un Pokémon incompatible,
## target_chosen seulement pour une cible utilisable, un seul signal par toucher, cible mise en
## avant (UTILISER À NOUVEAU), ANNULER, mise à jour sans rejouer l'entrée.

const PICKER_SCENE := preload("res://game/ui/bag/party_picker.tscn")

var _chosen: Array[int] = []
var _backs: int = 0


func _member(index: int, name: String, hp: int, max_hp: int) -> TeamMemberView:
	var member := TeamMemberView.new()
	member.party_index = index
	member.species_id = &"charmander"
	member.display_name = name
	member.level = 10
	member.hp = hp
	member.max_hp = max_hp
	member.status_text = TeamMemberView.STATUS_FAINTED if hp == 0 else ""
	return member


func _view(selected: int = -1) -> PartyPickerView:
	var view := PartyPickerView.new()
	view.item_id = &"potion"
	view.item_name = "Potion"
	view.quantity = 3
	view.selected = selected
	view.targets.append(PartyTargetView.new(_member(0, "Salamèche", 13, 39), true))
	view.targets.append(PartyTargetView.new(_member(1, "Roucool", 34, 34), false,
		"PV déjà au maximum"))
	view.targets.append(PartyTargetView.new(_member(2, "Rattata", 0, 26), false,
		"Ce Pokémon est K.O."))
	return view


func _picker() -> PartyPicker:
	var picker := PICKER_SCENE.instantiate() as PartyPicker
	picker.speed_scale = 0.0
	picker.haptics_enabled = false
	picker.size = Vector2(1200, 700)
	add_child_autofree(picker)
	picker.target_chosen.connect(func(i: int) -> void: _chosen.append(i))
	picker.back_requested.connect(func() -> void: _backs += 1)
	_chosen.clear()
	_backs = 0
	return picker


func _tap(card: BagTile) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = card.size * 0.5
		card._gui_input(event)


func test_shows_every_member_with_hp() -> void:
	var picker := _picker()
	picker.show_targets(_view())
	await wait_frames(2)
	assert_eq(picker.get_cards().size(), 3)
	assert_eq(picker.get_card(0).get_name_text(), "Salamèche")
	assert_eq(picker.get_card(0).get_hp_text(), "13 / 39")
	assert_string_contains(picker.get_title_text(), "Potion")
	assert_string_contains(picker.get_title_text(), "×3")


func test_incompatible_member_shows_reason_and_emits_nothing() -> void:
	var picker := _picker()
	picker.show_targets(_view())
	await wait_frames(2)
	assert_eq(picker.get_card(1).get_reason_text(), "PV déjà au maximum")
	assert_eq(picker.get_card(2).get_reason_text(), "Ce Pokémon est K.O.")
	assert_false(picker.get_card(1).is_chevron_shown())
	assert_eq(picker.get_card(0).get_reason_text(), "")
	_tap(picker.get_card(1))
	_tap(picker.get_card(2))
	assert_eq(_chosen, [])


func test_usable_member_emits_one_choice_per_touch() -> void:
	var picker := _picker()
	picker.show_targets(_view())
	await wait_frames(2)
	_tap(picker.get_card(0))
	assert_eq(_chosen, [0])


func test_selected_member_is_highlighted() -> void:
	var picker := _picker()
	picker.show_targets(_view(0))
	await wait_frames(2)
	assert_true(picker.get_card(0).is_selected())
	assert_false(picker.get_card(1).is_selected())


func test_refresh_updates_hp_without_replaying_entry() -> void:
	var picker := _picker()
	picker.show_targets(_view())
	await wait_frames(2)
	var view := _view(0)
	view.targets[0] = PartyTargetView.new(_member(0, "Salamèche", 33, 39), true)
	picker.show_targets(view)
	assert_eq(picker.get_card(0).get_hp_text(), "33 / 39")
	assert_true(picker.is_shown())
	assert_true(picker.get_card(0).is_selected())


func test_cancel_emits_one_back() -> void:
	var picker := _picker()
	picker.show_targets(_view())
	await wait_frames(2)
	picker.get_cancel_button().pressed.emit()
	assert_eq(_backs, 1)
	assert_eq(_chosen, [])


func test_cancel_does_nothing_when_closed() -> void:
	var picker := _picker()
	picker.cancel()
	assert_eq(_backs, 0)
