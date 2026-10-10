extends GutTest
## Introduction du Prof. Chen (OUV.2, dossier 13 §4 plans 2 à 8, §5.5, §6, §7) : IntroPlayer sur
## le vrai script (`data/opening/oak_intro.json`), la vraie scène (IntroStage) et la boîte de
## dialogue du jeu, sans Boot. Textes du §6 dans l'ordre, prénoms résolus, scène à chaque plan,
## « Non » qui rouvre le champ prérempli, retour Android, et la **durée** de l'introduction en
## temps simulé (plafond de 90 s hors saisie, vitesse Normale).

const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const STAGE_SCENE := preload("res://game/ui/opening/intro_stage.tscn")
## Les 16 textes du §6 (version « petit-fils », option A), prénoms « Sacha » et « Régis ».
const TEXTS: Array[String] = [
	"Bonjour ! Bienvenue dans le monde des Pokémon !",
	"Je m'appelle Chen. Ici, on m'appelle le Professeur Pokémon.",
	"Ce monde est peuplé de créatures que l'on appelle Pokémon.",
	"Certains vivent à nos côtés. D'autres préfèrent les hautes herbes, les forêts ou la mer.",
	"Certains Dresseurs s'entraînent avec eux pour combattre. Moi… je passe mes journées à les "
		+ "observer.",
	"Mais parlons un peu de toi.",
	"Comment t'appelles-tu ?",
	"Sacha ! C'est bien ça ?",
	"Et lui, tu le connais depuis toujours. C'est mon petit-fils.",
	"Vous vous lancez des défis depuis que vous savez marcher.",
	"Il s'appelle… euh…",
	"Comment s'appelle-t-il, déjà ?",
	"Régis ! C'est ça, bien sûr.",
	"Sacha ! Ta propre aventure est sur le point de commencer.",
	"Un monde de rêves et de rencontres t'attend.",
	"Allez… en route !",
]
## Plafond de durée hors saisie (dossier 13 §4) et temps de lecture d'une page (estimation
## d'OUV.0 : 1,5 s par texte).
const CEILING := 90.0
const READ_SECONDS := 1.5

var _script: IntroScript
var _names: OpeningNames
var _box: DialogueBox
var _stage: IntroStage
var _intro: IntroPlayer
var _finished: Array = []
## Texte de la boîte à chaque étape de texte (dans l'ordre).
var _seen: Array[String] = []
## Portraits sur la scène au début de chaque étape de texte.
var _stages_seen: Array[Dictionary] = []


func before_all() -> void:
	_script = IntroScript.new()
	assert_true(_script.load_file(), str(_script.get_errors()))
	_names = OpeningNames.new()
	assert_true(_names.load_file(), str(_names.get_errors()))


func before_each() -> void:
	_finished.clear()
	_seen.clear()
	_stages_seen.clear()


func _start(stage_speed: float = 0.0, chars_per_second: float = 0.0,
		reduce_motion: bool = false, auto_start: bool = true) -> void:
	_box = BOX_SCENE.instantiate() as DialogueBox
	add_child_autofree(_box)
	_stage = STAGE_SCENE.instantiate() as IntroStage
	_stage.speed_scale = stage_speed
	_stage.reduce_motion = reduce_motion
	add_child_autofree(_stage)
	_intro = IntroPlayer.new()
	_intro.chars_per_second = chars_per_second
	add_child_autofree(_intro)
	_intro.setup(_script, _names, _stage, _box)
	_intro.finished.connect(func(player: String, rival: String) -> void:
		_finished.append([player, rival]))
	_intro.step_started.connect(_on_step_started)
	if auto_start:
		_intro.start()


func _on_step_started(index: int) -> void:
	var step := _script.step(index)
	if step.type != IntroStep.Type.STAGE:
		_stages_seen.append(_stage.get_on_stage())
		_seen.append(_box.get_text())


## Joue l'introduction en entier, images réelles (scène instantanée, texte d'un coup) :
## prénoms donnés, réponses Oui.
func _play_through(player: String, rival: String) -> void:
	var guard := 0
	while _finished.is_empty() and guard < 400:
		guard += 1
		if _intro.is_waiting_for_name():
			var reader := _intro.get_reader()
			var prompt := reader.current().name
			_intro.submit_name(player if prompt == IntroScript.PROMPT_PLAYER_NAME else rival)
		elif _intro.is_waiting_for_choice():
			_intro.answer(true)
		else:
			_intro.advance()
		await wait_process_frames(1)


func test_the_whole_introduction_shows_the_texts_of_the_dossier_in_order() -> void:
	_start()
	await _play_through("Sacha", "Régis")
	assert_eq(_finished, [["Sacha", "Régis"]])
	assert_eq(_seen, TEXTS)
	assert_false(_box.is_open(), "boîte fermée à la fin")


func test_every_text_is_said_by_professor_chen() -> void:
	_start()
	var speakers: Array[String] = []
	_intro.step_started.connect(func(_i: int) -> void:
		if _box.is_open():
			speakers.append(_box.get_speaker_text()))
	await _play_through("Red", "Blue")
	for speaker: String in speakers:
		assert_eq(speaker, "Prof. Chen")
	assert_gt(speakers.size(), 10)


## Plans 2 à 8 du storyboard (dossier 13 §4), relevés au début de chaque texte.
func test_the_stage_of_each_shot() -> void:
	_start()
	await _play_through("Sacha", "Régis")
	var expected: Array[Dictionary] = [
		{&"chen": &"center"}, {&"chen": &"center"},
		{&"chen": &"left", &"nidorino": &"right"}, {&"chen": &"left", &"nidorino": &"right"},
		{&"chen": &"left", &"nidorino": &"right"},
		{&"player": &"center"}, {&"player": &"left"}, {&"player": &"left"},
		{&"rival": &"center", &"chen": &"left"}, {&"rival": &"center", &"chen": &"left"},
		{&"rival": &"center", &"chen": &"left"},
		{&"rival": &"left"}, {&"rival": &"left"},
		{&"chen": &"center"}, {&"chen": &"center"}, {&"player": &"center"},
	]
	assert_eq(_stages_seen.size(), expected.size())
	for i: int in mini(expected.size(), _stages_seen.size()):
		assert_eq(_stages_seen[i], expected[i], "texte %d : « %s »" % [i + 1, TEXTS[i]])


func test_the_name_entry_opens_on_the_question_with_the_suggestions() -> void:
	_start()
	await _advance_until(func() -> bool: return _intro.is_waiting_for_name())
	var entry := _stage.get_name_entry()
	assert_true(entry.is_open())
	assert_eq(_box.get_text(), "Comment t'appelles-tu ?", "la question reste dans la boîte")
	assert_true(_box.is_open())
	var chips: Array[String] = []
	for chip: Button in entry.get_chips():
		chips.append(chip.text)
	assert_eq(chips, ["Red", "Sacha", "Kevin"] as Array[String])
	assert_eq(entry.get_text(), "", "premier passage : champ vide")
	assert_eq(entry.get_validate_button().text, "VALIDER")
	assert_true(entry.get_validate_button().disabled)
	assert_eq(_stage.get_on_stage(), {&"player": &"left"} as Dictionary[StringName, StringName],
		"le portrait nommé à gauche")


func test_an_invalid_name_is_refused_and_a_valid_one_is_normalized() -> void:
	_start()
	await _advance_until(func() -> bool: return _intro.is_waiting_for_name())
	assert_false(_intro.submit_name("   "), "vide")
	assert_false(_intro.submit_name("R2D2"), "chiffres")
	assert_false(_intro.submit_name("Abcdefghijk"), "trop long")
	assert_true(_intro.is_waiting_for_name())
	assert_true(_intro.submit_name("  jean  luc "))
	assert_eq(_intro.get_reader().player_name(), "Jean luc")
	assert_false(_stage.get_name_entry().is_open(), "l'écran de prénom se ferme")
	assert_eq(_box.get_text(), "Jean luc ! C'est bien ça ?")


func test_no_reopens_the_field_prefilled() -> void:
	_start()
	await _advance_until(func() -> bool: return _intro.is_waiting_for_name())
	var entry := _stage.get_name_entry()
	entry.type_text("Kevin")
	entry.get_validate_button().pressed.emit()
	await _advance_until(func() -> bool: return _intro.is_waiting_for_choice())
	assert_true(_box.is_choice_showing(), "Oui / Non : le choix à deux cartes")
	var cards := _box.get_choice_cards()
	assert_eq(Array(cards.get_texts()), ["Kevin ! C'est bien ça ?", "Non", "Oui"])
	cards.get_cancel_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(_intro.is_waiting_for_name(), "retour à la question")
	assert_true(entry.is_open())
	assert_eq(entry.get_text(), "Kevin", "champ prérempli")
	assert_eq(_box.get_text(), "Comment t'appelles-tu ?")
	assert_false(entry.get_validate_button().disabled)


func test_android_back_closes_the_keyboard_then_does_nothing() -> void:
	_start()
	await _advance_until(func() -> bool: return _intro.is_waiting_for_name())
	var line := _stage.get_name_entry().get_line_edit()
	line.grab_focus()
	assert_true(line.has_focus())
	assert_true(_intro.handle_back(), "le retour appartient à l'introduction")
	assert_false(line.has_focus(), "clavier fermé")
	assert_true(_intro.handle_back())
	assert_true(_intro.is_waiting_for_name(), "rien d'autre : pas de retour en arrière")


func test_touches_do_nothing_during_a_stage_move() -> void:
	_start(1.0)
	await wait_process_frames(1)
	assert_true(_intro.is_staging(), "Chen entre")
	_intro.advance()
	_intro.advance()
	assert_eq(_intro.get_reader().index(), 0, "aucune étape passée")


func test_reduced_motion_shortens_the_moves() -> void:
	_start(1.0, 0.0, true)
	await wait_process_frames(1)
	var holder := _stage.get_holder(&"chen")
	assert_not_null(holder)
	var picture := holder.get_node(^"Picture") as TextureRect
	assert_eq(picture.position.y, -UiTokens.INTRO_HEIGHT_ADULT, "pas de montée")


## Durée hors saisie, en temps simulé : texte à la vitesse Normale, 1,5 s de lecture par texte
## avant de toucher (ou de répondre), scène à vitesse 1 ; les prénoms sont donnés aussitôt.
func test_the_introduction_lasts_less_than_ninety_seconds_at_normal_speed() -> void:
	_start(1.0, UiTokens.DIALOG_CHARS_PER_SECOND, false, false)
	var seconds := await _simulated_duration()
	assert_eq(_finished, [["Sacha", "Régis"]])
	gut.p("Durée simulée de l'introduction (Normale) : %.1f s" % seconds)
	assert_lt(seconds, CEILING, "plafond de 90 s hors saisie (dossier 13 §4)")
	var estimate := _script.estimated_seconds(UiTokens.DIALOG_CHARS_PER_SECOND, READ_SECONDS,
		0.5, 5)
	assert_lt(seconds, estimate + 5.0, "proche de l'estimation d'OUV.0 (%.1f s)" % estimate)


func _simulated_duration() -> float:
	# Le lecteur est retiré du moteur avant de démarrer : ses tweens (attente des mouvements de
	# scène) naissent sous l'horloge simulée.
	var sim := FrameSim.new(get_tree(), [_intro])
	_intro.start()
	var read_left := READ_SECONDS
	while _finished.is_empty() and sim.elapsed() < 300.0:
		await sim.frame()
		if _intro.is_staging() or not _intro.is_text_complete():
			read_left = READ_SECONDS
			continue
		if _intro.is_waiting_for_name():
			var prompt := _intro.get_reader().current().name
			_intro.submit_name("Sacha" if prompt == IntroScript.PROMPT_PLAYER_NAME else "Régis")
			continue
		read_left -= FrameSim.STEP
		if read_left > 0.0:
			continue
		read_left = READ_SECONDS
		if _intro.is_waiting_for_choice():
			_intro.answer(true)
		elif _intro.is_running():
			_intro.advance()
	var seconds := sim.elapsed()
	gut.p("fin simulée : étape %d, mise en scène %s, texte complet %s, en cours %s" % [
		_intro.get_reader().index(), _intro.is_staging(), _intro.is_text_complete(),
		_intro.is_running()])
	sim.finish()
	return seconds


func _advance_until(done: Callable) -> void:
	var guard := 0
	while not done.call() and guard < 200:
		guard += 1
		_intro.advance()
		await wait_process_frames(1)
