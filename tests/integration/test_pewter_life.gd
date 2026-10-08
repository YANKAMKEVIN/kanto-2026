extends GutTest
## La vie de la Route 2 nord et d'Argenta (jalon 10 T14, jalon-10.md §2.10 à §2.12 ; dossier 12
## §5, §6, arbitrages 6, 7, 10) avec la vraie scène Boot, les vraies cartes et une sauvegarde en
## mémoire :
## - arrivée : trois cases d'entrée, drapeau `pewter_arrived`, objectif « obtenir le Badge
##   Roche. », Grand moment « Arrivée à Argenta », ni dialogue ni caméra, une seule fois ;
## - garde de la Route 3 avant le badge : règle, recul, scène rejouée ; reparlé : réplique brève ;
## - Potion de la Route 2 nord : Sac + 1, journal des objets trouvés, drapeau, retrait ;
## - chercheuse : première fois puis ensuite ; réactions au badge seulement chez l'enfant, la
##   jeune Dresseuse, le guide d'Arène (et le Montagnard qui le remarque) ;
## - routines : le Montagnard et le tailleur bougent dans leur grille, le Racaillou reste
##   immobile et réagit, il n'a ni dialogue ni capture.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_pewter_life_save.json"
const FADE := 0.05
const TIMEOUT := 14.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Dialogues d'Argenta qui changent avec le badge, et seulement eux (arbitrage 6) ; Pierre
## lui-même (T17) change aussi.
const BADGE_AWARE: Array[String] = [
	"pewter_kid", "pewter_lass", "pewter_gym_guide", "route_2_north_mountaineer",
	"pewter_gym_brock",
]
const SPAWNS: Dictionary = {
	&"pewter_city": &"from_route_2_north_c", &"route_2_north": &"from_forest_gate",
}
const DIALOGUE_FILES: Array[String] = [
	"res://data/dialogues/pewter_city.json", "res://data/dialogues/pewter_houses.json",
	"res://data/dialogues/pewter_museum.json", "res://data/dialogues/pewter_gym.json",
	"res://data/dialogues/route_2_north.json",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-09T14:03:05")
	_fs = MemoryFs.new()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot sur [param map_id], joueur posé sur [param cell] ; [param start] : départ de débogage
## (sans lui : la partie relue de la sauvegarde en mémoire). [param flags] : drapeaux en plus.
func _start(map_id: StringName, cell: Vector2i, facing: Vector2i, start: String,
		flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = SPAWNS.get(map_id, &"entrance")
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
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
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


# --- Arrivée ------------------------------------------------------------------------------------

func test_arrival_raises_the_flag_sets_the_objective_and_records_the_moment_once() -> void:
	await _start(&"route_2_north", Vector2i(15, 1), Vector2i.UP, "route_2_north")
	assert_false(GameState.flags.has_flag(&"pewter_arrived"))
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file())
	assert_eq(objectives.current(GameState.flags), "continuer vers le nord.")
	# Raccord nord → Argenta (17..19, 43), puis la rue jusqu'aux cases d'arrivée (y 42).
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"pewter_city", TIMEOUT)
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	assert_eq(_player.get_cell().y, 43, "posé sur le raccord sud d'Argenta")
	await _walk(Vector2i.UP, Vector2i(_player.get_cell().x, 42))
	await wait_process_frames(10)
	assert_true(GameState.flags.has_flag(&"pewter_arrived"), "drapeau posé en silence")
	assert_eq(_scenes, [&"pewter_arrival"] as Array[StringName])
	assert_eq(_pages, [] as Array[String], "ni dialogue")
	assert_eq(objectives.current(GameState.flags), "obtenir le Badge Roche.")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var arrivals := TrainerSummary.first_arrivals(GameState.discovered_maps, zones)
	assert_true(arrivals.has(&"pewter_city"), "zone Argenta découverte (Grand moment d'arrivée)")
	var moments := MomentLibrary.new()
	assert_true(moments.load_file())
	assert_eq(moments.get_zone_text(&"pewter_city").title, "Arrivée à Argenta")
	# On revient puis on repasse : rien de plus.
	await _walk(Vector2i.DOWN, Vector2i(_player.get_cell().x, 43))
	await _walk(Vector2i.UP, Vector2i(_player.get_cell().x, 42))
	await wait_process_frames(10)
	assert_eq(_scenes, [&"pewter_arrival"] as Array[StringName], "une seule fois")
	assert_push_error_count(0)


func test_each_entrance_cell_triggers_the_arrival() -> void:
	for x: int in [17, 19]:
		_scenes.clear()
		await _start(&"pewter_city", Vector2i(x, 43), Vector2i.UP, "pewter")
		assert_false(GameState.flags.has_flag(&"pewter_arrived"))
		await _walk(Vector2i.UP, Vector2i(x, 42))
		await wait_process_frames(10)
		assert_true(GameState.flags.has_flag(&"pewter_arrived"), "arrivée par x = %d" % x)
		_boot.queue_free()
		await wait_process_frames(3)


# --- Garde de la Route 3 ---------------------------------------------------------------------------

func test_guard_states_the_rule_pushes_back_and_can_be_met_again() -> void:
	await _start(&"pewter_city", Vector2i(47, 26), Vector2i.RIGHT, "pewter")
	for round_index: int in 2:
		_pages.clear()
		await _walk(Vector2i.RIGHT, Vector2i(48, 26))
		await wait_process_frames(5)
		await _finish_scene()
		assert_eq(_pages, ["La Route 3 est réservée aux Dresseurs\nqui ont obtenu le Badge Roche."]
			as Array[String], "règle (passage %d)" % round_index)
		assert_eq(_player.get_cell(), Vector2i(47, 26), "recul d'une case")
		assert_eq(_player.get_facing(), Vector2i.UP, "tourné vers le garde, en recul")
	assert_eq(_scenes.count(&"route_3_guard"), 2, "scène rejouée")
	assert_false(GameState.flags.has_flag(&"route_3_guard_cleared"), "rien avant le badge")
	assert_eq(_boot.get_map().map_id, &"pewter_city", "la sortie ne s'ouvre pas")
	# Reparler au garde : réplique brève.
	_pages.clear()
	await _talk_to(&"route_3_guard")
	assert_eq(_pages, ["Pierre dirige l'Arène d'Argenta."] as Array[String])


# --- Potion de la Route 2 nord ---------------------------------------------------------------

func test_the_potion_goes_to_the_bag_and_stays_gone_after_a_reload() -> void:
	await _start(&"route_2_north", Vector2i(5, 1), Vector2i.LEFT, "route_2_north")
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"route_2_north_ball_1"))
	var before := GameState.bag.count_of(&"potion")
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(&"route_2_north_ball_1") == null, TIMEOUT)
	await _finish_scene()
	assert_eq(GameState.bag.count_of(&"potion"), before + 1, "Sac + 1")
	var found := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == "potion" and entry["map"] == "route_2_north":
			found += 1
	assert_eq(found, 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(&"got_route_2_north_item_1"))
	assert_eq(_pages, [] as Array[String], "aucune bulle")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(&"route_2_north", Vector2i(5, 1), Vector2i.LEFT, "")
	assert_null(_boot.get_map().get_npc(&"route_2_north_ball_1"), "absente au rechargement")
	assert_eq(GameState.bag.count_of(&"potion"), before + 1, "Sac inchangé")


# --- Chercheuse, réactions au badge ---------------------------------------------------------------

func test_researcher_first_time_then_afterwards() -> void:
	await _start(&"pewter_house_researcher", Vector2i(11, 7), Vector2i.UP, "pewter")
	assert_false(GameState.flags.has_flag(&"pewter_researcher_talked"))
	await _talk_to(&"researcher")
	await _talk_to(&"researcher")
	await _talk_to(&"researcher")
	assert_eq(_pages, ["Ma sœur travaille au Musée.",
		"Les fossiles racontent un monde\nque personne n'a vu.",
		"Les fossiles racontent un monde\nque personne n'a vu."] as Array[String])
	assert_true(GameState.flags.has_flag(&"pewter_researcher_talked"))


func _says(npc_id: StringName, flags: Array[StringName]) -> String:
	_pages.clear()
	await _start(&"pewter_city", Vector2i(18, 41), Vector2i.UP, "pewter", flags)
	await _talk_to(npc_id)
	var text := _pages[0] if not _pages.is_empty() else ""
	_boot.queue_free()
	await wait_process_frames(3)
	return text


func test_kid_and_lass_react_to_the_badge() -> void:
	var badge: Array[StringName] = [&"badge_boulder"]
	var none: Array[StringName] = []
	assert_eq(await _says(&"kid", none), "Pierre connaît tout sur les Pokémon Roche !")
	assert_eq(await _says(&"kid", badge), "Tu l'as vraiment battu ?!")
	assert_eq(await _says(&"lass", none), "Je me prépare avant d'affronter Pierre.")
	assert_eq(await _says(&"lass", badge),
		"Alors c'est toi qui l'as battu…\nIl faut que je m'entraîne encore.")


func test_the_mountaineer_notices_the_badge() -> void:
	var badge: Array[StringName] = [&"badge_boulder"]
	var none: Array[StringName] = []
	for with_badge: bool in [false, true]:
		_pages.clear()
		await _start(&"route_2_north", Vector2i(18, 6), Vector2i.LEFT, "route_2_north",
			badge if with_badge else none)
		await _talk_to(&"mountaineer")
		var expected := "C'est le Badge Roche que je vois là ?\nLa Route 3 t'attend, alors." \
			if with_badge else "Argenta est juste devant.\nOn voit le Musée depuis la route."
		assert_eq(_pages, [expected] as Array[String], "badge : %s" % with_badge)
		_boot.queue_free()
		await wait_process_frames(3)


func test_only_the_expected_people_react_to_the_badge() -> void:
	var aware: Array[String] = []
	for path: String in DIALOGUE_FILES:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for id: String in data:
			for variant: Variant in (data[id] as Dictionary).get("variants", []):
				var conditions: Array = (variant as Dictionary).get("if", [])
				if conditions.has("badge_boulder") and not aware.has(id):
					aware.append(id)
	aware.sort()
	var expected := BADGE_AWARE.duplicate()
	expected.sort()
	assert_eq(aware, expected, "enfant, jeune Dresseuse, guide, Montagnard : personne d'autre")


# --- Routines et Racaillou ---------------------------------------------------------------------

func test_the_mountaineer_walks_back_and_forth_inside_his_route() -> void:
	await _start(&"route_2_north", Vector2i(15, 12), Vector2i.UP, "route_2_north")
	var npc := _boot.get_map().get_npc(&"mountaineer")
	var seen: Dictionary = {}
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while seen.size() < 3 and Time.get_ticks_msec() < deadline:
		seen[npc.get_cell()] = true
		await wait_process_frames(5)
	assert_eq(seen.size(), 3, "trois cases parcourues")
	for cell: Vector2i in seen:
		assert_eq(cell.x, 17)
		assert_between(cell.y, 5, 7)


func test_the_stonemason_works_and_his_geodude_stays_put_and_reacts() -> void:
	await _start(&"pewter_city", Vector2i(7, 28), Vector2i.UP, "pewter")
	var map := _boot.get_map()
	var mason := map.get_npc(&"stonemason")
	var geodude := map.get_npc(&"stonemason_geodude")
	assert_not_null(geodude, "Racaillou du tailleur")
	assert_eq(geodude.get_cell(), Vector2i(4, 25))
	
	assert_null(map.get_interactions().find(Vector2i(4, 26), Vector2i.UP), "pas d'interaction")
	var reacted := [false]
	geodude.reacted.connect(func() -> void: reacted[0] = true)
	var seen: Dictionary = {}
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (seen.size() < 3 or not reacted[0]) and Time.get_ticks_msec() < deadline:
		seen[mason.get_cell()] = true
		await wait_process_frames(5)
	assert_eq(seen.size(), 3, "le tailleur parcourt ses trois cases")
	for cell: Vector2i in seen:
		assert_eq(cell.y, 25)
		assert_between(cell.x, 6, 8)
	assert_true(reacted[0], "le Racaillou soulève une pierre")
	assert_eq(geodude.get_cell(), Vector2i(4, 25), "immobile")
