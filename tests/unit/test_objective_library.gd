extends GutTest
## ObjectiveLibrary : « Objectif : … » du tableau de bord (jalon-06.md §3.2, Q-4).


func _library(list: Array) -> ObjectiveLibrary:
	var library := ObjectiveLibrary.new()
	assert_true(library.add_from_array(list, "t"), "\n".join(library.get_errors()))
	return library


# --- Données réelles -----------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	assert_eq(library.get_errors().size(), 0)
	assert_eq(library.get_ids(), [&"reach_viridian"] as Array[StringName])


func test_q4_nothing_before_the_rival_battle_then_reach_viridian() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	assert_eq(library.current(flags), "", "prologue : aucune ligne")
	for flag: StringName in [&"mom_greeted", &"oak_met", &"starter_offered", &"starter_chosen",
			&"rival_challenged"]:
		flags.set_flag(flag)
		assert_eq(library.current(flags), "", "pas encore : %s" % flag)
	flags.set_flag(&"rival_battle_done")
	assert_eq(library.current(flags), "rejoindre Jadielle")
	assert_eq(library.current_id(flags), &"reach_viridian")
	assert_true(library.is_draft(&"reach_viridian"), "texte provisoire")
	flags.set_flag(&"got_potion_route_1")
	assert_eq(library.current(flags), "rejoindre Jadielle", "toujours vrai sur la Route 1")
	# Jalon 7 T4 : l'arrivée à Jadielle (micro-scène) efface la ligne, en silence.
	flags.set_flag(&"viridian_arrived")
	assert_eq(library.current(flags), "", "arrivé à Jadielle : plus de ligne")


func test_real_condition_flags_are_raised_by_the_story() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var raised := cutscenes.get_set_flags() + dialogues.get_set_flags()
	for flag: StringName in library.get_condition_flags():
		assert_true(raised.has(flag), "« %s » levé par une scène ou un dialogue" % flag)


# --- Règles --------------------------------------------------------------------------------

func test_first_matching_entry_wins() -> void:
	var library := _library([
		{"id": "b", "text": "étape B", "if": ["b"]},
		{"id": "a", "text": "étape A", "if": ["a"], "unless": ["done"]},
		{"id": "start", "text": "début"},
	])
	var flags := StoryFlags.new()
	assert_eq(library.current(flags), "début", "sans condition : toujours vraie")
	flags.set_flag(&"a")
	assert_eq(library.current(flags), "étape A")
	flags.set_flag(&"b")
	assert_eq(library.current(flags), "étape B", "ordre du fichier")
	flags.set_flag(&"b", false)
	flags.set_flag(&"done")
	assert_eq(library.current(flags), "début", "« unless » écarte A")
	assert_eq(library.current(null), "début")
	assert_eq(library.get_condition_flags(), [&"b", &"a", &"done"] as Array[StringName])


func test_no_entry_no_line() -> void:
	var library := _library([])
	assert_eq(library.current(StoryFlags.new()), "")
	assert_eq(library.current_id(StoryFlags.new()), &"")
	assert_false(library.is_draft(&"missing"))


func test_text_is_trimmed_and_draft_defaults_to_false() -> void:
	var library := _library([{"id": "x", "text": "  aller voir  "}])
	assert_eq(library.current(null), "aller voir")
	assert_false(library.is_draft(&"x"))


func test_invalid_entries_are_rejected() -> void:
	var library := ObjectiveLibrary.new()
	assert_false(library.add_from_array([
		{"id": "ok", "text": "bon"},
		{"id": "typo", "text": "x", "iff": ["a"]},
		{"id": "ok", "text": "doublon"},
		{"text": "sans id"},
		{"id": "no_text"},
		{"id": "bad_if", "text": "x", "if": "a"},
		{"id": "bad_flag", "text": "x", "unless": [""]},
		{"id": "bad_draft", "text": "x", "draft": "oui"},
		"pas un objet",
	], "t"))
	assert_eq(library.get_ids(), [&"ok"] as Array[StringName], "seule l'entrée valide reste")
	var errors := "\n".join(library.get_errors())
	assert_string_contains(errors, "clé inconnue « iff »")
	assert_string_contains(errors, "identifiant « ok » en double")
	assert_push_error_count(8, "une erreur par entrée invalide")


func test_missing_file_and_wrong_root() -> void:
	var library := ObjectiveLibrary.new()
	assert_false(library.load_file("res://tests/fixtures/absent_objectives.json"))
	assert_push_error("fichier introuvable")
	var path := "user://test_objectives_root.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\"id\": \"x\"}")
	file.close()
	assert_false(library.load_file(path))
	assert_push_error("une liste d'objectifs est attendue")
	DirAccess.remove_absolute(path)
