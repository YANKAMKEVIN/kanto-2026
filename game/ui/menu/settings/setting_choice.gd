class_name SettingChoice
extends PanelContainer
## Ligne d'un choix (Paramètres, T28 ; présentation MM.3, maquette) : libellé et aide à gauche,
## sélecteur « ‹ Valeur › » à droite (pilule de verre, valeur écrite au milieu). Une flèche émet
## un seul [signal changed] avec la **valeur du réglage** de l'option voisine (jamais son rang) ;
## aux bouts de la liste, la flèche est éteinte et ne fait rien (pas de retour au début : la
## position se lit). L'état affiché ne bouge qu'au retour de la vue.

signal changed(key: StringName, value: Variant)

const PREV_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron_left.svg")
const NEXT_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")

var key: StringName = &""

var _view: SettingControlView
var _label: Label
var _detail: Label
var _pill: PanelContainer
var _prev: Button
var _next: Button
var _value: Label


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
	_pill = PanelContainer.new()
	_pill.name = "Selector"
	_pill.theme_type_variation = &"SettingsPill"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_pill)
	var inner := HBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"separation", 0)
	_pill.add_child(inner)
	_prev = _arrow(PREV_ICON, -1, inner)
	_value = Label.new()
	_value.theme_type_variation = &"SettingsValue"
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.custom_minimum_size.x = UiTokens.SETTINGS_PILL_VALUE_WIDTH
	_value.size_flags_vertical = Control.SIZE_FILL
	inner.add_child(_value)
	_next = _arrow(NEXT_ICON, 1, inner)


func setup(view: SettingControlView, _animate: bool = false) -> void:
	_view = view
	key = view.key
	_label.text = view.label
	_detail.text = view.detail
	_detail.visible = not view.detail.is_empty()
	var selected := view.selected_option()
	# La valeur de la vue (« Auto (Élevée) » : ce qu'Auto choisit), sinon le nom de l'option.
	if not view.value_text.is_empty():
		_value.text = view.value_text
	elif selected >= 0:
		_value.text = view.options[selected].label
	else:
		_value.text = ""
	_prev.disabled = not view.enabled or _neighbour(-1) < 0
	_next.disabled = not view.enabled or _neighbour(1) < 0
	modulate.a = 1.0 if view.enabled else 0.5


## Flèche « ‹ » (option précédente).
func get_prev_button() -> Button:
	return _prev


## Flèche « › » (option suivante).
func get_next_button() -> Button:
	return _next


## Les deux flèches (‹ puis ›).
func get_arrow_buttons() -> Array[Button]:
	return [_prev, _next]


## Valeur écrite au milieu du sélecteur.
func get_value_text() -> String:
	return _value.text


## Rang de l'option affichée comme choisie (-1 : aucune) : celle de la vue.
func get_selected_index() -> int:
	return _view.selected_option() if _view != null else -1


func get_label_text() -> String:
	return _label.text


func get_selector() -> Control:
	return _pill


## Rang de l'option à [param direction] (−1 / +1) de la choisie, ou -1 au bout de la liste.
## Sans option choisie, « › » va à la première et « ‹ » ne mène nulle part.
func _neighbour(direction: int) -> int:
	if _view == null or _view.options.is_empty():
		return -1
	var selected := _view.selected_option()
	if selected < 0:
		return 0 if direction > 0 else -1
	var index := selected + direction
	return index if index >= 0 and index < _view.options.size() else -1


func _arrow(icon: Texture2D, direction: int, parent: Control) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SettingsArrow"
	button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	TapGuard.attach(button)
	button.pressed.connect(_on_arrow_pressed.bind(direction))
	parent.add_child(button)
	return button


func _text_label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = UiTokens.SETTINGS_TEXT_MIN_WIDTH
	parent.add_child(label)
	return label


func _on_arrow_pressed(direction: int) -> void:
	var index := _neighbour(direction)
	if index < 0 or not _view.enabled:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	# La nouvelle valeur ne s'affiche qu'au retour de la vue.
	changed.emit(key, _view.options[index].value)
