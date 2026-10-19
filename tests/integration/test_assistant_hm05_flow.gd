extends GutTest
## L'assistant de Chen et la CS05 de bout en bout (jalon-17.md §2.6, T19 ; dossier 20 §8) avec la
## vraie scène Boot, la vraie pièce `route_2_east_gate`, les vraies données (dialogue, scène,
## objet), les vraies entrées (`move_*`, `interact`) et une sauvegarde en mémoire :
## - moins de 10 espèces : T-1 (première visite, `hm05_assistant_met`) puis T-2 à chaque visite,
##   aucune CS05 ;
## - 10 espèces ou plus (dont par une évolution, ou après avoir relâché toute l'équipe) : T-3, la
##   CS05 au Sac, `got_hm05` ; une seule remise (T-4 ensuite, scène rejouée : rien de plus) ;
## - application tuée pendant la remise : rien n'est écrit tant que la partie n'est pas stable
##   (objet et drapeau changent dans la même scène, la sauvegarde arrive après).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const NINE := "res://tools/debug_start/route_2_east.json"
const TEN := "res://tools/debug_start/route_2_east_10.json"
const SAVE_PATH := "user://test_assistant_hm05_flow_save.json"
const POST := &"route_2_east_gate"
const DATE := "2026-10-15T18:00:00"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 60000
const WALK_STOP := &"test_walk_stop"
const ENTRANCE := Vector2i(7, 8)
## Case d'où l'on parle à l'assistant (8, 5), tourné ↑.
const TALK_CELL := Vector2i(8, 6)
const FIRST_MEETING: Array[String] = [
	"Je suis un assistant du Professeur Chen.",
	"Il m'a confié quelque chose pour toi.",
	"Mais il faut d'abord avoir capturé 10 espèces.",
	"Ton Pokédex en compte 9. Reviens me voir !",
]
const REMINDER: Array[String] = [
	"Ton Pokédex compte 9 espèces capturées.",
	"Encore 1, et c'est à toi.",
]
const GIVING: Array[String] = [
	"Ton Pokédex compte 10 espèces !",
	"Le Professeur Chen sera ravi.",
	"Voici la CS05 : Flash.",
	"Kevin reçoit la CS05 — Flash !",
	"Flash éclaire les grottes les plus sombres.",
	"Il suffit d'avoir dans ton équipe un Pokémon capable de l'utiliser.",
]
const AFTER: Array[String] = [
	"Avec Flash, plus besoin d'avancer à tâtons.",
	"Continue de remplir ton Pokédex !",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	GameState.pokedex.clear()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(start_path: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = POST
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.player_name = "Kevin"
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, POST)
	assert_eq(_player.get_cell(), ENTRANCE)
	await _walk(Vector2i.UP, Vector2i(7, 6))
	await _walk(Vector2i.RIGHT, TALK_CELL)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Parle à l'assistant et déroule tout ; renvoie les pages lues, dans l'ordre. [param during]
## (facultatif) est appelé à chaque image où la scène tourne.
func _talk(during: Callable = Callable()) -> Array[String]:
	assert_eq(_player.get_cell(), TALK_CELL, "devant l'assistant")
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var pages: Array[String] = []
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or box.is_open()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_open():
			var text := box.get_text()
			if pages.is_empty() or pages.back() != text:
				pages.append(text)
			if during.is_valid():
				during.call()
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_process_frames(3)
	return pages


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _saved_has_hm05() -> bool:
	return _fs.files.get(SAVE_PATH, "").contains("hm05")


func test_the_nine_species_start_is_nine() -> void:
	await _start(NINE)
	assert_eq(GameState.pokedex.caught_count(), 9)
	assert_push_error_count(0)


func test_under_ten_species_first_meeting_then_the_reminder() -> void:
	await _start(NINE)
	var first := await _talk()
	assert_eq(first, FIRST_MEETING, "T-1 à la première visite")
	assert_true(GameState.flags.has_flag(&"hm05_assistant_met"))
	var second := await _talk()
	assert_eq(second, REMINDER, "T-2 ensuite, à chaque visite")
	var third := await _talk()
	assert_eq(third, REMINDER)
	assert_eq(GameState.bag.count_of(&"hm05"), 0, "aucune CS05")
	assert_false(GameState.flags.has_flag(&"got_hm05"))
	assert_push_error_count(0)


func test_ten_species_give_the_hm_once() -> void:
	await _start(TEN)
	assert_eq(GameState.pokedex.caught_count(), 10)
	var pages := await _talk()
	assert_eq(pages, GIVING, "T-3 : trois bulles, la CS05, deux bulles")
	assert_eq(GameState.bag.count_of(&"hm05"), 1, "CS05 au Sac")
	assert_true(GameState.flags.has_flag(&"got_hm05"))
	var again := await _talk()
	assert_eq(again, AFTER, "T-4 ensuite")
	assert_eq(GameState.bag.count_of(&"hm05"), 1, "une seule CS05")
	# La scène rejouée après coup ne donne rien de plus (étapes `unless got_hm05`).
	var director := _boot.get_cutscene_director()
	director.play(&"route_2_east_give_hm05")
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	assert_eq(GameState.bag.count_of(&"hm05"), 1, "jamais deux CS05")
	assert_push_error_count(0)


func test_the_tenth_species_by_evolution_gives_the_hm() -> void:
	await _start(NINE)
	var first := await _talk()
	assert_eq(first, FIRST_MEETING)
	GameState.record_evolved(&"pidgeotto")
	assert_eq(GameState.pokedex.caught_count(), 10, "une évolution compte")
	var pages := await _talk()
	assert_eq(pages, GIVING, "la remise, même après la première rencontre")
	assert_eq(GameState.bag.count_of(&"hm05"), 1)
	assert_push_error_count(0)


func test_releasing_everyone_does_not_take_the_hm_back() -> void:
	await _start(TEN)
	while GameState.party.size() > 1:
		GameState.party.remove_at(GameState.party.size() - 1)
	GameState.storage.clear()
	assert_eq(GameState.pokedex.caught_count(), 10, "relâcher ne retire rien du Pokédex")
	var pages := await _talk()
	assert_eq(pages, GIVING)
	assert_eq(GameState.bag.count_of(&"hm05"), 1)
	assert_push_error_count(0)


## Application tuée pendant la remise : tant que la scène tourne, la partie n'est pas stable, donc
## rien n'est écrit (la sauvegarde d'avant reste) ; objet et drapeau changent dans la même scène,
## et la sauvegarde qui suit les contient tous les deux.
func test_the_save_is_never_written_in_the_middle_of_the_handing_over() -> void:
	await _start(TEN)
	var probes: Array[bool] = []
	var during := func() -> void:
		_boot.request_autosave("test : milieu de la remise")
		probes.append(_saved_has_hm05())
	var pages := await _talk(during)
	assert_eq(pages, GIVING)
	assert_gt(probes.size(), 3, "sondé à chaque bulle")
	for found: bool in probes:
		assert_false(found, "rien d'écrit pendant la remise (état d'avant)")
	await wait_until(func() -> bool: return _saved_has_hm05(), TIMEOUT)
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("got_hm05"), "drapeau écrit")
	assert_true(_saved_has_hm05(), "CS05 écrite avec lui")
	assert_eq(GameState.bag.count_of(&"hm05"), 1)
	assert_push_error_count(0)
