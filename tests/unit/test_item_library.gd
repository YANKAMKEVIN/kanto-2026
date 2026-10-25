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
	# Jalon 12 : data/items/mt_moon.json (Corde Sortie, Pierre Lune, fossiles, CT01) ; jalon 14 :
	# items_j14.json (CT19, CT28, Passe Bateau, Super Bonbon) ; jalon 15 (T12) : Super Potion et
	# Guérison (data/items/vermilion.json) ; jalon 16 : items_j16.json (CS01, CT24 ; la Super
	# Potion du J16 est celle du J15) ; jalon 17 (T7) : CS05 (data/items/j17.json).
	# Jalon 20 (T7) : items_j20.json (Super Ball, pierres, boissons, CT13, CT21, Clé Ascenseur,
	# Scope Sylphe) ; jalon 20 (T11) : Rappel, Poupée Poké, objets X, Muscle +.
	# Jalon 28 (T3) : items_j28.json (CT27 Abîme).
	# Passe systèmes 2 (S2B) : items_systemes2.json (Poké Flûte, Bicyclette) ; S2C : CS03 (hm03) ; S2D : CS04 (hm04) ; S2C-bis : cannes.
	# Jalon 24 (T4) : items_j24.json (CT35 ; Hyper Ball, Hyper Potion et Total Soin sont ceux du J22).
	# Jalon 21 (T4) : CT39 (data/items/items_j21.json ; la Poké Flûte est celle de la passe systèmes 2).
	# Jalon 22 (T4) : Bon de Commande, Hyper Potion, Hyper Ball (ultra_ball) ; Total Soin
	# (full_heal, décision de Kevin du 2026-10-22, copie du J24) ; T10 : CT09 Bélier
	# à la place de la CT20 (Frénésie sans effet dans le moteur) (items_j22.json).
	# Jalon 25 (T8) : items_j25.json (Clé Secrète, Vieil Ambre, CT38, Potion Max, Rappel Max, CT14, CT22).
	assert_eq(_library.get_ids(), [&"antidote", &"awakening", &"bicycle", &"bike_voucher", &"burn_heal",
		&"card_key", &"dire_hit",
		&"dome_fossil", &"escape_rope", &"fire_stone", &"fresh_water", &"full_heal", &"full_restore",
		&"good_rod", &"great_ball", &"helix_fossil", &"hm01", &"hm02", &"hm03", &"hm04", &"hm05", &"hyper_potion", &"ice_heal", &"leaf_stone", &"lemonade",
		&"lift_key", &"max_potion", &"max_revive", &"moon_stone", &"nugget", &"oak_parcel",
		&"old_amber", &"old_rod", &"paralyze_heal", &"poke_ball",
		&"poke_doll", &"poke_flute", &"potion", &"rare_candy", &"revive", &"secret_key", &"silph_scope", &"soda_pop",
		&"ss_ticket", &"super_potion", &"super_rod", &"thunder_stone", &"tm01", &"tm09", &"tm11", &"tm13", &"tm14", &"tm19",
		&"tm21", &"tm22", &"tm24", &"tm27", &"tm28", &"tm34", &"tm35", &"tm38", &"tm39", &"ultra_ball", &"water_stone", &"x_accuracy",
		&"x_attack", &"x_defend", &"x_special", &"x_speed"] as Array[StringName])
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
		[&"poke_ball", &"potion", &"antidote", &"paralyze_heal", &"awakening", &"burn_heal", &"ice_heal",
		&"nugget", &"tm11", &"tm34", &"oak_parcel", &"tm19", &"tm28", &"ss_ticket",
		&"rare_candy", &"hm01", &"tm24", &"great_ball", &"revive", &"poke_doll", &"x_attack",
		&"x_defend", &"x_speed", &"x_special", &"x_accuracy", &"dire_hit", &"fire_stone",
		&"water_stone",
		&"thunder_stone", &"leaf_stone", &"fresh_water", &"soda_pop", &"lemonade", &"tm13",
		&"tm21", &"lift_key", &"silph_scope", &"tm39", &"bike_voucher", &"hyper_potion",
		&"ultra_ball", &"full_heal", &"tm09", &"tm35",
		&"secret_key", &"old_amber", &"tm38", &"max_potion", &"max_revive", &"tm14", &"tm22",
		&"tm27",
		&"poke_flute", &"bicycle", &"card_key", &"hm02", &"hm03", &"hm04",
		&"old_rod", &"good_rod", &"super_rod", &"hm05", &"escape_rope", &"moon_stone", &"dome_fossil", &"helix_fossil", &"tm01", &"super_potion",
		&"full_restore"] as Array[StringName],
		"ordre alphabétique des fichiers (items, items_j14, items_j16, items_j20, "
		+ "items_j21, items_j22, items_j24, items_j25, items_j28, items_systemes2, j17, mt_moon, vermilion)")
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
	assert_eq(ItemData.CATEGORY_NAMES, ["ball", "heal", "battle", "field", "key", "tm"]
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
		# Jalon 13 §2.13 : AVENTURE sans usage (la Pépite) n'a aucun contexte.
		ItemData.Category.FIELD: [],
		ItemData.Category.KEY: [],
	}
	for category: ItemData.Category in expected:
		item.category = category
		var contexts: Array = []
		contexts.assign(item.contexts())
		assert_eq(contexts, expected[category], ItemData.CATEGORY_NAMES[category])
	item.category = ItemData.Category.FIELD
	item.field_use = &"escape_rope"
	assert_eq(item.contexts(), [&"field"] as Array[StringName], "AVENTURE avec un usage")
	item.field_use = &""
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
	assert_string_contains(errors, "un objet clé ou une CS n'a pas de prix")


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
		"a": [{"category": "heal"}, "un soin a « heal_amount », « cures » ou « revive »"],
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


func test_real_j11_remedies() -> void:
	assert_true(_library.load_dir())
	# Dossier 14 §3.4 et textes n° 34 à 37 du §13 (validés le 2026-10-10) ; prix de Rouge/Bleu.
	var rows: Array = []
	for id: StringName in [&"paralyze_heal", &"awakening", &"burn_heal", &"ice_heal"]:
		var item := _library.get_item(id)
		rows.append([item.name, item.plural, item.cures, item.price, item.description,
			item.category, item.heal_amount, item.draft])
	assert_eq(rows, [
		["Anti-Para", "Anti-Para", [&"paralysis"] as Array[StringName], 200,
			"Soigne un Pokémon paralysé.", ItemData.Category.HEAL, 0, false],
		["Réveil", "Réveils", [&"sleep"] as Array[StringName], 250,
			"Réveille un Pokémon endormi.", ItemData.Category.HEAL, 0, false],
		["Anti-Brûle", "Anti-Brûle", [&"burn"] as Array[StringName], 250,
			"Soigne un Pokémon brûlé.", ItemData.Category.HEAL, 0, false],
		["Antigel", "Antigels", [&"freeze"] as Array[StringName], 250,
			"Dégèle un Pokémon gelé.", ItemData.Category.HEAL, 0, false],
	])


## Jalon 14 (T5, jalon-14.md §2.6 et §2.10) : Passe Bateau (objet clé) et Super Bonbon (AVENTURE,
## jamais vendu ; UTILISER hors combat depuis le T18b) ; textes n° 58 et 59 du dossier 17.
func test_real_j14_ticket_and_rare_candy() -> void:
	assert_true(_library.load_dir(), "\n".join(_library.get_errors()))
	var ticket := _library.get_item(&"ss_ticket")
	assert_eq([ticket.name, ticket.category, ticket.price],
		["Passe Bateau", ItemData.Category.KEY, 0])
	assert_eq(ticket.description,
		"Une invitation pour le S.S. Anne, le paquebot qui fait escale à Carmin-sur-Mer.")
	assert_true(ticket.is_key())
	assert_false(ticket.is_sellable())
	assert_eq(ticket.contexts(), [] as Array[StringName], "aucun bouton UTILISER au J14")
	assert_eq(ticket.quantity_text(1), "PASSE BATEAU")
	assert_eq(ticket.added_text(1), "ajouté aux objets clés")
	var candy := _library.get_item(&"rare_candy")
	assert_eq([candy.name, candy.plural, candy.feminine, candy.category, candy.price],
		["Super Bonbon", "Super Bonbons", false, ItemData.Category.FIELD, 0])
	assert_eq(candy.description, "Un bonbon plein d'énergie. Fait monter un Pokémon d'un niveau.")
	assert_false(candy.is_sellable(), "jamais vendu au J14")
	# T18b : « field_use » rare_candy, UTILISER en exploration seulement (jamais en combat).
	assert_eq(candy.field_use, ItemData.FIELD_USE_RARE_CANDY)
	assert_eq(candy.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName],
		"UTILISER hors combat, jamais en combat")
	assert_eq(candy.added_text(1), "Ajouté au Sac")
	for item: ItemData in [ticket, candy]:
		assert_false(item.draft, "%s : texte validé (dossier 17 §15)" % item.name)


## Jalon 21 (T4, jalon-21.md §2.1) : Poké Flûte (objet clé de la passe systèmes 2, avec son
## « key_use ») et CT39 Météores (Route 12). Textes du dossier 24 §15.6 et §15.8 bis, validés le
## 2026-10-16.
func test_real_j21_poke_flute_and_tm39() -> void:
	assert_true(_library.load_dir(), "\n".join(_library.get_errors()))
	var flute := _library.get_item(&"poke_flute")
	assert_eq([flute.name, flute.plural, flute.feminine, flute.category, flute.price],
		["Poké Flûte", "Poké Flûtes", true, ItemData.Category.KEY, 0])
	assert_eq(flute.description,
		"Une flûte à la mélodie douce. Elle réveille les Pokémon endormis.")
	assert_true(flute.is_key())
	assert_false(flute.is_sellable(), "objet clé : sans prix")
	assert_eq(flute.key_use, ItemData.KEY_USE_POKE_FLUTE, "passe systèmes 2 (S2B)")
	assert_eq(flute.quantity_text(1), "POKÉ FLÛTE")
	assert_eq(flute.added_text(1), "ajoutée aux objets clés")
	var tm := _library.get_item(&"tm39")
	assert_eq([tm.name, tm.category, tm.tm_number, tm.teaches, tm.price],
		["CT39 — Météores", ItemData.Category.TM, 39, &"swift", 0])
	assert_eq(tm.description, "Météores ne rate jamais sa cible.")
	assert_true(tm.is_permanent())
	assert_false(tm.is_sellable(), "CT jamais vendue")
	assert_eq(_library.get_tm(39), &"tm39")
	for item: ItemData in [flute, tm]:
		assert_false(item.draft, "%s : texte du §15 validé par Kevin (2026-10-16)" % item.name)
	assert_eq(flute.source, "res://data/items/items_systemes2.json", "un seul exemplaire")
	assert_eq(tm.source, "res://data/items/items_j21.json")
