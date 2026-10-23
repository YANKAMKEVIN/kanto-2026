class_name FlyDirector
extends Node
## Vol hors combat (passe systèmes 2, `docs/tech/systemes-2.md` §2.8, T24–T25) : lancé depuis
## l'écran Carte (bouton « S'ENVOLER » d'une ville ouverte, Q-4) ; Boot ferme le menu puis
## appelle [method fly]. Mise en scène : compagnon rentré, « {pokemon} s'envole très haut ! »,
## le joueur s'efface ([constant TAKEOFF_SECONDS]), changement de carte habituel vers le point
## d'arrivée (`fly_points.json`, devant le Centre), « {pokemon} redescend. », joueur libre.
## L'autosave d'arrivée est celui de [signal SceneRouter.map_entered].
##
## Toutes les dépendances sont injectées ([method setup]) : testable sans Boot.

signal flight_started(zone: StringName)
signal flight_finished(zone: StringName)

const MOVE: StringName = &"fly"
const TAKEOFF_DIALOGUE: StringName = &"fly_takeoff"
const LANDING_DIALOGUE: StringName = &"fly_landing"
## Effacement du joueur à l'envol (secondes) [D].
const TAKEOFF_SECONDS: float = 0.6
const INPUT_REASON: StringName = &"fly"
## Orientation à l'arrivée [D] : face à l'écran, dos au Centre.
const ARRIVAL_FACING: Vector2i = Vector2i.DOWN

var _rules: FlyRules
## func() -> Dictionary : cartes découvertes (`GameState.discovered_maps`).
var _discovered: Callable = Callable()
## func(move: StringName) -> FieldMoves.Result.
var _field_check: Callable = Callable()
var _caves: CaveLibrary
## func() -> GameMap.
var _current_map: Callable = Callable()
var _player: Player
var _runner: DialogueRunner
var _router: Node
var _companion: CompanionController
var _flying: bool = false


func setup(rules: FlyRules, discovered: Callable, field_check: Callable, caves: CaveLibrary,
		current_map: Callable, player: Player, runner: DialogueRunner, router: Node,
		companion: CompanionController = null) -> void:
	_rules = rules
	_discovered = discovered
	_field_check = field_check
	_caves = caves
	_current_map = current_map
	_player = player
	_runner = runner
	_router = router
	_companion = companion


func is_flying() -> bool:
	return _flying


## Réponse de [method FlyRules.can_fly_to] pour la carte et la partie courantes.
func check(zone: StringName) -> FlyRules.Check:
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if _rules == null or not is_instance_valid(map):
		return FlyRules.Check.BUSY
	var state := FieldMoves.State.NO_HM
	if _field_check.is_valid():
		var result: Variant = _field_check.call(MOVE)
		if result is FieldMoves.Result:
			state = (result as FieldMoves.Result).state
	var cave := _caves != null and _caves.is_cave(map.map_id)
	var discovered: Dictionary = _discovered.call() if _discovered.is_valid() else {}
	var traits := FlyRules.traits_of(map.interior, cave)
	# Jalon 30 (T8) : carte marquée « no_fly » (salles de la Ligue).
	traits.no_fly = traits.no_fly or map.no_fly
	return _rules.can_fly_to(zone, state, traits, discovered, _flying)


## Vrai si le bouton « S'ENVOLER » est proposé pour [param zone] (menu).
func can_fly_to(zone: StringName) -> bool:
	return check(zone) == FlyRules.Check.OK


## Envol vers [param zone] (coroutine). Sans effet si [method check] refuse.
func fly(zone: StringName) -> void:
	if check(zone) != FlyRules.Check.OK:
		return
	var point := _rules.get_point(zone)
	_flying = true
	flight_started.emit(zone)
	_player.set_input_enabled(false, INPUT_REASON)
	if _companion != null:
		_companion.on_cutscene_started()
	await _say(TAKEOFF_DIALOGUE)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_player, ^"modulate:a", 0.0, TAKEOFF_SECONDS)
		await tween.finished
	await _router.change_map(point.map, point.spawn, ARRIVAL_FACING)
	if is_instance_valid(_player):
		_player.modulate.a = 1.0
	await _say(LANDING_DIALOGUE)
	if _companion != null:
		_companion.on_cutscene_finished()
	_player.set_input_enabled(true, INPUT_REASON)
	_flying = false
	flight_finished.emit(zone)


func _say(dialogue_id: StringName) -> void:
	if _runner == null:
		return
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if _runner.play(dialogue_id, null, map):
		await _runner.dialogue_finished
