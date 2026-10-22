extends GutTest
## Données Pokémon du jalon 27 (T3) : M. Mime, Kicklee, Tygnon, Vague Psy (CT46).

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_data_loads_without_error() -> void:
	assert_eq(_data.get_errors().size(), 0, "\n".join(_data.get_errors()))


func test_species_and_types() -> void:
	var expected := {
		&"mr_mime": [122, [&"psychic", &"fairy"]],
		&"hitmonlee": [106, [&"fighting"]],
		&"hitmonchan": [107, [&"fighting"]],
	}
	for id: StringName in expected:
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		var types: Array[StringName] = []
		types.assign(expected[id][1])
		assert_eq([species.dex, species.types], [expected[id][0], types], String(id))
	assert_eq(_data.get_species(&"hitmonlee").male_ratio, 1.0)
	assert_eq(_data.get_species(&"hitmonchan").male_ratio, 1.0)


func test_psywave() -> void:
	var move := _data.get_move(&"psywave")
	assert_not_null(move)
	assert_eq([move.type, move.accuracy, move.pp], [&"psychic", 80, 15])
	var fixed := move.effect_of(MoveEffect.Kind.FIXED_DAMAGE)
	assert_not_null(fixed)
	assert_eq(fixed.mode, &"psywave")


func test_tm46_teaches_psywave() -> void:
	var tm := _items.get_item(&"tm46")
	assert_not_null(tm)
	assert_eq([tm.tm_number, tm.teaches], [46, &"psywave"])
	assert_true(_data.can_learn_tm(&"mr_mime", 46))


func test_borrowed_species_exist() -> void:
	for id: StringName in [&"venomoth", &"machoke", &"slowpoke", &"slowbro"]:
		assert_true(_data.has_species(id), String(id))


func test_hitmons_can_be_created_at_level_30() -> void:
	for id: StringName in [&"hitmonlee", &"hitmonchan"]:
		var mon := PokemonFactory.create(_data, id, 30, GameRng.new(7))
		assert_not_null(mon, String(id))
		assert_eq(mon.level, 30)
		assert_gt(mon.moves.size(), 0)
		assert_eq(mon.gender, Pokemon.Gender.MALE)
