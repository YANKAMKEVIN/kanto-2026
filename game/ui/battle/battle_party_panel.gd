class_name BattlePartyPanel
extends BattleWidget
## Le panneau ÉQUIPE du combat (jalon 7, dossier 05 §14, jalon-07.md §15.23) : panneau latéral
## sombre translucide en bas à gauche, au-dessus du bouton « ‹ », comme le Sac de combat ;
## l'adversaire (centre droit) reste visible derrière. Pas d'écran noir.
##
## Composition : en-tête (icône ÉQUIPE et titre ; après un K.O., la question « Qui envoyer au
## combat ? »), une carte par Pokémon de l'équipe dans l'ordre (BattlePartyCard : type, nom,
## Nv., PV, « ACTIF », « K.O. » et sa raison), puis le pied : le nom du Pokémon choisi et UNE
## action claire, ENVOYER.
##
## Gestes (aucune fenêtre de confirmation, deux gestes pour envoyer) :
## - toucher une carte qui peut être envoyée = elle est SÉLECTIONNÉE (pokemon_selected), rien
##   n'est envoyé ; la première qui peut l'être est déjà sélectionnée ;
## - toucher une carte qui ne peut pas l'être (le Pokémon actif, un K.O.) = elle tremble, sa
##   raison s'écrit dans le pied (pokemon_refused), rien n'est choisi ;
## - ENVOYER = un seul pokemon_chosen(index), le panneau se ferme et se tait jusqu'au prochain
##   show_party ;
## - « ‹ » (ou Échap) = back_requested, le panneau se ferme, rien n'est choisi. Après un K.O.
##   ([param forced] de show_party), pas de « ‹ » : il faut envoyer quelqu'un.
## Clavier (tests sur Mac) : flèches = sélection, ui_accept = ENVOYER.
## Placement : BattleHudLayout.Slot.PARTY (l'hôte appelle BattleHudLayout.place) ; il recouvre
## la carte joueur et les pastilles, que l'hôte fait sortir avant.

## ENVOYER touché : place dans l'équipe du Pokémon choisi (une seule fois par ouverture).
signal pokemon_chosen(index: int)
## « ‹ » touché : le panneau se ferme sans rien choisir (jamais après un K.O.).
signal back_requested
## Une carte qui peut être envoyée est touchée : elle est sélectionnée.
signal pokemon_selected(index: int)
## Une carte qui ne peut pas être envoyée est touchée : [param reason] est écrite dans le pied.
signal pokemon_refused(index: int, reason: String)

const TITLE_ICON: Texture2D = preload("res://assets/ui/icons/battle/team.svg")
## Textes d'interface (provisoires).
const TITLE := "ÉQUIPE"
const SEND_TEXT := "ENVOYER"

var _views: Array[BattlePartyView] = []
var _cards: Array[BattlePartyCard] = []
var _selected: int = -1
var _forced: bool = false
var _answered: bool = false
var _frame: PanelContainer
var _title: Label
var _grid: GridContainer
var _footer_label: Label
var _send: Button

@onready var _back: BattleBackButton = %BackButton


func _ready() -> void:
	slide_direction = Vector2.LEFT
	super._ready()
	_build()
	_back.back_requested.connect(_on_back)
	_back.haptic_played.connect(haptic_played.emit)


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
		_on_send()


## Montre l'équipe [param views] (dans l'ordre). [param forced] : remplacement après un K.O.
## (pas de « ‹ », le titre devient [param prompt]). La première carte qui peut être envoyée est
## sélectionnée. Réarme le panneau après un choix.
func show_party(views: Array[BattlePartyView], forced: bool = false,
		prompt: String = "") -> void:
	_back.speed_scale = speed_scale
	_back.haptics_enabled = haptics_enabled
	_views = views.duplicate()
	_forced = forced
	_answered = false
	_title.text = prompt if forced and not prompt.is_empty() else TITLE
	_rebuild_cards()
	_selected = -1
	for view: BattlePartyView in _views:
		if view.can_send:
			_selected = view.party_index
			break
	_refresh()
	slide_in()


## Sélectionne la carte [param index] si son Pokémon peut être envoyé (sinon rien ne change).
## N'émet aucun signal.
func select(index: int) -> void:
	var view := _view_at(index)
	if view == null or not view.can_send:
		return
	_selected = index
	_refresh()


## Place du Pokémon sélectionné (−1 : aucun ne peut être envoyé).
func get_selected_index() -> int:
	return _selected


func get_cards() -> Array[BattlePartyCard]:
	return _cards


func get_card(index: int) -> BattlePartyCard:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func get_send_button() -> Button:
	return _send


func get_back_button() -> BattleBackButton:
	return _back


func get_title_text() -> String:
	return _title.text


## Texte du pied : le nom du Pokémon choisi, ou la raison du dernier refus.
func get_footer_text() -> String:
	return _footer_label.text


## Rectangle du cadre (écran), hors bouton « ‹ ».
func get_frame_rect() -> Rect2:
	return _frame.get_global_rect()


## Remplacement après un K.O. (pas de retour possible).
func is_forced() -> bool:
	return _forced


## Un choix ou « ‹ » a été fait : le panneau se tait jusqu'au prochain show_party.
func is_answered() -> bool:
	return _answered


func slide_in() -> void:
	if not _forced:
		_back.slide_in()
	await super.slide_in()


func slide_out() -> void:
	_back.slide_out()
	await super.slide_out()


func _build() -> void:
	var below := float(UiTokens.BATTLE_BACK_SIZE + UiTokens.GAP)
	_frame = PanelContainer.new()
	_frame.theme_type_variation = &"BagPanel"
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame.anchor_left = 0.0
	_frame.anchor_right = 0.0
	_frame.anchor_top = 1.0
	_frame.anchor_bottom = 1.0
	_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_frame.offset_left = 0.0
	_frame.offset_right = UiTokens.BAG_PANEL_WIDTH
	_frame.offset_bottom = -below
	_frame.offset_top = -below
	_frame.custom_minimum_size.x = UiTokens.BAG_PANEL_WIDTH
	_body.add_child(_frame)
	_body.move_child(_frame, 0)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override(&"separation", UiTokens.BAG_ROW_GAP)
	_frame.add_child(content)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override(&"separation", UiTokens.GAP)
	content.add_child(header)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = TITLE_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.BAG_TITLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(icon)
	_title = Label.new()
	_title.theme_type_variation = &"BagTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.text = TITLE
	header.add_child(_title)

	var divider := Panel.new()
	divider.theme_type_variation = &"BagDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size.y = UiTokens.BORDER_WIDTH
	content.add_child(divider)

	_grid = GridContainer.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.columns = UiTokens.BATTLE_PARTY_COLUMNS
	_grid.add_theme_constant_override(&"h_separation", UiTokens.PICKER_GAP)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.PICKER_GAP)
	content.add_child(_grid)

	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.custom_minimum_size.y = UiTokens.BATTLE_PARTY_FOOTER_HEIGHT
	footer.add_theme_constant_override(&"separation", UiTokens.GAP)
	content.add_child(footer)
	_footer_label = Label.new()
	_footer_label.theme_type_variation = &"BagDetailName"
	_footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_footer_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_footer_label.clip_text = true
	footer.add_child(_footer_label)
	_send = Button.new()
	_send.theme_type_variation = &"AccentButton"
	_send.text = SEND_TEXT
	_send.focus_mode = Control.FOCUS_NONE
	_send.custom_minimum_size = UiTokens.BAG_ACTION_SIZE
	_send.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_send.pressed.connect(_on_send)
	footer.add_child(_send)


func _rebuild_cards() -> void:
	for card: BattlePartyCard in _cards:
		_grid.remove_child(card)
		card.free()
	_cards.clear()
	for view: BattlePartyView in _views:
		var card := BattlePartyCard.new()
		_grid.add_child(card)
		card.speed_scale = speed_scale
		card.set_view(view)
		card.tapped.connect(_on_card_tapped.bind(view.party_index))
		_cards.append(card)


## Sélection et pied à jour : le Pokémon choisi, « Nv. », et ENVOYER ; aucun : ENVOYER caché.
func _refresh() -> void:
	for card: BattlePartyCard in _cards:
		card.set_selected(card.get_view().party_index == _selected)
	var view := _view_at(_selected)
	_send.visible = view != null
	_footer_label.remove_theme_color_override(&"font_color")
	_footer_label.text = "%s  %s %d" % [view.display_name, BattleInfoCard.LEVEL_TAG,
		view.level] if view != null else ""


func _view_at(index: int) -> BattlePartyView:
	for view: BattlePartyView in _views:
		if view.party_index == index:
			return view
	return null


func _on_card_tapped(index: int) -> void:
	if _answered or not _shown:
		return
	var view := _view_at(index)
	if view == null:
		return
	if not view.can_send:
		var card := get_card(_views.find(view))
		if card != null:
			card.shake()
		_footer_label.text = "%s : %s" % [view.display_name, view.reason]
		_footer_label.add_theme_color_override(&"font_color", UiTokens.HP_LOW)
		_haptic(UiTokens.HAPTIC_REFUSE_MS)
		pokemon_refused.emit(index, view.reason)
		return
	if index != _selected:
		select(index)
	else:
		_refresh()
	_haptic(UiTokens.HAPTIC_TICK_MS)
	pokemon_selected.emit(index)


func _on_send() -> void:
	if _answered or not _shown or _view_at(_selected) == null:
		return
	_answered = true
	_haptic(UiTokens.HAPTIC_TAP_MS)
	pokemon_chosen.emit(_selected)
	slide_out()


func _on_back() -> void:
	if _answered or not _shown or _forced:
		return
	_answered = true
	back_requested.emit()
	slide_out()


func _move_selection(step: Vector2i) -> void:
	var columns := UiTokens.BATTLE_PARTY_COLUMNS
	var position_index := maxi(_views.find(_view_at(_selected)), 0)
	var cell := Vector2i(position_index % columns,
		floori(position_index / float(columns))) + step
	var target := cell.y * columns + cell.x
	if cell.x < 0 or cell.x >= columns or cell.y < 0 or target >= _views.size():
		return
	var view := _views[target]
	if not view.can_send:
		return
	select(view.party_index)
	_haptic(UiTokens.HAPTIC_TICK_MS)
	pokemon_selected.emit(_selected)
