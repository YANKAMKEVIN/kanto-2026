extends GutTest
## GameRng (aléatoire injectable) et ScriptedRng (tirages imposés des tests), jalon 4 §2.1.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")


func _draws(rng: GameRng, count: int) -> Array[int]:
	var result: Array[int] = []
	for i: int in count:
		result.append(rng.roll(1000))
	return result


func test_same_seed_gives_the_same_sequence() -> void:
	assert_eq(_draws(GameRng.new(42), 50), _draws(GameRng.new(42), 50))
	assert_ne(_draws(GameRng.new(42), 50), _draws(GameRng.new(43), 50))


func test_seed_is_kept_and_drawn_when_negative() -> void:
	assert_eq(GameRng.new(7).get_seed(), 7)
	var drawn := GameRng.new()
	assert_true(drawn.get_seed() >= 0, "graine tirée, jamais négative")
	var replay := GameRng.new(drawn.get_seed())
	assert_eq(_draws(drawn, 20), _draws(replay, 20), "la graine gardée rejoue la partie")


func test_roll_stays_in_bounds_and_covers_them() -> void:
	var rng := GameRng.new(1)
	var seen: Dictionary[int, bool] = {}
	for i: int in 600:
		var value := rng.roll(6)
		assert_between(value, 1, 6)
		seen[value] = true
	assert_eq(seen.size(), 6, "toutes les faces sortent")
	assert_eq(rng.roll(1), 1)


func test_roll_below_one_is_an_error() -> void:
	assert_eq(GameRng.new(1).roll(0), 1)
	assert_push_error("n ≥ 1")


func test_range_int_and_pick_index_bounds() -> void:
	var rng := GameRng.new(3)
	var low := 100
	var high := 0
	for i: int in 500:
		var value := rng.range_int(85, 100)
		low = mini(low, value)
		high = maxi(high, value)
		assert_between(rng.pick_index(4), 0, 3)
	assert_eq(low, 85)
	assert_eq(high, 100)


func test_chance_frequency_and_extremes() -> void:
	var rng := GameRng.new(5)
	var hits := 0
	for i: int in 4000:
		if rng.chance(1, 4):
			hits += 1
	assert_between(hits, 850, 1150, "environ un quart")
	assert_true(rng.chance(3, 3), "certitude")
	assert_false(rng.chance(0, 3), "impossible")


func test_scripted_rng_returns_the_queued_values() -> void:
	var rng := ScriptedRng.new([1, 16, 3])
	assert_true(rng.chance(1, 24), "1 → vrai")
	assert_eq(rng.range_int(85, 100), 100, "16e valeur de 85..100")
	assert_eq(rng.pick_index(4), 2)
	assert_eq(rng.remaining(), 0)
	assert_eq(rng.calls, 3)


func test_scripted_rng_empty_or_out_of_range_is_an_error() -> void:
	var rng := ScriptedRng.new([7])
	assert_eq(rng.roll(6), 6, "valeur ramenée dans les bornes")
	assert_push_error("hors de 1..6")
	rng.roll(6)
	assert_push_error("file vide")


func test_to_dict_and_from_dict_resume_the_exact_sequence() -> void:
	var rng := GameRng.new(42)
	_draws(rng, 10)
	var dict: Dictionary = JSON.parse_string(JSON.stringify(rng.to_dict()))
	assert_eq(dict["seed"], "42", "en chaînes : JSON ne garde pas les entiers 64 bits")
	assert_true((dict["state"] as String).is_valid_int())
	var resumed := GameRng.from_dict(dict)
	assert_not_null(resumed)
	assert_eq(resumed.get_seed(), 42)
	assert_eq(_draws(resumed, 20), _draws(rng, 20), "reprend exactement où il en était")
	assert_ne(_draws(GameRng.from_dict(rng.to_dict()), 5), _draws(GameRng.new(42), 5),
		"pas un simple redémarrage de la graine")


func test_from_dict_rejects_invalid_content() -> void:
	assert_null(GameRng.from_dict({}))
	assert_null(GameRng.from_dict({"seed": "-1", "state": "3"}))
	assert_null(GameRng.from_dict({"seed": 42, "state": "3"}), "nombres bruts refusés")
	assert_null(GameRng.from_dict({"seed": "42", "state": "abc"}))
	assert_push_error_count(4)
