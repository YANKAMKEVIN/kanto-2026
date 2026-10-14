extends GutTest
## **Reprise du sas** (jalon 13 T8, docs/tech/jalon-13.md §2.2, §2.19) : la Route 4 remplace le sas
## du J12 sous le **même identifiant** `route_4`. Une partie sauvegardée dans le sas, sur
## **n'importe quelle case praticable de `tools/plans/route_4_sas.txt`** (la grille du sas est lue
## par [PlanGrid], pas recopiée), doit se recharger sur la **même case**, **praticable**, de la
## nouvelle scène. Pour chaque case : sauvegarde v6 écrite puis relue (système de fichiers en
## mémoire), partie rechargée dans une instance neuve de GameState, reprise de la carte
## (`find_standing_cell` = même case). Un échantillon de cases passe par la vraie scène Boot.
## Plus, sur la vraie scène : `from_mt_moon` (3, 6), les cases du futur déclencheur
## `route_4_reached` (4, 5..9) praticables, l'échelle vers B2F, le bord est vers Azuria.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAS_PLAN := "res://tools/plans/route_4_sas.txt"
const SAVE_PATH := "user://test_route_4_resume_save.json"
const MAP_ID := &"route_4"
const FADE := 0.05
## Cases passées par la vraie scène Boot (coins du sas, bouche, arrivée, ancien bord est,
## déclencheur futur).
const BOOT_SAMPLE: Array[Vector2i] = [
	Vector2i(2, 6), Vector2i(3, 6), Vector2i(3, 5), Vector2i(4, 9), Vector2i(8, 3),
	Vector2i(22, 3), Vector2i(23, 6), Vector2i(23, 7), Vector2i(22, 11), Vector2i(6, 11),
]

var _sas: PlanGrid
var _map: GameMap
var _fs: MemoryFs
var _save: SaveSystem
var _fades: Array[float] = []


func before_all() -> void:
	_sas = PlanGrid.new()
	assert_true(_sas.load_file(SAS_PLAN), _sas.error)
	_map = (load(MapCatalog.scene_path(MAP_ID)) as PackedScene).instantiate() as GameMap
	add_child(_map)


func after_all() -> void:
	_map.free()


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-12T10:00:00")
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


## Cases praticables du sas, panneau exclu (solide dans le sas comme dans la Route 4).
func _sas_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var sign: Array[Vector2i] = _sas.cells_at("panneau_route_4")
	for cell: Vector2i in _sas.cells_of(_sas.walkable):
		if not sign.has(cell):
			cells.append(cell)
	return cells


func test_the_sas_grid_is_what_the_test_thinks_it_is() -> void:
	assert_eq(_sas.width, 24)
	assert_eq(_sas.height, 14)
	assert_eq(_sas.walkable, ".=De")
	assert_gt(_sas_cells().size(), 150, "le sas a ≈ 200 cases praticables")


func test_every_walkable_cell_of_the_sas_resumes_on_the_same_walkable_cell() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var grid := _map.get_grid()
	var checked := 0
	for cell: Vector2i in _sas_cells():
		var state: Node = autofree(GameStateScript.new())
		state.clock = FixedClock.new("2026-10-12T10:00:00")
		state.new_game(7)
		state.set_player_location(MAP_ID, cell, Vector2i.DOWN)
		assert_eq(_save.write(state.to_dict()), OK, "sauvegarde écrite en %s" % cell)
		var content := _save.read()
		assert_eq(content.get("map"), "route_4", "carte écrite")
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(content, data), "rechargée en %s" % cell)
		assert_eq(loaded.current_map, MAP_ID, "même carte en %s" % cell)
		assert_eq(loaded.player_cell, cell, "même case écrite puis lue")
		assert_true(MapCatalog.has_map(loaded.current_map))
		assert_false(grid.is_solid(cell) or grid.is_water(cell),
			"%s : praticable dans la nouvelle Route 4" % cell)
		assert_true(grid.is_in_bounds(cell))
		assert_eq(_map.find_standing_cell(cell), cell, "%s : reprise sur la même case" % cell)
		checked += 1
	assert_eq(checked, _sas_cells().size())
	gut.p("reprise du sas : %d cases vérifiées" % checked)


func test_every_resume_cell_of_the_sas_is_in_the_same_place_as_the_plan() -> void:
	# Même repère : la grille de la Route 4 reprend le sas case pour case (colonnes 0..23,
	# rangées 0..13) ; praticable reste praticable, sauf ce que la grille permet (rangée du
	# rebord : non, elle reste fermée ici).
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_4.txt"), plan.error)
	for y: int in _sas.height:
		for x: int in _sas.width:
			var cell := Vector2i(x, y)
			if _sas.is_walkable(cell):
				assert_true(plan.is_walkable(cell), "sas %s « %s » praticable dans la Route 4"
					% [cell, _sas.at(cell)])
			elif x < 23:
				assert_eq(plan.at(cell), _sas.at(cell), "case %s inchangée" % cell)


func test_a_sample_of_cells_goes_through_the_real_boot() -> void:
	for cell: Vector2i in BOOT_SAMPLE:
		assert_true(_sas.is_walkable(cell), "échantillon %s praticable dans le sas" % cell)
		_fs = MemoryFs.new()
		_save = SaveSystem.new(_fs, SAVE_PATH)
		_write_saved_game(cell, Vector2i.LEFT)
		var boot := BOOT_SCENE.instantiate() as Boot
		boot.save_system = _save
		add_child_autofree(boot)
		await wait_process_frames(2)
		assert_true(boot.has_resumed(), "partie reprise (%s)" % cell)
		assert_eq(boot.get_map().map_id, MAP_ID, "même carte")
		assert_eq(boot.get_player().get_cell(), cell, "même case")
		assert_eq(boot.get_player().get_facing(), Vector2i.LEFT, "même orientation")
		assert_false(boot.get_map().get_grid().is_solid(cell), "case praticable")
		remove_child(boot)
		boot.free()
	assert_push_error_count(0)


func _write_saved_game(cell: Vector2i, facing: Vector2i) -> void:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-12T10:00:00")
	state.new_game(42)
	state.flags.set_flag(&"route_3_entered")
	state.discover_map(MAP_ID)
	state.set_player_location(MAP_ID, cell, facing)
	assert_eq(_save.write(state.to_dict()), OK, "sauvegarde type écrite")
	_fs.journal.clear()


# --- Sur la vraie scène ---------------------------------------------------------------

func test_the_ladder_the_arrival_the_future_trigger_and_the_east_edge_are_kept() -> void:
	var grid := _map.get_grid()
	assert_eq(_map.get_spawn_cell(&"from_mt_moon"), Vector2i(3, 6), "arrivée de B2F")
	var ladder := _map.get_warps().find_on_step(Vector2i(2, 6), Vector2i.LEFT)
	assert_not_null(ladder, "la bouche de la grotte")
	if ladder != null:
		assert_eq([ladder.target_map, ladder.target_spawn], [&"mt_moon_b2f", &"arrivee_s"],
			"l'échelle mène toujours à B2F")
	# Futur déclencheur `route_4_reached` (J12 T28) sur (4, 5..9) : cases praticables.
	for y: int in range(5, 10):
		assert_false(grid.is_solid(Vector2i(4, y)), "(4, %d) praticable" % y)
	assert_false(grid.is_solid(Vector2i(6, 6)))
	assert_true(grid.is_solid(Vector2i(6, 5)), "panneau (6, 5)")
	var east := _map.get_warps().find_on_push(Vector2i(63, 20), Vector2i.RIGHT)
	assert_not_null(east, "le bord est mène à Azuria")
	if east != null:
		assert_eq(east.target_map, &"cerulean_city")
	for cell: Vector2i in [Vector2i(23, 6), Vector2i(23, 7)]:
		assert_true(_map.get_warps().get_at(cell).is_empty(), "plus de raccord en %s" % cell)
		assert_false(grid.is_solid(cell), "l'ancien bord est est du chemin")


func test_the_exit_of_mont_selenite_still_arrives_on_the_route_4() -> void:
	var b2f := (load(MapCatalog.scene_path(&"mt_moon_b2f")) as PackedScene).instantiate() as GameMap
	add_child_autofree(b2f)
	var exits: Array[Warp] = []
	for warp: Warp in b2f.get_warps().get_all():
		if warp.target_map == MAP_ID:
			exits.append(warp)
	assert_eq(exits.size(), 1, "une sortie de B2F vers la Route 4")
	for warp: Warp in exits:
		assert_false(warp.is_coming_soon())
		assert_eq(warp.target_spawn, &"from_mt_moon")
		assert_true(_map.has_spawn(warp.target_spawn))
		assert_false(_map.get_grid().is_solid(_map.get_spawn_cell(warp.target_spawn)))
