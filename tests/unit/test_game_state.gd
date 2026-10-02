extends GutTest
## Autoload GameState (jalon 3A §2.6) : drapeaux de la session, nouvelle partie, aucune
## dépendance à un autre autoload. Jalon 4 (§3.9, T1) : équipe, starter, aléatoire à graine.
## Jalon 4B (§14.6) : le Sac. Jalon 5 (§16) : faits pour le J6 ; l'aller-retour complet de la
## sauvegarde est dans test_save_system.gd.

const SCRIPT_PATH := "res://game/autoload/game_state.gd"
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")


func _make() -> Node:
	return autofree((load(SCRIPT_PATH) as GDScript).new())


func test_starts_with_empty_flags() -> void:
	var state := _make()
	assert_true(state.flags is StoryFlags)
	assert_eq(state.flags.to_array().size(), 0)


func test_new_game_clears_flags() -> void:
	var state := _make()
	state.flags.set_flag(&"mom_greeted")
	state.flags.set_flag(&"rival_met")
	state.new_game()
	assert_false(state.flags.has_flag(&"mom_greeted"))
	assert_false(state.flags.has_flag(&"rival_met"))
	assert_eq(state.flags.to_array().size(), 0)


func test_new_game_keeps_same_flags_instance() -> void:
	# Les systèmes reçoivent GameState.flags par injection : l'instance ne change pas.
	var state := _make()
	var flags: StoryFlags = state.flags
	state.new_game()
	assert_same(state.flags, flags)


func test_does_not_reference_scene_router() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	assert_false(source.contains("SceneRouter"), "aucune référence au routeur")
	assert_false(source.contains("scene_router"), "aucune référence au routeur")


func test_does_not_reference_any_other_autoload() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = setting["name"]
		if not key.begins_with("autoload/") or key == "autoload/GameState":
			continue
		var autoload := key.trim_prefix("autoload/")
		assert_false(source.contains(autoload), "aucune référence à %s" % autoload)


func test_starts_with_empty_party_no_starter_and_a_rng() -> void:
	var state := _make()
	assert_true(state.party is Party)
	assert_eq(state.party.size(), 0)
	assert_eq(state.starter_species, &"")
	assert_true(state.rng is GameRng)


func test_new_game_clears_party_and_starter() -> void:
	var state := _make()
	var party: Party = state.party
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	state.party.add(PokemonFactory.create(data, &"bulbasaur", 5, GameRng.new(1)))
	state.starter_species = &"bulbasaur"
	assert_eq(state.party.size(), 1)
	state.new_game()
	assert_eq(state.party.size(), 0, "équipe vide")
	assert_same(state.party, party, "même instance d'équipe (injectée)")
	assert_eq(state.starter_species, &"", "pas de starter")


func test_starts_with_an_empty_bag_and_new_game_empties_it() -> void:
	var state := _make()
	assert_true(state.bag is Bag)
	assert_true(state.bag.is_empty())
	var bag: Bag = state.bag
	state.bag.add(&"poke_ball", 5)
	state.new_game()
	assert_true(state.bag.is_empty(), "Sac vide")
	assert_same(state.bag, bag, "même instance de Sac (injectée)")


func test_starts_with_an_empty_pokedex_and_new_game_empties_it() -> void:
	var state := _make()
	assert_true(state.pokedex is Pokedex)
	assert_eq(state.pokedex.seen_count(), 0)
	var dex: Pokedex = state.pokedex
	state.pokedex.mark_caught(&"pidgey")
	state.new_game()
	assert_eq(state.pokedex.seen_count(), 0, "Pokédex vidé")
	assert_eq(state.pokedex.caught_count(), 0)
	assert_same(state.pokedex, dex, "même instance de Pokédex (injectée)")


func test_new_game_changes_the_seed() -> void:
	var state := _make()
	var seeds := {}
	var before: GameRng = state.rng
	for i: int in 5:
		state.new_game()
		seeds[state.rng.get_seed()] = true
	assert_ne(state.rng, before, "aléatoire neuf")
	assert_gt(seeds.size(), 1, "graines tirées au hasard")


func test_new_game_with_a_seed_is_reproducible() -> void:
	var state := _make()
	state.new_game(42)
	assert_eq(state.rng.get_seed(), 42)
	var first: Array[int] = []
	for i: int in 5:
		first.append(state.rng.roll(100))
	state.new_game(42)
	assert_eq(state.rng.get_seed(), 42, "même graine")
	var second: Array[int] = []
	for i: int in 5:
		second.append(state.rng.roll(100))
	assert_eq(second, first, "mêmes tirages")


# --- Faits pour le J6 (jalon 5 §16.3) --------------------------------------------------------

func _dated() -> Node:
	var state := _make()
	state.clock = FixedClock.new("2026-10-02T14:03:05")
	state.new_game(1)
	return state


func test_new_game_starts_the_adventure_now_with_default_name_and_no_facts() -> void:
	var state := _dated()
	assert_eq(state.player_name, "Kevin")
	assert_eq(state.started_at, "2026-10-02T14:03:05")
	assert_eq(state.play_time, 0.0)
	assert_eq(state.current_map, &"")
	assert_eq(state.player_facing, Vector2i.DOWN)
	assert_eq(state.discovered_maps.size(), 0)
	assert_eq(state.found_items.size(), 0)
	assert_eq(state.moments.size(), 0)


func test_new_game_resets_every_fact() -> void:
	var state := _dated()
	state.player_name = "Rouge"
	state.add_play_time(10.0)
	state.set_player_location(&"route_1", Vector2i(3, 4), Vector2i.LEFT)
	state.heal_map = &"viridian_center"
	state.discover_map(&"route_1")
	state.record_item_found(&"potion", &"route_1")
	state.record_moment(state.MOMENT_STARTER, &"oak_lab")
	state.clock.iso = "2027-01-01T00:00:00"
	state.new_game()
	assert_eq(state.player_name, "Kevin")
	assert_eq(state.play_time, 0.0)
	assert_eq(state.started_at, "2027-01-01T00:00:00", "nouvelle aventure, nouvelle date")
	assert_eq(state.current_map, &"")
	assert_eq(state.player_cell, Vector2i.ZERO)
	assert_eq(state.player_facing, Vector2i.DOWN)
	assert_eq(state.heal_map, &"player_house_1f")
	assert_eq(state.discovered_maps.size(), 0)
	assert_eq(state.found_items.size(), 0)
	assert_eq(state.moments.size(), 0)


func test_play_time_only_grows() -> void:
	var state := _dated()
	state.add_play_time(1.5)
	state.add_play_time(-3.0)
	state.add_play_time(0.0)
	state.add_play_time(2.0)
	assert_eq(state.play_time, 3.5)


func test_discover_map_dates_the_first_visit_only() -> void:
	var state := _dated()
	assert_true(state.discover_map(&"pallet_town"))
	state.clock.iso = "2026-10-03T09:00:00"
	assert_false(state.discover_map(&"pallet_town"), "déjà découverte")
	assert_false(state.discover_map(&""))
	assert_eq(state.discovered_maps[&"pallet_town"], "2026-10-02T14:03:05")
	assert_eq(state.discovered_maps.size(), 1)


func test_record_item_found_and_moments_are_append_only_and_dated() -> void:
	var state := _dated()
	state.record_item_found(&"potion", &"route_1")
	state.record_item_found(&"", &"route_1")
	assert_eq(state.found_items, [{"item": "potion", "map": "route_1",
		"date": "2026-10-02T14:03:05"}] as Array[Dictionary])
	var details := {"species": "charmander"}
	state.record_moment(state.MOMENT_STARTER, &"oak_lab", details)
	details["species"] = "modifié après"
	state.clock.iso = "2026-10-02T15:00:00"
	state.record_moment(state.MOMENT_RIVAL_BATTLE, &"oak_lab", {"outcome": "win"})
	state.record_moment(&"", &"oak_lab")
	assert_eq(state.moments.size(), 2)
	assert_eq(state.moments[0], {"type": "starter", "date": "2026-10-02T14:03:05",
		"map": "oak_lab", "details": {"species": "charmander"}})
	assert_eq(state.moments[1]["type"], "rival_battle")
	assert_eq(state.moments[1]["date"], "2026-10-02T15:00:00")


func test_record_seen_and_caught_date_the_pokedex() -> void:
	var state := _dated()
	assert_true(state.record_seen(&"pidgey", &"route_1"))
	assert_false(state.record_seen(&"pidgey", &"route_1"))
	assert_true(state.record_caught(&"pidgey", &"route_1"))
	var entry: PokedexEntry = state.pokedex.get_entry(&"pidgey")
	assert_eq(entry.first_seen_date, "2026-10-02T14:03:05")
	assert_eq(entry.first_caught_map, &"route_1")
	assert_eq(entry.times_seen, 2)


func test_stamp_meeting_uses_the_player_name_the_date_and_the_level() -> void:
	var state := _dated()
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var charmander := PokemonFactory.create(data, &"charmander", 5, GameRng.new(1))
	state.stamp_meeting(charmander, Pokemon.Origin.STARTER, &"oak_lab")
	assert_eq(charmander.origin, Pokemon.Origin.STARTER)
	assert_eq(charmander.met_map, &"oak_lab")
	assert_eq(charmander.met_level, 5)
	assert_eq(charmander.met_date, "2026-10-02T14:03:05")
	assert_eq(charmander.original_trainer, "Kevin")
	state.stamp_meeting(null, Pokemon.Origin.CAPTURE, &"route_1")
	pass_test("un Pokémon null est ignoré")


func test_to_dict_lists_every_saved_field_and_nothing_else() -> void:
	# §16.2 + §16.3 ; pas d'argent, de badges ni de statistiques (§16.3 « pas stocké »).
	var keys: Array = _dated().to_dict().keys()
	keys.sort()
	assert_eq(keys, ["bag", "cell", "discovered_maps", "facing", "flags", "found_items",
		"heal_map", "heal_spawn", "map", "moments", "party", "play_time", "player_name",
		"pokedex", "rng", "started_at", "starter", "storage"])


func test_starts_with_an_empty_storage_and_new_game_empties_it() -> void:
	# Jalon 5D : le « système de recherche de Chen » (équipe pleine).
	var state := _make()
	assert_true(state.storage is PokemonStorage)
	assert_true(state.storage.is_empty())
	var storage: PokemonStorage = state.storage
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	state.storage.add(PokemonFactory.create(data, &"pidgey", 3, GameRng.new(1)))
	state.new_game()
	assert_true(state.storage.is_empty(), "stockage vidé")
	assert_same(state.storage, storage, "même instance (injectée)")


func test_registered_as_autoload() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/GameState"), "*" + SCRIPT_PATH)
	assert_not_null(get_tree().root.get_node_or_null(^"GameState"))
