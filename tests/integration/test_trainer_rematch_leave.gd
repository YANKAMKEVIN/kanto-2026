extends GutTest
## Jalon 12 (jalon-12.md §2.11, T17) : reprise et départ d'un Dresseur, joués de bout en bout par
## un vrai [TrainerWatcher], un vrai [CutsceneDirector] et un vrai [DialogueRunner] (texte
## instantané), avec un faux combat (issue imposée) et un faux réveil, sur une mini-carte (PNJ de
## tests/fixtures/npcs/rocket_map.json) :
## - « guard » (5, 2) ↓, vision 4, « rematch », départ [[0, 0], [3, 0]] (retour à son poste puis
##   3 cases à droite) ;
## - « lookout » (12, 8) ←, vision 2, départ vide (s'efface sur place) ;
## - « scout » (15, 2) ↓, vision 3 : bloc du J9 sans clé nouvelle (témoin de compatibilité).
## Victoire → réplique « vaincu », marche, fondu, retiré ; absent au rechargement (`unless
## beaten_<id>`). Défaite → `lost_<id>`, réveil ; au défi suivant, la réplique de reprise
## remplace « avant ». Témoin : défaite sans trace ni réplique de reprise.

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const NPCS := "res://tests/fixtures/npcs/"
const MAP_ID := &"rocket_map"
const TIMEOUT := 10.0
const START := Vector2i(5, 12)
const GUARD_POST := Vector2i(5, 2)
## Case vue par le garde à 4 cases.
const GUARD_SEEN := Vector2i(5, 6)
const LOOKOUT_CELL := Vector2i(12, 8)
## Case vue par la guetteuse à 2 cases.
const LOOKOUT_SEEN := Vector2i(10, 8)
const SCOUT_SEEN := Vector2i(15, 5)
const DIALOGUES := {
	"guard_before": {"speaker": "Sbire", "pages": ["Avant."]},
	"guard_after": {"speaker": "Sbire", "pages": ["Après."]},
	"guard_defeated": {"speaker": "Sbire", "pages": ["Vaincu."]},
	"guard_rematch": {"speaker": "Sbire", "pages": ["Encore toi ?"]},
	"lookout_before": {"speaker": "Sbire", "pages": ["Avant."]},
	"lookout_after": {"speaker": "Sbire", "pages": ["Après."]},
	"lookout_defeated": {"speaker": "Sbire", "pages": ["Vaincue."]},
	"scout_before": {"speaker": "Scout", "pages": ["Avant."]},
	"scout_after": {"speaker": "Scout", "pages": ["Après."]},
}


## Faux combat de Dresseur : issue imposée, appels enregistrés, deux images de combat.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.WIN
	var calls: Array[StringName] = []

	func run(trainer_id: StringName, _map: GameMap,
			_world_actors: Dictionary[StringName, StringName]) -> int:
		calls.append(trainer_id)
		await get_tree().process_frame
		await get_tree().process_frame
		return outcome_to_return


## Faux réveil après une défaite : compte les appels.
class StubRecovery extends DefeatRecovery:
	var calls: int = 0

	func recover() -> void:
		calls += 1
		await get_tree().process_frame


var _router: Node
var _world: Node2D
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _director: CutsceneDirector
var _flags: StoryFlags
var _map: GameMap
var _battles: StubRunner
var _recovery: StubRecovery
var _watcher: TrainerWatcher
var _dialogues_played: Array[StringName] = []


func before_each() -> void:
	_dialogues_played.clear()
	var dialogues := DialogueLibrary.new()
	dialogues.add_from_dict(DIALOGUES, "test")
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
	_runner.dialogue_started.connect(func(id: StringName) -> void: _dialogues_played.append(id))
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(CutsceneLibrary.new(), _flags, _runner, _player, _router)
	_battles = StubRunner.new()
	add_child_autofree(_battles)
	_director.set_battle_runner(_battles)
	_recovery = StubRecovery.new()
	add_child_autofree(_recovery)
	_director.set_recovery(_recovery)
	_watcher = TrainerWatcher.new()
	add_child_autofree(_watcher)
	_watcher.setup(_player, _flags, _director)
	_router.setup(_world, _player, null)
	_router.map_changed.connect(_director.set_map)
	_router.map_changed.connect(_watcher.set_map)
	_load_map()


## (Re)charge la carte comme Boot : nouvelle instance, PNJ ajustés aux drapeaux.
func _load_map() -> void:
	_map = _router.start(MAP_ID, &"start", Vector2i.UP)
	_map.refresh_npcs(_flags)
	_player.set_process(false)
	_player.set_input_enabled(true, &"transition")


## Carte 20 × 18 sans tuiles, PNJ du fixture, départ (5, 12).
func _make_map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.name = "RocketMap"
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
	return map


## Le joueur arrive (pas terminé) sur [param cell], tourné vers [param facing].
func _arrive(cell: Vector2i, facing: Vector2i = Vector2i.UP) -> void:
	_player.enter_map(_map.get_grid(), cell, facing, _map.get_pixel_rect())
	_player.moved.emit(cell)


## Joue la scène jusqu'au bout en fermant chaque dialogue (une image d'écart).
func _play_to_the_end() -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if _runner.is_running():
			_box.advance_requested.emit()
	assert_false(_director.is_running(), "séquence terminée")


func test_beaten_guard_says_his_line_walks_away_fades_and_is_gone_on_reload() -> void:
	var guard := _map.get_npc(&"guard")
	assert_not_null(guard)
	var cells: Array[Vector2i] = []
	guard.step_finished.connect(func(cell: Vector2i) -> void: cells.append(cell))
	_arrive(GUARD_SEEN)
	assert_true(_director.is_running(), "repéré")
	await _play_to_the_end()
	assert_eq(_battles.calls, [&"test_rocket_guard"] as Array[StringName])
	assert_true(_flags.has_flag(&"beaten_test_rocket_guard"))
	assert_false(_flags.has_flag(&"lost_test_rocket_guard"))
	assert_eq(_dialogues_played, [&"guard_before", &"guard_defeated"] as Array[StringName],
		"« avant » puis « vaincu »")
	assert_eq(cells.slice(cells.find(Vector2i(5, 5)) + 1), [Vector2i(5, 4), Vector2i(5, 3),
		GUARD_POST, Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2)] as Array[Vector2i],
		"retour à son poste puis trois cases à droite")
	assert_null(_map.get_npc(&"guard"), "parti au fondu")
	assert_false(_map.get_grid().is_occupied(Vector2i(8, 2)), "case libérée")
	assert_eq(_recovery.calls, 0)
	assert_true(_player.is_input_enabled(), "joueur libre à la fin")
	_load_map()
	assert_null(_map.get_npc(&"guard"), "absent au rechargement")
	assert_not_null(_map.get_npc(&"lookout"), "les autres restent")
	assert_push_error_count(0)


func test_lost_then_rematch_line_then_leaves() -> void:
	_battles.outcome_to_return = Battle.Outcome.LOSS
	_arrive(GUARD_SEEN)
	await _play_to_the_end()
	assert_eq(_recovery.calls, 1, "réveil au point de repos")
	assert_true(_flags.has_flag(&"lost_test_rocket_guard"), "défaite mémorisée")
	assert_false(_flags.has_flag(&"beaten_test_rocket_guard"))
	assert_eq(_dialogues_played, [&"guard_before"] as Array[StringName])
	assert_not_null(_map.get_npc(&"guard"), "il reste")
	# Le vrai réveil change de carte : le garde est de retour à son poste.
	_load_map()
	assert_eq(_map.get_npc(&"guard").get_cell(), GUARD_POST)
	_dialogues_played.clear()
	_battles.outcome_to_return = Battle.Outcome.WIN
	_arrive(GUARD_SEEN)
	await _play_to_the_end()
	assert_eq(_dialogues_played, [&"guard_rematch", &"guard_defeated"] as Array[StringName],
		"la reprise remplace « avant »")
	assert_null(_map.get_npc(&"guard"), "battu : parti")
	assert_push_error_count(0)


func test_rematch_line_also_when_talked_to() -> void:
	_flags.set_flag(&"lost_test_rocket_guard")
	_player.enter_map(_map.get_grid(), GUARD_POST + Vector2i.DOWN, Vector2i.UP,
		_map.get_pixel_rect())
	assert_true(_watcher.challenge(_map.get_npc(&"guard")))
	await _play_to_the_end()
	assert_eq(_dialogues_played, [&"guard_rematch", &"guard_defeated"] as Array[StringName])


func test_empty_leave_fades_on_the_spot() -> void:
	var lookout := _map.get_npc(&"lookout")
	watch_signals(lookout)
	_arrive(LOOKOUT_SEEN, Vector2i.RIGHT)
	assert_true(_director.is_running())
	await _play_to_the_end()
	assert_eq(_dialogues_played, [&"lookout_before", &"lookout_defeated"] as Array[StringName])
	assert_null(_map.get_npc(&"lookout"), "effacée sur place")
	assert_false(_map.get_grid().is_occupied(LOOKOUT_SEEN + Vector2i.RIGHT), "case libérée")
	_load_map()
	assert_null(_map.get_npc(&"lookout"), "absente au rechargement")
	assert_push_error_count(0)


func test_jalon_9_block_is_unchanged() -> void:
	_battles.outcome_to_return = Battle.Outcome.LOSS
	_arrive(SCOUT_SEEN)
	await _play_to_the_end()
	assert_eq(_recovery.calls, 1)
	assert_false(_flags.has_flag(&"lost_test_scout"), "sans « rematch » : aucune trace")
	_load_map()
	_dialogues_played.clear()
	_battles.outcome_to_return = Battle.Outcome.WIN
	_arrive(SCOUT_SEEN)
	await _play_to_the_end()
	assert_eq(_dialogues_played, [&"scout_before", &"scout_after"] as Array[StringName],
		"« avant » à chaque fois, « après » tout de suite")
	assert_not_null(_map.get_npc(&"scout"), "il reste sur la carte")
	_load_map()
	assert_not_null(_map.get_npc(&"scout"), "toujours là au rechargement")
	assert_push_error_count(0)
