class_name CaptureResult
extends RefCounted
## Issue d'un lancer de Ball ([CaptureCalc], jalon 5 §2.4). Donnée pure.

## Le Pokémon est capturé.
var caught: bool = false
## Secousses à montrer (0 à 3) : min(tests réussis, 3). Une capture en montre toujours 3.
var shakes: int = 0


func _init(is_caught: bool = false, shake_count: int = 0) -> void:
	caught = is_caught
	shakes = shake_count
