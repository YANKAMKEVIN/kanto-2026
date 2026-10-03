class_name MapCanvas
extends Control
## L'illustration de Kanto de l'écran Carte (dossier 08 §5 ; jalon-06.md §6.10) : l'image
## entière (rapport gardé, filtre linéaire : c'est un décor HD), le nom discret des zones
## **découvertes**, le portrait du joueur et le halo de la zone du panneau. Aucune zone non
## découverte n'a d'étiquette ni de toucher : la géographie seule la montre (Q-15).
##
## Zone de toucher d'une zone découverte : son rectangle mis à l'échelle, **agrandi autour de
## son centre jusqu'à TOUCH_MIN** de côté au moins. Règle des recouvrements (la plus simple) :
## un point dans le vrai rectangle d'une zone est toujours à elle ; sinon, parmi les zones dont
## la zone agrandie contient le point, la plus proche par le centre. Ainsi les zones agrandies
## ne volent jamais le toucher d'une zone voisine posé sur son propre rectangle.
## Un toucher = un seul [signal zone_pressed], au relâchement, si le doigt est resté sur la
## zone où il s'était posé.

signal zone_pressed(zone: StringName)

const PORTRAIT: Texture2D = preload("res://assets/ui/map/player_portrait.png")

var _view: MapView
var _texture: Texture2D
var _selected: StringName = &""
var _pressed_zone: StringName = &""
var _labels: Dictionary[StringName, PanelContainer] = {}
var _label_texts: Dictionary[StringName, Label] = {}
var _portrait: TextureRect
var _highlight: StyleBoxFlat


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true
	_portrait = TextureRect.new()
	_portrait.texture = PORTRAIT
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.visible = false
	add_child(_portrait)
	_highlight = StyleBoxFlat.new()
	_highlight.bg_color = UiTokens.tinted(UiTokens.ACCENT, UiTokens.MAP_HIGHLIGHT_FILL)
	_highlight.border_color = UiTokens.ACCENT
	_highlight.set_border_width_all(int(UiTokens.MAP_HIGHLIGHT_BORDER))
	_highlight.set_corner_radius_all(int(UiTokens.MAP_HIGHLIGHT_RADIUS))
	_highlight.anti_aliasing = true
	resized.connect(_layout)


## Pose la vue : image, zones découvertes (étiquettes), portrait. Les étiquettes sont refaites.
func setup(view: MapView) -> void:
	_view = view
	_texture = null
	if not view.image_path.is_empty() and ResourceLoader.exists(view.image_path):
		_texture = load(view.image_path) as Texture2D
	for label: PanelContainer in _labels.values():
		remove_child(label)
		label.queue_free()
	_labels.clear()
	_label_texts.clear()
	for zone: MapZoneView in view.zones:
		if not zone.is_touchable():
			continue
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.modulate.a = UiTokens.MAP_LABEL_ALPHA
		var text := Label.new()
		text.text = zone.name
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(text)
		add_child(pill)
		_labels[zone.zone_id] = pill
		_label_texts[zone.zone_id] = text
	var player := view.zone(view.player_zone)
	_portrait.visible = player != null and player.is_touchable()
	_apply_selection_style()
	_layout()
	queue_redraw()


## Zone du panneau : halo sur l'illustration et étiquette en ACCENT (&"" : aucune).
func set_selected(zone_id: StringName) -> void:
	if zone_id == _selected:
		return
	_selected = zone_id
	_apply_selection_style()
	_layout()
	queue_redraw()


func get_selected() -> StringName:
	return _selected


## Échelle de l'image dans le contrôle (image entière, rapport gardé).
func get_image_scale() -> float:
	if _view == null or _view.image_size.x <= 0 or _view.image_size.y <= 0:
		return 1.0
	return minf(size.x / _view.image_size.x, size.y / _view.image_size.y)


## Rectangle de l'image dans le contrôle.
func get_image_rect() -> Rect2:
	if _view == null:
		return Rect2()
	var shown := Vector2(_view.image_size) * get_image_scale()
	return Rect2((size - shown) * 0.5, shown)


## Point de l'image (en pixels de l'image) dans le repère du contrôle.
func image_to_local(point: Vector2) -> Vector2:
	return get_image_rect().position + point * get_image_scale()


## Rectangle de [param zone_id] dans le repère du contrôle (vide : zone absente de la vue).
func zone_rect(zone_id: StringName) -> Rect2:
	var zone := _view.zone(zone_id) if _view != null else null
	if zone == null or not zone.is_touchable():
		return Rect2()
	return Rect2(image_to_local(zone.area.position), zone.area.size * get_image_scale())


## Zone de toucher de [param zone_id] : son rectangle agrandi jusqu'à TOUCH_MIN au moins.
func touch_rect(zone_id: StringName) -> Rect2:
	var rect := zone_rect(zone_id)
	if not rect.has_area():
		return rect
	return _grown(rect, float(UiTokens.TOUCH_MIN))


## La zone **découverte** touchée en [param point] (repère du contrôle), &"" si aucune.
func zone_at(point: Vector2) -> StringName:
	if _view == null:
		return &""
	for zone: MapZoneView in _view.zones:
		if zone_rect(zone.zone_id).has_point(point):
			return zone.zone_id
	var best: StringName = &""
	var best_distance := INF
	for zone: MapZoneView in _view.zones:
		if not touch_rect(zone.zone_id).has_point(point):
			continue
		var distance := zone_rect(zone.zone_id).get_center().distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best = zone.zone_id
	return best


## Étiquettes affichées : zone → texte (jamais une zone non découverte).
func get_label_texts() -> Dictionary[StringName, String]:
	var texts: Dictionary[StringName, String] = {}
	for zone_id: StringName in _label_texts:
		texts[zone_id] = _label_texts[zone_id].text
	return texts


func get_label(zone_id: StringName) -> PanelContainer:
	return _labels.get(zone_id, null)


func get_portrait() -> TextureRect:
	return _portrait


func _draw() -> void:
	if _texture != null and _view != null:
		draw_texture_rect(_texture, get_image_rect(), false)
	if not _selected.is_empty():
		var rect := zone_rect(_selected)
		if rect.has_area():
			draw_style_box(_highlight, _grown(rect, UiTokens.MAP_HIGHLIGHT_MIN))


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_pressed_zone = zone_at(button.position)
		return
	var zone := _pressed_zone
	_pressed_zone = &""
	if not zone.is_empty() and zone_at(button.position) == zone:
		Input.vibrate_handheld(UiTokens.HAPTIC_TICK_MS)
		zone_pressed.emit(zone)


func _apply_selection_style() -> void:
	for zone_id: StringName in _labels:
		var on := zone_id == _selected
		_labels[zone_id].theme_type_variation = &"MapLabelOn" if on else &"MapLabel"
		_label_texts[zone_id].theme_type_variation = &"MapLabelTextOn" if on else &"MapLabelText"


## Étiquettes et portrait, posés à l'échelle courante.
func _layout() -> void:
	if _view == null:
		return
	var portrait_height := UiTokens.MAP_PORTRAIT_HEIGHT
	_portrait.size = Vector2(portrait_height * 0.5, portrait_height)
	var player := zone_rect(_view.player_zone)
	if player.has_area():
		_portrait.position = player.get_center() - _portrait.size * 0.5
	for zone: MapZoneView in _view.zones:
		var pill: PanelContainer = _labels.get(zone.zone_id, null)
		if pill == null:
			continue
		pill.reset_size()
		var rect := zone_rect(zone.zone_id)
		var center := rect.get_center()
		var half_height := maxf(rect.size.y, UiTokens.MAP_HIGHLIGHT_MIN) * 0.5
		var half_width := maxf(rect.size.x, UiTokens.MAP_HIGHLIGHT_MIN) * 0.5
		if zone.current:
			half_height = maxf(half_height, portrait_height * 0.5)
		var at: Vector2
		if zone.kind == ZoneData.KIND_ROUTE:
			at = Vector2(center.x + half_width + UiTokens.MAP_LABEL_GAP,
				center.y - pill.get_combined_minimum_size().y * 0.5)
		else:
			at = Vector2(center.x - pill.get_combined_minimum_size().x * 0.5,
				center.y + half_height + UiTokens.MAP_LABEL_GAP)
		var pill_size := pill.get_combined_minimum_size()
		at.x = clampf(at.x, 0.0, maxf(size.x - pill_size.x, 0.0))
		at.y = clampf(at.y, 0.0, maxf(size.y - pill_size.y, 0.0))
		pill.position = at
	queue_redraw()


## [param rect] agrandi autour de son centre jusqu'à [param minimum] de côté (jamais réduit).
static func _grown(rect: Rect2, minimum: float) -> Rect2:
	var wanted := Vector2(maxf(rect.size.x, minimum), maxf(rect.size.y, minimum))
	return Rect2(rect.get_center() - wanted * 0.5, wanted)
