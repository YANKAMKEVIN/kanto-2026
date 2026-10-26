extends GutTest
## Clôture du J23 (QA 23E, non vu sur le S24 : « aucune réaction en poussant ») : le Surf depuis la
## rive avec la vraie partie de sortie de l'Arène (`koga_qa` : CS03 au Sac, Aquali et Nidoking
## compatibles), sans rien simuler de l'état du Surf (FieldMoves réel de Boot, `field_moves.json`).
## - Pousser vers l'eau ne fait jamais surfer : le Surf passe par le bouton d'action (passe
##   systèmes 2, S2C) ; face à l'eau surfable, la cible du bouton est EXAMINER sans le Badge Âme,
##   SURFER avec lui.
## - L'eau surfable la plus proche de Parmanie est celle de la Route 19 (J24) ; Parmanie et les
##   zones du Parc Safari n'ont **aucune** case surfable (leur eau est du décor, §2.10 du plan :
##   le J23 ne pose pas d'eau surfable).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const SAVE_PATH := "user://test_j23_surf_after_koga_save.json"
const START := "res://tools/debug_start/koga_qa.json"
const TIMEOUT := 12.0
const FADE := 0.05
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Cartes du J23 où le joueur voit de l'eau sans pouvoir surfer.
const DRY_MAPS: Array[StringName] = [&"fuchsia_city", &"safari_zone_center",
	&"safari_zone_east", &"safari_zone_north", &"safari_zone_west"]

var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_19"
	_boot.start_spawn = &"from_fuchsia_city"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_player = _boot.get_player()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


## Pose le joueur à pied sur la case de rive la plus proche de son arrivée, tourné vers l'eau.
func _stand_on_the_shore() -> void:
	var map := SceneRouter.get_current_map()
	var grid := map.get_grid()
	var from := _player.get_cell()
	var seen: Dictionary[Vector2i, bool] = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if grid.is_surfable(next):
				_player.enter_map(grid, cell, direction, map.get_pixel_rect())
				await wait_process_frames(3)
				return
			if not seen.has(next) and grid.is_in_bounds(next) and not grid.is_solid(next) \
					and not grid.is_water(next) and not grid.is_occupied(next):
				seen[next] = true
				queue.append(next)
	fail_test("aucune rive accessible depuis l'arrivée de Parmanie")


func _target() -> Interaction:
	return _boot.get_interaction_controller().get_target()


func test_surf_is_offered_by_the_action_button_once_the_soul_badge_is_won() -> void:
	assert_eq(SceneRouter.get_current_map().map_id, &"route_19")
	assert_true(GameState.bag.has(&"hm03"), "CS03 au Sac (Maison Secrète)")
	assert_false(GameState.flags.has_flag(&"badge_soul"), "avant Koga")
	await _stand_on_the_shore()
	assert_eq(_boot.field_state(&"surf").state, FieldMoves.State.NO_BADGE)
	var target := _target()
	assert_not_null(target, "face à l'eau : une cible")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE, "sans Badge Âme : EXAMINER")
	GameState.flags.set_flag(&"badge_soul")
	await wait_process_frames(3)
	assert_eq(_boot.field_state(&"surf").state, FieldMoves.State.READY)
	target = _target()
	assert_not_null(target)
	if target != null:
		assert_eq(target.kind, Interaction.Kind.SURF, "Badge Âme : SURFER")
	# Pousser vers l'eau ne monte jamais en Surf (refus de pas, à pied).
	var cell := _player.get_cell()
	Input.action_press(_action(_player.get_facing()))
	await wait_process_frames(20)
	Input.action_release(_action(_player.get_facing()))
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
	assert_eq(_player.get_cell(), cell, "pousser ne fait pas entrer dans l'eau")
	assert_eq(_player.get_mount(), Mount.Kind.NONE)
	assert_push_error_count(0)


func test_fuchsia_and_the_safari_zone_have_no_surfable_water() -> void:
	for map_id: StringName in DRY_MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		assert_eq(map.surf_cells.size(), 0, "%s : eau de décor seulement" % map_id)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"
