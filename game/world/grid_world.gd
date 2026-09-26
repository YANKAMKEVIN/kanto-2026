class_name GridWorld
extends RefCounted
## Règles d'accès aux cases d'une carte : limites, cases solides, eau, rebords, occupation.
##
## Classe pure, sans dépendance à l'arbre de scènes. [GameMap] la remplit au chargement
## à partir des données des tuiles (solid, water, ledge) et des empreintes des props.
## La seule question « puis-je entrer ? » est tranchée par [method can_enter] ;
## [method get_step_target] en dérive la case d'arrivée réelle (saut de rebord compris).

## Rebord sautable : direction dans laquelle on peut le franchir.
## Valeurs identiques à la donnée de tuile `ledge` du TileSet.
enum Ledge { NONE = 0, DOWN = 1, LEFT = 2, RIGHT = 3 }

const _FLAG_SOLID: int = 1
const _FLAG_WATER: int = 2
const _LEDGE_SHIFT: int = 2
const _LEDGE_MASK: int = 0b1100

## Ordre d'exploration de [method find_path] (chemins reproductibles).
const _PATH_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]

var _size: Vector2i
var _flags: PackedByteArray = PackedByteArray()
var _occupants: Dictionary[Vector2i, Object] = {}


func _init(map_size: Vector2i) -> void:
	_size = Vector2i(maxi(map_size.x, 0), maxi(map_size.y, 0))
	_flags.resize(_size.x * _size.y)
	_flags.fill(0)


## Direction de franchissement d'un rebord (Vector2i.ZERO pour [constant Ledge.NONE]).
static func ledge_direction(ledge: Ledge) -> Vector2i:
	match ledge:
		Ledge.DOWN:
			return Vector2i.DOWN
		Ledge.LEFT:
			return Vector2i.LEFT
		Ledge.RIGHT:
			return Vector2i.RIGHT
	return Vector2i.ZERO


func get_size() -> Vector2i:
	return _size


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


## Marque une case solide (ou la libère). Renvoie false si la case est hors carte.
func set_solid(cell: Vector2i, solid: bool = true) -> bool:
	return _set_flag(cell, _FLAG_SOLID, solid)


func is_solid(cell: Vector2i) -> bool:
	return _has_flag(cell, _FLAG_SOLID)


## Marque une case d'eau (infranchissable à pied). Renvoie false si hors carte.
func set_water(cell: Vector2i, water: bool = true) -> bool:
	return _set_flag(cell, _FLAG_WATER, water)


func is_water(cell: Vector2i) -> bool:
	return _has_flag(cell, _FLAG_WATER)


## Pose un rebord sur une case. Renvoie false si hors carte.
func set_ledge(cell: Vector2i, ledge: Ledge) -> bool:
	if not is_in_bounds(cell):
		return false
	var i := _index(cell)
	_flags[i] = (_flags[i] & ~_LEDGE_MASK) | ((ledge << _LEDGE_SHIFT) & _LEDGE_MASK)
	return true


func get_ledge(cell: Vector2i) -> Ledge:
	if not is_in_bounds(cell):
		return Ledge.NONE
	return ((_flags[_index(cell)] & _LEDGE_MASK) >> _LEDGE_SHIFT) as Ledge


## Marque solides les cellules d'une empreinte de prop, relatives à sa case d'ancrage.
## Renvoie le nombre de cellules marquées (les cellules hors carte sont ignorées).
func add_solid_footprint(anchor: Vector2i, footprint: Array[Vector2i]) -> int:
	var marked := 0
	for offset: Vector2i in footprint:
		if set_solid(anchor + offset):
			marked += 1
	return marked


## Entité qui occupe la case, ou null. Une entité libérée ne compte plus.
func get_occupant(cell: Vector2i) -> Object:
	if not _occupants.has(cell):
		return null
	if not is_instance_valid(_occupants[cell]):
		_occupants.erase(cell)
		return null
	return _occupants[cell]


func is_occupied(cell: Vector2i) -> bool:
	return get_occupant(cell) != null


## Réserve une case pour une entité. Échoue hors carte ou si une autre entité l'occupe.
func occupy(cell: Vector2i, entity: Object) -> bool:
	if entity == null or not is_in_bounds(cell):
		return false
	var current := get_occupant(cell)
	if current != null and current != entity:
		return false
	_occupants[cell] = entity
	return true


## Libère une case, seulement si c'est bien [param entity] qui l'occupe.
func release(cell: Vector2i, entity: Object) -> void:
	if get_occupant(cell) == entity:
		_occupants.erase(cell)


## Déplace l'occupation d'une entité d'une case à une autre.
func move_occupant(entity: Object, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not occupy(to_cell, entity):
		return false
	if from_cell != to_cell:
		release(from_cell, entity)
	return true


## Règle unique d'accès : peut-on entrer dans [param cell] en se déplaçant vers
## [param direction] ? [param mover] est ignoré dans le test d'occupation (sa propre case).
## Refus : direction non cardinale, hors carte, solide, eau, case occupée par une autre
## entité, rebord abordé dans une autre direction que la sienne.
func can_enter(cell: Vector2i, direction: Vector2i, mover: Object = null) -> bool:
	if not Grid.is_cardinal(direction) or not is_in_bounds(cell):
		return false
	var flags := _flags[_index(cell)]
	if flags & (_FLAG_SOLID | _FLAG_WATER):
		return false
	var ledge := ((flags & _LEDGE_MASK) >> _LEDGE_SHIFT) as Ledge
	if ledge != Ledge.NONE and ledge_direction(ledge) != direction:
		return false
	var occupant := get_occupant(cell)
	return occupant == null or occupant == mover


## Case d'arrivée d'un pas depuis [param from_cell] vers [param direction] :
## la case voisine, la case après un rebord (saut de 2 cases), ou [param from_cell]
## si le pas est impossible.
func get_step_target(from_cell: Vector2i, direction: Vector2i, mover: Object = null) -> Vector2i:
	var next := from_cell + direction
	if not can_enter(next, direction, mover):
		return from_cell
	if get_ledge(next) == Ledge.NONE:
		return next
	var landing := next + direction
	if not can_enter(landing, direction, mover) or get_ledge(landing) != Ledge.NONE:
		return from_cell
	return landing


## Cases atteignables à pied depuis [param start] (start compris), en respectant
## rebords et occupation. Sert aux tests d'acceptation des cartes.
func find_reachable(start: Vector2i, mover: Object = null) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {}
	if not is_in_bounds(start):
		return reached
	var directions: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	]
	var queue: Array[Vector2i] = [start]
	reached[start] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for direction: Vector2i in directions:
			var target := get_step_target(cell, direction, mover)
			if target != cell and not reached.has(target):
				reached[target] = true
				queue.append(target)
	return reached


## Vrai si une entité peut **se tenir** sur [param cell] : dans la carte, ni solide, ni eau,
## ni rebord, et libre (ou occupée par [param mover]). Sert à choisir une case d'arrivée
## (scènes : « à côté du joueur »).
func is_free(cell: Vector2i, mover: Object = null) -> bool:
	if not is_in_bounds(cell):
		return false
	var flags := _flags[_index(cell)]
	if flags & (_FLAG_SOLID | _FLAG_WATER | _LEDGE_MASK):
		return false
	var occupant := get_occupant(cell)
	return occupant == null or occupant == mover


## Plus court chemin à pied de [param from] à [param to], sous forme de **liste de
## directions** (un élément par pas ; un saut de rebord compte pour un pas). Mêmes règles que
## [method get_step_target] (solides, eau, rebords, occupants autres que [param mover]).
## Parcours en largeur, directions essayées dans l'ordre haut, bas, gauche, droite : à
## longueur égale, le chemin est toujours le même. Vide si [param from] == [param to], si
## l'une des deux cases est hors carte ou si [param to] est inaccessible.
## Alloue : à appeler au début d'un déplacement, jamais à chaque image.
func find_path(from: Vector2i, to: Vector2i, mover: Object = null) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if from == to or not is_in_bounds(from) or not is_in_bounds(to):
		return path
	# Case atteinte → case d'où l'on vient, et direction du pas qui y mène.
	var previous: Dictionary[Vector2i, Vector2i] = {from: from}
	var step_of: Dictionary[Vector2i, Vector2i] = {}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in _PATH_DIRECTIONS:
			var target := get_step_target(cell, direction, mover)
			if target == cell or previous.has(target):
				continue
			previous[target] = cell
			step_of[target] = direction
			if target == to:
				var back := to
				while back != from:
					path.append(step_of[back])
					back = previous[back]
				path.reverse()
				return path
			queue.append(target)
	return path


func _index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x


func _set_flag(cell: Vector2i, flag: int, value: bool) -> bool:
	if not is_in_bounds(cell):
		return false
	var i := _index(cell)
	if value:
		_flags[i] = _flags[i] | flag
	else:
		_flags[i] = _flags[i] & ~flag
	return true


func _has_flag(cell: Vector2i, flag: int) -> bool:
	return is_in_bounds(cell) and (_flags[_index(cell)] & flag) != 0
