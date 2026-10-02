class_name BagItemCard
extends BagTile
## Carte d'un objet du Sac (maquette du Sac du jalon 6, dossier 08 §3) : illustration, nom en
## gras dessous, quantité « ×5 » au coin de l'illustration. Sélectionnée : liseré ACCENT épais,
## halo et léger grossissement (l'information ne tient pas à la couleur seule).
##
## Elle ne décide rien : elle rapporte le toucher (tapped) au panneau, qui montre l'aperçu.

var _view: BagEntryView

@onready var _column: VBoxContainer = %Column
@onready var _icon_box: Control = %IconBox
@onready var _icon: TextureRect = %Icon
@onready var _quantity: Label = %Quantity
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	normal_variation = &"BagCard"
	selected_variation = &"BagCardSelected"
	selected_scale = UiTokens.BAG_CARD_SELECTED_SCALE
	custom_minimum_size = UiTokens.BAG_CARD_SIZE
	_icon_box.custom_minimum_size.y = UiTokens.BAG_CARD_ICON
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_CARD_ICON
	_apply()


## Objet affiché ; null = carte vide (inerte).
func set_view(view: BagEntryView) -> void:
	_view = view
	if is_node_ready():
		_apply()


func get_view() -> BagEntryView:
	return _view


func get_name_text() -> String:
	return _name_label.text


## « ×5 ».
func get_quantity_text() -> String:
	return _quantity.text


func get_icon() -> Texture2D:
	return _icon.texture


func _apply() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if _view != null else Control.MOUSE_FILTER_IGNORE
	_column.visible = _view != null
	if _view == null:
		return
	_name_label.text = _view.display_name
	_quantity.text = _view.quantity_text()
	_icon.texture = _view.get_icon()
	set_selected(_selected)
