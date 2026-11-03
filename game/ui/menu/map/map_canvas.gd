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
## Reliquats du Menu peint (2026-11-02) : étiquettes sans chevauchement ([MapLabelLayout]) ;
## une étiquette secondaire sans place libre à cette échelle est masquée (zone toujours touchable).
## MM.2 (maquette) : étiquettes en pastilles de verre avec l'icône du genre de zone (ville,
## route, lieu) ; **lieu courant** en ACCENT, zone du panneau cerclée d'ACCENT (et son halo) ;
## portrait du joueur = tête du buste peint dans un rond.

signal zone_pressed(zone: StringName)

const KIND_ICONS: Dictionary[StringName, Texture2D] = {
	ZoneData.KIND_TOWN: preload("res://assets/ui/icons/map/town.svg"),
	ZoneData.KIND_ROUTE: preload("res://assets/ui/icons/map/route.svg"),
	ZoneData.KIND_PLACE: preload("res://assets/ui/icons/map/place.svg"),
}
const ICON_DEFAULT: Texture2D = preload("res://assets/ui/icons/map/route.svg")
## Priorité des étiquettes (reliquats du Menu peint) : les deux premières ne sont jamais masquées.
const LABEL_RANK_CURRENT := 0
const LABEL_RANK_SELECTED := 1
const LABEL_RANK_TOWN := 2
const LABEL_RANK_PLACE := 3
const LABEL_RANK_ROUTE := 4

var _view: MapView
var _texture: Texture2D
var _selected: StringName = &""
var _pressed_zone: StringName = &""
var _labels: Dictionary[StringName, PanelContainer] = {}
var _label_texts: Dictionary[StringName, Label] = {}
var _label_icons: Dictionary[StringName, TextureRect] = {}
var _current: StringName = &""
var _portrait: Panel
var _highlight: StyleBoxFlat


## Tête du buste dans le rond du portrait.
var _head: ZoneArt

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true
	# Portrait : la tête du buste peint dans un rond (masque du shader de ZoneArt : un clip
	# d'enfants ne s'imbrique pas dans celui du cadre de la Carte).
	_portrait = Panel.new()
	_portrait.theme_type_variation = &"MapPortrait"
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	add_child(_portrait)
	var head := ZoneArt.new()
	_head = head
	head.set_style(UiTokens.MAP_PORTRAIT_HEIGHT * 0.5 - UiTokens.MAP_PORTRAIT_BORDER, 1.0,
		UiTokens.MAP_PORTRAIT_BG)
	head.show_texture(MenuArt.hero_bust(), UiTokens.MAP_PORTRAIT_REGION)
	head.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := float(UiTokens.MAP_PORTRAIT_BORDER)
	head.offset_left = inset
	head.offset_top = inset
	head.offset_right = -inset
	head.offset_bottom = -inset
	_portrait.add_child(head)
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
	# Costumes (CO-5, CO-7) : le buste peut avoir changé depuis la construction.
	_head.show_texture(MenuArt.hero_bust(), UiTokens.MAP_PORTRAIT_REGION)
	_texture = null
	if not view.image_path.is_empty() and ResourceLoader.exists(view.image_path):
		_texture = load(view.image_path) as Texture2D
	for label: PanelContainer in _labels.values():
		remove_child(label)
		label.queue_free()
	_labels.clear()
	_label_texts.clear()
	_label_icons.clear()
	_current = &""
	for zone: MapZoneView in view.zones:
		if zone.current:
			_current = zone.zone_id
		if not zone.is_touchable():
			continue
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.modulate.a = UiTokens.MAP_LABEL_ALPHA
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override(&"separation", UiTokens.MAP_LABEL_GAP)
		pill.add_child(row)
		var icon := TextureRect.new()
		icon.texture = KIND_ICONS.get(zone.kind, ICON_DEFAULT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * UiTokens.MAP_LABEL_ICON
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var text := Label.new()
		text.text = zone.name
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		add_child(pill)
		_labels[zone.zone_id] = pill
		_label_texts[zone.zone_id] = text
		_label_icons[zone.zone_id] = icon
	var player := view.zone(view.player_zone)
	_portrait.visible = player != null and player.is_touchable()
	_apply_selection_style()
	_layout()
	queue_redraw()


## Zone du panneau : halo sur l'illustration et étiquette cerclée d'ACCENT (&"" : aucune).
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


## Portrait du joueur (rond, tête du buste peint).
func get_portrait() -> Control:
	return _portrait


## Zone du joueur dont l'étiquette est mise en avant (&"" : aucune).
func get_current() -> StringName:
	return _current


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
		Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
		zone_pressed.emit(zone)


## Lieu courant : pastille ACCENT ; zone du panneau (si ce n'est pas lui) : pastille cerclée.
func _apply_selection_style() -> void:
	for zone_id: StringName in _labels:
		var here := zone_id == _current
		var variation := &"MapLabel"
		if here:
			variation = &"MapLabelOn"
		elif zone_id == _selected:
			variation = &"MapLabelSelected"
		_labels[zone_id].theme_type_variation = variation
		_label_texts[zone_id].theme_type_variation = &"MapLabelTextOn" if here \
			else &"MapLabelText"
		_label_icons[zone_id].modulate = UiTokens.ACCENT_TEXT if here else UiTokens.ACCENT


## Étiquettes et portrait, posés à l'échelle courante.
func _layout() -> void:
	if _view == null:
		return
	var portrait_height := UiTokens.MAP_PORTRAIT_HEIGHT
	_portrait.size = Vector2(portrait_height, portrait_height)
	var player := zone_rect(_view.player_zone)
	if player.has_area():
		_portrait.position = player.get_center() - _portrait.size * 0.5
	var ids: Array[StringName] = []
	var sizes: Array[Vector2] = []
	var candidates: Array[Array] = []
	var ranks: Array[int] = []
	for zone: MapZoneView in _view.zones:
		var pill: PanelContainer = _labels.get(zone.zone_id, null)
		if pill == null:
			continue
		pill.reset_size()
		var pill_size := pill.get_combined_minimum_size()
		var rect := zone_rect(zone.zone_id)
		var half_height := maxf(rect.size.y, UiTokens.MAP_HIGHLIGHT_MIN) * 0.5
		var half_width := maxf(rect.size.x, UiTokens.MAP_HIGHLIGHT_MIN) * 0.5
		if zone.current:
			half_height = maxf(half_height, portrait_height * 0.5)
		ids.append(zone.zone_id)
		sizes.append(pill_size)
		candidates.append(_label_candidates(rect.get_center(), Vector2(half_width, half_height),
			pill_size, zone.kind == ZoneData.KIND_ROUTE))
		ranks.append(_label_rank(zone))
	# Priorité : lieu courant, zone du panneau, puis villes, lieux, routes (ordre des données).
	var order: Array[int] = []
	order.assign(range(ids.size()))
	order.sort_custom(func(a: int, b: int) -> bool:
		return ranks[a] < ranks[b] or (ranks[a] == ranks[b] and a < b))
	var forced := 0
	for index: int in order:
		if ranks[index] < LABEL_RANK_TOWN:
			forced += 1
	var obstacles: Array[Rect2] = []
	if _portrait.visible:
		obstacles.append(Rect2(_portrait.position, _portrait.size))
	# Étiquettes gardées sur l'illustration (pas sur le fond flou autour), dans le contrôle.
	var bounds := get_image_rect().intersection(Rect2(Vector2.ZERO, size))
	if not bounds.has_area():
		bounds = Rect2(Vector2.ZERO, size)
	var placed := MapLabelLayout.place(sizes, candidates, order, forced, bounds, obstacles,
		float(UiTokens.MAP_LABEL_GAP))
	for index: int in ids.size():
		var pill: PanelContainer = _labels[ids[index]]
		pill.visible = placed[index].has_area()
		if pill.visible:
			pill.position = placed[index].position
	queue_redraw()


## Rectangles des étiquettes **affichées** (zone → rectangle) : jamais deux qui se chevauchent.
func get_label_rects() -> Dictionary[StringName, Rect2]:
	var rects: Dictionary[StringName, Rect2] = {}
	for zone_id: StringName in _labels:
		var pill := _labels[zone_id]
		if pill.visible:
			rects[zone_id] = Rect2(pill.position, pill.size)
	return rects


## Rang de priorité de l'étiquette de [param zone] (plus petit = posée d'abord).
func _label_rank(zone: MapZoneView) -> int:
	if zone.zone_id == _current:
		return LABEL_RANK_CURRENT
	if zone.zone_id == _selected:
		return LABEL_RANK_SELECTED
	if zone.kind == ZoneData.KIND_TOWN:
		return LABEL_RANK_TOWN
	return LABEL_RANK_PLACE if zone.kind == ZoneData.KIND_PLACE else LABEL_RANK_ROUTE


## Positions candidates (coin haut gauche) d'une étiquette de taille [param label] autour d'une
## zone de centre [param center] et de demi-taille [param half] : sous la zone (à droite pour
## une route), puis les trois autres côtés.
static func _label_candidates(center: Vector2, half: Vector2, label: Vector2,
		route: bool) -> Array:
	var gap := float(UiTokens.MAP_LABEL_GAP)
	var below := Vector2(center.x - label.x * 0.5, center.y + half.y + gap)
	var right := Vector2(center.x + half.x + gap, center.y - label.y * 0.5)
	var above := Vector2(center.x - label.x * 0.5, center.y - half.y - gap - label.y)
	var left := Vector2(center.x - half.x - gap - label.x, center.y - label.y * 0.5)
	return [right, left, below, above] if route else [below, above, right, left]


## [param rect] agrandi autour de son centre jusqu'à [param minimum] de côté (jamais réduit).
static func _grown(rect: Rect2, minimum: float) -> Rect2:
	var wanted := Vector2(maxf(rect.size.x, minimum), maxf(rect.size.y, minimum))
	return Rect2(rect.get_center() - wanted * 0.5, wanted)
