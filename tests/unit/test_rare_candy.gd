extends GutTest
## RareCandy (jalon 14, T18a, jalon-14.md §2.6) : +1 niveau hors combat, statistiques et PV,
## capacités du niveau proposées (jamais apprises ici), évolution signalée, refus au niveau 100
## et sur un Pokémon K.O. Règle pure, données réelles (Abra, Kadabra, Machoc du jalon 14).

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _create(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


func _threshold(pokemon: Pokemon, level: int) -> int:
	return ExpCurve.exp_for_level(_data.get_species(pokemon.species_id).growth_rate, level)


# --- check ------------------------------------------------------------------------------------

func test_check_ok_max_level_and_fainted() -> void:
	var abra := _create(&"abra", 15)
	assert_eq(RareCandy.check(abra), RareCandy.Check.OK)
	assert_eq(RareCandy.check(_create(&"machop", 99)), RareCandy.Check.OK, "99 : encore un")
	assert_eq(RareCandy.check(_create(&"machop", 100)), RareCandy.Check.MAX_LEVEL)
	abra.hp = 0
	assert_eq(RareCandy.check(abra), RareCandy.Check.FAINTED)
	assert_eq(RareCandy.check(null), RareCandy.Check.FAINTED)


# --- apply ------------------------------------------------------------------------------------

func test_apply_gains_exactly_one_level_at_the_threshold() -> void:
	var abra := _create(&"abra", 15)
	var step := RareCandy.apply(abra, _data)
	assert_not_null(step)
	assert_eq(abra.level, 16)
	assert_eq(step.level, 16)
	assert_eq(abra.experience, _threshold(abra, 16), "XP au seuil exact du niveau 16")


func test_apply_with_partial_experience_still_gains_one_level_only() -> void:
	var machop := _create(&"machop", 19)
	machop.experience = _threshold(machop, 20) - 3
	var step := RareCandy.apply(machop, _data)
	assert_eq(machop.level, 20)
	assert_eq(step.level, 20)
	assert_eq(machop.experience, _threshold(machop, 20))


func test_apply_recalculates_stats_and_raises_hp_by_the_difference() -> void:
	var abra := _create(&"abra", 15)
	abra.hp = abra.max_hp() - 5
	var before := abra.stats.duplicate()
	var step := RareCandy.apply(abra, _data)
	var expected := StatCalc.compute(_data.get_species(&"abra"), 16, abra.ivs, abra.evs)
	assert_eq(abra.stats, expected, "statistiques du niveau 16")
	assert_eq(abra.hp, abra.max_hp() - 5, "les PV perdus restent perdus")
	for stat: StringName in SpeciesData.STATS:
		assert_eq(step.stat_gains[stat], expected[stat] - before[stat], String(stat))


func test_apply_lists_the_level_moves_without_learning_them() -> void:
	var machop := _create(&"machop", 19)
	assert_eq(machop.moves.size(), 1, "Poing Karaté seul (table RB)")
	var step := RareCandy.apply(machop, _data)
	assert_eq(step.moves, [&"low_kick"] as Array[StringName], "Balayage au niveau 20")
	assert_false(machop.knows_move(&"low_kick"), "la présentation le propose, rien n'est appris")
	assert_eq(machop.moves.size(), 1)


func test_apply_skips_a_move_already_known() -> void:
	var kadabra := _create(&"kadabra", 15)
	assert_true(kadabra.knows_move(&"confusion"))
	var step := RareCandy.apply(kadabra, _data)
	assert_eq(step.moves, [] as Array[StringName], "Choc Mental déjà connu au niveau 16")


func test_apply_refuses_level_100_and_changes_nothing() -> void:
	var machop := _create(&"machop", 100)
	var experience := machop.experience
	var stats := machop.stats.duplicate()
	assert_null(RareCandy.apply(machop, _data))
	assert_eq(machop.level, 100)
	assert_eq(machop.experience, experience)
	assert_eq(machop.stats, stats)


func test_apply_refuses_a_fainted_pokemon_and_changes_nothing() -> void:
	var abra := _create(&"abra", 15)
	abra.hp = 0
	var experience := abra.experience
	assert_null(RareCandy.apply(abra, _data))
	assert_eq(abra.level, 15)
	assert_eq(abra.experience, experience)
	assert_eq(abra.hp, 0, "toujours K.O.")


func test_apply_without_data_or_pokemon() -> void:
	assert_null(RareCandy.apply(null, _data))
	var abra := _create(&"abra", 15)
	assert_null(RareCandy.apply(abra, null))
	assert_eq(abra.level, 15)


# --- evolution_after --------------------------------------------------------------------------

func test_abra_15_reaches_16_and_must_evolve_into_kadabra_with_confusion() -> void:
	var abra := _create(&"abra", 15)
	assert_eq(RareCandy.evolution_after(abra, _data), &"", "pas encore au niveau 15")
	RareCandy.apply(abra, _data)
	assert_eq(RareCandy.evolution_after(abra, _data), &"kadabra")
	# La présentation joue ensuite l'évolution (annulable) : Choc Mental proposé.
	assert_eq(Evolution.evolve(abra, &"kadabra", _data), [&"confusion"] as Array[StringName])
	assert_eq(abra.species_id, &"kadabra")
	assert_eq(abra.level, 16)


func test_no_evolution_below_the_level_or_without_a_level_rule() -> void:
	var abra := _create(&"abra", 10)
	RareCandy.apply(abra, _data)
	assert_eq(RareCandy.evolution_after(abra, _data), &"", "Abra 11")
	var kadabra := _create(&"kadabra", 41)
	RareCandy.apply(kadabra, _data)
	assert_eq(RareCandy.evolution_after(kadabra, _data), &"",
		"Kadabra : évolution par le Cordon d'échange, jamais par niveau")
	var machop := _create(&"machop", 27)
	RareCandy.apply(machop, _data)
	assert_eq(RareCandy.evolution_after(machop, _data), &"", "Machopeur absent au jalon 14")


func test_a_cancelled_evolution_comes_back_with_the_next_candy() -> void:
	var abra := _create(&"abra", 20)
	RareCandy.apply(abra, _data)
	assert_eq(RareCandy.evolution_after(abra, _data), &"kadabra", "annulée avant : reproposée")


func test_evolution_after_on_a_fainted_or_missing_pokemon() -> void:
	var abra := _create(&"abra", 16)
	abra.hp = 0
	assert_eq(RareCandy.evolution_after(abra, _data), &"")
	assert_eq(RareCandy.evolution_after(null, _data), &"")
