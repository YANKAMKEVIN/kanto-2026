extends GutTest
## Jalon 32, N-18 (validé par Kevin le 2026-10-25, « Un Ronflex après la Ligue ») : règle de
## [StaticRespawn], données (scène, dialogue) et Ronflex du belvédère de la Route 10 [D].

const MAP_PATH := "res://game/world/maps/route_10.tscn"
const CELLS: Array[Vector2i] = [Vector2i(21, 19), Vector2i(22, 19), Vector2i(21, 20),
	Vector2i(22, 20)]

var _map: GameMap


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)


func after_all() -> void:
	_map.free()


func _both_knocked_out() -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in StaticRespawn.ROUTE_SNORLAX_DONE:
		flags.set_flag(flag)
	return flags


func _league(flags: StoryFlags) -> Array[StringName]:
	return StaticRespawn.on_league_won([] as Array[StaticEncounter], flags)


func test_both_route_snorlax_knocked_out_brings_a_third_after_the_league() -> void:
	var flags := _both_knocked_out()
	assert_true(StaticRespawn.route_snorlax_lost(flags))
	assert_eq(_league(flags), [StaticRespawn.SNORLAX_EXTRA_PRESENT] as Array[StringName])
	assert_true(flags.has_flag(StaticRespawn.SNORLAX_EXTRA_PRESENT))


func test_no_third_snorlax_if_one_was_caught_or_is_still_asleep() -> void:
	var caught := _both_knocked_out()
	caught.set_flag(&"snorlax_route_16_caught")
	assert_eq(_league(caught), [] as Array[StringName])
	var asleep := StoryFlags.new()
	asleep.set_flag(&"snorlax_route_12_done")
	assert_eq(_league(asleep), [] as Array[StringName], "le Ronflex de la Route 16 dort encore")
	assert_false(asleep.has_flag(StaticRespawn.SNORLAX_EXTRA_PRESENT))


func test_the_third_snorlax_comes_back_after_each_league_until_caught() -> void:
	var flags := _both_knocked_out()
	_league(flags)
	flags.set_flag(StaticRespawn.SNORLAX_EXTRA_DONE)  # mis K.O. à son tour
	assert_eq(_league(flags), [StaticRespawn.SNORLAX_EXTRA_DONE] as Array[StringName])
	assert_false(flags.has_flag(StaticRespawn.SNORLAX_EXTRA_DONE), "revenu")
	flags.set_flag(StaticRespawn.SNORLAX_EXTRA_DONE)
	flags.set_flag(StaticRespawn.SNORLAX_EXTRA_CAUGHT)
	assert_eq(_league(flags), [] as Array[StringName], "capturé : jamais plus")
	assert_true(flags.has_flag(StaticRespawn.SNORLAX_EXTRA_DONE))


func test_route_snorlax_never_come_back() -> void:
	var flags := _both_knocked_out()
	_league(flags)
	for flag: StringName in StaticRespawn.ROUTE_SNORLAX_DONE:
		assert_true(flags.has_flag(flag), "%s reste posé : la route reste ouverte" % flag)


func test_wake_scene_reuses_the_j21_lines() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), str(library.get_errors()))
	var scene := library.get_cutscene(&"snorlax_post_league_wake")
	assert_not_null(scene)
	var variant := scene.variants[0]
	assert_eq(variant.if_flags, [StaticRespawn.SNORLAX_EXTRA_PRESENT] as Array[StringName])
	assert_eq(variant.unless_flags, [StaticRespawn.SNORLAX_EXTRA_DONE] as Array[StringName])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), str(dialogues.get_errors()))
	for id: StringName in [&"snorlax_post_league", &"snorlax_flute_played", &"snorlax_wakes",
			&"snorlax_calms", &"snorlax_sleeps"]:
		assert_true(dialogues.has_dialogue(id), String(id))


func test_route_10_snorlax_is_hidden_until_the_flag_then_blocks_its_cells() -> void:
	var gate := _map.get_node(^"Entities/Ronflex") as FlagGate
	assert_not_null(gate)
	assert_eq(gate.blocking_cells, CELLS)
	assert_false(gate.is_open(StoryFlags.new()), "invisible avant la Ligue")
	var flags := StoryFlags.new()
	flags.set_flag(StaticRespawn.SNORLAX_EXTRA_PRESENT)
	assert_true(gate.is_open(flags))
	flags.set_flag(StaticRespawn.SNORLAX_EXTRA_DONE)
	assert_false(gate.is_open(flags), "parti après le combat")
	assert_not_null(_map.get_scene_prop(&"Snorlax"), "acteur des étapes react / emote")


func test_route_10_snorlax_examine_and_flute_follow_the_flags() -> void:
	var empty := StoryFlags.new()
	var present := StoryFlags.new()
	present.set_flag(StaticRespawn.SNORLAX_EXTRA_PRESENT)
	var found := 0
	for interaction: Interaction in _map.get_interactions().get_all():
		if interaction.dialogue_id != &"snorlax_post_league":
			continue
		found += 1
		assert_true(CELLS.has(interaction.cell), str(interaction.cell))
		assert_false(interaction.is_available(empty), "aucun EXAMINER avant la Ligue")
		assert_true(interaction.is_available(present))
	assert_eq(found, 4)
	var targets := _map.flute_targets().filter(func(t: FluteTarget) -> bool:
		return t.cutscene_id == &"snorlax_post_league_wake")
	assert_eq(targets.size(), 1)
	var target: FluteTarget = targets[0]
	assert_false(target.is_present(empty))
	assert_true(target.is_present(present))
	assert_true(target.touches(Vector2i(20, 19)), "Flûte depuis le belvédère")
