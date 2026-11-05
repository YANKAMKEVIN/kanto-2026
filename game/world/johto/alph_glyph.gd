class_name AlphGlyph
extends Node2D
## Signe gravé de la Galerie des Glyphes (JOHP1, dossier JOH-11 §8.1, JH-77 : Zarbi reste en décor,
## aucune donnée). Dessin provisoire qui « respire » doucement ; le lot d'art le remplace. Posé par
## `tools/build_johp1_maps.gd` sur les murs et sur les dalles : **le signe d'une bonne dalle est
## celui du mur qui lui correspond** (voir [enum Sign]).

## Les trois mots de la légende, et un signe sans mot, qui ne mène nulle part.
enum Sign { MEMORY, RETURN, BREATH, DECOY }

const SIZE: float = 30.0
const WIDTH: float = 6.0
const PULSE_SPEED: float = 1.1
const ALPHA_LOW: float = 0.55

@export var sign_kind: Sign = Sign.MEMORY
@export var color: Color = Color(0.9, 0.84, 0.62)

var _time: float = 0.0


func _ready() -> void:
	# Chaque signe a sa phase (décalée par sa position).
	_time = fmod(position.x * 0.013 + position.y * 0.007, TAU)


func _process(delta: float) -> void:
	_time += delta * PULSE_SPEED
	modulate.a = lerpf(ALPHA_LOW, 1.0, 0.5 + 0.5 * sin(_time))


func _draw() -> void:
	match sign_kind:
		Sign.MEMORY:
			draw_arc(Vector2.ZERO, SIZE, 0.0, TAU, 32, color, WIDTH, true)
			draw_circle(Vector2.ZERO, WIDTH * 1.4, color)
		Sign.RETURN:
			for row: int in 2:
				draw_polyline(_wave(row * 24.0 - 12.0), color, WIDTH, true)
		Sign.BREATH:
			for row: int in 3:
				var y := SIZE - row * 26.0
				draw_polyline(PackedVector2Array([Vector2(-SIZE, y), Vector2(0.0, y - 20.0),
					Vector2(SIZE, y)]), color, WIDTH, true)
		Sign.DECOY:
			draw_line(Vector2(-SIZE, -SIZE), Vector2(SIZE, SIZE), color, WIDTH, true)
			draw_line(Vector2(SIZE, -SIZE), Vector2(-SIZE, SIZE), color, WIDTH, true)


func _wave(y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 13:
		var x := -SIZE + i * SIZE / 6.0
		points.append(Vector2(x, y + sin(i * PI / 3.0) * 9.0))
	return points
