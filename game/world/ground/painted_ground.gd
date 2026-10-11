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
## **Textures réglables** (jalon 12 T7) : [member base_texture] (fond), [member r_texture] (canal
## rouge du masque), [member g_texture] (canal vert) ; nulles = herbe, pavés, chemin (défauts de
## toutes les cartes peintes jusqu'au J11, qui n'enregistrent aucune de ces propriétés). La Route 3
## y met le sol rocheux, le Mont Sélénite ses trois sols (`tools/cave_map_kit.gd`). Toutes les
## textures d'un même sol ont la même taille (uniform `texture_size` du shader).

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
## Texture du fond (là où le masque est noir) ; nulle = herbe ([constant GRASS_TEXTURE]).
@export var base_texture: Texture2D:
	set(value):
		base_texture = value
		_update_textures()
## Texture du canal rouge du masque ; nulle = pavés ([constant PAVING_TEXTURE]).
@export var r_texture: Texture2D:
	set(value):
		r_texture = value
		_update_textures()
## Texture du canal vert du masque ; nulle = chemin ([constant PATH_TEXTURE]).
@export var g_texture: Texture2D:
	set(value):
		g_texture = value
		_update_textures()


func _init() -> void:
	z_index = WorldLighting.Z_GROUND
	_update_material()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size * Grid.TILE_SIZE)), Color.WHITE)


func get_shader_material() -> ShaderMaterial:
	return material as ShaderMaterial


## Textures effectivement dessinées : fond, canal rouge, canal vert (défauts compris).
func get_textures() -> Array[Texture2D]:
	var shader_material := get_shader_material()
	var textures: Array[Texture2D] = []
	for parameter: StringName in [&"grass_texture", &"paving_texture", &"path_texture"]:
		textures.append(shader_material.get_shader_parameter(parameter) as Texture2D)
	return textures


func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = SHADER
		material = shader_material
		_update_textures()
	shader_material.set_shader_parameter(&"ground_mask", mask)
	shader_material.set_shader_parameter(&"tile_size", float(Grid.TILE_SIZE))
	shader_material.set_shader_parameter(&"has_shore", shore_mask != null)
	shader_material.set_shader_parameter(&"shore_mask", shore_mask)
	if shore_mask != null and shader_material.get_shader_parameter(&"sand_texture") == null:
		shader_material.set_shader_parameter(&"sand_texture", load(SAND_TEXTURE))
		shader_material.set_shader_parameter(&"water_texture", load(WATER_TEXTURE))


## Pose les trois textures (réglées ou par défaut). Une carte enregistrée sans réglage garde le
## matériau de sa scène, qui porte déjà les textures par défaut : rien n'est rechargé.
func _update_textures() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"grass_texture",
		base_texture if base_texture != null else load(GRASS_TEXTURE))
	shader_material.set_shader_parameter(&"paving_texture",
		r_texture if r_texture != null else load(PAVING_TEXTURE))
	shader_material.set_shader_parameter(&"path_texture",
		g_texture if g_texture != null else load(PATH_TEXTURE))
