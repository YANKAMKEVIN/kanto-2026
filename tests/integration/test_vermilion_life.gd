extends GutTest
## Carmin-sur-Mer jouée sur la vraie scène Boot (jalon 15 T15, jalon-15.md §2.7.8, §2.7.9, §2.9,
## §4 « 15B », §5 ; dossier 18 §15.3, T-25 à T-34, T-42) :
## - arrivée : `vermilion_reached` et l'objectif « explorer Carmin-sur-Mer. » ;
## - marin de la passerelle : T-26 **identique** sans puis avec le Passe Bateau, embarquement
##   inatteignable ; dockers T-27 / T-28 ;
## - jeune arbre : EXAMINER → T-29, la porte de l'Arène reste fermée ;
## - Fan Club : président T-33, membres T-34 et annexe A ;
## - Boutique : la Super Potion au stock, achetée 700 ₽.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_vermilion_life_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
const T26: Array[String] = ["Le S.S. Anne est à quai pour quelques jours.",
	"L'équipage prépare la croisière. L'embarquement n'a pas encore commencé."]
const T27 := "Ce paquebot fait le tour du monde. Les Dresseurs à bord viennent de partout."
const T28 := "On charge depuis l'aube. Des caisses, des malles… et des Pokémon de toutes les régions."
const T29 := "Un jeune arbre pousse devant l'entrée. Impossible de passer."
const T33: Array[String] = ["Tu aimes les Pokémon ? Alors écoute-moi parler de mon Ponyta !",
	"Sa crinière, sa démarche… un champion !",
	"Reviens quand tu veux, j'ai toujours une histoire à raconter !"]
const T34 := "Ici, on ne se bat pas. On se raconte nos Pokémon."
const A4_MEMBER := "Mon Miaouss adore qu'on parle de lui. Regarde comme il se tient droit !"
const TREE := Vector2i(49, 10)
const GYM_DOOR := Vector2i(49, 9)

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T16:00:00")
	_fs = MemoryFs.new()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map] / [param spawn], départ [param start] (`tools/debug_start/`), sauvegarde
## en mémoire vierge.
func _start(map: StringName, spawn: StringName, start: String = "vermilion") -> void:
	_fs = MemoryFs.new()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var debug_start := DebugStart.new()
	assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
		_boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(debug_start.get_errors()))
	debug_start.apply(GameState, _boot.get_pokemon_data())
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text().replace("\n", " ")))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


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
	assert_false(_runner.is_running(), "dialogue fini")
	await wait_process_frames(5)


## Parle à [param npc_id] depuis une case voisine libre (routines tenues) ; rend les pages dites.
func _talk_to(npc_id: StringName) -> Array[String]:
	_pages.clear()
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	if npc == null:
		return []
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	return _pages.duplicate()


func _objective() -> String:
	return _boot.get_menu_director().build_dashboard().objective_text


func test_arrival_raises_the_flag_and_the_explore_objective() -> void:
	await _start(&"vermilion_city", &"from_route_6_c")
	assert_false(GameState.flags.has_flag(&"vermilion_reached"))
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"vermilion_reached"),
		TIMEOUT)
	Input.action_release(&"move_down")
	await _finish_scene()
	assert_eq(_objective(), "Objectif : explorer Carmin-sur-Mer.", "T-42")
	assert_push_error_count(0)


func test_sailor_says_t26_with_and_without_the_ticket_and_boarding_stays_closed() -> void:
	for start: String in ["vermilion", "vermilion_ss_ticket"]:
		await _start(&"vermilion_city", &"from_route_6_c", start)
		assert_eq(GameState.flags.has_flag(&"got_ss_ticket"), start != "vermilion", start)
		assert_eq(await _talk_to(&"sailor"), T26, "%s : T-26" % start)
		assert_eq(await _talk_to(&"docker_1"), [T27] as Array[String], "%s : T-27" % start)
		assert_eq(await _talk_to(&"docker_2"), [T28] as Array[String], "%s : T-28" % start)
		# Le marin tient la passerelle : la case derrière lui n'est jamais libre.
		var sailor := _boot.get_map().get_npc(&"sailor")
		assert_true(_boot.get_map().get_grid().is_occupied(sailor.get_cell()), "passerelle gardée")
		_boot.queue_free()
		await wait_process_frames(3)
	assert_push_error_count(0)


func test_examining_the_young_tree_says_t29_and_the_gym_stays_shut() -> void:
	await _start(&"vermilion_city", &"from_route_6_c")
	var map := _boot.get_map()
	assert_true(map.get_grid().is_occupied(TREE), "l'arbre occupe sa case")
	map.spawn_player_at(_player, TREE + Vector2i.DOWN, Vector2i.UP)
	await wait_process_frames(3)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, [T29] as Array[String], "T-29")
	assert_eq(_player.get_cell(), TREE + Vector2i.DOWN, "le joueur ne passe pas")
	assert_ne(map.get_grid().is_free(TREE), true, "toujours bloqué")
	assert_push_error_count(0)


func test_fan_club_chairman_and_members() -> void:
	await _start(&"vermilion_fan_club", &"entrance")
	assert_eq(await _talk_to(&"chairman"), T33, "T-33")
	assert_eq(await _talk_to(&"member_1"), [T34] as Array[String], "T-34")
	assert_eq(await _talk_to(&"member_2"), [A4_MEMBER] as Array[String], "annexe A.4")
	assert_push_error_count(0)


func test_the_mart_sells_super_potion_for_700() -> void:
	await _start(&"vermilion_mart", &"entrance")
	var shop := _boot.get_shop_library().get_shop(&"vermilion_mart")
	assert_not_null(shop, "Boutique de Carmin")
	if shop == null:
		return
	assert_true(ShopRules.stock(shop, GameState.flags).has(&"super_potion"), "au stock")
	var item := _boot.get_item_library().get_item(&"super_potion")
	GameState.money = 1000
	var before := GameState.bag.count_of(&"super_potion")
	assert_eq(ShopRules.buy(GameState, shop, item, 1), ShopRules.Status.OK)
	assert_eq(GameState.money, 300, "700 ₽")
	assert_eq(GameState.bag.count_of(&"super_potion"), before + 1)
	assert_ne(ShopRules.buy(GameState, shop, item, 1), ShopRules.Status.OK, "300 ₽ : refusé")
	assert_eq(GameState.money, 300, "refus sans effet")
