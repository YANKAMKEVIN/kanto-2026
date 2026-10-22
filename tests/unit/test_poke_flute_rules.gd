extends GutTest
## PokeFluteRules et FluteTarget (jalon 21 §2.2, T3) : dormeur voisin en exploration, Pokémon
## endormis des deux camps, réveil par cure_status sans autre effet.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const WAKE_11 := &"snorlax_route_11_wake"
const WAKE_16 := &"snorlax_route_16_wake"
const DONE_11 := &"snorlax_route_11_done"
const DONE_16 := &"snorlax_route_16_done"

var _data: PokemonData
var _flags: StoryFlags


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_flags = StoryFlags.new()


func _mon(species: StringName = &"rattata", level: int = 10) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


func _asleep(turns: int = 3) -> Pokemon:
	var pokemon := _mon()
	pokemon.status = StatusRules.SLEEP
	pokemon.status_turns = turns
	return pokemon


## Bloc 2 × 2 dont le coin haut-gauche est [param origin].
func _target(origin: Vector2i, cutscene: StringName, done: StringName) -> FluteTarget:
	var target := FluteTarget.new()
	for dy: int in 2:
		for dx: int in 2:
			target.cells.append(origin + Vector2i(dx, dy))
	target.unless_flags.assign([done])
	target.cutscene_id = cutscene
	return target


func _targets(list: Array) -> Array[FluteTarget]:
	var result: Array[FluteTarget] = []
	result.assign(list)
	return result


func _party(members: Array) -> Party:
	var party := Party.new()
	for pokemon: Pokemon in members:
		party.add(pokemon)
	return party


# --- field_target ---


func test_every_orthogonal_neighbour_of_a_two_by_two_block_wakes_it() -> void:
	# Ronflex de la Route 11 en (66..67, 14..15).
	var targets := _targets([_target(Vector2i(66, 14), WAKE_11, DONE_11)])
	var neighbours: Array[Vector2i] = [
		Vector2i(66, 13), Vector2i(67, 13),  # haut
		Vector2i(66, 16), Vector2i(67, 16),  # bas
		Vector2i(65, 14), Vector2i(65, 15),  # gauche
		Vector2i(68, 14), Vector2i(68, 15),  # droite
	]
	for cell: Vector2i in neighbours:
		assert_eq(PokeFluteRules.field_target(targets, cell, _flags), WAKE_11, str(cell))


func test_diagonals_far_cells_and_own_cells_do_not_count() -> void:
	var targets := _targets([_target(Vector2i(66, 14), WAKE_11, DONE_11)])
	var cells: Array[Vector2i] = [
		Vector2i(65, 13), Vector2i(68, 13), Vector2i(65, 16), Vector2i(68, 16),  # diagonales
		Vector2i(64, 14), Vector2i(69, 15), Vector2i(66, 12), Vector2i(67, 17),  # à 2 cases
		Vector2i(66, 14), Vector2i(67, 15),  # sur le bloc
		Vector2i(0, 0),
	]
	for cell: Vector2i in cells:
		assert_eq(PokeFluteRules.field_target(targets, cell, _flags), &"", str(cell))


func test_a_block_hidden_by_its_flags_is_no_target() -> void:
	var targets := _targets([_target(Vector2i(66, 14), WAKE_11, DONE_11)])
	_flags.set_flag(DONE_11)
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(65, 14), _flags), &"")
	_flags.set_flag(DONE_11, false)
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(65, 14), _flags), WAKE_11)


func test_two_targets_give_the_right_scene() -> void:
	# Ronflex de la Route 16 en (24..25, 22..23), vu depuis (26, 22).
	var targets := _targets([
		_target(Vector2i(66, 14), WAKE_11, DONE_11),
		_target(Vector2i(24, 22), WAKE_16, DONE_16),
	])
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(26, 22), _flags), WAKE_16)
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(68, 15), _flags), WAKE_11)
	_flags.set_flag(DONE_11)
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(68, 15), _flags), &"",
		"l'un parti, l'autre reste")
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(26, 22), _flags), WAKE_16)


func test_no_target_or_null_flags() -> void:
	assert_eq(PokeFluteRules.field_target(_targets([]), Vector2i(1, 1), _flags), &"")
	var targets := _targets([_target(Vector2i(66, 14), WAKE_11, DONE_11)])
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(65, 14), null), WAKE_11,
		"sans drapeaux : le dormeur est là")


# --- sleepers ---


func test_sleepers_lists_player_then_foe() -> void:
	var mine := _asleep()
	var theirs_1 := _asleep()
	var theirs_2 := _asleep()
	var awake := _mon()
	var player := _party([awake, mine])
	var foe := _party([theirs_1, _mon(), theirs_2])
	assert_eq(PokeFluteRules.sleepers(player, foe), [mine, theirs_1, theirs_2] as Array[Pokemon])


func test_sleepers_skip_fainted_and_other_statuses() -> void:
	var fainted := _asleep()
	fainted.take_damage(9999)
	var poisoned := _mon()
	poisoned.status = StatusRules.POISON
	var frozen := _mon()
	frozen.status = StatusRules.FREEZE
	var paralysed := _mon()
	paralysed.status = StatusRules.PARALYSIS
	var sleeping := _asleep()
	var player := _party([fainted, poisoned, frozen])
	var foe := _party([paralysed, sleeping])
	assert_eq(PokeFluteRules.sleepers(player, foe), [sleeping] as Array[Pokemon])


func test_sleepers_with_nobody_asleep_or_null_parties() -> void:
	assert_eq(PokeFluteRules.sleepers(_party([_mon()]), _party([_mon()])).size(), 0)
	assert_eq(PokeFluteRules.sleepers(null, null).size(), 0)
	var sleeping := _asleep()
	assert_eq(PokeFluteRules.sleepers(null, _party([sleeping])), [sleeping] as Array[Pokemon])


# --- wake_all ---


func test_wake_all_clears_status_and_counter_only() -> void:
	var sleeping := _asleep(3)
	sleeping.take_damage(5)
	var hp_before := sleeping.hp
	var pp_before := sleeping.moves[0].pp
	var battler := Battler.new(sleeping, [&"normal"] as Array[StringName])
	battler.confusion_turns = 2
	var woken := PokeFluteRules.wake_all([sleeping] as Array[Pokemon])
	assert_eq(woken, [sleeping] as Array[Pokemon])
	assert_eq(sleeping.status, StatusRules.NONE)
	assert_eq(sleeping.status_turns, 0)
	assert_eq(sleeping.hp, hp_before, "PV inchangés")
	assert_eq(sleeping.moves[0].pp, pp_before, "PP inchangés")
	assert_eq(battler.confusion_turns, 2, "confusion inchangée")


func test_wake_all_leaves_other_statuses_alone() -> void:
	var poisoned := _mon()
	poisoned.status = StatusRules.POISON
	var burnt := _mon()
	burnt.status = StatusRules.BURN
	var sleeping := _asleep()
	var woken := PokeFluteRules.wake_all([poisoned, sleeping, burnt] as Array[Pokemon])
	assert_eq(woken, [sleeping] as Array[Pokemon])
	assert_eq(poisoned.status, StatusRules.POISON)
	assert_eq(burnt.status, StatusRules.BURN)


func test_wake_all_wakes_a_rest_sleeper() -> void:
	var rester := _mon()
	rester.take_damage(3)
	assert_true(StatusRules.apply_rest(rester))
	assert_eq(rester.status_turns, StatusRules.REST_SLEEP_TURNS)
	var woken := PokeFluteRules.wake_all([rester] as Array[Pokemon])
	assert_eq(woken, [rester] as Array[Pokemon])
	assert_eq(rester.status, StatusRules.NONE)
	assert_eq(rester.status_turns, 0)
	assert_eq(rester.hp, rester.max_hp(), "les PV rendus par Repos restent")


func test_wake_all_on_empty_list_or_awake_pokemon_does_nothing() -> void:
	assert_eq(PokeFluteRules.wake_all([] as Array[Pokemon]).size(), 0)
	var awake := _mon()
	assert_eq(PokeFluteRules.wake_all([awake] as Array[Pokemon]).size(), 0)
	assert_eq(awake.status, StatusRules.NONE)


func test_wake_all_after_sleepers_wakes_both_camps() -> void:
	var mine := _asleep(1)
	var theirs := _asleep(3)
	var player := _party([mine])
	var foe := _party([theirs])
	var woken := PokeFluteRules.wake_all(PokeFluteRules.sleepers(player, foe))
	assert_eq(woken.size(), 2)
	assert_eq(PokeFluteRules.sleepers(player, foe).size(), 0)
