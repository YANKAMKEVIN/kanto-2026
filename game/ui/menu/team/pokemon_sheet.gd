class_name PokemonSheet
extends VBoxContainer
## La fiche du Pokémon sélectionné (dossier 08 §2) : trois onglets Aperçu · Capacités ·
## Histoire. Elle ne connaît qu'un [PokemonSheetView].
## - Aperçu : type(s), sexe, six statistiques en jauges + valeurs (jamais un tableau),
##   évolution **sans spoiler** (stades vus, sinon « ??? » ; jamais de condition, de niveau, de
##   silhouette ni d'image d'un stade inconnu : Q-9).
## - Capacités : une carte par capacité (MoveCard) ; un toucher émet [signal move_tapped].
## - Histoire : lieu, niveau de rencontre, dresseur d'origine, date ; sinon une phrase douce.
## L'onglet ouvert se garde quand on change de Pokémon.

## Une capacité est touchée (rang dans la fiche).
signal move_tapped(index: int)
## Un onglet est choisi.
signal tab_changed(tab: int)

enum Tab { OVERVIEW, MOVES, HISTORY }

const TAB_TEXTS: Dictionary[Tab, String] = {
	Tab.OVERVIEW: "Aperçu",
	Tab.MOVES: "Capacités",
	Tab.HISTORY: "Histoire",
}
const TYPE_CAPTION := "Type"
const GENDER_CAPTION := "Sexe"
const STATS_CAPTION := "Statistiques"
const EVOLUTION_CAPTION := "Évolution"
const GENDER_NAMES: Dictionary[BattleCardView.Gender, String] = {
	BattleCardView.Gender.NONE: "—",
	BattleCardView.Gender.MALE: "Mâle",
	BattleCardView.Gender.FEMALE: "Femelle",
}
const LEVEL_CAPTION := "Niveau"
const TRAINER_CAPTION := "Dresseur d'origine"
const DATE_CAPTION := "Date"
const STAGE_SEPARATOR := "→"
const BRANCH_SEPARATOR := "/"
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")
const MOVE_CARD_SCENE: PackedScene = preload("res://game/ui/battle/move_card.tscn")

var _sheet: PokemonSheetView
var _tab: Tab = Tab.OVERVIEW
var _tabs: Dictionary[Tab, Button] = {}
var _pages: Dictionary[Tab, Control] = {}
var _type_row: HBoxContainer
var _gender_icon: TextureRect
var _gender_text: Label
var _stats: VBoxContainer
var _evolution: PanelContainer
var _evolution_row: HBoxContainer
var _moves: VBoxContainer
var _history: VBoxContainer
var _move_cards: Array[MoveCard] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", UiTokens.TEAM_PAGE_GAP)
	_build()


## Pose [param sheet] sur les trois pages ; l'onglet ouvert reste ouvert.
func show_sheet(sheet: PokemonSheetView) -> void:
	_sheet = sheet
	_fill_overview(sheet)
	_fill_moves(sheet)
	_fill_history(sheet)
	_show_tab(_tab)


## Ouvre un onglet (comme un toucher, sans la vibration).
func select_tab(tab: Tab) -> void:
	_tabs[tab].button_pressed = true
	_show_tab(tab)


func get_tab() -> Tab:
	return _tab


func get_tab_button(tab: Tab) -> Button:
	return _tabs[tab]


func get_page(tab: Tab) -> Control:
	return _pages[tab]


func get_move_cards() -> Array[MoveCard]:
	return _move_cards


func get_stats_container() -> VBoxContainer:
	return _stats


func get_evolution_section() -> PanelContainer:
	return _evolution


func get_evolution_row() -> HBoxContainer:
	return _evolution_row


func get_history_container() -> VBoxContainer:
	return _history


func get_type_row() -> HBoxContainer:
	return _type_row


## Tous les textes d'une page (pour vérifier ce qui est écrit).
func get_page_texts(tab: Tab) -> Array[String]:
	var texts: Array[String] = []
	_collect_texts(_pages[tab], texts)
	return texts


func _collect_texts(node: Node, into: Array[String]) -> void:
	var label := node as Label
	if label != null and label.is_visible_in_tree() and not label.text.is_empty():
		into.append(label.text)
	for child: Node in node.get_children():
		_collect_texts(child, into)


func _show_tab(tab: Tab) -> void:
	_tab = tab
	for key: Tab in _pages:
		_pages[key].visible = key == tab
	if not _tabs[tab].button_pressed:
		_tabs[tab].set_pressed_no_signal(true)


func _on_tab_pressed(tab: Tab) -> void:
	if tab == _tab:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_show_tab(tab)
	tab_changed.emit(tab)


func _fill_overview(sheet: PokemonSheetView) -> void:
	_clear(_type_row)
	for i: int in sheet.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_type_row.add_child(badge)
		badge.set_type(sheet.type_ids[i], sheet.type_names[i])
	var gender := sheet.member.gender
	_gender_icon.texture = BattleInfoCard.GENDER_ICONS.get(gender, null)
	_gender_icon.modulate = BattleInfoCard.GENDER_COLORS.get(gender, UiTokens.TEXT)
	_gender_icon.visible = _gender_icon.texture != null
	_gender_text.text = GENDER_NAMES.get(gender, "—")
	_clear(_stats)
	for stat: StatView in sheet.stats:
		_stats.add_child(_stat_row(stat))
	_fill_evolution(sheet)


func _stat_row(stat: StatView) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = UiTokens.TEAM_STAT_ROW
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	var name_label := Label.new()
	name_label.theme_type_variation = &"TeamStat"
	name_label.text = stat.name
	name_label.custom_minimum_size.x = UiTokens.TEAM_STAT_NAME_WIDTH
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	var gauge := StatGauge.new()
	gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauge.set_ratio(stat.ratio, UiTokens.HP_HIGH if stat.stat_id == &"hp"
		else UiTokens.TEAM_GAUGE_FILL)
	row.add_child(gauge)
	var value := Label.new()
	value.theme_type_variation = &"TeamValue"
	value.text = str(stat.value)
	value.custom_minimum_size.x = UiTokens.TEAM_STAT_VALUE_WIDTH
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value)
	return row


## Évolution : « Évolution » puis les stades (vignette + nom) ; « → » entre colonnes, « / »
## entre branches. Un stade inconnu : un cercle vide et « ??? » — ni image ni silhouette.
func _fill_evolution(sheet: PokemonSheetView) -> void:
	_evolution.visible = not sheet.evolution.is_empty()
	_clear(_evolution_row)
	var caption := Label.new()
	caption.theme_type_variation = &"TeamValue"
	caption.text = EVOLUTION_CAPTION
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_evolution_row.add_child(caption)
	for i: int in sheet.evolution.size():
		var stage := sheet.evolution[i]
		if i > 0:
			var same_column := sheet.evolution[i - 1].step == stage.step
			_evolution_row.add_child(_separator(BRANCH_SEPARATOR if same_column
				else STAGE_SEPARATOR))
		_evolution_row.add_child(_stage_node(stage))


func _separator(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"TeamCaption"
	label.text = text
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _stage_node(stage: EvolutionStageView) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	var circle := Panel.new()
	circle.theme_type_variation = &"TeamEvoCircle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2.ONE * UiTokens.TEAM_EVO_CIRCLE
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(circle)
	if stage.known:
		var path := TeamSlotCard.SPRITE_PATH % stage.species_id
		if ResourceLoader.exists(path):
			var image := TextureRect.new()
			image.texture = load(path) as Texture2D
			image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.custom_minimum_size = Vector2.ONE * UiTokens.TEAM_EVO_SPRITE
			image.size = image.custom_minimum_size
			image.position = (Vector2.ONE * UiTokens.TEAM_EVO_CIRCLE - image.size) * 0.5
			circle.add_child(image)
	var name_label := Label.new()
	name_label.theme_type_variation = &"TeamCaption"
	name_label.text = stage.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stage.current:
		name_label.add_theme_color_override(&"font_color", UiTokens.ACCENT)
	column.add_child(name_label)
	return column


func _fill_moves(sheet: PokemonSheetView) -> void:
	_clear(_moves)
	_move_cards.clear()
	for i: int in sheet.moves.size():
		var card := MOVE_CARD_SCENE.instantiate() as MoveCard
		card.ignore_pp = true
		_moves.add_child(card)
		card.custom_minimum_size = Vector2(0.0, UiTokens.TEAM_MOVE_CARD_HEIGHT)
		card.set_view(sheet.moves[i])
		card.tapped.connect(_on_move_tapped.bind(i))
		_move_cards.append(card)


func _on_move_tapped(index: int) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	move_tapped.emit(index)


func _fill_history(sheet: PokemonSheetView) -> void:
	_clear(_history)
	var history := sheet.history
	if history.is_empty():
		_history.add_child(_history_text(TeamViews.HISTORY_UNKNOWN, true))
		return
	if not history.note.is_empty():
		_history.add_child(_history_text(history.note, true))
	if not history.place.is_empty():
		_history.add_child(_history_row(history.place_label, history.place))
	if history.met_level > 0:
		_history.add_child(_history_row(LEVEL_CAPTION, str(history.met_level)))
	if not history.trainer.is_empty():
		_history.add_child(_history_row(TRAINER_CAPTION, history.trainer))
	if not history.date_text.is_empty():
		_history.add_child(_history_row(DATE_CAPTION, history.date_text))


func _history_text(text: String, muted: bool) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"TeamValue"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if muted:
		label.add_theme_color_override(&"font_color", UiTokens.TEXT_MUTED)
	return label


func _history_row(caption: String, value: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 0)
	var cap := Label.new()
	cap.theme_type_variation = &"TeamCaption"
	cap.text = caption
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cap)
	var val := Label.new()
	val.theme_type_variation = &"TeamValue"
	val.add_theme_font_size_override(&"font_size", UiTokens.TEAM_HISTORY_FONT)
	val.text = value
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(val)
	return box


func _clear(container: Node) -> void:
	for old: Node in container.get_children():
		container.remove_child(old)
		old.queue_free()


func _build() -> void:
	var tab_row := HBoxContainer.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_row.add_theme_constant_override(&"separation", UiTokens.GAP / 2)
	add_child(tab_row)
	var group := ButtonGroup.new()
	for tab: Tab in TAB_TEXTS:
		var button := Button.new()
		button.theme_type_variation = &"TeamTab"
		button.text = TAB_TEXTS[tab]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = UiTokens.TEAM_TAB_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_pressed.bind(tab))
		tab_row.add_child(button)
		_tabs[tab] = button
	_tabs[Tab.OVERVIEW].set_pressed_no_signal(true)

	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.clip_contents = true
	add_child(stack)

	var overview := VBoxContainer.new()
	overview.add_theme_constant_override(&"separation", UiTokens.TEAM_PAGE_GAP)
	overview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pages[Tab.OVERVIEW] = overview
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override(&"separation", UiTokens.GAP * 2)
	overview.add_child(info)
	var type_box := VBoxContainer.new()
	type_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_box.add_theme_constant_override(&"separation", UiTokens.TEAM_HEADER_GAP / 2)
	info.add_child(type_box)
	type_box.add_child(_caption(TYPE_CAPTION))
	_type_row = HBoxContainer.new()
	_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	type_box.add_child(_type_row)
	var gender_box := VBoxContainer.new()
	gender_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gender_box.add_theme_constant_override(&"separation", UiTokens.TEAM_HEADER_GAP / 2)
	info.add_child(gender_box)
	gender_box.add_child(_caption(GENDER_CAPTION))
	var gender_row := HBoxContainer.new()
	gender_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gender_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	gender_box.add_child(gender_row)
	_gender_icon = TextureRect.new()
	_gender_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gender_icon.custom_minimum_size = Vector2.ONE * UiTokens.MENU_STAT_ICON
	_gender_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gender_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gender_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gender_row.add_child(_gender_icon)
	_gender_text = Label.new()
	_gender_text.theme_type_variation = &"TeamValue"
	_gender_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gender_row.add_child(_gender_text)
	var stats_panel := _section()
	overview.add_child(stats_panel)
	_stats = VBoxContainer.new()
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats.add_theme_constant_override(&"separation", 0)
	stats_panel.get_child(0).add_child(_stats)
	_evolution = _section()
	overview.add_child(_evolution)
	_evolution_row = HBoxContainer.new()
	_evolution_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_evolution_row.add_theme_constant_override(&"separation", UiTokens.GAP)
	_evolution.get_child(0).add_child(_evolution_row)

	_moves = VBoxContainer.new()
	_moves.add_theme_constant_override(&"separation", UiTokens.TEAM_HEADER_GAP)
	_moves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pages[Tab.MOVES] = _moves
	_history = VBoxContainer.new()
	_history.add_theme_constant_override(&"separation", UiTokens.TEAM_PAGE_GAP)
	_history.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pages[Tab.HISTORY] = _history
	for page: Control in _pages.values():
		page.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		stack.add_child(page)
		page.visible = false
	overview.visible = true


## Section : un panneau sombre discret avec une marge ; le conteneur intérieur est son premier
## enfant.
func _section() -> PanelContainer:
	var section := PanelContainer.new()
	section.theme_type_variation = &"TeamSection"
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.GAP)
	section.add_child(margin)
	return section


func _caption(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"TeamCaption"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
