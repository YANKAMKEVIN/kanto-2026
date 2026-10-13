extends GutTest
## La vie d'Azuria (jalon 13 T17, jalon-13.md §2.4, §2.5, §2.16 ; dossier 16 §4.4, §5, §6, §18, §21) avec
## la vraie scène Boot et les vraies cartes :
## - arrivée par l'ouest : drapeau `cerulean_reached`, objectif « obtenir le Badge Cascade. »,
##   Grand moment « Arrivée à Azuria », ni dialogue, une seule fois ;
## - les sept habitants à leur case de la grille, leurs répliques (textes 7 à 11, 14 à 17) ; la
##   voisine garde la mémoire de sa première parole, seule la Nageuse réagit au badge ;
## - indices du cambriolage : porte (« Un ruban interdit l'entrée. »), clôture arrachée, rien
##   d'autre (aucun marqueur, aucun objectif) ; sorties fermées sans warp ;
## - maison ouverte et magasin de vélos (trois pages, aucun achat) ; panneaux ;
## - Centre : point de repos.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PLAN_PATH := "res://tools/plans/azuria.txt"
const SAVE_NAME := "test_cerulean_life"
const FADE := 0.05
const TIMEOUT := 14.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T14:03:05")
	_fs = MemoryFs.new()
	_pages.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map_id] (départ de débogage [param start], drapeaux en plus [param flags]),
## joueur posé sur [param cell].
func _start(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i,
		start: String, flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	if not start.is_empty():
		var debug_start := DebugStart.new()
		assert_true(debug_start.load_file("res://tools/debug_start/%s.json" % start,
			_boot.get_pokemon_data(), _boot.get_item_library()),
			"\n".join(debug_start.get_errors()))
		debug_start.apply(GameState, _boot.get_pokemon_data())
		for flag: StringName in flags:
			GameState.flags.set_flag(flag)
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	await wait_process_frames(3)
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


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action := _action(direction)
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


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
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


## Examine ce que fait face à [param facing] depuis [param cell] ; renvoie les pages dites.
func _examine(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i,
		start: String = "cerulean_city") -> Array[String]:
	_pages.clear()
	await _start(map_id, spawn, cell, facing, start)
	await _press_interact()
	await wait_process_frames(4)
	if _runner.is_running():
		await _finish_scene()
	var said := _pages.duplicate()
	_boot.queue_free()
	await wait_process_frames(3)
	return said


## Première page dite par [param npc_id] (partie « cerulean_city » + [param flags]).
func _says(map_id: StringName, spawn: StringName, cell: Vector2i, npc_id: StringName,
		flags: Array[StringName] = []) -> Array[String]:
	_pages.clear()
	await _start(map_id, spawn, cell, Vector2i.UP, "cerulean_city", flags)
	await _talk_to(npc_id)
	var said := _pages.duplicate()
	_boot.queue_free()
	await wait_process_frames(3)
	return said

const CITY := &"cerulean_city"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")


# --- Arrivée ------------------------------------------------------------------------------------

func test_arrival_raises_the_flag_sets_the_objective_and_records_the_moment_once() -> void:
	await _start(&"route_4", &"from_cerulean_c", Vector2i(62, 20), Vector2i.RIGHT, "route_4")
	assert_false(GameState.flags.has_flag(&"cerulean_reached"))
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	assert_eq(objectives.current(GameState.flags), "continuer vers la Route 3.", "avant Azuria")
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return _boot.get_map().map_id == CITY, TIMEOUT)
	Input.action_release(&"move_right")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell().x, 0, "posé sur le raccord ouest d'Azuria")
	await _walk(Vector2i.RIGHT, Vector2i(1, _player.get_cell().y))
	await wait_process_frames(10)
	assert_true(GameState.flags.has_flag(&"cerulean_reached"), "drapeau posé en silence")
	assert_eq(_scenes, [&"cerulean_arrival"] as Array[StringName])
	assert_eq(_pages, [] as Array[String], "ni dialogue")
	assert_eq(objectives.current(GameState.flags), "obtenir le Badge Cascade.")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(CITY), CITY)
	var arrivals := TrainerSummary.first_arrivals(GameState.discovered_maps, zones)
	assert_true(arrivals.has(CITY), "zone Azuria découverte (Grand moment d'arrivée)")
	var moments := MomentLibrary.new()
	assert_true(moments.load_file())
	assert_eq(moments.get_zone_text(CITY).title, "Arrivée à Azuria")
	assert_eq(moments.get_zone_text(CITY).detail, "Une ville d'eau et de lumière.")
	assert_eq(_boot.get_map().display_name, "Azuria", "titre de zone")
	assert_eq(_boot.get_map().region, "La ville aux eaux claires")
	await _walk(Vector2i.LEFT, Vector2i(0, _player.get_cell().y))
	await _walk(Vector2i.RIGHT, Vector2i(1, _player.get_cell().y))
	await wait_process_frames(10)
	assert_eq(_scenes, [&"cerulean_arrival"] as Array[StringName], "une seule fois")
	assert_push_error_count(0)


func test_each_entrance_row_triggers_the_arrival() -> void:
	for y: int in [19, 21]:
		_scenes.clear()
		await _start(CITY, &"from_route_4_c", Vector2i(0, y), Vector2i.RIGHT, "cerulean_city",
			[])
		GameState.flags.set_flag(&"cerulean_reached", false)
		await _walk(Vector2i.RIGHT, Vector2i(1, y))
		await wait_process_frames(10)
		assert_true(GameState.flags.has_flag(&"cerulean_reached"), "arrivée par la rangée %d" % y)
		_boot.queue_free()
		await wait_process_frames(3)


func test_arriving_from_the_north_raises_the_flag_too() -> void:
	await _start(CITY, &"from_route_24_c", Vector2i(32, 0), Vector2i.DOWN, "cerulean_city")
	GameState.flags.set_flag(&"cerulean_reached", false)
	await _walk(Vector2i.DOWN, Vector2i(32, 1))
	await wait_process_frames(10)
	assert_true(GameState.flags.has_flag(&"cerulean_reached"))


# --- Habitants ------------------------------------------------------------------------------------

func test_the_seven_residents_stand_on_their_planned_cells() -> void:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(PLAN_PATH), plan.error)
	await _start(CITY, &"from_route_4_c", Vector2i(2, 20), Vector2i.RIGHT, "cerulean_city")
	var map := _boot.get_map()
	var expected := {
		&"h1_fisher": "h1_pecheur", &"h2_kid": "h2_enfant", &"h3_neighbor": "h3_voisine",
		&"h4_policeman": "h4_policier", &"h5_swimmer": "h5_nageuse",
		&"h6_trainer": "h6_dresseur", &"h7_resident": "h7_habitant",
	}
	for npc_id: StringName in expected:
		var npc := map.get_npc(npc_id)
		assert_not_null(npc, "%s posé" % npc_id)
		if npc != null:
			assert_eq(npc.get_cell(), plan.cell_of(expected[npc_id]), "%s à sa case" % npc_id)
	assert_eq(map.get_npcs().size(), 7, "ni plus ni moins (Clara, rival, Ondine : ailleurs)")


func test_residents_say_the_validated_lines() -> void:
	var cases := [
		[&"h1_fisher", Vector2i(24, 14),
			["Pas de canne aujourd'hui.", "Je viens juste regarder l'eau. Ça suffit parfois."]],
		[&"h2_kid", Vector2i(31, 17), ["Il y a des Pokémon sous le pont !", "…Je crois."]],
		[&"h4_policeman", Vector2i(12, 10), ["Circulez. L'enquête est en cours."]],
		[&"h6_trainer", Vector2i(36, 22), ["Le Pont Pépite, au nord ? Cinq Dresseurs à la suite.",
			"Je me suis arrêté au troisième."]],
		[&"h7_resident", Vector2i(50, 22), ["On ne passe pas par là pour l'instant."]],
	]
	for entry: Array in cases:
		var said: Array[String] = await _says(CITY, &"from_route_4_c", entry[1], entry[0])
		assert_eq(said, entry[2] as Array[String], String(entry[0]))


func test_the_neighbor_remembers_what_she_already_said() -> void:
	await _start(CITY, &"from_route_4_c", Vector2i(22, 10), Vector2i.LEFT, "cerulean_city")
	assert_false(GameState.flags.has_flag(&"cerulean_neighbor_talked"))
	await _talk_to(&"h3_neighbor")
	await _talk_to(&"h3_neighbor")
	assert_eq(_pages, ["Ils sont entrés chez mon voisin en pleine nuit.",
		"Le matin, on a vu un homme en noir partir par l'arrière.",
		"Ici, on ne fermait jamais nos portes."] as Array[String])
	assert_true(GameState.flags.has_flag(&"cerulean_neighbor_talked"))
	for text: String in _pages:
		assert_false(text.contains("Rocket") or text.contains("Team"), "aucun nom (dossier 16 §6)")


func test_only_the_swimmer_and_the_guide_react_to_the_badge() -> void:
	var none: Array[StringName] = []
	var badge: Array[StringName] = [&"badge_cascade"]
	var before: Array[String] = await _says(CITY, &"from_route_4_c", Vector2i(37, 12),
		&"h5_swimmer", none)
	assert_eq(before, ["Je m'entraîne à l'Arène tous les matins.",
		"Ondine ? Elle n'est jamais là quand il y a des défis sur le pont."] as Array[String])
	var after: Array[String] = await _says(CITY, &"from_route_4_c", Vector2i(37, 12),
		&"h5_swimmer", badge)
	assert_eq(after, ["Le Badge Cascade !", "Ondine ne le donne pas à n'importe qui."]
		as Array[String])
	var aware: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogues/cerulean_city.json"))
	for id: String in data:
		for variant: Variant in (data[id] as Dictionary).get("variants", []):
			if ((variant as Dictionary).get("if", []) as Array).has("badge_cascade") \
					and not aware.has(id):
				aware.append(id)
	aware.sort()
	assert_eq(aware, ["cerulean_gym_guide", "cerulean_gym_misty", "cerulean_h5_swimmer"]
		as Array[String], "arbitrage 6 du dossier 12 : ne réagit que ce qui peut le savoir (+ Ondine, T19)")


# --- Cambriolage, sorties fermées, panneaux ------------------------------------------------------

func test_the_burgled_house_gives_two_clues_and_nothing_else() -> void:
	var door: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(10, 10),
		Vector2i.UP)
	assert_eq(door, ["Un ruban interdit l'entrée."] as Array[String], "porte fermée (n° 12)")
	var fence: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(5, 1),
		Vector2i.RIGHT)
	assert_eq(fence, ["La clôture a été arrachée."] as Array[String], "clôture (n° 13)")
	# Planche, pot, trou : décor seul, aucun texte ; aucune porte (aucun warp) ; rien au tableau.
	await _start(CITY, &"from_route_4_c", Vector2i(10, 10), Vector2i.UP, "cerulean_city")
	var map := _boot.get_map()
	for cell: Vector2i in [Vector2i(9, 2), Vector2i(14, 3)]:
		assert_eq(map.get_interactions().get_at(cell).size(), 0, "%s : décor seul" % cell)
	for warp: Warp in map.get_warps().get_all():
		assert_ne(warp.cell, Vector2i(10, 9), "la porte de la maison cambriolée n'est pas un warp")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	for id: StringName in objectives.get_ids():
		assert_false(String(id).contains("burgl") or String(id).contains("theft"),
			"aucun objectif du cambriolage (dossier 16 §6)")
	assert_eq(objectives.current(GameState.flags), "obtenir le Badge Cascade.")


func test_the_closed_exits_say_one_neutral_line_without_a_warp() -> void:
	var east: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(52, 23),
		Vector2i.RIGHT)
	assert_eq(east, ["On ne passe pas par là pour l'instant."] as Array[String])
	var south: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(32, 37),
		Vector2i.DOWN)
	assert_eq(south, ["On ne passe pas par là pour l'instant."] as Array[String])
	for text: String in east + south:
		assert_false(text.contains("Coupe") or text.contains("Route"), "aucune promesse")


func test_signs_read_their_validated_text() -> void:
	var town: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(3, 19), Vector2i.UP)
	assert_eq(town, ["AZURIA\nUne ville bordée d'eau, entre la montagne et le cap."]
		as Array[String], "n° 6")
	var gym: Array[String] = await _examine(CITY, &"from_route_4_c", Vector2i(38, 11), Vector2i.UP)
	assert_eq(gym, ["ARÈNE D'AZURIA\nChampionne : Ondine — La sirène au caractère bien trempé"]
		as Array[String], "n° 20")


# --- Maison ouverte, vélos, Centre --------------------------------------------------------------

func test_the_open_house_resident_talks_about_the_water() -> void:
	var said: Array[String] = await _says(&"cerulean_house", &"entrance", Vector2i(5, 6),
		&"resident")
	assert_eq(said, ["Toute l'eau d'Azuria descend du nord.",
		"Quand le soleil tape sur les canaux, la ville entière devient bleue."] as Array[String])


func test_the_bike_shop_clerk_sells_nothing() -> void:
	var said: Array[String] = await _says(&"cerulean_bike_shop", &"entrance", Vector2i(12, 6),
		&"vendor")
	assert_eq(said, ["Bienvenue ! Les meilleurs vélos de Kanto.", "Celui-ci ? 1 000 000 ₽.",
		"…Reviens quand tu veux. Pour regarder."] as Array[String])
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogues/cerulean_city.json"))
	assert_false((data["cerulean_bike_clerk"] as Dictionary).has("action"), "aucun mode Boutique")
	assert_false(FileAccess.file_exists("res://data/shops/cerulean_bike_shop.json"), "aucun achat")


func test_the_center_nurse_is_there_and_the_center_is_a_rest_point() -> void:
	await _start(&"cerulean_center", &"entrance", Vector2i(7, 5), Vector2i.UP, "cerulean_city")
	assert_not_null(_boot.get_map().get_npc(&"nurse"), "infirmière")
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	assert_not_null(points.get_point(&"cerulean_center"))
