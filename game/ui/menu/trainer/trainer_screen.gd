class_name TrainerScreen
extends MenuScreen
## Écran Dresseur du Menu Dresseur (dossier 08 §6 ; jalon-06.md §6.11 ; maquette
## menu-dresseur-v1.jpg pour la DA seulement, règle 10), recomposé en paysage (MM.2) : à gauche
## le **grand portrait peint** du héros sur le décor de sa zone, avec nom, titre, date de départ,
## argent et liens « vus » / « capturés » ; au centre les **8 emplacements de badges** (silhouette
## commune et « ??? » tant qu'ils ne sont pas obtenus) et l'équipe actuelle en artworks ; à droite
## les statistiques et la frise des grands moments (vignettes des lieux).
##
## Un journal, pas un tableau de bord : ni niveau, XP, titre, tenue, pourcentage, heure,
## « 27 / 151 » ni « 1 / 8 » ; **l'argent y est** (dossier 09 §10, Q-8). Il reçoit un
## [TrainerView] et n'en sait rien d'autre ; il n'invente aucune route et ne décide aucun
## déblocage.
## - « vus » / « capturés » (seulement s'ils sont dans la vue) : **un** [signal route_requested]
##   avec la route de la vue.
## - Un moment avec route touché : **un** [signal route_requested] avec cette route ; sans route
##   (et les badges, l'équipe) : rien.
## - Un badge **obtenu** touché : bulle de détail (nom, puis ville et Champion) ancrée sous
##   l'emplacement ; un toucher n'importe où (y compris le même badge) la ferme. Un badge muet
##   est inerte.
## - « ‹ » : [signal back_requested].
## Composition (MM.2) : l'écran remonte dans la rangée du × (covers_header) et y pose son « ‹ »
## (owns_back), l'icône du Dresseur et « Dresseur » ; bandeau d'état de l'hôte à droite.
## Placement : rempli par [TrainerMenu] sous l'en-tête, marges de SAFE_MARGIN.

## J30 (Q30-4) : le lien « Panthéon » a été touché (consultation, lecture seule).
signal hall_of_fame_requested

const TITLE := "Dresseur"
const BACK_TEXT := "RETOUR"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const TITLE_ICON: Texture2D = preload("res://assets/ui/icons/menu/trainer.svg")
const ICON_CALENDAR: Texture2D = preload("res://assets/ui/icons/trainer/calendar.svg")
const ICON_COIN: Texture2D = preload("res://assets/ui/icons/shop/coin.svg")
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
var _identity: PanelContainer
var _backdrop: ZoneArt
var _stage: Control
var _name: Label
var _subtitle: Label
var _started_row: HBoxContainer
var _started: Label
var _money_row: HBoxContainer
var _money: Label
var _portrait: TextureRect
var _links: HBoxContainer
var _seen: Button
var _caught: Button
var _seen_route: MenuRoute
var _caught_route: MenuRoute
## J30 (Q30-4) : lien « Panthéon ».
var _hall: Button
var _slots: Array[BadgeSlot] = []
var _team_panel: PanelContainer
var _team_grid: GridContainer
var _team_cards: Array[TrainerTeamCard] = []
var _stats_panel: PanelContainer
var _stats_grid: GridContainer
var _scroll: ScrollContainer
var _moments: VBoxContainer
var _rows: Array[MomentRow] = []
var _empty: Label
var _catcher: Control
var _bubble: BadgeBubble
var _bubble_slot: BadgeSlot


func _init() -> void:
	covers_header = true
	owns_back = true
	backdrop_dim = UiTokens.MENU_GLASS_DIM
	backdrop_blur = UiTokens.MENU_GLASS_BLUR
	backdrop_lod = UiTokens.MENU_GLASS_LOD


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = -UiTokens.DEX_LAYOUT_RISE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	add_child(column)
	_build_header(column)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	column.add_child(body)
	body.add_child(_build_identity())
	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	body.add_child(center)
	center.add_child(_build_badges())
	center.add_child(_build_team())
	var side := VBoxContainer.new()
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.custom_minimum_size.x = UiTokens.TRAINER_SIDE_WIDTH
	side.add_theme_constant_override(&"separation", UiTokens.TRAINER_GAP)
	body.add_child(side)
	_stats_panel = PanelContainer.new()
	_stats_panel.theme_type_variation = &"MenuGlass"
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(_stats_panel)
	side.add_child(_build_moments())
	_build_bubble_layer()
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


## Grand portrait peint du héros.
func get_portrait() -> TextureRect:
	return _portrait


## Décor du portrait (aperçu de la zone du joueur).
func get_backdrop() -> ZoneArt:
	return _backdrop


## Boutons « vus » et « capturés » (cachés quand la vue laisse le texte vide).
func get_seen_button() -> Button:
	return _seen


func get_caught_button() -> Button:
	return _caught


## Toujours 8 emplacements.
func get_badge_slots() -> Array[BadgeSlot]:
	return _slots


## Cartes de l'équipe actuelle, dans l'ordre (vide : section absente).
func get_team_cards() -> Array[TrainerTeamCard]:
	return _team_cards


func get_team_panel() -> PanelContainer:
	return _team_panel


## Bulle de détail ouverte (null : fermée).
func get_open_bubble() -> BadgeBubble:
	return _bubble if _catcher != null and _catcher.visible else null


## Ouvre la bulle de détail de [param slot] (sans effet si le badge n'est pas obtenu).
func open_badge_detail(slot: BadgeSlot) -> void:
	if slot == null or not slot.is_touchable() or _catcher == null:
		return
	_bubble_slot = slot
	_bubble.setup(slot.get_view())
	_catcher.visible = true
	var rect := slot.get_global_rect()
	var local := rect.position - _catcher.get_global_rect().position
	var width := _bubble.size.x
	var x := clampf(local.x + rect.size.x * 0.5 - width * 0.5, float(UiTokens.SAFE_MARGIN),
		_catcher.size.x - float(UiTokens.SAFE_MARGIN) - width)
	var y := local.y + rect.size.y + float(UiTokens.TRAINER_BUBBLE_OFFSET)
	if y + _bubble.size.y > _catcher.size.y - float(UiTokens.SAFE_MARGIN):
		y = local.y - float(UiTokens.TRAINER_BUBBLE_OFFSET) - _bubble.size.y
	_bubble.position = Vector2(x, y)
	_bubble.appear(speed_scale)


func close_badge_detail() -> void:
	if _catcher != null:
		_catcher.visible = false
	_bubble_slot = null


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


func _build_header(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.TOUCH_MIN
	row.add_theme_constant_override(&"separation", UiTokens.MENU_TITLE_GAP)
	parent.add_child(row)
	_back = Button.new()
	_back.theme_type_variation = &"MenuRoundButton"
	_back.icon = BACK_ICON
	_back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back.tooltip_text = BACK_TEXT
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	_back.pressed.connect(_on_back)
	row.add_child(_back)
	var icon := TextureRect.new()
	icon.texture = TITLE_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.MENU_TITLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var title := Label.new()
	title.theme_type_variation = &"MenuScreenTitle"
	title.text = TITLE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)


## Identité : décor de la zone du joueur, grand portrait peint ancré en bas à droite, textes
## par-dessus (ombrés), liens « vus » / « capturés » en bas.
func _build_identity() -> PanelContainer:
	_identity = PanelContainer.new()
	_identity.theme_type_variation = &"MapHero"
	_identity.custom_minimum_size.x = UiTokens.TRAINER_IDENTITY_WIDTH
	_identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_identity.clip_contents = true
	_backdrop = ZoneArt.new()
	_backdrop.set_style(float(UiTokens.MENU_GLASS_RADIUS), 0.0,
		UiTokens.tinted(UiTokens.SURFACE_DARK, 0.85), 0.25)
	_identity.add_child(_backdrop)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.resized.connect(_place_portrait)
	_identity.add_child(_stage)
	_portrait = TextureRect.new()
	_portrait.texture = MenuArt.hero_bust()
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_portrait)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.MENU_GLASS_PAD)
	_identity.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	margin.add_child(column)
	_name = Label.new()
	_name.theme_type_variation = &"MenuName"
	_name.clip_text = true
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow(_name)
	column.add_child(_name)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = &"MenuSubtitle"
	_subtitle.clip_text = true
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow(_subtitle)
	column.add_child(_subtitle)
	var bar := Panel.new()
	bar.theme_type_variation = &"MenuIdBar"
	bar.custom_minimum_size = UiTokens.MENU_ID_BAR
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bar)
	_started_row = _icon_row(column, ICON_CALENDAR, UiTokens.TEXT)
	_started = _started_row.get_child(1) as Label
	_started.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_started.clip_text = false
	_money_row = _icon_row(column, ICON_COIN, UiTokens.ACCENT)
	_money = _money_row.get_child(1) as Label
	_started_row.item_rect_changed.connect(_place_portrait)
	_money_row.item_rect_changed.connect(_place_portrait)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
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
	# J30 (Q30-4) : « Panthéon » sur sa propre ligne, sous l'argent (la rangée des liens reste à
	# deux boutons).
	_hall = _link_button()
	_hall.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_hall.clip_text = false
	_hall.custom_minimum_size.x = UiTokens.TRAINER_HALL_LINK_WIDTH
	_hall.pressed.connect(_on_hall_pressed)
	column.add_child(_hall)
	column.move_child(_hall, _money_row.get_index() + 1)
	_hall.item_rect_changed.connect(_place_portrait)
	return _identity


func _build_badges() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuGlass"
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
		slot.touched.connect(open_badge_detail)
		grid.add_child(slot)
		_slots.append(slot)
	return panel


## Couche de la bulle : un receveur plein écran (un toucher le ferme) et la bulle par-dessus.
func _build_bubble_layer() -> void:
	_catcher = Control.new()
	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.visible = false
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)
	_bubble = BadgeBubble.new()
	_catcher.add_child(_bubble)


func _on_catcher_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	# Fermée au **relâchement** : l'appui a été avalé ici, il ne peut pas atteindre ce qui est
	# dessous (un lien de la frise, un autre badge) une fois la bulle partie.
	if (mouse != null and not mouse.pressed) or (touch != null and not touch.pressed):
		close_badge_detail()
	_catcher.accept_event()


func _build_team() -> PanelContainer:
	_team_panel = PanelContainer.new()
	_team_panel.theme_type_variation = &"MenuGlass"
	_team_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_SECTION_GAP)
	_team_panel.add_child(column)
	_section_title(column, TrainerView.TEAM_TITLE)
	_team_grid = GridContainer.new()
	_team_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_grid.columns = UiTokens.TRAINER_TEAM_COLUMNS
	_team_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_team_grid.add_theme_constant_override(&"h_separation", UiTokens.TRAINER_BADGE_GAP)
	_team_grid.add_theme_constant_override(&"v_separation", UiTokens.TRAINER_BADGE_GAP)
	column.add_child(_team_grid)
	return _team_panel


func _build_moments() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MenuGlass"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.TRAINER_SECTION_GAP)
	panel.add_child(column)
	_section_title(column, TrainerView.MOMENTS_TITLE)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	_moments = VBoxContainer.new()
	_moments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_moments.add_theme_constant_override(&"separation", UiTokens.TRAINER_MOMENT_GAP)
	_scroll.add_child(_moments)
	return panel


func _apply(view: TrainerView) -> void:
	close_badge_detail()
	_name.text = view.player_name
	_subtitle.text = view.player_title
	_subtitle.visible = not view.player_title.is_empty()
	_backdrop.show_zone(view.zone_id)
	var started := ""
	if not view.started_text.is_empty():
		started = "%s : %s" % [TrainerView.STARTED_LABEL, view.started_text]
	_set_row(_started_row, _started, started)
	var money := ""
	if not view.money_text.is_empty():
		money = "%s : %s" % [TrainerView.MONEY_LABEL, view.money_text]
	_set_row(_money_row, _money, money)
	_place_portrait.call_deferred()
	_seen_route = view.seen_route
	_caught_route = view.caught_route
	_set_link(_seen, view.seen_text)
	_set_link(_caught, view.caught_text)
	_set_link(_hall, view.hall_of_fame_text)
	_links.visible = _seen.visible or _caught.visible
	for i: int in _slots.size():
		_slots[i].setup(view.badges[i] if i < view.badges.size() else BadgeSlotView.new(i))
	_rebuild_team(view)
	_rebuild_stats(view)
	_rebuild_moments(view)


func _rebuild_team(view: TrainerView) -> void:
	for card: TrainerTeamCard in _team_cards:
		_team_grid.remove_child(card)
		card.queue_free()
	_team_cards.clear()
	_team_panel.visible = not view.team.is_empty()
	for member: TeamMemberView in view.team:
		var card := TrainerTeamCard.new()
		_team_grid.add_child(card)
		card.setup(member)
		_team_cards.append(card)


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
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	# Le texte est limité à la moitié gauche : le portrait occupe la droite.
	label.custom_minimum_size.x = 0.0
	_shadow(label)
	row.add_child(label)
	return row


## Ombre portée du texte : il se lit sur le décor et le portrait peints.
func _shadow(label: Label) -> void:
	label.add_theme_color_override(&"font_shadow_color", UiTokens.DEX_SCENE_TEXT_SHADOW)
	label.add_theme_constant_override(&"shadow_offset_x", 0)
	label.add_theme_constant_override(&"shadow_offset_y", 2)
	label.add_theme_constant_override(&"shadow_outline_size", UiTokens.DEX_SCENE_TEXT_SHADOW_SIZE)


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


## Bas des lignes d'identité (nom, date, argent), dans le repère du cadre : le portrait
## commence sous cette ligne, jamais dessus (montant à 6 chiffres compris).
func _text_bottom() -> float:
	var bottom := 0.0
	for row: Control in [_started_row, _money_row, _hall]:
		if row != null and row.visible:
			bottom = maxf(bottom, row.global_position.y + row.size.y - _stage.global_position.y)
	return bottom + UiTokens.GAP


## Portrait : au plus TRAINER_HERO_MAX de haut, posé sur le bas du cadre, bord droit contre lui.
func _place_portrait() -> void:
	var texture := _portrait.texture
	if texture == null:
		return
	var free_top := _text_bottom()
	var height := minf(float(UiTokens.TRAINER_HERO_MAX), _stage.size.y - free_top)
	height = maxf(height, 0.0)
	var width := height * texture.get_width() / float(texture.get_height())
	_portrait.size = Vector2(width, height)
	_portrait.position = Vector2(_stage.size.x - width + UiTokens.TRAINER_HERO_OFFSET_X,
		_stage.size.y - height)


func _on_link_pressed(is_seen: bool) -> void:
	var route := _seen_route if is_seen else _caught_route
	if route == null:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	route_requested.emit(route)


## J30 (Q30-4) : lien « Panthéon » touché.
func _on_hall_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	hall_of_fame_requested.emit()


## Bouton « Panthéon » (tests).
func get_hall_of_fame_button() -> Button:
	return _hall


func _on_back() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
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
		var button := child as BaseButton
		if button != null and button.is_visible_in_tree() and not button.disabled:
			into.append(button)
		_collect_touch(child, into)
