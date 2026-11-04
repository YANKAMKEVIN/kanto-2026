class_name ShopRules
extends RefCounted
## Règles de la Boutique (dossier 09 §9 et §10, jalon-07.md §3.4) : ce qui est en vente, ce
## qu'on peut acheter ou vendre, et la transaction elle-même. Classe pure, statique.
##
## [param state] : l'autoload GameState (ou une instance de game_state.gd en test) ; seuls
## [code]money[/code], [code]bag[/code], [code]flags[/code], [code]spend_money[/code] et
## [code]add_money[/code] sont lus. **Un refus ne change rien** (ni argent, ni Sac). Acheter
## passe par [method Bag.add], qui tient l'ordre d'obtention (tri « récents » du Sac).
## Un achat ne demande jamais de seconde confirmation (dossier 09 §9) ; vendre un **favori**
## en demande une ([constant Status.NEEDS_CONFIRM]) ; un objet clé ne se vend jamais.

enum Status {
	## La transaction a eu lieu.
	OK,
	## Achat : le total dépasse l'argent du joueur.
	NOT_ENOUGH_MONEY,
	## Achat : l'objet n'est pas (ou pas encore) dans le stock de cette boutique.
	NOT_SOLD_HERE,
	## Vente : objet clé ou objet sans prix (« Je ne peux pas te reprendre ça. »).
	NOT_SELLABLE,
	## Vente : le Sac n'en contient pas autant.
	NOT_ENOUGH_ITEMS,
	## Vente d'un favori sans confirmation : rien n'est vendu, l'écran demande la confirmation.
	NEEDS_CONFIRM,
	## Quantité hors de 1 à [constant MAX_QUANTITY], ou objet absent.
	BAD_QUANTITY,
	## Achat d'un objet permanent (une CT, jalon 20) déjà dans le Sac.
	ALREADY_OWNED,
}

## Quantité maximale d'une transaction (sélecteur QUANTITÉ, dossier 09 §9 ; Rouge/Bleu).
const MAX_QUANTITY: int = 99


## Objets en vente dans [param shop] pour l'état de [param flags] (conditions « if » /
## « unless »), dans l'ordre des données. Sans drapeaux (null) : les objets sans condition.
## JOH3 : une ligne « if_weekday » n'est en vente que le jour [param weekday] (« monday »…) ;
## sans jour (&""), jamais.
static func stock(shop: ShopData, flags: StoryFlags, weekday: StringName = &"") \
		-> Array[StringName]:
	var ids: Array[StringName] = []
	if shop == null:
		return ids
	for entry: Dictionary in shop.stock:
		var days: Array = entry.get("if_weekday", [])
		if not days.is_empty() and not days.has(weekday):
			continue
		var if_flags: Array[StringName] = entry["if"]
		var unless_flags: Array[StringName] = entry["unless"]
		if flags == null:
			if if_flags.is_empty():
				ids.append(entry["item"])
		elif flags.has_all(if_flags) and flags.has_none(unless_flags):
			ids.append(entry["item"])
	return ids


## Quantité maximale achetable de [param item] avec [param money] : 0 à
## [constant MAX_QUANTITY] (0 : objet sans prix, ou pas assez d'argent pour un seul). Un objet
## permanent (une CT, jalon 20 §2.9.2) : 1 s'il n'est pas dans [param bag], 0 sinon.
## [param price] : prix unitaire (JOH3, promotion) ; -1 = [member ItemData.price].
static func max_buy(item: ItemData, money: int, bag: Bag = null, price: int = -1) -> int:
	if item == null or item.price <= 0 or item.is_key() or money <= 0:
		return 0
	var unit := item.price if price < 0 else price
	if unit <= 0:
		return 0
	if item.is_permanent():
		if bag != null and bag.has(item.id):
			return 0
		return 1 if money >= unit else 0
	return mini(MAX_QUANTITY, floori(float(money) / unit))


## Prix unitaire de [param item] dans [param shop] le jour [param weekday] (JOH3, JH-33) : la
## moitié du prix (arrondie à l'unité inférieure, au moins 1) si l'objet est en promotion ce
## jour-là, sinon [member ItemData.price]. Sans boutique ou sans jour : le prix normal.
static func unit_price(shop: ShopData, item: ItemData, weekday: StringName = &"") -> int:
	if item == null:
		return 0
	if shop == null or weekday.is_empty() or item.price <= 0:
		return item.price
	var promoted: Array = shop.promotions.get(weekday, [])
	return maxi(1, item.price / 2) if promoted.has(item.id) else item.price


## Vrai si [param item] est en promotion dans [param shop] le jour [param weekday] (JOH3).
static func is_promoted(shop: ShopData, item: ItemData, weekday: StringName) -> bool:
	return item != null and unit_price(shop, item, weekday) < item.price


## Quantité maximale vendable de [param item] : ce que contient [param bag], borné à
## [constant MAX_QUANTITY] ; 0 si l'objet ne se vend pas.
static func max_sell(item: ItemData, bag: Bag) -> int:
	if item == null or bag == null or not item.is_sellable():
		return 0
	return mini(MAX_QUANTITY, bag.count_of(item.id))


## Total d'un achat (prix × quantité, en ₽).
## [param price] : prix unitaire (-1 = celui de l'objet ; JOH3 : promotion du jour).
static func buy_total(item: ItemData, quantity: int, price: int = -1) -> int:
	if item == null or quantity <= 0:
		return 0
	return (item.price if price < 0 else price) * quantity


## Total d'une vente (prix de reprise × quantité, en ₽).
static func sell_total(item: ItemData, quantity: int) -> int:
	return item.sell_price() * quantity if item != null and quantity > 0 else 0


## Achète [param quantity] [param item] dans [param shop] : l'argent est débité, les objets
## ajoutés au Sac (et marqués « obtenus en dernier »). Sinon le refus, et rien ne change. Un
## objet permanent (CT) s'achète un à la fois, seulement s'il n'est pas déjà dans le Sac.
## [param weekday] (JOH3) : jour de l'achat (lignes « if_weekday », promotion du jour).
static func buy(state: Object, shop: ShopData, item: ItemData, quantity: int,
		weekday: StringName = &"") -> Status:
	if state == null or item == null or quantity < 1 or quantity > MAX_QUANTITY:
		return Status.BAD_QUANTITY
	if not stock(shop, state.flags, weekday).has(item.id) or item.price <= 0 or item.is_key():
		return Status.NOT_SOLD_HERE
	if item.is_permanent():
		if (state.bag as Bag).has(item.id):
			return Status.ALREADY_OWNED
		if quantity > 1:
			return Status.BAD_QUANTITY
	var total := buy_total(item, quantity, unit_price(shop, item, weekday))
	if total > int(state.money):
		return Status.NOT_ENOUGH_MONEY
	if not state.spend_money(total):
		return Status.NOT_ENOUGH_MONEY
	(state.bag as Bag).add(item.id, quantity)
	return Status.OK


## Vend [param quantity] [param item] : les objets quittent le Sac, la moitié du prix est
## versée (plafond de l'argent : l'excédent est perdu, comme dans Rouge/Bleu). Un favori
## renvoie [constant Status.NEEDS_CONFIRM] tant que [param confirmed] est faux ; un objet clé
## [constant Status.NOT_SELLABLE]. Sur un refus, rien ne change.
static func sell(state: Object, item: ItemData, quantity: int, confirmed: bool = false) -> Status:
	if state == null or item == null:
		return Status.BAD_QUANTITY
	if not item.is_sellable():
		return Status.NOT_SELLABLE
	if quantity < 1 or quantity > MAX_QUANTITY:
		return Status.BAD_QUANTITY
	var bag: Bag = state.bag
	if bag.count_of(item.id) < quantity:
		return Status.NOT_ENOUGH_ITEMS
	if bag.is_favorite(item.id) and not confirmed:
		return Status.NEEDS_CONFIRM
	bag.remove(item.id, quantity)
	state.add_money(sell_total(item, quantity))
	return Status.OK
