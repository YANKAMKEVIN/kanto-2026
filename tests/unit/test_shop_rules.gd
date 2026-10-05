extends GutTest
## ShopRules (jalon-07.md §3.4 ; dossier 09 §9, §10) : achat exact, argent insuffisant,
## quantités, stock conditionnel, vente à moitié prix, objet clé refusé, favori confirmé,
## rien ne change sur un refus, ordre d'obtention tenu à l'achat.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _items: ItemLibrary
var _shops: ShopLibrary
var _mart: ShopData
var _state: Node
var _ball: ItemData
var _potion: ItemData
var _parcel: ItemData


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()
	_shops = ShopLibrary.new()
	_shops.load_dir()
	_shops.check_references(_items)
	_mart = _shops.get_shop(&"viridian_mart")
	_ball = _items.get_item(&"poke_ball")
	_potion = _items.get_item(&"potion")
	_parcel = _items.get_item(&"oak_parcel")


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-10-05T10:00:00")
	_state.new_game(7)


func after_each() -> void:
	_state.free()


## Argent et Sac, pour vérifier qu'un refus ne change rien.
func _snapshot() -> Array:
	return [_state.money, _state.bag.to_dict()]


# --- Achat -----------------------------------------------------------------------------------

func test_buy_exact_amount() -> void:
	assert_eq(_state.money, 3000, "nouvelle partie : 3 000 ₽")
	assert_eq(ShopRules.buy(_state, _mart, _ball, 5), ShopRules.Status.OK)
	assert_eq(_state.money, 2000, "5 × 200 ₽")
	assert_eq(_state.bag.count_of(&"poke_ball"), 5)
	assert_eq(ShopRules.buy(_state, _mart, _potion, 1), ShopRules.Status.OK)
	assert_eq(_state.money, 1700)
	assert_eq(_state.bag.count_of(&"potion"), 1)


func test_buy_with_exactly_the_money_leaves_zero() -> void:
	_state.money = 600
	assert_eq(ShopRules.buy(_state, _mart, _ball, 3), ShopRules.Status.OK)
	assert_eq(_state.money, 0, "jamais négatif, exactement 0")


func test_not_enough_money_changes_nothing() -> void:
	_state.money = 599
	var before := _snapshot()
	assert_eq(ShopRules.buy(_state, _mart, _ball, 3), ShopRules.Status.NOT_ENOUGH_MONEY)
	assert_eq(_snapshot(), before)
	assert_eq(ShopRules.buy(_state, _mart, _ball, 2), ShopRules.Status.OK)
	assert_eq(_state.money, 199)


func test_bad_quantities_change_nothing() -> void:
	var before := _snapshot()
	for quantity: int in [0, -1, ShopRules.MAX_QUANTITY + 1]:
		assert_eq(ShopRules.buy(_state, _mart, _ball, quantity), ShopRules.Status.BAD_QUANTITY,
			str(quantity))
	assert_eq(ShopRules.buy(_state, _mart, null, 1), ShopRules.Status.BAD_QUANTITY)
	assert_eq(ShopRules.buy(null, _mart, _ball, 1), ShopRules.Status.BAD_QUANTITY)
	assert_eq(_snapshot(), before)


func test_ninety_nine_is_the_maximum() -> void:
	_state.money = GameStateScript.MONEY_MAX
	assert_eq(ShopRules.buy(_state, _mart, _potion, 99), ShopRules.Status.OK)
	assert_eq(_state.bag.count_of(&"potion"), 99)
	assert_eq(_state.money, GameStateScript.MONEY_MAX - 99 * 300)


func test_not_sold_here_changes_nothing() -> void:
	var before := _snapshot()
	assert_eq(ShopRules.buy(_state, _mart, _parcel, 1), ShopRules.Status.NOT_SOLD_HERE,
		"objet clé, hors stock")
	var other := ShopLibrary.new()
	other.add_from_dict({"mart": {"stock": [{"item": "potion"},
		{"item": "poke_ball", "if": ["pokedex_activated"]}]}}, "t")
	var mart := other.get_shop(&"mart")
	assert_eq(ShopRules.buy(_state, mart, _ball, 1), ShopRules.Status.NOT_SOLD_HERE,
		"pas encore en stock")
	assert_eq(ShopRules.buy(_state, null, _ball, 1), ShopRules.Status.NOT_SOLD_HERE)
	assert_eq(_snapshot(), before)
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(ShopRules.buy(_state, mart, _ball, 1), ShopRules.Status.OK, "le stock évolue")


## jalon-06.md Q-12 : un achat rend l'objet « obtenu le plus récemment » (tri « récents »).
func test_buying_updates_the_acquired_order() -> void:
	_state.bag.add(&"potion", 1)
	_state.bag.add(&"poke_ball", 1)
	assert_gt(_state.bag.acquired_rank(&"poke_ball"), _state.bag.acquired_rank(&"potion"))
	ShopRules.buy(_state, _mart, _potion, 1)
	assert_gt(_state.bag.acquired_rank(&"potion"), _state.bag.acquired_rank(&"poke_ball"),
		"la Potion achetée passe en tête des récents")


func test_max_buy() -> void:
	assert_eq(ShopRules.max_buy(_ball, 3000), 15)
	assert_eq(ShopRules.max_buy(_ball, 199), 0)
	assert_eq(ShopRules.max_buy(_ball, 200), 1)
	assert_eq(ShopRules.max_buy(_potion, 999_999), ShopRules.MAX_QUANTITY)
	assert_eq(ShopRules.max_buy(_parcel, 999_999), 0, "objet clé")
	assert_eq(ShopRules.max_buy(_ball, 0), 0)
	assert_eq(ShopRules.max_buy(null, 3000), 0)
	assert_eq(ShopRules.buy_total(_ball, 3), 600)
	assert_eq(ShopRules.sell_total(_potion, 3), 450)
	assert_eq(ShopRules.buy_total(_ball, 0), 0)


# --- Vente -----------------------------------------------------------------------------------

func test_sell_at_half_price() -> void:
	_state.bag.add(&"potion", 3)
	assert_eq(ShopRules.sell(_state, _potion, 2), ShopRules.Status.OK)
	assert_eq(_state.bag.count_of(&"potion"), 1)
	assert_eq(_state.money, 3300, "2 × 150 ₽")
	assert_eq(ShopRules.sell(_state, _potion, 1), ShopRules.Status.OK)
	assert_false(_state.bag.has(&"potion"), "à 0, l'objet quitte le Sac")
	assert_eq(_state.money, 3450)


func test_key_item_is_never_sold() -> void:
	_state.bag.add(&"oak_parcel", 1)
	var before := _snapshot()
	assert_eq(ShopRules.sell(_state, _parcel, 1), ShopRules.Status.NOT_SELLABLE)
	assert_eq(ShopRules.sell(_state, _parcel, 1, true), ShopRules.Status.NOT_SELLABLE,
		"même confirmé")
	assert_eq(_snapshot(), before)
	assert_eq(ShopRules.max_sell(_parcel, _state.bag), 0)


func test_not_enough_items_or_bad_quantity_changes_nothing() -> void:
	_state.bag.add(&"potion", 2)
	var before := _snapshot()
	assert_eq(ShopRules.sell(_state, _potion, 3), ShopRules.Status.NOT_ENOUGH_ITEMS)
	assert_eq(ShopRules.sell(_state, _ball, 1), ShopRules.Status.NOT_ENOUGH_ITEMS,
		"absent du Sac")
	assert_eq(ShopRules.sell(_state, _potion, 0), ShopRules.Status.BAD_QUANTITY)
	assert_eq(ShopRules.sell(_state, _potion, 100), ShopRules.Status.BAD_QUANTITY)
	assert_eq(ShopRules.sell(_state, null, 1), ShopRules.Status.BAD_QUANTITY)
	assert_eq(_snapshot(), before)


## Décision de Kevin : vendre un favori demande une confirmation.
func test_favorite_needs_confirmation_then_sells() -> void:
	_state.bag.add(&"potion", 2)
	_state.bag.set_favorite(&"potion", true)
	var before := _snapshot()
	assert_eq(ShopRules.sell(_state, _potion, 1), ShopRules.Status.NEEDS_CONFIRM)
	assert_eq(_snapshot(), before, "rien vendu sans confirmation")
	assert_eq(ShopRules.sell(_state, _potion, 1, true), ShopRules.Status.OK)
	assert_eq(_state.bag.count_of(&"potion"), 1)
	assert_eq(_state.money, 3150)
	assert_eq(ShopRules.sell(_state, _potion, 1), ShopRules.Status.NEEDS_CONFIRM,
		"chaque vente d'un favori")
	assert_eq(ShopRules.sell(_state, _potion, 1, true), ShopRules.Status.OK)
	assert_true(_state.bag.is_favorite(&"potion"), "le favori reste (il reviendra favori)")


func test_not_enough_items_comes_before_the_confirmation() -> void:
	_state.bag.add(&"potion", 1)
	_state.bag.set_favorite(&"potion", true)
	assert_eq(ShopRules.sell(_state, _potion, 2), ShopRules.Status.NOT_ENOUGH_ITEMS)


func test_selling_at_the_money_ceiling_keeps_it_capped() -> void:
	_state.bag.add(&"potion", 10)
	_state.money = GameStateScript.MONEY_MAX - 100
	assert_eq(ShopRules.sell(_state, _potion, 10), ShopRules.Status.OK)
	assert_eq(_state.money, GameStateScript.MONEY_MAX, "plafond de Rouge/Bleu")
	assert_false(_state.bag.has(&"potion"))


func test_max_sell() -> void:
	assert_eq(ShopRules.max_sell(_potion, _state.bag), 0)
	_state.bag.add(&"potion", 120)
	assert_eq(ShopRules.max_sell(_potion, _state.bag), ShopRules.MAX_QUANTITY)
	assert_eq(ShopRules.max_sell(null, _state.bag), 0)


## Dossier 09 §10 : aucune perte d'argent à la défaite — rien hors de la Boutique ne débite
## l'argent : seules la Boutique (ShopRules) et GameState touchent à `money`.
func test_only_the_shop_spends_money() -> void:
	var allowed := ["res://game/autoload/game_state.gd", "res://game/systems/shop/shop_rules.gd"]
	for path: String in _scripts("res://game"):
		if allowed.has(path):
			continue
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("spend_money"), path)
		assert_false(text.contains("money -="), path)


func _scripts(dir: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_scripts(dir.path_join(sub)))
	return found
