extends GutTest
## Jalon 12 (jalon-12.md §2.8, T17) : InteractionController et point d'examen conditionnel
## (objet caché « face à un indice »), sur une mini-carte avec un vrai joueur, un vrai
## DialogueRunner et une vraie DialogueBox. L'indice (7, 4) est une case **bloquée** examinable de
## tous côtés ; son dialogue lève `got_<id>` (dans le jeu : la scène `give … found` puis `set`,
## branchée par les données au T18 — `test_hidden_items` sur Boot réel).
## Face à l'indice → cible EXAMINER (Q-2 : le bouton apparaît) ; de dos ou de côté → rien ;
## examiné → drapeau levé, plus de cible, même sur une carte rechargée ; les points sans
## condition (table) restent des cibles.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const NPCS := "res://tests/fixtures/npcs/"
const CLUE_CELL := Vector2i(7, 4)
const TABLE_CELL := Vector2i(12, 4)
const FOUND := &"got_test_hidden_awakening"
const DIALOGUES := {
	"test_hidden_awakening": {
		"narration": true, "set": ["got_test_hidden_awakening"], "pages": ["Trouvé !"],
	},
	"table": {"narration": true, "pages": ["Une table."]},
}
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
	library.add_from_dict(DIALOGUES, "test")
	_flags = StoryFlags.new()
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
	_controller.set_story_flags(_flags)
	_controller.target_changed.connect(func(kind: int) -> void: _kinds.append(kind))
	_map = _make_map()
	add_child_autofree(_map)
	_map.get_grid().set_solid(CLUE_CELL)
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_controller.set_map(_map)


func after_each() -> void:
	Input.action_release(&"interact")


## Carte rechargée : nouvelle instance (comme après un changement de carte), le joueur y entre
## sur [param cell] tourné vers [param facing].
func _reload_map() -> void:
	_map = _make_map()
	add_child_autofree(_map)
	_map.get_grid().set_solid(CLUE_CELL)
	_controller.set_map(_map)


## Carte 20 × 18 sans tuiles : indice bloqué (7, 4) avec « unless », table (12, 4) sans
## condition, spawn « start » (7, 6).
func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "HiddenMap"
	map.map_id = &"hidden_map"
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
	var clue := InteractPoint.new()
	clue.name = "HiddenAwakening"
	clue.position = Grid.cell_to_world(CLUE_CELL)
	clue.dialogue_id = &"test_hidden_awakening"
	clue.unless_flags = [FOUND] as Array[StringName]
	map.get_node(^"Interactables").add_child(clue)
	var table := InteractPoint.new()
	table.name = "Table"
	table.position = Grid.cell_to_world(TABLE_CELL)
	table.dialogue_id = &"table"
	map.get_node(^"Interactables").add_child(table)
	return map


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


func test_facing_the_clue_from_every_side_targets_it() -> void:
	for side: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		_place(CLUE_CELL + side, -side)
		await wait_process_frames(2)
		var target := _controller.get_target()
		assert_not_null(target, "face à l'indice depuis %s" % side)
		if target != null:
			assert_eq(target.kind, Interaction.Kind.EXAMINE, "verbe EXAMINER (Q-2)")
			assert_eq(target.dialogue_id, &"test_hidden_awakening")


func test_back_or_side_gives_nothing() -> void:
	_place(CLUE_CELL + Vector2i.DOWN, Vector2i.DOWN)
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "de dos")
	_place(CLUE_CELL + Vector2i.DOWN, Vector2i.LEFT)
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "de côté")


func test_examined_then_gone_even_after_reload() -> void:
	_place(CLUE_CELL + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(2)
	assert_eq(_kinds.back(), Interaction.Kind.EXAMINE)
	await _press_interact()
	assert_true(_runner.is_running(), "examen lancé")
	await _finish_dialogue()
	assert_true(_flags.has_flag(FOUND), "objet trouvé : drapeau levé")
	await wait_process_frames(2)
	assert_null(_controller.get_target(), "trouvé : plus de cible")
	assert_eq(_kinds.back(), InteractionController.NO_TARGET, "le bouton disparaît")
	watch_signals(_runner)
	await _press_interact()
	assert_signal_not_emitted(_runner, "dialogue_started", "appui sans effet")
	# Carte rechargée : l'indice n'est toujours plus une cible, sous aucun angle.
	_reload_map()
	for side: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		_place(CLUE_CELL + side, -side)
		await wait_process_frames(2)
		assert_null(_controller.get_target(), "rechargée, depuis %s" % side)


func test_points_without_condition_are_unchanged() -> void:
	_flags.set_flag(FOUND)
	_place(TABLE_CELL + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(2)
	assert_not_null(_controller.get_target(), "la table reste examinable")
	assert_eq(_controller.get_target().dialogue_id, &"table")


func test_without_story_flags_the_clue_is_a_target() -> void:
	_controller.set_story_flags(null)
	_place(CLUE_CELL + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(2)
	assert_not_null(_controller.get_target(), "nouvelle partie sans drapeaux branchés")
