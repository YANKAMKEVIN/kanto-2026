extends GutTest
## Écran de prénom (OUV.2, dossier 13 §5.5, §7) : champ natif limité, filtre en direct, aide sous
## le champ seulement pour un caractère refusé, compteur, trois pastilles, VALIDER actif seulement
## sur un prénom valide, tout dans la moitié haute de l'écran (le clavier couvre le bas), retour
## Android = fermer le clavier.

const SCENE := preload("res://game/ui/opening/name_entry.tscn")
const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const SUGGESTIONS := ["Red", "Sacha", "Kevin"]
const QUESTION := "Comment t'appelles-tu ?"

var _entry: NameEntry
var _submitted: Array[String] = []


func before_each() -> void:
	_submitted.clear()
	_entry = SCENE.instantiate() as NameEntry
	add_child_autofree(_entry)
	_entry.submitted.connect(func(raw: String) -> void: _submitted.append(raw))
	_entry.open(QUESTION, PackedStringArray(SUGGESTIONS), 10, "", "Valider")


func test_opens_empty_with_the_suggestions_and_validate_inactive() -> void:
	assert_true(_entry.is_open())
	assert_eq(_entry.get_text(), "")
	assert_eq(_entry.get_counter_text(), "0 / 10")
	assert_eq(_entry.get_help_text(), "")
	var chips: Array[String] = []
	for chip: Button in _entry.get_chips():
		chips.append(chip.text)
	assert_eq(chips, ["Red", "Sacha", "Kevin"] as Array[String])
	assert_true(_entry.get_validate_button().disabled)
	assert_eq(_entry.get_validate_button().text, "VALIDER")
	assert_eq(_entry.get_title_text(), QUESTION, "la question de Chen en titre (QA S21)")


func test_native_field_with_max_length_and_virtual_keyboard() -> void:
	var line := _entry.get_line_edit()
	assert_eq(line.max_length, 10)
	assert_true(line.virtual_keyboard_enabled)
	await wait_process_frames(1)
	assert_true(line.has_focus(), "le champ prend le focus : le clavier s'ouvre")


func test_typing_a_valid_name_enables_validate_and_counts() -> void:
	_entry.type_text("Sacha")
	assert_eq(_entry.get_counter_text(), "5 / 10")
	assert_false(_entry.get_validate_button().disabled)
	assert_eq(_entry.get_chips()[1].theme_type_variation, &"NameChipSelected",
		"la pastille du nom saisi est mise en avant")
	assert_eq(_entry.get_chips()[0].theme_type_variation, &"NameChip")


func test_refused_characters_are_removed_and_the_help_shows() -> void:
	_entry.type_text("Kev2")
	assert_eq(_entry.get_text(), "Kev", "chiffre retiré")
	assert_eq(_entry.get_help_text(), "Lettres, espaces, - et ’ seulement")
	assert_false(_entry.get_validate_button().disabled, "Kev reste valide")
	_entry.type_text("Kevi")
	assert_eq(_entry.get_help_text(), "", "l'aide disparaît à la frappe suivante")
	_entry.type_text("A🔥")
	assert_eq(_entry.get_text(), "A")
	assert_eq(_entry.get_help_text(), NameRules.INVALID_CHAR_HELP)


func test_apostrophe_and_paste_are_filtered_like_typing() -> void:
	_entry.type_text("d'Artagnan42 de Gascogne")
	assert_eq(_entry.get_text(), "d’Artagnan", "apostrophe typographique, tronqué à 10")
	assert_eq(_entry.get_counter_text(), "10 / 10")
	assert_eq(_entry.get_help_text(), NameRules.INVALID_CHAR_HELP)


func test_empty_or_letterless_input_keeps_validate_inactive_without_help() -> void:
	for raw: String in ["   ", "-", "’", ""]:
		_entry.type_text(raw)
		assert_true(_entry.get_validate_button().disabled, "« %s »" % raw)
		assert_eq(_entry.get_help_text(), "", "« %s » : pas d'aide" % raw)


func test_a_chip_fills_the_field_without_submitting() -> void:
	_entry.get_chips()[2].pressed.emit()
	assert_eq(_entry.get_text(), "Kevin")
	assert_eq(_submitted, [] as Array[String], "rien n'est validé")
	_entry.get_validate_button().pressed.emit()
	assert_eq(_submitted, ["Kevin"] as Array[String])


func test_validate_and_enter_submit_only_a_valid_name() -> void:
	_entry.get_validate_button().pressed.emit()
	_entry.get_line_edit().text_submitted.emit("")
	assert_eq(_submitted, [] as Array[String], "vide : rien")
	_entry.type_text("Léa")
	_entry.get_line_edit().text_submitted.emit("Léa")
	assert_eq(_submitted, ["Léa"] as Array[String], "Entrée du clavier = VALIDER")


func test_prefill_after_no() -> void:
	_entry.close()
	_entry.open(QUESTION, PackedStringArray(SUGGESTIONS), 10, "Régis", "Valider")
	assert_eq(_entry.get_text(), "Régis")
	assert_eq(_entry.get_line_edit().caret_column, 5, "curseur au bout")
	assert_false(_entry.get_validate_button().disabled)


func test_everything_sits_in_the_upper_half_of_the_screen() -> void:
	await wait_process_frames(2)
	var half := get_viewport().get_visible_rect().size.y * 0.5
	var panel := _entry.get_panel().get_global_rect()
	assert_lt(panel.end.y, half, "panneau dans la moitié haute (clavier en bas)")
	assert_gte(panel.position.y, float(UiTokens.SAFE_MARGIN))
	assert_lte(panel.end.x, get_viewport().get_visible_rect().size.x - UiTokens.SAFE_MARGIN)
	for chip: Button in _entry.get_chips():
		assert_gte(chip.size.y, float(UiTokens.TOUCH_MIN), "pastille ≥ TOUCH_MIN")
	assert_gte(_entry.get_validate_button().size.y, float(UiTokens.TOUCH_MIN))
	assert_gte(_entry.get_validate_button().size.x, float(UiTokens.TOUCH_MIN))


func test_back_releases_the_keyboard_then_nothing() -> void:
	await wait_process_frames(1)
	assert_true(_entry.release_keyboard(), "clavier fermé")
	assert_false(_entry.get_line_edit().has_focus())
	assert_false(_entry.release_keyboard(), "puis rien")
	assert_true(_entry.is_open(), "l'écran reste")


func test_closed_entry_ignores_everything() -> void:
	_entry.type_text("Sacha")
	_entry.close()
	assert_false(_entry.visible)
	_entry.get_validate_button().pressed.emit()
	assert_eq(_submitted, [] as Array[String])


## Défaut (QA S21, point 4) : l'aide s'efface d'elle-même après NAME_HELP_HOLD.
func test_the_help_fades_away_after_a_while() -> void:
	var clock := TweenClock.new(get_tree())
	_entry.type_text("Ash9")
	assert_eq(_entry.get_help_text(), NameRules.INVALID_CHAR_HELP)
	clock.step(UiTokens.NAME_HELP_HOLD - 0.1)
	assert_eq(_entry.get_help_text(), NameRules.INVALID_CHAR_HELP, "pas avant le délai")
	clock.step(0.2)
	assert_eq(_entry.get_help_text(), "", "effacée après le délai")
	assert_eq(_entry.get_text(), "Ash")
	clock.release()


func test_the_panel_is_above_the_dialogue_box() -> void:
	assert_gt(UiTokens.LAYER_NAME_ENTRY, UiTokens.LAYER_DIALOG)
	assert_lt(UiTokens.LAYER_NAME_ENTRY, UiTokens.LAYER_TRANSITION)
