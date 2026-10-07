class_name BattleBagPanel
extends BattleWidget
## Le Sac ouvert pendant un combat sauvage (jalon 5D T14, jalon-05.md §3.10 et §3.12), d'après
## le Sac du jalon 6 (dossier 08 §3) adapté au combat, objets en rangées comme le storyboard
## (CB.2) : panneau sombre translucide en bas à gauche, au-dessus du bouton « ‹ » ; l'adversaire (centre droit) reste visible.
##
## Composition : en-tête « SAC » et onglets de catégories (CAPTURE, SOINS…), objets en cartes
## (illustration, nom, quantité), aperçu de l'objet touché (illustration, nom, quantité,
## description) et UNE action claire (LANCER). Rien n'est annoncé d'avance : un objet
## inutilisable, une catégorie vide ou sans objet utilisable ne s'affichent pas, et il n'y a
## aucun bouton grisé.
##
## Gestes (aucune fenêtre de confirmation, deux gestes pour lancer) :
## - toucher une carte = elle est SÉLECTIONNÉE et son aperçu s'affiche (item_previewed), rien
##   n'est choisi ; la première carte de la catégorie ouverte est déjà aperçue ;
## - toucher un onglet ouvre sa catégorie (category_opened) ;
## - LANCER = un seul item_chosen(id), le panneau se ferme et se tait jusqu'au prochain
##   show_bag ;
## - « ‹ » (ou Échap) = back_requested, le panneau se ferme, rien n'est choisi.
## Clavier (tests sur Mac) : flèches = sélection, ui_accept = LANCER.
## Placement : BattleHudLayout.Slot.BAG (l'hôte appelle BattleHudLayout.place) ; il recouvre
## la carte joueur et les pastilles, que l'hôte fait sortir avant.

## LANCER touché : identifiant de l'objet choisi (une seule fois par ouverture).
signal item_chosen(item_id: StringName)
## « ‹ » touché : le panneau se ferme sans rien choisir.
signal back_requested
## Une carte est touchée : son aperçu est affiché (aucun choix).
signal item_previewed(item_id: StringName)
## Un onglet est touché : sa catégorie est ouverte.
signal category_opened(category_id: StringName)

const TAB_SCENE: PackedScene = preload("res://game/ui/bag/bag_category_tab.tscn")
const TITLE_ICON: Texture2D = preload("res://assets/ui/icons/battle/bag.svg")
## Illustration de l'onglet d'une catégorie ; le sac pour les autres.
const CATEGORY_ICONS: Dictionary[StringName, Texture2D] = {
	&"ball": preload("res://assets/ui/icons/items/poke_ball.svg"),
}
## Textes d'interface (validés par Kevin le 2026-10-06).
const TITLE := "SAC"
const EMPTY_TEXT := "Aucun objet utilisable pour l'instant."

var _by_category: Dictionary[StringName, Array] = {}
var _categories: Array[StringName] = []
var _open: StringName = &""
var _selected: StringName = &""
var _tabs: Dictionary[StringName, BagCategoryTab] = {}
var _cards: Array[BattleBagRow] = []
var _answered: bool = false
var _detail_tween: Tween

@onready var _frame: PanelContainer = %Frame
@onready var _content: VBoxContainer = %Content
@onready var _header: HBoxContainer = %Header
@onready var _title_icon: TextureRect = %TitleIcon
@onready var _title: Label = %Title
@onready var _tabs_row: HBoxContainer = %Tabs
@onready var _divider: Panel = %Divider
@onready var _scroll: ScrollContainer = %Scroll
@onready var _pad: MarginContainer = %Pad
@onready var _grid: GridContainer = %Grid
@onready var _empty: Label = %Empty
@onready var _detail: PanelContainer = %Detail
@onready var _detail_row: HBoxContainer = %DetailRow
@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _name_row: HBoxContainer = %NameRow
@onready var _detail_name: Label = %DetailName
@onready var _detail_quantity: Label = %DetailQuantity
@onready var _detail_text: Label = %DetailText
@onready var _action: Button = %ActionButton
@onready var _back: BattleBackButton = %BackButton


func _ready() -> void:
	slide_direction = Vector2.LEFT
	super._ready()
	var below := float(UiTokens.BATTLE_BACK_SIZE + UiTokens.GAP)
	_frame.anchor_left = 0.0
	_frame.anchor_right = 0.0
	_frame.anchor_top = 1.0
	_frame.anchor_bottom = 1.0
	_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_frame.offset_left = 0.0
	_frame.offset_right = UiTokens.BATTLE_BAG_WIDTH
	_frame.offset_bottom = -below
	_frame.offset_top = -below
	_frame.custom_minimum_size.x = UiTokens.BATTLE_BAG_WIDTH
	_content.add_theme_constant_override(&"separation", UiTokens.BAG_ROW_GAP)
	_header.add_theme_constant_override(&"separation", UiTokens.GAP)
	_tabs_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	_title_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TITLE_ICON
	_title_icon.texture = TITLE_ICON
	_title.text = TITLE
	_divider.custom_minimum_size.y = UiTokens.BORDER_WIDTH
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		_pad.add_theme_constant_override(side, UiTokens.BAG_SCROLL_PAD)
	_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.columns = 1
	_grid.add_theme_constant_override(&"v_separation", UiTokens.BATTLE_BAG_ROW_GAP)
	_empty.text = EMPTY_TEXT
	_empty.custom_minimum_size.y = UiTokens.BAG_EMPTY_HEIGHT
	_detail_row.add_theme_constant_override(&"separation", UiTokens.BAG_DETAIL_GAP)
	_name_row.add_theme_constant_override(&"separation", UiTokens.BAG_TAB_GAP)
	_detail_icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_DETAIL_ICON
	_detail_text.max_lines_visible = 2
	# Rangées : l'illustration, le nom et la quantité sont déjà dans la rangée choisie.
	_detail_icon.visible = false
	_name_row.visible = false
	_detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action.custom_minimum_size = UiTokens.BAG_ACTION_SIZE
	_action.focus_mode = Control.FOCUS_NONE
	_action.pressed.connect(_on_action)
	_back.back_requested.connect(_on_back)
	_back.haptic_played.connect(haptic_played.emit)
	_clear()


func _unhandled_input(event: InputEvent) -> void:
	if not _shown or _answered or _cards.is_empty():
		return
	var moves: Dictionary[StringName, Vector2i] = {
		&"ui_left": Vector2i.LEFT, &"ui_right": Vector2i.RIGHT,
		&"ui_up": Vector2i.UP, &"ui_down": Vector2i.DOWN,
	}
	for action: StringName in moves:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_move_selection(moves[action])
			return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_on_action()


## Montre le Sac avec les objets [param entries] : seuls ceux qui sont affichables (au moins un
## exemplaire, utilisables) comptent. S'ouvre sur la catégorie [param start_category] si elle
## existe, sinon sur la première ; la première carte est aperçue. Rien n'est choisi ; réarme
## le panneau après un choix. Aucun objet utilisable : une phrase simple, et « ‹ ».
func show_bag(entries: Array[BagEntryView], start_category: StringName = &"") -> void:
	_back.speed_scale = speed_scale
	_back.haptics_enabled = haptics_enabled
	_group(entries)
	_answered = false
	_build_tabs()
	var first: StringName = _categories[0] if not _categories.is_empty() else &""
	open_category(start_category if _by_category.has(start_category) else first)
	slide_in()


## Ouvre la catégorie [param category_id] (sans effet si elle n'existe pas) : sa liste de
## cartes, la première carte aperçue. N'émet aucun signal.
func open_category(category_id: StringName) -> void:
	if not _by_category.has(category_id):
		_open = &""
		_selected = &""
		_rebuild_cards()
		_refresh()
		return
	_open = category_id
	for id: StringName in _tabs:
		_tabs[id].set_selected(id == category_id)
	_rebuild_cards()
	var views: Array = _by_category[category_id]
	select_item((views[0] as BagEntryView).item_id)


## Aperçoit l'objet [param item_id] de la catégorie ouverte (sans effet s'il n'y est pas).
## N'émet aucun signal.
func select_item(item_id: StringName) -> void:
	var found := false
	for card: BattleBagRow in _cards:
		var chosen := card.get_view().item_id == item_id
		card.set_selected(chosen)
		found = found or chosen
	_selected = item_id if found else &""
	_refresh()


## Identifiant de l'objet aperçu, &"" si rien.
func get_selected_id() -> StringName:
	return _selected


## Catégorie ouverte, &"" si le Sac est vide.
func get_open_category() -> StringName:
	return _open


## Catégories affichées (onglets), dans l'ordre.
func get_categories() -> Array[StringName]:
	return _categories


## Nombre d'onglets affichés.
func get_tabs_count() -> int:
	return _tabs.size()


func get_tab(category_id: StringName) -> BagCategoryTab:
	return _tabs.get(category_id)


## Cartes de la catégorie ouverte, dans l'ordre.
func get_cards() -> Array[BattleBagRow]:
	return _cards


func get_action_button() -> Button:
	return _action


func get_back_button() -> BattleBackButton:
	return _back


## Rectangle du cadre (écran), hors bouton « ‹ ».
func get_frame_rect() -> Rect2:
	return _frame.get_global_rect()


func get_detail() -> PanelContainer:
	return _detail


func get_detail_name() -> String:
	return _detail_name.text


func get_detail_quantity() -> String:
	return _detail_quantity.text


func get_detail_text() -> String:
	return _detail_text.text


func get_empty_label() -> Label:
	return _empty


func get_scroll() -> ScrollContainer:
	return _scroll


## Un choix ou « ‹ » a été fait : le panneau se tait jusqu'au prochain show_bag.
func is_answered() -> bool:
	return _answered


func slide_in() -> void:
	_back.slide_in()
	await super.slide_in()


func slide_out() -> void:
	_back.slide_out()
	await super.slide_out()


## Classe les objets affichables par catégorie, dans l'ordre où elles apparaissent.
func _group(entries: Array[BagEntryView]) -> void:
	_by_category.clear()
	_categories.clear()
	for view: BagEntryView in entries:
		if view == null or not view.is_displayable():
			continue
		if not _by_category.has(view.category_id):
			_by_category[view.category_id] = []
			_categories.append(view.category_id)
		_by_category[view.category_id].append(view)


func _build_tabs() -> void:
	for tab: BagCategoryTab in _tabs.values():
		_tabs_row.remove_child(tab)
		tab.free()
	_tabs.clear()
	for category_id: StringName in _categories:
		var tab := TAB_SCENE.instantiate() as BagCategoryTab
		_tabs_row.add_child(tab)
		tab.set_category(category_id, BagEntryView.category_label(category_id),
			CATEGORY_ICONS.get(category_id, TITLE_ICON))
		tab.tapped.connect(_on_tab_tapped.bind(category_id))
		_tabs[category_id] = tab


func _rebuild_cards() -> void:
	for card: BattleBagRow in _cards:
		_grid.remove_child(card)
		card.free()
	_cards.clear()
	if _open.is_empty():
		return
	for view: BagEntryView in _by_category[_open]:
		var card := BattleBagRow.new()
		_grid.add_child(card)
		card.set_view(view)
		card.tapped.connect(_on_card_tapped.bind(view.item_id))
		_cards.append(card)
	var rows := _cards.size()
	var height := rows * UiTokens.BATTLE_BAG_ROW_HEIGHT \
		+ maxi(rows - 1, 0) * UiTokens.BATTLE_BAG_ROW_GAP
	_scroll.custom_minimum_size.y = minf(height, UiTokens.BAG_GRID_MAX_HEIGHT) \
		+ UiTokens.BAG_SCROLL_PAD * 2.0
	_scroll.scroll_vertical = 0


## Remet l'aperçu et la liste à jour après un changement d'objet ou de catégorie.
func _refresh() -> void:
	var views: Array = _by_category.get(_open, [])
	var has_items := not views.is_empty()
	_tabs_row.visible = has_items
	_divider.visible = has_items
	_scroll.visible = has_items
	_empty.visible = not has_items
	var view := _selected_view()
	_detail.visible = view != null
	if view == null:
		return
	_detail_icon.texture = view.get_icon()
	_detail_name.text = view.display_name
	_detail_quantity.text = view.quantity_text()
	_detail_text.text = view.description
	_action.text = view.action_label
	_flash_detail()


func _selected_view() -> BagEntryView:
	for card: BattleBagRow in _cards:
		if card.get_view().item_id == _selected:
			return card.get_view()
	return null


## Remise à zéro avant le premier show_bag : rien d'affiché.
func _clear() -> void:
	_by_category.clear()
	_categories.clear()
	_open = &""
	_selected = &""
	_refresh()


## L'aperçu s'éclaircit d'un fondu court quand l'objet change (jamais d'apparition sèche).
func _flash_detail() -> void:
	if _detail_tween != null:
		_detail_tween.kill()
		_detail_tween = null
	_detail.modulate.a = 1.0
	var time := UiTokens.ANIM_MICRO * speed_scale
	if time <= 0.0 or not is_inside_tree():
		return
	_detail.modulate.a = UiTokens.BAG_DETAIL_FADE_FROM
	_detail_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_detail_tween.tween_property(_detail, ^"modulate:a", 1.0, time)


func _on_tab_tapped(category_id: StringName) -> void:
	if _answered or not _shown or category_id == _open:
		return
	open_category(category_id)
	_haptic(UiTokens.HAPTIC_TICK_MS)
	category_opened.emit(category_id)


func _on_card_tapped(item_id: StringName) -> void:
	if _answered or not _shown:
		return
	if item_id != _selected:
		select_item(item_id)
	_haptic(UiTokens.HAPTIC_TICK_MS)
	item_previewed.emit(item_id)


func _on_action() -> void:
	if _answered or not _shown or _selected.is_empty():
		return
	_answered = true
	_haptic(UiTokens.HAPTIC_TAP_MS)
	item_chosen.emit(_selected)
	slide_out()


func _on_back() -> void:
	if _answered or not _shown:
		return
	_answered = true
	back_requested.emit()
	slide_out()


func _move_selection(step: Vector2i) -> void:
	var index := 0
	for i: int in _cards.size():
		if _cards[i].get_view().item_id == _selected:
			index = i
	var target := index + step.y
	if step.y == 0 or target < 0 or target >= _cards.size():
		return
	select_item(_cards[target].get_view().item_id)
	_scroll.ensure_control_visible(_cards[target])
	_haptic(UiTokens.HAPTIC_TICK_MS)
	item_previewed.emit(_selected)
