extends GutTest
## La vie de la Route 11 (jalon 17 T17, jalon-17.md §2.4 ; dossier 20 §3.2, §5, §7, §16) avec la
## vraie scène Boot et une sauvegarde en mémoire :
## - bord est (J21 T9a, décision M-3 de Kevin du 2026-10-16) : Ronflex a quitté la Route 11 pour
##   le croisement de la Route 12 ; le goulet est libre, aucun examen, et le bord est montre
##   « ROUTE 12 — À venir » puis rend le joueur juste à l'ouest, tourné ← (plus d'impasse muette) ;
## - objets O1 (Super Potion), O2 (Réveil) : PRENDRE, une seule fois, retirés au rechargement ;
##   O3 (Poké Ball) cachée sous le caillou : bouton face à l'indice seulement, une seule fois,
##   plus de cible après la trouvaille et au rechargement ;
## - panneaux T-12 (entrée) et T-10 (Cave) ; rencontres (table du dossier §5) ;
## - chaque dialogue du fichier est utilisé (le titre d'arrivée : `test_route_11_vermilion_link`).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/route_11.json"
const PLAN_PATH := "res://tools/plans/route_11.txt"
const SAVE_PATH := "user://test_route_11_life_save.json"
const MAP_ID := "route_11"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Goulet de l'est : les cases de l'ancien Ronflex du J17 (retiré par M-3).
const NARROWS := [Vector2i(66, 14), Vector2i(67, 14), Vector2i(66, 15), Vector2i(67, 15)]
const FRONT := [Vector2i(65, 14), Vector2i(65, 15)]

var _plan: PlanGrid
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _toasts: Array[PackedStringArray] = []
var _events: Array[String] = []
var _pages: Array[String] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T14:03:05")
	_fs = MemoryFs.new()
	_toasts.clear()
	_events.clear()
	_pages.clear()


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
	_boot.start_spawn = &"from_vermilion_c"
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
		_pages.append(_runner.get_session().get_text()))
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
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while (director.is_running() or _runner.is_running()) \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


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


# --- Rencontres ------------------------------------------------------------------------------

func test_encounter_table_follows_the_dossier() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var table := library.get_table(&"route_11")
	assert_not_null(table)
	assert_eq(table.rate, 25)
	assert_eq(table.total_weight(), 100)
	assert_almost_eq(table.chance_of(&"spearow"), 0.35, 0.0001)
	assert_almost_eq(table.chance_of(&"drowzee"), 0.25, 0.0001)
	assert_almost_eq(table.chance_of(&"ekans"), 0.20, 0.0001)
	assert_almost_eq(table.chance_of(&"sandshrew"), 0.20, 0.0001)


func test_tall_grass_of_the_scene_matches_the_three_zones() -> void:
	var map := (load("res://game/world/maps/route_11.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	for cell: Vector2i in _plan.cells_of("h"):
		assert_true(map.get_grid().is_tall_grass(cell), "%s : hautes herbes" % cell)
	for id: String in ["herbes_h1", "herbes_h2", "herbes_h3"]:
		assert_true(map.get_grid().is_tall_grass(_plan.cell_of(id)), id)


# --- Bord est (M-3) ----------------------------------------------------------------------------

func test_east_narrows_are_free_and_silent() -> void:
	await _start(Vector2i(65, 14), Vector2i.RIGHT, true)
	var map := _boot.get_map()
	for cell: Vector2i in NARROWS:
		assert_false(map.get_grid().is_occupied(cell), "goulet libre en %s (M-3)" % cell)
	assert_null(_boot.get_interaction_controller().get_target(), "plus de Ronflex à examiner")
	var reached := map.get_grid().find_reachable(Vector2i(0, 12), _player)
	for cell: Vector2i in [Vector2i(75, 14), Vector2i(75, 15), Vector2i(70, 12)]:
		assert_true(reached.has(cell), "%s atteignable" % cell)
	assert_push_error_count(0)


func test_east_edge_shows_route_12_coming_soon_then_returns() -> void:
	await _start(Vector2i(75, 15), Vector2i.RIGHT, true)
	watch_signals(SceneRouter)
	Input.action_press(&"move_right")
	await wait_for_signal(SceneRouter.coming_soon_shown, TIMEOUT)
	Input.action_release(&"move_right")
	assert_signal_emitted_with_parameters(SceneRouter, "coming_soon_shown", ["Route 12"])
	await wait_for_signal(SceneRouter.coming_soon_finished, TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"route_11", "aucune carte chargée")
	assert_eq(_player.get_cell(), Vector2i(74, 15), "retour juste à l'ouest du bord")
	assert_eq(_player.get_facing(), Vector2i.LEFT, "tourné vers la route")
	assert_push_error_count(0)


# --- Objets visibles -------------------------------------------------------------------------

func _check_visible_item(index: int, item: StringName) -> void:
	var id := StringName("route_11_item_%d" % index)
	var cell := _plan.cell_of("route_11_item_%d" % index)
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
	assert_true(GameState.flags.has_flag(StringName("got_route_11_item_%d" % index)))
	assert_eq(_toasts.size(), 1, "un toast")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	var bag_after := _bag(item)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(near[0], near[1], false)
	assert_null(_boot.get_map().get_npc(id), "absent au rechargement : une seule fois")
	assert_eq(_bag(item), bag_after, "Sac inchangé")
	assert_push_error_count(0)


func test_o1_super_potion_in_the_central_grove() -> void:
	assert_eq(_plan.cell_of("route_11_item_1"), Vector2i(40, 13))
	await _check_visible_item(1, &"super_potion")


func test_o2_awakening_on_the_shore_pocket() -> void:
	assert_eq(_plan.cell_of("route_11_item_2"), Vector2i(47, 25))
	await _check_visible_item(2, &"awakening")


# --- Objet caché -----------------------------------------------------------------------------

func test_o3_hidden_poke_ball_under_the_stone_once() -> void:
	var clue := _plan.cell_of("route_11_hidden_1")
	assert_eq(clue, Vector2i(62, 9))
	await _start(clue + Vector2i.DOWN, Vector2i.UP, true)
	assert_not_null(_boot.get_interaction_controller().get_target(),
		"le caillou est une cible depuis (62, 10) tourné vers lui")
	var before := _bag(&"poke_ball")
	await _press_interact()
	await wait_until(func() -> bool: return _bag(&"poke_ball") > before, TIMEOUT)
	await _finish_scene()
	assert_eq(_bag(&"poke_ball"), before + 1)
	assert_eq(_found("poke_ball"), 1)
	assert_true(GameState.flags.has_flag(&"got_route_11_hidden_1"))
	await wait_process_frames(8)
	assert_null(_boot.get_interaction_controller().get_target(), "plus de cible après la trouvaille")
	await _press_interact()
	await wait_process_frames(8)
	assert_eq(_bag(&"poke_ball"), before + 1, "une seule fois")
	# Après rechargement : toujours plus de cible, rien de plus.
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	await _start(clue + Vector2i.DOWN, Vector2i.UP, false)
	assert_null(_boot.get_interaction_controller().get_target(), "absent au rechargement")
	assert_push_error_count(0)


func test_o3_only_when_facing_the_clue() -> void:
	var clue := _plan.cell_of("route_11_hidden_1")
	await _start(clue + Vector2i.DOWN, Vector2i.DOWN, true)
	assert_null(_boot.get_interaction_controller().get_target(), "tourné ailleurs : rien")
	_boot.get_map().spawn_player_at(_player, clue + Vector2i.LEFT, Vector2i.RIGHT)
	await wait_process_frames(3)
	assert_not_null(_boot.get_interaction_controller().get_target(), "de côté, tourné vers lui")


# --- Panneaux --------------------------------------------------------------------------------

func _read_from(cell: Vector2i, facing: Vector2i) -> void:
	await _start(cell, facing, true)
	await _press_interact()
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	await _finish_scene()


func test_west_sign_t12() -> void:
	await _read_from(Vector2i(3, 11), Vector2i.UP)
	assert_eq(_pages, ["ROUTE 11\nCarmin-sur-Mer — Route 12"] as Array[String])


func test_cave_sign_t10() -> void:
	await _read_from(Vector2i(17, 9), Vector2i.UP)
	assert_eq(_pages, ["CAVE TAUPIQUEUR\nVers la Route 2"] as Array[String])


# --- Dialogues -------------------------------------------------------------------------------

func test_every_dialogue_of_the_file_is_used() -> void:
	var raw: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/dialogues/route_11.json"))
	var used: Dictionary = {}
	var roster := NpcRoster.load_for_map(&"route_11")
	for spec: NpcSpec in roster.get_all():
		for id: StringName in [spec.dialogue, spec.before_dialogue, spec.defeated_dialogue]:
			used[id] = true
	var map := (load("res://game/world/maps/route_11.tscn") as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	for interaction: Interaction in map.get_interactions().get_all():
		used[interaction.dialogue_id] = true
	# M-3 (J21 T9a) : `route_11_snorlax` (T-6, T-7) reste dans le fichier, réservé au Ronflex de
	# la Route 12 (J21 T19-T21) ; plus aucun point de la Route 11 ne le lit.
	assert_true(raw.has("route_11_snorlax"), "T-6 / T-7 gardés pour la Route 12")
	assert_false(used.has(&"route_11_snorlax"), "Ronflex retiré de la Route 11")
	used[&"route_11_snorlax"] = true
	for key: String in raw:
		assert_true(used.has(StringName(key)), "%s : utilisé" % key)
	for id: StringName in used:
		if not String(id).is_empty():
			assert_true(raw.has(String(id)), "%s : défini" % id)
	assert_eq(raw.size(), 3 + 8 * 3 + 3, "2 panneaux, Ronflex (réservé, M-3), 8 × 3 répliques, 3 objets")
