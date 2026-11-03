extends GutTest
## RP-285 : aucun départ de débogage (`tools/debug_start/*.json`) n'est « rattrapé » au premier
## chargement (data/story/key_item_repairs.json) : drapeau et objet clé vont toujours ensemble.

const DIR := "res://tools/debug_start/"


func test_no_debug_start_is_changed_by_the_repair() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var repair := KeyItemRepair.new()
	assert_true(repair.load_file())
	var count := 0
	for file: String in DirAccess.get_files_at(DIR):
		if not file.ends_with(".json"):
			continue
		var start := DebugStart.new()
		if not start.load_file(DIR + file, data, items):
			continue  # invalide : couvert par les tests des départs concernés
		count += 1
		var flags := StoryFlags.new()
		for flag: StringName in start.flags:
			flags.set_flag(flag)
		var bag := Bag.new()
		for id: StringName in start.bag:
			bag.add(id, start.bag[id])
		var notes := repair.apply(flags, bag)
		assert_eq(notes.size(), 0, "%s : %s" % [file, "; ".join(notes)])
	assert_gt(count, 100, "les départs sont bien parcourus")
