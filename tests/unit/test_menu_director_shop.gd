extends GutTest
## Le directeur et la Boutique (jalon-07.md §6.10, T12), seul, avec l'écran factice de la
## Boutique : ouverture en écran seul (pas de tableau de bord), onglets, achat (argent, Sac,
## « Merci ! », état changé), refus (« Tu n'as pas assez d'argent. », rien ne change), vente
## (moitié du prix), favori → confirmation puis vente, objet clé jamais en VENDRE, boutique
## inconnue ou non branchée → écran provisoire, fermeture.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FakeShop := preload("res://tests/helpers/fake_shop_screen.gd")
const MART := &"viridian_mart"

var _state: Node
var _items: ItemLibrary
var _shops: ShopLibrary
var _director: MenuDirector
var _screen: Node
var _dashboards: int = 0
var _placeholders: Array[StringName] = []
var _closed: Array[bool] = []


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.new_game(1)
	_items = ItemLibrary.new()
	_items.load_dir()
	_shops = ShopLibrary.new()
	_shops.load_dir()
	_shops.check_references(_items)
	_director = MenuDirector.new()
	add_child_autofree(_director)
	_director.setup(_state, PokemonData.new(), ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(_state.flags, _state.party), func() -> bool: return true, _items)
	_director.set_shops(_shops)
	_screen = autofree(FakeShop.new())
	_screen.wire(_director)
	_dashboards = 0
	_placeholders.clear()
	_closed.clear()
	_director.dashboard_shown.connect(func(_v: DashboardView) -> void: _dashboards += 1)
	_director.placeholder_shown.connect(_placeholders.append)
	_director.menu_closed.connect(_closed.append)


func after_each() -> void:
	get_tree().paused = false


func _open(mode: StringName = MenuRoute.SHOP_MODE_BUY) -> bool:
	return _director.open(MenuRoute.shop(MART, mode), true)


func _shown() -> ShopView:
	return _screen.last_shop()


func test_the_shop_opens_alone_without_a_dashboard() -> void:
	assert_true(_open())
	assert_true(get_tree().paused, "monde en pause")
	assert_true(_director.get_navigator().is_standalone(), "écran seul")
	assert_eq(_dashboards, 0, "ni tableau de bord, ni en-tête construit")
	assert_eq(_screen.shops.size(), 1)
	var view := _shown()
	assert_eq(view.shop_id, MART)
	assert_eq(view.mode, ShopViews.MODE_BUY)
	assert_eq(view.money_text, MenuFormat.money(3000))
	var ids: Array[StringName] = []
	for entry: ShopEntryView in view.entries:
		ids.append(entry.item_id)
	assert_eq(ids, [&"poke_ball", &"potion"] as Array[StringName], "stock du dossier 09 §9")
	assert_eq(_placeholders.size(), 0)


func test_the_shop_never_opens_inside_the_dashboard() -> void:
	assert_false(_director.open(MenuRoute.shop(MART)), "seulement seul")
	assert_false(_director.is_open())
	assert_false(get_tree().paused, "aucune pause laissée")
	assert_true(_director.open())
	assert_false(_director.go(MenuRoute.shop(MART)), "jamais par un lien")
	_director.close()


func test_back_closes_the_standalone_shop() -> void:
	assert_true(_open())
	assert_true(_director.handle_back())
	assert_false(_director.is_open(), "retour = fermer")
	assert_false(get_tree().paused)
	assert_eq(_closed, [false] as Array[bool], "rien n'a changé : pas d'autosave")


func test_tabs_reemit_the_view() -> void:
	assert_true(_open(MenuRoute.SHOP_MODE_SELL))
	assert_eq(_shown().mode, ShopViews.MODE_SELL, "ouvert sur l'onglet demandé")
	_screen.shop_mode_changed.emit(ShopViews.MODE_BUY)
	assert_eq(_shown().mode, ShopViews.MODE_BUY)
	_screen.shop_mode_changed.emit(&"steal")
	assert_eq(_shown().mode, ShopViews.MODE_BUY, "onglet inconnu : ACHETER")
	assert_eq(_screen.shops.size(), 3)


func test_buying_spends_money_fills_the_bag_and_thanks() -> void:
	assert_true(_open())
	_screen.shop_buy_requested.emit(&"poke_ball", 3)
	assert_eq(_state.money, 3000 - 600)
	assert_eq(_state.bag.count_of(&"poke_ball"), 3)
	assert_eq(_screen.results, [["Merci !", true]] as Array[Array])
	assert_eq(_screen.shops.size(), 2, "vue rafraîchie")
	assert_eq(_shown().money_text, MenuFormat.money(2400), "argent à jour")
	assert_eq(_shown().entry(&"poke_ball").owned_text, "DANS LE SAC : 3")
	_director.close()
	assert_eq(_closed, [true] as Array[bool], "état changé : autosave à la fermeture")


func test_not_enough_money_changes_nothing() -> void:
	_state.money = 250
	assert_true(_open())
	assert_eq(_director.buy(&"potion", 1), ShopRules.Status.NOT_ENOUGH_MONEY)
	assert_eq(_state.money, 250)
	assert_false(_state.bag.has(&"potion"))
	assert_eq(_screen.results, [["Tu n'as pas assez d'argent.", false]] as Array[Array])
	assert_eq(_screen.shops.size(), 1, "pas de vue réémise")
	_director.close()
	assert_eq(_closed, [false] as Array[bool], "rien n'a changé")


func test_selling_pays_half_the_price() -> void:
	_state.bag.add(&"potion", 4)
	assert_true(_open(MenuRoute.SHOP_MODE_SELL))
	_screen.shop_sell_requested.emit(&"potion", 2, false)
	assert_eq(_state.money, 3000 + 300)
	assert_eq(_state.bag.count_of(&"potion"), 2)
	assert_eq(_screen.results, [["Merci !", true]] as Array[Array])
	assert_eq(_shown().mode, ShopViews.MODE_SELL, "l'onglet reste VENDRE")
	assert_eq(_shown().entry(&"potion").owned, 2)


func test_selling_a_favorite_asks_first_then_sells() -> void:
	_state.bag.add(&"potion", 4)
	_state.bag.set_favorite(&"potion", true)
	assert_true(_open(MenuRoute.SHOP_MODE_SELL))
	_screen.shop_sell_requested.emit(&"potion", 1, false)
	assert_eq(_state.bag.count_of(&"potion"), 4, "rien vendu avant la confirmation")
	assert_eq(_screen.results.size(), 0, "pas de message")
	assert_eq(_screen.confirms.size(), 1)
	var view: ChoiceView = _screen.confirms[0][0]
	assert_eq(view.title, "Vendre Potion ?")
	assert_eq([view.confirm_label, view.cancel_label], ["VENDRE", "ANNULER"])
	assert_eq([_screen.confirms[0][1], _screen.confirms[0][2]], [&"potion", 1])
	_screen.confirm_sell()
	assert_eq(_state.bag.count_of(&"potion"), 3)
	assert_eq(_state.money, 3150)
	assert_true(_state.bag.is_favorite(&"potion"), "reste favori")
	assert_eq(_screen.results, [["Merci !", true]] as Array[Array])


func test_the_parcel_is_never_for_sale() -> void:
	_state.bag.add(&"oak_parcel", 1)
	_state.bag.add(&"potion", 1)
	assert_true(_open(MenuRoute.SHOP_MODE_SELL))
	assert_null(_shown().entry(&"oak_parcel"), "le colis n'est pas en VENDRE")
	assert_not_null(_shown().entry(&"potion"))
	assert_eq(_director.sell(&"oak_parcel", 1), ShopRules.Status.NOT_SELLABLE)
	assert_eq(_screen.results, [["Je ne peux pas te reprendre ça.", false]] as Array[Array])
	assert_true(_state.bag.has(&"oak_parcel"))


func test_nothing_to_sell() -> void:
	assert_true(_open(MenuRoute.SHOP_MODE_SELL))
	assert_true(_shown().is_empty())
	assert_eq(_shown().empty_text, "Tu n'as rien à vendre.")


func test_without_shops_or_an_unknown_shop_the_placeholder_shows() -> void:
	assert_true(_director.open(MenuRoute.shop(&"nowhere"), true))
	assert_eq(_placeholders, [MenuRoute.SHOP] as Array[StringName], "boutique inconnue")
	assert_eq(_director.buy(&"potion", 1), ShopRules.Status.NOT_SOLD_HERE)
	assert_eq(_state.money, 3000)
	_director.close()
	var bare := MenuDirector.new()
	add_child_autofree(bare)
	bare.setup(_state, PokemonData.new(), ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(_state.flags, _state.party), func() -> bool: return true, _items)
	var shown: Array[StringName] = []
	bare.placeholder_shown.connect(shown.append)
	assert_true(bare.open(MenuRoute.shop(MART), true))
	assert_eq(shown, [MenuRoute.SHOP] as Array[StringName], "sans boutiques branchées")
	bare.close()


func test_no_transaction_once_closed() -> void:
	assert_true(_open())
	_director.close()
	assert_eq(_director.buy(&"potion", 1), ShopRules.Status.NOT_SOLD_HERE)
	assert_eq(_state.money, 3000)
	assert_null(_director.build_shop())
