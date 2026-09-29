extends GutTest
## CutsceneDirector (jalon 3B §2.4, T2) sur une mini-carte (PNJ de
## tests/fixtures/npcs/runner_map.json, déclencheur 2 × 1), avec un vrai joueur, un vrai
## DialogueRunner (texte instantané), une vraie DialogueBox, des StoryFlags neufs et une
## instance de scene_router.gd (map_factory, sans rideau). Scènes et dialogues d'essai en
## mémoire. Étapes wait, dialogue, face, set ; blocage dans l'image même ; déclenchement
## dans le moved, sans pas de plus direction tenue ; gardes (variante, transition, pas
## scripté). T3 : spawn, move (chemin écrit, case absolue, voisine d'un acteur, course,
## blocage), variante 2 (pensée puis un pas vers le bas). T4 : suiveur d'une étape move,
## change_map (PNJ de la nouvelle carte, échec du routeur).
## Jalon 4 (T1) : alias résolus à chaque étape (face, move, near, follower, hop, lean,
## despawn), alias absent (étape sautée), hop (attend la fin du saut, refus), lean (aller et
## retour sans changer de case), despawn (case libérée, PNJ retiré).
## Jalon 4B (jalon-04.md §14.3) : conditions d'étape « if » / « unless », évaluées au moment
## de jouer l'étape (drapeaux levés plus tôt dans la même scène compris).

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
		{"unless": ["starter"], "steps": [
			{"dialogue": "thought"}, {"move": "player", "path": ["down"]},
		]},
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
	"to_lab": {"steps": [
		{"change_map": "lab_map", "at": "start", "facing": "left"},
		{"face": "oak", "to": "player"}, {"set": ["after"]},
	]},
	"to_lab_then_mom": {"steps": [
		{"change_map": "lab_map", "at": "start"}, {"face": "mom", "to": "down"},
		{"set": ["after"]},
	]},
	"to_missing": {"steps": [
		{"change_map": "missing_map", "at": "start"}, {"set": ["after"]},
	]},
	"mom_leads": {"steps": [
		{"move": "mom", "follower": "player", "path": ["down", "down", "down", "left"]},
		{"set": ["after"]},
	]},
	"spawn_oak": {"steps": [
		{"spawn": "oak", "sprite": "oak", "cell": [5, 15], "facing": "up"},
	]},
	"oak_runs_to_player": {"steps": [
		{"spawn": "oak", "sprite": "oak", "cell": [5, 15], "facing": "up"},
		{"move": "oak", "run": true,
			"to": {"near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]]}},
		{"set": ["arrived"]},
	]},
	"mom_walks_to": {"steps": [{"move": "mom", "to": [9, 6]}, {"set": ["after"]}]},
	"mom_path": {"steps": [{"move": "mom", "path": ["down", "down", "left"]}]},
	"player_path": {"steps": [{"move": "player", "path": ["down", "right"]}]},
	"mom_blocked": {"steps": [{"move": "mom", "path": ["down"]}, {"set": ["after"]}]},
	"ghost_move": {"steps": [{"move": "nobody", "path": ["down"]}, {"set": ["after"]}]},
	"spawn_taken": {"steps": [
		{"spawn": "oak", "sprite": "oak", "cell": [7, 4]}, {"set": ["after"]},
	]},
	"ghost": {"steps": [{"face": "nobody", "to": "down"}, {"set": ["after"]}]},
	"never": {"if": ["nope"], "steps": [{"wait": 0.1}]},
	"alias_each_step": {"steps": [
		{"face": "player", "to": "down"},
		{"face": "$buddy", "to": "player"},
		{"face": "player", "to": "$buddy"},
		{"move": "$buddy", "path": ["down", "down", "down", "down", "right", "right", "right"]},
		{"face": "player", "to": "$buddy"},
		{"face": "$buddy", "to": "player"},
		{"set": ["after"]},
	]},
	"alias_near_and_follower": {"steps": [
		{"move": "rival", "to": {"near": "$buddy", "offsets": [[0, 1]]}},
		{"move": "$leader", "follower": "$pal", "path": ["left", "left"]},
		{"set": ["after"]},
	]},
	"alias_missing": {"steps": [{"face": "$ghost", "to": "down"}, {"set": ["after"]}]},
	"hop_buddy": {"steps": [
		{"hop": "$buddy", "to": {"near": "$buddy", "offsets": [[0, 1]]}}, {"set": ["after"]},
	]},
	"hop_taken": {"steps": [{"hop": "mom", "to": [13, 4]}, {"set": ["after"]}]},
	"lean_buddy": {"steps": [{"lean": "$buddy", "to": "player"}, {"set": ["after"]}]},
	"despawn_buddy": {"steps": [{"despawn": "$buddy"}, {"set": ["after"]}]},
	"after_battle": {"steps": [
		{"set": ["won"]},
		{"set": ["won_line"], "if": ["won"]},
		{"set": ["lost_line"], "if": ["lost"]},
		{"set": ["not_won_line"], "unless": ["won"]},
		{"face": "player", "to": "left", "if": ["lost"]},
		{"set": ["after"]},
	]},
	"battle_scene": {"steps": [
		{"battle": "rival_lab", "player_pokemon": "$mine", "foe_pokemon": "$foe",
			"win": ["won_flag"], "lose": ["lost_flag"]},
		{"set": ["after"]},
	]},
	"give_scene": {"steps": [
		{"give": "poke_ball", "count": 5}, {"set": ["after"]},
	]},
	"give_unknown": {"steps": [
		{"give": "mystery", "count": 2}, {"set": ["after"]},
	]},
}


## Faux directeur de combat : renvoie une issue imposée, enregistre l'appel, laisse passer
## une image (coroutine) pour vérifier que l'étape « battle » attend la fin.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.WIN
	var calls: Array = []
	var finished: bool = false

	func run(trainer_id: StringName, map: GameMap,
			world_actors: Dictionary[StringName, StringName]) -> int:
		calls.append([trainer_id, world_actors.duplicate(), map])
		finished = false
		await get_tree().process_frame
		await get_tree().process_frame
		finished = true
		return outcome_to_return

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
	_router.map_factory = func(map_id: StringName) -> GameMap:
		return null if map_id == &"missing_map" else _make_map(map_id)
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
	_player.set_process(true)
	assert_true(_director.play(&"grass"))
	assert_eq(_runner.get_dialogue_id(), &"thought", "variante 2 (met levé)")
	await wait_until(func() -> bool: return _box.is_open(), TIMEOUT)
	assert_true(_box.is_narration())
	assert_eq(_box.get_speaker_text(), "")
	await _finish_dialogue()
	await _await_scene_end()
	assert_eq(_player.get_cell(), START + Vector2i.DOWN, "recul d'un pas")
	_flags.set_flag(&"starter")
	assert_false(_director.play(&"grass"), "plus aucune variante")
	assert_push_error_count(0)


# --- change_map (T4) -----------------------------------------------------------------

func test_change_map_then_the_next_steps_target_the_npcs_of_the_new_map() -> void:
	var old_map := _map
	assert_true(_director.play(&"to_lab"))
	await _await_scene_end()
	var lab := _router.get_current_map() as GameMap
	assert_eq(lab.map_id, &"lab_map")
	assert_ne(lab, old_map)
	assert_eq(_player.get_parent(), lab.get_entities())
	assert_eq(_player.get_cell(), START, "au point d'apparition")
	assert_eq(_player.get_facing(), Vector2i.LEFT, "orientation demandée")
	# Chen (8, 4) → joueur (5, 8) : axe vertical dominant, vers le bas.
	assert_eq(lab.get_npc(&"oak").get_facing(), Vector2i.DOWN, "PNJ de la nouvelle carte")
	assert_true(_flags.has_flag(&"after"))
	assert_true(_player.is_input_enabled(), "transition et scène terminées")
	assert_false(_player.is_blocked_by(Player.REASON_TRANSITION))
	assert_push_error_count(0)


func test_change_map_keeps_the_player_blocked_during_the_transition() -> void:
	var seen: Array = []
	_router.map_changed.connect(func(_m: GameMap) -> void:
		seen.append([_player.is_blocked_by(CutsceneDirector.REASON),
			_player.is_blocked_by(Player.REASON_TRANSITION)]))
	_director.play(&"to_lab")
	await _await_scene_end()
	assert_eq(seen, [[true, true]], "scène et transition tiennent le joueur")


func test_after_change_map_the_npcs_of_the_old_map_are_gone() -> void:
	_director.play(&"to_lab_then_mom")
	await _await_scene_end()
	assert_push_error("introuvable")
	assert_true(_flags.has_flag(&"after"), "la scène continue")


func test_change_map_failure_stops_the_scene_and_frees_the_player() -> void:
	var old_map := _map
	_director.play(&"to_missing")
	await _await_scene_end()
	assert_push_error("carte inconnue")
	assert_push_error("manqué")
	assert_false(_flags.has_flag(&"after"), "scène arrêtée")
	assert_false(_director.is_running())
	assert_same(_router.get_current_map(), old_map, "toujours sur la carte de départ")
	assert_true(_player.is_input_enabled(), "joueur libéré")
	assert_signal_emit_count(_director, "cutscene_finished", 1)


# --- Suiveur (T4) ----------------------------------------------------------------------

func test_follower_stays_one_step_behind_and_ends_on_the_leader_second_to_last_cell() -> void:
	# Maman (7, 4) mène ; le joueur, à sa gauche en (6, 4), suit.
	_place(Vector2i(6, 4), Vector2i.RIGHT)
	_player.set_process(true)
	var mom := _map.get_npc(&"mom")
	var leader_cells: Array[Vector2i] = [mom.get_cell()]
	var follower_cells: Array[Vector2i] = []
	var gaps: Array[int] = []
	mom.step_finished.connect(func(cell: Vector2i) -> void: leader_cells.append(cell))
	_player.moved.connect(func(cell: Vector2i) -> void: follower_cells.append(cell))
	var watch := func() -> void:
		# Cases de départ pendant un pas (GridMover.get_cell), cases d'arrêt sinon.
		if _director.is_running():
			var gap := mom.get_cell() - _player.get_cell()
			gaps.append(absi(gap.x) + absi(gap.y))
	get_tree().process_frame.connect(watch)
	await _play_timed(&"mom_leads")
	get_tree().process_frame.disconnect(watch)
	assert_eq(leader_cells, [Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7),
		Vector2i(6, 7)] as Array[Vector2i])
	assert_eq(follower_cells, leader_cells.slice(0, 4), "chaque case que le meneur quitte")
	assert_eq(_player.get_cell(), Vector2i(7, 7), "avant-dernière case du meneur")
	assert_eq(mom.get_cell(), Vector2i(6, 7))
	assert_false(gaps.is_empty())
	for gap: int in gaps:
		assert_eq(gap, 1, "toujours un pas derrière")
	assert_true(_flags.has_flag(&"after"), "l'étape attend les deux")
	assert_true(_player.is_input_enabled())
	assert_push_error_count(0)


func test_follower_steps_in_the_same_frame_as_the_leader() -> void:
	_place(Vector2i(6, 4), Vector2i.RIGHT)
	_player.set_process(true)
	var mom := _map.get_npc(&"mom")
	var starts: Array = []
	var watch := func() -> void:
		starts.append([mom.is_moving(), _player.is_moving()])
	get_tree().process_frame.connect(watch)
	await _play_timed(&"mom_leads")
	get_tree().process_frame.disconnect(watch)
	for pair: Array in starts:
		assert_eq(pair[0], pair[1], "meneur et suiveur partent et s'arrêtent ensemble")


func test_follower_not_next_to_the_leader_is_ignored_with_error() -> void:
	var mom := _map.get_npc(&"mom")
	await _play_timed(&"mom_leads")
	assert_push_error("pas à côté")
	assert_eq(mom.get_cell(), Vector2i(6, 7), "le meneur marche seul")
	assert_eq(_player.get_cell(), START)
	assert_true(_flags.has_flag(&"after"))


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
	assert_true(_player.script_step(Vector2i.UP), "pas scripté, joueur bloqué")
	_simulate_until(func() -> bool: return not _player.is_moving())
	assert_eq(_player.get_cell(), TRIGGER)
	assert_signal_not_emitted(_director, "cutscene_started")
	_player.set_input_enabled(true, &"test")


# --- spawn et move (T3) -------------------------------------------------------------------

## Temps de jeu d'une scène (somme des delta tant qu'elle tourne), joueur animé par le
## moteur (aucune entrée tenue).
func _play_timed(cutscene_id: StringName) -> float:
	var elapsed: Array[float] = [0.0]
	var count := func() -> void:
		if _director.is_running():
			elapsed[0] += get_process_delta_time()
	get_tree().process_frame.connect(count)
	assert_true(_director.play(cutscene_id))
	await _await_scene_end()
	get_tree().process_frame.disconnect(count)
	return elapsed[0]


func test_spawn_creates_the_npc_on_its_cell() -> void:
	_director.play(&"spawn_oak")
	var oak := _map.get_npc(&"oak")
	assert_not_null(oak)
	if oak == null:
		return
	assert_eq(oak.get_cell(), Vector2i(5, 15))
	assert_eq(oak.get_facing(), Vector2i.UP)
	assert_same(_map.get_grid().get_occupant(Vector2i(5, 15)), oak)
	assert_eq(oak.get_parent(), _map.get_entities())
	assert_false(_director.is_running())
	assert_push_error_count(0)


func test_spawn_on_a_taken_cell_is_skipped_with_error() -> void:
	_director.play(&"spawn_taken")
	assert_push_error("occupée")
	assert_null(_map.get_npc(&"oak"))
	assert_true(_flags.has_flag(&"after"), "la scène continue")


func test_move_near_the_player_runs_along_find_path_and_waits_for_arrival() -> void:
	# Joueur en (5, 8) : première case libre parmi (6, 8), (4, 8), (5, 9) → (6, 8).
	var expected_goal := Vector2i(6, 8)
	var oak_cells: Array[Vector2i] = []
	_director.step_started.connect(func(index: int) -> void:
		if index == 1:
			var oak := _map.get_npc(&"oak")
			var path := _map.get_grid().find_path(oak.get_cell(), expected_goal, oak)
			oak_cells.append_array(CutsceneMoves.path_cells(oak.get_cell(), path))
			oak.step_finished.connect(func(cell: Vector2i) -> void: oak_cells.append(cell)))
	var elapsed: float = await _play_timed(&"oak_runs_to_player")
	var oak := _map.get_npc(&"oak")
	assert_eq(oak.get_cell(), expected_goal)
	assert_false(oak.is_moving())
	assert_true(_flags.has_flag(&"arrived"), "étape suivante après l'arrivée")
	# Première moitié : le chemin attendu ; seconde : les cases réellement atteintes.
	var half := oak_cells.size() / 2
	assert_gt(half, 0)
	assert_eq(oak_cells.slice(half), oak_cells.slice(0, half), "suit find_path")
	var steps := half
	assert_almost_eq(elapsed, steps * Grid.RUN_STEP_DURATION, 0.1 + steps * 0.02,
		"%d pas en courant" % steps)
	assert_eq(_player.get_cell(), START, "le joueur n'a pas bougé")
	assert_push_error_count(0)


func test_move_to_an_absolute_cell() -> void:
	var mom := _map.get_npc(&"mom")
	var path := _map.get_grid().find_path(mom.get_cell(), Vector2i(9, 6), mom)
	var elapsed: float = await _play_timed(&"mom_walks_to")
	assert_eq(mom.get_cell(), Vector2i(9, 6))
	assert_true(_flags.has_flag(&"after"))
	assert_almost_eq(elapsed, path.size() * Grid.WALK_STEP_DURATION, 0.1 + path.size() * 0.02,
		"%d pas en marchant" % path.size())
	assert_false(_map.get_grid().is_occupied(Vector2i(7, 4)), "case de départ libérée")
	assert_push_error_count(0)


func test_move_along_a_written_path() -> void:
	var mom := _map.get_npc(&"mom")
	await _play_timed(&"mom_path")
	assert_eq(mom.get_cell(), Vector2i(6, 6))
	assert_eq(mom.get_facing(), Vector2i.LEFT)


func test_move_the_player_along_a_path_while_blocked() -> void:
	_player.set_process(true)
	var seen: Array = []
	_player.moved.connect(func(cell: Vector2i) -> void:
		seen.append([cell, _player.is_blocked_by(CutsceneDirector.REASON)]))
	await _play_timed(&"player_path")
	assert_eq(_player.get_cell(), START + Vector2i(1, 1))
	assert_eq(seen, [[START + Vector2i.DOWN, true], [START + Vector2i(1, 1), true]])
	assert_true(_player.is_input_enabled())
	assert_signal_emit_count(_director, "cutscene_started", 1, "pas de scène relancée")


func test_move_blocked_longer_than_the_timeout_is_abandoned_with_error() -> void:
	var blocker := RefCounted.new()
	_map.get_grid().occupy(Vector2i(7, 5), blocker)
	var elapsed: float = await _play_timed(&"mom_blocked")
	assert_push_error("bloqué")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_almost_eq(elapsed, CutsceneDirector.MOVE_BLOCK_TIMEOUT, 0.2, "abandonné au délai")
	assert_eq(_map.get_npc(&"mom").get_cell(), Vector2i(7, 4))


func test_move_resumes_when_the_cell_frees_up_before_the_timeout() -> void:
	var blocker := RefCounted.new()
	_map.get_grid().occupy(Vector2i(7, 5), blocker)
	_director.play(&"mom_blocked")
	await wait_seconds(0.5)
	assert_true(_director.is_running())
	_map.get_grid().release(Vector2i(7, 5), blocker)
	await _await_scene_end()
	assert_eq(_map.get_npc(&"mom").get_cell(), Vector2i(7, 5))
	assert_push_error_count(0)


func test_move_with_unknown_actor_is_skipped_with_error() -> void:
	_director.play(&"ghost_move")
	assert_push_error("introuvable")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_false(_director.is_running())


# --- alias, hop, lean, despawn (jalon 4, T1) ---------------------------------------------

func test_alias_is_resolved_at_each_step() -> void:
	var mom := _map.get_npc(&"mom")
	var facings: Array[Vector2i] = []
	_director.step_started.connect(func(index: int) -> void:
		if index == 3 or index == 6:
			facings.append(_player.get_facing()))
	assert_true(_director.play(&"alias_each_step", {&"buddy": &"mom"}))
	# Maman (7, 4) → joueur (5, 8) : bas ; joueur → Maman (2, -4) : haut.
	assert_eq(mom.get_facing(), Vector2i.DOWN, "alias dans l'acteur de face")
	await _await_scene_end()
	assert_eq(facings[0], Vector2i.UP, "alias dans la cible de face")
	assert_eq(mom.get_cell(), Vector2i(10, 8), "alias dans l'acteur de move")
	# Maman a bougé : l'alias désigne sa nouvelle case (10, 8) → joueur regarde à droite.
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "cible résolue sur la case actuelle")
	assert_eq(mom.get_facing(), Vector2i.LEFT)
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


func test_alias_in_near_and_follower() -> void:
	var rival := _map.get_npc(&"rival")
	var leo := _map.get_npc(&"leo")
	var rattata := _map.get_npc(&"leo_rattata")
	_director.play(&"alias_near_and_follower",
		{&"buddy": &"mom", &"leader": &"leo_rattata", &"pal": &"leo"})
	await _await_scene_end()
	assert_eq(rival.get_cell(), Vector2i(7, 5), "voisin résolu : sous Maman")
	assert_eq(rattata.get_cell(), Vector2i(15, 9), "meneur résolu")
	assert_eq(leo.get_cell(), Vector2i(16, 9), "suiveur résolu, un pas derrière")
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


func test_missing_alias_skips_the_step_with_error() -> void:
	assert_true(_director.play(&"alias_missing", {&"buddy": &"mom"}))
	assert_push_error("alias « $ghost » absent")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_false(_director.is_running())
	assert_true(_player.is_input_enabled())


func test_aliases_are_forgotten_after_the_scene() -> void:
	_director.play(&"lean_buddy", {&"buddy": &"mom"})
	await _await_scene_end()
	_flags.clear()
	_director.play(&"lean_buddy")
	assert_push_error("alias « $buddy » absent")
	assert_true(_flags.has_flag(&"after"))


func test_hop_waits_for_the_end_of_the_jump() -> void:
	var mom := _map.get_npc(&"mom")
	var elapsed: Array[float] = [0.0]
	var count := func() -> void:
		if _director.is_running():
			elapsed[0] += get_process_delta_time()
	get_tree().process_frame.connect(count)
	assert_true(_director.play(&"hop_buddy", {&"buddy": &"mom"}))
	assert_true(mom.is_hopping(), "saut lancé dans l'appel même")
	assert_false(_map.get_grid().is_occupied(Vector2i(7, 4)), "case quittée libérée")
	assert_same(_map.get_grid().get_occupant(Vector2i(7, 5)), mom, "arrivée réservée")
	await wait_process_frames(3)
	assert_true(_director.is_running(), "la scène attend le saut")
	assert_false(_flags.has_flag(&"after"))
	await _await_scene_end()
	get_tree().process_frame.disconnect(count)
	assert_false(mom.is_hopping())
	assert_eq(mom.get_cell(), Vector2i(7, 5))
	assert_true(_flags.has_flag(&"after"))
	var expected := Npc.hop_total_duration(mom.get_spec().hop_style)
	assert_almost_eq(elapsed[0], expected, 0.1, "durée du saut (%.2f s)" % expected)
	assert_push_error_count(0)


func test_hop_refused_is_skipped_with_error() -> void:
	var mom := _map.get_npc(&"mom")
	_director.play(&"hop_taken")
	assert_push_error("refusé")
	assert_eq(mom.get_cell(), Vector2i(7, 4))
	assert_false(mom.is_hopping())
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_false(_director.is_running())


func test_lean_goes_toward_the_target_then_comes_back() -> void:
	var mom := _map.get_npc(&"mom")
	var max_offset := 0.0
	_director.play(&"lean_buddy", {&"buddy": &"mom"})
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		max_offset = maxf(max_offset, mom.get_lean_offset().y)
		assert_eq(mom.get_cell(), Vector2i(7, 4), "même case pendant l'élan")
	# Joueur (5, 8) sous Maman (7, 4) : élan vers le bas.
	assert_almost_eq(max_offset, Npc.LEAN_DISTANCE, 1.0, "élan vers le joueur")
	assert_eq(mom.get_lean_offset(), Vector2.ZERO, "revenu")
	assert_eq(mom.get_cell(), Vector2i(7, 4), "même case")
	assert_same(_map.get_grid().get_occupant(Vector2i(7, 4)), mom)
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


func test_despawn_frees_the_cell_and_removes_the_npc() -> void:
	var mom := _map.get_npc(&"mom")
	_director.play(&"despawn_buddy", {&"buddy": &"mom"})
	assert_false(_map.get_grid().is_occupied(Vector2i(7, 4)), "case libérée dès le début")
	assert_true(_director.is_running(), "fondu en cours")
	await _await_scene_end()
	assert_null(_map.get_npc(&"mom"), "PNJ retiré de la carte")
	assert_true(not is_instance_valid(mom) or mom.is_queued_for_deletion())
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


# --- Jalon 4B : conditions d'étape ----------------------------------------------------

func test_step_conditions_are_read_when_the_step_is_played() -> void:
	var facing := _player.get_facing()
	assert_ne(facing, Vector2i.LEFT)
	assert_true(_director.play(&"after_battle"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"won_line"), "« if » : drapeau levé plus tôt dans la scène")
	assert_false(_flags.has_flag(&"lost_line"), "« if » non rempli : étape sautée")
	assert_false(_flags.has_flag(&"not_won_line"), "« unless » : étape sautée")
	assert_eq(_player.get_facing(), facing, "étape face sautée")
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_push_error_count(0)


# --- Jalon 4B : étapes battle et give (jalon-04.md §14.3) ------------------------------

func test_battle_waits_for_the_end_and_raises_the_win_flags() -> void:
	var stub := StubRunner.new()
	stub.outcome_to_return = Battle.Outcome.WIN
	add_child_autofree(stub)
	_director.set_battle_runner(stub)
	assert_true(_director.play(&"battle_scene", {&"mine": &"charmander", &"foe": &"squirtle"}))
	assert_true(_director.is_running(), "la scène tourne pendant le combat")
	assert_false(_flags.has_flag(&"after"), "l'étape battle n'est pas finie")
	await _await_scene_end()
	assert_true(stub.finished, "le combat est allé au bout")
	assert_eq(stub.calls.size(), 1)
	assert_eq(stub.calls[0][0], &"rival_lab", "dresseur")
	assert_eq(stub.calls[0][1], {&"player": &"charmander", &"foe": &"squirtle"}
		as Dictionary[StringName, StringName], "alias résolus")
	assert_same(stub.calls[0][2], _map, "carte courante")
	assert_true(_flags.has_flag(&"won_flag"), "drapeau de victoire levé")
	assert_false(_flags.has_flag(&"lost_flag"))
	assert_true(_flags.has_flag(&"after"), "la scène continue")
	assert_push_error_count(0)


func test_battle_raises_the_lose_flags_on_a_loss() -> void:
	var stub := StubRunner.new()
	stub.outcome_to_return = Battle.Outcome.LOSS
	add_child_autofree(stub)
	_director.set_battle_runner(stub)
	_director.play(&"battle_scene", {&"mine": &"charmander", &"foe": &"squirtle"})
	await _await_scene_end()
	assert_true(_flags.has_flag(&"lost_flag"))
	assert_false(_flags.has_flag(&"won_flag"))
	assert_true(_flags.has_flag(&"after"))


func test_battle_without_a_runner_is_skipped_with_error() -> void:
	_director.play(&"battle_scene", {&"mine": &"charmander", &"foe": &"squirtle"})
	await _await_scene_end()
	assert_push_error("pas de directeur de combat")
	assert_false(_flags.has_flag(&"won_flag"))
	assert_false(_flags.has_flag(&"lost_flag"))
	assert_true(_flags.has_flag(&"after"), "la scène continue")


func test_battle_refused_outcome_none_is_skipped_with_error() -> void:
	var stub := StubRunner.new()
	stub.outcome_to_return = Battle.Outcome.NONE
	add_child_autofree(stub)
	_director.set_battle_runner(stub)
	_director.play(&"battle_scene", {&"mine": &"charmander", &"foe": &"squirtle"})
	await _await_scene_end()
	assert_push_error("refusé")
	assert_false(_flags.has_flag(&"won_flag"))
	assert_false(_flags.has_flag(&"lost_flag"))
	assert_true(_flags.has_flag(&"after"))


func test_give_adds_to_the_bag_and_emits_item_given() -> void:
	var bag := Bag.new()
	var items := ItemLibrary.new()
	items.load_dir()
	_director.set_inventory(bag, items)
	watch_signals(_director)
	_director.play(&"give_scene")
	await _await_scene_end()
	assert_eq(bag.count_of(&"poke_ball"), 5)
	assert_signal_emitted_with_parameters(_director, "item_given", [&"poke_ball", 5])
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


func test_give_unknown_item_is_skipped_with_error() -> void:
	var bag := Bag.new()
	var items := ItemLibrary.new()
	items.load_dir()
	_director.set_inventory(bag, items)
	watch_signals(_director)
	_director.play(&"give_unknown")
	await _await_scene_end()
	assert_push_error("objet inconnu")
	assert_true(bag.is_empty(), "Sac inchangé")
	assert_signal_not_emitted(_director, "item_given")
	assert_true(_flags.has_flag(&"after"))


func test_give_without_a_bag_is_skipped_with_error() -> void:
	_director.play(&"give_scene")
	await _await_scene_end()
	assert_push_error("pas de Sac")
	assert_true(_flags.has_flag(&"after"))
