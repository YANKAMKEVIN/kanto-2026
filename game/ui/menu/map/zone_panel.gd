class_name ZonePanel
extends PanelContainer
## Panneau latéral d'une zone découverte de l'écran Carte (dossier 08 §5 ; jalon-06.md §6.10) :
## nom, sous-titre, description, puis les trois sections **seulement si leur liste n'est pas
## vide** (titre compris) : Pokémon observés (toucher → fiche du Pokédex), objets trouvés,
## services. Aucun bouton d'action, aucun total, aucun « ??? ».
##
## Il reçoit un [ZonePanelView] et n'en sait rien d'autre. Le contenu est refait à chaque
## [method show_zone] (les anciens nœuds sont retirés tout de suite, puis libérés).

## Un Pokémon observé touché : un seul lien vers sa fiche du Pokédex.
signal route_requested(route: MenuRoute)

const SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"

var speed_scale: float = 1.0

var _view: ZonePanelView
var _scroll: ScrollContainer
var _column: VBoxContainer
var _entries: Array[Button] = []
var _tween: Tween


func _init() -> void:
	theme_type_variation = &"MapPanel"
	custom_minimum_size.x = UiTokens.MAP_PANEL_WIDTH
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override(&"separation", UiTokens.MAP_PANEL_GAP)
	_scroll.add_child(_column)


## Affiche [param view]. Un fondu court quand la zone change (ou que le panneau apparaît) ;
## rappelé pour la même zone (nouvel objet), il met à jour sans rejouer l'animation.
func show_zone(view: ZonePanelView) -> void:
	var changed := _view == null or _view.zone_id != view.zone_id or not visible
	_view = view
	_rebuild(view)
	visible = true
	_scroll.scroll_vertical = 0
	if changed:
		_play_fade()


func get_view() -> ZonePanelView:
	return _view


func get_scroll() -> ScrollContainer:
	return _scroll


## Cellules des Pokémon observés (boutons tactiles), dans l'ordre.
func get_pokemon_entries() -> Array[Button]:
	return _entries


## Tous les textes affichés par le panneau, dans l'ordre de l'arbre.
func get_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect_texts(_column, texts)
	return texts


func _rebuild(view: ZonePanelView) -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_entries.clear()
	_add_label(view.name, &"MapName")
	_add_label(view.subtitle, &"MapSubtitle")
	_add_label(view.description, &"MapText")
	if not view.pokemon.is_empty():
		_add_label(ZonePanelView.POKEMON_TITLE, &"MapSection")
		var flow := _flow(UiTokens.MAP_ENTRY_GAP)
		for entry: ZoneEntryView in view.pokemon:
			var cell := _pokemon_cell(entry)
			flow.add_child(cell)
			_entries.append(cell)
	if not view.items.is_empty():
		_add_label(ZonePanelView.ITEMS_TITLE, &"MapSection")
		var flow := _flow(UiTokens.MAP_ENTRY_GAP)
		for entry: ZoneEntryView in view.items:
			flow.add_child(_chip(entry, BagEntryView.icon_for(entry.id)))
	if not view.services.is_empty():
		_add_label(ZonePanelView.SERVICES_TITLE, &"MapSection")
		var flow := _flow(UiTokens.MAP_ENTRY_GAP)
		for entry: ZoneEntryView in view.services:
			flow.add_child(_chip(entry, null))


## Un texte ; vide : rien (« texte vide = élément absent »).
func _add_label(text: String, variation: StringName) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(label)


func _flow(gap: int) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override(&"h_separation", gap)
	flow.add_theme_constant_override(&"v_separation", gap)
	_column.add_child(flow)
	return flow


## Un Pokémon observé : sprite en pixel art à l'échelle entière (sprite absent : le nom seul,
## jamais une silhouette) et nom ; toucher → sa fiche du Pokédex.
func _pokemon_cell(entry: ZoneEntryView) -> Button:
	var cell := Button.new()
	cell.theme_type_variation = &"MapEntry"
	cell.focus_mode = Control.FOCUS_NONE
	cell.custom_minimum_size = UiTokens.MAP_ENTRY_SIZE
	cell.pressed.connect(_on_pokemon_pressed.bind(entry.id))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 0)
	cell.add_child(box)
	var path := SPRITE_PATH % entry.id
	if ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = load(path) as Texture2D
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var side := float(UiTokens.MAP_ENTRY_SPRITE_SOURCE * UiTokens.MAP_ENTRY_SPRITE_SCALE)
		art.custom_minimum_size = Vector2(side, side)
		box.add_child(art)
	var name_label := Label.new()
	name_label.theme_type_variation = &"MapEntryText"
	name_label.text = entry.name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	return cell


## Un objet trouvé (icône, nom, « ×2 ») ou un service (nom seul).
func _chip(entry: ZoneEntryView, icon: Texture2D) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"MapChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	chip.add_child(row)
	if icon != null:
		var art := TextureRect.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = icon
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2.ONE * UiTokens.MAP_CHIP_ICON
		row.add_child(art)
	var name_label := Label.new()
	name_label.theme_type_variation = &"MapEntryText"
	name_label.text = entry.name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var count := entry.count_text()
	if not count.is_empty():
		var count_label := Label.new()
		count_label.theme_type_variation = &"MapSubtitle"
		count_label.text = count
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(count_label)
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
