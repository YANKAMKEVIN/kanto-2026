extends GutTest
## Jalon 22 sur la vraie scène Boot : Bon de Commande (Fan Club de Carmin, choix), échange de la
## Bicyclette (Azuria), Canne (pêcheur de Carmin), Méga Canne (Route 12 sud), garde de la Piste
## (refus et recul sans vélo ; salut une fois, sortie en selle côté Piste), pêche au ponton.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_j22_story_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T15:00:00")
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_left", &"move_right", &"move_up",
			&"move_down"]:
		Input.action_release(action)


func _start(map: StringName, spawn: StringName, flags: Array = [], items: Array = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	for flag: StringName in [&"starter_chosen"] + flags:
		GameState.flags.set_flag(flag)
	for item: StringName in items:
		(GameState.bag as Bag).add(item)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Fait défiler dialogues et scènes ; [param answer] à un choix.
func _finish(answer: bool = true) -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Se place à côté du PNJ [param npc_id], tourné vers lui, et lui parle.
func _talk_to(npc_id: StringName, answer: bool = true) -> void:
	_pages.clear()
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, String(npc_id))
	if npc == null:
		return
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _finish(answer)


## Fait un pas vers [param direction] (puis attend la fin des scènes déclenchées).
func _step(direction: StringName) -> void:
	var before := _player.get_cell()
	Input.action_press(direction)
	await wait_until(func() -> bool: return _player.get_cell() != before \
		or _boot.get_cutscene_director().is_running(), 3.0)
	Input.action_release(direction)
	await wait_until(func() -> bool: return not _player.is_moving(), 3.0)
	await _finish()


func test_no_then_yes_gives_the_voucher_once() -> void:
	await _start(&"vermilion_fan_club", &"entrance")
	await _talk_to(&"chairman", false)
	assert_has(_pages, "Oh… Une autre fois, alors.")
	assert_false((GameState.bag as Bag).has(&"bike_voucher"), "NON : rien")
	await _talk_to(&"chairman", true)
	assert_eq((GameState.bag as Bag).count_of(&"bike_voucher"), 1)
	assert_true(GameState.flags.has_flag(&"got_bike_voucher"))
	assert_has(_pages, "Kevin reçoit un Bon de Commande !")
	await _talk_to(&"chairman", true)
	assert_eq(_pages, ["Mon Ponyta te passe le bonjour !"] as Array[String])
	assert_eq((GameState.bag as Bag).count_of(&"bike_voucher"), 1, "une seule fois")


func test_the_bike_shop_trades_the_voucher_for_the_bicycle() -> void:
	await _start(&"cerulean_bike_shop", &"entrance", [], [&"bike_voucher"])
	await _talk_to(&"vendor")
	assert_true((GameState.bag as Bag).has(&"bicycle"))
	assert_false((GameState.bag as Bag).has(&"bike_voucher"), "le Bon quitte le Sac")
	assert_true(GameState.flags.has_flag(&"got_bicycle"))
	assert_has(_pages, "Kevin échange le Bon contre une Bicyclette !")
	await _talk_to(&"vendor")
	assert_eq(_pages, ["Alors, cette Bicyclette ?\nElle roule bien, hein ?"] as Array[String])
	assert_eq((GameState.bag as Bag).count_of(&"bicycle"), 1)


func test_without_the_voucher_the_clerk_is_unchanged() -> void:
	await _start(&"cerulean_bike_shop", &"entrance")
	await _talk_to(&"vendor")
	assert_eq(_pages.back(), "…Reviens quand tu veux. Pour regarder.")
	assert_false((GameState.bag as Bag).has(&"bicycle"))


func test_the_three_rods() -> void:
	await _start(&"vermilion_fisher_house", &"entrance")
	await _talk_to(&"fisher")
	assert_true((GameState.bag as Bag).has(&"old_rod"), "Canne")
	assert_true(GameState.flags.has_flag(&"got_old_rod"))
	await _talk_to(&"fisher")
	assert_eq(_pages, ["Alors, ça mord ?"] as Array[String])
	_boot.queue_free()
	await wait_process_frames(2)
	await _start(&"route_12_rod_house", &"entrance")
	await _talk_to(&"fisher")
	assert_true((GameState.bag as Bag).has(&"super_rod"), "Méga Canne")
	await _talk_to(&"fisher")
	assert_eq(_pages, ["Mes frères pêchent à Carmin\net à Parmanie. Tu les as vus ?"]
		as Array[String])
	_boot.queue_free()
	await wait_process_frames(2)
	await _start(&"fuchsia_good_rod_house", &"entrance")
	await _talk_to(&"fisher")
	assert_true((GameState.bag as Bag).has(&"good_rod"), "Super Canne")
	assert_true(GameState.flags.has_flag(&"got_good_rod"))


func test_the_gate_guard_refuses_without_a_bicycle() -> void:
	await _start(&"route_16_gate", &"entrance_bas_est")
	for i: int in 4:
		await _step(&"move_left")
	assert_has(_pages, "Désolé ! La Piste Cyclable\nest réservée aux vélos.")
	assert_eq(_player.get_cell().x, 7, "recul d'une case")


func test_with_a_bicycle_the_guard_greets_once_and_the_road_mounts_the_player() -> void:
	await _start(&"route_16_gate", &"entrance_bas_est", [&"got_bicycle"], [&"bicycle"])
	for i: int in 4:
		await _step(&"move_left")
	assert_has(_pages, "La Piste descend jusqu'à Parmanie.\nBonne route, et gare aux Motards !")
	assert_true(GameState.flags.has_flag(&"cycling_gate_16_greeted"))
	assert_lt(_player.get_cell().x, 7, "passage libre")
	while _player.get_cell().x > 2:
		await _step(&"move_left")
	await _step(&"move_down")
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"route_16_west", TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning() \
		and _boot.is_stable(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"route_16_west")
	assert_true(_boot.get_map().is_cycling_road_at(_player.get_cell()), "sur la Piste")
	assert_eq(_player.get_mount(), Mount.Kind.BIKE, "monté d'office")
	assert_true(_boot.get_mount_director().is_bike_blocked(), "descente refusée (bouton grisé)")


func test_fishing_on_the_route_12_pier_offers_fish() -> void:
	await _start(&"route_12_south", &"from_route_12", [], [&"old_rod"])
	var map := _boot.get_map()
	# Ponton (25..26, 0..13), eau pêchable en x 24 et 27.
	map.spawn_player_at(_player, Vector2i(25, 5), Vector2i.LEFT)
	await wait_process_frames(3)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target)
	if target != null:
		assert_eq(target.kind, Interaction.Kind.FISH, "PÊCHER face à l'eau")
		assert_eq(target.cell, Vector2i(24, 5))


func test_route_17_slope_drifts_down_without_input() -> void:
	await _start(&"route_17", &"from_route_16", [&"got_bicycle"], [&"bicycle"])
	# La Bicyclette arrive au Sac après le chargement de la carte : arrivée rejouée.
	_boot.get_mount_director().on_map_changed(_boot.get_map())
	assert_eq(_player.get_mount(), Mount.Kind.BIKE, "Piste : en selle d'office")
	# Place du départ plate (rangées 0..7) : on se pose au début de la pente ouest.
	_boot.get_map().spawn_player_at(_player, Vector2i(12, 9), Vector2i.DOWN)
	var start := _player.get_cell()
	await wait_until(func() -> bool: return _player.get_cell().y >= start.y + 3, 5.0)
	assert_gte(_player.get_cell().y, start.y + 3, "dérive vers le bas sans appui")
	assert_eq(_player.get_cell().x, start.x)


func test_the_fly_house_gives_hm02_once() -> void:
	await _start(&"route_16_fly_house", &"entrance")
	await _talk_to(&"girl")
	assert_true((GameState.bag as Bag).has(&"hm02"), "CS02")
	assert_has(_pages, "Kevin reçoit la CS02 — Vol !")
	await _talk_to(&"girl")
	assert_eq((GameState.bag as Bag).count_of(&"hm02"), 1, "une fois")
