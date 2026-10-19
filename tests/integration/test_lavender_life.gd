extends GutTest
## La vie de Lavanville (jalon 18 T24, jalon-18.md §4.11, §4.13 ; dossier 21 §6, §12, §15.3) avec
## la vraie scène Boot et une sauvegarde en mémoire :
## - la légende de première arrivée (T-17) : une fois, jamais à un départ de débogage ni à une
##   seconde arrivée ; `lavender_reached` posé en silence au premier pas vers le sud, objectif
##   « visiter la Tour Pokémon. » ;
## - panneaux T-18 à T-20, habitants T-21 à T-24 ; Maison des Pokémon (enfant T-25 puis T-26,
##   Rondoudou et Nidoran femelle sans texte), maisons 1 et 2 (T-27, T-28) ;
## - Centre (point de repos) et Boutique (stock du dossier §6.4).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PLAN_PATH := "res://tools/plans/lavanville.txt"
const SAVE_NAME := "test_lavender_life"
const LEGEND := "La ville où reposent les souvenirs"
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


func _title() -> ZoneTitle:
	return _boot.get_hud().get_zone_title()


## Parle à [param npc_id] depuis une case voisine libre (routines tenues).
func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
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


# --- Légende de première arrivée ---------------------------------------------------------------

func test_the_legend_shows_on_the_first_arrival_from_route_10_and_never_again() -> void:
	await _start(&"route_10", &"from_dark_cave_s_w", "route_10_south", Vector2i(8, 48),
		Vector2i.DOWN)
	assert_false(GameState.discovered_maps.has(&"lavender_town"))
	await SceneRouter.change_map(&"lavender_town", &"from_route_10_c")
	assert_eq(_boot.get_map().map_id, &"lavender_town")
	assert_true(_title().is_showing())
	assert_eq(_title().get_zone_name_text(), "LAVANVILLE")
	assert_eq(_title().get_region_text(), LEGEND, "T-17 : au lieu de « Kanto »")
	assert_true(GameState.discovered_maps.has(&"lavender_town"), "découverte ensuite")
	await SceneRouter.change_map(&"route_10", &"from_lavender_c")
	await SceneRouter.change_map(&"lavender_town", &"from_route_10_c")
	assert_true(_title().is_showing())
	assert_eq(_title().get_region_text(), "Kanto", "seconde arrivée : plus de légende")


func test_a_debug_start_in_lavender_shows_no_legend() -> void:
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, &"lavender_town")
	assert_ne(_title().get_region_text(), LEGEND, "départ de débogage : jamais de légende")


func test_a_resumed_game_in_lavender_shows_no_legend() -> void:
	# Partie qui a quitté Lavanville avant de la « découvrir » (ancienne sauvegarde) : le Boot
	# démarre sans carte quittée, donc sans légende.
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN, false)
	assert_ne(_title().get_region_text(), LEGEND)


# --- Arrivée, objectif -------------------------------------------------------------------------

func test_the_first_step_south_raises_lavender_reached_in_silence_once() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	assert_eq(library.current_id(GameState.flags), &"reach_lavender")
	assert_false(GameState.flags.has_flag(&"lavender_reached"))
	await _walk(Vector2i.DOWN, Vector2i(22, 2))
	await wait_process_frames(10)
	assert_eq(_scenes, [&"lavender_reached"] as Array[StringName])
	assert_true(GameState.flags.has_flag(&"lavender_reached"))
	assert_eq(library.current(GameState.flags), "visiter la Tour Pokémon.")
	assert_eq(_pages.size(), 0, "silencieuse")
	assert_eq(_toasts.size(), 0)
	_scenes.clear()
	_boot.get_map().spawn_player_at(_player, Vector2i(22, 0), Vector2i.DOWN)
	await _walk(Vector2i.DOWN, Vector2i(22, 2))
	await wait_process_frames(10)
	assert_eq(_scenes.filter(func(id: StringName) -> bool: return id == &"lavender_reached").size(),
		0, "une seule fois")


func test_the_arrival_row_covers_the_three_columns_of_the_north_edge() -> void:
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	var cells: Array[Vector2i] = []
	for point: Node in _boot.get_map().get_node(^"Triggers").get_children():
		cells.append_array(point.call(&"get_cells"))
	cells.sort()
	assert_eq(cells, _plan.cells_at("legende_arrivee"))
	assert_eq(cells.size(), 3)


# --- Panneaux et habitants ---------------------------------------------------------------------

func test_the_three_signs_say_t18_to_t20() -> void:
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	var signs := [
		["panneau_ville", Vector2i.LEFT, "LAVANVILLE\nUne ville noble et paisible."],
		["panneau_tour", Vector2i.DOWN, "TOUR POKÉMON\nIci reposent les Pokémon aimés."],
		["panneau_fuji", Vector2i.DOWN, "MAISON DES POKÉMON\nCeux qui n'ont plus personne trouvent ici un foyer."],
	]
	for entry: Array in signs:
		var sign_cell := _plan.cell_of(entry[0])
		await _read_from(sign_cell + entry[1], -entry[1])
		assert_eq(_pages, [entry[2]] as Array[String], entry[0])


func test_the_scope_sign_spot_is_empty_for_j19() -> void:
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	var spot := _plan.cell_of("panneau_scope_j19")
	assert_eq(spot, Vector2i(42, 11))
	for interaction: Interaction in _boot.get_map().get_interactions().get_all():
		assert_ne(interaction.cell, spot, "rien d'examinable au J18")


func test_the_four_inhabitants_say_t21_to_t24() -> void:
	await _start(&"lavender_town", &"from_route_10", "lavender", Vector2i(22, 0),
		Vector2i.DOWN)
	var expected := {
		&"l1_fillette": ["Fillette", ["Ici, tout le monde parle doucement.\nMême les Pokémon !"]],
		&"l2_jeune_homme": ["Jeune homme", ["Mon premier Pokémon est là-haut.",
			"Je viens lui dire bonjour chaque\nfois que je passe."]],
		&"l3_passant": ["Passant", ["Lavanville, c'est petit. Mais les gens\nviennent de loin pour la Tour."]],
		&"l4_femme_bouquet": ["Habitante", ["Des fleurs blanches, comme d'habitude.\nIl les aimait bien."]],
	}
	for id: StringName in expected:
		await _talk_to(id)
		assert_eq(_pages, expected[id][1] as Array[String], String(id))
		assert_eq(_speakers[0], expected[id][0])
	assert_eq(_boot.get_map().get_npcs().size(), 4, "quatre habitants dehors")


# --- Intérieurs --------------------------------------------------------------------------------

func test_the_pokemon_house_kid_says_t25_then_t26() -> void:
	await _start(&"pokemon_house", &"entrance", "lavender", Vector2i(7, 8), Vector2i.UP)
	var map := _boot.get_map()
	for ambient: StringName in [&"rondoudou", &"nidoran_f"]:
		var npc := map.get_npc(ambient)
		assert_not_null(npc, "%s posé" % ambient)
		if npc != null:
			assert_true(npc.get_spec().dialogue.is_empty(), "%s : aucun texte" % ambient)
	assert_false(GameState.flags.has_flag(&"pokemon_house_kid_talked"))
	await _talk_to(&"enfant")
	assert_eq(_pages, ["Papy Fuji ? Il passe ses journées\nà la Tour.",
		"Il dit que quelqu'un doit veiller\nsur eux."] as Array[String], "T-25")
	assert_true(GameState.flags.has_flag(&"pokemon_house_kid_talked"))
	await _talk_to(&"enfant")
	assert_eq(_pages, ["Ces Pokémon n'avaient plus de Dresseur.\nMaintenant, ils nous ont nous."] \
		as Array[String], "T-26")
	await _talk_to(&"enfant")
	assert_eq(_pages.size(), 1, "T-26 ensuite, à chaque fois")
	assert_eq(_speakers[0], "Enfant")


func test_the_old_lady_says_t27() -> void:
	await _start(&"lavender_house_1", &"entrance", "lavender", Vector2i(7, 8), Vector2i.UP)
	await _talk_to(&"habitante")
	assert_eq(_pages, ["Mon Roucool chantait tous les matins\nà la fenêtre.",
		"Je laisse toujours la fenêtre\nouverte."] as Array[String], "T-27")


func test_the_couple_says_t28() -> void:
	await _start(&"lavender_house_2", &"entrance", "lavender", Vector2i(7, 8), Vector2i.UP)
	assert_eq(_boot.get_map().map_id, &"lavender_house_2")
	for id: StringName in [&"habitant_1", &"habitant_2"]:
		await _talk_to(id)
		assert_eq(_pages, ["On monte des fleurs à la Tour\nchaque semaine.",
			"Ça nous fait du bien, à nous aussi."] as Array[String], "T-28 %s" % id)


func test_the_center_is_a_rest_point_with_a_heal_machine() -> void:
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var point := points.get_point(&"lavender_center")
	assert_not_null(point, "point de repos de Lavanville")
	if point != null:
		assert_true(point.registers)
		assert_eq(point.wakeup_dialogue, &"nurse_wakeup")
	await _start(&"lavender_center", &"entrance", "lavender", Vector2i(7, 8), Vector2i.UP)
	var map := _boot.get_map()
	assert_not_null(map.get_node_or_null(^"%HealMachine"))
	assert_not_null(map.get_npc(&"nurse"), "l'infirmière")
	if point != null:
		assert_true(map.has_spawn(point.spawn))
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(" — ".join(points.registered_toast(zones.get_zone(&"lavender_town").name)),
		"Point de repos enregistré — Lavanville")


func test_the_mart_sells_the_validated_stock() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	var shop := shops.get_shop(&"lavender_mart")
	assert_not_null(shop)
	if shop != null:
		assert_eq(shop.item_ids(), [&"poke_ball", &"potion", &"super_potion", &"antidote",
			&"paralyze_heal", &"awakening", &"burn_heal", &"escape_rope"] as Array[StringName])
		for absent: StringName in [&"great_ball", &"revive", &"super_repel"]:
			assert_false(shop.item_ids().has(absent), "%s : reporté (dossier §6.4)" % absent)
	await _start(&"lavender_mart", &"entrance", "lavender", Vector2i(7, 8), Vector2i.UP)
	assert_not_null(_boot.get_map().get_npc(&"clerk"), "le vendeur")
