extends GutTest
## Départs de débogage des sessions 15A et 15B sur les **vraies** cartes (jalon 15 T15/T20,
## jalon-15.md §2.12, §3 « T22 ») : chacun se charge, se pose sur une case praticable de sa carte
## et produit la situation annoncée par le protocole (Pension réelle : dépôt du compagnon, refus
## du dernier apte, retrait avec capacité, oubli et évolution ; Jackpot ; Basile ; Passe Bateau).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const DIR := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation].
const STARTS := {
	"route_5": [&"route_5", &"from_cerulean_c", Vector2i.DOWN],
	"route_5_daycare": [&"route_5_daycare", &"counter", Vector2i.UP],
	"route_5_daycare_last": [&"route_5_daycare", &"counter", Vector2i.UP],
	"route_5_daycare_ready": [&"route_5_daycare", &"counter", Vector2i.UP],
	"route_5_pay_day": [&"route_5", &"from_cerulean_c", Vector2i.DOWN],
	"route_6_basile": [&"route_6", &"belvedere", Vector2i.UP],
	"vermilion_ss_ticket": [&"vermilion_city", &"from_route_6_c", Vector2i.DOWN],
}

var _data: PokemonData
var _items: ItemLibrary
var _config: DaycareConfig


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")
	_items = ItemLibrary.new()
	_items.load_dir()
	_config = DaycareConfig.load_default()


func _load(name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(DIR + name + ".json", _data, _items),
		"%s : %s" % [name, "\n".join(start.get_errors())])
	return start


func _state(name: String) -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-15T10:00:00")
	state.new_game(15)
	_load(name).apply(state, _data)
	return state


func test_every_start_lands_on_a_real_walkable_spawn() -> void:
	for name: String in STARTS:
		var start := _load(name)
		assert_eq([start.map, start.spawn, start.facing], STARTS[name], name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)


func test_daycare_start_has_meowth_as_companion_and_a_fainted_member() -> void:
	var state := _state("route_5_daycare")
	assert_true(state.daycare.is_empty(), "Pension vide")
	assert_eq(state.get_companion().species_id, &"meowth", "Miaouss compagnon (à déposer)")
	assert_true(state.party.get_at(2).is_fainted(), "Roucool K.O. : déposable")


func test_last_start_refuses_the_only_able_pokemon() -> void:
	var state := _state("route_5_daycare_last")
	var able := 0
	for index: int in state.party.size():
		if not state.party.get_at(index).is_fainted():
			able += 1
	assert_eq(able, 1, "Miaouss seul en forme : T-5 sur sa carte")


func test_ready_start_teaches_with_a_forget_choice_then_evolves() -> void:
	var state := _state("route_5_daycare_ready")
	assert_eq(state.get_companion().species_id, &"meowth")
	assert_eq(state.daycare.pokemon.moves.size(), 4, "4 capacités : l'oubli sera proposé")
	assert_eq(state.daycare.pokemon.hp, 1, "gardé à 1 PV et empoisonné : le soin se voit")
	assert_eq(state.daycare.pokemon.status, StatusRules.POISON)
	var plan := DaycareRules.withdraw(state.daycare, state.party, state.money, _config, _data)
	assert_eq(plan.status, DaycareRules.Status.OK)
	assert_eq(plan.levels_gained(), 2, "N14 → N16")
	assert_eq(plan.moves, [&"leer"] as Array[StringName], "Groz'Yeux au N15")
	assert_eq(plan.evolution, &"charmeleon", "évolution proposée")
	assert_eq(plan.price, 100 + 100 * 2)


func test_pay_day_start_has_meowth_17_with_pay_day_and_a_forced_table() -> void:
	var start := _load("route_5_pay_day")
	var state := _state("route_5_pay_day")
	var lead: Pokemon = state.party.get_at(0)
	assert_eq(lead.species_id, &"meowth")
	assert_gte(lead.level, 17)
	var moves: Array[StringName] = []
	for slot: MoveSlot in lead.moves:
		moves.append(slot.move_id)
	assert_true(moves.has(&"pay_day"), "Jackpot")
	assert_eq(int(start.wild.get("rate", 0)), 255, "rencontre au premier pas d'herbe")


func test_basile_start_is_next_to_his_file_and_the_others_are_beaten() -> void:
	var state := _state("route_6_basile")
	for id: String in ["lass_chloe", "camper_gabin", "scout_axel", "camper_mathis",
			"lass_manon"]:
		assert_true(state.flags.has_flag(StringName("beaten_route_6_" + id)), id)
	assert_false(state.flags.has_flag(&"beaten_route_6_scout_basile"))
	var roster := NpcRoster.load_for_map(&"route_6")
	var basile := roster.get_spec(&"scout_basile")
	var start := _load("route_6_basile")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var one_up := map.get_spawn_cell(start.spawn) + Vector2i.UP
	var seen := false
	for k: int in range(1, basile.sight + 1):
		seen = seen or basile.cell + basile.facing * k == one_up
	assert_true(seen, "un pas vers le nord : Basile voit le joueur")
	assert_eq(state.bag.count_of(&"paralyze_heal"), 2)
	assert_eq(state.bag.count_of(&"awakening"), 2)


func test_ticket_start_holds_the_ss_ticket() -> void:
	var state := _state("vermilion_ss_ticket")
	assert_true(state.flags.has_flag(&"got_ss_ticket"))
	assert_eq(state.bag.count_of(&"ss_ticket"), 1)
	assert_false(state.flags.has_flag(&"vermilion_reached"), "l'arrivée reste à jouer")


## Registre des reportés (RP-002) : l'objectif de la Route 5 est juste dès le premier pas.
func test_route_5_start_has_entered_the_route() -> void:
	var state := _state("route_5")
	assert_true(state.flags.has_flag(&"route_5_entered"), "objectif de la Route 5, pas du Badge")
