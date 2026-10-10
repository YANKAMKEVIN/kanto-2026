extends GutTest
## IntroScript et IntroReader (dossier 13 §3.2, §4, §5.5, §6) : le vrai script de Chen, sa
## validation stricte et le curseur (avancer, prénoms, Oui / Non).

const T := IntroStep.Type
## Textes du §6, version « petit-fils », dans l'ordre d'affichage (prompts et confirmations
## compris, jetons non résolus).
const EXPECTED_TEXTS: Array[String] = [
	"Bonjour ! Bienvenue dans le monde des Pokémon !",
	"Je m'appelle Chen. Ici, on m'appelle le Professeur Pokémon.",
	"Ce monde est peuplé de créatures que l'on appelle Pokémon.",
	"Certains vivent à nos côtés. D'autres préfèrent les hautes herbes, les forêts ou la mer.",
	"Certains Dresseurs s'entraînent avec eux pour combattre. Moi… je passe mes journées à "
		+ "les observer.",
	"Mais parlons un peu de toi.",
	"Comment t'appelles-tu ?",
	"{player} ! C'est bien ça ?",
	"Et lui, tu le connais depuis toujours. C'est mon petit-fils.",
	"Vous vous lancez des défis depuis que vous savez marcher.",
	"Il s'appelle… euh…",
	"Comment s'appelle-t-il, déjà ?",
	"{rival} ! C'est ça, bien sûr.",
	"{player} ! Ta propre aventure est sur le point de commencer.",
	"Un monde de rêves et de rencontres t'attend.",
	"Allez… en route !",
]
const MAX := 10

var _intro: IntroScript


func before_all() -> void:
	_intro = IntroScript.new()
	assert_true(_intro.load_file(), str(_intro.get_errors()))


## Petit script valide, modifiable par chaque test.
func _minimal() -> Dictionary:
	return {
		"speaker": "Prof. Chen", "yes": "Oui", "no": "Non",
		"steps": [
			{"type": "stage", "show": "chen", "at": "center"},
			{"type": "page", "text": "Bonjour !"},
			{"type": "prompt", "name": "player_name", "text": "Ton nom ?"},
			{"type": "confirm", "name": "player_name", "text": "{player} ?"},
			{"type": "prompt", "name": "rival_name", "text": "Son nom ?"},
			{"type": "confirm", "name": "rival_name", "text": "{rival} !"},
			{"type": "page", "text": "{player} et {rival}."},
		],
	}


func _rejects(data: Dictionary, why: String) -> void:
	var intro := IntroScript.new()
	assert_false(intro.add_from_dict(data, "test"), why)
	assert_false(intro.is_loaded(), why + " (tout ou rien)")
	assert_gt(intro.get_errors().size(), 0, why)


func _with_step(index: int, step: Dictionary) -> Dictionary:
	var data := _minimal()
	(data["steps"] as Array).insert(index, step)
	return data


func _reader() -> IntroReader:
	return IntroReader.new(_intro, MAX)


## Dictionnaire typé des portraits attendus.
func _stage(expected: Dictionary) -> Dictionary[StringName, StringName]:
	var typed: Dictionary[StringName, StringName] = {}
	typed.assign(expected)
	return typed


## Avance le lecteur jusqu'au prochain PROMPT / CONFIRM (ou la fin).
func _skip(reader: IntroReader) -> void:
	while not reader.is_finished() and reader.current().type in [T.STAGE, T.PAGE]:
		reader.advance()


# --- Le vrai script -----------------------------------------------------------------------

func test_real_script_texts_are_exactly_section_6() -> void:
	var texts: Array[String] = []
	for i: int in _intro.size():
		if _intro.step(i).type != T.STAGE:
			texts.append(_intro.step(i).text)
	assert_eq(texts, EXPECTED_TEXTS)


func test_real_script_speaker_and_labels() -> void:
	assert_eq(_intro.speaker, "Prof. Chen")
	assert_eq(_intro.yes_label, "Oui")
	assert_eq(_intro.no_label, "Non")
	for i: int in _intro.size():
		if _intro.step(i).type != T.STAGE:
			assert_eq(_intro.step(i).speaker, "Prof. Chen")


func test_real_script_has_about_fifteen_pages() -> void:
	assert_between(_intro.text_count(), 13, 17, "≈ 15 pages (dossier 13 §4)")


func test_real_script_estimated_duration_within_ceiling() -> void:
	# Vitesse « Normale » (45 car./s), 1,5 s pour lire et toucher, 0,5 s par mouvement de
	# scène, prénoms de 10 caractères ; saisie non comptée (§4 : 60–90 s au plus).
	var normal := _intro.estimated_seconds(UiTokens.DIALOG_CHARS_PER_SECOND, 1.5, 0.5)
	assert_lt(normal, 90.0, "plafond de 90 s")
	assert_gt(normal, 20.0, "estimation plausible")
	var slow := _intro.estimated_seconds(GameSettings.CHARS_PER_SECOND[0], 1.5, 0.5)
	assert_lt(slow, 90.0, "même en vitesse lente")
	assert_gt(slow, normal)


func test_estimate_instant_text_counts_only_reading() -> void:
	var instant := _intro.estimated_seconds(0.0, 1.0, 0.0)
	assert_eq(instant, float(_intro.text_count()))


func test_real_script_nidorino_appears_from_a_poke_ball() -> void:
	var found := false
	for i: int in _intro.size():
		var entry := _intro.step(i)
		if entry.type == T.STAGE and entry.portrait == &"nidorino" and entry.show:
			found = true
			assert_eq(entry.effect, &"pokeball")
	assert_true(found)


func test_real_script_ends_with_player_alone_at_center() -> void:
	var reader := _reader()
	_skip(reader)
	reader.answer_prompt("Kevin")
	reader.answer_confirm(true)
	_skip(reader)
	reader.answer_prompt("Régis")
	reader.answer_confirm(true)
	while not reader.is_finished():
		reader.advance()
	assert_eq(reader.portraits_on_stage(), _stage({&"player": &"center"}))


func test_prompt_names() -> void:
	assert_eq(_intro.step(_intro.prompt_index(IntroScript.PROMPT_PLAYER_NAME)).text,
		"Comment t'appelles-tu ?")
	assert_eq(_intro.prompt_index(&"look"), -1, "option A : pas de choix d'apparence")


# --- Validation stricte -------------------------------------------------------------------

func test_minimal_is_valid() -> void:
	var intro := IntroScript.new()
	assert_true(intro.add_from_dict(_minimal(), "test"), str(intro.get_errors()))
	assert_eq(intro.size(), 7)


func test_unknown_type() -> void:
	_rejects(_with_step(1, {"type": "wait"}), "type inconnu")
	_rejects(_with_step(1, {"text": "sans type"}), "type absent")


func test_unknown_keys() -> void:
	var data := _minimal()
	data["voice"] = "x"
	_rejects(data, "clé racine")
	_rejects(_with_step(1, {"type": "page", "text": "a", "pause": 1}), "clé de page")
	_rejects(_with_step(1, {"type": "stage", "show": "chen", "at": "left", "speed": 2}),
		"clé de stage")


func test_missing_root_texts() -> void:
	for key: String in ["speaker", "yes", "no", "steps"]:
		var data := _minimal()
		data.erase(key)
		_rejects(data, key)


func test_unknown_portrait_slot_or_effect() -> void:
	_rejects(_with_step(1, {"type": "stage", "show": "brock", "at": "left"}), "portrait")
	_rejects(_with_step(1, {"type": "stage", "show": "player", "at": "top"}), "emplacement")
	_rejects(_with_step(1, {"type": "stage", "show": "player", "at": "left",
		"effect": "sparkle"}), "effet")
	_rejects(_with_step(1, {"type": "stage", "show": "player"}), "show sans at")


func test_stage_needs_exactly_one_of_show_or_hide() -> void:
	_rejects(_with_step(1, {"type": "stage", "at": "left"}), "ni l'un ni l'autre")
	_rejects(_with_step(1, {"type": "stage", "show": "chen", "hide": "chen", "at": "left"}),
		"les deux")
	_rejects(_with_step(1, {"type": "stage", "hide": "chen", "at": "left"}), "hide avec at")


func test_hide_of_absent_portrait() -> void:
	_rejects(_with_step(1, {"type": "stage", "hide": "rival"}), "rival absent")


func test_two_portraits_on_same_slot() -> void:
	_rejects(_with_step(1, {"type": "stage", "show": "player", "at": "center"}), "centre pris")


func test_moving_a_shown_portrait_is_allowed() -> void:
	var intro := IntroScript.new()
	assert_true(intro.add_from_dict(_with_step(1, {"type": "stage", "show": "chen",
		"at": "left"}), "test"), str(intro.get_errors()))


func test_unknown_token() -> void:
	_rejects(_with_step(1, {"type": "page", "text": "Un {first_wild_species} !"}), "jeton")
	_rejects(_with_step(1, {"type": "page", "text": "Salut {Player}"}), "majuscule")
	_rejects(_with_step(1, {"type": "page", "text": "Salut {player"}), "accolade")


func test_token_before_its_prompt() -> void:
	_rejects(_with_step(1, {"type": "page", "text": "Bonjour {player} !"}), "{player} trop tôt")
	_rejects(_with_step(4, {"type": "page", "text": "Et {rival} ?"}), "{rival} trop tôt")
	var data := _minimal()
	data["steps"][2]["text"] = "{player}, ton nom ?"
	_rejects(data, "jeton dans son propre prompt")


func test_prompts_required_once() -> void:
	var data := _minimal()
	(data["steps"] as Array).remove_at(5)
	(data["steps"] as Array).remove_at(4)
	data["steps"][4]["text"] = "Fin."
	_rejects(data, "prompt du rival manquant")
	_rejects(_with_step(4, {"type": "prompt", "name": "player_name", "text": "Encore ?"}),
		"prompt en double")


func test_unknown_or_look_prompt() -> void:
	_rejects(_with_step(1, {"type": "prompt", "name": "nickname", "text": "?"}), "inconnu")
	_rejects(_with_step(1, {"type": "prompt", "name": "look", "text": "Garçon ?"}),
		"option A : look refusé")


func test_confirm_must_follow_its_prompt() -> void:
	var data := _minimal()
	data["steps"][5]["name"] = "player_name"
	data["steps"][5]["text"] = "{player} ?"
	_rejects(data, "confirm d'un autre prompt")
	_rejects(_with_step(1, {"type": "confirm", "name": "player_name", "text": "{player} ?"}),
		"confirm sans prompt")


func test_confirm_needs_its_token() -> void:
	var data := _minimal()
	data["steps"][3]["text"] = "C'est bien ça ?"
	_rejects(data, "confirm sans {player}")


func test_page_speaker_override() -> void:
	var intro := IntroScript.new()
	assert_true(intro.add_from_dict(_with_step(1, {"type": "page", "text": "Hé !",
		"speaker": "Maman"}), "test"))
	assert_eq(intro.step(1).speaker, "Maman")
	assert_eq(intro.step(2).speaker, "Prof. Chen")
	_rejects(_with_step(1, {"type": "page", "text": "Hé !", "speaker": ""}), "speaker vide")


func test_resolve() -> void:
	var values: Dictionary[StringName, String] = {&"player": "Sacha", &"rival": "Régis"}
	assert_eq(IntroScript.resolve("{player} et {rival} !", values), "Sacha et Régis !")
	assert_eq(IntroScript.resolve("Sans jeton.", values), "Sans jeton.")
	assert_eq(IntroScript.resolve("{player}", {} as Dictionary[StringName, String]),
		"{player}")


# --- Lecteur ------------------------------------------------------------------------------

func test_reader_walks_the_real_script() -> void:
	var reader := _reader()
	assert_eq(reader.current().type, T.STAGE)
	assert_eq(reader.text(), "")
	assert_true(reader.advance())
	assert_eq(reader.text(), "Bonjour ! Bienvenue dans le monde des Pokémon !")
	_skip(reader)
	assert_eq(reader.current().type, T.PROMPT)
	assert_eq(reader.text(), "Comment t'appelles-tu ?")
	assert_eq(reader.prefill(), "")
	assert_eq(reader.portraits_on_stage(), _stage({&"player": &"left"}))


func test_reader_refuses_wrong_actions() -> void:
	var reader := _reader()
	assert_false(reader.answer_prompt("Kevin"), "pas sur un prompt")
	assert_false(reader.answer_confirm(true), "pas sur une confirmation")
	_skip(reader)
	var index := reader.index()
	assert_false(reader.advance(), "un prompt ne s'avance pas d'un toucher")
	assert_false(reader.answer_confirm(true))
	assert_eq(reader.index(), index)


func test_reader_rejects_invalid_names() -> void:
	var reader := _reader()
	_skip(reader)
	var index := reader.index()
	for bad: String in ["", "   ", "R2D2", "Maximilienne", "😀"]:
		assert_false(reader.answer_prompt(bad), bad)
	assert_eq(reader.index(), index)
	assert_eq(reader.player_name(), "")


func test_reader_normalizes_and_confirms() -> void:
	var reader := _reader()
	_skip(reader)
	assert_true(reader.answer_prompt("  sacha  "))
	assert_eq(reader.player_name(), "Sacha")
	assert_eq(reader.current().type, T.CONFIRM)
	assert_eq(reader.text(), "Sacha ! C'est bien ça ?")


func test_reader_no_returns_to_prompt_with_prefill() -> void:
	var reader := _reader()
	_skip(reader)
	var prompt_index := reader.index()
	reader.answer_prompt("Sacha")
	assert_true(reader.answer_confirm(false))
	assert_eq(reader.index(), prompt_index)
	assert_eq(reader.current().type, T.PROMPT)
	assert_eq(reader.prefill(), "Sacha", "champ déjà rempli")
	assert_true(reader.answer_prompt("Red"))
	assert_eq(reader.text(), "Red ! C'est bien ça ?")
	assert_true(reader.answer_confirm(true))
	assert_eq(reader.player_name(), "Red")


func test_reader_full_run_resolves_both_names() -> void:
	var reader := _reader()
	var shown: Array[String] = []
	var answers := {IntroScript.PROMPT_PLAYER_NAME: "Kevin", IntroScript.PROMPT_RIVAL_NAME: "gary"}
	var guard := 0
	while not reader.is_finished() and guard < 200:
		guard += 1
		var entry := reader.current()
		if entry.type != T.STAGE:
			shown.append(reader.text())
		match entry.type:
			T.STAGE, T.PAGE:
				reader.advance()
			T.PROMPT:
				reader.answer_prompt(answers[entry.name])
			T.CONFIRM:
				reader.answer_confirm(true)
	assert_true(reader.is_finished())
	assert_eq(reader.player_name(), "Kevin")
	assert_eq(reader.rival_name(), "Gary")
	assert_true(shown.has("Gary ! C'est ça, bien sûr."))
	assert_true(shown.has("Kevin ! Ta propre aventure est sur le point de commencer."))
	assert_eq(shown.size(), _intro.text_count())
	assert_null(reader.current())
	assert_false(reader.advance(), "fini")


func test_reader_same_name_for_player_and_rival_is_allowed() -> void:
	var reader := _reader()
	_skip(reader)
	reader.answer_prompt("Red")
	reader.answer_confirm(true)
	_skip(reader)
	assert_true(reader.answer_prompt("Red"))
	assert_eq(reader.rival_name(), "Red")


func test_reader_rival_no_keeps_player_name() -> void:
	var reader := _reader()
	_skip(reader)
	reader.answer_prompt("Kevin")
	reader.answer_confirm(true)
	_skip(reader)
	reader.answer_prompt("Blue")
	reader.answer_confirm(false)
	assert_eq(reader.current().name, IntroScript.PROMPT_RIVAL_NAME)
	assert_eq(reader.prefill(), "Blue")
	assert_eq(reader.player_name(), "Kevin")
	assert_eq(reader.portraits_on_stage(), _stage({&"rival": &"left"}))
