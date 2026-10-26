extends GutTest
## Poison grave de Toxik (J23, dossier 26 §10.4, N-14 ; plan `jalon-23.md` §2.12, T5) : ToxicRules.

var _data: PokemonData
var _rng: GameRng


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_rng = GameRng.new(23)


func _poisoned(level: int = 40) -> Pokemon:
	var mon := PokemonFactory.create(_data, &"rattata", level, _rng)
	mon.status = StatusRules.POISON
	return mon


func test_counter_grows_from_one_and_is_capped() -> void:
	assert_eq(ToxicRules.next_counter(ToxicRules.OFF), 1)
	assert_eq(ToxicRules.next_counter(1), 2)
	assert_eq(ToxicRules.next_counter(ToxicRules.MAX_COUNTER), ToxicRules.MAX_COUNTER)


func test_damage_is_n_sixteenths_of_max_hp() -> void:
	var mon := _poisoned()
	var max_hp := mon.max_hp()
	assert_eq(ToxicRules.end_turn_damage(mon, 1), maxi(floori(max_hp / 16.0), 1))
	assert_eq(ToxicRules.end_turn_damage(mon, 3), floori(max_hp * 3 / 16.0))


func test_damage_has_a_floor_of_one_and_a_ceiling_of_current_hp() -> void:
	var small := _poisoned(2)
	assert_eq(ToxicRules.end_turn_damage(small, 1), 1, "au moins 1 PV")
	var low := _poisoned()
	low.hp = 3
	assert_eq(ToxicRules.end_turn_damage(low, 10), 3, "au plus les PV restants")


func test_no_damage_without_poison_counter_or_when_fainted() -> void:
	var mon := _poisoned()
	assert_eq(ToxicRules.end_turn_damage(mon, ToxicRules.OFF), 0, "compteur nul")
	mon.status = StatusRules.NONE
	assert_eq(ToxicRules.end_turn_damage(mon, 2), 0, "plus empoisonné")
	var fainted := _poisoned()
	fainted.hp = 0
	assert_eq(ToxicRules.end_turn_damage(fainted, 2), 0)


func test_reset_turns_it_into_plain_poison() -> void:
	assert_eq(ToxicRules.reset_counter(), ToxicRules.OFF)
	var mon := _poisoned()
	assert_eq(StatusRules.end_turn_damage(mon), maxi(floori(mon.max_hp() / 8.0), 1),
		"compteur remis à zéro : le poison simple du J9 s'applique")
