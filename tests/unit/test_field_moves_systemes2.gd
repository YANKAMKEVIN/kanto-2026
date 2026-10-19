extends GutTest
## Entrées `surf`, `strength`, `fly` de `data/world/field_moves.json` (passe systèmes 2, T3b ;
## `systemes-2.md` §2.5, §2.8) : CS03 + Badge Âme, CS04 + Badge Prisme (valeurs du J23 §2.10),
## CS02 + Badge Foudre (Q-3). Tant que la CS n'est pas en données, l'état reste NO_HM.

var _rules: FieldMoves


func before_all() -> void:
	_rules = FieldMoves.new()
	assert_true(_rules.load_file(), "\n".join(_rules.get_errors()))


func test_hm_of_each_move() -> void:
	assert_eq(_rules.hm_of(&"surf"), &"hm03")
	assert_eq(_rules.hm_of(&"strength"), &"hm04")
	assert_eq(_rules.hm_of(&"fly"), &"hm02")


func test_existing_moves_unchanged() -> void:
	assert_eq(_rules.hm_of(&"cut"), &"hm01")
	assert_eq(_rules.hm_of(&"flash"), &"hm05")


func test_badge_of_each_move_is_checked() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "\n".join(data.get_errors()))
	var items := ItemLibrary.new()
	assert_true(items.load_dir(), "\n".join(items.get_errors()))
	var party := Party.new()
	party.add(PokemonFactory.create(data, &"pidgey", 20, GameRng.new(3)))
	for move: StringName in [&"surf", &"strength", &"fly"]:
		var bag := Bag.new()
		bag.add(_rules.hm_of(move))
		var r := _rules.check(move, party, bag, StoryFlags.new(), items, data)
		if items.get_item(_rules.hm_of(move)) == null:
			assert_eq(r.state, FieldMoves.State.NO_HM, "%s : CS pas encore en données" % move)
		else:
			assert_eq(r.state, FieldMoves.State.NO_BADGE, "%s : badge exigé" % move)
