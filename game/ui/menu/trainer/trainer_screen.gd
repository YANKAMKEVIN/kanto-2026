class_name TrainerScreen
extends MenuScreen
## Écran Dresseur du Menu Dresseur (dossier 08 §6 ; jalon-06.md §6.11 ; maquette
## menu-dresseur-v1.jpg pour la DA seulement, règle 10), recomposé en paysage : identité et
## portrait à gauche, **8 emplacements de badges muets** et statistiques au centre, frise des
## grands moments à droite.
##
## Un journal, pas un tableau de bord : ni niveau, XP, titre, tenue, pourcentage, argent, heure,
## « 27 / 151 » ni « 1 / 8 ». Il reçoit un [TrainerView] et n'en sait rien d'autre ; il n'invente
## aucune route et ne décide aucun déblocage.
## - « vus » / « capturés » (seulement s'ils sont dans la vue) : **un** [signal route_requested]
##   avec la route de la vue.
## - Un moment avec route touché : **un** [signal route_requested] avec cette route ; sans route
##   (et les badges) : rien.
## - RETOUR : [signal back_requested].
## Placement : rempli par [TrainerMenu] sous l'en-tête, marges de SAFE_MARGIN.

const TITLE := "Dresseur"
const BACK_TEXT := "RETOUR"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const ICON_CLOCK: Texture2D = preload("res://assets/ui/icons/menu/clock.svg")
const ICON_CALENDAR: Texture2D = preload("res://assets/ui/icons/trainer/calendar.svg")
const STAT_ICONS: Dictionary[StringName, Texture2D] = {
	TrainerSummary.STAT_PLAY_TIME: preload("res://assets/ui/icons/menu/clock.svg"),
	TrainerSummary.STAT_ZONES: preload("res://assets/ui/icons/menu/map.svg"),
	TrainerSummary.STAT_CAPTURES: preload("res://assets/ui/icons/poke_ball.svg"),
	TrainerSummary.STAT_ITEMS_FOUND: preload("res://assets/ui/icons/battle/bag.svg"),
}
const ICON_STAT_DEFAULT: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")

var _view: TrainerView
var _built: bool = false
var _back: Button
var _name: Label
var _subtitle: Label
var _play_time_row: HBoxContainer
var _play_time: Label
var _started_row: HBoxContainer
var _started: Label
var _portrait: TextureRect
var _links: HBoxContainer
var _seen: Button
var _caught: Button
var _seen_route: MenuRoute
var _caught_route: MenuRoute
var _slots: Array[BadgeSlot] = []
var _stats_panel: PanelContainer
var _stats_grid: GridContainer
var _scroll: ScrollContainer
var _moments: VBoxContainer
var _rows: Array[MomentRow] = []
var _empty: Label


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	add_child(body)
	body.add_child(_build_identity())
	var rest := VBoxContainer.new()
	rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	body.add_child(rest)
	_build_header(rest)
	var columns := HBoxContainer.new()
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	rest.add_child(columns)
	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	columns.add_child(center)
	center.add_child(_build_badges())
	_stats_panel = PanelContainer.new()
	_stats_panel.theme_type_variation = &"MenuPanel"
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(_stats_panel)
	columns.add_child(_build_moments())
	_built = true
	if _view != null:
		_apply(_view)


## Affiche [param view]. Rappelé pendant que l'écran est affiché, il met à jour **sans rejouer
## l'entrée** (la frise garde sa position de défilement).
func show_trainer(view: TrainerView) -> void:
	_view = view
	if _built:
		_apply(view)


func get_back_button() -> Button:
	return _back


func get_name_label() -> Label:
	return _name


func get_portrait() -> TextureRect:
	return _portrait


## Boutons « vus » et « capturés » (cachés quand la vue laisse le texte vide).
func get_seen_button() -> Button:
	return _seen


func get_caught_button() -> Button:
	return _caught


## Toujours 8 emplacements.
func get_badge_slots() -> Array[BadgeSlot]:
	return _slots


## Lignes de la frise, du plus ancien au plus récent.
func get_moment_rows() -> Array[MomentRow]:
	return _rows


func get_scroll() -> ScrollContainer:
	return _scroll


## Phrase de la frise vide (null : la frise a des moments).
func get_empty_label() -> Label:
	return _empty


func get_stats_panel() -> PanelContainer:
	return _stats_panel


## Tous les textes visibles de l'écran, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(self, texts)
	return texts


## Tous les contrôles qui répondent au toucher (boutons visibles et actifs) : pour vérifier
## les tailles et les marges.
func get_touch_controls() -> Array[Control]:
	var found: Array[Control] = []
	_collect_touch(self, found)
	return found


func _build_identity() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size.x = UiTokens.TRAINER_LEFT_WIDTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	panel.add_child(column)
	_name = Label.new()
	_name.theme_type_variation = &"MenuName"
	_name.clip_text = true
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_name)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = &"MenuSubtitle"
	_subtitle.clip_text = true
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_subtitle)
	var bar := Panel.new()
	bar.theme_type_variation = &"MenuIdBar"
	bar.custom_minimum_size = UiTokens.MENU_ID_BAR
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bar)
	_play_time_row = _icon_row(column, ICON_CLOCK, UiTokens.TEXT)
	_play_time = _play_time_row.get_child(1) as Label
	_started_row = _icon_row(column, ICON_CALENDAR, UiTokens.TEXT)
	_started = _started_row.get_child(1) as Label
	_started.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_started.clip_text = false
	_portrait = TextureRect.new()
	_portrait.texture = _portrait_texture()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(UiTokens.MENU_PORTRAIT_SOURCE) \
		* UiTokens.TRAINER_PORTRAIT_SCALE
	_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_portrait)
	_links = HBoxContainer.new()
	_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_links.add_theme_constant_override(&"separation", UiTokens.TRAINER_LINK_GAP)
	column.add_child(_links)
	_seen = _link_button()
	_seen.pressed.connect(_on_link_pressed.bind(true))
	_links.add_child(_seen)
	_caught = _link_button()
	_caught.pressed.connect(_on_link_pressed.bind(false))
	_links.add_child(_caught)
	return panel


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.TRAINER_HEADER_HEIGHT
	row.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"PanelButton"
	_back.text = BACK_TEXT
	_back.icon = BACK_ICON
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(UiTokens.TRAINER_BACK_WIDTH, UiTokens.TOUCH_MIN)
	_back.pressed.connect(back_requested.emit)
	row.add_child(_back)
	var title := Label.new()
	title.theme_type_variation = &"DexTitle"
	title.text = TITLE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)


func _build_badges() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_SECTION_GAP)
	panel.add_child(column)
	_section_title(column, TrainerView.BADGES_TITLE)
	var grid := GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.columns = UiTokens.TRAINER_BADGE_COLUMNS
	grid.add_theme_constant_override(&"h_separation", UiTokens.TRAINER_BADGE_GAP)
	grid.add_theme_constant_override(&"v_separation", UiTokens.TRAINER_BADGE_GAP)
	column.add_child(grid)
	for i: int in TrainerView.BADGE_COUNT:
		var slot := BadgeSlot.new()
		grid.add_child(slot)
		_slots.append(slot)
	return panel


func _build_moments() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.custom_minimum_size.x = UiTokens.TRAINER_RIGHT_WIDTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_SECTION_GAP)
	panel.add_child(column)
	_section_title(column, TrainerView.MOMENTS_TITLE)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_moments = VBoxContainer.new()
	_moments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_moments.add_theme_constant_override(&"separation", UiTokens.TRAINER_MOMENT_GAP)
	_scroll.add_child(_moments)
	return panel


func _apply(view: TrainerView) -> void:
	_name.text = view.player_name
	_subtitle.text = view.player_title
	_subtitle.visible = not view.player_title.is_empty()
	_set_row(_play_time_row, _play_time, view.play_time_text)
	var started := ""
	if not view.started_text.is_empty():
		started = "%s : %s" % [TrainerView.STARTED_LABEL, view.started_text]
	_set_row(_started_row, _started, started)
	_seen_route = view.seen_route
	_caught_route = view.caught_route
	_set_link(_seen, view.seen_text)
	_set_link(_caught, view.caught_text)
	_links.visible = _seen.visible or _caught.visible
	for i: int in _slots.size():
		_slots[i].setup(view.badges[i] if i < view.badges.size() else BadgeSlotView.new(i))
	_rebuild_stats(view)
	_rebuild_moments(view)


func _rebuild_stats(view: TrainerView) -> void:
	for child: Node in _stats_panel.get_children():
		_stats_panel.remove_child(child)
		child.queue_free()
	_stats_panel.visible = not view.stats.is_empty()
	if view.stats.is_empty():
		return
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_SECTION_GAP)
	_stats_panel.add_child(column)
	_section_title(column, TrainerView.STATS_TITLE)
	_stats_grid = GridContainer.new()
	_stats_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_grid.columns = UiTokens.TRAINER_STAT_COLUMNS
	_stats_grid.add_theme_constant_override(&"h_separation", UiTokens.GAP)
	_stats_grid.add_theme_constant_override(&"v_separation", UiTokens.GAP)
	column.add_child(_stats_grid)
	for line: TrainerStatView in view.stats:
		_stats_grid.add_child(_stat_cell(line))


func _stat_cell(line: TrainerStatView) -> Control:
	var cell := HBoxContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override(&"separation", UiTokens.TRAINER_STAT_GAP)
	var icon := TextureRect.new()
	icon.texture = STAT_ICONS.get(line.stat_id, ICON_STAT_DEFAULT)
	icon.modulate = UiTokens.ACCENT
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.TRAINER_STAT_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cell.add_child(icon)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override(&"separation", 0)
	cell.add_child(texts)
	var label := Label.new()
	label.theme_type_variation = &"TrainerStatLabel"
	label.text = line.label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(label)
	var value := Label.new()
	value.theme_type_variation = &"TrainerStatValue"
	value.text = line.value_text
	value.clip_text = true
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(value)
	return cell


func _rebuild_moments(view: TrainerView) -> void:
	var keep := _scroll.scroll_vertical
	for child: Node in _moments.get_children():
		_moments.remove_child(child)
		child.queue_free()
	_rows.clear()
	_empty = null
	if view.moments.is_empty():
		_empty = Label.new()
		_empty.theme_type_variation = &"TrainerEmpty"
		_empty.text = TrainerView.MOMENTS_EMPTY_TEXT
		_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_moments.add_child(_empty)
		return
	var count := view.moments.size()
	for i: int in count:
		var row := MomentRow.new(view.moments[i], i == 0, i == count - 1)
		row.touched.connect(route_requested.emit)
		_moments.add_child(row)
		_rows.append(row)
	_scroll.set_deferred(&"scroll_vertical", keep)


func _section_title(parent: Control, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = &"TrainerSection"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)


## Ligne « icône + texte » (identité) : renvoie le conteneur, le libellé est son 2e enfant.
func _icon_row(parent: Control, icon: Texture2D, tint: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.MENU_STAT_GAP)
	parent.add_child(row)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.modulate = tint
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2.ONE * UiTokens.TRAINER_ROW_ICON
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(picture)
	var label := Label.new()
	label.theme_type_variation = &"TrainerRow"
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _set_row(row: Control, label: Label, text: String) -> void:
	label.text = text
	row.visible = not text.is_empty()


func _link_button() -> Button:
	var button := Button.new()
	button.theme_type_variation = &"TrainerLink"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0.0, UiTokens.TRAINER_LINK_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	return button


## Un lien est affiché seulement si son texte l'est (« vus » / « capturés » vides avant
## l'activation du Pokédex) ; une route nulle ne se touche pas.
func _set_link(button: Button, text: String) -> void:
	button.text = text
	button.visible = not text.is_empty()


func _on_link_pressed(is_seen: bool) -> void:
	var route := _seen_route if is_seen else _caught_route
	if route == null:
		return
	Input.vibrate_handheld(UiTokens.HAPTIC_TICK_MS)
	route_requested.emit(route)


func _portrait_texture() -> Texture2D:
	var frames := load(TrainerCardPanel.PORTRAIT_FRAMES_PATH) as SpriteFrames
	if frames == null or not frames.has_animation(TrainerCardPanel.PORTRAIT_ANIMATION):
		return null
	return frames.get_frame_texture(TrainerCardPanel.PORTRAIT_ANIMATION, 0)


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
		var button := child as BaseButton
		if button != null and button.is_visible_in_tree() and not button.disabled:
			into.append(button)
		_collect_touch(child, into)
