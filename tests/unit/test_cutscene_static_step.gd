extends GutTest
## Étape « wild_battle » de la passe systèmes 2 (T30) dans [CutsceneLibrary] et [CutsceneStep] :
## clés « catch », « static », « actor », « intro » ; drapeaux de l'issue ; drapeaux levés.

const O := Battle.Outcome
const FULL := {"wild_battle": "articuno", "level": 50, "intro": "legendary",
	"actor": "articuno", "static": {"done": "articuno_done", "caught": "articuno_caught"},
	"catch": ["articuno_extra"], "win": ["articuno_t21"]}


func _load(step: Dictionary) -> CutsceneLibrary:
	var library := CutsceneLibrary.new()
	library.add_from_dict({"scene": {"steps": [step]}}, "test")
	return library


func _step(library: CutsceneLibrary) -> CutsceneStep:
	return library.get_cutscene(&"scene").variants[0].steps[0]


func test_full_step_is_parsed_into_a_static_encounter() -> void:
	var library := _load(FULL)
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_eq(step.intro, CutsceneStep.INTRO_LEGENDARY)
	assert_eq(step.actor, &"articuno")
	assert_eq(step.catch_flags, [&"articuno_extra"] as Array[StringName])
	var fixed := step.static_encounter
	assert_not_null(fixed)
	assert_eq(fixed.id, &"articuno", "identifiant = acteur")
	assert_eq(fixed.species, &"articuno")
	assert_eq(fixed.level, 50)
	assert_eq(fixed.done_flag, &"articuno_done")
	assert_eq(fixed.caught_flag, &"articuno_caught")


func test_outcome_flags_follow_the_articuno_policy_plus_written_flags() -> void:
	var step := _step(_load(FULL))
	assert_eq(step.outcome_flags(O.CAUGHT),
		[&"articuno_done", &"articuno_caught", &"articuno_extra"] as Array[StringName])
	assert_eq(step.outcome_flags(O.WIN),
		[&"articuno_done", &"articuno_t21"] as Array[StringName])
	for outcome: int in [O.FLED, O.FOE_FLED, O.LOSS, O.NONE]:
		assert_eq(step.outcome_flags(outcome), [] as Array[StringName], str(outcome))


func test_without_static_catch_flags_alone() -> void:
	var library := _load({"wild_battle": "pidgey", "level": 5, "catch": ["c"], "win": ["w"]})
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_null(step.static_encounter)
	assert_eq(step.intro, &"", "entrée ordinaire par défaut")
	assert_eq(step.outcome_flags(O.CAUGHT), [&"c"] as Array[StringName])
	assert_eq(step.outcome_flags(O.WIN), [&"w"] as Array[StringName])


func test_static_without_actor_takes_the_species_as_id() -> void:
	var step := _step(_load({"wild_battle": "pidgey", "level": 5,
		"static": {"done": "d", "caught": "c"}}))
	assert_eq(step.static_encounter.id, &"pidgey")
	assert_eq(step.actor, &"")


func test_set_flags_include_static_and_catch_flags() -> void:
	var flags := _load(FULL).get_set_flags()
	for flag: StringName in [&"articuno_done", &"articuno_caught", &"articuno_extra",
			&"articuno_t21"]:
		assert_has(flags, flag)


func test_copy_keeps_the_new_fields() -> void:
	var step := _step(_load(FULL))
	var other := step.copy()
	assert_same(other.static_encounter, step.static_encounter)
	assert_eq(other.intro, step.intro)
	assert_eq(other.catch_flags, step.catch_flags)
	other.catch_flags.append(&"x")
	assert_eq(step.catch_flags.size(), 1, "copie indépendante")


func test_invalid_entries_are_rejected() -> void:
	var bad: Array[Dictionary] = [
		{"wild_battle": "pidgey", "level": 5, "actor": "legend"},
		{"wild_battle": "pidgey", "level": 5, "static": {"done": "d"}},
		{"wild_battle": "pidgey", "level": 5, "static": {"done": "d", "caught": "d"}},
		{"wild_battle": "pidgey", "level": 5, "static": {"done": "d", "caught": "c", "x": 1}},
		{"wild_battle": "pidgey", "level": 5, "static": "d"},
		{"wild_battle": "pidgey", "level": 5, "static": {"done": "d", "caught": "c"},
			"actor": "player"},
		{"wild_battle": "pidgey", "level": 5, "intro": "slow"},
		{"wild_battle": "pidgey", "level": 5, "catch": []},
		{"battle": "rival", "catch": ["c"]},
	]
	for entry: Dictionary in bad:
		var library := _load(entry)
		assert_false(library.has_cutscene(&"scene"), "refusée : %s" % entry)
		assert_eq(library.get_errors().size(), 1, "une erreur : %s" % [library.get_errors()])
	assert_push_error_count(bad.size(), "une erreur par entrée")
