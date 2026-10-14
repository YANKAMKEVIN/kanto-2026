extends GutTest
## Sac « CT » (jalon 11, T12 ; dossier 14 §6.1–6.2) : onglet absent sans CT, carte et détail
## (type, puissance, précision, PP, description), APPRENDRE, états COMPATIBLE / DÉJÀ CONNUE /
## INCOMPATIBLE toujours visibles, refus en combat ; le directeur demande l'apprentissage sans
## jamais consommer la CT.

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _data: PokemonData
var _items: ItemLibrary
var _state: Node


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.new_game(3)
	for species: StringName in [&"charmander", &"caterpie", &"pidgey"]:
		_state.party.add(PokemonFactory.create(_data, species, 8, GameRng.new(5)))


func _tm_entry(context: StringName) -> BagEntryView:
	for view: BagEntryView in BagQuery.entries(_state.bag, _items, context,
			BagQuery.Sort.RELEVANCE, null, _data):
		if view.item_id == &"tm34":
			return view
	return null


func test_the_tm_tab_appears_only_with_a_tm() -> void:
	_state.bag.add(&"potion", 1)
	var view := BagQuery.view(_state.bag, _items, BagQuery.CONTEXT_FIELD)
	assert_false(view.categories.has(&"tm"), "aucune CT : pas d'onglet")
	_state.bag.add(&"tm34", 1)
	view = BagQuery.view(_state.bag, _items, BagQuery.CONTEXT_FIELD, BagQuery.Sort.RELEVANCE,
		&"", null, -1, _data)
	assert_eq(view.categories, [&"heal", &"tm"] as Array[StringName])
	assert_eq(BagEntryView.category_label(&"tm"), "CT", "texte n° 38")


func test_tm_card_and_detail() -> void:
	_state.bag.add(&"tm34", 1)
	var entry := _tm_entry(BagQuery.CONTEXT_FIELD)
	assert_eq(entry.display_name, "CT34 — Patience")
	assert_eq(entry.quantity_text(), "", "permanente : pas de « ×1 »")
	assert_eq(entry.action_label, "APPRENDRE", "texte n° 42")
	assert_true(entry.usable)
	assert_true(entry.targets_pokemon)
	assert_eq(entry.description, "Normal · Puissance — · Précision — · PP 10\n"
		+ "Encaisse deux tours, puis riposte avec le double des dégâts reçus.")
	var in_battle := _tm_entry(BagQuery.CONTEXT_TRAINER_BATTLE)
	assert_false(in_battle.usable)
	assert_false(in_battle.is_displayable(), "jamais dans le Sac du combat")
	assert_eq(in_battle.note, "Les CT s'utilisent hors combat.", "texte n° 44")
	assert_true(BagQuery.entries(_state.bag, _items, BagQuery.CONTEXT_TEAM).is_empty(),
		"pas dans le Sac ouvert depuis l'Équipe")


func test_targets_show_the_three_states() -> void:
	_state.bag.add(&"tm34", 1)
	var charmander: Pokemon = _state.party.get_at(0)
	var pidgey: Pokemon = _state.party.get_at(2)
	pidgey.learn_move(&"bide", _data)
	var picker := BagQuery.targets(_state.party, _state.bag, _items.get_item(&"tm34"),
		BagQuery.CONTEXT_FIELD, _data)
	assert_true(picker.permanent)
	var rows: Array = []
	for target: PartyTargetView in picker.targets:
		rows.append([target.usable, target.reason, target.show_reason])
	assert_eq(rows, [[true, "COMPATIBLE", true], [false, "INCOMPATIBLE", true],
		[false, "DÉJÀ CONNUE", true]], "texte n° 41, toujours visibles")
	assert_false(charmander.knows_move(&"bide"))


func test_the_director_asks_to_learn_and_never_spends_the_tm() -> void:
	_state.bag.add(&"tm34", 1)
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(_state, _data, ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(_state.flags, _state.party), func() -> bool: return true, _items)
	var requests: Array = []
	director.tm_learn_requested.connect(func(i: int, id: StringName) -> void:
		requests.append([i, id]))
	var pickers: Array[PartyPickerView] = []
	director.bag_targets_shown.connect(pickers.append)
	assert_false(director.use_item_on(&"tm34", 1), "Chenipan : incompatible, rien ne part")
	assert_true(director.use_item_on(&"tm34", 0))
	assert_eq(requests, [[0, &"tm34"]])
	assert_eq(_state.bag.count_of(&"tm34"), 1, "la CT reste au Sac")
	_state.party.get_at(0).learn_move(&"bide", _data)
	director.finish_tm_learn(0, &"tm34", true)
	assert_eq(pickers.back().targets[0].reason, "DÉJÀ CONNUE", "choix rafraîchi")
	assert_eq(_state.bag.count_of(&"tm34"), 1)
