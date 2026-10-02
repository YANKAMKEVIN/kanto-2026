class_name BagCategoryTab
extends BagTile
## Onglet d'une catégorie du Sac (CAPTURE, SOINS…) : icône et nom, au moins TOUCH_MIN de haut.
## Sélectionné : fond teinté d'ACCENT et liseré ACCENT ; la liste dessous change aussi.

var _category_id: StringName = &""

@onready var _row: HBoxContainer = %Row
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	normal_variation = &"BagTab"
	selected_variation = &"BagTabSelected"
	custom_minimum_size.y = UiTokens.BAG_TAB_HEIGHT
	_row.add_theme_constant_override(&"separation", UiTokens.BAG_TAB_GAP)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TAB_ICON


## Catégorie [param category_id] affichée sous le nom [param label], avec l'illustration
## [param icon].
func set_category(category_id: StringName, label: String, icon: Texture2D) -> void:
	_category_id = category_id
	_name_label.text = label
	_icon.texture = icon


func get_category_id() -> StringName:
	return _category_id


func get_name_text() -> String:
	return _name_label.text


func get_icon() -> Texture2D:
	return _icon.texture
