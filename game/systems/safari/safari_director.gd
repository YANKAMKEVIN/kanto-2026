class_name SafariDirector
extends Node
## Visite du Parc Safari en jeu (J23, dossier 26 §4, §11 ; plan `jalon-23.md` §2.1, §2.2, §2.15).
## Pilote la [SafariVisit] de l'état ([member GameState.safari]) ; les règles restent dans
## [SafariVisit] et [SafariConfig] (pures, testées à part).
##
## - **Péage** (étape de scène « safari » : « enter ») : 500 ₽ débités d'un coup ou rien
##   (`safari_pay_failed`), visite commencée, autosave demandée.
## - **Pas** : chaque pas effectif du joueur sur une carte du Parc ([member SafariConfig.maps] :
##   zones et maisons ; pas la Porte) appelle [method SafariVisit.on_step]. Pivoter, se cogner,
##   les dialogues, menus, combats et déplacements scriptés ne comptent pas (aucun pas libre).
##   Compteur à 0 : le pas suivant termine la visite, sans rencontre sur ce pas (les rencontres
##   sont coupées dès que le compteur tombe à 0).
## - **Fin** : jamais pendant un combat, une scène, un dialogue ou une transition ; annoncée dès
##   le retour au calme (haut-parleur, fondu vers la Porte, mot de l'employé : scènes
##   `j23_safari_time_up` / `j23_safari_out_of_balls`). La fin par les Balls est relevée au retour
##   d'une rencontre Safari (la visite y est devenue inactive).
## - **Sortie volontaire** (« leave ») : la visite finit, Balls perdues.
## - **Quitter le Parc autrement** (Corde Sortie quand elle s'y utilisera, réveil, départ de
##   débogage) : arrivée sur une carte qui n'est ni du Parc ni la Porte → visite close, sans
##   remboursement. **Cohérence au chargement** : joueur dans le Parc sans visite → renvoyé à la
##   Porte (`j23_safari_no_visit`, message neutre [D]).
## - Drapeau miroir `safari_active` (= visite active), lu par les variantes des dialogues et des
##   scènes de la Porte ; tenu à jour à chaque changement.
## - CS03 / CS04 (dossier 26 §11) : réconciliation objet ↔ drapeau à chaque carte
##   ([method reconcile_key_items]).

## La visite a changé (pastille « pas · Balls », N-7) ; [param shown] : pastille à montrer.
signal visit_changed(shown: bool, steps_left: int, balls_left: int)
## La visite vient de se terminer ([constant SafariVisit.TIME_UP], [constant
## SafariVisit.OUT_OF_BALLS], [constant SafariVisit.LEFT_EARLY], [constant LEFT_PARK]).
signal visit_ended(reason: StringName)

const FLAG_ACTIVE: StringName = &"safari_active"
const FLAG_PAY_FAILED: StringName = &"safari_pay_failed"
## Drapeaux de passage du comptoir, remis à faux par « clear ».
const TRANSIENT_FLAGS: Array[StringName] = [&"safari_gate_yes", &"safari_gate_leave_yes",
	&"safari_pay_failed"]
## Fin hors du Parc (Corde Sortie, réveil, débogage) : close sans annonce.
const LEFT_PARK: StringName = &"left_park"
## Partie rechargée dans le Parc sans visite.
const NO_VISIT: StringName = &"no_visit"
const END_CUTSCENES: Dictionary[StringName, StringName] = {
	SafariVisit.TIME_UP: &"j23_safari_time_up",
	SafariVisit.OUT_OF_BALLS: &"j23_safari_out_of_balls",
	NO_VISIT: &"j23_safari_no_visit",
}
## Objets uniques remis avec un drapeau dans la même scène : drapeau → objet (dossier 26 §11).
const KEY_ITEMS: Dictionary[StringName, StringName] = {&"got_hm03": &"hm03", &"got_hm04": &"hm04"}
const INPUT_REASON: StringName = &"safari"

var _state: Node
var _config: SafariConfig
var _player: Player
var _router: Node
var _cutscenes: CutsceneDirector
var _encounters: EncounterDirector
var _battles: BattleDirector
var _autosave: Callable = Callable()
var _map_id: StringName = &""
## Fin à annoncer au retour au calme (&"" : aucune).
var _pending: StringName = &""
var _shown: bool = false
var _last_emit: Array = []


## Branche le directeur. [param state] : GameState (ou une instance de test) ; [param autosave] :
## `func(reason: String) -> void` (Boot.request_autosave), facultatif.
func setup(state: Node, config: SafariConfig, player: Player, router: Node,
		cutscenes: CutsceneDirector, encounters: EncounterDirector = null,
		battles: BattleDirector = null, autosave: Callable = Callable()) -> void:
	_state = state
	_config = config
	_player = player
	_router = router
	_cutscenes = cutscenes
	_encounters = encounters
	_battles = battles
	_autosave = autosave
	if is_instance_valid(_player) and not _player.moved.is_connected(_on_player_moved):
		_player.moved.connect(_on_player_moved)
	if _encounters != null and not _encounters.encounter_finished.is_connected(
			_on_encounter_finished):
		_encounters.encounter_finished.connect(_on_encounter_finished)
	if _cutscenes != null:
		_cutscenes.safari_handler = handle
	_sync_flag()


func get_config() -> SafariConfig:
	return _config


func get_visit() -> SafariVisit:
	return _state.safari as SafariVisit if _state != null else null


## Vrai si [param map_id] est une carte du Parc (le compteur y tourne).
func is_park_map(map_id: StringName) -> bool:
	return _config != null and _config.maps.has(map_id)


## Fin en attente d'annonce (&"" : aucune), pour les tests.
func get_pending_end() -> StringName:
	return _pending


## Nouvelle carte ([signal SceneRouter.map_changed]).
func set_map(map: GameMap) -> void:
	_map_id = map.map_id if is_instance_valid(map) else &""
	var visit := get_visit()
	if visit == null:
		return
	reconcile_key_items()
	var park := is_park_map(_map_id)
	if visit.active and not park and _map_id != _config.end_map:
		visit.finish()
		_pending = &""
		visit_ended.emit(LEFT_PARK)
	elif not visit.active and park and _pending.is_empty():
		_pending = NO_VISIT
	elif visit.active and park and _pending == NO_VISIT:
		# Visite reprise entre-temps (chargement) : rien à renvoyer.
		_pending = &""
	_sync_flag()
	_update_encounters()
	_emit_changed()


## Étape de scène « safari » (CutsceneDirector.safari_handler).
func handle(action: StringName) -> void:
	var flags := _flags()
	match action:
		&"enter":
			if flags != null:
				flags.set_flag(&"safari_gate_yes", false)
			var visit := get_visit()
			if visit != null and visit.active:
				return
			var started := SafariVisit.start(int(_state.money), _config)
			if started == null or not _state.spend_money(_config.fee):
				if flags != null:
					flags.set_flag(FLAG_PAY_FAILED)
				return
			_state.safari = started
			_pending = &""
			_sync_flag()
			if _autosave.is_valid():
				_autosave.call("péage du Parc Safari")
		&"leave":
			if flags != null:
				flags.set_flag(&"safari_gate_leave_yes", false)
			var visit := get_visit()
			if visit != null and visit.active:
				visit.finish()
				visit_ended.emit(SafariVisit.LEFT_EARLY)
			_sync_flag()
		&"clear":
			if flags != null:
				for flag: StringName in TRANSIENT_FLAGS:
					flags.set_flag(flag, false)
	_update_encounters()
	_emit_changed()


## Objet ↔ drapeau des CS du Parc (dossier 26 §11, modèle du J16) : objet sans drapeau → drapeau ;
## drapeau sans objet → objet rendu (une fois : le drapeau reste), anomalie journalisée.
func reconcile_key_items() -> void:
	var flags := _flags()
	var bag: Bag = _state.bag as Bag if _state != null else null
	if flags == null or bag == null:
		return
	for flag: StringName in KEY_ITEMS:
		var item: StringName = KEY_ITEMS[flag]
		var has_item := bag.has(item)
		if has_item and not flags.has_flag(flag):
			flags.set_flag(flag)
		elif flags.has_flag(flag) and not has_item:
			push_warning("SafariDirector : %s posé sans %s ; objet rendu" % [flag, item])
			bag.add(item, 1)


func _process(_delta: float) -> void:
	_sync_flag()
	if not _pending.is_empty() and _is_calm():
		_play_end(_pending)
	_emit_changed()


func _on_player_moved(_cell: Vector2i) -> void:
	if not is_park_map(_map_id):
		return
	if is_instance_valid(_player) and not _player.is_input_enabled():
		return
	var visit := get_visit()
	if visit == null or not visit.active:
		return
	if visit.on_step() == SafariVisit.TIME_UP:
		_pending = SafariVisit.TIME_UP
		_sync_flag()
		visit_ended.emit(SafariVisit.TIME_UP)
	_update_encounters()
	_emit_changed()


## Retour d'une rencontre : la dernière Safari Ball a fini la visite (§2.3).
func _on_encounter_finished(_outcome: int) -> void:
	var visit := get_visit()
	if visit == null or not is_park_map(_map_id):
		return
	if not visit.active and _pending.is_empty() and _state.flags.has_flag(FLAG_ACTIVE):
		_pending = SafariVisit.OUT_OF_BALLS
		visit_ended.emit(SafariVisit.OUT_OF_BALLS)
	_sync_flag()
	_update_encounters()


## Rien ne bouge : ni scène, ni combat, ni rencontre, ni transition, joueur libre.
func _is_calm() -> bool:
	if _cutscenes == null or _cutscenes.is_running():
		return false
	if _battles != null and _battles.is_running():
		return false
	if _encounters != null and _encounters.is_running():
		return false
	if _router != null and _router.has_method(&"is_transitioning") \
			and bool(_router.call(&"is_transitioning")):
		return false
	return not is_instance_valid(_player) or _player.is_input_enabled()


func _play_end(reason: StringName) -> void:
	_pending = &""
	var visit := get_visit()
	if visit != null and visit.active:
		visit.finish()
	_sync_flag()
	_update_encounters()
	var cutscene: StringName = END_CUTSCENES.get(reason, &"")
	if _cutscenes != null and not cutscene.is_empty():
		_cutscenes.play(cutscene)


## Rencontres coupées sur le pas qui termine la visite (compteur à 0) et sans visite dans le Parc.
func _update_encounters() -> void:
	if _encounters == null:
		return
	var visit := get_visit()
	if is_park_map(_map_id):
		_encounters.enabled = visit != null and visit.active and visit.steps_left > 0
	else:
		_encounters.enabled = true


func _sync_flag() -> void:
	var flags := _flags()
	var visit := get_visit()
	if flags != null and visit != null and flags.has_flag(FLAG_ACTIVE) != visit.active:
		flags.set_flag(FLAG_ACTIVE, visit.active)


func _emit_changed() -> void:
	var visit := get_visit()
	var shown := visit != null and visit.active and is_park_map(_map_id) \
		and (_cutscenes == null or not _cutscenes.is_running()) \
		and (_battles == null or not _battles.is_running())
	var steps := visit.steps_left if visit != null else 0
	var balls := visit.balls_left if visit != null else 0
	var now := [shown, steps, balls]
	if now == _last_emit:
		return
	_last_emit = now
	_shown = shown
	visit_changed.emit(shown, steps, balls)


func _flags() -> StoryFlags:
	return _state.flags as StoryFlags if _state != null else null
