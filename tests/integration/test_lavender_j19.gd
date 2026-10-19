extends GutTest
## Lavanville au J19 (T20 ; docs/tech/jalon-19.md §2.11, dossier 22 §10 et §15.6) avec la vraie
## scène Boot : textes §15.6.1 à 15.6.5 **mot pour mot** aux bonnes cases, panneau du Scope
## bloquant et lu depuis (41, 11) →, absence du mot interdit (décision 7), T-25 plus joué.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const DOSSIER := "res://docs/design/dossier-22-tour-pokemon.md"
const TOWN_PLAN := "res://tools/plans/lavanville.txt"
const HOUSE_PLAN := "res://tools/plans/lavanville_maison_pokemon.txt"
const SAVE_NAME := "test_lavender_j19"
const FADE := 0.05
const TIMEOUT := 12.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Fichiers de données ajoutés ou modifiés par le T20.
const FILES: Array[String] = [
	"res://data/dialogues/lavender_houses.json", "res://data/dialogues/lavender_town.json",
	"res://data/npcs/pokemon_house.json", "res://data/npcs/lavender_center.json",
	"res://tools/plans/lavanville_maison_pokemon.txt",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:03:05")
	_fs = MemoryFs.new()
	_pages.clear()
	_speakers.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, "user://%s_save.json" % SAVE_NAME)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var debug_start := DebugStart.new()
	assert_true(debug_start.load_file("res://tools/debug_start/lavender.json",
		_boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(debug_start.get_errors()))
	debug_start.apply(GameState, _boot.get_pokemon_data())
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")


func _finish() -> void:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while _runner.is_running() and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(5)


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
	await _finish()


## Les textes « … » de l'élément numéroté [param number] du §15.6 du dossier (lignes jointes).
func _quote(number: int) -> String:
	var source := FileAccess.get_file_as_string(DOSSIER)
	var start := source.find("### 15.6 Lavanville")
	var section := source.substr(start, source.find("### 15.7") - start)
	section = section.replace("\n   ", " ")
	var regex := RegEx.create_from_string("« (.+?) »")
	for line: String in section.split("\n"):
		if line.begins_with("%d. " % number):
			var found := regex.search(line)
			if found != null:
				return found.get_string(1)
	return ""


func _said() -> String:
	var texts: Array[String] = []
	for page: String in _pages:
		assert_lte(page.split("\n").size(), 2, "bulle de deux lignes au plus")
		texts.append(page.replace("\n", " "))
	return " ".join(texts)


func test_the_kid_says_15_6_1_and_not_t25_then_t26() -> void:
	await _start(&"pokemon_house", &"entrance", Vector2i(7, 8), Vector2i.UP)
	await _talk_to(&"enfant")
	assert_eq(_said(), _quote(1), "§15.6.1")
	assert_ne(_quote(1), "")
	assert_false(_said().contains("passe ses journées"), "T-25 n'est plus joué")
	await _talk_to(&"enfant")
	assert_eq(_said(), "Ces Pokémon n'avaient plus de Dresseur. Maintenant, ils nous ont nous.",
		"T-26 garde sa place")


func test_the_man_and_the_girl_stand_in_the_pokemon_house_and_say_15_6_2_and_3() -> void:
	await _start(&"pokemon_house", &"entrance", Vector2i(7, 8), Vector2i.UP)
	var plan := PlanGrid.new()
	assert_true(plan.load_file(HOUSE_PLAN), plan.error)
	var map := _boot.get_map()
	for entry: Array in [[&"homme", Vector2i(11, 7), 2, "Homme"],
			[&"fille", Vector2i(3, 5), 3, "Fillette"]]:
		var npc := map.get_npc(entry[0])
		assert_not_null(npc, String(entry[0]))
		assert_eq(npc.get_cell(), entry[1])
		assert_eq(plan.cell_of(String(entry[0])), entry[1], "case de la grille")
		assert_true(plan.is_walkable(entry[1]), "case libre")
		await _talk_to(entry[0])
		assert_ne(_quote(entry[2]), "")
		assert_eq(_said(), _quote(entry[2]), "§15.6.%d" % entry[2])
		assert_eq(_speakers[0], entry[3])
	# Aucun Osselait visible au J19 : seuls Rondoudou et Nidoran femelle sont des Pokémon.
	for npc: Npc in map.get_npcs():
		if String(npc.get_spec().sprite).begins_with("pokemon/"):
			assert_true(["pokemon/jigglypuff", "pokemon/nidoran_f"].has(npc.get_spec().sprite))


func test_the_gentleman_of_the_center_says_15_6_4() -> void:
	await _start(&"lavender_center", &"entrance", Vector2i(7, 8), Vector2i.UP)
	var map := _boot.get_map()
	var gentleman := map.get_npc(&"gentleman")
	assert_not_null(gentleman)
	assert_eq(gentleman.get_cell(), Vector2i(11, 5))
	assert_not_null(map.get_npc(&"nurse"), "l'infirmière reste en place")
	await _talk_to(&"gentleman")
	assert_ne(_quote(4), "")
	assert_eq(_said(), _quote(4), "§15.6.4")
	assert_eq(_speakers[0], "Gentleman")


func test_the_scope_sign_blocks_and_is_read_from_41_11() -> void:
	await _start(&"lavender_town", &"from_route_10", Vector2i(22, 0), Vector2i.DOWN)
	var plan := PlanGrid.new()
	assert_true(plan.load_file(TOWN_PLAN), plan.error)
	var spot := plan.cell_of("panneau_scope_j19")
	assert_eq(spot, Vector2i(42, 11))
	var map := _boot.get_map()
	assert_true(map.get_grid().is_solid(spot), "panneau bloquant")
	assert_true(map.get_grid().is_free(spot + Vector2i.LEFT), "case de lecture libre")
	map.spawn_player_at(_player, Vector2i(41, 11), Vector2i.RIGHT)
	await wait_process_frames(3)
	_pages.clear()
	await _press_interact()
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _finish()
	assert_ne(_quote(5), "")
	assert_eq(_said(), _quote(5), "§15.6.5")


func test_the_legend_of_the_tower_is_unchanged_15_6_6() -> void:
	var dialogue := DialogueLibrary.new()
	dialogue.load_dir()
	var sign: Dialogue = dialogue.get_dialogue(&"lavender_tower_sign")
	assert_eq(sign.variants.size(), 1)
	assert_eq(sign.variants[0].pages[0].text, "TOUR POKÉMON\nIci reposent les Pokémon aimés.")


func test_the_word_rocket_appears_in_no_text_added_by_j19() -> void:
	for path: String in FILES:
		var text := FileAccess.get_file_as_string(path).to_lower()
		assert_gt(text.length(), 0, path)
		assert_false(text.contains("rocket"), path)
