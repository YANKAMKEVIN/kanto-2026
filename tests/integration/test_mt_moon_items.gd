extends GutTest
## Objets de l'événement du Mont Sélénite (jalon 12, T25 ; `jalon-12.md` §2.7, §2.8, §2.22,
## dossier 15 §10, §12, §20 n° 31) sur le vrai Boot et les vrais étages :
## - Pierre Lune **visible** dans la poche de l'échelle C (B1F, (25, 20)) : PRENDRE, toast, Sac,
##   journal, absente au rechargement ;
## - CT01 Ultimapoing au fond de la salle des éclats (B2F, (4, 5)) : PRENDRE, toast « obtenue » ;
## - Pierre Lune **cachée** (B2F) : rien de côté ni de dos, EXAMINER face à l'éclat isolé (36, 12)
##   depuis (35, 12), toast seul, plus de cible ensuite ni après rechargement ;
## - départs de la session 12C (`mt_moon_weak`, `mt_moon_fossil`, `moon_stone_qa`) valides, et la
##   Pierre Lune compatible avec les quatre espèces de `moon_stone_qa`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_mt_moon_items_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const MOON_STONE_CELL := Vector2i(25, 20)
const TM_CELL := Vector2i(4, 5)
const HIDDEN_STAND := Vector2i(35, 12)
const HIDDEN_CLUE := Vector2i(36, 12)
const HIDDEN_FLAG := &"got_mt_moon_b2f_hidden_1"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T14:00:00")
	_fs = MemoryFs.new()
	_toasts.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(start: String, fresh: bool = true) -> void:
	var path := STARTS + start + ".json"
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = StringName(json["map"])
	_boot.start_spawn = StringName(json["spawn"])
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var data := DebugStart.new()
		assert_true(data.load_file(path, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(data.get_errors()))
		data.apply(GameState, _boot.get_pokemon_data())
		_boot.get_map().refresh_npcs(GameState.flags)
		_boot.get_companion_controller().refresh()
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


func _reload(start: String) -> void:
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_toasts.clear()
	await _start(start, false)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _found(item: String, map_id: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == map_id:
			count += 1
	return count


## PRENDRE l'objet [param npc_id] posé en [param cell].
func _take(npc_id: StringName, cell: Vector2i, item: StringName, flag: StringName,
		map_id: String) -> void:
	var map := _boot.get_map()
	assert_not_null(map.get_npc(npc_id), "%s au sol" % npc_id)
	var grid := map.get_grid()
	var stand := Vector2i(-1, -1)
	var facing := Vector2i.ZERO
	for direction: Vector2i in DIRECTIONS:
		if grid.is_free(cell - direction):
			stand = cell - direction
			facing = direction
			break
	await _put(stand, facing)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible PRENDRE")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := GameState.bag.count_of(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(npc_id) == null, TIMEOUT)
	await _finish_scene()
	assert_null(map.get_npc(npc_id), "objet retiré")
	assert_eq(GameState.bag.count_of(item), before + 1, "%s + 1" % item)
	assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_eq(_found(String(item), map_id), 1, "journal des objets trouvés")


func test_the_visible_moon_stone_of_the_b1f_pocket() -> void:
	await _start("mt_moon_b1f")
	await _take(&"mt_moon_b1f_ball_1", MOON_STONE_CELL, &"moon_stone",
		&"got_mt_moon_b1f_item_1", "mt_moon_b1f")
	assert_eq(_toasts.size(), 1, "un toast")
	if _toasts.size() == 1:
		assert_eq(_toasts[0][0], "Pierre Lune ×1")
	await _reload("mt_moon_b1f")
	assert_null(_boot.get_map().get_npc(&"mt_moon_b1f_ball_1"), "absente au rechargement")
	assert_eq(GameState.bag.count_of(&"moon_stone"), 1)


func test_tm01_at_the_back_of_the_shard_room() -> void:
	await _start("mt_moon_b2f")
	assert_eq(GameState.bag.count_of(&"tm01"), 0)
	await _take(&"mt_moon_b2f_ball_1", TM_CELL, &"tm01", &"got_mt_moon_b2f_item_1",
		"mt_moon_b2f")
	assert_eq(_toasts, [PackedStringArray(["CT01 — Ultimapoing", "obtenue"])],
		"toast des CT (J11)")
	await _reload("mt_moon_b2f")
	assert_null(_boot.get_map().get_npc(&"mt_moon_b2f_ball_1"), "absente au rechargement")


func test_the_hidden_moon_stone_faces_its_shard_then_disappears() -> void:
	await _start("mt_moon_b2f")
	var controller := _boot.get_interaction_controller()
	assert_true(_boot.get_map().get_grid().is_solid(HIDDEN_CLUE), "indice : case bloquée")
	await _put(HIDDEN_STAND, Vector2i.UP)
	assert_null(controller.get_target(), "de côté : rien")
	await _put(HIDDEN_STAND, Vector2i.LEFT)
	assert_null(controller.get_target(), "de dos : rien")
	await _put(HIDDEN_STAND, Vector2i.RIGHT)
	var target := controller.get_target()
	assert_not_null(target, "face à l'éclat : EXAMINER")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.EXAMINE)
		assert_eq(target.dialogue_id, &"mt_moon_b2f_hidden_1")
	var before := GameState.bag.count_of(&"moon_stone")
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(HIDDEN_FLAG), TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"moon_stone"), before + 1, "Pierre Lune + 1")
	assert_eq(_found("moon_stone", "mt_moon_b2f"), 1, "journal des objets trouvés")
	assert_eq(_toasts.size(), 1, "un toast, aucune phrase nouvelle")
	if _toasts.size() == 1:
		assert_eq(_toasts[0][0], "Pierre Lune ×1")
	await wait_process_frames(3)
	assert_null(controller.get_target(), "plus rien à examiner")
	await _reload("mt_moon_b2f")
	await _put(HIDDEN_STAND, Vector2i.RIGHT)
	assert_null(_boot.get_interaction_controller().get_target(), "ni après rechargement")
	assert_eq(GameState.bag.count_of(&"moon_stone"), before + 1, "trouvée une seule fois")


func test_the_12c_debug_starts() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	for name: String in ["mt_moon_weak", "mt_moon_fossil", "moon_stone_qa"]:
		var start := DebugStart.new()
		assert_true(start.load_file(STARTS + name + ".json", data, items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_true(MapCatalog.has_map(start.map), name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
		map.free()
	var qa := DebugStart.new()
	qa.load_file(STARTS + "moon_stone_qa.json", data, items)
	var state := GameState
	qa.apply(state, data)
	assert_eq(state.bag.count_of(&"moon_stone"), 2, "deux Pierres Lune")
	var compatible: Array[StringName] = []
	for i: int in state.party.size():
		var pokemon := state.party.get_at(i)
		if StoneUse.check(pokemon, &"moon_stone", data) == StoneUse.Check.COMPATIBLE:
			compatible.append(pokemon.species_id)
	assert_eq(compatible, [&"nidorina", &"nidorino", &"clefairy", &"jigglypuff"]
		as Array[StringName], "quatre compatibles, Reptincel et Nosferapti non")
