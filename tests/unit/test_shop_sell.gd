extends GutTest
## Boutique d'Azuria et vente de la Pépite (jalon 13 T17, jalon-13.md §2.5, §2.15 ; dossier 16 §5) :
## stock D-13 (remèdes du J11, jamais de Repousse), VENDRE existe : la Pépite se vend la moitié
## de son prix (5 000 ₽), la confirmation du favori existe, l'objet clé reste invendable.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _items: ItemLibrary
var _shops: ShopLibrary
var _mart: ShopData
var _nugget: ItemData
var _state: Node


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()
	_shops = ShopLibrary.new()
	_shops.load_dir()
	assert_true(_shops.check_references(_items), "boutiques : objets connus")
	_mart = _shops.get_shop(&"cerulean_mart")
	_nugget = _items.get_item(&"nugget")


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-10-13T10:00:00")
	_state.new_game(7)


func after_each() -> void:
	_state.free()


func test_the_stock_is_the_agreed_one_without_repel() -> void:
	assert_not_null(_mart, "boutique cerulean_mart")
	var ids := _mart.item_ids()
	assert_eq(ids, [&"poke_ball", &"potion", &"antidote", &"paralyze_heal", &"awakening",
		&"ice_heal", &"burn_heal", &"escape_rope"] as Array[StringName],
		"Corde Sortie (J12) en dernier ; Repousse : jamais (D-13)")
	assert_false(ids.has(&"repel"))
	assert_false(ids.has(&"nugget"), "la Pépite ne s'achète pas")
	for entry: Dictionary in _mart.stock:
		assert_true((entry.get("if", []) as Array).is_empty(), "tout le stock est disponible dès l'arrivée")


func test_the_nugget_sells_for_5000_and_is_not_a_key_item() -> void:
	assert_not_null(_nugget)
	assert_eq(_nugget.price, 10000)
	assert_eq(_nugget.sell_price(), 5000, "⌊10 000 / 2⌋")
	assert_true(_nugget.is_sellable())
	_state.bag.add(&"nugget", 1)
	var before: int = _state.money
	assert_eq(ShopRules.max_sell(_nugget, _state.bag), 1)
	assert_eq(ShopRules.sell(_state, _nugget, 1), ShopRules.Status.OK)
	assert_eq(_state.money, before + 5000)
	assert_eq(_state.bag.count_of(&"nugget"), 0, "sortie du Sac")


func test_a_favorite_nugget_asks_for_confirmation_then_sells() -> void:
	_state.bag.add(&"nugget", 1)
	_state.bag.set_favorite(&"nugget", true)
	var before: int = _state.money
	assert_eq(ShopRules.sell(_state, _nugget, 1), ShopRules.Status.NEEDS_CONFIRM)
	assert_eq(_state.money, before, "rien ne change sur le refus")
	assert_eq(ShopRules.sell(_state, _nugget, 1, true), ShopRules.Status.OK)
	assert_eq(_state.money, before + 5000)


func test_the_nugget_cannot_be_sold_when_missing() -> void:
	assert_eq(ShopRules.sell(_state, _nugget, 1), ShopRules.Status.NOT_ENOUGH_ITEMS)


func test_tm11_is_never_sold() -> void:
	var tm := _items.get_item(&"tm11")
	assert_not_null(tm)
	assert_false(tm.is_sellable(), "CT jamais vendues")
