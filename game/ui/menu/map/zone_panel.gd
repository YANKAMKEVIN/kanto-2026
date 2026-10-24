class_name ZonePanel
extends PanelContainer
## Panneau latéral d'une zone découverte de l'écran Carte (dossier 08 §5 ; jalon-06.md §6.10 ;
## MM.2, maquette) : grande image de la zone (aperçu peint flouté, ou recadrage de l'illustration)
## avec son nom et son sous-titre (connexions) écrits dessus et « Tu es ici » pour le lieu
## courant, description, puis
## les trois sections **seulement si leur liste n'est pas vide** (titre compris) : Pokémon
## observés (artworks officiels ; toucher → fiche du Pokédex), objets trouvés (icônes peintes),
## services. Aucun bouton d'action, aucun total, aucun « ??? », jamais de silhouette.
##
## Il reçoit un [ZonePanelView] et n'en sait rien d'autre. Le contenu est refait à chaque
## [method show_zone] (les anciens nœuds sont retirés tout de suite, puis libérés).

## Un Pokémon observé touché : un seul lien vers sa fiche du Pokédex.
signal route_requested(route: MenuRoute)
## Passe systèmes 2 (§2.8, T24) : « S'ENVOLER » touché pour la zone affichée.
signal fly_requested(zone: StringName)

const FLY_TEXT := "S'ENVOLER"

## « Tu es ici » sur l'image du lieu courant (MM.2, texte à relire par Kevin).
const HERE_TEXT := "Tu es ici"
const PIN_ICON: Texture2D = preload("res://assets/ui/icons/menu/map.svg")

var speed_scale: float = 1.0

var _view: ZonePanelView
var _scroll: ScrollContainer
var _column: VBoxContainer
var _hero_art: ZoneArt
var _entries: Array[Button] = []
var _tween: Tween


func _init() -> void:
	theme_type_variation = &"MapPanel"
	custom_minimum_size.x = UiTokens.MAP_PANEL_MIN
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	add_child(_scroll)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override(&"separation", UiTokens.MAP_PANEL_GAP)
	_scroll.add_child(_column)


## Affiche [param view]. Un fondu court quand la zone change (ou que le panneau apparaît) ;
## rappelé pour la même zone (nouvel objet), il met à jour sans rejouer l'animation.
## [param illustration] et [param area] : l'illustration de Kanto et le rectangle de la zone,
## recadrés quand la zone n'a pas d'aperçu peint.
func show_zone(view: ZonePanelView, illustration: Texture2D = null,
		area: Rect2 = Rect2()) -> void:
	var changed := _view == null or _view.zone_id != view.zone_id or not visible
	_view = view
	_rebuild(view, illustration, area)
	visible = true
	_scroll.scroll_vertical = 0
	if changed:
		_play_fade()


func get_view() -> ZonePanelView:
	return _view


func get_scroll() -> ScrollContainer:
	return _scroll


## Image de la zone en tête du panneau.
func get_hero_art() -> ZoneArt:
	return _hero_art


## Cellules des Pokémon observés (boutons tactiles), dans l'ordre.
func get_pokemon_entries() -> Array[Button]:
	return _entries


## Tous les textes affichés par le panneau, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(_column, texts)
	return texts


func _rebuild(view: ZonePanelView, illustration: Texture2D, area: Rect2) -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_entries.clear()
	_build_hero(view, illustration, area)
	_add_label(_column, view.description, &"MapText")
	if not view.pokemon.is_empty():
		var flow := _section(ZonePanelView.POKEMON_TITLE)
		for entry: ZoneEntryView in view.pokemon:
			var cell := _pokemon_cell(entry)
			flow.add_child(cell)
			_entries.append(cell)
	if not view.items.is_empty():
		var flow := _section(ZonePanelView.ITEMS_TITLE)
		for entry: ZoneEntryView in view.items:
			flow.add_child(_item_cell(entry))
	if not view.services.is_empty():
		var flow := _section(ZonePanelView.SERVICES_TITLE)
		for entry: ZoneEntryView in view.services:
			flow.add_child(_service_chip(entry))
	if view.fly_available:
		_column.add_child(_fly_button(view.zone_id))


## Grande image, nom écrit dessus en bas à gauche, « Tu es ici » en haut à gauche.
func _build_hero(view: ZonePanelView, illustration: Texture2D, area: Rect2) -> void:
	var hero := PanelContainer.new()
	hero.theme_type_variation = &"MapHero"
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.custom_minimum_size.y = UiTokens.MAP_HERO_HEIGHT
	_column.add_child(hero)
	_hero_art = ZoneArt.new()
	_hero_art.set_style(float(UiTokens.MAP_HERO_RADIUS), UiTokens.MAP_HERO_FADE_FROM,
		UiTokens.tinted(UiTokens.SURFACE_DARK, 0.92))
	_hero_art.show_zone(view.zone_id, illustration, area)
	hero.add_child(_hero_art)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, UiTokens.MAP_HERO_PAD)
	hero.add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	if view.current:
		var here := PanelContainer.new()
		here.theme_type_variation = &"MapHere"
		here.mouse_filter = Control.MOUSE_FILTER_IGNORE
		here.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		stack.add_child(here)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override(&"separation", UiTokens.MAP_LABEL_GAP)
		here.add_child(row)
		var pin := TextureRect.new()
		pin.texture = PIN_ICON
		pin.modulate = UiTokens.ACCENT_TEXT
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pin.custom_minimum_size = Vector2.ONE * UiTokens.MAP_HERE_ICON
		pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pin)
		_add_label(row, HERE_TEXT, &"MapHereText").autowrap_mode = TextServer.AUTOWRAP_OFF
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)
	var name_label := _add_label(stack, view.name, &"MapHeroName")
	if name_label != null:
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add_label(stack, view.subtitle, &"MapHeroSubtitle")


## Carte de section (titre puis cellules) ; renvoie le conteneur des cellules.
func _section(title: String) -> HFlowContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"MapSectionCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(card)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", UiTokens.MAP_SECTION_GAP)
	card.add_child(box)
	_add_label(box, title, &"MapSection")
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override(&"h_separation", UiTokens.MAP_ENTRY_GAP)
	flow.add_theme_constant_override(&"v_separation", UiTokens.MAP_ENTRY_GAP)
	box.add_child(flow)
	return flow


## Un texte ; vide : rien (« texte vide = élément absent »).
func _add_label(parent: Control, text: String, variation: StringName) -> Label:
	if text.is_empty():
		return null
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


## Un Pokémon observé : artwork officiel dans un rond (numéro inconnu : le nom seul, jamais une
## silhouette) et nom ; toucher → sa fiche du Pokédex.
func _pokemon_cell(entry: ZoneEntryView) -> Button:
	var cell := Button.new()
	cell.theme_type_variation = &"MapEntry"
	cell.focus_mode = Control.FOCUS_NONE
	cell.custom_minimum_size = UiTokens.MAP_POKEMON_CELL
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	TapGuard.attach(cell)
	cell.pressed.connect(_on_pokemon_pressed.bind(entry.id))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 4)
	cell.add_child(box)
	var art := MenuArt.pokemon_thumbnail(entry.dex_number)
	if art != null:
		var round := Panel.new()
		round.theme_type_variation = &"MenuRoundThumb"
		round.mouse_filter = Control.MOUSE_FILTER_IGNORE
		round.custom_minimum_size = Vector2.ONE * UiTokens.MAP_POKEMON_ROUND
		round.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(round)
		var picture := TextureRect.new()
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.texture = art
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		round.add_child(picture)
	var name_label := Label.new()
	name_label.theme_type_variation = &"MapEntryText"
	name_label.text = entry.name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	return cell


## Un objet trouvé : icône peinte (sinon l'icône du Sac), nom, « ×2 ».
func _item_cell(entry: ZoneEntryView) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.theme_type_variation = &"MapItemCell"
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.custom_minimum_size = UiTokens.MAP_ITEM_CELL
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 4)
	cell.add_child(box)
	var icon := MenuArt.item_icon(entry.id)
	if icon == null:
		icon = BagEntryView.icon_for(entry.id)
	if icon != null:
		var art := TextureRect.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = icon
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2.ONE * UiTokens.MAP_ITEM_ICON
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(art)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 6)
	box.add_child(row)
	for label: Label in [_add_label(row, entry.name, &"MapEntryText"),
			_add_label(row, entry.count_text(), &"MapSubtitle")]:
		if label != null:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return cell


## Un service découvert (nom seul).
func _service_chip(entry: ZoneEntryView) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"MapChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Une ligne : dans la rangée qui coule, un libellé qui passe à la ligne tombait à une largeur
	# nulle et s'écrivait lettre par lettre (QA S2E sur S21, « Centre » d'Argenta).
	var label := _add_label(chip, entry.name, &"MapEntryText")
	if label != null:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return chip


func _collect_texts(node: Node, into: PackedStringArray) -> void:
	for child: Node in node.get_children():
		var label := child as Label
		if label != null and not label.text.is_empty():
			into.append(label.text)
		_collect_texts(child, into)


func _play_fade() -> void:
	_kill_tween()
	modulate.a = 1.0
	var time := UiTokens.MAP_FADE * speed_scale
	if time <= 0.0 or not is_inside_tree():
		return
	modulate.a = 0.0
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"modulate:a", 1.0, time)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _on_pokemon_pressed(species: StringName) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	route_requested.emit(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, species))


## Bouton « S'ENVOLER » (T24) : une seule intention, le directeur décide.
func _fly_button(zone: StringName) -> Button:
	var button := Button.new()
	button.name = "FlyButton"
	button.theme_type_variation = &"AccentButton"
	button.text = FLY_TEXT
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = UiTokens.TOUCH_MIN
	button.pressed.connect(func() -> void: fly_requested.emit(zone))
	return button


## Bouton « S'ENVOLER » affiché, ou null (tests).
func get_fly_button() -> Button:
	return _column.get_node_or_null(^"FlyButton") as Button
