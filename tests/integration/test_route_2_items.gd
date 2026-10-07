extends GutTest
## Objets de la Route 2 (jalon 8 T7, jalon-08.md §2.3, §2.4) avec la vraie scène Boot, une
## sauvegarde en mémoire et le départ de débogage `route_2` : la Poké Ball du sol (verbe
## PRENDRE : Sac + 1, journal des objets trouvés, drapeau, PNJ retiré tout de suite et au
## rechargement, toast) et l'objet caché (narration puis toast, une seule fois).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_2.json"
const SAVE_PATH := "user://test_route_2_items_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
## Poké Ball O1 (10, 53), prise depuis la case à l'est (hautes herbes), tourné vers l'ouest.
const BALL_CELL := Vector2i(10, 53)
const BALL_FROM := Vector2i(11, 53)
## O3 caché (13, 42), approché depuis le sud.
const HIDDEN_CELL := Vector2i(13, 42)
const HIDDEN_FROM := Vector2i(13, 43)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-07T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur la Route 2 ; [param fresh] applique le départ de débogage (sinon : la partie en
## cours, relue de la sauvegarde en mémoire comme un rechargement).
func _start(cell: Vector2i, facing: Vector2i, fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_2"
	_boot.start_spawn = &"from_viridian_c"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if fresh:
		var start := DebugStart.new()
		assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(start.get_errors()))
		start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_events.append("toast")
			_toasts.append(PackedStringArray([title, detail])))
	_runner.page_started.connect(func(_index: int) -> void: _events.append("page"))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


## Déroule la scène en cours : avance les pages jusqu'à la fin de la scène et du dialogue.
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


func _bag_count(item: StringName) -> int:
	return GameState.bag.count_of(item)


func _found(item: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == "route_2":
			count += 1
	return count


func test_taking_the_ball_adds_it_to_the_bag_once_and_removes_the_object() -> void:
	await _start(BALL_FROM, Vector2i.LEFT, true)
	var map := _boot.get_map()
	var ball := map.get_npc(&"route_2_ball_1")
	assert_not_null(ball, "la Ball est au sol")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible d'interaction")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := _bag_count(&"poke_ball")
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(&"route_2_ball_1") == null, TIMEOUT)
	assert_null(map.get_npc(&"route_2_ball_1"), "objet retiré tout de suite")
	assert_false(map.get_grid().is_occupied(BALL_CELL), "case libérée")
	await _finish_scene()
	assert_eq(_bag_count(&"poke_ball"), before + 1, "Sac + 1")
	assert_eq(_found("poke_ball"), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(&"got_route_2_item_1"), "drapeau")
	assert_eq(_toasts.size(), 1, "un seul toast")
	if _toasts.size() == 1:
		assert_eq(_toasts[0], PackedStringArray(["Poké Ball ×1", "Ajoutée au Sac"]))
	assert_eq(_events.count("page"), 0, "aucune bulle avant le toast")
	assert_push_error_count(0)


func test_the_ball_is_still_gone_after_a_reload() -> void:
	await _start(BALL_FROM, Vector2i.LEFT, true)
	await _press_interact()
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"got_route_2_item_1"),
		TIMEOUT)
	await _finish_scene()
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := _bag_count(&"poke_ball")
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(BALL_FROM, Vector2i.LEFT, false)
	assert_null(_boot.get_map().get_npc(&"route_2_ball_1"), "absente au rechargement")
	assert_false(_boot.get_map().get_grid().is_occupied(BALL_CELL))
	assert_eq(_bag_count(&"poke_ball"), bag_after, "Sac inchangé")
	assert_eq(_found("poke_ball"), 1)


func test_the_hidden_item_gives_narration_then_toast_once() -> void:
	await _start(HIDDEN_FROM, Vector2i.UP, true)
	var before := _bag_count(&"poke_ball")
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell() == HIDDEN_CELL, TIMEOUT)
	Input.action_release(&"move_up")
	await _finish_scene()
	assert_eq(_events, ["page", "toast"] as Array[String], "narration puis toast")
	assert_eq(_bag_count(&"poke_ball"), before + 1)
	assert_eq(_found("poke_ball"), 1)
	assert_true(GameState.flags.has_flag(&"got_route_2_item_3"))
	assert_eq(_toasts.size(), 1)
	# On repasse sur la case : rien.
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == HIDDEN_FROM, TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell() == HIDDEN_CELL, TIMEOUT)
	Input.action_release(&"move_up")
	await wait_process_frames(20)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène la seconde fois")
	assert_eq(_events, ["page", "toast"] as Array[String], "rien de nouveau")
	assert_eq(_bag_count(&"poke_ball"), before + 1)
	assert_eq(_found("poke_ball"), 1)
