extends GutTest
## Lot 32P (écarts P1 de l'audit des objets du J32) : vitamines ([Vitamin]), PP Plus, Éthers et
## Élixirs ([PpItem]), Repousses ([RepelRules]), Cherch'Objet ([Itemfinder]), Multi Exp
## ([method ExpCalc.distribute] et le moteur de combat), données des objets et Sac.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func _item(id: StringName) -> ItemData:
	return _items.get_item(id)


# --- Données ----------------------------------------------------------------------------------

func test_library_loads_without_errors() -> void:
	assert_eq(_items.get_errors(), PackedStringArray())


func test_new_items_have_their_use_and_no_more_inert_mention() -> void:
	for id: StringName in [&"hp_up", &"protein", &"iron", &"carbos", &"calcium"]:
		assert_eq(_item(id).field_use, ItemData.FIELD_USE_VITAMIN, String(id))
		assert_eq(_item(id).price, 9800, "prix de Rouge/Bleu : %s" % id)
	assert_eq(_item(&"calcium").vitamin_stats, [&"spa", &"spd"] as Array[StringName],
		"le Spécial unique de Rouge/Bleu [D]")
	assert_eq(_item(&"pp_up").field_use, ItemData.FIELD_USE_PP_UP)
	for id: StringName in [&"ether", &"max_ether", &"elixir", &"max_elixir"]:
		assert_eq(_item(id).field_use, ItemData.FIELD_USE_PP_RESTORE, String(id))
	assert_eq([_item(&"ether").pp_amount, _item(&"ether").pp_all_moves], [10, false])
	assert_eq([_item(&"max_elixir").pp_amount, _item(&"max_elixir").pp_all_moves], [0, true])
	assert_eq([_item(&"repel").repel_steps, _item(&"super_repel").repel_steps,
		_item(&"max_repel").repel_steps], [100, 200, 250])
	assert_eq([_item(&"repel").price, _item(&"super_repel").price, _item(&"max_repel").price],
		[350, 500, 700])
	assert_eq(_item(&"itemfinder").key_use, ItemData.KEY_USE_ITEMFINDER)
	assert_true(_item(&"exp_all").is_key())
	for id: StringName in [&"hp_up", &"carbos", &"pp_up", &"max_elixir", &"max_ether",
			&"protein", &"iron", &"calcium", &"ether", &"elixir", &"repel", &"itemfinder",
			&"exp_all"]:
		assert_false(_item(id).description.contains("Sans effet"), String(id))
		assert_true(_item(id).usable_in(ItemData.CONTEXT_FIELD) or _item(id).is_key(),
			"UTILISER en exploration : %s" % id)


func test_field_params_are_reserved_to_their_use() -> void:
	var library := ItemLibrary.new()
	library.add_from_dict({"bad": {"name": "X", "plural": "X", "feminine": false,
		"category": "field", "field_use": "rare_candy", "repel_steps": 10,
		"description": "X"}}, "test")
	assert_false(library.has_item(&"bad"))
	assert_push_error("« repel_steps » est réservé")


# --- Vitamines --------------------------------------------------------------------------------

func test_vitamin_gives_ten_evs_and_recomputes_stats() -> void:
	var pikachu := _mon(&"pikachu", 50)
	var before := pikachu.max_hp()
	pikachu.hp = before - 5
	var gained := Vitamin.apply(pikachu, _item(&"hp_up"), _data)
	assert_eq(gained, {&"hp": 10} as Dictionary[StringName, int])
	assert_eq(pikachu.evs[&"hp"], 10)
	assert_eq(pikachu.max_hp(), before + 1, "10 EV = +1 PV au niveau 50")
	assert_eq(pikachu.hp, before - 4, "les PV courants suivent les PV max")


func test_vitamin_caps_at_one_hundred_then_no_effect() -> void:
	var pikachu := _mon(&"pikachu", 50)
	for i: int in 10:
		assert_eq(Vitamin.check(pikachu, _item(&"protein")), Vitamin.Check.OK)
		Vitamin.apply(pikachu, _item(&"protein"), _data)
	assert_eq(pikachu.evs[&"atk"], 100)
	assert_eq(Vitamin.check(pikachu, _item(&"protein")), Vitamin.Check.NO_EFFECT)
	assert_true(Vitamin.apply(pikachu, _item(&"protein"), _data).is_empty())


func test_vitamin_respects_the_total_of_510() -> void:
	var pikachu := _mon(&"pikachu", 50)
	pikachu.evs[&"hp"] = 252
	pikachu.evs[&"atk"] = 252
	pikachu.evs[&"def"] = 0
	assert_eq(Vitamin.gains(pikachu, _item(&"iron")), {&"def": 6} as Dictionary[StringName, int])
	pikachu.evs[&"def"] = 6
	assert_eq(Vitamin.check(pikachu, _item(&"calcium")), Vitamin.Check.NO_EFFECT)


func test_calcium_raises_both_special_stats_and_works_on_a_fainted_pokemon() -> void:
	var pikachu := _mon(&"pikachu", 50)
	pikachu.hp = 0
	Vitamin.apply(pikachu, _item(&"calcium"), _data)
	assert_eq([pikachu.evs[&"spa"], pikachu.evs[&"spd"]], [10, 10])
	assert_eq(pikachu.hp, 0, "un Pokémon K.O. le reste")
	assert_eq(Vitamin.result_text(_item(&"calcium"), "Pikachu"), "Le Spécial de Pikachu augmente.")


# --- PP Plus, Éthers, Élixirs ----------------------------------------------------------------

func test_pp_up_adds_a_fifth_three_times_at_most() -> void:
	var pikachu := _mon(&"pikachu", 50)
	var slot := pikachu.moves[0]
	var base := PpItem.base_pp(slot, _data)
	var step := maxi(1, base / 5)
	slot.pp = 3
	assert_eq(PpItem.apply(pikachu, 0, _item(&"pp_up"), _data), step)
	assert_eq([slot.max_pp, slot.pp], [base + step, 3 + step], "les PP courants montent d'autant")
	PpItem.apply(pikachu, 0, _item(&"pp_up"), _data)
	PpItem.apply(pikachu, 0, _item(&"pp_up"), _data)
	assert_eq(slot.max_pp, base + 3 * step)
	assert_eq(PpItem.check_move(pikachu, 0, _item(&"pp_up"), _data), PpItem.Check.NO_EFFECT)
	assert_eq(PpItem.apply(pikachu, 0, _item(&"pp_up"), _data), 0)


func test_ether_restores_one_move_and_elixir_all() -> void:
	var pikachu := _mon(&"pikachu", 50)
	assert_eq(PpItem.check(pikachu, _item(&"ether"), _data), PpItem.Check.NO_EFFECT,
		"PP pleins : sans effet")
	for slot: MoveSlot in pikachu.moves:
		slot.pp = 0
	assert_true(PpItem.needs_move(_item(&"ether")))
	assert_false(PpItem.needs_move(_item(&"elixir")))
	assert_eq(PpItem.apply(pikachu, 0, _item(&"ether"), _data),
		mini(10, pikachu.moves[0].max_pp))
	assert_eq(pikachu.moves[1].pp, 0, "l'Éther ne touche qu'une capacité")
	PpItem.apply(pikachu, -1, _item(&"max_elixir"), _data)
	for slot: MoveSlot in pikachu.moves:
		assert_eq(slot.pp, slot.max_pp)


func test_pp_up_survives_a_save_round_trip() -> void:
	var pikachu := _mon(&"pikachu", 50)
	PpItem.apply(pikachu, 0, _item(&"pp_up"), _data)
	var copy := Pokemon.from_dict(pikachu.to_dict(), _data)
	assert_eq(copy.moves[0].max_pp, pikachu.moves[0].max_pp, "PP max déjà sauvegardés")


# --- Repousse ---------------------------------------------------------------------------------

func test_repel_blocks_weaker_wild_pokemon_only() -> void:
	var party := Party.new()
	var fainted := _mon(&"pikachu", 40)
	fainted.hp = 0
	party.add(fainted)
	party.add(_mon(&"rattata", 20))
	assert_eq(RepelRules.lead_level(party), 20, "le premier Pokémon debout")
	assert_true(RepelRules.blocks(5, 19, party))
	assert_false(RepelRules.blocks(5, 20, party), "même niveau : la rencontre a lieu")
	assert_false(RepelRules.blocks(0, 2, party), "sans Repousse")
	assert_eq([RepelRules.tick(100), RepelRules.tick(1), RepelRules.tick(0)], [99, 0, 0])


func test_repel_counter_is_not_saved() -> void:
	var state: Node = GameStateScript.new()
	add_child_autofree(state)
	state.new_game(3)
	state.repel_steps = 42
	assert_false(JSON.stringify(state.to_dict()).contains("repel"))
	state.new_game(3)
	assert_eq(state.repel_steps, 0)


# --- Cherch'Objet -----------------------------------------------------------------------------

func test_itemfinder_points_to_the_nearest_hidden_item() -> void:
	var player := Vector2i(10, 10)
	assert_eq(Itemfinder.dialogue_for([] as Array[Vector2i], player), &"itemfinder_nothing")
	assert_eq(Itemfinder.dialogue_for([Vector2i(10, 16)] as Array[Vector2i], player),
		&"itemfinder_nothing", "6 cases : hors de portée")
	assert_eq(Itemfinder.dialogue_for([Vector2i(10, 15), Vector2i(8, 9)] as Array[Vector2i],
		player), &"itemfinder_west", "le plus proche, l'axe le plus long")
	assert_eq(Itemfinder.dialogue_for([Vector2i(12, 7)] as Array[Vector2i], player),
		&"itemfinder_north")
	assert_eq(Itemfinder.direction(player, Vector2i(13, 13)), Vector2i.DOWN, "égalité : vertical")
	assert_eq(Itemfinder.dialogue_for([Vector2i(15, 10)] as Array[Vector2i], player),
		&"itemfinder_east")


func test_itemfinder_dialogues_exist() -> void:
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for id: StringName in Itemfinder.DIRECTION_DIALOGUES.values() + [Itemfinder.NOTHING_DIALOGUE,
			Itemfinder.HERE_DIALOGUE, RepelRules.WORE_OFF_DIALOGUE]:
		assert_not_null(dialogues.get_dialogue(id), String(id))


# --- Multi Exp --------------------------------------------------------------------------------

func test_distribute_keeps_the_total() -> void:
	var a := _mon(&"pikachu", 10)
	var b := _mon(&"rattata", 10)
	var c := _mon(&"pidgey", 10)
	var plain := ExpCalc.distribute(21, [a] as Array[Pokemon], [a, b, c] as Array[Pokemon], false)
	assert_eq(plain, {a: 21} as Dictionary[Pokemon, int])
	var shared := ExpCalc.distribute(21, [a] as Array[Pokemon], [a, b, c] as Array[Pokemon], true)
	assert_eq(shared, {a: 11 + 4, b: 3, c: 3} as Dictionary[Pokemon, int],
		"moitié (11) au participant, 10 à toute l'équipe")


func test_battle_shares_exp_with_the_bench_when_exp_all_is_carried() -> void:
	var charmander := _mon(&"charmander", 5)
	var bench := _mon(&"bulbasaur", 5)
	var bench_exp := bench.experience
	var party := Party.new()
	party.add(charmander)
	party.add(bench)
	var foes := Party.new()
	foes.add(_mon(&"pidgey", 3))
	var rules := BattleRules.for_wild()
	rules.exp_all = true
	var rng := ScriptedRng.new([1, 50, 2, 16])
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false), _data, rng,
		rules)
	battle.start()
	battle.get_foe_side().active.pokemon.hp = 1
	battle.get_foe_side().active.change_stage(&"spe", -6)
	var before := charmander.experience
	battle.submit(BattleAction.move(0))
	assert_eq(charmander.experience - before, 16, "21 XP : 11 + la moitié de 10")
	assert_eq(bench.experience - bench_exp, 5, "le Pokémon resté au banc gagne sa part")


# --- Sac --------------------------------------------------------------------------------------

func _state_with(items: Dictionary) -> Node:
	var state: Node = GameStateScript.new()
	add_child_autofree(state)
	state.new_game(3)
	state.party.add(_mon(&"pikachu", 50))
	for id: StringName in items:
		state.bag.add(id, items[id])
	return state


func _director(state: Node) -> MenuDirector:
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(state, _data, ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(state.flags, state.party), func() -> bool: return true, _items)
	return director


func test_bag_vitamin_is_consumed_and_says_what_rose() -> void:
	var state := _state_with({&"carbos": 2})
	var director := _director(state)
	var texts: Array[String] = []
	director.bag_result_shown.connect(func(text: String, _again: bool) -> void: texts.append(text))
	assert_true(director.use_item_on(&"carbos", 0))
	assert_eq(state.bag.count_of(&"carbos"), 1)
	assert_eq(state.party.get_at(0).evs[&"spe"], 10)
	assert_eq(texts, ["La Vitesse de Pikachu augmente."] as Array[String])


func test_bag_ether_asks_for_a_move_then_applies() -> void:
	var state := _state_with({&"ether": 1})
	var pikachu: Pokemon = state.party.get_at(0)
	pikachu.moves[0].pp = 0
	var director := _director(state)
	var asked: Array = []
	director.pp_move_requested.connect(func(index: int, id: StringName) -> void:
		asked.append([index, id]))
	assert_true(director.use_item_on(&"ether", 0))
	assert_eq(asked, [[0, &"ether"]])
	assert_eq(state.bag.count_of(&"ether"), 1, "rien n'est consommé avant le choix")
	assert_false(director.finish_pp_item(0, &"ether", -1), "RETOUR : rien ne change")
	assert_eq(state.bag.count_of(&"ether"), 1)
	assert_true(director.finish_pp_item(0, &"ether", 0))
	assert_eq(state.bag.count_of(&"ether"), 0)
	assert_eq(pikachu.moves[0].pp, mini(10, pikachu.moves[0].max_pp))


func test_bag_repel_sets_the_counter_without_target() -> void:
	var state := _state_with({&"super_repel": 1})
	var director := _director(state)
	var targets: Array = []
	director.bag_targets_shown.connect(func(view: PartyPickerView) -> void: targets.append(view))
	director.request_item_use(&"super_repel")
	assert_eq(state.repel_steps, 200)
	assert_eq(state.bag.count_of(&"super_repel"), 0)
	assert_true(targets.is_empty(), "aucun choix de Pokémon")


func test_bag_targets_refuse_a_capped_pokemon() -> void:
	var state := _state_with({&"protein": 1})
	(state.party.get_at(0) as Pokemon).evs[&"atk"] = 100
	var picker := BagQuery.targets(state.party, state.bag, _item(&"protein"),
		BagQuery.CONTEXT_FIELD, _data)
	assert_false(picker.targets[0].usable)
