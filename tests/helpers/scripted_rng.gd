extends GameRng
## GameRng des tests : [method roll] renvoie les valeurs imposées, dans l'ordre.
##
## Chaque valeur est le résultat d'un [method GameRng.roll] (1..n), donc aussi celui des
## méthodes qui en dérivent : [code]range_int(85, 100)[/code] avec la valeur 16 → 100,
## [code]chance(1, 24)[/code] avec la valeur 1 → vrai. Une file vide ou une valeur hors de
## 1..n est une erreur (push_error, le test échoue) : un tirage imprévu ne passe pas inaperçu.
## Utilisation : [code]const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")[/code].

var _queue: Array[int] = []
## Nombre de tirages demandés depuis la création.
var calls: int = 0


func _init(values: Array[int] = []) -> void:
	super._init(0)
	_queue.assign(values)


## Ajoute des valeurs à la fin de la file.
func push(values: Array[int]) -> void:
	_queue.append_array(values)


## Valeurs pas encore consommées.
func remaining() -> int:
	return _queue.size()


func roll(n: int) -> int:
	calls += 1
	if _queue.is_empty():
		push_error("ScriptedRng : file vide (tirage %d, roll(%d))" % [calls, n])
		return 1
	var value: int = _queue.pop_front()
	if value < 1 or value > n:
		push_error("ScriptedRng : valeur %d hors de 1..%d (tirage %d)" % [value, n, calls])
		return clampi(value, 1, maxi(n, 1))
	return value
