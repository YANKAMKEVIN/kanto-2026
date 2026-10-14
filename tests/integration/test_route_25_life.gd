extends GutTest
## La vie de la Route 25 (jalon 14 T16, jalon-14.md §2.11 ; dossier 17 §9 à §11, §15 n° 42 à 51,
## 66) avec la vraie scène Boot et une sauvegarde en mémoire :
## - rencontres : table de `data/encounters/route_25.json` (taux 15, Abra rare 10-12), repli
##   Roucool / Chenipan tant que Mystherbe et Chétiflor (J13 T11) n'existent pas ;
## - objets O1 (CT19), O2, O3 : PRENDRE, une seule fois, retirés au rechargement ; O4 caché
##   (rocher au coquillage examiné depuis le nord) : une seule fois, puis « plus rien » ;
## - panneaux, promeneur et vieil homme : textes validés ; un Dresseur interpelle ;
## - objectif n° 66 ; chaque dialogue du fichier est utilisé (D5 et D6 compris depuis le T23).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_25.json"
const PLAN_PATH := "res://tools/plans/route_25.txt"
const SAVE_PATH := "user://test_route_25_life_save.json"
const MAP_ID := "route_25"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
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


func _start(cell: Vector2i, facing: Vector2i, fresh: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = StringName(MAP_ID)
	_boot.start_spawn = &"from_route_24_c"
	_boot.start_facing = Vector2i.RIGHT
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
	_runner.page_started.connect(func(_index: int) -> void:
		_events.append("page")
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


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_right"
	match direction:
		Vector2i.UP:
			action = &"move_up"
		Vector2i.DOWN:
			action = &"move_down"
		Vector2i.LEFT:
			action = &"move_left"
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _scenes.is_empty(), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


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


func _found(item: String) -> int:
	var count := 0
	for entry: Dictionary in GameState.found_items:
		if entry["item"] == item and entry["map"] == MAP_ID:
			count += 1
	return count


# --- Rencontres ----------------------------------------------------------------------------

func _table() -> EncounterTable:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	assert_true(library.has_table(&"route_25"))
	return library.get_table(&"route_25")


func test_encounter_table_rate_15_with_rare_abra() -> void:
	var table := _table()
	assert_eq(table.rate, 15, "taux 15 (dossier 17 §10)")
	assert_true(table.has_ramp(), "rampe par défaut des routes")
	assert_eq(table.total_weight(), 100)
	assert_almost_eq(table.chance_of(&"abra"), 0.15, 0.0001, "Abra 15 %")
	for slot: EncounterSlot in table.slots:
		if slot.species == &"abra":
			assert_eq([slot.min_level, slot.max_level], [10, 12], "Abra 10-12")
	# Depuis le T23 (J13 T11 fusionné) : Roucool 20, Mystherbe 18, Chétiflor 17 (12-14), Chenipan
	# 10, puis Aspicot 10, Chrysacier 5, Coconfort 5 (plus de repli Roucool 38 / Chenipan 27).
	assert_almost_eq(table.chance_of(&"pidgey"), 0.20, 0.0001)
	assert_almost_eq(table.chance_of(&"oddish"), 0.18, 0.0001)
	assert_almost_eq(table.chance_of(&"bellsprout"), 0.17, 0.0001)
	assert_almost_eq(table.chance_of(&"caterpie"), 0.10, 0.0001)
	for slot: EncounterSlot in table.slots:
		if slot.species == &"oddish" or slot.species == &"bellsprout":
			assert_eq([slot.min_level, slot.max_level], [12, 14], String(slot.species))
	assert_almost_eq(table.chance_of(&"weedle"), 0.10, 0.0001)
	assert_almost_eq(table.chance_of(&"metapod"), 0.05, 0.0001)
	assert_almost_eq(table.chance_of(&"kakuna"), 0.05, 0.0001)


func test_tall_grass_of_the_scene_matches_the_four_zones() -> void:
	var map := (load("res://game/world/maps/route_25.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var grass := 0
	for cell: Vector2i in _plan.cells_of("h"):
		assert_true(map.get_grid().is_tall_grass(cell), "%s : hautes herbes" % cell)
		grass += 1
	assert_gt(grass, 0)
	for id: String in ["herbes_h1", "herbes_h2", "herbes_h3", "herbes_h4"]:
		assert_true(map.get_grid().is_tall_grass(_plan.cell_of(id)), id)


# --- Objets visibles -----------------------------------------------------------------------

func _check_visible_item(index: int, item: StringName) -> void:
	var id := StringName("route_25_item_%d" % index)
	var cell := _plan.cell_of("route_25_item_%d" % index)
	var near := _neighbour(cell)
	assert_false(near.is_empty(), "%s a une case d'accès" % id)
	if near.is_empty():
		return
	await _start(near[0], near[1], true)
	var map := _boot.get_map()
	assert_not_null(map.get_npc(id), "l'objet est au sol")
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "cible d'interaction")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TAKE, "verbe PRENDRE")
	var before := _bag(item)
	await _press_interact()
	await wait_until(func() -> bool: return map.get_npc(id) == null, TIMEOUT)
	await _finish_scene()
	assert_eq(_bag(item), before + 1, "Sac + 1")
	assert_eq(_found(String(item)), 1, "journal des objets trouvés")
	assert_true(GameState.flags.has_flag(StringName("got_route_25_item_%d" % index)))
	assert_eq(_toasts.size(), 1, "un toast")
	assert_eq(_events.count("page"), 0, "aucune bulle avant le toast")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := _bag(item)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement : une seule fois")
	assert_eq(_bag(item), bag_after, "Sac inchangé")
	assert_push_error_count(0)


func test_o1_tm19_on_the_terrace() -> void:
	await _check_visible_item(1, &"tm19")


func test_o2_potion_in_the_cove() -> void:
	await _check_visible_item(2, &"potion")


func test_o3_poke_ball_on_the_point() -> void:
	await _check_visible_item(3, &"poke_ball")


# --- Objet caché ---------------------------------------------------------------------------

func test_o4_hidden_potion_under_the_shell_once() -> void:
	var clue := _plan.cell_of("route_25_hidden_1")
	assert_eq(clue, Vector2i(64, 20))
	var from := clue + Vector2i.UP
	await _start(from, Vector2i.DOWN, true)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "le rocher est une cible depuis (64, 19) tourné vers le sud")
	var before := _bag(&"potion")
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_events, ["page", "toast"] as Array[String], "narration puis toast")
	assert_eq(_pages, ["Quelque chose est caché\nsous ce coquillage."] as Array[String])
	assert_eq(_bag(&"potion"), before + 1)
	assert_eq(_found("potion"), 1)
	assert_true(GameState.flags.has_flag(&"got_route_25_hidden_1"))
	# Repli (J12 T17 absent) : le point reste examinable mais ne redonne rien.
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_bag(&"potion"), before + 1, "une seule fois")
	assert_eq(_found("potion"), 1)
	assert_eq(_events, ["page", "toast", "page"] as Array[String])
	assert_eq(_pages[1], "Il n'y a plus rien\nsous ce coquillage.")
	assert_push_error_count(0)


func test_o4_is_not_reachable_from_the_wrong_side() -> void:
	var clue := _plan.cell_of("route_25_hidden_1")
	await _start(clue + Vector2i.UP, Vector2i.UP, true)
	assert_null(_boot.get_interaction_controller().get_target(), "tourné vers le nord : rien")


# --- Panneaux et PNJ -----------------------------------------------------------------------

func _read_from(cell: Vector2i, facing: Vector2i) -> void:
	await _start(cell, facing, true)
	await _press_interact()
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	await _finish_scene()


func test_west_sign_n42() -> void:
	await _read_from(Vector2i(3, 13), Vector2i.UP)
	assert_eq(_pages, ["ROUTE 25\nAzuria ← → Cap d'Azuria"] as Array[String])


func test_cape_sign_n43() -> void:
	await _read_from(Vector2i(69, 13), Vector2i.UP)
	assert_eq(_pages, ["CAP D'AZURIA\nMaison de Léo. Sonnez fort."] as Array[String])


func _talk_to(npc_id: StringName) -> void:
	var npc := _boot.get_map().get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	var near := _neighbour(npc.get_cell())
	await _start(near[0], near[1], true)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()


func test_traveler_n44() -> void:
	await _start(Vector2i(13, 10), Vector2i.RIGHT, true)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, ["Le Cap, là-bas.\nUn drôle de type y vit.",
		"Des fois, sa maison\nfait des étincelles."] as Array[String])


func test_old_man_n45() -> void:
	await _start(Vector2i(66, 15), Vector2i.DOWN, true)
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, ["La mer est calme ce soir.\nLéo vit tout au bout.",
		"Il ne sort pas beaucoup."] as Array[String])


# --- Dresseurs -----------------------------------------------------------------------------

func test_d1_calls_the_player_at_the_exit_of_the_route_24() -> void:
	await _start(Vector2i(15, 14), Vector2i.RIGHT, true)
	await _walk(Vector2i.RIGHT, Vector2i(19, 14))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_route_25_youngster_jules"] as Array[StringName])
	assert_false(GameState.flags.has_flag(&"beaten_route_25_youngster_jules"))


func test_a_beaten_trainer_does_not_call_and_says_his_last_line() -> void:
	await _start(Vector2i(18, 15), Vector2i.UP, true)
	GameState.flags.set_flag(&"beaten_route_25_youngster_jules")
	await _walk(Vector2i.UP, Vector2i(18, 11))
	await wait_process_frames(30)
	assert_eq(_player.get_cell(), Vector2i(18, 11), "jusqu'au pied de Jules")
	assert_eq(_scenes, [] as Array[StringName], "un Dresseur battu ne défie plus")
	await _press_interact()
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	await _finish_scene()
	assert_eq(_pages, ["Je m'entraîne ici tous les jours.\nPas assez, faut croire."] \
		as Array[String])
	assert_eq(_speakers, ["Gamin Jules"] as Array[String])


func test_d4_in_the_cove_calls_from_two_cells() -> void:
	var bernard := _plan.cell_of("d4")
	await _start(bernard + Vector2i(0, -3), Vector2i.DOWN, true)
	await _walk(Vector2i.DOWN, bernard + Vector2i(0, -2))
	await wait_until(func() -> bool: return not _scenes.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_route_25_hiker_bernard"] as Array[StringName])


# --- Objectif n° 66 -------------------------------------------------------------------------

func test_objective_n66_until_leo_is_met() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	var flags := StoryFlags.new()
	for flag: StringName in [&"pokedex_activated", &"pewter_arrived", &"badge_boulder",
			&"route_4_reached", &"cerulean_reached"]:
		flags.set_flag(flag)
	assert_eq(library.current_id(flags), &"get_cascade_badge")
	flags.set_flag(&"beaten_nugget_rocket")
	assert_eq(library.current_id(flags), &"get_cascade_badge", "pont avant badge (J13)")
	flags.set_flag(&"badge_cascade")
	assert_eq(library.current_id(flags), &"go_cerulean_cape", "après le Pont Pépite et le badge")
	assert_eq(library.current(flags), "rejoindre le Cap d'Azuria.")
	flags.set_flag(&"bill_met")
	assert_eq(library.current_id(flags), &"help_bill", "Léo rencontré : « aider Léo » (T17) remplace la ligne")


# --- Dialogues -----------------------------------------------------------------------------

func test_every_dialogue_of_the_file_is_used() -> void:
	var raw: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/dialogues/route_25.json"))
	var used: Dictionary = {}
	var roster := NpcRoster.load_for_map(&"route_25")
	for spec: NpcSpec in roster.get_all():
		for id: StringName in [spec.dialogue, spec.before_dialogue, spec.defeated_dialogue]:
			used[id] = true
	var map := (load("res://game/world/maps/route_25.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	for interaction: Interaction in map.get_interactions().get_all():
		used[interaction.dialogue_id] = true
	var cutscenes := FileAccess.get_file_as_string("res://data/cutscenes/route_25.json")
	var parsed: Dictionary = JSON.parse_string(cutscenes)
	for scene: Dictionary in parsed.values():
		for variant: Dictionary in scene["variants"]:
			for step: Dictionary in variant["steps"]:
				if step.has("dialogue"):
					used[StringName(step["dialogue"])] = true
	for key: String in raw:
		assert_true(used.has(StringName(key)), "%s : utilisé" % key)
	for id: StringName in used:
		if not String(id).is_empty():
			assert_true(raw.has(String(id)), "%s : défini" % id)
	assert_eq(raw.size(), 27, "2 panneaux, 2 PNJ, 6 × 3 répliques, 3 objets, 2 cachés")
