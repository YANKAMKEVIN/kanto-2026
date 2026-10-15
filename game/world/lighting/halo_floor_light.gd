class_name HaloFloorLight
extends Node2D
## Lueur du halo au sol (J17 T25) : un rectangle à la taille de la vue, en **ajout**, dessiné en
## z absolu [constant WorldLighting.Z_GROUND_DECALS] (au-dessus du sol, sous les personnages),
## qui éclaircit le sol dans le halo du joueur (mêmes rayons que le trou de [DarknessVeil]).
## Raison : le héros (haut clair, jambes sombres) se détache mal d'un sol de luminance moyenne
## (≈ 0,33) ; le voile, au-dessus des personnages, ne peut pas éclaircir le sol sans éclaircir
## le héros. Ne calcule rien ; piloté par [DarknessController]. Aucun effet sur la grille.

const SHADER: Shader = preload("res://game/world/lighting/shaders/halo_floor_light.gdshader")

var _shader_material: ShaderMaterial
var _size: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2(INF, INF)
var _clear: float = -1.0
var _fade: float = -1.0
var _strength: float = -1.0


func _init() -> void:
	name = "HaloFloorLight"
	z_as_relative = false
	z_index = WorldLighting.Z_GROUND_DECALS
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SHADER
	material = _shader_material
	visible = false


func _draw() -> void:
	if _size != Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, _size), Color.WHITE)


func set_view_rect(rect: Rect2) -> void:
	if position != rect.position:
		position = rect.position
	if _size != rect.size:
		_size = rect.size
		queue_redraw()


func set_center(world_position: Vector2) -> void:
	if _center != world_position:
		_center = world_position
		_shader_material.set_shader_parameter(&"center", world_position)


func set_params(params: VeilParams) -> void:
	if not is_equal_approx(_clear, params.clear_px):
		_clear = params.clear_px
		_shader_material.set_shader_parameter(&"clear_radius", _clear)
	if not is_equal_approx(_fade, params.fade_px):
		_fade = params.fade_px
		_shader_material.set_shader_parameter(&"fade_radius", _fade)


func set_strength(strength: float) -> void:
	if not is_equal_approx(_strength, strength):
		_strength = strength
		_shader_material.set_shader_parameter(&"strength", strength)


func get_strength() -> float:
	return maxf(_strength, 0.0)


## Éclaircissement ajouté au sol au point [param point] (miroir du shader).
func lift_at(point: Vector2) -> float:
	return VeilMath.lift_at(point, _center, VeilParams.make(_clear, _fade, 0.0), get_strength())


func get_view_rect_for_test() -> Rect2:
	return Rect2(position, _size)
