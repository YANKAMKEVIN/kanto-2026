extends GutTest
## Apprendre une CT depuis le Sac, dans le vrai Boot (jalon 11, T12) : le directeur du menu
## demande l'apprentissage, Boot joue le déroulé partagé (bandeau « … apprend … ! », ou l'offre
## d'oubli et NE PAS APPRENDRE) sur le voile au-dessus du menu ; la CT reste au Sac.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_tm_learn_save.json"

var _boot: Boot


func before_each() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	add_child_autofree(_boot)
	await wait_process_frames(3)
	var data := _boot.get_pokemon_data()
	GameState.new_game(4)
	GameState.party.add(PokemonFactory.create(data, &"charmander", 10, GameRng.new(2)))
	GameState.bag.add(&"tm34", 1)
	_boot.get_battle_director().get_move_learn_prompt().speed_scale = 0.0


## Attend que le bandeau du voile attende un toucher, et renvoie sa phrase.
func _banner_line() -> String:
	var banner := _boot.get_tm_learn_overlay().get_message_banner()
	await wait_until(func() -> bool: return banner.is_waiting(), 5.0)
	return banner.get_text()


func test_a_free_slot_learns_patience_and_keeps_the_tm() -> void:
	var charmander: Pokemon = GameState.party.get_at(0)
	assert_lt(charmander.moves.size(), 4)
	assert_true(_boot.get_menu_director().use_item_on(&"tm34", 0))
	var overlay := _boot.get_tm_learn_overlay()
	assert_not_null(overlay)
	assert_true(overlay.is_open())
	assert_gt(overlay.layer, UiTokens.LAYER_MENU, "au-dessus du menu")
	assert_eq(await _banner_line(), "Salamèche apprend Patience !", "texte n° 43")
	overlay.get_message_banner().skip()
	await wait_until(func() -> bool: return not overlay.is_open(), 5.0)
	assert_true(charmander.knows_move(&"bide"))
	assert_eq(charmander.moves[charmander.move_index(&"bide")].pp, 10, "PP pleins")
	assert_eq(GameState.bag.count_of(&"tm34"), 1, "la CT n'est jamais consommée")
	assert_push_error_count(0)


func test_four_moves_offer_to_forget_and_keep_changes_nothing() -> void:
	var charmander: Pokemon = GameState.party.get_at(0)
	var data := _boot.get_pokemon_data()
	for move_id: StringName in [&"leer", &"tackle", &"growl", &"scratch", &"ember"]:
		if charmander.moves.size() < 4 and not charmander.knows_move(move_id):
			charmander.learn_move(move_id, data)
	assert_eq(charmander.moves.size(), 4)
	var before: Array[StringName] = []
	for slot: MoveSlot in charmander.moves:
		before.append(slot.move_id)
	assert_true(_boot.get_menu_director().use_item_on(&"tm34", 0))
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	await wait_until(func() -> bool: return prompt.get_forget_panel() != null \
		and prompt.get_forget_panel().is_visible_in_tree(), 5.0)
	var panel := prompt.get_forget_panel()
	assert_not_null(panel, "le panneau d'oubli s'ouvre au-dessus du menu")
	panel.skip_chosen.emit()
	assert_eq(await _banner_line(), "Salamèche n'apprend pas Patience.")
	var overlay := _boot.get_tm_learn_overlay()
	overlay.get_message_banner().skip()
	await wait_until(func() -> bool: return not overlay.is_open(), 5.0)
	var after: Array[StringName] = []
	for slot: MoveSlot in charmander.moves:
		after.append(slot.move_id)
	assert_eq(after, before, "GARDER / NE PAS APPRENDRE : rien ne change")
	assert_eq(GameState.bag.count_of(&"tm34"), 1)
	assert_push_error_count(0)
