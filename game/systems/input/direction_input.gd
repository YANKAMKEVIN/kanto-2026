class_name DirectionInput
extends RefCounted
## Réduit les entrées de déplacement à une seule direction de grille (4 directions).
##
## - [method update] : lit l'état des quatre actions move_* (clavier, ou actions
##   pressées par le joystick tactile) ; la dernière direction pressée encore tenue
##   l'emporte, comme dans Pokémon.
## - [method quantize] : convertit le vecteur analogique du joystick en direction
##   cardinale, avec zone morte et hystérésis pour éviter le va-et-vient en diagonale.

## Directions tenues, de la plus ancienne à la plus récente.
var _held: Array[Vector2i] = []


## Met à jour l'état des quatre directions et renvoie la direction retenue.
func update(up: bool, down: bool, left: bool, right: bool) -> Vector2i:
	_set_held(Vector2i.UP, up)
	_set_held(Vector2i.DOWN, down)
	_set_held(Vector2i.LEFT, left)
	_set_held(Vector2i.RIGHT, right)
	return get_direction()


## Direction retenue (Vector2i.ZERO si rien n'est tenu).
func get_direction() -> Vector2i:
	if _held.is_empty():
		return Vector2i.ZERO
	return _held.back()


func reset() -> void:
	_held.clear()


## [param vector] : déplacement du pouce normalisé par le rayon du joystick (longueur 0..1).
## [param previous] : direction renvoyée à l'image précédente. L'axe précédent est
## conservé tant que l'autre ne le dépasse pas de plus de [param hysteresis] (20 %).
static func quantize(
	vector: Vector2,
	previous: Vector2i = Vector2i.ZERO,
	deadzone: float = 0.3,
	hysteresis: float = 0.2
) -> Vector2i:
	if vector.length() < deadzone:
		return Vector2i.ZERO
	var ax := absf(vector.x)
	var ay := absf(vector.y)
	var horizontal: bool
	if previous.x != 0:
		horizontal = ay <= ax * (1.0 + hysteresis)
	elif previous.y != 0:
		horizontal = ax > ay * (1.0 + hysteresis)
	else:
		horizontal = ax >= ay
	if horizontal:
		return Vector2i.RIGHT if vector.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if vector.y > 0.0 else Vector2i.UP


func _set_held(direction: Vector2i, held: bool) -> void:
	var index := _held.find(direction)
	if held and index == -1:
		_held.append(direction)
	elif not held and index != -1:
		_held.remove_at(index)
