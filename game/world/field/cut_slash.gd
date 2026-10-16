class_name CutSlash
extends Node2D
## Effet de Coupe (jalon 16, série 18 `FX_COUPE`, T10) : 4 images peintes (demi-trait, arc
## complet, second trait en X avec les feuilles, dissipation), centrées sur l'obstacle. Les trois
## premières défilent pendant le tracé ([constant DRAW_PART] de la durée), la quatrième
## s'efface pendant le reste. Un seul `Sprite2D` (deux nœuds avec celui-ci). « Réduire les
## animations » ne joue pas cet effet (`FieldMoveStage.stages` : fondu seul).

const FRAMES: Array[String] = [
	"res://assets/world/fx/fx_coupe_01.png",
	"res://assets/world/fx/fx_coupe_02.png",
	"res://assets/world/fx/fx_coupe_03.png",
	"res://assets/world/fx/fx_coupe_04.png",
]
## Part de la durée passée à tracer (images 1 à 3 ; le reste : l'image 4 s'efface).
const DRAW_PART: float = 0.55

var _progress: float = 0.0
var _alpha: float = 1.0
var _textures: Array[Texture2D] = []
var _sprite: Sprite2D


func _init() -> void:
	name = "CutSlash"
	z_index = 50
	for path: String in FRAMES:
		_textures.append(load(path) as Texture2D)
	_sprite = Sprite2D.new()
	_sprite.name = "Frame"
	_sprite.visible = false
	add_child(_sprite)


## Coroutine : joue l'effet en [param seconds] s (tracé puis effacement).
func play(seconds: float) -> void:
	_progress = 0.0
	_alpha = 1.0
	_refresh()
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, seconds * DRAW_PART)
	tween.tween_method(_set_alpha, 1.0, 0.0, seconds * (1.0 - DRAW_PART))
	await tween.finished


## Avancée du tracé (0 à 1), pour les tests.
func get_progress() -> float:
	return _progress


## Image affichée (0 à 3), -1 avant le début ; pour les tests et les captures.
func get_frame() -> int:
	if not _sprite.visible:
		return -1
	return _textures.find(_sprite.texture)


func _set_progress(value: float) -> void:
	_progress = value
	_refresh()


func _set_alpha(value: float) -> void:
	_alpha = value
	_refresh()


func _refresh() -> void:
	if _progress <= 0.0 or _alpha <= 0.0:
		_sprite.visible = false
		return
	var frame := 3 if _progress >= 1.0 else mini(2, floori(_progress * 3.0))
	_sprite.texture = _textures[frame]
	_sprite.modulate.a = _alpha
	_sprite.visible = true
