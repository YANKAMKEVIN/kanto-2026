extends GutTest
## Le directeur et les Paramètres (jalon-06.md §6.12, T29) avec l'écran factice : un geste
## valide émet `settings_changed` puis une vue neuve, un geste refusé n'émet rien ; sans
## réglages branchés, la route reste l'écran provisoire. Le test avec le vrai écran (toucher →
## fichier écrit → effet) suit la fusion du T28.

const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SETTINGS_PATH := "user://test_t29b_settings.json"
const SAVE_PATH := "user://test_t29b_save.json"


func _director(with_settings: bool) -> MenuDirector:
	GameState.new_game()
	var director := MenuDirector.new()
	add_child_autofree(director)
	director.setup(GameState, PokemonData.new(), ZoneLibrary.new(), ObjectiveLibrary.new(),
		MenuUnlocks.new(GameState.flags, GameState.party), func() -> bool: return true)
	if with_settings:
		director.set_settings(GameSettings.new(), GameSettings.Graphics.HIGH, true)
	return director


func test_a_valid_change_emits_the_settings_then_a_fresh_view() -> void:
	var director := _director(true)
	var order: Array[String] = []
	director.settings_changed.connect(func(_s: GameSettings) -> void: order.append("changed"))
	director.settings_shown.connect(func(_v: SettingsView) -> void: order.append("shown"))
	assert_true(director.change_setting(GameSettings.LEFT_HANDED, true))
	assert_eq(order, ["changed", "shown"] as Array[String])


func test_a_refused_change_emits_nothing() -> void:
	var director := _director(true)
	watch_signals(director)
	assert_false(director.change_setting(GameSettings.TEXT_SPEED, 99), "valeur hors énumération")
	assert_false(director.change_setting(&"nope", true), "réglage inconnu")
	assert_false(director.change_setting(GameSettings.HAPTICS, true), "même valeur")
	assert_signal_not_emitted(director, "settings_changed")
	assert_signal_not_emitted(director, "settings_shown")


func test_changes_are_not_game_changes() -> void:
	var director := _director(true)
	var closed: Array[bool] = []
	director.menu_closed.connect(func(changed: bool) -> void: closed.append(changed))
	director.open(MenuRoute.settings())
	director.change_setting(GameSettings.HIGH_CONTRAST, true)
	director.close()
	assert_eq(closed, [false] as Array[bool], "aucun autosave pour un réglage")


func test_without_settings_the_route_stays_a_placeholder() -> void:
	var director := _director(false)
	var screen: Node = autofree(FakeMenu.new())
	screen.wire(director)
	director.open(MenuRoute.settings())
	assert_true(screen.placeholders.has(MenuRoute.SETTINGS))
	assert_true(screen.settings_views.is_empty())
	director.close()
	assert_false(director.change_setting(GameSettings.HAPTICS, false))


# --- Avec le vrai écran (T28) : toucher → fichier réécrit → effet ------------------------------

var _fs: MemoryFs
var _boot: Boot


func after_each() -> void:
	get_tree().paused = false
	Haptics.reset()
	UiPrefs.reset()
	Engine.max_fps = 0


## Vrai Boot et vrai écran, ouvert sur les Paramètres, catégorie [param category].
func _open_real(category: StringName) -> SettingsScreen:
	_fs = MemoryFs.new()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.device = {"processors": 8, "memory_mb": 8192}
	add_child_autofree(_boot)
	_boot.get_trainer_menu().speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)
	assert_true(_boot.get_menu_director().open(MenuRoute.settings()))
	var screen := _boot.get_trainer_menu().get_settings()
	screen.get_category_buttons()[category].pressed.emit()
	await wait_process_frames(2)
	return screen


func _stored() -> GameSettings:
	return SettingsStore.new(_fs, SETTINGS_PATH).load_settings()


func test_real_screen_economy_choice() -> void:
	var screen := await _open_real(SettingsViews.CATEGORY_GRAPHICS)
	var row := screen.get_row(GameSettings.GRAPHICS) as SettingChoice
	# Auto → Élevée → Économie : une flèche par cran, la vue revient entre les deux.
	row.get_next_button().pressed.emit()
	assert_eq(_stored().graphics, GameSettings.Graphics.HIGH)
	(screen.get_row(GameSettings.GRAPHICS) as SettingChoice).get_next_button().pressed.emit()
	assert_eq(_stored().graphics, GameSettings.Graphics.ECO, "fichier réécrit")
	assert_eq(Engine.max_fps, 30)
	assert_false(_boot.get_trainer_menu().is_backdrop_blur_enabled(), "flou du menu coupé")
	assert_false(_boot.get_battle_stage().backdrop_blur)
	var again := screen.get_row(GameSettings.GRAPHICS) as SettingChoice
	assert_eq(again.get_selected_index(), 2, "l'écran montre la vue neuve")
	assert_eq(again.get_value_text(), "Économie")
	assert_true(again.get_next_button().disabled, "dernière option : › éteinte")
	again.get_prev_button().pressed.emit()
	assert_eq(Engine.max_fps, 0)
	assert_true(_boot.get_trainer_menu().is_backdrop_blur_enabled())


func test_real_screen_left_handed_reaches_the_hud() -> void:
	var screen := await _open_real(SettingsViews.CATEGORY_CONTROLS)
	(screen.get_row(GameSettings.LEFT_HANDED) as SettingToggle).pressed.emit()
	assert_true(_stored().left_handed)
	assert_true(_boot.get_hud().is_left_handed())
	(screen.get_row(GameSettings.BUTTON_SCALE) as SettingChoice).get_next_button().pressed.emit()
	assert_almost_eq(_boot.get_hud().get_button_scale(), 1.2, 0.001)


func test_real_screen_large_text_reaches_ui_prefs() -> void:
	var screen := await _open_real(SettingsViews.CATEGORY_ACCESSIBILITY)
	(screen.get_row(GameSettings.TEXT_SIZE) as SettingChoice).get_next_button().pressed.emit()
	assert_eq(_stored().text_size, GameSettings.TextSize.LARGE)
	assert_almost_eq(UiPrefs.text_scale, 1.15, 0.001)


func test_real_screen_save_now_shows_the_result() -> void:
	var screen := await _open_real(SettingsViews.CATEGORY_GAME)
	screen.get_action_button().pressed.emit()
	assert_true(screen.get_result_label().text.begins_with(SettingsViews.SAVE_DONE_TEXT),
		screen.get_result_label().text)
	assert_true(_fs.exists(SAVE_PATH), "la sauvegarde est écrite")
