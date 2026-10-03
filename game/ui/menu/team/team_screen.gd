class_name TeamScreen
extends MenuScreen
## Écran Équipe du Menu Dresseur (dossier 08 §2 ; jalon-06.md §6.5, §6.7) : la liste des six
## emplacements à gauche, le Pokémon sélectionné en grand au centre (la vedette), sa fiche à
## droite (Aperçu · Capacités · Histoire) et les actions UTILISER UN OBJET · DÉPLACER · FAVORI.
##
## Il reçoit un [TeamView] et n'en sait rien d'autre : ni un Pokémon, ni données, ni état. Il émet
## des intentions ; c'est le directeur du menu qui les applique et rappelle [method show_team].
## - Toucher un emplacement : la fiche change tout de suite (les fiches de tous les membres sont
##   dans la vue) et [signal member_selected] informe.
## - Réordonner : appui long sur A, glisser sur B, relâcher (un seul [signal member_moved]) **ou**
##   DÉPLACER (A est le Pokémon sélectionné) puis toucher B. Jamais vers un emplacement vide ni
##   vers soi-même. Les deux emplacements glissent l'un vers l'autre (TEAM_SWAP_TIME).
## - Emplacements vides : neutres, aucun texte, aucune action.
## - Une capacité touchée ouvre [MoveDetailSheet] ; un toucher ailleurs la referme.
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN.

## L'écran a changé de Pokémon sélectionné (informatif : il change de fiche seul).
signal member_selected(index: int)
## A est échangé avec B (glisser-déposer ou DÉPLACER).
signal member_moved(from: int, to: int)
## FAVORI touché sur le Pokémon [param index].
signal favorite_toggled(index: int)
## UTILISER UN OBJET touché sur le Pokémon [param index] (lien croisé vers le Sac, 6B).
signal use_item_requested(index: int)

const BACK_TEXT := "RETOUR"
const USE_TEXT := "UTILISER UN OBJET"
const MOVE_TEXT := "DÉPLACER"
const CANCEL_TEXT := "ANNULER"
const FAVORITE_ON_TEXT := "RETIRER FAVORI"
const FAVORITE_OFF_TEXT := "MARQUER FAVORI"
const COUNT_FORMAT := "Équipe  %d / %d"
const MOVE_HINT_FORMAT := "Choisis où placer %s"
const MOVE_ALONE_TEXT := "Il faut deux Pokémon pour en déplacer un."
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const BAG_ICON: Texture2D = preload("res://assets/ui/icons/battle/bag.svg")
const SWAP_ICON: Texture2D = preload("res://assets/ui/icons/menu/swap.svg")
const STAR_ON_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const STAR_OFF_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_outline.svg")
const MOVE_SHEET_SCENE: PackedScene = preload("res://game/ui/battle/move_detail_sheet.tscn")

var _view: TeamView
var _selected: int = 0
var _move_mode: bool = false
var _move_from: int = -1
var _drag_from: int = -1
var _drop_target: int = -1
var _swap_pending: Vector2i = Vector2i(-1, -1)
var _swap_tween: Tween
var _hint_alone: bool = false

var _slots: Array[TeamSlotCard] = []
var _list: Control
var _ghost: TeamSlotCard
var _back: Button
var _caption: Label
var _hint: PanelContainer
var _hint_label: Label
var _showcase: PokemonShowcase
var _sheet_panel: PanelContainer
var _sheet: PokemonSheet
var _use: Button
var _move: Button
var _favorite: Button
var _overlay: Control
var _move_sheet: MoveDetailSheet


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.TEAM_COLUMN_GAP)
	add_child(body)
	_build_list(body)
	_build_center(body)
	_build_sheet(body)
	_build_overlay()


## Affiche [param view] avec [param selected] sélectionné. Rappelé pendant que l'écran est
## affiché (après un échange ou un favori) : met à jour sans rejouer l'entrée, en gardant
## l'onglet ouvert ; les mouvements d'un échange demandé par le geste sont joués ici.
func show_team(view: TeamView, selected: int) -> void:
	var previous := _selected
	var had_view := _view != null
	_view = view
	_selected = TeamViews.clamp_selection(selected, view.size())
	_end_drag()
	_close_move_sheet_now()
	if _move_mode and (_move_from < 0 or _move_from >= view.size()):
		_set_move_mode(false)
	for i: int in TeamView.SLOT_COUNT:
		var slot := _slots[i]
		slot.slot = i
		slot.set_member(view.members[i] if i < view.size() else null)
	_refresh(had_view and previous != _selected)
	if _swap_pending.x >= 0:
		_play_swap(_swap_pending.x, _swap_pending.y)
		_swap_pending = Vector2i(-1, -1)


## Pokémon sélectionné (-1 : équipe vide).
func get_selected() -> int:
	return _selected if _view != null and _view.size() > 0 else -1


func is_move_mode() -> bool:
	return _move_mode


## Le Pokémon qui attend sa nouvelle place (mode DÉPLACER), sinon -1.
func get_move_source() -> int:
	return _move_from if _move_mode else -1


func is_swapping() -> bool:
	return _swap_tween != null and _swap_tween.is_running()


func get_slots() -> Array[TeamSlotCard]:
	return _slots


func get_slot(index: int) -> TeamSlotCard:
	return _slots[index]


func get_ghost() -> TeamSlotCard:
	return _ghost


func get_drop_target() -> int:
	return _drop_target


func get_showcase() -> PokemonShowcase:
	return _showcase


func get_sheet() -> PokemonSheet:
	return _sheet


func get_back_button() -> Button:
	return _back


func get_use_button() -> Button:
	return _use


func get_move_button() -> Button:
	return _move


func get_favorite_button() -> Button:
	return _favorite


func get_caption_text() -> String:
	return _caption.text


## Consigne du mode DÉPLACER (ou de l'équipe d'un seul Pokémon) ; "" si absente.
func get_hint_text() -> String:
	return _hint_label.text if _hint.visible else ""


func get_move_sheet() -> MoveDetailSheet:
	return _move_sheet


func is_move_sheet_open() -> bool:
	return _overlay.visible


func get_overlay() -> Control:
	return _overlay


## Ferme la fiche d'une capacité.
func close_move_sheet() -> void:
	if not _overlay.visible:
		return
	_overlay.visible = false
	_move_sheet.close()


func _build_list(parent: Control) -> void:
	_list = Control.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var step := UiTokens.TEAM_SLOT_HEIGHT + UiTokens.TEAM_SLOT_GAP
	_list.custom_minimum_size = Vector2(UiTokens.TEAM_LIST_WIDTH,
		step * TeamView.SLOT_COUNT - UiTokens.TEAM_SLOT_GAP)
	parent.add_child(_list)
	for i: int in TeamView.SLOT_COUNT:
		var slot := TeamSlotCard.new()
		slot.slot = i
		slot.position = _home(i)
		slot.size = Vector2(UiTokens.TEAM_LIST_WIDTH, UiTokens.TEAM_SLOT_HEIGHT)
		slot.tapped.connect(_on_slot_tapped)
		slot.drag_started.connect(_on_drag_started)
		slot.drag_moved.connect(_on_drag_moved)
		slot.drag_released.connect(_on_drag_released)
		_list.add_child(slot)
		_slots.append(slot)


func _build_center(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", UiTokens.TEAM_HEADER_GAP)
	parent.add_child(column)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.MENU_CARD_ICON * 2, UiTokens.TOUCH_MIN)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.pressed.connect(_on_back)
	column.add_child(_back)
	var info := Control.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.custom_minimum_size.y = UiTokens.MENU_OBJECTIVE_HEIGHT
	column.add_child(info)
	_caption = Label.new()
	_caption.theme_type_variation = &"TeamCaption"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_caption)
	_hint = PanelContainer.new()
	_hint.theme_type_variation = &"TeamPillAccent"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint.visible = false
	info.add_child(_hint)
	_hint_label = Label.new()
	_hint_label.theme_type_variation = &"TeamPillAccentText"
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.clip_text = true
	_hint.add_child(_hint_label)
	_showcase = PokemonShowcase.new()
	_showcase.size_flags_horizontal = Control.SIZE_FILL
	column.add_child(_showcase)


func _build_sheet(parent: Control) -> void:
	_sheet_panel = PanelContainer.new()
	_sheet_panel.theme_type_variation = &"MenuPanel"
	_sheet_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_panel.custom_minimum_size.x = UiTokens.TEAM_SHEET_WIDTH
	parent.add_child(_sheet_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TEAM_PAGE_GAP)
	_sheet_panel.add_child(column)
	_sheet = PokemonSheet.new()
	_sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sheet.move_tapped.connect(_on_move_tapped)
	_sheet.tab_changed.connect(_on_tab_changed)
	column.add_child(_sheet)
	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	column.add_child(actions)
	_use = _action(USE_TEXT, BAG_ICON)
	_use.pressed.connect(_on_use_pressed)
	actions.add_child(_use)
	_move = _action(MOVE_TEXT, SWAP_ICON)
	_move.pressed.connect(_on_move_pressed)
	actions.add_child(_move)
	_favorite = _action(FAVORITE_OFF_TEXT, STAR_OFF_ICON)
	_favorite.pressed.connect(_on_favorite_pressed)
	actions.add_child(_favorite)


func _action(text: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"TeamAction"
	button.text = text
	button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = UiTokens.TEAM_ACTION_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_overlay.gui_input.connect(_on_overlay_input)
	add_child(_overlay)
	var scrim := ColorRect.new()
	scrim.color = UiTokens.TEAM_SCRIM
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(scrim)
	_move_sheet = MOVE_SHEET_SCENE.instantiate() as MoveDetailSheet
	_move_sheet.speed_scale = speed_scale
	_overlay.add_child(_move_sheet)


## Remet la vue à jour (fiche, vedette, actions, aspect des emplacements).
func _refresh(switched: bool) -> void:
	var count := _view.size()
	_caption.text = COUNT_FORMAT % [count, TeamView.SLOT_COUNT]
	var has_member := count > 0
	_showcase.visible = has_member
	_sheet_panel.visible = has_member
	if has_member:
		var sheet_view := _view.sheet_at(_selected)
		_showcase.speed_scale = speed_scale
		_showcase.show_sheet(sheet_view, switched)
		_sheet.show_sheet(sheet_view)
		_update_favorite_button(sheet_view.member.favorite)
	_update_move_ui()
	_update_looks()


func _update_favorite_button(favorite: bool) -> void:
	_favorite.theme_type_variation = &"TeamActionOn" if favorite else &"TeamAction"
	_favorite.icon = STAR_ON_ICON if favorite else STAR_OFF_ICON
	_favorite.text = FAVORITE_ON_TEXT if favorite else FAVORITE_OFF_TEXT


func _update_move_ui() -> void:
	_move.text = CANCEL_TEXT if _move_mode else MOVE_TEXT
	_move.theme_type_variation = &"TeamActionOn" if _move_mode else &"TeamAction"
	var text := ""
	if _move_mode and _view != null and _view.sheet_at(_move_from) != null:
		text = MOVE_HINT_FORMAT % _view.sheet_at(_move_from).member.display_name
	elif _hint_alone:
		text = MOVE_ALONE_TEXT
	_hint_label.text = text
	_hint.visible = not text.is_empty()
	_caption.visible = text.is_empty()


func _update_looks() -> void:
	for i: int in _slots.size():
		var slot := _slots[i]
		if slot.is_empty():
			slot.set_look(TeamSlotCard.Look.NORMAL)
		elif _move_mode and i == _move_from:
			slot.set_look(TeamSlotCard.Look.SOURCE)
		elif _drag_from >= 0 and i == _drag_from:
			slot.set_look(TeamSlotCard.Look.SOURCE)
		elif _drag_from >= 0 and i == _drop_target:
			slot.set_look(TeamSlotCard.Look.TARGET)
		elif i == _selected:
			slot.set_look(TeamSlotCard.Look.SELECTED)
		else:
			slot.set_look(TeamSlotCard.Look.NORMAL)


func _select(index: int) -> void:
	if _view == null or index < 0 or index >= _view.size() or index == _selected:
		return
	_selected = index
	_close_move_sheet_now()
	_refresh(true)
	member_selected.emit(index)


func _set_move_mode(on: bool) -> void:
	_move_mode = on
	_move_from = _selected if on else -1
	_hint_alone = false


## Demande l'échange de [param from] et [param to] (jamais vers soi, jamais vers un
## emplacement vide) ; les mouvements sont joués quand la vue revient.
func _request_move(from: int, to: int) -> void:
	if _view == null or from == to or from < 0 or to < 0 \
			or from >= _view.size() or to >= _view.size():
		return
	_set_move_mode(false)
	Input.vibrate_handheld(UiTokens.HAPTIC_TEAM_SWAP_MS)
	_selected = TeamViews.selection_after_swap(_selected, from, to)
	_swap_pending = Vector2i(from, to)
	member_moved.emit(from, to)
	_swap_pending = Vector2i(-1, -1)
	_update_move_ui()
	_update_looks()


## Les deux emplacements glissent l'un vers l'autre : chacun est déjà rempli de son nouveau
## contenu et part de la place de l'autre.
func _play_swap(a: int, b: int) -> void:
	if _swap_tween != null:
		_swap_tween.kill()
		_swap_tween = null
	for i: int in _slots.size():
		_slots[i].position = _home(i)
		_slots[i].z_index = 0
	var time := UiTokens.TEAM_SWAP_TIME * speed_scale
	if time <= 0.0:
		return
	_slots[a].position = _home(b)
	_slots[b].position = _home(a)
	_slots[a].z_index = 1
	_slots[b].z_index = 1
	_swap_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	_swap_tween.tween_property(_slots[a], ^"position", _home(a), time)
	_swap_tween.tween_property(_slots[b], ^"position", _home(b), time)
	_swap_tween.chain().tween_callback(_on_swap_done.bind(a, b))


func _on_swap_done(a: int, b: int) -> void:
	_slots[a].z_index = 0
	_slots[b].z_index = 0
	_swap_tween = null


func _home(index: int) -> Vector2:
	return Vector2(0.0, index * (UiTokens.TEAM_SLOT_HEIGHT + UiTokens.TEAM_SLOT_GAP))


func _on_slot_tapped(index: int) -> void:
	if _move_mode:
		if index == _move_from:
			_set_move_mode(false)
			_update_move_ui()
			_update_looks()
		else:
			_request_move(_move_from, index)
		return
	Input.vibrate_handheld(UiTokens.HAPTIC_TICK_MS)
	_hint_alone = false
	_select(index)
	_update_move_ui()


func _on_drag_started(index: int) -> void:
	if _move_mode:
		_set_move_mode(false)
	_drag_from = index
	_drop_target = -1
	_hint_alone = false
	if _ghost == null:
		_ghost = TeamSlotCard.new()
		_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost.z_index = 10
		add_child(_ghost)
	_ghost.size = _slots[index].size
	_ghost.set_member(_slots[index].get_member())
	_ghost.set_look(TeamSlotCard.Look.SELECTED)
	_ghost.modulate.a = UiTokens.TEAM_DRAG_GHOST_ALPHA
	_ghost.visible = true
	_ghost.position = _slots[index].global_position - global_position
	_slots[index].set_look(TeamSlotCard.Look.SOURCE)
	_update_move_ui()


func _on_drag_moved(index: int, global_pos: Vector2) -> void:
	if _drag_from != index:
		return
	_ghost.position = global_pos - global_position - _ghost.size * 0.5
	var target := _slot_at(global_pos)
	if target == index or target < 0 or _slots[target].is_empty():
		target = -1
	if target != _drop_target:
		_drop_target = target
		_update_looks()


func _on_drag_released(index: int, global_pos: Vector2) -> void:
	if _drag_from != index:
		return
	var target := _slot_at(global_pos)
	var from := _drag_from
	_end_drag()
	if target >= 0 and target != from and not _slots[target].is_empty():
		_request_move(from, target)


func _end_drag() -> void:
	_drag_from = -1
	_drop_target = -1
	if _ghost != null:
		_ghost.visible = false
	if is_node_ready() and not _slots.is_empty():
		_update_looks()


## Emplacement sous [param global_pos] (position globale dans le calque), -1 s'il n'y en a pas.
func _slot_at(global_pos: Vector2) -> int:
	for i: int in _slots.size():
		var origin := _list.global_position + _home(i)
		if Rect2(origin, _slots[i].size).has_point(global_pos):
			return i
	return -1


func _on_back() -> void:
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	back_requested.emit()


func _on_use_pressed() -> void:
	if _view == null or _view.size() == 0:
		return
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	use_item_requested.emit(_selected)


func _on_move_pressed() -> void:
	if _view == null or _view.size() == 0:
		return
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	if _move_mode:
		_set_move_mode(false)
	elif _view.size() < 2:
		_hint_alone = true
	else:
		_set_move_mode(true)
	_update_move_ui()
	_update_looks()


func _on_favorite_pressed() -> void:
	if _view == null or _view.size() == 0:
		return
	Input.vibrate_handheld(UiTokens.HAPTIC_TAP_MS)
	favorite_toggled.emit(_selected)


func _on_tab_changed(_tab: int) -> void:
	close_move_sheet()


func _on_move_tapped(index: int) -> void:
	if _view == null:
		return
	var sheet_view := _view.sheet_at(_selected)
	if sheet_view == null or index < 0 or index >= sheet_view.moves.size():
		return
	_move_sheet.speed_scale = speed_scale
	_overlay.visible = true
	_move_sheet.open(sheet_view.moves[index])
	_move_sheet.size = Vector2(UiTokens.MOVE_DETAIL_WIDTH, 0.0)
	await get_tree().process_frame
	_fit_move_sheet()


## Largeur fixe, hauteur du texte (une fois le texte mis en page), centrée.
func _fit_move_sheet() -> void:
	var height := _move_sheet.get_body().get_combined_minimum_size().y
	_move_sheet.size = Vector2(UiTokens.MOVE_DETAIL_WIDTH, height)
	_move_sheet.position = ((_overlay.size - _move_sheet.size) * 0.5).floor()


func _on_overlay_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		close_move_sheet()


func _close_move_sheet_now() -> void:
	if _overlay != null and _overlay.visible:
		_overlay.visible = false
		_move_sheet.close()
