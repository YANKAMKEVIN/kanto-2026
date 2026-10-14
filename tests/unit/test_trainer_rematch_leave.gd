extends GutTest
## Jalon 12 (jalon-12.md §2.11, T17) : bloc « trainer » étendu — réplique de reprise
## (« rematch », drapeau `lost_<id>`) et départ (« leave » : marche puis fondu), lus par
## [NpcRoster] et construits par [TrainerEncounter.build]. Compatibilité ascendante : sans ces
## clés, la séquence est celle des jalons 9 et 10 (tous les Dresseurs des données réelles).

const K := CutsceneStep.Kind
const NPC_DIR := "res://data/npcs/"
const BEATEN := &"beaten_mt_rocket_test"
const LOST := &"lost_mt_rocket_test"


func _entry(trainer: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var block := {"id": "mt_rocket_test", "sight": 4, "before": "rocket_before"}
	block.merge(trainer, true)
	var entry := {
		"cell": [10, 6], "facing": "left", "sprite": "scout", "dialogue": "rocket_after",
		"trainer": block,
	}
	entry.merge(extra, true)
	return entry


func _parse(entry: Dictionary) -> NpcSpec:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry(entry, errors)
	assert_eq(errors.size(), 0, str(errors))
	return spec


func _errors(entry: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	NpcRoster.parse_entry(entry, errors)
	return errors


func _kinds(variant: CutsceneVariant) -> Array[int]:
	var kinds: Array[int] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	return kinds


# --- Règles et lecture ------------------------------------------------------------------------

func test_lost_flag() -> void:
	assert_eq(TrainerRules.lost_flag(&"mt_moon_rocket_1"), &"lost_mt_moon_rocket_1")
	assert_eq(TrainerRules.LOST_PREFIX, "lost_")


func test_new_keys_at_the_end_of_trainer_keys() -> void:
	assert_eq(NpcRoster.TRAINER_KEYS.slice(0, 4),
		["id", "sight", "before", "defeated"] as Array[String], "clés du J9–J10 inchangées")
	assert_eq(NpcRoster.TRAINER_KEYS.slice(4), ["rematch", "leave"] as Array[String])


func test_without_new_keys_defaults() -> void:
	var spec := _parse(_entry({}))
	assert_eq(spec.rematch_dialogue, &"")
	assert_false(spec.has_rematch())
	assert_false(spec.leaves)
	assert_true(spec.leave_cells.is_empty())


func test_rematch_and_leave_are_read() -> void:
	var spec := _parse(_entry({"rematch": "rocket_rematch", "leave": [[0, 0], [-3, 1]]},
		{"unless": [String(BEATEN)]}))
	assert_eq(spec.rematch_dialogue, &"rocket_rematch")
	assert_true(spec.has_rematch())
	assert_true(spec.leaves)
	assert_eq(spec.leave_cells, [Vector2i(0, 0), Vector2i(-3, 1)] as Array[Vector2i])
	assert_eq(spec.get_leave_path_cells(), [Vector2i(10, 6), Vector2i(7, 7)] as Array[Vector2i],
		"cases relatives à sa case de départ")


func test_empty_leave_means_fade_on_the_spot() -> void:
	var spec := _parse(_entry({"leave": []}, {"unless": [String(BEATEN)]}))
	assert_true(spec.leaves)
	assert_true(spec.leave_cells.is_empty())


func test_leave_needs_unless_beaten() -> void:
	var errors := _errors(_entry({"leave": []}))
	assert_eq(errors.size(), 1, str(errors))
	assert_string_contains(errors[0], "beaten_mt_rocket_test")
	errors = _errors(_entry({"leave": []}, {"unless": ["other_flag"]}))
	assert_eq(errors.size(), 1, str(errors))


func test_invalid_rematch_and_leave_are_rejected() -> void:
	var unless := {"unless": [String(BEATEN)]}
	for trainer: Dictionary in [
		{"rematch": ""}, {"rematch": 3}, {"leave": "left"}, {"leave": [[1]]},
		{"leave": [[0.5, 0]]}, {"leave": [[9, 0]]}, {"leave": [[0, -9]]},
		{"leave": [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]},
		{"unknown": true},
	]:
		assert_gt(_errors(_entry(trainer, unless)).size(), 0, "refusé : %s" % trainer)
	var near_edge := _entry({"leave": [[-3, 0]]}, {"unless": [String(BEATEN)], "cell": [2, 6]})
	var errors := _errors(near_edge)
	assert_eq(errors.size(), 1, "case hors de la carte : %s" % str(errors))


func test_is_offset() -> void:
	assert_true(NpcRoster.is_offset([0, 0], 8))
	assert_true(NpcRoster.is_offset([-8, 8], 8))
	assert_false(NpcRoster.is_offset([-9, 0], 8))
	assert_false(NpcRoster.is_offset([1.5, 0], 8))
	assert_false(NpcRoster.is_offset([1, 2, 3], 8))
	assert_false(NpcRoster.is_offset("1,2", 8))


# --- Séquence ---------------------------------------------------------------------------------

func test_rematch_splits_the_before_line_and_marks_the_defeat() -> void:
	var spec := _parse(_entry({"rematch": "rocket_rematch"}))
	var variant := TrainerEncounter.build(&"rocket", spec, 3)
	assert_eq(_kinds(variant), [K.EMOTE, K.WAIT, K.MOVE, K.FACE, K.FACE, K.DIALOGUE,
		K.DIALOGUE, K.BATTLE, K.DIALOGUE, K.WAKE_UP] as Array[int])
	var before: CutsceneStep = variant.steps[5]
	var rematch: CutsceneStep = variant.steps[6]
	var battle: CutsceneStep = variant.steps[7]
	assert_eq(before.dialogue_id, &"rocket_before")
	assert_eq(before.unless_flags, [LOST] as Array[StringName])
	assert_true(before.if_flags.is_empty())
	assert_eq(rematch.dialogue_id, &"rocket_rematch")
	assert_eq(rematch.if_flags, [LOST] as Array[StringName])
	assert_eq(battle.win_flags, [BEATEN] as Array[StringName])
	assert_eq(battle.lose_flags, [LOST] as Array[StringName], "la défaite est mémorisée")
	# Conditions évaluées au moment de jouer.
	var first := StoryFlags.new()
	assert_true(before.applies(first) and not rematch.applies(first), "1re fois : « avant »")
	var again := StoryFlags.new()
	again.set_flag(LOST)
	assert_true(rematch.applies(again) and not before.applies(again), "après une défaite")


func test_leave_walks_to_each_cell_then_fades_only_when_beaten() -> void:
	var spec := _parse(_entry({"defeated": "rocket_defeated", "leave": [[0, 0], [2, 0]]},
		{"unless": [String(BEATEN)]}))
	var variant := TrainerEncounter.build(&"rocket", spec, TrainerEncounter.TALKED_TO)
	assert_eq(_kinds(variant), [K.FACE, K.FACE, K.DIALOGUE, K.BATTLE, K.DIALOGUE, K.MOVE,
		K.MOVE, K.DESPAWN, K.WAKE_UP] as Array[int])
	var steps := variant.steps
	assert_eq(steps[4].dialogue_id, &"rocket_defeated", "réplique « vaincu » d'abord")
	for i: int in [5, 6, 7]:
		assert_eq(steps[i].actor, &"rocket")
		assert_eq(steps[i].if_flags, [BEATEN] as Array[StringName], "seulement s'il est battu")
		assert_true(steps[i].unless_flags.is_empty())
	assert_eq(steps[5].cell, Vector2i(10, 6), "retour à son poste (chemin calculé)")
	assert_true(steps[5].path.is_empty() and steps[5].near.is_empty())
	assert_eq(steps[6].cell, Vector2i(12, 6))
	assert_true(steps[3].lose_flags.is_empty(), "sans « rematch » : défaite sans trace")
	assert_eq(steps[8].unless_flags, [BEATEN] as Array[StringName], "réveil si le joueur perd")


func test_empty_leave_fades_on_the_spot() -> void:
	var spec := _parse(_entry({"leave": []}, {"unless": [String(BEATEN)]}))
	var variant := TrainerEncounter.build(&"rocket", spec, 1)
	assert_eq(_kinds(variant), [K.EMOTE, K.WAIT, K.FACE, K.FACE, K.DIALOGUE, K.BATTLE,
		K.DIALOGUE, K.DESPAWN, K.WAKE_UP] as Array[int])


func test_rematch_and_leave_together() -> void:
	var spec := _parse(_entry({"rematch": "rocket_rematch", "defeated": "rocket_defeated",
		"leave": [[1, 0]]}, {"unless": [String(BEATEN)]}))
	var variant := TrainerEncounter.build(&"rocket", spec, 2)
	assert_eq(_kinds(variant), [K.EMOTE, K.WAIT, K.MOVE, K.FACE, K.FACE, K.DIALOGUE,
		K.DIALOGUE, K.BATTLE, K.DIALOGUE, K.MOVE, K.DESPAWN, K.WAKE_UP] as Array[int])


# --- Compatibilité ascendante -----------------------------------------------------------------

## Séquence attendue d'un Dresseur des jalons 9 et 10 (aucune clé du J12).
func _legacy_kinds(distance: int) -> Array[int]:
	var kinds: Array[int] = []
	if distance > TrainerEncounter.TALKED_TO:
		kinds.append_array([K.EMOTE, K.WAIT])
		if distance > 1:
			kinds.append(K.MOVE)
	kinds.append_array([K.FACE, K.FACE, K.DIALOGUE, K.BATTLE, K.DIALOGUE, K.WAKE_UP])
	return kinds


func test_every_real_trainer_keeps_the_jalon_9_10_sequence() -> void:
	var count := 0
	for file: String in DirAccess.get_files_at(NPC_DIR):
		if not file.ends_with(".json"):
			continue
		var roster := NpcRoster.new()
		assert_true(roster.load_file(NPC_DIR + file), file)
		for spec: NpcSpec in roster.get_all():
			if not spec.is_trainer() or spec.has_rematch() or spec.leaves:
				continue
			count += 1
			for distance: int in [TrainerEncounter.TALKED_TO, 1, spec.sight]:
				var variant := TrainerEncounter.build(spec.id, spec, distance)
				assert_eq(_kinds(variant), _legacy_kinds(distance), "%s à %d" % [spec.id, distance])
				for step: CutsceneStep in variant.steps:
					assert_true(step.lose_flags.is_empty(), "%s : aucune trace de défaite" % spec.id)
					for flag: StringName in step.if_flags + step.unless_flags:
						assert_false(String(flag).begins_with(TrainerRules.LOST_PREFIX), spec.id)
				var before: CutsceneStep = variant.steps[variant.steps.size() - 4]
				assert_eq(before.dialogue_id, spec.before_dialogue)
				assert_true(before.if_flags.is_empty() and before.unless_flags.is_empty(),
					"%s : « avant » sans condition" % spec.id)
	assert_gt(count, 5, "Dresseurs de la forêt, Liam… (%d)" % count)
