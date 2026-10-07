class_name ZoneStrip
extends HBoxContainer
## Bandeau du bas de l'écran Carte (MM.2, maquette menu-carte-v1.jpg pour la DA seulement) : la
## carte « Exploration de Kanto » (« N zones découvertes », **jamais de total** : dossier 08
## règle 2) et la frise des zones **découvertes**, dans l'ordre du voyage (vignette de leur carte
## peinte, nom ; lieu courant marqué d'une épingle, zone du panneau cerclée d'ACCENT).
##
## Il reçoit un [MapView] et n'en sait rien d'autre. Une vignette touchée : **un**
## [signal zone_chosen] (le directeur ouvre le panneau). La frise défile à l'horizontale ; un
## glissement ne choisit rien (TapGuard).

## Une vignette (zone découverte) est touchée.
signal zone_chosen(zone: StringName)

## Textes (MM.2, à relire par Kevin).
const EXPLORE_TITLE := "Exploration de Kanto"
const ZONES_ONE := "%d zone découverte"
const ZONES_MANY := "%d zones découvertes"
const PIN_ICON: Texture2D = preload("res://assets/ui/icons/menu/map.svg")

var _explore_text: Label
var _scroll: ScrollContainer
var _row: HBoxContainer
var _thumbs: Dictionary[StringName, Button] = {}
var _rims: Dictionary[StringName, Panel] = {}
var _selected: StringName = &""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = UiTokens.MAP_STRIP_HEIGHT
	add_theme_constant_override(&"separation", UiTokens.MAP_GAP)
	_build_explore()
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MapStrip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.scroll_deadzone = roundi(UiTokens.TAP_SLOP)
	panel.add_child(_scroll)
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override(&"separation", UiTokens.MAP_THUMB_GAP)
	_scroll.add_child(_row)


## Pose [param view] : compteur et vignettes (refaites). [param illustration] : l'illustration
## de Kanto, recadrée pour une zone sans aperçu peint.
func setup(view: MapView, illustration: Texture2D) -> void:
	var count := view.zones.size()
	_explore_text.text = (ZONES_ONE if count == 1 else ZONES_MANY) % count
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_thumbs.clear()
	_rims.clear()
	for zone: MapZoneView in view.zones:
		var thumb := _thumb(zone, illustration)
		_row.add_child(thumb)
		_thumbs[zone.zone_id] = thumb
	_apply_selection()


## Zone du panneau : sa vignette est cerclée d'ACCENT et ramenée dans la frise.
func set_selected(zone_id: StringName) -> void:
	_selected = zone_id
	_apply_selection()
	var thumb: Button = _thumbs.get(zone_id, null)
	if thumb != null and is_inside_tree():
		_scroll.ensure_control_visible.call_deferred(thumb)


func get_selected() -> StringName:
	return _selected


## Vignettes, par zone (seulement des zones découvertes).
func get_thumbs() -> Dictionary[StringName, Button]:
	return _thumbs


## « 2 zones découvertes ».
func get_count_text() -> String:
	return _explore_text.text


func get_scroll() -> ScrollContainer:
	return _scroll


func _build_explore() -> void:
	var card := PanelContainer.new()
	card.theme_type_variation = &"MapStrip"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size.x = UiTokens.MAP_EXPLORE_WIDTH
	add_child(card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", UiTokens.GAP)
	card.add_child(row)
	var round := Panel.new()
	round.theme_type_variation = &"MapPortrait"
	round.mouse_filter = Control.MOUSE_FILTER_IGNORE
	round.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	round.custom_minimum_size = Vector2.ONE * UiTokens.MAP_EXPLORE_ROUND
	round.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(round)
	var art := TextureRect.new()
	art.texture = MenuArt.card_illustration(MenuRoute.MAP)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	round.add_child(art)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override(&"separation", 2)
	row.add_child(texts)
	var title := Label.new()
	title.theme_type_variation = &"MapExploreTitle"
	title.text = EXPLORE_TITLE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	texts.add_child(title)
	_explore_text = Label.new()
	_explore_text.theme_type_variation = &"MapExploreText"
	_explore_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_explore_text)


func _thumb(zone: MapZoneView, illustration: Texture2D) -> Button:
	var thumb := Button.new()
	thumb.theme_type_variation = &"MapThumb"
	thumb.focus_mode = Control.FOCUS_NONE
	thumb.custom_minimum_size = Vector2(UiTokens.MAP_THUMB_WIDTH, UiTokens.TOUCH_MIN)
	# Dans un défilement : le glissement du doigt doit atteindre le ScrollContainer.
	thumb.mouse_filter = Control.MOUSE_FILTER_PASS
	TapGuard.attach(thumb)
	thumb.pressed.connect(_on_thumb_pressed.bind(zone.zone_id))
	var art := ZoneArt.new()
	art.set_style(float(UiTokens.MAP_THUMB_RADIUS), UiTokens.MAP_THUMB_FADE_FROM,
		UiTokens.tinted(UiTokens.SURFACE_DARK, 0.9))
	art.show_zone(zone.zone_id, illustration, zone.area)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.add_child(art)
	var name_label := Label.new()
	name_label.theme_type_variation = &"MapThumbName"
	name_label.text = zone.name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = 8
	name_label.offset_right = -8
	name_label.offset_bottom = -8
	thumb.add_child(name_label)
	if zone.current:
		var pin := TextureRect.new()
		pin.texture = PIN_ICON
		pin.modulate = UiTokens.ACCENT
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pin.size = Vector2.ONE * UiTokens.MAP_THUMB_PIN
		pin.position = Vector2(10, 10)
		thumb.add_child(pin)
	var rim := Panel.new()
	rim.theme_type_variation = &"MapThumbRim"
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.add_child(rim)
	_rims[zone.zone_id] = rim
	return thumb


func _apply_selection() -> void:
	for zone_id: StringName in _rims:
		_rims[zone_id].theme_type_variation = &"MapThumbRimOn" if zone_id == _selected \
			else &"MapThumbRim"


func _on_thumb_pressed(zone: StringName) -> void:
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	zone_chosen.emit(zone)
