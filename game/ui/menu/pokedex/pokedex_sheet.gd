class_name PokedexSheet
extends VBoxContainer
## La fiche d'une espèce du Pokédex (dossier 08 §4 ; jalon-06.md §6.9) : l'identité (vignette,
## numéro, nom, « Vu N fois », types à la capture) puis quatre onglets : Aperçu · Habitat ·
## Évolution · Observations. Elle ne connaît qu'un [PokedexSheetView].
##
## Anti-spoiler (règle 10, Q-9) : **seulement ce que le joueur a découvert**. Une espèce
## seulement vue n'a ni types, ni taille, ni poids, ni description (absents, pas de cases vides
## « ??? »). Jamais de statistiques de base, de talents, de silhouette, de condition
## d'évolution, ni de zone non découverte.
## - Habitat : une petite carte (les zones observées seules) et une pastille par zone ; la
##   toucher émet **un** [signal route_requested] vers la Carte.
## - L'onglet ouvert reste ouvert quand on change d'espèce.

## Zone d'habitat touchée : lien croisé vers la Carte (MenuRoute.map).
signal route_requested(route: MenuRoute)
## Un onglet est choisi (rang dans [constant PokedexSheetView.TAB_LABELS]).
signal tab_changed(tab: int)

enum Tab { OVERVIEW, HABITAT, EVOLUTION, NOTES }

const SIZE_CAPTION := "Taille"
const WEIGHT_CAPTION := "Poids"
const SEEN_HINT := "Capture ce Pokémon pour compléter sa fiche."
const NO_EVOLUTION_TEXT := "Pas d'évolution."
const STAGE_SEPARATOR := "→"
const BRANCH_SEPARATOR := "/"
const SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")
const BALL_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")
const PIN_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/pin.svg")
## Opacité de la Poké Ball qui tient la place d'un sprite absent (pas une silhouette).
const BALL_PLACEHOLDER_ALPHA := 0.16

var _view: PokedexSheetView
var _tab: Tab = Tab.OVERVIEW
var _tabs: Array[Button] = []
var _pages: Array[Control] = []
var _sprite: TextureRect
var _ball: TextureRect
var _number: Label
var _name: Label
var _counts: Label
var _type_row: HBoxContainer
var _overview: VBoxContainer
var _habitat: VBoxContainer
var _evolution: HFlowContainer
var _notes: VBoxContainer
var _map: PokedexHabitatMap
var _chips: Array[Button] = []
var _scroll: ScrollContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_build()


## Pose [param view] sur les quatre pages ; l'onglet ouvert reste ouvert.
func show_sheet(view: PokedexSheetView) -> void:
	_view = view
	_fill_identity(view)
	_fill_overview(view)
	_fill_habitat(view)
	_fill_evolution(view)
	_fill_notes(view)
	_show_tab(_tab)


## Ouvre un onglet (comme un toucher, sans la vibration).
func select_tab(tab: Tab) -> void:
	_show_tab(tab)


func get_tab() -> Tab:
	return _tab


func get_tab_button(tab: Tab) -> Button:
	return _tabs[tab]


func get_page(tab: Tab) -> Control:
	return _pages[tab]


func get_view() -> PokedexSheetView:
	return _view


func get_sprite() -> TextureRect:
	return _sprite


func get_type_row() -> HBoxContainer:
	return _type_row


func get_map() -> PokedexHabitatMap:
	return _map


## Pastilles de zone de l'onglet Habitat.
func get_chips() -> Array[Button]:
	return _chips


func get_scroll() -> ScrollContainer:
	return _scroll


func get_name_label() -> Label:
	return _name


## Tous les textes visibles d'une page, ou de toute la fiche si [param tab] vaut -1.
func get_texts(tab: int = -1) -> Array[String]:
	var texts: Array[String] = []
	_collect_texts(self if tab < 0 else _pages[tab], texts)
	return texts


func _collect_texts(node: Node, into: Array[String]) -> void:
	var label := node as Label
	if label != null and label.is_visible_in_tree() and not label.text.is_empty():
		into.append(label.text)
	var button := node as Button
	if button != null and button.is_visible_in_tree() and not button.text.is_empty():
		into.append(button.text)
	for child: Node in node.get_children():
		_collect_texts(child, into)


func _show_tab(tab: Tab) -> void:
	_tab = tab
	for i: int in _pages.size():
		_pages[i].visible = i == int(tab)
	for i: int in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == int(tab))
	_scroll.scroll_vertical = 0


func _on_tab_pressed(tab: Tab) -> void:
	if tab == _tab:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_show_tab(tab)
	tab_changed.emit(int(tab))


func _fill_identity(view: PokedexSheetView) -> void:
	var path := SPRITE_PATH % view.species_id
	var has_sprite := ResourceLoader.exists(path)
	_sprite.texture = load(path) as Texture2D if has_sprite else null
	_sprite.visible = has_sprite
	_ball.visible = not has_sprite
	_number.text = view.number_text
	_name.text = view.name
	_counts.text = view.counts_text
	_counts.visible = not view.counts_text.is_empty()
	_clear(_type_row)
	for i: int in view.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_type_row.add_child(badge)
		badge.set_type(view.type_ids[i], view.type_names[i])
	_type_row.visible = not view.type_ids.is_empty()


## Aperçu : à la capture, taille, poids et description ; sinon seulement un mot d'encouragement.
func _fill_overview(view: PokedexSheetView) -> void:
	_clear(_overview)
	var facts := HBoxContainer.new()
	facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	facts.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	if not view.height_text.is_empty():
		facts.add_child(_fact(SIZE_CAPTION, view.height_text))
	if not view.weight_text.is_empty():
		facts.add_child(_fact(WEIGHT_CAPTION, view.weight_text))
	if facts.get_child_count() > 0:
		_overview.add_child(facts)
	else:
		facts.queue_free()
	if not view.description.is_empty():
		var text := Label.new()
		text.theme_type_variation = &"BagDetailText"
		text.text = view.description
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overview.add_child(text)
	if view.description.is_empty() and view.height_text.is_empty():
		var hint := Label.new()
		hint.theme_type_variation = &"TeamCaption"
		hint.text = SEEN_HINT
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overview.add_child(hint)


func _fact(caption: String, value: String) -> PanelContainer:
	var card := _section()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 0)
	card.get_child(0).add_child(box)
	var cap := Label.new()
	cap.theme_type_variation = &"TeamCaption"
	cap.text = caption
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cap)
	var val := Label.new()
	val.theme_type_variation = &"TeamValue"
	val.add_theme_font_size_override(&"font_size", UiTokens.DEX_INFO_FONT)
	val.text = value
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(val)
	return card


## Habitat : la petite carte et une pastille par zone observée (jamais « ??? »).
func _fill_habitat(view: PokedexSheetView) -> void:
	_clear(_habitat)
	_chips.clear()
	if view.habitats.is_empty():
		_map = null
		var empty := Label.new()
		empty.theme_type_variation = &"TeamCaption"
		empty.text = view.habitat_empty_text
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_habitat.add_child(empty)
		return
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	_habitat.add_child(row)
	_map = PokedexHabitatMap.new()
	_map.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_map)
	var zone_ids: Array[StringName] = []
	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	row.add_child(list)
	for habitat: PokedexHabitatView in view.habitats:
		zone_ids.append(habitat.zone_id)
		var chip := Button.new()
		chip.theme_type_variation = &"TeamAction"
		chip.text = habitat.name
		chip.icon = PIN_ICON
		chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		chip.focus_mode = Control.FOCUS_NONE
		chip.custom_minimum_size.y = UiTokens.DEX_CHIP_HEIGHT
		chip.add_theme_constant_override(&"icon_max_width", UiTokens.DEX_CHIP_ICON)
		# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		TapGuard.attach(chip)
		chip.pressed.connect(_on_chip_pressed.bind(habitat.zone_id))
		list.add_child(chip)
		_chips.append(chip)
	_map.set_zones(zone_ids)


func _on_chip_pressed(zone_id: StringName) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	route_requested.emit(MenuRoute.map(zone_id))


## Évolution : un rond (sprite à l'échelle entière) et un nom par stade, « → » entre les
## colonnes, « / » entre les branches. Un stade inconnu : un rond vide et « ??? ».
func _fill_evolution(view: PokedexSheetView) -> void:
	_clear(_evolution)
	if view.evolution.is_empty():
		var none := Label.new()
		none.theme_type_variation = &"TeamCaption"
		none.text = NO_EVOLUTION_TEXT
		none.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_evolution.add_child(none)
		return
	for i: int in view.evolution.size():
		var stage := view.evolution[i]
		if i > 0:
			var same_column := view.evolution[i - 1].step == stage.step
			_evolution.add_child(_separator(BRANCH_SEPARATOR if same_column
				else STAGE_SEPARATOR))
		_evolution.add_child(_stage_node(stage))


func _separator(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"DexNumber"
	label.text = text
	label.custom_minimum_size.y = UiTokens.DEX_EVO_CIRCLE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _stage_node(stage: EvolutionStageView) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	var circle := Panel.new()
	circle.theme_type_variation = &"TeamEvoCircle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2.ONE * UiTokens.DEX_EVO_CIRCLE
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(circle)
	if stage.known:
		var path := SPRITE_PATH % stage.species_id
		if ResourceLoader.exists(path):
			var side := float(UiTokens.DEX_CELL_SPRITE_SOURCE * UiTokens.DEX_EVO_SPRITE_SCALE)
			var image := TextureRect.new()
			image.texture = load(path) as Texture2D
			image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image.size = Vector2.ONE * side
			image.position = (Vector2.ONE * UiTokens.DEX_EVO_CIRCLE - image.size) * 0.5
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


func _fill_notes(view: PokedexSheetView) -> void:
	_clear(_notes)
	if view.notes.is_empty():
		var empty := Label.new()
		empty.theme_type_variation = &"TeamCaption"
		empty.text = view.notes_empty_text
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_notes.add_child(empty)
		return
	for note: String in view.notes:
		var card := _section()
		var text := Label.new()
		text.theme_type_variation = &"BagDetailText"
		text.text = note
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.get_child(0).add_child(text)
		_notes.add_child(card)


func _build() -> void:
	var identity := HBoxContainer.new()
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	add_child(identity)
	var frame := Panel.new()
	frame.theme_type_variation = &"DexSpriteFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2.ONE * UiTokens.DEX_SPRITE_FRAME
	identity.add_child(frame)
	var side := float(UiTokens.DEX_CELL_SPRITE_SOURCE * UiTokens.DEX_SHEET_SPRITE_SCALE)
	_sprite = TextureRect.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.size = Vector2.ONE * side
	_sprite.position = (Vector2.ONE * UiTokens.DEX_SPRITE_FRAME - _sprite.size) * 0.5
	frame.add_child(_sprite)
	_ball = TextureRect.new()
	_ball.texture = BALL_ICON
	_ball.modulate = UiTokens.tinted(UiTokens.TEXT, BALL_PLACEHOLDER_ALPHA)
	_ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ball.size = Vector2.ONE * side * 0.6
	_ball.position = (Vector2.ONE * UiTokens.DEX_SPRITE_FRAME - _ball.size) * 0.5
	frame.add_child(_ball)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.add_theme_constant_override(&"separation", 0)
	identity.add_child(titles)
	_number = Label.new()
	_number.theme_type_variation = &"DexNumber"
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_number)
	_name = Label.new()
	_name.theme_type_variation = &"DexName"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(_name)
	_counts = Label.new()
	_counts.theme_type_variation = &"TeamCaption"
	_counts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_counts)
	_type_row = HBoxContainer.new()
	_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	titles.add_child(_type_row)

	var tab_row := HBoxContainer.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_row.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	add_child(tab_row)
	var group := ButtonGroup.new()
	for i: int in PokedexSheetView.TAB_LABELS.size():
		var button := Button.new()
		button.theme_type_variation = &"DexTab"
		button.text = PokedexSheetView.TAB_LABELS[i]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = UiTokens.DEX_TAB_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_pressed.bind(i as Tab))
		tab_row.add_child(button)
		_tabs.append(button)
	_tabs[Tab.OVERVIEW].set_pressed_no_signal(true)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(stack)
	_overview = VBoxContainer.new()
	_overview.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_habitat = VBoxContainer.new()
	_evolution = HFlowContainer.new()
	_evolution.add_theme_constant_override(&"h_separation", UiTokens.DEX_GAP)
	_evolution.add_theme_constant_override(&"v_separation", UiTokens.DEX_GAP)
	_notes = VBoxContainer.new()
	_notes.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_pages = [_overview, _habitat, _evolution, _notes]
	for page: Control in _pages:
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.visible = false
		stack.add_child(page)
	_overview.visible = true


## Un encadré discret avec marge ; le conteneur intérieur est son premier enfant.
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


func _clear(container: Node) -> void:
	for old: Node in container.get_children():
		container.remove_child(old)
		old.queue_free()
