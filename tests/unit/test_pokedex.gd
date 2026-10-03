extends GutTest
## Pokedex : espèces vues et capturées (jalon 5, décision de Kevin 2026-09-29). Données
## collectées dès le jalon 5, sérialisées pour la sauvegarde ; l'écran arrive au jalon 6.

var _dex: Pokedex


func before_each() -> void:
	_dex = Pokedex.new()


func test_new_pokedex_is_empty() -> void:
	assert_eq(_dex.seen_count(), 0)
	assert_eq(_dex.caught_count(), 0)
	assert_false(_dex.is_seen(&"pidgey"))
	assert_false(_dex.is_caught(&"pidgey"))


func test_mark_seen_is_true_only_the_first_time() -> void:
	assert_true(_dex.mark_seen(&"pidgey"), "première fois")
	assert_false(_dex.mark_seen(&"pidgey"), "déjà vue")
	assert_true(_dex.is_seen(&"pidgey"))
	assert_false(_dex.is_caught(&"pidgey"))
	assert_eq(_dex.seen_count(), 1)


func test_mark_caught_implies_seen() -> void:
	assert_true(_dex.mark_caught(&"rattata"), "première capture")
	assert_true(_dex.is_seen(&"rattata"), "capturer implique voir")
	assert_true(_dex.is_caught(&"rattata"))
	assert_eq(_dex.seen_count(), 1)
	assert_eq(_dex.caught_count(), 1)


func test_mark_caught_is_true_only_the_first_capture() -> void:
	_dex.mark_seen(&"rattata")
	assert_true(_dex.mark_caught(&"rattata"), "première capture d'une espèce déjà vue")
	assert_false(_dex.mark_caught(&"rattata"), "déjà capturée")


func test_empty_species_is_ignored() -> void:
	assert_false(_dex.mark_seen(&""))
	assert_false(_dex.mark_caught(&""))
	assert_eq(_dex.seen_count(), 0)


func test_ids_are_sorted() -> void:
	_dex.mark_seen(&"rattata")
	_dex.mark_seen(&"pidgey")
	_dex.mark_caught(&"charmander")
	assert_eq(_dex.seen_ids(), [&"charmander", &"pidgey", &"rattata"] as Array[StringName])
	assert_eq(_dex.caught_ids(), [&"charmander"] as Array[StringName])


func test_clear_empties_everything() -> void:
	_dex.mark_caught(&"pidgey")
	_dex.clear()
	assert_eq(_dex.seen_count(), 0)
	assert_eq(_dex.caught_count(), 0)


func test_to_dict_and_from_dict_round_trip() -> void:
	_dex.mark_seen(&"pidgey")
	_dex.mark_seen(&"rattata")
	_dex.mark_caught(&"rattata")
	var dict := _dex.to_dict()
	assert_eq(dict["entries"].keys(), ["pidgey", "rattata"], "entrées triées")
	assert_false(dict["entries"]["pidgey"]["caught"])
	assert_true(dict["entries"]["rattata"]["caught"])
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict(JSON.parse_string(JSON.stringify(dict))))
	assert_true(loaded.is_seen(&"pidgey"))
	assert_true(loaded.is_caught(&"rattata"))
	assert_true(loaded.is_seen(&"rattata"))
	assert_eq(loaded.seen_count(), 2)
	assert_eq(loaded.caught_count(), 1)
	assert_eq(loaded.to_dict(), dict)


func test_from_dict_reads_the_old_lists_shape() -> void:
	# Forme du jalon 5 T0 ({ seen, caught }), avant les faits du §16.3.
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict({"seen": ["pidgey", "rattata"], "caught": ["rattata"]}))
	assert_eq(loaded.seen_ids(), [&"pidgey", &"rattata"] as Array[StringName])
	assert_eq(loaded.caught_ids(), [&"rattata"] as Array[StringName])
	assert_eq(loaded.times_seen(&"pidgey"), 1)


func test_from_dict_marks_caught_as_seen_even_when_seen_omits_it() -> void:
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict({"seen": [], "caught": ["pidgey"]}))
	assert_true(loaded.is_seen(&"pidgey"), "capturé sans être listé vu → vu quand même")
	assert_true(loaded.is_caught(&"pidgey"))


func test_from_dict_discards_invalid_entries() -> void:
	var loaded := Pokedex.new()
	assert_false(loaded.from_dict({"seen": [42, ""], "caught": "pas une liste"}))
	assert_eq(loaded.seen_count(), 0)
	assert_false(loaded.from_dict({"entries": {"pidgey": "x", "": {}, "rattata": {}}}))
	assert_eq(loaded.seen_ids(), [&"rattata"] as Array[StringName], "l'entrée valide reste")
	assert_false(loaded.from_dict({"entries": []}))
	assert_eq(loaded.seen_count(), 0)
	# 42 écarté, "" écarté, « caught » pas une liste (3) ; « x » et « » écartés (2) ;
	# « entries » pas un dictionnaire (1) : six push_error attendus.
	assert_push_error_count(6)


# --- Faits par espèce (jalon 5 §16.3) -------------------------------------------------------

func test_mark_seen_without_map_or_date_keeps_the_old_api() -> void:
	assert_true(_dex.mark_seen(&"pidgey"))
	var entry := _dex.get_entry(&"pidgey")
	assert_not_null(entry)
	assert_eq(entry.times_seen, 1)
	assert_eq(entry.first_seen_map, &"")
	assert_eq(entry.first_seen_date, "")
	assert_eq(entry.seen_maps.size(), 0, "pas de carte inconnue dans la liste")
	assert_null(_dex.get_entry(&"rattata"), "jamais vue → pas d'entrée")


func test_first_sighting_is_kept_and_sightings_are_counted() -> void:
	assert_true(_dex.mark_seen(&"pidgey", &"route_1", "2026-10-02T10:00:00"))
	assert_false(_dex.mark_seen(&"pidgey", &"route_1", "2026-10-02T10:05:00"))
	assert_false(_dex.mark_seen(&"pidgey", &"viridian_forest", "2026-10-03T09:00:00"))
	var entry := _dex.get_entry(&"pidgey")
	assert_eq(entry.first_seen_map, &"route_1")
	assert_eq(entry.first_seen_date, "2026-10-02T10:00:00", "la première date reste")
	assert_eq(entry.seen_maps, [&"route_1", &"viridian_forest"] as Array[StringName])
	assert_eq(_dex.times_seen(&"pidgey"), 3)
	assert_eq(_dex.times_caught(&"pidgey"), 0)
	assert_eq(_dex.times_seen(&"mew"), 0)


func test_capture_after_sighting_dates_the_first_capture_only() -> void:
	_dex.mark_seen(&"rattata", &"route_1", "d1")
	assert_true(_dex.mark_caught(&"rattata", &"route_1", "d2"))
	assert_false(_dex.mark_caught(&"rattata", &"route_22", "d3"))
	var entry := _dex.get_entry(&"rattata")
	assert_eq(entry.first_seen_date, "d1")
	assert_eq(entry.first_caught_map, &"route_1")
	assert_eq(entry.first_caught_date, "d2")
	assert_eq(entry.times_caught, 2)
	assert_eq(entry.times_seen, 1, "une capture ne compte pas une observation de plus")
	assert_eq(_dex.caught_count(), 1)


func test_capture_of_an_unseen_species_counts_as_its_first_sighting() -> void:
	# Le starter : « capturé » à son entrée dans l'équipe sans avoir été « vu » en combat.
	assert_true(_dex.mark_caught(&"charmander", &"oak_lab", "d1"))
	var entry := _dex.get_entry(&"charmander")
	assert_true(_dex.is_seen(&"charmander"), "caught ⊆ seen")
	assert_eq(entry.first_seen_map, &"oak_lab")
	assert_eq(entry.first_seen_date, "d1")
	assert_eq(entry.seen_maps, [&"oak_lab"] as Array[StringName])
	assert_eq(entry.times_seen, 1, "la capture vaut sa première observation")
	assert_eq(entry.times_caught, 1)
	assert_eq(_dex.times_seen(&"charmander"), 1)
	# Une seconde capture ne rajoute pas d'observation.
	_dex.mark_caught(&"charmander", &"route_1", "d2")
	assert_eq(_dex.times_seen(&"charmander"), 1)
	assert_eq(_dex.times_caught(&"charmander"), 2)


func test_a_wild_pokemon_seen_then_caught_is_seen_exactly_once() -> void:
	# Combat sauvage : « vu » à l'entrée du Pokémon, « capturé » à la capture.
	_dex.mark_seen(&"pidgey", &"route_1", "d1")
	_dex.mark_caught(&"pidgey", &"route_1", "d2")
	assert_eq(_dex.times_seen(&"pidgey"), 1, "pas de double compte")
	assert_eq(_dex.times_caught(&"pidgey"), 1)
	assert_eq(_dex.get_entry(&"pidgey").first_seen_date, "d1")


func test_an_old_save_with_a_captured_species_seen_zero_times_is_fixed_on_load() -> void:
	# Sauvegarde du jalon 5 avant la règle : starter capturé, times_seen à 0.
	var old := {"entries": {
		"charmander": {"caught": true, "first_seen_map": "oak_lab", "first_seen_date": "d1",
			"first_caught_map": "oak_lab", "first_caught_date": "d1",
			"seen_maps": ["oak_lab"], "times_seen": 0, "times_caught": 1},
		"rattata": {"caught": true, "first_caught_map": "route_1", "first_caught_date": "d2",
			"times_seen": 0, "times_caught": 1},
		"pidgey": {"caught": false, "times_seen": 3, "times_caught": 0},
		"zubat": {"caught": false, "times_seen": 0},
	}}
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict(old))
	assert_eq(loaded.times_seen(&"charmander"), 1, "au moins 1")
	assert_eq(loaded.get_entry(&"charmander").first_seen_date, "d1", "date gardée")
	assert_eq(loaded.times_seen(&"rattata"), 1)
	assert_eq(loaded.get_entry(&"rattata").first_seen_map, &"route_1", "reprend la capture")
	assert_eq(loaded.get_entry(&"rattata").seen_maps, [&"route_1"] as Array[StringName])
	assert_eq(loaded.times_seen(&"pidgey"), 3, "un compte valide n'est pas touché")
	assert_eq(loaded.times_seen(&"zubat"), 1, "une entrée existe = vue au moins une fois")
	assert_eq(PokedexEntry.from_dict(&"x", {"caught": true}).times_seen, 1)


func test_old_lists_load_with_one_sighting_for_captured_species() -> void:
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict({"seen": ["pidgey"], "caught": ["charmander"]}))
	assert_eq(loaded.times_seen(&"charmander"), 1)
	assert_eq(loaded.times_seen(&"pidgey"), 1)


func test_notes_round_trip_and_default() -> void:
	# Jalon 6, T0 (jalon-06.md §5.1) : notes d'Observations posées dans la sauvegarde v2.
	_dex.mark_seen(&"pidgey", &"route_1", "d1")
	var entry := _dex.get_entry(&"pidgey")
	assert_eq(entry.notes, [] as Array[StringName], "aucune note au départ")
	assert_eq(entry.to_dict()["notes"], [])
	entry.notes.append(&"pidgey_paths")
	var copy := PokedexEntry.from_dict(&"pidgey",
		JSON.parse_string(JSON.stringify(entry.to_dict())))
	assert_eq(copy.notes, [&"pidgey_paths"] as Array[StringName])
	var dict := entry.to_dict()
	dict.erase("notes")
	assert_eq(PokedexEntry.from_dict(&"pidgey", dict).notes, [] as Array[StringName],
		"sauvegarde v1 : aucune note")
	dict["notes"] = ["a", "", 3, "a", "b"]
	assert_eq(PokedexEntry.from_dict(&"pidgey", dict).notes, [&"a", &"b"] as Array[StringName],
		"entrées invalides et doublons écartés, sans erreur")


func test_entry_round_trip_and_tolerant_reading() -> void:
	_dex.mark_seen(&"pidgey", &"route_1", "d1")
	_dex.mark_caught(&"pidgey", &"route_1", "d2")
	var dict := _dex.get_entry(&"pidgey").to_dict()
	var copy := PokedexEntry.from_dict(&"pidgey", JSON.parse_string(JSON.stringify(dict)))
	assert_eq(copy.to_dict(), dict)
	assert_eq(copy.species, &"pidgey")
	var sparse := PokedexEntry.from_dict(&"pidgey", {"caught": "oui", "times_seen": -2,
		"seen_maps": "route_1"})
	assert_false(sparse.caught)
	assert_eq(sparse.times_seen, 0)
	assert_eq(sparse.seen_maps.size(), 0)
	assert_eq(sparse.first_seen_map, &"")


# --- J6 (jalon-06.md §3.5) : signal recorded, notes, lieux ----------------------------------

func test_recorded_is_emitted_for_each_sighting_and_capture() -> void:
	var calls: Array[Array] = []
	_dex.recorded.connect(func(species: StringName, map: StringName, first_seen: bool,
			new_map: bool, caught: bool) -> void:
		calls.append([species, map, first_seen, new_map, caught]))
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_dex.mark_seen(&"pidgey", &"route_1")
	_dex.mark_caught(&"pidgey", &"route_1")
	_dex.mark_caught(&"rattata", &"route_1")
	_dex.mark_seen(&"", &"route_1")
	assert_eq(calls, [
		[&"pidgey", &"pallet_town", true, true, false],
		[&"pidgey", &"pallet_town", false, false, false],
		[&"pidgey", &"route_1", false, true, false],
		[&"pidgey", &"route_1", false, false, true],
		[&"rattata", &"route_1", true, true, true],
	] as Array[Array], "une espèce vide n'émet rien")


func test_loading_never_emits_recorded() -> void:
	var source := Pokedex.new()
	source.mark_caught(&"pidgey", &"route_1")
	var count := [0]
	_dex.recorded.connect(func(_s: StringName, _m: StringName, _f: bool, _n: bool,
			_c: bool) -> void: count[0] += 1)
	_dex.from_dict(source.to_dict())
	_dex.from_dict({"seen": ["rattata"], "caught": ["pidgey"]})
	assert_eq(count[0], 0)
	assert_true(_dex.is_caught(&"pidgey"), "ancienne forme toujours lue")
	assert_eq(_dex.times_seen(&"pidgey"), 1)


func test_has_seen_at() -> void:
	_dex.mark_seen(&"pidgey", &"route_1")
	assert_true(_dex.has_seen_at(&"pidgey", &"route_1"))
	assert_false(_dex.has_seen_at(&"pidgey", &"pallet_town"))
	assert_false(_dex.has_seen_at(&"pidgey", &""))
	assert_false(_dex.has_seen_at(&"rattata", &"route_1"))


func test_unlock_note() -> void:
	assert_false(_dex.unlock_note(&"pidgey", &"pidgey_paths"), "espèce jamais vue")
	_dex.mark_seen(&"pidgey")
	assert_true(_dex.unlock_note(&"pidgey", &"pidgey_paths"))
	assert_false(_dex.unlock_note(&"pidgey", &"pidgey_paths"), "déjà débloquée")
	assert_false(_dex.unlock_note(&"pidgey", &""))
	assert_true(_dex.has_note(&"pidgey", &"pidgey_paths"))
	assert_false(_dex.has_note(&"rattata", &"pidgey_paths"))
	assert_eq(_dex.get_entry(&"pidgey").notes, [&"pidgey_paths"] as Array[StringName])
