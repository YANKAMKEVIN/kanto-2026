class_name FieldTravelDirector
extends Node
## Téléport et Tunnel hors combat (passe systèmes 2, `docs/tech/systemes-2.md` §3.6 T25b, Q-5),
## sur le modèle de [FlyDirector] : lancés depuis l'écran Équipe (UTILISER dans la fiche de la
## capacité) ; Boot ferme le menu puis appelle [method travel]. Mise en scène : compagnon rentré,
## « {pokemon} utilise Téléport ! » / « {pokemon} creuse un tunnel ! » (dialogues
## `data/dialogues/field_travel.json`, variantes `field`), le joueur s'efface
## ([constant VANISH_SECONDS]), changement de carte habituel (autosave d'arrivée de
## [signal SceneRouter.map_entered]), joueur libre.
## - Téléport : au point de réveil d'après une défaite ([method DefeatRecovery.wakeup_point]),
##   **sans soin**.
## - Tunnel : à la sortie de la grotte, comme la Corde Sortie, sans objet consommé.
##
## Toutes les dépendances sont injectées ([method setup]) : testable sans Boot.

signal travel_started(move: StringName)
signal travel_finished(move: StringName)

const DIALOGUES: Dictionary[StringName, StringName] = {
	FieldTravelRules.TELEPORT: &"teleport_used",
	FieldTravelRules.DIG: &"dig_used",
}
## Effacement du joueur au départ (secondes) [D], celui de l'envol.
const VANISH_SECONDS: float = FlyDirector.TAKEOFF_SECONDS
const INPUT_REASON: StringName = &"field_travel"

## func(move: StringName) -> FieldMoves.Result.
var _field_check: Callable = Callable()
## func() -> RestPoint : le point du réveil (map, spawn, facing).
var _teleport_target: Callable = Callable()
var _caves: CaveLibrary
## func() -> GameMap.
var _current_map: Callable = Callable()
var _player: Player
var _runner: DialogueRunner
var _router: Node
var _companion: CompanionController
var _travelling: bool = false


func setup(field_check: Callable, teleport_target: Callable, caves: CaveLibrary,
		current_map: Callable, player: Player, runner: DialogueRunner, router: Node,
		companion: CompanionController = null) -> void:
	_field_check = field_check
	_teleport_target = teleport_target
	_caves = caves
	_current_map = current_map
	_player = player
	_runner = runner
	_router = router
	_companion = companion


func is_travelling() -> bool:
	return _travelling


## Réponse de [FieldTravelRules] pour [param move] sur la carte et la partie courantes.
func check(move: StringName) -> FieldTravelRules.Check:
	if not FieldTravelRules.is_travel_move(move):
		return FieldTravelRules.Check.UNKNOWN_MOVE
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if not is_instance_valid(map):
		return FieldTravelRules.Check.BUSY
	var state := _field_state(move)
	if move == FieldTravelRules.TELEPORT:
		var traits := MapTraits.new(map.interior)
		var target := _teleport_point()
		return FieldTravelRules.check_teleport(state, traits,
			target.map if target != null else &"", _travelling)
	return FieldTravelRules.check_dig(state, _dig_exit(map), _travelling)


## Voyage par [param move] (coroutine). Sans effet si [method check] refuse.
func travel(move: StringName) -> void:
	if check(move) != FieldTravelRules.Check.OK:
		return
	var map: GameMap = _current_map.call()
	var target_map: StringName
	var target_spawn: StringName
	var facing: Vector2i
	if move == FieldTravelRules.TELEPORT:
		var point := _teleport_point()
		target_map = point.map
		target_spawn = point.spawn
		facing = point.facing
	else:
		var exit := _dig_exit(map)
		target_map = exit.map
		target_spawn = exit.spawn
		facing = exit.facing
	_travelling = true
	travel_started.emit(move)
	_player.set_input_enabled(false, INPUT_REASON)
	if _companion != null:
		_companion.on_cutscene_started()
	await _say(DIALOGUES[move])
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_player, ^"modulate:a", 0.0, VANISH_SECONDS)
		await tween.finished
	await _router.change_map(target_map, target_spawn, facing)
	if is_instance_valid(_player):
		_player.modulate.a = 1.0
	if _companion != null:
		_companion.on_cutscene_finished()
	_player.set_input_enabled(true, INPUT_REASON)
	_travelling = false
	travel_finished.emit(move)


func _field_state(move: StringName) -> FieldMoves.State:
	if _field_check.is_valid():
		var result: Variant = _field_check.call(move)
		if result is FieldMoves.Result:
			return (result as FieldMoves.Result).state
	return FieldMoves.State.NO_POKEMON


func _teleport_point() -> RestPoint:
	if not _teleport_target.is_valid():
		return null
	var point: Variant = _teleport_target.call()
	return point as RestPoint if point is RestPoint else null


func _dig_exit(map: GameMap) -> CaveExit:
	var cell := _player.get_cell() if is_instance_valid(_player) else CaveLibrary.NO_CELL
	return FieldItemRules.escape_target(map.map_id, _caves, cell)


func _say(dialogue_id: StringName) -> void:
	if _runner == null:
		return
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if _runner.play(dialogue_id, null, map):
		await _runner.dialogue_finished
