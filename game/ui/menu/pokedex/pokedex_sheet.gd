class_name PokedexSheet
extends VBoxContainer
## Panneau de droite du Pokédex (dossier 08 §4 ; refonte T3) : quatre onglets, Aperçu · Habitat ·
## Évolution · Observations. L'identité (numéro, nom, portrait, cartes Vu / Capturé, description)
## est dans la colonne centrale ([PokedexPortrait]). Il ne connaît qu'un [PokedexSheetView].
##
## Anti-spoiler (règle 10, Q-9) : **seulement ce que le joueur a découvert**. Une espèce
## seulement vue n'a ni types, ni taille, ni poids (absents, pas de cases vides « ??? »). Jamais
## de statistiques de base, de talents, de condition d'évolution, ni de zone non découverte.
## - Aperçu : types, taille et poids (à la capture), aperçu Habitat (petite carte, « Zones
##   observées : N », un toucher ouvre l'onglet Habitat) et aperçu Évolution (ronds + noms).
## - Habitat : une petite carte (les zones observées seules) et une pastille par zone ; la
##   toucher émet **un** [signal route_requested] vers la Carte.
## - Évolution : vignettes de l'atlas ; un stade pas encore vu en **silhouette** (nom « ??? »),
##   un rond vide quand le stade ne désigne pas une seule espèce.
## - L'onglet ouvert reste ouvert quand on change d'espèce.

## Zone d'habitat touchée : lien croisé vers la Carte (MenuRoute.map).
signal route_requested(route: MenuRoute)
## Un onglet est choisi (rang dans [constant PokedexSheetView.TAB_LABELS]).
signal tab_changed(tab: int)

enum Tab { OVERVIEW, HABITAT, EVOLUTION, NOTES }

const SIZE_CAPTION := "Taille"
const WEIGHT_CAPTION := "Poids"
const TYPES_CAPTION := "Types"
const HABITAT_TITLE := "Habitat"
const EVOLUTION_TITLE := "Évolution"
const NO_EVOLUTION_TEXT := "Pas d'évolution."
const STAGE_SEPARATOR := "→"
const PREVIEW_ARROW := "»"
const BRANCH_SEPARATOR := "/"
const BADGE_SCENE: PackedScene = preload("res://game/ui/components/type_badge.tscn")
const PIN_ICON: Texture2D = preload("res://assets/ui/icons/pokedex/pin.svg")
const CHEVRON_ICON: Texture2D = preload("res://assets/ui/icons/menu/chevron.svg")

var _view: PokedexSheetView
var _tab: Tab = Tab.OVERVIEW
var _tabs: Array[Button] = []
var _pages: Array[Control] = []
var _type_row: HBoxContainer
var _overview: VBoxContainer
var _habitat: VBoxContainer
var _evolution: HFlowContainer
var _notes: VBoxContainer
var _map: PokedexHabitatMap
var _preview_map: PokedexHabitatMap
var _habitat_preview: Button
var _chips: Array[Button] = []
var _evolution_images: Array[TextureRect] = []
var _evolution_circles: Array[Panel] = []
var _preview_circles: Array[Panel] = []
var _scroll: ScrollContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	_build()


## Pose [param view] sur les quatre pages ; l'onglet ouvert reste ouvert.
func show_sheet(view: PokedexSheetView) -> void:
	_view = view
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


## Rangée des types de la carte « Types » de l'Aperçu (vide pour une espèce seulement vue).
func get_type_row() -> HBoxContainer:
	return _type_row


func get_map() -> PokedexHabitatMap:
	return _map


## Petite carte de l'aperçu d'Habitat de l'Aperçu (null si l'espèce n'a aucune zone).
func get_preview_map() -> PokedexHabitatMap:
	return _preview_map


## Carte tactile de l'aperçu d'Habitat (null si absente).
func get_habitat_preview() -> Button:
	return _habitat_preview


## Pastilles de zone de l'onglet Habitat.
func get_chips() -> Array[Button]:
	return _chips


## Ronds de la page Évolution et de l'aperçu de l'Aperçu.
func get_evolution_circles() -> Array[Panel]:
	return _evolution_circles


func get_preview_circles() -> Array[Panel]:
	return _preview_circles


## Vignettes posées dans les ronds de la page Évolution (un rond vide n'en a pas). Celle d'un
## stade inconnu porte le matériau de silhouette.
func get_evolution_images() -> Array[TextureRect]:
	return _evolution_images


func get_scroll() -> ScrollContainer:
	return _scroll


## Tous les textes visibles d'une page, ou de tout le panneau si [param tab] vaut -1.
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


## Aperçu : à la capture, types, taille et poids ; puis les aperçus d'Habitat et d'Évolution.
func _fill_overview(view: PokedexSheetView) -> void:
	_clear(_overview)
	_preview_map = null
	_habitat_preview = null
	_preview_circles.clear()
	_type_row = HBoxContainer.new()
	_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_row.add_theme_constant_override(&"separation", UiTokens.TYPE_BADGE_GAP)
	for i: int in view.type_ids.size():
		var badge := BADGE_SCENE.instantiate() as TypeBadge
		_type_row.add_child(badge)
		badge.set_type(view.type_ids[i], view.type_names[i])
	var facts := HBoxContainer.new()
	facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	facts.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	if not view.type_ids.is_empty():
		facts.add_child(_fact_card(TYPES_CAPTION, _type_row))
	else:
		_type_row.visible = false
		_overview.add_child(_type_row)
	if not view.height_text.is_empty():
		facts.add_child(_fact(SIZE_CAPTION, view.height_text))
	if not view.weight_text.is_empty():
		facts.add_child(_fact(WEIGHT_CAPTION, view.weight_text))
	if facts.get_child_count() > 0:
		_overview.add_child(facts)
	else:
		facts.queue_free()
	if not view.habitats.is_empty():
		_overview.add_child(_habitat_preview_card(view))
	if not view.evolution.is_empty():
		_overview.add_child(_evolution_preview(view))


func _fact(caption: String, value: String) -> PanelContainer:
	var val := Label.new()
	val.theme_type_variation = &"TeamValue"
	val.add_theme_font_size_override(&"font_size", UiTokens.DEX_INFO_FONT)
	val.text = value
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return _fact_card(caption, val)


func _fact_card(caption: String, content: Control) -> PanelContainer:
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
	box.add_child(content)
	return card


## Carte de l'aperçu d'Habitat : titre, petite carte, « Zones observées : N » et un chevron ;
## un toucher ouvre l'onglet Habitat (jamais la Carte directement).
func _habitat_preview_card(view: PokedexSheetView) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"DexPreviewCard"
	button.focus_mode = Control.FOCUS_NONE
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size.y = UiTokens.DEX_LAYOUT_MAP_PREVIEW_HEIGHT \
		+ 2 * UiTokens.GAP + 2 * UiTokens.DEX_SHEET_GAP + 2 * UiTokens.DEX_LAYOUT_PREVIEW_ROW
	TapGuard.attach(button)
	button.pressed.connect(_on_habitat_preview_pressed)
	_habitat_preview = button
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	button.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE,
		UiTokens.GAP)
	var title := Label.new()
	title.theme_type_variation = &"DexPreviewTitle"
	title.text = HABITAT_TITLE
	title.custom_minimum_size.y = UiTokens.DEX_LAYOUT_PREVIEW_ROW
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	_preview_map = PokedexHabitatMap.new()
	_preview_map.custom_minimum_size = Vector2(0.0, UiTokens.DEX_LAYOUT_MAP_PREVIEW_HEIGHT)
	_preview_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var zone_ids: Array[StringName] = []
	for habitat: PokedexHabitatView in view.habitats:
		zone_ids.append(habitat.zone_id)
	_preview_map.set_zones(zone_ids)
	box.add_child(_preview_map)
	var footer := HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	footer.custom_minimum_size.y = UiTokens.DEX_LAYOUT_PREVIEW_ROW
	box.add_child(footer)
	footer.add_child(_icon(PIN_ICON))
	var count := Label.new()
	count.theme_type_variation = &"DexCardValue"
	count.text = view.habitat_count_text
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(count)
	footer.add_child(_icon(CHEVRON_ICON))
	return button


func _icon(texture: Texture2D) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2.ONE * UiTokens.DEX_LAYOUT_PREVIEW_ICON
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return image


func _on_habitat_preview_pressed() -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	_show_tab(Tab.HABITAT)
	tab_changed.emit(int(Tab.HABITAT))


## Aperçu d'Évolution : les stades en petits ronds, noms dessous, « » » entre les colonnes.
func _evolution_preview(view: PokedexSheetView) -> PanelContainer:
	var title := Label.new()
	title.theme_type_variation = &"DexPreviewTitle"
	title.text = EVOLUTION_TITLE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HFlowContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"h_separation", UiTokens.DEX_SHEET_GAP)
	row.add_theme_constant_override(&"v_separation", UiTokens.DEX_SHEET_GAP)
	for i: int in view.evolution.size():
		var stage := view.evolution[i]
		if i > 0:
			var same_column := view.evolution[i - 1].step == stage.step
			row.add_child(_separator(BRANCH_SEPARATOR if same_column else PREVIEW_ARROW,
				UiTokens.DEX_LAYOUT_EVO_PREVIEW))
		row.add_child(_stage_node(stage, UiTokens.DEX_LAYOUT_EVO_PREVIEW, _preview_circles))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	box.add_child(title)
	box.add_child(row)
	var card := _section()
	card.get_child(0).add_child(box)
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
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.DEX_GAP)
	_habitat.add_child(column)
	_map = PokedexHabitatMap.new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_map)
	var zone_ids: Array[StringName] = []
	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	column.add_child(list)
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


## Évolution : un rond (vignette de l'atlas sur un halo) et un nom par stade, « → » entre les
## colonnes, « / » entre les branches. Stade inconnu : sa silhouette (Q-1) et « ??? » ; rond
## vide quand le stade ne désigne pas une seule espèce. Jamais de condition.
func _fill_evolution(view: PokedexSheetView) -> void:
	_clear(_evolution)
	_evolution_images.clear()
	_evolution_circles.clear()
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
				else STAGE_SEPARATOR, UiTokens.DEX_EVO_CIRCLE))
		_evolution.add_child(_stage_node(stage, UiTokens.DEX_EVO_CIRCLE, _evolution_circles,
			_evolution_images))


func _separator(text: String, height: int) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"DexNumber"
	label.text = text
	label.custom_minimum_size.y = height
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Un stade : un rond (halo + vignette) et son nom. [param images] reçoit la vignette.
func _stage_node(stage: EvolutionStageView, diameter: int, circles: Array[Panel],
		images: Array[TextureRect] = []) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	var circle := Panel.new()
	circle.theme_type_variation = &"TeamEvoCircle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2.ONE * diameter
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(circle)
	circles.append(circle)
	if stage.number > 0:
		var halo := TextureRect.new()
		halo.texture = PokedexArt.halo_texture()
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		halo.stretch_mode = TextureRect.STRETCH_SCALE
		halo.size = Vector2.ONE * diameter
		if not stage.known:
			halo.modulate.a = UiTokens.DEX_HALO_UNKNOWN_ALPHA
		circle.add_child(halo)
		var image := TextureRect.new()
		image.texture = PokedexArt.thumbnail(stage.number)
		if not stage.known:
			image.material = PokedexArt.silhouette_material()
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.size = Vector2.ONE * (diameter * UiTokens.DEX_LAYOUT_EVO_IMAGE_RATIO)
		image.position = (Vector2.ONE * diameter - image.size) * 0.5
		circle.add_child(image)
		images.append(image)
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
	var tab_row := HBoxContainer.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_row.add_theme_constant_override(&"separation", UiTokens.DEX_SHEET_GAP)
	add_child(tab_row)
	var group := ButtonGroup.new()
	for i: int in PokedexSheetView.TAB_LABELS.size():
		var button := Button.new()
		button.theme_type_variation = &"DexSheetTab"
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
