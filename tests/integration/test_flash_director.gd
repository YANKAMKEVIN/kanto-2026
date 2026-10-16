extends GutTest
## Mise en scène automatique de Flash dans le vrai Boot (jalon 17 T24 ; dossier 20 H-7, Q-1
## « tout J17 » ; `jalon-17.md` §2.11, contrat du J18 §3.3), sur la carte de QA `qa_flash`
## (PROVISOIRE, retirée au T28 avec ce test et les départs `flash_qa*`) : une fois par arrivée,
## rallumée à chaque retour et à la reprise dans la grotte (aucun drapeau), avertissement sans
## CS05 ou sans compatible, K.O. accepté, durée au pas près.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const DIR := "res://tools/debug_start/"
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _fades: Array[float] = []
var _clock: TweenClock


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")
	_clock = null


func after_each() -> void:
	if _clock != null:
		_clock.release()
	for action: StringName in [&"move_up", &"move_down", &"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _start(start_name: String, path: String = "") -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_flash_director_save.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = path if not path.is_empty() else DIR + start_name + ".json"
	add_child_autofree(_boot)
	await wait_process_frames(2)
	await _settle()


## Partie stable, sans action de Flash en attente (l'avertissement fermé au besoin).
func _settle() -> void:
	var flash := _boot.get_flash_director()
	await wait_until(func() -> bool: return not flash.is_pending() and _boot.is_stable() \
		or _boot.get_dialogue_runner().is_running(), TIMEOUT)


## Un pas vers [param direction] et l'arrivée sur [param map_id] (dialogue d'avertissement
## éventuel ouvert, ou mise en scène terminée).
func _walk_to(direction: Vector2i, map_id: StringName) -> void:
	assert_true(_boot.get_player().script_step(direction), "pas %s" % direction)
	await wait_until(func() -> bool: return _boot.get_map().map_id == map_id \
		and not SceneRouter.is_transitioning(), TIMEOUT)
	await wait_process_frames(2)
	await _settle()


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")


func _caption_text() -> String:
	var caption := _boot.get_hud().find_child("WorldCaption", true, false) as Label
	return caption.text if caption != null else ""


# --- Avec Flash --------------------------------------------------------------------------------

func test_flash_plays_once_per_entry_and_relights_on_return() -> void:
	await _start("flash_qa")
	var flash := _boot.get_flash_director()
	var darkness := _boot.get_darkness()
	assert_eq(_boot.get_map().map_id, &"qa_flash_entry")
	assert_true(flash.is_available(), "CS05 au Sac, Pikachu compatible")
	assert_eq(flash.get_cue_count(), 0, "pièce éclairée : rien")
	# Pendant la mise en scène (relevé dans le signal) : joueur bloqué, voile sombre.
	var seen := {}
	flash.cue_started.connect(func() -> void:
		seen["locked"] = _boot.get_player().is_blocked_by(FlashDirector.LOCK_REASON)
		seen["stable"] = _boot.is_stable()
		seen["dark"] = darkness.is_dark() and not darkness.is_lit()
		seen["controls"] = _boot.get_hud().are_controls_visible(), CONNECT_ONE_SHOT)
	var banners: Array[String] = []
	flash.flash_used.connect(func(_map_id: StringName) -> void:
		banners.append(_caption_text()))
	assert_true(_boot.get_player().script_step(Vector2i.UP))
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_flash" \
		and flash.get_cue_count() == 1 and not flash.is_running() and _boot.is_stable(), TIMEOUT)
	assert_eq(seen, {"locked": true, "stable": false, "dark": true, "controls": false})
	assert_eq(flash.get_cue_count(), 1, "une fois par arrivée")
	assert_true(darkness.is_lit(), "halo de Flash ouvert")
	assert_eq(banners, ["Pikachu utilise Flash !"] as Array[String], "T-17, le compagnon")
	assert_false(_boot.get_player().is_blocked_by(FlashDirector.LOCK_REASON))
	assert_null(flash.get_cameo(), "Pokémon montré rentré à la fin")
	assert_false(GameState.flags.has_flag(&"qa_flash_lit"), "aucun drapeau « allumée »")
	# Sortie, puis retour : Flash se rallume, une seconde fois seulement.
	await _walk_to(Vector2i.DOWN, &"qa_flash_entry")
	assert_false(darkness.is_dark())
	assert_eq(flash.get_cue_count(), 1)
	await _walk_to(Vector2i.UP, &"qa_flash")
	await wait_until(func() -> bool: return not flash.is_running() and _boot.is_stable(),
		TIMEOUT)
	assert_eq(flash.get_cue_count(), 2, "rallumée à chaque arrivée")
	assert_true(darkness.is_lit())


## Durée au pas près : apparition + un éclair + ouverture du halo (≈ 1,2 s), une image de plus
## au plus par enchaînement ; une image de moins tolérée (l'horloge simulée naît sur le signal
## `cue_started`, parfois une image après le premier tween : vu une fois en suite complète, 83 / 84).
func test_cue_duration_in_simulated_time() -> void:
	await _start("flash_qa")
	var flash := _boot.get_flash_director()
	flash.cue_started.connect(func() -> void: _clock = TweenClock.new(get_tree()),
		CONNECT_ONE_SHOT)
	assert_true(_boot.get_player().script_step(Vector2i.UP))
	await wait_until(func() -> bool: return _clock != null, TIMEOUT)
	var steps := _clock.run_until(func() -> bool: return not flash.is_running(), 5.0)
	var expected := FlashDirector.APPEAR + ScreenFlash.duration_of(1, false) \
		+ _boot.get_darkness().get_profile().open_duration
	var min_steps := ceili(expected / TweenClock.STEP - 0.001)
	assert_between(steps, min_steps - 1, min_steps + 3, "≈ %.2f s" % expected)
	assert_true(_boot.get_darkness().is_lit())


## Reprise dans la grotte (départ posé dans `qa_flash`) : Flash se rallume comme à une arrivée.
func test_starting_inside_the_cave_relights() -> void:
	var start: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "flash_qa.json"))
	start["map"] = "qa_flash"
	start["spawn"] = "from_qa_flash_entry_w"
	var path := "user://test_flash_director_inside.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(start))
	file.close()
	await _start("", path)
	DirAccess.remove_absolute(path)
	var flash := _boot.get_flash_director()
	await wait_until(func() -> bool: return flash.get_cue_count() == 1 \
		and not flash.is_running(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"qa_flash")
	assert_true(_boot.get_darkness().is_lit())


## Seul compatible K.O. (sans compagnon) : Flash quand même, Pikachu sort de sa Ball à côté du
## joueur (derrière, sinon sur un côté : l'entrée est au bord de la carte) le temps de la scène.
func test_fainted_user_still_lights_and_shows_up() -> void:
	await _start("flash_qa_ko")
	var flash := _boot.get_flash_director()
	var cameo := {}
	flash.cue_started.connect(func() -> void:
		var shown := flash.get_cameo()
		cameo["species"] = shown.get_species() if shown != null else &""
		cameo["cell"] = shown.get_cell() if shown != null else Vector2i(-1, -1)
		cameo["distance"] = (_boot.get_player().get_cell() - cameo["cell"]).length_squared(),
		CONNECT_ONE_SHOT)
	var banners: Array[String] = []
	flash.flash_used.connect(func(_map_id: StringName) -> void:
		banners.append(_caption_text()))
	await _walk_to(Vector2i.UP, &"qa_flash")
	await wait_until(func() -> bool: return flash.get_cue_count() == 1 \
		and not flash.is_running(), TIMEOUT)
	assert_eq(cameo.get("species"), &"pikachu")
	assert_eq(cameo.get("distance"), 1, "à côté du joueur (derrière s'il le peut)")
	assert_null(flash.get_cameo(), "rentré dans sa Ball à la fin")
	assert_eq(banners, ["Pikachu utilise Flash !"] as Array[String])
	assert_true(_boot.get_darkness().is_lit())


# --- Sans Flash --------------------------------------------------------------------------------

func test_without_hm05_a_warning_once_per_entry() -> void:
	await _start("flash_qa_no_hm")
	await _check_warning()


func test_without_compatible_pokemon_a_warning() -> void:
	await _start("flash_qa_no_pokemon")
	await _check_warning()


func _check_warning() -> void:
	var flash := _boot.get_flash_director()
	var runner := _boot.get_dialogue_runner()
	assert_false(flash.is_available())
	await _walk_to(Vector2i.UP, &"qa_flash")
	assert_true(runner.is_running(), "avertissement")
	assert_eq(runner.get_dialogue_id(), FlashDirector.WARN_DIALOGUE)
	assert_eq(runner.get_session().get_page().text,
		"Il fait très sombre ici… Mieux vaut avancer prudemment.", "T-3 du dossier 21")
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_eq(flash.get_cue_count(), 0, "pas de mise en scène")
	assert_true(_boot.get_darkness().is_dark())
	assert_false(_boot.get_darkness().is_lit(), "halo sombre")
	# Un pas dans la grotte : pas de nouvel avertissement.
	assert_true(_boot.get_player().script_step(Vector2i.RIGHT))
	await wait_process_frames(30)
	assert_false(runner.is_running(), "une fois par arrivée")
