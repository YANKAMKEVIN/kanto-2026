class_name DefeatRecovery
extends Node
## Réveil après une défaite (dossier 07 §11, dossier 09 §7 ; jalon-07.md §3.3.2, §6.3) : remplace
## l'ancien `EncounterDirector._handle_defeat`. Partagé par la défaite sauvage
## ([EncounterDirector]) et la défaite contre un Dresseur (étape de scène « wake_up »,
## [method CutsceneDirector.set_recovery], T25 : le rival de la Route 22).
##
## [method recover] : l'équipe est soignée, le joueur se réveille au **point de repos** de la
## partie ([method RestPointLibrary.wakeup_point] : le dernier Centre utilisé, sinon la maison),
## tourné comme le dit la donnée, puis [signal woke_up] part (Boot écrit la sauvegarde tout de
## suite : la défaite est un fait accompli, QA S3 du J5) et le mot du lieu est joué
## (`mom_wakeup`, `nurse_wakeup` : `data/world/rest_points.json`), sans être attendu : le
## dialogue pose son propre verrou sur le joueur. Le fondu du routeur tient lieu de l'« écran très
## bref » (dossier 05 §23).
##
## Ne lit aucun autoload : tout arrive par [method setup].

## Le joueur vient de se réveiller au point de repos (équipe soignée), avant le mot du lieu.
signal woke_up(map_id: StringName)

var _state: Node
var _rest_points: RestPointLibrary
var _router: Node
var _runner: DialogueRunner
var _map: GameMap


## [param state] : GameState (ou une instance de game_state.gd en test) ; [param router] :
## SceneRouter (ou un faux qui a `change_map`) ; [param runner] : lecteur du mot de réveil
## (null : aucun mot).
func setup(state: Node, rest_points: RestPointLibrary, router: Node,
		runner: DialogueRunner) -> void:
	_state = state
	_rest_points = rest_points
	_router = router
	_runner = runner


## Carte courante (Boot, à chaque changement de carte) : celle du mot de réveil si le routeur ne
## la donne pas.
func set_map(map: GameMap) -> void:
	_map = map


## Soin, réveil au point de repos, [signal woke_up], puis le mot du lieu. Coroutine.
func recover() -> void:
	if _state == null:
		return
	var party := _state.party as Party
	if party != null:
		party.heal_all()
	var point := wakeup_point()
	if _router != null and _router.has_method(&"change_map"):
		await _router.change_map(point.map, point.spawn, point.facing)
	woke_up.emit(point.map)
	if _runner != null and not point.wakeup_dialogue.is_empty():
		_runner.play(point.wakeup_dialogue, null, _current_map())


## Où le joueur se réveillerait maintenant (jamais null).
func wakeup_point() -> RestPoint:
	if _rest_points != null:
		return _rest_points.wakeup_point(_state)
	var fallback := RestPoint.new()
	fallback.map = _state.heal_map
	fallback.spawn = _state.heal_spawn
	return fallback


func _current_map() -> GameMap:
	if _router != null and _router.has_method(&"get_current_map"):
		var map := _router.call(&"get_current_map") as GameMap
		if is_instance_valid(map):
			return map
	return _map if is_instance_valid(_map) else null
