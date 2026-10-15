class_name DarknessVeil
extends Node2D
## Le voile d'obscurité (brique commune J17 T9 / J18 : docs/tech/jalon-18.md §2.1–§2.5) : un
## rectangle **dans le monde**, à la taille de la vue (marge comprise), dessiné en z **absolu**
## [constant WorldLighting.Z_VEIL] (au-dessus des personnages, de `LightGlow` et d'`Overhead`,
## sous la bulle « ! » [constant WorldLighting.Z_ABOVE_VEIL] et sous tous les `CanvasLayer` :
## étalonnage, combat, HUD, dialogues, menus), avec le shader `shaders/darkness_veil.gdshader`.
## Ne calcule rien : reçoit rectangle, centre, réglages, sources et battement
## ([DarknessController]). Chaque paramètre n'est poussé au shader **que s'il change** (aucune
## allocation par image). Aucun effet sur la grille ni les collisions : un rendu, rien d'autre.

const SHADER: Shader = preload("res://game/world/lighting/shaders/darkness_veil.gdshader")
const _P_COLOR: StringName = &"veil_color"
const _P_CENTER: StringName = &"center"
const _P_CLEAR: StringName = &"clear_radius"
const _P_FADE: StringName = &"fade_radius"
const _P_OUTSIDE: StringName = &"outside"
const _P_BREATH: StringName = &"breath"
const _P_PERIOD: StringName = &"breath_period"
const _P_DITHER: StringName = &"dither"
const _P_SOURCES: StringName = &"sources"
const _P_COUNT: StringName = &"source_count"

var _shader_material: ShaderMaterial
var _size: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2(INF, INF)
var _params: VeilParams = VeilParams.new()
var _breath: float = -1.0
var _period: float = -1.0
var _sources: PackedVector4Array = PackedVector4Array()


func _init() -> void:
	name = "DarknessVeil"
	z_as_relative = false
	z_index = WorldLighting.Z_VEIL
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SHADER
	material = _shader_material
	visible = false
	set_sources(PackedVector4Array())


func _draw() -> void:
	if _size != Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, _size), Color.WHITE)


## Rectangle couvert, en coordonnées du monde (parent sans transformation).
func set_view_rect(rect: Rect2) -> void:
	if position != rect.position:
		position = rect.position
	if _size != rect.size:
		_size = rect.size
		queue_redraw()


func get_view_rect() -> Rect2:
	return Rect2(position, _size)


## Centre du trou (monde, px).
func set_center(world_position: Vector2) -> void:
	if _center == world_position:
		return
	_center = world_position
	_shader_material.set_shader_parameter(_P_CENTER, world_position)


func get_center() -> Vector2:
	return _center


func set_params(params: VeilParams) -> void:
	if not is_equal_approx(_params.clear_px, params.clear_px):
		_params.clear_px = params.clear_px
		_shader_material.set_shader_parameter(_P_CLEAR, params.clear_px)
	if not is_equal_approx(_params.fade_px, params.fade_px):
		_params.fade_px = params.fade_px
		_shader_material.set_shader_parameter(_P_FADE, params.fade_px)
	if not is_equal_approx(_params.outside, params.outside):
		_params.outside = params.outside
		_shader_material.set_shader_parameter(_P_OUTSIDE, params.outside)


## Réglages poussés (copie).
func get_params() -> VeilParams:
	return VeilParams.make(_params.clear_px, _params.fade_px, _params.outside)


func set_color(color: Color) -> void:
	_shader_material.set_shader_parameter(_P_COLOR, Vector3(color.r, color.g, color.b))


func set_dither(amount: float) -> void:
	_shader_material.set_shader_parameter(_P_DITHER, amount)


## Halos fixes qui percent le voile (au plus [constant VeilMath.MAX_SOURCES]).
func set_sources(sources: PackedVector4Array) -> void:
	_sources = sources.slice(0, VeilMath.MAX_SOURCES)
	var padded := _sources.duplicate()
	padded.resize(VeilMath.MAX_SOURCES)
	_shader_material.set_shader_parameter(_P_SOURCES, padded)
	_shader_material.set_shader_parameter(_P_COUNT, _sources.size())


func get_sources() -> PackedVector4Array:
	return _sources


## Battement du halo : amplitude relative (0 = immobile) et période (s).
func set_breath(amplitude: float, period: float = 3.5) -> void:
	if is_equal_approx(_breath, amplitude) and is_equal_approx(_period, period):
		return
	_breath = amplitude
	_period = period
	_shader_material.set_shader_parameter(_P_BREATH, amplitude)
	_shader_material.set_shader_parameter(_P_PERIOD, period)


func get_breath() -> float:
	return maxf(_breath, 0.0)


## Opacité calculée (miroir du shader, sans battement) au point [param point] du monde.
func alpha_at(point: Vector2) -> float:
	return VeilMath.alpha_at(point, _center, _params, _sources)
