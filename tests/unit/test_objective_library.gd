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
	assert_eq(library.get_ids(), [&"deliver_parcel", &"reach_viridian"] as Array[StringName])


## Convention homogène (décision de Kevin du 2026-10-05) : tout texte d'objectif finit par un
## point (« remettre le colis au Professeur Chen. », « rejoindre Jadielle. »).
func test_every_objective_text_ends_with_a_period() -> void:
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string(
		ObjectiveLibrary.DEFAULT_PATH))
	assert_gt(list.size(), 0)
	for entry: Dictionary in list:
		var text := str(entry.get("text", "")).strip_edges()
		assert_true(text.ends_with("."), "« %s » (%s) finit par un point" % [text, entry.get("id")])
		assert_false(text.ends_with(".."), "« %s » : un seul point" % text)


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
	assert_eq(library.current(flags), "rejoindre Jadielle.")
	assert_eq(library.current_id(flags), &"reach_viridian")
	assert_false(library.is_draft(&"reach_viridian"), "texte validé par Kevin le 2026-10-06")
	flags.set_flag(&"got_potion_route_1")
	assert_eq(library.current(flags), "rejoindre Jadielle.", "toujours vrai sur la Route 1")
	# Jalon 7 T4 : l'arrivée à Jadielle (micro-scène) efface la ligne, en silence.
	flags.set_flag(&"viridian_arrived")
	assert_eq(library.current(flags), "", "arrivé à Jadielle : plus de ligne")


## Drapeaux lus par les objectifs avant que leur scène existe (J7) : à retirer de cette liste
## dès que la tâche qui les lève est fusionnée — `viridian_arrived` (T4, arrivée à Jadielle).
## `got_oak_parcel` est levé par la première visite de la Boutique depuis le T12
## (data/cutscenes/viridian_mart.json), `pokedex_activated` par la scène du colis depuis le T18
## (data/cutscenes/oak_lab.json).
const _PENDING_FLAGS: Array[StringName] = [&"viridian_arrived"]


## Jalon 7 (dossier 09 §4, §19) : le colis en main → « remettre le colis au Professeur
## Chen. » ; après l'activation, plus de ligne (Q-10) ; « rejoindre Jadielle » s'efface à
## l'arrivée.
func test_parcel_objective_then_nothing_after_the_activation() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var flags := StoryFlags.new()
	flags.set_flag(&"rival_battle_done")
	assert_eq(library.current_id(flags), &"reach_viridian")
	flags.set_flag(&"viridian_arrived")
	assert_eq(library.current(flags), "", "arrivé à Jadielle : plus de « rejoindre Jadielle »")
	flags.set_flag(&"got_oak_parcel")
	assert_eq(library.current(flags), "remettre le colis au Professeur Chen.")
	assert_eq(library.current_id(flags), &"deliver_parcel")
	assert_false(library.is_draft(&"deliver_parcel"), "texte validé (dossier 09 §19)")
	flags.set_flag(&"viridian_arrived", false)
	assert_eq(library.current_id(flags), &"deliver_parcel", "le colis passe en tête")
	flags.set_flag(&"viridian_arrived")
	flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(library.current(flags), "", "Q-10 : aucune ligne après l'activation")


func test_real_condition_flags_are_raised_by_the_story() -> void:
	var library := ObjectiveLibrary.new()
	library.load_file()
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	var raised := cutscenes.get_set_flags() + dialogues.get_set_flags()
	for flag: StringName in library.get_condition_flags():
		if _PENDING_FLAGS.has(flag) and not raised.has(flag):
			continue
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
