extends GutTest
## Porte de l'Arène de Jadielle (jalon 28, `docs/tech/jalon-28.md` §2.3, §5) avec la vraie scène
## Boot, la vraie carte `viridian_city` et le vrai SceneRouter (fondus raccourcis) :
## - sans `silph_giovanni_defeated` (tous les autres Badges sauf Marais et Volcan, qui n'existent
##   pas encore) : pousser ↑ ne change pas de carte, l'examen donne « La porte est verrouillée. » ;
## - avec le drapeau (sans `badge_soul`, `badge_marsh`, `badge_volcano`) : pousser ↑ mène à
##   `viridian_gym` sur `entrance` ; sortir (PUSH ↓) ramène à `viridian_city` / `from_gym` ;
## - guetteur `gym_watcher` : trois textes selon les drapeaux (T28-01, T28-02, texte du J7).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/viridian_locked.json"
const SAVE_PATH := "user://test_viridian_gym_door_save.json"
const CITY := &"viridian_city"
const GYM := &"viridian_gym"
const FADE := 0.05
const TIMEOUT := 12.0
const FROM_GYM := Vector2i(9, 10)
const GYM_ENTRANCE := Vector2i(18, 20)
const OPEN := &"silph_giovanni_defeated"
const LOCKED_TEXT := "La porte est verrouillée."
const WATCHER_CLOSED := "Encore fermée… Je me demande où est passé le Champion."
const WATCHER_OPEN := "La porte de l'Arène est ouverte ! Le Champion serait revenu…"
const WATCHER_GONE := "Le Champion est reparti. Personne ne sait où."
const MISSING_BADGES: Array[StringName] = [&"badge_soul", &"badge_marsh", &"badge_volcano"]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T10:00:00")
	_fs = MemoryFs.new()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)


## Boot sur Jadielle, sur `from_gym` tourné ↑, partie de `viridian_locked` (Sylphe non libérée,
## tous les autres Badges sauf Marais et Volcan) ; [param open] pose `silph_giovanni_defeated`.
func _start(open: bool) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = CITY
	_boot.start_spawn = &"from_gym"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	for flag: StringName in MISSING_BADGES + [OPEN]:
		GameState.flags.set_flag(flag, false)
	if open:
		GameState.flags.set_flag(OPEN)
	await wait_process_frames(2)
	# Les passages et points d'examen sont posés selon les drapeaux au chargement : on recharge.
	await SceneRouter.change_map(CITY, &"from_gym", Vector2i.UP)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(_player.get_cell(), FROM_GYM)
	assert_eq(GameState.flags.has_flag(OPEN), open)
	for flag: StringName in MISSING_BADGES:
		assert_false(GameState.flags.has_flag(flag), "%s : n'existe pas encore" % flag)
	assert_true(GameState.flags.has_flag(&"badge_rainbow"), "les autres Badges sont là")


func _press(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await wait_process_frames(frames)
	Input.action_release(action)


## Pousse [param action] jusqu'à ce que la carte soit [param map] (faux au bout du délai).
func _push_until(action: StringName, map: StringName, seconds: float) -> bool:
	Input.action_press(action)
	await wait_until(func() -> bool:
		return _boot.get_map().map_id == map and not SceneRouter.is_transitioning(), seconds)
	Input.action_release(action)
	await wait_process_frames(3)
	return _boot.get_map().map_id == map


func test_the_door_is_closed_without_the_flag_and_answers_when_examined() -> void:
	await _start(false)
	var changed := await _push_until(&"move_up", GYM, 1.5)
	assert_false(changed, "la porte ne s'ouvre pas")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(_player.get_cell(), FROM_GYM, "le joueur n'a pas bougé")
	assert_false(SceneRouter.is_transitioning())
	_player.face(Vector2i.UP)
	var box := _boot.get_dialogue_box()
	await _press(&"interact", 2)
	await wait_until(func() -> bool: return box.is_open(), TIMEOUT)
	assert_true(box.is_open(), "l'examen répond")
	assert_eq(box.get_text().replace("\n", " "), LOCKED_TEXT)
	assert_push_error_count(0)


func test_the_door_opens_with_the_flag_even_without_the_last_badges() -> void:
	await _start(true)
	assert_true(await _push_until(&"move_up", GYM, TIMEOUT), "porte ouverte")
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), GYM_ENTRANCE, "sur « entrance »")
	assert_eq(_player.get_facing(), Vector2i.UP)
	for flag: StringName in MISSING_BADGES:
		assert_false(GameState.flags.has_flag(flag), flag)
	assert_push_error_count(0)


func test_the_gym_exit_leads_back_to_the_city_door() -> void:
	await _start(true)
	assert_true(await _push_until(&"move_up", GYM, TIMEOUT))
	assert_true(await _push_until(&"move_down", CITY, TIMEOUT), "sortie par le bas")
	assert_eq(_boot.get_map().map_id, CITY)
	assert_eq(_player.get_cell(), FROM_GYM, "retour sur from_gym")
	# Toujours ouverte : on peut y retourner.
	assert_true(await _push_until(&"move_up", GYM, TIMEOUT), "ouverte pour toujours")
	assert_push_error_count(0)


func test_the_door_examine_point_disappears_once_open() -> void:
	await _start(true)
	_player.face(Vector2i.UP)
	var box := _boot.get_dialogue_box()
	await _press(&"interact", 2)
	await wait_process_frames(3)
	assert_false(box.is_open(), "plus de « porte verrouillée »")


# --- Guetteur ---------------------------------------------------------------------------------

func test_the_watcher_has_three_texts_by_flags() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var dialogue := library.get_dialogue(&"viridian_gym_watcher")
	assert_not_null(dialogue)
	assert_eq(dialogue.speaker, "Habitant")
	assert_eq(dialogue.variants.size(), 3)
	var cases: Array = [
		[[] as Array[StringName], WATCHER_CLOSED],
		[[OPEN] as Array[StringName], WATCHER_OPEN],
		[[OPEN, &"badge_earth"] as Array[StringName], WATCHER_GONE],
		[[&"badge_earth"] as Array[StringName], WATCHER_GONE],
	]
	for entry: Array in cases:
		var flags := StoryFlags.new()
		for flag: StringName in entry[0]:
			flags.set_flag(flag)
		var variant := dialogue.pick(flags)
		assert_not_null(variant, "variante pour %s" % [entry[0]])
		if variant != null:
			assert_eq(variant.pages.size(), 1)
			assert_eq(variant.pages[0].text, entry[1], "drapeaux %s" % [entry[0]])


func test_the_watcher_stands_in_the_city_and_speaks_by_flags() -> void:
	await _start(true)
	var watcher := _boot.get_map().get_npc(&"gym_watcher")
	assert_not_null(watcher, "guetteur en ville")
	if watcher != null:
		assert_eq(watcher.get_spec().dialogue, &"viridian_gym_watcher")
