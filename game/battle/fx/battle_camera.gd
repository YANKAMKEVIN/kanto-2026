class_name BattleCamera
extends RefCounted
## Caméra de combat (chantier Combat vivant, `docs/tech/combat-vivant.md` §2.7, CV-3) : léger
## zoom et tremblement **du calque du combat** (le `CanvasLayer` de [BattleStage] : décor peint,
## Pokémon, effets), jamais de la HUD, qui vit sur son propre calque.
##
## Le zoom se fait autour d'un pivot écran (le point d'impact) : le calque reçoit
## `scale = zoom` et `offset = pivot × (1 − zoom) + secousse`. Le tremblement est un bruit doux
## et déterministe (somme de sinus, sans tirage : le RNG du combat n'est pas touché) qui
## s'amortit. Les plafonds (zoom ≤ 1,06, tremblement ≤ 6 px) sont déjà appliqués par
## [MoveFxPlan] ; [method set_pose] les borne encore par sûreté.
## Le fond flouté du monde (sans décor peint) est dessiné par la caméra du monde, hors du calque :
## il ne zoome pas [D].

## Plafonds de sûreté (les données font foi, `limits` de `families.json`).
const ZOOM_MAX: float = 1.1
const SHAKE_MAX: float = 8.0
## Fréquences du bruit (Hz) : deux sinus par axe, non multiples, pour un tremblement non périodique.
const SHAKE_FREQ := Vector4(23.0, 37.0, 29.0, 41.0)

var _layer: CanvasLayer
var _zoom: float = 1.0
var _pivot: Vector2 = Vector2.ZERO
var _shake: Vector2 = Vector2.ZERO


func _init(layer: CanvasLayer = null) -> void:
	_layer = layer


## Pose de la caméra : zoom [param zoom] autour de [param pivot] (px écran), plus la secousse
## [param shake] (px).
func set_pose(zoom: float, pivot: Vector2, shake: Vector2 = Vector2.ZERO) -> void:
	_zoom = clampf(zoom, 1.0, ZOOM_MAX)
	_pivot = pivot
	_shake = shake.limit_length(SHAKE_MAX)
	_apply()


func set_zoom(zoom: float) -> void:
	set_pose(zoom, _pivot, _shake)


func set_shake(shake: Vector2) -> void:
	set_pose(_zoom, _pivot, shake)


## Retour au cadrage normal (aucun zoom, aucune secousse).
func reset() -> void:
	set_pose(1.0, _pivot, Vector2.ZERO)


func get_zoom() -> float:
	return _zoom


func get_shake() -> Vector2:
	return _shake


func is_at_rest() -> bool:
	return is_equal_approx(_zoom, 1.0) and _shake.is_zero_approx()


## Décalage du calque pour un zoom [param zoom] autour de [param pivot], plus [param shake].
static func layer_offset(pivot: Vector2, zoom: float, shake: Vector2 = Vector2.ZERO) -> Vector2:
	return pivot * (1.0 - zoom) + shake


## Secousse à l'instant [param t] (s) d'un tremblement d'[param amplitude] px qui dure
## [param duration] s : bruit doux amorti (nul à la fin).
static func shake_at(t: float, amplitude: float, duration: float) -> Vector2:
	if duration <= 0.0 or amplitude <= 0.0 or t >= duration:
		return Vector2.ZERO
	var fade := 1.0 - clampf(t / duration, 0.0, 1.0)
	fade *= fade
	var x := sin(TAU * SHAKE_FREQ.x * t) * 0.6 + sin(TAU * SHAKE_FREQ.y * t + 1.3) * 0.4
	var y := sin(TAU * SHAKE_FREQ.z * t + 0.7) * 0.6 + sin(TAU * SHAKE_FREQ.w * t + 2.1) * 0.4
	return Vector2(x, y * 0.6) * amplitude * fade


func _apply() -> void:
	if _layer == null:
		return
	_layer.scale = Vector2.ONE * _zoom
	_layer.offset = layer_offset(_pivot, _zoom, _shake)
