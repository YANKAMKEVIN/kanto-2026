extends GutTest
## Compagnon sur les cartes du jalon 20 (T22, jalon-20.md §2.12 ; dossier 14 §8 ; règle du J11)
## sur la vraie scène Boot : Miaouss (planche validée) suit sur la Route 7, la Route 8, dans le
## souterrain, à Céladopole (phrase « ville ») et dans le repaire Rocket (grotte non intérieure,
## phrase générique) ; rentré dans les intérieurs (Centre, toit du grand magasin) ; rappelé
## pendant une glisse sur dalle et un trajet d'ascenseur (grand magasin, repaire) puis de retour ;
## Évoli (aucune planche d'exploration peinte) n'est pas éligible (règle J11 : aucun substitut) ;
## après le don d'Évoli le compagnon choisi reste celui de la partie.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const SAVE_PATH := "user://test_companion_j20_save.json"
const FADE := 0.05
const TIMEOUT := 20.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]
## Carte → [point d'apparition, départ de débogage].
const OUTDOORS := {
	&"route_7": [&"from_celadon_c", "route_7"],
	&"route_8": [&"from_lavender_c", "route_8"],
	&"underground_path_7_8": [&"from_route_7_n", "underground_7_8"],
	&"celadon_city": [&"from_route_7_c", "celadon"],
}

var _boot: Boot
var _companion: CompanionController
var _fades: Array[float] = []
var _sim: FrameSim


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-20T10:00:00")
	_sim = null


func after_each() -> void:
	if _sim != null:
		_sim.finish()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Boot sur [param map] (départ [param start]) avec Miaouss N17 compagnon.
func _start(map: StringName, spawn: StringName, start: String) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_companion = _boot.get_companion_controller()
	var debug_start := DebugStart.new()
	assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
		_boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(debug_start.get_errors()))
	debug_start.apply(GameState, _boot.get_pokemon_data())
	var meowth := PokemonFactory.create(_boot.get_pokemon_data(), &"meowth", 17,
		GameRng.new(17))
	GameState.party.add(meowth)
	GameState.ensure_unique_uids()
	assert_true(GameState.set_companion(meowth), "Miaouss compagnon")
	_companion.refresh()


func _step(direction: Vector2i) -> bool:
	var player := _boot.get_player()
	if not player.script_step(direction):
		return false
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving(), TIMEOUT)
	await wait_process_frames(2)
	return true


func _free_step() -> Vector2i:
	var map := _boot.get_map()
	var grid := map.get_grid()
	var cell := _boot.get_player().get_cell()
	for direction: Vector2i in DIRECTIONS:
		var next := cell + direction
		if grid.is_free(next) and not grid.is_tall_grass(next) \
				and map.get_warps().get_at(next).is_empty():
			return direction
	return Vector2i.ZERO


func _walk_until_shown() -> void:
	for i: int in 3:
		var direction := _free_step()
		assert_ne(direction, Vector2i.ZERO, "un pas libre")
		await _step(direction)
		await wait_until(func() -> bool: return not _boot.get_cutscene_director().is_running(),
			TIMEOUT)
		if _companion.is_shown():
			return
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")


func _go(map_id: StringName, spawn: StringName) -> void:
	SceneRouter.change_map(map_id, spawn)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


func _assert_follows(label: String) -> void:
	assert_true(_companion.is_shown(), "%s : Miaouss suit" % label)
	var gap := _companion.get_node_2d().get_cell() - _boot.get_player().get_cell()
	assert_eq(absi(gap.x) + absi(gap.y), 1, "%s : juste derrière le héros" % label)


func _action_of(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


# --- Données ------------------------------------------------------------------------------------

func test_catalog_contexts_and_eevee_rule() -> void:
	var catalog := CompanionCatalog.new()
	assert_true(catalog.load_file(), "\n".join(catalog.get_errors()))
	assert_eq(catalog.context_of(&"celadon_city"), &"city", "Céladopole : ville")
	for map_id: StringName in [&"route_7", &"route_8", &"underground_path_7_8",
			&"rocket_hideout_b1f", &"rocket_hideout_b2f", &"rocket_hideout_b4f"]:
		assert_eq(catalog.context_of(map_id), &"", "%s : générique [D]" % map_id)
	assert_true(catalog.is_eligible_species(&"meowth"))
	assert_false(catalog.is_eligible_species(&"eevee"),
		"Évoli : aucune planche d'exploration peinte, aucun substitut (règle J11)")
	assert_false(ResourceLoader.exists("res://assets/sprites/pokemon/painted/eevee_frames.tres"),
		"si la planche d'Évoli arrive, l'ajouter à companions.json")


# --- Dehors : il suit -----------------------------------------------------------------------------

func test_meowth_follows_outdoors_on_the_j20_maps() -> void:
	for map_id: StringName in OUTDOORS:
		var info: Array = OUTDOORS[map_id]
		await _start(map_id, info[0], info[1])
		assert_false(_boot.get_map().interior, "%s : dehors" % map_id)
		await _walk_until_shown()
		_assert_follows(String(map_id))
		_boot.queue_free()
		await wait_process_frames(3)
	assert_push_error_count(0)


func test_celadon_line_is_a_city_line_and_the_underground_is_generic() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	await _walk_until_shown()
	assert_true(_companion.talk() in [&"companion_city", &"companion_water"], "ville ou eau")
	await _close_dialogue()
	await _go(&"underground_path_7_8", &"from_route_7_n")
	await _walk_until_shown()
	assert_true(CompanionRules.GENERIC_LINES.has(_companion.talk()), "phrase générique")
	await _close_dialogue()
	assert_push_error_count(0)


func test_withdrawn_indoors_and_out_again_in_celadon() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	await _walk_until_shown()
	for room: Array in [[&"celadon_center", &"entrance"], [&"celadon_dept_roof", &"from_down"]]:
		await _go(room[0], room[1])
		assert_true(_boot.get_map().interior, "%s : intérieur" % room[0])
		assert_false(_companion.is_shown(), "%s : rentré" % room[0])
	await _go(&"celadon_city", &"from_route_7_c")
	await _walk_until_shown()
	_assert_follows("retour à Céladopole")
	assert_push_error_count(0)


# --- Repaire : grotte, il suit ---------------------------------------------------------------------

func test_meowth_follows_in_the_hideout() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	for room: Array in [[&"rocket_hideout_b1f", &"from_elevator"],
			[&"rocket_hideout_b2f", &"from_elevator"]]:
		await _go(room[0], room[1])
		assert_false(_boot.get_map().interior, "%s : grotte, pas un intérieur" % room[0])
		await _walk_until_shown()
		_assert_follows(String(room[0]))
	assert_push_error_count(0)


# --- Glisse et ascenseur ---------------------------------------------------------------------------

func test_the_companion_retracts_during_a_hideout_slide_and_returns() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	await _go(&"rocket_hideout_b2f", &"from_elevator")
	var map := _boot.get_map()
	var grid := map.get_grid()
	var field := map.get_node(^"SpinTiles") as SpinTileField
	var spin := _boot.get_spin_director()
	var player := _boot.get_player()
	var found := false
	var start := Vector2i.ZERO
	var toward := Vector2i.ZERO
	var longest := 0
	var walkable := func(cell: Vector2i) -> bool: return grid.is_free(cell)
	for arrow: Vector2i in field.arrows:
		var length := field.slide_from(arrow, walkable).size()
		for direction: Vector2i in DIRECTIONS:
			var from := arrow - direction
			if length > longest and grid.is_free(from) and not field.is_arrow(from) \
					and grid.is_free(from - direction):
				found = true
				longest = length
				start = from
				toward = direction
	assert_true(found, "une case libre devant une dalle")
	player.enter_map(grid, start, toward, map.get_pixel_rect())
	_companion.refresh()
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "dehors avant la glisse")
	var followed: Array[bool] = []
	spin.slide_started.connect(func(_slide: SpinSlide) -> void:
		followed.append(_companion.get_trail().is_placed()))
	_sim = FrameSim.new(get_tree(), [player])
	Input.action_press(_action_of(toward))
	await _sim.frame()
	Input.action_release(_action_of(toward))
	await _sim.run_until(func() -> bool: return spin.is_running() or not player.is_moving(),
		TIMEOUT)
	assert_true(spin.is_running(), "la glisse est partie")
	assert_eq(followed, [false] as Array[bool], "rappelé dès le début de la glisse")
	await _sim.run_until(func() -> bool:
		return not _companion.is_shown() or not spin.is_running(), TIMEOUT)
	assert_true(spin.is_running(), "toujours en glisse")
	assert_false(_companion.is_shown(), "rentré pendant la glisse")
	await _sim.run_until(func() -> bool:
		return not spin.is_running() and not player.is_moving(), TIMEOUT)
	_sim.finish()
	_sim = null
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "revenu à l'arrêt")
	assert_ne(_companion.get_node_2d().get_cell(), player.get_cell(), "pas sur le joueur")
	assert_push_error_count(0)


func test_the_companion_retracts_during_both_elevator_rides_and_returns() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	(GameState.bag as Bag).add(&"lift_key")
	# [carte d'où l'on vient, arrivée, cabine, arrivée dans la cabine, étage, cabine intérieure].
	var rides: Array = [
		[&"celadon_dept_gf", &"from_elevator", &"celadon_dept_elevator", &"entrance", &"2f"],
		[&"rocket_hideout_b1f", &"from_elevator", &"rocket_hideout_elevator", &"entrance_w",
			&"b2f"],
	]
	for ride: Array in rides:
		await _go(ride[0], ride[1])
		var cave_like: bool = not _boot.get_map().interior
		await _go(ride[2], ride[3])
		if cave_like:
			await _walk_until_shown()
			assert_true(_companion.is_shown(), "%s : il suit jusque dans la cabine" % ride[2])
		var director := _boot.get_elevator_director()
		var states: Array[bool] = []
		director.ride_started.connect(func(_id: StringName) -> void:
			states.append(_companion.is_shown()), CONNECT_ONE_SHOT)
		assert_true(director.open_panel(), "panneau ouvert (%s)" % ride[2])
		assert_eq(director.choose_floor(ride[4]), ElevatorRules.Status.OK)
		await wait_until(func() -> bool:
			return not _companion.is_shown() or not director.is_riding(), TIMEOUT)
		assert_true(director.is_riding(), "%s : toujours en trajet" % ride[2])
		assert_false(_companion.is_shown(), "%s : rentré pendant le trajet" % ride[2])
		await wait_until(func() -> bool: return not director.is_riding(), TIMEOUT)
		await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
		assert_eq(states.size(), 1, "trajet parti")
		if cave_like:
			await _walk_until_shown()
			assert_true(_companion.is_shown(), "%s : de retour après le trajet" % ride[2])
		else:
			assert_false(_companion.is_shown(), "%s : intérieur, toujours rentré" % ride[2])
	assert_push_error_count(0)


# --- Don d'Évoli -----------------------------------------------------------------------------------

func test_the_companion_survives_the_eevee_gift() -> void:
	await _start(&"celadon_city", &"from_route_7_c", "celadon")
	await _walk_until_shown()
	var chosen := _companion.get_chosen()
	var eevee := PokemonFactory.create(_boot.get_pokemon_data(), &"eevee", 25, GameRng.new(25))
	GameState.party.add(eevee)
	GameState.ensure_unique_uids()
	_companion.refresh()
	await wait_process_frames(2)
	assert_eq(_companion.get_chosen(), chosen, "le compagnon reste Miaouss")
	assert_true(_companion.is_shown(), "il est toujours là")
	# Même désigné de force, Évoli est écarté au rafraîchissement (inéligible).
	GameState.set_companion(eevee)
	_companion.refresh()
	await wait_process_frames(2)
	assert_eq(GameState.companion_uid, "", "choix effacé : Évoli inéligible")
	await wait_until(func() -> bool: return not _companion.is_shown(), TIMEOUT)
	assert_false(_companion.is_shown(), "personne ne suit")
	assert_push_error_count(0)
