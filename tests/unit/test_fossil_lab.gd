extends GutTest
## FossilLab (jalon 24, T13 ; dossier 27 §10.5, `jalon-24.md` §2.8) : IDLE → REVIVING → READY →
## IDLE, données `data/world/fossils.json`, don par une interface injectée (la vraie : un
## adaptateur de `PokemonGift`, J20), drapeaux effacés seulement après un don réussi.

var _lab: FossilLab
var _bag: Bag
var _flags: StoryFlags
var _given: Array = []


func before_each() -> void:
	_lab = FossilLab.new()
	assert_true(_lab.load_file())
	_bag = Bag.new()
	_flags = StoryFlags.new()
	_given = []


func _gift_ok(species: StringName, level: int) -> bool:
	_given.append([species, level])
	return true


func _gift_refused(_species: StringName, _level: int) -> bool:
	return false


func test_data_lists_the_two_fossils() -> void:
	assert_eq(_lab.fossil_ids(), [&"dome_fossil", &"helix_fossil"] as Array[StringName])
	assert_eq(_lab.species_of(&"dome_fossil"), &"kabuto")
	assert_eq(_lab.species_of(&"helix_fossil"), &"omanyte")
	assert_eq(_lab.level_of(&"dome_fossil"), 30)
	assert_eq(_lab.flag_of(&"helix_fossil"), &"fossil_reviving_omanyte")
	assert_eq(_lab.ready_map(), &"cinnabar_island")
	assert_eq(_lab.ready_flag(), &"fossil_ready")
	assert_eq(_lab.species_of(&"old_amber"), &"", "le J25 l'ajoutera aux données")


func test_species_and_fossil_items_exist_in_game_data() -> void:
	var items := ItemLibrary.new()
	var data := PokemonData.new()
	assert_true(items.load_dir() and data.load_dir())
	for fossil: StringName in _lab.fossil_ids():
		assert_not_null(items.get_item(fossil), String(fossil))
		assert_not_null(data.get_species(_lab.species_of(fossil)), String(fossil))


func test_bad_data_is_refused() -> void:
	var lab := FossilLab.new()
	assert_false(lab.add_from_dict({"fossils": {}}))
	assert_push_error("FossilLab")
	assert_false(lab.add_from_dict({"ready_map": "m", "ready_flag": "f",
		"fossils": {"x": {"species": "kabuto", "level": 0, "flag": "f2"}}}))
	assert_push_error("FossilLab")


func test_full_cycle() -> void:
	_bag.add(&"dome_fossil")
	assert_eq(_lab.state(_flags), FossilLab.State.IDLE)
	assert_eq(_lab.fossils_in_bag(_bag), [&"dome_fossil"] as Array[StringName])
	assert_true(_lab.deposit(&"dome_fossil", _bag, _flags))
	assert_false(_bag.has(&"dome_fossil"), "fossile confié")
	assert_true(_flags.has_flag(&"fossil_reviving_kabuto"))
	assert_eq(_lab.state(_flags), FossilLab.State.REVIVING)
	assert_eq(_lab.reviving_fossil(_flags), &"dome_fossil")
	assert_eq(_lab.collect(_flags, _gift_ok), &"", "pas encore prêt (T-64)")
	assert_true(_given.is_empty())
	assert_false(_lab.on_map_entered(&"cinnabar_lab", _flags), "toujours dans le Labo")
	assert_true(_lab.on_map_entered(&"cinnabar_island", _flags), "ressorti en ville")
	assert_eq(_lab.state(_flags), FossilLab.State.READY)
	assert_false(_lab.on_map_entered(&"cinnabar_island", _flags), "déjà prêt")
	assert_eq(_lab.collect(_flags, _gift_ok), &"kabuto")
	assert_eq(_given, [[&"kabuto", 30]])
	assert_eq(_lab.state(_flags), FossilLab.State.IDLE)
	assert_false(_flags.has_flag(&"fossil_reviving_kabuto"))
	assert_false(_flags.has_flag(&"fossil_ready"))


func test_refused_gift_keeps_the_flags_for_a_retry() -> void:
	_bag.add(&"helix_fossil")
	_lab.deposit(&"helix_fossil", _bag, _flags)
	_lab.on_map_entered(&"cinnabar_island", _flags)
	assert_eq(_lab.collect(_flags, _gift_refused), &"")
	assert_eq(_lab.state(_flags), FossilLab.State.READY, "rien n'est perdu")
	assert_eq(_lab.collect(_flags, _gift_ok), &"omanyte")
	assert_eq(_lab.collect(_flags, _gift_ok), &"", "jamais deux fois")
	assert_eq(_given.size(), 1)


func test_deposit_refusals() -> void:
	assert_false(_lab.deposit(&"dome_fossil", _bag, _flags), "pas dans le Sac (T-63)")
	assert_true(_lab.fossils_in_bag(_bag).is_empty())
	_bag.add(&"dome_fossil")
	_bag.add(&"helix_fossil")
	assert_false(_lab.deposit(&"old_amber", _bag, _flags), "fossile inconnu")
	assert_true(_lab.deposit(&"helix_fossil", _bag, _flags))
	assert_false(_lab.deposit(&"dome_fossil", _bag, _flags), "une résurrection à la fois")
	assert_true(_bag.has(&"dome_fossil"))


func test_ready_flag_alone_is_not_a_revival() -> void:
	_flags.set_flag(&"fossil_ready")
	assert_eq(_lab.state(_flags), FossilLab.State.IDLE)
	assert_false(_lab.on_map_entered(&"cinnabar_island", _flags))


func test_no_species_in_the_code() -> void:
	var source := FileAccess.get_file_as_string("res://game/world/fossils/fossil_lab.gd")
	for word: String in ["kabuto", "omanyte", "aerodactyl", "dome_fossil", "helix_fossil"]:
		assert_false(source.contains(word), word)
