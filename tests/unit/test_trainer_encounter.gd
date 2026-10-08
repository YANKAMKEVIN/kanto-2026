extends GutTest
## TrainerEncounter (jalon 9, jalon-09.md §2.4.3) : étapes de la séquence d'un Dresseur
## repéré (« ! », pause, approche, regards, répliques, combat, suite selon l'issue) et du défi
## à la parole (sans « ! » ni approche), conditions `beaten_<id>`.

const K := CutsceneStep.Kind


func _theo() -> NpcSpec:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry({
		"cell": [5, 2], "facing": "down", "sprite": "scout",
		"dialogue": "forest_scout_theo_after",
		"trainer": {"id": "forest_scout_theo", "sight": 4, "before": "forest_scout_theo_before"},
	}, errors)
	assert_eq(errors.size(), 0, str(errors))
	spec.id = &"scout_theo"
	return spec


func _kinds(variant: CutsceneVariant) -> Array[int]:
	var kinds: Array[int] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	return kinds


func test_cutscene_id() -> void:
	assert_eq(TrainerEncounter.cutscene_id(&"forest_scout_theo"), &"trainer_forest_scout_theo")


func test_spotted_from_afar_exclamation_pause_approach_then_battle() -> void:
	var variant := TrainerEncounter.build(&"scout_theo", _theo(), 4)
	assert_not_null(variant)
	assert_eq(_kinds(variant), [K.EMOTE, K.WAIT, K.MOVE, K.FACE, K.FACE, K.DIALOGUE, K.BATTLE,
		K.DIALOGUE, K.WAKE_UP] as Array[int])
	assert_true(variant.if_flags.is_empty() and variant.unless_flags.is_empty(),
		"la variante ne dépend d'aucun drapeau (le watcher choisit)")
	var steps := variant.steps
	assert_eq(steps[0].actor, &"scout_theo")
	assert_eq(steps[0].emote, &"exclamation")
	assert_eq(steps[1].seconds, TrainerEncounter.SPOTTED_PAUSE)
	assert_eq(steps[1].seconds, 0.3, "défaut du plan")
	assert_eq(steps[2].actor, &"scout_theo")
	assert_eq(steps[2].path, [Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN] as Array[Vector2i],
		"jusqu'à la case voisine du joueur")
	assert_false(steps[2].run, "il marche")
	assert_false(steps[2].background)
	assert_eq([steps[3].actor, steps[3].target], [&"player", &"scout_theo"])
	assert_eq([steps[4].actor, steps[4].target], [&"scout_theo", &"player"])
	assert_eq(steps[5].dialogue_id, &"forest_scout_theo_before")
	assert_true(steps[5].if_flags.is_empty() and steps[5].unless_flags.is_empty())
	assert_eq(steps[6].trainer_id, &"forest_scout_theo")
	assert_eq(steps[6].win_flags, [&"beaten_forest_scout_theo"] as Array[StringName])
	assert_true(steps[6].lose_flags.is_empty(), "une défaite ne laisse aucune trace")
	assert_eq(steps[7].dialogue_id, &"forest_scout_theo_after", "réplique « après » tout de suite")
	assert_eq(steps[7].if_flags, [&"beaten_forest_scout_theo"] as Array[StringName])
	assert_eq(steps[8].unless_flags, [&"beaten_forest_scout_theo"] as Array[StringName],
		"réveil au point de repos seulement si le joueur a perdu")


func test_spotted_next_to_him_no_approach() -> void:
	var variant := TrainerEncounter.build(&"scout_theo", _theo(), 1)
	assert_eq(_kinds(variant), [K.EMOTE, K.WAIT, K.FACE, K.FACE, K.DIALOGUE, K.BATTLE,
		K.DIALOGUE, K.WAKE_UP] as Array[int])


func test_talked_to_no_exclamation_no_approach() -> void:
	var variant := TrainerEncounter.build(&"scout_theo", _theo(), TrainerEncounter.TALKED_TO)
	assert_eq(_kinds(variant), [K.FACE, K.FACE, K.DIALOGUE, K.BATTLE, K.DIALOGUE, K.WAKE_UP]
		as Array[int])


func test_conditions_follow_the_outcome() -> void:
	var variant := TrainerEncounter.build(&"scout_theo", _theo(), 3)
	var won := StoryFlags.new()
	won.set_flag(&"beaten_forest_scout_theo")
	var lost := StoryFlags.new()
	var after := variant.steps[variant.steps.size() - 2]
	var wake_up := variant.steps.back() as CutsceneStep
	assert_true(after.applies(won))
	assert_false(after.applies(lost))
	assert_false(wake_up.applies(won))
	assert_true(wake_up.applies(lost))


func test_not_a_trainer() -> void:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry({"cell": [1, 1], "sprite": "kid", "dialogue": "x"}, errors)
	assert_null(TrainerEncounter.build(&"kid", spec, 2))
	assert_push_error("n'est pas un Dresseur")
	assert_null(TrainerEncounter.build(&"kid", null, 2))
	assert_push_error_count(2)


## Jalon 10 (jalon-10.md §2.5) : avec une réplique « vaincu » (Campeur Liam), c'est elle qui est
## dite juste après la victoire, aux mêmes conditions ; la réplique « après » reste celle du PNJ.
## Sans elle, la séquence du jalon 9 ne change pas.
func test_defeated_line_replaces_the_after_line_once() -> void:
	var spec := _theo()
	spec.defeated_dialogue = &"forest_scout_theo_defeated"
	for distance: int in [3, TrainerEncounter.TALKED_TO]:
		var variant := TrainerEncounter.build(&"scout_theo", spec, distance)
		var after := variant.steps[variant.steps.size() - 2]
		assert_eq(after.kind, K.DIALOGUE)
		assert_eq(after.dialogue_id, &"forest_scout_theo_defeated", str(distance))
		assert_eq(after.if_flags, [&"beaten_forest_scout_theo"] as Array[StringName])
		assert_eq((variant.steps.back() as CutsceneStep).kind, K.WAKE_UP)
	assert_eq(spec.dialogue, &"forest_scout_theo_after", "réplique permanente inchangée")
	var plain := TrainerEncounter.build(&"scout_theo", _theo(), 3)
	assert_eq(plain.steps[plain.steps.size() - 2].dialogue_id, &"forest_scout_theo_after",
		"sans « defeated » : comportement du jalon 9")
