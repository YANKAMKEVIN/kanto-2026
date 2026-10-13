extends GutTest
## Départs de débogage de la carte de QA `qa_daycare` (J15 T6, PROVISOIRES, retirés au T23) :
## chacun se charge, se pose sur la carte de QA et produit la situation annoncée au retrait
## (niveaux gagnés, capacité à apprendre, évolution, équipe pleine, argent, compagnon).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const DIR := "res://tools/debug_start/"

var _data: PokemonData
var _items: ItemLibrary
var _config: DaycareConfig


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")
	_items = ItemLibrary.new()
	_items.load_dir()
	_config = DaycareConfig.load_default()


func _start(name: String) -> Node:
	var start := DebugStart.new()
	assert_true(start.load_file(DIR + name + ".json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq(start.map, &"qa_daycare", name)
	assert_eq(start.spawn, &"counter", name)
	assert_eq(start.facing, Vector2i.UP, name)
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-12T10:00:00")
	state.new_game(15)
	start.apply(state, _data)
	return state


func test_every_start_loads_and_places_the_player_on_the_qa_map() -> void:
	for name: String in ["daycare_qa", "daycare_companion", "daycare_ready", "daycare_evolve",
			"daycare_poor", "daycare_full", "daycare_lv99"]:
		_start(name)


func test_simple_deposit_start_has_an_empty_daycare_and_money() -> void:
	var state := _start("daycare_qa")
	assert_true(state.daycare.is_empty())
	assert_eq(state.party.size(), 3)
	assert_eq(state.money, 5000)


func test_companion_start_designates_the_first_pokemon() -> void:
	var state := _start("daycare_companion")
	assert_not_null(state.get_companion())
	assert_eq(state.get_companion().species_id, &"charmander")


func test_ready_start_gains_levels_and_must_forget_a_move() -> void:
	var state := _start("daycare_ready")
	assert_eq(state.daycare.pokemon.moves.size(), 4, "4 capacités : l'oubli sera proposé")
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.OK)
	assert_eq(plan.levels_gained(), 4, "N11 → N15")
	assert_eq(plan.moves, [&"hyper_fang"] as Array[StringName])
	assert_eq(plan.evolution, &"", "pas d'évolution")
	assert_eq(plan.price, 100 + 100 * 4)


func test_evolve_start_proposes_an_evolution() -> void:
	var state := _start("daycare_evolve")
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.OK)
	assert_eq(plan.pokemon.level, 16)
	assert_eq(plan.evolution, &"charmeleon")


func test_poor_start_cannot_pay_the_price() -> void:
	var state := _start("daycare_poor")
	assert_eq(state.money, 0)
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_lt(plan.paid, plan.price, "tout l'argent est pris, le Pokémon est rendu")


func test_full_start_refuses_the_withdrawal() -> void:
	var state := _start("daycare_full")
	assert_true(state.party.is_full())
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.PARTY_FULL)


func test_level_99_start_is_capped_at_level_100() -> void:
	var state := _start("daycare_lv99")
	assert_eq(state.daycare.pokemon.level, 99)
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_eq(plan.pokemon.level, 100)


func test_qa_map_has_a_keeper_and_a_counter_that_talk_to_the_daycare() -> void:
	var map := (load("res://game/world/maps/qa_daycare.tscn") as PackedScene).instantiate() \
			as GameMap
	add_child_autofree(map)
	map.rebuild_grid()
	var found := false
	for child: Node in map.get_node(^"Interactables").get_children():
		if child is InteractPoint and (child as InteractPoint).dialogue_id == &"daycare_keeper":
			found = true
	assert_true(found, "le comptoir joue daycare_keeper")
	assert_true(map.has_spawn(&"counter"))
	assert_true(map.has_spawn(&"entrance"))
