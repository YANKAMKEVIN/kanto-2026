extends GutTest
## TrainerSlot.moves : capacités choisies à la main pour un Pokémon de Dresseur (jalon 10
## §2.4, dossier 12 §2). Fichier séparé de test_trainer_library.gd (modifié par le J9).

var _data: PokemonData
var _fixture_data: PokemonData
var _library: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_fixture_data = PokemonData.new()
	_fixture_data.load_dir("res://tests/fixtures/pokemon/valid/")


func before_each() -> void:
	_library = TrainerLibrary.new(_fixture_data)


func _entry(slot: Dictionary) -> Dictionary:
	return {
		"name": "Test", "ai": "smart", "can_lose": false, "heal_after": false,
		"gives_exp": true, "prize_money": 10, "team": [slot],
	}


func _add(slot: Dictionary) -> bool:
	return _library.add_from_dict({ "t": _entry(slot) }, "test")


func _move_ids(pokemon: Pokemon) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: MoveSlot in pokemon.moves:
		ids.append(slot.move_id)
	return ids


# --- Lecture ----------------------------------------------------------------------------

func test_moves_are_read_in_order() -> void:
	assert_true(_add({ "species": "sprout", "level": 5, "moves": ["lick", "ember", "tackle"] }))
	var slot := _library.get_trainer(&"t").team[0]
	assert_eq(slot.moves, [&"lick", &"ember", &"tackle"] as Array[StringName])
	assert_eq(typeof(slot.moves[0]), TYPE_STRING_NAME)


func test_without_moves_the_slot_has_none() -> void:
	assert_true(_add({ "species": "sprout", "level": 5 }))
	assert_true(_library.get_trainer(&"t").team[0].moves.is_empty())


func test_four_moves_are_accepted_without_learnset_check() -> void:
	# Aucune de ces capacités n'est apprise par Pousse au Nv. 2 : c'est voulu.
	assert_true(_add({ "species": "sprout", "level": 2,
		"moves": ["lick", "bubble", "ember", "razor_leaf"] }))
	assert_eq(_library.get_errors().size(), 0)


# --- Refus ------------------------------------------------------------------------------

func test_unknown_move_is_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "moves": ["tackle", "hyper_beam"] }))
	assert_push_error("capacité inconnue « hyper_beam »")
	assert_false(_library.has_trainer(&"t"))


func test_duplicate_move_is_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "moves": ["tackle", "tackle"] }))
	assert_push_error("capacité en double « tackle »")


func test_five_moves_are_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5,
		"moves": ["tackle", "growl", "ember", "bubble", "lick"] }))
	assert_push_error("« moves » doit être une liste de 1 à 4 capacités")


func test_empty_list_is_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "moves": [] }))
	assert_push_error("« moves » doit être une liste de 1 à 4 capacités")


func test_not_an_array_is_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "moves": "tackle" }))
	assert_push_error("« moves » doit être une liste de 1 à 4 capacités")


func test_non_text_entry_is_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "moves": ["tackle", 3] }))
	assert_push_error("« moves » ne contient que des identifiants")


func test_other_slot_keys_are_still_refused() -> void:
	assert_false(_add({ "species": "sprout", "level": 5, "item": "potion" }))
	assert_push_error("clé inconnue « item »")


func test_moves_in_team_by_starter_are_checked_too() -> void:
	var entry := _entry({})
	entry.erase("team")
	entry["team_by_starter"] = {
		"sprout": [{ "species": "wisp", "level": 5, "moves": ["nope"] }],
	}
	assert_false(_library.add_from_dict({ "t": entry }, "test"))
	assert_push_error("capacité inconnue « nope »")


# --- Création de l'équipe ---------------------------------------------------------------

func test_build_team_uses_the_chosen_moves_with_full_pp() -> void:
	_add({ "species": "sprout", "level": 5, "moves": ["lick", "ember"] })
	var pokemon := _library.build_team(&"t", &"sprout", GameRng.new(4)).get_at(0)
	assert_eq(_move_ids(pokemon), [&"lick", &"ember"] as Array[StringName])
	for slot: MoveSlot in pokemon.moves:
		var full := _fixture_data.get_move(slot.move_id).pp
		assert_eq(slot.max_pp, full, String(slot.move_id))
		assert_eq(slot.pp, full, String(slot.move_id))


func test_without_moves_build_team_keeps_red_blue_moves() -> void:
	_add({ "species": "sprout", "level": 5 })
	var built := _library.build_team(&"t", &"sprout", GameRng.new(4)).get_at(0)
	var expected := PokemonFactory.create(_fixture_data, &"sprout", 5, GameRng.new(4))
	assert_eq(_move_ids(built), _move_ids(expected))
	assert_false(_move_ids(built).is_empty())


func test_same_seed_same_team_with_or_without_moves() -> void:
	_library.add_from_dict({
		"plain": _entry({ "species": "sprout", "level": 5 }),
		"chosen": _entry({ "species": "sprout", "level": 5, "moves": ["lick"] }),
	}, "test")
	var plain := _library.build_team(&"plain", &"sprout", GameRng.new(21)).get_at(0)
	var chosen := _library.build_team(&"chosen", &"sprout", GameRng.new(21)).get_at(0)
	assert_eq(chosen.ivs, plain.ivs, "aucun tirage en plus : mêmes IV")
	assert_eq(chosen.gender, plain.gender, "aucun tirage en plus : même sexe")
	assert_eq(chosen.max_hp(), plain.max_hp())
	assert_eq(_move_ids(chosen), [&"lick"] as Array[StringName])


func test_rng_after_build_is_unchanged_by_moves() -> void:
	_library.add_from_dict({
		"plain": { "name": "A", "ai": "random", "can_lose": false, "heal_after": false,
			"gives_exp": true, "prize_money": 0, "team": [
				{ "species": "sprout", "level": 5 }, { "species": "wisp", "level": 6 }] },
		"chosen": { "name": "B", "ai": "random", "can_lose": false, "heal_after": false,
			"gives_exp": true, "prize_money": 0, "team": [
				{ "species": "sprout", "level": 5, "moves": ["tackle"] },
				{ "species": "wisp", "level": 6 }] },
	}, "test")
	var plain := _library.build_team(&"plain", &"sprout", GameRng.new(9))
	var chosen := _library.build_team(&"chosen", &"sprout", GameRng.new(9))
	assert_eq(chosen.get_at(1).to_dict(), plain.get_at(1).to_dict(),
		"le Pokémon suivant est tiré pareil")


# --- Vraies données ---------------------------------------------------------------------

func test_real_trainers_still_load_and_rival_keeps_red_blue_moves() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir())
	assert_eq(library.get_errors().size(), 0)
	var rival := library.get_trainer(&"rival_lab")
	for starter: StringName in rival.team_by_starter:
		for slot: TrainerSlot in rival.team_for(starter):
			assert_true(slot.moves.is_empty(), "le rival n'a pas de capacités choisies")
