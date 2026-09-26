extends GutTest
## CutsceneDirector (jalon 3B §2.4, T2) sur une mini-carte (PNJ de
## tests/fixtures/npcs/runner_map.json, déclencheur 2 × 1), avec un vrai joueur, un vrai
## DialogueRunner (texte instantané), une vraie DialogueBox, des StoryFlags neufs et une
## instance de scene_router.gd (map_factory, sans rideau). Scènes et dialogues d'essai en
## mémoire. Étapes wait, dialogue, face, set ; blocage dans l'image même ; déclenchement
## dans le moved, sans pas de plus direction tenue ; gardes (variante, transition, pas
## scripté).

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const NPCS := "res://tests/fixtures/npcs/"
const FRAME := 1.0 / 60.0
const TIMEOUT := 3.0
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run", &"interact",
]
## Mini-carte : départ (5, 8) ; déclencheur « grass » sur (5, 6) et (6, 6).
const START := Vector2i(5, 8)
const TRIGGER := Vector2i(5, 6)
const DIALOGUES := {
	"call": {"speaker": "???", "pages": ["Hé ! Attends !"]},
	"thought": {"narration": true, "pages": ["Je ne devrais pas aller là sans Pokémon."]},
}
const SCENES := {
	"grass": {"variants": [
		{"unless": ["met"], "steps": [
			{"wait": 0.2}, {"dialogue": "call"}, {"face": "player", "to": "down"},
			{"set": ["met"]},
		]},
		{"unless": ["starter"], "steps": [{"dialogue": "thought"}]},
	]},
	"timed": {"steps": [{"wait": 0.5}]},
	"face_direction": {"steps": [{"face": "player", "to": "left"}]},
	"face_actors": {"steps": [
		{"face": "mom", "to": "player"}, {"face": "rival", "to": "mom"},
		{"face": "player", "to": "rival"},
	]},
	"flag_then_dialogue": {"steps": [{"set": ["seen"]}, {"dialogue": "call"}]},
	"two_dialogues": {"steps": [
		{"dialogue": "call"}, {"wait": 0.3}, {"dialogue": "thought"},
	]},
	"not_yet": {"steps": [{"move": "player", "path": ["down"]}, {"set": ["after"]}]},
	"ghost": {"steps": [{"face": "nobody", "to": "down"}, {"set": ["after"]}]},
	"never": {"if": ["nope"], "steps": [{"wait": 0.1}]},
}

var _router: Node
var _world: Node2D
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _director: CutsceneDirector
var _flags: StoryFlags
var _map: GameMap


func before_each() -> void:
	var dialogues := DialogueLibrary.new()
	dialogues.add_from_dict(DIALOGUES, "test")
	var scenes := CutsceneLibrary.new()
	scenes.add_from_dict(SCENES, "test")
	_flags = StoryFlags.new()
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_world = Node2D.new()
	add_child_autofree(_world)
	_player = PLAYER_SCENE.instantiate() as Player
	autofree(_player)
	_box = BOX_SCENE.instantiate() as DialogueBox
	add_child_autofree(_box)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(dialogues, _flags, _box, _player)
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, _runner, _player, _router)
	_router.setup(_world, _player, null)
	_router.map_changed.connect(_director.set_map)
	_map = _router.start(&"runner_map", &"start", Vector2i.UP)
	_player.set_process(false)
	watch_signals(_director)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


## Carte 20 × 18 sans tuiles : PNJ du fixture (Maman (7, 4), rival (13, 4)…), départ
## (5, 8), déclencheur « grass » 2 × 1 ancré en (5, 6).
func _make_map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.name = "DirectorMap"
	map.map_id = map_id
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(START)
	map.get_node(^"Spawns").add_child(marker)
	var point := EventTriggerPoint.new()
	point.name = "Grass"
	point.position = Grid.cell_to_world(TRIGGER)
	point.size = Vector2i(2, 1)
	point.cutscene_id = &"grass"
	map.get_node(^"Triggers").add_child(point)
	return map


func _place(cell: Vector2i, facing: Vector2i) -> void:
	_player.enter_map(_map.get_grid(), cell, facing, _map.get_pixel_rect())


## Simule des images du joueur (entrées lues par Player._process) jusqu'à [param done].
func _simulate_until(done: Callable, max_seconds: float = 2.0) -> void:
	for i: int in roundi(max_seconds / FRAME):
		_player._process(FRAME)
		if done.call():
			return


func _simulate(seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		_player._process(FRAME)


## Termine le dialogue en cours par des touchers de la boîte (une image d'écart).
func _finish_dialogue() -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		_box.advance_requested.emit()
	assert_false(_runner.is_running(), "dialogue terminé")


func _await_scene_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


# --- play : blocage, signaux, fin ------------------------------------------------------

func test_play_blocks_player_in_the_same_frame_and_emits_started() -> void:
	assert_true(_player.is_input_enabled())
	assert_true(_director.play(&"timed"))
	assert_true(_player.is_blocked_by(CutsceneDirector.REASON), "bloqué dans l'appel même")
	assert_false(_player.is_input_enabled())
	assert_true(_director.is_running())
	assert_eq(_director.get_step_index(), 0)
	assert_signal_emitted_with_parameters(_director, "cutscene_started", [&"timed"])
	assert_signal_emitted_with_parameters(_director, "step_started", [0])
	await _await_scene_end()
	assert_true(_player.is_input_enabled(), "joueur libre à la fin")
	assert_eq(_director.get_step_index(), -1)
	assert_signal_emitted_with_parameters(_director, "cutscene_finished", [&"timed"])


func test_wait_lasts_the_requested_time() -> void:
	# Temps de jeu : somme des delta de chaque image du moteur tant que la scène tourne.
	var timing: Array[float] = [0.0, 0.0]  # [écoulé, image la plus longue]
	var count := func() -> void:
		if _director.is_running():
			var delta := get_process_delta_time()
			timing[0] += delta
			timing[1] = maxf(timing[1], delta)
	get_tree().process_frame.connect(count)
	_director.play(&"timed")
	await _await_scene_end()
	get_tree().process_frame.disconnect(count)
	assert_false(_director.is_running())
	assert_almost_eq(timing[0], 0.5, timing[1] + 0.001, "0,5 s à une image près")


func test_dialogue_step_waits_for_the_end_of_the_dialogue() -> void:
	assert_true(_director.play(&"grass"))
	assert_false(_runner.is_running(), "0,2 s de silence d'abord")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	assert_eq(_director.get_step_index(), 1)
	assert_eq(_runner.get_dialogue_id(), &"call")
	await wait_until(func() -> bool: return _box.is_open(), TIMEOUT)
	assert_eq(_box.get_speaker_text(), "???")
	assert_eq(_box.get_text(), "Hé ! Attends !")
	await wait_process_frames(10)
	assert_true(_director.is_running(), "la scène attend le dialogue")
	assert_eq(_director.get_step_index(), 1)
	assert_eq(_player.get_facing(), Vector2i.UP, "pas encore retourné")
	assert_false(_flags.has_flag(&"met"))
	await _finish_dialogue()
	await _await_scene_end()
	assert_eq(_player.get_facing(), Vector2i.DOWN, "retourné après le dialogue")
	assert_true(_flags.has_flag(&"met"))
	assert_true(_player.is_input_enabled())
	assert_signal_emit_count(_director, "cutscene_finished", 1)


func test_player_stays_blocked_between_two_dialogues() -> void:
	_director.play(&"two_dialogues")
	await wait_until(func() -> bool: return _box.is_open(), TIMEOUT)
	await _finish_dialogue()
	assert_true(_director.is_running())
	assert_eq(_director.get_step_index(), 1, "wait entre les deux dialogues")
	assert_false(_player.is_input_enabled(), "toujours bloqué par la scène")
	assert_true(_player.is_blocked_by(CutsceneDirector.REASON))
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	assert_eq(_runner.get_dialogue_id(), &"thought")
	await wait_until(func() -> bool: return _box.is_open(), TIMEOUT)
	await _finish_dialogue()
	await _await_scene_end()
	assert_true(_player.is_input_enabled())


func test_face_a_direction() -> void:
	assert_true(_director.play(&"face_direction"))
	assert_false(_director.is_running(), "étape synchrone : scène déjà finie")
	assert_eq(_player.get_facing(), Vector2i.LEFT)
	assert_true(_player.is_input_enabled())
	assert_signal_emitted(_director, "cutscene_finished")


func test_face_the_player_and_an_npc() -> void:
	var mom := _map.get_npc(&"mom")
	var rival := _map.get_npc(&"rival")
	_director.play(&"face_actors")
	# Maman (7, 4) → joueur (5, 8) : bas ; rival (13, 4) → Maman : gauche ; joueur → rival
	# (8, -4) : droite.
	assert_eq(mom.get_facing(), Vector2i.DOWN)
	assert_eq(rival.get_facing(), Vector2i.LEFT)
	assert_eq(_player.get_facing(), Vector2i.RIGHT)
	assert_push_error_count(0)


func test_set_raises_the_flag_before_the_next_step() -> void:
	_director.play(&"flag_then_dialogue")
	assert_true(_flags.has_flag(&"seen"))
	assert_true(_runner.is_running(), "étape suivante : le dialogue")
	await _finish_dialogue()
	await _await_scene_end()


func test_no_variant_returns_false_without_error() -> void:
	assert_false(_director.play(&"never"))
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled())
	assert_signal_not_emitted(_director, "cutscene_started")
	assert_push_error_count(0)


func test_unknown_cutscene_returns_false_with_error() -> void:
	assert_false(_director.play(&"missing"))
	assert_push_error("scène inconnue")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled())


func test_play_during_a_scene_returns_false() -> void:
	_director.play(&"timed")
	assert_false(_director.play(&"face_direction"))
	assert_eq(_player.get_facing(), Vector2i.UP, "la seconde scène ne joue rien")
	await _await_scene_end()
	assert_signal_emit_count(_director, "cutscene_started", 1)


func test_transition_lock_active_at_the_end_keeps_the_player_blocked() -> void:
	_player.set_input_enabled(false, Player.REASON_TRANSITION)
	_director.play(&"timed")
	await _await_scene_end()
	assert_false(_player.is_blocked_by(CutsceneDirector.REASON))
	assert_true(_player.is_blocked_by(Player.REASON_TRANSITION))
	assert_false(_player.is_input_enabled())
	_player.set_input_enabled(true)


func test_variant_depends_on_the_flags() -> void:
	_director.play(&"grass")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	assert_eq(_runner.get_dialogue_id(), &"call", "variante 1")
	await _finish_dialogue()
	await _await_scene_end()
	assert_true(_director.play(&"grass"))
	assert_eq(_runner.get_dialogue_id(), &"thought", "variante 2 (met levé)")
	await wait_until(func() -> bool: return _box.is_open(), TIMEOUT)
	assert_true(_box.is_narration())
	assert_eq(_box.get_speaker_text(), "")
	await _finish_dialogue()
	await _await_scene_end()
	_flags.set_flag(&"starter")
	assert_false(_director.play(&"grass"), "plus aucune variante")
	assert_push_error_count(0)


func test_step_not_played_yet_is_skipped_with_error() -> void:
	_director.play(&"not_yet")
	assert_push_error("pas encore jouée")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_eq(_player.get_cell(), START)
	assert_true(_player.is_input_enabled())


func test_unknown_actor_is_skipped_with_error() -> void:
	_director.play(&"ghost")
	assert_push_error("introuvable")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_false(_director.is_running())


func test_setup_again_abandons_the_scene_and_frees_the_player() -> void:
	_director.play(&"timed")
	_director.setup(CutsceneLibrary.new(), _flags, _runner, _player, _router)
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled())
	await wait_seconds(0.7)
	assert_signal_not_emitted(_director, "cutscene_finished")


# --- Déclencheur ------------------------------------------------------------------------

func test_trigger_starts_the_scene_in_moved_and_no_further_step_with_up_held() -> void:
	var seen: Array = []
	_player.moved.connect(func(cell: Vector2i) -> void:
		seen.append([cell, _director.is_running(),
			_player.is_blocked_by(CutsceneDirector.REASON)]))
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _director.is_running())
	assert_eq(_player.get_cell(), TRIGGER)
	assert_eq(seen, [[START + Vector2i.UP, false, false], [TRIGGER, true, true]])
	assert_signal_emitted_with_parameters(_director, "cutscene_started", [&"grass"])
	_simulate(1.0)
	assert_eq(_player.get_cell(), TRIGGER, "aucun pas de plus, move_up tenu")
	assert_false(_player.is_moving())
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_dialogue()
	await _await_scene_end()
	assert_eq(_player.get_facing(), Vector2i.DOWN)
	assert_true(_player.is_input_enabled())


func test_trigger_on_the_second_column_while_running() -> void:
	_place(TRIGGER + Vector2i(1, 2), Vector2i.UP)
	Input.action_press(&"run")
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _director.is_running())
	assert_eq(_player.get_cell(), TRIGGER + Vector2i.RIGHT)
	_simulate(1.0)
	assert_eq(_player.get_cell(), TRIGGER + Vector2i.RIGHT, "aucun pas de plus en courant")


func test_no_trigger_when_no_variant_applies() -> void:
	_flags.set_flag(&"met")
	_flags.set_flag(&"starter")
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _player.get_cell() == TRIGGER + Vector2i.UP)
	assert_signal_not_emitted(_director, "cutscene_started")
	assert_true(_player.is_input_enabled())
	assert_push_error_count(0)


func test_no_trigger_during_a_transition() -> void:
	_router._busy = true
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _player.get_cell() == TRIGGER + Vector2i.UP)
	_router._busy = false
	assert_signal_not_emitted(_director, "cutscene_started")


func test_no_trigger_on_a_scripted_step() -> void:
	_place(TRIGGER + Vector2i.DOWN, Vector2i.UP)
	_player.set_input_enabled(false, &"test")
	assert_true(_player._mover.start_step(Vector2i.UP), "pas scripté, joueur bloqué")
	_simulate_until(func() -> bool: return not _player.is_moving())
	assert_eq(_player.get_cell(), TRIGGER)
	assert_signal_not_emitted(_director, "cutscene_started")
	_player.set_input_enabled(true, &"test")
