extends GutTest
## Téléporteurs (passe systèmes 2, `docs/tech/systemes-2.md` §2.9, T26) : [member Warp.style]
## TELEPORT, [method SceneRouter.relocate] (même carte, sans rechargement) et fondu court vers
## une autre carte. Instance fraîche du routeur, jamais l'autoload ; mini-cartes en code :
## - « t » (10 × 6) : téléporteur (2, 2) → spawn « pad_b » (7, 2), téléporteur (7, 2) → « pad_a »
##   (2, 2) ; téléporteur (2, 4) → carte « u » ; départ (2, 3) ;
## - « u » (6 × 5) : téléporteur (1, 1) → « t » / « pad_a ».

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FADE_SCENE := preload("res://game/ui/components/screen_fade.tscn")
const FRAME := 1.0 / 60.0
const FADE_TIME := 0.05
const TIMEOUT := 3.0
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run",
]
const T_START := Vector2i(2, 3)
const PAD_A := Vector2i(2, 2)
const PAD_B := Vector2i(7, 2)
const PAD_U := Vector2i(2, 4)
const U_PAD := Vector2i(1, 1)

var _router: Node
var _world: Node2D
var _player: Player
var _fade: ScreenFade
var _made: Dictionary[StringName, GameMap] = {}
## Nombre d'instanciations par carte (une carte replacée n'est pas rechargée).
var _built: Dictionary[StringName, int] = {}
var _events: Array[String] = []


func before_each() -> void:
	_made.clear()
	_built.clear()
	_events.clear()
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_router.fade_out_duration = FADE_TIME
	_router.fade_in_duration = FADE_TIME
	_router.teleport_fade_duration = FADE_TIME
	_world = Node2D.new()
	add_child_autofree(_world)
	_fade = FADE_SCENE.instantiate() as ScreenFade
	add_child_autofree(_fade)
	_player = PLAYER_SCENE.instantiate() as Player
	autofree(_player)
	_router.setup(_world, _player, _fade)
	_router.transition_started.connect(func(id: StringName) -> void:
		_events.append("transition_started:%s" % id))
	_router.map_changed.connect(func(map: GameMap) -> void:
		_events.append("map_changed:%s" % map.map_id))
	_router.map_entered.connect(func(map: GameMap) -> void:
		_events.append("map_entered:%s" % map.map_id))
	_router.relocated.connect(func(map: GameMap) -> void:
		_events.append("relocated:%s" % map.map_id))
	watch_signals(_router)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


# --- Mini-cartes --------------------------------------------------------------------

func _make_map(map_id: StringName) -> GameMap:
	var map: GameMap
	match map_id:
		&"t":
			map = _base_map(map_id, Vector2i(10, 6))
			_spawn(map, &"start", T_START)
			_spawn(map, &"pad_a", PAD_A)
			_spawn(map, &"pad_b", PAD_B)
			_teleporter(map, PAD_A, &"t", &"pad_b")
			_teleporter(map, PAD_B, &"t", &"pad_a")
			_teleporter(map, PAD_U, &"u", &"pad")
		&"u":
			map = _base_map(map_id, Vector2i(6, 5))
			_spawn(map, &"pad", U_PAD)
			_teleporter(map, U_PAD, &"t", &"pad_a")
		_:
			return null
	_made[map_id] = map
	_built[map_id] = _built.get(map_id, 0) + 1
	return map


func _base_map(map_id: StringName, map_size: Vector2i) -> GameMap:
	var map := GameMap.new()
	map.name = String(map_id).to_upper()
	map.map_id = map_id
	map.size = map_size
	for group: String in ["Entities", "Spawns", "Warps"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	return map


func _spawn(map: GameMap, spawn_name: StringName, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = Grid.cell_to_world(cell)
	map.get_node(^"Spawns").add_child(marker)


func _teleporter(map: GameMap, cell: Vector2i, to_map: StringName, to_spawn: StringName) -> void:
	var point := WarpPoint.new()
	point.name = "Teleporter%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.style = Warp.Style.TELEPORT
	point.target_map = to_map
	point.target_spawn = to_spawn
	map.get_node(^"Warps").add_child(point)


# --- Outils -------------------------------------------------------------------------

func _start_on_t() -> GameMap:
	var map: GameMap = _router.start(&"t", &"start", Vector2i.UP)
	_player.set_process(false)
	_events.clear()
	return map


func _simulate_until(done: Callable, max_seconds: float = 2.0) -> void:
	for i: int in roundi(max_seconds / FRAME):
		_player._process(FRAME)
		if done.call():
			return


func _step(direction: StringName, cell: Vector2i) -> void:
	Input.action_press(direction)
	_simulate_until(func() -> bool: return _player.get_cell() == cell and not _player.is_moving())
	Input.action_release(direction)


func _await_idle() -> void:
	await wait_until(func() -> bool: return not _router.is_transitioning(), TIMEOUT)


# --- Donnée ---------------------------------------------------------------------------

func test_warp_style_defaults_to_door_and_is_copied_from_the_point() -> void:
	var door := Warp.new(Vector2i(1, 1), Warp.Trigger.STEP_ON, Vector2i.ZERO, &"a", &"b")
	assert_eq(door.style, Warp.Style.DOOR)
	assert_false(door.is_teleport())
	var point := WarpPoint.new()
	point.style = Warp.Style.TELEPORT
	point.target_map = &"a"
	point.target_spawn = &"b"
	var warp := point.to_warp()
	assert_true(warp.is_teleport())
	assert_true(warp.is_valid())
	point.free()


# --- Même carte -------------------------------------------------------------------------

func test_teleporter_on_the_same_map_relocates_without_reloading() -> void:
	var map := _start_on_t()
	_step(&"move_up", PAD_A)
	assert_true(_router.is_transitioning(), "transition ouverte dans l'image du pas")
	assert_false(_player.is_input_enabled())
	await wait_for_signal(_router.relocated, TIMEOUT)
	assert_eq(_player.get_cell(), PAD_B, "destination exacte")
	assert_eq(_player.get_facing(), Vector2i.UP, "orientation conservée [D]")
	assert_eq(_router.get_current_map(), map, "même carte")
	assert_true(is_instance_valid(map))
	assert_eq(_built[&"t"], 1, "aucun rechargement")
	assert_eq(_events, ["transition_started:t", "relocated:t"] as Array[String])
	assert_true(_player.is_input_enabled())
	assert_false(_router.is_transitioning())
	assert_false(_fade.is_opaque())


func test_arriving_on_a_teleporter_does_not_trigger_it() -> void:
	_start_on_t()
	_step(&"move_up", PAD_A)
	await wait_for_signal(_router.relocated, TIMEOUT)
	# Le joueur est debout sur le téléporteur d'en face : rien ne repart.
	for i: int in 30:
		_player._process(FRAME)
	await get_tree().process_frame
	assert_eq(_player.get_cell(), PAD_B)
	assert_eq(_count("relocated"), 1, "aucune boucle")
	assert_false(_router.is_transitioning())


func test_stepping_off_and_back_on_takes_the_teleporter_again() -> void:
	_start_on_t()
	_step(&"move_up", PAD_A)
	await wait_for_signal(_router.relocated, TIMEOUT)
	_step(&"move_down", PAD_B + Vector2i.DOWN)
	_step(&"move_up", PAD_B)
	await wait_for_signal(_router.relocated, TIMEOUT)
	assert_eq(_player.get_cell(), PAD_A, "retour par le téléporteur d'en face")
	assert_eq(_count("relocated"), 2)


func test_old_cell_is_released_and_new_cell_occupied() -> void:
	var map := _start_on_t()
	_step(&"move_up", PAD_A)
	await wait_for_signal(_router.relocated, TIMEOUT)
	var grid := map.get_grid()
	assert_true(grid.is_free(PAD_A), "case de départ libérée")
	assert_false(grid.is_free(PAD_B), "case d'arrivée occupée par le joueur")


func test_relocate_with_an_unknown_spawn_keeps_the_player_in_place() -> void:
	_start_on_t()
	_router.relocate(&"nowhere")
	await wait_for_signal(_router.relocated, TIMEOUT)
	assert_push_error("spawn inconnu")
	assert_eq(_player.get_cell(), T_START)
	assert_true(_player.is_input_enabled())


func test_relocate_is_ignored_during_a_transition() -> void:
	_start_on_t()
	_router.relocate(&"pad_b")
	_router.relocate(&"pad_a")
	await _await_idle()
	assert_eq(_player.get_cell(), PAD_B)
	assert_eq(_count("relocated"), 1)


func test_relocate_without_fade_is_immediate() -> void:
	_router.setup(_world, _player, null)
	_router.relocated.connect(func(map: GameMap) -> void:
		_events.append("relocated:%s" % map.map_id))
	_router.start(&"t", &"start", Vector2i.UP)
	_router.relocate(&"pad_b", Vector2i.LEFT)
	assert_eq(_player.get_cell(), PAD_B)
	assert_eq(_player.get_facing(), Vector2i.LEFT, "orientation imposée")
	assert_false(_router.is_transitioning())


# --- Autre carte -------------------------------------------------------------------------

func test_teleporter_to_another_map_changes_map_with_the_short_fade() -> void:
	# Fondu des portes plus long que l'attente : seul le fondu court du téléporteur arrive à temps.
	_router.fade_out_duration = 30.0
	_router.fade_in_duration = 30.0
	_start_on_t()
	_step(&"move_down", PAD_U)
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map(), _made[&"u"])
	assert_eq(_player.get_cell(), U_PAD)
	assert_eq(_player.get_facing(), Vector2i.DOWN)
	assert_eq(_events, ["transition_started:u", "map_changed:u", "map_entered:u"] as Array[String])


func test_a_door_still_uses_the_door_fade() -> void:
	assert_eq(_router.teleport_fade_duration, FADE_TIME)
	var fresh: Node = ROUTER_SCRIPT.new()
	assert_eq(fresh.teleport_fade_duration, 0.25, "fondu d'un téléporteur [D]")
	assert_eq(fresh.fade_out_duration, UiTokens.ANIM_FADE_OUT)
	fresh.free()


func _count(prefix: String) -> int:
	var n := 0
	for event: String in _events:
		if event.begins_with(prefix):
			n += 1
	return n
