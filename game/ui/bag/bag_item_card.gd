class_name BagItemCard
extends BagTile
## Carte d'un objet du Sac (maquette du Sac du jalon 6, dossier 08 §3) : illustration, nom en
## gras dessous, quantité « ×5 » au coin de l'illustration. Sélectionnée : liseré ACCENT épais,
## halo et léger grossissement (l'information ne tient pas à la couleur seule).
##
## Elle ne décide rien : elle rapporte le toucher (tapped) au panneau, qui montre l'aperçu.

const STAR_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")

var _view: BagEntryView
var _star: TextureRect

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
	_star = TextureRect.new()
	_star.texture = STAR_ICON
	_star.modulate = UiTokens.ACCENT
	_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_star.custom_minimum_size = Vector2.ONE * UiTokens.BAG_CARD_STAR_ICON
	_star.size = _star.custom_minimum_size
	_star.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_star.visible = false
	_icon_box.add_child(_star)
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


## L'étoile des favoris est affichée sur la carte.
func is_favorite_shown() -> bool:
	return _star != null and _star.visible


func _apply() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS if _view != null else Control.MOUSE_FILTER_IGNORE
	_column.visible = _view != null
	if _view == null:
		return
	_name_label.text = _view.display_name
	_quantity.text = _view.quantity_text()
	_icon.texture = _view.get_icon()
	_star.visible = _view.favorite
	set_selected(_selected)
