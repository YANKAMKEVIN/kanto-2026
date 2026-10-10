class_name NameEntry
extends Control
## Écran de prénom de l'introduction (OUV.2, dossier 13 §5.5, §7 ; composition de
## reference/ouverture-prenom-v1.webp, règle 10).
##
## Panneau de verre à liseré doré **en haut à droite, entier dans la moitié haute de l'écran** :
## en paysage, le clavier du téléphone couvre le bas. La question de Chen reste dans la boîte de
## dialogue (§5.5) ; le portrait nommé est à gauche, sur la scène ([IntroStage]).
## - Champ texte **natif** ([LineEdit] : le clavier du téléphone s'ouvre, accents et correction
##   compris), limité à `max_length` caractères ; chaque frappe ou collage passe par
##   [method NameRules.filter_input] (caractères refusés retirés, tronqué) ;
## - compteur discret « 4 / 10 » au bout du champ ;
## - aide « Lettres, espaces, - et ’ seulement » sous le champ, **seulement** quand la dernière
##   frappe contenait un caractère refusé (sa place est réservée : rien ne bouge) ; jamais de
##   pop-up ;
## - pastilles des noms proposés (toucher = remplir le champ) et **VALIDER**, actif seulement si
##   [method NameRules.validate] vaut OK.
## Vue pure : elle émet [signal submitted] avec la saisie brute (la normalisation est faite par
## celui qui la reçoit, [IntroReader]). Retour Android : [method release_keyboard] ferme le
## clavier, puis rien (§5.5) ; c'est l'appelant qui décide.

## VALIDER (ou Entrée du clavier) avec un prénom valide : la saisie telle qu'affichée.
signal submitted(raw: String)

var _max_length: int = 10
var _suggestions: PackedStringArray = PackedStringArray()
var _open: bool = false
var _help_shown: bool = false
var _panel: PanelContainer
var _line: LineEdit
var _counter: Label
var _help: Label
var _chips: HBoxContainer
var _validate: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


## Ouvre l'écran : [param suggestions] (les pastilles), [param max_length] caractères au plus,
## champ prérempli de [param prefill] (retour par « Non »), bouton [param validate_label].
## Le champ prend le focus : le clavier du téléphone s'ouvre.
func open(suggestions: PackedStringArray, max_length: int, prefill: String,
		validate_label: String) -> void:
	_suggestions = suggestions
	_max_length = maxi(max_length, 1)
	_line.max_length = _max_length
	_validate.text = validate_label.to_upper()
	_rebuild_chips()
	_help_shown = false
	_line.text = NameRules.filter_input(prefill, _max_length)
	_line.caret_column = _line.text.length()
	_open = true
	visible = true
	_refresh()
	UiPrefsApplier.apply(self)
	if is_inside_tree():
		_line.grab_focus()


## Ferme l'écran (et le clavier).
func close() -> void:
	_open = false
	if _line.has_focus():
		_line.release_focus()
	visible = false


func is_open() -> bool:
	return _open


## Retour Android : ferme le clavier s'il est ouvert (vrai), sinon rien (faux).
func release_keyboard() -> bool:
	if _open and _line.has_focus():
		_line.release_focus()
		return true
	return false


## Saisie courante, telle qu'affichée.
func get_text() -> String:
	return _line.text


## Vrai si la saisie est un prénom valide (VALIDER actif).
func is_valid() -> bool:
	return NameRules.validate(_line.text, _max_length) == NameRules.Result.OK


## Une frappe ou un collage (même chemin que le clavier) : utile aux tests et aux outils.
func type_text(raw: String) -> void:
	_line.text = raw
	_on_text_changed(raw)


func get_line_edit() -> LineEdit:
	return _line


func get_validate_button() -> Button:
	return _validate


func get_chips() -> Array[Button]:
	var chips: Array[Button] = []
	for child: Node in _chips.get_children():
		if child is Button and not child.is_queued_for_deletion():
			chips.append(child as Button)
	return chips


## « 4 / 10 ».
func get_counter_text() -> String:
	return _counter.text


## Aide sous le champ ("" quand elle est cachée).
func get_help_text() -> String:
	return _help.text


func get_panel() -> PanelContainer:
	return _panel


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = &"NamePanel"
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -UiTokens.SAFE_MARGIN - UiTokens.NAME_PANEL_WIDTH
	_panel.offset_right = -UiTokens.SAFE_MARGIN
	_panel.offset_top = UiTokens.SAFE_MARGIN
	_panel.offset_bottom = UiTokens.SAFE_MARGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.NAME_PANEL_GAP)
	_panel.add_child(column)
	var field := Control.new()
	field.name = "Field"
	field.custom_minimum_size.y = UiTokens.NAME_FIELD_HEIGHT
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(field)
	_line = LineEdit.new()
	_line.name = "Line"
	_line.theme_type_variation = &"NameField"
	_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_line.virtual_keyboard_enabled = true
	_line.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_line.context_menu_enabled = false
	_line.select_all_on_focus = false
	_line.caret_blink = true
	_line.text_changed.connect(_on_text_changed)
	_line.text_submitted.connect(_on_submitted.unbind(1))
	field.add_child(_line)
	_counter = Label.new()
	_counter.name = "Counter"
	_counter.theme_type_variation = &"NameCounter"
	_counter.anchor_left = 1.0
	_counter.anchor_right = 1.0
	_counter.anchor_bottom = 1.0
	_counter.offset_left = -UiTokens.NAME_FIELD_PAD_H - UiTokens.NAME_COUNTER_WIDTH
	_counter.offset_right = -UiTokens.NAME_FIELD_PAD_H
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(_counter)
	_help = Label.new()
	_help.name = "Help"
	_help.theme_type_variation = &"NameHelp"
	_help.custom_minimum_size.y = UiTokens.NAME_HELP_HEIGHT
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_help)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.NAME_PANEL_GAP)
	column.add_child(row)
	_chips = HBoxContainer.new()
	_chips.name = "Chips"
	_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chips.add_theme_constant_override(&"separation", UiTokens.NAME_PANEL_GAP)
	row.add_child(_chips)
	_validate = Button.new()
	_validate.name = "Validate"
	_validate.theme_type_variation = &"NameValidate"
	_validate.focus_mode = Control.FOCUS_NONE
	_validate.custom_minimum_size = Vector2(UiTokens.NAME_VALIDATE_WIDTH, UiTokens.TOUCH_MIN)
	_validate.pressed.connect(_on_submitted)
	row.add_child(_validate)


func _rebuild_chips() -> void:
	for child: Node in _chips.get_children():
		_chips.remove_child(child)
		child.queue_free()
	for suggestion: String in _suggestions:
		var chip := Button.new()
		chip.text = suggestion
		chip.theme_type_variation = &"NameChip"
		# Le champ garde le focus (et le clavier reste ouvert) quand on touche une pastille.
		chip.focus_mode = Control.FOCUS_NONE
		chip.custom_minimum_size = Vector2(UiTokens.NAME_CHIP_WIDTH, UiTokens.TOUCH_MIN)
		chip.pressed.connect(_on_chip_pressed.bind(suggestion))
		_chips.add_child(chip)


## Frappe ou collage : caractères refusés retirés, tronqué ; l'aide dit qu'un caractère a été
## refusé.
func _on_text_changed(raw: String) -> void:
	var filtered := NameRules.filter_input(raw, _max_length)
	_help_shown = NameRules.has_invalid_chars(raw)
	if filtered != raw:
		var caret := _line.caret_column - (raw.length() - filtered.length())
		_line.text = filtered
		_line.caret_column = clampi(caret, 0, filtered.length())
	_refresh()


func _on_chip_pressed(suggestion: String) -> void:
	if not _open:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	_line.text = NameRules.filter_input(suggestion, _max_length)
	_line.caret_column = _line.text.length()
	_help_shown = false
	_refresh()


func _on_submitted() -> void:
	if not _open or not is_valid():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	submitted.emit(_line.text)


func _refresh() -> void:
	_counter.text = "%d / %d" % [_line.text.length(), _max_length]
	_help.text = NameRules.INVALID_CHAR_HELP if _help_shown else ""
	_validate.disabled = not is_valid()
	var chosen := NameRules.normalize(_line.text)
	for chip: Button in get_chips():
		chip.theme_type_variation = &"NameChipSelected" if chip.text == chosen else &"NameChip"
