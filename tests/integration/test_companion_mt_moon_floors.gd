extends GutTest
## Compagnon au chargement d'un étage du Mont Sélénite (bug de la session 12B, `jalon-12.md`
## T22) : vraie scène Boot, vrais départs de débogage (`tools/debug_start/mt_moon_*.json`).
## À l'arrivée par une échelle, la case derrière le joueur est souvent l'échelle elle-même ou une
## paroi (jamais posé sur un passage, T20) : il n'a pas de case et doit apparaître à la fin du
## premier pas qui libère une case (A-1, « masqué sans case libre »). Le joueur marche **sans
## s'arrêter** 3 pas dans une direction tenue : le compagnon doit être montré, juste derrière lui.
## Profils : Rondoudou (marche), Nosferapti (vol), Racaillou (planche `geodude_walk`).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_mt_moon_floors_save.json"
const START_1F := "res://tools/debug_start/mt_moon_1f.json"
const START_B1F := "res://tools/debug_start/mt_moon_b1f.json"
const START_B2F := "res://tools/debug_start/mt_moon_b2f.json"
const FADE := 0.05
const TIMEOUT := 12.0
## Pas enchaînés : jusqu'à [constant STEPS], au moins [constant MIN_STEPS] (arrivée S, en impasse).
const STEPS := 3
const MIN_STEPS := 2
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
const ACTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"move_down", Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
	Vector2i.UP: &"move_up",
}
## Place dans l'équipe des départs de débogage : Rondoudou, Nosferapti, Racaillou.
const JIGGLYPUFF := 1
const ZUBAT := 2
const GEODUDE := 4

var _boot: Boot
var _fades: Array[float] = []
var _companion: CompanionController


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T10:00:00")


func after_each() -> void:
	for action: StringName in ACTIONS.values():
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


# --- Départs de débogage (le compagnon de chaque fichier) --------------------------------------

func test_debug_start_1f_jigglypuff() -> void:
	await _start(START_1F, -1)
	await _check_walk("départ 1F", &"jigglypuff")


func test_debug_start_b1f_zubat() -> void:
	await _start(START_B1F, -1)
	await _check_walk("départ B1F", &"zubat")


func test_debug_start_b2f_geodude() -> void:
	await _start(START_B2F, -1)
	await _check_walk("départ B2F", &"geodude")


# --- Arrivées par chaque échelle ----------------------------------------------------------------

func test_ladder_a_to_1f() -> void:
	await _ladder(START_B1F, JIGGLYPUFF, &"mt_moon_1f", &"arrivee_a", &"jigglypuff")


func test_ladder_b_to_1f() -> void:
	await _ladder(START_B1F, GEODUDE, &"mt_moon_1f", &"arrivee_b", &"geodude")


func test_ladder_c_to_1f() -> void:
	await _ladder(START_B1F, ZUBAT, &"mt_moon_1f", &"arrivee_c", &"zubat")


func test_ladder_d_to_1f() -> void:
	await _ladder(START_B2F, JIGGLYPUFF, &"mt_moon_1f", &"arrivee_d", &"jigglypuff")


func test_ladder_a_to_b1f() -> void:
	await _ladder(START_1F, GEODUDE, &"mt_moon_b1f", &"arrivee_a", &"geodude")


func test_ladder_b_to_b1f() -> void:
	await _ladder(START_1F, JIGGLYPUFF, &"mt_moon_b1f", &"arrivee_b", &"jigglypuff")


func test_ladder_c_to_b1f() -> void:
	await _ladder(START_1F, ZUBAT, &"mt_moon_b1f", &"arrivee_c", &"zubat")


func test_ladder_d_to_b2f() -> void:
	await _ladder(START_1F, GEODUDE, &"mt_moon_b2f", &"arrivee_d", &"geodude")


func test_ladder_d_to_b2f_zubat() -> void:
	await _ladder(START_1F, ZUBAT, &"mt_moon_b2f", &"arrivee_d", &"zubat")


func test_arrival_s_to_b2f() -> void:
	await _ladder(START_B1F, JIGGLYPUFF, &"mt_moon_b2f", &"arrivee_s", &"jigglypuff")


# --- Interne --------------------------------------------------------------------------------------

## Départ de débogage [param path] ; [param companion] ≥ 0 : ce membre de l'équipe devient le
## compagnon (FAIRE SORTIR, comme depuis l'Équipe).
func _start(path: String, companion: int) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.force_debug_start = true
	_boot.debug_start_path = path
	add_child_autofree(_boot)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	_companion = _boot.get_companion_controller()
	if companion >= 0:
		GameState.set_companion(GameState.party.get_at(companion))
		_companion.refresh()


## Arrivée sur [param map] / [param spawn] par l'échelle (même orientation d'arrivée que le
## passage de la carte d'en face), puis la marche.
func _ladder(path: String, companion: int, map: StringName, spawn: StringName,
		species: StringName) -> void:
	await _start(path, companion)
	var facing := _arrival_facing(map, spawn)
	SceneRouter.change_map(map, spawn, facing)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map \
		and _boot.is_stable() and not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(2)
	await _check_walk("échelle → %s / %s" % [map, spawn], species)


## Orientation d'arrivée du passage qui mène à [param map] / [param spawn] (bas sans passage).
func _arrival_facing(map: StringName, spawn: StringName) -> Vector2i:
	for source: StringName in [&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f"]:
		var scene := load("res://game/world/maps/%s.tscn" % source) as PackedScene
		var state := scene.get_state()
		for i: int in state.get_node_count():
			var props := {}
			for p: int in state.get_node_property_count(i):
				props[state.get_node_property_name(i, p)] = state.get_node_property_value(i, p)
			if props.get(&"target_map", &"") == map and props.get(&"target_spawn", &"") == spawn:
				return props.get(&"arrival_facing", Vector2i.DOWN)
	return Vector2i.DOWN


## Jusqu'à [constant STEPS] pas sans s'arrêter dans la direction la plus libre : le compagnon
## [param species] est montré après le premier pas, et juste derrière le joueur à la fin.
func _check_walk(label: String, species: StringName) -> void:
	var player := _boot.get_player()
	var grid := _boot.get_map().get_grid()
	var chosen := _companion.get_chosen()
	assert_not_null(chosen, "%s : compagnon choisi" % label)
	if chosen == null:
		return
	assert_eq(chosen.species_id, species, label)
	var run := _free_run(grid, player.get_cell())
	var direction: Vector2i = run[0]
	var steps: int = run[1]
	assert_gte(steps, MIN_STEPS, "%s : %d cases libres en ligne" % [label, MIN_STEPS])
	if steps < MIN_STEPS:
		return
	var shown_after: Array[bool] = []
	var on_moved := func(_cell: Vector2i) -> void: shown_after.append(_companion.is_shown())
	player.moved.connect(on_moved)
	# Touche relâchée pendant le dernier pas (aucun pas de trop vers un passage).
	var started := [0]
	var on_started := func(_from: Vector2i, _to: Vector2i, _kind: StringName) -> void:
		started[0] += 1
		if started[0] >= steps:
			Input.action_release(ACTIONS[direction])
	player.step_started.connect(on_started)
	Input.action_press(ACTIONS[direction])
	await wait_until(func() -> bool: return shown_after.size() >= steps, TIMEOUT)
	Input.action_release(ACTIONS[direction])
	player.step_started.disconnect(on_started)
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving(), TIMEOUT)
	player.moved.disconnect(on_moved)
	assert_gte(shown_after.size(), steps, "%s : le joueur a marché" % label)
	# Au 2e pas au plus tard (le 1er libère la case, il sort à sa fin).
	for i: int in range(1, shown_after.size()):
		assert_true(shown_after[i], "%s : montré après le pas %d" % [label, i + 1])
	assert_true(_companion.is_shown(), "%s : le compagnon suit" % label)
	assert_eq(_companion.get_node_2d().get_species(), species, "%s : espèce" % label)
	# Sa planche peinte de marche (Racaillou : `geodude_walk`, pas la planche « react »).
	var catalog := CompanionCatalog.new()
	catalog.load_file()
	var look := CharacterLook.resolve(catalog.sprite_of(species))
	var frames := _companion.get_node_2d().get_sprite().sprite_frames
	assert_true(look.painted, "%s : planche peinte" % label)
	assert_not_null(frames, "%s : planche chargée" % label)
	if frames != null:
		assert_eq(frames.resource_path, look.frames_path, "%s : planche du catalogue" % label)
		for anim: StringName in [&"idle_down", &"walk_left", &"walk_right", &"walk_up"]:
			assert_true(frames.has_animation(anim), "%s : %s" % [label, anim])
	assert_eq(_companion.get_node_2d().get_cell(), player.get_cell() - direction,
		"%s : juste derrière le joueur" % label)


## La direction (bas, gauche, droite, haut) qui offre le plus de cases libres en ligne (hors
## passages, herbes, gravats : aucune rencontre), jusqu'à [constant STEPS] : `[direction, n]`.
func _free_run(grid: GridWorld, from: Vector2i) -> Array:
	var warps := _boot.get_map().get_warps()
	var best: Array = [Vector2i.ZERO, 0]
	for direction: Vector2i in DIRECTIONS:
		var n := 0
		while n < STEPS:
			var cell := from + direction * (n + 1)
			if not grid.is_free(cell) or not warps.get_at(cell).is_empty() \
					or grid.is_tall_grass(cell) or grid.is_rubble(cell):
				break
			n += 1
		if n > best[1]:
			best = [direction, n]
	return best
