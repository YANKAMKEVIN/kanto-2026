extends GutTest
## SceneRouter (jalon 2 §2.2, T5) sur une instance fraîche du routeur, jamais l'autoload :
## deux mini-cartes fabriquées en code (A : porte STEP_ON UP ; B : tapis PUSH DOWN) et un
## ScreenFade aux durées courtes.

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FADE_SCENE := preload("res://game/ui/components/screen_fade.tscn")
const FRAME := 1.0 / 60.0
const FADE_TIME := 0.05
const TIMEOUT := 3.0
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run",
]
## Carte A (8 × 6) : départ (3, 4), porte (3, 1) ouverte au nord (case (3, 0) libre).
const A_START := Vector2i(3, 4)
const A_DOOR := Vector2i(3, 1)
## Carte B (6 × 5) : tapis de sortie (2, 4) sur la dernière rangée.
const B_MAT := Vector2i(2, 4)

var _router: Node
var _world: Node2D
var _player: Player
var _fade: ScreenFade
## Cartes fabriquées, par identifiant (la dernière instance).
var _made: Dictionary[StringName, GameMap] = {}
var _events: Array[String] = []


func before_each() -> void:
	_made.clear()
	_events.clear()
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_router.fade_out_duration = FADE_TIME
	_router.fade_in_duration = FADE_TIME
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
	watch_signals(_router)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


# --- Mini-cartes --------------------------------------------------------------------

func _make_map(map_id: StringName) -> GameMap:
	var map: GameMap
	match map_id:
		&"a":
			map = _base_map(map_id, Vector2i(8, 6))
			_spawn(map, &"start", A_START)
			_spawn(map, &"door", A_DOOR)
			_warp(map, A_DOOR, Warp.Trigger.STEP_ON, Vector2i.UP, &"b", &"entrance")
		&"b":
			map = _base_map(map_id, Vector2i(6, 5))
			_spawn(map, &"entrance", B_MAT)
			_warp(map, B_MAT, Warp.Trigger.PUSH, Vector2i.DOWN, &"a", &"door")
		_:
			return null
	_made[map_id] = map
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


func _warp(
	map: GameMap, cell: Vector2i, trigger: Warp.Trigger, direction: Vector2i,
	to_map: StringName, to_spawn: StringName
) -> void:
	var point := WarpPoint.new()
	point.name = "Warp%d_%d" % [cell.x, cell.y]
	point.position = Grid.cell_to_world(cell)
	point.trigger = trigger
	point.direction = direction
	point.target_map = to_map
	point.target_spawn = to_spawn
	map.get_node(^"Warps").add_child(point)


# --- Outils -------------------------------------------------------------------------

## Démarre sur A ; les images du joueur sont ensuite simulées à la main.
func _start_on_a() -> GameMap:
	var map: GameMap = _router.start(&"a", &"start", Vector2i.UP)
	_player.set_process(false)
	return map


## Simule des images du joueur jusqu'à [param done] (ou [param max_seconds]).
func _simulate_until(done: Callable, max_seconds: float = 2.0) -> void:
	var frames := roundi(max_seconds / FRAME)
	for i: int in frames:
		_player._process(FRAME)
		if done.call():
			return


func _simulate(seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		_player._process(FRAME)


func _await_idle() -> void:
	await wait_until(func() -> bool: return not _router.is_transitioning(), TIMEOUT)


func _count(prefix: String) -> int:
	var n := 0
	for event: String in _events:
		if event.begins_with(prefix):
			n += 1
	return n


# --- 1. start -------------------------------------------------------------------------

func test_start_places_player_and_emits_changed_then_entered() -> void:
	var map := _start_on_a()
	assert_not_null(map)
	assert_eq(_router.get_current_map(), _made[&"a"])
	assert_eq(map.get_parent(), _world)
	assert_eq(_player.get_parent(), map.get_entities())
	assert_eq(_player.get_cell(), A_START)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_eq(_events, ["map_changed:a", "map_entered:a"] as Array[String])
	assert_false(_router.is_transitioning())
	assert_true(_player.is_input_enabled())
	assert_false(_fade.is_opaque())


# --- 2. porte STEP_ON ---------------------------------------------------------------

func test_step_on_door_locks_same_frame_then_arrives_in_b() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	var player_before := _player
	var moved_cells: Array[Vector2i] = []
	_player.moved.connect(func(cell: Vector2i) -> void: moved_cells.append(cell))
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return moved_cells.has(A_DOOR))
	# Même image que le pas terminé sur la porte : entrées déjà bloquées.
	assert_eq(_player.get_cell(), A_DOOR)
	assert_false(_player.is_input_enabled(), "bloqué dans la même image")
	assert_true(_router.is_transitioning())
	assert_signal_emitted_with_parameters(_router, "transition_started", [&"b"])
	Input.action_release(&"move_up")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map(), _made[&"b"])
	assert_eq(_player, player_before, "même instance du joueur")
	assert_eq(_player.get_parent(), _made[&"b"].get_entities())
	assert_eq(_player.get_cell(), B_MAT)
	assert_eq(_player.get_facing(), Vector2i.UP, "orientation conservée")
	assert_false(is_instance_valid(map_a), "carte A libérée")
	assert_true(_player.is_input_enabled(), "entrées rétablies")
	assert_false(_router.is_transitioning())


# --- 3. tapis PUSH ------------------------------------------------------------------

func test_holding_down_on_mat_returns_to_door_facing_down() -> void:
	_start_on_a()
	_router.change_map(&"b", &"entrance")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map(), _made[&"b"])
	_player.set_process(false)
	Input.action_press(&"move_down")
	_simulate_until(func() -> bool: return _router.is_transitioning())
	assert_true(_router.is_transitioning(), "pousser vers le bas déclenche le tapis")
	assert_false(_player.is_input_enabled())
	Input.action_release(&"move_down")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_router.get_current_map().map_id, &"a")
	assert_eq(_player.get_cell(), A_DOOR, "arrivée sur la case de porte")
	assert_eq(_player.get_facing(), Vector2i.DOWN)


# --- 4. direction tenue pendant le fondu ----------------------------------------------

func test_player_stays_on_door_during_fade_while_direction_held() -> void:
	_start_on_a()
	var grid_a := _made[&"a"].get_grid()
	Input.action_press(&"move_up")
	_simulate_until(func() -> bool: return _router.is_transitioning())
	assert_eq(_player.get_cell(), A_DOOR)
	# Le fondu avance sur les images du moteur ; le joueur, lui, reçoit encore des images.
	for i: int in 3:
		_simulate(0.3)
		await wait_process_frames(1)
		assert_true(_router.is_transitioning())
		if _router.get_current_map() != _made[&"a"]:
			break
		assert_eq(_player.get_cell(), A_DOOR, "reste sur la porte")
		assert_false(_player.is_moving())
		assert_false(grid_a.is_occupied(A_DOOR + Vector2i.UP), "case au-delà libre")
		assert_eq(_player.position, Grid.cell_to_world(A_DOOR))
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(_player.get_cell(), B_MAT)


# --- 5. un seul passage à la fois ------------------------------------------------------

func test_second_change_map_during_transition_is_ignored() -> void:
	_start_on_a()
	_events.clear()
	_router.change_map(&"b", &"entrance")
	_router.change_map(&"a", &"start")
	await _await_idle()
	await wait_process_frames(3)
	assert_eq(_count("transition_started"), 1)
	assert_eq(_count("map_entered"), 1)
	assert_eq(_router.get_current_map().map_id, &"b")
	assert_eq(_player.get_cell(), B_MAT)


# --- 6. carte ou spawn inconnus ----------------------------------------------------------

func test_unknown_map_keeps_current_map() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	_events.clear()
	_router.change_map(&"nowhere", &"entrance")
	await _await_idle()
	assert_push_error("carte inconnue")
	assert_eq(_router.get_current_map(), map_a)
	assert_eq(_player.get_parent(), map_a.get_entities())
	assert_eq(_player.get_cell(), A_START)
	assert_true(_player.is_input_enabled(), "entrées rétablies")
	assert_eq(_count("map_entered"), 0)
	assert_eq(_count("map_changed"), 0)
	assert_false(_fade.is_opaque(), "rideau relevé")


func test_unknown_spawn_keeps_current_map() -> void:
	_start_on_a()
	var map_a := _made[&"a"]
	_events.clear()
	_router.change_map(&"b", &"nowhere")
	await _await_idle()
	assert_push_error("spawn inconnu")
	assert_eq(_router.get_current_map(), map_a)
	assert_eq(_player.get_cell(), A_START)
	assert_true(_player.is_input_enabled())
	assert_eq(_count("map_entered"), 0)
	assert_eq(_world.get_child_count(), 1, "carte B écartée")


# --- 7. rideau opaque pendant le changement ------------------------------------------------

func test_fade_is_opaque_when_map_changes() -> void:
	_start_on_a()
	var opaque_at_change: Array[bool] = []
	_router.map_changed.connect(func(_map: GameMap) -> void:
		opaque_at_change.append(_fade.is_opaque()))
	_router.change_map(&"b", &"entrance")
	await wait_for_signal(_router.map_entered, TIMEOUT)
	assert_eq(opaque_at_change, [true] as Array[bool])
	assert_false(_fade.is_opaque(), "rideau relevé à l'arrivée")
	assert_eq(_events.slice(-3), [
		"transition_started:b", "map_changed:b", "map_entered:b",
	] as Array[String])


# --- Divers --------------------------------------------------------------------------------

func test_without_fade_transition_is_immediate() -> void:
	_router.setup(_world, _player, null)
	_start_on_a()
	_router.change_map(&"b", &"entrance")
	assert_eq(_router.get_current_map(), _made[&"b"])
	assert_false(_router.is_transitioning())
	assert_true(_player.is_input_enabled())


func test_setup_again_disconnects_previous_player() -> void:
	var other := PLAYER_SCENE.instantiate() as Player
	autofree(other)
	_router.setup(_world, other, _fade)
	assert_false(_player.moved.is_connected(_router._on_player_moved))
	assert_true(other.moved.is_connected(_router._on_player_moved))
	assert_eq(_router.get_player(), other)


func test_default_fade_durations_come_from_tokens() -> void:
	var fresh: Node = ROUTER_SCRIPT.new()
	assert_eq(fresh.fade_out_duration, UiTokens.ANIM_FADE_OUT)
	assert_eq(fresh.fade_in_duration, UiTokens.ANIM_FADE_IN)
	assert_eq(fresh.maps_dir, MapCatalog.MAPS_DIR)
	fresh.free()


func test_real_maps_neighbors_prefetched_then_used() -> void:
	# Cartes réelles (sans fabrique) : les cibles des warps se chargent en arrière-plan.
	_router.map_factory = Callable()
	_router.setup(_world, _player, null)
	var map: GameMap = _router.start(&"player_house_1f", &"entrance", Vector2i.UP)
	assert_not_null(map)
	var town := MapCatalog.scene_path(&"pallet_town")
	var bedroom := MapCatalog.scene_path(&"player_house_2f")
	assert_true(_router._prefetching.has(town), "Bourg Palette préchargé")
	assert_true(_router._prefetching.has(bedroom), "chambre préchargée")
	_router.change_map(&"pallet_town", &"player_house_door")
	assert_eq(_router.get_current_map().map_id, &"pallet_town")
	assert_eq(_player.get_cell(), Vector2i(36, 9))
	assert_false(_router._prefetching.has(town), "chargement récupéré")
	assert_true(_router._scenes.has(town), "scène gardée en cache")
