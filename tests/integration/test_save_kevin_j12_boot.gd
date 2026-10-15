extends GutTest
## Clôture du J12 (T29) : la **vraie partie de Kevin** (v6, S21, 2026-10-14 ; Jadielle, sans
## badge) reprise par le vrai Boot du J12, puis les raccords vers Argenta et la Route 3.
## - Continuer : la partie reprend à Jadielle sur sa case, rien n'est écarté ; le premier
##   autosave (arrivée sur la carte) réécrit la même partie (v6), seul le temps de jeu avance ;
## - à pied, PNJ placés selon **ses** drapeaux : de sa case, Jadielle → Route 2 → Forêt de Jade
##   → Route 2 nord → Argenta (Arène, Centre) ; la sortie est d'Argenta est gardée tant qu'il n'a
##   pas le badge (scène `route_3_guard`), puis la Route 3, le Centre du Mont Sélénite et le 1F.
## Système de fichiers en mémoire : jamais le vrai `user://`, ni le fichier du téléphone.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const FIXTURE := "res://tests/fixtures/save/v6_kevin_s21.json"
const SAVE_PATH := "user://test_kevin_j12_save.json"
const SETTINGS_PATH := "user://test_kevin_j12_settings.json"
const ABSENT := "user://test_kevin_j12_absent.json"
const TIMEOUT := 12.0
## Cartes parcourues pour les raccords (les autres warps sont ignorés : Route 1, Route 22…).
const WAY: Array[StringName] = [
	&"viridian_city", &"route_2", &"viridian_forest_gate_south", &"viridian_forest",
	&"viridian_forest_gate_north", &"route_2_north", &"pewter_city", &"pewter_gym",
	&"pewter_center", &"route_3", &"mt_moon_center", &"mt_moon_1f",
]
const TO_PEWTER: Array[StringName] = [
	&"route_2", &"viridian_forest_gate_south", &"viridian_forest", &"viridian_forest_gate_north",
	&"route_2_north", &"pewter_city", &"pewter_gym", &"pewter_center",
]
const BEYOND: Array[StringName] = [&"route_3", &"mt_moon_center", &"mt_moon_1f"]

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node
var _maps: Dictionary = {}


func before_each() -> void:
	_fs = MemoryFs.new()
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-10-14T12:00:00")


func after_each() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()
	GameState.clock = DeviceClock.new()


func _text() -> String:
	return FileAccess.get_file_as_string(FIXTURE)


func _original() -> Dictionary:
	return JSON.parse_string(_text())


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


# --- Reprise par le vrai Boot --------------------------------------------------------------

func _launch() -> void:
	_fs.files[SAVE_PATH] = _text()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = ABSENT
	_boot.debug_unlocks_path = ABSENT
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	await wait_process_frames(2)


func _written() -> bool:
	for entry: String in _fs.journal:
		if entry.ends_with("-> " + SAVE_PATH) or entry == "write " + SAVE_PATH:
			return true
	return false


func test_continue_resumes_his_game_and_the_autosave_keeps_everything() -> void:
	await _launch()
	var title := _boot.get_opening().get_screen()
	assert_not_null(title, "écran titre")
	if title == null:
		return
	assert_eq(title.get_featured(), &"continue", "Continuer en avant : partie reconnue")
	assert_eq(_boot.get_opening().get_model().summary.player_name, "Kevin")
	title.get_entry_button(&"continue").pressed.emit()
	await wait_until(func() -> bool: return _boot.get_opening().is_finished(), TIMEOUT)
	await wait_process_frames(2)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, &"viridian_city")
	assert_eq(_boot.get_player().get_cell(), Vector2i(42, 22), "sur sa case")
	assert_eq(GameState.party.size(), 4)
	assert_eq(GameState.money, 2100)
	assert_true(_boot._can_write(), "autosave normal")
	await wait_until(_written, TIMEOUT)
	assert_true(_written(), "premier autosave écrit")
	assert_false(_fs.files.has(SAVE_PATH + ".rejected"), "rien d'écarté")
	var saved: Dictionary = JSON.parse_string(_fs.files[SAVE_PATH])
	var original := _original()
	# J15 : réécrite en v7, avec la seule Pension vide en plus.
	assert_eq(int(saved["version"]), 7, "v7 (J15)")
	assert_eq(saved.get("daycare"), {}, "Pension vide")
	assert_true(float(saved["play_time"]) >= float(original["play_time"]), "temps de jeu")
	saved.erase("play_time")
	original.erase("play_time")
	saved.erase("daycare")
	original["version"] = 7
	assert_eq(_json(saved), _json(original), "même partie, champ pour champ")


# --- Raccords vers Argenta -----------------------------------------------------------------

func _map(map_id: StringName, flags: StoryFlags) -> GameMap:
	if _maps.has(map_id):
		return _maps[map_id]
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child(map)
	map.refresh_npcs(flags)
	_maps[map_id] = map
	return map


## Cartes de [constant WAY] atteintes à pied depuis la case sauvegardée, PNJ placés selon
## [param flags] (warps « à venir » exclus). Les scènes de garde ne sont pas jouées ici.
func _reached_maps(flags: StoryFlags) -> Array[StringName]:
	var original := _original()
	var start_map := StringName(original["map"])
	var first := _map(start_map, flags)
	var start := first.find_standing_cell(Vector2i(original["cell"][0], original["cell"][1]))
	var visited: Dictionary = {}
	var queue: Array = [[start_map, start]]
	var maps: Array[StringName] = []
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var map_id: StringName = item[0]
		var key := "%s%s" % [map_id, item[1]]
		if visited.has(key):
			continue
		visited[key] = true
		if not maps.has(map_id):
			maps.append(map_id)
		var map := _map(map_id, flags)
		var reached := map.get_grid().find_reachable(item[1])
		for warp: Warp in map.get_warps().get_all():
			if warp.is_coming_soon() or not WAY.has(warp.target_map):
				continue
			if not reached.has(warp.cell):
				continue
			var target := _map(warp.target_map, flags)
			queue.append([warp.target_map, target.get_spawn_cell(warp.target_spawn)])
	return maps


func _kevin_flags() -> StoryFlags:
	var flags := StoryFlags.new()
	flags.load_array(_original()["flags"])
	return flags


func test_from_his_cell_pewter_city_is_reachable_on_foot() -> void:
	var reached := _reached_maps(_kevin_flags())
	gut.p("cartes atteintes : %s" % [reached])
	for map_id: StringName in TO_PEWTER:
		assert_has(reached, map_id, "atteinte depuis Jadielle : %s" % map_id)


func test_the_route_3_guard_turns_him_back_until_the_badge() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "scènes")
	var guard := library.get_cutscene(&"route_3_guard")
	assert_not_null(guard)
	var flags := _kevin_flags()
	assert_eq(guard.pick(flags), guard.variants[0], "sans badge : demi-tour")
	flags.set_flag(&"badge_boulder")
	assert_eq(guard.pick(flags), guard.variants[1], "avec le badge : le garde s'écarte")
	flags.set_flag(&"route_3_guard_cleared")
	assert_null(guard.pick(flags), "ensuite, plus rien")


func test_with_the_badge_the_route_3_and_mt_moon_follow() -> void:
	var flags := _kevin_flags()
	flags.set_flag(&"badge_boulder")
	flags.set_flag(&"route_3_guard_cleared")
	var reached := _reached_maps(flags)
	for map_id: StringName in TO_PEWTER + BEYOND:
		assert_has(reached, map_id, "atteinte avec le badge : %s" % map_id)
