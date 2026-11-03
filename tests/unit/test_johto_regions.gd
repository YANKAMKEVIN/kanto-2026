extends GutTest
## Chapitre Johto, JOH0 lot D (`jalon-joh0.md` §2.12, §2.13) : Pokédex à 202 espèces en liste
## continue avec le filtre région et le compte de Johto (Diplôme), zones et points de Vol de
## Johto, Vol entre régions refusé pendant l'acte 1, Carte à deux pages.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const READY := FieldMoves.State.READY

var _data: PokemonData
var _zones: ZoneLibrary
var _lib: PokedexLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_lib = PokedexLibrary.new()
	assert_true(_lib.load_dir(), str(_lib.get_errors()))
	assert_true(_lib.check_references(_data), str(_lib.get_errors()))


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.new_game(2)
	return state


# --- Pokédex 202 ---------------------------------------------------------------------------------

func test_the_pokedex_library_sums_both_files_and_accepts_national_numbers() -> void:
	assert_eq(_lib.size(), 202, "151 + 51")
	assert_true(_lib.has_species(&"chikorita"))
	assert_true(_lib.has_species(&"celebi"))
	assert_true(_lib.has_species(&"bulbasaur"))
	var kanto_only := PokedexLibrary.new()
	assert_true(kanto_only.load_file())
	assert_eq(kanto_only.size(), 151)
	assert_true(kanto_only.check_references(_data), "151 fiches, numéros ≤ 251")
	assert_eq(PokedexLibrary.MAX_DEX, 251)


func test_the_list_is_continuous_with_the_region_filter() -> void:
	var dex := Pokedex.new()
	var view := PokedexQuery.grid(dex, _data, _lib, _zones)
	assert_eq(view.slots.size(), 202, "aucune case vide entre 151 et 152")
	assert_eq(view.slots[150].number, 151)
	assert_eq(view.slots[151].number, 152, "Germignon juste après Mew")
	assert_eq(view.slots[201].number, 251)
	assert_eq(view.counts_text, "0 vu · 0 capturé · 202 espèces")
	assert_eq(view.region_ids, [] as Array[StringName], "rien vu de Johto : pas de filtre région")
	dex.mark_seen(&"chikorita", &"olivine_city", "2026-11-03")
	dex.mark_caught(&"chikorita", &"olivine_city", "2026-11-03")
	dex.mark_caught(&"pidgey", &"route_1", "2026-11-03")
	view = PokedexQuery.grid(dex, _data, _lib, _zones)
	assert_eq(view.region_ids, [&"", &"kanto", &"johto"] as Array[StringName])
	assert_eq(view.region_names, PackedStringArray(["Tout", "Kanto", "Johto"]))
	assert_eq(view.region, &"")
	var johto := PokedexQuery.grid(dex, _data, _lib, _zones, PokedexQuery.Filter.ALL, &"", &"",
		"", &"", ZoneData.REGION_JOHTO)
	assert_eq(johto.slots.size(), 51)
	assert_eq(johto.slots[0].number, 152)
	assert_eq(johto.slots[0].species_id, &"chikorita")
	assert_eq(johto.region, &"johto")
	var kanto := PokedexQuery.grid(dex, _data, _lib, _zones, PokedexQuery.Filter.CAUGHT, &"",
		&"", "", &"", ZoneData.REGION_KANTO)
	assert_eq(kanto.slots.size(), 1)
	assert_eq(kanto.slots[0].species_id, &"pidgey")
	assert_eq(PokedexQuery.caught_in_region(dex, _data, ZoneData.REGION_JOHTO), 1)
	assert_eq(PokedexQuery.caught_in_region(dex, _data, ZoneData.REGION_KANTO), 1)
	assert_eq(PokedexQuery.region_of_number(151), &"kanto")
	assert_eq(PokedexQuery.region_of_number(152), &"johto")


func test_the_johto_diploma_condition_counts_johto_species_only() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.add_from_dict({"elm": {"speaker": "Orme", "variants": [
		{"if_caught_johto_at_least": 50, "pages": ["Voici ton Diplôme de Johto !"]},
		{"unless_caught_johto_at_least": 50, "pages": ["Continue, il t'en manque."]},
	]}}, "test"), str(library.get_errors()))
	var dialogue := library.get_dialogue(&"elm")
	assert_eq(dialogue.pick(StoryFlags.new(), null, 200).pages[0].text, "Continue, il t'en manque.",
		"200 captures en tout ne font pas le Diplôme de Johto")
	assert_eq(dialogue.pick(StoryFlags.new(), null, 0, Callable(), Callable(), Callable(), &"",
		&"", 50).pages[0].text, "Voici ton Diplôme de Johto !")
	var bad := DialogueLibrary.new()
	assert_false(bad.add_from_dict({"x": {"pages": ["a"], "if_caught_johto_at_least": 60,
		"unless_caught_johto_at_least": 50}}, "bad"))
	assert_push_error("if_caught_johto_at_least")
	var runner := DialogueRunner.new()
	add_child_autofree(runner)
	assert_eq(runner._caught_johto(), 0)
	runner.caught_johto_count = func() -> int: return 7
	assert_eq(runner._caught_johto(), 7)


# --- Régions, Vol -------------------------------------------------------------------------------

func test_fly_points_of_johto_carry_their_region_and_are_refused_during_act_1() -> void:
	var rules := FlyRules.new()
	assert_true(rules.load_file())
	rules.stamp_regions(_zones)
	assert_eq(rules.get_point(&"olivine_city").region, &"johto")
	assert_eq(rules.get_point(&"pallet_town").region, &"kanto")
	var discovered := {&"pallet_town": "", &"olivine_city": "", &"goldenrod_city": ""}
	var outdoors := MapTraits.new()
	assert_eq(rules.can_fly_to(&"olivine_city", READY, outdoors, discovered, false, &"kanto",
		true), FlyRules.Check.OK, "acte 2 : Vol entre régions")
	assert_eq(rules.can_fly_to(&"olivine_city", READY, outdoors, discovered, false, &"kanto",
		false), FlyRules.Check.OTHER_REGION, "acte 1 : refusé")
	assert_eq(rules.can_fly_to(&"goldenrod_city", READY, outdoors, discovered, false, &"johto",
		false), FlyRules.Check.OK, "même région : permis")
	assert_eq(rules.can_fly_to(&"olivine_city", READY, outdoors, discovered, false, &"", false),
		FlyRules.Check.OK, "sans région connue : aucun contrôle")
	assert_eq(rules.can_fly_to(&"ecruteak_city", READY, outdoors, discovered, false, &"johto",
		true), FlyRules.Check.CLOSED, "non découverte")
	var open := rules.destinations(discovered, &"johto", true)
	assert_eq(open.size(), 3)
	assert_eq(open[0].zone, &"olivine_city", "la région courante d'abord")
	assert_eq(open[2].zone, &"pallet_town")
	assert_eq(rules.destinations(discovered, &"johto", false).size(), 2, "acte 1 : Johto seul")


# --- Carte à deux pages -----------------------------------------------------------------------

func test_the_map_has_a_johto_page_once_arrived() -> void:
	var state := _state()
	state.discover_map(&"pallet_town")
	state.discover_map(&"viridian_city")
	state.current_map = &"pallet_town"
	assert_eq(MapJournal.available_regions(state.flags), [&"kanto"] as Array[StringName])
	state.flags.set_flag(TeamConfiscation.ARRIVED)
	assert_eq(MapJournal.available_regions(state.flags), [&"kanto", &"johto"]
		as Array[StringName])
	var kanto_art := MapIllustration.new()
	assert_true(kanto_art.load_file())
	var johto_art := MapIllustration.new()
	assert_true(johto_art.load_file("res://assets/ui/map/johto_placeholder_areas.json"),
		str(johto_art.get_errors()))
	assert_true(johto_art.check_references(_zones))
	var regions := MapJournal.available_regions(state.flags)
	var kanto := MapJournal.view(state, _zones, kanto_art, &"", &"kanto", regions)
	assert_eq(kanto.region_name, "Kanto")
	assert_eq(kanto.next_region(), &"johto")
	assert_eq(kanto.region_names, PackedStringArray(["Kanto", "Johto"]))
	assert_eq(kanto.zones.size(), 2)
	assert_eq(kanto.player_zone, &"pallet_town")
	var johto := MapJournal.view(state, _zones, johto_art, &"", &"johto", regions)
	assert_eq(johto.region_name, "Johto")
	assert_eq(johto.next_region(), &"kanto")
	assert_eq(johto.zones.size(), 0, "rien de Johto découvert : aucune zone nommée")
	assert_eq(johto.player_zone, &"", "le joueur n'est pas sur cette page")
	assert_eq(johto.image_path, "res://assets/ui/map/johto_placeholder.webp")
	var alone := MapJournal.view(state, _zones, kanto_art, &"", &"kanto", [&"kanto"])
	assert_eq(alone.next_region(), &"", "une seule page : pas de bouton")
	var legacy := MapJournal.view(state, _zones, kanto_art)
	assert_eq(legacy.zones.size(), 2, "sans région : toutes les zones (appels d'avant)")
