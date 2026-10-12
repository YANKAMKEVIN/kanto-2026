extends GutTest
## StatusRules (jalon 9 §2.1.1, Q-6 ; jalon 11 §2.2) : vocabulaire des statuts, règles du
## poison et des statuts du J11 (paralysie, sommeil, brûlure, gel).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const NORMAL: Array[StringName] = [&"normal"]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func test_the_five_major_statuses_are_known_at_j11() -> void:
	assert_eq(StatusRules.KNOWN, [&"poison", &"paralysis", &"sleep", &"burn", &"freeze"]
		as Array[StringName])
	assert_eq(StatusRules.POISON, &"poison")
	assert_eq(StatusRules.NONE, &"")


func test_is_known() -> void:
	assert_true(StatusRules.is_known(&"poison"))
	assert_false(StatusRules.is_known(StatusRules.NONE), "« aucun » n'est pas un statut")
	assert_true(StatusRules.is_known(&"paralysis"), "paralysie : J11")
	assert_false(StatusRules.is_known(&"confusion"), "la confusion est un état temporaire")


func test_poison_can_be_inflicted_on_a_healthy_pokemon() -> void:
	var rattata := _mon(&"rattata", 3)
	assert_eq(StatusRules.can_inflict(&"poison", rattata, NORMAL), StatusRules.Inflict.OK)
	assert_eq(rattata.status, StatusRules.NONE, "rien ne change")


func test_poison_and_steel_types_are_immune() -> void:
	var weedle := _mon(&"weedle", 3)
	assert_eq(StatusRules.can_inflict(&"poison", weedle, [&"bug", &"poison"] as Array[StringName]),
		StatusRules.Inflict.IMMUNE)
	assert_eq(StatusRules.can_inflict(&"poison", weedle, [&"steel"] as Array[StringName]),
		StatusRules.Inflict.IMMUNE, "Acier (Q-6, règles actuelles)")
	assert_eq(StatusRules.POISON_IMMUNE_TYPES, [&"poison", &"steel"] as Array[StringName])
	assert_eq(StatusRules.immune_types(&"sleep"), [] as Array[StringName], "aucune immunité")


func test_one_status_at_a_time() -> void:
	var rattata := _mon(&"rattata", 3)
	rattata.status = StatusRules.POISON
	assert_eq(StatusRules.can_inflict(&"poison", rattata, NORMAL), StatusRules.Inflict.ALREADY)


func test_a_fainted_pokemon_receives_nothing() -> void:
	var rattata := _mon(&"rattata", 3)
	rattata.hp = 0
	assert_eq(StatusRules.can_inflict(&"poison", rattata, NORMAL), StatusRules.Inflict.FAINTED)
	assert_eq(StatusRules.can_inflict(&"poison", null, NORMAL), StatusRules.Inflict.FAINTED)


func test_poison_takes_an_eighth_of_max_hp_at_the_end_of_the_turn() -> void:
	var charmander := _mon(&"charmander", 20)
	charmander.status = StatusRules.POISON
	var max_hp := charmander.max_hp()
	assert_eq(StatusRules.end_turn_damage(charmander), floori(max_hp / 8.0))
	assert_eq(charmander.hp, max_hp, "rien n'est retiré ici (le moteur le fait)")


func test_poison_takes_at_least_one_hp_and_at_most_what_is_left() -> void:
	var pidgey := _mon(&"pidgey", 2)
	pidgey.status = StatusRules.POISON
	assert_lt(pidgey.max_hp(), 16, "1/8 < 2")
	assert_eq(StatusRules.end_turn_damage(pidgey), 1, "au moins 1")
	var charmander := _mon(&"charmander", 20)
	charmander.status = StatusRules.POISON
	charmander.hp = 2
	assert_eq(StatusRules.end_turn_damage(charmander), 2, "jamais plus que les PV restants")


func test_no_damage_without_poison_or_when_fainted() -> void:
	var charmander := _mon(&"charmander", 20)
	assert_eq(StatusRules.end_turn_damage(charmander), 0, "sans statut")
	charmander.status = StatusRules.POISON
	charmander.hp = 0
	assert_eq(StatusRules.end_turn_damage(charmander), 0, "K.O.")
	assert_eq(StatusRules.end_turn_damage(null), 0)


func test_catch_bonus() -> void:
	assert_eq(StatusRules.catch_bonus(StatusRules.POISON), 1.5, "Q-6 : ×1,5")
	assert_eq(StatusRules.catch_bonus(StatusRules.NONE), 1.0)
	assert_eq(StatusRules.catch_bonus(StatusRules.PARALYSIS), 1.5)
	assert_eq(StatusRules.catch_bonus(StatusRules.BURN), 1.5)
	assert_eq(StatusRules.catch_bonus(StatusRules.SLEEP), 2.5)
	assert_eq(StatusRules.catch_bonus(StatusRules.FREEZE), 2.5)


# --- Jalon 11 ------------------------------------------------------------------------------

func test_fire_electric_and_ice_types_are_immune_to_their_status() -> void:
	var pikachu := _mon(&"pikachu", 5)
	assert_eq(StatusRules.can_inflict(&"paralysis", pikachu, [&"electric"] as Array[StringName]),
		StatusRules.Inflict.IMMUNE)
	assert_eq(StatusRules.can_inflict(&"burn", pikachu, [&"fire"] as Array[StringName]),
		StatusRules.Inflict.IMMUNE)
	assert_eq(StatusRules.can_inflict(&"freeze", pikachu, [&"ice"] as Array[StringName]),
		StatusRules.Inflict.IMMUNE)
	assert_eq(StatusRules.can_inflict(&"paralysis", pikachu, NORMAL), StatusRules.Inflict.OK)


func test_burn_takes_a_sixteenth_and_halves_physical_damage() -> void:
	var charmander := _mon(&"charmander", 40)
	charmander.status = StatusRules.BURN
	assert_eq(StatusRules.end_turn_damage(charmander), floori(charmander.max_hp() / 16.0))
	assert_true(StatusRules.halves_physical(StatusRules.BURN))
	assert_false(StatusRules.halves_physical(StatusRules.POISON))
	var pidgey := _mon(&"pidgey", 2)
	pidgey.status = StatusRules.BURN
	assert_eq(StatusRules.end_turn_damage(pidgey), 1, "au moins 1")


func test_paralysis_halves_speed_and_blocks_on_25_or_less() -> void:
	assert_eq(StatusRules.speed_multiplier(StatusRules.PARALYSIS), 0.5)
	assert_eq(StatusRules.speed_multiplier(StatusRules.BURN), 1.0)
	var rattata := _mon(&"rattata", 3)
	rattata.status = StatusRules.PARALYSIS
	assert_eq(StatusRules.check_act(rattata, ScriptedRng.new([25])), StatusRules.Act.FULLY_PARALYZED)
	assert_eq(StatusRules.check_act(rattata, ScriptedRng.new([26])), StatusRules.Act.OK)
	assert_eq(rattata.status, StatusRules.PARALYSIS, "la paralysie ne passe pas seule")


func test_sleep_lasts_its_drawn_turns_then_wakes_and_acts() -> void:
	var rattata := _mon(&"rattata", 3)
	StatusRules.apply(StatusRules.SLEEP, rattata, ScriptedRng.new([2]))
	assert_eq([rattata.status, rattata.status_turns], [StatusRules.SLEEP, 2], "1 à 3 tours (2)")
	var rng := ScriptedRng.new()
	assert_eq(StatusRules.check_act(rattata, rng), StatusRules.Act.ASLEEP)
	assert_eq(StatusRules.check_act(rattata, rng), StatusRules.Act.ASLEEP)
	assert_eq(rattata.status_turns, 0)
	assert_eq(StatusRules.check_act(rattata, rng), StatusRules.Act.WOKE_UP, "agit au réveil")
	assert_eq(rattata.status, StatusRules.NONE)
	assert_eq(rng.calls, 0, "le sommeil ne tire rien")
	StatusRules.apply(StatusRules.SLEEP, rattata, ScriptedRng.new([1]))
	assert_eq(rattata.status_turns, 1, "au moins 1")


func test_freeze_thaws_on_20_or_less() -> void:
	var rattata := _mon(&"rattata", 3)
	StatusRules.apply(StatusRules.FREEZE, rattata, ScriptedRng.new())
	assert_eq(rattata.status_turns, 0, "pas de compteur pour le gel")
	assert_eq(StatusRules.check_act(rattata, ScriptedRng.new([21])), StatusRules.Act.FROZEN)
	assert_eq(StatusRules.check_act(rattata, ScriptedRng.new([20])), StatusRules.Act.THAWED)
	assert_eq(rattata.status, StatusRules.NONE)


func test_no_status_never_draws_and_acts() -> void:
	var rattata := _mon(&"rattata", 3)
	var rng := ScriptedRng.new()
	assert_eq(StatusRules.check_act(rattata, rng), StatusRules.Act.OK)
	rattata.status = StatusRules.POISON
	assert_eq(StatusRules.check_act(rattata, rng), StatusRules.Act.OK)
	assert_eq(rng.calls, 0)
