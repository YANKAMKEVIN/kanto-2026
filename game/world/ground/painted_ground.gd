class_name PaintedGround
extends Node2D
## Sol peint d'une carte (docs/tech/jalon-07.md §6.6) : un seul rectangle de la taille de la
## carte, dessiné par `ground_blend` (herbe, pavés, chemin mélangés par [member mask]). Le sol
## ne se lit plus en tuiles : le `TileMapLayer` `Ground` reste dans la carte, **invisible**,
## comme source logique (solide, herbes hautes, rebords).
## Dessiné sous les ombres et les décalcomanies ([constant WorldLighting.Z_GROUND]).
## **Rivage** (DA.2) : [member shore_mask] (facultatif, [method GroundMask.build_shore]) ajoute
## le sable puis la mer par-dessus, avec une frange d'écume et une eau qui ondule doucement
## (`proto/da_jadielle/sol_bourg.gdshader`). Sans lui, ni sable ni eau (textures non chargées).

const SHADER: Shader = preload("res://game/world/lighting/shaders/ground_blend.gdshader")
const GRASS_TEXTURE: String = "res://assets/world/ground/ground_herbe_01.png"
const PAVING_TEXTURE: String = "res://assets/world/ground/ground_paves_01.png"
const PATH_TEXTURE: String = "res://assets/world/ground/ground_chemin_01.png"
const SAND_TEXTURE: String = "res://assets/world/ground/ground_sable_01.png"
const WATER_TEXTURE: String = "res://assets/world/ground/ground_eau_01.png"

## Taille en cases (celle de la carte).
@export var size: Vector2i = Vector2i(16, 16):
	set(value):
		size = value
		queue_redraw()
## Masque de la carte ([GroundMask] : R pavés, G chemin), 1 pixel = 1 case.
@export var mask: Texture2D:
	set(value):
		mask = value
		_update_material()
## Masque du rivage ([method GroundMask.build_shore] : R sable, G eau), 1 pixel = 1 case ;
## nul = pas de rivage.
@export var shore_mask: Texture2D:
	set(value):
		shore_mask = value
		_update_material()


func _init() -> void:
	z_index = WorldLighting.Z_GROUND
	_update_material()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size * Grid.TILE_SIZE)), Color.WHITE)


func get_shader_material() -> ShaderMaterial:
	return material as ShaderMaterial


func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = SHADER
		shader_material.set_shader_parameter(&"grass_texture", load(GRASS_TEXTURE))
		shader_material.set_shader_parameter(&"paving_texture", load(PAVING_TEXTURE))
		shader_material.set_shader_parameter(&"path_texture", load(PATH_TEXTURE))
		material = shader_material
	shader_material.set_shader_parameter(&"ground_mask", mask)
	shader_material.set_shader_parameter(&"tile_size", float(Grid.TILE_SIZE))
	shader_material.set_shader_parameter(&"has_shore", shore_mask != null)
	shader_material.set_shader_parameter(&"shore_mask", shore_mask)
	if shore_mask != null and shader_material.get_shader_parameter(&"sand_texture") == null:
		shader_material.set_shader_parameter(&"sand_texture", load(SAND_TEXTURE))
		shader_material.set_shader_parameter(&"water_texture", load(WATER_TEXTURE))
