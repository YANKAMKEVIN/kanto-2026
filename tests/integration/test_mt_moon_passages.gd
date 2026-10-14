extends GutTest
## Passages du Mont Sélénite **avec les PNJ en place** (jalon 12, correctif du chercheur ; dossier
## 15 §9 « après le partage, le chercheur reste dans la chambre ») sur le vrai Boot et le départ
## `mt_moon_fossil` (Sbires et chercheur battus, joueur au pied de l'échelle de sortie) :
## - B2F : de la salle de l'échelle de sortie, toute case libre est atteignable (chambre, couloir
##   du gardien, échelle D vers le 1F, CT01 du détour) avec le chercheur rangé ; le trajet se fait
##   **pour de vrai** au clavier, aller et retour, par le goulet (13..14, 31) ;
## - B1F : Sbires partis, rien ne bloque (la niche du guetteur R1 comprise).
## (La reprise après la scène du chercheur est vérifiée dans `test_mt_moon_fossil`, celle après
## le départ de chaque Sbire dans `test_mt_moon_rocket`.)

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/mt_moon_fossil.json"
const SAVE_PATH := "user://test_mt_moon_passages_save.json"
const FADE := 0.05
const TIMEOUT := 14.0
const STEP_TIMEOUT := 3.0
const RESEARCHER_AFTER := Vector2i(15, 30)
const EXIT_ROOM := Vector2i(11, 30)
const EXIT_LADDER := Vector2i(11, 29)
const NARROW: Array[Vector2i] = [Vector2i(13, 31), Vector2i(14, 31)]
const CORRIDOR_FOOT := Vector2i(25, 26)
## Cases à atteindre depuis la salle de sortie : déclencheur du chercheur, arrivée de l'échelle D,
## devant la CT01 (4, 5), devant la dalle, devant la Pierre Lune cachée (36, 12).
const KEY_CELLS: Array[Vector2i] = [Vector2i(25, 27), Vector2i(46, 3), Vector2i(4, 6),
	Vector2i(24, 30), Vector2i(24, 32), Vector2i(35, 12)]
const ACTIONS: Dictionary = {Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right"}

var _boot: Boot
var _player: Player
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T16:00:00")
	Haptics.sink = func(_ms: int) -> void: pass


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in ACTIONS.values():
		Input.action_release(action)


func _start() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(START))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = StringName(json["map"])
	_boot.start_spawn = StringName(json["spawn"])
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var data := DebugStart.new()
	assert_true(data.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(data.get_errors()))
	data.apply(GameState, _boot.get_pokemon_data())
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_companion_controller().refresh()
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


## Un seul pas vers [param direction] (un appui bref ne fait que tourner : on réessaie une fois).
func _step(direction: Vector2i) -> bool:
	var before := _player.get_cell()
	for attempt: int in 2:
		Input.action_press(ACTIONS[direction])
		await wait_until(func() -> bool:
			return _player.is_moving() or _player.get_cell() != before, STEP_TIMEOUT)
		Input.action_release(ACTIONS[direction])
		await wait_until(func() -> bool: return not _player.is_moving(), STEP_TIMEOUT)
		if _player.get_cell() != before:
			return true
	return false


## Marche au clavier jusqu'à [param goal] (chemin recalculé à chaque pas) ; cases traversées.
func _walk_to(goal: Vector2i) -> Array[Vector2i]:
	var grid := _boot.get_map().get_grid()
	var trail: Array[Vector2i] = [_player.get_cell()]
	for i: int in 120:
		var path := grid.find_path(_player.get_cell(), goal, _player)
		if path.is_empty() or not await _step(path[0]):
			break
		trail.append(_player.get_cell())
	return trail


func test_from_the_exit_room_the_whole_floor_is_reachable_with_the_researcher_aside() -> void:
	await _start()
	var map := _boot.get_map()
	assert_eq(map.map_id, &"mt_moon_b2f")
	assert_eq(_player.get_cell(), EXIT_ROOM, "départ au pied de l'échelle de sortie")
	assert_null(map.get_npc(&"mt_moon_researcher"), "plus au goulet")
	var researcher := map.get_npc(&"mt_moon_researcher_after")
	assert_not_null(researcher, "rangé dans la chambre")
	if researcher != null:
		assert_eq(researcher.get_cell(), RESEARCHER_AFTER)
		assert_eq(researcher.get_facing(), Vector2i.RIGHT, "tourné vers la dalle")
	var grid := map.get_grid()
	for cell: Vector2i in NARROW:
		assert_true(grid.is_free(cell, _player), "goulet %s libre" % cell)
	assert_eq(GridPaths.cut_off(grid, _player.get_cell(), _player), [] as Array[Vector2i],
		"aucune case de B2F coupée de la salle de sortie")
	assert_eq(GridPaths.cut_by_occupants(grid, _player.get_cell(), _player),
		[] as Array[Vector2i], "aucun PNJ ne coupe de passage")
	var reached := grid.find_reachable(_player.get_cell(), _player)
	for cell: Vector2i in KEY_CELLS + [EXIT_LADDER]:
		assert_true(reached.has(cell), "%s atteignable" % cell)


func test_walking_out_of_the_exit_room_and_back_through_the_narrow() -> void:
	await _start()
	var out := await _walk_to(CORRIDOR_FOOT)
	assert_eq(_player.get_cell(), CORRIDOR_FOOT, "pied du couloir atteint au clavier %s" % [out])
	for cell: Vector2i in NARROW:
		assert_has(out, cell, "par le goulet")
	var back := await _walk_to(EXIT_ROOM)
	assert_eq(_player.get_cell(), EXIT_ROOM, "retour à la salle de sortie %s" % [back])
	assert_eq(_boot.get_map().map_id, &"mt_moon_b2f", "aucun passage pris en route")


func test_upper_floor_free_once_the_grunts_are_gone() -> void:
	await _start()
	await SceneRouter.change_map(&"mt_moon_b1f", &"arrivee_a", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var map := _boot.get_map()
	assert_eq(map.map_id, &"mt_moon_b1f")
	assert_null(map.get_npc(&"rocket_guetteur"), "R1 parti")
	assert_null(map.get_npc(&"rocket_fouilleuse"), "R2 partie")
	assert_eq(GridPaths.cut_by_occupants(map.get_grid(), _player.get_cell(), _player),
		[] as Array[Vector2i], "B1F : rien ne bloque (les poches des échelles B et C à part)")
	assert_true(map.get_grid().find_reachable(_player.get_cell(), _player).has(
		Vector2i(14, 1)), "niche du guetteur libre")
	assert_true(map.get_grid().find_reachable(_player.get_cell(), _player).has(
		Vector2i(14, 4)), "passage sous la niche libre")
