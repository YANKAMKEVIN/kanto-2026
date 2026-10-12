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
## Une carte inutilisable est touchée : elle tremble, [param text] est la raison complète
## (« Roucool a déjà tous ses PV. »). Rien n'est choisi.
signal target_refused(index: int, text: String)
## Tous les soins animés sont finis (après un show_targets qui en a lancé).
signal heal_finished
## ANNULER touché : l'hôte referme le choix, rien n'est utilisé.
signal back_requested

const CANCEL_TEXT := "ANNULER"
## Titre du choix compact, dans le panneau de l'objet du Sac (maquette ; l'objet est au-dessus).
const COMPACT_TITLE := "Utiliser sur…"
## Jalon 11, défaut (règle 4) : titre compact pour une CT.
const COMPACT_PERMANENT_TITLE := "Apprendre à…"
const CLOSE_ICON: Texture2D = preload("res://assets/ui/icons/menu/close.svg")
## « Utiliser Potion ×7 sur… » (texte d'interface).
const TITLE_FORMAT := "%s  %s  —  sur quel Pokémon ?"
## Jalon 11, défaut (règle 4) : titre d'une CT (pas de quantité, on l'apprend « à » un Pokémon).
const PERMANENT_TITLE_FORMAT := "%s  —  à quel Pokémon ?"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")

## Le refus s'écrit dans le titre du choix (combat). Faux : l'hôte l'affiche (UseResultBar du Sac).
var refusal_in_title: bool = true

## Compact (Sac du menu, MM.1) : une colonne de lignes de verre, sans cadre (le panneau de
## l'objet en est un), titre « Utiliser sur… » et ANNULER sur la même rangée.
var _compact: bool = false

var _view: PartyPickerView
var _healing: int = 0
var _heal_generation: int = 0
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
	var previous := _view if _shown else null
	_view = view
	_heal_generation += 1
	_healing = 0
	if _compact:
		_title.text = COMPACT_PERMANENT_TITLE if view.permanent else COMPACT_TITLE
	elif view.permanent:
		_title.text = PERMANENT_TITLE_FORMAT % view.item_name
	else:
		_title.text = TITLE_FORMAT % [view.item_name, "×%d" % view.quantity]
	_title.remove_theme_color_override(&"font_color")
	for card: PartyTargetCard in _cards:
		_grid.remove_child(card)
		# Différé : show_targets est rappelé depuis le toucher de cette carte (tapped).
		card.queue_free()
	_cards.clear()
	for i: int in view.size():
		var card := PartyTargetCard.new()
		if _compact:
			card.use_compact()
		_grid.add_child(card)
		card.speed_scale = speed_scale
		card.set_target(view.targets[i])
		card.set_selected(i == view.selected)
		card.tapped.connect(_on_card_tapped.bind(i))
		_cards.append(card)
		var old := previous.target_at(i) if previous != null else null
		var now := view.targets[i]
		if old != null and old.member != null and now.member != null \
				and old.member.species_id == now.member.species_id \
				and now.member.hp > old.member.hp:
			_healing += 1
			card.heal_finished.connect(_on_card_healed.bind(_heal_generation), CONNECT_ONE_SHOT)
			card.play_heal(old.member.hp)
	slide_in()


## Passe en version compacte (avant le premier show_targets) : une colonne, sans cadre ni largeur
## minimale, glisse depuis le bas.
func use_compact() -> void:
	_compact = true
	slide_direction = Vector2.DOWN
	custom_minimum_size.x = 0.0
	_frame.theme_type_variation = &""
	_frame.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_grid.columns = 1
	_grid.add_theme_constant_override(&"v_separation", UiTokens.PICKER_COMPACT_GAP)
	_title.theme_type_variation = &"MenuTargetsTitle"
	_cancel.theme_type_variation = &"MenuAction"
	_cancel.icon = CLOSE_ICON
	_scroll_pad_zero()


func is_compact() -> bool:
	return _compact


## Referme le choix sans rien choisir (back_requested), comme ANNULER. Sans effet s'il est fermé.
func cancel() -> void:
	if not _shown:
		return
	_haptic(UiTokens.HAPTIC_TICK_MS)
	back_requested.emit()


## Un soin animé est en cours (barres qui remontent).
func is_healing() -> bool:
	return _healing > 0


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


func _scroll_pad_zero() -> void:
	var pad := _scroll.get_child(0) as MarginContainer
	for side: StringName in [&"margin_left", &"margin_right"]:
		pad.add_theme_constant_override(side, 0)


func _on_card_tapped(index: int) -> void:
	if not _shown or _view == null:
		return
	var target := _view.target_at(index)
	if target == null:
		return
	if not target.usable:
		_refuse(index, target)
		return
	_haptic(UiTokens.HAPTIC_TAP_MS)
	target_chosen.emit(index)


func _refuse(index: int, target: PartyTargetView) -> void:
	var text := target.refusal if not target.refusal.is_empty() else target.reason
	_cards[index].shake()
	_haptic(UiTokens.HAPTIC_REFUSE_MS)
	if refusal_in_title and not text.is_empty():
		_title.text = text
		_title.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
	target_refused.emit(index, text)


func _on_card_healed(generation: int) -> void:
	if generation != _heal_generation:
		return
	_healing = maxi(_healing - 1, 0)
	if _healing == 0:
		heal_finished.emit()
