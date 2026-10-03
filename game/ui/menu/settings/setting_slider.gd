class_name SettingSlider
extends PanelContainer
## Ligne d'un curseur (Paramètres, T28) : libellé et aide à gauche, piste au centre, pourcentage
## écrit à droite. Le pourcentage suit le doigt pendant le geste ; **un seul** [signal changed] au
## lâcher, avec la valeur sur un cran. L'état affiché ne bouge qu'au retour de la vue.

signal changed(key: StringName, value: Variant)

var key: StringName = &""

var _label: Label
var _detail: Label
var _track: SettingSliderTrack
var _value_label: Label


func _init() -> void:
	theme_type_variation = &"SettingsRowBox"
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
	_track = SettingSliderTrack.new()
	_track.previewed.connect(_on_previewed)
	_track.committed.connect(_on_committed)
	row.add_child(_track)
	_value_label = Label.new()
	_value_label.theme_type_variation = &"SettingsValue"
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.custom_minimum_size.x = UiTokens.SETTINGS_SLIDER_VALUE_WIDTH
	_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_value_label)


func setup(view: SettingControlView, _animate: bool = false) -> void:
	key = view.key
	_label.text = view.label
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	_track.min_value = view.min_value
	_track.max_value = view.max_value
	_track.step = view.step
	_track.enabled = view.enabled
	if not _track.is_dragging():
		_track.set_value(float(view.value))
		_value_label.text = view.value_text
	modulate.a = 1.0 if view.enabled else 0.5


func get_track() -> SettingSliderTrack:
	return _track


func get_label_text() -> String:
	return _label.text


## Pourcentage affiché (celui de la vue, ou celui du doigt pendant le geste).
func get_value_text() -> String:
	return _value_label.text


func _text_label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = UiTokens.SETTINGS_TEXT_MIN_WIDTH
	parent.add_child(label)
	return label


func _on_previewed(value: float) -> void:
	_value_label.text = SettingsViews.percent_text(value)
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)


func _on_committed(value: float) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	changed.emit(key, value)
