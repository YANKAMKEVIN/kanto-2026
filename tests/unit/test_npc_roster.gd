extends GutTest
## NpcRoster et NpcSpec : format de data/npcs/<map_id>.json, valeurs par défaut,
## validation (jalon 3 §2.3).

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
		"not_object": "mom",
	}, "test"))
	assert_push_error_count(10)
	assert_eq(roster.size(), 0)
	assert_eq(roster.get_errors().size(), 10)


func test_one_invalid_entry_keeps_the_others() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({
		"good": {"cell": [1, 2], "sprite": "x"},
		"bad": {"cell": [1], "sprite": "x"},
	}, "test"))
	assert_push_error_count(1)
	assert_not_null(roster.get_spec(&"good"))
	assert_null(roster.get_spec(&"bad"))
