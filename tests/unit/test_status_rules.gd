extends GutTest
## StatusRules (jalon 9 §2.1.1, Q-6) : vocabulaire des statuts et règles du poison.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const NORMAL: Array[StringName] = [&"normal"]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func test_poison_is_the_only_known_status_at_j9() -> void:
	assert_eq(StatusRules.KNOWN, [&"poison"] as Array[StringName])
	assert_eq(StatusRules.POISON, &"poison")
	assert_eq(StatusRules.NONE, &"")


func test_is_known() -> void:
	assert_true(StatusRules.is_known(&"poison"))
	assert_false(StatusRules.is_known(StatusRules.NONE), "« aucun » n'est pas un statut")
	assert_false(StatusRules.is_known(&"paralysis"), "paralysie : J11")


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
	assert_eq(StatusRules.immune_types(&"burn"), [] as Array[StringName])


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
