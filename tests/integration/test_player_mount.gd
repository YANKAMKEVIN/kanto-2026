extends GutTest
## Joueur monté (passe systèmes 2, `systemes-2.md` §2.2 et §2.3, T7–T9) : sur une petite
## GridWorld, durées des pas, course ignorée, mode d'accès, signaux, dérive sur la pente de la
## Piste. Rien ne change à pied (les tests de `test_player.gd` passent sans modification).

const PLAYER_SCENE := "res://game/player/player.tscn"
const FRAME := 1.0 / 60.0
const START := Vector2i(2, 1)
const SIZE := Vector2i(8, 10)
const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"run",
]

var _grid: GridWorld
var _player: Player


func before_each() -> void:
	_grid = GridWorld.new(SIZE)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(_player)
	_player.enter_map(_grid, START, Vector2i.DOWN, Grid.map_pixel_rect(SIZE))
	_player.set_process(false)
	watch_signals(_player)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)


func _simulate(seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		_player._process(FRAME)


func test_on_foot_by_default() -> void:
	assert_eq(_player.get_mount(), Mount.Kind.NONE)
	assert_eq(_player.get_move_mode(), GridWorld.MoveMode.WALK)


func test_set_mount_emits_once_and_changes_the_access_mode() -> void:
	_player.set_mount(Mount.Kind.BIKE)
	_player.set_mount(Mount.Kind.BIKE)
	assert_signal_emit_count(_player, "mount_changed", 1)
	assert_signal_emitted_with_parameters(_player, "mount_changed", [Mount.Kind.BIKE])
	assert_eq(_player.get_move_mode(), GridWorld.MoveMode.WALK, "le Vélo suit la marche")
	_player.set_mount(Mount.Kind.SURF)
	assert_eq(_player.get_move_mode(), GridWorld.MoveMode.SURF)
	assert_eq(GridWorld.move_mode_of(_player), GridWorld.MoveMode.SURF)


func test_the_bike_is_faster_than_running_and_ignores_the_run_button() -> void:
	_player.set_mount(Mount.Kind.BIKE)
	Input.action_press(&"move_down")
	Input.action_press(&"run")
	_simulate(BikeRules.BIKE_STEP_DURATION * 3.0 + 0.04)
	assert_eq(_player.get_cell(), START + Vector2i(0, 3), "trois cases en 3 × 0,12 s")
	assert_false(_player.is_running(), "la course n'existe qu'à pied")


func test_a_mounted_step_is_announced_as_bike() -> void:
	_player.set_mount(Mount.Kind.BIKE)
	assert_true(_player.script_step(Vector2i.DOWN))
	assert_signal_emitted_with_parameters(_player, "step_started",
		[START, START + Vector2i.DOWN, &"bike"])


func test_getting_off_restores_the_walk() -> void:
	_player.set_mount(Mount.Kind.BIKE)
	_player.set_mount(Mount.Kind.NONE)
	Input.action_press(&"move_down")
	_simulate(Grid.WALK_STEP_DURATION + 0.04)
	assert_eq(_player.get_cell(), START + Vector2i.DOWN, "une seule case à la marche")


func test_on_the_slope_the_bike_drifts_down_to_the_landing() -> void:
	for y: int in range(2, 6):
		_grid.set_slope(Vector2i(START.x, y))
	_player.set_mount(Mount.Kind.BIKE)
	_player.script_step(Vector2i.DOWN)
	_simulate(1.5)
	assert_eq(_player.get_cell(), Vector2i(START.x, 6), "dérive jusqu'au palier, sans appui")
	assert_false(_player.is_moving(), "le palier arrête la dérive")


func test_holding_a_direction_on_the_slope_wins_over_the_drift() -> void:
	for x: int in SIZE.x:
		_grid.set_slope(Vector2i(x, START.y))
	_player.set_mount(Mount.Kind.BIKE)
	Input.action_press(&"move_right")
	_simulate(BikeRules.BIKE_STEP_DURATION * 2.0 + 0.2)
	assert_eq(_player.get_cell().y, START.y, "gauche, droite et haut restent libres")
	assert_gt(_player.get_cell().x, START.x)


func test_no_drift_on_foot_or_when_blocked() -> void:
	_grid.set_slope(START)
	_simulate(0.5)
	assert_eq(_player.get_cell(), START, "à pied : pas de dérive")
	_player.set_mount(Mount.Kind.BIKE)
	_player.set_input_enabled(false, &"dialogue")
	_simulate(0.5)
	assert_eq(_player.get_cell(), START, "dialogue, scène, Dresseur qui voit : pas de dérive")
	_player.set_input_enabled(true, &"dialogue")
	_simulate(BikeRules.BIKE_STEP_DURATION + 0.04)
	assert_eq(_player.get_cell(), START + Vector2i.DOWN)


func test_an_obstacle_stops_the_drift() -> void:
	_grid.set_slope(START)
	_grid.set_slope(START + Vector2i.DOWN)
	_grid.set_solid(START + Vector2i(0, 2))
	_player.set_mount(Mount.Kind.BIKE)
	_simulate(1.0)
	assert_eq(_player.get_cell(), START + Vector2i.DOWN)
	assert_false(_player.is_moving())
