extends GutTest
## DialogueRunner (jalon 3A §2.5, T3) avec la vraie DialogueBox, des StoryFlags neufs, les
## dialogues de tests/fixtures/dialogues/ (plus « rival », ajouté en mémoire) et une
## mini-carte dont les PNJ viennent de tests/fixtures/npcs/runner_map.json.
## Blocage du joueur dans l'image même de play, pages, avance (compléter, suivante),
## drapeaux levés avant dialogue_finished, variante suivante, erreurs, react, face_player,
## silence, blocage « transition » conservé.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const DIALOGUES := "res://tests/fixtures/dialogues/"
const NPCS := "res://tests/fixtures/npcs/"
const MOM_1 := "Bonjour ! Tu es enfin réveillé ?"
const MOM_2 := "J'ai laissé quelque chose à manger sur la table."
const MOM_AGAIN := "Tu sors ? Profite de cette belle journée."
## Rival, en mémoire (même forme que data/dialogues/rival_house.json).
const RIVAL := {
	"rival": {
		"speaker": "Rival",
		"variants": [{
			"unless": ["rival_met"], "set": ["rival_met"],
			"pages": [
				"Ah. Enfin réveillé.",
				{"text": "T'as choisi ton jour pour faire la grasse matinée.", "face_player": true},
				{"text": "Moi, je suis prêt.", "pause": 0.8},
			],
		}, {"pages": ["Quoi ?", "Va faire un tour. Tu comprendras."]}],
	},
}
const TIMEOUT := 3.0
## Textes de l'infirmière (dossier 09 §19).
const QUESTION := "Bonjour. Je m'occupe de ton équipe ?"
const HEALED := "Voilà. Tout le monde est en pleine forme."
const LATER := "Très bien. Reviens quand tu veux."

var _box: DialogueBox
var _runner: DialogueRunner
var _flags: StoryFlags
var _player: Player
var _map: GameMap
var _library: DialogueLibrary
## Gestionnaire d'actions des tests (T6) : déroulé et état au début de chaque action.
var _actions: Array[String] = []
var _action_seen: Array[Array] = []


func before_each() -> void:
	_actions = []
	_action_seen = []
	_library = DialogueLibrary.new()
	_library.load_dir(DIALOGUES)
	_library.add_from_dict(RIVAL, "test")
	_flags = StoryFlags.new()
	_map = _make_map()
	add_child_autofree(_map)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_player.set_process(false)
	_box = (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(_box)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(_library, _flags, _box, _player)
	watch_signals(_runner)


func after_each() -> void:
	Input.action_release(&"interact")


## Carte 20 × 18 sans tuiles, joueur au spawn « start » (13, 5), sous le rival.
func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "RunnerMap"
	map.map_id = &"runner_map"
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		map.add_child(node)
	(map.get_node(^"Entities") as Node2D).y_sort_enabled = true
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(Vector2i(13, 5))
	map.get_node(^"Spawns").add_child(marker)
	return map


func _visible_characters() -> int:
	return (_box.get_node(^"%Text") as Label).visible_characters


## Avance par un toucher sur la boîte (une image plus tard que play).
func _advance() -> void:
	_box.advance_requested.emit()


func _finish() -> void:
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)


func test_play_blocks_player_in_the_same_frame_and_shows_page_one() -> void:
	assert_true(_player.is_input_enabled())
	assert_true(_runner.play(&"mom"))
	assert_true(_player.is_blocked_by(DialogueRunner.REASON), "bloqué dans l'appel même")
	assert_false(_player.is_input_enabled())
	assert_signal_emitted_with_parameters(_runner, "dialogue_started", [&"mom"])
	assert_true(_runner.is_running())
	assert_true(_box.is_open())
	assert_eq(_box.get_speaker_text(), "Maman")
	assert_eq(_box.get_text(), MOM_1)
	assert_false(_box.is_narration())


func test_two_advances_complete_then_next_then_finish_sets_flag_before_signal() -> void:
	_runner.chars_per_second = 5.0
	var flag_at_signal: Array[bool] = []
	_runner.dialogue_finished.connect(func(_id: StringName) -> void:
		flag_at_signal.append(_flags.has_flag(&"mom_greeted")))
	_runner.play(&"mom")
	await wait_process_frames(1)
	assert_false(_runner.get_session().is_page_complete(), "page 1 en cours d'écriture")
	_advance()
	assert_true(_runner.get_session().is_page_complete(), "1re avance : page complétée")
	assert_eq(_visible_characters(), -1)
	assert_eq(_runner.get_session().get_page_index(), 0)
	assert_true(_box.is_continue_visible(), "« › » sur une page complète non finale")
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 1, "2e avance : page suivante")
	assert_eq(_box.get_text(), MOM_2)
	assert_false(_box.is_continue_visible())
	_advance()
	_advance()
	assert_false(_player.is_input_enabled(), "bloqué jusqu'à la fermeture de la boîte")
	await _finish()
	assert_signal_emitted_with_parameters(_runner, "dialogue_finished", [&"mom"])
	assert_eq(flag_at_signal, [true] as Array[bool], "mom_greeted levé avant le signal")
	assert_true(_player.is_input_enabled(), "joueur libéré")
	assert_false(_runner.is_running())
	assert_false(_box.is_open())


func test_second_play_uses_the_next_variant() -> void:
	_runner.play(&"mom")
	await wait_process_frames(1)
	_advance()
	_advance()
	await _finish()
	assert_true(_runner.play(&"mom"))
	assert_eq(_box.get_text(), MOM_AGAIN)
	assert_false(_runner.has_auto_variant(&"mom"), "la variante auto ne s'applique plus")


func test_has_auto_variant_follows_flags() -> void:
	assert_true(_runner.has_auto_variant(&"mom"))
	assert_false(_runner.has_auto_variant(&"leo"))
	assert_false(_runner.has_auto_variant(&"nobody"))
	_flags.set_flag(&"mom_greeted")
	assert_false(_runner.has_auto_variant(&"mom"))


func test_unknown_id_returns_false_with_error() -> void:
	assert_false(_runner.play(&"nobody"))
	assert_push_error("dialogue inconnu")
	assert_false(_runner.is_running())
	assert_true(_player.is_input_enabled())
	assert_signal_not_emitted(_runner, "dialogue_started")


func test_no_matching_variant_returns_false_with_error() -> void:
	_library.add_from_dict({"locked": {"if": ["never"], "pages": ["…"]}}, "test")
	assert_false(_runner.play(&"locked"))
	assert_push_error("aucune variante")
	assert_true(_player.is_input_enabled())


func test_play_during_a_dialogue_returns_false() -> void:
	assert_true(_runner.play(&"mom"))
	assert_false(_runner.play(&"leo"))
	assert_eq(_box.get_speaker_text(), "Maman")
	assert_signal_emit_count(_runner, "dialogue_started", 1)


func test_react_on_leo_page_calls_react_on_the_rattata() -> void:
	var rattata := _map.get_npc(&"leo_rattata")
	var leo := _map.get_npc(&"leo")
	watch_signals(rattata)
	watch_signals(leo)
	_runner.play(&"leo", leo, _map)
	assert_signal_not_emitted(rattata, "reacted", "pas de réaction en page 1")
	await wait_process_frames(1)
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 1)
	assert_signal_emit_count(rattata, "reacted", 1, "réaction au début de la page 2")
	assert_signal_not_emitted(leo, "reacted")


func test_face_player_turns_the_npc_on_that_page_only() -> void:
	var rival := _map.get_npc(&"rival")
	_runner.play(&"rival", rival, _map)
	assert_eq(rival.get_facing(), Vector2i.RIGHT, "page 1 : tourné vers ses affaires")
	await wait_process_frames(1)
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 1)
	assert_eq(rival.get_facing(), Vector2i.DOWN, "page 2 : se tourne vers le joueur")
	# Le joueur ne compte pas : même si le rival est retourné, la page 3 ne le tourne pas.
	rival.face(Vector2i.RIGHT)
	_advance()
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 2)
	assert_eq(rival.get_facing(), Vector2i.RIGHT, "page 3 : pas de face_player")
	_advance()
	await _finish()
	assert_eq(rival.get_facing(), Vector2i.RIGHT, "retourne à ses affaires")
	assert_true(_flags.has_flag(&"rival_met"))


func test_pause_shows_no_character_before_the_silence_ends() -> void:
	var rival := _map.get_npc(&"rival")
	_runner.play(&"rival", rival, _map)
	await wait_process_frames(1)
	_advance()
	_advance()
	# Le moteur ne pilote plus le lecteur : le temps passe à la main.
	_runner.set_process(false)
	assert_eq(_runner.get_session().get_page_index(), 2)
	assert_true(_runner.get_session().is_pausing())
	assert_eq(_visible_characters(), 0, "début du silence")
	_runner._process(0.5)
	assert_eq(_visible_characters(), 0, "toujours en silence après 0,5 s")
	assert_false(_box.is_continue_visible())
	_runner._process(0.4)
	assert_eq(_visible_characters(), -1, "texte affiché après 0,8 s")


func test_pause_with_typing_speed() -> void:
	_runner.chars_per_second = 10.0
	_library.add_from_dict({"quiet": {"pages": [{"text": "abcdef", "pause": 0.6}]}}, "test")
	_runner.play(&"quiet")
	_runner.set_process(false)
	_runner._process(0.55)
	assert_eq(_visible_characters(), 0)
	_runner._process(0.25)
	assert_eq(_visible_characters(), 2, "0,2 s d'écriture à 10 caractères/s")


func test_transition_block_survives_the_end_of_a_dialogue() -> void:
	_runner.play(&"leo", null, _map)
	_player.set_input_enabled(false, &"transition")
	await wait_process_frames(1)
	_advance()  # page 2 (silence)
	_advance()  # page 2 complétée
	_advance()  # fin
	await _finish()
	assert_false(_player.is_blocked_by(DialogueRunner.REASON))
	assert_true(_player.is_blocked_by(&"transition"))
	assert_false(_player.is_input_enabled(), "toujours bloqué par la transition")


func test_advance_in_the_frame_of_play_is_ignored() -> void:
	_runner.play(&"leo", null, _map)
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 0)
	assert_true(_runner.is_running())


func test_delay_blocks_now_and_opens_the_box_later() -> void:
	_runner.play(&"mom", null, null, 0.35)
	assert_false(_player.is_input_enabled())
	assert_false(_box.is_open(), "boîte pas encore ouverte")
	assert_null(_runner.get_session())
	_runner.set_process(false)
	_runner._process(0.2)
	assert_false(_box.is_open())
	_runner._process(0.2)
	assert_true(_box.is_open(), "ouverte après le délai")
	assert_eq(_box.get_text(), MOM_1)


## Clé « heal » (jalon 5 §3.11) : à la fin du dialogue, heal_requested est émis une seule fois,
## après la levée des drapeaux et avant dialogue_finished.
func test_heal_variant_emits_heal_requested_once_at_the_end() -> void:
	_library.add_from_dict({"nurse": {"speaker": "Maman",
		"pages": ["Tes Pokémon vont bien."], "heal": true}}, "test")
	var order: Array[String] = []
	_runner.heal_requested.connect(func() -> void: order.append("heal"))
	_runner.dialogue_finished.connect(func(_id: StringName) -> void: order.append("finished"))
	assert_true(_runner.play(&"nurse"))
	await wait_process_frames(1)
	_advance()  # page complétée
	_advance()  # fin
	await _finish()
	assert_eq(order, ["heal", "finished"] as Array[String],
		"heal_requested une fois, avant dialogue_finished")


## Un dialogue sans clé « heal » n'émet jamais heal_requested.
func test_a_plain_dialogue_never_heals() -> void:
	var healed: Array[bool] = []
	_runner.heal_requested.connect(func() -> void: healed.append(true))
	_runner.play(&"mom")
	await wait_process_frames(1)
	_advance()
	_advance()
	await _finish()
	assert_eq(healed.size(), 0, "aucun soin sans clé « heal »")


func test_interact_key_advances() -> void:
	_runner.play(&"leo", null, _map)
	await wait_process_frames(1)
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	assert_eq(_runner.get_session().get_page_index(), 1, "E fait passer à la page suivante")


# --- Indication « turn » (jalon 3B §2.7, T3) ----------------------------------------------

## Dialogues à « turn » (en mémoire) : joueur en (13, 5) tourné vers le haut, rival en
## (13, 4) tourné à droite, Rattata de Léo en (17, 9) tourné à droite.
const TURNS := {
	"turns": {"speaker": "Prof. Chen", "pages": [
		{"text": "Un.", "turn": {"rival": "left", "player": "rival"}},
		{"text": "Deux."},
		{"text": "Trois.", "turn": {"rival": "player", "player": "right"}},
	]},
	"turn_react": {"pages": [
		{"text": "Hop.", "turn": {"leo_rattata": "up"}, "react": "leo_rattata"},
	]},
	"turn_ghost": {"pages": [
		{"text": "Personne.", "turn": {"ghost": "up", "rival": "nobody"}},
		{"text": "Suite.", "turn": {"rival": "down"}},
	]},
}


func _add_turns() -> void:
	_library.add_from_dict(TURNS, "test")


func test_turn_turns_the_npc_then_the_player_at_the_start_of_that_page_only() -> void:
	_add_turns()
	var rival := _map.get_npc(&"rival")
	var order: Array = []
	_player.facing_changed.connect(func(_dir: Vector2i) -> void:
		order.append(["player", rival.get_facing()]))
	_player.face(Vector2i.LEFT)
	order.clear()
	assert_true(_runner.play(&"turns", null, _map))
	assert_eq(rival.get_facing(), Vector2i.LEFT, "page 1 : rival à gauche")
	assert_eq(_player.get_facing(), Vector2i.UP, "page 1 : joueur vers le rival")
	assert_eq(order, [["player", Vector2i.LEFT]], "le rival d'abord, puis le joueur")
	rival.face(Vector2i.RIGHT)
	await wait_process_frames(1)
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 1)
	assert_eq(rival.get_facing(), Vector2i.RIGHT, "page 2 : aucune orientation rejouée")
	_advance()
	assert_eq(_runner.get_session().get_page_index(), 2)
	assert_eq(rival.get_facing(), Vector2i.DOWN, "page 3 : rival vers le joueur")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "page 3 : joueur à droite")
	_advance()
	await _finish()
	assert_eq(rival.get_facing(), Vector2i.DOWN, "sans npc passé à play : il garde son orientation")
	assert_push_error_count(0)


func test_turn_is_applied_before_react() -> void:
	_add_turns()
	var rattata := _map.get_npc(&"leo_rattata")
	var facing_at_react: Array[Vector2i] = []
	rattata.reacted.connect(func() -> void: facing_at_react.append(rattata.get_facing()))
	_runner.play(&"turn_react", null, _map)
	assert_eq(facing_at_react, [Vector2i.UP] as Array[Vector2i], "tourné avant la réaction")
	await wait_process_frames(1)
	_advance()
	await _finish()


func test_turn_with_unknown_actor_or_target_warns_and_continues() -> void:
	_add_turns()
	var rival := _map.get_npc(&"rival")
	assert_true(_runner.play(&"turn_ghost", null, _map))
	assert_eq(rival.get_facing(), Vector2i.RIGHT, "cible inconnue : rien")
	assert_eq(_box.get_text(), "Personne.")
	await wait_process_frames(1)
	_advance()
	assert_eq(rival.get_facing(), Vector2i.DOWN, "la page suivante est jouée")
	_advance()
	await _finish()
	assert_push_error_count(0)


func test_turn_without_map_warns_and_continues() -> void:
	_add_turns()
	assert_true(_runner.play(&"turn_react"))
	assert_eq(_box.get_text(), "Hop.")
	await wait_process_frames(1)
	_advance()
	await _finish()
	assert_true(_player.is_input_enabled())


# --- Fins de variante : choix, action, scène (jalon 7 §3.3, T6) ---------------------------

## Infirmière du Centre (textes du dossier 09 §19), plus des variantes de test.
func _add_service_dialogues() -> void:
	assert_true(_library.add_from_dict({
		"nurse": {"speaker": "Infirmière", "pages": [QUESTION], "choice": {
			"confirm": "SOIGNER", "cancel": "PAS MAINTENANT", "confirm_action": "center_heal",
			"confirm_pages": [HEALED], "cancel_pages": [LATER]}},
		"mom_choice": {"speaker": "Maman", "pages": ["Je les soigne ?"], "choice": {
			"confirm": "OUI", "cancel": "NON", "confirm_action": "heal"}},
		"plain_choice": {"pages": ["Sûr ?"], "choice": {"confirm": "OUI", "cancel": "NON"}},
		"clerk": {"speaker": "Vendeur", "pages": ["Qu'est-ce qu'il te faut ?"],
			"action": "open_shop", "set": ["clerk_met"]},
		"terminal": {"narration": true, "action": "open_storage"},
		"oak_parcel_talk": {"speaker": "Prof. Chen", "pages": ["Tiens…"],
			"cutscene": "oak_parcel"},
	}, "test"))


## Gestionnaire d'actions des tests : note le début et la fin, l'état de la boîte et du
## joueur au début, et dure quelques images (comme le rituel du Centre).
func _slow_action(action: StringName) -> void:
	_actions.append("start:%s" % action)
	_action_seen.append([_box.is_open(), _player.is_blocked_by(DialogueRunner.REASON)])
	for i: int in 5:
		await get_tree().process_frame
	_actions.append("end:%s" % action)


func test_choice_is_requested_after_the_question_page_and_blocks_the_dialogue() -> void:
	_add_service_dialogues()
	var views: Array[ChoiceView] = []
	_runner.choice_requested.connect(func(view: ChoiceView) -> void: views.append(view))
	assert_true(_runner.play(&"nurse"))
	await wait_process_frames(1)
	assert_eq(views.size(), 0, "pas de choix avant la fin de la question")
	_advance()
	assert_eq(views.size(), 1, "un choix demandé après la dernière page")
	assert_eq(views[0].title, QUESTION, "la question dans le titre (voile plein cadre)")
	assert_eq(views[0].confirm_label, "SOIGNER")
	assert_eq(views[0].cancel_label, "PAS MAINTENANT")
	assert_true(_runner.is_awaiting_choice())
	assert_true(_box.is_open(), "la boîte garde la question")
	assert_eq(_box.get_text(), QUESTION)
	_advance()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_true(_runner.is_awaiting_choice(), "toucher ou `interact` n'avancent plus")
	assert_eq(views.size(), 1, "un seul choix demandé")
	assert_true(_runner.is_running())
	assert_true(_player.is_blocked_by(DialogueRunner.REASON))


func test_confirm_awaits_the_action_then_plays_the_confirm_pages() -> void:
	_add_service_dialogues()
	_runner.action_handler = _slow_action
	_runner.play(&"nurse")
	await wait_process_frames(1)
	_advance()
	_runner.choose(true)
	assert_eq(_actions, ["start:center_heal"] as Array[String], "action lancée tout de suite")
	assert_eq(_action_seen[0], [true, true], "boîte ouverte, joueur bloqué pendant l'action")
	assert_false(_runner.is_awaiting_choice())
	_advance()
	assert_eq(_box.get_text(), QUESTION, "rien n'avance pendant l'action")
	await wait_process_frames(8)
	assert_eq(_actions, ["start:center_heal", "end:center_heal"] as Array[String])
	assert_eq(_box.get_text(), HEALED, "pages de confirmation après l'action")
	assert_eq(_box.get_speaker_text(), "Infirmière")
	assert_true(_runner.is_running())
	_advance()
	await _finish()
	assert_true(_player.is_input_enabled(), "joueur rendu à la fin")
	assert_false(_box.is_open())


func test_cancel_plays_the_cancel_pages_without_any_action() -> void:
	_add_service_dialogues()
	_runner.action_handler = _slow_action
	var healed: Array[bool] = []
	_runner.heal_requested.connect(func() -> void: healed.append(true))
	_runner.play(&"nurse")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(false)
	assert_eq(_box.get_text(), LATER)
	_advance()
	await _finish()
	assert_eq(_actions.size(), 0, "aucune action")
	assert_eq(healed.size(), 0, "aucun soin")
	assert_true(_player.is_input_enabled())


func test_choose_without_a_pending_choice_does_nothing() -> void:
	_add_service_dialogues()
	_runner.action_handler = _slow_action
	_runner.choose(true)
	assert_false(_runner.is_running())
	_runner.play(&"nurse")
	await wait_process_frames(1)
	_runner.choose(true)
	assert_eq(_box.get_text(), QUESTION, "question pas finie : choose ignoré")
	assert_eq(_actions.size(), 0)
	_advance()
	await _runner.choose(false)
	_runner.choose(true)
	assert_eq(_actions.size(), 0, "une seule réponse par question")
	assert_eq(_box.get_text(), LATER)


func test_heal_as_a_choice_action_emits_heal_requested_once() -> void:
	_add_service_dialogues()
	var order: Array[String] = []
	_runner.heal_requested.connect(func() -> void: order.append("heal"))
	_runner.dialogue_finished.connect(func(_id: StringName) -> void: order.append("finished"))
	_runner.play(&"mom_choice")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(true)
	assert_eq(order, ["heal"] as Array[String], "soin demandé au moment du choix")
	await _finish()
	assert_eq(order, ["heal", "finished"] as Array[String])


func test_empty_answer_pages_end_the_dialogue() -> void:
	_add_service_dialogues()
	_runner.play(&"plain_choice")
	await wait_process_frames(1)
	_advance()
	_runner.choose(true)
	await _finish()
	assert_false(_runner.is_running())
	assert_true(_player.is_input_enabled())


## J15 (Pension) : la réponse au choix est émise une fois, avant l'action et les pages.
func test_choice_made_carries_the_answer_once_before_the_answer_pages() -> void:
	_add_service_dialogues()
	var answers: Array[bool] = []
	var text_at_answer: Array[String] = []
	_runner.choice_made.connect(func(confirmed: bool) -> void:
		answers.append(confirmed)
		text_at_answer.append(_box.get_text()))
	_runner.play(&"nurse")
	await wait_process_frames(1)
	_advance()
	_runner.choose(false)
	_runner.choose(true)
	assert_eq(answers, [false] as Array[bool], "une seule réponse")
	assert_eq(text_at_answer, [QUESTION] as Array[String], "avant les pages de la réponse")
	_advance()
	await _finish()


## J15 : jetons « de contexte » de la Pension dans la question (T-7 : « Ce sera {price} ₽. »),
## résolus au début du dialogue, choix demandé sur la question résolue.
func test_a_context_token_in_the_question_is_resolved() -> void:
	assert_true(_library.add_from_dict({"visit": {"pages": ["{pokemon} va bien.",
		"Ce sera {price} ₽."], "choice": {"confirm": "OUI", "cancel": "NON"}}}, "test"))
	_runner.token_values = func() -> Dictionary[StringName, String]:
		return {&"pokemon": "Rattata", &"price": "300"} as Dictionary[StringName, String]
	var views: Array[ChoiceView] = []
	_runner.choice_requested.connect(func(view: ChoiceView) -> void: views.append(view))
	_runner.play(&"visit")
	await wait_process_frames(1)
	assert_eq(_box.get_text(), "Rattata va bien.")
	_advance()
	assert_eq(_box.get_text(), "Ce sera 300 ₽.")
	_advance()
	assert_eq(views.size(), 1)
	if views.size() == 1:
		assert_eq(views[0].title, "Ce sera 300 ₽.")
	_runner.choose(true)
	await _finish()


func test_final_action_is_awaited_with_the_box_closed_before_the_player_is_released() -> void:
	_add_service_dialogues()
	_runner.action_handler = _slow_action
	var finished_after: Array[String] = []
	_runner.dialogue_finished.connect(func(_id: StringName) -> void:
		finished_after.assign(_actions))
	_runner.play(&"clerk")
	await wait_process_frames(1)
	_advance()
	await _finish()
	assert_eq(finished_after, ["start:open_shop", "end:open_shop"] as Array[String],
		"action attendue avant dialogue_finished")
	assert_eq(_action_seen[0], [false, true], "boîte fermée, joueur encore bloqué")
	assert_true(_flags.has_flag(&"clerk_met"), "drapeaux levés")
	assert_true(_player.is_input_enabled())


func test_action_without_handler_is_reported_and_the_dialogue_ends() -> void:
	_add_service_dialogues()
	_runner.play(&"clerk")
	await wait_process_frames(1)
	_advance()
	await _finish()
	assert_push_error("sans gestionnaire")
	assert_true(_player.is_input_enabled())


func test_variant_without_pages_runs_its_action_without_opening_the_box() -> void:
	_add_service_dialogues()
	_runner.action_handler = _slow_action
	assert_true(_runner.play(&"terminal"))
	assert_true(_runner.is_running(), "play rend la main avant la fin")
	assert_true(_player.is_blocked_by(DialogueRunner.REASON))
	await _finish()
	assert_eq(_actions, ["start:open_storage", "end:open_storage"] as Array[String])
	assert_eq(_action_seen[0], [false, true], "aucune boîte")
	assert_true(_player.is_input_enabled())


func test_cutscene_is_requested_right_after_the_dialogue_ends() -> void:
	_add_service_dialogues()
	var order: Array[String] = []
	_runner.dialogue_finished.connect(func(_id: StringName) -> void: order.append("finished"))
	_runner.cutscene_requested.connect(func(id: StringName) -> void:
		order.append("cutscene:%s" % id))
	_runner.play(&"oak_parcel_talk")
	await wait_process_frames(1)
	_advance()
	await _finish()
	await wait_process_frames(1)
	assert_eq(order, ["finished", "cutscene:oak_parcel"] as Array[String])
	assert_false(_runner.is_running(), "la scène pose son propre verrou")


# --- Jetons de texte (jalon 7 §3.6, T18) ---------------------------------------------------

const CHEN_LINE := "Un {first_wild_species}… Tu n'as pas perdu de temps."


func _add_token_dialogues() -> void:
	assert_true(_library.add_from_dict({
		"oak_records": {"speaker": "Prof. Chen", "pages": [
			"Tiens…", {"text": CHEN_LINE, "pause": 0.3}, "Ton voyage peut nous apprendre beaucoup.",
		]},
		"only_token": {"pages": [CHEN_LINE], "set": ["heard"]},
		"token_answer": {"pages": ["Sûr ?"], "choice": {"confirm": "OUI", "cancel": "NON",
			"confirm_pages": [CHEN_LINE, "Bien."]}},
	}, "test"), str(_library.get_errors()))


func _species_values(species: String) -> Callable:
	return func() -> Dictionary[StringName, String]:
		var values: Dictionary[StringName, String] = {}
		if not species.is_empty():
			values[DialogueTokens.FIRST_WILD_SPECIES] = species
		return values


## Tous les textes montrés par la boîte, page après page, jusqu'à la fin du dialogue.
func _play_all(id: StringName) -> Array[String]:
	var shown: Array[String] = []
	_runner.page_started.connect(func(_i: int) -> void: shown.append(_box.get_text()))
	assert_true(_runner.play(id))
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		_advance()
	assert_false(_runner.is_running())
	return shown


func test_token_resolved_with_its_value() -> void:
	_add_token_dialogues()
	_runner.token_values = _species_values("Roucool")
	var shown := await _play_all(&"oak_records")
	assert_eq(shown, ["Tiens…", "Un Roucool… Tu n'as pas perdu de temps.",
		"Ton voyage peut nous apprendre beaucoup."] as Array[String])


func test_page_omitted_when_its_token_has_no_value() -> void:
	_add_token_dialogues()
	_runner.token_values = _species_values("")
	var shown := await _play_all(&"oak_records")
	assert_eq(shown, ["Tiens…", "Ton voyage peut nous apprendre beaucoup."] as Array[String])
	assert_eq(_runner.get_session(), null)


func test_page_omitted_without_any_token_source() -> void:
	_add_token_dialogues()
	var shown := await _play_all(&"oak_records")
	assert_eq(shown.size(), 2, "sans token_values : aucune valeur, la page est omise")
	assert_push_error_count(0)


func test_every_page_omitted_ends_without_opening_the_box() -> void:
	_add_token_dialogues()
	var opened: Array[bool] = []
	_runner.page_started.connect(func(_i: int) -> void: opened.append(true))
	assert_true(_runner.play(&"only_token"))
	await _finish()
	assert_eq(opened.size(), 0, "aucune page")
	assert_false(_box.is_open())
	assert_true(_flags.has_flag(&"heard"), "la fin de la variante a lieu")
	assert_true(_player.is_input_enabled())


func test_answer_pages_are_resolved_too() -> void:
	_add_token_dialogues()
	_runner.token_values = _species_values("Rattata")
	_runner.play(&"token_answer")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(true)
	assert_eq(_box.get_text(), "Un Rattata… Tu n'as pas perdu de temps.")
	_runner.token_values = _species_values("")
	_advance()
	await _finish()
	_runner.play(&"token_answer")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(true)
	assert_eq(_box.get_text(), "Bien.", "réplique omise dans les pages de la réponse")


# --- Choix qui pose un drapeau (jalon-13.md §2.13, T16) --------------------------------------

func _add_flag_choice() -> void:
	assert_true(_library.add_from_dict({
		"recruit": {"speaker": "Sbire", "pages": ["Tu veux nous rejoindre ?"], "choice": {
			"confirm": "OUI", "cancel": "NON", "confirm_set": ["recruit_yes"],
			"cancel_set": ["recruit_no", "recruit_refused"]}},
	}, "test"))


func test_confirm_raises_only_the_confirm_flags_before_closing() -> void:
	_add_flag_choice()
	_runner.play(&"recruit")
	await wait_process_frames(1)
	_advance()
	assert_true(_runner.is_awaiting_choice())
	assert_false(_flags.has_flag(&"recruit_yes"), "rien avant le choix")
	await _runner.choose(true)
	assert_true(_flags.has_flag(&"recruit_yes"), "OUI → confirm_set, tout de suite")
	assert_false(_flags.has_flag(&"recruit_no"), "rien d'autre")
	assert_false(_flags.has_flag(&"recruit_refused"))
	await _finish()
	assert_eq(_flags.to_array(), [&"recruit_yes"] as Array[StringName], "un seul drapeau")


func test_cancel_raises_only_the_cancel_flags() -> void:
	_add_flag_choice()
	_runner.play(&"recruit")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(false)
	assert_true(_flags.has_flag(&"recruit_no"), "NON → cancel_set")
	assert_true(_flags.has_flag(&"recruit_refused"))
	assert_false(_flags.has_flag(&"recruit_yes"))
	await _finish()


func test_flags_are_raised_before_dialogue_finished() -> void:
	_add_flag_choice()
	var seen: Array[bool] = []
	_runner.dialogue_finished.connect(func(_id: StringName) -> void:
		seen.append(_flags.has_flag(&"recruit_yes")))
	_runner.play(&"recruit")
	await wait_process_frames(1)
	_advance()
	await _runner.choose(true)
	await _finish()
	assert_eq(seen, [true] as Array[bool], "levé avant la fin : les étapes suivantes le lisent")


# --- Jalon 17 (T4) : variantes selon les espèces capturées ---------------------------------

func _add_caught_dialogue() -> void:
	assert_true(_library.add_from_dict({"assistant": {"variants": [
		{"if_caught_at_least": 10, "pages": ["Ton Pokédex compte {caught} espèces !"]},
		{"pages": ["Ton Pokédex compte {caught} espèces capturées.",
			"Encore {caught_missing}, et c'est à toi."]},
	]}}, "test"))


func test_caught_count_picks_the_variant_and_fills_the_tokens() -> void:
	_add_caught_dialogue()
	var caught := [9]
	_runner.caught_count = func() -> int: return caught[0]
	_runner.token_values = func() -> Dictionary[StringName, String]:
		return DialogueTokens.caught_values(caught[0])
	assert_eq(await _play_all(&"assistant"), ["Ton Pokédex compte 9 espèces capturées.",
		"Encore 1, et c'est à toi."] as Array[String])
	caught[0] = 10
	assert_eq(await _play_all(&"assistant"), ["Ton Pokédex compte 10 espèces !"]
		as Array[String], "compte relu à chaque dialogue")


func test_without_caught_count_source_the_count_is_zero() -> void:
	_add_caught_dialogue()
	_runner.token_values = func() -> Dictionary[StringName, String]:
		return DialogueTokens.caught_values(0)
	assert_eq((await _play_all(&"assistant"))[0], "Ton Pokédex compte 0 espèces capturées.")
