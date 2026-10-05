class_name StorageScreen
extends MenuScreen
## Écran Stockage (dossier 09 §8, §19 ; jalon-07.md §6.4, §6.9) : trois colonnes. À gauche l'ÉQUIPE
## (six emplacements), au centre le Pokémon sélectionné (la vedette de l'Équipe, plus petite) et
## ses actions DÉPOSER / REPRENDRE, FAVORI et « ⋯ » (menu secondaire : LIBÉRER), à droite le
## STOCKAGE en grille défilante.
##
## Il reçoit un [StorageView] et **ne décide d'aucune règle** : il émet des intentions, le
## directeur applique [StorageRules], rappelle [method show_storage] (vue neuve) ou
## [method show_refusal] (rien ne change).
## - **Glisser = un signal, bouton = le même** : appui long sur une carte de l'ÉQUIPE puis la poser
##   sur le STOCKAGE → [signal deposit_requested], comme DÉPOSER ; dans l'autre sens
##   [signal withdraw_requested], comme REPRENDRE. Jamais de réordonnancement ici.
## - Toucher une carte : [signal selected] (le directeur renvoie la vue de ce Pokémon). Faire
##   défiler la grille ne sélectionne rien ([StorageCard], [TapGuard] : seuil TAP_SLOP).
## - Aucune action n'est grisée : un refus se montre ([method show_refusal] : la carte tremble, la
##   raison s'écrit sur la fiche).
## - LIBÉRER n'existe que dans le menu « ⋯ » ; il émet [signal release_requested], puis le
##   directeur montre la confirmation ([method ask_release], [ChoiceCards] LIBÉRER / ANNULER) ou
##   refuse (favori, dernier Pokémon) **sans confirmation ni contournement**.
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN ; la
## grille prend la largeur restante (2 colonnes à 1920, 3 à 2340).

## Carte touchée (place : [enum StorageRules.Place], index dans sa liste) ; informatif.
signal selected(place: int, index: int)
## DÉPOSER, ou une carte de l'ÉQUIPE glissée sur le STOCKAGE.
signal deposit_requested(index: int)
## REPRENDRE, ou une carte du STOCKAGE glissée sur l'ÉQUIPE.
signal withdraw_requested(index: int)
## FAVORI.
signal favorite_toggled(place: int, index: int)
## LIBÉRER du menu « ⋯ » (avant confirmation).
signal release_requested(place: int, index: int)
## Carte LIBÉRER de la confirmation.
signal release_confirmed(place: int, index: int)

const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const STAR_ON_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const STAR_OFF_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_outline.svg")
const DEPOSIT_ICON: Texture2D = preload("res://assets/ui/icons/storage/deposit.svg")
const WITHDRAW_ICON: Texture2D = preload("res://assets/ui/icons/storage/withdraw.svg")
const MORE_ICON: Texture2D = preload("res://assets/ui/icons/storage/more.svg")
const RELEASE_ICON: Texture2D = preload("res://assets/ui/icons/storage/release.svg")

var _view: StorageView
var _refusal_tween: Tween
var _shake_tween: Tween
var _shaking_card: StorageCard
var _drag_card: StorageCard
var _drop_place: StorageRules.Place = StorageRules.Place.STORAGE
var _hovering_drop: bool = false
var _pending_release: StorageSelection
var _menu_open: bool = false
var _cols: int = 1

var _party_cards: Array[StorageCard] = []
var _grid_cards: Array[StorageCard] = []
var _party_zone: Control
var _party_title: Label
var _party_holder: Control
var _grid_zone: PanelContainer
var _grid_title: Label
var _scroll: ScrollContainer
var _grid_holder: Control
var _empty: Label
var _back: Button
var _detail_holder: Control
var _detail_panel: PanelContainer
var _showcase: PokemonShowcase
var _primary: Button
var _favorite: Button
var _more: Button
var _refusal: PanelContainer
var _refusal_label: Label
var _drop_zone: Panel
var _ghost: TeamSlotCard
var _menu_layer: Control
var _menu_panel: PanelContainer
var _menu_box: VBoxContainer
var _release_button: Button
var _choice: ChoiceCards


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.STORAGE_COLUMN_GAP)
	add_child(body)
	_build_party(body)
	_build_detail(body)
	_build_grid(body)
	_build_overlays()


## Affiche [param view] (vue neuve après chaque action). Rappelé pendant que l'écran est
## affiché, il met à jour sans rejouer l'entrée : le défilement de la grille reste ; une carte
## qui change de place est suivie (rendue visible) par le défilement.
func show_storage(view: StorageView) -> void:
	var previous := _view.selection if _view != null else null
	_view = view
	_end_drag()
	_close_menu()
	_clear_refusal()
	_party_title.text = view.party_title
	_grid_title.text = view.storage_title
	_back.text = view.back_label
	_sync_party(view)
	_sync_grid(view)
	_empty.text = view.empty_text
	_empty.visible = not view.empty_text.is_empty()
	_refresh_detail(view, previous == null or not previous.equals(view.selection))
	_update_looks()
	_follow_selection.call_deferred()


## La carte ([param place], [param index]) tremble et vibre, la raison [param text] s'écrit sur
## la fiche (tremblement + raison, langage du 6B). Ne change rien d'autre.
func show_refusal(place: int, index: int, text: String) -> void:
	_clear_refusal()
	Haptics.vibrate(UiTokens.HAPTIC_REFUSE_MS)
	var card := get_card(place, index)
	if card != null:
		_shake(card)
	if text.is_empty():
		return
	_refusal_label.text = text
	_refusal.visible = true
	var time := UiTokens.STORAGE_REFUSAL_SECONDS * speed_scale
	if time > 0.0 and is_inside_tree():
		_refusal_tween = create_tween()
		_refusal_tween.tween_interval(time)
		_refusal_tween.tween_callback(_clear_refusal)


## La confirmation de LIBÉRER ([param view], [ChoiceCards]) pour le Pokémon de la carte
## ([param place], [param index]). LIBÉRER → [signal release_confirmed] ; ANNULER (ou
## [method go_back]) → rien.
func ask_release(view: ChoiceView, place: int, index: int) -> void:
	_close_menu()
	_pending_release = StorageSelection.new(place as StorageRules.Place, index)
	_choice.speed_scale = speed_scale
	_choice.show_choice(view)


## Retour (retour Android, Échap) : ferme d'abord la confirmation (= ANNULER), sinon le menu
## « ⋯ ». Vrai si c'est ce qui s'est passé (l'événement est consommé) ; faux : l'hôte quitte
## l'écran.
func go_back() -> bool:
	if _choice.is_showing():
		_choice.hide_choice()
		_pending_release = null
		return true
	if _menu_open:
		_close_menu()
		return true
	return false


## Carte de la liste [param place] à [param index] (null si elle n'existe pas).
func get_card(place: int, index: int) -> StorageCard:
	var cards := _party_cards if place == StorageRules.Place.PARTY else _grid_cards
	if index < 0 or index >= cards.size():
		return null
	var card := cards[index]
	return card if not card.is_empty() and card.visible else null


func get_party_cards() -> Array[StorageCard]:
	return _party_cards


## Cartes du stockage affichées (dans l'ordre d'arrivée).
func get_storage_cards() -> Array[StorageCard]:
	var shown: Array[StorageCard] = []
	for card: StorageCard in _grid_cards:
		if card.visible:
			shown.append(card)
	return shown


func get_back_button() -> Button:
	return _back


## DÉPOSER (Pokémon de l'équipe sélectionné) ou REPRENDRE (Pokémon du stockage).
func get_primary_button() -> Button:
	return _primary


func get_favorite_button() -> Button:
	return _favorite


func get_more_button() -> Button:
	return _more


## LIBÉRER : n'existe que tant que le menu « ⋯ » est ouvert (sinon null).
func get_release_button() -> Button:
	return _release_button if _menu_open else null


func is_menu_open() -> bool:
	return _menu_open


## Ouvre ou ferme le menu « ⋯ » (comme le bouton).
func toggle_menu() -> void:
	_on_more_pressed()


func get_choice() -> ChoiceCards:
	return _choice


func get_showcase() -> PokemonShowcase:
	return _showcase


func get_scroll() -> ScrollContainer:
	return _scroll


func get_party_zone() -> Control:
	return _party_zone


func get_grid_zone() -> Control:
	return _grid_zone


func get_ghost() -> TeamSlotCard:
	return _ghost


## Un glisser est en cours.
func is_dragging() -> bool:
	return _drag_card != null


## Le cadre de dépôt est montré (pendant un glisser).
func is_drop_zone_shown() -> bool:
	return _drop_zone.visible


## La liste visée par le glisser en cours.
func get_drop_place() -> int:
	return _drop_place


## Raison d'un refus affichée ("" si aucune).
func get_refusal_text() -> String:
	return _refusal_label.text if _refusal.visible else ""


## Une carte tremble encore.
func is_shaking() -> bool:
	return _shake_tween != null and _shake_tween.is_valid() and _shake_tween.is_running()


func get_shaking_card() -> StorageCard:
	return _shaking_card if is_shaking() else null


## Colonnes de la grille à la largeur actuelle.
func get_grid_columns() -> int:
	return _cols


## Libellés des actions affichées (primaire, favori), pour les tests.
func get_action_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for button: Button in [_primary, _favorite]:
		if button.visible:
			texts.append(button.text)
	return texts


func get_view() -> StorageView:
	return _view


func _build_party(parent: Control) -> void:
	_party_zone = VBoxContainer.new()
	_party_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_zone.custom_minimum_size.x = UiTokens.STORAGE_PARTY_WIDTH
	_party_zone.add_theme_constant_override(&"separation", UiTokens.STORAGE_PARTY_GAP)
	parent.add_child(_party_zone)
	_party_title = _title_label()
	_party_zone.add_child(_party_title)
	_party_holder = Control.new()
	_party_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_holder.custom_minimum_size = Vector2(UiTokens.STORAGE_PARTY_WIDTH, _party_height())
	_party_zone.add_child(_party_holder)
	for i: int in StorageView.PARTY_SLOTS:
		var card := _new_card(StorageRules.Place.PARTY)
		card.position = _party_home(i)
		card.size = Vector2(UiTokens.STORAGE_PARTY_WIDTH, UiTokens.TEAM_SLOT_HEIGHT)
		_party_holder.add_child(card)
		_party_cards.append(card)


func _build_detail(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.custom_minimum_size.x = UiTokens.STORAGE_DETAIL_WIDTH
	column.add_theme_constant_override(&"separation", UiTokens.STORAGE_DETAIL_GAP)
	parent.add_child(column)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = StorageViews.BACK_LABEL
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size.y = UiTokens.TOUCH_MIN
	_back.pressed.connect(_on_back_pressed)
	column.add_child(_back)
	_detail_holder = Control.new()
	_detail_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_detail_holder)
	_detail_panel = PanelContainer.new()
	_detail_panel.theme_type_variation = &"MenuPanel"
	_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_holder.add_child(_detail_panel)
	_showcase = PokemonShowcase.new(UiTokens.STORAGE_SPRITE_SCALE, false)
	_showcase.size_flags_horizontal = Control.SIZE_FILL
	_detail_panel.add_child(_showcase)
	_refusal = PanelContainer.new()
	_refusal.theme_type_variation = &"StorageRefusal"
	_refusal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refusal.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_refusal.offset_left = UiTokens.GAP / 2
	_refusal.offset_right = -UiTokens.GAP / 2
	_refusal.offset_top = UiTokens.GAP / 2
	_refusal.offset_bottom = UiTokens.GAP / 2
	_refusal.visible = false
	_detail_holder.add_child(_refusal)
	_refusal_label = Label.new()
	_refusal_label.theme_type_variation = &"StorageRefusalText"
	_refusal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refusal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refusal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refusal.add_child(_refusal_label)
	_primary = _action_button(DEPOSIT_ICON)
	_primary.pressed.connect(_on_primary_pressed)
	column.add_child(_primary)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.STORAGE_DETAIL_GAP)
	column.add_child(row)
	_favorite = _action_button(STAR_OFF_ICON)
	_favorite.pressed.connect(_on_favorite_pressed)
	row.add_child(_favorite)
	_more = _action_button(MORE_ICON)
	_more.text = ""
	_more.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_more.size_flags_horizontal = Control.SIZE_SHRINK_END
	_more.custom_minimum_size.x = UiTokens.STORAGE_MORE_WIDTH
	_more.pressed.connect(_on_more_pressed)
	row.add_child(_more)


func _build_grid(parent: Control) -> void:
	_grid_zone = PanelContainer.new()
	_grid_zone.theme_type_variation = &"MenuPanel"
	_grid_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_grid_zone)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.STORAGE_PARTY_GAP)
	_grid_zone.add_child(column)
	_grid_title = _title_label()
	column.add_child(_grid_title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_grid_holder = Control.new()
	_grid_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_holder.resized.connect(_layout_grid)
	_scroll.add_child(_grid_holder)
	_empty = Label.new()
	_empty.theme_type_variation = &"StorageEmpty"
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = false
	_scroll.add_child(_empty)


func _build_overlays() -> void:
	_drop_zone = Panel.new()
	_drop_zone.theme_type_variation = &"StorageDropZone"
	_drop_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_zone.visible = false
	add_child(_drop_zone)
	_menu_layer = Control.new()
	_menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.visible = false
	_menu_layer.gui_input.connect(_on_menu_layer_input)
	add_child(_menu_layer)
	_menu_panel = PanelContainer.new()
	_menu_panel.theme_type_variation = &"StorageMenu"
	_menu_layer.add_child(_menu_panel)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override(&"separation", UiTokens.STORAGE_DETAIL_GAP)
	_menu_panel.add_child(_menu_box)
	_choice = ChoiceCards.new()
	_choice.speed_scale = speed_scale
	_choice.chosen.connect(_on_release_chosen)
	add_child(_choice)


func _title_label() -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StorageTitle"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.y = UiTokens.STORAGE_TITLE_HEIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _action_button(icon: Texture2D) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"TeamAction"
	button.icon = icon
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = UiTokens.STORAGE_ACTION_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _new_card(place: StorageRules.Place) -> StorageCard:
	var card := StorageCard.new()
	card.place = place
	card.tapped.connect(_on_card_tapped.bind(card))
	card.drag_started.connect(_on_drag_started.bind(card))
	card.drag_moved.connect(_on_drag_moved.bind(card))
	card.drag_released.connect(_on_drag_released.bind(card))
	return card


func _party_height() -> float:
	var step := UiTokens.TEAM_SLOT_HEIGHT + UiTokens.STORAGE_PARTY_GAP
	return float(step * StorageView.PARTY_SLOTS - UiTokens.STORAGE_PARTY_GAP)


func _party_home(index: int) -> Vector2:
	return Vector2(0.0, index * (UiTokens.TEAM_SLOT_HEIGHT + UiTokens.STORAGE_PARTY_GAP))


func _grid_cell_width(width: float) -> float:
	return (width - (_cols - 1) * UiTokens.STORAGE_GRID_GAP) / float(_cols)


func _grid_home(index: int) -> Vector2:
	var width := _grid_holder.size.x
	var cell := _grid_cell_width(width)
	var col := index % _cols
	var row := index / _cols
	return Vector2(col * (cell + UiTokens.STORAGE_GRID_GAP),
		row * (UiTokens.TEAM_SLOT_HEIGHT + UiTokens.STORAGE_GRID_GAP))


func _home_of(card: StorageCard) -> Vector2:
	if card.place == StorageRules.Place.PARTY:
		return _party_home(_party_cards.find(card))
	return _grid_home(_grid_cards.find(card))


func _sync_party(view: StorageView) -> void:
	for i: int in _party_cards.size():
		var card := _party_cards[i]
		var card_view := view.party[i] if i < view.party.size() else null
		card.set_member(card_view.member if card_view != null else null)


func _sync_grid(view: StorageView) -> void:
	while _grid_cards.size() < view.storage.size():
		var card := _new_card(StorageRules.Place.STORAGE)
		card.size = Vector2(UiTokens.STORAGE_GRID_MIN_CELL, UiTokens.TEAM_SLOT_HEIGHT)
		_grid_holder.add_child(card)
		_grid_cards.append(card)
	for i: int in _grid_cards.size():
		var card := _grid_cards[i]
		var in_use := i < view.storage.size()
		card.visible = in_use
		card.set_member(view.storage[i].member if in_use else null)
	_layout_grid()


func _layout_grid() -> void:
	if _grid_holder == null:
		return
	var width := _grid_holder.size.x
	if width <= 0.0:
		return
	var gap := UiTokens.STORAGE_GRID_GAP
	_cols = maxi(1, floori((width + gap) / (UiTokens.STORAGE_GRID_MIN_CELL + gap)))
	var count := _view.storage.size() if _view != null else 0
	var rows := ceili(float(count) / float(_cols))
	var height := 0.0
	if rows > 0:
		height = rows * UiTokens.TEAM_SLOT_HEIGHT + (rows - 1) * gap
	_grid_holder.custom_minimum_size.y = height
	var cell := _grid_cell_width(width)
	for i: int in _grid_cards.size():
		var card := _grid_cards[i]
		if card == _shaking_card and is_shaking():
			continue
		card.position = _grid_home(i)
		card.size = Vector2(cell, UiTokens.TEAM_SLOT_HEIGHT)


func _refresh_detail(view: StorageView, changed: bool) -> void:
	var has_selection := view.sheet != null
	_detail_panel.visible = has_selection
	_primary.visible = not view.actions.is_empty()
	_favorite.visible = view.actions.size() > 1
	_more.visible = not view.more_actions.is_empty()
	if has_selection:
		_showcase.speed_scale = speed_scale
		_showcase.show_sheet(view.sheet, changed)
	for action: StorageActionView in view.actions:
		match action.id:
			StorageViews.ACTION_DEPOSIT, StorageViews.ACTION_WITHDRAW:
				_primary.text = action.label
				_primary.icon = DEPOSIT_ICON if action.id == StorageViews.ACTION_DEPOSIT \
					else WITHDRAW_ICON
				_primary.theme_type_variation = &"TeamActionOn"
			StorageViews.ACTION_FAVORITE:
				_favorite.text = action.label
				_favorite.icon = STAR_ON_ICON if action.active else STAR_OFF_ICON
				_favorite.theme_type_variation = &"TeamActionOn" if action.active \
					else &"TeamAction"


func _update_looks() -> void:
	for cards: Array[StorageCard] in [_party_cards, _grid_cards]:
		for card: StorageCard in cards:
			if card.is_empty():
				card.set_look(TeamSlotCard.Look.NORMAL)
			elif card == _drag_card:
				card.set_look(TeamSlotCard.Look.SOURCE)
			elif _is_selected(card):
				card.set_look(TeamSlotCard.Look.SELECTED)
			else:
				card.set_look(TeamSlotCard.Look.NORMAL)


func _is_selected(card: StorageCard) -> bool:
	return _view != null and not card.is_empty() and not _view.selection.is_empty() \
		and _view.selection.place == card.place and _view.selection.index == card.party_index


## Après une action, le Pokémon sélectionné reste visible dans la grille (sans bouger si c'est
## déjà le cas).
func _follow_selection() -> void:
	if _view == null or not is_inside_tree():
		return
	if _view.selection.place == StorageRules.Place.STORAGE:
		var card := get_card(StorageRules.Place.STORAGE, _view.selection.index)
		if card != null:
			_scroll.ensure_control_visible(card)


func _shake(card: StorageCard) -> void:
	_shaking_card = card
	var base := _home_of(card)
	var time := UiTokens.PICKER_SHAKE_TIME * speed_scale
	if time <= 0.0 or not is_inside_tree():
		_shake_tween = null
		return
	var steps := UiTokens.PICKER_SHAKE_STEPS
	var step_time := time / float(steps * 2 + 1)
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE)
	for i: int in steps:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var decay := 1.0 - float(i) / float(steps)
		_shake_tween.tween_property(card, ^"position:x",
			base.x + dir * UiTokens.PICKER_SHAKE_AMPLITUDE * decay, step_time)
		_shake_tween.tween_property(card, ^"position:x", base.x, step_time)
	_shake_tween.tween_callback(_stop_shake)


func _stop_shake() -> void:
	if _shaking_card != null and is_instance_valid(_shaking_card):
		_shaking_card.position = _home_of(_shaking_card)
	_shake_tween = null


func _clear_refusal() -> void:
	if _refusal_tween != null:
		_refusal_tween.kill()
		_refusal_tween = null
	if _shake_tween != null:
		_shake_tween.kill()
		_stop_shake()
	_refusal.visible = false


func _close_menu() -> void:
	_menu_open = false
	_release_button = null
	if _menu_layer != null:
		_menu_layer.visible = false
	if _more != null:
		_more.theme_type_variation = &"TeamAction"


func _open_menu() -> void:
	if _view == null or _view.more_actions.is_empty():
		return
	for old: Node in _menu_box.get_children():
		_menu_box.remove_child(old)
		old.queue_free()
	_release_button = null
	for action: StorageActionView in _view.more_actions:
		var item := Button.new()
		item.theme_type_variation = &"PanelButton"
		item.text = action.label
		item.icon = RELEASE_ICON
		item.focus_mode = Control.FOCUS_NONE
		item.custom_minimum_size = Vector2(UiTokens.STORAGE_MENU_WIDTH,
			UiTokens.STORAGE_MENU_ITEM_HEIGHT)
		item.pressed.connect(_on_menu_item_pressed.bind(action.id))
		_menu_box.add_child(item)
		if action.id == StorageViews.ACTION_RELEASE:
			_release_button = item
	_menu_open = true
	_menu_layer.visible = true
	_more.theme_type_variation = &"TeamActionOn"
	_menu_panel.reset_size()
	var panel_size := _menu_panel.get_combined_minimum_size()
	var anchor := _more.get_global_rect()
	var origin := anchor.position - global_position
	var x := minf(origin.x + anchor.size.x - panel_size.x, size.x - panel_size.x)
	var y := maxf(origin.y - panel_size.y - UiTokens.GAP / 2, 0.0)
	_menu_panel.position = Vector2(maxf(x, 0.0), y)
	_menu_panel.size = panel_size


func _end_drag() -> void:
	_drag_card = null
	_hovering_drop = false
	if _ghost != null:
		_ghost.visible = false
	if _drop_zone != null:
		_drop_zone.visible = false
	if is_node_ready() and _view != null:
		_update_looks()


func _zone_rect(place: StorageRules.Place) -> Rect2:
	var zone: Control = _party_zone if place == StorageRules.Place.PARTY else _grid_zone
	return zone.get_global_rect()


func _on_card_tapped(index: int, card: StorageCard) -> void:
	if _view == null or _drag_card != null:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_clear_refusal()
	_close_menu()
	if _is_selected(card):
		return
	selected.emit(int(card.place), index)


func _on_drag_started(_index: int, card: StorageCard) -> void:
	if _view == null or _drag_card != null:
		return
	_clear_refusal()
	_close_menu()
	_drag_card = card
	_drop_place = StorageRules.Place.STORAGE if card.place == StorageRules.Place.PARTY \
		else StorageRules.Place.PARTY
	_hovering_drop = false
	if _ghost == null:
		_ghost = TeamSlotCard.new()
		_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost.z_index = 10
		add_child(_ghost)
	_ghost.size = card.size
	_ghost.set_member(card.get_member())
	_ghost.set_look(TeamSlotCard.Look.SELECTED)
	_ghost.modulate.a = UiTokens.TEAM_DRAG_GHOST_ALPHA
	_ghost.visible = true
	_ghost.position = card.global_position - global_position
	var rect := _zone_rect(_drop_place)
	_drop_zone.position = rect.position - global_position
	_drop_zone.size = rect.size
	_drop_zone.modulate.a = 0.55
	_drop_zone.visible = true
	_update_looks()


func _on_drag_moved(_index: int, global_pos: Vector2, card: StorageCard) -> void:
	if _drag_card != card:
		return
	_ghost.position = global_pos - global_position - _ghost.size * 0.5
	var over := _zone_rect(_drop_place).has_point(global_pos)
	if over != _hovering_drop:
		_hovering_drop = over
		_drop_zone.modulate.a = 1.0 if over else 0.55


func _on_drag_released(index: int, global_pos: Vector2, card: StorageCard) -> void:
	if _drag_card != card:
		return
	var target := _drop_place
	var dropped := _zone_rect(target).has_point(global_pos)
	_end_drag()
	if not dropped:
		return
	Haptics.vibrate(UiTokens.HAPTIC_STORAGE_MOVE_MS)
	if card.place == StorageRules.Place.PARTY:
		deposit_requested.emit(index)
	else:
		withdraw_requested.emit(index)


func _on_back_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()


func _on_primary_pressed() -> void:
	if _view == null or _view.selection.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	_clear_refusal()
	_close_menu()
	if _view.selection.place == StorageRules.Place.PARTY:
		deposit_requested.emit(_view.selection.index)
	else:
		withdraw_requested.emit(_view.selection.index)


func _on_favorite_pressed() -> void:
	if _view == null or _view.selection.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	_clear_refusal()
	_close_menu()
	favorite_toggled.emit(int(_view.selection.place), _view.selection.index)


func _on_more_pressed() -> void:
	if _view == null or _view.selection.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	_clear_refusal()
	if _menu_open:
		_close_menu()
	else:
		_open_menu()


func _on_menu_item_pressed(action_id: StringName) -> void:
	if _view == null or _view.selection.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	var place := int(_view.selection.place)
	var index := _view.selection.index
	_close_menu()
	if action_id == StorageViews.ACTION_RELEASE:
		release_requested.emit(place, index)


func _on_menu_layer_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		_close_menu()


func _on_release_chosen(confirmed: bool) -> void:
	var pending := _pending_release
	_pending_release = null
	if confirmed and pending != null:
		release_confirmed.emit(int(pending.place), pending.index)
