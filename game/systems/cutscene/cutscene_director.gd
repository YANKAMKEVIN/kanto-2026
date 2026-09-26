class_name CutsceneDirector
extends Node
## Directeur de scènes : le **seul** à jouer une scène scriptée (docs/tech/jalon-03b.md §2.4).
##
## Il ne décide rien : il écoute les pas terminés du joueur ([signal Player.moved]), cherche
## un déclencheur dans la [TriggerTable] de la carte courante, choisit la variante de la
## scène pour les drapeaux ([method Cutscene.pick]) et joue ses étapes dans l'ordre, en
## appelant les nœuds existants ([DialogueRunner], [Player], [Npc]). Le joueur est bloqué
## pour la raison [constant REASON] dès [method play] (de façon synchrone : appelé depuis
## le pas terminé, le verrou empêche le pas qui s'enchaînerait), puis libéré à la fin.
## Il reçoit ses dépendances par [method setup] : il ne lit aucun autoload.
##
## Étapes jouées (T2) : wait, dialogue, face, set. Les étapes spawn, move et change_map sont
## validées par la bibliothèque mais pas encore jouées : push_error, étape sautée.

signal cutscene_started(cutscene_id: StringName)
## Début d'une étape (tests, outils de capture).
signal step_started(index: int)
signal cutscene_finished(cutscene_id: StringName)
## Fin d'une étape « wait » (interne).
signal _wait_elapsed

## Raison de blocage du joueur pendant une scène ([method Player.set_input_enabled]).
const REASON: StringName = &"cutscene"
## Un pas bloqué (case occupée) est retenté à chaque image ; au-delà, l'étape est abandonnée
## (étape « move », T3).
const MOVE_BLOCK_TIMEOUT: float = 2.0
const _ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")

var _library: CutsceneLibrary
var _flags: StoryFlags
var _runner: DialogueRunner
var _player: Player
var _router: _ROUTER_SCRIPT
var _map: GameMap
var _running: bool = false
var _cutscene_id: StringName = &""
var _step_index: int = -1
## Incrémenté à chaque setup() : une scène lancée avant est abandonnée à sa reprise.
var _session: int = 0
var _waiting: bool = false
var _wait_left: float = 0.0
## Image du début de l'attente : elle ne compte pas (sinon l'attente finirait une image tôt).
var _wait_frame: int = -1


func _ready() -> void:
	set_process(_running)


func _process(delta: float) -> void:
	if not _waiting or Engine.get_process_frames() == _wait_frame:
		return
	_wait_left -= delta
	if _wait_left <= 0.0:
		_waiting = false
		_wait_elapsed.emit()


## Branche le directeur. [param router] : l'autoload SceneRouter en jeu, une instance de
## scene_router.gd en test (même API : change_map, get_current_map, is_transitioning).
## Peut être rappelé : une scène en cours est abandonnée, l'ancien joueur débranché.
func setup(library: CutsceneLibrary, flags: StoryFlags, runner: DialogueRunner,
		player: Player, router: Node) -> void:
	_disconnect_player()
	_session += 1
	if _running and is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_running = false
	_waiting = false
	_cutscene_id = &""
	_step_index = -1
	_library = library
	_flags = flags
	_runner = runner
	_player = player
	_router = router as _ROUTER_SCRIPT
	if _player != null:
		_player.moved.connect(_on_player_moved)
	set_process(false)


## Carte courante (relais de Boot sur SceneRouter.map_changed).
func set_map(map: GameMap) -> void:
	_map = map


## Joue [param cutscene_id]. Faux (et rien ne se passe) si une scène tourne, si
## l'identifiant est inconnu (push_error) ou si aucune variante ne s'applique (sans erreur :
## déclencheur désarmé).
func play(cutscene_id: StringName) -> bool:
	if _running:
		return false
	var cutscene := _library.get_cutscene(cutscene_id) if _library != null else null
	if cutscene == null:
		push_error("CutsceneDirector : scène inconnue « %s »" % cutscene_id)
		return false
	var variant := cutscene.pick(_flags)
	if variant == null:
		return false
	_running = true
	_cutscene_id = cutscene_id
	_step_index = -1
	if is_instance_valid(_player):
		_player.set_input_enabled(false, REASON)
	cutscene_started.emit(cutscene_id)
	set_process(true)
	_run(variant, _session)
	return true


func is_running() -> bool:
	return _running


## Étape en cours (−1 hors scène).
func get_step_index() -> int:
	return _step_index


## Identifiant de la scène en cours (&"" hors scène).
func get_cutscene_id() -> StringName:
	return _cutscene_id


func _run(variant: CutsceneVariant, session: int) -> void:
	for i: int in variant.steps.size():
		_step_index = i
		step_started.emit(i)
		var go_on: bool = await _play_step(variant.steps[i])
		if session != _session:
			return
		if not go_on:
			break
	_finish()


## Joue une étape. Faux : la scène s'arrête (réservé au changement de carte manqué, T4).
func _play_step(step: CutsceneStep) -> bool:
	match step.kind:
		CutsceneStep.Kind.WAIT:
			if step.seconds > 0.0:
				_wait_left = step.seconds
				_wait_frame = Engine.get_process_frames()
				_waiting = true
				await _wait_elapsed
		CutsceneStep.Kind.DIALOGUE:
			await _play_dialogue(step.dialogue_id)
		CutsceneStep.Kind.FACE:
			_face(step.actor, step.target)
		CutsceneStep.Kind.SET_FLAGS:
			if _flags != null:
				for flag: StringName in step.flags:
					_flags.set_flag(flag)
		_:
			push_error("CutsceneDirector : étape « %s » pas encore jouée (%s, étape %d)" % [
				CutsceneStep.kind_name(step.kind), _cutscene_id, _step_index + 1])
	return true


func _play_dialogue(dialogue_id: StringName) -> void:
	var map: GameMap = _map if is_instance_valid(_map) else null
	if _runner == null or not _runner.play(dialogue_id, null, map):
		push_error("CutsceneDirector : dialogue « %s » refusé (%s, étape %d)" % [
			dialogue_id, _cutscene_id, _step_index + 1])
		return
	while _runner.is_running():
		await _runner.dialogue_finished


## L'acteur se tourne vers la cible : nom de direction, « player » ou PNJ (axe dominant).
func _face(actor_id: StringName, target: StringName) -> void:
	var actor := _find_actor(actor_id)
	if actor == null:
		push_error("CutsceneDirector : acteur « %s » introuvable (%s, étape %d)" % [
			actor_id, _cutscene_id, _step_index + 1])
		return
	var direction := Grid.direction_from_name(target)
	if not Grid.is_direction_name(target):
		var other := _find_actor(target)
		if other == null:
			push_error("CutsceneDirector : cible « %s » introuvable (%s, étape %d)" % [
				target, _cutscene_id, _step_index + 1])
			return
		direction = Grid.dominant_direction(_cell_of(actor), _cell_of(other))
	if direction == Vector2i.ZERO:
		return
	if actor is Player:
		(actor as Player).face(direction)
	else:
		(actor as Npc).face(direction)


## Joueur (« player ») ou PNJ de la carte courante, résolu à chaque étape ; null sinon.
func _find_actor(actor_id: StringName) -> Node2D:
	if actor_id == NpcRoster.PLAYER_ID:
		return _player if is_instance_valid(_player) else null
	if not is_instance_valid(_map):
		return null
	return _map.get_npc(actor_id)


static func _cell_of(actor: Node2D) -> Vector2i:
	if actor is Player:
		return (actor as Player).get_cell()
	return (actor as Npc).get_cell()


func _finish() -> void:
	var cutscene_id := _cutscene_id
	_running = false
	_waiting = false
	_cutscene_id = &""
	_step_index = -1
	if is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	set_process(false)
	cutscene_finished.emit(cutscene_id)


func _disconnect_player() -> void:
	if is_instance_valid(_player) and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)


## Pas terminé du joueur : déclencheur de la case, si le joueur est libre (pas scripté,
## transition et scène en cours ignorés).
func _on_player_moved(cell: Vector2i) -> void:
	if _running or not is_instance_valid(_map) or not is_instance_valid(_player):
		return
	if not _player.is_input_enabled():
		return
	if _router != null and _router.is_transitioning():
		return
	var trigger := _map.get_triggers().find_on_step(cell, _player.get_facing())
	if trigger != null:
		play(trigger.cutscene_id)
