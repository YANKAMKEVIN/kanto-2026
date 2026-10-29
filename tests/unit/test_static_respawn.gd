extends GutTest
## StaticRespawn (jalon 32, N-17 « Réapparaît après la Ligue ») : un Pokémon unique mis K.O.
## revient à chaque victoire à la Ligue ; capturé, jamais.

const O := Battle.Outcome

var _bird: StaticEncounter
var _mewtwo: StaticEncounter


func before_each() -> void:
	_bird = StaticEncounter.new(&"articuno", &"articuno", 50, &"articuno_done", &"articuno_caught")
	_mewtwo = StaticEncounter.new(&"mewtwo", &"mewtwo", 70, &"mewtwo_encounter_resolved",
		&"mewtwo_caught")


func _apply(encounter: StaticEncounter, outcome: int, flags: StoryFlags) -> void:
	for flag: StringName in encounter.flags_for(outcome):
		flags.set_flag(flag)


func test_a_knocked_out_legendary_comes_back_after_the_league() -> void:
	var flags := StoryFlags.new()
	_apply(_bird, O.WIN, flags)
	assert_false(_bird.is_present(flags), "K.O. : disparu")
	var cleared := StaticRespawn.on_league_won([_bird, _mewtwo] as Array[StaticEncounter], flags)
	assert_eq(cleared, [&"articuno_done"] as Array[StringName])
	assert_true(_bird.is_present(flags), "revenu après la Ligue")
	assert_false(flags.has_flag(&"articuno_caught"))


func test_a_caught_legendary_never_comes_back() -> void:
	var flags := StoryFlags.new()
	_apply(_bird, O.CAUGHT, flags)
	assert_eq(StaticRespawn.on_league_won([_bird] as Array[StaticEncounter], flags),
		[] as Array[StringName])
	assert_false(_bird.is_present(flags))


func test_untouched_or_fled_encounters_are_left_alone() -> void:
	var flags := StoryFlags.new()
	_apply(_mewtwo, O.FLED, flags)
	assert_eq(StaticRespawn.on_league_won([_bird, _mewtwo] as Array[StaticEncounter], flags),
		[] as Array[StringName])
	assert_eq(flags.size(), 0)


func test_every_league_win_brings_it_back_again() -> void:
	var flags := StoryFlags.new()
	for round: int in 3:
		_apply(_mewtwo, O.WIN, flags)
		assert_eq(StaticRespawn.knocked_out([_mewtwo] as Array[StaticEncounter], flags).size(), 1)
		StaticRespawn.on_league_won([_mewtwo] as Array[StaticEncounter], flags)
		assert_true(_mewtwo.is_present(flags), "victoire %d" % round)


func test_library_lists_the_static_encounters_of_the_real_data() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var ids: Array[StringName] = []
	for encounter: StaticEncounter in library.get_static_encounters():
		ids.append(encounter.id)
	assert_true(ids.has(&"articuno"), str(ids))
	assert_false(ids.has(&"snorlax"), "Ronflex hors périmètre (pas de clé « static »)")
	assert_false(ids.has(&"marowak"), "Ossatueur spectre non capturable")


func test_knocked_out_articuno_scene_plays_again_after_the_league() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var flags := StoryFlags.new()
	flags.set_flag(&"articuno_done")
	var cutscene := library.get_cutscene(&"articuno")
	var gate := cutscene.variants[0].unless_flags
	assert_true(gate.has(&"articuno_done"), str(gate))
	assert_false(flags.has_none(gate), "K.O. : la scène ne joue plus")
	StaticRespawn.on_league_won(library.get_static_encounters(), flags)
	assert_true(flags.has_none(gate), "après la Ligue : la scène rejoue")


## J32 (T8, N-17 et 32J) : Mew mis K.O. ou en fuite revient au camion après la Ligue ; capturé,
## jamais. La Ligue ne touche ni au Diplôme ni aux seconds exemplaires d'après la Ligue.
func test_mew_comes_back_after_the_league_unless_caught() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var flags := StoryFlags.new()
	for flag: StringName in [&"mew_appeared", &"mew_resolved", &"diploma_received",
			&"oak_post_league_gifts_done", &"eevee_received_2", &"j32_second_fossil_given"]:
		flags.set_flag(flag)
	var gate := library.get_cutscene(&"mew").variants[0].unless_flags
	assert_false(flags.has_none(gate), "K.O. : plus de Mew")
	StaticRespawn.on_league_won(library.get_static_encounters(), flags)
	assert_true(flags.has_none(gate), "après la Ligue : Mew revient")
	for flag: StringName in [&"diploma_received", &"oak_post_league_gifts_done",
			&"eevee_received_2", &"j32_second_fossil_given"]:
		assert_true(flags.has_flag(flag), "%s gardé" % flag)
	flags.set_flag(&"mew_resolved")
	flags.set_flag(&"mew_caught")
	StaticRespawn.on_league_won(library.get_static_encounters(), flags)
	assert_false(flags.has_none(gate), "capturé : jamais de retour")
