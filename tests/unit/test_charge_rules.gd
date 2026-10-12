extends GutTest
## « Charge puis frappe » (jalon 14 T7, `jalon-14.md` §2.3) : règles pures ([ChargeRules]),
## lecture de l'effet « charge » ([PokemonData]), état volatil du [Battler], messages.

const J14Moves := preload("res://tests/helpers/j14_moves.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	J14Moves.ensure(_data)


func _move(entry: Dictionary) -> MoveData:
	var data := PokemonData.new()
	data.add_moves_from_dict({"m": entry}, "test")
	return data.get_move(&"m")


func _battler(species: StringName = &"rattata") -> Battler:
	var pokemon := PokemonFactory.create(_data, species, 5, GameRng.new(1))
	return Battler.new(pokemon, _data.get_species(species).types)


func test_dig_reads_charge_effect() -> void:
	var dig := _data.get_move(&"dig")
	assert_not_null(dig)
	var effect := dig.charge_effect()
	assert_not_null(effect, "dig sans effet « charge » : remplacer pending_effects (T5) par §2.3")
	assert_eq(effect.texts, &"dig")
	assert_true(effect.invulnerable)
	assert_eq([dig.power, dig.accuracy, dig.pp], [100, 100, 10], "RB")
	assert_null(_data.get_move(&"tackle").charge_effect())


func test_invulnerable_is_optional_and_texts_required() -> void:
	var base := {"name": "C", "type": "normal", "category": "physical", "power": 120,
		"accuracy": 100, "pp": 10, "description": "…"}
	var plain := base.duplicate()
	plain["effects"] = [{"kind": "charge", "texts": "skull_bash"}]
	var move := _move(plain)
	assert_not_null(move)
	assert_false(move.charge_effect().invulnerable, "Coud'Krâne : pas d'invulnérabilité")
	for bad: Dictionary in [{"kind": "charge"}, {"kind": "charge", "texts": ""},
			{"kind": "charge", "texts": "Dig"}, {"kind": "charge", "texts": "dig",
			"invulnerable": 1}, {"kind": "charge", "texts": "dig", "extra": true}]:
		var entry := base.duplicate()
		entry["effects"] = [bad]
		var data := PokemonData.new()
		assert_false(data.add_moves_from_dict({"m": entry}, "test"), str(bad))
	assert_push_error_count(5)


func test_charge_needs_a_damaging_move() -> void:
	var data := PokemonData.new()
	assert_false(data.add_moves_from_dict({"m": {"name": "C", "type": "normal",
		"category": "status", "accuracy": 0, "pp": 10, "description": "…",
		"effects": [{"kind": "charge", "texts": "dig"}]}}, "test"))
	assert_push_error_count(1)


func test_targets_foe() -> void:
	for id: StringName in [&"tackle", &"seismic_toss", &"super_fang", &"growl",
			&"poison_powder", &"leech_seed", &"supersonic", &"sleep_powder", &"thunder_wave"]:
		assert_true(ChargeRules.targets_foe(_data.get_move(id)), String(id))
	for id: StringName in [&"harden", &"focus_energy", &"bide", &"growth", &"teleport"]:
		assert_false(ChargeRules.targets_foe(_data.get_move(id)), String(id))
	assert_false(ChargeRules.targets_foe(null))


func test_dodges_only_when_invulnerable() -> void:
	var target := _battler()
	var tackle := _data.get_move(&"tackle")
	assert_false(ChargeRules.dodges(target, tackle))
	target.invulnerable = true
	assert_true(ChargeRules.dodges(target, tackle))
	assert_false(ChargeRules.dodges(target, _data.get_move(&"harden")))


func test_breaks_charge() -> void:
	assert_false(ChargeRules.breaks_charge(StatusRules.NONE, true))
	assert_false(ChargeRules.breaks_charge(StatusRules.POISON, true))
	assert_false(ChargeRules.breaks_charge(StatusRules.PARALYSIS, true))
	assert_true(ChargeRules.breaks_charge(StatusRules.NONE, false), "toute action empêchée")
	assert_true(ChargeRules.breaks_charge(StatusRules.SLEEP, true), "réveillé ici : remonte")
	assert_true(ChargeRules.breaks_charge(StatusRules.FREEZE, true), "dégelé ici : remonte")


func test_battler_lock_reads_bide_or_charge() -> void:
	var battler := _battler()
	assert_false(battler.is_locked())
	assert_eq(battler.locked_slot(), -1)
	battler.charge_slot = 2
	battler.invulnerable = true
	assert_true(battler.is_charging())
	assert_true(battler.is_locked())
	assert_eq(battler.locked_slot(), 2)
	battler.clear_charge()
	assert_false(battler.is_locked())
	assert_false(battler.invulnerable)
	battler.bide_stage = 1
	battler.bide_slot = 1
	assert_eq(battler.locked_slot(), 1)


func test_messages() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	var event := BattleEvent.new(BattleEvent.Kind.CHARGE_STARTED)
	event.pokemon_name = "Sabelette"
	event.move_id = &"dig"
	assert_eq(Array(texts.lines(event, _data)), ["Sabelette creuse un trou !"], "n° 52")
	event.kind = BattleEvent.Kind.CHARGE_BROKEN
	assert_eq(Array(texts.lines(event, _data)), ["Sabelette remonte à la surface."], "n° 54")
	event.kind = BattleEvent.Kind.CHARGE_RELEASED
	assert_eq(Array(texts.lines(event, _data)), [], "pas de phrase : le MOVE_USED suit")
	event.kind = BattleEvent.Kind.DODGED
	assert_eq(Array(texts.lines(event, _data)), ["Sabelette évite l'attaque !"], "n° 53")
	event.kind = BattleEvent.Kind.BALL_BLOCKED
	assert_eq(Array(texts.lines(event, _data)), ["Impossible de viser !"], "n° 55")
	event.kind = BattleEvent.Kind.CHARGE_STARTED
	event.move_id = &"tackle"
	assert_eq(Array(texts.lines(event, _data)), [], "sans effet charge : pas de phrase")
