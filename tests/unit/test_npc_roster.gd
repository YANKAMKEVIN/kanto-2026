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
		"bad_verb": {"cell": [1, 2], "sprite": "x", "verb": "smell"},
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
	assert_string_contains(errors, "« meet_verb » : « verb » vaut talk, observe, take ou examine")
	assert_string_contains(errors, "« hop_style » vaut calm, eager, playful")


func test_take_verb_for_an_object_on_the_ground() -> void:
	# Jalon 8 §2.3 : un objet visible au sol est un PNJ « take » (PRENDRE).
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({"ball": {"cell": [10, 53], "facing": "down",
		"sprite": "object/poke_ball_ground", "dialogue": "route_2_ball_1", "verb": "take",
		"turn_to_player": false, "unless": ["got_route_2_item_1"]}}, "test"))
	var spec := roster.get_spec(&"ball")
	assert_eq(spec.verb, Interaction.Kind.TAKE)
	assert_eq(spec.sprite, &"object/poke_ball_ground")
	var interaction := spec.make_interaction(spec.cell, null)
	assert_eq(interaction.kind, Interaction.Kind.TAKE)
	assert_eq(Interaction.kind_name(interaction.kind), &"take")


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


## Jalon 9 (T18, jalon-09.md §2.7.6) : Chenipan relève la tête (« notice », reste), Aspicot se
## rétracte (« hide », quitte la carte) ; mêmes règles que « fly » / « flee » (non interactif,
## sans routine).
func test_notice_and_hide_are_shy_actions() -> void:
	var errors := PackedStringArray()
	var notice := NpcRoster.parse_entry({"cell": [1, 2], "sprite": "pokemon/caterpie",
		"shy": {"action": "notice"}}, errors)
	assert_eq(notice.shy_action, &"notice")
	assert_eq(notice.shy_radius, 2)
	var hide := NpcRoster.parse_entry({"cell": [1, 2], "sprite": "pokemon/weedle",
		"lift": 32, "shy": {"action": "hide", "radius": 1}}, errors)
	assert_eq([hide.shy_action, hide.shy_radius, hide.lift], [&"hide", 1, 32])
	assert_true(errors.is_empty(), "\n".join(errors))
	assert_null(NpcRoster.parse_entry({"cell": [1, 2], "sprite": "pokemon/weedle",
		"dialogue": "hello", "shy": {"action": "hide"}}, errors), "interactif : refusé")
	assert_null(NpcRoster.parse_entry({"cell": [1, 2], "sprite": "pokemon/caterpie",
		"shy": {"action": "notice"}, "route": {"cells": [[1, 2], [1, 3]]}}, errors),
		"routine : refusée")
	assert_eq(errors.size(), 2)


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
		assert_eq(traveler.route_start, 1, "sans « start » : la case du Voyageur dans la boucle")
		assert_false(traveler.enters_building())
		assert_false(traveler.has_idle_react())


# --- Jalon 7 (T2) : départ dans la boucle, entrée dans un bâtiment, animation d'ambiance ---

## Le Rattata part un pas derrière l'enfant, sur la même boucle (dossier 09 §2).
const _LOOP: Array = [[5, 5], [6, 5], [7, 5], [7, 6], [6, 6], [5, 6]]


func test_route_start_and_enter() -> void:
	var errors := PackedStringArray()
	var child := NpcRoster.parse_entry({"cell": [6, 5], "sprite": "npc",
		"route": {"cells": _LOOP, "start": 1}}, errors)
	var rattata := NpcRoster.parse_entry({"cell": [5, 5], "sprite": "rattata",
		"route": {"cells": _LOOP, "start": 0}}, errors)
	var courier := NpcRoster.parse_entry({"cell": [7, 6], "sprite": "npc", "dialogue": "x",
		"route": {"cells": _LOOP, "pause": 0.5, "start": 3,
			"enter": {"cell": [7, 5], "seconds": 8}}}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_eq(child.route_start, 1)
	assert_eq(rattata.route_start, 0, "un pas derrière l'enfant")
	assert_false(child.enters_building(), "pas d'entrée par défaut")
	assert_eq(child.route_enter_cell, NpcSpec.NO_ENTER_CELL)
	assert_eq(child.route_enter_seconds, 0.0)
	assert_eq(courier.route_start, 3)
	assert_true(courier.enters_building())
	assert_eq(courier.route_enter_cell, Vector2i(7, 5))
	assert_eq(courier.route_enter_seconds, 8.0)


func test_route_start_defaults_to_the_cell_in_the_loop() -> void:
	var errors := PackedStringArray()
	var inside := NpcRoster.parse_entry({"cell": [7, 6], "sprite": "npc",
		"route": {"cells": _LOOP}}, errors)
	var outside := NpcRoster.parse_entry({"cell": [9, 9], "sprite": "npc",
		"route": {"cells": _LOOP}}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_eq(inside.route_start, 3)
	assert_eq(outside.route_start, 0, "hors de la boucle : 0, comme au jalon 5")
	assert_eq(NpcSpec.new().route_start, 0)


func test_invalid_route_start_and_enter_are_rejected() -> void:
	var bad: Array[Dictionary] = [
		{"cells": _LOOP, "start": 6},
		{"cells": _LOOP, "start": -1},
		{"cells": _LOOP, "start": 1.5},
		{"cells": _LOOP, "start": "1"},
		{"cells": _LOOP, "start": 2},
		{"cells": _LOOP, "enter": [7, 5]},
		{"cells": _LOOP, "enter": {"cell": [9, 9], "seconds": 8}},
		{"cells": _LOOP, "enter": {"cell": [7, 5]}},
		{"cells": _LOOP, "enter": {"cell": [7, 5], "seconds": 0}},
		{"cells": _LOOP, "enter": {"cell": [7, 5], "seconds": 121}},
		{"cells": _LOOP, "enter": {"cell": [7, 5], "seconds": 8, "fade": 1}},
		{"cells": _LOOP, "enter": {"cell": "door", "seconds": 8}},
		{"cells": _LOOP, "loop": true},
	]
	var messages := PackedStringArray()
	for route: Dictionary in bad:
		var errors := PackedStringArray()
		assert_null(NpcRoster.parse_entry({"cell": [6, 5], "sprite": "npc", "route": route},
			errors), str(route))
		messages.append_array(errors)
	var all := "\n".join(messages)
	for expected: String in ["« route.start » doit être un index", "n'est pas « cell »",
			"« route.enter » doit être un objet", "n'appartient pas à la boucle",
			"« route.enter.seconds »", "clé inconnue dans « route.enter » : « fade »",
			"« route.enter.cell » doit être [x, y]", "clé inconnue dans « route » : « loop »"]:
		assert_string_contains(all, expected)


func test_idle_react() -> void:
	var errors := PackedStringArray()
	var pidgey := NpcRoster.parse_entry({"cell": [3, 3], "sprite": "pidgey",
		"idle_react": 6.0}, errors)
	var still := NpcRoster.parse_entry({"cell": [3, 3], "sprite": "pidgey"}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_true(pidgey.has_idle_react())
	assert_eq(pidgey.idle_react_every, 6.0)
	assert_false(still.has_idle_react(), "aucune par défaut")
	assert_eq(still.idle_react_every, 0.0)
	for value: Variant in [0, -1, 121, "6"]:
		var refused := PackedStringArray()
		assert_null(NpcRoster.parse_entry({"cell": [3, 3], "sprite": "pidgey",
			"idle_react": value}, refused), str(value))
		assert_string_contains("\n".join(refused), "« idle_react »")
	var shy := PackedStringArray()
	assert_null(NpcRoster.parse_entry({"cell": [3, 3], "sprite": "pidgey",
		"shy": {"action": "fly"}, "idle_react": 6}, shy))
	assert_string_contains("\n".join(shy), "« idle_react » interdit sur un Pokémon « shy »")


## Attente animée (Jadielle agrandie : aucun habitant figé).
func test_look_around() -> void:
	var errors := PackedStringArray()
	var guard := NpcRoster.parse_entry({"cell": [3, 3], "sprite": "youngster",
		"look": {"facings": ["up", "left", "up", "right"], "every": 2.5}}, errors)
	var default_every := NpcRoster.parse_entry({"cell": [3, 3], "sprite": "lass",
		"look": {"facings": ["right", "down"]}}, errors)
	var still := NpcRoster.parse_entry({"cell": [3, 3], "sprite": "lass"}, errors)
	assert_eq(errors.size(), 0, str(errors))
	assert_true(guard.has_look())
	assert_eq(guard.look_facings, [Vector2i.UP, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT])
	assert_eq(guard.look_every, 2.5)
	assert_eq(default_every.look_every, NpcSpec.LOOK_EVERY_DEFAULT)
	assert_false(still.has_look(), "aucune par défaut")
	var cases := {
		"« look » doit être": "up",
		"au moins deux orientations": {"facings": ["up"]},
		"down, up, left ou right": {"facings": ["up", "north"]},
		"« look.every »": {"facings": ["up", "down"], "every": 0.1},
		"clé inconnue « speed »": {"facings": ["up", "down"], "speed": 2},
	}
	for expected: String in cases:
		var refused := PackedStringArray()
		assert_null(NpcRoster.parse_entry({"cell": [3, 3], "sprite": "lass",
			"look": cases[expected]}, refused), expected)
		assert_string_contains("\n".join(refused), expected)
	var walker := PackedStringArray()
	assert_null(NpcRoster.parse_entry({"cell": [3, 3], "sprite": "lass",
		"route": {"cells": [[3, 3], [4, 3]]}, "look": {"facings": ["up", "down"]}}, walker))
	assert_string_contains("\n".join(walker), "« look » interdit avec « route »")


func test_roster_file_reads_the_jalon_7_keys() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({
		"child": {"cell": [6, 5], "sprite": "npc", "route": {"cells": _LOOP, "start": 1}},
		"trainer_pidgey": {"cell": [2, 2], "sprite": "pidgey", "idle_react": 6},
	}, "test"), str(roster.get_errors()))
	assert_eq(roster.get_spec(&"child").route_start, 1)
	assert_eq(roster.get_spec(&"trainer_pidgey").idle_react_every, 6.0)


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


# --- Jalon 9 (jalon-09.md §2.4.1) : bloc « trainer » -------------------------------------

const _THEO: Dictionary = {
	"cell": [5, 2], "facing": "down", "sprite": "scout", "dialogue": "forest_scout_theo_after",
	"trainer": {"id": "forest_scout_theo", "sight": 4, "before": "forest_scout_theo_before"},
}


func _theo_with(changes: Dictionary, removed: Array[String] = []) -> Dictionary:
	var entry := _THEO.duplicate(true)
	entry.merge(changes, true)
	for key: String in removed:
		entry.erase(key)
	return entry


func test_trainer_block_is_read() -> void:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry(_THEO, errors)
	assert_true(errors.is_empty(), "\n".join(errors))
	assert_true(spec.is_trainer())
	assert_eq(spec.trainer_id, &"forest_scout_theo")
	assert_eq(spec.sight, 4)
	assert_eq(spec.before_dialogue, &"forest_scout_theo_before")
	assert_eq(spec.dialogue, &"forest_scout_theo_after", "réplique « après »")
	assert_eq(spec.facing, Vector2i.DOWN)
	var plain := NpcRoster.parse_entry({"cell": [1, 1], "sprite": "mom"}, errors)
	assert_false(plain.is_trainer(), "pas un Dresseur par défaut")
	assert_eq(plain.sight, 0)


func test_trainer_sight_bounds() -> void:
	for sight: int in [TrainerRules.SIGHT_MIN, TrainerRules.SIGHT_MAX]:
		var errors := PackedStringArray()
		var entry := _THEO.duplicate(true)
		entry["trainer"]["sight"] = sight
		assert_not_null(NpcRoster.parse_entry(entry, errors), "vision %d" % sight)
	assert_eq([TrainerRules.SIGHT_MIN, TrainerRules.SIGHT_MAX], [0, 8], "J25 : 0 = on lui parle")


func test_invalid_trainer_blocks_are_rejected() -> void:
	var bad: Array[Dictionary] = []
	for block: Variant in [
		"forest_scout_theo",
		{"id": "forest_scout_theo", "sight": 4},
		{"id": "", "sight": 4, "before": "b"},
		{"sight": 4, "before": "b"},
		{"id": "t", "sight": -1, "before": "b"},
		{"id": "t", "sight": 9, "before": "b"},
		{"id": "t", "sight": 2.5, "before": "b"},
		{"id": "t", "sight": "4", "before": "b"},
		{"id": "t", "sight": 4, "before": "b", "after": "a"},
	]:
		bad.append(_theo_with({"trainer": block}))
	bad.append(_theo_with({}, ["facing"]))
	bad.append(_theo_with({}, ["dialogue"]))
	bad.append(_theo_with({"verb": "observe"}))
	bad.append(_theo_with({"route": {"cells": [[5, 2], [5, 3]]}}))
	bad.append(_theo_with({"look": {"facings": ["down", "left"]}}))
	bad.append(_theo_with({"idle_react": 4}))
	bad.append(_theo_with({"shy": {"action": "flee"}}, ["dialogue"]))
	for i: int in bad.size():
		var errors := PackedStringArray()
		assert_null(NpcRoster.parse_entry(bad[i], errors), "%d : %s" % [i, bad[i]])
		assert_false(errors.is_empty(), str(i))
	var errors := PackedStringArray()
	NpcRoster.parse_entry(_theo_with({}, ["facing"]), errors)
	assert_string_contains("\n".join(errors), "exige « facing »")
	errors.clear()
	NpcRoster.parse_entry(_theo_with({"look": {"facings": ["down", "left"]}}), errors)
	assert_string_contains("\n".join(errors), "« look » interdit sur un Dresseur")


## Jalon 10 (jalon-10.md §2.5) : réplique « vaincu » facultative du bloc « trainer ».
func test_trainer_defeated_line_is_optional() -> void:
	var errors := PackedStringArray()
	assert_eq(NpcRoster.parse_entry(_THEO, errors).defeated_dialogue, &"", "absente : &\"\"")
	var block: Dictionary = (_THEO["trainer"] as Dictionary).duplicate()
	block["defeated"] = "forest_scout_theo_defeated"
	var spec := NpcRoster.parse_entry(_theo_with({"trainer": block}), errors)
	assert_true(errors.is_empty(), "\n".join(errors))
	assert_eq(spec.defeated_dialogue, &"forest_scout_theo_defeated")
	assert_eq(spec.dialogue, &"forest_scout_theo_after", "la réplique « après » reste")
	for bad: Variant in ["", 3, ["x"]]:
		block["defeated"] = bad
		errors.clear()
		assert_null(NpcRoster.parse_entry(_theo_with({"trainer": block}), errors), str(bad))
		assert_string_contains("\n".join(errors), "« trainer.defeated » doit être un identifiant")


## Données réelles : chaque Dresseur posé sur une carte existe dans data/trainers/ et ses deux
## répliques dans data/dialogues/ (aucun fichier n'en pose avant le T12 : vrai à vide).
func test_real_trainers_exist_with_their_dialogues() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	assert_not_null(trainers.get_trainer(&"forest_scout_theo"), "données des Dresseurs lues")
	for file: String in DirAccess.get_files_at(NpcRoster.DATA_DIR):
		if file.get_extension() != "json":
			continue
		for spec: NpcSpec in NpcRoster.load_for_map(StringName(file.get_basename())).get_all():
			if not spec.is_trainer():
				continue
			assert_not_null(trainers.get_trainer(spec.trainer_id), "%s : %s" % [file, spec.id])
			for dialogue: StringName in [spec.before_dialogue, spec.dialogue]:
				assert_true(dialogues.has_dialogue(dialogue), "%s : %s" % [file, dialogue])
			if not spec.defeated_dialogue.is_empty():
				assert_true(dialogues.has_dialogue(spec.defeated_dialogue), "%s : %s" % [file,
					spec.defeated_dialogue])
