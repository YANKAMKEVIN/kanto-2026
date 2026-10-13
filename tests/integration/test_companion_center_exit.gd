extends GutTest
## Compagnon à la sortie d'un Centre Pokémon (bug de la session S24 12A, `jalon-12.md` T19) :
## vraie scène Boot. À la sortie, la case derrière le joueur est la porte (jamais posé sur un
## passage, T20) : il n'a pas de case et doit apparaître à la fin du premier pas. Le joueur qui
## **marche sans s'arrêter** enchaîne le pas suivant dans la même image : l'apparition en attente
## ne doit pas être perdue (le compagnon restait invisible jusqu'à l'ouverture du menu), et
## l'enthousiasme du soin se joue à sa sortie.
## Vérifié aux trois Centres : Jadielle, Argenta (J11) et Mont Sélénite (J12).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_center_exit_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
## Pas enchaînés en tenant la direction.
const STEPS := 2
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ACTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"move_down", Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}

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


func test_mt_moon_center_exit_then_walking_shows_the_companion() -> void:
	await _check_center(&"mt_moon_center", &"route_3", &"from_center_e")


func test_viridian_center_exit_then_walking_shows_the_companion() -> void:
	await _check_center(&"viridian_center", &"viridian_city", &"from_center")


func test_pewter_center_exit_then_walking_shows_the_companion() -> void:
	await _check_center(&"pewter_center", &"pewter_city", &"from_center")


## Dans le Centre [param center] avec un compagnon choisi, soin (enthousiasme en attente), sortie
## vers [param outside] / [param spawn], puis [constant STEPS] pas sans s'arrêter.
func _check_center(center: StringName, outside: StringName, spawn: StringName) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = center
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_companion = _boot.get_companion_controller()
	GameState.flags.set_flag(&"starter_chosen")
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"charmeleon", 17, GameRng.new(7))
	GameState.party.add(lead)
	GameState.set_companion(lead)
	_companion.refresh()
	assert_false(_companion.is_shown(), "au Centre (intérieur) : rentré")
	_companion.note_joy()
	SceneRouter.change_map(outside, spawn, Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == outside \
		and _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)
	var player := _boot.get_player()
	var grid := _boot.get_map().get_grid()
	var direction := _free_direction(grid, player.get_cell())
	assert_ne(direction, Vector2i.ZERO, "%s : %d cases libres devant la porte" % [outside, STEPS])
	if direction == Vector2i.ZERO:
		return
	var start := player.get_cell()
	var steps := [0]
	var count := func(_cell: Vector2i) -> void: steps[0] += 1
	player.moved.connect(count)
	# Enthousiasme du soin (« ♪ ») joué à sa sortie.
	var bubble := _companion.get_node_2d().get_bubble()
	var joy := [false]
	var watch := func() -> void: joy[0] = joy[0] or (bubble.is_playing() \
		and bubble.get_icon() == EmoteBubble.ICONS[EmoteBubble.NOTE])
	get_tree().process_frame.connect(watch)
	Input.action_press(ACTIONS[direction])
	await wait_until(func() -> bool: return steps[0] >= STEPS, TIMEOUT)
	Input.action_release(ACTIONS[direction])
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving(), TIMEOUT)
	player.moved.disconnect(count)
	get_tree().process_frame.disconnect(watch)
	assert_gte(steps[0], STEPS, "le joueur a marché")
	assert_ne(player.get_cell(), start)
	assert_true(_companion.is_shown(), "%s : le compagnon suit après la sortie" % center)
	assert_eq(_companion.get_node_2d().get_cell(), player.get_cell() - direction,
		"juste derrière le joueur")
	assert_true(joy[0], "%s : « ♪ » du soin à sa sortie" % center)


## Une direction (bas, gauche, droite) avec [constant STEPS] cases libres en ligne.
func _free_direction(grid: GridWorld, from: Vector2i) -> Vector2i:
	for direction: Vector2i in DIRECTIONS:
		var ok := true
		for i: int in range(1, STEPS + 1):
			if not grid.is_free(from + direction * i):
				ok = false
				break
		if ok:
			return direction
	return Vector2i.ZERO
