extends GutTest
## Capacités de terrain (jalon 16, T6 ; dossier 19 §7 et §0.5 n° 25 à 28, `jalon-16.md` §2.2) :
## ordre des vérifications (CS, badge, équipe), choix du Pokémon nommé (compagnon d'abord),
## Pokémon K.O. accepté, Pokémon qui connaît déjà Coupe.

var _data: PokemonData
var _items: ItemLibrary
var _rules: FieldMoves


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))
	_rules = FieldMoves.new()
	assert_true(_rules.load_file(), "\n".join(_rules.get_errors()))


func _party(species: Array[StringName]) -> Party:
	var party := Party.new()
	for id: StringName in species:
		party.add(PokemonFactory.create(_data, id, 20, GameRng.new(3)))
	return party


func _bag(with_hm: bool) -> Bag:
	var bag := Bag.new()
	if with_hm:
		bag.add(&"hm01")
	return bag


func _flags(badge: bool) -> StoryFlags:
	var flags := StoryFlags.new()
	if badge:
		flags.set_flag(&"badge_cascade")
	return flags


func test_rules_loaded() -> void:
	assert_true(_rules.has_move(&"cut"))
	assert_eq(_rules.hm_of(&"cut"), &"hm01")


func test_no_hm_first() -> void:
	var r := _rules.check(&"cut", _party([&"sandshrew"]), _bag(false), _flags(true), _items, _data)
	assert_eq(r.state, FieldMoves.State.NO_HM)
	assert_eq(r.key(&"cut"), "cut:no_hm")


func test_no_badge_wins_over_team() -> void:
	var r := _rules.check(&"cut", _party([&"squirtle", &"paras"]), _bag(true), _flags(false),
		_items, _data)
	assert_eq(r.state, FieldMoves.State.NO_BADGE, "ARB-01 prime")
	assert_eq(r.pokemon_index, 1, "nomme le compatible (Paras)")
	var none := _rules.check(&"cut", _party([&"squirtle", &"pikachu"]), _bag(true),
		_flags(false), _items, _data)
	assert_eq(none.state, FieldMoves.State.NO_BADGE, "sans badge ni compatible : ARB-01 aussi")
	assert_eq(none.pokemon_index, 0, "nomme le premier de l'équipe")


func test_no_pokemon() -> void:
	var r := _rules.check(&"cut", _party([&"squirtle", &"pikachu"]), _bag(true), _flags(true),
		_items, _data)
	assert_eq(r.state, FieldMoves.State.NO_POKEMON)
	assert_eq(r.key(&"cut"), "cut:no_pokemon")


func test_ready_picks_first_compatible_then_companion() -> void:
	var party := _party([&"squirtle", &"beedrill", &"sandshrew"])
	var r := _rules.check(&"cut", party, _bag(true), _flags(true), _items, _data)
	assert_eq([r.state, r.pokemon_index], [FieldMoves.State.READY, 1])
	var with_companion := _rules.check(&"cut", party, _bag(true), _flags(true), _items, _data,
		party.get_at(2))
	assert_eq(with_companion.pokemon_index, 2, "le compagnon compatible coupe")
	var squirtle_out := _rules.check(&"cut", party, _bag(true), _flags(true), _items, _data,
		party.get_at(0))
	assert_eq(squirtle_out.pokemon_index, 1, "compagnon incompatible : le premier compatible")


func test_fainted_and_known_move() -> void:
	var party := _party([&"squirtle", &"charmander"])
	party.get_at(1).hp = 0
	var r := _rules.check(&"cut", party, _bag(true), _flags(true), _items, _data)
	assert_eq([r.state, r.pokemon_index], [FieldMoves.State.READY, 1], "un K.O. peut couper")
	var unknown := _rules.check(&"surf", party, _bag(true), _flags(true), _items, _data)
	assert_eq(unknown.state, FieldMoves.State.NO_HM, "capacité sans règle")


func test_bad_rules_rejected() -> void:
	var rules := FieldMoves.new()
	assert_false(rules.add_from_dict({"cut": {"hm": 1}}, "test"))
	assert_false(rules.add_from_dict({"cut": {"hm": "hm01", "x": ""}}, "test"))
	assert_true(rules.add_from_dict({"cut": {"hm": "hm01"}}, "test"))
	assert_push_error_count(2)
