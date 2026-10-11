class_name LightGlow
extends Sprite2D
## Halo de lumière léger (docs/tech/jalon-12.md §2.4) : lampes de chantier, puits de jour,
## éclats de Pierre Lune, projecteurs. Un `Sprite2D` **additif** dont la texture est un dégradé
## radial **généré** (aucun asset), couleur, rayon, intensité et vacillement lus par type dans
## `data/world/light_glows.json` ([LightGlowLibrary]). **Aucune `Light2D`** (rendu `mobile`).
##
## Posé par l'outil de construction d'une carte (`tools/cave_map_kit.gd`) : la scène n'enregistre
## que [member glow_type] (et la position) ; texture, échelle et matériau sont reconstruits au
## chargement, partagés entre tous les halos d'un même type (un matériau par type qui vacille,
## un seul pour les halos fixes).
## Dessiné **au-dessus des personnages** ([constant Z_GLOW] : au-dessus de `Entities`, sous la
## couche haute) pour qu'ils prennent la lumière en passant ; intensité ≤
## [constant LightGlowLibrary.ALPHA_MAX].
## « Réduire les animations » : [method set_reduce_motion] coupe le vacillement de tous les halos
## (amplitude nulle), le halo reste allumé.

## Au-dessus de `Entities` (0, tri par les pieds), sous `Overhead` (10).
const Z_GLOW: int = 5
const SHADER: Shader = preload("res://game/world/lighting/shaders/light_glow.gdshader")
## Côté de la texture du dégradé (pixels) ; le sprite est mis à l'échelle du rayon.
const TEXTURE_SIZE: int = 256

static var _library: LightGlowLibrary
static var _texture: GradientTexture2D
static var _steady_material: CanvasItemMaterial
static var _flicker_materials: Dictionary[StringName, ShaderMaterial] = {}
static var _reduce_motion: bool = false

## Type de halo (clé de `light_glows.json`).
@export var glow_type: StringName = &"lamp":
	set(value):
		glow_type = value
		if is_node_ready():
			_apply()


func _init() -> void:
	z_index = Z_GLOW
	z_as_relative = false
	centered = true


func _ready() -> void:
	_apply()


## Coupe (vrai) ou rend le vacillement de tous les halos (« Réduire les animations »).
static func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	for id: StringName in _flicker_materials:
		_flicker_materials[id].set_shader_parameter(&"amplitude", _amplitude_of(id))


static func is_reduce_motion() -> bool:
	return _reduce_motion


## Types de halo du jeu (chargés une fois depuis [constant LightGlowLibrary.DATA_PATH]).
static func library() -> LightGlowLibrary:
	if _library == null:
		_library = LightGlowLibrary.new()
		_library.load_file()
	return _library


## Amplitude du vacillement appliquée aux halos de [param id] (0 : fixe, ou animations
## réduites).
static func flicker_amplitude(id: StringName) -> float:
	return _amplitude_of(id)


## Échelle du sprite pour un halo de [param radius] cases.
static func scale_for(radius: float) -> float:
	return radius * 2.0 * Grid.TILE_SIZE / TEXTURE_SIZE


## Vrai si ce halo est affiché (type connu).
func is_lit() -> bool:
	return visible and texture != null


func _apply() -> void:
	var type := library().get_type(glow_type)
	if type == null:
		push_error("LightGlow : type de halo inconnu « %s »" % glow_type)
		texture = null
		visible = false
		return
	visible = true
	texture = _gradient()
	scale = Vector2.ONE * scale_for(type.radius)
	self_modulate = Color(type.color, type.alpha)
	material = _material_for(type)


static func _amplitude_of(id: StringName) -> float:
	var type := library().get_type(id)
	if type == null or _reduce_motion:
		return 0.0
	return type.flicker


static func _material_for(type: LightGlowLibrary.GlowType) -> Material:
	if type.flicker <= 0.0:
		if _steady_material == null:
			_steady_material = CanvasItemMaterial.new()
			_steady_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return _steady_material
	if not _flicker_materials.has(type.id):
		var shader_material := ShaderMaterial.new()
		shader_material.shader = SHADER
		_flicker_materials[type.id] = shader_material
	_flicker_materials[type.id].set_shader_parameter(&"amplitude", _amplitude_of(type.id))
	return _flicker_materials[type.id]


## Dégradé radial blanc, opaque au centre et nul au bord (adouci : pas d'anneau visible).
static func _gradient() -> GradientTexture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.62),
			Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0)])
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = TEXTURE_SIZE
		_texture.height = TEXTURE_SIZE
	return _texture
