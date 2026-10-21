class_name KeyDoorDirector
extends Node
## Portes à carte (passe systèmes 2, §2.10, T28) : répond à l'appui OUVRIR
## ([signal InteractionController.door_requested]). Avec la clé : le battant s'efface
## ([constant OPEN_SECONDS], joueur bloqué), le drapeau de la porte est levé (Boot règle les
## [FlagGate] à chaque drapeau changé : cases libérées, OUVRIR retiré), puis une sauvegarde est
## demandée. Sans la clé : [member KeyDoor.locked_dialogue].
##
## Branché par Boot (`_setup_teleporters`) ; la carte courante est relue à chaque appui.

signal door_opened(door: KeyDoor)

const OPEN_SECONDS: float = 0.3
const INPUT_REASON: StringName = &"key_door"

var _flags: StoryFlags
var _bag: Bag
var _player: Player
var _runner: DialogueRunner
var _current_map: Callable = Callable()
var _request_save: Callable = Callable()
var _busy: bool = false


## [param current_map] : func() -> GameMap ; [param request_save] : func(reason: String).
func setup(flags: StoryFlags, bag: Bag, player: Player, runner: DialogueRunner,
		current_map: Callable, request_save: Callable) -> void:
	_flags = flags
	_bag = bag
	_player = player
	_runner = runner
	_current_map = current_map
	_request_save = request_save


func is_busy() -> bool:
	return _busy


## Porte de la carte courante qui couvre [param cell] (null si aucune).
func find_door(cell: Vector2i) -> KeyDoor:
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if not is_instance_valid(map):
		return null
	for node: Node in get_tree().get_nodes_in_group(FlagGate.GROUP):
		var door := node as KeyDoor
		if door != null and map.is_ancestor_of(door) and door.covers(cell):
			return door
	return null


func on_door_requested(cell: Vector2i) -> void:
	if _busy:
		return
	var door := find_door(cell)
	if door == null:
		push_warning("KeyDoorDirector : aucune porte à carte en %s" % cell)
		return
	var flag := door.get_open_flag()
	match KeyDoor.decide(_flags.has_flag(flag), _bag.has(door.key_item)):
		KeyDoor.Outcome.OPEN:
			_open(door, flag)
		KeyDoor.Outcome.LOCKED:
			if _runner != null:
				_runner.play(door.locked_dialogue, null, _current_map.call())


func _open(door: KeyDoor, flag: StringName) -> void:
	_busy = true
	if is_instance_valid(_player):
		_player.set_input_enabled(false, INPUT_REASON)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(door, ^"modulate:a", 0.0, OPEN_SECONDS)
		await tween.finished
	if is_instance_valid(door):
		door.modulate.a = 1.0
	_flags.set_flag(flag)
	if is_instance_valid(_player):
		_player.set_input_enabled(true, INPUT_REASON)
	_busy = false
	if _request_save.is_valid():
		_request_save.call("porte à carte")
	door_opened.emit(door)
