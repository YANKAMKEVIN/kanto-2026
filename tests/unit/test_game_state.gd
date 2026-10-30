extends GutTest
## Autoload GameState (jalon 3A §2.6) : drapeaux de la session, nouvelle partie, aucune
## dépendance à un autre autoload. Jalon 4 (§3.9, T1) : équipe, starter, aléatoire à graine.
## Jalon 4B (§14.6) : le Sac. Jalon 5 (§16) : faits pour le J6 ; l'aller-retour complet de la
## sauvegarde est dans test_save_system.gd.

const SCRIPT_PATH := "res://game/autoload/game_state.gd"
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")


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
	state.add_money(500)
	state.record_wild_encounter(&"pidgey", &"route_1")
	state.clock.iso = "2027-01-01T00:00:00"
	state.new_game()
	assert_eq(state.money, 3000, "argent de départ")
	assert_eq(state.first_wild_encounter, {}, "aucune rencontre sauvage")
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


## Évolution (jalon-09.md §2.3.2) : la nouvelle espèce est vue et possédée, datée, sans lieu
## (aucun habitat) et sans capture comptée (statistique « Captures » du Dresseur).
func test_record_evolved_marks_seen_and_owned_without_habitat_nor_capture() -> void:
	var state := _dated()
	state.record_caught(&"caterpie", &"viridian_forest")
	var signals: Array = []
	state.pokedex.recorded.connect(func(species: StringName, map: StringName, first: bool,
			new_map: bool, caught: bool) -> void:
		signals.append([species, map, first, new_map, caught]))
	assert_true(state.record_evolved(&"metapod"), "première fois possédé")
	var entry: PokedexEntry = state.pokedex.get_entry(&"metapod")
	assert_true(state.pokedex.is_seen(&"metapod"))
	assert_true(state.pokedex.is_caught(&"metapod"))
	assert_eq(entry.times_seen, 1, "vu une fois")
	assert_eq(entry.times_caught, 0, "une évolution n'est pas une capture")
	assert_eq(entry.seen_maps, [] as Array[StringName], "aucun habitat")
	assert_eq(entry.first_seen_map, &"")
	assert_eq(entry.first_caught_map, &"")
	assert_eq(entry.first_seen_date, "2026-10-02T14:03:05")
	assert_eq(entry.first_caught_date, "2026-10-02T14:03:05")
	assert_eq(signals, [[&"metapod", &"", true, false, true]], "comme une capture : aucun toast")
	assert_eq(TrainerSummary.capture_count(state.pokedex, &""), 1, "seule la capture compte")
	# Une deuxième évolution vers la même espèce : déjà possédée, rien ne double.
	assert_false(state.record_evolved(&"metapod"))
	assert_eq(entry.times_seen, 1)
	assert_eq(entry.times_caught, 0)
	# Une espèce déjà vue (dans la nature) garde son observation et son habitat.
	state.record_seen(&"butterfree", &"route_2")
	assert_true(state.record_evolved(&"butterfree"))
	var seen: PokedexEntry = state.pokedex.get_entry(&"butterfree")
	assert_eq([seen.times_seen, seen.times_caught, seen.seen_maps],
		[1, 0, [&"route_2"] as Array[StringName]])
	# Aller-retour de la sauvegarde : possédé, 0 capture.
	var reloaded := Pokedex.new()
	assert_true(reloaded.from_dict(state.pokedex.to_dict()))
	assert_true(reloaded.is_caught(&"metapod"))
	assert_eq(reloaded.times_caught(&"metapod"), 0)
	assert_eq(reloaded.get_entry(&"metapod").times_seen, 1)


func test_a_captured_starter_is_seen_once_not_zero_times() -> void:
	# Le starter n'est jamais « vu » en combat : sa capture est sa première observation.
	var state := _dated()
	assert_true(state.record_caught(&"charmander", &"oak_lab"))
	var entry: PokedexEntry = state.pokedex.get_entry(&"charmander")
	assert_eq(entry.times_seen, 1)
	assert_eq(entry.times_caught, 1)
	assert_eq(entry.first_seen_map, &"oak_lab")
	# Le Pokémon du rival, lui, est seulement vu.
	state.record_seen(&"squirtle", &"oak_lab")
	assert_eq(state.pokedex.times_seen(&"squirtle"), 1)
	assert_false(state.pokedex.is_caught(&"squirtle"))


func test_load_dict_fixes_a_captured_species_saved_as_seen_zero_times() -> void:
	var state := _dated()
	state.record_caught(&"charmander", &"oak_lab")
	var saved: Dictionary = state.to_dict()
	# Sauvegarde du jalon 5 avant la règle : le compteur d'observations est à 0.
	saved["pokedex"]["entries"]["charmander"]["times_seen"] = 0
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var loaded := _make()
	assert_true(loaded.load_dict(saved, data))
	assert_eq(loaded.pokedex.times_seen(&"charmander"), 1, "corrigé au chargement")
	assert_true(loaded.pokedex.is_caught(&"charmander"))
	assert_eq(loaded.pokedex.times_caught(&"charmander"), 1)


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
	# §16.2 + §16.3 ; v3 (jalon-07.md §5.1) : argent et première rencontre sauvage. Ni badges
	# ni statistiques (§16.3 « pas stocké »).
	var keys: Array = _dated().to_dict().keys()
	keys.sort()
	# v5 (OUV.1, ouverture.md §2) : prénom du rival et apparence du joueur ; v6 (J11) : compagnon ;
	# v7 (J15) : Pension.
	assert_eq(keys, ["bag", "cell", "companion", "daycare", "discovered_maps", "facing",
		"first_wild_encounter",
		"flags", "found_items", "heal_map", "heal_spawn", "map", "moments", "money", "party",
		"play_time", "player_look", "player_name", "pokedex", "rival_name", "rng", "started_at",
		"starter", "storage"])


# --- Sauvegarde v5 : prénom du rival et apparence (OUV.1) ---------------------------------

func test_default_names_and_max_length_match_the_opening_data() -> void:
	var names := OpeningNames.new()
	assert_true(names.load_file(), str(names.get_errors()))
	assert_eq(GameStateScript.DEFAULT_PLAYER_NAME, names.default_name(OpeningNames.ROLE_PLAYER))
	assert_eq(GameStateScript.DEFAULT_RIVAL_NAME, names.default_name(OpeningNames.ROLE_RIVAL))
	assert_eq(GameStateScript.NAME_MAX_LENGTH, names.max_length())


func test_a_new_game_has_the_default_rival_and_the_hero() -> void:
	var state := _dated()
	assert_eq(state.rival_name, "Régis")
	assert_eq(state.player_look, &"hero")
	state.rival_name = "Blue"
	state.new_game()
	assert_eq(state.rival_name, "Régis", "remis au défaut")
	assert_eq(state.player_look, &"hero")
	assert_eq(GameStateScript.PLAYER_LOOKS, [&"hero", &"heroine"] as Array[StringName], "JR-1")


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


func test_has_moment_tells_whether_a_moment_type_is_recorded() -> void:
	var state := _dated()
	assert_false(state.has_moment(state.MOMENT_FIRST_CAPTURE))
	state.record_moment(state.MOMENT_STARTER, &"oak_lab")
	assert_false(state.has_moment(state.MOMENT_FIRST_CAPTURE), "le starter n'est pas une capture")
	state.record_moment(state.MOMENT_FIRST_CAPTURE, &"route_1", {"species": "pidgey"})
	assert_true(state.has_moment(state.MOMENT_FIRST_CAPTURE))
	assert_true(state.has_moment(state.MOMENT_STARTER))


# --- Jalon 7 (jalon-07.md §3.1) : argent et première rencontre sauvage ---------------------

func test_a_new_game_starts_with_3000_and_no_wild_encounter() -> void:
	var state := _dated()
	assert_eq(state.STARTING_MONEY, 3000, "dossier 09 §10")
	assert_eq(state.money, 3000)
	assert_eq(state.first_wild_encounter, {})
	assert_eq(state.first_wild_species(), &"")
	assert_eq(SaveSystem.V3_MIGRATED_MONEY, state.STARTING_MONEY,
		"une partie migrée reçoit la même somme qu'une nouvelle partie (dossier 09 §17)")


func test_add_money_is_capped_and_ignores_negative_amounts() -> void:
	var state := _dated()
	assert_eq(state.add_money(250), 250)
	assert_eq(state.money, 3250)
	assert_eq(state.add_money(0), 0)
	assert_eq(state.add_money(-100), 0, "un montant négatif n'enlève rien")
	assert_eq(state.money, 3250)
	assert_eq(state.add_money(state.MONEY_MAX), state.MONEY_MAX - 3250, "borné au plafond")
	assert_eq(state.money, 999_999)
	assert_eq(state.add_money(1), 0, "déjà au plafond")
	assert_eq(state.money, 999_999)


func test_spend_money_refuses_without_changing_anything_when_short() -> void:
	var state := _dated()
	assert_false(state.spend_money(3001), "pas assez")
	assert_eq(state.money, 3000, "rien n'a changé")
	assert_false(state.spend_money(-5), "montant négatif refusé")
	assert_eq(state.money, 3000)
	assert_true(state.spend_money(200))
	assert_eq(state.money, 2800)
	assert_true(state.spend_money(2800), "la somme exacte passe")
	assert_eq(state.money, 0, "jamais négatif")
	assert_false(state.spend_money(1))
	assert_true(state.spend_money(0), "rien à payer")
	assert_eq(state.money, 0)


func test_record_wild_encounter_keeps_only_the_first_one() -> void:
	var state := _dated()
	assert_false(state.record_wild_encounter(&"", &"route_1"), "sans espèce : rien")
	assert_true(state.record_wild_encounter(&"rattata", &"route_1"))
	state.clock.iso = "2026-10-02T15:00:00"
	assert_false(state.record_wild_encounter(&"pidgey", &"route_22"), "déjà retenue")
	assert_eq(state.first_wild_encounter, {"species": "rattata", "map": "route_1",
		"date": "2026-10-02T14:03:05"})
	assert_eq(state.first_wild_species(), &"rattata")


func test_money_and_first_wild_encounter_round_trip_and_tolerant_loading() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var state := _dated()
	state.add_money(1234)
	state.record_wild_encounter(&"pidgey", &"route_1")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	var loaded := _dated()
	assert_true(loaded.load_dict(saved, data))
	assert_eq(loaded.money, 4234)
	assert_eq(loaded.first_wild_encounter, state.first_wild_encounter)
	assert_eq(loaded.to_dict(), state.to_dict())
	# Formes inattendues : bornées ou valeurs par défaut, rien ne plante.
	var cases := [[-50, 0], [5_000_000, 999_999], ["beaucoup", 3000], [12.5, 3000]]
	for case: Array in cases:
		saved["money"] = case[0]
		assert_true(loaded.load_dict(saved, data))
		assert_eq(loaded.money, case[1], "argent lu depuis %s" % [case[0]])
	saved.erase("money")
	assert_true(loaded.load_dict(saved, data))
	assert_eq(loaded.money, 3000, "absent : argent de départ")
	for odd: Variant in [null, "pidgey", {}, {"species": 3}, {"species": ""}]:
		saved["first_wild_encounter"] = odd
		assert_true(loaded.load_dict(saved, data))
		assert_eq(loaded.first_wild_encounter, {}, "mal formée : aucune")
	saved["first_wild_encounter"] = {"species": "pidgey", "map": 4}
	assert_true(loaded.load_dict(saved, data))
	assert_eq(loaded.first_wild_encounter, {"species": "pidgey", "map": "", "date": ""})
	saved["first_wild_encounter"] = {"species": "missingno", "map": "route_1", "date": ""}
	assert_false(loaded.load_dict(saved, data), "espèce inconnue écartée")
	assert_eq(loaded.first_wild_encounter, {})
	assert_push_error_count(1)


# --- Jalon 9 (T2, sauvegarde v4) : statut des Pokémon -----------------------------------------

func test_poisoned_party_and_storage_members_are_reloaded_poisoned() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var state := _dated()
	var charmander := PokemonFactory.create(data, &"charmander", 9, GameRng.new(1))
	charmander.status = StatusRules.POISON
	charmander.take_damage(7)
	state.party.add(charmander)
	state.party.add(PokemonFactory.create(data, &"pidgey", 7, GameRng.new(2)))
	var stored := PokemonFactory.create(data, &"rattata", 4, GameRng.new(3))
	stored.status = StatusRules.POISON
	state.storage.add(stored)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	assert_eq(saved["party"][0]["status"], "poison")
	assert_eq(saved["party"][1]["status"], "", "sans statut : écrit vide")
	assert_eq(saved["storage"][0]["status"], "poison")
	var loaded := _dated()
	assert_true(loaded.load_dict(saved, data), "rien d'écarté")
	assert_eq(loaded.party.get_at(0).status, StatusRules.POISON, "équipe : empoisonné")
	assert_eq(loaded.party.get_at(0).hp, charmander.hp, "PV gardés")
	assert_eq(loaded.party.get_at(1).status, StatusRules.NONE)
	assert_eq(loaded.storage.get_at(0).status, StatusRules.POISON, "stockage : empoisonné")
	assert_eq(loaded.to_dict(), state.to_dict(), "aller-retour identique")
	loaded.party.heal_all()
	assert_eq(loaded.party.get_at(0).status, StatusRules.NONE, "soin de l'équipe : effacé")
