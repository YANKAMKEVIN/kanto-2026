extends GutTest
## InteractionController (jalon 3A §2.2, §2.7, T3) sur une mini-carte avec des PNJ
## (tests/fixtures/npcs/runner_map.json) et un point fixe, avec un vrai joueur, un vrai
## DialogueRunner et une vraie DialogueBox. Entrées injectées (Input.action_press).
## Cible devant le joueur (une émission par changement), pas de cible pendant un pas ou un
## dialogue, `interact` lance le bon dialogue et tourne le PNJ, anti-rebond, dialogue
## automatique à l'arrivée sur la carte.
## Jalon 4 (T1) : une surcharge « Rencontrer » (MEET) sur un PNJ → target_changed(MEET), et
## l'appui émet meet_requested(npc) sans jouer de dialogue, avec le même anti-rebond.

const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const DIALOGUES := "res://tests/fixtures/dialogues/"
const NPCS := "res://tests/fixtures/npcs/"
const MOM_CELL := Vector2i(7, 4)
## Point fixe (table) : une seule case, sous Maman.
const TABLE_CELL := Vector2i(7, 5)
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run", &"interact",
]
const TIMEOUT := 3.0

var _map: GameMap
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _controller: InteractionController
var _flags: StoryFlags
var _kinds: Array[int] = []


func before_each() -> void:
	_kinds.clear()
	var library := DialogueLibrary.new()
	library.load_dir(DIALOGUES)
	_flags = StoryFlags.new()
	_map = _make_map()
	add_child_autofree(_map)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_box = (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(_box)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(library, _flags, _box, _player)
	_controller = InteractionController.new()
	add_child_autofree(_controller)
	_controller.setup(_player, _runner)
	_controller.target_changed.connect(func(kind: int) -> void: _kinds.append(kind))
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_controller.set_map(_map)
	watch_signals(_runner)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


## Carte 20 × 18 sans tuiles : PNJ du fixture, point fixe en (7, 5), spawn « start » (7, 6).
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
	marker.position = Grid.cell_to_world(Vector2i(7, 6))
	map.get_node(^"Spawns").add_child(marker)
	var point := InteractPoint.new()
	point.name = "Table"
	point.position = Grid.cell_to_world(TABLE_CELL)
	point.dialogue_id = &"breakfast_table"
	map.get_node(^"Interactables").add_child(point)
	return map


## Place le joueur (à l'arrêt) sur [param cell], orienté vers [param facing].
func _place(cell: Vector2i, facing: Vector2i) -> void:
	_player.enter_map(_map.get_grid(), cell, facing, _map.get_pixel_rect())


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	await wait_process_frames(1)


func _finish_dialogue() -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		await _press_interact()
	assert_false(_runner.is_running(), "dialogue terminé")


func test_facing_a_point_then_an_npc_then_nothing() -> void:
	await wait_process_frames(2)
	assert_eq(_kinds, [Interaction.Kind.EXAMINE] as Array[int], "table devant le joueur")
	assert_eq(_controller.get_target().dialogue_id, &"breakfast_table")
	_place(Vector2i(7, 5), Vector2i.UP)
	await wait_process_frames(2)
	assert_eq(_kinds.back(), Interaction.Kind.TALK, "Maman devant le joueur")
	assert_eq(_controller.get_target().source, _map.get_npc(&"mom"))
	var count := _kinds.size()
	await wait_process_frames(3)
	assert_eq(_kinds.size(), count, "une seule émission tant que la cible ne change pas")
	_player.face(Vector2i.LEFT)
	await wait_process_frames(2)
	assert_eq(_kinds.back(), InteractionController.NO_TARGET, "détourné : plus de cible")
	assert_null(_controller.get_target())


func test_nothing_behind_or_beside() -> void:
	_place(Vector2i(7, 3), Vector2i.UP)
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "Maman derrière le joueur")
	_place(Vector2i(8, 5), Vector2i.UP)
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "Maman en diagonale")


func test_no_target_while_stepping() -> void:
	# Du spawn (7, 6) vers la table (7, 5), case praticable : pendant le pas, la case devant
	# la case de départ est la table, que InteractionFinder trouverait ; le contrôleur n'a
	# pourtant aucune cible. À l'arrêt en (7, 5), Maman est devant.
	await wait_process_frames(2)
	assert_eq(_controller.get_target().dialogue_id, &"breakfast_table")
	Input.action_press(&"move_up")
	var saw_moving := false
	for i: int in 60:
		await wait_process_frames(1)
		if _player.is_moving():
			saw_moving = true
			assert_not_null(InteractionFinder.find(_map.get_grid(), _map.get_interactions(),
				_player.get_cell(), _player.get_facing()), "le point serait trouvé")
			assert_null(_controller.get_target(), "pas de cible pendant un pas")
			Input.action_release(&"move_up")
		elif saw_moving:
			break
	Input.action_release(&"move_up")
	assert_true(saw_moving, "le joueur a marché")
	await wait_process_frames(2)
	assert_eq(_player.get_cell(), TABLE_CELL)
	assert_eq(_controller.get_target().source, _map.get_npc(&"mom"), "cible à l'arrêt")


func test_no_target_while_blocked() -> void:
	await wait_process_frames(2)
	assert_not_null(_controller.get_target())
	_player.set_input_enabled(false, &"transition")
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "pas de cible pendant une transition")
	_player.set_input_enabled(true, &"transition")
	await wait_process_frames(2)
	assert_not_null(_controller.get_target())


func test_interact_plays_the_dialogue_and_turns_the_npc() -> void:
	_place(Vector2i(6, 4), Vector2i.RIGHT)
	var mom := _map.get_npc(&"mom")
	assert_eq(mom.get_facing(), Vector2i.DOWN)
	await wait_process_frames(2)
	await _press_interact()
	assert_true(_runner.is_running())
	assert_signal_emitted_with_parameters(_runner, "dialogue_started", [&"mom"])
	assert_eq(mom.get_facing(), Vector2i.LEFT, "Maman se tourne vers le joueur")
	assert_null(_controller.get_target(), "pas de cible pendant un dialogue")
	assert_eq(_kinds.back(), InteractionController.NO_TARGET)
	await _finish_dialogue()
	assert_eq(mom.get_facing(), Vector2i.DOWN, "elle reprend son orientation")


func test_examine_point_plays_narration() -> void:
	await wait_process_frames(2)
	await _press_interact()
	assert_true(_runner.is_running())
	assert_eq(_runner.get_dialogue_id(), &"breakfast_table")
	assert_true(_box.is_narration())
	assert_eq(_box.get_speaker_text(), "")


func test_interact_held_at_the_end_does_not_restart_the_dialogue() -> void:
	await wait_process_frames(2)
	await _press_interact()
	assert_true(_runner.is_running())
	# Le dernier appui (qui ferme) reste tenu.
	Input.action_press(&"interact")
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)
	await wait_process_frames(5)
	assert_false(_runner.is_running(), "interact tenu : pas de relance")
	assert_signal_emit_count(_runner, "dialogue_started", 1)
	Input.action_release(&"interact")
	await wait_process_frames(2)
	await _press_interact()
	assert_true(_runner.is_running(), "relâcher puis réappuyer relance")
	assert_signal_emit_count(_runner, "dialogue_started", 2)


func test_interact_without_target_does_nothing() -> void:
	_player.face(Vector2i.LEFT)
	await wait_process_frames(2)
	await _press_interact()
	assert_false(_runner.is_running())
	assert_signal_not_emitted(_runner, "dialogue_started")


func test_auto_variant_on_map_entered() -> void:
	_place(Vector2i(2, 4), Vector2i.DOWN)
	var mom := _map.get_npc(&"mom")
	# Images simulées (FrameSim) : le délai du DialogueRunner se compte en images.
	var sim := FrameSim.new(get_tree(), [_runner])
	_controller.on_map_entered(_map)
	assert_true(_runner.is_running(), "dialogue automatique")
	assert_eq(_runner.get_dialogue_id(), &"mom")
	assert_true(_player.is_blocked_by(DialogueRunner.REASON), "bloqué dans l'appel même")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "le joueur se tourne vers Maman")
	assert_eq(mom.get_facing(), Vector2i.LEFT, "Maman se tourne vers le joueur")
	assert_false(_box.is_open(), "la boîte attend le délai")
	await sim.run_until(func() -> bool: return false,
		InteractionController.AUTO_DIALOGUE_DELAY - FrameSim.STEP)
	assert_false(_box.is_open(), "pas avant AUTO_DIALOGUE_DELAY (%.3f s)" % sim.elapsed())
	await sim.run_until(func() -> bool: return _box.is_open(), 1.0)
	sim.finish()
	assert_true(_box.is_open(), "ouverte après AUTO_DIALOGUE_DELAY")
	assert_between(sim.elapsed(), InteractionController.AUTO_DIALOGUE_DELAY - 0.0001,
		InteractionController.AUTO_DIALOGUE_DELAY + FrameSim.STEP + 0.0001,
		"au délai près (%.3f s)" % sim.elapsed())
	assert_eq(_box.get_speaker_text(), "Maman")
	await _finish_dialogue()
	assert_true(_flags.has_flag(&"mom_greeted"))
	assert_true(_player.is_input_enabled())
	_controller.on_map_entered(_map)
	assert_false(_runner.is_running(), "pas de relance à l'arrivée suivante")


func test_no_auto_dialogue_on_map_entered_while_the_player_is_blocked() -> void:
	_place(Vector2i(2, 4), Vector2i.DOWN)
	_player.set_input_enabled(false, &"cutscene")
	_controller.on_map_entered(_map)
	assert_false(_runner.is_running(), "scène en cours : pas de dialogue automatique")
	assert_signal_not_emitted(_runner, "dialogue_started")
	assert_eq(_player.get_facing(), Vector2i.DOWN, "le joueur ne se tourne pas")
	_player.set_input_enabled(true, &"cutscene")
	_controller.on_map_entered(_map)
	assert_true(_runner.is_running(), "libre : Maman parle comme en 3A")


func test_auto_dialogue_holds_the_player_even_with_a_direction_held() -> void:
	_place(Vector2i(2, 4), Vector2i.DOWN)
	Input.action_press(&"move_down")
	_controller.on_map_entered(_map)
	await wait_seconds(0.6)
	assert_eq(_player.get_cell(), Vector2i(2, 4), "aucun pas pendant le dialogue")
	Input.action_release(&"move_down")


# --- Rencontrer (jalon 4, T1) ------------------------------------------------------------

## Maman (7, 4) reçoit une surcharge MEET ; joueur en (7, 5) tourné vers elle.
func _meet_mom() -> Npc:
	var mom := _map.get_npc(&"mom")
	mom.set_interaction_override(
		Interaction.new(Interaction.Kind.MEET, mom.get_cell(), &"", Vector2i.ZERO, mom))
	_place(Vector2i(7, 5), Vector2i.UP)
	return mom


func test_meet_override_is_the_target() -> void:
	var mom := _meet_mom()
	await wait_process_frames(2)
	assert_eq(_kinds.back(), Interaction.Kind.MEET, "cible Rencontrer")
	assert_eq(_controller.get_target().kind, Interaction.Kind.MEET)
	assert_same(_controller.get_target().source, mom)
	mom.clear_interaction_override()
	await wait_process_frames(2)
	assert_eq(_kinds.back(), Interaction.Kind.TALK, "surcharge retirée : Parler")


func test_meet_emits_meet_requested_without_dialogue() -> void:
	var mom := _meet_mom()
	watch_signals(_controller)
	await wait_process_frames(2)
	await _press_interact()
	assert_signal_emit_count(_controller, "meet_requested", 1)
	assert_signal_emitted_with_parameters(_controller, "meet_requested", [mom])
	assert_false(_runner.is_running(), "aucun dialogue")
	assert_signal_not_emitted(_runner, "dialogue_started")
	assert_eq(mom.get_facing(), Vector2i.DOWN, "le PNJ ne se tourne pas (le choix s'en charge)")


func test_meet_held_does_not_repeat_until_released() -> void:
	_meet_mom()
	watch_signals(_controller)
	await wait_process_frames(2)
	Input.action_press(&"interact")
	await wait_process_frames(10)
	assert_signal_emit_count(_controller, "meet_requested", 1, "interact tenu : un seul appel")
	Input.action_release(&"interact")
	await wait_process_frames(2)
	await _press_interact()
	assert_signal_emit_count(_controller, "meet_requested", 2, "relâcher puis réappuyer")
	assert_signal_not_emitted(_runner, "dialogue_started")


func test_dominant_direction() -> void:
	var from := Vector2i(5, 5)
	assert_eq(InteractionController.dominant_direction(from, Vector2i(9, 6)), Vector2i.RIGHT)
	assert_eq(InteractionController.dominant_direction(from, Vector2i(1, 4)), Vector2i.LEFT)
	assert_eq(InteractionController.dominant_direction(from, Vector2i(6, 1)), Vector2i.UP)
	assert_eq(InteractionController.dominant_direction(from, Vector2i(4, 9)), Vector2i.DOWN)
	assert_eq(InteractionController.dominant_direction(from, Vector2i(6, 6)), Vector2i.DOWN,
		"égalité : axe vertical")
	assert_eq(InteractionController.dominant_direction(from, from), Vector2i.ZERO)
