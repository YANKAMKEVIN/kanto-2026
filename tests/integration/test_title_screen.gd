extends GutTest
## Écran titre (OUV.1, dossier 13 §5.2–§5.4, §7) : entrées et mise en avant selon l'état de la
## sauvegarde, carte Continuer (prénom, lieu, temps, badges, captures ; lignes vides omises),
## message d'état, un toucher = un signal, mode gaucher, confirmation à deux cartes, Paramètres
## hébergés sans « Sauvegarder maintenant », zones tactiles et marges à 1920 et 2340.

const SCENE := preload("res://game/ui/opening/title_screen.tscn")
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _texts := TitleTexts.new()
var _chosen: Array[StringName] = []
var _vibrations: Array[int] = []


func before_all() -> void:
	assert_true(_texts.load_file(), str(_texts.get_errors()))


func before_each() -> void:
	_chosen.clear()
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	Haptics.reset()
	UiPrefs.reset()


func _make_summary(badges: int = 1, pokedex: bool = true) -> SaveSummary:
	var summary := SaveSummary.new()
	summary.player_name = "Kevin"
	summary.map_id = &"viridian_forest"
	summary.zone_name = "Forêt de Jade"
	summary.play_time = 12 * 3600 + 43 * 60
	summary.badge_count = badges
	summary.caught_count = 23
	summary.pokedex_active = pokedex
	return summary


func _model(status: OpeningFlow.SaveStatus, summary: SaveSummary = null) -> TitleMenuModel:
	return TitleMenuModel.build(status, summary if summary != null else _make_summary(), _texts)


func _screen_in(model: TitleMenuModel, width: int = 2340) -> TitleScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var screen := SCENE.instantiate() as TitleScreen
	screen.speed_scale = 0.0
	viewport.add_child(screen)
	screen.show_title(model)
	screen.entry_chosen.connect(func(entry: StringName) -> void: _chosen.append(entry))
	await wait_process_frames(3)
	return screen


func test_no_save_features_new_game_without_continue_nor_message() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.NONE))
	assert_eq(screen.get_entries(), [&"new_game", &"settings"] as Array[StringName])
	assert_eq(screen.get_featured(), &"new_game")
	assert_eq(screen.get_message_text(), "")
	assert_eq(screen.get_texts(), PackedStringArray(["NOUVELLE PARTIE", "PARAMÈTRES"]))


func test_valid_save_features_continue_with_its_card() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID))
	assert_eq(screen.get_entries(), [&"continue", &"new_game", &"settings"] as Array[StringName])
	assert_eq(screen.get_featured(), &"continue")
	assert_eq(screen.get_entry_button(&"new_game").theme_type_variation, &"TitleCard",
		"Nouvelle partie secondaire")
	assert_eq(screen.get_texts(), PackedStringArray(["CONTINUER", "Kevin", "Forêt de Jade",
		"12 h 43", "1 badge", "23 capturés", "NOUVELLE PARTIE", "PARAMÈTRES"]))
	var card := screen.get_entry_button(&"continue")
	assert_gt(card.size.y, screen.get_entry_button(&"new_game").size.y, "la plus grande carte")
	assert_not_null(card.find_child("Bust", true, false), "buste du joueur")


func test_empty_summary_lines_are_omitted() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID, _make_summary(0, false)))
	var texts := screen.get_texts()
	assert_false(texts.has("0 badge"), "jamais « 0 badge »")
	assert_false(texts.has("23 capturés"), "captures seulement avec le Pokédex activé")
	assert_has(texts, "12 h 43")


func test_corrupt_and_newer_show_their_message_under_new_game() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.CORRUPT))
	assert_eq(screen.get_entries(), [&"new_game", &"settings"] as Array[StringName])
	assert_eq(screen.get_featured(), &"new_game")
	assert_eq(screen.get_message_text(),
		"La sauvegarde n'a pas pu être lue. Une copie a été mise de côté.")
	screen.show_title(_model(OpeningFlow.SaveStatus.NEWER))
	await wait_process_frames(2)
	assert_eq(screen.get_message_text(),
		"Cette sauvegarde vient d'une version plus récente du jeu. Elle n'a pas été modifiée.")
	assert_eq(screen.get_entries(), [&"new_game", &"settings"] as Array[StringName])


func test_one_touch_one_signal_with_a_vibration() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID))
	for entry: StringName in screen.get_entries():
		screen.get_entry_button(entry).pressed.emit()
	assert_eq(_chosen, [&"continue", &"new_game", &"settings"] as Array[StringName])
	assert_eq(_vibrations.size(), 3)


func test_no_entry_is_taken_under_the_confirmation_or_the_settings() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID))
	screen.show_confirm(ChoiceView.new("Une aventure est déjà en cours.", "Nouvelle partie",
		"Annuler"))
	screen.get_entry_button(&"continue").pressed.emit()
	screen.hide_confirm()
	screen.show_settings(SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH,
		false, false))
	screen.get_entry_button(&"new_game").pressed.emit()
	assert_eq(_chosen, [] as Array[StringName])


func test_confirmation_cards_answer_once() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID))
	var answers: Array[bool] = []
	screen.confirm_chosen.connect(func(confirmed: bool) -> void: answers.append(confirmed))
	screen.show_confirm(ChoiceView.new("Une aventure est déjà en cours.", "Nouvelle partie",
		"Annuler"))
	assert_true(screen.is_confirm_open())
	screen.get_confirm().get_confirm_button().pressed.emit()
	screen.get_confirm().get_confirm_button().pressed.emit()
	assert_eq(answers, [true] as Array[bool])
	assert_false(screen.is_confirm_open())


func test_settings_are_hosted_without_save_now_and_relay_changes() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID))
	var changes: Array = []
	var backs: Array[int] = [0]
	screen.setting_changed.connect(func(key: StringName, value: Variant) -> void:
		changes.append([key, value]))
	screen.settings_back_requested.connect(func() -> void: backs[0] += 1)
	screen.show_settings(SettingsViews.build(GameSettings.new(), GameSettings.Graphics.HIGH,
		false, false))
	await wait_process_frames(2)
	assert_true(screen.is_settings_open())
	assert_false(screen.get_column().visible, "la colonne laisse la place")
	var settings := screen.get_settings()
	assert_true(settings.visible)
	assert_null(settings.get_action_button(), "pas de « Sauvegarder maintenant »")
	assert_eq(settings.get_selected_category(), SettingsViews.CATEGORY_GAME)
	settings.setting_changed.emit(GameSettings.HAPTICS, false)
	settings.get_back_button().pressed.emit()
	assert_eq(changes, [[GameSettings.HAPTICS, false]])
	assert_eq(backs[0], 1)
	screen.hide_settings()
	assert_false(screen.is_settings_open())
	assert_true(screen.get_column().visible)


func test_left_handed_puts_the_column_left_and_the_logo_right() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID), width)
		var column := screen.get_column().get_global_rect()
		var logo := screen.get_logo().get_global_rect()
		assert_gt(column.position.x, width / 2.0, "colonne à droite à %d" % width)
		assert_lt(logo.end.x, width / 2.0, "logo à gauche à %d" % width)
		screen.set_left_handed(true)
		await wait_process_frames(2)
		column = screen.get_column().get_global_rect()
		logo = screen.get_logo().get_global_rect()
		assert_lt(column.end.x, width / 2.0, "colonne à gauche à %d" % width)
		assert_gt(logo.position.x, width / 2.0, "logo à droite à %d" % width)


func test_the_logo_sits_on_a_soft_shadow() -> void:
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.VALID), 1920)
	var logo := screen.get_logo()
	var shadow := logo.get_node(^"LogoShadow") as TextureRect
	assert_not_null(shadow, "ombre douce du logo (DAF.7b)")
	assert_true(shadow.show_behind_parent, "sous le logo")
	var drop := shadow.get_global_rect().position - logo.get_global_rect().position
	assert_almost_eq(drop.x, 0.0, 0.5)
	assert_gt(drop.y, 0.0, "décalée vers le bas")
	assert_eq(shadow.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_touch_zones_and_safe_margins_at_both_widths() -> void:
	for status: OpeningFlow.SaveStatus in [OpeningFlow.SaveStatus.VALID,
			OpeningFlow.SaveStatus.CORRUPT]:
		for width: int in WIDTHS:
			for left_handed: bool in [false, true]:
				var screen := await _screen_in(_model(status), width)
				screen.set_left_handed(left_handed)
				await wait_process_frames(2)
				var logo := screen.get_logo().get_global_rect()
				for entry: StringName in screen.get_entries():
					var rect := screen.get_entry_button(entry).get_global_rect()
					var label := "%s à %d (gaucher : %s)" % [entry, width, left_handed]
					assert_gte(rect.size.y, float(UiTokens.TOUCH_MIN), label)
					assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN), label)
					assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN), label)
					assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN), label)
					assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN), label)
					assert_false(rect.intersects(logo), "%s : le logo ne couvre rien" % label)


func test_large_text_keeps_the_cards_inside_the_screen() -> void:
	var settings := GameSettings.new()
	settings.text_size = GameSettings.TextSize.LARGE
	UiPrefs.apply(settings)
	var screen := await _screen_in(_model(OpeningFlow.SaveStatus.CORRUPT), 1920)
	await wait_process_frames(2)
	var last := screen.get_column().get_child(screen.get_column().get_child_count() - 1)
	assert_lte((last as Control).get_global_rect().end.y, float(HEIGHT - UiTokens.SAFE_MARGIN),
		"le message reste dans l'écran")
	var card := screen.get_entry_button(&"new_game")
	var label := card.find_children("*", "Label", true, false)[0] as Label
	assert_gt(label.get_theme_font_size(&"font_size"), UiTokens.TITLE_ENTRY_FONT,
		"texte agrandi")
