extends GutTest
## PokedexNotes : déblocage des notes d'Observations (jalon-06.md §3.5, Q-6). Les notes se
## débloquent en silence, même avant l'activation du Pokédex (règle de déblocage).

var _lib: PokedexLibrary
var _dex: Pokedex
var _flags: StoryFlags


func before_each() -> void:
	_lib = PokedexLibrary.new()
	assert_true(_lib.add_from_dict({"size": 151, "species": {
		"pidgey": {"height": 0.3, "weight": 1.8, "description": "x", "notes": [
			{"id": "pidgey_first", "text": "Première.", "unlock": {"seen": 1}},
			{"id": "pidgey_often", "text": "Souvent.", "unlock": {"seen": 3}},
			{"id": "pidgey_route", "text": "Route.", "unlock": {"map": "route_1"}},
			{"id": "pidgey_caught", "text": "Capturé.", "unlock": {"caught": 1}},
			{"id": "pidgey_flag", "text": "Drapeau.", "unlock": {"flag": "met_aoki",
				"seen": 2}},
		]},
		"rattata": {"height": 0.3, "weight": 3.5, "description": "x", "notes": [
			{"id": "rattata_first", "text": "R.", "unlock": {"seen": 1}},
		]},
	}}, "test"))
	_dex = Pokedex.new()
	_flags = StoryFlags.new()


func _refresh() -> Array[Array]:
	return PokedexNotes.refresh(_dex, _lib, _flags)


func test_nothing_unlocks_for_an_unseen_species() -> void:
	_flags.set_flag(&"met_aoki")
	assert_eq(_refresh(), [] as Array[Array])
	assert_false(_dex.has_note(&"pidgey", &"pidgey_flag"))


func test_first_sighting_unlocks_the_seen_note_once() -> void:
	_dex.mark_seen(&"pidgey", &"pallet_town")
	assert_eq(_refresh(), [[&"pidgey", &"pidgey_first"]] as Array[Array])
	assert_true(_dex.has_note(&"pidgey", &"pidgey_first"))
	assert_eq(_refresh(), [] as Array[Array], "jamais deux fois")
	assert_eq(_dex.get_entry(&"pidgey").notes, [&"pidgey_first"] as Array[StringName])


func test_seen_count_map_caught_and_flag_conditions() -> void:
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_refresh()
	assert_false(_dex.has_note(&"pidgey", &"pidgey_often"), "2 observations sur 3")
	assert_false(_dex.has_note(&"pidgey", &"pidgey_flag"), "drapeau pas levé")
	_flags.set_flag(&"met_aoki")
	assert_eq(_refresh(), [[&"pidgey", &"pidgey_flag"]] as Array[Array])
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_eq(_refresh(), [[&"pidgey", &"pidgey_often"], [&"pidgey", &"pidgey_route"]] \
		as Array[Array], "ordre du fichier")
	_dex.mark_caught(&"pidgey", &"route_1")
	assert_eq(_refresh(), [[&"pidgey", &"pidgey_caught"]] as Array[Array])


func test_all_conditions_must_hold() -> void:
	_flags.set_flag(&"met_aoki")
	_dex.mark_seen(&"pidgey")
	_refresh()
	assert_false(_dex.has_note(&"pidgey", &"pidgey_flag"), "drapeau mais une seule observation")


func test_a_capture_of_an_unseen_species_counts_as_its_first_sighting() -> void:
	_dex.mark_caught(&"rattata", &"route_1")
	assert_eq(_refresh(), [[&"rattata", &"rattata_first"]] as Array[Array])


func test_only_limits_the_refresh_to_one_species() -> void:
	_dex.mark_seen(&"pidgey")
	_dex.mark_seen(&"rattata")
	assert_eq(PokedexNotes.refresh(_dex, _lib, _flags, &"rattata"),
		[[&"rattata", &"rattata_first"]] as Array[Array])
	assert_false(_dex.has_note(&"pidgey", &"pidgey_first"))


func test_unlocked_notes_are_saved() -> void:
	_dex.mark_seen(&"pidgey")
	_refresh()
	var copy := Pokedex.new()
	copy.from_dict(_dex.to_dict())
	assert_true(copy.has_note(&"pidgey", &"pidgey_first"))


func test_species_of() -> void:
	var pairs: Array[Array] = [[&"pidgey", &"a"], [&"rattata", &"b"], [&"pidgey", &"c"]]
	assert_eq(PokedexNotes.species_of(pairs), [&"pidgey", &"rattata"] as Array[StringName])


func test_null_inputs_do_nothing() -> void:
	assert_eq(PokedexNotes.refresh(null, _lib, _flags), [] as Array[Array])
	assert_eq(PokedexNotes.refresh(_dex, null, _flags), [] as Array[Array])
	_dex.mark_seen(&"pidgey")
	assert_eq(PokedexNotes.refresh(_dex, _lib, null).size(), 1, "sans drapeaux")


func test_real_data_first_sighting_unlocks_one_note_per_encounterable_species() -> void:
	var lib := PokedexLibrary.new()
	lib.load_file()
	for species: StringName in [&"pidgey", &"rattata", &"charmander", &"bulbasaur",
			&"squirtle"]:
		_dex.mark_seen(species)
	_dex.mark_seen(&"raticate")
	var unlocked := PokedexNotes.refresh(_dex, lib, _flags)
	assert_eq(unlocked.size(), 5, "Q-6 : une note chacun, aucune pour Rattatac")
