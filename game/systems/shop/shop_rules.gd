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
}

## Quantité maximale d'une transaction (sélecteur QUANTITÉ, dossier 09 §9 ; Rouge/Bleu).
const MAX_QUANTITY: int = 99


## Objets en vente dans [param shop] pour l'état de [param flags] (conditions « if » /
## « unless »), dans l'ordre des données. Sans drapeaux (null) : les objets sans condition.
static func stock(shop: ShopData, flags: StoryFlags) -> Array[StringName]:
	var ids: Array[StringName] = []
	if shop == null:
		return ids
	for entry: Dictionary in shop.stock:
		var if_flags: Array[StringName] = entry["if"]
		var unless_flags: Array[StringName] = entry["unless"]
		if flags == null:
			if if_flags.is_empty():
				ids.append(entry["item"])
		elif flags.has_all(if_flags) and flags.has_none(unless_flags):
			ids.append(entry["item"])
	return ids


## Quantité maximale achetable de [param item] avec [param money] : 0 à
## [constant MAX_QUANTITY] (0 : objet sans prix, ou pas assez d'argent pour un seul).
static func max_buy(item: ItemData, money: int) -> int:
	if item == null or item.price <= 0 or item.is_key() or money <= 0:
		return 0
	return mini(MAX_QUANTITY, floori(float(money) / item.price))


## Quantité maximale vendable de [param item] : ce que contient [param bag], borné à
## [constant MAX_QUANTITY] ; 0 si l'objet ne se vend pas.
static func max_sell(item: ItemData, bag: Bag) -> int:
	if item == null or bag == null or not item.is_sellable():
		return 0
	return mini(MAX_QUANTITY, bag.count_of(item.id))


## Total d'un achat (prix × quantité, en ₽).
static func buy_total(item: ItemData, quantity: int) -> int:
	return item.price * quantity if item != null and quantity > 0 else 0


## Total d'une vente (prix de reprise × quantité, en ₽).
static func sell_total(item: ItemData, quantity: int) -> int:
	return item.sell_price() * quantity if item != null and quantity > 0 else 0


## Achète [param quantity] [param item] dans [param shop] : l'argent est débité, les objets
## ajoutés au Sac (et marqués « obtenus en dernier »). Sinon le refus, et rien ne change.
static func buy(state: Object, shop: ShopData, item: ItemData, quantity: int) -> Status:
	if state == null or item == null or quantity < 1 or quantity > MAX_QUANTITY:
		return Status.BAD_QUANTITY
	if not stock(shop, state.flags).has(item.id) or item.price <= 0 or item.is_key():
		return Status.NOT_SOLD_HERE
	var total := buy_total(item, quantity)
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
