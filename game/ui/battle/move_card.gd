class_name MoveCard
extends PanelContainer
## Carte d'une capacité (combat-capacites-v1) : icône du type à gauche, NOM en gras, « PP x/y »
## en haut à droite (« PP » discret), pastille du type, « Puissance 40 » ou « Statut » en bas
## à droite ; fond teinté par la couleur du type (MOVE_CARD_TINT de TYPE_COLORS dans
## PANEL_BG). Sélectionnée : liseré ACCENT et halo (la flèche ▶ est posée par MoveGrid).
##
## Elle ne décide rien : elle rapporte les gestes à MoveGrid.
## - Appui : pressed_down. Relâché sur la carte avant LONG_PRESS : tapped (une fois).
##   Relâché hors de la carte : press_cancelled.
## - Tenue LONG_PRESS : long_pressed ; le relâchement qui suit émet long_press_released,
##   jamais tapped.
## Seule la souris compte (émulée depuis le toucher sur le téléphone, réelle sur Mac) : un
## toucher n'est jamais compté deux fois. Vide ou sans PP, la carte est inerte.

signal pressed_down
signal tapped
signal press_cancelled
signal long_pressed
signal long_press_released

## Textes d'interface.
const PP_TAG := "PP"
const PP_FORMAT := "%d/%d"
const POWER_FORMAT := "Puissance %s"
const STATUS_TEXT := "Statut"
const NO_VALUE := "—"
## Icône neutre (anneau, comme NORMAL sur la référence) pour un type sans icône.
const GENERIC_ICON: Texture2D = preload("res://assets/ui/icons/types/normal.svg")

var _view: BattleMoveView
var _selected: bool = false
var _held: bool = false
var _long: bool = false
var _held_time: float = 0.0

@onready var _row: HBoxContainer = %Row
@onready var _icon_slot: Control = %IconSlot
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _pp_tag: Label = %PpTag
@onready var _pp_value: Label = %PpValue
@onready var _badge: TypeBadge = %Badge
@onready var _power: Label = %Power


func _ready() -> void:
	custom_minimum_size = UiTokens.MOVE_CARD_SIZE
	_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	_icon_slot.custom_minimum_size.x = UiTokens.MOVE_CARD_ICON_COLUMN
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.MOVE_CARD_ICON
	_pp_tag.text = PP_TAG
	_badge.set_show_icon(false)
	set_process(false)
	_apply()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mouse.pressed:
		if _held or not is_usable():
			return
		_held = true
		_long = false
		_held_time = 0.0
		set_process(true)
		pressed_down.emit()
		return
	if not _held:
		return
	_held = false
	set_process(false)
	if _long:
		long_press_released.emit()
	elif Rect2(Vector2.ZERO, size).has_point(mouse.position):
		tapped.emit()
	else:
		press_cancelled.emit()


func _process(delta: float) -> void:
	_held_time += delta
	if not _long and _held_time >= UiTokens.LONG_PRESS:
		_long = true
		long_pressed.emit()


## Capacité affichée ; null = emplacement vide (inerte).
func set_view(view: BattleMoveView) -> void:
	_view = view
	_held = false
	_long = false
	set_process(false)
	if is_node_ready():
		_apply()


func get_view() -> BattleMoveView:
	return _view


## Liseré ACCENT et halo (la carte choisie, appuyée ou sous le focus clavier).
func set_selected(selected: bool) -> void:
	_selected = selected
	if is_node_ready():
		_apply_style()


func is_selected() -> bool:
	return _selected


func is_empty() -> bool:
	return _view == null


## Une capacité avec des PP : elle réagit au toucher.
func is_usable() -> bool:
	return _view != null and _view.is_usable()


## Le doigt est posé sur la carte.
func is_held() -> bool:
	return _held


func get_name_text() -> String:
	return _name_label.text


## « 35/35 » (sans « PP »).
func get_pp_text() -> String:
	return _pp_value.text


func get_power_text() -> String:
	return _power.text


func get_badge() -> TypeBadge:
	return _badge


func get_icon() -> Texture2D:
	return _icon.texture


func get_style() -> StyleBoxFlat:
	return get_theme_stylebox(&"panel") as StyleBoxFlat


func _apply() -> void:
	var empty := _view == null
	_row.visible = not empty
	mouse_filter = Control.MOUSE_FILTER_IGNORE if not is_usable() else Control.MOUSE_FILTER_STOP
	modulate = UiTokens.MODULATE_FULL if empty or is_usable() else UiTokens.MOVE_CARD_DISABLED
	if not empty:
		_name_label.text = _view.display_name.to_upper()
		_pp_value.text = PP_FORMAT % [_view.pp, _view.max_pp]
		if _view.is_usable():
			_pp_value.remove_theme_color_override(&"font_color")
		else:
			_pp_value.add_theme_color_override(&"font_color", UiTokens.MOVE_PP_EMPTY)
		_power.text = power_text(_view)
		_badge.set_type(_view.type_id, _view.type_name)
		_icon.texture = TypeBadge.ICONS.get(_view.type_id, GENERIC_ICON)
	_apply_style()


## « Statut », « Puissance 40 », ou « Puissance — » (capacité offensive sans puissance fixe).
static func power_text(view: BattleMoveView) -> String:
	if view.category == BattleMoveView.Category.STATUS:
		return STATUS_TEXT
	return POWER_FORMAT % (str(view.power) if view.power > 0 else NO_VALUE)


func _apply_style() -> void:
	if _view == null:
		theme_type_variation = &"MoveCardEmpty"
		remove_theme_stylebox_override(&"panel")
		return
	theme_type_variation = &"MoveCardSelected" if _selected else &"MoveCard"
	remove_theme_stylebox_override(&"panel")
	var style := (get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	var type_color: Color = UiTokens.TYPE_COLORS.get(_view.type_id, UiTokens.TYPE_COLOR_UNKNOWN)
	style.bg_color = UiTokens.PANEL_BG.lerp(type_color, UiTokens.MOVE_CARD_TINT)
	if not _selected:
		var border := type_color
		border.a = UiTokens.MOVE_CARD_BORDER_ALPHA
		style.border_color = border
	add_theme_stylebox_override(&"panel", style)
