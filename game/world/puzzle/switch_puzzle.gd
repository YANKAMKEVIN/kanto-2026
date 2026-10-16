class_name SwitchPuzzle
extends RefCounted
## Puzzle des deux interrupteurs de l'Arène de Carmin (jalon 16, dossier 19 §9 et G-8 « Rouge/Bleu
## strict », `jalon-16.md` §2.6) : classe pure.
##
## Les objets à fouiller forment une grille de [member columns] × [member rows], numérotés de 1
## ligne par ligne (« index » des positions de la grille `tools/plans/carmin_arene.txt`). À
## [method start], le premier interrupteur est tiré au hasard ; au premier succès, le second est
## tiré parmi les **voisins orthogonaux** du premier. Toute erreur après le premier remet tout à
## zéro et tire un nouveau premier interrupteur. L'état n'est **jamais sauvegardé** : quitter la
## carte l'efface (une nouvelle instance au retour). Résolu, le puzzle reste résolu par le drapeau
## de la scène, pas ici.

## Résultat d'une fouille ([method search]).
enum Result { NOTHING, FIRST_FOUND, SOLVED, RESET }

var columns: int = 5
var rows: int = 3
var _rng: GameRng
## Index (1..n) du premier interrupteur, du second (0 tant que le premier n'est pas trouvé).
var _first: int = 0
var _second: int = 0
var _first_found: bool = false
var _solved: bool = false


func _init(p_rng: GameRng, p_columns: int = 5, p_rows: int = 3) -> void:
	_rng = p_rng
	columns = p_columns
	rows = p_rows


## Nombre d'objets à fouiller.
func size() -> int:
	return columns * rows


## Tire le premier interrupteur (entrée dans la carte, ou après une erreur).
func start() -> void:
	_first = _rng.pick_index(size()) + 1
	_second = 0
	_first_found = false
	_solved = false


## Fouille l'objet [param index] (1..n). Hors bornes : NOTHING.
func search(index: int) -> Result:
	if _solved or index < 1 or index > size():
		return Result.NOTHING
	if not _first_found:
		if index != _first:
			return Result.NOTHING
		_first_found = true
		var around := neighbors(_first)
		_second = around[_rng.pick_index(around.size())]
		return Result.FIRST_FOUND
	if index == _second:
		_solved = true
		return Result.SOLVED
	start()
	return Result.RESET


## Voisins orthogonaux de [param index] dans la grille (index 1..n), dans l'ordre haut, bas,
## gauche, droite.
func neighbors(index: int) -> Array[int]:
	var col := (index - 1) % columns
	@warning_ignore("integer_division")
	var row := (index - 1) / columns
	var result: Array[int] = []
	for step: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var c := col + step.x
		var r := row + step.y
		if c >= 0 and c < columns and r >= 0 and r < rows:
			result.append(r * columns + c + 1)
	return result


func is_first_found() -> bool:
	return _first_found


func is_solved() -> bool:
	return _solved


## Premier interrupteur tiré (tests, QA).
func first() -> int:
	return _first


## Second interrupteur, 0 tant que le premier n'est pas trouvé (tests, QA).
func second() -> int:
	return _second
