extends GutTest
## La vie de la Route 9 (jalon 18 T18, jalon-18.md §4.3, §4.13 ; dossier 21 §3.2, §3.4, §12)
## avec la vraie scène Boot, la vraie carte et une sauvegarde en mémoire :
## - objets visibles O1–O3 : PRENDRE → Sac + quantité, journal, drapeau, retiré tout de suite et
##   au rechargement, toast seul ;
## - panneau ouest lu de face ; Pokémon d'ambiance (Piafabec qui s'envole, Racaillou endormi) ;
## - premier pas sur la colonne 1 → `route_9_entered` (silencieux) → objectif « traverser la
##   Route 9 vers l'est. » ;
## - rencontres : table de `data/encounters/route_9.json`, hautes herbes de la scène, un pas dans
##   H1 → combat sauvage, « vu » au Pokédex ;
## - bord ouest « Azuria — À venir » (la Coupe du J16 n'est pas dans cette base), bord est vers la
##   Route 10 ; départ de débogage `route_9`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_9.json"
const PLAN_PATH := "res://tools/plans/route_9.txt"
const SAVE_PATH := "user://test_route_9_life_save.json"
const MAP_ID := "route_9"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _pages: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T15:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur la Route 9 ; [param fresh] applique le départ de débogage (sinon : la partie relue de
## la sauvegarde) ; le joueur est ensuite posé sur [param cell] s'il est donné.
func _start(cell: Variant, facing: Vector2i, fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_9"
	_boot.start_spawn = &"from_cerulean"
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
		_pages.append(_runner.get_session().get_text()))
	await wait_process_frames(3)
	if cell is Vector2i:
		_boot.get_map().spawn_player_at(_player, cell, facing)
		await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_right"
	match direction:
		Vector2i.UP:
			action = &"move_up"
		Vector2i.DOWN:
			action = &"move_down"
		Vector2i.LEFT:
			action = &"move_left"
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Case praticable voisine de [param cell] (hors hautes herbes) et direction vers [param cell].
func _neighbour(cell: Vector2i) -> Array:
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if _plan.is_walkable(from) and _plan.at(from) != "h":
			return [from, -direction]
	return []


func _found(item: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == MAP_ID:
			count += 1
	return count


# --- Départ de débogage -----------------------------------------------------------------------

func test_debug_start_is_the_azuria_exit_with_a_plausible_team() -> void:
	await _start(null, Vector2i.RIGHT, true)
	assert_eq(_boot.get_map().map_id, &"route_9")
	assert_eq(_player.get_cell(), Vector2i(0, 23), "arrivée d'Azuria")
	var species: Array[StringName] = []
	for pokemon: Pokemon in GameState.party.get_all():
		species.append(pokemon.species_id)
	assert_eq(species, [&"charmeleon", &"pidgeotto", &"mankey", &"gloom"] as Array[StringName])
	assert_eq(GameState.party.get_at(0).level, 25)
	assert_true(GameState.flags.has_flag(&"badge_cascade"))
	assert_false(GameState.flags.has_flag(&"route_9_entered"))
	assert_push_error_count(0)


# --- Objets visibles -----------------------------------------------------------------------

func _check_visible_item(index: int, item: StringName, count: int) -> void:
	var id := StringName("route_9_item_%d" % index)
	var cell := _plan.cell_of(String(id))
	assert_eq(StringName(_plan.attr(String(id), "item")), item, "objet de la grille")
	var near := _neighbour(cell)
	assert_false(near.is_empty(), "%s a une case d'accès" % id)
	if near.is_empty():
		return
	await _start(near[0], near[1], true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(id), "l'objet est au sol")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible d'interaction")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(id) == null, TIMEOUT)
	assert_null(map.get_npc(id), "objet retiré tout de suite")
	await _finish_scene()
	assert_eq(GameState.bag.count_of(item), before + count, "Sac + %d" % count)
	assert_eq(_found(String(item)), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(StringName("got_" + id)))
	assert_eq(_toasts.size(), 1, "un toast")
	if not _toasts.is_empty():
		assert_true(_toasts[0][0].contains("×%d" % count), "quantité : %s" % _toasts[0][0])
	assert_eq(_events.count("page"), 0, "aucune bulle")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(item)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement")
	assert_false(_boot.get_map().get_grid().is_occupied(cell))
	assert_eq(GameState.bag.count_of(item), bag_after, "Sac inchangé")
	assert_push_error_count(0)


func test_o1_super_potion_in_the_high_corridor() -> void:
	await _check_visible_item(1, &"super_potion", 1)


func test_o2_antidote_in_the_valley() -> void:
	await _check_visible_item(2, &"antidote", 1)


func test_o3_two_poke_balls_on_the_east_terrace() -> void:
	await _check_visible_item(3, &"poke_ball", 2)


# --- Panneau, PNJ et Pokémon d'ambiance -------------------------------------------------------

func test_sign_is_read_from_the_front() -> void:
	var sign_cell := _plan.cell_of("panneau_ouest")
	await _start(sign_cell + Vector2i.DOWN, Vector2i.UP, true)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, ["ROUTE 9\nAzuria — Route 10"] as Array[String], "panneau du dossier 21 §3.1")
	# De côté : rien.
	_boot.get_map().spawn_player_at(_player, sign_cell + Vector2i.RIGHT, Vector2i.UP)
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(), "de côté : rien")


func test_ambient_pokemon_on_their_cells() -> void:
	await _start(null, Vector2i.RIGHT, true)
	var map := _boot.get_map()
	var spearow := map.get_npc(&"piafabec_1")
	var geodude := map.get_npc(&"racaillou_1")
	assert_not_null(spearow, "Piafabec posé")
	assert_not_null(geodude, "Racaillou posé")
	if spearow != null:
		assert_eq(spearow.get_cell(), _plan.cell_of("piafabec_1"))
		assert_eq(spearow.get_spec().sprite, &"pokemon/spearow")
		assert_eq(spearow.get_spec().shy_action, &"fly", "s'envole")
		assert_eq(spearow.get_spec().shy_radius, 2, "rayon 2")
	if geodude != null:
		assert_eq(geodude.get_cell(), _plan.cell_of("racaillou_1"))
		assert_eq(geodude.get_spec().sprite, &"pokemon/geodude")
	var count := 0
	for npc: Npc in map.get_npcs():
		count += 1
	assert_eq(count, 13, "7 Dresseurs, 3 objets, 2 Pokémon d'ambiance, la CT30 (N-22)")


# --- Déclencheur et objectif ----------------------------------------------------------------

func test_first_step_on_route_9_sets_the_objective_silently() -> void:
	await _start(null, Vector2i.RIGHT, true)
	assert_eq(_player.get_cell(), Vector2i(0, 23))
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	await _walk(Vector2i.RIGHT, Vector2i(1, 23))
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"route_9_entered"),
		TIMEOUT)
	assert_true(GameState.flags.has_flag(&"route_9_entered"))
	assert_eq(objectives.current(GameState.flags), "traverser la Route 9 vers l'est.",
		"dossier 21 §12")
	await wait_process_frames(5)
	assert_eq(_events, [] as Array[String], "en silence")
	assert_true(_player.is_input_enabled(), "le joueur garde la main")
	assert_push_error_count(0)


func test_entered_trigger_covers_the_three_west_rows() -> void:
	var map := (load("res://game/world/maps/route_9.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var points := map.get_node(^"Triggers").get_children()
	assert_eq(points.size(), 1)
	var trigger := points[0] as EventTriggerPoint
	assert_eq(trigger.cutscene_id, &"route_9_entered")
	var cells := trigger.get_cells()
	cells.sort()
	assert_eq(cells, [Vector2i(1, 22), Vector2i(1, 23), Vector2i(1, 24)] as Array[Vector2i])
	assert_eq(trigger.direction, Vector2i.ZERO, "toute direction")


# --- Rencontres -------------------------------------------------------------------------------

func _table() -> EncounterTable:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(&"route_9"))
	return library.get_table(&"route_9")


func test_encounter_table_matches_dossier_21() -> void:
	var table := _table()
	assert_eq(table.rate, 25, "taux comme la Route 3")
	assert_true(table.has_ramp())
	assert_eq(table.total_weight(), 100)
	assert_almost_eq(table.chance_of(&"rattata"), 0.30, 0.0001)
	assert_almost_eq(table.chance_of(&"spearow"), 0.35, 0.0001)
	assert_almost_eq(table.chance_of(&"ekans"), 0.18, 0.0001)
	assert_almost_eq(table.chance_of(&"sandshrew"), 0.17, 0.0001)
	for slot: EncounterSlot in table.slots:
		var expected := {&"rattata": [14, 17], &"spearow": [13, 17], &"ekans": [11, 17],
			&"sandshrew": [11, 17]}[slot.species] as Array
		assert_eq([slot.min_level, slot.max_level], expected, String(slot.species))


func test_tall_grass_of_the_scene_matches_the_four_zones() -> void:
	var map := (load("res://game/world/maps/route_9.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var grass := 0
	for cell: Vector2i in _plan.cells_of("h"):
		assert_true(map.get_grid().is_tall_grass(cell), "%s : hautes herbes" % cell)
		grass += 1
	assert_gt(grass, 0)
	for id: String in ["herbes_h1", "herbes_h2", "herbes_h3", "herbes_h4"]:
		assert_true(map.get_grid().is_tall_grass(_plan.cell_of(id)), id)


## Un pas dans H1 avec la table forcée à taux maximal : combat sauvage, espèce « vue ».
func test_a_step_in_h1_starts_a_wild_battle() -> void:
	await _start(null, Vector2i.RIGHT, true)
	var grass := _plan.cell_of("herbes_h1")
	var map := _boot.get_map()
	assert_true(map.get_grid().is_tall_grass(grass), "H1 de la grille")
	assert_true(_boot.get_encounter_library().override_table(&"route_9", &"grass",
		{"rate": 255, "slots": [{"species": "rattata", "levels": [14, 14], "weight": 1}]},
		"test"))
	var started: Array[StringName] = []
	_boot.get_encounter_director().encounter_started.connect(
		func(species: StringName, _level: int) -> void: started.append(species))
	map.spawn_player_at(_player, grass + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return not started.is_empty(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(started, [&"rattata"] as Array[StringName], "rencontre de Rattata")
	await wait_until(func() -> bool: return _boot.get_battle_director().is_running(), TIMEOUT)
	assert_true(GameState.pokedex.is_seen(&"rattata"), "Rattata vu")


# --- Raccords ---------------------------------------------------------------------------------

## T15 : le bord ouest mène à Azuria (arbre coupé du J16, variante J18).
func test_west_edge_leads_to_azuria_and_east_edge_to_route_10() -> void:
	var map := (load("res://game/world/maps/route_9.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	for row: int in [22, 23, 24]:
		var west := map.get_warps().find_on_push(Vector2i(0, row), Vector2i.LEFT)
		assert_not_null(west, "bord ouest (0, %d)" % row)
		if west != null:
			assert_eq(west.target_map, &"cerulean_city", "Azuria (variante J18)")
			assert_false(west.is_coming_soon())
		var east := map.get_warps().find_on_push(Vector2i(79, 12 + row - 22), Vector2i.RIGHT)
		assert_not_null(east, "bord est")
		if east != null:
			assert_eq(east.target_map, &"route_10")
