class_name WaterfallDecor
extends Node2D
## Cascade du B2F des Îles Tourbillon (JOH7, `docs/tech/jalon-joh7.md` §2.1, dossier JOH-08 §3) :
## dessin seul (les cases `F` sont bloquées par la carte), bandes d'eau claire qui tombent sur
## chaque case de [member cells], en provisoire jusqu'au lot d'art de Johto.

## Cases de la cascade.
@export var cells: Array[Vector2i] = []

const FALL_SPEED: float = 260.0
const BASE_COLOR := Color(0.55, 0.78, 0.95, 0.9)
const STREAK_COLOR := Color(0.95, 0.99, 1.0, 0.85)

var _time: float = 0.0


func _process(delta: float) -> void:
	if cells.is_empty() or not is_visible_in_tree():
		return
	_time = fmod(_time + delta, 3600.0)
	queue_redraw()


func _draw() -> void:
	var tile := float(Grid.TILE_SIZE)
	for cell: Vector2i in cells:
		var origin := Vector2(cell) * tile - position
		draw_rect(Rect2(origin, Vector2(tile, tile)), BASE_COLOR)
		for lane: int in 4:
			var x := origin.x + 12.0 + float(lane) * 22.0
			var y := fmod(_time * FALL_SPEED + float(lane * 37 + cell.x * 19), tile)
			draw_line(Vector2(x, origin.y + y), Vector2(x, origin.y + minf(y + 34.0, tile)),
				STREAK_COLOR, 5.0)
