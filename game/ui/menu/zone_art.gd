class_name ZoneArt
extends TextureRect
## Image d'une zone dans le menu (MM.2) : son aperçu peint ([method MenuArt.zone_preview]) ou, à
## défaut, un recadrage de l'illustration de Kanto autour de son rectangle ; couvre le contrôle
## sans déformation, coins arrondis, dégradé vers le bas ([code]menu_zone_art.gdshader[/code], un
## seul tracé). Sans image : rien n'est dessiné (le fond du parent reste).

const SHADER: Shader = preload("res://game/ui/menu/menu_zone_art.gdshader")

var _material: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	resized.connect(_on_resized)


## Pose l'image de [param zone_id] : son aperçu s'il existe, sinon la région de
## [param illustration] autour de [param area] (pixels de l'image) ; null/vide : aucune image.
func show_zone(zone_id: StringName, illustration: Texture2D = null,
		area: Rect2 = Rect2()) -> void:
	var preview := MenuArt.zone_preview(zone_id)
	if preview != null:
		_set_image(preview, Rect2(Vector2.ZERO, preview.get_size()))
		return
	if illustration != null:
		var crop := MenuArt.zone_crop(area, illustration.get_size())
		if crop.has_area():
			_set_image(illustration, crop)
			return
	texture = null


## Pose [param image] (sa région [param region] en pixels ; vide : l'image entière).
func show_texture(image: Texture2D, region: Rect2 = Rect2()) -> void:
	if image == null:
		texture = null
		return
	_set_image(image, region if region.has_area() else Rect2(Vector2.ZERO, image.get_size()))


## Vrai si une image est posée.
func has_image() -> bool:
	return texture != null


## Rayon des coins, début et couleur du dégradé, voile (vignette grisée), point gardé.
func set_style(radius: float, fade_from: float, fade_color: Color, dim: float = 0.0,
		focus: Vector2 = Vector2(0.5, 0.5)) -> void:
	_material.set_shader_parameter(&"radius", radius)
	_material.set_shader_parameter(&"fade_from", fade_from)
	_material.set_shader_parameter(&"fade_color", fade_color)
	_material.set_shader_parameter(&"dim", dim)
	_material.set_shader_parameter(&"focus", focus)


func _set_image(image: Texture2D, region: Rect2) -> void:
	texture = image
	var full := image.get_size()
	_material.set_shader_parameter(&"texture_size", region.size)
	_material.set_shader_parameter(&"region", Vector4(region.position.x / full.x,
		region.position.y / full.y, region.size.x / full.x, region.size.y / full.y))


func _on_resized() -> void:
	_material.set_shader_parameter(&"rect_size", size)
