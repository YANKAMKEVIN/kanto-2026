class_name SettingToggle
extends Button
## Ligne d'un interrupteur (Paramètres, T28 ; présentation MM.3) : libellé, aide, état écrit
## discret (« Activé ») et interrupteur vert. **Toute la ligne** est le bouton (hauteur ≥
## TOUCH_MIN). Un toucher émet un seul [signal changed] avec le **contraire** de la valeur
## affichée ; l'état affiché ne bouge qu'au retour de la vue (l'écran n'invente pas l'état).

signal changed(key: StringName, value: Variant)

var key: StringName = &""
## Durées multipliées (0 = instantané).
var speed_scale: float = 1.0:
	set(value):
		speed_scale = value
		if _switch != null:
			_switch.speed_scale = value

var _value: bool = false
var _label: Label
var _detail: Label
var _value_label: Label
var _switch: SettingSwitch


func _init() -> void:
	theme_type_variation = &"SettingsRow"
	focus_mode = Control.FOCUS_NONE
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(0.0, UiTokens.SETTINGS_ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = UiTokens.SETTINGS_ROW_PAD_H
	row.offset_right = -UiTokens.SETTINGS_ROW_PAD_H
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
	_value_label = Label.new()
	_value_label.theme_type_variation = &"SettingsState"
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_value_label)
	_switch = SettingSwitch.new()
	row.add_child(_switch)
	TapGuard.attach(self)
	pressed.connect(_on_pressed)


## Pose [param view] ; [param animate] : l'interrupteur glisse (mise à jour d'une ligne affichée).
func setup(view: SettingControlView, animate: bool = false) -> void:
	key = view.key
	_value = bool(view.value)
	_label.text = view.label
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	_value_label.text = view.value_text
	_switch.set_on(_value, animate)
	disabled = not view.enabled
	modulate.a = 1.0 if view.enabled else 0.5


func get_value() -> bool:
	return _value


func get_label_text() -> String:
	return _label.text


func get_value_text() -> String:
	return _value_label.text


func get_switch() -> SettingSwitch:
	return _switch


func _text_label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = UiTokens.SETTINGS_TEXT_MIN_WIDTH
	parent.add_child(label)
	return label


func _on_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	changed.emit(key, not _value)
