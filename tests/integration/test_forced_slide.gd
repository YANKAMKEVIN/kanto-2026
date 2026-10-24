extends GutTest
## Courants du Surf joués par [ForcedSlideDirector] (passe systèmes 2 T15, `systemes-2.md` §2.5
## point 7, §2.6). Les dalles du J20 restent couvertes par `test_spin_slide.gd`.
##
## Première partie : une instance fraîche du routeur (jamais l'autoload), sans rideau, branchée
## comme dans Boot (directeur d'abord sur le pas du joueur ; `map_changed` → `set_map`,
## `map_entered` → `ride_from_here`, `warp_reached` → `follow_warp_at`), sur des mini-cartes
## 10 × 3 fabriquées en code : la rangée 1 est de l'eau surfable, les rangées 0 et 2 de la terre.
## - `calm` : courant → en (3..5, 1), fin sur l'eau calme (6, 1) ;
## - `shore` : eau (0..6, 1), courant → en (3..6, 1), fin sur la terre (7, 1) : descente ;
## - `falls` : courant → en (3..6, 1), passage STEP_ON en (6, 1) vers `calm` / `start` ;
## - `loop` : courants (3, 1) → et (4, 1) ← (erreur de données).
## Le joueur part de (2, 1), en Surf, tourné → (spawn `start`) ; `on_current` est la case (3, 1).
##
## Seconde partie : la vraie scène Boot sur la vraie Route 2 (la carte de QA `qa_mount` est retirée
## en S2Z, T33), eau et courants posés en mémoire dans sa grille par le test, le long de la rangée
## du passage de bord vers la Route 2 est (partie pas stable pendant la glisse, contrôles cachés ;
## passage de bord en fin de courant).

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_forced_slide_save.json"
const MAP_SIZE := Vector2i(10, 3)
const START := Vector2i(2, 1)
const ENTRY := Vector2i(3, 1)
const CALM_PATH: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)]
const SHORE_PATH: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
	Vector2i(7, 1)]
const TIMEOUT := 10.0

var _router: Node
var _world: Node2D
var _player: Player
var _director: ForcedSlideDirector
var _sim: FrameSim
var _moves: Array[Vector2i] = []
var _move_frames: Array[int] = []
var _facings: Array[Vector2i] = []
var _events: Array[String] = []


func before_each() -> void:
	_moves.clear()
	_move_frames.clear()
	_facings.clear()
	_events.clear()
	_sim = null
	_player = PLAYER_SCENE.instantiate() as Player
	autofree(_player)


func after_each() -> void:
	if _sim != null:
		_sim.finish()
	for action: StringName in [&"run", &"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


# --- Courants (routeur frais) --------------------------------------------------------------

func test_a_current_carries_the_surfer_to_calm_water_at_surf_speed() -> void:
	_start_router(&"calm")
	await _step_right_onto_the_current()
	assert_true(_director.is_running(), "la glisse part dans le pas qui pose sur le courant")
	assert_true(_director.get_slide() is CurrentField.Ride, "trajet du courant")
	assert_true(_player.is_blocked_by(ForcedSlideDirector.LOCK_REASON), "joueur bloqué")
	assert_false(_player.is_running(), "pas de course sur un courant")
	await _run_slide()
	assert_eq(_moves, [ENTRY] + CALM_PATH, "un pas par case du courant")
	assert_eq(_facings, [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT] as Array[Vector2i],
		"tourné dans le sens du flux")
	assert_eq(_events, ["started:%s" % ENTRY, "finished:%s" % CALM_PATH.back()] as Array[String])
	assert_eq(_player.get_cell(), CALM_PATH.back())
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "toujours en Surf sur l'eau calme")
	assert_true(_player.is_input_enabled(), "libre à l'arrêt")
	# Au pas près : chaque pas dure un pas de Surf (pas fini avant, au plus une image de plus).
	var per_step := ceili(MountRules.step_duration(Mount.Kind.SURF, false) / FrameSim.STEP
		- 0.001)
	for i: int in range(1, _move_frames.size()):
		var frames := _move_frames[i] - _move_frames[i - 1]
		assert_between(frames, per_step, per_step + 1, "pas %d : %d images" % [i, frames])
	assert_push_error_count(0)


func test_a_current_ending_on_land_dismounts() -> void:
	_start_router(&"shore")
	await _step_right_onto_the_current()
	assert_true(_director.is_running())
	var mount_at_finish: Array[Mount.Kind] = []
	_director.slide_finished.connect(func(_cell: Vector2i) -> void:
		mount_at_finish.append(_player.get_mount()))
	await _run_slide()
	assert_eq(_moves, [ENTRY] + SHORE_PATH)
	assert_eq(_player.get_cell(), Vector2i(7, 1), "sur la rive")
	assert_eq(mount_at_finish, [Mount.Kind.NONE] as Array[Mount.Kind], "à pied dès la fin")
	assert_eq(_player.get_mount(), Mount.Kind.NONE)
	assert_true(_player.is_input_enabled())


func test_a_current_ending_on_a_warp_follows_it_with_the_lock_lifted() -> void:
	_start_router(&"falls")
	var locked_at_warp: Array[bool] = []
	_director.warp_reached.connect(func(cell: Vector2i, direction: Vector2i) -> void:
		_events.append("warp:%s:%s" % [cell, direction])
		locked_at_warp.append(_player.is_blocked_by(ForcedSlideDirector.LOCK_REASON)))
	await _step_right_onto_the_current()
	assert_true(_director.is_running())
	assert_eq((_director.get_slide() as ForcedSlide).warp, true, "fin sur un passage")
	await _run_slide()
	await _sim.run_until(func() -> bool: return _router.get_current_map().map_id == &"calm",
		TIMEOUT)
	assert_eq(_events, ["started:%s" % ENTRY, "finished:(6, 1)", "warp:(6, 1):(1, 0)"]
		as Array[String])
	assert_eq(locked_at_warp, [false] as Array[bool], "verrou levé avant le passage")
	assert_eq(_router.get_current_map().map_id, &"calm", "passage suivi")
	assert_eq(_player.get_cell(), START, "au spawn d'arrivée")
	assert_false(_director.is_running(), "aucune glisse à l'arrivée (pas sur un courant)")
	assert_true(_player.is_input_enabled(), "libre après le passage")
	assert_push_error_count(0)


func test_no_slide_on_foot() -> void:
	_start_router(&"calm", &"start", Mount.Kind.NONE)
	# À pied, rangée de terre : un courant posé sur (3, 0) ne s'applique pas.
	_router.get_current_map().get_grid().set_current(Vector2i(3, 0), Vector2i.RIGHT)
	_router.get_current_map().spawn_player_at(_player, Vector2i(2, 0), Vector2i.RIGHT)
	_sim = FrameSim.new(get_tree(), [_player])
	Input.action_press(&"move_right")
	await _sim.frame()
	Input.action_release(&"move_right")
	await _sim.run_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), Vector2i(3, 0))
	assert_false(_director.is_running(), "aucune glisse à pied")
	assert_eq(_events, [] as Array[String])
	assert_false(_director.ride_from_here(), "ni à l'arrivée")


func test_resume_on_a_current_rides_from_the_arrival() -> void:
	_start_router(&"calm", &"on_current")
	assert_true(_director.is_running(), "la glisse part dès l'arrivée")
	assert_false(_director.get_slide().can_save(), "aucune sauvegarde pendant la glisse")
	_sim = FrameSim.new(get_tree(), [_player])
	await _run_slide()
	assert_eq(_moves, CALM_PATH)
	assert_eq(_player.get_cell(), CALM_PATH.back())
	assert_true(_player.is_input_enabled())


func test_resume_on_a_current_on_foot_does_not_ride() -> void:
	_start_router(&"calm", &"on_current", Mount.Kind.NONE)
	assert_eq(_player.get_cell(), ENTRY)
	assert_false(_director.is_running(), "à pied : aucune glisse")


func test_a_data_error_plays_no_slide() -> void:
	_start_router(&"loop")
	await _step_right_onto_the_current()
	await _sim.run_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_push_error("LOOP")
	assert_false(_director.is_running(), "aucune glisse")
	assert_eq(_player.get_cell(), ENTRY, "le joueur reste sur la case")
	assert_true(_player.is_input_enabled())


# --- Boot ---------------------------------------------------------------------------------

func test_boot_is_not_stable_during_a_current_and_follows_an_edge_warp() -> void:
	var saved_router := [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	GameState.clock = FixedClock.new("2026-10-21T15:00:00")
	var boot := BOOT_SCENE.instantiate() as Boot
	boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	boot.start_map = &"route_2"
	boot.start_spawn = &"from_route_2_east_n"
	boot.start_facing = Vector2i.LEFT
	add_child_autofree(boot)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	GameState.new_game(7)
	assert_eq(boot.get_spin_director(), boot.get_forced_slide_director(), "ancien nom gardé")
	var player := boot.get_player()
	var director := boot.get_forced_slide_director()
	# Rangée 43 : eau (36..41, 43), courant → en (37..40, 43) jusqu'au passage de bord (41, 43),
	# un warp PUSH → vers la Route 2 est.
	var grid := boot.get_map().get_grid()
	assert_eq(boot.get_map().get_warps().find_on_push(Vector2i(41, 43), Vector2i.RIGHT) \
		.target_map, &"route_2_east", "passage de bord réel")
	boot.get_map().spawn_player_at(player, Vector2i(36, 43), Vector2i.RIGHT)
	for x: int in range(36, 42):
		assert_true(grid.is_free(Vector2i(x, 43), player), "case libre (%d, 43)" % x)
		grid.set_surfable(Vector2i(x, 43))
	for x: int in range(37, 41):
		grid.set_current(Vector2i(x, 43), Vector2i.RIGHT)
	player.set_mount(Mount.Kind.SURF)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return boot.is_stable(), TIMEOUT)
	_sim = FrameSim.new(get_tree(), [player])
	Input.action_press(&"move_right")
	await _sim.frame()
	Input.action_release(&"move_right")
	await _sim.run_until(func() -> bool: return director.is_running() or not player.is_moving(),
		TIMEOUT)
	assert_true(director.is_running(), "glisse partie")
	assert_false(boot.is_stable(), "partie pas stable pendant la glisse")
	assert_false(boot.get_hud().are_controls_visible(), "contrôles cachés")
	await _sim.run_until(func() -> bool: return not director.is_running(), TIMEOUT)
	_sim.finish()
	_sim = null
	await wait_until(func() -> bool:
		return boot.get_map().map_id == &"route_2_east" and boot.is_stable(), TIMEOUT)
	assert_eq(boot.get_map().map_id, &"route_2_east", "warp de bord suivi en fin de courant")
	assert_true(player.is_input_enabled(), "joueur libre à l'arrivée")
	assert_false(director.is_running())
	SceneRouter.fade_out_duration = saved_router[0]
	SceneRouter.fade_in_duration = saved_router[1]
	GameState.clock = DeviceClock.new()


# --- Outils -------------------------------------------------------------------------------

## Routeur frais branché comme dans Boot, puis départ sur [param map_id] / [param spawn] avec la
## monture [param mount].
func _start_router(map_id: StringName, spawn: StringName = &"start",
		mount: Mount.Kind = Mount.Kind.SURF) -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_director = ForcedSlideDirector.new()
	add_child_autofree(_director)
	# Directeur d'abord sur le pas du joueur (comme Boot), routeur ensuite.
	_director.setup(_player, null)
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_router.setup(_world, _player)
	_router.map_changed.connect(_director.set_map)
	_router.map_entered.connect(func(_map: GameMap) -> void: _director.ride_from_here())
	_director.warp_reached.connect(func(cell: Vector2i, direction: Vector2i) -> void:
		_router.follow_warp_at(cell, direction))
	_player.moved.connect(func(cell: Vector2i) -> void:
		_moves.append(cell)
		_move_frames.append(_sim.frames if _sim != null else -1))
	_player.step_started.connect(func(_from: Vector2i, _to: Vector2i, _kind: StringName) -> void:
		if _director.is_running():
			_facings.append(_player.get_facing()))
	_director.slide_started.connect(func(slide: ForcedSlide) -> void:
		_events.append("started:%s" % slide.start))
	_director.slide_finished.connect(func(cell: Vector2i) -> void:
		_events.append("finished:%s" % cell))
	_player.set_mount(mount)
	assert_not_null(_router.start(map_id, spawn, Vector2i.RIGHT), "carte %s" % map_id)


## Un pas libre (entrée tenue une image) de (2, 1) vers (3, 1), en images simulées ; rend la main
## dès que la glisse est partie (ou après le pas).
func _step_right_onto_the_current() -> void:
	assert_eq(_player.get_cell(), START, "au départ")
	_moves.clear()
	_move_frames.clear()
	_sim = FrameSim.new(get_tree(), [_player])
	Input.action_press(&"move_right")
	await _sim.frame()
	Input.action_release(&"move_right")
	assert_true(_player.is_moving(), "le pas libre est parti")
	await _sim.run_until(func() -> bool:
		return _director.is_running() or not _player.is_moving(), TIMEOUT)


## Images simulées jusqu'à la fin de la glisse (signal différé compris).
func _run_slide() -> void:
	await _sim.run_until(func() -> bool:
		return not _director.is_running() and not _player.is_moving(), TIMEOUT)


func _make_map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.name = String(map_id).to_upper()
	map.map_id = map_id
	map.size = MAP_SIZE
	for group: String in ["Entities", "Spawns", "Warps"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	_spawn(map, &"start", START)
	_spawn(map, &"on_current", ENTRY)
	var water_end := 6 if map_id == &"shore" else MAP_SIZE.x - 1
	for x: int in range(0, water_end + 1):
		map.surf_cells.append(Vector2i(x, 1))
	match map_id:
		&"calm":
			_current(map, 3, 5, Vector2i.RIGHT)
		&"shore", &"falls":
			_current(map, 3, 6, Vector2i.RIGHT)
		&"loop":
			map.current_cells[Vector2i(3, 1)] = Vector2i.RIGHT
			map.current_cells[Vector2i(4, 1)] = Vector2i.LEFT
	if map_id == &"falls":
		var point := WarpPoint.new()
		point.name = "Falls"
		point.position = Grid.cell_to_world(Vector2i(6, 1))
		point.trigger = Warp.Trigger.STEP_ON
		point.target_map = &"calm"
		point.target_spawn = &"start"
		map.get_node(^"Warps").add_child(point)
	return map


func _current(map: GameMap, from_x: int, to_x: int, direction: Vector2i) -> void:
	for x: int in range(from_x, to_x + 1):
		map.current_cells[Vector2i(x, 1)] = direction


func _spawn(map: GameMap, spawn_name: StringName, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = Grid.cell_to_world(cell)
	map.get_node(^"Spawns").add_child(marker)
