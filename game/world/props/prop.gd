class_name WorldProp
extends Node2D
## Élément de décor HD unique (maison, arbre, rocher, lampadaire…) posé dans `Entities`.
##
## Origine aux pieds : `position = Grid.cell_to_world(ancre)`. Le `Sprite2D` %Sprite
## est décalé pour que son bas tombe sur l'origine (y-sort naturel). L'empreinte
## liste les cases solides, relatives à la case d'ancrage (x vers l'est, y vers le sud).
## [GameMap] les marque dans [GridWorld] au chargement.

## Opacité du sprite quand il cache le joueur.
const COVERED_ALPHA: float = 0.5
## Durée du fondu (s).
const FADE_DURATION: float = 0.15

## Cases solides relatives à la case d'ancrage.
@export var footprint: Array[Vector2i] = [Vector2i.ZERO]
## Devient semi-transparent quand le joueur passe derrière (feuillages, toits).
@export var fade_when_covering: bool = false

var _target: Node2D


func _ready() -> void:
	set_process(fade_when_covering)


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	var sprite := get_node(^"%Sprite") as Sprite2D
	var covering := _target != null and covers(
		sprite.get_global_transform() * sprite.get_rect(), global_position.y,
		(_target as Player).get_body_rect())
	var alpha := COVERED_ALPHA if covering else 1.0
	sprite.modulate.a = move_toward(sprite.modulate.a, alpha,
		delta * (1.0 - COVERED_ALPHA) / FADE_DURATION)


## Vrai si un sprite de décor (rectangle global, pieds en `base_y`) masque le corps
## `body` : le corps est derrière (pieds plus au nord) et les rectangles se chevauchent.
static func covers(sprite_rect: Rect2, base_y: float, body: Rect2) -> bool:
	return body.end.y < base_y and sprite_rect.intersects(body)


## Case d'ancrage (celle qui contient l'origine).
func get_anchor_cell() -> Vector2i:
	return Grid.world_to_cell(position)


## Empreinte relative (les sous-classes peuvent la calculer).
func get_footprint() -> Array[Vector2i]:
	return footprint


## Cases solides absolues sur la carte.
func get_solid_cells() -> Array[Vector2i]:
	var anchor := get_anchor_cell()
	var cells: Array[Vector2i] = []
	for offset: Vector2i in get_footprint():
		cells.append(anchor + offset)
	return cells
