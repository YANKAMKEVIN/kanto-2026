extends GutTest
## ShopLibrary et ShopData (jalon-07.md §3.4, dossier 09 §9) : vraies données (la Boutique de
## Jadielle), validation stricte, stock conditionnel, références aux objets.

var _library: ShopLibrary
var _items: ItemLibrary


func before_all() -> void:
	_items = ItemLibrary.new()
	_items.load_dir()


func before_each() -> void:
	_library = ShopLibrary.new()


func test_real_data_loads_without_error() -> void:
	assert_true(_library.load_dir(), "\n".join(_library.get_errors()))
	assert_true(_library.check_references(_items), "\n".join(_library.get_errors()))
	assert_eq(_library.get_errors().size(), 0)
	assert_eq(_library.get_ids(),
		[&"celadon_dept_2f", &"celadon_dept_2f_tm", &"celadon_dept_4f", &"celadon_dept_4f_stones",
		&"celadon_dept_5f", &"celadon_dept_roof_lemonade", &"celadon_dept_roof_soda",
		&"celadon_dept_roof_water", &"cerulean_mart", &"fuchsia_mart", &"lavender_mart",
		&"pewter_mart",
		&"vermilion_mart", &"viridian_mart"]
		as Array[StringName], "jalon 10 : Argenta (test_pewter_data) ; jalon 13 : Azuria ;"
		+ " jalon 15 : Carmin (test_vermilion_data) ; jalon 20 : grand magasin"
		+ " (test_celadon_data) ; jalon 22 : Parmanie")
	var mart := _library.get_shop(&"viridian_mart")
	assert_eq(mart.id, &"viridian_mart")
	assert_eq(mart.source, "res://data/shops/viridian_mart.json")
	# Dossier 09 §9 : stock initial Poké Ball, Potion (ordre des données, §13) ; jalon 9 :
	# l'Antidote après la Potion, seulement une fois le poison annoncé (« poison_unlocked »).
	assert_eq(mart.item_ids(), [&"poke_ball", &"potion", &"antidote", &"paralyze_heal", &"awakening", &"burn_heal"] \
		as Array[StringName])
	assert_eq(ShopRules.stock(mart, StoryFlags.new()), [&"poke_ball", &"potion", &"paralyze_heal", &"awakening", &"burn_heal"] \
		as Array[StringName], "sans drapeau : le stock du J7 et les remèdes du J11")
	var flags := StoryFlags.new()
	flags.set_flag(&"poison_unlocked")
	assert_eq(ShopRules.stock(mart, flags), mart.item_ids(), "poison annoncé : l'Antidote")


## Dossier 09 §9 : jamais un objet pour une mécanique absente, jamais un objet clé.
func test_real_shops_sell_only_priced_non_key_items() -> void:
	_library.load_dir()
	for id: StringName in _library.get_ids():
		for item_id: StringName in _library.get_shop(id).item_ids():
			var item := _items.get_item(item_id)
			assert_not_null(item, String(item_id))
			assert_gt(item.price, 0, String(item_id))
			assert_false(item.is_key(), String(item_id))


func test_conditional_stock_follows_the_flags() -> void:
	assert_true(_library.add_from_dict({"mart": {"stock": [
		{"item": "potion"},
		{"item": "poke_ball", "if": ["pokedex_activated"]},
		{"item": "antidote", "if": ["a", "b"], "unless": ["c"]},
	]}}, "t"))
	var mart := _library.get_shop(&"mart")
	var flags := StoryFlags.new()
	assert_eq(ShopRules.stock(mart, flags), [&"potion"] as Array[StringName])
	flags.set_flag(&"pokedex_activated")
	assert_eq(ShopRules.stock(mart, flags), [&"potion", &"poke_ball"] as Array[StringName])
	flags.set_flag(&"a")
	assert_eq(ShopRules.stock(mart, flags).size(), 2, "« if » : tous les drapeaux")
	flags.set_flag(&"b")
	assert_eq(ShopRules.stock(mart, flags), [&"potion", &"poke_ball", &"antidote"] \
		as Array[StringName], "ordre des données")
	flags.set_flag(&"c")
	assert_eq(ShopRules.stock(mart, flags).size(), 2, "« unless » écarte")
	assert_eq(ShopRules.stock(mart, null), [&"potion"] as Array[StringName],
		"sans drapeaux : les objets sans condition")
	assert_eq(ShopRules.stock(null, flags), [] as Array[StringName])
	assert_eq(_library.get_condition_flags(), [&"pokedex_activated", &"a", &"b", &"c"] \
		as Array[StringName])


func test_invalid_shops_are_rejected() -> void:
	assert_false(_library.add_from_dict({
		"ok": {"stock": [{"item": "potion"}]},
		"typo": {"stock": [{"item": "potion"}], "prices": {}},
		"empty": {"stock": []},
		"no_stock": {},
		"not_list": {"stock": "potion"},
		"bad_entry": {"stock": ["potion"]},
		"no_item": {"stock": [{"if": ["a"]}]},
		"bad_key": {"stock": [{"item": "potion", "iff": ["a"]}]},
		"bad_if": {"stock": [{"item": "potion", "if": "a"}]},
		"bad_flag": {"stock": [{"item": "potion", "unless": [""]}]},
		"double": {"stock": [{"item": "potion"}, {"item": "potion"}]},
		"not_object": "potion",
	}, "t"))
	assert_eq(_library.get_ids(), [&"ok"] as Array[StringName], "seule la boutique valide reste")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["clé inconnue « prices »", "« stock » est une liste non vide",
			"« item » est un identifiant", "clé inconnue « iff »", "« if » est une liste",
			"« unless » est une liste", "objet « potion » en double", "un objet est attendu"]:
		assert_string_contains(errors, expected)
	assert_push_error_count(11)


func test_duplicate_id_across_files() -> void:
	assert_true(_library.add_from_dict({"mart": {"stock": [{"item": "potion"}]}}, "a.json"))
	assert_false(_library.add_from_dict({"mart": {"stock": [{"item": "potion"}]}}, "b.json"))
	assert_push_error("déjà défini dans a.json")
	assert_eq(_library.size(), 1)


func test_references_unknown_unpriced_or_key_items_are_removed() -> void:
	var items := ItemLibrary.new()
	assert_true(items.add_from_dict({
		"potion": {"name": "Potion", "plural": "Potions", "feminine": true, "category": "heal",
			"heal_amount": 20, "price": 300, "description": "x"},
		"free": {"name": "Rien", "plural": "Riens", "feminine": false, "category": "field",
			"description": "x"},
		"parcel": {"name": "Colis", "plural": "Colis", "feminine": false, "category": "key",
			"description": "x"},
	}, "t"))
	assert_true(_library.add_from_dict({"mart": {"stock": [
		{"item": "potion"}, {"item": "ghost"}, {"item": "free"}, {"item": "parcel"},
	]}}, "t"))
	assert_false(_library.check_references(items))
	assert_eq(_library.get_shop(&"mart").item_ids(), [&"potion"] as Array[StringName])
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« ghost » : objet inconnu")
	assert_string_contains(errors, "« free » : objet sans prix")
	assert_string_contains(errors, "« parcel » : un objet clé ne se vend pas")
	assert_push_error_count(3)


func test_missing_dir_and_file() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/absent_shops/"))
	assert_push_error("dossier introuvable")
	assert_false(_library.load_file("res://tests/fixtures/absent_shop.json"))
	assert_push_error("fichier introuvable")
	var path := "user://test_shop_root.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[1, 2]")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("un objet { identifiant: boutique } est attendu")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\n\"mart\": ,\n}")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("ligne 2")
	DirAccess.remove_absolute(path)
