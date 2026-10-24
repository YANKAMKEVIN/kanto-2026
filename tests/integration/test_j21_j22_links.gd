extends GutTest
## Raccords J21 ↔ J22 (2026-10-23, contrat `docs/tech/jalon-22.md` §0.5, en-tête de
## `tools/plans/route_16_gate.txt`) sur les vraies scènes :
## - Route 12 (25..26, 101) ↔ Route 12 sud (25..26, 0), case pour case, dans les deux sens ;
## - Route 16 est ↔ poste `route_16_gate` : porte basse (15..16, 20) ↔ couloir bas (10..11, 7..8),
##   porte haute (19..20, 13) ↔ couloir haut (10..11, 1..2), case pour case ;
## - plus aucun « À venir » sur ces passages ;
## - l'arbre à Couper (38..39, 19..20) : [FlagGate] `CutTree` et examen 2 × 2 `route_16_tree`,
##   COUPER → `cut_tree_route_16` ; lui seul ouvre la voie haute ; aucun contournement de Ronflex ;
## - vraie Boot (départ `snorlax_16_qa`, Reptincel, Badge Cascade, CS01 ajoutée au Sac) : Coupe, puis aller-retour
##   par la porte haute.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/snorlax_16_qa.json"
const SAVE_PATH := "user://test_j21_j22_links_save.json"
const TIMEOUT := 12.0
const FADE := 0.05
const TREE_FLAG := &"cut_route_16_tree"
const SNORLAX_FLAG := &"snorlax_route_16_done"
## Triées (x puis y), comme `Array.sort()` les rend.
const TREE: Array[Vector2i] = [Vector2i(38, 19), Vector2i(38, 20), Vector2i(39, 19),
	Vector2i(39, 20)]
const LOW_DOOR: Array[Vector2i] = [Vector2i(15, 20), Vector2i(16, 20)]
const HIGH_DOOR: Array[Vector2i] = [Vector2i(19, 13), Vector2i(20, 13)]
const PARVIS: Array[Vector2i] = [Vector2i(15, 21), Vector2i(16, 21)]
const READY_CUT: Array[String] = [
	"Reptincel peut couper cet arbuste.", "Utiliser Coupe ?", "Reptincel utilise Coupe !"]

var _boot: Boot
var _player: Player
var _fs: MemoryFs
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Aides (scènes seules) -------------------------------------------------------------------

func _map(map_id: StringName) -> GameMap:
	assert_true(MapCatalog.has_map(map_id), "%s existe" % map_id)
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _flags(list: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


## Passages de [param from] vers [param to] : chacun a sa direction, une arrivée de la carte cible
## à la case attendue (case de départ + [param offset], rangée [param row] si ≥ 0), libre, et
## aucun « À venir ». Rend le nombre de passages.
func _check_ways(from: GameMap, to: GameMap, direction: Vector2i, offset: Vector2i,
		row: int) -> int:
	var count := 0
	for warp: Warp in from.get_warps().get_all():
		if warp.target_map != to.map_id:
			continue
		count += 1
		var label := "%s %s → %s" % [from.map_id, warp.cell, warp.target_spawn]
		assert_false(warp.is_coming_soon(), label)
		assert_eq(warp.direction, direction, label)
		assert_true(to.has_spawn(warp.target_spawn), label)
		var expected := warp.cell + offset
		if row >= 0:
			expected.y = row
		assert_eq(to.get_spawn_cell(warp.target_spawn), expected, label)
		assert_false(to.get_grid().is_solid(to.get_spawn_cell(warp.target_spawn)), label)
	return count


# --- Raccords case pour case -----------------------------------------------------------------

func test_route_12_and_route_12_south_are_joined_cell_for_cell() -> void:
	var north := _map(&"route_12")
	var south := _map(&"route_12_south")
	assert_eq(_check_ways(north, south, Vector2i.DOWN, Vector2i.ZERO, 0), 2,
		"Route 12 (25..26, 101) → Route 12 sud (25..26, 0)")
	assert_eq(_check_ways(south, north, Vector2i.UP, Vector2i.ZERO, 100), 2,
		"Route 12 sud (25..26, 0) → Route 12 (25..26, 100)")
	assert_eq(north.get_spawn_cell(&"from_route_12_sud"), Vector2i(25, 100))
	assert_eq(north.get_spawn_cell(&"from_route_12_sud_1"), Vector2i(26, 100))
	assert_false(north.has_spawn(&"from_route_12_sud_e"), "ancien nom retiré")
	for warp: Warp in north.get_warps().get_all() + south.get_warps().get_all():
		assert_false(warp.is_coming_soon() and warp.coming_soon == "Route 12",
			"plus de « Route 12 — À venir » (%s)" % warp.cell)


func test_route_16_and_its_gate_are_joined_cell_for_cell() -> void:
	var route := _map(&"route_16")
	var gate := _map(&"route_16_gate")
	# Porte basse : (15..16, 20) ↑ → couloir bas (10..11, 7) ; (10..11, 8) ↓ → parvis (15..16, 21).
	var low := 0
	var high := 0
	for warp: Warp in route.get_warps().get_all():
		if warp.target_map != &"route_16_gate":
			continue
		assert_false(warp.is_coming_soon())
		assert_eq(warp.trigger, Warp.Trigger.STEP_ON, "%s" % warp.cell)
		var arrival := gate.get_spawn_cell(warp.target_spawn)
		if LOW_DOOR.has(warp.cell):
			low += 1
			assert_eq(warp.direction, Vector2i.UP)
			assert_eq(arrival, Vector2i(warp.cell.x - 5, 7), "%s → %s" % [warp.cell, arrival])
			assert_eq(warp.facing, Vector2i.UP, "tourné ↑ dans le poste")
		elif HIGH_DOOR.has(warp.cell):
			high += 1
			assert_eq(warp.direction, Vector2i.DOWN)
			assert_eq(arrival, Vector2i(warp.cell.x - 9, 2), "%s → %s" % [warp.cell, arrival])
			assert_eq(warp.facing, Vector2i.DOWN, "tourné ↓ dans le poste")
		else:
			fail_test("passage inattendu %s" % warp.cell)
	assert_eq([low, high], [2, 2], "deux portes de deux cases")
	low = 0
	high = 0
	for warp: Warp in gate.get_warps().get_all():
		if warp.target_map != &"route_16":
			continue
		assert_false(warp.is_coming_soon())
		var arrival := route.get_spawn_cell(warp.target_spawn)
		assert_false(route.get_grid().is_solid(arrival))
		if warp.cell.y == 8:
			low += 1
			assert_eq(warp.direction, Vector2i.DOWN)
			assert_eq(arrival, Vector2i(warp.cell.x + 5, 21), "%s → %s" % [warp.cell, arrival])
			assert_eq(warp.facing, Vector2i.DOWN)
		elif warp.cell.y == 1:
			high += 1
			assert_eq(warp.direction, Vector2i.UP)
			assert_eq(arrival, Vector2i(warp.cell.x + 9, 12), "%s → %s" % [warp.cell, arrival])
			assert_eq(warp.facing, Vector2i.UP)
	assert_eq([low, high], [2, 2], "couloirs bas et haut vers la Route 16 est")
	assert_eq(route.get_spawn_cell(&"from_poste"), PARVIS[0])
	assert_eq(route.get_spawn_cell(&"from_poste_1"), PARVIS[1])
	assert_eq(route.get_spawn_cell(&"from_poste_haut"), Vector2i(19, 12))
	assert_eq(route.get_spawn_cell(&"from_poste_haut_1"), Vector2i(20, 12))
	for gone: StringName in [&"from_poste_w", &"from_poste_e"]:
		assert_false(route.has_spawn(gone), "ancien nom retiré : %s" % gone)
	for warp: Warp in route.get_warps().get_all() + gate.get_warps().get_all():
		assert_false(warp.is_coming_soon(), "aucun « À venir » : %s" % warp.cell)


func test_the_tree_alone_opens_the_high_path_without_bypassing_snorlax() -> void:
	var route := _map(&"route_16")
	var grid := route.get_grid()
	var start := route.get_spawn_cell(&"from_celadon")
	var tree := route.find_child("CutTree", true, false) as FlagGate
	assert_not_null(tree, "FlagGate CutTree")
	assert_eq(tree.unless_flags, [TREE_FLAG] as Array[StringName])
	var cells := tree.blocking_cells.duplicate()
	cells.sort()
	assert_eq(cells, TREE, "l'arbre ferme ses 2 × 2 cases")
	assert_not_null(tree.get_node_or_null(^"Tree"), "décor de l'arbre")
	# Arbre debout (Ronflex parti ou non) : la voie haute et la porte haute restent fermées.
	for flags: Array[StringName] in [[] as Array[StringName], [SNORLAX_FLAG] as Array[StringName]]:
		route.apply_flag_gates(_flags(flags))
		assert_true(tree.visible)
		var reached := grid.find_reachable(start)
		for cell: Vector2i in HIGH_DOOR + [Vector2i(38, 18), Vector2i(30, 12), Vector2i(19, 12)]:
			assert_false(reached.has(cell), "%s fermé tant que l'arbre est debout" % cell)
	# Arbre coupé, Ronflex endormi : la voie haute et la porte haute s'ouvrent, pas le parvis.
	route.apply_flag_gates(_flags([TREE_FLAG]))
	assert_false(tree.visible, "arbre retiré")
	for cell: Vector2i in TREE:
		assert_false(grid.is_occupied(cell), "libre %s" % cell)
	var open := grid.find_reachable(start)
	for cell: Vector2i in HIGH_DOOR + [Vector2i(38, 18), Vector2i(19, 12), Vector2i(18, 11)]:
		assert_true(open.has(cell), "%s atteint, arbre coupé" % cell)
	for cell: Vector2i in LOW_DOOR + PARVIS + [Vector2i(23, 22)]:
		assert_false(open.has(cell), "%s : aucun contournement de Ronflex" % cell)
	# Tout est relié quand les deux sont levés.
	route.apply_flag_gates(_flags([TREE_FLAG, SNORLAX_FLAG]))
	assert_eq(GridPaths.cut_off(grid, start).size(), 0, "tout le sol est relié")
	route.apply_flag_gates(_flags())


func test_the_tree_examine_and_cut_data() -> void:
	var route := _map(&"route_16")
	var point: InteractPoint = null
	for node: Node in route.get_node(^"Interactables").get_children():
		if (node as InteractPoint).dialogue_id == &"route_16_tree":
			point = node as InteractPoint
	assert_not_null(point, "examen de l'arbre")
	if point == null:
		return
	assert_eq(point.size, Vector2i(2, 2))
	assert_eq(point.unless_flags, [TREE_FLAG] as Array[StringName])
	var cells := point.get_cells()
	cells.sort()
	assert_eq(cells, TREE)
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	var dialogue := dialogues.get_dialogue(&"route_16_tree")
	assert_not_null(dialogue)
	var ready: DialogueVariant = dialogue.variants[-1]
	assert_not_null(ready.choice)
	assert_eq(ready.choice.confirm_cutscene, &"cut_tree_route_16")
	# Textes de la Coupe du J16 et du J17 (dossier 25 §16.5 n° 10), mot pour mot.
	var model := dialogues.get_dialogue(&"route_2_east_bush")
	for i: int in model.variants.size():
		assert_eq(dialogue.variants[i].pages.size(), model.variants[i].pages.size())
		for j: int in model.variants[i].pages.size():
			assert_eq(dialogue.variants[i].pages[j].text, model.variants[i].pages[j].text)
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var cut := cutscenes.get_cutscene(&"cut_tree_route_16")
	assert_not_null(cut)
	assert_eq(cut.variants[0].unless_flags, [TREE_FLAG] as Array[StringName])
	assert_eq(cut.variants[0].steps[1].flags, [TREE_FLAG] as Array[StringName])
	assert_not_null(route.get_node_or_null(NodePath("Entities/CutTree")), "cible de la scène")


# --- Vraie Boot ------------------------------------------------------------------------------

func _start(spawn: StringName, change: Callable = Callable()) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(START, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	await _settle()
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_encounter_director().enabled = false
	if change.is_valid():
		change.call()
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, &"route_16")


func _settle() -> void:
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


func _examine(facing: Vector2i) -> Array[String]:
	_pages.clear()
	_player.face(facing)
	await wait_process_frames(1)
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + 30000
	while (director.is_running() or runner.is_running() or box.is_open()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)
	var pages: Array[String] = []
	pages.assign(_pages)
	return pages


func _step(direction: Vector2i) -> void:
	assert_true(_player.script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Marche vers [param direction] jusqu'au changement de carte (porte ou bord), touche relâchée dès
## que la transition commence.
func _walk_through(direction: Vector2i) -> void:
	var action: StringName = {Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
		Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down"}[direction]
	var from_id := _boot.get_map().map_id
	Input.action_press(action)
	await wait_until(func() -> bool: return SceneRouter.is_transitioning(), 8.0)
	Input.action_release(action)
	await wait_until(func() -> bool: return is_instance_valid(_boot.get_map()) \
		and _boot.get_map().map_id != from_id and not SceneRouter.is_transitioning(), TIMEOUT)
	await _settle()


func test_cutting_the_tree_opens_the_high_path_for_good() -> void:
	# Le départ a `got_hm01` et le Badge Cascade ; la CS01 revient dans le Sac.
	await _start(&"face_arbre", func() -> void: GameState.bag.add(&"hm01"))
	assert_eq(_player.get_cell(), Vector2i(38, 21), "sous l'arbre")
	var gate := _boot.get_map().get_node(^"Entities/CutTree") as FlagGate
	assert_true(gate.visible)
	assert_eq(await _examine(Vector2i.UP), READY_CUT, "prêt, COUPER, « utilise Coupe ! »")
	assert_true(GameState.flags.has_flag(TREE_FLAG), "arbre coupé")
	assert_false(gate.visible, "arbre retiré")
	for i: int in 4:
		await _step(Vector2i.UP)
	assert_eq(_player.get_cell(), Vector2i(38, 17), "sur le lien de la voie haute")
	assert_push_error_count(0)


func test_the_high_door_round_trip_with_the_gate() -> void:
	await _start(&"from_poste_haut", func() -> void: GameState.flags.set_flag(TREE_FLAG))
	assert_eq(_player.get_cell(), Vector2i(19, 12))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, &"route_16_gate", "couloir haut du poste")
	assert_eq(_player.get_cell(), Vector2i(10, 2), "entrance_haut_est")
	await _walk_through(Vector2i.UP)
	assert_eq(_boot.get_map().map_id, &"route_16", "retour sur la voie haute")
	assert_eq(_player.get_cell(), Vector2i(19, 12), "from_poste_haut, même colonne")
	assert_push_error_count(0)


func test_the_low_door_round_trip_with_the_gate() -> void:
	await _start(&"from_poste", func() -> void: GameState.flags.set_flag(SNORLAX_FLAG))
	assert_eq(_player.get_cell(), PARVIS[0])
	await _walk_through(Vector2i.UP)
	assert_eq(_boot.get_map().map_id, &"route_16_gate", "couloir bas du poste")
	assert_eq(_player.get_cell(), Vector2i(10, 7), "entrance_bas_est")
	await _walk_through(Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, &"route_16", "retour sur le parvis")
	assert_eq(_player.get_cell(), PARVIS[0], "from_poste, même colonne")
	assert_push_error_count(0)
