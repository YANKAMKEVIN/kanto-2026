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


## Scène complète d'une rencontre fixe et son Pokémon de carte (anciennes données de QA
## `qa_s2_legendary` de la Route 1, retirées en S2Z avec leurs départs) : la scène se charge avec
## de vraies espèces, et le Pokémon de la carte n'est présent qu'avec son drapeau d'apparition et
## tant que la rencontre n'est pas consommée (`unless` sur le drapeau `done`).
func test_a_full_static_scene_and_its_map_pokemon() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"essai_legendaire": {"variants": [{
		"unless": ["essai_legendaire_done"],
		"steps": [
			{"dialogue": "essai_legendaire_cry"},
			{"wild_battle": "clefairy", "level": 25, "intro": "legendary",
				"actor": "essai_legendaire",
				"static": {"done": "essai_legendaire_done", "caught": "essai_legendaire_caught"}},
			{"dialogue": "essai_legendaire_after_ko", "if": ["essai_legendaire_done"],
				"unless": ["essai_legendaire_caught"]},
			{"dialogue": "essai_legendaire_after_catch", "if": ["essai_legendaire_caught"]},
		]}]}}, "test"), str(library.get_errors()))
	var data := PokemonData.new()
	assert_true(data.load_dir())
	assert_true(library.check_species(data), str(library.get_errors()))
	var battle := library.get_cutscene(&"essai_legendaire").variants[0].steps[1]
	assert_eq(battle.kind, CutsceneStep.Kind.WILD_BATTLE)
	assert_eq(battle.intro, CutsceneStep.INTRO_LEGENDARY)
	assert_eq(battle.actor, &"essai_legendaire")
	assert_eq(battle.static_encounter.done_flag, &"essai_legendaire_done")
	assert_eq(battle.static_encounter.caught_flag, &"essai_legendaire_caught")
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({"essai_legendaire": {"cell": [23, 41], "facing": "down",
		"sprite": "pokemon/clefairy", "dialogue": "essai_legendaire", "verb": "observe",
		"turn_to_player": false, "if": ["essai_legendaire_shown"],
		"unless": ["essai_legendaire_done"]}}), str(roster.get_errors()))
	var present := func(flags: StoryFlags) -> bool:
		return roster.get_present(flags).any(func(s: NpcSpec) -> bool:
			return s.id == &"essai_legendaire")
	assert_false(present.call(null), "absent d'une nouvelle partie")
	var flags := StoryFlags.new()
	flags.set_flag(&"essai_legendaire_shown")
	assert_true(present.call(flags))
	flags.set_flag(&"essai_legendaire_done")
	assert_false(present.call(flags), "caché quand la rencontre est consommée")
