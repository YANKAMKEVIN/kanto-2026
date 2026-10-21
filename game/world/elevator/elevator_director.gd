class_name ElevatorDirector
extends Node
## Ascenseur dans le moteur (jalon 20 T13, `docs/tech/jalon-20.md` §2.3.3 et §2.3.5 ; dossier 23
## §9 et §13.4). Enfant de [Boot]. Les règles sont dans [ElevatorRules] (pur) ; ce nœud relie la
## cabine, le panneau d'étages ([ElevatorPanel], T14) et le joueur.
##
## - **Entrée dans une cabine** ([method set_map], relais de `SceneRouter.map_changed`) : l'étage
##   courant est celui d'où l'on vient ([method ElevatorRules.entry_floor]) ; la **sortie est
##   réorientée** : chaque warp de la cabine qui mène à un étage de cet ascenseur vise l'arrivée
##   de l'étage courant (dans la scène, ces warps visent le premier étage).
## - **Panneau** : le dialogue [constant PANEL_DIALOGUE] (action `open_elevator`) fait appeler
##   [method open_panel] par Boot à la fin du dialogue. Sans la clé : dialogue
##   [constant LOCKED_DIALOGUE] (T-50), rien d'autre. Sinon le panneau s'ouvre (joueur bloqué,
##   [signal panel_opened]) ; FERMER ou le retour Android : rien ne change.
## - **Trajet** ([method choose_floor]) : panneau fermé, [signal ride_started] (Boot rentre le
##   compagnon), légère secousse de la caméra du joueur ([constant SHAKE_DURATION] s,
##   ±[constant SHAKE_AMPLITUDE] px, coupée par « Réduire les animations ») avec une vibration
##   légère, fondu au noir, étage courant changé et sortie réorientée, fondu retour, joueur
##   libre, [signal ride_finished]. Le joueur **sort à pied** par la porte de la cabine.
## - **Sauvegarde** : rien n'est persisté ; la cabine n'est jamais une position sauvée :
##   [method stable_location] rend l'arrivée de l'étage courant.
##
## Interface de l'écran (T14) : [method set_panel] reçoit un objet qui a `open(view:
## ElevatorPanelView)`, `close()`, et les signaux `floor_chosen(floor_id: StringName)` et
## `closed` ; le directeur l'ouvre, le ferme et écoute ses deux signaux. Sans écran (tests) :
## [method choose_floor] et [method close_panel] pilotent directement.

## Le panneau vient de s'ouvrir (vue des étages).
signal panel_opened(view: ElevatorPanelView)
## Le panneau s'est fermé sans trajet (FERMER, retour Android).
signal panel_closed
## Un trajet commence vers [param floor_id] (joueur bloqué, compagnon à rentrer).
signal ride_started(floor_id: StringName)
## Trajet fini : [param floor_id] est l'étage courant, le joueur est libre.
signal ride_finished(floor_id: StringName)

## Raison de blocage du joueur pendant le panneau et le trajet.
const LOCK_REASON: StringName = &"elevator"
## Dialogue du panneau de toute cabine (variante sans page, action `open_elevator`).
const PANEL_DIALOGUE: StringName = &"elevator_panel"
## « Le panneau ne répond pas. Il faut une clé. » (dossier 23 §20, texte 50).
const LOCKED_DIALOGUE: StringName = &"elevator_locked"
## Fondu du trajet : au noir, puis retour (0,4 s en tout) [D].
const FADE_OUT: float = 0.2
const FADE_IN: float = 0.2
## Secousse [D] : durée (s), amplitude (px), vibration légère (ms).
const SHAKE_DURATION: float = 0.25
const SHAKE_AMPLITUDE: float = 6.0
const SHAKE_HAPTIC_MS: int = UiTokens.HAPTIC_TAP_MS
## Décalages successifs de la secousse (fractions de l'amplitude, axe vertical).
const _SHAKE_STEPS: Array[float] = [1.0, -1.0, 0.6, -0.6, 0.0]

## « Réduire les animations » : pas de secousse (le fondu reste). Posé par Boot.
var reduce_motion: bool = false
## Case d'un point d'apparition d'une autre carte : `func(map_id, spawn) -> Vector2i`
## ((-1, -1) si inconnu). Boot y branche sa lecture des scènes ; sert à [method stable_location].
var spawn_cell_source: Callable = Callable()

var _library: ElevatorLibrary
var _player: Player
var _runner: DialogueRunner
var _fade: ScreenFade
## L'état de la partie (son Sac) : l'autoload GameState en jeu, une instance en test.
var _state: Node
var _panel: Object
var _map: GameMap
var _elevator: ElevatorData
var _current: StringName = &""
var _panel_open: bool = false
var _riding: bool = false
var _shake: Tween
## Étage → case d'arrivée (lue une fois par visite de la cabine).
var _arrival_cells: Dictionary[StringName, Vector2i] = {}


## Branche le directeur. [param fade] : le rideau des transitions (fondu du trajet).
func setup(library: ElevatorLibrary, state: Node, player: Player, runner: DialogueRunner,
		fade: ScreenFade) -> void:
	_library = library
	_state = state
	_player = player
	_runner = runner
	_fade = fade


## Branche l'écran du panneau (voir l'en-tête : `open`, `close`, `floor_chosen`, `closed`).
func set_panel(panel: Object) -> void:
	if _panel != null:
		if _panel.is_connected(&"floor_chosen", _on_floor_chosen):
			_panel.disconnect(&"floor_chosen", _on_floor_chosen)
		if _panel.is_connected(&"closed", close_panel):
			_panel.disconnect(&"closed", close_panel)
	_panel = panel
	if _panel != null:
		_panel.connect(&"floor_chosen", _on_floor_chosen)
		_panel.connect(&"closed", close_panel)


func get_panel() -> Object:
	return _panel


## Nouvelle carte (écran noir) : dans une cabine, étage courant d'après [param arrived_from] (la
## carte quittée) et sortie réorientée ; ailleurs, plus d'ascenseur.
func set_map(map: GameMap, arrived_from: StringName) -> void:
	_map = map
	_arrival_cells.clear()
	_elevator = _library.for_car(map.map_id) if _library != null and map != null else null
	if _elevator == null:
		_current = &""
		return
	_current = ElevatorRules.entry_floor(_elevator, arrived_from)
	_apply_exit()


## Ascenseur de la cabine courante (null hors cabine).
func get_elevator() -> ElevatorData:
	return _elevator


## Étage courant (&"" hors cabine).
func get_current_floor() -> StringName:
	return _current


func is_panel_open() -> bool:
	return _panel_open


func is_riding() -> bool:
	return _riding


## Vrai pendant le panneau ou un trajet (partie pas stable : aucune écriture).
func is_running() -> bool:
	return _panel_open or _riding


## Fin du dialogue du panneau (`open_elevator`) : panneau ouvert, ou T-50 sans la clé. Faux
## (rien ne s'ouvre) hors cabine ou si le panneau ou un trajet est déjà en cours.
func open_panel() -> bool:
	if _elevator == null:
		push_error("ElevatorDirector : panneau hors d'une cabine (%s)"
			% (_map.map_id if is_instance_valid(_map) else &""))
		return false
	if is_running():
		return false
	if not ElevatorRules.can_operate(_elevator, _bag()):
		if _runner != null:
			_runner.play(LOCKED_DIALOGUE, null, _map if is_instance_valid(_map) else null)
		return false
	_panel_open = true
	_lock(true)
	var view := panel_view()
	if _panel != null:
		_panel.call(&"open", view)
	panel_opened.emit(view)
	return true


## Vue du panneau pour la cabine courante.
func panel_view() -> ElevatorPanelView:
	return ElevatorPanelView.build(_elevator, _current)


## Choix d'un étage au panneau. OK : le trajet part (coroutine non attendue). SAME_FLOOR ou
## UNKNOWN_FLOOR : rien ne change, le panneau reste ouvert. Panneau fermé : UNKNOWN_FLOOR.
func choose_floor(floor_id: StringName) -> ElevatorRules.Status:
	if not _panel_open:
		return ElevatorRules.Status.UNKNOWN_FLOOR
	var status := ElevatorRules.choose(_elevator, _current, floor_id, _bag())
	if status != ElevatorRules.Status.OK:
		return status
	_panel_open = false
	_riding = true
	if _panel != null:
		_panel.call(&"close")
	_ride(floor_id)
	return status


## FERMER (ou retour Android) : panneau fermé, joueur libre, rien d'autre.
func close_panel() -> void:
	if not _panel_open:
		return
	_panel_open = false
	if _panel != null:
		_panel.call(&"close")
	_lock(false)
	panel_closed.emit()


## Retour Android : panneau ouvert → fermé ; pendant un trajet → avalé. Faux sinon.
func handle_back() -> bool:
	if _riding:
		return true
	if _panel_open:
		close_panel()
		return true
	return false


## Position à sauver pour [param map_id] / [param cell] / [param facing] :
## { "map": StringName, "cell": Vector2i, "facing": Vector2i }. Dans une cabine, l'arrivée de
## l'étage courant (case de son point d'apparition, orientation de la sortie) ; ailleurs, ou si
## l'arrivée est introuvable, la position donnée.
func stable_location(map_id: StringName, cell: Vector2i, facing: Vector2i) -> Dictionary:
	var given := {"map": map_id, "cell": cell, "facing": facing}
	if _library == null or not _library.is_car(map_id):
		return given
	var elevator := _library.for_car(map_id)
	var floor_id := _current if elevator == _elevator else &""
	var target := ElevatorRules.save_target(elevator, floor_id)
	if target.is_empty():
		return given
	var arrival := _arrival_cell(StringName(target["map"]), StringName(target["spawn"]))
	if arrival == Vector2i(-1, -1):
		push_error("ElevatorDirector : arrivée « %s » introuvable sur « %s »"
			% [target["spawn"], target["map"]])
		return given
	var exit_facing := _exit_facing()
	return {"map": target["map"], "cell": arrival,
		"facing": exit_facing if exit_facing != Vector2i.ZERO else facing}


func _on_floor_chosen(floor_id: StringName) -> void:
	choose_floor(floor_id)


## Le trajet : secousse et vibration, fondu au noir, étage changé, fondu retour.
func _ride(floor_id: StringName) -> void:
	ride_started.emit(floor_id)
	Haptics.vibrate(SHAKE_HAPTIC_MS)
	if not reduce_motion:
		await _play_shake()
	if _fade != null:
		await _fade.fade_out(FADE_OUT)
	_current = floor_id
	_apply_exit()
	if _fade != null:
		await _fade.fade_in(FADE_IN)
	_riding = false
	_lock(false)
	ride_finished.emit(floor_id)


## Secousse de la caméra du joueur ; finit toujours au repos (décalage nul).
func _play_shake() -> void:
	var camera := _player.get_camera() if is_instance_valid(_player) else null
	if camera == null:
		return
	if _shake != null and _shake.is_valid():
		_shake.kill()
	_shake = create_tween()
	var step := SHAKE_DURATION / _SHAKE_STEPS.size()
	for fraction: float in _SHAKE_STEPS:
		_shake.tween_property(camera, ^"offset", Vector2(0.0, fraction * SHAKE_AMPLITUDE), step)
	await _shake.finished
	camera.offset = Vector2.ZERO


## Chaque warp de la cabine qui mène à un étage de l'ascenseur vise l'arrivée de l'étage
## courant.
func _apply_exit() -> void:
	if _elevator == null or not is_instance_valid(_map):
		return
	var target := ElevatorRules.exit_target(_elevator, _current)
	if target.is_empty():
		return
	for warp: Warp in _exit_warps():
		warp.target_map = target["map"]
		warp.target_spawn = target["spawn"]


func _exit_warps() -> Array[Warp]:
	var warps: Array[Warp] = []
	if _elevator == null or not is_instance_valid(_map):
		return warps
	for warp: Warp in _map.get_warps().get_all():
		if not warp.is_coming_soon() and not _elevator.floor_for_map(warp.target_map).is_empty():
			warps.append(warp)
	return warps


## Orientation d'arrivée de la sortie de la cabine (ZERO : garder celle du joueur).
func _exit_facing() -> Vector2i:
	var warps := _exit_warps()
	return warps[0].facing if not warps.is_empty() else Vector2i.ZERO


func _arrival_cell(map_id: StringName, spawn: StringName) -> Vector2i:
	var key := StringName("%s/%s" % [map_id, spawn])
	if not _arrival_cells.has(key):
		var cell := Vector2i(-1, -1)
		if spawn_cell_source.is_valid():
			cell = spawn_cell_source.call(map_id, spawn)
		_arrival_cells[key] = cell
	return _arrival_cells[key]


func _lock(locked: bool) -> void:
	if is_instance_valid(_player):
		_player.set_input_enabled(not locked, LOCK_REASON)


func _bag() -> Bag:
	return _state.bag as Bag if _state != null else null
