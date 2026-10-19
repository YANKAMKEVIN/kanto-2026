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


# --- Fins de variante : choix, action, scène (jalon 7 §3.3) -------------------------------

## L'infirmière du Centre (textes du dossier 09 §19), forme du jalon-07.md §3.3.
func _nurse() -> Dictionary:
	return {
		"nurse": {
			"speaker": "Infirmière",
			"variants": [{
				"pages": ["Bonjour. Je m'occupe de ton équipe ?"],
				"choice": {
					"confirm": "SOIGNER", "cancel": "PAS MAINTENANT",
					"confirm_action": "center_heal",
					"confirm_pages": ["Voilà. Tout le monde est en pleine forme."],
					"cancel_pages": ["Très bien. Reviens quand tu veux."],
				},
			}],
		},
	}


func test_choice_is_read_with_its_action_and_pages() -> void:
	assert_true(_library.add_from_dict(_nurse(), "test"))
	var variant := _library.get_dialogue(&"nurse").variants[0]
	assert_eq(variant.pages.size(), 1, "la question est la dernière page")
	assert_eq(variant.action, &"", "pas d'action de fin à côté d'un choix")
	var choice := variant.choice
	assert_not_null(choice)
	assert_eq(choice.confirm_label, "SOIGNER")
	assert_eq(choice.cancel_label, "PAS MAINTENANT")
	assert_eq(choice.confirm_action, &"center_heal")
	assert_eq(choice.confirm_pages.size(), 1)
	assert_eq(choice.confirm_pages[0].text, "Voilà. Tout le monde est en pleine forme.")
	assert_eq(choice.cancel_pages[0].text, "Très bien. Reviens quand tu veux.")


func test_choice_view_carries_the_question_and_both_labels() -> void:
	_library.add_from_dict(_nurse(), "test")
	var view := _library.get_dialogue(&"nurse").variants[0].choice.to_view("Question ?")
	assert_eq(view.title, "Question ?")
	assert_eq(view.confirm_label, "SOIGNER")
	assert_eq(view.cancel_label, "PAS MAINTENANT")
	assert_eq(view.detail, "", "aucune précision")


func test_choice_without_action_or_answer_pages_is_valid() -> void:
	assert_true(_library.add_from_dict({"q": {"pages": ["Sûr ?"],
		"choice": {"confirm": "OUI", "cancel": "NON", "confirm_pages": []}}}, "test"))
	var choice := _library.get_dialogue(&"q").variants[0].choice
	assert_eq(choice.confirm_action, &"")
	assert_true(choice.confirm_pages.is_empty())
	assert_true(choice.cancel_pages.is_empty())


func test_invalid_choices_are_rejected() -> void:
	var bad: Array = [
		"SOIGNER",
		{"cancel": "NON"},
		{"confirm": "OUI", "cancel": "  "},
		{"confirm": "OUI", "cancel": "NON", "confirm_action": "teleport"},
		{"confirm": "OUI", "cancel": "NON", "cancel_pages": "Non."},
		{"confirm": "OUI", "cancel": "NON", "confirm_pages": [""]},
		{"confirm": "OUI", "cancel": "NON", "typo": true},
	]
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"bad_%d" % i: {"pages": ["?"], "choice": bad[i]}},
			"test"), str(bad[i]))
	assert_push_error_count(bad.size())
	assert_eq(_library.size(), 0)
	assert_string_contains(";".join(_library.get_errors()), "action inconnue « teleport »")


func test_choice_needs_its_question_page() -> void:
	assert_false(_library.add_from_dict({"q": {"choice": {"confirm": "OUI", "cancel": "NON"}}},
		"test"))
	assert_push_error("« pages » doit être une liste non vide")


func test_action_and_cutscene_are_read() -> void:
	assert_true(_library.add_from_dict({
		"clerk": {"pages": ["Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ?"],
			"action": "open_shop"},
		"oak": {"pages": ["Tiens…"], "cutscene": "oak_parcel"},
	}, "test"))
	assert_eq(_library.get_dialogue(&"clerk").variants[0].action, &"open_shop")
	assert_eq(_library.get_dialogue(&"clerk").variants[0].cutscene, &"")
	assert_eq(_library.get_dialogue(&"oak").variants[0].cutscene, &"oak_parcel")
	assert_null(_library.get_dialogue(&"oak").variants[0].choice)


func test_every_known_action_is_accepted() -> void:
	for action: StringName in DialogueLibrary.ACTIONS:
		assert_true(_library.add_from_dict({String(action): {"pages": ["x"],
			"action": String(action)}}, "test"), String(action))
	assert_eq(DialogueLibrary.ACTIONS, [&"heal", &"center_heal", &"open_shop",
		&"open_storage", &"open_daycare"] as Array[StringName], "J15 : la Pension")


## J15 : le gardien de la Pension n'a pas de réplique à lui (action seule, sans page).
func test_daycare_keeper_is_an_action_without_page() -> void:
	assert_true(_library.add_from_dict({"keeper": {"speaker": "Gardien",
		"action": "open_daycare"}}, "test"))
	var variant := _library.get_dialogue(&"keeper").variants[0]
	assert_eq(variant.action, &"open_daycare")
	assert_eq(variant.pages.size(), 0)


func test_unknown_action_is_rejected() -> void:
	assert_false(_library.add_from_dict({"a": {"pages": ["x"], "action": "fly"}}, "test"))
	assert_false(_library.add_from_dict({"b": {"pages": ["x"], "action": 3}}, "test"))
	assert_false(_library.add_from_dict({"c": {"pages": ["x"], "cutscene": ""}}, "test"))
	assert_push_error_count(3)
	assert_eq(_library.size(), 0)


func test_variant_without_pages_needs_an_action_or_a_cutscene() -> void:
	assert_true(_library.add_from_dict({
		"terminal": {"action": "open_storage"},
		"oak_parcel_talk": {"pages": [], "cutscene": "oak_parcel"},
	}, "test"))
	assert_true(_library.get_dialogue(&"terminal").variants[0].pages.is_empty())
	assert_true(_library.get_dialogue(&"oak_parcel_talk").variants[0].pages.is_empty())
	assert_false(_library.add_from_dict({"nothing": {"set": ["x"]}}, "test"))
	assert_push_error("« pages » doit être une liste non vide")


func test_old_heal_key_means_the_heal_action() -> void:
	assert_true(_library.add_from_dict({
		"mom": {"pages": ["Laisse-moi m'occuper de tes Pokémon."], "heal": true},
		"mom_off": {"pages": ["Bonjour."], "heal": false},
	}, "test"))
	assert_eq(_library.get_dialogue(&"mom").variants[0].action, &"heal")
	assert_eq(_library.get_dialogue(&"mom_off").variants[0].action, &"")


func test_only_one_ending_per_variant() -> void:
	assert_false(_library.add_from_dict({"a": {"pages": ["x"], "heal": true,
		"action": "center_heal"}}, "test"))
	assert_false(_library.add_from_dict({"b": {"pages": ["x"], "action": "open_shop",
		"cutscene": "oak_parcel"}}, "test"))
	assert_false(_library.add_from_dict({"c": {"pages": ["x"], "action": "open_shop",
		"choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"))
	assert_push_error_count(3)
	assert_string_contains(_library.get_errors()[0], "une seule fin parmi heal, action")
	assert_eq(_library.size(), 0)


# --- Jetons de texte (jalon 7 §3.6, T18) ---------------------------------------------------

func test_known_token_is_accepted_in_both_page_forms() -> void:
	assert_true(_library.add_from_dict({"oak": {"pages": [
		"Un {first_wild_species}… Tu n'as pas perdu de temps.",
		{"text": "{first_wild_species} !", "pause": 0.2},
	]}}, "test"), str(_library.get_errors()))
	var pages := _library.get_dialogue(&"oak").variants[0].pages
	assert_eq(pages[0].text, "Un {first_wild_species}… Tu n'as pas perdu de temps.",
		"le texte des données garde son jeton (résolu au moment de jouer)")
	assert_eq(DialogueTokens.tokens_in(pages[1].text),
		[&"first_wild_species"] as Array[StringName])


func test_unknown_or_malformed_tokens_are_rejected() -> void:
	var bad: Array = [
		"Un {species}…", {"text": "Bonjour {player_name}"}, "Accolade { seule",
		"Fin }", "{First_wild_species}", "{}",
	]
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"d%d" % i: {"pages": [bad[i]]}}, "test"),
			str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size())
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "jeton inconnu « {species} »")
	assert_string_contains(errors, "jeton inconnu « {player_name} »")
	assert_string_contains(errors, "accolade hors d'un jeton")


## Locuteur à jeton (OUV.2, dossier 13 §3.5) : `{rival}` permis dans « speaker », au niveau du
## dialogue et de la page ; un jeton inconnu y est refusé.
func test_tokens_in_the_speaker() -> void:
	assert_true(_library.add_from_dict({"r": {"speaker": "{rival}", "pages": [
		"Hé !", {"text": "Ah.", "speaker": "{player}"}]}}, "test"), str(_library.get_errors()))
	var dialogue := _library.get_dialogue(&"r")
	assert_eq(dialogue.speaker, "{rival}", "gardé tel quel (résolu au moment de jouer)")
	assert_eq(dialogue.variants[0].pages[1].speaker, "{player}")
	assert_false(_library.add_from_dict({"s": {"speaker": "{rivl}", "pages": ["x"]}}, "test"))
	assert_false(_library.add_from_dict({"t": {"pages": [{"text": "x", "speaker": "{Rival}"}]}},
		"test"))
	assert_push_error_count(2)
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "jeton inconnu « {rivl} »")


func test_tokens_are_checked_in_the_answer_pages_of_a_choice() -> void:
	assert_false(_library.add_from_dict({"nurse": {"pages": ["Je soigne ?"], "choice": {
		"confirm": "OUI", "cancel": "NON", "confirm_pages": ["Voilà, {nobody}."]}}}, "test"))
	assert_push_error("jeton inconnu « {nobody} »")
	assert_true(_library.add_from_dict({"ok": {"pages": ["Je soigne ?"], "choice": {
		"confirm": "OUI", "cancel": "NON",
		"cancel_pages": ["Un {first_wild_species}…"]}}}, "test"), "réponse : jeton permis")


## La question d'un choix ne peut pas être omise : jamais de jeton dans sa dernière page.
func test_the_question_of_a_choice_has_no_token() -> void:
	assert_false(_library.add_from_dict({"q": {"pages": ["Tu as vu un {first_wild_species} ?"],
		"choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"))
	assert_push_error("la question d'un choix (dernière page) n'a pas de jeton")
	assert_true(_library.add_from_dict({"q2": {"pages": ["Un {first_wild_species}…",
		"Je soigne ?"], "choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"),
		"jeton permis avant la question")


## J15 : seuls les jetons « de contexte » de la Pension (toujours fournis par son directeur) sont
## permis dans la question (T-7, T-8 : « Tu veux le reprendre ? Ce sera {price} ₽. »).
func test_context_tokens_are_allowed_in_the_question_of_a_choice() -> void:
	assert_true(_library.add_from_dict({"visit": {"pages": ["{pokemon} va très bien.",
		"Tu veux le reprendre ? Ce sera {price} ₽."],
		"choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"))
	assert_false(_library.add_from_dict({"mixed": {"pages": ["{player}, {price} ₽ ?"],
		"choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"), "un jeton hors contexte")
	assert_push_error("la question d'un choix (dernière page) n'a pas de jeton")
# --- Choix qui pose un drapeau (jalon-13.md §2.13, T16) --------------------------------------

func test_choice_flags_are_read_and_listed_as_set() -> void:
	assert_true(_library.add_from_dict({"recruit": {"pages": ["Tu nous rejoins ?"],
		"choice": {"confirm": "OUI", "cancel": "NON", "confirm_set": ["recruit_yes"],
			"cancel_set": ["recruit_no", "recruit_refused"], "confirm_action": "heal"}}},
		"test"), "compatible avec confirm_action")
	var choice := _library.get_dialogue(&"recruit").variants[0].choice
	assert_eq(choice.confirm_set, [&"recruit_yes"] as Array[StringName])
	assert_eq(choice.cancel_set, [&"recruit_no", &"recruit_refused"] as Array[StringName])
	assert_eq(_library.get_set_flags(),
		[&"recruit_no", &"recruit_refused", &"recruit_yes"] as Array[StringName],
		"drapeaux du choix comptés comme levés (tests de données)")


func test_choice_without_flags_has_empty_lists() -> void:
	assert_true(_library.add_from_dict({"q": {"pages": ["Sûr ?"],
		"choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"))
	var choice := _library.get_dialogue(&"q").variants[0].choice
	assert_true(choice.confirm_set.is_empty())
	assert_true(choice.cancel_set.is_empty())


func test_invalid_choice_flags_are_rejected() -> void:
	var bad: Array = [
		{"confirm": "OUI", "cancel": "NON", "confirm_set": []},
		{"confirm": "OUI", "cancel": "NON", "cancel_set": "recruit_no"},
		{"confirm": "OUI", "cancel": "NON", "confirm_set": [""]},
		{"confirm": "OUI", "cancel": "NON", "cancel_set": [3]},
	]
	for i: int in bad.size():
		assert_false(_library.add_from_dict({"bad_%d" % i: {"pages": ["?"], "choice": bad[i]}},
			"test"), str(bad[i]))
	assert_push_error_count(bad.size())
	assert_eq(_library.size(), 0)


func test_page_voice_spirit_is_read_and_unknown_voice_is_refused() -> void:
	assert_true(_library.add_from_dict({"e1": {"pages": [
		{"text": "Laisse… nous…", "voice": "spirit"}, "Normal."]}}, "test"),
		str(_library.get_errors()))
	var pages := _library.get_dialogue(&"e1").variants[0].pages
	assert_eq(pages[0].voice, &"spirit")
	assert_eq(pages[1].voice, &"", "voix normale par défaut")
	var other := DialogueLibrary.new()
	assert_false(other.add_from_dict({"e2": {"pages": [
		{"text": "Boo", "voice": "demon"}]}}, "test"))
	assert_string_contains("\n".join(other.get_errors()), "voice")
	assert_push_error("voice")


## Jalon 20 (§2.9.1) : « shop » choisit la boutique d'un vendeur, seulement avec open_shop.
func test_shop_key_needs_the_open_shop_action() -> void:
	assert_true(_library.add_from_dict({"seller": {"pages": ["Bienvenue !"],
		"action": "open_shop", "shop": "celadon_dept_5f"}}, "test"))
	assert_eq(_library.get_dialogue(&"seller").variants[0].shop, &"celadon_dept_5f")
	assert_false(_library.add_from_dict({"a": {"pages": ["x"], "shop": "celadon_dept_4f"}},
		"test"), "sans action")
	assert_false(_library.add_from_dict({"b": {"pages": ["x"], "action": "center_heal",
		"shop": "celadon_dept_4f"}}, "test"), "autre action")
	assert_false(_library.add_from_dict({"c": {"pages": ["x"], "action": "open_shop",
		"shop": ""}}, "test"), "identifiant vide")
	assert_push_error_count(3)
	assert_eq(_library.size(), 1)
