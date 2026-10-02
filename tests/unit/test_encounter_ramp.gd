extends GutTest
## Montée du taux de rencontre avec la série de pas d'herbe sans rencontre (jalon 5 §3.6,
## décision de Kevin du 2026-10-02) : règle du taux effectif de [EncounterTable], garantie
## d'une rencontre au plus tard au pas maximum, ordre des tirages, reproductibilité, lecture
## de la clé « ramp » par [EncounterLibrary] et valeurs de la Route 1.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _table(rate: int = 25, from_step: int = 0, max_steps: int = 0) -> EncounterTable:
	var table := EncounterTable.new()
	table.id = &"t"
	table.terrain = &"grass"
	table.rate = rate
	table.ramp_from = from_step
	table.ramp_max = max_steps
	table.slots = [
		EncounterSlot.new(&"pidgey", 2, 5, 30),
		EncounterSlot.new(&"rattata", 2, 4, 10),
	]
	return table


func _ramp_table() -> EncounterTable:
	return _table(25, 15, 20)


func _lib() -> EncounterLibrary:
	return EncounterLibrary.new(_data)


func _valid_dict() -> Dictionary:
	return {
		"route_1_grass": {
			"maps": ["route_1"], "terrain": "grass", "rate": 25,
			"slots": [{ "species": "pidgey", "levels": [2, 5], "weight": 20 }],
		},
	}


# --- Taux effectif ---------------------------------------------------------------------

func test_without_ramp_the_rate_is_fixed() -> void:
	var table := _table()
	assert_false(table.has_ramp())
	assert_eq(table.ramp_increment(), 0)
	for quiet: int in [0, 5, 40, 200]:
		assert_eq(table.effective_rate(quiet), 25)


func test_ramp_keeps_the_base_rate_then_climbs_to_certain() -> void:
	# rate 25, de 15 à 20 : (256 - 25) / 5 → +47 par pas ; pas k = quiet_steps + 1.
	var table := _ramp_table()
	assert_true(table.has_ramp())
	assert_eq(table.ramp_increment(), 47)
	assert_eq(table.effective_rate(0), 25, "premier pas : taux de base")
	assert_eq(table.effective_rate(14), 25, "pas 15 : encore le taux de base")
	assert_eq(table.effective_rate(15), 72, "pas 16")
	assert_eq(table.effective_rate(16), 119)
	assert_eq(table.effective_rate(17), 166)
	assert_eq(table.effective_rate(18), 213)
	assert_eq(table.effective_rate(19), EncounterTable.RATE_DEN, "pas 20 : certain")
	assert_eq(table.effective_rate(500), EncounterTable.RATE_DEN, "plafonné")


func test_the_last_step_is_always_certain_and_the_rate_never_decreases() -> void:
	for rate: int in [1, 10, 25, 128, 254, 255]:
		for from_step: int in [1, 5, 12]:
			for max_steps: int in [from_step + 1, from_step + 7, 20, 40]:
				var table := _table(rate, from_step, max_steps)
				var label := "taux %d, de %d à %d" % [rate, from_step, max_steps]
				assert_eq(table.effective_rate(max_steps - 1), EncounterTable.RATE_DEN, label)
				var previous := 0
				for quiet: int in max_steps + 5:
					var effective := table.effective_rate(quiet)
					assert_true(effective >= previous and effective >= rate, label)
					assert_true(effective <= EncounterTable.RATE_DEN, label)
					previous = effective


# --- Tirage ----------------------------------------------------------------------------

func test_roll_with_a_ramp_keeps_the_order_of_draws() -> void:
	# Au pas 20 (quiet_steps = 19) le taux effectif vaut 256 : roll(256)=256 passe quand même,
	# puis roll(40) pour le poids et range_int pour le niveau. Toujours un seul tirage de taux.
	var rng := ScriptedRng.new([256, 5, 2])
	var result := _ramp_table().roll(rng, 19)
	assert_not_null(result)
	assert_eq(result.species, &"pidgey")
	assert_eq(result.level, 3)
	assert_eq(rng.remaining(), 0, "exactement trois tirages, comme sans montée")


func test_roll_with_a_ramp_still_misses_below_the_effective_rate() -> void:
	# Pas 16 : taux effectif 72 ; 73 le manque (un seul tirage), 72 le passe.
	var missed := ScriptedRng.new([73])
	assert_null(_ramp_table().roll(missed, 15))
	assert_eq(missed.remaining(), 0)
	assert_not_null(_ramp_table().roll(ScriptedRng.new([72, 1, 1]), 15))


func test_roll_without_quiet_steps_is_the_old_behaviour() -> void:
	# Même appel qu'avant la montée : taux de base, 26 > 25 manque, 25 passe.
	assert_null(_ramp_table().roll(ScriptedRng.new([26])))
	assert_not_null(_ramp_table().roll(ScriptedRng.new([25, 1, 1])))


func test_a_series_never_exceeds_the_last_step_of_the_ramp() -> void:
	# La vraie boucle du directeur : compteur +1 sans rencontre, remis à 0 sur une rencontre.
	var table := _ramp_table()
	var rng := GameRng.new(2026)
	var quiet := 0
	var longest := 0
	var encounters := 0
	for i: int in 50000:
		if table.roll(rng, quiet) == null:
			quiet += 1
			longest = maxi(longest, quiet)
		else:
			quiet = 0
			encounters += 1
	assert_true(encounters > 4000, "des rencontres régulières (%d)" % encounters)
	assert_true(longest <= table.ramp_max - 1,
		"au plus %d pas sans rencontre, vu %d" % [table.ramp_max - 1, longest])


func test_same_seed_same_steps_same_encounters() -> void:
	var table := _ramp_table()
	var first := _walk(table, 7, 400)
	var second := _walk(table, 7, 400)
	assert_eq(first, second, "même graine, mêmes pas : mêmes rencontres")
	assert_ne(first, _walk(table, 8, 400), "une autre graine change le parcours")
	assert_gt(first.size(), 0)


## Marche [param steps] pas d'herbe ; renvoie « pas:espèce:niveau » pour chaque rencontre.
func _walk(table: EncounterTable, seed_value: int, steps: int) -> Array[String]:
	var rng := GameRng.new(seed_value)
	var quiet := 0
	var found: Array[String] = []
	for step: int in steps:
		var result := table.roll(rng, quiet)
		if result == null:
			quiet += 1
		else:
			quiet = 0
			found.append("%d:%s:%d" % [step, result.species, result.level])
	return found


# --- Lecture de la clé « ramp » ----------------------------------------------------------

func test_ramp_is_read_and_optional() -> void:
	var lib := _lib()
	assert_true(lib.add_from_dict(_valid_dict(), "test"))
	assert_false(lib.get_table(&"route_1").has_ramp(), "sans « ramp » : taux fixe")
	var dict := _valid_dict()
	dict["route_1_grass"]["ramp"] = { "from_step": 15, "max_steps": 20 }
	lib = _lib()
	assert_true(lib.add_from_dict(dict, "test"))
	var table := lib.get_table(&"route_1")
	assert_true(table.has_ramp())
	assert_eq(table.ramp_from, 15)
	assert_eq(table.ramp_max, 20)


func test_invalid_ramps_are_rejected() -> void:
	var bad: Array = [
		{ "from_step": 20, "max_steps": 20 },
		{ "from_step": 0, "max_steps": 20 },
		{ "from_step": 15, "max_steps": 300 },
		{ "from_step": 1.5, "max_steps": 20 },
		{ "from_step": 15 },
		{ "from_step": 15, "max_steps": 20, "extra": 1 },
		"vite",
	]
	for ramp: Variant in bad:
		var dict := _valid_dict()
		dict["route_1_grass"]["ramp"] = ramp
		var lib := _lib()
		assert_false(lib.add_from_dict(dict, "test"), "ramp %s" % str(ramp))
		assert_false(lib.has_table(&"route_1", &"grass"))
		assert_push_error("ramp")


func test_route_1_ramp_guarantees_an_encounter_by_step_20() -> void:
	var lib := _lib()
	assert_true(lib.load_dir())
	var table := lib.get_table(&"route_1")
	assert_true(table.has_ramp(), "la Route 1 monte (décision du 2026-10-02)")
	assert_eq(table.rate, 25, "taux de base validé au T8")
	assert_true(table.ramp_max <= 20)
	assert_eq(table.effective_rate(table.ramp_max - 1), EncounterTable.RATE_DEN)
