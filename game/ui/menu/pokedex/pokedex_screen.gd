class_name PokedexScreen
extends MenuScreen
## Écran Pokédex du Menu Dresseur (dossier 08 §4 ; maquette menu-pokedex-v1.jpg pour la DA et
## la composition seulement, règle 10) : **trois colonnes permanentes** sous une rangée d'en-tête
## qui occupe aussi la rangée du × : la grille numérotée des 151 cases (à gauche), le grand
## portrait de l'espèce choisie ([PokedexPortrait], au centre) et la fiche à onglets
## ([PokedexSheet], à droite).
##
## Il reçoit un [PokedexGridView] et un [PokedexSheetView] et n'en sait rien d'autre : ni
## Pokédex, ni données, ni règles. Il émet des intentions ; le directeur du menu les applique
## et rappelle [method show_grid] / [method show_sheet].
## - En-tête : ‹ RETOUR, Poké Ball + titre + compteur, filtres TOUS · VUS · CAPTURÉS · HABITATS
##   (pastilles), recherche. Au-dessus de la grille : bouton Type et, pour HABITATS, bouton Zone.
##   **Un seul** [signal filter_changed] par geste ; l'écran attend la vue qui revient.
## - Une case connue touchée : **un** [signal species_opened] ; une case inconnue : rien.
## - RETOUR (et le retour Android) quittent le Pokédex : la fiche est toujours visible, il n'y a
##   plus rien à refermer ([method close_sheet] renvoie toujours faux).
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête ; l'écran remonte de la
## hauteur de l'en-tête commun (covers_header) et laisse sa place au × à gauche.

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
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
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

var _back: Button
var _title: Label
var _counts: Label
var _header: HBoxContainer
var _list_panel: PanelContainer
var _search: LineEdit
var _type_button: Button
var _zone_button: Button
var _scroll: ScrollContainer
var _flow: HFlowContainer
var _empty: Label
var _portrait: PokedexPortrait
var _sheet_panel: PanelContainer
var _sheet: PokedexSheet
var _sheet_empty: Label


func _init() -> void:
	covers_header = true


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = -UiTokens.DEX_LAYOUT_RISE
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
	_portrait = PokedexPortrait.new()
	body.add_child(_portrait)
	_build_sheet(body)
	_show_empty_species(true, "")


## Affiche [param view]. Rappelé pendant que l'écran est affiché (filtre, recherche, nouvelle
## observation), il met à jour **sans rejouer l'entrée** ; l'espèce affichée reste la même et
## le défilement est gardé tant que le filtre, la zone, le type et la recherche ne changent pas.
func show_grid(view: PokedexGridView) -> void:
	if not (visible and _view != null):
		_opened = &""  # nouvelle arrivée : jamais l'espèce d'une visite précédente
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
			_filters[i].text = view.filter_labels[i]
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
	if _opened.is_empty():
		_show_empty_species(true, view.no_species_text)


## Affiche l'espèce de [param view] au centre et à droite. Rappelé pendant qu'elle est
## affichée, il met à jour sans rejouer le fondu du portrait si l'espèce est la même ;
## l'onglet ouvert reste ouvert.
func show_sheet(view: PokedexSheetView) -> void:
	_opened = view.species_id
	_portrait.speed_scale = speed_scale
	_show_empty_species(false, "")
	_portrait.show_species(view)
	_sheet.show_sheet(view)
	_select_cell(_opened)


## RETOUR et retour Android quittent le Pokédex : la fiche est toujours visible, il n'y a rien à
## refermer. Toujours faux (l'événement n'est jamais consommé ici).
func close_sheet() -> bool:
	return false


## Vrai si une espèce est affichée au centre et à droite.
func is_sheet_open() -> bool:
	return not _opened.is_empty()


## Espèce affichée (&"" si aucune).
func get_opened_species() -> StringName:
	return _opened


func get_back_button() -> Button:
	return _back


func get_header() -> HBoxContainer:
	return _header


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


func get_portrait() -> PokedexPortrait:
	return _portrait


func get_sheet_panel() -> PanelContainer:
	return _sheet_panel


func get_sheet() -> PokedexSheet:
	return _sheet


func get_sheet_empty_label() -> Label:
	return _sheet_empty


## Cases affichées (celles de la vue courante), dans l'ordre.
func get_slots() -> Array[PokedexSlot]:
	var shown: Array[PokedexSlot] = []
	for slot: PokedexSlot in _slots:
		if slot.visible:
			shown.append(slot)
	return shown


## Case du numéro [param number] (null si absente de la grille).
func get_slot(number: int) -> PokedexSlot:
	for slot: PokedexSlot in get_slots():
		if slot.get_view().number == number:
			return slot
	return null


## Nombre de cases créées depuis le début (jamais plus de 151 : le pool se réutilise).
func get_pool_size() -> int:
	return _slots.size()


func _build_header(parent: Control) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", UiTokens.DEX_LAYOUT_CLOSE_RESERVE)
	parent.add_child(margin)
	_header = HBoxContainer.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.custom_minimum_size.y = UiTokens.DEX_HEADER_HEIGHT
	_header.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	margin.add_child(_header)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.DEX_LAYOUT_BACK_WIDTH, UiTokens.TOUCH_MIN)
	_back.pressed.connect(_on_back)
	_header.add_child(_back)
	var ball := TextureRect.new()
	ball.texture = BALL_ICON
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.custom_minimum_size = Vector2.ONE * UiTokens.DEX_LAYOUT_TITLE_ICON
	ball.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(ball)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.add_theme_constant_override(&"separation", 0)
	_header.add_child(titles)
	_title = Label.new()
	_title.theme_type_variation = &"DexHeaderTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_title)
	_counts = Label.new()
	_counts.theme_type_variation = &"DexHeaderCounts"
	_counts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_counts)
	var group := ButtonGroup.new()
	for i: int in 4:
		var button := Button.new()
		button.theme_type_variation = &"DexFilterPill"
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(UiTokens.DEX_LAYOUT_FILTER_MIN_WIDTH,
			UiTokens.TOUCH_MIN)
		button.pressed.connect(_on_filter_pressed.bind(i))
		_header.add_child(button)
		_filters.append(button)
	_search = LineEdit.new()
	_search.theme_type_variation = &"DexSearch"
	_search.placeholder_text = SEARCH_PLACEHOLDER
	_search.right_icon = SEARCH_ICON
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(UiTokens.DEX_LAYOUT_SEARCH_MIN_WIDTH,
		UiTokens.TOUCH_MIN)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.add_theme_constant_override(&"icon_max_width", UiTokens.DEX_SEARCH_ICON)
	_search.text_changed.connect(_on_search_changed)
	_search.text_submitted.connect(_on_search_submitted)
	_header.add_child(_search)


func _build_list(parent: Control) -> void:
	_list_panel = PanelContainer.new()
	_list_panel.theme_type_variation = &"DexPanel"
	_list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_list_panel.custom_minimum_size.x = UiTokens.DEX_LAYOUT_GRID_WIDTH
	parent.add_child(_list_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.DEX_SECTION_GAP)
	_list_panel.add_child(column)
	var refine := HBoxContainer.new()
	refine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	refine.add_theme_constant_override(&"separation", UiTokens.DEX_SECTION_GAP)
	column.add_child(refine)
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
	_flow.add_theme_constant_override(&"h_separation", UiTokens.DEX_LAYOUT_CELL_GAP)
	_flow.add_theme_constant_override(&"v_separation", UiTokens.DEX_LAYOUT_CELL_GAP)
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
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.visible = false
	return button


func _build_sheet(parent: Control) -> void:
	_sheet_panel = PanelContainer.new()
	_sheet_panel.theme_type_variation = &"DexPanel"
	_sheet_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_panel.size_flags_stretch_ratio = UiTokens.DEX_LAYOUT_RIGHT_STRETCH
	_sheet_panel.custom_minimum_size.x = UiTokens.DEX_LAYOUT_RIGHT_MIN
	parent.add_child(_sheet_panel)
	_sheet = PokedexSheet.new()
	_sheet.route_requested.connect(route_requested.emit)
	_sheet_panel.add_child(_sheet)
	_sheet_empty = Label.new()
	_sheet_empty.theme_type_variation = &"BagEmpty"
	_sheet_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheet_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sheet_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet_empty.visible = false
	_sheet_panel.add_child(_sheet_empty)


## Aucune espèce choisie : le centre et la droite n'affichent que [param text] (s'il est
## vide, des colonnes vides).
func _show_empty_species(empty: bool, text: String) -> void:
	_sheet.visible = not empty
	_sheet_empty.visible = empty and not text.is_empty()
	_sheet_empty.text = text
	if empty:
		_portrait.show_species(null, text)


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
	back_requested.emit()
