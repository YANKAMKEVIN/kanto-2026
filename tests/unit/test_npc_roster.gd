extends GutTest
## NpcRoster et NpcSpec : format de data/npcs/<map_id>.json, valeurs par défaut,
## validation (jalon 3 §2.3). Jalon 4 : style de saut (hop_style), verbe « meet » refusé.

const FIXTURES := "res://tests/fixtures/npcs/"


func test_load_for_map_reads_the_map_file_in_order() -> void:
	var roster := NpcRoster.load_for_map(&"sample_map", FIXTURES)
	assert_eq(roster.get_errors().size(), 0)
	assert_eq(roster.size(), 4)
	var ids: Array[StringName] = []
	for spec: NpcSpec in roster.get_all():
		ids.append(spec.id)
	assert_eq(ids, [&"mom", &"charmander", &"rival", &"pidgey_1"] as Array[StringName])


func test_missing_file_gives_an_empty_roster_without_error() -> void:
	var roster := NpcRoster.load_for_map(&"no_such_map", FIXTURES)
	assert_eq(roster.size(), 0)
	assert_eq(roster.get_errors().size(), 0)
	assert_eq(NpcRoster.path_for_map(&"oak_lab"), "res://data/npcs/oak_lab.json")


func test_fields_and_defaults() -> void:
	var roster := NpcRoster.load_for_map(&"sample_map", FIXTURES)
	var mom := roster.get_spec(&"mom")
	assert_eq(mom.cell, Vector2i(7, 4))
	assert_eq(mom.facing, Vector2i.DOWN)
	assert_eq(mom.sprite, &"mom")
	assert_eq(mom.dialogue, &"mom")
	assert_eq(mom.verb, Interaction.Kind.TALK, "parler par défaut")
	assert_true(mom.turn_to_player, "se tourne par défaut")
	assert_false(mom.keep_facing, "reprend son orientation par défaut")
	var rival := roster.get_spec(&"rival")
	assert_eq(rival.facing, Vector2i.RIGHT)
	assert_false(rival.turn_to_player)
	assert_eq(mom.lift, 0, "au sol par défaut")
	var charmander := roster.get_spec(&"charmander")
	assert_eq(charmander.verb, Interaction.Kind.OBSERVE)
	assert_eq(charmander.lift, 56, "posé sur la table")


func test_npc_without_dialogue_is_not_interactive() -> void:
	var roster := NpcRoster.load_for_map(&"sample_map", FIXTURES)
	var pidgey := roster.get_spec(&"pidgey_1")
	assert_false(pidgey.is_interactive())
	assert_null(pidgey.make_interaction(pidgey.cell, null))


func test_make_interaction() -> void:
	var roster := NpcRoster.load_for_map(&"sample_map", FIXTURES)
	var spec := roster.get_spec(&"charmander")
	var source := RefCounted.new()
	var interaction := spec.make_interaction(Vector2i(11, 5), source)
	assert_eq(interaction.kind, Interaction.Kind.OBSERVE)
	assert_eq(interaction.dialogue_id, &"observe_charmander")
	assert_eq(interaction.cell, Vector2i(11, 5))
	assert_eq(interaction.facing, Vector2i.ZERO, "de n'importe quel côté")
	assert_eq(interaction.source, source)


func test_default_facing_is_down() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({"a": {"cell": [1, 2], "sprite": "x"}}))
	assert_eq(roster.get_spec(&"a").facing, Vector2i.DOWN)


func test_invalid_entries_are_rejected() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({
		"no_cell": {"sprite": "x"},
		"bad_cell": {"cell": [1.5, 2], "sprite": "x"},
		"negative": {"cell": [-1, 2], "sprite": "x"},
		"no_sprite": {"cell": [1, 2]},
		"bad_facing": {"cell": [1, 2], "sprite": "x", "facing": "north"},
		"bad_verb": {"cell": [1, 2], "sprite": "x", "verb": "examine"},
		"typo": {"cell": [1, 2], "sprite": "x", "dialog": "mom"},
		"bad_bool": {"cell": [1, 2], "sprite": "x", "turn_to_player": "no"},
		"bad_lift": {"cell": [1, 2], "sprite": "x", "lift": -4},
		"meet_verb": {"cell": [1, 2], "sprite": "x", "dialogue": "x", "verb": "meet"},
		"bad_hop_style": {"cell": [1, 2], "sprite": "x", "hop_style": "fast"},
		"hop_style_not_text": {"cell": [1, 2], "sprite": "x", "hop_style": 2},
		"not_object": "mom",
	}, "test"))
	assert_push_error_count(13)
	assert_eq(roster.size(), 0)
	assert_eq(roster.get_errors().size(), 13)
	var errors := "\n".join(roster.get_errors())
	assert_string_contains(errors, "« meet_verb » : « verb » vaut talk ou observe")
	assert_string_contains(errors, "« hop_style » vaut calm, eager, playful")


func test_hop_style() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({
		"calm": {"cell": [1, 2], "sprite": "x", "hop_style": "calm"},
		"eager": {"cell": [2, 2], "sprite": "x", "hop_style": "eager"},
		"playful": {"cell": [3, 2], "sprite": "x", "hop_style": "playful"},
		"none": {"cell": [4, 2], "sprite": "x"},
	}, "test"))
	for id: StringName in [&"calm", &"eager", &"playful"]:
		assert_eq(roster.get_spec(id).hop_style, id)
	assert_eq(roster.get_spec(&"none").hop_style, &"", "saut par défaut")


## Décision de Kevin n° 1 (jalon 4 §8) : chaque starter du labo a son style de saut.
func test_real_lab_starters_have_their_hop_style() -> void:
	var roster := NpcRoster.load_for_map(&"oak_lab")
	assert_eq(roster.get_errors().size(), 0)
	var expected: Dictionary[StringName, StringName] = {
		&"bulbasaur": &"calm", &"charmander": &"eager", &"squirtle": &"playful",
	}
	for id: StringName in expected:
		assert_eq(roster.get_spec(id).hop_style, expected[id], String(id))


func test_one_invalid_entry_keeps_the_others() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({
		"good": {"cell": [1, 2], "sprite": "x"},
		"bad": {"cell": [1], "sprite": "x"},
	}, "test"))
	assert_push_error_count(1)
	assert_not_null(roster.get_spec(&"good"))
	assert_null(roster.get_spec(&"bad"))


# --- Présence conditionnelle et validation d'une entrée (jalon 3B §2.6) ------------------

func _flags(names: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func test_if_and_unless_are_read() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({
		"oak": {"cell": [8, 4], "sprite": "oak", "if": ["oak_met"]},
		"rival": {"cell": [13, 4], "sprite": "rival", "unless": ["oak_met", "x"]},
		"maya": {"cell": [5, 3], "sprite": "maya"},
	}, "test"))
	var oak := roster.get_spec(&"oak")
	assert_eq(oak.if_flags, [&"oak_met"] as Array[StringName])
	assert_true(oak.unless_flags.is_empty())
	assert_true(oak.is_conditional())
	assert_eq(roster.get_spec(&"rival").unless_flags, [&"oak_met", &"x"] as Array[StringName])
	assert_false(roster.get_spec(&"maya").is_conditional())


func test_is_present() -> void:
	var spec := NpcSpec.new()
	assert_true(spec.is_present(null), "sans condition : toujours là")
	assert_true(spec.is_present(_flags([&"oak_met"])))
	spec.if_flags = [&"oak_met"] as Array[StringName]
	assert_false(spec.is_present(null), "nouvelle partie : aucun drapeau")
	assert_false(spec.is_present(_flags()))
	assert_true(spec.is_present(_flags([&"oak_met"])))
	spec.unless_flags = [&"starter_chosen"] as Array[StringName]
	assert_false(spec.is_present(_flags([&"oak_met", &"starter_chosen"])))
	var gone := NpcSpec.new()
	gone.unless_flags = [&"oak_met"] as Array[StringName]
	assert_true(gone.is_present(null))
	assert_false(gone.is_present(_flags([&"oak_met"])))


func test_get_present_keeps_file_order() -> void:
	var roster := NpcRoster.new()
	roster.add_from_dict({
		"maya": {"cell": [5, 3], "sprite": "maya"},
		"oak": {"cell": [8, 4], "sprite": "oak", "if": ["oak_met"]},
		"rival_home": {"cell": [13, 4], "sprite": "rival", "unless": ["oak_met"]},
		"rival_lab": {"cell": [9, 6], "sprite": "rival", "if": ["oak_met"]},
	}, "test")
	var ids := func(specs: Array[NpcSpec]) -> Array[StringName]:
		var result: Array[StringName] = []
		for spec: NpcSpec in specs:
			result.append(spec.id)
		return result
	assert_eq(ids.call(roster.get_present(null)), [&"maya", &"rival_home"] as Array[StringName])
	assert_eq(ids.call(roster.get_present(_flags([&"oak_met"]))),
		[&"maya", &"oak", &"rival_lab"] as Array[StringName])
	assert_eq(roster.size(), 4, "toutes les entrées restent connues")


func test_invalid_conditions_are_rejected() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({
		"a": {"cell": [1, 2], "sprite": "x", "if": "oak_met"},
		"b": {"cell": [1, 2], "sprite": "x", "unless": []},
		"c": {"cell": [1, 2], "sprite": "x", "if": [""]},
		"d": {"cell": [1, 2], "sprite": "x", "unless": [3]},
	}, "test"))
	assert_push_error_count(4)
	assert_eq(roster.size(), 0)


func test_player_id_is_reserved() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({"player": {"cell": [1, 2], "sprite": "x"}}, "test"))
	assert_push_error("réservé au joueur")
	assert_eq(roster.size(), 0)


func test_parse_entry_reports_errors_without_signalling_them() -> void:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry({"cell": [24, 13], "sprite": "oak", "facing": "up"},
		errors)
	assert_true(errors.is_empty())
	assert_eq(spec.cell, Vector2i(24, 13))
	assert_eq(spec.facing, Vector2i.UP)
	assert_eq(spec.sprite, &"oak")
	assert_eq(spec.id, &"", "l'identifiant est renseigné par l'appelant")
	assert_null(NpcRoster.parse_entry({"cell": [1], "sprite": "", "lift": -1}, errors))
	assert_eq(errors.size(), 3, "une erreur par problème")
	assert_null(NpcRoster.parse_entry("oak", errors))
	assert_eq(errors.size(), 4)
	assert_push_error_count(0, "c'est l'appelant qui signale")


## Réactions d'ambiance « shy » (jalon 5 §3.5).
func test_shy_defaults_and_values() -> void:
	var errors := PackedStringArray()
	var none := NpcRoster.parse_entry({"cell": [1, 2], "sprite": "pidgey"}, errors)
	assert_eq(none.shy_action, &"", "aucune réaction par défaut")
	assert_false(none.is_shy())
	var fly := NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "pidgey", "shy": {"action": "fly"}}, errors)
	assert_eq(fly.shy_action, &"fly")
	assert_eq(fly.shy_radius, NpcSpec.SHY_RADIUS_DEFAULT, "rayon 2 par défaut")
	assert_true(fly.is_shy())
	var flee := NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "rattata", "shy": {"action": "flee", "radius": 4}}, errors)
	assert_eq(flee.shy_action, &"flee")
	assert_eq(flee.shy_radius, 4)
	assert_true(errors.is_empty(), "\n".join(errors))


func test_shy_invalid_values_are_rejected() -> void:
	var errors := PackedStringArray()
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "x", "shy": "fly"}, errors), "shy doit être un objet")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "x", "shy": {"action": "jump"}}, errors), "action inconnue")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "x", "shy": {"action": "fly", "radius": 0}}, errors),
		"rayon < 1")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "x", "shy": {"action": "fly", "radius": 5}}, errors),
		"rayon > 4")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "x", "shy": {"action": "fly", "who": 1}}, errors),
		"clé inconnue dans shy")
	assert_eq(errors.size(), 5, "une erreur par problème")
	assert_push_error_count(0, "parse_entry ne signale pas")


func test_shy_is_refused_on_an_interactive_npc() -> void:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry(
		{"cell": [1, 2], "sprite": "pidgey", "dialogue": "hello", "shy": {"action": "fly"}},
		errors)
	assert_null(spec, "un Pokémon qui fuit ne se parle pas")
	assert_string_contains("\n".join(errors), "interdit sur un PNJ interactif")


func test_is_cell() -> void:
	assert_true(NpcRoster.is_cell([0, 0]))
	assert_true(NpcRoster.is_cell([24.0, 13.0]))
	assert_false(NpcRoster.is_cell([1]))
	assert_false(NpcRoster.is_cell([1, -1]))
	assert_false(NpcRoster.is_cell([1.5, 2]))
	assert_false(NpcRoster.is_cell("1, 2"))


# --- Routine de marche (jalon 5, le Voyageur, dossier-07 §5) -------------------------

func test_route_defaults_and_values() -> void:
	var errors := PackedStringArray()
	var none := NpcRoster.parse_entry({"cell": [1, 2], "sprite": "npc"}, errors)
	assert_false(none.has_route(), "aucune routine par défaut")
	assert_eq(none.route_pause, NpcSpec.ROUTE_PAUSE_DEFAULT)
	var walker := NpcRoster.parse_entry({
		"cell": [5, 5], "sprite": "npc", "dialogue": "x",
		"route": {"cells": [[5, 5], [5, 6], [5, 7], [5, 6]], "pause": 0.8}}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_true(walker.has_route())
	assert_eq(walker.route_cells.size(), 4)
	assert_eq(walker.route_cells[1], Vector2i(5, 6))
	assert_eq(walker.route_pause, 0.8)


func test_route_default_pause_when_omitted() -> void:
	var errors := PackedStringArray()
	var walker := NpcRoster.parse_entry({
		"cell": [5, 5], "sprite": "npc", "route": {"cells": [[5, 5], [5, 6]]}}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_eq(walker.route_pause, NpcSpec.ROUTE_PAUSE_DEFAULT)


func test_route_invalid_entries_are_rejected() -> void:
	var errors := PackedStringArray()
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 1], "sprite": "x", "route": [[1, 1], [1, 2]]}, errors),
		"route doit être un objet")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 1], "sprite": "x", "route": {"cells": [[1, 1]]}}, errors),
		"au moins deux cases")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 1], "sprite": "x", "route": {"cells": [[1, 1], [3, 3]]}}, errors),
		"cases non voisines")
	assert_null(NpcRoster.parse_entry(
		{"cell": [1, 1], "sprite": "x", "route": {"cells": [[1, 1], [1, 2]], "pause": -1}},
		errors), "pause négative")


func test_route_refused_on_shy_pokemon() -> void:
	var errors := PackedStringArray()
	assert_null(NpcRoster.parse_entry({
		"cell": [1, 1], "sprite": "pidgey", "shy": {"action": "fly"},
		"route": {"cells": [[1, 1], [1, 2]]}}, errors), "shy + route interdit")


func test_real_route_1_traveler_has_a_route() -> void:
	var roster := NpcRoster.load_for_map(&"route_1")
	assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
	var traveler := roster.get_spec(&"traveler")
	assert_not_null(traveler)
	if traveler != null:
		assert_true(traveler.has_route(), "le Voyageur marche")
		assert_true(traveler.is_interactive(), "on peut lui parler")


## Espèce d'un Pokémon du décor à OBSERVER (jalon-06.md §3.5, Q-7).
func test_species_is_read_on_an_observable_pokemon() -> void:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry({"cell": [27, 13], "sprite": "pidgey",
		"dialogue": "observe_aoki_pidgey", "verb": "observe", "species": "pidgey"}, errors)
	assert_true(errors.is_empty(), "\n".join(errors))
	assert_eq(spec.species, &"pidgey")
	assert_true(spec.is_observable_species())
	var plain := NpcRoster.parse_entry({"cell": [1, 1], "sprite": "mom"}, errors)
	assert_eq(plain.species, &"", "aucune espèce par défaut")
	assert_false(plain.is_observable_species())


func test_species_needs_the_observe_verb_and_a_dialogue() -> void:
	var errors := PackedStringArray()
	assert_null(NpcRoster.parse_entry({"cell": [1, 1], "sprite": "pidgey",
		"species": "pidgey"}, errors), "sans dialogue")
	assert_null(NpcRoster.parse_entry({"cell": [1, 1], "sprite": "aoki", "dialogue": "aoki",
		"species": "pidgey"}, errors), "verbe parler")
	assert_null(NpcRoster.parse_entry({"cell": [1, 1], "sprite": "pidgey", "dialogue": "x",
		"verb": "observe", "species": ""}, errors), "identifiant vide")
	assert_null(NpcRoster.parse_entry({"cell": [1, 1], "sprite": "pidgey", "dialogue": "x",
		"verb": "observe", "species": 16}, errors), "pas un identifiant")
	assert_eq(errors.size(), 4)


func test_real_species_exist_in_the_pokemon_data() -> void:
	var data := PokemonData.new()
	data.load_dir()
	for file: String in DirAccess.get_files_at(NpcRoster.DATA_DIR):
		if file.get_extension() != "json":
			continue
		var roster := NpcRoster.load_for_map(StringName(file.get_basename()))
		assert_eq(roster.get_errors().size(), 0, file)
		for spec: NpcSpec in roster.get_all():
			if spec.is_observable_species():
				assert_true(data.has_species(spec.species), "%s : %s" % [file, spec.species])
