extends GutTest
## Panthéon (jalon 30 T6 ; `jalon-30.md` §2.4, §2.6, §5) : instantané immuable, une entrée par
## victoire, plafond de 50 (Q30-5 : on n'ajoute plus), sérialisation identique à la relecture.


func _mon(species: StringName, level: int, nickname: String = "", uid: String = "") -> Pokemon:
	var mon := Pokemon.new()
	mon.species_id = species
	mon.level = level
	mon.nickname = nickname
	mon.uid = uid if not uid.is_empty() else "uid-%s-%d" % [species, level]
	return mon


func _team() -> Array:
	return [_mon(&"charizard", 65, "Flamby", "a1"), _mon(&"lapras", 58), _mon(&"jolteon", 57)]


func _entry() -> Dictionary:
	return HallOfFame.snapshot(_team(), "Kevin", &"charmander", 4567.5, "2026-10-22T21:04:00")


func test_snapshot_keeps_species_nickname_level_uid_date() -> void:
	var entry := _entry()
	assert_eq(entry["player"], "Kevin")
	assert_eq(entry["starter"], "charmander")
	assert_eq(entry["date"], "2026-10-22T21:04:00")
	assert_eq(entry["play_time"], 4567.5)
	assert_eq((entry["team"] as Array).size(), 3)
	assert_eq(entry["team"][0], {"species": "charizard", "nickname": "Flamby", "level": 65,
		"uid": "a1"})


func test_snapshot_is_detached_from_the_party() -> void:
	var team := _team()
	var entry := HallOfFame.snapshot(team, "Kevin", &"charmander", 1.0, "d")
	(team[0] as Pokemon).level = 70
	(team[0] as Pokemon).nickname = "Autre"
	assert_eq(entry["team"][0]["level"], 65)
	assert_eq(entry["team"][0]["nickname"], "Flamby")


func test_snapshot_ignores_non_pokemon_and_caps_at_six() -> void:
	var team: Array = [null, "x"]
	for i: int in 8:
		team.append(_mon(&"pidgeot", 50 + i))
	var entry := HallOfFame.snapshot(team, "K", &"squirtle", -3.0, "d")
	assert_eq((entry["team"] as Array).size(), 6)
	assert_eq(entry["play_time"], 0.0)


func test_each_victory_adds_an_entry() -> void:
	var hof := HallOfFame.new()
	assert_true(hof.is_empty())
	assert_eq(hof.add(_entry()), HallOfFame.AddResult.ADDED)
	var second := HallOfFame.snapshot([_mon(&"venusaur", 70)], "Kevin", &"charmander", 9.0, "e")
	assert_eq(hof.add(second), HallOfFame.AddResult.ADDED)
	assert_eq(hof.size(), 2)
	assert_eq(hof.get_entry(0)["team"][0]["species"], "charizard", "la première reste")
	assert_eq(hof.get_entry(1)["team"][0]["species"], "venusaur")


func test_entries_are_immutable_from_outside() -> void:
	var hof := HallOfFame.new()
	var entry := _entry()
	hof.add(entry)
	entry["player"] = "Triche"
	(entry["team"] as Array).clear()
	var read := hof.get_entry(0)
	read["player"] = "Autre"
	(read["team"] as Array)[0]["level"] = 1
	for listed: Dictionary in hof.entries():
		listed["date"] = "x"
	(hof.to_array()[0] as Dictionary)["starter"] = "x"
	var kept := hof.get_entry(0)
	assert_eq(kept["player"], "Kevin")
	assert_eq(kept["date"], "2026-10-22T21:04:00")
	assert_eq(kept["starter"], "charmander")
	assert_eq(kept["team"][0]["level"], 65)
	assert_eq((kept["team"] as Array).size(), 3)


func test_invalid_entries_are_refused() -> void:
	var hof := HallOfFame.new()
	assert_eq(hof.add({}), HallOfFame.AddResult.INVALID, "équipe vide")
	assert_eq(hof.add({"team": [{"species": "", "level": 5}]}), HallOfFame.AddResult.INVALID)
	assert_eq(hof.add({"team": [{"species": "onix", "level": 0}]}), HallOfFame.AddResult.INVALID)
	assert_eq(hof.add({"team": ["onix"]}), HallOfFame.AddResult.INVALID)
	assert_true(hof.is_empty())


func test_beyond_fifty_nothing_is_added_and_nothing_is_erased() -> void:
	# Q30-5, défaut du plan : arrêter d'ajouter (la plus ancienne n'est pas effacée).
	var hof := HallOfFame.new()
	for i: int in HallOfFame.MAX_ENTRIES:
		var entry := HallOfFame.snapshot([_mon(&"onix", 1 + i)], "K", &"bulbasaur", 0.0, str(i))
		assert_eq(hof.add(entry), HallOfFame.AddResult.ADDED)
	assert_true(hof.is_full())
	assert_eq(hof.add(_entry()), HallOfFame.AddResult.FULL)
	assert_eq(hof.size(), 50)
	assert_eq(hof.get_entry(0)["date"], "0", "la plus ancienne est gardée")
	assert_eq(hof.get_entry(49)["date"], "49")


func test_write_and_read_back_are_identical() -> void:
	var hof := HallOfFame.new()
	hof.add(_entry())
	hof.add(HallOfFame.snapshot([_mon(&"dragonite", 62, "Draco")], "Kevin", &"charmander", 2.0,
		"2026-10-23T08:00:00"))
	var json := JSON.stringify(hof.to_array())
	var loaded := HallOfFame.new()
	assert_true(loaded.load_array(JSON.parse_string(json)))
	assert_eq(loaded.size(), 2)
	assert_eq(JSON.stringify(loaded.to_array()), json, "relecture à l'identique")


func test_reading_an_empty_or_missing_list_gives_an_empty_hall() -> void:
	var loaded := HallOfFame.new()
	loaded.add(_entry())
	assert_true(loaded.load_array([]))
	assert_true(loaded.is_empty(), "le chargement remplace")


func test_reading_skips_bad_entries_and_keeps_the_good_ones() -> void:
	var good := _entry()
	var loaded := HallOfFame.new()
	assert_false(loaded.load_array([good, "texte", {"team": []}, good]))
	assert_eq(loaded.size(), 2)


func test_reading_more_than_fifty_keeps_the_first_fifty() -> void:
	var list: Array = []
	for i: int in 55:
		list.append(HallOfFame.snapshot([_mon(&"onix", 10)], "K", &"squirtle", 0.0, str(i)))
	var loaded := HallOfFame.new()
	assert_false(loaded.load_array(list))
	assert_eq(loaded.size(), 50)
	assert_eq(loaded.get_entry(49)["date"], "49")


func test_out_of_range_entry_is_empty() -> void:
	assert_eq(HallOfFame.new().get_entry(0), {})
	assert_eq(HallOfFame.new().get_entry(-1), {})
