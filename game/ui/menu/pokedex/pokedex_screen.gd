class_name PokedexScreen
extends MenuScreen
## Écran Pokédex du Menu Dresseur (dossier 08 §4 ; jalon-06.md §6.9 ; maquette
## menu-pokedex-v1.jpg pour la DA seulement, règle 10) : en-tête « POKÉDEX — KANTO » avec le
## compteur et les filtres, la grille numérotée des 151 cases, la fiche de l'espèce touchée.
##
## Il reçoit un [PokedexGridView] et un [PokedexSheetView] et n'en sait rien d'autre : ni
## Pokédex, ni données, ni règles. Il émet des intentions ; le directeur du menu les applique
## et rappelle [method show_grid] / [method show_sheet].
## - Filtres TOUS · VUS · CAPTURÉS · HABITATS ; recherche (à la saisie) ; bouton Type et, pour
##   HABITATS, bouton Zone : chacun les fait défiler. **Un seul** [signal filter_changed] par
##   geste. L'écran ne change rien tout seul : il attend la vue qui revient.
## - Une case connue touchée : **un** [signal species_opened] ; une case inconnue : rien (ni
##   image, ni toucher).
## - Fiche ouverte : la grille se resserre à gauche, la fiche prend la droite. RETOUR (ou
##   [method close_sheet], retour Android) referme d'abord la fiche, puis quitte l'écran.
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN.

## Filtre, zone d'HABITATS, type ou recherche changé (valeurs complètes après le geste).
signal filter_changed(filter: int, zone: StringName, type: StringName, text: String)
## Case connue touchée.
signal species_opened(species: StringName)

const BACK_TEXT := "RETOUR"
const SEARCH_PLACEHOLDER := "Rechercher"
const TYPE_FORMAT := "Type : %s"
const ZONE_FORMAT := "%s"
const ALL_TYPES_TEXT := "Tous"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const SEARCH_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/search.svg")
const SWAP_ICON: Texture2D = preload("res://assets/ui/icons/menu/swap.svg")
const PIN_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/pin.svg")

var _view: PokedexGridView
var _filter: int = 0
var _zone: StringName = &""
var _type: StringName = &""
var _text: String = ""
var _opened: StringName = &""
var _slots: Array[PokedexSlot] = []
var _filters: Array[Button] = []
var _sheet_tween: Tween

var _back: Button
var _title: Label
var _counts: Label
var _list_panel: PanelContainer
var _search: LineEdit
var _type_button: Button
var _zone_button: Button
var _scroll: ScrollContainer
var _flow: HFlowContainer
var _empty: Label
var _sheet_panel: PanelContainer
var _sheet: PokedexSheet


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	add_child(column)
	_build_header(column)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	column.add_child(body)
	_build_list(body)
	_build_sheet(body)
	_apply_layout()


## Affiche [param view]. Rappelé pendant que l'écran est affiché (filtre, recherche, nouvelle
## observation), il met à jour **sans rejouer l'entrée** ; la fiche ouverte reste ouverte et le
## défilement est gardé tant que le filtre, la zone, le type et la recherche ne changent pas.
func show_grid(view: PokedexGridView) -> void:
	if not (visible and _view != null):
		close_sheet()  # nouvelle arrivée : jamais la fiche d'une visite précédente
	var changed := _view == null or view.filter != _filter or view.zone != _zone \
		or view.type != _type or view.text != _text
	var scroll := _scroll.scroll_vertical
	_view = view
	_filter = view.filter
	_zone = view.zone
	_type = view.type
	_text = view.text
	_title.text = view.title
	_counts.text = view.counts_text
	_counts.visible = not view.counts_text.is_empty()
	for i: int in _filters.size():
		_filters[i].visible = i < view.filter_labels.size()
		if i < view.filter_labels.size():
			_filters[i].text = view.filter_labels[i].to_upper()
		_filters[i].set_pressed_no_signal(i == view.filter)
	if _search.text != view.text:
		_search.text = view.text
	_refresh_refine(view)
	_fill_cells(view)
	_empty.text = view.empty_text
	var empty := view.is_empty()
	_empty.visible = empty
	_scroll.visible = not empty
	_scroll.scroll_vertical = scroll if not changed else 0
	_select_cell(_opened)


## Affiche la fiche de [param view] à droite (la grille se resserre). Rappelé pendant que la
## fiche est ouverte, il la met à jour sans rejouer l'animation ; l'onglet ouvert reste ouvert.
func show_sheet(view: PokedexSheetView) -> void:
	var was_open := _sheet_panel.visible
	_opened = view.species_id
	_sheet.show_sheet(view)
	_select_cell(_opened)
	_sheet_panel.visible = true
	_apply_layout()
	if not was_open:
		_play_sheet_entry()


## Referme la fiche (retour Android, RETOUR). Vrai si elle était ouverte (l'événement est
## consommé) ; faux : l'hôte revient à l'écran précédent.
func close_sheet() -> bool:
	if not is_sheet_open():
		return false
	_kill_sheet_tween()
	_sheet_panel.visible = false
	_opened = &""
	_select_cell(&"")
	_apply_layout()
	return true


func is_sheet_open() -> bool:
	return _sheet_panel != null and _sheet_panel.visible


## Espèce dont la fiche est ouverte (&"" si aucune).
func get_opened_species() -> StringName:
	return _opened


func get_back_button() -> Button:
	return _back


func get_title_label() -> Label:
	return _title


func get_counts_label() -> Label:
	return _counts


func get_filter_buttons() -> Array[Button]:
	return _filters


func get_search() -> LineEdit:
	return _search


func get_type_button() -> Button:
	return _type_button


func get_zone_button() -> Button:
	return _zone_button


func get_scroll() -> ScrollContainer:
	return _scroll


func get_empty_label() -> Label:
	return _empty


func get_list_panel() -> PanelContainer:
	return _list_panel


func get_sheet_panel() -> PanelContainer:
	return _sheet_panel


func get_sheet() -> PokedexSheet:
	return _sheet


## Cases affichées (celles de la vue courante), dans l'ordre.
func get_slots() -> Array[PokedexSlot]:
	var shown: Array[PokedexSlot] = []
	for slot: PokedexSlot in _slots:
		if slot.visible:
			shown.append(slot)
	return shown


## Case de [param species] ou du numéro [param number] (null si absente de la grille).
func get_slot(number: int) -> PokedexSlot:
	for slot: PokedexSlot in get_slots():
		if slot.get_view().number == number:
			return slot
	return null


## Nombre de cases créées depuis le début (jamais plus de 151 : le pool se réutilise).
func get_pool_size() -> int:
	return _slots.size()


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.DEX_HEADER_HEIGHT
	row.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.DEX_BACK_WIDTH, UiTokens.TOUCH_MIN)
	_back.pressed.connect(_on_back)
	row.add_child(_back)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.add_theme_constant_override(&"separation", 0)
	row.add_child(titles)
	_title = Label.new()
	_title.theme_type_variation = &"DexTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(_title)
	_counts = Label.new()
	_counts.theme_type_variation = &"MenuSubtitle"
	_counts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_counts)
	var group := ButtonGroup.new()
	for i: int in 4:
		var button := Button.new()
		button.theme_type_variation = &"DexTab"
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(UiTokens.DEX_FILTER_MIN_WIDTH, UiTokens.TOUCH_MIN)
		button.add_theme_font_size_override(&"font_size", UiTokens.DEX_FILTER_FONT)
		button.pressed.connect(_on_filter_pressed.bind(i))
		row.add_child(button)
		_filters.append(button)


func _build_list(parent: Control) -> void:
	_list_panel = PanelContainer.new()
	_list_panel.theme_type_variation = &"DexPanel"
	parent.add_child(_list_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.DEX_SECTION_GAP)
	_list_panel.add_child(column)
	var refine := HBoxContainer.new()
	refine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refine.add_theme_constant_override(&"separation", UiTokens.DEX_SECTION_GAP)
	column.add_child(refine)
	_search = LineEdit.new()
	_search.theme_type_variation = &"DexSearch"
	_search.placeholder_text = SEARCH_PLACEHOLDER
	_search.right_icon = SEARCH_ICON
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(UiTokens.DEX_SEARCH_MIN_WIDTH, UiTokens.TOUCH_MIN)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.add_theme_constant_override(&"icon_max_width", UiTokens.DEX_SEARCH_ICON)
	_search.text_changed.connect(_on_search_changed)
	_search.text_submitted.connect(_on_search_submitted)
	refine.add_child(_search)
	_type_button = _refine_button(SWAP_ICON)
	_type_button.pressed.connect(_on_type_pressed)
	refine.add_child(_type_button)
	_zone_button = _refine_button(PIN_ICON)
	_zone_button.pressed.connect(_on_zone_pressed)
	refine.add_child(_zone_button)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		pad.add_theme_constant_override(side, UiTokens.DEX_SCROLL_PAD)
	_scroll.add_child(pad)
	_flow = HFlowContainer.new()
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override(&"h_separation", UiTokens.DEX_CELL_GAP)
	_flow.add_theme_constant_override(&"v_separation", UiTokens.DEX_CELL_GAP)
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


func _refine_button(icon: Texture2D) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"TeamAction"
	button.icon = icon
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(UiTokens.DEX_REFINE_WIDTH, UiTokens.TOUCH_MIN)
	button.clip_text = true
	button.visible = false
	return button


func _build_sheet(parent: Control) -> void:
	_sheet_panel = PanelContainer.new()
	_sheet_panel.theme_type_variation = &"DexPanel"
	_sheet_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_panel.custom_minimum_size.x = UiTokens.DEX_SHEET_MIN_WIDTH
	_sheet_panel.visible = false
	parent.add_child(_sheet_panel)
	_sheet = PokedexSheet.new()
	_sheet.route_requested.connect(route_requested.emit)
	_sheet_panel.add_child(_sheet)


## Grille serrée à gauche quand la fiche est ouverte, sur toute la largeur sinon.
func _apply_layout() -> void:
	if is_sheet_open():
		_list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_list_panel.custom_minimum_size.x = UiTokens.DEX_LIST_WIDTH
	else:
		_list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list_panel.custom_minimum_size.x = 0.0


func _refresh_refine(view: PokedexGridView) -> void:
	var types_shown := not view.type_ids.is_empty()
	_type_button.visible = types_shown
	if types_shown:
		var type_name := ALL_TYPES_TEXT
		var rank := view.type_ids.find(view.type)
		if rank >= 0 and rank < view.type_names.size():
			type_name = view.type_names[rank]
		_type_button.text = TYPE_FORMAT % type_name
	var zones_shown := view.filter == MenuRoute.DEX_FILTER_HABITAT and not view.zone_ids.is_empty()
	_zone_button.visible = zones_shown
	if zones_shown:
		var rank := view.zone_ids.find(view.zone)
		rank = maxi(rank, 0)
		_zone_button.text = ZONE_FORMAT % (view.zone_names[rank] if rank < view.zone_names.size()
			else "")


## Une case par entrée de la vue, créées une fois (pool) puis réutilisées : un filtre ne crée
## ni ne détruit rien, il met à jour et cache le surplus.
func _fill_cells(view: PokedexGridView) -> void:
	while _slots.size() < view.slots.size():
		var slot := PokedexSlot.new()
		slot.visible = false
		_flow.add_child(slot)
		slot.tapped.connect(_on_slot_tapped.bind(slot))
		_slots.append(slot)
	for i: int in _slots.size():
		_slots[i].set_view(view.slots[i] if i < view.slots.size() else null)


func _select_cell(species: StringName) -> void:
	for slot: PokedexSlot in _slots:
		var slot_view := slot.get_view()
		var wanted := slot.visible and slot_view != null and not species.is_empty() \
			and slot_view.species_id == species
		if slot.is_selected() != wanted:
			slot.set_selected(wanted)


func _play_sheet_entry() -> void:
	_kill_sheet_tween()
	_sheet_panel.modulate.a = 1.0
	var time := UiTokens.DEX_SHEET_FADE * speed_scale
	if time <= 0.0 or not is_inside_tree():
		return
	_sheet_panel.modulate.a = 0.0
	_sheet_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sheet_tween.tween_property(_sheet_panel, ^"modulate:a", 1.0, time)


func _kill_sheet_tween() -> void:
	if _sheet_tween != null:
		_sheet_tween.kill()
		_sheet_tween = null
	_sheet_panel.modulate.a = 1.0


func _emit_filter(filter: int, zone: StringName, type: StringName, text: String) -> void:
	filter_changed.emit(filter, zone, type, text)


func _on_filter_pressed(filter: int) -> void:
	if filter == _filter:
		_filters[filter].set_pressed_no_signal(true)
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_emit_filter(filter, _zone, _type, _text)


func _on_search_changed(text: String) -> void:
	_emit_filter(_filter, _zone, _type, text)


func _on_search_submitted(_text: String) -> void:
	_search.release_focus()


func _on_type_pressed() -> void:
	if _view == null or _view.type_ids.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	var choices: Array[StringName] = [&""]
	choices.append_array(_view.type_ids)
	var next := choices[(choices.find(_type) + 1) % choices.size()]
	_emit_filter(_filter, _zone, next, _text)


func _on_zone_pressed() -> void:
	if _view == null or _view.zone_ids.is_empty():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	var rank := maxi(_view.zone_ids.find(_zone), 0)
	_emit_filter(_filter, _view.zone_ids[(rank + 1) % _view.zone_ids.size()], _type, _text)


func _on_slot_tapped(slot: PokedexSlot) -> void:
	var slot_view := slot.get_view()
	if slot_view == null or slot_view.is_unknown():
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	species_opened.emit(slot_view.species_id)


func _on_back() -> void:
	if close_sheet():
		return
	back_requested.emit()
