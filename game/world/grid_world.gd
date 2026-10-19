class_name GridWorld
extends RefCounted
## Règles d'accès aux cases d'une carte : limites, cases solides, eau, rebords, occupation.
##
## Classe pure, sans dépendance à l'arbre de scènes. [GameMap] la remplit au chargement
## à partir des données des tuiles (solid, water, ledge) et des empreintes des props.
## La seule question « puis-je entrer ? » est tranchée par [method can_enter] ;
## [method get_step_target] en dérive la case d'arrivée réelle (saut de rebord compris).
##
## Jalon 24 (T6, `docs/tech/jalon-24.md` §2.1), ajouts purs : **à pied, rien ne change** tant
## qu'une carte ne pose ni eau surfable, ni courant, ni niveau de sol.
## - Eau **surfable** ([method set_surfable]) : toujours posée avec l'eau, donc refusée à pied.
## - **Mode** du déplaceur ([enum MoveMode]) : lu par `get_move_mode()` sur [code]mover[/code]
##   s'il existe, [constant MoveMode.WALK] sinon (PNJ, compagnon). En [constant MoveMode.SURF],
##   l'eau surfable libre est accessible, la terre praticable aussi (la **descente**).
## - **Courant** ([method set_current]) : direction du flux d'une case d'eau, lue par
##   [CurrentField] ; ignorée par [method can_enter].
## - **Niveau de sol** ([enum Level], Îles Écume : collisions « par paires » de RB) : on ne passe
##   du sol bas au sol haut que par un escalier ; l'eau est au niveau du sol bas. Par défaut,
##   [constant Level.ANY] : compatible avec tout.

## Rebord sautable : direction dans laquelle on peut le franchir.
## Valeurs identiques à la donnée de tuile `ledge` du TileSet.
enum Ledge { NONE = 0, DOWN = 1, LEFT = 2, RIGHT = 3 }
## Mode de déplacement (jalon 24) : à pied ou en Surf.
enum MoveMode { WALK, SURF }
## Niveau de sol d'une case (jalon 24, Îles Écume). ANY (défaut) et STAIRS sont compatibles avec
## tout ; LOW et HIGH ne se touchent pas. Une échelle ou un passage reste ANY.
enum Level { ANY = 0, LOW = 1, HIGH = 2, STAIRS = 3 }

## [method find_reachable] : le mode est celui du déplaceur.
const MODE_FROM_MOVER: int = -1

const _FLAG_SOLID: int = 1
const _FLAG_WATER: int = 2
const _LEDGE_SHIFT: int = 2
const _LEDGE_MASK: int = 0b1100
## Hautes herbes (jalon 5) : bit 4, au-dessus du rebord (bits 2–3). Drapeau purement
## informatif (rencontres, sprite « jambes dans l'herbe ») : il n'entre dans aucune règle
## de déplacement (can_enter, get_step_target, is_free l'ignorent).
const _FLAG_TALL_GRASS: int = 16
## Gravats (jalon 12, T20) : bit 5. Informatif comme les hautes herbes (rencontres de grotte,
## [EncounterDirector]) : n'entre dans aucune règle de déplacement.
const _FLAG_RUBBLE: int = 32

## Second octet par case (jalon 24) : eau surfable (bit 0), courant (bit 1) et sa direction
## (bits 2–3, ordre de [constant _CURRENT_DIRECTIONS]), niveau de sol (bits 4–5).
const _SEA_SURF: int = 1
const _SEA_CURRENT: int = 2
const _SEA_DIR_SHIFT: int = 2
const _SEA_DIR_MASK: int = 0b1100
const _SEA_LEVEL_SHIFT: int = 4
const _SEA_LEVEL_MASK: int = 0b110000
const _CURRENT_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]

## Ordre d'exploration de [method find_path] (chemins reproductibles).
const _PATH_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]

var _size: Vector2i
var _flags: PackedByteArray = PackedByteArray()
## Eau surfable, courants, niveaux (jalon 24) : à part, pour laisser [member _flags] intact.
var _sea: PackedByteArray = PackedByteArray()
var _occupants: Dictionary[Vector2i, Object] = {}
## Occupation **douce** (jalon 11, compagnon) : case → entité. Seules les routines des PNJ la
## consultent ([method is_soft_held]) ; l'accès, les pas, les scènes, les Dresseurs et les
## interactions l'ignorent (`docs/tech/jalon-11-compagnon.md` §2.5).
var _soft: Dictionary[Vector2i, Object] = {}


func _init(map_size: Vector2i) -> void:
	_size = Vector2i(maxi(map_size.x, 0), maxi(map_size.y, 0))
	_flags.resize(_size.x * _size.y)
	_flags.fill(0)
	_sea.resize(_size.x * _size.y)
	_sea.fill(0)


## Mode de déplacement de [param mover] : son `get_move_mode()` s'il existe, WALK sinon.
static func move_mode_of(mover: Object) -> MoveMode:
	if mover != null and is_instance_valid(mover) and mover.has_method(&"get_move_mode"):
		return mover.call(&"get_move_mode") as MoveMode
	return MoveMode.WALK


## Vrai si l'on peut passer d'un sol de niveau [param a] à un sol de niveau [param b].
static func levels_compatible(a: Level, b: Level) -> bool:
	return a == b or a == Level.ANY or b == Level.ANY or a == Level.STAIRS \
		or b == Level.STAIRS


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


## Marque une case d'eau **surfable** (jalon 24) : pose aussi l'eau, si bien qu'à pied la case
## reste refusée. [param surfable] faux retire seulement le caractère surfable (l'eau reste).
## Renvoie false si hors carte.
func set_surfable(cell: Vector2i, surfable: bool = true) -> bool:
	if not is_in_bounds(cell):
		return false
	if surfable:
		set_water(cell, true)
	var i := _index(cell)
	_sea[i] = (_sea[i] | _SEA_SURF) if surfable else (_sea[i] & ~_SEA_SURF)
	return true


## Vrai si la case est une eau surfable (toujours aussi de l'eau).
func is_surfable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and (_sea[_index(cell)] & _SEA_SURF) != 0 and is_water(cell)


## Pose un courant de direction [param direction] (cardinale) sur une case, ou le retire
## (Vector2i.ZERO). Ignoré par les règles d'accès : seul [CurrentField] le lit. Renvoie false
## hors carte ou pour une direction non cardinale.
func set_current(cell: Vector2i, direction: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	var i := _index(cell)
	if direction == Vector2i.ZERO:
		_sea[i] = _sea[i] & ~(_SEA_CURRENT | _SEA_DIR_MASK)
		return true
	var code := _CURRENT_DIRECTIONS.find(direction)
	if code < 0:
		return false
	_sea[i] = (_sea[i] & ~_SEA_DIR_MASK) | _SEA_CURRENT | (code << _SEA_DIR_SHIFT)
	return true


## Direction du courant de la case (Vector2i.ZERO : pas de courant).
func get_current(cell: Vector2i) -> Vector2i:
	if not is_in_bounds(cell):
		return Vector2i.ZERO
	var value := _sea[_index(cell)]
	if value & _SEA_CURRENT == 0:
		return Vector2i.ZERO
	return _CURRENT_DIRECTIONS[(value & _SEA_DIR_MASK) >> _SEA_DIR_SHIFT]


func is_current(cell: Vector2i) -> bool:
	return get_current(cell) != Vector2i.ZERO


## Pose le niveau de sol d'une case (jalon 24). Renvoie false si hors carte.
func set_level(cell: Vector2i, level: Level) -> bool:
	if not is_in_bounds(cell):
		return false
	var i := _index(cell)
	_sea[i] = (_sea[i] & ~_SEA_LEVEL_MASK) | ((level << _SEA_LEVEL_SHIFT) & _SEA_LEVEL_MASK)
	return true


## Niveau de sol de la case ([constant Level.ANY] hors carte ou par défaut).
func get_level(cell: Vector2i) -> Level:
	if not is_in_bounds(cell):
		return Level.ANY
	return ((_sea[_index(cell)] & _SEA_LEVEL_MASK) >> _SEA_LEVEL_SHIFT) as Level


## Marque une case en hautes herbes (ou la libère). Renvoie false si hors carte. N'influe
## sur aucune règle de déplacement : une case peut être à la fois solide et en herbe (les
## deux cases bloquées du bord nord de Bourg Palette, jalon 5 §3.3).
func set_tall_grass(cell: Vector2i, tall: bool = true) -> bool:
	return _set_flag(cell, _FLAG_TALL_GRASS, tall)


func is_tall_grass(cell: Vector2i) -> bool:
	return _has_flag(cell, _FLAG_TALL_GRASS)


## Marque une case de gravats (jalon 12, donnée de tuile `rubble`) ou la libère. Renvoie false
## si hors carte. Comme les hautes herbes, n'influe sur aucune règle de déplacement.
func set_rubble(cell: Vector2i, rubble: bool = true) -> bool:
	return _set_flag(cell, _FLAG_RUBBLE, rubble)


func is_rubble(cell: Vector2i) -> bool:
	return _has_flag(cell, _FLAG_RUBBLE)


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


## Tient doucement [param cell] pour [param entity] (le compagnon, sa case d'arrivée) : la case
## qu'elle tenait est rendue. Une routine de PNJ attend une case tenue ; rien d'autre n'en tient
## compte.
func soft_hold(cell: Vector2i, entity: Object) -> void:
	soft_release(entity)
	if entity != null and is_in_bounds(cell):
		_soft[cell] = entity


## Rend la case tenue doucement par [param entity] (rappel, carte quittée).
func soft_release(entity: Object) -> void:
	for cell: Vector2i in _soft.keys():
		if _soft[cell] == entity:
			_soft.erase(cell)


## Vrai si [param cell] est tenue doucement par une entité encore valide.
func is_soft_held(cell: Vector2i) -> bool:
	if not _soft.has(cell):
		return false
	if not is_instance_valid(_soft[cell]):
		_soft.erase(cell)
		return false
	return true


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
## Jalon 24 : le mode est celui de [param mover] ([method move_mode_of]) ; voir
## [method can_enter_as].
func can_enter(cell: Vector2i, direction: Vector2i, mover: Object = null) -> bool:
	return can_enter_as(cell, direction, move_mode_of(mover), mover)


## [method can_enter] pour un mode donné (jalon 24). Dans les deux modes, en plus : le niveau de
## sol de la case de départ ([param cell] − [param direction]) doit être compatible
## ([method levels_compatible] ; toujours vrai sur une carte sans niveaux).
## - WALK : la règle historique (ni solide, ni eau, rebord abordé dans son sens, libre).
## - SURF : une eau surfable libre (nager) ou une terre praticable libre sans rebord
##   (descendre) ; l'eau non surfable, le solide et les rebords sont refusés.
func can_enter_as(cell: Vector2i, direction: Vector2i, mode: MoveMode,
		mover: Object = null) -> bool:
	if not Grid.is_cardinal(direction) or not is_in_bounds(cell):
		return false
	var flags := _flags[_index(cell)]
	if mode == MoveMode.SURF:
		if flags & _FLAG_SOLID:
			return false
		if flags & _FLAG_WATER:
			if not is_surfable(cell):
				return false
		elif flags & _LEDGE_MASK:
			return false
	else:
		if flags & (_FLAG_SOLID | _FLAG_WATER):
			return false
		var ledge := ((flags & _LEDGE_MASK) >> _LEDGE_SHIFT) as Ledge
		if ledge != Ledge.NONE and ledge_direction(ledge) != direction:
			return false
	if not levels_compatible(get_level(cell - direction), get_level(cell)):
		return false
	var occupant := get_occupant(cell)
	return occupant == null or occupant == mover


## Case d'arrivée d'un pas depuis [param from_cell] vers [param direction] :
## la case voisine, la case après un rebord (saut de 2 cases), ou [param from_cell]
## si le pas est impossible. Jalon 24 : le mode est celui de [param mover].
func get_step_target(from_cell: Vector2i, direction: Vector2i, mover: Object = null) -> Vector2i:
	return get_step_target_as(from_cell, direction, move_mode_of(mover), mover)


## [method get_step_target] pour un mode donné (jalon 24). En SURF, aucun saut de rebord : la
## case voisine si [method can_enter_as] l'accepte (nager, ou **descendre** sur une terre
## praticable : à l'appelant de repasser à pied), sinon [param from_cell].
func get_step_target_as(from_cell: Vector2i, direction: Vector2i, mode: MoveMode,
		mover: Object = null) -> Vector2i:
	var next := from_cell + direction
	if not can_enter_as(next, direction, mode, mover):
		return from_cell
	if mode == MoveMode.SURF or get_ledge(next) == Ledge.NONE:
		return next
	var landing := next + direction
	if not can_enter_as(landing, direction, mode, mover) or get_ledge(landing) != Ledge.NONE:
		return from_cell
	return landing


## Cases atteignables à pied depuis [param start] (start compris), en respectant
## rebords et occupation. Sert aux tests d'acceptation des cartes.
## Jalon 24 : [param mode] (un [enum MoveMode], ou [constant MODE_FROM_MOVER] : celui de
## [param mover]). En SURF, on ne repart que des cases d'eau surfable : les cases de terre où
## l'on peut descendre sont comptées, sans marcher au-delà ([method SurfRules.find_reachable]
## parcourt à pied **et** en Surf).
func find_reachable(start: Vector2i, mover: Object = null,
		mode: int = MODE_FROM_MOVER) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {}
	if not is_in_bounds(start):
		return reached
	var move_mode: MoveMode = move_mode_of(mover) if mode == MODE_FROM_MOVER \
		else mode as MoveMode
	var directions: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	]
	var queue: Array[Vector2i] = [start]
	reached[start] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if move_mode == MoveMode.SURF and not is_surfable(cell):
			continue
		for direction: Vector2i in directions:
			var target := get_step_target_as(cell, direction, move_mode, mover)
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
	var mode := move_mode_of(mover)
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in _PATH_DIRECTIONS:
			var target := get_step_target_as(cell, direction, mode, mover)
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
