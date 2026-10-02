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
	assert_false(_unlocks.is_available(&"storage"))
	assert_false(_unlocks.is_available(&""))


func test_without_state_nothing_conditional_is_visible() -> void:
	var bare := MenuUnlocks.new()
	assert_false(bare.team_visible())
	assert_false(bare.pokedex_visible())
	assert_eq(bare.dashboard_cards().size(), 4)
