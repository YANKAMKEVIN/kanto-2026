extends GutTest
## EncounterTable : tirage d'une rencontre (taux, poids, niveaux), ordre des tirages,
## distribution (jalon 5 §2.2, §3.6).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")


func _table() -> EncounterTable:
	var table := EncounterTable.new()
	table.id = &"t"
	table.terrain = &"grass"
	table.rate = 25
	table.slots = [
		EncounterSlot.new(&"pidgey", 2, 5, 30),
		EncounterSlot.new(&"rattata", 2, 4, 10),
	]
	return table


func test_total_weight_and_chance() -> void:
	var table := _table()
	assert_eq(table.total_weight(), 40)
	assert_almost_eq(table.chance_of(&"pidgey"), 0.75, 0.0001)
	assert_almost_eq(table.chance_of(&"rattata"), 0.25, 0.0001)
	assert_eq(table.chance_of(&"charmander"), 0.0)


func test_roll_order_of_draws() -> void:
	# Ordre imposé : roll(256) pour le taux, roll(40) pour le poids, range_int(2, 5) pour le
	# niveau. roll(256)=10 ≤ 25 → rencontre ; roll(40)=5 ≤ 30 → pidgey ; range_int(2,5) avec
	# roll(4)=2 → niveau 3.
	var rng := ScriptedRng.new([10, 5, 2])
	var result := _table().roll(rng)
	assert_not_null(result)
	assert_eq(result.species, &"pidgey")
	assert_eq(result.level, 3)
	assert_eq(result.table_id, &"t")
	assert_eq(rng.remaining(), 0, "exactement trois tirages")


func test_roll_misses_the_rate() -> void:
	# roll(256)=26 > 25 : pas de rencontre, aucun autre tirage.
	var rng := ScriptedRng.new([26])
	assert_null(_table().roll(rng))
	assert_eq(rng.remaining(), 0)


func test_weight_selects_the_second_slot() -> void:
	# roll(40)=35 : dépasse 30 (pidgey), tombe sur rattata ; range_int(2,4)=4 → niveau 4.
	var rng := ScriptedRng.new([1, 35, 3])
	var result := _table().roll(rng)
	assert_eq(result.species, &"rattata")
	assert_eq(result.level, 4)


func test_pick_skips_the_rate_test() -> void:
	# pick n'utilise pas roll(256) : premier tirage = poids.
	var rng := ScriptedRng.new([5, 1])
	var result := _table().pick(rng)
	assert_eq(result.species, &"pidgey")
	assert_eq(result.level, 2)


func test_levels_stay_in_bounds_over_many_rolls() -> void:
	var rng := GameRng.new(1234)
	for i: int in 2000:
		var result := _table().pick(rng)
		if result.species == &"pidgey":
			assert_between(result.level, 2, 5)
		else:
			assert_between(result.level, 2, 4)


func test_distribution_matches_weights() -> void:
	# 10 000 pick avec une graine : ~75 % pidgey (±2 points).
	var rng := GameRng.new(42)
	var pidgey := 0
	var n := 10000
	for i: int in n:
		if _table().pick(rng).species == &"pidgey":
			pidgey += 1
	var ratio := float(pidgey) / float(n)
	assert_almost_eq(ratio, 0.75, 0.02)


func test_empty_table_yields_nothing() -> void:
	var table := EncounterTable.new()
	assert_null(table.pick(ScriptedRng.new([])))
	assert_null(table.roll(ScriptedRng.new([])))


# --- Jalon 19 (T5) --------------------------------------------------------------------------

func test_floor_is_a_known_terrain() -> void:
	assert_true(EncounterTable.TERRAINS.has(&"floor"))
	assert_true(EncounterTable.TERRAINS.has(&"grass"), "les terrains d'avant restent")
	assert_true(EncounterTable.TERRAINS.has(&"rubble"))


func test_ghost_item_is_empty_by_default() -> void:
	assert_eq(EncounterTable.new().ghost_unless_item, &"")


func test_roll_never_decides_the_ghost() -> void:
	# La table porte la clé ; le tirage ne décide rien : GhostRule, avec le Sac du moment.
	var table := _table()
	table.terrain = &"floor"
	table.ghost_unless_item = &"silph_scope"
	var result := table.roll(ScriptedRng.new([10, 5, 2]))
	assert_not_null(result)
	assert_false(result.ghost, "faux par défaut")
	assert_false(table.pick(GameRng.new(7)).ghost)
	assert_true(GhostRule.is_ghost(table.ghost_unless_item, Bag.new()), "décidé à part")
