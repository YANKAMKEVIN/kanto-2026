extends GutTest
## Jalon 21 (`jalon-21.md` §2.3, T10, T19) dans [CutsceneLibrary] et [CutsceneStep] : clés
## « flee », « clear », « reveal », « uncatchable » de « wild_battle » ; « set » d'un « give » ;
## « skip_reduced » d'un « animate » ; étape « flute » ; « if_items » / « unless_items » des
## variantes.

const O := Battle.Outcome
const FULL := {"wild_battle": "marowak", "level": 30, "ghost_unless_item": "silph_scope",
	"reveal": true, "uncatchable": true, "win": ["w"], "lose": ["l"], "flee": ["f"],
	"catch": ["c"], "clear": ["busy"]}


func _load(steps: Array, variant_keys: Dictionary = {}) -> CutsceneLibrary:
	var library := CutsceneLibrary.new()
	var scene := variant_keys.duplicate()
	scene["steps"] = steps
	library.add_from_dict({"scene": scene}, "test")
	return library


func _step(library: CutsceneLibrary, index: int = 0) -> CutsceneStep:
	return library.get_cutscene(&"scene").variants[0].steps[index]


# --- wild_battle ------------------------------------------------------------------------

func test_full_wild_battle_is_parsed() -> void:
	var library := _load([FULL])
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_true(step.reveal)
	assert_true(step.uncatchable)
	assert_eq(step.flee_flags, [&"f"] as Array[StringName])
	assert_eq(step.clear_flags, [&"busy"] as Array[StringName])


func test_defaults_are_false_and_empty() -> void:
	var step := _step(_load([{"wild_battle": "pidgey", "level": 5}]))
	assert_false(step.reveal)
	assert_false(step.uncatchable)
	assert_eq(step.flee_flags, [] as Array[StringName])
	assert_eq(step.clear_flags, [] as Array[StringName])


func test_outcome_flags_include_flee_and_never_clear() -> void:
	var step := _step(_load([FULL]))
	assert_eq(step.outcome_flags(O.FLED), [&"f"] as Array[StringName])
	assert_eq(step.outcome_flags(O.WIN), [&"w"] as Array[StringName])
	assert_eq(step.outcome_flags(O.LOSS), [&"l"] as Array[StringName])
	assert_eq(step.outcome_flags(O.CAUGHT), [&"c"] as Array[StringName])
	assert_eq(step.outcome_flags(O.FOE_FLED), [] as Array[StringName])


func test_set_flags_include_flee_but_not_clear() -> void:
	var flags := _load([FULL]).get_set_flags()
	assert_has(flags, &"f")
	assert_does_not_have(flags, &"busy")


func test_copy_keeps_the_new_fields() -> void:
	var step := _step(_load([FULL]))
	var other := step.copy()
	assert_eq(other.reveal, true)
	assert_eq(other.uncatchable, true)
	assert_eq(other.flee_flags, step.flee_flags)
	assert_eq(other.clear_flags, step.clear_flags)
	other.clear_flags.append(&"x")
	assert_eq(step.clear_flags.size(), 1, "copie indépendante")


func test_reveal_with_ghost_unless_item_is_accepted() -> void:
	var library := _load([{"wild_battle": "marowak", "level": 30,
		"ghost_unless_item": "silph_scope", "reveal": true}])
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))


func test_invalid_wild_battle_entries_are_rejected() -> void:
	var bad: Array[Dictionary] = [
		{"wild_battle": "marowak", "level": 30, "ghost": "always", "reveal": true},
		{"wild_battle": "marowak", "level": 30, "clear": []},
		{"wild_battle": "marowak", "level": 30, "clear": "busy"},
		{"wild_battle": "marowak", "level": 30, "flee": []},
		{"wild_battle": "marowak", "level": 30, "reveal": "yes"},
		{"wild_battle": "marowak", "level": 30, "uncatchable": 1},
		{"battle": "rival", "flee": ["f"]},
		{"battle": "rival", "clear": ["f"]},
	]
	for entry: Dictionary in bad:
		var library := _load([entry])
		assert_false(library.has_cutscene(&"scene"), "refusée : %s" % entry)
		assert_eq(library.get_errors().size(), 1, "une erreur : %s" % [library.get_errors()])
	assert_push_error_count(bad.size(), "une erreur par entrée")


# --- give + set, animate.skip_reduced, flute ----------------------------------------------

func test_give_with_set_is_one_give_step() -> void:
	var library := _load([{"give": "poke_flute", "set": ["got_poke_flute"]}])
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var step := _step(library)
	assert_eq(step.kind, CutsceneStep.Kind.GIVE)
	assert_eq(step.item_id, &"poke_flute")
	assert_eq(step.flags, [&"got_poke_flute"] as Array[StringName])
	assert_has(library.get_set_flags(), &"got_poke_flute")
	assert_eq(step.copy().flags, step.flags)


func test_set_step_alone_is_unchanged() -> void:
	var step := _step(_load([{"set": ["a"]}]))
	assert_eq(step.kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(step.flags, [&"a"] as Array[StringName])


func test_animate_skip_reduced() -> void:
	var library := _load([
		{"animate": "Light", "offset": [0, -1], "duration": 2.0, "skip_reduced": true},
		{"animate": "Light", "offset": [0, -1], "duration": 2.0},
	])
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_true(_step(library, 0).skip_reduced)
	assert_false(_step(library, 1).skip_reduced, "faux par défaut")
	assert_true(_step(library, 0).copy().skip_reduced)


func test_flute_step() -> void:
	var library := _load([{"flute": true}])
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(_step(library).kind, CutsceneStep.Kind.FLUTE)
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.FLUTE), &"flute")


func test_invalid_j21_steps_are_rejected() -> void:
	var bad: Array[Dictionary] = [
		{"give": "potion", "set": []},
		{"give": "potion", "set": "a"},
		{"animate": "Light", "offset": [0, 1], "duration": 1.0, "skip_reduced": "yes"},
		{"flute": false},
		{"flute": true, "count": 3},
		{"wait": 1, "skip_reduced": true},
	]
	for entry: Dictionary in bad:
		var library := _load([entry])
		assert_false(library.has_cutscene(&"scene"), "refusée : %s" % entry)
		assert_eq(library.get_errors().size(), 1, "une erreur : %s" % [library.get_errors()])
	assert_push_error_count(bad.size(), "une erreur par entrée")


# --- Variantes selon le Sac ---------------------------------------------------------------

func test_variant_item_keys_are_read() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"scene": {"variants": [
		{"if_items": ["silph_scope"], "unless": ["calmed"], "steps": [{"set": ["a"]}]},
		{"unless_items": ["silph_scope", "poke_flute"], "steps": [{"set": ["b"]}]},
	]}}, "test"), str(library.get_errors()))
	var variants := library.get_cutscene(&"scene").variants
	assert_eq(variants[0].if_items, [&"silph_scope"] as Array[StringName])
	assert_eq(variants[1].unless_items, [&"silph_scope", &"poke_flute"] as Array[StringName])


func test_single_variant_scene_accepts_item_keys() -> void:
	var library := _load([{"set": ["a"]}], {"if_items": ["silph_scope"]})
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(library.get_cutscene(&"scene").variants[0].if_items,
		[&"silph_scope"] as Array[StringName])


func test_empty_or_invalid_item_lists_are_rejected() -> void:
	var bad: Array[Dictionary] = [
		{"if_items": []},
		{"unless_items": []},
		{"if_items": "silph_scope"},
		{"if_items": [""]},
	]
	for keys: Dictionary in bad:
		var library := _load([{"set": ["a"]}], keys)
		assert_false(library.has_cutscene(&"scene"), "refusée : %s" % keys)
	assert_push_error_count(bad.size(), "une erreur par entrée")
