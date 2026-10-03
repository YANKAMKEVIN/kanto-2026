class_name PokedexHabitatMap
extends Control
## Petite carte de l'onglet Habitat (dossier 08 §4) : un fond sombre et, **seulement pour les
## zones où l'espèce a été observée**, un morceau de l'illustration provisoire du Kanto
## (assets/ui/map/kanto_placeholder.webp) avec une épingle. Tout le reste est voilé : jamais
## une zone non découverte, jamais « ??? ».
##
## La géométrie vient de kanto_placeholder_areas.json (présentation de l'illustration, en
## lecture seule). Une zone sans rectangle connu n'a pas d'épingle (la pastille de son nom,
## à côté, reste son accès). Purement visuelle : les accès tactiles sont les pastilles.

const MAP_TEXTURE: Texture2D = preload("res://assets/ui/map/kanto_placeholder.webp")
const AREAS_PATH := "res://assets/ui/map/kanto_placeholder_areas.json"

static var _areas: Dictionary = {}
static var _loaded: bool = false

var _zone_ids: Array[StringName] = []
var _rects: Array[Rect2] = []


func _init() -> void:
	custom_minimum_size = UiTokens.DEX_MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


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


func _draw() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = UiTokens.tinted(UiTokens.SURFACE_DARK, 0.9)
	frame.border_color = UiTokens.PANEL_BORDER
	frame.set_border_width_all(UiTokens.BORDER_WIDTH)
	frame.set_corner_radius_all(UiTokens.RADIUS)
	frame.anti_aliasing = true
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
	var shown := _shown_bounds()
	if not shown.has_area():
		return
	var scale_factor := minf(size.x / shown.size.x, size.y / shown.size.y)
	var offset := (size - shown.size * scale_factor) * 0.5 - shown.position * scale_factor
	for rect: Rect2 in _rects:
		if not rect.has_area():
			continue
		var patch := _patch(rect)
		var dest := Rect2(offset + patch.position * scale_factor, patch.size * scale_factor)
		draw_texture_rect_region(MAP_TEXTURE, dest, patch)
		draw_rect(dest, UiTokens.ACCENT, false, UiTokens.DEX_MAP_PATCH_BORDER)
		var center := offset + rect.get_center() * scale_factor
		draw_circle(center, UiTokens.DEX_MAP_PIN + UiTokens.DEX_MAP_PIN_BORDER,
			UiTokens.SURFACE_DARK)
		draw_circle(center, UiTokens.DEX_MAP_PIN, UiTokens.ACCENT)


## Cadre de la petite carte : l'ensemble des zones montrées, avec une marge.
func _shown_bounds() -> Rect2:
	var bounds := Rect2()
	var first := true
	for rect: Rect2 in _rects:
		if not rect.has_area():
			continue
		var patch := _patch(rect)
		bounds = patch if first else bounds.merge(patch)
		first = false
	return bounds.grow(UiTokens.DEX_MAP_FRAME_MARGIN)


## Morceau de l'illustration autour de [param area], dans les limites de l'image.
func _patch(area: Rect2) -> Rect2:
	return area.grow(UiTokens.DEX_MAP_PATCH_MARGIN).intersection(
		Rect2(Vector2.ZERO, MAP_TEXTURE.get_size()))


static func _load_areas() -> Dictionary:
	if _loaded:
		return _areas
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AREAS_PATH))
	if parsed is Dictionary and (parsed as Dictionary).get("zones") is Dictionary:
		_areas = (parsed as Dictionary)["zones"]
	return _areas
