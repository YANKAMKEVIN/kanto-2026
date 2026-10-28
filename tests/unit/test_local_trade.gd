extends GutTest
## LocalTrade (jalon 32, T4 ; `jalon-32.md` §1.2) : terminal d'échange local, logique pure.
## Individu identique, équipe pleine sans perte, original intact tant que l'échange n'est pas
## fini, Pokémon incompatible refusé.

const S := LocalTrade.Status

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _create(species: StringName, level: int, seed: int = 1) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(seed))
	pokemon.ensure_uid()
	return pokemon


func _party(species: Array[StringName]) -> Party:
	var party := Party.new()
	for i: int in species.size():
		party.add(_create(species[i], 30, i + 1))
	return party


func test_trade_target_follows_the_trade_rule_only() -> void:
	assert_eq(LocalTrade.trade_target(_create(&"graveler", 30), _data), &"golem")
	assert_eq(LocalTrade.trade_target(_create(&"geodude", 30), _data), &"",
		"Racaillou évolue par niveau, pas par échange")
	assert_eq(LocalTrade.trade_target(_create(&"golem", 40), _data), &"", "forme finale")
	assert_eq(LocalTrade.trade_target(null, _data), &"")


func test_candidates_are_the_compatible_members_in_order() -> void:
	var party := _party([&"pikachu", &"graveler", &"geodude", &"graveler"])
	assert_eq(LocalTrade.candidates(party, _data), [1, 3] as Array[int])


func test_the_same_individual_comes_back_evolved() -> void:
	var party := _party([&"pikachu", &"graveler"])
	var before := party.get_at(1)
	before.nickname = "Caillou"
	before.status = StatusRules.POISON
	before.evs[&"atk"] = 12
	before.moves[0].pp = 1
	before.favorite = true
	before.take_damage(5)
	var lost := before.max_hp() - before.hp
	var snapshot := before.to_dict()
	var pokedex := Pokedex.new()
	var result := LocalTrade.execute(party, 1, _data, pokedex, &"pewter_center", "2026-10-25")
	assert_eq(result["status"], S.DONE)
	assert_eq(result["from"], &"graveler")
	assert_eq(result["into"], &"golem")
	var after := party.get_at(1)
	assert_eq(result["pokemon"], after)
	assert_eq(after.species_id, &"golem")
	assert_eq(party.size(), 2)
	var expected := snapshot.duplicate(true)
	var got := after.to_dict()
	for key: String in ["nickname", "level", "gender", "exp", "ivs", "evs", "moves", "met",
			"favorite", "status", "status_turns", "uid"]:
		assert_eq(got[key], expected[key], key)
	assert_eq(after.max_hp() - after.hp, lost, "PV perdus gardés")
	assert_true(pokedex.is_seen(&"golem") and pokedex.is_caught(&"golem"))


func test_the_original_object_is_untouched_until_the_swap() -> void:
	var party := _party([&"graveler"])
	var original := party.get_at(0)
	var snapshot := original.to_dict()
	LocalTrade.execute(party, 0, _data)
	assert_eq(original.to_dict(), snapshot, "évolution faite sur la copie de travail")
	assert_ne(party.get_at(0), original)


func test_a_full_party_loses_nobody_and_keeps_the_order() -> void:
	var party := _party([&"pikachu", &"geodude", &"graveler", &"rattata", &"pidgey", &"spearow"])
	var uids: Array[String] = []
	for pokemon: Pokemon in party.get_all():
		uids.append(pokemon.uid)
	var result := LocalTrade.execute(party, 2, _data)
	assert_eq(result["status"], S.DONE)
	assert_eq(party.size(), 6)
	for i: int in 6:
		assert_eq(party.get_at(i).uid, uids[i], "place %d" % i)
	assert_eq(party.get_at(2).species_id, &"golem")


func test_an_incompatible_pokemon_is_refused_and_nothing_changes() -> void:
	var party := _party([&"pikachu", &"graveler"])
	var before := party.to_array()
	var pokedex := Pokedex.new()
	var result := LocalTrade.execute(party, 0, _data, pokedex)
	assert_eq(result["status"], S.INCOMPATIBLE)
	assert_eq(party.to_array(), before)
	assert_false(pokedex.is_seen(&"golem"))


func test_invalid_index_changes_nothing() -> void:
	var party := _party([&"graveler"])
	var before := party.to_array()
	for index: int in [-1, 1, 6]:
		assert_eq(LocalTrade.execute(party, index, _data)["status"], S.INVALID, str(index))
	assert_eq(party.to_array(), before)


func test_the_companion_keeps_its_identity_and_is_flagged() -> void:
	var party := _party([&"graveler"])
	var uid := party.get_at(0).uid
	var result := LocalTrade.execute(party, 0, _data, null, &"", "", uid)
	assert_true(result["companion_evolved"])
	assert_eq(party.get_at(0).uid, uid)


func test_picker_lists_the_whole_party_with_reasons() -> void:
	var party := _party([&"pikachu", &"graveler"])
	var view := LocalTrade.picker_view(party, _data)
	assert_eq(view.title, LocalTrade.PICK_TEXT)
	assert_eq(view.targets.size(), 2)
