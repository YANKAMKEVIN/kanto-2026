class_name RubbleBurst
extends Node2D
## Petit éboulis sous les pieds (jalon 12, T20 ; dossier 15 §6, dossier 04 : intro ≤ 2 s) quand
## une rencontre démarre sur les gravats d'une grotte : quelques cailloux roulent hors de la case
## et un peu de poussière se lève puis retombe. Présentation pure, modèle de [GrassRustle] :
## aucune logique de jeu, un seul Tween, le nœud se libère à la fin ([method burst]).
##
## Provisoire (assets finaux plus tard) : cailloux en [Polygon2D] bruns et poussière en disques
## translucides, sans texture. Dimensions à l'échelle d'une case (96 px), origine au centre de
## la case (comme [GrassRustle]).

## Cailloux : nombre, teintes (brun des gravats et brun sombre : lisibles sur le sol ardoise
## clair comme sur les gravats), rayon.
const PEBBLE_COUNT: int = 7
const PEBBLE_COLOR := Color("#8a7458")
const PEBBLE_COLOR_DARK := Color("#4a3f35")
const PEBBLE_RADIUS: float = 12.0
## Distance parcourue par un caillou (px monde) et petit saut au départ.
const ROLL_DISTANCE: float = 64.0
const ROLL_HOP: float = 20.0
## Poussière : nombre de bouffées, teinte, rayon de départ et d'arrivée.
const DUST_COUNT: int = 3
const DUST_COLOR := Color(0.85, 0.80, 0.71, 0.7)
const DUST_RADIUS_FROM: float = 14.0
const DUST_RADIUS_TO: float = 50.0
## Durée totale (s) à la vitesse 1 (`jalon-12.md` §2.5 : ≈ 0,6 s).
const DURATION: float = 0.6
## Côtés d'un disque de poussière et d'un caillou.
const _DUST_SIDES: int = 12
const _PEBBLE_SIDES: int = 6
## Part finale de la durée pendant laquelle les cailloux s'effacent.
const _FADE_SHARE: float = 0.35

const SCENE_PATH: String = "res://game/world/rubble/rubble_burst.tscn"

var _pebbles: Array[Polygon2D] = []
var _dust: Array[Polygon2D] = []
## Direction de chaque caillou (vecteur au sol), fixée à la construction.
var _directions: Array[Vector2] = []


## Crée un éboulis, enfant de [param parent], au point monde [param world_pos].
static func spawn(parent: Node, world_pos: Vector2) -> RubbleBurst:
	var node := (load(SCENE_PATH) as PackedScene).instantiate() as RubbleBurst
	parent.add_child(node)
	node.global_position = world_pos
	return node


func _ready() -> void:
	if _pebbles.is_empty():
		_build()


## Coroutine : joue l'éboulis ([constant DURATION]) puis se libère. [param speed_scale] = 0 :
## instantané (tests).
func burst(speed_scale: float = 1.0) -> void:
	if _pebbles.is_empty():
		_build()
	var tween := create_tween()
	tween.tween_method(_apply, 0.0, 1.0, DURATION)
	if speed_scale <= 0.0:
		tween.custom_step(1000.0)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	queue_free()


## Cailloux et poussière : nombre de nœuds dessinés (tests).
func get_piece_count() -> int:
	return _pebbles.size() + _dust.size()


## Progression [param t] de 0 à 1 : les cailloux s'éloignent en sautillant (rebond amorti) et
## s'effacent sur la fin ; la poussière gonfle puis s'efface.
func _apply(t: float) -> void:
	var ease_out := 1.0 - (1.0 - t) * (1.0 - t)
	var hop := absf(sin(t * PI * 2.0)) * (1.0 - t) * ROLL_HOP
	var fade := clampf((1.0 - t) / _FADE_SHARE, 0.0, 1.0)
	for i: int in _pebbles.size():
		var pebble := _pebbles[i]
		pebble.position = _directions[i] * ROLL_DISTANCE * ease_out + Vector2(0.0, -hop)
		pebble.rotation = t * TAU * (1.0 if i % 2 == 0 else -1.0)
		pebble.modulate.a = fade
	var grow := lerpf(DUST_RADIUS_FROM, DUST_RADIUS_TO, ease_out) / DUST_RADIUS_FROM
	for puff: Polygon2D in _dust:
		puff.scale = Vector2(grow, grow * 0.6)
		puff.modulate.a = 1.0 - t


func _build() -> void:
	for i: int in DUST_COUNT:
		var puff := Polygon2D.new()
		puff.polygon = _disc(DUST_RADIUS_FROM, _DUST_SIDES)
		puff.color = DUST_COLOR
		var angle := TAU * float(i) / float(DUST_COUNT)
		puff.position = Vector2(cos(angle), sin(angle) * 0.5) * 12.0
		add_child(puff)
		_dust.append(puff)
	for i: int in PEBBLE_COUNT:
		var pebble := Polygon2D.new()
		# Cailloux de tailles variées selon le rang (aucun hasard : rendu reproductible).
		pebble.polygon = _disc(PEBBLE_RADIUS * (0.7 + 0.15 * float(i % 3)), _PEBBLE_SIDES)
		pebble.color = PEBBLE_COLOR if i % 2 == 0 else PEBBLE_COLOR_DARK
		var angle := TAU * (float(i) + 0.5) / float(PEBBLE_COUNT)
		# Ellipse aplatie : le sol est vu de trois quarts, les cailloux roulent au sol.
		_directions.append(Vector2(cos(angle), sin(angle) * 0.55))
		add_child(pebble)
		_pebbles.append(pebble)


static func _disc(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in sides:
		var angle := TAU * float(i) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
