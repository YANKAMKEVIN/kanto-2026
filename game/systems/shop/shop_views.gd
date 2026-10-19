class_name ShopViews
extends RefCounted
## Vues de l'écran de la Boutique (dossier 09 §9 et §19, jalon-07.md §3.4, §6.9) : ce qui est
## en vente ou vendable, l'argent, les totaux, les messages. Classe pure, statique : l'écran
## ne reçoit que des [ShopView] et des textes.
##
## Libellés et messages validés (dossier 09 §19 ; les autres : lot de textes validé par Kevin le
## 2026-10-06).

## Onglets.
const MODE_BUY: StringName = &"buy"
const MODE_SELL: StringName = &"sell"
const MODES: Array[StringName] = [MODE_BUY, MODE_SELL]
## Libellés de l'écran (dossier 09 §19).
const LABEL_BUY: String = "ACHETER"
const LABEL_SELL: String = "VENDRE"
const LABEL_QUANTITY: String = "QUANTITÉ"
const LABEL_TOTAL: String = "TOTAL"
const LABEL_OWNED: String = "DANS LE SAC"
const LABEL_CONFIRM: String = "CONFIRMER"
const LABEL_BACK: String = "RETOUR"
## « DANS LE SAC : 3 ».
const OWNED_FORMAT: String = "DANS LE SAC : %d"
## Messages (dossier 09 §19).
const TEXT_THANKS: String = "Merci !"
const TEXT_NO_MONEY: String = "Tu n'as pas assez d'argent."
const TEXT_NOT_SELLABLE: String = "Je ne peux pas te reprendre ça."
## CT déjà dans le Sac (jalon 20, annexe A, n° 160), à la place du prix.
const TEXT_ALREADY_OWNED: String = "Déjà dans le Sac"
## VENDRE sans rien de vendable.
const TEXT_NOTHING_TO_SELL: String = "Tu n'as rien à vendre."
## Confirmation de la vente d'un favori : « Vendre Potion ? », « Vendre 3 Potions ? ».
const SELL_CONFIRM_ONE: String = "Vendre %s ?"
const SELL_CONFIRM_MANY: String = "Vendre %d %s ?"
const SELL_CONFIRM_DETAIL: String = "C'est un de tes favoris."
const SELL_CONFIRM_LABEL: String = "VENDRE"
const SELL_CANCEL_LABEL: String = "ANNULER"


## Vue de l'onglet [param mode] de [param shop] pour [param state] (argent, Sac, drapeaux).
## ACHETER : le stock du moment ([method ShopRules.stock]), chaque objet borné par l'argent.
## VENDRE : les objets vendables du Sac (jamais un objet clé), dans l'ordre des données. Un
## objet inconnu de [param items] est omis (push_error).
static func build(state: Object, shop: ShopData, items: ItemLibrary,
		mode: StringName = MODE_BUY) -> ShopView:
	var view := ShopView.new()
	view.mode = mode if MODES.has(mode) else MODE_BUY
	view.shop_id = shop.id if shop != null else &""
	view.modes = MODES.duplicate()
	view.mode_labels = PackedStringArray([LABEL_BUY, LABEL_SELL])
	if state == null or items == null:
		return view
	var money := int(state.money)
	var bag: Bag = state.bag
	view.money_text = MenuFormat.money(money)
	if view.mode == MODE_BUY:
		for id: StringName in ShopRules.stock(shop, state.flags):
			var item := _item(items, id)
			if item != null:
				view.entries.append(_buy_entry(item, bag, money))
	else:
		var sellable: Array[ItemData] = []
		for id: StringName in bag.get_ids():
			var item := _item(items, id)
			if item != null and item.is_sellable():
				sellable.append(item)
		sellable.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.order < b.order)
		for item: ItemData in sellable:
			view.entries.append(_sell_entry(item, bag))
		if view.entries.is_empty():
			view.empty_text = TEXT_NOTHING_TO_SELL
	return view


## TOTAL : « 600 ₽ » (prix unitaire × quantité, calculé à chaque cran du sélecteur).
static func total_text(unit_price: int, quantity: int) -> String:
	return MenuFormat.money(unit_price * maxi(quantity, 0))


## Message après une transaction ([enum ShopRules.Status]) : « Merci ! », « Tu n'as pas assez
## d'argent. », « Je ne peux pas te reprendre ça. » ; "" pour les autres (rien à afficher :
## NEEDS_CONFIRM ouvre la confirmation, les autres ne viennent pas d'un geste de l'écran).
static func status_text(status: ShopRules.Status) -> String:
	match status:
		ShopRules.Status.OK:
			return TEXT_THANKS
		ShopRules.Status.NOT_ENOUGH_MONEY:
			return TEXT_NO_MONEY
		ShopRules.Status.NOT_SELLABLE:
			return TEXT_NOT_SELLABLE
	return ""


## Confirmation de la vente d'un favori (`ChoiceCards`) : « Vendre Potion ? », VENDRE (avec le
## gain) / ANNULER.
static func sell_confirm_view(entry: ShopEntryView, quantity: int) -> ChoiceView:
	var name := entry.name if entry != null else ""
	var plural := entry.plural if entry != null else ""
	var question := SELL_CONFIRM_ONE % name if quantity <= 1 \
		else SELL_CONFIRM_MANY % [quantity, plural]
	var view := ChoiceView.new(question, SELL_CONFIRM_LABEL, SELL_CANCEL_LABEL)
	view.detail = SELL_CONFIRM_DETAIL
	if entry != null:
		view.confirm_detail = "+" + total_text(entry.unit_price, quantity)
	return view


static func _buy_entry(item: ItemData, bag: Bag, money: int) -> ShopEntryView:
	var entry := _entry(item, bag)
	entry.unit_price = item.price
	entry.price_text = MenuFormat.money(item.price)
	entry.max_quantity = ShopRules.max_buy(item, money, bag)
	if item.is_permanent() and bag.has(item.id):
		entry.price_text = TEXT_ALREADY_OWNED
		entry.reason = TEXT_ALREADY_OWNED
	elif entry.max_quantity == 0:
		entry.reason = TEXT_NO_MONEY
	return entry


static func _sell_entry(item: ItemData, bag: Bag) -> ShopEntryView:
	var entry := _entry(item, bag)
	entry.unit_price = item.sell_price()
	entry.price_text = MenuFormat.money(entry.unit_price)
	entry.max_quantity = ShopRules.max_sell(item, bag)
	entry.needs_confirm = entry.favorite
	return entry


static func _entry(item: ItemData, bag: Bag) -> ShopEntryView:
	var entry := ShopEntryView.new()
	entry.item_id = item.id
	entry.name = item.name
	entry.plural = item.plural
	entry.description = item.description
	entry.category_id = item.category_id()
	entry.owned = bag.count_of(item.id)
	entry.owned_text = OWNED_FORMAT % entry.owned
	entry.favorite = bag.is_favorite(item.id)
	var card := BagEntryView.new(item.id, item.name_for(entry.owned), entry.owned,
		item.description, entry.category_id, true)
	card.favorite = entry.favorite
	entry.card = card
	return entry


static func _item(items: ItemLibrary, id: StringName) -> ItemData:
	var item := items.get_item(id)
	if item == null:
		push_error("ShopViews : objet inconnu « %s »" % id)
	return item
