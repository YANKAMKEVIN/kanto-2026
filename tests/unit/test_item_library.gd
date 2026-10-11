extends GutTest
## ItemLibrary et ItemData (jalon-04.md §14.6) : vraies données (la Poké Ball donnée par
## le Prof. Chen), validation stricte, textes du toast (bible UI §6) accordés.

const BALL := {
	"name": "Poké Ball", "plural": "Poké Balls", "feminine": true,
	"category": "ball", "catch_bonus": 1, "description": "Capture.",
}

var _library: ItemLibrary


func before_each() -> void:
	_library = ItemLibrary.new()


func test_real_data_loads_without_error() -> void:
	assert_true(_library.load_dir(), "data/items/ se charge")
	assert_eq(_library.get_errors().size(), 0, str(_library.get_errors()))
	# Jalon 5 : la Potion cachée de la Route 1 (catégorie « heal », ramassée seulement).
	assert_eq(_library.get_ids(), [&"antidote", &"oak_parcel", &"poke_ball", &"potion"] \
		as Array[StringName])
	var ball := _library.get_item(&"poke_ball")
	assert_eq(ball.name, "Poké Ball")
	assert_eq(ball.plural, "Poké Balls")
	assert_true(ball.feminine)
	assert_eq(ball.category, ItemData.Category.BALL)
	assert_eq(ball.catch_bonus, 1.0)
	assert_false(ball.draft, "description validé par Kevin le 2026-10-06")
	assert_eq(ball.source, "res://data/items/items.json")
	var potion := _library.get_item(&"potion")
	assert_eq(potion.name, "Potion")
	assert_eq(potion.category, ItemData.Category.HEAL)
	assert_eq(potion.catch_bonus, 1.0, "pas de catch_bonus hors Ball (valeur par défaut)")
	assert_eq(potion.heal_amount, 20, "jalon 6 : la Potion rend 20 PV")
	assert_eq(ball.heal_amount, 0)
	assert_eq(_library.get_ids_in_data_order(),
		[&"poke_ball", &"potion", &"antidote", &"oak_parcel"] as Array[StringName])
	assert_eq([ball.order, potion.order], [0, 1])


## Dossier 07 §8 (« Poké Balls ×5 ») et bible UI §6 (« Potion ×1 — Ajoutée au Sac »).
func test_toast_texts_of_the_five_poke_balls() -> void:
	_library.load_dir()
	var ball := _library.get_item(&"poke_ball")
	assert_eq(ball.quantity_text(5), "Poké Balls ×5")
	assert_eq(ball.added_text(5), "Ajoutées au Sac")
	assert_eq(ball.quantity_text(1), "Poké Ball ×1")
	assert_eq(ball.added_text(1), "Ajoutée au Sac")


func test_masculine_agreement() -> void:
	var item := ItemData.new()
	item.name = "Rappel"
	item.plural = "Rappels"
	item.feminine = false
	assert_eq(item.quantity_text(1), "Rappel ×1")
	assert_eq(item.added_text(1), "Ajouté au Sac")
	assert_eq(item.quantity_text(2), "Rappels ×2")
	assert_eq(item.added_text(2), "Ajoutés au Sac")


func test_valid_entry() -> void:
	assert_true(_library.add_from_dict({"poke_ball": BALL}, "test"))
	assert_true(_library.has_item(&"poke_ball"))
	assert_eq(_library.size(), 1)
	assert_false(_library.get_item(&"poke_ball").draft, "draft facultatif, faux par défaut")
	assert_null(_library.get_item(&"missing"))


func test_invalid_entries_are_rejected() -> void:
	var bad: Array[Dictionary] = []
	for key: String in ["name", "plural", "feminine", "category", "description"]:
		var entry := BALL.duplicate()
		entry.erase(key)
		bad.append(entry)
	var extra := BALL.duplicate()
	extra["cost"] = 200
	bad.append(extra)
	var no_bonus := BALL.duplicate()
	no_bonus.erase("catch_bonus")
	bad.append(no_bonus)
	var zero_bonus := BALL.duplicate()
	zero_bonus["catch_bonus"] = 0
	bad.append(zero_bonus)
	var unknown := BALL.duplicate()
	unknown["category"] = "berry"
	bad.append(unknown)
	var empty_name := BALL.duplicate()
	empty_name["name"] = " "
	bad.append(empty_name)
	var not_bool := BALL.duplicate()
	not_bool["feminine"] = "oui"
	bad.append(not_bool)
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"item_%d" % i: bad[i]}, "test"), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par entrée")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« name » est obligatoire", "clé inconnue « cost »",
			"« catch_bonus » doit être", "catégorie inconnue « berry »",
			"« name » doit être un texte", "« feminine » vaut true ou false"]:
		assert_string_contains(errors, expected)


## Jalon 5D : le multiplicateur de capture est une donnée de la Ball, lu par le moteur.
func test_catch_bonus_belongs_to_balls_only() -> void:
	var better := BALL.duplicate()
	better["catch_bonus"] = 1.5
	assert_true(_library.add_from_dict({"great_ball": better}, "test"))
	assert_eq(_library.get_item(&"great_ball").catch_bonus, 1.5, "nombre décimal accepté")
	var healing := BALL.duplicate()
	healing["category"] = "heal"
	healing["heal_amount"] = 20
	assert_false(_library.add_from_dict({"potion": healing}, "test"))
	assert_push_error("« catch_bonus » est réservé aux Balls")
	var negative := BALL.duplicate()
	negative["catch_bonus"] = -1
	var text := BALL.duplicate()
	text["catch_bonus"] = "1"
	assert_false(_library.add_from_dict({"a": negative, "b": text}, "test"))
	assert_push_error_count(3)
	assert_eq(_library.get_ids(), [&"great_ball"] as Array[StringName])


func test_duplicate_id_is_rejected() -> void:
	assert_true(_library.add_from_dict({"poke_ball": BALL}, "a.json"))
	assert_false(_library.add_from_dict({"poke_ball": BALL}, "b.json"))
	assert_push_error("déjà défini dans a.json")


func test_missing_dir_and_file() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/items/missing/"))
	assert_false(_library.load_file("res://tests/fixtures/items/missing.json"))
	assert_push_error_count(2)


# --- Jalon 6 (§3.4) : catégories, soins, contextes ---------------------------------------

const POTION := {
	"name": "Potion", "plural": "Potions", "feminine": true,
	"category": "heal", "heal_amount": 20, "description": "Soigne.",
}


func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var entry := base.duplicate()
	for key: Variant in changes:
		if changes[key] == null:
			entry.erase(key)
		else:
			entry[key] = changes[key]
	return entry


func test_new_categories_are_read_at_the_end_of_the_enum() -> void:
	assert_eq(ItemData.CATEGORY_NAMES, ["ball", "heal", "battle", "field", "key"]
		as Array[String])
	var plain := _with(BALL, {"catch_bonus": null})
	assert_true(_library.add_from_dict({
		"x_attack": _with(plain, {"category": "battle"}),
		"repel": _with(plain, {"category": "field"}),
		"parcel": _with(plain, {"category": "key"}),
	}, "test"), str(_library.get_errors()))
	assert_eq(_library.get_item(&"x_attack").category, ItemData.Category.BATTLE)
	assert_eq(_library.get_item(&"repel").category, ItemData.Category.FIELD)
	assert_eq(_library.get_item(&"parcel").category, ItemData.Category.KEY)
	assert_eq(_library.get_item(&"parcel").category_id(), &"key")
	assert_eq(_library.get_ids_in_data_order(), [&"x_attack", &"repel", &"parcel"]
		as Array[StringName], "ordre des données, pas l'ordre alphabétique")


func test_heal_amount_is_required_for_a_heal_and_refused_elsewhere() -> void:
	assert_true(_library.add_from_dict({"potion": POTION}, "test"))
	assert_eq(_library.get_item(&"potion").heal_amount, 20)
	var bad: Array[Dictionary] = [
		_with(POTION, {"heal_amount": null}),
		_with(POTION, {"heal_amount": 0}),
		_with(POTION, {"heal_amount": -5}),
		_with(POTION, {"heal_amount": 2.5}),
		_with(POTION, {"heal_amount": "20"}),
		_with(BALL, {"heal_amount": 20}),
	]
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"bad_%d" % i: bad[i]}, "test"), str(bad[i]))
	assert_push_error_count(bad.size())
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« heal_amount » doit être un entier > 0 pour un soin")
	assert_string_contains(errors, "« heal_amount » est réservé aux soins")
	assert_eq(_library.size(), 1)


func test_contexts_follow_the_category() -> void:
	var item := ItemData.new()
	var expected := {
		ItemData.Category.BALL: [&"wild_battle"],
		ItemData.Category.HEAL: [&"field", &"wild_battle", &"trainer_battle"],
		ItemData.Category.BATTLE: [&"wild_battle", &"trainer_battle"],
		ItemData.Category.FIELD: [&"field"],
		ItemData.Category.KEY: [],
	}
	for category: ItemData.Category in expected:
		item.category = category
		var contexts: Array = []
		contexts.assign(item.contexts())
		assert_eq(contexts, expected[category], ItemData.CATEGORY_NAMES[category])
	item.category = ItemData.Category.BALL
	assert_true(item.usable_in(ItemData.CONTEXT_WILD_BATTLE))
	assert_false(item.usable_in(ItemData.CONTEXT_TRAINER_BATTLE), "pas de Ball contre un dresseur")
	assert_false(item.usable_in(ItemData.CONTEXT_FIELD))
	assert_eq(ItemData.CONTEXT_FIELD, MenuRoute.BAG_CONTEXT_FIELD, "mêmes valeurs que le menu")


func test_only_heals_are_given_to_a_pokemon() -> void:
	assert_true(_library.load_dir())
	assert_true(_library.get_item(&"potion").targets_pokemon())
	assert_false(_library.get_item(&"poke_ball").targets_pokemon())


# --- Prix et objets clés (jalon-07.md §3.4, dossier 09 §9, §10, §19) -----------------------

func test_real_prices_and_the_parcel() -> void:
	assert_true(_library.load_dir())
	var ball := _library.get_item(&"poke_ball")
	var potion := _library.get_item(&"potion")
	assert_eq(ball.price, 200, "dossier 09 §10")
	assert_eq(potion.price, 300, "dossier 09 §10")
	assert_eq(ball.sell_price(), 100, "moitié du prix")
	assert_eq(potion.sell_price(), 150)
	assert_true(ball.is_sellable())
	var parcel := _library.get_item(&"oak_parcel")
	assert_eq(parcel.category, ItemData.Category.KEY)
	assert_true(parcel.is_key())
	assert_eq(parcel.price, 0, "un objet clé n'a jamais de prix")
	assert_false(parcel.is_sellable())
	assert_eq(parcel.sell_price(), 0)
	assert_false(parcel.draft, "description validée")
	assert_eq(parcel.contexts(), [] as Array[StringName], "jamais utilisé")


## Dossier 09 §19 : « COLIS POUR CHEN — ajouté aux objets clés ».
func test_key_item_toast_text() -> void:
	assert_true(_library.load_dir())
	var parcel := _library.get_item(&"oak_parcel")
	assert_eq(parcel.quantity_text(1), "COLIS POUR CHEN")
	assert_eq(parcel.added_text(1), "ajouté aux objets clés")
	var key := ItemData.new()
	key.name = "Clé"
	key.feminine = true
	key.category = ItemData.Category.KEY
	assert_eq(key.added_text(1), "ajoutée aux objets clés", "accordé au genre")


func test_sell_price_rounds_down_and_unpriced_items_do_not_sell() -> void:
	var odd := BALL.duplicate()
	odd["price"] = 25
	var free := BALL.duplicate()
	assert_true(_library.add_from_dict({"odd": odd, "free": free}, "test"))
	assert_eq(_library.get_item(&"odd").sell_price(), 12, "arrondi en dessous")
	assert_eq(_library.get_item(&"free").price, 0, "prix absent : 0")
	assert_false(_library.get_item(&"free").is_sellable(), "sans prix : jamais repris")
	assert_eq(_library.get_item(&"free").sell_price(), 0)


func test_invalid_prices_are_rejected() -> void:
	var negative := BALL.duplicate()
	negative["price"] = -1
	var decimal := BALL.duplicate()
	decimal["price"] = 2.5
	var text := BALL.duplicate()
	text["price"] = "200"
	var key := {"name": "Colis", "plural": "Colis", "feminine": false, "category": "key",
		"description": "x", "price": 100}
	var key_zero := key.duplicate()
	key_zero["price"] = 0
	assert_false(_library.add_from_dict({"a": negative, "b": decimal, "c": text, "d": key,
		"e": key_zero}, "test"))
	assert_eq(_library.get_ids(), [&"e"] as Array[StringName], "objet clé à 0 : accepté")
	assert_push_error_count(4)
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« price » doit être un entier ≥ 0")
	assert_string_contains(errors, "un objet clé n'a pas de prix")


## Jalon 9 : un soin rend des PV et / ou soigne des statuts (« cures »).
func test_cures() -> void:
	var antidote := {"name": "Antidote", "plural": "Antidotes", "feminine": false,
		"category": "heal", "cures": ["poison"], "price": 100, "description": "…"}
	assert_true(_library.add_from_dict({"antidote": antidote}, "test"))
	var item := _library.get_item(&"antidote")
	assert_eq([item.cures, item.heal_amount], [[&"poison"] as Array[StringName], 0])
	assert_true(item.targets_pokemon())
	assert_true(item.cures_status(&"poison"))
	assert_false(item.cures_status(StatusRules.NONE))
	var both := antidote.duplicate()
	both["heal_amount"] = 20
	assert_true(_library.add_from_dict({"both": both}, "test"), "PV et statut ensemble")
	var cases := {
		"a": [{"category": "heal"}, "un soin a « heal_amount » ou « cures »"],
		"b": [{"cures": []}, "« cures » doit être une liste non vide"],
		"c": [{"cures": ["toxic"]}, "« cures » doit être une liste non vide"],
		"d": [{"cures": ["poison", "poison"]}, "sans doublon"],
		"e": [{"cures": "poison"}, "« cures » doit être une liste non vide"],
		"f": [{"category": "ball", "catch_bonus": 1}, "« cures » est réservé aux soins"],
	}
	for id: String in cases:
		var entry := antidote.duplicate()
		entry.merge(cases[id][0], true)
		if id == "a":
			entry.erase("cures")
		assert_false(_library.add_from_dict({id: entry}, "test"), id)
		assert_string_contains("\n".join(_library.get_errors()), cases[id][1])
	assert_push_error_count(cases.size())
	assert_eq(_library.get_ids(), [&"antidote", &"both"] as Array[StringName])


func test_real_antidote() -> void:
	assert_true(_library.load_dir())
	var antidote := _library.get_item(&"antidote")
	# Textes n° 11 à 13 du lot du J9 (verrouillé le 2026-10-07), prix de Rouge/Bleu (défaut).
	assert_eq([antidote.name, antidote.plural, antidote.feminine, antidote.description],
		["Antidote", "Antidotes", false, "Soigne un Pokémon empoisonné."])
	assert_eq([antidote.category, antidote.cures, antidote.price, antidote.heal_amount],
		[ItemData.Category.HEAL, [&"poison"] as Array[StringName], 100, 0])
	assert_false(antidote.draft)
	assert_eq(antidote.added_text(1), "Ajouté au Sac", "toast « Antidote ×1 — Ajouté au Sac »")
	assert_eq(antidote.quantity_text(1), "Antidote ×1")
