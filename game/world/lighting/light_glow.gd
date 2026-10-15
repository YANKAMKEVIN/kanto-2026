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
const SHADER_MIX: Shader = preload("res://game/world/lighting/shaders/light_glow_mix.gdshader")
## Côté de la texture du dégradé (pixels) ; le sprite est mis à l'échelle du rayon.
const TEXTURE_SIZE: int = 256
## Image générée d'une colonne de lumière (pixels) ; mise à l'échelle de la largeur et de la
## hauteur du type.
const COLUMN_WIDTH: int = 64
const COLUMN_HEIGHT: int = 256

static var _library: LightGlowLibrary
static var _texture: GradientTexture2D
static var _plateau_texture: GradientTexture2D
static var _column_texture: ImageTexture
static var _steady_material: CanvasItemMaterial
static var _steady_mix_material: CanvasItemMaterial
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
	if type.shape == LightGlowLibrary.SHAPE_COLUMN:
		# Colonne posée à son pied (position du nœud = bas de la colonne, au sol).
		texture = _column()
		centered = false
		offset = Vector2(-COLUMN_WIDTH / 2.0, -COLUMN_HEIGHT)
		scale = Vector2(type.radius * 2.0 * Grid.TILE_SIZE / COLUMN_WIDTH,
			type.height * Grid.TILE_SIZE / COLUMN_HEIGHT)
	else:
		texture = _plateau() if type.blend == LightGlowLibrary.BLEND_MIX else _gradient()
		centered = true
		offset = Vector2.ZERO
		scale = Vector2.ONE * scale_for(type.radius)
	self_modulate = Color(type.color, type.alpha)
	material = _material_for(type)


static func _amplitude_of(id: StringName) -> float:
	var type := library().get_type(id)
	if type == null or _reduce_motion:
		return 0.0
	return type.flicker


static func _material_for(type: LightGlowLibrary.GlowType) -> Material:
	var mix := type.blend == LightGlowLibrary.BLEND_MIX
	if type.flicker <= 0.0:
		if mix:
			if _steady_mix_material == null:
				_steady_mix_material = CanvasItemMaterial.new()
				_steady_mix_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			return _steady_mix_material
		if _steady_material == null:
			_steady_material = CanvasItemMaterial.new()
			_steady_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return _steady_material
	if not _flicker_materials.has(type.id):
		var shader_material := ShaderMaterial.new()
		shader_material.shader = SHADER_MIX if mix else SHADER
		_flicker_materials[type.id] = shader_material
	_flicker_materials[type.id].set_shader_parameter(&"amplitude", _amplitude_of(type.id))
	return _flicker_materials[type.id]


## Colonne de lumière douce (puits de jour) : bords latéraux adoucis, nulle en haut et au pied
## (fondue dans la flaque du sol, aucun bord net), la plus forte au dernier quart.
static func _column() -> ImageTexture:
	if _column_texture == null:
		var image := Image.create(COLUMN_WIDTH, COLUMN_HEIGHT, false, Image.FORMAT_RGBA8)
		for y: int in COLUMN_HEIGHT:
			var v := (y + 0.5) / COLUMN_HEIGHT
			var vertical := smoothstep(0.0, 0.75, v) * (1.0 - smoothstep(0.82, 1.0, v))
			for x: int in COLUMN_WIDTH:
				var u := absf((x + 0.5) / COLUMN_WIDTH * 2.0 - 1.0)
				var side := pow(maxf(1.0 - u * u, 0.0), 1.6)
				image.set_pixel(x, y, Color(1, 1, 1, side * vertical))
		_column_texture = ImageTexture.create_from_image(image)
	return _column_texture


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


## Disque doux à cœur plein (halos « mix ») : la teinte couvre l'objet entier avant de s'éteindre,
## au lieu du dégradé pointu des lampes (qui ne tient que sur le centre).
static func _plateau() -> GradientTexture2D:
	if _plateau_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 0.75, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.85),
			Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		_plateau_texture = GradientTexture2D.new()
		_plateau_texture.gradient = gradient
		_plateau_texture.fill = GradientTexture2D.FILL_RADIAL
		_plateau_texture.fill_from = Vector2(0.5, 0.5)
		_plateau_texture.fill_to = Vector2(1.0, 0.5)
		_plateau_texture.width = TEXTURE_SIZE
		_plateau_texture.height = TEXTURE_SIZE
	return _plateau_texture
