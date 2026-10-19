extends GutTest
## Données du jalon 23 (dossier 26 §7, §9.1 ; plan `jalon-23.md` §2.7, §2.10, T6) :
## `data/pokemon/moves/j23.json` et `data/items/items_j23.json`. Toxik et la CT06 viennent avec
## le poison grave (T18).

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func _move(id: StringName) -> MoveData:
	assert_true(_data.has_move(id), "%s existe" % id)
	return _data.get_move(id)


func test_surf_and_strength_follow_red_blue() -> void:
	var surf := _move(&"surf")
	assert_eq([surf.type, surf.power, surf.accuracy, surf.pp], [&"water", 95, 100, 15])
	var strength := _move(&"strength")
	assert_eq([strength.type, strength.power, strength.accuracy, strength.pp],
		[&"normal", 80, 100, 15])


func test_egg_bomb_and_double_team_follow_red_blue() -> void:
	var egg := _move(&"egg_bomb")
	assert_eq([egg.type, egg.power, egg.accuracy, egg.pp], [&"normal", 100, 75, 10])
	var team := _move(&"double_team")
	assert_eq(team.pp, 15)
	assert_eq(team.effects.size(), 1, "Esquive +1 sur soi")
	assert_eq(team.pending_effects.size(), 0, "aucun effet en attente")


func test_hm03_and_hm04_teach_surf_and_strength() -> void:
	assert_eq(_items.get_hm(3), &"hm03")
	assert_eq(_items.get_hm(4), &"hm04")
	assert_eq(_items.get_item(&"hm03").teaches, &"surf")
	assert_eq(_items.get_item(&"hm04").teaches, &"strength")
	assert_eq([_data.hm_move(3), _data.hm_move(4)], [&"surf", &"strength"],
		"même table que tm_compatibility.json")
	for id: StringName in [&"hm03", &"hm04"]:
		assert_true(_items.get_item(id).is_permanent(), "%s jamais consommée" % id)
		assert_false(_items.get_item(id).is_sellable(), "%s invendable" % id)


func test_tm32_and_tm37() -> void:
	assert_eq(_items.get_tm(32), &"tm32")
	assert_eq(_items.get_tm(37), &"tm37")
	assert_eq(_items.get_item(&"tm32").teaches, &"double_team")
	assert_eq(_items.get_item(&"tm37").teaches, &"egg_bomb")


func test_gold_teeth_is_a_key_item() -> void:
	var teeth := _items.get_item(&"gold_teeth")
	assert_not_null(teeth)
	assert_true(teeth.is_key())
	assert_false(teeth.is_sellable(), "objet clé invendable")


func test_compatibilities_match_red_blue_examples() -> void:
	assert_true(_data.can_learn_hm(&"squirtle", 3), "Carapuce apprend Surf")
	assert_true(_data.can_learn_hm(&"squirtle", 4), "Carapuce apprend Force")
	assert_false(_data.can_learn_hm(&"pidgey", 3), "Roucool n'apprend pas Surf")
	assert_true(_data.can_learn_hm(&"machop", 4), "Machoc apprend Force")
