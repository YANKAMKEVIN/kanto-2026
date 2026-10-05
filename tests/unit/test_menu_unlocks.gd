extends GutTest
## MenuUnlocks : règle de déblocage du Menu Dresseur (jalon-06.md §4).

var _flags: StoryFlags
var _party: Party
var _unlocks: MenuUnlocks


func before_each() -> void:
	_flags = StoryFlags.new()
	_party = Party.new()
	_unlocks = MenuUnlocks.new(_flags, _party)


func _add_member() -> void:
	var pokemon := Pokemon.new()
	pokemon.species_id = &"charmander"
	_party.add(pokemon)


func test_before_the_starter_only_four_cards() -> void:
	assert_false(_unlocks.team_visible())
	assert_false(_unlocks.pokedex_visible())
	assert_eq(_unlocks.dashboard_cards(), [&"bag", &"map", &"trainer", &"settings"]
		as Array[StringName], "Q-2 : ni ÉQUIPE ni POKÉDEX, aucun emplacement vide")


func test_with_a_team_five_cards_without_pokedex() -> void:
	_add_member()
	assert_true(_unlocks.team_visible())
	assert_eq(_unlocks.dashboard_cards(), [&"team", &"bag", &"map", &"trainer", &"settings"]
		as Array[StringName])
	assert_false(_unlocks.is_available(MenuRoute.POKEDEX))


func test_pokedex_activated_gives_six_cards() -> void:
	_add_member()
	_flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_true(_unlocks.pokedex_visible())
	assert_eq(_unlocks.dashboard_cards(), MenuRoute.DASHBOARD_ORDER)


func test_debug_flag_shows_pokedex_without_touching_story_flags() -> void:
	_add_member()
	_unlocks.debug_pokedex = true
	assert_true(_unlocks.pokedex_visible())
	assert_eq(_unlocks.dashboard_cards().size(), 6)
	assert_false(_flags.has_flag(StoryFlags.POKEDEX_ACTIVATED), "jamais un drapeau d'histoire")
	assert_eq(_flags.size(), 0)


func test_unlocks_follow_the_live_state() -> void:
	assert_false(_unlocks.team_visible())
	_add_member()
	assert_true(_unlocks.team_visible(), "relu à chaque appel")
	_flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_true(_unlocks.pokedex_visible())


func test_always_available_screens_and_unknown_screen() -> void:
	for screen: StringName in [MenuRoute.DASHBOARD, MenuRoute.BAG, MenuRoute.MAP,
			MenuRoute.TRAINER, MenuRoute.SETTINGS]:
		assert_true(_unlocks.is_available(screen), screen)
	assert_false(_unlocks.is_available(&"unknown_screen"))
	assert_false(_unlocks.is_available(&""))


func test_without_state_nothing_conditional_is_visible() -> void:
	var bare := MenuUnlocks.new()
	assert_false(bare.team_visible())
	assert_false(bare.pokedex_visible())
	assert_eq(bare.dashboard_cards().size(), 4)


# --- Stockage (J7A, jalon-07.md §3.5) ----------------------------------------------------------

## Une zone avec un Centre (« v_center ») et une Boutique (« v_mart »), et une zone sans service.
func _zones_with_center() -> ZoneLibrary:
	var zones := ZoneLibrary.new()
	assert_true(zones.add_from_dict({
		"services": {"pokemon_center": {"name": "Centre Pokémon"},
			"poke_mart": {"name": "Boutique"}},
		"zones": {
			"v": {"name": "Jadielle", "kind": "town", "maps": ["v", "v_center", "v_mart"],
				"services": [{"id": "pokemon_center", "found_on": "v_center"},
					{"id": "poke_mart", "found_on": "v_mart"}]},
			"r": {"name": "Route", "kind": "route", "maps": ["r"]},
		},
	}, "t"), "\n".join(zones.get_errors()))
	return zones


func test_storage_only_inside_a_pokemon_center() -> void:
	var zones := _zones_with_center()
	assert_true(MenuUnlocks.is_storage_map(&"v_center", zones))
	assert_false(MenuUnlocks.is_storage_map(&"v", zones), "pas dans la ville du Centre")
	assert_false(MenuUnlocks.is_storage_map(&"v_mart", zones), "pas à la Boutique")
	assert_false(MenuUnlocks.is_storage_map(&"r", zones))
	assert_false(MenuUnlocks.is_storage_map(&"", zones))
	assert_false(MenuUnlocks.is_storage_map(&"v_center", null))


func test_storage_available_follows_the_current_map() -> void:
	_add_member()
	var where := {"map": &"v"}
	_unlocks.set_location(_zones_with_center(), func() -> StringName: return where["map"])
	assert_false(_unlocks.storage_available())
	assert_false(_unlocks.is_available(MenuRoute.STORAGE))
	where["map"] = &"v_center"
	assert_true(_unlocks.storage_available(), "relu à chaque appel")
	assert_true(_unlocks.is_available(MenuRoute.STORAGE))
	assert_false(_unlocks.dashboard_cards().has(MenuRoute.STORAGE),
		"jamais une carte du tableau de bord")


func test_storage_needs_a_location_and_a_team() -> void:
	assert_false(_unlocks.storage_available(), "sans lieu branché : nulle part")
	_unlocks.set_location(_zones_with_center(), func() -> StringName: return &"v_center")
	assert_true(_unlocks.storage_available())
	assert_false(_unlocks.is_available(MenuRoute.STORAGE), "sans équipe, pas d'écran")
	_add_member()
	assert_true(_unlocks.is_available(MenuRoute.STORAGE))


func test_real_zones_have_no_storage_outside_centers() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for map: StringName in [&"pallet_town", &"player_house_1f", &"oak_lab", &"route_1",
			&"viridian_city"]:
		assert_false(MenuUnlocks.is_storage_map(map, zones), map)
