extends GutTest
## Arène de Jadielle (jalon 28, `docs/tech/jalon-28.md` §2.1, §5) sur la vraie scène : **grille de
## la scène = grille fonctionnelle** `tools/plans/jadielle_arene.txt` (24 × 22), nœud `SpinTiles`
## (flèches et arrêts de la grille), douze dalles dont la glissade redonne exactement le trajet
## Rouge/Bleu et finit sur la case d'arrêt, aucun personnage sur une dalle ni sur un trajet,
## Dresseurs des données = positions de la grille, sortie vers Jadielle ; puis la vraie scène Boot :
## glisse réelle sur la dalle (21, 13) (pas par pas, `FrameSim`) et reprise d'une sauvegarde posée
## sur une dalle.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const MAP_PATH := "res://game/world/maps/viridian_gym.tscn"
const PLAN_PATH := "res://tools/plans/jadielle_arene.txt"
const SAVE_PATH := "user://test_viridian_gym_save.json"
const MAP := &"viridian_gym"
const SIZE := Vector2i(24, 22)
const FADE := 0.05
const TIMEOUT := 12.0
## Scénario Boot : départ (21, 14) tourné ↑, dalle ↑ (21, 13), trajet N9, arrêt (21, 4).
const START := Vector2i(21, 14)
const ARROW := Vector2i(21, 13)
const STOP := Vector2i(21, 4)

var _plan: PlanGrid
var _map: GameMap
var _grid: GridWorld
var _field: SpinTileField
var _roster: NpcRoster
var _boot: Boot
var _player: Player
var _spin: ForcedSlideDirector
var _fs: MemoryFs
var _sim: FrameSim
var _saved_router: Array = []
var _moves: Array[Vector2i] = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_field = _map.get_node(^"SpinTiles") as SpinTileField
	_roster = NpcRoster.load_for_map(MAP)


func after_all() -> void:
	_map.free()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T15:00:00")
	_fs = MemoryFs.new()
	_moves.clear()
	_sim = null


func after_each() -> void:
	if _sim != null:
		_sim.finish()
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	get_tree().paused = false
	for action: StringName in [&"interact", &"run", &"menu", &"move_up", &"move_down",
			&"move_left", &"move_right"]:
		Input.action_release(action)


func _walkable(cell: Vector2i) -> bool:
	return not _grid.is_solid(cell)


## Dalles de la grille : [{id, start, dir (lettre), steps, stop}].
func _arrows_of_plan() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] != "dalle":
			continue
		var trip := _plan.attr(id, "trajet")
		var stop_text := _plan.attr(id, "arret")
		found.append({"id": id, "start": _plan.cell_of(id), "letter": trip.substr(0, 1),
			"steps": int(trip.substr(1)), "stop": Vector2i(int(stop_text.get_slice(",", 0)),
			int(stop_text.get_slice(",", 1)))})
	return found


# --- Carte = grille ---------------------------------------------------------------------------

func test_metadata_and_size() -> void:
	assert_eq(_map.map_id, MAP)
	assert_eq(_map.size, SIZE)
	assert_eq(_plan.width, SIZE.x)
	assert_eq(_plan.height, SIZE.y)
	assert_true(_map.interior)
	assert_eq(_plan.walkable, ".<>^voX")
	assert_not_null(_field, "nœud SpinTiles")


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell)
			if _grid.is_solid(cell) != solid:
				mismatches += 1
				if mismatches <= 5:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/jadielle_arene.txt")


func test_spin_tiles_match_the_grid_characters() -> void:
	var expected_arrows: Dictionary[Vector2i, Vector2i] = {}
	for character: String in SpinTileRules.ARROW_CHARS:
		for cell: Vector2i in _plan.cells_of(character):
			expected_arrows[cell] = SpinTileRules.direction_of_char(character)
	assert_eq(_field.arrows.size(), 12, "douze dalles (RB)")
	assert_eq(_field.arrows, expected_arrows, "flèches = « < > ^ v » de la grille")
	var expected_stops := _plan.cells_of(SpinTileRules.STOP_CHAR)
	var stops := _field.stops.duplicate()
	stops.sort()
	expected_stops.sort()
	assert_eq(stops, expected_stops, "arrêts = « o » de la grille")
	assert_eq(_field.check(_walkable), PackedStringArray(), "SpinTileField.check() muet")


func test_exit_leads_to_viridian_city_and_the_spawns_exist() -> void:
	for cell: Vector2i in [Vector2i(18, 20), Vector2i(19, 20)]:
		var out := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(out, "sortie %s" % cell)
		if out != null:
			assert_eq([out.target_map, out.target_spawn], [&"viridian_city", &"from_gym"])
	assert_eq(_map.get_spawn_cell(&"entrance"), Vector2i(18, 20))
	assert_eq(_map.get_spawn_cell(&"before_giovanni"), Vector2i(4, 4))
	assert_eq(_plan.cell_of("entree"), Vector2i(18, 20))
	assert_eq(_plan.cell_of("parler_giovanni"), Vector2i(4, 4))
	var city := (load(MapCatalog.scene_path(&"viridian_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	assert_true(city.has_spawn(&"from_gym"))
	assert_eq(city.get_spawn_cell(&"from_gym"), Vector2i(9, 10))


# --- Dalles -----------------------------------------------------------------------------------

func test_every_arrow_slides_exactly_along_the_rb_path() -> void:
	var arrows := _arrows_of_plan()
	assert_eq(arrows.size(), 12, "douze dalles dans la grille")
	for entry: Dictionary in arrows:
		var start: Vector2i = entry["start"]
		var id: String = entry["id"]
		var direction := SpinTileRules.compass_direction(entry["letter"])
		assert_ne(direction, Vector2i.ZERO, "%s : direction du trajet" % id)
		assert_true(_field.is_arrow(start), "%s : %s est une dalle" % [id, start])
		assert_eq(_field.arrows.get(start), direction, "%s : sens de la dalle" % id)
		var slide := _field.slide_from(start, _walkable)
		assert_true(slide.is_ok(), "%s : %s" % [id, slide.status_name()])
		var expected: Array[Vector2i] = []
		for i: int in range(1, int(entry["steps"]) + 1):
			expected.append(start + direction * i)
		assert_eq(slide.cells, expected, "%s : %d pas vers %s" % [id, entry["steps"],
			entry["letter"]])
		assert_eq(slide.end, entry["stop"], "%s : finit sur l'arrêt" % id)
		assert_true(_field.stops.has(slide.end), "%s : l'arrêt est une case d'arrêt" % id)
		# Aucune flèche ni arrêt au milieu du trajet, aucun mur.
		for i: int in expected.size() - 1:
			assert_false(_field.is_arrow(expected[i]), "%s : flèche au milieu (%s)" % [id,
				expected[i]])
			assert_false(_field.stops.has(expected[i]), "%s : arrêt au milieu" % id)
			assert_true(_walkable(expected[i]))
		assert_eq(_field.safe_cell(start, _walkable), entry["stop"], "%s : reprise sur l'arrêt" % id)


func test_no_character_or_object_sits_on_an_arrow_a_stop_or_a_path() -> void:
	var forbidden: Dictionary[Vector2i, String] = {}
	for entry: Dictionary in _arrows_of_plan():
		forbidden[entry["start"]] = "dalle %s" % entry["id"]
		var slide := _field.slide_from(entry["start"], _walkable)
		for cell: Vector2i in slide.cells:
			forbidden[cell] = "trajet de %s" % entry["id"]
	for cell: Vector2i in _field.stops:
		forbidden[cell] = "case d'arrêt"
	assert_gt(_roster.get_all().size(), 10, "PNJ des données lus")
	for spec: NpcSpec in _roster.get_all():
		assert_false(forbidden.has(spec.cell), "%s en %s : sur %s" % [spec.id, spec.cell,
			forbidden.get(spec.cell, "")])
		assert_false(_grid.is_solid(spec.cell), "%s : case libre" % spec.id)


func test_trainers_of_the_data_are_the_trainers_of_the_grid() -> void:
	var from_plan: Dictionary[StringName, String] = {}
	var count := 0
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] != "dresseur":
			continue
		count += 1
		var trainer := StringName(_plan.attr(id, "trainer"))
		from_plan[trainer] = id
		var spec: NpcSpec = null
		for candidate: NpcSpec in _roster.get_all():
			if candidate.trainer_id == trainer:
				spec = candidate
		assert_not_null(spec, "%s : Dresseur %s dans les données" % [id, trainer])
		if spec == null:
			continue
		var facing: Vector2i = {"left": Vector2i.LEFT, "right": Vector2i.RIGHT,
			"up": Vector2i.UP, "down": Vector2i.DOWN}[_plan.attr(id, "facing")]
		assert_eq(spec.cell, _plan.cell_of(id), "%s : case" % id)
		assert_eq(spec.facing, facing, "%s : regard" % id)
		assert_eq(spec.sight, int(_plan.attr(id, "sight")), "%s : portée de vue" % id)
	assert_eq(count, 8, "huit Dresseurs (RB)")
	var trainers_in_data := 0
	for spec: NpcSpec in _roster.get_all():
		if spec.is_trainer():
			trainers_in_data += 1
			assert_true(from_plan.has(spec.trainer_id), "%s est dans la grille" % spec.trainer_id)
	assert_eq(trainers_in_data, 8)
	# Giovanni, le guide et l'objet aux cases de la grille.
	assert_eq(_roster.get_spec(&"giovanni").cell, _plan.cell_of("giovanni"))
	assert_eq(_roster.get_spec(&"gym_guide").cell, _plan.cell_of("guide"))
	assert_eq(_roster.get_spec(&"viridian_gym_item_1").cell, _plan.cell_of("rappel"))


# --- Boot réel : glisse ------------------------------------------------------------------------

func test_a_real_slide_on_the_first_arrow_ends_on_its_stop() -> void:
	await _start()
	assert_eq(_spin.get_field(), _boot.get_map().get_node(^"SpinTiles"), "SpinTiles trouvé")
	assert_eq(_player.get_cell(), START)
	_player.face(Vector2i.UP)
	_sim = FrameSim.new(get_tree(), [_player])
	Input.action_press(&"move_up")
	await _sim.frame()
	Input.action_release(&"move_up")
	assert_true(_player.is_moving(), "le pas libre est parti")
	await _sim.run_until(func() -> bool: return _spin.is_running() or not _player.is_moving(),
		TIMEOUT)
	assert_true(_spin.is_running(), "la glisse part sur la dalle")
	assert_false(_boot.is_stable(), "partie pas stable pendant la glisse")
	await _sim.run_until(func() -> bool:
		return not _spin.is_running() and not _player.is_moving(), TIMEOUT)
	var expected: Array[Vector2i] = [ARROW]
	for y: int in range(12, 3, -1):
		expected.append(Vector2i(21, y))
	assert_eq(_moves, expected, "un pas par case, de la dalle à l'arrêt")
	assert_eq(_player.get_cell(), STOP)
	assert_eq(_player.get_facing(), Vector2i.UP)
	assert_eq(_boot.get_map().map_id, MAP, "carte inchangée")
	assert_false(_spin.is_running())
	assert_true(_player.is_input_enabled(), "joueur libre à l'arrêt")
	assert_true(_boot.is_stable(), "partie stable à l'arrêt")
	assert_push_error_count(0)


func test_a_save_on_an_arrow_resumes_on_its_stop() -> void:
	await _start()
	GameState.set_player_location(MAP, ARROW, Vector2i.UP)
	assert_eq(_boot.save_system.write(GameState.to_dict()), OK)
	_boot.queue_free()
	await wait_process_frames(2)
	await _boot_on(&"")
	assert_eq(_boot.get_map().map_id, MAP)
	assert_eq(_player.get_cell(), STOP, "posé sur la case d'arrêt de la dalle")
	assert_false(_spin.is_running(), "aucune glisse jouée")
	assert_true(_boot.is_stable())
	assert_eq(_spin.stable_cell(ARROW), STOP)
	assert_eq(_spin.stable_cell(START), START)


# --- Outils ------------------------------------------------------------------------------------

func _boot_on(map: StringName, spawn: StringName = &"") -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	if not map.is_empty():
		_boot.start_map = map
		_boot.start_spawn = spawn
		_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_spin = _boot.get_spin_director()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player.moved.connect(func(cell: Vector2i) -> void: _moves.append(cell))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Boot neuve dans l'Arène, joueur posé en (21, 14) tourné ↑.
func _start() -> void:
	await _boot_on(MAP, &"entrance")
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	_boot.get_map().refresh_npcs(GameState.flags)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_map().spawn_player_at(_player, START, Vector2i.UP)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_moves.clear()
