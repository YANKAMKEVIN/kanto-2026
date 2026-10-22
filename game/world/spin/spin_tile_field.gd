class_name SpinTileField
extends Node2D
## Dalles tournantes d'une carte (jalon 20 T4, docs/tech/jalon-20.md §2.4.2) : **nœud de données
## seul**, posé sous le nom `SpinTiles` par l'outil de construction du repaire (T20). Les flèches
## et les disques d'arrêt sont peints dans le décor ; ce nœud ne dessine rien et ne traite aucune
## entrée. Le directeur (T19) le trouve par son groupe et applique [SpinTileRules].

const GROUP: StringName = &"spin_tile_field"

## Dalle → direction de glisse (vecteur cardinal).
@export var arrows: Dictionary[Vector2i, Vector2i] = {}
## Cases d'arrêt (disques clairs).
@export var stops: Array[Vector2i] = []


func _enter_tree() -> void:
	add_to_group(GROUP)


func is_arrow(cell: Vector2i) -> bool:
	return arrows.has(cell)


## Trajet depuis la dalle [param start] (voir [method SpinTileRules.slide]).
func slide_from(start: Vector2i, walkable: Callable) -> SpinSlide:
	return SpinTileRules.slide(start, arrows, stops, walkable)


## Case stable pour une reprise (voir [method SpinTileRules.safe_cell]).
func safe_cell(cell: Vector2i, walkable: Callable) -> Vector2i:
	return SpinTileRules.safe_cell(cell, arrows, stops, walkable)


## Erreurs de données (voir [method SpinTileRules.check_field]).
func check(walkable: Callable) -> PackedStringArray:
	return SpinTileRules.check_field(arrows, stops, walkable)
