extends GutTest
## BagQuery (jalon-06.md §3.4, dossier 08 §3) : ordre des onglets, onglets vides absents,
## favoris en tête, filtres de contexte, tris (Q-12), onglet d'ouverture, choix du Pokémon et
## ses raisons (Q-11), texte du résultat. Objets fabriqués pour couvrir les cinq catégories.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData
var _items: ItemLibrary
var _bag: Bag


func _item(name: String, category: String, extra: Dictionary = {}) -> Dictionary:
	var entry := {"name": name, "plural": name + "s", "feminine": true, "category": category,
		"description": name + "."}
	entry.merge(extra)
	return entry


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	# Ordre des données : celui-ci (pertinence hors combat).
	assert_true(_items.add_from_dict({
		"poke_ball": _item("Poké Ball", "ball", {"catch_bonus": 1}),
		"great_ball": _item("Super Ball", "ball", {"catch_bonus": 1.5}),
		"potion": _item("Potion", "heal", {"heal_amount": 20}),
		"super_potion": _item("Super Potion", "heal", {"heal_amount": 50}),
		"x_attack": _item("Attaque +", "battle"),
		"repel": _item("Repousse", "field"),
		"parcel": _item("Colis", "key"),
	}, "test"), str(_items.get_errors()))


func before_each() -> void:
	_bag = Bag.new()


func _ids(views: Array[BagEntryView]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for view: BagEntryView in views:
		ids.append(view.item_id)
	return ids


func _by_id(views: Array[BagEntryView]) -> Dictionary[StringName, BagEntryView]:
	var result: Dictionary[StringName, BagEntryView] = {}
	for view: BagEntryView in views:
		result[view.item_id] = view
	return result


func _mon(hp: int) -> Pokemon:
	var mon := PokemonFactory.create(_data, &"charmander", 5, ScriptedRng.new(IV_0))
	mon.hp = hp
	return mon


func _fill_everything() -> void:
	for id: StringName in [&"parcel", &"repel", &"x_attack", &"super_potion", &"potion",
			&"great_ball", &"poke_ball"]:
		_bag.add(id, 1)


# --- Onglets ----------------------------------------------------------------------------

func test_contexts_share_the_menu_values() -> void:
	assert_eq(BagQuery.CONTEXT_FIELD, MenuRoute.BAG_CONTEXT_FIELD)
	assert_eq(BagQuery.CONTEXT_TEAM, MenuRoute.BAG_CONTEXT_TEAM)


func test_tabs_follow_the_fixed_order_and_empty_ones_are_absent() -> void:
	_fill_everything()
	var views := BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD)
	assert_eq(BagQuery.categories(views),
		[&"heal", &"ball", &"battle", &"field", &"key"] as Array[StringName],
		"SOINS, CAPTURE, COMBAT, AVENTURE, OBJETS CLÉS ; pas de FAVORIS sans favori")
	_bag = Bag.new()
	_bag.add(&"potion")
	_bag.add(&"poke_ball", 5)
	assert_eq(BagQuery.categories(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD)),
		[&"heal", &"ball"] as Array[StringName], "rien d'annoncé d'avance")
	assert_eq(BagQuery.categories([] as Array[BagEntryView]), [] as Array[StringName])


func test_favorites_come_first_only_when_present_in_the_bag() -> void:
	_bag.add(&"potion")
	_bag.add(&"poke_ball", 5)
	_bag.set_favorite(&"poke_ball", true)
	_bag.set_favorite(&"potion", true)
	_bag.set_favorite(&"repel", true)
	var view := BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD)
	assert_eq(view.categories, [&"favorites", &"heal", &"ball"] as Array[StringName])
	assert_eq(_ids(view.favorites), [&"poke_ball", &"potion"] as Array[StringName],
		"ordre de marquage ; la Repousse, absente du Sac, n'apparaît pas")
	assert_eq(_ids(view.entries_in(BagQuery.FAVORITES)), _ids(view.favorites))
	assert_eq(_ids(view.entries_in(&"heal")), [&"potion"] as Array[StringName],
		"un favori reste aussi dans sa catégorie")
	assert_true(view.entry(&"potion").favorite)
	assert_eq(view.category_label(BagQuery.FAVORITES), "FAVORIS")
	_bag.remove(&"potion")
	_bag.remove(&"poke_ball", 5)
	_bag.add(&"super_potion")
	assert_false(BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD).categories
		.has(BagQuery.FAVORITES), "aucun favori présent : pas d'onglet")


func test_category_labels() -> void:
	var labels: Array[String] = []
	for id: StringName in [&"heal", &"ball", &"battle", &"field", &"key"]:
		labels.append(BagEntryView.category_label(id))
	assert_eq(labels, ["SOINS", "CAPTURE", "COMBAT", "AVENTURE", "OBJETS CLÉS"]
		as Array[String])


# --- Contextes --------------------------------------------------------------------------

func test_in_the_field_everything_is_listed_with_a_note_when_unusable() -> void:
	_fill_everything()
	var by_id := _by_id(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD))
	assert_eq(by_id.size(), 7)
	assert_true(by_id[&"potion"].usable)
	assert_true(by_id[&"potion"].targets_pokemon)
	assert_eq(by_id[&"potion"].note, "")
	assert_true(by_id[&"repel"].usable, "AVENTURE : en exploration")
	for id: StringName in [&"x_attack", &"poke_ball", &"great_ball"]:
		assert_false(by_id[id].usable, String(id))
		assert_eq(by_id[id].note, "Utilisable en combat", String(id))
		assert_true(by_id[id].is_listed())
		assert_false(by_id[id].is_displayable(), "jamais au Sac du combat sous ce contexte")
	assert_false(by_id[&"parcel"].usable, "un objet clé ne s'utilise pas")
	assert_eq(by_id[&"parcel"].note, "", "et ne porte aucune mention")
	assert_eq(by_id[&"poke_ball"].action_label, "LANCER")
	assert_eq(by_id[&"potion"].action_label, "UTILISER")
	assert_eq(by_id[&"potion"].display_name, "Potion", "nom au singulier")


func test_wild_battle_offers_balls_and_heals() -> void:
	_fill_everything()
	var views := BagQuery.entries(_bag, _items, BagQuery.CONTEXT_WILD_BATTLE)
	var usable: Array[StringName] = []
	for view: BagEntryView in views:
		if view.is_displayable():
			usable.append(view.item_id)
	assert_eq(usable, [&"poke_ball", &"great_ball", &"potion", &"super_potion", &"x_attack"]
		as Array[StringName], "pertinence : Balls, puis soins, puis le reste")
	assert_eq(_ids(views).slice(0, 4), [&"poke_ball", &"great_ball", &"potion",
		&"super_potion"] as Array[StringName])


func test_trainer_battle_has_no_ball() -> void:
	_fill_everything()
	var by_id := _by_id(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_TRAINER_BATTLE))
	assert_false(by_id[&"poke_ball"].usable)
	assert_true(by_id[&"potion"].usable)
	assert_true(by_id[&"x_attack"].usable)
	assert_false(by_id[&"repel"].usable)


func test_from_the_team_only_heals_with_the_reason_for_this_pokemon() -> void:
	_fill_everything()
	var party := Party.new()
	party.add(_mon(18))
	party.add(_mon(4))
	var full := BagQuery.view(_bag, _items, BagQuery.CONTEXT_TEAM, BagQuery.Sort.RELEVANCE,
		&"", party, 0, _data)
	assert_eq(_ids(full.entries), [&"potion", &"super_potion"] as Array[StringName],
		"SOINS filtré sur les objets compatibles")
	assert_eq(full.categories, [&"heal"] as Array[StringName])
	assert_eq(full.start_category, &"heal")
	assert_eq([full.target_index, full.target_name], [0, "Salamèche"])
	assert_false(full.entries[0].usable)
	assert_eq(full.entries[0].note, "PV déjà au maximum")
	var hurt := BagQuery.view(_bag, _items, BagQuery.CONTEXT_TEAM, BagQuery.Sort.RELEVANCE,
		&"", party, 1, _data)
	assert_true(hurt.entries[0].usable)
	assert_eq(hurt.entries[0].note, "")
	party.get_at(1).hp = 0
	var fainted := BagQuery.view(_bag, _items, BagQuery.CONTEXT_TEAM, BagQuery.Sort.RELEVANCE,
		&"", party, 1, _data)
	assert_eq(fainted.entries[0].note, "Ce Pokémon est K.O.")


func test_empty_texts() -> void:
	var view := BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD)
	assert_true(view.is_empty())
	assert_eq(view.empty_text, "Ton Sac est vide.")
	assert_eq(view.start_category, &"")
	_bag.add(&"poke_ball")
	assert_eq(BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD).empty_text, "",
		"texte vide = élément absent")
	assert_eq(BagQuery.view(_bag, _items, BagQuery.CONTEXT_TEAM).empty_text,
		"Aucun soin dans ton Sac.")


func test_unknown_items_and_missing_bag() -> void:
	_bag.add(&"mystery")
	assert_eq(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD).size(), 0)
	assert_push_error("objet inconnu")
	assert_eq(BagQuery.entries(null, _items, BagQuery.CONTEXT_FIELD).size(), 0)
	assert_eq(BagQuery.entries(_bag, null, BagQuery.CONTEXT_FIELD).size(), 0)


# --- Tris -------------------------------------------------------------------------------

func test_sorts() -> void:
	_bag.add(&"super_potion", 1)
	_bag.add(&"poke_ball", 10)
	_bag.add(&"potion", 3)
	var field := BagQuery.CONTEXT_FIELD
	assert_eq(_ids(BagQuery.entries(_bag, _items, field, BagQuery.Sort.RELEVANCE)),
		[&"poke_ball", &"potion", &"super_potion"] as Array[StringName], "ordre des données")
	assert_eq(_ids(BagQuery.entries(_bag, _items, field, BagQuery.Sort.NAME)),
		[&"poke_ball", &"potion", &"super_potion"] as Array[StringName],
		"Poké Ball, Potion, Super Potion")
	assert_eq(_ids(BagQuery.entries(_bag, _items, field, BagQuery.Sort.QUANTITY)),
		[&"poke_ball", &"potion", &"super_potion"] as Array[StringName], "10, 3, 1")
	assert_eq(_ids(BagQuery.entries(_bag, _items, field, BagQuery.Sort.RECENT)),
		[&"potion", &"poke_ball", &"super_potion"] as Array[StringName],
		"Q-12 : obtenus le plus récemment d'abord")
	_bag.add(&"super_potion")
	assert_eq(_ids(BagQuery.entries(_bag, _items, field, BagQuery.Sort.RECENT))[0],
		&"super_potion", "une nouvelle obtention remonte l'objet")


func test_name_sort_ignores_case_and_ties_keep_the_data_order() -> void:
	_bag.add(&"great_ball", 2)
	_bag.add(&"poke_ball", 2)
	assert_eq(_ids(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD,
		BagQuery.Sort.QUANTITY)), [&"poke_ball", &"great_ball"] as Array[StringName],
		"égalité de quantité : ordre des données")
	assert_eq(_ids(BagQuery.entries(_bag, _items, BagQuery.CONTEXT_FIELD,
		BagQuery.Sort.NAME)), [&"poke_ball", &"great_ball"] as Array[StringName],
		"Poké Ball avant Super Ball")


func test_favorites_follow_the_chosen_sort_except_relevance() -> void:
	_bag.add(&"potion", 1)
	_bag.add(&"poke_ball", 9)
	_bag.set_favorite(&"potion", true)
	_bag.set_favorite(&"poke_ball", true)
	var by_quantity := BagQuery.view(_bag, _items, BagQuery.CONTEXT_FIELD,
		BagQuery.Sort.QUANTITY)
	assert_eq(_ids(by_quantity.favorites), [&"poke_ball", &"potion"] as Array[StringName])
	assert_eq(by_quantity.sort, BagQuery.Sort.QUANTITY)
	assert_eq(Array(by_quantity.sort_labels), ["Pertinence", "Nom", "Quantité", "Récents"])


# --- Onglet d'ouverture -----------------------------------------------------------------

func test_start_category() -> void:
	var all: Array[StringName] = [&"favorites", &"heal", &"ball"]
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_WILD_BATTLE, &"heal", all), &"ball",
		"combat sauvage : CAPTURE")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_TEAM, &"ball", all), &"heal")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_TRAINER_BATTLE, &"", all), &"heal")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_FIELD, &"ball", all), &"ball",
		"exploration : le dernier onglet ouvert")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_FIELD, &"", all), &"favorites",
		"rien d'ouvert : le premier")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_FIELD, &"key", all), &"favorites",
		"le dernier n'existe plus : le premier")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_WILD_BATTLE, &"",
		[&"heal"] as Array[StringName]), &"heal", "pas de Ball : le premier")
	assert_eq(BagQuery.start_category(BagQuery.CONTEXT_FIELD, &"",
		[] as Array[StringName]), &"")


# --- Choix du Pokémon et résultat -------------------------------------------------------

func test_party_picker_shows_everyone_with_a_reason() -> void:
	_bag.add(&"potion", 2)
	var party := Party.new()
	party.add(_mon(5))
	party.add(_mon(18))
	party.add(_mon(0))
	var picker := BagQuery.targets(party, _bag, _items.get_item(&"potion"),
		BagQuery.CONTEXT_FIELD, _data, 0)
	assert_eq([picker.item_id, picker.item_name, picker.quantity, picker.selected],
		[&"potion", "Potion", 2, 0])
	assert_eq(picker.size(), 3, "toute l'équipe, jamais filtrée")
	var rows: Array = []
	for target: PartyTargetView in picker.targets:
		rows.append([target.member.party_index, target.member.hp, target.usable, target.reason])
	assert_eq(rows, [[0, 5, true, ""], [1, 18, false, "PV déjà au maximum"],
		[2, 0, false, "Ce Pokémon est K.O."]])
	assert_eq(picker.target_at(2).member.status_text, "K.O.")
	assert_true(picker.has_usable())
	assert_null(picker.target_at(3))
	_bag.remove(&"potion", 2)
	var empty := BagQuery.targets(party, _bag, _items.get_item(&"potion"),
		BagQuery.CONTEXT_WILD_BATTLE, _data)
	assert_false(empty.has_usable())
	assert_eq(empty.target_at(0).reason, "Il n'en reste plus")


func test_result_text_and_repeat() -> void:
	_bag.add(&"potion", 2)
	var mon := _mon(5)
	var potion := _items.get_item(&"potion")
	var result := ItemUse.apply(_bag, potion, mon, BagQuery.CONTEXT_FIELD)
	assert_eq(BagQuery.result_text(result, "Salamèche"), "+13 PV — Salamèche 18/18")
	assert_true(BagQuery.can_repeat(result), "il reste une Potion")
	var again := ItemUse.apply(_bag, potion, mon, BagQuery.CONTEXT_FIELD)
	assert_eq(BagQuery.result_text(again, "Salamèche"), "PV déjà au maximum",
		"UTILISER À NOUVEAU sur PV pleins : la raison, rien consommé")
	assert_eq(_bag.count_of(&"potion"), 1)
	mon.hp = 1
	var last := ItemUse.apply(_bag, potion, mon, BagQuery.CONTEXT_FIELD)
	assert_eq(BagQuery.result_text(last, "Salamèche"), "+17 PV — Salamèche 18/18")
	assert_false(BagQuery.can_repeat(last), "plus de Potion")
	assert_eq(BagQuery.result_text(null, "x"), "")
	assert_eq(BagQuery.reason_text(ItemUse.Check.OK), "")
