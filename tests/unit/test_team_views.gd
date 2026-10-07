extends GutTest
## TeamViews : la vue de l'écran Équipe (jalon-06.md §3.3 ; dossier 08 §2 ; Q-9).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const REAL_SAVE: String = "res://tests/fixtures/save/v1_after_capture.json"

var _data: PokemonData
var _zones: ZoneLibrary
var _state: Node
var _unlocks: MenuUnlocks


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	_state.clock = FixedClock.new("2026-10-02T19:07:52")
	_unlocks = MenuUnlocks.new(_state.flags, _state.party)


func after_each() -> void:
	_state.free()


func _build() -> TeamView:
	return TeamViews.build(_state.party, _data, _zones, _state.pokedex, _unlocks)


func _add(species: StringName, level: int, kind: Pokemon.Origin = Pokemon.Origin.CAPTURE,
		map: StringName = &"route_1") -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, _state.rng)
	_state.party.add(pokemon)
	_state.stamp_meeting(pokemon, kind, map)
	return pokemon


func test_empty_team() -> void:
	var view := _build()
	assert_eq(view.size(), 0)
	assert_null(view.sheet_at(0))
	assert_eq(TeamView.SLOT_COUNT, 6)


func test_members_and_sheets_in_party_order() -> void:
	_add(&"charmander", 6, Pokemon.Origin.STARTER, &"oak_lab")
	_add(&"pidgey", 3)
	var view := _build()
	assert_eq(view.size(), 2)
	assert_eq(view.sheets.size(), 2)
	for i: int in 2:
		assert_eq(view.members[i].party_index, i)
		assert_eq(view.sheet_at(i).member, view.members[i], "la fiche porte le même membre")
		assert_true(view.sheet_at(i).is_valid())
	assert_eq(view.members[0].species_id, &"charmander")
	assert_eq(view.members[1].display_name, "Roucool")


func test_sheet_header_types_and_exp() -> void:
	var charmander := _add(&"charmander", 5, Pokemon.Origin.STARTER, &"oak_lab")
	charmander.experience = 135 + 30
	var sheet := _build().sheet_at(0)
	assert_eq(sheet.species_name, "Salamèche")
	assert_eq(sheet.type_ids, [&"fire"] as Array[StringName])
	assert_eq(sheet.type_names, ["Feu"] as Array[String])
	assert_eq(sheet.exp_text, "30 / 44 XP")
	assert_eq(sheet.exp_remaining_text, "14 XP avant le niveau suivant")
	assert_almost_eq(sheet.exp_fraction, 30.0 / 44.0, 0.0001)
	var pidgey := _add(&"pidgey", 3)
	assert_eq(_build().sheet_at(1).type_ids, [&"normal", &"flying"] as Array[StringName])
	assert_eq(pidgey.level, 3)


func test_exp_at_level_100_has_no_text() -> void:
	_add(&"rattata", 100)
	var sheet := _build().sheet_at(0)
	assert_eq(sheet.exp_text, "")
	assert_eq(sheet.exp_remaining_text, "")
	assert_eq(sheet.exp_fraction, 1.0, "barre pleine")


func test_large_exp_numbers_are_grouped() -> void:
	var raticate := _add(&"raticate", 50)
	var sheet := _build().sheet_at(0)
	var span := ExpCalc.level_span(raticate, _data)
	assert_gt(span.y, 999)
	assert_eq(sheet.exp_text, "0 / %s XP" % MenuFormat.number(span.y))
	assert_true(sheet.exp_text.contains(MenuFormat.THOUSANDS_SEPARATOR))


func test_stats_in_order_with_gauges() -> void:
	var pokemon := _add(&"charmander", 10)
	var stats := _build().sheet_at(0).stats
	var names: Array[String] = []
	var highest := 0
	for stat: StringName in SpeciesData.STATS:
		highest = maxi(highest, pokemon.stats[stat])
	for i: int in stats.size():
		names.append(stats[i].name)
		assert_eq(stats[i].stat_id, SpeciesData.STATS[i])
		assert_eq(stats[i].value, pokemon.stats[SpeciesData.STATS[i]])
		assert_almost_eq(stats[i].ratio, float(stats[i].value) / highest, 0.0001)
	assert_eq(names, ["PV", "Attaque", "Défense", "Atq. Spé.", "Déf. Spé.", "Vitesse"]
		as Array[String])
	assert_eq(stats[0].value, pokemon.max_hp(), "PV = PV max")
	var full := 0
	for stat: StatView in stats:
		if is_equal_approx(stat.ratio, 1.0):
			full += 1
	assert_gt(full, 0, "la plus haute statistique remplit sa jauge")


func test_moves_reuse_the_battle_cards() -> void:
	var pokemon := _add(&"charmander", 9)
	pokemon.moves[0].pp = 3
	var moves := _build().sheet_at(0).moves
	assert_eq(moves.size(), pokemon.moves.size())
	assert_eq(moves[0].display_name, _data.get_move(pokemon.moves[0].move_id).name)
	assert_eq(moves[0].pp, 3)
	for move: BattleMoveView in moves:
		assert_true(move.is_valid())


func test_fainted_status_in_text() -> void:
	var pokemon := _add(&"pidgey", 3)
	pokemon.hp = 0
	var view := _build()
	assert_eq(view.members[0].status_text, "K.O.")
	assert_eq(view.sheet_at(0).member.status_text, "K.O.")
	assert_eq(view.members[0].hp, 0)


func test_favorite_is_shown() -> void:
	_add(&"pidgey", 3)
	_add(&"rattata", 3).favorite = true
	var view := _build()
	assert_false(view.members[0].favorite)
	assert_true(view.members[1].favorite)


func test_history_of_the_starter_in_the_lab_names_the_town() -> void:
	_add(&"charmander", 5, Pokemon.Origin.STARTER, &"oak_lab")
	var history := _build().sheet_at(0).history
	assert_eq(history.note, "Ton premier Pokémon")
	assert_eq(history.place_label, "Reçu à")
	assert_eq(history.place, "Bourg Palette", "le labo : le nom de sa ville (zone)")
	assert_eq(history.met_level, 5)
	assert_eq(history.trainer, "Kevin")
	assert_eq(history.date_text, "2 octobre 2026")
	assert_false(history.is_empty())


func test_history_of_a_capture_on_route_1() -> void:
	_state.clock = FixedClock.new("2026-11-01T08:00:00")
	_add(&"pidgey", 4, Pokemon.Origin.CAPTURE, &"route_1")
	var history := _build().sheet_at(0).history
	assert_eq(history.note, "")
	assert_eq(history.place_label, "Capturé à")
	assert_eq(history.place, "Route 1")
	assert_eq(history.met_level, 4)
	assert_eq(history.date_text, "1er novembre 2026")


func test_history_unknown_before_5c5_is_empty() -> void:
	_state.party.add(PokemonFactory.create(_data, &"squirtle", 5, _state.rng))
	var history := _build().sheet_at(0).history
	assert_true(history.is_empty())
	assert_eq(history.place_label, "Rencontré à")
	assert_eq(history.note, "")
	assert_false(TeamViews.HISTORY_UNKNOWN.is_empty())


func test_history_of_a_map_outside_any_zone_has_no_place() -> void:
	_add(&"pidgey", 3, Pokemon.Origin.CAPTURE, &"nowhere")
	var history := _build().sheet_at(0).history
	assert_eq(history.place, "", "ligne absente plutôt qu'un identifiant")
	assert_eq(TeamViews.history(_state.party.get_lead(), null).place, "", "sans zones")


func test_evolution_follows_the_unlock_rule() -> void:
	_add(&"charmander", 5, Pokemon.Origin.STARTER, &"oak_lab")
	_add(&"rattata", 3)
	_state.pokedex.mark_seen(&"charmeleon")
	assert_eq(_build().sheet_at(0).evolution_text, "???", "Q-9 : avant l'activation")
	_unlocks.debug_pokedex = true
	assert_eq(_build().sheet_at(0).evolution_text, "Salamèche → Reptincel → ???")
	assert_eq(_build().sheet_at(1).evolution_text, "Rattata → ???")
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	_unlocks.debug_pokedex = false
	assert_eq(_build().sheet_at(0).evolution.size(), 3)


func test_no_condition_anywhere_in_the_sheet_evolution() -> void:
	_add(&"bulbasaur", 15)
	for debug: bool in [false, true]:
		_unlocks.debug_pokedex = debug
		var line := _build().sheet_at(0).evolution_text
		assert_false(line.contains("16"), line)
		assert_false(line.contains("Nv"), line)


func test_the_real_save_party() -> void:
	var file := FileAccess.get_file_as_string(REAL_SAVE)
	var party := Party.new()
	assert_true(party.load_array(JSON.parse_string(file)["party"], _data))
	var view := TeamViews.build(party, _data, _zones, Pokedex.new(), _unlocks)
	assert_eq(view.size(), party.size())
	var lead := view.sheet_at(0)
	assert_eq(lead.member.display_name, "Salamèche")
	assert_eq(lead.history.place, "Bourg Palette")
	assert_eq(lead.history.date_text, "2 octobre 2026")
	assert_eq(lead.history.note, "Ton premier Pokémon")
	for sheet: PokemonSheetView in view.sheets:
		assert_true(sheet.is_valid())
		assert_false(sheet.history.is_empty())


func test_selection_after_swap_follows_the_selected_pokemon() -> void:
	assert_eq(TeamViews.selection_after_swap(0, 0, 2), 2)
	assert_eq(TeamViews.selection_after_swap(2, 0, 2), 0)
	assert_eq(TeamViews.selection_after_swap(1, 0, 2), 1)
	assert_eq(TeamViews.clamp_selection(5, 3), 2)
	assert_eq(TeamViews.clamp_selection(-1, 3), 0)
	assert_eq(TeamViews.clamp_selection(2, 0), 0)


func test_storage_button_only_inside_a_center() -> void:
	_add(&"charmander", 5, Pokemon.Origin.STARTER, &"oak_lab")
	assert_false(_build().storage_available, "sans lieu branché")
	var zones := ZoneLibrary.new()
	assert_true(zones.add_from_dict({
		"services": {"pokemon_center": {"name": "Centre Pokémon"}},
		"zones": {"v": {"name": "Jadielle", "kind": "town", "maps": ["v", "v_center"],
			"services": [{"id": "pokemon_center", "found_on": "v_center"}]}},
	}, "t"))
	var where := {"map": &"v"}
	_unlocks.set_location(zones, func() -> StringName: return where["map"])
	assert_false(_build().storage_available, "dans la ville : absent")
	where["map"] = &"v_center"
	assert_true(_build().storage_available, "au Centre : bouton STOCKAGE")


func test_poisoned_status_reads_psn_and_ko_wins() -> void:
	var pokemon := _add(&"pidgey", 3)
	pokemon.status = StatusRules.POISON
	var view := _build()
	assert_eq(view.members[0].status_text, "PSN")
	assert_eq(view.sheet_at(0).member.status_text, "PSN", "la fiche lit le même statut")
	pokemon.hp = 0
	assert_eq(_build().members[0].status_text, "K.O.", "K.O. d'abord")
