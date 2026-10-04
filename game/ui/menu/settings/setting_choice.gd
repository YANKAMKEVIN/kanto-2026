class_name SettingChoice
extends PanelContainer
## Ligne d'un choix (Paramètres, T28) : libellé et aide à gauche, **toutes** les options côte à
## côte à droite (Lente · Normale · Rapide · Instantanée), la choisie en ACCENT. Un toucher sur
## une autre option émet un seul [signal changed] avec la **valeur du réglage** de l'option
## (jamais son rang) ; toucher l'option déjà choisie ne fait rien. L'état affiché ne bouge qu'au
## retour de la vue.

signal changed(key: StringName, value: Variant)

var key: StringName = &""

var _view: SettingControlView
var _label: Label
var _detail: Label
var _options: HBoxContainer
var _buttons: Array[Button] = []
var _group := ButtonGroup.new()


func _init() -> void:
	theme_type_variation = &"SettingsRowBox"
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(0.0, UiTokens.SETTINGS_ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(row)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	row.add_child(texts)
	_label = _text_label(&"SettingsLabel", texts)
	_detail = _text_label(&"SettingsDetail", texts)
	_options = HBoxContainer.new()
	_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options.add_theme_constant_override(&"separation", UiTokens.SETTINGS_OPTION_GAP)
	row.add_child(_options)


func setup(view: SettingControlView, _animate: bool = false) -> void:
	_view = view
	key = view.key
	_label.text = view.label
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	if _buttons.size() != view.options.size():
		_rebuild(view)
	var selected := view.selected_option()
	for i: int in _buttons.size():
		var button := _buttons[i]
		# L'option choisie écrit la valeur de la vue (« Auto (Élevée) » : ce qu'Auto choisit).
		button.text = view.value_text if i == selected and not view.value_text.is_empty() \
			else view.options[i].label
		button.set_pressed_no_signal(i == selected)
		button.disabled = not view.enabled
	modulate.a = 1.0 if view.enabled else 0.5


## Boutons des options, dans l'ordre de la vue.
func get_option_buttons() -> Array[Button]:
	return _buttons


## Rang de l'option affichée comme choisie (-1 : aucune).
func get_selected_index() -> int:
	for i: int in _buttons.size():
		if _buttons[i].button_pressed:
			return i
	return -1


func get_label_text() -> String:
	return _label.text


func _rebuild(view: SettingControlView) -> void:
	for button: Button in _buttons:
		_options.remove_child(button)
		button.queue_free()
	_buttons.clear()
	for i: int in view.options.size():
		var button := Button.new()
		button.theme_type_variation = &"SettingsOption"
		button.toggle_mode = true
		button.button_group = _group
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.custom_minimum_size = Vector2(UiTokens.SETTINGS_OPTION_MIN_WIDTH,
			UiTokens.TOUCH_MIN)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		TapGuard.attach(button)
		button.pressed.connect(_on_option_pressed.bind(i))
		_options.add_child(button)
		_buttons.append(button)


func _text_label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = UiTokens.SETTINGS_TEXT_MIN_WIDTH
	parent.add_child(label)
	return label


func _on_option_pressed(index: int) -> void:
	if _view == null:
		return
	var selected := _view.selected_option()
	if index == selected:
		# Option déjà choisie : le groupe la garde enfoncée, rien à dire.
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	# La nouvelle option ne s'affiche qu'au retour de la vue : l'ancienne reste marquée.
	if selected >= 0 and selected < _buttons.size():
		_buttons[selected].set_pressed_no_signal(true)
	changed.emit(key, _view.options[index].value)
