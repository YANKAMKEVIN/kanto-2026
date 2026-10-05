extends GutTest
## MenuRoute : écrans du Menu Dresseur et leurs paramètres (jalon-06.md §3.2).


func test_dashboard_order_follows_dossier_08() -> void:
	assert_eq(MenuRoute.DASHBOARD_ORDER, [&"team", &"pokedex", &"bag", &"map", &"trainer",
		&"settings"] as Array[StringName])
	for screen: StringName in MenuRoute.DASHBOARD_ORDER:
		assert_true(MenuRoute.SCREENS.has(screen), screen)
	assert_false(MenuRoute.DASHBOARD_ORDER.has(MenuRoute.DASHBOARD))


func test_factories_carry_documented_params() -> void:
	assert_eq(MenuRoute.dashboard().screen, MenuRoute.DASHBOARD)
	assert_eq(MenuRoute.dashboard().params, {})
	assert_eq(MenuRoute.team(2).params, {"index": 2})
	assert_eq(MenuRoute.team().get_param("index"), 0)
	var bag := MenuRoute.bag(MenuRoute.BAG_CONTEXT_TEAM, 1)
	assert_eq(bag.screen, MenuRoute.BAG)
	assert_eq(bag.get_param("context"), MenuRoute.BAG_CONTEXT_TEAM)
	assert_eq(bag.get_param("target"), 1)
	assert_eq(MenuRoute.bag().get_param("context"), MenuRoute.BAG_CONTEXT_FIELD)
	assert_eq(MenuRoute.bag().get_param("target"), -1)
	var dex := MenuRoute.pokedex(MenuRoute.DEX_FILTER_CAUGHT, &"pidgey")
	assert_eq(dex.get_param("filter"), MenuRoute.DEX_FILTER_CAUGHT)
	assert_eq(dex.get_param("species"), &"pidgey")
	assert_eq(MenuRoute.pokedex().get_param("filter"), MenuRoute.DEX_FILTER_ALL)
	assert_eq(MenuRoute.map(&"route_1").get_param("zone"), &"route_1")
	assert_eq(MenuRoute.trainer().screen, MenuRoute.TRAINER)
	assert_eq(MenuRoute.settings().screen, MenuRoute.SETTINGS)
	assert_eq(MenuRoute.storage().screen, MenuRoute.STORAGE)
	assert_eq(MenuRoute.storage().params, {})
	assert_false(MenuRoute.DASHBOARD_ORDER.has(MenuRoute.STORAGE), "pas une carte")
	assert_eq(MenuRoute.trainer().get_param("missing", 7), 7)


func test_pokedex_filters_keep_the_planned_order() -> void:
	assert_eq([MenuRoute.DEX_FILTER_ALL, MenuRoute.DEX_FILTER_SEEN, MenuRoute.DEX_FILTER_CAUGHT,
		MenuRoute.DEX_FILTER_HABITAT], [0, 1, 2, 3])


func test_for_screen_gives_the_default_route_of_each_card() -> void:
	for screen: StringName in MenuRoute.SCREENS:
		var route := MenuRoute.for_screen(screen)
		assert_not_null(route, screen)
		assert_eq(route.screen, screen)
	assert_true(MenuRoute.for_screen(&"team").equals(MenuRoute.team(0)))
	assert_null(MenuRoute.for_screen(&"unknown_screen"), "écran inconnu")


func test_equals_compares_screen_and_params() -> void:
	assert_true(MenuRoute.team(1).equals(MenuRoute.team(1)))
	assert_false(MenuRoute.team(1).equals(MenuRoute.team(2)))
	assert_false(MenuRoute.map().equals(MenuRoute.trainer()))
	assert_false(MenuRoute.map().equals(null))


func test_routes_are_independent_copies() -> void:
	var params := {"index": 1}
	var route := MenuRoute.new(MenuRoute.TEAM, params)
	params["index"] = 5
	assert_eq(route.get_param("index"), 1, "paramètres copiés à la création")
	var copy := route.duplicate_route()
	copy.params["index"] = 3
	assert_eq(route.get_param("index"), 1, "duplicate_route copie les paramètres")


## Jalon 7 : la Boutique, écran seul (jalon-07.md §3.4).
func test_shop_route() -> void:
	var shop := MenuRoute.shop(&"viridian_mart", MenuRoute.SHOP_MODE_SELL)
	assert_eq(shop.screen, MenuRoute.SHOP)
	assert_eq(shop.params, {"shop": &"viridian_mart", "mode": &"sell"})
	assert_eq(MenuRoute.shop(&"x").get_param("mode"), MenuRoute.SHOP_MODE_BUY)
	assert_eq([MenuRoute.SHOP_MODE_BUY, MenuRoute.SHOP_MODE_SELL],
		[ShopViews.MODE_BUY, ShopViews.MODE_SELL], "mêmes valeurs que ShopViews")
	assert_true(MenuRoute.is_standalone_screen(MenuRoute.SHOP))
	assert_false(MenuRoute.is_standalone_screen(MenuRoute.BAG))
	assert_false(MenuRoute.SCREENS.has(MenuRoute.SHOP), "pas un écran du tableau de bord")
	assert_false(MenuRoute.DASHBOARD_ORDER.has(MenuRoute.SHOP))
	assert_null(MenuRoute.for_screen(MenuRoute.SHOP), "pas de route par défaut")
