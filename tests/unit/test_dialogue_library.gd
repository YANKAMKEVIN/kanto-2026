extends GutTest
## DialogueLibrary, Dialogue, DialogueVariant, DialoguePage : format des fichiers de
## data/dialogues/, validation, choix de la variante selon les drapeaux (jalon 3 §2.4).

const FIXTURES := "res://tests/fixtures/dialogues/"

var _library: DialogueLibrary


func before_each() -> void:
	_library = DialogueLibrary.new()


func _flags(names: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


# --- Chargement ---------------------------------------------------------------------

func test_load_dir_reads_every_json_file_and_ignores_others() -> void:
	assert_true(_library.load_dir(FIXTURES))
	assert_eq(_library.get_ids(), [&"breakfast_table", &"leo", &"mom", &"sign_test"]
		as Array[StringName])
	assert_eq(_library.get_errors().size(), 0)
	assert_eq(_library.get_dialogue(&"mom").source, FIXTURES + "house.json")


func test_missing_dir_or_file_is_an_error() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/nowhere/"))
	assert_push_error("dossier introuvable")
	assert_false(_library.load_file("res://tests/fixtures/dialogues/nothing.json"))
	assert_push_error("fichier introuvable")


func test_unknown_id_returns_null() -> void:
	assert_null(_library.get_dialogue(&"nobody"))
	assert_false(_library.has_dialogue(&"nobody"))


# --- Format ---------------------------------------------------------------------------

func test_variants_with_conditions_and_set_flags() -> void:
	_library.load_dir(FIXTURES)
	var mom := _library.get_dialogue(&"mom")
	assert_eq(mom.speaker, "Maman")
	assert_false(mom.narration)
	assert_eq(mom.variants.size(), 2)
	var first := mom.variants[0]
	assert_eq(first.unless_flags, [&"mom_greeted"] as Array[StringName])
	assert_eq(first.set_flags, [&"mom_greeted"] as Array[StringName])
	assert_true(first.auto)
	assert_eq(first.pages.size(), 2)
	assert_eq(first.pages[0].text, "Bonjour ! Tu es enfin réveillé ?")
	assert_false(mom.variants[1].auto, "auto vaut faux par défaut")
	assert_true(mom.variants[1].is_unconditional())


func test_single_variant_shorthand_and_narration() -> void:
	_library.load_dir(FIXTURES)
	var table := _library.get_dialogue(&"breakfast_table")
	assert_true(table.narration)
	assert_eq(table.speaker, "", "pas d'étiquette de nom")
	assert_eq(table.variants.size(), 1)
	assert_eq(table.variants[0].pages[0].text, "Ton petit-déjeuner est encore chaud.")


func test_page_object_with_stage_directions() -> void:
	_library.load_dir(FIXTURES)
	var pages := _library.get_dialogue(&"leo").variants[0].pages
	assert_eq(pages[0].pause, 0.0)
	assert_eq(pages[0].react, &"")
	assert_false(pages[0].face_player)
	assert_eq(pages[1].text, "...enfin, presque.")
	assert_eq(pages[1].react, &"leo_rattata")
	assert_almost_eq(pages[1].pause, 0.5, 0.0001)


func test_page_speaker_override_for_multi_voice_scenes() -> void:
	var ok := _library.add_from_dict({
		"lab_arrival": {
			"speaker": "Rival",
			"pages": [
				"Enfin.",
				{ "text": "Un peu de patience.", "speaker": "Chen" },
			],
		},
	}, "test")
	assert_true(ok)
	var pages := _library.get_dialogue(&"lab_arrival").variants[0].pages
	assert_eq(pages[0].speaker, "", "vide = locuteur du dialogue")
	assert_eq(pages[1].speaker, "Chen")


func test_draft_flag_is_read() -> void:
	_library.load_dir(FIXTURES)
	assert_true(_library.get_dialogue(&"sign_test").draft)
	assert_false(_library.get_dialogue(&"mom").draft)


# --- Validation -----------------------------------------------------------------------

func test_duplicate_id_across_files_is_rejected() -> void:
	_library.load_dir(FIXTURES)
	assert_false(_library.add_from_dict({"mom": {"pages": ["Autre."]}}, "autre.json"))
	assert_push_error("déjà défini")
	assert_eq(_library.get_dialogue(&"mom").speaker, "Maman", "le premier est gardé")


func test_unknown_key_is_rejected() -> void:
	assert_false(_library.add_from_dict({"typo": {"page": ["Oups."]}}, "test"))
	assert_push_error_count(2, "clé inconnue, puis pages manquantes")
	assert_string_contains(_library.get_errors()[0], "clé inconnue « page »")
	assert_false(_library.has_dialogue(&"typo"))


func test_empty_or_missing_pages_are_rejected() -> void:
	assert_false(_library.add_from_dict({"a": {"speaker": "A"}}, "test"))
	assert_false(_library.add_from_dict({"b": {"pages": []}}, "test"))
	assert_false(_library.add_from_dict({"c": {"pages": ["  "]}}, "test"))
	assert_false(_library.add_from_dict({"d": {"pages": [{"speaker": "X"}]}}, "test"))
	assert_false(_library.add_from_dict({"e": {"pages": [42]}}, "test"))
	assert_push_error_count(5)
	assert_eq(_library.size(), 0)


func test_bad_types_are_rejected() -> void:
	assert_false(_library.add_from_dict({"a": {"pages": ["x"], "auto": "oui"}}, "test"))
	assert_false(_library.add_from_dict({"b": {"pages": ["x"], "if": "flag"}}, "test"))
	assert_false(_library.add_from_dict({"c": {"pages": [{"text": "x", "pause": -1}]}}, "t"))
	assert_false(_library.add_from_dict({"d": {"pages": ["x"], "speaker": 3}}, "test"))
	assert_false(_library.add_from_dict({"e": "texte"}, "test"))
	assert_push_error_count(5)
	assert_eq(_library.size(), 0)


func test_variant_keys_beside_variants_are_rejected() -> void:
	var entry := {"variants": [{"pages": ["x"]}], "pages": ["y"]}
	assert_false(_library.add_from_dict({"a": entry}, "test"))
	assert_push_error("doit être dans une variante")


func test_one_invalid_entry_does_not_discard_the_others() -> void:
	assert_false(_library.add_from_dict({
		"good": {"pages": ["Bonjour."]},
		"bad": {"pages": []},
	}, "test"))
	assert_push_error_count(1)
	assert_true(_library.has_dialogue(&"good"))
	assert_false(_library.has_dialogue(&"bad"))
	assert_eq(_library.get_errors().size(), 1)


func test_invalid_json_file_reports_the_line() -> void:
	var path := "user://test_dialogue_invalid.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\n\t\"a\": { \"pages\": [\"x\" }\n}\n")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("ligne 2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- Choix de la variante -------------------------------------------------------------

func test_first_matching_variant_wins() -> void:
	_library.load_dir(FIXTURES)
	var mom := _library.get_dialogue(&"mom")
	assert_eq(mom.pick(_flags()), mom.variants[0], "premier échange")
	assert_eq(mom.pick(_flags([&"mom_greeted"])), mom.variants[1], "si on lui reparle")
	assert_eq(mom.pick(null), mom.variants[0], "sans drapeaux : aucun n'est levé")


func test_if_condition_requires_all_flags() -> void:
	_library.add_from_dict({"x": {"variants": [
		{"if": ["a", "b"], "pages": ["deux"]},
		{"if": ["a"], "pages": ["un"]},
	]}}, "test")
	var x := _library.get_dialogue(&"x")
	assert_null(x.pick(_flags()), "aucune variante ne s'applique")
	assert_null(x.pick(null))
	assert_eq(x.pick(_flags([&"a"])).pages[0].text, "un")
	assert_eq(x.pick(_flags([&"a", &"b"])).pages[0].text, "deux")


func test_flags_used_and_set_are_listed() -> void:
	_library.load_dir(FIXTURES)
	_library.add_from_dict({"x": {"if": ["starter_received"], "pages": ["…"]}}, "test")
	assert_eq(_library.get_condition_flags(), [&"mom_greeted", &"starter_received"]
		as Array[StringName])
	assert_eq(_library.get_set_flags(), [&"mom_greeted"] as Array[StringName])


# --- Clé de page « turn » (jalon 3B §2.7) ------------------------------------------------

func test_turn_is_read_in_order() -> void:
	assert_true(_library.add_from_dict({
		"oak_warning": {
			"speaker": "Prof. Chen",
			"pages": [
				{ "text": "Tu allais vraiment entrer là-dedans tout seul ?",
					"turn": { "oak": "player", "player": "oak" } },
				{ "text": "Les Pokémon qui vivent ici…", "turn": { "oak": "up" } },
				"Sans Pokémon à tes côtés, tu prends un risque inutile.",
			],
		},
	}, "test"))
	var pages := _library.get_dialogue(&"oak_warning").variants[0].pages
	assert_eq(pages[0].turn.keys(), [&"oak", &"player"], "ordre du fichier")
	assert_eq(pages[0].turn[&"oak"], &"player")
	assert_eq(pages[0].turn[&"player"], &"oak")
	assert_eq(pages[1].turn, {&"oak": &"up"} as Dictionary[StringName, StringName])
	assert_true(pages[2].turn.is_empty(), "sans « turn », personne ne se tourne")


func test_invalid_turn_is_rejected() -> void:
	var bad_turns: Array = [
		{}, "oak", ["oak", "up"], { "oak": "" }, { "oak": 3 }, { "": "up" }, { "up": "oak" },
	]
	for i: int in bad_turns.size():
		var id := "bad_%d" % i
		assert_false(_library.add_from_dict({
			id: { "pages": [{ "text": "x", "turn": bad_turns[i] }] },
		}, "test"), str(bad_turns[i]))
	assert_push_error_count(bad_turns.size())
	assert_eq(_library.size(), 0)
