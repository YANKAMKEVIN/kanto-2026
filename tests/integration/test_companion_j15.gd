extends GutTest
## Compagnon sur les cartes du jalon 15 (T20, jalon-15.md §2.10 ; dossier 14 §8 ; règle du J11)
## sur la vraie scène Boot : Miaouss (planche validée, A-11) suit sur la Route 5, la Route 6, à
## Carmin-sur-Mer et dans le passage souterrain (ni grotte ni intérieur : visible comme sur une
## route, phrase générique faute de contexte « souterrain » [D]) ; rentré dans les intérieurs
## (Pension, bâtiments d'entrée, Centre de Carmin) ; à Carmin, phrase « ville » (ou « eau » près du
## port) ; **déposé à la vraie Pension** (`route_5_daycare`, gardien au comptoir) → plus de
## compagnon, ni dehors ni après rechargement.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_j15_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]
## Carte → [point d'apparition, départ de débogage].
const OUTDOORS := {
	&"route_5": [&"from_cerulean_c", "route_5"],
	&"route_6": [&"from_underground", "route_6"],
	&"vermilion_city": [&"from_route_6_c", "vermilion"],
	&"underground_path": [&"from_route_5_w", "underground_path"],
}
## Intérieur → [carte d'où l'on part, point d'apparition dehors, point d'arrivée dedans].
const INDOORS := {
	&"route_5_daycare": [&"route_5", &"from_cerulean_c", &"entrance"],
	&"route_5_gate": [&"route_5", &"from_cerulean_c", &"from_route_5"],
	&"route_5_underground_gate": [&"underground_path", &"from_route_5_w", &"from_underground_w"],
	&"route_6_underground_gate": [&"route_6", &"from_underground", &"from_route_6"],
	&"vermilion_center": [&"vermilion_city", &"from_route_6_c", &"entrance"],
}

var _fs: MemoryFs
var _boot: Boot
var _companion: CompanionController
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")
	_fs = MemoryFs.new()


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact", &"run"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## Boot sur [param map] (départ [param start]) ; Miaouss N17 en tête et compagnon si
## [param add_meowth] (sinon le départ fournit l'équipe et le compagnon) ; [param keep_save] :
## reprend la sauvegarde en mémoire de la partie précédente (sinon une copie vierge).
func _start(map: StringName, spawn: StringName, start: String, add_meowth: bool = true,
		keep_save: bool = false) -> void:
	if not keep_save:
		_fs = MemoryFs.new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_companion = _boot.get_companion_controller()
	if not start.is_empty():
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
	if add_meowth:
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


## Un pas libre (ni passage, ni herbes hautes) depuis la position du joueur.
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


## Deux pas libres (le premier peut lancer une micro-scène d'arrivée) puis attente du compagnon.
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


# --- Dehors : il suit ----------------------------------------------------------------------------

func test_meowth_follows_on_the_four_outdoor_maps() -> void:
	var catalog := CompanionCatalog.new()
	assert_true(catalog.load_file(), "\n".join(catalog.get_errors()))
	assert_true(catalog.is_eligible_species(&"meowth"), "Miaouss éligible (A-11)")
	for map_id: StringName in OUTDOORS:
		var info: Array = OUTDOORS[map_id]
		await _start(map_id, info[0], info[1])
		assert_false(_boot.get_map().interior, "%s : ni bâtiment ni intérieur" % map_id)
		await _walk_until_shown()
		assert_true(_companion.is_shown(), "%s : Miaouss suit" % map_id)
		assert_eq(_companion.get_chosen().species_id, &"meowth")
		var cell := _companion.get_node_2d().get_cell()
		var gap := cell - _boot.get_player().get_cell()
		assert_eq(absi(gap.x) + absi(gap.y), 1, "%s : juste derrière le héros" % map_id)
		_boot.queue_free()
		await wait_process_frames(3)
	assert_push_error_count(0)


func test_underground_line_is_generic_and_vermilion_is_a_city() -> void:
	var catalog := CompanionCatalog.new()
	catalog.load_file()
	assert_eq(catalog.context_of(&"underground_path"), &"", "souterrain : aucun contexte [D]")
	assert_eq(catalog.context_of(&"vermilion_city"), &"city", "Carmin : ville")
	for map_id: StringName in [&"route_5", &"route_6"]:
		assert_eq(catalog.context_of(map_id), &"", "%s : générique" % map_id)
	await _start(&"underground_path", &"from_route_5_w", "underground_path")
	await _walk_until_shown()
	var line := _companion.talk()
	assert_true(CompanionRules.GENERIC_LINES.has(line), "phrase générique (%s)" % line)
	await _close_dialogue()
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"vermilion_city", &"from_route_6_c", "vermilion")
	await _walk_until_shown()
	assert_true(_companion.talk() in [&"companion_city", &"companion_water"], "ville ou port")
	await _close_dialogue()
	assert_push_error_count(0)


# --- Dedans : il rentre ---------------------------------------------------------------------------

func test_withdrawn_in_the_j15_interiors_and_out_again() -> void:
	for room: StringName in INDOORS:
		var info: Array = INDOORS[room]
		await _start(info[0], info[1], String(OUTDOORS[info[0]][1]))
		await _walk_until_shown()
		assert_true(_companion.is_shown(), "%s : visible dehors" % info[0])
		await _go(room, info[2])
		assert_true(_boot.get_map().interior, "%s : intérieur" % room)
		assert_false(_companion.is_shown(), "%s : rentré" % room)
		_boot.queue_free()
		await wait_process_frames(3)
	assert_push_error_count(0)


# --- Pension réelle : déposé = effacé ------------------------------------------------------------

func test_depositing_the_companion_at_the_real_daycare_clears_it() -> void:
	await _start(&"route_5_daycare", &"counter", "route_5_daycare", false)
	assert_eq(_boot.get_map().map_id, &"route_5_daycare")
	var meowth := GameState.get_companion()
	assert_not_null(meowth, "Miaouss compagnon (départ)")
	assert_eq(meowth.species_id, &"meowth")
	var daycare := _boot.get_daycare_director()
	daycare.pick_requested.connect(func(view: DaycarePickView) -> void:
		var index := -1
		for i: int in view.party.size():
			if view.party.get_at(i) == meowth:
				index = i
		assert_eq(daycare.choose_deposit(index), DaycareRules.Status.OK))
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var player := _boot.get_player()
	assert_eq(player.get_cell(), Vector2i(7, 5), "devant le comptoir")
	player.face(Vector2i.UP)
	await wait_process_frames(2)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return runner.is_running(), TIMEOUT)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (runner.is_running() or daycare.is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running() or daycare.is_running(), "conversation finie")
	assert_eq(GameState.daycare.pokemon, meowth, "Miaouss gardé")
	assert_eq(GameState.companion_uid, "", "compagnon effacé")
	# Dehors : plus personne ne suit.
	await _go(&"route_5", &"from_daycare")
	await _step(Vector2i.DOWN)
	await wait_process_frames(10)
	assert_false(_companion.is_shown(), "plus de compagnon sur la Route 5")
	assert_null(_companion.get_chosen())
	# Rechargement : toujours aucun.
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _fs.files.has(SAVE_PATH), TIMEOUT)
	await wait_process_frames(3)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"route_5", &"from_daycare", "", false, true)
	assert_eq(GameState.companion_uid, "", "relu : aucun compagnon")
	assert_eq(GameState.daycare.pokemon.species_id, &"meowth", "relu : Miaouss à la Pension")
	await _step(Vector2i.DOWN)
	await wait_process_frames(10)
	assert_false(_companion.is_shown(), "relu : personne ne suit")
	assert_push_error_count(0)
