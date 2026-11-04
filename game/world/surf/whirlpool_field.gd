class_name WhirlpoolField
extends Node2D
## Tourbillons de la Route 41 (Chapitre Johto, JOH7, `docs/tech/jalon-joh7.md` §2.1 ; dossier JOH-08
## §8, JH-48 : pas de Siphon, les tourbillons sont du **décor infranchissable** qui dessine les
## chenaux). Dessin seul : les cases sont bloquées par la carte (`blocked_cells`) et l'examen (M-4)
## est un [InteractPoint] posé par l'outil de construction. Une spirale claire qui tourne sur
## chaque case de [member cells], en provisoire jusqu'au lot d'art de Johto.

## Cases des tourbillons.
@export var cells: Array[Vector2i] = []

const TURN_SPEED: float = 2.4
const ARMS: int = 3
const RING_COLOR := Color(0.06, 0.18, 0.32, 0.55)
const FOAM_COLOR := Color(0.88, 0.96, 1.0, 0.8)

var _time: float = 0.0


func _process(delta: float) -> void:
	if cells.is_empty() or not is_visible_in_tree():
		return
	_time = fmod(_time + delta, 3600.0)
	queue_redraw()


func _draw() -> void:
	var tile := float(Grid.TILE_SIZE)
	# QA A17 : seuls les tourbillons à l'écran sont dessinés (la Route 41 en compte ~150 : 36 i/s
	# sans ce tri, 795 appels de dessin).
	var view := _visible_rect().grow(tile)
	for cell: Vector2i in cells:
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * tile - position
		if not view.has_point(center):
			continue
		draw_circle(center, tile * 0.42, RING_COLOR)
		# Phase propre à chaque case : les tourbillons voisins ne tournent pas en bloc.
		var phase := _time * TURN_SPEED + float((cell.x * 7 + cell.y * 13) % 11) * 0.6
		for arm: int in ARMS:
			var points := PackedVector2Array()
			for k: int in 9:
				var t := float(k) / 8.0
				var angle := phase + float(arm) * TAU / float(ARMS) + t * 2.6
				points.append(center + Vector2.from_angle(angle) * (6.0 + t * tile * 0.38))
			draw_polyline(points, FOAM_COLOR, 4.0)
		draw_circle(center, 7.0, FOAM_COLOR.darkened(0.4))


## Rectangle visible, dans le repère local (tout le champ hors d'un arbre de scène).
func _visible_rect() -> Rect2:
	if not is_inside_tree():
		return Rect2(-1e9, -1e9, 2e9, 2e9)
	var to_local := get_global_transform_with_canvas().affine_inverse()
	return to_local * get_viewport_rect()
