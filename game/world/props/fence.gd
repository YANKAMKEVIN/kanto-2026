class_name FenceProp
extends WorldProp
## Segment de clôture de [member length] cases (piquets blancs ou barrière bois).
##
## Horizontal : cases x 0..N−1 sur la rangée de l'ancre (ancre = case la plus à l'ouest).
## Vertical : cases y −(N−1)..0 (ancre = case la plus au sud, pour le y-sort).
## Le sprite répète la texture d'un segment (région de N cases).

@export_range(1, 64) var length: int = 1:
	set(value):
		length = maxi(value, 1)
		_update_sprite()
@export var vertical: bool = false:
	set(value):
		vertical = value
		_update_sprite()
@export var horizontal_texture: Texture2D
@export var vertical_texture: Texture2D


func _ready() -> void:
	super()
	_update_sprite()


func get_footprint() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i: int in length:
		cells.append(Vector2i(0, -i) if vertical else Vector2i(i, 0))
	return cells


func _update_sprite() -> void:
	var sprite := get_node_or_null(^"Sprite") as Sprite2D
	if sprite == null:
		return
	var tile := Grid.TILE_SIZE
	sprite.texture = vertical_texture if vertical else horizontal_texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if vertical:
		sprite.region_rect = Rect2(0, 0, tile, tile * length)
		sprite.offset = Vector2(-Grid.HALF_TILE, -tile * length)
	else:
		sprite.region_rect = Rect2(0, 0, tile * length, tile)
		sprite.offset = Vector2(-Grid.HALF_TILE, -tile)
