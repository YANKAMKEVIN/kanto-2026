class_name StrengthDirector
extends Node
## Force dans la partie (passe systèmes 2, `docs/tech/systemes-2.md` §2.7 ; dossier 27 §6) :
## enfant de [Boot], comme [MountDirector]. **Aucune règle ici** : les poussées viennent de
## [BoulderField] / [BoulderRules], la mise en scène du Pokémon de [FieldMovePresenter].
##
## - **Arrivée** ([method on_map_changed], écran noir, joueur posé) : Force retombe (elle ne
##   dure que jusqu'au prochain changement de carte ; un combat ne l'annule pas) ; le nœud
##   [BoulderSetup] `Boulders` de la carte donne le [BoulderField] ; un [Boulder] est posé à
##   chaque origine de [method BoulderField.boulders_at_load] (aucune position n'est
##   sauvegardée : retour à l'origine à chaque entrée). Une origine occupée (le joueur repris
##   dessus) est sautée pour la visite [D].
## - **Activation** : EXAMINER face à un rocher → `strength_boulder` (variantes
##   `strength:<état>`) ; prête, le choix UTILISER / LAISSER ; UTILISER → [method activate] : le
##   Pokémon apparaît ([method FieldMovePresenter.perform], sans obstacle à retirer), Force
##   active, texte T-7 (`strength_used`). Force active, les rochers ne proposent plus rien [D].
## - **Poussée** : Force active, le joueur pousse contre un rocher ([signal Player.bumped]) et
##   garde la direction [constant HOLD_TIME] s → [method push] :
##   MOVED / ON_SWITCH : le rocher glisse, le joueur avance en même temps d'une case [D] ;
##   ON_SWITCH pose ensuite le drapeau de l'interrupteur ; FELL : le rocher tombe et disparaît,
##   drapeau du trou posé, puis T-15 (`strength_boulder_fell`) ; REFUSED : il tremble, sans texte.
##   Un drapeau posé ici déclenche une **sauvegarde forcée** ([member save_handler]) ; les
##   [FlagGate] de la carte (trou bouché, barrière ouverte) suivent par Boot (drapeau changé).
##   Entrées bloquées pendant la glissade (raison [constant REASON]).

## Activation (choix UTILISER) : début et fin (texte T-7 fermé).
signal activation_started
signal activation_finished
## Poussée acceptée : début (entrées bloquées) et fin, avec le résultat ([enum
## BoulderRules.Outcome]) ; un refus n'émet que [signal push_finished].
signal push_started
signal push_finished(outcome: BoulderRules.Outcome)

## Capacité de terrain ([FieldMoves], `data/world/field_moves.json`).
const MOVE: StringName = &"strength"
## Textes validés (dossier 27 T-5 à T-7, T-15) : `data/dialogues/strength.json`.
const EXAMINE_DIALOGUE: StringName = Boulder.EXAMINE_DIALOGUE
const USED_DIALOGUE: StringName = &"strength_used"
const FELL_DIALOGUE: StringName = &"strength_boulder_fell"
## Appui tenu contre un rocher avant la poussée (s), dossier 27 §6.3 [D].
const HOLD_TIME: float = 0.25
## Raison de blocage du joueur pendant une poussée ou l'activation.
const REASON: StringName = &"strength"
## Raison de la sauvegarde forcée (journal).
const SAVE_REASON := "force"

## Sauvegarde forcée : `func(reason: String) -> Error` (Boot : même chemin que l'étape « save »
## d'une scène). Non valide : rien n'est écrit (tests).
var save_handler: Callable

var _flags: StoryFlags
var _player: Player
var _runner: DialogueRunner
var _presenter: FieldMovePresenter
var _map: GameMap
var _field: BoulderField
var _boulders: Array[Boulder] = []
var _active: bool = false
## Activation ou poussée en cours.
var _busy: bool = false
## Change à chaque carte : une coroutine d'une carte quittée s'arrête.
var _session: int = 0
## Appui tenu contre un rocher : direction (ZERO : aucun) et durée.
var _hold_direction: Vector2i = Vector2i.ZERO
var _hold_time: float = 0.0
## Réponse au choix d'EXAMINER (UTILISER).
var _confirmed: bool = false


func _init() -> void:
	name = "StrengthDirector"


func _process(delta: float) -> void:
	if _hold_direction == Vector2i.ZERO:
		return
	var boulder := boulder_at(_player.get_cell() + _hold_direction) \
		if is_instance_valid(_player) else null
	if boulder == null or not _can_push() or _player.get_facing() != _hold_direction \
			or _player.get_bump_direction() != _hold_direction:
		_disarm()
		return
	_hold_time += delta
	if _hold_time >= HOLD_TIME:
		var direction := _hold_direction
		_disarm()
		push(boulder, direction)


## Branche le directeur (rappelable). [param runner] : textes et choix d'EXAMINER (null en test :
## aucun texte) ; [param presenter] : le Pokémon montré à l'activation (null : aucun).
func setup(flags: StoryFlags, player: Player, runner: DialogueRunner,
		presenter: FieldMovePresenter = null) -> void:
	if is_instance_valid(_player) and _player.bumped.is_connected(_on_bumped):
		_player.bumped.disconnect(_on_bumped)
	if is_instance_valid(_runner) and _runner.choice_made.is_connected(_on_choice_made):
		_runner.choice_made.disconnect(_on_choice_made)
		_runner.dialogue_finished.disconnect(_on_dialogue_finished)
	_flags = flags
	_player = player
	_runner = runner
	_presenter = presenter
	if _player != null:
		_player.bumped.connect(_on_bumped)
	if _runner != null:
		_runner.choice_made.connect(_on_choice_made)
		_runner.dialogue_finished.connect(_on_dialogue_finished)


## Nouvelle carte (écran noir, joueur déjà posé) : Force retombe, rochers à leur origine.
func on_map_changed(map: GameMap) -> void:
	_session += 1
	_clear()
	_map = map
	_active = false
	_confirmed = false
	if _busy and is_instance_valid(_player):
		_player.set_input_enabled(true, REASON)
	_busy = false
	if not is_instance_valid(map):
		return
	var boulder_setup := map.get_node_or_null(NodePath(BoulderSetup.NODE_NAME)) as BoulderSetup
	if boulder_setup == null:
		return
	_field = boulder_setup.to_field()
	var grid := map.get_grid()
	for cell: Vector2i in _field.boulders_at_load(_flags):
		var boulder := Boulder.new()
		boulder.name = "Boulder_%d_%d" % [cell.x, cell.y]
		map.get_entities().add_child(boulder)
		if not boulder.place(grid, cell):
			print("StrengthDirector : origine %s occupée sur %s, rocher absent pour la visite"
				% [cell, map.map_id])
			boulder.queue_free()
			continue
		_boulders.append(boulder)


## Vrai si Force est active sur la carte courante.
func is_active() -> bool:
	return _active


## Vrai pendant une activation ou une poussée.
func is_running() -> bool:
	return _busy


## Rochers posés sur la carte courante.
func get_boulders() -> Array[Boulder]:
	return _boulders.duplicate()


## [BoulderField] de la carte courante (null : carte sans rochers).
func get_field() -> BoulderField:
	return _field


## Rocher de [param cell] (null : aucun).
func boulder_at(cell: Vector2i) -> Boulder:
	for boulder: Boulder in _boulders:
		if is_instance_valid(boulder) and boulder.get_cell() == cell:
			return boulder
	return null


## Coroutine : Force s'active (choix UTILISER) ; [param boulder] : le rocher examiné (cible de la
## mise en scène, peut être null). Faux si rien ne s'est fait (déjà active, occupé, sans carte).
func activate(boulder: Boulder = null) -> bool:
	if _active or _busy or not is_instance_valid(_map) or not is_instance_valid(_player):
		return false
	var session := _session
	_busy = true
	_player.set_input_enabled(false, REASON)
	activation_started.emit()
	if _presenter != null:
		await _presenter.perform(MOVE, boulder, false)
		if session != _session:
			return false
	_active = true
	for each: Boulder in _boulders:
		if is_instance_valid(each):
			each.set_examinable(false)
	var played := _runner != null and _runner.play(USED_DIALOGUE, null, _map)
	_player.set_input_enabled(true, REASON)
	_busy = false
	if played:
		await _runner.dialogue_finished
	activation_finished.emit()
	return true


## Coroutine : pousse [param boulder] vers [param direction] (le joueur derrière lui). Rend le
## résultat ; REFUSED sans Force active, sans carte ou pendant une autre poussée.
func push(boulder: Boulder, direction: Vector2i) -> BoulderRules.Outcome:
	if not _active or _busy or _field == null or not is_instance_valid(boulder) \
			or not is_instance_valid(_map):
		return BoulderRules.Outcome.REFUSED
	var result := _field.push(_map.get_grid(), boulder.get_cell(), direction, _flags)
	if result.is_refused():
		boulder.shake()
		push_finished.emit(result.outcome)
		return result.outcome
	var session := _session
	var flag := _field.flag_to_set(result, _flags)
	_busy = true
	_player.set_input_enabled(false, REASON)
	push_started.emit()
	if result.outcome == BoulderRules.Outcome.FELL:
		await boulder.fall(result.target).finished
		if session != _session:
			return result.outcome
		_boulders.erase(boulder)
		boulder.leave_grid()
		boulder.queue_free()
	else:
		var tween := boulder.slide(result.target)
		_player.script_step(direction)
		if tween != null:
			await tween.finished
		if session != _session:
			return result.outcome
		if _player.is_moving():
			await _player.moved
			if session != _session:
				return result.outcome
	if not flag.is_empty():
		_flags.set_flag(flag)
		if save_handler.is_valid():
			save_handler.call(SAVE_REASON)
	_busy = false
	_player.set_input_enabled(true, REASON)
	push_finished.emit(result.outcome)
	if result.outcome == BoulderRules.Outcome.FELL and not flag.is_empty() and _runner != null:
		_runner.play(FELL_DIALOGUE, null, _map)
	return result.outcome


func _can_push() -> bool:
	return _active and not _busy and _field != null and is_instance_valid(_map) \
		and is_instance_valid(_player) and _player.is_input_enabled() and not _player.is_moving()


func _disarm() -> void:
	_hold_direction = Vector2i.ZERO
	_hold_time = 0.0


func _clear() -> void:
	_disarm()
	for boulder: Boulder in _boulders:
		if is_instance_valid(boulder):
			boulder.leave_grid()
			boulder.queue_free()
	_boulders.clear()
	_field = null


func _on_bumped(direction: Vector2i) -> void:
	if not _can_push() or boulder_at(_player.get_cell() + direction) == null:
		return
	_hold_direction = direction
	_hold_time = 0.0


func _on_choice_made(confirmed: bool) -> void:
	if _runner.get_dialogue_id() == EXAMINE_DIALOGUE:
		_confirmed = confirmed


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	if dialogue_id != EXAMINE_DIALOGUE:
		return
	var confirmed := _confirmed
	_confirmed = false
	if confirmed and is_instance_valid(_player):
		# Après les autres écouteurs de la fin du dialogue (HUD, contrôleur d'interactions).
		_activate_deferred.call_deferred(boulder_at(_player.get_cell() + _player.get_facing()))


func _activate_deferred(boulder: Boulder) -> void:
	await activate(boulder)
