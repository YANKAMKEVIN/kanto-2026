extends GutTest
## CutsceneLibrary, Cutscene, CutsceneVariant, CutsceneStep : format des fichiers de
## data/cutscenes/, validation, choix de la variante selon les drapeaux (jalon 3B §2.3).

const FIXTURES := "res://tests/fixtures/cutscenes/"

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _flags(names: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


## Ajoute une scène d'une seule étape ; renvoie l'étape (null si refusée).
func _one_step(step: Variant, id: String = "s") -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


# --- Chargement ---------------------------------------------------------------------

func test_load_dir_reads_every_json_file() -> void:
	assert_true(_library.load_dir(FIXTURES))
	assert_eq(_library.get_errors().size(), 0, str(_library.get_errors()))
	assert_eq(_library.get_ids(), [&"route1_grass", &"walk_to_desk"] as Array[StringName])
	assert_eq(_library.size(), 2)
	assert_eq(_library.get_cutscene(&"route1_grass").source, FIXTURES + "prologue.json")
	assert_eq(_library.get_cutscene(&"route1_grass").id, &"route1_grass")


func test_missing_dir_or_file_is_an_error() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/nowhere/"))
	assert_push_error("dossier introuvable")
	assert_false(_library.load_file(FIXTURES + "nothing.json"))
	assert_push_error("fichier introuvable")
	assert_null(_library.get_cutscene(&"nothing"))
	assert_false(_library.has_cutscene(&"nothing"))


func test_invalid_json_file_reports_the_line() -> void:
	var path := "user://test_cutscene_invalid.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\n\t\"a\": {\n\t\t\"steps\": [{ \"wait\": 1 }\n\t}\n}\n")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("ligne 4")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_not_an_object_file_is_an_error() -> void:
	var path := "user://test_cutscene_list.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[1, 2]")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("un objet { identifiant: scène }")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- Contenu d'une scène ---------------------------------------------------------------

func test_every_step_type_of_the_prologue() -> void:
	_library.load_dir(FIXTURES)
	var variant := _library.get_cutscene(&"route1_grass").variants[0]
	var kinds: Array[CutsceneStep.Kind] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	var K := CutsceneStep.Kind
	assert_eq(kinds, [K.WAIT, K.DIALOGUE, K.FACE, K.SPAWN, K.MOVE, K.FACE, K.DIALOGUE,
		K.SET_FLAGS, K.MOVE, K.CHANGE_MAP, K.MOVE, K.FACE, K.DIALOGUE, K.SET_FLAGS]
		as Array[CutsceneStep.Kind])
	var steps := variant.steps
	assert_almost_eq(steps[0].seconds, 0.4, 0.0001)
	assert_eq(steps[1].dialogue_id, &"oak_route1_call")
	assert_eq(steps[2].actor, &"player")
	assert_eq(steps[2].target, &"down")
	assert_eq(steps[5].target, &"player")
	assert_eq(steps[7].flags, [&"oak_met"] as Array[StringName])


func test_spawn_step_carries_an_npc_spec() -> void:
	_library.load_dir(FIXTURES)
	var spawn := _library.get_cutscene(&"route1_grass").variants[0].steps[3]
	assert_eq(spawn.actor, &"oak")
	assert_not_null(spawn.spec)
	assert_eq(spawn.spec.id, &"oak")
	assert_eq(spawn.spec.cell, Vector2i(24, 13))
	assert_eq(spawn.spec.facing, Vector2i.UP)
	assert_eq(spawn.spec.sprite, &"oak")
	assert_false(spawn.spec.is_interactive())
	assert_true(spawn.spec.is_present(null), "pas de condition dans une étape")


func test_move_steps() -> void:
	_library.load_dir(FIXTURES)
	var steps := _library.get_cutscene(&"route1_grass").variants[0].steps
	var run: CutsceneStep = steps[4]
	assert_eq(run.actor, &"oak")
	assert_true(run.run)
	assert_true(run.has_destination())
	assert_eq(run.cell, CutsceneStep.NO_CELL)
	assert_eq(run.near, &"player")
	assert_eq(run.offsets, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
		as Array[Vector2i])
	assert_true(run.path.is_empty())
	var follow: CutsceneStep = steps[8]
	assert_false(follow.run, "marche par défaut")
	assert_false(follow.has_destination())
	assert_eq(follow.follower, &"player")
	assert_eq(follow.path, [Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN] as Array[Vector2i])
	var desk := _library.get_cutscene(&"walk_to_desk").variants[0].steps[0]
	assert_true(desk.has_destination())
	assert_eq(desk.cell, Vector2i(8, 4))
	assert_eq(desk.near, &"")


func test_change_map_step() -> void:
	_library.load_dir(FIXTURES)
	var lab := _library.get_cutscene(&"route1_grass").variants[0].steps[9]
	assert_eq(lab.map_id, &"oak_lab")
	assert_eq(lab.spawn, &"entrance")
	assert_eq(lab.facing, Vector2i.UP)
	var town := _library.get_cutscene(&"walk_to_desk").variants[0].steps[1]
	assert_eq(town.facing, Vector2i.ZERO, "sans facing : garder l'orientation")


func test_kind_names() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.WAIT), &"wait")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.SET_FLAGS), &"set")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.CHANGE_MAP), &"change_map")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())


# --- Variantes et drapeaux --------------------------------------------------------------

func test_first_matching_variant_wins() -> void:
	_library.load_dir(FIXTURES)
	var grass := _library.get_cutscene(&"route1_grass")
	assert_eq(grass.pick(_flags()), grass.variants[0], "d'abord l'interception de Chen")
	assert_eq(grass.pick(null), grass.variants[0])
	assert_eq(grass.pick(_flags([&"oak_met"])), grass.variants[1], "puis la pensée")
	assert_null(grass.pick(_flags([&"oak_met", &"has_starter"])), "désarmé avec un starter")
	assert_false(grass.matches(_flags([&"oak_met", &"has_starter"])))
	assert_true(grass.matches(_flags([&"oak_met"])))


func test_if_condition_requires_all_flags() -> void:
	_library.load_dir(FIXTURES)
	var desk := _library.get_cutscene(&"walk_to_desk")
	assert_false(desk.matches(null))
	assert_false(desk.matches(_flags()))
	assert_true(desk.matches(_flags([&"oak_met"])))


func test_flags_and_dialogues_are_listed() -> void:
	_library.load_dir(FIXTURES)
	assert_eq(_library.get_condition_flags(), [&"has_starter", &"oak_met"]
		as Array[StringName])
	assert_eq(_library.get_set_flags(), [&"oak_lab_reunion", &"oak_met"] as Array[StringName])
	assert_eq(_library.get_dialogue_ids(), [&"oak_lab_reunion", &"oak_route1_call",
		&"oak_route1_warning", &"route1_grass_thought"] as Array[StringName])


# --- Validation -----------------------------------------------------------------------

func test_duplicate_id_across_files_is_rejected() -> void:
	_library.load_dir(FIXTURES)
	assert_false(_library.add_from_dict({"walk_to_desk": {"steps": [{"wait": 1}]}}, "b.json"))
	assert_push_error("déjà défini")
	assert_eq(_library.get_cutscene(&"walk_to_desk").source, FIXTURES + "short.json")


func test_scene_level_errors() -> void:
	var bad: Dictionary = {
		"not_object": "wait",
		"no_steps": {"unless": ["x"]},
		"empty_steps": {"steps": []},
		"empty_variants": {"variants": []},
		"typo": {"step": [{"wait": 1}]},
		"bad_flags": {"if": "oak_met", "steps": [{"wait": 1}]},
		"beside_variants": {"variants": [{"steps": [{"wait": 1}]}], "unless": ["x"]},
	}
	for id: String in bad:
		assert_false(_library.add_from_dict({id: bad[id]}, "test"), id)
		assert_false(_library.has_cutscene(StringName(id)), id)
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size() + 1, "une erreur par scène, deux pour « typo »")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["un objet est attendu", "« steps » doit être une liste non vide",
			"« variants » doit être une liste non vide", "clé inconnue « step »",
			"« if » doit être une liste", "doit être dans une variante"]:
		assert_string_contains(errors, expected)


func test_step_type_must_be_unique_and_known() -> void:
	assert_null(_one_step({"sleep": 1}, "a"))
	assert_null(_one_step({"wait": 1, "dialogue": "x"}, "b"))
	assert_null(_one_step("wait", "c"))
	assert_null(_one_step({"change_map": "oak_lab", "at": "entrance", "spawn": "oak"}, "d"))
	assert_eq(_library.size(), 0)
	assert_push_error_count(4)
	assert_string_contains(_library.get_errors()[0], "exactement un type")


func test_invalid_step_parameters() -> void:
	var bad: Array[Dictionary] = [
		{"wait": -1},
		{"wait": "long"},
		{"wait": 1, "to": "up"},
		{"dialogue": ""},
		{"dialogue": 3},
		{"face": "oak"},
		{"face": "oak", "to": ""},
		{"face": "", "to": "up"},
		{"set": []},
		{"set": "oak_met"},
		{"set": [""]},
		{"move": "oak"},
		{"move": "oak", "path": ["down"], "to": [1, 1]},
		{"move": "oak", "path": []},
		{"move": "oak", "path": ["south"]},
		{"move": "oak", "to": [1]},
		{"move": "oak", "to": "player"},
		{"move": "oak", "to": {"near": "player"}},
		{"move": "oak", "to": {"near": "player", "offsets": [[0, 0]]}},
		{"move": "oak", "to": {"near": "player", "offsets": [[1.5, 0]]}},
		{"move": "oak", "to": {"near": "", "offsets": [[1, 0]]}},
		{"move": "oak", "to": {"near": "player", "offsets": [[1, 0]], "first": true}},
		{"move": "oak", "path": ["down"], "run": "yes"},
		{"move": "oak", "path": ["down"], "follower": "oak"},
		{"move": "oak", "path": ["down"], "follower": ""},
		{"change_map": "oak_lab"},
		{"change_map": "", "at": "entrance"},
		{"change_map": "oak_lab", "at": "entrance", "facing": "north"},
		{"change_map": "oak_lab", "at": "entrance", "fade": false},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")


func test_invalid_spawn_steps() -> void:
	var bad: Array[Dictionary] = [
		{"spawn": "oak", "cell": [24, 13]},
		{"spawn": "oak", "sprite": "oak"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "facing": "north"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "dialog": "oak"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "if": ["oak_met"]},
		{"spawn": "player", "sprite": "oak", "cell": [24, 13]},
		{"spawn": "", "sprite": "oak", "cell": [24, 13]},
		{"spawn": "oak", "sprite": "oak", "at": [24, 13]},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "spawn_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size() + 1, "une par étape, deux pour « at » sans « cell »")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« sprite » est obligatoire", "« cell » doit être",
			"« facing » vaut", "clé inconnue « dialog »", "conditions : variante",
			"réservé au joueur", "spawn : identifiant attendu", "clé inconnue « at »"]:
		assert_string_contains(errors, expected)


func test_spawn_accepts_optional_npc_keys() -> void:
	var step := _one_step({"spawn": "starter", "sprite": "bulbasaur", "cell": [10, 5],
		"dialogue": "observe_bulbasaur", "verb": "observe", "lift": 56})
	assert_not_null(step)
	assert_eq(step.spec.verb, Interaction.Kind.OBSERVE)
	assert_eq(step.spec.lift, 56)
	assert_eq(step.spec.dialogue, &"observe_bulbasaur")


func test_one_invalid_scene_does_not_discard_the_others() -> void:
	assert_false(_library.add_from_dict({
		"good": {"steps": [{"wait": 0.5}]},
		"bad": {"steps": [{"wait": 0.5}, {"move": "oak"}]},
	}, "test"))
	assert_push_error_count(1)
	assert_true(_library.has_cutscene(&"good"))
	assert_false(_library.has_cutscene(&"bad"), "écartée entière, pas seulement l'étape")
	assert_eq(_library.get_errors().size(), 1)
