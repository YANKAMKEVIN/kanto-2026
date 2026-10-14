extends GutTest
## La vie de la Route 24 nord (jalon 13 T22, jalon-13.md §2.14, §2.16 ; dossier 16 §13, §18) avec la
## vraie scène Boot : Potion au sol (Sac + 1, journal, drapeau, absente au rechargement), deux zones
## d'herbes à la table `route_24_grass` (Mystherbe, Chétiflor, Roucool, Chenipan, Aspicot,
## Chrysacier, Coconfort), Antidote caché (point d'examen, souche d'une autre teinte), aucun
## Dresseur au nord, raccord est « ROUTE 25 — À venir », objectifs n° 62 et 63.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_NAME := "test_route_24_life"
const FADE := 0.05
const TIMEOUT := 14.0
const POTION := Vector2i(44, 3)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T11:00:00")
	_fs = MemoryFs.new()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


func _start(start: String, cell: Vector2i, facing: Vector2i, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = &"route_24"
	_boot.start_spawn = &"north_land"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func test_the_potion_goes_to_the_bag_and_stays_gone_after_a_reload() -> void:
	await _start("route_24_north", Vector2i(44, 4), Vector2i.UP)
	var map := _boot.get_map()
	var npc := map.get_npc(&"route_24_ball_1")
	assert_not_null(npc, "Potion posée")
	assert_eq(npc.get_cell(), POTION)
	var before := GameState.bag.count_of(&"potion")
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(&"route_24_ball_1") == null, TIMEOUT)
	await wait_process_frames(8)
	assert_eq(GameState.bag.count_of(&"potion"), before + 1, "Sac + 1")
	assert_true(GameState.flags.has_flag(&"got_route_24_potion"))
	var found := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == "potion" and entry["map"] == "route_24":
			found += 1
	assert_eq(found, 1, "journal des objets trouvés")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start("route_24_north", Vector2i(44, 4), Vector2i.UP, false)
	assert_null(_boot.get_map().get_npc(&"route_24_ball_1"), "absente au rechargement")
	assert_eq(GameState.bag.count_of(&"potion"), before + 1)
	assert_push_error_count(0)


func test_the_wild_table_is_wired_and_the_north_has_two_tall_grass_zones() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(&"route_24", &"grass"))
	var table := library.get_table(&"route_24")
	var species: Array[StringName] = []
	for slot: Variant in table.slots:
		species.append(slot.species)
	species.sort()
	var expected: Array[StringName] = [&"oddish", &"bellsprout", &"pidgey", &"caterpie", &"weedle",
		&"metapod", &"kakuna"]
	expected.sort()
	assert_eq(species, expected, "table de la Route 24 (§2.14)")
	await _start("route_24_north", Vector2i(33, 17), Vector2i.UP)
	var grid := _boot.get_map().get_grid()
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/route_24.txt"), plan.error)
	assert_true(grid.is_tall_grass(plan.cell_of("herbes_h1")), "H1 (prairie ouest)")
	assert_true(grid.is_tall_grass(plan.cell_of("herbes_h2")), "H2 (prairie est)")
	assert_eq(plan.cells_of("h").size(), 7 * 5 + 7 * 5, "deux zones de 7 × 5 cases")
	# Aucun Dresseur au nord du recruteur (dossier 16 §13).
	for spec: NpcSpec in NpcRoster.load_for_map(&"route_24").get_all():
		if spec.trainer_id != &"":
			assert_gt(spec.cell.y, 20, "%s : sur le pont ou au sud, jamais au nord" % spec.id)


func test_the_hidden_antidote_is_a_stump_with_an_examine_point_that_vanishes() -> void:
	await _start("route_24_north", Vector2i(16, 7), Vector2i.UP)
	var map := _boot.get_map()
	assert_true(map.get_grid().is_solid(Vector2i(16, 6)), "la souche bloque sa case")
	assert_not_null(map.get_node_or_null(^"Entities/HiddenClue1"), "souche d'une autre teinte")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "face à la souche : EXAMINER")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE)
	var before := GameState.bag.count_of(&"antidote")
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"got_route_24_antidote"),
		TIMEOUT)
	await wait_process_frames(8)
	assert_eq(GameState.bag.count_of(&"antidote"), before + 1, "Sac + 1")
	assert_null(_boot.get_interaction_controller().get_target(), "plus de cible")
	assert_push_error_count(0)


func test_the_east_edge_is_route_25_coming_soon_and_the_zone_title_is_the_bridge() -> void:
	await _start("route_24_north", Vector2i(54, 7), Vector2i.RIGHT)
	var map := _boot.get_map()
	assert_eq(map.display_name, "Route 24")
	assert_eq(map.region, "Le Pont Pépite", "texte n° 56")
	var warp := map.get_warps().find_on_push(Vector2i(55, 7), Vector2i.RIGHT)
	assert_not_null(warp)
	if warp != null:
		assert_true(warp.is_coming_soon(), "« ROUTE 25 — À venir » (texte n° 57)")


func test_the_objectives_follow_the_bridge() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	await _start("nugget_bridge", Vector2i(32, 46), Vector2i.UP)
	assert_eq(library.current(GameState.flags), "traverser le Pont Pépite.", "n° 62")
	_boot.queue_free()
	await wait_process_frames(3)
	await _start("route_24_north", Vector2i(33, 17), Vector2i.UP)
	assert_eq(library.current(GameState.flags), "explorer les environs d'Azuria.", "n° 63")
