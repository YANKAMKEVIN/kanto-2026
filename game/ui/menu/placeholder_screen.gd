class_name PlaceholderScreen
extends MenuScreen
## Écran provisoire d'une carte dont l'écran n'existe pas encore (« ÉQUIPE — À venir »), avec
## un bouton RETOUR (zone tactile ≥ TOUCH_MIN). Disparaît écran après écran, du 6A au 6F.

const SOON_TEXT := "À venir"
const BACK_TEXT := "RETOUR"
const BACK_SIZE := Vector2(300, UiTokens.TOUCH_MIN)

var _title: Label
var _back: Button


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.GAP * 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	_title = Label.new()
	_title.theme_type_variation = &"MenuName"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = BACK_SIZE
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(_on_back)
	column.add_child(_back)


## « ÉQUIPE — À venir ».
func set_screen_title(text: String) -> void:
	_title.text = "%s — %s" % [text.to_upper(), SOON_TEXT]


func get_title_text() -> String:
	return _title.text


func get_back_button() -> Button:
	return _back


func _on_back() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()
