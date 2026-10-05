class_name ShopScreen
extends MenuScreen
## Écran de la Boutique (dossier 09 §9 ; jalon-07.md §6.4 et §6.10), dans le langage du Sac du
## menu : à gauche RETOUR, les onglets ACHETER / VENDRE et l'argent ; au centre les objets en
## cartes ([BagItemCard]) avec leur prix ; à droite l'aperçu, QUANTITÉ, TOTAL et CONFIRMER.
##
## Il reçoit un [ShopView] et **ne fait aucune règle** : ni argent, ni Sac, ni prix. Il garde
## l'onglet affiché, l'objet sélectionné et la quantité (bornée par
## [method ShopEntryView.clamp_quantity]) ; le TOTAL est recalculé ici à chaque cran
## ([method ShopViews.total_text]), sans aller-retour. Il émet des intentions ; le directeur les
## applique et rappelle [method show_shop].
## - Un toucher sur une carte = la sélectionner (jamais un achat) ; faire glisser la liste ne
##   sélectionne rien (le seuil de [BagTile] est TAP_SLOP, celui de [TapGuard]).
## - CONFIRMER : **un seul** signal par toucher ([signal buy_requested] / [signal sell_requested]),
##   jamais de seconde confirmation à l'achat. Objet indisponible (argent insuffisant) : aucun
##   signal ; la carte de la raison tremble et la raison s'écrit dans la barre de résultat.
## - [method show_result] : « Merci ! » (succès) ou le refus (tremblement de CONFIRMER).
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN.

## Onglet touché ([constant ShopViews.MODE_BUY] ou [constant ShopViews.MODE_SELL]).
signal mode_changed(mode: StringName)
## CONFIRMER en ACHETER.
signal buy_requested(item_id: StringName, quantity: int)
## CONFIRMER en VENDRE ; [param confirmed] est faux (la confirmation d'un favori vient du menu).
signal sell_requested(item_id: StringName, quantity: int, confirmed: bool)

const FAVORITE_TEXT := "FAVORI"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const STAR_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const COIN_ICON: Texture2D = preload("res://assets/ui/icons/shop/coin.svg")
const TAB_SCENE: PackedScene = preload("res://game/ui/bag/bag_category_tab.tscn")
const CARD_SCENE: PackedScene = preload("res://game/ui/bag/bag_item_card.tscn")
## Illustration de chaque onglet.
const MODE_ICONS: Dictionary[StringName, Texture2D] = {
	ShopViews.MODE_BUY: preload("res://assets/ui/icons/battle/bag.svg"),
	ShopViews.MODE_SELL: preload("res://assets/ui/icons/shop/coin.svg"),
}

var _view: ShopView
var _mode: StringName = ShopViews.MODE_BUY
var _selected: StringName = &""
var _quantity: int = 1
var _tabs: Dictionary[StringName, BagCategoryTab] = {}
var _cards: Array[BagItemCard] = []
var _cells: Dictionary[StringName, Control] = {}
var _shake_tween: Tween
var _detail_tween: Tween

var _back: Button
var _tabs_box: VBoxContainer
var _money_panel: PanelContainer
var _money: Label
var _title: Label
var _scroll: ScrollContainer
var _flow: HFlowContainer
var _empty: Label
var _center_panel: PanelContainer
var _detail_panel: PanelContainer
var _detail_column: VBoxContainer
var _icon: TextureRect
var _name: Label
var _owned: Label
var _price: Label
var _favorite_pill: PanelContainer
var _description: Label
var _quantity_caption: Label
var _stepper: QuantityStepper
var _total_caption: Label
var _total: Label
var _note: Label
var _confirm: Button
var _result: UseResultBar


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	add_child(body)
	_build_left(body)
	var middle := VBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	body.add_child(middle)
	_build_center(middle)
	_result = UseResultBar.new()
	_result.speed_scale = speed_scale
	middle.add_child(_result)
	_build_detail(body)
	_refresh()


## Affiche [param view]. Rappelé pendant que l'écran est affiché dans le **même onglet** (après
## un achat ou une vente), il met à jour sans rejouer l'entrée : l'objet sélectionné, la
## quantité (reprise dans ses nouvelles bornes), le défilement et la barre de résultat restent.
## Un autre onglet, ou une première ouverture : première carte, quantité 1.
func show_shop(view: ShopView) -> void:
	var keep := visible and _view != null and _view.mode == view.mode
	var scroll := _scroll.scroll_vertical
	var wanted := _selected
	_view = view
	_mode = view.mode
	if not keep:
		_result.clear()
		wanted = &""
		_quantity = 1
	_build_tabs()
	_rebuild_cards()
	var entry := view.entry(wanted) if not wanted.is_empty() else null
	if entry == null:
		entry = view.entries[0] if not view.entries.is_empty() else null
		if keep:
			_quantity = 1
	_selected = entry.item_id if entry != null else &""
	_quantity = entry.clamp_quantity(_quantity) if entry != null else 1
	_mark_selection()
	_refresh()
	if keep:
		_scroll.set_deferred(&"scroll_vertical", scroll)


## Montre le résultat d'une transaction : [param ok] « Merci ! » (succès), sinon le refus
## (CONFIRMER tremble, vibration courte). Un texte vide n'affiche rien.
func show_result(text: String, ok: bool) -> void:
	if text.is_empty():
		return
	_result.speed_scale = speed_scale
	_result.show_result(text, false, 1 if ok else 0)
	if not ok:
		_refuse_feedback()


## Retour (retour Android) : l'écran n'a rien à refermer lui-même (la confirmation d'une vente
## est tenue par [TrainerMenu]). Toujours faux : l'hôte ferme la Boutique.
func go_back() -> bool:
	return false


func get_view() -> ShopView:
	return _view


func get_mode() -> StringName:
	return _mode


func get_selected_id() -> StringName:
	return _selected


func get_quantity() -> int:
	return _quantity


## Sélectionne [param item_id] (sans signal) ; quantité remise à 1.
func select_item(item_id: StringName) -> void:
	if _view == null or _view.entry(item_id) == null:
		return
	_select(item_id)


## Pose la quantité (bornée, sans signal).
func set_quantity(quantity: int) -> void:
	var entry := _selected_entry()
	if entry == null:
		return
	_quantity = entry.clamp_quantity(quantity)
	_refresh_quantity()


func get_back_button() -> Button:
	return _back


func get_tabs() -> Dictionary[StringName, BagCategoryTab]:
	return _tabs


func get_tab(mode: StringName) -> BagCategoryTab:
	return _tabs.get(mode)


func get_cards() -> Array[BagItemCard]:
	return _cards


func get_card(item_id: StringName) -> BagItemCard:
	for card: BagItemCard in _cards:
		if card.get_view().item_id == item_id:
			return card
	return null


## Prix écrit sous la carte de [param item_id] (« 200 ₽ »), vide si absente.
func get_card_price_text(item_id: StringName) -> String:
	var cell: Control = _cells.get(item_id)
	if cell == null:
		return ""
	return (cell.get_child(1) as Label).text


func get_stepper() -> QuantityStepper:
	return _stepper


func get_confirm_button() -> Button:
	return _confirm


## CONFIRMER agit (objet disponible) ; faux : il tremble et dit pourquoi.
func is_confirm_active() -> bool:
	var entry := _selected_entry()
	return entry != null and entry.is_available()


func get_result_bar() -> UseResultBar:
	return _result


func get_scroll() -> ScrollContainer:
	return _scroll


func get_title_text() -> String:
	return _title.text


func get_money_text() -> String:
	return _money.text if _money_panel.visible else ""


func get_detail_name() -> String:
	return _name.text


func get_detail_owned() -> String:
	return _owned.text


func get_detail_price() -> String:
	return _price.text


func get_detail_text() -> String:
	return _description.text


func get_total_text() -> String:
	return _total.text


## Raison affichée sous TOTAL (objet indisponible), vide sinon.
func get_note_text() -> String:
	return _note.text if _note.visible else ""


func is_favorite_pill_shown() -> bool:
	return _favorite_pill.visible


func is_detail_shown() -> bool:
	return _detail_panel.visible


func get_detail_panel() -> PanelContainer:
	return _detail_panel


func get_center_panel() -> PanelContainer:
	return _center_panel


func get_empty_label() -> Label:
	return _empty


## La carte de [param item_id] tremble (refus) ; vrai si CONFIRMER tremble encore.
func is_shaking() -> bool:
	return _shake_tween != null and _shake_tween.is_valid() and _shake_tween.is_running()


## Tous les textes visibles, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(self, texts)
	return texts


## Tous les contrôles qui répondent au toucher (boutons visibles et actifs, cartes).
func get_touch_controls() -> Array[Control]:
	var found: Array[Control] = []
	_collect_touch(self, found)
	return found


func _build_left(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.custom_minimum_size.x = UiTokens.BAG_SCREEN_LEFT_WIDTH
	column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	parent.add_child(column)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = ShopViews.LABEL_BACK
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.MENU_CARD_ICON * 2, UiTokens.TOUCH_MIN)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.pressed.connect(_on_back)
	column.add_child(_back)
	var tabs_panel := PanelContainer.new()
	tabs_panel.theme_type_variation = &"MenuPanel"
	column.add_child(tabs_panel)
	_tabs_box = VBoxContainer.new()
	_tabs_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabs_box.add_theme_constant_override(&"separation", UiTokens.BAG_TAB_GAP)
	tabs_panel.add_child(_tabs_box)
	_money_panel = PanelContainer.new()
	_money_panel.theme_type_variation = &"MenuPanel"
	_money_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_money_panel)
	var money_column := VBoxContainer.new()
	money_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_money_panel.add_child(money_column)
	var money_caption := Label.new()
	money_caption.theme_type_variation = &"ShopMoneyLabel"
	money_caption.text = TrainerView.MONEY_LABEL.to_upper()
	money_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_column.add_child(money_caption)
	var money_row := HBoxContainer.new()
	money_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	money_column.add_child(money_row)
	var coin := TextureRect.new()
	coin.texture = COIN_ICON
	coin.modulate = UiTokens.ACCENT
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.custom_minimum_size = Vector2.ONE * UiTokens.SHOP_COIN_ICON
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money_row.add_child(coin)
	_money = Label.new()
	_money.theme_type_variation = &"ShopMoney"
	_money.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money.clip_text = true
	money_row.add_child(_money)


func _build_center(parent: Control) -> void:
	_center_panel = PanelContainer.new()
	_center_panel.theme_type_variation = &"MenuPanel"
	_center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_center_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_center_panel.add_child(column)
	_title = Label.new()
	_title.theme_type_variation = &"BagTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_title)
	var divider := Panel.new()
	divider.theme_type_variation = &"BagDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size.y = UiTokens.BORDER_WIDTH
	column.add_child(divider)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		pad.add_theme_constant_override(side, UiTokens.BAG_SCROLL_PAD)
	_scroll.add_child(pad)
	_flow = HFlowContainer.new()
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override(&"h_separation", UiTokens.BAG_CARD_GAP)
	_flow.add_theme_constant_override(&"v_separation", UiTokens.BAG_CARD_GAP)
	pad.add_child(_flow)
	_empty = Label.new()
	_empty.theme_type_variation = &"BagEmpty"
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = false
	column.add_child(_empty)


func _build_detail(parent: Control) -> void:
	_detail_panel = PanelContainer.new()
	_detail_panel.theme_type_variation = &"MenuPanel"
	_detail_panel.custom_minimum_size.x = UiTokens.SHOP_DETAIL_WIDTH
	parent.add_child(_detail_panel)
	_detail_column = VBoxContainer.new()
	_detail_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_detail_panel.add_child(_detail_column)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override(&"separation", UiTokens.GAP)
	_detail_column.add_child(head)
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.SHOP_ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(_icon)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override(&"separation", 0)
	head.add_child(names)
	_name = _label(&"ShopName", names)
	_name.clip_text = true
	_owned = _label(&"ShopOwned", names)
	_price = _label(&"ShopUnitPrice", names)
	_favorite_pill = PanelContainer.new()
	_favorite_pill.theme_type_variation = &"TeamPill"
	_favorite_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_favorite_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	names.add_child(_favorite_pill)
	var pill_row := HBoxContainer.new()
	pill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_favorite_pill.add_child(pill_row)
	var star := TextureRect.new()
	star.texture = STAR_ICON
	star.modulate = UiTokens.ACCENT
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.custom_minimum_size = Vector2.ONE * UiTokens.BAG_STAR_ICON
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pill_row.add_child(star)
	var pill_text := _label(&"TeamPillText", pill_row)
	pill_text.text = FAVORITE_TEXT
	_description = _label(&"ShopDescription", _detail_column)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_column.add_child(spacer)
	_quantity_caption = _label(&"ShopCaption", _detail_column)
	_quantity_caption.text = ShopViews.LABEL_QUANTITY
	_stepper = QuantityStepper.new()
	_stepper.changed.connect(_on_stepper_changed)
	_detail_column.add_child(_stepper)
	var total_row := HBoxContainer.new()
	total_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	_detail_column.add_child(total_row)
	_total_caption = _label(&"ShopCaption", total_row)
	_total_caption.text = ShopViews.LABEL_TOTAL
	_total_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_total = _label(&"ShopTotal", total_row)
	_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_note = _label(&"BagNote", _detail_column)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm = Button.new()
	_confirm.theme_type_variation = &"AccentButton"
	_confirm.text = ShopViews.LABEL_CONFIRM
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.custom_minimum_size.y = UiTokens.TOUCH_MIN
	_confirm.pressed.connect(_on_confirm)
	_detail_column.add_child(_confirm)


func _label(variation: StringName, parent: Control) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _build_tabs() -> void:
	for tab: BagCategoryTab in _tabs.values():
		_tabs_box.remove_child(tab)
		tab.queue_free()  # différé : rappelé depuis le toucher de cet onglet
	_tabs.clear()
	for i: int in _view.modes.size():
		var mode := _view.modes[i]
		var tab := TAB_SCENE.instantiate() as BagCategoryTab
		_tabs_box.add_child(tab)
		var label := _view.mode_labels[i] if i < _view.mode_labels.size() else String(mode)
		tab.set_category(mode, label, MODE_ICONS.get(mode, BagEntryView.GENERIC_ICON))
		tab.set_selected(mode == _mode)
		tab.tapped.connect(_on_tab_tapped.bind(mode))
		_tabs[mode] = tab


func _rebuild_cards() -> void:
	for cell: Control in _cells.values():
		_flow.remove_child(cell)
		cell.queue_free()  # différé : rappelé depuis le toucher de cette carte
	_cells.clear()
	_cards.clear()
	for entry: ShopEntryView in _view.entries:
		var cell := VBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_constant_override(&"separation", 0)
		_flow.add_child(cell)
		var card := CARD_SCENE.instantiate() as BagItemCard
		cell.add_child(card)
		card.set_view(entry.card)
		card.tapped.connect(_on_card_tapped.bind(entry.item_id))
		var price := Label.new()
		price.theme_type_variation = &"ShopCardPrice"
		price.text = entry.price_text
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.custom_minimum_size.y = UiTokens.SHOP_CARD_PRICE_HEIGHT
		cell.add_child(price)
		var dim := 1.0 if entry.is_available() else UiTokens.SHOP_DISABLED_ALPHA
		card.modulate.a = dim
		price.modulate.a = dim
		_cells[entry.item_id] = cell
		_cards.append(card)
	_scroll.scroll_vertical = 0


func _mark_selection() -> void:
	for card: BagItemCard in _cards:
		card.set_selected(card.get_view().item_id == _selected)


func _select(item_id: StringName) -> void:
	_selected = item_id
	var entry := _selected_entry()
	_quantity = 1 if entry == null else entry.clamp_quantity(1)
	_mark_selection()
	_refresh()


func _selected_entry() -> ShopEntryView:
	if _view == null or _selected.is_empty():
		return null
	return _view.entry(_selected)


## Remet textes, aperçu et boutons à jour pour la vue et l'objet sélectionné.
func _refresh() -> void:
	var empty := _view == null or _view.is_empty()
	var mode_label := ""
	if _view != null:
		var index := _view.modes.find(_mode)
		mode_label = _view.mode_labels[index] if index >= 0 and index < _view.mode_labels.size() \
			else ""
	_title.text = mode_label
	_money_panel.visible = _view != null and not _view.money_text.is_empty()
	_money.text = "" if _view == null else _view.money_text
	_scroll.visible = not empty
	_empty.visible = empty
	_empty.text = "" if _view == null else _view.empty_text
	_detail_panel.visible = not empty
	var entry := _selected_entry()
	if entry == null:
		return
	_icon.texture = entry.get_icon()
	_name.text = entry.name
	_owned.text = entry.owned_text
	_price.text = entry.price_text
	_favorite_pill.visible = entry.favorite
	_description.text = entry.description
	_description.visible = not entry.description.is_empty()
	_refresh_quantity()
	_flash_detail()


## Quantité, TOTAL, raison et CONFIRMER pour l'objet sélectionné.
func _refresh_quantity() -> void:
	var entry := _selected_entry()
	if entry == null:
		return
	_stepper.configure(entry.max_quantity, _quantity)
	_total.text = ShopViews.total_text(entry.unit_price, _quantity)
	var available := entry.is_available()
	_note.text = entry.reason
	_note.visible = not available and not entry.reason.is_empty()
	_confirm.modulate.a = 1.0 if available else UiTokens.SHOP_DISABLED_ALPHA
	_total.modulate.a = 1.0 if available else UiTokens.SHOP_DISABLED_ALPHA


func _flash_detail() -> void:
	if _detail_tween != null:
		_detail_tween.kill()
		_detail_tween = null
	_detail_column.modulate.a = 1.0
	var time := UiTokens.ANIM_MICRO * speed_scale
	if time <= 0.0 or not is_inside_tree():
		return
	_detail_column.modulate.a = UiTokens.BAG_DETAIL_FADE_FROM
	_detail_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_detail_tween.tween_property(_detail_column, ^"modulate:a", 1.0, time)


## Refus : CONFIRMER tremble (PICKER_SHAKE_TIME) et vibre brièvement.
func _refuse_feedback() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_REFUSE_MS)
	var time := UiTokens.PICKER_SHAKE_TIME * speed_scale
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var base := _confirm.position.x
	if time <= 0.0 or not is_inside_tree():
		_shake_tween = null
		return
	var steps := UiTokens.PICKER_SHAKE_STEPS
	var step_time := time / float(steps * 2 + 1)
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE)
	for i: int in steps:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var decay := 1.0 - float(i) / float(steps)
		_shake_tween.tween_property(_confirm, ^"position:x",
			base + dir * UiTokens.PICKER_SHAKE_AMPLITUDE * decay, step_time)
		_shake_tween.tween_property(_confirm, ^"position:x", base, step_time)
	_shake_tween.tween_callback(func() -> void: _confirm.position.x = base)


func _on_tab_tapped(mode: StringName) -> void:
	_result.clear()
	if mode == _mode:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	for id: StringName in _tabs:
		_tabs[id].set_selected(id == mode)
	mode_changed.emit(mode)


func _on_card_tapped(item_id: StringName) -> void:
	_result.clear()
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	if item_id != _selected:
		_select(item_id)


func _on_stepper_changed(quantity: int) -> void:
	_result.clear()
	_quantity = quantity
	var entry := _selected_entry()
	if entry != null:
		_total.text = ShopViews.total_text(entry.unit_price, _quantity)


func _on_confirm() -> void:
	var entry := _selected_entry()
	if entry == null:
		return
	if not entry.is_available():
		Haptics.vibrate(UiTokens.HAPTIC_REFUSE_MS)
		_refuse_feedback()
		if not entry.reason.is_empty():
			_result.speed_scale = speed_scale
			_result.show_result(entry.reason, false, 0)
		return
	_result.clear()
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	var quantity := entry.clamp_quantity(_quantity)
	if _mode == ShopViews.MODE_SELL:
		sell_requested.emit(entry.item_id, quantity, false)
	else:
		buy_requested.emit(entry.item_id, quantity)


func _on_back() -> void:
	back_requested.emit()


func _collect_texts(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var label := child as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			into.append(label.text)
		var button := child as Button
		if button != null and button.is_visible_in_tree() and not button.text.is_empty():
			into.append(button.text)
		_collect_texts(child, into)


func _collect_touch(node: Node, into: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var control := child as Control
		if control != null and control.is_visible_in_tree():
			if control is BaseButton and not (control as BaseButton).disabled:
				into.append(control)
			elif control is BagTile and (control as BagTile).mouse_filter != \
					Control.MOUSE_FILTER_IGNORE:
				into.append(control)
		_collect_touch(child, into)
