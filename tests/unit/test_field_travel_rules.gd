extends GutTest
## Téléport et Tunnel hors combat (passe systèmes 2, `systemes-2.md` §3.6 T25b) :
## [FieldTravelRules] (pur) et les capacités sans CS de [FieldMoves] (`"hm": ""` : il faut
## connaître la capacité), sans rien changer à Coupe, Flash, Surf, Force et Vol.

const READY := FieldMoves.State.READY
const Check := FieldTravelRules.Check

var _rules: FieldMoves
var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_rules = FieldMoves.new()
	assert_true(_rules.load_file(), "\n".join(_rules.get_errors()))
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func _pokemon(species: StringName, level: int, move: StringName = &"") -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(3))
	if move != &"" and not pokemon.knows_move(move):
		assert_true(pokemon.replace_move(0, move, _data))
	return pokemon


func _exit() -> CaveExit:
	var exit := CaveExit.new()
	exit.map = &"route_3"
	exit.spawn = &"from_mt_moon_w"
	return exit


# --- FieldTravelRules ------------------------------------------------------------------

func test_teleport_outdoors_and_in_a_cave_but_not_indoors() -> void:
	assert_eq(FieldTravelRules.check_teleport(READY, MapTraits.new(false), &"pewter_center"),
		Check.OK, "extérieur ou grotte (une grotte n'est pas un intérieur)")
	assert_eq(FieldTravelRules.check_teleport(READY, MapTraits.new(true), &"pewter_center"),
		Check.NOT_HERE, "intérieur [D]")
	var park := MapTraits.new(false)
	park.no_teleport = true
	assert_eq(FieldTravelRules.check_teleport(READY, park, &"pewter_center"), Check.NOT_HERE,
		"carte interdite (Parc Safari, J23)")
	assert_eq(FieldTravelRules.check_teleport(READY, MapTraits.new(false), &""), Check.NOT_HERE,
		"aucun point de soin")


func test_teleport_needs_a_pokemon_and_a_free_player() -> void:
	var outdoors := MapTraits.new(false)
	assert_eq(FieldTravelRules.check_teleport(FieldMoves.State.NO_POKEMON, outdoors,
		&"pewter_center"), Check.NO_POKEMON)
	assert_eq(FieldTravelRules.check_teleport(READY, outdoors, &"pewter_center", true),
		Check.BUSY, "occupé d'abord")


func test_dig_only_with_a_cave_exit() -> void:
	assert_eq(FieldTravelRules.check_dig(READY, _exit()), Check.OK)
	assert_eq(FieldTravelRules.check_dig(READY, null), Check.NOT_HERE, "hors grotte")
	assert_eq(FieldTravelRules.check_dig(FieldMoves.State.NO_POKEMON, _exit()),
		Check.NO_POKEMON)
	assert_eq(FieldTravelRules.check_dig(READY, _exit(), true), Check.BUSY)


func test_travel_moves() -> void:
	assert_true(FieldTravelRules.is_travel_move(&"teleport"))
	assert_true(FieldTravelRules.is_travel_move(&"dig"))
	assert_false(FieldTravelRules.is_travel_move(&"fly"))
	assert_false(FieldTravelRules.is_travel_move(&"cut"))


# --- FieldMoves : capacités sans CS ----------------------------------------------------

func test_teleport_and_dig_have_no_hm() -> void:
	for move: StringName in FieldTravelRules.MOVES:
		assert_true(_rules.has_move(move), move)
		assert_false(_rules.needs_hm(move), move)
	for move: StringName in [&"cut", &"flash", &"surf", &"strength", &"fly"]:
		assert_true(_rules.needs_hm(move), "%s garde sa CS" % move)


func test_a_move_without_hm_must_be_known() -> void:
	var party := Party.new()
	party.add(_pokemon(&"charmander", 12))
	var r := _rules.check(&"teleport", party, Bag.new(), StoryFlags.new(), _items, _data)
	assert_eq(r.state, FieldMoves.State.NO_POKEMON, "sans CS, jamais NO_HM")
	party.add(_pokemon(&"abra", 15, &"teleport"))
	r = _rules.check(&"teleport", party, Bag.new(), StoryFlags.new(), _items, _data)
	assert_eq(r.state, READY)
	assert_eq(r.pokemon_index, 1)
	assert_eq(r.pokemon_name, "Abra")
	assert_eq(r.key(&"teleport"), "teleport:ready")


func test_known_move_prefers_the_companion() -> void:
	var party := Party.new()
	party.add(_pokemon(&"diglett", 18, &"dig"))
	var second := _pokemon(&"diglett", 20, &"dig")
	party.add(second)
	var r := _rules.check(&"dig", party, null, null, _items, _data, second)
	assert_eq(r.state, READY)
	assert_eq(r.pokemon_index, 1)


func test_hm_moves_unchanged() -> void:
	var party := Party.new()
	party.add(_pokemon(&"charmander", 12))
	var r := _rules.check(&"cut", party, Bag.new(), StoryFlags.new(), _items, _data)
	assert_eq(r.state, FieldMoves.State.NO_HM, "Coupe : la CS reste exigée")


func test_rules_accept_an_empty_hm() -> void:
	var rules := FieldMoves.new()
	assert_true(rules.add_from_dict({"dig": {"hm": "", "badge": ""}}, "test"))
	assert_false(rules.needs_hm(&"dig"))
	assert_false(rules.add_from_dict({"dig": {"badge": ""}}, "test"), "« hm » reste exigé")
	assert_push_error_count(1)
