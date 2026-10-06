class_name ForestFloor
extends Node2D
## Sous-bois de la forêt serrée ([DenseForest]) : sol sombre sous les cases de forêt, à la
## frontière bruitée, pour que l'herbe claire ne se voie jamais entre les troncs. Réécrit
## d'après `proto/da_jadielle/sous_bois.gdshader` (mêmes bruits, mêmes seuils, mêmes couleurs).
##
## Un rectangle de la taille de la carte dessiné par `forest_floor.gdshader`, au-dessus du sol
## peint ([PaintedGround], même z [constant WorldLighting.Z_GROUND] : il le suit dans l'arbre)
## et sous les ombres et les décalcomanies. Le masque (1 pixel = 1 case, blanc = forêt) est
## calculé par l'outil de construction de la carte et **enregistré dans la scène**
## ([method create] : `ImageTexture` intégrée, aucune image à importer, aucune deuxième passe).

const SHADER: Shader = preload("res://game/world/lighting/shaders/forest_floor.gdshader")

## Taille en cases (celle de la carte).
@export var size: Vector2i = Vector2i(16, 16):
	set(value):
		size = value
		queue_redraw()
## Masque de la forêt ([method build_mask]), 1 pixel = 1 case.
@export var mask: Texture2D:
	set(value):
		mask = value
		_update_material()


func _init() -> void:
	z_index = WorldLighting.Z_GROUND
	_update_material()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size * Grid.TILE_SIZE)), Color.WHITE)


## Masque d'une carte de [param map_size] cases : blanc sur les cases de [param forest]
## (cases → vrai, ou tableau de Vector2i), noir ailleurs. Hors carte : ignoré.
static func build_mask(map_size: Vector2i, forest: Variant) -> Image:
	var image := Image.create(maxi(map_size.x, 1), maxi(map_size.y, 1), false, Image.FORMAT_L8)
	var cells: Array = (forest as Dictionary).keys() if forest is Dictionary else forest
	for cell: Vector2i in cells:
		if cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y:
			image.set_pixelv(cell, Color.WHITE)
	return image


## Calque prêt à poser dans la carte (nommé `ForestFloor`), masque intégré.
static func create(map_size: Vector2i, forest: Variant) -> ForestFloor:
	var floor_node := ForestFloor.new()
	floor_node.name = "ForestFloor"
	floor_node.size = map_size
	floor_node.mask = ImageTexture.create_from_image(build_mask(map_size, forest))
	return floor_node


## Vrai si la case [param cell] est de la forêt d'après le masque (hors masque : non).
func is_forest(cell: Vector2i) -> bool:
	if mask == null:
		return false
	var image := mask.get_image()
	if cell.x < 0 or cell.y < 0 or cell.x >= image.get_width() or cell.y >= image.get_height():
		return false
	return image.get_pixelv(cell).r > 0.5


func get_shader_material() -> ShaderMaterial:
	return material as ShaderMaterial


func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = SHADER
		material = shader_material
	shader_material.set_shader_parameter(&"forest_mask", mask)
	shader_material.set_shader_parameter(&"tile_size", float(Grid.TILE_SIZE))
