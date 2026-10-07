class_name EvolutionRays
extends Control
## Rayons de lumière de l'écran d'évolution (jalon-09.md §2.3.3) : un éventail de pinceaux
## qui partent du centre du contrôle et s'effacent vers l'extérieur, tracés une fois
## (UiTokens.EVOLUTION_RAY_*). La teinte et l'opacité viennent du modulate ; la rotation
## (autour du centre) est menée par l'écran. Purement visuel : il ignore le toucher.

## Longueur relative des rayons, en alternance (un long, un court) : l'éventail respire.
const SHORT_RAY := 0.72
## Lumière de l'axe d'un rayon à mi-course (part de sa longueur), pour des bords adoucis.
const CORE_REACH := 0.55
const CORE_ALPHA := 0.45


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_on_resized()


func _draw() -> void:
	var center := size * 0.5
	var inner := UiTokens.EVOLUTION_RAY_COLOR
	var clear := inner
	clear.a = 0.0
	var core := inner
	core.a = CORE_ALPHA
	for i: int in UiTokens.EVOLUTION_RAY_COUNT:
		var angle := TAU * float(i) / float(UiTokens.EVOLUTION_RAY_COUNT)
		var length := UiTokens.EVOLUTION_RAY_RADIUS * (1.0 if i % 2 == 0 else SHORT_RAY)
		var half := UiTokens.EVOLUTION_RAY_HALF_WIDTH
		var axis := Vector2.from_angle(angle)
		var mid := center + axis * length * CORE_REACH
		var left := center + Vector2.from_angle(angle - half) * length
		var right := center + Vector2.from_angle(angle + half) * length
		# Bords adoucis : l'axe porte la lumière, les côtés sont transparents.
		draw_polygon(PackedVector2Array([center, left, mid]),
			PackedColorArray([inner, clear, core]))
		draw_polygon(PackedVector2Array([center, mid, right]),
			PackedColorArray([inner, core, clear]))
		draw_polygon(PackedVector2Array([mid, left, center + axis * length]),
			PackedColorArray([core, clear, clear]))
		draw_polygon(PackedVector2Array([mid, center + axis * length, right]),
			PackedColorArray([core, clear, clear]))


func _on_resized() -> void:
	pivot_offset = size * 0.5
	queue_redraw()
