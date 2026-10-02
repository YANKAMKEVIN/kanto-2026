extends GutTest
## MenuNavigator : pile du Menu Dresseur, retour, liens croisés (jalon-06.md §3.2, §4).

var _flags: StoryFlags
var _party: Party
var _unlocks: MenuUnlocks
var _nav: MenuNavigator


func before_each() -> void:
	_flags = StoryFlags.new()
	_party = Party.new()
	var pokemon := Pokemon.new()
	pokemon.species_id = &"charmander"
	_party.add(pokemon)
	_unlocks = MenuUnlocks.new(_flags, _party)
	_nav = MenuNavigator.new(_unlocks)
	watch_signals(_nav)


func test_closed_at_start() -> void:
	assert_false(_nav.is_open())
	assert_eq(_nav.depth(), 0)
	assert_null(_nav.current())
	assert_false(_nav.back(), "retour menu fermé : rien")
	assert_false(_nav.go(MenuRoute.trainer()), "aller quelque part menu fermé : refusé")
	assert_signal_emit_count(_nav, "route_changed", 0)


func test_open_on_the_dashboard() -> void:
	assert_true(_nav.open())
	assert_true(_nav.is_open())
	assert_eq(_nav.depth(), 1)
	assert_eq(_nav.current().screen, MenuRoute.DASHBOARD)
	assert_signal_emit_count(_nav, "opened", 1)
	assert_false(_nav.open(), "déjà ouvert")
	assert_signal_emit_count(_nav, "opened", 1)


func test_open_on_a_screen_keeps_the_dashboard_below() -> void:
	assert_true(_nav.open(MenuRoute.team(0)))
	assert_eq(_nav.get_screens(), [&"dashboard", &"team"] as Array[StringName])
	assert_eq(get_signal_parameters(_nav, "opened")[0].screen, MenuRoute.TEAM)
	assert_true(_nav.back())
	assert_eq(_nav.current().screen, MenuRoute.DASHBOARD)


func test_open_on_an_unavailable_screen_opens_the_dashboard() -> void:
	assert_true(_nav.open(MenuRoute.pokedex()))
	assert_eq(_nav.get_screens(), [&"dashboard"] as Array[StringName])


func test_back_from_the_dashboard_closes() -> void:
	_nav.open()
	assert_true(_nav.back())
	assert_false(_nav.is_open())
	assert_signal_emit_count(_nav, "closed", 1)
	assert_signal_emit_count(_nav, "route_changed", 0)


func test_card_then_back_then_back() -> void:
	_nav.open()
	assert_true(_nav.go(MenuRoute.bag()))
	assert_eq(_nav.current().screen, MenuRoute.BAG)
	assert_signal_emit_count(_nav, "route_changed", 1)
	assert_true(_nav.back())
	assert_eq(_nav.current().screen, MenuRoute.DASHBOARD)
	assert_signal_emit_count(_nav, "route_changed", 2)
	assert_true(_nav.back())
	assert_false(_nav.is_open())
	assert_signal_emit_count(_nav, "closed", 1)


func test_close_from_anywhere() -> void:
	_nav.open()
	_nav.go(MenuRoute.team())
	_nav.go(MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, 0))
	_nav.close()
	assert_false(_nav.is_open())
	assert_eq(_nav.depth(), 0)
	assert_signal_emit_count(_nav, "closed", 1)
	_nav.close()
	assert_signal_emit_count(_nav, "closed", 1, "fermer un menu fermé : rien")


func test_pokedex_link_refused_without_unlock() -> void:
	_nav.open()
	_nav.go(MenuRoute.trainer())
	assert_false(_nav.go(MenuRoute.pokedex(MenuRoute.DEX_FILTER_SEEN)))
	assert_eq(_nav.get_screens(), [&"dashboard", &"trainer"] as Array[StringName],
		"rien ne change")
	assert_signal_emit_count(_nav, "route_changed", 1)


func test_pokedex_link_accepted_with_activation_or_debug_flag() -> void:
	_nav.open()
	_flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_true(_nav.go(MenuRoute.pokedex()))
	_nav.close()
	_flags.clear()
	_unlocks.debug_pokedex = true
	_nav.open()
	assert_true(_nav.go(MenuRoute.pokedex()))
	assert_false(_flags.has_flag(StoryFlags.POKEDEX_ACTIVATED))


func test_team_refused_with_an_empty_party() -> void:
	_party.clear()
	_nav.open()
	assert_false(_nav.go(MenuRoute.team(0)), "Pokémon de tête absent : pas d'Équipe")
	assert_eq(_nav.depth(), 1)


func test_pokedex_map_loop_does_not_stack() -> void:
	_unlocks.debug_pokedex = true
	_nav.open()
	_nav.go(MenuRoute.pokedex())
	_nav.go(MenuRoute.map(&"route_1"))
	assert_true(_nav.go(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, &"pidgey")))
	assert_eq(_nav.get_screens(), [&"dashboard", &"pokedex"] as Array[StringName],
		"retour sur le Pokédex, pile coupée au-dessus")
	assert_eq(_nav.current().get_param("species"), &"pidgey", "paramètres remplacés")
	_nav.go(MenuRoute.map(&"pallet_town"))
	_nav.go(MenuRoute.pokedex())
	_nav.go(MenuRoute.map())
	assert_eq(_nav.depth(), 3)
	assert_true(_nav.back())
	assert_true(_nav.back())
	assert_eq(_nav.current().screen, MenuRoute.DASHBOARD)


func test_going_to_the_dashboard_unwinds_the_stack() -> void:
	_nav.open()
	_nav.go(MenuRoute.team())
	_nav.go(MenuRoute.bag())
	assert_true(_nav.go(MenuRoute.dashboard()))
	assert_eq(_nav.get_screens(), [&"dashboard"] as Array[StringName])


func test_same_route_twice_emits_once() -> void:
	_nav.open()
	_nav.go(MenuRoute.team(0))
	assert_true(_nav.go(MenuRoute.team(0)), "accepté, mais rien ne change")
	assert_signal_emit_count(_nav, "route_changed", 1)
	assert_true(_nav.go(MenuRoute.team(1)))
	assert_signal_emit_count(_nav, "route_changed", 2)
	assert_eq(_nav.depth(), 2)
	assert_eq(_nav.current().get_param("index"), 1)


func test_depth_is_bounded_and_the_top_is_replaced() -> void:
	_unlocks.debug_pokedex = true
	_nav.open()
	_nav.go(MenuRoute.team())
	_nav.go(MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, 0))
	_nav.go(MenuRoute.map())
	assert_eq(_nav.depth(), MenuNavigator.MAX_DEPTH)
	assert_true(_nav.go(MenuRoute.pokedex()))
	assert_eq(_nav.depth(), MenuNavigator.MAX_DEPTH)
	assert_eq(_nav.get_screens(), [&"dashboard", &"team", &"bag", &"pokedex"]
		as Array[StringName], "le dessus est remplacé, le fond reste")
	_nav.go(MenuRoute.trainer())
	_nav.go(MenuRoute.settings())
	assert_eq(_nav.depth(), MenuNavigator.MAX_DEPTH)
	assert_eq(_nav.get_screens()[0], MenuRoute.DASHBOARD)


func test_current_is_a_copy() -> void:
	_nav.open()
	_nav.go(MenuRoute.team(1))
	_nav.current().params["index"] = 4
	assert_eq(_nav.current().get_param("index"), 1)


func test_unknown_or_null_route_refused() -> void:
	_nav.open()
	assert_false(_nav.go(null))
	assert_false(_nav.go(MenuRoute.new(&"storage")))
	assert_eq(_nav.depth(), 1)


func test_reopen_after_close_starts_over() -> void:
	_nav.open()
	_nav.go(MenuRoute.trainer())
	_nav.back()
	_nav.back()
	assert_true(_nav.open())
	assert_eq(_nav.get_screens(), [&"dashboard"] as Array[StringName])
	assert_signal_emit_count(_nav, "opened", 2)
