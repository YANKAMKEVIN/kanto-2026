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
## Jalon 8 (§1.2 B) : une case peut avoir une **valeur partielle** (0,45, 0,55 : sous-bois en
## taches bruitées qui gagne la prairie de la lisière) ; seules les cases pleines (blanches) sont
## « de la forêt » pour [method is_forest].

const SHADER: Shader = preload("res://game/world/lighting/shaders/forest_floor.gdshader")
## Valeur du masque au-dessus de laquelle une case est de la forêt (pleine) ; en dessous, une
## valeur partielle ne fait que des taches de sous-bois.
const FOREST_THRESHOLD: float = 0.95

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
## (tableau de Vector2i, ou cases → vrai), noir ailleurs. Dans un dictionnaire, une valeur
## **nombre** dans [0, 1] donne la valeur de la case (sous-bois partiel ; vrai = 1, faux = 0).
## Hors carte : ignoré.
static func build_mask(map_size: Vector2i, forest: Variant) -> Image:
	var image := Image.create(maxi(map_size.x, 1), maxi(map_size.y, 1), false, Image.FORMAT_L8)
	var values: Dictionary = forest if forest is Dictionary else {}
	var cells: Array = values.keys() if forest is Dictionary else forest
	for cell: Vector2i in cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= map_size.x or cell.y >= map_size.y:
			continue
		var value := 1.0
		if values.has(cell):
			var raw: Variant = values[cell]
			if raw is float or raw is int:
				value = clampf(float(raw), 0.0, 1.0)
			elif raw is bool and not raw:
				value = 0.0
		image.set_pixelv(cell, Color(value, value, value))
	return image


## Calque prêt à poser dans la carte (nommé `ForestFloor`), masque intégré.
static func create(map_size: Vector2i, forest: Variant) -> ForestFloor:
	var floor_node := ForestFloor.new()
	floor_node.name = "ForestFloor"
	floor_node.size = map_size
	floor_node.mask = ImageTexture.create_from_image(build_mask(map_size, forest))
	return floor_node


## Vrai si la case [param cell] est de la forêt d'après le masque (pleine ; valeur partielle ou
## hors masque : non).
func is_forest(cell: Vector2i) -> bool:
	if mask == null:
		return false
	var image := mask.get_image()
	if cell.x < 0 or cell.y < 0 or cell.x >= image.get_width() or cell.y >= image.get_height():
		return false
	return image.get_pixelv(cell).r > FOREST_THRESHOLD


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
