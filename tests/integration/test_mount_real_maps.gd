extends GutTest
## Monture sur de vraies cartes (passe systèmes 2, §2.2–§2.4). Les cartes de QA `qa_mount`,
## `qa_mount_interieur`, `qa_mount_piste` et le départ `s2_bike` sont retirés en S2Z (T33) ; ce qui
## y éprouvait un système est rejoué ici, sans rien livrer :
## - dormeur de la Poké Flûte : le vrai Ronflex de la Route 12 (celui de la Route 11 y est déplacé
##   au J21, arbitrage M-3), dont le point d'examen reçoit **en
##   mémoire** une `flute_cutscene` d'essai ([method GameMap.flute_targets], [PokeFluteRules],
##   [FlagGate] qui libère ses cases avec le drapeau) ;
## - dans le vrai Boot : départ écrit sous `user://` sur la Route 2, à pied, Bicyclette au Sac ;
##   porte du poste sud de la Forêt de Jade (intérieur : à pied), retour, puis passage de bord
##   vers la Route 2 est rendue **Piste Cyclable en mémoire** (`cycling_road`, fabrique de
##   [member SceneRouter.map_factory]) : arrivée en Vélo d'office, et retour.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FADE := 0.05
const TIMEOUT := 12.0
const SNORLAX_FLAG: StringName = &"snorlax_route_12_done"
const FLUTE_SCENE: StringName = &"essai_reveil"
const PISTE: StringName = &"route_2_east"
## `user://` est partagé par toutes les copies du dépôt : un nom par processus évite qu'une suite
## lancée en parallèle écrase ou efface le départ d'une autre.
var _start_path := "user://test_mount_real_maps_start_%d.json" % OS.get_process_id()
const GATE_DOOR := Vector2i(20, 8)
const EAST_EDGE := Vector2i(41, 43)
## Départ (ancien `s2_bike`) : Pikachu, Roucool endormi, Bicyclette et Poké Flûte.
const START := {
	"map": "route_2", "spawn": "from_forest_gate", "facing": "down",
	"flags": ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
		"starter_chosen", "taken_charmander", "taken_squirtle", "rival_lab_won",
		"rival_challenged", "rival_battle_done", "rival_left_lab", "viridian_arrived",
		"got_oak_parcel", "pokedex_activated", "poison_unlocked"],
	"party": [{"species": "pikachu", "level": 12},
		{"species": "pidgey", "level": 12, "status": "sleep", "status_turns": 5}],
	"companion": 0,
	"bag": {"bicycle": 1, "poke_flute": 1, "poke_ball": 10, "potion": 5},
	"money": 3000,
}

var _boot: Boot
var _fades: Array[float] = []


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)
	if not _fades.is_empty():
		SceneRouter.fade_out_duration = _fades[0]
		SceneRouter.fade_in_duration = _fades[1]
		_fades.clear()
		GameState.clock = DeviceClock.new()
	SceneRouter.map_factory = Callable()
	if FileAccess.file_exists(_start_path):
		DirAccess.remove_absolute(_start_path)


# --- Poké Flûte : le Ronflex de la Route 12 ------------------------------------------------------

func _route_12_with_flute() -> GameMap:
	var map := (load(MapCatalog.scene_path(&"route_12")) as PackedScene).instantiate() as GameMap
	var point := map.get_node(^"Interactables/SnorlaxPoint") as InteractPoint
	point.flute_cutscene = FLUTE_SCENE
	add_child_autofree(map)
	return map


func test_the_sleeper_blocks_until_its_flag_and_is_the_flute_target_next_to_it() -> void:
	var map := _route_12_with_flute()
	var grid := map.get_grid()
	var targets := map.flute_targets()
	assert_eq(targets.size(), 1, "un dormeur")
	var sleeper := targets[0]
	assert_eq(sleeper.cutscene_id, FLUTE_SCENE)
	assert_eq(sleeper.unless_flags, [SNORLAX_FLAG] as Array[StringName])
	assert_false(sleeper.cells.is_empty())
	var flags := StoryFlags.new()
	map.apply_flag_gates(flags)
	for cell: Vector2i in sleeper.cells:
		assert_true(grid.is_occupied(cell), "le dormeur occupe %s" % cell)
	var beside := sleeper.cells[0] + Vector2i.DOWN
	if sleeper.cells.has(beside):
		beside = sleeper.cells[-1] + Vector2i.DOWN
	assert_true(sleeper.touches(beside), "la Flûte joue juste à côté")
	assert_eq(PokeFluteRules.field_target(targets, beside, flags), FLUTE_SCENE)
	assert_eq(PokeFluteRules.field_target(targets, sleeper.cells[0] + Vector2i(0, 6), flags), &"",
		"trop loin : la Flûte joue ailleurs")
	flags.set_flag(SNORLAX_FLAG)
	map.apply_flag_gates(flags)
	for cell: Vector2i in sleeper.cells:
		assert_false(grid.is_occupied(cell), "%s libérée" % cell)
	assert_eq(PokeFluteRules.field_target(targets, beside, flags), &"", "plus de dormeur")


# --- Vrai Boot : porte d'intérieur et Piste Cyclable --------------------------------------------

## Vraie scène ; la Route 2 est devient une Piste Cyclable (en mémoire seulement).
func _make_map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	if map_id == PISTE:
		map.cycling_road = true
	return map


func _boot_on_route_2() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	SceneRouter.map_factory = _make_map
	GameState.clock = FixedClock.new("2026-10-20T10:00:00")
	var file := FileAccess.open(_start_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(START))
	file.close()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_mount_real_maps_save.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = _start_path
	add_child_autofree(_boot)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _step(direction: Vector2i) -> void:
	assert_true(_boot.get_player().script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return not _boot.get_player().is_moving() \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(2)


## Pousse vers [param action] (warp PUSH : le joueur bute contre le bord) jusqu'à la carte
## [param map_id].
func _push_to(action: StringName, map_id: StringName) -> void:
	Input.action_press(action)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await wait_process_frames(3)


func test_boot_walks_into_an_interior_and_rides_onto_the_cycling_road() -> void:
	await _boot_on_route_2()
	var player := _boot.get_player()
	assert_eq(_boot.get_map().map_id, &"route_2")
	assert_false(_boot.get_map().cycling_road, "la vraie Route 2 n'est pas une Piste")
	assert_eq(GameState.bag.count_of(&"bicycle"), 1)
	assert_eq(GameState.party.size(), 2)
	# Poste de la Forêt : un pas dans la porte (STEP_ON ↑), puis un pas sur le tapis de sortie.
	_boot.get_map().spawn_player_at(player, GATE_DOOR + Vector2i.DOWN, Vector2i.UP)
	await _step(Vector2i.UP)
	await wait_until(func() -> bool: return _boot.get_map().map_id \
		== &"viridian_forest_gate_south" and _boot.is_stable(), TIMEOUT)
	assert_true(_boot.get_map().interior)
	assert_eq(player.get_mount(), Mount.Kind.NONE, "à pied dans l'intérieur")
	_boot.get_map().spawn_player_at(player, Vector2i(4, 6), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_2" \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"route_2", "retour sur la Route 2")
	# Piste : poussée vers l'est depuis la case de bord, arrivée en Vélo d'office.
	_boot.get_map().spawn_player_at(player, EAST_EDGE, Vector2i.RIGHT)
	await _push_to(&"move_right", PISTE)
	assert_true(_boot.get_map().cycling_road)
	assert_eq(player.get_mount(), Mount.Kind.BIKE, "monté d'office avec la Bicyclette")
	# Retour par le bord ouest de la Piste.
	await _push_to(&"move_left", &"route_2")
	assert_eq(player.get_cell(), EAST_EDGE)
