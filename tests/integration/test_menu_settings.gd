extends GutTest
## Le directeur et les Paramètres (jalon-06.md §6.12, T29) avec l'écran factice : un geste
## valide émet `settings_changed` puis une vue neuve, un geste refusé n'émet rien ; sans
## réglages branchés, la route reste l'écran provisoire. Le test avec le vrai écran (toucher →
## fichier écrit → effet) suit la fusion du T28.

const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")


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
