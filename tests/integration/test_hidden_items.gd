extends GutTest
## Objets cachés « face à un indice » (jalon 12 T18, jalon-12.md §1.3 n° 1, §2.8 ; dossier 15
## §12, Q-2) sur la **vraie scène Boot**, la vraie carte et une sauvegarde en mémoire :
## - face à l'indice → cible EXAMINER (le bouton apparaît) ; de dos ou de côté → rien ;
## - EXAMINER → toast standard seul (« Réveil ×1 » / « Ajouté au Sac »), aucune bulle, Sac + 1,
##   journal des objets trouvés, drapeau `got_<id>` ;
## - ensuite plus de cible, même après un rechargement de la partie.
## Caches : Route 3 (T18), Route 24 nord (T22, Antidote), souterrain (J15 T19, Guérison), Route 5 (J15 T13, Antidote du tronc), Route 6 (J15 T14/T15, Super Potion des joncs), J20 T17 : Rappel de la Route 8, Pépite et Super Potion du souterrain 7-8, Rappel de Céladopole ([constant CACHES]).

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
	[&"route_24", "res://tools/debug_start/route_24_north.json", &"north_land",
		"route_24_antidote", Vector2i(16, 6), &"antidote", ["Antidote ×1", "Ajouté au Sac"]],
	# Jalon 15 (T19) : la Guérison du souterrain, seule cache avec une phrase (T-19, en page
	# avant le toast).
	[&"underground_path", "res://tools/debug_start/underground_path.json", &"from_route_5_w",
		"underground_hidden_1", Vector2i(11, 9), &"full_restore",
		["Guérison ×1", "Ajoutée au Sac"], ["page", "toast"]],
	[&"route_5", "res://tools/debug_start/route_5.json", &"from_cerulean_c", "route_5_hidden_1",
		Vector2i(16, 31), &"antidote", ["Antidote ×1", "Ajouté au Sac"]],
	# Jalon 15 (T14 / T15) : la Super Potion des joncs, rive ouest de l'étang de la Route 6.
	[&"route_6", "res://tools/debug_start/route_6.json", &"from_underground",
		"route_6_hidden_1", Vector2i(10, 32), &"super_potion",
		["Super Potion ×1", "Ajoutée au Sac"]],
	# Jalon 18 (T20) : la Super Potion entre les racines de l'antichambre de l'échelle B de la
	# Grotte Sombre (B1F) ; la paroi (40, 32) et le plafond bloquent : on la fouille de l'est
	# (42, 32) ou du sud (41, 33). [carte, départ, spawn, id, indice, objet, toast, pages, côtés]
	[&"dark_cave_b1f", "res://tools/debug_start/dark_cave_b1f.json", &"arrivee_a",
		"dark_cave_b1f_hidden_1", Vector2i(41, 32), &"super_potion",
		["Super Potion ×1", "Ajoutée au Sac"], ["toast"], [Vector2i.RIGHT, Vector2i.DOWN]],
	# Jalon 20 (T17) : le Rappel de la Route 8 (pierre d'une autre teinte sous la terrasse, la
	# corniche au sud : on la fouille de l'ouest, de l'est ou du nord), la Pépite de la niche et la
	# Super Potion du coude du souterrain (carrelage fissuré, murs au nord), le Rappel de la ruelle
	# sombre de Céladopole (poubelle ; mur à l'ouest, bac au nord). Toast seul, comme la Route 3.
	[&"route_8", "res://tools/debug_start/route_8.json", &"from_lavender_c", "route_8_hidden_1",
		Vector2i(43, 9), &"revive", ["Rappel ×1", "Ajouté au Sac"], ["toast"],
		[Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]],
	[&"underground_path_7_8", "res://tools/debug_start/underground_7_8.json",
		&"from_route_7_n", "souterrain_hidden_1", Vector2i(15, 2), &"nugget",
		["Pépite ×1", "Ajoutée au Sac"], ["toast"], [Vector2i.DOWN]],
	[&"underground_path_7_8", "res://tools/debug_start/underground_7_8.json",
		&"from_route_7_n", "souterrain_hidden_2", Vector2i(34, 1), &"super_potion",
		["Super Potion ×1", "Ajoutée au Sac"], ["toast"], [Vector2i.LEFT, Vector2i.DOWN]],
	[&"celadon_city", "res://tools/debug_start/celadon.json", &"from_route_7_c",
		"celadon_hidden_1", Vector2i(46, 27), &"pp_up", ["PP Plus ×1", "Ajouté au Sac"],
		["toast"], [Vector2i.RIGHT, Vector2i.DOWN]],
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
	# Grotte obscure : l'avertissement d'entrée (T-3) s'ouvre ; on le ferme avant de fouiller.
	var box := _boot.get_dialogue_box()
	for i: int in 20:
		if not _runner.is_running():
			break
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(2)
	_events.clear()
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
	for side: Vector2i in (cache[8] if cache.size() > 8 else SIDES):
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
	var expected_events: Array[String] = ["toast"]
	if cache.size() > 7:
		expected_events.assign(cache[7])
	assert_eq(_events, expected_events, "toast seul (T-19 : une page avant le toast)")
	assert_eq(_toasts, [PackedStringArray(cache[6])] as Array[PackedStringArray])
	assert_null(_target(), "plus de cible une fois trouvé")
	# Rechargement : toujours rien face à l'indice, le Sac ne bouge pas.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := GameState.bag.count_of(cache[5])
	_boot.queue_free()
	await wait_process_frames(3)
	var first: Vector2i = cache[8][0] if cache.size() > 8 else SIDES[0]
	await _start(cache, clue + first, -first, false)
	assert_true(GameState.flags.has_flag(flag), "drapeau relu")
	assert_null(_target(), "rechargé : plus de cible")
	assert_eq(GameState.bag.count_of(cache[5]), bag_after)
	assert_eq(_found(cache), 1)
	assert_push_error_count(0)


func test_route_3_awakening_behind_the_pebble() -> void:
	await _check_cache(CACHES[0])


func test_route_24_antidote_behind_the_stump() -> void:
	await _check_cache(CACHES[1])


func test_underground_full_restore_behind_the_loose_stone() -> void:
	await _check_cache(CACHES[2])


func test_route_5_antidote_behind_the_trunk() -> void:
	await _check_cache(CACHES[3])


func test_route_6_super_potion_behind_the_rushes() -> void:
	await _check_cache(CACHES[4])


func test_dark_cave_b1f_super_potion_between_the_roots() -> void:
	await _check_cache(CACHES[5])


func test_route_8_revive_behind_the_pebble() -> void:
	await _check_cache(CACHES[6])


func test_underground_7_8_nugget_in_the_cracked_tile_of_the_niche() -> void:
	await _check_cache(CACHES[7])


func test_underground_7_8_super_potion_at_the_end_of_the_bend() -> void:
	await _check_cache(CACHES[8])


func test_celadon_revive_in_the_dark_alley_bin() -> void:
	await _check_cache(CACHES[9])
