extends GutTest
## L'écran du choix des 6 (JOH0, JH-24 ; `jalon-joh0.md` §2.2) : une ligne par Pokémon de la
## réserve (Johto puis Kanto), sélection par défaut cochée, compteur « n / 6 », VALIDER permis
## seulement si le choix l'est, retour Android avalé, [method TeamReturnOverlay.pick] rend les
## identifiants dans l'ordre de touche.

var _data: PokemonData
var _overlay: TeamReturnOverlay


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_overlay = TeamReturnOverlay.new()
	_overlay.label_for = func(pokemon: Pokemon) -> String:
		return "%s N%d" % [pokemon.display_name(_data), pokemon.level]
	add_child_autofree(_overlay)


func _mon(species: StringName, level: int, hp: int = -1) -> Pokemon:
	var mon := PokemonFactory.create(_data, species, level, GameRng.new(level))
	mon.ensure_uid()
	if hp >= 0:
		mon.hp = hp
	return mon


func _selection() -> TeamReturnSelection:
	var johto: Array[Pokemon] = [_mon(&"squirtle", 14), _mon(&"rattata", 11)]
	var kanto: Array[Pokemon] = [_mon(&"charizard", 62), _mon(&"pidgeot", 58),
		_mon(&"raticate", 55, 0), _mon(&"nidoking", 57), _mon(&"alakazam", 60)]
	return TeamReturnSelection.new(johto, kanto)


func test_pick_shows_the_pool_with_the_default_six_and_returns_the_choice() -> void:
	var selection := _selection()
	var picked: Array = []
	var task := func() -> void:
		picked.append(await _overlay.pick(selection))
	task.call()
	await get_tree().process_frame
	assert_true(_overlay.is_open())
	var buttons := _overlay.get_buttons()
	assert_eq(buttons.size(), 7)
	assert_true(buttons[0].text.begins_with("Carapuce N14"), buttons[0].text)
	assert_true(buttons[0].text.ends_with("Johto"))
	assert_true(buttons[2].text.ends_with("Kanto"))
	for i: int in 6:
		assert_true(buttons[i].button_pressed, "coché par défaut : %d" % i)
	assert_false(buttons[6].button_pressed)
	assert_eq(_overlay.get_count_text(), "6 / 6")
	assert_false(_overlay.get_confirm_button().disabled)
	# Décocher Rattata puis cocher Alakazam : l'ordre de touche met Alakazam en dernier.
	buttons[1].button_pressed = false
	buttons[6].button_pressed = true
	assert_eq(_overlay.get_count_text(), "6 / 6")
	assert_true(_overlay.handle_back(), "retour avalé")
	assert_true(_overlay.is_open())
	_overlay.get_confirm_button().pressed.emit()
	await wait_until(func() -> bool: return not picked.is_empty(), 2.0)
	var pool := selection.get_pool()
	assert_eq(picked[0], [pool[0].uid, pool[2].uid, pool[3].uid, pool[4].uid, pool[5].uid,
		pool[6].uid] as Array[String])
	assert_false(_overlay.is_open())
	assert_false(_overlay.handle_back(), "fermé : rien à avaler")


func test_confirm_is_refused_with_nothing_or_only_a_fainted_one() -> void:
	var selection := _selection()
	var picked: Array = []
	var task := func() -> void:
		picked.append(await _overlay.pick(selection))
	task.call()
	await get_tree().process_frame
	var buttons := _overlay.get_buttons()
	for i: int in 6:
		buttons[i].button_pressed = false
	assert_eq(_overlay.get_count_text(), "0 / 6")
	assert_true(_overlay.get_confirm_button().disabled)
	_overlay.get_confirm_button().pressed.emit()
	await get_tree().process_frame
	assert_true(picked.is_empty(), "VALIDER refusé")
	buttons[4].button_pressed = true
	assert_true(_overlay.get_confirm_button().disabled, "le seul K.O. : refusé")
	buttons[2].button_pressed = true
	assert_false(_overlay.get_confirm_button().disabled)
	# Une 7e coche est refusée par la sélection : le bouton revient décoché.
	for i: int in [0, 1, 3, 5]:
		buttons[i].button_pressed = true
	assert_eq(_overlay.get_count_text(), "6 / 6")
	buttons[6].button_pressed = true
	assert_false(buttons[6].button_pressed, "plus de place")
	assert_eq(_overlay.get_count_text(), "6 / 6")
	_overlay.get_confirm_button().pressed.emit()
	await wait_until(func() -> bool: return not picked.is_empty(), 2.0)
	assert_eq((picked[0] as Array).size(), 6)
