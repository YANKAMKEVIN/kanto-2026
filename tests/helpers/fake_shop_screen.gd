extends Node
## Écran factice de la Boutique (jalon-07.md §6.10, T12) : la partie « Boutique » de l'interface
## figée de `TrainerMenu` (signaux et méthodes du T11), sans rendu, qui journalise ce qu'on lui
## demande. Sert à tester [MenuDirector] et le câblage de [Boot] tant que le `ShopScreen` du
## T11 n'est pas fusionné. [method wire] reproduit **exactement** le câblage de `Boot._ready`
## (derrière `has_signal(&"shop_buy_requested")`).

signal shop_mode_changed(mode: StringName)
signal shop_buy_requested(item_id: StringName, quantity: int)
signal shop_sell_requested(item_id: StringName, quantity: int, confirmed: bool)

var shops: Array[ShopView] = []
var results: Array[Array] = []
var confirms: Array[Array] = []
## Réponse de [method shop_back] (une confirmation ouverte : vrai).
var confirm_open: bool = false
var back_count: int = 0


func show_shop(view: ShopView) -> void:
	shops.append(view)


func show_shop_result(text: String, ok: bool) -> void:
	results.append([text, ok])


func show_shop_confirm(view: ChoiceView, item_id: StringName, quantity: int) -> void:
	confirms.append([view, item_id, quantity])
	confirm_open = true


func shop_back() -> bool:
	back_count += 1
	var was_open := confirm_open
	confirm_open = false
	return was_open


## Le joueur touche VENDRE dans la confirmation (ChoiceCards.chosen(true)).
func confirm_sell() -> void:
	var last: Array = confirms.back()
	confirm_open = false
	shop_sell_requested.emit(last[1], last[2], true)


func last_shop() -> ShopView:
	return shops.back() if not shops.is_empty() else null


func wire(director: MenuDirector) -> void:
	director.shop_shown.connect(Callable(self, &"show_shop"))
	director.shop_result_shown.connect(Callable(self, &"show_shop_result"))
	director.shop_confirm_requested.connect(Callable(self, &"show_shop_confirm"))
	connect(&"shop_mode_changed", director.set_shop_mode)
	connect(&"shop_buy_requested", director.buy)
	connect(&"shop_sell_requested", director.sell)
