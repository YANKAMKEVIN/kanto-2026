class_name PartyPicker
extends BattleWidget
## Le choix du Pokémon après UTILISER (dossier 08 §3 ; jalon-06.md §6.8), le même dans le Sac du
## menu et en combat : toute l'équipe en cartes (portrait, nom, Nv., PV), dans l'ordre.
## - Un Pokémon qui peut recevoir l'objet porte une flèche ; le toucher émet UN
##   [signal target_chosen] (aucune confirmation).
## - Un Pokémon qui ne le peut pas reste visible avec **sa raison** (« PV déjà au maximum »,
##   « Ce Pokémon est K.O. ») : le toucher n'émet rien, jamais un bouton grisé sans explication.
## - [member PartyPickerView.selected] (UTILISER À NOUVEAU) est mis en avant (liseré ACCENT).
## - ANNULER (ou [method cancel], appelé par le retour Android) : [signal back_requested].
## Rappelé pendant qu'il est affiché (après un usage, les PV ont changé), [method show_targets]
## met les cartes à jour sans rejouer l'entrée : le choix reste ouvert pour en changer.
## Placement : par l'hôte (BagScreen dans la zone du Sac ; BattleHudLayout en combat). Largeur
## minimale : PICKER_COLUMNS colonnes de PICKER_COLUMN_WIDTH.

## Une cible utilisable est touchée (jamais une autre).
signal target_chosen(index: int)
## ANNULER touché : l'hôte referme le choix, rien n'est utilisé.
signal back_requested

const CANCEL_TEXT := "ANNULER"
## « Utiliser Potion ×7 sur… » (texte d'interface).
const TITLE_FORMAT := "%s  %s  —  sur quel Pokémon ?"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")

var _view: PartyPickerView
var _cards: Array[PartyTargetCard] = []
var _frame: PanelContainer
var _title: Label
var _cancel: Button
var _scroll: ScrollContainer
var _grid: GridContainer


func _ready() -> void:
	slide_direction = Vector2.LEFT
	super._ready()
	_build()


## Montre le choix pour [param view] : s'ouvre (glisse) s'il ne l'est pas, sinon se met à jour.
func show_targets(view: PartyPickerView) -> void:
	_view = view
	_title.text = TITLE_FORMAT % [view.item_name, "×%d" % view.quantity]
	for card: PartyTargetCard in _cards:
		_grid.remove_child(card)
		# Différé : show_targets est rappelé depuis le toucher de cette carte (tapped).
		card.queue_free()
	_cards.clear()
	for i: int in view.size():
		var card := PartyTargetCard.new()
		_grid.add_child(card)
		card.set_target(view.targets[i])
		card.set_selected(i == view.selected)
		card.tapped.connect(_on_card_tapped.bind(i))
		_cards.append(card)
	slide_in()


## Referme le choix sans rien choisir (back_requested), comme ANNULER. Sans effet s'il est fermé.
func cancel() -> void:
	if not _shown:
		return
	_haptic(UiTokens.HAPTIC_TICK_MS)
	back_requested.emit()


func get_view() -> PartyPickerView:
	return _view


func get_cards() -> Array[PartyTargetCard]:
	return _cards


func get_card(index: int) -> PartyTargetCard:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func get_cancel_button() -> Button:
	return _cancel


func get_title_text() -> String:
	return _title.text


func get_frame() -> PanelContainer:
	return _frame


func _build() -> void:
	custom_minimum_size.x = UiTokens.PICKER_COLUMNS * UiTokens.PICKER_COLUMN_WIDTH \
		+ (UiTokens.PICKER_COLUMNS - 1) * UiTokens.PICKER_GAP + UiTokens.MENU_PANEL_PAD * 2
	_frame = PanelContainer.new()
	_frame.theme_type_variation = &"MenuPanel"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.add_child(_frame)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.PICKER_GAP)
	_frame.add_child(column)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(header)
	_title = Label.new()
	_title.theme_type_variation = &"PickerTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(_title)
	_cancel = Button.new()
	_cancel.theme_type_variation = &"PanelButton"
	_cancel.text = CANCEL_TEXT
	_cancel.icon = BACK_ICON
	_cancel.focus_mode = Control.FOCUS_NONE
	_cancel.custom_minimum_size = Vector2(UiTokens.MENU_CARD_ICON * 2, UiTokens.TOUCH_MIN)
	_cancel.pressed.connect(cancel)
	header.add_child(_cancel)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		pad.add_theme_constant_override(side, UiTokens.BAG_SCROLL_PAD)
	_scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.columns = UiTokens.PICKER_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override(&"h_separation", UiTokens.PICKER_GAP)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.PICKER_GAP)
	pad.add_child(_grid)


func _on_card_tapped(index: int) -> void:
	if not _shown or _view == null:
		return
	var target := _view.target_at(index)
	if target == null or not target.usable:
		return
	_haptic(UiTokens.HAPTIC_TAP_MS)
	target_chosen.emit(index)
