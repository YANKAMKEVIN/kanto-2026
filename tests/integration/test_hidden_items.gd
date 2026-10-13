extends GutTest
## Objets cachés « face à un indice » (jalon 12 T18, jalon-12.md §1.3 n° 1, §2.8 ; dossier 15
## §12, Q-2) sur la **vraie scène Boot**, la vraie carte et une sauvegarde en mémoire :
## - face à l'indice → cible EXAMINER (le bouton apparaît) ; de dos ou de côté → rien ;
## - EXAMINER → toast standard seul (« Réveil ×1 » / « Ajouté au Sac »), aucune bulle, Sac + 1,
##   journal des objets trouvés, drapeau `got_<id>` ;
## - ensuite plus de cible, même après un rechargement de la partie.
## Caches : Route 3 (T18). Le 1F et le B2F s'ajoutent au T21 / T25 ([constant CACHES]).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_hidden_items_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
## [carte, départ de débogage, spawn, identifiant de la cache, case de l'indice, objet, toast].
const CACHES: Array = [
	[&"route_3", "res://tools/debug_start/route_3.json", &"from_pewter_c", "route_3_hidden_1",
		Vector2i(36, 18), &"awakening", ["Réveil ×1", "Ajouté au Sac"]],
]
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _events: Array[String] = []
var _toasts: Array[PackedStringArray] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T15:00:00")
	_fs = MemoryFs.new()
	_events.clear()
	_toasts.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


## Boot sur [param cache], le joueur posé sur [param cell] tourné vers [param facing] ;
## [param fresh] applique le départ de débogage (sinon : la partie relue de la sauvegarde).
func _start(cache: Array, cell: Vector2i, facing: Vector2i, fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = cache[0]
	_boot.start_spawn = cache[2]
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(cache[1], _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void: _events.append("page"))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _target() -> Interaction:
	return _boot.get_interaction_controller().get_target()


func _found(cache: Array) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == String(cache[5]) and entry["map"] == String(cache[0]):
			count += 1
	return count


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


func _check_cache(cache: Array) -> void:
	var clue: Vector2i = cache[4]
	var flag := StringName("got_" + cache[3])
	await _start(cache, clue + Vector2i.DOWN, Vector2i.DOWN, true)
	var grid := _boot.get_map().get_grid()
	assert_true(grid.is_solid(clue), "l'indice est bloqué")
	assert_null(_target(), "de dos : rien")
	for side: Vector2i in SIDES:
		var from := clue + side
		assert_false(grid.is_solid(from), "%s praticable" % from)
		_boot.get_map().spawn_player_at(_player, from, Vector2i.UP if side.y == 0 else
			Vector2i.LEFT)
		await wait_process_frames(3)
		assert_null(_target(), "depuis %s, de côté : rien" % from)
		_boot.get_map().spawn_player_at(_player, from, -side)
		await wait_process_frames(3)
		var target := _target()
		assert_not_null(target, "face à l'indice depuis %s : une cible" % from)
		if target != null:
			assert_eq(target.kind, Interaction.Kind.EXAMINE, "verbe EXAMINER")
	var before := GameState.bag.count_of(cache[5])
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return GameState.flags.has_flag(flag), TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(cache[5]), before + 1, "Sac + 1")
	assert_eq(_found(cache), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(flag), "drapeau %s" % flag)
	assert_eq(_events, ["toast"] as Array[String], "toast seul, aucune bulle")
	assert_eq(_toasts, [PackedStringArray(cache[6])] as Array[PackedStringArray])
	assert_null(_target(), "plus de cible une fois trouvé")
	# Rechargement : toujours rien face à l'indice, le Sac ne bouge pas.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(cache[5])
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(cache, clue + SIDES[0], -SIDES[0], false)
	assert_true(GameState.flags.has_flag(flag), "drapeau relu")
	assert_null(_target(), "rechargé : plus de cible")
	assert_eq(GameState.bag.count_of(cache[5]), bag_after)
	assert_eq(_found(cache), 1)
	assert_push_error_count(0)


func test_route_3_awakening_behind_the_pebble() -> void:
	await _check_cache(CACHES[0])
