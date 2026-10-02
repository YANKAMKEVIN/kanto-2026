class_name GrassRustle
extends Node2D
## Petit froissement d'herbe (jalon 5 §3.5, §3.7) : quelques brins verts qui s'écartent puis
## reviennent, quand une rencontre démarre (herbe qui bouge à l'origine). Présentation pure :
## aucune logique de jeu, un seul Tween, le nœud se libère à la fin ([method rustle]).
##
## Provisoire (assets finaux plus tard) : des brins en [Polygon2D] verts, sans texture, lisses
## au filtre par défaut du projet. Dimensions à l'échelle d'une case (96 px).

## Brins et leur teinte (deux verts clairs, lisibles sur les hautes herbes foncées).
const BLADE_COUNT: int = 5
const BLADE_COLOR := Color("#8fd06a")
const BLADE_COLOR_DARK := Color("#6cb84a")
## Demi-largeur de la touffe et hauteur des brins (px monde).
const SPREAD: float = 40.0
const BLADE_HEIGHT: float = 44.0
const BLADE_HALF_WIDTH: float = 4.0
## Un aller-retour et nombre d'oscillations amorties (~0,25 s au total, §3.7).
const SWAY_TIME: float = 0.06
const SWAYS: int = 2
## Angle d'écartement maximal (rad) à amplitude 1.
const SWAY_ANGLE: float = 0.55
## Amplitude « rencontre » (§3.7 : « ×2 plus ample » qu'un simple pas dans l'herbe).
const AMPLITUDE_ENCOUNTER: float = 2.0

const SCENE_PATH: String = "res://game/world/grass/grass_rustle.tscn"

var _blades: Array[Polygon2D] = []


## Crée un froissement, enfant de [param parent], au point monde [param world_pos].
static func spawn(parent: Node, world_pos: Vector2) -> GrassRustle:
	var rustle := (load(SCENE_PATH) as PackedScene).instantiate() as GrassRustle
	parent.add_child(rustle)
	rustle.global_position = world_pos
	return rustle


func _ready() -> void:
	if _blades.is_empty():
		_build()


## Coroutine : joue le froissement puis se libère. [param speed_scale] = 0 : instantané
## (tests) ; [param amplitude] : ampleur de l'écartement ([constant AMPLITUDE_ENCOUNTER]).
func rustle(speed_scale: float = 1.0, amplitude: float = AMPLITUDE_ENCOUNTER) -> void:
	if _blades.is_empty():
		_build()
	var tween := create_tween()
	var total := SWAY_TIME * SWAYS * 2.0
	tween.tween_method(_apply_sway.bind(amplitude), 0.0, 1.0, total)
	if speed_scale <= 0.0:
		tween.custom_step(1000.0)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	queue_free()


## Oscillation amortie : [param t] va de 0 à 1, les brins pairs et impairs partent en sens
## opposés, l'amplitude décroît vers 0 (l'herbe revient droite).
func _apply_sway(t: float, amplitude: float) -> void:
	var wave := sin(t * PI * SWAYS * 2.0) * (1.0 - t)
	for i: int in _blades.size():
		var dir := 1.0 if i % 2 == 0 else -1.0
		_blades[i].rotation = wave * SWAY_ANGLE * amplitude * dir


func _build() -> void:
	var points := PackedVector2Array([
		Vector2(-BLADE_HALF_WIDTH, 0.0), Vector2(BLADE_HALF_WIDTH, 0.0),
		Vector2(0.0, -BLADE_HEIGHT)])
	for i: int in BLADE_COUNT:
		var blade := Polygon2D.new()
		blade.polygon = points
		blade.color = BLADE_COLOR if i % 2 == 0 else BLADE_COLOR_DARK
		var t := 0.0 if BLADE_COUNT <= 1 else float(i) / float(BLADE_COUNT - 1)
		blade.position = Vector2(lerpf(-SPREAD, SPREAD, t), 0.0)
		add_child(blade)
		_blades.append(blade)
