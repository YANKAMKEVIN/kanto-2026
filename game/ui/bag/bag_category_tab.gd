class_name BagCategoryTab
extends BagTile
## Onglet d'une catégorie du Sac (CAPTURE, SOINS…) : icône et nom, au moins TOUCH_MIN de haut.
## Sélectionné : fond teinté d'ACCENT et liseré ACCENT ; la liste dessous change aussi.

var _category_id: StringName = &""
var _count: Label
var _count_round: PanelContainer
var _caption: Label

@onready var _row: HBoxContainer = %Row
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	normal_variation = &"BagTab"
	selected_variation = &"BagTabSelected"
	custom_minimum_size.y = UiTokens.BAG_TAB_HEIGHT
	_row.add_theme_constant_override(&"separation", UiTokens.BAG_TAB_GAP)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TAB_ICON


## Rangée alignée à gauche, avec le nombre d'objets de la catégorie à droite (écran Sac du menu).
func use_list_layout() -> void:
	_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count = Label.new()
	_count.theme_type_variation = &"BagTabCount"
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count.custom_minimum_size.x = UiTokens.BAG_TAB_COUNT_WIDTH
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_row.add_child(_count)


## Écran Sac du menu rapproché de la maquette (MM.1) : verre, icône peinte plus grande, nom en
## casse de phrase et une légende dessous, compteur dans un rond (après use_list_layout).
func use_menu_layout() -> void:
	normal_variation = &"MenuBagTab"
	selected_variation = &"MenuBagTabSelected"
	set_selected(_selected)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TAB_PAINTED_ICON
	_name_label.theme_type_variation = &"MenuBagTabName"
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override(&"separation", 0)
	_row.add_child(texts)
	_row.move_child(texts, _name_label.get_index())
	_name_label.reparent(texts)
	_caption = Label.new()
	_caption.theme_type_variation = &"MenuBagTabCaption"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.visible = false
	texts.add_child(_caption)
	if _count != null:
		_count_round = PanelContainer.new()
		_count_round.theme_type_variation = &"MenuCountRound"
		_count_round.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_count_round.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TAB_COUNT_WIDTH
		_count_round.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_row.add_child(_count_round)
		_count.reparent(_count_round)
		_count.custom_minimum_size.x = 0.0
		_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Légende sous le nom (use_menu_layout) ; vide : pas de ligne.
func set_caption(text: String) -> void:
	if _caption != null:
		_caption.text = text
		_caption.visible = not text.is_empty()


## Nombre d'objets de la catégorie (après use_list_layout).
func set_count(count: int) -> void:
	if _count != null:
		_count.text = str(count)


func get_count_text() -> String:
	return _count.text if _count != null else ""


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
