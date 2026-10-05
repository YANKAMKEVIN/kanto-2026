extends GutTest
## Party : équipe de 6 au maximum, tête, premier valide, soin, sauvegarde.

var _data: PokemonData
var _rng: GameRng
var _party: Party


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(7)
	_party = Party.new()


func _make(species: StringName = &"charmander") -> Pokemon:
	return PokemonFactory.create(_data, species, 5, _rng)


func test_empty_party() -> void:
	assert_eq(_party.size(), 0)
	assert_null(_party.get_lead())
	assert_null(_party.first_able())
	assert_false(_party.has_able())
	assert_null(_party.get_at(0))


func test_add_up_to_six() -> void:
	for i: int in Party.MAX_SIZE:
		assert_true(_party.add(_make()))
	assert_true(_party.is_full())
	assert_false(_party.add(_make()), "équipe pleine")
	assert_false(Party.new().add(null))
	assert_eq(_party.size(), 6)


func test_lead_and_first_able() -> void:
	var first := _make(&"bulbasaur")
	var second := _make(&"squirtle")
	_party.add(first)
	_party.add(second)
	assert_eq(_party.get_lead(), first)
	assert_eq(_party.get_at(1), second)
	first.take_damage(999)
	assert_eq(_party.first_able(), second)
	second.take_damage(999)
	assert_false(_party.has_able())
	_party.heal_all()
	assert_eq(_party.first_able(), first)
	assert_eq(second.hp, second.max_hp())


func test_index_of_uses_identity_not_species() -> void:
	var first := _make(&"bulbasaur")
	var twin := _make(&"bulbasaur")
	_party.add(first)
	_party.add(twin)
	assert_eq(_party.index_of(first), 0)
	assert_eq(_party.index_of(twin), 1, "même espèce : la place, pas l'espèce")
	assert_eq(_party.index_of(_make(&"bulbasaur")), -1, "absent")
	assert_eq(_party.index_of(null), -1)


func test_get_all_is_a_copy() -> void:
	_party.add(_make())
	_party.get_all().clear()
	assert_eq(_party.size(), 1)
	_party.clear()
	assert_eq(_party.size(), 0)


func test_round_trip() -> void:
	_party.add(_make(&"bulbasaur"))
	_party.add(_make(&"squirtle"))
	var saved := _party.to_array()
	var loaded := Party.new()
	assert_true(loaded.load_array(JSON.parse_string(JSON.stringify(saved)), _data))
	assert_eq(loaded.to_array(), saved)


func test_invalid_entries_are_skipped() -> void:
	var saved: Array = [_make().to_dict(), {"species": "missingno"}, 42]
	assert_false(_party.load_array(saved, _data))
	assert_push_error_count(3)
	assert_eq(_party.size(), 1)


# --- Réordonner (jalon 6A, jalon-06.md §3.3) ---------------------------------------------

func _three() -> Array[Pokemon]:
	var members: Array[Pokemon] = [_make(&"charmander"), _make(&"pidgey"), _make(&"rattata")]
	for pokemon: Pokemon in members:
		_party.add(pokemon)
	return members


func test_swap_exchanges_two_places_and_changes_the_lead() -> void:
	var m := _three()
	assert_true(_party.swap(0, 2))
	assert_eq(_party.get_all(), [m[2], m[1], m[0]] as Array[Pokemon])
	assert_eq(_party.get_lead(), m[2], "le premier de la liste est le Pokémon de tête")
	assert_true(_party.swap(2, 1), "l'ordre des arguments est indifférent")
	assert_eq(_party.get_all(), [m[2], m[0], m[1]] as Array[Pokemon])


func test_swap_refuses_bad_places_without_change() -> void:
	var m := _three()
	for pair: Vector2i in [Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, 3), Vector2i(5, 0)]:
		assert_false(_party.swap(pair.x, pair.y), "refusé : %s" % pair)
	assert_eq(_party.get_all(), m, "rien n'a bougé")


func test_move_inserts_and_shifts_the_others() -> void:
	var m := _three()
	assert_true(_party.move(2, 0))
	assert_eq(_party.get_all(), [m[2], m[0], m[1]] as Array[Pokemon])
	assert_true(_party.move(0, 2))
	assert_eq(_party.get_all(), m, "aller-retour")
	assert_true(_party.move(0, 1))
	assert_eq(_party.get_all(), [m[1], m[0], m[2]] as Array[Pokemon])


func test_move_refuses_bad_places_without_change() -> void:
	var m := _three()
	for pair: Vector2i in [Vector2i(2, 2), Vector2i(-1, 0), Vector2i(0, 3), Vector2i(3, 0)]:
		assert_false(_party.move(pair.x, pair.y), "refusé : %s" % pair)
	assert_eq(_party.get_all(), m)


func test_new_order_survives_the_save() -> void:
	var m := _three()
	m[2].favorite = true
	_party.swap(0, 2)
	var loaded := Party.new()
	assert_true(loaded.load_array(JSON.parse_string(JSON.stringify(_party.to_array())), _data))
	assert_eq(loaded.get_lead().species_id, &"rattata")
	assert_true(loaded.get_lead().favorite, "le favori suit son Pokémon")
	assert_eq(loaded.get_at(2).species_id, &"charmander")


func test_remove_at_returns_the_same_instance_and_shifts_the_others() -> void:
	var first := _make(&"charmander")
	var second := _make(&"pidgey")
	var third := _make(&"rattata")
	_party.add(first)
	_party.add(second)
	_party.add(third)
	second.take_damage(3)
	var hp := second.hp
	assert_same(_party.remove_at(1), second)
	assert_eq(second.hp, hp, "même instance, PV gardés")
	assert_eq(_party.get_all(), [first, third] as Array[Pokemon])
	assert_null(_party.remove_at(2))
	assert_null(_party.remove_at(-1))
	assert_eq(_party.size(), 2)
