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

var _box: DialogueBox
var _runner: DialogueRunner
var _flags: StoryFlags
var _player: Player
var _map: GameMap
var _library: DialogueLibrary


func before_each() -> void:
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
