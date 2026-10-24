extends GutTest
## Rattrapage des objets remis par une scène (jalon 16 T13, jalon-16.md §2.8, dossier 19 §6) :
## règles réelles, les deux sens, sans effet sur une partie cohérente ni la seconde fois.


func _repair() -> KeyItemRepair:
	var repair := KeyItemRepair.new()
	assert_true(repair.load_file(), "\n".join(repair.get_errors()))
	return repair


func test_real_rules_link_hm01_to_its_flag_and_the_item_exists() -> void:
	var repair := _repair()
	# J25 (§2.4) : la Clé Secrète ramassée au B1F du Manoir ; le Vieil Ambre, lui, est confié au
	# Labo (consommé) : aucune réparation.
	assert_eq(repair.rules, [{"item": &"hm01", "flag": &"got_hm01"},
		{"item": &"secret_key", "flag": &"got_pokemon_mansion_b1f_item_5"}] as Array[Dictionary])
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	for rule: Dictionary in repair.rules:
		assert_true(items.has_item(rule["item"]), "objet « %s » connu" % rule["item"])


func test_item_without_flag_raises_the_flag() -> void:
	var flags := StoryFlags.new()
	var bag := Bag.new()
	bag.add(&"hm01")
	var notes := _repair().apply(flags, bag)
	assert_true(flags.has_flag(&"got_hm01"))
	assert_eq(bag.count_of(&"hm01"), 1, "aucun doublon")
	assert_eq(notes.size(), 1, "journalisé")


func test_flag_without_item_gives_it_back_once() -> void:
	var flags := StoryFlags.new()
	flags.set_flag(&"got_hm01")
	var bag := Bag.new()
	var repair := _repair()
	assert_eq(repair.apply(flags, bag).size(), 1)
	assert_eq(bag.count_of(&"hm01"), 1)
	assert_eq(repair.apply(flags, bag).size(), 0, "sans effet la seconde fois")
	assert_eq(bag.count_of(&"hm01"), 1)


func test_consistent_games_are_untouched() -> void:
	var repair := _repair()
	var flags := StoryFlags.new()
	var bag := Bag.new()
	assert_eq(repair.apply(flags, bag).size(), 0, "ni objet ni drapeau")
	assert_false(flags.has_flag(&"got_hm01"))
	assert_false(bag.has(&"hm01"))
	flags.set_flag(&"got_hm01")
	bag.add(&"hm01")
	assert_eq(repair.apply(flags, bag).size(), 0, "les deux")
	assert_eq(bag.count_of(&"hm01"), 1)


func test_invalid_files_are_rejected() -> void:
	var repair := KeyItemRepair.new()
	assert_false(repair.load_file("res://tests/fixtures/absent_key_item_repairs.json"))
	assert_eq(repair.rules.size(), 0)
