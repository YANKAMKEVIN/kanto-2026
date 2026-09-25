class_name GridMover
extends RefCounted
## Déplacement case par case d'une entité (joueur, plus tard PNJ), sans scène.
##
## Piloté à chaque image par [method update] (delta, direction tenue, course).
## Comportement Pokémon :
## - à l'arrêt, une direction différente de l'orientation fait d'abord pivoter ;
##   relâchée avant [member turn_hold_duration] (comptée à partir de l'image qui suit
##   le pivot), le personnage a seulement tourné ;
## - la direction déjà regardée fait avancer tout de suite (le pas démarre dans
##   l'image de l'appui ; son temps compte à partir de l'image suivante) ;
## - tant qu'une direction est tenue, les cases s'enchaînent sans pause (le temps
##   restant d'un pas est reporté sur le suivant) ; changer de direction en marche
##   fait tourner et repartir sans délai ;
## - contre un obstacle, le personnage reste sur place et [signal bumped] est émis
##   une fois par poussée.
## La scène lit [method get_world_position] et les signaux pour l'affichage.

signal facing_changed(direction: Vector2i)
signal step_started(from_cell: Vector2i, to_cell: Vector2i, running: bool)
signal step_finished(cell: Vector2i)
signal bumped(direction: Vector2i)

enum State { IDLE, TURNING, MOVING }

var walk_duration: float = Grid.WALK_STEP_DURATION
var run_duration: float = Grid.RUN_STEP_DURATION
var jump_duration: float = Grid.LEDGE_JUMP_DURATION
var turn_hold_duration: float = Grid.TURN_HOLD_DURATION

var _grid: GridWorld
var _entity: Object
var _state: State = State.IDLE
var _cell: Vector2i = Vector2i.ZERO
var _facing: Vector2i = Vector2i.DOWN
var _from: Vector2i = Vector2i.ZERO
var _to: Vector2i = Vector2i.ZERO
var _elapsed: float = 0.0
var _duration: float = 0.0
var _running: bool = false
var _jumping: bool = false
var _bumped_direction: Vector2i = Vector2i.ZERO


## [param entity] : objet inscrit dans l'occupation de [param grid] (null = aucune).
func _init(grid: GridWorld, entity: Object = null) -> void:
	_grid = grid
	_entity = entity


## Téléporte l'entité (apparition, changement de carte). Annule tout pas en cours.
## Échoue si la case est hors carte ou occupée par une autre entité.
func place(cell: Vector2i, facing: Vector2i = Vector2i.DOWN) -> bool:
	if not _grid.is_in_bounds(cell):
		return false
	if _entity != null:
		if not _grid.occupy(cell, _entity):
			return false
		if _state == State.MOVING and _to != cell:
			_grid.release(_to, _entity)
		if _cell != cell:
			_grid.release(_cell, _entity)
	_cell = cell
	_from = cell
	_to = cell
	_state = State.IDLE
	_elapsed = 0.0
	_running = false
	_jumping = false
	_bumped_direction = Vector2i.ZERO
	if Grid.is_cardinal(facing):
		_set_facing(facing)
	return true


## Avance la simulation. [param direction] : direction tenue (ZERO si aucune ;
## une valeur non cardinale est ignorée). [param run] : bouton de course tenu.
func update(delta: float, direction: Vector2i, run: bool) -> void:
	if not Grid.is_cardinal(direction):
		direction = Vector2i.ZERO
	if direction != _bumped_direction:
		_bumped_direction = Vector2i.ZERO
	match _state:
		State.MOVING:
			_elapsed += delta
			if _elapsed < _duration:
				return
			var leftover := _elapsed - _duration
			_finish_step()
			if direction != Vector2i.ZERO:
				_set_facing(direction)
				_try_step(direction, run, leftover)
		State.TURNING:
			if direction == Vector2i.ZERO:
				_state = State.IDLE
			elif direction != _facing:
				_begin_turn(direction)
			else:
				_elapsed += delta
				if _elapsed >= turn_hold_duration:
					_try_step(direction, run, _elapsed - turn_hold_duration)
		State.IDLE:
			if direction == Vector2i.ZERO:
				return
			if direction != _facing:
				_begin_turn(direction)
			else:
				_try_step(direction, run, 0.0)


## Case sur laquelle l'entité se tient (case de départ pendant un pas).
func get_cell() -> Vector2i:
	return _cell


## Case visée par le pas en cours (= [method get_cell] à l'arrêt). Déjà réservée.
func get_target_cell() -> Vector2i:
	return _to if _state == State.MOVING else _cell


func get_facing() -> Vector2i:
	return _facing


func get_state() -> State:
	return _state


func is_moving() -> bool:
	return _state == State.MOVING


func is_running() -> bool:
	return _state == State.MOVING and _running


func is_jumping() -> bool:
	return _state == State.MOVING and _jumping


## Avancement du pas en cours, de 0 à 1 (0 à l'arrêt).
func get_progress() -> float:
	if _state != State.MOVING or _duration <= 0.0:
		return 0.0
	return clampf(_elapsed / _duration, 0.0, 1.0)


## Position monde interpolée (pieds), à appliquer au nœud à chaque image.
func get_world_position() -> Vector2:
	if _state != State.MOVING:
		return Grid.cell_to_world(_cell)
	return Grid.cell_to_world(_from).lerp(Grid.cell_to_world(_to), get_progress())


func _begin_turn(direction: Vector2i) -> void:
	_set_facing(direction)
	_state = State.TURNING
	_elapsed = 0.0


func _try_step(direction: Vector2i, run: bool, elapsed: float) -> bool:
	var target := _grid.get_step_target(_cell, direction, _entity)
	if target == _cell:
		_state = State.IDLE
		_elapsed = 0.0
		if _bumped_direction != direction:
			_bumped_direction = direction
			bumped.emit(direction)
		return false
	if _entity != null and not _grid.move_occupant(_entity, _cell, target):
		_state = State.IDLE
		_elapsed = 0.0
		return false
	_jumping = target != _cell + direction
	_running = run and not _jumping
	if _jumping:
		_duration = jump_duration
	elif _running:
		_duration = run_duration
	else:
		_duration = walk_duration
	_from = _cell
	_to = target
	_elapsed = elapsed
	_state = State.MOVING
	step_started.emit(_from, _to, _running)
	return true


func _finish_step() -> void:
	_cell = _to
	_from = _to
	_state = State.IDLE
	_elapsed = 0.0
	_jumping = false
	step_finished.emit(_cell)


func _set_facing(direction: Vector2i) -> void:
	if direction == _facing:
		return
	_facing = direction
	facing_changed.emit(direction)
