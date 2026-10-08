class_name BattleBagRow
extends BagTile
## Rangée d'un objet du Sac de combat (CB.2, storyboard combat-capture-v1 case 2) : ▶ de
## sélection, illustration, nom, quantité « × 12 » à droite. Sélectionnée : liseré ACCENT et
## ▶ visible (l'information ne tient pas à la couleur seule). Elle ne décide rien : elle
## rapporte le toucher (tapped) au panneau, qui montre l'aperçu.

const ARROW: Texture2D = preload("res://assets/ui/icons/battle/select_arrow.svg")

var _view: BagEntryView
var _arrow: TextureRect
var _icon: TextureRect
var _name_label: Label
var _quantity: Label


func _ready() -> void:
	normal_variation = &"BagCard"
	selected_variation = &"BagCardSelected"
	selected_scale = 1.0
	custom_minimum_size.y = UiTokens.BATTLE_BAG_ROW_HEIGHT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.BATTLE_BAG_ROW_GAP)
	add_child(row)
	_arrow = TextureRect.new()
	_arrow.texture = ARROW
	_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arrow.custom_minimum_size = UiTokens.MOVE_SELECT_ARROW
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.self_modulate = UiTokens.ACCENT
	row.add_child(_arrow)
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.BATTLE_BAG_ROW_ICON
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"BagCardName"
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_name_label)
	_quantity = Label.new()
	_quantity.theme_type_variation = &"BagCardName"
	_quantity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_quantity)
	_apply()


## Objet affiché ; null = rangée vide (inerte).
func set_view(view: BagEntryView) -> void:
	_view = view
	if is_node_ready():
		_apply()


func get_view() -> BagEntryView:
	return _view


func get_name_text() -> String:
	return _name_label.text


## « × 12 » (la quantité de la vue, « ×12 », avec une espace après le signe).
func get_quantity_text() -> String:
	return _quantity.text


func get_icon() -> Texture2D:
	return _icon.texture


func set_selected(selected: bool) -> void:
	super.set_selected(selected)
	if _arrow != null:
		_arrow.modulate.a = 1.0 if selected else 0.0


func _apply() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS if _view != null else Control.MOUSE_FILTER_IGNORE
	if _view == null:
		return
	_name_label.text = _view.display_name
	_quantity.text = _view.quantity_text().replace("×", "× ")
	_icon.texture = _view.get_icon()
	set_selected(_selected)
