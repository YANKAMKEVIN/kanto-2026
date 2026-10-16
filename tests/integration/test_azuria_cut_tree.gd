extends GutTest
## Arbre à couper à l'est d'Azuria et raccord Azuria ↔ Route 9 (jalon 18, dossier 21 §9, I-2 ;
## `tools/plans/azuria.txt`, variante J18) avec le mécanisme de Coupe du J16 (`FlagGate`, scène
## `cut_tree_cerulean_east`, drapeau `cut_cerulean_east_bush`) sur la vraie scène Boot :
## - sans CS01 ou sans Badge Cascade : arbre debout, case bloquée, texte 17, aucun choix ;
## - avec CS01, Badge Cascade et un Pokémon compatible : COUPER → coupé, passage vers la
##   Route 9, retour à Azuria, **définitif** après une relance (sauvegarde relue) ;
## - LAISSER ne change rien ; la carte seule (drapeaux appliqués à l'arrivée) suit le drapeau.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const MAP_PATH := "res://game/world/maps/cerulean_city.tscn"
const SAVE_PATH := "user://test_azuria_cut_tree_save.json"
const STARTS := "res://tools/debug_start/%s.json"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
const WALK_STOP := &"test_walk_stop"
const CITY := &"cerulean_city"
const ROUTE_9 := &"route_9"
const CUT := &"cut_cerulean_east_bush"
const TREE := Vector2i(53, 23)
const FRONT := Vector2i(52, 23)
const TEXT_17 := "On ne passe pas par là pour l'instant."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _answers: Array[bool] = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_pages.clear()
	_answers.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Aides ---------------------------------------------------------------------------------


func _start(start_name: String) -> void:
	var start := DebugStart.new()
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	assert_true(start.load_file(STARTS % start_name, data, items), "\n".join(start.get_errors()))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = start.map
	_boot.start_spawn = start.spawn
	_boot.start_facing = start.facing
	add_child_autofree(_boot)
	await _attach()
	start.apply(GameState, _boot.get_pokemon_data())
	_boot.get_map().refresh_npcs(GameState.flags)
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_eq(_boot.get_map().map_id, start.map)
	await _save_now()


func _relaunch(disk: Dictionary) -> void:
	if is_instance_valid(_boot):
		_boot.queue_free()
		await wait_process_frames(2)
	_fs = MemoryFs.new()
	_fs.files[SAVE_PATH] = JSON.stringify(disk)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	add_child_autofree(_boot)
	await _attach()


func _attach() -> void:
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)
	_player.moved.connect(_on_player_moved)
	await wait_until(func() -> bool:
		return is_instance_valid(_boot.get_map()) and not SceneRouter.is_transitioning(),
		TIMEOUT)
	await wait_process_frames(3)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _disk() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _save_now() -> void:
	var writes := _writes()
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)


func _on_page_started(_index: int) -> void:
	_pages.append(_boot.get_dialogue_box().get_text())


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Maintient [param action] jusqu'à [param until] (ou jusqu'à ce que le joueur ne bouge plus).
func _walk(action: StringName, until: Vector2i) -> void:
	_stop_at = until
	_held = action
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Pousse [param action] jusqu'à l'arrivée sur la carte [param map_id].
func _push_to(action: StringName, map_id: StringName) -> void:
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == map_id and not SceneRouter.is_transitioning(), TIMEOUT)
	Input.action_release(action)
	await _play_out()


func _play_out() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var yes: bool = _answers.pop_front() if not _answers.is_empty() else false
			(cards.get_confirm_button() if yes else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)


func _interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _play_out()


func _tree() -> Node2D:
	return _boot.get_map().get_node(^"Entities/EastTree") as Node2D


func _pokemon_name() -> String:
	var state := _boot.field_state(&"cut")
	return GameState.party.get_at(state.pokemon_index).display_name(_boot.get_pokemon_data())


# --- La carte seule ------------------------------------------------------------------------


func _map_with(flags: Array[StringName]) -> GameMap:
	var map := (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var story := StoryFlags.new()
	for flag: StringName in flags:
		story.set_flag(flag)
	map.apply_flag_gates(story)
	return map


func test_the_standing_tree_occupies_its_cell_and_the_cut_one_frees_it() -> void:
	var standing := _map_with([])
	assert_true(standing.get_grid().is_occupied(TREE), "arbre debout : case occupée")
	assert_true((standing.get_node(^"Entities/EastTree") as Node2D).visible)
	var cut := _map_with([CUT])
	assert_false(cut.get_grid().is_occupied(TREE), "arbre coupé : case libre")
	assert_false((cut.get_node(^"Entities/EastTree") as Node2D).visible)
	# Les deux pans de clôture restent : seul l'arbre s'ouvre.
	for cell: Vector2i in [Vector2i(53, 22), Vector2i(53, 24)]:
		assert_true(cut.get_grid().is_solid(cell), "clôture %s" % cell)


func test_the_east_path_leads_to_route_9_row_by_row() -> void:
	var map := _map_with([CUT])
	var suffixes := ["_n", "", "_s"]
	for i: int in 3:
		var cell := Vector2i(55, 22 + i)
		var warp := map.get_warps().find_on_push(cell, Vector2i.RIGHT)
		assert_not_null(warp, "raccord %s" % cell)
		if warp != null:
			assert_false(warp.is_coming_soon())
			assert_eq([warp.target_map, warp.target_spawn],
				[ROUTE_9, StringName("from_cerulean" + suffixes[i])])
		assert_eq(map.get_spawn_cell(StringName("from_route_9" + suffixes[i])), cell)


# --- Sur la vraie scène --------------------------------------------------------------------


func test_without_cut_the_tree_stays_blocked_and_says_text_17() -> void:
	for start_name: String in ["cerulean_east_tree_no_hm", "cerulean_east_tree_no_badge"]:
		_pages.clear()
		await _start(start_name)
		assert_eq(_player.get_cell(), FRONT, start_name)
		await _interact()
		assert_eq(_pages, [TEXT_17] as Array[String], start_name)
		assert_false(GameState.flags.has_flag(CUT), start_name)
		assert_true(_tree().visible, start_name)
		assert_eq(_boot.get_map().map_id, CITY, start_name)
		await _walk(&"move_right", TREE)
		assert_eq(_player.get_cell(), FRONT, "%s : l'arbre barre le passage" % start_name)
		_boot.queue_free()
		await wait_process_frames(2)
		_fs = MemoryFs.new()
	assert_push_error_count(0)


func test_leave_then_cut_then_cross_to_route_9_and_back_for_good() -> void:
	await _start("cerulean_east_tree")
	var pokemon := _pokemon_name()
	_answers = [false]
	await _interact()
	assert_eq(_pages, ["%s peut couper cet arbuste." % pokemon, "Utiliser Coupe ?"]
		as Array[String], "offre de Coupe")
	assert_false(GameState.flags.has_flag(CUT), "LAISSER : rien ne change")
	assert_true(_tree().visible)
	_pages.clear()
	_answers = [true]
	await _interact()
	assert_true(_pages.has("%s utilise Coupe !" % pokemon))
	assert_true(GameState.flags.has_flag(CUT))
	assert_false(_tree().visible, "arbre coupé")
	assert_false(_boot.get_map().get_grid().is_occupied(TREE), "case libérée")
	# Passage : jusqu'au sentier, puis vers la Route 9, colonne 0, même rangée.
	await _walk(&"move_right", Vector2i(54, 23))
	assert_eq(_player.get_cell(), Vector2i(54, 23), "l'arbre coupé laisse passer")
	await _walk(&"move_right", Vector2i(55, 23))
	await _push_to(&"move_right", ROUTE_9)
	assert_eq(_player.get_cell(), Vector2i(0, 23), "Route 9, bord ouest")
	assert_eq(_player.get_facing(), Vector2i.RIGHT, "tourné vers l'est")
	# Retour vers Azuria : l'arbre est toujours coupé.
	await _push_to(&"move_left", CITY)
	assert_eq(_player.get_cell(), Vector2i(55, 23))
	assert_false(_tree().visible, "toujours coupé au retour")
	# Relance : coupé pour toujours.
	await _save_now()
	await _relaunch(_disk())
	assert_true(GameState.flags.has_flag(CUT))
	assert_eq(_boot.get_map().map_id, CITY)
	assert_false(_tree().visible, "coupé après la relance")
	assert_false(_boot.get_map().get_grid().is_occupied(TREE))
	assert_push_error_count(0)
