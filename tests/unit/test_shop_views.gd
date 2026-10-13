extends GutTest
## ShopViews, ShopView, ShopEntryView (jalon-07.md §3.4, §6.9 ; dossier 09 §9, §19) : onglets,
## argent, prix, DANS LE SAC, quantités bornées, raisons, totaux, messages, confirmation d'un
## favori, objet clé absent de VENDRE, rien du Pokédex.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _items: ItemLibrary
var _mart: ShopData
var _state: Node
var _nbsp: String = MenuFormat.THOUSANDS_SEPARATOR


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()
	var shops := ShopLibrary.new()
	shops.load_dir()
	shops.check_references(_items)
	_mart = shops.get_shop(&"viridian_mart")


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-10-05T10:00:00")
	_state.new_game(7)


func after_each() -> void:
	_state.free()


func _money(text: String) -> String:
	return text.replace(" ", _nbsp) + _nbsp + "₽"


func _ids(view: ShopView) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: ShopEntryView in view.entries:
		ids.append(entry.item_id)
	return ids


func test_buy_tab() -> void:
	_state.bag.add(&"poke_ball", 3)
	var view := ShopViews.build(_state, _mart, _items)
	assert_eq(view.mode, ShopViews.MODE_BUY, "ACHETER par défaut")
	assert_eq(view.shop_id, &"viridian_mart")
	assert_eq(view.modes, [&"buy", &"sell"] as Array[StringName])
	assert_eq(view.mode_labels, PackedStringArray(["ACHETER", "VENDRE"]))
	assert_eq(view.money_text, _money("3 000"))
	assert_eq(_ids(view), [&"poke_ball", &"potion", &"paralyze_heal", &"awakening", &"burn_heal"] as Array[StringName],
		"ordre du stock")
	assert_eq(view.empty_text, "")
	var ball := view.entry(&"poke_ball")
	assert_eq(ball.name, "Poké Ball")
	assert_eq(ball.plural, "Poké Balls")
	assert_eq(ball.description, "Permet de capturer un Pokémon sauvage.")
	assert_eq(ball.category_id, &"ball")
	assert_eq(ball.unit_price, 200)
	assert_eq(ball.price_text, _money("200"))
	assert_eq(ball.owned, 3)
	assert_eq(ball.owned_text, "DANS LE SAC : 3")
	assert_eq(ball.max_quantity, 15, "3 000 ₽ / 200 ₽")
	assert_true(ball.is_available())
	assert_eq(ball.reason, "")
	assert_false(ball.needs_confirm, "un achat ne demande jamais de confirmation")
	assert_eq(ball.card.display_name, "Poké Balls", "carte du Sac, nom accordé")
	assert_eq(ball.card.quantity, 3)
	assert_not_null(ball.get_icon())
	var potion := view.entry(&"potion")
	assert_eq(potion.owned_text, "DANS LE SAC : 0", "toujours écrit à l'achat")
	assert_eq(potion.max_quantity, 10)
	assert_null(view.entry(&"oak_parcel"))


func test_buy_tab_without_enough_money_gives_the_reason() -> void:
	_state.money = 250
	var view := ShopViews.build(_state, _mart, _items, ShopViews.MODE_BUY)
	assert_eq(view.entry(&"poke_ball").max_quantity, 1)
	var potion := view.entry(&"potion")
	assert_eq(potion.max_quantity, 0)
	assert_false(potion.is_available())
	assert_eq(potion.reason, "Tu n'as pas assez d'argent.")
	assert_eq(potion.clamp_quantity(5), 1, "sélecteur : 1 même indisponible")


func test_quantity_is_clamped_by_max() -> void:
	var ball := ShopViews.build(_state, _mart, _items).entry(&"poke_ball")
	assert_eq(ball.clamp_quantity(0), 1)
	assert_eq(ball.clamp_quantity(7), 7)
	assert_eq(ball.clamp_quantity(99), 15)


func test_sell_tab_lists_only_sellable_items_in_data_order() -> void:
	_state.bag.add(&"potion", 2)
	_state.bag.add(&"oak_parcel", 1)
	_state.bag.add(&"poke_ball", 4)
	_state.bag.set_favorite(&"potion", true)
	var view := ShopViews.build(_state, _mart, _items, ShopViews.MODE_SELL)
	assert_eq(view.mode, ShopViews.MODE_SELL)
	assert_eq(_ids(view), [&"poke_ball", &"potion"] as Array[StringName],
		"ordre des données ; le colis (objet clé) n'y est pas")
	var ball := view.entry(&"poke_ball")
	assert_eq(ball.unit_price, 100, "moitié du prix")
	assert_eq(ball.price_text, _money("100"))
	assert_eq(ball.max_quantity, 4, "ce que contient le Sac")
	assert_false(ball.needs_confirm)
	var potion := view.entry(&"potion")
	assert_true(potion.favorite)
	assert_true(potion.card.favorite)
	assert_true(potion.needs_confirm, "favori : confirmation")
	assert_eq(potion.unit_price, 150)


func test_sell_tab_with_nothing_to_sell() -> void:
	_state.bag.add(&"oak_parcel", 1)
	var view := ShopViews.build(_state, _mart, _items, ShopViews.MODE_SELL)
	assert_true(view.is_empty())
	assert_eq(view.empty_text, "Tu n'as rien à vendre.")
	assert_eq(view.money_text, _money("3 000"), "l'argent reste affiché")


func test_conditional_stock_in_the_view() -> void:
	var shops := ShopLibrary.new()
	shops.add_from_dict({"mart": {"stock": [{"item": "potion"},
		{"item": "poke_ball", "unless": ["got_oak_parcel"]}]}}, "t")
	var mart := shops.get_shop(&"mart")
	assert_eq(_ids(ShopViews.build(_state, mart, _items)).size(), 2)
	_state.flags.set_flag(&"got_oak_parcel")
	assert_eq(_ids(ShopViews.build(_state, mart, _items)), [&"potion"] as Array[StringName])


func test_unknown_mode_and_missing_state() -> void:
	assert_eq(ShopViews.build(_state, _mart, _items, &"steal").mode, ShopViews.MODE_BUY)
	var empty := ShopViews.build(null, _mart, _items)
	assert_true(empty.is_empty())
	assert_eq(empty.money_text, "")


func test_total_text() -> void:
	assert_eq(ShopViews.total_text(200, 3), _money("600"))
	assert_eq(ShopViews.total_text(300, 10), _money("3 000"))
	assert_eq(ShopViews.total_text(200, 0), _money("0"))


## Dossier 09 §19.
func test_status_texts_and_labels() -> void:
	assert_eq(ShopViews.status_text(ShopRules.Status.OK), "Merci !")
	assert_eq(ShopViews.status_text(ShopRules.Status.NOT_ENOUGH_MONEY),
		"Tu n'as pas assez d'argent.")
	assert_eq(ShopViews.status_text(ShopRules.Status.NOT_SELLABLE),
		"Je ne peux pas te reprendre ça.")
	assert_eq(ShopViews.status_text(ShopRules.Status.NEEDS_CONFIRM), "")
	assert_eq([ShopViews.LABEL_BUY, ShopViews.LABEL_SELL, ShopViews.LABEL_QUANTITY,
		ShopViews.LABEL_TOTAL, ShopViews.LABEL_OWNED, ShopViews.LABEL_CONFIRM,
		ShopViews.LABEL_BACK], ["ACHETER", "VENDRE", "QUANTITÉ", "TOTAL", "DANS LE SAC",
		"CONFIRMER", "RETOUR"])


func test_sell_confirm_view() -> void:
	_state.bag.add(&"potion", 3)
	_state.bag.set_favorite(&"potion", true)
	var potion := ShopViews.build(_state, _mart, _items, ShopViews.MODE_SELL).entry(&"potion")
	var one := ShopViews.sell_confirm_view(potion, 1)
	assert_eq(one.title, "Vendre Potion ?")
	assert_eq(one.detail, "C'est un de tes favoris.")
	assert_eq(one.confirm_label, "VENDRE")
	assert_eq(one.cancel_label, "ANNULER")
	assert_eq(one.confirm_detail, "+" + _money("150"))
	var many := ShopViews.sell_confirm_view(potion, 3)
	assert_eq(many.title, "Vendre 3 Potions ?")
	assert_eq(many.confirm_detail, "+" + _money("450"))


## Règle de déblocage : rien du Pokédex dans la Boutique.
func test_no_pokedex_word_anywhere() -> void:
	_state.bag.add(&"potion", 1)
	for mode: StringName in ShopViews.MODES:
		var view := ShopViews.build(_state, _mart, _items, mode)
		var texts := PackedStringArray(view.mode_labels)
		texts.append_array([view.money_text, view.empty_text])
		for entry: ShopEntryView in view.entries:
			texts.append_array([entry.name, entry.description, entry.owned_text,
				entry.price_text, entry.reason])
		assert_false(" ".join(texts).to_lower().contains("pokédex"), String(mode))
