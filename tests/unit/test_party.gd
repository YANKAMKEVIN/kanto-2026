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
