extends GutTest
## Les réglages agissent dans le jeu (jalon-06.md §6.12, T29) avec le vrai Boot, des fichiers
## en mémoire (réglages et sauvegarde séparés) et l'écran factice : lecture au démarrage,
## réécriture à chaque changement, profil graphique, vibrations, vitesse du texte (dialogues
## seulement, Q-20), réduction des animations, « Sauvegarder maintenant ».

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t29_save.json"
const SETTINGS_PATH := "user://test_t29_settings.json"
const STRONG_DEVICE := {"processors": 8, "memory_mb": 8192}

var _fs: MemoryFs
var _boot: Boot
var _menu: MenuDirector
var _screen: Node
var _vibrations: Array[int] = []


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-10-04T10:00:00")
	_fs = MemoryFs.new()
	_vibrations = []


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	UiPrefs.reset()
	Engine.max_fps = 0


## [param initial] : réglages déjà dans le fichier (null = premier lancement).
func _start(initial: GameSettings = null) -> void:
	if initial != null:
		SettingsStore.new(_fs, SETTINGS_PATH).save_settings(initial)
		_fs.journal.clear()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.device = STRONG_DEVICE
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	await wait_process_frames(2)


func _stored() -> GameSettings:
	return SettingsStore.new(_fs, SETTINGS_PATH).load_settings()


func _writes_to(path: String) -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + path):
			count += 1
	return count


# --- Lecture et écriture ------------------------------------------------------------------

func test_settings_are_read_at_start_and_applied() -> void:
	var s := GameSettings.new()
	s.text_speed = GameSettings.TextSpeed.FAST
	s.haptics = false
	s.graphics = GameSettings.Graphics.ECO
	await _start(s)
	assert_true(_boot.get_settings().equals(s))
	assert_eq(_boot.get_dialogue_runner().chars_per_second, 90.0)
	assert_false(Haptics.enabled)
	assert_eq(Engine.max_fps, 30)


func test_first_launch_uses_the_defaults_and_writes_nothing() -> void:
	await _start(null)
	assert_true(_boot.get_settings().equals(GameSettings.new()))
	assert_eq(_writes_to(SETTINGS_PATH), 0, "rien d'écrit avant un changement")
	assert_eq(Engine.max_fps, 0)


func test_a_change_rewrites_the_settings_file_and_not_the_save() -> void:
	await _start(null)
	var saves := _writes_to(SAVE_PATH)
	assert_true(_menu.change_setting(GameSettings.TEXT_SPEED, GameSettings.TextSpeed.SLOW))
	assert_eq(_writes_to(SETTINGS_PATH), 1)
	assert_eq(_stored().text_speed, GameSettings.TextSpeed.SLOW)
	assert_eq(_writes_to(SAVE_PATH), saves, "la sauvegarde n'est pas touchée")
	assert_eq(_boot.get_dialogue_runner().chars_per_second, 25.0)
	assert_false(_menu.change_setting(GameSettings.TEXT_SPEED, GameSettings.TextSpeed.SLOW),
		"même valeur : rien")
	assert_eq(_writes_to(SETTINGS_PATH), 1)


func test_the_settings_survive_a_restart() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.LEFT_HANDED, true)
	_menu.change_setting(GameSettings.CONFIRM_ACTIONS, true)
	_boot.free()
	await _start(null)
	assert_true(_boot.get_settings().left_handed)
	assert_true(_boot.get_battle_director().confirm_forget)


func test_under_gut_boot_opens_no_real_settings_file() -> void:
	var boot := BOOT_SCENE.instantiate() as Boot
	add_child_autofree(boot)
	assert_null(boot.settings_store)
	assert_false(FileAccess.file_exists(SettingsStore.DEFAULT_PATH))


func test_changing_a_setting_shows_a_new_view() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.HIGH_CONTRAST, true)
	assert_eq(_screen.settings_views.size(), 1)
	var view: SettingControlView = _screen.settings_views[0].control(GameSettings.HIGH_CONTRAST)
	assert_true(view.value)


func test_the_settings_route_shows_the_settings_view() -> void:
	await _start(null)
	assert_true(_menu.open(MenuRoute.settings()))
	assert_eq(_screen.settings_views.size(), 1)
	assert_false(_screen.placeholders.has(MenuRoute.SETTINGS), "plus l'écran provisoire")
	_menu.close()


# --- Graphismes ---------------------------------------------------------------------------

func test_eco_limits_fps_and_cuts_the_blur_and_high_restores_them() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.GRAPHICS, GameSettings.Graphics.ECO)
	assert_eq(Engine.max_fps, 30)
	assert_false(_boot.get_battle_stage().backdrop_blur)
	assert_false(_boot.get_graphics_profile().menu_blur)
	_menu.change_setting(GameSettings.GRAPHICS, GameSettings.Graphics.HIGH)
	assert_eq(Engine.max_fps, 0)
	assert_true(_boot.get_battle_stage().backdrop_blur)
	assert_true(_boot.get_graphics_profile().menu_blur)


func test_auto_follows_the_device() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.device = {"processors": 4, "memory_mb": 3000}
	add_child_autofree(_boot)
	assert_eq(Engine.max_fps, 30, "appareil modeste : Économie")
	assert_eq(_boot.get_graphics_profile().quality, GameSettings.Graphics.ECO)


func test_the_view_knows_the_device_quality() -> void:
	await _start(null)
	_menu.open(MenuRoute.settings())
	var view: SettingControlView = _screen.settings_views[0].control(GameSettings.GRAPHICS)
	assert_true(view.value_text.contains("Élevée"), view.value_text)
	_menu.close()


# --- Vibrations, texte, animations ----------------------------------------------------------

func test_haptics_off_means_no_vibration_at_all() -> void:
	await _start(null)
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)
	Haptics.vibrate(40)
	assert_eq(_vibrations.size(), 1)
	_menu.change_setting(GameSettings.HAPTICS, false)
	Haptics.vibrate(40)
	assert_eq(_vibrations.size(), 1, "aucun nouvel appel au sink")


func test_text_speed_rules_dialogues_only() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.TEXT_SPEED, GameSettings.TextSpeed.INSTANT)
	assert_eq(_boot.get_dialogue_runner().chars_per_second, 0.0)
	assert_eq(_boot.get_battle_director().speed_scale, 1.0)
	assert_eq(_boot.get_battle_hud().message_hold_scale, 1.0)


func test_reduced_motion_speeds_up_animations_but_not_message_holds() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.REDUCE_MOTION, true)
	assert_almost_eq(_boot.get_battle_director().speed_scale, 0.6, 0.0001)
	assert_almost_eq(_boot.get_trainer_menu().speed_scale, 0.5, 0.0001)
	assert_eq(_boot.get_battle_hud().message_hold_scale, 1.0)
	_boot.get_battle_hud().speed_scale = 0.6
	assert_eq(_boot.get_battle_hud().get_message_banner().hold_scale, 1.0)
	_menu.change_setting(GameSettings.REDUCE_MOTION, false)
	assert_eq(_boot.get_battle_director().speed_scale, 1.0)


func test_reduce_flashes_reaches_the_stage() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.REDUCE_FLASHES, true)
	assert_true(_boot.get_battle_stage().reduce_flashes)


func test_ui_prefs_follow_the_settings() -> void:
	await _start(null)
	_menu.change_setting(GameSettings.HIGH_CONTRAST, true)
	assert_true(UiPrefs.high_contrast)


# --- Sauvegarder maintenant -------------------------------------------------------------------

func test_save_now_writes_the_save_and_reports_the_result() -> void:
	await _start(null)
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)
	var before := _writes_to(SAVE_PATH)
	_menu.open()
	_screen.save_now_requested.emit()
	assert_eq(_writes_to(SAVE_PATH), before + 1)
	assert_eq(_screen.save_results.size(), 1)
	assert_true(_screen.save_results[0].begins_with(SettingsViews.SAVE_DONE_TEXT),
		_screen.save_results[0])
	_menu.close()


func test_save_now_is_disabled_after_a_debug_start() -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.force_debug_start = true
	_boot.debug_start_path = "res://tests/fixtures/debug_start/valid.json"
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	await wait_process_frames(2)
	assert_false(_boot.is_autosave_enabled())
	_menu.request_save()
	assert_eq(_screen.save_results.size(), 1)
	assert_eq(_screen.save_results[0], SettingsViews.SAVE_DISABLED_TEXT)
	assert_eq(_writes_to(SAVE_PATH), 0)
	# Les réglages, eux, fonctionnent malgré le départ de débogage (§5.3).
	_menu.change_setting(GameSettings.HAPTICS, false)
	assert_eq(_writes_to(SETTINGS_PATH), 1)
