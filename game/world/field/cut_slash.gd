class_name CutSlash
extends Node2D
## Effet de Coupe **provisoire** (jalon 16) : un trait de lame blanc qui balaie l'obstacle en
## diagonale puis s'efface. Dessiné en code en attendant l'art `FX_COUPE` (série 18), qui le
## remplacera au T10. Deux nœuds au plus (celui-ci), aucune texture.

## Longueur et épaisseur du trait (px de référence), couleurs : valeurs par défaut (règle 4).
const LENGTH: float = 150.0
const WIDTH: float = 10.0
const CORE := Color(1.0, 1.0, 1.0, 0.95)
const GLOW := Color(0.85, 0.95, 1.0, 0.35)
## Part de la durée passée à tracer (le reste : effacement).
const DRAW_PART: float = 0.55

var _progress: float = 0.0
var _alpha: float = 1.0


func _init() -> void:
	name = "CutSlash"
	z_index = 50


## Coroutine : trace le trait en [param seconds] s (tracé puis effacement).
func play(seconds: float) -> void:
	_progress = 0.0
	_alpha = 1.0
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, seconds * DRAW_PART) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_alpha, 1.0, 0.0, seconds * (1.0 - DRAW_PART))
	await tween.finished


## Avancée du tracé (0 à 1), pour les tests.
func get_progress() -> float:
	return _progress


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _set_alpha(value: float) -> void:
	_alpha = value
	queue_redraw()


func _draw() -> void:
	if _progress <= 0.0 or _alpha <= 0.0:
		return
	var start := Vector2(-LENGTH, -LENGTH) * 0.5
	var finish := start.lerp(-start, _progress)
	var glow := Color(GLOW, GLOW.a * _alpha)
	var core := Color(CORE, CORE.a * _alpha)
	draw_line(start, finish, glow, WIDTH * 2.6, true)
	draw_line(start, finish, core, WIDTH, true)
	draw_circle(finish, WIDTH * 0.9, core)
