extends GutTest
## Surf du joueur dans la vraie partie (passe systèmes 2, `systemes-2.md` §2.5, T12 à T14) : la
## vraie scène Boot sur la Route 1, une bande d'eau surfable posée en mémoire devant le joueur.
## Bouton contextuel (SURFER / EXAMINER), montée par un saut, texte T-3 une seule fois, nage,
## descente sur la rive, Vélo rangé, reprise d'une partie en Surf et ses garde-fous.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_surf_integration_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
## Longueur de la bande d'eau posée au-dessus du joueur.
const WATER_LENGTH := 3

var _boot: Boot
var _fades: Array[float] = []
var _mount: MountDirector
var _player: Player
var _grid: GridWorld
var _start: Vector2i
var _ready_state: FieldMoves.State = FieldMoves.State.READY


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.flags.set_flag(&"starter_chosen")
	_mount = _boot.get_mount_director()
	_player = _boot.get_player()
	_grid = SceneRouter.get_current_map().get_grid()
	_start = _player.get_cell()
	for i: int in range(1, WATER_LENGTH + 1):
		var cell := _start + Vector2i.UP * i
		_grid.set_solid(cell, false)
		_grid.set_surfable(cell)
	_ready_state = FieldMoves.State.READY
	_mount.surf_state = func() -> FieldMoves.State: return _ready_state
	# La CS03 arrive avec les données du S2C : le texte nomme un Pokémon prêt.
	_boot.get_dialogue_runner().field_source = func(_move: StringName) -> FieldMoves.Result:
		var result := FieldMoves.Result.new(_ready_state, 0)
		result.pokemon_name = "Carapuce"
		return result


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _interactions() -> InteractionController:
	return _boot.get_interaction_controller()


func _surf_up() -> void:
	assert_eq(_mount.start_surf(), SurfRules.MountCheck.READY, "SURFER")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func test_facing_water_the_button_says_surf_when_ready() -> void:
	var target := _mount.surf_target(_start, Vector2i.UP)
	assert_not_null(target)
	assert_eq(target.kind, Interaction.Kind.SURF)
	assert_eq(target.cell, _start + Vector2i.UP)
	assert_same(_mount.surf_target(_start, Vector2i.UP), target,
		"même instance tant que rien ne change (le contrôleur compare les instances)")
	assert_null(_mount.surf_target(_start, Vector2i.DOWN), "pas d'eau devant : rien")


func test_facing_water_without_the_hm_the_button_examines() -> void:
	_ready_state = FieldMoves.State.NO_HM
	var target := _mount.surf_target(_start, Vector2i.UP)
	assert_eq(target.kind, Interaction.Kind.EXAMINE)
	assert_eq(target.dialogue_id, MountDirector.SURF_WATER_DIALOGUE)
	assert_eq(_mount.start_surf(), SurfRules.MountCheck.NO_HM, "rien ne part")
	assert_eq(_player.get_mount(), Mount.Kind.NONE)


func test_the_interaction_controller_offers_the_water_target() -> void:
	await wait_process_frames(3)
	var target := _interactions().get_target()
	assert_not_null(target, "aucune entité devant : la cible de terrain")
	assert_eq(target.kind, Interaction.Kind.SURF)


func test_surf_jumps_onto_the_water_and_says_t3_once() -> void:
	assert_eq(_mount.start_surf(), SurfRules.MountCheck.READY)
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
	assert_true(_player.is_jumping(), "la montée est un saut")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), _start + Vector2i.UP)
	assert_eq(GameState.player_mount, Mount.Kind.SURF, "GameState suit")
	assert_eq(GameState.last_land_cell, _start, "dernière terre : la rive")
	var runner := _boot.get_dialogue_runner()
	assert_true(runner.is_running(), "T-3 la première fois")
	assert_true(GameState.flags.has_flag(MountDirector.SURF_FIRST_FLAG))
	assert_false(_boot.get_hud().get_bike_button().visible and \
		not _boot.get_hud().is_bike_button_dimmed(), "pas de Vélo en mer")


func test_swim_then_dismount_on_the_shore() -> void:
	GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	await _surf_up()
	assert_false(_boot.get_dialogue_runner().is_running(), "T-3 déjà vu : rien")
	assert_true(_player.script_step(Vector2i.UP), "nage")
	assert_false(_player.is_jumping(), "nager n'est pas un saut")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
	assert_true(_player.script_step(Vector2i.DOWN))
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_true(_player.script_step(Vector2i.DOWN), "vers la rive")
	assert_true(_player.is_jumping(), "la descente est un saut")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell(), _start)
	assert_eq(_player.get_mount(), Mount.Kind.NONE, "à pied sur la rive")
	assert_eq(GameState.player_mount, Mount.Kind.NONE)


func test_the_bike_is_put_away_to_surf() -> void:
	GameState.bag.add(&"bicycle", 1)
	GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	assert_eq(_mount.toggle_bike(), BikeRules.Check.OK)
	assert_eq(_player.get_mount(), Mount.Kind.BIKE)
	await _surf_up()
	assert_eq(_player.get_mount(), Mount.Kind.SURF)
	assert_true(_mount.is_bike_blocked(), "bouton Vélo grisé en mer")
	assert_eq(_mount.toggle_bike(), BikeRules.Check.BUSY, "pas de Vélo en mer")


func test_resume_on_the_water_keeps_surfing() -> void:
	var map := SceneRouter.get_current_map()
	var water := _start + Vector2i.UP * 2
	GameState.player_mount = Mount.Kind.SURF
	GameState.last_land_cell = _start
	assert_eq(_mount.resume_cell(map, water), water)
	assert_eq(GameState.player_mount, Mount.Kind.SURF)


func test_resume_without_the_conditions_goes_back_to_the_last_shore() -> void:
	var map := SceneRouter.get_current_map()
	GameState.player_mount = Mount.Kind.SURF
	GameState.last_land_cell = _start
	_ready_state = FieldMoves.State.NO_POKEMON
	assert_eq(_mount.resume_cell(map, _start + Vector2i.UP * 2), _start, "garde-fou : la rive")
	assert_eq(GameState.player_mount, Mount.Kind.NONE, "à pied")


func test_resume_on_foot_keeps_the_router_rule() -> void:
	GameState.player_mount = Mount.Kind.NONE
	assert_eq(_mount.resume_cell(SceneRouter.get_current_map(), _start), Vector2i(-1, -1))


func test_map_change_while_surfing_onto_land_walks() -> void:
	GameState.flags.set_flag(MountDirector.SURF_FIRST_FLAG)
	await _surf_up()
	_mount.on_map_changed(SceneRouter.get_current_map())
	assert_eq(_player.get_mount(), Mount.Kind.SURF, "toujours sur l'eau : en Surf")
