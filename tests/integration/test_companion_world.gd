extends GutTest
## Compagnon sur les vraies cartes (jalon 11, T20d ; dossier 14 §8.3–8.5) : vraie scène Boot.
## Portes (Centre de Jadielle : rentre, ressort derrière le joueur au premier pas), phrase de la
## ville, de la forêt et de l'étang de Bourg Palette, rebords de la Route 1 (il saute au pas
## suivant, jamais sur le rebord), Dresseur de la Forêt de Jade (rentre pendant le défi), reprise
## d'une sauvegarde avec un compagnon choisi, et aucun nœud de trop sur la carte.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_companion_world_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
## Nœuds du compagnon au plus (sprite, ombre, devant de touffe, bulle et ses enfants) : budget
## de la conception (`jalon-11-compagnon.md`, fps de la forêt).
const MAX_NODES := 6

var _boot: Boot
var _fades: Array[float] = []
var _fs: MemoryFs
var _companion: CompanionController
var _lead: Pokemon


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-12T10:00:00")
	_fs = MemoryFs.new()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _start(map: StringName, spawn: StringName, facing: Vector2i, choose := true) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_companion = _boot.get_companion_controller()
	if not choose:
		return
	GameState.flags.set_flag(&"starter_chosen")
	_lead = PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 12, GameRng.new(7))
	GameState.party.add(_lead)
	GameState.set_companion(_lead)
	_companion.refresh()


## Un pas scripté vers [param direction], attendu jusqu'au bout (compagnon compris).
func _step(direction: Vector2i) -> bool:
	var player := _boot.get_player()
	if not player.script_step(direction):
		return false
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving(), TIMEOUT)
	return true


## Pose le joueur sur [param cell] (le compagnon le rejoint au premier pas).
func _put_player(cell: Vector2i, facing: Vector2i) -> void:
	var map := _boot.get_map()
	_boot.get_player().enter_map(map.get_grid(), cell, facing, map.get_pixel_rect())
	_companion.on_cutscene_started()
	_companion.on_cutscene_finished()


## Ferme la phrase en cours (appuis successifs).
func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
	assert_false(runner.is_running(), "phrase fermée")


func _count_nodes(node: Node) -> int:
	var count := 1
	for child: Node in node.get_children():
		count += _count_nodes(child)
	return count


func test_doors_withdraw_then_follow_out_again_in_viridian_city() -> void:
	await _start(&"viridian_city", &"from_center", Vector2i.DOWN)
	var player := _boot.get_player()
	assert_true(await _step(Vector2i.DOWN), "un pas devant le Centre")
	assert_true(_companion.is_shown(), "il suit en ville")
	SceneRouter.change_map(&"viridian_center", &"entrance")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"viridian_center" \
		and _boot.is_stable(), TIMEOUT)
	assert_false(_companion.is_shown(), "rentré au Centre (intérieur)")
	assert_eq(_companion.get_node_2d().get_parent(), _boot.get_map().get_entities(),
		"le nœud a suivi la carte")
	SceneRouter.change_map(&"viridian_city", &"from_center", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"viridian_city" \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	var grid := _boot.get_map().get_grid()
	var behind := player.get_cell() - player.get_facing()
	if grid.is_free(behind):
		assert_true(_companion.is_shown(), "case derrière libre : ressort tout de suite")
	else:
		assert_false(_companion.is_shown(), "derrière lui, la porte : il attend le premier pas")
		var from := player.get_cell()
		assert_true(await _step(Vector2i.DOWN))
		await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
		assert_eq(_companion.get_node_2d().get_cell(), from, "sort sur la case quittée")
	assert_lte(_count_nodes(_companion.get_node_2d()), MAX_NODES, "budget de nœuds")


func test_city_line_in_viridian() -> void:
	await _start(&"viridian_city", &"from_center", Vector2i.DOWN)
	assert_true(await _step(Vector2i.DOWN))
	assert_eq(_companion.talk(), CompanionRules.CONTEXT_LINES[&"city"], "« observe les passants »")


func test_forest_line_then_a_trainer_challenge_withdraws_it() -> void:
	await _start(&"viridian_forest", &"before_theo", Vector2i.LEFT)
	assert_true(await _step(Vector2i.LEFT))
	assert_eq(_companion.talk(), CompanionRules.CONTEXT_LINES[&"forest"],
		"« écoute les bruits de la forêt »")
	await _close_dialogue()
	# Trois pas de plus vers l'ouest : le quatrième entre dans la vue de Théo.
	var cutscenes := _boot.get_cutscene_director()
	for i: int in 3:
		if cutscenes.is_running():
			break
		_boot.get_player().script_step(Vector2i.LEFT)
		await wait_until(func() -> bool: return not _boot.get_player().is_moving(), TIMEOUT)
	await wait_until(func() -> bool: return cutscenes.is_running(), TIMEOUT)
	assert_true(cutscenes.is_running(), "Théo repère le joueur")
	await wait_until(func() -> bool: return not _companion.is_shown(), TIMEOUT)
	assert_false(_companion.is_shown(), "rentré pendant le défi (D-2)")
	assert_false(_boot.get_map().get_grid().is_soft_held(_companion.get_node_2d().get_cell()),
		"aucune case tenue pendant la scène")


func test_pond_line_in_pallet_town() -> void:
	await _start(&"pallet_town", &"start", Vector2i.DOWN)
	var grid := _boot.get_map().get_grid()
	# Une case libre à 2 cases de l'étang, avec une case libre au nord pour faire un pas.
	var spot := Vector2i(-1, -1)
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if spot.x >= 0 or not grid.is_free(cell) or not grid.is_free(cell + Vector2i.UP):
				continue
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if grid.is_in_bounds(cell + Vector2i(dx, dy)) \
							and grid.is_water(cell + Vector2i(dx, dy)):
						spot = cell
	assert_ne(spot, Vector2i(-1, -1), "une case au bord de l'étang")
	_put_player(spot, Vector2i.UP)
	assert_true(await _step(Vector2i.UP))
	assert_eq(_companion.get_node_2d().get_cell(), spot)
	assert_eq(_companion.talk(), CompanionRules.LINE_WATER, "« regarde l'eau »")


func test_route_1_ledge_jump_is_followed_on_the_next_step() -> void:
	await _start(&"route_1", &"from_pallet_w", Vector2i.UP)
	var grid := _boot.get_map().get_grid()
	# Un rebord vers le bas avec une case libre au-dessus (et encore au-dessus).
	var ledge := Vector2i(-1, -1)
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if ledge.x < 0 and grid.get_ledge(cell) == GridWorld.Ledge.DOWN \
					and grid.is_free(cell + Vector2i.UP) and grid.is_free(cell + Vector2i.UP * 2) \
					and grid.is_free(cell + Vector2i.DOWN) and grid.is_free(cell + Vector2i.DOWN * 2):
				ledge = cell
	assert_ne(ledge, Vector2i(-1, -1), "un rebord de la Route 1")
	_put_player(ledge + Vector2i.UP * 2, Vector2i.DOWN)
	assert_true(await _step(Vector2i.DOWN), "un pas vers le rebord")
	var above := ledge + Vector2i.UP
	assert_eq(_boot.get_player().get_cell(), above)
	assert_true(await _step(Vector2i.DOWN), "saut du rebord")
	var landing := _boot.get_player().get_cell()
	assert_eq(landing, ledge + Vector2i.DOWN, "le joueur atterrit sous le rebord")
	var node := _companion.get_node_2d()
	assert_eq(node.get_cell(), above, "le compagnon attend au-dessus du rebord")
	var jumped := [false]
	var watch := func() -> void: jumped[0] = jumped[0] or node.is_jumping()
	get_tree().process_frame.connect(watch)
	assert_true(await _step(Vector2i.DOWN), "pas suivant")
	get_tree().process_frame.disconnect(watch)
	assert_true(jumped[0], "il saute le rebord à son tour")
	assert_eq(node.get_cell(), landing, "sur la case d'atterrissage, jamais sur le rebord")


func test_resuming_a_save_with_a_companion_shows_it_on_the_first_step() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-12T09:00:00")
	state.new_game(42)
	for flag: StringName in [&"mom_greeted", &"starter_chosen", &"rival_battle_done",
			&"rival_challenged"]:
		state.flags.set_flag(flag)
	var mon := PokemonFactory.create(data, &"charmander", 9, GameRng.new(3))
	state.party.add(mon)
	state.set_companion(mon)
	var spawn_map := (load(MapCatalog.scene_path(&"route_1")) as PackedScene).instantiate() \
		as GameMap
	var cell := spawn_map.get_spawn_cell(&"from_pallet_w") + Vector2i.UP * 2
	spawn_map.free()
	state.set_player_location(&"route_1", cell, Vector2i.UP)
	var save := SaveSystem.new(_fs, SAVE_PATH)
	assert_eq(save.write(state.to_dict()), OK)
	await _start(&"player_house_2f", &"start", Vector2i.DOWN, false)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(GameState.get_companion().species_id, &"charmander", "compagnon relu")
	var player := _boot.get_player()
	var from := player.get_cell()
	if not _companion.is_shown():
		assert_true(await _step(Vector2i.UP))
		await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "visible sur la Route 1 après la reprise")
	assert_true(_companion.get_node_2d().get_cell() in [from, from + Vector2i.DOWN])
