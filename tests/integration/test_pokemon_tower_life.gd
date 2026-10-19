extends GutTest
## La vie du rez-de-chaussée de la Tour Pokémon (jalon 18 T24, jalon-18.md §4.12 ; dossier 21 §7,
## §12, §14, §15.4) avec la vraie scène Boot et une sauvegarde en mémoire :
## - 36 tombes examinables : 5 nommées (T-36 à T-40), 31 « Une tombe bien entretenue. » (T-41) ;
## - gardien (T-30, à travers le comptoir) et trois visiteurs (T-31 à T-33) ;
## - Exorciste (gardienne) : elle occupe la seule case d'accès à l'escalier, qui reste
##   inatteignable ; quand `tower_stairs_open` est levé (J19, T16) elle se range en (18, 3) ;
##   T-34 et T-35 sont remplacés par la scène `tower_guardian` (`test_pokemon_tower_1f_j19`) ;
## - du J19 : seulement l'escalier armé et le premier pas (aucun spectre ni combat ici).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PLAN_PATH := "res://tools/plans/tour_pokemon_rdc.txt"
const SAVE_NAME := "test_pokemon_tower_life"
const STAIRS := Vector2i(17, 2)
const ACCESS := Vector2i(17, 3)
## Tombe nommée → [case de la grille, case de lecture, texte].
const NAMED := {
	"tombe_1": [Vector2i(4, 4), "Ici repose Plumo. Il chantait pour\nréveiller toute la maison."],
	"tombe_2": [Vector2i(7, 6), "Pour Caillou, qui n'a jamais eu\npeur de rien."],
	"tombe_3": [Vector2i(12, 4), "Tu nous as appris la patience.\nMerci, Mousse."],
	"tombe_4": [Vector2i(15, 6), "À notre Rondoudou, qui endormait\nles enfants."],
	"tombe_5": [Vector2i(5, 10), "Repose en paix, vieil ami.\nOn se reverra."],
}
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _titles: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-16T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()
	_titles.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map_id] / [param spawn] ; [param start] = départ de débogage appliqué si
## [param fresh] ; joueur reposé sur [param cell] (le départ lui-même n'est pas une arrivée).
func _start(map_id: StringName, spawn: StringName, start: String, cell: Vector2i,
		facing: Vector2i, fresh: bool = true) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
	_connect_signals()
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _connect_signals() -> void:
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.zone_announced.connect(func(zone: String, region: String) -> void:
		_titles.append("%s / %s" % [zone, region]))


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


## Marche vers [param direction] jusqu'à [param until] (ou jusqu'à une scène).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _scenes.is_empty(), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Examine ce qui est devant [param facing] depuis [param cell] (pages dans `_pages`).
func _read_from(cell: Vector2i, facing: Vector2i) -> void:
	_pages.clear()
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)
	await _press_interact()
	await wait_process_frames(4)
	if _runner.is_running():
		await _finish_scene()


## Case praticable voisine de [param cell] (hors hautes herbes) et la direction qui mène de
## cette case à [param cell].
func _neighbour(cell: Vector2i) -> Array:
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if _plan.is_walkable(from) and _plan.at(from) != "h":
			return [from, -direction]
	return []


func _bag(item: StringName) -> int:
	return GameState.bag.count_of(item)


func _begin(extra_flags: Array[StringName] = []) -> void:
	await _start(&"pokemon_tower_1f", &"entrance", "pokemon_tower_1f", Vector2i(9, 16),
		Vector2i.UP)
	for flag: StringName in extra_flags:
		GameState.flags.set_flag(flag)


## Parle à [param npc_id] depuis une case voisine libre (routines tenues).
func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	var cell := npc.get_cell()
	for direction: Vector2i in DIRECTIONS:
		var from := cell + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	_pages.clear()
	_speakers.clear()
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


# --- Tombes ------------------------------------------------------------------------------------

func test_the_five_named_graves_say_t36_to_t40() -> void:
	await _begin()
	for id: String in NAMED:
		var grave := _plan.cell_of(id)
		var reading: Vector2i = NAMED[id][0]
		assert_eq(absi(grave.x - reading.x) + absi(grave.y - reading.y), 1, "%s : voisine" % id)
		await _read_from(reading, grave - reading)
		assert_eq(_pages, [NAMED[id][1]] as Array[String], id)
	assert_eq(_scenes.size(), 0, "aucune scène")
	assert_eq(_toasts.size(), 0)


func test_every_other_grave_says_t41_from_any_free_side() -> void:
	await _begin()
	var named: Array[Vector2i] = []
	for id: String in NAMED:
		named.append(_plan.cell_of(id))
	var others := 0
	for grave: Vector2i in _plan.cells_of("g"):
		if named.has(grave):
			continue
		others += 1
		var found := false
		for direction: Vector2i in DIRECTIONS:
			var from := grave + direction
			if _plan.is_walkable(from):
				var target := _boot.get_map().get_interactions().find(grave, -direction)
				assert_not_null(target, "tombe %s lisible depuis %s" % [grave, from])
				if target != null:
					assert_eq(target.dialogue_id, &"pokemon_tower_grave")
				found = true
		assert_true(found, "tombe %s : une case de lecture" % grave)
	assert_eq(others, 31)
	await _read_from(Vector2i(3, 4), Vector2i.DOWN)
	assert_eq(_pages, ["Une tombe bien entretenue."] as Array[String], "T-41")


# --- Gardien et visiteurs ----------------------------------------------------------------------

func test_the_keeper_is_spoken_to_across_the_counter() -> void:
	await _begin()
	assert_eq(_boot.get_map().get_npc(&"gardien").get_cell(), Vector2i(3, 12))
	await _read_from(Vector2i(3, 14), Vector2i.UP)
	assert_eq(_pages, ["Bienvenue à la Tour Pokémon.",
		"On vient ici se souvenir de ceux\nqui nous ont accompagnés.",
		"Prends ton temps."] as Array[String], "T-30")
	assert_true(_boot.get_map().get_grid().is_solid(Vector2i(3, 13)), "le comptoir bloque")


func test_the_visitors_say_t31_to_t33() -> void:
	await _begin()
	for npc: Npc in _boot.get_map().get_npcs():
		npc.set_routine_held(true)
	var expected := {
		&"visiteuse": ["Visiteuse", ["Mon Rattata m'a suivi pendant\nquinze ans.",
			"Il était têtu, et je l'adorais."]],
		&"visiteur": ["Visiteur", ["…", "Je n'ai pas grand-chose à dire.\nJe suis juste venu."]],
		&"jeune_fille": ["Jeune fille", ["Je viens chaque semaine.\nPour qu'il ne se sente pas seul."]],
	}
	for id: StringName in expected:
		await _talk_to(id)
		assert_eq(_pages, expected[id][1] as Array[String], String(id))
		assert_eq(_speakers[0], expected[id][0])


# --- Exorciste (gardienne) ---------------------------------------------------------------------

func test_the_guardian_blocks_the_only_access_to_the_stairs() -> void:
	await _begin()
	var map := _boot.get_map()
	var guardian := map.get_npc(&"exorciste_gardienne")
	assert_not_null(guardian)
	assert_eq(guardian.get_cell(), ACCESS)
	assert_true(map.get_grid().is_occupied(ACCESS))
	var reached := map.get_grid().find_reachable(Vector2i(9, 16), _player)
	assert_false(reached.has(STAIRS), "escalier inatteignable")
	assert_false(reached.has(ACCESS))
	map.spawn_player_at(_player, Vector2i(17, 4), Vector2i.UP)
	await wait_process_frames(3)
	Input.action_press(&"move_up")
	await wait_process_frames(30)
	Input.action_release(&"move_up")
	assert_eq(_player.get_cell(), Vector2i(17, 4), "elle ne s'écarte pas")
	assert_eq(_scenes.size(), 0)


func test_talking_to_the_guardian_before_the_flag_plays_the_j19_scene() -> void:
	# J19 (T16) : plus de T-34 / T-35 ; avant `tower_stairs_open`, lui parler joue la scène
	# (partie chargée déjà dans la salle). L'objectif du J18 reste « visiter la Tour Pokémon ».
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	await _begin([&"dark_cave_crossed", &"lavender_reached"])
	assert_eq(library.current(GameState.flags), "visiter la Tour Pokémon.")
	await _read_from(Vector2i(17, 4), Vector2i.UP)
	assert_eq(_scenes, [&"tower_guardian"] as Array[StringName], "la scène de la gardienne")
	assert_eq(_pages[0], "Ah… C'est vous.\nPardonnez-moi, je priais.")
	assert_true(GameState.flags.has_flag(&"tower_stairs_open"))
	assert_false(GameState.flags.has_flag(&"tower_medium_talked"), "T-34 n'est plus joué")


func test_the_guardian_steps_aside_to_18_3_when_the_stairs_flag_is_raised() -> void:
	await _begin()
	var map := _boot.get_map()
	assert_false(map.get_grid().find_reachable(Vector2i(9, 16), _player).has(STAIRS))
	GameState.flags.set_flag(&"tower_stairs_open")
	map.refresh_npcs(GameState.flags)
	await wait_process_frames(3)
	var guardian := map.get_npc(&"exorciste_gardienne")
	assert_not_null(guardian, "elle reste dans la salle (J19 : `moved`, plus `unless`)")
	assert_eq(guardian.get_cell(), Vector2i(18, 3))
	assert_eq(guardian.get_facing(), Vector2i.LEFT)
	assert_false(map.get_grid().is_occupied(ACCESS), "elle n'occupe plus la case")
	assert_true(map.get_grid().find_reachable(Vector2i(9, 16), _player).has(STAIRS),
		"la voie est libre sans elle")


func test_only_the_t16_pieces_of_j19_are_there() -> void:
	await _begin()
	var map := _boot.get_map()
	assert_eq(map.get_npcs().size(), 5, "gardien, trois visiteurs, Exorciste")
	assert_eq(map.get_node(^"Triggers").get_child_count(), 2, "premier pas (9..10, 15), T16")
	assert_eq(map.get_interactions().get_all().size(), 36 + 4, "36 tombes + comptoir (4 cases)")
	var stairs := map.get_warps().find_on_step(STAIRS, Vector2i.UP)
	assert_not_null(stairs)
	if stairs != null:
		assert_false(stairs.is_coming_soon(), "armé vers le 2F (T16)")
