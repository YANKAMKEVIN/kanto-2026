class_name PokedexHabitatMap
extends Control
## Carte d'habitat du Pokédex (dossier 08 §4 ; refonte T4 : elle **remplit son cadre**, comme
## la maquette). L'illustration du Kanto (assets/ui/map/kanto_placeholder.webp) est recadrée sur
## la région utile : les zones où l'espèce a été observée, agrandies au rapport du cadre (sans
## descendre sous DEX_MAP_MIN_REGION, sans sortir de l'image).
##
## Anti-spoiler : **seules les zones observées** sont marquées (éclairées, liseré, épingle).
## Autour, la géographie reste voilée (DEX_MAP_VEIL), sans aucun nom, liseré ni épingle — comme
## sur la Carte, où l'illustration est entière et seules les zones découvertes sont nommées
## (Q-15). Jamais « ??? ». La géométrie vient de kanto_placeholder_areas.json (présentation, en
## lecture seule). Une zone sans rectangle connu n'a pas d'épingle. Purement visuelle : les
## accès tactiles sont autour (carte de l'Aperçu, pastilles de l'onglet Habitat).

const MAP_TEXTURE: Texture2D = preload("res://assets/ui/map/kanto_placeholder.webp")
const AREAS_PATH := "res://assets/ui/map/kanto_placeholder_areas.json"
const ROUNDED_SHADER: Shader = preload("res://game/ui/menu/pokedex/pokedex_rounded.gdshader")

static var _areas: Dictionary = {}
static var _loaded: bool = false

var _zone_ids: Array[StringName] = []
var _rects: Array[Rect2] = []


func _init() -> void:
	custom_minimum_size = UiTokens.DEX_MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rounded := ShaderMaterial.new()
	rounded.shader = ROUNDED_SHADER
	rounded.set_shader_parameter(&"radius", float(UiTokens.DEX_MAP_RADIUS))
	material = rounded
	resized.connect(_on_resized)


## Zones à montrer (celles de la fiche, observées).
func set_zones(zone_ids: Array[StringName]) -> void:
	_zone_ids = zone_ids.duplicate()
	_rects.clear()
	var areas := _load_areas()
	for zone_id: StringName in _zone_ids:
		var entry: Variant = areas.get(String(zone_id), null)
		if entry is Dictionary and (entry as Dictionary).get("area") is Array:
			var a: Array = (entry as Dictionary)["area"]
			if a.size() == 4:
				_rects.append(Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3])))
				continue
		_rects.append(Rect2())
	queue_redraw()


## Zones montrées, dans l'ordre.
func get_zone_ids() -> Array[StringName]:
	return _zone_ids


## Nombre d'épingles dessinées (zones dont la géométrie est connue).
func get_pin_count() -> int:
	var count := 0
	for rect: Rect2 in _rects:
		if rect.has_area():
			count += 1
	return count


## Rectangles (pixels de l'illustration) des zones marquées : **seulement** les zones observées
## dont la géométrie est connue.
func get_marked_areas() -> Array[Rect2]:
	var marked: Array[Rect2] = []
	for rect: Rect2 in _rects:
		if rect.has_area():
			marked.append(rect)
	return marked


## Région de l'illustration montrée dans le cadre (Rect2() si aucune zone n'est connue).
func get_shown_region() -> Rect2:
	return _region(size)


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, UiTokens.tinted(UiTokens.SURFACE_DARK, 0.9))
	var region := _region(size)
	if not region.has_area():
		return
	draw_texture_rect_region(MAP_TEXTURE, frame, region)
	draw_rect(frame, UiTokens.DEX_MAP_VEIL)
	var scale_factor := size.x / region.size.x
	var offset := -region.position * scale_factor
	for rect: Rect2 in _rects:
		if not rect.has_area():
			continue
		var patch := _patch(rect)
		var dest := Rect2(offset + patch.position * scale_factor, patch.size * scale_factor)
		draw_texture_rect_region(MAP_TEXTURE, dest, patch)
		draw_rect(dest, UiTokens.ACCENT, false, UiTokens.DEX_MAP_PATCH_BORDER)
	for rect: Rect2 in _rects:
		if not rect.has_area():
			continue
		var center := offset + rect.get_center() * scale_factor
		draw_circle(center, UiTokens.DEX_MAP_PIN + UiTokens.DEX_MAP_PIN_BORDER,
			UiTokens.SURFACE_DARK)
		draw_circle(center, UiTokens.DEX_MAP_PIN, UiTokens.ACCENT)
	var border := StyleBoxFlat.new()
	border.draw_center = false
	border.border_color = UiTokens.DEX_CARD_BORDER
	border.set_border_width_all(UiTokens.BORDER_WIDTH)
	border.set_corner_radius_all(UiTokens.DEX_MAP_RADIUS)
	border.anti_aliasing = true
	draw_style_box(border, frame)


## Région de l'illustration à montrer dans un cadre de [param frame] : les zones observées
## (avec marge), agrandie au rapport du cadre et au moins DEX_MAP_MIN_REGION, recentrée sur
## elles et gardée dans l'image.
func _region(frame: Vector2) -> Rect2:
	if frame.x <= 0.0 or frame.y <= 0.0:
		return Rect2()
	var bounds := Rect2()
	var first := true
	for rect: Rect2 in _rects:
		if not rect.has_area():
			continue
		var patch := _patch(rect)
		bounds = patch if first else bounds.merge(patch)
		first = false
	if first:
		return Rect2()
	bounds = bounds.grow(UiTokens.DEX_MAP_FRAME_MARGIN)
	var ratio := frame.x / frame.y
	var wanted := bounds.size.max(UiTokens.DEX_MAP_MIN_REGION)
	if wanted.x / wanted.y < ratio:
		wanted.x = wanted.y * ratio
	else:
		wanted.y = wanted.x / ratio
	var image := MAP_TEXTURE.get_size()
	if wanted.x > image.x:
		wanted = Vector2(image.x, image.x / ratio)
	if wanted.y > image.y:
		wanted = Vector2(image.y * ratio, image.y)
	var origin := bounds.get_center() - wanted * 0.5
	origin = origin.clamp(Vector2.ZERO, image - wanted)
	return Rect2(origin, wanted)


## Morceau de l'illustration autour de [param area], dans les limites de l'image.
func _patch(area: Rect2) -> Rect2:
	return area.grow(UiTokens.DEX_MAP_PATCH_MARGIN).intersection(
		Rect2(Vector2.ZERO, MAP_TEXTURE.get_size()))


func _on_resized() -> void:
	(material as ShaderMaterial).set_shader_parameter(&"rect_size", size)
	queue_redraw()


static func _load_areas() -> Dictionary:
	if _loaded:
		return _areas
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AREAS_PATH))
	if parsed is Dictionary and (parsed as Dictionary).get("zones") is Dictionary:
		_areas = (parsed as Dictionary)["zones"]
	return _areas
